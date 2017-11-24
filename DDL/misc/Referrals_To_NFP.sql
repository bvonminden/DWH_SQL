create procedure [survey_views].usp_etl_select_Referrals_To_NFP  
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
vbase.REFERRAL_PROSPECT_0_SOURCE_CODE,
vbase.REFERRAL_SOURCE_PRIMARY_0_NAME,
vbase.REFERRAL_SOURCE_PRIMARY_1_LOCATION,
vbase.REFERRAL_SOURCE_SECONDARY_0_NAME,
vbase.REFERRAL_SOURCE_SECONDARY_1_LOCATION,
vbase.REFERRAL_PROSPECT_0_NOTES,
vbase.REFERRAL_PROSPECT_DEMO_1_PLANG,
vbase.REFERRAL_PROSPECT_DEMO_1_NAME_FIRST,
vbase.REFERRAL_PROSPECT_DEMO_0_NAME_LAST,
vbase.REFERRAL_PROSPECT_DEMO_1_DOB,
vbase.REFERRAL_PROSPECT_DEMO_1_STREET,
vbase.REFERRAL_PROSPECT_DEMO_1_STREET2,
vbase.REFERRAL_PROSPECT_DEMO_1_ZIP,
vbase.REFERRAL_PROSPECT_DEMO_1_WORK,
vbase.REFERRAL_PROSPECT_DEMO_1_PHONE_HOME,
vbase.REFERRAL_PROSPECT_DEMO_1_CELL,
vbase.REFERRAL_PROSPECT_DEMO_1_EMAIL,
vbase.REFERRAL_PROSPECT_DEMO_1_EDD,
vbase.REFERRAL_PROSPECT_0_WAIT_LIST,
vbase.REFERRAL_PROSPECT_0_FOLLOWUP_NURSE,
--vbase.DW_AuditDate,
--vbase.DataSource,
--vbase.LA_CTY_REFERRAL_SCHOOL,
--vbase.LA_CTY_REFERRAL_SOURCE_OTH,
vbase.CLIENT_0_ID_NSO
--vbase.Master_SurveyID

from survey_views.f_select_Referrals_To_NFP_Program(@_hash_profile,@p_export_profile_id) vbase
where
vbase.CL_EN_GEN_ID in (select * from survey_views.f_list_client_inclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))
and
vbase.CL_EN_GEN_ID not in (select * from survey_views.f_list_client_exclusions(vbase.ProgramID, vbase.SiteID,vbase.CL_EN_GEN_ID,@p_entity_filter))

 
end;


