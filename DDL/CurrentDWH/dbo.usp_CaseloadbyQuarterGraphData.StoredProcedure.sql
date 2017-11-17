USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_CaseloadbyQuarterGraphData]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_CaseloadbyQuarterGraphData]
	--@EndDate date
AS BEGIN

--DECLARE @EndDate DATE
--SET @EndDate = GETDATE()

SET NOCOUNT ON;
WITH MyCte AS
(
SELECT MyCounter = DATEADD(qq, DATEDIFF(qq,0,DATEADD(day,1,GETDATE())), -1)
--SELECT MyCounter = DATEADD(qq, DATEDIFF(qq,0,DATEADD(day,1,@EndDate)), -1)
--UNION ALL
--SELECT   DATEADD(MONTH,-3,MyCounter)
--FROM     MyCte
--where   DATEADD(MONTH,-3,MyCounter) BETWEEN '12/31/2012' AND '12/31/2012'-- GETDATE()
)
,Dataset as
(
SELECT 

	MyCounter
	,CAST(DATEPART(YEAR,MyCounter) AS CHAR) + CAST(DATEPART(Q,MyCounter) AS CHAR) YearQuarter
	,Programs.*
	,R.*
FROM MyCte
CROSS JOIN (
			SELECT DISTINCT 4 ReportType, P.ProgramID ParentEntity
			FROM UV_PAS P

			UNION ALL

			SELECT DISTINCT 3 ReportType, P.SiteID ParentEntity
			FROM UV_PAS P

			UNION ALL

			SELECT DISTINCT 2 ReportType, P.StateID ParentEntity
			FROM UV_PAS P
			) Programs
	OUTER APPLY dbo.udf_CaseLoadSnapshot(MyCounter,ParentEntity,ReportType) R
)
INSERT INTO UC_CaseloadbyQuarter 
SELECT * 
FROM Dataset D
END
GO
