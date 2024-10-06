//
//  FilterView.swift
//  Announcer-test
//
//  Created by Lee Jun Lei Adam on 6/10/24.
//

import SwiftUI

struct FilterView: View {
    let tags: [String]
    @Binding var selectedTags: Set<String>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            HStack {
                Button("Clear") {
                    selectedTags.removeAll()
                }
                Spacer()
                Text("Select Tags")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding()
            
            List(tags, id: \.self) { tag in
                MultipleSelectionRow(tag: tag, isSelected: selectedTags.contains(tag)) {
                    if selectedTags.contains(tag) {
                        selectedTags.remove(tag)
                    } else {
                        selectedTags.insert(tag)
                    }
                }
            }
        }
        .frame(minWidth: 300, minHeight: 400)
    }
}
