//
//  NetworkSession.swift
//  GoodNetworking
//
//  Created by Dominik Pethö on 8/17/20.
//

import Alamofire
import Foundation
import Combine

/// Executes network requests for the client app.
public class NetworkSession {

    // MARK: - Static

    public static var `default` = NetworkSession()

    // MARK: - Variables

    public let session: Alamofire.Session
    public let configuration: NetworkSessionConfiguration?

    public let baseUrl: String?

    private let requestExecutor = RequestExecutor()

    // MARK: - Initialization

    /// A public initializer that sets the baseURL and configuration properties, and initializes the underlying `Session` object.
    public init(
        baseUrl: String? = nil,
        configuration: NetworkSessionConfiguration = .default
    ) {
        self.baseUrl = baseUrl
        self.configuration = configuration

        session = .init(
            configuration: configuration.urlSessionConfiguration,
            interceptor: configuration.interceptor,
            serverTrustManager: configuration.serverTrustManager,
            eventMonitors: configuration.eventMonitors
        )
    }

}

// MARK: - Build Request

public extension NetworkSession {

    /// Builds a DataRequest object by constructing URL and Body parameters.
    ///
    /// - Parameters:
    ///   - endpoint: A Endpoint instance representing the endpoint.
    ///   - base: An optional BaseURL instance representing the base URL. If not provided, the default `baseUrl` property will be used.
    /// - Returns: A DataRequest object that is ready to be executed.
    @available(*, deprecated, renamed: "buildRequest", message: "Request method is deprecated, use buildRequest instead.")
    func request(endpoint: Endpoint, base: String? = nil) -> DataRequest {
        let baseUrl = base ?? baseUrl ?? ""

        return session.request(
            try? endpoint.url(on: baseUrl),
            method: endpoint.method,
            parameters: endpoint.parameters?.dictionary,
            encoding: endpoint.encoding,
            headers: endpoint.headers
        )
    }

    /// Builds a DataRequest object by constructing URL and Body parameters.
    ///
    /// - Parameters:
    ///   - endpoint: A Endpoint instance representing the endpoint.
    ///   - base: An optional BaseURL instance representing the base URL. If not provided, the default `baseUrl` property will be used.
    /// - Returns: A DataRequest object that is ready to be executed.
    func buildRequest(endpoint: Endpoint, base: String? = nil) -> DataRequest {
        let baseUrl = base ?? baseUrl ?? ""

        return session.request(
            try? endpoint.url(on: baseUrl),
            method: endpoint.method,
            parameters: endpoint.parameters?.dictionary,
            encoding: endpoint.encoding,
            headers: endpoint.headers
        )
    }

}

// MARK: - Execute request - Async

public extension NetworkSession {

    /// Executes a data request and returns a `DataResponse` containing the result of the request.
    ///
    /// This method allows you to specify various parameters to control the request execution,
    /// including deduplication, valid response codes, and empty response handling.
    ///
    /// - Parameters:
    ///   - request: The `DataRequest` to be executed.
    ///   - deduplicate: A boolean value indicating whether to deduplicate the request. Default is `true`.
    ///   - validResponseCodes: A set of valid HTTP response codes. Default is all codes from 200 to 299.
    ///   - emptyResponseCodes: A set of HTTP response codes that indicate an empty response. Default is the `DecodableResponseSerializer` default empty response codes for the specified `ResultType`.
    ///   - emptyResponseMethods: A set of HTTP methods that indicate an empty response. Default is the `DecodableResponseSerializer` default empty request methods for the specified `ResultType`.
    ///   - cacheTimeout: The time interval to cache the successful response. Default is `0` (no cache).
    /// - Returns: A `DataResponse` containing the result of the request, which includes either the decoded result of type `ResultType` or an `AFError`.
    func execute<ResultType: Decodable>(
        request: DataRequest,
        deduplicate: Bool = true,
        validResponseCodes: Set<Int> = Set(200..<300),
        emptyResponseCodes: Set<Int> = DecodableResponseSerializer<ResultType>.defaultEmptyResponseCodes,
        emptyResponseMethods: Set<HTTPMethod> = DecodableResponseSerializer<ResultType>.defaultEmptyRequestMethods,
        cacheTimeout: TimeInterval = 0
    ) async -> DataResponse<ResultType, AFError> {
        let taskID = request.convertible.urlRequest?.url?.absoluteString ?? UUID().uuidString

        return await requestExecutor.execute(
            request,
            taskID: taskID,
            deduplicate: deduplicate,
            validResponseCodes: validResponseCodes,
            emptyResponseCodes: emptyResponseCodes,
            emptyResponseMethods: emptyResponseMethods,
            cacheTimeout: cacheTimeout
        )
    }

    /// Executes a request to the specified endpoint and returns a `DataResponse` containing the result.
    ///
    /// This method allows you to specify various parameters to control the request execution,
    /// including the base URL, deduplication, valid response codes, and empty response handling.
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` representing the API endpoint to be requested.
    ///   - base: An optional base URL to be used for the request. If not provided, the default base URL is used.
    ///   - deduplicate: A boolean value indicating whether to deduplicate the request. Default is `true`.
    ///   - validResponseCodes: A set of valid HTTP response codes. Default is all codes from 200 to 299.
    ///   - emptyResponseCodes: A set of HTTP response codes that indicate an empty response. Default is the `DecodableResponseSerializer` default empty response codes for the specified `ResultType`.
    ///   - emptyResponseMethods: A set of HTTP methods that indicate an empty response. Default is the `DecodableResponseSerializer` default empty request methods for the specified `ResultType`.
    ///   - cacheTimeout: The time interval to cache the successful response. Default is `0` (no cache).
    /// - Returns: A `DataResponse` containing the result of the request, which includes either the decoded result of type `ResultType` or an `AFError`.
    func execute<ResultType: Decodable>(
        endpoint: Endpoint,
        base: String? = nil,
        deduplicate: Bool = true,
        validResponseCodes: Set<Int> = Set(200..<300),
        emptyResponseCodes: Set<Int> = DecodableResponseSerializer<ResultType>.defaultEmptyResponseCodes,
        emptyResponseMethods: Set<HTTPMethod> = DecodableResponseSerializer<ResultType>.defaultEmptyRequestMethods,
        cacheTimeout: TimeInterval = 0
    ) async -> DataResponse<ResultType, AFError> {
        let baseUrl = base ?? baseUrl ?? ""
        let taskID = (try? endpoint.url(on: baseUrl).absoluteString) ?? UUID().uuidString
        let request = self.buildRequest(endpoint: endpoint, base: base)

        return await requestExecutor.execute(
            request,
            taskID: taskID,
            deduplicate: deduplicate,
            validResponseCodes: validResponseCodes,
            emptyResponseCodes: emptyResponseCodes,
            emptyResponseMethods: emptyResponseMethods,
            cacheTimeout: cacheTimeout
        )
    }

}

// MARK: - Execute Request - Publisher DataResponse

public extension NetworkSession {

    /// Executes a request to the specified endpoint and returns a `DataResponse` containing the result.
    ///
    /// This method allows you to specify various parameters to control the request execution,
    /// including the base URL, deduplication, valid response codes, and empty response handling.
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` representing the API endpoint to be requested.
    ///   - base: An optional base URL to be used for the request. If not provided, the default base URL is used.
    ///   - deduplicate: A boolean value indicating whether to deduplicate the request. Default is `true`.
    ///   - validResponseCodes: A set of valid HTTP response codes. Default is all codes from 200 to 299.
    ///   - emptyResponseCodes: A set of HTTP response codes that indicate an empty response. Default is the `DecodableResponseSerializer` default empty response codes for the specified `ResultType`.
    ///   - emptyResponseMethods: A set of HTTP methods that indicate an empty response. Default is the `DecodableResponseSerializer` default empty request methods for the specified `ResultType`.
    ///   - cacheTimeout: The time interval to cache the successful response. Default is `0` (no cache).
    /// - Returns: A Publisher of `DataResponse` containing the result of the request, which includes either the decoded result of type `ResultType` or an `AFError`.
    func execute<ResultType: Decodable>(
        request: DataRequest,
        deduplicate: Bool = true,
        validResponseCodes: Set<Int> = Set(200..<300),
        emptyResponseCodes: Set<Int> = DecodableResponseSerializer<ResultType>.defaultEmptyResponseCodes,
        emptyResponseMethods: Set<HTTPMethod> = DecodableResponseSerializer<ResultType>.defaultEmptyRequestMethods,
        cacheTimeout: TimeInterval = 0
    ) -> AnyPublisher<DataResponse<ResultType, AFError>, Never> {
        let taskID = request.convertible.urlRequest?.url?.absoluteString ?? UUID().uuidString

        return Future.create { [weak self] in
            guard let self else {
                return DataResponse<ResultType, AFError>(
                    request: nil,
                    response: nil,
                    data: nil,
                    metrics: nil,
                    serializationDuration: .nan,
                    result: .failure(AFError.sessionDeinitialized)
                )
            }

            return await requestExecutor.execute(
                request,
                taskID: taskID,
                deduplicate: deduplicate,
                validResponseCodes: validResponseCodes,
                emptyResponseCodes: emptyResponseCodes,
                emptyResponseMethods: emptyResponseMethods,
                cacheTimeout: cacheTimeout
            )
        }
        .eraseToAnyPublisher()
    }

    /// Executes a request to the specified endpoint and returns a `DataResponse` containing the result.
    ///
    /// This method allows you to specify various parameters to control the request execution,
    /// including the base URL, deduplication, valid response codes, and empty response handling.
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` representing the API endpoint to be requested.
    ///   - base: An optional base URL to be used for the request. If not provided, the default base URL is used.
    ///   - deduplicate: A boolean value indicating whether to deduplicate the request. Default is `true`.
    ///   - validResponseCodes: A set of valid HTTP response codes. Default is all codes from 200 to 299.
    ///   - emptyResponseCodes: A set of HTTP response codes that indicate an empty response. Default is the `DecodableResponseSerializer` default empty response codes for the specified `ResultType`.
    ///   - emptyResponseMethods: A set of HTTP methods that indicate an empty response. Default is the `DecodableResponseSerializer` default empty request methods for the specified `ResultType`.
    ///   - cacheTimeout: The time interval to cache the successful response. Default is `0` (no cache).
    /// - Returns: A Publisher of `DataResponse` containing the result of the request, which includes either the decoded result of type `ResultType` or an `AFError`.
    func execute<ResultType: Decodable>(
        endpoint: Endpoint,
        base: String? = nil,
        deduplicate: Bool = true,
        validResponseCodes: Set<Int> = Set(200..<300),
        emptyResponseCodes: Set<Int> = DecodableResponseSerializer<ResultType>.defaultEmptyResponseCodes,
        emptyResponseMethods: Set<HTTPMethod> = DecodableResponseSerializer<ResultType>.defaultEmptyRequestMethods,
        cacheTimeout: TimeInterval = 0
    ) -> AnyPublisher<DataResponse<ResultType, AFError>, Never> {
        let baseUrl = base ?? baseUrl ?? ""
        let taskID = (try? endpoint.url(on: baseUrl).absoluteString) ?? UUID().uuidString
        let request = self.buildRequest(endpoint: endpoint, base: base)

        return Future.create { [weak self] in
            guard let self else {
                return DataResponse<ResultType, AFError>(
                    request: nil,
                    response: nil,
                    data: nil,
                    metrics: nil,
                    serializationDuration: .nan,
                    result: .failure(AFError.sessionDeinitialized)
                )
            }

            return await requestExecutor.execute(
                request,
                taskID: taskID,
                deduplicate: deduplicate,
                validResponseCodes: validResponseCodes,
                emptyResponseCodes: emptyResponseCodes,
                emptyResponseMethods: emptyResponseMethods,
                cacheTimeout: cacheTimeout
            )
        }
        .eraseToAnyPublisher()
    }

}

// MARK: - Execute Request - Publisher Response

public extension NetworkSession {

    /// Executes a request to the specified endpoint and returns a `DataResponse` containing the result.
    ///
    /// This method allows you to specify various parameters to control the request execution,
    /// including the base URL, deduplication, valid response codes, and empty response handling.
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` representing the API endpoint to be requested.
    ///   - base: An optional base URL to be used for the request. If not provided, the default base URL is used.
    ///   - deduplicate: A boolean value indicating whether to deduplicate the request. Default is `true`.
    ///   - validResponseCodes: A set of valid HTTP response codes. Default is all codes from 200 to 299.
    ///   - emptyResponseCodes: A set of HTTP response codes that indicate an empty response. Default is the `DecodableResponseSerializer` default empty response codes for the specified `ResultType`.
    ///   - emptyResponseMethods: A set of HTTP methods that indicate an empty response. Default is the `DecodableResponseSerializer` default empty request methods for the specified `ResultType`.
    ///   - cacheTimeout: The time interval to cache the successful response. Default is `0` (no cache).
    /// - Returns: A Publisher of `ResultType` or an `AFError`.
    func execute<ResultType: Decodable>(
        endpoint: Endpoint,
        base: String? = nil,
        deduplicate: Bool = true,
        validResponseCodes: Set<Int> = Set(200..<300),
        emptyResponseCodes: Set<Int> = DecodableResponseSerializer<ResultType>.defaultEmptyResponseCodes,
        emptyResponseMethods: Set<HTTPMethod> = DecodableResponseSerializer<ResultType>.defaultEmptyRequestMethods,
        cacheTimeout: TimeInterval = 0
    ) -> AnyPublisher<ResultType, AFError> {
        let baseUrl = base ?? baseUrl ?? ""
        let taskID = (try? endpoint.url(on: baseUrl).absoluteString) ?? UUID().uuidString
        let request = self.buildRequest(endpoint: endpoint, base: base)

        return Future.create { [weak self] in
            guard let self else {
                throw AFError.sessionDeinitialized
            }

            let dataResponse: DataResponse<ResultType, AFError> = await requestExecutor.execute(
                request,
                taskID: taskID,
                deduplicate: deduplicate,
                validResponseCodes: validResponseCodes,
                emptyResponseCodes: emptyResponseCodes,
                emptyResponseMethods: emptyResponseMethods,
                cacheTimeout: cacheTimeout
            )

            switch dataResponse.result {
            case .success(let success):
                return success
            case .failure(let failure):
                throw failure
            }
        }
        .mapError { $0.asAFError(orFailWith: "") }
        .eraseToAnyPublisher()
    }

    /// Executes a request to the specified endpoint and returns a `DataResponse` containing the result.
    ///
    /// This method allows you to specify various parameters to control the request execution,
    /// including the base URL, deduplication, valid response codes, and empty response handling.
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` representing the API endpoint to be requested.
    ///   - base: An optional base URL to be used for the request. If not provided, the default base URL is used.
    ///   - deduplicate: A boolean value indicating whether to deduplicate the request. Default is `true`.
    ///   - validResponseCodes: A set of valid HTTP response codes. Default is all codes from 200 to 299.
    ///   - emptyResponseCodes: A set of HTTP response codes that indicate an empty response. Default is the `DecodableResponseSerializer` default empty response codes for the specified `ResultType`.
    ///   - emptyResponseMethods: A set of HTTP methods that indicate an empty response. Default is the `DecodableResponseSerializer` default empty request methods for the specified `ResultType`.
    ///   - cacheTimeout: The time interval to cache the successful response. Default is `0` (no cache).
    /// - Returns: A Publisher of `ResultType` or an `AFError`.
    func execute<ResultType: Decodable>(
        request: DataRequest,
        deduplicate: Bool = true,
        validResponseCodes: Set<Int> = Set(200..<300),
        emptyResponseCodes: Set<Int> = DecodableResponseSerializer<ResultType>.defaultEmptyResponseCodes,
        emptyResponseMethods: Set<HTTPMethod> = DecodableResponseSerializer<ResultType>.defaultEmptyRequestMethods,
        cacheTimeout: TimeInterval = 0
    ) -> AnyPublisher<ResultType, AFError> {
        let taskID = request.convertible.urlRequest?.url?.absoluteString ?? UUID().uuidString

        return Future.create { [weak self] in
            guard let self else {
                throw AFError.sessionDeinitialized
            }

            let dataResponse: DataResponse<ResultType, AFError> = await requestExecutor.execute(
                request,
                taskID: taskID,
                deduplicate: deduplicate,
                validResponseCodes: validResponseCodes,
                emptyResponseCodes: emptyResponseCodes,
                emptyResponseMethods: emptyResponseMethods,
                cacheTimeout: cacheTimeout
            )

            switch dataResponse.result {
            case .success(let success):
                return success
            case .failure(let failure):
                throw failure
            }
        }
        .mapError { $0.asAFError(orFailWith: "") }
        .eraseToAnyPublisher()
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

    /// Uploads multipart form data to endpoint.
    ///
    /// - Parameters:
    ///  - endpoint: The endpoint manager object to specify the endpoint URL and other related information.
    ///  - multipartFormData: The multipart form data to be uploaded.
    ///  - base: The base URL to use for the request. Defaults to nil.
    /// - Returns: The upload request object.
    /// ## Example
    /// ```swift
    /// let fileURL = URL(filePath: "path/to/file")
    /// let multipartFormData = MultipartFormData()
    /// multipartFormData.append(fileURL, withName: "file")
    ///
    /// let image = UIImage(named: "image")
    /// let imageData = image?.jpegData(compressionQuality: 0.5)
    /// multipartFormData.append(imageData!, withName: "image", fileName: "image.jpg", mimeType: "image/jpeg")
    ///
    /// let request = session.uploadWithMultipart(endpoint: endpoint, multipartFormData: multipartFormData)
    /// ```
    func uploadWithMultipart(
        endpoint: Endpoint,
        multipartFormData: MultipartFormData,
        base: String? = nil
    ) -> UploadRequest {
        let baseUrl = base ?? baseUrl ?? ""

        return session.upload(
            multipartFormData: multipartFormData,
            to: try? endpoint.url(on: baseUrl),
            method: endpoint.method,
            headers: endpoint.headers
        )
    }

}
