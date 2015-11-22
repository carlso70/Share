//
//  TableViewController.swift
//  ParseStarterProject
//
//  Created by Jimmy Carlson on 11/15/15.
//  Copyright © 2015 Parse. All rights reserved.
//

import UIKit
import Parse

class TableViewController: UITableViewController {
    
    //best practice to use the userIds over username because that will not change
    var usernames = [""]
    var userids = [""]
    var isFollowing = ["":false] //dictionary is better for updating follower info because the times the updating of followers happens is not syncronous with the updating of user list so it is best to use a dictionary to keep everything in the same order

    var refresher: UIRefreshControl!
    
    func refresh() {
        
        var query = PFUser.query()
        
        query?.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
            
            if let users = objects {
                
                self.usernames.removeAll(keepCapacity: true) //clear array first to prevent the same name twice
                self.userids.removeAll(keepCapacity: true)
                self.isFollowing.removeAll(keepCapacity: true)
                
                for object in users {
                    
                    if let user = object as? PFUser {
                        
                        if user.objectId != PFUser.currentUser()?.objectId { //Prevents us from seeing our own name on list
                            
                            self.usernames.append(user.username!)
                            self.userids.append(user.objectId!)
                            
                            var query = PFQuery(className: "followers")
                            
                            query.whereKey("follower", equalTo: (PFUser.currentUser()?.objectId)!)
                            query.whereKey("following",equalTo: user.objectId!)
                            
                            query.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                                
                                if let objects = objects {
                                    
                                    if objects.count > 0 {
                                        
                                        self.isFollowing[user.objectId!] = true
                                        
                                    } else {
                                        
                                        self.isFollowing[user.objectId!] = false
                                    }
                                    
                                } else {
                                    
                                    //if object is not following you
                                    self.isFollowing[user.objectId!] = false
                                    
                                }
                                
                                if self.isFollowing.count == self.usernames.count {
                                    
                                    self.tableView.reloadData()
                                    
                                    self.refresher.endRefreshing()
                                    
                                }
                                
                            })
                            
                        }
                        
                    }
                }
            }
            
        })

        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refresher = UIRefreshControl()
        refresher.attributedTitle = NSAttributedString(string: "Pull Down to Refresh")
        refresher.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        
        self.tableView.addSubview(refresher)
        
        refresh()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return usernames.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        
        cell.textLabel?.text =  usernames[indexPath.row]
        
        let followedObjectId = userids[indexPath.row]
        
        if isFollowing[followedObjectId] == true {
            
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            
        }

        return cell
    }
    

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        
        let cell:UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        
        let followingObjectId = userids[indexPath.row]
        
        if isFollowing[followingObjectId] == false { //code to follow, checks if we are already following them
        
            isFollowing[followingObjectId] = true
            
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            
            var following = PFObject(className: "followers")
            following["following"] = userids[indexPath.row]
            following["follower"] = PFUser.currentUser()?.objectId
        
            following.saveInBackground()
            
        } else {
            
            isFollowing[followingObjectId] = false
            cell.accessoryType = UITableViewCellAccessoryType.None
            
            var query = PFQuery(className: "followers")
            
            query.whereKey("follower", equalTo: (PFUser.currentUser()?.objectId)!)
            query.whereKey("following",equalTo: userids[indexPath.row])
            
            query.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
                
                if let objects = objects {
                    
                    for object in objects {
                        
                        object.deleteInBackground()
                    }
                    
                }
                
            })
            
            
        }
    }

}
