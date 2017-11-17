USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Outcome_2]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Fid_Outcome_2]
(	@StartDate		Date 
	,@EndDate		Date 
	,@CompStartDate	Date 
	,@CompEndDate	Date 
	,@ParentEntity Varchar(4000)
	,@REName	VARCHAR(50) 
	,@ReportType	VARCHAR(50) 
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
--	,@GestAge INT
--SET @StartDate		 = CAST('4/1/2012' AS DATE)
--SET @EndDate		 = DATEADD(D,-1,DATEADD(YEAR,1,@StartDate))
--SET @CompStartDate	 = CAST('4/1/2011' AS DATE)
--SET @CompEndDate	 = DATEADD(D,-1,DATEADD(YEAR,1,@CompStartDate))
--SET @ParentEntity	 = 18
--SET @REName			 = NULL
--SET @ReportType		 = 2
--SET @GestAge			= 38;

DECLARE 
	@rStartDate		Date 
	,@rEndDate		Date 
	,@rCompStartDate	Date 
	,@rCompEndDate	Date 
	,@rParentEntity Varchar(4000)
	,@rREName VARCHAR(50) 
	,@rReportType VARCHAR(50) 
	,@rData INT
	,@rGestAge DECIMAL(18,8)
SET @rStartDate		 = @StartDate
SET @rEndDate		 = @EndDate
SET @rCompStartDate	 = @CompStartDate
SET @rCompEndDate	 = @CompEndDate
SET @rParentEntity	 = @ParentEntity
SET @rREName		 = @REName
SET @rReportType	 = @ReportType
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
	
	----------------- Ethnicity compare ---------------------
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 1
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureHispanicCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 1
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) HispanicCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) Eth_BirthTotal_wGest
	,COUNT(DISTINCT
				CASE 
					WHEN P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) Eth_BirthTotal
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 2
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureNonLatinaCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 2
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) NonLatinaCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 3
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureDeclinedCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 3
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) DeclinedCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 4
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureMissingCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 4
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) MissingCount
					
	----------------- Race compare ---------------------
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 8
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureRaceMissingCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 8
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) RaceMissingCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) Race_BirthTotal_wGest
	,COUNT(DISTINCT
				CASE 
					WHEN P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) Race_BirthTotal
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) Race_TotalPremature
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 6
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureRaceDeclinedCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 6
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) RaceDeclinedCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 1
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureAmericanCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 1
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) AmericanCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 2
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureAsianCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 2
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) AsianCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 9
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureBothCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 9
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) BothCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 4
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematurePacificCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 4
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PacificCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 3
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureAfricanCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 3
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) AfricanCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 5
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureWhiteCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 5
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) WhiteCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 7
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureManyRaceCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 7
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) ManyRaceCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) Eth_TotalPemature
	
	
	---------------- Comparative -------------------

	----------------- Ethnicity compare ---------------------
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 1
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureHispanicCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 1
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) HispanicCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) Eth_BirthTotal_wGest_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) Eth_BirthTotal_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 2
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureNonLatinaCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 2
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) NonLatinaCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 3
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureDeclinedCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 3
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) DeclinedCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 4
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureMissingCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 4
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) MissingCount_comp
					
	----------------- Race compare ---------------------
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 8
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureRaceMissingCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 8
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) RaceMissingCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) Race_BirthTotal_wGest_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) Race_BirthTotal_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) Race_TotalPremature_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 6
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureRaceDeclinedCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 6
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) RaceDeclinedCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 1
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureAmericanCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 1
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) AmericanCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 2
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureAsianCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 2
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) AsianCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 9
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureBothCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 9
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) BothCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 4
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematurePacificCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 4
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PacificCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 3
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureAfricanCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 3
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) AfricanCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 5
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureWhiteCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 5
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) WhiteCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 7
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureManyRaceCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 7
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) ManyRaceCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) Eth_TotalPemature_comp
	,NULL CLID
FROM UV_Fidelity_CLID P
WHERE CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN P.StateID
		WHEN @rReportType = 3 THEN P.Site_ID
		WHEN @rReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))
	  
	--AND P.GestAge BETWEEN 18 AND 43.999999
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
      ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL
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
	

	----------------- Ethnicity compare ---------------------
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 1
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureHispanicCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 1
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) HispanicCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) Eth_BirthTotal_wGest
	,COUNT(DISTINCT
				CASE 
					WHEN P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) Eth_BirthTotal
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 2
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureNonLatinaCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 2
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) NonLatinaCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 3
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureDeclinedCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 3
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) DeclinedCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 4
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureMissingCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 4
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) MissingCount
					
	----------------- Race compare ---------------------
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 8
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureRaceMissingCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 8
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) RaceMissingCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) Race_BirthTotal_wGest
	,COUNT(DISTINCT
				CASE 
					WHEN P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) Race_BirthTotal
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) Race_TotalPremature
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 6
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureRaceDeclinedCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 6
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) RaceDeclinedCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 1
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureAmericanCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 1
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) AmericanCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 2
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureAsianCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 2
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) AsianCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 9
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureBothCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 9
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) BothCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 4
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematurePacificCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 4
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PacificCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 3
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureAfricanCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 3
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) AfricanCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 5
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureWhiteCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 5
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) WhiteCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 7
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) PrematureManyRaceCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 7
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) ManyRaceCount
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END) Eth_TotalPemature
	
	
	---------------- Comparative -------------------

	----------------- Ethnicity compare ---------------------
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 1
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureHispanicCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 1
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) HispanicCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) Eth_BirthTotal_wGest_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) Eth_BirthTotal_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 2
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureNonLatinaCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 2
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) NonLatinaCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 3
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureDeclinedCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 3
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) DeclinedCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 4
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureMissingCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Ethnicity = 4
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) MissingCount_comp
					
	----------------- Race compare ---------------------
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 8
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureRaceMissingCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 8
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) RaceMissingCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) Race_BirthTotal_wGest_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) Race_BirthTotal_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) Race_TotalPremature_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 6
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureRaceDeclinedCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 6
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) RaceDeclinedCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 1
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureAmericanCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 1
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) AmericanCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 2
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureAsianCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 2
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) AsianCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 9
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureBothCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 9
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) BothCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 4
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematurePacificCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 4
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PacificCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 3
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureAfricanCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 3
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) AfricanCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 5
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureWhiteCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 5
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) WhiteCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 7
						AND P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) PrematureManyRaceCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.Race = 7
						AND P.GestAge BETWEEN 18 AND 43.999999
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) ManyRaceCount_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAge BETWEEN 18 AND @GestAge
						AND P.DOB BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END) Eth_TotalPemature_comp
	,P.CLID			
	
FROM UV_Fidelity_CLID P
WHERE CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN P.StateID
		WHEN @rReportType = 3 THEN P.Site_ID
		WHEN @rReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))
	  
	--AND P.GestAge BETWEEN 18 AND 43.999999
	--AND P.GestAge IS NOT NULL
		  	
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
