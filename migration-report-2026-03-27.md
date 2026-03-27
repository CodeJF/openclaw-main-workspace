# OpenClaw 迁移记录：本地 Mac → 阿里云 Ubuntu 24.04

**迁移时间**
- 2026-03-27

**源环境**
- 本地电脑：macOS
- 本地 OpenClaw 工作目录：`/Users/jianfengxu/.openclaw`

**目标环境**
- 阿里云服务器：`47.119.177.99`
- 系统：`Ubuntu 24.04 64位`
- SSH：
  ```bash
  ssh -i /Users/jianfengxu/Downloads/has_jianfeng_key.pem root@47.119.177.99
  ```

---

# 一、迁移目标

将本地部署的 OpenClaw 完整迁移到阿里云服务器，保证以下能力可继续使用：

1. OpenClaw 主服务正常运行
2. Feishu 通道正常连接
3. Control UI 可远程访问
4. workspace / extensions / credentials / cron / agents 迁移成功
5. `workspace-interviewer/automation/recruiter-pipeline` 相关 Python 定时任务可在服务器继续运行

---

# 二、迁移前检查

## 1. 验证远端 SSH 连通
执行：
```bash
ssh -i /Users/jianfengxu/Downloads/has_jianfeng_key.pem -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 root@47.119.177.99 'echo CONNECTED && hostname && uname -a'
```

确认：
- 可正常 SSH 登录
- 远端主机名：
  - `iZwz9bcm6p9zi5ccdu3mdeZ`

---

## 2. 盘点本地 OpenClaw
检查了：
- OpenClaw 状态
- 本地安装方式
- 配置目录
- 扩展目录
- 关键数据目录

确认本地关键信息：
- 本机 OpenClaw 版本：`2026.3.23-2`
- 安装方式：全局 npm/pnpm
- 配置主文件：
  - `~/.openclaw/openclaw.json`
- 关键目录：
  - `~/.openclaw/credentials`
  - `~/.openclaw/cron`
  - `~/.openclaw/identity`
  - `~/.openclaw/devices`
  - `~/.openclaw/extensions`
  - `~/.openclaw/agents`
  - `~/.openclaw/workspace`
  - `~/.openclaw/workspace-interviewer`

---

## 3. 盘点远端系统
检查：
- OS
- 监听端口
- 防火墙
- OpenClaw 是否已安装

结论：
- Ubuntu 24.04.4
- 仅 SSH 22 端口在监听
- `ufw` 未开启
- 远端未安装 OpenClaw

---

# 三、本地备份

## 1. 创建完整备份包
执行：
```bash
mkdir -p /Users/jianfengxu/.openclaw/workspace/migration-artifacts
backup="/Users/jianfengxu/.openclaw/workspace/migration-artifacts/openclaw-home-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
tar \
  --exclude='/Users/jianfengxu/.openclaw/logs' \
  --exclude='/Users/jianfengxu/.openclaw/browser' \
  --exclude='/Users/jianfengxu/.openclaw/media' \
  -czf "$backup" /Users/jianfengxu/.openclaw
shasum -a 256 "$backup"
```

结果：
- 备份文件：
  - `/Users/jianfengxu/.openclaw/workspace/migration-artifacts/openclaw-home-backup-20260327-161301.tar.gz`

---

# 四、远端安装 OpenClaw

## 1. 安装 Node.js / npm / OpenClaw
在阿里云执行了类似：
```bash
apt-get update
apt-get install -y curl ca-certificates gnupg
# 添加 NodeSource
apt-get install -y nodejs
npm install -g openclaw@2026.3.23-2
```

确认：
- `node -v` 正常
- `npm -v` 正常
- `openclaw --version` 正常

结果：
- Node.js：`v22.22.0`
- npm：`10.9.4`
- OpenClaw：`2026.3.23-2`

---

# 五、迁移配置与数据

## 1. 生成 Linux 版远端配置
从本地 `openclaw.json` 生成远端版配置，替换关键路径：

### 替换前
- `/Users/jianfengxu/.openclaw/workspace`
- `/Users/jianfengxu/.openclaw/workspace-interviewer`
- `/Users/jianfengxu/.openclaw/agents/...`

### 替换后
- `/root/.openclaw/workspace`
- `/root/.openclaw/workspace-interviewer`
- `/root/.openclaw/agents/...`

生成文件：
- `migration-artifacts/openclaw.remote.json`

---

## 2. 组装迁移包
打包迁移内容：
- credentials
- cron
- identity
- devices
- extensions
- agents
- workspace
- workspace-interviewer
- Linux 版 `openclaw.json`

迁移包：
- `migration-artifacts/openclaw-stage.tar.gz`

并计算 SHA256。

---

## 3. 上传迁移包到阿里云
执行：
```bash
scp -i /Users/jianfengxu/Downloads/has_jianfeng_key.pem openclaw-stage.tar.gz root@47.119.177.99:/root/openclaw-stage.tar.gz
```

并在远端验 hash。

---

## 4. 解压到远端 `/root/.openclaw`
执行了：
- 创建 `/root/.openclaw`
- 解压迁移包
- 修权限
- 写入 systemd service

---

# 六、远端服务启动与首次故障修复

## 1. 初始 systemd 启动方式有误
最初 service 写成了：
```ini
ExecStart=/usr/bin/env openclaw gateway start
```

后确认这不是前台运行网关的正确方式。

## 2. 改成正确前台启动
修正为：
```ini
ExecStart=/usr/bin/env openclaw gateway
```

---

## 3. Feishu 插件加载失败
首次启动后，`openclaw-lark` 插件报错：
- `Cannot find module './browser/crypto'`

原因：
- 本地直接拷过去的插件目录存在跨平台依赖问题
- 插件目录不适合直接从 macOS 生拷到 Ubuntu 使用

---

## 4. 解决方式：远端重装 Feishu 插件
处理方式：
1. 删除远端迁移过来的坏插件目录
2. 在远端重新安装：
   ```bash
   npm install -g @larksuite/openclaw-lark@2026.3.25
   ```
3. 再复制/部署到：
   - `/root/.openclaw/extensions/openclaw-lark`
4. 修复 owner / permissions
5. 重启 OpenClaw

结果：
- Feishu 插件恢复正常
- Feishu channel 状态恢复为 OK

---

# 七、Control UI 对外访问修复

## 问题 1：公网访问不到 18789
### 现象
- 安全组已放行 18789
- 但浏览器无法访问阿里云 Control UI

### 原因
`gateway.bind` 仍是：
- `loopback`

实际监听只有：
- `127.0.0.1:18789`

### 修复
改远端配置为公网监听：
```json
"gateway": {
  "bind": "custom",
  "customBindHost": "0.0.0.0"
}
```

结果：
- `0.0.0.0:18789` 开始监听
- `http://47.119.177.99:18789/` 可访问

---

## 问题 2：Control UI 报 `origin not allowed`
### 原因
`gateway.controlUi.allowedOrigins` 只允许：
- localhost
- 127.0.0.1
- 0.0.0.0

没包含公网地址。

### 修复
增加：
- `http://47.119.177.99:18789`
- `http://47.119.177.99`

---

## 问题 3：Control UI 报 `requires device identity`
### 原因
纯 HTTP 公网访问不是安全上下文，OpenClaw 默认拒绝。

### 临时修复
为了先能连上，开启：
```json
"gateway": {
  "controlUi": {
    "allowInsecureAuth": true,
    "dangerouslyDisableDeviceAuth": true
  }
}
```

说明：
- 这是临时放开
- 适合当前排障和迁移验证
- 不建议长期公网裸跑

---

## 问题 4：Control UI 报 `gateway token missing`
### 处理
读取远端网关 token，并通过 UI 输入 token 或 URL 带 token 完成连接。

最终结果：
- Control UI 成功连接

---

# 八、模型出站网络问题修复

## 问题
Feishu 能收到消息，但模型调用失败，报：
- `LLM request failed`
- `fetch failed`

## 诊断结果
远端网络测试发现：
- `api.openai.com`：超时
- `api.minimaxi.com`：可访问

## 处理
将远端默认模型从 `gpt-5.4` 切换为：
- `minimax-portal/MiniMax-M2.5`

结果：
- 阿里云上的机器人恢复可回答能力
- 避开了 OpenAI 出站超时问题

---

# 九、Python 定时任务环境修复（recruiter-pipeline）

目标目录：
- `/root/.openclaw/workspace-interviewer/automation/recruiter-pipeline`

---

## 1. 初始检查结论
发现以下问题：

### 问题 A：脚本仍写死本地路径
`run_pipeline.sh` 中原内容：
```bash
cd /Users/jianfengxu/.openclaw/workspace-interviewer
```

`cron_send_high_scores.sh` 中原内容：
```bash
cd /Users/jianfengxu/.openclaw/workspace-interviewer/automation/recruiter-pipeline
```

### 问题 B：迁移过来的 `.venv` 是坏的
里面仍然指向 macOS Python：
- `/opt/homebrew/opt/python@3.13/bin/python3.13`

### 问题 C：cron 任务定义中仍使用本地路径
`/root/.openclaw/cron/jobs.json` 里仍然有：
- `/Users/jianfengxu/.openclaw/workspace-interviewer/...`

### 问题 D：high score 配置未完全迁净
`config.highscore.json` 里 `pipeline.jdDir` / `pipeline.runtimeDir` 仍然是本地路径。

---

## 2. 修复动作

### 修复脚本路径
修正：
- `run_pipeline.sh`
- `cron_send_high_scores.sh`

从：
- `/Users/jianfengxu/...`

改为：
- `/root/.openclaw/...`

---

### 修复配置文件
修正：
- `config.highscore.json`
- `config.local.json` 已经是 Linux 路径，无需大改

---

### 修复 cron job 定义
将 `jobs.json` 中所有：
- `/Users/jianfengxu/.openclaw/workspace-interviewer/...`

替换为：
- `/root/.openclaw/workspace-interviewer/...`

---

### 删除坏的虚拟环境并重建
发现 Ubuntu 缺少 `python3.12-venv`，因此先安装：

```bash
apt-get update
apt-get install -y python3.12-venv python3-pip
```

然后执行：
```bash
rm -rf .venv
python3 -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r requirements.txt
```

安装依赖：
- `pypdf`
- `openpyxl`
- `httpx`

---

## 3. 手工验证脚本运行

### 验证 `run_pipeline.sh`
执行：
```bash
bash automation/recruiter-pipeline/run_pipeline.sh
```

结果：
- 退出码：`0`
- 执行成功

示例输出：
- 本次处理：1 封
- 预筛跳过 LLM：1 封
- 剩余未读：0 封

---

### 验证 `cron_send_high_scores.sh`
首次执行失败，原因：
- `config.highscore.json` 里的 `pipeline.jdDir` 仍是本地路径
- `runtime/logs` 目录不存在

修复后：
- 修正 `pipeline.jdDir`
- 修正 `pipeline.runtimeDir`
- 创建：
  - `runtime/logs`
  - `runtime/state`
  - `runtime/processed`
  - `runtime/cache`
  - `runtime/reports`

再次执行：
```bash
bash ./cron_send_high_scores.sh
```

结果：
- 退出码：`0`
- 执行成功
- `runtime/logs/cron.log` 正常写入

---

# 十、迁移后清洁收尾

## 1. 修复代码里的硬编码路径
修正：
- `core/query_ops.py`

原路径：
- `/Users/jianfengxu/.openclaw/workspace-interviewer/automation/recruiter-pipeline/run_pipeline.sh`

改为：
- `/root/.openclaw/workspace-interviewer/automation/recruiter-pipeline/run_pipeline.sh`

---

## 2. 归档 macOS 专用文件
归档到：
- `migration-archive/`

文件：
- `install_launchd.sh`
- `com.hichs.interviewer-recruiter-pipeline.plist`

说明：
- 不删除
- 但从主运行目录移走，避免误用

---

## 3. 清理 `.DS_Store`
删除了项目目录中的 `.DS_Store` 文件。

---

# 十一、当前阶段状态（截至现在）

## OpenClaw 主服务
- 已迁移完成
- 远端运行正常

## Feishu
- 正常连接
- 可接收并处理消息

## Control UI
- 可通过公网访问
- 当前可连接
- 目前处于**临时放宽安全校验**状态

## 默认模型
- 已切换到 `MiniMax-M2.5`
- 原因：阿里云到 OpenAI 出站超时

## Python 定时任务环境
- 已修复完成
- `run_pipeline.sh` 已实跑通过
- `cron_send_high_scores.sh` 已实跑通过

## recruiter-pipeline
- 主运行链路已迁净
- 剩余本地路径主要只存在于：
  - 历史缓存
  - 示例配置
  - 已归档的 macOS 文件

---

# 十二、当前仍保留的临时/待优化项

## 1. Control UI 安全配置还是临时态
当前为了让 HTTP 公网先能用，开启了：
- `allowInsecureAuth`
- `dangerouslyDisableDeviceAuth`

后续建议：
1. 配置 HTTPS
2. 关闭以上危险开关
3. 配置 `gateway.auth.rateLimit`

---

## 2. OpenAI 出站问题未解决
当前绕过方式：
- 默认模型已切到 MiniMax

后续如需恢复 `gpt-5.4`：
- 需要单独排查阿里云到 OpenAI 的出站网络问题

---

## 3. 示例/历史缓存未彻底清洗
当前不影响运行，但如果要彻底洁净：
- 可后续再清理示例文件与历史缓存中的旧路径字符串

---

# 十三、最终结论

本次迁移已经完成到以下阶段：

## 已完成
- OpenClaw 主服务迁移成功
- Feishu 通道迁移成功
- Control UI 连通成功
- Python 定时任务环境迁移并修复成功
- `recruiter-pipeline` 主运行链路迁移成功
- 两条关键脚本均已人工执行验证通过

## 当前可认为
**阿里云服务器已经可以作为主 OpenClaw 运行节点正常使用。**
