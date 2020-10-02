//
//  CGImageExtensions.swift
//  bigpic
//
//  Created by Cristian Sava on 23.09.20.
//  Copyright © 2020 Cristian Sava. All rights reserved.
//

import UIKit

extension CGImage {

    func convertToRGBA() -> CGImage? {
        guard var colorSpace = colorSpace else {
            Log.error("Source image has no color space defined!")
            return nil
        }
        if !colorSpace.supportsOutput {
            Log.message("Image color space \(colorSpace) doesn't support output, will create new color space")
            colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        }
        
        var bpc = 8
        if bitsPerComponent > 8 {
            bpc = bitsPerComponent
        }
        guard let ctx = CGContext(data: nil,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: bpc,
                                  bytesPerRow: 0,
                                  space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            Log.error("Failed to create new RGBA bitmap context")
            return nil
        }
        
        ctx.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return ctx.makeImage()
    }
}
