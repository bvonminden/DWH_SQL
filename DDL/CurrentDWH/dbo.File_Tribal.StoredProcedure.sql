USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[File_Tribal]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of [Tribal] data where the SiteID from [Tribal_survey] is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- =============================================
CREATE PROCEDURE [dbo].[File_Tribal]
	-- Add the parameters for the stored procedure here
	@SiteID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
--DECLARE @ProfileID INT
--SET @ProfileID = 27

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
      ,[DW_AuditDate]
      ,[CLIENT_TRIBAL_0_PARITY]
      ,[CLIENT_PERSONAL_0_NAME_FIRST]
      ,[CLIENT_PERSONAL_0_NAME_LAST]
      ,[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,[NURSE_PERSONAL_0_NAME]
      ,[DataSource]
      ,[CLIENT_TRIBAL_CHILD_1_LIVING]
      ,[CLIENT_TRIBAL_CHILD_10_LIVING]
      ,[CLIENT_TRIBAL_CHILD_2_LIVING]
      ,[CLIENT_TRIBAL_CHILD_3_LIVING]
      ,[CLIENT_TRIBAL_CHILD_4_LIVING]
      ,[CLIENT_TRIBAL_CHILD_5_LIVING]
      ,[CLIENT_TRIBAL_CHILD_6_LIVING]
      ,[CLIENT_TRIBAL_CHILD_7_LIVING]
      ,[CLIENT_TRIBAL_CHILD_8_LIVING]
      ,[CLIENT_TRIBAL_CHILD_9_LIVING]
      ,[CLIENT_TRIBAL_CHILD_1_DOB]
      ,[CLIENT_TRIBAL_CHILD_10_DOB]
      ,[CLIENT_TRIBAL_CHILD_2_DOB]
      ,[CLIENT_TRIBAL_CHILD_3_DOB]
      ,[CLIENT_TRIBAL_CHILD_4_DOB]
      ,[CLIENT_TRIBAL_CHILD_5_DOB]
      ,[CLIENT_TRIBAL_CHILD_6_DOB]
      ,[CLIENT_TRIBAL_CHILD_7_DOB]
      ,[CLIENT_TRIBAL_CHILD_8_DOB]
      ,[CLIENT_TRIBAL_CHILD_9_DOB]
      ,[Master_SurveyID]
FROM [DataWarehouse].[dbo].[Tribal_Survey]
WHERE SiteID = @SiteID

END



GO
