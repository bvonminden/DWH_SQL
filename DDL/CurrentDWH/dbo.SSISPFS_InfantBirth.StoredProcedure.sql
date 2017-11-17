USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFS_InfantBirth]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Sheri Scott
-- Create date: 1/13/2016
-- Description:	Extract of InfantBirth data where the SiteID from [Infant_Birth_Survey] is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- *********************************************
-- Modified by: Jingjing Gao
-- Modified on: 02/14/2017
-- Description: Per Kyla's ticket#[00019665]:JPAL Raw Data Extract Modification, remove the filter "PFS_STUDY_VULNERABLE_POP = 0" because JPAL want to include all 
--              clients regardless the clients is vulnerable or not. In addition, joining condition need to be changed. Use [CL_EN_GEN_ID] instead of [CLIENT_0_ID_NSO]
--              to join [dbo].[Clients] table.
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFS_InfantBirth]
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
      ,s.[INFANT_0_ID_NSO]
      ,s.[INFANT_PERSONAL_0_FIRST NAME]
      ,s.[INFANT_BIRTH_0_DOB]
      ,s.[CLIENT_0_ID_NSO]
      ,s.[CLIENT_PERSONAL_0_NAME_FIRST]
      ,s.[CLIENT_PERSONAL_0_NAME_LAST]
      ,s.[NURSE_PERSONAL_0_NAME]
      ,s.[INFANT_BIRTH_1_MULTIPLE_BIRTHS]
      ,s.[INFANT_PERSONAL_0_ETHNICITY]
      ,s.[INFANT_PERSONAL_0_RACE]
      ,s.[INFANT_PERSONAL_0_GENDER]
      ,s.[INFANT_BIRTH_1_WEIGHT_GRAMS]
      ,s.[INFANT_BIRTH_1_WEIGHT_POUNDS]
      ,s.[INFANT_BIRTH_1_GEST_AGE]
      ,s.[INFANT_BIRTH_1_NICU]
      ,s.[INFANT_BIRTH_1_NICU_DAYS]
      ,s.[CLIENT_WEIGHT_0_PREG_GAIN]
      ,s.[INFANT_BREASTMILK_0_EVER_BIRTH]
      ,s.[INFANT_0_ID_NSO2]
      ,s.[INFANT_PERSONAL_0_FIRST NAME2]
      ,s.[INFANT_BIRTH_0_DOB2]
      ,s.[INFANT_PERSONAL_0_ETHNICITY2]
      ,s.[INFANT_PERSONAL_0_ETHNICITY3]
      ,s.[INFANT_PERSONAL_0_RACE2]
      ,s.[INFANT_PERSONAL_0_RACE3]
      ,s.[INFANT_PERSONAL_0_GENDER2]
      ,s.[INFANT_BIRTH_1_WEIGHT_GRAMS2]
      ,s.[INFANT_BIRTH_1_GEST_AGE2]
      ,s.[INFANT_BIRTH_1_NICU2]
      ,s.[INFANT_BIRTH_1_NICU_DAYS2]
      ,s.[INFANT_0_ID_NSO3]
      ,s.[INFANT_BIRTH_0_DOB3]
      ,s.[INFANT_PERSONAL_0_GENDER3]
      ,s.[INFANT_BIRTH_1_WEIGHT_GRAMS3]
      ,s.[INFANT_BIRTH_1_WEIGHT_POUNDS3]
      ,s.[INFANT_BIRTH_1_GEST_AGE3]
      ,s.[INFANT_BIRTH_1_NICU3]
      ,s.[INFANT_BIRTH_1_NICU_DAYS3]
      ,s.[INFANT_BREASTMILK_0_EVER_BIRTH2]
      ,s.[INFANT_BREASTMILK_0_EVER_BIRTH3]
      ,s.[INFANT_BIRTH_1_WEIGHT_MEASURE]
      ,s.[INFANT_BIRTH_1_WEIGHT_OUNCES]
      ,s.[INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS]
      ,s.[INFANT_BIRTH_1_WEIGHT_MEASURE2]
      ,s.[INFANT_BIRTH_1_WEIGHT_MEASURE3]
      ,s.[INFANT_BIRTH_1_WEIGHT_OUNCES3]
      ,s.[INFANT_BIRTH_1_WEIGHT_POUNDS2]
      ,s.[INFANT_BIRTH_1_WEIGHT_OUNCES2]
      ,s.[INFANT_PERSONAL_0_FIRST NAME3]
      ,s.[CLIENT_0_ID_AGENCY]
      ,s.[INFANT_PERSONAL_0_LAST NAME]
      ,s.[DW_AuditDate]
      ,s.[DataSource]
      ,s.[INFANT_BIRTH_0_CLIENT_ER]
      ,s.[INFANT_BIRTH_0_CLIENT_URGENT CARE]
      ,s.[INFANT_BIRTH_1_NICU_R2]
      ,s.[INFANT_BIRTH_1_NICU_R2_2]
      ,s.[INFANT_BIRTH_1_NICU_R2_3]
      ,s.[INFANT_BIRTH_1_NURSERY_R2]
      ,s.[INFANT_BIRTH_1_NURSERY_R2_2]
      ,s.[INFANT_BIRTH_1_NURSERY_R2_3]
      ,s.[INFANT_BIRTH_0_CLIENT_ER_TIMES]
      ,s.[INFANT_BIRTH_0_CLIENT_URGENT CARE_TIMES]
      ,s.[INFANT_BIRTH_1_NICU_DAYS_R2]
      ,s.[INFANT_BIRTH_1_NICU_DAYS_R2_2]
      ,s.[INFANT_BIRTH_1_NICU_DAYS_R2_3]
      ,s.[INFANT_BIRTH_1_NURSERY_DAYS_R2]
      ,s.[INFANT_BIRTH_1_NURSERY_DAYS_R2_2]
      ,s.[INFANT_BIRTH_1_NURSERY_DAYS_R2_3]
      ,s.[INFANT_BIRTH_1_NICU_NURSERY_PURPOSE]
      ,s.[INFANT_BIRTH_1_NICU_NURSERY_PURPOSE2]
      ,s.[INFANT_BIRTH_1_NICU_NURSERY_PURPOSE3]
      ,s.[INFANT_BIRTH_1_DELIVERY]
      ,s.[INFANT_BIRTH_1_HEARING_SCREEN]
      ,s.[INFANT_BIRTH_1_HEARING_SCREEN2]
      ,s.[INFANT_BIRTH_1_HEARING_SCREEN3]
      ,s.[INFANT_BIRTH_1_LABOR]
      ,s.[INFANT_BIRTH_1_NEWBORN_SCREEN]
      ,s.[INFANT_BIRTH_1_NEWBORN_SCREEN2]
      ,s.[INFANT_BIRTH_1_NEWBORN_SCREEN3]
      ,s.[INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER]
      ,s.[INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER2]
      ,s.[INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER3]
      ,s.[Master_SurveyID]
      ,s.[INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS2]
      ,s.[INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS3]
      ,s.[LastModified]  
      ,s.[Archive_Record]
      ,s.[INFANT_INSURANCE_TYPE]
      ,s.[INFANT_INSURANCE_TYPE2]
      ,s.[INFANT_INSURANCE_TYPE3]
      ,s.[INFANT_BIRTH_COSLEEP]
      ,s.[INFANT_BIRTH_COSLEEP2]
      ,s.[INFANT_BIRTH_COSLEEP3]
      ,s.[INFANT_BIRTH_READ]
      ,s.[INFANT_BIRTH_READ2]
      ,s.[INFANT_BIRTH_READ3]
      ,s.[INFANT_BIRTH_SLEEP_BACK]
      ,s.[INFANT_BIRTH_SLEEP_BACK2]
      ,s.[INFANT_BIRTH_SLEEP_BACK3]
      ,s.[INFANT_BIRTH_SLEEP_BEDDING]
      ,s.[INFANT_BIRTH_SLEEP_BEDDING2]
      ,s.[INFANT_BIRTH_SLEEP_BEDDING3]
      ,s.[INFANT_INSURANCE]
      ,s.[INFANT_INSURANCE2]
      ,s.[INFANT_INSURANCE3]
      ,s.[INFANT_INSURANCE_OTHER]
      ,s.[INFANT_INSURANCE_OTHER2]
      ,s.[INFANT_INSURANCE_OTHER3] 
	FROM dbo.[Infant_Birth_Survey] s
	INNER JOIN dbo.Clients c ON c.Client_Id = s.[CL_EN_GEN_ID]
	WHERE SiteID in (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
					  WHERE ExportProfileID = @ProfileID)
	--AND c.PFS_STUDY_VULNERABLE_POP = 0
	
END

GO
