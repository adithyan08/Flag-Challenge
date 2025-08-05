//
//  questionView.swift
//  Flags Challenge
//
//  Created by adithyan na on 5/8/25.
//

import SwiftUI

func timerString(_ seconds: Int) -> String {
     String(format: "%02d:%02d", seconds / 60, seconds % 60)
 }
 
 // MARK: - Time Input Field
 
 func timeInputField(title: String, value: Binding<Int>) -> some View {
     VStack(spacing: 6) {
         TextField("", value: value, formatter: NumberFormatter())
             .keyboardType(.numberPad)
             .frame(width: 50, height: 44)
             .background(Color(white: 0.9))
             .cornerRadius(8)
             .multilineTextAlignment(.center)
         Text(title)
             .font(.caption)
             .foregroundColor(.gray)
     }
 }

