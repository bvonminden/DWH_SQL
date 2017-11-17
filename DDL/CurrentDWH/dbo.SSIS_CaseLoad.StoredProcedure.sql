USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSIS_CaseLoad]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Michael Osborn
-- Create date: 02/13/2014
-- Description:	Extract of caseload
-- Modified by: Jingjing
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in each 
--             recipient folder.
-- =============================================
CREATE PROCEDURE [dbo].[SSIS_CaseLoad]
	@ProfileID INT 
AS
BEGIN
	
	SET NOCOUNT ON;
	
	SELECT DISTINCT s.EntityID, 
					c.CLID,
					c.ProgramID, 
					c.StaffxClientID, 
					c.StartDate, 
					c.EndDate, 
					c.AuditDate
	FROM      dbo.StaffXEntities s
	INNER JOIN dbo.StaffxClientHx c
	ON s.StaffID = c.StaffID
	WHERE PROGRAMID in (select programid from ProgramsAndSites 
						 where SiteID in (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities 
										   WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))
	and ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	AND c.CLID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients)

END
GO
