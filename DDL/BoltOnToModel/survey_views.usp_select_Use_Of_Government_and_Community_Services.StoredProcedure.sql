DROP PROCEDURE [survey_views].[usp_select_Use_Of_Government_and_Community_Services]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_select_Use_Of_Government_and_Community_Services]
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
      ,s.[ClientID]
     -- ,s.[RespondentID]
      ,s.[CLIENT_0_ID_NSO]
      ,s.[CLIENT_PERSONAL_0_NAME_FIRST]
      ,s.[CLIENT_PERSONAL_0_NAME_LAST]
      ,s.[NURSE_PERSONAL_0_NAME]
      ,s.[SERVICE_USE_0_TANF_CLIENT]
      ,s.[SERVICE_USE_0_FOODSTAMP_CLIENT]
      ,s.[SERVICE_USE_0_SOCIAL_SECURITY_CLIENT]
      ,s.[SERVICE_USE_0_UNEMPLOYMENT_CLIENT]
      ,s.[SERVICE_USE_0_SUBSID_CHILD_CARE_CLIENT]
      ,s.[SERVICE_USE_0_IPV_CLIENT]
      ,s.[SERVICE_USE_0_CPS_CLIENT]
      ,s.[SERVICE_USE_0_CPS_CHILD]
      ,s.[SERVICE_USE_0_MENTAL_CLIENT]
      ,s.[SERVICE_USE_0_RELATIONSHIP_COUNSELING_CLIENT]
      ,s.[SERVICE_USE_0_SMOKE_CLIENT]
      ,s.[SERVICE_USE_0_ALCOHOL_ABUSE_CLIENT]
      ,s.[SERVICE_USE_0_DRUG_ABUSE_CLIENT]
      ,s.[SERVICE_USE_0_MEDICAID_CLIENT]
      ,s.[SERVICE_USE_0_MEDICAID_CHILD]
      ,s.[SERVICE_USE_0_SCHIP_CLIENT]
      ,s.[SERVICE_USE_0_SCHIP_CHILD]
      ,s.[SERVICE_USE_0_SPECIAL_NEEDS_CLIENT]
      ,s.[SERVICE_USE_0_SPECIAL_NEEDS_CHILD]
      ,s.[SERVICE_USE_0_PCP_CLIENT]
      ,s.[SERVICE_USE_0_PCP_SICK_CHILD]
      ,s.[SERVICE_USE_0_PCP_WELL_CHILD]
      ,s.[SERVICE_USE_0_DEVELOPMENTAL_DISABILITY_CLIENT]
      ,s.[SERVICE_USE_0_WIC_CLIENT]
      ,s.[SERVICE_USE_0_CHILD_CARE_CLIENT]
      ,s.[SERVICE_USE_0_JOB_TRAINING_CLIENT]
      ,s.[SERVICE_USE_0_HOUSING_CLIENT]
      ,s.[SERVICE_USE_0_TRANSPORTATION_CLIENT]
      ,s.[SERVICE_USE_0_PREVENT_INJURY_CLIENT]
      ,s.[SERVICE_USE_0_BIRTH_EDUC_CLASS_CLIENT]
      ,s.[SERVICE_USE_0_LACTATION_CLIENT]
      ,s.[SERVICE_USE_0_GED_CLIENT]
      ,s.[SERVICE_USE_0_HIGHER_EDUC_CLIENT]
      ,s.[SERVICE_USE_0_CHARITY_CLIENT]
      ,s.[SERVICE_USE_0_LEGAL_CLIENT]
      ,s.[SERVICE_USE_0_PATERNITY_CLIENT]
      ,s.[SERVICE_USE_0_CHILD_SUPPORT_CLIENT]
      ,s.[SERVICE_USE_0_ADOPTION_CLIENT]
      ,s.[SERVICE_USE_0_OTHER1_DESC]
      ,s.[SERVICE_USE_0_OTHER1]
      ,s.[SERVICE_USE_0_CHILD_OTHER1]
      ,s.[SERVICE_USE_0_OTHER2_DESC]
      ,s.[SERVICE_USE_0_OTHER3_DESC]
      ,s.[SERVICE_USE_0_OTHER2]
      ,s.[SERVICE_USE_0_CHILD_OTHER2]
      ,s.[SERVICE_USE_0_OTHER3]
      ,s.[SERVICE_USE_0_CHILD_OTHER3]
      ,s.[SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT]
      ,s.[SERVICE_USE_0_PRIVATE_INSURANCE_CHILD]
      ,s.[CLIENT_0_ID_AGENCY]
      ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,s.[SERVICE_USE_0_DENTAL_CLIENT]
      ,s.[SERVICE_USE_0_INTERVENTION]
      ,s.[SERVICE_USE_0_PCP_WELL_CLIENT]
      ,s.[SERVICE_USE_0_DENTAL_CHILD]
     -- ,s.[DW_AuditDate]
     -- ,s.[DataSource]
     -- ,s.[JP error  if no data associated delete element]
      ,s.[SERVICE_USE_INDIAN_HEALTH_CHILD]
      ,s.[SERVICE_USE_INDIAN_HEALTH_CLIENT]
      ,s.[SERVICE_USE_MILITARY_INS_CHILD]
     -- ,s.[SERVICE_USE_MILITARY_INS_CLIENT ]
      ,s.[SERVICE_USE_PCP_CLIENT_POSTPARTUM]
      ,s.[SERVICE_USE_PCP_CLIENT_PRENATAL]
      ,s.[SERVICE_USE_PCP_CLIENT_WELLWOMAN]
      --,s.[Master_SurveyID]
     -- ,s.[Archive_Record]						
      ,s.[SERVICE_USE_0_INTERVENTION_45DAYS]	
from survey_views.Use_Of_Government_and_Community_Services s
where
s.SiteID in (select s.siteid from survey_views.f_get_sites_for_profile_id(@p_Profile_Id, @p_exclude_tribal) s)



end 
GO
