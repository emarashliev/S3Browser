//
//  LinearGradient+appColor.swift
//  S3Browser
//
//  Created by Emil Marashliev on 5.10.24.
//

import SwiftUICore

extension LinearGradient {
    static var appColor: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.pink, .purple]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
