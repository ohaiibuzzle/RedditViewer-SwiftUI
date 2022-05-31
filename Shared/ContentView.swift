//
//  ContentView.swift
//  Shared
//
//  Created by Venti on 28/05/2022.
//

import SwiftUI

struct ContentView: View {
    @State private var subredditName: String
    @ObservedObject var postList: MinimalDataList
    
    init() {
        self.subredditName = "WholesomeYuri"
        self.postList = MinimalDataList()
    }
    
    var body: some View {
        ScrollView{
            LazyVStack{
                ForEach(postList.Data, id: \.id, content: {(postData) in
                    RedditPostView(postData: postData)
                        .onAppear{
                            if postData == postList.Data.last{
                                postList.update(subreddit: subredditName, offset: postList.lastPost)
                            }
                        }
                })
            }
        }
        HStack{
        TextField("Subreddit", text: $subredditName)
            .disableAutocorrection(true)
            .onSubmit {
                postList.update(subreddit: subredditName, willRemoveAll: true)
            }
            Button(){
                postList.update(subreddit: subredditName, willRemoveAll: true)
            } label: {
                Text("Refresh")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
