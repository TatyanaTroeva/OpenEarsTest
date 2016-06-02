//
//  ViewController.swift
//  WordCount
//
//  Created by iMAC i7 on 3/30/15.
//  Copyright (c) 2015 YuriiMobile. All rights reserved.
//

import UIKit
import MessageUI

class WordCell: UITableViewCell {
    
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
}

class ViewController: UIViewController, OEEventsObserverDelegate, UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate {

    var words: Array<String> = [] // Word array for dictionary
    var countArray: Array<Int> = [] // Array for recognized count
    
    var pathToDynamicallyGeneratedLanguageModel: NSString! // Language Model Path
    var pathToDynamicallyGeneratedDictionary: NSString! // Dictionary Path
    var openEarsEventsObserver: OEEventsObserver!
    var pocketsphinxController: OEPocketsphinxController!
    var usingStartLanguageModel: Bool!
    var restartAttemptsDueToPermissionRequests: Int!
    var startupFailedDueToLackOfPermissions: Bool!
    var IsListening: Bool!
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    
    func startListening() {
        if openEarsEventsObserver == nil {
            openEarsEventsObserver = OEEventsObserver()
            openEarsEventsObserver.delegate = self
        }
        do {
            try OEPocketsphinxController.sharedInstance().setActive(true)
        } catch _ {
        }
  
        OEPocketsphinxController.sharedInstance().startListeningWithLanguageModelAtPath(pathToDynamicallyGeneratedLanguageModel as? String, dictionaryAtPath: pathToDynamicallyGeneratedDictionary as? String, acousticModelAtPath: OEAcousticModel.pathToModel("AcousticModelEnglish") as? String, languageModelIsJSGF: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        restartAttemptsDueToPermissionRequests = 0
        startupFailedDueToLackOfPermissions = false
        
        /**Advanced: set this to TRUE to receive n-best results.*/
        OEPocketsphinxController.sharedInstance().returnNbest = true
        /**Advanced: the number of n-best results to return. This is a maximum number to return -- if there are null hypotheses fewer than this number will be returned.*/
        OEPocketsphinxController.sharedInstance().nBestNumber = 5
        OEPocketsphinxController.sharedInstance().secondsOfSilenceToDetect = 0.5 // Silence detect within 0.5
        OEPocketsphinxController.sharedInstance().vadThreshold = 3.5 // Noise detection
        OELogging .startOpenEarsLogging()
        
        openEarsEventsObserver = OEEventsObserver()
        openEarsEventsObserver.delegate = self
        
        words = ["Demonstrate", "Highlight", "Skillset", "Ability"]
        countArray = [0,0,0,0]
        tableView.reloadData()
        
        let languageModelGenerator = OELanguageModelGenerator()
        let error = languageModelGenerator.generateLanguageModelFromArray(words, withFilesNamed: "FirstOpenEarsDynamicLanguageModel", forAcousticModelAtPath: OEAcousticModel.pathToModel("AcousticModelEnglish"))
        if error == nil {
            pathToDynamicallyGeneratedLanguageModel = languageModelGenerator.pathToSuccessfullyGeneratedLanguageModelWithRequestedName("FirstOpenEarsDynamicLanguageModel")
            pathToDynamicallyGeneratedDictionary = languageModelGenerator.pathToSuccessfullyGeneratedDictionaryWithRequestedName("FirstOpenEarsDynamicLanguageModel")
        }
        usingStartLanguageModel = true
        IsListening = false
//        startListening()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Mark: - UIButton Action
    
    @IBAction func onClickStart(sender: AnyObject) {
        startListening()
        OEPocketsphinxController.sharedInstance().resumeRecognition()
    }

    @IBAction func onClickStop(sender: AnyObject) {
        OEPocketsphinxController.sharedInstance().stopListening()
    }
    
    @IBAction func onClickEmail(sender: AnyObject) {
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            self.presentViewController(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposerVC.setToRecipients(["someone@somewhere.com"])
        mailComposerVC.setSubject("Sending recognition result to...")
        mailComposerVC.addAttachmentData(UIImageJPEGRepresentation(screenShotMethod(), 1.0)!, mimeType: "image/jpeg", fileName: "screenshot.jpg")
        mailComposerVC.setMessageBody("", isHTML: false)
        
        return mailComposerVC
    }
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", delegate: self, cancelButtonTitle: "OK")
        sendMailErrorAlert.show()
    }
    
    func screenShotMethod() -> UIImage {
        //Create the UIImage
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Mark: - UITableViewDelegate, UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return words.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("WordCell") as! WordCell
        cell.wordLabel.text = words[indexPath.row]
        cell.countLabel.text = String(countArray[indexPath.row])
        return cell
    }
    
    // Mark: - OpenEarsEventsObserver delegate methods
    func pocketsphinxDidReceiveHypothesis(hypothesis: String!, recognitionScore: String!, utteranceID: String!) {
        var i: Int
        for i=0; i<words.count; i++ {
            if (hypothesis == words[i]) {
                countArray[i]++ // Increase recognized count
                tableView.reloadData()
                break;
            }
        }
    }
    
    // An optional delegate method of OpenEarsEventsObserver which informs that there was an interruption to the audio session (e.g. an incoming phone call).
    func audioSessionInterruptionDidBegin() {
        OEPocketsphinxController.sharedInstance().stopListening()
    }
    
    // An optional delegate method of OpenEarsEventsObserver which informs that the interruption to the audio session ended.
    func audioSessionInterruptionDidEnd() {
        startListening()
    }
    
    // An optional delegate method of OpenEarsEventsObserver which informs that the unavailable audio input became available again.
    func audioInputDidBecomeAvailable() {
        startListening()
    }
    
    // An optional delegate method of OpenEarsEventsObserver which informs that the audio input became unavailable.
    func audioInputDidBecomeUnavailable() {
        OEPocketsphinxController.sharedInstance().stopListening()
    }
    
    // An optional delegate method of OpenEarsEventsObserver which informs that there was a change to the audio route (e.g. headphones were plugged in or unplugged).
    func audioRouteDidChangeToRoute(newRoute: String!) {
        OEPocketsphinxController.sharedInstance().stopListening()
        startListening()
    }
    
    // An optional delegate method of OpenEarsEventsObserver which informs that the Pocketsphinx recognition loop hit the calibration stage in its startup.
    // This might be useful in debugging a conflict between another sound class and Pocketsphinx. Another good reason to know when you're in the middle of
    // calibration is that it is a timeframe in which you want to avoid playing any other sounds including speech so the calibration will be successful.
    func pocketsphinxDidStartCalibration() {
        
    }
    
    // An optional delegate method of OpenEarsEventsObserver which informs that the Pocketsphinx recognition loop completed the calibration stage in its startup.
    // This might be useful in debugging a conflict between another sound class and Pocketsphinx.
    func pocketsphinxDidCompleteCalibration() {
        OEPocketsphinxController.sharedInstance().suspendRecognition()
    }
    
    // An optional delegate method of OpenEarsEventsObserver which informs that the Pocketsphinx recognition loop has entered its actual loop.
    // This might be useful in debugging a conflict between another sound class and Pocketsphinx.
    func pocketsphinxRecognitionLoopDidStart() {
        
    }
    
    // An optional delegate method of OpenEarsEventsObserver which informs that Pocketsphinx is now listening for speech.
    func pocketsphinxDidStartListening() {
        startButton.enabled = false
        stopButton.enabled = true
    }
    
    // An optional delegate method of OpenEarsEventsObserver which informs that Pocketsphinx detected speech and is starting to process it.
    func pocketsphinxDidDetectSpeech() {
        
    }
    
    // An optional delegate method of OpenEarsEventsObserver which informs that Pocketsphinx detected a second of silence, indicating the end of an utterance.
    // This was added because developers requested being able to time the recognition speed without the speech time. The processing time is the time between
    // this method being called and the hypothesis being returned.
    func pocketsphinxDidDetectFinishedSpeech() {
        
    }
    
    // An optional delegate method of OpenEarsEventsObserver which informs that Pocketsphinx has exited its recognition loop, most
    // likely in response to the PocketsphinxController being told to stop listening via the stopListening method.
    func pocketsphinxDidStopListening() {
        startButton.enabled = true
        stopButton.enabled = false
    }
    
    // An optional delegate method of OpenEarsEventsObserver which informs that Pocketsphinx is still in its listening loop but it is not
    // Going to react to speech until listening is resumed.  This can happen as a result of Flite speech being
    // in progress on an audio route that doesn't support simultaneous Flite speech and Pocketsphinx recognition,
    // or as a result of the PocketsphinxController being told to suspend recognition via the suspendRecognition method.
    func pocketsphinxDidSuspendRecognition() {
        
    }
    
    // An optional delegate method of OpenEarsEventsObserver which informs that Pocketsphinx is still in its listening loop and after recognition
    // having been suspended it is now resuming.  This can happen as a result of Flite speech completing
    // on an audio route that doesn't support simultaneous Flite speech and Pocketsphinx recognition,
    // or as a result of the PocketsphinxController being told to resume recognition via the resumeRecognition method.
    func pocketsphinxDidResumeRecognition() {
        
    }
    
    // An optional delegate method which informs that Pocketsphinx switched over to a new language model at the given URL in the course of
    // recognition. This does not imply that it is a valid file or that recognition will be successful using the file.
    func pocketsphinxDidChangeLanguageModelToFile(newLanguageModelPathAsString: String!, andDictionary newDictionaryPathAsString: String!) {
        
    }
    
    // An optional delegate method of OpenEarsEventsObserver which informs that Flite is speaking, most likely to be useful if debugging a
    // complex interaction between sound classes. You don't have to do anything yourself in order to prevent Pocketsphinx from listening to Flite talk and trying to recognize the speech.
    func fliteDidStartSpeaking() {
        
    }
    
    // An optional delegate method of OpenEarsEventsObserver which informs that Flite is finished speaking, most likely to be useful if debugging a
    // complex interaction between sound classes.
    func fliteDidFinishSpeaking() {
        
    }
    
    func pocketSphinxContinuousSetupDidFail() {
        
    }
    
    func testRecognitionCompleted() {
        OEPocketsphinxController.sharedInstance().stopListening()
    }
    
    /** Pocketsphinx couldn't start because it has no mic permissions (will only be returned on iOS7 or later).*/
    func pocketsphinxFailedNoMicPermissions() {
        startupFailedDueToLackOfPermissions = true
    }
    
    /** The user prompt to get mic permissions, or a check of the mic permissions, has completed with a TRUE or a FALSE result  (will only be returned on iOS7 or later).*/
    func micPermissionCheckCompleted(result: Bool) {
        if result == true {
            restartAttemptsDueToPermissionRequests = restartAttemptsDueToPermissionRequests+1
            if restartAttemptsDueToPermissionRequests == 1 && startupFailedDueToLackOfPermissions == true {
                startListening()
                startupFailedDueToLackOfPermissions = false
            }
        }
    }
}

