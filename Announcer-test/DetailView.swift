//
//  DetailView.swift
//  Announcer-test
//
//  Created by Lee Jun Lei Adam on 6/10/24.
//

import SwiftUI

struct DetailView: View {
    let article: AtomArticle
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(article.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                if let author = article.author {
                    Text("By: \(author)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                if !article.categories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(article.categories, id: \.self) { category in
                                Text(category)
                                    .font(.system(size: 14))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(8)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                
                Divider()
                
                if let attributedString = formatHTML(article.content) {
                    Text(attributedString)
                        .foregroundColor(.primary)
                } else {
                    Text("Failed to load content")
                        .foregroundColor(.red)
                }
            }
            .padding()
        }
    }
    
    private func formatHTML(_ html: String) -> AttributedString? {
        guard let data = html
            .replacingOccurrences(of: "background-color: white;", with: "")
            .data(using: .utf8) else {
            return nil
        }
        
        do {
            // Create an NSAttributedString with the HTML content
            let attributedString = try NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )
            
            // Convert to AttributedString
            let finalString = AttributedString(attributedString)
            
            // Create a new AttributedString for storing the result
            var result = AttributedString()
            
            // Iterate through runs and apply formatting while preserving bold and links
            for run in finalString.runs {
                var runString = AttributedString(finalString[run.range])
                
                // Check for bold text using inlineContentType
                if run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true {
                    runString.font = .system(size: 16, weight: .bold)
                } else {
                    runString.font = .system(size: 16)
                }
                
                // Style links
                if run.link != nil {
                    runString.foregroundColor = .blue
                    runString.underlineStyle = .single
                } else {
                    runString.foregroundColor = .primary
                }
                
                result += runString
            }
            
            return result
        } catch {
            print("Error formatting HTML: \(error)")
            return nil
        }
    }
}
