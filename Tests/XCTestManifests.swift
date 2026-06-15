// ================================================
// 乘风AI - 测试入口
// ================================================

import XCTest

// iOS 应用测试需包含必要的测试入口
@testable import ChengFengAI

// 测试执行入口（可选，仅用于 Linux/非 Xcode 环境）
// 在 Xcode 中运行测试时，自动扫描所有 XCTestCase 子类

// 手动运行测试列表（用于调试时可以查看有哪些测试）
let allTestClasses: [AnyObject.Type] = [
    MessageTests.self,
    AttachmentTests.self,
    ConversationTests.self,
    UserProfileTests.self,
    ModelProviderTests.self,
    APICredentialTests.self,
    TokenCounterTests.self,
    ConversationStoreTests.self,
    SettingsStoreTests.self,
    ModelSchedulerTests.self,
    IOSLocalModelServiceTests.self,
    DataIntegrityTests.self,
    ErrorHandlingTests.self
]

// 打印测试概览
func printTestOverview() {
    print("=========== 乘风AI 单元测试概览 ===========")
    print("")
    
    var totalTests = 0
    for testClass in allTestClasses {
        let className = String(describing: testClass)
        
        // 动态获取测试方法数量
        var methodCount = 0
        switch testClass {
        case is MessageTests.Type:
            methodCount = MessageTests.allTests.count
        case is AttachmentTests.Type:
            methodCount = AttachmentTests.allTests.count
        case is ConversationTests.Type:
            methodCount = ConversationTests.allTests.count
        case is UserProfileTests.Type:
            methodCount = UserProfileTests.allTests.count
        case is ModelProviderTests.Type:
            methodCount = ModelProviderTests.allTests.count
        case is APICredentialTests.Type:
            methodCount = APICredentialTests.allTests.count
        case is TokenCounterTests.Type:
            methodCount = TokenCounterTests.allTests.count
        case is ConversationStoreTests.Type:
            methodCount = ConversationStoreTests.allTests.count
        case is SettingsStoreTests.Type:
            methodCount = SettingsStoreTests.allTests.count
        case is ModelSchedulerTests.Type:
            methodCount = ModelSchedulerTests.allTests.count
        case is IOSLocalModelServiceTests.Type:
            methodCount = IOSLocalModelServiceTests.allTests.count
        case is DataIntegrityTests.Type:
            methodCount = DataIntegrityTests.allTests.count
        case is ErrorHandlingTests.Type:
            methodCount = ErrorHandlingTests.allTests.count
        default:
            methodCount = 0
        }
        
        print("[\(className)] - \(methodCount) 个测试方法")
        totalTests += methodCount
    }
    
    print("")
    print("总计: \(allTestClasses.count) 个测试类, \(totalTests) 个测试方法")
    print("==========================================")
}

// 主程序（命令行环境下可用）
printTestOverview()
