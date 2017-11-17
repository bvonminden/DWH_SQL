USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFSDUA_CaseLoad]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Create date: 01/12/2016
-- Description:	Extract of caseload for Pay for Success
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFSDUA_CaseLoad]
	@ProfileID INT
AS
BEGIN

	SET NOCOUNT ON;
	
	SELECT  SXE.EntityID, 
			HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),SXC.CLID)) AS CLID, 
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
	AND PFS_STUDY_VULNERABLE_POP = 0

END


GO
