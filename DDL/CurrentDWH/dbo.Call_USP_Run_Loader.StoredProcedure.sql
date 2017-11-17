USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[Call_USP_Run_Loader]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Sheri Scott
-- Create date: 1/8/2016
-- Description:	Calls another stored proc
-- =============================================
CREATE PROCEDURE [dbo].[Call_USP_Run_Loader]
	
AS
BEGIN

	SET NOCOUNT ON;
	
	DECLARE @DATE DATE = CONVERT(date, GETDATE())
	--This is a full reload. Drop tables and build, reload.
	--EXEC NFPBIDB01.NFP_DM_Reporting.dbo.USP_RUN_Loader 
	
    EXEC NFPBIDB01.NFP_DM_Reporting.dbo.USP_RUN_Loader @DATE
    
END

select CONVERT(date, GETDATE())
GO
