USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISDUA_HomeEncounter]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of HomeEncounter data where the SiteID from [Home_Visit_Encounter_Survey] is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- Modify date: 11/01/2016
-- By: Jingjing Gao
-- Description: Modify store proc per ETO "Blueprint_October 2016 Release_09012016.xls" located on S:\IT\ETO\Release 8 (Oct 2016)\Requirements
-- *********************************************
-- Modified by: Jingjing
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSISDUA_HomeEncounter]
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
      ,[CLIENT_TIME_0_START_VISIT]
      ,[CLIENT_TIME_1_END_VISIT]
      ,[NURSE_MILEAGE_0_VIS]
      ,[NURSE_PERSONAL_0_NAME]
      ,[CLIENT_COMPLETE_0_VISIT]
      ,[CLIENT_LOCATION_0_VISIT]
      ,[CLIENT_ATTENDEES_0_AT_VISIT]
      ,[CLIENT_INVOLVE_0_CLIENT_VISIT]
      ,[CLIENT_INVOLVE_1_GRNDMTHR_VISIT]
      ,[CLIENT_INVOLVE_1_PARTNER_VISIT]
      ,[CLIENT_CONFLICT_0_CLIENT_VISIT]
      ,[CLIENT_CONFLICT_1_GRNDMTHR_VISIT]
      ,[CLIENT_CONFLICT_1_PARTNER_VISIT]
      ,[CLIENT_UNDERSTAND_0_CLIENT_VISIT]
      ,[CLIENT_UNDERSTAND_1_GRNDMTHR_VISIT]
      ,[CLIENT_UNDERSTAND_1_PARTNER_VISIT]
      ,[CLIENT_DOMAIN_0_PERSHLTH_VISIT]
      ,[CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT]
      ,[CLIENT_DOMAIN_0_LIFECOURSE_VISIT]
      ,[CLIENT_DOMAIN_0_MATERNAL_VISIT]
      ,[CLIENT_DOMAIN_0_FRNDFAM_VISIT]
      ,[CLIENT_DOMAIN_0_TOTAL_VISIT]
      ,[CLIENT_CONTENT_0_PERCENT_VISIT]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_ATTENDEES_0_OTHER_VISIT_DESC])) AS [CLIENT_ATTENDEES_0_OTHER_VISIT_DESC]
      ,[CLIENT_TIME_1_DURATION_VISIT]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_AGENCY])) AS [CLIENT_0_ID_AGENCY]
      ,[CLIENT_CHILD_INJURY_0_PREVENTION]
      ,[CLIENT_IPV_0_SAFETY_PLAN]
      ,[DW_AuditDate]
      ,[DataSource]
      ,[CLIENT_PRENATAL_VISITS_WEEKS]
      ,[CLIENT_NO_REFERRAL]
      ,[CLIENT_PRENATAL_VISITS]
      ,[CLIENT_SCREENED_SRVCS]
      ,[CLIENT_VISIT_SCHEDULE]
      ,[Master_SurveyID]
      ,[CLIENT_PLANNED_VISIT_SCH]
      ,[CLIENT_TIME_FROM_AMPM]
      ,[CLIENT_TIME_FROM_HR]
      ,[CLIENT_TIME_FROM_MIN]
      ,[CLIENT_TIME_TO_AMPM]
      ,[CLIENT_TIME_TO_HR]
      ,[CLIENT_TIME_TO_MIN]
      ,[temp_time_start]
      ,[temp_time_end]
      ,[Old_CLIENT_TIME_0_START_Visit]
      ,[Old_CLIENT_TIME_1_END_Visit]
      ,[old_CLIENT_TIME_1_DURATION_VISIT]
      ,[temp_DURATION]
      ,[LastModified]
      ,[Archive_Record]
      ,[INFANT_HEALTH_ER_1_TYPE]
      ,[INFANT_HEALTH_HOSP_1_TYPE]
      ,[INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2]
      ,[CLIENT_CHILD_DEVELOPMENT_CONCERN]
      ,[CLIENT_CONT_HLTH_INS]
      ,[INFANT_HEALTH_ER_0_HAD_VISIT]
      ,[INFANT_HEALTH_ER_1_INGEST_ERvsUC1]
      ,[INFANT_HEALTH_ER_1_INGEST_ERvsUC2]
      ,[INFANT_HEALTH_ER_1_INGEST_ERvsUC3]
      ,[INFANT_HEALTH_ER_1_INGEST_TREAT1]
      ,[INFANT_HEALTH_ER_1_INGEST_TREAT2]
      ,[INFANT_HEALTH_ER_1_INGEST_TREAT3]
      ,[INFANT_HEALTH_ER_1_INJ_ERvsUC1]
      ,[INFANT_HEALTH_ER_1_INJ_ERvsUC2]
      ,[INFANT_HEALTH_ER_1_INJ_ERvsUC3]
      ,[INFANT_HEALTH_ER_1_INJ_TREAT1]
      ,[INFANT_HEALTH_ER_1_INJ_TREAT2]
      ,[INFANT_HEALTH_ER_1_INJ_TREAT3]
      ,[INFANT_HEALTH_ER_1_OTHER]
      ,[INFANT_HEALTH_ER_1_OTHER_ERvsUC1]
      ,[INFANT_HEALTH_ER_1_OTHER_ERvsUC2]
      ,[INFANT_HEALTH_ER_1_OTHER_ERvsUC3]
      ,[INFANT_HEALTH_HOSP_0_HAD_VISIT]
      ,[INFANT_HEALTH_PROVIDER_0_APPT_R2]
      ,[INFANT_HEALTH_ER_1_OTHER_REASON1]
      ,[INFANT_HEALTH_ER_1_OTHER_REASON2]
      ,[INFANT_HEALTH_ER_1_OTHER_REASON3]
      ,[INFANT_HEALTH_ER_1_INGEST_DAYS1]
      ,[INFANT_HEALTH_ER_1_INGEST_DAYS2]
      ,[INFANT_HEALTH_ER_1_INGEST_DAYS3]
      ,[INFANT_HEALTH_ER_1_INJ_DAYS1]
      ,[INFANT_HEALTH_ER_1_INJ_DAYS2]
      ,[INFANT_HEALTH_ER_1_INJ_DAYS3]
      ,[INFANT_HEALTH_ER_1_INGEST_DATE1]
      ,[INFANT_HEALTH_ER_1_INGEST_DATE2]
      ,[INFANT_HEALTH_ER_1_INGEST_DATE3]
      ,[INFANT_HEALTH_ER_1_INJ_DATE1]
      ,[INFANT_HEALTH_ER_1_INJ_DATE2]
      ,[INFANT_HEALTH_ER_1_INJ_DATE3]
      ,[INFANT_HEALTH_ER_1_OTHERDT1]
      ,[INFANT_HEALTH_ER_1_OTHERDT2]
      ,[INFANT_HEALTH_ER_1_OTHERDT3]
      ,[INFANT_HEALTH_HOSP_1_INGEST_DATE1]
      ,[INFANT_HEALTH_HOSP_1_INGEST_DATE2]
      ,[INFANT_HEALTH_HOSP_1_INGEST_DATE3]
      ,[INFANT_HEALTH_HOSP_1_INJ_DATE1]
      ,[INFANT_HEALTH_HOSP_1_INJ_DATE2]
      ,[INFANT_HEALTH_HOSP_1_INJ_DATE3]
  FROM [DataWarehouse].[dbo].[Home_Visit_Encounter_Survey] s
	 WHERE SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	   AND ProgramID NOT IN (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	   AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
  
END
GO
