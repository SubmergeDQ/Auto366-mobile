package com.auto366.ui.page

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.auto366.ui.component.CenterTopBar

/**
 * 主页示例
 * 展示如何使用 TopBar + Scaffold 的基础页面结构
 */
@Composable
fun HomeScreen() {
    Scaffold(
        topBar = { CenterTopBar("主页") }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
            contentAlignment = Alignment.Center
        ) {
            Text("主页内容")
        }
    }
}
