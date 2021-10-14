//
//  ContentView.swift
//  ThumVive
//
//  Created by Abraham De Leon on 10/10/21.
//

import SwiftUI


struct ContentView: View {
    @State var optionSelected = 0

    var body: some View {
        
        VStack {
            if self.optionSelected == 0 {
                PostTableView()
            } else {
                ProfileView()
            }
            // Your View.....
            Spacer()
            TabBarView(optionSelected: self.$optionSelected)
            
        }.background(Color(.clear).edgesIgnoringSafeArea(.top))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
