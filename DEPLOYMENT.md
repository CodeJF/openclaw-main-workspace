# OpenClaw Multi-Workspace Deployment

## 核心原则

OpenClaw 的 **agent 绑定的是 workspace**。
所以后续新增 agent 时，服务器端不是“给 agent git pull”，而是：

1. 看该 agent 绑定到哪个 workspace
2. pull 对应 workspace 的 git 仓库
3. `systemctl restart openclaw`

也就是说，**部署单位是 workspace repo，不是 agent 本身**。

## 当前服务器上的主业务 workspace

- `main` -> `~/.openclaw/workspace`
- `interviewer` -> `~/.openclaw/workspace-interviewer`
- `resume-intake` -> `~/.openclaw/workspace-resume-intake`

## 标准部署方式

### 单个 workspace 更新

```bash
bash /root/.openclaw/workspace/deploy/pull-and-restart-openclaw.sh /root/.openclaw/workspace main
bash /root/.openclaw/workspace/deploy/pull-and-restart-openclaw.sh /root/.openclaw/workspace-interviewer main
bash /root/.openclaw/workspace/deploy/pull-and-restart-openclaw.sh /root/.openclaw/workspace-resume-intake main
```

### 所有业务 workspace 一次性更新

```bash
bash /root/.openclaw/workspace/deploy/pull-all-workspaces.sh
```

## 新增 agent 时怎么处理

如果以后新增 agent：

- 先在 `openclaw.json` 中看它绑定的 `workspace`
- 如果是绑定到已有 workspace：不用新增仓库，pull 原 workspace 即可
- 如果是绑定到新 workspace：
  1. 给这个新 workspace 初始化独立 git 仓库或 clone 远程仓库
  2. 把新路径加入 `pull-all-workspaces.sh`
  3. restart openclaw

## 建议

- 3 个主业务 workspace 各自独立 git 仓库
- 本地开发 + push
- 服务器只 pull + restart
- 运行时目录、日志、缓存、私有配置不要进 git

## 已删除的旧测试/临时调度

- 测试天气脚本 `scripts/send_shenzhen_weather.sh`
- 天气相关 OpenClaw cron（如存在）
- `cron_send_high_scores.sh` 对应的用户 crontab 定时项
