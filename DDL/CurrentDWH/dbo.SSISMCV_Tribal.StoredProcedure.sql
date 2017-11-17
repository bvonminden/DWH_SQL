USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISMCV_Tribal]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Michael Osborn
-- Create date: 2/15/2015
-- Description:	Extract of MICHVEI data where the SiteID from the Survey is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSISMCV_Tribal]
	@ProfileID INT
AS
BEGIN
	
	SET NOCOUNT ON;
	
	SELECT TS.[SurveyResponseID]
		  ,TS.[ElementsProcessed]
		  ,TS.[SurveyID]
		  ,TS.[SurveyDate]
		  ,TS.[AuditDate]
		  ,TS.[CL_EN_GEN_ID]
		  ,TS.[SiteID]
		  ,TS.[ProgramID]
		  ,TS.[IA_StaffID]
		  ,TS.[ClientID]
		  ,TS.[RespondentID]
		  ,TS.[DW_AuditDate]
		  ,TS.[CLIENT_TRIBAL_0_PARITY]
		  ,TS.[CLIENT_PERSONAL_0_NAME_FIRST]
		  ,TS.[CLIENT_PERSONAL_0_NAME_LAST]
		  ,TS.[CLIENT_PERSONAL_0_DOB_INTAKE]
		  ,TS.[NURSE_PERSONAL_0_NAME]
		  ,TS.[DataSource]
		  ,TS.[CLIENT_TRIBAL_CHILD_1_LIVING]
		  ,TS.[CLIENT_TRIBAL_CHILD_10_LIVING]
		  ,TS.[CLIENT_TRIBAL_CHILD_2_LIVING]
		  ,TS.[CLIENT_TRIBAL_CHILD_3_LIVING]
		  ,TS.[CLIENT_TRIBAL_CHILD_4_LIVING]
		  ,TS.[CLIENT_TRIBAL_CHILD_5_LIVING]
		  ,TS.[CLIENT_TRIBAL_CHILD_6_LIVING]
		  ,TS.[CLIENT_TRIBAL_CHILD_7_LIVING]
		  ,TS.[CLIENT_TRIBAL_CHILD_8_LIVING]
		  ,TS.[CLIENT_TRIBAL_CHILD_9_LIVING]
		  ,TS.[CLIENT_TRIBAL_CHILD_1_DOB]
		  ,TS.[CLIENT_TRIBAL_CHILD_10_DOB]
		  ,TS.[CLIENT_TRIBAL_CHILD_2_DOB]
		  ,TS.[CLIENT_TRIBAL_CHILD_3_DOB]
		  ,TS.[CLIENT_TRIBAL_CHILD_4_DOB]
		  ,TS.[CLIENT_TRIBAL_CHILD_5_DOB]
		  ,TS.[CLIENT_TRIBAL_CHILD_6_DOB]
		  ,TS.[CLIENT_TRIBAL_CHILD_7_DOB]
		  ,TS.[CLIENT_TRIBAL_CHILD_8_DOB]
		  ,TS.[CLIENT_TRIBAL_CHILD_9_DOB]
		  ,TS.[Master_SurveyID]
		FROM [DataWarehouse].[dbo].[Tribal_Survey] TS
		WHERE CL_EN_GEN_ID in (select CL_EN_GEN_ID from View_MIECHVP_Cleints 
						   where siteid in(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ISNULL(ExportDisabled,0) != 1)) 
		and TS.ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
		AND TS.CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = TS.SiteID)
  
END



GO
