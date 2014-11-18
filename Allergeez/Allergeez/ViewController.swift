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
    
    @IBOutlet weak var ingredientField: UITextField!
    @IBOutlet weak var isAreLabel: UILabel!
    @IBOutlet weak var rollingPinImageButton: UIButton!
    @IBOutlet weak var rollingPinLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    @IBOutlet weak var scrollViewCenterYConstraint: NSLayoutConstraint!
    
    //Array of all allergens' column names in the data store, and their correlating label names
    var allergensArray = [ ("isGlutenFree", "Gluten Free?"), ("isDairyFree", "Dairy Free?"), ("isSoyFree", "Soy Free?")]
    
    
    //Arrays used for label under rolling pin icon, based on result of ingredient search
    let infoLabelEmptySearch = "Type something first!"
    let infoLabelisFreeArray = ["You're in the clear!", "Yes indeed. Mmmm.", "This'll be tasty. Enjoy!", "Yep. Throw it in the cart!"]
    let infoLabelisNotFreeArray = ["Nope, avoid this one!", "Stay away from it!", "This won't make ya feel good!", "Pass on this."]
    let infoLabelNotFoundArray = ["Oops, I can't find that!", "Uh oh. I can't find that!", "Uh oh...This is awkward."]
    
    
    //Colors used to change the main views background color
    var blueColor:UIColor! //Exact color of main view background -> initialized in viewDidLoad()
    let greenColor = UIColor(red: 99/255, green: 219/255, blue: 153/255, alpha: 1.0)
    let redColor = UIColor(red: 251/255, green: 112/255, blue: 105/255, alpha: 1.0)
    let purpleColor = UIColor(red: 165/255, green: 124/255, blue: 199/255, alpha: 1.0)
    let zeroOpacityColor = UIColor(red: 80/255, green: 171/255, blue: 250/250, alpha: 0.0) //used to make the placeholder text transparent
    
    
    //Used for speed in UI animations after searching ingredients or swiping allergens
    let changeUIAnimSpeed:NSTimeInterval = 0.2
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //Get the exact value of the initial background color of the main view defined in IB
        blueColor = self.view.backgroundColor
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(true)
        
        //puts all allergen labels into the scrollView
        populateScrollView()
        
    }

    
    //Populates scrollView with a label for each food allergen from allergensArray
    func populateScrollView() {
        
        let labelFontSize:CGFloat = 45.0
        
        //Populate the scrollview with labels
        for var index = 0; index < allergensArray.count; index++ {
            
            var allergenLabel = UILabel()
            allergenLabel.frame = CGRectMake(scrollView.frame.size.width * CGFloat(index), 0, scrollView.frame.size.width, scrollView.frame.size.height)
            allergenLabel.text = allergensArray[index].1
            allergenLabel.textColor = UIColor.whiteColor()
            allergenLabel.font = UIFont(name: "HelveticaNeue-Thin", size: labelFontSize)
            allergenLabel.textAlignment = NSTextAlignment.Center
            
            scrollView.addSubview(allergenLabel)
        }

        //contentSize is equal to the number of labels added (3) * the frame width of the scrollView
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width * CGFloat(allergensArray.count), height: scrollView.frame.size.height)
        scrollView.pagingEnabled = true
        scrollView.decelerationRate = UIScrollViewDecelerationRateFast
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    //Tap on the rolling pin, bring ingredientField into focus with the keyboard
    @IBAction func rollingPinPressed(sender: AnyObject) {
        
        self.ingredientField.becomeFirstResponder()
        
    }

    
    //Called when the user presses the search key
    func searchIngredients() {
        
        var sanitizedIngredient = sanitizeIngredientString(self.ingredientField.text)
        
        if sanitizedIngredient == "" {
            
            changeUIEmpty()
            
            return
        }
        
        if let queryResult = queryIngredientStore(sanitizedIngredient) { //the ingredient exists in the DB, use it's managed object
            
            var ingredientName = queryResult.valueForKey("name") as String
            println("\(ingredientName)")
            
            
            //If the ingredient should be pronounced plural, change the label to read "Are"
            if ingredientName.hasSuffix("s") && !ingredientName.hasSuffix("us") && !ingredientName.hasSuffix("ss") {
                
                changeIsAreLabel("Are")
            }
            
            
            //Check to see which allergen is selected
            println("Current Page: \(pageControl.currentPage)")
            
            //Use current pageControl page as index in allergensArray, and select the first (0th) item in the tuple
            //Ex. if "Gluten Free?" page is selected, return "isGlutenFree" from the allergens array tuple -> ("isGlutenFree", "Gluten Free?")
            
            var isAllergenFree:Bool = queryResult.valueForKey( allergensArray[pageControl.currentPage].0 ) as Bool
            
            if isAllergenFree {
                
                self.changeUIIsFree()
                
            }
            else {
                
                self.changeUIIsNotFree()
                
            }
            
        }
        else { //the ingredient is nil, it does not exist in the store
            
            println("Ingredient wasn't found")
                
            self.changeUINotFound()
        }
        
        
    }
    
    
    //Returns the sanitized version of the ingredient string the user entered in the text field
    func sanitizeIngredientString(ingredient:String) -> String {
        
        println("Original String: \(ingredient)")
        
        var sanitizedIngredient = ingredient.lowercaseString //lol
        
        println("Lowercase String: \(sanitizedIngredient)")
        
        sanitizedIngredient = sanitizedIngredient.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        sanitizedIngredient = sanitizedIngredient.stringByTrimmingCharactersInSet(NSCharacterSet.punctuationCharacterSet())
        
        println("No Whitespace/Punctuation String: \(sanitizedIngredient)")
        
        return sanitizedIngredient
        
    }
    
    
    //Returns an ingredient as an NSManagedObject if it's found in the data store, if not, returns nil
    func queryIngredientStore(ingredient:String) -> NSManagedObject? {
        
        let appDel:AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let context:NSManagedObjectContext = appDel.managedObjectContext!
        
        //configure fetch request with predicate
        var fetchRequest = NSFetchRequest(entityName: "Foods")
        var fetchPredicate:NSPredicate = NSPredicate(format: "%K MATCHES[c] %@", argumentArray: ["name", "\(ingredient)"])
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
            
            var foundIngredientObject:NSManagedObject = result[0] as NSManagedObject //only interested in first result
            
            var ingredientName = foundIngredientObject.valueForKey("name") as String
            var isAllergenFree = foundIngredientObject.valueForKey( allergensArray[pageControl.currentPage].0 ) as Bool
            
            println("Ingredient Name: \(ingredientName)\n\(allergensArray[pageControl.currentPage].0): \(isAllergenFree)")
            
            
            return foundIngredientObject
            
        }
        else { //if no result was found
            
            println("Ingredient not in store")
         
            return nil
            
        }
        
        
    }
    
    //Changes the text in isAreLabel that initially reads "Is" to newLabel
    func changeIsAreLabel(newLabel: String) {
        
        self.isAreLabel.text = newLabel
    }
    
    
    //Returns a random element from the array passed (see arrays defined at top)
    //Element will contain a search result saying based on result of search
    func getRandomSaying(searchResultSayings : [String]) -> String {
        
        var randomIndex = Int( arc4random_uniform( UInt32(searchResultSayings.count)))
        
        return searchResultSayings[randomIndex]
    }
    
    
    //Changes elements of UI because the ingredient IS allergen free
    func changeUIIsFree() {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
        
            UIView.animateWithDuration(self.changeUIAnimSpeed, animations: { () -> Void in

                self.view.backgroundColor = self.greenColor
                self.rollingPinImageButton.setImage(UIImage(named: "rolling_happy"), forState: UIControlState.Normal)
                self.rollingPinLabel.text = self.getRandomSaying(self.infoLabelisFreeArray)
                self.rollingPinLabel.hidden = false
            
            }) //end animation
            
        })
    }
    
    //Changes elements of UI because the ingredient IS NOT allergen free
    func changeUIIsNotFree() {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
        
            UIView.animateWithDuration(self.changeUIAnimSpeed, animations: { () -> Void in
            
                self.view.backgroundColor = self.redColor
                self.rollingPinImageButton.setImage(UIImage(named: "rolling_sad"), forState: UIControlState.Normal)
                self.rollingPinLabel.text = self.getRandomSaying(self.infoLabelisNotFreeArray)
                self.rollingPinLabel.hidden = false
            
            }) //end animation
            
        })
    }
    
    //Changes elements of UI because the ingredient CAN'T BE FOUND in the database
    func changeUINotFound() {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
        
            UIView.animateWithDuration(self.changeUIAnimSpeed, animations: { () -> Void in
            
                self.view.backgroundColor = self.purpleColor
                self.rollingPinImageButton.setImage(UIImage(named: "rolling_oh"), forState: UIControlState.Normal)
                self.rollingPinLabel.text = self.getRandomSaying(self.infoLabelNotFoundArray)
                self.rollingPinLabel.hidden = false
            
            })
        })
    }
    
    
    func changeUIDefault() {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
        
            UIView.animateWithDuration(self.changeUIAnimSpeed, animations: { () -> Void in
                self.view.backgroundColor = self.blueColor
                self.rollingPinImageButton.setImage(nil, forState: UIControlState.Normal)
                self.rollingPinLabel.hidden = true //hide the informational label
            }) //end animation
        })
    }
    
    //Changes elements of UI because no text was entered into the text field
    func changeUIEmpty() {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            UIView.animateWithDuration(self.changeUIAnimSpeed, animations: { () -> Void in
                self.view.backgroundColor = self.blueColor
                self.rollingPinImageButton.setImage(UIImage(named: "rolling_smh"), forState: UIControlState.Normal)
                self.rollingPinLabel.text = self.infoLabelEmptySearch
                self.rollingPinLabel.hidden = false
            }) //end animation
        })
    }
    
    //Changes elements of UI because the user is swiping between allergens
    func changeUISwiping() {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            UIView.animateWithDuration(self.changeUIAnimSpeed, animations: { () -> Void in
                self.view.backgroundColor = self.blueColor
                self.rollingPinImageButton.setImage(UIImage(named: "rolling_smh"), forState: UIControlState.Normal)
                self.rollingPinLabel.hidden = true
            }) //end animation
        })
    }
    
    
    //Hides or Shows the scrollView and the associated pageControl
    //Only used for devices prior to iPhone 5 (ex. 4s)
    func toggleScrollViewVisible() {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            UIView.animateWithDuration(0.1, animations: { () -> Void in
                
                if self.scrollView.hidden == true { //if it's already hidden, show it
                    
                    self.scrollView.hidden = false
                    self.pageControl.hidden = false
                }
                else { //if it's visible, hide it
                    
                    self.scrollView.hidden = true
                    self.pageControl.hidden = true
                }
                
                
            }) //end animation
        })
        
    }
    
    //Moves the Y coordinate of scrollView up by a constant value, moving all above views up as well
    //Used for all devices past the iPhone 4s (ex. 5, 5s, 6, etc.)
    func slideUpMainView() {
        
        self.view.layoutIfNeeded()
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                
                self.scrollViewCenterYConstraint.constant = self.scrollViewCenterYConstraint.constant + 40.0
                
                self.view.layoutIfNeeded()
                
            }) //end animation
        })
        
    }
    
    
    //Moves the Y coordinate of scrollView down by a constant value, moving all above views down as well
    //Used for all devices past the iPhone 4s (ex. 5, 5s, 6, etc.)
    func slideDownMainView() {
        
        self.view.layoutIfNeeded()
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                
                self.scrollViewCenterYConstraint.constant = self.scrollViewCenterYConstraint.constant - 40.0
                
                self.view.layoutIfNeeded()
                
            }) //end animation
        })
        
    }
    
    
    //-----UITextField Delegate Methods-----
    

    
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {

        //If the main views' height is less than that of the 5s, hide and show the scrollView
        if self.view.frame.height < 568.0 {
            
            toggleScrollViewVisible()
        }
            
        //If the main views' height is that of the 5s or greater, animate the scrollViews constraints up
        else {
            
            slideUpMainView()
        }
        
        
        return true
    }
    
    
    func textFieldDidBeginEditing(textField: UITextField) {
        
        
        //First change the Is/Are label back to "Is" to conform with the singular placeholder "Corn" below
        changeIsAreLabel("Is")
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            //Hide the placeholder text (make it transparent) to let the user know that they should type in the field
            self.ingredientField.attributedPlaceholder = NSAttributedString(string: "Corn", attributes: [NSForegroundColorAttributeName: self.zeroOpacityColor])
            
        }) //end async on main thread
        
        
        self.changeUIDefault()
        
    }
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        //If the main views' height is less than that of the 5s, hide and show the scrollView
        //*No need to worry about landscape heights, app is portrait only
        if self.view.frame.height < 568.0 {
            
            toggleScrollViewVisible()
        }
        //If the main views' height is that of the 5s or greater, animate the scrollViews constraints back down
        else {
            
            slideDownMainView()
        }
        
        textField.resignFirstResponder() //hides the keyboard on return keypress
        
        searchIngredients()
        
        return true
        
    }
    
    
    func textFieldDidEndEditing(textField: UITextField) {
        
        //Return the placeholder text to its original state
        self.ingredientField.attributedPlaceholder = NSAttributedString(string: "Corn")
    }
    
    
    

    //-----UIScrollViewDelegate Methods-----
    
    
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        
        changeUISwiping()
    }
    
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {

        //Check if the scrollView's ending offset is equal to any of the labels starting x values
        //If it is, set the currentPage to the associated index, which correlates to a specific allergen (on purpose)
        
        for var index = 0; index < allergensArray.count; index++ {
            
            //If we're not editing (ie. keyboard is gone) search the ingredients & update the pageControl
            if (scrollView.contentOffset.x == scrollView.frame.size.width * CGFloat(index)) && !ingredientField.editing {
                
                pageControl.currentPage = index
                
                searchIngredients()
            }
            //If we are editing (ie. keyboard is visible) just update the pageControl (don't want them searching until the keyboard is gone)
            else if (scrollView.contentOffset.x == scrollView.frame.size.width * CGFloat(index)) && ingredientField.editing {
                
                pageControl.currentPage = index
                
            }
            
        } //end for
        
        
    }
    
    
    
    
    
    

} //end ViewController class

