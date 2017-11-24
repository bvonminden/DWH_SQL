create procedure [survey_views].usp_etl_select_ PHQ-9  
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
vbase.CLIENT_0_ID_AGENCY,
vbase.CLIENT_0_ID_NSO,
vbase.CLIENT_PERSONAL_0_DOB_INTAKE,
vbase.CLIENT_PERSONAL_0_NAME_FIRST,
vbase.CLIENT_PERSONAL_0_NAME_LAST,
vbase.Need from Kim,
vbase.NeedFromKim,
vbase.CLIENT_PHQ9_0_TOTAL_SCORE,
vbase.CLIENT_PHQ9_1_CONCENTRATION,
vbase.CLIENT_PHQ9_1_DIFFICULTY,
vbase.CLIENT_PHQ9_1_FEEL_BAD,
vbase.CLIENT_PHQ9_1_FEEL_DEPRESSED,
vbase.CLIENT_PHQ9_1_FEEL_TIRED,
vbase.CLIENT_PHQ9_1_HURT_SELF,
vbase.CLIENT_PHQ9_1_LITTLE_INTEREST,
vbase.CLIENT_PHQ9_1_MOVE_SPEAK,
vbase.CLIENT_PHQ9_1_TROUBLE_EAT,
vbase.CLIENT_PHQ9_1_TROUBLE_SLEEP,
vbase.NURSE_PERSONAL_0_NAME,
vbase.DW_AuditDate,
vbase.DataSource,
vbase.Master_SurveyID,

from survey_views.f_select_ PHQ-9 (@_hash_profile,@p_export_profile_id) vbase
where
vbase.CL_EN_GEN_ID in (select * from survey_views.f_list_client_inclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))
and
vbase.CL_EN_GEN_ID not in (select * from survey_views.f_list_client_exclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))

 
end;


