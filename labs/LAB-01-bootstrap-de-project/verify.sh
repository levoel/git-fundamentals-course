#!/usr/bin/env bash
# verify.sh — проверяет, что LAB-01 выполнена корректно.
#
# Usage:
#   bash verify.sh <path-to-project>
#
# Например:
#   bash verify.sh ~/de-projects/orders-pipeline
#
# Скрипт НЕ изменяет твой репозиторий — только читает и сравнивает.

set -u

PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || {
  echo "[FAIL] directory not found: $1"
  exit 1
}

cd "$PROJECT_DIR"

PASS=0
FAIL=0

ok() {
  echo "[OK]   $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "[FAIL] $1"
  FAIL=$((FAIL + 1))
}

note() {
  echo "       $1"
}

echo "Verifying LAB-01 in: $PROJECT_DIR"
echo "----------------------------------------"

# --- 1. git repository ---
if [ -d ".git" ]; then
  ok "git repository initialized"
else
  fail ".git/ directory missing — did you run 'git init'?"
fi

# --- 2. default branch is main ---
default_branch="$(git symbolic-ref --short HEAD 2>/dev/null || echo "")"
if [ "$default_branch" = "main" ] || git show-ref --verify --quiet refs/heads/main; then
  ok "main branch exists"
else
  fail "main branch not found (current HEAD: $default_branch)"
fi

# --- 3. core files ---
for f in ".gitignore" ".pre-commit-config.yaml" "pyproject.toml" "README.md"; do
  if [ -f "$f" ]; then
    ok "$f present"
  else
    fail "$f missing"
  fi
done

# --- 4. .gitignore content sanity ---
if [ -f ".gitignore" ]; then
  if grep -qE '^\.env' .gitignore && grep -qE '\*\.parquet' .gitignore && grep -qE '__pycache__' .gitignore; then
    ok ".gitignore covers .env, *.parquet, __pycache__"
  else
    fail ".gitignore missing critical DE patterns (.env, *.parquet, __pycache__)"
  fi
fi

# --- 5. README placeholders removed ---
if [ -f "README.md" ]; then
  if grep -qE '\{\{[^}]+\}\}' README.md; then
    fail "README.md still contains {{placeholder}} — fill them in"
    grep -nE '\{\{[^}]+\}\}' README.md | head -5 | sed 's/^/       /'
  else
    ok "README.md has no unfilled placeholders"
  fi
fi

# --- 6. pre-commit hook installed ---
if [ -f ".git/hooks/pre-commit" ]; then
  if grep -q "pre-commit" .git/hooks/pre-commit 2>/dev/null; then
    ok ".git/hooks/pre-commit installed by pre-commit framework"
  else
    fail ".git/hooks/pre-commit exists but doesn't look like pre-commit framework hook"
  fi
else
  fail ".git/hooks/pre-commit missing — did you run 'pre-commit install'?"
fi

# --- 7. pre-commit run passes ---
if command -v pre-commit >/dev/null 2>&1; then
  if pre-commit run --all-files >/tmp/lab01-precommit.log 2>&1; then
    ok "pre-commit run --all-files passes"
  else
    fail "pre-commit run --all-files failed — see /tmp/lab01-precommit.log"
    tail -20 /tmp/lab01-precommit.log | sed 's/^/       /'
  fi
else
  fail "pre-commit CLI not found in PATH"
fi

# --- 8. remote configured ---
if git remote get-url origin >/dev/null 2>&1; then
  remote_url="$(git remote get-url origin)"
  ok "origin remote configured: $remote_url"
else
  fail "no 'origin' remote configured — did you 'gh repo create' or 'git remote add'?"
fi

# --- 9. feature branch exists ---
if git show-ref --verify --quiet refs/heads/feat/initial-pipeline; then
  ok "feat/initial-pipeline branch exists"
  if git ls-tree -r feat/initial-pipeline --name-only 2>/dev/null | grep -q "^dags/orders_etl.py$"; then
    ok "dags/orders_etl.py present on feat/initial-pipeline"
  else
    fail "dags/orders_etl.py missing on feat/initial-pipeline"
  fi
else
  fail "feat/initial-pipeline branch not found"
fi

# --- 10. at least 2 commits total ---
total_commits="$(git rev-list --all --count 2>/dev/null || echo 0)"
if [ "$total_commits" -ge 2 ]; then
  ok "at least 2 commits in repository ($total_commits total)"
else
  fail "expected at least 2 commits, found $total_commits"
fi

# --- 11. gh PR opened (optional, only warns if missing) ---
if command -v gh >/dev/null 2>&1; then
  if gh pr list --head feat/initial-pipeline --json number --jq 'length' 2>/dev/null | grep -qE '^[1-9]'; then
    ok "PR open from feat/initial-pipeline"
  else
    note "no open PR found — open one via: gh pr create"
  fi
else
  note "gh CLI not installed — skipping PR check"
fi

echo "----------------------------------------"
echo "Passed: $PASS    Failed: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
