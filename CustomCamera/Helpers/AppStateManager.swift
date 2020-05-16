//
//  AppStateManager.swift
//  CustomCamera
//
//  Created by Dev Shanghai on 08/05/2020.
//  Copyright © 2020 Dev Shanghai. All rights reserved.
//



import Foundation

class AppStateManager {
    
    static let instance = AppStateManager()
    private init() {}
    
//    var webServices = WebServices()
//    var validation = Validation()
    
    var selectedVcIndex: Int!
    var checkMore = 0
    var checkImage = 0 //For clearing selected post Images array on viewwillAppear on CreatePostController
    
}

extension AppStateManager {
    func logout() {
        UserDefaults.standard.removeObject(forKey: "loginData")
        UserDefaults.standard.removeObject(forKey: "userId")
    }
    
    func deleteDevice(onCompletion:((_ receivedData:AnyObject?) -> Void)?){
        let param = ["user_id" : UserDefaults.standard.value(forKey: "userId") , "device_id": UserDefaults.standard.value(forKey: "deviceId")] as [String : AnyObject]
        
        Logger.logInfo(value: param)
        
//        AppStateManager.instance.webServices.startConnectionWithPostType(getUrlString: "DeleteDevice", params: param) { (receivedData) in
//
//            Logger.logInfo(value: receivedData)
//            onCompletion?(receivedData)
//
//        }
    }
    
    func adminDeactivateUserAccount(onCompletion: @escaping ((_ receivedData: AnyObject) -> Void)){
        
//        if !(NetworkManager.sharedInstance.isConnected()){
//            Utility.showAlert(title:"ShowUoff", message:ApiErrorMessage.NoNetwork, buttonTitles:["Ok"], completion :{ response in })
//            return
//        }
//        AppStateManager.instance.webServices.startConnectionWithGetType(getUrlString: "UserAutoLogoutIfAdminDeactivate/" + String(describing: (UserDefaults.standard.value(forKey: "userId")!))) { (receivedData) in
//
//            Logger.logInfo(value: receivedData)
//
//            if AppStateManager.instance.webServices.responseCode == 1 {
//
//                if String(describing: receivedData.value(forKey: "response")!) == "1" {
//                    onCompletion(receivedData)
//                }
//            }
//        }
    }
    
    func autoLogoutFromOldDevice(onCompletion: @escaping ((_ receivedData: AnyObject) -> Void)){
        
//        if !(NetworkManager.sharedInstance.isConnected()){
//            Utility.showAlert(title:"ShowUoff", message:ApiErrorMessage.NoNetwork, buttonTitles:["Ok"], completion :{ response in })
//            return
//        }
//        let param = ["user_id" : UserDefaults.standard.value(forKey: "userId") , "device_id": UserDefaults.standard.value(forKey: "deviceId")] as [String : AnyObject]
//        
//        Logger.logInfo(value: param)
//        
//        AppStateManager.instance.webServices.startConnectionWithPostType(getUrlString: "LogoutOldDeviceIfNewfound", params: param) { (receivedData) in
//            
//            Logger.logInfo(value: receivedData)
//            
//            if AppStateManager.instance.webServices.responseCode == 1 {
//                
//                if String(describing: receivedData.value(forKey: "response")!) == "1" {
//                    onCompletion(receivedData)
//                }
//                
//            }
//        }
    }
}
