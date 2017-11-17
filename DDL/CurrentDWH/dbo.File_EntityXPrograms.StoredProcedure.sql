USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[File_EntityXPrograms]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop PROCEDURE [dbo].[File_EntityXPrograms] 
-- =============================================
-- Author:		
-- Create date: 5/3/2016
-- Description:	Extract entity history data
-- =============================================
CREATE PROCEDURE [dbo].[File_EntityXPrograms] 
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
  FROM [DataWarehouse].[dbo].[EntityXPrograms]
  
 WHERE Program_ID in(SELECT ProgramID from dbo.ProgramsAndSites WHERE SiteID = @SiteID)
END


GO
