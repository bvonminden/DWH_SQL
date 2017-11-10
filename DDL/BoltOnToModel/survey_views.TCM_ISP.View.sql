DROP VIEW [survey_views].[TCM_ISP]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[TCM_ISP] as
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
max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'LA_CTY_AGENCY_ADDRESS_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_AGENCY_ADDRESS_ISP,
max(case sq.pseudonym when 'LA_CTY_AGENCY_NAME_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_AGENCY_NAME_ISP,
max(case sq.pseudonym when 'LA_CTY_AGENCY_PH_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_AGENCY_PH_ISP,
max(case sq.pseudonym when 'LA_CTY_AREAS_ASSESD_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_AREAS_ASSESD_ISP,
max(case sq.pseudonym when 'LA_CTY_CASE_MGR_ID ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_CASE_MGR_ID,
max(case sq.pseudonym when 'LA_CTY_CLI_AGREE_DATE_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_CLI_AGREE_DATE_ISP,
max(case sq.pseudonym when 'LA_CTY_CLI_AGREE_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_CLI_AGREE_ISP,
max(case sq.pseudonym when 'LA_CTY_COMM_LIV_NEEDS_IDENTIFIED_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_COMM_LIV_NEEDS_IDENTIFIED_ISP,
max(case sq.pseudonym when 'LA_CTY_COMM_LIV_NEEDS_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_COMM_LIV_NEEDS_ISP,
max(case sq.pseudonym when 'LA_CTY_ENVIRON_NEEDS_IDENTIFIED_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_ENVIRON_NEEDS_IDENTIFIED_ISP,
max(case sq.pseudonym when 'LA_CTY_ENVIRON_NEEDS_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_ENVIRON_NEEDS_ISP,
max(case sq.pseudonym when 'LA_CTY_FREQ_DUR_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_FREQ_DUR_ISP,
max(case sq.pseudonym when 'LA_CTY_FU_PREV_REF_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_FU_PREV_REF_ISP,
max(case sq.pseudonym when 'LA_CTY_GOAL_NOT_MET_REASON_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_GOAL_NOT_MET_REASON_ISP,
max(case sq.pseudonym when 'LA_CTY_LOC_SEC_DOC_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_LOC_SEC_DOC_ISP,
max(case sq.pseudonym when 'LA_CTY_MED_NEEDS_IDENTIFIED_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_MED_NEEDS_IDENTIFIED_ISP,
max(case sq.pseudonym when 'LA_CTY_MED_NEEDS_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_MED_NEEDS_ISP,
max(case sq.pseudonym when 'LA_CTY_MEDI_CAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_MEDI_CAL,
max(case sq.pseudonym when 'LA_CTY_MENTAL_NEEDS_IDENTIFIED_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_MENTAL_NEEDS_IDENTIFIED_ISP,
max(case sq.pseudonym when 'LA_CTY_MENTAL_NEEDS_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_MENTAL_NEEDS_ISP,
max(case sq.pseudonym when 'LA_CTY_NPI ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_NPI,
max(case sq.pseudonym when 'LA_CTY_PHN_SIG_DATE_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_PHN_SIG_DATE_ISP,
max(case sq.pseudonym when 'LA_CTY_PHN_SIG_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_PHN_SIG_ISP,
max(case sq.pseudonym when 'LA_CTY_PHYSICAL_NEEDS_IDENTIFIED_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_PHYSICAL_NEEDS_IDENTIFIED_ISP,
max(case sq.pseudonym when 'LA_CTY_PHYSICAL_NEEDS_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_PHYSICAL_NEEDS_ISP,
max(case sq.pseudonym when 'LA_CTY_PREV_REF_DATE_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_PREV_REF_DATE_ISP,
max(case sq.pseudonym when 'LA_CTY_PROG_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_PROG_NAME,
max(case sq.pseudonym when 'LA_CTY_REF_FU_COMPLETE_DATE_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_REF_FU_COMPLETE_DATE_ISP,
max(case sq.pseudonym when 'LA_CTY_REF_FU_DUE_DATE_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_REF_FU_DUE_DATE_ISP,
max(case sq.pseudonym when 'LA_CTY_REF_FU_OUTCOME_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_REF_FU_OUTCOME_ISP,
max(case sq.pseudonym when 'LA_CTY_SIG_INTERVAL_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_SIG_INTERVAL_ISP,
max(case sq.pseudonym when 'LA_CTY_SOCIAL_NEEDS_IDENTIFIED_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_SOCIAL_NEEDS_IDENTIFIED_ISP,
max(case sq.pseudonym when 'LA_CTY_SOCIAL_NEEDS_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_SOCIAL_NEEDS_ISP,
max(case sq.pseudonym when 'LA_CTY_SRVC_COMP_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_SRVC_COMP_ISP,
max(case sq.pseudonym when 'LA_CTY_SRVC_DATE_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_SRVC_DATE_ISP,
max(case sq.pseudonym when 'LA_CTY_SUP_SIG_DATE_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_SUP_SIG_DATE_ISP,
max(case sq.pseudonym when 'LA_CTY_SUP_SIG_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_SUP_SIG_ISP,
max(case sq.pseudonym when 'LA_CTY_TARGET_POP_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_TARGET_POP_ISP,
max(case sq.pseudonym when 'LA_CTY_TARGET_POP_RISK_21_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_TARGET_POP_RISK_21_ISP,
max(case sq.pseudonym when 'LA_CTY_TARGET_POP_RISK_NEG_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_TARGET_POP_RISK_NEG_ISP,
max(case sq.pseudonym when 'LA_CTY_VISIT_LOCATION_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_VISIT_LOCATION_ISP,
max(case sq.pseudonym when 'LA_CTY_VOC_ED_NEEDS_IDENTIFIED_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_VOC_ED_NEEDS_IDENTIFIED_ISP,
max(case sq.pseudonym when 'LA_CTY_VOC_ED_NEEDS_ISP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as LA_CTY_VOC_ED_NEEDS_ISP,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME   


   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'TCM ISP'
  
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
