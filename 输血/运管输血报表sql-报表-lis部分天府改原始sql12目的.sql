SELECT XM,
                  SUM(T.RC) RC,
                  SUM(T.FY) FY,
                  SUM(T.GZL) GZL
                   FROM( SELECT  Distinct  
                 b.chinese_name_short XM,
                 count(a.inspection_id) RC,
                 sum(Nvl(b.charge, 0)) FY,
                 count(a.inspection_id) GZL
   FROM bis.lis_inspection_sample  a
   inner join bis.lis_inspection_sample_charge b
   on a.inspection_id=b.inspection_id
  where (@{C:INPUT_TIME:A.INPUT_TIME})  
    and a.group_id in ('G013')
    and B.sample_charge_id not like 'B%' and  B.sample_charge_id not like 'C%' 
   and a.INPUT_TIME<to_date('2025-04-22 00:00:00','yyyy-mm-dd hh24:mi:ss') 
  Group by b.chinese_name_short
  UNION ALL
  select
                  a.charge_item_name XM,
                  sum(charge_num) rc,
                  sum(a.charge) fy,
                  sum(charge_num) gzl
              from bis.bis_charged_list a
              inner join bis.bis_requisition_info b
              on a.requisition_id=b.requisition_id
             where (@{C:INPUT_TIME:A.INPUT_TIME})  
               and a.requisition_id like '99%'
               and a.charge_state in ('1','-1')
               and (a.inspection_id not like '*%' or a.inspection_id is null)
               and sample_charge_id like 'H%'
               and a.INPUT_TIME<to_date('2025-04-22 00:00:00','yyyy-mm-dd hh24:mi:ss') 
             group  by a.charge_item_name
  union all         
  select
                  a.CHARGE_ITEM_NAME XM,
                  count(A.CHARGED_ID) rc,
                  sum(a.charge) fy,
                  COUNT(A.CHARGED_ID) gzl
              from XH_BIS.bis6_charged_info a
             where  (@{C:AREA_ID:A.AREA_ID})
             and (@{C:INPUT_TIME:A.CHARGE_TIME})
               and a.charge_state in ('charged','uncharged')
               and a.CHARGED_TYPE='补费'
               and a.CHARGE_ITEM_NAME not in ('辐照单采血小板')
               and a.charge_time>to_date('2025-04-22 00:00:00','yyyy-mm-dd hh24:mi:ss') 
             group  by a.charge_item_name
  UNION ALL
  select
                  b.CHARGE_ITEM_NAME XM,
                  sum(b.CHARGE_NUM) rc,
                  sum(b.charge) fy,
                  COUNT(a.CHARGED_ID) gzl
              from XH_BIS.bis6_charged_info a
              inner join XH_COM.xinghe_charged_list b
              on a.sample_charge_id=b.sample_charge_id
             where  a.charge_state in ('charged','uncharged')
               And (@{C:AREA_ID:A.AREA_ID})
               and (@{C:INPUT_TIME:A.CHARGE_TIME})
               and a.sample_charge_id like 'H%'
               and a.charge_time>to_date('2025-04-22 00:00:00','yyyy-mm-dd hh24:mi:ss') 
             group  by b.charge_item_name
  union all
  SELECT  Distinct  
                 b.chinese_name_short XM,
                 count(a.inspection_id) RC,
                 sum(Nvl(c.charge, 0)) FY,
                 count(a.inspection_id) GZL
   FROM xh_data.lis6_inspect_sample  a
   inner join xh_data.lis6_inspect_charge b
   on a.inspection_id=b.inspection_id
   inner join XH_SYS.lis6_charge_item c
   on b.charge_item_id=c.charge_item_id
   where (@{C:AREA_ID:A.AREA_ID})
   and (@{C:INPUT_TIME:A.INPUT_TIME})
    and a.group_id in ('G013')    
    and a.INPUT_TIME>to_date('2025-04-22 00:00:00','yyyy-mm-dd hh24:mi:ss') 
  Group by b.chinese_name_short
  union all
  select Distinct
                 c.blood_type_name XM,
                 count(a.inspection_id) RC,
                 0 FY,
                 count(a.inspection_id) GZL
        from xh_data.lis6_inspect_sample a
        inner join xh_bis.bis6_req_info b
        on a.requisition_id=b.req_id
        inner join xh_bis.bis6_req_blood c
        on b.req_id=c.req_id
        where (@{C:AREA_ID:A.AREA_ID})
        and (@{C:INPUT_TIME:A.INPUT_TIME})
        and a.group_id in ('G013') 
        and a.INPUT_TIME>to_date('2025-04-22 00:00:00','yyyy-mm-dd hh24:mi:ss') 
         group by c.blood_type_name
  UNION ALL
   SELECT Distinct
                  E.METHOD_NAME XM,
                  COUNT(A.MATCH_ID) RC,
                  SUM(E.METHOD_CHARGE) FY,
                  COUNT(A.MATCH_ID) GZL
   FROM XH_BIS.BIS6_BLOODBAG_MATCH A
   INNER JOIN XH_BIS.BIS6_BLOODBAG_INPUT D
   ON A.BLOODBAG_ID=D.BLOODBAG_ID
   INNER JOIN XH_BIS.BIS6_MATCH_BLOOD_TYPE B
   ON d.BLOOD_TYPE_ID=B.BLOOD_TYPE_ID
   inner join XH_BIS.Lis6_Inspect_Sample c
   on a.inspection_id=c.inspection_id
   INNER JOIN XH_BIS.BIS6_MATCH_METHOD E
   ON A.METHOD_TYPE_ID=E.METHOD_ID
   WHERE (@{C:AREA_ID:D.AREA_ID})
   and (@{C:INPUT_TIME:A.MACTH_DATE})
    AND e.method_id not in ('00000004','9','8','4')
    and a.macth_date>to_date('2025-04-22 00:00:00','yyyy-mm-dd hh24:mi:ss') 
    GROUP BY E.METHOD_NAME
   
   )T group by xm