//
//  BluetoothManager.swift
//  pebble
//
//  Created by Ester Sanchez on 14/12/2016.
//  Copyright © 2016 misato. All rights reserved.
//

import Foundation
import CoreBluetooth

private struct PebbleGATTClient {
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
    func bluetoothManagerDidFinishedConnectingWithDevice(_ manager: BluetoothManager)
}

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var delegate: BluetoothManagerDelegate?
    
    static let sharedInstance = BluetoothManager()
    
    private let centralManager = CBCentralManager()
    private var peripheral: CBPeripheral?
    private var characteristics: [CBUUID:CBCharacteristic] = [:]
    
    private var canScan = false
    private var devicesList: [String: CBPeripheral] = [:]
    
    private let pebbleServer = PebbleGATTServer()
    
    private let userDefaultsPeripheralUUIDKey = "userDefaultsPeripheralUUIDKey"
    private let userDefaultsPeripheralNameKey = "userDefaultsPeripheralNameKey"
    private let genericDeviceName = "<PEBBLE DEVICE>"
    private var connectViaUserDefaults = false
    
    // MARK: - Init 
    
    private override init() {
        super.init()
        centralManager.delegate = self
    }
    
    
    //MARK: - Scanning
    
    @objc func startScanning() {
        print("Start scanning...")
        
        // check if we already know a device from the UserDefaults
        
        let userDefaults = UserDefaults.standard
        if userDefaults.string(forKey: userDefaultsPeripheralUUIDKey) != nil {
            let deviceName = userDefaults.string(forKey: userDefaultsPeripheralNameKey) ?? genericDeviceName
            delegate?.bluetoothManager(self, didFindDeviceNamed: "[KNOWN] "+deviceName)
            
            connectViaUserDefaults = true
        }
        else {
            centralManager.scanForPeripherals(withServices: [PebbleGATTClient.serviceUUID], options:nil)
            pebbleServer.createService()
        }
        
    }
    
    
    @objc func stopScanning() {
        print("Stop scanning...")
        if !connectViaUserDefaults {
            centralManager.stopScan()
        }

    }
    
//    // MARK: - paired devices
//    
//    func getKnownDevices() {
//        centralManager.retrievePeripherals(withIdentifiers: [])
//    }
//    
    // MARK: - Connection
    
    func connectToDeviceNamed(_ name: String) {
        if connectViaUserDefaults {
            guard let peripheralUUID = UserDefaults.standard.string(forKey: userDefaultsPeripheralUUIDKey), let uuid = UUID(uuidString: peripheralUUID) else {
                delegate?.bluetoothManager(self, hadAnError: BluetoothManagerError(message: "There's no saved UUID", type: .userDefaultsError))
                return
            }
            
            let peripherals = centralManager.retrievePeripherals(withIdentifiers: [uuid])
            if peripherals.isEmpty {
                delegate?.bluetoothManager(self, hadAnError: BluetoothManagerError(message: "No known peripherals with that UUID", type: .userDefaultsError))
            }
            
            self.peripheral = peripherals.first
        }
        else {
            guard let peripheral = devicesList[name] else {
                return
            }
            
            stopScanning()
            self.peripheral = peripheral

        }
        
        self.peripheral?.delegate = self
        centralManager.connect(self.peripheral!, options: nil)
    }
    
    func disconnectFromDevice() {
        guard let peripheral = self.peripheral else {
            delegate?.bluetoothManager(self, hadAnError: BluetoothManagerError(message: "There is no peripheral saved", type: .genericError))
            return
        }
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    // MARK: - Pairing
    
    func doPairingWithDevice() {
        guard let peripheral = peripheral, let pairingTriggerChar = characteristics[PebbleGATTClient.pairingTriggerCharacteristicUUID] else {
            return
        }
//        peripheral.setNotifyValue(true, for: pairingTriggerChar);
        
        if pairingTriggerChar.properties.contains(CBCharacteristicProperties.write) {
            peripheral.writeValue(Data(bytes: [1]), for: pairingTriggerChar, type: .withResponse)
        }
        else {
            print("This seems to be some <4.0 FW Pebble, reading pairing trigger")
            peripheral.readValue(for: pairingTriggerChar)
        }
        
        // save UUID in NSUserDefaults for reconnection
        let userDefaults = UserDefaults.standard
        userDefaults.set(peripheral.identifier.uuidString, forKey: userDefaultsPeripheralUUIDKey)
        userDefaults.set(peripheral.name, forKey: userDefaultsPeripheralNameKey)
    }
    
    
    
    //MARK: -  Central Manager Delegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        canScan = false
        var errorMessage: String?
        switch central.state {
        case .poweredOn:
            errorMessage = nil
            print("Bluetooth is powered on.")
            canScan = true
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
        didConnect.discoverServices([PebbleGATTClient.serviceUUID])
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
    
    //  Invoked when the central manager retrieves a list of peripherals currently connected to the system.
    func centralManager(_ central: CBCentralManager, didRetrieveConnectedPeripherals: [CBPeripheral]) {

    }

    //  Invoked when the central manager retrieves a list of known peripherals.
    func centralManager(_ central: CBCentralManager, didRetrievePeripherals peripherals: [CBPeripheral]) {
        print("did retrieve peripherals")
        for peripheral in peripherals {
            print("Discovered peripheral \(peripheral.name)")
        }
    }
    
    
    //MARK: - CBPeripheralDelegate methods
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            let message = "Error discovering services: \(error.localizedDescription)"
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
        if let error = error {
            let message = "Error discovering characteristics: \(error.localizedDescription)"
            delegate?.bluetoothManager(self, hadAnError: BluetoothManagerError(message: message, type: .discoverCharacteristicsError))
            return
        }
        
        if let characteristics = service.characteristics {
            
            for characteristic in characteristics {
                print("Discovered characteristic \(characteristic)")
                self.characteristics[characteristic.uuid] = characteristic
                peripheral.setNotifyValue(true, for: characteristic);
            }
            
            
//            isOldPebble = characteristics.contains(where: { $0.uuid == PebbleBLE.connectionParametersCharacteristicUUID }) == false
        }
        
        delegate?.bluetoothManagerDidFinishedConnectingWithDevice(self)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            let message = "Error updating value for characteristic: \(error.localizedDescription)"
            delegate?.bluetoothManager(self, hadAnError: BluetoothManagerError(message: message, type: .updateValueError))
        }
        
        print("Updated value of characteristic \(characteristic)")
        guard let newValue = characteristic.value else {
            return
        }
        
        let bytes = [UInt8](newValue)
        print("new value: \(bytes)")
        
        if characteristic.uuid == PebbleGATTClient.connectivityCharacteristicUUID {

            let status = DeviceStatus(rawValue: bytes[0])
            print(status?.description() ?? "The device status is unknown")
//            switch bytes[0]{
//            case 0x01:
//                print("Device is not bonded")
//            case 0x05:
//                print("Device is bonding")
//            case 0x0F:
//                print("Device is bonded")
//            default:
//                print("Unknown state: \(bytes[0])")
//            }
            

        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            let message = "Error writting value for characteristic: \(error.localizedDescription)"
            delegate?.bluetoothManager(self, hadAnError: BluetoothManagerError(message: message, type: .updateValueError))
        }
        
        print("Wrote value of characteristic \(characteristic)")
        let newValue = characteristic.value
        print("new value: \(newValue)")
    }
    

}
