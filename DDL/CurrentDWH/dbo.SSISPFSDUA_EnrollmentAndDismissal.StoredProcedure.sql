USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFSDUA_EnrollmentAndDismissal]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Create date: 1/13/2016
-- Description:	Extract of [EnrollmentAndDismissal] data where the SiteID from [EnrollmentAndDismissal] is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFSDUA_EnrollmentAndDismissal]
	@ProfileID INT
AS
BEGIN

	SET NOCOUNT ON;
	
	SELECT s.[RecID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CLID])) AS [CLID]
		  ,s.[SourceTable]
		  ,s.[SiteID]
		  ,s.[ProgramID]
		  ,s.[ProgramStartDate]
		  ,s.[EndDate]
		  ,s.[TerminationReasonID]
		  ,s.[ReasonForDismissalID]
		  ,s.[ReasonForDismissal]
		  ,s.[Disabled]
		  ,s.[AuditStaffID]
		  ,s.[AuditDate]
		  ,s.[ProgramSpecific]
		  ,s.[EmploymentSpecific]
		  ,s.[EducationSpecific]
		  ,s.[RejectionSpecific]
		  ,s.[MatchSpecific]
		  ,s.[SequenceOrder]
		  ,s.[ReasonForDismissalID_Source]
		  ,s.[SourceReasonForDismissalID]
		  ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),s.[CaseNumber])) AS [CaseNumber]
		  ,s.[DataSource]
		  ,s.[SourceTableID]
		  ,s.[LastModified]
	FROM dbo.[EnrollmentAndDismissal] s
	INNER JOIN dbo.Clients c ON c.Client_Id = s.CLID
	WHERE SiteID in (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
					  WHERE ExportProfileID = @ProfileID)
	AND c.PFS_STUDY_VULNERABLE_POP = 0
  
END


GO
