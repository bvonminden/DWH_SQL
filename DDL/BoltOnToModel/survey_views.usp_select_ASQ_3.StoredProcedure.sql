DROP PROCEDURE [survey_views].[usp_select_ASQ_3]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_ASQ_3] 
	@p_Encrypt			bit = 1,
	@p_Profile_Id		int = null,
	@p_exclude_tribal	bit	= 0
as  
begin  

select 
s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      ,s.[CL_EN_GEN_ID]
      ,s.[SiteID]
      ,s.[ProgramID]
      ,s.[IA_StaffID]
      ,survey_views.f_hash_field(@p_Encrypt, s.[ClientID]) as [ClientID]
      ,s.[RespondentID]
      --,s.[DW_AuditDate]
     -- ,s.[DataSource]
      ,s.[INFANT_HEALTH_NO_ASQ_COMM]
      ,s.[INFANT_HEALTH_NO_ASQ_FINE]
      ,s.[INFANT_HEALTH_NO_ASQ_GROSS]
      ,s.[INFANT_HEALTH_NO_ASQ_PERSONAL]
      ,s.[INFANT_HEALTH_NO_ASQ_PROBLEM]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_0_ID_AGENCY]) as [CLIENT_0_ID_AGENCY]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_0_ID_NSO]) as [CLIENT_0_ID_NSO]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_PERSONAL_0_NAME_FIRST]) as [CLIENT_PERSONAL_0_NAME_FIRST]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_PERSONAL_0_NAME_LAST]) as [CLIENT_PERSONAL_0_NAME_LAST]
      ,survey_views.f_hash_field(@p_Encrypt, s.[INFANT_0_ID_NSO]) as [INFANT_0_ID_NSO]
      --,s.[INFANT_PERSONAL_0_NAME_FIRST]
     --,s.[INFANT_PERSONAL_0_NAME_LAST]
      ,s.[INFANT_AGES_STAGES_1_COMM]
      ,s.[INFANT_AGES_STAGES_1_FMOTOR]
      ,s.[INFANT_AGES_STAGES_1_GMOTOR]
      ,s.[INFANT_AGES_STAGES_1_PSOCIAL]
      ,s.[INFANT_AGES_STAGES_1_PSOLVE]
      --,s.[INFANT_BIRTH_0_DOB]
      ,s.[NURSE_PERSONAL_0_NAME]
     -- ,s.[Master_SurveyID]
from survey_views.ASQ_3  s
where
s.SiteID in (select s.siteid from survey_views.f_get_sites_for_profile_id(@p_Profile_Id, @p_exclude_tribal) s)



end 
GO
