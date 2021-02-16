

/* --- RUN IN PROD ----------------------------------------------------------------------------------------------------- */
    DROP TABLE students_202123;
    DROP TABLE course_202123;
    DROP TABLE student_course_202123;
    
    CREATE TABLE students_202123      AS SELECT * FROM students_20192e;
    CREATE TABLE course_202123         AS SELECT * FROM course_20192e;
    CREATE TABLE student_course_202123 AS SELECT * FROM student_course_20192e;
    ALTER TABLE course_202123 MODIFY (S11_WKLD_XLIST_GRP varchar2(15 char));

    TRUNCATE TABLE students_202123;
    TRUNCATE TABLE course_202123;
    TRUNCATE TABLE student_course_202123;

    /* --- RUN IN IR1 or IR2 ------------------------------------------------------------------------------------------------------ */

    INSERT INTO students_202123@proddb.dixie.edu
    SELECT s_pidm AS pidm,
           s_banner_id,
           s_banner_term AS TERM,
           s_inst,
           s_year,
           s_term,
           s_extract,
           CASE WHEN s_id_flag = 'I' THEN s_banner_id ELSE s_id END AS s_id,
           s_id_flag,
           s_prev_id,
           s_last_name AS s_last,
           s_first_name AS s_first,
           s_middle_name AS s_middle,
           s_suffix,
           s_prev_last,
           s_prev_first,
           s_prev_middle,
           s_prev_suffix,
           s_cur_zip_code AS s_curr_zip,
           s_county_origin,
           s_state_origin,
           s_country_origin,
           s_birth_dt,
           s_age,
           s_gender,
           s_citz_code,
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
           s_religion AS religion,
           s_marital_status AS marital_status,
           s_entry_action,
           s_styp AS styp,
           s_level,
           s_deg_intent,
           s_cur_cip1 AS s_curr_cip,
           s_cur_cip_ushe AS s_curr_cip_ushe,
           s_cur_cip2 AS s_curr_cip2,
           s_cur_prgm1 AS cur_prgm1,
           s_cur_prgm2 AS cur_prgm2,
           s_cur_degc1 AS cur_degc1,
           s_cur_degc1 AS degree1,
           s_cur_majr1 AS cur_majr1,
           s_cur_majr2 AS cur_majr2,
           s_cur_majr1 AS major1,
           s_cur_majr2 AS major2,
           s_major_desc1 AS major_desc1,
           s_major_desc2 AS major_desc2,
           s_cur_minor1 AS cur_minor1,
           s_cur_minor2 AS cur_minor2,
           s_cur_conc1 AS conc1,
           s_cur_conc2 AS conc2,
           s_cur_coll_code1 AS cur_coll_code1,
           s_cur_coll_code2 AS cur_coll_code2,
           s_cum_hrs_ugrad,
           s_cum_gpa_ugrad,
           s_term_gpa,
           s_cum_hrs_grad,
           s_cum_gpa_grad,
           s_trans_total,
           s_pt_ft,
           s_high_school,
           s_hsgrad_dt AS hsgrad_dt,
           s_hsgpa AS hsgpa,
           s_ssid,
           s_hb75_waiver,
           s_cum_mem_hrs,
           s_tot_clep,
           s_total_ap,
           s_act_comp,
           s_act_math,
           s_act_engl,
           s_act_read,
           s_act_sci,
           s_pell,
           s_bia,
           s_rate AS rate,
           s_cohort_block AS cohort_block,
           s_term_att_cr AS atmp_hrs,
           s_term_earned_cr AS earned_hrs,
           s_term_att_cr,
           s_term_earned_cr,
           s_confid_ind AS confid_ind,
           s_visatype AS visatype,
           s_sport AS sport,
           s_ada AS ada
    FROM   students_current;
    COMMIT;

    INSERT INTO course_202123@proddb.dixie.edu
    SELECT c_crn AS crn,
           c_banner_term AS TERM,
           c_inst,
           c_year,
           c_term,
           c_extract,
           c_crs_subject,
           c_crs_number,
           c_crs_section,
           c_ptrm_code AS ptrm_code,
           c_min_credit,
           c_max_credit,
           c_contact_hrs,
           c_line_item,
           c_site_type,
           c_budget_code,
           c_delivery_method,
           c_program_type,
           c_credit_ind,
           c_start_time1 AS c_start_time,
           c_stop_time1 AS c_stop_time,
           c_days1 AS c_days,
           c_bldg1 AS c_bldg,
           c_room1 AS c_room,
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
           c_instr_pidm AS instr_pidm,
           c_instr_id,
           c_instr_name,
           c_instruct_type,
           c_schd_code AS dsc_schd_code,
           c_division AS division,
           c_college,
           c_dept,
           c_enrl AS enrl,
           c_crs_level AS crs_level,
           c_gen_ed,
           c_xlist_ind AS xlist_ind,
           c_dest_site,
           c_del_model,
           c_dsc_fye AS dsc_fye,
           c_level,
           (
             SELECT DISTINCT sirasgn_workload_adjust 
             FROM   sirasgn
             WHERE  sirasgn_term_code = c_banner_term
             AND    sirasgn_crn = c_crn
             AND    sirasgn_primary_ind = 'Y'
           ) AS s11_wkld,
           (
             SELECT DISTINCT ssrxlst_xlst_group
             FROM   ssrxlst
             WHERE  ssrxlst_crn = c_crn
             AND    ssrxlst_term_code = c_banner_term
           ) AS s11_wkld_xlist_grp,
           c_bldg_num1,
           c_room_max1,
           c_room_type1,
           c_bldg_num2,
           c_room_max2,
           c_room_type2,
           c_bldg_num3,
           c_room_max3,
           c_room_type3
    FROM   courses_current;
    COMMIT;
    
    INSERT INTO student_course_202123@proddb.dixie.edu
    SELECT sc_pidm AS pidm,
           sc_id AS ID,
           sc_banner_term AS TERM,
           sc_crn AS crn,
           sc_inst,
           sc_year,
           sc_term,
           sc_extract,
           sc_id,
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
           gmod
    FROM   student_courses_current;
    COMMIT;
    
    /*
    SELECT s_gender,                   COUNT(*) AS students FROM students_current                      GROUP BY s_gender       ORDER BY s_gender;
    SELECT s_ethnic,                   COUNT(*) AS students FROM students_current                      GROUP BY s_ethnic       ORDER BY s_ethnic;
    SELECT s_regent_res,               COUNT(*) AS students FROM students_current                      GROUP BY s_regent_res   ORDER BY s_regent_res;
    SELECT s_entry_action,             COUNT(*) AS students FROM students_current                      GROUP BY s_entry_action ORDER BY s_entry_action;
    SELECT s_pt_ft,                    COUNT(*) AS students FROM students_current                      GROUP BY s_pt_ft        ORDER BY s_pt_ft;
    SELECT s_cur_prgm1, s_major_desc1, COUNT(*) AS students FROM students_current WHERE s_level = 'GG' GROUP BY s_cur_prgm1, s_major_desc1 ORDER BY s_cur_prgm1;
    */
    
--    select * from students_202123@proddb
--    select * from course_202123@proddb
--    select * from student_course_202123@proddb
    