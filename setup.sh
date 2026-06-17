#!/bin/bash
set -e

echo "========================================"
echo " Pi Agent 环境一键配置"
echo "========================================"
echo ""

# -------- 1. 安装 pi --------
echo "[1/3] 安装 pi agent..."
if ! command -v pi &> /dev/null; then
    curl -fsSL https://pi.dev/install.sh | sh
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.bashrc
    export PATH="$HOME/.local/bin:$PATH"
else
    echo "  pi 已安装，跳过"
fi

# -------- 2. 安装所有包 --------
echo ""
echo "[2/3] 安装 pi 包..."

packages=(
    "npm:@gotgenes/pi-subagents"
    "npm:pi-ask-user"
    "npm:pi-web-access"
    "npm:@vndv/pi-codegraph"
    "git:github.com/SilentMoebuta/pi-superpowers"
    "git:github.com/SilentMoebuta/pi-goal"
)

for pkg in "${packages[@]}"; do
    echo "  安装 $pkg ..."
    pi install "$pkg"
done

# -------- 3. 写入配置 --------
echo ""
echo "[3/3] 写入配置..."

mkdir -p ~/.pi/agent

cat > ~/.pi/agent/settings.json << 'EOF'
{
  "theme": "light",
  "defaultProvider": "deepseek",
  "defaultModel": "deepseek-v4-pro",
  "defaultThinkingLevel": "xhigh",
  "packages": [
    "npm:@gotgenes/pi-subagents",
    "npm:pi-ask-user",
    "npm:pi-web-access",
    "npm:@vndv/pi-codegraph",
    "git:github.com/SilentMoebuta/pi-superpowers",
    "git:github.com/SilentMoebuta/pi-goal"
  ]
}
EOF

# 拷贝自定义 agents
cp -r agents/*.md ~/.pi/agent/agents/ 2>/dev/null || true

echo ""
echo "========================================"
echo " 完成！"
echo " 运行 pi，然后执行 /login 登录。"
echo "========================================"
