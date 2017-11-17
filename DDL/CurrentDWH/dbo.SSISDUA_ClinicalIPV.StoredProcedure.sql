USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISDUA_ClinicalIPV]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Jingjing Gao
-- Create date: 12/09/2016
-- Description:	Extract of Clinical IPV data where the SiteID from [Clinical_IPV_Survey] is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				Relation survey is retired and is replaced with Clinical_IPV survey 
-- =============================================
CREATE PROCEDURE [dbo].[SSISDUA_ClinicalIPV]
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
      ,[Master_SurveyID]
      ,[SurveyDate]
      ,[AuditDate]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CL_EN_GEN_ID])) AS [CL_EN_GEN_ID]
      ,[SiteID]
      ,[ProgramID]
      ,[IA_StaffID]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[ClientID])) AS [ClientID]
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
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_NSO])) AS [CLIENT_0_ID_NSO]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_FIRST ])) AS [CLIENT_PERSONAL_0_NAME_FIRST ]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_LAST])) AS [CLIENT_PERSONAL_0_NAME_LAST]
      ,[IPV_Q1_4_SCORE]
      ,[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,[NURSE_PERSONAL_0_NAME]
  FROM [DataWarehouse].[dbo].[Clinical_IPV_Survey] s
	  WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	  and ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	  AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)

END

GO
