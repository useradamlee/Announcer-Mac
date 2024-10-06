//
//  AtomParser.swift
//  Announcer-test
//
//  Created by Lee Jun Lei Adam on 6/10/24.
//

import Foundation

struct AtomArticle: Identifiable, Codable {
    let id: String
    let title: String
    let link: String
    let content: String
    let published: String
    let author: String?
    let categories: [String]
}

class AtomParser: NSObject, XMLParserDelegate {
    private var articles: [AtomArticle] = []
    private var currentElement = ""
    private var currentId = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentContent = ""
    private var currentPublished = ""
    private var currentAuthor: String?
    private var currentCategories: [String] = []
    private var parsingAuthor = false

    private var foundCharacters = ""

    private let parser: XMLParser

    init(data: Data) {
        self.parser = XMLParser(data: data)
        super.init()
        self.parser.delegate = self
    }

    func parse() -> [AtomArticle]? {
        if parser.parse() {
            return articles
        }
        return nil
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName

        if elementName == "entry" {
            currentId = ""
            currentTitle = ""
            currentLink = ""
            currentContent = ""
            currentPublished = ""
            currentAuthor = nil
            currentCategories = []
        } else if elementName == "link", let rel = attributeDict["rel"], rel == "alternate" {
            currentLink = attributeDict["href"] ?? ""
        } else if elementName == "category", let term = attributeDict["term"] {
            currentCategories.append(term)
        } else if elementName == "author" {
            parsingAuthor = true
        }

        foundCharacters = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        foundCharacters += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let content = foundCharacters.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "id":
            currentId = content
        case "title":
            currentTitle = content
        case "content":
            currentContent = content
        case "published":
            currentPublished = content
        case "name" where parsingAuthor:
            currentAuthor = content
        case "author":
            parsingAuthor = false
        case "entry":
            let article = AtomArticle(
                id: currentId,
                title: currentTitle,
                link: currentLink,
                content: currentContent,
                published: currentPublished,
                author: currentAuthor,
                categories: currentCategories
            )
            articles.append(article)
        default:
            break
        }
    }
}
