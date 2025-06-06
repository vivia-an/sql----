基本表
序号	表前缀	全称	业务范围	备注说明
1	APC_	Accounts Payable Code Tables – 
Vendors	供应业务	　
2	ARC_
	Accounts Receivable Code Tables
-Billing rules, deposit, outstanding payment, insurance, order item master, receipts	接收业务(预约规则)	　
3	CF_	Configuration Code Tables	系统配置数据	CF_
4	CT_	Common Code Tables	基础数据表	CT_
5	IN_
	Inventory System
-Stock received, requested, transferred, disposed, stock-take, sterile supplies, order to manufacture items	库存数据,	
   6	MRC_	Electronic Medical Records Code Tables	电子诊疗基础数据	MRC_
   7	MR_	Electronic Medical Records
-Diagnosis, allergy, images, ICU values, nursing notes, objective/subjective findings, present illness	电子诊疗数据	MR_
   8	OEC_	Order Entry Code Tables	医嘱基础数据	OEC_
   9	OE_	Order Entry
-Items ordered, results, result codes, order execution	医嘱数据	OE_
   10	ORC_	Operating Room Code Tables	手术室基础数据	ORC_
   11	OR_	Operating Room
-Anaesthesia, operation	手术室,手术数据	OR_
   12	PA_		病人信息,就诊,床位转移,明细数据	PA_
   13	PHC_		药品基础数据	PHC_
   14	RBC_	Resource Booking code tables	资源预约基础数据	RBC_
   15	RB_	Resource Booking
-Resource details, bookings, scheduling	资源预约数据	RB_
   16	SS_	System Code Tables	系统基础数据	SS_
按表前缀划分
按HIS业务流程划分
1.基础数据字典表
1.1用户,安全组 ,医院基本信息表
序号	表名称	类名称	业务名称	备注说明
1	CT_Hospital	User.CTHospital	医院信息	　
2	SS_User	User.SSUser	用户	　
3	SS_GROUP	User. SSGroup	安全组	　
4	SS_UserOtherLogonLoc	User. SSUserOtherLogonLoc	登录其他科室信息	　
备注:
1.SS_USER是用户表  有一个指针指向SS_GROUP。系统里面所有操作计算机
的人员都在这里面存在，在MEDTRAK中如果连续10次密码输入错误，就会把SS_ACTIVE置为NO这时此用该用户不能再做登录。
2.SSUSR_CAREPROV_DR指向CT_CareProv说明这个用户是医护人员。在医嘱表里面有个指针也指向CT_Careprov这个表，他的来源也就是从SS_User中的那个指针来的。        3.SS_UserOtherLogonLoc一个用户属多个科室或安全组时存的数据。

1.2科室,部门,病房信息表
序号	表名称	类名称	业务名称	存储
1	CT_Loc	User.CTLoc	科室	　
	RBC_DepartmentGroup		科室部门组	
4	PAC_Ward	User.PACWard	病区	　
6	PAC_WardRoom 	User.PACWardRoom	病区房间(PAC_Ward 子表)	　
5	PAC_WardBedAllocation	User.PACWardBedAllocation	科室与病区对照	　
	PAC_Room		房间	
7	PAC_RoomType 	User. PACRoomType	病房类型	　User.PACRoomType
8	PAC_Bed	User. PACBed	床位表	　
9	PAC_BedType	User. PACBedType	床位类型	　
备注:
1PAC_WARD:在此表中存在的是在CT_LOC中的科室类型为WARD的记录,他是
在CT_LOC中的一个Trigger.
3PAC_BED是PAC_WARD的一个子表,在这个表里面存在的是病区的床位信息.在里     
面的床位大小可以通过SQL最后一次更新，在此表里面有一个指针指向PAC_BEDTYPE,在PAC_BEDTYPE中记录了医院的
8床位类型,他跟医嘱相关联,病人的床位费就是跟据此表来计算的.
PAC_WardRoom此表是PAC_WARD的一个子表,这个表里面是病区的房间信息,有一个指针指向PAC_RoomType, PAC_RoomType里面记录了医院所有的床位类型
4.科室类型
常用的科室类型：
      Execute：常规临床科室及医技科室
	     Emergency：急诊观察室 不包含急诊就诊科室
	     Operating Theatre：手术室
     Dispensing：库房管理科室
     Other：行政办公科室
         Ward：临床病区 护理单元，有床位
1.3医护人员表
序号	表名称	类名称	业务名称	存储
1	CT_CareProv	User.CTCareProv	医护人员	　
2	CT_CarPrvTp	User.CTCarPrvTp	医护人员类别	
3				　
备注：
1  CT_CARPRVTP这个表是用来表明医护人员的类型，在CT_Careprov中有一个指针指向这个表。

1.4诊断基础数据
序号	表名称	类名称	业务名称	存储
1	MRC_DiagnosType	User. MRCDiagnosType	诊断类型表(出院诊断,主诊断,入院诊断)	　
4	MRC_ICDAlias	User. MRCICDAlias	别名表	　
5	MRC_ICDDx	User.MRCICDDx	诊断表	　^MRC("ID"”)
   
1.5三大项基础信息
1.5.1 医嘱项
序号	表名称	类名称	业务名称	存储
1	ARC_ItmMast	User.ARCItmMast	医嘱项	　
	ARC_Alias	User.ARCAlias	医嘱项别名表	
	ARC_ItmRecLoc	User.ARCItmRecLoc	医嘱项接收科室	
	ARC_ItemCat	User.ARCItemCat	医嘱子分类	^ARC("IC")
	ARC_ItemCatRecLoc	User.ARCItemCatRecLoc	医嘱子分类接收科室	
	OEC_OrderCategory	User.OECOrderCategory	医嘱大类	^OEC("ORCAT")
	OEC_OrdCatRecLoc	User.OECOrdCatRecLoc	医嘱大类接收科室	
	OEC_OrderType	User.OECOrderType	医嘱类型	^OEC("TYP")
	OEC_OrderStatus	User.OECOrderStatus	医嘱状态表	^OEC("OSTAT")
	ARC_BillGrp	User.ARCBillGrp	帐单类	m
	ARC_BillSub	User.ARCBillSub	帐单子类(只有统计组用到)	
	OEC_Order_AdminStatus	User.OECOrderAdminStatus	医嘱执行状态表	
	ARC_OrdSets	User.ARCOrdSets	医嘱套	
	DHC_UserFavItems	User.DHCUserFavItems	个人医嘱套	ARC_ORDSETS -> ARC_OrdSetDate-> ARC_OrdSetDateIte
	OEC_Priority	User.OECPriority	医嘱类型(长期,临时)	
				
				
				
ARC_OrdSets -> ARC_OrdSetDate-> ARC_OrdSetDateItem  然后关联医嘱套中的医嘱信息

1.5.2药学项
序号	表名称	类名称	业务名称	存储
1	PHC_DrgMast	User.PHCDrgMast	药学项主表	　
2	PHC_DrgForm	User.PHCDrgForm	药学项子表	　
3	PHC_DrgFormExt	User.PHCDrgFormExt	药学项扩展表	　
4	PHC_DrgGeneric	User.PHCDrgGeneric	药品通用名(PHC_DrgMast的子表)	　
5	PHC_Form	User.PHCForm	 剂型(颗粒剂,胶囊)	
6	PHC_Generic	User.PHCGeneric	 通用名表(与PHC_DrgGeneric外键关联)	
7	CT_UOM	User.CTUOM	单位表	
8	CT_ConFac	User.CTConFac	单位转换系数表	
9	PHC_Freq	User.PHCFreq	频次	
10	PHC_DispensingTime	User.PHCDispensingTime	频次分发时间 (PHC_Freq的子表)	
	PHC_Instruc 	User.PHCInstruc	用药途径	
	PHC_Duration	User.PHCDuration	疗程	
	PHC_SubCat	User.PHCSubCat	药理学分类	
	PHC_Cat	User.PHCCat	药学项分类	
	PHC_Poison	User.PHCPoison	管制分类	
9	PHC_FormDoseEquiv	User.PHCFormDoseEquiv	PHC_DrgForm的子表	　

1.5.3库存项
序号	表名称	类名称	业务名称	存储
1	INC_Itm	User.INCItm	库存项	　
4	INC_ItmLoc	User.INCItmLoc	科室库存表(INC_Itm的子表)	　
5	INC_ALIAS	User.INCALIAS	库存项别名表	　
6	INC_StkCat		库存分类	　
7	INC_STKTKGP		盘点分类	　
8	APC_VENDOR		供应商	　
9	PH_Manufacturer		产地	　

1.6检验基础数据
序号	表名称	类名称	业务名称	存储
1	CT_Specimen	User.CTSpecimen	检验标本	　^TTAB
4	CT_TestCode	User.CTTestCode	检验项目	　
5	CT_TestCodeContainers	在LABDATA下	检验项目备注	　
6	CT_TestSet	在LABDATA下	检验医嘱	　
7	CT_TestSetSpecimen	在LABDATA下	检验医嘱关联标本	　
8	CT_TestCodeStandardComments	在LABDATA下	检验医嘱关联容器	　
9				　
1.7
1.7检查基础数据
序号	表名称	类名称	业务名称	存储
1	RBC_Equipment	User.RBCEquipment	检查设备	　
4	DHCRBC_ReportStatus	User.DHCRBCReportStatus	检查状态(未写报告 I 图象采集 R已录入  O 正在打开  V 已审核  S已发布)	　
5				　
6				　
7				　
8				　
9				　

1.8过敏源基础数据
序号	表名称	类名称	业务名称	存储
1	PAC_Allergy	User.PACAllergy	过敏源	　
1.9 手术基础数据
序号	表名称	类名称	业务名称	存储
1	ORC_AnaestMethod	User. CTCareProv	病麻醉方式	　
	ORC_Operation	User.ORCOperation	手术数据表	
	ORC_OperationAlias	User.ORCOperationAlias	手术别名表(ORC_Operation的子表)	
	ORC_OperPosition	User.ORCOperPosition	体位(平卧位, 侧位)	
	ORC_OperationCategory	User.ORCOperationCategory	手术分类(一类,二类,三类)	
	ORC_AnaestMethod	User.ORCAnaestMethod	麻醉方式数据表(安定麻醉)	
	ORC_BladeType	User.ORCBladeType	手术切口等级	
4	OEC_BodySite	User.OECBodySite	身体部位	

1.10计费基础信息
序号	表名称	类名称	业务名称	存储
1	CT_PayMode	User. CTPayMode	支付方式	^CT("CTPM")
4	PAC_AdmReason	User. PACAdmReason	病人入院类型字典	^PAC("ADMREA")
5	dhc_taritem	User.DHCTarItem	收费项目表	^DHCTARI
6	dhc_orderlinktar		收费项目与医嘱项对应表	^DHCOLT
7	dhc_taritemprice		收费项目价格表	^DHCTARI
8	dhc_taritemalias		收费项目别名	^DHCTARAL
	DHC_TARfactor		收费项目对不同病人的折扣与记帐比例	
	DHC_TarAC		收费项目会计分类	^DHCTarC("TAC")
	ARC_DisretOutstType		欠费类别表	^ARC("DOUTS")
	DHC_TarIc		住院费用大类字典	^DHCTarC("TIC")
	DHC_TarInpatCate		住院费用子类	^DHCTarC("IC"）
	DHC_TarPara		新计费系统参数表	^DHCTarC("CF")
	arc_deptype		预交金类型字典	^ARC("ARCDT")
	cmc_bankmas		银行字典	^CMC("CMCBM")
	DHC_TARCATE, DHC_TARSUBCATE		收费项目类(子类与病人收费有关)	
	DHC_TAROC  DHC_TAROUTPATCATE		门诊分类发票	
	DHC_TARIC  DHC_TARINPATCATE		住院分类	
	DHC_TAREC  DHC_TAREMCCATE		核算分类(只有统计组用到)	
	DHC_TarMc  DHC_TarMrCate		病案分类(MEDTRAK中的电子病历中病案首页)	
	DHC_TARAC  DHC_TARACCTCATE		会计分类(只有统计组用到)	
				
				
				
				

1.11其他基础数据
序号	表名称	类名称	业务名称	存储
1	MRC_BodyParts	User. CTCareProv	身体部位	^MRC(""BODP")
	PAC_BloodType	User.ORCOperation	血型	^PAC("BLDT")
	MRC_ObservationItem		观察项(生命体征数据)  代码表维护	
	MRC_ObservationGroup		观察组	
	MRC_ObservationGroupItems		观察项组对应关系	
				
				
4				

2.基础业务表
2.1 门诊业务
2.1.1 病人建档业务
2.1.1.1病人信息表
序号	表名称	类名称	业务名称	存储
1	PA_PatMas		医护人员	　
	PA_Person			^CT("SEX")
	CT_Sex	User. CTSex	性别表	
	CT_Marital		婚姻状况	
	CT_Relation		家庭关系	^CT("RLT"
	CT_Education		教育	^CT("EDU")
	CT_Nation		民族	^CT("NAT")
	CT_Occupation		职业	^CT("OCC"
	CT_SocialStatus		患者身份	
	CT_City			^CT("CIT")
	CT_Country		国家	
	CT_Region		区域	^CT("RG")
4	CT_Province			^CT("PROV")
2.1.1.2卡信息表
序号	表名称	类名称	业务名称	存储
1	DHC_CardTypeDef	User.DHCCardTypeDef	卡类型表	　
4	DHC_CardStatusChange	User.DHCCardStatusChange	卡状态修改表(DHC_CardRef的子表)	　
5	DHC_CardRef	User.DHCCardRef	卡信息表	　
6	DHC_CardINVPRT	User.DHCCardINVPRT	卡发票表	　

2.1.2病人挂号分诊业务
2.1.2.1排班表
序号	表名称	类名称	业务名称	存储
1	RB_Resource	User.RBResource	资源表	　
4	RB_ResEffDate	User.RBResEffDate	班次表	　
5	RB_ResEffDateSession	User.RBResEffDateSession	排班模板表	　
	DHC_RBResEffDateSessAppQty	User.DHCRBResEffDateSessAppQty	预约分配记录表	
6	RB_ApptSchedule	User.RBApptSchedule	排班表	　
7	DHC_RBApptSchedule	User.DHCRBApptSchedule	排班扩展表	　
8	RBC_SessionType	User.RBCSessionType	出诊级别	　
	DHC_RBCASStatus	User.DHCRBCASStatus	排班状态表(正常,停诊)	
	DHC_TimeRange	User.DHCTimeRange	出诊时段表(上午,下午)	
	DHC_RBApptScheduleAppQty	User.DHCRBApptScheduleAppQty	预约分配表(DHC_RBApptSchedule的子表)	
	RBC_ReasonNotAvail	User.RBCReasonNotAvail	停替诊原因	
9	RBC_ClinicGroup	User.RBCClinicGroup	亚专业	　
2.1.2.2 预约表
序号	表名称	类名称	业务名称	存储
1	RBC_AppointMethod	User.RBCAppointMethod	预约方式	　
4	RB_Appointment	User. RBAppointment	预约表	　
5	DHC_RBAppointment	User.DHCRBCAppointment	预约表扩展表	　
6				　
7				　
8				　
9				　

2.1.2.3分诊挂号表
序号	表名称	类名称	业务名称	存储
1				
4	DHCQueue	User.DHCQueue	挂号队列表	　
5	DHCExaBorough	User.DHCExaBorough	分诊区	
6	DHCExaBorDep	User.DHCExaBorDep	分诊区科室对照	
7	DHCExaRoom	User.DHCExaRoom	诊室	　
	DHCDepMark	User.DHCDepMark	科室号别对照表	
	DHCFirstCode	User.DHCFirstCode	分诊优先状态表(优先, 正常)	
	DHCPerState	User.DHCPerState	分诊状态表(等候, 过号,到达, 报到)	
9	DHCMarkDoc	User.DHCMarkDoc	医生号别对照	　

2.1.2.3就诊表
序号	表名称	类名称	业务名称	存储
1	PA_Adm	User. PAAdm	就诊表	　
4	PAC_AdmTypeLocation		访问类型位置	^PAC("ADMLOC")
5				
6				
7				　
8				　
9				　

2.1.3病人就诊业务
2.1.3.1病人诊断表
序号	表名称	类名称	业务名称	存储
1	MR_Adm	User. CTCareProv	诊断主表	　^MR,^MRi
4	MR_Diagnos	User. MRDiagnos	诊断子表	　^MR
5	MR_DiagType	User.MRDiagType	诊断类型(MR_Diagnos的子表)	　
6				　
7				　
8				　
9				　

2.1.3.2 病人医嘱表
序号	表名称	类名称	业务名称	存储
1	OE_Order	User.OEOrder	医嘱主表	　
4	OE_OrdItem	User.OEOrdItem	医嘱子表(OE_Order的子表)	　
5	OE_OrdExec	User.OEOrdExec	医嘱执行记录表(OE_OrdItem的子表)	　
6	OE_OrdExecStatus	User.OEOrdExecStatus	医嘱执行状态表(OE_OrdExec的子表)	　
	OE_OrdItemExt	User.OEOrdItemExt	医嘱扩展表	
	OE_OrdExecExt	User.OEOrdExecExt	医嘱执行记录扩展表	
7	DHC_OEDispensing	User.DHCOEDispensing	药品分发表	　
8	PA_Que1	User.PAQue1	处方表	　
	DHC_OE_OrdItem	User.DHCOEOrdItem	表OE_OrdItem的扩展表	
	DHC_OE_OrdExec	User.DHCOEOrdExec	表OE_OrdExec的扩展表	
9				　
2.1.3.3过敏信息
序号	表名称	类名称	业务名称	存储
1	PA_Allergy		过敏记录	PA_Allergy
				
				
				
				
				
				
注意: PA_Allergy  为病人信息表PAPatMas 的子表,过敏信息在病人信息上保存.
2.1.3.4检查申请单
序号	表名称	类名称	业务名称	存储
1	DHCRB_ApplicationBill	User. DHCRBApplicationBill	申请单表	　
4	DHCRB_ApplicationBill_OrdItem	User. DHCRBApplicationBillOrdItem	申请单表对应医嘱	　
5	DHCRBC_Goal 	User. DHCRBCGoal	申请检查目的表	　

2.1.3.5住院证信息
序号	表名称	类名称	业务名称	存储
1	DHCDocIPBooking	User.DHCDocIPBooking	住院证表	　
4	DHCDocIPBKTemplate	User.DHCDocIPBKTemplate	住院证模板表	　
5	DHCDocIPBKTempDtl	User.DHCDocIPBKTempDtl	住院证模板明细表	　
6	DHCDocIPBKTempItem	User.DHCDocIPBKTempItem	住院证模板项目字典表	　
7				　
8				　
9				　

2.1.3.6 发药业务
序号	表名称	类名称	业务名称	存储
1	DHC_PHARWIN		门诊药房	　
4	DHC_PHDISPEN		发药表	　
5	DHC_PHDISITEM		发药明细	　
6				　
7	DHC_OEDispensing			　
8				　
9				　

2.1.3.7 门诊收费业务
序号	表名称	类名称	业务名称	存储
1	DHC_PatientBill		账单表	　
4	DHC_PatBillOrder			　
5	DHC_PatBillDetails			　
6	DHC_INVPRT 		门诊发票表	　
7	DHC_INVPayMode 		发票支付方式表	　
8	DHC_BillConINV		账单发票连接表	　
	DHC_INVPRTReports		门诊报表结算表	
	DHC_AccPayINV		集中打印发票表	
	DHC_AccPINVConPRT		集中打印发票表关联门诊发票表	
	DHC_AccManager		门诊账户表	
	DHC_AccPreDeposit		门诊预交金表	
	DHC_AccPayList		门诊消费表	
				
				
				
9	DHC_INVPRTReports		门诊报表结算表	　
	DHC_AccPayList		门诊消费表	
				
				
				
9	DHC_INVPRTReports	User. PACBedType	门诊报表结算表	　
2.1.3.8 医保业务
序号	表名称	类名称	业务名称	存储
1	INSU_DicData	User.INSUDicData	医保字典维护	　
6	INSU_TarItems	User.INSUTarItems	医保三大目录字典（药品、诊疗、服务设施）	　
7	INSU_TarContrast	User.INSUTarContrast	医保三大目录对照	　
9	INSU_AdmInfo	User.INSUAdmInfo	医保就诊信息	　
	INSU_Divide	User.INSUDivide	医保结算信息	
	INSU_DivideSub	User.INSUDivideSub	医保收费项分解表	

2.2 住院业务
2.2.1 住院登记
序号	表名称	类名称	业务名称	存储
1				
4				
5				
6				
7				
8				　
9				　
2.2.2 住院就诊
序号	表名称	类名称	业务名称	存储
1				　
4	PA_AdmTransaction	User.PAAdmTransaction	病人入院、出院、转床,转床信息表	　
5	PAC_EpisodeSubType		就诊子类型(区分普通病人还是绿色通道)	　
6	PAC_AdmCategory		许可分类(绿色通道或者非绿色通道)	　
7				　^MRC("OBITM")
8				　
				
				
				
				
				

2.2.3住院收费
序号	表名称	类名称	业务名称	存储
1	DHC_PatientBill		账单表	　
4	DHC_PatBillOrder		医护人员类别	　
5	DHC_PatBillDetails			　
6	DHC_INVPRTZY 		住院发票表	　
7	dhc_sfprintdetail		押金表	　
8	AR_Receipts，AR_RcptAlloc，AR_RcptPayMode		住院押金管理	　
	DHC_BillCondition		计费点	
				
				
				
				
2.2.4住院发药
序号	表名称	类名称	业务名称	存储
1	DHC_PHACollected	User.DHCPHACollected	住院发药主表	
4	DHC_PHACollectItm	User.DHCPHACollectItm	住院发药从表	
5	DHC_STDRUGREFUSE	User.DHCSTDRUGREFUSE	住院拒绝发药表	
6	IN_AdjSalePrice	User.INAdjSalePrice	调价表	
7				　
8				　
9				

2.2.5 临床,手麻业务
序号	表名称	类名称	业务名称	存储
1	DHC_AN_Arrange	User.DHCANArrange	手术排班表	^DHCANOPArrange 
4	DHC_ANC_OperRoom		手术间	^DHCANC("OPRoom”)
5	DHC_ANPreOperDrug	User.CTCareProv	术前用药记录	　^DHCANOPPreDrug
6	DHC_ANPreOperEval	User.PACWardRoom	术前评估	　^DHCANOPPreEval
7	DHC_AN_Order	User.DHCANOrder	术中医嘱记录表（用药、处置治疗、材料）	　
8	DHC_AN_VitalSign	User. DHCANVitalSign	病人生命体征记录表	　
9				

2.3 统计业务
序号	表名称	类名称	业务名称	存储
1	DHC_WorkLoad	无	无	原始数据表。用于存放所有进入系统的原始有效数据
4	DHC_WLCFG_Hospital	无	无	系统配置医院表。用于存放医院信息。
5	DHC_WLCFG_Group	无	DHC_WLCFG_SubGrp
DHC_WLCFGR_GrpDep
DHC_WLCFGR_GrpOrd	系统配置统计组表。用于存放统计组信息。
6	DHC_WLCFG_SubGrp	DHC_WLCFG_Group	DHC_WLCFGR_SubGrpDep
DHC_WLCFGR_SubGrpOrd	系统配置统计子组表。存放统计组下的统计子组信息。
7	DHC_WLCFGR_GrpDep	DHC_WLCFG_Group	无	系统配置统计组科室关系表。存放统计组中包含的科室。
8	DHC_WLCFGR_GrpOrd	DHC_WLCFG_Group	DHC_WLCFGR_GrpPlan	系统配置统计组医嘱关系表。存放统计组中包含的医嘱。
9	DHC_WLCFGR_GrpPlan	DHC_WLCFGR_GrpOrd	无	系统配置统计组计划表。存放统计组计划。

3.表明细
3.1 基础数据
3.1.1基础字典表
3.1.1.1医院表CT_Hospital
序号	数据项	业务含义	类型	备注
1	HOSP_RowId	　	RowId	　
2	HOSP_Code	代码	Text	　
3	HOSP_Desc	描述	Text	　
序号	数据项	业务含义	类型	备注
1	SSUSR_RowId	　	RowId	　
2	SSUSR_Initials	ID	Text	　
3	SSUSR_Name	Name	Text	　
4	SSUSR_Password	登陆密码	Text	　
5	SSUSR_DefaultDept_DR	登陆科室	DR	　
6	SSUSR_IsThisDoctor	是否为医生	Y/N	B/S不用
7	SSUSR_UseDeptAsDefault	登陆科室是否默认	Y/N	指向医护人员表 CTCareProv，B/S为空
8	SSUSR_CTPCP_DR	关联医护人员	DR	　
9	SSUSR_Group	安全组	DR	　
10	SSUSR_ChangeLocation	是否允许用户更改登陆科室	Y/N	默认同SSUSR_Name
11	SSUSR_EMailName	Name on E Mail system	Text	指向科室表 CT_LOC
12	SSUSR_DeptforEMRLists	Location for EMR lists	DR	指向语言表 SS_Language
13	SSUSR_CTLAN_DR	默认语言	DR	指向医护人员表 CTCareProv
14	SSUSR_CareProv_DR	关联医护人员	DR	　
15	SSUSR_Pin	签名密码	Text	　
16	SSUSR_PrivilegeStock	Privilege for Stock	Y/N	　
17	SSUSR_RetainOrderCategory	Retain Order Category	Y/N	指向表 PA_Adm
18	SSUSR_LastPAADM_DR	Last PAADM	DR	　
19	SSUSR_Active	用户激活	Y/N	　
20	SSUSR_DRGTariffVisible	DRG Tariff Visible	Y/N	指向表 BLC_BillSequence
21	SSUSR_BillSequence_DR	　	DR	　
22	SSUSR_SearchAllAdm	　	Y/N	　
23	SSUSR_Inpatient	　	Y/N	　
24	SSUSR_Outpatient	　	Y/N	　
25	SSUSR_Emergency	　	Y/N	　
26	SSUSR_OwnPatientsOnly	　	Y/N	指向表 CT_LocationList
27	SSUSR_LocList_DR	　	DR	　
28	SSUSR_AutoAuthorise	　	Y/N	指向表 ARC_ItmMast
29	SSUSR_DefaultARCIM_DR	　	DR	指向表 CT_Loc
30	SSUSR_DefRBDepartment_DR	　	DR	指向表 RB_Resource
31	SSUSR_DefRBResource_DR	　	DR	指向表 RBC_Services
32	SSUSR_DefRBService_DR	　	DR	　
33	SSUSR_DefEpisode	　	　	　
34	SSUSR_LinkToBedManagement	　	　	　
35	SSUSR_UseDefaultEpisDep	　	　	　
36	SSUSR_WarnORBookingMoveRes	　	　	　
37	SSUSR_NAllORBookPast	　	　	　
38	SSUSR_NAllORBookNoSess	　	　	　
39	SSUSR_NAllORBookNA	　	　	　
40	SSUSR_AlwaysUseSoundex	　	　	　
41	SSUSR_RBNumberOfRows	　	　	　
42	SSUSR_MultiSelectRows	　	　	　
43	SSUSR_PasswordDate	　	　	　
44	SSUSR_DateLastLogin	　	　	　
45	SSUSR_TimeLastLogin	　	　	　
46	SSUSR_DateFromToday	　	　	　
47	SSUSR_DateToToday	　	　	　
48	SSUSR_DefRefHosp_DR	　	　	　
49	SSUSR_ResEntryButtons	　	　	　
50	SSUSR_DefaultResEntryButtons	　	　	　
51	SSUSR_DefDateinOE	　	　	　
52	SSUSR_DefDateInDisch	　	　	　
53	SSUSR_DisableEMRPreadm	　	　	　
54	SSUSR_SearchPrevAdm	　	　	　
55	SSUSR_NoOrders	　	　	　
56	SSUSR_NoEMR	　	　	　
57	SSUSR_NoDiagnosis	　	　	　
58	SSUSR_WebSecurityAccess	　	　	　
59	SSUSR_EpisSubType_DR	　	　	　
60	SSUSR_NotReadResults	　	　	　
61	SSUSR_RestrictModifDischarge	　	　	　
62	SSUSR_Booked	　	　	　
63	SSUSR_Admitted	　	　	　
64	SSUSR_Discharged	　	　	　
65	SSUSR_DefaultCareProv	　	　	　
66	SSUSR_DefaultLocation	　	　	　
67	SSUSR_PasswordChanged	　	　	　
68	SSUSR_Title	　	　	　
69	SSUSR_Surname	　	　	　
70	SSUSR_GivenName	　	　	　
71	SSUSR_OtherName	　	　	　
72	SSUSR_DepartmentHead	　	　	　
73	SSUSR_PayrollNumber	　	　	　
74	SSUSR_StaffType_DR	　	　	　
75	SSUSR_Comments	　	　	指向SS_User
76	SSUSR_LastUpdateUser_DR	最后更新人	DR	　
77	SSUSR_LastUpdateDate	最后更新日期	Date	　
78	SSUSR_LastUpdateTime	最后更新时间	Time	　
79	SSUSR_DoctorFlag	DoctorFlag	Y/N	　
80	SSUSR_NurseFlag	NurseFlag	Y/N	　
81	SSUSR_SecurityMsgRead	　	　	　
82	SSUSR_SecurityMessage	　	　	　
83	SSUSR_LoginID	　	　	　
84	SSUSR_LoginRound	LoginRound	Y/N	　
85	SSUSR_DefAllResources	　	　	　
86	SSUSR_DefApptSlots	　	　	　
87	SSUSR_DefUseStartTimeEachday	　	　	　
88	SSUSR_DefAppointMeth_DR	　	　	　
89	SSUSR_Title_DR	　	　	　
90	SSUSR_RegistrationNumber	　	　	　
91	SSUSR_PrintSecurityLevel	　	　	指向医院表 CT_Hospital
92	SSUSR_LastUpdateUserHosp_DR	　	DR	　
93	SSUSR_ChangeLocWithinLogHosp	　	Y/N	　
94	SSUSR_NotAllowToOverbook	　	Y/N	　
95	SSUSR_MarkInactiveDate	　	　	　
96	SSUSR_MarkInactiveTime	　	　	　
97	SSUSR_MarkInactiveUser_DR	　	　	　
98	SSUSR_DateFrom	生效日期	Date	　
99	SSUSR_DateTo	截止日期	Date	指向医院表 CT_Hospital
100	SSUSR_Hospital_DR	医院	DR	　
101	SSUSR_Mobile	　	　	　
102	SSUSR_Pager	　	　	　
103	SSUSR_Email	　	　	　
104	SSUSR_LocationNotMandatoryOnResEntry	　	　	　
105	SSUSR_TimeSinceLastAppt	　	　	　
106	SSUSR_TimeSincePeriod	　	　	　
107	SSUSR_Name1	　	　	　
108	SSUSR_Name2	　	　	　
109	SSUSR_Name3	　	　	　
110	SSUSR_IEPath	　	　	　
111	SSUSR_ExternalUserIdentifier	　	　	　
112	SSUSR_CashierShift	　	　	　
113	SSUSR_BioKey	　	　	　
114	SSUSR_BioMode	　	　	　
115	SSUSR_DisclaimerSigned	　	　	　
116	SSUSR_CreatedBy_DR	　	　	　
117	SSUSR_CreatedDate	　	　	　
118	SSUSR_CreatedTime	　	　	　
119	SSUSR_YesNo1	　	　	　
120	SSUSR_YesNo2	　	　	　
121	SSUSR_YesNo3	　	　	　
122	SSUSR_YesNo4	　	　	　
123	SSUSR_YesNo5	　	　	　
124	SSUSR_FreeText1	　	　	　
125	SSUSR_FreeText2	　	　	　
126	SSUSR_FreeText3	　	　	　
127	SSUSR_AllowWebLayoutManager	　	　	　
128	SSUSR_AllowWebColumnManager	　	　	　
3.1.2用户表SS_User
3.1.3科室表  CT_Loc
序号	数据项	业务含义	类型	备注
1	CTLOC_RowID	　	RowId	　
2	CTLOC_Code	代码	Text	　
3	CTLOC_Desc	描述	Text	　
4	CTLOC_GLCCC_DR	成本中心	DR	指向成本中心表GLC_CC
5	CTLOC_Password	　	Text	　
6	CTLOC_WardFlag	是否为病区	Y/N	　
7	CTLOC_Address	地址	Text	　
8	CTLOC_ActiveFlag	　	Y/N	　
9	CTLOC_Cashier_DR	　	DR	指向科室表 CT_Loc
10	CTLOC_OTC_DR	　	DR	指向科室表 CT_Loc
11	CTLOC_StartTime	　	Time	　
12	CTLOC_EndTime	　	Time	　
13	CTLOC_OwnQueFlag	　	Y/N	　
14	CTLOC_RecQueFlag	　	Y/N	　
15	CTLOC_Type	科室类型	Mul C	W||Ward,,E||Execute, DI||Drug Injection, D||Dispensing, C||Cashier,O||Other， OP||Operating Theatre, EM||Emergency,  DS||Day Surgery,MR||Medical Records, OR||OutPatient Consulting Room, CL||Clinic,ADM||Admission Point
16	CTLOC_DispLoc_DR	　	DR	指向科室表CT_Loc
17	CTLOC_Floor	科室地面	Text	　
18	CTLOC_NFMI_DR	　	DR	指向政府部门表CT_NFMI_CategDepart
19	CTLOC_Laundry	　	Y/N	　
20	CTLOC_Dep_DR	部门组	DR	指向科室部门组表 RBC_DepartmentGroup 
21	CTLOC_DifferentSexPatients	Single Sex Ward	Mul C	D||Does Not Matter, W||Warning,        N||Not Allowed
22	CTLOC_Index	　	Y/N	　
23	CTLOC_Hospital_DR	医院	DR	指向医院表CT_Hospital
24	CTLOC_ExecuteConfirmation	　	Y/N	　
25	CTLOC_DateActiveFrom	生效日期	Date	　
26	CTLOC_DateActiveTo	截止日期	Date	　
27	CTLOC_RehabilitativeFlag	复原标志	Y/N	　
28	CTLOC_MedicalRecordActive	在此科室病历可用	Y/N	　
29	CTLOC_DefaultMRType_DR	　	DR	指向病案类型表RTC_MRecordType
30	CTLOC_ResultDelivery	收集	Y/N	　
31	CTLOC_RespUnit_DR	Responsible Unit	DR	指向表  CT_ResponsibleUnit 
32	CTLOC_PatientAgeSexMix_DR	　	DR	指向表 PAC_PatientAgeSexMix
33	CTLOC_IntendClinCareIntensity_DR	　	DR	指向表 PAC_IntendClinCareIntens
34	CTLOC_BroadPatientGroup_DR	　	DR	指向表 PAC_BroadPatientGroup
35	CTLOC_WeeklyAvailIndicator	Weekly Availability	Y/N	　
36	CTLOC_OpenOvernightIndicator	Open Overnight	Y/N	　
37	CTLOC_SignifFacility_DR	　	DR	指向表 CT_SignificantFacility
38	CTLOC_NotUsed	　	Text	　
39	CTLOC_ExtGroup_DR	　	DR	指向表 CTLOC_ExtGroup_DR
40	CTLOC_ExternalInfoSystem	　	Mul C	Kestral,AusLab,Apex,Merlin Rx,Pyxis Rx,Cardiobase,ClinPath,Triple G,Quest Diagnostics,HBCIS Imaging,EBM,Mitra PACS,GE PACS,AGFA PACS,LabTrak,Sonic Apollo
41	CTLOC_Telephone	Telephone	Text	　
42	CTLOC_TelephoneExt	Ext.	Text	地坛医院订餐接口 ，固定4位，科室Rowid
43	CTLOC_HL7OrdersLink	　	DR	指向表SS_HL7
44	CTLOC_ContactName	ContactName	Text	地坛医院订餐接口 ，科室拼音头字母
45	CTLOC_FloorplanQuery	　	Mul C	E||Emergency,R||Emergency - RIE, B||Emergency B & R"
46	CTLOC_VisitHrFrom	　	Time	　
47	CTLOC_VisitHrTo	　	Time	　
48	CTLOC_RestPeriodFrom	　	Time	　
49	CTLOC_RestPeriodTo	　	Time	　
50	CTLOC_AgeFrom	　	Number	　
51	CTLOC_AgeTo	　	Number	　
52	CTLOC_NationCode	　	Text	　
53	CTLOC_OrdersToRecLoc	　	Mul C	P||On patient payment,O||On order entry
54	CTLOC_SendHL7MessageOn	　	Mul C	OE||Order Entry,SC||Specimen Collection, PA||Patient Arrive,APPT||Appointment & Pt Arrive,APC||Appointments Created,NRA||Non Radiology Appointment,SR||Specimen Receive
55	CTLOC_DepartmentHeadUserDR	　	DR	指向表 SS_User
56	CTLOC_PagerNo	　	Text	　
57	CTLOC_Email	　	Text	　
58	CTLOC_Fax	　	Text	　
59	CTLOC_DaysAutoGenerate	　	Number	　
60	CTLOC_MRRequestMoveValid	　	Y/N	　
61	CTLOC_SNAPFlag	　	Y/N	　
62	CTLOC_MultDateRangesVisitHrs	　	Text	　
63	CTLOC_MentalHealthUnit	　	Y/N	　
64	CTLOC_PreferedOutlierWard	　	DR	指向病区表 CTLOC_PreferedOutlierWard
65	CTLOC_WardSingleSex	　	DR	指向性别表 CT_Sex
66	CTLOC_PrintLabelsUrgMRRequest	　	Y/N	　
67	CTLOC_EnableDischargeAllHyperlink	　	Y/N	　
68	CTLOC_InPatientUnit	　	Y/N	　
69	CTLOC_OutPatientUnit	　	Y/N	　
70	CTLOC_TimeSinceLastAppt	　	Number	　
71	CTLOC_Period	　	Mul C	D||Day,M||Month,Y||Year
72	CTLOC_DischSumNotRequired	　	Y/N	　
73	CTLOC_NatCodeDateFrom	　	Date	　
74	CTLOC_NatCodeDateTo	　	Date	　
75	CTLOC_SignFacilDateFrom	　	Date	　
76	CTLOC_SignifFacilDateTo	　	Date	　
77	CTLOC_DischargeLounge	　	Y/N	　
78	CTLOC_ExternalViewerLink	　	Text	　
79	CTLOC_DaysToKeepRecord	　	Number	　
80	CTLOC_NATAHeadings	　	Text	　
81	CTLOC_WeeksSuspensionReview	　	Number	　
82	CTLOC_DaysForOPDOffer	　	Number	　
83	CTLOC_DaysForOPLetterResponse	　	Number	　
84	CTLOC_OffersBeforeIP_OPWaitReset	　	Number	　
85	CTLOC_DaysOfferOutcomeChange	　	Number	　
86	CTLOC_RadOrdAccessNoPrefix	　	Text	　
3.1.4 病区表PAC_Ward
序号	数据项	业务含义	类型	备注
1	WARD_RowID	　	RowId	　
2	WARD_Code	代码	Text	　
3	WARD_Desc	描述	Text	　
4	WARD_RoomDR	房间	DR	指向 PAC_Room
5	WARD_SingleRoom	单一房间	Y/N	　
6	WARD_LocationDR	在科室表RowID	DR	指向科室表CT_Loc
7	WARD_Active	激活	Y/N	　
8	WARD_InactiveDateFrom	　	Date	　
9	WARD_InactiveTimeFrom	　	Time	　
10	WARD_InactiveDateTo	　	Date	　
11	WARD_InactiveTimeTo	　	Time	　
12	WARD_ViewLinkedRooms	　	Y/N	　
13	WARD_ViewNextMostUrgent	　	Y/N	　
序号	数据项	业务含义	类型	备注
1	CTPCP_RowId1	　	RowID	　
2	CTPCP_Code	代码	Text	　
3	CTPCP_Desc	描述	Text	　
4	CTPCP_Id	　	Text	　
5	CTPCP_Category	　	Text	　
6	CTPCP_SMCNo	SMC号码	Text	　
7	CTPCP_CarPrvTp_DR	类型	DR	指向医护人员类型表CT_CarPrvTp
8	CTPCP_AddrType_DR	　	DR	指向 CT_AddrType
9	CTPCP_Blk	街区号	Text	　
10	CTPCP_StName	街道名字	Text	　
11	CTPCP_Level	楼层数	Text	　
12	CTPCP_Unit	单元号	Text	　
13	CTPCP_City_DR	城市	DR	指向表 CT_City
14	CTPCP_State_DR	国家	DR	指向表 CT_State
15	CTPCP_Zip_DR	邮编	DR	指向表 CT_Zip
16	CTPCP_Spec_DR	专长	DR	指向表 CT_Spec
17	CTPCP_SubSpec_DR	其它专长	DR	指向表 CT_Spec
18	CTPCP_TelO	电话号码(办公室)	Text	　
19	CTPCP_TelOExt	电话号码(分机)	Text	　
20	CTPCP_TelH	电话号码(家)	Text	　
21	CTPCP_PagerNo	Pager Number	Text	　
22	CTPCP_Hosp_DR	咨询医院	DR	指向表 CT_RefClin
23	CTPCP_Con1Code_DR	　	DR	指向表 ARC_ItmMast
24	CTPCP_Con2Code_DR	　	DR	指向表 ARC_ItmMast
25	CTPCP_ActiveFlag	激活	Y/N	　
26	CTPCP_VersionOrigin_DR	　	DR	指向表 CT_CareProv
27	CTPCP_VersionNumber	　	Text	　
28	CTPCP_VersionDate	　	Date	　
29	CTPCP_VersionTime	　	Time	　
30	CTPCP_VersionDateTime	　	Compute	s {CTPCP_VersionDateTime}=$p({CTPCP_VersionDate},$c(1))_"Z"_$p({CTPCP_VersionTime},$c(2))
31	CTPCP_AuthorID	　	Text	　
32	CTPCP_SpecialistYN	　	Y/N	　
33	CTPCP_FirstDigitInQueue	队列码的首位数字	Text	　
34	CTPCP_DateActiveFrom	生效日期	Date	　
35	CTPCP_DateActiveTo	截止日期	Date	　
36	CTPCP_LinkDoctor_DR	　	DR	指向表 CT_CareProv
37	CTPCP_AllocatedDoctor	　	Y/N	　
38	CTPCP_Surgeon	是外科医生	Y/N	　
39	CTPCP_Anaesthetist	是麻醉师	Y/N	　
40	CTPCP_PrescriberNumber	　	Text	　
41	CTPCP_CPGroup_DR	　	DR	指向表 CT_CareProvGroup
42	CTPCP_RespUnit_DR	　	DR	指向表 CT_ResponsibleUnit
43	CTPCP_CTLOC_DR	　	DR	指向表 CT_Loc
44	CTPCP_Title	Title	Text	　
45	CTPCP_DOB	Date Of Birth	Text	　
46	CTPCP_MobilePhone	MobilePhone	Text	　
47	CTPCP_Fax	Fax No.	Text	　
48	CTPCP_MailList	Mail List	Text	　
49	CTPCP_Email	Email	Text	　
50	CTPCP_PrefConMethod	　	Text	　
51	CTPCP_TextOne	　	Text	　
52	CTPCP_TextTwo	　	Text	　
53	CTPCP_ContactFirstOn	　	Text	　
54	CTPCP_Radiologist	　	Y/N	　
55	CTPCP_AdmittingRights	　	Y/N	　
56	CTPCP_Acceptance	　	Y/N	　
57	CTPCP_Previous	　	Y/N	　
58	CTPCP_MantouxTest	　	Y/N	　
59	CTPCP_Continuing	　	Y/N	　
60	CTPCP_New	　	Y/N	　
61	CTPCP_PrefMailAddFlad	　	Mul C	H||Home,I||Internal,R||Room
62	CTPCP_UpdateDate	最后更新日期	Date	　
63	CTPCP_UpdateTime	最后更新时间	Time	　
64	CTPCP_UpdateUser_DR	最后更新人	DR	指向表 SS_User
65	CTPCP_BestContactTime	　	Text	　
66	CTPCP_ReferralDoctor_DR	　	DR	指向表 PAC_RefDoctor
67	CTPCP_FirstName	First Name	Text	　
68	CTPCP_OtherName	Other Name	Text	　
69	CTPCP_Title_DR	　	DR	指向表 CT_Title
70	CTPCP_Surname	Surname	Text	　
71	CTPCP_HICApproved	　	Y/N	　
72	CTPCP_PractitionerFlag1	　	Y/N	　
73	CTPCP_RowId	　	RowID	　
3.1.5医护人员表CT_CareProv
3.1.6患者(身份)类型  CT_SocialStatus
序号	数据项	业务含义	类型	备注
1	SS_RowId	　	RowId	　
2	SS_Code	代码	Text	　
3	SS_Desc	描述	Text	　
3.1.7患者费别  PAC_AdmReason
序号	数据项	业务含义	类型	备注
1	REA_RowId	　	RowId	　
2	REA_Code	代码	Text	　
3	REA_Desc	描述	Text	　
4	REA_DateFrom	生效日期	Date	　
5	REA_DateTo	截止日期	Date	　
6	REA_NationalCode	　	Text	　
7	REA_AgeFrom	　	Number	　
8	REA_AgeTo	　	Number	　
9	REA_InPatAdm_DR	　	Text	　
10	REA_AdmSource	　	Text	　
11	REA_QualifStatus	　	Text	　
12	REA_CareType	　	Text	　
13	REA_EpisSubType	　	Text	　
14	REA_AgeType	　	Mul C	M||Month,D||Days,Y||Year
15	REA_Age1From	　	Number	　
16	REA_Age1To	　	Number	　
17	REA_Age1Type	　	Mul C	M||Month,D||Days,Y||Year
3.1.8病人信息字典表
3.1.8.1性别表CT_Sex
序号	数据项	业务含义	类型	备注
	CTSEX_Code	性别代码	Text	1
	CTSEX_Desc	性别描述	Text	40
	CTSEX_GrouperCode	分组代码	Text	10
	CTSEX_RowId		Row ID	16

3.1.8.2邮编表CT_Zip
序号	数据项	业务含义	类型	备注
	CTZIP_Active	是否为默认值	Yes/No	4
	CTZIP_CityAreaDesc	城市所在地区描述	Text	30
	CTZIP_CITYAREA_DR	指向城市区域表CT_CityArea的Row ID	DR	19
	CTZIP_CityDesc	城市描述	Text	30
	CTZIP_CITY_DR	指向城市表CT_City的Row ID	DR	16
	CTZIP_Code	邮编代码	Text	8
	CTZIP_Complement	补充说明	Text	30
	CTZIP_Desc	邮编描述	Text	40
	CTZIP_HCA_DR	指向健康监护区域CT_HealthCareArea表的Row ID	DR	16
	CTZIP_Province_DR	指向所在省市表CT_Province的Row ID	DR	16
	CTZIP_Region_DR	指向区域表CT_Regiona的Row ID	DR	16
	CTZIP_Remark	备注	Text	25
	CTZIP_RowId	标识号	Row ID	16
	CTZIP_Type	邮编类别	Multiple Choice	8

3.1.8.3出生地表、城市表CT_City
序号	数据项	业务含义	类型	备注
	CTCIT_Code	城市代码	Text	6
	CTCIT_Desc	城市描述	Text	20
	CTCIT_FiscalPrefix	前缀	Text	30
	CTCIT_Province_DR	指向所在省市表CT_Province的Row ID	DR	16
	CTCIT_RowId	标识号	Row ID	16
3.1.8.4婚姻状况表 CT_Marital
序号	数据项	业务含义	类型	备注
	CTMAR_RowId	标识号	Row ID
	CTMAR_Code	婚姻状况代码 	Text
	CTMAR_Desc	婚姻状况描述	Text
	CTMAR_PRS2	PRS2	Text

3.1.8.5职业表 CT_Occupation
序号	数据项	业务含义	类型	备注
	CTOCC_RowId	标识号	Row ID
	CTOCC_Code	职业代码	Text
	CTOCC_Desc	职业描述	Text

3.1.8.6病人血型表PAC_BloodType
序号	数据项	业务含义	类型	备注
	BLDT_RowId	标识号	Row ID
	BLDT_Code	病人血型代码	Text
	BLDT_Desc	病人血型描述	Text

3.1.8.7教育水平表CT_Education
序号	数据项	业务含义	类型	备注
1	EDU_RowId	标识号	Row ID
2	EDU_Code	教育水平代码	Text
3	EDU_Desc	教育水平描述	Text
3.1.8出诊级别  RBC_SessionType
序号	数据项	业务含义	类型	备注
1	SESS_RowId	　	RowID	　
2	SESS_Code	代码	Text	　
3	SESS_Desc	描述	Text	　
4	SESS_SessionType_DR	　	DR	指向 RBC_SessionType
5	SESS_NumberOfDays	天数	Number	　
6	SESS_EnableByDefault	默认允许	Y/N	　
7	SESS_DateFrom	生效日期	Date	　
8	SESS_DateTo	截止日期	Date	　
9	SESS_ReleaseDays	　	Number	　
10	SESS_ConvertPeriod	　	Number	mins
11	SESS_GenFrequency	　	Number	D||Day,M||Month,W||Week,Y||Year
12	SESS_GenPeriod	　	Mul C	　
3.1.9预约方式  RBC_AppointMethod
序号	数据项	业务含义	类型	备注
1	APTM_RowId	　	RowID	　
2	APTM_Code	代码	Text	　
3	APTM_Desc	描述	Text	　
4	APTM_CollectMoney	Collect Money	Y/N	　
5	APTM_DateFrom	生效日期	Date	　
6	APTM_DateTo	截止日期	Date	　
3.1.2三大项基础信息
3.1.2.1医嘱大类  OEC_OrderCategory     
序号	数据项	业务含义	类型	备注
1	ORCAT_RowId	　	RowID	　
2	ORCAT_Code	代码	Text	　
3	ORCAT_Desc	描述	Text	　
4	ORCAT_RepeatInOrder	重复医嘱	Y/N	　
5	ORCAT_OrderSeqNo	医嘱顺序号	Number	　
6	ORCAT_IconName	Icon Name	Text	　
7	ORCAT_IconPriority	Icon Priority	Text	　
8	ORCAT_Questionnaire_DR	　	DR	指向表 SS_UserDefWindow
9	ORCAT_HrsResultOverdue	　	Number	　
10	ORCAT_IconApptsMade	　	Text	　
11	ORCAT_IconResultOverdue	　	Text	　
12	ORCAT_CounterTypeDR	　	DR	指向表 PAC_CounterType
13	ORCAT_ShowIconBeforeEndDate	　	Y/N	　
14	ORCAT_NoShowIconAfterExcecut	　	Y/N	　
15	ORCAT_IconDisplayAfterExec	　	Text	　
16	ORCAT_OCGroup_DR	　	DR	目前用于标记“检查”，指向表 OEC_OrderCategoryGroup
17	ORCAT_PrescrExpDays	　	Number	　
18	ORCAT_PrescrRepeatDays	　	Number	　
19	ORCAT_IVExpiry	　	Number	　
20	ORCAT_DoNotDCOnAdmDisch	　	Y/N	　
21	ORCAT_DoNotDCOnAdmCancel	　	Y/N	　
22	ORCAT_PhoneOrderReviewTime	　	Number	　
23	ORCAT_ApplyBatchPricing	　	Y/N	　
3.1.2.2医嘱子类  ARC_ItemCat
序号	数据项	业务含义	类型	备注
1	CTPCP_RowId1	　	RowID	　
2	CTPCP_Code	代码	Text	　
3	CTPCP_Desc	描述	Text	　
4	CTPCP_Id	　	Text	　
5	CTPCP_Category	　	Text	　
6	CTPCP_SMCNo	SMC号码	Text	　
7	CTPCP_CarPrvTp_DR	类型	DR	指向医护人员类型表CT_CarPrvTp
8	CTPCP_AddrType_DR	　	DR	指向 CT_AddrType
9	CTPCP_Blk	街区号	Text	　
10	CTPCP_StName	街道名字	Text	　
11	CTPCP_Level	楼层数	Text	　
12	CTPCP_Unit	单元号	Text	　
13	CTPCP_City_DR	城市	DR	指向表 CT_City
14	CTPCP_State_DR	国家	DR	指向表 CT_State
15	CTPCP_Zip_DR	邮编	DR	指向表 CT_Zip
16	CTPCP_Spec_DR	专长	DR	指向表 CT_Spec
17	CTPCP_SubSpec_DR	其它专长	DR	指向表 CT_Spec
18	CTPCP_TelO	电话号码(办公室)	Text	　
19	CTPCP_TelOExt	电话号码(分机)	Text	　
20	CTPCP_TelH	电话号码(家)	Text	　
21	CTPCP_PagerNo	Pager Number	Text	　
22	CTPCP_Hosp_DR	咨询医院	DR	指向表 CT_RefClin
23	CTPCP_Con1Code_DR	　	DR	指向表 ARC_ItmMast
24	CTPCP_Con2Code_DR	　	DR	指向表 ARC_ItmMast
25	CTPCP_ActiveFlag	激活	Y/N	　
26	CTPCP_VersionOrigin_DR	　	DR	指向表 CT_CareProv
27	CTPCP_VersionNumber	　	Text	　
28	CTPCP_VersionDate	　	Date	　
29	CTPCP_VersionTime	　	Time	　
30	CTPCP_VersionDateTime	　	Compute	s {CTPCP_VersionDateTime}=$p({CTPCP_VersionDate},$c(1))_"Z"_$p({CTPCP_VersionTime},$c(2))
31	CTPCP_AuthorID	　	Text	　
32	CTPCP_SpecialistYN	　	Y/N	　
33	CTPCP_FirstDigitInQueue	队列码的首位数字	Text	　
34	CTPCP_DateActiveFrom	生效日期	Date	　
35	CTPCP_DateActiveTo	截止日期	Date	　
36	CTPCP_LinkDoctor_DR	　	DR	指向表 CT_CareProv
37	CTPCP_AllocatedDoctor	　	Y/N	　
38	CTPCP_Surgeon	是外科医生	Y/N	　
39	CTPCP_Anaesthetist	是麻醉师	Y/N	　
40	CTPCP_PrescriberNumber	　	Text	　
41	CTPCP_CPGroup_DR	　	DR	指向表 CT_CareProvGroup
42	CTPCP_RespUnit_DR	　	DR	指向表 CT_ResponsibleUnit
43	CTPCP_CTLOC_DR	　	DR	指向表 CT_Loc
44	CTPCP_Title	Title	Text	　
45	CTPCP_DOB	Date Of Birth	Text	　
46	CTPCP_MobilePhone	MobilePhone	Text	　
47	CTPCP_Fax	Fax No.	Text	　
48	CTPCP_MailList	Mail List	Text	　
49	CTPCP_Email	Email	Text	　
50	CTPCP_PrefConMethod	　	Text	　
51	CTPCP_TextOne	　	Text	　
52	CTPCP_TextTwo	　	Text	　
53	CTPCP_ContactFirstOn	　	Text	　
54	CTPCP_Radiologist	　	Y/N	　
55	CTPCP_AdmittingRights	　	Y/N	　
56	CTPCP_Acceptance	　	Y/N	　
57	CTPCP_Previous	　	Y/N	　
58	CTPCP_MantouxTest	　	Y/N	　
59	CTPCP_Continuing	　	Y/N	　
60	CTPCP_New	　	Y/N	　
61	CTPCP_PrefMailAddFlad	　	Mul C	H||Home,I||Internal,R||Room
62	CTPCP_UpdateDate	最后更新日期	Date	　
63	CTPCP_UpdateTime	最后更新时间	Time	　
64	CTPCP_UpdateUser_DR	最后更新人	DR	指向表 SS_User
65	CTPCP_BestContactTime	　	Text	　
66	CTPCP_ReferralDoctor_DR	　	DR	指向表 PAC_RefDoctor
67	CTPCP_FirstName	First Name	Text	　
68	CTPCP_OtherName	Other Name	Text	　
69	CTPCP_Title_DR	　	DR	指向表 CT_Title
70	CTPCP_Surname	Surname	Text	　
71	CTPCP_HICApproved	　	Y/N	　
72	CTPCP_PractitionerFlag1	　	Y/N	　
73	CTPCP_RowId	　	RowID	　
3.1.2.3医嘱项 ARC_ItmMast
序号	数据项	业务含义	类型	备注
1	CTPCP_RowId1	　	RowID	　
2	CTPCP_Code	代码	Text	　
3	CTPCP_Desc	描述	Text	　
4	CTPCP_Id	　	Text	　
5	CTPCP_Category	　	Text	　
6	CTPCP_SMCNo	SMC号码	Text	　
7	CTPCP_CarPrvTp_DR	类型	DR	指向医护人员类型表CT_CarPrvTp
8	CTPCP_AddrType_DR	　	DR	指向 CT_AddrType
9	CTPCP_Blk	街区号	Text	　
10	CTPCP_StName	街道名字	Text	　
11	CTPCP_Level	楼层数	Text	　
12	CTPCP_Unit	单元号	Text	　
13	CTPCP_City_DR	城市	DR	指向表 CT_City
14	CTPCP_State_DR	国家	DR	指向表 CT_State
15	CTPCP_Zip_DR	邮编	DR	指向表 CT_Zip
16	CTPCP_Spec_DR	专长	DR	指向表 CT_Spec
17	CTPCP_SubSpec_DR	其它专长	DR	指向表 CT_Spec
18	CTPCP_TelO	电话号码(办公室)	Text	　
19	CTPCP_TelOExt	电话号码(分机)	Text	　
20	CTPCP_TelH	电话号码(家)	Text	　
21	CTPCP_PagerNo	Pager Number	Text	　
22	CTPCP_Hosp_DR	咨询医院	DR	指向表 CT_RefClin
23	CTPCP_Con1Code_DR	　	DR	指向表 ARC_ItmMast
24	CTPCP_Con2Code_DR	　	DR	指向表 ARC_ItmMast
25	CTPCP_ActiveFlag	激活	Y/N	　
26	CTPCP_VersionOrigin_DR	　	DR	指向表 CT_CareProv
27	CTPCP_VersionNumber	　	Text	　
28	CTPCP_VersionDate	　	Date	　
29	CTPCP_VersionTime	　	Time	　
30	CTPCP_VersionDateTime	　	Compute	s {CTPCP_VersionDateTime}=$p({CTPCP_VersionDate},$c(1))_"Z"_$p({CTPCP_VersionTime},$c(2))
31	CTPCP_AuthorID	　	Text	　
32	CTPCP_SpecialistYN	　	Y/N	　
33	CTPCP_FirstDigitInQueue	队列码的首位数字	Text	　
34	CTPCP_DateActiveFrom	生效日期	Date	　
35	CTPCP_DateActiveTo	截止日期	Date	　
36	CTPCP_LinkDoctor_DR	　	DR	指向表 CT_CareProv
37	CTPCP_AllocatedDoctor	　	Y/N	　
38	CTPCP_Surgeon	是外科医生	Y/N	　
39	CTPCP_Anaesthetist	是麻醉师	Y/N	　
40	CTPCP_PrescriberNumber	　	Text	　
41	CTPCP_CPGroup_DR	　	DR	指向表 CT_CareProvGroup
42	CTPCP_RespUnit_DR	　	DR	指向表 CT_ResponsibleUnit
43	CTPCP_CTLOC_DR	　	DR	指向表 CT_Loc
44	CTPCP_Title	Title	Text	　
45	CTPCP_DOB	Date Of Birth	Text	　
46	CTPCP_MobilePhone	MobilePhone	Text	　
47	CTPCP_Fax	Fax No.	Text	　
48	CTPCP_MailList	Mail List	Text	　
49	CTPCP_Email	Email	Text	　
50	CTPCP_PrefConMethod	　	Text	　
51	CTPCP_TextOne	　	Text	　
52	CTPCP_TextTwo	　	Text	　
53	CTPCP_ContactFirstOn	　	Text	　
54	CTPCP_Radiologist	　	Y/N	　
55	CTPCP_AdmittingRights	　	Y/N	　
56	CTPCP_Acceptance	　	Y/N	　
57	CTPCP_Previous	　	Y/N	　
58	CTPCP_MantouxTest	　	Y/N	　
59	CTPCP_Continuing	　	Y/N	　
60	CTPCP_New	　	Y/N	　
61	CTPCP_PrefMailAddFlad	　	Mul C	H||Home,I||Internal,R||Room
62	CTPCP_UpdateDate	最后更新日期	Date	　
63	CTPCP_UpdateTime	最后更新时间	Time	　
64	CTPCP_UpdateUser_DR	最后更新人	DR	指向表 SS_User
65	CTPCP_BestContactTime	　	Text	　
66	CTPCP_ReferralDoctor_DR	　	DR	指向表 PAC_RefDoctor
67	CTPCP_FirstName	First Name	Text	　
68	CTPCP_OtherName	Other Name	Text	　
69	CTPCP_Title_DR	　	DR	指向表 CT_Title
70	CTPCP_Surname	Surname	Text	　
71	CTPCP_HICApproved	　	Y/N	　
72	CTPCP_PractitionerFlag1	　	Y/N	　
73	CTPCP_RowId	　	RowID	　
3.1.2.4 频次表PHC_Freq
序号	数据项	业务含义	类型	备注
1	PHCD_RowID	　	RowID	　
2	PHCD_Code	代码	Text	　
3	PHCD_Name	描述	Text	　
4	PHCD_MIMSNo	MIMS No	Number	　
5	PHCD_PHCSC_DR	药理学子分类	DR	指向表 PHC_SubCat
6	PHCD_Logo	Logo - MIMS info	Text	　
7	PHCD_ProductName	Full name of the product	Text	　
8	PHCD_PHCPO_DR	管制分类	DR	指向表 PHC_Poison
9	PHCD_Stat	Stat - MIMS	Text	　
3.1.2.5用药途径(方式)  PHC_Instruc
序号	数据项	业务含义	类型	备注
1	PHCIN_RowID	　	RowID	　
2	PHCIN_Code	代码	Text	　
3	PHCIN_Desc1	描述	Text	　
4	PHCIN_Desc2	Foreign Instruction	Text	　
3.1.2.6药学项主表PHC_DrgMast
序号	数据项	业务含义	类型	备注
1	PHCD_RowID	　	RowID	　
2	PHCD_Code	代码	Text	　
3	PHCD_Name	描述	Text	　
4	PHCD_MIMSNo	MIMS No	Number	　
5	PHCD_PHCSC_DR	药理学子分类	DR	指向表 PHC_SubCat
6	PHCD_Logo	Logo - MIMS info	Text	　
7	PHCD_ProductName	Full name of the product	Text	　
8	PHCD_PHCPO_DR	管制分类	DR	指向表 PHC_Poison
9	PHCD_Stat	Stat - MIMS	Text	　
10	PHCD_NotUseFlag	Not use Flag 	Y/N	　
11	PHCD_PHMNF_DR	产地	DR	指向表 PH_Manufacturer
12	PHCD_PHDIS_DR	　	DR	指向表 PH_Distributor
13	PHCD_LabelName1	标号(本地语言)	Text	　
14	PHCD_LabelName2	标号(外语)	compute	s {PHCD_LabelName2}=$$CO17^at519({PHCD_LabelName2},{PHCD_Name}
15	PHCD_MinSubCat_DR	药理学小子分类	DR	指向表 PHC_MinorSubCat
16	PHCD_UpdateDate	更新日期	Date	　
17	PHCD_UpdateTime	更新时间	Time	　
18	PHCD_UpdateUser	更新人	DR	　
19	PHCD_Generic_DR	通用名	DR	指向表 PHC_Generic
20	PHCD_OfficialCode	Official Code	Text	　
3.1.2.6药(理)学大类 PHC_Cat
序号	数据项	业务含义	类型	备注
1	PHCC_RowID	　	Row ID	　
2	PHCC_Code	代码	Text	　
3	PHCC_Desc	描述	Text	　
3.1.2.7药(理)学子类PHC_SubCat
序号	数据项	业务含义	类型	备注
1	PHCSC_RowID	　	Row ID	　
2	PHCSC_Code	代码	Text	　
3	PHCSC_Desc	描述	Text	　
4	PHCSC_LookupDisplay	　	Text	　
5	PHCSC_PHCC_ParRef	药学分类RowID	DR	指向表 PHC_Cat
6	PHCSC_ChildSub	ChildSub	ChildSub	　
3.1.2.8药学形态  PHC_DrgForm
序号	数据项	业务含义	类型	备注
1	PHCC_RowID	　	Row ID	　
2	PHCC_Code	代码	String	MAXLEN = 15
3	PHCC_Desc	描述	String	MAXLEN=220
4	PHCDF_PHCD_ParRef	药学项主表RowID	DR	PHC_DrgMast
5	PHCDF_PHCF_DR	剂型	DR	PHC_Form
6	PHCDF_PHCP_DR	　	Reference to PHCPer	Property
7	PHCDF_PHCS_DR	Des Ref to PHCS (Strength)	Reference to PHCStrength	Property
8	PHCDF_PHCPA_DR	Des Ref to PHCPA (Packing)	Reference to PHCPack	property
9	PHCDF_Price1	Price 1 - MIMS (info)	%float	　
10	PHCDF_Price2	Price 2	%float	　
11	PHCDF_ChildSub	New Key	%float	　
12	PHCDF_PHCFR_DR	Des Ref to PHCFR (Frequency)	Reference to PHCFreq	医嘱执行次数（bid等）
13	PHCDF_PHCIN_DR	Des Ref to PHCIN (Instruction)	Reference to PHCInstruc	医嘱用法（口服等）
14	PHCDF_PHCDO_DR	Des Ref to PHCDO (Dosage)	Reference to PHCDosage	管制分类？
15	PHCDF_Indication	Indication (info)	%string	list
16	PHCDF_ContraInd	Contra Indication (info)	%string	list
17	PHCDF_Precaution	Special Precautions (info)	%string	list
18	PHCDF_AdvReaction	Adverse Reaction (info)	%string	List， 不良反应
19	PHCDF_MIMSno	MIMS number	%string	　
20	PHCDF_PHCDU_DR	Des Ref to PHCDU  (Duartion)	Reference to PHCDuration	疗程
21	PHCDF_ATCBin	ATC Bin	%string	　
22	PHCDF_CTUOM_DR	　	Reference to CTUOM	基本单位
23	PHCDF_BaseQty	　	%float	基本数量
24	PHCDF_DeductPartially	Deduct Partially	%string	Y,N
25	PHCDF_UpdateDate	Update date	%date	　
26	PHCDF_UpdateTime	Update time	%time	　
27	PHCDF_UpdateUser	Update user	Reference to SSUser	　
28	PHCDF_InPatDuration_DR	　	Reference to PHCDuration	　
29	PHCDF_OfficialCode	Official cole	%string	医保类别
30	PHCDF_MaxNumberRepeats	Max Number of Repeats	%float	　
31	PHCDF_Interaction	Interaction	%string	list
32	PHCDF_Warning	warning	%string	list
33	PHCDF_DateFrom	Date from	%date	　
34	PHCDF_DateTo	Date to	%date	　
35	PHCDF_GenRtForm_DR	　	Reference to PHCGenericRtForms	　
36	PHCDF_Route_DR	　	Reference to OECRoute	　
37	PHCDF_Formulary	Formulary	%string	Y,N
38	PHCDF_Preferred	Preferred	%string	Y,N
3.1.2.9管制分类  PHC_Poison
序号	数据项	业务含义	类型	备注
1	PHCPO_RowId	　	RowID	　
2	PHCPO_Code	代码	Text	　
3	PHCPO_Desc	描述	Text	　
4	PHCPO_MHRpt	Minstry报告	Y/N	　
5	PHCPO_OTCFlag	超出计数	Y/N	　
6	PHCPO_SaleRpt	销售记录	Y/N	　
3.1.2.10剂型  PHC_Form
序号	数据项	业务含义	类型	备注
1	PHCF_RowID	　	　	　
2	PHCF_Code	代码	%String	　
3	PHCF_Desc	描述	%String	　
4	PHCF_TIMSno	TIMS No（管理科学学会 no）	%string	　
5	　	　	　	　
3.1.2.11库存项INC_Itm
序号	Col名称	含义	类型	备注
1	INCI_RowID	Row ID	RowID	PK
2	INCI_INCPO_DR	库存类型RowID	DR	INC_POGroup
3	INCI_INCTG_DR	盘点类型RowID	DR	INC_StkTkGp
4	INCI_INCCA_DR	Not Used Des Ref to INCCA (Ctrl Account)	%String	　
5	INCI_CTVAT_DR	增值税RowID	DR	CT_Vat
6	INCI_CTLOC_DR	科室RowID	DR	CT_Loc
7	INCI_MinQty	最低允许库存量	%Float	库存量低于该值时
，系统停止出库。
8	INCI_MaxQty	最高允许库存量	%Float	库存量高于该值时，
系统停止进货。
9	INCI_ReordLevel	进货下限	%Float	库存量低于该值时
，系统自动进货，
补充库存。
10	INCI_ReordQty	一次进货数量	%Float	　
11	INCI_CTUOM_DR	最小单位	DR	CT_UOM
12	INCI_INCSC_DR	库存分类RowID	DR	INC_StkCat
13	INCI_LogQty	可用数量	%Float	　
14	INCI_UnitCost	Unit cost	%Float	　
15	INCI_NotUseFlag	Not use flag	%String	Y,N
16	INCI_IsTrfFlag	出库方式 	%String	　
17	INCI_ARCIM_DR	医嘱项	DR	computed
18	INCI_Code	库存项代码	%string	　
19	INCI_Desc	库存项描述	%string	　
20	INCI_Remarks	备注	list	　
21	INCI_BatchReq	是否要求批号	%string	要求批号，
不要求批号，随意
22	INCI_ExpReq	是否需要有效期	%string	要求有效期，
不要求有效期，随意
23	INCI_OriginalARCIM_DR	医嘱项	DR	ARC_ItmMast
24	INCI_Sterile	消毒标志	%string	Y,N
25	INCI_DirtyQty	占用库存数量	%float	保存但未审核的
数量（出库）
26	INCI_FinanceCategory	Finance Category	%string	　
27	INCI_SterCat_DR	消毒用品分类RowID	DR	INC_SterileCategory
28	INCI_UpdateDate	Update date	%date	　
29	INCI_UpdateTime	Update time	%time	　
30	INCI_UpdateUser	Update user	DR	SS_User
31	INCI_StockQtyLastYear	上一年的库存量	%float	　
32	INCI_StockAmtLastYear	上一年的库存金额	%float	　
33	INCI_CTUOM_Purch_DR	定货单位（入库单位）	DR	CT_UOM
34	INCI_FinalVendor_DR	供货商RowID	DR	Computed APC_Vendor 
35	INCI_StockLocations	库存位置	%string	　
36	INCI_WardStock	补充库存方式	%string	　
37	INCI_BarCode	BarCode（存储规格）	%string	　
38	INCI_Account_DR	Des Ref Account	DR	GLC_Acct
39	INCI_ReportingDays	Reporting days	%string	　
40	INCI_Account1_DR	Des Ref Account1	DR	GLC_Acct
41	INCI_PrefVendor_DR	Des Ref PrefVendor	DR	APC_Vendor
42	INCI_INCSC_DR	　	DR	INC_StkCat
3.1.3计费基础信息
3.1.3.1收费项目  DHC_TarItem
TARI_SpecialFlag：特殊项目标志（Yes/No）。用于某些收费项目取固定价格或其他用法。
TARI_ActiveFlag：有效标志（Yes/No）。在有效标志为No时，医嘱项目不能与该项目建立新的关联关系，但已经建立的关联关系与此无关，仍可能存在。缺省值为Yes.
TARI_ExternalCode: 收费项目外部代码．用于和其它系统交换数据，如医保系统。
TARI_StartDate,TARI_EndDate,TARI_Price,TARI_AlterPrice1,TARI_AlterPrice2目前不用。可用于其它价格体系。亦可存放该项目的当前价格。

序号	数据项	业务含义	类型	备注
1	TARI_RowID	　	RowID	　
2	TARI_Code	收费项目代码	Text	　
3	TARI_Desc	收费项目名称	Text	　
4	TARI_UOM	收费项目单位	DR	指向Ct_uom　
5	TARI_SubCate	收费项目分类 	Y/N	指向DHC_TarSubCate
6	TARI_AcctCate	收费项目会计分类	Y/N	指向DHC_TarAcctCate
7	TARI_InpatCate	住院收据分类	DR	指向DHC_TarInpatCate
8	TARI_OutpatCate 	门诊收据分类	DR	指向DHC_TarOutpatCate
9	TARI_EMCCate	经济核算分类	DR	指向DHC_TarEMCCate
10	TARI_MRCate	病历首页费用分类 	DR	指向DHC_TarMRCate
11	TARI_SpecialFlag	特殊项目标志	Y/N	　
		TRAI_ActiveFlag 		
12	TARI_StartDate  	开始日期	%Date	　
13	TARI_EndDate	结束日期	%Date	　
14	TARI_Price	　	　	　
15	TARI_AlterPrice  	　	　	　
16	TARI_AlterPrice	　	　	　
17	TARI_ExternalCode	收费项目外部代码	　	　
3.1.3.2会计子分类   DHC_TarAcctCate
序号	数据项	业务含义	类型	备注
1	TARAC_RowId	　	RowId	　
2	TARAC_Code	代码	Text	　
3	TARAC_Desc	描述	Text	　
4	TARAC_TARTAC_DR	指向大类	DR	指向User.DHCTarAC
3.1.3.3核算大类  DHC_TarEC(^DHCTarC("TEC",{TARTEC_RowId}))
序号	数据项	业务含义	类型	备注
1	TARTAC_RowId	　	RowId	　
2	TARTAC_Code	代码	Text	　
3	TARTAC_Desc	描述	Text	　
3.1.3.4核算子分类  DHC_ TarEMCCate(^DHCTarC("EC",{TAREC_RowId}))
序号	数据项	业务含义	类型	备注
1	TAREC_RowId	　	RowId	　
2	TAREC_Code	代码	Text	　
3	TAREC_Desc	描述	Text	　
4	TAREC_TARTEC_DR	指向大类	DR	指向 User.DHCTarEC
3.1.3.5收费项目核算分类  DHC_TarEC(^DHCTarC("TEC",{TARTEC_RowId}))
序号	数据项	业务含义	类型	备注
1	TARTEC_RowId	　	RowId	　
2	TARTEC_Code	代码	Text	　
3	TARTEC_Desc	描述	Text	　
3.1.3.6收费项目住院子分类  DHC_TarInpatCate(^DHCTarC("IC",{TARIC_RowId}))
序号	数据项	业务含义	类型	备注
1	ARIC_RowId	　	RowId	　
2	ARIC_Code	代码	Text	　
3	ARIC_Desc	描述	Text	　
4	ARIC_TARTIC_DR	指向大类	DR	指向  User.DHCTarIC
3.1.3.7收费项目住院分类  DHC_TarIC(^DHCTarC("TIC",{TARTIC_RowId}))
序号	数据项	业务含义	类型	备注
1	TARTIC_RowId	　	RowId	　
2	TARTIC_Code	代码	Text	　
3	TARTIC_Desc	描述	Text	　
3.1.3.8病案子分类  DHC_TarMRCate(^DHCTarC("MC",{TARMC_RowId}))
序号	数据项	业务含义	类型	备注
1	TARMC_RowId	　	RowId	　
2	TARMC_Code	代码	Text	　
3	TARMC_Desc	描述	Text	　
4	TARMC_TARTMC_DR	指向大类	DR	指向User.DHCTarMC
3.1.3.9病案大类(收费项目病历首页分类)  DHC_TarMC(^DHCTarC("TMC",{TARTMC_RowId}))
序号	数据项	业务含义	类型	备注
1	TARTMC_RowId	　	RowId	　
2	TARTMC_Code	代码	Text	　
3	TARTMC_Desc	描述	Text	　
3.1.3.10门诊子分类  DHC_TarOutpatCate(^DHCTarC("OC",{TAROC_RowId}))
序号	数据项	业务含义	类型	备注
1	TAROC_RowId	　	RowId	　
2	TAROC_Code	代码	Text	　
3	TAROC_Desc	描述	Text	　
4	TAROC_TARTOC_DR	指向大类	DR	指向 DHC_TarOC
3.1.3.11门诊大类  DHC_TarOC(^DHCTarC("TOC",{TARTOC_RowId}))
序号	数据项	业务含义	类型	备注
1	TARTOC_RowId	　	RowId	　
2	TARTOC_Code	代码	Text	　
3	TARTOC_Desc	描述	Text	　
3.1.3.12.1收费项目分类 DHC_TarCate(^DHCTarC("CC",{TARC_RowId}))
序号	数据项	业务含义	类型	备注
1	TARC_RowId	　	RowId	　
2	TARC_Code	代码	Text	　
3	TARC_Desc	描述	Text	　

3.1.3.12.2收费项目子分类  DHC_TarSubCate(^DHCTarC("SC",{TARSC_RowId}))
序号	数据项	业务含义	类型	备注
1	TARSC_RowId	　	RowId	　
2	TARSC_Code	代码	Text	　
3	TARSC_Desc	描述	Text	　
4	TARSC_TARC_DR	指向大类	DR	指向 User.DHCTarCate
3.1.3.13收费大类  DHC_TarCate
序号	数据项	业务含义	类型	备注
1	TARC_RowId	　	RowId	　
2	TARC_Code	代码	Text	　
3	TARC_Desc	描述	Text	　
4	OSTAT_Desc	状态描述	String	　
3.1.3.14 费用项目价格表DHC_TarItemPrice
本表用于保存费用项目的价格信息，是费用项目表的子表
序号	数据项	业务含义	类型	备注
1	TP_RowId	价格表RowId	RowId	　
2	TP_TARI_ParRef		收费项目指针  DHC_TarItem	Text	　
3	TP_ChildSub	收费项目价格指针	Text	　
4	TP_PatInsType	病人保险类型  PAC_AdmReason	String	　
	TP_StartDate		价格有效日期		
	TP_EndDate	价格有效日期		
	TP_Price		标准价格		
	TP_AlterPrice1	辅助价格		
	TP_AlterPrice2	辅助价格		
	TP_LimitedPrice	病人最高记账限价		
	TP_PayorRate	病人记账比例		
	TP_DiscRate		病人折扣比例		
	TP_UpdateUser	调价人		
	TP_UpdateDate	调价日期		
	TP_UpdateTime		调价时间		
	TP_AdjustNo	调价单号		
				
				
				
				
				
				
				
3.1.3.15医嘱与收费项目关联表dhc_orderlinktar
定义医嘱、收费项目、病人入院分类之间的关系
序号	数据项	业务含义	类型	备注
1	OLT_RowId	医嘱费用关联表	RowId	　
2	OLT_ARCIM_DR	医嘱指针   ARC_ItmMast	Text	　
3	OLT_Tariff_DR	费用项目指针  DHC_TarItem	Text	　
4	OLT_Qty		计费数量	String	　
	OLT_StartDate	关联有效日期		
	OLT_EndDate	关联有效日期		
	OLT_Inst_DR	医嘱用法指针  PHC_Instruc		
	OLT_Priority_DR	医嘱优先级指针  OEC_Priority		
1)一个医嘱项目可与多个收费项目关联。
2)一个收费项目可与多个医嘱项目关联。
3)医嘱项目可以和医嘱用法、医嘱优先级结合关联费用项目。检查顺序为：
3．1 医嘱用法和医嘱优先级
3．2 医嘱用法
3．3 医嘱优先级
3．4 无医嘱用法和医嘱优先级
对于关联医嘱，由于各个医嘱的用法和优先级相同，所以计费时只考虑主医嘱与医嘱优先级和用法的关联，而不考虑副医嘱的优先级和用法。
4)当收费项目的 ActiveFlag 为No时,不能和医嘱进行新的关联。但以前建立的关联关系仍然有效。
5)关联关系发生变化时，不能删除已有的已有的关联关系。建立一个新的关联关系时，一定要设定开始日期；停止一个关联关系时，一定要设定停止日期。停止日期和开始日期包含日期当天。
6)OLT_Qty 为单位医嘱对应的计费项目数量。一条医嘱的计费数量应是OLT_Qty乘以医嘱数量。

3.1.3.16费用项目别名表DHC_TarItemAlias
序号	数据项	业务含义	类型	备注
1	 TIA_TARI_DR	收费项目	RowId	　
2	TIA_Desc	收费项目名称	Text	　
3	TIA_Alias	收费项目别名	Text	　
3.1.3.17病人折扣,记账系数表 DHC_TarFactor
定义按病人保险分类计算费用时的折扣和自费的系数
序号	数据项	业务含义	类型	备注
1	TF_REA_DR	病人保险分类  PAC_AdmReason	RowId	　
2	TF_TARSC_DR	收费类别  	Text	　
3	TF_StartDate		系数有效日期	Text	　
	TF_EndDate	系数有效日期		
	TF_DiscRate	折扣系数		
	TF_PayorRate		记账系数		
当计费系统采用病人折扣计算费用时，项目折扣优先于项目类别折扣系数。根据病人的保险分类首先检查计费项目是否在该表中有定义，如果有定义则按参数执行。如果无定义，则继续检查该项目所属项目类别是否在该表中有定义
3.1.3.18病人类别与标准价格DHC_TarEpisode
用于定义就诊类型与基准价格的关系。不同的就诊类型,可以使用不同的基准价格

序号	数据项	业务含义	类型	备注
1	TEP_EST_DR	病人就诊类别PAC_EpisodeSubType	RowId	　
2	TEP_PriceList	标准价格	Text	　
3	TEP_StartDate	标准价格执行日期	Text	　
	TEP_EndDate	标准价格执行日期		
3.1.3.19医嘱计费点设定DHC_BillCondition
序号	数据项	业务含义	类型	备注
1	TEP_EST_DR	病人就诊类别PAC_EpisodeSubType	RowId	　
2	TEP_PriceList	标准价格	Text	　
3	TEP_StartDate	标准价格执行日期	Text	　
	TEP_EndDate	标准价格执行日期		

3.1.3.20病人就诊类别 PAC_EpisodeSubType
序号	数据项	业务含义	类型	备注
1			RowId	　
2			Text	　
3			Text	　
				

3.1.3.21银行字典 CMC_BankMas  ^CMC("CMCBM")
序号	数据项	业务含义	类型	备注
1	CMCBM_Code		RowId	　
2	CMCBM_Desc		Text	　
3	CMCBM_RcFlag		Text	　
	CMCBM_Comp_DR			CT_Company
	CMCBM_DateFrom			
	CMCBM_DateTo			

3.1.3.22预交金支付方式字典 CT_PayMode
序号	数据项	业务含义	类型	备注
1	CTPM_Code		RowId	　
2	CTPM_Desc		Text	Yes,No　
3	CTPM_NotUseFlag		Text	　,CH,CC,CQ,DP
	CTPM_GrpCode			,Cash||CH,Card|| CC,Cheque || CQ,DirectPayment|| DP
	CTPM_DateFrom			
	CTPM_DateTo			
	CTPM_ChangeGiven			Yes,No

3.1.3.23预交金类型字典 ARC_DepType
序号	数据项	业务含义	类型	备注
1	ARCDT_Code		RowId	　
2	ARCDT_Desc		Text	　

3.1.3.24欠费类别表  ARC_DisretOutstType  ^ARC("DOUTS"
序号	数据项	业务含义	类型	备注
1	DOUTS_Code		RowId	　
2	DOUTS_Desc		Text	　
3	DOUTS_Type		Text	　,Patient||P,Non Patient||N
	DOUTS_DateFrom			
	DOUTS_DateTo			

3.2业务表
3.2.1 病人信息
3.2.1.1病人基本信息表主表 PA_PatMas
序号	数据项	业务含义	类型	备注
1	PAPMI_RowId	　	RowId	　
2	PAPMI_Name	姓名, First name	String	　
3	PAPMI_DOB	出生日期	String	　
4	PAPMI_Name2	Middle name	String	　
5	PAPMI_Name4	Last name	　	　
6	PAPMI_Name3	医保手册号	String	　
7	PAPMI_Medicare	病历号(住院)	　	　
8	PAPMIMedicareExpDate	　	　	　
9	PAPMI_MedicareCode	传真	　	　
10	PAPMI_GovernCardNo	门诊病历号	　	　
11	PAPMI_DVAnumbe	身份证号	　	　
12	PAPMIAlias	病人别名	　	　
13	PAPMIIPNo	住院号	　	　
14	PAPMIOPNo	门诊号	　	　
15	PAPMIEstAgeYear	　	　	　
16	PAPMIEstAgeMonth	　	　	　
17	PAPMIEstAgeTmStmp	　	　	　
18	PAPMISoundex	　	　	　
19	PAPMILangPrimDR	母语	　	　
20	PAPMILangSecondDR	第二母语	　	　
21	PAPMIPrefLanguageDR	首选语言	　	　
22	PAPMIActive	激活	　	　
23	PAPMIVIPFlag	VIP标志	　	　
24	PAPMIPatCategoryDR	病人分类	　	　
25	PAPMIHomeClinicNo	　	　	　
26	PAPMIRemark	备注	　	　
27	PAPMIDeceased	死亡标志	　	　
28	PAPMIDeceasedDate	死亡日期	　	　
29	PAPMIDeceasedTime	死亡时间	　	　
30	PAPMIBlackList	黑名单标志	　	　
31	PAPMIEstimatedDeathDate	　	　	　
32	PAPMIMotherDR	母亲记录指针	　	　
33	PAPMIMother1DR	　	　	　
34	PAPMIRefDocDR	家庭医生	　	　
35	PAPMIDentistDR	牙医	　	　
36	PAPMIDentistClinicDR	牙医诊所	　	　
37	PAPMITraceStatusDR	　	　	　
38	PAPMIMedicareSuffixDR	　	　	　
39	PAPMIAllergy	过敏记录	　	　
40	PAPMIEPRDescription	电子病历	　	　
41	PAPMIConcessionCardNo	　	　	　
42	PAPMIConcessionCardExpDate	　	　	　
43	PAPMISafetyNetCardNo	　	　	　
44	PAPMISafetyNetCardExpDate	　	　	　
45	PAPMIGovernCardNo	　	　	　
46	PAPMIDVAnumber	　	　	　
47	PAPMIInsuranceCardHolder	　	　	　
48	PAPMICardTypeDR	　	　	　
49	PAPMICHCPatient	　	　	　
50	PAPMICTHCADR	CTHealthCareArea	　	　
51	PAPMIHealthFundNo	　	　	　
52	PAPMIHealthCardExpiryDate	健康卡号失效日期	　	　
53	PAPMICountryOfBirthDR	出生国	　	　
54	PAPMICityBirthDR	出生城市	　	　
55	PAPMITitleDR	头衔	　	　
56	PAPMICTRegionDR	所在地区	　	　
57	PAPMICTProvinceDR	所在省	　	　
58	PAPMICityAreaDR	所在区	　	　
59	PAPMIEmail	电子邮件	　	　
60	PAPMIMobPhone	手机	　	　
61	PAPMISecondPhone	第二联系电话	　	　
62	PAPMIAuxInsTypeDR	　	　	　
63	PAPMIPensionTypeDR	　	　	　
64	PAPMIIndigStatDR	　	　	　
65	PAPMIRequireAssistanceMeal	需要辅食	　	　
66	PAPMIRequireAssistanceMenu	需要辅食菜单	　	　
3.2.1.2病人基本信息表  PA_Person
序号	数据项	业务含义	类型	备注
1	REA_RowId	　	RowId	　
2	PAPER_PAPMI_DR	　	　	PA_PatMast
3	PAPER_ID	　	身份证号	　
4	PAPER_Marital_DR	　	婚姻状况	　
5	PAPER_Sex_DR	　	性别	CT_Sex
6	PAPER_Age	　	年龄	　
7	PAPER_SocialStatus_DR	　	病人类型	　
8	PAPER_Occupation_DR	　	职业	　
9	PAPER_Education_DR	　	学历	　
10	PAPER_Email	　	Email	　
11	PAPER_Country_DR	　	国籍	CT_Country
12	PAPER_ReligionDR	　	宗教	　
13	PAPER_Nation_DR	　	民族	CT_Nation
14	PAPER_StayingPermanently	　	是否永久居住	　
15	PAPER_SecondPhone	　	工作单位	　
16	PAPER_ZipDR	　	邮编	　
17	PAPER_StName	　	街道住址	　
18	PAPER_House_Building_No	　	门牌号	　
19	PAPER_MobPhone	　	手机	　
20	PAPER_TelH	　	家庭电话	　
21	PAPER_TelO	　	办公电话	　
22	PAPER_CTRLTDR	　	联系人关系	CTRelation  "EMP"。4
23	PAPER_Name6	　	工作单位邮编	　
24	PAPER_ForeignId	　	联系人姓名	"PER",2。13
25	PAPER_ForeignCountry	　	护照国籍	　
26	PAPER_PassportNumber	　	护照号	　
27	PAPER_ForeignAddress	　	国际地址/联系人地址	　
28	PAPER_ForeignPhone	　	联系人电话	"ALL"。4
29	PAPER_ForeignPostCode	　	国际邮编	肿瘤作为
30				病人的联系邮编
31	PAPER_Complement	　	备注	　
32	　	　	　	　
33	PAPER_NokText	　	监护人信息	　
34	PAPER_NokName	　	监护人姓名	肿瘤作为
35				工作单位联系人
36	PAPER_NokPhone	　	监护人联系电话	肿瘤作为
37				工作单位联系人电话
38	PAPER_NokAddress1	　	　	肿瘤作为
39				工作单位地址
40	PAPERNokCTRLTDR	　	与监护人关系	CTRelation
41	　	　	　	　
42	PAPER_ExemptionNumber	　	住院累计次数	　
43	PAPMI_GPOrgAddress	　	首诊科室	　
44	PAPMI_GPText	　	首诊日期	　
45	　	　	　	　
46	PAPERCityCodeDR	　	　	　
47	PAPERStateCodeDR	　	　	　
48	PAPERCTRegionDR	　	　	　
49	PAPERCTProvinceDR	　	　	　
50	PAPERCityAreaDR	　	　	　
51	PAPERLangPrimDR	　	　	　
52	PAPERCTHCADR	　	　	　
53	PAPERHCPDR	　	CTHealthCareProvider	　
54	PAPERCityBirthDR	　	　	　
55	PAPERGovernCardNo	　	　	　
56	　	　	　	　
57	PAPERMotherDR	　	母亲	　
58	PAPERFatherDR	　	父亲	　
59	PAPERFamilyGroupDR	　	家族	　
60	PAPERFamilyDoctorDR	　	家庭医生	　
61	　	　	　	　
62	PAPERFromThisArea	　	　	　
63	PAPERReasonForChangeData	　	　	　
64	PAPERForeignNotes	　	　	　
65	PAPERExemptionNumber	　	　	　
66	PAPER Complement	　	补助	　
67	PAPERResponsibleForPayment	　	　	　
68	PAPERDiscretOutsTypeDR	　	　	　
69	　	　	　	　
70	PAPEREmplTypeDR	　	　	　
71	PAPERJobTitle	　	　	　
72	PAPEREmplRelatedTo	　	　	　
73	PAPEREmployeeNo	　	　	　
74	PAPEREmplDepDR	　	　	　
75	PAPERDiscDateFrom	　	　	　
76	PAPERDiscDateTo	　	　	　
77	PAPERDiscTypeDR	　	　	　
78	PAPEROutstandAmt	　	　	　
79	PAPEROutstandingDate	　	　	　
80	PAPEREmployeeFunction	　	　	　
81	PAPEREmployeeCompany	　	雇员所在公司	合同单位
82	PAPEREmployeeCoContract	　	雇员合约	　
83	PAPERGuardian1DR	　	　	　
84	PAPERGuardian2DR	　	　	　
85	PAPERExpectedPayDate	　	　	　
86	PAPERBillCode	　	　	　

3.2.2就诊信息
3.2.2.1就诊表PA_Adm
序号	数据项	业务含义	类型	备注
1	PAADM_RowID	　	RowId	　
2	PAADM_PAPMI_DR	病人登记号指针	DR	指向PA_PatMas
3	PAADM_Type	病人就诊类型	Text	I：住院；O：门诊；E：急诊；H：体检
4	PAADM_DepCode_DR	（入院）科室	DR	　
5	PAADM_AdmDate，PAADM_AdmTime	（入院、就诊）日期时间	Date	　
6	PAADM_AdmDocCodeDR	（入院、就诊）医生，管床医生	　	　
7	PAADM_VisitStatus	本次就诊状态	　	　
8	PAADM_CurrentWard_DR	入院病区	DR	　
9	PAADM_CurrentBed_DR	床位	DR	　
10	PAADM_MainMRAdm_DR	诊断主表指针	DR	　
11	PAADM_DischgDate	（出院）日期	Date	　
12	PAADM_DischgTime	（出院）时间	Date	　
13	PAADM_FirstOrReadm	是否初复诊	Text	F：初诊   R：复诊
14	PAADM_IsBooking	是否预约挂号	Text	C：普通  B：预约
15	PAADM_IsPlus	是否为加号	Text	Y：加号  N：不是加号
16	PAADM_CreateUser_DR	操作人员	DR	指向SS_User
3.2.3诊断信息
3.2.3.1诊断主表  MR_Adm
序号	数据项	业务含义	类型	备注
1	MRADM_RowId	　	RowId	　
3.2.3.2诊断子表  MR_Diagnos
序号	数据项	业务含义	类型	备注
1	MRDIA_RowId	　	RowId	　
2	MRDIA_MRADM_ParRef	诊断主表ＩＤ	DR	指向MR_Adm
3	MRDIA_Childsub	字表ID	　	　
4	MRDIA_ICDCode_DR	诊断ＩＣＤ码表	ＤＲ	指向MRC_ICDDx
5	MRDIA_DocCode_DR	下诊断医师	ＤＲ	指向CT_CareProv
6	MRDIA_Date	下诊断日期	Date	　
7	MRDIA_Time	下诊断时间	Date	　
8	MRDIA_DiagStat_DR	诊断状态	DR	指向MRC_DiagnosStatus
3.2.3.3诊断状态  MRC_DiagnosStatus
序号	数据项	业务含义	类型	备注
1	DSTAT_RowId	　	RowId	　
2	DSTAT_Code	代码	Text	　
3	DSTAT_Desc	描述	Text	　
3.2.3.4诊断ICD码  MRC_ICDDx
序号	数据项	业务含义	类型	备注
1	MRCID_RowId	　	RowId	　
2	MRCID_Code	代码	Text	　
3	MRCID_Desc	描述	Text	　
4	MRCID_ICD9CM_Code	ICD9码	Text	　
3.2.4医嘱信息
3.2.4.1医嘱主表  OE_Order
序号	数据项	业务含义	类型	备注
1	OEORD_RowId	Row ID	Rowid	　
2	OEORD_Adm_DR	就诊号（住院流水号）	DR	PA_Adm
3	OEORD_Date	医嘱录入日期	Date	　
4	OEORD_Time	医嘱录入时间	Time	　
5	OEORD_Doctor_DR	开单医生（诊断医生）	DR	CT_CareProv
6	OEORD_ARCOP_DR	　	　	　
7	OEORD_OEOTC_DR	　	　	　
8	OEORD_SundryDebtor_DR	　	DR	ARC_SundryDebtor

3.2.4.2医嘱明细  OE_OrdItem
序号	数据项	业务含义	类型	备注
1	OEORI_RowID	Row ID	Rowid	　
2	OEORI_OEORD_ParRef	医嘱主表	DR	OE_Order
3	OEORI_Childsub	New key	numeric	　
4	OEORI_ItmMast_DR	医嘱项	DR	ARC_ItmMast
5	OEORI_OrdDept_DR	开医嘱科室	DR	CT_Loc
6	OEORI_ItemStat_DR	医嘱状态	DR	OEC_OrderStatus
7	OEORI_Doctor_DR	　开医嘱医生	DR	CT_CareProv
8	OEORI_SttDat	医嘱开始日期	Date	　
9	OEORI_SttTim	医嘱开始时间	Time	　
10	OEORI_Priority_DR	医嘱优先级	DR	OEC_Priority
11	OEORI_Unit_DR	剂量单位	　	剂量单位
12	OEORI_PhQtyOrd	　医嘱剂量	　	Sqlcomputed
13	OEORI_XDate	医嘱停止日期	　	　
14	OEORI_UnitCost	单价	　	　
15	OEORI_DRCross_DR	医嘱停止人	DR	SS_User
16	OEORI_XTime	医嘱停止时间	　	　
17	OEORI_Qty	数量	String	对应于INC_Itm中INCI_CTUOM_DR
18	OEORI_AdministerSkinTest	是否要求皮试	String	Y，N,设为Y时，发药时必须检测皮试结果是否正常
19	OEORI_Abnormal	皮试结果是否异常	String	Y，N，Y表示异常
20	OEORI_UserAdd	医生	DR	SS_User
21	OEORI_UserDepartment_DR	医生科室	DR	CT_Loc
22	OEORI_Date	医嘱当前日期	Date	　
23	　	　	　	　
24	OEORI_RecDep_DR	接收科室（发药科室）	DR	CT_Loc
25	OEORI_PrescNo	处方号	String	　
26	OEORI_DoseQty	剂量	String	　
27	DHC_PHACounts	Itm的个数	Number	本发药单对应的明细的记录条数
28	DHC_PHADateFrom	本次发药的起始日期	Date	　
29	DHC_PHADateTo	截止日期	Date	　
30	DHC_PHAOrdType	发药类别	Text	　
31	DHC_PHADispNo	发药单号	Text	　
32	OEORI_Billed	是否结帐（结帐标志）	　	P(已结)
33	DHC_PHACollectUser	护士	DR	SS_User的RowID
34	　OEORI_LabEpisodeNo	　标本号	　	　
35	　OEORI_Durat_DR	　	　	　
36	　OEORI_Unit_DR	　单位指针	　	　
37	　OEORI_Instr_DR	　医嘱用法	　	　
38	　OEORI_PHFreq_DR	　医嘱频率	　	　
39	　	　	　	　
	  			
3.2.4.3医嘱状态  OEC_OrderStatus
序号	数据项	业务含义	类型	备注
1	OSTAT_RowID	RowID	PK	　
2	OSTAT_Activate	　	String	Y,N，值为Y表示该记录目前在使用
3	OSTAT_Code	代码	String	　
3.2.4.4医嘱扩展表DHC_OE_OrdItem
序号	数据项	业务含义	类型	备注
1	DHCORI_OEORI_Dr	　表oe_orditem的指针	　	　
2	DHCORI_SkinTestCtcp_Dr	置皮试结果人	DR	OE_OrdItem
3	DHCORI_SkinTestDate	置皮试结果日期	PK 	　
4	DHCORI_SkinTestTime	置皮试结果时间	Float	　
5	DHCORI_RefundAuditStatus	退费审核状态	Date	　
6	DHCORI_RefundAuditUser_Dr	退费审核用户	　	　
7	DHCORI_RefundAuditDate	退费审核日期	　	　
8	DHCORI_RefundAuditTime	退费审核时间	　	　
9	DHCORI_RefundReason	退费审核原因	　	　
10	DHCORI_RefAuditLoc_DR	退费审核科室	DR	OEC_Order_AdminStatus， E完成，PRE欲执行
11	DHCORI_PAALG_Dr	　过敏表指针	　	　
12	DHCORI_DisconUser_Dr	　停止医嘱处理人	　	　
	DHCORI_DisconDate	停止医嘱处理日期		
13	DHCORI_DisconTime	停止医嘱处理时间	　	　
14	DHCORI_MedAuditUser_Dr	领药审核人	DR	CT_Uom
	DHCORI_MedAuditDate	领药审核日期		
	DHCORI_MedAuditTime	领药审核时间		
	DHCORI_DispTimeList	发药时间列表		
	DHCORI_Approved	记账/医保审核状态		
	DHCORI_ApprovedUser_dr	记账/医保审核人			
	DHCORI_ApprovedDate	记账/医保审核日期		
	DHCORI_ApprovedTime	记账/医保审核时间		
	DHCORI_SkinTestAuditCtcp_Dr	皮试结果审核人		
	DHCORI_SkinTestAuditDate	皮试结果审核日期		
	DHCORI_SkinTestAuditTime	皮试结果审核时间		
	DHCORI_LISReport_DR	接收第三方报告状态		
	DHCORI_ConfirmFlag	财务审核标志		
	DHCORI_ConfirmDate	财务审核日期		
	DHCORI_ConfirmTime	财务审核时间		
	DHCORI_ConfirmUser	财务审核人		
	DHCORI_WardID			
	DHCORI_Paadm_dr	就诊		
	DHCORI_DoctorConfirmFlag	科室审核标志		
	DHCORI_DoctorConfirmDate	科室审核日期		
	DHCORI_DoctorConfirmTime	科室审核时间		
	DHCORI_DoctorConfirmUser_Dr	科室审核人		
	DHCORI_ApprovedPercent	记账审核比例		
	DHCORI_ApprovedLimit	记账审核限额		
	DHCORI_ApprovedFlag	记账审核类型		1:修改比例了，2:国产限价
	DHCORI_ApproveType	医保需审类型		1:医保特病  2:医保处方超限
				
				

3.2.4.5医嘱执行表  OE_OrdExec
序号	数据项	业务含义	类型	备注
1	OEORE_RowID	　	　	　
2	OEORE_OEORI_ParRef	医嘱明细	DR	OE_OrdItem
3	OEORE_Childsub	New Key	PK 	　
4	OEORE_PhQtyOrd	数量	Float	　
5	OEORE_XDate	注销日期	Date	　
6	OEORE_ExStDate	执行开始日期	　	　
7	OEORE_ExStTime	执行开始时间	　	　
8	OEORE_StDateTime	执行开始日期+时间	　	　
9	OEORE_XTime	注销时间	　	　
10	OEORE_Order_Status_DR	医嘱执行状态	DR	OEC_Order_AdminStatus， E完成，PRE欲执行
11	OEORE_CTPCP_DR	　	　	　
12	OEORE_PhQtyIss	　	　	　
13	OEORE_Billed	账单状态	　	　
14	OEORE_CTUOM_DR	单位	DR	CT_Uom
3.2.4.6医嘱执行扩展表DHC_OE_OrdExec
序号	数据项	业务含义	类型	备注
1	DHCORE_OEORE_Dr	　主表指针	　	　
2	DHCORE_OEORE_Date	医嘱明细		OE_OrdItem
3	DHCORE_Printed	打印标志		　
4	DHCORE_CTLOC_Dr		Float	　
5	DHCORE_Ward_Dr		Date	　
6	DHCORE_QueryCode	单据代码	　	　
7	DHCORE_Group		　	　
8	DHCORE_SeatNo		　	　
9	DHCORE_OEORE_Time	医嘱时间	　	　
10	DHCORE_Ssuser_Dr	执行用户		  
11	DHCORE_OEORI_Dr	　	　	　
12	DHCORE_SpecCollUser	　	　	　
13	DHCORE_SpecCollDate		Date	　
14	DHCORE_SpecCollTime			
	DHCORE_PrintUser_Dr	打印用户	String	
	DHCORE_PrintDate	打印日期	Date	
	DHCORE_PrintTime	打印日期	String	
	DHCORE_AuditUser_Dr		String	
	DHCORE_AuditDate		String	
	DHCORE_AuditTime		String	
	DHCORE_MedUnitCareProv_Dr		String	

3.2.5住院发药信息表
3.2.5.1住院发药主表   DHC_PHACollected
序号	数据项	业务含义	类型	备注
1	DHC_PHACollect_RowID	Row ID	Rowid	　
2	DHC_PHALoc_DR	发药科室	DR	CT_Loc
3	DHC_PHACollectDate	发药日期	Date	　
4	DHC_PHACollectTime	发药时间	Time	　
5	DHC_PHAWard_DR	病区	DR	PAC_Ward
6	DHC_PHAOperator	发药人（操作者）	DR	SS_User
7	DHC_PHACollectStatus	发药状态（Print）	Text	　
8	DHC_PHAPrintDate	打印日期	Date	　
9	DHC_PHAPrintTime	打印时间	Time	　
10	DHC_PHACounts	Itm的个数	Number	　
11	DHC_PHADateFrom	本次发药的起始日期	Date	　
12	DHC_PHADateTo	截止日期	Date	　
13	DHC_PHAOrdType	药品类型（发药类别）	Text	　
14	DHC_PHADispNo	发药单号	Text	　
15	DHC_PHACollectUser	护士	DR	SS_User
				
3.2.5.2住院发药从表   DHC_PHACollectItm
序号	数据项	业务含义	类型	备注
1	PHACI_PHAC_ParRef	发药主表	DR	DHC_PHACollected
2	PHACI_RowID	　	Rowid	　
3	PHACI_Adm_DR	就诊ID	DR	PA_Adm
4	PHACI_PrescNo	处方号	Text	　
5	PHACI_INCI_DR	药品科室批次	DR	INC_ItmLcBt
6	PHACI_Qty	发药数量	Number	　
7	PHACI_OEDIS_DR	发药ID	DR	OE_Dispensing
8	PHACI_ChildSub	　	Number	　
9	PHACI_BED	床位名称	Text	　
10	PHACI_Price	单价	Number	　
11	PHACI_OrdStatus	医嘱状态	　	　
12	PHACI_AdmLoc_DR	就诊科室	DR	CT_Loc
13	PHACI_DODIS_DR	　	DR	DHC_OEDispensing
14	PHACI_ResQty	欲发退回药品数量	　	有些药品在退药的时候不将实物退回，所以在发药的时候先将已经退药但实物尚未退回的部分发掉
3.2.5.3退药记录主表   DHC_PhaReturn
序号	数据项	业务含义	类型	备注
1	PHAR_Date	　退药时间	RowID	　
2	PHAR_Time	　退药时间	　	　
3	PHAR_SSUSR_DR	退药人	Dr	dhc_phloc
	PHAR_RETRQ_DR	就诊号		
	PHAR_RecLoc_DR	退药科室		
	PHAR_DeptLoc_DR	申请退药科室		如果是病区退药，存病区科室，如果是特殊科室退药，存医生科室
	PHAR_RetNo	退药单号		
	PHAR_AckStatus	退药单号		
	PHAR_AckDate			
	PHAR_AckTime			
	PHAR_AckUser			

3.2.5.4退药记录子表DHC_PhaReturnItm
序号	数据项	业务含义	类型	备注
1	PHARI_PHAR_Parref	　申请单号	RowID	　
2	PHARI_ChildSub	　执行科室	　	　
3	PHARI_OEDIS_DR	药房科室	Dr	OE_OrdItem
	PHARI_Price	单价		
	PHARI_Qty	退药数量		
	PHARI_REASON_DR	申请科室		如果是病区退药，存病区科室，如果是特殊科室退药，存医生科室
	PHARI_ReservedQty	患者床号		
	PHARI_Amount	退药状态		
	PHARI_PAADM_DR	退药人		
	PHARI_AdmLoc_DR	申请退药科室		
	PHARI_Bed_DR	床号		
	PHARI_RETRQI_DR			
	PHARI_INCI_DR	库存项指针		
	PHARI_DateDosing			
	PHARI_DoDis_Dr	打包指针		DHC_OEDispensing

3.2.5.4 退药申请单DHC_PhaRetRequest
序号	数据项	业务含义	类型	备注
1	RETRQ_RowID	RowID	　	　
2	RETRQ_RegNo	申请单号	　	　
3	RETRQ_RecLoc_DR	接收科室/执行科室	DR	CT_Loc
4	RETRQ_PaNo	登记号	　	　
5	RETRQ_ADM_No	就诊号（住院流水号）	　	　
6	RETRQ_PAADM_DR	住院登记表	DR	PA_Adm
7	RETRQ_Doctor_DR	医生	DR	SS_User
8	RETRQ_Dept_DR	申请科室	DR	CT_Loc
9	RETRQ_Bed_DR	床位	DR	PAC_Bed
10	RETRQ_OEDIS_DR	医嘱打包	DR	OE_Dispensing
11	RETRQ_PrescNo	处方号	　	　
12	RETRQ_Qty	数量	　	　
13	RETRQ_Sprice	单价	　	　
14	RETRQ_Samount	金额	　	　
15	RETRQ_Status	申请单状态	　	Prove（待退）,Execute（已退）,Ignore（取消）
16	RETRQ_OperUser_DR	操作员	　	SS_User
17	RETRQ_OperDate	操作日期	　	　
18	RETRQ_OperTime	操作时间	　	　
19	RETRQ_UpdateUser_DR	更新人	　	　
20	RETRQ_UpdateDate	更新日期	　	　
21	RETRQ_UpdateTime	更新时间	　	　
22	RETRQ_AdmLoc_DR	就诊科室	　	　
23	RETRQ_PHACI_DR	　	DR	DHC_PHACollectItm
24	RETRQ_DrugForm	药学项	　	　
1	RETRQ_ReqNo	　申请单号	RowID	　
2	RETRQ_RecLoc_DR	　执行科室	　	　
3	RETRQ_Papmi_DR	药房科室	Dr	dhc_phloc
	RETRQ_PAADM_DR	就诊号		
	RETRQ_Doctor_DR			
	RETRQ_Dept_DR	申请科室		如果是病区退药，存病区科室，如果是特殊科室退药，存医生科室
	RETRQ_Bed_DR	患者床号		
	RETRQ_Status	退药状态		
	RETRQ_OperUser_DR	退药人		
	RETRQ_OperDate	退药时间		
	RETRQ_OperTime	退药时间		
	RETRQ_UpdateUser_DR			
	RETRQ_UpdateDate			
	RETRQ_UpdateTime			
	RETRQ_WardLoc_DR			
				
3.2.5.5退药申请单子表
序号	数据项	业务含义	类型	备注
1	RETRQI_RETRQ_ParRef	　	RowID	　
2	RETRQI_ChildSub	　	　	　
3	RETRQI_OEDIS_DR	药房科室	Dr	OE_OrdItem
4	RETRQI_Qty			
	RETRQI_REASON_DR			
	RETRQI_SAmount			
	RETRQI_SPrice			
	RETRQI_UpdateDate			
	RETRQI_UpdateTime			
	RETRQI_UpdateUser_Dr	退药人		
	RETRQI_DateDosing			
	RETRQI_Status			Prove,Execute,Ignore"
	RETRQI_DoDis_Dr			
	RETRQI_RefundStatus			
	RETRQI_INCI_DR			
				
				
				
				
				

3.2.6门诊发药信息
3.2.6.1门诊发药  DHC_PhDispen
序号	数据项	业务含义	类型	备注
1	PHS_ROWID	　	RowID	　
2	PHD_PRT_DR	　	　	　
3	PHD_PRT_DR	药房科室	Dr	dhc_phloc
3.2.6.2门诊发药子表 DHC_PHDISITEM
序号	数据项	业务含义	类型	备注
1	PHDI_PHD_PARREF	　	　	　
2	PHDI_ROWID	　	　	　
3	PHDI_CHILDSUB	　	　	　
4	PHDI_PAPMI_DR	　	　	　
5	PHDI_INCLB_DR	　	　	　
6	PHDI_QTY	　	　	　
7	PHDI_PAYAMOUNT	　	　	　
8	　	　	　	　
3.2.6.3门诊退药 DHC_PhReturn
序号	数据项	业务含义	类型	备注
1	DHC_PHACollect_RowID	Row ID	Rowid	PK
2	DHC_PHALoc_DR	　	DR	CT_Loc
3	DHC_PHACollectDate	　	Date	　
4	DHC_PHACollectTime	　	Time	　
5	DHC_PHAWard_DR	病区	DR	PAC_Ward
6	DHC_PHAOperator	　	DR	SS_User
7	DHC_PHACollectStatus	　	Text	　
8	DHC_PHAPrintDate	　	Date	　
9	DHC_PHAPrintTime	　	Time	　
10	DHC_PHACounts	Itm的个数	Number	　
11	DHC_PHADateFrom	　	Date	　
12	DHC_PHADateTo	　	Date	　
13	DHC_PHAOrdType	发药类别	Text	　
14	DHC_PHACollectUser	发药人	DR	SS_User
15	DHC_PHADispNo	发药单号	Text	　
16	DHC_SendAutoFlag	是否已经发送到摆药机	Text	1-是，其他-否
17	DHC_PHAPrintFlag	打印次数标志	Text	　
18	DHC_PHASend_User	配送人（第二发药人）	Dr	SS_User
19	DHC_PHAOperateDate	　	Date	　
20	DHC_PHAOperateTime	　	Time	　
3.2.7住院计费信息
3.2.7.1账单主表  DHC_Patientbill(^DHCPB)
序号	数据项	业务含义	类型	备注
1	PB_Adm_DR	病人本次住院的就诊RowId	　	　
2	PB_AdmDate	病人入院日期	　	　
3	PB_DisChargeDate	病人出院日期	　	　
4	PB_PatInsType_DR	计费时病人的保险分类.	　	　
5	PB_PatAdmType_DR	计费时病人的入院分类	　	　
6	PB_DateFrom	本次计费的日期范围	　	　
7	PB_DateTo	本次计费的日期范围	　	　
8	PB_TotalAmount	本次计费的总额	　	　
9	PB_DiscAmount	本次计费的折扣额	　	　
10	PB_DiscType	折扣类型(内部类型: 病人折扣,项目折扣)	　	　
11	PB_PayorShare	本次费用记账额	　	　
12	PB_PatientShare	本次费用病人自付额	　	　
13	PB_AmountPaid	病人支付额	　	　
14	PB_AmounttoPay	病人应当支付额	　	　
15	PB_BillType	本次计费类型(门诊,住院,体检,急诊)	　	　
16	PB_PayedFlag	计费状态(Paid,Bill)	　	　
17	PB_UpdateDate	计费日期	　	　
18	PB_UpdateTime	计费时间	　	　
19	PB_UpdateUser	计费员	　	　
20	PB_RefundFlag	红冲标志	　	　
21	PB_OriginalBill_DR	原单号（在结账后发生红冲时）	　	　
22	PB_PatAdmType_DR	病人类型	DR	指向：PAC_EpisodeSubType表：6：普通病人
7：绿色通道病人
23	　	　	　	　
3.2.7.2账单明细表(账单字表)  DHC_PatBillOrder(^DHCPB)
序号	数据项	业务含义	类型	备注
1	PBO_ARCIM_DR	医嘱项指针ARC_ItmMast	　	　
2	PBO_OEORI_DR	病人医嘱指针OE_OrdItem	　	　
3	PBO_UnitPrice	医嘱单价	　	　
4	PBO_BillQty	总计费数量	　	　
5	PBO_RefundQty	退费数量	　	　
6	PBO_ TotalAmount	病人医嘱总费用	　	　
7	PBO_ DiscAmount	折扣部分	　	　
8	PBO_ PayorShare	病人记账部分	　	　
9	PBO_ PatientShare	病人自费部分	　	　
10	PBO_OrderDate	下医嘱日期	　	　
11	PBO_OrderTime	下医嘱时间	　	　
12	　	　	　	　
13	　	　	　	　
3.2.7.3账单收费项目明细表(账单孙子表)  DHC_PatBillDetails(^DHCPB)
序号	数据项	业务含义	类型	备注
1	PBD_PBO_Parref	　	　	　
2	PBD_TARI_DR	收费项目	　	　
3	PBD_UnitPrice	收费项目单价	　	　
4	PBD_BillQty	收费项目数量	　	　
5	PBD_DiscPerc	折扣率	　	　
6	PBD_TotalAmount	发生总数	　	　
7	PBD_DiscAmount	折扣数	　	　
8	PBD_PayorShare	记账数	　	　
9	PBD_PatientShare	病人自费数	　	　
10	PBD_BillDate	计费归属日期	　	　
11	PBD_BillTime	计费归属时间	　	　
12	PBD_BillStatus	(Bill,Paid)	　	　
13	PBD_CreateDate	计费日期	　	　
14	PBD_CreateTime	计费时间	　	　
15	PBD_BillUser	操作员	　	　
16	PBD_ExecDept_DR	计费归属科室	　	　
17	　	　	　	　
3.2.7.3住院发票表  DHC_invprtzy(^DHCINVPRTZY)
序号	数据项	业务含义	类型	备注
1	PRT_Rowid	Rowid	　	　
2	PRT_inv	发票号	　	　
3	PRT_Date	打印日期	　	　
4	PRT_Time	打印时间	　	　
5	PRT_Adm	指向表pa_adm	　	　
6	PRT_ARPBL	指向表dhc_patientbill	　	　
7	PRT_Acount	住院费用	　	　
8	PRT_Usr	打印人	　	　
9	PRT_Flag	打印标志：”A”代表作废，”N”代表正常，”S”代表冲红,”I”代表中途结算	　	　
10	PRT_PatType	病人收费 类型(In Patient,Out Patient) PAC_AdmReason	　	　
11	PRT_Approval	财务核销标志	　	　
12	PRT_AproUser	财务核销时间	　	　
13	PRT_Aprodate	财务核销日期	　	　
14	PRT_initInv	冲红时记录被冲的发票号	　	　
15	PRT_Handin	收款员结算标志	　	　
16	PRT_HandDate	收款员结算日期	　	　
17	PRT_HandTime	收款员结算时间	　	　
18	PRT_PAPMI_DR	指向表pa_patmas	　	　
19	PRT_ARRCP_DR	指向表ar_receipts	　	　
20	PRT_Invrpt_dr	　	　	　
21	PRT_initInv_DR	指向dhc_invprtzy	　	　
22	PRT_Deposit	押金总额	　	　
23	PRT_Jk_dr	收费员结算指针Dhc_jfuserjk	　	　
24	Prt_comment1	备用1	　	　
25	Prt_comment2	备用2	　	　
26	Prt_comment3	备用3	　	　
27	　	　	　	　
				
3.2.7.4收费员日报结算表DHC_jfuserjk(^DHCJFUSERJK)
序号	数据项	业务含义	类型	备注
1	Jk_date	交款日期	　	　
2	Jk_time	交款时间	　	　
3	Jk_stdate	开始日期	　	　
4	Jk_enddate	结束日期	　	　
5	Jk_user	交款人	　	　
3.2.7.5收费员日报表分类结算明细DHC_JFUSERJK(^DHCPB({DHC_PatientBill.PB_RowId},"O",{PBO_ChildSub}))
序号	数据项	业务含义	类型	备注
1	Cat_jk_dr	指向表dhc_jfuserjk	　	　
2	Cat_Num	分类张数	　	　
3	Cat_Fee	分类金额	　	　
4			　	　
5			　	　
3.2.7.6住院担保dhc_warrant
3.2.7.7预交金，应收款结算余额表dhc_jfyjacount
3.2.7.8应收款结算分类余额表dhc_jffeeacount
3.2.7.9欠费补交表dhc_jfqftotal
3.2.7.10支票到帐表dhc_jfbankback
3.2.7.11押金收据管理
3. 2.7.11.1押金收据购入DHC_sfbuy (^DHCSFBUY)
序号	数据项	业务含义	类型	备注
1	Buy_date	　购入日期	RowId	　
2	Buy_time	购入时间	Text	　
3	Buy_startno	开始号码	Text	　
4	Buy_endno	结束号码	String	　
	Buy_user	购入人		
	Buy_loc	部门		
	Buy_currentno	当前可发放的号码		
	Buy_useflag	可用标志，1：可用；2：已用完；空：待用		
	Buy_gruser	购入人		
	Buy_title	开始字母		
	Buy_payamt	金额		
	Buy_endno	结束号码		
	Buy_user	购入人		
	Buy_loc	部门		
	Buy_currentno	当前可发放的号码		
	Buy_useflag	可用标志，1：可用；2：已用完；空：待用		
	Buy_gruser	购入人		
	Buy_title	开始字母		
	Buy_payamt	金额		
3. 2.7.11.2财务科收据发放DHC_sfgrant(^DHCSFGRANT)
序号	数据项	业务含义	类型	备注
1	Grant_date	发放日期	RowId	　
2	Grant_time	发放时间	Text	　
3	Grant_startno	开始号码	Text	　
4	Grant_endno	结束号码	String	　
	Grant_user	发放人		
	Grant_loc	部门		
	Grant_currentno	当前可发放的号码		
	Grant_useflag	可用标志，1：可用；2：已用完；空：待用		
	grant_lquser	领取人		
	Grant_date	发放日期		
	Grant_time	发放时间		
	Grant_startno	开始号码		
	Grant_endno	结束号码		
	Grant_user	发放人		
	Grant_loc	部门		
	Grant_currentno	当前可发放的号码		
	Grant_useflag	可用标志，1：可用；2：已用完；空：待用		
				
				
3. 2.7.11.3住院处收据发放DHC_sfreceipt(^DHCSFRECEIPT)
序号	数据项	业务含义	类型	备注
1	Rcpt_date	发放日期	RowId	　
2	Rcpt_time	发放时间	Text	　
3	Rcpt_startno	开始号码	Text	　
4	Rcpt_endno	结束号码	String	　
	Rcpt_user	发放人		
	Rcpt_loc	部门		
	Rcpt_currentno	当前可使用的号码		
	Rcpt_useflag	可用标志，1：可用；2：已用完；空：待用		
	rcpt_lquser	领取人		
	Rcpt_title	开始字母		
	Rcpt_serialno			
	Rcpt_remain			
	Rcpt_usrsearialno			
	Rcpt_usrremain			
	Rcpt_original_dr	转交收据记录转交的原始rowid		
				
				
				
				
3. 2.7.11.4押金收据(发票购入)组定义DHC_ jfrcptgroupset 
序号	数据项	业务含义	类型	备注
1	Grp_rcpttype	组类型（门诊，住院，All）	RowId	　
2	grp_rcptgrptype		Text	　
3. 2.7.11.5押金收据（发票）人员定义DHC_ JFRcptGroupUser
序号	数据项	业务含义	类型	备注
1	grpuser_parref 	DHC_JFRcptGroupSet	RowId	　
2	grpuser_childsub		Text	　
	grpuser_ssgrp_dr	SS_Group		
	grpuser_ssusr_dr	SS_User		
3. 2.7.11.6退押金原因DHC_ jfyjrefreason
序号	数据项	业务含义	类型	备注
1	yjrrea_code	原因代码	RowId	　
2	yjrrea_desc	原因描述	Text	　
	yjrrea_date	创建日期		
	yjrrea_enddate	使用的截止日期		
	yjrrea_flag	可用标志		

3. 2.7.12发票管理
3. 2.7.12.1发票购入DHC_amtmag (^DHCAMTMAG)
序号	数据项	业务含义	类型	备注
1	Rcpt_date	发放日期	RowId	　
2	Rcpt_time	发放时间	Text	　
3	Rcpt_startno	开始号码	Text	　
4	Rcpt_endno	结束号码	String	　
	Rcpt_user	发放人		
	Rcpt_loc	部门		
	Rcpt_currentno	当前可使用的号码		
	Rcpt_useflag	可用标志，1：可用；2：已用完；空：待用		
	rcpt_lquser	领取人		
	Rcpt_title	开始字母		
	Rcpt_serialno			
	Rcpt_remain			
	Rcpt_usrsearialno			
	Rcpt_usrremain			
	Rcpt_original_dr	转交收据记录转交的原始rowid		
				
				
				
				
3. 2.7.12.2管理员领取发票DHC_amtdel (^DHCAMTDEL)
序号	数据项	业务含义	类型	备注
1	Deli_date	发放日期	RowId	　
2	Deli_time	发放时间	Text	　
3	Deli_getor	领取人	Text	　
4	Deli_stnum	开始号码	String	　
	Deli_endnum	结束号码		
	Deli_user			
	Deli_updatedat	更新日期		
	Deli_curinv	当前可发放号码		
	Deli_flag			
	Deli_loc	门诊/住院		
3. 2.7.12.3收费员领取发票DHC_invoice (^DHCINVOICE)
序号	数据项	业务含义	类型	备注
1	Inv_startinv	开始号码	RowId	　
2	Inv_endinv	结束号码	Text	　
3	Inv_user	领取人	Text	　
4	Inv_date	领取日期	String	　
	Inv_time	领取时间		
	Inv_lastnum	当前可用号码		
	Inv_finalflag	可用标志		
	Inv_type	部门（门诊/住院）		
	Inv_status			
	Inv_linkto			
	Inv_jynum			
	Inv_serialno			
	Inv_usrjynum			
	Inv_usrserialno			
3. 2.7.13押金管理
3. 2.7.13.1预交金明细DHC_sfprintdetail(^DHCSFPRINTDETAIL)
序号	数据项	业务含义	类型	备注
1	prt_rowid		RowId	　
2	prt_rcptno	收据号	Text	　
3	prt_printdate	打印日期	Text	　
4	prt_printtime	打印时间	String	　
	prt_adm_dr	指向pa_adm		
	prt_rcpt_dr	指向ar_receipts		
	prt_payamount	金额		
	prt_refundrcpt	被冲红的收据号		
	prt_status	收据状态“1”正常，”2”作废，”3”冲红，”4”已冲红，”5”打印		
	prt_paymode	支付方式		
	prt_bank	银行		
	prt_cardno	信用卡号		
	prt_company	支付单位		
	prt_deposit_dr	押金类型，指向arc_deptype为空时代表非押金		
	prt_adduserid	收款人		
	prt_deliverdate	转交日期		
	prt_delivertime	转交时间		
	prt_receivedate	接收日期		
	prt_receivetime	接收时间		
	prt_receiveuser	接收人		
	prt_jkuser	交款人		
	prt_jkflag	交款标志（即：也是收款员结算时间，每天上交财务科）		
	prt_jkdate	交款日期		
	prt_jktime	交款时间		
	prt_confirmuser	核销人		
	prt_confirmdate	核销日期		
	prt_confirmtime	核销时间		
	prt_confirmflag	核销标志		
	prt_deliverflag	转交标志		
	prt_title	标题		
	Prt_jk_dr	Dhc_userjk		
	Prt_comment1	备用1		
	Prt_comment2	备用2		
3. 2.7.13.2 病人支付纪录表(预缴金、支付、退款)AR_Receipts(^ARRCP)
序号	数据项	业务含义	类型	备注
1	ARRCP_Number          	预交金时为空，结算信息时保存发票号	RowId	　
2	ARRCP_Date            			
3	ARRCP_PayAmount       	金额		
4	ARRCP_AddUserID	用户		
5	ARRCP_AddDate	添加日期		
6	ARRCP_AddTime	添加时间		
7	ARRCP_PAPMI_DR         	病人信息rowid		病人信息表(PA_PatMas)
3. 2.7.13.3病人支付分配表Ar_rcptalloc(^ARRCP({AR_Receipts.ARRCP_RowId},"RAL",{ARRAL_ChildSub}))
序号	数据项	业务含义	类型	备注
1	ARRAL_ARRCP_ParRef  			RowId	　
2	ARRAL_RowId          				
3	ARRAL_ChildSub       				
4	ARRAL_PayAmt         				支付金额
5	ARRAL_PrevBal        				
6	ARRAL_Admission_DR  				病人PA_ADM的RowId
7	ARRAL_RcFlag         				
	ARRAL_Transact_DR    				
	ARRAL_Deposit_DR     		预缴金类型		ARC_DepType
	ARRAL_1stPayFlag    					
	ARRAL_ARPBIL_DR	病人账单指针		结算时，对应的帐单号DHC_PatientBill

3. 2.7.13.4 押金明细，出院结算Ar_rcptpaymode(^ARRCP({AR_Receipts.ARRCP_RowId},"PAYM",{PAYM_Childsub}))
病人一次付款，可能有多种支付方式
序号	数据项	业务含义	类型	备注
1	PAYM_PayMode_DR 	支付方式	RowId	支付方式CT_PayMode　
2	PAYM_CMBank_DR	银行id		银行id(CMC_BankMas)
3	PAYM_Amt	支付金额		
4	PAYM_Card_DR	卡类型		卡类型(Arc_BankCardType)工商卡，建行卡，银联等；
5	PAYM_CardChequeNo	卡或支票号		
6	PAYM_ChequeDate	支票日期		
7	PAYM_AddDate	操作日期		
	PAYM_AddTime	操作时间		


3.2.8 门诊收费信息
3.2.8.1收据信息主表Dhc_invprt(^DHCINVPRT({PRT_Rowid}))
序号	数据项	业务含义	类型	备注
1	PRT_Acount	收据金额数(票据费用总额)(不打折)	RowId	　
2	PRT_ARRCP_DR	指向表外键AR_Receipts	Text	TrakCare中的票据表　
3	PRT_Date	收费日期	Text	　
4	PRT_DHCINVPRTR_DR	关联结帐历史记录表	String	　指向DHC_INVPRTReports，收费员日结帐后建立的关联
	PRT_Flag	状态		Normal||N 正常
Abort||A  作废
Strike||S 冲红
	PRT_Handin	结帐标志		
	PRT_HandinDate	结帐日期		
	PRT_HandinTime	结帐时间		
	PRT_initInv_DR	冲红的原记录的ROWID		
	PRT_initInv	冲红的原发票号		指向DHC_INVPRT
	PRT_inv	发票号		
	PRT_PAPMI_DR	关联病人信息表		指向PA_PatMas
	PRT_PatType	病人类型		门诊 Out Patient
住院 In Patient
	PRT_Time	收费时间		
	PRT_Usr	收费员/或作废员		
	PRT_SocialStatus	指向CT_SocialStatus，作为患者类别；		
	PRT_INVPrintFlag	票据打印标志		NoPrint||N   没有打印
Printed||P   已经打印
正常的现金收费 标记 P
(原则:患者可以在没有结算帐户时随意打印发票,结算帐户时,一定打印发票;否则有些情况没法处理)
	PRT_ACCPINV_DR	指向DHCAccPayINV		帐户支付的集中打印发票
	PRT_PayorShare	病人记帐部分		
	PRT_DiscAmount	患者折扣部分		
	PRT_PatientShare	本次费用病人自付额		
	PRT_InsType_DR	PAC_AdmReason   患者结帐的费别		
	PRT_AllowRefund	允许作废标志		
	PRT_AllRefundUser	允许作废用户		
	PRT_AllRefundDate	允许作废日期		
	PRT_AllRefundTime	允许作废时间		
	新增字段	暂时不用了		
	PRT_PFinRep_DR	财务结算日期		把财务结算字段变为一个指向DHC_INVPRTFinRep的外键
	PRT_SfootTime	财务结算时间		
	PRT_SfootUser_DR	财务结算人员		
	PRT_OldINV_DR	对于部分退费发票新出得票据指向指向废票		
	PRT_InsuDiv_DR	指向INSU_Divide表		
	PRT_OPPreSum	门诊预收款		
	PRT_OPBackChange	找零		
	PRT_OPCRoundErr	分币误差		
	PRT_FairType	收费类型		
	PRT_AllRefundUser	允许作废用户		
	PRT_AllRefundDate	允许作废日期		
	PRT_AllRefundTime	允许作废时间		
	新增字段	暂时不用了		
	PRT_PFinRep_DR	财务结算日期		
	PRT_SfootTime	财务结算时间		
	PRT_SfootUser_DR	财务结算人员		
	PRT_OldINV_DR	对于部分退费发票新出得票据指向指向废票		废票
负票
新票
起作用的永远是新票
	PRT_InsuDiv_DR	指向INSU_Divide表		为医保保留的字段
此字段<>””表示此发票经过医保结算
=””表示此发票没有经过医保结算
	PRT_OPPreSum	门诊预收款		
	PRT_OPBackChange	找零		
	PRT_OPCRoundErr	分币误差		
	PRT_FairType	收费类型		
	PRT_OPPreSum	门诊预收款		
	PRT_OPBackChange	找零		
	PRT_OPCRoundErr	分币误差		误差金额说明：多收为正，少收为负；作日报和查询时要注意;
原则：就是方便操作员收费与找零，如果有医保，也是找整数
	PRT_FairType	收费类型		R:挂号，F：门诊收费
3.2.8.2票据账单连接表：DHC_BillConINV(^DHCBCI({DHCBCI_Rowid}))

序号	数据项	业务含义	类型	备注
1	DHCBCI_ADMDR	指向PA_Adm	　	　
2	DHCBCI_INVDR	指向DHC_INVPRT	　	　
3	DHCBCI_PatBillDR	指向DHC_PatientBill	　	　
3.2.8.3支付方式表 DHC_INVPayMode(^DHCINVPRT({DHC_INVPRT.PRT_Rowid},"P",{IPM_Sub}))
序号	数据项	业务含义	类型	备注
1	IPM_PRT_ParRef	指向父表DHC_INVPRT	　	　
2	IPM_Sub		　	　
3	IPM_PayMode_DR	支付方式	　	　
	IPM_CMBank_DR	银行卡或支票的银行信息		
	IPM_Amt	金额		
	IPM_CardChequeNo	卡支票号码		
	IPM_Card_DR	银行卡类型，包括自己发的卡		指向ARC_BankCardType工商卡，建行卡，银联等；医院发行的卡
	IPM_Date	支付日期		这个日期时间与父表的日期时间一致；主要是为了财务现金支付额提供财务报表
	IPM_Time	支付时间		
	IPM_AccPL_DR	指向DHCAccPayList		
	IPM_Unit	支付单位		患者所在工作单位等
	IPM_PayAccNO	支票对方账户号码		
	IPM_Note2			
	IPM_Note3			
	IPM_Note4			
	IPM_Note5			
	IPM_Note6			
				
				
				
				
				
				
				
				
				

IPM_Sub
$$next("^DHCINVPRT($p(%data(0),$c(1)),""P"",0)")

Index
1.^DHCINVPRTi(0,"Date",{IPM_Date},{DHC_INVPRT.PRT_Rowid},"P",{IPM_Sub})
2.^DHCINVPRTi(0,"PMDR",{DHC_INVPRT.PRT_Rowid},{IPM_PayMode_DR},"P",{IPM_Sub})
3.2.8统计信息
3.2.8.1收入数据表  DHC_WorkLoad

序号	字段名称	说明	类型	备注
1	WorkLoad_ARPBL_DR	帐单号DHC_PatientBill	Designative Reference	　
2	WorkLoad_BillGrp_DR	帐单大类ARC_BillGrp	Designative Reference	　
3	WorkLoad_BillSub_DR	帐单子类ARC_BillSub	Designative Reference	　
4	WorkLoad_CasherI_DR	SS_User	Designative Reference	　
5	WorkLoad_CasherO_DR	SS_User	Designative Reference	　
6	WorkLoad_DisDate	　	Date	　
7	WorkLoad_DisFlag	　	Text	　
8	WorkLoad_Flag	　	Text	　
9	WorkLoad_FlagDate	结算日期	Date	　
10	WorkLoad_FlagTime	　	Time	　
11	WorkLoad_HoldDep_DR	CT_Loc	Designative Reference	　
12	WorkLoad_HoldDoc_DR	CT_CareProv	Designative Reference	　
13	WorkLoad_HoldFlag	　	Text	　
14	WorkLoad_HoldFlagDate	　	Date	　
15	WorkLoad_ItemCat_DR	医嘱子类	Designative Reference	指向ARC_ItemCat
16	WorkLoad_ItemOrd_DR	医嘱项	Designative Reference	指向ARC_ItmMast
17	WorkLoad_OEORI_DR	医嘱OE_OrdItem	Designative Reference	　
18	WorkLoad_OrdDate	医嘱日期	Date	　
19	WorkLoad_OrdStatus	　	Multiple Choice	　
20	WorkLoad_OrdTime	　	　	　
21	WorkLoad_PAADM_DR	Pa_adm	Designative Reference	指向Pa_adm
22	WorkLoad_PAPMI_DR	PA_PatMas	Designative Reference	　
23	WorkLoad_PatDep_DR	下医嘱科室CT_Loc	Designative Reference	　
24	WorkLoad_PatDoc_DR	病人医生CT_CareProv	Designative Reference	　
25	WorkLoad_PatWard_DR	病人病区CT_Loc	Designative Reference	　
26	WorkLoad_Quantity	医嘱数量	　	　
27	WorkLoad_RecDep_DR	执行科室CT_Loc	Designative Reference	　
28	WorkLoad_RecDoc_DR	执行医生CT_CareProv	Designative Reference	　
29	WorkLoad_ReceiptI_DR	　	Text	　
30	WorkLoad_ReceiptO_DR	　	Text	　
31	WorkLoad_ResDep_DR	病人科室CT_Loc	Designative Reference	　
32	WorkLoad_ResDoc_DR	下医嘱医生CT_CareProv	Designative Reference	　
33	WorkLoad_Rowid	　	Row ID	　
34	WorkLoad_StatDate	插入数据日期	Date	　
35	WorkLoad_StatTime	　	Time	　
36	WorkLoad_TarAC_dr	会计分类DHC_TarAcctCate	Designative Reference	　
37	WorkLoad_TarEC_Dr	核算分类DHC_TarEMCCate	Designative Reference	　
38	WorkLoad_TarIC_Dr	住院分类DHC_TarInpatCate	Designative Reference	　
39	WorkLoad_TarItem_DR	收费项目DHC_TarItem	Designative Reference	　
40	WorkLoad_TarMC_Dr	病案分类DHC_TarMRCate	Designative Reference	　
41	WorkLoad_TarOut_Dr	门诊分类DHC_TarOutpatCate	Designative Reference	　
42	WorkLoad_TarSC_Dr	DHC_TarSubCate	Designative Reference	　
43	WorkLoad_TotalPrice	费用	　	　
44	WorkLoad_Type	病人类型	Multiple Choice	　
45	WorkLoad_UnitPrice	单价	　	　
46	WorkLoad_UserDep_DR	　	Designative Reference	　
47	WorkLoad_User_DR	　	Designative Reference	　
3.2.8.2挂号基础数据表  DHCWorkRegReport
序号	字段名称	说明	类型	备注
1	WR_Rowid	Rowid	Row id	　
2	WR_PAADM_DR	PA_Adm_rowid	Designative Reference	　
3	WR_SQINV_DR	DHC_Sqinv_rowid	Designative Reference	　
4	WR_ADMDoc_DR	挂号医生	Designative Reference	　
5	WR_ADMDEP_DR	所挂科室	Designative Reference	　
6	WR_ADMReason_DR	病人类型	Designative Reference	　
7	WR_ADMDate	挂号日期	Date	　
8	WR_RegUser	挂号员	Designative Reference	　
9	WR_RegType_Dr	挂号类别	Designative Reference	　
10	WR_PAPMI_Dr	病人papmi	Designative Reference	　
11	WR_AAMT	实际金额总数	Number	　
12	WR_Abook	实际病历本费用	Number	　
13	WR_Areg	实际挂号费	Number	　
14	WR_Adia	实际诊疗费	Number	　
15	WR_Status	状态	Multiple Choice	　
16	WR_HandDate	上交日期	Date	　
17	WR_Flag1	预约标志	text	　
18	WR_Flag2	号别种类标志	Text	　
19	WR_Flag3	打折标志	Text	　
20	WR_ Flag4	按号打折标志	Text	　
21	WR_Flag5	按金额打折标志	Text	　
22	WR_text1	预留字段1	Text	　
23	WR_text2	预留字段2	Text	　
24	WR_StatDate	记录插入表日期	Date	　
25	WR_StatTime	记录插入表时间	Time	　
26	WR_DateMonFlag	挂号日期月标志	Text	　
27	WR_SundayServer	周六周日业余服务	Text	　
28	WR_ AAMTRatio	提成金额（科室）	Number	　
29	WR_NumberFlag	挂号人次	Number	　
30	WR_ADMTime	挂号时间	Time	　
31	WR_CountFlag	挂号次数	Number	　
32	WR_HolidayServer	节假日	Number	　
33	WR_Text3	　	Text	　
34	WR_Text4	　	Text	　
35	WR_ADMSource_DR	病人来源	Designative Reference	　
36	WR_AdmReadm	初复诊	　	　
37	WR_AppMethod	预约方式	　	　
38	WR_AppFee	预约费用	　	　
39	WR_AdmAge	年龄	　	　
40	WR_AdmCity	城市	　	　
41	WR_AdmCityarea	区域	　	　
42	WR_AdmAddress	地址	　	　
43	WR_DocAMTRatio	医生提成	　	　
44	WR_MedicareFee	医保卡挂号费用	　	　
3.2.8.3工作量基础数据表  DHCMRIPDay
序号	字段名称	说明	类型	备注
1	MRIP_bednum	实际床数	Number	　
2	MRIP_BWRS	病危人数	Number	　
3	MRIP_creatdate	创建日期	Date	　
4	MRIP_creattime	创建时间	Time	　
5	MRIP_creatuser	创建人	Designative Reference	暂没用
6	MRIP_crrs	出院人数	Number	　
7	MRIP_date	日期	Date	　
8	MRIP_gdbednum	固定床数	Number	　
9	MRIP_knzc	科内转出	Number	　
10	MRIP_knzr	科内转入	Number	　
11	MRIP_loc_dr	病人科室	Designative Reference	　
12	MRIP_lyrs	原有人数	Number	　
13	MRIP_PHRS	陪护人数	Number	　
14	MRIP_QJRS	抢救人数	Number	　
15	MRIP_qnjc	期内加床	Number	　
16	MRIP_qnkc	期内空床	Number	　
17	MRIP_rowid	Row id	text	　
18	MRIP_ryrs	入院人数	Number	　
19	MRIP_subloc_dr	科室子组	Designative Reference	暂没用
20	MRIP_SWRS	死亡人数	Number	　
21	MRIP_tkzrrs	他科转入	Number	　
22	MRIP_tyrs	退院人数	Number	　
23	MRIP_WARD	病人病区	Designative Reference	　
24	MRIP_XYRS	现有（留院）人数	Number	　
25	MRIP_yydm	年	Text	　
26	MRIP_zwtkrs	转往他科人数	Number	　
3.2.8.4工作量明细数据表  DHC_MRIPDetail
序号	字段名称	说明	类型	备注
1	IPDE_MRIPDay_Dr	DHCMRIPDAY表ID	Designative Reference	　
2	IPDE_PAADM_Dr	病人ID	Designative Reference	　
3	IPDE_Rowid	Row id	Row id	　
4	IPDE_Type	类型	Text	　
3.2.8.5急诊累计数据表  DHCWLAddReport
序号	字段名称	说明	类型	备注
1	AddReport_Date	　	Date	　
2	AddReport_ECCat_Dr	核算分类	Designative Reference	　
3	AddReport_FlagPrice	结算费用	Number	　
4	AddReport_ItemDr	医嘱项	Text	　
5	AddReport_ItemLocFlag	　	Designative Reference	　
6	AddReport_LastAddPrice	上期余额	Number	　
7	AddReport_MonFlag	月标志	Text	　
8	AddReport_NowAddPrice	本期余额	Number	　
9	AddReport_OrdPrice	实际发生费用	Number	　
10	AddReport_PatLocDr	病人科室	Designative Reference	　
11	AddReport_PatType	病人类型	Multiple Choice	　
12	AddReport_Rowid	Row id	Row id	　
13	AddReport_StatDate	插入数据日期	Date	　
14	AddReport_StatTime	插入数据时间	Time	　
3.2.8.6床位维护表  DHC_MRBed
序号	字段名称	说明	类型	备注
1	MR_BZNum	备用床位数	Number	　
2	MR_Date	日期	Date	　
3	MR_GDNum	固定床位数	Number	　
4	MR_Loc	科室	Designative Reference	CT_Loc
5	MR_SYNum	实有床数	Number	　
6	MR_Ward	病区	Designative Reference	PAC_Ward
3.2.9手术麻醉信息
3.2.9.1麻醉表  DHCWL_Anaesthesia
序号	字段名称	说明	类型	备注
1	WLAN_PAADM_DR	病人ADM	Designative Reference	关联PAADM
2	WLAN_PAPMI_DR	病人PAPMI	Designative Reference	关联PaPatmas
3	WLAN_ADMReason_DR	病人身份类型	Designative Reference	关联Pac_AdmReason
4	WLAN_Type	病人类型(门诊，住院等)	Multiple Choice	　
5	WLAN_PatLoc_DR	病人所在科室	Designative Reference	关联CTLOC
6	WLAN_ PatWard _DR	病人所在病区	Designative Reference	　
7	WLAN_PatDoc_dr	病人医生	Designative Reference	　
8	WLAN_Method	麻醉方式	Designative Reference	OR_Anaesthesia. ANA_Method
9	WLAN_ AnaesthesiaDoc_DR	麻醉医生	Designative Reference	OR_Anaesthesia. ANA_Anaesthetist_DR
10	WLAN_SDate	麻醉开始日期	Date	　
11	WLAN_STime	麻醉开始时间	Time	　
12	WLAN_EDate	麻醉结束日期	Date	　
13	WLAN_ETime	麻醉结束时间	Time	　
14	WLAN_Continuance	手术持续时间(分钟)	Number	　
15	WLAN_WrDoc_Dr	添记录(申请)医生	Designative Reference	　
16	WLAN_WrDocDep_Dr	填记录医生所在科室	Designative Reference	　
17	WLAN_Cut_DR	切口	Designative Reference	MR_Adm（MRADM_DischClassif_Dr-）PAC_DischClassification）
18	WLAN_OperRoom_DR	手术间	Designative Reference	关联DHC_ANOperRoom
19	WLAN_RecLoc_DR	病人接收科室	Designative Reference	关联CTLOC
20	WLAN_Complication1	术后并发症1	Designative Reference	关联OR_AnaestComplications
21	WLAN_Complication2	术后并发症2	Designative Reference	关联OR_AnaestComplications
22	WLAN_ MonitorDevice1	监护设备1	Designative Reference	关联ORC_Equipment
23	WLAN_ MonitorDevice2	监护设备2	　	关联ORC_Equipment
24	WLAN_ MonitorDevice3	监护设备3	　	关联ORC_Equipment
25	WLAN_ MonitorDevice4	监护设备4	　	关联ORC_Equipment
26	WLAN_ MonitorDevice5	监护设备5	　	关联ORC_Equipment
27	WLAN_RHBolldType	RH血型	　	指向血型表ORC_BloodType
28	WLAN_PatHeight	病人身高（单位厘米）	　	numeric
29	WLAN_PatWeight	病人体重（单位公斤）	　	numeric
30	WLAN_DeadDate	病人死亡日期	　	　
31	WLAN_ToLoc_DR	出室去向科室（ICU/SICU）指向表CT_Loc	　	关联CTLOC
32	WLAN_ Evaluate_DR	DHC_ANPreOperEval术前评估	　	关联ORC_ASA_ClassPhActiv
33	WLAN_ Units	手术例数	　	1
34	WLAN_ Price	手术金额	　	　
35	WLAN_Counts	手术总数	　	　
36	WLAN_BloodAnount	备血量	　	numeric
37	WLAN_Memo	备注	　	Text(100)
38	WLAN_ Anaest _Type	麻醉类型	　	关联ORC_AnaestType
39	WLAN_ Anaest_Complications	麻醉并发症	　	关联ORC_Anaest_Complications
40	WLAN_ASA	ASA分级	　	关联ORC_ASA_ClassPhActiv
41	WLAN_Date	插入数据日期	　	　
42	WLAN_Time	插入数据时间	　	　
43	WLAN _OPER_DR	手术名称	　	OR_Anaest_Operation（ANAOP_Type_DR-）ORC_Operation）
44	WLAN _ICD_DR	手术icd	　	关联MRC_ICDDx
45	WLAN _PreopDiag_DR	术前诊断	　	OR_Anaest_Operation .ANAOP_PreopDiag_DR
46	WLAN _PostDiag_DR	术后诊断	　	　
47	WLAN _DiagFlag	术前术后诊断是否一致	　	Y/N
48	WLAN _BodySite_DR	身体部位	　	ORC_OperPosition
49	WLAN _OPDate	手术日期	　	OR_Anaest_Operation .ANAOP_OpStartDate
50	WLAN _OPTime	手术时间	　	OR_Anaest_Operation .ANAOP_OpStartTime
51	WLAN _OpDoc_DR	手术医生	　	　
52	WLAN _DocDep_DR	手术医生所在科室	　	　
53	WLAN _ AssistDoc1_DR	手术助理医生1	　	OR_An_Oper_Assistant（OPAS_Assist_DR->CT_CareProv）
54	WLAN _ AssistDoc2_DR	手术助理医生2	　	OR_An_Oper_Assistant（OPAS_Assist_DR->CT_CareProv）
55	WLAN _ AssistDoc3_DR	手术助理医生3	　	OR_An_Oper_Assistant（OPAS_Assist_DR->CT_CareProv）
56	WLAN _AnFADoc1_DR	助理麻醉医生1	　	OR_An_Oper_Anaest_Assistant（ANASS_CTCP_DR-> CT_CareProv）
57	WLAN _AnFADoc2_DR	助理麻醉医生2	　	OR_An_Oper_Anaest_Assistant（ANASS_CTCP_DR-> CT_CareProv）
58	WLAN _AnFADoc3_DR	助理麻醉医生3	　	OR_An_Oper_Anaest_Assistant（ANASS_CTCP_DR-> CT_CareProv）
59	WLAN _CirNurse1_DR	巡回护士	　	　
60	WLAN _CirNurse2_DR	巡回护士	　	　
61	WLAN _ScrNurse1_DR	器械护士	　	　
62	WLAN _ScrNurse2_DR	器械护士	　	　
3.2.9.1手术表 DHCWL_AnOperation
序号	字段名称	说明	类型	备注
1	WLOP_OPER_DR	手术名称	Designative Reference	OR_Anaest_Operation（ANAOP_Type_DR-）ORC_Operation）
2	WLOP_OPER_Type	主次手术标志	Multiple Choice	M\S
3	WLOP_ICD_DR	手术icd	Designative Reference	关联MRC_ICDDx
4	WLOP_ UnitPrice	单价	Number	　
5	WLOP_Units	次数	Number	　
6	WLOP_Price	总价	Number	　
7	WLOP_PreopDiag_DR	术前诊断	Designative Reference	OR_Anaest_Operation .ANAOP_PreopDiag_DR
8	WLOP_PostDiag_DR	术后诊断	Designative Reference	　
9	WLOP_DiagFlag	术前术后诊断是否一致	Multiple Choice	Y/N
10	WLOP_BodySite_DR	身体部位	Designative Reference	ORC_OperPosition
11	WLOP_Date	手术日期	Date	OR_Anaest_Operation .ANAOP_OpStartDate
12	WLOP_Time	手术时间	Time	OR_Anaest_Operation .ANAOP_OpStartTime
13	WLOP_OpDoc_DR	手术医生	Designative Reference	　
14	WLOP_DocDep_DR	手术医生所在科室	Designative Reference	　
15	WLOP_ AssistDoc1_DR	手术助理医生1	Designative Reference	OR_An_Oper_Assistant（OPAS_Assist_DR->CT_CareProv）
16	WLOP_ AssistDoc2_DR	手术助理医生2	Designative Reference	OR_An_Oper_Assistant（OPAS_Assist_DR->CT_CareProv）
17	WLOP_ AssistDoc3_DR	手术助理医生3	Designative Reference	OR_An_Oper_Assistant（OPAS_Assist_DR->CT_CareProv）
18	WLOP_AnFADoc1_DR	助理麻醉医生1	Designative Reference	OR_An_Oper_Anaest_Assistant（ANASS_CTCP_DR-> CT_CareProv）
19	WLOP_AnFADoc2_DR	助理麻醉医生2	Designative Reference	OR_An_Oper_Anaest_Assistant（ANASS_CTCP_DR-> CT_CareProv）
20	WLOP_AnFADoc3_DR	助理麻醉医生3	Designative Reference	OR_An_Oper_Anaest_Assistant（ANASS_CTCP_DR-> CT_CareProv）
21	WLOP_CirNurse1_DR	巡回护士	Designative Reference	　
22	WLOP_CirNurse2_DR	巡回护士	Designative Reference	　
23	WLOP_ScrNurse1_DR	器械护士	　	　
24	WLOP_ScrNurse2_DR	器械护士	　	　
3.2.10就诊卡管理表
3.2.7.1 卡类型表DHC_CardTypeDef
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	CTD_RowID						
2	CTD_Code	卡类型代码	Text		No		
3	CTD_Desc	卡类型描述	Text	20			
4	CTD_Note1		Text	50			
5	CTD_Note2						
6	CTD_Note3						
							

3.2.7.1卡信息表 DHC_Cardref
Global:^DHCCARD(“CF”,{CF_RowID}
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	CF_RowID						
2	CF_AccNo_DR	帐户代码外键	DR		No		说明此卡所挂的帐户(DHC_AccManager)
	CF_CardNo	卡号	Text				
3	CF_SecurityNO	卡的安全号码	Text				
4	CF_PAPMI_DR	指向PA_PatMas表	DR				
5	CF_IDCardNo	身份证号码	Text	30			
6	CF_PAPMINo	登记号	Text	30			
7	CF_Date	发卡日期	Date				
8	CF_Time	发卡时间	Time				
9	CF_User_DR	发卡人	DR				
10	CF_ActiveFlag	有效卡标志	Multi				Normal||N  正常
Suspend||S  挂失
Reclaim||R  回收
Depose||D  作废(此时，不能再次使用)
11	CF_DateFrom	Date					
12	CF_DateTo	Date					
13	CF_CancleDate						
14	CF_CancleTime						
15	CF_CancleUser_DR	SS_User	DR				
16	CF_Note1						
17	CF_Note2						
18	CF_Note3						
							
							
3.2.7.2卡的状态变化表：DHC_CardStatusChange
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	CSC_CF_ParRef						
2	CSC_RowID						
3	CSC_Sub						
4	CSC_Date	状态变化日期					
5	CSC_Time	状态变化时间					
6	CSC_CurStatus	当前的状态	Multi				同上的状态
N||Normal  正常
S||Suspend  挂失
R||Reclaim  回收
D||Depose  作废(此时，不能再次使用)
7	CSC_User_DR	操作员	DR				
8	CSC_ComputerIP	计算机的IP	Text				
9	CSC_Note1						
10	CSC_Note2						
11	CSC_Note3						
							
							
							

注意:卡管理表每变化一次，此状态表就写一条记录；记录当时操作的情况
3.2.7.3证件类型：DHC_CredType
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	CRT_RowID						
2	CRT_Code	证件代码	Text		No		身份证
学生证
军官证
驾照
3	CRT_Desc	证件类型描述	Text				
							
							

3.2.7.4卡账户表DHC_AccManager
Global Name：^DHCACD (“AccM”,{AccM_RowID})
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	AccM_AccountNo	帐户号	Text	16	YYYYMMDD+0000		为了与RowID分开，把此帐户号等同于预缴金的流水号。
2	AccM_PAPMI_DR	登记号RowID	DR				指向Pa_PatMas表
3	AccM_PAPMINo	登记号	Text	12			
4	AccM_CardNo	卡号	Text	30			此卡号与CardManager中的CardNo一致
5	AccM_OCDate	开户日期	Date				
6	AccM_OCTime	开户时间	Time				
7	AccM_Cuser_DR	开户人员	DR				指向SS_User表
8							
9	AccM_Balance	帐户余额(预缴金余额)	Number			0	
10	AccM_WoffDate	销户日期	Date				
11	AccM_WoffTime	销户时间	Time				
12	AccM_Duser_DR	销户人员	DR				指向SS_User表
13	AccM_PassWord	帐户密码					特指：需要加密，要求有一个算法。
14	AccM_AccStatus	帐户状态	Mutlti				Normal||N激活(N)
Foot|| F结算(F)
Suspend|| S帐户挂起(S)
15	AccM_DepPrice	帐户限支/透支额度	Number				患者在就诊时，最低的消费下限（可以支持透支,或限制支付等功能）
16	AccM_BadPrice	患者结算时产生坏账，给财务报坏账准备	Number				
17	AccM_Type	个人/集体账户标志	Multi				Person||P个人
Collect||C集体
18	AccM_CredType_DR	证件类型指向	DR				指向DHC_CredType
19	AccM_CredNo	证件号码，此号码相对于帐户来讲是稳定的；而卡号可能是不稳定的	Text				用来
20	AccM_Note1						
21	AccM_Note2						
22	AccM_Note3						
23	AccM_Note4						
24	AccM_Note5						
							
							
3.2.7.5预交金流水账：DHC_AccPreDeposit
Global Name： ^DHCACD("AccM",{DHC_AccManager.AccM_RowID},”AccPD”{AccPD_Sub})

序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	AccPD_ParRef		DR				父表DHC_AccManager
2	AccPD_RowID		Row ID				
3	AccPD_Sub						
5	AccPD_AccountNo	帐户号(预缴金编号)					(考虑不加在表中)
4	AccPD_Type	缴款类型	Multi	3			Pay||P缴款
Refund||R退费
Trans||T转帐
Foot||F结算帐户的缴退款
7	AccPD_Mode	缴款方式(用子表表示)	Number	3			1现金
2支票
3银行卡
4 
5	AccPD_PreSum	缴款额度	Number				
6	AccPD_PreDate	缴款日期	Date				
7	AccPD_PreTime	缴款时间	Time				
8	AccPD_User_DR	收款人员	DR				
9	AccPD_BillNum	票据号	Text				
10	AccPD_PDFoot_DR	结算时间外键	DR				DHC_AccPFoot
11	AccPD_Left	帐户余额	Number				
12	AccPD_BackReason	退款原因；	Text	100			
13	AccPD_Note1						
14	AccPD_Note2						
15	AccPD_Note3						
16	AccPD_Note4						
17	AccPD_Note5						
							
3.2.7.6卡帐户预交金的支付方式表DHC_AccPrePayMode   
支持：现金/支票/汇票/银行卡  
^DHCACD("AccM",{DHC_AccManager.AccM_RowID},”AccPD”{AccPD_Sub},”P”{ APPM_Sub })

3.2.7.7卡支付流水帐表：DHC_AccPayList
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	AccPL_ParRef	对应父表	DR		Not Null		DHC_AccManager
2	AccPL_RowID	Row ID	Row ID				RowID
3	AccPL_Sub		Number				
4	AccPL_PAPMI_DR	指向PA_PatMas表					指向此支付额为哪个患者支付的；
对于患者没有账户仍然可以支付
5	AccPL_InvPrt_DR	门诊结算票据管理的RowID	DR				对应表DHC_Invprt
6	AccPL_PAPMINo	患者的登记号	Text				在PA_PatMas中
7	AccPL_BillNo	小票号码(此号码可打可不打，决定权在项目)，可以加上审批权来代替这个	Text				与打印出来的票据号一致，格式：
登记号码_
8	AccPL_User_DR	服务/会计人员RowID，操作此支付的人员	DR				指向SS_User
9	AccPL_PayDate	卡支付日期	Date				对应账单支付的日期
10	AccPL_PayTime	卡支付时间	Time				对应账单支付的时间
11	AccPL_PayNum	支付金额	Number			0	
12	AccPL_Left	账户余额	Number				
13	AccPL_PayRecLoc_DR	患者支付时，所在的科室	DR				CT_Loc
14	AccPL_Note1		Number				
15	AccPL_Note2		DR				
16	AccPL_Note3						
17	AccPL_Note4						
							
							
							
							

卡支付流水帐：DHC_AccPayList
Data Master
^DHCACD("AccM",{DHC_AccManager.AccM_RowID},”AccPL”{AccPL_Sub})
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	APPM_AccPD_ParRef	指向预交金表DHC_AccPreDeposit	DR				
2	APPM_RowID		RowID				
3	APPM_Sub		Number				
4	APPM_PayMode_DR	支付方式					指向CT_PayMode
5	APPM_Card_DR	银行卡类型；例如工商卡，龙卡等	DR				指向ARC_BankCardType
工商卡，建行卡，银联等；
6	APPM_CardChequeNo	银行卡，支票等号码(此号码与账户有区别)	Text				
7	APPM_CMBank_DR	支票发行银行/银行卡发行银行	DR				指向CMC_BankMas
8	APPM_Branch	支付单位	Text	150			患者所在单位等
9	APPM_Amt	支付额					
10	APPM_PayAccNO	对方的帐户号(支付的帐号)					
11	APPM_ChequeDate	支票日期	Text				
12	APPM_Date	预交金支付日期	Date				
13	APPM_Time	预交金支付时间	Time				
14	APPM_Remark	备注					
15	APPM_Note1		Text				
16	APPM_Note2		Text				
17	APPM_Note3		Text				
18	APPM_Note4						
19	APPM_Note5						
							
							
							


3.2.7.8卡支付与预交金结算流水帐对帐：DHC_AccPFoot
（针对于会计的总账）
Global Name： ^DHCACD("AccPF",{AccPF_RowID})

序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	AccPF_RowID		RowID				
2	AccPF_Date	本次报表对帐日期	Date				
3	AccPF_Time	本次报表对帐时间	Time				
4	AccPF_User_DR	报表操作人	DR				SS_User
5	AccPF_LastDate	上次报表对帐日期	Date				
6	AccPF_LastTime	上次报表对帐时间	Time				
7	AccPF_PreLeftSum	前期余额汇总	Number				
8	AccPF_PreSum	收预缴金流水汇总	Number				是财务已结算，此值与出纳本次收预缴款一致。
9	AccPF_CardPaySum	卡支付流水汇总(是计算的出)	Number				是财务已结算，此值与出纳手中卡消费汇总一致
10	AccPF_LeftSum	本期余额	Number				此数与出纳手中的预缴金余款一致，总预缴款余额
11	AccPF_RefundPreSum	退预缴金流水汇总	Number				是财务已结算，此值与出纳本次退/结算预缴款一致。
12	AccPF_Note1						
13	AccPF_Note2						
14	AccPF_Note3						
15	AccPF_Note4						
16	AccPF_Note5						
17	AccPF_Note6						
18	AccPF_Note7						
19	AccPF_Note8						
20	AccPF_Note9						
							

3.2.7.9卡支付流水帐结算子表：DHC_AccPFootSub  
（应该是一个平衡的结算账） 对于单个患者的明细帐
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	AccPFS_ParRef		DR				指向父表DHC_AccPFoot
2	AccPFS_RowID	RowID	RowID				
3	AccPFS_Sub		Number				
4	AccPFS_AccM_DR	账户的RowID	DR				指向DHC_AccManager
5	AccPFS_PreLeft	前期余额					
6	AccPFS_PrePay	收预缴金之和					
7	AccPFS_CardPay	卡支付之和					
8	AccPFS_CurLeft	本期余额					这几个数值都是计算出来的算法可能比较麻烦
9	AccPFS_RefundPrePay						退预缴金之和
							
							
							
							
							

3.2.7.10预交金结算日报：DHC_AccPDFootLog   
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
	AccPDF_RowID						
1	AccPDF_Date	结算日期	Date				
2	AccPDF_Time	结算时间	Time				
3	AccPDF_User_DR	结算员用户RowID	DR				SS_User
4	AccPDF_LastDate	上次结算日期	Date				
5	AccPDF_LastTime	上次结算时间	Time				
6	AccPDF_OperUser_DR	收款员用户RowID	DR				SS_User
7	AccPDF_INSFootUser	财务接收人员	DR				SS_User
8	AccPDF_INSFootDate	财务接收日期	Date				
9	AccPDF_INSFootTime	财务接收时间	Time				
10	AccPDF_Note1						
11	AccPDF_Note2						
12	AccPDF_Note3						
13	AccPDF_Note4						
14	AccPDF_footnum						
15	AccPDF_refundnum						
16	AccPDF_footsum						
17	AccPDF_pdsum						
18	AccPDF_refundsum						
19	AccPDF_cashsum						
20	AccPDF_chequesum						
21	AccPDF_othersum						
22	AccPDF_rcptstr						
23	AccPDF_Other1						
24	AccPDF_Other2						
25	AccPDF_Other3						
26	AccPDF_Other4						
27	AccPDF_Other5						
28	AccPDF_Other6						
29	AccPDF_Other7						
30	AccPDF_Other8						
31	AccPDF_Other9						
32	AccPDF_Other10						
							
							


3.2.7.11账户更改日志表DHC_AccStatusChange
数据 :^DHCACD("AccM",{DHC_AccManager.AccM_RowID},"SC",{AccSC_Sub})

序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
0	AccSC_ParRef	子表	DR				父表DHC_AccManager
1	AccSC_RowID		RowID				
2	AccSC_Sub						
3	AccSC_Ovalue	修改原值	Text				
4	AccSC_Nvalue	修改值(现在的值)	Text				
5	AccSC_Left	账户余额	Number				
6	AccSC_OperDate	操作日期	Date				
7	AccSC_OperTime	操作时间	Time				
8	AccSC_User_DR	操作人员	DR				
9	AccSC_Note	操作说明日志（备注）					说明文档.
10	AccSC_Note1						
11	AccSC_Note2						
12	AccSC_Note3						
13	AccSC_Note4						
							
							


其他
UDHCJFREBILL.MAC	记录重新生成账单的原始账单	^DHCBILLDEL(+$h,bill)=adm_"^"_bill
UDHCJFREBILL.MAC	记录重新生成账单的新产生的账单	^DHCBILLDELNEW(bill)=adm_"^"_bill
UDHCJFPAY.MAC	记录账单结算时的押金的rowid,以便红冲后能够找到押金的明细，否则取消结算后对应的押金的明细的账单号取消，找不到对应的押金明细	^DHCJFDepositRowID("ZYJF",billno)=yjrowid
UDHCJFPBCANCEL.MAC	记录红冲的押金的rowid	^DHCJFDepositRowID("ZYJF",RedBill)=yjrowid
		
收费员与计算机关联表（为实现上海东方医院发票绑定到电脑添加此表）Dhcjfuserlinkcomputer (^DHCJFULC("ULC",0,{ULC_Rowid}))
ULC_Rowid 		
ULC_UserDr	收款员Dr	SS_User
ULC_ComputerDr	计算机Dr	临时使用Global保存计算机信息
ULC_GroupDr	安全组Dr	SS_Group
ULC_Flag	发票或押金标志	I:发票，D:押金
ULC_Comment1	备用	
ULC_Comment2	备用	
ULC_Comment3	备用	
ULC_Comment4	备用	
		
		

计算机维护表(发票与计算机绑定时用)dhc_jfcomputer（^DHCJFPC({DHC_JFPCRowid})）
DHC_JFPCRowid		
DHC_JFPCCode	CODE	
DHC_JFPCDesc	描述	
DHC_JFPCComent1	备用	
DHC_JFPCComent2	备用	
		


DHC_CurrentHospital  医院代码表
^DHCJFConfig       记录住院业务参数的globe。

货币与汇率表CT_Currency 货币(父)^CT("CUR",{CTCUR_RowId})
序号	列名		描述	节点	备注
1	CTCUR_Code				
2	CTCUR_Desc				
3	CTCUR_ExchangeRate				
4	CTCUR_DecimalChar				
5	CTCUR_TaxAmt				
6					

CT_ExChgRate 汇率(子)
^CT("CUR",{CT_Currency.CTCUR_RowId},"EXC",{CTEXC_ChildSub})
序号	列名		描述	节点	备注
1	CTEXC_CTFP_DR				
2	CTEXC_Rate				
3	CTEXC_Date				
4					
5					
6					



票据结算表：DHC_INVPRTReports(^DHCOPInsFoot)    
在此表的基础上实现财务人员的结算；
序号	数据项	业务含义		长度	可否为空	备注说明
	HIS_RowID	表的RowID				
1	HIS_Date	操作员结算日期	Date			
2	HIS_Time	操作员结算时间	Time			
3	HIS_StartDate	结算开始日期	Date			
4	HIS_StartTime	结算开始时间	Time			
5	HIS_EndDate	结算结束日期	Date			可能与操作员结算日期一致
6	HIS_EndTime	结算结束时间	Time			
7	HIS_Amount	结算费用总额	Text			应收费用总额，对于有卡支付的项目；=现金支付票据金额+卡支付票据金额
8	HIS_User	操作员RowID	DR			
9	HIS_Num	票据数量	Number			打印的票据数量（这里面包括收款员自己作废的票据）
10	HIS_RcptNO	票据号码段文本描述				
11	HIS_Confirm					
12	HIS_Collect					
13	HIS_INSFootDate	财务人员结算日期	Date			在积水潭一定要增加这个功能，财务提供总体的结算功能
14	HIS_INSFootTime	财务人员结算时间	Time			
15	HIS_INSFootUser	财务结算人	DR			
16	HIS_PatSum	应缴费用总额,	Text			这个是患者结算时，交给操作员的费用总额,  实收费用;  不包括医保的
患者实缴金额=门诊收费金额+预交金支付金额+
17	HIS_CashNum	现金张数	Text			对于DHC_INVPRT表
18	HIS_CashSum	现金金额	Text			对于DHC_INVPRT表
19	HIS_CheckNum	支票张数	Text			对于DHC_INVPRT表
20	HIS_CheckSum	支票金额	Text			对于DHC_INVPRT表
21	HIS_RefundNum	红冲张数	Text			对于DHC_INVPRT表
22	HIS_RefundSum	红冲金额	Text			对于DHC_INVPRT表
23	HIS_ParkNum	作废张数	Text			对于DHC_INVPRT表
24	HIS_ParkSum	作废金额	Text			对于DHC_INVPRT表
25	HIS_ParkINVInfo	作废票据信息	Text			对于DHC_INVPRT表
26	HIS_RefundINVInfo	红冲票据信息	Text			对于DHC_INVPRT表
27	HIS_OterPayNum	除了现金支票之外支付	Number			为其他支付方式的备留字段
28	HIS_OterPaySum		Number			
29	HIS_INVRoundSum	作为分币误差				
30	HIS_YBSum	医保支付	Number			对于DHC_INVPRT表的医保支付字段
31	HIS_CardNum		Number			对于DHC_AccPayINV表
32	HIS_CardSum		Number			对于DHC_AccPayINV表
33	HIS_CardYBSum	卡支付中的医保支付总额	Number			对于DHC_AccPayINV表
34	HIS_CardRefNum	卡支付红冲张数	Number			对于DHC_AccPayINV表
35	HIS_CardRefSum	卡支付票据红冲金额	Number			对于DHC_AccPayINV表
36	HIS_CardYBRefSum	卡支付中医保退费总额	Number			对于DHC_AccPayINV表
37	HIS_CardCashRefSum	卡支付红冲退现金额	Number			对于DHC_AccPayINV表
38	HIS_CardParkNum	卡支付作废张数	Number			对于DHC_AccPayINV表
39	HIS_CardParkSum	卡支付作废票据总额	Number			对于DHC_AccPayINV表
40	HIS_CardYBParkSum	卡支付中医保退费总额	Number			对于DHC_AccPayINV表
41	HIS_CardCashParkSum	卡支付中退费退现金总额	Number			对于DHC_AccPayINV表
42	HIS_CardParkINVInfo	卡支付作废票据信息	Text			对于DHC_AccPayINV表
43	HIS_CardRefundINVInfo	卡支付红冲票据信息	Text			对于DHC_AccPayINV表
44	HIS_Note1		Text			
45	HIS_Note2		Text			
46	HIS_Note3		Text			
47	HIS_Note4		Text			
48	HIS_Note5		Text			
49	HIS_Note6		Text			
50	HIS_Note7		Text			
51	HIS_Note8		Text			
52	HIS_Note9		Text			
53	HIS_Note10		Text			
54	HIS_Note11		Text			
55	HIS_Note12		Text			
						
Index
	Index INSFootDate
^DHCOPInsFootI


合肥项目中字段转换：
44	HIS_Note1	->HIS_CPPNum	Text			
45	HIS_Note2	->HIS_CPPSum	Text			
46	HIS_Note3	->HIS_GetTotal	Text			
47	HIS_Note4	->HIS_GiveTotal	Text			
48	HIS_Note5	->HIS_CashTotal	Text			
49	HIS_Note6	->HIS_CheckTotal	Text			
50	HIS_Note7	->HIS_OtherTotal	Text			
51	HIS_Note8		Text			
52	HIS_Note9		Text			
53	HIS_Note10		Text			
54	HIS_Note11		Text			
55	HIS_Note12		Text			

票据结算表：DHC_INVPRTReportsSub (^DHCOPInsFoot)   
添加门诊收费子类；
序号	数据项	业务含义	类型	长度	可否为空	备注说明
1	HisSub_ParRef	指向父表	RowID			
2	HisSub_Cat_DR	指向DHC_TarOC	DR			
3	HisSub_Acount	票据金额	Text			
4						
						
票据结算表：DHC_INVPRTReportsPaymode
添加门诊收费子类；
序号	数据项	业务含义	类型	长度	可否为空	备注说明
1	HisPay_ParRef	指向父表	RowID			
2	HisPay_RowID	指向DHC_TarOC	DR			
3	HisPay_ChildSub	票据金额	Text			
4	HisPay_Acount	收费金额				
5	HisPay_Paymode	支付模式				
6	HisPay_Refund	退票据数量				
7	HisPay_Refundsum	退费金额				
8	HisPay_num	收费数量				
9	HisPay_PRDGetNum	收预交金笔数				
10	HisPay_PRDGetSum	收预交金金额				
11	HisPay_PRDParkNum	退预交金笔数				
12	HisPay_PRDParkSum	退预交金金额				
13	HisPay_StrikRefSum	票据红冲  退费金额				
14	HisPay_StrikRefNum	票据红冲 退费数量				
15	HisPay_StrikGetSum	票据红冲 出的新的票据金额				特殊
16	HisPay_StrikGetNum	票据红冲 出的新的票据数量				特殊
17	HisPay_Note9					
18	HisPay_Note10					
19						
						


建立此表的目的：对于患者当场不缴钱的一个逻辑统计对于发票表Total-PaySum的差值，可以整体上叫做记帐，这个专门针对患者类型；

票据结算表：DHC_INVPRTReportsInsTypeCharge
添加门诊收费 患者费别分类；
序号	数据项	业务含义	类型	长度	可否为空	备注说明
1	ITC_Rep_ParRef	指向父表	RowID			
2	ITC_RowID	RowID	DR			
3	ITC_ChildSub		Text			
4	ITC_InsType_DR	指向费别表PAC_AdmReason				
5	ITC_TallNum	记帐的票据张数				
6	ITC_TallySum	记帐金额				
7	ITC_RefTallyNum	记帐的退费张数				
8	ITC_RefTallySum	记帐的退费金额				
9	ITC_Note1					
10	ITC_Note2					
11	ITC_Note3					
12	ITC_Note4					
13	HisPay_Note5					
14	HisPay_Note6					
15	HisPay_Note7					
16	HisPay_Note8					
17	HisPay_Note9					
18	HisPay_Note10					
19						
9.	门诊退费数量 DHC_OERefundQTY
序号	数据项	业务含义	可否为空	备注说明
1	OERQ_RowID			
2	OERQ_TotalQty 			医嘱总数量
3	OERQ_RefundQty			退费数量
4	OERQ_OEORI_DR			指向OE_Orditem
5	OERQ_Status			0:已申请退费，但没有去收费处实际退费，此时退费数量可以修改，一条医嘱最多只能有一条0状态的记录。
1:已实际退费,退费数量不能再修改，如果再有退费需新增加一条退费记录。
6	OERQ_PayFlag			医嘱收费状态。(暂时不用)
P：医嘱已收费。
非P:医嘱未收费。
7	OERQ_RefUser_DR			退费人，指向SS_User
8	OERQ_RefDate			退费日期
9	OERQ_RefTime			退费时间
10				
11				
12				
13				
				
				
				
				
				

配置表

1.帐单的费别表：PAC_ADMReason   医院级参数配置  对于特殊患者类型的控制
序号	数据项	业务含义	类型	长度	可否为空	备注说明
1	REA_RowId					
2	REA_Code					
3	REA_Desc					
4	REA_DateFrom					
5	REA_DateTo					
6	REA_NationalCode					
7	REA_AgeFrom					
8	REA_AgeTo					
9	REA_InPatAdm_DR					
10	REA_AdmSource	作为医保状态标志				=0    非医保
=1    医保类型
11	REA_QualifStatus	打印票据状态；	Text			0：默认打印发票=“”
1：表示不打印票据
12	REA_CareType	代表患者在支付需要特殊的控制手段				0：不需要任何标志；
1：需要PCS卡的支持；
2：
为以后的提供扩展；
13	REA_EpisSubType					
14	REA_AgeType					
15	REA_Age1From					
						
						
						

门诊收费结算数据统一配置：DHC_SOPFConfig(^DHCSOPFCON) 
在各地医院的统一配置，针对于医院的配置：
配置说明1： 按接收科室分票，且没张票上显示三个接收的医嘱：OPFCReclocFlag=1；OPFCRecInvCount=3(三个接收科室分一张票)
配置说明2： 按接收科室同时也按医嘱子类分配：OPFCItemFlag=1；OPFCReclocFlag=1；OPFCRecInvCount=3

序号	数据项	业务含义	类型	长度	可否为空	备注说明
1	OPFC_RowID					
2	OPFC_WebConDR		Text	30		医院RowID
3	OPFC_SiteCode					医院代码
4	OPFC_ItemFlag		Text	20	Null	ItemFlag=0不按照医嘱子类区分费用；
ItemFlag=1按照医嘱子类区分费用；
5	OPFC_ReclocFlag		Text	20	Null	ReclocFlag=0 不按照执行科室区分费用；
ReclocFlag=1 按照执行科室区分费用（按几个接收科室分一张表，取决于OPFC_RecInvCount）；

6	OPFC_PresNoFlag		Text			PresNoFlag =0 不按照处方区分费用；
PresNoFlag =1 按照处方区分费用；

7	OPFC_RecInvCount		Text			票据中的回执数量(如果opfc_Reclocflag=1,则该值设置为1，则按一个接受科室分一张票，如果为2则按两个接收科室分一张票，依次类推，如果设置为0则不按接收科室分票)
RecInvCount=0表示不打印回执（该值为0时，OPFC_ItemFlag、OPFC_ReclocFlag设置的值不起作用）
8	OPFC_PrintCount		Text			票据中打印明细数量；
PrintCount=0 表示不打印明细；

9	OPFC_HerbalFlag		Text			草药配制标志，起作用的前提：ItemFlag=1 同时RecInvCount<>0
HerbalFlag=0  按照正常的流程打印草药明细
HerbalFlag=1  按照配置表中的配置来计算
10	OPFC_HerbalDesc		Text			中草药费用名称
11	OPFC_HerbalNum		Text			中草药费用明细条数（此值打印明细时起作用）
12	OPFC_Version		Text			程序的版本信息
13	OPFC_YBFlag		Text			判断是不是连接医保Dll
=0 不连接
=1  连接
14	OPFC_AdmFlag		Text			在拆分发票时，是否区分不同的Adm，
=0   不按照Adm分票
=1   按照Adm分票
15	OPFC_AppFlag		Text			1   不需要审批
0   需要审批，默认的值  审批到发票
2	需要审批到医嘱  需要在审批时，判断
16	OPFC_PrtYBConFlag		Text			
17	OPFC_RoundDownNum		Text			1.四舍五入
2.五舍六入
18	OPFC_Node10		Text			
19	OPFC_Node11		Text			
20	OPFC_Node12		Text			
24	OPFC_OutSearchFlag  					门诊收费查询标志：
0:按日期，1:按时间
	OPFC_OutTimeRange  					门诊收费查询时间范围：
默认是当天
	OPFC_EmergencySearchFlag  					
	OPFC_EmergencyTimeRange					
	opfc_note5					是否使用押金管理（R）
	OPFC_OneToManyFlag		Text			集中打印发票与支付小条的对应关系（0:1：n;1:1:1）
	OPFC_RegInvFlag					集中打印发票时，挂号发票是否单独出票(0:不是，1:是)

3.详细数据配置表DHC_OPGroupSettings(^DHCOPGS(“GS”,GS_RowID))
序号	数据项	业务含义	类型	长度	可否为空	备注说明
1	GS_SSGroup_DR	安全组外键	DR		N	
2	GS_FootFlag	此安全组的结算标志	Yes/No		N	如果此安全组能办理结算，但是要设定此安全组能够接受的支付方式；
3	GS_RecLocFlag	是否按照接收科室进行接收	Yes/No		N	=Yes时，要求写门诊接收科室子表；=No时，DHC_OPGSRecLoc表都停止；不删除，把激活变为不激活
4	GS_PrtINVFlag	是否打印票据的设置	Yes/No		N	对于不同的安全组，来区分不同的票据或小票打印方式
	GS_					
5	GS_DateFrom	开始日期	Date			
6	GS_DateTo	结束日期	Date		N	
7	GS_AbortFlag	允许作废	Yes/No		N	
8	GS_RefundFlag	允许红冲	Yes/No		N	
9	GS_PrtXMLName	如果打印发票设置打印的XML文件名称,现金模板	Text			
10	GS_ColPrtXMLName	集中打印模板	Text			
11	GS_PRTParaFlag	票据参数安全组级设置	Multiple			如果有效，使用安全组配置，否则使用院级配置
Group PRT||G
Hosp  PRT||H
12	GS_ItemFlag		Text			
13	GS_RecDepFlag		Text			
14	GS_PresNoFlag		Text			
15	GS_RecInvCount		Text			
16	GS_PrintCount		Text			
17	GS_Note1		Text			
18	GS_Note2		Text			
19	GS_Note3		Text			
20	GS_OneToManyFlag		Text			集中打印发票与支付小条的对应关系（0:1：n;1:1:1）
21	GS_RegInvFlag					集中打印发票时，挂号发票是否单独出票(0:不是，1:是)
						

Index
按照安全组建立的索引：

^DHCOPGSi(“GS”,0,”GSDR”,{ GS_SSGroup_DR },{GS_RowID})



4.定义一个接收科室的子表：DHC_OPGSRecLoc
序号	数据项	业务含义	类型	长度	可否为空	备注说明
1	GS_RL_ParRef	ParRef	DR		N	
2	RL_RowID	RowID	Number		N	
3	RL_Sub		Number			
4	RL_LoadLoc_DR	登陆科室,指向CT_Loc	DR			此安全组所登陆的科室，避免项目实施中安全组配置过细；
5	RL_RecLoc_DR	指向CT_Loc	DR		N	
6	RL_DateFrom		Date			
7	RL_DateTo		Date			
8	RL_ActiveFlag	激活标志	Yes/No			
9	RL_Note1					
10	RL_Note2					
11	RL_Note3					
						
Master Data
^DHCOPGS(“GS”,{GS_RowID},”RL”,{RL_Sub})
^DHCOPGS("GS",{DHC_OPGroupSettings.GS_RowID},"RL",{RL_Sub})

1.Index – LoadRecDR
a)^DHCOPGSi("GS",0,"LRDR",{RL_LoadLoc_DR},{DHC_OPGroupSettings.GS_RowID},"RL",{RL_Sub})
2.
	

PM_Sub
$$next("^DHCOPGS(""GS"",+%data(0),""RL"",0)")


5.定义患者的支付方式表：DHC_OPGSPayMode

序号	数据项	业务含义	类型	长度	可否为空	备注说明
1	GS_PM_ParRef	指向父表				此表有效的前提：DHC_OPGroupSettings表中的字段：GS_FootFlag=Yes
2	PM_RowID		Number			
3	PM_Sub		Number			
4	PM_CTPM_DR	指向CT_PayMode表	DR			
5	PM_DateFrom	开始日期	Date			有效日期，开始日期
6	PM_DateTo	结束日期	Date			结束日期
7	PM_DefaultFlag	默认的支付方式	Yes/No			只有一个默认的支付形式
8	PM_INVPrtFlag	打印票据选项	Multi			需要票据判断
Print||P
No Print||NP
9	PM_RPFlag	需要填写支付的基本信息	Yes/No			=Yes;在门诊收费过程中弹出一个窗体用来写支付信息
10	PM_Note1		Text			预交金界面支付方式
11	PM_Note2		Text			
12	PM_Note3		Text			
13	PM_Note4		Text			
14	PM_Note5		Text			
						
Master Data
^DHCOPGS(“GS”,{GS_RowID},”PM”,{PM_Sub})
^DHCOPGS("GS",{DHC_OPGroupSettings.GS_RowID},"PM",{PM_Sub})

Index
3.Index – CTPMDR
a)^DHCOPGSi("GS",0,"CTPMDR",{PM_CTPM_DR},{DHC_OPGroupSettings.GS_RowID},"PM",{PM_Sub})


PM_Sub
$$next("^DHCOPGS (""GS"",+%data(0),""PM"",0)")

6.需要审批的收费类别设置DHC_OPApproved (^DHCOPApproved)
字段	类型	非空	指向	说明
OPA_ PatAdmAR_Dr	DR	Y	PAC_AdmReason	病人就诊的收费类别
OPA_ OrdAppAR_Dr	DR	Y	PAC_AdmReason	医嘱的收费类别(需要审批的收费类别)
OPA_ DisAppAR_Dr	DR	Y	PAC_AdmReason	不审批或者审批不通过的收费类别
OPA_OPAC_Dr	DR		DHC_OPAppCon	医嘱审批所需要的条件，为空时都需要审批
OPA_DateFrom	Date	Y		有效开始日期(设置日期0点开始有效)
OPA_DateTo	Date			有效结束日期(设置日期后一日0点开始无效)

7.需要审批的条件设置DHC_OPAppCon (^DHCOPAppCon)
字段	类型	非空	指向	说明
OPAC_Name	text	Y		需要审批条件的名称
OPAC_MinAmount	num			需要审批的金额最小值，为空时不判断金额
OPAC_DateFrom	Date			有效开始日期(设置日期0点开始有效)
OPAC_DateTo	Date			有效结束日期(设置日期后一日0点开始无效)

需要审批的收费项目子分类DHC_OPAppConCate(^DHCOPAppCon(parref,”C”))
字段	类型	非空	指向	说明		
OPACC_ TarSubCate_Dr	DR	Y	DHC_ TarSubCate	需要审批的收费项目子类		
OPACC_MinAmount	Num			需要审批的收费项目子分类金额最小值，为空时不判断金额		
OPACC_DateFrom	Date			有效开始日期(设置日期0点开始有效)		
OPACC_DateTo	Date			有效结束日期(设置日期后一日0点开始无效)		
						
合同单位回款表DHC_Reimburse 
序号	列名	类型	描述	节点	备注
1	 DHCRB_Date		回款日期		
2	 DHCRB_Time		回款时间		
3	 DHCRB_Amt		回款金额		
4	 DHCRB_User		收款人		
5	 DHCRB_HCP_DR		和同单位指针		
6	DHCRB_InAcountDate		回款入账日期		
7	DHCRB_TradeNO		回款交易流水号		
 DHC_ReimburseSub
序号	列名	类型	描述	节点	备注
1	 DHCRBS_FactAmt		实际回款额		
2	  DHCRBS_PartFalg		是否为部分回款		1:部分回款，非1:全部回款
3	  DHCRBS_Prt_DR		发票指针		
4					
5					
6					
					


科室、费别、就诊类型关联表
 DHCBill_LocConAdmRea
序号	列名	类型	描述	节点	备注
1	LCA_CtLoc_DR		科室指针		 CT_Loc
2	LCA_AdmReason_DR		费别指针		 PAC_AdmReason
3	LCA_Epissubtype_DR		就诊类型指针		 PAC_EpisodeSubType
4					
5					
6					
					

卡消费表
Global ：统一以DHCACD开头。
账户管理(预缴金统一管理)：DHC_AccManager
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	AccM_AccountNo	帐户号	Text	16	YYYYMMDD+0000		为了与RowID分开，把此帐户号等同于预缴金的流水号。
2	AccM_PAPMI_DR	登记号RowID	DR				指向Pa_PatMas表
3	AccM_PAPMINo	登记号	Text	12			
4	AccM_CardNo	卡号	Text	30			此卡号与CardManager中的CardNo一致
5	AccM_OCDate	开户日期	Date				
6	AccM_OCTime	开户时间	Time				
7	AccM_Cuser_DR	开户人员	DR				指向SS_User表
8							
9	AccM_Balance	帐户余额(预缴金余额)	Number			0	
10	AccM_WoffDate	销户日期	Date				
11	AccM_WoffTime	销户时间	Time				
12	AccM_Duser_DR	销户人员	DR				指向SS_User表
13	AccM_PassWord	帐户密码					特指：需要加密，要求有一个算法。
14	AccM_AccStatus	帐户状态	Mutlti				Normal||N激活(N)
Foot|| F结算(F)
Suspend|| S帐户挂起(S)
15	AccM_DepPrice	帐户限支/透支额度	Number				患者在就诊时，最低的消费下限（可以支持透支,或限制支付等功能）
16	AccM_BadPrice	患者结算时产生坏账，给财务报坏账准备	Number				
17	AccM_Type	个人/集体账户标志	Multi				Person||P个人
Collect||C集体
18	AccM_CredType_DR	证件类型指向	DR				指向DHC_CredType
19	AccM_CredNo	证件号码，此号码相对于帐户来讲是稳定的；而卡号可能是不稳定的	Text				用来
20	AccM_Note1						
21	AccM_Note2						
22	AccM_Note3						
23	AccM_Note4						
24	AccM_Note5						
							
							
	Global Name：^DHCACD (“AccM”,{AccM_RowID})
索引：
1、字段AccM_AccountNo    Index-- AccountNo 
 ^DHCACDi("AccM",0,"AccountNo",{AccM_AccountNo},{AccM_RowID})
2、字段 Index--OCDate
	^DHCACDi("AccM",0,"OCDate",{AccM_OCDate}, {AccM_RowID})
2、字段  AccM_ PAPMI_DR, AccM_AccStatus， AccM_CardNo    验证激活的帐户
Index--Satus
^DHCACDi("AccM",0,”AccStatus”,{AccM_AccStatus},{AccM_PAPMI_DR}, {AccM_CardNo},{AccM_RowID})

3、预缴金结算人员的查询
AccM_WoffDate     Index-- WOffDate
^DHCACDi("AccM",0,"WOffDate",{AccM_WOffDate},{AccM_RowID})
5、预缴金结算人员   Index--DUser
^DHCACDi("AccM",0,"DUserDR",{AccM_DUser_DR},{AccM_WOffDate}, {AccM_RowID})

6. Index-AccStatus   
^DHCACDi("AccM",0,"AccStatusOnly",{AccM_AccStatus},{AccM_RowID})

预缴金流水账：DHC_AccPreDeposit
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	AccPD_ParRef		DR				父表DHC_AccManager
2	AccPD_RowID		Row ID				
3	AccPD_Sub						
5	AccPD_AccountNo	帐户号(预缴金编号)					(考虑不加在表中)
4	AccPD_Type	缴款类型	Multi	3			Pay||P缴款
Refund||R退费
Trans||T转帐
Foot||F结算帐户的缴退款
7	AccPD_Mode	缴款方式(用子表表示)	Number	3			1现金
2支票
3银行卡
4 
5	AccPD_PreSum	缴款额度	Number				
6	AccPD_PreDate	缴款日期	Date				
7	AccPD_PreTime	缴款时间	Time				
8	AccPD_User_DR	收款人员	DR				
9	AccPD_BillNum	票据号	Text				
10	AccPD_PDFoot_DR	结算时间外键	DR				DHC_AccPFoot
11	AccPD_Left	帐户余额	Number				
12	AccPD_BackReason	退款原因；	Text	100			
13	AccPD_Note1						
14	AccPD_Note2						
15	AccPD_Note3						
16	AccPD_Note4						
17	AccPD_Note5						
							
	Global Name：  Data Master
^DHCACD("AccM",{DHC_AccManager.AccM_RowID},”AccPD”{AccPD_Sub})
索引：
1、Index—User      按照收款员
	^DHCACDi("AccM",0,"User",{AccPD_User_DR},{AccPD_PreDate},{DHC_AccManager.AccM_RowID},"AccPD",{AccPD_Sub})
2、Index—PDFootDR    --按照结算建立索引
	^DHCACDi ("AccM",0,"PDFootDR",{AccPD_PDFoot_DR}, 
 {DHC_AccManager.AccM_RowID},"AccPD",{AccPD_Sub})

AccPD_Sub：  $$next("^DHCACD(""AccM"",+%data(0),""AccPD"",0)")

帐户预交金的支付方式表：
DHC_AccPrePayMode   支持：现金/支票/汇票/银行卡  等方式
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	APPM_AccPD_ParRef	指向预交金表DHC_AccPreDeposit	DR				
2	APPM_RowID		RowID				
3	APPM_Sub		Number				
4	APPM_PayMode_DR	支付方式					指向CT_PayMode
5	APPM_Card_DR	银行卡类型；例如工商卡，龙卡等	DR				指向ARC_BankCardType
工商卡，建行卡，银联等；
6	APPM_CardChequeNo	银行卡，支票等号码(此号码与账户有区别)	Text				
7	APPM_CMBank_DR	支票发行银行/银行卡发行银行	DR				指向CMC_BankMas
8	APPM_Branch	支付单位	Text	150			患者所在单位等
9	APPM_Amt	支付额					
10	APPM_PayAccNO	对方的帐户号(支付的帐号)					
11	APPM_ChequeDate	支票日期	Text				
12	APPM_Date	预交金支付日期	Date				
13	APPM_Time	预交金支付时间	Time				
14	APPM_Remark	备注					
15	APPM_Note1		Text				
16	APPM_Note2		Text				
17	APPM_Note3		Text				
18	APPM_Note4						
19	APPM_Note5						
							
							
							

Data  Master
	^DHCACD("AccM",{DHC_AccManager.AccM_RowID},”AccPD”{AccPD_Sub},”P”{ APPM_Sub })

Index
1.预交金支付日期
^DHCACDi("AccM",{DHC_AccManager.AccM_RowID},”AccPD”{AccPD_Sub},”P”{ APPM_Sub })

APPM_Sub
  $$next("^DHCPB(+%data(0),""O"",$p($p(%data(0),$c(1)),""||"",2),""D"" ,0)")

卡支付流水帐：DHC_AccPayList
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	AccPL_ParRef	对应父表	DR		Not Null		DHC_AccManager
2	AccPL_RowID	Row ID	Row ID				RowID
3	AccPL_Sub		Number				
4	AccPL_PAPMI_DR	指向PA_PatMas表					指向此支付额为哪个患者支付的；
对于患者没有账户仍然可以支付
5	AccPL_InvPrt_DR	门诊结算票据管理的RowID	DR				对应表DHC_Invprt
6	AccPL_PAPMINo	患者的登记号	Text				在PA_PatMas中
7	AccPL_BillNo	小票号码(此号码可打可不打，决定权在项目)，可以加上审批权来代替这个	Text				与打印出来的票据号一致，格式：
登记号码_
8	AccPL_User_DR	服务/会计人员RowID，操作此支付的人员（操作的人）	DR				指向SS_User
9	AccPL_PayDate	卡支付日期	Date				对应账单支付的日期
10	AccPL_PayTime	卡支付时间	Time				对应账单支付的时间
11	AccPL_PayNum	支付金额	Number			0	
12	AccPL_Left	账户余额	Number				
13	AccPL_PayRecLoc_DR	患者支付时，所在的科室	DR				CT_Loc
14	AccPL_Note1		Number				
15	AccPL_Note2		DR				
16	AccPL_Note3						
17	AccPL_Note4						
							
							
							
	Global Name：
	Data Master
^DHCACD("AccM",{DHC_AccManager.AccM_RowID},”AccPL”{AccPL_Sub})
索引：
1、PayDate建立索引  Index-- PayDate
^DHCACDi("AccM",0,"PayDate",{AccPL_PayDate},{DHC_AccManager.AccM_RowID},"AccPL",{AccPL_Sub})
2、针对票据RowID建立的索引   Index—InvPrtDR
^DHCACDi("AccM",0,"InvPrtDR",{AccPL_InvPrt_DR},{DHC_AccManager.AccM_RowID},"AccPL",{AccPL_Sub})
3、索引

AccPL_Sub
$$next("^DHCACD(""AccM"",+%data(0),""AccPL"",0)")

对帐系统
卡支付与预缴金 结算 流水帐对帐：DHC_AccPFoot（针对于会计的总账）
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	AccPF_RowID		RowID				
2	AccPF_Date	本次报表对帐日期	Date				
3	AccPF_Time	本次报表对帐时间	Time				
4	AccPF_User_DR	报表操作人	DR				SS_User
5	AccPF_LastDate	上次报表对帐日期	Date				
6	AccPF_LastTime	上次报表对帐时间	Time				
7	AccPF_PreLeftSum	前期余额汇总	Number				
8	AccPF_PreSum	收预缴金流水汇总	Number				是财务已结算，此值与出纳本次收预缴款一致。
9	AccPF_CardPaySum	卡支付流水汇总(是计算的出)	Number				是财务已结算，此值与出纳手中卡消费汇总一致
10	AccPF_LeftSum	本期余额	Number				此数与出纳手中的预缴金余款一致，总预缴款余额
11	AccPF_RefundPreSum	退预缴金流水汇总	Number				是财务已结算，此值与出纳本次退/结算预缴款一致。
12	AccPF_Note1						
13	AccPF_Note2						
14	AccPF_Note3						
15	AccPF_Note4						
16	AccPF_Note5						
17	AccPF_Note6						
18	AccPF_Note7						
19	AccPF_Note8						
20	AccPF_Note9						
							

	Global Name：   Data Master
	^DHCACD("AccPF",{AccPF_RowID})
^DHCACD("AccPF")
索引：
1、Index--CurDate
^DHCACDi("AccPF",0,"CurDateT",{AccPF_Date}, {AccPF_RowID})
2、

卡支付流水帐结算子表：DHC_AccPFootSub  （应该是一个平衡的结算账） 对于单个患者的明细帐
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	AccPFS_ParRef		DR				指向父表DHC_AccPFoot
2	AccPFS_RowID	RowID	RowID				
3	AccPFS_Sub		Number				
4	AccPFS_AccM_DR	账户的RowID	DR				指向DHC_AccManager
5	AccPFS_PreLeft	前期余额					
6	AccPFS_PrePay	收预缴金之和					
7	AccPFS_CardPay	卡支付之和					
8	AccPFS_CurLeft	本期余额					这几个数值都是计算出来的算法可能比较麻烦
9	AccPFS_RefundPrePay						退预缴金之和
							
							
							
							
							
（注：病人已经办理结算，同时财务已经结算完毕的“账户” 预缴金帐不再出现此报表中）
	（流水明细只是列举当前发生交易的账户，不发生交易的账户，只是在总账中体现出来。）
用来定义子表的Sub：$$next("^DHCACD(""AccPF"",+%data(0),""PF"",0)")

	Global Name：   Data Master
	^DHCACD("AccPF",{DHC_AccPFoot.AccPF_RowID},"PF", {AccPFS_Sub})
Index：(在索引中用0把节点分开，千万不能用1)
1．Index—AccM_DR
^DHCACDi("AccPF",0,"AccMDR",{AccPFS_AccM_DR},  {DHC_AccPFoot.AccPF_RowID},"PF",{AccPFS_Sub})
2．dsfds

预缴金结算日报：DHC_AccPDFootLog      (保存存为时间)
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
	AccPDF_RowID						
1	AccPDF_Date	结算日期	Date				
2	AccPDF_Time	结算时间	Time				
3	AccPDF_User_DR	结算员用户RowID	DR				SS_User
4	AccPDF_LastDate	上次结算日期	Date				
5	AccPDF_LastTime	上次结算时间	Time				
6	AccPDF_OperUser_DR	收款员用户RowID	DR				SS_User
7	AccPDF_INSFootUser	财务接收人员	DR				SS_User
8	AccPDF_INSFootDate	财务接收日期	Date				
9	AccPDF_INSFootTime	财务接收时间	Time				
10	AccPDF_Note1						
11	AccPDF_Note2						
12	AccPDF_Note3						
13	AccPDF_Note4						
14	AccPDF_footnum						
15	AccPDF_refundnum						
16	AccPDF_footsum						
17	AccPDF_pdsum						
18	AccPDF_refundsum						
19	AccPDF_cashsum						
20	AccPDF_chequesum						
21	AccPDF_othersum						
22	AccPDF_rcptstr						
23	AccPDF_Other1						
24	AccPDF_Other2						
25	AccPDF_Other3						
26	AccPDF_Other4						
27	AccPDF_Other5						
28	AccPDF_Other6						
29	AccPDF_Other7						
30	AccPDF_Other8						
31	AccPDF_Other9						
32	AccPDF_Other10						
							
							
	两个User_DR的目的是可以使结算与收款分开。
Global Name：
^DHCACD("AccPDFL",{AccPDFRowID})
索引：
1、查询收款员的结算信息。Index--User
^DHCACDi("AccPDFL",0,"OperUser",{AccPDF_OperUser_DR},{AccPDF_Date},{AccPDFRowID})
2、Index--PFDate
	^DHCACDi("AccPDFL",0,"FootDT",{AccPDF_Date}, {AccPDFRowID})

账户更改日志：DHC_AccStatusChange
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
0	AccSC_ParRef	子表	DR				父表DHC_AccManager
1	AccSC_RowID		RowID				
2	AccSC_Sub						
3	AccSC_Ovalue	修改原值	Text				
4	AccSC_Nvalue	修改值(现在的值)	Text				
5	AccSC_Left	账户余额	Number				
6	AccSC_OperDate	操作日期	Date				
7	AccSC_OperTime	操作时间	Time				
8	AccSC_User_DR	操作人员	DR				
9	AccSC_Note	操作说明日志（备注）					说明文档.
10	AccSC_Note1						
11	AccSC_Note2						
12	AccSC_Note3						
13	AccSC_Note4						
							

Data Master
^DHCACD("AccM",{DHC_AccManager.AccM_RowID},"SC",{AccSC_Sub})
索引：	
1．Index-Item
AccSC_Sub: 
$$next("^DHCACD(""AccM"",+%data(0),"" SC "",0)")

票据管理借鉴住院押金：（表结构？）
DHC_AccBillManager   本来想弄成和住院一样的，现在暂时不用
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	AccBM_RowID	RowID	RowID				RowID
2	AccBM_BeginNum		Text	18			开始编号
3	AccBM_EndNum		Text	18			结束编号
4	AccBM_CurNum		Text	18			当前可用编号
5	AccBM_Date		Date				领取日期
6	AccBM_Time		Time				领取时间
7	AccBM_UseFlag		Number				可用标志
0 标志为可用
1 标志为不可用
8	AccBM_Priority	为了方便操作员能够方便设置票据使用的先后顺序.	Number				优先级
设定1,2,3,4
9	AccBM_User_DR	指向SS_User表	DR				
Global  Name:
^DHCACD("AccBM",{AccBM_RowID})

卡表设计：卡的管理表	设计原则：卡管理与帐户管理尽量能够独立，同时卡管理能够外接其他的卡；
患者丢失卡后，通过证件办理卡挂失（挂失的卡不能再用），帐户挂起；
患者办理新卡后（同时办理帐户的），
卡的Gloab统一以  ^DHCCARD开头
卡类型定义：DHC_CardTypeDef
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	CTD_RowID						
2	CTD_Code	卡类型代码	Text		No		
3	CTD_Desc	卡类型描述	Text	20			
4	CTD_Note1		Text	50			
5	CTD_Note2						
6	CTD_Note3						
							
Global
^DHCCARDTYPEDef
卡表
DHC_CardRef
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	CF_RowID						
2	CF_AccNo_DR	帐户代码外键	DR		No		说明此卡所挂的帐户(DHC_AccManager)
	CF_CardNo	卡号	Text				
3	CF_SecurityNO	卡的安全号码	Text				
4	CF_PAPMI_DR	指向PA_PatMas表	DR				
5	CF_IDCardNo	身份证号码	Text	30			
6	CF_PAPMINo	登记号	Text	30			
7	CF_Date	发卡日期	Date				
8	CF_Time	发卡时间	Time				
9	CF_User_DR	发卡人	DR				
10	CF_ActiveFlag	有效卡标志	Multi				Normal||N  正常
Suspend||S  挂失
Reclaim||R  回收
Depose||D  作废(此时，不能再次使用)
11	CF_DateFrom	Date					
12	CF_DateTo	Date					
13	CF_CancleDate						
14	CF_CancleTime						
15	CF_CancleUser_DR	SS_User	DR				
16	CF_Note1						
17	CF_Note2						
18	CF_Note3						
							
							

Global:
^DHCCARD(“CF”,{CF_RowID})
索引:
	1．Index AccNodr
^DHCCARDi ("CF",0,"AccNoDR",{CF_AccNo_DR},{CF_RowID})
	2.Index Date
 ^DHCCARDi("CF",0,"Date",{CF_Date},{CF_RowID})
3.Index PAPMIDR
		^DHCCARDi ("CF",0,"PAPMIDR",{CF_PAPMI_DR},{CF_RowID})

^DHCCARD

卡管理表每变化一次，此状态表就写一条记录；记录当时操作的情况；
卡的状态变化表：
DHC_CardStatusChange
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	CSC_CF_ParRef						
2	CSC_RowID						
3	CSC_Sub						
4	CSC_Date	状态变化日期					
5	CSC_Time	状态变化时间					
6	CSC_CurStatus	当前的状态	Multi				同上的状态
N||Normal  正常
S||Suspend  挂失
R||Reclaim  回收
D||Depose  作废(此时，不能再次使用)
7	CSC_User_DR	操作员	DR				
8	CSC_ComputerIP	计算机的IP	Text				
9	CSC_Note1						
10	CSC_Note2						
11	CSC_Note3						
							
							
							

Global：
^DHCCARD(“CF“,{ DHC_CardManager.CF_RowID},“CSC”,{CSC_Sub})

CSC_Sub
	$$next("^DHCCARD (""CF"",+%data(0),""CSC"",0)")

索引：
^DHCCARD

证件类型：DHC_CredType
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	CRT_RowID						
2	CRT_Code	证件代码	Text		No		身份证
学生证
军官证
驾照
3	CRT_Desc	证件类型描述	Text				
							
							

Global：
	^DHCACCCredType

综合打印发票（小票换发票）  此表作用只是为了核销票据
DHC_AccPayINV		患者个人账户支付统一打印票据表--此表参照DHC_INVPRT表
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	API_RowID						
2	API_Amount	票据上打印的自付金额	Number				
3	API_Flag	票据状态	Multi				Normal||N 正常
Abort||A  作废
Strike||S 冲红
4	API_Date	打印票据日期	Date				这个与小票日期不一致
5	API_Time	打印票据时间	Time				
6	API_PUser_DR	打印票据用户					
7	API_InvNo	票据号码					
8	API_CheckDate	核销日期	Date				
9	API_CheckTime	核销时间	Time				
10	API_CheckUser_DR	核销人员	DR				
11	API_PayINV_DR	指向原票据DHC_AccPayINV	DR				
12	API_PAPMI_DR	指向PA_PatMas	DR				
13	API_AccMan_DR	指向DHC_AccManager	DR				指向帐户(如果患者办理结算一定打印发票)
14	API_ PatientShare		Number				
15	API_ DiscAmount		Number				
16	API_ PayorShare		Number				
17	API_SelfPatPay	个人自付部分的分解，	Number				自付中医保的支付
18	API_SelfYBPay		Number				自付中的自付
19	API_RefundSum	退款总额	Number				
20	API_InsDiv_DR	指向INSU_Divide表	DR				此字段<>””表示此发票经过医保结算
=””表示此发票没有经过医保结算
21	API_ INVRep_DR	DHC_INVPRTReports	DR				
22	API_CashPay	更改一下，退费时记录一下现金退费金额	Number				
23	API_Note3						
24	API_Note4						
25	API_Note5						
26	API_Note6						
27	API_Note7						
28	API_Note8						
29	API_Note9						
30	API_Note10						
	API_INVRep_DR	关联结帐历史记录表					指向DHC_INVPRTReports，收费员日结帐后建立的关联
	API_OPCRoundSum	分币误差					

Global：
^DHCINVPRTAP({API_RowID})

索引：  	
	^DHCINVPRTAPi
1.打印票据日期
a)Index  Date
b)^DHCINVPRTAPi(0,"Date",{API_Date},{API_RowID})
2.核销日期
a)Index  CheckDate
b)^DHCINVPRTAPi(0,"CheckDate",{API_CheckDate},{API_RowID})
3.Index  -- INVNo    发票号码
a)^DHCINVPRTAPi(0,"INVNo",{API_INVNo},{API_RowID})
4.Index INVRep			日报外键
a)^DHCINVPRTAPi(0,"INVRep",{API_INVRep_DR},{API_RowID})
5.

集中打印发票支付方式表
DHC_AccPayINVMode
门诊卡支付集中打印发票记录此张发票的支付方式
序号	数据项	业务含义	类型	长度	可否为空	备注说明
1	APM_API_ParRef	指向父表DHC_INVPRT	Par			
2	APM_Sub		Number			
3	APM_PayMode_DR	支付方式	DR			指向CT_PayMode
4	APM_CMBank_DR	银行卡或支票的银行信息	DR			指向CMC_BankMas
5	APM_Amt	金额	Number			
6	APM_CardChequeNo	卡支票号码	Text	50		
7	APM_Card_DR	银行卡类型，包括自己发的卡	DR			指向ARC_BankCardType
工商卡，建行卡，银联等；
医院发行的卡
8	APM_Date	支付日期	Date			这个日期时间与父表的日期时间一致；主要是为了财务现金支付额提供财务报表；
9	APM_Time	支付时间	Time			
10	APM_Unit	支付单位	Text	150		患者所在工作单位等
11	APM_PayAccNO	支票对方账户号码	Text			
12	APM_Note1					
13	APM_Note2					
14	APM_Note3					
15	APM_Note4					
16	APM_Note5					
						
						

Global：
^DHCINVPRTAP({API_RowID},”P”,{APM_Sub})

Sub：
$$next("^DHCINVPRT($p(%data(0),$c(1)),""P"",0)")
集中打印发票表与支付表的关联表
DHC_AccPINVCONPRT        连接表
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	ACP_RowID						
2	ACP_INVPRT_DR	帐单集合外键	DR		No		指向DHC_INVPRT
	ACP_APINV_DR	集合发票的外键	DR				指向DHC_AccPayINV
3	ACP_Note1		Text				
4	ACP_Note2		DR				
5	ACP_Note3		Text	30			
Global：
^DHCINVPRTCAP({API_RowID})

索引：  	
^DHCINVPRTCAPi
1. Index -- APINVDR 
^DHCINVPRTCAPi(0,"APINVDR",{ACP_APINV_DR},{ACP_RowID})
2.Index –INVPRTDR 
^DHCINVPRTCAPi(0,"INVPRTDR",{ACP_INVPRT_DR},{ACP_RowID})

集体账户与患者信息关联表 /个人帐户
DHC_AccMConGroup
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	AMCG_RowID						
2	AMCG_User_Dr	办理关联人员					
3	AMCG_Date	办理日期					
4	AMCG_Time	办理时间					
5	AMCG_AccManFrom_DR	帐户管理中能给别人支付的帐户(集团帐户)，隐含这个帐户给别人支付	DR				指向DHC_AccManager
6	AMCG_PAPMI_DR	指向Pa_PatMas,	DR				
7	AMCG_AccManTo_DR	作为个人帐户(隐含给这个帐户支付)	DR				指向DHC_AccManager
8	AMCG_DateFrom	有效开始日期					
9	AMCG_DateTo	有效结束日期					
10	AMCG_LimitAmt	有效期间支付限额					
11	AMCG_PayAmt	有效期间支付总额;表示集团帐户给此人的支付额度					
12	AMCG_ActiveFlag	关联有效标志	Multi				Normal||N   正常
Abort||A    取消
13	AMCG_AbortDate	取消日期					
14	AMCG_AbortTime	取消时间					
15	AMCG_AbortUser_DR	取消人员					
16	AMCG_Note1						
17	AMCG_Note2						
18	AMCG_Note3						
19	AMCG_Note4						
20	AMCG_Note5						
							

Global：
	^DHCACDMCG({AMCG_RowID })

索引：
	^DHCACDMCGi
1.办理日期
a)Index Date
b)^DHCACDMCGi(0,"Date",{AMCG_Date},{AMCG_RowID})
2.取消日期
a)Index AbortDate
b)^DHCACDMCGi(0,"AbortDate",{AMCG_AbortDate},{AMCG_RowID})
3.Pa_PatMas
a)Index PAPMIDR
b)^DHCACDMCGi(0,"PAPMIDR",{AMCG_PAPMI_DR},{AMCG_RowID})
4.办理关联人员和办理日期
a)Index UserDate
b)^DHCACDMCGi(0,"UserDate",{AMCG_User_DR},{AMCG_Date}, {AMCG_RowID})
5.取消人员和取消日期
a)Index  AbortUserDate
b)^DHCACDMCGi(0,"AUDate",{AMCG_AbortUser_DR},{AMCG_AbortDate}, {AMCG_RowID})
6.Other

此表不在使用，只是暂时保留；
集体账户表：
DHC_AccGroupBill
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	AGB_RowID						
2	AGB_						
3	AGB_						
4	AGB_						
5	AGB_						
6	AGB_						
7							
8							
9							
10							
11							
12							
							

此表不在使用，只是暂时保留；
集体账户的预交金流水账：
DHC_AccGBPreDeposite
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	AGBPD_AGB_ParRef	指向夫表DHC_AccGroupBill					
2	AGBPD_RowID						
3	AGBPD_Sub						
4	AGBPD_						
5	AGBPD_						
6	AGBPD_						
7	AGBPD_						
	AGBPD_						
							



集体账户预交金支付方式：
DHC_AccGBPrePayMode
序号	数据项	数据项名称（业务含义）	类型	长度	可否为空	缺省值	备注说明
1	AGBPM_ AGBPD _ParRef						
2	AGBPD_						
3	AGBPD_						
4	AGBPD_						
5	AGBPD_						
							


5命名规则：
组件命名规则：
		DHCAC
		报表命名规则：
			DHCACR
JS文件命名规则：
		DHCAC
			报表命名规则：
				DHCACR
Web类命名规则：
		DHCAC
			报表命名规则：
				DHCACR
以上的规则都是名称的题头
5．遗留问题及解决措施
门诊预缴金的票据管理欠缺。（可以利用以有的住院押金票据管理模式）
不支持银行卡转帐。

设计后续，组件界面设计
1．患者账户结算组件，包含的信息
a)患者的基本信息，账户的基本信息；
b)此账户支付流水账
c)此账户预交金流水
d)账户状态变化日志；
e)结算按钮动作：
i.对账户进行结算
ii.对没有打印票据的账单集合，强制打印发票；
iii.
f)other
2．票据打印组件名称汇总，都是票据要求算法一致（）
a)
3．门诊收费支付方式的改造：（兼有支付方式下的票据）
a)用户选择某种支付方式;
b)支付方式中包含此支付方式必须需要的约束,例如
c)
4．Other
--select * from DHC_AccManager order by AccM_RowID desc
--select * from DHC_AccPreDeposit order by AccPD_ParRef desc
--select * from DHC_AccPayList order by AccPL_ParRef desc
--select * from DHC_AccStatusChange 
--select * from DHC_CardRef order by CF_RowID desc
--select * from DHC_CardStatusChange order by CSC_CF_ParRef desc

银医卡
医生站表
病人基本信息表PA_PatMas 
实体类: User. PAPatMas，User.PAPerson
业务类: web. PAPatMas,web.PAPerson
存储globe: ^PAPER


PA_PatMas基本信息表
序号	列名	结点	描述	备注
1	PAPMI_Name	"ALL"	姓名, First name	王强
6	PAPMI_DOB	"ALL"	出生日期	53760(1988-3-10)
2	PAPMI_Name2	"ALL"	Middle name或名字拼音的大写首字母	WQ
	PAPMI_Name4		Last name	
19	PAPMI_Name3	"ALL"	医保手册号、医保号	 InsuranceNo
22	PAPMI_Medicare	"PAT",1	病历号、病案号	DocumentID
	PAPMIMedicareExpDate	"PAT",1		
7	PAPMI_CardType_Dr	"PAT",3	证件类型指针，指向PAC_CardType表	表里面有证件的类型描述，及代码。
6	PAPMI_MedicareCode	"PAT",2	传真	
4	PAPMI_GovernCardNo	"PER",4	门诊病历号	现在基本就一个病历号，默认为PAPMI_Medicare
	PAPMI_DVAnumbe		身份证号	
	PAPMI_Alias		病人别名	
1	PAPMI_IPNo	"PAT",1	登记号	RegisterNo、 RegNo
2	PAPMI_OPNo	"PAT",1	登记（门诊）号	
	PAPMI_EstAgeYear			
	PAPMI_EstAgeMonth			
	PAPMI_EstAgeTmStmp			
	PAPMI_Soundex			
	PAPMI_LangPrimDR		母语	
	PAPMI_LangSecondDR		第二母语	
	PAPMI_PrefLanguageDR		首选语言	
	PAPMI_Active		激活	
	PAPMI_VIPFlag		VIP标志	
	PAPMI_PatCategoryDR		病人分类	
	PAPMI_HomeClinicNo			
	PAPMI_Remark		备注	
	PAPMI_Deceased		死亡标志	
	PAPMI_DeceasedDate		死亡日期	
	PAPMI_DeceasedTime		死亡时间	
	PAPMI_BlackList		黑名单标志	
	PAPMI_EstimatedDeathDate			
	PAPMI_MotherDR		母亲记录指针	
	PAPMI_Mother1DR			
	PAPMI_RefDocDR		家庭医生	
	PAPMI_DentistDR		牙医	
	PAPMI_DentistClinicDR		牙医诊所	
	PAPMI_TraceStatusDR			
	PAPMI_MedicareSuffixDR			
	PAPMI_Allergy		过敏记录	
	PAPMI_EPRDescription		电子病历	
	PAPMI_ConcessionCardNo			
	PAPMI_ConcessionCardExpDate			
	PAPMI_SafetyNetCardNo			
	PAPMI_SafetyNetCardExpDate			
	PAPMI_GovernCardNo			
	PAPMI_DVAnumber			
	PAPMI_InsuranceCardHolder			
	PAPMI_CardTypeDR			
	PAPMI_CHCPatient			
	PAPMI_CTHCADR		CTHealthCareArea	
	PAPMI_HealthFundNo			
	PAPMI_HealthCardExpiryDate		健康卡号失效日期	
	PAPMI_CountryOfBirthDR		出生国	
	PAPMI_CityBirthDR		出生城市	
	PAPMI_TitleDR		头衔	
	PAPMI_CTRegionDR		所在地区	
	PAPMI_CTProvinceDR		所在省	
	PAPMI_CityAreaDR		所在区	
	PAPMI_Email		电子邮件	
	PAPMI_MobPhone		手机	
	PAPMI_SecondPhone		第二联系电话	
	PAPMI_AuxInsTypeDR			
	PAPMI_PensionTypeDR			
	PAPMI_IndigStatDR			
	PAPMI_RequireAssistanceMeal		需要辅食	
	PAPMI_RequireAssistanceMenu		需要辅食菜单	
PA_Person登记信息总表
序号	列名	结点	描述	备注
	PAPER_PAPMI_DR		指向基本信息表，是计算值。	PA_PatMast
9	PAPER_ID	"ALL"	身份证号	
3	PAPER_Marital_DR	"PER",2	婚姻状况	CT_marital
7	PAPER_Sex_DR	"ALL"	指向性别表	CT_Sex
	PAPER_Age		年龄，计算值	
10	PAPER_SocialStatus_DR	"PER",1	病人类型，指公费自费等	CT_socialstatus
6	PAPER_Occupation_DR	"PER",2	职业表RowId	CT_Occupation
5	PAPER_Education_DR	"PER",2	学历	
19	PAPER_Email	"PER",4	Email	
8	PAPER_Country_DR	"PER",1	国籍	CT_Country
2	PAPER_ReligionDR	"PER",2	宗教	
1	PAPER_Nation_DR	"PER",2	民族	CT_Nation
	PAPER_StayingPermanently		是否永久居住	
18	PAPER_SecondPhone	"PER",4	工作单位地址	注意，不是第二联系电话
7	PAPER_ZipDR	"PER",1	邮编	CT_zip
	PAPER_StName	"PER","ADD"1	街道住址、地址、户口地址	
	PAPER_House_Building_No		门牌号	
21	PAPER_MobPhone	"PER",4	手机	
11	PAPER_TelH	"PER",1	联系电话	
9	PAPER_TelO	"PER",1	办公电话	
4	PAPER_CTRLTDR	 "EMP"	联系人关系	CT_Relation
	PAPER_Name4		老年证	沈阳用
	PAPER_Name6		工作单位邮编	
13	PAPER_ForeignId	"PER",2	联系人姓名	
	PAPER_ForeignCountry		护照国籍	
	PAPER_PassportNumber		护照号	
1	PAPER_ForeignAddress	"PER",1	国际地址/联系人地址	
	PAPER_ForeignPhone		联系人电话	
	PAPER_ForeignPostCode		国际邮编	肿瘤作为
病人的联系邮编
	PAPER_Complement		备注	
				
	PAPER_NokText		监护人信息	
	PAPER_NokName		监护人姓名	肿瘤作为
工作单位联系人
	PAPER_NokPhone		监护人联系电话	肿瘤作为
工作单位联系人电话
	PAPER_NokAddress1			肿瘤作为
工作单位地址
	PAPER_NokCTRLTDR		与监护人关系	CTRelation
				
	PAPER_ExemptionNumber		住院累计次数	
	PAPMI_GPOrgAddress		首诊科室	
	PAPMI_GPText		首诊日期	
11	PAPER_ProvinceBirthDR	"PER",2	出生省	CT_province
18	PAPER_CityBirthDR	"ALL"	出生城市	CT_City
	PAPER_CityCodeDR			
	PAPER_StateCodeDR			
	PAPER_CTRegionDR			
	PAPER_CTProvinceDR			
	PAPER_CityAreaDR			
	PAPER_LangPrimDR			
	PAPER_CTHCADR			
	PAPER_HCPDR		CTHealthCareProvider	
13	PAPER_DeceasedDate	"ALL"	病人死亡日期	
8	PAPER_DeceasedTime	"ALL"	病人死亡时间	
	PAPER_GovernCardNo			
				
	PAPER_MotherDR		母亲	
	PAPER_FatherDR		父亲	
	PAPER_FamilyGroupDR		家族	
	PAPER_FamilyDoctorDR		家庭医生	
				
	PAPER_FromThisArea			
	PAPER_ReasonForChangeData			
	PAPER_ForeignNotes			
	PAPER_ExemptionNumber			
	PAPER_ Complement		补助	
	PAPER_ResponsibleForPayment			
	PAPER_DiscretOutsTypeDR			
				
	PAPER_EmplTypeDR		在职离休	指向PAC_EmployeeType
	PAPER_JobTitle			
	PAPER_EmplRelatedTo			
	PAPER_EmployeeNo			
	PAPER_EmplDepDR			
	PAPER_DiscDateFrom			
	PAPER_DiscDateTo			
	PAPER_DiscTypeDR			
	PAPER_OutstandAmt			
	PAPER_OutstandingDate			
	PAPER_EmployeeFunction		行政级别	CTEmpFunc，
中山三院

	PAPER_EmployeeCompany		雇员所在公司	合同单位
	PAPER_EmployeeCoContract		雇员合约	
	PAPER_Guardian1DR			
	PAPER_Guardian2DR			
	PAPER_ExpectedPayDate			
	PAPER_BillCode			
Nok:next of kin. 最近的血親;最親的親戚 ...

病人信息表扩展    注:此表和护理组的DHC_PA_PatMas存储位置冲突,只有前两位是同步的.
$P（^PAPER({PAPER_RowId} ,”DHC”)）
1	PAPMI_BirthTime	%Time	出生时间	
2	PAPMI_BirthPlace		出生地	
3	PAPMI_CredTypeDR		其他证件类型	
4	PAPMI_CredNo		证件号	
5	PAPMI_BillTypeCodeStr		可参加费别	深圳用
6	PAPMI_InsurAdmCategory		医保证件类型	PAC_AdmCategory
复兴用
7	PAPMI_SecondMobPhone		第二联系电话	
8	PAPMI_SecondRLT_DR		第二联系电话持有人关系	CTRelation
9	PAPMI_LocalContactName		本地联系人姓名	
10	PAPMI_LocalContactRelation		与本地联系人关系	
11	PAPMI_LocalContactPhone		本地联系人电话	
12	PAPMI_Tourist		是否旅客	1：是 0：否
13	PAPMI_TouristHotelName		酒店名称	
14	PAPMI_ArrivalDate	%Date	到达日期	
15	PAPMI_EstDeparttureDate	%Date	预计离开日期	
16	PAPMI_Employee			
17	PAPMI_ ChooseIdentity		身份选择	存入代码
18	PAPMI_ ForeignMobile		国际联系手机	
19	PAPMI_ LocalAddress		本地地址(在华地址)	
20	PAPMI_ LocalPhone		本地电话(在华电话址)	
21	PAPMI_ LocalMobile		本地手机(在华手机)	
22	PAPMI_SecondEmail		第二电子邮件	
23	PAPMI_Employer		雇主	
24	PAPMI_EmployerAddress		雇主地址	
25	PAPMI_EmployerEmail		雇主Email	
26	PAPMI_EmployerPhone		雇主电话	
27	PAPMI_ Membership		会员选择	存入代码
28			空闲	
29			空闲	
30	PAPMI_ RegLoc		病人登记科室	用以记录是在那个科室新建病人信息
PACS组用

病人医保信息表扩展
$P（^PAPER({PAPER_RowId} ,”DHCINS”)）
1	PAPMI_InsurSubType	%String	在职状态
如在职,离休,退休	医保提供,
20100428中山三院
2.	PAPMI_InsurCardNo	%String	公费医疗证编码	20100428中山三院
3	PAPMI_InsurSpecType	%String	公医医疗证类别	医保提供
20100428中山三院
				

病人信息扩展表(DHCPerson)
1	PAPMI_BirthTime	%Time	出生日期	
2	PAPMI_BirthPlace		出生地	
	PAPER_PaPerson_dr       		指向pa_person表	
	PAPER_SGMedicareCode1		血透档案号	韶关
	PAPER_SGMedicareCode2		家庭病床档案号	韶关
	PAPER_SGMedicareCode3		宁养院档案号	韶关
	PAPER_FCMedicareCode1		妇产档案号1	妇产
	PAPER_FCMedicareCode2		妇产档案号2	妇产
	PAPER_Comment1		备用	
	PAPER_Comment2		备用	
	PAPER_Comment3		备用	
	PAPER_Comment4		备用	
	PAPER_Comment5		备用	
	PAPER_CityFlag		本埠外埠	

病人医保信息表; PA_PersonAdmInsurance
1	PAINS_ParRef		PA_Person	
2	PAINS_InsType_DR		保险公司	
3	PAINS_AuxInsType_DR		保险类型	
4	PAINS_DateTypeTo	Date	效期	
5	PAINS_Rank		保险额度	
6				

就诊医保信息PA_AdmInsurance
1	INS_ParRef		PA_Adm	
2	INS_InsType_DR		保险公司	
3	INS_AuxInsType_DR		保险类型	
4	INS_DateTypeTo	Date	效期	
5	INS_Rank		保险额度	
6	INS_CardNo		卡号	
7	INS_CaseClaimNo		保单号	
8	INS_CoPaymentPercentage		自付比例	
9	INS_MaxCopaymentAmt		自付额度	
10	INSCardholderName		保险持有者	

就诊支付信息记录表DHC_PAAdmPayModeRecord（华山医院 郭荣勇）
^PAADM(PA_Adm.PAAdm_RowId,"PMR",Childsub,"DHC")
1	PMR_ParRef		PA_Adm	
2	PMR_PayMode_DR		支付方式关联	以!分割的多种支付方式
3	PMR_ Theholder		持卡人	使用银行卡
4	PMR_Cardnumber		银行卡号	
5	PMR_ValiduntiltoCard	Date	银行卡有效期	
6	PMR_CompanyName		公司名称	使用公司卡
7	PMR_CompanyPerson		公司联系人	
8	PMR_CompanyPhone		公司电话	
9	PMR_CompanyEmail		公司Email	
10	PMR_ResponsiblePayment		付款人	
11	PMR_ResponsibleNumber		付款人电话	
12	PMR_ResponsibleMobile		付款人手机	
13	PMR_ResponsibleRelationship		付费人与患者关系	
14	PMR_ResponsibleEmail		付款人的Email	
15	PMR_EmailInCon		Email知情同意情况	
16	PMR_EmailDescription			
17	PMR_AppReminder			
18	PMR_CoPayment		共担额	
19	PMR_Deductible		可减免的部分	
20	PMR_PayRate		支付率	
21	PMR_USD		USD	
22	PMR_PolicyNo		保险号	
				
病人信息表扩展
$P（^PAPER({PAPER_RowId} ,”DHC”)）
1	PAPMI_BirthTime	%Time	出生时间	
2	PAPMI_BirthPlace		出生地	
3	PAPMI_CredTypeDR		其他证件类型	
4	PAPMI_CredNo		证件号	

病人信息扩展表(DHCPerson)
1	PAPMI_BirthTime	%Time	出生日期	
2	PAPMI_BirthPlace		出生地	

病人医保信息表; PA_PersonAdmInsurance
1	PAINS_ParRef		PA_Person	
2	PAINS_InsType_DR		保险公司	
3	PAINS_AuxInsType_DR		保险类型	
4	PAINS_DateTypeTo	Date	效期	
5	PAINS_Rank		保险额度	


就诊表 PA_Adm 
实体类: User.PAADM
业务类: Web.PAADM
存储globe: ^PAADM
序号	列名	结点	描述	备注
1	PAADM_PAPMI_DR		指向病人基本信息表	PA_Patmas
2	PAADM_Type		就诊类型	“O”:门诊
4	PAADM_DepCode_DR		就诊科室	
6	PAADM_AdmDate		就诊日期	
7	PAADM_AdmTime		就诊时间	
17	PAADM_DischgDate		出院日期	
9	PAADM_AdmDocCodeDR		就诊医生	
20	PAADM_VisitStatus		就诊状态	“A”正常  “C”退号
7	PAADM_FirstOrReadmis	String	复诊标志	F:初诊   R:复诊(积水潭:出院复诊)
29	PAADM_InPatNo		住院次数	
30	PAADM_TriageDate	1	发病日期	
56	PAADM_AdmReadm		复诊标志	R:复诊
4	PAADM_DepCode_DR		当前科室	CT_loc
70	PAADM_CurrentWardDR		当前病区	PAC_Ward
69	PAADM_Current_RoomDR		当前病房	PAC_Room
73	PAADM_CurrentBedDR		当前病床	PAC_Bed
7	PAADM_AdmReason_DR	1	费别	PAC_AdmReason
15	PAADM_Completed	Yes/No	结束标志	
16	PAADM_AdmCateg_DR		欠费管理用	PAC_AdmCateg
17	PAADM_InPatAdmType_DR		诊别(哈尔滨用)	PAC_InPatAdmissionType
18	PAADM_DischCond_DR		出院条件	PAC_DischCondit

就诊表扩展节点 
 ^PAADM({PAADM_RowID},"DHC")
1	PAADM_CheckInsued	Y/N	是否医保	
2	PAADM_CheckInsuUser_DR	String	核对人	
3	PAADM_CheckInsurDate	String	核对日期	
4	PAADM_CheckInsurTime	String	核对时间	
5	PAADM_TransferFlag	String	转诊标识	Y/N/
6	PAADM_CTEscortUnits	String	送押单位	^PAADMi("CTEscortUnits",$p(^PAADM({PAADM_RowID},"DHC"),"^",6)
,{PAADM_RowID})
7	PAADM_EscortPerson	String	送押民警	
8	PAADM_NotDistDrugs	String	不配药	只有深圳中医院用(草药录入置上”不配药”\标识,药房对此就诊先不配药)
针对 关系病人
9	PAADM_BregType	String	预约类型	仅VB版本用,VB版本系统没有按预约方式设置数据的功能,暂用此字段记录 诊间预约的功能,仅友谊用.复兴,安贞使用诊间预约
10	PAADM_ArriveDep_DR	String	就诊到达科室	为CT_Loc表Rowid,现使用医院:衢州

就诊病历表 MR_Adm 
实体类: User.MRADM
业务类: Web.MRADM
存储globe: ^MRADM
序号	列名	类型	描述	备注
1	MRADM_ADM_DR	String	就诊指针	MR_Adm
2	MRADM_Weight	String	体重	
3	MRADM_Height	String	身高	
4	MRADM_DischDestin_DR	String	病人去向	PAC_DischargeDestination
5	MRADM_DischType_DR	String	治疗情况	CT_Disposit
6	MRADM_GPConsent	String	慢病标志	Y：是
7	MRADM_OnsetDate	Date	就诊发病日期	

就诊病历扩展表 MR_Adm
存储globe: $P（^MR({MR_Adm.MRADM_RowId},DHC",)）
序号	列名	类型	描述	备注
1	MRADM_OPERInsurCode1		医保手术代码1	
2	MRADM_OPERInsurCode2		医保手术代码2	
3	MRADM_OPERInsurCode3		医保手术代码3	
4	MRADM_PregnentInsurCode		生育保险代码	
5	MRADM_TBInsurCode		特病代码	
6	MRADM_DBInsurCode		大病代码	
7	MRADM_BodySize		体表面积	
8	MRADM_DTPhyStatus		大通接口生理状态	字符串(1_$c(1)_孕妇_!_2_$c(1)_肝功能不全)
9	MRADM_Specimen		是否采样	Y:是        衢州
取生育保险基础数据w $$GetDicDataStr^DHCINSUDicData("BearingItem", "")
!492^BearingItem^20^上环术^^^!489^BearingItem^21^取环术^^^!487
此M医保组提供，在app下
返回结果用先用“！”分，492^BearingItem^20^上环术^^^ 用“^”  其中3，4分别是代码和名称

就诊诊断表MR_Diagnos
序号	列名	类型	描述	备注
	MRDIA_MRADM_Parref		父指针	MR_Adm
1	MRDIA_ICDCode_DR	String	诊断	MRC_ICDDX
2	MRDIA_DocCode_DR	String	下诊断医生	CT_CareProv
3	MRDIA_Date	Date	下诊断日期	
4	MRDIA_Time	Time	下诊断时间	
5	MRDIA_Desc		附加描述	
6	MRDIA_SignSym_DR		症状	MRC_DiagnosSignSymptom
7	MRDIA_Childsub	String		
8	MRDIA_DateDetect	String	Date Detected	
9	MRDIA_ICDStatus_DR	String		MRCICDStat
10	MRDIA_WorkRelated	Y/N	Work Related	
11	MRDIAICDSupDR			MRCSuppICD
12	MRDIA_DiagStat_DR			MRCDiagnosStatus
13	MRDIA_DRGOrder			
14	MRDIA_UpdateUser_DR			SSUser
15	MRDIA_DiagnosisGroup1_DR			MRCDiagnosisGroup1
16	MRDIA_DiagnosisGroup2_DR			MRCDiagnosisGroup2
17	MRDIA_StageClas_DR			PACStageClassification
诊断表扩展
$P（^MR({MR_Adm.MRADM_RowId},"DIA",{MRDIA_Childsub},”DHC”)）
1	TClass		T分级	0、1、2、3、4、X
2	NClass		N分级	0、1、2、3、4、X
3	MClass		M分级	0、1、2、3、4、X
4	InsurCode		医保诊断代码	沈阳用
5	SpecDiagnosFlag		医保10种慢性病诊断标识	复兴用 1:存在,其他:不存在 Add By 郭荣勇
6	FirstDiagnos		初步诊断	南昌用
7	CHDiagnos		中医诊断及症型	南昌用

医保诊断表 INSU_Diagnos
实体类: User. INSUDiagnos
业务类: Web. INSUDiagnos
存储globe: ^ INSUDiagnos

1	RowId			
2	Code		代码	
3	Desc		描述	
4	Alias		别名	
5	StartDate		开始日期	
6	EndDate		截止日期	


症状表 MRC_DiagnosSignSymptom
实体类: User.MRCDiagnosSignSymptom
业务类: Web. MRCDiagnosSignSymptom
存储globe: ^MRC("DSYM")
序号	列名	类型	描述	备注
1	DSYM_RowId	String		
2	DSYM_Code	String	代码	
3	DSYM_Desc	String	名称	
4	DSYM_CTLOC_DR	String	科室	CT_Loc
5	DSYM_DateFrom	String	开始日期	
6	DSYM_DateTo	String	截止日期	
7	DSYM_ActiveInActive	Yes/No	有效标志	

症状别名表 DHC_MRCDiagnosSignSymptomAlias
实体类: User.DHCMRCDiagnosSignSymptomAlias
业务类: Web. DHCMRCDiagnosSignSymptom
存储globe: ^MRC("DSYM",RowId,”ALIAS”,Child)
序号	列名	类型	描述	备注
1	DSYMA_RowId	String	指针	
2	DSYMA_ParRef	String	代码	
3	DSYMA_Child	String		
4	DSYMA_Alias	String	别名	CT_Loc

队列表 DHCQueue 
实体类: User.DHCQueue
业务类: Web.DHCQueue
存储globe: ^ User.DHCQueue
序号	列名	类型	描述	备注
1		String	病人指针	PA_Patmas
2	QueDate	Date	就诊日期	
3	QuePersonId	String	病人指针	
4	QuePaadmDr	Date	就诊指针	
5	QueStateDr	String	排队状态	
6	QueDocDr	String	呼叫医生	
7	QueMarkDr	String	号别	
8	QueNo	String	排队号	
9	QueCompDr	String	叫号状态	1:呼叫,2:候诊

排队状态表
序号	列名	类型	描述	备注
1	PersCode	String	代码	
2	PersName	String	描述	复诊
等候
过号
到达
退号
未分配 挂号
3	PersMemo	String	缩写	
				


科室表 CT_Loc 
实体类: User.CTLOC
业务类: Web.CTLOC
存储globe: ^OEORD
序号	列名	类型	描述	备注
	CTLOC_RowId			
1	CTLOC_Desc	String	就诊记录指针	PA_ADM
	CTLOC_ExternalViewerLink	String	注释取结果位置和注意事项	
	CTLOC_ContactName	String	科室别名	
科室表扩展节点 
 ^CTLOC({CTLOC_RowID}),"DHC")
1	CTLOC_LogonAsAdmLoc	String	登陆科室做为就诊科室	1:是   0:否
2	CTLOC_DepGroup 	String	科室组	DHC_LocGroup
3	CTLOC_AllowTransfer	String	允许转诊	东方医院
4	CTLOC_NotAllowPackQty	String	不允许录整包装	华山医院
医嘱表(医嘱主表,就诊一次有一张表)OE_Order
实体类: User.OEOrdItem,User.OEOrder
业务类: Web.OEOrdItem,Web.OEOrder
存储globe: ^OEORD
OE_Order(^OEORD({OEORD_RowId}))
序号	列名	结点	描述	备注
	OEORD_RowId			
1	OEORD_Adm_DR		就诊记录指针	PA_ADM
医嘱明细表OE_OrdItem 

OE_OrdItem (^OEORD({OE_Order.OEORD_RowId},"I",{OEORI_Childsub}))
序号	列名	结点	描述	备注
	OEORI_OEORD_Parref		父表	OE_Order
2	OEORI_ItmMast_DR	1	医嘱项指针	ARC_ItmMast
9	OEORI_SttDat	1	开始日期	
10	OEORI_SttTim	1	开始时间	
11	OEORI_Doctor_DR	1	开医嘱医生	CT_CareProv
8	OEORI_Priority_DR	1	医嘱类型	OEC_Priority
13	OEORI_ItemStat_DR	1	医嘱状态	OEC_ItemStatus
U：未审核，删除医嘱用
I:未激活,实习医生开医嘱用
15	OEORI_PrescNo	1	处方号	
1	OEORI_DoseQty	2	剂量	
3	OEORI_Unit_DR	2	剂量单位	CT_Unit
4	OEORI_PHFreq_DR	2	频率	PHC_Freq
6	OEORI_Durat_DR	2	疗程	PHC_Duration
7	OEORI_Instr_DR	2	用法	PHC_Instruction
8	OEORI_PhSpecInstr	2	草药用法描述	
4	OEORI_SeqNo	3	关联号	
6	OEORI_RecDep_DR	3	接受科室	CT_LOC
7	OEORI_Date	3	开医嘱日期	
15	OEORI_Time	3	开医嘱时间	
20	OEORI_LabEpisodeNo	3	检验条码	
25	OEORI_Price	3	自定义价格	
29	OEORI_XCTCP_DR	3	停止医生	CT_CareProv
34	OEORI_XDate	3	停止日期	
15	OEORI_XTime	2	停止时间	
9	OEORI_EndDate	9	预停日期	
10	OEORI_EndTime	9	预停时间	
1	OEORI_UserAdd	7	医嘱录入人	SS_User
2	OEORI_UserDepartment_DR	7	医嘱录入科室	CT_LOC
18	OEORI_BBExtCode	11	费别	PAC_AdmReason
39	OEORI_OEORI_DR	11	关联医嘱	OE_Orditem
	OEORI_DepProcNotes	"DEP"	备注	
6	OEORI_DRGOrder	6	诊断分类指针	DHC_DiagnosCat
18	OEORI_Qty	1	长嘱首次数量	
12	OEORI_FillerNo	9	滚医嘱来源信息	首医嘱!! 上一条医嘱
	OrderNotifyClinician		紧急标志	
21	OEORI_Action_DR	11	皮试备注	
2	OEORI_AdministerSkinTest	5	皮试标志	
2	OEORI_AdmLoc_DR	9	就诊科室	
5	OEORI_Billed	3	结算状态	
12	OEORI_PhQtyOrd	1	基本单位数量	
8	OEORI_PhSpecInstr	2	草药用法	
4	OEORI_QtyPackUOM	9	整包装数量	
	OEORI_Remarks	"REM"	备注	
23	OEORI_RefundQty	3	退费次数	停止医嘱时计算的应退执行次数
1	OEORI_ItemGroup	6	组号	将某类医嘱归为一组
16	OEORI_Lab1	8	病理记录指针	
3	OEORI_OrdDept_DR	1	下医嘱科室	
3	OEORI_Abnormal	11	皮试结果	Y:阳性,N:阴性,空:没有结果
9	OEORI_Anaest_DR	4	手术ID	关联表 OR_Anaesthesia
3	OEORI_CoverMainIns	3	医保标识(住院)	Y:医保,N:非医保
16	OEORI_Lab1	8	微生物标本来源关联	首家为复兴使用
新增索引-停止日期
S^OEORDi(0,"DHCXDate",{OEORI_XDate}, {OE_Order.OEORD_RowId},{OEORI_Childsub})=""

医嘱表扩展节点 
 ^OEORD(+OrderItemRowId,"I",$P(OrderItemRowId,"||",2),"DHC")
节点	列名	类型	描述	备注
1	ExecuteDateStr		医嘱日期串	
2	ASRowId		资源排班记录指针	AS_ApptSchedule
3	InsurCatRowId		医保类别指针	
4	StopDripFlag		停止输液标志	1:停止
5	StopDripDate	Date	停止输液日期	
6	StopDripTime	Time	停止输液时间	
7	StopUserRowId		停止输液人	SS_User
8	Order_Stage		医嘱阶段	SQ:术前
SZ:术中
SH:术后
9	Order_OMProcNoteRowId		嘱托备注	描述来源于配置
10	Order_Project		科研项目	药理项目的rowid
11	Order_NutritionDrugFlag		营养药标志	1:是  0:否  
友谊用,南通为12需改正
12	OEORI_DispWeekTime		星期频次的分发点	记录CT_DayOfWeek. DOW_Day以”^”分隔
13	OEORI_OldPrice		老系统价格	Add For 廊坊 2010-06-02
周志强
14	OEORI_MaterialNo		高值材料条码	Add For 肿瘤 2010.07.08
周志强
15	OEORI_MedUnit_DR		医疗单元	Add For 徐州2010.08.02
周志强
16	OEORI_NeedPIVAFlag		需要配液标志	Add For 沈阳 2010.10.25
郭荣勇  1:是  非1:否
17	OEORI_StayStatusFlag		留观状态标识	Add For 北京医保急诊留观
郭荣勇  1:是  非1:否
18	OEORI_UseObjective		医嘱是”治疗/预防”	Add For 山东省立医院
郭荣勇  1:治疗  2:预防
其它医院为:文本描述
19	OEORI_PayorAduitFlag		记账审核标识	Add For 协和医院
郭荣勇  Y:通过  N/’’:未通过
医嘱表扩展节点(此节点结合OrderNutritionDrugFlag使用) ^OEORD(+OrderItemRowId,"I",$P(OrderItemRowId,"||",2),"NDRUG",1)=配药日期^配药时间^配药人

医嘱扩展表 DHC_OE_OrdItem 
结点	列名	位置	描述	备注
	DHCORI_RowId			
	DHCORI_OEORI_Dr	1		OE_Orditem的指针
	DHCORI_SkinTestCtcp_Dr	2	置皮试结果人	CT_CareProv
	DHCORI_SkinTestDate	3	置皮试结果日期	
	DHCORI_SkinTestTime	4	置皮试结果时间	
	DHCORI_PAALG_Dr	5	过敏表指针	PA_Allergy
	DHCORI_DisconUser_Dr	6	停止医嘱处理人	070206	HeFei
	DHCORI_DisconDate	7	停止医嘱处理日期	070206	HeFei
	DHCORI_DisconTime	8	停止医嘱处理时间	070206	HeFei
	DHCORI_MedAuditUser_Dr	9	领药审核人	070206	HeFei
	DHCORI_SkinTestAuditDate	10	领药审核日期	070206	HeFei
	DHCORI_MedAuditTime	11	领药审核时间	070206	HeFei
	DHCORI_DispTimeList	12	发药时间列表	070425  ShangHai
	DHCORI_SkinTestAuditCtcp_Dr	13	皮试结果审核人	080710	ShenYang
	DHCORI_SkinTestAuditDate	14	皮试结果审核日期	080710	ShenYang
	DHCORI_SkinTestAuditTime	15	皮试结果审核时间	080710	ShenYang
1	DHCORI_RefundAuditStatus	1	退费审核状态	
1	DHCORI_RefundAuditUser_Dr	2	退费审核用户	
1	DHCORI_RefundAuditDate	3	退费审核日期	
1	DHCORI_RefundAuditTime	4	退费审核时间	
1	DHCORI_RefundReason	5	退费审核原因	
1	DHCORI_RefAuditLoc_DR	6	退费审核科室	
2	DHCORI_Approved	1	记账/医保审核状态	071119	ShenYang/吉大, Yes/No  Yes:通过,No:不通过
2	DHCORI_ApprovedUser_dr	2	记账/医保审核人	071119	ShenYang/吉大
2	DHCORI_ApprovedDate	3	记账/医保审核日期	071119	ShenYang/吉大
2	DHCORI_ApprovedTime	4	记账/医保审核时间	071119	ShenYang/吉大
2	DHCORI_ApprovedPercent	5	记账审核比例	100426  中山三院
2	DHCORI_ApprovedLimit	6	记账审核限额	100426  中山三院
2	DHCORI_ApprovedFlag	7	记账审核类型	100518	中山三院, 1:修改比例了，2:国产限价
2	DHCORI_ApproveType	8	医保需审类型	010609  吉大三院, 1:医保特病 2:医保处方超限 3:特殊药品 4:特殊材料
	DHCORI_LISReport_DR	16	接收第三方报告状态	2008-11-26 ZhaoCZ
3	DHCORI_ConfirmFlag	1	财务审核标志	090506  肿瘤
3	DHCORI_ConfirmDate	2	财务审核日期	090506  肿瘤
3	DHCORI_ConfirmTime	3	财务审核时间	090506  肿瘤
3	DHCORI_ConfirmUser	4	财务审核人	090506  肿瘤
3	DHCORI_WardID	5		(对比广州中山医院的库和肿瘤的库，广州有，肿瘤没有该字段)
3	DHCORI_Paadm_Dr	6	就诊	090506  肿瘤
4	DHCORI_DoctorConfirmFlag	1	科室审核标志	090717  深圳
4	DHCORI_DoctorConfirmDate	2	科室审核日期	090717  深圳
4	DHCORI_DoctorConfirmTime	3	科室审核时间	090717  深圳
4	DHCORI_DoctorConfirmUser_Dr	4	科室审核人	090717  深圳
^DHCORDItem  用于后期医嘱处理，包括护士执行和财务审核
医嘱别名表 ARC_Alias
实体类: User.ARCAlias
存储globe: ^ARC("ALIAS",{ALIAS_RowId})
序号	列名	类型	描述	节点	备注
					

医嘱适应症 DHC_OE_OrdItemDSYM  2009.02.27
^OEORD(+OEORDS_OEORI_PARREF,"I", OEORDS_OEORI_Childsub,"DSYM")
序号	列名	类型	描述	节点	备注
1	OEORDS_OEORI_PARREF	String			OEOrdItem.parref
2	OEORDS_OEORI_Childsub	String			OEOrdItem.child
3	OEORDS_Childsub	String			
4	OEORDS_DSYM_DR	String		1	MRCDiagnosSignSymptom
5	OEORDS_DSYMCode	String		2	MRCDiagnosSignSymptom
库存医嘱发放记录(发药)表 DHC_OEDispensing
^DHCOEDISQTY (DSP_RowId)
序号	列名	类型	描述	节点	备注
1	DSP_RowId	String			DSP_RowId
2	DSP_OEORI_DR	String	医嘱指针		OE_OrdItem
3	DSP_TotalQty	String	医嘱总数量		
4	DSP_OEORE_DR	String	医嘱执行指针		OE_OrdExec
5	DSP_SeqNo	String	医嘱执行顺序		
6	DSP_Qty		发药退药数量		
7	DSP_QtyUom		发药退药单位		CT_UOM
8	DSP_Status		发药退药状态		(待发\发药\退药)（TC\C\R）
9	DSP_Time		发药退药时间		
10	DSP_Date		发药退药日期		
11	DSP_User		发药退药操作人		SS_User
12	DSP_ConfirmQty		确认发药数量		
13	DSP_ConfirmUser		确认人		
14	DSP_Type		操作类型		
15	DSP_Pointer		操作指针		
16	DSP_DateAdd		生成日期		
17	DSP_TimeAdd		生成时间		
18	DSP_ConfirmFlag		确认数量		Yes/No
19	DSP_DateConfirm		确认日期		
20	DSP_TimeConfirm		确认时间		
21	DSP_TimeDosing		配液时间		
^DHCOEDISQTY(“”)
用药权限设置表DHC_ArcItemAut
DataMaster： ^ARCIM({AUT_ARCIM_Dr},{AUT_Childsub},"DHCAUT")
序号 	字段 	描述 	类型 	备注 
1 	AUT_RowID 	 	RowID 	 
2 	AUT_ARCIM_Dr 	医嘱项 	Dr 	 ARC_ItmMast
3 	AUT_Childsub 	 	Number 	 
4 	AUT_Relation 	关系 	Text 	值为“OR”，“AND” 
5 	AUT_Type 	类型 	Multiple Choice 	CTLOC||KS代表科室
CTCPT||ZC代表职称
SSUSR||YS代表医生 
6	AUT_Operate	操作	Text	值为“=”，“<>”，“>=”
7	AUT_Pointer	指向	Text	Type=“KS”，CT_Loc的ID；
Type=“ZC”，CT_CarPrvTp的ID；
Type=“YS”，SS_User的ID 
医嘱套权限控制表 DHC_UserFavItems
实体类:User. DHCUserFavItems
业务类: web.DHCUserFavItems
存储: ^DHCFavItems
序号	列名	类型	描述	备注
1	Fav_Type	String	项目类型	ARCOS/Item
2	Fav_User_Dr	ds	用户	
3	Fav_ItemRowid	String	项目Rowid	
4	Fav_Dep_Dr	ds	使用科室	
5	Fav_Other	String	其他使用	
6	Fav_ContralType	String	使用类型	

处方表 PA_QUE1
序号	列名	类型	描述	备注
1	QUE1_RowId	String		
2	QUE1_PAADM_DR	String	就诊记录指针	
3	QUE1_PrescNo	String	处方号	
^OEORD(0,"PrescNo",{OEORI_PrescNo},{OE_Order.OEORD_RowId},       {OEORI_Childsub})    

处方表扩展定义
^PAQUE1(QUE1_RowID,"DHC")
序号	列名	类型	描述	备注
1	PQPT_BillType_DR	String	费别	
2	PQPT_PrescriptType	String	处方类别	
3	PQPT_UserAdd_DR	String	用户	
4	PQPT_Date		日期	
5	PQPT_Time		时间	
6	PQPT_StartDate		开始日期	
7	PQPT_StartTime		开始时间	
8	PQPT_ItemStat_DR		状态	
9	PQPT_Frequence_DR		频次	
10	PQPT_Duration_DR		副数	
11	PQPT_Instruction_DR		用法	
12	PQPT_RecLoc_DR		接收科室	
13	PQPT_OrderQty		用量	
14	PQPT_OrderUOM		用量单位	
15	PQPT_PhCookMode		煎药方式	
16	PQPT_PackMode		包装方式	
17	PQPT_PackQty		副数	
18	PQPT_XDate		停止日期	
19	PQPT_XTime		停止时间	
20	PQPT_XUser_DR		停止用户	
21	PQPT_Notes		备注	
22	PQPT_Emergency		加急	
23	PQPT_MRDIARowids		处方诊断	
24	POPT_ARCOS_DR		医嘱套关联	
25	POPT_MedicationWay		服药方式	首家烟台中医院

医嘱分类OEC_OrderCategory
医嘱子分类ARC_ItemCat 

序号	列名	类型	描述	备注
	ARCIC_RowId			
1	ARCIC_Code	String		
2	ARCIC_Desc	String		
3	ARCIC_OrderType	String		R:药品N:诊疗 L:检验P:自定价医嘱

医嘱项ARC_ItmMast
序号	列名	类型	描述	备注
1	ARCIM _RowId	String		
2	ARCIM_MaxQty		医嘱最大量，一次开医嘱过程中剂量*频次*疗程算出的基本数量，	现在暂时用于控制医嘱录入整包装量的最大限量
3	ARCIM_ProcessingNotes		处理注意事项	草药录入的默认用法在此维护
4	ARCIM_Sensitive		紧急处理标志	医嘱项目维护上ResultSensitive代表是否可以在医嘱录入界面上选择紧急标志
5	ARCIM_SensitiveOrder		贵重药标志	
医嘱项扩展节点 
 ^ARCIM(+ARCIM _RowId,"I",$P(ARCIM _RowId,"||",2),"DHC")

节点	列名	类型	描述	备注
1	StopPreLongOrder	String	自动停止以前的长期医嘱	1:允许   0:不允许
2	NotAutoStop	String	不能被自动停止的长期费用医嘱	1:允许   0:不允许
医嘱项外部代码ARC_ItemExternalCodes
节点	列名	类型	描述	备注
1	EXT_DEfaultSend	Yes/No	单独生成标本号标志	Y:是   N:否
药学项PHC_DrgForm
序号	列名	类型	描述	备注
	PHCDF_PHCD_Parref		父指针	PHC_DrgMast
1	PHCDF_RowId	String		
2	PHCDF_Indication		适应症	
3	PHCDF_ContraInd		禁忌症	
4	PHCDF_Interaction		相互作用	
5	PHCDF_Precaution		注意事项	
6	PHCDF_Advreaction		不良反应	
7	PHCDF_Warning		警告	

已经有的接口方法:
1.是否毒麻药:
s ret=##class(web.DHCDocOrderCommon). GetDrgFormPoison(ARCIMRowid)
ret<>”” 代表毒麻药

药学项扩展节点 
 ^PHCD(+PHCDF_RowId,"DF",$P(PHCDF_RowId,"||",2),"DHC")

节点	列名	类型	描述	备注
1	CalcuDose	String	按总剂量计算整包装	1:允许   0:不允许
2	OPSkinTestYY	String	门诊皮试用原液	1:允许   0:不允许
3	IPSkinTestYY	String	住院皮试用原液	1:允许   0:不允许
4	AgeLimit	String	年龄限制	

医护人员级别药品管制分类对照DHC_CarPrvTpPHPoison
实体类: User.DHCCarPrvTpPHPoison
业务类: Web. DHCCarPrvTpPHPoison
存储globe: ^CT("CPT",RowId,”PHPO”,Child)
序号	列名	类型	描述	节点	备注
1	TPP_RowId	String	指针		
2	TPP_ParRef	String	父指针		User.CTCarPrvTp
3	TPP_Child	String			
4	TPP_Poison_DR	String	管制分类	1	User.PHCPoison
5	TPP_ControlType	String	允许类型	2	AlERT： 提示
FORBID：禁止   



费别医保医疗类别对照DHC_BillTypeEPType
实体类: User.DHCBillTypeInsurEPType
业务类: Web. DHCBillTypeInsurEPType
存储globe: ^PAC("ADMREA",{REA_RowId},”INSUR”,ChildSub)
序号	列名	类型	描述	节点	备注
1	BI _RowId	String	指针		
2	BI_BillType_ParRef	String	父指针		PAC_AdmReason
3	BI_Child	String			
4	BI_EpisodeType	String	就诊类别	1	I:住院,O:门诊,E:急诊
5	BI_InsurEPType_DR	String	医保医疗类别指针	3	 INSU_DicData
6	BI_Default	String	默认		Y:默认,N:不默认
INSU_DicData医保的基础对照表，采用链式方式记录了医保医疗类别和医保医疗子类别代码和其他信息，NSU_DicData.INDID_DicType =“SYS”， INSU_DicData.INDID_DicType= BI_InsurType
人员类别费别对照表DHC_PACADM
实体类: User. DHCPACADM
业务类: Web. DHCPACADM
存储globe: ^DHCPACADM
序号	列名	类型	描述	节点	备注
1	PAC_RowId	String	指针		
2	PAC_SocialStatus_Dr	String	病人类别	1	PAC_SocialStatus
3	PAC_AdmReason_Dr	String		2	PAC_AdmReason
4	PAC_StartDate	String	开始日期	3	
5	PAC_EndDate	String	截止日期	4	

出诊科室设置 PAC_AdmTypeLocation
实体类: User.PACAdmTypeLocation
存储globe: ^CTPCP({CTPCP_RowId})
序号	列名	类型	描述	节点	备注
1	ADMLOC_ _RowId		指针		
2	ADMLOC_AdmType	String	就诊类型	1	“O”,”I”,”E”
3	ADMLOC_CTLOC_DR	String	科室类型	2	
4	ADMLOC_LocDesc	Compu	描述		

医护人员 CT_CareProv
实体类: User. CTCareProv
存储globe: ^CTPCP({CTPCP_RowId})
序号	列名	类型	描述	节点	备注
1	CTPCP _RowId		指针		
2	CTPCP_Code	String	代码		
3	CTPCP_Desc	String	描述		
4	CTPCP_ActiveFlag	Y/N	有效标志		
5	CTPCP_Anaesthetist	Y/N	麻醉师标志		
20	CTPCP_Radiologist	Y/N	放射师标志		
22	CTPCP_Surgeon	Y/N	外科医生标志		
6	TPCP_AuthorID	String			
7	CTPCP_CPGroup_DR	String	医生组		CT_CareProvGroup
8	CTPCP_DateActiveFrom	Date	开始日期		
9	CTPCP_DateActiveTo	Date	截止日期		
10	CTPCP_DOB	Date	生日		
11	CTPCP_Email	String	Email		
12	CTPCP_Fax	String	传真		
13	CTPCP_TelH	String	家庭电话		
14	CTPCP_TelO	String	办公室电话		
16	CTPCP_MobilePhone	String	移动电话		
15	CTPCP_Hosp_DR		所属医院		CT_Hospital
17	CTPCP_SpecialistYN	Y/N	专家标志		
18	CTPCP_Spec_DR		专业		CT_Spec
19	CTPCP_SubSpec_DR		子专业		CT_Spec
21	CTPCP_RespUnit_DR				CT_ResponsibleUnit
23	CTPCP_Title	String	头衔		
					
科室 CT_Loc
实体类: User. CTLoc
存储globe: ^CTLOC(CTPCP _RowId)
序号	列名	类型	描述	节点	备注
1	CTLOC_RowId	String	科室指针		
2	CTLOC_Code	String	代码		
3	CTLOC_Desc	String	描述		
4	CTLOC_Hospital_DR	String	医院		
5	CTLOC_Type	Date	开始日期		Ward||W
Execute||E
Drug Injection||DI
Dispensing||D
Cashier||C
Other||O
Operating Theatre||OP
Emergency||EM
Day Surgery||DS
Medical Records||MR
OutPatient Consulting Room||OR
Clinic||CL
6	CTMU_DateTo	Date	截止日期		


科室医护人员归属RB_Resource
实体类: User. RBResource
存储globe: ^RB("RES",{RES_RowId})
序号	列名	类型	描述	备注
	RES_Rowid			
1	RES_ScheduleRequir		需要排班	
2	RES_CTLOC_DR		资源对应科室	
3	RES_CTPCP_DR		资源对应医生	
4	RES_EQ_DR		资源对应设备	
5	RES_Code		资源代码	

医疗单元DHC_CTLoc_MedUnit
实体类: User. CTLocMedUnit
存储globe: ^CTLOC(CTPCP _RowId,”MU”, CTMU_Childsub)
序号	列名	类型	描述	节点	备注
1	CTMU_CTLOC_ParRef	String	科室指针		CT_Loc
2	CTMU_Childsub				
3	CTMU_Code	String	代码	1	
4	CTMU_Desc	String	描述	2	
5	CTMU_ActiveFlag	String	激活标志	3	
6	CTMU_DateFrom	Date	开始日期	4	
7	CTMU_DateTo	Date	截止日期	5	

医疗单元医护人员DHC_CTLoc_MedUnitCareProv
实体类: User. CTLocMedUnitCareProv
存储globe: ^CTLOC(CTPCP _RowId,”MU”, CTMU_Childsub,”CP”, MUCP_Childsub)
序号	列名	类型	描述	节点	备注
1	MUCP_ParRef	String	医疗单元指针		DHC_CTLOC_ParRef
2	MUCP_Childsub	String			
3	MUCP_Doctor_DR	String	描述	1	CT_CareProv
4	MUCP_LeaderFlag	Y/N	组长标志		
5	MUCP _OPFlag	Y/N	门诊标志		
6	MUCP _IPFlag	Y/N	住院标志		
7	MUCP _DateFrom	Date	开始日期	4	
8	MUCP _DateTo	Date	截止日期	5	

公安医院送押单位 DHC_CTEscortUnits
实体类: User. DHCCTEscortUnits
存储globe: ^DHCCTEU(“EU”,Rowid)
序号	列名	类型	描述	节点	备注
1	EU_Rowid	String			
2	EU_Code	String	代码		
3	EU_Desc	String	描述		
4	EU_Alias	String	别名		
5	EU_StartDate	Date	开始日期		
6	EU_EndDate	Date	结束日期		

科室外部字典对照 DHC_LocExternal
实体类: User. DHCLocExternal
存储globe: ^DHCLE(Rowid)
说明:主要用于和外部接口的科室字典数据对照
序号	列名	类型	描述	节点	备注
1	LE_Rowid	Float			
2	LE_Local_Loc_DR	Float	指向CT_LOC		需要索引
3	LE_Local_Desc	String	本地科室描述		
4	LE_Ext_Code	String	外部科室代码		需要索引
5	LE_Ext_Desc	String	外部科室描述		
6	LE_Active	Yes/No	可用标识		默认为可用
频次外部字典对照 DHC_ FreqExternal
实体类: User. DHCFreqExternal
存储globe: ^DHCFE(Rowid)
说明:主要用于和外部接口的频次字典数据对照
序号	列名	类型	描述	节点	备注
1	FE_Rowid	Float			
2	FE_Local_Freq_DR	Float	指向PHC_Freq		需要索引
3	FE_Local_Desc	String	本地科室描述		
4	FE_Ext_Code	String	外部科室代码		需要索引
5	FE_Ext_Desc	String	外部科室描述		
6	FE_Active	Yes/No	可用标识		默认为可用

用法外部字典对照DHC_ InstrucExternal
实体类: User. DHCInstrucExternal
存储globe: ^DHCIE(Rowid)
说明:主要用于和外部接口的用法字典数据对照
序号	列名	类型	描述	节点	备注
1	IE_Rowid	Float			
2	IE_Local_Instruc_DR	Float	指向PHC_Instruc		需要索引
3	IE_Local_Desc	String	本地科室描述		
4	IE_Ext_Code	String	外部科室代码		需要索引
5	IE_Ext_Desc	String	外部科室描述		
6	IE_Active	Yes/No	可用标识		默认为可用

疗程外部字典对照 DHC_ DurationExternal
实体类: User. DHCDurationExternal
存储globe: ^DHCDE(Rowid)
说明:主要用于和外部接口的疗程字典数据对照
序号	列名	类型	描述	节点	备注
1	LE_Rowid	Float			
2	LE_Local_Duration_DR	Float	指向CT_LOC		需要索引
3	LE_Local_Desc	String	本地科室描述		
4	LE_Ext_Code	String	外部科室代码		需要索引
5	LE_Ext_Desc	String	外部科室描述		
6	LE_Active	Yes/No	可用标识		默认为可用

出院带药其他控制表 DHC_OutOrderOtherContral

实体类: User. DHCOutOrderOtherContral
存储globe: ^DHCOOOC(Rowid)
说明:主要控制出院带药指定的费别和子类的种类数，疗程
序号	列名	类型	描述	节点	备注
1	OOC_Rowid	Float			
2	OOC_ItemCat_DR		指向ARC_ItemCat		
3	OOC_AdmReason_DR		关联费别PAC_AdmReason		
4	OOC_ Dur_DR		关联疗程PHC_Duration		
5	OOC_ Drugspecies	String	品种数		

CA认证(数字证书认证)  DHC_DocSignVeify
实体类: User. DHCDocSignVeify
存储globe: ^DHCDSV(Rowid)
说明: CA认证(数字证书认证)
序号	列名	类型	描述	节点	备注
1	OOC_Rowid	Float			
2	OOC_ItemCat_DR		指向ARC_ItemCat		
3	OOC_AdmReason_DR		关联费别PAC_AdmReason		
4	OOC_ Dur_DR		关联疗程PHC_Duration		
5	OOC_ Drugspecies	String	品种数		

诊断状态
实体类:User. MRCDiagnosStatus
存储globe: ^MRC("DSTAT",{DSTAT_RowId})
说明: 诊断状态
序号	列名	类型	描述	节点	备注
1	DSTAT_Rowid	Float			
2	DSTAT_Code		状态代码		
3	DSTAT_Desc		状态描述		




图标 
实体类: epr.CTIconAssociation
存储globe: ^epr.CTIconAssociationD
序号	列名	类型	描述	备注
1	Code	String	代码	
2	Description	String	描述	
3	Icon	String	图标	
4	CondDescription	String	条件表达式描述	
5	CondExpr	String	Conditional Expression	可以通过s img=1决定是否显示图标， 
6	IsDirty	String		Y：是

图标组
实体类: epr.CTIconProfile
存储globe: ^ epr.CTIconProfileD
序号	列名	类型	描述	备注
1	Code	String	代码	
2	Description	String	描述	
3	CodeTableIcons	String	图标	

将类型为IconProfile的元素或列元素在界面编辑器里在Icon Profile里选上一个定义好的IconProfile记录， 
在组件生成中调用epr.CTIconProfile.show(cmpid，itemID，ProfileID，val)中，通过输出HTML语句例如<IMG align='top' SRC='../images//webemr/regalert.gif' title='正常'></TD>实现图标的展现。
TrakCare约定了一个ARY数组，在Icon的表达式属性里可以使用，这种方式是否新平台继续是用
图标组明细
实体类: epr.CTIconProfileItem
存储globe: ^epr.CTIconProfileD(ParRef,” Items”)
序号	列名	类型	描述	备注
0	ParRef			
1	IconDR	String	图标	
2	LinkItemDR	String		
3	Sequence	String	顺序号	
4	LinkComponent	String	关联组件	
5	LinkExpression	String	关联表达式	
6	LinkUrl	String	关联链接	
7	LinkNewWindow	String	新窗口	
8	LinkChartBookDR	String	关联图表	LinkUrl要定义为epr.Chart.csp

医嘱模板表
实体类: websys.Preferences
存储globe: ^websys.PreferencesD
序号	列名	类型	描述	备注
0	AppKey	String	类型	Eg:LAYOUT, COLUMNS, ORDER
1	AppSubKey	String	类型关联唯一标识	
2	Data	String	布局数据	
3	ObjectReference	String	保存类型关联唯一标识	Eg: DHCHealth
4	ObjectType	String	保存类型唯一标识	Eg: SITE

其他
表相关:
序号	表名	列名	类型	描述	备注
1			String		

Global相关:
序号	Global名	类型	描述	备注
1	$p($g(^TEMPPAADM(PaadmRowid)),"^",1)	String	VB版首诊标识	Y 首诊 其他
2	$p($g(^PAADM(PaadmRowid,"DHC")),"^",5)	String	VB版社区转诊标识	Y 社区转诊 其他
3	$g(^DHCDocInsuConfig("Emergency",AdmRowId))	String	VB 医保急诊标识	Y 医保急诊 其他
4				

标本来源代码表（复兴）
实体类: 
Terminal Table:DHC_SpecSource
存储globe: ^DHCSpS
序号	列名	类型	描述	备注
0	Sps_Code	String	代码	
1	Sps_Desc	String	描述	
2	Sps_StartDate	Date	开始日期	
3	Sps_EndDate	Date	结束日期	
4	Sps_Rowid	Numbir	主键	
图片：证件（类型代码、类型）

性别表

国籍表

民族表

邮编表

病人类型表

病人职业对照

婚姻对照

省份对照


城市对照

联系人关系对照

费别对照表

病房对照

病区对照

床位对照

科室对照

支付方式

银行对照

银行卡类型对照

收费项目分类

收费项目子分类

住院收费项目分类
住院收费项目子分类

收费项目门诊分类

收费项目门诊子分类

收费项目核算分类

收费项目核算子分类

收费项目病历首页分类

收费项目病历首页子分类

医嘱表(医嘱主表)

医嘱明细表

医嘱类型

药品服用频率

疗程

置皮试结果人

医嘱分类

医嘱子分类

医嘱项


病理pis3.DHCPIS_REPORT
DHCEMCUNSULTITM会诊子表
///急诊分诊信息表
SELECT * FROM DHC_EmPatCheckLev WHERE PCL_PAPMI_Dr='50104578'
SELECT * FROM PA_Adm WHERE PAADM_PAPMI_DR->PAPMI_No='0032104578'
SELECT * FROM PA_PatMas
SELECT * FROM DHC_EmPatChkSign WHERE PCS_Chk_Dr='34456' 
患者转移记录
Nur_Data.TransRecord



检验条码：Nur.dhcnurlisbarprintinfo
精准医学条码：User_pmed.barcodemag
华西入院证查询：DHC_MedIPBooking

查危急值报告时间：DHC_AntCVReport
生命体征数据表：MR_Observations

查病理报告：
进pis空间，查询pis3.dhcpis_test_master,有医嘱号
Pis3.DHCPIS_Report









