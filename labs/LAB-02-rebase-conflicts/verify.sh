#!/usr/bin/env bash
# verify.sh — проверяет, что LAB-02 выполнена корректно.
#
# Usage:
#   bash verify.sh <path-to-lab02-repo>
#
# Например:
#   bash verify.sh ~/de-projects/lab02-rebase

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

echo "Verifying LAB-02 in: $PROJECT_DIR"
echo "----------------------------------------"

# --- 1. on feature/etl-loader branch ---
current_branch="$(git symbolic-ref --short HEAD 2>/dev/null || echo "")"
if [ "$current_branch" = "feature/etl-loader" ]; then
  ok "on branch feature/etl-loader"
else
  fail "expected to be on feature/etl-loader, currently on: $current_branch"
fi

# --- 2. feature/etl-loader is rebased on main (linear) ---
if git show-ref --verify --quiet refs/heads/main; then
  merge_base="$(git merge-base feature/etl-loader main 2>/dev/null || echo "")"
  main_head="$(git rev-parse main 2>/dev/null || echo "")"
  if [ -n "$merge_base" ] && [ "$merge_base" = "$main_head" ]; then
    ok "feature/etl-loader is rebased onto main (merge-base == main HEAD)"
  else
    fail "feature/etl-loader is NOT rebased onto main"
    note "merge-base: $merge_base"
    note "main HEAD:  $main_head"
  fi
else
  fail "main branch not found"
fi

# --- 3. no merge commits on feature/etl-loader ---
merge_commits="$(git log --merges main..feature/etl-loader --oneline 2>/dev/null | wc -l | tr -d ' ')"
if [ "$merge_commits" = "0" ]; then
  ok "no merge commits on feature/etl-loader (linear history)"
else
  fail "found $merge_commits merge commits on feature/etl-loader (expected 0)"
fi

# --- 4. feature has 1-2 commits relative to main (after squash/fixup) ---
feature_commits="$(git rev-list --count main..feature/etl-loader 2>/dev/null || echo 0)"
if [ "$feature_commits" -ge 1 ] && [ "$feature_commits" -le 2 ]; then
  ok "feature/etl-loader has $feature_commits commit(s) relative to main (expected 1-2 after squash)"
else
  fail "feature/etl-loader has $feature_commits commits — expected 1 or 2 (you should have used fixup/squash)"
fi

# --- 5. no WIP-style commit messages ---
if git log main..feature/etl-loader --pretty=%s 2>/dev/null | grep -qiE '(^WIP|^wip|^fix typo$|^asdf|^stash)'; then
  fail "feature/etl-loader still has WIP-style commit messages — did you fixup them?"
  git log main..feature/etl-loader --pretty=%s | sed 's/^/       /'
else
  ok "no WIP/typo commit messages on feature/etl-loader"
fi

# --- 6. src/etl.py exists and is clean ---
if [ -f "src/etl.py" ]; then
  ok "src/etl.py exists"

  if grep -qE '^(<<<<<<<|=======|>>>>>>>)' src/etl.py; then
    fail "src/etl.py still contains conflict markers"
    grep -nE '^(<<<<<<<|=======|>>>>>>>)' src/etl.py | sed 's/^/       /'
  else
    ok "src/etl.py has no conflict markers"
  fi

  if grep -qE 'def load_orders\(df: pd\.DataFrame, table: str\) -> int:' src/etl.py; then
    ok "src/etl.py has typed load_orders signature"
  else
    fail "src/etl.py missing typed signature 'def load_orders(df: pd.DataFrame, table: str) -> int:'"
  fi

  if grep -qE 'raise NotImplementedError' src/etl.py; then
    fail "src/etl.py still has 'raise NotImplementedError' — you didn't merge the real implementation"
  else
    ok "src/etl.py has real implementation (no NotImplementedError stub)"
  fi

  if grep -qE 'if df\.empty:' src/etl.py; then
    ok "src/etl.py handles empty dataframe in load_orders"
  else
    fail "src/etl.py missing 'if df.empty:' check in load_orders"
  fi

  if grep -qE 'from src\.db import engine' src/etl.py; then
    ok "src/etl.py imports engine from src.db"
  else
    fail "src/etl.py missing 'from src.db import engine'"
  fi

  if grep -qE 'df\.to_sql\(table, engine' src/etl.py; then
    ok "src/etl.py calls df.to_sql(table, engine, ...)"
  else
    fail "src/etl.py missing df.to_sql(table, engine, ...) call"
  fi
else
  fail "src/etl.py missing"
fi

# --- 7. force push: remote matches local (if remote exists) ---
if git remote get-url origin >/dev/null 2>&1; then
  local_head="$(git rev-parse feature/etl-loader 2>/dev/null || echo "")"
  remote_head="$(git rev-parse origin/feature/etl-loader 2>/dev/null || echo "")"
  if [ -n "$remote_head" ] && [ "$local_head" = "$remote_head" ]; then
    ok "origin/feature/etl-loader matches local HEAD (force-push successful)"
  else
    fail "origin/feature/etl-loader does NOT match local — did you 'git push --force-with-lease'?"
    note "local:  $local_head"
    note "remote: $remote_head"
  fi
else
  note "no origin remote — skipping force-push check"
fi

# --- 8. no uncommitted changes ---
if [ -z "$(git status --porcelain)" ]; then
  ok "working tree clean"
else
  fail "working tree has uncommitted changes"
  git status --short | sed 's/^/       /'
fi

# --- 9. no rebase in progress ---
if [ -d ".git/rebase-merge" ] || [ -d ".git/rebase-apply" ]; then
  fail "rebase is still in progress — finish it with 'git rebase --continue' or abort with 'git rebase --abort'"
else
  ok "no rebase in progress"
fi

echo "----------------------------------------"
echo "Passed: $PASS    Failed: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
