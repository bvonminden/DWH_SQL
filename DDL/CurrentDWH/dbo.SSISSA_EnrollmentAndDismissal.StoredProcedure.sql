USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISSA_EnrollmentAndDismissal]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of [EnrollmentAndDismissal] data where the SiteID from [EnrollmentAndDismissal] is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing Gao
-- Modified Date: 11/30/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSISSA_EnrollmentAndDismissal]
	-- Add the parameters for the stored procedure here
	@ProfileID INT 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT [RecID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLID])) AS [CLID]
		  ,[SourceTable]
		  ,[SiteID]
		  ,[ProgramID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[ProgramStartDate])) AS [ProgramStartDate]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[EndDate])) AS [EndDate]
		  ,[TerminationReasonID]
		  ,[ReasonForDismissalID]
		  ,[ReasonForDismissal]
		  ,[Disabled]
		  ,[AuditStaffID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[AuditDate])) AS [AuditDate]
		  ,[ProgramSpecific]
		  ,[EmploymentSpecific]
		  ,[EducationSpecific]
		  ,[RejectionSpecific]
		  ,[MatchSpecific]
		  ,[SequenceOrder]
		  ,[ReasonForDismissalID_Source]
		  ,[SourceReasonForDismissalID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CaseNumber])) AS [CaseNumber]
		  ,[DataSource]
		  ,[SourceTableID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[LastModified])) AS [LastModified]
	  FROM [DataWarehouse].[dbo].[EnrollmentAndDismissal] s
	  WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	  and ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	  AND CLID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
	  
END
GO
