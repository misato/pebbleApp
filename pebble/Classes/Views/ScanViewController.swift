//
//  ViewController.swift
//  pebble
//
//  Created by Ester Sanchez on 09/12/2016.
//  Copyright © 2016 misato. All rights reserved.
//

import UIKit

class ScanViewController: UIViewController, BluetoothManagerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var devicesTableView: UITableView!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private let devicesTableViewCellIdentifier = "devicesTableViewCellIdentifier"
    
    private var btManager = BluetoothManager.sharedInstance
    private var deviceNames: [String] = []

    private var isScanning = false
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        devicesTableView.register(UITableViewCell.self, forCellReuseIdentifier: devicesTableViewCellIdentifier)
        devicesTableView.isHidden = true
        activityIndicator.stopAnimating()
        btManager.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Actions
    
    @IBAction func didTapConnect(_ sender: Any) {
            if !isScanning {
                btManager.startScanning()
                scanButton.setTitle("Scanning...", for: .normal)
                activityIndicator.startAnimating()
            }
            else {
                btManager.stopScanning()
                scanButton.setTitle("Scan BT devices", for: .normal)
                activityIndicator.stopAnimating()
            }
        
            isScanning = !isScanning
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let deviceName = deviceNames[indexPath.row]
        btManager.connectToDeviceNamed(deviceName)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let deviceConnectionVC = storyboard.instantiateViewController(withIdentifier: DeviceConnectionViewController.storyboardID) as! DeviceConnectionViewController
        deviceConnectionVC.deviceName = deviceName
        present(deviceConnectionVC, animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDatasource
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: devicesTableViewCellIdentifier, for: indexPath)
        cell.textLabel?.text = deviceNames[indexPath.row]
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deviceNames.count
    }
    
    // MARK: - BluetoothManagerDelegate
    
    func bluetoothManager(_ manager: BluetoothManager, didFindDeviceNamed deviceName: String) {
        if !deviceNames.contains(deviceName) {
            deviceNames.append(deviceName)
            // This should be done only once!
            devicesTableView.isHidden = false
            devicesTableView.reloadData()
        }
    }
    
    func bluetoothManager(_ manager: BluetoothManager, hadAnError error: BluetoothManagerError) {
        let alert = UIAlertController(title: "Bluetooth Error", message: error.description, preferredStyle: .alert)
        alert.show(self, sender: nil)
    }

}

