USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Element_12]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Fid_Element_12]
(	@StartDate		Date 
	,@EndDate		Date 
	,@CompStartDate	Date 
	,@CompEndDate	Date 
	,@ParentEntity Varchar(4000)
	,@REName	VARCHAR(50) 
	,@ReportType	VARCHAR(50) 
	,@Data INT
)

AS
--DECLARE 
--	@StartDate		Date 
--	,@EndDate		Date 
--	,@CompStartDate	Date 
--	,@CompEndDate	Date 
--	,@ParentEntity Varchar(4000)
--	,@REName VARCHAR(50) 
--	,@ReportType INT
--	,@Data INT
--SET @StartDate		 = CAST('4/1/2012' AS DATE)
--SET @EndDate		 = DATEADD(D,-1,DATEADD(YEAR,1,@StartDate))
--SET @CompStartDate	 = CAST('4/1/2011' AS DATE)
--SET @CompEndDate	 = DATEADD(D,-1,DATEADD(YEAR,1,@CompStartDate))
--SET @ParentEntity	 = 18
--SET @REName			 = NULL
--SET @ReportType		 = 2
--SET @Data			 = 1;

DECLARE 
	@rStartDate		Date 
	,@rEndDate		Date 
	,@rCompStartDate	Date 
	,@rCompEndDate	Date 
	,@rParentEntity Varchar(4000)
	,@rREName VARCHAR(50) 
	,@rReportType VARCHAR(50) 
	,@rData INT
SET @rStartDate		 = @StartDate
SET @rEndDate		 = @EndDate
SET @rCompStartDate	 = @CompStartDate
SET @rCompEndDate	 = @CompEndDate
SET @rParentEntity	 = @ParentEntity
SET @rREName		 = @REName
SET @rReportType	 = @ReportType
SET @rData			 = @Data;
DECLARE @Cycles int
SET @Cycles = (DATEDIFF(MONTH,@rStartDate,@rEndDate)+1);

with MyCte AS
    (select   MyCounter = 0
     UNION ALL
     SELECT   MyCounter - 1
     FROM     MyCte
     where    ABS(MyCounter) < @Cycles-1)
     
select 
	MyCounter
	,DATEADD(M, MyCounter, @rStartDate) StartDate
	,DATEADD(M, MyCounter, @rCompStartDate) CompStartDate
	,DATEADD(M, MyCounter, @rEndDate) EndDate
	,DATEADD(M, MyCounter, @rCompEndDate) CompEndDate
	,@rParentEntity ParentEntity
	,@rREName REName
	,@ReportType ReportType
	,0 Data
	,S.*
	,CAST(CountNHV_curr AS VARCHAR(50)) + CAST(MyCounter AS VARCHAR(50)) EntityCountCurr
	,CAST(CountNHV_comp AS VARCHAR(50)) + CAST(MyCounter AS VARCHAR(50)) EntityCountComp
	,ISNULL(CASE WHEN CountNHV_curr IS NOT NULL THEN SUM(1) OVER(Partition By MyCounter,CASE WHEN CountNHV_curr IS NOT NULL THEN 1 ELSE 0 END) END,0) Count_dupCurr
	,ISNULL(CASE WHEN CountNHV_comp IS NOT NULL THEN SUM(1) OVER(Partition By MyCounter,CASE WHEN CountNHV_comp IS NOT NULL THEN 1 ELSE 0 END) END,0) Count_dupComp
	--,ISNULL(CASE WHEN CountNHV2_curr IS NOT NULL THEN SUM(1) OVER(Partition By MyCounter,CASE WHEN CountNHV2_curr IS NOT NULL THEN 1 ELSE 0 END) END,0) Count_dupCurr
	--,ISNULL(CASE WHEN CountNHV2_comp IS NOT NULL THEN SUM(1) OVER(Partition By MyCounter,CASE WHEN CountNHV2_comp IS NOT NULL THEN 1 ELSE 0 END) END,0) Count_dupComp

from   MyCte M

OUTER APPLY  dbo.fn_Fidelity_Staff_El12(DATEADD(M, MyCounter, @rStartDate) 
											,DATEADD(M, MyCounter, @rEndDate) 
											,DATEADD(M, MyCounter, @rCompStartDate) 
											,DATEADD(M, MyCounter, @rCompEndDate) 
											,@rParentEntity 
											,@rREName 
											,@ReportType 
											,1) S
WHERE ISNULL(S.StateID,'') <> ''
GO
