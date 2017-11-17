USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Trib_Outcome_3]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Fid_Trib_Outcome_3]
(	@StartDate		Date 
	,@EndDate		Date 
	,@CompStartDate	Date 
	,@CompEndDate	Date 
	,@ParentEntity Varchar(4000)
	,@REName	VARCHAR(50) 
	,@ReportType	VARCHAR(50) 
	,@Tribal_PM		VARCHAR(10) 
	,@Data INT
	,@GestAge	DECIMAL(18,8)
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
--	,@GestAge FLOAT
--	,@Data INT
--SET @StartDate		 = CAST('4/1/2012' AS DATE)
--SET @EndDate		 = DATEADD(D,-1,DATEADD(YEAR,1,@StartDate))
--SET @CompStartDate	 = CAST('4/1/2011' AS DATE)
--SET @CompEndDate	 = DATEADD(D,-1,DATEADD(YEAR,1,@CompStartDate))
--SET @ParentEntity	 = 18
--SET @REName			 = NULL
--SET @ReportType		 = 2
--SET @GestAge		 = 38.999999
--SET @Data			 = 1;

DECLARE 
	@rStartDate		Date 
	,@rEndDate		Date 
	,@rCompStartDate	Date 
	,@rCompEndDate	Date 
	,@rParentEntity Varchar(4000)
	,@rREName VARCHAR(50) 
	,@rReportType VARCHAR(50) 
	,@rTribal_PM VARCHAR(10) 
	,@rData INT
	,@rGestAge DECIMAL(18,8)
SET @rStartDate		 = @StartDate
SET @rEndDate		 = @EndDate
SET @rCompStartDate	 = @CompStartDate
SET @rCompEndDate	 = @CompEndDate
SET @rParentEntity	 = @ParentEntity
SET @rREName		 = @REName
SET @rReportType	 = @ReportType
SET @rTribal_PM		 = @Tribal_PM
SET @rData			 = @Data
SET @rGestAge		 = @GestAge;


IF @rData = 0
BEGIN


SELECT 
	dbo.udf_StateVSTribal(P.Abbreviation,P.Site_ID) [State]
	,P.[US State]
	,P.StateID
	,P.[Site_ID]
	,P.AGENCY_INFO_0_NAME
	,P.ProgramID
	,dbo.udf_fn_GetCleanProg(P.ProgramID) ProgramName
	,CASE WHEN P.Site_ID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
		WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName END ReportingEntity
	
	----------------- AGE  ---------------------
	,COUNT(DISTINCT
				CASE 
					WHEN --P.ClientDelvAge BETWEEN 10 AND 44.999999
						--AND	
						P.GestAge BETWEEN 17 AND @GestAge
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureTotalCount
	,COUNT(DISTINCT
				CASE 
					WHEN (P.ClientDelvAge < 10 OR P.ClientDelvAge > 45 OR P.ClientDelvAge IS NULL)
						AND P.GestAge BETWEEN 17 AND @GestAge
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureTotalCount_noMomAge
	,COUNT(DISTINCT
				CASE 
					WHEN --P.ClientDelvAge BETWEEN 10 AND 44.999999
						--AND 
						P.GestAge BETWEEN 17 AND 43.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) TotalCount_wGest
	,COUNT(DISTINCT
				CASE 
					WHEN --P.ClientDelvAge BETWEEN 10 AND 44.999999
						--AND P.GestAge BETWEEN 17 AND 43.999999
						--AND 
						P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) TotalCount
	,COUNT(DISTINCT
				CASE 
					WHEN (P.ClientDelvAge < 10 OR P.ClientDelvAge > 45 OR P.ClientDelvAge IS NULL)
						AND P.GestAge BETWEEN 17 AND 43.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) TotalCount_noMomAge
	,COUNT(DISTINCT
				CASE 
					WHEN P.ClientDelvAge BETWEEN 10 AND  14.999999
						AND P.GestAge BETWEEN 17 AND @GestAge
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureA1014Count
	,COUNT(DISTINCT
				CASE 
					WHEN P.ClientDelvAge BETWEEN 10 AND  14.999999
						AND P.GestAge BETWEEN 17 AND 43.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) A1014Count
	,COUNT(DISTINCT
				CASE 
					WHEN P.ClientDelvAge BETWEEN 15 AND 17.999999
						AND P.GestAge BETWEEN 17 AND @GestAge
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureA1517Count
	,COUNT(DISTINCT
				CASE 
					WHEN P.ClientDelvAge BETWEEN 15 AND 17.999999
						AND P.GestAge BETWEEN 17 AND 43.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) A1517Count
	,COUNT(DISTINCT
				CASE 
					WHEN P.ClientDelvAge BETWEEN 18 AND 19.999999
						AND P.GestAge BETWEEN 17 AND @GestAge
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureA1819Count
	,COUNT(DISTINCT
				CASE 
					WHEN P.ClientDelvAge BETWEEN 18 AND 19.999999
						AND P.GestAge BETWEEN 17 AND 43.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) A1819Count
	,COUNT(DISTINCT
				CASE 
					WHEN P.ClientDelvAge BETWEEN 20 AND 24.999999
						AND P.GestAge BETWEEN 17 AND @GestAge
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureA2024Count
	,COUNT(DISTINCT
				CASE 
					WHEN P.ClientDelvAge BETWEEN 20 AND 24.999999
						AND P.GestAge BETWEEN 17 AND 43.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) A2024Count
	,COUNT(DISTINCT
				CASE 
					WHEN P.ClientDelvAge BETWEEN 25 AND 29.999999
						AND P.GestAge BETWEEN 17 AND @GestAge
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureA2529Count
	,COUNT(DISTINCT
				CASE 
					WHEN P.ClientDelvAge BETWEEN 25 AND 29.999999
						AND P.GestAge BETWEEN 17 AND 43.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) A2529Count
	,COUNT(DISTINCT
				CASE 
					WHEN P.ClientDelvAge BETWEEN 30 AND 44.999999
						AND P.GestAge BETWEEN 17 AND @GestAge
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureA3044Count
	,COUNT(DISTINCT
				CASE 
					WHEN P.ClientDelvAge BETWEEN 30 AND 44.999999
						AND P.GestAge BETWEEN 17 AND 43.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) A3044Count
					
		----------------- AGE Compare ---------------------
	,COUNT(DISTINCT
				CASE 
					WHEN --P.ClientDelvAge BETWEEN 10 AND 44.999999
						--AND
							P.GestAge BETWEEN 17 AND @GestAge
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureTotalCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN (P.ClientDelvAge < 10 OR P.ClientDelvAge > 45 OR P.ClientDelvAge IS NULL)
						AND P.GestAge BETWEEN 17 AND @GestAge
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureTotalCount_noMomAge_comp
	,COUNT(DISTINCT
				CASE 
					WHEN --P.ClientDelvAge BETWEEN 10 AND 44.999999
						--AND 
						P.GestAge BETWEEN 17 AND 43.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) TotalCount_wGest_comp
	,COUNT(DISTINCT
				CASE 
					WHEN --P.ClientDelvAge BETWEEN 10 AND 44.999999
						--AND P.GestAge BETWEEN 17 AND 43.999999
						--AND 
						P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) TotalCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN (P.ClientDelvAge < 10 OR P.ClientDelvAge > 45 OR P.ClientDelvAge IS NULL)
						AND P.GestAge BETWEEN 17 AND 43.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) TotalCount_noMomAge_comp
	
	
	,COUNT(DISTINCT
				CASE 
					WHEN P.ClientDelvAge BETWEEN 10 AND  14.999999
						AND P.GestAge BETWEEN 17 AND @GestAge
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureA1014Count_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.ClientDelvAge BETWEEN 10 AND  14.999999
						AND P.GestAge BETWEEN 17 AND 43.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) A1014Count_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.ClientDelvAge BETWEEN 15 AND 17.999999
						AND P.GestAge BETWEEN 17 AND @GestAge
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureA1517Count_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.ClientDelvAge BETWEEN 15 AND 17.999999
						AND P.GestAge BETWEEN 17 AND 43.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) A1517Count_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.ClientDelvAge BETWEEN 18 AND 19.999999
						AND P.GestAge BETWEEN 17 AND @GestAge
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureA1819Count_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.ClientDelvAge BETWEEN 18 AND 19.999999
						AND P.GestAge BETWEEN 17 AND 43.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) A1819Count_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.ClientDelvAge BETWEEN 20 AND 24.999999
						AND P.GestAge BETWEEN 17 AND @GestAge
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureA2024Count_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.ClientDelvAge BETWEEN 20 AND 24.999999
						AND P.GestAge BETWEEN 17 AND 43.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) A2024Count_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.ClientDelvAge BETWEEN 25 AND 29.999999
						AND P.GestAge BETWEEN 17 AND @GestAge
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureA2529Count_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.ClientDelvAge BETWEEN 25 AND 29.999999
						AND P.GestAge BETWEEN 17 AND 43.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) A2529Count_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.ClientDelvAge BETWEEN 30 AND 44.999999
						AND P.GestAge BETWEEN 17 AND @GestAge
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureA3044Count_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.ClientDelvAge BETWEEN 30 AND 44.999999
						AND P.GestAge BETWEEN 17 AND 43.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) A3044Count_comp

	,NULL CLID
	
FROM DataWarehouse..UV_Fidelity_CLID P
WHERE CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN P.StateID
		WHEN @rReportType = 3 THEN P.Site_ID
		WHEN @rReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))

	  AND P.Tribal = 1
	  AND P.Tribal_PM IN( SELECT * FROM dbo.udf_ParseMultiParam(@rTribal_PM))
	
	--AND P.GestAge BETWEEN 17 AND 43.999999
	--AND P.GestAge IS NOT NULL
	  	
GROUP BY 
	P.Site_ID
	,dbo.udf_StateVSTribal(P.Abbreviation,P.Site_ID) 
	,P.[US State]
	,P.StateID
	,P.AGENCY_INFO_0_NAME
	,P.ProgramID
--ORDER BY 1

UNION

SELECT 
	dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
	,P.[US State]
	,P.StateID
	,P.SiteID [Site_ID]
	,P.AGENCY_INFO_0_NAME
	,P.ProgramID
	,dbo.udf_fn_GetCleanProg(P.ProgramID) ProgramName
	,CASE WHEN P.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
		WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName END ReportingEntity
    ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL 
FROM DataWarehouse..UV_PAS P
WHERE CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN P.StateID
		WHEN @rReportType = 3 THEN P.SiteID
		WHEN @rReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))
	  
	
END

ELSE ------------------------- DATA Return ----------------------
BEGIN

SELECT  1

END

GO
