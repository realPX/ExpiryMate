# ExpiryMate

`ExpiryMate` 是一个面向中文用户的 iOS SwiftUI 小工具脚手架，聚焦“到期提醒”场景。

## 当前内容

- SwiftUI 三标签页应用骨架
- SwiftData 本地模型
- 新增 / 编辑 / 详情 / 列表 / 设置页
- 本地通知调度服务
- WidgetKit 组件骨架
- Ruby `xcodeproj` 生成脚本

## 使用方式

1. 在当前目录执行：

```bash
ruby generate_project.rb
```

2. 打开 `ExpiryMate.xcodeproj`
3. 将 `PRODUCT_BUNDLE_IDENTIFIER`、`App Group` 和签名团队改成你自己的配置
4. 运行 `ExpiryMate` target
