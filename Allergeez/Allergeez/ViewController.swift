//
//  ViewController.swift
//  Allergeez
//
//  Created by Ryan Hoffmann on 10/10/14.
//  Copyright (c) 2014 Mumush. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var findOutButton: UIButton!
    @IBOutlet weak var foodTextField: UITextField!
    @IBOutlet weak var isFreeImageButton: UIButton!
    @IBOutlet weak var imageInfoLabel: UILabel!
    @IBOutlet weak var isAreLabel: UILabel!
    
    
    //Array of all allergens' column names in the data store
    var allergensArray = ["isGlutenFree", "isDairyFree", "isSoyFree"]
    
    
    
    let infoLabelInitial = "Tap me to get started!"
    let infoLabelNotFound = "Oops, I can't find that!"
    let infoLabelEmptySearch = "C'mon, at least type something!"
    let infoLabelisFree = "You're in the clear!"
    let infoLabelisNotFree = "Nope, avoid this one!"
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        foodTextField.clearButtonMode = UITextFieldViewMode.Always
        
        generateScrollView()
        
    }

    
    
    func generateScrollView() {
        
        var glutenLabel = UILabel()
        glutenLabel.frame = CGRectMake(0, 0, scrollView.frame.size.width, scrollView.frame.size.height)
        glutenLabel.text = "Gluten Free?"
        glutenLabel.textColor = UIColor.whiteColor()
        glutenLabel.font = UIFont(name: "HelveticaNeue-Thin", size: 40.0)
        glutenLabel.textAlignment = NSTextAlignment.Center
        
        var dairyLabel = UILabel()
        dairyLabel.frame = CGRectMake(320, 0, scrollView.frame.size.width, scrollView.frame.size.height)
        dairyLabel.text = "Dairy Free?"
        dairyLabel.textColor = UIColor.whiteColor()
        dairyLabel.font = UIFont(name: "HelveticaNeue-Thin", size: 40.0)
        dairyLabel.textAlignment = NSTextAlignment.Center
        
        var soyLabel = UILabel()
        soyLabel.frame = CGRectMake(640, 0, scrollView.frame.size.width, scrollView.frame.size.height)
        soyLabel.text = "Soy Free?"
        soyLabel.textColor = UIColor.whiteColor()
        soyLabel.font = UIFont(name: "HelveticaNeue-Thin", size: 40.0)
        soyLabel.textAlignment = NSTextAlignment.Center

        
        scrollView.contentSize = CGSize(width: 960.0, height: 65.0)
        scrollView.pagingEnabled = true;
        
        scrollView.addSubview(glutenLabel)
        scrollView.addSubview(dairyLabel)
        scrollView.addSubview(soyLabel)
        
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //tap on the rolling pin imageview, bring the foodTextField into focus with the keyboard
    @IBAction func isFreeImageButtonPressed(sender: AnyObject) {
        
        self.foodTextField.becomeFirstResponder()
    }
    

    @IBAction func findButtonPressed() {
        
        var sanitizedFood = sanitizeFoodString(self.foodTextField.text)
        
        if sanitizedFood == "" {
            
            changeUIEmpty()
            
            return
        }
        
        if let queryFoodsResult = searchFoods(sanitizedFood) { //the food exists in the DB, we should use it
            
            println(queryFoodsResult.valueForKey("name")!)
            
            
            //check to see which allergen is selected
            println("Current Page: \(pageControl.currentPage)")
            
            //get the string related to the current page
            //Ex. if "Gluten Free?" page is selected, return "isGlutenFree" from the allergens array
            //defined afer the user first runs the app
            //allergensArray[pageControl.currentPage]
            
            var isAllergenFree:Bool = queryFoodsResult.valueForKey( allergensArray[pageControl.currentPage] ) as Bool
            
            if isAllergenFree {
                
                self.changeUIIsFree()
                
            }
            else {
                
                self.changeUIIsNotFree()
                
            }
            
        }
        else { //the food is nil, it does not exist in the DB
            
            println("Food wasn't found")
                
            self.changeUINotFound()
            
        }
        
        
    }
    
    
    //Returns the sanitized version of the food the user entered in the text field
    func sanitizeFoodString(foodTextName:String) -> String {
        
        println("Original String: \(foodTextName)")
        
        var sanitizedFood = foodTextField.text.lowercaseString //lol
        
        println("Lowercase String: \(sanitizedFood)")
        
        sanitizedFood = sanitizedFood.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        sanitizedFood = sanitizedFood.stringByTrimmingCharactersInSet(NSCharacterSet.punctuationCharacterSet())
        
        println("No Whitespace String: \(sanitizedFood)")
        
        return sanitizedFood
        
    }
    
    
    //Returns a food as an NSManagedObject if it's found in the store, if not, returns nil
    func searchFoods(foodTextName:String) -> NSManagedObject? {
        
        let appDel:AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let context:NSManagedObjectContext = appDel.managedObjectContext!
        
        //configure fetch request with predicate
        var fetchRequest = NSFetchRequest(entityName: "Foods")
        var fetchPredicate:NSPredicate = NSPredicate(format: "%K MATCHES[c] %@", argumentArray: ["name", "\(foodTextName)"])
        fetchRequest.predicate = fetchPredicate

        var fetchError:NSError? = nil
        
        //assign the query result to "result" array
        var result = context.executeFetchRequest(fetchRequest, error: &fetchError)!
        
        if((fetchError) != nil) { //if there was a fetch error, CONSIDER another color for fetch errors
            
            println("Fetch Error")
            println(fetchError?.localizedDescription)
            
            return nil
            
        }
        else if( result.count > 0 ) { //if at least one result was found
            
            println("Result List: \(result)")
            
            var foundFoodObject:NSManagedObject = result[0] as NSManagedObject
            
            var foodName = foundFoodObject.valueForKey("name") as String
            var isAllergenFree = foundFoodObject.valueForKey( allergensArray[pageControl.currentPage] ) as Bool
            
            println("Food Name: \(foodName)\n\(allergensArray[pageControl.currentPage]): \(isAllergenFree)")
            

            if foodName.hasSuffix("s") && !foodName.hasSuffix("us") && !foodName.hasSuffix("ss") {
                
                changeIsAreLabel("Are")
                
            }

            
            
            return foundFoodObject
            
        }
        else { //if no result was found
            
            println("Food not found")
         
            return nil
            
        }
        
        
    }
    
    //Changes the text in the label that initially reads "Is" -> 'newLabel' is the string of text to change the label to
    func changeIsAreLabel(newLabel: String) {
        
        self.isAreLabel.text = newLabel
        
    }
    
    
    
    //Changes the UI color to GREEN and the rolling pins icon because the food IS allergen free
    func changeUIIsFree() {
        
        let greenColor = UIColor(red: 99/255, green: 219/255, blue: 153/255, alpha: 1.0)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
        
            UIView.animateWithDuration(0.4, animations: { () -> Void in

                self.view.backgroundColor = greenColor
                self.findOutButton.setTitleColor(greenColor, forState: UIControlState.Normal)
                self.isFreeImageButton.setImage(UIImage(named: "rolling_happy"), forState: UIControlState.Normal)
                self.imageInfoLabel.text = self.infoLabelisFree
                self.imageInfoLabel.hidden = false
            
            }) //end animation
            
        })
        
    }
    
    //Changes the UI color to RED and the rolling pins icon because the food IS NOT allergen free
    func changeUIIsNotFree() {
        
        let redColor = UIColor(red: 251/255, green: 112/255, blue: 105/255, alpha: 1.0)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
        
            UIView.animateWithDuration(0.4, animations: { () -> Void in
            
                self.view.backgroundColor = redColor
                self.findOutButton.setTitleColor(redColor, forState: UIControlState.Normal)
                self.isFreeImageButton.setImage(UIImage(named: "rolling_sad"), forState: UIControlState.Normal)
                self.imageInfoLabel.text = self.infoLabelisNotFree
                self.imageInfoLabel.hidden = false
            
            }) //end animation
            
        })
        
    }
    
    //Changes the UI color to PURPLE and the rolling pins icon because the food CAN'T BE FOUND in the database
    func changeUINotFound() {
        
        let purpleColor = UIColor(red: 165/255, green: 124/255, blue: 199/255, alpha: 1.0)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
        
            UIView.animateWithDuration(0.4, animations: { () -> Void in
            
                self.view.backgroundColor = purpleColor
                self.findOutButton.setTitleColor(purpleColor, forState: UIControlState.Normal)
                self.isFreeImageButton.setImage(UIImage(named: "rolling_oh"), forState: UIControlState.Normal)
                self.imageInfoLabel.text = self.infoLabelNotFound
                self.imageInfoLabel.hidden = false
            
            })
        })
        
    }
    
    func changeUIDefault() {
        
        let blueColor = UIColor(red: 102/255, green: 165/255, blue: 255/255, alpha: 1.0)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
        
            UIView.animateWithDuration(0.4, animations: { () -> Void in
                self.view.backgroundColor = blueColor
                self.findOutButton.setTitleColor(blueColor, forState: UIControlState.Normal)
                self.isFreeImageButton.setImage(nil, forState: UIControlState.Normal)
                self.imageInfoLabel.hidden = true //hide the informational label
            }) //end animation
        })
    }
    
    func changeUIEmpty() {
        
        let blueColor = UIColor(red: 102/255, green: 165/255, blue: 255/255, alpha: 1.0)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            UIView.animateWithDuration(0.4, animations: { () -> Void in
                self.isFreeImageButton.setImage(UIImage(named: "rolling_smh"), forState: UIControlState.Normal)
                self.imageInfoLabel.text = self.infoLabelEmptySearch
                self.imageInfoLabel.hidden = false
            }) //end animation
        })
        
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
        
        //First change the Is/Are label back to "Is" to conform with the singular placeholder "Corn" below
        changeIsAreLabel("Is")
        
        let zeroOpacityColor = UIColor(red: 80/255, green: 171/255, blue: 250/250, alpha: 0.0)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            //Remove the placeholder text to let the user know that they should type in the field
            self.foodTextField.attributedPlaceholder = NSAttributedString(string: "Corn", attributes: [NSForegroundColorAttributeName: zeroOpacityColor])
            
        }) //end async on main thread
        
        
        self.changeUIDefault()
        
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        
        //return the placeholder text to its original state
        self.foodTextField.attributedPlaceholder = NSAttributedString(string: "Corn")
        
    }
    
    

    //UIScrollViewDelegate Methods
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        if scrollView.contentOffset.x == 0 {
            
            pageControl.currentPage = 0
            
        }
        else if scrollView.contentOffset.x == 320 {
            
            pageControl.currentPage = 1
            
        }
        else if scrollView.contentOffset.x == 640 {
            
            pageControl.currentPage = 2
            
        }
        
    }
    
    

}

