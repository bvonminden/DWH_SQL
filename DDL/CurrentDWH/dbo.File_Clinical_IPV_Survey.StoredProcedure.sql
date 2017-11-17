USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[File_Clinical_IPV_Survey]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[File_Clinical_IPV_Survey]
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
      ,[Archive_Record]
      ,[IPV_AFRAID]
      ,[IPV_CHILD_SAFETY]
      ,[IPV_CONTROLING]
      ,[IPV_FORCED_SEX]
      ,[IPV_INDICATED]
      ,[IPV_INSULTED]
      ,[IPV_PHYSICALLY_HURT]
      ,[IPV_PRN_REASON]
      ,[IPV_Q5_8_ANY_YES]
      ,[IPV_SCREAMED]
      ,[IPV_THREATENED]
      ,[IPV_TOOL_USED]
      ,[CLIENT_0_ID_NSO]
      ,[CLIENT_PERSONAL_0_NAME_FIRST ]
      ,[CLIENT_PERSONAL_0_NAME_LAST]
      ,[IPV_Q1_4_SCORE]
      ,[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,[NURSE_PERSONAL_0_NAME]
  FROM [DataWarehouse].[dbo].[Clinical_IPV_Survey]
  WHERE SiteID IN(@SiteID)
END

GO
