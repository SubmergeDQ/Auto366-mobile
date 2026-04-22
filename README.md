# Auto366-mobile Android 应用开发计划

## 项目目标
开发原生 Kotlin Android 应用，通过 Shizuku API 访问天学网应用数据，实现答案提取和缓存清理功能。

## 开发原则
- **渐进式开发**：每次只添加一个功能，确保构建成功后再继续
- **最小可用**：从最简版本开始，逐步增强
- **稳定优先**：确保每次改动后都能正常编译、打包、运行

## 项目结构

  ```
  com.auto366.mobile/
  ├── MainActivity.kt                    # 主活动（仅 UI 交互）
  ├── App.kt                             # Application 类（全局状态）
  ├── data/                              # 数据层
  │   ├── repository/                    # 数据仓库
  │   └── model/                         # 数据模型
  ├── domain/                            # 业务逻辑层
  │   ├── usecase/                       # 用例
  │   └── entity/                        # 业务实体
  ├── infrastructure/                    # 基础设施层
  │   ├── shizuku/                       # Shizuku 相关
  │   │   ├── ShizukuManager.kt          # Shizuku 管理器
  │   │   └── ShizukuFileService.kt      # Shizuku 文件服务
  │   ├── file/                          # 文件操作
  │   │   ├── FileFinder.kt              # 文件查找
  │   │   ├── FileCopier.kt              # 文件复制
  │   │   └── FileDecryptor.kt           # 文件解密
  │   └── parser/                        # 解析器
  │       └── AnswerParser.kt            # 答案解析器
  ├── ui/                                # UI 层
  │   ├── activity/                      # Activity
  │   ├── service/                       # Service
  │   │   └── FloatWindowService.kt      # 悬浮窗服务
  │   └── view/                          # 自定义 View
  └── util/                              # 工具类
      ├── Constants.kt                   # 常量定义
      ├── Extensions.kt                  # 扩展函数
      └── Logger.kt                      # 日志工具
  ```

