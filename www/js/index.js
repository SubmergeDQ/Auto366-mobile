/**
    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.
*/

// Wait for the deviceready event before using any of Cordova's device APIs.
// See https://cordova.apache.org/docs/en/latest/cordova/events/events.html#deviceready
document.addEventListener('deviceready', onDeviceReady, false);

function onDeviceReady() {
    // Cordova is now initialized. Have fun!

    console.log('Running cordova-' + cordova.platformId + '@' + cordova.version);
    document.getElementById('deviceready').classList.add('ready');
    startNodeProject();
}

// 监听来自 Node 端消息的回调函数
function channelListener(msg) {
    console.log('[Cordova] 收到来自Node的消息:' + msg);
}

// Node.js 引擎启动后的回调
function startupCallback(err) {
    if (err) {
        console.error('Node.js 启动失败:', err);
    } else {
        console.log('Node.js 引擎启动成功');
        // 启动成功后，立即向 Node 发送一条消息
        nodejs.channel.send('你好，Node！来自Cordova的消息。');
    }
}

// 启动 Node.js 项目的函数
function startNodeProject() {
    // 1. 设置消息监听器 (监听来自 Node 的 'message' 事件)
    nodejs.channel.setListener(channelListener);
    // 2. 启动 Node.js，入口文件为 'main.js'
    nodejs.start('main.js', startupCallback);
    // 可选：禁用 stdout/stderr 重定向到 Android logcat
    // nodejs.start('main.js', startupCallback, { redirectOutputToLogcat: false });
};