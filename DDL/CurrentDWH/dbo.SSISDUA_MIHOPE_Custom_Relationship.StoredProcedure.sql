USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISDUA_MIHOPE_Custom_Relationship]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Jingjing
-- Create date: 03/10/2017
-- Description:	Extract of Relationship data where the SiteID from [Relationship_Survey] is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- Export Requirements:
-- 1)	De-identified data for customer
-- 2)	Provide the same data set with identifiable data on the S drive for the NSO
-- 3)	Join with MIHOPE provided table to provide the MIHOPE ID with the corresponding NSO ID (which will be hashed)
-- 4)	We need to provide a table so they can cross reference EntityID with Nurse Name 
-- 5)	Parameter on the export – no SurveyDates or ProgramStartDates after 12/31/2016
-- 6)	Parameter on the export – only data from the following siteIDs and only data for the provided CLID/CL_EN_GENs/ClientId (SiteIDs: 289, 179, 185, 103, 163, 212, 251, 287)
-- =============================================
CREATE PROCEDURE [dbo].[SSISDUA_MIHOPE_Custom_Relationship]
	-- Add the parameters for the stored procedure here
	@ProfileID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT [SurveyResponseID]
		  ,[ElementsProcessed]
		  ,[SurveyID]
		  ,[SurveyDate]
		  ,[AuditDate]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CL_EN_GEN_ID])) AS [CL_EN_GEN_ID]
		  ,StudyID
		  ,[SiteID]
		  ,[ProgramID]
		  ,[IA_StaffID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[ClientID])) AS [ClientID]
		  ,[RespondentID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_NSO])) AS [CLIENT_0_ID_NSO]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_FIRST])) AS [CLIENT_PERSONAL_0_NAME_FIRST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_LAST])) AS [CLIENT_PERSONAL_0_NAME_LAST]
		  ,[CLIENT_PERSONAL_0_DOB_INTAKE]
		  ,[NURSE_PERSONAL_0_NAME]
		  ,[CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER]
		  ,[CLIENT_ABUSE_HIT_0_SLAP_PARTNER]
		  ,[CLIENT_ABUSE_TIMES_0_HURT_LAST_YR]
		  ,[CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER]
		  ,[CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER]
		  ,[CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER]
		  ,[CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER]
		  ,[CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER]
		  ,[CLIENT_ABUSE_FORCED_0_SEX]
		  ,[CLIENT_ABUSE_FORCED_1_SEX_LAST_YR]
		  ,[CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME]
		  ,[CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME]
		  ,[CLIENT_ABUSE_AFRAID_0_PARTNER]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_AGENCY])) AS [CLIENT_0_ID_AGENCY]
		  ,[ABUSE_EMOTION_0_PHYSICAL_PARTNER]
		  ,[DW_AuditDate]
		  ,[DataSource]
		  ,[Master_SurveyID]
	  FROM [DataWarehouse].[dbo].[Relationship_Survey] s
	  		  INNER JOIN [DataWarehouse].[dbo].[MIHOPE_Custom_Extract_Clients] m
      ON s.CL_EN_GEN_ID = m.Clientid_NFP
	  WHERE SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	   AND ProgramID NOT IN (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	   AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
	   AND CL_EN_GEN_ID IN (SELECT [Clientid_NFP] FROM [DataWarehouse].[dbo].[MIHOPE_Custom_Extract_Clients])
	  AND [SurveyDate] < '20170101'
	  ORDER BY SurveyDate

END

GO
