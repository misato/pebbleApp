//
//  PebbleGATTServer.swift
//  pebble
//
//  Created by Ester Sanchez on 16/12/2016.
//  Copyright © 2016 misato. All rights reserved.
//

import Foundation
import CoreBluetooth

private struct PebbleGATTServerUUID {
    static let service = CBUUID(string: "20000000-328E-0FBB-C642-1AA6699BDADA")
    static let serviceBADBAD = CBUUID(string: "BADBADBA-DBAD-BADB-ADBA-BADBADBADBAD")
    static let writeCharacteristics = CBUUID(string: "20000001-328E-0FBB-C642-1AA6699BDADA")
    static let readCharacteristics = CBUUID(string: "20000002-328E-0FBB-C642-1AA6699BDADA")
    static let characteristicsConfigurationDescriptor = CBUUID(string: "00002902-0000-1000-8000-00805f9b34fb")
}


class PebbleGATTServer: NSObject, CBPeripheralManagerDelegate {
 
    let peripheralManager = CBPeripheralManager()
    private let readCharacteristic = CBMutableCharacteristic(type: PebbleGATTServerUUID.readCharacteristics, properties: .read, value: nil, permissions: .readable)
    private let writeCharacteristic =  CBMutableCharacteristic(type: PebbleGATTServerUUID.writeCharacteristics, properties: [.writeWithoutResponse, .notify], value: nil, permissions: .writeable)
    private var subscribedCentrals: [CBCentral] = []
    
    // MARK: - Utils
    func createService() {
        if peripheralManager.isAdvertising {
            return
        }
        
        // Create the service to advertise
        let service = CBMutableService(type: PebbleGATTServerUUID.service, primary: true)
        
//        writeCharacteristic.descriptors = [CBMutableDescriptor(type: PebbleGATTServerUUID.characteristicsConfigurationDescriptor, value: nil)]
        
        service.characteristics = [readCharacteristic, writeCharacteristic]
        peripheralManager.add(service)
        
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [PebbleGATTServerUUID.service]])
    }
    
    // MARK: - Pebble functions
    
    func sendDataToPebble(_ data: Data) {
        peripheralManager.updateValue(data, for: writeCharacteristic, onSubscribedCentrals: subscribedCentrals)
    }
    
    func sendAckToPebbleWithSerial(_ serial: UInt8) {
        let data = Data(bytes: [(((serial << 3) | 1) & 0xff)], count: MemoryLayout<UInt8>.size)
        sendDataToPebble(data)
    }
    
    // MARK: - CBPeriferalManagerDelegate
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("received read request")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        print("received write request")
        for request in requests {
            guard let value = request.value else {
                continue
            }
            
            let bytes = [UInt8](value)
            let header = bytes[0] & 0xff
            let command = header & 7
            let serial = header >> 3
            
            
            print("Command: \(command)")
            switch command {
            case 0x01: // ACK
                print("Got ACK for serial \(serial)")
            case 0x02: // some request?
                let response: [UInt8] = (bytes.count > 1) ? [0x03, 0x19, 0x19] : [0x03]
                sendDataToPebble(Data(bytes: response, count: response.count))
            case 0: // normal package
                print("Got PPoGATT package serial \(serial) sending ACK")
                sendAckToPebbleWithSerial(serial)
            default:
                print("Unknown command")
            }
            
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("Central \(central) subscribed to characteristic \(characteristic)")
        subscribedCentrals.append(central)
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("peripheralManagerDidUpdateState")
    }
}
