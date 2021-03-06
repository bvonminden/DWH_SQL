USE [dwh_test]
GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_TCM_Finance_Log]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_TCM_Finance_Log]
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
CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
LA_CTY_CASE_MGR_ID varchar(256), 
LA_CTY_COMPONENT_CODE_FINANCE varchar(256), 
LA_CTY_CONSENT_FINANCE varchar(256), 
LA_CTY_DEMOGRAPHIC_FINANCE varchar(256), 
LA_CTY_ENCOUNTER_FINANCE varchar(256), 
LA_CTY_LOCATION_FINANCE varchar(256), 
LA_CTY_MEDI_CAL varchar(256), 
LA_CTY_MEDI_CAL_STATUS_FINANCE varchar(256), 
LA_CTY_NPI varchar(256), 
LA_CTY_PROG_NAME varchar(256), 
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
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'LA_CTY_CASE_MGR_ID ' then  secured_value else null end) as LA_CTY_CASE_MGR_ID,
	max(case sq.pseudonym when 'LA_CTY_COMPONENT_CODE_FINANCE ' then  secured_value else null end) as LA_CTY_COMPONENT_CODE_FINANCE,
	max(case sq.pseudonym when 'LA_CTY_CONSENT_FINANCE ' then  secured_value else null end) as LA_CTY_CONSENT_FINANCE,
	max(case sq.pseudonym when 'LA_CTY_DEMOGRAPHIC_FINANCE ' then  secured_value else null end) as LA_CTY_DEMOGRAPHIC_FINANCE,
	max(case sq.pseudonym when 'LA_CTY_ENCOUNTER_FINANCE ' then  secured_value else null end) as LA_CTY_ENCOUNTER_FINANCE,
	max(case sq.pseudonym when 'LA_CTY_LOCATION_FINANCE ' then  secured_value else null end) as LA_CTY_LOCATION_FINANCE,
	max(case sq.pseudonym when 'LA_CTY_MEDI_CAL ' then  secured_value else null end) as LA_CTY_MEDI_CAL,
	max(case sq.pseudonym when 'LA_CTY_MEDI_CAL_STATUS_FINANCE ' then  secured_value else null end) as LA_CTY_MEDI_CAL_STATUS_FINANCE,
	max(case sq.pseudonym when 'LA_CTY_NPI ' then  secured_value else null end) as LA_CTY_NPI,
	max(case sq.pseudonym when 'LA_CTY_PROG_NAME ' then  secured_value else null end) as LA_CTY_PROG_NAME,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then  secured_value else null end) as NURSE_PERSONAL_0_NAME
   
   from survey_views.f_secure_fact_survey_response('TCM Finance Log',@p_requested_security_policy,@p_export_profile_id) fr  
   
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
