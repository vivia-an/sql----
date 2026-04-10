#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys
import json
import base64
import logging
import os
import time
import configparser
from datetime import datetime, timedelta, date
import requests
from typing import List, Dict, Optional, Set


# 配置日志系统
logger = None  # 全局日志记录器

def setup_logging(config):
    log_date = datetime.now().strftime("%Y%m%d")
    log_filename = f"kylin_monitor_{log_date}.log"
    
    # 获取日志级别
    log_level = config.get('monitor', 'log_level', fallback='INFO').upper()
    level = getattr(logging, log_level, logging.INFO)
    
    logger = logging.getLogger("KylinJobMonitor")
    logger.setLevel(level)

    # 文件处理器
    file_handler = logging.FileHandler(log_filename)
    file_formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    file_handler.setFormatter(file_formatter)

    # 控制台处理器
    console_handler = logging.StreamHandler()
    console_formatter = logging.Formatter('%(levelname)s - %(message)s')
    console_handler.setFormatter(console_formatter)

    logger.addHandler(file_handler)
    logger.addHandler(console_handler)
    return logger

class KylinJobMonitor:
    def __init__(self, host: str, port: int, username: str, password: str, config: Dict):
        self.host = host
        self.port = port
        self.auth = base64.b64encode(f"{username}:{password}".encode()).decode()
        self.headers = {
            'Accept': 'application/vnd.apache.kylin-v4-public+json',
            'Content-Type': 'application/json;charset=utf-8',
            'Authorization': f'Basic {self.auth}'
        }
        # 监控配置
        self.max_task_duration_hours = config.getint('monitor', 'max_task_duration_hours', fallback=1)
        self.max_pending_jobs = config.getint('monitor', 'max_pending_jobs', fallback=5)
        # 状态跟踪
        self.daily_checked_models = set()  # 当天已检查的模型
        logger.info("初始化Kylin作业监控器")

    def _api_request(self, method: str, endpoint: str, params: Optional[Dict] = None, data: Optional[Dict] = None) -> Dict:
        """执行API请求"""
        url = f"http://{self.host}:{self.port}{endpoint}"
        try:
            start_time = time.time()
            response = requests.request(
                method=method,
                url=url,
                headers=self.headers,
                params=params,
                json=data
            )
            latency = int((time.time() - start_time) * 1000)
            logger.info(f"API {method} {url} - {response.status_code} ({latency}ms)")
            response.raise_for_status()
            return response.json()
        except requests.exceptions.HTTPError as e:
            logger.error(f"API请求失败: {e.response.status_code} - {e.response.text}")
            return {}
        except Exception as e:
            logger.exception(f"API请求异常: {str(e)}")
            return {}

    def get_all_models(self, project: str) -> List[Dict]:
        """获取项目下所有模型，过滤掉状态为offline的模型"""
        endpoint = f"/kylin/api/models"
        params = {'project': project, 'page_size': 100}
        response = self._api_request('GET', endpoint, params=params)
        models = response.get('data', {}).get('value', [])
        
        # 过滤掉状态为"offline"的模型
        filtered_models = [model for model in models if model.get('status', '').lower() != 'offline']
        
        logger.debug(f"总共获取到 {len(models)} 个模型，过滤后剩余 {len(filtered_models)} 个模型（已排除 {len(models) - len(filtered_models)} 个offline状态的模型）")
        return filtered_models

    def get_model_jobs_by_date(self, model_name: str, project: str, date: str) -> List[Dict]:
        """获取指定模型在指定日期的作业"""
        # 转换日期为时间戳范围 (当天00:00:00到23:59:59)
        start_date = datetime.strptime(date, '%Y%m%d')
        end_date = start_date + timedelta(days=1) - timedelta(seconds=1)

        start_ts = int(start_date.timestamp() * 1000)
        end_ts = int(end_date.timestamp() * 1000)

        endpoint = f"/kylin/api/jobs"
        params = {
            'project': project,
            'key': model_name,
            'start_time': start_ts,
            'end_time': end_ts
        }
        response = self._api_request('GET', endpoint, params=params)
        return response.get('data', {}).get('value', [])

    def analyze_job_status(self, jobs: List[Dict]) -> Dict:
        """分析作业状态，增加失败、长时间运行和排队任务检测"""
        if not jobs:
            return {'status': 'NO_JOBS', 'count': 0, 'success': 0, 'failed': 0, 'running': 0, 'long_running': [], 'pending': 0}

        status_count = {
            'FINISHED': 0,
            'ERROR': 0,
            'RUNNING': 0,
            'PENDING': 0,
            'DISCARDED': 0
        }
        failed_jobs = []
        long_running_jobs = []
        current_time = time.time() * 1000  # 当前时间戳(毫秒)

        for job in jobs:
            job_id = job.get('id', 'N/A')
            status = job.get('job_status', 'UNKNOWN')
            job_name = job.get('name', 'N/A')
            submit_time = job.get('create_time', 0)
            duration_minutes = 0

            # 计算任务持续时间
            if submit_time > 0 and status in ['RUNNING', 'PENDING']: 
                duration_ms = current_time - submit_time
                duration_minutes = duration_ms / (1000 * 60)

            # 失败任务检测
            if status == 'ERROR':
                failed_jobs.append(f"任务 {job_name} (ID: {job_id}) 失败")
                status_count[status] += 1

            # 长时间运行任务检测 (>1小时)
            elif status == 'RUNNING' and duration_minutes > self.max_task_duration_hours * 60:
                long_running_jobs.append(f"任务 {job_name} (ID: {job_id}) 运行时间过长: {int(duration_minutes)}分钟")
                status_count[status] += 1

            elif status in status_count:
                status_count[status] += 1
            else:
                status_count['UNKNOWN'] = status_count.get('UNKNOWN', 0) + 1

        # 排队任务检测
        pending_count = status_count['PENDING']
        if pending_count > self.max_pending_jobs:
            logger.warning(f"Pending任务数量过多: {pending_count}个，超过阈值{self.max_pending_jobs}")

        # 失败任务告警
        if failed_jobs:
            logger.warning(f"发现{len(failed_jobs)}个失败任务:\n{chr(10).join(failed_jobs)}")

        # 长时间运行任务告警
        if long_running_jobs:
            logger.warning(f"发现{len(long_running_jobs)}个长时间运行任务:\n{chr(10).join(long_running_jobs)}")

        # 确定整体状态
        if status_count['ERROR'] > 0:
            overall_status = 'FAILED'
        elif status_count['RUNNING'] > 0 or status_count['PENDING'] > 0:
            overall_status = 'RUNNING'
        elif status_count['FINISHED'] > 0:
            overall_status = 'SUCCESS'
        else:
            overall_status = 'UNKNOWN'

        return {
            'status': overall_status,
            'count': len(jobs),
            'success': status_count['FINISHED'],
            'failed': status_count['ERROR'],
            'running': status_count['RUNNING'],
            'pending': status_count['PENDING'],
            'discarded': status_count['DISCARDED'],
            'unknown': status_count.get('UNKNOWN', 0),
            'failed_jobs': failed_jobs,
            'long_running_jobs': long_running_jobs
        }

    def monitor_daily_builds(self, project: str, date: Optional[str] = None) -> List[Dict]:
        """监控指定日期的所有模型构建情况，增加无任务模型检测"""
        if not date:
            date = datetime.now().strftime('%Y%m%d')
            today = date
        else:
            today = date

        logger.info(f"开始监控项目 {project} 在 {today} 的模型构建情况")
        models = self.get_all_models(project)
        results = []
        all_model_names = {model.get('name', 'N/A') for model in models if model.get('name', 'N/A') != 'N/A'}

        for model in models:
            model_name = model.get('name', 'N/A')
            if model_name == 'N/A':
                continue
            self.daily_checked_models.add(model_name)
            logger.info(f"检查模型: {model_name}")

            jobs = self.get_model_jobs_by_date(model_name, project, today)
            analysis = self.analyze_job_status(jobs)

            result = {
                'model': model_name,
                'project': project,
                'date': today,
                'analysis': analysis,
                'jobs': jobs[:5]  # 只保留前5个作业的详细信息
            }
            results.append(result)

            # 记录监控结果
            logger.info(
                f"模型 {model_name} 构建状态: {analysis['status']} - "
                f"总作业: {analysis['count']}, 成功: {analysis['success']}, "
                f"失败: {analysis['failed']}, 运行中: {analysis['running']}, "
                f"排队中: {analysis['pending']}"
            )

        # 检测一整天都没有构建任务的模型（每天20:00后检查）
        current_hour = datetime.now().hour
        if current_hour >= 20:
            no_job_models = all_model_names - self.daily_checked_models
            if no_job_models:
                no_job_count = len(no_job_models)
                model_list = ', '.join(no_job_models)
                alert_msg = f"发现 {no_job_count} 个模型在 {today} 没有构建任务: {model_list}"
                logger.warning(alert_msg)

        return results

def load_config(config_path: str = 'config.ini') -> configparser.ConfigParser:
    """加载INI配置文件"""
    config = configparser.ConfigParser()
    try:
        if not config.read(config_path):
            logger.error(f"配置文件 {config_path} 未找到或无法读取")
            sys.exit(1)
        return config
    except Exception as e:
        logger.exception(f"加载配置文件失败: {str(e)}")
        sys.exit(1)

def main():
    # 加载配置文件
    config = load_config()
    
    # 配置日志系统
    global logger
    logger = setup_logging(config)

    # 初始化监控器
    monitor = KylinJobMonitor(
        host=config.get('kylin', 'host', fallback='10.239.80.100'),
        port=config.getint('kylin', 'port', fallback=7070),
        username=config.get('kylin', 'username', fallback='admin'),
        password=config.get('kylin', 'password', fallback='kylin@2023'),
        config=config
    )
    target_project = config.get('kylin', 'target_project', fallback='your_project')
    
    # 直接执行一次监控
    monitor.monitor_daily_builds(target_project)

if __name__ == '__main__':
    main()
