DROP VIEW [survey_views].[MN_6_Months_Infant]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[MN_6_Months_Infant] as
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
max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'INFANT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_0_ID_NSO,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_PERSONAL_0_NAME_FIRST,
max(case sq.pseudonym when 'INFANT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as INFANT_PERSONAL_0_NAME_LAST,
max(case sq.pseudonym when 'MN_ASQ3_4MOS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_ASQ3_4MOS,
max(case sq.pseudonym when 'MN_ASQ3_REFERRAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_ASQ3_REFERRAL,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CLIENT_INSURANCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CLIENT_INSURANCE_RESOURCE,
max(case sq.pseudonym when 'MN_CLIENT_INSURANCE_RESOURCE_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CLIENT_INSURANCE_RESOURCE_OTHER,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_COMPLETED_EDUCATION_PROGRAMS,
max(case sq.pseudonym when 'MN_COMPLETED_EDUCATION_PROGRAMS_YES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_COMPLETED_EDUCATION_PROGRAMS_YES,
max(case sq.pseudonym when 'MN_CPA_FILE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CPA_FILE,
max(case sq.pseudonym when 'MN_CPA_FIRST_TIME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CPA_FIRST_TIME,
max(case sq.pseudonym when 'MN_CPA_SUBSTANTIATED ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_CPA_SUBSTANTIATED,
max(case sq.pseudonym when 'MN_DATA_STAFF_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_DATA_STAFF_PERSONAL_0_NAME,
max(case sq.pseudonym when 'MN_FOLIC_ACID ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_FOLIC_ACID,
max(case sq.pseudonym when 'MN_FURTHER_SCREEN_ASQ3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_FURTHER_SCREEN_ASQ3,
max(case sq.pseudonym when 'MN_INFANT_0_ID_2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_INFANT_0_ID_2,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_INFANT_INSURANCE,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_INFANT_INSURANCE_RESOURCE,
max(case sq.pseudonym when 'MN_INFANT_INSURANCE_RESOURCE_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_INFANT_INSURANCE_RESOURCE_OTHER,
max(case sq.pseudonym when 'MN_NCAST_CAREGIVER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_NCAST_CAREGIVER,
max(case sq.pseudonym when 'MN_NCAST_CLARITY_CUES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_NCAST_CLARITY_CUES,
max(case sq.pseudonym when 'MN_NCAST_COGN_GROWTH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_NCAST_COGN_GROWTH,
max(case sq.pseudonym when 'MN_NCAST_DISTRESS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_NCAST_DISTRESS,
max(case sq.pseudonym when 'MN_NCAST_SE_GROWTH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_NCAST_SE_GROWTH,
max(case sq.pseudonym when 'MN_NCAST_SENS_CUES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_NCAST_SENS_CUES,
max(case sq.pseudonym when 'MN_SITE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_SITE,
max(case sq.pseudonym when 'MN_TOTAL_HV ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as MN_TOTAL_HV,
max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME


   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'MN 6 Months Infant'
  
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
