# Auto366 UI 框架模板

这是一个从 Auto366 项目中提取的精简 UI 框架模板，专为重构项目参考而设计。

## 模板特点

- **精简纯净**：移除了所有业务逻辑（Shizuku、解密、缓存管理等）
- **Material Design 3**：使用 Compose Material 3 组件
- **动态主题**：支持 Android 12+ 的 Material You 动态取色
- **导航框架**：完整的底部导航 + NavHost 结构
- **可复用组件**：TopBar、SettingsItem 等通用组件

## 项目结构

```
Template/
├── app/
│   ├── build.gradle.kts              # 应用级构建配置
│   ├── proguard-rules.pro            # 代码混淆规则
│   └── src/main/
│       ├── AndroidManifest.xml       # 应用清单文件
│       ├── java/com/auto366/ui/
│       │   ├── MainActivity.kt       # 主 Activity + 导航框架
│       │   ├── component/
│       │   │   ├── CenterTopBar.kt   # 居中标题 TopBar 组件
│       │   │   └── SettingsItem.kt   # 通用设置项组件
│       │   ├── page/
│       │   │   ├── HomeScreen.kt     # 主页示例
│       │   │   └── SettingsScreen.kt # 设置页示例
│       │   └── theme/
│       │       ├── Color.kt          # 颜色定义
│       │       ├── Theme.kt          # 主题组件
│       │       └── Type.kt           # 排版定义
│       └── res/
│           ├── values/
│           │   ├── colors.xml        # XML 颜色资源
│           │   ├── strings.xml       # 字符串资源
│           │   └── themes.xml        # XML 主题定义
│           └── mipmap-hdpi/
│               └── ic_launcher.png   # 应用图标
├── gradle/
│   └── libs.versions.toml            # Gradle 版本目录
└── settings.gradle.kts               # 项目设置
```

## 技术栈

| 组件 | 版本 |
|------|------|
| AGP | 8.8.2 |
| Kotlin | 2.2.21 |
| Gradle | 9.0.0 |
| Compose BOM | 2025.12.01 |
| Navigation Compose | 2.9.3 |
| compileSdk | 35 |
| minSdk | 26 |
| targetSdk | 35 |

## 如何使用

### 1. 导入 Android Studio

1. 打开 Android Studio
2. 选择 **Open an Existing Project**
3. 选择 `Template` 目录
4. 等待 Gradle 同步完成

### 2. 自定义包名

如需修改包名，需要更新以下位置：

1. `settings.gradle.kts` 中的 `rootProject.name`
2. `app/build.gradle.kts` 中的 `namespace` 和 `applicationId`
3. `app/src/main/AndroidManifest.xml` 中的 `android:name`
4. 所有 Kotlin 文件的 `package` 声明

### 3. 添加新页面

```kotlin
// 1. 在 ui/page/ 目录下创建新页面
@Composable
fun MyNewScreen() {
    Scaffold(
        topBar = { CenterTopBar("新页面") }
    ) { innerPadding ->
        // 页面内容
    }
}

// 2. 在 MainActivity.kt 的 MainNavigation() 中添加路由
composable("my_new_route") {
    MyNewScreen()
}

// 3. 在 BottomNavigationBar 中添加导航项
NavigationBarItem(
    icon = { Icon(Icons.Outlined.Star, contentDescription = null) },
    label = { Text("新功能") },
    selected = currentDestination?.hierarchy?.any { it.route == "my_new_route" } == true,
    onClick = { onNavigateToDestination("my_new_route") }
)
```

### 4. 修改主题

在 `ui/theme/Color.kt` 中修改颜色定义：

```kotlin
val Primary = Color(0xFF6750A4)  // 修改为主色调
```

在 `ui/theme/Theme.kt` 中调整主题行为：

```kotlin
@Composable
fun TemplateTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = false,  // 禁用动态取色
    content: @Composable () -> Unit
)
```

### 5. 添加依赖

在 `gradle/libs.versions.toml` 中添加版本：

```toml
[versions]
my-library = "1.0.0"

[libraries]
my-library = { module = "com.example:my-library", version.ref = "my-library" }
```

在 `app/build.gradle.kts` 中使用：

```kotlin
dependencies {
    implementation(libs.my.library)
}
```

## 核心组件说明

### MainActivity.kt

- 使用 `enableEdgeToEdge()` 实现全面屏适配
- `MainNavigation()` 管理所有页面的路由
- `BottomNavigationBar()` 提供底部导航栏
- 使用 `saveState` 和 `restoreState` 保持页面状态

### CenterTopBar.kt

- 简洁的居中标题 TopAppBar
- 透明背景，融入页面设计
- 使用方法：`CenterTopBar("标题")`

### SettingsItem.kt

- 通用设置项组件
- 支持图标、主标题、副标题、尾部内容
- 支持 enabled/disabled 状态
- 使用方法：
```kotlin
SettingsItem(
    icon = Icons.Outlined.Info,
    title = "设置项",
    subtitle = "副标题",
    onClick = { /* 点击事件 */ },
    trailing = { /* 可选：开关、箭头等 */ }
)
```

### Theme.kt

- 支持明暗主题自动切换
- Android 12+ 支持 Material You 动态取色
- 可自定义 Light/Dark 配色方案

## 注意事项

1. **版本兼容性**：此模板使用 Kotlin 2.2.21 + AGP 8.8.2，需要 Gradle 9.0.0
2. **Color 序列化**：使用 `rememberSaveable` 保存 Color 时，需转换为 Long 值存储
3. **Shizuku 集成**：此模板不包含 Shizuku，如需集成请参考原项目 ShizukuApi.kt
4. **ViewModel**：此模板未包含 ViewModel 示例，可通过 `androidx.lifecycle.viewmodel.compose` 添加

## 从原项目参考的文件

| 原文件 | 用途 |
|--------|------|
| `Mobile/app/build.gradle.kts` | 构建配置（已精简） |
| `Mobile/gradle/libs.versions.toml` | 版本目录（已精简） |
| `Mobile/app/src/main/java/.../MainActivity.kt` | 导航框架 |
| `Mobile/app/src/main/java/.../CenterTopBar.kt` | TopBar 组件 |
| `Mobile/app/src/main/java/.../SettingsItem.kt` | 设置项组件 |
| `Mobile/app/src/main/java/.../Theme.kt` | 主题系统 |
| `Mobile/app/src/main/java/.../Color.kt` | 颜色定义 |
| `Mobile/app/src/main/java/.../Type.kt` | 排版定义 |

## 许可证

此模板仅用于项目重构参考，请遵循原项目的许可协议。
