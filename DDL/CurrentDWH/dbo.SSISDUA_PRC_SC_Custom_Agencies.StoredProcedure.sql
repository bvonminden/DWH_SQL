USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISDUA_PRC_SC_Custom_Agencies]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Jingjing Gao
-- Create date: 04/20/2017
-- Description:	Extract of Client for PRC SC sites;
-- Export Requirements: 
-- 1)	De-identified data for customer
-- 2)	South Carolina sites only. Site IDs: 218, 219,235,236,242,243,296,384,385,413 (PRC CONFIRMING)
-- =============================================
CREATE PROCEDURE [dbo].[SSISDUA_PRC_SC_Custom_Agencies]
	-- Add the parameters for the stored procedure here
	@ProfileID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	


/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [Entity_Id]
      ,[AGENCY_INFO_0_NAME]
      ,[Site_ID]
      ,[Site_Alias]
      ,[Entity_Type_ID]
      ,[Entity_Type]
      ,[Entity_Subtype]
      ,[Entity_Subtype_ID]
      ,[Agency_Status]
      ,[Program_ID]
      ,[Address1]
      ,[Address2]
      ,[City]
      ,[State]
      ,[ZipCode]
      ,[county]
      ,[Phone1]
      ,[Site_Address1]
      ,[Site_Address2]
      ,[Site_City]
      ,[Site_State]
      ,[Site_ZipCode]
      ,[Site_County]
      ,[Site_Phone1]
      ,[Date_Created]
      ,[Audit_Date]
      ,[Site_Audit_Date]
      ,[Audit_Staff_ID]
      ,[Entity_Disabled]
      ,[Site_Disabled]
      ,[CRM_AccountId]
      ,[LMS_OrganizationID]
      ,[Last_CRM_Update]
      ,[Last_LMS_Update]
      ,[flag_update_LMS]
      ,[flag_update_crm]
      ,[CRM_ID]
      ,[AGENCY_INFO_1_COUNTY]
      ,[AGENCY_INFO_1_TYPE]
      ,[AGENCY_INFO_1_LOWINCOME_CRITERA]
      ,[AGENCY_INFO_1_LOWINCOME_PERCENT]
      ,[AGENCY_INFO_1_LOWINCOME_DESCRIPTION]
      ,[AGENCY_INFO_1_WEBSITE]
      ,[AGENCY_INFO_1_INITIATION_DATE]
      ,[AGENCY_DATE_FIRST_HOME_VISIT]
      ,[AGENCY_INFO_1_MILEAGE_RATE]
      ,[last_attribute_update]
      ,[DataSource]
      ,[SERVICE_LEVEL_COVERED]
      ,[Start_Date]
      ,[End_Date]
      ,[LastModified]
      ,[Site_Name]
  FROM [DataWarehouse].[dbo].[Agencies]
  WHERE Site_ID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
  and ISNULL(Program_ID,'') not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)

END


GO
