"""
企业微信消息发送：JWT生成 + 请求发送，合并为单脚本
血缘: AccessKey+SecretKey → JWT → Bearer Authorization → POST /hxmsg/msg/send-enterprise-wechat
"""
import json
import time
import jwt
import urllib.request

ACCESS_KEY = "847f1741-80e8-4934-be67-203ffdc7c972"
SECRET_KEY = "b1c72126-de63-4586-8034-5e5396ce7fd5"
BASE_URL = "https://if.wchscu.net"
TTL = 60


def gen_token() -> str:
    now = int(time.time())
    payload = {"iss": ACCESS_KEY, "exp": now + TTL, "iat": now}
    t = jwt.encode(payload, SECRET_KEY, algorithm="HS256")
    return t.decode("utf-8") if isinstance(t, bytes) else t


def send(wechat_ids: list[str], content: str) -> dict:
    token = gen_token()
    url = f"{BASE_URL}/hxmsg/msg/send-enterprise-wechat"
    body = json.dumps({"wechatIds": wechat_ids, "content": content}, ensure_ascii=False)
    req = urllib.request.Request(url, data=body.encode("utf-8"), method="POST")
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode())


if __name__ == "__main__":
    r = send(wechat_ids=["20208156"], content="测试内容")
    print(r)
