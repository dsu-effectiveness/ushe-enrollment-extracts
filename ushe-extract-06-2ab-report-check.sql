
 -- Last Res: All Data matched USHE's Data
 -- Params:   Extract Table Names, replace all instances of >>20172E<< with desired term
 -- Action:   Update parameter(s) and run query. Send results to ???
 -- Notes:    Use this to check USHE's Report 2AB. Note these do not check for E&G. If the
 --           school starts a non-E&G program, these scripts will need updating. They also
 --           do not check for duplicated records as none were reported for this term. If
 --           the term will have duplicates, you will need to run these scripts with and 
 --           without the 'DISTINCT' in the SELECT portion of the queries. 
 ----------------------------------------------------------------------------------------
 
 
 ----------------------------------------------------------------------------------------
 -- REPORT 2A | TABLE 1/2 ---------------------------------------------------------------
 ----------------------------------------------------------------------------------------
 
 SELECT DISTINCT
        (
          -- Headcount - Resident - Male  
          SELECT count(DISTINCT(s_id))
          FROM   student_courses_current sc, students_current s, courses_current c
          WHERE  sc_pidm = s_pidm
          AND    sc_crn = c_crn
          AND    s_gender = 'M' 
          AND    s_regent_res IN ('A','M','R')
          GROUP  BY s_gender
        ) 
        AS HC_RESID_MALE,
        (
          -- Headcount - Resident - Female  
          SELECT count(DISTINCT(s_id))
          FROM   student_courses_current sc, students_current s, courses_current c
          WHERE  sc_pidm = s_pidm
          AND    sc_crn = c_crn
          AND    s_gender = 'F' 
          AND    s_regent_res IN ('A','M','R')
          GROUP  BY s_gender
        )
        AS HC_RESID_FEMALE,
        (
          -- Headcount - Resident - Total  
          SELECT count(DISTINCT(s_id))
          FROM   student_courses_current sc, students_current s, courses_current c
          WHERE  sc_pidm = s_pidm
          AND    sc_crn = c_crn
          AND    s_regent_res IN ('A','M','R')
        )
        AS HC_RESID_TOTAL,
        (
          -- Headcount - Non-Resident - Male  
          SELECT count(DISTINCT(s_id))
          FROM   student_courses_current sc, students_current s, courses_current c
          WHERE  sc_pidm = s_pidm
          AND    sc_crn = c_crn
          AND    s_gender = 'M' 
          AND    s_regent_res IN ('N', 'G')
          GROUP  BY s_gender
        )
        AS HC_NORES_MALE,
        (
          -- Headcount - Non-Resident - Female  
          SELECT count(DISTINCT(s_id))
          FROM   student_courses_current sc, students_current s, courses_current c
          WHERE  sc_pidm = s_pidm
          AND    sc_crn = c_crn
          AND    s_gender = 'F' 
          AND    s_regent_res IN ('N', 'G')
          GROUP  BY s_gender
        )
        AS HC_NORES_FEMALE,
        (
          -- Headcount - Non-Resident - Total  
          SELECT count(DISTINCT(s_id))
          FROM   student_courses_current sc, students_current s, courses_current c
          WHERE  sc_pidm = s_pidm
          AND    sc_crn = c_crn
          AND    s_regent_res IN ('N', 'G')
        )
        AS HC_NORES_TOTAL,
        (
          -- Headcount - Overall  
          SELECT count(DISTINCT(s_id)) AS HC
          FROM   student_courses_current sc, students_current s, courses_current c
          WHERE  sc_pidm = s_pidm
          AND    sc_crn = c_crn
        )
        AS HC_TOTAL,
        0 as order_id
 FROM   student_courses_current
 ----------------------------------------------------------------------------------------

 UNION
 ----------------------------------------------------------------------------------------
 -- REPORT 2A | TABLE 3 -----------------------------------------------------------------
 ----------------------------------------------------------------------------------------
 
 SELECT DISTINCT
        (
          SELECT ( -- FTE - Resident - Male - Undergraduate Level
                    SELECT round(sum(sc_att_cr)/150 + sum(nvl(sc_contact_hrs,0))/450,2)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    s_gender = 'M' 
                    AND    c_level != 'G'
                    AND    s_regent_res IN ('A','M','R')
                )+(
                    -- FTE - Resident - Male - Graduate Level
                    SELECT nvl(round(sum(sc_att_cr)/100 + sum(nvl(sc_contact_hrs,0))/450,2),0)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    s_gender = 'M' 
                    AND    c_level  = 'G'
                    AND    s_regent_res IN ('A','M','R')
                  ) AS FTE_RESID_MALE
          FROM    DUAL
        )
        AS FTE_RESID_MALE,
        (
          SELECT ( -- FTE - Resident - Female - Undergraduate Level
                    SELECT round(sum(sc_att_cr)/150 + sum(nvl(sc_contact_hrs,0))/450,2)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    s_gender = 'F' 
                    AND    c_level != 'G'
                    AND    s_regent_res IN ('A','M','R')
                )+(
                    -- FTE - Resident - Female - Graduate Level
                    SELECT nvl(round(sum(sc_att_cr)/100 + sum(nvl(sc_contact_hrs,0))/450,2),0)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    s_gender = 'F' 
                    AND    c_level  = 'G'
                    AND    s_regent_res IN ('A','M','R')
                  ) AS FTE_RESID_FEMALE
          FROM    DUAL
        )
        AS FTE_RESID_FEMALE,
        (
          SELECT ( -- FTE - Resident - Undergraduate Level
                    SELECT round(sum(sc_att_cr)/150 + sum(nvl(sc_contact_hrs,0))/450,2)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    c_level != 'G'
                    AND    s_regent_res IN ('A','M','R')
                )+(
                    -- FTE - Resident Graduate Level
                    SELECT nvl(round(sum(sc_att_cr)/100 + sum(nvl(sc_contact_hrs,0))/450,2),0)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    c_level  = 'G'
                    AND    s_regent_res IN ('A','M','R')
                  ) AS FTE_RESID_TOTAL
          FROM    DUAL
        )
        AS FTE_RESID_TOTAL,
        (
          SELECT ( -- FTE - Non-Resident - Male - Undergraduate Level
                    SELECT round(sum(sc_att_cr)/150 + sum(nvl(sc_contact_hrs,0))/450,2)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    s_gender = 'M' 
                    AND    c_level != 'G'
                    AND    s_regent_res IN ('N', 'G')
                )+(
                    -- FTE - Non-Resident - Male - Graduate Level
                    SELECT nvl(round(sum(sc_att_cr)/100 + sum(nvl(sc_contact_hrs,0))/450,2),0)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    s_gender = 'M' 
                    AND    c_level  = 'G'
                    AND    s_regent_res IN ('N', 'G')
                  ) AS FTE_NORES_MALE
          FROM    DUAL
        )
        AS FTE_NORES_MALE,
        (
          SELECT ( -- FTE - Non-Resident - Female - Undergraduate Level
                    SELECT round(sum(sc_att_cr)/150 + sum(nvl(sc_contact_hrs,0))/450,2)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    s_gender = 'F' 
                    AND    c_level != 'G'
                    AND    s_regent_res IN ('N', 'G')
                )+(
                    -- FTE - Non-Resident - Female - Graduate Level
                    SELECT nvl(round(sum(sc_att_cr)/100 + sum(nvl(sc_contact_hrs,0))/450,2),0)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    s_gender = 'F' 
                    AND    c_level  = 'G'
                    AND    s_regent_res IN ('N', 'G')
                  ) AS FTE_NORES_FEMALE
          FROM    DUAL
        )
        AS FTE_NORES_FEMALE,
        (
          SELECT ( -- FTE - Non-Resident - Undergraduate Level
                    SELECT round(sum(sc_att_cr)/150 + sum(nvl(sc_contact_hrs,0))/450,2)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    c_level != 'G'
                    AND    s_regent_res IN ('N', 'G')
                )+(
                    -- FTE - Non-Resident Graduate Level
                    SELECT nvl(round(sum(sc_att_cr)/100 + sum(nvl(sc_contact_hrs,0))/450,2),0)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    c_level  = 'G'
                    AND    s_regent_res IN ('N', 'G')
                  ) AS FTE_NORES_TOTAL
          FROM    DUAL
        )
        AS FTE_NORES_TOTAL,
        (
          SELECT ( -- FTE - Overall - Undergraduate Level
                    SELECT round(sum(sc_att_cr)/150 + sum(nvl(sc_contact_hrs,0))/450,2)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    c_level != 'G'
                )+(
                    -- FTE - Overall Graduate Level
                    SELECT nvl(round(sum(sc_att_cr)/100 + sum(nvl(sc_contact_hrs,0))/450,2),0)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    c_level  = 'G'
                  ) AS FTE_TOTAL
          FROM    DUAL
        )
        AS FTE_TOTAL,
        1 as order_id
 FROM   student_courses_current
 ----------------------------------------------------------------------------------------
 
 UNION
 
 SELECT NULL,NULL,NULL,NULL,NULL,NULL,NULL,1.5 FROM DUAL
 
 UNION
 
 ----------------------------------------------------------------------------------------
 -- REPORT 2B | TABLE 1/2 ---------------------------------------------------------------
 ----------------------------------------------------------------------------------------
 
 SELECT DISTINCT
        (
          -- Headcount - Resident - Male  
          SELECT count(DISTINCT(s_id))
          FROM   student_courses_current sc, students_current s, courses_current c
          WHERE  sc_pidm = s_pidm
          AND    sc_crn = c_crn
          AND    s_gender = 'M' 
          AND    s_regent_res IN ('A','M','R')
          AND    c_budget_code LIKE 'B%'
          GROUP  BY s_gender
        ) 
        AS HC_RESID_MALE,
        (
          -- Headcount - Resident - Female  
          SELECT count(DISTINCT(s_id))
          FROM   student_courses_current sc, students_current s, courses_current c
          WHERE  sc_pidm = s_pidm
          AND    sc_crn = c_crn
          AND    s_gender = 'F' 
          AND    s_regent_res IN ('A','M','R')
          AND    c_budget_code LIKE 'B%'
          GROUP  BY s_gender
        )
        AS HC_RESID_FEMALE,
        (
          -- Headcount - Resident - Total  
          SELECT count(DISTINCT(s_id))
          FROM   student_courses_current sc, students_current s, courses_current c
          WHERE  sc_pidm = s_pidm
          AND    sc_crn = c_crn
          AND    s_regent_res IN ('A','M','R')
          AND    c_budget_code LIKE 'B%'
        )
        AS HC_RESID_TOTAL,
        (
          -- Headcount - Non-Resident - Male  
          SELECT count(DISTINCT(s_id))
          FROM   student_courses_current sc, students_current s, courses_current c
          WHERE  sc_pidm = s_pidm
          AND    sc_crn = c_crn
          AND    s_gender = 'M' 
          AND    s_regent_res IN ('N', 'G')
          AND    c_budget_code LIKE 'B%'
          GROUP  BY s_gender
        )
        AS HC_NORES_MALE,
        (
          -- Headcount - Non-Resident - Female  
          SELECT count(DISTINCT(s_id))
          FROM   student_courses_current sc, students_current s, courses_current c
          WHERE  sc_pidm = s_pidm
          AND    sc_crn = c_crn
          AND    s_gender = 'F' 
          AND    s_regent_res IN ('N', 'G')
          AND    c_budget_code LIKE 'B%'
          GROUP  BY s_gender
        )
        AS HC_NORES_FEMALE,
        (
          -- Headcount - Non-Resident - Total  
          SELECT count(DISTINCT(s_id))
          FROM   student_courses_current sc, students_current s, courses_current c
          WHERE  sc_pidm = s_pidm
          AND    sc_crn = c_crn
          AND    s_regent_res IN ('N', 'G')
          AND    c_budget_code LIKE 'B%'
        )
        AS HC_NORES_TOTAL,
        (
          -- Headcount - Overall  
          SELECT count(DISTINCT(s_id)) AS HC
          FROM   student_courses_current sc, students_current s, courses_current c
          WHERE  sc_pidm = s_pidm
          AND    sc_crn = c_crn
          AND    c_budget_code LIKE 'B%'
        )
        AS HC_TOTAL,
        2 as order_id
 FROM   student_courses_current
 ----------------------------------------------------------------------------------------

 UNION

 ----------------------------------------------------------------------------------------
 -- REPORT 2B | TABLE 3 -----------------------------------------------------------------
 ----------------------------------------------------------------------------------------
 
 SELECT DISTINCT
        (
          SELECT ( -- Budget-Related FTE - Resident - Male - Undergraduate Level
                    SELECT round(sum(sc_att_cr)/150 + sum(nvl(sc_contact_hrs,0))/450,2)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    s_gender = 'M' 
                    AND    c_level != 'G'
                    AND    s_regent_res IN ('A','M','R')
                    AND    c_budget_code LIKE 'B%'
                )+(
                    -- Budget-Related FTE - Resident - Male - Graduate Level
                    SELECT nvl(round(sum(sc_att_cr)/100 + sum(nvl(sc_contact_hrs,0))/450,2),0)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    s_gender = 'M' 
                    AND    c_level  = 'G'
                    AND    s_regent_res IN ('A','M','R')
                    AND    c_budget_code LIKE 'B%'
                  ) AS FTE_RESID_MALE
          FROM    DUAL
        )
        AS FTE_RESID_MALE,
        (
          SELECT ( -- Budget-Related FTE - Resident - Female - Undergraduate Level
                    SELECT round(sum(sc_att_cr)/150 + sum(nvl(sc_contact_hrs,0))/450,2)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    s_gender = 'F' 
                    AND    c_level != 'G'
                    AND    s_regent_res IN ('A','M','R')
                    AND    c_budget_code LIKE 'B%'
                )+(
                    -- Budget-Related FTE - Resident - Female - Graduate Level
                    SELECT nvl(round(sum(sc_att_cr)/100 + sum(nvl(sc_contact_hrs,0))/450,2),0)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    s_gender = 'F' 
                    AND    c_level  = 'G'
                    AND    s_regent_res IN ('A','M','R')
                    AND    c_budget_code LIKE 'B%'
                  ) AS FTE_RESID_FEMALE
          FROM    DUAL
        )
        AS FTE_RESID_FEMALE,
        (
          SELECT ( -- Budget-Related FTE - Resident - Undergraduate Level
                    SELECT round(sum(sc_att_cr)/150 + sum(nvl(sc_contact_hrs,0))/450,2)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    c_level != 'G'
                    AND    s_regent_res IN ('A','M','R')
                    AND    c_budget_code LIKE 'B%'
                )+(
                    -- Budget-Related FTE - Resident Graduate Level
                    SELECT nvl(round(sum(sc_att_cr)/100 + sum(nvl(sc_contact_hrs,0))/450,2),0)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    c_level  = 'G'
                    AND    s_regent_res IN ('A','M','R')
                    AND    c_budget_code LIKE 'B%'
                  ) AS FTE_RESID_TOTAL
          FROM    DUAL
        )
        AS FTE_RESID_TOTAL,
        (
          SELECT ( -- Budget-Related FTE - Non-Resident - Male - Undergraduate Level
                    SELECT round(sum(sc_att_cr)/150 + sum(nvl(sc_contact_hrs,0))/450,2)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    s_gender = 'M' 
                    AND    c_level != 'G'
                    AND    s_regent_res IN ('N', 'G')
                    AND    c_budget_code LIKE 'B%'
                )+(
                    -- Budget-Related FTE - Non-Resident - Male - Graduate Level
                    SELECT nvl(round(sum(sc_att_cr)/100 + sum(nvl(sc_contact_hrs,0))/450,2),0)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    s_gender = 'M' 
                    AND    c_level  = 'G'
                    AND    s_regent_res IN ('N', 'G')
                    AND    c_budget_code LIKE 'B%'
                  ) AS FTE_NORES_MALE
          FROM    DUAL
        )
        AS FTE_NORES_MALE,
        (
          SELECT ( -- Budget-Related FTE - Non-Resident - Female - Undergraduate Level
                    SELECT round(sum(sc_att_cr)/150 + sum(nvl(sc_contact_hrs,0))/450,2)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    s_gender = 'F' 
                    AND    c_level != 'G'
                    AND    s_regent_res IN ('N', 'G')
                    AND    c_budget_code LIKE 'B%'
                )+(
                    -- Budget-Related FTE - Non-Resident - Female - Graduate Level
                    SELECT nvl(round(sum(sc_att_cr)/100 + sum(nvl(sc_contact_hrs,0))/450,2),0)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    s_gender = 'F' 
                    AND    c_level  = 'G'
                    AND    s_regent_res IN ('N', 'G')
                    AND    c_budget_code LIKE 'B%'
                  ) AS FTE_NORES_FEMALE
          FROM    DUAL
        )
        AS FTE_NORES_FEMALE,
        (
          SELECT ( -- Budget-Related FTE - Non-Resident - Undergraduate Level
                    SELECT round(sum(sc_att_cr)/150 + sum(nvl(sc_contact_hrs,0))/450,2)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    c_level != 'G'
                    AND    s_regent_res IN ('N', 'G')
                    AND    c_budget_code LIKE 'B%'
                )+(
                    -- Budget-Related FTE - Non-Resident Graduate Level
                    SELECT nvl(round(sum(sc_att_cr)/100 + sum(nvl(sc_contact_hrs,0))/450,2),0)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    c_level  = 'G'
                    AND    s_regent_res IN ('N', 'G')
                    AND    c_budget_code LIKE 'B%'
                  ) AS FTE_NORES_TOTAL
          FROM    DUAL
        )
        AS FTE_NORES_TOTAL,
        (
          SELECT ( -- Budget-Related FTE - Overall - Undergraduate Level
                    SELECT round(sum(sc_att_cr)/150 + sum(nvl(sc_contact_hrs,0))/450,2)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    c_level != 'G'
                    AND    c_budget_code LIKE 'B%'
                )+(
                    -- Budget-Related FTE - Overall Graduate Level
                    SELECT nvl(round(sum(sc_att_cr)/100 + sum(nvl(sc_contact_hrs,0))/450,2),0)
                    FROM   student_courses_current sc, students_current s, courses_current c
                    WHERE  sc_pidm  = s_pidm
                    AND    sc_crn   = c_crn
                    AND    c_level  = 'G'
                    AND    c_budget_code LIKE 'B%'
                  ) AS FTE_TOTAL
          FROM    DUAL
        )
        AS FTE_TOTAL,
        3 as order_id
 FROM   student_courses_current
 
 ORDER BY order_id;
 ----------------------------------------------------------------------------------------
  
-- end of file 