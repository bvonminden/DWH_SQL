USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISSA_ASQ3]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of ASQ3 data where the SiteID from Client_Discharge_Survey is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing Gao
-- Modified Date: 11/30/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSISSA_ASQ3]
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
		  ,[DataSource]
		  ,[INFANT_HEALTH_NO_ASQ_COMM]
		  ,[INFANT_HEALTH_NO_ASQ_FINE]
		  ,[INFANT_HEALTH_NO_ASQ_GROSS]
		  ,[INFANT_HEALTH_NO_ASQ_PERSONAL]
		  ,[INFANT_HEALTH_NO_ASQ_PROBLEM]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_AGENCY])) AS [CLIENT_0_ID_AGENCY]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_NSO])) AS [CLIENT_0_ID_NSO]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_FIRST])) AS [CLIENT_PERSONAL_0_NAME_FIRST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_LAST])) AS [CLIENT_PERSONAL_0_NAME_LAST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_0_ID_NSO])) AS [INFANT_0_ID_NSO]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_PERSONAL_0_NAME_FIRST])) AS [INFANT_PERSONAL_0_NAME_FIRST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_PERSONAL_0_NAME_LAST])) AS [INFANT_PERSONAL_0_NAME_LAST]
		  ,[INFANT_AGES_STAGES_1_COMM]
		  ,[INFANT_AGES_STAGES_1_FMOTOR]
		  ,[INFANT_AGES_STAGES_1_GMOTOR]
		  ,[INFANT_AGES_STAGES_1_PSOCIAL]
		  ,[INFANT_AGES_STAGES_1_PSOLVE]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_BIRTH_0_DOB])) AS [INFANT_BIRTH_0_DOB]
		  ,[NURSE_PERSONAL_0_NAME]
		  ,[Master_SurveyID]
	   FROM [DataWarehouse].[dbo].[ASQ3_Survey] s
	  WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	  AND ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	  AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
	  
END
GO
