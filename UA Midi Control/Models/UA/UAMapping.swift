//
//  Device.swift
//  Focusrite Midi Control
//
//  Created by Antonio-Radu Varga on 08.07.18.
//  Copyright © 2018 Antonio-Radu Varga. All rights reserved.
//

import Cocoa

//let InputJsonResponse: Codable.Type = JsonResponse<InputProperties, InputChildren>

struct UAMapping: Codable {
    var deviceId: String = ""
    var inputId: String = ""
    var mix: String = ""
  
    init (deviceId:String, inputId:String, mix:String){
        self.mix = mix
        self.deviceId = deviceId
        self.inputId = inputId
    }
    
    init (fromStr: String){
        let strings: [String] = fromStr.components(separatedBy: "-")
        self.mix = strings[0]
        self.deviceId = strings[1]
        self.inputId = strings[2]
    }
    
    func getEncodeStr() -> String{
        return mix + "-" + deviceId + "-" + inputId
    }
}
