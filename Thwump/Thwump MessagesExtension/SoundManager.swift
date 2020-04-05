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
		let soundUrls = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: "media/sounds")
		let textureUrls = Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: "media/textures")
		print(soundUrls, textureUrls)
		return []
	}

}



struct Sound {

	var texture: UIImage!
	var title: String!
	var filePath: URL!


}
