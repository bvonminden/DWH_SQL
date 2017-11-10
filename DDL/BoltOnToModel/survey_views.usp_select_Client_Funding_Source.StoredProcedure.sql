DROP PROCEDURE [survey_views].[usp_select_Client_Funding_Source]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Client_Funding_Source]
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
      ,s.[ClientID]
      ,s.[RespondentID]
      ,s.[CLIENT_FUNDING_0_SOURCE_MIECHVP_COM]
      ,s.[CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM]
    --  ,s.[CLIENT_FUNDING_0_SOURCE_OTHER]
     -- ,s.[CLIENT_FUNDING_0_SOURCE_OTHER_TXT]
      ,s.[CLIENT_FUNDING_1_END_MIECHVP_COM]
      ,s.[CLIENT_FUNDING_1_END_MIECHVP_FORM]
     -- ,s.[CLIENT_FUNDING_1_END_OTHER]
      ,s.[CLIENT_FUNDING_1_START_MIECHVP_COM]
      ,s.[CLIENT_FUNDING_1_START_MIECHVP_FORM]
      --,s.[CLIENT_FUNDING_1_START_OTHER]
      ,s.[NURSE_PERSONAL_0_NAME]
     -- ,s.[DW_AuditDate]
      --,s.[DataSource]
      ,s.[CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL]
      ,s.[CLIENT_FUNDING_1_END_MIECHVP_TRIBAL]
      ,s.[CLIENT_FUNDING_1_START_MIECHVP_TRIBAL]
      ,s.[CLIENT_FUNDING_0_SOURCE_OTHER1]
      ,s.[CLIENT_FUNDING_0_SOURCE_OTHER2]
      ,s.[CLIENT_FUNDING_0_SOURCE_OTHER3]
      ,s.[CLIENT_FUNDING_1_END_OTHER1]
      ,s.[CLIENT_FUNDING_1_END_OTHER2]
      ,s.[CLIENT_FUNDING_1_END_OTHER3]
      ,s.[CLIENT_FUNDING_1_START_OTHER1]
      ,s.[CLIENT_FUNDING_1_START_OTHER2]
      ,s.[CLIENT_FUNDING_1_START_OTHER3]
      --,s.[Master_SurveyID]
      ,s.[CLIENT_FUNDING_0_SOURCE_PFS]
      ,s.[CLIENT_FUNDING_1_END_PFS]
      ,s.[CLIENT_FUNDING_1_START_PFS]
      --,s.[Archive_Record]					   
	  ,s.[CLIENT_FUNDING_0_SOURCE_OTHER4]     
      ,s.[CLIENT_FUNDING_0_SOURCE_OTHER5]     
      ,s.[CLIENT_FUNDING_0_SOURCE_OTHER6]     
      ,s.[CLIENT_FUNDING_1_END_OTHER4]        
      ,s.[CLIENT_FUNDING_1_END_OTHER5]        
      ,s.[CLIENT_FUNDING_1_END_OTHER6]        
      ,s.[CLIENT_FUNDING_1_START_OTHER4]      
      ,s.[CLIENT_FUNDING_1_START_OTHER5]      
      ,s.[CLIENT_FUNDING_1_START_OTHER6]      
from survey_views.Client_Funding_Source s
where
s.SiteID in (select s.siteid from survey_views.f_get_sites_for_profile_id(@p_Profile_Id, @p_exclude_tribal) s)


end 
GO
