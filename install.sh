#!/usr/bin/env bash
# plain-zh 一键安装（兼容主流 agent）
# - 技能：软链到各 agent 的 skills 目录（--copy 改为复制）
# - 政策：带标记幂等写入各 agent 的全局指令文件，重复执行自动去重更新
# - 默认只配置"检测到已安装"的 agent；--all 强制写入全部兼容位
# 用法：
#   ./install.sh               # 常规安装/刷新
#   ./install.sh --update      # 先 git pull 再刷新
#   ./install.sh --remove      # 撤销软链与政策块（canonical 副本保留）
set -euo pipefail

CANONICAL="${PLAIN_ZH_HOME:-$HOME/.local/share/plain-zh}"
REPO_URL="https://github.com/Gyanesh5/plain-zh.git"
BEGIN="<!-- plain-zh:begin (auto-managed) -->"
END="<!-- plain-zh:end -->"

REMOVE=0; UPDATE=0; ALL=0; COPY=0
for a in "$@"; do
  case "$a" in
    --remove) REMOVE=1 ;; --update) UPDATE=1 ;; --all) ALL=1 ;; --copy) COPY=1 ;;
    *) echo "未知参数: $a（可用: --update --all --copy --remove）"; exit 1 ;;
  esac
done

# agent 名 : skills 目录 : 全局指令文件
AGENTS=(
  "claude-code:$HOME/.claude:$HOME/.claude/skills:$HOME/.claude/CLAUDE.md"
  "codex:$HOME/.codex:$HOME/.codex/skills:$HOME/.codex/AGENTS.md"
  "opencode:$HOME/.config/opencode:$HOME/.config/opencode/skills:$HOME/.config/opencode/AGENTS.md"
  "zcode:$HOME/.zcode:$HOME/.zcode/skills:$HOME/.zcode/AGENTS.md"
  "gemini:$HOME/.gemini:$HOME/.gemini/skills:$HOME/.gemini/GEMINI.md"
)

strip_blocks() { # 删 marker 块 + 遗留的旧版 plain-zh 段（幂等基础）
  local f="$1"
  awk -v b="$BEGIN" -v e="$END" 'index($0,b),index($0,e){next} {print}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  awk '/^## plain-zh/{skip=1;next} skip && /^## /{skip=0} !skip' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
}

if [ "$REMOVE" = 1 ]; then
  for row in "${AGENTS[@]}"; do
    IFS=':' read -r name root sdir gfile <<< "$row"
    if [ -L "$sdir/plain-zh" ] || { [ "$COPY" = 1 ] && [ -d "$sdir/plain-zh" ]; }; then rm -rf "$sdir/plain-zh"; echo "removed $sdir/plain-zh"; fi
    if [ -f "$gfile" ]; then strip_blocks "$gfile"; echo "cleaned $gfile"; fi
  done
  echo "撤销完成。canonical 副本保留在 $CANONICAL（彻底删除: rm -rf $CANONICAL）"
  exit 0
fi

# 1) canonical 副本
if [ ! -f "$CANONICAL/SKILL.md" ]; then
  SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
  if [ -f "$SRC_DIR/SKILL.md" ] && [ "$SRC_DIR" != "$CANONICAL" ]; then
    mkdir -p "$CANONICAL"; cp -r "$SRC_DIR"/. "$CANONICAL"/
    echo "[1/3] canonical <- 本地检出 ($CANONICAL)"
  else
    git clone --depth 1 "$REPO_URL" "$CANONICAL"
    echo "[1/3] canonical <- $REPO_URL"
  fi
elif [ "$UPDATE" = 1 ] && [ -d "$CANONICAL/.git" ]; then
  git -C "$CANONICAL" pull --ff-only >/dev/null 2>&1 || echo "  (git pull 失败，沿用当前版本)"
  echo "[1/3] canonical 已更新"
else
  echo "[1/3] canonical 已存在: $CANONICAL（--update 可拉新版）"
fi

POLICY="$(cat "$CANONICAL/POLICY.md")"
TARGETS=()
for row in "${AGENTS[@]}"; do
  IFS=':' read -r name root sdir gfile <<< "$row"
  if [ "$ALL" = 1 ] || [ -d "$root" ]; then TARGETS+=("$row"); fi
done
if [ "${#TARGETS[@]}" = 0 ]; then
  echo "[2/3][3/3] 未检测到已安装的 agent（claude-code/codex/opencode/zcode/gemini）。"
  echo "        重跑加 --all 可预写全部兼容位（之后装任何 agent 即生效）。"
  exit 0
fi

echo "[2/3] 链接技能目录:"
for row in "${TARGETS[@]}"; do
  IFS=':' read -r name root sdir gfile <<< "$row"
  mkdir -p "$sdir"
  if [ "$COPY" = 1 ]; then rm -rf "$sdir/plain-zh"; cp -r "$CANONICAL" "$sdir/plain-zh"; echo "  copy  $name -> $sdir/plain-zh"
  else rm -rf "$sdir/plain-zh"; ln -sfn "$CANONICAL" "$sdir/plain-zh"; echo "  link  $name -> $sdir/plain-zh"; fi
done

echo "[3/3] 写入全局政策块（幂等，可重复执行）:"
for row in "${TARGETS[@]}"; do
  IFS=':' read -r name root sdir gfile <<< "$row"
  mkdir -p "$(dirname "$gfile")"; touch "$gfile"
  strip_blocks "$gfile"
  printf '\n%s\n\n%s\n%s\n' "$BEGIN" "$POLICY" "$END" >> "$gfile"
  echo "  $name -> $gfile"
done

echo "完成。以后规则更新: cd $CANONICAL && git pull && ./install.sh --update"
echo "（Hermes 走自己的安装通道: hermes skills install <raw SKILL.md 直链>；网页类工具粘 POLICY.md 进自定义指令）"
