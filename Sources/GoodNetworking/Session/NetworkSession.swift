//
//  NetworkSession.swift
//  GoodNetworking
//
//  Created by Dominik Pethö on 8/17/20.
//

import Alamofire
import Combine
import Foundation

#if canImport(AppDebugMode)
import AppDebugMode
#endif

private extension Future where Failure == Never {

    convenience init(_ asyncFunction: @escaping () async -> Output) {
        self.init { (promise: @escaping (Result<Output, Never>) -> Void) in
            Task { promise(.success(await asyncFunction())) }
        }
    }

}

/// Executes network requests for the client app.
public class NetworkSession {

    // MARK: - Static

    public static var `default` = NetworkSession()

    // MARK: - Private

    private let session: Alamofire.Session
    private let configuration: NetworkSessionConfiguration?

    private let baseUrl: String?

    // MARK: - Initialization

    /// A public initializer that sets the baseURL and configuration properties, and initializes the underlying `Session` object.
    public init(
        baseUrl: String? = nil,
        configuration: NetworkSessionConfiguration = .default
    ) {
        self.baseUrl = baseUrl
        self.configuration = configuration

        #if canImport(AppDebugMode)
            let startImmediately = false
        #else
            let startImmediately = true
        #endif

        session = .init(
            configuration: configuration.urlSessionConfiguration,
            startRequestsImmediately: startImmediately,
            interceptor: configuration.interceptor,
            serverTrustManager: configuration.serverTrustManager,
            eventMonitors: configuration.eventMonitors
        )
    }

}

// MARK: - Request

public extension NetworkSession {

    /// Builds a DataRequest object by constructing URL and Body parameters.
    ///
    /// - Parameters:
    ///   - endpoint: A GREndpoint instance representing the endpoint.
    ///   - base: An optional BaseURL instance representing the base URL. If not provided, the default `baseUrl` property will be used.
    /// - Returns: A DataRequest object that is ready to be executed.
    func request(endpoint: Endpoint, base: String? = nil) -> Future<DataRequest, Never> {
        let baseUrl = base ?? baseUrl ?? ""

#if canImport(AppDebugMode)
        if #available(iOS 17.0, *) {
            return Future { [self] in
                await withInterceptionProvider { [self] provider in
                    let interceptedEndpoint = await provider.intercept(requestTo: endpoint)

                    return session.request(
                        try? interceptedEndpoint.url(on: baseUrl),
                        method: interceptedEndpoint.method,
                        parameters: interceptedEndpoint.parameters?.dictionary,
                        encoding: interceptedEndpoint.encoding,
                        headers: interceptedEndpoint.headers
                    )
                }
            }
        } else {
            fatalError("AppDebugModeInterceptable is available on iOS 17.0 and higher")
        }
#else
        return Future { [self] in
            session.request(
                try? endpoint.url(on: baseUrl),
                method: endpoint.method,
                parameters: endpoint.parameters?.dictionary,
                encoding: endpoint.encoding,
                headers: endpoint.headers
            )
        }
#endif
    }

}

// MARK: - Download

public extension NetworkSession {

    /// Creates a download request for the given `endpoint`.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to make the request to.
    ///   - base: The base URL to use for the request. Defaults to nil.
    ///   - customFileName: The custom file name for the downloaded file.
    /// - Returns: A download request for the given endpoint.
    func download(endpoint: Endpoint, base: String? = nil, customFileName: String) -> DownloadRequest {
        let baseUrl = base ?? baseUrl ?? ""

        let destination: DownloadRequest.Destination = { temporaryURL, _ in
            let directoryURLs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let url = directoryURLs.first?.appendingPathComponent(customFileName) ?? temporaryURL

            return (url, [.removePreviousFile, .createIntermediateDirectories])
        }

        return session.download(
            try? endpoint.url(on: baseUrl),
            method: endpoint.method,
            parameters: endpoint.parameters?.dictionary,
            encoding: endpoint.encoding,
            headers: endpoint.headers,
            to: destination
        )
    }

}


// MARK: - Upload

public extension NetworkSession {

    /// Uploads data to endpoint.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint manager object to specify the endpoint URL and other related information.
    ///   - data: The data to be uploaded.
    ///   - fileHeader: The header to be used for the uploaded data in the form data. Defaults to "file".
    ///   - filename: The name of the file to be uploaded.
    ///   - mimeType: The MIME type of the data to be uploaded.
    /// - Returns: The upload request object.
    func uploadWithMultipart(
        endpoint: Endpoint,
        data: Data,
        fileHeader: String = "file",
        filename: String,
        mimeType: String,
        base: String? = nil
    ) -> UploadRequest {
        let baseUrl = base ?? baseUrl ?? ""

        return session.upload(
            multipartFormData: { formData in
                formData.append(data, withName: fileHeader, fileName: filename, mimeType: mimeType)
            },
            to: try? endpoint.url(on: baseUrl),
            method: endpoint.method,
            headers: endpoint.headers
        )
    }

}

// MARK: - Public - Global functions

#if canImport(AppDebugMode)
public func setupInterceptor() {
    print("✅ [GoodNetworking] AppDebugModeInterceptable installed")
}
#endif
