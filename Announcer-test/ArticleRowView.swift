//
//  ArticleRowView.swift
//  Announcer-test
//
//  Created by Lee Jun Lei Adam on 6/10/24.
//

import SwiftUI

struct ArticleRowView: View {
    let article: AtomArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        if let author = article.author {
                            Label(author, systemImage: "person")
                        }
                        
                        Label(formatDate(article.published), systemImage: "calendar")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Use SF Symbols that match macOS style
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !article.categories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(article.categories, id: \.self) { category in
                            CategoryTag(text: category)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle()) // Makes the entire row clickable
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = dateFormatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        displayFormatter.doesRelativeDateFormatting = true
        
        return displayFormatter.string(from: date)
    }
}

struct CategoryTag: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.1))
            .foregroundColor(.accentColor)
            .cornerRadius(6)
    }
}

// Preview
#Preview {
    List {
        ArticleRowView(article: AtomArticle(
            id: "1",
            title: "Sample Article with a Very Long Title That Might Wrap to Multiple Lines",
            link: "https://example.com",
            content: "Sample content",
            published: "2024-03-15T10:30:00Z",
            author: "John Doe",
            categories: ["Technology", "Education", "Programming", "SwiftUI"]
        ))
        
        ArticleRowView(article: AtomArticle(
            id: "2",
            title: "Another Sample Article",
            link: "https://example.com",
            content: "Sample content",
            published: "2024-03-14T15:45:00Z",
            author: nil,
            categories: ["News"]
        ))
    }
    .frame(width: 400)
}
