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
    
    func sendVolMessage(item: UAItem, volume: Int){
        var volume:Double = Double(volume)/100
        volume = 1/1.27 * volume
        
        sendVolumeMessage(devId: item.parentId, inputId: item.id, vol: String(format: "%.6f", volume))
    }
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
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
    
    func sendVolumeMessage(devId: String, inputId: String, vol: String){
        sendMessage(msg: "set /devices/" + devId + "/inputs/" + inputId + "/FaderLevelTapered/value/ " + vol)
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
                        appDelegate.addInput(devId: devId ,inputId: inputId, info: jsonResponse)
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
    
    func readMessage(size: Int) -> String{
        guard let data = self.read(size, timeout: 100) else { return "" }
        
        if let response = String(bytes: data, encoding: .utf8) {
            return response
        }
        return "";
    }
    
    
    func sendMessage(msg:String){
        var tcpMessage = String(format:"%@%@", msg, msgSeparator);
        var data:Data = tcpMessage.data(using: .utf8)!
        
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
