//
//  PostImageViewController.swift
//  Parstagram
//
//  Created by Aramis on 10/29/21.
//

import UIKit

import CameraManager
import Parse

class PostImageViewController: UIViewController {

    
    @IBOutlet weak var whiteOuterCircle: UIView!
    @IBOutlet weak var blackInnerCircle: UIView!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var capturedImage: UIImageView!
    
    @IBOutlet weak var flipCameraButton: UIButton!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var dismissViewButton: UIButton!

    @IBOutlet weak var captionTextView: UITextView!
    @IBOutlet weak var publishButton: UIButton!
    

    var cameraManager: CameraManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presentCamera()
        addStyle()
    }
    
    func addStyle() {
        // Hide the image view to allow the preview to show on top
        if cameraManager.canSetPreset(preset: .cif352x288) ?? false{
            cameraManager.cameraOutputQuality = .cif352x288
        }
        capturedImage.isHidden = true
        
        makeViewCircular(whiteOuterCircle)
        makeViewCircular(blackInnerCircle)
        makeViewCircular(captureButton)
        
        whiteOuterCircle.layer.zPosition = 10
        blackInnerCircle.layer.zPosition = 10
        captureButton.layer.zPosition = 10
        flipCameraButton.layer.zPosition = 10
        dismissViewButton.layer.zPosition = 10
        
        previewView.layer.cornerRadius = 10
        
        publishButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0)
        
        // Allow the caption text view's hold on the keyboard to be lost when the user taps outside the field
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(lowerKeyboard))
        view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func presentFinalImage(_ image: UIImage?) {
        if let image = image {
            capturedImage.isHidden = false
            capturedImage.image = image
            cameraManager.stopCaptureSession()
            whiteOuterCircle.isHidden = true
            flipCameraButton.isHidden = true
            // Don't hide the dismiss button, we still need it
        } else {
            print("Failed to unwrap captured image.")
        }
    }
    
    func makeViewCircular(_ view: UIView) {
        let viewLayer = view.layer
        let width = viewLayer.bounds.width
        viewLayer.cornerRadius = width / 2
    }
    
    func presentCamera() {
        cameraManager = CameraManager()
        cameraManager.addPreviewLayerToView(previewView)
    }
    
    func capturePhoto() {
        cameraManager.capturePictureWithCompletion { (result) in
            switch result {
            case .failure:
                print("Failed to capture image")
                self.dismiss(animated: true)
            case .success(let content):
                print("Successfully captured image")
                self.presentFinalImage(content.asImage)
            }
        }
    }
    
    func flipCamera() {
        let oldDevice = cameraManager.cameraDevice
        cameraManager.cameraDevice = oldDevice == .front ? .back : .front
    }
    
    func publishPost(withPhoto image: UIImage, withCaption text: String) {
        print("Publishing...")
        guard let user = PFUser.current() else {
            print("No user object available")
            return
        }
        let submission = PFObject(className: "Post")
        let imageData = image.pngData()!
        let imageFile = PFFileObject(data: imageData)
        
        submission["image"] = imageFile
        submission["caption"] = text
        submission["author"] = user
        
        submission.saveInBackground { (success, error) in
            if error != nil {
                print("Failed to post")
                print(error!.localizedDescription)
            } else if success {
                print("Posted")
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    
    // MARK: IBActions:
    @IBAction func onFlipCamera(_ sender: Any) {
        flipCamera()
    }
    
    @IBAction func onCapturePhoto(_ sender: Any) {
        capturePhoto()
    }
    
    @IBAction func onPublish(_ sender: Any) {
        guard let image = capturedImage.image else {return}
        guard let caption = captionTextView.text else {return}
        publishPost(withPhoto: image, withCaption: caption)
    }
    
    
    @IBAction func onRequestDismissal(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func lowerKeyboard() {
        captionTextView.resignFirstResponder()
    }
}
