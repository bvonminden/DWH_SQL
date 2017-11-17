USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISDUA_PRC_SC_Custom_EnrollmentAndDismissal]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Jingjing Gao
-- Create date: 03/30/2017
-- Description:	Extract of Client for PRC SC sites;
-- Export Requirements: 
-- 1)	De-identified data for customer
-- 2)	South Carolina sites only. Site IDs: 218, 219,235,236,242,243,296,384,385,413 (PRC CONFIRMING)
-- =============================================
CREATE PROCEDURE [dbo].[SSISDUA_PRC_SC_Custom_EnrollmentAndDismissal]
	-- Add the parameters for the stored procedure here
	@ProfileID INT 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT --[RecID]
		  HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLID])) AS [CLID]
		  --,[SourceTable]
		  ,[SiteID]
		  ,[ProgramID]
		  ,[ProgramStartDate]
		  ,[EndDate]
		  --,[TerminationReasonID]
		  --,[ReasonForDismissalID]
		  ,[ReasonForDismissal]
		  --,[Disabled]
		  --,[AuditStaffID]
		  --,[AuditDate]
		  --,[ProgramSpecific]
		  --,[EmploymentSpecific]
		  --,[EducationSpecific]
		  --,[RejectionSpecific]
		  --,[MatchSpecific]
		  --,[SequenceOrder]
		  --,[ReasonForDismissalID_Source]
		  --,[SourceReasonForDismissalID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CaseNumber])) AS [CaseNumber]
		  --,[DataSource]
		  --,[SourceTableID]
		  --,[LastModified]
	  FROM [DataWarehouse].[dbo].[EnrollmentAndDismissal] s
	  WHERE SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	  and ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	  AND CLID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
	  
END

GO
