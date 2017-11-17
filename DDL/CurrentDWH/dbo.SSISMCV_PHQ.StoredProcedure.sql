USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISMCV_PHQ]    Script Date: 11/16/2017 10:44:32 AM ******/
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
-- Modified by: Jingjing
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSISMCV_PHQ]
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
      ,[CLIENT_0_ID_AGENCY]
      ,[CLIENT_0_ID_NSO]
      ,[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,[CLIENT_PERSONAL_0_NAME_FIRST]
      ,[CLIENT_PERSONAL_0_NAME_LAST]
      ,[Need from Kim]
      ,[NeedFromKim]
      ,[CLIENT_PHQ9_0_TOTAL_SCORE]
      ,[CLIENT_PHQ9_1_CONCENTRATION]
      ,[CLIENT_PHQ9_1_DIFFICULTY]
      ,[CLIENT_PHQ9_1_FEEL_BAD]
      ,[CLIENT_PHQ9_1_FEEL_DEPRESSED]
      ,[CLIENT_PHQ9_1_FEEL_TIRED]
      ,[CLIENT_PHQ9_1_HURT_SELF]
      ,[CLIENT_PHQ9_1_LITTLE_INTEREST]
      ,[CLIENT_PHQ9_1_MOVE_SPEAK]
      ,[CLIENT_PHQ9_1_TROUBLE_EAT]
      ,[CLIENT_PHQ9_1_TROUBLE_SLEEP]
      ,[NURSE_PERSONAL_0_NAME]
      ,[DW_AuditDate]
      ,[DataSource]
      ,[Master_SurveyID]
	FROM [DataWarehouse].[dbo].[PHQ_Survey] s
	WHERE CL_EN_GEN_ID in (select CL_EN_GEN_ID from View_MIECHVP_Cleints 
						   where siteid in(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ISNULL(ExportDisabled,0) != 1))
	AND ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
  
END

GO
