USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[File_EnrollmentAndDismissal]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of [EnrollmentAndDismissal] data where the SiteID from [EnrollmentAndDismissal] is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- =============================================
CREATE PROCEDURE [dbo].[File_EnrollmentAndDismissal]
	-- Add the parameters for the stored procedure here
	@SiteID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
--DECLARE @ProfileID INT
--SET @ProfileID = 27

SELECT *
  FROM [DataWarehouse].[dbo].[EnrollmentAndDismissal]
  WHERE SiteID IN(@SiteID)
END

GO
