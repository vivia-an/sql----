select
cast(uuid() as string) as uuid,--UUID
cast(null as string) as medorgid,--医疗机构ID
cast(visit_record_medorgcode  as string) as medorgcode,--医疗机构代码
cast(visit_record_medorgname  as string) as medorgname,--医疗机构名称
cast(null as string) as empiid,--人员唯一标识ID
cast(null as string) as empino,--人员唯一标识号
cast(visit_record_persid  as string) as persid,--人员ID
cast(visit_record_persno  as string) as persno,--人员号
cast(visit_record_extstr3  as string) as visitid,--就诊ID
cast(visit_record_visitno  as string) as visitno,--就诊号
cast(null as string) as serialno,--流水号
cast(visit_record_persname  as string) as persname,--人员姓名
cast(now()  as date) as beinhospdate,--在院日期
cast(date_format(now() ,'yyyy-MM-dd') as string) as repdate,--日期
cast(date_format(now() ,'HH:mm:ss') as string ) as reptime,--
cast(date_format(now() ,'yyyy-MM-dd HH:mm:ss') as string) as repdttm,--
cast(date_format(now() ,'HH') as string) as rephour,--快照时刻
cast('1' as string ) as newest,
cast(visit_record_visitbedid  as string) as bednoid,--床号ID
cast(visit_record_visitbedcode  as string) as bedno,--床号
cast(visit_record_visitdttm  as string) as inhospdate,--入院日期 --visit_record_triagedttm
cast(null as string) as inhospwardid,--入院护理单元编码
cast(null as string) as inhospwardcode,--入院护理单元编码
cast(null as string) as inhospwardname,--入院护理单元名称
cast(null as string) as inhospmedelementid,--入院医疗单元ID
cast(null as string) as inhospmedelementcode,--入院医疗单元编码
cast(null as string) as inhospmedelementname,--入院医疗单元名称
cast(visit_record_visitwardid  as string) as currentwardid,--当前护理单元ID
cast(visit_record_visitwardcode  as string) as currentwardcode,--当前护理单元编码
cast(visit_record_visitwardname as string) as currentwardname,--当前护理单元名称
cast(visit_record_visitdeptid  as string) as currentmedelementid,--当前医疗单元ID
cast(visit_record_visitdeptcode  as string) as currentmedelementcode,--当前医疗单元编码
cast(visit_record_visitdeptname  as string) as currentmedelementname,--当前医疗单元名称
cast(visit_record_attendingdoctid  as string) as currentstaffgroupid,--当前医疗组长ID
cast(visit_record_attendingdoctcode  as string) as currentstaffgroupcode,--当前医疗组长工号
cast(visit_record_attendingdoctname  as string) as currentstaffgroupname,--当前医疗组长名称
cast((case when visit_record_visitbedcode is null then 1 else 0 end) as string) as iswait,--是否等待区
cast((case when visit_record_visitbedcode is not null then 1 else 0 end) as int) as beinhospperscount,--在院人次
cast('datacenter_db' as string) as datasourceflag,--数据来源标识
cast('visit_record' as string) as dstable,--接入数据源的表
cast('rowkey' as string) as indatasourcekey,--接入数据源的KEY
cast(rowkey  as string) as indatasourcekeyvalue,--接入数据源的KEY值
cast(visit_record_isdeleted  as string) as isdelete,--是否物理删除
cast(visit_record_lastupdatedttm  as string) as lastupdatedttm ,--最后更新时间
cast(now()  as string) as datacreatedttm   --数据创建时间
from datacenter_db.visit_record
where
	visit_record_isdeleted  ='0'
 and
	visit_record_visitwardcode  is not null
 and
	visit_record_visitrecordstatuscode  = 'A'
 and
	visit_record_visittypecode  = 'I'