//
//  CustomButton.swift
//  ThumVive
//
//  Created by Abraham De Leon on 10/14/21.
//

import SwiftUI

struct CustomButton: View {

@State private var didTap:Bool = false

  var body: some View {
    Button(action: {
        self.didTap = true
    }) {
        Image(didTap ? "Heart_Liked" : "Heart").foregroundColor(didTap ? Color("PinkColor") : Color("DarkGrayColor"))
    }
  }
}

struct CustomButton_Previews: PreviewProvider {
    static var previews: some View {
        CustomButton()
    }
}
