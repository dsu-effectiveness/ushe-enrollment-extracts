 /*
    This year: Replace 20172E with desired term and year select c_contact_hrs, courses.* from courses@dscir where select * from courses_current where c_crs_subject = 'CED' order by dsc_term_code desc
 */

 ----------------------------------------------------------------------------------------------------
 -- USHE S-09b --------------------------------------------------------------------------------------
 
    SELECT s_citz_code, count(*) AS "S-09b" FROM students_current GROUP BY s_citz_code ORDER BY s_citz_code;

 ----------------------------------------------------------------------------------------------------
 -- USHE S-10b --------------------------------------------------------------------------------------

    SELECT s_county_origin, count(*) AS "S-10b" FROM students_current GROUP BY s_county_origin ORDER BY s_county_origin;
    
 ----------------------------------------------------------------------------------------------------
 -- USHE S-14 --------------------------------------------------------------------------------------- 
 -- update the table name and run this script, it should match the green tab in the fix file

    SELECT s_ethnic_ipeds, count(s_ethnic_ipeds) AS "S-14"
    FROM   (
             SELECT (CASE
                 -- 1) Non-resident alien takes precedence.
                    WHEN (s_ethnic_n = 'N' OR s_citz_code = '2') THEN s_ethnic_n
                 -- 2) Hispanic comes second.
                    WHEN s_ethnic_h = 'H' THEN s_ethnic_h
                 -- 3) students with multiple ethnicities comes next.  (A,B,I,P,W only)
                    WHEN length(replace(nvl(s_ethnic_a,'')
                                      ||nvl(s_ethnic_b,'')
                                      ||nvl(s_ethnic_i,'')
                                      ||nvl(s_ethnic_p,'')
                                      ||nvl(s_ethnic_w,''),' ','')) > 1 
                    THEN 'M'
                 -- 4) The students ethnicity comes next. (A,B,I,P,W only)
                    WHEN length(replace(nvl(s_ethnic_a,'')
                                      ||nvl(s_ethnic_b,'')
                                      ||nvl(s_ethnic_i,'')
                                      ||nvl(s_ethnic_p,'')
                                      ||nvl(s_ethnic_w,''),' ','')) = 1
                    THEN        replace(nvl(s_ethnic_a,'')
                                      ||nvl(s_ethnic_b,'')
                                      ||nvl(s_ethnic_i,'')
                                      ||nvl(s_ethnic_p,'')
                                      ||nvl(s_ethnic_w,''),' ','')
                 -- 5) For students_ext112E with no declared ethnicity, U is given.
                    ELSE 'U'
                    END) AS s_ethnic_ipeds
               FROM students_current
            -- FROM students03 WHERE s_year = '2015' AND s_term = '2' AND s_extract = 'E'
          )
    GROUP BY s_ethnic_ipeds
    ORDER BY s_ethnic_ipeds;   
   
 ----------------------------------------------------------------------------------------------------   
 -- USHE S-21 ---------------------------------------------------------------------------------------
 -- both the courses and student_courses table must be compiled to investigate.
    
    SELECT custom_order, label, stu_count AS "S-21"
    FROM   ( 
             (SELECT '0'           AS label, count(s_cum_gpa_ugrad) AS stu_count, 6 AS custom_order FROM students_current WHERE s_cum_gpa_ugrad  = 0000                            ) UNION ALL
             (SELECT 'Less Than 1' AS label, count(s_cum_gpa_ugrad) AS stu_count, 5 AS custom_order  FROM students_current WHERE s_cum_gpa_ugrad >  0000 AND s_cum_gpa_ugrad < 1000 ) UNION ALL
             (SELECT'1' label, count(s_cum_gpa_ugrad) AS stu_count, 1 AS custom_order  FROM students_current WHERE s_cum_gpa_ugrad >= 1000 AND s_cum_gpa_ugrad < 2000 ) UNION ALL
          (SELECT '2'           AS label, count(s_cum_gpa_ugrad) AS stu_count, 2 AS custom_order  FROM students_current WHERE s_cum_gpa_ugrad >= 2000 AND s_cum_gpa_ugrad < 3000 ) UNION ALL
             (SELECT'3'           AS label, count(s_cum_gpa_ugrad) AS stu_count, 3 AS custom_order  FROM students_current WHERE s_cum_gpa_ugrad >= 3000 AND s_cum_gpa_ugrad < 4000 ) UNION ALL
             (SELECT'4'         AS label, count(s_cum_gpa_ugrad) AS stu_count, 4 AS custom_order  FROM students_current WHERE s_cum_gpa_ugrad  = 4000                            )
           )  ORDER  BY custom_order;

 ----------------------------------------------------------------------------------------------------
 -- USHE S-27D --------------------------------------------------------------------------------------

    SELECT s_state_origin, count(*) AS "S-27D" FROM students_current GROUP BY s_state_origin ORDER BY s_state_origin;

 ----------------------------------------------------------------------------------------------------
 -- USHE S-27E --------------------------------------------------------------------------------------

    SELECT s_country_origin, count(*) AS "S-27E" FROM students_current GROUP BY s_country_origin ORDER BY s_country_origin;
     
 ----------------------------------------------------------------------------------------------------
 -- USHE S-34 ---------------------------------------------------------------------------------------

    SELECT (
             SELECT count(S_SSID) AS "S-34"
             FROM   students_current 
             WHERE  s_entry_action IN ('FF','FH','HS')
           ) AS ssid_count,
           (
             SELECT count(s_id)   AS "S-34"
             FROM   students_current 
             WHERE  s_entry_action IN ('FF','FH','HS')
           ) as ff_fh_hs_count
    FROM DUAL;
    
 ----------------------------------------------------------------------------------------------------
 -- USHE S-36 ---------------------------------------------------------------------------------------

    SELECT '3671' AS "S-36",
           (SELECT count (distinct s_pidm) FROM students_current WHERE s_entry_action IN ('CS','FF','FH','RS','TU') AND s_act_comp > 0) AS s_act,
           (SELECT count (distinct s_pidm) FROM students_current WHERE s_entry_action IN ('CS','FF','FH','RS','TU')) AS "total"
    FROM   DUAL;
    
    -- select s_term_gpa, s_cum_gpa_ugrad, students_current.* from students_current where s_term_gpa = s_cum_gpa_ugrad and s_term_earned_cr <> s_cum_hrs_ugrad and s_cum_gpa_ugrad not in (0, 4000) and s_entry_action NOT IN ('FF','FH','TU','TG') and s_level != 'FR';
    -- select * from shrtgpa where shrtgpa_pidm = '226703';
 ----------------------------------------------------------------------------------------------------
 -- USHE S-43 ---------------------------------------------------------------------------------------
 
    SELECT *
    FROM   (
             SELECT '0'           AS label, count(*) AS "S-43" FROM students_current WHERE s_term_gpa =  0000 OR  s_term_gpa IS NULL UNION
             SELECT 'Less than 1' AS label, count(*) AS "S-43" FROM students_current WHERE s_term_gpa <  1000 AND s_term_gpa > 0000  UNION
             SELECT '1'           AS label, count(*) AS "S-43" FROM students_current WHERE s_term_gpa >= 1000 AND s_term_gpa < 2000  UNION
             SELECT '2'           AS label, count(*) AS "S-43" FROM students_current WHERE s_term_gpa >= 2000 AND s_term_gpa < 3000  UNION
             SELECT '3'           AS label, count(*) AS "S-43" FROM students_current WHERE s_term_gpa >= 3000 AND s_term_gpa < 4000  UNION
             SELECT '4'           AS label, count(*) AS "S-43" FROM students_current WHERE s_term_gpa  = 4000
           )
    ORDER BY label;    
    
 ----------------------------------------------------------------------------------------------------
 -- USHE S-44a --------------------------------------------------------------------------------------
    
    SELECT s_pell, count(*) AS "S-44a" FROM students_current GROUP BY s_pell ORDER BY s_pell;
    
 ----------------------------------------------------------------------------------------------------
 -- USHE S-45a --------------------------------------------------------------------------------------
   
    SELECT s_bia, count(*) AS "S-45a" FROM students_current GROUP BY s_bia ORDER BY s_bia DESC;
    
 ----------------------------------------------------------------------------------------------------
 -- USHE SC-08e -------------------------------------------------------------------------------------
    
    SELECT DISTINCT
           ( SELECT sum(sc_earned_cr) 
             FROM student_courses_current)/10,0
            AS "SC-08e"
    FROM student_courses_current;
    
 ----------------------------------------------------------------------------------------------------
 -- USHE C-22 ---------------------------------------------------------------------------------------
 
    SELECT c_room_type1, count(*) AS "C-22" FROM courses_current GROUP BY c_room_type1 /*ORDER BY c_room_type1 DESC*/;
 
 ----------------------------------------------------------------------------------------------------
 -- USHE C-30 ---------------------------------------------------------------------------------------

    SELECT c_room_type2, count(*) AS "C-30" FROM courses_current GROUP BY c_room_type2 /*ORDER BY c_room_type2 DESC*/;
 
 ----------------------------------------------------------------------------------------------------
 -- USHE C-38 ---------------------------------------------------------------------------------------

    SELECT c_room_type3, count(*) AS "C-38" FROM courses_current GROUP BY c_room_type3 /*ORDER BY c_room_type3 DESC*/;

 ----------------------------------------------------------------------------------------------------
 -- USHE C-47A ---------------------------------------------------------------------------------------
    SELECT
    (SELECT count(*) AS total_count FROM courses_current WHERE c_gen_ed IS NOT NULL) AS Gen_Ed_Count,
    (SELECT count(*) AS total_count FROM courses_current) AS total_count
    FROM dual;


 ----------------------------------------------------------------------------------------------------
 -- USHE C-50 ---------------------------------------------------------------------------------------
    
    SELECT c_del_model, count(*) AS "C-50" FROM courses_current GROUP BY c_del_model ORDER BY c_del_model DESC;

 ----------------------------------------------------------------------------------------------------
 -- USHE C-51b --------------------------------------------------------------------------------------
    
    SELECT c_level, count(*) "C-51b" FROM courses_current GROUP BY c_level ORDER BY c_level;

 ----------------------------------------------------------------------------------------------------
 
-- end of file
