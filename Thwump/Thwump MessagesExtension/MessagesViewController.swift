//
//  MessagesViewController.swift
//  Thwump MessagesExtension
//
//  Created by Ben Walker on 2020-04-04.
//  Copyright © 2020 bnwlkr. All rights reserved.
//

import UIKit
import Messages
import AVFoundation

protocol SoundPlayerDelegate {
	func playSound(url: URL)
}

protocol MessageSenderDelegate {
	func sendMessage(sound: Sound)
}

let CELL_ASPECT: CGFloat = 0.83

class MessagesViewController: MSMessagesAppViewController, SoundPlayerDelegate, MessageSenderDelegate {
	
    var sounds: [Sound] = []
    var player: AVAudioPlayer!
    
    fileprivate let collectionView:UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .white
        cv.showsHorizontalScrollIndicator = false
        cv.register(CustomCell.self, forCellWithReuseIdentifier: "cell")
        return cv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.sounds = SoundManager.getSounds()
    }
    
    override func viewWillAppear(_ animated: Bool) {
		view.addSubview(collectionView)
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        collectionView.heightAnchor.constraint(equalToConstant: view.frame.size.height * 0.68).isActive = true
        collectionView.contentInset = UIEdgeInsets(top: 15.0, left: 15.0, bottom: 15.0, right: 15.0)
        collectionView.delegate = self
		collectionView.dataSource = self
        
        let instructionLabel = UILabel()
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = -1
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)
        instructionLabel.text = "single tap to preview, double tap to send, touch and hold to listen to a message"
        instructionLabel.font = .systemFont(ofSize: 10.0)
        instructionLabel.textColor = .gray
		instructionLabel.topAnchor.constraint(equalTo: collectionView.bottomAnchor).isActive = true
		instructionLabel.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -20).isActive = true
		instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
	}
    
    
    func playSound(url: URL) {
		do {
			try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
			try AVAudioSession.sharedInstance().setActive(true)
			player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
			player.play()
		} catch let error {
			print(error.localizedDescription)
		}
	}
	
	func sendMessage(sound: Sound) {
		if activeConversation != nil {
			// The alternate filename doesn't actually work right now. Apparently it's been broken for years. Come on Apple.
			activeConversation?.sendAttachment(sound.soundURL, withAlternateFilename: "Thwump", completionHandler: nil)
		}
	}
}

extension MessagesViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.frame.height * 0.8
        let width = height * CELL_ASPECT
        return CGSize(width: width, height: height)
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.sounds.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CustomCell
        cell.sound = self.sounds[indexPath.item]
        cell.soundPlayerDelegate = self
        cell.messageSenderDelegate = self
        return cell
    }
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		return 25
	}
}

class CustomCell: UICollectionViewCell {
    
    var sound: Sound? {
		didSet {
			self.imageView.image = sound?.texture
		}
	}
	
	var soundPlayerDelegate: SoundPlayerDelegate?
	var messageSenderDelegate: MessageSenderDelegate?
    
    fileprivate let imageView: UIImageView = {
       let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
	@objc func handleSingleTap () {
		print("single tap")
		soundPlayerDelegate?.playSound(url: sound!.soundURL)
	}
	
	@objc func handleDoubleTap () {
		print("double tap")
		messageSenderDelegate?.sendMessage(sound: sound!)
	}
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        contentView.addSubview(imageView)
        
        contentView.isUserInteractionEnabled = true
        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTapRecognizer.numberOfTapsRequired = 1
		
		let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
		doubleTapRecognizer.numberOfTapsRequired = 2
		
		singleTapRecognizer.require(toFail: doubleTapRecognizer)
		
		contentView.addGestureRecognizer(singleTapRecognizer)
		contentView.addGestureRecognizer(doubleTapRecognizer)
		
		contentView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
		contentView.clipsToBounds = true
		contentView.layer.cornerRadius = 12
		
		contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowRadius = 4.0
        contentView.layer.shadowOpacity = 0.2
        contentView.layer.shadowOffset = .zero
        contentView.layer.masksToBounds = false
		
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        imageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 10).isActive = true
        imageView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10).isActive = true
        imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
