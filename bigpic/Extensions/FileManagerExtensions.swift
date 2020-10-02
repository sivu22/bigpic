//
//  FileManagerExtensions.swift
//  bigpic
//
//  Created by Cristian Sava on 22.09.20.
//  Copyright © 2020 Cristian Sava. All rights reserved.
//

import Foundation

extension FileManager {
    
    static func findAllFiles(atPath path: String) throws -> [String] {
        guard !path.isEmpty else {
            Log.error("Invalid images path \(path, modifier: .mPrivateRelease)")
            throw Status.imageSearchFailed("Invalid images path.")
        }
        
        let fileManager = FileManager.default
        var result: [String] = []
        do {
            let files = try fileManager.contentsOfDirectory(atPath: path)
            var isDir: ObjCBool = false
            for file in files {
                if fileManager.fileExists(atPath: path + "/" + file, isDirectory: &isDir) && isDir.boolValue == false {
                    result.append(file)
                }
            }
        } catch {
            let errorText = String(describing: error)
            Log.error("Failed to get files at \(path, modifier: .mPrivateRelease) " + errorText)
            throw Status.imageSearchFailed(errorText)
        }
        
        return result.sorted()
    }
}
