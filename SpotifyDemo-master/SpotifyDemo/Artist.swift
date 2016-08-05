//
//  Artist.swift
//  InSync
//
//  Created by Pedro Sandoval Segura on 7/11/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import Foundation

class Artist: NSObject {
    
    //Fields
    var id: String?
    var name: String?
    var uri: String?
    var popularity: Int?
    var profileImageUrl: String?
    
    init(dictionary: NSDictionary) {
        self.id = dictionary["id"] as? String
        self.name = dictionary["name"] as? String
        self.uri = dictionary["uri"] as? String
        self.popularity = dictionary["popularity"] as? Int
        
        if let imagesDictionary = dictionary["images"] as? [NSDictionary] {
            //Artist dictionaries within track objects do not contain images dictionaries
            //Artist dictionaries returned from a search query DO contain images dictionaries
            if !imagesDictionary.isEmpty {
                //Some artist dictionaries have empty arrays of images, so we must check against it
                self.profileImageUrl = imagesDictionary[0]["url"] as? String
            }
        }
    }
}