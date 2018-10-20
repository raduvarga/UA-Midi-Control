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
    
    @objc var items: [String : UAItem] = [:]
    @objc var midiMaps: [String : [String]] = [:]
    
    init(id:String, info: JsonResponse<DeviceProperties, DeviceChildren>){
        super.init()
        self.id = id
        self.name = info.data.properties.DeviceName.value
        self.online = info.data.properties.DeviceOnline.value
        recreateMidiMaps();
    }
    
    func addInput(id:String, info:JsonResponse<InputProperties, InputChildren>){
        let oldItem = items[id]
        let newItem = UAItem(devId: self.id, id: id, info: info)
       
        if (oldItem != nil){
            newItem.midiMapMessage = (oldItem?.midiMapMessage.copy())!
        }
        
        items[id] = newItem
    }
   
    func recreateMidiMaps(){
        let midiMapsPreferences = UserDefaults.standard.dictionary(forKey: "midiMaps")
        if (midiMapsPreferences != nil){
            midiMaps = midiMapsPreferences as! [String : [String]]
            
            for midiMap in midiMaps {
                let midiStr:String = midiMap.key
                let ids:[String] = midiMap.value
                
                for id in ids{
//                    print("id ", id)
                    let item:UAItem? = items[id]
                    
                    if (item != nil){
//                        print("item ", item)
                        item?.midiMapMessage = MidiMessage(midiStr: midiStr)
                    } else{
                        let item = UAItem()
                        item.midiMapMessage = MidiMessage(midiStr: midiStr)
                        items[id] = item
                    }
                }
            }
        }
    }
    
    func setMidiMap(ids: [String], midiMessage: MidiMessage){
        // remove old midi mapping
        let midiStr = midiMessage.asStr
        removeMidiMap(midiStr: midiStr)
        
        midiMaps[midiMessage.asStr] = ids
        UserDefaults.standard.set(midiMaps, forKey: "midiMaps")
        
        for id in ids{
            guard  let item:UAItem = items[id] else {return}
            item.midiMapMessage.copy(midiMessage: midiMessage)
        }
    }
    
    func removeMidiMap(midiStr: String){
        guard let oldMappingIds:[String] = midiMaps[midiStr] else {return}
        
        for oldMappingId in oldMappingIds{
            guard let oldMappingItem: UAItem = items[oldMappingId] else {return}
            oldMappingItem.midiMapMessage.clear()
            midiMaps.removeValue(forKey: midiStr)
        }
    }
    
    func removeAllMidiMaps(){
        for midiMap in midiMaps {
            removeMidiMap(midiStr: midiMap.key)
        }
    }
    
    func findItems(midiMessage: MidiMessage) -> [UAItem]?{
        var result: [UAItem] = []
        guard let ids:[String] = midiMaps[midiMessage.asStr] else {return result}
        
        for id in ids{
            result.append(items[id]!)
        }
        return result
    }
}
