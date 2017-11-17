USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISPFS_ProgramAndSites]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Sheri Scott
-- Create date: 1/13/2016
-- Description:	Extract of ProgramAndSites data where the SiteID from ProgramAndSites is the
--				same as ExportPFSEntities SiteID and ExportProfileID is the same as the passed ProfileID
--				for Pay For Success where clients are over the age of 14
-- =============================================
CREATE PROCEDURE [dbo].[SSISPFS_ProgramAndSites] 
	@ProfileID INT
AS
BEGIN

	SET NOCOUNT ON;

  SELECT @ProfileID AS [ExportID], ProgramID, ProgramName, SiteID, [Site] 
    FROM dbo.ProgramsAndSites
    WHERE
	SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
				WHERE ExportProfileID = @ProfileID)

END

GO
