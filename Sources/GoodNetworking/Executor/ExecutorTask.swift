//
//  ExecutorTask.swift
//
//
//  Created by Matus Klasovity on 06/08/2024.
//

import Foundation
import Alamofire

final class ExecutorTask<T: Decodable & Sendable> {

    var finishDate: Date?
    let taskID: String
    let task: Task<DataResponse<T, AFError>, Never>

    init(taskID: String, task: Task<DataResponse<T, AFError>, Never>) {
        self.taskID = taskID
        self.task = task
    }

}
