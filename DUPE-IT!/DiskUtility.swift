import Foundation
import SwiftUI
//
//  DiskUtility.swift
//  DUPE-IT!
//
//  Created by FreQRiDeR on 9/9/25.
//


struct DiskUtility {
    static func listDisks() async throws -> [DiskInfo] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
        process.arguments = ["list", "-plist"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw DiskUtilityError.commandFailed("diskutil failed with status \(process.terminationStatus)")
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()

        guard let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let allDisksAndPartitions = plist["AllDisksAndPartitions"] as? [[String: Any]] else {
            throw DiskUtilityError.parsingFailed("Failed to parse diskutil output")
        }

        var disks: [DiskInfo] = []
        let hiddenTypes: Set<String> = [
            "EFI", "Preboot", "Recovery", "VM", "Update", "UNDO", "Apple_APFS_Recovery", "Apple_APFS_ISC", "Apple_APFS_Preboot", "Apple_APFS_VM", "Apple_APFS_Update", "Apple_APFS_Snapshot"
        ]
        let hiddenNames: Set<String> = [
            "Preboot", "Recovery", "VM", "Update", "EFI", "Snapshot"
        ]
        for diskDict in allDisksAndPartitions {
            if let deviceIdentifier = diskDict["DeviceIdentifier"] as? String,
               let size = diskDict["Size"] as? Int64 {
                let type = diskDict["Content"] as? String ?? "Unknown"
                let name = diskDict["VolumeName"] as? String ?? diskDict["MediaName"] as? String ?? diskDict["APFSContainerReference"] as? String ?? type
                if !hiddenTypes.contains(type) && !hiddenNames.contains(name) {
                    let sizeString = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
                    disks.append(DiskInfo(
                        deviceIdentifier: "/dev/\(deviceIdentifier)",
                        name: name,
                        size: sizeString,
                        type: type
                    ))
                }
            }
            if let partitions = diskDict["Partitions"] as? [[String: Any]] {
                for partition in partitions {
                    if let deviceIdentifier = partition["DeviceIdentifier"] as? String,
                       let size = partition["Size"] as? Int64 {
                        let type = partition["Content"] as? String ?? "Partition"
                        let name = partition["VolumeName"] as? String ?? partition["MediaName"] as? String ?? type
                        if !hiddenTypes.contains(type) && !hiddenNames.contains(name) {
                            let sizeString = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
                            disks.append(DiskInfo(
                                deviceIdentifier: "/dev/\(deviceIdentifier)",
                                name: name,
                                size: sizeString,
                                type: type
                            ))
                        }
                    }
                }
            }
            if let apfsVolumes = diskDict["APFSVolumes"] as? [[String: Any]] {
                for apfsVolume in apfsVolumes {
                    if let deviceIdentifier = apfsVolume["DeviceIdentifier"] as? String,
                       let size = apfsVolume["Size"] as? Int64 {
                        let type = apfsVolume["Content"] as? String ?? "APFS Volume"
                        let name = apfsVolume["VolumeName"] as? String ?? apfsVolume["MediaName"] as? String ?? type
                        if !hiddenTypes.contains(type) && !hiddenNames.contains(name) {
                            let sizeString = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
                            disks.append(DiskInfo(
                                deviceIdentifier: "/dev/\(deviceIdentifier)",
                                name: name,
                                size: sizeString,
                                type: type
                            ))
                        }
                    }
                }
            }
        }
        return disks.sorted { $0.deviceIdentifier < $1.deviceIdentifier }
    }
}

enum DiskUtilityError: LocalizedError {
    case commandFailed(String)
    case parsingFailed(String)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let message):
            return message
        case .parsingFailed(let message):
            return message
        }
    }
}
