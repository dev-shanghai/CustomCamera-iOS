//
//  FAImageCropperVCViewController.swift
//  CustomCamera
//
//  Created by Dev Shanghai on 09/05/2020.
//  Copyright © 2020 Dev Shanghai. All rights reserved.
//

import UIKit
import Photos
import Foundation

protocol CroppedImageDelegate {
    func sendCroppedImage(_ image: UIImage)
}


class FAImageCropperVC: BaseViewController {

        // MARK: IBOutlets
        
        @IBOutlet weak var scrollContainerView: UIView!
        @IBOutlet weak var scrollView: FAScrollView!
        @IBOutlet weak var btnZoom: UIButton!
        @IBOutlet weak var done_btn: UIButton!
        @IBOutlet weak var cancel_btn: UIButton!
        
        var selectedImage : UIImage!
        var delegate : CroppedImageDelegate?
        var checkRotation : CGFloat = .pi*2
        
        @IBAction func tapZoom_btn(_ sender: Any) {
            scrollView.zoom()
        }
    
    
        @IBAction func tapCrop_btn(_ sender: Any) {
            croppedImage = captureVisibleRect()
            self.delegate?.sendCroppedImage(croppedImage!)
            //back()
            
            //performSegue(withIdentifier: "FADetailViewSegue", sender: nil)
        }
        
        @IBAction func tapRotate_btn(_ sender: Any) {
            
            
            
            if self.checkRotation == .pi*2{
                self.checkRotation = .pi/2
                let check = self.scrollView.imageView.image?.rotate(radians: self.checkRotation, imageSize: scrollView.frame.size)
                self.scrollView.imageView.image = check
                
            }else if self.checkRotation == .pi/2{
                self.checkRotation = .pi
                let check = self.scrollView.imageView.image?.rotate(radians: self.checkRotation, imageSize: scrollView.frame.size)
                self.scrollView.imageView.image = check
            }else if self.checkRotation == .pi{
                self.checkRotation = (.pi*3)/2
                let check = self.scrollView.imageView.image?.rotate(radians: self.checkRotation, imageSize: scrollView.frame.size)
                self.scrollView.imageView.image = check
            }else if self.checkRotation == (.pi*3)/2{
                self.checkRotation = .pi * 2
                let check = self.scrollView.imageView.image?.rotate(radians: self.checkRotation, imageSize: scrollView.frame.size)
                self.scrollView.imageView.image = check
            }
            
            self.view.layoutIfNeeded()
            self.scrollView.layoutIfNeeded()
            
            //self.scrollView.imageView.transform = self.scrollView.imageView.transform.rotated(by: CGFloat(M_PI_2))
        }
        
        
        // MARK: Public Properties
        
        var photos:[PHAsset]!
        var imageViewToDrag: UIImageView!
        var indexPathOfImageViewToDrag: IndexPath!
        
        let cellWidth = ((UIScreen.main.bounds.size.width)/3)-1
        
        
        // MARK: Private Properties
        
        private let imageLoader = FAImageLoader()
        private var croppedImage: UIImage? = nil

        
        
        // MARK: LifeCycle
        
        override func viewDidLoad() {
            super.viewDidLoad()
            // Do any additional setup after loading the view, typically from a nib.\
            
            self.done_btn.layer.cornerRadius = done_btn.frame.size.height/2
            
            self.done_btn.layer.masksToBounds = true
            
            displayImageInScrollView(image: self.selectedImage)
            
            setNavigation()
            
            
            viewConfigurations()
        }
        
        override func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
            // Dispose of any resources that can be recreated.
        }
        
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            super.prepare(for: segue, sender: sender)
            
            if segue.identifier == "FADetailViewSegue" {
                
                let detailVC = segue.destination as? FADetailVC
                detailVC?.croppedImage = croppedImage
            }
        }
        
        // MARK: Private Functions
        
        override func setNavigation() {
            super.setNavigation()
            addBackButton(color: .white)
        }
        
        /*
        override func back() {
            
            self.navigationController?.dismiss(animated: false, completion: nil)
        }
        */
        
        private func checkForPhotosPermission(){
            
            // Get the current authorization state.
            let status = PHPhotoLibrary.authorizationStatus()
            
            if (status == PHAuthorizationStatus.authorized) {
                // Access has been granted.
                loadPhotos()
            }
            else if (status == PHAuthorizationStatus.denied) {
                // Access has been denied.
            }
            else if (status == PHAuthorizationStatus.notDetermined) {
                
                // Access has not been determined.
                PHPhotoLibrary.requestAuthorization({ (newStatus) in
                    
                    if (newStatus == PHAuthorizationStatus.authorized) {
                        
                        DispatchQueue.main.async {
                            self.loadPhotos()
                        }
                    }
                    else {
                        // Access has been denied.
                    }
                })
            }
                
            else if (status == PHAuthorizationStatus.restricted) {
                // Restricted access - normally won't happen.
            }
        }
        
        private func viewConfigurations() {
            btnZoom.layer.cornerRadius = btnZoom.frame.size.width/2
            scrollView.zoom()
        }
        
        private func loadPhotos(){

            imageLoader.loadPhotos { (assets) in
                self.configureImageCropper(assets: assets)
            }
        }
        
        private func configureImageCropper(assets:[PHAsset]){

            if assets.count != 0{
                photos = assets
                ///collectionView.delegate = self
                //collectionView.dataSource = self
                //collectionView.reloadData()
                            //            selectDefaultImage()
            }
        }

        private func selectDefaultImage(){
            //collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: true, scrollPosition: .top)
            //        selectImageFromAssetAtIndex(index: 0)
        }
        
        
        private func captureVisibleRect() -> UIImage{
            
            var croprect = CGRect.zero
            let xOffset = (scrollView.imageToDisplay?.size.width)! / scrollView.contentSize.width;
            let yOffset = (scrollView.imageToDisplay?.size.height)! / scrollView.contentSize.height;
            
            croprect.origin.x = scrollView.contentOffset.x * xOffset;
            croprect.origin.y = scrollView.contentOffset.y * yOffset;
            
            let normalizedWidth = (scrollView?.frame.width)! / (scrollView?.contentSize.width)!
            let normalizedHeight = (scrollView?.frame.height)! / (scrollView?.contentSize.height)!
            
            croprect.size.width = scrollView.imageToDisplay!.size.width * normalizedWidth
            croprect.size.height = scrollView.imageToDisplay!.size.height * normalizedHeight
            
            let toCropImage = scrollView.imageView.image!.fixImageOrientation()
            
            if let cr = toCropImage.cgImage?.cropping(to: croprect) {
                return UIImage(cgImage: cr)
            }
            
            return toCropImage

        }
        private func isSquareImage() -> Bool{
            let image = scrollView.imageToDisplay
            if image?.size.width == image?.size.height { return true }
            else { return false }
        }

        
        // MARK: Public Functions

        func selectImageFromAssetAtIndex(index:NSInteger){
            
            FAImageLoader.imageFrom(asset: photos[index], size: PHImageManagerMaximumSize) { (image) in
                DispatchQueue.main.async {
                    self.displayImageInScrollView(image: image)
                }
            }
        }
        
        func displayImageInScrollView(image:UIImage){
            self.scrollView.imageToDisplay = image
            if isSquareImage() { btnZoom.isHidden = true }
            else { btnZoom.isHidden = false }
        }
        
        func replicate(_ image:UIImage) -> UIImage? {
            
            guard let cgImage = image.cgImage?.copy() else {
                return nil
            }

            return UIImage(cgImage: cgImage,
                                   scale: image.scale,
                                   orientation: image.imageOrientation)
        }
        

        @objc func handleLongPressGesture(recognizer: UILongPressGestureRecognizer) {

            let location = recognizer.location(in: view)

            if recognizer.state == .began {

                let cell: FAImageCell = recognizer.view as! FAImageCell
               // indexPathOfImageViewToDrag = collectionView.indexPath(for: cell)
                imageViewToDrag = UIImageView(image: replicate(cell.imageView.image!))
                imageViewToDrag.frame = CGRect(x: location.x - cellWidth/2, y: location.y - cellWidth/2, width: cellWidth, height: cellWidth)
                view.addSubview(imageViewToDrag!)
                view.bringSubviewToFront(imageViewToDrag!)
            }
            else if recognizer.state == .ended {
                
                if scrollView.frame.contains(location) {
                   // collectionView.selectItem(at: indexPathOfImageViewToDrag, animated: true, scrollPosition: UICollectionViewScrollPosition.centeredVertically)
    //              selectImageFromAssetAtIndex(index: indexPathOfImageViewToDrag.item)
                }
                
                imageViewToDrag.removeFromSuperview()
                imageViewToDrag = nil
                indexPathOfImageViewToDrag = nil
            }
            else{
                imageViewToDrag.center = location
            }
        }
    }





    extension FAImageCropperVC:UICollectionViewDataSource{
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

            let cell:FAImageCell = collectionView.dequeueReusableCell(withReuseIdentifier: "FAImageCell", for: indexPath) as! FAImageCell
            cell.populateDataWith(asset: photos[indexPath.item])
            cell.configureGestureWithTarget(target: self, action: #selector(FAImageCropperVC.handleLongPressGesture))
            
            return cell
        }
    }


    extension FAImageCropperVC:UICollectionViewDelegate{
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return photos.count
        }
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let cell:FAImageCell = collectionView.cellForItem(at: indexPath) as! FAImageCell
            cell.isSelected = true
    //        selectImageFromAssetAtIndex(index: indexPath.item)
        }
    }


    extension FAImageCropperVC:UICollectionViewDelegateFlowLayout{
        
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return CGSize(width: cellWidth, height: cellWidth)
        }
    }

    extension UIImage {
        func rotate(radians: CGFloat, imageSize: CGSize) -> UIImage {
            let rotatedSize = CGRect(origin: .zero, size: imageSize)
                .applying(CGAffineTransform(rotationAngle: CGFloat(radians)))
                .integral.size
            UIGraphicsBeginImageContext(rotatedSize)
            if let context = UIGraphicsGetCurrentContext() {
                let origin = CGPoint(x: rotatedSize.width / 2.0,
                                     y: rotatedSize.height / 2.0)
                context.translateBy(x: origin.x, y: origin.y)
                context.rotate(by: radians)
                draw(in: CGRect(x: -origin.x, y: -origin.y,
                                width: imageSize.width, height: imageSize.height))
                
                //UIGraphicsBeginImageContextWithOptions(imageSize, true, 1.0)
                let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                return rotatedImage ?? self
            }
            
            return self
        }
    }
