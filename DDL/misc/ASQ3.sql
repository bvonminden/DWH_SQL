create procedure [survey_views].usp_etl_select_ ASQ3  
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
vbase.DW_AuditDate,
vbase.DataSource,
vbase.INFANT_HEALTH_NO_ASQ_COMM,
vbase.INFANT_HEALTH_NO_ASQ_FINE,
vbase.INFANT_HEALTH_NO_ASQ_GROSS,
vbase.INFANT_HEALTH_NO_ASQ_PERSONAL,
vbase.INFANT_HEALTH_NO_ASQ_PROBLEM,
vbase.CLIENT_0_ID_AGENCY,
vbase.CLIENT_0_ID_NSO,
vbase.CLIENT_PERSONAL_0_NAME_FIRST,
vbase.CLIENT_PERSONAL_0_NAME_LAST,
vbase.INFANT_0_ID_NSO,
vbase.INFANT_PERSONAL_0_NAME_FIRST,
vbase.INFANT_PERSONAL_0_NAME_LAST,
vbase.INFANT_AGES_STAGES_1_COMM,
vbase.INFANT_AGES_STAGES_1_FMOTOR,
vbase.INFANT_AGES_STAGES_1_GMOTOR,
vbase.INFANT_AGES_STAGES_1_PSOCIAL,
vbase.INFANT_AGES_STAGES_1_PSOLVE,
vbase.INFANT_BIRTH_0_DOB,
vbase.NURSE_PERSONAL_0_NAME,
vbase.Master_SurveyID,

from survey_views.f_select_ ASQ3 (@_hash_profile,@p_export_profile_id) vbase
where
vbase.CL_EN_GEN_ID in (select * from survey_views.f_list_client_inclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))
and
vbase.CL_EN_GEN_ID not in (select * from survey_views.f_list_client_exclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))

 
end;


