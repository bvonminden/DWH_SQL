create procedure [survey_views].usp_etl_select_Health_Habits  
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
vbase.CLIENT_SUBSTANCE_CIG_1_PRE_PREG,
vbase.CLIENT_SUBSTANCE_CIG_0_DURING_PREG,
vbase.CLIENT_SUBSTANCE_CIG_1_LAST_48,
vbase.CLIENT_SUBSTANCE_ALCOHOL_0_14DAY,
vbase.CLIENT_SUBSTANCE_ALCOHOL_1_14DAY_DRINKS,
vbase.CLIENT_SUBSTANCE_POT_0_14DAYS,
vbase.CLIENT_SUBSTANCE_POT_1_14DAYS_JOINTS,
vbase.CLIENT_SUBSTANCE_COCAINE_0_14DAY,
vbase.CLIENT_SUBSTANCE_COCAINE_1_14DAY_TIMES,
vbase.CLIENT_SUBSTANCE_OTHER_0_14DAY,
vbase.CLIENT_SUBSTANCE_OTHER_1_14DAY_TIMES,
vbase.NURSE_PERSONAL_0_NAME_LAST,
vbase.CLIENT_0_ID_AGENCY,
--vbase.DW_AuditDate,
--vbase.DataSource,
vbase.CLIENT_SUBSTANCE_NICOTINE_0_OTHER_TYPES,
vbase.CLIENT_SUBSTANCE_NICOTINE_0_OTHER
--vbase.Master_SurveyID

from survey_views.f_select_Health_Habits(@_hash_profile,@p_export_profile_id) vbase
where
vbase.CL_EN_GEN_ID in (select * from survey_views.f_list_client_inclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))
and
vbase.CL_EN_GEN_ID not in (select * from survey_views.f_list_client_exclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))

 
end;


