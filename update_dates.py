import re

# 读取文件
with open('输血/运管输血报表sql-报表-lis部分11日期挪一个月.sql', 'r', encoding='utf-8') as file:
    content = file.read()

# 执行替换
# 将 date_add('month', -1, current_date) 替换为 current_date
content = re.sub(r"date_add\('month', -1, current_date\)", "current_date", content)

# 将 date_add('month', -2, current_date) 替换为 date_add('month', -1, current_date)
content = re.sub(r"date_add\('month', -2, current_date\)", "date_add('month', -1, current_date)", content)

# 将 date_add('month', -13, current_date) 替换为 date_add('month', -12, current_date)
content = re.sub(r"date_add\('month', -13, current_date\)", "date_add('month', -12, current_date)", content)

# 修改日期范围计算
# 将 date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', current_date)), '%Y-%m-%d')
# 替换为 
# date_format(date_trunc('month', current_date), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', 1, current_date))), '%Y-%m-%d')
content = re.sub(
    r"date_format\(date_trunc\('month', date_add\('month', -1, current_date\)\), '%Y-%m-%d'\) AND date_format\(date_add\('day', -1, date_trunc\('month', current_date\)\), '%Y-%m-%d'\)",
    "date_format(date_trunc('month', current_date), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', 1, current_date))), '%Y-%m-%d')",
    content
)

# 将 date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d')
# 替换为
# date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', current_date)), '%Y-%m-%d')
content = re.sub(
    r"date_format\(date_trunc\('month', date_add\('month', -2, current_date\)\), '%Y-%m-%d'\) AND date_format\(date_add\('day', -1, date_trunc\('month', date_add\('month', -1, current_date\)\)\), '%Y-%m-%d'\)",
    "date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', current_date)), '%Y-%m-%d')",
    content
)

# 将 date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d')
# 替换为
# date_format(date_trunc('month', date_add('month', -12, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -11, current_date))), '%Y-%m-%d')
content = re.sub(
    r"date_format\(date_trunc\('month', date_add\('month', -13, current_date\)\), '%Y-%m-%d'\) AND date_format\(date_add\('day', -1, date_trunc\('month', date_add\('month', -12, current_date\)\)\), '%Y-%m-%d'\)",
    "date_format(date_trunc('month', date_add('month', -12, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -11, current_date))), '%Y-%m-%d')",
    content
)

# 写入新文件
with open('输血/运管输血报表sql-报表-lis部分11日期挪一个月_更新.sql', 'w', encoding='utf-8') as file:
    file.write(content)

print("日期更新完成！") 