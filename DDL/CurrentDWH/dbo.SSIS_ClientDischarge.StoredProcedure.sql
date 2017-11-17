USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSIS_ClientDischarge]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mike Osborn
-- Create date: 09/24/2013
-- Description:	Extract of ClientDischarge data where the SiteID from Client_Discharge_Survey is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- Modified by: Jingjing
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSIS_ClientDischarge]
	@ProfileID INT
AS
BEGIN

	SET NOCOUNT ON;
	
	SELECT [SurveyResponseID]
		  ,[ElementsProcessed]
		  ,[SurveyID]
		  ,[SurveyDate]
		  ,[AuditDate]
		  ,[CL_EN_GEN_ID]
		  ,[SiteID]
		  ,[ProgramID]
		  ,[IA_StaffID]
		  ,[ClientID]
		  ,[RespondentID]
		  ,[CLIENT_0_ID_NSO]
		  ,[CLIENT_PERSONAL_0_NAME_FIRST]
		  ,[CLIENT_PERSONAL_0_NAME_LAST]
		  ,[NURSE_PERSONAL_0_NAME]
		  ,[CLIENT_DISCHARGE_1_DATE]
		  ,[CLIENT_DISCHARGE_0_REASON]
		  ,[CLIENT_DISCHARGE_1_MISCARRIED_DATE]
		  ,[CLIENT_DISCHARGE_1_LOST_CUSTODY]
		  ,[CLIENT_DISCHARGE_1_MATERNAL_DEATH_DATE]
		  ,[CLIENT_DISCHARGE_1_INCARCERATION_DATE]
		  ,[CLIENT_DISCHARGE_1_UNABLE_REASON]
		  ,[NONE]
		  ,[CLIENT_PERSONAL_0_DOB_INTAKE]
		  ,[CLIENT_0_ID_AGENCY]
		  ,[CLIENT_DISCHARGE_1_LOST_CUSTODY_DATE]
		  ,[DW_AuditDate]
		  ,[DataSource]
		  ,[CLIENT_DISCHARGE_1_INFANTDEATH_DATE]
		  ,[CLIENT_DISCHARGE_1_MISCARRIED_DATE2]
		  ,[Master_SurveyID]
		  ,[CLIENT_DISCHARGE_1_INFANTDEATH_REASON]
		  ,[CLIENT_DISCHARGE_1_MATERNAL_DEATH_REASON]
	  FROM [DataWarehouse].[dbo].[Client_Discharge_Survey] s
	 WHERE SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	   AND ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	   AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
		
END
GO
