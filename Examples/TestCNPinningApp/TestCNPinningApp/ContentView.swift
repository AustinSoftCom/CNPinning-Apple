// Copyright (c) 2026 AustinSoft.com

import SwiftUI

struct ContentView: View {
    enum ResultDisplay {
        case html(String)
        case error(String)
    }

    let url = URL(string: "https://www.austinsoft.com/pinning-test.html")!
	var host: String {
		url.host() ?? "unknown"
	}

    @State private var result: ResultDisplay?
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Test CN Pinning")
                .font(.title)
            HStack {
                VStack {
                    Text("Host:").font(.headline)
                    Text(host).font(.caption)
                }
            }
            Spacer()
            Button(
                role: .confirm,
                action: {
                    result = .html("Testing...")
                    isLoading = true
                    TestCNPinningApp.pinnedSession.dataTask(with: url) { data, _, error in
                        if let error {
                            result = .error(error.localizedDescription)
                        } else if let data, let htmlString = String(data: data, encoding: .utf8) {
                            result = .html(htmlString)
                        }
                        isLoading = false
                    }.resume()
                },
                label: {
                    Text("Test")
                        .font(
                            .system(
                                size: 24,
                                weight: .bold,
                                design: .default
                            )
                        )
                }
            ).disabled(isLoading)
            Spacer()

            if let result {
                switch result {
                case let .error(errorString):
                    Text(errorString)

                case let .html(htmlString):
                    Text(htmlString)
                }
            } else {
                Text("Tap 'Test' button to test")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
