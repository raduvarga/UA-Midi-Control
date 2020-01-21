//
//  ViewController.swift
//  Focusrite Midi Control
//
//  Created by Antonio-Radu Varga on 07.07.18.
//  Copyright © 2018 Antonio-Radu Varga. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate {
    
    let backgroundColor : CGColor = CGColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.0)
   
    @IBOutlet weak var mixLabel: NSTextField!
    @IBOutlet weak var connectedLabel: NSTextField!
    @IBOutlet weak var deviceNameLabel: NSTextField!
    @IBOutlet weak var valuesTableView: NSTableView!
    @IBOutlet weak var mixesTableView: NSTableView!
    @IBOutlet weak var creditsLabel: NSTextField!
    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var onlineLabel: NSTextField!
    var appDelegate:AppDelegate = NSApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.wantsLayer = true
        
        appDelegate.viewController = self
        let appVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        versionLabel.stringValue = "version: " + appVersion
    }
    
    override func awakeFromNib() {
        if self.view.layer != nil {
            self.view.layer?.backgroundColor = backgroundColor
        }
    }
    
    override func viewDidAppear() {
        self.view.window?.delegate = self
    }
    
    private func windowShouldClose(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @IBAction func onResetMidiMappings(_ sender: Any) {
        if(appDelegate.selectedUADevice != nil){
            UserDefaults.standard.set([:], forKey: "midiMaps")
            appDelegate.removeAllMidiMaps()
            valuesTableView.reloadData()
        }
    }
    
    @IBAction func onStopMidiClick(_ sender: NSButton) {
        if(appDelegate.isMidiMapping){
            let myString = "Start Midi Map"
            let myAttribute = [ NSAttributedStringKey.foregroundColor: NSColor.black ]
            let myAttrString = NSAttributedString(string: myString, attributes: myAttribute)
            sender.attributedTitle = myAttrString
            valuesTableView.reloadData()
            
            appDelegate.isMidiMapping = false
        }else{
            let myString = "Stop Midi Map"
            let myAttribute = [ NSAttributedStringKey.foregroundColor: NSColor.red ]
            let myAttrString = NSAttributedString(string: myString, attributes: myAttribute)
            sender.attributedTitle = myAttrString
        
            appDelegate.isMidiMapping = true
        }
    }
    
    func setMidiMapping(){
        DispatchQueue.main.async{
            if(self.valuesTableView.selectedRow != -1){
                let nrRows: Int = self.valuesTableView.numberOfRows - 1
                let rows: IndexSet =  IndexSet(0...nrRows)
                self.valuesTableView.reloadData(forRowIndexes: rows, columnIndexes: [1])
            }
        }
    }
    func setConnected(connected:Bool){
        DispatchQueue.main.async{
            self.connectedLabel.textColor = connected ?  NSColor.green: NSColor.red
        }
    }
    
    func onDeviceRefresh(){
        DispatchQueue.main.async{
            self.deviceNameLabel.stringValue = (self.appDelegate.selectedUADevice?.name)!
            if (self.appDelegate.selectedUADevice?.online)! {
                self.onlineLabel.stringValue =  "Online"
                self.onlineLabel.textColor = NSColor.green
            }else{
                self.onlineLabel.stringValue = "Offline"
                self.onlineLabel.textColor = NSColor.red
            }
        }
    }
    
    func onInputRefresh(){
        DispatchQueue.main.async{
            self.valuesTableView.reloadData()
            self.mixesTableView.reloadData()
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification){
        let tableView:NSTableView? = notification.object as? NSTableView
        if(tableView == valuesTableView){
            if (appDelegate.isMidiMapping && valuesTableView.selectedRow > -1){
                let input = getValues()[valuesTableView.selectedRow]
                appDelegate.selectedMidiMapId = input.id
            }
        }else {
            if (mixesTableView.selectedRow > -1){
                appDelegate.selectedMix = appDelegate.mixes[mixesTableView.selectedRow]
                mixLabel.stringValue = appDelegate.selectedMix
            
                valuesTableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if(tableView == valuesTableView){
            let values: [UAInput] = getValues()
            
            for input in values{
                let midiMessageStr = appDelegate.findMappingMessage(deviceId: input.parentId, inputId: input.id, mix: appDelegate.selectedMix)
                input.setMidiMessageForPrinting(str: midiMessageStr)
            }
            
            return values[row]
        }else {
            return appDelegate.mixes[row]
        }
    }
    
    func getInputs() -> [UAInput]{
        var inputs: [UAInput] = (appDelegate.selectedUADevice?.inputs.map({$0.value}))!
        inputs = inputs.sorted(by: { $0.id < $1.id })
        
        return inputs
    }
    
    func getPreamps() -> [UAInput]{
        let preamps: [UAInput] = (appDelegate.selectedUADevice?.inputs.map({$0.value}).filter({$0.hasPreamps()}))!
        
        return preamps
    }
    
    func getValues() -> [UAInput]{
        switch appDelegate.selectedMix {
        case "Inputs", "Send 0", "Send 1", "Send 2", "Send 3", "Send 4", "Send 5":
            return getInputs()
        case "Gain", "Pad", "Phase", "LowCut", "48V":
            return getPreamps()
        default:
            return getInputs()
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        var count = 0
        if(tableView == valuesTableView){
            if (appDelegate.selectedUADevice != nil){
                count = getValues().count
            } else {
                count = 0
            }
        } else{
            count = appDelegate.mixes.count
        }
        return count
    }
    
}

