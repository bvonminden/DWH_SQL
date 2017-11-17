USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFSDUA_Relationship]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Sheri Scott
-- Create date: 1/13/2016
-- Description:	Extract of Relationship data where the SiteID from [Relationship_Survey] is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFSDUA_Relationship]
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
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_0_ID_NSO])) AS [CLIENT_0_ID_NSO]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_PERSONAL_0_NAME_FIRST])) AS [CLIENT_PERSONAL_0_NAME_FIRST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_PERSONAL_0_NAME_LAST])) AS [CLIENT_PERSONAL_0_NAME_LAST]
		  ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
		  ,s.[NURSE_PERSONAL_0_NAME]
		  ,s.[CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER]
		  ,s.[CLIENT_ABUSE_HIT_0_SLAP_PARTNER]
		  ,s.[CLIENT_ABUSE_TIMES_0_HURT_LAST_YR]
		  ,s.[CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER]
		  ,s.[CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER]
		  ,s.[CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER]
		  ,s.[CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER]
		  ,s.[CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER]
		  ,s.[CLIENT_ABUSE_FORCED_0_SEX]
		  ,s.[CLIENT_ABUSE_FORCED_1_SEX_LAST_YR]
		  ,s.[CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME]
		  ,s.[CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME]
		  ,s.[CLIENT_ABUSE_AFRAID_0_PARTNER]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLIENT_0_ID_AGENCY])) AS [CLIENT_0_ID_AGENCY]
		  ,s.[ABUSE_EMOTION_0_PHYSICAL_PARTNER]
		  ,s.[DW_AuditDate]
		  ,s.[DataSource]
		  ,s.[Master_SurveyID]
	FROM dbo.[Relationship_Survey] s
	INNER JOIN dbo.Clients c ON c.Client_Id = s.CLIENT_0_ID_NSO
	WHERE s.SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
						WHERE ExportProfileID = @ProfileID)
	AND c.PFS_STUDY_VULNERABLE_POP = 0

END


GO
