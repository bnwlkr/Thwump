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

let CELL_ASPECT: CGFloat = 0.83

class MessagesViewController: MSMessagesAppViewController, UICollectionViewDelegate {
	
	let SEND_THRESHOLD = 0.5
	
    var sounds: [Sound] = []
    var player: AVAudioPlayer!
    var touchTimer: Timer?
	var didSend = false
	var currentlySelected: CustomCell?
    
    fileprivate let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.showsHorizontalScrollIndicator = false
        cv.register(CustomCell.self, forCellWithReuseIdentifier: "cell")
        cv.backgroundColor = .clear
        return cv
    }()

	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		if currentlySelected != nil {
			touchesEnded(cell: currentlySelected!)
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sounds = SoundManager.getSounds()
        view.backgroundColor = .tertiarySystemBackground
        collectionView.delegate = self
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
        instructionLabel.text = "tap to preview, long press to send, long press to listen to a received message"
        instructionLabel.font = .systemFont(ofSize: 10.0)
        instructionLabel.textColor = .secondaryLabel
		instructionLabel.topAnchor.constraint(equalTo: collectionView.bottomAnchor).isActive = true
		instructionLabel.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -60).isActive = true
		instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
		
		collectionView.heightAnchor.constraint(equalToConstant: (view.frame.size.height - instructionLabel.frame.size.height) * 0.7).isActive = true
		collectionView.delegate = self
		collectionView.dataSource = self
	}
	
	func touchesBegan(cell: CustomCell) {
		currentlySelected = cell
		UIView.animate(withDuration: 0.1) {
			cell.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
		}
		touchTimer = Timer.scheduledTimer(withTimeInterval: SEND_THRESHOLD, repeats: false, block: { _ in
			self.sendMessage(sound: cell.sound)
			self.didSend = true
			let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
			notificationFeedbackGenerator.prepare()
			notificationFeedbackGenerator.notificationOccurred(.success)
		})
	}
	
	func touchesEnded(cell: CustomCell) {
		currentlySelected = nil
		UIView.animate(withDuration: 0.2) {
			cell.transform = .identity
		}
		touchTimer?.invalidate()
		touchTimer = nil
		if !didSend {
			self.playSound(url: cell.sound.soundURL)
		}
		didSend = false
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


class CustomCell: UICollectionViewCell {
    
    
    var sound: Sound! {
		didSet {
			self.imageView.image = sound?.texture
		}
	}
	
	var messagesViewController: MessagesViewController!
	
    
    fileprivate let imageView: UIImageView = {
       let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		messagesViewController.touchesBegan(cell: self)
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		messagesViewController.touchesEnded(cell: self)
	}
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        contentView.addSubview(imageView)
        
        contentView.isUserInteractionEnabled = true
		
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
