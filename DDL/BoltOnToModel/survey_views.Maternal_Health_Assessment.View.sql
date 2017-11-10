DROP VIEW [survey_views].[Maternal_Health_Assessment]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view  [survey_views].[Maternal_Health_Assessment] as
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
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_ 0_DO_ANYTHING ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as [CLIENT_HEALTH_BELIEF_ 0_DO_ANYTHING],
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_CANT_SOLVE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_BELIEF_0_CANT_SOLVE,
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_FEEL_HELPLESS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_BELIEF_0_FEEL_HELPLESS,
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_FEEL_PUSHED_AROUND ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_BELIEF_0_FEEL_PUSHED_AROUND,
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_FUTURE_CONTROL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_BELIEF_0_FUTURE_CONTROL,
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_LITTLE_CAN_DO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_BELIEF_0_LITTLE_CAN_DO,
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_LITTLE_CONTROL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_BELIEF_0_LITTLE_CONTROL,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_ADDICTION ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_0_ADDICTION,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_CONCERNS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_0_CONCERNS,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_CONCERNS2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_0_CONCERNS2,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_MENTAL_HEALTH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_0_MENTAL_HEALTH,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_OTHER ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_0_OTHER,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_BP ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_BP,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_DIABETES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_DIABETES,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_HEART ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_HEART,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_KIDNEYS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_KIDNEYS,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_STI ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_STI,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_UTI ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_UTI,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_VI ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_VI,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_CURRENT_WEIGHT_0_POUNDS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_CURRENT_WEIGHT_0_POUNDS,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_HEIGHT_0_FEET ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_HEIGHT_0_FEET,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_HEIGHT_1_INCHES ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_HEIGHT_1_INCHES,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_WEIGHT_0_POUNDS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_GENERAL_WEIGHT_0_POUNDS,
	max(case sq.pseudonym when 'CLIENT_HEALTH_PREGNANCY_0_DOCTOR_VISIT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_PREGNANCY_0_DOCTOR_VISIT,
	max(case sq.pseudonym when 'CLIENT_HEALTH_PREGNANCY_0_EDD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_PREGNANCY_0_EDD,
	max(case sq.pseudonym when 'CLIENT_HEALTH_PREGNANCY_0_LIVE_BIRTHS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_PREGNANCY_0_LIVE_BIRTHS,
	max(case sq.pseudonym when 'CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME


   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Maternal Health Assessment'
  
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
