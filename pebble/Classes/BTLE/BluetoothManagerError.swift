//
//  BluetoothManagerError.swift
//  pebble
//
//  Created by Ester Sanchez on 14/12/2016.
//  Copyright © 2016 misato. All rights reserved.
//

import Foundation

enum BluetoothManagerErrorType: Int {
    case scanUpdateError = 0
    case connectionError = 1
    case discoverServicesError = 2
    case discoverCharacteristicsError = 3
    case genericError = 4
    case updateValueError = 5
    case userDefaultsError = 6
}

class BluetoothManagerError: NSError {
    init(message: String, type: BluetoothManagerErrorType) {
        super.init(domain: "BluetoothManager", code: type.rawValue, userInfo: [NSLocalizedDescriptionKey: message])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
