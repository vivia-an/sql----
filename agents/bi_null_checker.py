"""
BI报表空值检查Agent
检测永洪BI报表页面中的空值/缺失值，生成检查报告
血缘: bi_crawler.py(复用认证+滚动) -> bi_null_checker.py(空值检测) -> 报告输出
"""
import json
import os
import re
import time
from datetime import datetime
from pathlib import Path
from dataclasses import dataclass, field, asdict
from typing import List, Dict, Optional, Tuple
from bs4 import BeautifulSoup

# 空值匹配模式
NULL_PATTERNS = [
    "",           # 空字符串
    "null",       # null文本
    "NULL",
    "None",
    "-",          # 短横线占位
    "--",
    "N/A",
    "n/a",
    "NA",
    "NaN",
    "undefined",
]

# 可选：零值也可作为空值标记
ZERO_PATTERNS = ["0", "0.00", "0.0", ".00"]


@dataclass
class NullCell:
    """单个空值单元格"""
    row_idx: int
    col_idx: int
    row_label: str      # 行标识(如科室名)
    col_label: str      # 列标识(如指标名)
    cell_value: str      # 原始值
    null_type: str       # 空值类型: empty/null_text/dash/zero/na

    def to_dict(self) -> Dict:
        return asdict(self)


@dataclass
class NullCheckResult:
    """空值检查结果"""
    url: str
    check_time: str = field(default_factory=lambda: datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    total_rows: int = 0
    total_cols: int = 0
    total_cells: int = 0
    null_cells: List[NullCell] = field(default_factory=list)
    zero_cells: List[NullCell] = field(default_factory=list)
    headers: List[str] = field(default_factory=list)
    row_labels: List[str] = field(default_factory=list)
    include_zero: bool = False

    @property
    def null_count(self) -> int:
        return len(self.null_cells)

    @property
    def zero_count(self) -> int:
        return len(self.zero_cells)

    @property
    def null_rate(self) -> float:
        if self.total_cells == 0:
            return 0.0
        return self.null_count / self.total_cells * 100

    def summary(self) -> Dict:
        """汇总统计"""
        # 按列统计空值
        col_nulls = {}
        for cell in self.null_cells:
            col_nulls.setdefault(cell.col_label, []).append(cell)
        # 按行统计空值
        row_nulls = {}
        for cell in self.null_cells:
            row_nulls.setdefault(cell.row_label, []).append(cell)

        return {
            "check_time": self.check_time,
            "url": self.url,
            "total_rows": self.total_rows,
            "total_cols": self.total_cols,
            "total_cells": self.total_cells,
            "null_count": self.null_count,
            "null_rate": f"{self.null_rate:.2f}%",
            "zero_count": self.zero_count,
            "by_column": {k: len(v) for k, v in col_nulls.items()},
            "by_row": {k: len(v) for k, v in row_nulls.items()},
            "null_details": [c.to_dict() for c in self.null_cells],
            "zero_details": [c.to_dict() for c in self.zero_cells],
        }

    def to_json(self, path: str = None) -> str:
        data = self.summary()
        content = json.dumps(data, ensure_ascii=False, indent=2)
        if path:
            with open(path, "w", encoding="utf-8") as f:
                f.write(content)
        return content


class BiNullChecker:
    """BI报表空值检查器"""

    def __init__(self, include_zero: bool = False, use_proxy: bool = False):
        """
        Args:
            include_zero: 是否把0/0.00也视为空值
            use_proxy: 是否使用代理
        """
        self.include_zero = include_zero
        self.use_proxy = use_proxy

    # ---- 数据提取 ----
    def extract_grid_data(self, html: str) -> Tuple[List[str], List[List[str]]]:
        """从永洪BI HTML中提取表格数据

        永洪BI网格结构:
        - data-type=elem 包含多个组件(表格、图表、筛选器)
        - 主表格内部分左侧冻结列(630px) + 右侧滚动区(914px)
        - 单元格层级: container -> wrapper -> div[position:absolute] -> div[text]
        - 单元格位置由 position:absolute 的 top/left 决定

        Returns:
            (headers, rows) - headers为列标题列表, rows为二维数据列表
        """
        soup = BeautifulSoup(html, "html.parser")

        # 尝试永洪BI网格提取
        result = self._extract_yh_grid(soup)
        if result and result[1]:
            return result

        # 降级: 标准table标签
        result = self._extract_from_table(soup)
        if result and result[1]:
            return result

        # 降级: 通用绝对定位div
        return self._extract_positioned_divs(soup)

    def _find_main_grid(self, soup: BeautifulSoup):
        """找到永洪BI主数据表格组件(面积最大的data-type=elem)"""
        elems = soup.find_all(attrs={"data-type": "elem"})
        best, max_area = None, 0
        for e in elems:
            style = e.get("style", "") or ""
            w_m = re.search(r"width:\s*(\d+)", style)
            h_m = re.search(r"height:\s*(\d+)", style)
            if w_m and h_m:
                area = int(w_m.group(1)) * int(h_m.group(1))
                if area > max_area:
                    max_area = area
                    best = e
        return best

    def _get_cell_containers(self, grid_elem):
        """在主grid中找到单元格容器(按子div数量>10)"""
        containers = []
        for d in grid_elem.find_all("div"):
            children = d.find_all("div", recursive=False)
            if len(children) >= 10:
                style = d.get("style", "") or ""
                w_m = re.search(r"width:\s*(\d+)", style)
                h_m = re.search(r"height:\s*(\d+)", style)
                w = int(w_m.group(1)) if w_m else 0
                h = int(h_m.group(1)) if h_m else 0
                if h > 100:
                    containers.append({"elem": d, "w": w, "h": h, "count": len(children)})
        containers.sort(key=lambda x: x["w"])
        return containers

    def _extract_cells_from_container(self, container):
        """从容器中提取所有单元格及位置"""
        cells = []
        for wrapper in container.find_all("div", recursive=False):
            for d in wrapper.find_all("div"):
                s = d.get("style", "") or ""
                if "position: absolute" not in s and "position:absolute" not in s:
                    continue
                top_m = re.search(r"top:\s*(-?\d+)", s)
                left_m = re.search(r"left:\s*(-?\d+)", s)
                h_m = re.search(r"height:\s*(\d+)", s)
                w_m = re.search(r"width:\s*(\d+)", s)
                if not (top_m and left_m):
                    continue
                leaf = d.find("div")
                if leaf and not leaf.find("div"):
                    text = leaf.get_text(strip=True)
                else:
                    text = d.get_text(strip=True)
                cells.append({
                    "top": int(top_m.group(1)),
                    "left": int(left_m.group(1)),
                    "h": int(h_m.group(1)) if h_m else 30,
                    "w": int(w_m.group(1)) if w_m else 0,
                    "text": text,
                })
        return cells

    def _extract_yh_grid(self, soup: BeautifulSoup) -> Tuple[List[str], List[List[str]]]:
        """永洪BI网格提取"""
        grid = self._find_main_grid(soup)
        if not grid:
            return [], []

        containers = self._get_cell_containers(grid)
        if not containers:
            return [], []

        # 收集所有单元格
        all_cells = []
        for c in containers:
            all_cells.extend(self._extract_cells_from_container(c["elem"]))

        if not all_cells:
            return [], []

        # 找header: h>100的跨行cell就是列组header
        span_headers = [c for c in all_cells if c["h"] > 100]
        # 数据cell: h<=50 且 top > 0
        data_cells = [c for c in all_cells if c["h"] <= 50 and c["top"] > 0]

        # 如果top=0全是header混合, 从已知结构推断列名
        # 永洪BI常见列: 编号, 项目, 本期值, 差值, 环比值, 环比, 同比差值, 同比值, 同比
        known_headers = self._infer_headers(all_cells, span_headers)

        # 按top分组数据行
        from collections import defaultdict
        rows_dict = defaultdict(list)
        for c in data_cells:
            rows_dict[c["top"]].append(c)

        # 构建行数据(按left排序)
        rows = []
        for top in sorted(rows_dict.keys()):
            cells_in_row = sorted(rows_dict[top], key=lambda x: x["left"])
            row_values = [c["text"] for c in cells_in_row]
            rows.append(row_values)

        # 如果推断的header列数不匹配, 用通用列名
        if known_headers and rows:
            max_cols = max(len(r) for r in rows) if rows else 0
            while len(known_headers) < max_cols:
                known_headers.append(f"列{len(known_headers)+1}")

        return known_headers, rows

    def _infer_headers(self, all_cells, span_headers) -> List[str]:
        """从跨行header和top=0的cell推断列名"""
        # 常见永洪BI报表列名
        header_candidates = []
        for c in span_headers:
            if c["text"]:
                header_candidates.append(c["text"])

        # 从top=0且h=30的cell提取可能的列标题
        header_row = [c for c in all_cells if c["top"] == 0 and c["h"] == 30]

        # 找标题风格的cell (不包含数字/百分比的)
        title_pattern = re.compile(r"^[\u4e00-\u9fff\w\s\-()（）]+$")
        titles = []
        for c in sorted(header_row, key=lambda x: x["left"]):
            if title_pattern.match(c["text"]) and len(c["text"]) > 1:
                if c["text"] not in titles:
                    titles.append(c["text"])

        if titles:
            return titles

        # 降级: 用通用列名
        return header_candidates if header_candidates else ["编号", "项目", "本期值"]

    def _extract_from_table(self, soup: BeautifulSoup) -> Tuple[List[str], List[List[str]]]:
        """从标准table标签提取"""
        tables = soup.find_all("table")
        if not tables:
            return [], []
        table = max(tables, key=lambda t: len(t.find_all("tr")))
        rows = table.find_all("tr")
        if not rows:
            return [], []

        headers = [td.get_text(strip=True) for td in rows[0].find_all(["th", "td"])]
        data_rows = []
        for row in rows[1:]:
            cells = [td.get_text(strip=True) for td in row.find_all(["td", "th"])]
            if cells:
                data_rows.append(cells)
        return headers, data_rows

    def _extract_positioned_divs(self, soup: BeautifulSoup) -> Tuple[List[str], List[List[str]]]:
        """通用: 从所有绝对定位div提取"""
        divs = soup.find_all("div", style=re.compile(r"position\s*:\s*absolute"))
        groups = {}
        for div in divs:
            style = div.get("style", "")
            top_m = re.search(r"top:\s*(-?\d+)", style)
            left_m = re.search(r"left:\s*(-?\d+)", style)
            if not top_m:
                continue
            top = int(top_m.group(1))
            left = int(left_m.group(1)) if left_m else 0
            text = div.get_text(strip=True)
            if text and len(text) < 200:
                groups.setdefault(top, []).append((left, text))
        if not groups:
            return [], []
        sorted_tops = sorted(groups.keys())
        rows_raw = []
        for top in sorted_tops:
            items = sorted(groups[top], key=lambda x: x[0])
            row = [v for _, v in items]
            if row:
                rows_raw.append(row)
        headers = rows_raw[0] if rows_raw else []
        data_rows = rows_raw[1:] if len(rows_raw) > 1 else []
        return headers, data_rows

    # ---- 空值检测 ----
    def check_nulls(self, headers: List[str], rows: List[List[str]], url: str = "") -> NullCheckResult:
        """检测数据中的空值"""
        result = NullCheckResult(
            url=url,
            total_rows=len(rows),
            total_cols=len(headers),
            headers=headers,
            include_zero=self.include_zero,
        )

        # 收集行标签
        for row in rows:
            label = row[0] if row else ""
            result.row_labels.append(label)

        total_cells = 0
        for r_idx, row in enumerate(rows):
            row_label = row[0] if row else f"行{r_idx}"
            for c_idx in range(len(headers)):
                total_cells += 1
                val = row[c_idx].strip() if c_idx < len(row) else ""
                col_label = headers[c_idx] if c_idx < len(headers) else f"列{c_idx}"

                # 判断空值类型
                null_type = self._classify_null(val)
                if null_type and null_type != "zero":
                    result.null_cells.append(NullCell(
                        row_idx=r_idx, col_idx=c_idx,
                        row_label=row_label, col_label=col_label,
                        cell_value=val, null_type=null_type,
                    ))
                elif null_type == "zero":
                    result.zero_cells.append(NullCell(
                        row_idx=r_idx, col_idx=c_idx,
                        row_label=row_label, col_label=col_label,
                        cell_value=val, null_type="zero",
                    ))

                # 列缺失(行数据比表头短)
                if c_idx >= len(row):
                    result.null_cells.append(NullCell(
                        row_idx=r_idx, col_idx=c_idx,
                        row_label=row_label, col_label=col_label,
                        cell_value="<缺失>", null_type="missing",
                    ))

        result.total_cells = total_cells
        return result

    def _classify_null(self, val: str) -> Optional[str]:
        """判定单元格空值类型，返回None表示正常值"""
        if val == "" or val.isspace():
            return "empty"
        if val.lower() in ("null", "none", "undefined"):
            return "null_text"
        if val in ("-", "--"):
            return "dash"
        if val.upper() in ("N/A", "NA", "NAN"):
            return "na"
        if val in ZERO_PATTERNS:
            return "zero"
        return None

    # ---- Selenium抓取 + 检测 ----
    def check_page(self, url: str, cookies: Dict = None, wait_time: int = 90,
                   scroll: bool = True, max_scrolls: int = 50) -> NullCheckResult:
        """用Selenium打开页面，提取数据并检测空值

        提取策略优先级:
        1. JS注入提取网格数据(data-type=elem表格)
        2. HTML解析 + 滚动收集网格数据
        3. 文本报表模式: 提取页面全量文本 -> 解析指标 -> 检测空值
        """
        saved_env = {}
        if not self.use_proxy:
            for var in ["HTTP_PROXY", "HTTPS_PROXY", "http_proxy", "https_proxy"]:
                if var in os.environ:
                    saved_env[var] = os.environ.pop(var)

        try:
            from selenium import webdriver
            from selenium.webdriver.chrome.options import Options
            from selenium.webdriver.common.by import By
            from selenium.webdriver.common.keys import Keys
        except ImportError:
            raise RuntimeError("需要安装selenium: pip install selenium")

        opts = Options()
        opts.add_argument("--no-sandbox")
        opts.add_argument("--disable-dev-shm-usage")
        opts.add_argument("--ignore-certificate-errors")
        opts.add_argument("--disable-gpu")
        opts.add_argument("--window-size=1920,1080")

        driver = None
        try:
            driver = webdriver.Chrome(options=opts)
            driver.set_page_load_timeout(120)

            # 先访问域名种Cookie
            driver.get("https://hxdmc.wchscu.cn/")
            time.sleep(2)
            if cookies:
                for name, value in cookies.items():
                    try:
                        driver.add_cookie({"name": name, "value": value})
                    except Exception:
                        pass

            print(f"[NULL_CHECK] 访问报表: {url[:80]}...")
            driver.get(url)

            # 智能等待永洪BI渲染完成
            self._wait_for_report_ready(driver, max_wait=wait_time)

            src = driver.page_source
            debug_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "debug_page.html")
            with open(debug_path, "w", encoding="utf-8") as f:
                f.write(src)
            print(f"[NULL_CHECK] 页面已保存: {debug_path} ({len(src)}字符)")

            if "jwt过期" in src or "jwt异常" in src:
                print("[NULL_CHECK] JWT过期，请更新cookies")
                return NullCheckResult(url=url)

            # 策略1: JS注入提取网格
            js_data = self._extract_via_js(driver)
            if js_data and js_data.get("rows"):
                print(f"[NULL_CHECK] 网格提取: {len(js_data['headers'])}列, {len(js_data['rows'])}行")
                return self.check_nulls(js_data["headers"], js_data["rows"], url)

            # 策略2: HTML解析网格 + 滚动
            html = driver.page_source
            headers, rows = self.extract_grid_data(html)
            if rows:
                if scroll:
                    all_rows_dict = {"|".join(r[:2]) if len(r) >= 2 else "|".join(r): r for r in rows}
                    scroll_container = self._find_scroll_container(driver)
                    no_new = 0
                    for i in range(max_scrolls):
                        prev = len(all_rows_dict)
                        try:
                            if scroll_container:
                                driver.execute_script("arguments[0].scrollTop += 300;", scroll_container)
                            else:
                                driver.find_element(By.TAG_NAME, "body").send_keys(Keys.PAGE_DOWN)
                        except Exception:
                            driver.execute_script("window.scrollBy(0, 300);")
                        time.sleep(0.8)
                        hdrs, new_rows = self.extract_grid_data(driver.page_source)
                        for r in new_rows:
                            k = "|".join(r[:2]) if len(r) >= 2 else "|".join(r)
                            all_rows_dict[k] = r
                        added = len(all_rows_dict) - prev
                        if added > 0:
                            print(f"  滚动{i+1}: +{added}条, 累计{len(all_rows_dict)}条")
                            no_new = 0
                        else:
                            no_new += 1
                        if no_new >= 3:
                            break
                    rows = list(all_rows_dict.values())
                print(f"[NULL_CHECK] HTML网格: {len(headers)}列, {len(rows)}行")
                return self.check_nulls(headers, rows, url)

            # 策略3: 文本报表模式(非表格型BI报表)
            print("[NULL_CHECK] 网格未检测到，切换文本报表模式...")
            text_data = self._extract_text_report_via_js(driver)
            if text_data:
                return self._check_text_report(text_data, url, driver)

            print("[NULL_CHECK] 页面无可提取数据")
            return NullCheckResult(url=url)

        finally:
            if driver:
                driver.quit()
            for var, value in saved_env.items():
                os.environ[var] = value

    def _wait_for_report_ready(self, driver, max_wait: int = 90):
        """智能等待永洪BI报表渲染完成
        核心判断: 必须有实质内容(data-type=elem 或 body文本>200字符且稳定)
        """
        print("[NULL_CHECK] 等待报表加载...")
        start = time.time()
        last_text_len = 0
        stable_count = 0

        for i in range(max_wait // 3):
            time.sleep(3)
            elapsed = time.time() - start
            try:
                state = driver.execute_script("""
                    var r = {elem: 0, textLen: 0, loading: true};
                    var elems = document.querySelectorAll('[data-type="elem"]');
                    r.elem = elems.length;
                    var body = document.body;
                    if (body) r.textLen = (body.innerText || '').length;
                    var ld = document.getElementById('root-loading');
                    r.loading = ld ? (ld.style.display !== 'none' && ld.offsetHeight > 0) : false;
                    return r;
                """)
            except Exception:
                continue

            elem_cnt = state.get("elem", 0)
            text_len = state.get("textLen", 0)
            loading = state.get("loading", True)
            print(f"  [{elapsed:.0f}s] loading={loading}, elem={elem_cnt}, text={text_len}字符")

            # 条件1: 有BI组件渲染完成
            if elem_cnt > 0:
                print(f"[NULL_CHECK] 报表组件就绪 ({elem_cnt}个, {elapsed:.0f}s)")
                time.sleep(3)
                return

            # 条件2: loading消失且文本>200字符且内容稳定
            if not loading and text_len > 200:
                if text_len == last_text_len:
                    stable_count += 1
                else:
                    stable_count = 0
                    last_text_len = text_len
                if stable_count >= 2:
                    print(f"[NULL_CHECK] 内容稳定 ({text_len}字符, {elapsed:.0f}s)")
                    time.sleep(2)
                    return
            else:
                stable_count = 0
                last_text_len = text_len

            if elapsed > max_wait:
                break

        print(f"[NULL_CHECK] 等待超时({max_wait}s)，继续尝试提取")

    def _extract_text_report_via_js(self, driver) -> Optional[Dict]:
        """通过JS提取文本报表的全量结构化内容
        适用于运管指标每日推送等非表格型BI报表
        返回: {full_text, sections: [{title, items: [{text, has_value}]}]}
        """
        js_code = """
        var result = {full_text: '', sections: [], all_lines: []};
        var root = document.getElementById('root');
        if (!root) return JSON.stringify(result);

        // 获取页面全量渲染文本
        result.full_text = root.innerText || '';

        // 提取所有可见叶子文本节点(带位置信息)
        var walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, null, false);
        var nodes = [];
        while (walker.nextNode()) {
            var node = walker.currentNode;
            var text = node.textContent.trim();
            if (!text) continue;
            var parent = node.parentElement;
            if (!parent) continue;
            var rect = parent.getBoundingClientRect();
            if (rect.width === 0 && rect.height === 0) continue;
            nodes.push({
                text: text,
                top: Math.round(rect.top),
                left: Math.round(rect.left),
                tag: parent.tagName,
                fontSize: window.getComputedStyle(parent).fontSize,
                fontWeight: window.getComputedStyle(parent).fontWeight,
                color: window.getComputedStyle(parent).color
            });
        }

        // 按top分行(容差3px)
        var lineMap = {};
        nodes.forEach(function(n) {
            var key = Math.round(n.top / 3) * 3;
            if (!lineMap[key]) lineMap[key] = [];
            lineMap[key].push(n);
        });

        var tops = Object.keys(lineMap).map(Number).sort(function(a,b){return a-b;});
        tops.forEach(function(top) {
            var items = lineMap[top].sort(function(a,b){return a.left - b.left;});
            var lineText = items.map(function(i){return i.text;}).join(' ');
            result.all_lines.push({
                text: lineText,
                top: top,
                fontSize: items[0].fontSize,
                fontWeight: items[0].fontWeight
            });
        });

        return JSON.stringify(result);
        """
        try:
            raw = driver.execute_script(js_code)
            if raw:
                data = json.loads(raw)
                if data.get("full_text") and len(data["full_text"]) > 50:
                    print(f"[NULL_CHECK] 文本提取: {len(data['all_lines'])}行, {len(data['full_text'])}字符")
                    return data
        except Exception as e:
            print(f"[NULL_CHECK] 文本提取失败: {e}")
        return None

    def _check_text_report(self, text_data: Dict, url: str, driver=None) -> NullCheckResult:
        """检查文本报表中的空值/缺失指标

        解析逻辑:
        1. 从全文提取所有 "指标名:值" 或 "指标名XXX" 格式的指标
        2. 识别数值型指标(含数字/百分比的)和文本型指标
        3. 检查每行是否存在空值占位符
        4. 检测分段内容是否有缺失段落
        """
        full_text = text_data.get("full_text", "")
        all_lines = text_data.get("all_lines", [])

        # 把每行文本作为一行数据
        headers = ["行号", "内容", "指标类型"]
        rows = []
        null_cells = []
        zero_cells = []

        # 指标值提取模式
        val_pattern = re.compile(
            r'([\u4e00-\u9fff\w]+)'   # 指标名(中文+英文)
            r'[：:]\s*'                # 分隔符
            r'([\d.,%\-]*\s*)'         # 值(可能为空)
        )
        # 数值嵌入模式: "在院5375人" => 指标=在院, 值=5375, 单位=人
        num_inline = re.compile(
            r'([\u4e00-\u9fff]{2,}?)'   # 指标名
            r'(\d[\d,.]*%?)'             # 数值
            r'([\u4e00-\u9fff]*)'        # 单位
        )
        # 空值占位检测
        empty_pattern = re.compile(r'[：:]\s*[,，;；。\s]|[：:]\s*$')

        section_idx = 0
        for idx, line_info in enumerate(all_lines):
            line = line_info.get("text", "").strip()
            if not line or line in ("取消", "正在初始化中..."):
                continue

            # 识别段落标题 (如 "1.今日上午8点在院..." "3.昨日手术排程")
            is_section = bool(re.match(r'^\d+[.、．]', line))
            if is_section:
                section_idx += 1

            row = [str(idx + 1), line, f"段落{section_idx}"]
            rows.append(row)

            # 检查这一行是否有空值占位
            if empty_pattern.search(line):
                null_cells.append(NullCell(
                    row_idx=len(rows) - 1, col_idx=1,
                    row_label=f"段落{section_idx}", col_label="内容",
                    cell_value=line[:60], null_type="empty",
                ))

            # 检查 "指标:值" 格式中的空值
            for m in val_pattern.finditer(line):
                name, val = m.group(1), m.group(2).strip()
                if not val or val in ("-", "--", "null", "N/A"):
                    nt = self._classify_null(val) or "empty"
                    null_cells.append(NullCell(
                        row_idx=len(rows) - 1, col_idx=1,
                        row_label=f"段落{section_idx}", col_label=name,
                        cell_value=val or "(空)", null_type=nt,
                    ))

        # 尝试滚动获取完整页面内容(文本报表可能很长)
        if driver:
            extra = self._scroll_collect_text(driver)
            if extra:
                for line in extra:
                    if line.strip() and line not in [r[1] for r in rows]:
                        rows.append([str(len(rows) + 1), line.strip(), f"段落{section_idx}"])

        result = NullCheckResult(
            url=url,
            total_rows=len(rows),
            total_cols=len(headers),
            total_cells=len(rows) * len(headers),
            headers=headers,
            null_cells=null_cells,
            zero_cells=zero_cells,
            row_labels=[r[1][:30] for r in rows],
        )

        # 保存完整文本数据供分析
        text_out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "text_report_data.json")
        with open(text_out, "w", encoding="utf-8") as f:
            json.dump({
                "url": url,
                "check_time": result.check_time,
                "total_lines": len(rows),
                "sections": section_idx,
                "full_text": full_text,
                "lines": [{"idx": r[0], "text": r[1], "section": r[2]} for r in rows],
                "null_indicators": [c.to_dict() for c in null_cells],
            }, f, ensure_ascii=False, indent=2)
        print(f"[NULL_CHECK] 文本数据: {text_out}")

        return result

    def _scroll_collect_text(self, driver, max_scrolls: int = 20) -> List[str]:
        """滚动收集文本报表的完整内容"""
        from selenium.webdriver.common.by import By
        from selenium.webdriver.common.keys import Keys
        collected = set()
        try:
            for i in range(max_scrolls):
                text = driver.execute_script("return document.body.innerText || '';")
                lines = [l.strip() for l in text.split("\n") if l.strip()]
                before = len(collected)
                collected.update(lines)
                if len(collected) == before:
                    break
                try:
                    driver.find_element(By.TAG_NAME, "body").send_keys(Keys.PAGE_DOWN)
                except Exception:
                    driver.execute_script("window.scrollBy(0, 800);")
                time.sleep(1)
        except Exception as e:
            print(f"[NULL_CHECK] 滚动文本收集异常: {e}")
        return list(collected)

    def _extract_via_js(self, driver) -> Optional[Dict]:
        """通过JS注入从永洪BI网格提取数据(比HTML解析更准确)"""
        js_code = """
        var result = {headers: [], rows: []};
        // 找所有data-type=elem组件中面积最大的(主表格)
        var elems = document.querySelectorAll('[data-type="elem"]');
        var mainGrid = null, maxArea = 0;
        elems.forEach(function(e) {
            var w = e.offsetWidth || 0, h = e.offsetHeight || 0;
            if (w * h > maxArea) { maxArea = w * h; mainGrid = e; }
        });
        if (!mainGrid || maxArea < 50000) return JSON.stringify(result);

        // 提取所有叶子文本节点及其渲染坐标
        var cells = [];
        var gridRect = mainGrid.getBoundingClientRect();
        var allDivs = mainGrid.querySelectorAll('div');
        allDivs.forEach(function(d) {
            if (d.querySelector('div')) return; // 非叶子
            var text = d.textContent.trim();
            if (!text || text.length > 200) return;
            var rect = d.getBoundingClientRect();
            // 相对于grid的位置
            var relTop = Math.round(rect.top - gridRect.top);
            var relLeft = Math.round(rect.left - gridRect.left);
            cells.push({top: relTop, left: relLeft, w: Math.round(rect.width),
                        h: Math.round(rect.height), text: text});
        });

        // 按top分组(容差5px)
        var rowGroups = {};
        cells.forEach(function(c) {
            var rowKey = Math.round(c.top / 5) * 5;  // 5px容差
            if (!rowGroups[rowKey]) rowGroups[rowKey] = [];
            rowGroups[rowKey].push(c);
        });

        // 排序行
        var sortedTops = Object.keys(rowGroups).map(Number).sort(function(a,b){return a-b;});

        // 去重: 同行同left只保留一个
        sortedTops.forEach(function(top) {
            var seen = {};
            var unique = [];
            rowGroups[top].sort(function(a,b){return a.left - b.left;});
            rowGroups[top].forEach(function(c) {
                var key = Math.round(c.left / 3) * 3;
                if (!seen[key]) { seen[key] = true; unique.push(c); }
            });
            rowGroups[top] = unique;
        });

        // 第一行视为header(通常top最小的那行)
        if (sortedTops.length > 0) {
            var headerRow = rowGroups[sortedTops[0]];
            result.headers = headerRow.map(function(c){return c.text;});
        }
        // 数据行
        for (var i = 1; i < sortedTops.length; i++) {
            var row = rowGroups[sortedTops[i]];
            result.rows.push(row.map(function(c){return c.text;}));
        }
        return JSON.stringify(result);
        """
        try:
            raw = driver.execute_script(js_code)
            if raw:
                return json.loads(raw)
        except Exception as e:
            print(f"[NULL_CHECK] JS提取失败: {e}")
        return None

    def _find_scroll_container(self, driver):
        """查找滚动容器"""
        from selenium.webdriver.common.by import By
        try:
            containers = driver.find_elements(By.CSS_SELECTOR, '[style*="overflow"]')
            for c in containers:
                style = c.get_attribute("style") or ""
                if "scroll" in style or "auto" in style:
                    if c.size.get("height", 0) > 200:
                        return c
        except Exception:
            pass
        return None

    # ---- 从本地HTML检测 ----
    def check_html_file(self, html_path: str, url: str = "") -> NullCheckResult:
        """直接从本地HTML文件检测空值"""
        with open(html_path, "r", encoding="utf-8") as f:
            html = f.read()
        headers, rows = self.extract_grid_data(html)
        print(f"[NULL_CHECK] 从文件提取: {len(headers)}列, {len(rows)}行")
        return self.check_nulls(headers, rows, url or html_path)

    # ---- 从JSON数据检测 ----
    def check_json_data(self, json_path: str, url: str = "") -> NullCheckResult:
        """从bi_crawler输出的JSON数据检测空值"""
        with open(json_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        if not data:
            return NullCheckResult(url=url or json_path)

        # 推断列数
        max_data_len = max((len(item.get("数据", [])) for item in data), default=0)
        headers = ["医院", "科室"] + [f"指标{i+1}" for i in range(max_data_len)]
        rows = []
        for item in data:
            row = [item.get("医院", ""), item.get("科室", "")] + item.get("数据", [])
            rows.append(row)

        print(f"[NULL_CHECK] 从JSON加载: {len(headers)}列, {len(rows)}行")
        return self.check_nulls(headers, rows, url or json_path)


# ---- 报告生成 ----
def generate_report(result: NullCheckResult, output_dir: str = ".") -> str:
    """生成HTML格式的空值检查报告，返回报告文件路径"""
    summary = result.summary()
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_path = os.path.join(output_dir, f"null_check_report_{ts}.html")
    json_path = os.path.join(output_dir, f"null_check_report_{ts}.json")

    # 保存JSON
    result.to_json(json_path)

    # 按列统计
    col_stats = summary["by_column"]
    row_stats = summary["by_row"]

    # 构建HTML
    col_rows_html = ""
    for col, cnt in sorted(col_stats.items(), key=lambda x: -x[1]):
        col_rows_html += f"<tr><td>{col}</td><td class='num'>{cnt}</td></tr>\n"

    row_rows_html = ""
    for row, cnt in sorted(row_stats.items(), key=lambda x: -x[1])[:30]:
        row_rows_html += f"<tr><td>{row}</td><td class='num'>{cnt}</td></tr>\n"

    detail_rows_html = ""
    for cell in result.null_cells[:200]:
        badge = {
            "empty": "空白", "null_text": "null文本", "dash": "横线占位",
            "na": "N/A", "missing": "缺失",
        }.get(cell.null_type, cell.null_type)
        detail_rows_html += (
            f"<tr><td>{cell.row_idx+1}</td><td>{cell.row_label}</td>"
            f"<td>{cell.col_label}</td><td><code>{cell.cell_value or '(空)'}</code></td>"
            f"<td><span class='badge badge-{cell.null_type}'>{badge}</span></td></tr>\n"
        )

    zero_rows_html = ""
    for cell in result.zero_cells[:100]:
        zero_rows_html += (
            f"<tr><td>{cell.row_idx+1}</td><td>{cell.row_label}</td>"
            f"<td>{cell.col_label}</td><td><code>{cell.cell_value}</code></td></tr>\n"
        )

    # 严重等级
    if result.null_rate > 10:
        severity = "严重"
        severity_class = "critical"
    elif result.null_rate > 5:
        severity = "警告"
        severity_class = "warning"
    elif result.null_rate > 0:
        severity = "轻微"
        severity_class = "info"
    else:
        severity = "正常"
        severity_class = "ok"

    html = f"""<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<title>BI报表空值检查报告</title>
<style>
  body {{ font-family: 'Microsoft YaHei', sans-serif; margin: 20px; background: #f5f6fa; }}
  .container {{ max-width: 1100px; margin: 0 auto; }}
  h1 {{ color: #2c3e50; border-bottom: 3px solid #19af5d; padding-bottom: 10px; }}
  h2 {{ color: #34495e; margin-top: 30px; }}
  .summary-cards {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; margin: 20px 0; }}
  .card {{ background: #fff; border-radius: 8px; padding: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.08); text-align: center; }}
  .card .num {{ font-size: 32px; font-weight: bold; color: #2c3e50; }}
  .card .label {{ font-size: 14px; color: #7f8c8d; margin-top: 6px; }}
  .card.critical .num {{ color: #e74c3c; }}
  .card.warning .num {{ color: #f39c12; }}
  .card.info .num {{ color: #3498db; }}
  .card.ok .num {{ color: #27ae60; }}
  table {{ width: 100%; border-collapse: collapse; background: #fff; border-radius: 8px; overflow: hidden; box-shadow: 0 1px 4px rgba(0,0,0,0.06); margin-bottom: 20px; }}
  th {{ background: #19af5d; color: #fff; padding: 10px 14px; text-align: left; font-size: 14px; }}
  td {{ padding: 8px 14px; border-bottom: 1px solid #ecf0f1; font-size: 13px; }}
  tr:hover {{ background: #f8f9fa; }}
  .num {{ text-align: right; font-weight: 600; }}
  .badge {{ padding: 2px 8px; border-radius: 4px; font-size: 12px; color: #fff; }}
  .badge-empty {{ background: #e74c3c; }}
  .badge-null_text {{ background: #9b59b6; }}
  .badge-dash {{ background: #f39c12; }}
  .badge-na {{ background: #e67e22; }}
  .badge-missing {{ background: #c0392b; }}
  .meta {{ color: #95a5a6; font-size: 13px; margin-bottom: 20px; }}
  code {{ background: #f0f0f0; padding: 1px 5px; border-radius: 3px; }}
</style>
</head>
<body>
<div class="container">
  <h1>BI报表空值检查报告</h1>
  <div class="meta">
    检查时间: {result.check_time} &nbsp;|&nbsp;
    报表URL: <code>{result.url[:100]}...</code>
  </div>

  <div class="summary-cards">
    <div class="card">
      <div class="num">{result.total_rows}</div>
      <div class="label">数据行数</div>
    </div>
    <div class="card">
      <div class="num">{result.total_cols}</div>
      <div class="label">列数</div>
    </div>
    <div class="card">
      <div class="num">{result.total_cells}</div>
      <div class="label">总单元格</div>
    </div>
    <div class="card {severity_class}">
      <div class="num">{result.null_count}</div>
      <div class="label">空值数量</div>
    </div>
    <div class="card {severity_class}">
      <div class="num">{summary['null_rate']}</div>
      <div class="label">空值率 ({severity})</div>
    </div>
    <div class="card">
      <div class="num">{result.zero_count}</div>
      <div class="label">零值数量</div>
    </div>
  </div>

  <h2>按列统计空值</h2>
  <table>
    <tr><th>列名</th><th class="num">空值数</th></tr>
    {col_rows_html if col_rows_html else "<tr><td colspan='2'>无空值</td></tr>"}
  </table>

  <h2>按行统计空值 (Top 30)</h2>
  <table>
    <tr><th>行标识</th><th class="num">空值数</th></tr>
    {row_rows_html if row_rows_html else "<tr><td colspan='2'>无空值</td></tr>"}
  </table>

  <h2>空值明细 (前200条)</h2>
  <table>
    <tr><th>行号</th><th>行标识</th><th>列名</th><th>值</th><th>类型</th></tr>
    {detail_rows_html if detail_rows_html else "<tr><td colspan='5'>无空值</td></tr>"}
  </table>

  {"<h2>零值明细 (前100条)</h2><table><tr><th>行号</th><th>行标识</th><th>列名</th><th>值</th></tr>" + zero_rows_html + "</table>" if zero_rows_html else ""}
</div>
</body>
</html>"""

    with open(report_path, "w", encoding="utf-8") as f:
        f.write(html)

    print(f"[NULL_CHECK] HTML报告: {report_path}")
    print(f"[NULL_CHECK] JSON报告: {json_path}")
    return report_path


# ---- 便捷入口 ----
def load_cookies(cookie_path: str = "cookies.txt") -> Dict[str, str]:
    """从cookies.txt加载Cookie"""
    p = Path(cookie_path)
    if not p.exists():
        return {}
    text = p.read_text(encoding="utf-8").strip()
    cookies = {}
    for item in text.split(";"):
        item = item.strip()
        if "=" in item:
            name, value = item.split("=", 1)
            cookies[name.strip()] = value.strip()
    return cookies


def run_null_check(url: str = None, html_file: str = None, json_file: str = None,
                   include_zero: bool = False, scroll: bool = True,
                   output_dir: str = ".", cookie_path: str = "cookies.txt") -> Dict:
    """空值检查主入口

    三种模式（优先级: html_file > json_file > url）:
    1. html_file: 从本地HTML文件检测
    2. json_file: 从bi_crawler输出的JSON检测
    3. url: 用Selenium实时抓取检测

    Returns:
        检查结果摘要字典
    """
    checker = BiNullChecker(include_zero=include_zero)
    result = None

    if html_file:
        print(f"[NULL_CHECK] 模式: 本地HTML文件 -> {html_file}")
        result = checker.check_html_file(html_file, url or "")
    elif json_file:
        print(f"[NULL_CHECK] 模式: JSON数据文件 -> {json_file}")
        result = checker.check_json_data(json_file, url or "")
    elif url:
        print(f"[NULL_CHECK] 模式: Selenium实时抓取")
        cookies = load_cookies(cookie_path)
        if cookies:
            print(f"  加载{len(cookies)}个Cookie")
        result = checker.check_page(url, cookies=cookies, scroll=scroll)
    else:
        print("[NULL_CHECK] 错误: 需要提供url/html_file/json_file之一")
        return {"error": "no input"}

    report_path = generate_report(result, output_dir)

    summary = result.summary()
    # 打印摘要
    print("\n" + "=" * 60)
    print("  空值检查汇报")
    print("=" * 60)
    print(f"  数据规模: {result.total_rows}行 x {result.total_cols}列 = {result.total_cells}个单元格")
    print(f"  空值数量: {result.null_count} ({summary['null_rate']})")
    print(f"  零值数量: {result.zero_count}")
    if result.null_count > 0:
        print(f"\n  空值最多的列:")
        for col, cnt in sorted(summary["by_column"].items(), key=lambda x: -x[1])[:5]:
            print(f"    - {col}: {cnt}个空值")
    print(f"\n  报告: {report_path}")
    print("=" * 60)

    summary["report_path"] = report_path
    return summary


def main():
    """命令行入口"""
    import sys

    default_url = (
        "https://hxdmc.wchscu.cn/bi/sso?proc=1&action=viewer&hback=true"
        "&db=!28!01!29!!534e!!897f!!62a5!!8868!!95e8!!6237!!2f!!8fd0!!8425"
        "!!7ba1!!7406!!90e8!!2f!!8fd0!!7ba1!!53ef!!89c6!!5316!!5206!!6790!"
        "-!52ff!!52a8!!2f!!6bcf!!65e5!!63a8!!9001!!2f!!8fd0!!7ba1!!6307"
        "!!6807!!6bcf!!65e5!!63a8!!9001!!28!!4e0a!!5348!!29!.db"
    )

    args = sys.argv[1:]
    mode = "html"  # 默认用本地html
    target = None
    include_zero = "--zero" in args

    if "--url" in args:
        mode = "url"
        idx = args.index("--url")
        target = args[idx + 1] if idx + 1 < len(args) else default_url
    elif "--html" in args:
        mode = "html"
        idx = args.index("--html")
        target = args[idx + 1] if idx + 1 < len(args) else "bi_report.html"
    elif "--json" in args:
        mode = "json"
        idx = args.index("--json")
        target = args[idx + 1] if idx + 1 < len(args) else "bi_report_data.json"
    else:
        # 自动检测可用文件
        if Path("bi_report.html").exists():
            mode, target = "html", "bi_report.html"
        elif Path("bi_report_data.json").exists():
            mode, target = "json", "bi_report_data.json"
        else:
            mode, target = "url", default_url

    kwargs = {"include_zero": include_zero, "output_dir": "."}
    if mode == "html":
        kwargs["html_file"] = target
    elif mode == "json":
        kwargs["json_file"] = target
    else:
        kwargs["url"] = target

    run_null_check(**kwargs)


if __name__ == "__main__":
    main()
