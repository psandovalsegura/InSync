//
//  Album.swift
//  InSync
//
//  Created by Pedro Sandoval Segura on 7/18/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import Foundation

class Album: NSObject {
    
    //Fields
    var id: String?
    var albumImageUrl: String?
    var name: String?
    var uri: String?
    
    
    init(dictionary: NSDictionary) {
        self.id = dictionary["id"] as? String
        
        let albumImageDictionary = dictionary["images"] as? [NSDictionary]
        self.albumImageUrl = albumImageDictionary![0]["url"] as? String
        
        self.name = dictionary["name"] as? String
        self.uri = dictionary["uri"] as? String
        
    }
    
    
    
}