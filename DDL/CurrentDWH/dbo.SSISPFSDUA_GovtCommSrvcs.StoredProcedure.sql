USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFSDUA_GovtCommSrvcs]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Create date: 1/13/2016
-- Description:	Extract of GovtComm data where the SiteID from [Govt_Comm_Srvcs_Survey] is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- ************************************************
-- Modified by: Jingjing Gao
-- Modified Date:12/9/2016
-- Description: Two columns are added in the form: "Archive_Record", "SERVICE_USE_0_INTERVENTION_45DAYS" and need to be reflected
--              in "GovtCommSrvcs" file in the data extract. According to Ticket#33134.
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFSDUA_GovtCommSrvcs]
	@ProfileID INT
AS
BEGIN

	SET NOCOUNT ON;
	
	SELECT s.[SurveyResponseID]
		  ,s.[ElementsProcessed]
		  ,s.[SurveyID]
		  ,s.[SurveyDate]
		  ,s.[AuditDate]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CL_EN_GEN_ID])) AS [CL_EN_GEN_ID]
		  ,s.[SiteID]
		  ,s.[ProgramID]
		  ,s.[IA_StaffID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[ClientID])) AS [ClientID]
		  ,s.[RespondentID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_0_ID_NSO])) AS [CLIENT_0_ID_NSO]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_PERSONAL_0_NAME_FIRST])) AS [CLIENT_PERSONAL_0_NAME_FIRST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_PERSONAL_0_NAME_LAST])) AS [CLIENT_PERSONAL_0_NAME_LAST]
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
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_0_ID_AGENCY])) AS [CLIENT_0_ID_AGENCY]
		  ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
		  ,s.[SERVICE_USE_0_DENTAL_CLIENT]
		  ,s.[SERVICE_USE_0_INTERVENTION]
		  ,s.[SERVICE_USE_0_PCP_WELL_CLIENT]
		  ,s.[SERVICE_USE_0_DENTAL_CHILD]
		  ,s.[DW_AuditDate]
		  ,s.[DataSource]
		  ,s.[JP error  if no data associated delete element]
		  ,s.[SERVICE_USE_INDIAN_HEALTH_CHILD]
		  ,s.[SERVICE_USE_INDIAN_HEALTH_CLIENT]
		  ,s.[SERVICE_USE_MILITARY_INS_CHILD]
		  ,s.[SERVICE_USE_MILITARY_INS_CLIENT ]
		  ,s.[SERVICE_USE_PCP_CLIENT_POSTPARTUM]
		  ,s.[SERVICE_USE_PCP_CLIENT_PRENATAL]
		  ,s.[SERVICE_USE_PCP_CLIENT_WELLWOMAN]
		  ,s.[Master_SurveyID]
		  ,s.[Archive_Record]						/*****new columns added on 12/9/2016 according to Ticket#33134.*******/
          ,s.[SERVICE_USE_0_INTERVENTION_45DAYS]	/*****new columns added on 12/9/2016 according to Ticket#33134.*******/
	FROM [DataWarehouse].[dbo].[Govt_Comm_Srvcs_Survey] s
	INNER JOIN dbo.Clients c
	on c.Client_Id = s.CLIENT_0_ID_NSO
	WHERE s.SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
						WHERE ExportProfileID = @ProfileID)
	AND c.PFS_STUDY_VULNERABLE_POP = 0
  
END


GO
