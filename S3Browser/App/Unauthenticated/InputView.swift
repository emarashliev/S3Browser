//
//  InputView.swift
//  S3Browser
//
//  Created by Emil Marashliev on 29.09.24.
//

import SwiftUI

struct InputView: View {
    enum InputType {
        case secure
        case nonSecure
    }
    
    @Environment(\.colorScheme) var colorScheme

    @Binding var data: String
    var title: String
    let type: InputType

    var body: some View {
        ZStack {
            if type == .nonSecure {
                TextField("", text: $data)
                    .padding(.horizontal, 10)
                    .frame(height: 42)
                    .overlay(
                        RoundedRectangle(cornerSize: CGSize(width: 4, height: 4))
                            .stroke(Color.gray, lineWidth: 1)
                    )
            } else {
                SecureField("", text: $data)
                    .padding(.horizontal, 10)
                    .frame(height: 42)
                    .overlay(
                        RoundedRectangle(cornerSize: CGSize(width: 4, height: 4))
                            .stroke(Color.gray, lineWidth: 1)
                    )
            }

            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.thin)
                    .foregroundColor(Color.gray)
                    .multilineTextAlignment(.leading)
                    .padding(4)
                    .background(colorScheme == .dark ? .black : .white)
                Spacer()
            }
            .padding(.leading, 8)
            .offset(CGSize(width: 0, height: -20))
        }
        .padding(4)
    }
}

#Preview {
    @Previewable @State var data = ""
    InputView(data: $data, title: "Title", type: .nonSecure)
}
