-- =====================================================
-- MDR在院病人表 ETL SQL实现
-- 原PySpark脚本: mdr_beinhosp_mul_omdept.py + dict_yg.py
-- 转换日期: 2026-01-27
-- =====================================================

-- =====================================================
-- 血缘关系说明:
-- =====================================================
-- 【源表】
--   datacenter_db.visit_record    - 就诊记录主表
-- 
-- 【字典表】
--   md.dict_loc8                  - 八级科室字典
--   md.tbl_1308_h                 - 三级院区字典
--   md.tbl_1305_h                 - 运管科室字典
--   md.tbl_1306_h                 - 科室-运管科室映射
--   md.tbl_1307_h                 - 医生-运管科室映射
--   md.mappingmember              - 映射成员表(院区映射)
--
-- 【目标表】
--   m1.mdr_beinhosp               - 在院病人宽表
-- =====================================================

-- =====================================================
-- STEP 1: 创建字典临时表/CTE
-- =====================================================

WITH 
-- 1.1 运管院区字典(护理单元维度) - ygwardhospdic
dict_ward_hosp AS (
    SELECT DISTINCT
        loc8.dept_code || '||' || sjyq.medorgcode AS wardrowkey,
        CASE WHEN loc8.ctd_startdate IS NULL THEN '1900-01-01 00:00:00' 
             ELSE loc8.ctd_startdate || ' 00:00:00' END AS hossdateward,
        CASE WHEN loc8.ctd_enddate IS NULL THEN '2099-12-31 00:00:00' 
             ELSE loc8.ctd_enddate || ' 00:00:00' END AS hosedateward,
        sjyq.hoscode,
        sjyq.threecode AS threecodeward,
        sjyq.threedesc AS threenameward,
        mapp.refname AS omthreenameward,
        mapp.refcode AS omthreecodeward
    FROM (
        SELECT __changeindex, code, dept_code, name, ctd_startdate, ctd_enddate, medorgcode, ctdloc3code,
               ROW_NUMBER() OVER(PARTITION BY code, ctdloc3code ORDER BY __changeindex DESC) AS rtn
        FROM md.dict_loc8 dicloc8
        WHERE __dictionary_id = (SELECT MAX(__dictionary_id) FROM md.dict_loc8)
          AND __changeindex = (SELECT MAX(__changeindex) FROM md.dict_loc8 WHERE code = dicloc8.code)
    ) loc8
    LEFT JOIN (
        SELECT hoscode, threecode, threedesc, hoscode AS medorgcode, code 
        FROM md.tbl_1308_h WHERE isdeleted = '0'
    ) sjyq ON loc8.medorgcode = sjyq.medorgcode AND loc8.ctdloc3code = sjyq.threecode
    LEFT JOIN md.mappingmember mapp ON mapp.code = sjyq.code
    WHERE mapp.isdeleted = '0' AND mapp.dictionaryname LIKE '%三级院区%'
),

-- 1.2 运管院区字典(诊室维度) - ygzshospdic
dict_zs_hosp AS (
    SELECT DISTINCT
        loc8.dept_code || '||' || sjyq.medorgcode AS zsrowkey,
        CASE WHEN loc8.ctd_startdate IS NULL THEN '1900-01-01 00:00:00' 
             ELSE loc8.ctd_startdate || ' 00:00:00' END AS hossdatezs,
        CASE WHEN loc8.ctd_enddate IS NULL THEN '2099-12-31 00:00:00' 
             ELSE loc8.ctd_enddate || ' 00:00:00' END AS hosedatezs,
        sjyq.hoscode,
        sjyq.threecode AS threecodezs,
        sjyq.threedesc AS threenamezs,
        mapp.refname AS omthreenamezs,
        mapp.refcode AS omthreecodezs
    FROM (
        SELECT __changeindex, code, dept_code, name, ctd_startdate, ctd_enddate, medorgcode, ctdloc3code
        FROM md.dict_loc8 dicloc8
        WHERE __dictionary_id = (SELECT MAX(__dictionary_id) FROM md.dict_loc8)
          AND __changeindex = (SELECT MAX(__changeindex) FROM md.dict_loc8 WHERE code = dicloc8.code)
    ) loc8
    LEFT JOIN (
        SELECT hoscode, threecode, threedesc, hoscode AS medorgcode, code 
        FROM md.tbl_1308_h WHERE isdeleted = '0'
    ) sjyq ON loc8.medorgcode = sjyq.medorgcode AND loc8.ctdloc3code = sjyq.threecode
    LEFT JOIN md.mappingmember mapp ON mapp.code = sjyq.code
    WHERE mapp.isdeleted = '0' AND mapp.dictionaryname LIKE '%三级院区%'
),

-- 1.3 运管院区字典(科室维度) - yglochospdic
dict_loc_hosp AS (
    SELECT DISTINCT
        loc8.dept_code || '||' || sjyq.medorgcode AS locrowkey2,
        CASE WHEN loc8.ctd_startdate IS NULL THEN '1900-01-01 00:00:00' 
             ELSE loc8.ctd_startdate || ' 00:00:00' END AS hossdateloc,
        CASE WHEN loc8.ctd_enddate IS NULL THEN '2099-12-31 00:00:00' 
             ELSE loc8.ctd_enddate || ' 00:00:00' END AS hosedateloc,
        sjyq.hoscode,
        sjyq.threecode AS threecodeloc,
        sjyq.threedesc AS threenameloc,
        mapp.refname AS omthreenameloc,
        mapp.refcode AS omthreecodeloc
    FROM (
        SELECT __changeindex, code, dept_code, name, ctd_startdate, ctd_enddate, medorgcode, ctdloc3code
        FROM md.dict_loc8 dicloc8
        WHERE __dictionary_id = (SELECT MAX(__dictionary_id) FROM md.dict_loc8)
          AND __changeindex = (SELECT MAX(__changeindex) FROM md.dict_loc8 WHERE code = dicloc8.code)
    ) loc8
    LEFT JOIN (
        SELECT hoscode, threecode, threedesc, hoscode AS medorgcode, code 
        FROM md.tbl_1308_h WHERE isdeleted = '0'
    ) sjyq ON loc8.medorgcode = sjyq.medorgcode AND loc8.ctdloc3code = sjyq.threecode
    LEFT JOIN md.mappingmember mapp ON mapp.code = sjyq.code
    WHERE mapp.isdeleted = '0' AND mapp.dictionaryname LIKE '%三级院区%'
),

-- 1.4 运管科室字典(医生维度) - ygdocdic
dict_doc AS (
    SELECT DISTINCT
        doc.code AS doccode,
        CASE WHEN doc.startdate IS NULL THEN '1900-01-01 00:00:00' ELSE doc.startdate END AS docssdate,
        CASE WHEN doc.enddate IS NULL THEN '2099-12-31 00:00:00' ELSE doc.enddate END AS docedate,
        ygloc.code AS ygdocloccode,
        ygloc.name AS ygdoclocname,
        ygloc.id AS ygdoclocid
    FROM (
        SELECT __changeindex, code, startdate, enddate, ygks
        FROM md.tbl_1307_h tb1307
        WHERE __dictionary_id = (SELECT MAX(__dictionary_id) FROM md.tbl_1307_h) 
          AND isdeleted = '0'
          AND __changeindex = (SELECT MAX(__changeindex) FROM md.tbl_1307_h WHERE code = tb1307.code)
    ) doc
    LEFT JOIN (
        SELECT __changeindex, code, name, rowkey, depttypeid, id,
               ROW_NUMBER() OVER(PARTITION BY code ORDER BY __changeindex DESC) AS rtn
        FROM md.tbl_1305_h 
        WHERE __dictionary_id = (SELECT MAX(__dictionary_id) FROM md.tbl_1305_h) AND isdeleted = '0'
        GROUP BY __changeindex, code, name, rowkey, depttypeid, id
    ) ygloc ON ygloc.rowkey = doc.ygks
    WHERE ygloc.rtn = 1
),

-- 1.5 运管科室字典(科室维度) - yglocdic
dict_loc AS (
    SELECT DISTINCT
        ctloc.ctloc_code || '||' || ctloc.hospitalcode AS locrowkey,
        ygloc.depttypeid,
        CASE WHEN ctloc.startdate IS NULL THEN '1900-01-01 00:00:00' ELSE ctloc.startdate END AS locssdate,
        CASE WHEN ctloc.enddate IS NULL THEN '2099-12-31 00:00:00' ELSE ctloc.enddate END AS locedate,
        ygloc.code AS ygloccode,
        ygloc.name AS yglocname,
        ygloc.id AS yglocid
    FROM (
        SELECT __changeindex, ctloc_code, hospitalcode, startdate, enddate, ygks
        FROM md.tbl_1306_h tb1306
        WHERE __dictionary_id = (SELECT MAX(__dictionary_id) FROM md.tbl_1306_h) 
          AND isdeleted = '0'
          AND __changeindex = (SELECT MAX(__changeindex) FROM md.tbl_1306_h WHERE code = tb1306.code)
    ) ctloc
    LEFT JOIN (
        SELECT __changeindex, code, name, rowkey, depttypeid, id,
               ROW_NUMBER() OVER(PARTITION BY code ORDER BY __changeindex DESC) AS rtn
        FROM md.tbl_1305_h 
        WHERE __dictionary_id = (SELECT MAX(__dictionary_id) FROM md.tbl_1305_h) AND isdeleted = '0'
        GROUP BY __changeindex, code, name, rowkey, depttypeid, id
    ) ygloc ON ygloc.rowkey = ctloc.ygks
    WHERE ygloc.rtn = 1
),

-- 1.6 医院院区字典(非HID0101) - hcode
dict_hosp AS (
    SELECT DISTINCT
        sjyq.hoscode AS hosc,
        sjyq.threecode AS threec,
        sjyq.threedesc AS threen,
        mapp.refname AS omthreen,
        mapp.refcode AS omthreec
    FROM md.tbl_1308_h sjyq
    LEFT JOIN md.mappingmember mapp ON mapp.code = sjyq.code
    WHERE sjyq.hoscode <> 'HID0101'
),

-- =====================================================
-- STEP 2: 源数据提取
-- =====================================================
source_data AS (
    SELECT
        CAST(UUID() AS STRING) AS uuid,
        CAST(NULL AS STRING) AS medorgid,
        CAST(visit_record_medorgcode AS STRING) AS medorgcode,
        CAST(visit_record_medorgname AS STRING) AS medorgname,
        CAST(NULL AS STRING) AS empiid,
        CAST(NULL AS STRING) AS empino,
        CAST(visit_record_persid AS STRING) AS persid,
        CAST(visit_record_persno AS STRING) AS persno,
        CAST(visit_record_extstr3 AS STRING) AS visitid,
        CAST(visit_record_visitno AS STRING) AS visitno,
        CAST(NULL AS STRING) AS serialno,
        CAST(visit_record_persname AS STRING) AS persname,
        CAST(NOW() AS DATE) AS beinhospdate,
        CAST(DATE_FORMAT(NOW(), 'yyyy-MM-dd') AS STRING) AS repdate,
        CAST(DATE_FORMAT(NOW(), 'HH:mm:ss') AS STRING) AS reptime,
        CAST(DATE_FORMAT(NOW(), 'yyyy-MM-dd HH:mm:ss') AS STRING) AS repdttm,
        CAST(DATE_FORMAT(NOW(), 'HH') AS STRING) AS rephour,
        CAST('1' AS STRING) AS newest,
        CAST(visit_record_visitbedid AS STRING) AS bednoid,
        CAST(visit_record_visitbedcode AS STRING) AS bedno,
        CAST(visit_record_visitdttm AS STRING) AS inhospdate,
        CAST(NULL AS STRING) AS inhospwardid,
        CAST(NULL AS STRING) AS inhospwardcode,
        CAST(NULL AS STRING) AS inhospwardname,
        CAST(NULL AS STRING) AS inhospmedelementid,
        CAST(NULL AS STRING) AS inhospmedelementcode,
        CAST(NULL AS STRING) AS inhospmedelementname,
        CAST(visit_record_visitwardid AS STRING) AS currentwardid,
        CAST(visit_record_visitwardcode AS STRING) AS currentwardcode,
        CAST(visit_record_visitwardname AS STRING) AS currentwardname,
        CAST(visit_record_visitdeptid AS STRING) AS currentmedelementid,
        CAST(visit_record_visitdeptcode AS STRING) AS currentmedelementcode,
        CAST(visit_record_visitdeptname AS STRING) AS currentmedelementname,
        CAST(visit_record_attendingdoctid AS STRING) AS currentstaffgroupid,
        CAST(visit_record_attendingdoctcode AS STRING) AS currentstaffgroupcode,
        CAST(visit_record_attendingdoctname AS STRING) AS currentstaffgroupname,
        CAST(CASE WHEN visit_record_visitbedcode IS NULL THEN 1 ELSE 0 END AS STRING) AS iswait,
        CAST(CASE WHEN visit_record_visitbedcode IS NOT NULL THEN 1 ELSE 0 END AS INT) AS beinhospperscount,
        CAST('datacenter_db' AS STRING) AS datasourceflag,
        CAST('visit_record' AS STRING) AS dstable,
        CAST('rowkey' AS STRING) AS indatasourcekey,
        CAST(rowkey AS STRING) AS indatasourcekeyvalue,
        CAST(visit_record_isdeleted AS STRING) AS isdelete,
        CAST(visit_record_lastupdatedttm AS STRING) AS lastupdatedttm,
        CAST(NOW() AS STRING) AS datacreatedttm,
        -- 用于字典关联的辅助字段
        CAST(NOW() AS STRING) AS outhospdate1
    FROM datacenter_db.visit_record
    WHERE visit_record_isdeleted = '0'
      AND visit_record_visitwardcode IS NOT NULL
      AND visit_record_visitrecordstatuscode = 'A'
      AND visit_record_visittypecode = 'I'
),

-- =====================================================
-- STEP 3: 关联字典表
-- =====================================================
joined_data AS (
    SELECT 
        src.*,
        -- 关联键
        src.currentmedelementcode || '||' || src.medorgcode AS locrowkey,
        src.currentmedelementcode || '||' || src.medorgcode AS locrowkey2,
        src.currentmedelementname || '||' || src.medorgcode AS zsrowkey,
        src.currentwardcode || '||' || src.medorgcode AS wardrowkey,
        -- 医院院区字典
        h.threec,
        h.threen,
        h.omthreec,
        h.omthreen,
        -- 护理单元院区字典
        dw.threecodeward,
        dw.threenameward,
        dw.omthreecodeward,
        dw.omthreenameward,
        -- 诊室院区字典
        dz.threecodezs,
        dz.threenamezs,
        dz.omthreecodezs,
        dz.omthreenamezs,
        -- 科室院区字典
        dl.threecodeloc,
        dl.threenameloc,
        dl.omthreecodeloc,
        dl.omthreenameloc,
        -- 运管科室(科室维度)
        loc.ygloccode,
        loc.yglocname,
        loc.yglocid,
        -- 运管科室(医生维度)
        doc.ygdocloccode,
        doc.ygdoclocname,
        doc.ygdoclocid
    FROM source_data src
    -- 关联医院院区字典
    LEFT JOIN dict_hosp h ON src.medorgcode = h.hosc
    -- 关联护理单元院区字典
    LEFT JOIN dict_ward_hosp dw ON (src.currentwardcode || '||' || src.medorgcode) = dw.wardrowkey
        AND src.outhospdate1 >= dw.hossdateward AND src.outhospdate1 <= dw.hosedateward
    -- 关联诊室院区字典
    LEFT JOIN dict_zs_hosp dz ON (src.currentmedelementname || '||' || src.medorgcode) = dz.zsrowkey
        AND src.outhospdate1 >= dz.hossdatezs AND src.outhospdate1 <= dz.hosedatezs
    -- 关联科室院区字典
    LEFT JOIN dict_loc_hosp dl ON (src.currentmedelementcode || '||' || src.medorgcode) = dl.locrowkey2
        AND src.outhospdate1 >= dl.hossdateloc AND src.outhospdate1 <= dl.hosedateloc
    -- 关联运管科室(科室维度)
    LEFT JOIN dict_loc loc ON (src.currentmedelementcode || '||' || src.medorgcode) = loc.locrowkey
        AND src.outhospdate1 >= loc.locssdate AND src.outhospdate1 <= loc.locedate
    -- 关联运管科室(医生维度)
    LEFT JOIN dict_doc doc ON src.currentstaffgroupcode = doc.doccode
        AND src.outhospdate1 >= doc.docssdate AND src.outhospdate1 <= doc.docedate
),

-- =====================================================
-- STEP 4: 计算运管院区和运管科室
-- =====================================================
computed_data AS (
    SELECT 
        uuid, medorgid, medorgcode, medorgname, empiid, empino,
        persid, persno, visitid, visitno, serialno, persname,
        beinhospdate, repdate, reptime, repdttm, rephour, newest,
        bednoid, bedno, inhospdate,
        inhospwardid, inhospwardcode, inhospwardname,
        inhospmedelementid, inhospmedelementcode, inhospmedelementname,
        currentwardid, currentwardcode, currentwardname,
        currentmedelementid, currentmedelementcode, currentmedelementname,
        currentstaffgroupid, currentstaffgroupcode, currentstaffgroupname,
        iswait, beinhospperscount, datasourceflag, dstable,
        indatasourcekey, indatasourcekeyvalue, isdelete, lastupdatedttm, datacreatedttm,
        
        -- 三级院区编码 (hostype='ward'逻辑: 非HID0101用医院字典，HID0101用护理单元字典)
        CASE 
            WHEN medorgcode <> 'HID0101' THEN threec
            ELSE threecodeward
        END AS threecode_calc,
        
        -- 三级院区名称
        CASE 
            WHEN medorgcode <> 'HID0101' THEN threen
            ELSE threenameward
        END AS threename_calc,
        
        -- 运管院区编码
        CASE 
            WHEN medorgcode <> 'HID0101' THEN omthreec
            ELSE omthreecodeward
        END AS omthreecode_calc,
        
        -- 运管院区名称
        CASE 
            WHEN medorgcode <> 'HID0101' THEN omthreen
            ELSE omthreenameward
        END AS omthreename_calc,
        
        -- 运管科室编码 (loctype='doc+loc'逻辑: 优先用医生，其次用科室)
        CASE 
            WHEN ygdocloccode IS NOT NULL THEN ygdocloccode
            WHEN ygloccode IS NOT NULL THEN ygloccode
            WHEN currentmedelementcode IS NULL THEN '998'
            WHEN currentstaffgroupcode IS NULL THEN '996'
            ELSE '997'
        END AS omdeptcode_calc,
        
        -- 运管科室名称
        CASE 
            WHEN ygdocloccode IS NOT NULL THEN ygdoclocname
            WHEN ygloccode IS NOT NULL THEN yglocname
            WHEN currentmedelementcode IS NULL THEN '七级科室空值'
            WHEN currentstaffgroupcode IS NULL THEN '医疗组长空值'
            ELSE '运管科室待归'
        END AS omdeptdesc_calc,
        
        -- 运管科室ID
        CASE 
            WHEN ygdocloccode IS NOT NULL THEN ygdoclocid
            WHEN ygloccode IS NOT NULL THEN yglocid
            WHEN currentmedelementcode IS NULL THEN '87'
            WHEN currentstaffgroupcode IS NULL THEN '89'
            ELSE '88'
        END AS omdeptid_calc
        
    FROM joined_data
)

-- =====================================================
-- STEP 5: 最终输出 (带默认值处理)
-- =====================================================
SELECT
    CAST(uuid AS STRING) AS uuid,
    CAST(medorgid AS STRING) AS medorgid,
    CAST(medorgcode AS STRING) AS medorgcode,
    CAST(medorgname AS STRING) AS medorgname,
    CAST(empiid AS STRING) AS empiid,
    CAST(empino AS STRING) AS empino,
    CAST(persid AS STRING) AS persid,
    CAST(persno AS STRING) AS persno,
    CAST(visitid AS STRING) AS visitid,
    CAST(visitno AS STRING) AS visitno,
    CAST(serialno AS STRING) AS serialno,
    CAST(persname AS STRING) AS persname,
    CAST(beinhospdate AS DATE) AS beinhospdate,
    CAST(repdate AS STRING) AS repdate,
    CAST(reptime AS STRING) AS reptime,
    CAST(repdttm AS STRING) AS repdttm,
    CAST(rephour AS STRING) AS rephour,
    CAST(newest AS STRING) AS newest,
    CAST(bednoid AS STRING) AS bednoid,
    CAST(bedno AS STRING) AS bedno,
    CAST(inhospdate AS STRING) AS inhospdate,
    CAST(inhospwardid AS STRING) AS inhospwardid,
    CAST(inhospwardcode AS STRING) AS inhospwardcode,
    CAST(inhospwardname AS STRING) AS inhospwardname,
    CAST(inhospmedelementid AS STRING) AS inhospmedelementid,
    CAST(inhospmedelementcode AS STRING) AS inhospmedelementcode,
    CAST(inhospmedelementname AS STRING) AS inhospmedelementname,
    CAST(currentwardid AS STRING) AS currentwardid,
    CAST(currentwardcode AS STRING) AS currentwardcode,
    CAST(currentwardname AS STRING) AS currentwardname,
    CAST(currentmedelementid AS STRING) AS currentmedelementid,
    CAST(currentmedelementcode AS STRING) AS currentmedelementcode,
    CAST(currentmedelementname AS STRING) AS currentmedelementname,
    CAST(currentstaffgroupid AS STRING) AS currentstaffgroupid,
    CAST(currentstaffgroupcode AS STRING) AS currentstaffgroupcode,
    CAST(currentstaffgroupname AS STRING) AS currentstaffgroupname,
    CAST(iswait AS STRING) AS iswait,
    CAST(beinhospperscount AS INT) AS beinhospperscount,
    CAST(datasourceflag AS STRING) AS datasourceflag,
    CAST(dstable AS STRING) AS dstable,
    CAST(indatasourcekey AS STRING) AS indatasourcekey,
    CAST(indatasourcekeyvalue AS STRING) AS indatasourcekeyvalue,
    CAST(isdelete AS STRING) AS isdelete,
    CAST(lastupdatedttm AS STRING) AS lastupdatedttm,
    CAST(datacreatedttm AS STRING) AS datacreatedttm,
    -- 三级院区（带默认值）
    CAST(COALESCE(threecode_calc, 'YGF9998') AS STRING) AS threecode,
    CAST(COALESCE(threename_calc, '三级院区待归') AS STRING) AS threename,
    -- 运管院区（带默认值）
    CAST(COALESCE(omthreecode_calc, 'YGF9997') AS STRING) AS omthreecode,
    CAST(COALESCE(omthreename_calc, '运管三级院区待归') AS STRING) AS omthreename,
    -- 运管科室（带默认值）
    CAST(COALESCE(omdeptid_calc, '88') AS STRING) AS omdeptid,
    CAST(COALESCE(omdeptcode_calc, '997') AS STRING) AS omdeptcode,
    CAST(COALESCE(omdeptdesc_calc, '运管科室待归') AS STRING) AS omdeptdesc
FROM computed_data;


-- =====================================================
-- 写入目标表 (INSERT OVERWRITE 模式)
-- =====================================================
-- INSERT OVERWRITE TABLE m1.mdr_beinhosp PARTITION(repdate, rephour)
-- SELECT ... FROM computed_data;
