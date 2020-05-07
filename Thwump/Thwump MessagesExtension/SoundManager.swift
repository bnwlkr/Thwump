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

class SoundManager {

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
	
	var localManifestURL: URL {
		get {
			return mediaDirectoryURL.appendingPathComponent("manifest.json")
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
	
	// this is the only function in the public API
	public func sync (completion: @escaping ([Sound]) -> ()) {
		AF.request("https://thwump.bnwl.kr/manifest.json").responseJSON { response in
			switch (response.result) {
				case .success(let result):
					let manifestJSON = result as! [String:Any]
					let refreshKey = manifestJSON["refreshKey"] as! Int
					let manifestSoundTitles = manifestJSON["soundNames"] as! [String]
					if UserDefaults.standard.integer(forKey: "refreshKey") != refreshKey {
						for sound in self.getLocalSounds() {
							self.deleteSound(soundTitle: sound.title)
						}
						UserDefaults.standard.set(refreshKey, forKey: "refreshKey")
					}
					
					// delete any local sounds not in the manifest
					for sound in self.getLocalSounds() {
						if !manifestSoundTitles.contains(sound.title) {
							self.deleteSound(soundTitle: sound.title)
						}
					}
					
					// add any sounds in the manifest not present locally
					let localSoundTitles = self.getLocalSounds().map { $0.title }
					let downloadGroup = DispatchGroup()
					for soundTitle in manifestSoundTitles {
						if !localSoundTitles.contains(soundTitle) {
							downloadGroup.enter()
							self.downloadSound(soundTitle: soundTitle) {
								downloadGroup.leave()
							}
						}
					}
					downloadGroup.notify(queue: .main) {
						let localSounds = self.getLocalSounds()
						var localSoundsSorted: [Sound] = []
						for manifestSoundTitle in manifestSoundTitles {
							for localSound in localSounds {
								if localSound.title == manifestSoundTitle {
									localSoundsSorted.append(localSound)
								}
							}
						}
						completion(localSoundsSorted)
					}
				case .failure(let error):
					print(error)
					completion(self.getLocalSounds())
			}
		}
	}
	
	
	
	func deleteSound(soundTitle: String) {
		print("deleting \(soundTitle)")
		try? fileManager.removeItem(at: textureDirectoryURL.appendingPathComponent("\(soundTitle).png"))
		try? fileManager.removeItem(at: audioDirectoryURL.appendingPathComponent("\(soundTitle).mp3"))
	}
	
	func downloadSound(soundTitle: String, completion: @escaping ()->()) {
		print("downloading \(soundTitle)")
		let audioDestination: DownloadRequest.Destination = {_,_ in return (self.audioDirectoryURL.appendingPathComponent("\(soundTitle).mp3"), .removePreviousFile)}
		let textureDestination: DownloadRequest.Destination = {_,_ in return (self.textureDirectoryURL.appendingPathComponent("\(soundTitle).png"), .removePreviousFile)}
		AF.download("https://thwump.bnwl.kr/sounds/\(soundTitle).mp3", to: audioDestination).response {
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
	
	func getLocalSounds () -> [Sound] {
		var result: [Sound] = []
		do {
			let audioURLs = try fileManager.contentsOfDirectory(at: audioDirectoryURL, includingPropertiesForKeys: nil).filter { $0.pathExtension == "mp3" }
			let textureURLs = try fileManager.contentsOfDirectory(at: textureDirectoryURL, includingPropertiesForKeys: nil).filter { $0.pathExtension == "png" }

			for audioURL in audioURLs {
				let soundTitle = audioURL.deletingPathExtension().lastPathComponent
				for textureURL in textureURLs {
					if textureURL.deletingPathExtension().lastPathComponent == soundTitle {
						result.append(Sound(title: soundTitle, audioURL: audioURL, textureURL: textureURL))
					}
				}
			}
			return result
		} catch {
			print(error)
			return []
		}
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
