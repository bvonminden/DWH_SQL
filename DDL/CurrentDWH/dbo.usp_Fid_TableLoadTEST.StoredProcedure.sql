USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_TableLoadTEST]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Fid_TableLoadTEST]

--DECLARE
		@StartDate DATE --= '7/1/2012',
		,@EndDate DATE --= '6/30/2013',
		,@CompStartDate DATE --= '7/1/2011',
		,@CompEndDate DATE --= '6/30/2012',
		,@ParentEntity VARCHAR(4000) --= N'1',
		,@REName VARCHAR(50) --= NULL,
		,@ReportType VARCHAR(50) --= N'1',
		,@Data INT --= 0

AS 

INSERT INTO [TW_StaffDB].[dbo].[Check]
VALUES(1)

GO
