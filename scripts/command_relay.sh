#!/bin/bash
# 循环1: 命令中继 - 每60秒检查 pending.md 并转发给研究员
REPO_DIR="$HOME/projects/claude_supervisor"
PENDING="$REPO_DIR/commands/pending.md"
ARCHIVE_DIR="$REPO_DIR/commands"
LOG="$REPO_DIR/commands/relay.log"

cd "$REPO_DIR" || exit 1

while true; do
    # git pull 获取最新命令
    git pull --quiet origin master 2>/dev/null

    # 检查 pending.md 是否有实际内容（非空白）
    CONTENT=$(cat "$PENDING" 2>/dev/null | sed '/^[[:space:]]*$/d')

    if [ -n "$CONTENT" ]; then
        TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
        HHMM=$(date '+%H%M')

        echo "[$TIMESTAMP] 发送命令: $CONTENT" >> "$LOG"

        # 通过 tmux send-keys 发送给研究员
        tmux send-keys -t claude_admin "$CONTENT" Enter 2>>"$LOG"

        # 存档已执行命令
        echo "# 命令已执行 — $TIMESTAMP" > "$ARCHIVE_DIR/executed_${TIMESTAMP}.md"
        echo "" >> "$ARCHIVE_DIR/executed_${TIMESTAMP}.md"
        echo "$CONTENT" >> "$ARCHIVE_DIR/executed_${TIMESTAMP}.md"

        # 清空 pending.md
        echo "" > "$PENDING"

        # commit + push
        cd "$REPO_DIR"
        git add commands/
        git commit -m "命令已中继: $HHMM — $(echo "$CONTENT" | head -1 | cut -c1-50)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>" 2>/dev/null
        git push origin master 2>/dev/null

        echo "[$TIMESTAMP] 命令已发送并存档" >> "$LOG"
    fi

    sleep 60
done
