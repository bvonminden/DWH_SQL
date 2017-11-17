USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[File_StaffXEntities]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Michael Osborn
-- Create date: 08/20/2014
-- Description:	Return Staff Entity Data
-- =============================================
CREATE PROCEDURE [dbo].[File_StaffXEntities] 
	-- Add the parameters for the stored procedure here
	@SiteID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--DECLARE @ProfileID INT
--SET @ProfileID = 27

SELECT 
	  DISTINCT EntityID,
	  StaffXEntityID,
	  dbo.StaffxClientHx.StaffID,
      TargetSiteID,
      dbo.StaffxClientHx.AuditDate,
      cast(dbo.StaffxClientHx.DataSource as varchar) AS 'DataSource'
FROM dbo.StaffXEntities 
INNER JOIN dbo.StaffxClientHx ON dbo.StaffXEntities.StaffID = dbo.StaffxClientHx.StaffID
WHERE (dbo.StaffxClientHx.ProgramID IN(SELECT ProgramID FROM dbo.ProgramsAndSites WHERE (SiteID IN (@SiteID))))

END


GO
