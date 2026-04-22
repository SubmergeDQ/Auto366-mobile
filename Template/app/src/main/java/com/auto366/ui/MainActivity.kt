package com.auto366.ui

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.auto366.ui.page.HomeScreen
import com.auto366.ui.page.SettingsScreen
import com.auto366.ui.theme.TemplateTheme

/**
 * 应用主 Activity
 * 初始化 Compose 界面并配置导航系统和底部导航栏
 */
class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        
        setContent {
            TemplateTheme {
                Surface(
                    modifier = Modifier,
                    color = MaterialTheme.colorScheme.background
                ) {
                    MainNavigation()
                }
            }
        }
    }
}

/**
 * 主导航结构组件
 * 管理 Home 和 Settings 两个顶层页面的切换，包含底部导航栏
 */
@Composable
fun MainNavigation() {
    val navController = rememberNavController()
    
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination
    
    Scaffold(
        bottomBar = {
            BottomNavigationBar(
                currentDestination = currentDestination,
                onNavigateToDestination = { route ->
                    navController.navigate(route) {
                        popUpTo(navController.graph.findStartDestination().id) {
                            saveState = true
                        }
                        launchSingleTop = true
                        restoreState = true
                    }
                }
            )
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = "home",
            modifier = Modifier.padding(innerPadding)
        ) {
            composable("home") {
                HomeScreen()
            }
            
            composable("settings") {
                SettingsScreen()
            }
        }
    }
}

/**
 * 底部导航栏组件
 */
@Composable
private fun BottomNavigationBar(
    currentDestination: androidx.navigation.NavDestination?,
    onNavigateToDestination: (String) -> Unit
) {
    NavigationBar {
        NavigationBarItem(
            icon = { Icon(Icons.Outlined.Home, contentDescription = null) },
            label = { Text("主页") },
            selected = currentDestination?.hierarchy?.any { it.route == "home" } == true,
            onClick = { onNavigateToDestination("home") }
        )
        
        NavigationBarItem(
            icon = { Icon(Icons.Outlined.Settings, contentDescription = null) },
            label = { Text("设置") },
            selected = currentDestination?.hierarchy?.any { it.route == "settings" } == true,
            onClick = { onNavigateToDestination("settings") }
        )
    }
}
