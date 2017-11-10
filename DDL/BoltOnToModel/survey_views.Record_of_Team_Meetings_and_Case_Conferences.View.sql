DROP VIEW [survey_views].[Record_of_Team_Meetings_and_Case_Conferences]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view  [survey_views].[Record_of_Team_Meetings_and_Case_Conferences] as
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
max(case sq.pseudonym when 'AGENCY_MEETING_0_TYPE ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_0_TYPE,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE1,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE10 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE10,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE2,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE3,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE4 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE4,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE5 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE5,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE6 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE6,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE7 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE7,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE8 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE8,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE9 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE9,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF1,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF10 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF10,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF2,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF3,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF4 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF4,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF5 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF5,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF6 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF6,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF7 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF7,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF8 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF8,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_NONSTAFF9 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_NONSTAFF9,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF1 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF1,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF10 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF10,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF11 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF11,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF12 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF12,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF13 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF13,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF14 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF14,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF15 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF15,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF16 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF16,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF17 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF17,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF18 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF18,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF19 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF19,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF2 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF2,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF20 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF20,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF21 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF21,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF22 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF22,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF23 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF23,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF24 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF24,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF25 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF25,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF3 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF3,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF4 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF4,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF5 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF5,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF6 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF6,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF7 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF7,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF8 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF8,
max(case sq.pseudonym when 'AGENCY_MEETING_1_ATTENDEES_STAFF9 ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_ATTENDEES_STAFF9,
max(case sq.pseudonym when 'AGENCY_MEETING_1_LENGTH ' then coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)) else null end) as AGENCY_MEETING_1_LENGTH

   from fact_survey_response fr  
   
    inner join dim_survey_question      sq on fr.survey_question_key          = sq.survey_question_key
    inner join  dim_date                dk on fr.survey_date_key              = dk.date_key
    inner join  xref_organization       xo on fr.organization_key             = xo.organization_key
    inner join  xref_program            xp on xo.programid                    = xp.programid
    inner join  dim_client              dc on dc.client_key                   = fr.client_key
    left  join  dim_nurse               dn on dn.nurse_key                    = fr.nurse_key -- all fsr have nurse id's?
  
  where 
    sq.survey_name = 'Record of Team Meetings and Case Conferences'
  
  group by 
  
    fr.survey_response_id,
    sq.master_survey_id, 
    dk.date_actual,     
    xp.source_auditdate,
    dc.client_key,
    xp.site_id,  
    xp.programid,
    dn.nurse_id,
    dc.client_id
GO
