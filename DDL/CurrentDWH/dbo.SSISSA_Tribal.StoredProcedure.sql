USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISSA_Tribal]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of [Tribal] data where the SiteID from [Tribal_survey] is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing Gao
-- Modified Date: 11/30/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSISSA_Tribal]
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
		  ,[RespondentID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[DW_AuditDate])) AS [DW_AuditDate]
		  ,[CLIENT_TRIBAL_0_PARITY]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_FIRST])) AS [CLIENT_PERSONAL_0_NAME_FIRST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_LAST])) AS [CLIENT_PERSONAL_0_NAME_LAST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_DOB_INTAKE])) AS [CLIENT_PERSONAL_0_DOB_INTAKE]
		  ,[NURSE_PERSONAL_0_NAME]
		  ,[DataSource]
		  ,[CLIENT_TRIBAL_CHILD_1_LIVING]
		  ,[CLIENT_TRIBAL_CHILD_10_LIVING]
		  ,[CLIENT_TRIBAL_CHILD_2_LIVING]
		  ,[CLIENT_TRIBAL_CHILD_3_LIVING]
		  ,[CLIENT_TRIBAL_CHILD_4_LIVING]
		  ,[CLIENT_TRIBAL_CHILD_5_LIVING]
		  ,[CLIENT_TRIBAL_CHILD_6_LIVING]
		  ,[CLIENT_TRIBAL_CHILD_7_LIVING]
		  ,[CLIENT_TRIBAL_CHILD_8_LIVING]
		  ,[CLIENT_TRIBAL_CHILD_9_LIVING]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_TRIBAL_CHILD_1_DOB])) AS [CLIENT_TRIBAL_CHILD_1_DOB]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_TRIBAL_CHILD_10_DOB])) AS [CLIENT_TRIBAL_CHILD_10_DOB]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_TRIBAL_CHILD_2_DOB])) AS [CLIENT_TRIBAL_CHILD_2_DOB]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_TRIBAL_CHILD_3_DOB])) AS [CLIENT_TRIBAL_CHILD_3_DOB]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_TRIBAL_CHILD_4_DOB])) AS [CLIENT_TRIBAL_CHILD_4_DOB]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_TRIBAL_CHILD_5_DOB])) AS [CLIENT_TRIBAL_CHILD_5_DOB]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_TRIBAL_CHILD_6_DOB])) AS [CLIENT_TRIBAL_CHILD_6_DOB]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_TRIBAL_CHILD_7_DOB])) AS [CLIENT_TRIBAL_CHILD_7_DOB]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_TRIBAL_CHILD_8_DOB])) AS [CLIENT_TRIBAL_CHILD_8_DOB]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_TRIBAL_CHILD_9_DOB])) AS [CLIENT_TRIBAL_CHILD_9_DOB]
		  ,[Master_SurveyID]
	FROM [DataWarehouse].[dbo].[Tribal_Survey] s
	WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	AND ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)

END
GO
