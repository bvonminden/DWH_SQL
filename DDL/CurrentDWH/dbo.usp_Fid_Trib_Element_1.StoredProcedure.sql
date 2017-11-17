USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Trib_Element_1]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Fid_Trib_Element_1]
(	@StartDate		Date 
	,@EndDate		Date 
	,@CompStartDate	Date 
	,@CompEndDate	Date 
	,@ParentEntity VARCHAR(4000)
	,@REName	VARCHAR(50) 
	,@ReportType	VARCHAR(50) 
	,@Tribal_PM	VARCHAR(10)
	,@Data INT
)

AS

--DECLARE 
	--@StartDate		Date 
	--,@EndDate		Date 
	--,@CompStartDate	Date 
	--,@CompEndDate	Date 
	--,@ParentEntity VARCHAR(4000)
	--,@REName VARCHAR(50) 
	--,@ReportType VARCHAR(50) 
--SET @StartDate		 = CAST('4/1/2012' AS DATE)
--SET @EndDate		 = DATEADD(D,-1,DATEADD(YEAR,1,@StartDate))
--SET @CompStartDate	 = CAST('4/1/2011' AS DATE)
--SET @CompEndDate	 = DATEADD(D,-1,DATEADD(YEAR,1,@CompStartDate))
--SET @ParentEntity	 = 18
--SET @REName			 = NULL
--SET @ReportType		 = 2;

DECLARE 
	@rStartDate		Date 
	,@rEndDate		Date 
	,@rCompStartDate	Date 
	,@rCompEndDate	Date 
	,@rParentEntity VARCHAR(4000)
	,@rREName VARCHAR(50) 
	,@rReportType VARCHAR(50) 
	,@rTribal_PM	VARCHAR(10)
	,@rData INT
SET @rStartDate		 = @StartDate
SET @rEndDate		 = @EndDate
SET @rCompStartDate	 = @CompStartDate
SET @rCompEndDate	 = @CompEndDate
SET @rParentEntity	 = @ParentEntity
SET @rREName			 = @REName
SET @rReportType		 = @ReportType
SET @rTribal_PM		 = @Tribal_PM
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
	,ISNULL(COUNT(DISTINCT CASE 
			WHEN P.VolPart_yes BETWEEN @rStartDate AND @rEndDate
			THEN P.CLID
		END),0) VolPart_yes
	,ISNULL(COUNT(DISTINCT CASE 
			WHEN P.VolPart_data BETWEEN @rStartDate AND @rEndDate
			THEN P.CLID
		END),0) VolPart_data
	,ISNULL(COUNT(DISTINCT CASE 
			WHEN P.VolPart_missing BETWEEN @rStartDate AND @rEndDate
			THEN P.CLID
		END),0) VolPart_missing
	,ISNULL(COUNT(DISTINCT CASE 
			WHEN P.VolPart_yes BETWEEN @rCompStartDate AND @rCompEndDate
			THEN P.CLID
		END),0) VolPart_yes_comp
	,ISNULL(COUNT(DISTINCT CASE 
			WHEN P.VolPart_data BETWEEN @rCompStartDate AND @rCompEndDate
			THEN P.CLID
		END),0) VolPart_data_comp
	,ISNULL(COUNT(DISTINCT CASE 
			WHEN P.VolPart_missing BETWEEN @rCompStartDate AND @rCompEndDate
			THEN P.CLID
		END),0) VolPart_missing_comp
FROM DataWarehouse..UV_Fidelity_CLID P

WHERE  CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN P.StateID
		WHEN @rReportType = 3 THEN P.Site_ID
		WHEN @rReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))
	  AND P.RankingLatest = 1

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
      ,0,0,0,0,0,0 
      
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

END --changing a test comment

GO
