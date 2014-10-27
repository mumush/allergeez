//
//  ViewController.swift
//  AllergeezDataInput
//
//  Created by Ryan Hoffmann on 10/13/14.
//  Copyright (c) 2014 Mumush. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITextFieldDelegate {
    
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var isGlutenFreeSwitch: UISwitch!
    @IBOutlet weak var isDairyFreeSwitch: UISwitch!
    @IBOutlet weak var isSoyFreeSwitch: UISwitch!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        nameTextField.clearButtonMode = UITextFieldViewMode.Always
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    @IBAction func addButtonPressed(sender: AnyObject) {
        
        var foodExists:Bool = doesFoodAlreadyExist()
        
        if !foodExists { //food DOES NOT exist in DB, so insert it
         
            insertNewFood()
            
            navigationController?.popViewControllerAnimated(true)
            
        }
        else { //food DOES is exist in DB
            
            let alert = UIAlertView()
            alert.title = "Uh oh!"
            alert.message = "This food already exists in the data store."
            alert.addButtonWithTitle("Got it")
            alert.show()
            
        }
        
        
    }
    
    //Returns true if the food is already stored in the DB, false if it is not
    func doesFoodAlreadyExist() -> Bool {
        
        let appDel:AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let context:NSManagedObjectContext = appDel.managedObjectContext!
        
        var fetchCheckIfExists:NSFetchRequest = NSFetchRequest(entityName: "Foods")
        fetchCheckIfExists.predicate = NSPredicate(format: "name ==[c] %@", self.nameTextField.text.lowercaseString)
        var numOfOccurences = context.countForFetchRequest(fetchCheckIfExists, error: nil)
        
        //println(numOfOccurences)
        
        if numOfOccurences == 0 {
            
            return false
            
        }
        else {
            
            return true
            
        }
        
    }
    
    //Inserts food into data store based on input values
    func insertNewFood() {
        
        let appDel:AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let context:NSManagedObjectContext = appDel.managedObjectContext!
            
        let entityDescription = NSEntityDescription.entityForName("Foods", inManagedObjectContext: context)
        
        
        var newFood = Foods(entity: entityDescription!, insertIntoManagedObjectContext: context)
        
        newFood.name = self.nameTextField.text.lowercaseString
        newFood.isGlutenFree = self.isGlutenFreeSwitch.on
        newFood.isDairyFree = self.isDairyFreeSwitch.on
        newFood.isSoyFree = self.isSoyFreeSwitch.on
        
        //println(newFood)
        context.save(nil)
        //println("Food Saved.")
        
        
    }
    
    //User taps outside of text field to dismiss it
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        
        self.view.endEditing(true)
        
    }
    
    //UITextField Delegate Protocol
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.resignFirstResponder() //hides the keyboard on return keypress
        
        return true
        
    }
    


}

