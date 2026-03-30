# OpenClaw 云端 Gateway ↔ 本地 macOS Node 配对脚本

目标：让**本地 macOS 上的 OpenClaw node**通过 **SSH 本地转发**连接到**云端 OpenClaw Gateway**。

## 正确拓扑

- 云端 OpenClaw Gateway：`127.0.0.1:18789`（运行在 `47.119.177.99`）
- 本地 SSH 转发入口：`127.0.0.1:18790`
- SSH 本地转发：`本地 127.0.0.1:18790 -> 云端 127.0.0.1:18789`
- 本地 node 连接：`openclaw node run --host 127.0.0.1 --port 18790`

## 文件

- `cloud_show_token.sh`
  - 在云端打印 gateway token / gateway 监听 / devices / nodes 状态
- `cloud_approve_latest_node.sh`
  - 在云端查看 pending node 请求，并给出 approve 命令
- `mac_pair_to_cloud.sh`
  - 在本地 Mac 上建立 SSH 本地转发，并以前台方式启动 node 连接云端

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

这个脚本会先建立：

```bash
ssh -i /Users/jianfengxu/Downloads/has_jianfeng_key.pem -N -L 18790:127.0.0.1:18789 root@47.119.177.99
```

然后执行：

```bash
OPENCLAW_GATEWAY_TOKEN='<token>' openclaw node run --host 127.0.0.1 --port 18790 --display-name 'Master-Mac'
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

1. `mac_pair_to_cloud.sh` 最后是以前台运行的，方便你看到配对日志。
2. 如果本地 `18790` 已被占用，可改：

```bash
LOCAL_FORWARD_PORT=18792 GATEWAY_TOKEN='<token>' bash ./mac_pair_to_cloud.sh
```

3. 本方案的关键是：
   - **本地 node 主动连接云端 gateway**
   - 通过 SSH 本地转发，把远端 gateway 映射成本地可访问端口
