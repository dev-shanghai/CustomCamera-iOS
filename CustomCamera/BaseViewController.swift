//
//  BaseViewController.swift
//  CustomCamera
//
//  Created by Dev Shanghai on 08/05/2020.
//  Copyright © 2020 Dev Shanghai. All rights reserved.
//

import Foundation

import UIKit

class BaseViewController: UIViewController, UIGestureRecognizerDelegate {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //* Update status bar style *//
        self.setNeedsStatusBarAppearanceUpdate()
    }

    override func viewDidDisappear(_ animated: Bool) {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    func pushViewController(_ viewController: UIViewController, animated: Bool) {
        //self.pushViewController(viewController, animated: true)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    func setNavigation(){
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.navigationBar.barTintColor = UIColor.blue
        self.navigationController?.navigationBar.tintColor = UIColor.white

        //addAppLogo()
    }
    
    func addBackButton(color: UIColor = .black){
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 120, height: 40))
        leftView.backgroundColor = UIColor.clear

        let backButtonImg = UIImageView(frame: CGRect(x: 0, y: 10, width: 20, height: 20))
        backButtonImg.image = #imageLiteral(resourceName: "back-arrow30").withRenderingMode(.alwaysTemplate)
        leftView.addSubview(backButtonImg)

        let backButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        backButton.addTarget(self, action: #selector(back), for: UIControl.Event.touchUpInside)
        leftView.addSubview(backButton)

        backButton.tintColor = color
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftView)
    }
    
    /*
    func addAppLogo(){
        let navView = UIView()

        let image = UIImageView()

        image.image = UIImage(named: "100logo")

        image.frame = CGRect(x: 0, y: 0, width: 75, height: 30)
        image.center = navView.center
        image.contentMode = UIView.ContentMode.scaleAspectFit
        navView.addSubview(image)

        navigationItem.titleView = navView
        navigationController?.navigationBar.barStyle = .default
        navigationController?.navigationBar.isTranslucent = false

        navView.sizeToFit()
    }
    
    func addBackButton(color: UIColor = .black){
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 120, height: 40))
        leftView.backgroundColor = Colors.systemClear
        
        let backButtonImg = UIImageView(frame: CGRect(x: 0, y: 10, width: 20, height: 20))
        backButtonImg.image = #imageLiteral(resourceName: "back-arrow30").withRenderingMode(.alwaysTemplate)
        leftView.addSubview(backButtonImg)
        
        let backButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        backButton.addTarget(self, action: #selector(back), for: UIControl.Event.touchUpInside)
        leftView.addSubview(backButton)
        
        backButton.tintColor = color
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftView)
    }
    
    func addMenuButton() {
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 120, height: 40))
        leftView.backgroundColor = Colors.systemClear
        
        let backButtonImg = UIImageView(frame: CGRect(x: 0, y: 10, width: 20, height: 20))
        backButtonImg.image = #imageLiteral(resourceName: "menu30")
        
        let backButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        backButton.addTarget(self.revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), for: UIControl.Event.touchUpInside)
        
        leftView.addSubview(backButtonImg)
        leftView.addSubview(backButton)
        
        self.revealViewController().panGestureRecognizer()
        self.revealViewController().tapGestureRecognizer()
        self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        self.view.addGestureRecognizer(self.revealViewController().tapGestureRecognizer())
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftView)
    }
    */
    
    @objc func back() {
        _ = self.navigationController?.popViewController(animated: true)
    }
}



