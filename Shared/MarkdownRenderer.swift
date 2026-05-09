import Foundation
import Ink

enum MarkdownRenderer {
    nonisolated static func render(_ markdown: String) -> String {
        MarkdownParser().parse(markdown).html
    }
}
