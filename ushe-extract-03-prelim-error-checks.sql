 
 -- These queries are based on USHE's validation scripts and can serve as early warning or as a 
 -- confirmation of the results they provide us in the error fix file.
 -- -jv

 SELECT * FROM
 (

 -- A-01a --------------------------------------------------------------------------------------------
 -- Orphaned Records - s_id found in students table but not in student_course table
 /*
    SELECT 'A-01a.1' AS label, count(*) AS err_count
 -- SELECT *
    FROM   (
             SELECT DISTINCT sc_ID FROM student_courses_current
             MINUS
             SELECT DISTINCT s_id FROM students_current
           )
 UNION

    SELECT 'A-01a.2' AS label, count(*) AS err_count
 -- SELECT *
    FROM   (
             SELECT DISTINCT s_id FROM students_current
             MINUS
             SELECT DISTINCT sc_id FROM student_courses_current
           )
 UNION
 */
 -- A-03a --------------------------------------------------------------------------------------------
 -- Student IDs - s_id found in students table but not in student_course table

    SELECT 'A-03a' AS label, count(*) AS err_count
 -- SELECT *
    FROM   students_current
    WHERE  s_id NOT IN
           (
             SELECT sc_id FROM student_courses_current
           )

           -- SELECT * FROM sfrstcr WHERE sfrstcr_pidm = 273837 AND sfrstcr_term_code = 201840
           -- SELECT * FROM ssbsect WHERE ssbsect_crn  = 30101  AND ssbsect_term_code = 201830
           -- SELECT * FROM courses_current WHERE c_crn = '43213'
           -- SELECT * FROM as_catalog_schedule WHERE crn_key = 43213

 UNION

 -- A-03b --------------------------------------------------------------------------------------------
 -- Student IDs - s_id found in student_course table but not in students table

    SELECT 'A-03b' AS label, count(*) AS err_count
 -- SELECT *
    FROM   student_courses_current
    WHERE  sc_id NOT IN
           (
             SELECT s_id FROM students_current
           )

 UNION

 ----------------------------------------------------------------------------------------------------

 ----------------------------------------------------------------------------------------------------
 ----------------------------------------------------------------------------------------------------
 -- STUDENTS:                                                                                      --
 ----------------------------------------------------------------------------------------------------
 ----------------------------------------------------------------------------------------------------


 -- S-00a -------------------------------------------------------------------------------------------
 -- Duplicate Banner ID - Duplicate Records by Banner_ID

    SELECT 'S-00a' AS label, count(*) AS err_count
    FROM   (
             SELECT *
             FROM   (SELECT s_banner_id FROM students_current)
             GROUP  BY s_banner_id
             HAVING count(*) > 1
           )

 UNION

 -- S-00b -------------------------------------------------------------------------------------------
 -- Duplicate ID - Duplicate Records by S_ID

    SELECT 'S-00b' AS label, count(*) AS err_count
 -- SELECT s_id, s.*
    FROM   (
             SELECT *
             FROM   (SELECT s_id FROM students_current)
             GROUP  BY s_id
             HAVING count(*) > 1
           ) s

 UNION

 -- S-01 --------------------------------------------------------------------------------------------
 -- Institution - There should be an institution for every record.

    SELECT 'S-01' AS label, count(*) AS err_count
    FROM   students_current
    WHERE  s_inst <> '3671'

 UNION

 -- S-02 --------------------------------------------------------------------------------------------
 -- Year and Extract - There should be a year and extract for every record.

    SELECT 'S-02' AS label, count(*) AS err_count
    FROM   students_current
    WHERE  s_year    IS NULL
    OR     s_term    IS NULL
    OR     s_extract IS NULL

 UNION

 -- S-03a -------------------------------------------------------------------------------------------
 -- Freshmen ID - Every record should have an s_id for First-time freshman.

    SELECT 'S-03a' AS label, count(*) AS err_count
    FROM   students_current
    WHERE  s_entry_action IN ('FF','FH')
    AND    (s_id IS NULL OR s_id = ' ' OR s_id IN ('000000000','00000000'))

 UNION

 -- S-03b -------------------------------------------------------------------------------------------
 -- Duplicate Records - If there is a number here, then there are duplicate records.

    SELECT 'S-03b' AS label, count(*) AS err_count
 -- SELECT s_banner_id, s_last_name, s_first_name, s_gender, s.*
    FROM   (
             SELECT *
             FROM   (SELECT s_banner_id, s_last_name, s_first_name, s_gender FROM students_current)
             GROUP  BY s_banner_id, s_last_name, s_first_name, s_gender
             HAVING count(*) > 1
           ) s

 UNION

 -- S-03c -------------------------------------------------------------------------------------------
 -- Invalid S_IDs - Checking for s_ids that are not 9 digits long.

    SELECT 'S-03c' AS label, count(*) AS err_count
 -- SELECT s_id, students_current.*
    FROM   students_current
    WHERE  s_id IS NOT NULL
    AND    s_id_flag = 'S'
    AND    LENGTH(s_id) <> 9

 UNION

 -- S-03d -------------------------------------------------------------------------------------------
 -- Missing SSN with s_id_flag - If they are non-residents, they should have an institutional ID
 --                            - and s_id_flag should be flagged I.

    SELECT 'S-03d' AS label, count(*) AS err_count
 -- SELECT s_id, students_current.*
    FROM   students_current
    WHERE  s_id_flag = 'S'
    AND    (
             LENGTH(s_id) <> 9
             OR
             s_id IS NULL OR s_id = ' '
           )

 UNION

 -- S-03e -------------------------------------------------------------------------------------------
 -- Residents Missing SSN - These are the students who are flagged as residents andshould have SSNs.

 -- However, students are not required to release their SSN, so no SSNs is not uncommon.
 -- Not a useful script to run because there will always be results and nothing we can do for them.
/*
       SELECT 'S-03e' AS label, count(*) AS err_count
       FROM   students_current
       WHERE  s_citz_code = '1'
       AND    (
                s_id_flag  <> 'S'
                OR
                s_id = ' ' OR s_id IS NULL
              )
 UNION
*/

/*** Duplicate of 03A, removed on 9/24/2020 by tgroskreutz
--S-03f Every record should have an s_id. */
SELECT 'S03f' AS label, COUNT(*) AS err_count
   -- SELECT s_inst,  s_banner_id, s_last, s_first, s_gender
	FROM students_current
	WHERE s_id in ('000000000','00000000')

	UNION

 -- S-04 --------------------------------------------------------------------------------------------
 -- ID Flag - Every student should have a valid id_flag.

    SELECT 'S-04' AS label, count(*) AS err_count
 -- SELECT *
    FROM   students_current
    WHERE  s_id_flag NOT IN ('S','I')
    OR     s_id_flag IS NULL

 UNION

 -- S-04a --------------------------------------------------------------------------------------------
 -- ID Flag - Every student should have a valid id_flag.

    SELECT 'S-04a' AS label, count(*) AS err_count
 -- SELECT s_banner_id, s_id, s_id_flag, students_current.*
    FROM   students_current
    WHERE s_id_flag = 's'
	AND (S_ID IN ('078051120','111111111','123456789','219099999')
		OR (S_ID >= '987654320' AND S_ID <= '987654329')
		OR S_ID='999999999'
		OR S_ID LIKE '000%'
		OR S_ID LIKE '666%'
		OR S_ID LIKE '9%'
		OR S_ID LIKE '%[a-z]%'
		OR LENGTH(S_ID) < 9
		OR SUBSTR(S_ID,4,2) = '00'
		OR SUBSTR(S_ID,6,4) = '0000')

 UNION

 -- S-04b --------------------------------------------------------------------------------------------
 -- ID Flag - Incorrect s_id_flag.

    SELECT 'S-04b' AS label, count(*) AS err_count
 -- SELECT s_banner_id, s_id, s_id_flag, students_current.*
    FROM   students_current
    WHERE  s_id_flag = 'S'
    AND    (
                s_id = s_banner_id
             OR s_id = CASE WHEN s_banner_id LIKE '[a-z]%' THEN to_char(s_banner_id) ELSE s_banner_id END
             OR s_id LIKE '[a-z]%'
           )

 UNION


 -- S-04c --------------------------------------------------------------------------------------------
-- Incorrect id_flag. With I flag, s_id should match s_banner_id

    SELECT 'S-04c' AS label, count(*) AS err_count
 -- SELECT s_banner_id, s_id, s_id_flag, students_current.*
    FROM   students_current
    WHERE  (s_id_flag  = 'I' AND s_id != s_banner_id)
    OR     (s_id_flag != 'I' AND s_id  = s_banner_id)

 UNION

 -- S-05 ---------------------------------------------------------------------------------------------
 -- Previous ID - Default/Invalid Previous ID

    SELECT 'S-05' AS label, count(*) AS err_count
 -- SELECT s_banner_id, s_prev_id, students_current.*
    FROM   students_current
    WHERE  s_prev_id IN ('000000000','00000000','0000000','000000','00000','0000','000','00','0')

 UNION

 -- S-06a -------------------------------------------------------------------------------------------
 -- Last Name - Every student should have a last name, but international students may not.

    SELECT 'S-06a***' AS label, count(*) AS err_count
 /* SELECT s_pidm, s_banner_id, s_last_name, s_first_name, s_gender, s_ethnic,
           s_birth_dt, s_citz_code, s_regent_res, 'Confirm No Last Name' reason /**/
    FROM   students_current
    WHERE  s_last_name IS NULL
    OR     s_last_name = '.'

 UNION

    -- Standard Response
    -- International Student has no Last Name

 -- S-06b -------------------------------------------------------------------------------------------
 -- First Name - Every student should have a First name, but international students may not.

    SELECT 'S-06b*' AS label, count(*) AS err_count
 /* SELECT s_pidm, s_banner_id, s_last_name, s_first_name, s_gender, s_ethnic,
           s_birth_dt, s_citz_code, s_regent_res, 'Confirm No First Name' reason /**/
    FROM   students_current
    WHERE  s_first_name IS NULL
    OR     s_first_name = '.'

    -- Standard Response
    -- International Student has no First , Name

UNION


 -- S-08a -------------------------------------------------------------------------------------------
 -- First Name - Every student should have a First name, but international students may not.
   SELECT 'S-08b' AS label, count(*) AS err_count
   -- SELECT s_inst, s_banner_id, s_last_name, s_first_name, s_gender, s_cur_zip_code, s_citz_code, LENGTH(s_cur_zip_code) as zip_char_length
	FROM students_current
	WHERE (LENGTH(s_cur_zip_code) < 5 or s_cur_zip_code in ('00000','11111') or s_cur_zip_code like '%[a-z]%')
	and s_citz_code <> '1'

UNION



 -- S-08 --------------------------------------------------------------------------------------------
 -- Zip Code - Every student should have a zip code. Judge if there are a lot of zips missing.

    SELECT 'S-08' AS label, count(*) AS err_count
 /* SELECT s_banner_id, s_last_name, s_first_name, s_cur_zip_code, s_county_origin,
           s_state_origin, s_country_origin, s_citz_code, s_regent_res --*/
    FROM   students_current
    WHERE  s_cur_zip_code IS NULL

 UNION

--S-08b  --------------------------------------------------------------------------------------------
-- Every student should have a zip code.  Judge if there are a lot of zips missing.''
--Added s_citz_code and not in statement to where clause on 9/24/2020 by tgroskreutz
SELECT 'S-08b' AS label, count(*) AS err_count
--SELECT s_inst, s_banner_id, s_last_name, s_first_name, s_gender, s_cur_zip_code, s_citz_code, LENGTH(s_cur_zip_code)
	FROM students_current
	WHERE (LENGTH(s_cur_zip_code) < 5 or s_cur_zip_code like '%[a-z]%' or s_cur_zip_code not in ('00000','11111'))
	and s_citz_code <> '1'

	UNION

 -- S-09 --------------------------------------------------------------------------------------------
 -- Citizenship Code - There should be a s_citz_code for every record.

    SELECT 'S-09' AS label, count(*) AS err_count
    --SELECT a.s_pidm, s_banner_id, s_last_name, s_first_name, s_ethnic_n, s_citz_code, stvcitz_desc
    FROM   students_current a
    LEFT JOIN stvcitz b ON b.stvcitz_code = a.s_citz_code
    WHERE  s_citz_code IS NULL

 UNION

 -- S-09a -------------------------------------------------------------------------------------------
 -- Citizenship Code - There should be a s_citz_code for every record.

    SELECT 'S-09a' AS label, count(*) AS err_count
 -- SELECT s_ethnic_n, s_citz_code, stvcitz_desc, dsc.f_get_race_ethn(s_pidm) AS ethn, students_current.*
    FROM   students_current, stvcitz
    WHERE  stvcitz_code = s_citz_code
    AND   ((s_citz_code  = '2'  AND s_ethnic_n IS NULL)
    OR     (s_citz_code IS NULL AND s_ethnic_n  = 'N')
    OR     (s_citz_code != '2'  AND s_ethnic_n  = 'N')
    OR     (s_citz_code  = '2'  AND s_ethnic_n != 'N'))

 UNION

 -- S-10 --------------------------------------------------------------------------------------------
 -- County Code - There should be a county origin for every record.

    SELECT 'S-10' AS label, count(*) AS err_count
 -- SELECT s_county_origin, students_current.*
    FROM   students_current
	  WHERE  s_county_origin IS NULL
    OR     s_county_origin NOT IN ('UT001','UT003','UT005','UT007','UT009','UT011','UT013','UT015',
                                   'UT017','UT019','UT021','UT023','UT025','UT027','UT029','UT030',
                                   'UT031','UT033','UT035','UT037','UT039','UT041','UT043','UT045',
                                   'UT047','UT049','UT051','UT053','UT055','UT057','UT097','UT099')

 UNION

 -- S-11a -------------------------------------------------------------------------------------------
 -- State Codes - Checks where the state is UT but county is out of state.

    SELECT 'S-11a' AS label, count(*) AS err_count
 -- SELECT s_state_origin, s_county_origin, s_country_origin, s_cur_zip_code, students_current.*
    FROM   students_current
    WHERE  s_state_origin = 'UT'
    AND    s_county_origin IN ('UT097','UT099')

    -- select * from spraddr where spraddr_pidm = 274310

 UNION

 -- S-11b -------------------------------------------------------------------------------------------
 -- State Codes - Checks where the state is not UT but county is not out of state.

    SELECT 'S-11b' AS label, count(*) AS err_count
 -- SELECT s_county_origin, s_state_origin, s_county_origin, s_country_origin, students_current.*
    FROM   students_current
    WHERE  s_state_origin <> 'UT'
    AND    s_county_origin NOT IN ('UT097','UT099')

 UNION

 -- S-12 --------------------------------------------------------------------------------------------
 -- Birth Date - There should be a birth date for every record.

    SELECT 'S-12' AS label, count(*) AS err_count
 /* SELECT s_pidm, s_banner_id, s_last_name, s_first_name, s_gender, s_ethnic, s_birth_dt, s_citz_code, s_regent_res,
    'Missing Birth Date' reason /**/
    FROM   students_current
    WHERE  s_birth_dt IS NULL
    OR     s_birth_dt LIKE '%00000%'

 UNION

 -- S-13a -------------------------------------------------------------------------------------------
 -- Gender - Please resolve any missing OR invalid values.

    SELECT 'S-13a' AS label, count(*) AS err_count
 /* SELECT s_pidm, s_banner_id, s_last_name, s_first_name, s_gender, s_ethnic, s_birth_dt, s_citz_code, s_regent_res,
    'Invalid Gender' reason /**/
    FROM   students_current
    WHERE  s_gender  is null

 UNION

 -- S-13b --------------------------------------------------------------------------------------------
 -- Gender - Gender Change

    SELECT 'S-13b*' AS label, count(*) AS err_count
 /* SELECT s_pidm, s_id, s_banner_id, s_last_name, s_first_name, s_gender as new_gender,
           ( SELECT DISTINCT s3.s_gender
             FROM   students03@dscir s3
             WHERE  s_pidm = dsc_pidm
             AND    s1.s_gender <> s3.s_gender
           ) AS old_gender --*/
    FROM   students_current s1
    WHERE  EXISTS
           (
             SELECT *
             FROM   students03_copy s2
             WHERE  dsc_pidm    = s_pidm
             AND    banner_term = s_banner_term
             AND    s2.s_banner_id = s1.s_banner_id
             AND    s2.s_gender   <> s1.s_gender
             AND    s2.s_gender   <> 'N'
           )

 UNION

 -- S-14a -------------------------------------------------------------------------------------------
 -- Ethnicity - Please resolve any invalid codes.

    SELECT 'S-14' AS label, ("S-14a"+"S-14b"+"S-14h"+"S-14i"+"S-14p"+"S-14n"+"S-14u"+"S-14w") AS err_count
    FROM   (
             SELECT
               (SELECT count(*) FROM students_current WHERE s_ethnic_a NOT IN ('A',' ')) AS "S-14a",
               (SELECT count(*) FROM students_current WHERE s_ethnic_b NOT IN ('B',' ')) AS "S-14b",
               (SELECT count(*) FROM students_current WHERE s_ethnic_h NOT IN ('H',' ')) AS "S-14h",
               (SELECT count(*) FROM students_current WHERE s_ethnic_i NOT IN ('I',' ')) AS "S-14i",
               (SELECT count(*) FROM students_current WHERE s_ethnic_p NOT IN ('P',' ')) AS "S-14p",
               (SELECT count(*) FROM students_current WHERE s_ethnic_n NOT IN ('N',' ')) AS "S-14n",
               (SELECT count(*) FROM students_current WHERE s_ethnic_u NOT IN ('U',' ')) AS "S-14u",
               (SELECT count(*) FROM students_current WHERE s_ethnic_w NOT IN ('W',' ')) AS "S-14w"
             FROM dual
           )

 UNION

 -- S-14ua ------------------------------------------------------------------------------------------
 -- Ethnicity Unspecified - Ethnicity marked unspecified when already specified.

    SELECT 'S-14ua' AS label, count(*) AS err_count
    FROM   students_current
    WHERE  s_ethnic_u NOT IN ('U',' ')
    AND    (
                s_ethnic_a NOT IN ('A',' ')
             OR s_ethnic_b NOT IN ('B',' ')
             OR s_ethnic_h NOT IN ('H',' ')
             OR s_ethnic_i NOT IN ('I',' ')
             OR s_ethnic_p NOT IN ('P',' ')
             OR s_ethnic_n NOT IN ('N',' ')
             OR s_ethnic_w NOT IN ('W',' ')
          )

 UNION

 -- S-15 --------------------------------------------------------------------------------------------
 -- Regent Residency Status - There should be a valid residency status for each record.

    SELECT 'S-15' AS label, count(*) AS err_count
    FROM   students_current
    WHERE  s_regent_res NOT IN ('A','G','N','M','R')

 UNION

 -- S-16a -------------------------------------------------------------------------------------------
 -- CIP Codes - There should be a valid s_cur_cip_ushe for each record.

    SELECT 'S-16a' AS label, count(*) AS err_count
 -- SELECT *
    FROM   students_current
    WHERE  s_deg_intent <> '0'
    AND    lpad(s_cur_cip1,'6','0')     NOT IN (SELECT cip_code FROM cip2010)
    AND    lpad(s_cur_cip_ushe,'6','0') NOT IN (SELECT cip_code FROM cip2010)

 UNION

 -- S-17a -------------------------------------------------------------------------------------------
 -- Entry Action - Registration Status - Check for valid registration status values.

    SELECT 'S-17a' AS label, count(*) AS err_count
 -- SELECT s_entry_action, students_current.*
    FROM   students_current
    WHERE  s_entry_action NOT IN ('HS','FH','FF','TU','NG','TG','CS','RS','NM','CG','RG','CE','NC')

 UNION

 -- S-17b -------------------------------------------------------------------------------------------
 -- Entry Action - Check if graduate students are marked as first-year freshmen.

    SELECT 'S-17b' AS label, count(*) AS err_count
    FROM   students_current
    WHERE  s_entry_action IN ('HS','FF','FH','FS')
    AND    s_level IN ('GM','GD','GN','PM','PO','PL')

 UNION

 -- S-17c -------------------------------------------------------------------------------------------
 -- Entry Action - Check for students with academic history marked as first-time freshmen.

    SELECT 'S-17c' AS label, count(*) AS err_count
 -- SELECT s_entry_action, stu.*
    FROM   students_current stu
    WHERE  s_entry_action IN ('FF','FH')
    AND    EXISTS
           (
             SELECT s.dsc_pidm
             FROM   students03_copy s, stvterm t
             WHERE  s.banner_term = stvterm_code
             AND    s_pidm = s.dsc_pidm
             AND    substr(stu.s_hsgrad_dt,0,4) <= substr(s.dsc_term_code,0,4)
             AND    s.s_extract      = 'E'
             AND    s.s_term        != '1'
             AND    s.s_entry_action NOT IN ('CE','HS','NC','NM')
             AND    t.stvterm_start_date > to_date(s_hsgrad_dt,'YYYYMMDD')
           )

           -- SELECT * from student_courses_copy WHERE dsc_pidm = 91110381

 UNION

 -- S-17d -------------------------------------------------------------------------------------------
 -- Entry Action - Check for students with academic history marked as first-time freshmen less than
 --              - one year out of high school.

    SELECT 'S-17d' AS label, count(*) AS err_count
 -- SELECT s_pidm, s_banner_id, s_last_name, s_first_name, s_entry_action, s_high_school, s_hsgrad_dt
    FROM   students_current stu
    WHERE  s_entry_action    IN ('FH')
    AND    s_high_school NOT IN ('450351','459300')
    AND    EXISTS
           (
             SELECT 'Y'
          -- SELECT *
             FROM   students03_copy s, courses_copy c, student_courses_copy sc, stvterm
             WHERE  s_pidm           = s.dsc_pidm       AND s.dsc_pidm      = sc.dsc_pidm
             AND    s.dsc_term_code  = sc.dsc_term_code AND c.dsc_term_code = sc.dsc_term_code
             AND    s.banner_term    = stvterm_code     AND s.banner_term   = s_banner_term
             AND    c.dc_crn         = sc.dsc_crn
             AND    s.s_extract      = 'E'
             AND    s.s_term        != '1'
             AND    upper(sc_grade) != 'W'
             AND    s.s_entry_action NOT IN ('HS')
             AND    s_high_school    NOT IN ('450351','459300') -- GED
             AND    to_char(stvterm_start_date,'YYYYMMDD') > stu.s_hsgrad_dt
             AND    s.banner_term < stu.s_banner_term
           )

 UNION

 -- S-17e -------------------------------------------------------------------------------------------
 -- Entry Action - This query shows the age of students who are taking classes from the institution
 --              - while still in high school. Generally these students are under 20, but not always.

    SELECT 'S-17e' AS label, count(*) AS err_count
 /* SELECT s_pidm               AS pidm,
           s_banner_id          AS banner_id,
           f_format_name(s_pidm,'LFMI')
                                AS full_name,
           s_styp               AS stu_type,
           s_gender             AS gender,
           s_age                AS age,
           to_date(s_birth_dt, 'YYYYMMDD')
                                AS birth_dt,
           to_date(s_hsgrad_dt,'YYYYMMDD')
                                AS hsgrad_dt,
           s_cur_prgm1          AS curr_prgm,
           'Invalid HS Graduation and/or Birth Date'
                                AS reason /**/
    FROM   students_current, stvsbgi
    WHERE  s_high_school  = stvsbgi_code
    AND    s_entry_action = 'HS'
    AND    s_age          > '20'
    AND    s_high_school NOT IN ('206318','459150','450351') -- Non-standard High Schools

 UNION

 -- S-17f -------------------------------------------------------------------------------------------
 -- Entry Action - First-time Freshmen under 18. These students may be 'FH' instead of 'FF'.

    SELECT 'S-17f' AS label, count(*) AS err_count
 -- SELECT s_pidm, s_banner_id, s_last_name, s_first_name, s_age, s_hsgrad_dt, s_entry_action
    FROM   students_current, stvterm
    WHERE  stvterm_code   = s_banner_term
    AND    s_entry_action = 'FF'
    AND    s_age         <  '18'
    AND    s_hsgrad_dt   >= to_char(stvterm_start_date,'YYYYMMDD')-10000

 UNION

 -- S-17g -------------------------------------------------------------------------------------------
 -- Entry Action - First-time Freshmen out of HS over 20. These students may be 'FF' instead of 'FH'.
 --              - Need to rule out GED(a) and Non-standard High Schools(b).

    SELECT 'S-17g' AS label, count(*) AS err_count
 /* SELECT s_pidm, s_banner_id, f_format_name(s_pidm,'LFMI') AS full_name, s_styp, s_gender, s_age, s_entry_action,
    to_date(s_birth_dt,'YYYYMMDD') birth_date, to_date(s_hsgrad_dt,'YYYYMMDD') hsgrad_dt, s_high_school, stvsbgi_desc,
    'Double-Check DOB and HS Grad Date' AS reason
 /**/
    FROM   students_current LEFT JOIN stvsbgi ON stvsbgi_code = s_high_school
    WHERE  s_entry_action = 'FH'
    AND    s_age > '20'
    AND    s_high_school NOT IN ('459300','459050','459150','450351','394413','290113')

    --select * from students_current
 UNION

 -- S-17h -------------------------------------------------------------------------------------------
 -- Entry Action - Traditional students attending concurrent enrollment classes.

    SELECT 'S-17h' AS label, count(*) AS err_count
 /* SELECT s_pidm, s_banner_id, s_last_name, s_first_name, c_crn, c_crs_subject, c_crs_number, c_crs_section, s_styp, s_hsgrad_dt,
           'Non-HS student in an HSCE Section' AS reason /**/
    FROM   students_current s, courses_current c, student_courses_current sc
    WHERE  s_pidm = sc_pidm AND c_crn  = sc_crn
    AND    c_budget_code IN ('BC','SF')
    AND    s_entry_action != 'HS'

 UNION

 -- S-17i -------------------------------------------------------------------------------------------
 -- Entry Action - Entry Action Changes.

    SELECT 'S-17i*' AS label, count(*) AS err_count
 -- SELECT tw.s_entry_action as tw_ea, eot.s_entry_action as eot_ea, tw.*, eot.*
    FROM   students_current eot, students03_copy tw
    WHERE  s_pidm = dsc_pidm
    AND    tw.s_year = eot.s_year
    AND    tw.s_term = eot.s_term
    AND    tw.s_extract = '3'
    AND    tw.s_entry_action <> eot.s_entry_action

 UNION

 -- S-18 --------------------------------------------------------------------------------------------
 -- Class Level - There should be a valid level for each student.

    SELECT 'S-18' AS label, count(*) AS err_count
 -- SELECT *
    FROM   students_current
    WHERE  s_level NOT IN ('FR','SO','JR','SR','UG') -- undergraduate
    AND    s_level NOT IN ('GM','GD','GN','GG')      -- post-graduate (bachelors)
 -- OR     s_level NOT IN ('PM','PO','PI')           -- post-graduate (masters)

 UNION

 -- S-19 --------------------------------------------------------------------------------------------
 -- Degree Intent - There should be a valid degree intent for each student.

    SELECT 'S-19' AS label, count(*) AS err_count
 -- SELECT s_pidm, s_banner_id, s_last_name, s_first_name, s_cur_majr1, s_cur_prgm1, s_deg_intent--, students_current.*
    FROM   students_current
    WHERE  s_deg_intent NOT IN ('0','2','3','4','M')

 UNION

 -- S-19a -------------------------------------------------------------------------------------------
 -- Invalid Degree Intent?

    SELECT 'S-19a' AS label, count(*) AS err_count
 /* SELECT s_pidm, s_banner_id, s_first_name, s_last_name, s_cur_prgm1, s_entry_action, s_age, s_hsgrad_dt,
           'Invalid Degree Intent or Entry Action' AS reason /**/
 -- SELECT *
    FROM   students_current
    WHERE  s_deg_intent != '0'
 -- AND    s_entry_action IN ('HS')
    AND    s_entry_action IN ('NM','HS')

 UNION

 -- S-19b -------------------------------------------------------------------------------------------
 -- Major / Program - Traditional students attending concurrent enrollment classes.

    SELECT 'S-19b' AS label, count(*) AS err_count
 /* SELECT s_pidm, s_banner_id, s_first_name, s_last_name, s_cur_prgm1, s_deg_intent, s_entry_action, s_hsgrad_dt, s_styp, s_age,
           'Degree Intent doesn''t match Entry Action' AS reason /**/
    FROM   students_current
    WHERE  s_deg_intent = '0'
    AND    s_entry_action NOT IN ('NM','HS')

 UNION

 -- S-21 --------------------------------------------------------------------------------------------
 -- Cumulative Undergraduate GPA - Checking if any students are lacking undergraduate cumulative gpa.
 -- Use front-end SHACRSE for details.

    SELECT 'S-21' AS label, count(*) AS err_count
 -- SELECT *
    FROM   students_current
    WHERE  (s_cum_gpa_ugrad = 0 OR  s_cum_gpa_ugrad IS NULL)
    AND    (s_cum_hrs_ugrad > 0 AND s_cum_hrs_ugrad IS NOT NULL)
    AND    EXISTS
           (
             SELECT '1'
             FROM   shrtgpa
             WHERE  shrtgpa_pidm = s_pidm
             AND    shrtgpa_gpa_type_ind = 'I'
             AND    shrtgpa_levl_code IN ('NC','UG')
             AND    shrtgpa_quality_points > 0
           )
 UNION

 -- S-22 --------------------------------------------------------------------------------------------
 -- Cumulative Graduate GPA - Checking if undergraduate students have any hours or GPA in
 --                         - graduate hours or GPA. This query is not needed for DSU.
 /*
    SELECT 'S-22' AS label, count(*) AS err_count
    FROM   students_current
    WHERE  s_level NOT IN ('GM','GD','GN','PM','PO','PL')
    AND    s_cum_gpa_grad > 0

 UNION
 */
 -- S-25 --------------------------------------------------------------------------------------------
 -- Part-time/Full-time - There should be a valid code for each student.

    SELECT 'S-25' AS label, count(*) AS err_count
    FROM   students_current
    WHERE  s_pt_ft NOT IN ('F','P')

 UNION

 -- S-26 ---------------------------------------------------------------------------------------------
 -- Age - Students age 10 and under?

    SELECT 'S-26' AS label, count(*) AS err_count
 /* SELECT s_pidm, s_banner_id, s_first_name, s_last_name, s_cur_prgm1, s_age, s_birth_dt, s_hsgrad_dt,
           'Verify Birth Date (Student age 10 and under)' AS reason /**/
    FROM   students_current
    WHERE  s_age NOT BETWEEN to_number(substr(s_banner_term,1,4)) - to_number(substr(s_birth_dt,1,4)) - 1
                         AND to_number(substr(s_banner_term,1,4)) - to_number(substr(s_birth_dt,1,4)) + 1

 UNION

 -- S-26x --------------------------------------------------------------------------------------------
 -- Age - Students age 10 and under?

    SELECT 'S-26x' AS label, count(*) AS err_count
 /* SELECT s_pidm, s_banner_id, s_first_name||' '||s_last_name, s_styp, s_gender, s_age, s_birth_dt, s_hsgrad_dt, s_high_school,
           'Verify Birth Date (Student age 10 and under)' AS reason /**/
    FROM   students_current
    WHERE  s_age <= 10
    OR     s_age >= 100

 UNION

 -- S-27a -------------------------------------------------------------------------------------------
 -- Country Origin - Check for state codes within the US, but the country code is not US.

    SELECT 'S-27a' AS label, count(*) AS err_count
 -- SELECT s_county_origin, s_state_origin, s_country_origin, students_current.*
    FROM   students_current
    WHERE  s_country_origin <> 'US'
    AND    (
             (s_country_origin  = 'US' AND s_state_origin   = 'XX')
             OR
             (s_country_origin != 'US' AND s_county_origin != 'UT097')
             OR
             (s_country_origin  = 'US' AND s_state_origin  != 'UT' AND s_county_origin =  'UT099')
           )
 UNION

 -- S-27b -------------------------------------------------------------------------------------------
 -- Country Origin - Check for state/county codes outside US, but the country code is US.

    SELECT 'S-27b' AS label, count(*) AS err_count
    FROM   students_current
    WHERE  s_state_origin   = 'XX'
    AND    s_county_origin  = 'UT097'
    AND    s_country_origin = 'US'

 UNION

 -- S-27c -------------------------------------------------------------------------------------------
 -- Country Origin - Where there is a country code not in the FIPS list.

    SELECT 'S-27c' AS label, count(*) AS err_count
 -- SELECT s_pidm, s_banner_id, s_last_name, s_first_name, s_county_origin, s_state_origin, s_country_origin
    FROM   students_current
    WHERE  s_country_origin NOT IN (SELECT iso_code FROM country_iso)

 UNION

 -- S-28 --------------------------------------------------------------------------------------------
 -- High School Codes - Should be a valid high school code for each student. We are mainly concerned
 --                   - with zeroes AND invalid 45 series high schools.  Anything not 45% comes from
 --                   - out of state unless it is invalid.

    SELECT 'S-28*' AS label, count(*) AS err_count
 /* SELECT s_pidm, s_banner_id, dsc.f_format_name(s_pidm,'LFMI'), s_styp, s_gender, s_age, s_high_school, s_hsgrad_Dt,
    'Invalid High School' AS reason /**/
 -- SELECT distinct s_high_school
    FROM   students_current
    WHERE  (
             s_high_school IN ('459994','459993','459997','459999','459996',
                               '999999','459995','960000','459998','969999')
             OR     ( s_high_school NOT IN (SELECT sorhsch_sbgi_code FROM sorhsch)
                      AND
                      s_high_school NOT IN ('459000','459050','459100','459150','459200',
                                            '459250','459300','459400','459500','459600',' ')
                    )
              OR    (s_high_school IS NULL AND s_state_origin = 'UT')
              OR     s_high_school = ' '
            )
  -- AND    s_entry_action != 'NM'
  -- AND    s_age < 25

 UNION

 -- S-31 --------------------------------------------------------------------------------------------
 -- Membership Hours - DSU does not have membership hours

    SELECT 'S-31' AS label, count(*) AS err_count
    FROM   students_current
    WHERE  s_cum_mem_hrs <> 0

 UNION

 -- S-34 --------------------------------------------------------------------------------------------
 -- SSIDs - Our hope is for every freshmen and high school student from Utah to have an SSID.
 --       - There are no actions we can take to increase the number of SSIDs included.

    SELECT 'S-34' AS label, count(*) AS err_count
 -- SELECT s_ssid, students_current.*
    FROM   students_current
    WHERE  s_entry_action IN ('HS','FH','FF')
    AND    s_ssid IN
           (
             SELECT count(s2.s_ssid)
             FROM   students_current s2
             GROUP  BY s_pidm
             HAVING count(s2.s_ssid) > 1
           )
 UNION

 -- S-34b -------------------------------------------------------------------------------------------
 -- SSIDs - Check for any invalid values in the s_ssid field.

    SELECT 'S-34b' AS label, count(*) AS err_count
 -- SELECT s_ssid, students_current.*
    FROM   students_current
    WHERE  s_ssid != ' ' AND s_ssid IS NOT NULL
    AND    (
             s_ssid LIKE '%.%'
             OR s_ssid LIKE '%*%'
             OR substr(s_ssid,0,1) NOT BETWEEN '1' AND '2'
             OR LENGTH(s_ssid) <> '7'
           )
 UNION

 -- S-35b -------------------------------------------------------------------------------------------
 -- Banner IDs - There should be a valid institutionally assigned ID for all records.
 --            - This institution has an 8 digit institutional ID.

    SELECT 'S-35b' AS label, count(*) AS err_count
    FROM   students_current
    WHERE  LENGTH(s_banner_id) <> '9'

 UNION

 -- S-36a -------------------------------------------------------------------------------------------
 -- ACT Scores - Should be between 1 and 36

    SELECT 'S-36a' AS label, count(*) AS err_count
 -- SELECT s_pidm, s_banner_id, s_last_name, s_first_name, s_birth_dt, s_act_comp, s_act_engl, s_act_math, s_act_read, s_act_sci
    FROM   students_current
    WHERE  s_act_comp NOT BETWEEN 1 AND 36
    OR     s_act_engl NOT BETWEEN 1 AND 36
    OR     s_act_math NOT BETWEEN 1 AND 36
    OR     s_act_read NOT BETWEEN 1 AND 36
    OR     s_act_sci  NOT BETWEEN 1 AND 36

 UNION

 -- S-42 -------------------------------------------------------------------------------------------
 -- Invalid High School Grad Date - Dates should all be 8 digits in length

    SELECT 'S-42*' AS label, count(*) AS err_count
 -- SELECT s_banner_id, s_last_name, s_first_name, s_hsgrad_dt, s_birth_dt, s_citz_code, s_entry_action, s_styp, s_cur_prgm1, s_age
    FROM   students_current
    WHERE  LENGTH(s_hsgrad_dt) <> '8'
    OR    s_hsgrad_dt IS NULL

 UNION

 -- S-43a -------------------------------------------------------------------------------------------
 -- Missing Term GPA - See how many students earned 0 gpa for this term.

    SELECT 'S-43a' AS label, count(*) AS err_count
 -- SELECT *
    FROM   students_current
    WHERE  (s_term_gpa IS NULL OR s_term_gpa = 0)
    AND    EXISTS
           (
             SELECT '1'
             FROM   shrtgpa@proddb
             WHERE  shrtgpa_pidm = s_pidm
             AND    shrtgpa_gpa_type_ind = 'I'
             AND    shrtgpa_levl_code IN ('NC','UG')
             AND    shrtgpa_quality_points > 0
             AND    shrtgpa_term_code = s_banner_term
           )
 UNION

 -- S-43b -------------------------------------------------------------------------------------------
 -- Matching GPA S_CUM_GPA_UGRAD = S_TERM_GPA
    SELECT 'S-43b' AS label, count(*) AS err_count
 -- SELECT distinct s_inst, s_id, s_banner_id, s_level, s_entry_action as s_reg_status, s_cum_gpa_ugrad, s_term_gpa
    FROM   students_current s
    WHERE s_cum_gpa_ugrad not in ('0','4000')
    AND s_cum_gpa_ugrad = s_term_gpa
    AND s_level != 'FR'
    AND s_entry_action not in ('FF', 'FH', 'TU', 'TG')

 UNION

 -- S-46 --------------------------------------------------------------------------------------------
 -- Missing College - See how many students have the same term gpa and cumulative gpa.
    -- gpa groups are calculated separately, matches are purely coincidental.

 --     WHERE  s_cur_coll_code1 IS NULL
 --
 --  UNION*/

 -- S-49a -------------------------------------------------------------------------------------------
 -- Missing CIP 2

    SELECT 'S-49a*' AS label, count(*) AS err_count
 -- SELECT s_banner_id, s_last_name, s_first_name,  s_cur_prgm2, s_cur_cip2, s_cur_coll_code2, s_cur_majr2, students_current.*
    FROM   students_current
    WHERE (s_cur_majr2 IS NOT NULL AND s_cur_cip2 IS NULL    )
    OR    (s_cur_majr2 IS NULL     AND s_cur_cip2 IS NOT NULL)

--    select * from stvmajr where stvmajr_code = 'ASOC'
--    select * from dsc_programs_current where majr_code = 'ASOC'

 UNION

 ----------------------------------------------------------------------------------------------------

 ----------------------------------------------------------------------------------------------------
 ----------------------------------------------------------------------------------------------------
 -- COURSES:                                                                                       --
 ----------------------------------------------------------------------------------------------------
 ----------------------------------------------------------------------------------------------------

 -- C-00 --------------------------------------------------------------------------------------------
 -- Duplicate Records - Duplicate Records by Subject, Course Number and Section.

    SELECT 'C-00' AS label, count(*) AS err_count
    FROM   (
             SELECT *
             FROM   (SELECT c_crs_subject, c_crs_number, c_crs_section FROM courses_current)
             GROUP  BY c_crs_subject, c_crs_number, c_crs_section
             HAVING count(*) > 1
           )
 UNION

 -- C-01 --------------------------------------------------------------------------------------------
 -- Institution - There should be an institution for every record.

    SELECT 'C-01' AS label, count(*) AS err_count
    FROM   courses_current
    WHERE  c_inst <> '3671'

 UNION

 -- C-02 --------------------------------------------------------------------------------------------
 -- Year and Extract - There should be a year and extract for every record.

    SELECT 'C-02' AS label, count(*) AS err_count
    FROM   courses_current
    WHERE  c_year    IS NULL
    OR     c_term    IS NULL
    OR     c_extract IS NULL

 UNION

 -- C-09 --------------------------------------------------------------------------------------------
 -- Line Item. Check for valid values in c_line_item.

    SELECT 'C-09' AS label, count(*) AS err_count
    FROM   courses_current
    WHERE  upper(c_line_item) NOT IN ('A','B','C','D','E','F','G','H','I','K',
                                      'L','M','N','N','P','Q','R','S','T','X')
 UNION

 -- C-10 --------------------------------------------------------------------------------------------
 -- Site Type - Check for valid values in c_site_type.

    SELECT 'C-10' AS label, count(*) AS err_count
 /* SELECT c_banner_term, c_crn, c_crs_subject, c_crs_number, c_crs_section, c_schd_code, c_budget_code, c_site_type,
           'Invalid/Missing Campus Code' AS reason /**/
    FROM   courses_current
    WHERE  (
                 c_site_type NOT IN ('A01','G','H','SHO','SHH','Z')
	           AND c_site_type NOT LIKE 'B%'
	           AND c_site_type NOT LIKE 'C%'
	           AND c_site_type NOT LIKE 'D%'
	           AND c_site_type NOT LIKE 'E%'
	           AND c_site_type NOT LIKE 'F%'
	           AND c_site_type NOT LIKE 'O%'
           )
    OR     c_site_type IS NULL

 UNION

 -- C-11 --------------------------------------------------------------------------------------------
 -- Budget Codes - Ensure that there are budget codes for all course files.

    SELECT 'C-11' AS label, count(*) AS err_count
 /* SELECT c_banner_term, c_crn, c_crs_subject, c_crs_number, c_crs_section, c_schd_code, nvl(c_budget_code,'NULL'), c_enrl,
           'Missing Budget Code' AS reason /**/
    FROM   courses_current
    WHERE  c_budget_code NOT IN ('BA','BC','BU','BV','BY','SD','SF','SM','SP','SQ')
    OR     c_budget_code IS NULL

 UNION

 -- C-12 --------------------------------------------------------------------------------------------
 -- Delivery Method - Check for valid values in c_delivery_method.

    SELECT 'C-12' AS label, count(*) AS err_count
    --SELECT c_banner_term, c_crn, c_crs_subject, c_crs_number, c_crs_section, c_schd_code, c_delivery_method, c_enrl, 'Check delivery method' AS reason
    FROM   courses_current
    WHERE  c_delivery_method NOT IN ('P','H','T','R','I','B','C', 'V')
    OR     c_delivery_method IS NULL


 UNION

 -- C-13 --------------------------------------------------------------------------------------------
 -- Program Type - Check for valid values in c_program_type

    SELECT 'C-13' AS label, count(*) AS err_count
    FROM   courses_current
    WHERE  c_program_type NOT IN ('A','V','P','C')
    OR     c_program_type IS NULL

 UNION

 -- C-13a -------------------------------------------------------------------------------------------
 -- Program Type - Check for V c_program_type not in Perkins List (should be A?)

    SELECT 'C-13a' AS label, count(*) AS err_count
 -- SELECT *
    FROM   courses_current
    WHERE  c_program_type = 'V'
    AND    c_crs_subject||substr(c_crs_number,1,4) NOT IN (SELECT subj||substr(crse,1,4) FROM voccrs_current)

 UNION

 -- C-13b -------------------------------------------------------------------------------------------
 -- Program Type - Check for A c_program_type in Perkins List (should be V?)

    SELECT 'C-13b' AS label, count(*) AS err_count
 -- SELECT *
    FROM   courses_current
    WHERE  c_program_type = 'A'
    AND    c_crs_subject||c_crs_number IN (SELECT subj||crse FROM voccrs_current)


 UNION

 -- C-14 ---------------------------------------------------------------------------------------------
 -- Credit Indicator - Check for valid values for c_credit_ind.

    SELECT 'C-14' AS label, count(*) AS err_count
    FROM   courses_current
    WHERE  c_credit_ind NOT IN ('C','N')
    OR     c_credit_ind IS NULL

 UNION

 -- C-14b --------------------------------------------------------------------------------------------
 -- Credit Indicator - Check for valid values for c_credit_ind for 3rd Week Extracts.

    SELECT 'C-14b' AS label, count(*) AS err_count
 -- SELECT c_crn, c_crs_subject, c_crs_number, c_crs_section, c_credit_ind, c_enrl
    FROM   courses_current
    WHERE  c_credit_ind = 'N'
    AND    c_extract    = '3'

 UNION

 --C-22 ----------------------------------------------------------------------------------------------
 /*
    SELECT 'C-22' AS label, count(*) AS err_count
 -- SELECT c_credit_ind, c_instruct_type, c_program_type, courses_current.*
    FROM   courses_current
    WHERE  c_credit_ind        = 'N'
    AND    c_extract           = 'E'
    AND    c_instruct_type    != 'LAB'
    AND    c_crs_subject      != 'CED'
    AND    c_program_type NOT IN ('P','V')

 UNION
 */
 --C-14c ---------------------------------------------------------------------------------------------

    SELECT 'C-14c' AS label, count(*) AS err_count
 -- SELECT c_credit_ind, c_instruct_type, c_program_type, courses_current.*
    FROM   courses_current
    WHERE  c_credit_ind        = 'N'
    AND    c_extract           = 'E'
    AND    c_instruct_type    != 'LAB'
    AND    c_crs_subject      != 'CED'
    AND    c_program_type NOT IN ('P','V')

 UNION

 -- C-30a -------------------------------------------------------------------------------------------
 -- Start Date-Summer - Check for valid format for c_start_date. (Summer)

    SELECT 'C-30a' AS label, count(*) AS err_count
 -- SELECT *
    FROM   courses_current
    WHERE (
               c_start_date IS NULL
            OR c_start_date IN ('','0')
            OR substr(c_start_date,5,2) NOT IN ('05','06','07','08')   -- month range
            OR substr(c_start_date,0,4) <> (substr(c_banner_term,0,4)) -- year range
            OR substr(c_start_date,7,2) > '31'                         -- too many days
            OR substr(c_start_date,7,2) < '01'                         -- too few days
          )
    AND    c_term = 1

 UNION

 -- C-30b -------------------------------------------------------------------------------------------
 -- Start Date-Fall - Check for valid format for c_start_date. (Fall)

    SELECT 'C-30b' AS label, count(*) AS err_count
 -- SELECT *
    FROM   courses_current
    WHERE (
               c_start_date IS NULL
            OR c_start_date IN ('','0')
            OR substr(c_start_date,5,2) NOT IN ('08','09','10','11','12') -- month range
            OR substr(c_start_date,0,4) <> substr(c_banner_term,0,4)      -- year range
            OR substr(c_start_date,7,2) > '31'                            -- too many days
            OR substr(c_start_date,7,2) < '01'                            -- too few days
          )
    AND    c_term = 2
    AND    c_ptrm_code NOT IN ('S','Y')

 UNION

 -- C-30c -------------------------------------------------------------------------------------------
 -- Start Date-Spring - Check for valid format for c_start_date. (Spring)

    SELECT 'C-30c*' AS label, count(*) AS err_count
 -- SELECT *
    FROM   courses_current
    WHERE (
               c_start_date IS NULL
            OR c_start_date IN ('','0')
            OR substr(c_start_date,5,2) NOT IN ('01','02','03','04','05')
            OR (
                     substr(c_start_date,0,4) <> (substr(c_banner_term,0,4) -1) -- previous year
                 AND substr(c_start_date,0,4) <> (substr(c_banner_term,0,4))    -- current year
               )
            OR substr(c_start_date,7,2) > '31' -- too many days
            OR substr(c_start_date,7,2) < '01' -- too few days
          )
    AND    c_term = 3

 UNION

 -- C-31a -------------------------------------------------------------------------------------------
 -- Start Date-Summer - Check for valid format for c_start_date. (Summer)

    SELECT 'C-31a' AS label, count(*) AS err_count
    FROM   courses_current
    WHERE (
               c_end_date IS NULL
            OR c_end_date IN ('','0')
            OR substr(c_end_date,5,2) NOT IN ('05','06','07','08')   -- month range
            OR substr(c_end_date,0,4) <> (substr(c_banner_term,0,4)) -- year  range
            OR substr(c_end_date,7,2) > '31'                         -- too many days
            OR substr(c_end_date,7,2) < '01'                         -- too few days
          )
    AND    c_term = 1
    AND    c_crs_subject <> 'CED'
    
 UNION
 
 -- C-31b -------------------------------------------------------------------------------------------
 -- Start Date-Fall - Check for valid format for c_start_date. (Fall)
 
    SELECT 'C-31b' AS label, count(*) AS err_count
 -- SELECT * 
    FROM   courses_current
    WHERE  (
                c_end_date IS NULL
             OR c_end_date IN ('','0')
             OR substr(c_end_date,5,2) NOT IN ('08','09','10','11','12') -- month range
             OR substr(c_end_date,0,4) <> substr(c_banner_term,0,4)      -- year  range             
             OR substr(c_end_date,7,2) > '31'                            -- too many days
             OR substr(c_end_date,7,2) < '01'                            -- too few days
           )
    AND    c_term = 2
    AND    c_ptrm_code <> 'Y'
    AND    c_crs_subject <> 'CED'
    AND    c_ptrm_code NOT IN ('S','Y')
    
 UNION

 -- C-31c -------------------------------------------------------------------------------------------
 -- Start Date-Spring - Check for valid format for c_start_date. (Spring)
 
    SELECT 'C-31c' AS label, count(*) AS err_count
    FROM   courses_current
    WHERE (
               c_end_date IS NULL
            OR c_end_date IN ('','0')
            OR substr(c_end_date,5,2) NOT IN ('01','02','03','04','05','06')
            OR substr(c_end_date,0,4) <> (substr(c_banner_term,0,4))
            OR substr(c_end_date,7,2) > '31' -- too many days
            OR substr(c_end_date,7,2) < '01' -- too few days
          )
   AND    c_term = 3
   AND    c_crs_subject <> 'CED'
           
 UNION

 -- C-35 --------------------------------------------------------------------------------------------
 -- Instruction Type - Check for valid values for c_instruct_type.
 
    SELECT 'C-35' AS label, count(*) AS err_count
    FROM   courses_current
    WHERE  c_instruct_type NOT IN ('LEC','LEL','LAB','SUP','INV','THE','DIS','CON','OTH')
    OR     c_instruct_type IS NULL
    
 UNION

 -- C-38b -------------------------------------------------------------------------------------------
 -- Gen. Ed. Codes - Check for valid values for c_gen_ed.
    
    SELECT 'C-38b' AS label, count(*) AS err_count
 -- c_crs_subject, c_crs_number, c_crs_section, c_gen_ed, courses_current.*
    FROM   courses_current
    WHERE  c_gen_ed NOT IN ('C','QL','AI','FA','HU','SS','LS','PS','ID','IR','DB','CL','FL','DV',' ')
    
 UNION

 -- C-39 --------------------------------------------------------------------------------------------
 -- Class Size - Check for classes with no students enrolled.
 
    SELECT 'C-39' AS label, count(*) AS err_count
 -- SELECT c_enrl, courses_current.*
    FROM   courses_current
    WHERE  c_enrl = 0 
    OR     c_enrl IS NULL
    OR     NOT EXISTS (SELECT 'Y' FROM student_courses_current WHERE c_crn = sc_crn)

    
 UNION
 
 -- C-40 --------------------------------------------------------------------------------------------
 -- Enroll - Number of Students Enrolled
 
    SELECT 'C-40' AS label, count(*) AS err_count
 -- SELECT c_enrl, c.*, sc.*
    FROM   courses_current c, student_courses_current sc
    WHERE  c_crn = sc_crn
    GROUP  BY  c_year, c_term, c_extract, c_crs_subject, c_crs_number, c_crs_section, c_enrl
    HAVING count(sc_id) != c_enrl
    
    -- SELECT * FROM courses_current WHERE c_enrl <> (SELECT count(distinct sc_pidm) FROM student_courses_current WHERE c_crn = sc_crn);
    -- SELECT * FROM student_courses_current WHERE sc_crn IN (SELECT c_crn FROM courses_current WHERE c_enrl <> (SELECT count(distinct sc_pidm) FROM student_courses_current WHERE c_crn = sc_crn)) ORDER BY sc_crn;
    -- 40884 MUSC 1000R 40 has 44, not 42
    -- 43062 CED  0410  50 has  1, not 10
    -- select * from sfrstcr where sfrstcr_crn = '42386' AND sfrstcr_term_code = '201840'
    -- select * from as_catalog_schedule where crn_key = '42386' and term_code_key = '201840'
    -- select * from students_current where s_pidm = '250387'
    
 UNION
 
 -- C-45 --------------------------------------------------------------------------------------------
 -- College - Missing College Code
-- 
--    SELECT 'C-45' AS label, count(*) AS err_count
-- -- SELECT c_enrl, c.*, sc.*
--select *    FROM   courses_current c, student_courses_current sc
--    WHERE  c_crn = sc_crn
--    AND    c_college IS NULL 

    
-- UNION
 
 ----------------------------------------------------------------------------------------------------
 ----------------------------------------------------------------------------------------------------
 -- STUDENT COURSES:                                                                               --
 ----------------------------------------------------------------------------------------------------
 ----------------------------------------------------------------------------------------------------
 
 -- SC-00 -------------------------------------------------------------------------------------------
 -- Duplicate Records - Duplicate Records SC ID, Subject, Course Number and Section.
 
    SELECT 'SC-00' AS label, count(*) AS err_count
 -- SELECT * 
    FROM   (
             SELECT sc_id, sc_crs_sbj, sc_crs_num, sc_crs_sec 
             FROM   student_courses_current
             GROUP  BY sc_id, sc_crs_sbj, sc_crs_num, sc_crs_sec
             HAVING count(*) > 1
           )
 UNION
    
 -- SC-01 -------------------------------------------------------------------------------------------
 -- Institution - There should be an institution for every record.
 
    SELECT 'SC-01' AS label, count(*) AS err_count
    FROM   student_courses_current 
    WHERE  sc_inst <> '3671'
    
 UNION

 -- SC-02 -------------------------------------------------------------------------------------------
 -- Year and Extract - There should be a year and extract for every record.
 
    SELECT 'SC-02' AS label, count(*) AS err_count
    FROM   student_courses_current
    WHERE  sc_year    IS NULL 
    OR     sc_term    IS NULL 
    OR     sc_extract IS NULL
    
 UNION

 -- SC-07 -------------------------------------------------------------------------------------------
 -- Attempted Credit/Contact Hours - Checks for attempted credit hours as well as contact hours. 
 --                                - Non-credit budget-related would be vocational, not academic. 
 --                                - This combination is not possible and needs to be adjusted.
 
    SELECT 'SC-07' AS label, count(*) AS err_count
    FROM   student_courses_current sc, courses_current c
    WHERE  c_crn = sc_crn
 	  AND    c_budget_code  LIKE 'B%'
    AND    c_credit_ind   = 'N'
    AND    c_program_type = 'A'
	  AND    sc_att_cr      > 0
    
 UNION

 -- SC-08a ------------------------------------------------------------------------------------------
 -- Credit - These grade types should not have any earned credit.
 
    SELECT 'SC-08a' AS label, count(*) AS err_count
 -- SELECT sc_grade, sc_earned_cr, student_courses_current.*
    FROM   student_courses_current
	  WHERE  sc_grade IN ('L','NG','E','F','UW','I','NC','AU','W')
	  AND    sc_earned_cr > 0
    
 UNION

 -- SC-08b ------------------------------------------------------------------------------------------
 -- Credit - Check to see if any records have grades but earned no credit.
 
    SELECT 'SC-08b' AS label, count(*) AS err_count
 -- SELECT sc_grade, sc_earned_cr, student_courses_current.*
    FROM   student_courses_current
    WHERE  sc_earned_cr IS NULL
  	AND    sc_grade     IS NOT NULL 
    AND    sc_grade     <> 'IP'
    
 UNION

 -- SC-08c ------------------------------------------------------------------------------------------
 -- Credit - This checks for student_course records from courses that are coded as credit and yet 
 --        - have contact hours or membership hours, or vice versa. Credit indicators of C should not 
 --        - have contact OR membership hours.
 
    SELECT 'SC-08c' AS label, count(*) AS err_count
    FROM   student_courses_current sc, courses_current c
    WHERE  c_crn = sc_crn
 	  AND    c_credit_ind = 'C' 
    AND    (sc_contact_hrs > 0 OR sc_mem_hrs > 0)
    
 UNION

 -- SC-08d ------------------------------------------------------------------------------------------
 -- Membership Hours - There should be no values in this field.

    SELECT 'SC-08d' AS label, count(*) AS err_count
    FROM   student_courses_current
    WHERE  sc_mem_hrs > 0
    
 UNION


 -- SC-09a ------------------------------------------------------------------------------------------
 -- Contact Hours - Check if there are contact hours erroneously listed at 3rd week.  

    SELECT 'SC-09a' AS label, count(*) AS err_count
    FROM   student_courses_current
    WHERE  sc_contact_hrs > '0' 
    AND    sc_extract = '3'
    
 UNION

 -- SC-10a ------------------------------------------------------------------------------------------
 -- Grade - Checking for invalid values in sc_grade

    SELECT 'SC-10a' AS label, count(*) AS err_count
 -- SELECT sc_banner_id, sc_crs_sbj, sc_crs_num, sc_crs_sec, sc_grade, sum(sc_att_cr)/10 AS sc_att_cr, c_budget_code, c_end_date
    FROM   student_courses_current, courses_current
    WHERE  sc_grade NOT IN (SELECT DISTINCT grade FROM ushe_ref_grade WHERE  grade IS NOT NULL) 
    AND    c_crn = sc_crn
    AND    ((substr(c_end_date,-4) > 700 AND c_term <= 2 AND substr(c_end_date,-4) < 1232 ) 
    OR     ( substr(c_end_date,-4) < 600 AND c_term  = 3 ))
    GROUP  BY sc_grade, sc_banner_id, sc_inst, sc_crs_sbj, sc_crs_num, sc_crs_sec, c_budget_code, c_end_date
    HAVING sum(sc_att_cr)/10 != 0 
    
 UNION

 -- SC-10b ------------------------------------------------------------------------------------------
 -- Grade - Invalid Concurrent Enrollment Grades 

    SELECT 'SC-10b*' AS label, count(*) AS err_count
 -- SELECT sc_banner_id, sc_crn, c_ptrm_code, sc_crs_sbj, sc_crs_num, sc_crs_sec, c_end_date, sc_earned_cr, sc_grade
    FROM   student_courses_current, courses_current
    WHERE  c_crn = sc_crn
    AND    sc_stud_type IN ('CC','DC')  
 -- AND   (sc_grade IS NULL OR sc_grade IN ('','IP','I'))
    AND   (sc_grade IS NULL OR sc_grade IN ('','I'))
    AND    sc_extract   = 'E'
    AND    c_ptrm_code != 'Y'
    
 UNION

 -- SC-12a ------------------------------------------------------------------------------------------
 -- Student Type - Checks for valid student type codes.
 
    SELECT 'SC-12a' AS label, count(*) AS err_count
 -- SELECT *
    FROM   student_courses_current
    WHERE  sc_stud_type NOT IN ('UC','CC','EC','DC')
    
 UNION

 -- SC-12b ------------------------------------------------------------------------------------------
 -- Student Type - These students are listed as concurrent enrollment, but attend a non-qualifying 
 --              - high school (out-of-state high school / adult high school / home-school).
   
    SELECT 'SC-12b' AS label, count(*) AS err_count
    FROM   student_courses_current sc, students_current s, courses_current c
    WHERE  s_pidm = sc_pidm AND c_crn = sc_crn
    AND    s_entry_action = 'HS' 
    AND    s_high_school IN ('459050','459100','459150',/*'459200','459300',*/'459400','459500')
	  AND    c_budget_code IN ('BC','SF')
    AND    sc_stud_type  IS NULL
    
 UNION

 -- SC-12c ------------------------------------------------------------------------------------------
 -- Student Type - These students took concurrent enrollment courses, but are not coded CC.

    SELECT 'SC-12c' AS label, count(*) AS err_count
 -- SELECT *
    FROM   students_current s, student_courses_current sc, courses_current c
    WHERE  sc_crn  = c_crn
    AND    sc_pidm = s_pidm
 	  AND    sc_stud_type  NOT IN ('CC','DC','EC')
	  AND    c_budget_code IN ('BC','SF')

 UNION

 -- SC-12? ------------------------------------------------------------------------------------------
 -- Student Type - CC student does not match Budget Code.

    SELECT 'SC-12?' AS label, count(*) AS err_count
 /* SELECT sc_crn, sc_crs_sbj, sc_crs_num, sc_crs_sec, c_budget_code, 
           s_pidm, s_banner_id, s_last_name, s_first_name, s_hsgrad_dt, sc_stud_type, s.*, c.*, sc.*,
           'CC Student does not match Budget Code' AS reason /**/
    FROM   students_current s, student_courses_current sc, courses_current c
    WHERE  sc_crn  = c_crn
    AND    sc_pidm = s_pidm
 	  AND    sc_stud_type  NOT IN ('CC','DC')
	  AND    c_budget_code IN ('BC','SF')
    AND    s_high_school != '459500'
 )
 WHERE err_count > 0
 ORDER BY CASE substr(label,1,2) 
               WHEN 'S-' THEN 1 
               WHEN 'C-' THEN 2
               WHEN 'SC' THEN 3
                         ELSE 0 END,
          substr(label,instr(label,'-')+1,LENGTH(label)-instr(label,'-'));

 ----------------------------------------------------------------------------------------------------
 -- Internal Error Checks
 ----------------------------------------------------------------------------------------------------
 ----------------------------------------------------------------------------------------------------
/* HB75_Waiver:
   Checks to see if there are negative or over 125% */
   SELECT s_pidm, s_banner_id, s_last_name, s_first_name, s_hb75_waiver, s_banner_term
   FROM ENROLL.students_current
   WHERE (s_hb75_waiver < 0 OR s_hb75_waiver > 125);

/* Graduate GPA:
   Checks to see if Graduate GPA is zero */
   SELECT s_pidm, s_banner_id, s_last_name, s_first_name, s_cum_gpa_grad, s_entry_action, s_banner_term
   FROM ENROLL.students_current
   WHERE s_cum_gpa_grad = 0 AND s_entry_action IN ('CG', 'RG');

 -- SELECT * FROM student_courses_current;

-- end of file