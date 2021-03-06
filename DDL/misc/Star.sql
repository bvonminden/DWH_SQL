create procedure [survey_views].usp_etl_select_ Star  
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
vbase.Master_SurveyID,
vbase.SurveyDate,
vbase.AuditDate,
vbase.CL_EN_GEN_ID,
vbase.SiteID,
vbase.ProgramID,
vbase.IA_StaffID,
vbase.ClientID,
vbase.RespondentID,
vbase.DW_AuditDate,
vbase.DataSource,
vbase.CLIENT_GLOBAL_FACTORS,
vbase.CLIENT_CAREGIVING_FRIENDS_FAM,
vbase.CLIENT_CAREGIVING_RISK_LEVEL,
vbase.CLIENT_CAREGIVING_SERVICES_GOALS,
vbase.CLIENT_CAREGIVING_STAGE_CHANGE,
vbase.CLIENT_CAREGIVING_UNDERSTANDS_RISK,
vbase.CLIENT_CHLD_CARE_FRIENDS_FAM,
vbase.CLIENT_CHLD_CARE_RISK_LEVEL,
vbase.CLIENT_CHLD_CARE_SERVICES_GOALS,
vbase.CLIENT_CHLD_CARE_STAGE_CHANGE,
vbase.CLIENT_CHLD_CARE_UNDERSTANDS_RISK,
vbase.CLIENT_CHLD_HEALTH_FRIENDS_FAM,
vbase.CLIENT_CHLD_HEALTH_RISK_LEVEL,
vbase.CLIENT_CHLD_HEALTH_SERVICES_GOALS,
vbase.CLIENT_CHLD_HEALTH_STAGE_CHANGE,
vbase.CLIENT_CHLD_HEALTH_UNDERSTANDS_RISK,
vbase.CLIENT_CHLD_WELL_FRIENDS_FAM,
vbase.CLIENT_CHLD_WELL_RISK_LEVEL,
vbase.CLIENT_CHLD_WELL_SERVICES_GOALS,
vbase.CLIENT_CHLD_WELL_STAGE_CHANGE,
vbase.CLIENT_CHLD_WELL_UNDERSTANDS_RISK,
vbase.CLIENT_COMM_SVCS_FRIENDS_FAM,
vbase.CLIENT_COMM_SVCS_RISK_LEVEL,
vbase.CLIENT_COMM_SVCS_SERVICES_GOALS,
vbase.CLIENT_COMM_SVCS_STAGE_CHANGE,
vbase.CLIENT_COMM_SVCS_UNDERSTANDS_RISK,
vbase.CLIENT_COMPLICATION_ILL_FRIENDS_FAM,
vbase.CLIENT_COMPLICATION_ILL_RISK_LEVEL,
vbase.CLIENT_COMPLICATION_ILL_SERVICES_GOALS,
vbase.CLIENT_COMPLICATION_ILL_STAGE_CHANGE,
vbase.CLIENT_COMPLICATION_ILL_UNDERSTANDS_RISK,
vbase.CLIENT_CRIMINAL_FRIENDS_FAM,
vbase.CLIENT_CRIMINAL_RISK_LEVEL,
vbase.CLIENT_CRIMINAL_SERVICES_GOALS,
vbase.CLIENT_CRIMINAL_STAGE_CHANGE,
vbase.CLIENT_CRIMINAL_UNDERSTANDS_RISK,
vbase.CLIENT_DISABILITY_FRIENDS_FAM,
vbase.CLIENT_DISABILITY_RISK_LEVEL,
vbase.CLIENT_DISABILITY_SERVICES_GOALS,
vbase.CLIENT_DISABILITY_STAGE_CHANGE,
vbase.CLIENT_DISABILITY_UNDERSTANDS_RISK,
vbase.CLIENT_ECONOMIC_FRIENDS_FAM,
vbase.CLIENT_ECONOMIC_RISK_LEVEL,
vbase.CLIENT_ECONOMIC_SERVICES_GOALS,
vbase.CLIENT_ECONOMIC_STAGE_CHANGE,
vbase.CLIENT_ECONOMIC_UNDERSTANDS_RISK,
vbase.CLIENT_EDUC_FRIENDS_FAM,
vbase.CLIENT_EDUC_RISK_LEVEL,
vbase.CLIENT_EDUC_SERVICES_GOALS,
vbase.CLIENT_EDUC_STAGE_CHANGE,
vbase.CLIENT_EDUC_UNDERSTANDS_RISK,
vbase.CLIENT_ENGLIT_FRIENDS_FAM,
vbase.CLIENT_ENGLIT_RISK_LEVEL,
vbase.CLIENT_ENGLIT_SERVICES_GOALS,
vbase.CLIENT_ENGLIT_STAGE_CHANGE,
vbase.CLIENT_ENGLIT_UNDERSTANDS_RISK,
vbase.CLIENT_ENVIRO_HEALTH_FRIENDS_FAM,
vbase.CLIENT_ENVIRO_HEALTH_RISK_LEVEL,
vbase.CLIENT_ENVIRO_HEALTH_SERVICES_GOALS,
vbase.CLIENT_ENVIRO_HEALTH_STAGE_CHANGE,
vbase.CLIENT_ENVIRO_HEALTH_UNDERSTANDS_RISK,
vbase.CLIENT_HLTH_SVCS_FRIENDS_FAM,
vbase.CLIENT_HLTH_SVCS_RISK_LEVEL,
vbase.CLIENT_HLTH_SVCS_SERVICES_GOALS,
vbase.CLIENT_HLTH_SVCS_STAGE_CHANGE,
vbase.CLIENT_HLTH_SVCS_UNDERSTANDS_RISK,
vbase.CLIENT_HOME_SAFETY_FRIENDS_FAM,
vbase.CLIENT_HOME_SAFETY_RISK_LEVEL,
vbase.CLIENT_HOME_SAFETY_SERVICES_GOALS,
vbase.CLIENT_HOME_SAFETY_STAGE_CHANGE,
vbase.CLIENT_HOME_SAFETY_UNDERSTANDS_RISK,
vbase.CLIENT_HOMELESS_FRIENDS_FAM,
vbase.CLIENT_HOMELESS_RISK_LEVEL,
vbase.CLIENT_HOMELESS_SERVICES_GOALS,
vbase.CLIENT_HOMELESS_STAGE_CHANGE,
vbase.CLIENT_HOMELESS_UNDERSTANDS_RISK,
vbase.CLIENT_IPV_FRIENDS_FAM,
vbase.CLIENT_IPV_RISK_LEVEL,
vbase.CLIENT_IPV_SERVICES_GOALS,
vbase.CLIENT_IPV_STAGE_CHANGE,
vbase.CLIENT_IPV_UNDERSTANDS_RISK,
vbase.CLIENT_LONELY_FRIENDS_FAM,
vbase.CLIENT_LONELY_RISK_LEVEL,
vbase.CLIENT_LONELY_SERVICES_GOALS,
vbase.CLIENT_LONELY_STAGE_CHANGE,
vbase.CLIENT_LONELY_UNDERSTANDS_RISK,
vbase.CLIENT_MENTAL_HEALTH_FRIENDS_FAM,
vbase.CLIENT_MENTAL_HEALTH_RISK_LEVEL,
vbase.CLIENT_MENTAL_HEALTH_SERVICES_GOALS,
vbase.CLIENT_MENTAL_HEALTH_STAGE_CHANGE,
vbase.CLIENT_MENTAL_HEALTH_UNDERSTANDS_RISK,
vbase.CLIENT_PREGPLAN_FRIENDS_FAM,
vbase.CLIENT_PREGPLAN_RISK_LEVEL,
vbase.CLIENT_PREGPLAN_SERVICES_GOALS,
vbase.CLIENT_PREGPLAN_STAGE_CHANGE,
vbase.CLIENT_PREGPLAN_UNDERSTANDS_RISK,
vbase.CLIENT_SUBSTANCE_FRIENDS_FAM,
vbase.CLIENT_SUBSTANCE_RISK_LEVEL,
vbase.CLIENT_SUBSTANCE_SERVICES_GOALS,
vbase.CLIENT_SUBSTANCE_STAGE_CHANGE,
vbase.CLIENT_SUBSTANCE_UNDERSTANDS_RISK,
vbase.CLIENT_UNSAFE_NTWK_FRIENDS_FAM,
vbase.CLIENT_UNSAFE_NTWK_RISK_LEVEL,
vbase.CLIENT_UNSAFE_NTWK_SERVICES_GOALS,
vbase.CLIENT_UNSAFE_NTWK_STAGE_CHANGE,
vbase.CLIENT_UNSAFE_NTWK_UNDERSTANDS_RISK,
vbase.CLIENT_PERSONAL_0_NAME_FIRST,
vbase.CLIENT_PERSONAL_0_NAME_LAST,
vbase.CLIENT_0_ID_NSO,
vbase.CLIENT_0_ID_AGENCY,
vbase.CLIENT_PERSONAL_0_DOB_INTAKE,
vbase.NURSE_PERSONAL_0_NAME,

from survey_views.f_select_ Star (@_hash_profile,@p_export_profile_id) vbase
where
vbase.CL_EN_GEN_ID in (select * from survey_views.f_list_client_inclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))
and
vbase.CL_EN_GEN_ID not in (select * from survey_views.f_list_client_exclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))

 
end;


