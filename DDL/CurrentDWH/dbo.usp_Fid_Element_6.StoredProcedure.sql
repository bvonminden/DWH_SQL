USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Element_6]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Fid_Element_6]
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
	

IF @rData = 0
BEGIN

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
	,COUNT(DISTINCT CASE WHEN DATA.Total_Visits_Curr >= 1 THEN DATA.CL_EN_GEN_ID  END) Total_clients_w_Visit_Curr
	,COUNT(DISTINCT CASE WHEN DATA.Total_Visits_Comp >= 1 THEN DATA.CL_EN_GEN_ID  END) Total_clients_w_Visit_Comp
	,COUNT(DISTINCT CASE WHEN DATA.Home_Visit_Curr >= 1 THEN DATA.CL_EN_GEN_ID  END) Total_clients_w_HomeVisit_Curr
	,COUNT(DISTINCT CASE WHEN DATA.Home_Visit_Comp >= 1 THEN DATA.CL_EN_GEN_ID  END) Total_clients_w_HomeVisit_Comp
	,SUM(DATA.Total_Visits_Curr) Total_Visits_Curr
	,SUM(DATA.Total_Visits_Comp) Total_Visits_Comp
	,SUM(DATA.Home_Visit_Curr) Total_HomeVisits_Curr
	,SUM(DATA.Home_Visit_Comp) Total_HomeVisits_Comp
	,SUM(DATA.Percent_Home_Visits_Curr) Sum_Percent_Home_Visits_Curr
	,SUM(DATA.Percent_Home_Visits_Comp) Sum_Percent_Home_Visits_Comp
	FROM 	
	(SELECT 
		HVES.CL_EN_GEN_ID 	
		,HVES.ProgramID
		,HVES.SiteID
		,COUNT(DISTINCT CASE WHEN HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate THEN HVES.SurveyResponseID  END) Total_Visits_Curr
		,COUNT(DISTINCT CASE WHEN HVES.Home_Visit = 1 AND HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate THEN HVES.SurveyResponseID  END) Home_Visit_Curr
		,CASE WHEN COUNT(DISTINCT CASE WHEN HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate THEN HVES.SurveyResponseID  END)=0 
			  THEN NULL 
			  ELSE CAST(COUNT(DISTINCT CASE WHEN HVES.Home_Visit = 1 AND HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate THEN HVES.SurveyResponseID  END) AS FLOAT) 
				   /CAST(COUNT(DISTINCT CASE WHEN HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate THEN HVES.SurveyResponseID  END) AS FLOAT) END Percent_Home_Visits_Curr
				   
		,COUNT(DISTINCT CASE WHEN HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate THEN HVES.SurveyResponseID  END) Total_Visits_Comp
		,COUNT(DISTINCT CASE WHEN HVES.Home_Visit = 1 AND HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate THEN HVES.SurveyResponseID  END) Home_Visit_Comp
		,CASE WHEN COUNT(DISTINCT CASE WHEN HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate THEN HVES.SurveyResponseID  END)=0 
			  THEN NULL 
			  ELSE CAST(COUNT(DISTINCT CASE WHEN HVES.Home_Visit = 1 AND HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate THEN HVES.SurveyResponseID  END) AS FLOAT) 
				   /CAST(COUNT(DISTINCT CASE WHEN HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate THEN HVES.SurveyResponseID  END) AS FLOAT) END Percent_Home_Visits_Comp
	FROM UV_Fidelity_HVES HVES
	WHERE HVES.SurveyDate BETWEEN @rCompStartDate AND @rEndDate
	GROUP BY
		HVES.CL_EN_GEN_ID 	
		,HVES.ProgramID
		,HVES.SiteID) DATA
INNER JOIN UV_PAS P
	ON P.SiteID = DATA.SiteID
	AND P.ProgramID = DATA.ProgramID
	
WHERE CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN P.StateID
		WHEN @rReportType = 3 THEN P.SiteID
		WHEN @rReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))
	  	
GROUP BY 
	P.SiteID
	,dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) 
	,P.[US State]
	,P.StateID
	,P.SiteID
	,P.AGENCY_INFO_0_NAME
	,P.ProgramID

	
UNION

SELECT 
	dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
	,P.[US State]
	,P.StateID
	,P.SiteID [Site_ID]
	,P.AGENCY_INFO_0_NAME
	,P.ProgramID
	,dbo.udf_fn_GetCleanProg(P.ProgramID) ProgramName
	,CASE WHEN P.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @REName 
		WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @REName END ReportingEntity
	,0,0,0,0,0,0,0,0,0,0
      
FROM UV_PAS P
WHERE CASE
		WHEN @ReportType = 1 THEN 1
		WHEN @ReportType = 2 THEN P.StateID
		WHEN @ReportType = 3 THEN P.SiteID
		WHEN @ReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))
		

END

ELSE ------------------------- DATA Return ----------------------
BEGIN

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
	,COUNT(DISTINCT CASE WHEN DATA.Total_Visits_Curr >= 1 THEN DATA.CL_EN_GEN_ID  END) Total_clients_w_Visit_Curr
	,COUNT(DISTINCT CASE WHEN DATA.Total_Visits_Comp >= 1 THEN DATA.CL_EN_GEN_ID  END) Total_clients_w_Visit_Comp
	,COUNT(DISTINCT CASE WHEN DATA.Home_Visit_Curr >= 1 THEN DATA.CL_EN_GEN_ID  END) Total_clients_w_HomeVisit_Curr
	,COUNT(DISTINCT CASE WHEN DATA.Home_Visit_Comp >= 1 THEN DATA.CL_EN_GEN_ID  END) Total_clients_w_HomeVisit_Comp
	,SUM(DATA.Total_Visits_Curr) Total_Visits_Curr
	,SUM(DATA.Total_Visits_Comp) Total_Visits_Comp
	,SUM(DATA.Home_Visit_Curr) Total_HomeVisits_Curr
	,SUM(DATA.Home_Visit_Comp) Total_HomeVisits_Comp
	,SUM(DATA.Percent_Home_Visits_Curr) Sum_Percent_Home_Visits_Curr
	,SUM(DATA.Percent_Home_Visits_Comp) Sum_Percent_Home_Visits_Comp
	,DATA.CL_EN_GEN_ID
	FROM 	
	(SELECT 
		HVES.CL_EN_GEN_ID 	
		,HVES.ProgramID
		,HVES.SiteID
		,COUNT(DISTINCT CASE WHEN HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate THEN HVES.SurveyResponseID  END) Total_Visits_Curr
		,COUNT(DISTINCT CASE WHEN HVES.Home_Visit = 1 AND HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate THEN HVES.SurveyResponseID  END) Home_Visit_Curr
		,CASE WHEN COUNT(DISTINCT CASE WHEN HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate THEN HVES.SurveyResponseID  END)=0 
			  THEN NULL 
			  ELSE CAST(COUNT(DISTINCT CASE WHEN HVES.Home_Visit = 1 AND HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate THEN HVES.SurveyResponseID  END) AS FLOAT) 
				   /CAST(COUNT(DISTINCT CASE WHEN HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate THEN HVES.SurveyResponseID  END) AS FLOAT) END Percent_Home_Visits_Curr
				   
		,COUNT(DISTINCT CASE WHEN HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate THEN HVES.SurveyResponseID  END) Total_Visits_Comp
		,COUNT(DISTINCT CASE WHEN HVES.Home_Visit = 1 AND HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate THEN HVES.SurveyResponseID  END) Home_Visit_Comp
		,CASE WHEN COUNT(DISTINCT CASE WHEN HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate THEN HVES.SurveyResponseID  END)=0 
			  THEN NULL 
			  ELSE CAST(COUNT(DISTINCT CASE WHEN HVES.Home_Visit = 1 AND HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate THEN HVES.SurveyResponseID  END) AS FLOAT) 
				   /CAST(COUNT(DISTINCT CASE WHEN HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate THEN HVES.SurveyResponseID  END) AS FLOAT) END Percent_Home_Visits_Comp
	FROM UV_Fidelity_HVES HVES
	WHERE HVES.SurveyDate BETWEEN @rCompStartDate AND @rEndDate
	GROUP BY
		HVES.CL_EN_GEN_ID 	
		,HVES.ProgramID
		,HVES.SiteID) DATA
INNER JOIN UV_PAS P
	ON P.SiteID = DATA.SiteID
	AND P.ProgramID = DATA.ProgramID
	
WHERE CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN P.StateID
		WHEN @rReportType = 3 THEN P.SiteID
		WHEN @rReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))
	  	
GROUP BY 
	P.SiteID
	,dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) 
	,P.[US State]
	,P.StateID
	,P.SiteID
	,P.AGENCY_INFO_0_NAME
	,P.ProgramID,DATA.CL_EN_GEN_ID

END
GO
