#!/bin/bash
# =============================================================================
# セットアップスクリプト - AI Agent 定期実行の登録/解除
# =============================================================================
# 使い方:
#   ./setup.sh install     # launchd に登録（5時間ごとに自動実行）
#   ./setup.sh uninstall   # launchd から解除
#   ./setup.sh status      # 現在の状態を確認
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST_NAME="com.toiecapp.ai-review"
PLIST_SOURCE="$SCRIPT_DIR/$PLIST_NAME.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"
LOG_DIR="$SCRIPT_DIR/output"

do_install() {
    echo "=== AI Agent 定期実行を登録します ==="

    mkdir -p "$HOME/Library/LaunchAgents"

    # 既に登録済みなら先に解除
    if [ -f "$PLIST_DEST" ]; then
        launchctl unload "$PLIST_DEST" 2>/dev/null || true
    fi

    cp "$PLIST_SOURCE" "$PLIST_DEST"
    echo "✓ plist コピー完了: $PLIST_DEST"

    launchctl load "$PLIST_DEST"
    echo "✓ launchd に登録完了"
    echo ""
    echo "5時間ごとにAIレビューが自動実行されます。"
    echo "手動で今すぐ実行したい場合: ./coordinator.sh"
    echo "解除する場合: ./setup.sh uninstall"
}

do_uninstall() {
    echo "=== AI Agent 定期実行を解除します ==="

    if [ -f "$PLIST_DEST" ]; then
        launchctl unload "$PLIST_DEST" 2>/dev/null || true
        rm "$PLIST_DEST"
        echo "✓ launchd から解除完了"
    else
        echo "登録されていません。"
    fi
}

do_status() {
    echo "=== AI Agent 状態確認 ==="

    if [ -f "$PLIST_DEST" ]; then
        echo "✓ plist: インストール済み"
        echo "  場所: $PLIST_DEST"
    else
        echo "✗ plist: 未インストール"
    fi

    echo ""
    if launchctl list "$PLIST_NAME" &>/dev/null; then
        echo "✓ launchd: 登録済み（実行中）"
        launchctl list "$PLIST_NAME" 2>/dev/null || true
    else
        echo "✗ launchd: 未登録"
    fi

    echo ""
    echo "--- 最近のログ ---"
    if ls "$LOG_DIR"/coordinator-*.log 1>/dev/null 2>&1; then
        local latest_log
        latest_log=$(ls -t "$LOG_DIR"/coordinator-*.log | head -1)
        echo "最新ログ: $latest_log"
        tail -5 "$latest_log"
    else
        echo "ログファイルがまだありません。"
    fi
}

case "${1:-help}" in
    install)   do_install ;;
    uninstall) do_uninstall ;;
    status)    do_status ;;
    *)
        echo "使い方: $0 {install|uninstall|status}"
        echo ""
        echo "  install     5時間ごとにAIレビューを自動実行する設定を登録"
        echo "  uninstall   自動実行を解除"
        echo "  status      現在の状態を確認"
        exit 1
        ;;
esac
