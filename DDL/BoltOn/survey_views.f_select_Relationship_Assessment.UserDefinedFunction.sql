USE [dwh_test]
GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Relationship_Assessment]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_Relationship_Assessment]
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
CLIENT_ABUSE_AFRAID_0_PARTNER varchar(256), 
CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER varchar(256), 
CLIENT_ABUSE_FORCED_0_SEX varchar(256), 
CLIENT_ABUSE_FORCED_1_SEX_LAST_YR varchar(256), 
CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME varchar(256), 
CLIENT_ABUSE_HIT_0_SLAP_PARTNER varchar(256), 
CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER varchar(256), 
CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER varchar(256), 
CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER varchar(256), 
CLIENT_ABUSE_TIMES_0_HURT_LAST_YR varchar(256), 
CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME varchar(256), 
CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER varchar(256), 
CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER varchar(256), 
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
	max(case sq.pseudonym when 'CLIENT_ABUSE_AFRAID_0_PARTNER ' then  secured_value else null end) as CLIENT_ABUSE_AFRAID_0_PARTNER,
	max(case sq.pseudonym when 'CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER ' then  secured_value else null end) as CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER,
	max(case sq.pseudonym when 'CLIENT_ABUSE_FORCED_0_SEX ' then  secured_value else null end) as CLIENT_ABUSE_FORCED_0_SEX,
	max(case sq.pseudonym when 'CLIENT_ABUSE_FORCED_1_SEX_LAST_YR ' then  secured_value else null end) as CLIENT_ABUSE_FORCED_1_SEX_LAST_YR,
	max(case sq.pseudonym when 'CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME ' then  secured_value else null end) as CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME,
	max(case sq.pseudonym when 'CLIENT_ABUSE_HIT_0_SLAP_PARTNER ' then  secured_value else null end) as CLIENT_ABUSE_HIT_0_SLAP_PARTNER,
	max(case sq.pseudonym when 'CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER ' then  secured_value else null end) as CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER,
	max(case sq.pseudonym when 'CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER ' then  secured_value else null end) as CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER,
	max(case sq.pseudonym when 'CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER ' then  secured_value else null end) as CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER,
	max(case sq.pseudonym when 'CLIENT_ABUSE_TIMES_0_HURT_LAST_YR ' then  secured_value else null end) as CLIENT_ABUSE_TIMES_0_HURT_LAST_YR,
	max(case sq.pseudonym when 'CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME ' then  secured_value else null end) as CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME,
	max(case sq.pseudonym when 'CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER ' then  secured_value else null end) as CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER,
	max(case sq.pseudonym when 'CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER ' then  secured_value else null end) as CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then  secured_value else null end) as NURSE_PERSONAL_0_NAME



      from survey_views.f_secure_fact_survey_response('Relationship Assessment',@p_requested_security_policy,@p_export_profile_id) fr  
   
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
