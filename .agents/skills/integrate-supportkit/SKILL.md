---
name: integrate-supportkit
description: 在任何 Apple App 里实现、迁移或排查「联系我们 / 用户支持 / 关注我们」设置页能力时必须先加载：一律接 SupportKit（Jewel591/support-kit），⛔ 不再手写反馈邮件、微信/小红书跳转、隐私政策与 EULA 链接。覆盖标准接入姿势、CI lint（support-kit-lint）的装配证据、自定义动作控件、宿主信息架构、未知宿主 fail-closed 规则与新产品登记流程。触发词：联系我们、用户支持、反馈、关注我们、support page、SupportKit。
---

# SupportKit 接入 skill

（本文件是 skill 正身；各机器 `~/.agents/skills/integrate-supportkit/` 只放指向这里的壳。）

全线 Apple App 的支持/联系入口唯一正身是
**[Jewel591/support-kit](https://github.com/Jewel591/support-kit)**。
产品边界读仓库 `CLAUDE.md`，用法读 `README.md`；playbook 裁决在 `tech-stack TOOL-19`。

## 何时触发

- 设置页要加「联系我们 / 关注我们 / 隐私政策」
- 存量项目里看到手写 mailto 拼接、微信号复制、小红书 URL scheme 跳转
- `support-kit-lint` 红灯
- 新产品上架，要登记 Bundle ID / App Store ID
- 排查评分或分享入口不出现（多半是未知宿主 fail closed，见规则 4）

## 硬性规则

1. ⛔ 不手写支持入口。反馈邮箱、微信、小红书、官网、隐私政策、Apple 标准 EULA、
   邮件诊断信息与各动作的 fallback 全在 kit 内。
2. 接入 = lint 证据齐全（`support-kit-lint`，validation 起硬闸）：
   - canonical URL + `Up to Next Major Version`（`from:`）依赖声明
   - application target 生产源码 `import SupportKit`
   - **模块限定**构造唯一根入口 `SupportKit.SupportView(...)`
     （测试 / Preview / DEBUG / extension / 同名本地类型不算证据）
3. **宿主拥有信息架构**：每个 App 按自己的设置页结构，通过
   `SupportView(actions:style:)` 显式选择每个 surface 的动作与顺序；完整支持页可用
   `SupportView()`。Kit 不规定一级 / 二级，也不提供 placement 建议值。
4. 自定义 UI 通过 `SupportStyle` 覆盖渲染。设置行必须用
   `SupportActionRow(item) { content in ... }`，紧凑内联链接必须用
   `SupportActionLink(item) { content in ... }`。标题、图标、accessory 只通过闭包内的
   `content` 提供；两者都由 Kit 创建控件和执行动作。宿主只提供 label 视觉，⛔ 读取
   动作闭包、自己创建 Button 或重实现动作行为。
5. **未知宿主 fail closed**：联系/法务动作保留，App Store 评分与分享动作隐藏。
   新产品上架前去 kit 仓库登记 Bundle ID / App Store ID 并发新版本，
   ⛔ 不在宿主侧硬塞 App Store 链接绕过。
6. ⛔ 公开仓库与反馈模板里永不出现 secrets、API token、用户标识或账号邮箱。

## 宿主测试边界

- 宿主只测试自己的 bundle identity、各 surface 的 action 清单，以及 action 到产品页面 / 样式的映射。
- 动作控件、命中区、未知宿主 fail closed、邮件诊断拼装、URL fallback 与 App Store 动作属于 SupportKit；这些固定规则只在 Kit 包测试一次。
- 不在 XCTest 中扫描 `project.pbxproj`、import、旧类型名或源码字符串；装配与旧实现残留由 `support-kit-lint` 负责。
- 不调用真实邮件、URL scheme 或 App Store。若多个 App 复制同一个动作 fake，先把缺失接缝收回 Kit。
