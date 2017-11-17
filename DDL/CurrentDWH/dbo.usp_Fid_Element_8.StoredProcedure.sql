USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Element_8]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Fid_Element_8]
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
--	,@ReportType VARCHAR(50) 
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
SET @rREName			 = @REName
SET @rReportType		 = @ReportType
SET @rData			 = @Data;


IF @rData = 0
BEGIN



SELECT 
	dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
	,P.[US State]
	,P.StateID
	,P.[SiteID] [Site_ID]
	,P.AGENCY_INFO_0_NAME
	,CASE WHEN @ReportType = 3 THEN P.SiteID ELSE P.ProgramID END ProgramID
	,dbo.udf_fn_GetCleanProg(CASE WHEN @ReportType = 3 THEN NULL ELSE P.ProgramID END) ProgramName
	,CASE WHEN P.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
		WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName END ReportingEntity


	,( CASE WHEN DATA.rpt = 1 AND DATA.Degree = 1 THEN DATA.Entity_Id END) Doctorate_curr
	,( CASE WHEN DATA.rpt = 1 AND DATA.Degree = 2 THEN DATA.Entity_Id END) Masters_curr
	,( CASE WHEN DATA.rpt = 1 AND DATA.Degree = 3 THEN DATA.Entity_Id END) Bachelors_curr
	,( CASE WHEN DATA.rpt = 1 AND DATA.Degree = 4 THEN DATA.Entity_Id END) Associates_curr
	,( CASE WHEN DATA.rpt = 1 AND DATA.Degree = 5 THEN DATA.Entity_Id END) Diploma_curr
	,( CASE WHEN DATA.rpt = 1 AND DATA.Degree = 6 THEN DATA.Entity_Id END) NA_curr
	,( CASE WHEN DATA.rpt = 1 AND DATA.Degree = 7 THEN DATA.Entity_Id END) Missing_curr
	,( CASE WHEN DATA.rpt = 1 AND DATA.Degree BETWEEN 1 AND 7 THEN DATA.Entity_Id END) Total_curr
	
	,( CASE WHEN DATA.rpt = 2 AND DATA.Degree = 1 THEN DATA.Entity_Id END) Doctorate_comp
	,( CASE WHEN DATA.rpt = 2 AND DATA.Degree = 2 THEN DATA.Entity_Id END) Masters_comp
	,( CASE WHEN DATA.rpt = 2 AND DATA.Degree = 3 THEN DATA.Entity_Id END) Bachelors_comp
	,( CASE WHEN DATA.rpt = 2 AND DATA.Degree = 4 THEN DATA.Entity_Id END) Associates_comp
	,( CASE WHEN DATA.rpt = 2 AND DATA.Degree = 5 THEN DATA.Entity_Id END) Diploma_comp
	,( CASE WHEN DATA.rpt = 2 AND DATA.Degree = 6 THEN DATA.Entity_Id END) NA_comp
	,( CASE WHEN DATA.rpt = 2 AND DATA.Degree = 7 THEN DATA.Entity_Id END) Missing_comp
	,( CASE WHEN DATA.rpt = 2 AND DATA.Degree BETWEEN 1 AND 7 THEN DATA.Entity_Id END) Total_comp
	--,DATA.Full_Name,DATA.Entity_Id,DATA.HV_FTE,DATA.S_FTE
	--,DATA.NHV_Flag
	--,DATA.NS_Flag
FROM(
SELECT *,1 rpt
FROM dbo.fn_Fidelity_Staff_El8 (@rStartDate,@rEndDate) S
WHERE (S.EndDate > @rEndDate OR S.EndDate IS NULL)

UNION ALL

SELECT *,2 rpt
FROM dbo.fn_Fidelity_Staff_El8 (@rCompStartDate,@rCompEndDate) S
WHERE (S.EndDate > @rCompEndDate OR S.EndDate IS NULL)
) DATA


INNER JOIN UV_PAS P
ON DATA.ProgramID = P.ProgramID

WHERE  CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN P.StateID
		WHEN @rReportType = 3 THEN P.SiteID
		WHEN @rReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))
		
--GROUP BY 
--	P.SiteID
--	,dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) 
--	,P.[US State]
--	,P.StateID
--	,P.AGENCY_INFO_0_NAME
--	,CASE WHEN @ReportType = 3 THEN P.SiteID ELSE P.ProgramID END
--	,CASE WHEN @ReportType = 3 THEN NULL ELSE P.ProgramID END
	--,DATA.Full_Name,DATA.Entity_Id,DATA.HV_FTE,DATA.S_FTE
	--,DATA.NHV_Flag
	--,DATA.NS_Flag
--ORDER BY 1

--UNION

--SELECT 
--	dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
--	,P.[US State]
--	,P.StateID
--	,P.SiteID [Site_ID]
--	,P.AGENCY_INFO_0_NAME
--	,CASE WHEN @ReportType = 3 THEN P.SiteID ELSE P.ProgramID END ProgramID
--	,dbo.udf_fn_GetCleanProg(CASE WHEN @ReportType = 3 THEN NULL ELSE P.ProgramID END) ProgramName
--	,CASE WHEN P.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
--		WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName END ReportingEntity
--      ,0,0,0,0,0,0,0,0 ,0,0,0,0,0,0,0,0
      
--FROM UV_PAS P
--WHERE CASE
--		WHEN @rReportType = 1 THEN 1
--		WHEN @rReportType = 2 THEN P.StateID
--		WHEN @rReportType = 3 THEN P.SiteID
--		WHEN @rReportType = 4 THEN P.ProgramID
--	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))

END

ELSE ------------------------- DATA Return ----------------------
BEGIN


SELECT 
	dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
	,P.[US State]
	,P.StateID
	,P.[SiteID] [Site_ID]
	,P.AGENCY_INFO_0_NAME
	,CASE WHEN @ReportType = 3 THEN P.SiteID ELSE P.ProgramID END ProgramID
	,dbo.udf_fn_GetCleanProg(CASE WHEN @ReportType = 3 THEN NULL ELSE P.ProgramID END) ProgramName
	,CASE WHEN P.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
		WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName END ReportingEntity


	,( CASE WHEN DATA.rpt = 1 AND DATA.Degree = 1 THEN DATA.Entity_Id END) Doctorate_curr
	,( CASE WHEN DATA.rpt = 1 AND DATA.Degree = 2 THEN DATA.Entity_Id END) Masters_curr
	,( CASE WHEN DATA.rpt = 1 AND DATA.Degree = 3 THEN DATA.Entity_Id END) Bachelors_curr
	,( CASE WHEN DATA.rpt = 1 AND DATA.Degree = 4 THEN DATA.Entity_Id END) Associates_curr
	,( CASE WHEN DATA.rpt = 1 AND DATA.Degree = 5 THEN DATA.Entity_Id END) Diploma_curr
	,( CASE WHEN DATA.rpt = 1 AND DATA.Degree = 6 THEN DATA.Entity_Id END) NA_curr
	,( CASE WHEN DATA.rpt = 1 AND DATA.Degree = 7 THEN DATA.Entity_Id END) Missing_curr
	,( CASE WHEN DATA.rpt = 1 AND DATA.Degree BETWEEN 1 AND 7 THEN DATA.Entity_Id END) Total_curr
	
	,( CASE WHEN DATA.rpt = 2 AND DATA.Degree = 1 THEN DATA.Entity_Id END) Doctorate_comp
	,( CASE WHEN DATA.rpt = 2 AND DATA.Degree = 2 THEN DATA.Entity_Id END) Masters_comp
	,( CASE WHEN DATA.rpt = 2 AND DATA.Degree = 3 THEN DATA.Entity_Id END) Bachelors_comp
	,( CASE WHEN DATA.rpt = 2 AND DATA.Degree = 4 THEN DATA.Entity_Id END) Associates_comp
	,( CASE WHEN DATA.rpt = 2 AND DATA.Degree = 5 THEN DATA.Entity_Id END) Diploma_comp
	,( CASE WHEN DATA.rpt = 2 AND DATA.Degree = 6 THEN DATA.Entity_Id END) NA_comp
	,( CASE WHEN DATA.rpt = 2 AND DATA.Degree = 7 THEN DATA.Entity_Id END) Missing_comp
	,( CASE WHEN DATA.rpt = 2 AND DATA.Degree BETWEEN 1 AND 7 THEN DATA.Entity_Id END) Total_comp
	,DATA.Entity_Id
FROM(
SELECT *,1 rpt
FROM dbo.fn_Fidelity_Staff_El8 (@rStartDate,@rEndDate) S
WHERE (S.EndDate > @rEndDate OR S.EndDate IS NULL)

UNION ALL

SELECT *,2 rpt
FROM dbo.fn_Fidelity_Staff_El8 (@rCompStartDate,@rCompEndDate) S
WHERE (S.EndDate > @rCompEndDate OR S.EndDate IS NULL)
) DATA


INNER JOIN UV_PAS P
ON DATA.ProgramID = P.ProgramID

WHERE  CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN P.StateID
		WHEN @rReportType = 3 THEN P.SiteID
		WHEN @rReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))
		
--GROUP BY 
--	P.SiteID
--	,dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) 
--	,P.[US State]
--	,P.StateID
--	,P.AGENCY_INFO_0_NAME
--	,CASE WHEN @ReportType = 3 THEN P.SiteID ELSE P.ProgramID END
--	,CASE WHEN @ReportType = 3 THEN NULL ELSE P.ProgramID END
--	,DATA.Entity_Id
END
GO
