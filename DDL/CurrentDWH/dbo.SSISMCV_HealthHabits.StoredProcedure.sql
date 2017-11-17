USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISMCV_HealthHabits]    Script Date: 11/16/2017 10:44:32 AM ******/
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
CREATE PROCEDURE [dbo].[SSISMCV_HealthHabits]
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
		  ,[CL_EN_GEN_ID]
		  ,[SiteID]
		  ,[ProgramID]
		  ,[IA_StaffID]
		  ,[ClientID]
		  ,[RespondentID]
		  ,[CLIENT_0_ID_NSO]
		  ,[CLIENT_PERSONAL_0_NAME_FIRST]
		  ,[CLIENT_PERSONAL_0_NAME_LAST]
		  ,[CLIENT_PERSONAL_0_DOB_INTAKE]
		  ,[CLIENT_SUBSTANCE_CIG_1_PRE_PREG]
		  ,[CLIENT_SUBSTANCE_CIG_0_DURING_PREG]
		  ,[CLIENT_SUBSTANCE_CIG_1_LAST_48]
		  ,[CLIENT_SUBSTANCE_ALCOHOL_0_14DAY]
		  ,[CLIENT_SUBSTANCE_ALCOHOL_1_14DAY_DRINKS]
		  ,[CLIENT_SUBSTANCE_POT_0_14DAYS]
		  ,[CLIENT_SUBSTANCE_POT_1_14DAYS_JOINTS]
		  ,[CLIENT_SUBSTANCE_COCAINE_0_14DAY]
		  ,[CLIENT_SUBSTANCE_COCAINE_1_14DAY_TIMES]
		  ,[CLIENT_SUBSTANCE_OTHER_0_14DAY]
		  ,[CLIENT_SUBSTANCE_OTHER_1_14DAY_TIMES]
		  ,[NURSE_PERSONAL_0_NAME_LAST]
		  ,[CLIENT_0_ID_AGENCY]
		  ,[DW_AuditDate]
		  ,[DataSource]
		  ,[CLIENT_SUBSTANCE_NICOTINE_0_OTHER_TYPES]
		  ,[CLIENT_SUBSTANCE_NICOTINE_0_OTHER]
		  ,[Master_SurveyID]
	  FROM [DataWarehouse].[dbo].[Health_Habits_Survey] s
	 WHERE CL_EN_GEN_ID IN (select CL_EN_GEN_ID from View_MIECHVP_Cleints 
						     where siteid in(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ISNULL(ExportDisabled,0) != 1))
	   AND ProgramID NOT IN (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	   AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
	  
END

GO
