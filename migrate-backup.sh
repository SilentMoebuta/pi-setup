#!/usr/bin/env bash
# pi agent 迁移：备份当前机器的配置、自定义 agents、手动安装的 skills。
# 用法:
#   bash migrate-backup.sh              # 基础备份（配置 + agents + 手动 skills）
#   bash migrate-backup.sh --memory     # 含记忆数据库
#   bash migrate-backup.sh --sessions   # 含会话历史
#   bash migrate-backup.sh --all        # 全部
set -euo pipefail

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUT="pi-migrate-${TIMESTAMP}.tar.gz"
PI_DIR="$HOME/.pi/agent"
AGENTS_DIR="$HOME/.agents"

# ---- 收集要打包的文件 ----
files=()

# 核心配置文件（始终打包）
for f in settings.json models.json auth.json trust.json; do
  [ -f "$PI_DIR/$f" ] && files+=(".pi/agent/$f")
done

# 自定义 agents
[ -d "$PI_DIR/agents" ] && files+=(".pi/agent/agents")

# 手动安装的 skills（非 packages 管理）
[ -d "$AGENTS_DIR/skills" ] && files+=(".agents/skills")

# ---- 可选 ----
inc_memory=0; inc_sessions=0
for a in "$@"; do
  case "$a" in
    --memory)   inc_memory=1 ;;
    --sessions) inc_sessions=1 ;;
    --all)      inc_memory=1; inc_sessions=1 ;;
  esac
done

[ "$inc_memory" = 1 ] && {
  [ -f "$PI_DIR/memory/agent.db" ]  && files+=(".pi/agent/memory/agent.db")
  [ -f "$PI_DIR/memory/MEMORY.md" ] && files+=(".pi/agent/memory/MEMORY.md")
  [ -f "$PI_DIR/memory/config.toml" ] && files+=(".pi/agent/memory/config.toml")
}

[ "$inc_sessions" = 1 ] && {
  [ -d "$PI_DIR/sessions" ] && files+=(".pi/agent/sessions")
}

# ---- 打包 ----
tar czf "$OUT" -C "$HOME" "${files[@]}"
echo "✓ 已打包: $OUT ($(du -h "$OUT" | cut -f1))"
echo ""
echo "  内容:"
for f in "${files[@]}"; do echo "    ~/$f"; done
echo ""
echo "  ⚠️  auth.json 含 API key，请安全传输此文件"
echo "  ⚠️  传输后删除源备份文件或加密存储"
echo ""
echo "  恢复到新机器的步骤:"
echo "    1. tar xzf $OUT -C ~"
echo "    2. 安装 pi（若未装）: curl -fsSL https://pi.dev/install.sh | sh"
echo "    3. 恢复扩展包:            pi update --extensions"
echo "    4. 设置 API key 环境变量（如 DEEPSEEK_API_KEY）"
echo "    5. 运行 pi，/reload"
