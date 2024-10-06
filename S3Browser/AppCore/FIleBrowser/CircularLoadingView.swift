//
//  CircularLoadingView.swift
//  S3Browser
//
//  Created by Emil Marashliev on 5.10.24.
//

import SwiftUI

struct CircularLoadingView: View {
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.lightGray), lineWidth: 2)
            Circle()
                .trim(from: 0, to: 0.2)
                .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(Angle(degrees: isLoading ? 360 : 0))
                .animation(
                    Animation.linear(duration: 1).repeatForever(autoreverses: false),
                    value: self.isLoading
                )
                .onAppear() {
                    self.isLoading = true
                }
        }
    }
}

#Preview {
    CircularLoadingView().frame(width: 44, height: 44)
}
