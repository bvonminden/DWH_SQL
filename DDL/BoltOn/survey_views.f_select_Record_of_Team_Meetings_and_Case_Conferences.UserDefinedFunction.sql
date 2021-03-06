USE [dwh_test]
GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Record_of_Team_Meetings_and_Case_Conferences]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [survey_views].[f_select_Record_of_Team_Meetings_and_Case_Conferences]
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
AGENCY_MEETING_0_TYPE varchar(256), 
AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE1 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE10 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE2 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE3 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE4 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE5 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE6 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE7 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE8 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE9 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_NONSTAFF1 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_NONSTAFF10 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_NONSTAFF2 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_NONSTAFF3 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_NONSTAFF4 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_NONSTAFF5 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_NONSTAFF6 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_NONSTAFF7 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_NONSTAFF8 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_NONSTAFF9 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_STAFF1 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_STAFF10 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_STAFF11 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_STAFF12 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_STAFF13 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_STAFF14 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_STAFF15 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_STAFF16 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_STAFF17 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_STAFF18 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_STAFF19 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_STAFF2 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_STAFF20 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_STAFF21 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_STAFF22 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_STAFF23 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_STAFF24 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_STAFF25 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_STAFF3 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_STAFF4 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_STAFF5 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_STAFF6 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_STAFF7 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_STAFF8 varchar(256), 
AGENCY_MEETING_1_ATTENDEES_STAFF9 varchar(256), 
AGENCY_MEETING_1_LENGTH varchar(256)

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
	max(case sq.pseudonym when 'AGENCY_MEETING_0_TYPE ' then  secured_value else null end) as AGENCY_MEETING_0_TYPE,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE1 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE1,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE10 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE10,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE2 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE2,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE3 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE3,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE4 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE4,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE5 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE5,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE6 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE6,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE7 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE7,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE8 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE8,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE9 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE9,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF1 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF1,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF10 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF10,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF2 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF2,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF3 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF3,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF4 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF4,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF5 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF5,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF6 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF6,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF7 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF7,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF8 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF8,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF9 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF9,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF1 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF1,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF10 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF10,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF11 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF11,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF12 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF12,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF13 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF13,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF14 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF14,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF15 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF15,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF16 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF16,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF17 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF17,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF18 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF18,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF19 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF19,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF2 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF2,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF20 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF20,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF21 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF21,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF22 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF22,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF23 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF23,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF24 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF24,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF25 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF25,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF3 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF3,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF4 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF4,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF5 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF5,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF6 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF6,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF7 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF7,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF8 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF8,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF9 ' then  secured_value else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF9,
	max(case sq.pseudonym when 'AGENCY_MEETING_1_LENGTH ' then  secured_value else null end) as AGENCY_MEETING_1_LENGTH

   from survey_views.f_secure_fact_survey_response('Record of Team Meetings and Case Conferences',@p_requested_security_policy,@p_export_profile_id) fr  
   
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
