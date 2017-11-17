USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISSA_MN18MosToddler]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of [MN18MosToddler] data where the SiteID from [MN18MosToddler] is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing Gao
-- Modified Date: 11/30/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSISSA_MN18MosToddler]
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
      ,[Master_SurveyID]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[SurveyDate])) AS [SurveyDate]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[AuditDate])) AS [AuditDate]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CL_EN_GEN_ID])) AS [CL_EN_GEN_ID]
      ,[SiteID]
      ,[ProgramID]
      ,[IA_StaffID]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[ClientID])) AS [ClientID]
      ,[RespondentID]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[DW_AuditDate])) AS [DW_AuditDate]
      ,[DataSource]
      ,[MN_CLIENT_INSURANCE_RESOURCE]
      ,[MN_INFANT_INSURANCE_RESOURCE]
      ,[MN_CLIENT_INSURANCE]
      ,[MN_COMPLETED_EDUCATION_PROGRAMS]
      ,[MN_INFANT_INSURANCE]
      ,[MN_SITE]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_NSO])) AS [CLIENT_0_ID_NSO]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_FIRST])) AS [CLIENT_PERSONAL_0_NAME_FIRST]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_LAST])) AS [CLIENT_PERSONAL_0_NAME_LAST]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_0_ID_NSO])) AS [INFANT_0_ID_NSO]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_PERSONAL_0_NAME_FIRST])) AS [INFANT_PERSONAL_0_NAME_FIRST]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_PERSONAL_0_NAME_LAST])) AS [INFANT_PERSONAL_0_NAME_LAST]
      ,[MN_CLIENT_INSURANCE_RESOURCE_OTHER]
      ,[MN_COMPLETED_EDUCATION_PROGRAMS_YES]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[MN_INFANT_0_ID_2])) AS [MN_INFANT_0_ID_2]
      ,[MN_INFANT_INSURANCE_RESOURCE_OTHER]
      ,[MN_TEAM_NAME]
      ,[MN_TOTAL_HV]
      ,[MN_DATA_STAFF_PERSONAL_0_NAME]
      ,[NURSE_PERSONAL_0_NAME]
	FROM [DataWarehouse].dbo.MN18MosToddler s
	WHERE SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)

END
GO
