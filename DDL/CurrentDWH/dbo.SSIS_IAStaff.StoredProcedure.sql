USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSIS_IAStaff]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of IAStaff data where the SiteID from [IA_Staff] is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- =============================================
CREATE PROCEDURE [dbo].[SSIS_IAStaff] 
	-- Add the parameters for the stored procedure here
	@ProfileID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
--DECLARE @ProfileID INT --Testing
--SET @ProfileID = 27    --Testing

--SELECT *
--  FROM [DataWarehouse].[dbo].[IA_Staff]
--  WHERE 
--	   Entity_Subtype like '%nur%' 
--       AND Site_ID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0)

SELECT DISTINCT i.[Entity_Id]
      ,i.[Site_ID]
      ,i.[Full_Name]
      ,i.[Last_Name]
      ,i.[First_Name]
      ,i.[Middle_Name]
      ,i.[Prefix]
      ,i.[Suffix]
      ,i.[Entity_Type_ID]
      ,i.[Entity_Type]
      ,i.[Entity_Subtype]
      ,i.[Entity_Subtype_ID]
      ,i.[Program_ID]
      ,i.[Address1]
      ,i.[Address2]
      ,i.[City]
      ,i.[State]
      ,i.[ZipCode]
      ,i.[county]
      ,i.[Email]
      ,i.[Phone1]
      ,i.[Date_Created]
      ,i.[Audit_Date]
      ,i.[Contacts_Audit_Date]
      ,i.[Audit_Staff_ID]
      ,i.[Disabled]
      ,i.[CRM_ContactId]
      ,i.[LMS_StudentID]
      ,i.[Supervised_By_ID]
      ,i.[Termination_Date]
      ,i.[Last_CRM_Update]
      ,i.[Last_LMS_Update]
      ,i.[flag_update_LMS]
      ,i.[flag_update_crm]
      ,i.[NHV_ID]
      ,i.[NURSE_0_PROGRAM_POSITION]
      ,i.[NURSE_0_ETHNICITY]
      ,i.[NURSE_1_RACE]
      ,i.[NURSE_1_RACE_0]
      ,i.[NURSE_1_RACE_1]
      ,i.[NURSE_1_RACE_2]
      ,i.[NURSE_1_RACE_3]
      ,i.[NURSE_1_RACE_4]
      ,i.[NURSE_1_RACE_5]
      ,i.[NURSE_0_GENDER]
      ,i.[NURSE_0_YEAR_COMMHEALTH_EXPERIENCE]
      ,i.[NURSE_0_YEAR_NURSING_EXPERIENCE]
      ,i.[NURSE_0_YEAR_MATERNAL_EXPERIENCE]
      ,i.[NURSE_0_FIRST_HOME_VISIT_DATE]
      ,i.[NURSE_0_LANGUAGE]
      ,i.[START_DATE]
      ,i.[NURSE_0_YEAR_SUPERVISOR_EXPERIENCE]
      ,i.[NURSE_PERSONAL_0_ER_CONTACT]
      ,i.[NURSE_0_BIRTH_YEAR]
      ,i.[NURSE_0_ID_AGENCY]
      ,i.[Last_Attribute_Update]
      ,i.[flag_disregard_disabled]
      ,i.[NURSE_0_PROGRAM_POSITION1]
      ,i.[NURSE_0_PROGRAM_POSITION2]
      ,i.[NURSE_PROFESSIONAL_1_REASON_HIRE]
      ,i.[flag_dont_push_to_CRM]
      ,i.[DataSource]
      ,i.[ETO_LoginID]
      ,i.[ORIGINAL_START_DATE]
      ,i.[ETO_IntegrationID]
      ,i.[DW_Contact_ID]
FROM IA_Staff i
LEFT OUTER JOIN StaffXProgram p
ON i.Entity_Id = p.StaffID
WHERE Entity_Subtype like '%nur%' 
AND i.Site_ID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
AND (p.ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
  OR p.ProgramID is null)
 
END
GO
