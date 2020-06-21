//
//  Device.swift
//  Focusrite Midi Control
//
//  Created by Antonio-Radu Varga on 08.07.18.
//  Copyright © 2018 Antonio-Radu Varga. All rights reserved.
//

import Cocoa

//let InputJsonResponse: Codable.Type = JsonResponse<InputProperties, InputChildren>

@objc (UAInput)
class UAInput: NSObject {
    
    @objc dynamic var parentId: String = ""
    @objc dynamic var id: String = ""
    @objc dynamic var defaultName: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var printName: String = ""
    @objc dynamic var children: [String] = []
    
    @objc dynamic var midiMessageForPrinting: String = ""
    
    init (devId:String, id:String, info: JsonResponse<InputProperties, InputChildren>, children:[String]){
        super.init()
        self.parentId = devId
        self.id = id
        self.defaultName = info.data.properties.Name.default
        self.name = info.data.properties.Name.value
        self.printName = name + " (" + defaultName + ")"
        self.children = children
    }
    
    func hasPreamps () -> Bool{
        return children.contains("preamps")
    }
    
    func setMidiMessageForPrinting(str: String){
        midiMessageForPrinting = str
    }
    
}
