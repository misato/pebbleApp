//
//  BluetoothManager.swift
//  pebble
//
//  Created by Ester Sanchez on 09/12/2016.
//  Copyright © 2016 misato. All rights reserved.
//

import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager = CBCentralManager()
    var peripheral: CBPeripheral?
    var keepScanning = false

    // define our scanning interval times
    let timerPauseInterval:TimeInterval = 10.0
    let timerScanInterval:TimeInterval = 2.0
    
    
    override init() {
        super.init()
        centralManager.delegate = self
    }
    
    
    //MARK: - Scanning
    
    @objc func startScanning() {
        if keepScanning {
            print("Start scanning...")
            _ = Timer(timeInterval: timerScanInterval, target: self, selector: #selector(pauseScan), userInfo: nil, repeats: false)
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    
    @objc func pauseScan() {
        print("Stop scanning...")
        _ = Timer(timeInterval: timerPauseInterval, target: self, selector: #selector(startScanning), userInfo: nil, repeats: false)
        centralManager.stopScan()
    }
    
    
    //MARK: -  Central Manager Delegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        keepScanning = false
        switch central.state {
            case .poweredOn:
                print("Bluetooth is powered on")
                keepScanning = true
                startScanning()
            case .poweredOff:
                print("Bluetooth on this device is currently powered off.")
            case .unsupported:
                print("This device does not support Bluetooth Low Energy.")
            case .unauthorized:
                print("This app is not authorized to use Bluetooth Low Energy.")
            case .resetting:
                print("The BLE Manager is resetting; a state update is pending.")
            case .unknown:
                print("The state of the BLE Manager is unknown.")
        }
    }
    
    //  Invoked when the central manager is about to be restored by the system.
//    func centralManager(_ central: CBCentralManager, willRestoreState: [String : Any]) {
//        
//    }
    
    //  Invoked when a connection is successfully created with a peripheral.
    func centralManager(_ central: CBCentralManager, didConnect: CBPeripheral) {
        print("Connected to peripheral! ")
        
        // Now that we've successfully connected to the SensorTag, let's discover the services.
        // - NOTE:  we pass nil here to request ALL services be discovered.
        //          If there was a subset of services we were interested in, we could pass the UUIDs here.
        //          Doing so saves battery life and saves time.
        didConnect.discoverServices(nil)
    }

    //  Invoked when an existing connection with a peripheral is torn down.
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral: CBPeripheral, error: Error?) {
        print("Disconnected from the peripheral ")
    }
    
    //  Invoked when the central manager fails to create a connection with a peripheral.
    func centralManager(_ central: CBCentralManager, didFailToConnect: CBPeripheral, error: Error?) {
        print("Error connecting to the peripheral! \(error.debugDescription)")
    }
    
    //  Invoked when the central manager discovers a peripheral while scanning.
    func centralManager(_ central: CBCentralManager, didDiscover: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
         print("centralManager didDiscoverPeripheral - CBAdvertisementDataLocalNameKey is \"\(CBAdvertisementDataLocalNameKey)\"")
        // Retrieve the peripheral name from the advertisement data using the "kCBAdvDataLocalName" key
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            print("NEXT PERIPHERAL NAME: \(peripheralName)")
            print("NEXT PERIPHERAL UUID: \(didDiscover.identifier.uuidString)")
            keepScanning = false
            peripheral = didDiscover
            peripheral!.delegate = self
            
            centralManager.connect(peripheral!, options: nil)
        }
    
    }
    
//    //  Invoked when the central manager retrieves a list of peripherals currently connected to the system.
//    func centralManager(_ central: CBCentralManager, didRetrieveConnectedPeripherals: [CBPeripheral]) {
//        
//    }
//    
//    //  Invoked when the central manager retrieves a list of known peripherals.
//    func centralManager(_ central: CBCentralManager, didRetrievePeripherals: [CBPeripheral]) {
//        
//    }
    
    
    //MARK: - CBPeripheralDelegate methods
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print("ERROR DISCOVERING SERVICES: \(error?.localizedDescription)")
            return
        }
        
        // Core Bluetooth creates an array of CBService objects —- one for each service that is discovered on the peripheral.
        if let services = peripheral.services {
            for service in services {
                print("Discovered service \(service)")
                // If we found either the temperature or the humidity service, discover the characteristics for those services.
//                if (service.UUID == CBUUID(string: Device.TemperatureServiceUUID)) ||
//                    (service.UUID == CBUUID(string: Device.HumidityServiceUUID)) {
                    peripheral.discoverCharacteristics(nil, for: service)
//                }
            }
        }
    
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print("ERROR DISCOVERING CHARACTERISTICS: \(error?.localizedDescription)")
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                print("Characteristic \(characteristic)")
            }
        }
    }
    
}
