USE [dwh_test]
GO
/****** Object:  UserDefinedFunction [survey_views].[f_select_DANCE_Coding_Sheet]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [survey_views].[f_select_DANCE_Coding_Sheet]
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
CLIENT_ACTIVITY_DURATION varchar(256), 
CLIENT_CAC_COMMENTS varchar(256), 
CLIENT_CAC_NA varchar(256), 
CLIENT_CAC_PER varchar(256), 
CLIENT_CHILD_AGE varchar(256), 
CLIENT_CHILD_DURATION varchar(256), 
CLIENT_CI_COMMENTS varchar(256), 
CLIENT_CI_NA varchar(256), 
CLIENT_CI_PER varchar(256), 
CLIENT_EPA_COMMENTS varchar(256), 
CLIENT_EPA_NA varchar(256), 
CLIENT_EPA_PER varchar(256), 
CLIENT_LS_COMMENTS varchar(256), 
CLIENT_LS_NA varchar(256), 
CLIENT_LS_PER varchar(256), 
CLIENT_NCCO_COMMENTS varchar(256), 
CLIENT_NCCO_NA varchar(256), 
CLIENT_NCCO_PER varchar(256), 
CLIENT_NI_COMMENTS varchar(256), 
CLIENT_NI_NA varchar(256), 
CLIENT_NI_PER varchar(256), 
CLIENT_NT_COMMENTS varchar(256), 
CLIENT_NT_NA varchar(256), 
CLIENT_NT_PER varchar(256), 
CLIENT_NVC_COMMENTS varchar(256), 
CLIENT_NVC_NA varchar(256), 
CLIENT_NVC_PER varchar(256), 
CLIENT_PC_COMMENTS varchar(256), 
CLIENT_PC_NA varchar(256), 
CLIENT_PC_PER varchar(256), 
CLIENT_PERSONAL_0_NAME_FIRST varchar(256), 
CLIENT_PERSONAL_0_NAME_LAST varchar(256), 
CLIENT_PO_COMMENTS varchar(256), 
CLIENT_PO_NA varchar(256), 
CLIENT_PO_PER varchar(256), 
CLIENT_PRA_COMMENTS varchar(256), 
CLIENT_PRA_NA varchar(256), 
CLIENT_PRA_PER varchar(256), 
CLIENT_RD_COMMENTS varchar(256), 
CLIENT_RD_NA varchar(256), 
CLIENT_RD_PER varchar(256), 
CLIENT_RP_COMMENTS varchar(256), 
CLIENT_RP_NA varchar(256), 
CLIENT_RP_PER varchar(256), 
CLIENT_SCA_COMMENTS varchar(256), 
CLIENT_SCA_NA varchar(256), 
CLIENT_SCA_PER varchar(256), 
CLIENT_SE_COMMENTS varchar(256), 
CLIENT_SE_NA varchar(256), 
CLIENT_SE_PER varchar(256), 
CLIENT_VE_COMMENTS varchar(256), 
CLIENT_VE_NA varchar(256), 
CLIENT_VE_PER varchar(256), 
CLIENT_VEC_COMMENTS varchar(256), 
CLIENT_VEC_NA varchar(256), 
CLIENT_VEC_PER varchar(256), 
CLIENT_VISIT_VARIABLES varchar(256), 
CLIENT_VQ_COMMENTS varchar(256), 
CLIENT_VQ_NA varchar(256), 
CLIENT_VQ_PER varchar(256), 
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
	max(case sq.pseudonym when 'CLIENT_ACTIVITY_DURATION '  then  secured_value else null end) as CLIENT_ACTIVITY_DURATION,
	max(case sq.pseudonym when 'CLIENT_CAC_COMMENTS '  then  secured_value else null end) as CLIENT_CAC_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_CAC_NA '  then  secured_value else null end) as CLIENT_CAC_NA,
	max(case sq.pseudonym when 'CLIENT_CAC_PER '  then  secured_value else null end) as CLIENT_CAC_PER,
	max(case sq.pseudonym when 'CLIENT_CHILD_AGE '  then  secured_value else null end) as CLIENT_CHILD_AGE,
	max(case sq.pseudonym when 'CLIENT_CHILD_DURATION '  then  secured_value else null end) as CLIENT_CHILD_DURATION,
	max(case sq.pseudonym when 'CLIENT_CI_COMMENTS '  then  secured_value else null end) as CLIENT_CI_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_CI_NA '  then  secured_value else null end) as CLIENT_CI_NA,
	max(case sq.pseudonym when 'CLIENT_CI_PER '  then  secured_value else null end) as CLIENT_CI_PER,
	max(case sq.pseudonym when 'CLIENT_EPA_COMMENTS '  then  secured_value else null end) as CLIENT_EPA_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_EPA_NA '  then  secured_value else null end) as CLIENT_EPA_NA,
	max(case sq.pseudonym when 'CLIENT_EPA_PER '  then  secured_value else null end) as CLIENT_EPA_PER,
	max(case sq.pseudonym when 'CLIENT_LS_COMMENTS '  then  secured_value else null end) as CLIENT_LS_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_LS_NA '  then  secured_value else null end) as CLIENT_LS_NA,
	max(case sq.pseudonym when 'CLIENT_LS_PER '  then  secured_value else null end) as CLIENT_LS_PER,
	max(case sq.pseudonym when 'CLIENT_NCCO_COMMENTS '  then  secured_value else null end) as CLIENT_NCCO_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_NCCO_NA '  then  secured_value else null end) as CLIENT_NCCO_NA,
	max(case sq.pseudonym when 'CLIENT_NCCO_PER '  then  secured_value else null end) as CLIENT_NCCO_PER,
	max(case sq.pseudonym when 'CLIENT_NI_COMMENTS '  then  secured_value else null end) as CLIENT_NI_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_NI_NA '  then  secured_value else null end) as CLIENT_NI_NA,
	max(case sq.pseudonym when 'CLIENT_NI_PER '  then  secured_value else null end) as CLIENT_NI_PER,
	max(case sq.pseudonym when 'CLIENT_NT_COMMENTS '  then  secured_value else null end) as CLIENT_NT_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_NT_NA '  then  secured_value else null end) as CLIENT_NT_NA,
	max(case sq.pseudonym when 'CLIENT_NT_PER '  then  secured_value else null end) as CLIENT_NT_PER,
	max(case sq.pseudonym when 'CLIENT_NVC_COMMENTS '  then  secured_value else null end) as CLIENT_NVC_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_NVC_NA '  then  secured_value else null end) as CLIENT_NVC_NA,
	max(case sq.pseudonym when 'CLIENT_NVC_PER '  then  secured_value else null end) as CLIENT_NVC_PER,
	max(case sq.pseudonym when 'CLIENT_PC_COMMENTS '  then  secured_value else null end) as CLIENT_PC_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_PC_NA '  then  secured_value else null end) as CLIENT_PC_NA,
	max(case sq.pseudonym when 'CLIENT_PC_PER '  then  secured_value else null end) as CLIENT_PC_PER,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_FIRST '  then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_FIRST,
	max(case sq.pseudonym when 'CLIENT_PERSONAL_0_NAME_LAST '  then  secured_value else null end) as CLIENT_PERSONAL_0_NAME_LAST,
	max(case sq.pseudonym when 'CLIENT_PO_COMMENTS '  then  secured_value else null end) as CLIENT_PO_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_PO_NA '  then  secured_value else null end) as CLIENT_PO_NA,
	max(case sq.pseudonym when 'CLIENT_PO_PER '  then  secured_value else null end) as CLIENT_PO_PER,
	max(case sq.pseudonym when 'CLIENT_PRA_COMMENTS '  then  secured_value else null end) as CLIENT_PRA_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_PRA_NA '  then  secured_value else null end) as CLIENT_PRA_NA,
	max(case sq.pseudonym when 'CLIENT_PRA_PER '  then  secured_value else null end) as CLIENT_PRA_PER,
	max(case sq.pseudonym when 'CLIENT_RD_COMMENTS '  then  secured_value else null end) as CLIENT_RD_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_RD_NA '  then  secured_value else null end) as CLIENT_RD_NA,
	max(case sq.pseudonym when 'CLIENT_RD_PER '  then  secured_value else null end) as CLIENT_RD_PER,
	max(case sq.pseudonym when 'CLIENT_RP_COMMENTS '  then  secured_value else null end) as CLIENT_RP_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_RP_NA '  then  secured_value else null end) as CLIENT_RP_NA,
	max(case sq.pseudonym when 'CLIENT_RP_PER '  then  secured_value else null end) as CLIENT_RP_PER,
	max(case sq.pseudonym when 'CLIENT_SCA_COMMENTS '  then  secured_value else null end) as CLIENT_SCA_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_SCA_NA '  then  secured_value else null end) as CLIENT_SCA_NA,
	max(case sq.pseudonym when 'CLIENT_SCA_PER '  then  secured_value else null end) as CLIENT_SCA_PER,
	max(case sq.pseudonym when 'CLIENT_SE_COMMENTS '  then  secured_value else null end) as CLIENT_SE_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_SE_NA '  then  secured_value else null end) as CLIENT_SE_NA,
	max(case sq.pseudonym when 'CLIENT_SE_PER '  then  secured_value else null end) as CLIENT_SE_PER,
	max(case sq.pseudonym when 'CLIENT_VE_COMMENTS '  then  secured_value else null end) as CLIENT_VE_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_VE_NA '  then  secured_value else null end) as CLIENT_VE_NA,
	max(case sq.pseudonym when 'CLIENT_VE_PER '  then  secured_value else null end) as CLIENT_VE_PER,
	max(case sq.pseudonym when 'CLIENT_VEC_COMMENTS '  then  secured_value else null end) as CLIENT_VEC_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_VEC_NA '  then  secured_value else null end) as CLIENT_VEC_NA,
	max(case sq.pseudonym when 'CLIENT_VEC_PER '  then  secured_value else null end) as CLIENT_VEC_PER,
	max(case sq.pseudonym when 'CLIENT_VISIT_VARIABLES '  then  secured_value else null end) as CLIENT_VISIT_VARIABLES,
	max(case sq.pseudonym when 'CLIENT_VQ_COMMENTS '  then  secured_value else null end) as CLIENT_VQ_COMMENTS,
	max(case sq.pseudonym when 'CLIENT_VQ_NA '  then  secured_value else null end) as CLIENT_VQ_NA,
	max(case sq.pseudonym when 'CLIENT_VQ_PER '  then  secured_value else null end) as CLIENT_VQ_PER,
	max(case sq.pseudonym when 'NURSE_PERSONAL_0_NAME '  then  secured_value else null end) as NURSE_PERSONAL_0_NAME

   from survey_views.f_secure_fact_survey_response('DANCE Coding Sheet',@p_requested_security_policy,@p_export_profile_id) fr  
   
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

RETURN;

end



GO
