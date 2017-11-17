USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISDUA_MaternalHealth]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of MaternalHealth data where the SiteID from Maternal_Health_Survey is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSISDUA_MaternalHealth]
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
		  ,[CLIENT_HEALTH_PREGNANCY_0_LIVE_BIRTHS]
		  ,[CLIENT_HEALTH_PREGNANCY_0_DOCTOR_VISIT]
		  ,[CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE]
		  ,[CLIENT_HEALTH_PREGNANCY_0_EDD]
		  ,[CLIENT_HEALTH_GENERAL_0_CONCERNS]
		  ,[CLIENT_HEALTH_GENERAL_WEIGHT_0_POUNDS]
		  ,[CLIENT_HEALTH_BELIEF_0_LITTLE_CONTROL]
		  ,[CLIENT_HEALTH_BELIEF_0_CANT_SOLVE]
		  ,[CLIENT_HEALTH_BELIEF_0_LITTLE_CAN_DO]
		  ,[CLIENT_HEALTH_BELIEF_0_FEEL_HELPLESS]
		  ,[CLIENT_HEALTH_BELIEF_0_FEEL_PUSHED_AROUND]
		  ,[CLIENT_HEALTH_BELIEF_0_FUTURE_CONTROL]
		  ,[CLIENT_HEALTH_BELIEF_ 0_DO_ANYTHING]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_HEALTH_GENERAL_0_OTHER])) AS [CLIENT_HEALTH_GENERAL_0_OTHER]
		  ,[CLIENT_HEALTH_GENERAL_HEIGHT_0_FEET]
		  ,[CLIENT_HEALTH_GENERAL_HEIGHT_1_INCHES]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_AGENCY])) AS [CLIENT_0_ID_AGENCY]
		  ,[DW_AuditDate]
		  ,[DataSource]
		  ,[LA_CTY_MENTAL_MAT_HEALTH]
		  ,[LA_CTY_PHYSICAL_MAT_HEALTH]
		  ,[LA_CTY_DX_OTHER_MAT_HEALTH]
		  ,[LA_CTY_DSM_DX_MAT_HEALTH]
		  ,[CLIENT_HEALTH_GENERAL_0_PRE_GEST_BP]
		  ,[CLIENT_HEALTH_GENERAL_0_PRE_GEST_DIABETES]
		  ,[CLIENT_HEALTH_GENERAL_0_PRE_GEST_HEART]
		  ,[CLIENT_HEALTH_GENERAL_0_PRE_GEST_KIDNEYS]
		  ,[CLIENT_HEALTH_GENERAL_0_PRE_GEST_STI]
		  ,[CLIENT_HEALTH_GENERAL_0_PRE_GEST_UTI]
		  ,[CLIENT_HEALTH_GENERAL_0_PRE_GEST_VI]
		  ,[CLIENT_HEALTH_GENERAL_CURRENT_WEIGHT_0_POUNDS]
		  ,[Master_SurveyID]
		  ,[CLIENT_HEALTH_GENERAL_0_CONCERNS2]
		  ,[CLIENT_HEALTH_GENERAL_0_ADDICTION]
		  ,[CLIENT_HEALTH_GENERAL_0_MENTAL_HEALTH]  
	  FROM [DataWarehouse].[dbo].[Maternal_Health_Survey] s
	 WHERE SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	   AND ProgramID NOT IN (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	   AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)

END
GO
