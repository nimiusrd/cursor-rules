#!/bin/bash

# エラーが発生したら終了
set -e

# カラーコード
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# リポジトリ情報
REPO_OWNER="nimiusrd"
REPO_NAME="cursor-rules"
BRANCH="main"

# インストールするルールのリスト
RULES=(
  "commit-message-guide"
  "pr-creation-guide"
  "pr-template-guide"
)

# ルールをインストールするディレクトリ
RULES_DIR=".cursor/rules"

# プルリクエストテンプレートのパス
PR_TEMPLATE_SRC=".github/pull_request_template.md"
PR_TEMPLATE_DEST=".github/pull_request_template.md"

# 強制更新モードかどうかを確認
FORCE_UPDATE=false
for arg in "$@"; do
  if [[ "$arg" == "-f" || "$arg" == "--force" ]]; then
    FORCE_UPDATE=true
    break
  fi
done

# PRテンプレートをスキップするかどうかを確認
SKIP_PR_TEMPLATE=false
for arg in "$@"; do
  if [[ "$arg" == "--no-pr-template" ]]; then
    SKIP_PR_TEMPLATE=true
    break
  fi
done

# ヘルプ関数
show_help() {
  echo -e "${BOLD}${CYAN}Cursor Rules ダウンロードツール${NC}"
  echo -e "${CYAN}===============================${NC}"
  echo ""
  echo -e "${BOLD}使用方法:${NC}"
  echo "  $0 [オプション]"
  echo ""
  echo -e "${BOLD}説明:${NC}"
  echo "  このスクリプトは cursor-rules リポジトリから以下をダウンロードします："
  echo "    • Cursor エディタ用のルールファイル (.cursor/rules/ ディレクトリ)"
  echo "    • プルリクエストテンプレート (.github/ ディレクトリ)"
  echo ""
  echo -e "${BOLD}オプション:${NC}"
  echo "  -h, --help           このヘルプメッセージを表示"
  echo "  -f, --force          既存ファイルを強制的に上書き"
  echo "  --no-pr-template     プルリクエストテンプレートのダウンロードをスキップ"
  echo ""
  echo -e "${BOLD}使用例:${NC}"
  echo "  $0                   # 通常の実行"
  echo "  $0 -f                # 既存ファイルを上書きして実行"
  echo "  $0 --no-pr-template  # PRテンプレートなしで実行"
  echo "  $0 -f --no-pr-template  # 強制上書き & PRテンプレートなし"
  echo ""
  echo -e "${BOLD}ダウンロードされるルール:${NC}"
  local rules=(
    "commit-message-guide"
    "pr-creation-guide"
    "pr-template-guide"
  )
  for rule in "${rules[@]}"; do
    echo "  • $rule"
  done
  echo ""
  echo -e "${BOLD}インストール先:${NC}"
  echo "  • ルール: .cursor/rules/"
  echo "  • PRテンプレート: .github/"
  echo ""
}

# ヘルプオプションを確認
for arg in "$@"; do
  if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
    show_help
    exit 0
  fi
done

echo -e "${BOLD}${CYAN}Cursor Rules ダウンロードツール${NC}"
echo -e "${CYAN}===============================${NC}"
echo -e "以下のルールをダウンロードします："
echo ""
for rule in "${RULES[@]}"; do
  echo "    $rule"
done
echo ""

if [ "$SKIP_PR_TEMPLATE" = false ]; then
  echo -e "${BOLD}また、以下もダウンロードします：${NC}"
  echo ""
  echo "    プルリクエストテンプレート ${PR_TEMPLATE_DEST}"
  echo ""
fi

echo -e "${BOLD}ダウンロード先ディレクトリ:${NC}"
echo ""
echo "    ルール: ${RULES_DIR}"
if [ "$SKIP_PR_TEMPLATE" = false ]; then
  echo "    PRテンプレート: .github/"
fi
echo ""

if [ "$FORCE_UPDATE" = true ]; then
  echo -e "${BOLD}モード:${NC} ${MAGENTA}強制更新（既存ファイルを上書き）${NC}"
else
  echo -e "${BOLD}モード:${NC} ${YELLOW}スキップ（既存ファイルは更新しない）${NC}"
  echo -e "    ${YELLOW}注意: 既存ファイルを上書きするには -f または --force オプションを使用してください${NC}"
fi

echo -e "${BOLD}${CYAN}Cursor Rules ダウンロードを開始します...${NC}"

# ディレクトリがなければ作成
if [ ! -d "$RULES_DIR" ]; then
  echo -e "${BLUE}ディレクトリ '${RULES_DIR}' を作成します...${NC}"
  mkdir -p "$RULES_DIR"
else
  echo -e "${BLUE}ディレクトリ '${RULES_DIR}' は既に存在します${NC}"
fi

# ダウンロード成功とスキップのカウンター
INSTALLED=0
SKIPPED=0

# 各ルールをダウンロード
for rule in "${RULES[@]}"; do
  target_file="$RULES_DIR/$rule.mdc"
  
  # ファイルが既に存在するか確認
  if [ -f "$target_file" ] && [ "$FORCE_UPDATE" = false ]; then
    echo -e "${YELLOW}ルール '${rule}' は既に存在します - スキップします${NC}"
    SKIPPED=$((SKIPPED+1))
    continue
  elif [ -f "$target_file" ]; then
    echo -e "${MAGENTA}ルール '${rule}' は既に存在します - 上書きします${NC}"
  else
    echo -e "${BLUE}ルール '${rule}' をダウンロード中...${NC}"
  fi
  
  # ルールをダウンロード
  curl -s -o "$target_file" "https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$BRANCH/.cursor/rules/$rule.mdc"
  if [ $? -eq 0 ]; then
    echo -e "    ${GREEN}✓ ${rule} をダウンロードしました${NC}"
    INSTALLED=$((INSTALLED+1))
  else
    echo -e "    ${RED}✗ ${rule} のダウンロードに失敗しました${NC}"
    exit 1
  fi
done

# PRテンプレートのダウンロード
if [ "$SKIP_PR_TEMPLATE" = false ]; then
  # .githubディレクトリがなければ作成
  if [ ! -d ".github" ]; then
    echo -e "${BLUE}ディレクトリ '.github' を作成します...${NC}"
    mkdir -p ".github"
  fi

  # PRテンプレートが既に存在するか確認
  if [ -f "$PR_TEMPLATE_DEST" ] && [ "$FORCE_UPDATE" = false ]; then
    echo -e "${YELLOW}プルリクエストテンプレートは既に存在します - スキップします${NC}"
    SKIPPED=$((SKIPPED+1))
  else
    if [ -f "$PR_TEMPLATE_DEST" ]; then
      echo -e "${MAGENTA}プルリクエストテンプレートは既に存在します - 上書きします${NC}"
    else
      echo -e "${BLUE}プルリクエストテンプレートをダウンロード中...${NC}"
    fi
    
    # PRテンプレートをダウンロード
    curl -s -o "$PR_TEMPLATE_DEST" "https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$BRANCH/$PR_TEMPLATE_SRC"
    if [ $? -eq 0 ]; then
      echo -e "    ${GREEN}✓ プルリクエストテンプレートをダウンロードしました${NC}"
      INSTALLED=$((INSTALLED+1))
    else
      echo -e "    ${RED}✗ プルリクエストテンプレートのダウンロードに失敗しました${NC}"
      # テンプレートのダウンロードは失敗してもプログラムは続行
    fi
  fi
fi

echo -e "\n${BOLD}${GREEN}ダウンロード完了！${NC}"
echo -e "${BOLD}結果サマリー:${NC}"
echo -e "
    ${GREEN}ダウンロード済み: ${INSTALLED}${NC}
    ${YELLOW}スキップ: ${SKIPPED}${NC}
    ${BLUE}合計: $((INSTALLED+SKIPPED))${NC}"

echo -e "\n${GREEN}Cursorエディタでこれらのルールを使用できるようになりました。${NC}"
if [ $SKIPPED -gt 0 ] && [ "$FORCE_UPDATE" = false ]; then
  echo -e "${YELLOW}注意: 既存のファイルはスキップされました。更新するには -f または --force オプションを使用してください。${NC}"
fi 