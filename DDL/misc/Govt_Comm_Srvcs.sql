create procedure [survey_views].usp_etl_select_Govt_Comm_Srvcs  
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
--vbase.RespondentID,
vbase.CLIENT_0_ID_NSO,
vbase.CLIENT_PERSONAL_0_NAME_FIRST,
vbase.CLIENT_PERSONAL_0_NAME_LAST,
vbase.NURSE_PERSONAL_0_NAME,
vbase.SERVICE_USE_0_TANF_CLIENT,
vbase.SERVICE_USE_0_FOODSTAMP_CLIENT,
vbase.SERVICE_USE_0_SOCIAL_SECURITY_CLIENT,
vbase.SERVICE_USE_0_UNEMPLOYMENT_CLIENT,
vbase.SERVICE_USE_0_SUBSID_CHILD_CARE_CLIENT,
vbase.SERVICE_USE_0_IPV_CLIENT,
vbase.SERVICE_USE_0_CPS_CLIENT,
vbase.SERVICE_USE_0_CPS_CHILD,
vbase.SERVICE_USE_0_MENTAL_CLIENT,
vbase.SERVICE_USE_0_RELATIONSHIP_COUNSELING_CLIENT,
vbase.SERVICE_USE_0_SMOKE_CLIENT,
vbase.SERVICE_USE_0_ALCOHOL_ABUSE_CLIENT,
vbase.SERVICE_USE_0_DRUG_ABUSE_CLIENT,
vbase.SERVICE_USE_0_MEDICAID_CLIENT,
vbase.SERVICE_USE_0_MEDICAID_CHILD,
vbase.SERVICE_USE_0_SCHIP_CLIENT,
vbase.SERVICE_USE_0_SCHIP_CHILD,
vbase.SERVICE_USE_0_SPECIAL_NEEDS_CLIENT,
vbase.SERVICE_USE_0_SPECIAL_NEEDS_CHILD,
vbase.SERVICE_USE_0_PCP_CLIENT,
vbase.SERVICE_USE_0_PCP_SICK_CHILD,
vbase.SERVICE_USE_0_PCP_WELL_CHILD,
vbase.SERVICE_USE_0_DEVELOPMENTAL_DISABILITY_CLIENT,
vbase.SERVICE_USE_0_WIC_CLIENT,
vbase.SERVICE_USE_0_CHILD_CARE_CLIENT,
vbase.SERVICE_USE_0_JOB_TRAINING_CLIENT,
vbase.SERVICE_USE_0_HOUSING_CLIENT,
vbase.SERVICE_USE_0_TRANSPORTATION_CLIENT,
vbase.SERVICE_USE_0_PREVENT_INJURY_CLIENT,
vbase.SERVICE_USE_0_BIRTH_EDUC_CLASS_CLIENT,
vbase.SERVICE_USE_0_LACTATION_CLIENT,
vbase.SERVICE_USE_0_GED_CLIENT,
vbase.SERVICE_USE_0_HIGHER_EDUC_CLIENT,
vbase.SERVICE_USE_0_CHARITY_CLIENT,
vbase.SERVICE_USE_0_LEGAL_CLIENT,
vbase.SERVICE_USE_0_PATERNITY_CLIENT,
vbase.SERVICE_USE_0_CHILD_SUPPORT_CLIENT,
vbase.SERVICE_USE_0_ADOPTION_CLIENT,
vbase.SERVICE_USE_0_OTHER1_DESC,
vbase.SERVICE_USE_0_OTHER1,
vbase.SERVICE_USE_0_CHILD_OTHER1,
vbase.SERVICE_USE_0_OTHER2_DESC,
vbase.SERVICE_USE_0_OTHER3_DESC,
vbase.SERVICE_USE_0_OTHER2,
vbase.SERVICE_USE_0_CHILD_OTHER2,
vbase.SERVICE_USE_0_OTHER3,
vbase.SERVICE_USE_0_CHILD_OTHER3,
vbase.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT,
vbase.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD,
vbase.CLIENT_0_ID_AGENCY,
vbase.CLIENT_PERSONAL_0_DOB_INTAKE,
vbase.SERVICE_USE_0_DENTAL_CLIENT,
vbase.SERVICE_USE_0_INTERVENTION,
vbase.SERVICE_USE_0_PCP_WELL_CLIENT,
vbase.SERVICE_USE_0_DENTAL_CHILD,
--vbase.DW_AuditDate,
--vbase.DataSource,
--vbase.JP error  if no data associated delete element,
vbase.SERVICE_USE_INDIAN_HEALTH_CHILD,
vbase.SERVICE_USE_INDIAN_HEALTH_CLIENT,
vbase.SERVICE_USE_MILITARY_INS_CHILD,
vbase.SERVICE_USE_MILITARY_INS_CLIENT ,
vbase.SERVICE_USE_PCP_CLIENT_POSTPARTUM,
vbase.SERVICE_USE_PCP_CLIENT_PRENATAL,
vbase.SERVICE_USE_PCP_CLIENT_WELLWOMAN,
--vbase.Master_SurveyID,
--vbase.Archive_Record,
vbase.SERVICE_USE_0_INTERVENTION_45DAYS,

from survey_views.f_select_Use_Of_Government_and_Community_Services(@_hash_profile,@p_export_profile_id) vbase
where
vbase.CL_EN_GEN_ID in (select * from survey_views.f_list_client_inclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))
and
vbase.CL_EN_GEN_ID not in (select * from survey_views.f_list_client_exclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))

 
end;


