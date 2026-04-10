# coding=utf-8
from pyspark.sql.session import SparkSession
from pyspark.context import SparkContext
import pyspark.sql.functions as F
import pyspark.sql.types as T
import os
import datetime
import warnings
import dict_yg
warnings.filterwarnings('ignore')

os.environ['HADOOP_USER_NAME'] = "hxhdp"
os.environ['SPARK_HOME'] = "/home/hxhdp/bi/spark2/spark2-lz"
os.environ['PYSPARK_PYTHON'] = "/home/hxhdp/bi/anaconda3/bin/python3"
APP_NAME = "mdr_beinhosp"

DB_NAME_SINK = "m1"
TB_NAME_SINK = "mdr_beinhosp"
SINK_VERSION = "mdr_beinhosp_modify_ops"
BASE_PATH = "/bi/data/mdr/" + SINK_VERSION


spark = SparkSession.builder \
    .master('yarn') \
    .config("spark.yarn.queue", "default") \
    .config("spark.executor.instances", "10") \
    .config("spark.executor.memory", "10g") \
    .config("spark.executor.memoryOverhead", "5g") \
    .config("spark.executor.cores", "4") \
    .config("spark.driver.memory", "4g") \
    .config("spark.driver.memoryOverhead", "1g") \
    .config("spark.port.maxRetries", "100") \
    .enableHiveSupport() \
    .appName(APP_NAME) \
    .getOrCreate()
sc = SparkContext.getOrCreate()


def ptime(pstr):
    print(pstr, datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))


# 通过md转码
def getMD(df, newcol, dfmedorg , dfcol ,tbname,key, dictcol):
    df_mdrdict = spark.table(tbname).select([dictcol, 'medorgcode', key])
    dict_mdrdict = df_mdrdict.toPandas().set_index(['medorgcode', key]).to_dict()
    dict_mdrdict = dict_mdrdict[dictcol]
    dict_mdrdict = sc.broadcast(dict_mdrdict)
    udf1 = F.udf(lambda x, y: dict_mdrdict.value[x, y] if (x, y) in dict_mdrdict.value.keys() else None, T.StringType())
    return df.withColumn(newcol, udf1(dfmedorg, dfcol))


# 写hudi  暂不使用
def df2hudi(df, mode, database, tableName, rowkey, partitionpath, ts, writeopera, basePath):
    partition = partitionpath
    hudi_options = {
        'hoodie.write.markers.type': 'direct',
        'hoodie.metadata.enable': 'false',
        'hoodie.embed.timeline.server': 'false',
        'hoodie.table.name': tableName,
        'hoodie.datasource.write.recordkey.field': rowkey,
        'hoodie.datasource.write.partitionpath.field': partitionpath,
        'hoodie.datasource.write.table.name': tableName,
        'hoodie.datasource.write.operation': writeopera,
        'hoodie.datasource.write.precombine.field': ts,
        'hoodie.upsert.shuffle.parallelism': 20,
        'hoodie.insert.shuffle.parallelism': 20,
        # 'hoodie.insert.sort.mode': 'NONE',  # 20250731 未启用 可能增加内存消耗，小文件
        # 'hoodie.index.type': 'NONE',  # 20250731 添加 禁用索引 未启用 要报错
        # 'hoodie.index.type': "GLOBAL_BLOOM",    # 全局索引配置
        # 'hoodie.index.global.bloom.filter.enable': "true",  # 全局索引配置
        'hoodie.bulkinsert.shuffle.parallelism': 20,
        'hoodie.datasource.hive_sync.database': database,
        'hoodie.datasource.hive_sync.table': tableName,
        'hoodie.datasource.hive_sync.enable': 'true',
        'hoodie.datasource.hive_sync.partition_fields': partition,
        'hoodie.datasource.hive_sync.jdbcurl': 'jdbc:hive2://10.239.80.4:10000/default;principal=hive/hdpnode2.hde.com@HXHADOOP.COM',
        'hoodie.datasource.hive_sync.partition_extractor_class': 'org.apache.hudi.hive.MultiPartKeysValueExtractor'
    }
    df.write.format("hudi"). \
        options(**hudi_options). \
        mode(mode). \
        save(basePath)

if __name__ == '__main__':
    ptime("stt")

    sql_rdd = sc.textFile("/bi/doc/mdr_beinhosp_mul_source.sql")
    sql = "\n".join(sql_rdd.collect())
    df_save = spark.sql(sql)
    # --py-files /home/hxhdp/bi/py_schedule/t5_beinhosp/dict_yg.py
    # /home/hxhdp/bi/py_schedule/public/dict_yg.py
    ygks = dict_yg.Test(spark)

    df_save = ygks.getomtypedate('medorgcode','ward', 'doc+loc', '','beinhospdate', df_save,
                                    ygks.ygzshospdic,ygks.ygwardhospdic,ygks.yglochospdic,ygks.yglocdic,ygks.ygdocdic,
                                    'currentstaffgroupcode', 'currentmedelementcode', 'currentmedelementname','currentmedelementname',
                                    'currentwardcode', 'omdeptcode', 'omdeptdesc', 'omdeptid','threecode','threename','omthreecode','omthreename'
                                    ,ygks.zscode,ygks.hcode)

    ptime("创建视图以写入")
    df_save.createOrReplaceTempView('temp_mdr_beinhosp')
    # hdfs dfs -put -f /home/hxhdp/bi/ws/mdr/4_beinhosp_mul/new_add_yg/mdr_beinhosp_mul_sink.sql /bi/doc/
    # hdfs dfs -cat /bi/doc/mdr_beinhosp_mul_sink.sql
    sql_rdd = sc.textFile("/bi/doc/mdr_beinhosp_mul_sink.sql")
    sql = "\n".join(sql_rdd.collect())
    df_save = spark.sql(sql)

    for i in range(0, len(df_save.schema.fields)):
        df_save.schema.fields[i].nullable = True
    #
    # df2hudi(df_save, mode="append", database='m1', tableName="mdr_beinhosp", rowkey='uuid',
    #         partitionpath='repdate,rephour', ts='datacreatedttm', writeopera="insert_overwrite")
    writeOperation = "insert_overwrite"
    # print(df_save.count())
    # print(DB_NAME_SINK)
    # print(writeOperation)
    # print(BASE_PATH)
    df2hudi(df_save, mode='append', database=DB_NAME_SINK, tableName=TB_NAME_SINK, rowkey='uuid',
            partitionpath='repdate,rephour', ts='datacreatedttm', writeopera=writeOperation, basePath=BASE_PATH)
    ptime("end")
