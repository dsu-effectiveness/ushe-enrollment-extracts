 ------------------------------------------------------------------------------------------------------------
 /*
    This page will pull the data in the format needed for submitting the extract files to USHE for review. 
    Files should be | (pipe) delimited and should have headers. They should be saved as a text file with 
    the following naming convention: 
    
      * DSU-s-YYTE for the Students table.         For example, 2017 Spring EOT would be DSU-s-173E
      * DSU-c-YYTE for the Courses table.          For example, 2017 Spring EOT would be DSU-c-173E
      * DSU-sc-YYTE for the Student Courses table. For example, 2017 Spring EOT would be DSU-sc-173E
      
    One you have all 3 files, you will want to upload them via FTP to the state for review and cleaning. 
 */
 -- Students Table ------------------------------------------------------------------------------------------

     SELECT s_inst,
            s_year,
            s_term,
            s_extract,
            s_id,
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
            CASE WHEN REGEXP_LIKE(s_cur_zip_code, '^[[:digit:]]+$') 
                 THEN rpad(replace(s_cur_zip_code,'-',''),5,'0')
                 ELSE '000000000' END AS s_cur_zip,
            s_citz_code,
            s_county_origin,
            s_state_origin,
            s_birth_dt,
            s_gender,
            s_ethnic_h,
            s_ethnic_a,
            s_ethnic_b,
            s_ethnic_i,
            s_ethnic_p,
            s_ethnic_w,
            s_ethnic_n,
            s_ethnic_u,
            s_regent_res,
            CASE WHEN s_cur_cip1 = '999999' 
                 THEN '240102'
                 ELSE lpad(s_cur_cip1,6,'0') 
                 END  AS s_curr_cip,
            s_entry_action AS s_reg_status,
            s_level,
            s_deg_intent,
            lpad(s_cum_hrs_ugrad,5,'0') AS s_cum_hrs_ugrad,
            lpad(s_cum_gpa_ugrad,4,'0') AS s_cum_gpa_ugrad,
            lpad(s_cum_hrs_grad,5,'0')  AS s_cum_hrs_grad,
            lpad(s_cum_gpa_grad,4,'0')  AS s_cum_gpa_grad,
            s_trans_total,
            s_pt_ft,
            s_age,
            s_country_origin,
            s_high_school,
            CASE WHEN to_number(s_hb75_waiver) > '100' 
                 THEN to_char('100') 
                 ELSE to_char(s_hb75_waiver) 
                 END  AS s_hb75_waiver, 
            s_cur_cip2,
            s_cum_mem_hrs,
            s_tot_clep,
            s_total_ap,
            s_ssid,
            s_banner_id AS s_banner_id,
            s_act_comp AS s_act,
            CASE WHEN s_cur_cip1 = '999999' 
                 THEN '240102'
                 ELSE lpad(s_cur_cip1,6,'0') 
                 END  AS s_intent_cip,
            s_act_engl AS s_act_eng,
            s_act_math,
            s_act_read,
            s_act_sci,
            s_hsgrad_dt  AS s_hs_grad_date, 
            lpad(s_term_gpa,4,'0') AS s_term_gpa, 
            s_pell, 
            s_bia,
            s_cur_coll_code1 AS s_college,
            s_major_desc1    AS s_major,
            s_cur_coll_code2 AS s_college2,
            s_major_desc2    AS s_major2
     FROM   students_current;
    
 -- Courses Table -------------------------------------------------------------------------------------------
 
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
           c_instr_id, 
           c_instr_name,
           c_instruct_type, 
           c_college,
           c_dept, 
           c_gen_ed,
           c_dest_site,
           c_enrl AS c_class_size,
           c_del_model,
           c_level,
           c_crn
    FROM   courses_current;

 -- Student Courses Table -----------------------------------------------------------------------------------
 
    SELECT sc_inst,
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
           sc_stud_type AS sc_student_type,
           sc_banner_id,
           sc_crn
    FROM   student_courses_current;

 ------------------------------------------------------------------------------------------------------------
    
-- end of file    