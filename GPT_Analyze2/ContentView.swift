import SwiftUI
import AppKit
import Foundation
import NaturalLanguage

class Analyzer: ObservableObject {
    @Published var statusText: String = "Select a file to start analysis"
    @Published var isAnalyzing: Bool = false

    func analyze(fileURL: URL) {
        DispatchQueue.global(qos: .background).async {
            do {
                let startTime = Date()
                DispatchQueue.main.async {
                    self.statusText = "Starting analysis at: \(startTime)"
                }

                let data = try Data(contentsOf: fileURL)
                guard let conversationsData = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else {
                    DispatchQueue.main.async {
                        self.statusText = "Invalid JSON format"
                    }
                    return
                }

                DispatchQueue.main.async {
                    self.statusText = "File loaded and JSON parsed successfully"
                }

                var messages: [String] = []
                for conversation in conversationsData {
                    if let mapping = conversation["mapping"] as? [String: [String: Any]] {
                        for node in mapping.values {
                            if let message = node["message"] as? [String: Any],
                               let content = message["content"] as? [String: Any],
                               let parts = content["parts"] as? [String] {
                                messages.append(contentsOf: parts)
                            }
                        }
                    }
                }

                DispatchQueue.main.async {
                    self.statusText = "Messages extracted successfully"
                }

                let textMessages = messages.filter { $0 is String }
                let allText = textMessages.joined(separator: " ")

                DispatchQueue.main.async {
                    self.statusText = "Non-text messages filtered out"
                }

                let tokenizer = NLTokenizer(unit: .word)
                tokenizer.string = allText
                var words: [String] = []
                tokenizer.enumerateTokens(in: allText.startIndex..<allText.endIndex) { tokenRange, _ in
                    let word = String(allText[tokenRange]).lowercased()
                    words.append(word)
                    return true
                }

                DispatchQueue.main.async {
                    self.statusText = "Text tokenized successfully"
                }

                let wordCounts = NSCountedSet(array: words)
                let totalWords = wordCounts.count
                let sortedWords = wordCounts.allObjects.compactMap { $0 as? String }.sorted { wordCounts.count(for: $0) > wordCounts.count(for: $1) }

                DispatchQueue.main.async {
                    self.statusText = "Word frequencies counted"
                }

                let sentimentAnalyzer = NLTagger(tagSchemes: [.sentimentScore])
                sentimentAnalyzer.string = allText
                let sentiment = sentimentAnalyzer.tag(at: allText.startIndex, unit: .paragraph, scheme: .sentimentScore).0?.rawValue ?? "0.0"
                let overallSentiment = Double(sentiment) ?? 0.0

                DispatchQueue.main.async {
                    self.statusText = "Overall sentiment: \(overallSentiment)"
                }

                let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
                let resultsFileURL = homeDirectory.appendingPathComponent("analysis_results.txt")
                let filteredResultsFileURL = homeDirectory.appendingPathComponent("analysis_results_without_stopwords.txt")

                var resultsText = "Most common words:\n"
                for word in sortedWords.prefix(100000) {
                    let count = wordCounts.count(for: word)
                    let percentage = (Double(count) / Double(totalWords)) * 100
                    resultsText += "\(word): \(count) (\(String(format: "%.2f", percentage))%)\n"
                }
                resultsText += "\nOverall sentiment: \(overallSentiment)\n"
                try resultsText.write(to: resultsFileURL, atomically: true, encoding: .utf8)

                let stopWords: Set<String> = ["a", "an", "the", "and", "or", "but", "because", "as", "if", "when", "while", "of", "at", "by", "for", "with", "about", "against", "between", "into", "through", "during", "before", "after", "above", "below", "to", "from", "up", "down", "in", "out", "on", "off", "over", "under", "again", "further", "then", "once", "here", "there", "all", "any", "both", "each", "few", "more", "most", "other", "some", "such", "no", "nor", "not", "only", "own", "same", "so", "than", "too", "very", "s", "t", "can", "will", "just", "don", "should", "now"]

                let filteredWords = words.filter { !stopWords.contains($0) }

                DispatchQueue.main.async {
                    self.statusText = "Stop words filtered out"
                }

                let filteredWordCounts = NSCountedSet(array: filteredWords)
                let filteredTotalWords = filteredWordCounts.count
                let filteredSortedWords = filteredWordCounts.allObjects.compactMap { $0 as? String }.sorted { filteredWordCounts.count(for: $0) > filteredWordCounts.count(for: $1) }

                var filteredResultsText = "Most common words (without stop words):\n"
                for word in filteredSortedWords.prefix(100000) {
                    let count = filteredWordCounts.count(for: word)
                    let percentage = (Double(count) / Double(filteredTotalWords)) * 100
                    filteredResultsText += "\(word): \(count) (\(String(format: "%.2f", percentage))%)\n"
                }
                try filteredResultsText.write(to: filteredResultsFileURL, atomically: true, encoding: .utf8)

                let endTime = Date()
                DispatchQueue.main.async {
                    self.statusText = "Analysis completed at: \(endTime)\nTotal analysis time: \(endTime.timeIntervalSince(startTime)) seconds"
                    self.isAnalyzing = false
                }

            } catch {
                DispatchQueue.main.async {
                    self.statusText = "Error loading or parsing file: \(error)"
                    self.isAnalyzing = false
                }
            }
        }
    }
}
