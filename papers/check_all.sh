#!/usr/bin/env bash
# 一条命令跑完两轨的全部校验，每份稿子一行结论。
#
# 为什么需要它：六个校验器散在两个目录、各有各的调用方式，循环停下之后
# 接手的人记不住。这个脚本不新增任何断言 —— 它只是让已有的断言可用。
#
#   ./check_all.sh            只跑校验（假定 PDF 是最新的）
#   ./check_all.sh --build    先重新编译四份稿子，再校验
#
# 退出码 0 表示全部通过。校验器会各自打印它读的是哪一份 PDF、多久之前构建 ——
# 那一行要看，本项目里出现过三次"校验器审错了对象"。
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
A="$HERE/hospital_nl2sql_en"
B="$HERE/dataBase"
OUT="${TMPDIR:-/tmp}/paper-checks.$$"
mkdir -p "$OUT"
BUILD=0; [ "${1:-}" = "--build" ] && BUILD=1
fail=0

run() {  # run <标签> <目录> <命令...>
  local label="$1" dir="$2"; shift 2
  local log="$OUT/$(echo "$label" | tr -c 'A-Za-z0-9' '_').log"
  if ( cd "$dir" && "$@" ) >"$log" 2>&1; then
    printf '  \033[32mPASS\033[0m  %-34s %s\n' "$label" "$(tail -3 "$log" | grep -E 'checks|检查|PASS|passed' | tail -1)"
  else
    printf '  \033[31mFAIL\033[0m  %-34s %s\n' "$label" "见 $log"
    grep -E 'FAIL|failed [1-9]|失败' "$log" | head -4 | sed 's/^/          /'
    fail=1
  fi
}

if [ "$BUILD" = "1" ]; then
  echo "== 重新编译 =="
  ( cd "$A" && ./build_local.sh "$OUT/a" >/dev/null 2>&1 ) \
    && echo "  ok  main_applsci_mdpicls" || { echo "  FAIL  main_applsci_mdpicls"; fail=1; }
  for spec in "$A|main_cn|xelatex" "$B|main_jmir|pdflatex" "$B|main_cn|xelatex" "$B|main_fk|pdflatex"; do
    d="${spec%%|*}"; rest="${spec#*|}"; job="${rest%%|*}"; eng="${rest##*|}"
    w="$OUT/$(basename "$d")-$job"; mkdir -p "$w"
    command cp "$d/$job.tex" "$w/" 2>/dev/null
    [ -f "$d/data_fk.tex" ] && command cp "$d/data_fk.tex" "$w/"
    ( cd "$w" && for i in 1 2; do "$eng" -interaction=nonstopmode "$job.tex" >/dev/null 2>&1; done )
    if [ -f "$w/$job.pdf" ]; then
      e=$(grep -c '^! ' "$w/$job.log"); o=$(grep -c 'Overfull .hbox' "$w/$job.log")
      p=$(pdfinfo "$w/$job.pdf" 2>/dev/null | awk '/^Pages/{print $2}')
      printf '  %s  %-28s %s 页 errors=%s overfull=%s\n' \
        "$([ "$e" = 0 ] && echo ok || echo FAIL)" "$(basename "$d")/$job" "$p" "$e" "$o"
      [ "$e" = 0 ] || fail=1
    else
      echo "  FAIL  $(basename "$d")/$job 未产出 PDF"; fail=1
    fi
  done
  echo
fi

echo "== A 轨 Applied Sciences =="
run "verify_numbers（数值对填写表）"   "$A" python3 verify_numbers.py
run "verify_structure（结构+编辑台）"  "$A" python3 verify_structure.py
run "verify_cn（中文对照稿）"          "$A" python3 verify_cn.py

echo
echo "== B 轨 JMIR =="
run "verify_jmir（结构+文献）"         "$B" python3 verify_jmir.py
run "verify_cn（中文对照稿）"          "$B" python3 verify_cn.py
run "check_fk（算术+几何, JAMIA 稿）"  "$B" python3 check_fk.py

echo
echo "== 仍需作者输入（校验器查不了的） =="
pa=$(grep -o '\\PH{' "$A/main_applsci_mdpicls.tex" | wc -l)
pb=$(grep -o '\\PH{' "$B/main_jmir.tex" | wc -l)
prov=$(grep -c '^\\provisionaltrue' "$B/data_fk.tex" 2>/dev/null || echo 0)
echo "  A 轨占位符 \\PH{} 未填：$pa 处"
echo "  B 轨占位符 \\PH{} 未填：$pb 处"
if [ "$prov" != "0" ]; then
  echo "  B 轨 data_fk.tex 仍是 provisional —— 82 个数值宏全部印红，未实测前不可投"
fi
echo "  其余见 LOOP_STATE.md 末节：venue 二选一、11 条会议文献查证、"
echo "  STARE-HI 两条待答、TO_VERIFY.md 三组实测"

echo
[ "$fail" = 0 ] && echo "全部校验通过。" || echo "有校验未通过，见上。"
exit "$fail"
