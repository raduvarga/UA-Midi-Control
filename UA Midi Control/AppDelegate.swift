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
    
    // various vars
    var isMidiMapping:Bool = false
    var selectedMidiMapId = ""
    var selectedMidiMapIndex = -1
    
    override init(){
        super.init()
        tcpClient = TCPListener(address: SERVER_HOST, port: SERVER_PORT)
        midiListener = MidiListener()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        tcpClient?.start()
        midiListener?.start()
        
        UserDefaults.standard.register(defaults: ["volumeLimit" : "0"])
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func onMidiMessageReceived (midiMessage: MidiMessage){
        if(selectedUADevice != nil){
            if(isMidiMapping){
                let ids: [String] = [selectedMidiMapId]
                selectedUADevice?.setMidiMap(ids: ids, midiMessage: midiMessage)
                
                viewController?.setMidiMapping();
            }else{
                let midiItems: [UAItem]? = selectedUADevice?.findItems(midiMessage: midiMessage)
                if(midiItems != nil){
                    for midiItem in midiItems! {
                        tcpClient?.sendVolMessage(item: midiItem, volume: midiMessage.value)
                    }
                }
            }
        }
    }
    
    func addDevice (id:String, info:JsonResponse<DeviceProperties, DeviceChildren>){
        guard let uaDevice:UADevice = UADevice(id: id, info:info) else {return}
        
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
    
    func addInput (devId: String, inputId:String, info:JsonResponse<InputProperties, InputChildren>){
        uaDevices[devId]?.addInput(id: inputId, info:info)
        
        viewController?.onInputRefresh()
    }
    
    func onConnectionChange(connected:Bool){
        viewController?.setConnected(connected: connected)
    }

}

