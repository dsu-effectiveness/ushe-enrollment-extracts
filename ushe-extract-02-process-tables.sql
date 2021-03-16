/*
--DROP   TABLE extract_parameters;
  CREATE TABLE extract_parameters
  (
    p_dsc_term_code VARCHAR2(6),
    p_banner_term   NUMBER(6),
    p_acyr          VARCHAR2(4),
    p_year          NUMBER(4),
    p_term          VARCHAR2(1),
    p_extract       VARCHAR2(1)
  );
  
  INSERT INTO extract_parameters VALUES ('202123','202120','2021','2021','3','3');
*/

select *
   from extract_parameters;

 ------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------

 TRUNCATE TABLE students_current;

 INSERT INTO students_current
 SELECT      DISTINCT
             s_pidm,
             s_banner_id,
             s_banner_term,
             s_banner_extract,
             s_inst,
             s_year,
             s_term,
             s_extract,
             s_id,
             s_id_flag,
             s_prev_id,
             s_last_name,
             s_first_name,
             s_middle_name,
             s_suffix,
             s_prev_last,
             s_prev_first,
             s_prev_middle,
             s_prev_suffix,
             s_cur_zip_code,
             s_county_origin,
             s_state_origin,
             CASE WHEN s_state_origin = 'UT' THEN 'US' ELSE s_country_origin END AS s_country_origin,
             s_birth_dt,
             s_age,
             s_gender,
             replace(s_citz_code,6,9),
             s_ethnic,
             s_ethnic_h,
             s_ethnic_a,
             s_ethnic_b,
             s_ethnic_i,
             s_ethnic_p,
             s_ethnic_w,
             s_ethnic_n,
             s_ethnic_u,
             s_regent_res,
             s_religion,
             s_marital_status,
             s_entry_action,
             s_styp,
             s_level,
             s_deg_intent,
             s_cur_cip1,
             s_cur_cip_ushe,
             s_cur_cip2,
             s_cur_prgm1,
             s_cur_prgm2,
             s_cur_degc1,
             s_cur_degc2,
             s_cur_majr1,
             s_cur_majr2,
             s_majr_desc1 AS s_major_desc1,
             s_majr_desc2 AS s_major_desc2,
             s_cur_minr1  AS s_cur_minor1,
             s_cur_minr2  AS s_cur_minor2,
             s_cur_conc1,
             s_cur_conc2,
             s_cur_coll_code1,
             s_cur_coll_code2,
             nvl(s_cum_hrs_ugrad,0),
             nvl(s_cum_gpa_ugrad,0),
             s_term_gpa,
             nvl(s_cum_hrs_grad,0),
             nvl(s_cum_gpa_grad,0),
             s_trans_total,
             s_pt_ft,
             s_high_school,
             s_hsgrad_dt,
             s_hsgpa,
             s_ssid,
             s_hb75_waiver,
             s_cum_mem_hrs,
             s_total_clep AS s_tot_clep,
             s_total_ap,
             s_act_comp,
             s_act_math,
             s_act_engl,
             s_act_read,
             s_act_sci,
             s_pell,
             s_bia,
             s_rate,
             s_cohort_block,
             s_term_att_cr,
             s_term_earned_cr,
             s_confid_ind,
             s_visatype,
             s_sport,
             s_ada,
             s_xtrct_mltplr
 FROM   ( /**/
          WITH students AS
          (
            SELECT DISTINCT
                   (SELECT DISTINCT p_dsc_term_code FROM extract_parameters)                       AS s_banner_extract,
                   (SELECT DISTINCT p_banner_term FROM extract_parameters)                       AS s_banner_term,
                   (SELECT DISTINCT p_acyr FROM extract_parameters)                       AS s_acyr,
                   (SELECT DISTINCT p_year FROM extract_parameters)                       AS s_year,
                   (SELECT DISTINCT p_term FROM extract_parameters)                       AS s_term,
                   (SELECT DISTINCT p_extract FROM extract_parameters)                       AS s_extract,
                   spriden_pidm                    AS s_pidm,
                   'D' || spriden_id               AS s_banner_id,
                   substr(spriden_last_name ,1,60) AS s_last_name,
                   substr(spriden_first_name,1,15) AS s_first_name,
                   substr(spriden_mi,        1,15) AS s_middle_name,


                   CASE WHEN (SELECT DISTINCT p_extract FROM extract_parameters) = '3' THEN 0 ELSE 1 END
                                                   AS s_xtrct_mltplr, -- Zeros data points during 3rd week
                          COALESCE(spbpers_citz_code, rcrapp1_citz_ind)  AS s_citz_code,
                   (  -- from SABSUPL
                     SELECT ROWID
                     FROM   sabsupl s1
                     WHERE  s1.sabsupl_pidm = spriden_pidm
                     AND    s1.sabsupl_natn_code_admit IS NOT NULL
                     AND    s1.sabsupl_appl_no||s1.sabsupl_term_code_entry =
                            (
                              SELECT MIN(s2.sabsupl_appl_no||s2.sabsupl_term_code_entry)
                              FROM   sabsupl s2
                              WHERE  s2.sabsupl_pidm = s1.sabsupl_pidm
                              AND    s2.sabsupl_natn_code_admit IS NOT NULL
                           )
                   ) AS sabsupl_rowid,
                   nvl(
                        (     -- Check for Permanent Address
                          SELECT ROWID
                          FROM   spraddr s1
                          WHERE  s1.spraddr_pidm = spriden_pidm
                          AND    s1.spraddr_atyp_code = '00'
                          AND    s1.spraddr_natn_code IS NOT NULL
                          AND    s1.spraddr_seqno =
                                 (     -- Find largest sequence number
                                   SELECT MAX(s2.spraddr_seqno)
                                   FROM   spraddr s2
                                   WHERE  s2.spraddr_pidm = s1.spraddr_pidm
                                   AND    s2.spraddr_atyp_code = '00'
                                   AND    s2.spraddr_natn_code IS NOT NULL
                                 )
                        ),nvl(
                        (     -- Check for usable Address with Country Code
                          SELECT ROWID
                          FROM   spraddr s1
                          WHERE  s1.spraddr_pidm = spriden_pidm
                          AND    s1.spraddr_natn_code IS NOT NULL
                          AND    s1.spraddr_atyp_code =
                                 (     -- Find the lowest ATYP Code
                                   SELECT MIN(s2.spraddr_atyp_code)
                                   FROM   spraddr s2
                                   WHERE  s2.spraddr_pidm = s1.spraddr_pidm
                                   AND    s2.spraddr_natn_code IS NOT NULL
                                 )
                          AND    s1.spraddr_seqno =
                                 (     -- Find the largest sequence number
                                   SELECT MAX(s2.spraddr_seqno)
                                   FROM   spraddr s2
                                   WHERE  s2.spraddr_pidm = s1.spraddr_pidm
                                   AND    s2.spraddr_natn_code IS NOT NULL
                                   AND    s2.spraddr_atyp_code =
                                          (     -- Find the lowest ATYP code
                                            SELECT MIN(s3.spraddr_atyp_code)
                                            FROM   spraddr s3
                                            WHERE  s3.spraddr_pidm = s2.spraddr_pidm
                                            AND    s3.spraddr_natn_code IS NOT NULL
                                          )
                                  )
                        ),(   -- Check for usable address with State Code
                          SELECT ROWID
                          FROM   spraddr s1
                          WHERE  s1.spraddr_pidm = spriden_pidm
                          AND    s1.spraddr_stat_code IS NOT NULL
                          AND    s1.spraddr_atyp_code =
                                 (     -- Find lowest ATYP Code
                                   SELECT MIN(s2.spraddr_atyp_code)
                                   FROM   spraddr s2
                                   WHERE  s2.spraddr_pidm = s1.spraddr_pidm
                                   AND    s2.spraddr_stat_code IS NOT NULL
                                 )
                          AND    s1.spraddr_seqno =
                                 (     -- Find largest sequence number
                                   SELECT MAX(s2.spraddr_seqno)
                                   FROM   spraddr s2
                                   WHERE  s2.spraddr_pidm = s1.spraddr_pidm
                                   AND    s2.spraddr_stat_code IS NOT NULL
                                   AND    s2.spraddr_atyp_code =
                                          (     -- Find smallest ATYP Code
                                            SELECT MIN(s3.spraddr_atyp_code)
                                            FROM   spraddr s3
                                            WHERE  s3.spraddr_pidm = s2.spraddr_pidm
                                            AND    s2.spraddr_stat_code IS NOT NULL
                                          )
                                )
                        ))) AS spraddr_rowid

            FROM   spriden a
            INNER JOIN sfrstcr b ON b.sfrstcr_pidm = a.spriden_pidm
            INNER JOIN spbpers c ON c.spbpers_pidm = b.sfrstcr_pidm
            LEFT JOIN stvrsts d ON d.stvrsts_code = b.sfrstcr_rsts_code
            LEFT JOIN rcrapp1 e ON e.rcrapp1_pidm = a.spriden_pidm
            WHERE  sfrstcr_term_code      = (SELECT DISTINCT p_banner_term FROM extract_parameters) -- Join Term Codes
            AND    sfrstcr_rsts_code      = stvrsts_code  -- Valid Registrations
            AND    spriden_entity_ind     = 'P'           -- Valid Students
            AND    stvrsts_incl_sect_enrl = 'Y'           -- Valid Enrollments
            AND    sfrstcr_camp_code     <> 'XXX'         -- Invalid Enrollments
            AND    spriden_change_ind    IS NULL          -- Valid Students
            AND    (
                     SELECT upper(title)
                     FROM   as_catalog_schedule
                     WHERE  sfrstcr_crn = crn_key
                     AND    term_code_key = (SELECT DISTINCT p_banner_term FROM extract_parameters)
                     AND    ssts_code = 'A'
                   ) NOT LIKE '%LITERACY EXAM%'
          ) /**/
          SELECT '3671' AS s_inst,
                 students.s_year,
                 students.s_term,
                 students.s_extract,
                 -------------------------
                 students.s_pidm,
                 students.s_banner_id,
                 pers.s_id,
                 CASE WHEN pers.s_id LIKE 'D%' THEN 'I' ELSE 'S' END AS s_id_flag,
                 -------------------------
                 students.s_first_name,
                 students.s_last_name,
                 students.s_middle_name,
                 pers.s_suffix,
                 -------------------------
                 hlog.s_prev_id,
                 prev.s_prev_last,
                 prev.s_prev_first,
                 prev.s_prev_middle,
                 CAST (NULL AS VARCHAR2(1)) AS s_prev_suffix, -- We don't track previous suffix
                 -------------------------
                 addr.s_county_origin,
                 addr.s_state_origin,
                 addr.s_country_origin,
                 CASE WHEN LENGTH(addr.s_cur_zip_code) <> 10 THEN substr(addr.s_cur_zip_code,1,5)
                      ELSE addr.s_cur_zip_code
                      END AS s_cur_zip_code,
                 -------------------------
                 pers.s_birth_dt,
                 pers.s_age,
                 pers.s_gender,
                 students.s_citz_code,
                 pers.s_ethnic,
                 CASE WHEN pers.s_ethnic = 'H'                THEN 'H'
                      WHEN pers.s_ethnic = '2'
                       AND instr(pers.all_race_codes,'H') > 0 THEN 'H'
                       END AS s_ethnic_h,
                 CASE WHEN pers.s_ethnic = 'A'                THEN 'A'
                      WHEN pers.s_ethnic = '2'
                       AND instr(pers.all_race_codes,'A') > 0 THEN 'A'
                       END AS s_ethnic_a,
                 CASE WHEN pers.s_ethnic = 'B'                THEN 'B'
                      WHEN pers.s_ethnic = '2'
                       AND instr(pers.all_race_codes,'B') > 0 THEN 'B'
                       END AS s_ethnic_b,
                 CASE WHEN pers.s_ethnic = 'I'                THEN 'I'
                      WHEN pers.s_ethnic = '2'
                       AND instr(pers.all_race_codes,'I') > 0 THEN 'I'
                       END AS s_ethnic_i,
                 CASE WHEN pers.s_ethnic = 'P'                THEN 'P'
                      WHEN pers.s_ethnic = '2'
                       AND instr(pers.all_race_codes,'P') > 0 THEN 'P'
                       END AS s_ethnic_p,
                 CASE WHEN pers.s_ethnic = 'W'                THEN 'W'
                      WHEN pers.s_ethnic = '2'
                       AND instr(pers.all_race_codes,'W') > 0 THEN 'W'
                       END AS s_ethnic_w,
                 CASE WHEN pers.s_ethnic = 'N'                THEN 'N'
                       END AS s_ethnic_n,
                 CASE WHEN pers.s_ethnic = 'U'                THEN 'U'
                       END AS s_ethnic_u,
                 -------------------------
                 stdn.s_regent_res,
                 pers.s_religion,
                 pers.s_marital_status,
                 -------------------------
                 f_calc_entry_action_4
                 ( students.s_pidm,
                   students.s_banner_term
                 ) AS s_entry_action,
                 -------------------------
                 stdn.s_styp,
                 CASE WHEN majr.s_cur_degc1 LIKE 'N%' THEN '0'
                      WHEN stdn.s_styp         = 'P'  THEN '0'
                      WHEN majr.s_cur_degc1 LIKE 'C%' THEN '1'
                      WHEN majr.s_cur_degc1 LIKE 'A%' THEN '2'
                      WHEN majr.s_cur_degc1 LIKE 'B%' THEN '4'
                      WHEN majr.s_cur_degc1 LIKE 'M%' THEN 'M'
                      ELSE 'E' END AS s_deg_intent,
                 majr.s_cur_prgm1,
                 majr.s_cur_prgm2,
                 majr.s_cur_degc1,
                 majr.s_cur_degc2,
                 majr.s_cur_majr1,
                 majr.s_cur_majr2,
                 CASE WHEN s_cur_prgm1 = 'ND-ESL' THEN 'GE' -- Temp fix, it shouldn't be necessary.
                      ELSE (SELECT school_code FROM dsc_programs_current WHERE prgm_code = majr.s_cur_prgm1)
                      END AS s_cur_coll_code1,
                 CASE WHEN majr.s_cur_prgm2 IS NULL THEN NULL
                      ELSE (SELECT school_code FROM dsc_programs_current WHERE prgm_code = majr.s_cur_prgm2)
                      END AS s_cur_coll_code2,
                 majr.s_cur_cip1,
                 CASE WHEN majr.s_cur_prgm2 IS NULL THEN NULL ELSE majr.s_cur_cip2 END AS s_cur_cip2,
                 CASE WHEN majr.s_cur_degc1 = 'ND' THEN '240102' ELSE majr.s_cur_cip1 END AS s_cur_cip_ushe,
                 majr.s_cur_conc1,
                 majr.s_cur_conc2,
                 minr.s_cur_minr1,
                 minr.s_cur_minr2,
                 (SELECT stvmajr_desc FROM stvmajr WHERE stvmajr_code = majr.s_cur_majr1) AS s_majr_desc1,
                 (SELECT stvmajr_desc FROM stvmajr WHERE stvmajr_code = majr.s_cur_majr2) AS s_majr_desc2,
                 -------------------------
                 stcr.s_term_att_cr,
                 CASE WHEN students.s_extract = '3' THEN 0 ELSE grde.s_term_earned_cr END AS s_term_earned_cr,
                 CASE WHEN students.s_extract = 'E' THEN nvl(tgpa.s_term_gpa,0) END AS s_term_gpa,
                 gphr.s_cum_hrs_ugrad,
                 gphr.s_cum_gpa_ugrad,
                 gphr.s_cum_hrs_grad,
                 gphr.s_cum_gpa_grad,
                 NULL AS s_cum_mem_hrs,
                 tran.s_trans_total,
                 CASE WHEN stdn.levl_code = 'UG'
                           THEN CASE WHEN stcr.s_term_att_cr >= 120 THEN 'F' ELSE 'P' END
                      WHEN stdn.levl_code = 'GR'
                           THEN CASE WHEN stcr.s_term_att_cr >=  90 THEN 'F' ELSE 'P' END
                           ELSE 'P'
                      END AS s_pt_ft,
                 CASE WHEN majr.s_cur_degc1 LIKE 'M%'
                           THEN 'GG'
                      WHEN EXISTS
                           (
                             SELECT sum(shrlgpa_hours_earned)
                             FROM   shrlgpa
                             WHERE  shrlgpa_pidm = s_pidm
                             AND    shrlgpa_levl_code = 'UG'
                             AND    shrlgpa_gpa_type_ind = 'O'
                             HAVING sum(shrlgpa_hours_earned) < 30
                           )
                      THEN 'FR'
                      WHEN EXISTS
                           (
                             SELECT sum(shrlgpa_hours_earned)
                             FROM   shrlgpa
                             WHERE  shrlgpa_pidm = s_pidm
                             AND    shrlgpa_levl_code = 'UG'
                             AND    shrlgpa_gpa_type_ind = 'O'
                             HAVING sum(shrlgpa_hours_earned) BETWEEN 30 AND 59.99
                           )
                      THEN 'SO'
                      WHEN EXISTS
                           (
                             SELECT sum(shrlgpa_hours_earned)
                             FROM   shrlgpa
                             WHERE  shrlgpa_pidm = s_pidm
                             AND    shrlgpa_levl_code = 'UG'
                             AND    shrlgpa_gpa_type_ind = 'O'
                             HAVING sum(shrlgpa_hours_earned) BETWEEN 60 AND 89.99
                           )
                      THEN 'JR'
                      WHEN EXISTS
                           (
                             SELECT sum(shrlgpa_hours_earned)
                             FROM   shrlgpa
                             WHERE  shrlgpa_pidm = s_pidm
                             AND    shrlgpa_levl_code = 'UG'
                             AND    shrlgpa_gpa_type_ind = 'O'
                             HAVING sum(shrlgpa_hours_earned) >= 90
                           )
                      THEN 'SR'
                      ELSE 'FR' END AS s_level,
                 -------------------------
                 hsch.s_high_school,
                 hsch.s_hsgrad_dt,
                 hsch.s_hsgpa,
                 adid.s_ssid,
                 indx.s_index_score,
                 -------------------------
                 tran.s_total_clep,
                 tran.s_total_ap,
                 tesc.s_act_comp,
                 tesc.s_act_engl,
                 tesc.s_act_math,
                 tesc.s_act_read,
                 tesc.s_act_sci,
                 -------------------------
                 stdn.s_rate,
                 pell.s_pell,
                 sbia.s_bia,
                 atrm.s_hb75_waiver,
                 -------------------------
                 pers.s_confid_ind,
                 stdn.s_cohort_block,
                 sprt.s_sport,
                 medi.s_ada,
                 visa.s_visatype,
                 -------------------------
                 students.s_banner_term,
                 students.s_banner_extract,
                 students.s_xtrct_mltplr
                 -------------------------
          FROM   students, --<-- Created in the WITH statement above
                 ( /**/
                   SELECT s_pidm          AS inner_pidm,
                          CASE WHEN natn_code != 'US' AND stat_code NOT IN ('AA', 'AE', 'AP', 'AS', 'FM', 'GU', 'MH', 'MP', 'PR', 'PW', 'VI', 'UT')
                                    THEN 'UT097'
                               WHEN stat_code != 'UT'
                                    THEN 'UT099'
                               WHEN (cnty_code = 'UT' AND stat_code = 'UT')
                                 OR (stat_code = 'UT' AND cnty_code IN ('UT097','UT099'))
                                    THEN 'UT053' -- catch-all for UT residents
                                    ELSE cnty_code
                               END  AS s_county_origin,
                          CASE WHEN stat_code IS NOT NULL
                               THEN CASE WHEN stat_code IN
                                            (
                                                'AA', 'AE', 'AK','AL','AP', 'AR', 'AS','AZ','CA','CO','CT','DC','DE','FL','FM','GA','GU',
                                                'HI','IA','ID','IL','IN','KS','KY','LA','MA','MD','ME','MH',
                                                'MI','MN','MO','MP','MS','MT','NC','ND','NE','NH','NJ','NM',
                                                'NV','NY','OH','OK','OR','PA','PR','PW','RI','SC','SD','TN','TX',
                                                'UT','VA','VI','VT','WA','WI','WV','WY'
                                              )
                                         THEN stat_code
                                         ELSE 'XX' END
                               ELSE CASE WHEN natn_code != 'US'
                                         THEN 'XX'
                                         ELSE 'ER' END
                               END AS s_state_origin,
                          CASE WHEN natn_code IS NOT NULL AND stat_code NOT IN ('AA', 'AE', 'AP', 'AS', 'FM', 'GU', 'MH', 'MP', 'PR', 'PW', 'VI')
                                    THEN (SELECT iso_code FROM country_iso WHERE fips_code = natn_code)
                               ELSE CASE WHEN stat_code IN
                                              (
                                                'AA', 'AE', 'AK','AL','AP', 'AR', 'AS','AZ','CA','CO','CT','DC','DE','FL','FM','GA','GU',
                                                'HI','IA','ID','IL','IN','KS','KY','LA','MA','MD','ME','MH',
                                                'MI','MN','MO','MP','MS','MT','NC','ND','NE','NH','NJ','NM',
                                                'NV','NY','OH','OK','OR','PA','PR','PW','RI','SC','SD','TN','TX',
                                                'UT','VA','VI','VT','WA','WI','WV','WY'
                                              )
                                         THEN 'US'
                                         ELSE 'ER' END
                               END AS s_country_origin,
                          CASE WHEN zip_code IS NOT NULL THEN zip_code
--                                WHEN zip_code > 5 THEN nvl((     -- As a last resort, pull the first applicable zip code.
--                                           SELECT MAX(spraddr_zip)
--                                           FROM   spraddr
--                                           WHERE  spraddr_pidm = s_pidm
--                                           AND    REGEXP_LIKE(spraddr_zip, '^[[:digit:]]+$')
--                                         ),'00000')
                               ELSE '00000'
                               END AS s_cur_zip_code
                   FROM   (
                            SELECT s_pidm,
                                   CASE WHEN sabsupl_rowid IS NOT NULL
                                             THEN 'UT'||supl.cnty_code
                                        WHEN spraddr_rowid IS NOT NULL
                                             THEN 'UT'||addr.cnty_code
                                        WHEN nvl(supl.natn_code,addr.natn_code) <> 'US'
                                             THEN 'UT097'
                                        WHEN nvl(supl.natn_code,addr.natn_code)  = 'US'
                                         AND nvl(supl.stat_code,addr.stat_code) <> 'UT'
                                             THEN 'UT099'
                                             ELSE 'ERROR'
                                             END AS cnty_code,
                                   nvl(supl.stat_code,addr.stat_code) AS stat_code,
                                   CASE WHEN nvl(supl.natn_code,addr.natn_code) IS NULL
                                             THEN CASE WHEN nvl(supl.cnty_code,addr.cnty_code) = '053'
                                                        AND nvl(supl.stat_code,addr.stat_code) = 'UT'
                                                            THEN 'US'
                                                       END
                                             ELSE nvl(supl.natn_code,addr.natn_code)
                                         END  AS natn_code,
                                   --addr.zip_code AS zip_code
                                   CASE WHEN LENGTH(dsc.f_get_formatted_addr(addr.pidm, 'LOCALPERM', 'zip')) < 5 THEN '00000'
                                   ELSE (dsc.f_get_formatted_addr(addr.pidm, 'LOCALPERM', 'zip')) END AS zip_code
                            FROM   students,
                                   (
                                     SELECT sabsupl_pidm                       AS pidm,
                                            substr(sabsupl_cnty_code_admit,-3) AS cnty_code,
                                            nvl(sabsupl_stat_code_admit,'XX')  AS stat_code,
                                            sabsupl_natn_code_admit            AS natn_code
                                     FROM   students, sabsupl
                                     WHERE  s_pidm        = sabsupl_pidm (+)
                                     AND    sabsupl.ROWID = sabsupl_rowid
                                   ) supl,
                                   (
                                     SELECT spraddr_pidm                 AS pidm,
                                            substr(spraddr_cnty_code,-3) AS cnty_code,
                                            spraddr_stat_code            AS stat_code,
                                            spraddr_natn_code            AS natn_code,
                                            replace(spraddr_zip,'-','')  AS zip_code
                                     FROM   students,
                                            spraddr
                                     WHERE  s_pidm = spraddr_pidm (+)
                                     AND    spraddr.ROWID = spraddr_rowid
                                   ) addr
                            WHERE  s_pidm = supl.pidm (+)
                            AND    s_pidm = addr.pidm (+)
                          )
                 ) addr,


                 (
                   WITH ssid_list AS
                   (
                     SELECT goradid_pidm                     AS inner_pidm,
                            substr(goradid_additional_id,-7) AS s_ssid,
                            row_number() OVER (PARTITION BY goradid_pidm ORDER BY goradid_activity_date DESC) rn
                     FROM   students, goradid
                     WHERE  s_pidm = goradid_pidm (+)
                     AND    goradid_adid_code = 'SSID'
                     AND    trim(TRANSLATE(goradid_additional_id, '0123456789', ' ')) is null
                     AND    LENGTH(goradid_additional_id) BETWEEN 7 AND 9
                     AND    goradid_additional_id NOT LIKE '%*%'
                     AND    goradid_additional_id NOT LIKE '%.%'
                     AND    substr(substr(goradid_additional_id,-7),1,1) BETWEEN 1 AND 2
                   )
                -- Students can have more than one SSID, so use activity date to get the most recent one.
                   SELECT inner_pidm, s_ssid
                   FROM   ssid_list
                   WHERE  rn = 1
                 ) adid,
                 (
                   SELECT rpratrm_pidm AS inner_pidm,
                          round(sum(rpratrm_paid_amt) / max(hb75_minus), 2) * -100 AS s_hb75_waiver
                     FROM rpratrm, students,
                          (SELECT  SUM((SELECT MAX (sfrrgfe_per_cred_charge)
                             FROM sfrrgfe
                            WHERE sfrrgfe_term_code = (SELECT DISTINCT p_banner_term FROM extract_parameters)
                              AND sfrrgfe_from_flat_hrs = 12
                              AND sfrrgfe_resd_code = 'R'
                              AND sfrrgfe_detl_code IN ('1001', '1002')
                              AND sfrrgfe_program IS NULL
                              AND sfrrgfe_rate_code IS NULL)
                - (SELECT MAX (sfrrgfe_per_cred_charge)
                         FROM sfrrgfe
                        WHERE sfrrgfe_term_code = (SELECT DISTINCT p_banner_term FROM extract_parameters)
                          AND sfrrgfe_from_flat_hrs = 12
                          AND sfrrgfe_resd_code = 'N'
                          AND sfrrgfe_detl_code IN ('1200', '1201')
                          AND sfrrgfe_program IS NULL
                          AND sfrrgfe_rate_code IS NULL
                          AND sfrrgfe_camp_code IS NULL))*12  AS hb75_minus
                    FROM DUAL)
                   WHERE s_pidm = rpratrm_pidm (+)
                     AND rpratrm_term_code = s_banner_term
                     AND rpratrm_fund_code IN ('82010','82011','82012','82013','82016','82017')
                     AND rpratrm_paid_amt > 0
                GROUP BY rpratrm_pidm
                 ) atrm,
                 (
                   SELECT shrlgpa_pidm                AS inner_pidm,
                          round(nvl(sum(CASE WHEN shrlgpa_levl_code IN ('NC','UG')
                                             THEN shrlgpa_hours_earned END
                                       ) * 10, 0), 0) AS s_cum_hrs_ugrad,
                          round(nvl(sum(CASE WHEN shrlgpa_levl_code = 'GR'
                                             THEN shrlgpa_hours_earned END
                                       ) * 10, 0), 0) AS s_cum_hrs_grad,
                          round(nvl(sum(CASE WHEN  shrlgpa_levl_code IN ('NC','UG')
                                             THEN  shrlgpa_quality_points / shrlgpa_gpa_hours END
                                       ) * 1000,0),0) AS s_cum_gpa_ugrad,
                          round(nvl(sum(CASE WHEN  shrlgpa_levl_code  = 'GR'
                                             THEN  shrlgpa_quality_points / shrlgpa_gpa_hours END
                                       ) * 1000,0),0) AS s_cum_gpa_grad
                   FROM   students, shrlgpa
                   WHERE  s_pidm = shrlgpa_pidm (+)
                   AND    shrlgpa_gpa_type_ind = 'I'
                   AND    shrlgpa_quality_points > 0
                   GROUP  BY shrlgpa_pidm
                 ) gphr,
                 (
                   SELECT swvgrde_pidm                   AS inner_pidm,
                          sum(swvgrde_earned_hours) * 10 AS s_term_earned_cr
                   FROM   students, dsc_swvgrde
                   WHERE  swvgrde_term_code = s_banner_term
                   AND    s_pidm = swvgrde_pidm (+)
                   GROUP  BY swvgrde_pidm
                 ) grde,
                 (
                   SELECT s_pidm                 AS inner_pidm,
                          gurhlog_previous_value AS s_prev_id
                   FROM   students, gurhlog g1
                   WHERE  gurhlog_pidm||gurhlog_previous_value
                          <> gurhlog_pidm||gurhlog_current_value
                   AND    gurhlog_pidm = s_pidm
                   AND    gurhlog_previous_value
                          NOT IN ('000000000','00000000','0000000','000000',
                                  '00000','0000','000','00','0','`')
                   AND    gurhlog_activity_date =
                          (
                            SELECT MAX(g2.gurhlog_activity_date)
                            FROM   gurhlog g2, spbpers
                            WHERE  g2.gurhlog_pidm = g1.gurhlog_pidm
                            AND    g2.gurhlog_pidm = spbpers_pidm
                            AND    g2.gurhlog_previous_value
                                   NOT IN ('000000000','00000000','0000000','000000',
                                           '00000','0000','000','00','0')
                            AND    g2.gurhlog_previous_value IS NOT NULL
                            AND    g2.gurhlog_key = 'SPBPERS_SSN'
                            AND    g2.gurhlog_current_value = spbpers_ssn
                            AND    g2.gurhlog_pidm||g2.gurhlog_previous_value
                                   <> g2.gurhlog_pidm||g2.gurhlog_current_value
                          )
                 ) hlog,
                 (     -- Pull High School Information from SORHSCH, HSGPACT, and GORADID
                   SELECT DISTINCT
                          sorhsch_pidm AS inner_pidm,
                          CASE WHEN sorhsch_sbgi_code = '450413' THEN '450406'
                               WHEN sorhsch_sbgi_code = '450406' THEN '450413'
                               WHEN sorhsch_sbgi_code = '459999' THEN '459150'
                               WHEN sorhsch_sbgi_code = '969999' THEN '459200'
                               WHEN sorhsch_sbgi_code = '459998' THEN '459500'
                               WHEN sorhsch_sbgi_code = '969999' THEN '459500'
                               WHEN sorhsch_sbgi_code = '459994' THEN '459000'
                               WHEN sorhsch_sbgi_code = '459996' THEN '459200'
                               WHEN sorhsch_sbgi_code = '459997' THEN '459100'
                               WHEN sorhsch_sbgi_code = '459993' THEN '459050'
                               WHEN sorhsch_sbgi_code = '459995' THEN '459300'
                               WHEN sorhsch_sbgi_code = '960000' THEN '459400'
                               WHEN sorhsch_sbgi_code IS NULL    THEN '459200'
                               ELSE sorhsch_sbgi_code END              AS s_high_school,
                          to_char(sorhsch_graduation_date, 'YYYYMMDD') AS s_hsgrad_dt,
                          to_number(trunc(sorhsch_gpa,3))              AS s_hsgpa
                   FROM   students,
                          sorhsch
                   WHERE  s_pidm = sorhsch_pidm (+)
                   AND    sorhsch.ROWID = dsc.f_get_sorhsch_rowid(s_pidm)

                 ) hsch,
                 (
                   SELECT hsgpact_pidm    AS inner_pidm,
                          hsgpact_hsgpact AS s_index_score
                   FROM   students, dsc.hsgpact
                   WHERE  s_pidm = hsgpact_pidm (+)
                 ) indx,
                 (
                   SELECT s_pidm          AS inner_pidm,
                          prgm1.prgm_code AS s_cur_prgm1,
                          CASE WHEN prgm1.prgm_code <> prgm2.prgm_code
                               THEN prgm2.prgm_code
                               END        AS s_cur_prgm2,
                          prgm1.degc_code AS s_cur_degc1,
                          CASE WHEN prgm1.prgm_code <> prgm2.prgm_code
                               THEN prgm2.degc_code
                               END        AS s_cur_degc2,
                          majr1.majr_code AS s_cur_majr1,
                          CASE WHEN prgm1.prgm_code <> prgm2.prgm_code
                               THEN majr2.majr_code
                               END        AS s_cur_majr2,
                          nvl(prgm1.cur_cip1,'999999')
                                          AS s_cur_cip1,
                          prgm2.cur_cip2  AS s_cur_cip2,
                          cur_conc1       AS s_cur_conc1,
                          cur_conc2       AS s_cur_conc2
                   FROM   students,
                          (     -- 1st Major
                            SELECT sgvacur_pidm,
                                   CASE WHEN sgbstdn_levl_code = 'CE'
                                        THEN 'CE'
                                        ELSE sgvacur_majr_code_1
                                        END AS majr_code,
                                   sgvacur_majr_code_conc_1 AS cur_conc1,
                                   sgvacur_majr_code_conc_2 AS cur_conc2
                            FROM   students, sgvacur, sgbstdn s1
                            WHERE  sgvacur_pidm          = s_pidm
                            AND    sgbstdn_pidm          = s_pidm
                            AND    sgvacur_cact_code     = 'ACTIVE'
                            AND    sgvacur_order         = 1 -- first matriculation
                            AND    sgvacur_stdn_rowid    = s1.ROWID
                            AND    sgbstdn_term_code_eff =
                                   ( -- Find the most-recent effective term code
                                     SELECT MAX(s2.sgbstdn_term_code_eff)
                                     FROM   sgbstdn s2
                                     WHERE  s2.sgbstdn_pidm = s1.sgbstdn_pidm
                                     AND    s2.sgbstdn_term_code_eff <= s_banner_term
                                   )
                          ) majr1,
                          (     -- 2nd Major
                            SELECT sgvacur_pidm,
                                   sgvacur_majr_code_1 AS majr_code
                            FROM   students, sgvacur, sgbstdn s1
                            WHERE  sgvacur_pidm          = s_pidm
                            AND    sgbstdn_pidm          = s_pidm
                            AND    sgvacur_cact_code     = 'ACTIVE'
                            AND    sgvacur_order         = 2 -- second matriculation
                            AND    sgvacur_stdn_rowid    = s1.ROWID
                            AND    sgbstdn_term_code_eff =
                                   ( -- Find the most-recent effective term code
                                     SELECT MAX(s2.sgbstdn_term_code_eff)
                                     FROM   sgbstdn s2
                                     WHERE  s2.sgbstdn_pidm = s1.sgbstdn_pidm
                                     AND    s2.sgbstdn_term_code_eff <= s_banner_term
                                   )
                          ) majr2,
                          (     -- 1st Program
                            SELECT sgvccur_pidm,
                                   CASE WHEN sgbstdn_levl_code = 'CE'
                                        THEN 'ND'
                                        ELSE sgvccur_degc_code
                                        END  AS degc_code,
                                   CASE WHEN sgbstdn_levl_code = 'CE'
                                        THEN 'ND-CE'
                                        ELSE sgvccur_program
                                        END  AS prgm_code,
                                   cipc_code AS cur_cip1
                            FROM   students, dsc_programs_current, sgvccur, sgbstdn s1
                            WHERE  sgvccur_program    = prgm_code (+)
                            AND    sgvccur_pidm       = s_pidm
                            AND    sgbstdn_pidm       = s_pidm
                            AND    sgvccur_cact_code  = 'ACTIVE'
                            AND    sgvccur_order      = 1 -- first matriculation
                            AND    sgvccur_stdn_rowid = s1.ROWID
                            AND    sgbstdn_term_code_eff =
                                   (     -- Find most-recent effective term code
                                     SELECT MAX(s2.sgbstdn_term_code_eff)
                                     FROM   sgbstdn s2
                                     WHERE  s2.sgbstdn_pidm = s1.sgbstdn_pidm
                                     AND    s2.sgbstdn_term_code_eff <= s_banner_term
                                   )
                          ) prgm1,
                          (     -- 2nd Program
                            SELECT sgvccur_pidm,
                                   sgvccur_degc_code AS degc_code,
                                   sgvccur_program   AS prgm_code,
                                   cipc_code         AS cur_cip2
                            FROM   students, dsc_programs_current, sgvccur, sgbstdn s1
                            WHERE  sgvccur_program    = prgm_code (+)
                            AND    sgvccur_pidm       = s_pidm
                            AND    sgbstdn_pidm       = s_pidm
                            AND    sgvccur_cact_code  = 'ACTIVE'
                            AND    sgvccur_order      = 2 -- second matriculation
                            AND    sgvccur_stdn_rowid = s1.ROWID
                            AND    sgbstdn_term_code_eff =
                                   (     -- Find most-recent effective term code
                                     SELECT MAX(s2.sgbstdn_term_code_eff)
                                     FROM   sgbstdn s2
                                     WHERE  s2.sgbstdn_pidm = s1.sgbstdn_pidm
                                     AND    s2.sgbstdn_term_code_eff <= s_banner_term
                                   )
                          ) prgm2
                   WHERE s_pidm = majr1.sgvacur_pidm
                   AND   s_pidm = majr2.sgvacur_pidm (+)
                   AND   s_pidm = prgm1.sgvccur_pidm
                   AND   s_pidm = prgm2.sgvccur_pidm (+)
                 ) majr,
                 (
                   SELECT sprmedi_pidm           AS inner_pidm,
                          MAX(sprmedi_medi_code) AS s_ada
                   FROM   students, sprmedi
                   WHERE  s_pidm = sprmedi_pidm (+)
                   AND    sprmedi_medi_code IS NOT NULL
                   AND    sprmedi_medi_code <> 'DISABSURV'
                   GROUP  BY sprmedi_pidm
                 ) medi,
                 (
                   SELECT s_pidm AS inner_pidm,
                          (
                            SELECT sorlfos_majr_code
                            FROM   sorlfos s1
                            WHERE  sorlfos_pidm      = s_pidm
                            AND    sorlfos_seqno||sorlfos_lcur_seqno =
                                   (
                                     SELECT MAX(s2.sorlfos_seqno||s2.sorlfos_lcur_seqno)
                                     FROM   sorlfos s2
                                     WHERE  s2.sorlfos_pidm      = s_pidm
                                     AND    s2.sorlfos_cact_code = 'ACTIVE'
                                     AND    s2.sorlfos_lfst_code = 'MINOR'
                                   )
                            AND    ROWNUM = 1
                          ) AS s_cur_minr1,
                          (
                            SELECT sorlfos_majr_code
                            FROM   sorlfos s1
                            WHERE  sorlfos_pidm = s_pidm
                            AND    sorlfos_seqno||sorlfos_lcur_seqno =
                                   (
                                     SELECT MAX(s2.sorlfos_seqno||s2.sorlfos_lcur_seqno)
                                     FROM   sorlfos s2
                                     WHERE  s2.sorlfos_pidm      = s_pidm
                                     AND    s2.sorlfos_cact_code = 'ACTIVE'
                                     AND    s2.sorlfos_lfst_code = 'MINOR'
                                   )
                            AND    ROWNUM = 2
                          ) AS s_cur_minr2
                   FROM   students
                 ) minr,
                 (
                   SELECT s_pidm AS inner_pidm,
                          CASE WHEN s_pidm IN
                          (
                            SELECT tbraccd_pidm
                            FROM   tbraccd
                            WHERE  tbraccd_term_code   = (SELECT DISTINCT s_banner_term FROM students)
                            AND    tbraccd_detail_code = 'PELL'
                            AND    tbraccd_amount      > 0
                          )
                          THEN 'R'
                          WHEN s_pidm IN
                          (
                            SELECT rpratrm_pidm
                            FROM   rpratrm
                            WHERE  rpratrm_term_code  = (SELECT DISTINCT s_banner_term FROM students)
                            AND    rpratrm_offer_amt  > 0
                            AND    rpratrm_fund_code IN ('FPELL','FPELL1')
                          )
                          THEN 'E'
                          END AS s_pell
                   FROM   students
                 ) pell,
                 (     -- Pull personal data from SPBPERS and SPRIDEN
                   SELECT spbpers_pidm AS inner_pidm,
                          CASE WHEN spbpers_citz_code = 2 THEN 'D' || spriden_id
                               ELSE CASE WHEN NOT
                                    (
                                         (substr(spbpers_ssn,0,2) != '00' AND substr(spbpers_ssn,4,2) = '00') -- dummy ID
                                      OR  substr(spbpers_ssn,0,1)  = '9'                                      -- dummy ID
                                      OR  spbpers_ssn IN ('078051120','111111111','123456789')                -- dummy ID
                                      OR (spbpers_ssn >= '987654320' AND spbpers_ssn <= '987654329')          -- dummy ID
                                      OR  spbpers_ssn LIKE '000%'                                             -- dummy ID
                                      OR  spbpers_ssn LIKE '%9%99999%'                                        -- dummy ID
                                      OR  spbpers_ssn LIKE '666%'                                             -- cant begin w/ 666
                                      OR  spbpers_ssn LIKE '9%'	                                              -- cant begin w/ 9
                                      OR  substr(spbpers_ssn,4,2) = '00'                                      -- middle cant be 00
                                      OR  substr(spbpers_ssn,6,4) = '0000'                                    -- last four cant be 0000
                                      OR  LENGTH(trim(spbpers_ssn)) < 9                                       -- not 9 digits
                                      OR  spbpers_ssn LIKE '%[a-z]%'                                          -- contains nondigit
                                    )
                                    THEN trim(spbpers_ssn)
                                    ELSE 'D' || spriden_id END END      AS s_id,
                          spbpers_sex                            AS s_gender,
                          CASE WHEN upper(REPLACE(substr(spbpers_name_suffix, 1, 4),'.',''))
                                    NOT IN ('BAP','CAP','ESQ','MD','NA','JL','TY','JDB','MJE','E','ANM')
                               THEN REPLACE(substr(spbpers_name_suffix, 1, 4),'.','')
                               END                               AS s_suffix,
                          CASE WHEN f_calculate_age(stvterm_start_date, spbpers_birth_date, spbpers_dead_date) > 100
                               THEN to_char(to_date(to_char(spbpers_birth_date,'DD-MON-RR')),'YYYYMMDD')
                               ELSE to_char(spbpers_birth_date,'YYYYMMDD')
                               END                               AS s_birth_dt,
                          s_citz_code,
                          all_race_codes                         AS all_race_codes,
                          CASE -- 1.) Non-Resident Alien -----------------------
                               WHEN s_citz_code               = '2' THEN 'N'
                               -- 2.) Old Race Hispanic ------------------------
                               WHEN spbpers_ethn_cde          = '2' THEN 'H'
                               -- 3.) New Race Hispanic ------------------------
                               WHEN instr(all_race_codes,'H') > '0' THEN 'H'
                               -- 4.) New Race Multiple ------------------------
                               WHEN LENGTH(all_race_codes)    > '1' THEN '2'
                               -- 5.) New Race Code ----------------------------
                               ELSE nvl(
                                    all_race_codes,
                               -- 6.) Old Race Code ----------------------------
                                    nvl(
                                    spbpers_ethn_code,
                               -- 7.) Unknown (None of the above) --------------
                                    'U')
                                    ) END   AS s_ethnic,
                          spbpers_relg_code AS s_religion,
                          spbpers_mrtl_code AS s_marital_status,
                          CASE WHEN f_calculate_age(stvterm_start_date, spbpers_birth_date, spbpers_dead_date) > 100
                               THEN f_calculate_age(stvterm_start_date, to_date(to_char(spbpers_birth_date,'DD-MON-RR')), spbpers_dead_date)
                               ELSE f_calculate_age(stvterm_start_date, spbpers_birth_date, spbpers_dead_date)
                               END          AS s_age,
                          CASE WHEN spbpers_dead_ind = 'Y' THEN 'D'
                               ELSE nvl(spbpers_confid_ind,'N')
                               END AS s_confid_ind
                   FROM   students, spbpers, stvterm, spriden,
                          (     -- Load all Race Codes into a single field to save work in final query
                            SELECT gorprac_pidm,
                                   LISTAGG(gorprac_race_cde,'')
                                           WITHIN GROUP (ORDER BY gorprac_race_cde) AS all_race_codes
                            FROM   students, gorprac
                            WHERE  s_pidm = gorprac_pidm (+)
                            GROUP  BY gorprac_pidm
                          )
                   WHERE  s_pidm = spbpers_pidm
                   AND    s_pidm = spriden_pidm
                   AND    s_pidm = gorprac_pidm (+)
                   AND    stvterm_code = s_banner_term
                   AND    spriden_change_ind IS NULL
                 ) pers,
                 (     -- Pull previous SPRIDEN record information
                   SELECT spriden_pidm                       AS inner_pidm,
                          spriden_last_name                  AS s_prev_last,
                          substr(s1.spriden_first_name,1,15) AS s_prev_first,
                          substr(s1.spriden_mi,1,15)         AS s_prev_middle
                   FROM   students i LEFT JOIN spriden s1 ON spriden_pidm = s_pidm
                   WHERE  s1.spriden_last_name||s1.spriden_first_name||s1.spriden_mi
                          <> s_last_name||s_first_name||s_middle_name
                   AND    ROWNUM = 1 -- only grab one previous record. Add logic to choose best prev record?
                 ) prev,
                 (
                   SELECT s_pidm AS inner_pidm,
                          CASE WHEN EXISTS
                          (
                            SELECT 'Y'
                            FROM   tbraccd
                            WHERE  tbraccd_pidm        = s_pidm
                            AND    tbraccd_term_code   = s_banner_term
                            AND    tbraccd_detail_code = '8933'
                            AND    tbraccd_amount     <> 0
                          )
                          THEN 'B'
                          END AS s_bia
                   FROM   students
                 ) sbia,
                 (
                   SELECT sgrsprt_pidm AS inner_pidm,
                          listagg(sgrsprt_actc_code,',') WITHIN GROUP (ORDER BY sgrsprt_actc_code)
                                       AS s_sport
                   FROM   students, sgrsprt
                   WHERE  s_pidm            = sgrsprt_pidm (+)
                   AND    sgrsprt_term_code = s_banner_term
                   GROUP  BY sgrsprt_pidm
                 ) sprt,
                 (
                   SELECT sfrstcr_pidm              AS inner_pidm,
                          sum(sfrstcr_credit_hr)*10 AS s_term_att_cr
                   FROM   students, sfrstcr, stvrsts, ssbsect
                   WHERE  sfrstcr_pidm           = s_pidm
                   AND    ssbsect_crn            = sfrstcr_crn
                   AND    sfrstcr_term_code      = s_banner_term
                   AND    ssbsect_term_code      = sfrstcr_term_code
                   AND    sfrstcr_rsts_code      = stvrsts_code
                   AND    ssbsect_ssts_code      = 'A'
                   AND    ssbsect_camp_code     != 'XXX'
                   AND    stvrsts_incl_sect_enrl = 'Y'
                   GROUP  BY sfrstcr_pidm
                 ) stcr,
                 (     -- Application Student Type Code taken from SGBSTDN
                   SELECT sgbstdn_pidm      AS inner_pidm,
                          sgbstdn_styp_code AS s_styp,
                          REPLACE(sgbstdn_levl_code,'CE','UG')
                                            AS levl_code,
                          sgbstdn_rate_code AS s_rate,
                          sgbstdn_blck_code AS s_cohort_block,
                          CASE WHEN sgbstdn_resd_code IN ('R','N','A','M','G') THEN sgbstdn_resd_code
                               WHEN sgbstdn_resd_code IN ('C','S')             THEN 'R'
                               WHEN sgbstdn_resd_code IN ('0','H')             THEN 'N'
                               END          AS s_regent_res
                   FROM   students, sgbstdn s1
                   WHERE  sgbstdn_pidm = s_pidm
                   AND    sgbstdn_term_code_eff =
                          (     -- Find most-recent applicable term code
                            SELECT MAX(s2.sgbstdn_term_code_eff)
                            FROM   sgbstdn s2
                            WHERE  s2.sgbstdn_pidm           = s1.sgbstdn_pidm
                            AND    s2.sgbstdn_term_code_eff <= s_banner_term
                          )
                 ) stdn,
                 (
                   SELECT sortest_pidm AS inner_pidm,
                          act_comp     AS s_act_comp,
                          act_engl     AS s_act_engl,
                          act_math     AS s_act_math,
                          act_read     AS s_act_read,
                          act_sci      AS s_act_sci
                   FROM   (
                            SELECT sortest_pidm,
                                   decode(sortest_tesc_code,
                                          'A01' ,'act_engl',
                                          'A02' ,'act_math',
                                          'A02N','act_math',
                                          'A03' ,'act_read',
                                          'A04' ,'act_sci' ,
                                          'A05' ,'act_comp',
                                          sortest_tesc_code) AS tesc_code,
                                   sortest_test_score AS test_score,
                                   row_number() OVER (PARTITION BY sortest_pidm, sortest_tesc_code
                                                      ORDER BY sortest_test_score DESC) AS rn
                            FROM   students, sortest
                            WHERE  s_pidm = sortest_pidm (+)
                            AND    sortest_equiv_ind = 'N'
                            AND    sortest_tesc_code IN ('A05','A02','A02N','A01','A03','A04')
                          )
                   PIVOT  ( max(test_score) FOR tesc_code
                            IN ('act_comp' AS act_comp,
                                'act_engl' AS act_engl,
                                'act_math' AS act_math,
                                'act_read' AS act_read,
                                'act_sci'  AS act_sci))
                   WHERE rn = 1
                 ) tesc,
                 (
                   SELECT shrtgpa_pidm AS inner_pidm,
                          round(sum(shrtgpa_quality_points) / sum(shrtgpa_gpa_hours), 3) * 1000
                                       AS s_term_gpa
                   FROM   students, shrtgpa
                   WHERE  s_pidm                 = shrtgpa_pidm (+)
                   AND    shrtgpa_term_code      = s_banner_term
                   AND    shrtgpa_gpa_type_ind   = 'I'
                   AND    shrtgpa_quality_points > 0
                   GROUP  BY shrtgpa_pidm
                 ) tgpa,
                 (
                   SELECT shrtgpa_pidm   AS inner_pidm,
                          sum(hrs_trans) AS s_trans_total,
                          sum(hrs_clep)  AS s_total_clep,
                          sum(hrs_ap)    AS s_total_ap
                   FROM   (
                            SELECT shrtgpa_pidm,
                                   CASE WHEN stvsbgi_srce_ind = 'Y' AND stvsbgi_type_ind = 'C'
                                        THEN shrtgpa_hours_earned * 10
                                        END  AS hrs_trans,
                                   CASE WHEN shrtrit_sbgi_code LIKE 'CLEP%' OR shrtrit_sbgi_code LIKE 'CLP%'
                                        THEN shrtgpa_hours_earned * 10
                                        END  AS hrs_clep,
                                   CASE WHEN shrtrit_sbgi_code LIKE 'AP%'
                                        THEN shrtgpa_hours_earned * 10
                                        END  AS hrs_ap
                           FROM   students, shrtgpa, shrtrit, stvsbgi
                           WHERE  shrtgpa_pidm         = s_pidm
                           AND    shrtrit_pidm         = s_pidm
                           AND    shrtrit_sbgi_code    = stvsbgi_code
                           AND    shrtgpa_trit_seq_no  = shrtrit_seq_no
                           AND    shrtgpa_gpa_type_ind = 'T'
                          )
                   GROUP  BY shrtgpa_pidm
                 ) tran,
                 (
                   SELECT gorvisa_pidm      AS inner_pidm,
                          gorvisa_vtyp_code AS s_visatype
                   FROM   students, gorvisa g1, stvvtyp
                   WHERE  s_pidm = gorvisa_pidm (+)
                   AND    gorvisa_vtyp_code = stvvtyp_code
                   AND    gorvisa_seq_no||gorvisa_vtyp_code =
                          (
                            SELECT MAX(g2.gorvisa_seq_no||g2.gorvisa_vtyp_code)
                            FROM   gorvisa g2
                            WHERE  g2.gorvisa_pidm = g1.gorvisa_pidm
                          )
                    AND (gorvisa_visa_expire_date > sysdate OR gorvisa_visa_expire_date IS NULL)
                 ) visa


                 -------------------------------------
          WHERE  students.s_pidm = addr.inner_pidm (+)
          AND    students.s_pidm = adid.inner_pidm (+)
          AND    students.s_pidm = atrm.inner_pidm (+)
          AND    students.s_pidm = gphr.inner_pidm (+)
          AND    students.s_pidm = grde.inner_pidm (+)
          AND    students.s_pidm = hlog.inner_pidm (+)
          AND    students.s_pidm = hsch.inner_pidm (+)
          AND    students.s_pidm = indx.inner_pidm (+)
          AND    students.s_pidm = majr.inner_pidm (+)
          AND    students.s_pidm = medi.inner_pidm (+)
          AND    students.s_pidm = minr.inner_pidm (+)
          AND    students.s_pidm = pell.inner_pidm (+)
          AND    students.s_pidm = pers.inner_pidm (+)
          AND    students.s_pidm = prev.inner_pidm (+)
          AND    students.s_pidm = sbia.inner_pidm (+)
          AND    students.s_pidm = sprt.inner_pidm (+)
          AND    students.s_pidm = stcr.inner_pidm (+)
          AND    students.s_pidm = stdn.inner_pidm (+)
          AND    students.s_pidm = tesc.inner_pidm (+)
          AND    students.s_pidm = tgpa.inner_pidm (+)
          AND    students.s_pidm = tran.inner_pidm (+)
          AND    students.s_pidm = visa.inner_pidm (+)
        )

 COMMIT;

 ------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------       


 TRUNCATE TABLE courses_current;       
 INSERT INTO courses_current
 SELECT      c_crn,
             c_banner_term,
             c_banner_extract,
             c_inst,
             c_year,
             c_term,
             c_extract,
             c_crs_subject,
             c_crs_number,
             c_crs_section,
             c_ptrm_code,
             c_min_credit,
             c_max_credit,
             c_contact_hrs,
             c_line_item,
             c_site_type,
             c_budget_code,
             c_delivery_method,
             c_program_type,
             c_credit_ind,
             c_start_time1,
             c_stop_time1,
             c_days1,
             c_bldg1,
             c_bldg_num1,
             c_room1,
             c_room_max1,
             c_room_type1,
             c_start_time2,
             c_stop_time2,
             c_days2,
             c_bldg2,
             c_bldg_num2,
             c_room2,
             c_room_max2,
             c_room_type2,
             c_start_time3,
             c_stop_time3,
             c_days3,
             c_bldg3,
             c_bldg_num3,
             c_room3,
             c_room_max3,
             c_room_type3,
             c_start_date,
             c_end_date,
             c_title,
             c_instr_pidm,
             c_instr_id,
             c_instr_name,
             c_instruct_type,
             c_schd_code,
             c_division,
             c_college,
             c_dept,
             c_enrl,
             c_crs_level,
             c_gen_ed,
             c_xlist_ind,
             c_dest_site,
             c_del_model,
             c_dsc_fye,
             c_level
 FROM   (
          WITH courses AS
          (
            SELECT DISTINCT 
                   p_dsc_term_code   AS c_banner_extract,
                   p_banner_term     AS c_banner_term,
                   p_year            AS c_year,
                   p_term            AS c_term,
                   p_extract         AS c_extract,
                   crn_key           AS c_crn,
                   subj_code         AS c_crs_subject,
                   crse_number       AS c_crs_number,
                   seq_number_key    AS c_crs_section,
                   spriden_pidm      AS c_instr_pidm,
                   spriden_id        AS c_instr_id,
                   dsc.f_get_name(spriden_pidm)
                                     AS c_instr_name,
                   CASE WHEN ssbsect_insm_code = 'E'   THEN 'H' 
                        WHEN ssbsect_insm_code IS NULL THEN 'P'
                        ELSE ssbsect_insm_code
                        END  AS c_delivery_method,  
                   ssbsect_schd_code AS dsc_schd_code,
                   CASE WHEN subj_code = 'CED' -- When The course is a Community Education Course ...
                        THEN 'SD'              -- ... then Budget Code SD
                        ELSE ssrsccd_sccd_code -- ... else SCCD Code
                        END          AS c_budget_code,
                   CASE WHEN subj_code = 'CED' -- When the course is a Community Education Course...
                        THEN 'N'               -- ... Then Indicate it's a non-credit course
                        ELSE 'C'               -- ... Else Indicate it's a credit course
                        END          AS c_credit_ind                  
        -- SELECT * 
           FROM   extract_parameters, 
                  as_catalog_schedule,
                  ssbsect,
                  gtvinsm,
                  spriden,
                  ssrsccd
           WHERE  p_dsc_term_code       = (SELECT DISTINCT p_dsc_term_code FROM extract_parameters)              -- This is the only variable one need supply
           AND    term_code_key         = p_banner_term         -- Join Term Codes
           AND    primary_instructor_id = spriden_id (+)        -- Join Term Codes (LEFT JOIN)
           AND    ssbsect_term_code     = ssrsccd_term_code (+) -- Join Term Codes
           AND    ssbsect_insm_code     = gtvinsm_code          -- Join PIDMs (LEFT JOIN)
           AND    ssbsect_crn           = crn_key               -- Join CRNs
           AND    ssbsect_crn           = ssrsccd_crn (+)       -- Join CRNs (LEFT JOIN)
           AND    ssbsect_term_code     = p_banner_term         -- Join GTV Table
           AND    ssts_code             = 'A'                   -- Active Courses
           AND    camp_code            <> 'XXX'                 -- Invalid Courses
           AND    upper(title) NOT LIKE '%LITERACY EXAM'        -- Invalid Courses
           AND   (divs_code <> 'CE' OR divs_code  IS NULL)      -- Invalid Courses
           AND    CASE WHEN p_extract = '3'                     -- When Third Week...
                       THEN credit_hours_low ELSE 1 END > 0     -- ... Then eliminate zero credit courses.
           AND subj_code != 'CED'
          ) /**/
          SELECT '3671' AS c_inst,
                 courses.c_year,
                 courses.c_term,
                 courses.c_extract,
                 -------------------------
                 courses.c_crn,
                 courses.c_instr_pidm,
                 courses.c_instr_id,
                 courses.c_instr_name,
                 -------------------------
                 courses.c_crs_subject,
                 courses.c_crs_number,
                 courses.c_crs_section,
                 -------------------------
                 ascs.c_title,
                 ascs.c_college,
                 ascs.c_dept,
                 enrl.c_enrl,
                 -------------------------
                 ascs.c_ptrm_code,
                 ascs.c_min_credit,
                 ascs.c_max_credit,
                 ascs.c_contact_hrs,
                 -------------------------
                 ascs.c_start_date,
                 ascs.c_end_date,
                 courses.c_credit_ind,
                 -------------------------
                 ascs.c_start_time1,
                 ascs.c_stop_time1,
                 ascs.c_days1,
                 ascs.c_bldg1,
                 ascs.c_bldg_num1,
                 ascs.c_room1,
                 ascs.c_room_max1,
                 ascs.c_room_type1,
                 -------------------------
                 ascs.c_start_time2,
                 ascs.c_stop_time2,
                 ascs.c_days2,
                 ascs.c_bldg2,
                 ascs.c_bldg_num2,
                 ascs.c_room2,
                 ascs.c_room_max2,
                 ascs.c_room_type2,
                 -------------------------
                 ascs.c_start_time3,
                 ascs.c_stop_time3,
                 ascs.c_days3,
                 ascs.c_bldg3,
                 ascs.c_bldg_num3,
                 ascs.c_room3,
                 ascs.c_room_max3,
                 ascs.c_room_type3,
                 -------------------------
                 courses.c_budget_code,
                 courses.dsc_schd_code AS c_schd_code,
                 courses.c_delivery_method,
                 supp.c_dsc_fye,
                 CASE WHEN courses.c_delivery_method = 'E' THEN 'E' END AS c_del_model, 
                 gned.c_gen_ed,
                 ascs.c_site_type,
                 CASE WHEN dsc_schd_code IN ('PRA','INT', 'CLN','OTH','SUP')
                           THEN 'SUP'
                      WHEN dsc_schd_code IN ('ACT','MUM','MUN','INV')
                           THEN 'INV'
                      WHEN dsc_schd_code IN ('LEC', 'LEX')
                           THEN 'LEC'
                      WHEN dsc_schd_code IN ('LEL','ENS','STU')
                           THEN 'LEL'
                      WHEN dsc_schd_code IN ('LBC','LAB')
                           THEN 'LAB'
                      ELSE dsc_schd_code
                      END AS c_instruct_type,
                 ascs.c_crs_level,
                 CASE WHEN c_crs_number < '1000' AND c_crs_subject IN ('MATH', 'ENGL', 'ESL') THEN 'R'
                      WHEN c_crs_number >= '6000' THEN 'G'
                      ELSE 'U'
                      END AS c_level,
                 CAST (NULL AS VARCHAR2(4)) AS c_division,
                 'A' AS c_line_item,
                 xlst.c_xlist_ind,
                 CASE WHEN courses.c_term > 1  -- The term is not a Summer term
                      THEN CASE WHEN c_budget_code     = 'BC' AND c_site_type   IN ('A01','B80')
                                 AND c_delivery_method = 'R'  AND c_crs_section LIKE '%K%' THEN '450150'
                                WHEN c_budget_code     = 'SF' AND c_site_type = 'C01'      THEN '450350'
                                WHEN c_budget_code     = 'SF' AND c_site_type = 'C02'      THEN '450354'
                                WHEN c_budget_code     = 'SF' AND c_site_type = 'C03'      THEN '450353'
                                WHEN c_budget_code     = 'SF' AND c_site_type = 'C04'      THEN '450135'
                                WHEN c_budget_code     = 'SF' AND c_site_type = 'C05'      THEN '450444'
                                WHEN c_budget_code     = 'SF' AND c_site_type = 'C06'      THEN '450075'
                                WHEN c_budget_code     = 'SF' AND c_site_type = 'C07'      THEN '450045'
                                WHEN c_budget_code     = 'SF' AND c_site_type = 'C08'      THEN '450150'
                                WHEN c_budget_code     = 'SF' AND c_site_type = 'C09'      THEN '450060'
                                WHEN c_budget_code     = 'SF' AND c_site_type = 'C10'      THEN '450275'
                                WHEN c_budget_code     = 'SF' AND c_site_type = 'C11'      THEN '450010'
                                WHEN c_budget_code     = 'SF' AND c_site_type = 'C12'      THEN '450150'
                                WHEN c_budget_code     = 'SF' AND c_site_type = 'C13'      THEN '450359'
                                END
                         END AS c_dest_site,
                 CASE WHEN courses.c_crs_subject = 'CED'  -- The course is a Community Education course
                           THEN 'C' -- 01142019 - jv
                      WHEN supp.program_type = 'A' -- The Program Type is Academic
                       AND EXISTS
                           ( -- Course is in the Voccational Courses (VOCCRS) Table
                             SELECT 'Y'
                             FROM   voccrs_current
                             WHERE  c_crs_subject||c_crs_number = subj||crse
                           )
                           THEN 'V' -- mark the course V for Vocational
                      WHEN supp.program_type = 'V' -- The Program Type is Vocational
                       AND ascs.c_title NOT LIKE '%Work Exp%'  -- exclude work experience courses
                       AND NOT EXISTS 
                           ( -- Course is NOT in the Voccational Courses (VOCCRS) Table
                             SELECT 'Y'
                             FROM   voccrs_current
                             WHERE  c_crs_subject||c_crs_number = subj||crse
                           )
                           THEN 'A' -- mark the course A for Academic
                      WHEN -- No Program Type was previously calculated
                           supp.program_type IS NULL THEN 'A' -- mark them A for Academic
                      ELSE supp.program_type -- Otherwise, use the existing Program Type
                      END AS c_program_type,
                 -------------------------
                 courses.c_banner_term,
                 courses.c_banner_extract
       -- SELECT *
          FROM   courses,
                 ( /**/
                   SELECT crn_key                              AS inner_crn,
                          ptrm_code                            AS c_ptrm_code,
                          CASE WHEN c_credit_ind = 'N'    -- When the course is not a credit course...
                               THEN 0                     -- ... Then return zero
                               ELSE credit_hours_low * 10 -- ... else return credit hrs w/ implied decimal.
                               END                             AS c_min_credit,
                          CASE WHEN c_credit_ind = 'N'    -- ... Same as Credit Hours Low
                               THEN 0                  
                               ELSE nvl(credit_hours_high, credit_hours_low) * 10 
                               END                             AS c_max_credit,
                          CASE WHEN c_credit_ind = 'N'    -- ... Same as Credit Hours Low
                               THEN nvl(credit_hours_high, credit_hours_low) * 10                   
                               ELSE 0
                               END                             AS c_contact_hrs,
                          begin_time1                          AS c_start_time1,
                          end_time1                            AS c_stop_time1,
                             decode(monday_ind1,    NULL, ' ', monday_ind1   )    
                          || decode(tuesday_ind1,   NULL, ' ', tuesday_ind1  )   
                          || decode(wednesday_ind1, NULL, ' ', wednesday_ind1) 
                          || decode(thursday_ind1,  NULL, ' ', thursday_ind1 )  
                          || decode(friday_ind1,    NULL, ' ', friday_ind1   )     
                          || decode(saturday_ind1,  NULL, ' ', saturday_ind1 )  
                          || decode(sunday_ind1,    NULL, ' ', sunday_ind1   )
                                                               AS c_days1,
                          bldg_code1                           AS c_bldg1,
                          ( SELECT DISTINCT b_number 
                            FROM   space_util_bldg_current
                            WHERE  b_sname = bldg_code1 
                          )                                    AS c_bldg_num1,
                          substr(room_code1, 1, 4)             AS c_room1,
                          ( SELECT DISTINCT r_occupancy
                            FROM   space_util_room_current
                            WHERE  r_abbrev = bldg_code1
                            AND    r_number = substr(room_code1, 1, 4)
                          )                                    AS c_room_max1,  
                          ( SELECT DISTINCT r_use_code
                            FROM   space_util_room_current
                            WHERE  r_abbrev = bldg_code1
                            AND    r_number = substr(room_code1, 1, 4)
                          )                                    AS c_room_type1,  
                          begin_time2                          AS c_start_time2,
                          end_time2                            AS c_stop_time2,
                             decode(monday_ind2,    NULL, ' ', monday_ind2   )    
                          || decode(tuesday_ind2,   NULL, ' ', tuesday_ind2  )   
                          || decode(wednesday_ind2, NULL, ' ', wednesday_ind2) 
                          || decode(thursday_ind2,  NULL, ' ', thursday_ind2 )  
                          || decode(friday_ind2,    NULL, ' ', friday_ind2   )     
                          || decode(saturday_ind2,  NULL, ' ', saturday_ind2 )  
                          || decode(sunday_ind2,    NULL, ' ', sunday_ind2   )
                                                               AS c_days2,
                          bldg_code2                           AS c_bldg2,
                          ( SELECT DISTINCT b_number 
                            FROM   space_util_bldg_current
                            WHERE  b_sname = bldg_code2 
                          )                                    AS c_bldg_num2,
                          substr(room_code2, 1, 4)             AS c_room2,
                          ( SELECT DISTINCT r_occupancy
                            FROM   space_util_room_current
                            WHERE  r_abbrev = bldg_code2
                            AND    r_number = substr(room_code2, 1, 4)
                          )                                    AS c_room_max2,  
                          ( SELECT DISTINCT r_use_code
                            FROM   space_util_room_current
                            WHERE  r_abbrev = bldg_code2
                            AND    r_number = substr(room_code2, 1, 4)
                          )                                    AS c_room_type2,  
                          begin_time3                          AS c_start_time3,
                          end_time3                            AS c_stop_time3,
                             decode(monday_ind3,    NULL, ' ', monday_ind3   )    
                          || decode(tuesday_ind3,   NULL, ' ', tuesday_ind3  )   
                          || decode(wednesday_ind3, NULL, ' ', wednesday_ind3) 
                          || decode(thursday_ind3,  NULL, ' ', thursday_ind3 )  
                          || decode(friday_ind3,    NULL, ' ', friday_ind3   )    
                          || decode(saturday_ind3,  NULL, ' ', saturday_ind3 )  
                          || decode(sunday_ind3,    NULL, ' ', sunday_ind3   ) 
                                                               AS c_days3,
                          bldg_code3                           AS c_bldg3,
                          ( SELECT DISTINCT b_number 
                            FROM   space_util_bldg_current
                            WHERE  b_sname = bldg_code3
                          )                                    AS c_bldg_num3,
                          substr(room_code3, 1, 4)             AS c_room3,
                          ( SELECT DISTINCT r_occupancy
                            FROM   space_util_room_current
                            WHERE  r_abbrev = bldg_code3
                            AND    r_number = substr(room_code3, 1, 4)
                          )                                    AS c_room_max3,  
                          ( SELECT DISTINCT r_use_code
                            FROM   space_util_room_current
                            WHERE  r_abbrev = bldg_code3
                            AND    r_number = substr(room_code3, 1, 4)
                          )                                    AS c_room_type3,  
                          to_char(ptrm_start_date, 'YYYYMMDD') AS c_start_date,
                          to_char(ptrm_end_date, 'YYYYMMDD')   AS c_end_date,
                          title                                AS c_title,
                          coll_code                            AS c_college,
                          dept_code                            AS c_dept,
                          levl_code1                           AS c_crs_level,
                          CASE WHEN camp_code IN ('AC1','AU1', 'ACE')  THEN 'A01'
                               WHEN camp_code = 'B8C'           THEN 'B80'
                               WHEN camp_code = 'UOS'           THEN 'C'
                               WHEN camp_code IN ('OU1', 'V01') THEN 'O01'
                               ELSE camp_code END               AS c_site_type
                   FROM   courses,
                          as_catalog_schedule
                   WHERE  crn_key = c_crn
                   AND    term_code_key = c_banner_term 
                 ) ascs,

                 (  -- Calculated using SFRSTCR and STVRSTS
                   SELECT sfrstcr_crn AS inner_crn,
                          count(DISTINCT sfrstcr_pidm) AS c_enrl
                   FROM   courses, stvrsts, sfrstcr
                   WHERE  sfrstcr_crn = c_crn
                   AND    sfrstcr_term_code = c_banner_term
                   AND    sfrstcr_rsts_code = stvrsts_code
                   AND    stvrsts_incl_sect_enrl = 'Y'
                   GROUP  BY sfrstcr_crn
                 ) enrl,
                 (                 
                   SELECT inner_crn,
                          CASE WHEN gened_gc = 1 THEN 'DV' -- Map GC to DV
                               WHEN gened_en = 1 THEN 'C'  -- Map EN to C  for certain courses
                               WHEN gened_ma = 1 THEN 'QL' -- Map MA to QL
                               WHEN gened_ai = 1 THEN 'AI' -- Map AI to AI for certain classes
                               WHEN gened_cp = 1 THEN 'CL' -- Map CP to CL
                               WHEN gened_il = 1 THEN 'IR' -- Map IL to IR                                  
                               WHEN gened_fa = 1 THEN 'FA' -- Map FA to itself
                               WHEN gened_ss = 1 THEN 'SS' -- Map SS to itself
                               WHEN gened_ls = 1 THEN 'LS' -- Map LS to itself
                               WHEN gened_ps = 1 THEN 'PS' -- Map PS to itself
                               WHEN gened_hu = 1 THEN 'HU' -- Map HU to itself
                               WHEN gened_fl = 1 THEN 'FL' -- Map FL to itself
                               END AS c_gen_ed
                   FROM   (                   
                            SELECT c_crn AS inner_crn,
                                   sum(CASE WHEN ssrattr_attr_code = 'GC' THEN 1 ELSE 0 END) AS gened_gc,
                                   sum(CASE WHEN ssrattr_attr_code = 'EN' 
                                             AND c_crs_subject = 'ENGL'
                                             AND c_crs_number IN ('1010','2010','1010D')
                                            THEN 1 ELSE 0 END)                               AS gened_en,
                                   sum(CASE WHEN ssrattr_attr_code = 'MA' THEN 1 ELSE 0 END) AS gened_ma,
                                   sum(CASE WHEN ssrattr_attr_code = 'AI' 
                                             AND (  (c_crs_subject = 'ECON' AND c_crs_number = '1740')
                                                 OR (c_crs_subject = 'POLS' AND c_crs_number = '1100')
                                                 OR (c_crs_subject = 'HIST' AND c_crs_number = '1700'))
                                            THEN 1 ELSE 0 END)                               AS gened_ai,
                                   sum(CASE WHEN ssrattr_attr_code = 'CP' THEN 1 ELSE 0 END) AS gened_cp,
                                   sum(CASE WHEN ssrattr_attr_code = 'AI' THEN 1 ELSE 0 END) AS gened_il,
                                   sum(CASE WHEN ssrattr_attr_code = 'FA' THEN 1 ELSE 0 END) AS gened_fa,
                                   sum(CASE WHEN ssrattr_attr_code = 'SS' THEN 1 ELSE 0 END) AS gened_ss,
                                   sum(CASE WHEN ssrattr_attr_code = 'LS' THEN 1 ELSE 0 END) AS gened_ls,
                                   sum(CASE WHEN ssrattr_attr_code = 'PS' THEN 1 ELSE 0 END) AS gened_ps,
                                   sum(CASE WHEN ssrattr_attr_code = 'HU' THEN 1 ELSE 0 END) AS gened_hu,
                                   sum(CASE WHEN ssrattr_attr_code = 'FL' THEN 1 ELSE 0 END) AS gened_fl
                            FROM   courses, ssrattr
                            WHERE  c_crn = ssrattr_crn (+)
                            AND    ssrattr_term_code = c_banner_term
                            GROUP  BY c_crn
                          )
                 ) gned,
                 (
                   SELECT c_crn             AS inner_crn, 
                          scbsupp_occs_code AS program_type,
                          CASE WHEN c_budget_code NOT IN ('SF','BC') 
                                AND scbsupp_ccsl_code = 'FY' 
                                    THEN 'FYE'
                               WHEN ssbsect_crse_title LIKE '%First Year%' 
                                 OR ssbsect_crse_title LIKE '%FYE%' 
                                    THEN 'FYE'
                               END          AS c_dsc_fye 
                   FROM   courses, ssbsect, scbsupp s1
                   WHERE  scbsupp_subj_code = c_crs_subject
                   AND    scbsupp_crse_numb = c_crs_number
                   AND    ssbsect_crn       = c_crn
                   AND    ssbsect_term_code = c_banner_term
                   AND    scbsupp_eff_term  =
                          ( -- Find most-recent applicable term code
                            SELECT MAX(s2.scbsupp_eff_term)
                            FROM   scbsupp s2
                            WHERE  s2.scbsupp_eff_term <= c_banner_term
                            AND    s2.scbsupp_subj_code = s1.scbsupp_subj_code
                            AND    s2.scbsupp_crse_numb = s1.scbsupp_crse_numb
                          )
                 ) supp,
                 (
                   SELECT ssvenr1_crn      AS inner_crn,
                          ssvenr1_xlst_ind AS c_xlist_ind
                   FROM   courses, ssvenr1
                   WHERE  ssvenr1_term_code = c_banner_term
                   AND    ssvenr1_crn       = c_crn
                 ) xlst
          WHERE  courses.c_crn = ascs.inner_crn (+)
          AND    courses.c_crn = enrl.inner_crn (+)
          AND    courses.c_crn = gned.inner_crn (+)
          AND    courses.c_crn = supp.inner_crn (+)
          AND    courses.c_crn = xlst.inner_crn (+)
          AND    c_enrl > 0
        )
 
 COMMIT;
 ------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------

 TRUNCATE TABLE student_courses_current;
 INSERT INTO student_courses_current 
 SELECT      sc_pidm,
             sc_id,
             sc_banner_id,
             sc_banner_term,
             sc_banner_extract,
             sc_crn,
             sc_inst,
             sc_year,
             sc_term,
             sc_extract,
             sc_crs_sbj,
             sc_crs_num,
             sc_crs_sec,
             sc_att_cr,
             sc_earned_cr,
             sc_contact_hrs,
             sc_grade,
             sc_mem_hrs,
             sc_stud_type,
             dsc_loc_recvd,
             sc_gmod_code
 FROM   (
           WITH student_courses AS
           (
             SELECT DISTINCT
                    s_pidm            AS sc_pidm,
                    s_id              AS sc_id,
                    s_banner_id       AS sc_banner_id,
                    s_banner_term     AS sc_banner_term,
                    s_banner_extract  AS sc_banner_extract,
                    c_crn             AS sc_crn,
                    c_inst            AS sc_inst,
                    c_year            AS sc_year,
                    c_term            AS sc_term,
                    c_extract         AS sc_extract,
                    c_crs_subject     AS sc_crs_sbj,
                    c_crs_number      AS sc_crs_num,
                    c_crs_section     AS sc_crs_sec,
                    c_budget_code     AS sc_budget_code,
                    sfrstcr_gmod_code AS sc_gmod_code,
                    c_ptrm_code       AS sc_ptrm_code,
                    s_entry_action    AS sc_entry_action,
                    s_high_school     AS sc_high_school,
                    c_delivery_method AS sc_delivery_method,
                    c_site_type       AS sc_site_type,
                    s_xtrct_mltplr    AS sc_xtrct_mltplr,
                    c_credit_ind      AS sc_credit_ind,
                    s_cur_prgm1       AS sc_prgm_code,
                    CASE WHEN c_credit_ind = 'N' THEN 0 
                         ELSE sfrstcr_credit_hr * 10 -- * s_xtrct_mltplr
                         END          AS sc_att_cr, -- Zeros data points during 3rd week
                    CASE WHEN c_credit_ind = 'N' THEN 0 
                         ELSE 1 END   AS sc_crdt_mltplr -- Zeros non-credit data points
             FROM   students_current,
                    courses_current,
                    sfrstcr,
                    stvrsts
             WHERE  sfrstcr_pidm           = s_pidm        -- Join SFRSTCR to the Students Table
             AND    sfrstcr_crn            = c_crn         -- Join SFRSTCR to the Courses  Table
             AND    sfrstcr_term_code      = s_banner_term -- Limit Data to Term
             AND    sfrstcr_rsts_code      = stvrsts_code  -- Join SFRSTCR to STVRSTS 
             AND    stvrsts_incl_sect_enrl = 'Y'           -- Only include rsts codes considered enrolled
           )
           SELECT student_courses.sc_pidm,
                  student_courses.sc_id,
                  student_courses.sc_banner_id,
                  student_courses.sc_banner_term,
                  student_courses.sc_banner_extract,
                  student_courses.sc_crn,
                  student_courses.sc_inst,
                  student_courses.sc_year,
                  student_courses.sc_term,
                  student_courses.sc_extract,
                  student_courses.sc_crs_sbj,
                  student_courses.sc_crs_num,
                  student_courses.sc_crs_sec,
                  student_courses.sc_att_cr,
                  grde.sc_earned_cr,
                  grde.sc_contact_hrs,
                  grde.sc_grade,
                  CAST (NULL AS VARCHAR2(1)) AS sc_mem_hrs,
                  CASE   -- When the student is in a US High School
                       WHEN sc_entry_action = 'HS'
                       -- check for summer term, default to ec when summer
                            THEN CASE WHEN sc_high_school IN ('459500','459600','459998','969999','459150','459300','459200')
                                           THEN 'EC' -- Home School students are considered EC HSCE
                                      WHEN sc_prgm_code = 'ND-SA' 
                                       AND sc_budget_code NOT IN ('BC','SF')
                                           THEN 'DC' -- Paid for by Success Academy
                                      WHEN sc_crs_sbj||sc_crs_num IN ( SELECT subj||crse FROM voccrs_current )
                                       AND sc_budget_code IN ('BC','SF')
                                           THEN 'CC' -- Paid in full with HSCE Enrollment funds
                                      WHEN sc_budget_code IN ('BC','SF') 
                                           THEN 'DC' -- Patrially paid with HSCE funds
                                           ELSE 'EC' -- Students are paying full price. 
                               END 
                       END  AS sc_stud_type,
                  CASE WHEN sc_delivery_method = 'R'
                        AND sc_crs_sec LIKE '%M%' 
                        AND sc_site_type IN ('B80','C08')
                            THEN 'A01'
                       WHEN sc_delivery_method = 'R' 
                        AND sc_crs_sec LIKE '%H%'
                        AND sc_site_type IN ('A01','C08')
                            THEN 'B80'
                       WHEN sc_delivery_method = 'R'
                        AND sc_crs_sec LIKE '%K%' 
                        AND sc_site_type IN ('A01','B80')
                            THEN 'C08' 
                       END  AS dsc_loc_recvd,
                  student_courses.sc_gmod_code
           FROM   student_courses,
                  (
                    SELECT sc_pidm   AS inner_pidm,
                           sc_crn    AS inner_crn,
                           CASE WHEN sc_ptrm_code = 'Y' OR sc_credit_ind = 'N' 
                                     THEN 0
                                WHEN swvgrde_final_grade IN ('A','A-','B+','B','B-','C+','C','C-','D+','D','D-','CR','SP','P','L','NG','T')
                                     THEN swvgrde_earned_hours * 10 * sc_xtrct_mltplr * sc_crdt_mltplr 
                                     ELSE 0 
                                END AS sc_earned_cr,
                           CASE WHEN sc_credit_ind = 'N' 
                                     THEN swvgrde_earned_hours * 10
                                     ELSE 0  
                                END  AS sc_contact_hrs,
                           CASE WHEN sc_extract = '3' OR sc_credit_ind = 'N' 
                                     THEN NULL
                                WHEN sc_extract = 'E' AND sc_ptrm_code = 'Y' -- needs more logic
                                     THEN 'IP'
                                WHEN sc_crs_sbj = 'CED' AND swvgrde_final_grade != 'AU'
                                     THEN 'NC'
                                     ELSE swvgrde_final_grade
                                END  AS sc_grade
                    FROM   student_courses, dsc.dsc_swvgrde
                    WHERE  sc_pidm = swvgrde_pidm (+)
                    AND    sc_crn  = swvgrde_crn  (+)
                    AND    swvgrde_term_code = sc_banner_term
                  ) grde
           WHERE  sc_pidm = grde.inner_pidm (+)
           AND    sc_crn  = grde.inner_crn  (+)
         );

COMMIT;



/* Manual Fixes */

