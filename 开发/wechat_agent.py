"""
企业微信消息发送 Agent
血缘: AccessKey+SecretKey → jwt_sign() → Authorization Header → POST /hxmsg/msg/send-enterprise-wechat
"""
import requests
import logging
from typing import Union
from jwt_sign import jwt_sign

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

# ---------- 配置 ----------
BASE_URL = "https://if.wchscu.net"
ACCESS_KEY = "847f1741-80e8-4934-be67-203ffdc7c972"
SECRET_KEY = "b1c72126-de63-4586-8034-5e5396ce7fd5"
TOKEN_TTL = 60  # 秒，服务端限制较严，需小于认证策略最大过期时间


class WechatAgent:
    """企业微信消息发送 Agent，自动处理JWT鉴权"""

    def __init__(self, base_url: str = BASE_URL, access_key: str = ACCESS_KEY, secret_key: str = SECRET_KEY):
        self.base_url = base_url.rstrip("/")
        self.access_key = access_key
        self.secret_key = secret_key

    def _get_auth_header(self) -> dict:
        token = jwt_sign(self.access_key, self.secret_key, TOKEN_TTL)
        logger.info("[JWT] 生成token成功 (iss=%s, ttl=%ds)", self.access_key, TOKEN_TTL)
        return {"Authorization": token, "Content-Type": "application/json"}

    def send_enterprise_wechat(self, wechat_ids: list[str], content: str) -> dict:
        """
        发送企业微信消息

        Args:
            wechat_ids: 接收人的企业微信ID列表
            content: 消息内容

        Returns:
            接口响应dict，格式: { code, message, data }
        """
        url = f"{self.base_url}/hxmsg/msg/send-enterprise-wechat"
        headers = self._get_auth_header()
        body = {"wechatIds": wechat_ids, "content": content}

        logger.info("[Agent] 发送企业微信 → %s, 接收人: %s", url, wechat_ids)
        resp = requests.post(url, json=body, headers=headers, timeout=30)
        resp.raise_for_status()
        result = resp.json()
        logger.info("[Agent] 响应: code=%s, message=%s", result.get("code"), result.get("message"))
        return result


# ---------- Agent 编排入口 ----------
def run_agent(wechat_ids: Union[str, list], content: str) -> dict:
    """
    Agent编排主入口
    步骤:
        1. 初始化 WechatAgent (注入AccessKey/SecretKey)
        2. 生成 JWT token (JwtSign等效逻辑)
        3. 发送企业微信消息
        4. 返回结果

    Args:
        wechat_ids: 单个ID字符串或ID列表
        content: 消息内容
    """
    if isinstance(wechat_ids, str):
        wechat_ids = [wechat_ids]

    agent = WechatAgent()
    return agent.send_enterprise_wechat(wechat_ids, content)


if __name__ == "__main__":
    result = run_agent(
        wechat_ids=["20208156", "小马车"],
        content="测试内容"
    )
    print(result)
