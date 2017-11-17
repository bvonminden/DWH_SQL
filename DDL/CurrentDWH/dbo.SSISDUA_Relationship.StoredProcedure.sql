USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISDUA_Relationship]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of Relationship data where the SiteID from [Relationship_Survey] is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSISDUA_Relationship]
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
	  WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	  and ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	  AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)

END
GO
