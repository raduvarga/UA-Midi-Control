//
//  AppDelegate.swift
//  Focusrite Midi Control
//
//  Created by Antonio-Radu Varga on 07.07.18.
//  Copyright © 2018 Antonio-Radu Varga. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
   
    let SERVER_HOST:String = "127.0.0.1"
    let SERVER_PORT:Int32 = 4710
    
    // controllers
    var tcpClient: TCPListener?
    var midiListener: MidiListener?
    var viewController:ViewController?
    
    // ua stuff
    var uaDevices: [String : UADevice] = [:]
    var selectedUADevice: UADevice?
    var mixes: [String] = ["Inputs", "Gain", "48V", "LowCut", "Phase", "Pad", "Pan", "Solo", "Mute", "Send 0", "Send 1", "Send 2", "Send 3"]
    var selectedMix: String = "Inputs"
    
    // various vars
    var midiMaps: [String : UAMapping] = [:]
    var isMidiMapping:Bool = false
    var selectedMidiMapId = ""
    
    override init(){
        super.init()
        tcpClient = TCPListener(address: SERVER_HOST, port: SERVER_PORT)
        midiListener = MidiListener()
        recreateMidiMaps();
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        tcpClient?.start()
        midiListener?.start()
        
        UserDefaults.standard.register(defaults: ["volumeLimit" : "0"])
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func recreateMidiMaps(){
        let midiMapsPreferences = UserDefaults.standard.dictionary(forKey: "midiMaps")
        if (midiMapsPreferences != nil){
            let midiMapsEncoded: [String : String] = midiMapsPreferences as! [String : String]
            
            for midiMapEncoded in midiMapsEncoded {
                midiMaps[midiMapEncoded.key] = UAMapping(fromStr: midiMapEncoded.value)
            }
        }
    }
    
    func saveMidiMapsToPrefs(){
        var midiMapsEncoded: [String:String] = [:]
        
        for midiMap in midiMaps {
            midiMapsEncoded[midiMap.key] = midiMap.value.getEncodeStr()
        }
        
        UserDefaults.standard.set(midiMapsEncoded, forKey: "midiMaps")
    }
    
    func removeAllMidiMaps(){
        midiMaps.removeAll()
        saveMidiMapsToPrefs()
    }
    
    func findMapping(midiMessage: MidiMessage) -> UAMapping?{
        return midiMaps[midiMessage.asStr]
    }
    
    func findMappingMessage(deviceId:String, inputId:String, mix:String) -> String{
        for midiMap in midiMaps {
            let mapping: UAMapping = midiMap.value
           
            if(mapping.deviceId == deviceId &&
                mapping.inputId == inputId &&
                mapping.mix == mix){
                
                let midiMessage: MidiMessage = MidiMessage(midiStr: midiMap.key)
                return midiMessage.getPrintStr()
            }
        }
        
        return ""
    }
    
    func setMidiMap(deviceId:String, inputId: String, mix:String, midiMessage: MidiMessage){
        let midiStr = midiMessage.asStr
        // remove old midi mapping
        midiMaps.removeValue(forKey: midiStr)
        // set new mapping
        midiMaps[midiStr] = UAMapping(deviceId: deviceId, inputId: inputId, mix: mix)
        
        saveMidiMapsToPrefs()
    }
    
    func onMidiMessageReceived (midiMessage: MidiMessage){
        if(selectedUADevice != nil){
            if(isMidiMapping){
                setMidiMap(deviceId: (selectedUADevice?.id)!, inputId: selectedMidiMapId, mix: selectedMix, midiMessage: midiMessage)
                
                viewController?.setMidiMapping();
            }else{
                guard let mapping: UAMapping = findMapping(midiMessage: midiMessage) else {return}
                tcpClient?.sendUpdateMessage(mapping: mapping, value: midiMessage.value)
            }
        }
    }
    
    func addDevice (id:String, info:JsonResponse<DeviceProperties, DeviceChildren>){
        let uaDevice: UADevice = UADevice(id: id, info:info)
        
        uaDevices[id] = uaDevice
        
        onDeviceOnline(id: id, online: uaDevice.online)
    }
    
    func onDeviceOnline(id:String, online: Bool){
        let uaDevice = uaDevices[id]
        uaDevice?.online = online
        
        //TODO: Change to online
        if (selectedUADevice == nil || online){
            selectedUADevice = uaDevice
            viewController?.onDeviceRefresh()
            viewController?.onInputRefresh()
        }
    }
    
    func addInput (devId: String, inputId:String, info:JsonResponse<InputProperties, InputChildren>, children: [String]){
        uaDevices[devId]?.addInput(id: inputId, info:info, children:children)
        
        viewController?.onInputRefresh()
    }
    
    func onConnectionChange(connected:Bool){
        viewController?.setConnected(connected: connected)
    }

}

