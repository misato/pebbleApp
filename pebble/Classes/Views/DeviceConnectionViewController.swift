//
//  DeviceConnectionViewController.swift
//  pebble
//
//  Created by Ester Sanchez on 14/12/2016.
//  Copyright © 2016 misato. All rights reserved.
//

import UIKit

class DeviceConnectionViewController: UIViewController, BluetoothManagerDelegate {
    
    static let storyboardID = "deviceConnectionViewControllerID"
    
    private var btManager = BluetoothManager.sharedInstance
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var pairDeviceButton: UIButton!
    @IBOutlet weak var connectionTextLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var deviceName: String? {
        didSet {
            deviceNameLabel?.text = deviceName
        }
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        deviceNameLabel?.text = deviceName
        activityIndicator.startAnimating()
        btManager.delegate = self
        pairDeviceButton.isEnabled = false
    }
    
    // MARK: - Actions
    
    @IBAction func didTapDisconnect(_ sender: Any) {
        btManager.disconnectFromDevice()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapPairDevice(_ sender: Any) {
        btManager.doPairingWithDevice()
    }
    
    // MARK: - Bluetooth Manager Delegate
    
    func bluetoothManager(_ manager: BluetoothManager, didFindDeviceNamed deviceName: String) {  }
    
    func bluetoothManager(_ manager: BluetoothManager, hadAnError error: BluetoothManagerError) {
        let alert = UIAlertController(title: "Bluetooth Error", message: error.description, preferredStyle: .alert)
        alert.show(self, sender: nil)
    }
    
    func bluetoothManagerDidFinishedConnectingWithDevice(_ manager: BluetoothManager) {
        connectionTextLabel.text = "Conected to"
        activityIndicator.stopAnimating()
        pairDeviceButton.isEnabled = true
    }

}
