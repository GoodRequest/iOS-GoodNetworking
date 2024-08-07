//
//  FutureExtensions.swift
//
//
//  Created by Matus Klasovity on 06/08/2024.
//

import Foundation
import Combine

extension Future where Failure == Error {

    static func create(asyncThrowableFunc: @Sendable @escaping () async throws -> Output) -> Self {
        Self.init { promise in
            nonisolated(unsafe) let promise = promise
            Task {
                do {
                    let result = try await asyncThrowableFunc()
                    await MainActor.run {
                        promise(.success(result))
                    }
                } catch {
                    await MainActor.run {
                        promise(.failure(error))
                    }
                }
            }
        }
    }

}

extension Future where Failure == Never {

    static func create(asyncFunc: @Sendable @escaping () async -> Output) -> Self {
        Self.init { promise in
            nonisolated(unsafe) let promise = promise
            Task {
                let result = await asyncFunc()
                await MainActor.run {
                    promise(.success(result))
                }
            }
        }
    }

}
