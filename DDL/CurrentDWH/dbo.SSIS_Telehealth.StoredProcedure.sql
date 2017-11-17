USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSIS_Telehealth]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Sheri Scott
-- Create date: 05/16/2016
-- Description:	Extract of Telehealth Pilot data where the SiteID from Agency_Profile_Survey is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSIS_Telehealth]
	@ProfileID INT
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT [SurveyResponseID]
		  ,[ElementsProcessed]
		  ,[SurveyID]
		  ,[Master_SurveyID]
		  ,[SurveyDate]
		  ,[AuditDate]
		  ,[CL_EN_GEN_ID]
		  ,[SiteID]
		  ,[ProgramID]
		  ,[IA_StaffID]
		  ,[ClientID]
		  ,[RespondentID]
		  ,[DW_AuditDate]
		  ,[DataSource]
		  ,[CLIENT_TELEHEALTH_REASON]
		  ,[CLIENT_TELEHEALTH_TYPE]
		  ,[CLIENT_0_ID_NSO]
		  ,[CLIENT_PERSONAL_0_NAME_FIRST]
		  ,[CLIENT_PERSONAL_0_NAME_LAST]
		  ,[CLIENT_TELEHEALTH_REASON_OTHER]
		  ,[CLIENT_TELEHEALTH_TYPE_OTHER]
		  ,[CLIENT_PERSONAL_0_DOB_INTAKE]
		  ,[NURSE_PERSONAL_0_NAME]
		  ,[LastModified]
	  FROM [DataWarehouse].[dbo].[Telehealth_Pilot_Form_Survey] s
	 WHERE SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
						WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	   AND ProgramID NOT IN (SELECT ProgramID FROM dbo.Export_Program_Exclusions WHERE ExportProfileID = @ProfileID)
	   AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
 
END
GO
