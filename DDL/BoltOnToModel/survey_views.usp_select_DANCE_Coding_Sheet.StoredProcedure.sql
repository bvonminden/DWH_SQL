DROP PROCEDURE [survey_views].[usp_select_DANCE_Coding_Sheet]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_DANCE_Coding_Sheet]
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null,
	@p_exclude_tribal	bit	= 0
	
as  
begin  
set nocount on;

select 
	s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
     -- ,s.[Master_SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      ,s.[CL_EN_GEN_ID]
      ,s.[SiteID]
      ,s.[ProgramID]
      ,s.[IA_StaffID]
      ,survey_views.f_hash_field(@p_Encrypt,s.[ClientID]) as [ClientID]
      ,s.[RespondentID]
    --  ,s.[DW_AuditDate]
      --,s.[DataSource]
      ,s.[CLIENT_CAC_NA]
      ,s.[CLIENT_CI_NA]
      ,s.[CLIENT_EPA_NA]
      ,s.[CLIENT_NCCO_NA]
      ,s.[CLIENT_NI_NA]
      ,s.[CLIENT_NT_NA]
      ,s.[CLIENT_NVC_NA]
      ,s.[CLIENT_PC_NA]
      ,s.[CLIENT_PO_NA]
      ,s.[CLIENT_PRA_NA]
      ,s.[CLIENT_RP_NA]
      ,s.[CLIENT_SCA_NA]
      ,s.[CLIENT_SE_NA]
      ,s.[CLIENT_VE_NA]
      ,s.[CLIENT_VEC_NA]
      ,s.[CLIENT_VISIT_VARIABLES]
      ,s.[CLIENT_LS_NA]
      ,s.[CLIENT_RD_NA]
      ,s.[CLIENT_VQ_NA]
      ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_0_ID_NSO]) as [CLIENT_0_ID_NSO]
      ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_PERSONAL_0_NAME_FIRST]) as [CLIENT_PERSONAL_0_NAME_FIRST]
      ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_PERSONAL_0_NAME_LAST]) as [CLIENT_PERSONAL_0_NAME_LAST]
      ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_CAC_COMMENTS] ) as [CLIENT_CAC_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_CI_COMMENTS] ) as [CLIENT_CI_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_EPA_COMMENTS] ) as [CLIENT_EPA_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_LS_COMMENTS] ) as [CLIENT_LS_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_NCCO_COMMENTS] ) as [CLIENT_NCCO_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_NI_COMMENTS] ) as [CLIENT_NI_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_NT_COMMENTS] ) as [CLIENT_NT_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_NVC_COMMENTS] ) as [CLIENT_NVC_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_PC_COMMENTS] ) as [CLIENT_PC_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_PO_COMMENTS] ) as [CLIENT_PO_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_PRA_COMMENTS] ) as [CLIENT_PRA_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_RD_COMMENTS] ) as [CLIENT_RD_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_RP_COMMENTS] ) as [CLIENT_RP_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_SCA_COMMENTS] ) as [CLIENT_SCA_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_SE_COMMENTS] ) as [CLIENT_SE_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_VE_COMMENTS] ) as [CLIENT_VE_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_VEC_COMMENTS] ) as [CLIENT_VEC_COMMENTS]
	  ,survey_views.f_hash_field(@p_Encrypt,s.[CLIENT_VQ_COMMENTS] ) as [CLIENT_VQ_COMMENTS]
	  ,s.[CLIENT_ACTIVITY_DURATION]
      ,s.[CLIENT_CAC_PER]
      ,s.[CLIENT_CHILD_AGE]
      ,s.[CLIENT_CHILD_DURATION]
      ,s.[CLIENT_CI_PER]
      ,s.[CLIENT_EPA_PER]
      ,s.[CLIENT_LS_PER]
      ,s.[CLIENT_NCCO_PER]
      ,s.[CLIENT_NI_PER]
      ,s.[CLIENT_NT_PER]
      ,s.[CLIENT_NVC_PER]
      ,s.[CLIENT_PC_PER]
      ,s.[CLIENT_PO_PER]
      ,s.[CLIENT_PRA_PER]
      ,s.[CLIENT_RD_PER]
      ,s.[CLIENT_RP_PER]
      ,s.[CLIENT_SCA_PER]
      ,s.[CLIENT_SE_PER]
      ,s.[CLIENT_VE_PER]
      ,s.[CLIENT_VEC_PER]
      ,s.[CLIENT_VQ_PER]
      ,s.[NURSE_PERSONAL_0_NAME]   
from survey_views.DANCE_Coding_Sheet s
where
s.SiteID in (select s.siteid from survey_views.f_get_sites_for_profile_id(@p_Profile_Id, @p_exclude_tribal) s)



end 
GO
