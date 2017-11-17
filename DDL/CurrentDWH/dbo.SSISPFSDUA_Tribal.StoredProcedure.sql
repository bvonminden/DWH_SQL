USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFSDUA_Tribal]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		Sheri Scott
-- Create date: 1/13/2016
-- Description:	Extract of [Tribal] data where the SiteID from [Tribal_survey] is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFSDUA_Tribal]
	@ProfileID INT
AS
BEGIN

	SET NOCOUNT ON;
	
	SELECT s.[SurveyResponseID]
		  ,s.[ElementsProcessed]
		  ,s.[SurveyID]
		  ,s.[SurveyDate]
		  ,s.[AuditDate]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CL_EN_GEN_ID])) AS [CL_EN_GEN_ID]
		  ,s.[SiteID]
		  ,s.[ProgramID]
		  ,s.[IA_StaffID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[ClientID])) AS [ClientID]
		  ,s.[RespondentID]
		  ,s.[DW_AuditDate]
		  ,s.[CLIENT_TRIBAL_0_PARITY]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_PERSONAL_0_NAME_FIRST])) AS [CLIENT_PERSONAL_0_NAME_FIRST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_PERSONAL_0_NAME_LAST])) AS [CLIENT_PERSONAL_0_NAME_LAST]
		  ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
		  ,s.[NURSE_PERSONAL_0_NAME]
		  ,s.[DataSource]
		  ,s.[CLIENT_TRIBAL_CHILD_1_LIVING]
		  ,s.[CLIENT_TRIBAL_CHILD_10_LIVING]
		  ,s.[CLIENT_TRIBAL_CHILD_2_LIVING]
		  ,s.[CLIENT_TRIBAL_CHILD_3_LIVING]
		  ,s.[CLIENT_TRIBAL_CHILD_4_LIVING]
		  ,s.[CLIENT_TRIBAL_CHILD_5_LIVING]
		  ,s.[CLIENT_TRIBAL_CHILD_6_LIVING]
		  ,s.[CLIENT_TRIBAL_CHILD_7_LIVING]
		  ,s.[CLIENT_TRIBAL_CHILD_8_LIVING]
		  ,s.[CLIENT_TRIBAL_CHILD_9_LIVING]
		  ,s.[CLIENT_TRIBAL_CHILD_1_DOB]
		  ,s.[CLIENT_TRIBAL_CHILD_10_DOB]
		  ,s.[CLIENT_TRIBAL_CHILD_2_DOB]
		  ,s.[CLIENT_TRIBAL_CHILD_3_DOB]
		  ,s.[CLIENT_TRIBAL_CHILD_4_DOB]
		  ,s.[CLIENT_TRIBAL_CHILD_5_DOB]
		  ,s.[CLIENT_TRIBAL_CHILD_6_DOB]
		  ,s.[CLIENT_TRIBAL_CHILD_7_DOB]
		  ,s.[CLIENT_TRIBAL_CHILD_8_DOB]
		  ,s.[CLIENT_TRIBAL_CHILD_9_DOB]
		  ,s.[Master_SurveyID]
	FROM dbo.[Tribal_Survey] s
	INNER JOIN dbo.Clients c ON c.Client_Id = s.CL_EN_GEN_ID
	WHERE s.SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
						WHERE ExportProfileID = @ProfileID)
	AND c.PFS_STUDY_VULNERABLE_POP = 0

END

GO
