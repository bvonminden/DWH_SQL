USE [dwh_test]
GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Edinburgh_Postnatal_Depression_Scale]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_Edinburgh_Postnatal_Depression_Scale]
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
CLIENT_EPDS_1_ABLE_TO_LAUGH varchar(256), 
CLIENT_EPDS_1_ANXIOUS_WORRIED varchar(256), 
CLIENT_EPDS_1_BEEN_CRYING varchar(256), 
CLIENT_EPDS_1_BLAME_SELF varchar(256), 
CLIENT_EPDS_1_DIFFICULTY_SLEEPING varchar(256), 
CLIENT_EPDS_1_ENJOY_THINGS varchar(256), 
CLIENT_EPDS_1_HARMING_SELF varchar(256), 
CLIENT_EPDS_1_SAD_MISERABLE varchar(256), 
CLIENT_EPDS_1_SCARED_PANICKY varchar(256), 
CLIENT_EPDS_1_THINGS_GETTING_ON_TOP varchar(256), 
CLIENT_EPS_TOTAL_SCORE varchar(256), 
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
	max(case sq.pseudonym when 'CLIENT_EPDS_1_ABLE_TO_LAUGH ' then  secured_value else null end) as CLIENT_EPDS_1_ABLE_TO_LAUGH,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_ANXIOUS_WORRIED ' then  secured_value else null end) as CLIENT_EPDS_1_ANXIOUS_WORRIED,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_BEEN_CRYING ' then  secured_value else null end) as CLIENT_EPDS_1_BEEN_CRYING,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_BLAME_SELF ' then  secured_value else null end) as CLIENT_EPDS_1_BLAME_SELF,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_DIFFICULTY_SLEEPING ' then  secured_value else null end) as CLIENT_EPDS_1_DIFFICULTY_SLEEPING,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_ENJOY_THINGS ' then  secured_value else null end) as CLIENT_EPDS_1_ENJOY_THINGS,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_HARMING_SELF ' then  secured_value else null end) as CLIENT_EPDS_1_HARMING_SELF,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_SAD_MISERABLE ' then  secured_value else null end) as CLIENT_EPDS_1_SAD_MISERABLE,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_SCARED_PANICKY ' then  secured_value else null end) as CLIENT_EPDS_1_SCARED_PANICKY,
	max(case sq.pseudonym when 'CLIENT_EPDS_1_THINGS_GETTING_ON_TOP ' then  secured_value else null end) as CLIENT_EPDS_1_THINGS_GETTING_ON_TOP,
	max(case sq.pseudonym when 'CLIENT_EPS_TOTAL_SCORE ' then  secured_value else null end) as CLIENT_EPS_TOTAL_SCORE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_DOB_INTAKE ' then  secured_value else null end) as CLIENT_PERSONAL_0_DOB_INTAKE,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST ' then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME ' then  secured_value else null end) as NURSE_PERSONAL_0_NAME

   from survey_views.f_secure_fact_survey_response('Edinburgh Postnatal Depression Scale',@p_requested_security_policy,@p_export_profile_id) fr   
   
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
