//
//  Extensions.swift
//  CustomCamera
//
//  Created by Dev Shanghai on 08/05/2020.
//  Copyright © 2020 Dev Shanghai. All rights reserved.
//

import UIKit
import Foundation


extension UIImage {
    
    @objc func fixOrientation() -> UIImage {
        
        if self.imageOrientation == UIImage.Orientation.up {
            
            return self
            
        }
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        
        let normalizedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        
        return normalizedImage;
        
    }
}

extension UIViewController {
    
    // Not using static as it wont be possible to override to provide custom storyboardID then
    class var storyboardID : String {
        
        //if your storyboard name is same as ControllerName uncomment it
        return "\(self)"
        //return "\(self)" + "_ID"
        
    }
    
    static func instantiate(fromAppStoryboard appStoryboard: AppStoryboard) -> Self {
        return appStoryboard.viewController(viewControllerClass: self)
    }
}

enum AppStoryboard : String {
    
    // Add all the storyboard names you wanted to use in your project
    case Main, Secondary
    
    var instance : UIStoryboard {
        
        return UIStoryboard(name: self.rawValue, bundle: Bundle.main)
    }
    
    func viewController<T : UIViewController>(viewControllerClass : T.Type, function : String = #function, line : Int = #line, file : String = #file) -> T {
        
        let storyboardID = (viewControllerClass as UIViewController.Type).storyboardID
        
        guard let scene = instance.instantiateViewController(withIdentifier: storyboardID) as? T else {
            
            fatalError("ViewController with identifier \(storyboardID), not found in \(self.rawValue) Storyboard.\nFile : \(file) \nLine Number : \(line) \nFunction : \(function)")
        }
        
        return scene
    }
    
    func initialViewController() -> UIViewController? {
        
        return instance.instantiateInitialViewController()
    }
}


extension UIImage{
    static func convert(from ciImage: CIImage) -> UIImage{
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(ciImage, from: ciImage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
}
