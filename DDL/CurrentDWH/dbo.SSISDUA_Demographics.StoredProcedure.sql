USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISDUA_Demographics]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of Demographics data where the SiteID from Demographics_Survey is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
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
CREATE PROCEDURE [dbo].[SSISDUA_Demographics] 
	-- Add the parameters for the stored procedure here
	@ProfileID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	/****** Script for SelectTopNRows command from SSMS  ******/
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
      ,[CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED]
      ,[CLIENT_MARITAL_0_STATUS]
      ,[CLIENT_BIO_DAD_0_CONTACT_WITH]
      ,[CLIENT_LIVING_0_WITH]
      ,[CLIENT_LIVING_1_WITH_OTHERS]
      ,[CLIENT_EDUCATION_0_HS_GED]
      ,[CLIENT_EDUCATION_1_HS_GED_LAST_GRADE]
      ,[CLIENT_EDUCATION_1_HIGHER_EDUC_COMP]
      ,[CLIENT_EDUCATION_1_ENROLLED_CURRENT]
      ,[CLIENT_EDUCATION_1_ENROLLED_TYPE]
      ,[CLIENT_EDUCATION_1_ENROLLED_PLAN]
      ,[CLIENT_WORKING_0_CURRENTLY_WORKING]
      ,[CLIENT_INCOME_0_HH_INCOME]
      ,[CLIENT_INCOME_1_LOW_INCOME_QUALIFY]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_NSO])) AS [CLIENT_0_ID_NSO]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_FIRST])) AS [CLIENT_PERSONAL_0_NAME_FIRST]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_LAST])) AS [CLIENT_PERSONAL_0_NAME_LAST]
      ,[NURSE_PERSONAL_0_NAME]
      ,[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,[CLIENT_PERSONAL_0_ETHNICITY_INTAKE]
      ,[CLIENT_PERSONAL_0_RACE]
      ,[CLIENT_PERSONAL_LANGUAGE_0_INTAKE]
       ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_AGENCY])) AS [CLIENT_0_ID_AGENCY]
      ,[CLIENT_WORKING_1_WORKED_SINCE_BIRTH]
      ,[CLIENT_WORKING_1_WORKED_SINCE_BIRTH_MONTHS]
      ,[CLIENT_BC_0_USED_6MONTHS]
      ,[CLIENT_BC_1_NOT_USED_REASON]
      ,[CLIENT_BC_1_FREQUENCY]
      ,[CLIENT_BC_1_TYPES]
      ,[CLIENT_SUBPREG_0_BEEN_PREGNANT]
      ,[CLIENT_SUBPREG_1_BEGIN_MONTH]
      ,[CLIENT_SUBPREG_1_BEGIN_YEAR]
      ,[CLIENT_SUBPREG_1_PLANNED]
      ,[CLIENT_SUBPREG_1_OUTCOME]
      ,[CLIENT_SECOND_0_CHILD_DOB]
      ,[CLIENT_SECOND_1_CHILD_GENDER]
      ,[CLIENT_SECOND_1_CHILD_BW_POUNDS]
      ,[CLIENT_SECOND_1_CHILD_BW_OZ]
      ,[CLIENT_SECOND_1_CHILD_NICU]
      ,[CLIENT_SECOND_1_CHILD_NICU_DAYS]
      ,[CLIENT_BIO_DAD_1_TIME_WITH]
      ,[ADULTS_1_ENROLL_NO]
      ,[ADULTS_1_ENROLL_PT]
      ,[ADULTS_1_CARE_10]
      ,[ADULTS_1_CARE_20]
      ,[ADULTS_1_CARE_30]
      ,[ADULTS_1_CARE_40]
      ,[ADULTS_1_CARE_LESS10]
      ,[ADULTS_1_COMPLETE_GED]
      ,[ADULTS_1_COMPLETE_HS]
      ,[ADULTS_1_COMPLETE_HS_NO]
      ,[ADULTS_1_ED_TECH]
      ,[ADULTS_1_ED_ASSOCIATE]
      ,[ADULTS_1_ED_BACHELOR]
      ,[ADULTS_1_ED_MASTER]
      ,[ADULTS_1_ED_NONE]
      ,[ADULTS_1_ED_POSTGRAD]
      ,[ADULTS_1_ED_SOME_COLLEGE]
      ,[ADULTS_1_ED_UNKNOWN]
      ,[ADULTS_1_ENROLL_FT]
      ,[ADULTS_1_INS_NO]
      ,[ADULTS_1_INS_PRIVATE]
      ,[ADULTS_1_INS_PUBLIC]
      ,[ADULTS_1_WORK_10]
      ,[ADULTS_1_WORK_20]
      ,[ADULTS_1_WORK_37]
      ,[ADULTS_1_WORK_LESS10]
      ,[ADULTS_1_WORK_UNEMPLOY]
      ,[CLIENT_CARE_0_ER_HOSP]
      ,[CLIENT_EDUCATION_1_ENROLLED_FTPT]
      ,[CLIENT_INCOME_1_HH_SOURCES]
      ,[CLIENT_WORKING_1_CURRENTLY_WORKING_HRS]
      ,[DW_AuditDate]
      ,[DataSource]
      ,[CLIENT_EDUCATION_1_ENROLLED_PT_HRS]
      ,[CLIENT_SCHOOL_MIDDLE_HS]
      ,[CLIENT_ED_PROG_TYPE]
      ,[CLIENT_PROVIDE_CHILDCARE]
      ,[CLIENT_WORKING_2_CURRENTLY_WORKING_NO]
      ,[CLIENT_CARE_0_ER]
      ,[CLIENT_CARE_0_URGENT]
      ,[CLIENT_CARE_0_ER_TIMES]
      ,[CLIENT_CARE_0_URGENT_TIMES]
      ,[CLIENT_INCOME_IN_KIND]
      ,[CLIENT_INCOME_SOURCES]
      ,[CLIENT_MILITARY]
      ,[DELETE ME]
      ,[CLIENT_INCOME_AMOUNT]
      ,[CLIENT_WORKING_1_CURRENTLY_WORKING_NO]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_INCOME_INKIND_OTHER])) AS [CLIENT_INCOME_INKIND_OTHER]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_INCOME_OTHER_SOURCES])) AS [CLIENT_INCOME_OTHER_SOURCES]
      ,[CLIENT_BC_1_TYPES_NEXT6]
      ,[CLIENT_SUBPREG_1_EDD]
      ,[CLIENT_CARE_0_ER_PURPOSE]
      ,[CLIENT_CARE_0_URGENT_PURPOSE]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_CARE_0_URGENT_OTHER])) AS [CLIENT_CARE_0_URGENT_OTHER]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_CARE_0_ER_OTHER])) AS [CLIENT_CARE_0_ER_OTHER]
      ,[CLIENT_CARE_0_ER_FEVER_TIMES]
      ,[CLIENT_CARE_0_ER_INFECTION_TIMES]
      ,[CLIENT_CARE_0_ER_INGESTION_TIMES]
      ,[CLIENT_CARE_0_ER_INJURY_TIMES]
      ,[CLIENT_CARE_0_ER_OTHER_TIMES]
      ,[CLIENT_CARE_0_URGENT_FEVER_TIMES]
      ,[CLIENT_CARE_0_URGENT_INFECTION_TIMES]
      ,[CLIENT_CARE_0_URGENT_INGESTION_TIMES]
      ,[CLIENT_CARE_0_URGENT_INJURY_TIMES]
      ,[CLIENT_CARE_0_URGENT_OTHER_TIMES]
      ,[CLIENT_SECOND_1_CHILD_BW_MEASURE]
      ,[CLIENT_CARE_0_ URGENT_OTHER]
      ,[CLIENT_SECOND_1_CHILD_BW_CONVERT_GRAMS]
      ,[CLIENT_SECOND_1_CHILD_BW_GRAMS]
      ,[CLIENT_SUBPREG_1_GEST_AGE]
      ,[Master_SurveyID]
      ,[CLIENT_CARE_0_ER_PURPOSE_R6]
      ,[CLIENT_CARE_0_URGENT_PURPOSE_R6]
      ,[CLIENT_SUBPREG]
      ,[CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES]
      ,[CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES]
      ,[CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES]
      ,[CLIENT_CARE_0_ER_INGESTION_SELF_TIMES]
      ,[CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES]
      ,[CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES]
      ,[CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES]
      ,[CLIENT_CARE_0_ER_INJURY_SELF_TIMES]
      ,[CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES]
      ,[CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES]
      ,[CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES]
      ,[CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES]
      ,[CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES]
      ,[CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES]
      ,[CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES]
      ,[CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES]
      ,[Archive_Record]
      ,[CLIENT_INSURANCE_TYPE]
      ,[CLIENT_INSURANCE]
      ,[CLIENT_LIVING_HOMELESS]
      ,[CLIENT_LIVING_WHERE]
      ,[CLIENT_INSURANCE_OTHER]
  FROM [DataWarehouse].[dbo].[Demographics_Survey] s
	 WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileId AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	   AND ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	   AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
  
END
GO
