USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSIS_DANCE]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of dance data where the SiteID from dance is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- Modified by: Jingjing
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSIS_DANCE]
	@ProfileID int
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
		  ,[CLIENT_CAC_NA]
		  ,[CLIENT_CI_NA]
		  ,[CLIENT_EPA_NA]
		  ,[CLIENT_NCCO_NA]
		  ,[CLIENT_NI_NA]
		  ,[CLIENT_NT_NA]
		  ,[CLIENT_NVC_NA]
		  ,[CLIENT_PC_NA]
		  ,[CLIENT_PO_NA]
		  ,[CLIENT_PRA_NA]
		  ,[CLIENT_RP_NA]
		  ,[CLIENT_SCA_NA]
		  ,[CLIENT_SE_NA]
		  ,[CLIENT_VE_NA]
		  ,[CLIENT_VEC_NA]
		  ,[CLIENT_VISIT_VARIABLES]
		  ,[CLIENT_LS_NA]
		  ,[CLIENT_RD_NA]
		  ,[CLIENT_VQ_NA]
		  ,[CLIENT_0_ID_NSO]
		  ,[CLIENT_PERSONAL_0_NAME_FIRST]
		  ,[CLIENT_PERSONAL_0_NAME_LAST]
		  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_CAC_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_CAC_COMMENTS]
		  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_CI_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_CI_COMMENTS]
		  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_EPA_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_EPA_COMMENTS]
		  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_LS_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_LS_COMMENTS]
		  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_NCCO_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_NCCO_COMMENTS]
		  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_NI_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_NI_COMMENTS]
		  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_NT_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_NT_COMMENTS]
		  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_NVC_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_NVC_COMMENTS]
		  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_PC_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_PC_COMMENTS]
		  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_PO_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_PO_COMMENTS]
		  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_PRA_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_PRA_COMMENTS]
		  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_RD_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_RD_COMMENTS]
		  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_RP_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_RP_COMMENTS]
		  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_SCA_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_SCA_COMMENTS]
		  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_SE_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_SE_COMMENTS]
		  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_VE_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_VE_COMMENTS]
		  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_VEC_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_VEC_COMMENTS]
		  ,REPLACE(REPLACE(REPLACE(s.[CLIENT_VQ_COMMENTS], CHAR(13), ' '), CHAR(10), ' '), CHAR(9), ' ') AS [CLIENT_VQ_COMMENTS]
		  ,[CLIENT_ACTIVITY_DURATION]
		  ,[CLIENT_CAC_PER]
		  ,[CLIENT_CHILD_AGE]
		  ,[CLIENT_CHILD_DURATION]
		  ,[CLIENT_CI_PER]
		  ,[CLIENT_EPA_PER]
		  ,[CLIENT_LS_PER]
		  ,[CLIENT_NCCO_PER]
		  ,[CLIENT_NI_PER]
		  ,[CLIENT_NT_PER]
		  ,[CLIENT_NVC_PER]
		  ,[CLIENT_PC_PER]
		  ,[CLIENT_PO_PER]
		  ,[CLIENT_PRA_PER]
		  ,[CLIENT_RD_PER]
		  ,[CLIENT_RP_PER]
		  ,[CLIENT_SCA_PER]
		  ,[CLIENT_SE_PER]
		  ,[CLIENT_VE_PER]
		  ,[CLIENT_VEC_PER]
		  ,[CLIENT_VQ_PER]
		  ,[NURSE_PERSONAL_0_NAME]
	  FROM [DataWarehouse].[dbo].[DANCE_survey] s
	  WHERE SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	  and ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	  AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
  
END

GO
