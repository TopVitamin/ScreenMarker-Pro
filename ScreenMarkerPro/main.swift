import Cocoa

// 手动启动应用
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// 强制显示调试信息
print("====== main.swift 启动 ======")
NSLog("main.swift: 应用即将启动")

// 启动应用
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)




