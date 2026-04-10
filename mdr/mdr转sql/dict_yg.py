# coding=utf-8

import os
import warnings

import pandas as pd

import pyspark.sql.functions as F

warnings.filterwarnings("ignore")
os.environ['HADOOP_USER_NAME'] = "hxhdp"
os.environ['SPARK_HOME'] = "/home/hxhdp/bi/spark2/spark2-lz"
os.environ['PYSPARK_PYTHON'] = "/home/hxhdp/bi/anaconda3/bin/python3"
APP_NAME = "ov_test"
pd.options.display.max_columns= None
pd.options.display.max_rows= None

class Test:
    #运管院区字典
    def ygwardhospsql(self):
        sql = ("""
                           select   dept_code||'||'|| sjyq.medorgcode wardrowkey,case when ctd_startdate is null then '1900-01-01 00:00:00' else ctd_startdate||' 00:00:00' end hossdateward,case when ctd_enddate is null then '2099-12-31 00:00:00' else ctd_enddate||' 00:00:00' end hosedateward,
                           sjyq.hoscode,sjyq.threecode threecodeward,sjyq.threedesc  threenameward, mapp.refname omthreenameward,mapp.refcode omthreecodeward
                             from  ( select __changeindex,code,dept_code,name,ctd_startdate,ctd_enddate,medorgcode,ctdloc3code
                             ,row_number()over(partition by code,ctdloc3code order by __changeindex desc ) as rtn 
                             from md.dict_loc8 dicloc8
                             where __dictionary_id=(select max(__dictionary_id)  from md.dict_loc8 ) 
                              and __changeindex=(select max(__changeindex) from  md.dict_loc8 where code=dicloc8.code)
                             --group by __changeindex,code,dept_code,name,ctd_startdate,ctd_enddate,medorgcode,ctdloc3code
                             ) loc8 
                             left join  (select hoscode,threecode,threedesc ,hoscode as medorgcode,code  from md.tbl_1308_h  where isdeleted='0' ) sjyq on loc8.medorgcode=sjyq.medorgcode and loc8.ctdloc3code=sjyq.threecode
                             left join  md.mappingmember mapp   on mapp.code=sjyq.code
                             where   mapp.isdeleted='0'  and mapp.dictionaryname like '%三级院区%'    --院区三级字典  +运管院区""")
        return sql

    def ygzshospsql(self):
        sql = ("""
                           select   dept_code||'||'|| sjyq.medorgcode zsrowkey,case when ctd_startdate is null then '1900-01-01 00:00:00' else ctd_startdate||' 00:00:00' end hossdatezs,case when ctd_enddate is null then '2099-12-31 00:00:00' else ctd_enddate||' 00:00:00' end hosedatezs,
                            sjyq.hoscode,sjyq.threecode threecodezs,sjyq.threedesc  threenamezs, mapp.refname omthreenamezs,mapp.refcode omthreecodezs
                             from ( select __changeindex,code,dept_code,name,ctd_startdate,ctd_enddate,medorgcode,ctdloc3code
                             --,row_number()over(partition by code,ctdloc3code order by __changeindex desc ) as rtn 
                             from md.dict_loc8 dicloc8
                             where __dictionary_id=(select max(__dictionary_id)  from md.dict_loc8 ) 
                             and __changeindex=(select max(__changeindex) from  md.dict_loc8 where code=dicloc8.code)
                             --group by __changeindex,code,dept_code,name,ctd_startdate,ctd_enddate,medorgcode,ctdloc3code
                             ) loc8 
                             left join  (select hoscode,threecode,threedesc ,hoscode as medorgcode,code  from md.tbl_1308_h  where isdeleted='0' )  sjyq on loc8.medorgcode=sjyq.medorgcode and loc8.ctdloc3code=sjyq.threecode
                             left join  md.mappingmember mapp   on mapp.code=sjyq.code
                             where   mapp.isdeleted='0'  and mapp.dictionaryname like '%三级院区%'   --院区三级字典  +运管院区""")
        return sql

    def yglochospsql(self):
        sql = ("""
                select   dept_code||'||'|| sjyq.medorgcode locrowkey2,case when ctd_startdate is null then '1900-01-01 00:00:00' else ctd_startdate||' 00:00:00' end hossdateloc,case when ctd_enddate is null then '2099-12-31 00:00:00' else ctd_enddate||' 00:00:00' end hosedateloc,
                            sjyq.hoscode,sjyq.threecode threecodeloc,sjyq.threedesc  threenameloc, mapp.refname omthreenameloc,mapp.refcode omthreecodeloc
                             from ( select __changeindex,code,dept_code,name,ctd_startdate,ctd_enddate,medorgcode,ctdloc3code
                             --,row_number()over(partition by code,ctdloc3code order by __changeindex desc ) as rtn 
                             from md.dict_loc8 dicloc8
                             where __dictionary_id=(select max(__dictionary_id)  from md.dict_loc8 ) 
							  and __changeindex=(select max(__changeindex) from  md.dict_loc8 where code=dicloc8.code)
							 --group by __changeindex,code,dept_code,name,ctd_startdate,ctd_enddate,medorgcode,ctdloc3code
                             )as   loc8 
                             left join (select hoscode,threecode,threedesc ,hoscode as medorgcode,code  from md.tbl_1308_h  where isdeleted='0' ) sjyq on loc8.medorgcode=sjyq.medorgcode and loc8.ctdloc3code=sjyq.threecode
                             left join  md.mappingmember mapp   on mapp.code=sjyq.code
                             where       mapp.isdeleted='0'  and mapp.dictionaryname like '%三级院区%'   --院区三级字典  +运管院区""")
        return sql
    #运管科室字典L
    def ygdocsql(self):
        sql=("""	select  doc.code doccode ,case when doc.startdate is null then '1900-01-01 00:00:00' else doc.startdate end docssdate,
        case when doc.enddate is  null then '2099-12-31 00:00:00' else doc.enddate end docedate 
                        ,ygloc.code ygdocloccode,ygloc.name ygdoclocname,ygloc.id as ygdoclocid
                        from ( select __changeindex,code,startdate,enddate,ygks
                        --,row_number()over(partition by code ,ygks,startdate,enddate order by __changeindex desc ) as rtndoc 
                        from md.tbl_1307_h tb1307
                         where (__dictionary_id=(select max(__dictionary_id)  from md.tbl_1307_h) and isdeleted='0' ) 
                        and __changeindex=(select max(__changeindex) from  md.tbl_1307_h where code=tb1307.code)
                        --group by __changeindex,code,startdate,enddate,ygks
                             )   doc
                        left join  ( select __changeindex,code,name,rowkey,depttypeid,id,row_number()over(partition by code order by __changeindex desc ) as rtn from md.tbl_1305_h where (__dictionary_id=(select max(__dictionary_id)  from md.tbl_1305_h) and isdeleted='0' ) group by __changeindex,code,name,rowkey,depttypeid,id
                             )as   ygloc on ygloc.rowkey=doc.ygks 
                        --and ygloc.medorgcode=doc.medorgcode  --运管需要的80个科室
                        where   rtn=1  --包含七级科室的字典表""")
        return sql
    def yglocsql(self):
        sql=("""	/*科室取运管科室值.  code+loclochos+startdate+endate是唯一的记录*/
              
 select  ctloc.ctloc_code||'||'|| ctloc.hospitalcode locrowkey,ygloc.depttypeid,
                        case when ctloc.startdate is null then '1900-01-01 00:00:00' else ctloc.startdate end  locssdate,case when ctloc.enddate is null then '2099-12-31 00:00:00' else   ctloc.enddate  end locedate
                        ,ygloc.code ygloccode,ygloc.name yglocname,ygloc.id as yglocid
                        from ( select __changeindex,ctloc_code,hospitalcode,startdate,enddate,ygks
                       -- ,row_number()over(partition by ctloc_code,hospitalcode,startdate,enddate,ygks order by __changeindex desc ) as rtnloc 
                        from md.tbl_1306_h  tb1306
                        where (__dictionary_id=(select max(__dictionary_id)  from md.tbl_1306_h) and isdeleted='0' ) 
                         and __changeindex=(select max(__changeindex) from  md.tbl_1306_h where code=tb1306.code)
						 
                        -- group by __changeindex,ctloc_code,startdate,enddate,ygks,hospitalcode
                        )  ctloc   --包含七级科室的字典表 
                        left join ( select __changeindex,code,name,rowkey,depttypeid,id,row_number()over(partition by code order by __changeindex desc ) as rtn from md.tbl_1305_h where (__dictionary_id=(select max(__dictionary_id)  from md.tbl_1305_h) and isdeleted='0' ) group by __changeindex,code,name,rowkey,depttypeid,id
                             )as  ygloc on ygloc.rowkey=ctloc.ygks 
                        -- and ygloc.medorgcode=ctloc.hospitalcode  --运管需要的80个科室
                         where    rtn=1
						  """)
        return  sql

    def hsql(self):
        sql=("""select sjyq.hoscode hosc,sjyq.threecode threec,sjyq.threedesc  threen, mapp.refname omthreen,mapp.refcode omthreec
                from  md.tbl_1308_h  sjyq
                left join  md.mappingmember mapp   on mapp.code=sjyq.code
                where hoscode<>'HID0101'""")
        return sql

    def getomtypedate(self,medorgcode, hostype, loctype, admtype, outhospdate, df, ygzshospdic, ygwardhospdic, yglochospdic,
                      yglocdic, ygdocdic, usedfdoccode, usedfdeptcode, usedfdeptcode2, usedfdeptname, usedfwardcode,
                      omdeptcode, omdeptdesc, omdeptid, threecode, threename, omthreecode, omthreename, zscode, hcode):
        # df=df.withColumn('medorgcode', df[medorgcode])
        df = df.join(hcode, df[medorgcode] == hcode['hosc'], 'left')  # 直接用医院判断院区的

        if usedfdeptcode2 =='uroomcode':
            df = df.join(zscode, on=['medorgcode', 'visitno'], how='left')  # 关联诊室

        df = df.withColumn('outhospdate1', F.col(outhospdate).cast('string')) \
            .withColumn('locrowkey', F.concat_ws('||', F.col(usedfdeptcode), df[medorgcode])) \
            .withColumn('locrowkey2', F.concat_ws('||', F.col(usedfdeptcode), df[medorgcode])) \
            .withColumn('zsrowkey', F.concat_ws('||', F.col(usedfdeptcode2), df[medorgcode])) \
            .withColumn('wardrowkey', F.concat_ws('||', F.col(usedfwardcode), df[
            medorgcode]))  # zsrowkey 取哪一个值待确定后传入 locrowkey2 不管传入的是就诊科室还是开单科室，都用就诊科室关联,有就诊科室就传入就诊科室，没有就传入相同字段usedfdeptcode


        df = df.join(ygwardhospdic, (
                    (df.wardrowkey == ygwardhospdic.wardrowkey) & (df.outhospdate1 >= ygwardhospdic.hossdateward) & (
                        df.outhospdate1 <= ygwardhospdic.hosedateward)), 'left')
        df = df.join(ygzshospdic, (
                    (df.zsrowkey == ygzshospdic.zsrowkey) & (df.outhospdate1 >= ygzshospdic.hossdatezs) & (
                        df.outhospdate1 <= ygzshospdic.hosedatezs)), 'left')
        df = df.join(yglochospdic, (
                    (df.locrowkey2 == yglochospdic.locrowkey2) & (df.outhospdate1 >= yglochospdic.hossdateloc) & (
                        df.outhospdate1 <= yglochospdic.hosedateloc)), 'left')
        # #运管科室关联
        df = df.join(yglocdic, ((df.locrowkey == yglocdic.locrowkey) & (df.outhospdate1 >= yglocdic.locssdate) & (
                    df.outhospdate1 <= yglocdic.locedate)), 'left')
        df = df.join(ygdocdic, ((df[usedfdoccode] == ygdocdic.doccode) & (df.outhospdate1 >= ygdocdic.docssdate) & (
                    df.outhospdate1 <= ygdocdic.docedate)), 'left')

        if hostype == 'ward+loc+admtype+depttype':
            condition_med_I = ((df[medorgcode] == 'HID0101') & (df[admtype] == 'I'))
            condition_med_E = ((df[medorgcode] == 'HID0101') & (df[admtype] == 'E'))
            condition_zyq = ((df.depttypeid == '3') | (df.threecodeloc != '主院区'))
            condition_fzyq = ((df.depttypeid != '3') & (df.threecodeloc == '主院区'))
            df = df.select("*",
                           F.when(df[medorgcode] != 'HID0101', df['threec'])
                           .when(condition_med_I & condition_zyq, df.threecodeloc)
                           .when(condition_med_I & condition_fzyq, df.threecodeward)
                           .when(condition_med_E,
                                 F.when(df.threecodeward.isNotNull(), df.threecodeward).otherwise(df.threecodezs))
                           .otherwise(df.threecodeloc).alias(threecode),
                           F.when(df[medorgcode] != 'HID0101', df['threen'])
                           .when(condition_med_I & condition_zyq, df.threenameloc)
                           .when(condition_med_I & condition_fzyq, df.threenameward)
                           .when(condition_med_E,
                                 F.when(df.threecodeward.isNotNull(), df.threenameward).otherwise(df.threenamezs))
                           .otherwise(df.threenameloc).alias(threename),
                           F.when(df[medorgcode] != 'HID0101', df['omthreec'])
                           .when(condition_med_I & condition_zyq, df.omthreecodeloc)
                           .when(condition_med_I & condition_fzyq, df.omthreecodeward)
                           .when(condition_med_E,
                                 F.when(df.omthreecodeward.isNotNull(), df.omthreecodeward).otherwise(df.omthreecodezs))
                           .otherwise(df.omthreecodeloc).alias(omthreecode),
                           F.when(df[medorgcode] != 'HID0101', df['omthreen'])
                           .when(condition_med_I & condition_zyq, df.omthreenameloc)
                           .when(condition_med_I & condition_fzyq, df.omthreenameward)
                           .when(condition_med_E, F.when(df.omthreecodeward.isNotNull(), df.omthreenameward).otherwise(df.omthreenamezs))
                           .otherwise(df.omthreenameloc).alias(omthreename))

        if hostype == 'ward+loc+admtype':
            condition_med_I = ((df[medorgcode] == 'HID0101') & (df[admtype] == 'I'))
            condition_med_E = ((df[medorgcode] == 'HID0101') & (df[admtype] == 'E'))
            df = df.select("*", F.when(df[medorgcode] != 'HID0101', df['threec'])
                           .when(condition_med_I, df.threecodeward)
                           .when(condition_med_E & df.threecodeward.isNotNull(), df.threecodeward)
                           .when(condition_med_E & df.threecodeward.isNull(), df.threecodezs).otherwise(
                df.threecodeloc).alias(threecode)
                           , F.when(df[medorgcode] != 'HID0101', df['threen'])
                           .when(condition_med_I, df.threenameward)
                           .when(condition_med_E & df.threecodeward.isNotNull(), df.threenameward)
                           .when(condition_med_E & df.threecodeward.isNull(), df.threenamezs).otherwise(
                    df.threenameloc).alias(threename)

                           , F.when(df[medorgcode] != 'HID0101', df['omthreec'])
                           .when(condition_med_I, df.omthreecodeward)
                           .when(condition_med_E & df.omthreecodeward.isNotNull(), df.omthreecodeward)
                           .when(condition_med_E & df.omthreecodeward.isNull(), df.omthreecodezs).otherwise(
                    df.omthreecodeloc).alias(omthreecode)

                           , F.when(df[medorgcode] != 'HID0101', df['omthreen'])
                           .when(condition_med_I, df.omthreenameward)
                           .when(condition_med_E & df.omthreecodeward.isNotNull(), df.omthreenameward)
                           .when(condition_med_E & df.omthreecodeward.isNull(), df.omthreenamezs).otherwise(
                    df.omthreenameloc).alias(omthreename))

        if hostype == 'ward':
            df = df.select("*", F.when(df[medorgcode] != 'HID0101', df['threec']).otherwise(df.threecodeward).alias(
                threecode)
                           , F.when(df[medorgcode] != 'HID0101', df['threen']).otherwise(df.threenameward).alias(
                    threename)
                           , F.when(df[medorgcode] != 'HID0101', df['omthreec']).otherwise(df.omthreecodeward).alias(
                    omthreecode)
                           , F.when(df[medorgcode] != 'HID0101', df['omthreen']).otherwise(df.omthreenameward).alias(
                    omthreename))
        if hostype == 'loc':
            df = df.select("*",
                           F.when(df[medorgcode] != 'HID0101', df['threec']).otherwise(df.threecodeloc).alias(threecode)
                           ,
                           F.when(df[medorgcode] != 'HID0101', df['threen']).otherwise(df.threenameloc).alias(threename)
                           , F.when(df[medorgcode] != 'HID0101', df['omthreec']).otherwise(df.omthreecodeloc).alias(
                    omthreecode)
                           , F.when(df[medorgcode] != 'HID0101', df['omthreen']).otherwise(df.omthreenameloc).alias(
                    omthreename))

        if loctype == 'loc':
            df = df.select("*", F.when(df.outhospdate1.isNull(), '998').when(df.ygloccode.isNotNull(),
                                                                                          df.ygloccode).otherwise(
                '997').alias(omdeptcode)
                           , F.when(df.outhospdate1.isNull(), '七级科室空值').when(df.ygloccode.isNotNull(),
                                                                                   df.yglocname).otherwise(
                    '运管科室待归').alias(omdeptdesc)
                           , F.when(df.outhospdate1.isNull(), '87').when(df.ygloccode.isNotNull(),
                                                                                     df.yglocid).otherwise(
                    '88').alias(omdeptid))
            # df.show()
        if loctype == 'doc+loc':
            df = df.select("*", F.when(df.ygdocloccode.isNotNull(), df.ygdocloccode).when(df.ygloccode.isNotNull(),   df.ygloccode)
                           .when(df[usedfdeptcode].isNull(), '998').when(df[usedfdoccode].isNull(), '996').otherwise( '997').alias(omdeptcode)
                           , F.when(df.ygdocloccode.isNotNull(), df.ygdoclocname).when(df.ygloccode.isNotNull(),  df.yglocname)
                           .when(df[usedfdeptcode].isNull(), '七级科室空值').when(df[usedfdoccode].isNull(), '医疗组长空值').otherwise( '运管科室待归').alias(omdeptdesc)
                           ,
                           F.when(df.ygdocloccode.isNotNull(), df.ygdoclocid).when(df.ygloccode.isNotNull(), df.yglocid)
                           .when(df[usedfdeptcode].isNull(), '87').when(df[usedfdoccode].isNull(), '89').otherwise( '88').alias(omdeptid))

        if loctype == 'doc+loc+admtype':
            condition_NTX_O = (~df[usedfdeptname].contains('特需')) & (~df[usedfdeptname].contains('全科')) & ( df[admtype] == 'O')
            condition_TX_O = ((df[usedfdeptname].contains('特需')) | (df[usedfdeptname].contains('全科'))) & ( df[admtype] == 'O')
            df = df.select("*", F.when(df[usedfdeptcode].isNull(), '998').when(df[admtype].isNull(),'就诊类型空值code')
                           .when((df[admtype].isin('E', 'I')) & (df[usedfdeptname].contains('急诊')), '20')
                           .when((df[admtype] == 'I') & (~df[usedfdeptname].contains('急诊')) & (df.ygdocloccode.isNotNull()), df.ygdocloccode)
                           .when((df[admtype] == 'I') & (df.ygloccode.isNotNull()), df.ygloccode)
                           .when(condition_TX_O, '212')
                           .when(condition_NTX_O & (df.ygdocloccode.isNotNull()), df.ygdocloccode)
                           .when(condition_NTX_O & (df.ygdocloccode.isNull()) & (df.ygloccode.isNotNull()), df.ygloccode)
                           .when(df[usedfdoccode].isNull(), '996').otherwise('997').alias( omdeptcode) ,
                           F.when(df[usedfdeptcode].isNull(), '七级科室空值').when(df[admtype].isNull(), '就诊类型空值')
                           .when((df[admtype].isin('E', 'I')) & (df[usedfdeptname].contains('急诊')), '急诊科医疗单元')
                           .when((df[admtype] == 'I') & (~df[usedfdeptname].contains('急诊')) & ( df.ygdocloccode.isNotNull()), df.ygdoclocname).when( (df[admtype] == 'I') & (df.ygloccode.isNotNull()), df.yglocname)
                           .when(condition_TX_O, '全科医学中心医疗单元')
                           .when(condition_NTX_O & (df.ygdocloccode.isNotNull()), df.ygdoclocname)
                           .when(condition_NTX_O & (df.ygdocloccode.isNull()) & (df.ygloccode.isNotNull()),df.yglocname)
                           .when(df[usedfdoccode].isNull(), '医疗组长空值').otherwise('运管科室待归').alias(omdeptdesc)
                           , F.when(df[usedfdeptcode].isNull(), '87').when(df[admtype].isNull(), '90')
                           .when((df[admtype].isin('E', 'I')) & (df[usedfdeptname].contains('急诊')), '47')
                           .when((df[admtype] == 'I') & (~df[usedfdeptname].contains('急诊')) & (df.ygdocloccode.isNotNull()), df.ygdoclocid)
                           .when((df[admtype] == 'I') & (df.ygloccode.isNotNull()), df.yglocid)
                           .when(condition_TX_O, '91')
                           .when(condition_NTX_O & (df.ygdocloccode.isNotNull()), df.ygdoclocid)
                           .when(condition_NTX_O & (df.ygdocloccode.isNull()) & (df.ygloccode.isNotNull()), df.yglocid)
                           .when(df.ygdocloccode.isNull(), '89').otherwise('88').alias(omdeptid))
        if loctype == 'doc+loc+schdule+level':
            # scheduletypedesc,leveldesc
            # condition_Nnet_E=~df['scheduletypedesc'].contains('网络') & df['leveldesc'].contains('急诊') #非线上+急诊
            # condition_TX_Nnet_NE = ~df['scheduletypedesc'].contains('网络') & ~df['leveldesc'].contains('急诊')& (df[usedfdeptname].contains('特需')|df[usedfdeptname].contains('全科')) #非线上+非急诊+特需
            # condition_NTX_Nnet_NE = ~df['scheduletypedesc'].contains('网络') & ~df['leveldesc'].contains('急诊') & ~df[usedfdeptname].contains('特需') & ~df[usedfdeptname].contains('全科')#非线上+非急诊+非特需
            condition_Nnet_E = ~F.coalesce('scheduletypedesc', F.lit('空')).contains('网络') & F.coalesce('leveldesc',F.lit('空')).contains( '急诊')  # 非线上+急诊
            condition_TX_Nnet_NE = ~F.coalesce('scheduletypedesc', F.lit('空')).contains('网络') & ~F.coalesce('leveldesc', F.lit('空')).contains('急诊') & ( df[usedfdeptname].contains('特需') | df[usedfdeptname].contains( '全科'))  # 非线上+非急诊+特需
            condition_NTX_Nnet_NE = ~F.coalesce('scheduletypedesc', F.lit('空')).contains('网络') & ~F.coalesce('leveldesc', F.lit('空')).contains('急诊') & ~df[usedfdeptname].contains('特需') & ~df[ usedfdeptname].contains('全科')  # 非线上+非急诊+非特需

            df = df.select("*", F.when(df[usedfdeptcode].isNull(), '998')
                           .when(condition_Nnet_E, '20')
                           .when(condition_TX_Nnet_NE, '212')
                           .when(condition_NTX_Nnet_NE & (df.ygdocloccode.isNotNull()), df.ygdocloccode)
                           .when(condition_NTX_Nnet_NE & (df.ygdocloccode.isNull()) & (df.ygloccode.isNotNull()), df.ygloccode).otherwise('997').alias(omdeptcode)
                           , F.when(df[usedfdeptcode].isNull(), '七级科室空值')
                           .when(condition_Nnet_E, '急诊科医疗单元')
                           .when(condition_TX_Nnet_NE, '全科医学中心医疗单元')
                           .when(condition_NTX_Nnet_NE & (df.ygdocloccode.isNotNull()), df.ygdoclocname)
                           .when(condition_NTX_Nnet_NE & (df.ygdocloccode.isNull()) & (df.ygloccode.isNotNull()),df.yglocname).otherwise('运管科室待归').alias(omdeptdesc)
                           , F.when(df[usedfdeptcode].isNull(), '87')
                           .when(condition_Nnet_E, '47')
                           .when(condition_TX_Nnet_NE, '91')
                           .when(condition_NTX_Nnet_NE & (df.ygdocloccode.isNotNull()), df.ygdoclocid)
                           .when(condition_NTX_Nnet_NE & (df.ygdocloccode.isNull()) & (df.ygloccode.isNotNull()), df.yglocid).otherwise('88').alias(omdeptid))
        # 47 20 急诊科医疗单元  91  212  全科医学中心医疗单元 (F.array_contains(F.coalesce(df[usedfdeptcode],F.lit(0)),'急诊'))
        # df.show(600)
        df = df.withColumn(omdeptcode, F.when(df[omdeptcode].isNull(), '997').otherwise(df[omdeptcode])) \
            .withColumn(omdeptdesc, F.when(df[omdeptdesc].isNull(), '运管科室待归').otherwise(df[omdeptdesc])) \
            .withColumn(omdeptid, F.when(df[omdeptid].isNull(), '88').otherwise(df[omdeptid])) \
            .withColumn(threecode, F.when(df[threecode].isNull(), 'YGF9998').otherwise(df[threecode])) \
            .withColumn(threename, F.when(df[threename].isNull(), '三级院区待归').otherwise(df[threename])) \
            .withColumn(omthreecode,F.when(df[omthreecode].isNull(), 'YGF9997').otherwise(df[omthreecode])) \
            .withColumn(omthreename, F.when(df[omthreename].isNull(), '运管三级院区待归').otherwise(df[omthreename]))
        # df.show()
        field_drop = ['hosc', 'threec', 'threen', 'omthreen', 'omthreec', 'outhospdate1', 'hoscode', 'depttypeid',
                      'locrowkey2', 'zsrowkey', 'hossdateward', 'hosedateward', 'hossdatezs', 'hosedatezs',
                      'hossdateloc', 'hosedateloc', 'threecodeward', 'threecodezs', 'threecodeloc', 'threenameward',
                      'threenamezs', 'threenameloc', 'omthreecodeward', 'omthreecodezs', 'omthreecodeloc',
                      'omthreenameward', 'omthreenamezs', 'threenameloc', 'threecode1', 'threename1', 'omthreecode1',
                      'omthreename1', 'omthreenameloc', 'yglocid', 'locrowkey', 'wardrowkey', 'hosrowkey', 'hossdate',
                      'hosedate', 'doccode', 'docssdate', 'docedate', 'ygdocloccode', 'ygdoclocname', 'ygdoclocid',
                      'locrowkey', 'locssdate', 'locedate', 'ygloccode', 'yglocname', 'yglocname']
        df_clean = df.drop(*field_drop)
        if 'uroomcode' in df_clean.schema.fieldNames():
            df_clean = df_clean.drop('uroomcode')

        # df_clean.show(200)
        return df_clean

    def __init__(self,spark):
        self.spark = spark
        self.ygzshospdic=F.broadcast(spark.sql(self.ygzshospsql()).distinct())
        self.ygwardhospdic=F.broadcast(spark.sql(self.ygwardhospsql()).distinct())
        self.yglochospdic=F.broadcast(spark.sql(self.yglochospsql()).distinct())
        self.ygdocdic=F.broadcast(spark.sql(self.ygdocsql()).distinct())
        self.yglocdic=F.broadcast(spark.sql(self.yglocsql()).distinct())
        self.hcode=F.broadcast(spark.sql(self.hsql()).distinct())
        # uscodeadm = F.broadcast(spark.sql("""--#医疗组长
        # select  episodeid vid ,code as uscode, trans.medorgcode
        # from(select medorgcode,episodeid ,todocid,transtype,row_number()over(partition by episodeid order by rowkey desc ) as rtn  from datacenter_db.transrecord where transtype = 'D' and todocid is not null )trans
        # join md.dict_ssusr uuser on todocid=uuser.ssusr_rowid and uuser.medorgcode=trans.medorgcode where  rtn=1"""))
        # sus3 = spark.sql("""select DISTINCT medorgcodeu,ctpcp_rowid admctdorid ,name admctdorname,code admctdorcode from md.dict_ctpcp""")
        self.zscode= F.broadcast(spark.sql("""select MedOrgCode ,visit_reg_visitno visitno,visit_reg_roomcode uroomcode    FROM  datacenter_db.Visit_REG  where visit_reg_visittypecode='E' AND visit_reg_visitid<>'-1' AND visit_reg_isdeleted='0' and visit_reg_roomcode is not null""").distinct())

    # yghospdic.show()
if __name__ == '__main__':
    print("hehe")
    # 部署时先考文件 cp /home/hxhdp/bi/wyl/dic/dict_yg.py /home/hxhdp/bi/py_schedule/public/dict_yg.py
    # 部署时先考文件 cp /home/hxhdp/bi/wyl/dic/dict_yg.py /home/hxhdp/bi/py_schedule/t5_beinhosp/dict_yg.py
#     # yglocdic.show()
    # 调用加--py-files /home/hxhdp/bi/py_schedule/public/dict_yg.py

