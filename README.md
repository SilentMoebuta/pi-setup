# pi-setup

SilentMoebuta 的 pi agent 一键配置（private repo）。

## 用法

### 方式一：clone 后运行（推荐，含自定义 agents）

```bash
git clone git@github.com:SilentMoebuta/pi-setup
cd pi-setup
KSYUN_API_KEY="你的key" bash setup.sh
```

### 方式二：curl 管道（不含 agents/，仅配置 + 包）

```bash
KSYUN_API_KEY="你的key" bash -c "$(curl -fsSL https://raw.githubusercontent.com/SilentMoebuta/pi-setup/main/setup.sh)"
```

> 注：方式二不会拷贝 `agents/`（curl 无仓库文件）。要完整环境请用方式一。

## 前置条件

1. **KSYUN_API_KEY** 环境变量（金山云 GLM-5.2 的 API key）：
   ```bash
   export KSYUN_API_KEY="你的key"          # 当前 shell
   echo 'export KSYUN_API_KEY="你的key"' >> ~/.zshrc   # 持久化
   ```
   获取：https://kspmas.ksyun.com/
2. **SSH key 已添加到 GitHub**（用于 git@github.com 拉 private repo + 自维护包）

## setup.sh 做什么

1. 安装 pi agent（若未装）
2. 配置 git SSH 变通（`url.insteadOf` HTTPS→SSH，绕过 github.com:443 阻断）
3. 安装 11 个包：
   - npm: `@gotgenes/pi-subagents` / `pi-ask-user` / `pi-web-access` / `pi-powerline-footer`
   - git 自维护: `pi-superpowers` / `pi-goal` / `pi-memory` / `pi-plan-execute-gate` / `pi-hooks-system` / `pi-auto-fix-loop` / `pi-event-reminders`
4. 写入 `~/.pi/agent/settings.json`（ksyun/glm-5.2 + retry + powerline pi-goal/plan-execute 状态项）
5. 写入 `~/.pi/agent/models.json`（ksyun GLM-5.2，apiKey=`$KSYUN_API_KEY` 环境变量引用，**非明文**）
6. 拷贝自定义 agents 到 `~/.pi/agent/agents/`（coder/debugger/planner/researcher/reviewer，均用 ksyun/glm-5.2）

## 幂等性

- 可重复运行。已存在的 `settings.json` / `models.json` 不会覆盖（除非传 `--force`）。
- git config `insteadOf` 重复运行会检测已存在再跳过。
- `pi install` 本身幂等。

```bash
bash setup.sh --force   # 覆盖已有 settings.json / models.json
```

## 安全说明

- **本 repo 设为 private**：仅 SilentMoebuta 可 clone。自维护的 7 个 pi-* 包也是 private（若设了），其他机器需有对应 SSH key。
- `models.json` 用 `$KSYUN_API_KEY` 环境变量引用，**API key 不入仓**。
- `setup.sh` 在生成 models.json 时保留 `$KSYUN_API_KEY` 字面引用，pi 运行时解析环境变量。

## 自维护包一览

| 包 | 作用 | 仓库 |
|---|---|---|
| pi-superpowers | 35 个工作流 skills（TDD/调试/计划/审查等） | git@github.com:SilentMoebuta/pi-superpowers |
| pi-goal | 自主 goal + LLM judge + 状态机 | git@github.com:SilentMoebuta/pi-goal |
| pi-memory | 三层持久记忆（L1/L2/L3） | git@github.com:SilentMoebuta/pi-memory |
| pi-plan-execute-gate | Plan/Build 双模式门控 | git@github.com:SilentMoebuta/pi-plan-execute-gate |
| pi-hooks-system | 事件 hooks 框架 | git@github.com:SilentMoebuta/pi-hooks-system |
| pi-auto-fix-loop | 编辑后自动 format/typecheck/lint/test | git@github.com:SilentMoebuta/pi-auto-fix-loop |
| pi-event-reminders | 会话状态监控 + 主动提醒 | git@github.com:SilentMoebuta/pi-event-reminders |

## 升级已安装的包

setup.sh 只是首次安装。后续单包升级：

```bash
pi install git:github.com/SilentMoebuta/pi-goal   # 升级单包
# 或全部重装
for p in pi-superpowers pi-goal pi-memory pi-plan-execute-gate pi-hooks-system pi-auto-fix-loop pi-event-reminders; do
  pi install git:github.com/SilentMoebuta/$p
done
```

## License

MIT（个人使用）
