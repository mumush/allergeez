//
//  Foods.swift
//  AllergeezDataInput
//
//  Created by Ryan Hoffmann on 10/13/14.
//  Copyright (c) 2014 Mumush. All rights reserved.
//

import Foundation
import CoreData

@objc(Foods)
class Foods: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var isGlutenFree: NSNumber
    @NSManaged var isDairyFree: NSNumber
    @NSManaged var isSoyFree: NSNumber

}
