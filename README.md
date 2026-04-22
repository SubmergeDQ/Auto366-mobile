# Auto366-mobile

原生 Kotlin Android 应用，通过 Shizuku API 访问天学网应用数据，实现答案提取和缓存清理功能。

## 项目简介

Auto366-mobile 是一个辅助工具应用，主要功能包括：
- **答案提取**：通过 Shizuku 访问天学网应用数据，提取题目答案并显示在悬浮窗中
- **缓存清理**：清理天学网应用缓存和本应用缓存

## 开发原则

- **渐进式开发**：每次只添加一个功能，确保构建成功后再继续
- **最小可用**：从最简版本开始，逐步增强
- **稳定优先**：确保每次改动后都能正常编译、打包、运行
- **模块化设计**：清晰的分层架构，便于维护和扩展

## 开发阶段

### 阶段 1：集成 UI 模板 
**目标**：使用现成的 UI 模板，快速搭建应用框架

**主要任务**：
- 复制 `Template/` 目录到 `Mobile/`
- 修改包名为 `com.auto366.mobile`
- 在模板基础上扩展模块化目录结构
- 修改 HomeScreen 添加功能入口（答案提取开关、清理缓存按钮）
- 验证构建，确保能打包、能运行、不闪退

**完成标准**：
-  Gradle 构建成功
-  生成 APK 文件
-  APK 可安装
-  应用打开不闪退
-  UI 框架正常工作
-  底部导航可切换页面

---

### 阶段 2：Shizuku 基础集成
**目标**：集成 Shizuku API，实现权限管理和文件访问能力

**主要任务**：
- 添加 Shizuku 依赖（使用 Version Catalog）
- 配置权限和 Provider
- 实现 `ShizukuManager`（状态检查、权限请求）
- 实现 `ShizukuFileService`（文件操作接口）
- 在 ViewModel 中集成 Shizuku 状态管理

**完成标准**：
-  Shizuku 依赖无冲突
-  能检测 Shizuku 状态
-  能请求并获得授权
-  构建成功，不闪退

---

### 阶段 3：文件读取功能
**目标**：实现查找和复制天学网应用文件

**主要任务**：
- 实现 `FileFinder`（查找 page1.js.u3enc 文件）
- 实现 `FileCopier`（通过 Shizuku 复制文件）
- 创建 `FindAndCopyFileUsecase`（业务逻辑封装）
- 测试文件查找和复制功能

**完成标准**：
-  能通过 Shizuku 访问目标目录
-  能找到 `page1.js.u3enc` 文件
-  能复制文件到缓存目录
-  构建成功，不闪退

---

### 阶段 4：文件解密功能
**目标**：解密 .u3enc 加密文件

**主要任务**：
- 实现 `FileDecryptor`（AES-CBC 解密）
- 创建 `DecryptFileUsecase`（业务逻辑封装）
- 使用示例文件测试解密功能

**完成标准**：
-  解密算法正确
-  能解密示例文件
-  解密结果与预期一致
-  构建成功，不闪退

---

### 阶段 5：答案提取功能
**目标**：从解密的 page1.js 中提取答案

**主要任务**：
- 创建数据模型（`Answer`, `PageConfig`）
- 实现 `AnswerParser`（解析 page1.js）
- 创建 `ExtractAnswersUsecase`（业务逻辑封装）
- 实现答案格式化输出（"1. Visit family members.\n2. ..."）

**完成标准**：
-  能正确解析 page1.js
-  能提取所有答案
-  格式化输出正确
-  构建成功，不闪退

---

### 阶段 6：悬浮窗实现
**目标**：实现可拖动、可调节大小的悬浮窗

**主要任务**：
- 添加悬浮窗权限
- 创建 `FloatWindowService`（Service）
- 实现悬浮窗 UI（布局、拖动、大小调节）
- 创建 `FloatWindowManager`（控制管理器）
- 在 HomeScreen 中添加开关控制

**完成标准**：
-  悬浮窗能显示
-  悬浮窗置顶
-  悬浮窗可拖动
-  悬浮窗大小可调
-  开关能控制显示/隐藏
-  构建成功，不闪退

---

### 阶段 7：整合答案显示
**目标**：将提取的答案显示在悬浮窗中

**主要任务**：
- 创建 `AnswerRepository`（数据仓库）
- 创建 `AnswerViewModel`（UI 层核心）
- 连接数据流（查找→解密→提取→显示）
- 优化显示效果（加载状态、错误提示）

**完成标准**：
-  悬浮窗显示答案正确
-  完整流程无错误
-  数据流清晰，模块分离
-  构建成功，不闪退

---

### 阶段 8：清理缓存功能
**目标**：实现清理天学网缓存和本应用缓存

**主要任务**：
- 实现 `CacheCleaner`（清理逻辑）
- 创建 `CleanCacheUsecase`（业务逻辑封装）
- 在 UI 中添加清理按钮和确认对话框
- 在 ViewModel 中集成清理功能

**完成标准**：
-  能清理天学网缓存
-  能清理本应用缓存
-  清理结果有反馈
-  构建成功，不闪退

---

### 阶段 9：优化和完善
**目标**：提升代码质量、性能和用户体验

**主要任务**：
- 完善异常处理和错误提示
- 性能优化（后台线程、缓存机制）
- 用户体验优化（加载动画、UI 样式）
- 代码质量提升（单元测试、代码审查）

---

### 阶段 10：打包发布
**目标**：生成 Release APK，准备发布

**主要任务**：
- 配置签名（Keystore）
- 优化 ProGuard/R8 规则
- 生成 Release APK
- 多设备测试
- 编写使用说明和文档

---

## 架构设计

### 分层架构
```
┌─────────────────────────────────────┐
│           UI Layer (ui/)            │  ← MainActivity, ViewModel, Service
├─────────────────────────────────────┤
│        Domain Layer (domain/)       │  ← UseCases, Business Logic
├─────────────────────────────────────┤
│         Data Layer (data/)          │  ← Repository, Models
├─────────────────────────────────────┤
│    Infrastructure Layer (infra/)    │  ← Shizuku, File, Parser
├─────────────────────────────────────┤
│         Utils Layer (util/)         │  ← Constants, Extensions, Logger
└─────────────────────────────────────┘
```

### 模块职责
1. **UI 层 (ui/)**: 处理用户交互，显示数据
2. **Domain 层 (domain/)**: 纯 Kotlin 业务逻辑，不依赖 Android
3. **Data 层 (data/)**: 数据模型和仓库
4. **Infrastructure 层 (infrastructure/)**: 具体实现（Shizuku、文件操作等）
5. **Utils 层 (util/)**: 工具类、常量、扩展函数

### 数据流
```
UI (MainActivity)
  ↓
ViewModel (ui/viewmodel/)
  ↓
UseCase (domain/usecase/)
  ↓
Repository (data/repository/)
  ↓
Infrastructure (infrastructure/)
  ↓
External APIs (Shizuku, File System)
```

---

## 🛠️ 技术栈

| 组件 | 版本 |
|------|------|
| AGP | 8.8.2 |
| Kotlin | 2.2.21 |
| Gradle | 9.0.0 |
| Compose BOM | 2025.12.01 |
| Navigation Compose | 2.9.3 |
| Shizuku API | 13.1.5 |
| compileSdk | 35 |
| minSdk | 26 |
| targetSdk | 35 |

---

## 项目结构

```
Mobile/
├── app/
│   ├── build.gradle.kts              # 应用级构建配置
│   ├── proguard-rules.pro            # 代码混淆规则
│   └── src/main/
│       ├── AndroidManifest.xml       # 应用清单文件
│       ├── java/com/auto366/
│       │   ├── ui/                   # UI 层
│       │   │   ├── MainActivity.kt
│       │   │   ├── component/
│       │   │   ├── page/
│       │   │   ├── service/
│       │   │   └── viewmodel/
│       │   ├── data/                 # 数据层
│       │   ├── domain/               # 业务逻辑层
│       │   ├── infrastructure/       # 基础设施层
│       │   └── util/                 # 工具类
│       └── res/                      # 资源文件
├── gradle/
│   └── libs.versions.toml            # Gradle 版本目录
└── settings.gradle.kts               # 项目设置
```

---

## 📄 许可证

本项目采用 **GNU General Public License v3.0** 许可证。详见 [LICENSE](LICENSE) 文件。

Copyright (C) 2025 Auto366-mobile

这是一个自由软件，您可以根据 GNU GPL v3 许可证的条款重新分发和/或修改它。
本项目不提供任何担保，详见许可证全文。

---

## ⚠️ 注意事项

1. **Shizuku 要求**：需要设备已安装 Shizuku 并授权
2. **权限要求**：需要授予悬浮窗权限和文件访问权限
3. **兼容性**：仅支持 Android 8.0+ (API 26+)

