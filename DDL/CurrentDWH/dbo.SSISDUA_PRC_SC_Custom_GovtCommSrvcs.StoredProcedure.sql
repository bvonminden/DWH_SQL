USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISDUA_PRC_SC_Custom_GovtCommSrvcs]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Jingjing Gao
-- Create date: 04/04/2017
-- Description:	Extract of Client for PRC SC sites;
-- Export Requirements: 
-- 1)	De-identified data for customer
-- 2)	South Carolina sites only. Site IDs: 218, 219,235,236,242,243,296,384,385,413 (PRC CONFIRMING)
-- =============================================
CREATE PROCEDURE [dbo].[SSISDUA_PRC_SC_Custom_GovtCommSrvcs]
	-- Add the parameters for the stored procedure here
	@ProfileID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT [SurveyResponseID]
		  --,[ElementsProcessed]
		  ,[SurveyID]
		  ,[SurveyDate]
		  --,[AuditDate]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CL_EN_GEN_ID])) AS [CL_EN_GEN_ID]
		  ,[SiteID]
		  ,[ProgramID]
		  --,[IA_StaffID]
		  --,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[ClientID])) AS [ClientID]
		  --,[RespondentID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_NSO])) AS [CLIENT_0_ID_NSO]
		  --,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_FIRST])) AS [CLIENT_PERSONAL_0_NAME_FIRST]
		  --,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_LAST])) AS [CLIENT_PERSONAL_0_NAME_LAST]
		  ,[NURSE_PERSONAL_0_NAME]
		  --,[SERVICE_USE_0_TANF_CLIENT]
		  --,[SERVICE_USE_0_FOODSTAMP_CLIENT]
		  --,[SERVICE_USE_0_SOCIAL_SECURITY_CLIENT]
		  --,[SERVICE_USE_0_UNEMPLOYMENT_CLIENT]
		  --,[SERVICE_USE_0_SUBSID_CHILD_CARE_CLIENT]
		  ,[SERVICE_USE_0_IPV_CLIENT]
		  --,[SERVICE_USE_0_CPS_CLIENT]
		  --,[SERVICE_USE_0_CPS_CHILD]
		  ,[SERVICE_USE_0_MENTAL_CLIENT]
		  ,[SERVICE_USE_0_RELATIONSHIP_COUNSELING_CLIENT]
		  ,[SERVICE_USE_0_SMOKE_CLIENT]
		  ,[SERVICE_USE_0_ALCOHOL_ABUSE_CLIENT]
		  ,[SERVICE_USE_0_DRUG_ABUSE_CLIENT]
		  ,[SERVICE_USE_0_MEDICAID_CLIENT]
		  ,[SERVICE_USE_0_MEDICAID_CHILD]
		  --,[SERVICE_USE_0_SCHIP_CLIENT]
		  --,[SERVICE_USE_0_SCHIP_CHILD]
		  --,[SERVICE_USE_0_SPECIAL_NEEDS_CLIENT]
		  --,[SERVICE_USE_0_SPECIAL_NEEDS_CHILD]
		  --,[SERVICE_USE_0_PCP_CLIENT]
		  --,[SERVICE_USE_0_PCP_SICK_CHILD]
		  --,[SERVICE_USE_0_PCP_WELL_CHILD]
		  --,[SERVICE_USE_0_DEVELOPMENTAL_DISABILITY_CLIENT]
		  --,[SERVICE_USE_0_WIC_CLIENT]
		  --,[SERVICE_USE_0_CHILD_CARE_CLIENT]
		  --,[SERVICE_USE_0_JOB_TRAINING_CLIENT]
		  --,[SERVICE_USE_0_HOUSING_CLIENT]
		  --,[SERVICE_USE_0_TRANSPORTATION_CLIENT]
		  --,[SERVICE_USE_0_PREVENT_INJURY_CLIENT]
		  --,[SERVICE_USE_0_BIRTH_EDUC_CLASS_CLIENT]
		  --,[SERVICE_USE_0_LACTATION_CLIENT]
		  --,[SERVICE_USE_0_GED_CLIENT]
		  --,[SERVICE_USE_0_HIGHER_EDUC_CLIENT]
		  --,[SERVICE_USE_0_CHARITY_CLIENT]
		  --,[SERVICE_USE_0_LEGAL_CLIENT]
		  --,[SERVICE_USE_0_PATERNITY_CLIENT]
		  --,[SERVICE_USE_0_CHILD_SUPPORT_CLIENT]
		  --,[SERVICE_USE_0_ADOPTION_CLIENT]
		  --,[SERVICE_USE_0_OTHER1_DESC]
		  --,[SERVICE_USE_0_OTHER1]
		  --,[SERVICE_USE_0_CHILD_OTHER1]
		  --,[SERVICE_USE_0_OTHER2_DESC]
		  --,[SERVICE_USE_0_OTHER3_DESC]
		  --,[SERVICE_USE_0_OTHER2]
		  --,[SERVICE_USE_0_CHILD_OTHER2]
		  --,[SERVICE_USE_0_OTHER3]
		  --,[SERVICE_USE_0_CHILD_OTHER3]
		  --,[SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT]
		  --,[SERVICE_USE_0_PRIVATE_INSURANCE_CHILD]
		  --,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_AGENCY])) AS [CLIENT_0_ID_AGENCY]
		  --,[CLIENT_PERSONAL_0_DOB_INTAKE]
		  --,[SERVICE_USE_0_DENTAL_CLIENT]
		  --,[SERVICE_USE_0_INTERVENTION]
		  --,[SERVICE_USE_0_PCP_WELL_CLIENT]
		  --,[SERVICE_USE_0_DENTAL_CHILD]
		  --,[DW_AuditDate]
		  --,[DataSource]
		  --,[JP error  if no data associated delete element]
		  --,[SERVICE_USE_INDIAN_HEALTH_CHILD]
		  --,[SERVICE_USE_INDIAN_HEALTH_CLIENT]
		  --,[SERVICE_USE_MILITARY_INS_CHILD]
		  --,[SERVICE_USE_MILITARY_INS_CLIENT ]
		  --,[SERVICE_USE_PCP_CLIENT_POSTPARTUM]
		  --,[SERVICE_USE_PCP_CLIENT_PRENATAL]
		  --,[SERVICE_USE_PCP_CLIENT_WELLWOMAN]
		  --,[Master_SurveyID]
		  --,[Archive_Record]						/*****new columns added on 12/9/2016 according to Ticket#33134.*******/
    --      ,[SERVICE_USE_0_INTERVENTION_45DAYS]	/*****new columns added on 12/9/2016 according to Ticket#33134.*******/
	  FROM [DataWarehouse].[dbo].[Govt_Comm_Srvcs_Survey] s
	 WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	   AND ProgramID NOT IN (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	   AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)

END

GO
