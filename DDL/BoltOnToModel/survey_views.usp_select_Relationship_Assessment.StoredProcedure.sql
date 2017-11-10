DROP PROCEDURE [survey_views].[usp_select_Relationship_Assessment]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Relationship_Assessment] 
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
      ,s.[SurveyDate]
      ,s.[AuditDate]
      ,s.[CL_EN_GEN_ID]
      ,s.[SiteID]
      ,s.[ProgramID]
      ,s.[IA_StaffID]
      ,survey_views.f_hash_field(@p_Encrypt, s.[ClientID]) as [ClientID]
      ,s.[RespondentID]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_0_ID_NSO]) as [CLIENT_0_ID_NSO]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_PERSONAL_0_NAME_FIRST]) as  [CLIENT_PERSONAL_0_NAME_FIRST]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_PERSONAL_0_NAME_LAST]) as [CLIENT_PERSONAL_0_NAME_LAST]
      ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,s.[NURSE_PERSONAL_0_NAME]
      ,s.[CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER]
      ,s.[CLIENT_ABUSE_HIT_0_SLAP_PARTNER]
      ,s.[CLIENT_ABUSE_TIMES_0_HURT_LAST_YR]
      ,s.[CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER]
      ,s.[CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER]
      ,s.[CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER]
      ,s.[CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER]
      ,s.[CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER]
      ,s.[CLIENT_ABUSE_FORCED_0_SEX]
      ,s.[CLIENT_ABUSE_FORCED_1_SEX_LAST_YR]
      ,s.[CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME]
      ,s.[CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME]
      ,s.[CLIENT_ABUSE_AFRAID_0_PARTNER]
      ,survey_views.f_hash_field(@p_Encrypt, s.[CLIENT_0_ID_AGENCY]) as [CLIENT_0_ID_AGENCY]
      --,s.[ABUSE_EMOTION_0_PHYSICAL_PARTNER]
      --,s.[DW_AuditDate]
      --,s.[DataSource]
      --,s.[Master_SurveyID]  
from survey_views.Relationship_Assessment s
where
s.SiteID in (select s.siteid from survey_views.f_get_sites_for_profile_id(@p_Profile_Id, @p_exclude_tribal) s)



end 
GO
