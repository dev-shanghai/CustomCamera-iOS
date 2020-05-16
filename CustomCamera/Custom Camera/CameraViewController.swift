/*
 See LICENSE.txt for this sample’s licensing information.
 
 Abstract:
 View controller for camera interface.
 */

import UIKit
import TOCropViewController
import AssetsLibrary
import PhotosUI
import AVKit
import AVFoundation
import MobileCoreServices
import Photos
import SwiftGifOrigin
import ABVideoRangeSlider_SWIFT_5

class CameraViewController: BaseViewController, PhotoEditorDelegate, captureImageOutPut, CroppedImageDelegate,trimVideoFromLibray, TrimmedImageViewDelegate {




    // MARK: View Controller Life Cycle
    @IBOutlet weak var flashBtn: UIButton!
    var isFlashOn: Bool!
    // MARK: - VideoTrimmer
    @IBOutlet weak var videoTrimmerView: ABVideoRangeSlider!
    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet weak var pauseBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    
    let avPlayer = AVPlayer()
    var avPlayerLayer: AVPlayerLayer!
    var timeObserver: AnyObject!
    var startTime = 0.0;
    var endTime = 0.0;
    var progressTime = 0.0;
    var pathURL : NSURL!
    var shouldUpdateProgressIndicator = true
    var isSeeking = false


    var imageParam = ""
    var imagePicker = UIImagePickerController()
    var videoData:NSData!
    var profileImageData : NSData!
    var postImagesArr : NSMutableArray = []
    var postImagesCheckArr : NSMutableArray = []
    var coverImage:NSData!
    var sessionConfigured = false
    
    var delegate : TrimmedImageViewDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the video preview view.
        
        UserDefaults.standard.removeObject(forKey: "AnimateVideo")
        UserDefaults.standard.removeObject(forKey: "AnimateVideoThumbnail")
        
        previewView.session = session

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if avPlayerLayer != nil {
            avPlayerLayer.frame = videoContainer.bounds
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        if UserDefaults.standard.value(forKey: "AnimateVideo") != nil {
            
            if UserDefaults.standard.value(forKey: "AnimateVideo") as? String != nil {
                
                if UserDefaults.standard.value(forKey: "AnimateVideo") as! String == "yes" {
                    
                    UserDefaults.standard.removeObject(forKey: "AnimateVideo")
                    
                    AppStateManager.instance.checkImage = 1
                    
                    self.imageParam = "gif"
                    
                    imagePicker.sourceType = .photoLibrary
                    
                    imagePicker.mediaTypes = [kUTTypeMovie as String]
                    
                    imagePicker.delegate = self
                    
                    imagePicker.allowsEditing = false
                    
                    imagePicker.videoMaximumDuration = TimeInterval(30.0)
                    
                    present(imagePicker, animated: false, completion: nil)
                    
                }
            }
        }
        
        self.setNavigation()
        postImagesArr.removeAllObjects()
        postImagesCheckArr.removeAllObjects()
        
        self.flashBtn.setImage(#imageLiteral(resourceName: "flashOn"), for: .normal)
        isFlashOn = false
        
        
        self.profileImageData = nil
        self.coverImage = nil
        self.videoData = nil
        
        PersmissionsHandler.requestCameraAccess(onCompletion: { (success) in
            if success {
                self.sessionQueue.async {
                    if !self.sessionConfigured {
                        self.configureSession()
                    }
                    self.startCamera()
                }
            }
        })
        
    }
    
    override func setNavigation(){
        super.setNavigation()
        addBackButton(color: .white)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.navigationBar.isHidden = true
        
        sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
                //self.removeObservers()
            }
        }
        
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    // MARK: Session Management
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }

    var previewLayer = AVCaptureVideoPreviewLayer()
    var movieOutput = AVCaptureMovieFileOutput()
    var captureDevice:AVCaptureDevice?

    private var session = AVCaptureSession()
    private var isSessionRunning = false
    
    /// Communicate with the session and other session objects on this queue.
    private let sessionQueue = DispatchQueue(label: "session queue")
   
    
    private var setupResult: SessionSetupResult = .success
    
    var videoDeviceInput: AVCaptureDeviceInput!
    
    @IBOutlet private weak var previewView: PreviewView!
    
    // Call this on the session queue.
    private func startCamera() {
        switch self.setupResult {
        case .success:
            
            // Only setup observers and start the session running if setup succeeded.
            //self.addObservers()
            self.session.startRunning()
            self.isSessionRunning = self.session.isRunning
            
        case .notAuthorized:
            DispatchQueue.main.async {
                let changePrivacySetting = "AVCam doesn't have permission to use the camera, please change privacy settings"
                let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
                let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                        style: .cancel,
                                                        handler: nil))
                
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                                                        style: .`default`,
                                                        handler: { _ in
                                                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                }))
                
                self.present(alertController, animated: true, completion: nil)
            }
            
        case .configurationFailed:
            DispatchQueue.main.async {
                let alertMsg = "Alert message when something goes wrong during capture session configuration"
                let message = NSLocalizedString("Unable to capture media", comment: alertMsg)
                let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                        style: .cancel,
                                                        handler: nil))
                
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    // Call this on the session queue.
    private func configureSession() {
        if setupResult != .success {
            return
        }
        
        session.beginConfiguration()
        
        /*
         We do not create an AVCaptureMovieFileOutput when setting up the session because the
         AVCaptureMovieFileOutput does not support movie recording with AVCaptureSession.Preset.Photo.
         */
        session.sessionPreset = .photo
        
        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            // Choose the back dual camera if available, otherwise default to a wide angle camera.
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                // If the back dual camera is not available, default to the back wide angle camera.
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                /*
                 In some cases where users break their phones, the back wide angle camera is not available.
                 In this case, we should default to the front wide angle camera.
                 */
                defaultVideoDevice = frontCameraDevice
            }
            
            // If don't have camera access
            guard let device = defaultVideoDevice else {
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: device)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async {
                    /*
                     Why are we dispatching this to the main queue?
                     Because AVCaptureVideoPreviewLayer is the backing layer for PreviewView and UIView
                     can only be manipulated on the main thread.
                     Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
                     on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                     
                     Use the status bar orientation as the initial video orientation. Subsequent orientation changes are
                     handled by CameraViewController.viewWillTransition(to:with:).
                     */
                    let initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    
                    self.previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                    
                    self.previewView.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                    
                }
            } else {
                Logger.logInfo(value: "Could not add video device input to the session")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        } catch {
            
            Logger.logInfo(value: "Could not create video device input: \(error)")
            
            setupResult = .configurationFailed
            
            session.commitConfiguration()
            
            return
        }
        
        // Add photo output.
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
            photoOutput.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported
            
        } else {
            Logger.logInfo(value: "Could not add photo output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
        
        sessionConfigured = true
    }
    
    // MARK: Device Configuration
    
    @IBOutlet private weak var cameraButton: UIButton!
    
    @IBOutlet private weak var cameraUnavailableLabel: UILabel!
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera],
                                                                               mediaType: .video, position: .unspecified)
    
    @IBAction private func changeCamera(_ cameraButton: UIButton) {
        PersmissionsHandler.requestCameraAccess(onCompletion: { (success) in
            if success {
                
                self.sessionQueue.async {
                    let currentVideoDevice = self.videoDeviceInput.device
                    let currentPosition = currentVideoDevice.position
                    
                    let preferredPosition: AVCaptureDevice.Position
                    let preferredDeviceType: AVCaptureDevice.DeviceType
                    
                    switch currentPosition {
                    case .unspecified, .front:
                        preferredPosition = .back
                        preferredDeviceType = .builtInDualCamera
                        
                    case .back:
                        preferredPosition = .front
                        preferredDeviceType = .builtInWideAngleCamera
                    @unknown default:
                        fatalError()
                    }
                    
                    let devices = self.videoDeviceDiscoverySession.devices
                    var newVideoDevice: AVCaptureDevice? = nil
                    
                    // First, look for a device with both the preferred position and device type. Otherwise, look for a device with only the preferred position.
                    if let device = devices.first(where: { $0.position == preferredPosition && $0.deviceType == preferredDeviceType }) {
                        newVideoDevice = device
                    } else if let device = devices.first(where: { $0.position == preferredPosition }) {
                        newVideoDevice = device
                    }
                    
                    if let videoDevice = newVideoDevice {
                        do {
                            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                            
                            self.session.beginConfiguration()
                            
                            /// Remove the existing device input first, since using the front and back camera simultaneously is not supported.
                            self.session.removeInput(self.videoDeviceInput)
                            
                            if self.session.canAddInput(videoDeviceInput) {
                                NotificationCenter.default.removeObserver(self, name: .AVCaptureDeviceSubjectAreaDidChange, object: currentVideoDevice)
                                
                                self.session.addInput(videoDeviceInput)
                                self.videoDeviceInput = videoDeviceInput
                            } else {
                                self.session.addInput(self.videoDeviceInput)
                            }
                            
                            
                             /// Set Live Photo capture and depth data delivery if it is supported. When changing cameras, the
                             /// `livePhotoCaptureEnabled and depthDataDeliveryEnabled` properties of the AVCapturePhotoOutput gets set to NO when
                             /// a video device is disconnected from the session. After the new video device is
                             /// added to the session, re-enable them on the AVCapturePhotoOutput if it is supported.
                             
                            self.photoOutput.isLivePhotoCaptureEnabled = self.photoOutput.isLivePhotoCaptureSupported
                            self.photoOutput.isDepthDataDeliveryEnabled = self.photoOutput.isDepthDataDeliverySupported
                            
                            self.session.commitConfiguration()
                        } catch {
                            Logger.logInfo(value: "Error occured while creating video device input: \(error)")
                        }
                    }
                }
            }
        })
    }
    
    let minimumZoom: CGFloat = 1.0
    let maximumZoom: CGFloat = 3.0
    var lastZoomFactor: CGFloat = 1.0
    
    @IBAction func pinchGester_tap(_ sender: Any) {
        PersmissionsHandler.requestCameraAccess(onCompletion: { (success) in
            if success {
                
                let device = self.videoDeviceInput.device
                
                // Return zoom value between the minimum and maximum zoom values
                func minMaxZoom(_ factor: CGFloat) -> CGFloat {
                    return min(min(max(factor, self.minimumZoom), self.maximumZoom), device.activeFormat.videoMaxZoomFactor)
                }
                
                func update(scale factor: CGFloat) {
                    do {
                        try device.lockForConfiguration()
                        defer { device.unlockForConfiguration() }
                        device.videoZoomFactor = factor
                    } catch {
                        Logger.logInfo(value: "\(error.localizedDescription)")
                    }
                }
                
                let newScaleFactor = minMaxZoom((sender as! UIPinchGestureRecognizer).scale * self.lastZoomFactor)
                
                switch (sender as! UIPinchGestureRecognizer).state {
                case .began: fallthrough
                case .changed: update(scale: newScaleFactor)
                case .ended:
                    self.lastZoomFactor = minMaxZoom(newScaleFactor)
                    update(scale: self.lastZoomFactor)
                default: break
                }
            }
        })
    }
    
    @IBAction private func focusAndExposeTap(_ gestureRecognizer: UITapGestureRecognizer) {
        PersmissionsHandler.requestCameraAccess(onCompletion: { (success) in
            if success {
                let devicePoint = self.previewView.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: gestureRecognizer.location(in: gestureRecognizer.view))
                self.focus(with: .autoFocus, exposureMode: .autoExpose, at: devicePoint, monitorSubjectAreaChange: true)
            }
            
        })
    }
    
    private func focus(with focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {
        sessionQueue.async {
					let device : AVCaptureDevice = self.videoDeviceInput.device
            do {
                try device.lockForConfiguration()
                
                 /*
                 Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
                 Call set(Focus/Exposure)Mode() to apply the new point of interest.
                 */
                
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = focusMode
                }
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = exposureMode
                }
                
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            } catch {
                Logger.logInfo(value: "Could not lock device for configuration: \(error)")
            }
        }
    }
    
    @IBAction func tapGallery_btn(_ sender: Any) {
        PersmissionsHandler.requestPhotosAccess(onCompletion: { (success) in
            if success {
                AppStateManager.instance.checkImage = 1
                
                self.imageParam = "image"
                self.imagePicker.sourceType = .photoLibrary
                self.imagePicker.delegate = self
                self.imagePicker.mediaTypes = [kUTTypeImage as String]
                
                self.present(self.imagePicker, animated: true, completion: nil)
            }
        })
    }
    
    
  
    
    // MARK: START-Video
    @IBAction func tapCamera_btn(_ sender: Any) {
        PersmissionsHandler.requestCameraAccess(onCompletion: { (success) in
            if success {
                
                PersmissionsHandler.requestMicrophoneAccess(onCompletion: { (success) in
                    
                    if success {

                        // Updated by ASIM KHAN
                        /*
                        self.setupCaptureSession()
                        */

                        AppStateManager.instance.checkImage = 1
                        
                        self.imageParam = "video"
                        self.imagePicker.sourceType = .camera
                        self.imagePicker.mediaTypes = [kUTTypeMovie as String]
                        self.imagePicker.delegate = self
                        self.imagePicker.allowsEditing = false
											 self.imagePicker.videoMaximumDuration = TimeInterval(30.0)
                        
                        self.present(self.imagePicker, animated: true, completion: nil)


                    }
                })
                
            }
        })
        
        
    }

		//MARK: LOAD-Video
    @IBAction func tapVideoGallery_btn(_ sender: Any) {
        PersmissionsHandler.requestPhotosAccess(onCompletion: { (success) in
            if success {
                AppStateManager.instance.checkImage = 1
                
                self.imageParam = "video"
                self.imagePicker.sourceType = .photoLibrary
                self.imagePicker.mediaTypes = [kUTTypeMovie as String]
                self.imagePicker.delegate = self
                self.imagePicker.allowsEditing = false
                self.imagePicker.videoMaximumDuration = TimeInterval(30.0)
                
                self.present(self.imagePicker, animated: true, completion: nil)
            }
        })
        
    }
    
    // MARK: Capturing Photos
    
    private let photoOutput = AVCapturePhotoOutput()
    
    private var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureProcessor]()
    
    @IBOutlet private weak var photoButton: UIButton!
    
    @IBAction func tapFlashBtn(_ sender: Any) {
        PersmissionsHandler.requestCameraAccess(onCompletion: { (success) in
            if success {
                if self.flashBtn.imageView?.image == #imageLiteral(resourceName: "flash_Off"){
                    self.flashBtn.setImage(#imageLiteral(resourceName: "flashOn"), for: .normal)
                    self.isFlashOn = true
                } else {
                    self.flashBtn.setImage(#imageLiteral(resourceName: "flash_Off"), for: .normal)
                    self.isFlashOn = false
                }
            }
        })
    }
    
    @IBAction private func capturePhoto(_ photoButton: UIButton) {
        PersmissionsHandler.requestCameraAccess(onCompletion: { (success) in
            if success {
                let videoPreviewLayerOrientation = self.previewView.videoPreviewLayer.connection?.videoOrientation
                
                self.sessionQueue.async {
                    // Update the photo output's connection to match the video orientation of the video preview layer.
                    if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                        photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
                    }
                    
                    var photoSettings = AVCapturePhotoSettings()
                    // Capture HEIF photo when supported, with flash set to auto and high resolution photo enabled.
                    if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                        
                        photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                        
                    }
                    
                    /*
                    if self.flashBtn.imageView?.image == #imageLiteral(resourceName: "flashOn"){
                        
                        if self.videoDeviceInput.device.isFlashAvailable {
                            
                            photoSettings.flashMode = .on
                        }
                        
                    }else if self.flashBtn.imageView?.image == #imageLiteral(resourceName: "flash_Off"){
                        
                        if self.videoDeviceInput.device.isFlashAvailable {
                            
                            photoSettings.flashMode = .off
                        }
                    }
                    */
                    
                    if (self.isFlashOn) {
                        photoSettings.flashMode = .on
                    } else {
                        photoSettings.flashMode = .off
                    }
                    
                    /*
                    if self.videoDeviceInput.device.isFlashAvailable {
                        photoSettings.flashMode = .auto
                    }
                    */
                    
                    photoSettings.isHighResolutionPhotoEnabled = true
                    if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
                        photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
                    }
                    
                    photoSettings.isDepthDataDeliveryEnabled = false
                    
                    // Use a separate object for the photo capture delegate to isolate each capture life cycle.
                    let photoCaptureProcessor = PhotoCaptureProcessor(with: photoSettings, with: self.videoDeviceInput.device , willCapturePhotoAnimation: {
                        /*
                        DispatchQueue.main.async {
                            self.previewView.videoPreviewLayer.opacity = 0
                            UIView.animate(withDuration: 0.25) {
                                self.previewView.videoPreviewLayer.opacity = 1
                            }
                        }
                        */
                    }, livePhotoCaptureHandler: { capturing in
                        
                        
                        
                    }, completionHandler: { photoCaptureProcessor in
                        
                        
                        // When the capture is complete, remove a reference to the photo capture delegate so it can be deallocated.
                        /*
                        self.sessionQueue.async {
                            self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = nil
                        }
                        */
                    }
                    )
                    
                    /*
                     The Photo Output keeps a weak reference to the photo capture delegate so
                     we store it in an array to maintain a strong reference to this object
                     until the capture is completed.
                     */
                    self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor
                    
                    self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
                    
                    photoCaptureProcessor.delegate = self
                    
                }
            }
            
        })
        
    }
    
    
    func outPutCapture(_ image:UIImage?){
        
        Logger.logInfo(value: "delegate call")
        
        AppStateManager.instance.checkImage = 1
        imagePicker.dismiss(animated: true, completion: { })
        
        /*
        if captureDevice?.position == AVCaptureDevice.Position.back {
            if let image = context.createCGImage(ciImage, from: imageRect) {
                return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .right)
            }
        }

        if captureDevice?.position == AVCaptureDevice.Position.front {
            if let image = context.createCGImage(ciImage, from: imageRect) {
                return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .leftMirrored)

            }
        }
        */
       


        
        if let image = image {
            let vc = AppStoryboard.Secondary.instance.instantiateViewController(withIdentifier: "FAImageCropperVC") as! FAImageCropperVC
            vc.selectedImage = image
            vc.delegate = self

            //tabBarController?.present(BaseNavController(rootViewController: vc), animated: false, completion: nil)
            
            
            self.navigationController!.isNavigationBarHidden = false
            self.navigationController!.pushViewController(vc, animated: true)

        }
    }

}

@available(iOS 10.2, *)
extension CameraViewController : ABVideoRangeSliderDelegate {
	func didChangeValue(videoRangeSlider: ABVideoRangeSlider, startTime: Float64, endTime: Float64) {

		self.endTime = endTime

		if startTime != self.startTime{
			self.startTime = startTime

			let timescale = self.avPlayer.currentItem?.asset.duration.timescale
			let time = CMTimeMakeWithSeconds(self.startTime, preferredTimescale: timescale!)
			if !self.isSeeking{
				self.isSeeking = true
				avPlayer.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero){_ in
					self.isSeeking = false
				}
			}
		}
	}

	func indicatorDidChangePosition(videoRangeSlider: ABVideoRangeSlider, position: Float64) {
		self.shouldUpdateProgressIndicator = false

		// Pause the player
		avPlayer.pause()
		playBtn.isEnabled = true
		pauseBtn.isEnabled = false

		if self.progressTime != position {
			self.progressTime = position
			let timescale = self.avPlayer.currentItem?.asset.duration.timescale
			let time = CMTimeMakeWithSeconds(self.progressTime, preferredTimescale: timescale!)
			if !self.isSeeking{
				self.isSeeking = true
				avPlayer.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero){_ in
					self.isSeeking = false
				}
			}
		}

	}



}


@available(iOS 10.2, *)
extension CameraViewController : UIImagePickerControllerDelegate , UINavigationControllerDelegate , TOCropViewControllerDelegate {
    
    @objc func upload() {
        
        AppStateManager.instance.checkImage = 1
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Upload Image", style: UIAlertAction.Style.default, handler: { (alert:UIAlertAction!) -> Void in
            
            self.imageParam = "image"
            
            self.uploadImage()
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Upload Video", style: UIAlertAction.Style.default, handler: { (alert:UIAlertAction!) -> Void in
            
            self.imageParam = "video"
            
            self.uploadImage()
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        
        if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad)  {
            
            actionSheet.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width, y: self.view.bounds.size.height, width: 1.0, height: 1.0)
            
        }
        
        actionSheet.popoverPresentationController?.sourceView = self.view
        
        present(actionSheet, animated: true, completion: nil)
        
    }
    
    @objc func uploadImage() {
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        var title = ""
        if self.imageParam == "image" {
            title = "Take Photo"
        }else {
            title = "Record Video"
            
        }
        actionSheet.addAction(UIAlertAction(title: title, style: UIAlertAction.Style.default, handler: { (alert:UIAlertAction!) -> Void in
            
            self.camera()
            
        }))
        
        if self.imageParam == "image" {
            title = "Choose Photo"
        }else {
            title = "Choose Video"
            
        }
        actionSheet.addAction(UIAlertAction(title: title, style: UIAlertAction.Style.default, handler: { (alert:UIAlertAction!) -> Void in
            
            self.photoLibrary()
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        
        if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad)  {
            
            actionSheet.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width, y: self.view.bounds.size.height, width: 1.0, height: 1.0)
            
        }
        
        actionSheet.popoverPresentationController?.sourceView = self.view
        
        present(actionSheet, animated: true, completion: nil)
        
    }
    
    
    @objc func camera(){
        PersmissionsHandler.requestCameraAccess { (success) in
            if success {
                if self.imageParam == "image" {
                    self.imagePicker.sourceType = .camera
                    self.imagePicker.mediaTypes = [kUTTypeImage as String]
                    
                    self.present(self.imagePicker, animated: true, completion: nil)
                } else {
                    self.imagePicker.sourceType = .camera
                    self.imagePicker.mediaTypes = [kUTTypeMovie as String]
                    self.imagePicker.delegate = self
                    self.imagePicker.allowsEditing = false
                    self.imagePicker.videoMaximumDuration = TimeInterval(30.0)
                    
                    self.present(self.imagePicker, animated: true, completion: nil)
                }
            }
        }
    }
    
    
    @objc func photoLibrary() {
        PersmissionsHandler.requestCameraAccess { (success) in
            if success {
                if self.imageParam == "image" {
                    self.imagePicker.sourceType = .photoLibrary
                    self.imagePicker.mediaTypes = [kUTTypeImage as String]
                    
                    self.present(self.imagePicker, animated: true, completion: nil)
                } else {
                    self.imagePicker.sourceType = .photoLibrary
                    self.imagePicker.mediaTypes = [kUTTypeMovie as String]
                    self.imagePicker.delegate = self
                    self.imagePicker.allowsEditing = false
                    self.imagePicker.videoMaximumDuration = TimeInterval(30.0)
                    
                    self.present(self.imagePicker, animated: true, completion: nil)
                }
            }
        }
    }
    
		// MARK: - ImagePicker
    @objc  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

				// Local variable inserted by Swift 4.2 migrator.
				let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        
        if self.imageParam == "image" {
            imagePicker.dismiss(animated: true, completion: nil)
            
            guard let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage else {
                return
            }
            
            /*
            let vc = AppStoryboard.Secondary.instance.instantiateViewController(withIdentifier: "FAImageCropperVC") as! FAImageCropperVC
            vc.selectedImage = image

								vc.delegate = self

            tabBarController?.present(BaseNavController(rootViewController: vc), animated: false, completion: nil)
            */
            
								/*
								self.navigationController!.isNavigationBarHidden = false
								self.navigationController!.pushViewController(vc, animated: true)
								*/

        } else {

						/*
						if let pickedVideo:NSURL = (info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaURL)] as? NSURL) {

							let vc = AppStoryboard.Main.instance.instantiateViewController(withIdentifier: "trimLoadedVideoFromLibrary") as! trimLoadedVideoFromLibrary

							vc.pathURL = pickedVideo
							vc.delegate = self

							//vc.postId = String(describing:(self.postData.object(at: sender.tag) as! NSDictionary).value(forKey: "id")!)

							//self.navigationController?.pushViewController(vc, animated: true)

							//tabBarController?.present(BaseNavController(rootViewController: vc), animated: false, completion: nil)
							dismiss(animated: true, completion: nil)
							present(vc, animated: true, completion: nil)


						}
						*/

						/*

						if let pickedVideo:NSURL = (info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaURL)] as? NSURL) {

								// Video Trimmer
								self.pathURL = pickedVideo
								videoContainer.isHidden = false


							 navigationController!.setToolbarHidden(false, animated: false)
								let playerItem = AVPlayerItem(url: pickedVideo as URL)
								avPlayer.replaceCurrentItem(with: playerItem)
								avPlayerLayer = AVPlayerLayer(player: avPlayer)
								avPlayerLayer.frame = videoContainer.bounds


						videoContainer.layer.insertSublayer(avPlayerLayer, at: 0)
								videoContainer.layer.masksToBounds = true

								videoTrimmerView.setVideoURL(videoURL: pickedVideo as URL)
								videoTrimmerView.delegate = self
								self.endTime = CMTimeGetSeconds((avPlayer.currentItem?.duration)!)
							let timeInterval: CMTime = CMTimeMakeWithSeconds(0.01, preferredTimescale: 100)
								timeObserver = avPlayer.addPeriodicTimeObserver(forInterval: timeInterval,
																															queue: DispatchQueue.main) { (elapsedTime: CMTime) -> Void in
																																self.observeTime(elapsedTime: elapsedTime) } as AnyObject

								// OLD Code for Trimming
								/*
								videoTrimmerView.setVideoURL(videoURL: pickedVideo as URL)
								videoTrimmerView.isHidden = false
								// Set the Trim Defaults
								// Set the delegate
								videoTrimmerView.delegate = self

								// Set a minimun space (in seconds) between the Start indicator and End indicator
								videoTrimmerView.minSpace = 60.0

								// Set a maximun space (in seconds) between the Start indicator and End indicator - Default is 0 (no max limit)
								videoTrimmerView.maxSpace = 120.0
								// Set initial position of Start Indicator
								videoTrimmerView.setStartPosition(seconds: 50.0)

								// Set initial position of End Indicator
								videoTrimmerView.setEndPosition(seconds: 150.0)
								*/
							let vc = AppStoryboard.Main.instance.instantiateViewController(withIdentifier: "myFansViewController") as! myFansViewController

							vc.checkVC = "share"

							//vc.postId = String(describing:(self.postData.object(at: sender.tag) as! NSDictionary).value(forKey: "id")!)

						 /*
						 self.navigationController?.pushViewController(vc, animated: true)
								dismiss(animated: true, completion: nil)
						 */

						}
						*/

						// Uploading
            if let pickedVideo:NSURL = (info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaURL)] as? NSURL) {
                
                if UserDefaults.standard.value(forKey: "AnimateVideoThumbnail") != nil && UserDefaults.standard.value(forKey: "AnimateVideoThumbnail") as? NSData != nil {
                    
                    let coverImage:UIImage = UIImage(data: UserDefaults.standard.value(forKey: "AnimateVideoThumbnail") as! Data)!
                    
                    let thumbnail = coverImage
                    
                    postImagesArr.add(thumbnail)
                    
                    postImagesCheckArr.add(1)
                    
                    self.coverImage = thumbnail.fixOrientation().jpegData(compressionQuality: 0.3)! as NSData
                    
                    UserDefaults.standard.removeObject(forKey: "AnimateVideoThumbnail")
                    
                } else {
                    
                    do {
                        
                        let asset = AVURLAsset(url: pickedVideo as URL , options: nil)
                        
                        let imgGenerator = AVAssetImageGenerator(asset: asset)
                        
                        imgGenerator.appliesPreferredTrackTransform = true
                        
                        let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
                        
                        let thumbnail = UIImage(cgImage: cgImage)
                        
                        postImagesArr.add(thumbnail)
                        
                        postImagesCheckArr.add(1)
                        
                        self.coverImage = thumbnail.fixOrientation().jpegData(compressionQuality: 0.3)! as NSData
                        
                    } catch let error {
                        
                        Logger.logInfo(value: "*** Error generating thumbnail: \(error.localizedDescription)")
                        
                    }
                    
                }
                
                do {
                    self.videoData = try Data(contentsOf: pickedVideo as URL) as NSData
                    
                    Logger.logInfo(value: "File size before compression: \(Double(videoData.length / 1048576)) mb")
                    let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".m4v")
                    compressVideo(inputURL: pickedVideo as URL, outputURL: compressedURL) { (exportSession) in
                        guard let session = exportSession else {
                            return
                        }
                        
                        switch session.status {
                        case .unknown:
                            break
                        case .waiting:
                            break
                        case .exporting:
                            break
                        case .completed:
                            guard let compressedData = NSData(contentsOf: compressedURL) else {
                                return
                            }
                            
                            self.videoData = compressedData
                            
                            Logger.logInfo(value: "File size after compression: \(Double(compressedData.length / 1048576)) mb")
                        case .failed:
                            break
                        case .cancelled:
                            break
                        @unknown default:
                            fatalError()
                        }
                    }
                    
                    
                } catch {
                    Logger.logInfo(value: "Unable to load data: \(error)")
                }
                
                
                
                /*
                let vc = AppStoryboard.Secondary.instance.instantiateViewController(withIdentifier: "createPostViewController") as! createPostViewController

                vc.postImagesCheckArr = postImagesCheckArr

                vc.coverImage = self.coverImage

                vc.videoData = self.videoData

                vc.postImagesArr = self.postImagesArr

                vc.imageParam = "video"

						self.navigationController?.pushViewController(vc, animated: true)

                dismiss(animated: true, completion: nil)
                */
                
            }
        }
    }

		// MARK:- VideoTrimmingFunctions
		@IBAction func playTapped(_ sender: Any) {
			avPlayer.play()
			shouldUpdateProgressIndicator = true
			playBtn.isEnabled = false
			pauseBtn.isEnabled = true
		}

		@IBAction func pauseTapped(_ sender: Any) {
			avPlayer.pause()
			playBtn.isEnabled = true
			pauseBtn.isEnabled = false
		}

		// MARK:- SaveTapped
		@IBAction func saveTapped(_ sender: Any) {
			// Saving
			self.cropVideo(sourceURL1: self.pathURL, statTime: Float(startTime), endTime: Float(endTime))
		}

		func cropVideo(sourceURL1: NSURL, statTime:Float, endTime:Float)
		{
			let manager = FileManager.default

			guard let documentDirectory = try? manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {return}
			 let mediaType = "mp4"
			 let url = sourceURL1

			if mediaType == kUTTypeMovie as String || mediaType == "mp4" as String {
				let asset = AVAsset(url: url as URL)
				let length = Float(asset.duration.value) / Float(asset.duration.timescale)
				print("video length: \(length) seconds")

				let start = statTime
				let end = endTime

				var outputURL = documentDirectory.appendingPathComponent("output")
				do {
					try manager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
					let name = "hostent.newName()"
					outputURL = outputURL.appendingPathComponent("\(name).mp4")
				}catch let error {
					print(error)
				}

				//Remove existing file
				_ = try? manager.removeItem(at: outputURL)


				guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {return}
				exportSession.outputURL = outputURL
				exportSession.outputFileType = AVFileType.mp4

				let startTime = CMTime(seconds: Double(start ), preferredTimescale: 1000)
				let endTime = CMTime(seconds: Double(end ), preferredTimescale: 1000)
				let timeRange = CMTimeRange(start: startTime, end: endTime)

				exportSession.timeRange = timeRange
				exportSession.exportAsynchronously{
					switch exportSession.status {
					case .completed:
						print("exported at \(outputURL)")
						//self.saveVideoTimeline(outputURL)
						self.uploadTrimmedVideo(outputURL: outputURL as NSURL)
					case .failed:
						print("failed \(String(describing: exportSession.error))")

					case .cancelled:
						print("cancelled \(String(describing: exportSession.error))")

					default: break
					}
				}
			}
		}

		func uploadTrimmedVideo(outputURL : NSURL) {

			if UserDefaults.standard.value(forKey: "AnimateVideoThumbnail") != nil && UserDefaults.standard.value(forKey: "AnimateVideoThumbnail") as? NSData != nil {

				// User Defaults
				let coverImage:UIImage = UIImage(data: UserDefaults.standard.value(forKey: "AnimateVideoThumbnail") as! Data)!

				let thumbnail = coverImage

				postImagesArr.add(thumbnail)

				postImagesCheckArr.add(1)

				self.coverImage = thumbnail.fixOrientation().jpegData(compressionQuality: 0.3)! as NSData

				UserDefaults.standard.removeObject(forKey: "AnimateVideoThumbnail")

			}else{

				do {

					let asset = AVURLAsset(url: outputURL as URL , options: nil)

					let imgGenerator = AVAssetImageGenerator(asset: asset)

					imgGenerator.appliesPreferredTrackTransform = true

					let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)

					let thumbnail = UIImage(cgImage: cgImage)

					postImagesArr.add(thumbnail)

					postImagesCheckArr.add(1)

					self.coverImage = thumbnail.fixOrientation().jpegData(compressionQuality: 0.3)! as NSData

				} catch let error {

					Logger.logInfo(value: "*** Error generating thumbnail: \(error.localizedDescription)")

				}

			}

			do {
					self.videoData = try Data(contentsOf: outputURL as URL) as NSData

					Logger.logInfo(value: "File size before compression: \(Double(videoData.length / 1048576)) mb")
					let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".m4v")
						compressVideo(inputURL: outputURL as URL, outputURL: compressedURL) { (exportSession) in
						guard let session = exportSession else {
						return
					}

					switch session.status {
						case .unknown:
						break
						case .waiting:
						break
						case .exporting:
						break
						case .completed:
						guard let compressedData = NSData(contentsOf: compressedURL) else {
						return
						}

						self.videoData = compressedData

						Logger.logInfo(value: "File size after compression: \(Double(compressedData.length / 1048576)) mb")
						case .failed:
						break
						case .cancelled:
						break
                    @unknown default:
                        fatalError()
                            }
				}


			} catch {
				Logger.logInfo(value: "Unable to load data: \(error)")
			}


			// Move to Next
            /*
			let vc = AppStoryboard.Secondary.instance.instantiateViewController(withIdentifier: "createPostViewController") as! createPostViewController

			vc.postImagesCheckArr = postImagesCheckArr

			vc.coverImage = self.coverImage

			vc.videoData = self.videoData

			vc.postImagesArr = self.postImagesArr

			vc.imageParam = "video"

			self.navigationController?.pushViewController(vc, animated: true)

			dismiss(animated: true, completion: nil)
            */

		}

		private func observeTime(elapsedTime: CMTime) {
			let elapsedTime = CMTimeGetSeconds(elapsedTime)

			if (avPlayer.currentTime().seconds > self.endTime){
				avPlayer.pause()
				playBtn.isEnabled = true
				pauseBtn.isEnabled = false
			}

			if self.shouldUpdateProgressIndicator{
				videoTrimmerView.updateProgressIndicator(seconds: elapsedTime)
			}
		}

		// MARK: TrimmedDelegate
		func videoTrimmed(_ outputSource : [String : Any]) {

			// Move to Next
            /*
			let vc = AppStoryboard.Secondary.instance.instantiateViewController(withIdentifier: "createPostViewController") as! createPostViewController

			vc.postImagesCheckArr = outputSource["post_image_check_array"] as! NSMutableArray
			vc.coverImage = outputSource["cover_image"] as? NSData
			vc.videoData = outputSource["video_data"] as? NSData
			vc.postImagesArr = outputSource["post_image_array"] as! NSMutableArray
			vc.imageParam = outputSource["type"] as! String

			self.navigationController?.pushViewController(vc, animated: true)
            */

			
		}

    // MARK: - CroppingFunctions
    func sendCroppedImage(_ image: UIImage) {
        
        
        back()
        back()
        self.delegate.sendCroppedImage(image)
        
        
        
        /*
        let photoEditor = PhotoEditorViewController(nibName:"PhotoEditorViewController",bundle: Bundle(for: PhotoEditorViewController.self))

        photoEditor.photoEditorDelegate = self

        photoEditor.image = image

        for i in 1...24 {

            photoEditor.stickers.append(UIImage(named: i.description)!)

        }

        for _ in 25...46 {

            //photoEditor.stickers.append(UIImage.gif(name: i.description)!)

        }

        photoEditor.hiddenControls = [.share, .draw, .text, .crop, .save]

        photoEditor.colors = [.red,.blue,.green]

        present(photoEditor, animated: true, completion: nil)
        */
        
    }
    
    func compressVideo(inputURL: URL, outputURL: URL, handler:@escaping (_ exportSession: AVAssetExportSession?)-> Void) {
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetLowQuality) else {
            handler(nil)
            
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mov
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously { () -> Void in
            handler(exportSession)
        }
    }
    
    func doneEditing(image: UIImage) {
        
        self.postImagesCheckArr.removeAllObjects()
        
        self.postImagesCheckArr.removeAllObjects()
        
        self.profileImageData = image.fixOrientation().jpegData(compressionQuality: 0.3)! as NSData
        
        postImagesArr.add(image)
        
        postImagesCheckArr.add(0)
        
        /*
        let vc = AppStoryboard.Secondary.instance.instantiateViewController(withIdentifier: "createPostViewController") as! createPostViewController
        
        vc.postImagesArr =  postImagesArr
        
        vc.postImagesCheckArr = postImagesCheckArr
        
        vc.profileImageData = self.profileImageData
        
        vc.imageParam = "image"
        
        self.navigationController?.pushViewController(vc, animated: true)
        
        collection.reloadData()
        sendData()
        
        PhotoEditorViewController.dismiss(animated: true, completion: nil)
        */
    }
    
    func canceledEditing() {
        
        Logger.logInfo(value: "Canceled")
    }
    
    @objc func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        dismiss(animated: true, completion: nil)
        
    }

    func cropViewController(_ cropViewController: TOCropViewController, didCropImageTo cropRect: CGRect, angle: Int) {

    }

    func cropViewController(_ cropViewController: TOCropViewController, didCropTo image: UIImage, with cropRect: CGRect, angle: Int) {

    }
    
    /*
    @objc func cropViewController(_ cropViewController: TOCropViewController, didCropToImage image: UIImage, rect cropRect: CGRect, angle: Int) {
    }
    */
}

@available(iOS 10.2, *)
extension CameraViewController: AVCaptureMetadataOutputObjectsDelegate {
	func removeDevicesFromCaptureSession() {
		if let inputs = self.session.inputs as? [AVCaptureDeviceInput] {
			for input in inputs {
				self.session.removeInput(input)
			}
		}

	}

	func captureCustomCameraVideo() {
		self.removeDevicesFromCaptureSession()

		/*
		let videoFrontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
		*/
		let videoBackCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)
		let microPhone = AVCaptureDevice.default(.builtInMicrophone, for: AVMediaType.audio, position: .unspecified)

		do {
			let videoInputCam = try AVCaptureDeviceInput(device: videoBackCamera!)

			session.addInput(videoInputCam)
			let videoInputAu = try AVCaptureDeviceInput(device: microPhone!)

			session.addInput(videoInputAu)

			let totalSeconds = 20.0 //Total Seconds of capture time
			let timeScale: Int32 = 10 //FPS

			let maxDuration = CMTimeMakeWithSeconds(totalSeconds, preferredTimescale: timeScale)


			self.movieOutput.maxRecordedDuration = maxDuration
			self.movieOutput.minFreeDiskSpaceLimit = 1024 * 1024//SET MIN FREE SPACE IN BYTES FOR RECORDING TO CONTINUE ON A VOLUME

			if session.canAddOutput(self.movieOutput) {
				session.addOutput(self.movieOutput)
			}


			let videoLayer = AVCaptureVideoPreviewLayer(session: session)
			videoLayer.frame = self.previewView.bounds

			videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill

			self.previewView.layer.addSublayer(videoLayer)

			session.startRunning()
		} catch {
			print("inline-error: Video capturing error.")
		}

	}
	//MARK: Session Startup
	private func setupCaptureSession(){
		removeDevicesFromCaptureSession()
		self.captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
		do {
			let deviceInput = try AVCaptureDeviceInput(device: captureDevice!) as AVCaptureDeviceInput
			//Add the input feed to the session and start it
			self.session.addInput(deviceInput)
			self.setupPreviewLayer {
				self.session.startRunning()
				self.addMetaDataCaptureOutToSession()
			}
		} catch let setupError as NSError {
			print(setupError.localizedDescription)
		}
	}
	private func setupPreviewLayer(completion:() -> ()){
		self.previewLayer = AVCaptureVideoPreviewLayer(session: session) as AVCaptureVideoPreviewLayer
		self.previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
		self.previewLayer.frame = self.previewView.frame
		self.previewView.layer.addSublayer(previewLayer)
		completion()
	}
	//MARK: Metadata capture
	func addMetaDataCaptureOutToSession() {
		let metadata = AVCaptureMetadataOutput()
		self.session.addOutput(metadata)
		metadata.metadataObjectTypes = metadata.availableMetadataObjectTypes
		metadata.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
	}
}

// MARK: — AVCaptureFileOutputRecordingDelegate

extension CameraViewController : AVCaptureFileOutputRecordingDelegate {
	func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {

	}

	func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!){
		// save video to camera roll
		if error == nil {
			UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
		}
	}
    
    
}



/*

extension CameraViewController : AVCaptureFileOutputRecordingDelegate {

	func capture( _ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error! )
	{

	}

	func cropVideo( _ outputFileUrl: URL, callback: @escaping ( _ newUrl: URL ) -> () )
	{
		// Get input clip
		let videoAsset: AVAsset = AVAsset( url: outputFileUrl )
		let clipVideoTrack = videoAsset.tracks( withMediaType: AVMediaTypeVideo ).first! as AVAssetTrack

		// Make video to square
		let videoComposition = AVMutableVideoComposition()
		videoComposition.renderSize = CGSize( width: clipVideoTrack.naturalSize.height, height: clipVideoTrack.naturalSize.height )
		videoComposition.frameDuration = CMTimeMake( 1, self.framesPerSecond )

		// Rotate to portrait
		let transformer = AVMutableVideoCompositionLayerInstruction( assetTrack: clipVideoTrack )
		let transform1 = CGAffineTransform( translationX: clipVideoTrack.naturalSize.height, y: -( clipVideoTrack.naturalSize.width - clipVideoTrack.naturalSize.height ) / 2 )
		let transform2 = transform1.rotated(by: CGFloat( M_PI_2 ) )
		transformer.setTransform( transform2, at: kCMTimeZero)

		let instruction = AVMutableVideoCompositionInstruction()
		instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds( self.intendedVideoLength, self.framesPerSecond ) )

		instruction.layerInstructions = [transformer]
		videoComposition.instructions = [instruction]

		// Export
		let croppedOutputFileUrl = URL( fileURLWithPath: FileManager.getOutputPath( String.random() ) )
		let exporter = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality)!
		exporter.videoComposition = videoComposition
		exporter.outputURL = croppedOutputFileUrl
		exporter.outputFileType = AVFileTypeQuickTimeMovie

		exporter.exportAsynchronously( completionHandler: { () -> Void in
			DispatchQueue.main.async(execute: {
				callback( croppedOutputFileUrl )
			})
		})
	}

	func getOutputPath( _ name: String ) -> String
	{
		let documentPath = NSSearchPathForDirectoriesInDomains(      .documentDirectory, .userDomainMask, true )[ 0 ] as NSString
		let outputPath = "\(documentPath)/\(name).mov"
		return outputPath
	}



}
*/




// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
