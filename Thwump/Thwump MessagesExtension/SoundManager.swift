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
		
		for textureURL in textureURLs {
			let soundNameWithOrder = textureURL.deletingPathExtension().lastPathComponent
			let soundName = String(soundNameWithOrder.dropFirst(2))
			for soundURL in soundURLs {
				if soundURL.deletingPathExtension().lastPathComponent == soundName {
					if let textureData = try? Data(contentsOf: textureURL) {
						if let texture = UIImage(data: textureData) {
							result.append(Sound(texture: texture, title: soundNameWithOrder, soundURL: soundURL))
						}
					}
				}
			}
		}
		return result.sorted(by: {a, b in a.title < b.title}).map({Sound(texture: $0.texture, title: String($0.title.dropFirst(2)), soundURL: $0.soundURL)})
	}
}

struct Sound {
	var texture: UIImage
	var title: String
	var soundURL: URL
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
