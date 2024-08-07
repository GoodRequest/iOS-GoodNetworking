//
//  ExecutorTask.swift
//
//
//  Created by Matus Klasovity on 06/08/2024.
//

import Foundation
import Alamofire

final class ExecutorTask {

    var finishDate: Date?
    let taskID: String
    let task: Task<DataResponse<Decodable & Sendable, AFError>, Never>

    private let cacheTimeout: TimeInterval

    var exceedsTimeout: Bool {
        guard let finishDate else { return false }
        return Date().timeIntervalSince(finishDate) > cacheTimeout
    }

    init(taskID: String, task: Task<DataResponse<Decodable & Sendable, AFError>, Never>, cacheTimeout: TimeInterval) {
        self.taskID = taskID
        self.task = task
        self.cacheTimeout = cacheTimeout
    }

}
