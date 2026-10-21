#!/bin/bash
# 用法：./deploy.sh <GitHub用户名> <Token> [仓库名] [private|public]
set -e
USER="$1"; TOKEN="$2"; REPO="${3:-wy-property-func-map}"; VIS="${4:-public}"
PRIV=false; [ "$VIS" = "private" ] && PRIV=true
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

echo "== 1/4 初始化本地仓库 =="
git init -q -b main 2>/dev/null || true
git add -A
git -c user.name="wy-map" -c user.email="noreply@example.com" \
    commit -q -m "功能地图与研判台 · 243 项 · 四大升级专题" 2>/dev/null \
    || git -c user.name="wy-map" -c user.email="noreply@example.com" commit -q --amend --no-edit

echo "== 2/4 创建远程仓库 $USER/$REPO (private=$PRIV) =="
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" \
  https://api.github.com/user/repos \
  -d "{\"name\":\"$REPO\",\"private\":$PRIV,\"auto_init\":false,\"description\":\"智慧物业重构 · 功能地图与研判台\"}" \
  | grep -o '"full_name":[^,]*\|"message":[^,]*' | head -2

echo "== 3/4 推送 =="
git remote remove origin 2>/dev/null || true
git remote add origin "https://x-access-token:$TOKEN@github.com/$USER/$REPO.git"
git push -q -u origin main --force

echo "== 4/4 开启 GitHub Pages =="
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$USER/$REPO/pages" \
  -d '{"source":{"branch":"main","path":"/"}}' | grep -o '"html_url":[^,]*\|"message":[^,]*' | head -2

echo
echo "等待 Pages 构建（约 30-60 秒）…"
sleep 25
curl -s -H "Authorization: Bearer $TOKEN" "https://api.github.com/repos/$USER/$REPO/pages" \
  | grep -o '"html_url":[^,]*\|"status":[^,]*'
echo
echo "访问地址： https://$USER.github.io/$REPO/"
