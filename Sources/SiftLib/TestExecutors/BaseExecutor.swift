import Foundation

class BaseExecutor {

    var ssh: SSHExecutor!
    let threadName: String
    let queue: Queue
    let config: Config.NodeConfig
    let xctestrunPath: String
    let setUpScriptPath: String?
    let tearDownScriptPath: String?
    var xcodebuild: Xcodebuild!
    let UDID: String
    private var _finished: Bool = false
    var finished: Bool {
        get {
            self.queue.sync { self._finished }
        }
        set {
            self.queue.async(flags: .barrier) { self._finished = newValue }
        }
    }

    init(UDID: String,
         config: Config.NodeConfig,
         xctestrunPath: String,
         setUpScriptPath: String?,
         tearDownScriptPath: String?) throws {

        self.UDID = UDID
        self.config = config
        self.xctestrunPath = xctestrunPath
        self.setUpScriptPath = setUpScriptPath
        self.tearDownScriptPath = tearDownScriptPath
        self.threadName = UDID
        self.queue = .init(type: .serial, name: self.threadName)
        try self.queue.sync {
            self.ssh = try SSH(host: config.host, port: config.port)
            try self.ssh.authenticate(username: self.config.username, password: self.config.password)
            self.xcodebuild = Xcodebuild(xcodePath: self.config.xcodePath, shell: self.ssh)
        }
    }
    
    @discardableResult
    func executeShellScript(path: String?, testNameEnv: String) throws -> Int32? {
        if let scriptPath = path {
            let script = try String(contentsOfFile: scriptPath, encoding: .utf8)
            let env = "export TEST_NAME='\(testNameEnv)'\n" +
                      "export UDID='\(UDID)'\n" +
                (self.config
                    .environmentVariables?
                    .map { "export \($0.key)=\($0.value)" }
                    .joined(separator: "\n") ?? "")
            let scriptExecutionResult = try self.ssh.run(env + script)
            return scriptExecutionResult.status
        }
        return nil
    }
}
