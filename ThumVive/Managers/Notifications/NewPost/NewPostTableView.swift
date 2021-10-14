//
//  NewPostTableView.swift
//  ThumVive
//
//  Created by Abraham De Leon on 10/14/21.
//

import SwiftUI

struct NewPostTableView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                NewPostList()
            }.background(Color(.white).edgesIgnoringSafeArea(.all))
            .navigationBarTitle("")
            .navigationBarHidden(true)
        }
    }
}

struct NewPostList : View {
    var posts: [Post] = mockedPosts
    @State var selected = 0

    var body: some View {
        List {
            ForEach(posts) { post in
                NewPostCell(post: post)
            }
        }.onAppear {
         UITableView.appearance().separatorStyle = .none
        }
    }
}

struct NewPostTableView_Previews: PreviewProvider {
    static var previews: some View {
        NewPostTableView()
    }
}
