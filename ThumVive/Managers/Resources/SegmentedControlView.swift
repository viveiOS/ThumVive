//
//  SegmentedControlView.swift
//  ThumVive
//
//  Created by Abraham De Leon on 10/14/21.
//

import SwiftUI

struct Segment: Identifiable {
    var id: Int
    var segmentName: String
}

struct SegmentedControlView: View {
    @Binding var selected : Int
    var segments: [Segment]

    var body: some View {
        HStack {
            ForEach(segments) { segment in
                Button(action: {
                    self.selected = segment.id
                })
                {
                    Text(segment.segmentName)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 0)
                        .font(.custom("HelveticaNeue-Medium", size: 16))
                }.foregroundColor(self.selected == segment.id ? .black : .gray)
            }
        }.padding(20)
        .clipShape(Capsule())
        .animation(.default)
    }
}

struct SegmentedControlView_Previews: PreviewProvider {
    static var previews: some View {
        SegmentedControlView(selected: .constant(0), segments: [Segment(id: 0, segmentName: "Popular"), Segment(id: 1, segmentName: "New"), Segment(id: 2, segmentName: "Follow")])
    }
}
