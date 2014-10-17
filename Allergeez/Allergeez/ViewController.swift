//
//  ViewController.swift
//  Allergeez
//
//  Created by Ryan Hoffmann on 10/10/14.
//  Copyright (c) 2014 Mumush. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var findOutButton: UIButton!
    
    @IBOutlet weak var foodTextField: UITextField!
    
    @IBOutlet weak var isFreeImageButton: UIButton!
    
    @IBOutlet weak var imageInfoLabel: UILabel!
    
    
    var foodsList : Array<AnyObject> = []
    
    
    let blueColor = UIColor(red: 80/255, green: 171/255, blue: 250/250, alpha: 1.0) //no food selected (DEFAULT)
    let greenColor = UIColor(red: 123/255, green: 232/255, blue: 180/255, alpha: 1.0) //food IS gluten free
    let redColor = UIColor(red: 251/255, green: 112/255, blue: 105/255, alpha: 1.0) //food IS NOT gluten free
    let purpleColor = UIColor(red: 165/255, green: 124/255, blue: 199/255, alpha: 1.0) //food CAN'T BE FOUND
    
    let infoLabelInitial = "Tap me to get started!"
    let infoLabelNotFound = "Oops, I can't find that!"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        let appDel:AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let context:NSManagedObjectContext = appDel.managedObjectContext!
        
        let fetchRequest = NSFetchRequest(entityName: "Foods")
        
        foodsList = context.executeFetchRequest(fetchRequest, error: nil)!
        println("Food List: \(foodsList)")
        
        
        foodTextField.clearButtonMode = UITextFieldViewMode.Always
        
        self.imageInfoLabel.text = infoLabelInitial
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func isFreeImageButtonPressed(sender: AnyObject) {
        
        self.foodTextField.becomeFirstResponder()
        
    }
    
    

    @IBAction func findButtonPressed() {
        
        var foodTextName = foodTextField.text.lowercaseString
        println("TextField Text: \(foodTextName)")
        
        var didFindFood:Bool = searchFoods(foodTextName) //returns whether or not the food is in the DB
        
        if( didFindFood ) { //food was found
            
            changeUIFromResult( foodDictionary[foodTextName]! )
            
        }
        else { //food wasn't found, change the image view to the uh-oh face
            
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                UIView.animateWithDuration(0.4, animations: { () -> Void in
                
                    self.view.backgroundColor = self.purpleColor
                    self.findOutButton.setTitleColor(self.purpleColor, forState: UIControlState.Normal)
                    self.isFreeImageButton.setImage(UIImage(named: "rolling_oh"), forState: UIControlState.Normal)
                    self.imageInfoLabel.text = self.infoLabelNotFound
                    self.imageInfoLabel.hidden = false
                    
                })
                
            }) //end main thread async
            
            
        }
        
        
    }
    
    //returns true if the food is in the DB
    func searchFoods(foodTextName:String) -> Bool {
        
        let appDel:AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let context:NSManagedObjectContext = appDel.managedObjectContext!
        
        
        var fetchRequest = NSFetchRequest(entityName: "Foods")
        
        var fetchPredicate:NSPredicate = NSPredicate(format: "%K CONTAINS[c] %@", argumentArray: ["name", "\(foodTextName)"])
        fetchRequest.predicate = fetchPredicate
        
        var fetchError:NSError? = nil
        
        var result = context.executeFetchRequest(fetchRequest, error: &fetchError)!
        
        if((fetchError) != nil) {
            
            println("Uh Oh")
            println(fetchError?.localizedDescription)
            
        }
        else if( result.count > 0 ) {
            
            println("Result List: \(result)")
            
            var foodName = result[0].valueForKey("name") as String
            var isGlutenFree = result[0].valueForKey("isGlutenFree") as Bool
            
            println("Food Name: \(foodName)\nIs Gluten Free: \(isGlutenFree)")
            
        }
        else {
            
            println("Food not found")
            
        }
        
        return false
        
    }
    
    
    
    //alters the colors of UI depending on whether the food IS (green), or IS NOT (red), gluten free
    func changeUIFromResult(isGlutenFree:Bool) {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            UIView.animateWithDuration(0.4, animations: { () -> Void in
                
                if (isGlutenFree) { //if it is gluten free, make the background green
                    
                    self.view.backgroundColor = self.greenColor
                    self.findOutButton.setTitleColor(self.greenColor, forState: UIControlState.Normal)
                    self.isFreeImageButton.setImage(UIImage(named: "rolling_happy"), forState: UIControlState.Normal)
                    
                }
                else { //if not, make it red
                    
                    self.view.backgroundColor = self.redColor
                    self.findOutButton.setTitleColor(self.redColor, forState: UIControlState.Normal)
                    self.isFreeImageButton.setImage(UIImage(named: "rolling_sad"), forState: UIControlState.Normal)
                }
                
            
            }) //end animation
            
            
        }) //end main thread async
        
        
        
    }
    
    
    
    //User taps outside of text field to dismiss it
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        
        self.view.endEditing(true)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            UIView.animateWithDuration(0.4, animations: { () -> Void in
                self.isFreeImageButton.setImage(UIImage(named: "rolling_smh"), forState: UIControlState.Normal)
            }) //end animation
            
        }) //end async on main thread
        
        
    }
    
    
    //UITextField Delegate Protocol
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.resignFirstResponder() //hides the keyboard on return keypress
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            UIView.animateWithDuration(0.4, animations: { () -> Void in
                self.isFreeImageButton.setImage(UIImage(named: "rolling_smh"), forState: UIControlState.Normal)
            }) //end animation
            
        }) //end async on main thread
        
        
        return true
        
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        
        //println("Began Editing")
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            //remove the placeholder text to let the user know that they should type in the field
            //self.foodTextField.placeholder = ""
            
        
            UIView.animateWithDuration(0.4, animations: { () -> Void in
                    self.view.backgroundColor = self.blueColor
                    self.findOutButton.setTitleColor(self.blueColor, forState: UIControlState.Normal)
                    self.isFreeImageButton.setImage(nil, forState: UIControlState.Normal)
                    self.imageInfoLabel.hidden = true //hide the informational label
            }) //end animation
            
        }) //end async on main thread
        
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        
        //return the placeholder text to its original state
        //self.foodTextField.placeholder = "Pesto"
        
    }
    
    

}

