#!/usr/bin/env bash
# 启动蓝图 HTML 本地预览服务（端口 8766）
cd "$(dirname "$0")"
PORT=8766
if ss -ltn | grep -q ":${PORT} "; then
  echo "服务已在运行: http://127.0.0.1:${PORT}/新一代大数据平台_1234蓝图.html"
  exit 0
fi
nohup python3 -u -m http.server "$PORT" --bind 0.0.0.0 > /tmp/blueprint-preview.log 2>&1 &
echo "已启动: http://127.0.0.1:${PORT}/新一代大数据平台_1234蓝图.html"
echo "日志: /tmp/blueprint-preview.log"
