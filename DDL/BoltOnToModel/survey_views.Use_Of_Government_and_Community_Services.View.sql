DROP VIEW [survey_views].[Use_Of_Government_and_Community_Services]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view  [survey_views].[Use_Of_Government_and_Community_Services] as
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
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'JP error - if no data associated delete element ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as [JP error - if no data associated delete element],
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as NURSE_PERSONAL_0_NAME,
	max(case sq.pseudonym when 'SERVICE_USE_0_ADOPTION_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_ADOPTION_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_ALCOHOL_ABUSE_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_ALCOHOL_ABUSE_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_BIRTH_EDUC_CLASS_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_BIRTH_EDUC_CLASS_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_CHARITY_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_CHARITY_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_CHILD_CARE_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_CHILD_CARE_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_CHILD_OTHER1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_CHILD_OTHER1,
	max(case sq.pseudonym when 'SERVICE_USE_0_CHILD_OTHER2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_CHILD_OTHER2,
	max(case sq.pseudonym when 'SERVICE_USE_0_CHILD_OTHER3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_CHILD_OTHER3,
	max(case sq.pseudonym when 'SERVICE_USE_0_CHILD_SUPPORT_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_CHILD_SUPPORT_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_CPS_CHILD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_CPS_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_0_CPS_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_CPS_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_DENTAL_CHILD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_DENTAL_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_0_DENTAL_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_DENTAL_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_DEVELOPMENTAL_DISABILITY_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_DEVELOPMENTAL_DISABILITY_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_DRUG_ABUSE_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_DRUG_ABUSE_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_FOODSTAMP_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_FOODSTAMP_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_GED_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_GED_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_HIGHER_EDUC_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_HIGHER_EDUC_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_HOUSING_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_HOUSING_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_INTERVENTION ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_INTERVENTION,
	max(case sq.pseudonym when 'SERVICE_USE_0_INTERVENTION_45DAYS ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_INTERVENTION_45DAYS,
	max(case sq.pseudonym when 'SERVICE_USE_0_IPV_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_IPV_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_JOB_TRAINING_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_JOB_TRAINING_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_LACTATION_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_LACTATION_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_LEGAL_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_LEGAL_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_MEDICAID_CHILD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_MEDICAID_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_0_MEDICAID_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_MEDICAID_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_MENTAL_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_MENTAL_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_OTHER1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_OTHER1,
	max(case sq.pseudonym when 'SERVICE_USE_0_OTHER1_DESC ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_OTHER1_DESC,
	max(case sq.pseudonym when 'SERVICE_USE_0_OTHER2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_OTHER2,
	max(case sq.pseudonym when 'SERVICE_USE_0_OTHER2_DESC ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_OTHER2_DESC,
	max(case sq.pseudonym when 'SERVICE_USE_0_OTHER3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_OTHER3,
	max(case sq.pseudonym when 'SERVICE_USE_0_OTHER3_DESC ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_OTHER3_DESC,
	max(case sq.pseudonym when 'SERVICE_USE_0_PATERNITY_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_PATERNITY_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_PCP_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_PCP_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_PCP_SICK_CHILD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_PCP_SICK_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_0_PCP_WELL_CHILD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_PCP_WELL_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_0_PCP_WELL_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_PCP_WELL_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_PREVENT_INJURY_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_PREVENT_INJURY_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_PRIVATE_INSURANCE_CHILD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_PRIVATE_INSURANCE_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_RELATIONSHIP_COUNSELING_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_RELATIONSHIP_COUNSELING_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_SCHIP_CHILD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_SCHIP_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_0_SCHIP_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_SCHIP_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_SMOKE_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_SMOKE_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_SOCIAL_SECURITY_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_SOCIAL_SECURITY_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_SPECIAL_NEEDS_CHILD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_SPECIAL_NEEDS_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_0_SPECIAL_NEEDS_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_SPECIAL_NEEDS_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_SUBSID_CHILD_CARE_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_SUBSID_CHILD_CARE_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_TANF_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_TANF_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_TRANSPORTATION_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_TRANSPORTATION_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_UNEMPLOYMENT_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_UNEMPLOYMENT_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_WIC_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_0_WIC_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_INDIAN_HEALTH_CHILD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_INDIAN_HEALTH_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_INDIAN_HEALTH_CLIENT ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_INDIAN_HEALTH_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_MILITARY_INS_CHILD ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_MILITARY_INS_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_MILITARY_INS_CLIENT  ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_MILITARY_INS_CLIENT ,
	max(case sq.pseudonym when 'SERVICE_USE_PCP_CLIENT_POSTPARTUM ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_PCP_CLIENT_POSTPARTUM,
	max(case sq.pseudonym when 'SERVICE_USE_PCP_CLIENT_PRENATAL ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_PCP_CLIENT_PRENATAL,
	max(case sq.pseudonym when 'SERVICE_USE_PCP_CLIENT_WELLWOMAN ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as SERVICE_USE_PCP_CLIENT_WELLWOMAN

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Use Of Government & Community Services'
  
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
