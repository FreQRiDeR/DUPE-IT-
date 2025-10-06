//
//  DiskInfo.swift
//  DUPE-IT!
//
//  Created by FreQRiDeR on 9/9/25.
//

import Foundation

struct DiskInfo: Identifiable, Hashable {
    let id = UUID()
    let deviceIdentifier: String
    let name: String
    let size: String
    let type: String
    
    var displayName: String {
        "\(name) (\(deviceIdentifier)) - \(size)"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(deviceIdentifier)
    }
    
    static func == (lhs: DiskInfo, rhs: DiskInfo) -> Bool {
        lhs.deviceIdentifier == rhs.deviceIdentifier
    }
}
