USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Outcome_11c]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Fid_Outcome_11c]
(	@StartDate		Date 
	,@EndDate		Date 
	,@CompStartDate	Date 
	,@CompEndDate	Date 
	,@ParentEntity Varchar(4000)
	,@REName	VARCHAR(50) 
	,@ReportType	VARCHAR(50) 
	,@Data INT
	--,@ReportPeriod	INT
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
--SET @StartDate		 = CAST('4/1/2012' AS DATE)
--SET @EndDate		 = DATEADD(D,-1,DATEADD(YEAR,1,@StartDate))
--SET @CompStartDate	 = CAST('4/1/2011' AS DATE)
--SET @CompEndDate	 = DATEADD(D,-1,DATEADD(YEAR,1,@CompStartDate))
--SET @ParentEntity	 = 14
--SET @REName			 = NULL
--SET @ReportType		 = 2
--SET @ReportPeriod	= 6
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
	,COUNT(DISTINCT CASE WHEN P.SETotalWData_6 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalWData_6
	,COUNT(DISTINCT CASE WHEN P.SETotalWOData_6 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalWOData_6
	,COUNT(DISTINCT CASE WHEN P.SETotalScreenedCount_6 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalScreenedCount_6
	,COUNT(DISTINCT CASE WHEN P.SETotalRefCount_6 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalRefCount_6
	,COUNT(DISTINCT CASE WHEN P.SETotalNotEligibleCount_6 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalNotEligibleCount_6
	,COUNT(DISTINCT CASE WHEN P.SETotalDeclinedCount_6 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalDeclinedCount_6

	,COUNT(DISTINCT CASE WHEN P.SETotalWData_12 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalWData_12
	,COUNT(DISTINCT CASE WHEN P.SETotalWOData_12 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalWOData_12
	,COUNT(DISTINCT CASE WHEN P.SETotalScreenedCount_12 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalScreenedCount_12
	,COUNT(DISTINCT CASE WHEN P.SETotalRefCount_12 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalRefCount_12
	,COUNT(DISTINCT CASE WHEN P.SETotalNotEligibleCount_12 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalNotEligibleCount_12
	,COUNT(DISTINCT CASE WHEN P.SETotalDeclinedCount_12 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalDeclinedCount_12

	,COUNT(DISTINCT CASE WHEN P.SETotalWData_18 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalWData_18
	,COUNT(DISTINCT CASE WHEN P.SETotalWOData_18 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalWOData_18
	,COUNT(DISTINCT CASE WHEN P.SETotalScreenedCount_18 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalScreenedCount_18
	,COUNT(DISTINCT CASE WHEN P.SETotalRefCount_18 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalRefCount_18
	,COUNT(DISTINCT CASE WHEN P.SETotalNotEligibleCount_18 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalNotEligibleCount_18
	,COUNT(DISTINCT CASE WHEN P.SETotalDeclinedCount_18 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalDeclinedCount_18
	
	,COUNT(DISTINCT CASE WHEN P.SETotalWData_24 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalWData_24
	,COUNT(DISTINCT CASE WHEN P.SETotalWOData_24 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalWOData_24
	,COUNT(DISTINCT CASE WHEN P.SETotalScreenedCount_24 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalScreenedCount_24
	,COUNT(DISTINCT CASE WHEN P.SETotalRefCount_24 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalRefCount_24
	,COUNT(DISTINCT CASE WHEN P.SETotalNotEligibleCount_24 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalNotEligibleCount_24
	,COUNT(DISTINCT CASE WHEN P.SETotalDeclinedCount_24 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalDeclinedCount_24
	
---------- Compare period ---------

	,COUNT(DISTINCT CASE WHEN P.SETotalWData_6 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalWData_6_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalWOData_6 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalWOData_6_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalScreenedCount_6 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalScreenedCount_6_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalRefCount_6 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalRefCount_6_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalNotEligibleCount_6 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalNotEligibleCount_6_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalDeclinedCount_6 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalDeclinedCount_6_comp

	,COUNT(DISTINCT CASE WHEN P.SETotalWData_12 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalWData_12_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalWOData_12 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalWOData_12_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalScreenedCount_12 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalScreenedCount_12_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalRefCount_12 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalRefCount_12_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalNotEligibleCount_12 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalNotEligibleCount_12_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalDeclinedCount_12 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalDeclinedCount_12_comp

	,COUNT(DISTINCT CASE WHEN P.SETotalWData_18 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalWData_18_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalWOData_18 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalWOData_18_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalScreenedCount_18 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalScreenedCount_18_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalRefCount_18 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalRefCount_18_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalNotEligibleCount_18 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalNotEligibleCount_18_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalDeclinedCount_18 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalDeclinedCount_18_comp
	
	,COUNT(DISTINCT CASE WHEN P.SETotalWData_24 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalWData_24_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalWOData_24 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalWOData_24_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalScreenedCount_24 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalScreenedCount_24_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalRefCount_24 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalRefCount_24_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalNotEligibleCount_24 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalNotEligibleCount_24_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalDeclinedCount_24 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalDeclinedCount_24_comp
				
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
   ,0,0,0,0,0,0,0,0,0,0,0,0 ,0,0,0,0,0,0,0,0,0,0,0,0 ,0,0,0,0,0,0,0,0,0,0,0,0 ,0,0,0,0,0,0,0,0,0,0,0,0
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

	,P.CLID
---------- Current period ---------	
	,COUNT(DISTINCT CASE WHEN P.SETotalWData_6 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalWData_6
	,COUNT(DISTINCT CASE WHEN P.SETotalWOData_6 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalWOData_6
	,COUNT(DISTINCT CASE WHEN P.SETotalScreenedCount_6 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalScreenedCount_6
	,COUNT(DISTINCT CASE WHEN P.SETotalRefCount_6 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalRefCount_6
	,COUNT(DISTINCT CASE WHEN P.SETotalNotEligibleCount_6 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalNotEligibleCount_6
	,COUNT(DISTINCT CASE WHEN P.SETotalDeclinedCount_6 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalDeclinedCount_6

	,COUNT(DISTINCT CASE WHEN P.SETotalWData_12 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalWData_12
	,COUNT(DISTINCT CASE WHEN P.SETotalWOData_12 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalWOData_12
	,COUNT(DISTINCT CASE WHEN P.SETotalScreenedCount_12 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalScreenedCount_12
	,COUNT(DISTINCT CASE WHEN P.SETotalRefCount_12 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalRefCount_12
	,COUNT(DISTINCT CASE WHEN P.SETotalNotEligibleCount_12 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalNotEligibleCount_12
	,COUNT(DISTINCT CASE WHEN P.SETotalDeclinedCount_12 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalDeclinedCount_12

	,COUNT(DISTINCT CASE WHEN P.SETotalWData_18 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalWData_18
	,COUNT(DISTINCT CASE WHEN P.SETotalWOData_18 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalWOData_18
	,COUNT(DISTINCT CASE WHEN P.SETotalScreenedCount_18 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalScreenedCount_18
	,COUNT(DISTINCT CASE WHEN P.SETotalRefCount_18 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalRefCount_18
	,COUNT(DISTINCT CASE WHEN P.SETotalNotEligibleCount_18 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalNotEligibleCount_18
	,COUNT(DISTINCT CASE WHEN P.SETotalDeclinedCount_18 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalDeclinedCount_18
	
	,COUNT(DISTINCT CASE WHEN P.SETotalWData_24 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalWData_24
	,COUNT(DISTINCT CASE WHEN P.SETotalWOData_24 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalWOData_24
	,COUNT(DISTINCT CASE WHEN P.SETotalScreenedCount_24 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalScreenedCount_24
	,COUNT(DISTINCT CASE WHEN P.SETotalRefCount_24 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalRefCount_24
	,COUNT(DISTINCT CASE WHEN P.SETotalNotEligibleCount_24 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalNotEligibleCount_24
	,COUNT(DISTINCT CASE WHEN P.SETotalDeclinedCount_24 BETWEEN @rStartDate AND @rEndDate THEN P.CLID END) SETotalDeclinedCount_24
	
---------- Compare period ---------

	,COUNT(DISTINCT CASE WHEN P.SETotalWData_6 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalWData_6_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalWOData_6 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalWOData_6_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalScreenedCount_6 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalScreenedCount_6_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalRefCount_6 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalRefCount_6_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalNotEligibleCount_6 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalNotEligibleCount_6_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalDeclinedCount_6 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalDeclinedCount_6_comp

	,COUNT(DISTINCT CASE WHEN P.SETotalWData_12 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalWData_12_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalWOData_12 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalWOData_12_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalScreenedCount_12 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalScreenedCount_12_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalRefCount_12 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalRefCount_12_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalNotEligibleCount_12 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalNotEligibleCount_12_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalDeclinedCount_12 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalDeclinedCount_12_comp

	,COUNT(DISTINCT CASE WHEN P.SETotalWData_18 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalWData_18_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalWOData_18 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalWOData_18_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalScreenedCount_18 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalScreenedCount_18_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalRefCount_18 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalRefCount_18_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalNotEligibleCount_18 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalNotEligibleCount_18_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalDeclinedCount_18 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalDeclinedCount_18_comp
	
	,COUNT(DISTINCT CASE WHEN P.SETotalWData_24 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalWData_24_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalWOData_24 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalWOData_24_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalScreenedCount_24 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalScreenedCount_24_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalRefCount_24 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalRefCount_24_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalNotEligibleCount_24 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalNotEligibleCount_24_comp
	,COUNT(DISTINCT CASE WHEN P.SETotalDeclinedCount_24 BETWEEN @rCompStartDate AND @rCompEndDate THEN P.CLID END) SETotalDeclinedCount_24_comp	
				
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
	,P.CLID
--ORDER BY 1
	
END
GO
