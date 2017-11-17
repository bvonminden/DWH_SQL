USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[File_TeamTransferRequestSurvey]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[File_TeamTransferRequestSurvey]
	-- Add the parameters for the stored procedure here
	@SiteID INT
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
      ,[Entity_ID_Mapped]
      ,[STAFF_XFER_CLIENTS]
      ,[STAFF_XFER_PRIMARY_ROLE]
      ,[STAFF_XFER_SECOND_ROLE]
      ,[STAFF_XFER_SUP_PROMO]
      ,[STAFF_XFER_NEW_TEAM_B]
      ,[STAFF_XFER_PRIMARY_FTE]
      ,[STAFF_XFER_SECOND_FTE]
      ,[STAFF_XFER_LAST_DAY_TEAM_A]
      ,[STAFF_XFER_START_DATE_TEAM_B]
      ,[STAFF_XFER_FROM_TEAM_A]
      ,[STAFF_XFER_NAME]
      ,[DISPOSITION_CODE_0]
      ,[Archive_Record]
  FROM [DataWarehouse].[dbo].[TeamTransferRequestSurvey]
  WHERE SiteID IN(@SiteID)
END

GO
