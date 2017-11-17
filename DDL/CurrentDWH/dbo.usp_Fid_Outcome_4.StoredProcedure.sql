USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Outcome_4]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Fid_Outcome_4]
(	@StartDate		Date 
	,@EndDate		Date 
	,@CompStartDate	Date 
	,@CompEndDate	Date 
	,@ParentEntity Varchar(4000)
	,@REName	VARCHAR(50) 
	,@ReportType	VARCHAR(50) 
	,@Data INT
	--,@GestAge	INT
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
--	,@GestAge INT
--	,@Data INT
--SET @StartDate		 = CAST('4/1/2012' AS DATE)
--SET @EndDate		 = DATEADD(D,-1,DATEADD(YEAR,1,@StartDate))
--SET @CompStartDate	 = CAST('4/1/2011' AS DATE)
--SET @CompEndDate	 = DATEADD(D,-1,DATEADD(YEAR,1,@CompStartDate))
--SET @ParentEntity	 = 18
--SET @REName			 = NULL
--SET @ReportType		 = 2
--SET @GestAge			= 38
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
	--,@rGestAge INT
SET @rStartDate		 = @StartDate
SET @rEndDate		 = @EndDate
SET @rCompStartDate	 = @CompStartDate
SET @rCompEndDate	 = @CompEndDate
SET @rParentEntity	 = @ParentEntity
SET @rREName		 = @REName
SET @rReportType	 = @ReportType
SET @rData			 = @Data
--SET @rGestAge		 = @GestAge;


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
	
	----------------- Ethnicity  ---------------------
	,COUNT(DISTINCT
				CASE 
					WHEN  P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) Eth_BirthTotal
	,COUNT(DISTINCT
				CASE 
					WHEN P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) Eth_wWeight_BirthTotal
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 1
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightHispanicCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 1
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) HispanicCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 2
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightNonLatinaCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 2
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) NonLatinaCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 3
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightDeclinedCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 3
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) DeclinedCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 4
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightMissingCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 4
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) MissingCount
	---------------- Race -------------------
	,COUNT(DISTINCT
				CASE 
					WHEN P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) Race_BirthTotal
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 8
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightRaceMissingCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 8
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) RaceMissingCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 6
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightRaceDeclinedCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 6
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) RaceDeclinedCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 1
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightAmericanCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 1
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) AmericanCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 2
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightAsianCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 2
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) AsianCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 9
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightBothCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 9
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) BothCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 4
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightPacificCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 4
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PacificCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 3
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightAfricanCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 3
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) AfricanCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 5
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightWhiteCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 5
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) WhiteCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 7
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightManyRaceCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 7
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) ManyRaceCount
					
	,COUNT(DISTINCT
				CASE 
					WHEN P.Grams BETWEEN 430 AND 1499
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) Eth_TotalVeryLowCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) Eth_TotalLowCount
	
	
	------------------ Comparative ----------------
	
----------------- Ethnicity  ---------------------
	,COUNT(DISTINCT
				CASE 
					WHEN P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) Eth_BirthTotal_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) Eth_wWeight_BirthTotal_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 1
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightHispanicCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 1
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) HispanicCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 2
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightNonLatinaCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 2
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) NonLatinaCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 3
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightDeclinedCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 3
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) DeclinedCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 4
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightMissingCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 4
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) MissingCount_comp
	---------------- Race -------------------
	,COUNT(DISTINCT
				CASE 
					WHEN P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) Race_BirthTotal_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 8
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightRaceMissingCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 8
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) RaceMissingCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 6
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightRaceDeclinedCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 6
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) RaceDeclinedCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 1
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightAmericanCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 1
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) AmericanCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 2
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightAsianCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 2
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) AsianCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 9
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightBothCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 9
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) BothCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 4
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightPacificCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 4
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PacificCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 3
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightAfricanCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 3
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) AfricanCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 5
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightWhiteCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 5
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) WhiteCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 7
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightManyRaceCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 7
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) ManyRaceCount_comp
					
	,COUNT(DISTINCT
				CASE 
					WHEN P.Grams BETWEEN 430 AND 1499.99999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) Eth_TotalVeryLowCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) Eth_TotalLowCount_comp
	,NULL CLID
FROM UV_Fidelity_CLID P
WHERE CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN P.StateID
		WHEN @rReportType = 3 THEN P.Site_ID
		WHEN @rReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))
	
	--AND P.Grams BETWEEN 430 AND 7999.999999
	  	
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
    ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL CLID
FROM UV_PAS P
WHERE CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN P.StateID
		WHEN @rReportType = 3 THEN P.SiteID
		WHEN @rReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))
	  
	
END

ELSE ------------------------- DATA Return ----------------------
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
	
	
	----------------- Ethnicity  ---------------------
	,COUNT(DISTINCT
				CASE 
					WHEN  P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) Eth_BirthTotal
	,COUNT(DISTINCT
				CASE 
					WHEN P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) Eth_wWeight_BirthTotal
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 1
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightHispanicCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 1
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) HispanicCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 2
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightNonLatinaCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 2
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) NonLatinaCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 3
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightDeclinedCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 3
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) DeclinedCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 4
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightMissingCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 4
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) MissingCount
	---------------- Race -------------------
	,COUNT(DISTINCT
				CASE 
					WHEN P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) Race_BirthTotal
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 8
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightRaceMissingCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 8
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) RaceMissingCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 6
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightRaceDeclinedCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 6
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) RaceDeclinedCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 1
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightAmericanCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 1
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) AmericanCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 2
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightAsianCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 2
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) AsianCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 9
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightBothCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 9
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) BothCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 4
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightPacificCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 4
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PacificCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 3
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightAfricanCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 3
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) AfricanCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 5
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightWhiteCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 5
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) WhiteCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 7
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) LowWeightManyRaceCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 7
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) ManyRaceCount
					
	,COUNT(DISTINCT
				CASE 
					WHEN P.Grams BETWEEN 430 AND 1499
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) Eth_TotalVeryLowCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) Eth_TotalLowCount
	
	
	------------------ Comparative ----------------
	
----------------- Ethnicity  ---------------------
	,COUNT(DISTINCT
				CASE 
					WHEN P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) Eth_BirthTotal_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) Eth_wWeight_BirthTotal_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 1
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightHispanicCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 1
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) HispanicCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 2
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightNonLatinaCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 2
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) NonLatinaCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 3
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightDeclinedCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 3
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) DeclinedCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 4
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightMissingCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 4
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) MissingCount_comp
	---------------- Race -------------------
	,COUNT(DISTINCT
				CASE 
					WHEN P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) Race_BirthTotal_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 8
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightRaceMissingCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 8
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) RaceMissingCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 6
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightRaceDeclinedCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 6
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) RaceDeclinedCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 1
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightAmericanCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 1
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) AmericanCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 2
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightAsianCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 2
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) AsianCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 9
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightBothCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 9
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) BothCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 4
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightPacificCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 4
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PacificCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 3
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightAfricanCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 3
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) AfricanCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 5
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightWhiteCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 5
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) WhiteCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 7
						AND P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) LowWeightManyRaceCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 7
						AND P.Grams BETWEEN 430 AND 7999.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) ManyRaceCount_comp
					
	,COUNT(DISTINCT
				CASE 
					WHEN P.Grams BETWEEN 430 AND 1499.99999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) Eth_TotalVeryLowCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Grams BETWEEN 430 AND 2499.999999
						AND P.O2DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) Eth_TotalLowCount_comp
	,P.CLID
	
FROM UV_Fidelity_CLID P
WHERE CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN P.StateID
		WHEN @rReportType = 3 THEN P.Site_ID
		WHEN @rReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))
	
	--AND P.Grams BETWEEN 430 AND 7999.999999
	  	
GROUP BY 
	P.Site_ID
	,dbo.udf_StateVSTribal(P.Abbreviation,P.Site_ID) 
	,P.[US State]
	,P.StateID
	,P.AGENCY_INFO_0_NAME
	,P.ProgramID
	,P.CLID
--ORDER BY 1

END
GO
