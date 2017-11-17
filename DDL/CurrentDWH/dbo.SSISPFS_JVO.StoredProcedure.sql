USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFS_JVO]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Sheri Scott
-- Create date: 10/05/2016
-- Description:	Extract of JVO data where the SiteID from JVO_Survey is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- Modify date: 11/01/2016
-- By: Jingjing Gao
-- Description: Modify store proc per ETO "Blueprint_October 2016 Release_09012016.xls" located on S:\IT\ETO\Release 8 (Oct 2016)\Requirements
-- ×××××××××××××××××××××××××××××××××××××××××××××
-- Modified by: Jingjing Gao
-- Modified date:12/21/2016
-- Description: Add a filter include records only from Assessment Date: 1/1/2016 forward requested by Joie
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFS_JVO]
	@ProfileID INT
AS
BEGIN

	SET NOCOUNT ON;
	
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
      ,s.[DW_AuditDate]
      ,s.[DataSource]
      ,[Entity_ID_Mapped]
      ,[JVO_ADDITIONAL_REASON]
      ,[JVO_MI_CLIENT_PRIN_SCORE]
      ,[JVO_PARENT_CHILD_SCORE]
      ,[JVO_THERAPEUTIC_CHAR_SCORE]
      ,[JVO_VISIT_STRUCTURE_SCORE]
      ,[JVO_CLIENT_CASE]
      ,[JVO_CLIENT_NAME]
      ,[JVO_OBSERVER_NAME_OTHER]
      ,[JVO_START_TIME]
      ,[JVO_CLINICAL_CHART_CONSISTENT_COMMENTS]
      ,[JVO_HVEF_CONSISTENT_COMMENTS]
      ,[JVO_MI_CLIENT_PRIN_COMMENTS]
      ,[JVO_OTHER_OBSERVATIONS]
      ,[JVO_PARENT_CHILD_COMMENTS]
      ,[JVO_THERAPEUTIC_CHAR_COMMENTS]
      ,[JVO_VISIT_STRUCTURE_COMMENTS]
      ,[JVO_CLINICAL_CHART_CONSISTENT]
      ,[JVO_HVEF_CONSISTENT]
      ,[JVO_OBSERVER_NAME]
      ,[Master_SurveyID]
      ,[Archive_Record]
  FROM [DataWarehouse].[dbo].[JVO_Survey] s
  WHERE SiteID in (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
					  WHERE ExportProfileID = @ProfileID)  AND [SurveyDate] > '1/1/2016'
	
END

GO
