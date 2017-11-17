USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISMCVSA_Tribal]    Script Date: 11/16/2017 10:44:32 AM ******/
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
CREATE PROCEDURE [dbo].[SSISMCVSA_Tribal]
	@ProfileID INT
AS
BEGIN
	
	SET NOCOUNT ON;
	
	SELECT TS.[SurveyResponseID]
		  ,TS.[ElementsProcessed]
		  ,TS.[SurveyID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),TS.[SurveyDate])) AS [SurveyDate]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),TS.[AuditDate])) AS [AuditDate]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),TS.[CL_EN_GEN_ID])) AS [CL_EN_GEN_ID]
		  ,TS.[SiteID]
		  ,TS.[ProgramID]
		  ,TS.[IA_StaffID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),TS.[ClientID])) AS [ClientID]
		  ,TS.[RespondentID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),TS.[DW_AuditDate])) AS [DW_AuditDate]
		  ,TS.[CLIENT_TRIBAL_0_PARITY]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),TS.[CLIENT_PERSONAL_0_NAME_FIRST])) AS [CLIENT_PERSONAL_0_NAME_FIRST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),TS.[CLIENT_PERSONAL_0_NAME_LAST])) AS [CLIENT_PERSONAL_0_NAME_LAST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),TS.[CLIENT_PERSONAL_0_DOB_INTAKE])) AS [CLIENT_PERSONAL_0_DOB_INTAKE]
		  ,TS.[NURSE_PERSONAL_0_NAME]
		  ,TS.[DataSource]
		  ,TS.[CLIENT_TRIBAL_CHILD_1_LIVING]
		  ,TS.[CLIENT_TRIBAL_CHILD_10_LIVING]
		  ,TS.[CLIENT_TRIBAL_CHILD_2_LIVING]
		  ,TS.[CLIENT_TRIBAL_CHILD_3_LIVING]
		  ,TS.[CLIENT_TRIBAL_CHILD_4_LIVING]
		  ,TS.[CLIENT_TRIBAL_CHILD_5_LIVING]
		  ,TS.[CLIENT_TRIBAL_CHILD_6_LIVING]
		  ,TS.[CLIENT_TRIBAL_CHILD_7_LIVING]
		  ,TS.[CLIENT_TRIBAL_CHILD_8_LIVING]
		  ,TS.[CLIENT_TRIBAL_CHILD_9_LIVING]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),TS.[CLIENT_TRIBAL_CHILD_1_DOB])) AS [CLIENT_TRIBAL_CHILD_1_DOB]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),TS.[CLIENT_TRIBAL_CHILD_10_DOB])) AS [CLIENT_TRIBAL_CHILD_10_DOB]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),TS.[CLIENT_TRIBAL_CHILD_2_DOB])) AS [CLIENT_TRIBAL_CHILD_2_DOB]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),TS.[CLIENT_TRIBAL_CHILD_3_DOB])) AS [CLIENT_TRIBAL_CHILD_3_DOB]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),TS.[CLIENT_TRIBAL_CHILD_4_DOB])) AS [CLIENT_TRIBAL_CHILD_4_DOB]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),TS.[CLIENT_TRIBAL_CHILD_5_DOB])) AS [CLIENT_TRIBAL_CHILD_5_DOB]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),TS.[CLIENT_TRIBAL_CHILD_6_DOB])) AS [CLIENT_TRIBAL_CHILD_6_DOB]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),TS.[CLIENT_TRIBAL_CHILD_7_DOB])) AS [CLIENT_TRIBAL_CHILD_7_DOB]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),TS.[CLIENT_TRIBAL_CHILD_8_DOB])) AS [CLIENT_TRIBAL_CHILD_8_DOB]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),TS.[CLIENT_TRIBAL_CHILD_9_DOB])) AS [CLIENT_TRIBAL_CHILD_9_DOB]
		  ,TS.[Master_SurveyID]
		FROM [DataWarehouse].[dbo].[Tribal_Survey] TS
		WHERE CL_EN_GEN_ID in (select CL_EN_GEN_ID from View_MIECHVP_Cleints 
						   where siteid in(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ISNULL(ExportDisabled,0) != 1)) 
		AND TS.ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
		AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = TS.SiteID)
  
END
GO
