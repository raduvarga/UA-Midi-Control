//
//  MidiListener.swift
//  Focusrite Midi Control
//
//  Created by Antonio-Radu Varga on 08.07.18.
//  Copyright © 2018 Antonio-Radu Varga. All rights reserved.
//

import Cocoa
import CoreMIDI

let ENABLE_LOGGING = false

let appDelegate:AppDelegate  = NSApplication.shared.delegate as! AppDelegate

let CC:Int = 176
let CCMax:Int = 176 + 11
let Note:Int = 144
let NoteMax:Int = 144 + 11

let SLEEP_TIME:UInt32 = 150000

var client:MIDIClientRef = MIDIClientRef()
var inPort:MIDIPortRef = MIDIPortRef()

var messageCache:[String : MidiMessage] = [:]

// read incoming MIDI
func MyMIDIReadProc(pktList: UnsafePointer<MIDIPacketList>,
                    readProcRefCon: UnsafeMutableRawPointer?, srcConnRefCon: UnsafeMutableRawPointer?) -> Void
{
    let packetList:MIDIPacketList = pktList.pointee
    let packet:MIDIPacket = packetList.packet
    
    let first:Int = Int(packet.data.0)
    let second:Int = Int(packet.data.1)
    let third:Int = Int(packet.data.2)
    
    if(ENABLE_LOGGING){
        print("midi:", first,  second, third)
    }
    
    let midiMessage = MidiMessage(type: first, nr: second, value: third)
    
    if midiMessage.isCcMessage() {
        newMidiMessageReceived(midiMessage: midiMessage);
    }
}

func newMidiMessageReceived(midiMessage: MidiMessage){
    let writeNewMidiMessage: DispatchWorkItem = DispatchWorkItem {
         messageCache[midiMessage.asStr] = midiMessage
    }
    
    DispatchQueue.global().sync(execute: writeNewMidiMessage)
}

// detect when MIDI instruments connect/disconnect
func MyMIDINotifyProc(message: UnsafePointer<MIDINotification>, refCon: UnsafeMutableRawPointer?){
    let notification: MIDINotification = message.pointee
    let notificationID:MIDINotificationMessageID = notification.messageID
    
    switch notificationID {
        case MIDINotificationMessageID.msgObjectAdded:
            print("Midi instrument added")
            connectMidiSources()
        case MIDINotificationMessageID.msgObjectRemoved:
            print("Midi instrument removed")
        default: break
        }
}

// connect MIDI sources to our virtual input port
func connectMidiSources (){
    let sourceCount = MIDIGetNumberOfSources()
    for count in 0...sourceCount {
        var src:MIDIEndpointRef = MIDIGetSource(count)
        MIDIPortConnectSource (inPort, src, &src)
    }
}

class MidiListener: NSObject {
    
    var readingWorkItem: DispatchWorkItem?
    
    override init() {
        super.init()
    }
   
    func start() {
        MIDIClientCreate("Core MIDI Callback Demo" as CFString, MyMIDINotifyProc, nil, &client)
        MIDIInputPortCreate(client, "Input port" as CFString, MyMIDIReadProc, nil, &inPort)
        
        connectMidiSources();
        processMidiMessages();
        
        print ("Connected to MIDI")
    }
    
    func processMidiMessages(){
        readingWorkItem = DispatchWorkItem {
            if(messageCache.count > 0){
                for (midiStr, midiMessage) in messageCache {
                    if(ENABLE_LOGGING){
                        print("processMidiMessage:", midiStr, midiMessage.value)
                    }
                    messageCache.removeValue(forKey: midiStr)
                    appDelegate.onMidiMessageReceived(midiMessage: midiMessage)
                }
            }
            usleep(SLEEP_TIME)
            DispatchQueue.global().async(execute: self.readingWorkItem!)
        }
        
        DispatchQueue.global().async(execute: readingWorkItem!)
    }
}
