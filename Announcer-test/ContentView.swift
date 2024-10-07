//
//  ContentView.swift
//  Announcer-test
//
//  Created by Lee Jun Lei Adam on 6/10/24.
//

import SwiftUI

struct ContentView: View {
    @State private var articles: [AtomArticle] = []
    @State private var errorMessage: AlertMessage?
    @State private var selectedTags: Set<String> = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var selectedArticleID: String?
    @State private var currentTask: Task<Void, Never>?
    @State private var availableTags: [String] = []

    var selectedArticle: AtomArticle? {
        articles.first(where: { $0.id == selectedArticleID })
    }

    private var filteredArticles: [AtomArticle] {
        let tagFiltered = selectedTags.isEmpty ? articles : articles.filter { !Set($0.categories).isDisjoint(with: selectedTags) }
        
        return searchText.isEmpty ? tagFiltered : tagFiltered.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.author?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            $0.categories.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationSplitView {
            filterView
        } content: {
            articleListView
        } detail: {
            detailView
        }
        .navigationTitle("Announcer")
        .alert(item: $errorMessage) { errorMessage in
            Alert(
                title: Text("Error"),
                message: Text(errorMessage.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            loadArticles()
            NotificationCenter.default.addObserver(forName: .clearAllFilters, object: nil, queue: .main) { _ in
                DispatchQueue.main.async {
                    clearAllFilters()
                }
            }
            NotificationCenter.default.addObserver(forName: NSMenu.didChangeItemNotification, object: nil, queue: .main) { _ in
                DispatchQueue.main.async {
                    ensureSidebarVisible()
                }
            }
        }
    }
    // MARK: - Views
    
    private var filterView: some View {
        List {
            Section("Filters") {
                DisclosureGroup("Categories (\(selectedTags.count))") {
                    ForEach(availableTags, id: \.self) { tag in
                        TagToggleRow(tag: tag, isSelected: selectedTags.contains(tag)) {
                            toggleTagSelection(tag)
                        }
                    }
                    
                    if !selectedTags.isEmpty {
                        Button("Clear All") {
                            selectedTags.removeAll()
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Filters")
        .navigationSubtitle("\(filteredArticles.count) articles")
        .toolbar {
            ToolbarItem {
                Button {
                    NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
                } label: {
                    Image(systemName: "sidebar.left")
                }
            }
        }
    }
    
    private var articleListView: some View {
        List(filteredArticles, selection: $selectedArticleID) { article in
            ArticleRowView(article: article)
                .tag(article.id)
        }
        .frame(minWidth: 300)
        .searchable(text: $searchText)
        .toolbar {
            ToolbarItem {
                Button(action: {
                    Task {
                        await fetchAtomFeed()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
                .help("Refresh articles")
            }
        }
    }
    
    private var detailView: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let article = selectedArticle {
                DetailView(article: article)
                    .id(article.id)
            } else {
                Text("Select an article")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadArticles() {
        Task {
            if let cachedArticles = loadCachedArticles() {
                updateArticlesAndTags(with: cachedArticles)
            } else {
                await fetchAtomFeed()
            }
        }
    }
    
    private func toggleTagSelection(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    private func clearAllFilters() {
        selectedTags.removeAll()
        searchText = ""
    }
    
    private func fetchAtomFeed() async {
        currentTask?.cancel()
        
        currentTask = Task {
            isLoading = true
            defer { isLoading = false }
            
            guard let url = URL(string: "http://studentsblog.sst.edu.sg/feeds/posts/default") else {
                errorMessage = AlertMessage(message: "Invalid URL")
                return
            }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                if Task.isCancelled { return }
                
                let parser = AtomParser(data: data)
                if let parsedArticles = parser.parse() {
                    if !Task.isCancelled {
                        await MainActor.run {
                            updateArticlesAndTags(with: parsedArticles)
                            cacheArticles(parsedArticles)
                        }
                    }
                } else if !Task.isCancelled {
                    await MainActor.run {
                        self.errorMessage = AlertMessage(message: "Error parsing feed")
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.errorMessage = AlertMessage(message: "Error fetching feed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func updateArticlesAndTags(with newArticles: [AtomArticle]) {
        self.articles = newArticles
        self.availableTags = Array(Set(newArticles.flatMap { $0.categories })).sorted()
    }
    
    private func cacheArticles(_ articles: [AtomArticle]) {
        if let data = try? JSONEncoder().encode(articles) {
            UserDefaults.standard.set(data, forKey: "cachedArticles")
        }
    }

    private func loadCachedArticles() -> [AtomArticle]? {
        if let data = UserDefaults.standard.data(forKey: "cachedArticles"),
           let articles = try? JSONDecoder().decode([AtomArticle].self, from: data) {
            return articles
        }
        return nil
    }
    
    private func ensureSidebarVisible() {
        if let splitViewController = NSApp.keyWindow?.contentViewController as? NSSplitViewController {
            splitViewController.splitViewItems.forEach { item in
                if !item.isCollapsed {
                    item.isCollapsed = false
                }
            }
        }
    }
}

// MARK: - Other Supporting Structures

struct AlertMessage: Identifiable {
    let id = UUID()
    let message: String
}

struct TagToggleRow: View {
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

extension Notification.Name {
    static let clearAllFilters = Notification.Name("clearAllFilters")
}

#Preview {
    ContentView()
}
