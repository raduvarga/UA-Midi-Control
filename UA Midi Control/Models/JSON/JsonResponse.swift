//
//  Device.swift
//  Focusrite Midi Control
//
//  Created by Antonio-Radu Varga on 08.07.18.
//  Copyright © 2018 Antonio-Radu Varga. All rights reserved.
//

import Cocoa

////////////////////////////////
struct BoolValue : Codable {
    let type: String
    let value: Bool
}

struct StringValue : Codable {
    var type: String
    var value: String
}

////////////////////////////////


struct StringDefaultValue : Codable {
    var type: String
    var `default`: String
    var value: String
}

struct InputChildren : Codable {
}

struct InputProperties : Codable {
    var `Type`: StringValue
    var Name: StringDefaultValue
}

struct DeviceChildren : Codable {
}

struct DeviceProperties : Codable {
    var `Type`: StringValue
    var DeviceOnline: BoolValue
    var DeviceName: StringValue
}

////////////////////////////////
struct JsonData <Pr:Codable, Ch:Codable> : Codable {
    var properties: Pr
    var children: Ch
    
}

struct JsonResponse <Pr:Codable, Ch:Codable> : Codable {
    var path: String
    var data: JsonData <Pr, Ch>
}

struct BasicJsonResponse : Codable {
    var path: String
}
