//
//  ViewController.swift
//  pebble
//
//  Created by Ester Sanchez on 09/12/2016.
//  Copyright © 2016 misato. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var btManager :BluetoothManager?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    @IBAction func didTapConnect(_ sender: Any) {
        if btManager == nil {
            btManager = BluetoothManager()
        }
        
        if let btManager = btManager {
            btManager.startScanning()
        }
    }

}

