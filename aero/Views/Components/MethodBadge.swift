//
//  MethodBadge.swift
//  aero
//
//  Small colored pill showing an HTTP method.
//

import SwiftUI

struct MethodBadge: View {
    let method: HTTPMethod

    var body: some View {
        Text(method.rawValue)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(method.color)
            .frame(minWidth: 44)
    }
}

#Preview {
    VStack(alignment: .leading) {
        ForEach(HTTPMethod.allCases) { MethodBadge(method: $0) }
    }
    .padding()
}
