//
//  Todo.swift
//  todo-app-syncano
//
//  Created by Mariusz Wisniewski on 8/13/15.
//  Copyright (c) 2015 Mariusz Wisniewski. All rights reserved.
//

let kAPIisCompletedKey = "iscompleted"

class Todo: SCDataObject {
    var title = ""
    var isCompleted = false
    
    override func setNilValueForKey(key: String) {
        switch (key) {
        case "title":
            self.title = ""
        case "isCompleted":
            self.isCompleted = false
        default:
            break
        }
    }

    
    override class func extendedPropertiesMapping() -> [NSObject: AnyObject] {
        return [
            "isCompleted":kAPIisCompletedKey
        ]
    }
    
    class func fromDictionary(dictionary: AnyObject!) -> Todo {
        let todo = SCParseManager.sharedSCParseManager().parsedObjectOfClass(self.classForCoder(), fromJSONObject: dictionary) as! Todo
        return todo
    }
}
