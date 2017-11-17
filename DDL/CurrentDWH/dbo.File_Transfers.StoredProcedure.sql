USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[File_Transfers]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Michael Osborn
-- Create date: 08/20/2014
-- Description:	Return Team Data
-- =============================================
CREATE PROCEDURE [dbo].[File_Transfers] 
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
  FROM [DataWarehouse].[dbo].[Transfers]
  WHERE EntityID = @SiteID

END


GO
