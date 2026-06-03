// Copyright (c) 2026 AustinSoft.com

@testable import CNPinning_Apple
import Foundation
import XCTest

/// Sigh. Testing live works-once. Then Apple caches the successful results from the using the
/// pinning delegate and doesn't call it again for the domain.
final class TestURLSessionDelegate: NSObject, URLSessionTaskDelegate {
    func testDelegate() -> String {
        "TestULRSessionDelegate"
    }

    func urlSession(_ session: URLSession, task _: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let pinningManager = session.cnPinningManager else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        if !pinningManager.validate(challenge: challenge, completionHandler: completionHandler) {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

class CNPinningManagerLiveTests: XCTestCase {
    var urlSession: URLSession!
    var taskDelegate: URLSessionTaskDelegate!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.default
		// Necessary when testing pinning, otherwise the results are undefined due to caching
        configuration.urlCache = nil

        urlSession = URLSession(configuration: configuration)
        taskDelegate = TestURLSessionDelegate()
    }

    func testCNPinningManagerTestDelegateFailure() throws {
        let url = try XCTUnwrap(URL(string: "https://www.austinsoft.com/pinning-test.html"))
        let expectation = XCTestExpectation(description: "Request completed")
        let task = urlSession.dataTask(with: url) { data, response, error in
            XCTAssertNotNil(error)
            XCTAssertNil(data)
            XCTAssertNil(response)
            expectation.fulfill()
        }
        task.delegate = taskDelegate
        task.resume()

        wait(for: [expectation])
    }

    func testCNPinningManagerValidatePinnedLiveSucceeds() throws {
        let pinningManager = try CNPinningManager(
            configuration: [
                "www.austinsoft.com": .init(
                    includesSubdomains: false,
                    [
                        .init([
                            .init(.prefixWithNumber, "ISRG Root X"),
                            .init(.prefixWithNumber, "R"),
                            .init(.exact, "austinsoft.com"),
                        ]),
                    ]
                ),
            ]
        )
        urlSession.cnPinningManager = pinningManager

        let url = try XCTUnwrap(URL(string: "https://www.austinsoft.com/pinning-test.html"))
        let expectation = XCTestExpectation(description: "Request completed")
        let task = urlSession.dataTask(with: url) { data, response, _ in
            XCTAssertEqual(response?.url?.host, "www.austinsoft.com")
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
            XCTAssert(data != nil && !(data?.isEmpty ?? true))
            XCTAssert((data != nil ? String(data: data!, encoding: .utf8) : nil) == "<HTML><HEAD><TITLE>CN Pinning</TITLE></HEAD><BODY>CN-Pinning-Test-OK</BODY></HTML>\n")
            expectation.fulfill()
        }
        task.delegate = taskDelegate
        task.resume()

        wait(for: [expectation])
    }

    func testCNPinningManagerValidatePinnedLiveFails() throws {
        let pinningManager = try CNPinningManager(
            configuration: [
                "www.austinsoft.com": .init(
                    includesSubdomains: false,
                    [
                        .init([
                            .init(.prefixWithNumber, "ISRG Root X"),
                            .init(.prefixWithNumber, "R"),
                            .init(.exact, "www.austinsoft.com"), // certificate is for austinsoft.com, not www.austinsoft.com
                        ]),
                    ]
                ),
            ]
        )
        urlSession.cnPinningManager = pinningManager

        let url = try XCTUnwrap(URL(string: "https://www.austinsoft.com/pinning-test.html"))
        let expectation = XCTestExpectation(description: "Request completed")
        let task = urlSession.dataTask(with: url) { data, response, error in
            XCTAssertNotNil(error)
            XCTAssertNil(data)
            XCTAssertNil(response)
            expectation.fulfill()
        }
        task.delegate = taskDelegate
        task.resume()

        wait(for: [expectation])
    }

    func testCNPinningManagerValidatePinnedLiveUnpinned() throws {
        let pinningManager = try CNPinningManager(
            configuration: [
                "austinsoft.com": .init( // pin only the top-level domain name, not the subdomain
                    includesSubdomains: false,
                    [
                        .init([
                            .init(.prefixWithNumber, "ISRG Root X"),
                            .init(.prefixWithNumber, "R"),
                            .init(.exact, "austinsoft.com"),
                        ]),
                    ]
                ),
            ]
        )
        urlSession.cnPinningManager = pinningManager

        let url = try XCTUnwrap(URL(string: "https://www.austinsoft.com/pinning-test.html"))
        let expectation = XCTestExpectation(description: "Request completed")
        let task = urlSession.dataTask(with: url) { data, response, _ in
            XCTAssertEqual(response?.url?.host, "www.austinsoft.com")
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
            XCTAssert(data != nil && !(data?.isEmpty ?? true))
            XCTAssert((data != nil ? String(data: data!, encoding: .utf8) : nil) == "<HTML><HEAD><TITLE>CN Pinning</TITLE></HEAD><BODY>CN-Pinning-Test-OK</BODY></HTML>\n")
            expectation.fulfill()
        }
        task.delegate = taskDelegate
        task.resume()

        wait(for: [expectation])
    }

    func testDefaultPinningManager() throws {
        XCTAssertThrowsError(try CNPinningManager()) { error in
            XCTAssertNotNil(error as? CNParseError)
            XCTAssertEqual((error as? CNParseError)!, CNParseError.missingValue("CNPinningManager"))
        }
    }
}
