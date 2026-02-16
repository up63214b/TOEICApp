#!/bin/bash
# =============================================================================
# AI Agent Coordinator - TOEICApp 自動レビュー・改善システム
# =============================================================================
# 3つのサブエージェント（Reviewer → Improver → Verifier）を順番に実行し、
# コードの自動レビュー・改善・検証を行います。
#
# 使い方:
#   ./coordinator.sh              # 全エージェント実行
#   ./coordinator.sh review       # Reviewerだけ実行（テスト用）
#   ./coordinator.sh improve      # Reviewer + Improver
#   ./coordinator.sh dry-run      # 実際の変更なしでレビューだけ表示
# =============================================================================

set -euo pipefail

# --- 設定 ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/output"
PROMPTS_DIR="$SCRIPT_DIR/prompts"
RUN_ID="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$OUTPUT_DIR/coordinator-${RUN_ID}.log"
DATE_TAG="$(date +%Y%m%d)"
# 同日複数回の実行でもブランチ名が衝突しないようにタイムスタンプを含める
BRANCH_NAME="ai/improve-${RUN_ID}"

# 実行モード（引数で指定、デフォルトは全実行）
MODE="${1:-all}"

# 古いログを何件まで残すか
MAX_LOG_FILES=20

# --- 異常終了時のクリーンアップ ---
# エラーで中断しても main ブランチに戻り、一時ファイルを掃除する
cleanup_on_exit() {
    local exit_code=$?
    rm -f "$OUTPUT_DIR"/_tmp_*.txt 2>/dev/null
    rm -rf "/tmp/ai-agent-backup-${RUN_ID}" 2>/dev/null
    if [ $exit_code -ne 0 ]; then
        cd "$PROJECT_DIR" 2>/dev/null || true
        git checkout main 2>/dev/null || true
        # このRUNでstashした変更があれば復元
        if git stash list 2>/dev/null | head -1 | grep -q "ai-agent-auto-stash-${RUN_ID}"; then
            git stash pop 2>/dev/null || true
        fi
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: 異常終了（exit code: $exit_code）。mainブランチに復帰しました。" >> "$LOG_FILE" 2>/dev/null || true
    fi
}
trap cleanup_on_exit EXIT

# --- ユーティリティ ---
log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" >&2
    echo "$msg" >> "$LOG_FILE"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

# AIの出力からJSON部分だけを抽出する
# claude の応答にはマークダウンの ```json ... ``` や説明文が含まれることがあるため除去する
extract_json() {
    python3 -c "
import sys, json, re

raw = sys.stdin.read()

# 1) claude --output-format json のラッパーを外す
try:
    wrapper = json.loads(raw)
    if isinstance(wrapper, dict) and 'result' in wrapper:
        raw = wrapper['result']
except (json.JSONDecodeError, TypeError):
    pass

# 2) マークダウンのコードフェンス内のJSONを抽出
fence_match = re.search(r'\`\`\`(?:json)?\s*\n(.*?)\n\s*\`\`\`', raw, re.DOTALL)
if fence_match:
    raw = fence_match.group(1)

# 3) JSONとしてパースして整形出力（検証も兼ねる）
try:
    parsed = json.loads(raw)
    print(json.dumps(parsed, ensure_ascii=False, indent=2))
except json.JSONDecodeError:
    # パースできなかった場合はそのまま出力
    print(raw)
"
}

# 古いログファイルを削除（MAX_LOG_FILES件を超えた分）
cleanup_old_logs() {
    local count
    count=$(find "$OUTPUT_DIR" -name "coordinator-*.log" -type f | wc -l | tr -d ' ')
    if [ "$count" -gt "$MAX_LOG_FILES" ]; then
        log "古いログを整理中（${count}件 → ${MAX_LOG_FILES}件）"
        find "$OUTPUT_DIR" -name "coordinator-*.log" -type f -print0 \
            | xargs -0 ls -t \
            | tail -n +"$((MAX_LOG_FILES + 1))" \
            | xargs rm -f
    fi
}

# --- 前提条件チェック ---
check_prerequisites() {
    log "=== 前提条件チェック ==="

    if ! command -v claude &> /dev/null; then
        error_exit "claude CLI が見つかりません。インストールしてください。"
    fi
    log "✓ claude CLI: $(which claude)"

    if ! command -v gh &> /dev/null; then
        error_exit "gh CLI が見つかりません: brew install gh"
    fi
    log "✓ gh CLI: $(which gh)"

    if ! gh auth status &> /dev/null 2>&1; then
        error_exit "gh が認証されていません: gh auth login を実行してください"
    fi
    log "✓ gh 認証済み"

    if ! git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree &> /dev/null; then
        error_exit "$PROJECT_DIR はgitリポジトリではありません"
    fi
    log "✓ git リポジトリ確認済み"

    mkdir -p "$OUTPUT_DIR"
    log "✓ 出力先: $OUTPUT_DIR"
}

# --- プロジェクトファイル収集 ---
# Swift、シェルスクリプト、Markdown、設定ファイルなど全対象を収集
collect_source_code() {
    log "=== プロジェクトファイル収集 ==="
    local source_file="$OUTPUT_DIR/source-code.txt"

    echo "" > "$source_file"

    # 収集対象: Swift, シェルスクリプト, Markdown, プロンプト定義
    # 除外: output/（ログ・一時ファイル）, .git/, xcodeproj内部, Assets
    # プロセス置換を使用（スペース入りファイル名でも安全）
    while IFS= read -r -d '' file; do
        local relative_path="${file#$PROJECT_DIR/}"
        echo "========== $relative_path ==========" >> "$source_file"
        cat "$file" >> "$source_file"
        echo "" >> "$source_file"
    done < <(find "$PROJECT_DIR" \
        \( -name "*.swift" -o -name "*.sh" -o -name "*.md" -o -name "*.plist" \) \
        -type f \
        ! -path "*/output/*" \
        ! -path "*/.git/*" \
        ! -path "*.xcodeproj/*" \
        ! -path "*/xcworkspace/*" \
        ! -path "*/Assets.xcassets/*" \
        -print0 | sort -z)

    local line_count
    line_count=$(wc -l < "$source_file" | tr -d ' ')
    log "✓ ${line_count}行のプロジェクトファイルを収集"
    echo "$source_file"
}

# --- Agent 1: Reviewer ---
run_reviewer() {
    log "=== Agent 1: Reviewer 実行 ==="
    local source_file="$1"
    local review_output="$OUTPUT_DIR/review-result.json"
    local prompt_file="$PROMPTS_DIR/reviewer.md"

    # プロンプトファイルの存在確認
    if [ ! -f "$prompt_file" ]; then
        error_exit "reviewer.md が見つかりません: $prompt_file"
    fi

    # プロンプトファイルとソースコードを一時ファイルに結合（引数が長すぎる問題を回避）
    local tmp_prompt="$OUTPUT_DIR/_tmp_reviewer_prompt.txt"
    {
        cat "$prompt_file"
        echo ""
        echo "--- 以下がレビュー対象のソースコードです ---"
        echo ""
        cat "$source_file"
    } > "$tmp_prompt"

    log "Reviewer エージェント起動中..."
    local result
    if result=$(claude -p "$(cat "$tmp_prompt")" --output-format json 2>>"$LOG_FILE"); then
        echo "$result" | extract_json > "$review_output"
        log "✓ レビュー完了: $review_output"
    else
        error_exit "Reviewer エージェントが失敗しました"
    fi

    rm -f "$tmp_prompt"
    echo "$review_output"
}

# --- Agent 2: Improver ---
run_improver() {
    log "=== Agent 2: Improver 実行 ==="
    local review_result="$1"
    local improve_output="$OUTPUT_DIR/improve-result.json"
    local prompt_file="$PROMPTS_DIR/improver.md"

    cd "$PROJECT_DIR"

    # --- git操作前に必要なファイルを /tmp に退避 ---
    # git stash やブランチ切り替えで未コミットのファイルが消えるのを防ぐ
    local backup_dir="/tmp/ai-agent-backup-${RUN_ID}"
    mkdir -p "$backup_dir"
    cp "$review_result" "$backup_dir/review-result.json"
    cp -r "$PROMPTS_DIR" "$backup_dir/prompts"
    log "✓ 必要ファイルを退避: $backup_dir"

    # 未コミットの変更がないか確認
    # scripts/ を除外して stash（スクリプト自体を消さないため）
    if ! git diff --quiet || ! git diff --cached --quiet; then
        log "WARNING: 未コミットの変更があります。stashしてから作業します。"
        git stash push -m "ai-agent-auto-stash-${RUN_ID}" -- ':!scripts/ai-agents/' 2>>"$LOG_FILE" || true
    fi

    # mainブランチに切り替え
    git checkout main 2>>"$LOG_FILE"

    # 既存の同名ブランチがあれば削除（タイムスタンプ入りなので通常は衝突しない）
    if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
        log "既存ブランチ $BRANCH_NAME を削除"
        git branch -D "$BRANCH_NAME" 2>>"$LOG_FILE"
    fi

    git checkout -b "$BRANCH_NAME" 2>>"$LOG_FILE"
    log "✓ ブランチ作成: $BRANCH_NAME"

    # --- 退避したファイルを復元 ---
    cp "$backup_dir/review-result.json" "$review_result"
    cp -r "$backup_dir/prompts/"* "$PROMPTS_DIR/" 2>/dev/null || true
    mkdir -p "$OUTPUT_DIR"
    log "✓ 退避ファイルを復元"

    # プロンプトを一時ファイルに書き出し
    local tmp_prompt="$OUTPUT_DIR/_tmp_improver_prompt.txt"
    local prompt_file_safe="$backup_dir/prompts/improver.md"
    {
        cat "$prompt_file_safe"
        echo ""
        echo "--- Reviewerの指摘事項 ---"
        cat "$review_result"
        echo ""
        echo "--- 作業ディレクトリ ---"
        echo "$PROJECT_DIR"
        echo ""
        echo "上記の指摘事項に基づいて、$PROJECT_DIR 内のSwiftファイルを直接修正してください。"
        echo "修正が完了したら、修正サマリーをJSON形式で出力してください。"
    } > "$tmp_prompt"

    log "Improver エージェント起動中..."
    local result
    if result=$(cd "$PROJECT_DIR" && claude -p "$(cat "$tmp_prompt")" --output-format json --allowedTools "Edit,Read,Glob,Grep,Write" 2>>"$LOG_FILE"); then
        echo "$result" | extract_json > "$improve_output"

        # 変更をコミット（Swift, シェルスクリプト, Markdown, plist）
        cd "$PROJECT_DIR"
        if ! git diff --quiet; then
            git add '*.swift' '*.sh' '*.md' '*.plist' 2>/dev/null || true
            git add 'scripts/ai-agents/prompts/' 2>/dev/null || true
            git commit -m "AI改善: $(date +%Y-%m-%d) 自動レビューに基づく修正

Co-Authored-By: AI Agent <ai-agent@toiecapp.local>" 2>>"$LOG_FILE"
            log "✓ 修正をコミット"
        else
            log "WARNING: Improverによる変更はありませんでした"
        fi

        log "✓ 改善完了: $improve_output"
    else
        error_exit "Improver エージェントが失敗しました"
    fi

    rm -f "$tmp_prompt"
    echo "$improve_output"
}

# --- Agent 3: Verifier ---
run_verifier() {
    log "=== Agent 3: Verifier 実行 ==="
    local review_result="$1"
    local improve_result="$2"
    local verify_output="$OUTPUT_DIR/verify-result.json"
    local prompt_file="$PROMPTS_DIR/verifier.md"

    cd "$PROJECT_DIR"

    # プロンプトファイルの存在確認
    if [ ! -f "$prompt_file" ]; then
        error_exit "verifier.md が見つかりません: $prompt_file"
    fi

    # 入力ファイルの存在確認
    if [ ! -f "$review_result" ]; then
        error_exit "review-result.json が見つかりません: $review_result"
    fi

    # mainとの差分をファイルに保存（変数に入れると長すぎる場合がある）
    local diff_file="$OUTPUT_DIR/_tmp_diff.txt"
    git diff main..."$BRANCH_NAME" > "$diff_file" 2>/dev/null || echo "差分なし" > "$diff_file"

    # プロンプトを一時ファイルに書き出し
    local tmp_prompt="$OUTPUT_DIR/_tmp_verifier_prompt.txt"
    {
        cat "$prompt_file"
        echo ""
        echo "--- Reviewerの指摘事項 ---"
        cat "$review_result"
        echo ""
        echo "--- Improverの修正サマリー ---"
        cat "$improve_result"
        echo ""
        echo "--- 変更差分 (git diff) ---"
        cat "$diff_file"
    } > "$tmp_prompt"

    log "Verifier エージェント起動中..."
    local result
    if result=$(claude -p "$(cat "$tmp_prompt")" --output-format json 2>>"$LOG_FILE"); then
        echo "$result" | extract_json > "$verify_output"
        log "✓ 検証完了: $verify_output"
    else
        error_exit "Verifier エージェントが失敗しました"
    fi

    rm -f "$tmp_prompt" "$diff_file"
    echo "$verify_output"
}

# --- GitHub Issue 作成 ---
create_github_issue() {
    log "=== GitHub Issue 作成 ==="
    local review_result="$1"
    local verify_result="$2"

    # 検証結果からverdictを取得
    local verdict
    verdict=$(VERIFY_FILE="$verify_result" python3 -c "
import json, os
try:
    data = json.load(open(os.environ['VERIFY_FILE']))
    print(data.get('verdict', 'unknown'))
except:
    print('unknown')
" 2>/dev/null || echo "unknown")

    local emoji="🔍"
    case "$verdict" in
        approve) emoji="✅" ;;
        request_changes) emoji="⚠️" ;;
        reject) emoji="❌" ;;
    esac

    # Issue本文を一時ファイルに構築（変数に入れると特殊文字で壊れることがある）
    local body_file="$OUTPUT_DIR/_tmp_issue_body.md"
    cat > "$body_file" <<ISSUE_BODY
## ${emoji} AI自動レビュー結果 (${RUN_ID})

### レビュー指摘事項
\`\`\`json
$(cat "$review_result")
\`\`\`

### 検証結果
\`\`\`json
$(cat "$verify_result")
\`\`\`

### ブランチ
- 修正ブランチ: \`${BRANCH_NAME}\`
- verdict: **${verdict}**

---
*このIssueはAIエージェントシステムによって自動生成されました（${RUN_ID}）*
ISSUE_BODY

    cd "$PROJECT_DIR"

    # ラベルがなければ作成
    gh label create "ai-review" --description "AIエージェントによる自動レビュー" --color "1d76db" 2>/dev/null || true

    local issue_url
    issue_url=$(gh issue create \
        --title "${emoji} AI自動レビュー: ${RUN_ID}" \
        --body-file "$body_file" \
        --label "ai-review" 2>>"$LOG_FILE" || echo "Issue作成失敗")

    rm -f "$body_file"
    log "✓ GitHub Issue 作成: $issue_url"
    echo "$issue_url"
}

# --- メイン処理 ---
main() {
    log "================================================"
    log "AI Agent Coordinator 開始 (モード: $MODE)"
    log "プロジェクト: $PROJECT_DIR"
    log "実行ID: $RUN_ID"
    log "================================================"

    check_prerequisites
    cleanup_old_logs

    # ソースコード収集
    local source_file
    source_file=$(collect_source_code)

    # --- Agent 1: Reviewer ---
    local review_result
    review_result=$(run_reviewer "$source_file")

    if [ "$MODE" = "review" ] || [ "$MODE" = "dry-run" ]; then
        log "=== レビュー結果 ==="
        cat "$review_result" >&2
        log "=== 完了（${MODE}モード）==="
        exit 0
    fi

    # --- Agent 2: Improver ---
    local improve_result
    improve_result=$(run_improver "$review_result")

    if [ "$MODE" = "improve" ]; then
        log "=== 完了（improveモード）==="
        log "修正ブランチ: $BRANCH_NAME"
        exit 0
    fi

    # --- Agent 3: Verifier ---
    local verify_result
    verify_result=$(run_verifier "$review_result" "$improve_result")

    # --- GitHub Issue 作成 ---
    create_github_issue "$review_result" "$verify_result"

    # mainブランチに戻る
    cd "$PROJECT_DIR"
    git checkout main 2>>"$LOG_FILE"

    log "================================================"
    log "AI Agent Coordinator 完了"
    log "修正ブランチ: $BRANCH_NAME"
    log "ログ: $LOG_FILE"
    log "================================================"
}

main
