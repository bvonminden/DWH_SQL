USE [dwh_test]
GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Maternal_Health_Assessment]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_Maternal_Health_Assessment]
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
RespondentID int, 
CLIENT_0_ID_AGENCY varchar(256), 
CLIENT_0_ID_NSO varchar(256), 
[CLIENT_HEALTH_BELIEF_ 0_DO_ANYTHING] varchar(256), 
CLIENT_HEALTH_BELIEF_0_CANT_SOLVE varchar(256), 
CLIENT_HEALTH_BELIEF_0_FEEL_HELPLESS varchar(256), 
CLIENT_HEALTH_BELIEF_0_FEEL_PUSHED_AROUND varchar(256), 
CLIENT_HEALTH_BELIEF_0_FUTURE_CONTROL varchar(256), 
CLIENT_HEALTH_BELIEF_0_LITTLE_CAN_DO varchar(256), 
CLIENT_HEALTH_BELIEF_0_LITTLE_CONTROL varchar(256), 
CLIENT_HEALTH_GENERAL_0_ADDICTION varchar(256), 
CLIENT_HEALTH_GENERAL_0_CONCERNS varchar(256), 
CLIENT_HEALTH_GENERAL_0_CONCERNS2 varchar(256), 
CLIENT_HEALTH_GENERAL_0_MENTAL_HEALTH varchar(256), 
CLIENT_HEALTH_GENERAL_0_OTHER varchar(256), 
CLIENT_HEALTH_GENERAL_0_PRE_GEST_BP varchar(256), 
CLIENT_HEALTH_GENERAL_0_PRE_GEST_DIABETES varchar(256), 
CLIENT_HEALTH_GENERAL_0_PRE_GEST_HEART varchar(256), 
CLIENT_HEALTH_GENERAL_0_PRE_GEST_KIDNEYS varchar(256), 
CLIENT_HEALTH_GENERAL_0_PRE_GEST_STI varchar(256), 
CLIENT_HEALTH_GENERAL_0_PRE_GEST_UTI varchar(256), 
CLIENT_HEALTH_GENERAL_0_PRE_GEST_VI varchar(256), 
CLIENT_HEALTH_GENERAL_CURRENT_WEIGHT_0_POUNDS varchar(256), 
CLIENT_HEALTH_GENERAL_HEIGHT_0_FEET varchar(256), 
CLIENT_HEALTH_GENERAL_HEIGHT_1_INCHES varchar(256), 
CLIENT_HEALTH_GENERAL_WEIGHT_0_POUNDS varchar(256), 
CLIENT_HEALTH_PREGNANCY_0_DOCTOR_VISIT varchar(256), 
CLIENT_HEALTH_PREGNANCY_0_EDD varchar(256), 
CLIENT_HEALTH_PREGNANCY_0_LIVE_BIRTHS varchar(256), 
CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE varchar(256), 
CLIENT_PERSONAL_0_DOB_INTAKE varchar(256), 
CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
NURSE_PERSONAL_0_NAME varchar(256)

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
    null                      as RespondentID,
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY ' then  secured_value else null end) as CLIENT_0_ID_AGENCY,
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then  secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_ 0_DO_ANYTHING ' then  secured_value else null end) as [CLIENT_HEALTH_BELIEF_ 0_DO_ANYTHING],
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_CANT_SOLVE ' then  secured_value else null end) as CLIENT_HEALTH_BELIEF_0_CANT_SOLVE,
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_FEEL_HELPLESS ' then  secured_value else null end) as CLIENT_HEALTH_BELIEF_0_FEEL_HELPLESS,
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_FEEL_PUSHED_AROUND ' then  secured_value else null end) as CLIENT_HEALTH_BELIEF_0_FEEL_PUSHED_AROUND,
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_FUTURE_CONTROL ' then  secured_value else null end) as CLIENT_HEALTH_BELIEF_0_FUTURE_CONTROL,
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_LITTLE_CAN_DO ' then  secured_value else null end) as CLIENT_HEALTH_BELIEF_0_LITTLE_CAN_DO,
	max(case sq.pseudonym when 'CLIENT_HEALTH_BELIEF_0_LITTLE_CONTROL ' then  secured_value else null end) as CLIENT_HEALTH_BELIEF_0_LITTLE_CONTROL,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_ADDICTION ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_ADDICTION,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_CONCERNS ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_CONCERNS,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_CONCERNS2 ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_CONCERNS2,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_MENTAL_HEALTH ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_MENTAL_HEALTH,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_OTHER ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_OTHER,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_BP ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_BP,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_DIABETES ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_DIABETES,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_HEART ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_HEART,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_KIDNEYS ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_KIDNEYS,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_STI ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_STI,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_UTI ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_UTI,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_0_PRE_GEST_VI ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_0_PRE_GEST_VI,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_CURRENT_WEIGHT_0_POUNDS ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_CURRENT_WEIGHT_0_POUNDS,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_HEIGHT_0_FEET ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_HEIGHT_0_FEET,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_HEIGHT_1_INCHES ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_HEIGHT_1_INCHES,
	max(case sq.pseudonym when 'CLIENT_HEALTH_GENERAL_WEIGHT_0_POUNDS ' then  secured_value else null end) as CLIENT_HEALTH_GENERAL_WEIGHT_0_POUNDS,
	max(case sq.pseudonym when 'CLIENT_HEALTH_PREGNANCY_0_DOCTOR_VISIT ' then  secured_value else null end) as CLIENT_HEALTH_PREGNANCY_0_DOCTOR_VISIT,
	max(case sq.pseudonym when 'CLIENT_HEALTH_PREGNANCY_0_EDD ' then  secured_value else null end) as CLIENT_HEALTH_PREGNANCY_0_EDD,
	max(case sq.pseudonym when 'CLIENT_HEALTH_PREGNANCY_0_LIVE_BIRTHS ' then  secured_value else null end) as CLIENT_HEALTH_PREGNANCY_0_LIVE_BIRTHS,
	max(case sq.pseudonym when 'CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE ' then  secured_value else null end) as CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then  secured_value else null end) as NURSE_PERSONAL_0_NAME


  from survey_views.f_secure_fact_survey_response('Maternal Health Assessment',@p_requested_security_policy,@p_export_profile_id) fr    
   
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
