USE [dwh_test]
GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_NFP_Los_Angeles_Outreach_Marketing]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_NFP_Los_Angeles_Outreach_Marketing]
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
LA_CTY_CONTACT_NAME_OUTREACH varchar(256), 
LA_CTY_CONTACT_PHONE_OUTREACH varchar(256), 
LA_CTY_NOTES_OUTREACH varchar(256), 
LA_CTY_ORG_NAME_OUTREACH varchar(256), 
LA_CTY_ORG_TYPE_OTH_OUTREACH varchar(256), 
LA_CTY_ORG_TYPE_OUTREACH varchar(256), 
LA_CTY_STAFF_OUTREACH varchar(256), 
LA_CTY_STAFF2_OUTREACH varchar(256), 
LA_CTY_STAFF3_OUTREACH varchar(256), 
LA_CTY_STAFF4_OUTREACH varchar(256), 
LA_CTY_STAFF5_OUTREACH varchar(256), 
LA_CTY_TARGET_POP_OUTREACH varchar(256)
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
	max(case sq.pseudonym when 'LA_CTY_CONTACT_NAME_OUTREACH ' then  secured_value else null end) as LA_CTY_CONTACT_NAME_OUTREACH,
	max(case sq.pseudonym when 'LA_CTY_CONTACT_PHONE_OUTREACH ' then  secured_value else null end) as LA_CTY_CONTACT_PHONE_OUTREACH,
	max(case sq.pseudonym when 'LA_CTY_NOTES_OUTREACH ' then  secured_value else null end) as LA_CTY_NOTES_OUTREACH,
	max(case sq.pseudonym when 'LA_CTY_ORG_NAME_OUTREACH ' then  secured_value else null end) as LA_CTY_ORG_NAME_OUTREACH,
	max(case sq.pseudonym when 'LA_CTY_ORG_TYPE_OTH_OUTREACH ' then  secured_value else null end) as LA_CTY_ORG_TYPE_OTH_OUTREACH,
	max(case sq.pseudonym when 'LA_CTY_ORG_TYPE_OUTREACH ' then  secured_value else null end) as LA_CTY_ORG_TYPE_OUTREACH,
	max(case sq.pseudonym when 'LA_CTY_STAFF_OUTREACH ' then  secured_value else null end) as LA_CTY_STAFF_OUTREACH,
	max(case sq.pseudonym when 'LA_CTY_STAFF2_OUTREACH ' then  secured_value else null end) as LA_CTY_STAFF2_OUTREACH,
	max(case sq.pseudonym when 'LA_CTY_STAFF3_OUTREACH ' then  secured_value else null end) as LA_CTY_STAFF3_OUTREACH,
	max(case sq.pseudonym when 'LA_CTY_STAFF4_OUTREACH ' then  secured_value else null end) as LA_CTY_STAFF4_OUTREACH,
	max(case sq.pseudonym when 'LA_CTY_STAFF5_OUTREACH ' then  secured_value else null end) as LA_CTY_STAFF5_OUTREACH,
	max(case sq.pseudonym when 'LA_CTY_TARGET_POP_OUTREACH ' then  secured_value else null end) as LA_CTY_TARGET_POP_OUTREACH


    from survey_views.f_secure_fact_survey_response('NFP Los Angeles - Outreach/Marketing',@p_requested_security_policy,@p_export_profile_id) fr
   
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
