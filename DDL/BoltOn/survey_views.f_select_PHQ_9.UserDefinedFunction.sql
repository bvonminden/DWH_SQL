USE [dwh_test]
GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_PHQ_9]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_PHQ_9]
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
CLIENT_0_ID_NSO varchar(256), 
CLIENT_PERSONAL_0_DOB_INTAKE varchar(256), 
CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
CLIENT_PHQ9_0_TOTAL_SCORE varchar(256), 
CLIENT_PHQ9_1_CONCENTRATION varchar(256), 
CLIENT_PHQ9_1_DIFFICULTY varchar(256), 
CLIENT_PHQ9_1_FEEL_BAD varchar(256), 
CLIENT_PHQ9_1_FEEL_DEPRESSED varchar(256), 
CLIENT_PHQ9_1_FEEL_TIRED varchar(256), 
CLIENT_PHQ9_1_HURT_SELF varchar(256), 
CLIENT_PHQ9_1_LITTLE_INTEREST varchar(256), 
CLIENT_PHQ9_1_MOVE_SPEAK varchar(256), 
CLIENT_PHQ9_1_TROUBLE_EAT varchar(256), 
CLIENT_PHQ9_1_TROUBLE_SLEEP varchar(256), 
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
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO ' then  secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'CLIENT_PHQ9_0_TOTAL_SCORE ' then  secured_value else null end) as CLIENT_PHQ9_0_TOTAL_SCORE,
	max(case sq.pseudonym when 'CLIENT_PHQ9_1_CONCENTRATION ' then  secured_value else null end) as CLIENT_PHQ9_1_CONCENTRATION,
	max(case sq.pseudonym when 'CLIENT_PHQ9_1_DIFFICULTY ' then  secured_value else null end) as CLIENT_PHQ9_1_DIFFICULTY,
	max(case sq.pseudonym when 'CLIENT_PHQ9_1_FEEL_BAD ' then  secured_value else null end) as CLIENT_PHQ9_1_FEEL_BAD,
	max(case sq.pseudonym when 'CLIENT_PHQ9_1_FEEL_DEPRESSED ' then  secured_value else null end) as CLIENT_PHQ9_1_FEEL_DEPRESSED,
	max(case sq.pseudonym when 'CLIENT_PHQ9_1_FEEL_TIRED ' then  secured_value else null end) as CLIENT_PHQ9_1_FEEL_TIRED,
	max(case sq.pseudonym when 'CLIENT_PHQ9_1_HURT_SELF ' then  secured_value else null end) as CLIENT_PHQ9_1_HURT_SELF,
	max(case sq.pseudonym when 'CLIENT_PHQ9_1_LITTLE_INTEREST ' then  secured_value else null end) as CLIENT_PHQ9_1_LITTLE_INTEREST,
	max(case sq.pseudonym when 'CLIENT_PHQ9_1_MOVE_SPEAK ' then  secured_value else null end) as CLIENT_PHQ9_1_MOVE_SPEAK,
	max(case sq.pseudonym when 'CLIENT_PHQ9_1_TROUBLE_EAT ' then  secured_value else null end) as CLIENT_PHQ9_1_TROUBLE_EAT,
	max(case sq.pseudonym when 'CLIENT_PHQ9_1_TROUBLE_SLEEP ' then  secured_value else null end) as CLIENT_PHQ9_1_TROUBLE_SLEEP,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then  secured_value else null end) as NURSE_PERSONAL_0_NAME


   from survey_views.f_secure_fact_survey_response('PHQ-9',@p_requested_security_policy,@p_export_profile_id) fr 
   
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
