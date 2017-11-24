create procedure [survey_views].usp_etl_select_Relationships  
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
vbase.NURSE_PERSONAL_0_NAME,
vbase.CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER,
vbase.CLIENT_ABUSE_HIT_0_SLAP_PARTNER,
vbase.CLIENT_ABUSE_TIMES_0_HURT_LAST_YR,
vbase.CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER,
vbase.CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER,
vbase.CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER,
vbase.CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER,
vbase.CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER,
vbase.CLIENT_ABUSE_FORCED_0_SEX,
vbase.CLIENT_ABUSE_FORCED_1_SEX_LAST_YR,
vbase.CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME,
vbase.CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME,
vbase.CLIENT_ABUSE_AFRAID_0_PARTNER,
vbase.CLIENT_0_ID_AGENCY
--vbase.ABUSE_EMOTION_0_PHYSICAL_PARTNER,
--vbase.DW_AuditDate,
--vbase.DataSource,
--vbase.Master_SurveyID

from survey_views.f_select_Relationship_Assessment(@_hash_profile,@p_export_profile_id) vbase
where
vbase.CL_EN_GEN_ID in (select * from survey_views.f_list_client_inclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))
and
vbase.CL_EN_GEN_ID not in (select * from survey_views.f_list_client_exclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))

 
end;


