//
//  FoodsTableViewController.swift
//  AllergeezDataInput
//
//  Created by Ryan Hoffmann on 10/13/14.
//  Copyright (c) 2014 Mumush. All rights reserved.
//

import UIKit
import CoreData

class FoodsTableViewController: UITableViewController, UITableViewDataSource {
    
    var foodsList : Array<AnyObject> = []
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        
        let appDel:AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let context:NSManagedObjectContext = appDel.managedObjectContext!
        
        let fetchRequest = NSFetchRequest(entityName: "Foods")
        
        foodsList = context.executeFetchRequest(fetchRequest, error: nil)!
        println("Food List: \(foodsList)")
        
        tableView.reloadData()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return foodsList.count
    }
    
    

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell
        
        var data:NSManagedObject = foodsList[indexPath.row] as NSManagedObject
        
        cell.textLabel?.text = data.valueForKeyPath("name") as? String
        
        var isGlutenFree:Bool = data.valueForKeyPath("isGlutenFree") as Bool
        var isDairyFree:Bool = data.valueForKeyPath("isDairyFree") as Bool
        var isSoyFree:Bool = data.valueForKeyPath("isSoyFree") as Bool

        cell.detailTextLabel?.text = "Gluten Free: \(isGlutenFree), Dairy Free: \(isDairyFree), Soy Free: \(isSoyFree)"
        
        return cell
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        let appDel:AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let context:NSManagedObjectContext = appDel.managedObjectContext!
        
        if editingStyle == UITableViewCellEditingStyle.Delete {
            
            context.deleteObject(foodsList[indexPath.row] as NSManagedObject)
            
            //println("Deleting: \(foodsList[indexPath.row])")
            
            foodsList.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            
            //println("Food Deleted")
            
        }
        
        var error:NSError? = nil
        if !context.save(&error) {
            
            abort()
            
        }
        
        
    }
    
    
}
