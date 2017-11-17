USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[File_Clients]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of Client data where the SiteID from Clients is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- =============================================
CREATE PROCEDURE [dbo].[File_Clients]
	-- Add the parameters for the stored procedure here
	@SiteID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

--DECLARE @ProfileID int
--SET @ProfileID = 27

SELECT *
  FROM [DataWarehouse].[dbo].[Clients]
  WHERE Site_ID IN(@SiteID)
END

GO
