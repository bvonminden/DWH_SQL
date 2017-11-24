create procedure [survey_views].usp_etl_select_Edinburgh  
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
vbase.CLIENT_PERSONAL_0_NAME_FIRST,
vbase.CLIENT_PERSONAL_0_NAME_LAST,
vbase.CLIENT_PERSONAL_0_DOB_INTAKE,
vbase.CLIENT_EPDS_1_ABLE_TO_LAUGH,
vbase.CLIENT_EPDS_1_ENJOY_THINGS,
vbase.CLIENT_EPDS_1_BLAME_SELF,
vbase.CLIENT_EPDS_1_ANXIOUS_WORRIED,
vbase.CLIENT_EPDS_1_SCARED_PANICKY,
vbase.CLIENT_EPDS_1_THINGS_GETTING_ON_TOP,
vbase.CLIENT_EPDS_1_DIFFICULTY_SLEEPING,
vbase.CLIENT_EPDS_1_SAD_MISERABLE,
vbase.CLIENT_EPDS_1_BEEN_CRYING,
vbase.CLIENT_EPDS_1_HARMING_SELF,
vbase.CLIENT_0_ID_NSO,
vbase.NURSE_PERSONAL_0_NAME,
vbase.CLIENT_0_ID_AGENCY,
--vbase.DW_AuditDate,
--vbase.DataSource,
--vbase.LA_CTY_OQ10_EDPS,
--vbase.LA_CTY_PHQ9_SCORE_EDPS,
--vbase.LA_CTY_STRESS_INDEX_EDPS,
vbase.CLIENT_EPS_TOTAL_SCORE
--vbase.Master_SurveyID

from survey_views.f_select_Edinburgh_Postnatal_Depression_Scale(@_hash_profile,@p_export_profile_id) vbase
where
vbase.CL_EN_GEN_ID in (select * from survey_views.f_list_client_inclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))
and
vbase.CL_EN_GEN_ID not in (select * from survey_views.f_list_client_exclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))

 
end;


