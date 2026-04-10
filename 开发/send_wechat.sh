#!/usr/bin/env bash
# 企业微信消息发送：JWT生成 + 请求发送
# 血缘: AccessKey+SecretKey → JWT → Bearer Authorization → POST /hxmsg/msg/send-enterprise-wechat

ACCESS_KEY="847f1741-80e8-4934-be67-203ffdc7c972"
SECRET_KEY="b1c72126-de63-4586-8034-5e5396ce7fd5"
BASE_URL="https://if.wchscu.net"
TTL=60

base64url() {
  openssl base64 -e -A 2>/dev/null | tr '+/' '-_' | tr -d '='
}

gen_token() {
  local now exp payload msg sig
  now=$(date +%s)
  exp=$((now + TTL))
  payload="{\"iss\":\"${ACCESS_KEY}\",\"exp\":${exp},\"iat\":${now}}"
  msg="$(echo -n '{"alg":"HS256","typ":"JWT"}' | base64url).$(echo -n "$payload" | base64url)"
  sig=$(echo -n "$msg" | openssl dgst -sha256 -hmac "$SECRET_KEY" -binary | base64url)
  echo "${msg}.${sig}"
}

send() {
  local wechat_ids="$1"
  local content="$2"
  local token url body_file
  token=$(gen_token)
  url="${BASE_URL}/hxmsg/msg/send-enterprise-wechat"
  body_file=$(mktemp)
  printf '{"wechatIds":%s,"content":"%s"}' "$wechat_ids" "$content" > "$body_file"
  curl -s -k -X POST "$url" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d @"$body_file" \
    --connect-timeout 10
  rm -f "$body_file"
}

# 读取文件内容发送到企业微信（空格和换行替换为 -）
send_from_file() {
  local file_path="${1:-/tmp/shared_output.txt}"
  local wechat_ids="${2:-[\"14905\"]}"
  local prefix="${3:-new-实时链路监控:}"
  local file_content processed

  [ -f "$file_path" ] || { echo "文件不存在: $file_path"; return 1; }
  file_content=$(<"$file_path")
  echo "读取到的内容: $file_content"
  processed=$(printf '%s' "$file_content" | tr '\n' '-' | tr ' ' '-')
  processed="${processed//\\/\\\\}"
  processed="${processed//\"/\\\"}"
  send "$wechat_ids" "${prefix}${processed}"
}

# 使用方式:
#   默认: 读 /tmp/shared_output.txt，发到 14905（若报 user invalid 请改为实际企业微信ID如 ["20208156"]）
#   自定义: send_from_file "/path/to/file" '["20208156"]' "自定义前缀:"
if [ -f "/tmp/shared_output.txt" ]; then
  send_from_file
fi
