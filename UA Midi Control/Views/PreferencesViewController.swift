//
//  PreferencesController.swift
//  Focusrite Midi Control
//
//  Created by Antonio-Radu Varga on 08.07.18.
//  Copyright © 2018 Antonio-Radu Varga. All rights reserved.
//

import Cocoa

class PreferencesViewController: NSViewController {

    @IBOutlet weak var volumeLimitDropdown: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.size.height)
            }
    @IBAction func onVolumeLimitDropdownChange(_ sender: Any) {
    }
    
}
