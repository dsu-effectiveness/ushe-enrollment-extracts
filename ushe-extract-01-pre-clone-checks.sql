 -- File:     pre-enrollment-error-checks.sql
 -- Term:     202123 (2021 Spring 3rd Week)
 -- Action:   Update and run all of these queries, add any results to this term's error spreadsheet
 --           in Excel and send them to Julie Stender (Students) and/or Sharon Lee (Classes).

 ---------------------------------------------------------------------------------------------------
 --  Begin: DailyStats Table Create -- This table is used for many of the pre-enrollment checks.  -- 
 ---------------------------------------------------------------------------------------------------


 -- Drop Existing Table
    DROP TABLE dailystats;

 -- Create Table using data from other tables ------------------------------------------------------
 
    CREATE TABLE dailystats AS 
    (
      SELECT DISTINCT(sfvregd_pidm)     AS pidm, 
             swvstdn_styp_code          AS styp, 
             swvstdn_blck_code          AS BLOCK, 
             SYSDATE                    AS daterun, 
             sfvregd_term_code          AS term,
             sum(sfvregd_credit_hr)     AS atmphrs, 
             CASE WHEN sum(sfvregd_credit_hr) >= '12'  THEN 'F'
                  WHEN sum(sfvregd_credit_hr) >= '0.5' THEN 'P' 
                  ELSE 'N' END          AS "F/P/N",
             swvstdn_degc_code_1        AS "Degree", 
             swvstdn_program_1          AS cur_prgm, 
             swvstdn_majr_code_conc_1   AS conc1, 
             swvstdn_majr_code_conc_1_2 AS conc2, 
             swvstdn_resd_code          AS residency
      FROM   baninst1.sfvregd,
             saturn.stvrsts,
             dsc.dsc_swvstdn
      WHERE  sfvregd_term_code      = '202120' -- <-- this reporting term
      AND    sfvregd_pidm           = swvstdn_pidm	
      AND    sfvregd_term_code      = swvstdn_term_code
      AND    sfvregd_rsts_code      = stvrsts_code
      AND    stvrsts_incl_sect_enrl = 'Y'
      AND    sfvregd_camp_code     <> 'XXX'
      AND    ( SELECT count(*)
               FROM   sfrstcr, stvrsts, as_catalog_schedule
               WHERE  sfrstcr_pidm           = sfvregd_pidm
               AND    sfrstcr_crn            = crn_key 
               AND    sfvregd_term_code      = term_code_key
               AND    sfrstcr_term_code      = term_code_key
               AND    sfrstcr_rsts_code      = stvrsts_code
               AND    stvrsts_incl_sect_enrl = 'Y'
               AND    upper(title)    NOT LIKE '%LITERACY EXAM%'
             ) > 0
      GROUP  BY sfvregd_pidm, swvstdn_styp_code, swvstdn_blck_code, SYSDATE, 
                sfvregd_term_code, swvstdn_program_1, swvstdn_degc_code_1, 
                swvstdn_majr_code_conc_1, swvstdn_majr_code_conc_1_2, swvstdn_resd_code
    );
    
 -- Add Additional Fields --------------------------------------------------------------------------
 
    ALTER TABLE dailystats ADD 
    (
      cip       VARCHAR2(6),
      ID        VARCHAR2(9),
      valid_pgm VARCHAR2(1),
      SID       VARCHAR2(9),
      hsgraddt  DATE,
      classcode VARCHAR2(3),
      ethnic    VARCHAR2(1),
      gender    VARCHAR2(1),
      stu_age   NUMBER,
      reg_type  VARCHAR2(2)
    );

 -- Get Gender from SPBPERS Table ------------------------------------------------------------------
 
    UPDATE dailystats 
    SET    gender = 
           (
             SELECT spbpers_sex 
             FROM   spbpers 
             WHERE  dailystats.pidm = spbpers_pidm
           );

 -- Get Ethnicity - Non-Resident Aliens from SPBPERS -----------------------------------------------
 
    UPDATE dailystats 
    SET    ethnic = 'N' WHERE EXISTS 
           (
             SELECT spbpers_citz_code 
             FROM   spbpers 
             WHERE  spbpers_pidm = pidm 
             AND    spbpers_citz_code = '2'
           )
    AND    ethnic IS NULL;

 -- Get Ethnicity - Hispanic from SPBPERS ----------------------------------------------------------

    UPDATE dailystats
    SET    ethnic = 'H'
    WHERE  EXISTS 
           (
             SELECT spbpers_ethn_cde
             FROM   spbpers
             WHERE  spbpers_pidm = pidm
             AND    spbpers_ethn_cde = '2'
           )
    AND    ethnic IS NULL ;

 -- Get Ethnicity - Other from SPBPERS & GORRACE ---------------------------------------------------

    -- New Code (GORRACE)
    UPDATE dailystats
    SET    ethnic = 
           (
             SELECT MIN(gorprac_race_cde)
             FROM   gorprac
             WHERE  gorprac_pidm = pidm
           )
    WHERE  ethnic IS NULL;  

    -- Old Code (SPBPERS)
    UPDATE dailystats
    SET    ethnic = 
           (
             SELECT spbpers_ethn_code
             FROM   spbpers
             WHERE  spbpers_pidm = pidm
           )
    WHERE  ethnic IS NULL;  

 -- Calculate Class Code (FR/SO/JR/SR/UG) ----------------------------------------------------------

    UPDATE dailystats
    SET    classcode =
           (        
             SELECT f_class_calc_fnc(b.pidm, 'UG', b.term)  
             FROM   dailystats b
             WHERE  dailystats.pidm = b.pidm
           );

 -- Get CIP Codes from dsc_programs ----------------------------------------------------------------

    -- Known Programs
    UPDATE enroll.dailystats
    SET    cip = nvl(( SELECT cipc_code
 	                     FROM   dsc_programs_current
 	                     WHERE  prgm_code = cur_prgm
 	                     GROUP  BY cipc_code
                     ), '999999');
 
 -- Get ID from SPRIDEN ----------------------------------------------------------------------------

    UPDATE enroll.dailystats
    SET    ID =
           (
             SELECT spriden_id
             FROM   spriden
             WHERE  pidm = spriden_pidm
             AND    spriden_change_ind IS NULL
           );

 -- Get SID (SSN) from SPRIDEN ---------------------------------------------------------------------

    UPDATE enroll.dailystats
    SET    SID =
           ( 
             SELECT spbpers_ssn
             FROM   spbpers
             WHERE  pidm = spbpers_pidm
           );

 -- Get HS Grad Date from SORHSCH ------------------------------------------------------------------
    
 -- HS Grad Date: those with a HS transcript received date
    UPDATE enroll.dailystats
    SET    hsgraddt =
           (
             SELECT sorhsch_graduation_date
             FROM   sorhsch
             WHERE  sorhsch.rowid = dsc.f_get_sorhsch_rowid(pidm)
           );

 -- Calculate Entry Action by ----------------------------------------------------------------------

    UPDATE enroll.dailystats
    SET    reg_type = f_calc_entry_action_2(pidm,'202120');

 -- Calculate Age by Today's Date ------------------------------------------------------------------

    UPDATE enroll.dailystats
    SET    stu_age = 
           ( 
             SELECT f_calculate_age(SYSDATE, spbpers_birth_date, spbpers_dead_date)
             FROM   spbpers
             WHERE  spbpers_pidm = pidm
           );

    CREATE INDEX dailystats_pidm     ON dailystats (pidm);
    CREATE INDEX dailystats_styp     ON dailystats (styp);
    CREATE INDEX dailystats_cur_prgm ON dailystats (cur_prgm);

 ---------------------------------------------------------------------------------------------------
 -- End: Create DailyStats Table                                                                  --
 ---------------------------------------------------------------------------------------------------
 ---------------------------------------------------------------------------------------------------
 -- Begin: General Error Checking Queries                                                         --
 ---------------------------------------------------------------------------------------------------
 
 ---------------------------------------------------------------------------------------------------
 /* Tab/Num:  [ Demographics ] [ 1 ]
  * Action:   Send results to Julie to update Sex.
  * Notes:    Returns a list of Students whose gender is null or "N".
  */ 
  
    SELECT COUNT(DISTINCT(pidm)) AS demographics_table_1_errors
 /* SELECT * /**/ 
    FROM   (
             SELECT DISTINCT(spriden_pidm) AS pidm,
                    spriden_id             AS banner_id, 
                    f_format_name(spriden_pidm,'LFMI')                 
                                           AS full_name,
                    styp                   AS stu_type, 
                    spbpers_sex            AS gender, 
                    sfrstcr_term_code      AS term_code,
                    'Invalid Gender'       AS reason 
             FROM   spriden, 
                    sfrstcr, 
                    stvrsts, 
                    spbpers,
                    dailystats
             WHERE  spriden_change_ind IS NULL
             AND    spriden_pidm = spbpers_pidm (+)
             AND    sfrstcr_pidm = spriden_pidm
             AND    spriden_pidm = pidm
             AND    sfrstcr_term_code >= '202120' -- <-- YYYYTT of this reporting term
             AND    sfrstcr_rsts_code = stvrsts_code
             AND    stvrsts_incl_sect_enrl = 'Y'
             AND   (spbpers_sex IS NULL OR spbpers_sex NOT IN ('M','F'))
           );
    --  result(s)
 
 ---------------------------------------------------------------------------------------------------
 /* Tab/Num: [ Demographics ] [ 2 ]
  * Action:  Send results to Julie Stender   
  * Notes:   These queries return any students who are listed as living in the US but are missing 
  *          their state code and/or county code           
  */ 
 
 -- Check for US without state/county
    SELECT COUNT(DISTINCT(pidm)) AS demographics_table_2_errors
 -- SELECT DISTINCT * 
    FROM   (
             SELECT DISTINCT(s1.sabsupl_pidm)     AS pidm, 
                    spriden_id                    AS banner_id, 
                    f_format_name(spriden_pidm,'LFMI')                 
                                                  AS full_name,     
                    s1.sabsupl_cnty_code_admit    AS admit_county, 
                    s1.sabsupl_stat_code_admit    AS admit_state,
                    s1.sabsupl_natn_code_admit    AS admit_country, 
                    s1.sabsupl_term_code_entry    AS ea_term_code, 
                    s1.sabsupl_appl_no            AS appl_num,
                    'US Citizen, missing County or Country'  AS reason
             FROM   sabsupl s1, 
                    spriden,
                    dailystats
             WHERE  spriden_change_ind IS NULL
             AND    spriden_pidm = pidm
             AND    s1.sabsupl_appl_no||s1.sabsupl_term_code_entry = 
                    (
                      SELECT MAX(s2.sabsupl_appl_no||s2.sabsupl_term_code_entry) 
                      FROM   sabsupl s2
                      WHERE  s2.sabsupl_pidm = s1.sabsupl_pidm
                      AND    s2.sabsupl_term_code_entry >= '202120' -- <-- YYYYTT of this reporting term
                      AND    s2.sabsupl_term_code_entry != '999999'
                      GROUP BY sabsupl_pidm
                    ) 
             AND    s1.sabsupl_pidm             = spriden_pidm
             AND    s1.sabsupl_natn_code_admit  = 'US'
             AND    s1.sabsupl_term_code_entry != '999999'
             AND   (s1.sabsupl_cnty_code_admit IS NULL OR s1.sabsupl_stat_code_admit IS NULL)
    
             UNION ALL

             SELECT DISTINCT(s1.sabsupl_pidm)    AS pidm, 
                    spriden_id                   AS banner_id, 
                    f_format_name(spriden_pidm,'LFMI')                 
                                        AS full_name,     
                    s1.sabsupl_cnty_code_admit   AS admit_county, 
                    s1.sabsupl_stat_code_admit   AS admit_state,
                    s1.sabsupl_natn_code_admit   AS admit_country, 
                    s1.sabsupl_term_code_entry   AS ea_term_code, 
                    s1.sabsupl_appl_no           AS appl_num,
                    'US Citizen, missing County or Country'  AS reason
             FROM   sabsupl s1, 
                    spriden,
                    dailystats
             WHERE  spriden_change_ind IS NULL
             AND    spriden_pidm = pidm
             AND    s1.sabsupl_appl_no||s1.sabsupl_term_code_entry = 
                    (
                      SELECT MAX(s2.sabsupl_appl_no||s2.sabsupl_term_code_entry) 
                      FROM   sabsupl s2
                      WHERE  s2.sabsupl_pidm = s1.sabsupl_pidm
                      AND    s2.sabsupl_term_code_entry >= '202120' -- <-- YYYYTT of this reporting term
                      AND    s2.sabsupl_term_code_entry != '999999'
                      GROUP BY sabsupl_pidm
                    ) 
             AND    s1.sabsupl_pidm             = spriden_pidm
             AND    s1.sabsupl_stat_code_admit  = 'UT'
             AND    s1.sabsupl_term_code_entry != '999999'
             AND   (s1.sabsupl_cnty_code_admit IS NULL OR s1.sabsupl_natn_code_admit IS NULL)
           );
    --  result(s)
 
 ---------------------------------------------------------------------------------------------------
 /* Tab/Num: [ Demographics ][ 3 ]
  * Action:  Send results to Julie Stender   
  * Notes:   This query checks for:
  *          All those who have an N should also have a 2 in citizen code and a Visa Type (not null ?
  *          typically F1, etc.). When looking at international students recently, we found that we
  *          were over counting because not all 2?s had a visa type. Those who have 2?s that don?t
  *          have a visa type should be sent to Julie Stender and CC to Cari Heizer for cleaning..
  */

    SELECT COUNT(DISTINCT(pidm)) AS demographics_table_3_errors
 -- SELECT DISTINCT *
    FROM (SELECT DISTINCT
                 (pidm) AS pidm,
                 id AS banner_id,
                 f_format_name(spriden_pidm, 'LFMI') AS full_name,
                 styp AS stu_type,
                 hsgraddt AS hsgrad_dt,
                 cur_prgm AS curr_prgm,
                 spbpers_citz_code AS citz_code,
                 gorvisa_vtyp_code AS visa_type,
                 gorvisa_visa_expire_date AS visa_expire_date,
                 'CITZ 2 Non-Resident Alien without Visa Type' AS reason
            FROM sgbstdn a,
                 spbpers,
                 spriden,
                 dailystats
                 LEFT JOIN gorvisa
                           ON pidm = gorvisa_pidm
                 LEFT JOIN gobsevs
                           ON pidm = gobsevs_pidm
           WHERE spriden_change_ind IS NULL
             AND a.sgbstdn_pidm = spbpers_pidm
             AND a.sgbstdn_pidm = spriden_pidm
             AND a.sgbstdn_pidm = pidm
             AND a.sgbstdn_term_code_eff = (SELECT MAX(b.sgbstdn_term_code_eff)
                                              FROM sgbstdn b
                                             WHERE b.sgbstdn_pidm = a.sgbstdn_pidm
                                               AND b.sgbstdn_term_code_eff <= '202120' -- <-- YYYYTT of this reporting term
           )
             AND ((spbpers_citz_code <> '2' AND gorvisa_vtyp_code IS NOT NULL)
                 OR (spbpers_citz_code = '2' AND gorvisa_vtyp_code IS NULL)
                 OR (spbpers_citz_code NOT IN ('2', '3') AND gorvisa_vtyp_code IS NOT NULL)
                 OR (spbpers_citz_code = '2' AND gorvisa_vtyp_code IS NULL))
             AND (gorvisa_visa_expire_date > sysdate OR gorvisa_visa_expire_date IS NULL)
            );


    --  result(s)

 ---------------------------------------------------------------------------------------------------
 /* Tab/Num:  [ Demographics ] [ 4 ]
  * Action:   Send results to Julie to update HSCODE and HSGRAD_DT.
  * Notes:    finds those with no HS coded, if S class code as 450052 Success Academy,
  *           if CNN campus code check crn on ssasect to find which HS.
  */

    SELECT COUNT(DISTINCT(pidm)) AS demographics_table_4_errors
 /* SELECT * /**/
    FROM   (
             SELECT spriden_pidm            AS pidm,
                    spriden_id              AS banner_id,
                    f_format_name(spriden_pidm,'LFMI')
                                            AS full_name,
                    styp                    AS stu_type,
                    spbpers_sex             AS gender,
                    f_calculate_age(SYSDATE,spbpers_birth_date,spbpers_dead_date)
                                            AS age,
                    sorhsch_sbgi_code       AS hs_code,
                    sorhsch_graduation_date AS hs_grad_date,
                    'Missing HS Code and/or HS Grad Date'
                                            AS reason
             FROM   spriden,
                    sfrstcr,
                    stvrsts,
                    spbpers,
                    sorhsch,
                    ssbsect,
                    dailystats
             WHERE  spriden_pidm = pidm
             AND    sfrstcr_pidm = pidm
             AND    spriden_pidm = spbpers_pidm (+)
             AND    spriden_pidm = sorhsch_pidm (+)
             AND    sfrstcr_crn  = ssbsect_crn
             AND    sfrstcr_term_code = ssbsect_term_code
             AND    sfrstcr_rsts_code = stvrsts_code
             AND    sfrstcr_term_code = '202120' -- <-- YYYYTT of this reporting term
             AND    stvrsts_incl_sect_enrl = 'Y'
             AND    sorhsch_sbgi_code  IS NULL
             AND    spriden_change_ind IS NULL
             AND    substr(ssbsect_seq_numb,3,1) IS NOT NULL
             AND    f_calculate_age(SYSDATE, spbpers_birth_date, spbpers_dead_date) < 20
           );
    --  result(s)

 ---------------------------------------------------------------------------------------------------
 /* Tab/Num: [ Demographics] [ 5 ]
  * Action:  Send results to Julie Stender
  * Notes:   This query identifies an error in data entry where the student's high school
  *          graduation date is the same or before as their date of birth.
  */

    SELECT COUNT(DISTINCT(pidm)) AS demographics_table_5_errors
 -- SELECT DISTINCT *
    FROM   (
             SELECT pidm               AS pidm,
                    ID                 AS banner_id,
                    f_format_name(spriden_pidm,'LFMI')
                                       AS full_name,
                    styp               AS stu_type,
                    gender             AS gender,
                    f_calculate_age(SYSDATE,spbpers_birth_date,spbpers_dead_date)
                                       AS age,
                    spbpers_birth_date AS birth_dt,
                    to_char(sorhsch_graduation_date, 'mm-dd-yyyy')
                                       AS hsgrad_dt,
                    cur_prgm           AS curr_prgm,
                    'Invalid HS Graduation and/or Birth Date'
                                       AS reason
             FROM   dailystats,
                    spbpers,
                    spriden,
                    sorhsch
             WHERE  spbpers_pidm = pidm
             AND    spriden_pidm = pidm
             AND    sorhsch_pidm = pidm
             AND    (
                         (LENGTH(hsgraddt)          != 9 AND hsgraddt IS NOT NULL) -- Invalid BD
                      OR LENGTH(spbpers_birth_date) != 9                           -- Invalid BD
                      OR spbpers_birth_date         IS NULL                        -- Invalid BD
                      OR spbpers_birth_date         >= hsgraddt-3650               -- BD Within 10 years of HSGD
                    )
             AND    spriden_change_ind IS NULL
             ORDER  BY hsgraddt, spbpers_birth_date, pidm
           );
    --  result(s)

 ---------------------------------------------------------------------------------------------------
 /* Tab/Num: [ Demographics] [ 6 ]
  * Action:  Send results to Julie Stender
  * Notes:   This query identifies an error in which multiple students share the same SSN.
  */

    SELECT count(DISTINCT(pidm)) AS demographics_table_6_errors
 -- SELECT DISTINCT *
    FROM   (
             SELECT spriden_pidm       AS pidm,
                    spriden_id         AS banner_id,
                    f_format_name(spriden_pidm,'LFMI')
                                       AS full_name,
                    styp               AS stu_type,
                    spbpers_sex        AS gender,
                    f_calculate_age(SYSDATE,spbpers_birth_date,spbpers_dead_date)
                                       AS age,
                    spbpers_birth_date AS birth_dt,
                   -- to_char(sorhsch_graduation_date, 'mm-dd-yyyy')
                   --                  AS hsgrad_dt,
                   -- cur_prgm         AS curr_prgm,
                    '***-**-**'||substr(spbpers_ssn,8,2) AS stu_ssn,
                    'Duplicate SSN Found'
                                       AS reason
             FROM   dailystats RIGHT JOIN (spbpers pers1 INNER JOIN spriden iden1 ON spriden_pidm = spbpers_pidm) ON pidm = spbpers_pidm
                    --sorhsch
             WHERE  spbpers_ssn IN (SELECT spbpers_ssn FROM dailystats, spbpers WHERE spbpers_pidm = pidm)
             AND    spbpers_ssn IN
                    (
                         SELECT spbpers_ssn
                         FROM   spbpers pers2, spriden iden2
                         WHERE  pers2.spbpers_pidm = iden2.spriden_pidm
                         AND    iden2.spriden_change_ind IS NULL
                         AND    iden2.spriden_entity_ind = 'P'
                         AND    (
                                  SELECT count(*)
                                  FROM   spbpers pers3, spriden iden3
                                  WHERE  pers3.spbpers_pidm = iden3.spriden_pidm
                                  AND    pers3.spbpers_ssn  = pers2.spbpers_ssn
                                  AND    iden3.spriden_change_ind IS NULL
                                  AND    iden3.spriden_entity_ind = 'P'
                                ) > 1
                    )
             AND    spriden_change_ind IS NULL

             ORDER  BY hsgraddt, spbpers_birth_date, pidm
           )
    ORDER  BY stu_ssn, full_name;
    --  result(s)

     ---------------------------------------------------------------------------------------------------
 /* Tab/Num: [ Demographics] [ 7 ]
  * Action:  Send results to Julie Stender
  * Notes:   This query identifies null citizenship codes in SPBPERS
  */

  SELECT count(DISTINCT(pidm)) AS demographics_table_7_errors
 -- SELECT DISTINCT *
    FROM (SELECT spbpers_pidm AS pidm,
                 spriden_id AS banner_id, f_format_name(spriden_pidm,'LFMI') AS full_name,
                 spbpers_citz_code AS citz_code,
                 'Null citizenship code found' AS reason
            FROM spriden a
                 INNER JOIN sfrstcr b
                            ON b.sfrstcr_pidm = a.spriden_pidm
                 INNER JOIN spbpers c
                            ON c.spbpers_pidm = b.sfrstcr_pidm
                 LEFT JOIN stvrsts d
                           ON d.stvrsts_code = b.sfrstcr_rsts_code
           WHERE sfrstcr_term_code = '202120'
             AND spriden_entity_ind = 'P'
             AND spriden_change_ind IS NULL
             AND stvrsts_incl_sect_enrl = 'Y'
             AND sfrstcr_camp_code != 'XXX'
             AND spbpers_citz_code IS NULL);

 ---------------------------------------------------------------------------------------------------
 /* Tab/Num: [ Degrees & Programs ] [ 1 ]
  * Action:  Send results to Julie Stender
  * Notes:   Lists ALL students with two active matriculations for the specified term. Use this to
  *          find those with bogus 2nd programs and delete them prior to cloning.
  */

    SELECT COUNT(DISTINCT(pidm)) AS degs_progs_table_1_errors
 -- SELECT DISTINCT *
    FROM   (
             SELECT pidm                AS pidm,
                    ID                  AS banner_id,
                    spriden_last_name   AS last_name,
                    spriden_first_name  AS first_name,
                    sgvacur_majr_code_1 AS majr_code,
                    stvmajr_cipc_code   AS cipc_code,
                    cur_prgm            AS curr_prgm,
                    sgvacur_program     AS scnd_prgm,
                    'Double matriculations, check for bogus Programs'
                                        AS reason
             FROM   dailystats,
                    stvmajr,
                    sgvacur A,
                    sgbstdn,
                    spriden
             WHERE  spriden_pidm          = pidm
             AND    A.sgvacur_pidm        = pidm
             AND    A.sgvacur_pidm        = sgbstdn_pidm
             AND    A.sgvacur_majr_code_1 = stvmajr_code
             AND    A.sgvacur_cact_code   = 'ACTIVE'
             AND    A.sgvacur_order       = '2'
             AND    A.sgvacur_stdn_rowid  = sgbstdn.ROWID
             AND    sgbstdn_term_code_eff =
                    (
                      SELECT MAX(c.sgbstdn_term_code_eff)
                      FROM   sgbstdn c
                      WHERE  c.sgbstdn_pidm = pidm
                      AND    c.sgbstdn_term_code_eff <= '202120' -- <-- YYYYTT of this reporting term
                    )
             AND    NOT (sgvacur_majr_code_1 = 'RN'   -- Ignore RN   if curr program is BS-NURS-P or AA-ADN
                    AND (cur_prgm = 'BS-NURS-P' OR sgvacur_program = 'AAS-ADN' ))
             AND    NOT (sgvacur_majr_code_1 = 'DHYG' -- Ignore DHYG if curr program is BS-DHYG-P or AA-DHYG
                    AND (cur_prgm = 'BS-DHYG-P' OR sgvacur_program = 'AAS-DHYG'))
             AND    NOT (sgvacur_majr_code_1 = 'MLS'  -- Ignore MLS  if curr program is BS-MLS-P  or AA-MLS
                    AND (cur_prgm = 'BS-MLS-P'  OR sgvacur_program = 'AAS-MLS' ))
             AND    NOT (cur_prgm = 'BS-BU' OR sgvacur_program = 'BS-BU') -- Ignore Business Degrees
             AND    NOT ((cur_prgm = 'BS-PSY'  AND sgvacur_program = 'BS-ASOC') -- Ignore Psychology & Sociology combo
                     OR  (cur_prgm = 'BS-ASOC' AND sgvacur_program = 'BS-PSY'))
             AND    NOT sgvacur_program LIKE 'A%GENED' -- Filter out secondary programs of AA/AS-GENED
             AND    NOT cur_prgm IN ('BIS-INDV','BS-INTS') -- Filter out Indiv. Study. and Ind. Study.
             AND    spriden_change_ind IS NULL
             ORDER  BY sgvacur_program
           );
    --  result(s)

 ---------------------------------------------------------------------------------------------------
 /* Tab/Num: [ Degrees & Programs ] [ 2 ]
  * Action:  Send results to Julie Stender
  * Notes:   Lists ALL students who are still in High School, but don't have ND-CONC as Program.
  */

    SELECT COUNT(DISTINCT(pidm)) AS degs_progs_table_2_errors
 -- SELECT DISTINCT *
    FROM   (
             SELECT pidm                AS pidm,
                    ID                  AS banner_id,
                    spriden_last_name   AS last_name,
                    spriden_first_name  AS first_name,
                    cur_prgm            AS curr_prgm,
                    reg_type            AS entry_action,
                    stu_age             AS age,
                    hsgraddt            AS hsgrad_dt,
                    'HSCE Students not in ND-CONC/ND-SA/ND-CE Program'
                                        AS reason
             FROM   dailystats,
                    spriden
             WHERE  spriden_pidm = pidm
             AND    spriden_change_ind IS NULL
             AND    reg_type = 'HS'
             AND    cur_prgm NOT IN ('ND-CONC','ND-SA','ND-CE', 'ND-ACE')
           );
    --  result(s)

 ---------------------------------------------------------------------------------------------------

 ---------------------------------------------------------------------------------------------------
 /* Tab/Num: [ Student Type ][ 1 ]
  * Action:  Send results to Julie Stender
  * Notes:   now check for Instit history if record on SHATCKN by term it will show here. See how
  *          many of above R's attended after hs
  */

    SELECT COUNT(DISTINCT(pidm)) AS stu_type_table_1_errors
 -- SELECT pidm, banner_id, full_name, stu_type, hsgrad_dt, curr_prgm, min_term, max_term, reason
    FROM   (
             SELECT x.*, ROW_NUMBER() OVER (PARTITION by pidm ORDER BY max_term) AS rn
             FROM   (
                      SELECT pidm          AS pidm,
                             ID            AS banner_id,
                             f_format_name(spriden_pidm,'LFMI')
                                           AS full_name,
                             styp          AS stu_type,
                             hsgraddt      AS hsgrad_dt,
                             cur_prgm      AS curr_prgm,
                             min(substr(dsc_term_code,1,5)||'0')
                                           AS min_term,
                             max(substr(dsc_term_code,1,5)||'0')
                                           AS max_term,
                          -- s_term_att_cr AS att_hrs,
                             'Marked STYP '||styp||', but has attended DSU since HS Grad'
                                           AS reason
                      FROM   dailystats,
                             spriden,
                             bailey.students03@dscir,
                             stvterm
                      WHERE  styp IN ('N','F','T')
                      AND    spriden_pidm = pidm
                      AND    spriden_pidm = dsc_pidm
                      AND    stvterm_code = substr(dsc_term_code,1,5)||'0'
                      AND    spriden_change_ind IS NULL
                      AND    s_entry_action <> 'HS'
                      AND    stvterm_start_date > hsgraddt
                      AND    stvterm_code > to_char(hsgraddt,'YYYY')||'30'
                      AND    stvterm_code != '202120'
                      GROUP  BY spriden_pidm, pidm, ID, styp, hsgraddt, cur_prgm, s_term_att_cr
                    ) x
           )
    WHERE  rn = 1
    AND    CASE WHEN min_term = max_term -- This statement stops first-time attendance during the Summer from affecting Fall
                 AND substr(max_term, -2) = '30'
                 AND substr('202120', -2) = '40'
                 AND substr(max_term,1,4) = substr('202120',1,4)
           THEN 0 ELSE 1 END = 1
    ORDER  BY reason, full_name;
    --  results

 ---------------------------------------------------------------------------------------------------
 /* Tab/Num: [ Student Type ][ 2 ]
  * Action:  Send results to Julie Stender
  * Notes:   These students attended a non-summer college term at another college after graduating
  *          high school. Should their STYP really be marked Freshmen? and vice versa?
  */

    SELECT count(DISTINCT pidm) AS stu_type_table_2_errors
 /* SELECT pidm, banner_id, full_name, stu_type, hsgrad_dt, curr_prgm, sbgi_code,
           sbgi_desc, gap1, gap2, max_term_taken, dt_attended, gap3, xfer_credits, reason /**/
    FROM   (
             SELECT x.*, ROW_NUMBER() OVER(PARTITION BY pidm ORDER BY dt_attended) AS rn
             FROM   (
                      SELECT DISTINCT(spriden_pidm) AS pidm,
                             ID                     AS banner_id,
                             f_format_name(spriden_pidm,'LFMI')
                                                    AS full_name,
                             styp                   AS stu_type,
                             hsgraddt               AS hsgrad_dt,
                             cur_prgm               AS curr_prgm,
                             shrtrit_sbgi_code      AS sbgi_code,
                             stvsbgi_desc           AS sbgi_desc,
                             ''                     AS gap1,
                             ''                     AS gap2,
                             MAX(shrtrcr_term_code) AS max_term_taken,
                             shrtram_attn_period    AS dt_attended,
                             ''                     AS gap3,
                             sum(shrtrcr_trans_credit_hours)
                                                    AS xfer_credits,
                             'Marked STYP '||styp||', but attended another inst. prior to DSU'
                                                    AS reason
                      FROM   saturn.shrtrcr,
                             saturn.shrtrit,
                             shrtram,
                             saturn.stvsbgi,
                             dailystats,
                             spriden
                      WHERE  shrtrit_pidm = pidm
                      AND    shrtrcr_pidm = pidm
                      AND    shrtrcr_pidm = pidm
                      AND    shrtrcr_pidm = shrtrit_pidm
                      AND    shrtrcr_pidm = shrtram_pidm
                      AND    spriden_change_ind IS NULL
                      AND    spriden_pidm = pidm
                      AND    shrtrit_sbgi_code = stvsbgi_code
                      AND    shrtrcr_tram_seq_no = shrtram_seq_no  -- trcr to tram
                      AND    shrtrcr_trit_seq_no = shrtrit_seq_no  -- trcr to trit
                      AND    shrtram_trit_seq_no = shrtrit_seq_no  -- tram to trit
                      AND    shrtrcr_trit_seq_no = shrtram_trit_seq_no
                      AND    styp IN ('F', 'H', 'N')
                      AND    shrtrit_sbgi_code BETWEEN '0' AND '99999'
                      AND    shrtrcr_term_code > to_char(hsgraddt,'YYYY')||'30'
                      GROUP  BY shrtrcr_pidm, spriden_pidm, shrtrit_sbgi_code, stvsbgi_desc,
                                shrtram_attn_period, ID, hsgraddt, styp, cur_prgm
                      HAVING sum(shrtrcr_trans_credit_hours) > 0

                      UNION ALL

                      SELECT DISTINCT(spriden_pidm) AS pidm,
                             ID                     AS banner_id,
                             f_format_name(spriden_pidm,'LFMI')
                                                    AS full_name,
                             styp                   AS stu_type,
                             hsgraddt               AS hsgrad_dt,
                             cur_prgm               AS curr_prgm,
                             shrtrit_sbgi_code      AS sbgi_code,
                             stvsbgi_desc           AS sbgi_desc,
                             ''                     AS gap1,
                             ''                     AS gap2,
                             MAX(shrtrcr_term_code) AS max_term_taken,
                             shrtram_attn_period    AS dt_attended,
                             ''                     AS gap3,
                             sum(shrtrcr_trans_credit_hours)
                                                    AS xfer_credits,
                             'Marked STYP '||styp||', but did not transfer any credits to DSU'
                                                    AS reason
                      FROM   shrtrcr,
                             shrtrit,
                             shrtram,
                             stvsbgi,
                             dailystats,
                             spriden
                      WHERE  shrtrcr_pidm = pidm
                      AND    shrtrit_pidm = pidm
                      AND    shrtrcr_pidm = pidm
                      AND    shrtrcr_pidm = shrtram_pidm
                      AND    shrtrcr_pidm = shrtrit_pidm
                      AND    spriden_change_ind IS NULL
                      AND    spriden_pidm = pidm
                      AND    shrtrit_sbgi_code = stvsbgi_code
                      AND    shrtrcr_tram_seq_no = shrtram_seq_no  -- trcr to tram
                      AND    shrtrcr_trit_seq_no = shrtrit_seq_no  -- trcr to trit
                      AND    shrtram_trit_seq_no = shrtrit_seq_no  -- tram to trit
                      AND    shrtrcr_trit_seq_no = shrtram_trit_seq_no
                      AND    styp IN ('T')
                      AND    shrtrit_sbgi_code BETWEEN '0' AND '99999'
                      AND    shrtrcr_term_code < to_char(hsgraddt,'YYYY')||'30'
                      AND    NOT EXISTS
                             (
                               SELECT 'Y'
                               FROM   shrtrit, shrtram
                               WHERE  shrtrit_pidm = pidm
                               AND    shrtram_pidm = shrtrit_pidm
                               AND    shrtram_trit_seq_no = shrtrit_seq_no
                             )
                      GROUP  BY shrtrcr_pidm, spriden_pidm, shrtrit_sbgi_code, stvsbgi_desc,
                                shrtram_attn_period, ID, hsgraddt, styp, cur_prgm
                      HAVING sum(shrtrcr_trans_credit_hours) = 0
                      ORDER  BY pidm, max_term_taken
                    ) x
           )
    WHERE  rn = 1
    ORDER  BY reason, full_name;
    --  result(s)

 ---------------------------------------------------------------------------------------------------
 /* Tab/Num: [ Student Type ][ 3 ]
  * Action:  Send results to Julie Stender
  * Notes:   This query is used to help determine if a student should or should not be be considered
             a new student.  Students Marked RS/CS, but hasn't attended DSU since HS
  */

    SELECT COUNT(DISTINCT(pidm)) AS stu_type_table_3_errors
 -- SELECT DISTINCT *
    FROM   (
             SELECT DISTINCT pidm      AS pidm,
                    spriden_id         AS banner_id,
                    f_format_name(spriden_pidm,'LFMI')
                                       AS full_name,
                    styp               AS stu_type,
                    to_char(sorhsch_graduation_date, 'mm-dd-yyyy')
                                       AS hsgrad_dt,
                    cur_prgm           AS curr_prgm,
                    spbpers_birth_date AS birth_dt,
                    f_calculate_age(NULL, spbpers_birth_date, SYSDATE)
                                       AS age,
                    nvl (
                    (
                      SELECT MAX(substr(dsc_term_code,1,5)||'0')
                      FROM   bailey.students03@dscir
                      WHERE  dsc_pidm = pidm
                    ),nvl((
                      SELECT MAX(shrtgpa_term_code)
                      FROM   shrtgpa
                      WHERE  shrtgpa_pidm = pidm
                      AND    shrtgpa_gpa_type_ind = 'I'
                      AND    shrtgpa_hours_attempted > 0
                    ),'never'))        AS last_att,
                    'Marked STYP '||styp||', but hasn''t attended DSU since HS'
                                       AS reason
             FROM   dailystats,
                    sorhsch,
                    spriden,
                    spbpers,
                    sobsbgi,
                    stvsbgi
             WHERE  spriden_change_ind IS NULL
             AND    pidm = spriden_pidm
             AND    pidm = sorhsch_pidm (+)
             AND    pidm = spbpers_pidm
             AND    pidm = sorhsch_pidm
             AND    sorhsch_sbgi_code = stvsbgi_code
             AND    sorhsch_sbgi_code = sobsbgi_sbgi_code
             AND    styp IN ('R','C')
             AND    NOT EXISTS
                    (
                      SELECT 'Y'
                      FROM   bailey.students03@dscir
                      WHERE  dsc_pidm = pidm
                      AND    s_entry_action <> 'HS'
                    )
             AND    NOT EXISTS
                    (
                      SELECT 'Y'
                      FROM   shrtgpa
                      WHERE  shrtgpa_pidm = pidm
                      AND    shrtgpa_gpa_type_ind = 'I'
                      AND    shrtgpa_hours_attempted > 0
                    )
           )
    ORDER  BY reason, pidm;
    --  result(s)

 ---------------------------------------------------------------------------------------------------
 /* Tab/Num: [ Student Type ][ 5 ]
  * Action:  Send results to Julie Stender
  * Notes:   this checks for those with R styp but have been enrolled in the past year and s/b C.
  *          if soactrm not run yet then R will be converted to C if last term here.
  */

    SELECT COUNT(pidm) AS stu_type_table_5_errors
 -- SELECT DISTINCT *
    FROM   (
             SELECT DISTINCT
                    pidm               AS pidm,
                    ID                 AS banner_id,
                    f_format_name(spriden_pidm,'LFMI')
                                       AS full_name,
                    styp               AS stu_type,
                    hsgraddt           AS hsgrad_dt,
                    cur_prgm           AS curr_prgm,
                    s_entry_action     AS ea_then,
                    MAX(substr(dsc_term_code,0,5)||0) AS last_term,
                    'Marked STYP '||styp||', but has attended DSU in past year'
                                       AS reason
             FROM   dailystats,
                    bailey.students03@dscir,
                    spriden
             WHERE  pidm = dsc_pidm
             AND    spriden_change_ind IS NULL
             AND    spriden_pidm = pidm
             AND    styp = 'R'
             AND    s_entry_action <> 'HS'
             AND    substr(dsc_term_code,0,5)||0 IN -- the previous fall and spring
                    (
                      SELECT term_code
                      FROM   (
                               SELECT stvterm_code AS term_code, row_number() OVER (ORDER BY stvterm_code DESC) AS rn
                               FROM   stvterm
                               WHERE  stvterm_code < '202120'
                               AND    substr(stvterm_code, 5, 1) != '3'
                             )
                      WHERE  rn <= 2
                    )
             GROUP  BY spriden_pidm, pidm, ID, styp, cur_prgm, s_entry_action,
                       s_cum_hrs_ugrad/10, hsgraddt, dsc_term_code
             ORDER  BY MAX(substr(dsc_term_code,0,5)||0)
           );
    --  result(s)

 ---------------------------------------------------------------------------------------------------
 /* Tab/Num: [ Student Type ][ 6 ]
  * Action:  Send results to Julie Stender
  * Notes:   Find students who are marked HS, but shouldn't be...
  */

    SELECT COUNT(DISTINCT(pidm)) AS stu_type_table_6_errors
 -- SELECT DISTINCT *
    FROM   (
             SELECT pidm     AS pidm,
                    ID       AS banner_id,
                    f_format_name(spriden_pidm,'LFMI')
                             AS full_name,
                    styp     AS stu_type,
                    hsgraddt AS hsgrad_dt,
                    cur_prgm AS curr_prgm,
                    'Marked STYP '||styp||', but not in CE Program'
                             AS reason
             FROM   dailystats,
                    spriden
             WHERE  styp = 'H'
             AND    spriden_change_ind IS NULL
             AND    spriden_pidm = pidm
             AND    cur_prgm NOT IN ('CE-CONC','ND-CE','ND-CONC','ND-SA', 'ND-ACE')
           );
    --  result(s)

 ---------------------------------------------------------------------------------------------------
 /* Tab/Num: [ Student Type ][ 7 ]
  * Action:  Send results to Julie Stender
  * Notes:   Personal Interest students in degree-seeking programs
  */

    SELECT COUNT(DISTINCT(pidm)) AS stu_type_table_7_errors
 -- SELECT DISTINCT *
    FROM   (
             SELECT pidm     AS pidm,
                    ID       AS banner_id,
                    f_format_name(spriden_pidm,'LFMI')
                             AS full_name,
                    styp     AS stu_type,
                    hsgraddt AS hsgrad_dt,
                    cur_prgm AS curr_prgm,
                    'Personal interest student enrolled in degree-seeking program'
                             AS reason
             FROM   dailystats,
                    spriden
             WHERE  styp = 'P'
             AND    spriden_change_ind IS NULL
             AND    spriden_pidm = pidm
             AND    cur_prgm NOT IN ('CE-CONC','ND-CE','ND-BADM','ND-ESL')

             UNION

             SELECT pidm     AS pidm,
                    ID       AS banner_id,
                    f_format_name(spriden_pidm,'LFMI')
                             AS full_name,
                    styp     AS stu_type,
                    hsgraddt AS hsgrad_dt,
                    cur_prgm AS curr_prgm,
                    'Degree-seeking student in Personal interest program'
                             AS reason
             FROM   dailystats,
                    spriden
             WHERE  styp != 'P'
             AND    spriden_change_ind IS NULL
             AND    spriden_pidm = pidm
             AND    cur_prgm IN ('CE-CONC','ND-CE','ND-BADM','ND-ESL')
           );
    --  result(s)

 ---------------------------------------------------------------------------------------------------
 /* Tab/Num: [ Student Type ][ 8 ]
  * Action:  Send results to Julie Stender
  * Notes:   Find students coded HS concurrent who have financial aid.
  */

  -- NEEDS PARTITIONING TO REMOVE DUPLICATES

    SELECT COUNT(DISTINCT(pidm)) AS stu_type_table_8_errors
 -- SELECT DISTINCT *
    FROM   (
             SELECT DISTINCT(pidm)      AS pidm,
                    ID                  AS banner_id,
                    f_format_name(spriden_pidm,'LFMI')
                                        AS full_name,
                    styp                AS stu_type,
                    hsgraddt            AS hsgrad_dt,
                    cur_prgm            AS curr_prgm,
                    rcrapp4_hs_ged_rcvd AS has_ged,
                    'HS CE Student has FinAid'
                                        AS reason
             FROM   dailystats,
                    rcrapp4,
                    spriden
             WHERE  spriden_pidm        = rcrapp4_pidm
             AND    rcrapp4_pidm        = pidm
             AND    rcrapp4_aidy_code   = '1819' -- <-- AYAY of this academic year
             AND    rcrapp4_infc_code   = 'EDE'
             AND    styp                = 'H'
             AND    reg_type           != 'HS'
             AND    spriden_change_ind IS NULL
           );
           -- integrate RPRAWRD
    --  result(s)

 ---------------------------------------------------------------------------------------------------
 /* Tab/Num: [ Student Type ][ 9 ]
  * Action:  Send results to Julie Stender
  * Notes:   applied for fin aid, usually only those with valid program not ND-CE, had aid and need
  *          styp corrected if it's set to 'H' or 'P'.
  */

    SELECT COUNT(DISTINCT(pidm)) AS stu_type_table_9_errors
 -- SELECT DISTINCT *
    FROM   (
             SELECT pidm             AS pidm,
                    ID               AS banner_id,
                    f_format_name(spriden_pidm,'LFMI')
                                     AS full_name,
                    styp             AS stu_type,
                    hsgraddt         AS hsgrad_dt,
                    cur_prgm         AS curr_prgm,
                    sum(rpratrm_paid_amt) AS rprawrd_paid,
                    "F/P/N"          AS pt_ft,
                    classcode        AS class_code,
                    stu_age          AS age,
                    reg_type         AS entry_action,
                    'ND/CE applied for FinAid'
                                     AS reason
             FROM   faismgr.rpratrm,
                    enroll.dailystats,
                    spriden
             WHERE  rpratrm_pidm      = pidm
             AND    spriden_change_ind IS NULL
             AND    spriden_pidm = pidm
             AND    rpratrm_period = '202120' -- <-- AYAY of reporting academic year
             AND    rpratrm_paid_amt  > 0
             AND    styp IN ('H','P')
             GROUP  BY pidm, id, spriden_pidm, styp, hsgraddt, cur_prgm, "F/P/N", classcode, stu_age, reg_type
           );
    --  result(s)

 ---------------------------------------------------------------------------------------------------
 /* Tab/Num: [ Student Type ][ 10 ]
  * Action:  Send results to Julie Stender
  * Notes:   Find students coded HS concurrent who have graduated HS
  */

    SELECT COUNT(DISTINCT(pidm)) AS stu_type_table_10_errors
 -- SELECT DISTINCT *
    FROM   (
             SELECT DISTINCT(pidm)      AS pidm,
                    ID                  AS banner_id,
                    f_format_name(spriden_pidm,'LFMI')
                                        AS full_name,
                    styp                AS stu_type,
                    hsgraddt            AS hsgrad_dt,
                    cur_prgm            AS curr_prgm,
                 -- valid_pgm           AS valid_ind,
                    'HS CE Student has already graduated HS'
                                        AS reason
             FROM   dailystats,
                    stvterm,
                    spriden
             WHERE  pidm = spriden_pidm
             AND    spriden_change_ind IS NULL
             AND    stvterm_code = '202120'
             AND    hsgraddt < stvterm_start_date
             AND    styp = 'H'
           );
    --  result(s)

 ---------------------------------------------------------------------------------------------------

 ---------------------------------------------------------------------------------------------------
 /* Tab/Num:  [ Classes ] [ 1 ]
  * Action:   Send results to Sharon Lee
  * Notes:    Finds classes that have been cancelled, but still have students still enrolled.
  */

    SELECT COUNT(DISTINCT(crn)) AS classes_table_1_errors
 -- SELECT DISTINCT *
    FROM   (
             SELECT ssbsect_term_code AS term_code,
                    ssbsect_crn       AS crn,
                    ssbsect_subj_code AS subj_code,
                    ssbsect_crse_numb AS crse_num,
                    ssbsect_seq_numb  AS seq_num,
                    ssbsect_schd_code AS shcd_code,
                    ssbsect_enrl      AS enrl_count,
                    ssbsect_ssts_code AS ssts_code,
                    'Students still enrolled in cancelled class.'
                                      AS reason
             FROM   ssbsect
             WHERE  ssbsect_term_code = '202120' -- <-- YYYYTT of this reporting term
             AND    ssbsect_ssts_code <> 'A'
             AND    ssbsect_enrl > 0
           );
    --  result(s)

 ---------------------------------------------------------------------------------------------------
 /* Tab/Num:  [ Classes ] [ 2 ]
  * Action:   Send results to Sharon Lee
  * Notes:    Finds evening classess that are not in a 5% (50's) Section.
  */

    SELECT COUNT(DISTINCT(crn)) AS classes_table_2_errors
 -- SELECT DISTINCT *
    FROM   (
             SELECT ssbsect_term_code AS term_code,
                    ssbsect_crn       AS crn,
                    ssbsect_subj_code AS subj_code,
                    ssbsect_crse_numb AS crse_num,
                    ssbsect_seq_numb  AS seq_num,
                    ssbsect_schd_code AS shcd_code,
                    begin_time1       AS begin_time1,
                    'Evening Course not in 5% (50s Series) Section '
                                      AS reason
             FROM   ssbsect,
                    as_catalog_schedule
             WHERE  ssbsect_crn = crn_key
             AND    ssbsect_term_code = term_code_key
             AND    ssbsect_term_code = '202120' -- <-- YYYYTT of this reporting term
             AND    ssbsect_ssts_code = 'A'
             AND    begin_time1       > '1700'
             AND    ssbsect_seq_numb NOT LIKE '5%'
             AND    ssbsect_seq_numb NOT LIKE '7%'
             AND    ssbsect_seq_numb NOT LIKE '9%'
           );
    --  result(s)

 ---------------------------------------------------------------------------------------------------
 /* Tab/Num:  [ Classes ] [ 3 ]
  * Action:   Send results to Sharon Lee
  * Notes:    Courses with missing SCCD (Site) Code
  */

    SELECT COUNT(DISTINCT(crn)) AS classes_table_3_errors
 -- SELECT DISTINCT *
    FROM   (
             SELECT ssbsect_term_code AS term_code,
                    ssbsect_crn       AS crn,
                    ssbsect_subj_code AS subj_code,
                    ssbsect_crse_numb AS crse_num,
                    ssbsect_seq_numb  AS seq_num,
                    ssbsect_schd_code AS shcd_code,
                    ssbsect_enrl      AS enrl_count,
                    ssbsect_ssts_code AS ssts_code,
                    'Missing Budget Code.'
                                      AS reason
             FROM   ssbsect,
                    ssrsccd
             WHERE  ssbsect_term_code = '202120' -- <-- YYYYTT of this reporting term
             AND    ssbsect_ssts_code = 'A'
             AND    ssbsect_term_code = ssrsccd_term_code
             AND    ssbsect_crn       = ssrsccd_crn
             AND    ssrsccd_sccd_code IS NULL
           );
    --  result(s)

 ---------------------------------------------------------------------------------------------------
 /* Tab/Num: [ Classes ] [ 4 ]
  * Action:  Send results to Sharon Lee
  * Notes:   This query is used to check and ensure that HS courses are assigned the correct budget
  *          code. It will show All Courses coded BC or SF with a Section of A01, B80, or O01 that
  *          do not have a SEQ number 'S' for the specified term.
  */

  -- look into only showing SD and BA, and even look to see if the section coding to further filter results.

    SELECT COUNT(DISTINCT(crn)) AS classes_table_4_errors
 -- SELECT DISTINCT *
    FROM   (
             SELECT ssrsccd_term_code AS term_code,
                    ssrsccd_crn       AS crn,
                    ssbsect_subj_code AS crse_subj,
                    ssbsect_crse_numb AS crse_num,
                    ssbsect_seq_numb  AS seq_num,
                    ssbsect_schd_code AS schd_code,
                    ssbsect_enrl      AS enroll_count,
                    -- And campus code
                    ssrsccd_sccd_code AS sccd_code,
                    'HSCE Section with non-HSCE Budget Code?'
                                      AS reason
             FROM   saturn.ssrsccd,
                    saturn.ssbsect
             WHERE  ssrsccd_crn        = ssbsect_crn
             AND    ssrsccd_term_code  = '202120' -- <-- YYYYTT of this reporting term
             AND    ssrsccd_term_code  = ssbsect_term_code
             AND    ssrsccd_sccd_code NOT IN ('BC','SF')
             AND    (
		                     ssbsect_seq_numb LIKE '%V%'
			                OR ssbsect_seq_numb LIKE '%S%'
			                OR ssbsect_seq_numb LIKE 'S%'
			                OR ssbsect_seq_numb LIKE '%X%'
			                OR ssbsect_seq_numb LIKE '%J%'
                    )

             UNION ALL

             SELECT ssrsccd_term_code AS term_code,
                    ssrsccd_crn       AS crn,
                    ssbsect_subj_code AS crse_subj,
                    ssbsect_crse_numb AS crse_num,
                    ssbsect_seq_numb  AS seq_num,
                    ssbsect_schd_code AS schd_code,
                    ssbsect_enrl      AS enroll_count,
                    -- And campus code
                    ssrsccd_sccd_code AS sccd_code,
                    'non-HSCE Section with HSCE Budget Code?'
                                      AS reason
             FROM   saturn.ssrsccd,
                    saturn.ssbsect
             WHERE  ssrsccd_crn        = ssbsect_crn
             AND    ssrsccd_term_code  = '202120' -- <-- YYYYTT of this reporting term
             AND    ssrsccd_term_code  = ssbsect_term_code
             AND    ssrsccd_sccd_code IN ('BC','SF')
             AND    (
		                      ssbsect_seq_numb NOT LIKE '%V%'
			                AND ssbsect_seq_numb NOT LIKE '%S%'
			                AND ssbsect_seq_numb NOT LIKE 'S%'
			                AND ssbsect_seq_numb NOT LIKE '%X%'
			                AND ssbsect_seq_numb NOT LIKE '%J%'
                    )
             ORDER  BY sccd_code
           );
    --  result(s)

 ---------------------------------------------------------------------------------------------------
 /* Tab/Num: [ COURSES ][ 6 ]
  * Action:  Send results to Sharon Lee
  * Notes:   Finds courses marked OCCS Code 'A' that should not be.
  */

    SELECT COUNT(*) AS classes_table_6_errors
 -- SELECT DISTINCT *
    FROM   (
             SELECT '202120'          AS term_code,
                    scbsupp_subj_code AS subj_code,
                    scbsupp_crse_numb AS crse_num,
                    scbsupp_occs_code AS occs_code,
                    ay                AS academic_yr,
                    qualifies         AS does_qualify,
                    ''                AS spacer1,
                    ''                AS spacer2,
                    ''                AS spacer3,
                    'Course should be OCCS Code V'
                                      AS reason
             FROM   scbsupp,
                    scbcrse A,
                    voccrs_current -- <-- voccrs_AYAY of this academic year
             WHERE  scbsupp_subj_code = scbcrse_subj_code
             AND    scbsupp_crse_numb = scbcrse_crse_numb
             AND    scbsupp_eff_term  =
                    (
                      SELECT MAX(b.scbsupp_eff_term)
                      FROM   scbsupp b,
                             scbcrky c
                      WHERE  b.scbsupp_subj_code     = scbcrky_subj_code
                      AND    b.scbsupp_crse_numb     = scbcrky_crse_numb
                      AND    b.scbsupp_subj_code     = A.scbcrse_subj_code
                      AND    b.scbsupp_crse_numb     = A.scbcrse_crse_numb
                      AND    c.scbcrky_term_code_end = '999999'
                      GROUP  BY b.scbsupp_subj_code, b.scbsupp_crse_numb
                    )
             AND    scbsupp_subj_code = subj
             AND    scbsupp_crse_numb = crse
             AND   (scbsupp_occs_code = 'A' OR scbsupp_occs_code IS NULL)
             GROUP  BY scbsupp_subj_code, scbsupp_crse_numb, scbsupp_occs_code, qualifies, ay
             ORDER  BY scbsupp_subj_code, scbsupp_crse_numb, scbsupp_occs_code DESC
           );
    --  result(s)

    --Online Errors
SELECT COUNT(DISTINCT(crn)) AS classes_table_8_errors
 -- SELECT DISTINCT *
    FROM   (
             SELECT ssrsccd_term_code AS term_code,
                    ssrsccd_crn       AS crn,
                    ssbsect_subj_code AS crse_subj,
                    ssbsect_crse_numb AS crse_num,
                    ssbsect_seq_numb  AS seq_num,
                    ssbsect_schd_code AS schd_code,
                    ssbsect_enrl      AS enroll_count,
                    -- And campus code
                    ssbsect_camp_code AS camp_code,
                    ssbsect_insm_code AS insm_code,
                    'Online Error'
                                      AS reason
             FROM   saturn.ssrsccd,
                    saturn.ssbsect
             WHERE  ssrsccd_crn        = ssbsect_crn
             AND    ssrsccd_term_code  = '202120' -- <-- YYYYTT of this reporting term
             AND    ssrsccd_term_code  = ssbsect_term_code
             AND    (
                (ssbsect_camp_code != 'O01' AND ssbsect_seq_numb LIKE '4%' AND ssbsect_insm_code = 'I')
             OR (ssbsect_camp_code IN ('O01', 'UOS') AND ssbsect_seq_numb LIKE '4%' AND ssbsect_insm_code != 'I' )
             OR (ssbsect_camp_code = 'O01' AND ssbsect_seq_numb LIKE '4%' AND ssbsect_insm_code != 'I' )
             OR (ssbsect_camp_code IN ('O01', 'UOS') AND ssbsect_seq_numb NOT LIKE '4%' AND ssbsect_insm_code = 'I' )
             OR (ssbsect_camp_code = 'O01' AND ssbsect_seq_numb NOT LIKE '4%' AND ssbsect_insm_code = 'I' )
             OR (ssbsect_camp_code != 'O01' AND ssbsect_seq_numb NOT LIKE '4%' AND ssbsect_insm_code = 'I' )
             OR (ssbsect_camp_code IN ('O01', 'UOS') AND ssbsect_seq_numb NOT LIKE '4%' AND ssbsect_insm_code != 'I' )
       ));

 ---------------------------------------------------------------------------------------------------
 /* Tab/Num:  [ Classes ] [ 7 ]
  * Action:   Send results to Sharon Lee
  * Notes:
  */

    SELECT COUNT(*) AS classes_table_7_errors
 -- SELECT DISTINCT *   
    FROM   (
             SELECT ssbsect_term_code AS term_code, 
                    ssbsect_crn       AS crn, 
                    ssbsect_subj_code AS subj_code, 
                    ssbsect_crse_numb AS crse_num, 
                    ssbsect_seq_numb  AS seq_num,
                    ssbsect_insm_code AS insm_code,
                    ssbsect_camp_code AS camp_code,
                    ssrsccd_sccd_code AS sccd_code,
                    bldg_code1        AS bldg_code,
                    room_code1        AS room_code,
                    'Course lists Building but no Room Number?'
                                      AS reason
             FROM   as_catalog_schedule, 
                    ssbsect,
                    ssrsccd
             wHERE  ssrsccd_crn = ssbsect_crn
             AND    ssbsect_crn = crn_key
             AND    ssbsect_term_code = term_code_key
             AND    ssrsccd_term_code = term_code_key
             AND    ssbsect_insm_code NOT IN ('I','E')
             AND    ssts_code = 'A' 
             AND    camp_code <> 'XXX'    
             AND    term_code_key = '202120'
             AND    bldg_code1 NOT IN ('VIRT', 'ONLINE')
             AND    bldg_code1 IS NOT NULL 
             AND    room_code1 IS NULL
           );
    --  result(s)

 ---------------------------------------------------------------------------------------------------
 /* Tab/Num:  [ Classes ] [ 8 ]
  * Action:   Send results to Sharon Lee
  * Notes:    
  */ /*

    SELECT COUNT(DISTINCT(crn)) AS classes_table_8_errors
 -- SELECT DISTINCT *   
    FROM   (
             SELECT ssbsect_term_code AS term_code, 
                    ssbsect_crn       AS crn, 
                    ssbsect_subj_code AS subj_code, 
                    ssbsect_crse_numb AS crse_num, 
                    ssbsect_seq_numb  AS seq_num,
                    ssbsect_insm_code AS insm_code,
                    ssbsect_camp_code AS camp_code,
                    ssrsccd_sccd_code AS sccd_code,
                    bldg_code1        AS bldg_code,
                    room_code1        AS room_code,
                    'Traditional Course lists no Building/Room?'
                                      AS reason
             FROM   as_catalog_schedule, 
                    ssbsect,
                    ssrsccd
             wHERE  ssrsccd_crn = ssbsect_crn
             AND    ssbsect_crn = crn_key
             AND    ssrsccd_term_code = term_code_key
             AND    ssbsect_term_code = term_code_key
             AND    ssbsect_insm_code NOT IN ('I','E')
             AND    ssts_code = 'A' 
             AND    camp_code <> 'XXX'    
             AND    term_code_key = '202120'
             AND    bldg_code1 IS NULL
           );
    --  result(s)

 ---------------------------------------------------------------------------------------------------
 ---------------------------------------------------------------------------------------------------
 ---------------------------------------------------------------------------------------------------
 ---------------------------------------------------------------------------------------------------
 /* Tab/Num: 
  * Action:  Send results to Julie Stender   
  * Notes:   Check for students without a valid s_ID of '000000000'
  */ 
    /* 
    SELECT spriden.* 
    FROM   spriden 
    WHERE  spriden_id = '000000000';
 
 ---------------------------------------------------------------------------------------------------
 /* Tab/Num: 
  * Action:  Send results to Julie Stender   
  * Notes:   WashCnt School dist tuition and not HS -- won't find before 3rd week as AR hasn't posted
  */ /*
 
    SELECT COUNT(DISTINCT(pidm)) AS unspecified_table_3_errors
 -- SELECT DISTINCT *
    FROM   (
             SELECT DISTINCT(pidm)    AS pidm, 
                    ID                AS banner_id, 
                    f_format_name(spriden_pidm,'LFMI')                 
                                      AS full_name,
                    styp              AS stu_type,
                    hsgraddt          AS hsgrad_dt, 
                    cur_prgm          AS curr_prgm, 
                    tbraccd_term_code AS term_code, 
                    tbraccd_desc      AS accd_desc,
                    'Not Marked STYP H, but has WashCo Shool District Tuition'
                                      AS reason
             FROM   taismgr.tbraccd, 
                    dailystats,
                    spriden
             WHERE  spriden_pidm = pidm
             AND    spriden_change_ind IS NULL
             AND    tbraccd_term_code    = '202120' -- <-- YYYYTT of this reporting term
             AND    tbraccd_pidm         = pidm
             AND    tbraccd_detail_code IN ('7200', '7006')
             AND    styp                <> 'H'
           ); 
    --  result(s)
 
 ---------------------------------------------------------------------------------------------------
 -- End: General Error Checking Queries                                                           --
 ---------------------------------------------------------------------------------------------------
 ---------------------------------------------------------------------------------------------------
 -- START: EOT ONLY Error Checking Queries                                                        --
 ---------------------------------------------------------------------------------------------------
 
 ---------------------------------------------------------------------------------------------------
 /* Tab/Num: [ Student Type ][  ]
  * Action:  Send results to Julie Stender   
  * Notes:   at EOT dump above pidms and change the syear sterm code to find those who were different
  *          09.05.2014: created subquery to dump pidms from above query  
  */
  /*
    SELECT COUNT(DISTINCT(pidm)) AS unspecified_table_4_errors
 -- SELECT DISTINCT *
    FROM   (
             SELECT DISTINCT(pidm)     AS pidm, 
                    ID                 AS banner_id,  
                    f_format_name(spriden_pidm,'LFMI')                 
                                       AS full_name,
                    hsgraddt           AS hsgrad_dt, 
                    substr(dsc_term_code,0,5)||0 
                                       AS term_then,
                    s_entry_action     AS ea_then,  
                    styp               AS stu_type,  
                    cur_prgm           AS curr_prgm,
                    s_cum_hrs_ugrad/10 AS sum_hrs,
                    'Entry Action changed since 3rd Week' 
                                       AS reason
             FROM   bailey.students03@dscir,
                    dailystats,
                    spriden
             WHERE  pidm = dsc_pidm
             AND    spriden_change_ind IS NULL
             AND    spriden_pidm = pidm
             AND    s_entry_action <> 'HS'
             AND    pidm IN 
                    (
                      SELECT DISTINCT(shrtckn_pidm)
                      FROM   "SATURN"."SHRTCKN", dailystats, sorhsch
                      WHERE  shrtckn_pidm = pidm
                      AND    shrtckn_pidm = sorhsch_pidm (+)
                      AND    shrtckn_term_code < '202120'  -- <-- YYYYTT of this reporting term
                      AND    styp NOT IN  ('C','R','P')
                      AND    shrtckn_subj_code NOT IN ('CED','STIT','ICL','ADE', 'SAB')
                    ) 
             AND    dsc_term_code = '202120'  -- <-- YYYYTT of this reporting term
             ORDER  BY styp, s_entry_action, hsgraddt, pidm
           );
    --  result(s)
 
 ---------------------------------------------------------------------------------------------------
 /* Tab/Num: [ EOT Only ][ 1 ]
  * Action:  Send results to Julie Stender   
  * Notes:   was their EA changed for a valid reason during enrollment at 3rd week
  */
  
    SELECT COUNT(DISTINCT(pidm)) AS eot_only_table_1_errors
 -- SELECT x.* 
    FROM   (
             SELECT d.pidm         AS pidm,   
                    d.ID           AS banner_id,
                    f_format_name(spriden_pidm,'LFMI')                 
                                   AS full_name,
                    cur_prgm1      AS curr_prgm, 
                    s_entry_action AS ea_3rd, 
                    s.styp         AS stu_type_3rd, 
                    d.styp         AS stu_type_eot,  
                    d.cur_prgm     AS curr_prgm_eot,
                    d.hsgraddt     AS hsgrad_dt,
                    (
                      SELECT MAX(substr(dsc_term_code,0,5)||0)
                      FROM   students03@dscir
                      WHERE  dsc_pidm = d.pidm
                      AND    s_entry_action <> 'HS'
                      AND    dsc_term_code < '202120' -- update each term
                    ) AS last_term_dsu,
                    (
                      SELECT sum(shrtrcr_trans_credit_hours) 
                      FROM   shrtrcr
                      WHERE  shrtrcr_pidm = d.pidm
                    )              AS xfer_credits,
                    'Check Entry Action Change' 
                                   AS reason
             FROM   students_202043 s, -- update each term
                    dailystats d,
                    spriden
             WHERE  d.pidm = s.pidm
             AND    spriden_change_ind IS NULL
             AND    spriden_pidm = d.pidm
             AND    s_entry_action <> 'FH'
             AND    s_entry_action <> 'FF' 
             AND    d.styp = 'F'
             
             UNION ALL
         
             SELECT d.pidm         AS pidm,   
                    d.ID           AS banner_id,
                    f_format_name(spriden_pidm,'LFMI')                 
                                   AS full_name,
                    cur_prgm1      AS curr_prgm, 
                    s_entry_action AS ea_3rd, 
                    s.styp         AS stu_type_3rd, 
                    d.styp         AS stu_type_eot,  
                    d.cur_prgm     AS curr_prgm_eot,
                    d.hsgraddt     AS hsgrad_dt,
                    (
                      SELECT MAX(substr(dsc_term_code,0,5)||0)
                      FROM   students03@dscir
                      WHERE  dsc_pidm = d.pidm
                      AND    s_entry_action <> 'HS'
                      AND    dsc_term_code < '202120' -- update each term
                    ) AS last_term_dsu,
                    (
                      SELECT sum(shrtrcr_trans_credit_hours) 
                      FROM   shrtrcr
                      WHERE  shrtrcr_pidm = d.pidm
                    )              AS xfer_credits,
                    'Check Entry Action Change' 
                                   AS reason
             FROM   students_202043 s, -- update each term
                    dailystats d,
                    spriden
             WHERE  d.pidm  = s.pidm
             AND    s.styp <> d.styp
             AND    spriden_change_ind IS NULL
             AND    spriden_pidm = d.pidm
           ) x,
           stvterm
    WHERE  stvterm_code = '202120'
           -- Exclude Valid Corrections
    AND    NOT ((stu_type_3rd IN ('N','F') OR ea_3rd IN ('FF','FH','TU')) AND last_term_dsu <   202120       )
    AND    NOT ((stu_type_eot = 'C'        OR ea_3rd = 'CS'             ) AND last_term_dsu >= (202120 - 100))
    AND    NOT ((stu_type_eot = 'R'        OR ea_3rd = 'RS'             ) AND last_term_dsu <  (202120 - 100))
    AND    NOT ((stu_type_3rd = 'H'        OR ea_3rd = 'HS'             ) AND hsgrad_dt <= stvterm_start_date) 
    AND    NOT ((stu_type_3rd = 'H'        OR ea_3rd = 'HS'             ) AND hsgrad_dt >  stvterm_start_date);
    --  result(s)
     
 ---------------------------------------------------------------------------------------------------

 ---------------------------------------------------------------------------------------------------
 -- END: EOT ONLY Error Checking Queries                                                          --
 ---------------------------------------------------------------------------------------------------
 
-- end of file