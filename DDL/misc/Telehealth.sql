create procedure [survey_views].usp_etl_select_Telehealth  
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
--vbase.RespondentID,
--vbase.DW_AuditDate,
--vbase.DataSource,
vbase.CLIENT_TELEHEALTH_REASON,
vbase.CLIENT_TELEHEALTH_TYPE,
vbase.CLIENT_0_ID_NSO,
vbase.CLIENT_PERSONAL_0_NAME_FIRST,
vbase.CLIENT_PERSONAL_0_NAME_LAST,
vbase.CLIENT_TELEHEALTH_REASON_OTHER,
vbase.CLIENT_TELEHEALTH_TYPE_OTHER,
vbase.CLIENT_PERSONAL_0_DOB_INTAKE,
vbase.NURSE_PERSONAL_0_NAME
--vbase.LastModified

from survey_views.f_select_Telehealth_Form(@_hash_profile,@p_export_profile_id) vbase
where
vbase.CL_EN_GEN_ID in (select * from survey_views.f_list_client_inclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))
and
vbase.CL_EN_GEN_ID not in (select * from survey_views.f_list_client_exclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))

 
end;


