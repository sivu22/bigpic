//
//  Images.swift
//  bigpic
//
//  Created by Cristian Sava on 23.09.20.
//  Copyright © 2020 Cristian Sava. All rights reserved.
//

import Foundation
import UIKit

protocol ImagesDelegate: AnyObject {
    
    // Notify the VC about a new available image for display
    func addedImage(atIndex index: Int)
    // Notify the VC about an image who was removed
    func removedImage(atIndex index: Int)
    // Ask the VC to provide the maximum thumbnail size an image is expected to have
    func getThumbnailSize() -> CGSize
}

// Handles images at a given path
class Images {
    
    private let path: String
    private var images: [Image] = []        // Images are sorted by name
    var count: Int {
        return images.count
    }
    
    weak var delegate: ImagesDelegate?
    
    var queue = DispatchQueue(label: "com.sivu.bigpic.images")
    
    init(atPath path: String) {
        self.path = path
    }
    
    func searchForImages(completion: @escaping (Status, [String]) -> Void) {
        queue.async {
            var completionStatus = Status.success
            var allFiles: [String] = []
            
            do {
                allFiles = try FileManager.findAllFiles(atPath: self.path)
                Log.message("Found \(allFiles.count) files")
            } catch {
                if let error = error as? Status {
                    completionStatus = error
                } else {
                    completionStatus = Status.unknown
                }
            }
            
            DispatchQueue.main.async {
                completion(completionStatus, allFiles)
            }
        }
    }
    
    func addImages(fromFiles files: [String]) {
        var thumbnailSize = delegate?.getThumbnailSize()
        if thumbnailSize == nil {
            // If no size is provided, then use the whole image data
            thumbnailSize = CGSize()
        }
        
        queue.async { [weak self] in
            var numImages = 0
            let noImages = (self?.images.count == 0)
            for file in files {
                /* Check if the same image was already loaded, to avoid duplicates (because of
                   dynamically adding/removing images from Documents)
                   Image file update should be handeled via a separate refresh feature */
                if let index = self?.findImageIndex(forName: file), index == -1 {
                    if let image = Image(withPath: self?.path ?? "", withFileName: file, thumbnailSize: thumbnailSize!) {
                        /* Insert the new image either at the right position or at the end of the array,
                           because files is a sorted array */
                        var insertIndex = -1
                        
                        if !noImages {
                            if let correctIndex = self?.images.firstIndex(where: { $0.name > file }) {
                                insertIndex = correctIndex
                                self?.images.insert(image, at: insertIndex)
                            }
                        }
                        
                        if insertIndex == -1 {
                            insertIndex = self?.images.count ?? 0
                            self?.images.append(image)
                        }
                        
                        numImages += 1
                        
                        if let delegate = self?.delegate {
                            DispatchQueue.main.sync {
                                delegate.addedImage(atIndex: insertIndex)
                            }
                        }
                    } else {
                        Log.message("Failed to load image from \(file, modifier: .mPrivateRelease)")
                    }
                }
            }
            
            Log.message("Added \(numImages) images")
        }
    }
    
    func removeImages(fromFiles files: [String]) {
        queue.async { [weak self] in
            var numImages = 0
            for file in files {
                if let index = self?.findImageIndex(forName: file), index > -1, let _ = self?.images.remove(at: index) {
                    numImages += 1
                    
                    if let delegate = self?.delegate {
                        DispatchQueue.main.sync {
                            delegate.removedImage(atIndex: index)
                        }
                    }
                } else {
                    Log.error("Failed to remove image with name \(file, modifier: .mPrivateRelease) or file was not an image")
                }
            }
            
            Log.message("Removed \(numImages) images")
        }
    }
    
    private func findImageIndex(forName name: String) -> Int {
        for i in 0..<images.count {
            if images[i].name == name {
                return i
            }
        }
        
        return -1
    }
    
    subscript(index: Int) -> Image? {
        guard index < images.count else {
            return nil
        }
        
        return images[index]
    }
}
