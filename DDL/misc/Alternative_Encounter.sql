create procedure [survey_views].usp_etl_select_Alternative_Encounter  
(
 @p_export_profile_id int,
  @p_entity_filter char(5)=null
)
as
begin

declare  @_hash_profile   char(10);
set   @_hash_profile   = (select top 1 isnull('SA',hash_policy) from survey_views.f_get_survey_etl_work() where ExportProfileID=@p_export_profile_id);

--print  @p_export_profile_id;
--print  @_hash_profile;


select 

vbase. SurveyResponseID,
vbase.ElementsProcessed,
vbase.SurveyID,
vbase.SurveyDate,
vbase.AuditDate,
vbase.CL_EN_GEN_ID,
vbase.SiteID,
vbase.ProgramID,
vbase.IA_StaffID,
vbase.ClientID,
vbase.RespondentID,
vbase.CLIENT_0_ID_NSO,
vbase.CLIENT_PERSONAL_0_NAME_FIRST,
vbase.CLIENT_PERSONAL_0_NAME_LAST,
vbase.CLIENT_PERSONAL_0_DOB_INTAKE,
vbase.CLIENT_TIME_0_START_ALT,
vbase.CLIENT_TIME_1_END_ALT,
vbase.NURSE_PERSONAL_0_NAME,
vbase.CLIENT_TALKED_0_WITH_ALT,
vbase.CLIENT_TALKED_1_WITH_OTHER_ALT,
vbase.CLIENT_ALTERNATIVE_ENCOUNTER_0_TYPE_ALT,
vbase.CLIENT_ALTERNATIVE_ENCOUNTER_1_TYPE_OTHER_ALT,
vbase.CLIENT_DOMAIN_0_PERSONAL_HLTH_ALT,
vbase.CLIENT_DOMAIN_0_ENVIRONHLTH_ALT,
vbase.CLIENT_DOMAIN_0_LIFECOURSE_ALT,
vbase.CLIENT_DOMAIN_0_MATERNAL_ALT,
vbase.CLIENT_DOMAIN_0_FRNDFAM_ALT,
vbase.CLIENT_DOMAIN_0_TOTAL_ALT,
vbase.CLIENT_ALT_0_COMMENTS_ALT,
vbase.CLIENT_TIME_1_DURATION_ALT,
vbase.CLIENT_0_ID_AGENCY,
--vbase.DW_AuditDate,
vbase.DataSource,
vbase.CLIENT_NO_REFERRAL,
vbase.CLIENT_SCREENED_SRVCS,
--vbase.CLIENT_VISIT_SCHEDULE,
--vbase.Master_SurveyID,
vbase.CLIENT_TIME_FROM_AMPM_ALT,
vbase.CLIENT_TIME_FROM_HR_ALT,
vbase.CLIENT_TIME_FROM_MIN_ALT,
vbase.CLIENT_TIME_TO_AMPM_ALT,
vbase.CLIENT_TIME_TO_HR_ALT,
vbase.CLIENT_TIME_TO_MIN_ALT

from survey_views.f_select_Alternative_Encounter(@_hash_profile,@p_export_profile_id) vbase
where
vbase.CL_EN_GEN_ID in (select * from survey_views.f_list_client_inclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))
and
vbase.CL_EN_GEN_ID not in (select * from survey_views.f_list_client_exclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))

 
end;


