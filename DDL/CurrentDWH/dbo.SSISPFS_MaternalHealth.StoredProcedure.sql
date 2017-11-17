USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFS_MaternalHealth]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Sheri Scott
-- Create date: 1/13/2016
-- Description:	Extract of MaternalHealth data where the SiteID from Maternal_Health_Survey is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- *********************************************
-- Modified by: Jingjing Gao
-- Modified on: 02/14/2017
-- Description: Per Kyla's ticket#[00019665]:JPAL Raw Data Extract Modification, remove the filter "PFS_STUDY_VULNERABLE_POP = 0" because JPAL want to include all 
--              clients regardless the clients is vulnerable or not. 
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFS_MaternalHealth]
	@ProfileID INT
AS
BEGIN

	SET NOCOUNT ON;
	
	SELECT s.[SurveyResponseID]
      ,s.[ElementsProcessed]
      ,s.[SurveyID]
      ,s.[SurveyDate]
      ,s.[AuditDate]
      ,s.[CL_EN_GEN_ID]
      ,s.[SiteID]
      ,s.[ProgramID]
      ,s.[IA_StaffID]
      ,s.[ClientID]
      ,s.[RespondentID]
      ,s.[CLIENT_0_ID_NSO]
      ,s.[CLIENT_PERSONAL_0_NAME_FIRST]
      ,s.[CLIENT_PERSONAL_0_NAME_LAST]
      ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,s.[NURSE_PERSONAL_0_NAME]
      ,s.[CLIENT_HEALTH_PREGNANCY_0_LIVE_BIRTHS]
      ,s.[CLIENT_HEALTH_PREGNANCY_0_DOCTOR_VISIT]
      ,s.[CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE]
      ,s.[CLIENT_HEALTH_PREGNANCY_0_EDD]
      ,s.[CLIENT_HEALTH_GENERAL_0_CONCERNS]
      ,s.[CLIENT_HEALTH_GENERAL_WEIGHT_0_POUNDS]
      ,s.[CLIENT_HEALTH_BELIEF_0_LITTLE_CONTROL]
      ,s.[CLIENT_HEALTH_BELIEF_0_CANT_SOLVE]
      ,s.[CLIENT_HEALTH_BELIEF_0_LITTLE_CAN_DO]
      ,s.[CLIENT_HEALTH_BELIEF_0_FEEL_HELPLESS]
      ,s.[CLIENT_HEALTH_BELIEF_0_FEEL_PUSHED_AROUND]
      ,s.[CLIENT_HEALTH_BELIEF_0_FUTURE_CONTROL]
      ,s.[CLIENT_HEALTH_BELIEF_ 0_DO_ANYTHING]
      ,s.[CLIENT_HEALTH_GENERAL_0_OTHER]
      ,s.[CLIENT_HEALTH_GENERAL_HEIGHT_0_FEET]
      ,s.[CLIENT_HEALTH_GENERAL_HEIGHT_1_INCHES]
      ,s.[CLIENT_0_ID_AGENCY]
      ,s.[DW_AuditDate]
      ,s.[DataSource]
      ,s.[LA_CTY_MENTAL_MAT_HEALTH]
      ,s.[LA_CTY_PHYSICAL_MAT_HEALTH]
      ,s.[LA_CTY_DX_OTHER_MAT_HEALTH]
      ,s.[LA_CTY_DSM_DX_MAT_HEALTH]
      ,s.[CLIENT_HEALTH_GENERAL_0_PRE_GEST_BP]
      ,s.[CLIENT_HEALTH_GENERAL_0_PRE_GEST_DIABETES]
      ,s.[CLIENT_HEALTH_GENERAL_0_PRE_GEST_HEART]
      ,s.[CLIENT_HEALTH_GENERAL_0_PRE_GEST_KIDNEYS]
      ,s.[CLIENT_HEALTH_GENERAL_0_PRE_GEST_STI]
      ,s.[CLIENT_HEALTH_GENERAL_0_PRE_GEST_UTI]
      ,s.[CLIENT_HEALTH_GENERAL_0_PRE_GEST_VI]
      ,s.[CLIENT_HEALTH_GENERAL_CURRENT_WEIGHT_0_POUNDS]
      ,s.[Master_SurveyID]
      ,s.[CLIENT_HEALTH_GENERAL_0_CONCERNS2]
      ,s.[CLIENT_HEALTH_GENERAL_0_ADDICTION]
      ,s.[CLIENT_HEALTH_GENERAL_0_MENTAL_HEALTH]
      ,s.[LastModified]  
	FROM dbo.[Maternal_Health_Survey] s
	INNER JOIN dbo.Clients c ON c.Client_Id = s.CL_EN_GEN_ID
	WHERE SiteID in (SELECT SiteID FROM [DataWarehouse].dbo.ExportPFSEntities WHERE ExportProfileID = @ProfileID)
	--AND c.PFS_STUDY_VULNERABLE_POP = 0
	
END

GO
