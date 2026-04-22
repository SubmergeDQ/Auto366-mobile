package com.auto366.ui.page

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.NavigationArrow
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.auto366.ui.component.CenterTopBar
import com.auto366.ui.component.SettingsItem

/**
 * 设置页示例
 * 展示如何使用 SettingsItem 组件构建设置列表
 */
@Composable
fun SettingsScreen() {
    Scaffold(
        topBar = { CenterTopBar("设置") }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
        ) {
            // 示例设置项（仅展示 UI 框架，无实际业务逻辑）
            SettingsItem(
                icon = Icons.Outlined.Info,
                title = "示例设置项",
                subtitle = "这是一个示例",
                onClick = { /* TODO: 实现业务逻辑 */ },
                trailing = { /* 可选：添加箭头、开关等 */ }
            )

            Spacer(modifier = Modifier.height(8.dp))
        }
    }
}
