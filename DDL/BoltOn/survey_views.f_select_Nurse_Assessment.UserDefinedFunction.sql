USE [dwh_test]
GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_Nurse_Assessment]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create FUNCTION [survey_views].[f_select_Nurse_Assessment]
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
[NURSE_ASSESS_ DATA_0_USES] varchar(256), 
[NURSE_ASSESS_ DATA_1_USES_CMT] varchar(256), 
NURSE_ASSESS_6DOMAINS_0_UTILIZES varchar(256), 
NURSE_ASSESS_6DOMAINS_1_UTILIZES_CMT varchar(256), 
NURSE_ASSESS_ADAPTS_PRACTICE_0_TO_CULTURE varchar(256), 
NURSE_ASSESS_ADAPTS_PRACTICE_0_TO_CULTURE_CMT varchar(256), 
NURSE_ASSESS_BOUNDARIES_0_THERAPEUTIC varchar(256), 
NURSE_ASSESS_BOUNDARIES_0_THERAPEUTIC_CMT varchar(256), 
NURSE_ASSESS_CARE_0_SELF varchar(256), 
NURSE_ASSESS_CARE_0_SELF_CMT varchar(256), 
NURSE_ASSESS_COMMUNITY_0_RELATIONSHIPS_PARTNERS varchar(256), 
NURSE_ASSESS_COMMUNITY_0_RELATIONSHIPS_PARTNERS_CMT varchar(256), 
NURSE_ASSESS_CONTRIBUTES_0_TO_TEAM varchar(256), 
NURSE_ASSESS_CONTRIBUTES_0_TO_TEAM_CMT varchar(256), 
NURSE_ASSESS_CULTURE_0_IMPACT varchar(256), 
NURSE_ASSESS_CULTURE_0_IMPACT_CMT varchar(256), 
NURSE_ASSESS_DOCUMENTATION_0_TIMELY varchar(256), 
NURSE_ASSESS_DOCUMENTATION_0_TIMELY_CMT varchar(256), 
NURSE_ASSESS_FIDELITY_0_PRACTICES varchar(256), 
NURSE_ASSESS_FIDELITY_0_PRACTICES_CMT varchar(256), 
NURSE_ASSESS_GOALS_0_SETTING_ACHIEVING varchar(256), 
NURSE_ASSESS_GOALS_0_SETTING_ACHIEVING_CMT varchar(256), 
NURSE_ASSESS_GUIDELINES_0_ADAPTS varchar(256), 
NURSE_ASSESS_GUIDELINES_0_ADAPTS_CMT varchar(256), 
NURSE_ASSESS_MOTIVATIONAL_0_INTERVIEW_TECHNIQUES varchar(256), 
NURSE_ASSESS_MOTIVATIONAL_0_INTERVIEW_TECHNIQUES_CMT varchar(256), 
NURSE_ASSESS_PRIORITIES_0_EST_MNG_TIME varchar(256), 
NURSE_ASSESS_PRIORITIES_0_EST_MNG_TIME_CMT varchar(256), 
NURSE_ASSESS_QUALITIES_0_THERAPEUTIC varchar(256), 
NURSE_ASSESS_QUALITIES_0_THERAPEUTIC_CMT varchar(256), 
NURSE_ASSESS_REFLECTION_0_SELF varchar(256), 
NURSE_ASSESS_REFLECTION_0_SELF_CMT varchar(256), 
NURSE_ASSESS_REGULAR_0_SUPERVISION varchar(256), 
NURSE_ASSESS_REGULAR_0_SUPERVISION_CMT varchar(256), 
NURSE_ASSESS_RELATIONSHIPS_0_THERAPEUTIC varchar(256), 
NURSE_ASSESS_RELATIONSHIPS_0_THERAPEUTIC_CMT varchar(256), 
NURSE_ASSESS_RESOURCES_0_IDENTIFY_UTILIZE varchar(256), 
NURSE_ASSESS_RESOURCES_0_IDENTIFY_UTILIZE_CMT varchar(256), 
NURSE_ASSESS_SELF_ADVOCACY_0_BUILD varchar(256), 
NURSE_ASSESS_SELF_ADVOCACY_0_BUILD_CMT varchar(256), 
NURSE_ASSESS_THEORIES_0_PRINCIPLES varchar(256), 
NURSE_ASSESS_THEORIES_0_PRINCIPLES_CMT varchar(256), 
NURSE_ASSESS_UNDERSTAND_0_GOALS varchar(256), 
NURSE_ASSESS_UNDERSTAND_0_GOALS_CMT varchar(256)

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
	max(case sq.pseudonym when 'NURSE_ASSESS_ DATA_0_USES ' then  secured_value else null end) as [NURSE_ASSESS_ DATA_0_USES],
	max(case sq.pseudonym when 'NURSE_ASSESS_ DATA_1_USES_CMT ' then  secured_value else null end) as [NURSE_ASSESS_ DATA_1_USES_CMT],
	max(case sq.pseudonym when 'NURSE_ASSESS_6DOMAINS_0_UTILIZES ' then  secured_value else null end) as NURSE_ASSESS_6DOMAINS_0_UTILIZES,
	max(case sq.pseudonym when 'NURSE_ASSESS_6DOMAINS_1_UTILIZES_CMT ' then  secured_value else null end) as NURSE_ASSESS_6DOMAINS_1_UTILIZES_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_ADAPTS_PRACTICE_0_TO_CULTURE ' then  secured_value else null end) as NURSE_ASSESS_ADAPTS_PRACTICE_0_TO_CULTURE,
	max(case sq.pseudonym when 'NURSE_ASSESS_ADAPTS_PRACTICE_0_TO_CULTURE_CMT ' then  secured_value else null end) as NURSE_ASSESS_ADAPTS_PRACTICE_0_TO_CULTURE_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_BOUNDARIES_0_THERAPEUTIC ' then  secured_value else null end) as NURSE_ASSESS_BOUNDARIES_0_THERAPEUTIC,
	max(case sq.pseudonym when 'NURSE_ASSESS_BOUNDARIES_0_THERAPEUTIC_CMT ' then  secured_value else null end) as NURSE_ASSESS_BOUNDARIES_0_THERAPEUTIC_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_CARE_0_SELF ' then  secured_value else null end) as NURSE_ASSESS_CARE_0_SELF,
	max(case sq.pseudonym when 'NURSE_ASSESS_CARE_0_SELF_CMT ' then  secured_value else null end) as NURSE_ASSESS_CARE_0_SELF_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_COMMUNITY_0_RELATIONSHIPS_PARTNERS ' then  secured_value else null end) as NURSE_ASSESS_COMMUNITY_0_RELATIONSHIPS_PARTNERS,
	max(case sq.pseudonym when 'NURSE_ASSESS_COMMUNITY_0_RELATIONSHIPS_PARTNERS_CMT ' then  secured_value else null end) as NURSE_ASSESS_COMMUNITY_0_RELATIONSHIPS_PARTNERS_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_CONTRIBUTES_0_TO_TEAM ' then  secured_value else null end) as NURSE_ASSESS_CONTRIBUTES_0_TO_TEAM,
	max(case sq.pseudonym when 'NURSE_ASSESS_CONTRIBUTES_0_TO_TEAM_CMT ' then  secured_value else null end) as NURSE_ASSESS_CONTRIBUTES_0_TO_TEAM_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_CULTURE_0_IMPACT ' then  secured_value else null end) as NURSE_ASSESS_CULTURE_0_IMPACT,
	max(case sq.pseudonym when 'NURSE_ASSESS_CULTURE_0_IMPACT_CMT ' then  secured_value else null end) as NURSE_ASSESS_CULTURE_0_IMPACT_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_DOCUMENTATION_0_TIMELY ' then  secured_value else null end) as NURSE_ASSESS_DOCUMENTATION_0_TIMELY,
	max(case sq.pseudonym when 'NURSE_ASSESS_DOCUMENTATION_0_TIMELY_CMT ' then  secured_value else null end) as NURSE_ASSESS_DOCUMENTATION_0_TIMELY_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_FIDELITY_0_PRACTICES ' then  secured_value else null end) as NURSE_ASSESS_FIDELITY_0_PRACTICES,
	max(case sq.pseudonym when 'NURSE_ASSESS_FIDELITY_0_PRACTICES_CMT ' then  secured_value else null end) as NURSE_ASSESS_FIDELITY_0_PRACTICES_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_GOALS_0_SETTING_ACHIEVING ' then  secured_value else null end) as NURSE_ASSESS_GOALS_0_SETTING_ACHIEVING,
	max(case sq.pseudonym when 'NURSE_ASSESS_GOALS_0_SETTING_ACHIEVING_CMT ' then  secured_value else null end) as NURSE_ASSESS_GOALS_0_SETTING_ACHIEVING_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_GUIDELINES_0_ADAPTS ' then  secured_value else null end) as NURSE_ASSESS_GUIDELINES_0_ADAPTS,
	max(case sq.pseudonym when 'NURSE_ASSESS_GUIDELINES_0_ADAPTS_CMT ' then  secured_value else null end) as NURSE_ASSESS_GUIDELINES_0_ADAPTS_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_MOTIVATIONAL_0_INTERVIEW_TECHNIQUES ' then  secured_value else null end) as NURSE_ASSESS_MOTIVATIONAL_0_INTERVIEW_TECHNIQUES,
	max(case sq.pseudonym when 'NURSE_ASSESS_MOTIVATIONAL_0_INTERVIEW_TECHNIQUES_CMT ' then  secured_value else null end) as NURSE_ASSESS_MOTIVATIONAL_0_INTERVIEW_TECHNIQUES_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_PRIORITIES_0_EST_MNG_TIME ' then  secured_value else null end) as NURSE_ASSESS_PRIORITIES_0_EST_MNG_TIME,
	max(case sq.pseudonym when 'NURSE_ASSESS_PRIORITIES_0_EST_MNG_TIME_CMT ' then  secured_value else null end) as NURSE_ASSESS_PRIORITIES_0_EST_MNG_TIME_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_QUALITIES_0_THERAPEUTIC ' then  secured_value else null end) as NURSE_ASSESS_QUALITIES_0_THERAPEUTIC,
	max(case sq.pseudonym when 'NURSE_ASSESS_QUALITIES_0_THERAPEUTIC_CMT ' then  secured_value else null end) as NURSE_ASSESS_QUALITIES_0_THERAPEUTIC_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_REFLECTION_0_SELF ' then  secured_value else null end) as NURSE_ASSESS_REFLECTION_0_SELF,
	max(case sq.pseudonym when 'NURSE_ASSESS_REFLECTION_0_SELF_CMT ' then  secured_value else null end) as NURSE_ASSESS_REFLECTION_0_SELF_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_REGULAR_0_SUPERVISION ' then  secured_value else null end) as NURSE_ASSESS_REGULAR_0_SUPERVISION,
	max(case sq.pseudonym when 'NURSE_ASSESS_REGULAR_0_SUPERVISION_CMT ' then  secured_value else null end) as NURSE_ASSESS_REGULAR_0_SUPERVISION_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_RELATIONSHIPS_0_THERAPEUTIC ' then  secured_value else null end) as NURSE_ASSESS_RELATIONSHIPS_0_THERAPEUTIC,
	max(case sq.pseudonym when 'NURSE_ASSESS_RELATIONSHIPS_0_THERAPEUTIC_CMT ' then  secured_value else null end) as NURSE_ASSESS_RELATIONSHIPS_0_THERAPEUTIC_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_RESOURCES_0_IDENTIFY_UTILIZE ' then  secured_value else null end) as NURSE_ASSESS_RESOURCES_0_IDENTIFY_UTILIZE,
	max(case sq.pseudonym when 'NURSE_ASSESS_RESOURCES_0_IDENTIFY_UTILIZE_CMT ' then  secured_value else null end) as NURSE_ASSESS_RESOURCES_0_IDENTIFY_UTILIZE_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_SELF_ADVOCACY_0_BUILD ' then  secured_value else null end) as NURSE_ASSESS_SELF_ADVOCACY_0_BUILD,
	max(case sq.pseudonym when 'NURSE_ASSESS_SELF_ADVOCACY_0_BUILD_CMT ' then  secured_value else null end) as NURSE_ASSESS_SELF_ADVOCACY_0_BUILD_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_THEORIES_0_PRINCIPLES ' then  secured_value else null end) as NURSE_ASSESS_THEORIES_0_PRINCIPLES,
	max(case sq.pseudonym when 'NURSE_ASSESS_THEORIES_0_PRINCIPLES_CMT ' then  secured_value else null end) as NURSE_ASSESS_THEORIES_0_PRINCIPLES_CMT,
	max(case sq.pseudonym when 'NURSE_ASSESS_UNDERSTAND_0_GOALS ' then  secured_value else null end) as NURSE_ASSESS_UNDERSTAND_0_GOALS,
	max(case sq.pseudonym when 'NURSE_ASSESS_UNDERSTAND_0_GOALS_CMT ' then  secured_value else null end) as NURSE_ASSESS_UNDERSTAND_0_GOALS_CMT
   
   from survey_views.f_secure_fact_survey_response('Nurse Assessment',@p_requested_security_policy,@p_export_profile_id) fr  
   
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
