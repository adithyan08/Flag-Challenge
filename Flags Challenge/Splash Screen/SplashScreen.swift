//
//  SplashScreen.swift
//  Flags Challenge
//
//  Created by adithyan na on 6/8/25.
//

import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    let splashDuration: TimeInterval = 2.0
    @State private var logoScale: CGFloat = 0.3

    var body: some View {
        Group {
            if isActive {
                ContentView(context: PersistenceController.shared.container.viewContext)
                    .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
                    .preferredColorScheme(.light)
            } else {
                VStack(spacing: 20) {
                    
                    Text("Flags Challenge")
                                            .font(.largeTitle)
                                            .bold()
                                            .foregroundColor(Color.brandOrange)
                                            .scaleEffect(logoScale)
                        .onAppear {
                            withAnimation(.spring(response: 0.7, dampingFraction: 0.55)) {
                                logoScale = 1.0
                            }
                        }
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.brandOrange))
                        .scaleEffect(1.5)
                        .padding()

                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .ignoresSafeArea()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + splashDuration) {
                withAnimation {
                    isActive = true
                }
            }
        }
    }
}


