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
    @IBOutlet weak var mixTableView: NSTableView!
    @IBOutlet weak var outputsTableView: NSTableView!
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
            appDelegate.selectedUADevice?.removeAllMidiMaps()
            mixTableView.reloadData()
        }
    }
    
    @IBAction func onStopMidiClick(_ sender: NSButton) {
        if(appDelegate.isMidiMapping){
            let myString = "Start Midi Map"
            let myAttribute = [ NSAttributedStringKey.foregroundColor: NSColor.black ]
            let myAttrString = NSAttributedString(string: myString, attributes: myAttribute)
            sender.attributedTitle = myAttrString
            mixTableView.reloadData()
            
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
            if(self.mixTableView.selectedRow != -1){
                let nrRows: Int = self.mixTableView.numberOfRows - 1
                let rows: IndexSet =  IndexSet(0...nrRows)
                self.mixTableView.reloadData(forRowIndexes: rows, columnIndexes: [1])
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
            self.mixTableView.reloadData()
            self.outputsTableView.reloadData()
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification){
        let tableView:NSTableView? = notification.object as? NSTableView
        if(tableView == mixTableView){
            if (appDelegate.isMidiMapping && mixTableView.selectedRow > -1){
                let input = getInputs()[mixTableView.selectedRow]
                appDelegate.selectedMidiMapIndex = mixTableView.selectedRow
                appDelegate.selectedMidiMapId = input.id
            }
        }else {
            if (outputsTableView.selectedRow > -1){
            
                mixTableView.reloadData()
            }
        }
    }
    
    func getInputs() -> [UAItem]{
        var inputs: [UAItem] = (appDelegate.selectedUADevice?.items.map({$0.value}))!
        inputs = inputs.sorted(by: { $0.id < $1.id })
        
        return inputs
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        var count = 0
        if(tableView == mixTableView){
            if (appDelegate.selectedUADevice != nil){
                count = (appDelegate.selectedUADevice?.items.keys.count)!
            } else {
                count = 0
            }
        } else{
            count = 1
        }
        return count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if(tableView == mixTableView){
            let inputs: [UAItem] = getInputs()
            
            return inputs[row]
        }else {
            return ["Inputs"][row]
        }
    }
    
}

