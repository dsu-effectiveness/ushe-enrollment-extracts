 ------------------------------------------------------------------------------------------------------------
 /*
    This script will move the extract tables from current tables into the DSCIR archive. You should be 
    logged into DSCIR to perform these steps and update the source database (e.g. @tst3db) before you
    start running it. Naturally, backing up the larger tables will take several minutes each. 
 */
 ------------------------------------------------------------------------------------------------------------
 /** /
  DECLARE

  -- Parameters: --------------- --
     v_dsu_extract  VARCHAR2(6);   
     v_database     VARCHAR2(6);
  -- --------------------------- --

  BEGIN
  
  -- Manual Parameter: --------- --
     v_dsu_extract := '20204E';
     v_database    := 'proddb';
  -- --------------------------- --

 ------------------------------------------------------------------------------------------------------------

 -- !!! CAUTION: This can take 7-10 minutes to run !!! --
 -- Back up existing Extract Tables

    --EXECUTE IMMEDIATE ('DROP TABLE stu_bk'   ||to_char(SYSDATE,'MMDDYYYY'));         
    --EXECUTE IMMEDIATE ('DROP TABLE crs_bk'   ||to_char(SYSDATE,'MMDDYYYY'));
    --EXECUTE IMMEDIATE ('DROP TABLE stucrs_bk'||to_char(SYSDATE,'MMDDYYYY'));
    
    EXECUTE IMMEDIATE 
            ('CREATE TABLE stu_bk'||to_char(SYSDATE,'MMDDYYYY')||' AS (SELECT * FROM students03)');
            COMMIT;
    EXECUTE IMMEDIATE 
            ('CREATE TABLE crs_bk'||to_char(SYSDATE,'MMDDYYYY')||' AS (SELECT * FROM courses)');
            COMMIT;
    EXECUTE IMMEDIATE 
            ('CREATE TABLE stucrs_bk'||to_char(SYSDATE,'MMDDYYYY')||' AS (SELECT * FROM student_courses)');
            COMMIT;
 ------------------------------------------------------------------------------------------------------------
END;
/**/
 -- Create Temp Table for Students Data 
   -- CREATE TABLE ts20204E AS
                 SELECT s_inst,
                        s_year, 
                        s_term, 
                        s_extract,
                        lpad(nvl(s_id,0),9,0) AS s_id, 
                        s_id_flag,
                        lpad(s_prev_id,9,0) AS s_prev_id, 
                        s_last,
                        s_first,
                        s_middle, 
                        s_suffix,
                        s_prev_last, 
                        s_prev_first,
                        s_prev_middle, 
                        s_prev_suffix,
                        s_curr_zip, 
                        s_citz_code, 
                        s_county_origin,
                        s_state_origin, 
                        s_birth_dt,
                        s_gender, 
                        s_ethnic,
                        s_regent_res, 
                        s_curr_cip,
                        s_entry_action,
                        s_level, 
                        s_deg_intent,
                        s_cum_hrs_ugrad, 
                        s_cum_gpa_ugrad, 
                        s_cum_hrs_grad, 
                        s_cum_gpa_grad,
                        s_trans_total,
                        s_pt_ft, 
                        s_age, 
                        s_country_origin, 
                        s_high_school,
                        s_hb75_waiver,
                        s_curr_cip2, 
                        s_cum_mem_hrs AS s_cum_membership,
                        s_tot_clep AS s_total_clep,
                        s_total_ap,
                        nvl(0,0) AS s_census_date, 
                        s_regent_res as s_rpt_res, 
                        s_ssid, 
                        SUBSTR(s_banner_id,2,8) AS s_banner_id,
                        hsgrad_dt AS dsc_hsgrad_dt, 
                        pidm AS dsc_pidm,
                        s_act_comp,
                        s_curr_cip_ushe,
                        decode(s_ethnic_h, NULL, ' ', s_ethnic_h)|| 
                        decode(s_ethnic_a, NULL, ' ', s_ethnic_a)|| 
                        decode(s_ethnic_b, NULL, ' ', s_ethnic_b)|| 
                        decode(s_ethnic_i, NULL, ' ', s_ethnic_i)|| 
                        decode(s_ethnic_p, NULL, ' ', s_ethnic_p)|| 
                        decode(s_ethnic_w, NULL, ' ', s_ethnic_w)|| 
                        decode(s_ethnic_n, NULL, ' ', s_ethnic_n)|| 
                        decode(s_ethnic_u, NULL, ' ', s_ethnic_u) AS s_ushe_race_eth,
                        cur_prgm1,
                        cur_degc1,
                        cur_majr1,
                        cur_coll_code1,
                        conc1, 
                        conc2, 
                        s_term_gpa,
                        s_act_math,
                        s_act_engl,
                        s_act_read,
                        s_act_sci,
                        s_pell,
                        s_bia, 
                        cohort_block,
                        s_term_att_cr, 
                        s_term_earned_cr,
                        '20204E' AS dsc_term_code,
                        cur_minor1, 
                        cur_minor2,
                        religion, 
                        marital_status, 
                        cur_majr2, 
                        major2, 
                        major_desc1, 
                        major_desc2, 
                        cur_coll_code2,
                        cur_prgm2,
                        term,
                        dsc.f_is_1st_gen@proddb(pidm) AS FIRST_GEN_IND,
                        hsgpa,
                        (SELECT gorvisa_vtyp_code FROM gorvisa@proddb     WHERE gorvisa_pidm = pidm) AS vtyp_code,
                        (SELECT hsgpact_hsgpact   from dsc.hsgpact@proddb where hsgpact_pidm = pidm) AS index_score
                 FROM   students_20204E@proddb;

                           
 -- Create Temp Table for Courses Data 
    CREATE TABLE tc20204E AS
                 SELECT c_inst, 
                        c_year, 
                        c_term, 
                        c_extract, 
                        c_crs_subject, 
                        c_crs_number,
                        c_crs_section, 
                        c_min_credit, 
                        c_max_credit, 
                        c_contact_hrs,
                        c_line_item, 
                        c_site_type, 
                        c_budget_code, 
                        c_delivery_method,
                        c_program_type, 
                        c_credit_ind, 
                        c_start_time, 
                        c_stop_time,
                        c_days, 
                        c_bldg,
                        c_room, 
                        c_start_time2, 
                        c_stop_time2, 
                        c_days2,
                        c_bldg2,
                        c_room2,
                        c_start_time3, 
                        c_stop_time3,
                        c_days3, 
                        c_bldg3,
                        c_room3,
                        c_start_date,
                        c_end_date, 
                        c_title, 
                        c_instr_id,
                        c_instr_name,
                        c_instruct_type,
                        c_college,
                        c_dept,
                        crn AS dc_crn,
                        c_gen_ed, 
                        c_dest_site,
                        dsc_fye, 
                        enrl AS c_class_size,
                        '20204e' AS c_banner_extract,
                        c_level,
                        s11_wkld,
                        '   ' AS s11_wkld_cat,
                        s11_wkld_xlist_grp, 
                        term,
                        c_bldg_num1,
                        c_room_max1,
                        c_room_type1,
                        c_bldg_num2,
                        c_room_max2,
                        c_room_type2,
                        c_bldg_num3,
                        c_room_max3,
                        c_room_type3
                 FROM   course_20204E@proddb;

 -- Create Temp Table for Student Courses Data 
    CREATE TABLE tsc20204E AS
                 SELECT sc_inst, 
                        sc_year, 
                        sc_term,
                        sc_extract,
                        lpad(sc_id, 9, 0) AS sc_id,
                        sc_crs_sbj,
                        sc_crs_num,
                        sc_crs_sec, 
                        sc_att_cr, 
                        sc_earned_cr,
                        sc_contact_hrs,
                        sc_grade,
                        sc_mem_hrs AS sc_membership_hrs, 
                        sc_stud_type AS sc_student_type,
                        ID AS dsc_id,
                        sc.crn AS dsc_crn, 
                        sc.pidm AS dsc_pidm,
                        gmod, 
                        dsc_loc_recvd, 
                        '20204E' AS dsc_term_code,
                        sc.term,
                        SUBSTR(s_banner_id,2,8) AS sc_banner_id,
                        c.c_level AS sc_level,
                        c.c_delivery_method AS sc_del_method
                 FROM   student_course_20204E@proddb sc,
                        students_20204E@proddb s,
                        course_20204E@proddb c
                 WHERE  s.pidm = sc.pidm
                    AND  sc.crn = c.crn;
                    
 ------------------------------------------------------------------------------------------------------------
    
    -- Purge any previously imported records, if they exists, to prevent duplicates.                 
    DELETE FROM students03      WHERE dsc_term_code = '20204E';
    DELETE FROM courses         WHERE dsc_term_code = '20204E';
    DELETE FROM student_courses WHERE dsc_term_code = '20204E';
    
    -- Insert records from temp tables into the extract tables.
    INSERT INTO students03      SELECT * FROM  ts20204E;
    INSERT INTO courses         SELECT * FROM  tc20204E;
    INSERT INTO student_courses SELECT * FROM tsc20204E;


    
    -- Verify Imported Data.
    SELECT * FROM students03      WHERE dsc_term_code = '202043';
    SELECT * FROM courses         WHERE dsc_term_code = '202043';
    SELECT * FROM student_courses WHERE dsc_term_code = '202043';

    -- Delete temp tables.
    DROP TABLE  ts20204E;
    DROP TABLE  tc20204E;
    DROP TABLE tsc20204E;
    
     COMMIT;
    
 ------------------------------------------------------------------------------------------------------------
 /*
 -- This will supress the errors indicating that tables already exist.
    EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;

  END;

 ------------------------------------------------------------------------------------------------------------       
 /* -- Use these to check and make sure the records imported properly

    -- Students
       SELECT count(*), s_year, s_term, s_extract 
       FROM   students03
       GROUP  BY s_year, s_term, s_extract
       ORDER  BY s_year DESC, s_term DESC, s_extract DESC;

    -- Courses
       SELECT count(*), c_year, c_term, c_extract 
       FROM   courses
       GROUP  BY c_year, c_term, c_extract
       ORDER  BY c_year DESC, c_term DESC, c_extract DESC;
 
    -- Student Courses
       SELECT count(*), sc_year, sc_term, sc_extract 
       FROM   student_courses
       GROUP  BY sc_year, sc_term, sc_extract
       ORDER  BY sc_year DESC, sc_term DESC, sc_extract DESC;

 */ 
 ------------------------------------------------------------------------------------------------------------
 
-- end of file
