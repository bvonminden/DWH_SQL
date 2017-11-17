USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISMCV_WA_MIECHV]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:
-- Create date: 09/8/2015
-- Description:	Extract of WA_MIECHV_Survey data where the SiteID from [WA_MIECHV_Survey] is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSISMCV_WA_MIECHV]
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
		  ,[CLIENT_O_ID_NSO]
		  ,[CLIENT_PERSONAL_O_NAME_FIRST]
		  ,[CLIENT_PERSONAL_O_NAME_LAST]
		  ,[WA_HVEF_SUPPLEMENT_DELAYED_PREG]
		  ,[WA_HVEF_SUPPLEMENT_IPV]
		  ,[CLIENT_PERSONAL_O_DOB_INTAKE]
		  ,[NURSE_PERSONAL_0_NAME]
	  FROM [DataWarehouse].[dbo].[WA_MIECHV_Survey] s
	 WHERE CL_EN_GEN_ID in (select CL_EN_GEN_ID from View_MIECHVP_Cleints 
						     where siteid in(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ISNULL(ExportDisabled,0) != 1))
	   AND ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	   AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)

END

GO
