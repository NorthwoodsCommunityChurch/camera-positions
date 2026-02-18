import Foundation
import OSLog

private let logger = Logger(subsystem: "com.northwoods.CameraPositions", category: "HTTP")

struct HTTPRequest {
    let method: String
    let path: String
    let headers: [String: String]
    let body: Data

    static func parse(from data: Data) -> HTTPRequest? {
        guard let headerEnd = data.range(of: Data([0x0D, 0x0A, 0x0D, 0x0A])) else {
            return nil
        }

        let headerData = data[..<headerEnd.lowerBound]
        guard let headerString = String(data: headerData, encoding: .utf8) else {
            return nil
        }

        let lines = headerString.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return nil }

        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2 else { return nil }

        let method = String(parts[0])
        let path = String(parts[1])

        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            if let colonIndex = line.firstIndex(of: ":") {
                let key = String(line[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let value = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                headers[key] = value
            }
        }

        let body = Data(data[headerEnd.upperBound...])

        if let contentLengthStr = headers["Content-Length"],
           let contentLength = Int(contentLengthStr) {
            if body.count < contentLength { return nil }
            let trimmedBody = body.prefix(contentLength)
            return HTTPRequest(method: method, path: path, headers: headers, body: Data(trimmedBody))
        }

        return HTTPRequest(method: method, path: path, headers: headers, body: body)
    }
}

struct HTTPResponse {
    let statusCode: Int
    let statusText: String
    let headers: [String: String]
    let body: Data

    func toData() -> Data {
        var headerLines = ["HTTP/1.1 \(statusCode) \(statusText)"]

        var responseHeaders = headers
        if responseHeaders["Content-Length"] == nil {
            responseHeaders["Content-Length"] = "\(body.count)"
        }

        for (key, value) in responseHeaders {
            headerLines.append("\(key): \(value)")
        }

        let headerString = headerLines.joined(separator: "\r\n") + "\r\n\r\n"
        var data = Data(headerString.utf8)
        data.append(body)
        return data
    }

    static func ok(body: String, contentType: String = "text/html") -> HTTPResponse {
        HTTPResponse(
            statusCode: 200,
            statusText: "OK",
            headers: [
                "Content-Type": "\(contentType); charset=utf-8",
                "Cache-Control": "no-cache",
                "Access-Control-Allow-Origin": "*"
            ],
            body: Data(body.utf8)
        )
    }

    static func ok(data: Data, contentType: String) -> HTTPResponse {
        HTTPResponse(
            statusCode: 200,
            statusText: "OK",
            headers: [
                "Content-Type": contentType,
                "Cache-Control": "no-cache",
                "Access-Control-Allow-Origin": "*"
            ],
            body: data
        )
    }

    static func notFound() -> HTTPResponse {
        HTTPResponse(
            statusCode: 404,
            statusText: "Not Found",
            headers: ["Content-Type": "text/plain", "Access-Control-Allow-Origin": "*"],
            body: Data("404 Not Found".utf8)
        )
    }
}
