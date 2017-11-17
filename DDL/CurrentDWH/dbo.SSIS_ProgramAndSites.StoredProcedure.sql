USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSIS_ProgramAndSites]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Michael Osborn
-- Create date: 01/23/2015
-- Description:	Extract of ProgramAndSites data where the SiteID from ProgramAndSites is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- =============================================
CREATE PROCEDURE [dbo].[SSIS_ProgramAndSites] 
	-- Add the parameters for the stored procedure here
	@ProfileID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--DECLARE @ProfileID INT
--SET @ProfileID = 27

  SELECT @ProfileID AS [ExportID], ProgramID, ProgramName, SiteID, [Site] FROM dbo.ProgramsAndSites
    WHERE
	SiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	and ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)

END
GO
