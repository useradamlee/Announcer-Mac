//
//  MultipleSelectionRow.swift
//  Announcer-test
//
//  Created by Lee Jun Lei Adam on 6/10/24.
//

import SwiftUI

struct MultipleSelectionRow: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: self.action) {
            HStack {
                Text(self.tag)
                if self.isSelected {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}
