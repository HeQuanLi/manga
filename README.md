# 动漫之家 - Flutter 视频播放 APP

## 项目概述

这是一个功能完整的动漫视频播放 Flutter 应用，使用 MxdmSource 数据源提供动漫内容。

## 功能特性

### 核心功能
- ✅ **首页展示** - 多分类动漫推荐，水平滚动浏览
- ✅ **每周更新** - 按星期查看每日更新的动漫
- ✅ **搜索功能** - 快速搜索喜欢的动漫
- ✅ **详情页面** - 展示动漫详情、标签、剧集列表和相关推荐
- ✅ **视频播放** - 支持全屏播放、进度控制、音量调节

### 技术特性
- 状态管理：Provider
- 视频播放：Chewie + Video Player
- 图片缓存：Cached Network Image
- 网络请求：HTTP
- HTML 解析：HTML Parser
- 加密解密：Encrypt (AES)

## 项目结构

```
lib/
├── dto/                    # 数据传输对象
│   ├── anime_bean.dart          # 动漫基础信息
│   ├── anime_detail_bean.dart   # 动漫详情
│   ├── episode_bean.dart        # 剧集信息
│   ├── home_bean.dart           # 首页数据
│   └── video_bean.dart          # 视频数据
│
├── parse/                 # 数据源解析
│   ├── anime_source.dart        # 抽象接口
│   └── mxdm_source.dart         # MxdmSource 实现
│
├── util/                  # 工具类
│   ├── download_manager.dart    # HTTP 下载器
│   └── crypto_utils.dart        # AES 解密工具
│
├── providers/             # 状态管理
│   └── anime_provider.dart      # 动漫数据 Provider
│
├── widgets/               # 通用组件
│   ├── anime_card.dart          # 动漫卡片
│   └── common_widgets.dart      # 加载/错误组件
│
├── screens/               # 页面
│   ├── home/
│   │   └── home_screen.dart     # 首页
│   ├── week/
│   │   └── week_screen.dart     # 每周更新
│   ├── search/
│   │   └── search_screen.dart   # 搜索
│   ├── detail/
│   │   └── detail_screen.dart   # 详情页
│   └── player/
│       └── player_screen.dart   # 播放器
│
└── main.dart              # 应用入口
```

## 页面导航流程

```
MainScreen (底部导航)
├── HomeScreen (首页)
│   └── DetailScreen (详情)
│       └── PlayerScreen (播放器)
│
├── WeekScreen (时间表)
│   └── DetailScreen (详情)
│       └── PlayerScreen (播放器)
│
└── SearchScreen (搜索)
    └── DetailScreen (详情)
        └── PlayerScreen (播放器)
```

## 核心类说明

### 1. AnimeProvider
状态管理类，负责所有数据的加载和状态维护：
- `loadHomeData()` - 加载首页数据
- `loadWeekData()` - 加载每周更新
- `searchAnime()` - 搜索动漫
- `loadAnimeDetail()` - 加载详情
- `loadVideoData()` - 加载视频URL

### 2. MxdmSource
数据源实现类，从 mxdm.tv 网站解析数据：
- HTML 解析使用 html package
- 视频 URL 需要 AES 解密
- 支持多线路播放

### 3. PlayerScreen
视频播放页面：
- 使用 Chewie 作为播放器UI
- 支持全屏播放
- 自动播放
- 错误处理和重试

## 使用说明

### 1. 运行应用

```bash
# 安装依赖
flutter pub get

# 运行应用
flutter run
```

### 2. 基本使用流程

1. **首页浏览**
   - 查看多个分类的动漫推荐
   - 左右滑动浏览更多内容
   - 点击动漫卡片进入详情

2. **搜索动漫**
   - 点击底部"搜索"标签
   - 输入关键词
   - 浏览搜索结果

3. **查看详情**
   - 查看动漫封面、简介、标签
   - 选择播放线路
   - 选择剧集

4. **播放视频**
   - 自动开始播放
   - 支持全屏模式
   - 可控制进度和音量

## 依赖包

```yaml
dependencies:
  http: ^1.2.0              # HTTP 请求
  html: ^0.15.4             # HTML 解析
  encrypt: ^5.0.3           # AES 加密/解密
  provider: ^6.1.1          # 状态管理
  video_player: ^2.8.2      # 视频播放
  chewie: ^1.7.5            # 视频播放器 UI
  cached_network_image: ^3.3.1  # 图片缓存
  flutter_spinkit: ^5.2.0   # 加载动画
```

## 注意事项

### 网络权限配置

#### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

#### iOS (ios/Runner/Info.plist)
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### 性能优化建议

1. **图片加载**
   - 使用 CachedNetworkImage 自动缓存
   - 设置合理的占位符

2. **状态管理**
   - 使用 Provider 的 select 方法精确监听
   - 避免不必要的 rebuild

3. **视频播放**
   - 页面销毁时正确释放资源
   - 处理网络错误和超时

## 扩展建议

### 功能扩展
- [ ] 添加收藏功能
- [ ] 添加播放历史
- [ ] 支持下载离线观看
- [ ] 添加弹幕功能
- [ ] 用户账号系统

### 技术优化
- [ ] 使用 Dio 替代 HTTP（更强大的网络库）
- [ ] 添加本地数据库（如 Hive）
- [ ] 实现更复杂的缓存策略
- [ ] 添加错误日志上报
- [ ] 性能监控

## 开发团队

- Flutter + Dart 实现
- Material Design 3 UI
- 遵循 Flutter 最佳实践

## 许可证

本项目仅供学习交流使用。
# manga
