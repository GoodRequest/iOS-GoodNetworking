//
//  RequestExecutor.swift
//
//
//  Created by Matus Klasovity on 06/08/2024.
//

import Foundation
import Alamofire

actor RequestExecutor {

    private let logger: SessionLogger = {
        if #available(iOS 14, *) {
            return OSLogLogger()
        } else {
            return PrintLogger()
        }
    }()

    private var runningRequestTasks: [String: Any] = [:]

    func execute<SuccessType: Decodable>(
        _ request: DataRequest,
        taskID: String,
        deduplicate: Bool,
        validResponseCodes: Set<Int>,
        emptyResponseCodes: Set<Int>,
        emptyResponseMethods: Set<HTTPMethod>
    ) async -> DataResponse<SuccessType, AFError> {
        let randomUUID = UUID().uuidString
        return await execute(
            request,
            taskID: deduplicate ? taskID : randomUUID,
            validResponseCodes: validResponseCodes,
            emptyResponseCodes: emptyResponseCodes,
            emptyResponseMethods: emptyResponseMethods
        )
    }

    private func execute<SuccessType: Decodable & Sendable>(
        _ request: DataRequest,
        taskID: String,
        validResponseCodes: Set<Int>,
        emptyResponseCodes: Set<Int>,
        emptyResponseMethods: Set<HTTPMethod>
    ) async -> DataResponse<SuccessType, AFError> {
        if let runningTask = runningRequestTasks[taskID] {
            let executorTask = runningTask as! ExecutorTask<SuccessType>
            logger.log(level: .info, message: "🚀 taskID: \(taskID) Cached value used")
            return await executorTask.task.value
        } else {
            let requestTask = Task {
                return await request.goodifyAsync(
                    validResponseCodes: validResponseCodes,
                    emptyResponseCodes: emptyResponseCodes,
                    emptyResponseMethods: emptyResponseMethods
                ) as DataResponse<SuccessType, AFError>
            }

            logger.log(level: .info, message: "🚀 taskID: \(taskID): Task created")
            let executorTask: ExecutorTask = ExecutorTask(
                taskID: taskID,
                task: requestTask
            )

            runningRequestTasks[taskID] = executorTask

            let result = await requestTask.value

            logger.log(level: .info, message: "🚀 taskID: \(taskID): Task finished successfully")
            return result
        }
    }

}

