//
//  trimLoadedVideoFromLibrary.swift
//  ShowUOff iPhone Run
//
//  Created by dev shanghai on 26/02/2019.
//  Copyright © 2019 promatics. All rights reserved.
//

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

protocol trimVideoFromLibray: class {
	func videoTrimmed(_ outputSource : [String : Any])
}

class TrimLoadedVideoFromLibrary: UIViewController {

    @IBOutlet weak var videoTrimmerView: ABVideoRangeSlider!
    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet weak var pauseBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
	@IBOutlet weak var playBtnImg: UIImageView!
	
    let avPlayer = AVPlayer()
    var avPlayerLayer: AVPlayerLayer!
    var timeObserver: AnyObject!
    var startTime = 0.0;
    var endTime = 0.0;
    var progressTime = 0.0;
    var pathURL : NSURL!
    var shouldUpdateProgressIndicator = true
    var isSeeking = false

    var delegate : trimVideoFromLibray!


    var postImagesArr : NSMutableArray = []
    var postImagesCheckArr : NSMutableArray = []
    var videoData:NSData!
    var coverImage:NSData!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.


        if self.pathURL != nil {

            videoContainer.isHidden = false
            //navigationController!.setToolbarHidden(false, animated: false)
            let playerItem = AVPlayerItem(url: pathURL as URL)
            avPlayer.replaceCurrentItem(with: playerItem)
            avPlayerLayer = AVPlayerLayer(player: avPlayer)
            avPlayerLayer.frame = videoContainer.bounds

            videoContainer.layer.insertSublayer(avPlayerLayer, at: 0)
            videoContainer.layer.masksToBounds = true

            videoTrimmerView.setVideoURL(videoURL: pathURL as URL)
            videoTrimmerView.delegate = self

            // Set a minimun space (in seconds) between the Start indicator and End indicator
            videoTrimmerView.minSpace = 1.0

            // Set a maximun space (in seconds) between the Start indicator and End indicator - Default is 0 (no max limit)
            videoTrimmerView.maxSpace = 30.0

            // Set initial position of Start Indicator
            videoTrimmerView.setStartPosition(seconds: 0.0)


            if (avPlayer.currentItem?.currentTime().seconds)! > 30.0 {

            } else {



            }


            if let url = pathURL {
                let asset = AVAsset(url: url as URL)

                let duration = asset.duration
                let durationTime = CMTimeGetSeconds(duration)

                print(durationTime)

                if durationTime > 30 {

                    endTime = 30.0
                    // Set initial position of End Indicator
                    videoTrimmerView.setEndPosition(seconds: 30.0)



                } else {

                    // Set initial position of End Indicator
                    videoTrimmerView.setEndPosition(seconds: Float(durationTime))
                    self.endTime = durationTime

                }
            }




            let timeInterval: CMTime = CMTimeMakeWithSeconds(0.01, preferredTimescale: Int32(100.0))
            timeObserver = avPlayer.addPeriodicTimeObserver(forInterval: timeInterval,queue: DispatchQueue.main) { (elapsedTime: CMTime) -> Void in
                 self.observeTime(elapsedTime: elapsedTime) } as AnyObject
        }


    }
    

	// MARK:- VideoTrimmingFunctions
	@IBAction func playTapped(_ sender: Any) {

		if playBtnImg.image == UIImage(named: "play_button") {
			// You can Play
			playBtnImg.image = UIImage(named: "pause_button")
			avPlayer.play()
			shouldUpdateProgressIndicator = true

		} else {
			// You can Pause
			playBtnImg.image = UIImage(named: "play_button")
			avPlayer.pause()

		}
		playBtn.isEnabled = false
		pauseBtn.isEnabled = true
	}

	@IBAction func pauseTapped(_ sender: Any) {
		playBtn.isEnabled = true
		pauseBtn.isEnabled = false
	}

	// MARK:- SaveTapped
	@IBAction func saveTapped(_ sender: Any) {
		// Saving
		self.cropVideo(sourceURL1: self.pathURL, statTime: Float(startTime), endTime: Float(endTime))
	}


	@IBAction func cancelTapped(_ sender: Any) {
		self.navigationController?.popViewController(animated: true)
		dismiss(animated: true, completion: nil)
	}

}

extension TrimLoadedVideoFromLibrary {

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
					//print("exported at \(outputURL)")
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

            self.coverImage = thumbnail.fixOrientation().jpegData(compressionQuality: 0.3) as NSData?
            
            //UIImageJPEGRepresentation(compressionQuality: 0.3) as! NSData
			UserDefaults.standard.removeObject(forKey: "AnimateVideoThumbnail")

		} else {

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
        */

        /*
		var response = Dictionary<String, Any>()
		response["post_image_check_array"] = postImagesCheckArr
		response["cover_image"] = self.coverImage
		response["video_data"] = self.videoData
		response["post_image_array"] = self.postImagesArr
		response["type"] = "video"
		delegate.videoTrimmed(response)
        */

		/*
		vc.postImagesCheckArr = postImagesCheckArr
		vc.coverImage = self.coverImage
		vc.videoData = self.videoData
		vc.postImagesArr = self.postImagesArr
		vc.imageParam = "video"
		*/

        /*
		self.navigationController?.pushViewController(vc, animated: true)

		dismiss(animated: true, completion: nil)
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

	private func observeTime(elapsedTime: CMTime) {
		let elapsedTime = CMTimeGetSeconds(elapsedTime)

		if (avPlayer.currentTime().seconds > self.endTime){
			avPlayer.pause()

			playBtnImg.image = UIImage(named: "play_button")
		}

		if self.shouldUpdateProgressIndicator{
			videoTrimmerView.updateProgressIndicator(seconds: elapsedTime)
		}
	}
}



extension TrimLoadedVideoFromLibrary : ABVideoRangeSliderDelegate {
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
		playBtnImg.image = UIImage(named: "play_button")


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
