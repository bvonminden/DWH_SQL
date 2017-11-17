USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Outcome_11b]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[usp_Fid_Outcome_11b]
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
--	,@ReportPeriod INT
--	,@Data INT
--SET @StartDate		 = CAST('10/1/2013' AS DATE)
--SET @EndDate		 = DATEADD(D,-1,DATEADD(YEAR,1,@StartDate))
--SET @CompStartDate	 = CAST('10/1/2012' AS DATE)
--SET @CompEndDate	 = DATEADD(D,-1,DATEADD(YEAR,1,@CompStartDate))
--SET @ParentEntity	 = 14
--SET @REName			 = NULL
--SET @ReportType		 = 2
--SET @ReportPeriod	= 6
--SET @Data			 = 0;

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
SET @rData			 = @Data


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
	,COUNT( DISTINCT
				CASE WHEN DATEADD(MONTH,5,P.DOB) BETWEEN @rStartDate AND @rEndDate AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,5,P.DOB))
					THEN P.CLID END) ChildWData_4
	,COUNT( DISTINCT
				CASE WHEN DATEADD(MONTH,5,P.DOB) BETWEEN @rStartDate AND @rEndDate AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,5,P.DOB))
						AND P.ChildWData_4 IS NOT NULL --AND P.ChildWData_4 <= @rEndDate
					THEN P.CLID END) ChildScreened_4
	,COUNT( DISTINCT
				CASE WHEN P.ChildReff_4 BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END)  ChildReff_4
	,COUNT( DISTINCT
				CASE WHEN P.ChildScreened_4 BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END)  ChildReff_4_denom
	,COUNT( DISTINCT 
				CASE WHEN DATEADD(MONTH,11,P.DOB) BETWEEN @rStartDate AND @rEndDate AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,11,P.DOB))
					THEN P.CLID END)  ChildWData_10
	,COUNT( DISTINCT
				CASE WHEN DATEADD(MONTH,11,P.DOB) BETWEEN @rStartDate AND @rEndDate AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,11,P.DOB))
						AND P.ChildWData_10 IS NOT NULL --AND P.ChildWData_10 <= @rEndDate
					THEN P.CLID END)  ChildScreened_10
	,COUNT( DISTINCT
				CASE WHEN P.ChildReff_10 BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END)  ChildReff_10
	,COUNT( DISTINCT
				CASE WHEN P.ChildScreened_10 BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END)  ChildReff_10_denom
	,COUNT( DISTINCT
				CASE WHEN DATEADD(MONTH,15,P.DOB) BETWEEN @rStartDate AND @rEndDate AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,15,P.DOB))
					THEN P.CLID END)  ChildWData_14
	,COUNT( DISTINCT
				CASE WHEN DATEADD(MONTH,15,P.DOB) BETWEEN @rStartDate AND @rEndDate AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,15,P.DOB))
						AND P.ChildWData_14 IS NOT NULL --AND P.ChildWData_14 <= @rEndDate
					THEN P.CLID END)  ChildScreened_14
	,COUNT( DISTINCT
				CASE WHEN P.ChildReff_14 BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END)  ChildReff_14
	,COUNT( DISTINCT
				CASE WHEN P.ChildScreened_14 BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END)  ChildReff_14_denom
	,COUNT( DISTINCT
				CASE WHEN DATEADD(MONTH,21,P.DOB) BETWEEN @rStartDate AND @rEndDate AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,21,P.DOB))
					THEN P.CLID END)  ChildWData_20
	,COUNT( DISTINCT
				CASE WHEN DATEADD(MONTH,21,P.DOB) BETWEEN @rStartDate AND @rEndDate AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,21,P.DOB))
						AND P.ChildWData_20 IS NOT NULL --AND P.ChildWData_20 <= @rEndDate
					THEN P.CLID END)  ChildScreened_20
	,COUNT( DISTINCT
				CASE WHEN P.ChildReff_20 BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END)  ChildReff_20
	,COUNT( DISTINCT
				CASE WHEN P.ChildScreened_20 BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END)  ChildReff_20_denom
	,COUNT( DISTINCT
				CASE WHEN (DATEADD(MONTH,19,P.DOB) >= @rStartDate 
						AND DATEADD(MONTH,19,P.DOB) <=  @rEndDate) 
						AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,19,P.DOB))
					THEN P.CLID END)  ChildWData_18
	,COUNT( DISTINCT
				CASE WHEN (DATEADD(MONTH,19,P.DOB) >= @rStartDate 
						AND DATEADD(MONTH,19,P.DOB) <=  @rEndDate)
						AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,19,P.DOB))
						AND P.ChildWData_18 IS NOT NULL --AND P.ChildWData_18 <= @rEndDate
					THEN P.CLID END)  ChildScreened_18
	,COUNT( DISTINCT
				CASE WHEN P.ChildReff_18 BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END)  ChildReff_18
	,COUNT( DISTINCT
				CASE WHEN (DATEADD(MONTH,19,P.DOB) >= @rStartDate 
						AND DATEADD(MONTH,19,P.DOB) <=  @rEndDate) 
						AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,19,P.DOB))
					THEN P.CLID END)  ChildReff_18_denom
	,COUNT( DISTINCT
				CASE WHEN (dateadd(month, 25, [DOB]) >= @rStartDate 
						and dateadd(month, 25, [DOB]) <= @rEndDate) 
						AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,23,P.DOB))
					THEN P.CLID END)  ChildWData_24
	,COUNT( DISTINCT
				CASE WHEN (dateadd(month, 25, [DOB]) >= @rStartDate 
						and dateadd(month, 25, [DOB]) <= @rEndDate) 
						AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,23,P.DOB))
						AND P.ChildWData_24 IS NOT NULL
					THEN P.CLID END)  ChildScreened_24 
	,COUNT( DISTINCT
				CASE WHEN P.ChildReff_24 BETWEEN @rStartDate AND @rEndDate
					THEN P.CLID END)  ChildReff_24
	,COUNT( DISTINCT
				CASE WHEN (dateadd(month, 25, [DOB]) >= @rStartDate 
						and dateadd(month, 25, [DOB]) <= @rEndDate) 
						AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,23,P.DOB))
						AND P.ChildScreened_24 IS NOT NULL
					THEN P.CLID END)  ChildReff_24_denom

---------- Compare period ---------
	
	,COUNT( DISTINCT
				CASE WHEN DATEADD(MONTH,5,P.DOB) BETWEEN @rCompStartDate AND @rCompEndDate AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,5,P.DOB))
					 THEN P.CLID END) ChildWData_4_comp
	,COUNT( DISTINCT
				CASE WHEN DATEADD(MONTH,5,P.DOB) BETWEEN @rCompStartDate AND @rCompEndDate AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,5,P.DOB))
						AND P.ChildWData_4 IS NOT NULL --AND P.ChildWData_4 <= @rCompEndDate
					THEN P.CLID END) ChildScreened_4_comp
	,COUNT( DISTINCT
				CASE WHEN P.ChildReff_4 BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END)  ChildReff_4_comp
	,COUNT( DISTINCT
				CASE WHEN P.ChildScreened_4 BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END)  ChildReff_4_denom_comp
	,COUNT( DISTINCT 
				CASE WHEN DATEADD(MONTH,11,P.DOB) BETWEEN @rCompStartDate AND @rCompEndDate AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,11,P.DOB))
					THEN P.CLID END)  ChildWData_10_comp
	,COUNT( DISTINCT
				CASE WHEN DATEADD(MONTH,11,P.DOB) BETWEEN @rCompStartDate AND @rCompEndDate AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,11,P.DOB))
						AND P.ChildWData_10 IS NOT NULL --AND P.ChildWData_10 <= @rCompEndDate
					THEN P.CLID END)  ChildScreened_10_comp
	,COUNT( DISTINCT
				CASE WHEN P.ChildReff_10 BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END)  ChildReff_10_comp
	,COUNT( DISTINCT
				CASE WHEN P.ChildScreened_10 BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END)  ChildReff_10_denom_comp
	,COUNT( DISTINCT
				CASE WHEN DATEADD(MONTH,15,P.DOB) BETWEEN @rCompStartDate AND @rCompEndDate AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,15,P.DOB))
					THEN P.CLID END)  ChildWData_14_comp
	,COUNT( DISTINCT
				CASE WHEN DATEADD(MONTH,15,P.DOB) BETWEEN @rCompStartDate AND @rCompEndDate AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,15,P.DOB))
						AND P.ChildWData_14 IS NOT NULL --AND P.ChildWData_14 <= @rCompEndDate
					THEN P.CLID END)  ChildScreened_14_comp
	,COUNT( DISTINCT
				CASE WHEN P.ChildReff_14 BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END)  ChildReff_14_comp
	,COUNT( DISTINCT
				CASE WHEN P.ChildScreened_14 BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END)  ChildReff_14_denom_comp
	,COUNT( DISTINCT
				CASE WHEN DATEADD(MONTH,21,P.DOB) BETWEEN @rCompStartDate AND @rCompEndDate AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,21,P.DOB))
					THEN P.CLID END)  ChildWData_20_comp
	,COUNT( DISTINCT
				CASE WHEN DATEADD(MONTH,21,P.DOB) BETWEEN @rCompStartDate AND @rCompEndDate AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,21,P.DOB))
						AND P.ChildWData_20 IS NOT NULL --AND P.ChildWData_20 <= @rCompEndDate
					THEN P.CLID END)  ChildScreened_20_comp
	,COUNT( DISTINCT
				CASE WHEN P.ChildReff_20 BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END)  ChildReff_20_comp
	,COUNT( DISTINCT
				CASE WHEN P.ChildScreened_20 BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END)  ChildReff_20_denom_comp
	,COUNT( DISTINCT
				CASE WHEN (dateadd(month, 19, [DOB]) >= @rCompStartDate 
						and dateadd(month, 19, [DOB]) <= @rCompEndDate) 
						AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,19,P.DOB))
					THEN P.CLID END)  ChildWData_18_comp
	,COUNT( DISTINCT
				CASE WHEN (DATEADD(MONTH,19,P.DOB) >= @rCompStartDate
						AND DATEADD(MONTH,19,P.DOB) <=  @rCompEndDate)
						AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,19,P.DOB))
						AND P.ChildWData_18 IS NOT NULL --AND P.ChildWData_18 <= @rEndDate
					THEN P.CLID END)  ChildScreened_18_comp
	,COUNT( DISTINCT
				CASE WHEN P.ChildReff_18 BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END)  ChildReff_18_comp
	,COUNT( DISTINCT
				CASE WHEN (dateadd(month, 19, [DOB]) >= @rCompStartDate 
						and dateadd(month, 19, [DOB]) <= @rCompEndDate) 
						AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,19,P.DOB))
						AND P.ChildScreened_18 IS NOT NULL
					THEN P.CLID END)  ChildReff_18_denom_comp
	,COUNT( DISTINCT
				CASE WHEN DATEADD(MONTH,25,P.DOB) BETWEEN @rCompStartDate AND @rCompEndDate 
						AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,23,P.DOB))
					THEN P.CLID END)  ChildWData_24_comp
	,COUNT( DISTINCT
				CASE WHEN DATEADD(MONTH,25,P.DOB) BETWEEN @rCompStartDate AND @rCompEndDate 
						AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,23,P.DOB))
						AND P.ChildWData_24 IS NOT NULL --AND P.ChildWData_24 <= @rCompEndDate
					THEN P.CLID END)  ChildScreened_24_comp
	,COUNT( DISTINCT
				CASE WHEN P.ChildReff_24 BETWEEN @rCompStartDate AND @rCompEndDate
					THEN P.CLID END)  ChildReff_24_comp
	,COUNT( DISTINCT
				CASE WHEN (dateadd(month, 25, [DOB]) >= @rCompStartDate 
						and dateadd(month, 25, [DOB]) <= @rCompEndDate) 
						AND (P.EndDate IS NULL OR P.EndDate > DATEADD(MONTH,23,P.DOB))
						AND P.ChildScreened_24 IS NOT NULL
					THEN P.CLID END)  ChildReff_24_denom_comp


FROM UV_Fidelity_CLID P
WHERE CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN P.StateID
		WHEN @rReportType = 3 THEN P.Site_ID
		WHEN @rReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))

	  	
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
   ,0,0,0,0,0,0,0,0,0,0
   ,0,0,0,0,0,0,0,0,0,0
   ,0,0,0,0,0,0,0,0,0,0
   ,0,0,0,0,0,0,0,0,0,0
   ,0,0,0,0,0,0,0,0
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




SELECT 1
	
END






GO
