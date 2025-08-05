//
//  ReuseableImage.swift
//  Flags Challenge
//
//  Created by adithyan na on 5/8/25.
//

import Foundation
import SwiftUI

struct SafeFlagImage: View {
    let imageName: String
    
    var body: some View {
        if UIImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
        } else {
            Image(systemName: "flag.slash")
                .resizable()
                .foregroundColor(.gray)
        }
    }
}
