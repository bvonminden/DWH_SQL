USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSIS_MN24MosToddler]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of [MN24MosToddler] data where the SiteID from [MN24MosToddler] is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSIS_MN24MosToddler]
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
		  ,[MN_INFANT_INSURANCE_RESOURCE]
		  ,[MN_CLIENT_INSURANCE]
		  ,[MN_COMPLETED_EDUCATION_PROGRAMS]
		  ,[MN_INFANT_INSURANCE]
		  ,[MN_SITE]
		  ,[CLIENT_0_ID_NSO]
		  ,[CLIENT_PERSONAL_0_NAME_FIRST]
		  ,[CLIENT_PERSONAL_0_NAME_LAST]
		  ,[INFANT_0_ID_NSO]
		  ,[INFANT_PERSONAL_0_NAME_FIRST]
		  ,[INFANT_PERSONAL_0_NAME_LAST]
		  ,[MN_CLIENT_INSURANCE_RESOURCE_OTHER]
		  ,[MN_COMPLETED_EDUCATION_PROGRAMS_YES]
		  ,[MN_INFANT_0_ID_2]
		  ,[MN_INFANT_INSURANCE_RESOURCE_OTHER]
		  ,[MN_TEAM_NAME]
		  ,[MN_TOTAL_HV]
		  ,[MN_DATA_STAFF_PERSONAL_0_NAME]
		  ,[NURSE_PERSONAL_0_NAME]
	FROM [DataWarehouse].dbo.MN24MosToddler s
	WHERE SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
					  WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	  AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)

END

GO
