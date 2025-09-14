import Foundation
import SwiftUI

struct DiskInfo: Identifiable, Hashable {
    let id = UUID()
    let deviceIdentifier: String
    let name: String
    let size: String
    let type: String
    
    var displayName: String {
        if name != "Unknown" && !name.isEmpty {
            return "\(name) (\(deviceIdentifier))"
        } else {
            return deviceIdentifier
        }
    }
}
