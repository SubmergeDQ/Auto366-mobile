package com.auto366.ui.component

import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.text.font.FontWeight

/**
 * 居中标题的顶部应用栏组件
 * 使用透明背景以融入页面整体设计，标题采用加粗样式突出显示
 *
 * @param title 顶部栏显示的标题文本
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CenterTopBar(title: String) {
    TopAppBar(
        title = {
            Text(
                text = title,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
        },
        colors = TopAppBarDefaults.topAppBarColors(
            containerColor = androidx.compose.ui.graphics.Color.Transparent
        )
    )
}
