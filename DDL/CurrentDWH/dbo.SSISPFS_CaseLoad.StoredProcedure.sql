USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFS_CaseLoad]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Create date: 01/12/2016
-- Description:	Extract of caseload for Pay for Success
-- *******************************
-- Modified by: Jingjing Gao
-- Modified on: 02/14/2017
-- Description: Per Kyla's ticket#[00019665]:JPAL Raw Data Extract Modification, remove the filter "PFS_STUDY_VULNERABLE_POP = 0" because JPAL want to include all 
--              clients regardless the clients is vulnerable or not. 
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFS_CaseLoad]
	@ProfileID INT
AS
BEGIN

	SET NOCOUNT ON;
	
	SELECT  SXE.EntityID, 
			SXC.CLID, 
			SXC.ProgramID, 
			SXC.StaffxClientID, 
			SXC.StartDate, 
			SXC.EndDate, 
			SXC.AuditDate
	FROM dbo.StaffXEntities SXE
	INNER JOIN dbo.StaffxClientHx SXC ON SXE.StaffID = SXC.StaffID
	INNER JOIN dbo.Clients c ON c.Client_Id = SXC.CLID
	WHERE SXC.ProgramID in (select programid from ProgramsAndSites 
							 where SiteID in (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
											   WHERE ExportProfileID = @ProfileID))
	--AND PFS_STUDY_VULNERABLE_POP = 0

END

GO
