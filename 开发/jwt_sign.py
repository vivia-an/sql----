"""
JWT签名生成模块
等效实现 H3C api-signature-sdk 中的 JwtSign.sign(accessKey, secretKey, timeToLiveSeconds)

Java原始逻辑（java-jwt-3.7.0 / auth0）:
    Algorithm algorithm = Algorithm.HMAC256(secretKey);
    String token = JWT.create()
        .withIssuer(accessKey)
        .withExpiresAt(new Date(now + ttl * 1000))
        .sign(algorithm);
    return token;

Python等效: PyJWT, HMAC-SHA256, iss=accessKey
"""
import time
import jwt


def jwt_sign(access_key: str, secret_key: str, time_to_live_seconds: int = 1800) -> str:
    """
    生成JWT鉴权token（等效Java JwtSign.sign）

    Args:
        access_key: 管理页面获取的AccessKey，作为JWT issuer
        secret_key: 管理页面获取的SecretKey，作为HMAC签名密钥
        time_to_live_seconds: token有效期(秒)，需小于认证策略配置的最大过期时间

    Returns:
        JWT token字符串，直接填入请求的 Authorization header
    """
    now = int(time.time())
    payload = {
        "iss": access_key,
        "exp": now + time_to_live_seconds,
        "iat": now,
    }
    token = jwt.encode(payload, secret_key, algorithm="HS256")
    # PyJWT >= 2.0 返回str，< 2.0 返回bytes，统一处理
    if isinstance(token, bytes):
        token = token.decode("utf-8")
    return token


if __name__ == "__main__":
    ACCESS_KEY = "847f1741-80e8-4934-be67-203ffdc7c972"
    SECRET_KEY = "b1c72126-de63-4586-8034-5e5396ce7fd5"

    # 服务端报 "exceeds maximum allowed expiration" 时需缩短ttl
    token = jwt_sign(ACCESS_KEY, SECRET_KEY, time_to_live_seconds=60)
    print("Authorization:", token)
