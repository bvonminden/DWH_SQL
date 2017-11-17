USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[File_CaseLoad]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Michael Osborn
-- Create date: 02/13/2014
-- Description:	Extract of caseload
-- =============================================
CREATE PROCEDURE [dbo].[File_CaseLoad]
	-- Add the parameters for the stored procedure here
	@SiteID INT 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
SELECT DISTINCT dbo.StaffXEntities.EntityID, 
				dbo.StaffxClientHx.CLID, 
				dbo.StaffxClientHx.ProgramID, 
				dbo.StaffxClientHx.StaffxClientID, 
				dbo.StaffxClientHx.StartDate, 
                dbo.StaffxClientHx.EndDate, 
                dbo.StaffxClientHx.AuditDate
FROM      dbo.StaffXEntities 
INNER JOIN dbo.StaffxClientHx ON dbo.StaffXEntities.StaffID = dbo.StaffxClientHx.StaffID
WHERE     PROGRAMID in (select programid from ProgramsAndSites where SiteID in (@SiteID))

END

GO
