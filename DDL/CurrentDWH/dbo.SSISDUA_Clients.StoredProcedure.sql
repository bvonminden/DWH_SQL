USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISDUA_Clients]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of Client data where the SiteID from Clients is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- ************************************************
-- Modified by: Jingjing Gao
-- Modified Date:12/8/2016
-- Description: Four columns are added in the form: "LastModified", "PFS_STUDY_VULNERABLE_POP", "DECLINED_CELL", "ETO_ARCHIVED" and need to be reflected
--              in "Participants_and_Referrals" file in the data extract. According to Ticket#33134.
-- =============================================
CREATE PROCEDURE [dbo].[SSISDUA_Clients]
	-- Add the parameters for the stored procedure here
	@ProfileID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT DISTINCT HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),c.[Client_Id])) AS [Client_Id]
		  ,c.[Site_ID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),c.[Last_Name])) AS [Last_Name]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),c.[First_Name])) AS [First_Name]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),c.[Middle_Name])) AS [Middle_Name]
		  ,c.[Prefix]
		  ,c.[Suffix]
		  ,c.[DOB]
		  ,c.[Gender]
		  ,c.[Marital_Status]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),c.[Address1])) AS [Address1]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),c.[Address2])) AS [Address2]
		  ,c.[City]
		  ,c.[State]
		  ,c.[ZipCode]
		  ,c.[county]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),c.[Email])) AS [Email]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),c.[Home_Phone])) AS [Home_Phone]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),c.[Cell_Phone])) AS [Cell_Phone]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),c.[Work_Phone])) AS [Work_Phone]
		  ,c.[Work_Phone_Extension]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),c.[Pager])) AS [Pager]
		  ,c.[Date_Created]
		  ,c.[Audit_Date]
		  ,c.[Audit_Staff_ID]
		  ,c.[Disabled]
		  ,c.[Funding_Entity_ID]
		  ,c.[Referral_Entity_ID]
		  ,c.[Assigned_Staff_ID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),c.[CRM_Client_ID])) AS [CRM_Client_ID]
		  ,c.[Last_CRM_Update]
		  ,c.[flag_update_crm]
		  ,c.[DEMO_CLIENT_INTAKE_0_ETHNICITY]
		  ,c.[DEMO_CLIENT_INTAKE_0_RACE]
		  ,c.[DEMO_CLIENT_INTAKE_0_RACE_10]
		  ,c.[DEMO_CLIENT_INTAKE_0_LANGUAGE]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),c.[CaseNumber])) AS [CaseNumber]
		  ,c.[Last_Demog_Update]
		  ,c.[CLIENT_PERSONAL_LANGUAGE_1_DESC]
		  ,c.[DataSource]
		  ,c.[ReasonForReferral]
		  ,c.[DEMO_CLIENT_INTAKE_0_ANCESTRY]
		  ,c.[DW_AuditDate]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),c.[SSN])) AS [SSN]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),c.[CLIENT_MEDICAID_NUMBER])) AS [CLIENT_MEDICAID_NUMBER]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),c.[CHILD_MEDICAID_NUMBER])) AS [CHILD_MEDICAID_NUMBER]
		  ,c.[INFANT_BIRTH_0_DOB]
		  ,c.[LastModified]				/***new column added on 12/8/2016 according to Ticket#33134****/
          ,c.[PFS_STUDY_VULNERABLE_POP] /***new column added on 12/8/2016 according to Ticket#33134****/
          ,c.[DECLINED_CELL]			/***new column added on 12/8/2016 according to Ticket#33134****/
          ,c.[ETO_ARCHIVED]				/***new column added on 12/8/2016 according to Ticket#33134****/
	FROM dbo.Clients c
	INNER JOIN dbo.EnrollmentAndDismissal ead
	ON ead.CLID = c.Client_Id 
	WHERE c.Site_ID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	AND ead.ProgramID NOT IN (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	AND c.Client_Id NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = c.Site_ID)

END
GO
