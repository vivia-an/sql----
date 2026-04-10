import jwt
import time
from typing import Optional


class JwtUtils:
    """JWT工具类，用于生成JWT token"""
    
    # JWT签名密钥
    SECRET_KEY = "huaxiyiyuanxxzx_visind_secret_bi"
    
    # 签发者
    ISSUER = "7DF322CBA4EB466B5CAEB8FCAAECCD16"
    
    @staticmethod
    def get_yh_jwt(usercode: str) -> Optional[str]:
        """
        生成JWT token
        
        Args:
            usercode: 用户代码
            
        Returns:
            JWT token字符串，如果生成失败则返回None
        """
        try:
            # 构建claims
            claims = {
                "loginname": usercode,
                "iss": JwtUtils.ISSUER,
                "exp": int(time.time()) + 18000000,  # 当前时间 + 18000秒（5小时）
                "sub": usercode  # subject
            }
            
            # 生成JWT token
            token = jwt.encode(
                claims,
                JwtUtils.SECRET_KEY,
                algorithm="HS256"
            )
            
            return token
            
        except Exception as e:
            print(f"生成JWT失败: {e}")
            import traceback
            traceback.print_exc()
            return None


if __name__ == "__main__":
    # 测试代码
    token = JwtUtils.get_yh_jwt("20238061")
    print(token)
