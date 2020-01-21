//
//  TcpClient.swift
//  Focusrite Midi Control
//
//  Created by Antonio-Radu Varga on 07.07.18.
//  Copyright © 2018 Antonio-Radu Varga. All rights reserved.
//

import Cocoa
import SwiftSocket

class TCPListener: TCPClient{
    
    let ENABLE_LOGGING = false
    
    let RECONNECT_TIME:UInt32 = 3
    let KEEP_ALIVE_TIME:UInt32 = 3
    let SLEEP_TIME:UInt32 = 3
    let msgSeparator:String = "\u{0}"
    
    let lengthSize = 14;
    var connected:Bool = false
    var approved:Bool?
    
    var readingWorkItem: DispatchWorkItem? = nil
//    var readingQueue = DispatchQueue(label: "Reading Queue")
    var keepAliveItem: DispatchWorkItem? = nil
//    var keepAliveQueue = DispatchQueue(label: "Keep Alive Queue")
    
    func start(){
        switch connect(timeout: 3) {
            case .success:
                print("---------------")
                print("Connected to TCP")
                setConnected(connected: true)
                sendGetDevices();
                pollForResponse()
                startKeepAlive()
            case .failure(let error):
                print("connect error:" + error.localizedDescription)
                setConnected(connected: false)
                sleep(RECONNECT_TIME)
                restart()
        }
    }
    
    func setConnected (connected:Bool){
        self.connected = connected
        appDelegate.onConnectionChange(connected: connected)
    }
    
    func restart(){
        print("-----------------------")
        print("Hang on, reconnecting...")
        close()
        start()
    }
    
    func getTaperedLevel (value:Int) -> Double{
        var taptered:Double = Double(value)/100
        taptered = 1/1.27 * taptered
        return taptered
    }
    
    func getFloatValue (value:Int) -> Double{
        var floaty:Double = Double(value)/100
        floaty = 2/1.27 * floaty
        floaty = floaty - 1
        return floaty
    }
    
    func getBool (value:Int) -> Bool{
        return value > 0
    }
    
    func sendUpdateMessage(mapping: UAMapping, value: Int){
        switch mapping.mix {
        case "Inputs":
            sendVolumeMessage(devId: mapping.deviceId, inputId: mapping.inputId,
                              value: value)
        case "Gain":
            sendGainPreampMessage(devId: mapping.deviceId, inputId: mapping.inputId,
                                  value: value)
        case "Pad", "Phase","LowCut","48V":
            sendBoolPreampMessage(devId: mapping.deviceId, inputId: mapping.inputId,
                                  property: mapping.mix, value: value)
        case "Solo", "Mute":
            sendBoolMessage(devId: mapping.deviceId, inputId: mapping.inputId,
                                  property: mapping.mix, value: value)
        case "Send 0", "Send 1", "Send 2", "Send 3", "Send 4", "Send 5":
            sendGainSendMessage(devId: mapping.deviceId, inputId: mapping.inputId,
                                sendId: String(mapping.mix.last!), value: value)
        case "Pan":
            sendFloatMessage(devId: mapping.deviceId, inputId: mapping.inputId, property: mapping.mix,
                                value: value)
        default:
            return
        }
    }
    
    func sendBoolMessage(devId: String, inputId: String, property: String, value: Int){
        sendMessage(msg: "set /devices/" + devId + "/inputs/" + inputId + "/" + property + "/value " + String(getBool(value: value)))
    }
    func sendBoolPreampMessage(devId: String, inputId: String, property: String, value: Int){
        sendMessage(msg: "set /devices/" + devId + "/inputs/" + inputId + "/preamps/0/" + property + "/value " + String(getBool(value: value)))
    }
    func sendGainSendMessage(devId: String, inputId: String, sendId: String, value: Int){
        sendMessage(msg: "set /devices/" + devId + "/inputs/" + inputId + "/sends/" + sendId + "/GainTapered/value " +
            String(format: "%.6f",  getTaperedLevel(value: value)))
    }
    func sendGainPreampMessage(devId: String, inputId: String, value: Int){
        sendMessage(msg: "set /devices/" + devId + "/inputs/" + inputId + "/preamps/0/GainTapered/value " +
            String(format: "%.6f",  getTaperedLevel(value: value)))
    }
    func sendVolumeMessage(devId: String, inputId: String, value: Int){
        sendMessage(msg: "set /devices/" + devId + "/inputs/" + inputId + "/FaderLevelTapered/value/ " +
            String(format: "%.6f",  getTaperedLevel(value: value)))
    }
    func sendFloatMessage(devId: String, inputId: String, property: String, value: Int){
        sendMessage(msg: "set /devices/" + devId + "/inputs/" + inputId + "/" + property + "/value/ " +
            String(format: "%.6f",  getFloatValue(value: value)))
    }
    func sendGetDevices(){
        sendMessage(msg: "get /devices")
    }
    func sendGetDevice(devId: String){
        sendMessage(msg: "get /devices/" + devId)
        sendMessage(msg: "subscribe /devices/" + devId + "/DeviceOnline")
    }
    func sendGetInputs(devId: String){
        sendMessage(msg: "get /devices/" + devId + "/inputs")
    }
    func sendGetInput(devId: String, inputId: String){
        sendMessage(msg: "get /devices/" + devId + "/inputs/" + inputId)
        sendMessage(msg: "get /devices/" + devId + "/inputs/" + inputId + "/sends")
    }
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print("error: ", error.localizedDescription)
            }
        }
        return nil
    }
    
    func getJsonChildren (jsonData: Data) -> [String]{
        do{
            let jsonDict:[String:Any] = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [String : Any]
            let data = jsonDict["data"] as! [String: Any]
            let children = data["children"] as! [String: Any]
            
            return Array(children.keys)
        } catch {
            return []
        }
    }
    
    func getDataAsBool (jsonData: Data) -> Bool{
        do{
            let jsonDict:[String:Any] = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [String : Any]
            let boolData = jsonDict["data"] as! Bool
            
            return boolData
        } catch {
            return false
        }
    }
    
    func handleMessage(msg: String){
        let jsonData = msg.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        do {
            let jsonResponse = try decoder.decode(BasicJsonResponse.self, from: jsonData)
            
            let jsonPath = jsonResponse.path.split(separator: "/")
            
            if (jsonPath[0] == "devices"){
                if (jsonPath.count == 0) {
                
                // -> /devices
                } else if (jsonPath.count == 1) {
                    let childrenKeys = getJsonChildren(jsonData: jsonData)
                    
                    for id in childrenKeys{
                        sendGetDevice(devId: id)
                    }
                
                // -> /devices/id
                } else if (jsonPath.count == 2) {
                    let devId:String = String(jsonPath[1])
                    let jsonResponse = try decoder.decode(JsonResponse<DeviceProperties, DeviceChildren>.self, from: jsonData)
                    appDelegate.addDevice(id: devId, info: jsonResponse)
                    sendGetInputs(devId: devId)
                    
                // -> /devices/id/DeviceOnline
                } else if (jsonPath[2] == "DeviceOnline") {
                    let devId:String = String(jsonPath[1])
                    let online = getDataAsBool(jsonData: jsonData)
                    appDelegate.onDeviceOnline(id: devId, online: online)
                
                } else if (jsonPath[2] == "inputs") {
                    let devId:String = String(jsonPath[1])
                    
                    // -> /devices/id/inputs
                    if (jsonPath.count == 3) {
                        let childrenKeys = getJsonChildren(jsonData: jsonData)
                        
                        for id in childrenKeys{
                            sendGetInput(devId: devId, inputId: id)
                        }
                      
                    // -> /devices/id/inputs/id
                    } else if (jsonPath.count == 4) {
                        let inputId:String = String(jsonPath[3])
                         let jsonResponse = try decoder.decode(JsonResponse<InputProperties, InputChildren>.self, from: jsonData)
                        
                        let childrenKeys = getJsonChildren(jsonData: jsonData)
                        appDelegate.addInput(devId: devId ,inputId: inputId, info: jsonResponse, children: childrenKeys)
                    }
                } else {
                    
                }
            }
        } catch  {
            print("-----------------")
            print("Parse error: \(error).")
        }
    }

    func startKeepAlive() {
        self.keepAliveItem = DispatchWorkItem {
            if(self.connected){
                self.sendMessage(msg: "set /Sleep false")
            }
            sleep(self.KEEP_ALIVE_TIME)
            DispatchQueue.global().async(execute: self.keepAliveItem!)
        }
        
        DispatchQueue.global().async(execute: keepAliveItem!)
    }
    
    func pollForResponse(){
        self.readingWorkItem = DispatchWorkItem {
            if(self.connected){
                
                var dataMsg: String = ""
                var dataChar: String = ""
                
                while !self.compareStrAsChar(str1: dataChar, str2: self.msgSeparator) {
                    dataMsg.append(dataChar)
                    dataChar = self.readMessage(size: 1);
                }
                
                if(self.ENABLE_LOGGING){
                    print("-----------------")
                    print("receivedMsg:" + dataMsg)
                }
                self.handleMessage(msg: dataMsg)
//                sleep(self.SLEEP_TIME)
                
                DispatchQueue.global().async(execute: self.readingWorkItem!)
            }
        }
        
        DispatchQueue.global().async(execute: self.readingWorkItem!)
    }
    
    func compareStrAsChar (str1: String, str2:String) -> Bool{
       return (str1.data(using: .utf8) == str2.data(using: .utf8))
    }
    
    func readMessage(size: Int) -> String {
        guard let data = self.read(size, timeout: 100) else { return "" }
        
        if let response = String(bytes: data, encoding: .utf8) {
            return response
        }
        return "";
    }
    
    
    func sendMessage(msg:String){
        let tcpMessage = String(format:"%@%@", msg, msgSeparator);
        let data:Data = tcpMessage.data(using: .utf8)!
        
        switch self.send(data: data) {
        case .success:
            if(ENABLE_LOGGING){
                print("-----------------")
                print("Send:" + tcpMessage)
            }
        case .failure(let error):
            print("failed to send message." + error.localizedDescription)
            setConnected(connected: false)
            self.restart()
        }
    }
}
