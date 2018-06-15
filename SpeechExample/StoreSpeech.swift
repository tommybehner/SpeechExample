//
//  StoreSpeech.swift
//  SpeechExample
//


import Speech

/// Type that is used to return to a call asynchronously
typealias callback = (_ text: String?, _ error: Error?) -> Void

/// Completion used in Speech Recognition
typealias completionPermission = (_ status: Bool, _ message: String) -> Void

// Mark - Class
class StoreSpeech: NSObject {
    // Mark - Life cycle
    
    /// Default Singleton
    /// - Single Object Instance
    static let singleton = StoreSpeech()
    
    /// Perform real speech recognition
    ///
    /// # Note
    /// By default, the location of the device will be detected and in response, it will recognize the appropriate language for that geographic location.
    ///
    ///
    /// Passing parameter
    ///
    ///     let s = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    ///
    /// Pattern
    ///
    ///     let s = SFSpeechRecognizer()
    fileprivate let speechRecognizer: SFSpeechRecognizer? = {
        return SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    }()
    
    /// To allocate the speech as the user speaks in real time and control the buffering
    fileprivate var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    ///Will be used to manage, cancel or interrupt the current recognition task
    fileprivate var recognitionTask: SFSpeechRecognitionTask?
    
    /// Processes audio streaming
    /// - Will give updates when the microphone receives audio
    fileprivate let audioEngine: AVAudioEngine = {
        return AVAudioEngine()
    }()
    
    /// Save the result obtained from the acknowledgment
    fileprivate var speechResult: SFSpeechRecognitionResult = {
        return SFSpeechRecognitionResult()
    }()
    
    // Hiding the class constructor method
    private override init() {
        super.init()
    }
    
}

// Mark - Public methods
extension StoreSpeech {
    
    /// Speech Recognition authorization method
    ///
    /// Returns an access boolean as a message stating the status
    func requestPermission(completion: @escaping completionPermission) {
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    completion(true, "Authorized Speech Recognition")
                    break
                case .notDetermined:
                    completion(false, "Speech Recognition was not determined")
                    break
                case .denied:
                    completion(false, "User denied access to Speech Recognition")
                    break
                case .restricted:
                    completion(false, "Speech Recognition Restricted to this device")
                    break
                }
            }
        }
    }

    /// Method that will start the process of speech recognition
    /// - Parameters:
    ///     - callback: Will be called every time an acknowledgment is processed. And in case of error will be called.
    func startRecording(callback: @escaping callback) throws {
        
        // Checks whether an audio input process already exists
        if !audioEngine.isRunning {
            
            // Check availability for the device and location
            // If it is not supported this object will be null
            guard let speechRecognizer = speechRecognizer else {
                callback(nil, NSError())
                return
            }
            
            // Recognizer is not available now
            if !speechRecognizer.isAvailable {
                callback(nil, NSError())
                return
            }
            
            // Creating requisition object
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
            // Audio engine and speech recognition
            let inputNode = audioEngine.inputNode
            guard let recognitionRequest = recognitionRequest else {
                callback(nil, NSError())
                return
            }
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer , _) in
                recognitionRequest.append(buffer)
            }
            
            // Configure the request so that the results are returned before the audio recording is finished
            recognitionRequest.shouldReportPartialResults = true
            
            // A recognition task is used for speech recognition sessions
            // A reference to the task is saved so it can be canceled
            // This is where recognition takes place. The audio is being sent to an Apple server and then returns an object with attributes as a result
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
                
                if let result = result {
                    self.speechResult = result
                    
                    // Use: result.bestTranscription.formattedString, to format the result as a string value
                    callback(result.bestTranscription.formattedString, nil)
                }
                
                // In case something goes wrong
                if error != nil {
                    // Stop recognition
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    
                    self.recognitionRequest = nil
                    self.recognitionTask?.cancel()
                    self.recognitionTask = nil
                    
                    callback(nil, error)
                }
                
            }
            
            // Prepare and start recording using the audio engine
            // Try is throwing the exception to who calls `startRecording`
            audioEngine.prepare()
            try audioEngine.start()
        }
    }
    
    /// Method to cancel recognition
    /// All processes are stopped and objects are set with `nil`
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
    }
    
}

