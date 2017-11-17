USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Element_5]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Fid_Element_5]
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
--SET @ParentEntity	 = 14
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
	
	,SUM(CASE WHEN P.SurveyDate BETWEEN @rStartDate AND @rEndDate /*AND P.Rank_dup=1*/ THEN 1 ELSE 0 END) Total_Visits_Curr
	,SUM(CASE WHEN P.SurveyDate BETWEEN @rStartDate AND @rEndDate AND P.Count_dup=1 THEN 1 ELSE 0 END) One_on_one_Visit_Curr
	,SUM(CASE WHEN P.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate /*AND P.Rank_dup=1*/ THEN 1 ELSE 0 END) Total_Visits_Comp
	,SUM(CASE WHEN P.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate AND P.Count_dup=1 THEN 1 ELSE 0 END) One_on_one_Visit_Comp
	
FROM UV_Fidelity_HVES P
	
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
      ,0,0,0,0
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
	
	,SUM(CASE WHEN P.SurveyDate BETWEEN @rStartDate AND @rEndDate /*AND P.Rank_dup=1*/ THEN 1 ELSE 0 END) Total_Visits_Curr
	,SUM(CASE WHEN P.SurveyDate BETWEEN @rStartDate AND @rEndDate AND P.Count_dup=1 THEN 1 ELSE 0 END) One_on_one_Visit_Curr
	,SUM(CASE WHEN P.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate /*AND P.Rank_dup=1*/ THEN 1 ELSE 0 END) Total_Visits_Comp
	,SUM(CASE WHEN P.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate AND P.Count_dup=1 THEN 1 ELSE 0 END) One_on_one_Visit_Comp
	,P.CL_EN_GEN_ID
	
FROM UV_Fidelity_HVES P
	
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
	,P.CL_EN_GEN_ID
--ORDER BY 1


END
GO
