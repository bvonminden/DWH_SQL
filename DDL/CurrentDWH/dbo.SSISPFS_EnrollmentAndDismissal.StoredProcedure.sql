USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFS_EnrollmentAndDismissal]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Create date: 1/13/2016
-- Description:	Extract of [EnrollmentAndDismissal] data where the SiteID from [EnrollmentAndDismissal] is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- *********************************************
-- Modified by: Jingjing Gao
-- Modified on: 02/14/2017
-- Description: Per Kyla's ticket#[00019665]:JPAL Raw Data Extract Modification, remove the filter "PFS_STUDY_VULNERABLE_POP = 0" because JPAL want to include all 
--              clients regardless the clients is vulnerable or not.
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFS_EnrollmentAndDismissal]
	@ProfileID INT
AS
BEGIN

	SET NOCOUNT ON;
	
	SELECT s.[RecID]
      ,s.[CLID]
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
      ,s.[CaseNumber]
      ,s.[DataSource]
      ,s.[SourceTableID]
      ,s.[LastModified]  
	FROM dbo.[EnrollmentAndDismissal] s
	INNER JOIN dbo.Clients c ON c.Client_Id = s.CLID
	WHERE SiteID in (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
					  WHERE ExportProfileID = @ProfileID)
	--AND c.PFS_STUDY_VULNERABLE_POP = 0
  
END

GO
