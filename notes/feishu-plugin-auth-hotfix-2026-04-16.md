# Feishu 插件授权热修说明（2026-04-16）

服务器：`root@47.119.177.99`
插件目录：`/root/.openclaw/extensions/openclaw-lark`
服务管理：**仅使用 `systemctl` 管理 `openclaw`**

## 背景问题

线上 Feishu 插件把“普通用户给自己授权”和“普通用户用自己已授权的用户态工具”错误地实现成了 owner-only，导致：

1. 非 owner 用户首次使用用户态工具时，无法正常发起 OAuth 授权
2. 即使完成授权，也会在真正调用用户态工具时再次被 owner-check 拦住
3. 用户说“给我授权入口/一键授权”时，系统有时只会解释 OAuth URL，而不是直接发授权卡

## 目标行为

- 普通用户可以为**自己**完成 OAuth 授权
- 普通用户可以使用**自己**的 UAT 调用用户态工具
- 普通用户可以执行“批量授权/一键授权全部自己所需 scope”
- 用户明确说“授权/给我授权入口/一键授权”等时，直接走真实授权卡，不再手工解释 URL
- 多用户 token 并存，互不覆盖

## 修改文件

### 1) `src/tools/oauth.js`

#### 修改前
`executeAuthorize()` 一开始就对当前 sender 做 owner-check：

- 非 owner → 直接返回 `permission_denied`
- 导致普通用户永远无法进入 Device Flow

#### 修改后
移除了 `executeAuthorize()` 中的 owner-only 拦截。

#### 影响
- 普通用户可为自己发起 Device Flow
- 不影响 token 按 `appId + senderOpenId` 隔离存储

---

### 2) `src/core/tool-client.js`

#### 修改前
`invokeAsUser()` 中存在：

```js
await assertOwnerAccessStrict(this.account, this.sdk, userOpenId);
```

这会导致：
- 普通用户即使已经完成授权
- 在真正调用用户态工具时仍被 owner-only 拦截

#### 修改后
移除了这句 owner-check。

#### 影响
- 普通用户授权后可以真正使用用户态工具
- 用户态工具按用户自己的 token 正常执行

---

### 3) `src/tools/oauth-batch-auth.js`

#### 修改内容
把工具描述从“应用 owner/管理员导向”调整为“当前用户自助一键授权自己尚未授权的全部已开通 user scopes”。

#### 影响
- 产品语义与真实行为一致
- 减少后续误判

---

### 4) `src/messaging/inbound/dispatch.js`

#### 修改内容
增加自然语言授权意图识别：

匹配类似表达：
- 给我授权入口
- 发起授权
- 一键授权
- 批量授权
- 授权所有权限
- 全量授权

命中后，强制向 agent 注入系统指令：
- 立即调用 `feishu_oauth_batch_auth`
- 不要手工解释 OAuth URL
- 若已授权则直接告知用户

#### 影响
- 用户明确要求授权时，直接出真实授权卡
- 不再出现“嘴上给一个 OAuth URL 模板”的体验问题

## 验证结果

已验证通过：

1. 非 owner 用户可触发 `feishu_oauth_batch_auth`
2. Device Flow 授权卡可正常发出
3. 授权成功后 token 可保存
4. synthetic message 可正常触发自动重试
5. 后续 `feishu_get_user`、`feishu_bitable_app_table_record` 等用户态工具可正常执行
6. 多用户 token 互不覆盖（按 `appId + senderOpenId` 隔离）

## 运维注意事项

### 重要
这台阿里云服务器上的 OpenClaw **以后只用 systemd 管理**：

```bash
systemctl status openclaw
systemctl restart openclaw
journalctl -u openclaw -f
```

**不要再使用：**
- `nohup openclaw gateway ...`
- 手动拉起额外进程
- 其他 ad-hoc 启动方式

原因：此前已出现手动进程与 systemd 管理的 `openclaw.service` 双实例冲突、抢占端口 `18789`、导致重启异常的问题。

## 风险与后续

### 风险
- 后续升级 OpenClaw 或 openclaw-lark 插件时，这些热修可能被覆盖
- `dispatch.js` 的“授权意图强路由”属于体验增强逻辑，未来上游若改路由层，需重新验证

### 建议
升级前后重点复查以下文件：
- `src/tools/oauth.js`
- `src/core/tool-client.js`
- `src/tools/oauth-batch-auth.js`
- `src/messaging/inbound/dispatch.js`

### 建议回归测试
1. 非 owner 未授权时调用用户态工具 → 应发授权卡
2. 非 owner 完成授权后再调用 → 应成功
3. 非 owner 说“给我授权入口” → 应直接发卡
4. 两个不同用户分别授权 → token 不互相覆盖
5. owner 用户路径仍正常
