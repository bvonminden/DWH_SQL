create procedure [survey_views].usp_etl_select_ Client_Funding  
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
vbase.CLIENT_FUNDING_0_SOURCE_MIECHVP_COM,
vbase.CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM,
vbase.CLIENT_FUNDING_0_SOURCE_OTHER,
vbase.CLIENT_FUNDING_0_SOURCE_OTHER_TXT,
vbase.CLIENT_FUNDING_1_END_MIECHVP_COM,
vbase.CLIENT_FUNDING_1_END_MIECHVP_FORM,
vbase.CLIENT_FUNDING_1_END_OTHER,
vbase.CLIENT_FUNDING_1_START_MIECHVP_COM,
vbase.CLIENT_FUNDING_1_START_MIECHVP_FORM,
vbase.CLIENT_FUNDING_1_START_OTHER,
vbase.NURSE_PERSONAL_0_NAME,
vbase.DW_AuditDate,
vbase.DataSource,
vbase.CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL,
vbase.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL,
vbase.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL,
vbase.CLIENT_FUNDING_0_SOURCE_OTHER1,
vbase.CLIENT_FUNDING_0_SOURCE_OTHER2,
vbase.CLIENT_FUNDING_0_SOURCE_OTHER3,
vbase.CLIENT_FUNDING_1_END_OTHER1,
vbase.CLIENT_FUNDING_1_END_OTHER2,
vbase.CLIENT_FUNDING_1_END_OTHER3,
vbase.CLIENT_FUNDING_1_START_OTHER1,
vbase.CLIENT_FUNDING_1_START_OTHER2,
vbase.CLIENT_FUNDING_1_START_OTHER3,
vbase.Master_SurveyID,
vbase.CLIENT_FUNDING_0_SOURCE_PFS,
vbase.CLIENT_FUNDING_1_END_PFS,
vbase.CLIENT_FUNDING_1_START_PFS,
vbase.Archive_Record,
vbase.CLIENT_FUNDING_0_SOURCE_OTHER4,
vbase.CLIENT_FUNDING_0_SOURCE_OTHER5,
vbase.CLIENT_FUNDING_0_SOURCE_OTHER6,
vbase.CLIENT_FUNDING_1_END_OTHER4,
vbase.CLIENT_FUNDING_1_END_OTHER5,
vbase.CLIENT_FUNDING_1_END_OTHER6,
vbase.CLIENT_FUNDING_1_START_OTHER4,
vbase.CLIENT_FUNDING_1_START_OTHER5,
vbase.CLIENT_FUNDING_1_START_OTHER6,

from survey_views.f_select_ Client_Funding (@_hash_profile,@p_export_profile_id) vbase
where
vbase.CL_EN_GEN_ID in (select * from survey_views.f_list_client_inclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))
and
vbase.CL_EN_GEN_ID not in (select * from survey_views.f_list_client_exclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))

 
end;


