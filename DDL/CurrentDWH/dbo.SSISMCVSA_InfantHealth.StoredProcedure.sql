USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISMCVSA_InfantHealth]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mike Osborn
-- Create date: 1/11/2016
-- Description:	Extract of MICHVEI data where the SiteID from the Survey is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing Gao
-- Modified Date: 11/30/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSISMCVSA_InfantHealth]
	-- Add the parameters for the stored procedure here
	@ProfileID INT
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT [SurveyResponseID]
		  ,[ElementsProcessed]
		  ,[SurveyID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[SurveyDate])) AS [SurveyDate]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[AuditDate])) AS [AuditDate]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CL_EN_GEN_ID])) AS [CL_EN_GEN_ID]
		  ,[SiteID]
		  ,[ProgramID]
		  ,[IA_StaffID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[ClientID])) AS [ClientID]
		  ,[RespondentID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_0_ID_NSO])) AS [INFANT_0_ID_NSO]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_PERSONAL_0_NAME_FIRST])) AS [INFANT_PERSONAL_0_NAME_FIRST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_BIRTH_0_DOB])) AS [INFANT_BIRTH_0_DOB]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_NSO])) AS [CLIENT_0_ID_NSO]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_FIRST])) AS [CLIENT_PERSONAL_0_NAME_FIRST]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_LAST])) AS [CLIENT_PERSONAL_0_NAME_LAST]
		  ,[NURSE_PERSONAL_0_NAME]
		  ,[INFANT_HEALTH_PROVIDER_0_PRIMARY]
		  ,[INFANT_HEALTH_IMMUNIZ_0_UPDATE]
		  ,[INFANT_HEALTH_IMMUNIZ_1_RECORD]
		  ,[INFANT_HEALTH_LEAD_0_TEST]
		  ,[INFANT_HEALTH_HEIGHT_0_INCHES]
		  ,[INFANT_HEALTH_HEIGHT_1_PERCENT]
		  ,[INFANT_HEALTH_HEAD_0_CIRC_INCHES]
		  ,[INFANT_HEALTH_ER_0_HAD_VISIT]
		  ,[INFANT_HEALTH_ER_1_TYPE]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_HEALTH_ER_1_INJ_DATE1])) AS [INFANT_HEALTH_ER_1_INJ_DATE1]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_HEALTH_ER_1_INJ_DATE2])) AS [INFANT_HEALTH_ER_1_INJ_DATE2]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_HEALTH_ER_1_INJ_DATE3])) AS [INFANT_HEALTH_ER_1_INJ_DATE3]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_HEALTH_ER_1_INGEST_DATE1])) AS [INFANT_HEALTH_ER_1_INGEST_DATE1]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_HEALTH_ER_1_INGEST_DATE2])) AS [INFANT_HEALTH_ER_1_INGEST_DATE2]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_HEALTH_ER_1_INGEST_DATE3])) AS [INFANT_HEALTH_ER_1_INGEST_DATE3]
		  ,[INFANT_HEALTH_HOSP_0_HAD_VISIT]
		  ,[INFANT_BREASTMILK_0_EVER_IHC]
		  ,[INFANT_BREASTMILK_1_CONT]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_HEALTH_HOSP_1_INJ_DATE1])) AS [INFANT_HEALTH_HOSP_1_INJ_DATE1]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_HEALTH_HOSP_1_INJ_DATE2])) AS [INFANT_HEALTH_HOSP_1_INJ_DATE2]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_HEALTH_HOSP_1_INJ_DATE3])) AS [INFANT_HEALTH_HOSP_1_INJ_DATE3]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_HEALTH_HOSP_1_INGEST_DATE1])) AS [INFANT_HEALTH_HOSP_1_INGEST_DATE1]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_HEALTH_HOSP_1_INGEST_DATE2])) AS [INFANT_HEALTH_HOSP_1_INGEST_DATE2]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_HEALTH_HOSP_1_INGEST_DATE3])) AS [INFANT_HEALTH_HOSP_1_INGEST_DATE3]
		  ,[INFANT_HEALTH_HOSP_1_TYPE]
		  ,[INFANT_BREASTMILK_1_AGE_STOP]
		  ,[INFANT_BREASTMILK_1_WEEK_STOP]
		  ,[INFANT_BREASTMILK_1_EXCLUSIVE_WKS]
		  ,[INFANT_SOCIAL_SERVICES_0_REFERRAL]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_SOCIAL_SERVICES_1_REFDATE1])) AS [INFANT_SOCIAL_SERVICES_1_REFDATE1]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_SOCIAL_SERVICES_1_REFDATE2])) AS [INFANT_SOCIAL_SERVICES_1_REFDATE2]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_SOCIAL_SERVICES_1_REFDATE3])) AS [INFANT_SOCIAL_SERVICES_1_REFDATE3]
		  ,[INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_SOCIAL_SERVICES_1_NHV_REFDATE1])) AS [INFANT_SOCIAL_SERVICES_1_NHV_REFDATE1]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_SOCIAL_SERVICES_1_NHV_REFDATE2])) AS [INFANT_SOCIAL_SERVICES_1_NHV_REFDATE2]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_SOCIAL_SERVICES_1_NHV_REFDATE3])) AS [INFANT_SOCIAL_SERVICES_1_NHV_REFDATE3]
		  ,[INFANT_HEALTH_WEIGHT_0_POUNDS]
		  ,[INFANT_HEALTH_WEIGHT_1_OUNCES]
		  ,[INFANT_HEALTH_WEIGHT_1_OZ]
		  ,[INFANT_HEALTH_WEIGHT_1_PERCENT]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_AGENCY])) AS [CLIENT_0_ID_AGENCY]
		  ,[INFANT_AGES_STAGES_1_COMM]
		  ,[INFANT_AGES_STAGES_0_VERSION]
		  ,[INFANT_AGES_STAGES_1_GMOTOR]
		  ,[INFANT_AGES_STAGES_1_FMOTOR]
		  ,[INFANT_AGES_STAGES_1_PSOLVE]
		  ,[INFANT_AGES_STAGES_1_PSOCIAL]
		  ,[INFANT_AGES_STAGES_SE_0_EMOTIONAL]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_PERSONAL_0_NAME_LAST])) AS [INFANT_PERSONAL_0_NAME_LAST]
		  ,[INFANT_HEALTH_HEAD_1_REPORT]
		  ,[INFANT_HEALTH_HEIGHT_1_REPORT]
		  ,[INFANT_HEALTH_PROVIDER_0_APPT]
		  ,[INFANT_HEALTH_WEIGHT_1_REPORT]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_HEALTH_ER_1_OTHERDT1])) AS [INFANT_HEALTH_ER_1_OTHERDT1]
		  ,[INFANT_HEALTH_ER_1_INGEST_TREAT1]
		  ,[INFANT_HEALTH_ER_1_INGEST_TREAT2]
		  ,[INFANT_HEALTH_ER_1_INGEST_TREAT3]
		  ,[INFANT_HEALTH_ER_1_INJ_TREAT1]
		  ,[INFANT_HEALTH_ER_1_INJ_TREAT2]
		  ,[INFANT_HEALTH_ER_1_OTHER]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_HEALTH_ER_1_OTHER_REASON1])) AS [INFANT_HEALTH_ER_1_OTHER_REASON1]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_HEALTH_ER_1_OTHER_REASON2])) AS [INFANT_HEALTH_ER_1_OTHER_REASON2]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_HEALTH_ER_1_OTHER_REASON3])) AS [INFANT_HEALTH_ER_1_OTHER_REASON3]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_HEALTH_ER_1_OTHERDT2])) AS [INFANT_HEALTH_ER_1_OTHERDT2]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_HEALTH_ER_1_OTHERDT3])) AS [INFANT_HEALTH_ER_1_OTHERDT3]
		  ,[INFANT_HOME_0_TOTAL]
		  ,[INFANT_HOME_1_ACCEPTANCE]
		  ,[INFANT_HOME_1_EXPERIENCE]
		  ,[INFANT_HOME_1_INVOLVEMENT]
		  ,[INFANT_HOME_1_LEARNING]
		  ,[INFANT_HOME_1_ORGANIZATION]
		  ,[INFANT_HOME_1_RESPONSIVITY]
		  ,[INFANT_SOCIAL_SERVICES_1_NHV_REASON1]
		  ,[INFANT_SOCIAL_SERVICES_1_NHV_REASON2]
		  ,[INFANT_SOCIAL_SERVICES_1_NHV_REASON3]
		  ,[INFANT_SOCIAL_SERVICES_1_REASON1]
		  ,[INFANT_SOCIAL_SERVICES_1_REASON2]
		  ,[INFANT_SOCIAL_SERVICES_1_REASON3]
		  ,[NFANT_HEALTH_ER_1_INJ_TREAT3]
		  ,[DW_AuditDate]
		  ,[DataSource]
		  ,[INFANT_HEALTH_ER_1_INJ_ERvsUC1]
		  ,[INFANT_HEALTH_PROVIDER_0_APPT_R2]
		  ,[INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2]
		  ,[INFANT_HEALTH_ER_1_INGEST_ERvsUC1]
		  ,[INFANT_HEALTH_ER_1_INGEST_ERvsUC2]
		  ,[INFANT_HEALTH_ER_1_INGEST_ERvsUC3]
		  ,[INFANT_HEALTH_ER_1_INJ_ERvsUC2]
		  ,[INFANT_HEALTH_ER_1_OTHER_ERvsUC1]
		  ,[INFANT_HEALTH_ER_1_OTHER_ERvsUC2]
		  ,[INFANT_HEALTH_NO_ASQ_COMM]
		  ,[INFANT_HEALTH_NO_ASQ_FINE]
		  ,[INFANT_HEALTH_NO_ASQ_GROSS]
		  ,[INFANT_HEALTH_NO_ASQ_PERSONAL]
		  ,[INFANT_HEALTH_NO_ASQ_PROBLEM]
		  ,[INFANT_HEALTH_NO_ASQ_TOTAL]
		  ,[INFANT_HEALTH_ER_1_INJ_ERvsUC3]
		  ,[INFANT_HEALTH_ER_1_OTHER_ERvsUC3]
		  ,[INFANT_HEALTH_ER_1_INJ_TREAT3]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_PERSONAL_0_SSN])) AS [INFANT_PERSONAL_0_SSN]
		  ,[INFANT_HEALTH_ER_1_INGEST_DAYS1]
		  ,[INFANT_HEALTH_ER_1_INGEST_DAYS2]
		  ,[INFANT_HEALTH_ER_1_INGEST_DAYS3]
		  ,[INFANT_HEALTH_ER_1_INJ_DAYS1]
		  ,[INFANT_HEALTH_ER_1_INJ_DAYS2]
		  ,[INFANT_HEALTH_ER_1_INJ_DAYS3]
		  ,[Master_SurveyID]
		  ,[INFANT_HEALTH_IMMUNIZ_UPDATE_NO]
		  ,[INFANT_HEALTH_IMMUNIZ_UPDATE_YES]
		  ,[INFANT_HEALTH_DENTIST]
		  ,[INFANT_HEALTH_DENTIST_STILL_EBF]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_SOCIAL_SERVICES_1_NHV_REASON1_OTHER])) AS [INFANT_SOCIAL_SERVICES_1_NHV_REASON1_OTHER]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_SOCIAL_SERVICES_1_NHV_REASON2_OTHER])) AS [INFANT_SOCIAL_SERVICES_1_NHV_REASON2_OTHER]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_SOCIAL_SERVICES_1_NHV_REASON3_OTHER])) AS [INFANT_SOCIAL_SERVICES_1_NHV_REASON3_OTHER]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_SOCIAL_SERVICES_1_REASON1_OTHER])) AS [INFANT_SOCIAL_SERVICES_1_REASON1_OTHER]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_SOCIAL_SERVICES_1_REASON2_OTHER])) AS [INFANT_SOCIAL_SERVICES_1_REASON2_OTHER]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[INFANT_SOCIAL_SERVICES_1_REASON3_OTHER])) AS [INFANT_SOCIAL_SERVICES_1_REASON3_OTHER]
		  ,[Archive_Record]
      ,[INFANT_INSURANCE_TYPE]
      ,[INFANT_AGES_STAGES_SE_VERSION]
      ,[INFANT_BIRTH_COSLEEP]
      ,[INFANT_BIRTH_READ]
      ,[INFANT_BIRTH_SLEEP_BACK]
      ,[INFANT_BIRTH_SLEEP_BEDDING]
      ,[INFANT_HEALTH_DENTAL_SOURCE]
      ,[INFANT_INSURANCE]
      ,[INFANT_INSURANCE_OTHER]
	  FROM [DataWarehouse].[dbo].[Infant_Health_Survey] s
	 WHERE CL_EN_GEN_ID in (select CL_EN_GEN_ID from View_MIECHVP_Cleints 
						     where siteid in(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ISNULL(ExportDisabled,0) != 1))
	   AND ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	   AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
  
END
GO
