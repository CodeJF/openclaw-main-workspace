# OpenClaw 云端 Gateway ↔ 本地 macOS Node 配对脚本

目标：让**云端 OpenClaw**可以通过 **SSH 反向隧道**访问并操作**本地 macOS**。

## 架构

- 云端 Gateway：`47.119.177.99`
- 云端本地隧道入口：`127.0.0.1:18790`
- 本地 macOS node host：`127.0.0.1:18791`
- SSH 反向隧道：`cloud 127.0.0.1:18790 -> mac 127.0.0.1:18791`

## 文件

- `cloud_show_token.sh`
  - 在云端打印 gateway token / devices / nodes 状态
- `cloud_approve_latest_node.sh`
  - 在云端查看 pending node 请求，并给出 approve 命令
- `mac_pair_to_cloud.sh`
  - 在本地 Mac 上启动 node host、建立 SSH 反向隧道、以前台方式启动 node 连接云端

## 使用步骤

### 1. 上传脚本到云端（一次即可）

本地执行：

```bash
scp -i /Users/jianfengxu/Downloads/has_jianfeng_key.pem -r \
  /Users/jianfengxu/.openclaw/workspace/scripts/openclaw-node-pairing \
  root@47.119.177.99:/root/
```

### 2. 在云端查看 token

```bash
ssh -i /Users/jianfengxu/Downloads/has_jianfeng_key.pem root@47.119.177.99 \
  'bash /root/openclaw-node-pairing/cloud_show_token.sh'
```

### 3. 在本地 Mac 发起 node 连接

把上一步打印出来的 token 填进去：

```bash
chmod +x /Users/jianfengxu/.openclaw/workspace/scripts/openclaw-node-pairing/*.sh
GATEWAY_TOKEN='<云端打印出的token>' \
  bash /Users/jianfengxu/.openclaw/workspace/scripts/openclaw-node-pairing/mac_pair_to_cloud.sh
```

### 4. 在云端批准 pending node

```bash
ssh -i /Users/jianfengxu/Downloads/has_jianfeng_key.pem root@47.119.177.99 \
  'bash /root/openclaw-node-pairing/cloud_approve_latest_node.sh'
```

如果看到 pending request，就复制脚本打印出的 approve 命令执行。

### 5. 验证

云端执行：

```bash
openclaw nodes status
openclaw nodes list
```

如果成功，应该能看到你的 macOS node 在线。

## 说明

1. `mac_pair_to_cloud.sh` 里 `openclaw node run` 是以前台运行的，方便你看到配对日志。
2. SSH 反向隧道是后台运行的；如果想停掉，手动 kill 对应 ssh 进程即可。
3. 这个方案的关键是：
   - **Mac 主动出站**连云端
   - 云端不直接打 NAT 内网里的 Mac
4. 若本机 `openclaw node install/restart` 因 launchd 环境失败，也可以直接让脚本前台起 `node run`，本方案已经这么做了。
