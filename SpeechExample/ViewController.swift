//
//  ViewController.swift
//  SpeechExample
//


import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var buttonStart: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        StoreSpeech.singleton.requestPermission { (status, message) in
            self.buttonStart.isEnabled = status
            self.textView.text = message
        }
    }

    @IBAction func actionStart(_ sender: UIButton) {
        if let text = sender.titleLabel?.text, text == "Stop" {
            sender.setTitle("Start", for: .normal)
                StoreSpeech.singleton.stopRecording()

        } else {
            sender.setTitle("Stop", for: .normal)
            textView.text = nil
            
            do {
                try StoreSpeech.singleton.startRecording { (text, _) in
                    if let text = text {
                        self.textView.text = text
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
}
