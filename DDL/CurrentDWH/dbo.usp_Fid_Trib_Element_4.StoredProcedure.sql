USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Trib_Element_4]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Fid_Trib_Element_4]
(	@StartDate		Date 
	,@EndDate		Date 
	,@CompStartDate	Date 
	,@CompEndDate	Date 
	,@ParentEntity Varchar(4000)
	,@REName	VARCHAR(50) 
	,@ReportType	VARCHAR(50) 
	,@Tribal_PM	VARCHAR(10)
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
	,@rTribal_PM	VARCHAR(10)
	,@rData INT
SET @rStartDate		 = @StartDate
SET @rEndDate		 = @EndDate
SET @rCompStartDate	 = @CompStartDate
SET @rCompEndDate	 = @CompEndDate
SET @rParentEntity	 = @ParentEntity
SET @rREName		 = @REName
SET @rReportType	 = @ReportType
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

	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAgeIntake BETWEEN 1 AND 28.999999
						AND P.FirstVisit BETWEEN @StartDate AND @EndDate
					THEN P.CLID
				END) Enrollment_by_28_curr
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAgeIntake BETWEEN 29.0000000000 AND 40.999999
						AND P.FirstVisit BETWEEN @StartDate AND @EndDate
					THEN P.CLID
				END) Enrollment_after_28_curr
	,COUNT(DISTINCT
				CASE 
					WHEN P.FirstVisit BETWEEN @StartDate AND @EndDate
					THEN P.CLID
				END) Total_Enrollment_curr
	,COUNT(DISTINCT
				CASE 
					WHEN P.FirstVisit BETWEEN @StartDate AND @EndDate
						AND P.GestAgeIntake BETWEEN 1 AND 40.999999
					THEN P.CLID
				END) Total_Enrollment_btw1_40_curr
	,COUNT(DISTINCT
				CASE 
					WHEN P.FirstVisit BETWEEN @StartDate AND @EndDate
						AND P.GestAge_EDD IS NULL
					THEN P.CLID
				END) EDD_blank_curr
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAgeIntake BETWEEN 1 AND 28.999999
						AND P.FirstVisit BETWEEN @CompStartDate AND @CompEndDate
					THEN P.CLID
				END) Enrollment_by_28_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAgeIntake BETWEEN 29.0000000000 AND 40.999999
						AND P.FirstVisit BETWEEN @CompStartDate AND @CompEndDate
					THEN P.CLID
				END) Enrollment_after_28_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.FirstVisit BETWEEN @CompStartDate AND @CompEndDate
					THEN P.CLID
				END) Total_Enrollment_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.FirstVisit BETWEEN @CompStartDate AND @CompEndDate
						AND P.GestAgeIntake BETWEEN 1 AND 40.999999
					THEN P.CLID
				END) Total_Enrollment_btw1_40_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.FirstVisit BETWEEN @CompStartDate AND @CompEndDate
						AND P.GestAge_EDD IS NULL
					THEN P.CLID
				END) EDD_blank_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAgeIntake BETWEEN 1 and 16.999999
						AND P.FirstVisit BETWEEN @StartDate AND @EndDate
					THEN P.CLID
				END) Gest_int_1_16_curr
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAgeIntake BETWEEN 17 and 22.999999
						AND P.FirstVisit BETWEEN @StartDate AND @EndDate
					THEN P.CLID
				END) Gest_int_17_22_curr
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAgeIntake BETWEEN 23 and 28.999999
						AND P.FirstVisit BETWEEN @StartDate AND @EndDate
					THEN P.CLID
				END) Gest_int_23_28_curr
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAgeIntake BETWEEN 29 and 40.999999
						AND P.FirstVisit BETWEEN @StartDate AND @EndDate
					THEN P.CLID
				END) Gest_int_29_40_curr
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAgeIntake > 40.999999
						AND P.FirstVisit BETWEEN @StartDate AND @EndDate
					THEN P.CLID
				END) Gest_int_40_more_curr
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAgeIntake <= 0
						AND P.FirstVisit BETWEEN @StartDate AND @EndDate
					THEN P.CLID
				END) Gest_int_0_orless_curr
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAgeIntake IS NULL
						AND P.FirstVisit BETWEEN @StartDate AND @EndDate
					THEN P.CLID
				END) Gest_int_Missing_curr
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAgeIntake BETWEEN 1 and 16.999999
						AND P.FirstVisit BETWEEN @CompStartDate AND @CompEndDate
					THEN P.CLID
				END) Gest_int_1_16_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAgeIntake BETWEEN 17 and 22.999999
						AND P.FirstVisit BETWEEN @CompStartDate AND @CompEndDate
					THEN P.CLID
				END) Gest_int_17_22_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAgeIntake BETWEEN 23 and 28.999999
						AND P.FirstVisit BETWEEN @CompStartDate AND @CompEndDate
					THEN P.CLID
				END) Gest_int_23_28_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAgeIntake BETWEEN 29 and 40.999999
						AND P.FirstVisit BETWEEN @CompStartDate AND @CompEndDate
					THEN P.CLID
				END) Gest_int_29_40_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAgeIntake > 40.999999
						AND P.FirstVisit BETWEEN @CompStartDate AND @CompEndDate
					THEN P.CLID
				END) Gest_int_40_more_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAgeIntake <= 0
						AND P.FirstVisit BETWEEN @CompStartDate AND @CompEndDate
					THEN P.CLID
				END) Gest_int_0_orless_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.GestAgeIntake IS NULL
						AND P.FirstVisit BETWEEN @CompStartDate AND @CompEndDate
					THEN P.CLID
				END) Gest_int_Missing_comp
FROM DataWarehouse..UV_Fidelity_CLID P
	
WHERE CASE
		WHEN @ReportType = 1 THEN 1
		WHEN @ReportType = 2 THEN P.StateID
		WHEN @ReportType = 3 THEN P.Site_ID
		WHEN @ReportType = 4 THEN P.ProgramID
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
	,CASE WHEN P.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @REName 
		WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @REName END ReportingEntity
      ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
FROM DataWarehouse..UV_PAS P
WHERE CASE
		WHEN @ReportType = 1 THEN 1
		WHEN @ReportType = 2 THEN P.StateID
		WHEN @ReportType = 3 THEN P.SiteID
		WHEN @ReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))
	
END

ELSE ------------------------- DATA Return ----------------------
BEGIN


SELECT 1

END

GO
