//
//  Device.swift
//  Focusrite Midi Control
//
//  Created by Antonio-Radu Varga on 08.07.18.
//  Copyright © 2018 Antonio-Radu Varga. All rights reserved.
//

import Cocoa

//let InputJsonResponse: Codable.Type = JsonResponse<InputProperties, InputChildren>

@objc (UAItem)
class UAItem: UAMidiMappableItem {
    
    @objc dynamic var parentId: String = ""
    @objc dynamic var id: String = ""
    @objc dynamic var defaultName: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var printName: String = ""
    
    override init(){
        super.init()
    }
    
    init (devId:String, id:String, info: JsonResponse<InputProperties, InputChildren>){
        super.init()
        self.parentId = devId
        self.id = id
        self.defaultName = info.data.properties.Name.default
        self.name = info.data.properties.Name.value
        self.printName = name + " (" + defaultName + ")"
    }
    
    
}
