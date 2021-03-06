USE [dwh_test]
GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Client_Funding_Source]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_Client_Funding_Source]
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
	CLIENT_FUNDING_0_SOURCE_MIECHVP_COM varchar(256), 
	CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM varchar(256), 
	CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL varchar(256), 
	CLIENT_FUNDING_0_SOURCE_OTHER1 varchar(256), 
	CLIENT_FUNDING_0_SOURCE_OTHER2 varchar(256), 
	CLIENT_FUNDING_0_SOURCE_OTHER3 varchar(256), 
	CLIENT_FUNDING_0_SOURCE_OTHER4 varchar(256), 
	CLIENT_FUNDING_0_SOURCE_OTHER5 varchar(256), 
	CLIENT_FUNDING_0_SOURCE_OTHER6 varchar(256), 
	CLIENT_FUNDING_0_SOURCE_PFS varchar(256), 
	CLIENT_FUNDING_1_END_MIECHVP_COM varchar(256), 
	CLIENT_FUNDING_1_END_MIECHVP_FORM varchar(256), 
	CLIENT_FUNDING_1_END_MIECHVP_TRIBAL varchar(256), 
	CLIENT_FUNDING_1_END_OTHER1 varchar(256), 
	CLIENT_FUNDING_1_END_OTHER2 varchar(256), 
	CLIENT_FUNDING_1_END_OTHER3 varchar(256), 
	CLIENT_FUNDING_1_END_OTHER4 varchar(256), 
	CLIENT_FUNDING_1_END_OTHER5 varchar(256), 
	CLIENT_FUNDING_1_END_OTHER6 varchar(256), 
	CLIENT_FUNDING_1_END_PFS varchar(256), 
	CLIENT_FUNDING_1_START_MIECHVP_COM varchar(256), 
	CLIENT_FUNDING_1_START_MIECHVP_FORM varchar(256), 
	CLIENT_FUNDING_1_START_MIECHVP_TRIBAL varchar(256), 
	CLIENT_FUNDING_1_START_OTHER1 varchar(256), 
	CLIENT_FUNDING_1_START_OTHER2 varchar(256), 
	CLIENT_FUNDING_1_START_OTHER3 varchar(256), 
	CLIENT_FUNDING_1_START_OTHER4 varchar(256), 
	CLIENT_FUNDING_1_START_OTHER5 varchar(256), 
	CLIENT_FUNDING_1_START_OTHER6 varchar(256), 
	CLIENT_FUNDING_1_START_PFS varchar(256), 
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
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_MIECHVP_COM '  then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_MIECHVP_COM,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM '  then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL '  then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_OTHER1 '  then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_OTHER1,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_OTHER2 '  then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_OTHER2,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_OTHER3 '  then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_OTHER3,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_OTHER4 '  then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_OTHER4,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_OTHER5 '  then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_OTHER5,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_OTHER6 '  then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_OTHER6,
	max(case sq.pseudonym when 'CLIENT_FUNDING_0_SOURCE_PFS '  then  secured_value else null end) as CLIENT_FUNDING_0_SOURCE_PFS,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_MIECHVP_COM '  then  secured_value else null end) as CLIENT_FUNDING_1_END_MIECHVP_COM,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_MIECHVP_FORM '  then  secured_value else null end) as CLIENT_FUNDING_1_END_MIECHVP_FORM,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_MIECHVP_TRIBAL '  then  secured_value else null end) as CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_OTHER1 '  then  secured_value else null end) as CLIENT_FUNDING_1_END_OTHER1,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_OTHER2 '  then  secured_value else null end) as CLIENT_FUNDING_1_END_OTHER2,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_OTHER3 '  then  secured_value else null end) as CLIENT_FUNDING_1_END_OTHER3,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_OTHER4 '  then  secured_value else null end) as CLIENT_FUNDING_1_END_OTHER4,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_OTHER5 '  then  secured_value else null end) as CLIENT_FUNDING_1_END_OTHER5,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_OTHER6 '  then  secured_value else null end) as CLIENT_FUNDING_1_END_OTHER6,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_END_PFS '  then  secured_value else null end) as CLIENT_FUNDING_1_END_PFS,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_MIECHVP_COM '  then  secured_value else null end) as CLIENT_FUNDING_1_START_MIECHVP_COM,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_MIECHVP_FORM '  then  secured_value else null end) as CLIENT_FUNDING_1_START_MIECHVP_FORM,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_MIECHVP_TRIBAL '  then  secured_value else null end) as CLIENT_FUNDING_1_START_MIECHVP_TRIBAL,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_OTHER1 '  then  secured_value else null end) as CLIENT_FUNDING_1_START_OTHER1,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_OTHER2 '  then  secured_value else null end) as CLIENT_FUNDING_1_START_OTHER2,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_OTHER3 '  then  secured_value else null end) as CLIENT_FUNDING_1_START_OTHER3,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_OTHER4 '  then  secured_value else null end) as CLIENT_FUNDING_1_START_OTHER4,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_OTHER5 '  then  secured_value else null end) as CLIENT_FUNDING_1_START_OTHER5,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_OTHER6 '  then  secured_value else null end) as CLIENT_FUNDING_1_START_OTHER6,
	max(case sq.pseudonym when 'CLIENT_FUNDING_1_START_PFS '  then  secured_value else null end) as CLIENT_FUNDING_1_START_PFS,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME '  then  secured_value else null end) as NURSE_PERSONAL_0_NAME

   from survey_views.f_secure_fact_survey_response( 'Client Funding Source',@p_requested_security_policy,@p_export_profile_id) fr  
   
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
