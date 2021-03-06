USE [dwh_test]
GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Client_Discharge]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create FUNCTION [survey_views].[f_select_Client_Discharge]
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
[CLIENT_0_ID_NSO] varchar(256),
[CLIENT_PERSONAL_0_NAME_FIRST] varchar(256),
[CLIENT_PERSONAL_0_NAME_LAST] varchar(256),
[CLIENT_DISCHARGE_1_LOST_CUSTODY_DATE] varchar(256),
[CLIENT_DISCHARGE_1_MATERNAL_DEATH_DATE] varchar(256),
[CLIENT_DISCHARGE_1_INCARCERATION_DATE] varchar(256),
[CLIENT_DISCHARGE_1_INFANTDEATH_DATE] varchar(256),
[CLIENT_DISCHARGE_1_MISCARRIED_DATE2] varchar(256),
[CLIENT_PERSONAL_0_DOB_INTAKE] varchar(256),
[CLIENT_DISCHARGE_1_MISCARRIED_DATE] varchar(256),
[NURSE_PERSONAL_0_NAME] varchar(256),
[CLIENT_DISCHARGE_1_MATERNAL_DEATH_REASON] varchar(256),
[CLIENT_DISCHARGE_1_INFANTDEATH_REASON] varchar(256),
[CLIENT_DISCHARGE_1_LOST_CUSTODY] varchar(256),
[CLIENT_DISCHARGE_0_REASON] varchar(256),
[CLIENT_DISCHARGE_1_UNABLE_REASON] varchar(256),
[CLIENT_0_ID_AGENCY] varchar(256)
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
	max(case sq.pseudonym when 'CLIENT_0_ID_NSO'  then  fr.secured_value else null end) as [CLIENT_0_ID_NSO],
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST'  then  fr.secured_value else null end) as [CLIENT_PERSONAL_0_NAME_FIRST],
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST'  then  fr.secured_value else null end) as [CLIENT_PERSONAL_0_NAME_LAST],
	max(case sq.pseudonym when 'CLIENT_DISCHARGE_1_LOST_CUSTODY_DATE'  then  fr.secured_value else null end) as [CLIENT_DISCHARGE_1_LOST_CUSTODY_DATE],
	max(case sq.pseudonym when 'CLIENT_DISCHARGE_1_MATERNAL_DEATH_DATE'  then  fr.secured_value else null end) as [CLIENT_DISCHARGE_1_MATERNAL_DEATH_DATE],
	max(case sq.pseudonym when 'CLIENT_DISCHARGE_1_INCARCERATION_DATE'  then  fr.secured_value else null end) as [CLIENT_DISCHARGE_1_INCARCERATION_DATE],
	max(case sq.pseudonym when 'CLIENT_DISCHARGE_1_INFANTDEATH_DATE'  then  fr.secured_value else null end) as [CLIENT_DISCHARGE_1_INFANTDEATH_DATE],
	max(case sq.pseudonym when 'CLIENT_DISCHARGE_1_MISCARRIED_DATE2'  then  fr.secured_value else null end) as [CLIENT_DISCHARGE_1_MISCARRIED_DATE2],
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE'  then  fr.secured_value else null end) as [CLIENT_PERSONAL_0_DOB_INTAKE],
	max(case sq.pseudonym when 'CLIENT_DISCHARGE_1_MISCARRIED_DATE'  then  fr.secured_value else null end) as [CLIENT_DISCHARGE_1_MISCARRIED_DATE],
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME'  then  fr.secured_value else null end) as [NURSE_PERSONAL_0_NAME],
	max(case sq.pseudonym when 'CLIENT_DISCHARGE_1_MATERNAL_DEATH_REASON'  then  fr.secured_value else null end) as [CLIENT_DISCHARGE_1_MATERNAL_DEATH_REASON],
	max(case sq.pseudonym when 'CLIENT_DISCHARGE_1_INFANTDEATH_REASON'  then  fr.secured_value else null end) as [CLIENT_DISCHARGE_1_INFANTDEATH_REASON],
	max(case sq.pseudonym when 'CLIENT_DISCHARGE_1_LOST_CUSTODY'  then  fr.secured_value else null end) as [CLIENT_DISCHARGE_1_LOST_CUSTODY],
	max(case sq.pseudonym when 'CLIENT_DISCHARGE_1_UNABLE_REASON'  then  fr.secured_value else null end) as [CLIENT_DISCHARGE_1_UNABLE_REASON],
	max(case sq.pseudonym when 'CLIENT_DISCHARGE_0_REASON'  then  fr.secured_value else null end) as [CLIENT_DISCHARGE_0_REASON],
	max(case sq.pseudonym when 'CLIENT_0_ID_AGENCY'  then  fr.secured_value else null end) as [CLIENT_0_ID_AGENCY]

      from survey_views.f_secure_fact_survey_response( 'Supplemental Discharge Information', @p_requested_security_policy, @p_export_profile_id) fr  

   
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
