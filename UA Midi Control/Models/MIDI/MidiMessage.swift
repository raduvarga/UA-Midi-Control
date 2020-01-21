//
//  MidiMessage.swift
//  Focusrite Midi Control
//
//  Created by Antonio-Radu Varga on 09.07.18.
//  Copyright © 2018 Antonio-Radu Varga. All rights reserved.
//

import Cocoa

@objc (MidiMessage)
class MidiMessage: NSObject {
    @objc var type: Int = -1
    @objc var nr: Int = -1
    @objc var value: Int = -1
    @objc var asStr: String = ""
    @objc var printStr: String = ""
    
    override init(){
        super.init()
        toStr()
    }
    
    init(midiStr: String){
        super.init()
        let splits = midiStr.split(separator: "-")
        if (splits.count > 0){
            self.type = Int(splits[0])!
            self.nr = Int(splits[1])!
            toStr()
        }else{
            clear()
            toStr()
        }
    }
    
    init(type: Int, nr: Int){
        super.init()
        self.type = type
        self.nr = nr
        self.asStr = ""
        toStr()
    }
    
    init(type: Int, nr: Int, value: Int){
        super.init()
        self.type = type
        self.nr = nr
        self.value = value
        self.asStr = ""
        toStr()
    }
    
    func clear(){
        self.type = -1
        self.nr = -1
        self.value = -1
        self.asStr = ""
        self.printStr = ""
    }
    
    func copy(midiMessage: MidiMessage){
        self.asStr = midiMessage.asStr
        self.type = midiMessage.type
        self.nr = midiMessage.nr
        self.value = midiMessage.value
        self.printStr = midiMessage.printStr
    }
    
    func copy() -> MidiMessage{
        return MidiMessage(type: type, nr: nr, value: value)
    }

    func isCcMessage() -> Bool{
        return (type >= CC) && (type <= CCMax)
    }
    
    func getMidiChannel () -> Int{
        if isCcMessage (){
            return type - CC + 1
        }
        return 0
    }
    
    func toStr() {
        if(!isEmpty()){
            asStr =  String(format: "%d-%d", type, nr)
        }
        getEncodeStr()
    }
    
    func getEncodeStr () -> String{
        if(!isEmpty()){
            var messageType:String = ""
            if (isCcMessage()){
                messageType = "CC"
            }
            let midiChannel:Int = getMidiChannel()
            
            printStr =  String(format: "%d-%@-%d", midiChannel, messageType, nr)
        }
        return printStr
    }
    
    func isEmpty() -> Bool{
        return type == -1 && nr == -1
    }
}
