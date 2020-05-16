//
//  ViewController.swift
//  CustomCamera
//
//  Created by Dev Shanghai on 08/05/2020.
//  Copyright © 2020 Dev Shanghai. All rights reserved.
//

import UIKit

protocol TrimmedImageViewDelegate {
     func sendCroppedImage(_ image: UIImage)
}


class ViewController: UIViewController, TrimmedImageViewDelegate {
    func sendCroppedImage(_ image: UIImage) {
        self.imageView.image = image
        
    }
    
    
    
    @IBOutlet weak var imageView: UIImageView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    

    @IBAction func didTapOpenCamera(_ sender: Any) {
        
         let vc = AppStoryboard.Main.instance.instantiateViewController(withIdentifier: "CameraViewController") as! CameraViewController
        
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

