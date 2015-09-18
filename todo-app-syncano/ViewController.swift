//
//  ViewController.swift
//  todo-app-syncano
//
//  Created by Mariusz Wisniewski on 8/13/15.
//  Copyright (c) 2015 Mariusz Wisniewski. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var todoItems = [Todo]()
    let syncano = Syncano.sharedInstanceWithApiKey(kSyncanoApiKey, instanceName: kSyncanoInstanceName)
    lazy var channel : SCChannel = SCChannel(name: kSyncanoChannelName, andDelegate: self)
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.setupUI()
        self.downloadTodoItemsFromSyncano()
        self.channel.subscribeToChannel()
    }
    
    func setupUI() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "plusButtonPressed")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "refreshButtonPressed")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startLoadingAnimation() {
        self.navigationItem.startAnimatingAt(.Center);
    }
    
    func stopLoadingAnimation() {
        self.navigationItem.stopAnimating()
    }
    
    func reloadTableView() {
        self.tableView.reloadData()
    }
    
    func reloadRowAtIndex(index: Int) {
        self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Automatic)
    }
    
    func insertRowAtIndex(index: Int) {
        self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Automatic)
    }
    
    func deleteRowAtIndex(index: Int) {
        self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Automatic)
    }
    
    func showAlertController(title: String, okActionTitle: String, cancelActionTitle: String, todoItem: Todo, finalAction: () -> () ) {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: okActionTitle, style: .Default) { _ in
            let titleTextField = alertController.textFields![0] as! UITextField
            // isCompleted should be always false for new items
            todoItem.title = titleTextField.text
            self.saveTodoItemToSyncano(todoItem)
            finalAction()
        }
        okAction.enabled = false
        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .Cancel) { _ in
        }
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Add Todo Item TextField Title Placeholder".localized()
            textField.text = todoItem.title
            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue()) { (notification) in
                okAction.enabled = textField.text != ""
            }
        }
        self.presentViewController(alertController, animated: true, completion: nil);
    }
    
    func plusButtonPressed() {
        let todo = Todo()
        todo.isCompleted = false
        todo.channel = kSyncanoChannelName
        todo.other_permissions = .Full
        self.showAlertController("Add Todo Item".localized(), okActionTitle: "Add Todo Item Confirm Button Title".localized(), cancelActionTitle: "Add Todo Item Cancel Button Title".localized(), todoItem: todo) {}
    }
    
    func refreshButtonPressed() {
        self.downloadTodoItemsFromSyncano()
    }
    
    func downloadTodoItemsFromSyncano() {
        self.startLoadingAnimation()
        self.todoItems.removeAll(keepCapacity: true)
        Todo.please().giveMeDataObjectsWithCompletion { items, error in
            if let todoItems = items as? [Todo] {
                self.todoItems += todoItems
            }
            self.reloadTableView()
            self.stopLoadingAnimation()
        }
    }
    
    func deleteTodoItemFromSyncano(todo: Todo) {
        self.startLoadingAnimation()
        todo.deleteWithCompletion { error in
            //handle error
            self.stopLoadingAnimation()
        }
    }
    
    func saveTodoItemToSyncano(todo: Todo) {
        self.startLoadingAnimation()
        todo.saveWithCompletionBlock { error in
            //handle error
            self.stopLoadingAnimation()
        }
    }
    
    func reverseTodoItemCompletedStateAtSyncano(todo: Todo) {
        todo.isCompleted = !todo.isCompleted
        self.startLoadingAnimation()
        todo.saveWithCompletionBlock { error in
            //error handling
            self.stopLoadingAnimation()
        }
    }
    
    func deleteTodoItemAtIndex(index: Int) {
        let todo = self.todoItems[index]
        self.todoItems.removeAtIndex(index)
        self.deleteRowAtIndex(index)
        self.deleteTodoItemFromSyncano(todo)
    }
    
    func editTodoItemAtIndex(index: Int) {
        let todo = self.todoItems[index]
        self.showAlertController("Edit Todo Item".localized(), okActionTitle: "Edit Todo Item Confirm Button Title".localized(), cancelActionTitle: "Edit Todo Item Cancel Button Title".localized(), todoItem: todo) {
            self.reloadRowAtIndex(index)
        }
    }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.todoItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "todoAppCellIdentifier"
        
        var cell: MGSwipeTableCell? = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as? MGSwipeTableCell
        if (cell == nil) {
            cell = MGSwipeTableCell(style: .Default, reuseIdentifier: cellIdentifier)
            cell?.rightButtons = [
                MGSwipeButton(title: "Delete Todo Item Action Button Title".localized(), backgroundColor: UIColor.redColor(), callback: { cell -> Bool in
                    let indexPath = tableView.indexPathForCell(cell)
                    if let row = indexPath?.row {
                        self.deleteTodoItemAtIndex(row)
                    }
                    return true
                }),
                MGSwipeButton(title: "Edit Todo Item Action Button Title".localized(), backgroundColor: UIColor.lightGrayColor(), callback: { cell -> Bool in
                    let indexPath = tableView.indexPathForCell(cell)
                    if let row = indexPath?.row {
                        self.editTodoItemAtIndex(row)
                    }
                    return true
                })
            ]
            cell?.selectionStyle = .None
        }
        
        let todo = self.todoItems[indexPath.row]
        
        cell?.textLabel?.text = todo.title
        if (todo.isCompleted) {
            cell?.accessoryType = .Checkmark
        } else {
            cell?.accessoryType = .None
        }
        
        return cell!
    }
}

// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let todo = self.todoItems[indexPath.row]
        self.reverseTodoItemCompletedStateAtSyncano(todo)
        self.reloadRowAtIndex(indexPath.row)
    }
}

// MARK: - SCChannelDelegate
extension ViewController : SCChannelDelegate {
    func getObjectIdFromMessage(message: SCChannelNotificationMessage) -> Int {
        let objectId : Int = message.payload[kSyncanoMessagePayloadIdKey] as! Int
        return objectId
    }
    
    func findTodoObjectWithIdInArray(objectId: Int) -> Todo? {
        let filterredArray = self.todoItems.filter { $0.objectId == objectId }
        return filterredArray.first
    }
    
    func findArrayIndexOfTodoItem(todo: Todo?) -> Int? {
        if let todoItem = todo {
            return find(self.todoItems, todoItem)
        }
        return nil
    }
    
    func findArrayIndexOfTodoObjectWithId(objectId: Int) -> Int? {
        let todo = self.findTodoObjectWithIdInArray(objectId)
        return self.findArrayIndexOfTodoItem(todo)
    }
    
    func addItemFromMessage(message: SCChannelNotificationMessage) {
        let todo = Todo.fromDictionary(message.payload)
        self.todoItems += [todo]
        self.insertRowAtIndex(self.todoItems.count - 1)
    }
    
    func deleteItemFromMessage(message: SCChannelNotificationMessage) {
        let objectId = self.getObjectIdFromMessage(message)
        let index = self.findArrayIndexOfTodoObjectWithId(objectId)
        if let notNilIndex = index {
            self.todoItems.removeAtIndex(notNilIndex)
            self.deleteRowAtIndex(notNilIndex)
        }
    }
    
    func updateItemFromMessage(message: SCChannelNotificationMessage) {
        let objectId = self.getObjectIdFromMessage(message)
        let todo = self.findTodoObjectWithIdInArray(objectId)
        if let title = message.payload[kSyncanoMessagePayloadTitleKey] as? String {
            todo?.title = title
        }
        if let completed = message.payload[kAPIisCompletedKey] as? Bool {
            todo?.isCompleted = completed
        }
        if let index = self.findArrayIndexOfTodoItem(todo) {
            self.reloadRowAtIndex(index)
        }
    }
    
    func chanellDidReceivedNotificationMessage(notificationMessage: SCChannelNotificationMessage!) {
        switch(notificationMessage.action) {
        case .Create:
            self.addItemFromMessage(notificationMessage)
        case .Delete:
            self.deleteItemFromMessage(notificationMessage)
        case .Update:
            self.updateItemFromMessage(notificationMessage)
        default:
            break
        }
    }
}