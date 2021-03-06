USE [dwh_test]
GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Use_Of_Government_and_Community_Services]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_Use_Of_Government_and_Community_Services]
(
	@p_requested_security_policy char(10)=null,
	@p_export_profile_id int=null
)
RETURNS 
@result TABLE 
(
SurveyResponseID int, 
ElementsProcessed int, 
SurveyID int, 
SurveyDate date, 
AuditDate datetime2, 
CL_EN_GEN_ID bigint, 
SiteID int, 
ProgramID int, 
IA_StaffID int, 
ClientID varchar(20), 
CLIENT_0_ID_AGENCY varchar(256), 
CLIENT_0_ID_NSO varchar(256), 
CLIENT_PERSONAL_0_DOB_INTAKE varchar(256), 
CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
[JP error ] varchar(256), 
NURSE_PERSONAL_0_NAME varchar(256), 
SERVICE_USE_0_ADOPTION_CLIENT varchar(256), 
SERVICE_USE_0_ALCOHOL_ABUSE_CLIENT varchar(256), 
SERVICE_USE_0_BIRTH_EDUC_CLASS_CLIENT varchar(256), 
SERVICE_USE_0_CHARITY_CLIENT varchar(256), 
SERVICE_USE_0_CHILD_CARE_CLIENT varchar(256), 
SERVICE_USE_0_CHILD_OTHER1 varchar(256), 
SERVICE_USE_0_CHILD_OTHER2 varchar(256), 
SERVICE_USE_0_CHILD_OTHER3 varchar(256), 
SERVICE_USE_0_CHILD_SUPPORT_CLIENT varchar(256), 
SERVICE_USE_0_CPS_CHILD varchar(256), 
SERVICE_USE_0_CPS_CLIENT varchar(256), 
SERVICE_USE_0_DENTAL_CHILD varchar(256), 
SERVICE_USE_0_DENTAL_CLIENT varchar(256), 
SERVICE_USE_0_DEVELOPMENTAL_DISABILITY_CLIENT varchar(256), 
SERVICE_USE_0_DRUG_ABUSE_CLIENT varchar(256), 
SERVICE_USE_0_FOODSTAMP_CLIENT varchar(256), 
SERVICE_USE_0_GED_CLIENT varchar(256), 
SERVICE_USE_0_HIGHER_EDUC_CLIENT varchar(256), 
SERVICE_USE_0_HOUSING_CLIENT varchar(256), 
SERVICE_USE_0_INTERVENTION varchar(256), 
SERVICE_USE_0_INTERVENTION_45DAYS varchar(256), 
SERVICE_USE_0_IPV_CLIENT varchar(256), 
SERVICE_USE_0_JOB_TRAINING_CLIENT varchar(256), 
SERVICE_USE_0_LACTATION_CLIENT varchar(256), 
SERVICE_USE_0_LEGAL_CLIENT varchar(256), 
SERVICE_USE_0_MEDICAID_CHILD varchar(256), 
SERVICE_USE_0_MEDICAID_CLIENT varchar(256), 
SERVICE_USE_0_MENTAL_CLIENT varchar(256), 
SERVICE_USE_0_OTHER1 varchar(256), 
SERVICE_USE_0_OTHER1_DESC varchar(256), 
SERVICE_USE_0_OTHER2 varchar(256), 
SERVICE_USE_0_OTHER2_DESC varchar(256), 
SERVICE_USE_0_OTHER3 varchar(256), 
SERVICE_USE_0_OTHER3_DESC varchar(256), 
SERVICE_USE_0_PATERNITY_CLIENT varchar(256), 
SERVICE_USE_0_PCP_CLIENT varchar(256), 
SERVICE_USE_0_PCP_SICK_CHILD varchar(256), 
SERVICE_USE_0_PCP_WELL_CHILD varchar(256), 
SERVICE_USE_0_PCP_WELL_CLIENT varchar(256), 
SERVICE_USE_0_PREVENT_INJURY_CLIENT varchar(256), 
SERVICE_USE_0_PRIVATE_INSURANCE_CHILD varchar(256), 
SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT varchar(256), 
SERVICE_USE_0_RELATIONSHIP_COUNSELING_CLIENT varchar(256), 
SERVICE_USE_0_SCHIP_CHILD varchar(256), 
SERVICE_USE_0_SCHIP_CLIENT varchar(256), 
SERVICE_USE_0_SMOKE_CLIENT varchar(256), 
SERVICE_USE_0_SOCIAL_SECURITY_CLIENT varchar(256), 
SERVICE_USE_0_SPECIAL_NEEDS_CHILD varchar(256), 
SERVICE_USE_0_SPECIAL_NEEDS_CLIENT varchar(256), 
SERVICE_USE_0_SUBSID_CHILD_CARE_CLIENT varchar(256), 
SERVICE_USE_0_TANF_CLIENT varchar(256), 
SERVICE_USE_0_TRANSPORTATION_CLIENT varchar(256), 
SERVICE_USE_0_UNEMPLOYMENT_CLIENT varchar(256), 
SERVICE_USE_0_WIC_CLIENT varchar(256), 
SERVICE_USE_INDIAN_HEALTH_CHILD varchar(256), 
SERVICE_USE_INDIAN_HEALTH_CLIENT varchar(256), 
SERVICE_USE_MILITARY_INS_CHILD varchar(256), 
SERVICE_USE_MILITARY_INS_CLIENT varchar(256), 
SERVICE_USE_PCP_CLIENT_POSTPARTUM varchar(256), 
SERVICE_USE_PCP_CLIENT_PRENATAL varchar(256), 
SERVICE_USE_PCP_CLIENT_WELLWOMAN varchar(256)

)
as
begin

insert into @result
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
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then  secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'JP error - if no data associated delete element ' then  secured_value else null end) as [JP error - if no data associated delete element],
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then  secured_value else null end) as NURSE_PERSONAL_0_NAME,
	max(case sq.pseudonym when 'SERVICE_USE_0_ADOPTION_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_ADOPTION_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_ALCOHOL_ABUSE_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_ALCOHOL_ABUSE_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_BIRTH_EDUC_CLASS_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_BIRTH_EDUC_CLASS_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_CHARITY_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_CHARITY_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_CHILD_CARE_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_CHILD_CARE_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_CHILD_OTHER1 ' then  secured_value else null end) as SERVICE_USE_0_CHILD_OTHER1,
	max(case sq.pseudonym when 'SERVICE_USE_0_CHILD_OTHER2 ' then  secured_value else null end) as SERVICE_USE_0_CHILD_OTHER2,
	max(case sq.pseudonym when 'SERVICE_USE_0_CHILD_OTHER3 ' then  secured_value else null end) as SERVICE_USE_0_CHILD_OTHER3,
	max(case sq.pseudonym when 'SERVICE_USE_0_CHILD_SUPPORT_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_CHILD_SUPPORT_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_CPS_CHILD ' then  secured_value else null end) as SERVICE_USE_0_CPS_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_0_CPS_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_CPS_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_DENTAL_CHILD ' then  secured_value else null end) as SERVICE_USE_0_DENTAL_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_0_DENTAL_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_DENTAL_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_DEVELOPMENTAL_DISABILITY_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_DEVELOPMENTAL_DISABILITY_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_DRUG_ABUSE_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_DRUG_ABUSE_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_FOODSTAMP_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_FOODSTAMP_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_GED_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_GED_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_HIGHER_EDUC_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_HIGHER_EDUC_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_HOUSING_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_HOUSING_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_INTERVENTION ' then  secured_value else null end) as SERVICE_USE_0_INTERVENTION,
	max(case sq.pseudonym when 'SERVICE_USE_0_INTERVENTION_45DAYS ' then  secured_value else null end) as SERVICE_USE_0_INTERVENTION_45DAYS,
	max(case sq.pseudonym when 'SERVICE_USE_0_IPV_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_IPV_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_JOB_TRAINING_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_JOB_TRAINING_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_LACTATION_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_LACTATION_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_LEGAL_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_LEGAL_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_MEDICAID_CHILD ' then  secured_value else null end) as SERVICE_USE_0_MEDICAID_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_0_MEDICAID_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_MEDICAID_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_MENTAL_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_MENTAL_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_OTHER1 ' then  secured_value else null end) as SERVICE_USE_0_OTHER1,
	max(case sq.pseudonym when 'SERVICE_USE_0_OTHER1_DESC ' then  secured_value else null end) as SERVICE_USE_0_OTHER1_DESC,
	max(case sq.pseudonym when 'SERVICE_USE_0_OTHER2 ' then  secured_value else null end) as SERVICE_USE_0_OTHER2,
	max(case sq.pseudonym when 'SERVICE_USE_0_OTHER2_DESC ' then  secured_value else null end) as SERVICE_USE_0_OTHER2_DESC,
	max(case sq.pseudonym when 'SERVICE_USE_0_OTHER3 ' then  secured_value else null end) as SERVICE_USE_0_OTHER3,
	max(case sq.pseudonym when 'SERVICE_USE_0_OTHER3_DESC ' then  secured_value else null end) as SERVICE_USE_0_OTHER3_DESC,
	max(case sq.pseudonym when 'SERVICE_USE_0_PATERNITY_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_PATERNITY_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_PCP_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_PCP_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_PCP_SICK_CHILD ' then  secured_value else null end) as SERVICE_USE_0_PCP_SICK_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_0_PCP_WELL_CHILD ' then  secured_value else null end) as SERVICE_USE_0_PCP_WELL_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_0_PCP_WELL_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_PCP_WELL_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_PREVENT_INJURY_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_PREVENT_INJURY_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_PRIVATE_INSURANCE_CHILD ' then  secured_value else null end) as SERVICE_USE_0_PRIVATE_INSURANCE_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_RELATIONSHIP_COUNSELING_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_RELATIONSHIP_COUNSELING_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_SCHIP_CHILD ' then  secured_value else null end) as SERVICE_USE_0_SCHIP_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_0_SCHIP_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_SCHIP_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_SMOKE_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_SMOKE_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_SOCIAL_SECURITY_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_SOCIAL_SECURITY_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_SPECIAL_NEEDS_CHILD ' then  secured_value else null end) as SERVICE_USE_0_SPECIAL_NEEDS_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_0_SPECIAL_NEEDS_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_SPECIAL_NEEDS_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_SUBSID_CHILD_CARE_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_SUBSID_CHILD_CARE_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_TANF_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_TANF_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_TRANSPORTATION_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_TRANSPORTATION_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_UNEMPLOYMENT_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_UNEMPLOYMENT_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_0_WIC_CLIENT ' then  secured_value else null end) as SERVICE_USE_0_WIC_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_INDIAN_HEALTH_CHILD ' then  secured_value else null end) as SERVICE_USE_INDIAN_HEALTH_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_INDIAN_HEALTH_CLIENT ' then  secured_value else null end) as SERVICE_USE_INDIAN_HEALTH_CLIENT,
	max(case sq.pseudonym when 'SERVICE_USE_MILITARY_INS_CHILD ' then  secured_value else null end) as SERVICE_USE_MILITARY_INS_CHILD,
	max(case sq.pseudonym when 'SERVICE_USE_MILITARY_INS_CLIENT  ' then  secured_value else null end) as SERVICE_USE_MILITARY_INS_CLIENT ,
	max(case sq.pseudonym when 'SERVICE_USE_PCP_CLIENT_POSTPARTUM ' then  secured_value else null end) as SERVICE_USE_PCP_CLIENT_POSTPARTUM,
	max(case sq.pseudonym when 'SERVICE_USE_PCP_CLIENT_PRENATAL ' then  secured_value else null end) as SERVICE_USE_PCP_CLIENT_PRENATAL,
	max(case sq.pseudonym when 'SERVICE_USE_PCP_CLIENT_WELLWOMAN ' then  secured_value else null end) as SERVICE_USE_PCP_CLIENT_WELLWOMAN

   from survey_views.f_secure_fact_survey_response('Use Of Government & Community Services',@p_requested_security_policy,@p_export_profile_id) fr   
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id;
return;
end

GO
