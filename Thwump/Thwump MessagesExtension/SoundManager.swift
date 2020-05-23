//
//  Sound.swift
//  Thwump MessagesExtension
//
//  Created by Ben Walker on 2020-04-04.
//  Copyright © 2020 bnwlkr. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

protocol MediaUpdateDelegate {
	func added (sound: Sound)
	func removed (soundTitle: String)
}

class SoundManager {
	
	var mediaUpdateDelegate: MediaUpdateDelegate?
	let fileManager: FileManager
	var documentsDirectoryURL: URL {
		get {
			return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
		}
	}
	
	var mediaDirectoryURL: URL {
		get {
			return documentsDirectoryURL.appendingPathComponent("media")
		}
	}
	
	var audioDirectoryURL: URL {
		get {
			return mediaDirectoryURL.appendingPathComponent("sounds")
		}
	}
	
	var textureDirectoryURL: URL {
		get {
			return mediaDirectoryURL.appendingPathComponent("textures")
		}
	}
	
	var soundOrderJsonURL: URL {
		get {
			return mediaDirectoryURL.appendingPathComponent("order.json")
		}
	}
	
	
	init() {
		self.fileManager = .default
		// create media directory if it doesn't already exist
		if !fileManager.fileExists(atPath: mediaDirectoryURL.path) {
			print("creating media directories")
			do {
				try fileManager.createDirectory(at: audioDirectoryURL, withIntermediateDirectories: true, attributes: nil)
				try fileManager.createDirectory(at: textureDirectoryURL, withIntermediateDirectories: true, attributes: nil)
			} catch {
				print(error)
			}
		}
	}
	
	public func sync (completion: @escaping () -> ()) {
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(5)) {
			AF.request("https://thwump.bnwl.kr/manifest.json").responseJSON { response in
			switch (response.result) {
				case .success(let result):
					let manifestJSON = result as! [String:Any]
					print(manifestJSON)
					let refreshKey = manifestJSON["refreshKey"] as! Int
					let manifestSoundTitles = manifestJSON["soundNames"] as! [String]
					
					// write the ordering specified in the manifest to a file
					let soundOrderJsonData = try? JSONSerialization.data(withJSONObject: manifestSoundTitles, options: .init())
					if soundOrderJsonData != nil {
						try? soundOrderJsonData?.write(to: self.soundOrderJsonURL)
					}
					
					// clear everything if the refreshKey is out of date
					if UserDefaults.standard.integer(forKey: "refreshKey") != refreshKey {
						self.clearAllLocalMedia()
						UserDefaults.standard.set(refreshKey, forKey: "refreshKey")
					}
					
					// delete any local sounds not in the manifest
					for sound in self.getLocalSounds() {
						if !manifestSoundTitles.contains(sound.title) {
							self.deleteSound(soundTitle: sound.title)
							self.mediaUpdateDelegate?.removed(soundTitle: sound.title)
						}
					}
					
					// add any sounds in the manifest not present locally
					let localSoundTitles = self.getLocalSounds().map { $0.title }
					let downloadGroup = DispatchGroup()
					for soundTitle in manifestSoundTitles {
						if !localSoundTitles.contains(soundTitle) {
							downloadGroup.enter()
							self.downloadSound(soundTitle: soundTitle, completion: downloadGroup.leave)
						}
					}
					downloadGroup.notify(queue: .main) {
						completion()
					}
				case .failure(let error):
					print(error)
					completion()
			}
		}
		}
		
	}
	
	func deleteSound(soundTitle: String) {
		print("deleting \(soundTitle)")
		try? fileManager.removeItem(at: textureDirectoryURL.appendingPathComponent("\(soundTitle).png"))
		try? fileManager.removeItem(at: audioDirectoryURL.appendingPathComponent("\(soundTitle).mp4"))
	}
	
	func downloadSound(soundTitle: String, completion: @escaping ()->()) {
		print("downloading \(soundTitle)")
		let audioDestination: DownloadRequest.Destination = {_,_ in return (self.audioDirectoryURL.appendingPathComponent("\(soundTitle).mp4"), .removePreviousFile)}
		let textureDestination: DownloadRequest.Destination = {_,_ in return (self.textureDirectoryURL.appendingPathComponent("\(soundTitle).png"), .removePreviousFile)}
		AF.download("https://thwump.bnwl.kr/sounds/\(soundTitle).mp4", to: audioDestination).response {
			response in
			if response.error == nil {
				print("downloaded audio for \(soundTitle)")
				AF.download("https://thwump.bnwl.kr/textures/\(soundTitle).png", to: textureDestination).response {
					response in
						// if texture download fails, delete the accompanying audio
						if response.error != nil {
							self.deleteSound(soundTitle: soundTitle)
						}
						print("downloaded texture for \(soundTitle)")
						completion()
				}
			}
		}
	}
	
	func clearAllLocalMedia () {
		print("clearing out media directories")
		if let audioPaths = try? fileManager.contentsOfDirectory(atPath: audioDirectoryURL.path) {
			for audioPath in audioPaths {
				try? fileManager.removeItem(at: audioDirectoryURL.appendingPathComponent(audioPath))
			}
		}
		if let texturePaths = try? fileManager.contentsOfDirectory(atPath: textureDirectoryURL.path) {
			for texturePath in texturePaths {
				try? fileManager.removeItem(at: textureDirectoryURL.appendingPathComponent(texturePath))
			}
		}
	}
	
	// wil return things in the ordering specified by the soundOrderJson file
	func getLocalSounds () -> [Sound] {
		var result: [Sound] = []
		do {
			let audioURLs = try fileManager.contentsOfDirectory(at: audioDirectoryURL, includingPropertiesForKeys: nil).filter { $0.pathExtension == "mp4" }
			let textureURLs = try fileManager.contentsOfDirectory(at: textureDirectoryURL, includingPropertiesForKeys: nil).filter { $0.pathExtension == "png" }

			for audioURL in audioURLs {
				let soundTitle = audioURL.deletingPathExtension().lastPathComponent
				for textureURL in textureURLs {
					if textureURL.deletingPathExtension().lastPathComponent == soundTitle {
						result.append(Sound(title: soundTitle, audioURL: audioURL, textureURL: textureURL))
					}
				}
			}
		} catch {
			print(error)
			return []
		}
		
		if let soundOrderJsonData = try? Data(contentsOf: self.soundOrderJsonURL) {
			if let soundOrderArray = try? JSONSerialization.jsonObject(with: soundOrderJsonData, options: .init()) as? [String] {
				return self.sortedSounds(sounds: result, orderedTitles: soundOrderArray)
			}
		}
		return result
	}
	
	func sortedSounds (sounds: [Sound], orderedTitles: [String]) -> [Sound] {
		var result: [Sound] = []
		for orderedTitle in orderedTitles {
			for sound in sounds {
				if sound.title == orderedTitle {
					result.append(sound)
				}
			}
		}
		return result
	}
	
	
}

struct Sound {
	var texture: UIImage? {
		get {
			if let textureData = try? Data(contentsOf: textureURL) {
				if let texture = UIImage(data: textureData) {
					return texture
				}
			}
			return nil
		}
	}
	var title: String
	var audioURL: URL
	var textureURL: URL
}

extension String {
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }

    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
}
