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

    private var runningRequestTasks: [String: ExecutorTask] = [:]

    func execute<SuccessType: Decodable>(
        _ request: DataRequest,
        taskID: String,
        deduplicate: Bool,
        validResponseCodes: Set<Int>,
        emptyResponseCodes: Set<Int>,
        emptyResponseMethods: Set<HTTPMethod>,
        cacheTimeout: TimeInterval
    ) async -> DataResponse<SuccessType, AFError> {
        let randomUUID = UUID().uuidString
        return await execute(
            request,
            taskID: deduplicate ? taskID : randomUUID,
            validResponseCodes: validResponseCodes,
            emptyResponseCodes: emptyResponseCodes,
            emptyResponseMethods: emptyResponseMethods,
            cacheTimeout: cacheTimeout
        )
    }

    private func execute<SuccessType: Decodable>(
        _ request: DataRequest,
        taskID: String,
        validResponseCodes: Set<Int>,
        emptyResponseCodes: Set<Int>,
        emptyResponseMethods: Set<HTTPMethod>,
        cacheTimeout: TimeInterval
    ) async -> DataResponse<SuccessType, AFError> {
        runningRequestTasks = runningRequestTasks.filter { !$0.value.exceedsTimeout }

        if let runningTask = runningRequestTasks[taskID] {
            logger.log(level: .info, message: "🚀 taskID: \(taskID) Cached value used")
            return await runningTask.task.value.map { $0 as! SuccessType }
        } else {
            let requestTask = Task<DataResponse<Decodable & Sendable, AFError>, Never> {
                let result: DataResponse<SuccessType, AFError> = await request.goodifyAsync(
                    validResponseCodes: validResponseCodes,
                    emptyResponseCodes: emptyResponseCodes,
                    emptyResponseMethods: emptyResponseMethods
                )

                return result.map { $0 as Decodable }
            }

            logger.log(level: .info, message: "🚀 taskID: \(taskID): Task created")
            let executorTask: ExecutorTask = ExecutorTask(
                taskID: taskID,
                task: requestTask,
                cacheTimeout: cacheTimeout
            )

            runningRequestTasks[taskID] = executorTask

            let dataResponse = await requestTask.value
            switch dataResponse.result {
            case .success:
                logger.log(level: .info, message: "🚀 taskID: \(taskID): Task finished successfully")
                if cacheTimeout > 0 {
                    runningRequestTasks[taskID]?.finishDate = Date()
                } else {
                    runningRequestTasks[taskID] = nil
                }

            case .failure:
                logger.log(level: .error, message: "🚀 taskID: \(taskID): Task finished with error")
                runningRequestTasks[taskID] = nil
            }

            return dataResponse.map { $0 as! SuccessType }
        }
    }

}

