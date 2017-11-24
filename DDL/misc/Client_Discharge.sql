create procedure [survey_views].usp_etl_select_Client_Discharge  
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
vbase.NURSE_PERSONAL_0_NAME,
vbase.CLIENT_DISCHARGE_1_DATE,
vbase.CLIENT_DISCHARGE_0_REASON,
vbase.CLIENT_DISCHARGE_1_MISCARRIED_DATE,
vbase.CLIENT_DISCHARGE_1_LOST_CUSTODY,
vbase.CLIENT_DISCHARGE_1_MATERNAL_DEATH_DATE,
vbase.CLIENT_DISCHARGE_1_INCARCERATION_DATE,
vbase.CLIENT_DISCHARGE_1_UNABLE_REASON,
vbase.NONE,
vbase.CLIENT_PERSONAL_0_DOB_INTAKE,
vbase.CLIENT_0_ID_AGENCY,
vbase.CLIENT_DISCHARGE_1_LOST_CUSTODY_DATE,
vbase.DW_AuditDate,
vbase.DataSource,
vbase.CLIENT_DISCHARGE_1_INFANTDEATH_DATE,
vbase.CLIENT_DISCHARGE_1_MISCARRIED_DATE2,
vbase.Master_SurveyID,
vbase.CLIENT_DISCHARGE_1_INFANTDEATH_REASON,
vbase.CLIENT_DISCHARGE_1_MATERNAL_DEATH_REASON

from survey_views.f_select_Client_Discharge(@_hash_profile,@p_export_profile_id) vbase
where
vbase.CL_EN_GEN_ID in (select * from survey_views.f_list_client_inclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))
and
vbase.CL_EN_GEN_ID not in (select * from survey_views.f_list_client_exclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))

 
end;


