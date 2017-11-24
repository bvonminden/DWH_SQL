create procedure [survey_views].usp_etl_select_ MN18MosToddler  
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
vbase.MN_CLIENT_INSURANCE_RESOURCE,
vbase.MN_INFANT_INSURANCE_RESOURCE,
vbase.MN_CLIENT_INSURANCE,
vbase.MN_COMPLETED_EDUCATION_PROGRAMS,
vbase.MN_INFANT_INSURANCE,
vbase.MN_SITE,
vbase.CLIENT_0_ID_NSO,
vbase.CLIENT_PERSONAL_0_NAME_FIRST,
vbase.CLIENT_PERSONAL_0_NAME_LAST,
vbase.INFANT_0_ID_NSO,
vbase.INFANT_PERSONAL_0_NAME_FIRST,
vbase.INFANT_PERSONAL_0_NAME_LAST,
vbase.MN_CLIENT_INSURANCE_RESOURCE_OTHER,
vbase.MN_COMPLETED_EDUCATION_PROGRAMS_YES,
vbase.MN_INFANT_0_ID_2,
vbase.MN_INFANT_INSURANCE_RESOURCE_OTHER,
vbase.MN_TEAM_NAME,
vbase.MN_TOTAL_HV,
vbase.MN_DATA_STAFF_PERSONAL_0_NAME,
vbase.NURSE_PERSONAL_0_NAME,

from survey_views.f_select_ MN18MosToddler (@_hash_profile,@p_export_profile_id) vbase
where
vbase.CL_EN_GEN_ID in (select * from survey_views.f_list_client_inclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))
and
vbase.CL_EN_GEN_ID not in (select * from survey_views.f_list_client_exclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))

 
end;


