USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISDUA_MIHOPE_Custom_ReferralsToServices]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Jingjing
-- Create date: 04/25/2017
-- Description:	Extract of [ReferralsToServices_Survey] data where the SiteID from [[ReferralsToServices_Survey]] is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- Export Requirements:
-- 1)	De-identified data for customer
-- 2)	Provide the same data set with identifiable data on the S drive for the NSO
-- 3)	Join with MIHOPE provided table to provide the MIHOPE ID with the corresponding NSO ID (which will be hashed)
-- 4)	We need to provide a table so they can cross reference EntityID with Nurse Name 
-- 5)	Parameter on the export – no SurveyDates or ProgramStartDates after 12/31/2016
-- 6)	Parameter on the export – only data from the following siteIDs and only data for the provided CLID/CL_EN_GENs/ClientId (SiteIDs: 289, 179, 185, 103, 163, 212, 251, 287)
-- =============================================
CREATE PROCEDURE [dbo].[SSISDUA_MIHOPE_Custom_ReferralsToServices]
	-- Add the parameters for the stored procedure here
	@ProfileID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT [SurveyResponseID]
      ,[ElementsProcessed]
      ,[SurveyID]
      ,[SurveyDate]
      ,[AuditDate]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CL_EN_GEN_ID])) AS [CL_EN_GEN_ID]
      ,[StudyID]
      ,[SiteID]
      ,[ProgramID]
      ,[IA_StaffID]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[ClientID])) AS [ClientID]
      ,[RespondentID]
      ,[SERVICE_REFER_0_TANF]
      ,[SERVICE_REFER_0_FOODSTAMP]
      ,[SERVICE_REFER_0_SOCIAL_SECURITY]
      ,[SERVICE_REFER_0_UNEMPLOYMENT]
      ,[SERVICE_REFER_0_SUBSID_CHILD_CARE]
      ,[SERVICE_REFER_0_IPV]
      ,[SERVICE_REFER_0_CPS]
      ,[SERVICE_REFER_0_MENTAL]
      ,[SERVICE_REFER_0_RELATIONSHIP_COUNSELING]
      ,[SERVICE_REFER_0_SMOKE]
      ,[SERVICE_REFER_0_ALCOHOL_ABUSE]
      ,[SERVICE_REFER_0_MEDICAID]
      ,[SERVICE_REFER_0_SCHIP]
      ,[SERVICE_REFER_0_PRIVATE_INSURANCE]
      ,[SERVICE_REFER_0_SPECIAL_NEEDS]
      ,[SERVICE_REFER_0_PCP]
      ,[SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY]
      ,[SERVICE_REFER_0_WIC_CLIENT]
      ,[SERVICE_REFER_0_CHILD_CARE]
      ,[SERVICE_REFER_0_JOB_TRAINING]
      ,[SERVICE_REFER_0_HOUSING]
      ,[SERVICE_REFER_0_TRANSPORTATION]
      ,[SERVICE_REFER_0_PREVENT_INJURY]
      ,[SERVICE_REFER_0_BIRTH_EDUC_CLASS]
      ,[SERVICE_REFER_0_LACTATION]
      ,[SERVICE_REFER_0_GED]
      ,[SERVICE_REFER_0_HIGHER_EDUC]
      ,[SERVICE_REFER_0_CHARITY]
      ,[SERVICE_REFER_0_LEGAL_CLIENT]
      ,[SERVICE_REFER_0_PATERNITY]
      ,[SERVICE_REFER_0_CHILD_SUPPORT]
      ,[SERVICE_REFER_0_ADOPTION]
      ,[SERIVCE_REFER_0_OTHER1_DESC]
      ,[SERIVCE_REFER_0_OTHER2_DESC]
      ,[SERIVCE_REFER_0_OTHER3_DESC]
      ,[SERVICE_REFER_0_DRUG_ABUSE]
      ,[SERVICE_REFER_0_OTHER]
      ,[REFERRALS_TO_0_FORM_TYPE]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_NSO])) AS [CLIENT_0_ID_NSO]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_FIRST])) AS [CLIENT_PERSONAL_0_NAME_FIRST]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_LAST])) AS [CLIENT_PERSONAL_0_NAME_LAST]
      --,[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_AGENCY])) AS [CLIENT_0_ID_AGENCY]
      ,[NURSE_PERSONAL_0_NAME]
      ,[SERVICE_REFER_0_DENTAL]
      ,[SERVICE_REFER_0_INTERVENTION]
      ,[DW_AuditDate]
      ,[DataSource]
      ,[SERVICE_REFER_0_PCP_R2]
      ,[SERVICE_REFER_INDIAN_HEALTH]
      ,[SERVICE_REFER_MILITARY_INS]
      ,[Master_SurveyID]
   FROM [DataWarehouse].[dbo].[Referrals_to_Services_Survey] s
		  INNER JOIN [DataWarehouse].[dbo].[MIHOPE_Custom_Extract_Clients] m
      ON s.CL_EN_GEN_ID = m.Clientid_NFP
	  WHERE SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	   AND ProgramID NOT IN (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	   AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
	   AND CL_EN_GEN_ID IN (SELECT [Clientid_NFP] FROM [DataWarehouse].[dbo].[MIHOPE_Custom_Extract_Clients])
	  AND [SurveyDate] < '20170101'
	  ORDER BY SurveyDate
   
END


GO
