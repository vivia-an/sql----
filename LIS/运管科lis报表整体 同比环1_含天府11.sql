-- 运管科LIS报表整体（含天府医院独立数据）
-- 添加了天府医院独立统计（hid0117数据源）

WITH date_ranges AS (

    -- 获取动态日期范围

   SELECT 

        -- 当月日期范围

         -- 当月（实际是上个月）日期范围

        REPLACE(CAST(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH) AS VARCHAR), '-', '') as current_month_start,

        REPLACE(CAST(LAST_DAY_OF_MONTH(CURRENT_DATE - INTERVAL '1' MONTH) AS VARCHAR), '-', '') as current_month_end,

        -- 上月（实际是上上个月）日期范围

        REPLACE(CAST(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '2' MONTH) AS VARCHAR), '-', '') as last_month_start,

        REPLACE(CAST(LAST_DAY_OF_MONTH(CURRENT_DATE - INTERVAL '2' MONTH) AS VARCHAR), '-', '') as last_month_end,

        -- 去年同期（实际是去年同期的上个月）日期范围

        REPLACE(CAST(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' YEAR - INTERVAL '1' MONTH) AS VARCHAR), '-', '') as last_year_start,

        REPLACE(CAST(LAST_DAY_OF_MONTH(CURRENT_DATE - INTERVAL '1' YEAR - INTERVAL '1' MONTH) AS VARCHAR), '-', '') as last_year_end



),

correct_workload AS (

    -- 当月数据

    SELECT 

        t."GROUP_ID" as "亚专业组代码",

        COUNT(DISTINCT t."inspection_id") as "标本数",

        SUM(COALESCE(CAST(b."workload" AS DOUBLE), 0)) as "工作量"

    FROM hid0101_orcl_lis_dbo.lis_inspection_sample t

    INNER JOIN hid0101_orcl_lis_dbo.lis_inspection_sample_charge b

        ON t."inspection_id" = b."inspection_id"

        AND b."isdeleted" = '0'

    CROSS JOIN date_ranges d

    WHERE t."inspection_date" BETWEEN d.current_month_start AND d.current_month_end

        AND t."isdeleted" = '0'

    GROUP BY t."GROUP_ID"

),

correct_workload_last_month AS (

    -- 上月数据

    SELECT 

        t."GROUP_ID" as "亚专业组代码",

        COUNT(DISTINCT t."inspection_id") as "上月标本数",

        SUM(COALESCE(CAST(b."workload" AS DOUBLE), 0)) as "上月工作量"

    FROM hid0101_orcl_lis_dbo.lis_inspection_sample t

    INNER JOIN hid0101_orcl_lis_dbo.lis_inspection_sample_charge b

        ON t."inspection_id" = b."inspection_id"

        AND b."isdeleted" = '0'

    CROSS JOIN date_ranges d

    WHERE t."inspection_date" BETWEEN d.last_month_start AND d.last_month_end

        AND t."isdeleted" = '0'

    GROUP BY t."GROUP_ID"

),

correct_workload_last_year AS (

    -- 去年同期数据

    SELECT 

        t."GROUP_ID" as "亚专业组代码",

        COUNT(DISTINCT t."inspection_id") as "去年同期标本数",

        SUM(COALESCE(CAST(b."workload" AS DOUBLE), 0)) as "去年同期工作量"

    FROM hid0101_orcl_lis_dbo.lis_inspection_sample t

    INNER JOIN hid0101_orcl_lis_dbo.lis_inspection_sample_charge b

        ON t."inspection_id" = b."inspection_id"

        AND b."isdeleted" = '0'

    CROSS JOIN date_ranges d

    WHERE t."inspection_date" BETWEEN d.last_year_start AND d.last_year_end

        AND t."isdeleted" = '0'

    GROUP BY t."GROUP_ID"

),

income_data AS (

    -- 当月收入

    SELECT 

        A."GROUP_ID" as "亚专业组代码",

        SUM(COALESCE(CAST(A."SAMPLE_CHARGE" AS DOUBLE), 0)) as "总收入"

    FROM hid0101_orcl_lis_dbo.lis_inspection_sample A

    CROSS JOIN date_ranges d

    WHERE A."inspection_date" BETWEEN d.current_month_start AND d.current_month_end

        AND A."isdeleted" = '0'

        AND A."CHECK_TIME" IS NOT NULL

    GROUP BY A."GROUP_ID"

),

income_data_last_month AS (

    -- 上月收入

    SELECT 

        A."GROUP_ID" as "亚专业组代码",

        SUM(COALESCE(CAST(A."SAMPLE_CHARGE" AS DOUBLE), 0)) as "上月总收入"

    FROM hid0101_orcl_lis_dbo.lis_inspection_sample A

    CROSS JOIN date_ranges d

    WHERE A."inspection_date" BETWEEN d.last_month_start AND d.last_month_end

        AND A."isdeleted" = '0'

        AND A."CHECK_TIME" IS NOT NULL

    GROUP BY A."GROUP_ID"

),

income_data_last_year AS (

    -- 去年同期收入

    SELECT 

        A."GROUP_ID" as "亚专业组代码",

        SUM(COALESCE(CAST(A."SAMPLE_CHARGE" AS DOUBLE), 0)) as "去年同期总收入"

    FROM hid0101_orcl_lis_dbo.lis_inspection_sample A

    CROSS JOIN date_ranges d

    WHERE A."inspection_date" BETWEEN d.last_year_start AND d.last_year_end

        AND A."isdeleted" = '0'

        AND A."CHECK_TIME" IS NOT NULL

    GROUP BY A."GROUP_ID"

),

-- ===== 天府医院独立数据查询 (hid0117) =====

tianfu_data AS (

    -- 天府医院当月数据

    SELECT 

        COUNT(DISTINCT T."inspection_id") as "标本数",

        count(b.inspection_id) as "工作量",

        SUM(COALESCE(CAST(B."item_charge" AS DOUBLE), 0)) as "收费金额"

    FROM hid0117_orcl_lis_dbo.lis_inspection_sample T

    INNER JOIN hid0117_orcl_lis_xhdata.lis6_inspect_charge B

        ON T."inspection_id" = B."inspection_id"

        AND B."isdeleted" = '0'

    CROSS JOIN date_ranges d

    WHERE T."inspection_date" BETWEEN d.current_month_start AND d.current_month_end

        AND T."GROUP_ID" <> 'G050'

        AND T."isdeleted" = '0'

        AND NOT EXISTS (

            SELECT 1

            FROM hid0117_orcl_lis_dbo.lis_requisition_item Q

            WHERE Q."requisition_id" = T."requisition_id"

                AND Q."charge_item_id" IN ('LIS0301', 'LIS027534', 'LIS024805',

                    'LIS01566', 'LIS01414', 'LIS027420')

                AND Q."isdeleted" = '0'

        )
        and T.GROUP_ID IN ('G003','G004','G006','G009','G010','G011','G014','G017','G022','G068' ,'G999')

),

tianfu_data_last_month AS (

    -- 天府医院上月数据

    SELECT 

        COUNT(DISTINCT T."inspection_id") as "上月标本数",

        count(b.inspection_id) as "上月工作量",

        SUM(COALESCE(CAST(B."item_charge" AS DOUBLE), 0)) as "上月收费金额"

    FROM hid0117_orcl_lis_dbo.lis_inspection_sample T

    INNER JOIN hid0117_orcl_lis_xhdata.lis6_inspect_charge B

        ON T."inspection_id" = B."inspection_id"

        AND B."isdeleted" = '0'

    CROSS JOIN date_ranges d

    WHERE T."inspection_date" BETWEEN d.last_month_start AND d.last_month_end

        AND T."GROUP_ID" <> 'G050'

        AND T."isdeleted" = '0'

        AND NOT EXISTS (

            SELECT 1

            FROM hid0117_orcl_lis_dbo.lis_requisition_item Q

            WHERE Q."requisition_id" = T."requisition_id"

                AND Q."charge_item_id" IN ('LIS0301', 'LIS027534', 'LIS024805',

                    'LIS01566', 'LIS01414', 'LIS027420')

                AND Q."isdeleted" = '0'

        )
        and T.GROUP_ID IN ('G003','G004','G006','G009','G010','G011','G014','G017','G022','G068' ,'G999')

),

tianfu_data_last_year AS (

    -- 天府医院去年同期数据

    SELECT 

        COUNT(DISTINCT T."inspection_id") as "去年同期标本数",

        count(b.inspection_id) as "去年同期工作量",

        SUM(COALESCE(CAST(B."item_charge" AS DOUBLE), 0)) as "去年同期收费金额"

    FROM hid0117_orcl_lis_dbo.lis_inspection_sample T

    INNER JOIN hid0117_orcl_lis_xhdata.lis6_inspect_charge B

        ON T."inspection_id" = B."inspection_id"

        AND B."isdeleted" = '0'

    CROSS JOIN date_ranges d

    WHERE T."inspection_date" BETWEEN d.last_year_start AND d.last_year_end

        AND T."GROUP_ID" <> 'G050'

        AND T."isdeleted" = '0'

        AND NOT EXISTS (

            SELECT 1

            FROM hid0117_orcl_lis_dbo.lis_requisition_item Q

            WHERE Q."requisition_id" = T."requisition_id"

                AND Q."charge_item_id" IN ('LIS0301', 'LIS027534', 'LIS024805',

                    'LIS01566', 'LIS01414', 'LIS027420')

                AND Q."isdeleted" = '0'

        )
        and T.GROUP_ID IN ('G003','G004','G006','G009','G010','G011','G014','G017','G022','G068' ,'G999')

),

group_level AS (

    SELECT 

        cw."亚专业组代码",

        CASE 

            WHEN cw."亚专业组代码" IN ('G003', 'G001') THEN '临床免疫实验室'

            WHEN cw."亚专业组代码" IN ('G021', 'G017', 'G007') THEN '临床生化实验室'

            WHEN cw."亚专业组代码" IN ('G999', 'G998', 'G014', 'G022') THEN '临床微生物实验室'

            WHEN cw."亚专业组代码" IN ('G044', 'G009', 'G062') THEN '临床分子诊断实验室'

            WHEN cw."亚专业组代码" IN ('G002', 'G025', 'G006', 'G004', 'G076') THEN '临检与血液实验室'

            WHEN cw."亚专业组代码" IN ('G049', 'G051', 'G050', 'G054', 'G065') THEN '温江院区'

            WHEN cw."亚专业组代码" IN ('G011', 'G010', 'G072') THEN '急诊应急组'

            WHEN cw."亚专业组代码" IN ('G112', 'G113') THEN '天府院区'

            WHEN cw."亚专业组代码" IN ('G115', 'G116', 'G077', 'G104', 'G101', 'G103', 'G102') THEN '锦江院区'

            ELSE '其他'

        END as "亚专业组",

        -- 当月数据

        cw."标本数",

        cw."工作量" as "项目数",

        COALESCE(i."总收入", 0) as "总收入",

        -- 上月数据

        COALESCE(lm."上月标本数", 0) as "上月标本数",

        COALESCE(lm."上月工作量", 0) as "上月项目数",

        COALESCE(ilm."上月总收入", 0) as "上月总收入",

        -- 去年同期数据

        COALESCE(ly."去年同期标本数", 0) as "去年同期标本数",

        COALESCE(ly."去年同期工作量", 0) as "去年同期项目数",

        COALESCE(ily."去年同期总收入", 0) as "去年同期总收入"

    FROM correct_workload cw

    LEFT JOIN income_data i ON cw."亚专业组代码" = i."亚专业组代码"

    LEFT JOIN correct_workload_last_month lm ON cw."亚专业组代码" = lm."亚专业组代码"

    LEFT JOIN income_data_last_month ilm ON cw."亚专业组代码" = ilm."亚专业组代码"

    LEFT JOIN correct_workload_last_year ly ON cw."亚专业组代码" = ly."亚专业组代码"

    LEFT JOIN income_data_last_year ily ON cw."亚专业组代码" = ily."亚专业组代码"

),

final_summary AS (

    SELECT 

        "亚专业组",

        SUM("标本数") as "标本数",

        SUM("项目数") as "项目数",

        ROUND(SUM("总收入"), 2) as "总收入",

        SUM("上月标本数") as "上月标本数",

        SUM("上月项目数") as "上月项目数",

        ROUND(SUM("上月总收入"), 2) as "上月总收入",

        SUM("去年同期标本数") as "去年同期标本数",

        SUM("去年同期项目数") as "去年同期项目数",

        ROUND(SUM("去年同期总收入"), 2) as "去年同期总收入"

    FROM group_level

    WHERE "亚专业组" != '其他'

    GROUP BY "亚专业组"

),

summary_with_totals AS (

    -- 原始科室数据

    SELECT 

        CAST(YEAR(CURRENT_DATE - INTERVAL '1' MONTH) AS VARCHAR) || '年-' || 

        LPAD(CAST(MONTH(CURRENT_DATE - INTERVAL '1' MONTH) AS VARCHAR), 2, '0') || '月' as "统计月份",

        '实验医学科(检验科)' as "运管科室",

        CASE 

            WHEN "亚专业组" IN ('温江院区') THEN '温江院区'

            WHEN "亚专业组" IN ('天府院区') THEN '天府院区'

            WHEN "亚专业组" IN ('锦江院区') THEN '锦江院区'

            ELSE '主院区'

        END as "运管院区",

        "亚专业组",

        "标本数",

        "项目数",

        "总收入",

        "上月标本数",

        "上月项目数",

        "上月总收入",

        "去年同期标本数",

        "去年同期项目数",

        "去年同期总收入",

        -- 收入占比

        CASE 

            WHEN (SELECT SUM("总收入") FROM final_summary) = 0 THEN 0

            ELSE ROUND("总收入" * 100.0 / (SELECT SUM("总收入") FROM final_summary), 2)

        END as "总收入占比%",

        CASE 

            WHEN (SELECT SUM("上月总收入") FROM final_summary) = 0 THEN 0

            ELSE ROUND("上月总收入" * 100.0 / (SELECT SUM("上月总收入") FROM final_summary), 2)

        END as "上月总收入占比%",

        CASE 

            WHEN (SELECT SUM("去年同期总收入") FROM final_summary) = 0 THEN 0

            ELSE ROUND("去年同期总收入" * 100.0 / (SELECT SUM("去年同期总收入") FROM final_summary), 2)

        END as "去年同期总收入占比%",

        -- 环比增长率

        CAST(ROUND(("标本数" - "上月标本数") * 100.0 / NULLIF("上月标本数", 0), 2) AS DECIMAL(10,2)) as "标本数环比增长率%",

        CAST(ROUND(("项目数" - "上月项目数") * 100.0 / NULLIF("上月项目数", 0), 2) AS DECIMAL(10,2)) as "项目数环比增长率%",

        CAST(ROUND(("总收入" - "上月总收入") * 100.0 / NULLIF("上月总收入", 0), 2) AS DECIMAL(10,2)) as "收入环比增长率%",

        -- 同比增长率

        CAST(ROUND(("标本数" - "去年同期标本数") * 100.0 / NULLIF("去年同期标本数", 0), 2) AS DECIMAL(10,2)) as "标本数同比增长率%",

        CAST(ROUND(("项目数" - "去年同期项目数") * 100.0 / NULLIF("去年同期项目数", 0), 2) AS DECIMAL(10,2)) as "项目数同比增长率%",

        CAST(ROUND(("总收入" - "去年同期总收入") * 100.0 / NULLIF("去年同期总收入", 0), 2) AS DECIMAL(10,2)) as "收入同比增长率%"

    FROM final_summary

    

    UNION ALL

    

    -- 合计行

    SELECT 

        CAST(YEAR(CURRENT_DATE - INTERVAL '1' MONTH) AS VARCHAR) || '年-' || 

        LPAD(CAST(MONTH(CURRENT_DATE - INTERVAL '1' MONTH) AS VARCHAR), 2, '0') || '月' as "统计月",

        '实验医学科(检验科)' as "运管科室",

        '合计' as "运管院区",

        '合计' as "亚专业组",

        SUM("标本数") as "标本数",

        SUM("项目数") as "项目数",

        ROUND(SUM("总收入"), 2) as "总收入",

        SUM("上月标本数") as "上月标本数",

        SUM("上月项目数") as "上月项目数",

        ROUND(SUM("上月总收入"), 2) as "上月总收入",

        SUM("去年同期标本数") as "去年同期标本数",

        SUM("去年同期项目数") as "去年同期项目数",

        ROUND(SUM("去年同期总收入"), 2) as "去年同期总收入",

        -- 合计行的环比增长率

        CAST(ROUND((SUM("标本数") - SUM("上月标本数")) * 100.0 / NULLIF(SUM("上月标本数"), 0), 2) AS DECIMAL(10,2)),

        CAST(ROUND((SUM("项目数") - SUM("上月项目数")) * 100.0 / NULLIF(SUM("上月项目数"), 0), 2) AS DECIMAL(10,2)),

        CAST(ROUND((SUM("总收入") - SUM("上月总收入")) * 100.0 / NULLIF(SUM("上月总收入"), 0), 2) AS DECIMAL(10,2)),

        -- 合计行的同比增长率

        CAST(ROUND((SUM("标本数") - SUM("去年同期标本数")) * 100.0 / NULLIF(SUM("去年同期标本数"), 0), 2) AS DECIMAL(10,2)),

        CAST(ROUND((SUM("项目数") - SUM("去年同期项目数")) * 100.0 / NULLIF(SUM("去年同期项目数"), 0), 2) AS DECIMAL(10,2)),

        CAST(ROUND((SUM("总收入") - SUM("去年同期总收入")) * 100.0 / NULLIF(SUM("去年同期总收入"), 0), 2) AS DECIMAL(10,2)),

        -- 合计行收入占比（都是100%）

        100.00 as "总收入占比%",

        100.00 as "上月总收入占比%",

        100.00 as "去年同期总收入占比%"

    FROM final_summary

    

    UNION ALL

    

    -- 本部实际量（排除天府院区）

    SELECT 

        CAST(YEAR(CURRENT_DATE - INTERVAL '1' MONTH) AS VARCHAR) || '年-' || 

        LPAD(CAST(MONTH(CURRENT_DATE - INTERVAL '1' MONTH) AS VARCHAR), 2, '0') || '月' as "统计月",

        '实验医学科(检验科)' as "运管科室",

        '本部实际量' as "运管院区",

        '本部实际量' as "亚专业组",

        SUM("标本数") as "标本数",

        SUM("项目数") as "项目数",

        ROUND(SUM("总收入"), 2) as "总收入",

        SUM("上月标本数") as "上月标本数",

        SUM("上月项目数") as "上月项目数",

        ROUND(SUM("上月总收入"), 2) as "上月总收入",

        SUM("去年同期标本数") as "去年同期标本数",

        SUM("去年同期项目数") as "去年同期项目数",

        ROUND(SUM("去年同期总收入"), 2) as "去年同期总收入",

        -- 本部实际量的环比增长率

        CAST(ROUND((SUM("标本数") - SUM("上月标本数")) * 100.0 / NULLIF(SUM("上月标本数"), 0), 2) AS DECIMAL(10,2)),

        CAST(ROUND((SUM("项目数") - SUM("上月项目数")) * 100.0 / NULLIF(SUM("上月项目数"), 0), 2) AS DECIMAL(10,2)),

        CAST(ROUND((SUM("总收入") - SUM("上月总收入")) * 100.0 / NULLIF(SUM("上月总收入"), 0), 2) AS DECIMAL(10,2)),

        -- 本部实际量的同比增长率

        CAST(ROUND((SUM("标本数") - SUM("去年同期标本数")) * 100.0 / NULLIF(SUM("去年同期标本数"), 0), 2) AS DECIMAL(10,2)),

        CAST(ROUND((SUM("项目数") - SUM("去年同期项目数")) * 100.0 / NULLIF(SUM("去年同期项目数"), 0), 2) AS DECIMAL(10,2)),

        CAST(ROUND((SUM("总收入") - SUM("去年同期总收入")) * 100.0 / NULLIF(SUM("去年同期总收入"), 0), 2) AS DECIMAL(10,2)),

        -- 本部实际量收入占比

        CASE 

            WHEN (SELECT SUM("总收入") FROM final_summary) = 0 THEN 0

            ELSE ROUND(SUM("总收入") * 100.0 / (SELECT SUM("总收入") FROM final_summary), 2)

        END as "总收入占比%",

        CASE 

            WHEN (SELECT SUM("上月总收入") FROM final_summary) = 0 THEN 0

            ELSE ROUND(SUM("上月总收入") * 100.0 / (SELECT SUM("上月总收入") FROM final_summary), 2)

        END as "上月总收入占比%",

        CASE 

            WHEN (SELECT SUM("去年同期总收入") FROM final_summary) = 0 THEN 0

            ELSE ROUND(SUM("去年同期总收入") * 100.0 / (SELECT SUM("去年同期总收入") FROM final_summary), 2)

        END as "去年同期总收入占比%"

    FROM final_summary

    WHERE "亚专业组" != '天府院区'

    

    UNION ALL

    

    -- ===== 天府医院独立统计行 (hid0117数据源) =====

    SELECT 

        CAST(YEAR(CURRENT_DATE - INTERVAL '1' MONTH) AS VARCHAR) || '年-' || 

        LPAD(CAST(MONTH(CURRENT_DATE - INTERVAL '1' MONTH) AS VARCHAR), 2, '0') || '月' as "统计月",

        '实验医学科(检验科)' as "运管科室",

        '天府医院' as "运管院区",

        '天府医院' as "亚专业组",

        -- 当月数据

        COALESCE(tf."标本数", 0) as "标本数",

        COALESCE(tf."工作量", 0) as "项目数",

        COALESCE(tf."收费金额", 0) as "总收入",

        -- 上月数据

        COALESCE(tflm."上月标本数", 0) as "上月标本数",

        COALESCE(tflm."上月工作量", 0) as "上月项目数",

        COALESCE(tflm."上月收费金额", 0) as "上月总收入",

        -- 去年同期数据

        COALESCE(tfly."去年同期标本数", 0) as "去年同期标本数",

        COALESCE(tfly."去年同期工作量", 0) as "去年同期项目数",

        COALESCE(tfly."去年同期收费金额", 0) as "去年同期总收入",

        -- 天府医院环比增长率

        CAST(ROUND((COALESCE(tf."标本数", 0) - COALESCE(tflm."上月标本数", 0)) * 100.0 / 

            NULLIF(COALESCE(tflm."上月标本数", 0), 0), 2) AS DECIMAL(10,2)) as "标本数环比增长率%",

        CAST(ROUND((COALESCE(tf."工作量", 0) - COALESCE(tflm."上月工作量", 0)) * 100.0 / 

            NULLIF(COALESCE(tflm."上月工作量", 0), 0), 2) AS DECIMAL(10,2)) as "项目数环比增长率%",

        CAST(ROUND((COALESCE(tf."收费金额", 0) - COALESCE(tflm."上月收费金额", 0)) * 100.0 / 

            NULLIF(COALESCE(tflm."上月收费金额", 0), 0), 2) AS DECIMAL(10,2)) as "收入环比增长率%",

        -- 天府医院同比增长率

        CAST(ROUND((COALESCE(tf."标本数", 0) - COALESCE(tfly."去年同期标本数", 0)) * 100.0 / 

            NULLIF(COALESCE(tfly."去年同期标本数", 0), 0), 2) AS DECIMAL(10,2)) as "标本数同比增长率%",

        CAST(ROUND((COALESCE(tf."工作量", 0) - COALESCE(tfly."去年同期工作量", 0)) * 100.0 / 

            NULLIF(COALESCE(tfly."去年同期工作量", 0), 0), 2) AS DECIMAL(10,2)) as "项目数同比增长率%",

        CAST(ROUND((COALESCE(tf."收费金额", 0) - COALESCE(tfly."去年同期收费金额", 0)) * 100.0 / 

            NULLIF(COALESCE(tfly."去年同期收费金额", 0), 0), 2) AS DECIMAL(10,2)) as "收入同比增长率%",

        -- 天府医院收入占比（注：由于数据源不同，暂时设为NULL或0）

        0.00 as "总收入占比%",

        0.00 as "上月总收入占比%",

        0.00 as "去年同期总收入占比%"

    FROM tianfu_data tf

    CROSS JOIN tianfu_data_last_month tflm

    CROSS JOIN tianfu_data_last_year tfly

)

-- 最终结果

SELECT *

FROM summary_with_totals

ORDER BY 

    CASE 

        WHEN "亚专业组" = '合计' THEN 1

        WHEN "亚专业组" = '本部实际量' THEN 2

        WHEN "亚专业组" = '天府医院' THEN 3

        ELSE 4

    END,

    "标本数" DESC;

