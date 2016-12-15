//
//  BluetoothManager.swift
//  pebble
//
//  Created by Ester Sanchez on 14/12/2016.
//  Copyright © 2016 misato. All rights reserved.
//

import Foundation
import CoreBluetooth

private struct PebbleBLE {
    static let serviceUUID = CBUUID(string:"0000fed9-0000-1000-8000-00805f9b34fb")
    static let connectivityCharacteristicUUID = CBUUID(string:"00000001-328E-0FBB-C642-1AA6699BDADA")
    static let pairingTriggerCharacteristicUUID = CBUUID(string:"00000002-328E-0FBB-C642-1AA6699BDADA")
    static let mtuCharacteristicUUID = CBUUID(string:"00000003-328E-0FBB-C642-1AA6699BDADA")
    static let connectionParametersCharacteristicUUID = CBUUID(string:"00000005-328E-0FBB-C642-1AA6699BDADA")
    static let characteristicConfiguratorDescriptor = CBUUID(string:"00002902-0000-1000-8000-00805f9b34fb")
}

protocol BluetoothManagerDelegate {
    func bluetoothManager(_ manager: BluetoothManager, didFindDeviceNamed deviceName: String)
    func bluetoothManager(_ manager: BluetoothManager, hadAnError error: BluetoothManagerError)
}

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var delegate: BluetoothManagerDelegate?
    
    static let sharedInstance = BluetoothManager()
    
    private var centralManager = CBCentralManager()
    private var peripheral: CBPeripheral?
    private var keepScanning = false
    private var devicesList: [String: CBPeripheral] = [:]
    
    // define our scanning interval times
    private let timerPauseInterval:TimeInterval = 10.0
    private let timerScanInterval:TimeInterval = 2.0
    
    
    private override init() {
        super.init()
        centralManager.delegate = self
    }
    
    
    //MARK: - Scanning
    
    @objc func startScanning() {
        if keepScanning {
            print("Start scanning...")
            _ = Timer(timeInterval: timerScanInterval, target: self, selector: #selector(stopScanning), userInfo: nil, repeats: false)
            centralManager.scanForPeripherals(withServices: [PebbleBLE.serviceUUID], options: nil)
        }
    }
    
    
    @objc func stopScanning() {
        print("Stop scanning...")
        if keepScanning {
            _ = Timer(timeInterval: timerPauseInterval, target: self, selector: #selector(startScanning), userInfo: nil, repeats: false)
        }
        centralManager.stopScan()
    }
    
    // MARK: - Connection
    func connectToDeviceNamed(_ name: String) {
        guard let peripheral = devicesList[name] else {
            return
        }
        keepScanning = false
        stopScanning()
        self.peripheral = peripheral
        self.peripheral?.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnectFromDevice() {
        guard let peripheral = self.peripheral else {
            delegate?.bluetoothManager(self, hadAnError: BluetoothManagerError(message: "There is no peripheral saved", type: .genericError))
            return
        }
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    //MARK: -  Central Manager Delegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        keepScanning = false
        var errorMessage: String?
        switch central.state {
        case .poweredOn:
            errorMessage = nil
            print("Bluetooth is powered on.")
            keepScanning = true
        case .poweredOff:
            errorMessage = "Bluetooth on this device is currently powered off."
        case .unsupported:
            errorMessage = "This device does not support Bluetooth Low Energy."
        case .unauthorized:
            errorMessage = "This app is not authorized to use Bluetooth Low Energy."
        case .resetting:
            errorMessage = "The BLE Manager is resetting; a state update is pending."
        case .unknown:
            errorMessage = "The state of the BLE Manager is unknown."
        }
        
        if let errorMessage = errorMessage {
            delegate?.bluetoothManager(self, hadAnError: BluetoothManagerError(message: errorMessage, type: .scanUpdateError))
        }
    }
    
    
    
    //  Invoked when a connection is successfully created with a peripheral.
    func centralManager(_ central: CBCentralManager, didConnect: CBPeripheral) {
        print("Connected to peripheral! ")
        didConnect.discoverServices([PebbleBLE.serviceUUID])
    }
    
    //  Invoked when an existing connection with a peripheral is torn down.
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral: CBPeripheral, error: Error?) {
        print("Disconnected from the peripheral ")
        peripheral = nil
    }
    
    //  Invoked when the central manager fails to create a connection with a peripheral.
    func centralManager(_ central: CBCentralManager, didFailToConnect: CBPeripheral, error: Error?) {
        let message = "Error connecting to the peripheral! \(error.debugDescription)"
        delegate?.bluetoothManager(self, hadAnError: BluetoothManagerError(message: message, type: .connectionError))
    }
    
    //  Invoked when the central manager discovers a peripheral while scanning.
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            print("centralManager didDiscoverPeripheral \(peripheralName)")
            devicesList[peripheralName] = peripheral
            delegate?.bluetoothManager(self, didFindDeviceNamed: peripheralName)
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
            let message = "Error discovering services: \(error?.localizedDescription)"
            delegate?.bluetoothManager(self, hadAnError: BluetoothManagerError(message: message, type: .discoverServicesError))
            return
        }
        
        // Core Bluetooth creates an array of CBService objects —- one for each service that is discovered on the peripheral.
        if let services = peripheral.services {
            for service in services {
                print("Discovered service \(service)")
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            let message = "Error discovering characteristics: \(error?.localizedDescription)"
            delegate?.bluetoothManager(self, hadAnError: BluetoothManagerError(message: message, type: .discoverCharacteristicsError))
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                print("Characteristic \(characteristic)")
            }
        }
    }

}
