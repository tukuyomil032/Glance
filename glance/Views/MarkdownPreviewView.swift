//
//  MarkdownPreviewView.swift
//  glance
//
//  Created by yomi on 2026/05/09.
//

import SwiftUI
import WebKit

struct MarkdownPreviewView: NSViewRepresentable {
    let html: String

    func makeNSView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }
}
