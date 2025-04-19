#!/usr/bin/env swift

import Foundation

// MARK: - Setup Directories
let fileManager = FileManager.default
let articlesDir = URL(fileURLWithPath: "articles", isDirectory: true)
let tagsDir = URL(fileURLWithPath: "tags", isDirectory: true)

// Ensure tags directory exists
try? fileManager.createDirectory(at: tagsDir, withIntermediateDirectories: true)

// MARK: - Date Formatters
let inputFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "yyyyMMdd"
    df.locale = Locale(identifier: "en_US_POSIX")
    return df
}()

func formattedDate(_ date: Date) -> String {
    let calendar = Calendar.current
    let day = calendar.component(.day, from: date)
    let month = calendar.component(.month, from: date)
    let year = calendar.component(.year, from: date)
    let monthName = DateFormatter().monthSymbols[month - 1]
    // Ordinal suffix
    let suffix: String
    switch day {
    case 11, 12, 13: suffix = "th"
    default:
        switch day % 10 {
        case 1: suffix = "st"
        case 2: suffix = "nd"
        case 3: suffix = "rd"
        default: suffix = "th"
        }
    }
    return "\(monthName) \(day)\(suffix), \(year)"
}

// MARK: - Load and Parse Articles
guard let articleFiles = try? fileManager.contentsOfDirectory(at: articlesDir, includingPropertiesForKeys: nil) else {
    fatalError("Could not list articles directory")
}

struct Article {
    let date: Date
    let title: String
    let filename: String
    let url: URL
    var tags: [String]
}

var articles: [Article] = []

for fileURL in articleFiles where fileURL.pathExtension.lowercased() == "md" {
    let filename = fileURL.lastPathComponent
    let nameOnly = fileURL.deletingPathExtension().lastPathComponent
    let parts = nameOnly.split(separator: " ", maxSplits: 1)
    guard parts.count == 2,
          let date = inputFormatter.date(from: String(parts[0])) else { continue }
    let title = String(parts[1])
    let content = (try? String(contentsOf: fileURL)) ?? ""
    var extractedTags: [String] = []

    // Extract YAML front matter tags
    if content.hasPrefix("---") {
        if let endRange = content.range(of: "\n---", range: content.index(content.startIndex, offsetBy: 3)..<content.endIndex) {
            let yamlBlock = content[content.index(content.startIndex, offsetBy: 3)..<endRange.lowerBound]
            for line in yamlBlock.split(separator: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("- ") {
                    let tag = trimmed.dropFirst(2).trimmingCharacters(in: .whitespaces)
                    extractedTags.append(String(tag))
                }
            }
        }
    }
    articles.append(Article(date: date, title: title, filename: filename, url: fileURL, tags: extractedTags))
}

// Sort by date descending
let sortedArticles = articles.sorted { $0.date > $1.date }

// MARK: - Generate Root README.md (5 Recent with Previews)
var rootReadme = "# Recent Articles\n\n"
for article in sortedArticles.prefix(5) {
    let content = (try? String(contentsOf: article.url)) ?? ""
    var preview = ""
    if let start = content.range(of: "<!-- preview -->"),
       let end = content.range(of: "<!-- /preview -->", range: start.upperBound..<content.endIndex) {
        preview = String(content[start.upperBound..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    let dateLine = formattedDate(article.date)
    let encoded = article.filename.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? article.filename
    let link = "articles/\(encoded)"
    rootReadme += "## [\(article.title)](\(link))\n"
    rootReadme += "###### \(dateLine)\n\n"
    rootReadme += "\(preview)\n\n"

    let filename = article.url.lastPathComponent
    let encodedFilename = filename.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? filename
    rootReadme += "[Continue Reading](articles/\(encodedFilename))\n\n"
}

rootReadme += "##\n"
rootReadme += "[View All](articles/)"

try rootReadme.write(to: URL(fileURLWithPath: "README.md"), atomically: true, encoding: .utf8)

// MARK: - Generate articles/README.md (All Articles List)
var articlesIndex = "# All Articles\n\n"
for article in sortedArticles {
    let dateLine = formattedDate(article.date)
    let encoded = article.filename.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? article.filename
    let link = "articles/\(encoded)"
    articlesIndex += "- [\(article.title)](\(link)) \(dateLine)\n"
}
try articlesIndex.write(to: articlesDir.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)

// MARK: - Build Tag Mapping
var tagMap: [String: [Article]] = [:]
for article in sortedArticles {
    for tag in article.tags {
        tagMap[tag, default: []].append(article)
    }
}

// MARK: - Generate tags/README.md
var tagReadme = "# Tags\n\n"
for tag in tagMap.keys.sorted() {
    let count = tagMap[tag]?.count ?? 0
    let fileName = "\(tag.uppercased()).md"
    let encodedFile = fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? fileName
    tagReadme += "- [\(tag)](\(encodedFile)) \(count)\n"
}
try tagReadme.write(to: tagsDir.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)

// MARK: - Generate individual Tag files
for (tag, articles) in tagMap {
    let fileName = "\(tag.uppercased()).md"
    let tagFileURL = tagsDir.appendingPathComponent(fileName)
    var contents = "# Articles tagged ‘\(tag)’\n\n"
    for article in articles {
        let encoded = article.filename.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? article.filename
        let link = "../articles/\(encoded)"
        contents += "- [\(article.title)](\(link))\n"
    }
    try contents.write(to: tagFileURL, atomically: true, encoding: .utf8)
}

print("Generated README.md, articles/README.md, and tags index/files.")
