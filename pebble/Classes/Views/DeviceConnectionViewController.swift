//
//  DeviceConnectionViewController.swift
//  pebble
//
//  Created by Ester Sanchez on 14/12/2016.
//  Copyright © 2016 misato. All rights reserved.
//

import UIKit

class DeviceConnectionViewController: UIViewController {
    
    static let storyboardID = "deviceConnectionViewControllerID"
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    
    var deviceName: String? {
        didSet {
            deviceNameLabel?.text = deviceName
        }
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        deviceNameLabel?.text = deviceName
    }
    
    // MARK: - Actions
    
    @IBAction func didTapDisconnect(_ sender: Any) {
        BluetoothManager.sharedInstance.disconnectFromDevice()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapPairDevice(_ sender: Any) {
        
    }
}
