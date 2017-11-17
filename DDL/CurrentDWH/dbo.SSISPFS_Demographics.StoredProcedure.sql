USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFS_Demographics]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Create date: 1/12/2016
-- Description:	Extract of Demographics data where the SiteID from Demographics_Survey is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- Modify date: 11/01/2016
-- By: Jingjing Gao
-- Description: Modify store proc per ETO "Blueprint_October 2016 Release_09012016.xls" located on S:\IT\ETO\Release 8 (Oct 2016)\Requirements
-- *********************************************
-- Modified by: Jingjing Gao
-- Modified on: 02/14/2017
-- Description: Per Kyla's ticket#[00019665]:JPAL Raw Data Extract Modification, remove the filter "PFS_STUDY_VULNERABLE_POP = 0" because JPAL want to include all 
--              clients regardless the clients is vulnerable or not. In addition, joining condition need to be changed. Use [CL_EN_GEN_ID] instead of [CLIENT_0_ID_NSO]
--              to join [dbo].[Clients] table.
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFS_Demographics] 
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
      ,s.[CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED]
      ,s.[CLIENT_MARITAL_0_STATUS]
      ,s.[CLIENT_BIO_DAD_0_CONTACT_WITH]
      ,s.[CLIENT_LIVING_0_WITH]
      ,s.[CLIENT_LIVING_1_WITH_OTHERS]
      ,s.[CLIENT_EDUCATION_0_HS_GED]
      ,s.[CLIENT_EDUCATION_1_HS_GED_LAST_GRADE]
      ,s.[CLIENT_EDUCATION_1_HIGHER_EDUC_COMP]
      ,s.[CLIENT_EDUCATION_1_ENROLLED_CURRENT]
      ,s.[CLIENT_EDUCATION_1_ENROLLED_TYPE]
      ,s.[CLIENT_EDUCATION_1_ENROLLED_PLAN]
      ,s.[CLIENT_WORKING_0_CURRENTLY_WORKING]
      ,s.[CLIENT_INCOME_0_HH_INCOME]
      ,s.[CLIENT_INCOME_1_LOW_INCOME_QUALIFY]
      ,s.[CLIENT_0_ID_NSO]
      ,s.[CLIENT_PERSONAL_0_NAME_FIRST]
      ,s.[CLIENT_PERSONAL_0_NAME_LAST]
      ,s.[NURSE_PERSONAL_0_NAME]
      ,s.[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,s.[CLIENT_PERSONAL_0_ETHNICITY_INTAKE]
      ,s.[CLIENT_PERSONAL_0_RACE]
      ,s.[CLIENT_PERSONAL_LANGUAGE_0_INTAKE]
      ,s.[CLIENT_0_ID_AGENCY]
      ,s.[CLIENT_WORKING_1_WORKED_SINCE_BIRTH]
      ,s.[CLIENT_WORKING_1_WORKED_SINCE_BIRTH_MONTHS]
      ,s.[CLIENT_BC_0_USED_6MONTHS]
      ,s.[CLIENT_BC_1_NOT_USED_REASON]
      ,s.[CLIENT_BC_1_FREQUENCY]
      ,s.[CLIENT_BC_1_TYPES]
      ,s.[CLIENT_SUBPREG_0_BEEN_PREGNANT]
      ,s.[CLIENT_SUBPREG_1_BEGIN_MONTH]
      ,s.[CLIENT_SUBPREG_1_BEGIN_YEAR]
      ,s.[CLIENT_SUBPREG_1_PLANNED]
      ,s.[CLIENT_SUBPREG_1_OUTCOME]
      ,s.[CLIENT_SECOND_0_CHILD_DOB]
      ,s.[CLIENT_SECOND_1_CHILD_GENDER]
      ,s.[CLIENT_SECOND_1_CHILD_BW_POUNDS]
      ,s.[CLIENT_SECOND_1_CHILD_BW_OZ]
      ,s.[CLIENT_SECOND_1_CHILD_NICU]
      ,s.[CLIENT_SECOND_1_CHILD_NICU_DAYS]
      ,s.[CLIENT_BIO_DAD_1_TIME_WITH]
      ,s.[ADULTS_1_ENROLL_NO]
      ,s.[ADULTS_1_ENROLL_PT]
      ,s.[ADULTS_1_CARE_10]
      ,s.[ADULTS_1_CARE_20]
      ,s.[ADULTS_1_CARE_30]
      ,s.[ADULTS_1_CARE_40]
      ,s.[ADULTS_1_CARE_LESS10]
      ,s.[ADULTS_1_COMPLETE_GED]
      ,s.[ADULTS_1_COMPLETE_HS]
      ,s.[ADULTS_1_COMPLETE_HS_NO]
      ,s.[ADULTS_1_ED_TECH]
      ,s.[ADULTS_1_ED_ASSOCIATE]
      ,s.[ADULTS_1_ED_BACHELOR]
      ,s.[ADULTS_1_ED_MASTER]
      ,s.[ADULTS_1_ED_NONE]
      ,s.[ADULTS_1_ED_POSTGRAD]
      ,s.[ADULTS_1_ED_SOME_COLLEGE]
      ,s.[ADULTS_1_ED_UNKNOWN]
      ,s.[ADULTS_1_ENROLL_FT]
      ,s.[ADULTS_1_INS_NO]
      ,s.[ADULTS_1_INS_PRIVATE]
      ,s.[ADULTS_1_INS_PUBLIC]
      ,s.[ADULTS_1_WORK_10]
      ,s.[ADULTS_1_WORK_20]
      ,s.[ADULTS_1_WORK_37]
      ,s.[ADULTS_1_WORK_LESS10]
      ,s.[ADULTS_1_WORK_UNEMPLOY]
      ,s.[CLIENT_CARE_0_ER_HOSP]
      ,s.[CLIENT_EDUCATION_1_ENROLLED_FTPT]
      ,s.[CLIENT_INCOME_1_HH_SOURCES]
      ,s.[CLIENT_WORKING_1_CURRENTLY_WORKING_HRS]
      ,s.[DW_AuditDate]
      ,s.[DataSource]
      ,s.[CLIENT_EDUCATION_1_ENROLLED_PT_HRS]
      ,s.[CLIENT_SCHOOL_MIDDLE_HS]
      ,s.[CLIENT_ED_PROG_TYPE]
      ,s.[CLIENT_PROVIDE_CHILDCARE]
      ,s.[CLIENT_WORKING_2_CURRENTLY_WORKING_NO]
      ,s.[CLIENT_CARE_0_ER]
      ,s.[CLIENT_CARE_0_URGENT]
      ,s.[CLIENT_CARE_0_ER_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_TIMES]
      ,s.[CLIENT_INCOME_IN_KIND]
      ,s.[CLIENT_INCOME_SOURCES]
      ,s.[CLIENT_MILITARY]
      ,s.[DELETE ME]
      ,s.[CLIENT_INCOME_AMOUNT]
      ,s.[CLIENT_WORKING_1_CURRENTLY_WORKING_NO]
      ,s.[CLIENT_INCOME_INKIND_OTHER]
      ,s.[CLIENT_INCOME_OTHER_SOURCES]
      ,s.[CLIENT_BC_1_TYPES_NEXT6]
      ,s.[CLIENT_SUBPREG_1_EDD]
      ,s.[CLIENT_CARE_0_ER_PURPOSE]
      ,s.[CLIENT_CARE_0_URGENT_PURPOSE]
      ,s.[CLIENT_CARE_0_ URGENT_OTHER]
      ,s.[CLIENT_CARE_0_ER_OTHER]
      ,s.[CLIENT_CARE_0_ER_FEVER_TIMES]
      ,s.[CLIENT_CARE_0_ER_INFECTION_TIMES]
      ,s.[CLIENT_CARE_0_ER_INGESTION_TIMES]
      ,s.[CLIENT_CARE_0_ER_INJURY_TIMES]
      ,s.[CLIENT_CARE_0_ER_OTHER_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_FEVER_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_INFECTION_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_INGESTION_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_INJURY_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_OTHER_TIMES]
      ,s.[CLIENT_SECOND_1_CHILD_BW_MEASURE]
      ,s.[CLIENT_CARE_0_URGENT_OTHER]
      ,s.[CLIENT_SECOND_1_CHILD_BW_CONVERT_GRAMS]
      ,s.[CLIENT_SECOND_1_CHILD_BW_GRAMS]
      ,s.[CLIENT_SUBPREG_1_GEST_AGE]
      ,s.[Master_SurveyID]
      ,s.[CLIENT_CARE_0_ER_PURPOSE_R6]
      ,s.[CLIENT_CARE_0_URGENT_PURPOSE_R6]
      ,s.[CLIENT_SUBPREG]
      ,s.[CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES]
      ,s.[CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES]
      ,s.[CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES]
      ,s.[CLIENT_CARE_0_ER_INGESTION_SELF_TIMES]
      ,s.[CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES]
      ,s.[CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES]
      ,s.[CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES]
      ,s.[CLIENT_CARE_0_ER_INJURY_SELF_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES]
      ,s.[CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES]
      ,s.[Archive_Record]
      ,s.[CLIENT_INSURANCE_TYPE]
      ,s.[CLIENT_INSURANCE]
      ,s.[CLIENT_LIVING_HOMELESS]
      ,s.[CLIENT_LIVING_WHERE]
      ,s.[CLIENT_INSURANCE_OTHER]
  FROM [DataWarehouse].[dbo].[Demographics_Survey] s
	INNER JOIN dbo.Clients c ON c.Client_Id = s.CL_EN_GEN_ID
	WHERE SiteID in (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
					  WHERE ExportProfileID = @ProfileID)
	--AND c.PFS_STUDY_VULNERABLE_POP = 0
  
END

GO
