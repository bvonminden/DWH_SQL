USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Element_17]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Fid_Element_17]
(	@StartDate		Date 
	,@EndDate		Date 
	,@CompStartDate	Date 
	,@CompEndDate	Date 
	,@ParentEntity VARCHAR(4000)
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
--	,@ParentEntity INT
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
--SET @Data			 = 0;

DECLARE 
	@rStartDate		Date 
	,@rEndDate		Date 
	,@rCompStartDate	Date 
	,@rCompEndDate	Date 
	,@rParentEntity INT
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
	,NULL ProgramID
	,NULL ProgramName
	,CASE WHEN P.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
		WHEN P.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName END ReportingEntity
	,FA.Meetings_curr
	,FA.Meetings_comp
	,Floor((DATEDIFF(MONTH,@rStartDate,@rEndDate)+1)/3) Meeting_expect_curr
	,Floor((DATEDIFF(MONTH,@rCompStartDate,@rCompEndDate)+1)/3) Meeting_expect_comp




FROM dbo.fn_Fidelity_Agency(@rStartDate,@rEndDate,@rCompStartDate,@rCompEndDate,@rParentEntity,@rREName,@rReportType) FA
	INNER JOIN UV_PAS P
		ON FA.ProgramID IN (P.Program_ID_NHV,P.Program_ID_Referrals,P.Program_ID_Staff_Supervision)

WHERE CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN P.StateID
		WHEN @rReportType = 3 THEN P.SiteID
		WHEN @rReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))

UNION

SELECT 
	dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
	,P.[US State]
	,P.StateID
	,P.SiteID [Site_ID]
	,P.AGENCY_INFO_0_NAME
	,NULL ProgramID
	,NULL ProgramName
	,CASE WHEN P.SiteID IN (@rParentEntity) THEN @rREName 
		WHEN P.StateID IN (@rParentEntity) THEN @rREName END ReportingEntity
      ,0,0
    ,Floor((DATEDIFF(MONTH,@rStartDate,@rEndDate)+1)/3) Meeting_expect_curr
	,Floor((DATEDIFF(MONTH,@rCompStartDate,@rCompEndDate)+1)/3) Meeting_expect_comp
FROM UV_PAS P
WHERE CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN P.StateID
		WHEN @rReportType = 3 THEN P.SiteID
		WHEN @rReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))

END

ELSE -------------------------- DATA RETURN -----------------------------
BEGIN
SELECT 
	dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
	,P.[US State]
	,P.StateID
	,P.SiteID [Site_ID]
	,P.AGENCY_INFO_0_NAME
	,NULL ProgramID
	,NULL ProgramName
	,CASE WHEN P.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
		WHEN P.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName END ReportingEntity
	,COUNT(DISTINCT
				CASE 
					WHEN APS.CL_EN_GEN_ID IS NOT NULL
						AND APS.AGENCY_INFO_BOARD_0_MEETING_DATE01 IS NOT NULL
						AND APS.AGENCY_INFO_BOARD_0_MEETING_DATE01 BETWEEN @rStartDate AND @rEndDate
					THEN APS.AGENCY_INFO_BOARD_0_MEETING_DATE01
				END)
	+COUNT(DISTINCT
				CASE 
					WHEN APS.CL_EN_GEN_ID IS NOT NULL
						AND APS.AGENCY_INFO_BOARD_0_MEETING_DATE01 IS NOT NULL
						AND APS.AGENCY_INFO_BOARD_0_MEETING_DATE02 BETWEEN @rStartDate AND @rEndDate
					THEN APS.AGENCY_INFO_BOARD_0_MEETING_DATE02
				END)
	+COUNT(DISTINCT
				CASE 
					WHEN APS.CL_EN_GEN_ID IS NOT NULL
						AND APS.AGENCY_INFO_BOARD_0_MEETING_DATE01 IS NOT NULL
						AND APS.AGENCY_INFO_BOARD_0_MEETING_DATE03 BETWEEN @rStartDate AND @rEndDate
					THEN APS.AGENCY_INFO_BOARD_0_MEETING_DATE03
				END)
	+COUNT(DISTINCT
				CASE 
					WHEN APS.CL_EN_GEN_ID IS NOT NULL
						AND APS.AGENCY_INFO_BOARD_0_MEETING_DATE01 IS NOT NULL
						AND APS.AGENCY_INFO_BOARD_0_MEETING_DATE04 BETWEEN @rStartDate AND @rEndDate
					THEN APS.AGENCY_INFO_BOARD_0_MEETING_DATE04
				END) Meetings_Curr
	,COUNT(DISTINCT
				CASE 
					WHEN APS.CL_EN_GEN_ID IS NOT NULL
						AND APS.AGENCY_INFO_BOARD_0_MEETING_DATE01 IS NOT NULL
						AND APS.AGENCY_INFO_BOARD_0_MEETING_DATE01 BETWEEN @rCompStartDate AND @rCompEndDate
					THEN APS.AGENCY_INFO_BOARD_0_MEETING_DATE01
				END)
	+COUNT(DISTINCT
				CASE 
					WHEN APS.CL_EN_GEN_ID IS NOT NULL
						AND APS.AGENCY_INFO_BOARD_0_MEETING_DATE01 IS NOT NULL
						AND APS.AGENCY_INFO_BOARD_0_MEETING_DATE02 BETWEEN @rCompStartDate AND @rCompEndDate
					THEN APS.AGENCY_INFO_BOARD_0_MEETING_DATE02
				END)
	+COUNT(DISTINCT
				CASE 
					WHEN APS.CL_EN_GEN_ID IS NOT NULL
						AND APS.AGENCY_INFO_BOARD_0_MEETING_DATE01 IS NOT NULL
						AND APS.AGENCY_INFO_BOARD_0_MEETING_DATE03 BETWEEN @rCompStartDate AND @rCompEndDate
					THEN APS.AGENCY_INFO_BOARD_0_MEETING_DATE03
				END)
	+COUNT(DISTINCT
				CASE 
					WHEN APS.CL_EN_GEN_ID IS NOT NULL
						AND APS.AGENCY_INFO_BOARD_0_MEETING_DATE01 IS NOT NULL
						AND APS.AGENCY_INFO_BOARD_0_MEETING_DATE04 BETWEEN @rCompStartDate AND @rCompEndDate
					THEN APS.AGENCY_INFO_BOARD_0_MEETING_DATE04
				END) Meetings_Comp
	,Floor((DATEDIFF(MONTH,@rStartDate,@rEndDate)+1)/3) Meeting_expect_curr
	,Floor((DATEDIFF(MONTH,@rCompStartDate,@rCompEndDate)+1)/3) Meeting_expect_comp
	,APS.SurveyResponseID
	FROM 
	Agency_Profile_Survey APS
	INNER JOIN UV_PAS P
		ON APS.ProgramID IN (P.Program_ID_NHV,P.Program_ID_Referrals,P.Program_ID_Staff_Supervision)
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
	,P.AGENCY_INFO_0_NAME
	--,P.ProgramID
	,APS.SurveyResponseID
END
GO
