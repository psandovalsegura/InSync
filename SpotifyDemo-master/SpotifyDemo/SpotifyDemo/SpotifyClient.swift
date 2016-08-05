//
//  SpotifyClient.swift
//  InSync
//
//  Created by Pedro Sandoval Segura on 7/8/16.
//  Copyright © FBU Team Interaction. All rights reserved.
//

import Foundation
import Alamofire

/**
 * SpotifyClient should manage Authentication and all related API calls
 */
class SpotifyClient {
    static let CLIENT_ID = "3de489abe8a0405ebe98e789e031cfba"
    static let CALLBACK_URL = "insync://returnafterlogin"
    static let TOKEN_SWAP_URL = "http://localhost:1234/swap"
    static let TOKEN_REFRESH_URL = "http://localhost:1234/refresh"
    
    static var CURRENT_SESSION = SPTSession() //Properly set up after 'loginSession' is set up after Authentication success in the ViewController class
    static var CURRENT_USER = User(dictionary: ["nil": "nil"]) //Properly set up after 'loginSession' is set up after Authentication success in the ViewController class
    
    /*
     A function that returns a user object for the current user
     
     @return (through complettion handler) a user object
     
     */
    class func getCurrentUser(completionHandler: (User) -> Void) {
        Alamofire.request(.GET, "https://api.spotify.com/v1/me", headers: ["Authorization": "Bearer \(SpotifyClient.CURRENT_SESSION.accessToken)"]).responseJSON { (response) in
            if let json = response.result.value as? NSDictionary {
                let currentUser = User(dictionary: json)
                
                completionHandler(currentUser)
            }
        }
    }
    
    /*
     A function that returns Playlist objects are returned WITHOUT the tracks field ( a convention of this method of the Spotify API )
     NOTE: The tracks field is part of the Playlist object because other API calls provide Playlist objects with full Track objects
     
     @return (through complettion handler) an array of Playlist objects
     */
    class func getCurrentUserPlaylists(completionHandler: ([Playlist]) -> Void) {
        Alamofire.request(.GET, "https://api.spotify.com/v1/users/\(SpotifyClient.CURRENT_USER.id!)/playlists", headers: ["Authorization": "Bearer \(SpotifyClient.CURRENT_SESSION.accessToken)"]).responseJSON { (response) in
            if let json = response.result.value as? NSDictionary {
                let externalDictionary = json["items"] as! [NSDictionary]
                
                var playlists = [Playlist]()
                for playlistDictionary in externalDictionary {
                    let playlist = Playlist(dictionary: playlistDictionary)
                    playlists.append(playlist)
                }
                completionHandler(playlists)
            }
        }
    }
    
    /*
     A function that returns featured Playlist objects are returned WITHOUT the tracks field ( a convention of this method of the Spotify API )
     NOTE: The tracks field is part of the Playlist object because other API calls provide Playlist objects with full Track objects
     
     @return (through complettion handler) an array of Playlist objects
     */
    class func getFeaturedPlaylists(completionHandler: ([Playlist]) -> Void) {
        Alamofire.request(.GET, "https://api.spotify.com/v1/browse/featured-playlists", headers: ["Authorization": "Bearer \(SpotifyClient.CURRENT_SESSION.accessToken)"]).responseJSON { (response) in
            if let json = response.result.value as? NSDictionary {
                let externalDictionary = json["playlists"] as! NSDictionary
                let itemsDictionary = externalDictionary["items"] as! [NSDictionary]
                
                var playlists = [Playlist]()
                for playlistDictionary in itemsDictionary {
                    let playlist = Playlist(dictionary: playlistDictionary)
                    playlists.append(playlist)
                }
                completionHandler(playlists)
            }
        }
    }
    
    
    /*
     A function that returns track objects for a given playlist object
     NOTE: The returned track objects only contain basic fields (refer to Track.swift fields for more information)
     
     @param playlist: an object containing
     
     @return (through complettion handler) an array of track objects of the given playlist
     
     */
    class func getPlaylistTracks(playlist: Playlist, completionHandler: ([Track]) -> Void) {
        Alamofire.request(.GET, "https://api.spotify.com/v1/users/\(playlist.owner!)/playlists/\(playlist.id!)/tracks", headers: ["Authorization": "Bearer \(SpotifyClient.CURRENT_SESSION.accessToken)"]).responseJSON { (response) in
            if let json = response.result.value as? NSDictionary {
                let externalTrackDictionary = json["items"] as! [NSDictionary]
                var trackDictionaries = [NSDictionary]()
                
                for external in externalTrackDictionary {
                    trackDictionaries.append(external["track"] as! NSDictionary)
                }
                
                var returnTracks: [Track] = []
                for trackDictionary in trackDictionaries {
                    returnTracks.append(Track(dictionary: trackDictionary))
                }
                completionHandler(returnTracks)
                
            }
        }
    }
    
    /*
     A function that returns Track objects that the current user has saved in "My Songs"
     NOTE: The returned Track objects only contain basic fields (refer to Track.swift fields for more information)
     
     @return (through complettion handler) an array of track objects
     
     */
    class func getCurrentUserSavedTracks(completionHandler: ([Track]) -> Void) {
        Alamofire.request(.GET, "https://api.spotify.com/v1/me/tracks", headers: ["Authorization": "Bearer \(SpotifyClient.CURRENT_SESSION.accessToken)"]).responseJSON { (response) in
            if let json = response.result.value as? NSDictionary {
                let externalTrackDictionary = json["items"] as! [NSDictionary]
                var trackDictionaries = [NSDictionary]()
                for external in externalTrackDictionary {
                    trackDictionaries.append(external["track"] as! NSDictionary)
                }
                
                var returnTracks = [Track]()
                for trackDictionary in trackDictionaries {
                    returnTracks.append(Track(dictionary: trackDictionary))
                }
                
                completionHandler(returnTracks)
            }
        }
    }
    
    
    /*
     A function that returns a track object for a given track id
     NOTE: The returned track object only contain basic fields (refer to Track.swift fields for more information)
     NOTE: the returned track's audio feature fields will be nil
     
     @param trackId: the id field of a track object
     
     @return (through complettion handler) a track object
     
     */
    class func getFullFieldTrack(trackId: String, completionHandler: (Track?) -> Void ) {
        Alamofire.request(.GET, "https://api.spotify.com/v1/tracks/\(trackId)", headers: ["Authorization": "Bearer \(SpotifyClient.CURRENT_SESSION.accessToken)"]).responseJSON { (response) in
            if let json = response.result.value as? NSDictionary {
                let track = Track(dictionary: json)
                SpotifyClient.getAudioFeatures(track, completionHandlerFeature: { (fullFieldTrack) in
                    completionHandler(fullFieldTrack)
                })
            }
        }
        
    }
    
    //Overloaded method for passing in track object
    class func getFullFieldTrack(track: Track, completionHandler: (Track?) -> Void ) {
        Alamofire.request(.GET, "https://api.spotify.com/v1/tracks/\(track.id!)", headers: ["Authorization": "Bearer \(SpotifyClient.CURRENT_SESSION.accessToken)"]).responseJSON { (response) in
            if let json = response.result.value as? NSDictionary {
                let track = Track(dictionary: json)
                SpotifyClient.getAudioFeatures(track, completionHandlerFeature: { (fullFieldTrack) in
                    completionHandler(fullFieldTrack)
                })
            }
        }
        
    }
    
    
    //A helper function for creating a detailed track object ( used in getFullFieldTrack() )
    class func getAudioFeatures(track: Track, completionHandlerFeature: (Track) -> Void) {
        Alamofire.request(.GET, "https://api.spotify.com/v1/audio-features/\(track.id!)", headers: ["Authorization": "Bearer \(SpotifyClient.CURRENT_SESSION.accessToken)"]).responseJSON { (response) in
            if let json = response.result.value as? NSDictionary {
                track.danceability = json["danceability"] as? Double
                track.acousticness = json["acousticness"] as? Double
                track.energy = json["energy"] as? Double
                track.liveliness = json["liveness"] as? Double
                track.loudness = json["loudness"] as? Double
                track.speechiness = json["speechiness"] as? Double
                track.valence = json["valence"] as? Double
                completionHandlerFeature(track)
            }
        }
    }
    
    /*
     A function that returns track objects for a given search query
     NOTE: The returned track object only contain basic fields (refer to Track.swift fields for more information)
     NOTE: the returned track's audio feature fields will be nil
     
     @param query: a string of whatever the user types into a text field
     
     @return (through complettion handler) a Track object
     
     */
    class func searchTracks(query: String, completionHandler: ([Track]) -> Void ) {
        let parameters = ["q": query, "type": "track"]
        Alamofire.request(.GET, "https://api.spotify.com/v1/search", parameters: parameters, headers: ["Authorization": "Bearer \(SpotifyClient.CURRENT_SESSION.accessToken)"]).responseJSON { (response) in
            if let json = response.result.value as? NSDictionary {
                let externalTrackDictionary = json["tracks"] as? NSDictionary
                let trackDictionaries = externalTrackDictionary!["items"] as! [NSDictionary]
                
                var returnTracks = [Track]()
                for trackDictioanry in trackDictionaries {
                    returnTracks.append(Track(dictionary: trackDictioanry))
                }
                
                completionHandler(returnTracks)
                
            } else {
                print("There was an error in Search tracks")
            }
        }
    }
    /*
     A function that returns track, playlists, artists, and album objects for a given search query
     NOTE: The returned track object only contain basic fields (refer to Track.swift fields for more information)
     NOTE: the returned track's audio feature fields will be nil
     
     TO CALL EXAMPLE:
     let query = "one dance"
     SpotifyClient.searchAll(query, completionHandler: { (resultsTuple) in
     //Results tuple contains all fields
     let firstTrack = resultsTuple.tracks[0]
     let firstAlbum = resultsTuple.albums[0]
     let firstPlaylist = resultsTuple.playlists[0]
     let firstArtist = resultsTuple.artists[0]
     
     print("Track: \(firstTrack.name!)")
     print("Album: \(firstAlbum.name!) with uri \(firstAlbum.uri!)")
     print("Artist: \(firstArtist.name!) with uri \(firstArtist.uri!)")
     print("Playlist: \(firstPlaylist.name!) with uri \(firstPlaylist.uri!)")
     })
     
     @param query: a string of whatever the user types into a text field
     
     @return (through complettion handler) a tuple of album, artist, playlist, and track objects
     
     */
    class func searchAll(query: String, completionHandler: ((tracks: [Track], playlists: [Playlist], albums: [Album], artists: [Artist])) -> Void ) {
        let parameters = ["q": query, "type": "album,artist,playlist,track"]
        Alamofire.request(.GET, "https://api.spotify.com/v1/search", parameters: parameters, headers: ["Authorization": "Bearer \(SpotifyClient.CURRENT_SESSION.accessToken)"]).responseJSON { (response) in
            if let json = response.result.value as? NSDictionary {
                
                //Attain track search results
                let externalTrackDictionary = json["tracks"] as? NSDictionary
                let trackDictionaries = externalTrackDictionary!["items"] as! [NSDictionary]
                var returnTracks = [Track]()
                for trackDictioanry in trackDictionaries {
                    returnTracks.append(Track(dictionary: trackDictioanry))
                }
                
                
                //Attain playlist results
                let externalPlaylistsDictionary = json["playlists"] as? NSDictionary
                let playlistDictionaries = externalPlaylistsDictionary!["items"] as! [NSDictionary]
                var returnPlaylists = [Playlist]()
                for playlistDictionary in playlistDictionaries {
                    returnPlaylists.append(Playlist(dictionary: playlistDictionary))
                }
                
                //Attain artist results
                let externalArtistsDictionary = json["artists"] as? NSDictionary
                let artistDictionaries = externalArtistsDictionary!["items"] as! [NSDictionary]
                var returnArtists = [Artist]()
                for artistDictionary in artistDictionaries {
                    returnArtists.append(Artist(dictionary: artistDictionary))
                }
                
                
                //Attain album search results
                let externalAlbumDictionary = json["albums"] as? NSDictionary
                let albumDictionaries = externalAlbumDictionary!["items"] as! [NSDictionary]
                var returnAlbums = [Album]()
                for albumDictionary in albumDictionaries {
                    returnAlbums.append(Album(dictionary: albumDictionary))
                }
                
                
                let searchResults = (returnTracks, returnPlaylists, returnAlbums, returnArtists)
                completionHandler(searchResults)
                
            } else {
                print("There was an error in Search tracks")
            }
        }
    }
    
    
    /*
     A function that returns track objects for a given Album object
     
     @param album: an album object
     
     @return (through complettion handler) an Artist object
     
     */
    class func getAlbumTracks(album: Album, completionHandler: ([Track]) -> Void) {
        
        Alamofire.request(.GET, "https://api.spotify.com/v1/albums/\(album.id!)/tracks", headers: ["Authorization": "Bearer \(SpotifyClient.CURRENT_SESSION.accessToken)"]).responseJSON { (response) in
            if let json = response.result.value as? NSDictionary {
                let externalTrackDictionary = json["items"] as! [NSDictionary]
                
                
                var albumTracks = [Track]()
                for trackDictionary in externalTrackDictionary {
                    albumTracks.append(Track(dictionary: trackDictionary))
                }
             
                completionHandler(albumTracks)
            }
        }
    }
    
    
    /*
     A function that returns artist objects for a given search query
     
     @param query: a string of whatever the user types into a text field
     
     @return (through complettion handler) an Artist object
     
     */
    class func searchArtists(query: String, completionHandler: ([Artist]) -> Void ) {
        let parameters = ["q": query, "type": "artist"]
        Alamofire.request(.GET, "https://api.spotify.com/v1/search", parameters: parameters, headers: ["Authorization": "Bearer \(SpotifyClient.CURRENT_SESSION.accessToken)"]).responseJSON { (response) in
            if let json = response.result.value as? NSDictionary {
                let externalTrackDictionary = json["artists"] as? NSDictionary
                let artistDictionaries = externalTrackDictionary!["items"] as! [NSDictionary]
                
                var returnArtists = [Artist]()
                for artistDictionary in artistDictionaries {
                    returnArtists.append(Artist(dictionary: artistDictionary))
                }
                
                completionHandler(returnArtists)
                
            } else {
                print("There was an error in Search tracks")
            }
        }
    }
    
    /*
     A function that returns an artist's top tracks
     NOTE: The returned track object only contain basic fields (refer to Track.swift fields for more information)
     NOTE: the returned track's audio feature fields will be nil
     
     @param query: a string of whatever the user types into a text field
     
     @return (through complettion handler) Track objects
     
     */
    
    class func getArtistTopTracks(artist: Artist, completionHandler: ([Track]) -> Void) {
        let parameters = ["country" : "US"]
        Alamofire.request(.GET, "https://api.spotify.com/v1/artists/\(artist.id!)/top-tracks", parameters: parameters, headers: ["Authorization": "Bearer \(SpotifyClient.CURRENT_SESSION.accessToken)"]).responseJSON { (response) in
            if let json = response.result.value as? NSDictionary {
                let trackDictionaries = json["tracks"] as! [NSDictionary]
                var returnTracks = [Track]()
                for trackDictionary in trackDictionaries {
                    returnTracks.append(Track(dictionary: trackDictionary))
                }
                
                completionHandler(returnTracks)
            }
        }
        
    }
    
    
    
    //Testing required
    class func getTrackFromHREF(href: String, completionHandler: (Track?) -> Void) {
        print("got track from href")
        print("")
        Alamofire.request(.GET, href,  headers: ["Authorization": "Bearer \(SpotifyClient.CURRENT_SESSION.accessToken)"]).responseJSON { (response) in
            if let json = response.result.value as? NSDictionary {
                print("json response")
                print("")
                let track = Track(dictionary: json)
                SpotifyClient.getFullFieldTrack(track, completionHandler: { (spotifyTrack) in
                    completionHandler(spotifyTrack)
                })
            }
        }
    }
    
    
    
}