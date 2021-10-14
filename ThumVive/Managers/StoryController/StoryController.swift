//
//  StoryController.swift
//  ThumVive
//
//  Created by Abraham De Leon on 10/14/21.
//


import UIKit
import MBProgressHUD
import CloudKit
import AVFoundation
import SwiftAudio
import AVKit
import MobileCoreServices
import StoreKit

enum StoryControllerMode {
    case new
    case edit
    case view
}

protocol StoryControllerDelegate: class {
    func storySaved()
}

class StoryController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var saveButton: MainButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var editButton: RoundedShadownButton!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var microphoneButton: VoiceButton!
    @IBOutlet weak var recordingView: UIView!
    @IBOutlet weak var recordingTimeLabel: UILabel!
    
    var story = Story(date: Date())
    var photoRecordsForDelete = [CKRecord.Reference]()
    var audioRecordForDelete: CKRecord.Reference?
    var videoRecordForDelete: CKRecord.Reference?
    
    var mode = StoryControllerMode.new
    
    var imagePicker = UIImagePickerController()
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder?
    
    var timer: Timer?
    
    weak var delegate: StoryControllerDelegate?
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? MainNoteCell {
            cell.stopPlayer()
        }
        
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? MainEditStoryCell {
            cell.stopPlayer()
        }
    }
    
    //MARK: - Privates
    
    private func setupView() {
        titleLabel.font = UIFont.getFont(font: .sfProTextSemibold, size: 17)
        titleLabel.text = "newNote".localized()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "MainNoteCell", bundle: nil), forCellReuseIdentifier: "MainNoteCell")
        tableView.register(UINib(nibName: "MainEditStoryCell", bundle: nil), forCellReuseIdentifier: "MainEditStoryCell")
//        tableView.register(UINib(nibName: "AudioCell", bundle: nil), forCellReuseIdentifier: "AudioCell")
        
        saveButton.titleLabel?.font = UIFont.getFont(font: .robotoRegular, size: 16)
        saveButton.setTitle("saveChanges".localized(), for: .normal)
        
        switch mode {
        case .new:
            titleLabel.text = "newStory".localized()
            saveButton.isHidden = false
            tableViewBottomConstraint.constant = 86
//            deleteButton.isHidden = true
            microphoneButton.isHidden = story.audio != nil
            editButton.isHidden = true
        case .edit:
            titleLabel.text = "editStory".localized()
            saveButton.isHidden = false
            tableViewBottomConstraint.constant = 86
//            deleteButton.isHidden = false
            microphoneButton.isHidden = story.audio != nil
            editButton.isHidden = true
        case .view:
            titleLabel.text = "viewStory".localized()
            saveButton.isHidden = true
            tableViewBottomConstraint.constant = 0
//            deleteButton.isHidden = true
            microphoneButton.isHidden = true
            editButton.isHidden = false
        }
        
        view.layoutIfNeeded()
    }
    
    private func presentInputText(mode: StringType) {
        let textInputController = TextInputController.storyboard()
        textInputController.delegate = self
        textInputController.mode = mode
        switch mode {
        case .heading:
            textInputController.text = story.heading ?? ""
            textInputController.color = story.headingColor
            textInputController.fontNumber = story.headingFontNumber
        case .place:
            textInputController.text = story.place ?? ""
            textInputController.color = story.placeColor
            textInputController.fontNumber = story.placeFontNumber
        case .thoughts:
            textInputController.text = story.text ?? ""
            textInputController.color = story.textColor
            textInputController.fontNumber = story.textFontNumber
        }
        present(textInputController, animated: true, completion: nil)
    }
    
    private func presentInputDate() {
        let dateUnputController = DateInputController.storyboard()
        dateUnputController.selectedDate = story.date
        dateUnputController.delegate = self
        present(dateUnputController, animated: true, completion: nil)
    }
    
    private func showPhotoAlert() {
        let actionSheetController: UIAlertController = UIAlertController()
//        actionSheetController.title = "Take a starting Photo?".localized()
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "cancel".localized(), style: .cancel) { void in
            actionSheetController.dismiss(animated: true, completion: nil)
        }
        actionSheetController.addAction(cancelActionButton)
        
        let cameraActionButton: UIAlertAction = UIAlertAction(title: "camera".localized(), style: .default) { void in
            self.openPhotoCamera()
        }
        actionSheetController.addAction(cameraActionButton)
        
        let galleryActionButton: UIAlertAction = UIAlertAction(title: "gallery".localized(), style: .default) { void in
            self.showAlbum()
        }
        actionSheetController.addAction(galleryActionButton)
        
        present(actionSheetController, animated: true, completion: nil)
    }
    
    private func openPhotoCamera() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            imagePicker = UIImagePickerController()
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.cameraDevice = .rear
            //                        imagePicker.allowsEditing = true
            imagePicker.delegate = self
            
            self.present(imagePicker, animated: true, completion: nil)
        }
        else {
            let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func openVideoCamera() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.cameraDevice = .rear
            imagePicker.mediaTypes = [kUTTypeMovie as String]
            //                        imagePicker.allowsEditing = true
            imagePicker.videoMaximumDuration = 15
            imagePicker.delegate = self
            
            self.present(imagePicker, animated: true, completion: nil)
        }
        else {
            let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func showAlbum() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            imagePicker.sourceType = .photoLibrary
            imagePicker.delegate = self
        }
        //        imagePicker.modalTransitionStyle = .partialCurl
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    private func updateStory() {
        MBProgressHUD.showAdded(to: view, animated: true)
        API.StoryModule.update(story: story, photosForDelete: photoRecordsForDelete, audioForDelete: audioRecordForDelete, videoForDelete: videoRecordForDelete, success: { (_) in
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                self.dismiss(animated: true) {
                    self.delegate?.storySaved()
                }
            }
            
        }) { (error) in
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                self.showWarningAlert(text: error.localizedDescription, type: .error)
            }
        }
    }
    
    private func saveNewStory() {
        MBProgressHUD.showAdded(to: view, animated: true)
        API.StoryModule.saveNew(story: story, success: { (_) in
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                self.dismiss(animated: true) {
                    self.delegate?.storySaved()
                    if !Global.isRatePresented && self.story.photos.count > 0 {
                        self.rateApp()
                    }
                }
            }
        }) { (error) in
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                self.showWarningAlert(text: error.localizedDescription, type: .error)
            }
            
        }
    }
    
    private func rateApp() {
        let appId = "id1510420527"
        
        if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()

        } else if let url = URL(string: "itms-apps://itunes.apple.com/app/" + appId) {
            if #available(iOS 10, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                Global.isRatePresented = true

            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    private func showDeleteAlert() {
        let actionSheetController: UIAlertController = UIAlertController()
        actionSheetController.title = "deleteAlertTitle".localized()
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "cancel".localized(), style: .cancel) { void in
            actionSheetController.dismiss(animated: true, completion: nil)
        }
        actionSheetController.addAction(cancelActionButton)
        
        let deleteActionButton: UIAlertAction = UIAlertAction(title: "delete".localized(), style: .default) { void in
            self.deleteStory()
        }
        actionSheetController.addAction(deleteActionButton)
        
        present(actionSheetController, animated: true, completion: nil)
    }
    
    private func deleteStory() {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        API.StoryModule.delete(story: self.story, success: { (_) in
            
            self.dismiss(animated: true) {
                self.delegate?.storySaved()
            }
        }) { (error) in
            self.showWarningAlert(text: error.localizedDescription, type: .error)
        }
    }
    
    private func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()

//            recordButton.setTitle("Tap to Stop", for: .normal)
        } catch {
            finishRecording(success: false)
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    private func finishRecording(success: Bool) {
        audioRecorder?.stop()
        audioRecorder = nil

        if success {
            story.audio = AudioModel(url: getDocumentsDirectory().appendingPathComponent("recording.m4a"))
            tableView.reloadData()
            saveButton.isEnabled = true
            microphoneButton.isHidden = true
//            recordButton.setTitle("Tap to Re-record", for: .normal)
        } else {
//            recordButton.setTitle("Tap to Record", for: .normal)
            // recording failed :(
        }
    }
    
    private func showVideoAlert() {
        let actionSheetController: UIAlertController = UIAlertController()
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "cancel".localized(), style: .cancel) { void in
            actionSheetController.dismiss(animated: true, completion: nil)
        }
        actionSheetController.addAction(cancelActionButton)
        
        let cameraActionButton: UIAlertAction = UIAlertAction(title: "camera".localized(), style: .default) { void in
            self.openVideoCamera()
        }
        actionSheetController.addAction(cameraActionButton)
        
        let galleryActionButton: UIAlertAction = UIAlertAction(title: "gallery".localized(), style: .default) { void in
            VideoHelper.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
//            self.showAlbum()
        }
        actionSheetController.addAction(galleryActionButton)
        
        present(actionSheetController, animated: true, completion: nil)
    }
    
    @objc private func updateRecordingTimeLabel() {
        self.recordingTimeLabel.text = audioRecorder?.currentTime.secondsToString()
    }
    
    internal func showSubscriptions() {
        let subscriptionsController = SubscriptionsController.storyboard()
        present(subscriptionsController, animated: true)
    }
    
    //MARK: - Actions
    
    @IBAction func closeButtonAction(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func saveButtonAction(_ sender: Any) {
        if let heading = story.heading, heading.count >= 3 {
            switch mode {
            case .edit, .view:
                updateStory()
            case .new :
                saveNewStory()
//                if let url = story.video?.url {
//                    let player = AVPlayer(url: url)
//                    let vcPlayer = AVPlayerViewController()
//                    vcPlayer.player = player
//                    self.present(vcPlayer, animated: true, completion: nil)
//                }
                
            }
            
        } else {
            showWarningAlert(text: "headingWarning".localized(), type: .warning)
        }
    }
    
    @IBAction func deleteButtonAction(_ sender: Any) {
        showDeleteAlert()
    }
    
    @IBAction func microphoneButtonTouchDown(_ sender: RoundedShadownButton) {
        guard Global.isPremium else {
            showSubscriptions()
            return
        }
        timer = Timer.scheduledTimer(timeInterval: 0.0001, target: self, selector: #selector(self.updateRecordingTimeLabel), userInfo: nil, repeats: true)
        recordingView.isHidden = false
        
        recordingSession = AVAudioSession.sharedInstance()
        switch recordingSession.recordPermission {
        case AVAudioSession.RecordPermission.granted:
            print("Permission granted")
            do {
                        try recordingSession.setCategory(.playAndRecord, mode: .default)
                        try recordingSession.setActive(true)
                        recordingSession.requestRecordPermission() { [unowned self] allowed in
                            DispatchQueue.main.async {
                                if allowed {
            //                        self.loadRecordingUI()
                                    self.startRecording()
                                } else {
                                    self.finishRecording(success: false)
                                    // failed to record!
                                }
                            }
                        }
                    } catch {
                        // failed to record!
                    }
        case AVAudioSession.RecordPermission.denied:
            print("Pemission denied")
            showWarningAlert(text: "You have not given permission to use the microphone".localized(), type: .warning)
        case AVAudioSession.RecordPermission.undetermined:
            print("Request permission here")
            recordingSession.requestRecordPermission({ (granted) in
                if granted {
                    do {
                        try self.recordingSession.setCategory(.playAndRecord, mode: .default)
                        try self.recordingSession.setActive(true)
                        self.recordingSession.requestRecordPermission() { [unowned self] allowed in
                            DispatchQueue.main.async {
                                if allowed {
                                    //                        self.loadRecordingUI()
                                    self.startRecording()
                                } else {
                                    self.finishRecording(success: false)
                                    // failed to record!
                                }
                            }
                        }
                    } catch {
                        // failed to record!
                    }
                }
            })
        @unknown default:
            fatalError()
        }

        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.startRecording()
                    } else {
                        self.finishRecording(success: false)
                    }
                }
            }
        } catch {
            self.finishRecording(success: false)
        }
    }
    
    @IBAction func microphoneButtonTouchUpInside(_ sender: RoundedShadownButton) {
        guard Global.isPremium else { return }
        recordingView.isHidden = true
        timer?.invalidate()
        finishRecording(success: recordingSession.recordPermission == .granted)
    }
    
    @IBAction func microphoneButtonTouchDragOutside(_ sender: RoundedShadownButton) {
        guard Global.isPremium else { return }
        recordingView.isHidden = true
        timer?.invalidate()
        finishRecording(success: false)
    }
    @IBAction func microphoneButtonTouchDragExit(_ sender: Any) {
        guard Global.isPremium else { return }
        recordingView.isHidden = true
        timer?.invalidate()
        finishRecording(success: false)
    }
    
    @IBAction func microphoneButtonTouchCancel(_ sender: Any) {
        guard Global.isPremium else { return }
        recordingView.isHidden = true
        timer?.invalidate()
        finishRecording(success: false)
    }
    
    @IBAction func editButtonAction(_ sender: Any) {
        self.mode = .edit
        self.setupView()
        self.tableView.reloadData()
    }
}

//MARK: - UITableViewDataSource
extension StoryController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch mode {
        case .new, .edit:
            let cell = tableView.dequeueReusableCell(withIdentifier: "MainEditStoryCell") as! MainEditStoryCell
            cell.delegate = self
            cell.setupUI(story: story)
            return cell
        case .view:
            let cell = tableView.dequeueReusableCell(withIdentifier: "MainNoteCell") as! MainNoteCell
            cell.delegate = self
            cell.setupUI(story: story)
            return cell
        }
    }
}

//MARK: - UITableViewDelegate
extension StoryController: UITableViewDelegate {
}

//MARK: - MainEditStoryCellDelegate
extension StoryController: MainEditStoryCellDelegate {
    func deleteVideo() {
        if let videoReference = story.video?.cloudReference {
            videoRecordForDelete = videoReference
        }
        
        story.video = nil
        tableView.reloadData()
        saveButton.isEnabled = true
    }
    
    func didTapDeleteAudioButton() {
        if let audioReference = story.audio?.cloudReference {
            audioRecordForDelete = audioReference
        }
        story.audio = nil
        tableView.reloadData()
        saveButton.isEnabled = true
        microphoneButton.isHidden = false
    }
    
    func deletePhoto(number: Int) {
        if let photoReference = story.photos[number].cloudReference {
            photoRecordsForDelete.append(photoReference)
        }
        
        story.photos.remove(at: number)
        tableView.reloadData()
        saveButton.isEnabled = true
    }
    
    func didTapPhoto(number: Int) {
        if number == 0 || Global.isPremium {
            let fullPhotoController = FullPhotoController.storyboard()
            fullPhotoController.photo = story.photos[number]
            fullPhotoController.numberOfPhoto = number
            fullPhotoController.mode = .edit
            fullPhotoController.delegate = self
            present(fullPhotoController, animated: true)
        } else {
            showSubscriptions()
        }
        
    }
    
    func didTapAddPhoto() {
        
        if story.photos.count == 0 || Global.isPremium {
            showPhotoAlert()
        } else {
            showSubscriptions()
        }
    }
    
    private func showVideoPlayer() {
       
        if let videoRecordID = story.video?.cloudReference?.recordID {
            MBProgressHUD.showAdded(to: view, animated: true)
            API.StoryModule.getVideoUrl(videoID: videoRecordID, success: { (url) in
                
                DispatchQueue.main.async {
                    
                    MBProgressHUD.hide(for: self.view, animated: true)
                    
                    //                    var videoURL = video.fileURL
                    
                    
                    let videoData = try? Data(contentsOf: url)
                    
                    let documentsPath = self.getDocumentsDirectory()
                    let destinationPath = documentsPath.appendingPathComponent("video.mov")
                    
                    FileManager.default.createFile(atPath: destinationPath.path, contents: videoData, attributes:nil)
                    
                    let videoURL = destinationPath
                    
                    let player = AVPlayer(url: videoURL)
                    do {
                        try AVAudioSession.sharedInstance().setCategory(.playback)
                       } catch _ {
                    }
                    let vcPlayer = AVPlayerViewController()
                    vcPlayer.player = player
                    self.present(vcPlayer, animated: true, completion: nil)
                }
                
            }) { (error) in
                MBProgressHUD.hide(for: self.view, animated: true)
                self.showWarningAlert(text: "Error!!!", type: AlertType.error)
            }
        } else if let videoURL = story.video?.url {
            let player = AVPlayer(url: videoURL)

            do {
                try AVAudioSession.sharedInstance().setCategory(.playback)
               } catch _ {
            }
            let vcPlayer = AVPlayerViewController()
            vcPlayer.player = player
            self.present(vcPlayer, animated: true, completion: nil)
        }
        
        
    }
    
    func didTapAddVideo() {
        if Global.isPremium {
            if story.video == nil {
                showVideoAlert()
            } else {
                showVideoPlayer()
            }
        } else {
            showSubscriptions()
        }
    }
    
    func didTapCalendar() {
        presentInputDate()
    }
    
    func didTapLocation() {
        presentInputText(mode: .place)
    }
    
    func didTapThoughts() {
        presentInputText(mode: .thoughts)
    }
    
    func didTapHeading() {
        presentInputText(mode: .heading)
    }
}

//MARK: - MainNoteCellDelegate
extension StoryController: MainNoteCellDelegate {
    func didTapVideo() {
        if Global.isPremium {
            showVideoPlayer()
        } else {
            showSubscriptions()
        }
        
    }
    
    func didTapPhoto(photo: PhotoModel, index: Int) {
        if index > 0 && !Global.isPremium {
            showSubscriptions()
        } else {
            let fullPhotoController = FullPhotoController.storyboard()
            fullPhotoController.photo = photo
            present(fullPhotoController, animated: true)
        }
        
    }
}

//MARK: - TextInputControllerDelegate
extension StoryController: TextInputControllerDelegate {
    
    func didTapDone(text: String, mode: StringType, color: UIColor, fontNumber: Int) {
        let oldStory = story
        switch mode {
        case .heading:
            story.heading = text
            story.headingColor = color
            story.headingFontNumber = fontNumber
        case .place:
            story.place = text
            story.placeColor = color
            story.placeFontNumber = fontNumber
        case .thoughts:
            story.text = text
            story.textColor = color
            story.textFontNumber = fontNumber
        }
        
        if oldStory != story {
            saveButton.isEnabled = true
        }
        
        tableView.reloadData()
    }
}

//MARK: - DateInputControllerDelegate
extension StoryController: DateInputControllerDelegate {
    func didTapDone(date: Date) {
        story.date = date
        saveButton.isEnabled = true
        tableView.reloadData()
    }
}
//MARK: - FullPhotoControllerDelegate
extension StoryController: FullPhotoControllerDelegate {
    
}

//MARK: - UINavigationControllerDelegate, UIImagePickerControllerDelegate
extension StoryController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        
        if let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String,
            mediaType == (kUTTypeMovie as String),
            let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            
//            let videoFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
//            dismiss(animated: true) {
            
            
                           do {
                               let videoData = try Data(contentsOf: url)
                               let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                               let destinationPath = NSURL(fileURLWithPath: documentsPath).appendingPathComponent("video.mov", isDirectory: false)
                               FileManager.default.createFile(atPath: destinationPath!.path, contents:videoData, attributes:nil)
                            if let video = VideoModel(url: destinationPath) {
                                story.video = video
                                saveButton.isEnabled = true
                            }
                 
                           } catch {
                               print("Error downloading video")
                           }
            
            
            tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
            
            dismiss(animated: true, completion: nil)
//                let player = AVPlayer(url: url)
//                let vcPlayer = AVPlayerViewController()
//                vcPlayer.player = player
//                self.present(vcPlayer, animated: true, completion: nil)
//            }
        } else {
            
            let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
            
            var  chosenImage = UIImage()
            chosenImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as! UIImage
            if let photo = PhotoModel(image: chosenImage) {
                story.photos.append(photo)
                saveButton.isEnabled = true
            }
            
            //        photoImages.append(chosenImage)
            tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
            
            dismiss(animated: true, completion: nil)
        }
        
        
    }
    
    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
    }
    
    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
        return input.rawValue
    }
}

extension StoryController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
}
