USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISMCVSA_ClientDischarge]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Michael Osborn
-- Create date: 2/15/2015
-- Description:	Extract of MICHVEI data where the SiteID from the Survey is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing Gao
-- Modified Date: 11/30/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSISMCVSA_ClientDischarge]
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
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[SurveyDate])) AS [SurveyDate]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[AuditDate])) AS [AuditDate]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CL_EN_GEN_ID])) AS [CL_EN_GEN_ID]
		  ,[SiteID]
		  ,[ProgramID]
		  ,[IA_StaffID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[ClientID])) AS [ClientID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_NSO])) AS [CLIENT_0_ID_NSO]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_FIRST])) AS [CLIENT_PERSONAL_0_NAME_FIRST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_LAST])) AS [CLIENT_PERSONAL_0_NAME_LAST]
		  ,[NURSE_PERSONAL_0_NAME]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_DISCHARGE_1_DATE])) AS [CLIENT_DISCHARGE_1_DATE]
		  ,[CLIENT_DISCHARGE_0_REASON]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_DISCHARGE_1_MISCARRIED_DATE])) AS [CLIENT_DISCHARGE_1_MISCARRIED_DATE]
		  ,[CLIENT_DISCHARGE_1_LOST_CUSTODY]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_DISCHARGE_1_MATERNAL_DEATH_DATE])) AS [CLIENT_DISCHARGE_1_MATERNAL_DEATH_DATE]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_DISCHARGE_1_INCARCERATION_DATE])) AS [CLIENT_DISCHARGE_1_INCARCERATION_DATE]
		  ,[CLIENT_DISCHARGE_1_UNABLE_REASON]
		  ,[NONE]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_DOB_INTAKE])) AS [CLIENT_PERSONAL_0_DOB_INTAKE]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_AGENCY])) AS [CLIENT_0_ID_AGENCY]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_DISCHARGE_1_LOST_CUSTODY_DATE])) AS [CLIENT_DISCHARGE_1_LOST_CUSTODY_DATE]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[DW_AuditDate])) AS [DW_AuditDate]
		  ,[DataSource]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_DISCHARGE_1_INFANTDEATH_DATE])) AS [CLIENT_DISCHARGE_1_INFANTDEATH_DATE]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_DISCHARGE_1_MISCARRIED_DATE2])) AS [CLIENT_DISCHARGE_1_MISCARRIED_DATE2]
		  ,[Master_SurveyID]
		  ,[CLIENT_DISCHARGE_1_INFANTDEATH_REASON]
		  ,[CLIENT_DISCHARGE_1_MATERNAL_DEATH_REASON]
	 FROM [DataWarehouse].[dbo].[Client_Discharge_Survey] s
	WHERE CL_EN_GEN_ID in (select CL_EN_GEN_ID from View_MIECHVP_Cleints 
						   where siteid in(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ISNULL(ExportDisabled,0) != 1))
	  AND ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	  AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
 
END
GO
