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
        cv.showsHorizontalScrollIndicator = false
        cv.register(CustomCell.self, forCellWithReuseIdentifier: "cell")
        cv.backgroundColor = .clear
        return cv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.sounds = SoundManager.getSounds()
        view.backgroundColor = .tertiarySystemBackground
    }
    
    override func viewWillAppear(_ animated: Bool) {
		view.addSubview(collectionView)
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        collectionView.contentInset = UIEdgeInsets(top: 15.0, left: 15.0, bottom: 15.0, right: 15.0)
        
        let instructionLabel = UILabel()
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = -1
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)
        instructionLabel.text = "single tap to preview, double tap to send, touch and hold to listen to a message"
        instructionLabel.font = .systemFont(ofSize: 10.0)
        instructionLabel.textColor = .secondaryLabel
		instructionLabel.topAnchor.constraint(equalTo: collectionView.bottomAnchor).isActive = true
		instructionLabel.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -20).isActive = true
		instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
		
		collectionView.heightAnchor.constraint(equalToConstant: (view.frame.size.height - instructionLabel.frame.size.height) * 0.7).isActive = true
		collectionView.delegate = self
		collectionView.dataSource = self
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
        cell.messagesViewController = self
        return cell
    }
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		return 25
	}
}

class CustomCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    let SEND_THRESHOLD = 0.5
    
    var sound: Sound! {
		didSet {
			self.imageView.image = sound?.texture
		}
	}
	
	var messagesViewController: MessagesViewController!
	var touchTimer: Timer?
    
    fileprivate let imageView: UIImageView = {
       let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		UIView.animate(withDuration: 0.2) {
			self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
		}
		touchTimer = Timer.scheduledTimer(withTimeInterval: SEND_THRESHOLD, repeats: false, block: { _ in
			self.messagesViewController.sendMessage(sound: self.sound)
			var notificationFeedbackGenerator: UINotificationFeedbackGenerator? = UINotificationFeedbackGenerator()
			notificationFeedbackGenerator?.prepare()
			notificationFeedbackGenerator?.notificationOccurred(.success)
			notificationFeedbackGenerator = nil
		})
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		UIView.animate(withDuration: 0.2) {
			self.transform = .identity
		}
		touchTimer?.invalidate()
		touchTimer = nil
		messagesViewController.playSound(url: sound.soundURL)
	}
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        contentView.addSubview(imageView)
        
        contentView.isUserInteractionEnabled = true
        
        
//        let soundTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleSoundTap))
//        soundTapRecognizer.numberOfTapsRequired = 1
//
//		let sendSwipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSendSwipe))
//		sendSwipeRecognizer.direction = .up
//
//		contentView.addGestureRecognizer(soundTapRecognizer)
//		contentView.addGestureRecognizer(sendSwipeRecognizer)
		
		contentView.backgroundColor = UIColor(named: "cellColor")
		contentView.clipsToBounds = true
		contentView.layer.cornerRadius = 12
		
		contentView.layer.shadowColor = UIColor.label.cgColor
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
