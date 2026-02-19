#!/bin/bash
# =============================================================================
# TOEICApp AI Agent Runner 設定ファイル
# run.sh から source される
# Usage: run.sh --config /path/to/this/config.sh [--mode <mode>]
# =============================================================================

# --- パス設定 ---
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"   # TOEICApp/
OUTPUT_DIR="$PROJECT_DIR/.agents/output"                             # 出力先
PROMPTS_DIR="$PROJECT_DIR/.agents/prompts"                           # プロンプト格納先

# --- モデル設定 ---
MODEL_LIGHT="claude-sonnet-4-5-20250929"  # 軽量タスク（reviewer, ux-analyst など）
MODEL_HEAVY="claude-opus-4-6"             # 重量タスク（improver, verifier）

# --- タイムアウト設定（秒） ---
TIMEOUT_SECONDS=300  # 各エージェントの最大実行時間

# --- Improver への追加指示 ---
# 基本指示は prompts/improver.md に一元化済み。
# プロジェクト固有の追加指示が必要な場合のみここに記載する。
IMPROVER_INSTRUCTION=""

# --- パイプライン定義 ---
# 引数: モード名（review / dry-run / improve / all / ux / test / feature）
# 出力: 空白区切りのエージェント名リスト（run.sh の for ループで使用）
get_pipeline() {
    local mode="$1"
    case "$mode" in
        review|dry-run)
            echo "reviewer"
            ;;
        improve)
            echo "reviewer improver"
            ;;
        all)
            echo "reviewer improver verifier ux-analyst test-writer feature-proposer"
            ;;
        ux)
            echo "ux-analyst"
            ;;
        test)
            echo "test-writer"
            ;;
        feature)
            echo "feature-proposer"
            ;;
        verify|verifier)
            echo "verifier"
            ;;
        *)
            return 1  # 不明なモード → run.sh が error_exit を呼ぶ
            ;;
    esac
}

# --- エージェント設定 ---
# 引数: エージェント名
# 出力: "プロンプトパス:モデル:タイプ" 形式の文字列
# タイプ: analysis | improver | verifier  （runner.sh が分岐に使用）
get_agent_config() {
    local agent="$1"
    case "$agent" in
        reviewer)
            echo "$PROMPTS_DIR/reviewer.md:$MODEL_LIGHT:analysis"
            ;;
        improver)
            echo "$PROMPTS_DIR/improver.md:$MODEL_HEAVY:improver"
            ;;
        verifier)
            echo "$PROMPTS_DIR/verifier.md:$MODEL_HEAVY:verifier"
            ;;
        ux-analyst)
            echo "$PROMPTS_DIR/ux-analyst.md:$MODEL_LIGHT:analysis"
            ;;
        test-writer)
            echo "$PROMPTS_DIR/test-writer.md:$MODEL_LIGHT:analysis"
            ;;
        feature-proposer)
            echo "$PROMPTS_DIR/feature-proposer.md:$MODEL_LIGHT:analysis"
            ;;
        *)
            return 1  # 不明なエージェント → runner.sh が error_exit を呼ぶ
            ;;
    esac
}
