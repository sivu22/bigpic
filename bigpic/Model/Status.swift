//
//  Status.swift
//  bigpic
//
//  Created by Cristian Sava on 23.09.20.
//  Copyright © 2020 Cristian Sava. All rights reserved.
//

import Foundation

// Define statuses appropriate to this app, can be easily extended as the app evolves
enum Status: Error {
    
    case success
    case unknown
    
    case imageSearchFailed(String)
    case imageLoadFailed(String)
}

extension Status: Equatable {
    
    static func ==(lhs: Status, rhs: Status) -> Bool {
        switch(lhs, rhs) {
        case (.success, .success), (.unknown, .unknown):
            return true
        default:
            return false
        }
    }
}
