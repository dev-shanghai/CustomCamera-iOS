//
//  Logger.swift
//  ShowUoff
//
//  Created by Ingic on 07/07/2017.
//  Copyright © 2018 ShowUoff. All rights reserved.
//

import UIKit

//import Crashlytics

class Logger {
    static func logException(error:Error) {
        #if DEBUG
            print("ShowUoff - Exception -> \(error.localizedDescription)")
        #endif
        
        // Crashlytics.sharedInstance().recordError(error)
    }
    
    static func logError(value:Any) {
        #if DEBUG
            print("ShowUoff - Error -> \(value)")
        #endif
    }
    
    static func logWarning(value:Any) {
        #if DEBUG
            print("ShowUoff - Warning -> \(value)")
        #endif
    }
    
    static func logInfo(value:Any) {
        #if DEBUG
            print("ShowUoff - Info -> \(value)")
        #endif
    }
}
