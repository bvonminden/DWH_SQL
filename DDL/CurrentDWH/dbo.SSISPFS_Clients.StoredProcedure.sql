USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFS_Clients]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Create date: 1/12/2016
-- Description:	Extract of Client data where the SiteID from Clients is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- Modify date: 12/15/2016
-- Modified by: Jingjing Gao
-- Description: Add two new columns "[DECLINED_CELL]" and "[ETO_ARCHIVED]"
-- *********************************************
-- Modified by: Jingjing Gao
-- Modified on: 02/14/2017
-- Description: Per Kyla's ticket#[00019665]:JPAL Raw Data Extract Modification, remove the filter "PFS_STUDY_VULNERABLE_POP = 0" because JPAL want to include all 
--              clients regardless the clients is vulnerable or not. 
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFS_Clients]
	@ProfileID INT
AS
BEGIN

	SET NOCOUNT ON;

SELECT  [Client_Id]
      ,[Site_ID]
      ,[Last_Name]
      ,[First_Name]
      ,[Middle_Name]
      ,[Prefix]
      ,[Suffix]
      ,[DOB]
      ,[Gender]
      ,[Marital_Status]
      ,[Address1]
      ,[Address2]
      ,[City]
      ,[State]
      ,[ZipCode]
      ,[county]
      ,[Email]
      ,[Home_Phone]
      ,[Cell_Phone]
      ,[Work_Phone]
      ,[Work_Phone_Extension]
      ,[Pager]
      ,[Date_Created]
      ,[Audit_Date]
      ,[Audit_Staff_ID]
      ,[Disabled]
      ,[Funding_Entity_ID]
      ,[Referral_Entity_ID]
      ,[Assigned_Staff_ID]
      ,[CRM_Client_ID]
      ,[Last_CRM_Update]
      ,[flag_update_crm]
      ,[DEMO_CLIENT_INTAKE_0_ETHNICITY]
      ,[DEMO_CLIENT_INTAKE_0_RACE]
      ,[DEMO_CLIENT_INTAKE_0_RACE_10]
      ,[DEMO_CLIENT_INTAKE_0_LANGUAGE]
      ,[CaseNumber]
      ,[Last_Demog_Update]
      ,[CLIENT_PERSONAL_LANGUAGE_1_DESC]
      ,[DataSource]
      ,[ReasonForReferral]
      ,[DEMO_CLIENT_INTAKE_0_ANCESTRY]
      ,[DW_AuditDate]
      ,[SSN]
      ,[CLIENT_MEDICAID_NUMBER]
      ,[CHILD_MEDICAID_NUMBER]
      ,[INFANT_BIRTH_0_DOB]
      ,[LastModified]
      ,[PFS_STUDY_VULNERABLE_POP]
      ,[DECLINED_CELL]
      ,[ETO_ARCHIVED]
	FROM dbo.Clients
	WHERE Site_ID in (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
					  WHERE ExportProfileID = @ProfileID)
	--AND PFS_STUDY_VULNERABLE_POP = 0
	
END

GO
