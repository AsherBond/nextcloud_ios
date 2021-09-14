//
//  NCViewerVideoToolBar.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 01/07/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation

class NCViewerVideoToolBar: UIView {
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var playbackSlider: UISlider!
    @IBOutlet weak var labelOverallDuration: UILabel!
    @IBOutlet weak var labelCurrentTime: UILabel!
    
    var player: AVPlayer?
    fileprivate let seekDuration: Float64 = 15
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)

        if newWindow != nil {
            
            let blurEffect = UIBlurEffect(style: .dark)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            
            self.layer.cornerRadius = 15
            self.layer.masksToBounds = true
                       
            blurEffectView.frame = self.bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.insertSubview(blurEffectView, at:0)
        }
    }
    
    func setPlayer(player: AVPlayer?) {
        self.player = player
        
        let duration: CMTime = (player?.currentItem?.asset.duration)!
        let durationSeconds: Float64 = CMTimeGetSeconds(duration)
        
        playbackSlider.minimumValue = 0
        playbackSlider.maximumValue = Float(durationSeconds)
        playbackSlider.isContinuous = true
        playbackSlider.tintColor = .lightGray
        playbackSlider.action(for: .valueChanged) { _ in
            let seconds : Int64 = Int64(self.playbackSlider.value)
            let targetTime:CMTime = CMTimeMake(value: seconds, timescale: 1)
            self.player?.seek(to: targetTime)
            if self.player?.rate == 0 {
                self.player?.play()
            }
        }
        
        labelCurrentTime.text = stringFromTimeInterval(interval: 0)
        labelCurrentTime.textColor = .lightGray
        labelOverallDuration.text = "-" + stringFromTimeInterval(interval: durationSeconds)
        labelOverallDuration.textColor = .lightGray
        
        player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: .main, using: { (CMTime) in
            
            if self.player?.currentItem?.status == .readyToPlay {
                let currentSeconds: Float64 = CMTimeGetSeconds(self.player!.currentTime())
                self.playbackSlider.value = Float(currentSeconds)
                self.labelCurrentTime.text = self.stringFromTimeInterval(interval: currentSeconds)
                self.labelOverallDuration.text = "-" + self.stringFromTimeInterval(interval: durationSeconds - currentSeconds)
            }
        })
    }
    
    func setToolBar() {
        
        let mute = CCUtility.getAudioMute()
        
        if  player?.rate == 1 {
            playButton.setImage(NCUtility.shared.loadImage(named: "pause.fill", color: .white), for: .normal)
        } else {
            playButton.setImage(NCUtility.shared.loadImage(named: "play.fill", color: .white), for: .normal)
        }
       
        if mute {
            muteButton.setImage(NCUtility.shared.loadImage(named: "audioOff", color: .white), for: .normal)
        } else {
            muteButton.setImage(NCUtility.shared.loadImage(named: "audioOn", color: .white), for: .normal)
        }
        
        backButton.setImage(NCUtility.shared.loadImage(named: "gobackward.15", color: .white), for: .normal)
        forwardButton.setImage(NCUtility.shared.loadImage(named: "goforward.15", color: .white), for: .normal)
    }

    //MARK: - Action
    
    @IBAction func playerPause(_ sender: Any) {
        
        if player?.timeControlStatus == .playing {
            player?.pause()
        } else if player?.timeControlStatus == .paused {
            player?.play()
        }
    }
        
    @IBAction func setMute(_ sender: Any) {
        
        let mute = CCUtility.getAudioMute()
        
        CCUtility.setAudioMute(!mute)
        player?.isMuted = !mute
        setToolBar()
    }
    
    @IBAction func forwardButtonSec(_ sender: Any) {
        guard let player = self.player else { return }
        
        if let duration = player.currentItem?.duration {
            
            let playerCurrentTime = CMTimeGetSeconds(player.currentTime())
            let newTime = playerCurrentTime + seekDuration
            if newTime < CMTimeGetSeconds(duration) {
                let selectedTime: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
                player.seek(to: selectedTime)
            }
            player.pause()
            player.play()
        }
    }
    
    @IBAction func backButtonSec(_ sender: Any) {
        guard let player = self.player else { return }

        let playerCurrenTime = CMTimeGetSeconds(player.currentTime())
        var newTime = playerCurrenTime - seekDuration
        if newTime < 0 { newTime = 0 }
        player.pause()
        let selectedTime: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
        player.seek(to: selectedTime)
        player.play()
    }
    
    //MARK: - Algorithms
    
    func stringFromTimeInterval(interval: TimeInterval) -> String {
    
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
