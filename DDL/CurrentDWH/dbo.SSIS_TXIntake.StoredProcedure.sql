USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSIS_TXIntake]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Sheri Scott
-- Create date: 6/29/2016
-- Description:	Extract of MICHVEI data where the SiteID from the Survey is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSIS_TXIntake]
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
      ,[MIECHV_INTAKE_COMM_REF]
      ,[CLIENT_0_ID_NSO]
      ,[CLIENT_PERSONAL_0_NAME_FIRST]
      ,[CLIENT_PERSONAL_0_NAME_LAST]
      ,[CLIENT_0_ID_AGENCY]
      ,[MIECHV_PFS_CONCRETE_INTAKE]
      ,[MIECHV_PFS_FAMILY_INTAKE]
      ,[MIECHV_PFS_SOCIAL_INTAKE]
      ,[MIECHV_SUPPORTED_BY_INCOME_INTAKE]
      ,[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,[NURSE_PERSONAL_0_NAME]
      ,[TX_FUNDING_SOURCE_INTAKE]
  FROM [DataWarehouse].[dbo].[TX_SupMiechvIntake_AgencySurvey] s
  WHERE CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)

END

GO
