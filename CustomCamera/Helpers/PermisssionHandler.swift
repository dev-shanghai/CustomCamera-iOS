//
//  PermisssionHandler.swift
//  CustomCamera
//
//  Created by Dev Shanghai on 08/05/2020.
//  Copyright © 2020 Dev Shanghai. All rights reserved.
//


import UIKit
import Permission

class PersmissionsHandler: NSObject {
    private override init() { super.init() }
    
    static func requestCameraAccess(onCompletion: @escaping ((_ success: Bool) -> Void)) {
        let permission = Permission.camera
        permission.presentDeniedAlert = true
        permission.presentDisabledAlert = true
        /*
        let deniedAlert = permission.deniedAlert
        let disableAlert = permission.disabledAlert
        
        deniedAlert.title    = "Permisson Denied"
        deniedAlert.message  = "Please allow access to your camera"
        deniedAlert.cancel   = "Cancel"
        deniedAlert.settings = "Settings"
        
        disableAlert.title    = "Permisson Disable"
        disableAlert.message  = "Please allow access to your camera"
        disableAlert.cancel   = "Cancel"
        disableAlert.settings = "Settings"
        */
        permission.request { (status) in
            switch status {
            case .authorized:
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    onCompletion(true)
                } else {
                    onCompletion(false)
                }
                
            default:
                onCompletion(false)
            }
        }
    }
    
    static func requestPhotosAccess(onCompletion: @escaping ((_ success: Bool) -> Void)) {
        let permission = Permission.photos
        permission.presentDeniedAlert = true
        permission.presentDisabledAlert = true
        /*
        let deniedAlert = permission.deniedAlert
        let disableAlert = permission.disabledAlert
        
        deniedAlert.title    = "Permisson Denied"
        deniedAlert.message  = "Please allow access to your photos"
        deniedAlert.cancel   = "Cancel"
        deniedAlert.settings = "Settings"
        
        disableAlert.title    = "Permisson Disable"
        disableAlert.message  = "Please allow access to your photos"
        disableAlert.cancel   = "Cancel"
        disableAlert.settings = "Settings"
        */
        permission.request { (status) in
            switch status {
            case .authorized:
                onCompletion(true)
            default:
                onCompletion(false)
            }
        }
    }
    
    static func requestMediaLibraryAccess(onCompletion: @escaping ((_ success: Bool) -> Void)) {
        let permission = Permission.mediaLibrary
        permission.presentDeniedAlert = true
        permission.presentDisabledAlert = true
        /*
        let deniedAlert = permission.deniedAlert
        let disableAlert = permission.disabledAlert
        
        deniedAlert.title    = "Permisson Denied"
        deniedAlert.message  = "Please allow access to your media library"
        deniedAlert.cancel   = "Cancel"
        deniedAlert.settings = "Settings"
        
        disableAlert.title    = "Permisson Disable"
        disableAlert.message  = "Please allow access to your media library"
        disableAlert.cancel   = "Cancel"
        disableAlert.settings = "Settings"
        */
        permission.request { (status) in
            switch status {
            case .authorized:
                onCompletion(true)
            default:
                onCompletion(false)
            }
        }
    }
    
    static func requestMicrophoneAccess(onCompletion: @escaping ((_ success: Bool) -> Void)) {
        let permission = Permission.microphone
        permission.presentDeniedAlert = true
        permission.presentDisabledAlert = true
        /*
         let deniedAlert = permission.deniedAlert
         let disableAlert = permission.disabledAlert
         
         deniedAlert.title    = "Permisson Denied"
         deniedAlert.message  = "Please allow access to your media library"
         deniedAlert.cancel   = "Cancel"
         deniedAlert.settings = "Settings"
         
         disableAlert.title    = "Permisson Disable"
         disableAlert.message  = "Please allow access to your media library"
         disableAlert.cancel   = "Cancel"
         disableAlert.settings = "Settings"
         */
        permission.request { (status) in
            switch status {
            case .authorized:
                onCompletion(true)
            default:
                onCompletion(false)
            }
        }
    }

    
}

