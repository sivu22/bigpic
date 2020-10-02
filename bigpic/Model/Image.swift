//
//  Image.swift
//  bigpic
//
//  Created by Cristian Sava on 23.09.20.
//  Copyright © 2020 Cristian Sava. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

struct Image {

    private(set) var path: String       // Image full path
    private(set) var name: String       // Filename
    private(set) var width: Int = 0     // In pixels
    private(set) var height: Int = 0    // In pixels
    private(set) var size: Int = 0      // Image size in bytes
    private(set) var uti: String?
    private(set) var data: UIImage?     // Stores either a thumbnail of the image - since
                                        // we're dealing with (possibly) huge images - or the
                                        // whole image data
    private(set) var resized = false    // A way to know if the image was resized (thumbnail) or not
    
    static let defThumbnailWidth = 300  // Default width
    static let defThumbnailHeight = 300 // Default height

    /* Specifying no maximum thumbnail size means we want to hold the whole image data in memory
       Useful when displaying the image at big dimmensions or editing it, for example */
    init?(withPath path: String, withFileName fileName: String, thumbnailSize: CGSize = CGSize()) {
        guard !path.isEmpty && !fileName.isEmpty else {
            return nil
        }
        
        name = fileName
        if path.last == "/" {
            self.path = path + name
        } else {
            self.path = path + "/" + name
        }
        
        // Try to load the image and get the uti, resolution and size
        var img: CGImage?
        if thumbnailSize.width == 0 || thumbnailSize.height == 0 {
            (img, uti, width, height, size) = load()
        } else {
            (img, uti, width, height, size) = load(asThumbnail: true, thumbnailSize: thumbnailSize)
            resized = true
        }
        if img == nil {
            return nil
        }
        
        data = UIImage(cgImage: img!)
        
        Log.message("\(name, modifier: .mPrivateRelease) of type \(uti == nil ? "nil" : uti!) resolution \(width), \(height) size \(sizeAsString())")
    }
    
    // Image size displayed appropriately
    func sizeAsString() -> String {
        if size < 1024 {
            return "\(size) B"
        } else if size < 1048576 {
            return "\(Int(size / 1024)) KB"
        }
        
        return String(format: "%.1f", Float(size) / 1048576.0) + " MB"
    }
    
    // MARK: - Image loading
    
    // Load an image and return it alongside its UTI, resolution and storage size
    private func load(asThumbnail: Bool = false, thumbnailSize: CGSize = CGSize()) -> (CGImage?, String?, Int, Int, Int) {
        var uti: String?
        var width = 0.0, height = 0.0
        var cgImage: CGImage?
        var size = 0
        
        let urlImg = URL(fileURLWithPath: path, isDirectory: false)
        if let imgData = NSData(contentsOf: urlImg as URL) {
            if let imageSource = CGImageSourceCreateWithData(imgData, nil) {
                // Use either the downsampled image or the original one
                if asThumbnail && thumbnailSize.width > 0 && thumbnailSize.height > 0 {
                    cgImage = getThumbnail(fromImageSource: imageSource, withSize: thumbnailSize)
                } else {
                    cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
                    /* If image data is already present, we already loaded this image previously,
                       so we already have all image details at hand */
                    if data != nil {
                        return (cgImage, self.uti, self.width, self.height, self.size)
                    }
                }
                
                if let UTI = CGImageSourceGetType(imageSource) {
                    uti = String(UTI)
                }
                
                if let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [AnyHashable: Any] {
                    let pixelWidth = properties[kCGImagePropertyPixelWidth] as! CFNumber?
                    let pixelHeight = properties[kCGImagePropertyPixelHeight] as! CFNumber?
                    
                    if pixelWidth == nil || pixelHeight == nil || !(CFNumberGetValue(pixelWidth, .cgFloatType, &width) && CFNumberGetValue(pixelHeight, .cgFloatType, &height)) {
                        Log.error("Failed to retrieve image dimensions for \(name)")
                    }
                }
                
                size = imgData.length
            }
        }
        
        return (cgImage, uti, Int(width), Int(height), size)
    }
    
    private func getThumbnail(fromImageSource imageSource: CGImageSource, withSize size: CGSize) -> CGImage?
    {
        let maxThumbnailDimension = max(size.width, size.height)
        
        // Don't use kCGImageSourceCreateThumbnailWithTransform to perserve actual pixel aspect ratio
        let downsampledOptions = [kCGImageSourceCreateThumbnailFromImageAlways: true,   // Also needed by PDFs
                                  kCGImageSourceShouldCacheImmediately: true,
                                  kCGImageSourceThumbnailMaxPixelSize: maxThumbnailDimension] as CFDictionary
        
        return CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampledOptions)
    }
    
    /* Returns an UIImage to be used for display purposes, no downsampling. If the image data
       is a thumbnail, the image will be loaded up again. */
    func getOriginalImage() -> (Status, UIImage?) {
        var status: Status = .success
        var uiImage: UIImage?
        
        if !resized {
            uiImage = data
        } else {
            Log.message("Loading image \(self.name)")
            
            var img: CGImage?
            (img, _, _, _, _) = self.load()
            if let img = img {
                uiImage = UIImage(cgImage: img)
            } else {
                status = .imageLoadFailed("Failed to load image \(self.name). Does the image still exists?")
            }
        }
        
        return (status, uiImage)
    }
}
