create procedure survey_views.usp_etl_select_Dance_Coding_Sheet
(
	@p_export_profile_id int
)
as
begin

declare		@_hash_profile			char(10);
set			@_hash_profile			= (select top 1 isnull('SA',hash_policy) from survey_views.f_get_survey_etl_work() where ExportProfileID=@p_export_profile_id);

print		@p_export_profile_id;
print		@_hash_profile;


select 
	vbase. SurveyResponseID,
	vbase.ElementsProcessed,
	vbase.SurveyID,
	--vbase.Master_SurveyID,
	vbase.SurveyDate,
	vbase.AuditDate,
	vbase.CL_EN_GEN_ID,
	vbase.SiteID,
	vbase.ProgramID,
	vbase.IA_StaffID,
	vbase.ClientID,
	vbase.RespondentID,
	--vbase.DW_AuditDate,
	--vbase.DataSource,
	vbase.CLIENT_CAC_NA,
	vbase.CLIENT_CI_NA,
	vbase.CLIENT_EPA_NA,
	vbase.CLIENT_NCCO_NA,
	vbase.CLIENT_NI_NA,
	vbase.CLIENT_NT_NA,
	vbase.CLIENT_NVC_NA,
	vbase.CLIENT_PC_NA,
	vbase.CLIENT_PO_NA,
	vbase.CLIENT_PRA_NA,
	vbase.CLIENT_RP_NA,
	vbase.CLIENT_SCA_NA,
	vbase.CLIENT_SE_NA,
	vbase.CLIENT_VE_NA,
	vbase.CLIENT_VEC_NA,
	vbase.CLIENT_VISIT_VARIABLES,
	vbase.CLIENT_LS_NA,
	vbase.CLIENT_RD_NA,
	vbase.CLIENT_VQ_NA,
	vbase.CLIENT_0_ID_NSO,
	vbase.CLIENT_PERSONAL_0_NAME_FIRST,
	vbase.CLIENT_PERSONAL_0_NAME_LAST,
	vbase.CLIENT_CAC_COMMENTS,
	vbase.CLIENT_CI_COMMENTS,
	vbase.CLIENT_EPA_COMMENTS,
	vbase.CLIENT_LS_COMMENTS,
	vbase.CLIENT_NCCO_COMMENTS,
	vbase.CLIENT_NI_COMMENTS,
	vbase.CLIENT_NT_COMMENTS,
	vbase.CLIENT_NVC_COMMENTS,
	vbase.CLIENT_PC_COMMENTS,
	vbase.CLIENT_PO_COMMENTS,
	vbase.CLIENT_PRA_COMMENTS,
	vbase.CLIENT_RD_COMMENTS,
	vbase.CLIENT_RP_COMMENTS,
	vbase.CLIENT_SCA_COMMENTS,
	vbase.CLIENT_SE_COMMENTS,
	vbase.CLIENT_VE_COMMENTS,
	vbase.CLIENT_VEC_COMMENTS,
	vbase.CLIENT_VQ_COMMENTS,
	vbase.CLIENT_ACTIVITY_DURATION,
	vbase.CLIENT_CAC_PER,
	vbase.CLIENT_CHILD_AGE,
	vbase.CLIENT_CHILD_DURATION,
	vbase.CLIENT_CI_PER,
	vbase.CLIENT_EPA_PER,
	vbase.CLIENT_LS_PER,
	vbase.CLIENT_NCCO_PER,
	vbase.CLIENT_NI_PER,
	vbase.CLIENT_NT_PER,
	vbase.CLIENT_NVC_PER,
	vbase.CLIENT_PC_PER,
	vbase.CLIENT_PO_PER,
	vbase.CLIENT_PRA_PER,
	vbase.CLIENT_RD_PER,
	vbase.CLIENT_RP_PER,
	vbase.CLIENT_SCA_PER,
	vbase.CLIENT_SE_PER,
	vbase.CLIENT_VE_PER,
	vbase.CLIENT_VEC_PER,
	vbase.CLIENT_VQ_PER,
	vbase.NURSE_PERSONAL_0_NAME

from survey_views.f_select_DANCE_Coding_Sheet(@_hash_profile,@p_export_profile_id) vbase;

 
end
