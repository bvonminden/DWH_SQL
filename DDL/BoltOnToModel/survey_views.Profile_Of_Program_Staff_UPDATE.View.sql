DROP VIEW [survey_views].[Profile_Of_Program_Staff_UPDATE]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[Profile_Of_Program_Staff_UPDATE] as
select 
  
    fr.survey_response_id     as SurveyResponseID,
    1                         as ElementsProcessed,
    sq.master_survey_id       as SurveyID,
    dk.date_actual            as SurveyDate,
    xp.source_auditdate       as AuditDate,
    dc.client_key             as CL_EN_GEN_ID,
    xp.site_id                as SiteID,
    xp.programid              as ProgramID, 
    dn.nurse_id               as IA_StaffID,
    dc.client_id              as ClientID,
    null                      as RespondentID,
	max(case sq.pseudonym when 'NURSE_EDUCATION_0_NURSING_DEGREES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_EDUCATION_0_NURSING_DEGREES,
max(case sq.pseudonym when 'NURSE_EDUCATION_1_OTHER_DEGREES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_EDUCATION_1_OTHER_DEGREES,
max(case sq.pseudonym when 'NURSE_PRIMARY_ROLE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PRIMARY_ROLE,
max(case sq.pseudonym when 'NURSE_PRIMARY_ROLE_FTE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PRIMARY_ROLE_FTE,
max(case sq.pseudonym when 'NURSE_PROFESSIONAL_1_ADMIN_ASST_FTE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PROFESSIONAL_1_ADMIN_ASST_FTE,
max(case sq.pseudonym when 'NURSE_PROFESSIONAL_1_HOME_VISITOR_FTE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PROFESSIONAL_1_HOME_VISITOR_FTE,
max(case sq.pseudonym when 'NURSE_PROFESSIONAL_1_NEW_ROLE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PROFESSIONAL_1_NEW_ROLE,
max(case sq.pseudonym when 'NURSE_PROFESSIONAL_1_OTHER_FTE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PROFESSIONAL_1_OTHER_FTE,
max(case sq.pseudonym when 'NURSE_PROFESSIONAL_1_SUPERVISOR_FTE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PROFESSIONAL_1_SUPERVISOR_FTE,
max(case sq.pseudonym when 'NURSE_PROFESSIONAL_1_TOTAL_FTE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PROFESSIONAL_1_TOTAL_FTE,
max(case sq.pseudonym when 'NURSE_SECONDARY_ROLE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_SECONDARY_ROLE,
max(case sq.pseudonym when 'NURSE_SECONDARY_ROLE_FTE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_SECONDARY_ROLE_FTE,
max(case sq.pseudonym when 'NURSE_STATUS_0_CHANGE_LEAVE_END ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_STATUS_0_CHANGE_LEAVE_END,
max(case sq.pseudonym when 'NURSE_STATUS_0_CHANGE_LEAVE_START ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_STATUS_0_CHANGE_LEAVE_START,
max(case sq.pseudonym when 'NURSE_STATUS_0_CHANGE_SPECIFIC ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_STATUS_0_CHANGE_SPECIFIC,
max(case sq.pseudonym when 'NURSE_STATUS_0_CHANGE_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_STATUS_0_CHANGE_START_DATE,
max(case sq.pseudonym when 'NURSE_STATUS_0_CHANGE_TERMINATE_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_STATUS_0_CHANGE_TERMINATE_DATE,
max(case sq.pseudonym when 'NURSE_STATUS_0_CHANGE_TRANSFER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_STATUS_0_CHANGE_TRANSFER,
max(case sq.pseudonym when 'NURSE_STATUS_TERM_REASON ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_STATUS_TERM_REASON,
max(case sq.pseudonym when 'NURSE_STATUS_TERM_REASON_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_STATUS_TERM_REASON_OTHER,
max(case sq.pseudonym when 'NURSE_TEAM_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_TEAM_NAME,
max(case sq.pseudonym when 'NURSE_TEAM_START_DATE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_TEAM_START_DATE

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Profile Of Program Staff-UPDATE'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
