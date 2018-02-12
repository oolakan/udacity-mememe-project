//
//  ViewController.swift
//  ImagePicker
//
//  Created by Swifta on 2/2/18.
//  Copyright © 2018 Swifta. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    

    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var bottomTextFields: UITextField!
    @IBOutlet weak var topTextFields: UITextField!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    //let paragraph = NSMutableParagraphStyle().alignment = .center
    
   
    override func viewDidLoad() {
        super.viewDidLoad()
        // set text alignment to center
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let memeTextAttributes:[String:Any] = [
            NSAttributedStringKey.strokeColor.rawValue: UIColor.black /* TODO: fill in appropriate UIColor */,
            NSAttributedStringKey.foregroundColor.rawValue: UIColor.white,
            NSAttributedStringKey.font.rawValue: UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
            NSAttributedStringKey.strokeWidth.rawValue: CGFloat(-4.5) /* TODO: fill in appropriate Float */,
            NSAttributedStringKey.paragraphStyle.rawValue: paragraph
        ]
        self.topTextFields.delegate = self
        self.bottomTextFields.delegate = self
        
        self.navigationController?.isNavigationBarHidden = true
        self.topTextFields.backgroundColor = .clear
        self.bottomTextFields.backgroundColor = .clear
        
        self.topTextFields.defaultTextAttributes = memeTextAttributes
        self.bottomTextFields.defaultTextAttributes = memeTextAttributes
    
    }
    // select image from album
    @IBAction func pickAnImageFromAlbum(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
        present(imagePicker, animated: true, completion: nil)
    }
    // capture image from camera
    @IBAction func pickAnImageFromCamera(_ sender: Any)  {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.modalPresentationStyle = .fullScreen
        present(imagePicker, animated: true, completion: nil)
    }
    // cancel saved mimedImage and reset to default
    @IBAction func cancel() {
        self.navigationController?.isNavigationBarHidden = true; // hide navigation bar
        imageView.image = nil //remove image
        topTextFields.text = "TOP" //reset top text field
        bottomTextFields.text = "BOTTOM" // reset bottom textfield
    }
    // share memed image with friends
    @IBAction func shareWithFriends(){
        if ((topTextFields.text?.isEmpty)! || (bottomTextFields.text?.isEmpty)!) {
            alert(title: "Action", message: "Both top and bottom texts are required")
        }else {
            let message = "check out this cool image"
            let sharedImage = generateMemedImage()
            let activityViewController = UIActivityViewController(activityItems: [message, sharedImage], applicationActivities: nil)
            self.present(activityViewController, animated: true, completion: nil)
            
            //REF: https://stackoverflow.com/questions/45122576/ios-swift-how-to-know-when-activityviewcontroller-has-//been-successfully-used
            activityViewController.completionWithItemsHandler = { activity, completed, items, error in
                if !completed {
                    // handle task not completed
                    print("This task was not completed")
                    return
                }
                self.save()
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        let selectedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        self.navigationController?.isNavigationBarHidden = false
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        imageView.image = selectedImage
        dismiss(animated:true, completion: nil)
    }
    
    // dismiss image picker view controller
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // check if camera is avaible on device
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subscribeToKeyboardNotifications()
        subscribeToKeyboardWillHideNotifications()
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        topTextFields.resignFirstResponder()
        bottomTextFields.resignFirstResponder()
        return true
    }
   
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
        unsubscribeFromKeyboardWillHideNotifications()
    }
    
    
    func subscribeToKeyboardNotifications() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
    }
    
    func subscribeToKeyboardWillHideNotifications() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
    }
    
    func unsubscribeFromKeyboardWillHideNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    

    @objc func keyboardWillShow(_ notification:Notification) {
        if (bottomTextFields.isEditing) {
            self.view.frame.origin.y -= getKeyboardHeight(notification)
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y += getKeyboardHeight(notification)
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if topTextFields.isEditing {
            topTextFields.text = nil
        }
        if bottomTextFields.isEditing {
            bottomTextFields.text = nil
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    func getKeyboardHeight(_ notification:Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.cgRectValue.height
    }
    
    func save() {
            // save the memed image with texts
        let memedImage: UIImage = generateMemedImage()
        _ = Meme(topText: topTextFields.text!, bottomText: bottomTextFields.text!, originalImage: imageView.image!, memedImage: memedImage)
    }

    func generateMemedImage() -> UIImage {
        // hide navbar and toolbar
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.isToolbarHidden = true
        
        // Render view to an image
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
        let memedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        // show navbar and toolbar
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.isToolbarHidden = false
      
        return memedImage
    }
    
    
    func alert(title: String, message: String) {
        let uiAlertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        uiAlertController.addAction(UIAlertAction(title: "CLOSE", style: .default, handler: nil))
        present(uiAlertController, animated: true, completion: nil)
        return
    }
    
}

