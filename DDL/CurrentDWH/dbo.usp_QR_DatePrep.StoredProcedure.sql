USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_QR_DatePrep]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Michael Osborn
-- Create date: 06032016
-- Description:	Returns a year and quarter which feeds into the QuartlyReports. 
-- =============================================
CREATE PROCEDURE [dbo].[usp_QR_DatePrep]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	--Automatically return a year and quarter
	SELECT DISTINCT CAST( 2000+Year AS VARCHAR(4)), CAST(Quarter AS VARCHAR(1))
	FROM [UV_ReportAutomation] 

	--Manualy Set a year and quarter for return
	--SELECT DISTINCT CAST(2015 AS VARCHAR(4)), CAST(4 AS VARCHAR(1))
END
GO
