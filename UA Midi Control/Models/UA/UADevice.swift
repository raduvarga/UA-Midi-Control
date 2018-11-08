//
//  Device.swift
//  Focusrite Midi Control
//
//  Created by Antonio-Radu Varga on 08.07.18.
//  Copyright © 2018 Antonio-Radu Varga. All rights reserved.
//

import Cocoa

//let DeviceJsonResponse: Codable.Type = JsonResponse<DeviceProperties, DeviceChildren>

@objc (UADevice)
class UADevice: NSObject {
   
    @objc var id: String = ""
    @objc var name: String = ""
    @objc var online: Bool = false
    
    @objc var inputs: [String : UAInput] = [:]
    
    init(id:String, info: JsonResponse<DeviceProperties, DeviceChildren>){
        super.init()
        self.id = id
        self.name = info.data.properties.DeviceName.value
        self.online = info.data.properties.DeviceOnline.value
    }
    
    func addInput(id:String, info:JsonResponse<InputProperties, InputChildren>, children: [String]){
        let newItem = UAInput(devId: self.id, id: id, info: info, children: children)
        
        inputs[id] = newItem
    }
}
