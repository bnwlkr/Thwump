//
//  Sound.swift
//  Thwump MessagesExtension
//
//  Created by Ben Walker on 2020-04-04.
//  Copyright © 2020 bnwlkr. All rights reserved.
//

import Foundation
import UIKit

class SoundManager {

	static func getSounds () -> [Sound] {
		var result: [Sound] = []
	
		let soundURLs = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: "media/sounds") ?? []
		let textureURLs = Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: "media/textures") ?? []
		
		for soundURL in soundURLs {
			let soundName = soundURL.deletingPathExtension().lastPathComponent
			for textureURL in textureURLs {
				if textureURL.deletingPathExtension().lastPathComponent == soundName {
					if let textureData = try? Data(contentsOf: textureURL) {
						if let texture = UIImage(named: soundName) {
							result.append(Sound(texture: texture, title: soundName, soundURL: soundURL))
						}
					}
				}
			}
		}
		return result
	}
}

struct Sound {

	var texture: UIImage
	var title: String
	var soundURL: URL

}
