#!/bin/bash
# ============================================================
# Pi Agent 一键安装脚本（自包含，无需 clone pi-setup repo）
#
# 用法:
#   1. 把本文件拷到目标机器
#   2. export KSYUN_API_KEY="你的key"
#   3. bash install-pi.sh
#
# 或一行（从 GitHub 拉取）:
#   KSYUN_API_KEY="xxx" bash -c "$(curl -fsSL https://raw.githubusercontent.com/SilentMoebuta/pi-setup/main/install-pi.sh)"
#
# 幂等: 可重复运行。已存在的 settings.json/models.json 不覆盖（除非 --force）。
# ============================================================
set -e

FORCE=0
[ "$1" = "--force" ] && FORCE=1

echo "========================================"
echo " Pi Agent 一键安装"
echo " Provider: ksyun / glm-5.2"
echo "========================================"
echo ""

# -------- 0. 前置: KSYUN_API_KEY --------
if [ -z "$KSYUN_API_KEY" ]; then
  echo "⚠️  未检测到 KSYUN_API_KEY 环境变量。"
  echo "   获取: https://kspmas.ksyun.com/"
  echo "   设置: export KSYUN_API_KEY=\"你的key\""
  echo "   持久: echo 'export KSYUN_API_KEY=\"你的key\"' >> ~/.zshrc"
  echo ""
  read -p "仍继续安装？（models.json 会生成但需稍后补 key）[y/N] " yn
  [ "$yn" != "y" ] && [ "$yn" != "Y" ] && { echo "已取消"; exit 1; }
fi

mkdir -p ~/.pi/agent

# -------- 1. 安装 pi --------
echo "[1/5] 安装 pi agent..."
if ! command -v pi &> /dev/null; then
  curl -fsSL https://pi.dev/install.sh | sh
  for rc in ~/.bashrc ~/.zshrc; do
    [ -f "$rc" ] && ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$rc" 2>/dev/null && \
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
  done
  export PATH="$HOME/.local/bin:$PATH"
  echo "  ✓ pi 已安装"
else
  echo "  ✓ pi 已安装，跳过"
fi

# -------- 2. git SSH 变通（仅当 HTTPS 访问 github.com 被阻断时）--------
echo ""
echo "[2/5] 检查 github.com 连通性..."
if curl -sfI --max-time 8 https://github.com >/dev/null 2>&1; then
  echo "  ✓ HTTPS 可访 github.com，无需 SSH 变通"
else
  echo "  ⚠️  HTTPS 访问失败，尝试 SSH 变通..."
  if [ ! -f ~/.ssh/id_ed25519 ] && [ ! -f ~/.ssh/id_rsa ]; then
    echo "  ⚠️  无 SSH key。生成中..."
    ssh-keygen -t ed25519 -C "pi-setup@$(hostname)" -f ~/.ssh/id_ed25519 -N "" -q
    echo "  ✓ SSH key 已生成: ~/.ssh/id_ed25519.pub"
    echo "  ⚠️  请将下面公钥添加到 GitHub Settings → SSH keys:"
    cat ~/.ssh/id_ed25519.pub
    echo ""
    echo "  添加后重跑本脚本。"
    exit 1
  fi
  EXISTING=$(git config --global --get url."git@github.com:".insteadOf 2>/dev/null || true)
  if [ -z "$EXISTING" ]; then
    git config --global url."git@github.com:".insteadOf "https://github.com/"
    echo "  ✓ 已配 SSH 变通（HTTPS→SSH）"
  else
    echo "  ✓ SSH 变通已存在"
  fi
fi

# -------- 3. 安装 11 个包 --------
echo ""
echo "[3/5] 安装 pi 包（11 个）..."
PACKAGES=(
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
for pkg in "${PACKAGES[@]}"; do
  echo "  → $pkg"
  pi install "$pkg" 2>&1 | tail -1
done

# -------- 4. settings.json --------
echo ""
echo "[4/5] 写入 settings.json..."
SETTINGS=~/.pi/agent/settings.json
if [ -f "$SETTINGS" ] && [ "$FORCE" -ne 1 ]; then
  echo "  ⚠️  已存在，跳过（--force 覆盖）"
else
  cat > "$SETTINGS" << 'EOF'
{
  "theme": "light",
  "defaultProvider": "ksyun",
  "defaultModel": "glm-5.2",
  "defaultThinkingLevel": "high",
  "retry": {
    "enabled": true,
    "maxRetries": 5,
    "baseDelayMs": 4000,
    "provider": { "maxRetries": 0, "maxRetryDelayMs": 60000 }
  },
  "powerline": {
    "customItems": [
      { "id": "pi-goal", "statusKey": "pi-goal", "position": "right", "color": "accent" },
      { "id": "plan-execute", "statusKey": "plan-execute", "position": "right", "color": "warning", "prefix": "mode", "hideWhenMissing": false }
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
EOF
  echo "  ✓ settings.json 已写入"
fi

# -------- 5. models.json（ksyun GLM-5.2，$KSYUN_API_KEY 引用）--------
echo ""
echo "[5/5] 写入 models.json..."
MODELS=~/.pi/agent/models.json
if [ -f "$MODELS" ] && [ "$FORCE" -ne 1 ]; then
  echo "  ⚠️  已存在，跳过（--force 覆盖）"
else
  cat > "$MODELS" << 'EOF'
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
          "thinkingLevelMap": { "minimal": null, "low": "high", "medium": "high", "high": "high", "xhigh": "max" },
          "input": ["text"],
          "contextWindow": 1000000,
          "maxTokens": 128000,
          "cost": { "input": 8, "output": 28, "cacheRead": 2, "cacheWrite": 0 }
        }
      ]
    }
  }
}
EOF
  echo "  ✓ models.json 已写入（apiKey=\$KSYUN_API_KEY 环境变量引用）"
fi

# -------- 完成 --------
echo ""
echo "========================================"
echo " ✓ 完成！"
echo "========================================"
echo ""
echo "下一步:"
echo "  1. 持久化 KSYUN_API_KEY（若未做）:"
echo "       echo 'export KSYUN_API_KEY=\"你的key\"' >> ~/.zshrc"
echo "  2. 运行 pi，执行 /login（若需登录）"
echo "  3. /reload 加载扩展与技能"
echo ""
echo "已装: 11 包（4 npm + 7 自维护 git）| Provider: ksyun/glm-5.2 | 默认 Build Mode"
