import Foundation

public protocol RunnerDelegate: AnyObject {
    func runnerFinished() async
    func handleTestsResults(runner: Runner, executedTests: [String], pathToResults: String?) async
    func XCTestRun() async throws -> XCTestRun
    func buildPath() async -> String
    func getTests() async -> [String]
}
