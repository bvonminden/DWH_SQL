USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Trib_Outcome_8]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Fid_Trib_Outcome_8]
(	@StartDate		Date 
	,@EndDate		Date 
	,@CompStartDate	Date 
	,@CompEndDate	Date 
	,@ParentEntity Varchar(4000)
	,@REName	VARCHAR(50) 
	,@ReportType	VARCHAR(50) 
	,@Tribal_PM	VARCHAR(10) 
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
	,@rTribal_PM VARCHAR(10) 
	,@rData INT
	--,@rGestAge INT
SET @rStartDate		 = @StartDate
SET @rEndDate		 = @EndDate
SET @rCompStartDate	 = @CompStartDate
SET @rCompEndDate	 = @CompEndDate
SET @rParentEntity	 = @ParentEntity
SET @rREName		 = @REName
SET @rReportType	 = @ReportType
SET @rTribal_PM		 = @Tribal_PM	
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

---------- Current period ---------	
	,COUNT(DISTINCT	
				CASE
					WHEN P.WorkIn_Yes BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID
				END) WorkIn_Yes
	,COUNT(DISTINCT	
				CASE
					WHEN P.WorkIn_Data BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID
				END) WorkIn_Data
	,COUNT(DISTINCT	
				CASE
					WHEN P.WorkIn_Missing BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID
				END) WorkIn_Missing
				
	,COUNT(DISTINCT	
				CASE
					WHEN P.Work6_Yes BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID
				END) Work6_Yes
	,COUNT(DISTINCT	
				CASE
					WHEN P.Work6_Data BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID
				END) Work6_Data
	,COUNT(DISTINCT	
				CASE
					WHEN P.Work6_Missing BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID
				END) Work6_Missing
				
	,COUNT(DISTINCT	
				CASE
					WHEN P.Work12_Yes BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID
				END) Work12_Yes
	,COUNT(DISTINCT	
				CASE
					WHEN P.Work12_Data BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID
				END) Work12_Data
	,COUNT(DISTINCT	
				CASE
					WHEN P.Work12_Missing BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID
				END) Work12_Missing
				
	,COUNT(DISTINCT	
				CASE
					WHEN P.Work18_Yes BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID
				END) Work18_Yes
	,COUNT(DISTINCT	
				CASE
					WHEN P.Work18_Data BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID
				END) Work18_Data
	,COUNT(DISTINCT	
				CASE
					WHEN P.Work18_Missing BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID
				END) Work18_Missing
				
	,COUNT(DISTINCT	
				CASE
					WHEN P.Work24_Yes BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID
				END) Work24_Yes
	,COUNT(DISTINCT	
				CASE
					WHEN P.Work24_Data BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID
				END) Work24_Data
	,COUNT(DISTINCT	
				CASE
					WHEN P.Work24_Missing BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID
				END) Work24_Missing

---------- Compare period ---------
	,COUNT(DISTINCT	
				CASE
					WHEN P.WorkIn_Yes BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID
				END) WorkIn_Yes_comp
	,COUNT(DISTINCT	
				CASE
					WHEN P.WorkIn_Data BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID
				END) WorkIn_Data_comp
	,COUNT(DISTINCT	
				CASE
					WHEN P.WorkIn_Missing BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID
				END) WorkIn_Missing_comp
	,COUNT(DISTINCT	
				CASE
					WHEN P.Work6_Yes BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID
				END) Work6_Yes_comp
	,COUNT(DISTINCT	
				CASE
					WHEN P.Work6_Data BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID
				END) Work6_Data_comp
	,COUNT(DISTINCT	
				CASE
					WHEN P.Work6_Missing BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID
				END) Work6_Missing_comp
				
	,COUNT(DISTINCT	
				CASE
					WHEN P.Work12_Yes BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID
				END) Work12_Yes_comp
	,COUNT(DISTINCT	
				CASE
					WHEN P.Work12_Data BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID
				END) Work12_Data_comp
	,COUNT(DISTINCT	
				CASE
					WHEN P.Work12_Missing BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID
				END) Work12_Missing_comp
				
	,COUNT(DISTINCT	
				CASE
					WHEN P.Work18_Yes BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID
				END) Work18_Yes_comp
	,COUNT(DISTINCT	
				CASE
					WHEN P.Work18_Data BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID
				END) Work18_Data_comp
	,COUNT(DISTINCT	
				CASE
					WHEN P.Work18_Missing BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID
				END) Work18_Missing_comp
				
	,COUNT(DISTINCT	
				CASE
					WHEN P.Work24_Yes BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID
				END) Work24_Yes_comp
	,COUNT(DISTINCT	
				CASE
					WHEN P.Work24_Data BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID
				END) Work24_Data_comp
	,COUNT(DISTINCT	
				CASE
					WHEN P.Work24_Missing BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID
				END) Work24_Missing_comp
				
FROM DataWarehouse..UV_Fidelity_CLID P
WHERE CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN P.StateID
		WHEN @rReportType = 3 THEN P.Site_ID
		WHEN @rReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))
	
	AND P.ClientAgeIntake >= 18
	AND P.Tribal = 1
	  AND P.Tribal_PM IN( SELECT * FROM dbo.udf_ParseMultiParam(@rTribal_PM))
	  	
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
   ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
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




SELECT 1
	
END

GO
