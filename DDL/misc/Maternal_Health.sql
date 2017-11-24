create procedure [survey_views].usp_etl_select_Maternal_Health  
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

vbase.SurveyResponseID,
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
vbase.CLIENT_HEALTH_PREGNANCY_0_LIVE_BIRTHS,
vbase.CLIENT_HEALTH_PREGNANCY_0_DOCTOR_VISIT,
vbase.CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE,
vbase.CLIENT_HEALTH_PREGNANCY_0_EDD,
vbase.CLIENT_HEALTH_GENERAL_0_CONCERNS,
vbase.CLIENT_HEALTH_GENERAL_WEIGHT_0_POUNDS,
vbase.CLIENT_HEALTH_BELIEF_0_LITTLE_CONTROL,
vbase.CLIENT_HEALTH_BELIEF_0_CANT_SOLVE,
vbase.CLIENT_HEALTH_BELIEF_0_LITTLE_CAN_DO,
vbase.CLIENT_HEALTH_BELIEF_0_FEEL_HELPLESS,
vbase.CLIENT_HEALTH_BELIEF_0_FEEL_PUSHED_AROUND,
vbase.CLIENT_HEALTH_BELIEF_0_FUTURE_CONTROL,
vbase.[CLIENT_HEALTH_BELIEF_ 0_DO_ANYTHING],
vbase.CLIENT_HEALTH_GENERAL_0_OTHER,
vbase.CLIENT_HEALTH_GENERAL_HEIGHT_0_FEET,
vbase.CLIENT_HEALTH_GENERAL_HEIGHT_1_INCHES,
vbase.CLIENT_0_ID_AGENCY,
--vbase.DW_AuditDate,
--vbase.DataSource,
--vbase.LA_CTY_MENTAL_MAT_HEALTH,
--vbase.LA_CTY_PHYSICAL_MAT_HEALTH,
--vbase.LA_CTY_DX_OTHER_MAT_HEALTH,
--vbase.LA_CTY_DSM_DX_MAT_HEALTH,
vbase.CLIENT_HEALTH_GENERAL_0_PRE_GEST_BP,
vbase.CLIENT_HEALTH_GENERAL_0_PRE_GEST_DIABETES,
vbase.CLIENT_HEALTH_GENERAL_0_PRE_GEST_HEART,
vbase.CLIENT_HEALTH_GENERAL_0_PRE_GEST_KIDNEYS,
vbase.CLIENT_HEALTH_GENERAL_0_PRE_GEST_STI,
vbase.CLIENT_HEALTH_GENERAL_0_PRE_GEST_UTI,
vbase.CLIENT_HEALTH_GENERAL_0_PRE_GEST_VI,
vbase.CLIENT_HEALTH_GENERAL_CURRENT_WEIGHT_0_POUNDS,
--vbase.Master_SurveyID,
vbase.CLIENT_HEALTH_GENERAL_0_CONCERNS2,
vbase.CLIENT_HEALTH_GENERAL_0_ADDICTION,
vbase.CLIENT_HEALTH_GENERAL_0_MENTAL_HEALTH

from survey_views.f_select_Maternal_Health_Assessment(@_hash_profile,@p_export_profile_id) vbase
where
vbase.CL_EN_GEN_ID in (select * from survey_views.f_list_client_inclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))
and
vbase.CL_EN_GEN_ID not in (select * from survey_views.f_list_client_exclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))

 
end;


