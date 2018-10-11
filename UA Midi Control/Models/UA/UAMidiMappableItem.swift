//
//  MidiMappableItem.swift
//  Focusrite Midi Control
//
//  Created by Antonio-Radu Varga on 09.07.18.
//  Copyright © 2018 Antonio-Radu Varga. All rights reserved.
//

import Cocoa

@objc (UAMidiMappableItem)
class UAMidiMappableItem: NSObject {
    @objc var midiMapMessage: MidiMessage = MidiMessage()
    
    override init(){
        super.init()
    }
}
