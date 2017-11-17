USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFSDUA_Clients]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Create date: 1/12/2016
-- Description:	Extract of Client data where the SiteID from Clients is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFSDUA_Clients]
	@ProfileID INT
AS
BEGIN

	SET NOCOUNT ON;

	SELECT DISTINCT HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[Client_Id])) AS [Client_Id]
		  ,[Site_ID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[Last_Name])) AS [Last_Name]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[First_Name])) AS [First_Name]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[Middle_Name])) AS [Middle_Name]
		  ,[Prefix]
		  ,[Suffix]
		  ,[DOB]
		  ,[Gender]
		  ,[Marital_Status]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[Address1])) AS [Address1]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[Address2])) AS [Address2]
		  ,[City]
		  ,[State]
		  ,[ZipCode]
		  ,[county]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[Email])) AS [Email]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[Home_Phone])) AS [Home_Phone]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[Cell_Phone])) AS [Cell_Phone]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[Work_Phone])) AS [Work_Phone]
		  ,[Work_Phone_Extension]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[Pager])) AS [Pager]
		  ,[Date_Created]
		  ,[Audit_Date]
		  ,[Audit_Staff_ID]
		  ,[Disabled]
		  ,[Funding_Entity_ID]
		  ,[Referral_Entity_ID]
		  ,[Assigned_Staff_ID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CRM_Client_ID])) AS [CRM_Client_ID]
		  ,[Last_CRM_Update]
		  ,[flag_update_crm]
		  ,[DEMO_CLIENT_INTAKE_0_ETHNICITY]
		  ,[DEMO_CLIENT_INTAKE_0_RACE]
		  ,[DEMO_CLIENT_INTAKE_0_RACE_10]
		  ,[DEMO_CLIENT_INTAKE_0_LANGUAGE]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CaseNumber])) AS [CaseNumber]
		  ,[Last_Demog_Update]
		  ,[CLIENT_PERSONAL_LANGUAGE_1_DESC]
		  ,[DataSource]
		  ,[ReasonForReferral]
		  ,[DEMO_CLIENT_INTAKE_0_ANCESTRY]
		  ,[DW_AuditDate]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[SSN])) AS [SSN]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_MEDICAID_NUMBER])) AS [CLIENT_MEDICAID_NUMBER]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CHILD_MEDICAID_NUMBER])) AS [CHILD_MEDICAID_NUMBER]
		  ,[INFANT_BIRTH_0_DOB]
      ,[LastModified]
      ,[PFS_STUDY_VULNERABLE_POP] 
	FROM dbo.Clients
	WHERE Site_ID in (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
					  WHERE ExportProfileID = @ProfileID)
	AND PFS_STUDY_VULNERABLE_POP = 0
	
END


GO
