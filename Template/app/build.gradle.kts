plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.compose.compiler)
}

android {
    namespace = "com.auto366.template"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.auto366.template"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

dependencies {
    // Compose BOM 平台声明（必须在最前面以控制传递依赖版本）
    implementation(platform(libs.androidx.compose.bom))

    // 强制约束 androidx.core 版本，防止 BOM 拉取不兼容的高版本
    implementation("androidx.core:core:1.15.0") {
        version { strictly("1.15.0") }
    }

    // AndroidX 核心库
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.navigation.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)

    // Compose UI 组件
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.material.icons.extended)

    // Material Design 3（View 层面，提供 Theme.Material3 等 XML 主题资源）
    implementation("com.google.android.material:material:1.12.0")

    // 调试依赖
    debugImplementation(libs.androidx.compose.ui.tooling)
}
