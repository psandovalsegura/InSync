//
//  TrackAdder.swift
//  InSync
//
//  Created by Pedro Sandoval Segura on 7/20/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import Foundation
import UIKit

class TrackAdder {
    
    static var selectedTracks  = [Track]()
    static var hostInitialSelection = true
    
    //Adds a track to the selected tracks array
    class func addPossibleChoiceTrack(track: Track) {
        selectedTracks.append(track)
    }
    
    //Removes the track from selected tracks array
    class func removePossibleChoiceTrack(track: Track) {
        TrackAdder.selectedTracks  = TrackAdder.selectedTracks.filter() { $0.id! != track.id! }
    }
    
    //Function returns a boolean value representing whether the track has been selected before
    class func wasSelected(track: Track) -> Bool {
        for selectedTrack in TrackAdder.selectedTracks {
            if selectedTrack.id! == track.id! {
                return true
            }
        }
        return false
    }
    
    
    //Clears the selected tracks so new tracks can be successfully selected
    class func clearSelectedTracks() {
        TrackAdder.selectedTracks.removeAll()
    }
    
}
