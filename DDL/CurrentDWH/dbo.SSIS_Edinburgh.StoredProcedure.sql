USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSIS_Edinburgh]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of Edinburgh data where the SiteID from Edinburgh_Survey is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSIS_Edinburgh]
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
		  ,[CLIENT_PERSONAL_0_NAME_FIRST]
		  ,[CLIENT_PERSONAL_0_NAME_LAST]
		  ,[CLIENT_PERSONAL_0_DOB_INTAKE]
		  ,[CLIENT_EPDS_1_ABLE_TO_LAUGH]
		  ,[CLIENT_EPDS_1_ENJOY_THINGS]
		  ,[CLIENT_EPDS_1_BLAME_SELF]
		  ,[CLIENT_EPDS_1_ANXIOUS_WORRIED]
		  ,[CLIENT_EPDS_1_SCARED_PANICKY]
		  ,[CLIENT_EPDS_1_THINGS_GETTING_ON_TOP]
		  ,[CLIENT_EPDS_1_DIFFICULTY_SLEEPING]
		  ,[CLIENT_EPDS_1_SAD_MISERABLE]
		  ,[CLIENT_EPDS_1_BEEN_CRYING]
		  ,[CLIENT_EPDS_1_HARMING_SELF]
		  ,[CLIENT_0_ID_NSO]
		  ,[NURSE_PERSONAL_0_NAME]
		  ,[CLIENT_0_ID_AGENCY]
		  ,[DW_AuditDate]
		  ,[DataSource]
		  ,[LA_CTY_OQ10_EDPS]
		  ,[LA_CTY_PHQ9_SCORE_EDPS]
		  ,[LA_CTY_STRESS_INDEX_EDPS]
		  ,[CLIENT_EPS_TOTAL_SCORE]
		  ,[Master_SurveyID]  
	 FROM [DataWarehouse].[dbo].[Edinburgh_Survey] s
	WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	  AND ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	  AND CL_EN_GEN_ID NOT IN (select ISNULL (ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)

END
GO
