//
//  PebbleDevice.swift
//  pebble
//
//  Created by Ester Sanchez on 23/12/2016.
//  Copyright © 2016 misato. All rights reserved.
//

import Foundation

enum DeviceStatus: UInt8 {
    case notBonded = 0x01
    case bonding = 0x05
    case bonded = 0x0F
    
    
    func description() -> String {
        switch self {
        case .notBonded:
            return "Device is not bonded"
        case .bonding:
            return "Device is bonding"
        case .bonded:
            return "Device is bonded"
        }
    }
}
