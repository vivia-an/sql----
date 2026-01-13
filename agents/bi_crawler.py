"""
BI报表爬虫测试脚本
用于爬取华西医院BI系统页面数据
"""
import os
import requests
from bs4 import BeautifulSoup
import json
import time
import sqlite3
import shutil
from pathlib import Path

# 设置代理地址
PROXY = "http://127.0.0.1:7897"
os.environ['HTTP_PROXY'] = PROXY
os.environ['HTTPS_PROXY'] = PROXY


class BICrawler:
    """BI报表爬虫"""
    
    def __init__(self, use_proxy=True, session_id=None):
        self.session = requests.Session()
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
            'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
        }
        
        # 如果提供了sessionId，添加到Cookie和Header
        if session_id:
            self.headers['X-Session-Id'] = session_id
            self.headers['sessionId'] = session_id
            self.session.cookies.set('sessionId', session_id, domain='hxdmc.wchscu.cn')
            self.session.cookies.set('JSESSIONID', session_id, domain='hxdmc.wchscu.cn')
            print(f"[INFO] 使用sessionId: {session_id[:20]}...")
        
        self.session.headers.update(self.headers)
        
        # 设置代理
        if use_proxy:
            self.proxies = {
                'http': PROXY,
                'https': PROXY
            }
            self.session.proxies.update(self.proxies)
            print(f"[INFO] 使用代理: {PROXY}")
        else:
            self.proxies = None
    
    def get_chrome_cookies(self, domain: str) -> dict:
        """从Chrome浏览器获取指定域名的Cookie"""
        cookies = {}
        
        # Chrome Cookie文件路径 (Windows)
        cookie_path = Path.home() / "AppData/Local/Google/Chrome/User Data/Default/Network/Cookies"
        
        if not cookie_path.exists():
            # 尝试其他可能的路径
            cookie_path = Path.home() / "AppData/Local/Google/Chrome/User Data/Default/Cookies"
        
        if not cookie_path.exists():
            print(f"[WARN] Chrome Cookie文件不存在: {cookie_path}")
            return cookies
        
        # 复制Cookie文件（因为Chrome可能锁定它）
        temp_cookie = Path("temp_cookies.db")
        try:
            shutil.copy2(cookie_path, temp_cookie)
            
            conn = sqlite3.connect(str(temp_cookie))
            cursor = conn.cursor()
            
            # 查询指定域名的cookie
            cursor.execute(
                "SELECT name, value, encrypted_value FROM cookies WHERE host_key LIKE ?",
                (f"%{domain}%",)
            )
            
            for name, value, encrypted_value in cursor.fetchall():
                if value:
                    cookies[name] = value
                # 注意：encrypted_value需要解密，这里暂时跳过
            
            conn.close()
            print(f"[INFO] 从Chrome获取到 {len(cookies)} 个Cookie")
            
        except Exception as e:
            print(f"[WARN] 获取Chrome Cookie失败: {e}")
        finally:
            if temp_cookie.exists():
                temp_cookie.unlink()
        
        return cookies
    
    def load_cookies_from_chrome(self, domain: str = "hxdmc.wchscu.cn"):
        """加载Chrome的Cookie到session"""
        cookies = self.get_chrome_cookies(domain)
        for name, value in cookies.items():
            self.session.cookies.set(name, value, domain=domain)
        return len(cookies) > 0
    
    def load_cookies_from_string(self, cookie_string: str, domain: str = "hxdmc.wchscu.cn"):
        """从Cookie字符串加载（从浏览器开发者工具复制）
        
        格式: name1=value1; name2=value2; ...
        """
        if not cookie_string:
            return False
        
        count = 0
        for item in cookie_string.split(';'):
            item = item.strip()
            if '=' in item:
                name, value = item.split('=', 1)
                self.session.cookies.set(name.strip(), value.strip(), domain=domain)
                count += 1
        
        print(f"[INFO] 加载了 {count} 个Cookie")
        return count > 0
    
    def crawl_with_jwt(self, url: str) -> dict:
        """使用JWT令牌爬取页面"""
        result = {
            "success": False,
            "status_code": None,
            "content_type": None,
            "content_length": 0,
            "html": None,
            "text": None,
            "error": None
        }
        
        try:
            print(f"正在请求URL: {url[:100]}...")
            # 先不跟随重定向，查看重定向信息
            response = self.session.get(url, timeout=30, allow_redirects=False)
            
            # 如果是重定向，打印Location并跟随
            if response.status_code in [301, 302, 303, 307, 308]:
                location = response.headers.get('Location', '')
                print(f"   重定向状态码: {response.status_code}")
                print(f"   Location: {location}")
                print(f"   所有响应头: {dict(response.headers)}")
                
                # 获取服务器设置的Cookie
                if response.cookies:
                    print(f"   服务器设置Cookie: {dict(response.cookies)}")
                
                # 跟随重定向
                if location:
                    response = self.session.get(location, timeout=30, allow_redirects=True)
                else:
                    # Location为空，可能是需要刷新页面
                    print("   [WARN] Location为空，尝试重新请求...")
                    response = self.session.get(url, timeout=30, allow_redirects=True)
            
            result["status_code"] = response.status_code
            result["content_type"] = response.headers.get('Content-Type', '')
            result["content_length"] = len(response.text)
            result["html"] = response.text
            
            # 检查是否JWT过期（支持各种编码形式）
            # UTF-8中文被误读时的实际字符串
            jwt_expired_patterns = [
                "jwt过期", "jwt异常", 
                "jwtè¿\x87æ\x9c\x9f",  # jwt过期 的乱码形式
                "jwtå¼\x82å¸¸",  # jwt异常 的乱码形式
                "jwt expired", "token expired", "jwt error"
            ]
            html_text = response.text
            for pattern in jwt_expired_patterns:
                if pattern.lower() in html_text.lower():
                    result["error"] = "JWT令牌已过期"
                    result["jwt_expired"] = True
                    result["html"] = response.text
                    print(f"[X] JWT令牌已过期")
                    return result
            
            result["success"] = True
            print(f"[OK] 请求成功，状态码: {response.status_code}")
            print(f"   Content-Type: {result['content_type']}")
            print(f"   内容长度: {result['content_length']} 字符")
            
            # 解析HTML
            soup = BeautifulSoup(response.text, 'html.parser')
            result["text"] = soup.get_text(separator='\n', strip=True)
            
            # 提取页面标题
            title = soup.find('title')
            if title:
                print(f"   页面标题: {title.text}")
            
            # 提取所有表格数据
            tables = soup.find_all('table')
            if tables:
                print(f"   发现 {len(tables)} 个表格")
                result["tables"] = []
                for i, table in enumerate(tables):
                    rows = table.find_all('tr')
                    table_data = []
                    for row in rows:
                        cells = row.find_all(['td', 'th'])
                        row_data = [cell.get_text(strip=True) for cell in cells]
                        if row_data:
                            table_data.append(row_data)
                    result["tables"].append(table_data)
                    print(f"   表格{i+1}: {len(table_data)} 行")
            
            # 提取所有脚本中的数据（有些BI系统用JS渲染数据）
            scripts = soup.find_all('script')
            for script in scripts:
                if script.string and 'data' in script.string.lower():
                    print(f"   发现可能包含数据的脚本")
            
        except requests.exceptions.Timeout:
            result["error"] = "请求超时"
            print("[X] 请求超时")
        except requests.exceptions.RequestException as e:
            result["error"] = str(e)
            print(f"[X] 请求错误: {e}")
        except Exception as e:
            result["error"] = str(e)
            print(f"[X] 未知错误: {e}")
        
        return result
    
    def save_result(self, result: dict, filename: str = "crawl_result"):
        """保存爬取结果"""
        # 保存HTML
        if result.get("html"):
            html_file = f"{filename}.html"
            with open(html_file, 'w', encoding='utf-8') as f:
                f.write(result["html"])
            print(f"HTML已保存到: {html_file}")
        
        # 保存JSON结果（不含html原文）
        json_result = {k: v for k, v in result.items() if k != 'html'}
        json_file = f"{filename}.json"
        with open(json_file, 'w', encoding='utf-8') as f:
            json.dump(json_result, f, ensure_ascii=False, indent=2)
        print(f"JSON已保存到: {json_file}")


def crawl_with_selenium(url: str, cookies: dict = None, wait_time: int = 10, use_proxy: bool = False):
    """使用Selenium爬取（适用于JS渲染的页面）
    
    Args:
        url: 目标URL
        cookies: Cookie字典，格式 {name: value}
        wait_time: 等待JS渲染的时间（秒）
        use_proxy: 是否使用代理
    """
    # 临时清除代理环境变量，防止影响ChromeDriver
    proxy_vars = ['HTTP_PROXY', 'HTTPS_PROXY', 'http_proxy', 'https_proxy', 'NO_PROXY', 'no_proxy']
    saved_env = {}
    for var in proxy_vars:
        if var in os.environ:
            saved_env[var] = os.environ.pop(var)
    
    try:
        from selenium import webdriver
        from selenium.webdriver.chrome.options import Options
        from selenium.webdriver.chrome.service import Service
        from selenium.webdriver.common.by import By
        from selenium.webdriver.support.ui import WebDriverWait
        from selenium.webdriver.support import expected_conditions as EC
    except ImportError:
        print("[X] 需要安装selenium: pip install selenium")
        return None
    
    chrome_options = Options()
    # chrome_options.add_argument('--headless')  # 无头模式，调试时注释掉
    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--disable-dev-shm-usage')
    chrome_options.add_argument('--ignore-certificate-errors')
    chrome_options.add_argument('--disable-gpu')
    chrome_options.add_argument('--window-size=1920,1080')
    print("[INFO] Selenium直接连接（已清除代理环境变量）")
    
    driver = None
    try:
        driver = webdriver.Chrome(options=chrome_options)
        driver.set_page_load_timeout(60)
        
        # 先访问目标域名以设置Cookie
        domain_url = "https://hxdmc.wchscu.cn/"
        print(f"[INFO] 先访问域名设置Cookie: {domain_url}")
        driver.get(domain_url)
        time.sleep(2)
        
        # 添加Cookie（不指定domain，让浏览器自动处理）
        if cookies:
            print(f"[INFO] 设置 {len(cookies)} 个Cookie...")
            for name, value in cookies.items():
                try:
                    # 简单的cookie格式，不指定domain
                    cookie_dict = {
                        'name': name,
                        'value': value,
                    }
                    driver.add_cookie(cookie_dict)
                    print(f"   添加Cookie: {name} = {value[:20]}...")
                except Exception as e:
                    print(f"   [WARN] 添加Cookie {name} 失败: {e}")
        
        # 访问目标URL
        print(f"[INFO] Selenium访问: {url[:80]}...")
        driver.get(url)
        
        # 等待JS渲染
        print(f"[INFO] 等待页面加载 {wait_time} 秒...")
        time.sleep(wait_time)
        
        # 检查JWT是否过期
        page_source = driver.page_source
        if "jwt过期" in page_source or "jwt异常" in page_source:
            print("[X] JWT令牌已过期")
            driver.save_screenshot("bi_jwt_expired.png")
            return None
        
        print(f"[OK] 页面标题: {driver.title}")
        print(f"   当前URL: {driver.current_url[:80]}...")
        
        # 截图
        screenshot_file = "bi_screenshot.png"
        driver.save_screenshot(screenshot_file)
        print(f"   截图已保存: {screenshot_file}")
        
        # 获取页面源码（JS渲染后）
        html = driver.page_source
        print(f"   页面HTML长度: {len(html)} 字符")
        
        # 保存HTML
        with open("bi_selenium_result.html", 'w', encoding='utf-8') as f:
            f.write(html)
        print("   HTML已保存: bi_selenium_result.html")
        
        # 尝试提取表格数据
        try:
            tables = driver.find_elements(By.TAG_NAME, 'table')
            print(f"   发现 {len(tables)} 个表格")
            
            # 尝试查找报表元素
            report_elements = driver.find_elements(By.CLASS_NAME, 'yh-grid')
            print(f"   发现 {len(report_elements)} 个报表网格")
        except Exception as e:
            print(f"   [WARN] 提取元素失败: {e}")
        
        return html
        
    except Exception as e:
        print(f"[X] Selenium错误: {e}")
        import traceback
        traceback.print_exc()
        return None
    finally:
        if driver:
            driver.quit()
        # 恢复代理环境变量
        for var, value in saved_env.items():
            os.environ[var] = value


def crawl_with_scroll(url: str, cookies: dict = None, wait_time: int = 10, max_scrolls: int = 50):
    """使用Selenium滚动页面获取所有数据
    
    Args:
        url: 目标URL
        cookies: Cookie字典
        wait_time: 初始等待时间
        max_scrolls: 最大滚动次数
    
    Returns:
        包含所有数据的字典
    """
    from bs4 import BeautifulSoup
    import re
    import json
    
    saved_env = {}
    for var in ['HTTP_PROXY', 'HTTPS_PROXY', 'http_proxy', 'https_proxy']:
        if var in os.environ:
            saved_env[var] = os.environ.pop(var)
    
    try:
        from selenium import webdriver
        from selenium.webdriver.chrome.options import Options
        from selenium.webdriver.common.by import By
        from selenium.webdriver.common.keys import Keys
    except ImportError:
        print("[X] 需要安装selenium: pip install selenium")
        return None
    
    chrome_options = Options()
    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--disable-dev-shm-usage')
    chrome_options.add_argument('--ignore-certificate-errors')
    chrome_options.add_argument('--disable-gpu')
    chrome_options.add_argument('--window-size=1920,1080')
    
    driver = None
    all_data = {}  # 用字典存储，自动去重
    
    try:
        driver = webdriver.Chrome(options=chrome_options)
        driver.set_page_load_timeout(60)
        
        # 设置Cookie
        print(f"[INFO] 先访问域名设置Cookie...")
        driver.get("https://hxdmc.wchscu.cn/")
        time.sleep(2)
        
        if cookies:
            for name, value in cookies.items():
                try:
                    driver.add_cookie({'name': name, 'value': value})
                except:
                    pass
        
        # 访问目标URL
        print(f"[INFO] 访问报表页面...")
        driver.get(url)
        time.sleep(wait_time)
        
        print(f"[OK] 页面标题: {driver.title}")
        
        # 查找滚动容器
        scroll_container = None
        try:
            containers = driver.find_elements(By.CSS_SELECTOR, '[style*="overflow"]')
            for c in containers:
                style = c.get_attribute('style') or ''
                if 'scroll' in style or 'auto' in style:
                    height = c.size.get('height', 0)
                    if height > 200:
                        scroll_container = c
                        print(f"[INFO] 找到滚动容器，高度: {height}px")
                        break
        except Exception as e:
            print(f"[WARN] 查找滚动容器失败: {e}")
        
        # 提取当前页面数据的函数
        def extract_current_data():
            html = driver.page_source
            soup = BeautifulSoup(html, 'html.parser')
            
            divs_with_pos = soup.find_all('div', style=re.compile(r'position.*absolute'))
            groups = {}
            
            for div in divs_with_pos:
                style = div.get('style', '')
                top_match = re.search(r'top:\s*(\d+)', style)
                left_match = re.search(r'left:\s*(\d+)', style)
                if top_match:
                    top = int(top_match.group(1))
                    left = int(left_match.group(1)) if left_match else 0
                    content = div.get_text(strip=True)
                    if content and len(content) < 100:
                        if top not in groups:
                            groups[top] = []
                        groups[top].append((left, content))
            
            data = {}
            for top, items in groups.items():
                items_sorted = sorted(items, key=lambda x: x[0])
                values = [v[1] for v in items_sorted]
                
                if len(values) >= 2 and '四川大学' in values[0]:
                    key = f"{values[0]}|{values[1]}"
                    data[key] = values
            
            return data
        
        # 滚动并收集数据
        print(f"[INFO] 开始滚动收集数据（最多{max_scrolls}次）...")
        
        last_count = 0
        no_new_data_count = 0
        
        for scroll_num in range(max_scrolls):
            current_data = extract_current_data()
            all_data.update(current_data)
            
            current_count = len(all_data)
            new_count = current_count - last_count
            
            if new_count > 0:
                print(f"   滚动 {scroll_num + 1}: 新增 {new_count} 条，累计 {current_count} 条")
                no_new_data_count = 0
            else:
                no_new_data_count += 1
            
            last_count = current_count
            
            if no_new_data_count >= 3:
                print("[OK] 已滚动到底部，数据收集完成")
                break
            
            # 执行滚动
            try:
                if scroll_container:
                    driver.execute_script("arguments[0].scrollTop += 300;", scroll_container)
                else:
                    body = driver.find_element(By.TAG_NAME, 'body')
                    body.send_keys(Keys.PAGE_DOWN)
            except:
                driver.execute_script("window.scrollBy(0, 300);")
            
            time.sleep(0.8)
        
        driver.save_screenshot("bi_screenshot_final.png")
        print(f"[OK] 最终截图: bi_screenshot_final.png")
        
        # 整理数据
        result_data = []
        for key, values in all_data.items():
            parts = key.split('|')
            result_data.append({
                '医院': parts[0],
                '科室': parts[1] if len(parts) > 1 else '',
                '数据': values[2:] if len(values) > 2 else []
            })
        
        with open('bi_full_data.json', 'w', encoding='utf-8') as f:
            json.dump(result_data, f, ensure_ascii=False, indent=2)
        print(f"[OK] 完整数据已保存: bi_full_data.json ({len(result_data)} 条)")
        
        return {
            'success': True,
            'total_rows': len(result_data),
            'data': result_data
        }
        
    except Exception as e:
        print(f"[X] 滚动爬取错误: {e}")
        import traceback
        traceback.print_exc()
        return None
    finally:
        if driver:
            driver.quit()
        for var, value in saved_env.items():
            os.environ[var] = value


def build_bi_url(db_path: str) -> str:
    """根据db路径构建完整的BI报表URL
    
    Args:
        db_path: 报表db路径，例如 "!28!01!29!!534e!!897f!...!.db" 或完整URL
    
    Returns:
        完整的BI报表URL
    """
    # 如果已经是完整URL，直接返回
    if db_path.startswith("http"):
        # 移除可能存在的JWT参数
        if "&yhjwt=" in db_path:
            db_path = db_path.split("&yhjwt=")[0]
        return db_path
    
    # 构建URL
    base_url = "https://hxdmc.wchscu.cn/bi/sso"
    params = f"?proc=1&action=viewer&hback=true&db={db_path}&platform=PC&browerType=chrome"
    return base_url + params


def crawl_bi_report(db_path: str, output_prefix: str = "bi_report", full_data: bool = False) -> dict:
    """爬取BI报表的主函数
    
    Args:
        db_path: 报表db路径或完整URL
        output_prefix: 输出文件前缀
        full_data: 是否获取完整数据（滚动页面）
    
    Returns:
        爬取结果字典
    """
    url = build_bi_url(db_path)
    
    print("=" * 60)
    print(f"BI报表爬虫 {'(完整数据模式)' if full_data else ''}")
    print(f"URL: {url[:80]}...")
    print("=" * 60)
    
    # 从cookies.txt读取Cookie
    cookie_file = Path("cookies.txt")
    cookies_dict = {}
    if cookie_file.exists():
        cookie_string = cookie_file.read_text(encoding='utf-8').strip()
        for item in cookie_string.split(';'):
            item = item.strip()
            if '=' in item:
                name, value = item.split('=', 1)
                cookies_dict[name.strip()] = value.strip()
    
    if full_data:
        # 滚动获取完整数据
        print("\n使用滚动模式获取完整数据...")
        print("-" * 40)
        result = crawl_with_scroll(url, cookies=cookies_dict, wait_time=15, max_scrolls=100)
        
        if result and result.get('success'):
            print(f"[OK] 完整数据已获取: {result['total_rows']} 条")
            return result
        else:
            print("[X] 完整数据获取失败")
            return {"success": False, "data": None, "url": url}
    else:
        # 普通模式：只获取当前可见数据
        print("\n使用Selenium爬取（JS渲染）...")
        print("-" * 40)
        
        result = crawl_with_selenium(url, cookies=cookies_dict, wait_time=15)
        
        if result:
            with open(f"{output_prefix}.html", 'w', encoding='utf-8') as f:
                f.write(result)
            print(f"[OK] HTML已保存: {output_prefix}.html")
            print(f"[OK] 截图已保存: bi_screenshot.png")
            return {"success": True, "html": result, "url": url}
        else:
            print("[X] 爬取失败")
            return {"success": False, "html": None, "url": url}


def main():
    """主函数 - 支持命令行参数
    
    用法:
        python bi_crawler.py [报表URL或db路径] [--full]
        
        --full: 滚动获取完整数据（默认只获取可见区域数据）
    
    示例:
        python bi_crawler.py                           # 使用默认报表
        python bi_crawler.py "完整URL"                  # 指定报表URL
        python bi_crawler.py "db路径" --full           # 获取完整数据
    """
    import sys
    
    # 默认报表db路径
    default_db = "!28!01!29!!534e!!897f!!62a5!!8868!!95e8!!6237!!2f!!8fd0!!8425!!7ba1!!7406!!90e8!!2f!!533b!!7597!!7ec4!!957f!!8bc4!!4ef7!.db"
    
    # 解析参数
    args = sys.argv[1:]
    full_data = '--full' in args
    if full_data:
        args.remove('--full')
    
    # 获取db路径
    if args:
        db_path = args[0]
        print(f"[INFO] 使用命令行参数: {db_path[:60]}...")
    else:
        db_path = default_db
        print(f"[INFO] 使用默认报表")
    
    if full_data:
        print("[INFO] 启用完整数据模式（滚动获取所有数据）")
    
    # 爬取报表
    result = crawl_bi_report(db_path, full_data=full_data)
    
    print("\n" + "=" * 60)
    print("爬取完成！")
    return result


if __name__ == "__main__":
    main()
