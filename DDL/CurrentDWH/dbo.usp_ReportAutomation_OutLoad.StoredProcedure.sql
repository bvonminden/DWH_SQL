USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_ReportAutomation_OutLoad]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_ReportAutomation_OutLoad]

AS

DECLARE

		@StartDate DATE
		,@EndDate DATE 
		,@CompStartDate DATE 
		,@CompEndDate DATE 
		,@ParentEntity VARCHAR(4000)
		,@REName VARCHAR(50) 
		,@ReportType VARCHAR(50) 
		,@Data INT 

SET @StartDate = (SELECT TOP 1 StartDate FROM UV_ReportAutomation WHERE MyCounter = 3)
SET	@EndDate = (SELECT TOP 1 EndDate FROM UV_ReportAutomation WHERE MyCounter = 3)
SET	@CompStartDate = (SELECT TOP 1 CompStartDate FROM UV_ReportAutomation WHERE MyCounter = 3)
SET	@CompEndDate = (SELECT TOP 1 CompEndDate FROM UV_ReportAutomation WHERE MyCounter = 3)
SET	@ParentEntity = N'1'
SET	@REName = NULL
SET	@ReportType = N'1'
SET	@Data = 0

EXECUTE DataWarehouse..usp_Fid_Out_TableLoad

		@StartDate 
		,@EndDate  
		,@CompStartDate  
		,@CompEndDate  
		,@ParentEntity 
		,@REName 
		,@ReportType 
		,@Data 


		/*
		@StartDate DATE --= '7/1/2012',
		,@EndDate DATE --= '6/30/2013',
		,@CompStartDate DATE --= '7/1/2011',
		,@CompEndDate DATE --= '6/30/2012',
		,@ParentEntity VARCHAR(4000) --= N'1',
		,@REName VARCHAR(50) --= NULL,
		,@ReportType VARCHAR(50) --= N'1',
		,@Data INT --= 0
		*/

GO
