USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSIS_Star]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Mike Osborn
-- Create date: 1/13/2016
-- Description:	Extract of [Star_Survey] data where the SiteID from [Star_Survey] is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSIS_Star]
	@ProfileID INT
AS
BEGIN

	SET NOCOUNT ON;
	
SELECT S.[SurveyResponseID]
      ,S.[ElementsProcessed]
      ,S.[SurveyID]
      ,S.[Master_SurveyID]
      ,S.[SurveyDate]
      ,S.[AuditDate]
      ,S.[CL_EN_GEN_ID]
      ,S.[SiteID]
      ,S.[ProgramID]
      ,S.[IA_StaffID]
      ,S.[ClientID]
      ,S.[RespondentID]
      ,S.[DW_AuditDate]
      ,S.[DataSource]
      ,S.[CLIENT_GLOBAL_FACTORS]
      ,S.[CLIENT_CAREGIVING_FRIENDS_FAM]
      ,S.[CLIENT_CAREGIVING_RISK_LEVEL]
      ,S.[CLIENT_CAREGIVING_SERVICES_GOALS]
      ,S.[CLIENT_CAREGIVING_STAGE_CHANGE]
      ,S.[CLIENT_CAREGIVING_UNDERSTANDS_RISK]
      ,S.[CLIENT_CHLD_CARE_FRIENDS_FAM]
      ,S.[CLIENT_CHLD_CARE_RISK_LEVEL]
      ,S.[CLIENT_CHLD_CARE_SERVICES_GOALS]
      ,S.[CLIENT_CHLD_CARE_STAGE_CHANGE]
      ,S.[CLIENT_CHLD_CARE_UNDERSTANDS_RISK]
      ,S.[CLIENT_CHLD_HEALTH_FRIENDS_FAM]
      ,S.[CLIENT_CHLD_HEALTH_RISK_LEVEL]
      ,S.[CLIENT_CHLD_HEALTH_SERVICES_GOALS]
      ,S.[CLIENT_CHLD_HEALTH_STAGE_CHANGE]
      ,S.[CLIENT_CHLD_HEALTH_UNDERSTANDS_RISK]
      ,S.[CLIENT_CHLD_WELL_FRIENDS_FAM]
      ,S.[CLIENT_CHLD_WELL_RISK_LEVEL]
      ,S.[CLIENT_CHLD_WELL_SERVICES_GOALS]
      ,S.[CLIENT_CHLD_WELL_STAGE_CHANGE]
      ,S.[CLIENT_CHLD_WELL_UNDERSTANDS_RISK]
      ,S.[CLIENT_COMM_SVCS_FRIENDS_FAM]
      ,S.[CLIENT_COMM_SVCS_RISK_LEVEL]
      ,S.[CLIENT_COMM_SVCS_SERVICES_GOALS]
      ,S.[CLIENT_COMM_SVCS_STAGE_CHANGE]
      ,S.[CLIENT_COMM_SVCS_UNDERSTANDS_RISK]
      ,S.[CLIENT_COMPLICATION_ILL_FRIENDS_FAM]
      ,S.[CLIENT_COMPLICATION_ILL_RISK_LEVEL]
      ,S.[CLIENT_COMPLICATION_ILL_SERVICES_GOALS]
      ,S.[CLIENT_COMPLICATION_ILL_STAGE_CHANGE]
      ,S.[CLIENT_COMPLICATION_ILL_UNDERSTANDS_RISK]
      ,S.[CLIENT_CRIMINAL_FRIENDS_FAM]
      ,S.[CLIENT_CRIMINAL_RISK_LEVEL]
      ,S.[CLIENT_CRIMINAL_SERVICES_GOALS]
      ,S.[CLIENT_CRIMINAL_STAGE_CHANGE]
      ,S.[CLIENT_CRIMINAL_UNDERSTANDS_RISK]
      ,S.[CLIENT_DISABILITY_FRIENDS_FAM]
      ,S.[CLIENT_DISABILITY_RISK_LEVEL]
      ,S.[CLIENT_DISABILITY_SERVICES_GOALS]
      ,S.[CLIENT_DISABILITY_STAGE_CHANGE]
      ,S.[CLIENT_DISABILITY_UNDERSTANDS_RISK]
      ,S.[CLIENT_ECONOMIC_FRIENDS_FAM]
      ,S.[CLIENT_ECONOMIC_RISK_LEVEL]
      ,S.[CLIENT_ECONOMIC_SERVICES_GOALS]
      ,S.[CLIENT_ECONOMIC_STAGE_CHANGE]
      ,S.[CLIENT_ECONOMIC_UNDERSTANDS_RISK]
      ,S.[CLIENT_EDUC_FRIENDS_FAM]
      ,S.[CLIENT_EDUC_RISK_LEVEL]
      ,S.[CLIENT_EDUC_SERVICES_GOALS]
      ,S.[CLIENT_EDUC_STAGE_CHANGE]
      ,S.[CLIENT_EDUC_UNDERSTANDS_RISK]
      ,S.[CLIENT_ENGLIT_FRIENDS_FAM]
      ,S.[CLIENT_ENGLIT_RISK_LEVEL]
      ,S.[CLIENT_ENGLIT_SERVICES_GOALS]
      ,S.[CLIENT_ENGLIT_STAGE_CHANGE]
      ,S.[CLIENT_ENGLIT_UNDERSTANDS_RISK]
      ,S.[CLIENT_ENVIRO_HEALTH_FRIENDS_FAM]
      ,S.[CLIENT_ENVIRO_HEALTH_RISK_LEVEL]
      ,S.[CLIENT_ENVIRO_HEALTH_SERVICES_GOALS]
      ,S.[CLIENT_ENVIRO_HEALTH_STAGE_CHANGE]
      ,S.[CLIENT_ENVIRO_HEALTH_UNDERSTANDS_RISK]
      ,S.[CLIENT_HLTH_SVCS_FRIENDS_FAM]
      ,S.[CLIENT_HLTH_SVCS_RISK_LEVEL]
      ,S.[CLIENT_HLTH_SVCS_SERVICES_GOALS]
      ,S.[CLIENT_HLTH_SVCS_STAGE_CHANGE]
      ,S.[CLIENT_HLTH_SVCS_UNDERSTANDS_RISK]
      ,S.[CLIENT_HOME_SAFETY_FRIENDS_FAM]
      ,S.[CLIENT_HOME_SAFETY_RISK_LEVEL]
      ,S.[CLIENT_HOME_SAFETY_SERVICES_GOALS]
      ,S.[CLIENT_HOME_SAFETY_STAGE_CHANGE]
      ,S.[CLIENT_HOME_SAFETY_UNDERSTANDS_RISK]
      ,S.[CLIENT_HOMELESS_FRIENDS_FAM]
      ,S.[CLIENT_HOMELESS_RISK_LEVEL]
      ,S.[CLIENT_HOMELESS_SERVICES_GOALS]
      ,S.[CLIENT_HOMELESS_STAGE_CHANGE]
      ,S.[CLIENT_HOMELESS_UNDERSTANDS_RISK]
      ,S.[CLIENT_IPV_FRIENDS_FAM]
      ,S.[CLIENT_IPV_RISK_LEVEL]
      ,S.[CLIENT_IPV_SERVICES_GOALS]
      ,S.[CLIENT_IPV_STAGE_CHANGE]
      ,S.[CLIENT_IPV_UNDERSTANDS_RISK]
      ,S.[CLIENT_LONELY_FRIENDS_FAM]
      ,S.[CLIENT_LONELY_RISK_LEVEL]
      ,S.[CLIENT_LONELY_SERVICES_GOALS]
      ,S.[CLIENT_LONELY_STAGE_CHANGE]
      ,S.[CLIENT_LONELY_UNDERSTANDS_RISK]
      ,S.[CLIENT_MENTAL_HEALTH_FRIENDS_FAM]
      ,S.[CLIENT_MENTAL_HEALTH_RISK_LEVEL]
      ,S.[CLIENT_MENTAL_HEALTH_SERVICES_GOALS]
      ,S.[CLIENT_MENTAL_HEALTH_STAGE_CHANGE]
      ,S.[CLIENT_MENTAL_HEALTH_UNDERSTANDS_RISK]
      ,S.[CLIENT_PREGPLAN_FRIENDS_FAM]
      ,S.[CLIENT_PREGPLAN_RISK_LEVEL]
      ,S.[CLIENT_PREGPLAN_SERVICES_GOALS]
      ,S.[CLIENT_PREGPLAN_STAGE_CHANGE]
      ,S.[CLIENT_PREGPLAN_UNDERSTANDS_RISK]
      ,S.[CLIENT_SUBSTANCE_FRIENDS_FAM]
      ,S.[CLIENT_SUBSTANCE_RISK_LEVEL]
      ,S.[CLIENT_SUBSTANCE_SERVICES_GOALS]
      ,S.[CLIENT_SUBSTANCE_STAGE_CHANGE]
      ,S.[CLIENT_SUBSTANCE_UNDERSTANDS_RISK]
      ,S.[CLIENT_UNSAFE_NTWK_FRIENDS_FAM]
      ,S.[CLIENT_UNSAFE_NTWK_RISK_LEVEL]
      ,S.[CLIENT_UNSAFE_NTWK_SERVICES_GOALS]
      ,S.[CLIENT_UNSAFE_NTWK_STAGE_CHANGE]
      ,S.[CLIENT_UNSAFE_NTWK_UNDERSTANDS_RISK]
      ,S.[CLIENT_PERSONAL_0_NAME_FIRST]
      ,S.[CLIENT_PERSONAL_0_NAME_LAST]
      ,S.[CLIENT_0_ID_NSO]
      ,S.[CLIENT_0_ID_AGENCY]
      ,S.[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,S.[NURSE_PERSONAL_0_NAME]
       FROM [DataWarehouse].[dbo].[Star_Survey] S
  WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
  and ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
  AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = S.SiteID)

END

GO
