#!/bin/bash

# 配置
KYLIN_HOST="10.239.80.100"
KYLIN_PORT="7070"
PROJECT="${1:-M1}"
MODEL_NAME="${2}"
AUTH="YWRtaW46a3lsaW5AMjAyMw=="

if [ -z "$MODEL_NAME" ]; then
    echo "用法: $0 <项目名> <模型名>"
    echo "示例: $0 M1 ZEN_MODEL_MDR_INCOME"
    exit 1
fi

# 计算时间戳（兼容 Python 2.x）
START_TIME=$(python -c "import time; from datetime import datetime; d=datetime.now().replace(hour=0,minute=0,second=0,microsecond=0); import calendar; print(int(calendar.timegm(d.timetuple())*1000))")
END_TIME=$(python -c "import time; from datetime import datetime; d=datetime.now().replace(hour=23,minute=59,second=59); import calendar; print(int(calendar.timegm(d.timetuple())*1000+999))")
CURRENT_TIME=$(python -c "import time; print(int(time.time()*1000))")

echo "========================================="
echo "查询模型: $MODEL_NAME (项目: $PROJECT)"
echo "日期: $(date +%Y-%m-%d)"
echo "========================================="

# 查询 API
RESPONSE=$(curl -s -X GET "http://${KYLIN_HOST}:${KYLIN_PORT}/kylin/api/jobs?project=${PROJECT}&model=${MODEL_NAME}&time_filter=4&start_time=${START_TIME}&end_time=${END_TIME}" \
  -H "Accept: application/vnd.apache.kylin-v4-public+json" \
  -H "Authorization: Basic ${AUTH}")

# 检查错误
if echo "$RESPONSE" | grep -q '"code":"999"'; then
    echo "✗ API 调用失败"
    echo "$RESPONSE"
    exit 1
fi

# 格式化输出
printf "%-15s %-40s %-10s %-20s %-12s %-8s\n" "JOB_ID" "JOB_NAME" "STATUS" "CREATE_TIME" "DURATION(分)" "超时?"
printf "%-15s %-40s %-10s %-20s %-12s %-8s\n" "------" "--------" "------" "-----------" "------------" "------"

echo "$RESPONSE" | python -c "
import sys, json
try:
    data = json.load(sys.stdin)
    jobs = data.get('data', {}).get('value', [])
    current_time = $CURRENT_TIME
    
    for job in jobs:
        job_id = job.get('id', 'N/A')[:15]
        job_name = job.get('name', 'N/A')[:40]
        status = job.get('job_status', 'UNKNOWN')[:10]
        create_time = job.get('create_time', 0)
        
        # 格式化时间
        if create_time > 0:
            import time
            time_str = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(create_time/1000))
            duration_min = int((current_time - create_time) / 60000)
        else:
            time_str = 'N/A'
            duration_min = 0
        
        # 检测超时
        is_timeout = 'YES' if (status == 'RUNNING' and duration_min > 60) else 'NO'
        
        print('%-15s %-40s %-10s %-20s %-12d %-8s' % (
            job_id, job_name, status, time_str, duration_min, is_timeout
        ))
    
    print('')
    print('总计: %d 个 Jobs' % len(jobs))
except Exception as e:
    print('解析错误: %s' % str(e))
    sys.exit(1)
"