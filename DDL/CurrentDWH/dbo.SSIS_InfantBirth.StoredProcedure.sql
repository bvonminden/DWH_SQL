USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSIS_InfantBirth]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Mike Osborn
-- Create date: 09/24/2013
-- Description:	Extract of InfantBirth data where the SiteID from [Infant_Birth_Survey] is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSIS_InfantBirth]
	@ProfileID INT
AS
BEGIN

	SET NOCOUNT ON;
	
SELECT [SurveyResponseID]
      ,[ElementsProcessed]
      ,[SurveyID]
      ,[SurveyDate]
      ,[AuditDate]
      ,[CL_EN_GEN_ID]
      ,[SiteID]
      ,[ProgramID]
      ,[IA_StaffID]
      ,[ClientID]
      ,[RespondentID]
      ,[INFANT_0_ID_NSO]
      ,[INFANT_PERSONAL_0_FIRST NAME]
      ,[INFANT_BIRTH_0_DOB]
      ,[CLIENT_0_ID_NSO]
      ,[CLIENT_PERSONAL_0_NAME_FIRST]
      ,[CLIENT_PERSONAL_0_NAME_LAST]
      ,[NURSE_PERSONAL_0_NAME]
      ,[INFANT_BIRTH_1_MULTIPLE_BIRTHS]
      ,[INFANT_PERSONAL_0_ETHNICITY]
      ,[INFANT_PERSONAL_0_RACE]
      ,[INFANT_PERSONAL_0_GENDER]
      ,[INFANT_BIRTH_1_WEIGHT_GRAMS]
      ,[INFANT_BIRTH_1_WEIGHT_POUNDS]
      ,[INFANT_BIRTH_1_GEST_AGE]
      ,[INFANT_BIRTH_1_NICU]
      ,[INFANT_BIRTH_1_NICU_DAYS]
      ,[CLIENT_WEIGHT_0_PREG_GAIN]
      ,[INFANT_BREASTMILK_0_EVER_BIRTH]
      ,[INFANT_0_ID_NSO2]
      ,[INFANT_PERSONAL_0_FIRST NAME2]
      ,[INFANT_BIRTH_0_DOB2]
      ,[INFANT_PERSONAL_0_ETHNICITY2]
      ,[INFANT_PERSONAL_0_ETHNICITY3]
      ,[INFANT_PERSONAL_0_RACE2]
      ,[INFANT_PERSONAL_0_RACE3]
      ,[INFANT_PERSONAL_0_GENDER2]
      ,[INFANT_BIRTH_1_WEIGHT_GRAMS2]
      ,[INFANT_BIRTH_1_GEST_AGE2]
      ,[INFANT_BIRTH_1_NICU2]
      ,[INFANT_BIRTH_1_NICU_DAYS2]
      ,[INFANT_0_ID_NSO3]
      ,[INFANT_BIRTH_0_DOB3]
      ,[INFANT_PERSONAL_0_GENDER3]
      ,[INFANT_BIRTH_1_WEIGHT_GRAMS3]
      ,[INFANT_BIRTH_1_WEIGHT_POUNDS3]
      ,[INFANT_BIRTH_1_GEST_AGE3]
      ,[INFANT_BIRTH_1_NICU3]
      ,[INFANT_BIRTH_1_NICU_DAYS3]
      ,[INFANT_BREASTMILK_0_EVER_BIRTH2]
      ,[INFANT_BREASTMILK_0_EVER_BIRTH3]
      ,[INFANT_BIRTH_1_WEIGHT_MEASURE]
      ,[INFANT_BIRTH_1_WEIGHT_OUNCES]
      ,[INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS]
      ,[INFANT_BIRTH_1_WEIGHT_MEASURE2]
      ,[INFANT_BIRTH_1_WEIGHT_MEASURE3]
      ,[INFANT_BIRTH_1_WEIGHT_OUNCES3]
      ,[INFANT_BIRTH_1_WEIGHT_POUNDS2]
      ,[INFANT_BIRTH_1_WEIGHT_OUNCES2]
      ,[INFANT_PERSONAL_0_FIRST NAME3]
      ,[CLIENT_0_ID_AGENCY]
      ,[INFANT_PERSONAL_0_LAST NAME]
      ,[DW_AuditDate]
      ,[DataSource]
      ,[INFANT_BIRTH_0_CLIENT_ER]
      ,[INFANT_BIRTH_0_CLIENT_URGENT CARE]
      ,[INFANT_BIRTH_1_NICU_R2]
      ,[INFANT_BIRTH_1_NICU_R2_2]
      ,[INFANT_BIRTH_1_NICU_R2_3]
      ,[INFANT_BIRTH_1_NURSERY_R2]
      ,[INFANT_BIRTH_1_NURSERY_R2_2]
      ,[INFANT_BIRTH_1_NURSERY_R2_3]
      ,[INFANT_BIRTH_0_CLIENT_ER_TIMES]
      ,[INFANT_BIRTH_0_CLIENT_URGENT CARE_TIMES]
      ,[INFANT_BIRTH_1_NICU_DAYS_R2]
      ,[INFANT_BIRTH_1_NICU_DAYS_R2_2]
      ,[INFANT_BIRTH_1_NICU_DAYS_R2_3]
      ,[INFANT_BIRTH_1_NURSERY_DAYS_R2]
      ,[INFANT_BIRTH_1_NURSERY_DAYS_R2_2]
      ,[INFANT_BIRTH_1_NURSERY_DAYS_R2_3]
      ,[INFANT_BIRTH_1_NICU_NURSERY_PURPOSE]
      ,[INFANT_BIRTH_1_NICU_NURSERY_PURPOSE2]
      ,[INFANT_BIRTH_1_NICU_NURSERY_PURPOSE3]
      ,[INFANT_BIRTH_1_DELIVERY]
      ,[INFANT_BIRTH_1_HEARING_SCREEN]
      ,[INFANT_BIRTH_1_HEARING_SCREEN2]
      ,[INFANT_BIRTH_1_HEARING_SCREEN3]
      ,[INFANT_BIRTH_1_LABOR]
      ,[INFANT_BIRTH_1_NEWBORN_SCREEN]
      ,[INFANT_BIRTH_1_NEWBORN_SCREEN2]
      ,[INFANT_BIRTH_1_NEWBORN_SCREEN3]
      ,[INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER]
      ,[INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER2]
      ,[INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER3]
      ,[Master_SurveyID]
      ,[INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS2]
      ,[INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS3]
      ,[LastModified]
      ,[Archive_Record]
      ,[INFANT_INSURANCE_TYPE]
      ,[INFANT_INSURANCE_TYPE2]
      ,[INFANT_INSURANCE_TYPE3]
      ,[INFANT_BIRTH_COSLEEP]
      ,[INFANT_BIRTH_COSLEEP2]
      ,[INFANT_BIRTH_COSLEEP3]
      ,[INFANT_BIRTH_READ]
      ,[INFANT_BIRTH_READ2]
      ,[INFANT_BIRTH_READ3]
      ,[INFANT_BIRTH_SLEEP_BACK]
      ,[INFANT_BIRTH_SLEEP_BACK2]
      ,[INFANT_BIRTH_SLEEP_BACK3]
      ,[INFANT_BIRTH_SLEEP_BEDDING]
      ,[INFANT_BIRTH_SLEEP_BEDDING2]
      ,[INFANT_BIRTH_SLEEP_BEDDING3]
      ,[INFANT_INSURANCE]
      ,[INFANT_INSURANCE2]
      ,[INFANT_INSURANCE3]
      ,[INFANT_INSURANCE_OTHER]
      ,[INFANT_INSURANCE_OTHER2]
      ,[INFANT_INSURANCE_OTHER3]
  FROM [DataWarehouse].[dbo].[Infant_Birth_Survey] s
  WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
  and ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
  AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
  
END
GO
