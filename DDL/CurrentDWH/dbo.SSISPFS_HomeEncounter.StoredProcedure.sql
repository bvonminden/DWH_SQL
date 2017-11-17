USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFS_HomeEncounter]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Sheri Scott
-- Create date: 1/13/2016
-- Description:	Extract of HomeEncounter data where the SiteID from [Home_Visit_Encounter_Survey] is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- Modify date: 11/01/2016
-- By: Jingjing Gao
-- Description: Modify store proc per ETO "Blueprint_October 2016 Release_09012016.xls" located on S:\IT\ETO\Release 8 (Oct 2016)\Requirements
-- *********************************************
-- Modified by: Jingjing Gao
-- Modified on: 02/14/2017
-- Description: Per Kyla's ticket#[00019665]:JPAL Raw Data Extract Modification, remove the filter "PFS_STUDY_VULNERABLE_POP = 0" because JPAL want to include all 
--              clients regardless the clients is vulnerable or not. 
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFS_HomeEncounter]
	@ProfileID INT
AS
BEGIN

	SET NOCOUNT ON;
	
	/****** Script for SelectTopNRows command from SSMS  ******/
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
      ,s.[CLIENT_TIME_0_START_VISIT]
      ,s.[CLIENT_TIME_1_END_VISIT]
      ,s.[NURSE_MILEAGE_0_VIS]
      ,s.[NURSE_PERSONAL_0_NAME]
      ,s.[CLIENT_COMPLETE_0_VISIT]
      ,s.[CLIENT_LOCATION_0_VISIT]
      ,s.[CLIENT_ATTENDEES_0_AT_VISIT]
      ,s.[CLIENT_INVOLVE_0_CLIENT_VISIT]
      ,s.[CLIENT_INVOLVE_1_GRNDMTHR_VISIT]
      ,s.[CLIENT_INVOLVE_1_PARTNER_VISIT]
      ,s.[CLIENT_CONFLICT_0_CLIENT_VISIT]
      ,s.[CLIENT_CONFLICT_1_GRNDMTHR_VISIT]
      ,s.[CLIENT_CONFLICT_1_PARTNER_VISIT]
      ,s.[CLIENT_UNDERSTAND_0_CLIENT_VISIT]
      ,s.[CLIENT_UNDERSTAND_1_GRNDMTHR_VISIT]
      ,s.[CLIENT_UNDERSTAND_1_PARTNER_VISIT]
      ,s.[CLIENT_DOMAIN_0_PERSHLTH_VISIT]
      ,s.[CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT]
      ,s.[CLIENT_DOMAIN_0_LIFECOURSE_VISIT]
      ,s.[CLIENT_DOMAIN_0_MATERNAL_VISIT]
      ,s.[CLIENT_DOMAIN_0_FRNDFAM_VISIT]
      ,s.[CLIENT_DOMAIN_0_TOTAL_VISIT]
      ,s.[CLIENT_CONTENT_0_PERCENT_VISIT]
      ,s.[CLIENT_ATTENDEES_0_OTHER_VISIT_DESC]
      ,s.[CLIENT_TIME_1_DURATION_VISIT]
      ,s.[CLIENT_0_ID_AGENCY]
      ,s.[CLIENT_CHILD_INJURY_0_PREVENTION]
      ,s.[CLIENT_IPV_0_SAFETY_PLAN]
      ,s.[DW_AuditDate]
      ,s.[DataSource]
      ,s.[CLIENT_PRENATAL_VISITS_WEEKS]
      ,s.[CLIENT_NO_REFERRAL]
      ,s.[CLIENT_PRENATAL_VISITS]
      ,s.[CLIENT_SCREENED_SRVCS]
      ,s.[CLIENT_VISIT_SCHEDULE]
      ,s.[Master_SurveyID]
      ,s.[CLIENT_PLANNED_VISIT_SCH]
      ,s.[CLIENT_TIME_FROM_AMPM]
      ,s.[CLIENT_TIME_FROM_HR]
      ,s.[CLIENT_TIME_FROM_MIN]
      ,s.[CLIENT_TIME_TO_AMPM]
      ,s.[CLIENT_TIME_TO_HR]
      ,s.[CLIENT_TIME_TO_MIN]
      ,s.[temp_time_start]
      ,s.[temp_time_end]
      ,s.[Old_CLIENT_TIME_0_START_Visit]
      ,s.[Old_CLIENT_TIME_1_END_Visit]
      ,s.[old_CLIENT_TIME_1_DURATION_VISIT]
      ,s.[temp_DURATION]
      ,s.[LastModified]
      ,s.[Archive_Record]
      ,s.[INFANT_HEALTH_ER_1_TYPE]
      ,s.[INFANT_HEALTH_HOSP_1_TYPE]
      ,s.[INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2]
      ,s.[CLIENT_CHILD_DEVELOPMENT_CONCERN]
      ,s.[CLIENT_CONT_HLTH_INS]
      ,s.[INFANT_HEALTH_ER_0_HAD_VISIT]
      ,s.[INFANT_HEALTH_ER_1_INGEST_ERvsUC1]
      ,s.[INFANT_HEALTH_ER_1_INGEST_ERvsUC2]
      ,s.[INFANT_HEALTH_ER_1_INGEST_ERvsUC3]
      ,s.[INFANT_HEALTH_ER_1_INGEST_TREAT1]
      ,s.[INFANT_HEALTH_ER_1_INGEST_TREAT2]
      ,s.[INFANT_HEALTH_ER_1_INGEST_TREAT3]
      ,s.[INFANT_HEALTH_ER_1_INJ_ERvsUC1]
      ,s.[INFANT_HEALTH_ER_1_INJ_ERvsUC2]
      ,s.[INFANT_HEALTH_ER_1_INJ_ERvsUC3]
      ,s.[INFANT_HEALTH_ER_1_INJ_TREAT1]
      ,s.[INFANT_HEALTH_ER_1_INJ_TREAT2]
      ,s.[INFANT_HEALTH_ER_1_INJ_TREAT3]
      ,s.[INFANT_HEALTH_ER_1_OTHER]
      ,s.[INFANT_HEALTH_ER_1_OTHER_ERvsUC1]
      ,s.[INFANT_HEALTH_ER_1_OTHER_ERvsUC2]
      ,s.[INFANT_HEALTH_ER_1_OTHER_ERvsUC3]
      ,s.[INFANT_HEALTH_HOSP_0_HAD_VISIT]
      ,s.[INFANT_HEALTH_PROVIDER_0_APPT_R2]
      ,s.[INFANT_HEALTH_ER_1_OTHER_REASON1]
      ,s.[INFANT_HEALTH_ER_1_OTHER_REASON2]
      ,s.[INFANT_HEALTH_ER_1_OTHER_REASON3]
      ,s.[INFANT_HEALTH_ER_1_INGEST_DAYS1]
      ,s.[INFANT_HEALTH_ER_1_INGEST_DAYS2]
      ,s.[INFANT_HEALTH_ER_1_INGEST_DAYS3]
      ,s.[INFANT_HEALTH_ER_1_INJ_DAYS1]
      ,s.[INFANT_HEALTH_ER_1_INJ_DAYS2]
      ,s.[INFANT_HEALTH_ER_1_INJ_DAYS3]
      ,s.[INFANT_HEALTH_ER_1_INGEST_DATE1]
      ,s.[INFANT_HEALTH_ER_1_INGEST_DATE2]
      ,s.[INFANT_HEALTH_ER_1_INGEST_DATE3]
      ,s.[INFANT_HEALTH_ER_1_INJ_DATE1]
      ,s.[INFANT_HEALTH_ER_1_INJ_DATE2]
      ,s.[INFANT_HEALTH_ER_1_INJ_DATE3]
      ,s.[INFANT_HEALTH_ER_1_OTHERDT1]
      ,s.[INFANT_HEALTH_ER_1_OTHERDT2]
      ,s.[INFANT_HEALTH_ER_1_OTHERDT3]
      ,s.[INFANT_HEALTH_HOSP_1_INGEST_DATE1]
      ,s.[INFANT_HEALTH_HOSP_1_INGEST_DATE2]
      ,s.[INFANT_HEALTH_HOSP_1_INGEST_DATE3]
      ,s.[INFANT_HEALTH_HOSP_1_INJ_DATE1]
      ,s.[INFANT_HEALTH_HOSP_1_INJ_DATE2]
      ,s.[INFANT_HEALTH_HOSP_1_INJ_DATE3]
  FROM [DataWarehouse].[dbo].[Home_Visit_Encounter_Survey] s
	INNER JOIN dbo.Clients c ON c.Client_Id = s.CL_EN_GEN_ID
	WHERE s.SiteID in (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
						WHERE ExportProfileID = @ProfileID)
	--AND c.PFS_STUDY_VULNERABLE_POP = 0
	 
END

GO
