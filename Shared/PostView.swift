//
//  PostView.swift
//  MyApp
//
//  Created by Venti on 28/05/2022.
//

import Foundation
import SwiftUI
import SwiftyJSON

class MinimalDataList: ObservableObject{
    @Published var Data = [MinimalRedditData]()
    @Published var subredditName: String
    @Published var lastPost: String?
    
    init() {
        self.subredditName = "WholesomeYuri"
        self.lastPost = nil
        update(subreddit: subredditName, willRemoveAll: true)
    }
    
    func update(subreddit: String, willRemoveAll: Bool = false, offset: String? = nil){
        subredditName = subreddit
        if willRemoveAll
        {
            Data.removeAll()
            self.lastPost = nil
        }
        var url = "https://www.reddit.com/r/" + subredditName + ".json"
        if offset != nil {
            url += "?after=" + offset!
        }
        guard let source = URL(string: url) else {print("Error"); return;}
        let urlSession = URLSession(configuration: .default)
        urlSession.dataTask(with: source, completionHandler: {(redditData, response, err) in
            if err != nil {
                print((err?.localizedDescription)!)
                return
            }
            //print(response!)
            if redditData != nil {
                let data = JSON(redditData as Any)
                // print(data)
                for child in data["data"]["children"]
                {
                    let post = child.1["data"]
                    
                    DispatchQueue.main.async {
                        self.lastPost = post["name"].stringValue
                    }
                    
                    //print("Adding post \(post["name"])")
                    
                    if (post["is_gallery"].boolValue) {
                        let firstImageFormat = post["media_metadata"].first!.1["m"].stringValue.split(separator: "/").last ?? "png"
                        let firstImageURL = "https://i.redd.it/" + post["media_metadata"].first!.1["id"].stringValue + "." + firstImageFormat
                        let galleryCount = post["gallery_data"]["items"].count
                        DispatchQueue.main.async {
                            self.Data.append(MinimalRedditData(postName: post["title"].stringValue, postThumbnailUrl: firstImageURL, postUrl: ("https://reddit.com" + post["permalink"].stringValue), postUps: post["ups"].intValue, postDowns: post["downs"].intValue, isGallery: true, galleryCount: galleryCount))
                        }
                    }
                    else {
                    let postUrl = post["url"].stringValue
                    if (!postUrl.hasSuffix("jpg") || !postUrl.hasSuffix("png")){continue;}
                    if (post["over_18"].boolValue) {continue;}
                    DispatchQueue.main.async {
                        self.Data.append(MinimalRedditData(postName: post["title"].stringValue, postThumbnailUrl: post["url"].stringValue, postUrl: ("https://reddit.com" + post["permalink"].stringValue), postUps: post["ups"].intValue, postDowns: post["downs"].intValue))
                    }
                    }
                }
            }
        }).resume()
    }
}

class MinimalRedditData: Identifiable, Equatable
{
    static func == (lhs: MinimalRedditData, rhs: MinimalRedditData) -> Bool {
        return lhs.id == rhs.id &&
        lhs.postName == rhs.postName &&
        lhs.postUrl == lhs.postUrl
    }
    
    var id = UUID();
    var postName: String;
    var postThumbnailUrl: URL;
    var postUrl: URL;
    var postUps: Int;
    var postDowns: Int;
    var isGallery: Bool
    var galleryCount: Int;

    init(postName: String, postThumbnailUrl:String, postUrl:String, postUps: Int, postDowns: Int, isGallery: Bool = false, galleryCount: Int = 1) {
        self.postName = postName
        self.postThumbnailUrl = URL(string: postThumbnailUrl)!
        self.postUrl = URL(string: postUrl) ?? URL(string: postThumbnailUrl)!
        self.postUps = postUps
        self.postDowns = postDowns
        self.isGallery = isGallery
        self.galleryCount = galleryCount
    }
}

struct RedditPostView: View, Identifiable {
    let id = UUID()
    
    @Environment(\.openURL) private var openURL
    @State var postData: MinimalRedditData
    
    var body: some View {
        HStack{
            AsyncImage (url: postData.postThumbnailUrl){ image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: 200, alignment: .leading)
            } placeholder: {
                Color.gray
            }
            VStack{
                Text(postData.postName)
                    .font(.body)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                //Text(postData.postUrl.absoluteString)
                //    .foregroundColor(Color.gray)
                HStack {
                    Text("Ups: \(postData.postUps)")
                    Text("|")
                    Text("Downs: \(postData.postDowns)")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(postData.isGallery ? "Gallery: \(postData.galleryCount) images" : "")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            openURL(postData.postUrl)
        }
    }
    
}
