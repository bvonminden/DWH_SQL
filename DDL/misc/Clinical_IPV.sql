create procedure [survey_views].usp_etl_select_Clinical_IPV  
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
--vbase.Master_SurveyID,
vbase.SurveyDate,
vbase.AuditDate,
vbase.CL_EN_GEN_ID,
vbase.SiteID,
vbase.ProgramID,
vbase.IA_StaffID,
vbase.ClientID,
vbase.RespondentID,
--vbase.DW_AuditDate,
--vbase.DataSource,
--vbase.Archive_Record,
vbase.IPV_AFRAID,
vbase.IPV_CHILD_SAFETY,
vbase.IPV_CONTROLING,
vbase.IPV_FORCED_SEX,
vbase.IPV_INDICATED,
vbase.IPV_INSULTED,
vbase.IPV_PHYSICALLY_HURT,
vbase.IPV_PRN_REASON,
--vbase.IPV_Q5_8_ANY_YES,
vbase.IPV_SCREAMED,
vbase.IPV_THREATENED,
vbase.IPV_TOOL_USED,
vbase.CLIENT_0_ID_NSO,
vbase.CLIENT_PERSONAL_0_NAME_FIRST ,
vbase.CLIENT_PERSONAL_0_NAME_LAST,
vbase.IPV_Q1_4_SCORE,
vbase.CLIENT_PERSONAL_0_DOB_INTAKE,
vbase.NURSE_PERSONAL_0_NAME

from survey_views.f_select_Clinical_IPV_Assessment(@_hash_profile,@p_export_profile_id) vbase
where
vbase.CL_EN_GEN_ID in (select * from survey_views.f_list_client_inclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))
and
vbase.CL_EN_GEN_ID not in (select * from survey_views.f_list_client_exclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))

 
end;


