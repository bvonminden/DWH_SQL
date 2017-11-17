USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISMCV_MNPrimaryCaregiverIntake]    Script Date: 11/16/2017 10:44:32 AM ******/
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
CREATE PROCEDURE [dbo].[SSISMCV_MNPrimaryCaregiverIntake]
	-- Add the parameters for the stored procedure here
	@ProfileID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--DECLARE @ProfileID AS INT
--SET @ProfileID = 27

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
		  ,[MN_CLIENT_INSURANCE_RESOURCE]
		  ,[MN_CLIENT_INSURANCE]
		  ,[MN_COMPLETED_EDUCATION_PROGRAMS]
		  ,[MN_SITE]
		  ,[CLIENT_0_ID_NSO]
		  ,[CLIENT_PERSONAL_0_NAME_FIRST]
		  ,[CLIENT_PERSONAL_0_NAME_LAST]
		  ,[MN_CLIENT_INSURANCE_RESOURCE_OTHER]
		  ,[MN_COMPLETED_EDUCATION_PROGRAMS_YES]
		  ,[MN_TEAM_NAME]
		  ,[CLIENT_0_ID_AGENCY]
		  ,[MN_HOUSEHOLD_SIZE]
		  ,[MN_WKS_PREGNANT]
		  ,[MN_DATA_STAFF_PERSONAL_0_NAME]
		  ,[NURSE_PERSONAL_0_NAME]
	  FROM [DataWarehouse].dbo.MNPrimaryCaregiverIntake s
	 where CL_EN_GEN_ID in (select CL_EN_GEN_ID from View_MIECHVP_Cleints 
                         where siteid in(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ISNULL(ExportDisabled,0) != 1))
	   AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)

END


GO
