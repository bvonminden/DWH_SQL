USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[File_CAB_MEETINGS_SURVEY]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Sheri Scott
-- Create date: 12/3/2015
-- Description:	Extract of CAB Meeting Survey data where the SiteID from CAB Meeting Survey is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- =============================================
CREATE PROCEDURE [dbo].[File_CAB_MEETINGS_SURVEY]
	-- Add the parameters for the stored procedure here
	@SiteID INT
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
      ,[Entity_ID_Mapped]
      ,[CAB_MTG_DATE]
  FROM [DataWarehouse].[dbo].[CAB_MEETINGS_SURVEY]
 WHERE SiteID IN (@SiteID)
 
END


GO
