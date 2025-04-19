#!/usr/bin/env swift

import Foundation

// Directory containing markdown articles\ 
let articlesDir = URL(fileURLWithPath: "articles", isDirectory: true)

// DateFormatter to parse filenames (yyyyMMdd)
let inputFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "yyyyMMdd"
    df.locale = Locale(identifier: "en_US_POSIX")
    return df
}()

// DateFormatter to format for README (e.g., May 15th, 2024)
func formattedDate(_ date: Date) -> String {
    let calendar = Calendar.current
    let day = calendar.component(.day, from: date)
    let formatter = DateFormatter()
    formatter.dateFormat = "LLLL yyyy"
    let monthYear = formatter.string(from: date)
    // Determine ordinal suffix
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
    return "\(formatter.monthSymbols[Calendar.current.component(.month, from: date)-1]) \(day)\(suffix), \(calendar.component(.year, from: date))"
}

// Read and process files
let fileManager = FileManager.default

guard let items = try? fileManager.contentsOfDirectory(at: articlesDir, includingPropertiesForKeys: nil) else {
    fatalError("Could not list directory: \(articlesDir.path)")
}

// Collect (date, title, url) tuples for markdown files
var articles: [(date: Date, title: String, url: URL)] = []

for fileURL in items where fileURL.pathExtension.lowercased() == "md" {
    let filename = fileURL.deletingPathExtension().lastPathComponent
    // Expect "YYYYMMDD Title"
    let components = filename.split(separator: " ", maxSplits: 1)
    guard components.count == 2 else { continue }
    let dateString = String(components[0])
    let title = String(components[1])
    guard let date = inputFormatter.date(from: dateString) else { continue }
    articles.append((date: date, title: title, url: fileURL))
}

// Sort by date descending, pick top 5
let recent = articles
    .sorted { $0.date > $1.date }
    .prefix(5)

// Build README content
var readme = "# Recent Articles\n\n"

for article in recent {
    // Extract preview
    guard let data = try? Data(contentsOf: article.url),
          let content = String(data: data, encoding: .utf8) else { continue }
    let previewStart = "<!-- preview -->"
    let previewEnd = "<!-- /preview -->"
    var previewText = ""
    if let startRange = content.range(of: previewStart),
       let endRange = content.range(of: previewEnd, range: startRange.upperBound..<content.endIndex) {
        previewText = String(content[startRange.upperBound..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    // Format date line
    let dateLine = formattedDate(article.date)
    // Append markdown
    readme += "## \(article.title)\n"
    readme += "###### \(dateLine)\n\n"
    readme += "\(previewText)\n\n"
    readme += "[Continue Reading](articles/\(article.url.lastPathComponent))\n\n"
}

readme += "##\n"
readme += "[View All](articles/)"

// Write README.md
let readmeURL = URL(fileURLWithPath: "README.md")
try readme.write(to: readmeURL, atomically: true, encoding: .utf8)

print("README.md generated successfully with the 5 most recent articles.")
