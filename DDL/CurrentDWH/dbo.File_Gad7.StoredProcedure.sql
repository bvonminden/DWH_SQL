USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[File_Gad7]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of Gad7 data where the SiteID from Gad7 Survey is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- =============================================
CREATE PROCEDURE [dbo].[File_Gad7]
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
      ,[CLIENT_GAD7_AFRAID]
      ,[CLIENT_GAD7_CTRL_WORRY]
      ,[CLIENT_GAD7_IRRITABLE]
      ,[CLIENT_GAD7_NERVOUS]
      ,[CLIENT_GAD7_PROBS_DIFFICULT]
      ,[CLIENT_GAD7_RESTLESS]
      ,[CLIENT_GAD7_TRBL_RELAX]
      ,[CLIENT_GAD7_WORRY]
      ,[CLIENT_0_ID_NSO]
      ,[CLIENT_PERSONAL_0_NAME_FIRST]
      ,[CLIENT_PERSONAL_0_NAME_LAST]
      ,[CLIENT_GAD7_TOTAL]
      ,[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,[NURSE_PERSONAL_0_NAME]
  FROM [DataWarehouse].[dbo].[GAD7_Survey]
  WHERE SiteID IN(@SiteID)
END


GO
