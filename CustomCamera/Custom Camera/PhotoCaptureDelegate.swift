/*
 
See LICENSE.txt for this sample’s licensing information.

Abstract:
Photo capture delegate.
 
*/

import UIKit
import AVFoundation
import Photos

protocol captureImageOutPut: class {
    func outPutCapture(_ image:UIImage?)
}


class PhotoCaptureProcessor: NSObject {
	private(set) var requestedPhotoSettings: AVCapturePhotoSettings
    private(set) var captureDevice: AVCaptureDevice
	
	private let willCapturePhotoAnimation: () -> Void
	
	private let livePhotoCaptureHandler: (Bool) -> Void
	
	private let completionHandler: (PhotoCaptureProcessor) -> Void
	
	private var photoData: Data?
	
	private var livePhotoCompanionMovieURL: URL?
    
	weak var delegate: captureImageOutPut?

	init(with requestedPhotoSettings: AVCapturePhotoSettings, with captureDevice: AVCaptureDevice,
	     willCapturePhotoAnimation: @escaping () -> Void,
	     livePhotoCaptureHandler: @escaping (Bool) -> Void,
	     completionHandler: @escaping (PhotoCaptureProcessor) -> Void) {
		self.requestedPhotoSettings = requestedPhotoSettings
        self.captureDevice = captureDevice
		self.willCapturePhotoAnimation = willCapturePhotoAnimation
		self.livePhotoCaptureHandler = livePhotoCaptureHandler
		self.completionHandler = completionHandler
	}
	
	private func didFinish() {
		if let livePhotoCompanionMoviePath = livePhotoCompanionMovieURL?.path {
			if FileManager.default.fileExists(atPath: livePhotoCompanionMoviePath) {
				do {
					try FileManager.default.removeItem(atPath: livePhotoCompanionMoviePath)
				} catch {
					Logger.logInfo(value: "Could not remove file at url: \(livePhotoCompanionMoviePath)")
				}
			}
		}
		
		completionHandler(self)
	}

    
}

extension PhotoCaptureProcessor: AVCapturePhotoCaptureDelegate {
    /*
     This extension includes all the delegate callbacks for AVCapturePhotoCaptureDelegate protocol
    */
    
    
    
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        if resolvedSettings.livePhotoMovieDimensions.width > 0 && resolvedSettings.livePhotoMovieDimensions.height > 0 {
            livePhotoCaptureHandler(true)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        willCapturePhotoAnimation()
    }
    
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        

        /*
        if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
          print("image: \(UIImage(data: dataImage)?.size)") // Your Image

            if let image = self.getImageFromSampleBuffer(buffer: sampleBuffer)
           {
              delegate?.outPutCapture(image)
           }


        } else {
             if let image = UIImage(data: photoData!) {



            }
        }
        */

        
        /*
        if #available(iOS 11.0, *) {
            
        } else {
            let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer!, previewPhotoSampleBuffer: previewPhotoSampleBuffer)
            let dataProvider = CGDataProvider(data: imageData! as CFData)
            let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
            let image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImage.Orientation.right)
            
            delegate?.outPutCapture(image)
        }
        */
        
        /*
        self.tempImageView.isHidden = false
        self.yellowButton.isHidden = true
        self.toggleAction.isHidden = true
        self.adorButton.isHidden = true
        */
        print("Output")
    }
    
    
    
    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
         print("Output")
    }
   
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingRawPhoto rawSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
         print("Output")
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if let error = error {
            Logger.logInfo(value: "Error capturing photo: \(error)")
        } else {
            
            if let data = photo.fileDataRepresentation() {
                let image = UIImage(data: data)!
                let ciImage: CIImage = CIImage(cgImage: image.cgImage!).oriented(forExifOrientation: 6)
                let flippedImage = ciImage.transformed(by: CGAffineTransform(scaleX: -1, y: 1))
                
                delegate?.outPutCapture(UIImage.convert(from: flippedImage))

            }
            
            
            if #available(iOS 11.0, *) {
                photoData = photo.fileDataRepresentation()
                
                //let dataProvider = CGDataProvider(data: photoData! as CFData)
                
                /*
                let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
                let image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImage.Orientation.right)
                */
                
                /*
                if let image = self.getImageFromSampleBuffer(buffer: dataProvider?.data as! CMSampleBuffer)
                {
                    delegate?.outPutCapture(image)
                }
                */
                
                //delegate?.outPutCapture(image)
                
                
                /*
                if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
                  print("image: \(UIImage(data: dataImage)?.size)") // Your Image
                }
                */
                
                
            } else {
                // Fallback on earlier versions
                
                if let image = self.getImageFromSampleBuffer(buffer: photoData as! CMSampleBuffer)
                {
                   delegate?.outPutCapture(image)
                }
                
                /*
                if let image = UIImage(data: photoData!) {
                 
                }
                */
            }
            
            

        }
    }
    
    func getImageFromSampleBuffer (buffer:CMSampleBuffer) -> UIImage? {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()

            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))

            /*
            if let image = context.createCGImage(ciImage, from: imageRect) {
                return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .leftMirrored)
            }
            */
            
            
            if captureDevice.position == AVCaptureDevice.Position.back {
               if let image = context.createCGImage(ciImage, from: imageRect) {
                   return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .right)
               }
            }

            if captureDevice.position == AVCaptureDevice.Position.front {
               if let image = context.createCGImage(ciImage, from: imageRect) {
                   return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .leftMirrored)

               }
            }
                  
    }
        return nil
    }

    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishRecordingLivePhotoMovieForEventualFileAt outputFileURL: URL, resolvedSettings: AVCaptureResolvedPhotoSettings) {
        livePhotoCaptureHandler(false)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if error != nil {
            Logger.logInfo(value: "Error processing live photo companion movie: \(String(describing: error))")
            return
        }
        livePhotoCompanionMovieURL = outputFileURL
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = error {
            Logger.logInfo(value: "Error capturing photo: \(error)")
            didFinish()
            return
        }
        
        guard let photoData = photoData else {
            Logger.logInfo(value: "No photo data resource")
            didFinish()
            return
        }
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    if #available(iOS 11.0, *) {
                        options.uniformTypeIdentifier = self.requestedPhotoSettings.processedFileType.map { $0.rawValue }
                    } else {
                        // Fallback on earlier versions
                    }
                    creationRequest.addResource(with: .photo, data: photoData, options: options)
                    
                    if let livePhotoCompanionMovieURL = self.livePhotoCompanionMovieURL {
                        let livePhotoCompanionMovieFileResourceOptions = PHAssetResourceCreationOptions()
                        livePhotoCompanionMovieFileResourceOptions.shouldMoveFile = true
                        creationRequest.addResource(with: .pairedVideo, fileURL: livePhotoCompanionMovieURL, options: livePhotoCompanionMovieFileResourceOptions)
                    }
                    
                    }, completionHandler: { _, error in
                        if let error = error {
                            Logger.logInfo(value: "Error occurered while saving photo to photo library: \(error)")
                        }
                        
                        self.didFinish()
                    }
                )
            } else {
                self.didFinish()
            }
        }
    }
}
