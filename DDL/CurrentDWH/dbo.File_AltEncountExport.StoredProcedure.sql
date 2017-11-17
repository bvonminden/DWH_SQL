USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[File_AltEncountExport]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Michael Osborn
-- Create date: 07/24/2014
-- Description:	Extract of Alternative Encounter data where the SiteID from Alternative_Encounter_Survey is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- =============================================
CREATE PROCEDURE [dbo].[File_AltEncountExport]
	-- Add the parameters for the stored procedure here
	@SiteID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--DECLARE @ProfileID AS INT
--SET @ProfileID = 27

SELECT *
  FROM [DataWarehouse].[dbo].[Alternative_Encounter_Survey]
  WHERE	SiteID IN(@SiteID)
  
END

GO
