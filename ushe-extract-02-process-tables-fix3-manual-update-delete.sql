-- S171

-- This student did non-credit courses in 201940.  Updating s_entry_action from CS to TU
update students_current
set s_entry_action = 'TU'
where s_banner_id = '00420468';

-- Confirmed that this student is a graduate student.  Updating s_entry_action from CS to NG.
update students_current
set s_entry_action = 'NG'
where s_banner_id = '00205890';

-- This student was an FF at TW (change made after USHE submission).  Updating s_entry_action from FH to FF.
update students_current
set s_entry_action = 'FF'
where s_banner_id = '00234325';

-- S42 Fixing missing s_HS_GRAD_DATE for 2 International Students
update students_current
set s_hsgrad_dt = 20120102, s_high_school = '459999'
where s_banner_id = '00414664';

update students_current
set s_hsgrad_dt = 20150605, s_high_school = '459999'
where s_banner_id = '00415638';

-- S43B Updating Term GPA to 4000.  This is what is reflected in Banner (shrtgpa).  Updating s_term_gpa from 3944 to 4000.
update students_current
set s_term_gpa = 4000
where s_banner_id = '00399465';


-- C13B Verified that these courses are on the Perkins Master list.  Changing c_program_type from A to V.
update courses_current
set c_program_type = 'V'
where c_crs_subject = 'EMS'
  and c_crs_number in ('1110', '1120');

commit;