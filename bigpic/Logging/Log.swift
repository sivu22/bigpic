//
//  Log.swift
//  bigpic
//
//  Created by Cristian Sava on 22.09.20.
//  Copyright © 2020 Cristian Sava. All rights reserved.
//

import Foundation
import os.log

class Log {
    
    private static var logger = Log()
    
    private var oslog: AnyObject?
    
    public init(subSystem: String = Bundle.main.bundleIdentifier!, category: String = "App") {
        oslog = OSLog(subsystem: subSystem, category: category)
    }
    
    public func setCategory(to cat: String, forSubsystem subsystem: String = "") {
        if !cat.isEmpty {
            var subSystem = Bundle.main.bundleIdentifier!
            if !subsystem.isEmpty {
                subSystem = subsystem
            }
            oslog = OSLog(subsystem: subSystem, category: cat)
        }
    }
    
    private func log(_ msg: String, type: OSLogType) {
        os_log("%{public}s", log: oslog as! OSLog, type: type, msg)
    }
    
    public func debug(_ msg: String) {
        log(msg, type: .debug)
    }
    
    public func info(_ msg: String) {
        log(msg, type: .info)
    }
    
    public func message(_ msg: String) {
        log(msg, type: .default)
    }
    
    public func error(_ msg: String) {
        log(msg, type: .error)
    }
    
    // MARK: - Default logger
    
    public static func setCategory(to cat: String, forSubsystem subsystem: String = "") {
        logger.setCategory(to: cat, forSubsystem: subsystem)
    }
    
    public static func debug(_ msg: String) {
        logger.debug(msg)
    }
    
    public static func info(_ msg: String) {
        logger.info(msg)
    }
    
    public static func message(_ msg: String) {
        logger.message(msg)
    }
    
    public static func error(_ msg: String) {
        logger.error(msg)
    }
}

// MARK: - StringInterpolation
extension String.StringInterpolation {
    
    public enum Modifier {
        case mPrivate
        case mPrivateRelease
        case mPublic
    }
    
    public mutating func appendInterpolation(_ value: Any?, modifier: String.StringInterpolation.Modifier = .mPublic) {
        switch modifier {
        case .mPrivate:
            if value != nil {
                appendLiteral("<redacted>")
            } else {
                appendLiteral("nil")
            }
        case .mPrivateRelease:
            if let value = value {
                #if DEBUG
                appendInterpolation(value)
                #else
                appendLiteral("<redacted>")
                #endif
            } else {
                appendLiteral("nil")
            }
        case .mPublic:
            if let value = value {
                appendInterpolation(value)
            } else {
                appendLiteral("nil")
            }
        }
    }
}
