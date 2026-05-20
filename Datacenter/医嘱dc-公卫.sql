医嘱dc-公卫


/*DC集成华上天夏医嘱明细
251016更新内容:order_main_datacreatedttm字段取值由原来获取当前时间改为集成的数据到DC的order_main表中查找数据，如果有数据则取已有的时间，如果没有则取当前时间
251028更新内容：①提取获取ETL增量时间为临时表；②将DL的删除数据与未删除数据分开集成，未删除数据按原来的逻辑集成，删除数据从DC取数据
251031更新内容：因为获取数据老是超内存，所有获取删除数据由关联查询调整为子查询
260520更新内容：①新增开单人科室3列(order_main_orderuserdept_code/id/name)，通过OEORI_UserDepartment_DR关联CT_Loc取；②病区3列(order_main_wardcode/wardid/wardname)去掉CTLOC_Type='W'/'EM'限制，直接取WardCTLoc字段；HID0122/HID0123两院区同步；DL删除兜底union暂以NULL占位3新列(DC schema扩展后改为直接SELECT)
*/
select
  a.order_main_abtusereason as order_main_abtusereason,
  a.order_main_applyid as order_main_applyid,
  a.order_main_applytypecode as order_main_applytypecode,
  a.order_main_applytypeid as order_main_applytypeid,
  a.order_main_applytypename as order_main_applytypename,
  a.order_main_basedrugflag as order_main_basedrugflag,
  a.order_main_basicunit as order_main_basicunit,
  a.order_main_basicunitratio as order_main_basicunitratio,
  a.order_main_canceldttm as order_main_canceldttm,
  a.order_main_cancelperscode as order_main_cancelperscode,
  a.order_main_cancelpersid as order_main_cancelpersid,
  a.order_main_cancelpersname as order_main_cancelpersname,
  a.order_main_checkdttm as order_main_checkdttm,
  a.order_main_checknurscode as order_main_checknurscode,
  a.order_main_checknursid as order_main_checknursid,
  a.order_main_checknursname as order_main_checknursname,
  a.order_main_checkperscode as order_main_checkperscode,
  a.order_main_checkpersid as order_main_checkpersid,
  a.order_main_checkpersname as order_main_checkpersname,
  a.order_main_datacreatedttm as order_main_datacreatedttm,
  a.order_main_datasourceflag as order_main_datasourceflag,
  a.order_main_dayonenum as order_main_dayonenum,
  a.order_main_deptcode as order_main_deptcode,
  a.order_main_deptid as order_main_deptid,
  a.order_main_deptname as order_main_deptname,
  a.order_main_dosingflag as order_main_dosingflag,
  a.order_main_doubtorderdesc as order_main_doubtorderdesc,
  a.order_main_doubtorderflag as order_main_doubtorderflag,
  a.order_main_drugcode as order_main_drugcode,
  a.order_main_drugdosageform as order_main_drugdosageform,
  a.order_main_drugdosageformid as order_main_drugdosageformid,
  a.order_main_drugid as order_main_drugid,
  a.order_main_drugmanageplatformcode as order_main_drugmanageplatformcode,
  a.order_main_drugname as order_main_drugname,
  a.order_main_drugpurchasecode as order_main_drugpurchasecode,
  a.order_main_drugspec as order_main_drugspec,
  a.order_main_dstable as order_main_dstable,
  a.order_main_dstablekey as order_main_dstablekey,
  a.order_main_dstablevalue as order_main_dstablevalue,
  a.order_main_empiid as order_main_empiid,
  a.order_main_empino as order_main_empino,
  a.order_main_enabledaynum as order_main_enabledaynum,
  a.order_main_entrust as order_main_entrust,
  a.order_main_entryreason as order_main_entryreason,
  a.order_main_estimatedtotalprice as order_main_estimatedtotalprice,
  a.order_main_excessreason as order_main_excessreason,
  a.order_main_execdttm as order_main_execdttm,
  a.order_main_execperscode as order_main_execperscode,
  a.order_main_execpersid as order_main_execpersid,
  a.order_main_execpersname as order_main_execpersname,
  a.order_main_extdate1 as order_main_extdate1,
  a.order_main_extdate2 as order_main_extdate2,
  a.order_main_extnum1 as order_main_extnum1,
  a.order_main_extnum2 as order_main_extnum2,
  a.order_main_extstr1 as order_main_extstr1,
  a.order_main_extstr2 as order_main_extstr2,
  a.order_main_extstr3 as order_main_extstr3,
  a.order_main_extstr4 as order_main_extstr4,
  a.order_main_extstr5 as order_main_extstr5,
  a.order_main_extstr6 as order_main_extstr6,
  a.order_main_giveadaptationdisease as order_main_giveadaptationdisease,
  a.order_main_givefreqcode as order_main_givefreqcode,
  a.order_main_givefreqid as order_main_givefreqid,
  a.order_main_givefreqname as order_main_givefreqname,
  a.order_main_giverateunit as order_main_giverateunit,
  a.order_main_giveratevalue as order_main_giveratevalue,
  a.order_main_givestrength as order_main_givestrength,
  a.order_main_givestrengthunit as order_main_givestrengthunit,
  a.order_main_herbclasscode as order_main_herbclasscode,
  a.order_main_herbclassid as order_main_herbclassid,
  a.order_main_herbclassname as order_main_herbclassname,
  a.order_main_herbdecoctioncode as order_main_herbdecoctioncode,
  a.order_main_herbdecoctionid as order_main_herbdecoctionid,
  a.order_main_herbdecoctionname as order_main_herbdecoctionname,
  a.order_main_incisiontypecode as order_main_incisiontypecode,
  a.order_main_incisiontypeid as order_main_incisiontypeid,
  a.order_main_incisiontypename as order_main_incisiontypename,
  a.order_main_insuflag as order_main_insuflag,
  a.order_main_isdeleted as order_main_isdeleted,
  a.order_main_lastupdatedttm as order_main_lastupdatedttm,
  a.order_main_longorderrelationid as order_main_longorderrelationid,
  a.order_main_maindrug as order_main_maindrug,
  a.order_main_mainorderno as order_main_mainorderno,
  a.order_main_materialsbarcode as order_main_materialsbarcode,
  a.order_main_medorgcode as order_main_medorgcode,
  a.order_main_medorgname as order_main_medorgname,
  a.order_main_opspecialdiseasecode as order_main_opspecialdiseasecode,
  a.order_main_opspecialdiseaseflag as order_main_opspecialdiseaseflag,
  a.order_main_opspecialdiseaseid as order_main_opspecialdiseaseid,
  a.order_main_opspecialdiseasename as order_main_opspecialdiseasename,
  a.order_main_orderbegindttm as order_main_orderbegindttm,
  a.order_main_ordercontent as order_main_ordercontent,
  a.order_main_orderdetid as order_main_orderdetid,
  a.order_main_orderdoctcode as order_main_orderdoctcode,
  a.order_main_orderdoctid as order_main_orderdoctid,
  a.order_main_orderdoctname as order_main_orderdoctname,
  a.order_main_orderdttm as order_main_orderdttm,
  a.order_main_orderenddttm as order_main_orderenddttm,
  a.order_main_ordergroupno as order_main_ordergroupno,
  a.order_main_ordergroupsubno as order_main_ordergroupsubno,
  a.order_main_orderid as order_main_orderid,
  a.order_main_orderitemcode as order_main_orderitemcode,
  a.order_main_orderitemid as order_main_orderitemid,
  a.order_main_orderitemname as order_main_orderitemname,
  a.order_main_orderpclasscode as order_main_orderpclasscode,
  a.order_main_orderpclassid as order_main_orderpclassid,
  a.order_main_orderpclassname as order_main_orderpclassname,
  a.order_main_orderrelationno as order_main_orderrelationno,
  a.order_main_ordersclasscode as order_main_ordersclasscode,
  a.order_main_ordersclassid as order_main_ordersclassid,
  a.order_main_ordersclassname as order_main_ordersclassname,
  a.order_main_orderserialno as order_main_orderserialno,
  a.order_main_orderstagecode as order_main_orderstagecode,
  a.order_main_orderstageid as order_main_orderstageid,
  a.order_main_orderstagename as order_main_orderstagename,
  a.order_main_orderstatuscode as order_main_orderstatuscode,
  a.order_main_orderstatusid as order_main_orderstatusid,
  a.order_main_orderstatusname as order_main_orderstatusname,
  a.order_main_ordertypecode as order_main_ordertypecode,
  a.order_main_ordertypeid as order_main_ordertypeid,
  a.order_main_ordertypename as order_main_ordertypename,
  a.order_main_outhospdrugflag as order_main_outhospdrugflag,
  a.order_main_packageunit as order_main_packageunit,
  a.order_main_packageunitratio as order_main_packageunitratio,
  a.order_main_pathwaycode as order_main_pathwaycode,
  a.order_main_pathwayid as order_main_pathwayid,
  a.order_main_pathwayname as order_main_pathwayname,
  a.order_main_paystatuscode as order_main_paystatuscode,
  a.order_main_paystatusid as order_main_paystatusid,
  a.order_main_paystatusname as order_main_paystatusname,
  a.order_main_persid as order_main_persid,
  a.order_main_persno as order_main_persno,
  a.order_main_prescno as order_main_prescno,
  a.order_main_presctypecode as order_main_presctypecode,
  a.order_main_presctypeid as order_main_presctypeid,
  a.order_main_presctypename as order_main_presctypename,
  a.order_main_priority as order_main_priority,
  a.order_main_recdeptcode as order_main_recdeptcode,
  a.order_main_recdeptid as order_main_recdeptid,
  a.order_main_recdeptname as order_main_recdeptname,
  a.order_main_selfdrugflag as order_main_selfdrugflag,
  a.order_main_skintest as order_main_skintest,
  a.order_main_skintestmemo as order_main_skintestmemo,
  a.order_main_specimenid as order_main_specimenid,
  a.order_main_specimenname as order_main_specimenname,
  a.order_main_textorderproperty as order_main_textorderproperty,
  a.order_main_tisaneflag as order_main_tisaneflag,
  a.order_main_totalmeasure as order_main_totalmeasure,
  a.order_main_totalmeasureunit as order_main_totalmeasureunit,
  a.order_main_totalprice as order_main_totalprice,
  a.order_main_transfusionnum as order_main_transfusionnum,
  a.order_main_treatmentcode as order_main_treatmentcode,
  a.order_main_treatmentdesc as order_main_treatmentdesc,
  a.order_main_treatmentid as order_main_treatmentid,
  a.order_main_unitprice as order_main_unitprice,
  a.order_main_unitypurchaseplatformflag as order_main_unitypurchaseplatformflag,
  a.order_main_urgent as order_main_urgent,
  a.order_main_usage as order_main_usage,
  a.order_main_usedrugnum as order_main_usedrugnum,
  a.order_main_usedrugpurpose as order_main_usedrugpurpose,
  a.order_main_visitid as order_main_visitid,
  a.order_main_visitno as order_main_visitno,
  a.order_main_visittypecode as order_main_visittypecode,
  a.order_main_visittypeid as order_main_visittypeid,
  a.order_main_visittypename as order_main_visittypename,
  a.order_main_orderuserdept_code as order_main_orderuserdept_code,
  a.order_main_orderuserdept_id as order_main_orderuserdept_id,
  a.order_main_orderuserdept_name as order_main_orderuserdept_name,
  a.order_main_wardcode as order_main_wardcode,
  a.order_main_wardid as order_main_wardid,
  a.order_main_wardname as order_main_wardname,
  a.rowkey as rowkey
  from (
with t_ord_rowids as (
	select medorgcode,order_main_dstablevalue,order_main_datacreatedttm from datacenter_db.order_main
),t_incr_time as ( /*用于过滤出增量数据*/
	select coalesce(
	(select replace(replace(replace(replace(cast(date_add('minute', -5, log_summary_start) as varchar),'-',''),':',''),' ',''),'.','')
	from etl_master.etl_strategy.etl_logsummary /* 获取到的时间提前5分钟,这样可以减少5分钟内因数据依赖导致的问题 */ /* 当任务一次都没有执行成功过则默认当天,根据实际需要合理修改,避免不必要的数据更新 */
	where module_name = 'ETL_FACT_order_main_HID0101_1745307444170' and status = 2 /* 通过 ETL系统中的任务ID获取指定任务最后一次执行成功的任务开始时间 */
	order by log_summary_start desc limit 1),concat(cast(date_format(current_date, '%Y%m%d') as varchar),'000000000') ) as etl_time
)/*省公卫*/
  SELECT CAST
	( null AS VARCHAR ) AS order_main_abtusereason,
	CAST (
	CASE
			
			WHEN OECOrderCategory.ORCAT_Desc = '病理' THEN
			OEOrditem.OEORI_RowId 
			WHEN OECOrderCategory.ORCAT_Desc = '检查' THEN
			OEOrditem.OEORI_RowId 
			WHEN OECOrderCategory.ORCAT_Desc = '放射' THEN
			OEOrditem.OEORI_RowId 
			WHEN OECOrderCategory.ORCAT_Desc = '化验' THEN
			OEOrditem.OEORI_RowId 
			WHEN OECOrderCategory.ORCAT_Desc = '微生物化验' THEN
			OEOrditem.OEORI_RowId ELSE NULL 
	END AS VARCHAR 
	) AS order_main_applyid,
	CAST (
	CASE
			
			WHEN OECOrderCategory.ORCAT_Desc = '病理' THEN
			'检查' 
			WHEN OECOrderCategory.ORCAT_Desc = '检查' THEN
			'检查' 
			WHEN OECOrderCategory.ORCAT_Desc = '放射' THEN
			'检查' 
			WHEN OECOrderCategory.ORCAT_Desc = '化验' THEN
			'检验' 
			WHEN OECOrderCategory.ORCAT_Desc = '微生物化验' THEN
			'检验' ELSE NULL 
	END AS VARCHAR 
	) AS order_main_applytypecode,
	CAST ( NULL AS VARCHAR ) AS order_main_applytypeid,
	CAST (
	CASE
			
			WHEN OECOrderCategory.ORCAT_Desc = '病理' THEN
			'检查' 
			WHEN OECOrderCategory.ORCAT_Desc = '检查' THEN
			'检查' 
			WHEN OECOrderCategory.ORCAT_Desc = '放射' THEN
			'检查' 
			WHEN OECOrderCategory.ORCAT_Desc = '化验' THEN
			'检验' 
			WHEN OECOrderCategory.ORCAT_Desc = '微生物化验' THEN
			'检验' ELSE NULL 
	END AS VARCHAR 
	) AS order_main_applytypename,
	CAST ( DHCItmAddionInfo.INFO_BasicDrug AS VARCHAR ) AS order_main_basedrugflag,
	CAST ( BasicCTUom.CTUOM_Desc AS VARCHAR ) AS order_main_basicunit,
	CAST ( PHCFormDoseEquiv.EQ_Qty AS VARCHAR ) AS order_main_basicunitratio,
	CAST (
	CASE
			
			WHEN OECOrderStatus.OSTAT_Code = 'C' THEN
			concat ( OEOrdItem.OEORI_Xdate, ' ', COALESCE ( OEOrdItem.OEORI_XTIME, '00:00:00' ) ) ELSE NULL 
	END AS VARCHAR 
	) AS order_main_canceldttm,
	CAST ( XCTCPCTCareProv.CTPCP_Code AS VARCHAR ) AS order_main_cancelperscode,
	CAST ( OEOrdItem.OEORI_XCTCP_DR AS VARCHAR ) AS order_main_cancelpersid,
	CAST ( XCTCPCTCareProv.CTPCP_Desc AS VARCHAR ) AS order_main_cancelpersname,
	CAST ( null AS VARCHAR ) AS order_main_checkdttm,
	CAST ( NULL AS VARCHAR ) AS order_main_checknurscode,
	CAST ( NULL AS VARCHAR ) AS order_main_checknursid,
	CAST ( NULL AS VARCHAR ) AS order_main_checknursname,
	CAST ( NULL AS VARCHAR ) AS order_main_checkperscode,
	CAST ( null AS VARCHAR ) AS order_main_checkpersid,
	CAST ( null AS VARCHAR ) AS order_main_checkpersname,
	COALESCE(t_ord_rowids.order_main_datacreatedttm,cast(CURRENT_TIMESTAMP as varchar)) AS order_main_datacreatedttm,
	CAST ( '155' AS VARCHAR ) AS order_main_datasourceflag,
	CAST ( OEOrdItem.OEORI_Qty AS VARCHAR ) AS order_main_dayonenum,
	CAST ( DocCTLoc.CTLOC_Code AS VARCHAR ) AS order_main_deptcode,
	CAST ( OEOrdItem.OEORI_OrdDept_DR AS VARCHAR ) AS order_main_deptid,
	CAST ( DocCTLoc.CTLOC_Desc AS VARCHAR ) AS order_main_deptname,
	CAST ( OEOrdItemExt.OEORI_NeedPIVAFlag AS VARCHAR ) AS order_main_dosingflag,
	CAST ( null AS VARCHAR ) AS order_main_doubtorderdesc,
	CAST ( null AS VARCHAR ) AS order_main_doubtorderflag,
	CAST ( PHCDrgMast.PHCD_Code AS VARCHAR ) AS order_main_drugcode,
	CAST ( PHCForm.PHCF_Desc AS VARCHAR ) AS order_main_drugdosageform,
	CAST ( PHCDrgForm.PHCDF_PHCF_DR AS VARCHAR ) AS order_main_drugdosageformid,
	CAST ( PHCDrgForm.PHCDF_PHCD_ParRef AS VARCHAR ) AS order_main_drugid,
	CAST ( NULL AS VARCHAR ) AS order_main_drugmanageplatformcode,
	CAST ( PHCDrgMast.PHCD_Name AS VARCHAR ) AS order_main_drugname,
	CAST ( NULL AS VARCHAR ) AS order_main_drugpurchasecode,
	CAST ( DHCItmAddionInfo.INFO_Spec AS VARCHAR ) AS order_main_drugspec,
	CAST ( 'hid0122_cache_his_dhcapp_sqluser.OE_Orditem' AS VARCHAR ) AS order_main_dstable,
	CAST ( 'OEORI_RowId' AS VARCHAR ) AS order_main_dstablekey,
	CAST ( OEOrditem.OEORI_RowId AS VARCHAR ) AS order_main_dstablevalue,
	CAST ( NULL AS VARCHAR ) AS order_main_empiid,
	CAST ( NULL AS VARCHAR ) AS order_main_empino,
	CAST ( OEOrdItemExt.OEORI_UsableDays AS VARCHAR ) AS order_main_enabledaynum,
	CAST ( TRIM ( OEOrdItem.OEORI_DepProcNotes ) AS VARCHAR ) AS order_main_entrust,
	CAST ( null AS VARCHAR ) AS order_main_entryreason,
	CAST ( OEOrdItem.OEORI_Cost AS VARCHAR ) AS order_main_estimatedtotalprice,
	CAST ( DHCDocExceedReason.DHCExceed_Desc AS VARCHAR ) AS order_main_excessreason,
	CAST ( concat ( OEOrdItem.OEORI_DateExecuted, ' ', COALESCE ( OEOrdItem.OEORI_TimeExecuted, '00:00:00' ) ) AS VARCHAR ) AS order_main_execdttm,
	CAST ( SSUser.SSUSR_Initials AS VARCHAR ) AS order_main_execperscode,
	CAST ( OEOrditem.OEORI_UserExecuted AS VARCHAR ) AS order_main_execpersid,
	CAST ( SSUser.SSUSR_Name AS VARCHAR ) AS order_main_execpersname,
	CAST ( NULL AS VARCHAR ) AS order_main_extdate1,
	CAST ( NULL AS VARCHAR ) AS order_main_extdate2,
	CAST ( NULL AS VARCHAR ) AS order_main_extnum1,
	CAST ( NULL AS VARCHAR ) AS order_main_extnum2,
	CAST ( NULL AS VARCHAR ) AS order_main_extstr1,
	CAST ( NULL AS VARCHAR ) AS order_main_extstr2,
	CAST ( OEOrder.OEORD_Adm_DR AS VARCHAR ) AS order_main_extstr3,
	CAST ( NULL AS VARCHAR ) AS order_main_extstr4,
	CAST ( NULL AS VARCHAR ) AS order_main_extstr5,
	CAST ( NULL AS VARCHAR ) AS order_main_extstr6,
	CAST ( PHCDrgForm.PHCDF_Indication AS VARCHAR ) AS order_main_giveadaptationdisease,
	CAST ( PHCFreq.PHCFR_Code AS VARCHAR ) AS order_main_givefreqcode,
	CAST ( OEOrdItem.OEORI_PHFreq_DR AS VARCHAR ) AS order_main_givefreqid,
	CAST ( PHCFreq.PHCFR_Desc1 AS VARCHAR ) AS order_main_givefreqname,
	CAST ( NULL AS VARCHAR ) AS order_main_giverateunit,
	CAST ( OEOrdItem.OEORI_SpeedFlowRate AS VARCHAR ) AS order_main_giveratevalue,
	CAST ( TRIM ( OEOrdItem.OEORI_DoseQty ) AS VARCHAR ) AS order_main_givestrength,
	CAST ( DoseCTUOM.CTUOM_Desc AS VARCHAR ) AS order_main_givestrengthunit,
	CAST ( NULL AS VARCHAR ) AS order_main_herbclasscode,
	CAST ( NULL AS VARCHAR ) AS order_main_herbclassid,
	CAST ( NULL AS VARCHAR ) AS order_main_herbclassname,
	CAST ( NULL AS VARCHAR ) AS order_main_herbdecoctioncode,
	CAST ( NULL AS VARCHAR ) AS order_main_herbdecoctionid,
	CAST ( NULL AS VARCHAR ) AS order_main_herbdecoctionname,
	CAST ( NULL AS VARCHAR ) AS order_main_incisiontypecode,
	CAST ( NULL AS VARCHAR ) AS order_main_incisiontypeid,
	CAST ( null AS VARCHAR ) AS order_main_incisiontypename,
	CAST ( OEOrditem.OEORI_CoverMainIns AS VARCHAR ) AS order_main_insuflag,
	CAST ( OEOrdItem.isdeleted AS VARCHAR ) AS order_main_isdeleted,
	CURRENT_TIMESTAMP AS order_main_lastupdatedttm,
	CAST ( OEOrdItem.OEORI_FillerNo AS VARCHAR ) AS order_main_longorderrelationid,
	CAST ( NULL AS VARCHAR ) AS order_main_maindrug,
	CAST ( OEOrdItem.OEORI_OEORI_DR AS VARCHAR ) AS order_main_mainorderno,
	CAST ( OEOrdItemExt.OEORI_MaterialNo AS VARCHAR ) AS order_main_materialsbarcode,
	CAST ( 'HID0122' AS VARCHAR ) AS order_main_medorgcode,
	CAST ( '四川大学华西医院锦城医院(四川省公共综合临床中心)' AS VARCHAR ) AS order_main_medorgname,
	CAST (null AS VARCHAR ) AS order_main_opspecialdiseasecode,
	CAST ( null AS VARCHAR ) AS order_main_opspecialdiseaseflag,
	CAST ( null AS VARCHAR ) AS order_main_opspecialdiseaseid,
	CAST ( null AS VARCHAR ) AS order_main_opspecialdiseasename,
	CAST ( concat ( OEOrdItem.OEORI_SttDat, ' ', OEOrdItem.OEORI_SttTim ) AS VARCHAR ) AS order_main_orderbegindttm,
	CAST ( NULL AS VARCHAR ) AS order_main_ordercontent,
	CAST ( OEOrdItem.OEORI_Childsub AS VARCHAR ) AS order_main_orderdetid,
	CAST ( DocCTCareProv.CTPCP_Code AS VARCHAR ) AS order_main_orderdoctcode,
	CAST ( OEOrdItem.OEORI_Doctor_DR AS VARCHAR ) AS order_main_orderdoctid,
	CAST ( DocCTCareProv.CTPCP_Desc AS VARCHAR ) AS order_main_orderdoctname,
	CAST ( concat ( OEOrdItem.OEORI_Date, ' ', OEOrdItem.OEORI_TimeOrd ) AS VARCHAR ) AS order_main_orderdttm,
	CAST (
	CASE
			
			WHEN OECOrderStatus.OSTAT_Code = 'D' THEN
			concat ( OEOrdItem.OEORI_Xdate, ' ', COALESCE ( OEOrdItem.OEORI_XTIME, '00:00:00' ) ) ELSE NULL 
	END AS VARCHAR 
	) AS order_main_orderenddttm,
	CAST ( OEOrdItem.OEORI_ARCOS_DR AS VARCHAR ) AS order_main_ordergroupno,
	CAST ( ARCOrdSetDateItem.ITM_Childsub AS VARCHAR ) AS order_main_ordergroupsubno,
	CAST ( OEOrdItem.OEORI_OEORD_ParRef AS VARCHAR ) AS order_main_orderid,
	CAST ( ARCItmMast.ARCIM_Code AS VARCHAR ) AS order_main_orderitemcode,
	CAST ( OEOrditem.OEORI_ItmMast_DR AS VARCHAR ) AS order_main_orderitemid,
	CAST ( ARCItmMast.ARCIM_Desc AS VARCHAR ) AS order_main_orderitemname,
	CAST ( OECOrderCategory.ORCAT_Code AS VARCHAR ) AS order_main_orderpclasscode,
	CAST ( ARCItemCat.ARCIC_OrdCat_DR AS VARCHAR ) AS order_main_orderpclassid,
	CAST ( OECOrderCategory.ORCAT_Desc AS VARCHAR ) AS order_main_orderpclassname,
	CAST ( OEOrdItem.OEORI_SeqNo AS VARCHAR ) AS order_main_orderrelationno,
	CAST ( ARCItemCat.ARCIC_Code AS VARCHAR ) AS order_main_ordersclasscode,
	CAST ( ARCItmMast.ARCIM_ItemCat_DR AS VARCHAR ) AS order_main_ordersclassid,
	CAST ( ARCItemCat.ARCIC_Desc AS VARCHAR ) AS order_main_ordersclassname,
	CAST ( OEOrditem.OEORI_RowId AS VARCHAR ) AS order_main_orderserialno,
	CAST ( OEOrdItemExt.OEORI_Stage AS VARCHAR ) AS order_main_orderstagecode,
	CAST ( NULL AS VARCHAR ) AS order_main_orderstageid,
	CAST ( CASE OEOrdItemExt.OEORI_Stage WHEN 'SQ' THEN '术前' WHEN 'SZ' THEN '术中' WHEN 'SH' THEN '术后' ELSE OEOrdItemExt.OEORI_Stage END AS VARCHAR ) AS order_main_orderstagename,
	CAST ( OECOrderStatus.OSTAT_Code AS VARCHAR ) AS order_main_orderstatuscode,
	CAST ( OEOrditem.OEORI_ItemStat_DR AS VARCHAR ) AS order_main_orderstatusid,
	CAST ( OECOrderStatus.OSTAT_Desc AS VARCHAR ) AS order_main_orderstatusname,
	CAST ( OECPriority.OECPR_Code AS VARCHAR ) AS order_main_ordertypecode,
	CAST ( OEOrditem.OEORI_Priority_DR AS VARCHAR ) AS order_main_ordertypeid,
	CAST ( OECPriority.OECPR_Desc AS VARCHAR ) AS order_main_ordertypename,
	CAST ( CASE WHEN OECPriority.OECPR_Desc = '出院带药' THEN 'Y' ELSE'N' END AS VARCHAR ) AS order_main_outhospdrugflag,
	CAST ( CASE WHEN PHCDrgMast.PHCD_Code IS NOT NULL THEN PurchCTUOM.CTUOM_Desc ELSE NULL END AS VARCHAR ) AS order_main_packageunit,
	CAST ( CTConFac.CTCF_Factor AS VARCHAR ) AS order_main_packageunitratio,
	CAST ( PHCInstruc.PHCIN_Code AS VARCHAR ) AS order_main_pathwaycode,
	CAST ( OEOrdItem.OEORI_Instr_DR AS VARCHAR ) AS order_main_pathwayid,
	CAST ( PHCInstruc.PHCIN_Desc1 AS VARCHAR ) AS order_main_pathwayname,
	CAST ( OEOrdItem.OEORI_Billed AS VARCHAR ) AS order_main_paystatuscode,
	CAST ( NULL AS VARCHAR ) AS order_main_paystatusid,
	CAST ( NULL AS VARCHAR ) AS order_main_paystatusname,
	CAST ( COALESCE ( PAAdm.PAADM_PAPMI_DR, '-1' ) AS VARCHAR ) AS order_main_persid,
	CAST ( COALESCE ( PAPatmas.PAPMI_OPNo, PAPatmas.PAPMI_IPNo ) AS VARCHAR ) AS order_main_persno,
	CAST ( OEOrdItem.OEORI_PrescNo AS VARCHAR ) AS order_main_prescno,
	CAST ( NULL AS VARCHAR ) AS order_main_presctypecode,
	CAST ( NULL AS VARCHAR ) AS order_main_presctypeid,
	CAST (
	IF
		(
			CAST ( CASE WHEN OEOrdItem.OEORI_PrescNo IS NOT NULL THEN TRUE ELSE FALSE END AS BOOLEAN ),
			CAST (
			CASE
					
					WHEN PHCPoison.PHCPO_Desc IS NOT NULL THEN
					CONCAT ( PHCPoison.PHCPO_Desc, '处方' ) 
					WHEN PAAdm.PAADM_Type = 'E' THEN
					'急诊处方' 
					WHEN date_diff (
						'day',
						CAST (
						CASE
								
								WHEN PAPatmas.PAPMI_DOB IS NOT NULL 
								AND LENGTH ( PAPatmas.PAPMI_DOB ) < 18 THEN
									CONCAT ( PAPatmas.PAPMI_DOB, ' 01:00:00' ) ELSE PAPatmas.PAPMI_DOB 
								END AS TIMESTAMP 
							),
							CAST (
							CASE
									
									WHEN PAAdm.PAADM_AdmDate IS NOT NULL 
									AND LENGTH ( PAAdm.PAADM_AdmDate ) < 18 THEN
										CONCAT ( PAAdm.PAADM_AdmDate, ' 00:00:00' ) ELSE PAAdm.PAADM_AdmDate 
									END AS TIMESTAMP 
								) 
								) / 365.25 < 15 THEN
								'儿童处方' ELSE'普通处方' 
						END AS VARCHAR 
						),
					NULL 
					) AS VARCHAR 
				) AS order_main_presctypename,
				CAST ( OECPriority.OECPR_Desc AS VARCHAR ) AS order_main_priority,
				CAST ( RecCTLoc.CTLOC_Code AS VARCHAR ) AS order_main_recdeptcode,
				CAST ( OEOrdItem.OEORI_RecDep_DR AS VARCHAR ) AS order_main_recdeptid,
				CAST ( RecCTLoc.CTLOC_Desc AS VARCHAR ) AS order_main_recdeptname,
				CAST ( OEOrdItemExt.OEORI_SelfOMFlag AS VARCHAR ) AS order_main_selfdrugflag,
				CAST ( OEOrdItem.OEORI_AdministerSkinTest AS VARCHAR ) AS order_main_skintest,
				CAST ( OECAction.ACT_Desc AS VARCHAR ) AS order_main_skintestmemo,
				CAST ( null AS VARCHAR ) AS order_main_specimenid,
				CAST ( null AS VARCHAR ) AS order_main_specimenname,
				CAST ( NULL AS VARCHAR ) AS order_main_textorderproperty,
				CAST ( NULL AS VARCHAR ) AS order_main_tisaneflag,
				CAST (
				CASE
						
						WHEN ARCItemCat.ARCIC_OrderType <> 'R' THEN
						OEOrdItem.OEORI_PhQtyOrd ELSE
					CASE
							
							WHEN OEOrdItem.OEORI_QtyPackUOM IS NOT NULL THEN
							OEOrdItem.OEORI_QtyPackUOM 
							WHEN OEOrdItem.OEORI_PhQtyOrd IS NOT NULL THEN
							OEOrdItem.OEORI_PhQtyOrd ELSE NULL 
						END 
					END AS VARCHAR 
					) AS order_main_totalmeasure,
					CAST (
CASE WHEN ARCItemCat.ARCIC_OrderType <> 'R' AND OEOrdItem.OEORI_PhQtyOrd IS NOT NULL THEN PurchCTUOM.CTUOM_Desc 
	 WHEN ARCItemCat.ARCIC_OrderType = 'R' AND OEOrdItem.OEORI_QtyPackUOM IS NOT NULL THEN PurchCTUOM.CTUOM_Desc 
	 WHEN ARCItemCat.ARCIC_OrderType = 'R' AND OEOrdItem.OEORI_QtyPackUOM IS NULL AND OEOrdItem.OEORI_PhQtyOrd IS NOT NULL 
	 THEN DoseCTUOM.CTUOM_Desc ELSE NULL END AS VARCHAR) AS order_main_totalmeasureunit,
CAST ( OEOrdItem.OEORI_Cost AS VARCHAR ) AS order_main_totalprice,
CAST ( OEOrdItemExt.OEORI_LocalInfusionQty AS VARCHAR ) AS order_main_transfusionnum,
CAST ( PHCDuration.PHCDU_Code AS VARCHAR ) AS order_main_treatmentcode,
CAST ( PHCDuration.PHCDU_Desc1 AS VARCHAR ) AS order_main_treatmentdesc,
CAST ( OEOrditem.OEORI_Durat_DR AS VARCHAR ) AS order_main_treatmentid,
CAST ( OEOrdItem.OEORI_UnitCost AS VARCHAR ) AS order_main_unitprice,
CAST ( NULL AS VARCHAR ) AS order_main_unitypurchaseplatformflag,
CAST ( OEOrditem.OEORI_NotifyClinician AS VARCHAR ) AS order_main_urgent,
CAST ( PHCInstruc.PHCIN_Desc1 AS VARCHAR ) AS order_main_usage,
CAST ( CASE WHEN PHCDuration.PHCDU_Desc2 = '饮片' THEN PHCDuration.PHCDU_Factor ELSE NULL END AS VARCHAR ) AS order_main_usedrugnum,
CAST ( null AS VARCHAR ) AS order_main_usedrugpurpose,
CAST ( COALESCE ( mdm.visit_id, '-1' ) AS VARCHAR ) AS order_main_visitid,
CAST ( PAAdm.PAADM_ADMNo AS VARCHAR ) AS order_main_visitno,
CAST ( PAAdm.PAADM_Type AS VARCHAR ) AS order_main_visittypecode,
CAST ( PACEpisodeSubType.subt_rowid AS VARCHAR ) AS order_main_visittypeid,
CAST ( PACEpisodeSubType.SUBT_Desc AS VARCHAR ) AS order_main_visittypename,
CAST ( UserDeptCTLoc.CTLOC_Code AS VARCHAR ) AS order_main_orderuserdept_code,
CAST ( OEOrdItem.OEORI_UserDepartment_DR AS VARCHAR ) AS order_main_orderuserdept_id,
CAST ( UserDeptCTLoc.CTLOC_Desc AS VARCHAR ) AS order_main_orderuserdept_name,
CAST ( WardCTLoc.CTLOC_Code AS VARCHAR ) AS order_main_wardcode,
CAST ( WardCTLoc.CTLOC_RowID AS VARCHAR ) AS order_main_wardid,
CAST ( WardCTLoc.CTLOC_Desc AS VARCHAR ) AS order_main_wardname,
CAST ( concat ( '22_1_1_OE_OrdItem_', OEOrdItem.OEORI_RowId ) AS VARCHAR ) AS rowkey 
FROM
	(select * from hid0122_cache_his_dhcapp_sqluser.oe_orditem
	where _hoodie_commit_time>=(select etl_time from t_incr_time) and isdeleted='0') OEOrditem
LEFT JOIN ( SELECT OEORD_RowId1, OEORD_Adm_DR FROM hid0122_cache_his_dhcapp_sqluser.OE_Order )   OEOrder ON OEOrder.OEORD_RowId1 = OEOrdItem.OEORI_OEORD_ParRef
LEFT JOIN ( SELECT PAADM_RowID, PAADM_PAPMI_DR, PAADM_Type, PAADM_ADMNo, PAADM_AdmDate FROM hid0122_cache_his_dhcapp_sqluser.PA_Adm )   PAAdm ON PAAdm.PAADM_RowID = OEOrder.OEORD_Adm_DR
LEFT JOIN ( SELECT PAPMI_RowId1, PAPMI_OPNo, PAPMI_IPNo, PAPMI_DOB FROM hid0122_cache_his_dhcapp_sqluser.PA_Patmas )   PAPatmas ON PAPatmas.PAPMI_RowId1 = PAAdm.PAADM_PAPMI_DR
LEFT JOIN ( SELECT DATE_ParRef, DATE_RowId FROM hid0122_cache_his_dhcapp_sqluser.ARC_OrdSetDate )   ARCOrdSetDate ON ARCOrdSetDate.DATE_ParRef = OEOrdItem.OEORI_ARCOS_DR
LEFT JOIN (
SELECT
	ITM_ParRef,
	ITM_ARCIM_DR,
	ITM_Childsub,
	ROW_NUMBER ( ) OVER ( PARTITION BY ITM_ParRef, ITM_ARCIM_DR ORDER BY CAST ( ITM_Childsub as   BIGINT )   )   rownumber 
FROM
	hid0122_cache_his_dhcapp_sqluser.ARC_OrdSetDateItem 
)   ARCOrdSetDateItem ON ARCOrdSetDateItem.ITM_ParRef = ARCOrdSetDate.DATE_RowId 
AND ARCOrdSetDateItem.ITM_ARCIM_DR = OEOrditem.OEORI_ItmMast_DR 
AND ARCOrdSetDateItem.rownumber = 1
LEFT JOIN ( SELECT CTLOC_RowID, CTLOC_Code, CTLOC_Desc FROM hid0122_cache_his_dhcapp_sqluser.CT_Loc )   DocCTLoc ON DocCTLoc.CTLOC_RowID = OEOrdItem.OEORI_OrdDept_DR
LEFT JOIN ( SELECT CTLOC_RowID, CTLOC_Type, CTLOC_Code, CTLOC_Desc FROM hid0122_cache_his_dhcapp_sqluser.CT_Loc )   WardCTLoc ON WardCTLoc.CTLOC_RowID = OEOrdItem.OEORI_AdmLoc_DR
LEFT JOIN ( SELECT CTLOC_RowID, CTLOC_Code, CTLOC_Desc FROM hid0122_cache_his_dhcapp_sqluser.CT_Loc )   UserDeptCTLoc ON UserDeptCTLoc.CTLOC_RowID = OEOrdItem.OEORI_UserDepartment_DR
LEFT JOIN ( SELECT OECPR_RowId, OECPR_Code, OECPR_Desc FROM hid0122_cache_his_dhcapp_sqluser.OEC_Priority )   OECPriority ON OECPriority.OECPR_RowId = OEOrditem.OEORI_Priority_DR
LEFT JOIN ( SELECT ARCIM_RowId, ARCIM_Code, ARCIM_PHCDF_DR, ARCIM_BillingUOM_DR, ARCIM_Desc, ARCIM_ItemCat_DR FROM hid0122_cache_his_dhcapp_sqluser.ARC_ItmMast )   ARCItmMast ON ARCItmMast.ARCIM_RowId = OEOrditem.OEORI_ItmMast_DR
LEFT JOIN ( SELECT ARCIC_RowId, ARCIC_OrdCat_DR, ARCIC_Code, ARCIC_Desc, ARCIC_OrderType FROM hid0122_cache_his_dhcapp_sqluser.ARC_ItemCat )   ARCItemCat ON ARCItemCat.ARCIC_RowId = ARCItmMast.ARCIM_ItemCat_DR
LEFT JOIN ( SELECT ORCAT_RowId, ORCAT_Code, ORCAT_Desc FROM hid0122_cache_his_dhcapp_sqluser.OEC_OrderCategory )   OECOrderCategory ON OECOrderCategory.ORCAT_RowId = ARCItemCat.ARCIC_OrdCat_DR
LEFT JOIN ( SELECT OSTAT_RowId, OSTAT_Code, OSTAT_Desc FROM hid0122_cache_his_dhcapp_sqluser.OEC_OrderStatus )   OECOrderStatus ON OECOrderStatus.OSTAT_RowId = OEOrditem.OEORI_ItemStat_DR
LEFT JOIN ( SELECT INCI_RowId, INCI_OriginalARCIM_DR, INCI_Code FROM hid0122_cache_his_dhcapp_sqluser.INC_Itm )   INCItm ON INCItm.INCI_OriginalARCIM_DR = ARCItmMast.ARCIM_RowId 
AND INCItm.INCI_Code = ARCItmMast.ARCIM_Code
LEFT JOIN ( SELECT INFO_INCI_DR, INFO_BasicDrug, INFO_Spec FROM hid0122_cache_his_dhcapp_sqluser.DHC_ItmAddionInfo )   DHCItmAddionInfo ON DHCItmAddionInfo.INFO_INCI_DR = INCItm.INCI_RowId
LEFT JOIN ( SELECT CTUOM_RowId, CTUOM_Desc FROM hid0122_cache_his_dhcapp_sqluser.CT_UOM )   DoseCTUOM ON DoseCTUOM.CTUOM_RowId = OEOrdItem.OEORI_Unit_DR
LEFT JOIN ( SELECT PHCDF_RowId, PHCDF_PHCD_ParRef, PHCDF_CTUOM_DR, PHCDF_PHCF_DR, PHCDF_Indication FROM hid0122_cache_his_dhcapp_sqluser.PHC_DrgForm )   PHCDrgForm ON PHCDrgForm.PHCDF_RowId = ARCItmMast.ARCIM_PHCDF_DR
LEFT JOIN ( SELECT PHCD_RowId, PHCD_PHCPO_DR, PHCD_Code, PHCD_Name FROM hid0122_cache_his_dhcapp_sqluser.PHC_DrgMast )   PHCDrgMast ON PHCDrgMast.PHCD_RowId = PHCDrgForm.PHCDF_PHCD_ParRef
LEFT JOIN ( SELECT PHCF_RowID, PHCF_Desc FROM hid0122_cache_his_dhcapp_sqluser.PHC_Form )   PHCForm ON PHCForm.PHCF_RowID = PHCDrgForm.PHCDF_PHCF_DR
LEFT JOIN ( SELECT EQ_ParRef, EQ_CTUOM_DR, EQ_Qty FROM hid0122_cache_his_dhcapp_sqluser.PHC_FormDoseEquiv )   PHCFormDoseEquiv ON PHCFormDoseEquiv.EQ_ParRef = PHCDrgForm.PHCDF_RowID 
AND PHCFormDoseEquiv.EQ_CTUOM_DR = OEOrdItem.OEORI_Unit_DR
LEFT JOIN ( SELECT CTUOM_RowId, CTUOM_Desc FROM hid0122_cache_his_dhcapp_sqluser.CT_Uom )   BasicCTUom ON BasicCTUom.CTUOM_RowId = PHCDrgForm.PHCDF_CTUOM_DR
LEFT JOIN ( SELECT CTUOM_RowId, CTUOM_Desc FROM hid0122_cache_his_dhcapp_sqluser.CT_UOM )   PurchCTUOM ON PurchCTUOM.CTUOM_RowId = ARCItmMast.ARCIM_BillingUOM_DR
LEFT JOIN ( SELECT CTCF_ActiveFlag, CTCF_FrUOM_DR, CTCF_ToUOM_DR, CTCF_RowID, CTCF_Factor FROM hid0122_cache_his_dhcapp_sqluser.CT_ConFac )   CTConFac ON CTConFac.CTCF_ActiveFlag = 'Y' 
AND CTConFac.CTCF_FrUOM_DR = ARCItmMast.ARCIM_BillingUOM_DR 
AND CTConFac.CTCF_ToUOM_DR = PHCDrgForm.PHCDF_CTUOM_DR 
AND CTConFac.CTCF_RowID <> '102' 
AND CTConFac.CTCF_RowID <> '113'
LEFT JOIN ( SELECT PHCFR_RowId, PHCFR_Code, PHCFR_desc1 FROM hid0122_cache_his_dhcapp_sqluser.PHC_Freq )   PHCFreq ON PHCFreq.PHCFR_RowId = OEOrdItem.OEORI_PHFreq_DR
LEFT JOIN ( SELECT PHCIN_RowId, PHCIN_Code, PHCIN_desc1 FROM hid0122_cache_his_dhcapp_sqluser.PHC_Instruc )   PHCInstruc ON PHCInstruc.PHCIN_RowId = OEOrdItem.OEORI_Instr_DR
LEFT JOIN ( SELECT CTPCP_RowId1, CTPCP_Code, CTPCP_desc FROM hid0122_cache_his_dhcapp_sqluser.CT_CareProv )   DocCTCareProv ON DocCTCareProv.CTPCP_RowId1 = OEOrdItem.OEORI_Doctor_DR
LEFT JOIN ( SELECT CTPCP_RowId1, CTPCP_Code, CTPCP_desc FROM hid0122_cache_his_dhcapp_sqluser.CT_CareProv )   XCTCPCTCareProv ON XCTCPCTCareProv.CTPCP_RowId1 = OEOrdItem.OEORI_XCTCP_DR
LEFT JOIN ( SELECT CTLOC_RowID, CTLOC_Code, CTLOC_desc FROM hid0122_cache_his_dhcapp_sqluser.CT_Loc )   RecCTLoc ON RecCTLoc.CTLOC_RowID = OEOrdItem.OEORI_RecDep_DR
LEFT JOIN ( SELECT PHCDU_RowId, PHCDU_Code, PHCDU_Desc1, PHCDU_Desc2, PHCDU_Factor FROM hid0122_cache_his_dhcapp_sqluser.PHC_Duration )   PHCDuration ON PHCDuration.PHCDU_RowId = OEOrditem.OEORI_Durat_DR
-- LEFT JOIN ( SELECT orditemid, OrderFillReasonDR, CutTypeDR, OrderReasonDR FROM hid0122_cache_his_dhcapp_sqluser.HXAntiDrugInfo )   HXAntiDrugInfo ON HXAntiDrugInfo.orditemid = OEOrditem.OEORI_RowId
-- LEFT JOIN ( SELECT HX_ROWID, yka026 FROM hid0122_cache_his_dhcapp_sqluser.HX_DiseaseDicData )   HXDiseaseDicData ON HXDiseaseDicData.HX_ROWID = OEOrditem.OEORI_DRGOrder
-- LEFT JOIN ( SELECT ID, YDMT_DisCode FROM hid0122_cache_his_dhcapp_sqluser.YDMT_Disease )   YDMTDisease ON YDMTDisease.ID = OEOrditem.OEORI_DRGOrder
LEFT JOIN ( SELECT PHCPO_RowId, PHCPO_Desc FROM hid0122_cache_his_dhcapp_sqluser.PHC_Poison )   PHCPoison ON PHCPoison.PHCPO_RowId = PHCDrgMast.PHCD_PHCPO_DR
LEFT JOIN ( SELECT ACT_RowId, ACT_Desc FROM hid0122_cache_his_dhcapp_sqluser.OEC_Action )   OECAction ON OECAction.ACT_RowId = OEOrditem.OEORI_Action_DR
LEFT JOIN ( SELECT SPEC_ParRef, SPEC_Code FROM hid0122_cache_his_dhcapp_sqluser.OE_OrdSpecimen )   OEOrdSpecimen ON OEOrdSpecimen.SPEC_ParRef = OEOrditem.OEORI_RowId
-- JOIN ( SELECT RowID, Code, IName FROM hid0122_cache_his_dhcapp_sqluser.BT_Specimen )   BTSpecimen ON BTSpecimen.Code = OEOrdSpecimen.SPEC_Code
LEFT JOIN ( SELECT SSUSR_RowId, SSUSR_Initials, SSUSR_Name FROM hid0122_cache_his_dhcapp_sqluser.SS_User )   SSUser ON SSUser.SSUSR_RowId = OEOrditem.OEORI_UserExecuted
LEFT JOIN ( SELECT REA_RowId FROM hid0122_cache_his_dhcapp_sqluser.PAC_AdmReason )   BBExtPACAdmReason ON BBExtPACAdmReason.REA_RowId = OEOrditem.OEORI_BBExtCode
LEFT JOIN hid0122_cache_his_dhcapp_sqluser.OE_OrdItemExt   OEOrdItemExt ON OEOrdItemExt.OEORI_RowId = OEOrditem.OEORI_RowId
/*LEFT JOIN (
SELECT
	ABTP_SaveUser,
	ABTP_SaveDate,
	ABTP_SaveTime,
	ABTP_OeordItemID,
	ABTP_Temp1,
	ROW_NUMBER ( ) OVER ( PARTITION BY ABTP_OeordItemID ORDER BY CAST ( ABTP_Rowid   BIGINT ) DESC )   rownumber 
FROM
	hid0122_cache_his_dhcapp_sqluser.ABTPrescSignInfo 
)   ABTPrescSignInfo ON ABTPrescSignInfo.ABTP_OeordItemID = OEOrdItem.OEORI_RowId 
AND ABTPrescSignInfo.rownumber = 1
LEFT JOIN ( SELECT SSUSR_RowId, SSUSR_Initials, SSUSR_Name FROM hid0122_cache_his_dhcapp_sqluser.SS_User )   ABTPSSUser ON ABTPSSUser.SSUSR_RowId = ABTPrescSignInfo.ABTP_SaveUser */
LEFT JOIN ( SELECT subt_rowid, subt_code, SUBT_Desc FROM hid0122_cache_his_dhcapp_sqluser.PAC_EpisodeSubType )   PACEpisodeSubType ON PACEpisodeSubType.subt_code = PAAdm.PAADM_Type
LEFT JOIN ( SELECT DHCExceed_RowID, DHCExceed_Desc FROM hid0122_cache_his_dhcapp_sqluser.DHCDoc_ExceedReason )   DHCDocExceedReason ON DHCDocExceedReason.DHCExceed_RowID = OEOrdItemExt.OEORI_ExceedReason_DR
LEFT JOIN ddm.mdm_patientvisitkey   mdm ON OEOrder.OEORD_Adm_DR = mdm.visit_no 
AND mdm.system_source = '155' 
  left join t_ord_rowids on t_ord_rowids.medorgcode='HID0122' and t_ord_rowids.order_main_dstablevalue=OEOrditem.oeori_rowid
union all /*峨眉*/
SELECT CAST
	( null AS VARCHAR ) AS order_main_abtusereason,
	CAST (
	CASE
			
			WHEN OECOrderCategory.ORCAT_Desc = '病理' THEN
			OEOrditem.OEORI_RowId 
			WHEN OECOrderCategory.ORCAT_Desc = '检查' THEN
			OEOrditem.OEORI_RowId 
			WHEN OECOrderCategory.ORCAT_Desc = '放射' THEN
			OEOrditem.OEORI_RowId 
			WHEN OECOrderCategory.ORCAT_Desc = '化验' THEN
			OEOrditem.OEORI_RowId 
			WHEN OECOrderCategory.ORCAT_Desc = '微生物化验' THEN
			OEOrditem.OEORI_RowId ELSE NULL 
	END AS VARCHAR 
	) AS order_main_applyid,
	CAST (
	CASE
			
			WHEN OECOrderCategory.ORCAT_Desc = '病理' THEN
			'检查' 
			WHEN OECOrderCategory.ORCAT_Desc = '检查' THEN
			'检查' 
			WHEN OECOrderCategory.ORCAT_Desc = '放射' THEN
			'检查' 
			WHEN OECOrderCategory.ORCAT_Desc = '化验' THEN
			'检验' 
			WHEN OECOrderCategory.ORCAT_Desc = '微生物化验' THEN
			'检验' ELSE NULL 
	END AS VARCHAR 
	) AS order_main_applytypecode,
	CAST ( NULL AS VARCHAR ) AS order_main_applytypeid,
	CAST (
	CASE
			
			WHEN OECOrderCategory.ORCAT_Desc = '病理' THEN
			'检查' 
			WHEN OECOrderCategory.ORCAT_Desc = '检查' THEN
			'检查' 
			WHEN OECOrderCategory.ORCAT_Desc = '放射' THEN
			'检查' 
			WHEN OECOrderCategory.ORCAT_Desc = '化验' THEN
			'检验' 
			WHEN OECOrderCategory.ORCAT_Desc = '微生物化验' THEN
			'检验' ELSE NULL 
	END AS VARCHAR 
	) AS order_main_applytypename,
	CAST ( DHCItmAddionInfo.INFO_BasicDrug AS VARCHAR ) AS order_main_basedrugflag,
	CAST ( BasicCTUom.CTUOM_Desc AS VARCHAR ) AS order_main_basicunit,
	CAST ( PHCFormDoseEquiv.EQ_Qty AS VARCHAR ) AS order_main_basicunitratio,
	CAST (
	CASE
			
			WHEN OECOrderStatus.OSTAT_Code = 'C' THEN
			concat ( OEOrdItem.OEORI_Xdate, ' ', COALESCE ( OEOrdItem.OEORI_XTIME, '00:00:00' ) ) ELSE NULL 
	END AS VARCHAR 
	) AS order_main_canceldttm,
	CAST ( XCTCPCTCareProv.CTPCP_Code AS VARCHAR ) AS order_main_cancelperscode,
	CAST ( OEOrdItem.OEORI_XCTCP_DR AS VARCHAR ) AS order_main_cancelpersid,
	CAST ( XCTCPCTCareProv.CTPCP_Desc AS VARCHAR ) AS order_main_cancelpersname,
	CAST ( null AS VARCHAR ) AS order_main_checkdttm,
	CAST ( NULL AS VARCHAR ) AS order_main_checknurscode,
	CAST ( NULL AS VARCHAR ) AS order_main_checknursid,
	CAST ( NULL AS VARCHAR ) AS order_main_checknursname,
	CAST ( NULL AS VARCHAR ) AS order_main_checkperscode,
	CAST ( null AS VARCHAR ) AS order_main_checkpersid,
	CAST ( null AS VARCHAR ) AS order_main_checkpersname,
	COALESCE(t_ord_rowids.order_main_datacreatedttm,cast(CURRENT_TIMESTAMP as varchar)) AS order_main_datacreatedttm,
	CAST ( '158' AS VARCHAR ) AS order_main_datasourceflag,
	CAST ( OEOrdItem.OEORI_Qty AS VARCHAR ) AS order_main_dayonenum,
	CAST ( DocCTLoc.CTLOC_Code AS VARCHAR ) AS order_main_deptcode,
	CAST ( OEOrdItem.OEORI_OrdDept_DR AS VARCHAR ) AS order_main_deptid,
	CAST ( DocCTLoc.CTLOC_Desc AS VARCHAR ) AS order_main_deptname,
	CAST ( OEOrdItemExt.OEORI_NeedPIVAFlag AS VARCHAR ) AS order_main_dosingflag,
	CAST ( null AS VARCHAR ) AS order_main_doubtorderdesc,
	CAST ( null AS VARCHAR ) AS order_main_doubtorderflag,
	CAST ( PHCDrgMast.PHCD_Code AS VARCHAR ) AS order_main_drugcode,
	CAST ( PHCForm.PHCF_Desc AS VARCHAR ) AS order_main_drugdosageform,
	CAST ( PHCDrgForm.PHCDF_PHCF_DR AS VARCHAR ) AS order_main_drugdosageformid,
	CAST ( PHCDrgForm.PHCDF_PHCD_ParRef AS VARCHAR ) AS order_main_drugid,
	CAST ( NULL AS VARCHAR ) AS order_main_drugmanageplatformcode,
	CAST ( PHCDrgMast.PHCD_Name AS VARCHAR ) AS order_main_drugname,
	CAST ( NULL AS VARCHAR ) AS order_main_drugpurchasecode,
	CAST ( DHCItmAddionInfo.INFO_Spec AS VARCHAR ) AS order_main_drugspec,
	CAST ( 'hid0123_cache_his_dhcapp_sqluser.OE_Orditem' AS VARCHAR ) AS order_main_dstable,
	CAST ( 'OEORI_RowId' AS VARCHAR ) AS order_main_dstablekey,
	CAST ( OEOrditem.OEORI_RowId AS VARCHAR ) AS order_main_dstablevalue,
	CAST ( NULL AS VARCHAR ) AS order_main_empiid,
	CAST ( NULL AS VARCHAR ) AS order_main_empino,
	CAST ( OEOrdItemExt.OEORI_UsableDays AS VARCHAR ) AS order_main_enabledaynum,
	CAST ( TRIM ( OEOrdItem.OEORI_DepProcNotes ) AS VARCHAR ) AS order_main_entrust,
	CAST ( null AS VARCHAR ) AS order_main_entryreason,
	CAST ( OEOrdItem.OEORI_Cost AS VARCHAR ) AS order_main_estimatedtotalprice,
	CAST ( DHCDocExceedReason.DHCExceed_Desc AS VARCHAR ) AS order_main_excessreason,
	CAST ( concat ( OEOrdItem.OEORI_DateExecuted, ' ', COALESCE ( OEOrdItem.OEORI_TimeExecuted, '00:00:00' ) ) AS VARCHAR ) AS order_main_execdttm,
	CAST ( SSUser.SSUSR_Initials AS VARCHAR ) AS order_main_execperscode,
	CAST ( OEOrditem.OEORI_UserExecuted AS VARCHAR ) AS order_main_execpersid,
	CAST ( SSUser.SSUSR_Name AS VARCHAR ) AS order_main_execpersname,
	CAST ( NULL AS VARCHAR ) AS order_main_extdate1,
	CAST ( NULL AS VARCHAR ) AS order_main_extdate2,
	CAST ( NULL AS VARCHAR ) AS order_main_extnum1,
	CAST ( NULL AS VARCHAR ) AS order_main_extnum2,
	CAST ( NULL AS VARCHAR ) AS order_main_extstr1,
	CAST ( NULL AS VARCHAR ) AS order_main_extstr2,
	CAST ( OEOrder.OEORD_Adm_DR AS VARCHAR ) AS order_main_extstr3,
	CAST ( NULL AS VARCHAR ) AS order_main_extstr4,
	CAST ( NULL AS VARCHAR ) AS order_main_extstr5,
	CAST ( NULL AS VARCHAR ) AS order_main_extstr6,
	CAST ( PHCDrgForm.PHCDF_Indication AS VARCHAR ) AS order_main_giveadaptationdisease,
	CAST ( PHCFreq.PHCFR_Code AS VARCHAR ) AS order_main_givefreqcode,
	CAST ( OEOrdItem.OEORI_PHFreq_DR AS VARCHAR ) AS order_main_givefreqid,
	CAST ( PHCFreq.PHCFR_Desc1 AS VARCHAR ) AS order_main_givefreqname,
	CAST ( NULL AS VARCHAR ) AS order_main_giverateunit,
	CAST ( OEOrdItem.OEORI_SpeedFlowRate AS VARCHAR ) AS order_main_giveratevalue,
	CAST ( TRIM ( OEOrdItem.OEORI_DoseQty ) AS VARCHAR ) AS order_main_givestrength,
	CAST ( DoseCTUOM.CTUOM_Desc AS VARCHAR ) AS order_main_givestrengthunit,
	CAST ( NULL AS VARCHAR ) AS order_main_herbclasscode,
	CAST ( NULL AS VARCHAR ) AS order_main_herbclassid,
	CAST ( NULL AS VARCHAR ) AS order_main_herbclassname,
	CAST ( NULL AS VARCHAR ) AS order_main_herbdecoctioncode,
	CAST ( NULL AS VARCHAR ) AS order_main_herbdecoctionid,
	CAST ( NULL AS VARCHAR ) AS order_main_herbdecoctionname,
	CAST ( NULL AS VARCHAR ) AS order_main_incisiontypecode,
	CAST ( NULL AS VARCHAR ) AS order_main_incisiontypeid,
	CAST ( null AS VARCHAR ) AS order_main_incisiontypename,
	CAST ( OEOrditem.OEORI_CoverMainIns AS VARCHAR ) AS order_main_insuflag,
	CAST ( OEOrdItem.isdeleted AS VARCHAR ) AS order_main_isdeleted,
	CURRENT_TIMESTAMP AS order_main_lastupdatedttm,
	CAST ( OEOrdItem.OEORI_FillerNo AS VARCHAR ) AS order_main_longorderrelationid,
	CAST ( NULL AS VARCHAR ) AS order_main_maindrug,
	CAST ( OEOrdItem.OEORI_OEORI_DR AS VARCHAR ) AS order_main_mainorderno,
	CAST ( OEOrdItemExt.OEORI_MaterialNo AS VARCHAR ) AS order_main_materialsbarcode,
	CAST ( 'HID0123' AS VARCHAR ) AS order_main_medorgcode,
	CAST ( '四川大学华西峨眉医院' AS VARCHAR ) AS order_main_medorgname,
	CAST (null AS VARCHAR ) AS order_main_opspecialdiseasecode,
	CAST ( null AS VARCHAR ) AS order_main_opspecialdiseaseflag,
	CAST ( null AS VARCHAR ) AS order_main_opspecialdiseaseid,
	CAST ( null AS VARCHAR ) AS order_main_opspecialdiseasename,
	CAST ( concat ( OEOrdItem.OEORI_SttDat, ' ', OEOrdItem.OEORI_SttTim ) AS VARCHAR ) AS order_main_orderbegindttm,
	CAST ( NULL AS VARCHAR ) AS order_main_ordercontent,
	CAST ( OEOrdItem.OEORI_Childsub AS VARCHAR ) AS order_main_orderdetid,
	CAST ( DocCTCareProv.CTPCP_Code AS VARCHAR ) AS order_main_orderdoctcode,
	CAST ( OEOrdItem.OEORI_Doctor_DR AS VARCHAR ) AS order_main_orderdoctid,
	CAST ( DocCTCareProv.CTPCP_Desc AS VARCHAR ) AS order_main_orderdoctname,
	CAST ( concat ( OEOrdItem.OEORI_Date, ' ', OEOrdItem.OEORI_TimeOrd ) AS VARCHAR ) AS order_main_orderdttm,
	CAST (
	CASE
			
			WHEN OECOrderStatus.OSTAT_Code = 'D' THEN
			concat ( OEOrdItem.OEORI_Xdate, ' ', COALESCE ( OEOrdItem.OEORI_XTIME, '00:00:00' ) ) ELSE NULL 
	END AS VARCHAR 
	) AS order_main_orderenddttm,
	CAST ( OEOrdItem.OEORI_ARCOS_DR AS VARCHAR ) AS order_main_ordergroupno,
	CAST ( ARCOrdSetDateItem.ITM_Childsub AS VARCHAR ) AS order_main_ordergroupsubno,
	CAST ( OEOrdItem.OEORI_OEORD_ParRef AS VARCHAR ) AS order_main_orderid,
	CAST ( ARCItmMast.ARCIM_Code AS VARCHAR ) AS order_main_orderitemcode,
	CAST ( OEOrditem.OEORI_ItmMast_DR AS VARCHAR ) AS order_main_orderitemid,
	CAST ( ARCItmMast.ARCIM_Desc AS VARCHAR ) AS order_main_orderitemname,
	CAST ( OECOrderCategory.ORCAT_Code AS VARCHAR ) AS order_main_orderpclasscode,
	CAST ( ARCItemCat.ARCIC_OrdCat_DR AS VARCHAR ) AS order_main_orderpclassid,
	CAST ( OECOrderCategory.ORCAT_Desc AS VARCHAR ) AS order_main_orderpclassname,
	CAST ( OEOrdItem.OEORI_SeqNo AS VARCHAR ) AS order_main_orderrelationno,
	CAST ( ARCItemCat.ARCIC_Code AS VARCHAR ) AS order_main_ordersclasscode,
	CAST ( ARCItmMast.ARCIM_ItemCat_DR AS VARCHAR ) AS order_main_ordersclassid,
	CAST ( ARCItemCat.ARCIC_Desc AS VARCHAR ) AS order_main_ordersclassname,
	CAST ( OEOrditem.OEORI_RowId AS VARCHAR ) AS order_main_orderserialno,
	CAST ( OEOrdItemExt.OEORI_Stage AS VARCHAR ) AS order_main_orderstagecode,
	CAST ( NULL AS VARCHAR ) AS order_main_orderstageid,
	CAST ( CASE OEOrdItemExt.OEORI_Stage WHEN 'SQ' THEN '术前' WHEN 'SZ' THEN '术中' WHEN 'SH' THEN '术后' ELSE OEOrdItemExt.OEORI_Stage END AS VARCHAR ) AS order_main_orderstagename,
	CAST ( OECOrderStatus.OSTAT_Code AS VARCHAR ) AS order_main_orderstatuscode,
	CAST ( OEOrditem.OEORI_ItemStat_DR AS VARCHAR ) AS order_main_orderstatusid,
	CAST ( OECOrderStatus.OSTAT_Desc AS VARCHAR ) AS order_main_orderstatusname,
	CAST ( OECPriority.OECPR_Code AS VARCHAR ) AS order_main_ordertypecode,
	CAST ( OEOrditem.OEORI_Priority_DR AS VARCHAR ) AS order_main_ordertypeid,
	CAST ( OECPriority.OECPR_Desc AS VARCHAR ) AS order_main_ordertypename,
	CAST ( CASE WHEN OECPriority.OECPR_Desc = '出院带药' THEN 'Y' ELSE'N' END AS VARCHAR ) AS order_main_outhospdrugflag,
	CAST ( CASE WHEN PHCDrgMast.PHCD_Code IS NOT NULL THEN PurchCTUOM.CTUOM_Desc ELSE NULL END AS VARCHAR ) AS order_main_packageunit,
	CAST ( CTConFac.CTCF_Factor AS VARCHAR ) AS order_main_packageunitratio,
	CAST ( PHCInstruc.PHCIN_Code AS VARCHAR ) AS order_main_pathwaycode,
	CAST ( OEOrdItem.OEORI_Instr_DR AS VARCHAR ) AS order_main_pathwayid,
	CAST ( PHCInstruc.PHCIN_Desc1 AS VARCHAR ) AS order_main_pathwayname,
	CAST ( OEOrdItem.OEORI_Billed AS VARCHAR ) AS order_main_paystatuscode,
	CAST ( NULL AS VARCHAR ) AS order_main_paystatusid,
	CAST ( NULL AS VARCHAR ) AS order_main_paystatusname,
	CAST ( COALESCE ( PAAdm.PAADM_PAPMI_DR, '-1' ) AS VARCHAR ) AS order_main_persid,
	CAST ( COALESCE ( PAPatmas.PAPMI_OPNo, PAPatmas.PAPMI_IPNo ) AS VARCHAR ) AS order_main_persno,
	CAST ( OEOrdItem.OEORI_PrescNo AS VARCHAR ) AS order_main_prescno,
	CAST ( NULL AS VARCHAR ) AS order_main_presctypecode,
	CAST ( NULL AS VARCHAR ) AS order_main_presctypeid,
	CAST (
	IF
		(
			CAST ( CASE WHEN OEOrdItem.OEORI_PrescNo IS NOT NULL THEN TRUE ELSE FALSE END AS BOOLEAN ),
			CAST (
			CASE
	
	WHEN PHCPoison.PHCPO_Desc IS NOT NULL THEN
	CONCAT ( PHCPoison.PHCPO_Desc, '处方' ) 
	WHEN PAAdm.PAADM_Type = 'E' THEN
	'急诊处方' 
	WHEN date_diff (
		'day',
		CAST (
		CASE
				
				WHEN PAPatmas.PAPMI_DOB IS NOT NULL 
				AND LENGTH ( PAPatmas.PAPMI_DOB ) < 18 THEN
					CONCAT ( PAPatmas.PAPMI_DOB, ' 01:00:00' ) ELSE PAPatmas.PAPMI_DOB 
				END AS TIMESTAMP 
			),
			CAST (
			CASE
					
					WHEN PAAdm.PAADM_AdmDate IS NOT NULL 
					AND LENGTH ( PAAdm.PAADM_AdmDate ) < 18 THEN
						CONCAT ( PAAdm.PAADM_AdmDate, ' 00:00:00' ) ELSE PAAdm.PAADM_AdmDate 
					END AS TIMESTAMP 
				) 
				) / 365.25 < 15 THEN
				'儿童处方' ELSE'普通处方' 
		END AS VARCHAR 
		),
	NULL 
	) AS VARCHAR 
) AS order_main_presctypename,
CAST ( OECPriority.OECPR_Desc AS VARCHAR ) AS order_main_priority,
CAST ( RecCTLoc.CTLOC_Code AS VARCHAR ) AS order_main_recdeptcode,
CAST ( OEOrdItem.OEORI_RecDep_DR AS VARCHAR ) AS order_main_recdeptid,
CAST ( RecCTLoc.CTLOC_Desc AS VARCHAR ) AS order_main_recdeptname,
CAST ( OEOrdItemExt.OEORI_SelfOMFlag AS VARCHAR ) AS order_main_selfdrugflag,
CAST ( OEOrdItem.OEORI_AdministerSkinTest AS VARCHAR ) AS order_main_skintest,
CAST ( OECAction.ACT_Desc AS VARCHAR ) AS order_main_skintestmemo,
CAST ( null AS VARCHAR ) AS order_main_specimenid,
CAST ( null AS VARCHAR ) AS order_main_specimenname,
CAST ( NULL AS VARCHAR ) AS order_main_textorderproperty,
CAST ( NULL AS VARCHAR ) AS order_main_tisaneflag,
CAST (
CASE WHEN ARCItemCat.ARCIC_OrderType <> 'R' THEN
		OEOrdItem.OEORI_PhQtyOrd ELSE
	CASE WHEN OEOrdItem.OEORI_QtyPackUOM IS NOT NULL THEN
			OEOrdItem.OEORI_QtyPackUOM 
			WHEN OEOrdItem.OEORI_PhQtyOrd IS NOT NULL THEN
			OEOrdItem.OEORI_PhQtyOrd ELSE NULL 
		END 
	END AS VARCHAR ) AS order_main_totalmeasure,
CAST (
CASE			
WHEN ARCItemCat.ARCIC_OrderType <> 'R' 
AND OEOrdItem.OEORI_PhQtyOrd IS NOT NULL THEN
	PurchCTUOM.CTUOM_Desc 
	WHEN ARCItemCat.ARCIC_OrderType = 'R' 
	AND OEOrdItem.OEORI_QtyPackUOM IS NOT NULL THEN
		PurchCTUOM.CTUOM_Desc 
		WHEN ARCItemCat.ARCIC_OrderType = 'R' 
		AND OEOrdItem.OEORI_QtyPackUOM IS NULL 
		AND OEOrdItem.OEORI_PhQtyOrd IS NOT NULL THEN
			DoseCTUOM.CTUOM_Desc ELSE NULL 
	END AS VARCHAR 
	) AS order_main_totalmeasureunit,
	CAST ( OEOrdItem.OEORI_Cost AS VARCHAR ) AS order_main_totalprice,
	CAST ( OEOrdItemExt.OEORI_LocalInfusionQty AS VARCHAR ) AS order_main_transfusionnum,
	CAST ( PHCDuration.PHCDU_Code AS VARCHAR ) AS order_main_treatmentcode,
	CAST ( PHCDuration.PHCDU_Desc1 AS VARCHAR ) AS order_main_treatmentdesc,
	CAST ( OEOrditem.OEORI_Durat_DR AS VARCHAR ) AS order_main_treatmentid,
	CAST ( OEOrdItem.OEORI_UnitCost AS VARCHAR ) AS order_main_unitprice,
	CAST ( NULL AS VARCHAR ) AS order_main_unitypurchaseplatformflag,
	CAST ( OEOrditem.OEORI_NotifyClinician AS VARCHAR ) AS order_main_urgent,
	CAST ( PHCInstruc.PHCIN_Desc1 AS VARCHAR ) AS order_main_usage,
	CAST ( CASE WHEN PHCDuration.PHCDU_Desc2 = '饮片' THEN PHCDuration.PHCDU_Factor ELSE NULL END AS VARCHAR ) AS order_main_usedrugnum,
	CAST ( null AS VARCHAR ) AS order_main_usedrugpurpose,
	CAST ( concat('123',lpad(OEOrder.OEORD_Adm_DR,15,'0')) AS VARCHAR ) AS order_main_visitid,
	CAST ( PAAdm.PAADM_ADMNo AS VARCHAR ) AS order_main_visitno,
	CAST ( PAAdm.PAADM_Type AS VARCHAR ) AS order_main_visittypecode,
	CAST ( PACEpisodeSubType.subt_rowid AS VARCHAR ) AS order_main_visittypeid,
	CAST ( PACEpisodeSubType.SUBT_Desc AS VARCHAR ) AS order_main_visittypename,
	CAST ( UserDeptCTLoc.CTLOC_Code AS VARCHAR ) AS order_main_orderuserdept_code,
	CAST ( OEOrdItem.OEORI_UserDepartment_DR AS VARCHAR ) AS order_main_orderuserdept_id,
	CAST ( UserDeptCTLoc.CTLOC_Desc AS VARCHAR ) AS order_main_orderuserdept_name,
	CAST ( WardCTLoc.CTLOC_Code AS VARCHAR ) AS order_main_wardcode,
	CAST ( WardCTLoc.CTLOC_RowID AS VARCHAR ) AS order_main_wardid,
	CAST ( WardCTLoc.CTLOC_Desc AS VARCHAR ) AS order_main_wardname,
	CAST ( concat ( '23_1_1_OE_OrdItem_', OEOrdItem.OEORI_RowId ) AS VARCHAR ) AS rowkey 
FROM
	(select * from hid0123_cache_his_dhcapp_sqluser.oe_orditem
	where _hoodie_commit_time>=(select etl_time from t_incr_time) and isdeleted='0') OEOrditem
LEFT JOIN ( SELECT OEORD_RowId1, OEORD_Adm_DR FROM hid0123_cache_his_dhcapp_sqluser.OE_Order ) AS OEOrder ON OEOrder.OEORD_RowId1 = OEOrdItem.OEORI_OEORD_ParRef
LEFT JOIN ( SELECT PAADM_RowID, PAADM_PAPMI_DR, PAADM_Type, PAADM_ADMNo, PAADM_AdmDate FROM hid0123_cache_his_dhcapp_sqluser.PA_Adm ) AS PAAdm ON PAAdm.PAADM_RowID = OEOrder.OEORD_Adm_DR
LEFT JOIN ( SELECT PAPMI_RowId1, PAPMI_OPNo, PAPMI_IPNo, PAPMI_DOB FROM hid0123_cache_his_dhcapp_sqluser.PA_Patmas ) AS PAPatmas ON PAPatmas.PAPMI_RowId1 = PAAdm.PAADM_PAPMI_DR
LEFT JOIN ( SELECT DATE_ParRef, DATE_RowId FROM hid0123_cache_his_dhcapp_sqluser.ARC_OrdSetDate ) AS ARCOrdSetDate ON ARCOrdSetDate.DATE_ParRef = OEOrdItem.OEORI_ARCOS_DR
LEFT JOIN (
SELECT
	ITM_ParRef,
	ITM_ARCIM_DR,
	ITM_Childsub,
	ROW_NUMBER ( ) OVER ( PARTITION BY ITM_ParRef, ITM_ARCIM_DR ORDER BY CAST ( ITM_Childsub AS BIGINT ) ASC ) AS rownumber 
FROM
	hid0123_cache_his_dhcapp_sqluser.ARC_OrdSetDateItem 
) AS ARCOrdSetDateItem ON ARCOrdSetDateItem.ITM_ParRef = ARCOrdSetDate.DATE_RowId 
AND ARCOrdSetDateItem.ITM_ARCIM_DR = OEOrditem.OEORI_ItmMast_DR 
AND ARCOrdSetDateItem.rownumber = 1
LEFT JOIN ( SELECT CTLOC_RowID, CTLOC_Code, CTLOC_Desc,ctloc_hospital_dr FROM hid0123_cache_his_dhcapp_sqluser.CT_Loc ) AS DocCTLoc ON DocCTLoc.CTLOC_RowID = OEOrdItem.OEORI_OrdDept_DR
LEFT JOIN ( SELECT CTLOC_RowID, CTLOC_Type, CTLOC_Code, CTLOC_Desc FROM hid0123_cache_his_dhcapp_sqluser.CT_Loc ) AS WardCTLoc ON WardCTLoc.CTLOC_RowID = OEOrdItem.OEORI_AdmLoc_DR
LEFT JOIN ( SELECT CTLOC_RowID, CTLOC_Code, CTLOC_Desc FROM hid0123_cache_his_dhcapp_sqluser.CT_Loc ) AS UserDeptCTLoc ON UserDeptCTLoc.CTLOC_RowID = OEOrdItem.OEORI_UserDepartment_DR
LEFT JOIN ( SELECT OECPR_RowId, OECPR_Code, OECPR_Desc FROM hid0123_cache_his_dhcapp_sqluser.OEC_Priority ) AS OECPriority ON OECPriority.OECPR_RowId = OEOrditem.OEORI_Priority_DR
LEFT JOIN ( SELECT ARCIM_RowId, ARCIM_Code, ARCIM_PHCDF_DR, ARCIM_BillingUOM_DR, ARCIM_Desc, ARCIM_ItemCat_DR FROM hid0123_cache_his_dhcapp_sqluser.ARC_ItmMast ) AS ARCItmMast ON ARCItmMast.ARCIM_RowId = OEOrditem.OEORI_ItmMast_DR
LEFT JOIN ( SELECT ARCIC_RowId, ARCIC_OrdCat_DR, ARCIC_Code, ARCIC_Desc, ARCIC_OrderType FROM hid0123_cache_his_dhcapp_sqluser.ARC_ItemCat ) AS ARCItemCat ON ARCItemCat.ARCIC_RowId = ARCItmMast.ARCIM_ItemCat_DR
LEFT JOIN ( SELECT ORCAT_RowId, ORCAT_Code, ORCAT_Desc FROM hid0123_cache_his_dhcapp_sqluser.OEC_OrderCategory ) AS OECOrderCategory ON OECOrderCategory.ORCAT_RowId = ARCItemCat.ARCIC_OrdCat_DR
LEFT JOIN ( SELECT OSTAT_RowId, OSTAT_Code, OSTAT_Desc FROM hid0123_cache_his_dhcapp_sqluser.OEC_OrderStatus ) AS OECOrderStatus ON OECOrderStatus.OSTAT_RowId = OEOrditem.OEORI_ItemStat_DR
LEFT JOIN ( SELECT INCI_RowId, INCI_OriginalARCIM_DR, INCI_Code FROM hid0123_cache_his_dhcapp_sqluser.INC_Itm ) AS INCItm ON INCItm.INCI_OriginalARCIM_DR = ARCItmMast.ARCIM_RowId 
AND INCItm.INCI_Code = ARCItmMast.ARCIM_Code
LEFT JOIN ( SELECT INFO_INCI_DR, INFO_BasicDrug, INFO_Spec FROM hid0123_cache_his_dhcapp_sqluser.DHC_ItmAddionInfo ) AS DHCItmAddionInfo ON DHCItmAddionInfo.INFO_INCI_DR = INCItm.INCI_RowId
LEFT JOIN ( SELECT CTUOM_RowId, CTUOM_Desc FROM hid0123_cache_his_dhcapp_sqluser.CT_UOM ) AS DoseCTUOM ON DoseCTUOM.CTUOM_RowId = OEOrdItem.OEORI_Unit_DR
LEFT JOIN ( SELECT PHCDF_RowId, PHCDF_PHCD_ParRef, PHCDF_CTUOM_DR, PHCDF_PHCF_DR, PHCDF_Indication FROM hid0123_cache_his_dhcapp_sqluser.PHC_DrgForm ) AS PHCDrgForm ON PHCDrgForm.PHCDF_RowId = ARCItmMast.ARCIM_PHCDF_DR
LEFT JOIN ( SELECT PHCD_RowId, PHCD_PHCPO_DR, PHCD_Code, PHCD_Name FROM hid0123_cache_his_dhcapp_sqluser.PHC_DrgMast ) AS PHCDrgMast ON PHCDrgMast.PHCD_RowId = PHCDrgForm.PHCDF_PHCD_ParRef
LEFT JOIN ( SELECT PHCF_RowID, PHCF_Desc FROM hid0123_cache_his_dhcapp_sqluser.PHC_Form ) AS PHCForm ON PHCForm.PHCF_RowID = PHCDrgForm.PHCDF_PHCF_DR
LEFT JOIN ( SELECT EQ_ParRef, EQ_CTUOM_DR, EQ_Qty FROM hid0123_cache_his_dhcapp_sqluser.PHC_FormDoseEquiv ) AS PHCFormDoseEquiv ON PHCFormDoseEquiv.EQ_ParRef = PHCDrgForm.PHCDF_RowID 
AND PHCFormDoseEquiv.EQ_CTUOM_DR = OEOrdItem.OEORI_Unit_DR
LEFT JOIN ( SELECT CTUOM_RowId, CTUOM_Desc FROM hid0123_cache_his_dhcapp_sqluser.CT_Uom ) AS BasicCTUom ON BasicCTUom.CTUOM_RowId = PHCDrgForm.PHCDF_CTUOM_DR
LEFT JOIN ( SELECT CTUOM_RowId, CTUOM_Desc FROM hid0123_cache_his_dhcapp_sqluser.CT_UOM ) AS PurchCTUOM ON PurchCTUOM.CTUOM_RowId = ARCItmMast.ARCIM_BillingUOM_DR
LEFT JOIN ( SELECT CTCF_ActiveFlag, CTCF_FrUOM_DR, CTCF_ToUOM_DR, CTCF_RowID, CTCF_Factor FROM hid0123_cache_his_dhcapp_sqluser.CT_ConFac ) AS CTConFac ON CTConFac.CTCF_ActiveFlag = 'Y' 
AND CTConFac.CTCF_FrUOM_DR = ARCItmMast.ARCIM_BillingUOM_DR 
AND CTConFac.CTCF_ToUOM_DR = PHCDrgForm.PHCDF_CTUOM_DR 
AND CTConFac.CTCF_RowID <> '102' 
AND CTConFac.CTCF_RowID <> '113'
LEFT JOIN ( SELECT PHCFR_RowId, PHCFR_Code, PHCFR_desc1 FROM hid0123_cache_his_dhcapp_sqluser.PHC_Freq ) AS PHCFreq ON PHCFreq.PHCFR_RowId = OEOrdItem.OEORI_PHFreq_DR
LEFT JOIN ( SELECT PHCIN_RowId, PHCIN_Code, PHCIN_desc1 FROM hid0123_cache_his_dhcapp_sqluser.PHC_Instruc ) AS PHCInstruc ON PHCInstruc.PHCIN_RowId = OEOrdItem.OEORI_Instr_DR
LEFT JOIN ( SELECT CTPCP_RowId1, CTPCP_Code, CTPCP_desc FROM hid0123_cache_his_dhcapp_sqluser.CT_CareProv ) AS DocCTCareProv ON DocCTCareProv.CTPCP_RowId1 = OEOrdItem.OEORI_Doctor_DR
LEFT JOIN ( SELECT CTPCP_RowId1, CTPCP_Code, CTPCP_desc FROM hid0123_cache_his_dhcapp_sqluser.CT_CareProv ) AS XCTCPCTCareProv ON XCTCPCTCareProv.CTPCP_RowId1 = OEOrdItem.OEORI_XCTCP_DR
LEFT JOIN ( SELECT CTLOC_RowID, CTLOC_Code, CTLOC_desc FROM hid0123_cache_his_dhcapp_sqluser.CT_Loc ) AS RecCTLoc ON RecCTLoc.CTLOC_RowID = OEOrdItem.OEORI_RecDep_DR
LEFT JOIN ( SELECT PHCDU_RowId, PHCDU_Code, PHCDU_Desc1, PHCDU_Desc2, PHCDU_Factor FROM hid0123_cache_his_dhcapp_sqluser.PHC_Duration ) AS PHCDuration ON PHCDuration.PHCDU_RowId = OEOrditem.OEORI_Durat_DR
-- LEFT JOIN ( SELECT orditemid, OrderFillReasonDR, CutTypeDR, OrderReasonDR FROM hid0123_cache_his_dhcapp_sqluser.HXAntiDrugInfo ) AS HXAntiDrugInfo ON HXAntiDrugInfo.orditemid = OEOrditem.OEORI_RowId
-- LEFT JOIN ( SELECT HX_ROWID, yka026 FROM hid0123_cache_his_dhcapp_sqluser.HX_DiseaseDicData ) AS HXDiseaseDicData ON HXDiseaseDicData.HX_ROWID = OEOrditem.OEORI_DRGOrder
-- LEFT JOIN ( SELECT ID, YDMT_DisCode FROM hid0123_cache_his_dhcapp_sqluser.YDMT_Disease ) AS YDMTDisease ON YDMTDisease.ID = OEOrditem.OEORI_DRGOrder
LEFT JOIN ( SELECT PHCPO_RowId, PHCPO_Desc FROM hid0123_cache_his_dhcapp_sqluser.PHC_Poison ) AS PHCPoison ON PHCPoison.PHCPO_RowId = PHCDrgMast.PHCD_PHCPO_DR
LEFT JOIN ( SELECT ACT_RowId, ACT_Desc FROM hid0123_cache_his_dhcapp_sqluser.OEC_Action ) AS OECAction ON OECAction.ACT_RowId = OEOrditem.OEORI_Action_DR
LEFT JOIN ( SELECT SPEC_ParRef, SPEC_Code FROM hid0123_cache_his_dhcapp_sqluser.OE_OrdSpecimen ) AS OEOrdSpecimen ON OEOrdSpecimen.SPEC_ParRef = OEOrditem.OEORI_RowId
-- JOIN ( SELECT RowID, Code, IName FROM hid0123_cache_his_dhcapp_sqluser.BT_Specimen ) AS BTSpecimen ON BTSpecimen.Code = OEOrdSpecimen.SPEC_Code
LEFT JOIN ( SELECT SSUSR_RowId, SSUSR_Initials, SSUSR_Name FROM hid0123_cache_his_dhcapp_sqluser.SS_User ) AS SSUser ON SSUser.SSUSR_RowId = OEOrditem.OEORI_UserExecuted
LEFT JOIN ( SELECT REA_RowId FROM hid0123_cache_his_dhcapp_sqluser.PAC_AdmReason ) AS BBExtPACAdmReason ON BBExtPACAdmReason.REA_RowId = OEOrditem.OEORI_BBExtCode
LEFT JOIN hid0123_cache_his_dhcapp_sqluser.OE_OrdItemExt AS OEOrdItemExt ON OEOrdItemExt.OEORI_RowId = OEOrditem.OEORI_RowId
/*LEFT JOIN (
SELECT
	ABTP_SaveUser,
	ABTP_SaveDate,
	ABTP_SaveTime,
	ABTP_OeordItemID,
	ABTP_Temp1,
	ROW_NUMBER ( ) OVER ( PARTITION BY ABTP_OeordItemID ORDER BY CAST ( ABTP_Rowid AS BIGINT ) DESC ) AS rownumber 
FROM
	hid0123_cache_his_dhcapp_sqluser.ABTPrescSignInfo 
) AS ABTPrescSignInfo ON ABTPrescSignInfo.ABTP_OeordItemID = OEOrdItem.OEORI_RowId 
AND ABTPrescSignInfo.rownumber = 1
LEFT JOIN ( SELECT SSUSR_RowId, SSUSR_Initials, SSUSR_Name FROM hid0123_cache_his_dhcapp_sqluser.SS_User ) AS ABTPSSUser ON ABTPSSUser.SSUSR_RowId = ABTPrescSignInfo.ABTP_SaveUser */
LEFT JOIN ( SELECT subt_rowid, subt_code, SUBT_Desc FROM hid0123_cache_his_dhcapp_sqluser.PAC_EpisodeSubType ) AS PACEpisodeSubType ON PACEpisodeSubType.subt_code = PAAdm.PAADM_Type
LEFT JOIN ( SELECT DHCExceed_RowID, DHCExceed_Desc FROM hid0123_cache_his_dhcapp_sqluser.DHCDoc_ExceedReason ) AS DHCDocExceedReason ON DHCDocExceedReason.DHCExceed_RowID = OEOrdItemExt.OEORI_ExceedReason_DR
left join t_ord_rowids on t_ord_rowids.medorgcode='HID0123' and t_ord_rowids.order_main_dstablevalue=OEOrditem.oeori_rowid
WHERE DocCTLoc.ctloc_hospital_dr='2'
union all /*DL中删除数据从DC取数据*/
select order_main_abtusereason,order_main_applyid,order_main_applytypecode,order_main_applytypeid,order_main_applytypename,order_main_basedrugflag,
order_main_basicunit,order_main_basicunitratio,order_main_canceldttm,order_main_cancelperscode,order_main_cancelpersid,order_main_cancelpersname,
order_main_checkdttm,order_main_checknurscode,order_main_checknursid,order_main_checknursname,order_main_checkperscode,order_main_checkpersid,
order_main_checkpersname,order_main_datacreatedttm,order_main_datasourceflag,order_main_dayonenum,order_main_deptcode,order_main_deptid,
order_main_deptname,order_main_dosingflag,order_main_doubtorderdesc,order_main_doubtorderflag,order_main_drugcode,order_main_drugdosageform,
order_main_drugdosageformid,order_main_drugid,order_main_drugmanageplatformcode,order_main_drugname,order_main_drugpurchasecode,
order_main_drugspec,order_main_dstable,order_main_dstablekey,order_main_dstablevalue,order_main_empiid,order_main_empino,order_main_enabledaynum,
order_main_entrust,order_main_entryreason,order_main_estimatedtotalprice,order_main_excessreason,order_main_execdttm,order_main_execperscode,
order_main_execpersid,order_main_execpersname,order_main_extdate1,order_main_extdate2,order_main_extnum1,order_main_extnum2,order_main_extstr1,
order_main_extstr2,order_main_extstr3,order_main_extstr4,order_main_extstr5,order_main_extstr6,order_main_giveadaptationdisease,
order_main_givefreqcode,order_main_givefreqid,order_main_givefreqname,order_main_giverateunit,order_main_giveratevalue,order_main_givestrength,
order_main_givestrengthunit,order_main_herbclasscode,order_main_herbclassid,order_main_herbclassname,order_main_herbdecoctioncode,
order_main_herbdecoctionid,order_main_herbdecoctionname,order_main_incisiontypecode,order_main_incisiontypeid,order_main_incisiontypename,
order_main_insuflag,'1' as order_main_isdeleted,current_timestamp as order_main_lastupdatedttm,order_main_longorderrelationid,
order_main_maindrug,order_main_mainorderno,order_main_materialsbarcode,order_main_medorgcode,order_main_medorgname,order_main_opspecialdiseasecode,
order_main_opspecialdiseaseflag,order_main_opspecialdiseaseid,order_main_opspecialdiseasename,order_main_orderbegindttm,order_main_ordercontent,
order_main_orderdetid,order_main_orderdoctcode,order_main_orderdoctid,order_main_orderdoctname,order_main_orderdttm,order_main_orderenddttm,
order_main_ordergroupno,order_main_ordergroupsubno,order_main_orderid,order_main_orderitemcode,order_main_orderitemid,order_main_orderitemname,
order_main_orderpclasscode,order_main_orderpclassid,order_main_orderpclassname,order_main_orderrelationno,order_main_ordersclasscode,
order_main_ordersclassid,order_main_ordersclassname,order_main_orderserialno,order_main_orderstagecode,order_main_orderstageid,order_main_orderstagename,
order_main_orderstatuscode,order_main_orderstatusid,order_main_orderstatusname,order_main_ordertypecode,order_main_ordertypeid,
order_main_ordertypename,order_main_outhospdrugflag,order_main_packageunit,order_main_packageunitratio,order_main_pathwaycode,order_main_pathwayid,
order_main_pathwayname,order_main_paystatuscode,order_main_paystatusid,order_main_paystatusname,order_main_persid,order_main_persno,
order_main_prescno,order_main_presctypecode,order_main_presctypeid,order_main_presctypename,order_main_priority,order_main_recdeptcode,
order_main_recdeptid,order_main_recdeptname,order_main_selfdrugflag,order_main_skintest,order_main_skintestmemo,order_main_specimenid,
order_main_specimenname,order_main_textorderproperty,order_main_tisaneflag,order_main_totalmeasure,order_main_totalmeasureunit,
order_main_totalprice,order_main_transfusionnum,order_main_treatmentcode,order_main_treatmentdesc,order_main_treatmentid,order_main_unitprice,
order_main_unitypurchaseplatformflag,order_main_urgent,order_main_usage,order_main_usedrugnum,order_main_usedrugpurpose,order_main_visitid,
order_main_visitno,order_main_visittypecode,order_main_visittypeid,order_main_visittypename,
order_main_orderuserdept_code,order_main_orderuserdept_id,order_main_orderuserdept_name,
order_main_wardcode,order_main_wardid,
order_main_wardname,rowkey
from datacenter_db.order_main
where (medorgcode='HID0122' and order_main_dstablevalue in(select oeori_rowid from hid0122_cache_his_dhcapp_sqluser.oe_orditem where _hoodie_commit_time >= (select etl_time from t_incr_time) and isdeleted='1'))
or (medorgcode='HID0123' and order_main_dstablevalue in(select oeori_rowid from hid0123_cache_his_dhcapp_sqluser.oe_orditem where _hoodie_commit_time >= (select etl_time from t_incr_time) and isdeleted='1'))
) a