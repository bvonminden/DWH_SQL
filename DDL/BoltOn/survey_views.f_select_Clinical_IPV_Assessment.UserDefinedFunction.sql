USE [dwh_test]
GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Clinical_IPV_Assessment]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_Clinical_IPV_Assessment]
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
	IPV_AFRAID varchar(256), 
	IPV_CHILD_SAFETY varchar(256), 
	IPV_CONTROLING varchar(256), 
	IPV_FORCED_SEX varchar(256), 
	IPV_INDICATED varchar(256), 
	IPV_INSULTED varchar(256), 
	IPV_PHYSICALLY_HURT varchar(256), 
	IPV_PRN_REASON varchar(256), 
	IPV_Q1_4_SCORE varchar(256), 
	IPV_SCREAMED varchar(256), 
	IPV_THREATENED varchar(256), 
	IPV_TOOL_USED varchar(256), 
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
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO '  then  secured_value else null end) as CLIENT_0_ID_NSO,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE '  then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST  '  then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST ,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST '  then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'IPV_AFRAID '  then  secured_value else null end) as IPV_AFRAID,
	max(case sq.pseudonym when 'IPV_CHILD_SAFETY '  then  secured_value else null end) as IPV_CHILD_SAFETY,
	max(case sq.pseudonym when 'IPV_CONTROLING '  then  secured_value else null end) as IPV_CONTROLING,
	max(case sq.pseudonym when 'IPV_FORCED_SEX '  then  secured_value else null end) as IPV_FORCED_SEX,
	max(case sq.pseudonym when 'IPV_INDICATED '  then  secured_value else null end) as IPV_INDICATED,
	max(case sq.pseudonym when 'IPV_INSULTED '  then  secured_value else null end) as IPV_INSULTED,
	max(case sq.pseudonym when 'IPV_PHYSICALLY_HURT '  then  secured_value else null end) as IPV_PHYSICALLY_HURT,
	max(case sq.pseudonym when 'IPV_PRN_REASON '  then  secured_value else null end) as IPV_PRN_REASON,
	max(case sq.pseudonym when 'IPV_Q1_4_SCORE '  then  secured_value else null end) as IPV_Q1_4_SCORE,
	max(case sq.pseudonym when 'IPV_SCREAMED '  then  secured_value else null end) as IPV_SCREAMED,
	max(case sq.pseudonym when 'IPV_THREATENED '  then  secured_value else null end) as IPV_THREATENED,
	max(case sq.pseudonym when 'IPV_TOOL_USED '  then  secured_value else null end) as IPV_TOOL_USED,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME '  then  secured_value else null end) as NURSE_PERSONAL_0_NAME

   from survey_views.f_secure_fact_survey_response('Clinical IPV Assessment',@p_requested_security_policy,@p_export_profile_id) fr  
   
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
