select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
	--ss.source_system_name	  
	null as DataSource,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then secured_value else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_ALT_0_COMMENTS_ALT ' then survey_views.f_replace_chars(secured_value) else null end) as CLIENT_ALT_0_COMMENTS_ALT,
	max(case sq.pseudonym when 'CLIENT_ALTERNATIVE_ENCOUNTER_0_TYPE_ALT ' then secured_value else null end) as CLIENT_ALTERNATIVE_ENCOUNTER_0_TYPE_ALT,
	max(case sq.pseudonym when 'CLIENT_ALTERNATIVE_ENCOUNTER_1_TYPE_OTHER_ALT ' then secured_value else null end) as CLIENT_ALTERNATIVE_ENCOUNTER_1_TYPE_OTHER_ALT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_ENVIRONHLTH_ALT ' then secured_value else null end) as CLIENT_DOMAIN_0_ENVIRONHLTH_ALT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_FRNDFAM_ALT ' then secured_value else null end) as CLIENT_DOMAIN_0_FRNDFAM_ALT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_LIFECOURSE_ALT ' then secured_value else null end) as CLIENT_DOMAIN_0_LIFECOURSE_ALT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_MATERNAL_ALT ' then secured_value else null end) as CLIENT_DOMAIN_0_MATERNAL_ALT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_PERSONAL_HLTH_ALT ' then secured_value else null end) as CLIENT_DOMAIN_0_PERSONAL_HLTH_ALT,
	max(case sq.pseudonym when 'CLIENT_DOMAIN_0_TOTAL_ALT ' then secured_value else null end) as CLIENT_DOMAIN_0_TOTAL_ALT,
	max(case sq.pseudonym when 'CLIENT_NO_REFERRAL ' then secured_value else null end) as CLIENT_NO_REFERRAL,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'CLIENT_SCREENED_SRVCS ' then secured_value else null end) as CLIENT_SCREENED_SRVCS,
	max(case sq.pseudonym when 'CLIENT_TALKED_0_WITH_ALT ' then secured_value else null end) as CLIENT_TALKED_0_WITH_ALT,
	max(case sq.pseudonym when 'CLIENT_TALKED_1_WITH_OTHER_ALT ' then secured_value else null end) as CLIENT_TALKED_1_WITH_OTHER_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_0_START_ALT ' then secured_value else null end) as CLIENT_TIME_0_START_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_1_DURATION_ALT ' then secured_value else null end) as CLIENT_TIME_1_DURATION_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_1_END_ALT ' then secured_value else null end) as CLIENT_TIME_1_END_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_FROM_AMPM_ALT ' then secured_value else null end) as CLIENT_TIME_FROM_AMPM_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_FROM_HR_ALT ' then secured_value else null end) as CLIENT_TIME_FROM_HR_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_FROM_MIN_ALT ' then secured_value else null end) as CLIENT_TIME_FROM_MIN_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_TO_AMPM_ALT ' then secured_value else null end) as CLIENT_TIME_TO_AMPM_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_TO_HR_ALT ' then secured_value else null end) as CLIENT_TIME_TO_HR_ALT,
	max(case sq.pseudonym when 'CLIENT_TIME_TO_MIN_ALT ' then secured_value else null end) as CLIENT_TIME_TO_MIN_ALT,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then secured_value else null end) as NURSE_PERSONAL_0_NAME


   from survey_views.udf_secure_fact_survey_response('Alternative Encounter','DUA') fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    inner  join  dim_nurse              dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
	--inner join dim_source_system		ss on fr.source_system_key			  = ss.source_system_key
  

  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id,
	--ss.source_system_name,
	xp.source_auditdate



