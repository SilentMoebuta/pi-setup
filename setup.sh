#!/bin/bash
# Pi Agent 一键配置（SilentMoebuta 自维护环境）
# 仓库: https://github.com/SilentMoebuta/pi-setup (public)
#
# 用法:  curl -fsSL https://raw.githubusercontent.com/SilentMoebuta/pi-setup/main/setup.sh | bash
#   或:  git clone https://github.com/SilentMoebuta/pi-setup && bash pi-setup/setup.sh
#
# 幂等: 可重复运行，已存在的配置不覆盖（除非传 --force）。
set -e

FORCE=0
[ "$1" = "--force" ] && FORCE=1

echo "========================================"
echo " Pi Agent 环境一键配置"
echo " Provider: ksyun / glm-5.2"
echo "========================================"
echo ""

# -------- 0. 前置检查: KSYUN_API_KEY --------
if [ -z "$KSYUN_API_KEY" ]; then
  echo "⚠️  未检测到 KSYUN_API_KEY 环境变量。"
  echo "   请先设置:  export KSYUN_API_KEY=\"你的金山云 API key\""
  echo "   获取地址: https://kspmas.ksyun.com/"
  echo ""
  echo "   （models.json 用 \$KSYUN_API_KEY 引用，不会明文入仓）"
  echo ""
  read -p "是否继续安装（models.json 仍会生成，但需稍后补 KSYUN_API_KEY）? [y/N] " yn
  [ "$yn" != "y" ] && [ "$yn" != "Y" ] && { echo "已取消。"; exit 1; }
fi

mkdir -p ~/.pi/agent

# -------- 1. 安装 pi --------
echo "[1/6] 安装 pi agent..."
if ! command -v pi &> /dev/null; then
  curl -fsSL https://pi.dev/install.sh | sh
  # 写入 PATH（幂等：避免重复追加）
  for rc in ~/.bashrc ~/.zshrc; do
    [ -f "$rc" ] && ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$rc" 2>/dev/null && \
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
  done
  export PATH="$HOME/.local/bin:$PATH"
  echo "  ✓ pi 已安装"
else
  echo "  ✓ pi 已安装，跳过"
fi

# -------- 2. git SSH 变通（可选：仅当 HTTPS 访问 github.com 被阻断时）--------
echo ""
echo "[2/6] 检查 github.com 连通性（部分网络阻断 443 端口，需 SSH 变通）..."
if curl -sfI --max-time 8 https://github.com >/dev/null 2>&1; then
  echo "  ✓ HTTPS 可访 github.com，无需 SSH 变通"
else
  echo "  ⚠️  HTTPS 访问 github.com 失败，配置 git SSH 变通（HTTPS → SSH）..."
  if [ ! -f ~/.ssh/id_ed25519 ] && [ ! -f ~/.ssh/id_rsa ]; then
    echo "  ⚠️  未检测到 SSH key。SSH 变通需要 SSH key 已添加到 GitHub。"
    echo "     生成: ssh-keygen -t ed25519 -C "your_email@example.com"，然后添加到 GitHub Settings。"
    echo "     跳过 SSH 变通（pi install git: 可能失败）"
  else
    EXISTING=$(git config --global --get url."git@github.com:".insteadOf 2>/dev/null || true)
    if [ -z "$EXISTING" ]; then
      git config --global url."git@github.com:".insteadOf "https://github.com/"
      echo "  ✓ 已配置 url.insteadOf（HTTPS → SSH）"
    else
      echo "  ✓ 已存在 insteadOf 配置，跳过"
    fi
  fi
fi

# -------- 3. 安装所有包（11 个）--------
echo ""
echo "[3/6] 安装 pi 包（11 个）..."

packages=(
  "npm:@gotgenes/pi-subagents"
  "npm:pi-ask-user"
  "npm:pi-web-access"
  "npm:pi-powerline-footer"
  "git:github.com/SilentMoebuta/pi-superpowers"
  "git:github.com/SilentMoebuta/pi-goal"
  "git:github.com/SilentMoebuta/pi-memory"
  "git:github.com/SilentMoebuta/pi-plan-execute-gate"
  "git:github.com/SilentMoebuta/pi-hooks-system"
  "git:github.com/SilentMoebuta/pi-auto-fix-loop"
  "git:github.com/SilentMoebuta/pi-event-reminders"
)

for pkg in "${packages[@]}"; do
  echo "  安装 $pkg ..."
  pi install "$pkg"
done

# -------- 4. 写入 settings.json --------
echo ""
echo "[4/6] 写入 settings.json..."
SETTINGS=~/.pi/agent/settings.json
if [ -f "$SETTINGS" ] && [ "$FORCE" -ne 1 ]; then
  echo "  ⚠️  $SETTINGS 已存在，跳过（用 --force 覆盖）"
else
  cat > "$SETTINGS" << 'SETTINGS_EOF'
{
  "theme": "light",
  "defaultProvider": "ksyun",
  "defaultModel": "glm-5.2",
  "defaultThinkingLevel": "high",
  "retry": {
    "enabled": true,
    "maxRetries": 5,
    "baseDelayMs": 4000,
    "provider": {
      "maxRetries": 0,
      "maxRetryDelayMs": 60000
    }
  },
  "powerline": {
    "customItems": [
      {
        "id": "pi-goal",
        "statusKey": "pi-goal",
        "position": "right",
        "color": "accent"
      },
      {
        "id": "plan-execute",
        "statusKey": "plan-execute",
        "position": "right",
        "color": "warning",
        "prefix": "mode",
        "hideWhenMissing": false
      }
    ]
  },
  "packages": [
    "npm:@gotgenes/pi-subagents",
    "npm:pi-ask-user",
    "npm:pi-web-access",
    "npm:pi-powerline-footer",
    "git:github.com/SilentMoebuta/pi-superpowers",
    "git:github.com/SilentMoebuta/pi-goal",
    "git:github.com/SilentMoebuta/pi-memory",
    "git:github.com/SilentMoebuta/pi-plan-execute-gate",
    "git:github.com/SilentMoebuta/pi-hooks-system",
    "git:github.com/SilentMoebuta/pi-auto-fix-loop",
    "git:github.com/SilentMoebuta/pi-event-reminders"
  ]
}
SETTINGS_EOF
  echo "  ✓ settings.json 已写入"
fi

# -------- 5. 写入 models.json（ksyun GLM-5.2，$KSYUN_API_KEY 引用）--------
echo ""
echo "[5/6] 写入 models.json（ksyun / glm-5.2）..."
MODELS=~/.pi/agent/models.json
if [ -f "$MODELS" ] && [ "$FORCE" -ne 1 ]; then
  echo "  ⚠️  $MODELS 已存在，跳过（用 --force 覆盖）"
else
  cat > "$MODELS" << 'MODELS_EOF'
{
  "providers": {
    "ksyun": {
      "name": "Ksyun",
      "baseUrl": "https://kspmas.ksyun.com/v1",
      "apiKey": "$KSYUN_API_KEY",
      "api": "openai-completions",
      "authHeader": true,
      "compat": {
        "supportsStore": false,
        "supportsDeveloperRole": false,
        "supportsReasoningEffort": true,
        "supportsUsageInStreaming": true,
        "maxTokensField": "max_completion_tokens",
        "supportsStrictMode": false,
        "thinkingFormat": "openai"
      },
      "models": [
        {
          "id": "glm-5.2",
          "name": "Ksyun GLM-5.2",
          "reasoning": true,
          "thinkingLevelMap": {
            "minimal": null,
            "low": "high",
            "medium": "high",
            "high": "high",
            "xhigh": "max"
          },
          "input": ["text"],
          "contextWindow": 1000000,
          "maxTokens": 128000,
          "cost": { "input": 8, "output": 28, "cacheRead": 2, "cacheWrite": 0 }
        }
      ]
    }
  }
}
MODELS_EOF
  echo "  ✓ models.json 已写入（apiKey=\$KSYUN_API_KEY 环境变量引用）"
fi

# -------- 6. 拷贝自定义 agents --------
echo ""
echo "[6/6] 拷贝自定义 agents..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -d "$SCRIPT_DIR/agents" ]; then
  mkdir -p ~/.pi/agent/agents
  cp -r "$SCRIPT_DIR/agents/"*.md ~/.pi/agent/agents/ 2>/dev/null && \
    echo "  ✓ agents 已拷贝到 ~/.pi/agent/agents/" || \
    echo "  ⚠️  agents 目录为空或拷贝失败"
else
  echo "  ⚠️  未找到 agents/ 目录（若通过 curl 管道运行，请先 clone 仓库）"
fi

# -------- 完成 --------
echo ""
echo "========================================"
echo " ✓ 完成！"
echo "========================================"
echo ""
echo "下一步:"
echo "  1. 确保 KSYUN_API_KEY 已 export（写入 ~/.zshrc 或 ~/.bashrc 持久化）:"
echo "       echo 'export KSYUN_API_KEY=\"你的key\"' >> ~/.zshrc"
echo "  2. 运行 pi，执行 /login（若需登录）"
echo "  3. /reload 加载所有扩展与技能"
echo ""
echo "已安装: 11 个包（4 npm + 7 自维护 git）"
echo "Provider: ksyun / glm-5.2（100万上下文，thinking high）"
echo "自定义 agents: coder/debugger/planner/researcher/reviewer（均用 ksyun/glm-5.2）"
