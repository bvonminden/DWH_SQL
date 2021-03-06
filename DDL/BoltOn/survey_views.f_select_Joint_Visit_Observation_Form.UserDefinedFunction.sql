USE [dwh_test]
GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Joint_Visit_Observation_Form]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_Joint_Visit_Observation_Form]
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
JVO_ADDITIONAL_REASON varchar(256), 
JVO_CLIENT_CASE varchar(256), 
JVO_CLIENT_NAME varchar(256), 
JVO_CLINICAL_CHART_CONSISTENT varchar(256), 
JVO_CLINICAL_CHART_CONSISTENT_COMMENTS varchar(256), 
JVO_HVEF_CONSISTENT varchar(256), 
JVO_HVEF_CONSISTENT_COMMENTS varchar(256), 
JVO_MI_CLIENT_PRIN_COMMENTS varchar(256), 
JVO_MI_CLIENT_PRIN_SCORE varchar(256), 
JVO_OBSERVER_NAME varchar(256), 
JVO_OBSERVER_NAME_OTHER varchar(256), 
JVO_OTHER_OBSERVATIONS varchar(256), 
JVO_PARENT_CHILD_COMMENTS varchar(256), 
JVO_PARENT_CHILD_SCORE varchar(256), 
JVO_START_TIME varchar(256), 
JVO_THERAPEUTIC_CHAR_COMMENTS varchar(256), 
JVO_THERAPEUTIC_CHAR_SCORE varchar(256), 
JVO_VISIT_STRUCTURE_COMMENTS varchar(256), 
JVO_VISIT_STRUCTURE_SCORE varchar(256)
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
	max(case sq.pseudonym when 'JVO_ADDITIONAL_REASON ' then  secured_value else null end) as JVO_ADDITIONAL_REASON,
	max(case sq.pseudonym when 'JVO_CLIENT_CASE ' then  secured_value else null end) as JVO_CLIENT_CASE,
	max(case sq.pseudonym when 'JVO_CLIENT_NAME ' then  secured_value else null end) as JVO_CLIENT_NAME,
	max(case sq.pseudonym when 'JVO_CLINICAL_CHART_CONSISTENT ' then  secured_value else null end) as JVO_CLINICAL_CHART_CONSISTENT,
	max(case sq.pseudonym when 'JVO_CLINICAL_CHART_CONSISTENT_COMMENTS ' then  secured_value else null end) as JVO_CLINICAL_CHART_CONSISTENT_COMMENTS,
	max(case sq.pseudonym when 'JVO_HVEF_CONSISTENT ' then  secured_value else null end) as JVO_HVEF_CONSISTENT,
	max(case sq.pseudonym when 'JVO_HVEF_CONSISTENT_COMMENTS ' then  secured_value else null end) as JVO_HVEF_CONSISTENT_COMMENTS,
	max(case sq.pseudonym when 'JVO_MI_CLIENT_PRIN_COMMENTS ' then  secured_value else null end) as JVO_MI_CLIENT_PRIN_COMMENTS,
	max(case sq.pseudonym when 'JVO_MI_CLIENT_PRIN_SCORE ' then  secured_value else null end) as JVO_MI_CLIENT_PRIN_SCORE,
	max(case sq.pseudonym when 'JVO_OBSERVER_NAME ' then  secured_value else null end) as JVO_OBSERVER_NAME,
	max(case sq.pseudonym when 'JVO_OBSERVER_NAME_OTHER ' then  secured_value else null end) as JVO_OBSERVER_NAME_OTHER,
	max(case sq.pseudonym when 'JVO_OTHER_OBSERVATIONS ' then  secured_value else null end) as JVO_OTHER_OBSERVATIONS,
	max(case sq.pseudonym when 'JVO_PARENT_CHILD_COMMENTS ' then  secured_value else null end) as JVO_PARENT_CHILD_COMMENTS,
	max(case sq.pseudonym when 'JVO_PARENT_CHILD_SCORE ' then  secured_value else null end) as JVO_PARENT_CHILD_SCORE,
	max(case sq.pseudonym when 'JVO_START_TIME ' then  secured_value else null end) as JVO_START_TIME,
	max(case sq.pseudonym when 'JVO_THERAPEUTIC_CHAR_COMMENTS ' then  secured_value else null end) as JVO_THERAPEUTIC_CHAR_COMMENTS,
	max(case sq.pseudonym when 'JVO_THERAPEUTIC_CHAR_SCORE ' then  secured_value else null end) as JVO_THERAPEUTIC_CHAR_SCORE,
	max(case sq.pseudonym when 'JVO_VISIT_STRUCTURE_COMMENTS ' then  secured_value else null end) as JVO_VISIT_STRUCTURE_COMMENTS,
	max(case sq.pseudonym when 'JVO_VISIT_STRUCTURE_SCORE ' then  secured_value else null end) as JVO_VISIT_STRUCTURE_SCORE
  
   from survey_views.f_secure_fact_survey_response('Joint Visit Observation Form',@p_requested_security_policy,@p_export_profile_id) fr   
   
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
