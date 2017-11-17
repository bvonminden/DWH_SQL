USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISDUA_PRC_SC_Custom_StaffUpdate]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Jingjing Gao
-- Create date: 04/03/2017
-- Description:	Extract of Client for PRC SC sites;
-- Export Requirements: 
-- 1)	De-identified data for customer
-- 2)	South Carolina sites only. Site IDs: 218, 219,235,236,242,243,296,384,385,413 (PRC CONFIRMING)
-- =============================================
CREATE PROCEDURE [dbo].[SSISDUA_PRC_SC_Custom_StaffUpdate]
	-- Add the parameters for the stored procedure here
	@ProfileID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
--DECLARE @ProfileID INT --Testing
--SET @ProfileID = 27    --Testing

SELECT [SurveyResponseID]
      ,[ElementsProcessed]
      ,[SurveyID]
      ,[SurveyDate]
      ,[AuditDate]
      ,[CL_EN_GEN_ID]
      ,[SiteID]
      ,[ProgramID]
      ,[IA_StaffID]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[ClientID])) AS [ClientID]
      ,[RespondentID]
      ,[Entity_ID_Mapped]
      ,[NURSE_STATUS_0_CHANGE_START_DATE]
      ,[NURSE_STATUS_0_CHANGE_LEAVE_START]
      ,[NURSE_STATUS_0_CHANGE_LEAVE_END]
      ,[NURSE_STATUS_0_CHANGE_TERMINATE_DATE]
      ,[NURSE_PROFESSIONAL_1_NEW_ROLE]
      ,[NURSE_PROFESSIONAL_1_HOME_VISITOR_FTE]
      ,[NURSE_PROFESSIONAL_1_SUPERVISOR_FTE]
      ,[NURSE_PROFESSIONAL_1_ADMIN_ASST_FTE]
      ,[NURSE_STATUS_0_CHANGE_SPECIFIC]
      ,[NURSE_EDUCATION_0_NURSING_DEGREES]
      ,[NURSE_EDUCATION_1_OTHER_DEGREES]
      ,[DISPOSITION_CODE_0]
      ,[ETO_LOGIN_DISABLED]
      ,[ETO_LOGIN_DISABLED_BY]
      ,[ETO_UPDATED]
      ,[ETO_UPDATED_BY]
      ,[CMS_UPDATED]
      ,[CMS_UPDATED_BY]
      ,[GEN_COMMENTS_0]
      ,[NURSE_PROFESSIONAL_1_OTHER_FTE]
      ,[DW_AuditDate]
      ,[DataSource]
      ,[NURSE_PROFESSIONAL_1_TOTAL_FTE]
      ,[NURSE_STATUS_0_CHANGE_TRANSFER]
      ,[Master_SurveyID]
      ,[NURSE_STATUS_TERM_REASON]
      ,[NURSE_PRIMARY_ROLE]
      ,[NURSE_SECONDARY_ROLE]
      ,[NURSE_STATUS_TERM_REASON_OTHER]
      ,[NURSE_PRIMARY_ROLE_FTE]
      ,[NURSE_SECONDARY_ROLE_FTE]
      ,[NURSE_TEAM_START_DATE]
      ,[NURSE_TEAM_NAME]
      ,[LastModified]
      ,[Archive_Record]
  FROM [DataWarehouse].[dbo].[Staff_Update_Survey]
  WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
  and ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)

END

GO
