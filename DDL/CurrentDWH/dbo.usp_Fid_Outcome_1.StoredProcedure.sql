USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Outcome_1]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_Fid_Outcome_1]
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
--SET @CompStartDate	 = CAST('1/1/2011' AS DATE)
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
	,P.Site_ID [Site_ID]
	,P.AGENCY_INFO_0_NAME
	,P.ProgramID
	,dbo.udf_fn_GetCleanProg(P.ProgramID) ProgramName
	,CASE WHEN P.Site_ID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
		WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName END ReportingEntity
	,COUNT(DISTINCT
				CASE 
					WHEN P.SmokingIntake <= @rEndDate
						AND ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rStartDate AND @rEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rEndDate 
					THEN P.CLID
				END) Smoking_intake_yes_curr
	,COUNT(DISTINCT
				CASE 
					WHEN P.SmokingIntakeData <= @rEndDate
						AND P.SmokingPreg36Data BETWEEN @rStartDate AND @rEndDate 
						AND ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rStartDate AND @rEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rEndDate 
					THEN P.CLID
				END) Smoking_total_curr
	,COUNT(DISTINCT
				CASE 
					WHEN P.SmokingPreg36 <= @rEndDate
						AND ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rStartDate AND @rEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rEndDate 
					THEN P.CLID
				END) Smoking_36w_yes_curr
	,COUNT(DISTINCT
				CASE 
					WHEN P.SmokingIntakeMissing <= @rEndDate
						AND P.SmokingPreg36Data BETWEEN @rStartDate AND @rEndDate
						AND ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rStartDate AND @rEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rEndDate 
					THEN P.CLID
				END) Smoking_intake_missing_curr
	,COUNT(DISTINCT
				CASE 
					WHEN  P.SmokingIntakeData <= @rEndDate
						AND P.SmokingPreg36Missing BETWEEN @rStartDate AND @rEndDate
						AND ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rStartDate AND @rEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rEndDate 
					THEN P.CLID
				END) Smoking_36w_missing_curr
	,COUNT(DISTINCT
				CASE 
					WHEN P.SmokingIntakeMissing <= @rEndDate
						AND P.SmokingPreg36Missing BETWEEN @rStartDate AND @rEndDate
						AND ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rStartDate AND @rEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rEndDate 
					THEN P.CLID
				END) Smoking_both_missing_curr
	,COUNT(DISTINCT
				CASE 
					WHEN ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rStartDate AND @rEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rEndDate 
					THEN P.CLID
				END) Smoking_miss_total_curr
	,COUNT(DISTINCT
				CASE 
					WHEN P.SmokingPreg36Form BETWEEN @rStartDate AND @rEndDate AND P.SmokingIntakeForm <= @rEndDate 
					THEN P.CLID
				END) SurveyTotal		
					
	,COUNT(DISTINCT
				CASE 
					WHEN P.SmokingIntake <= @rCompEndDate
						AND ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rCompStartDate AND @rCompEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rCompEndDate 
					THEN P.CLID
				END) Smoking_intake_yes_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.SmokingIntakeData <= @rCompEndDate
						AND P.SmokingPreg36Data BETWEEN @rCompStartDate AND @rCompEndDate
						AND ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rCompStartDate AND @rCompEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rCompEndDate 
					THEN P.CLID
				END) Smoking_total_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.SmokingPreg36 <= @rCompEndDate
						AND ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rCompStartDate AND @rCompEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rCompEndDate 
					THEN P.CLID
				END) Smoking_36w_yes_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.SmokingIntakeMissing <= @rCompEndDate
						AND P.SmokingPreg36Data BETWEEN @rCompStartDate AND @rCompEndDate
						AND ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rCompStartDate AND @rCompEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rCompEndDate 
					THEN P.CLID
				END) Smoking_intake_missing_comp
	,COUNT(DISTINCT
				CASE 
					WHEN  P.SmokingIntakeData <= @rCompEndDate
						AND P.SmokingPreg36Missing BETWEEN @rCompStartDate AND @rCompEndDate
						AND ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rCompStartDate AND @rCompEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rCompEndDate 
					THEN P.CLID
				END) Smoking_36w_missing_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.SmokingIntakeMissing <= @rCompEndDate
						AND P.SmokingPreg36Missing BETWEEN @rCompStartDate AND @rCompEndDate
						AND ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rCompStartDate AND @rCompEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rCompEndDate 
					THEN P.CLID
				END) Smoking_both_missing_comp
	,COUNT(DISTINCT
				CASE 
					WHEN ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rCompStartDate AND @rCompEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rCompEndDate 
					THEN P.CLID
				END) Smoking_miss_total_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.SmokingPreg36Form BETWEEN @rCompStartDate AND @rCompEndDate AND P.SmokingIntakeForm <= @rCompEndDate 
					THEN P.CLID
				END) SurveyTotal_comp
	,NULL CLID
	
FROM 

UV_Fidelity_CLID P

WHERE CASE
		WHEN @ReportType = 1 THEN 1
		WHEN @ReportType = 2 THEN P.StateID
		WHEN @ReportType = 3 THEN P.Site_ID
		WHEN @ReportType = 4 THEN P.ProgramID
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
	,CASE WHEN P.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @REName 
		WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @REName END ReportingEntity
     ,0,0,0,0,0,0,0,0 ,0,0,0,0,0,0,0,0,NULL
      
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
	dbo.udf_StateVSTribal(P.Abbreviation,P.Site_ID) [State]
	,P.[US State]
	,P.StateID
	,P.Site_ID [Site_ID]
	,P.AGENCY_INFO_0_NAME
	,P.ProgramID
	,dbo.udf_fn_GetCleanProg(P.ProgramID) ProgramName
	,CASE WHEN P.Site_ID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
		WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName END ReportingEntity
	,COUNT(DISTINCT
				CASE 
					WHEN P.SmokingIntake <= @rEndDate
						AND ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rStartDate AND @rEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rEndDate 
					THEN P.CLID
				END) Smoking_intake_yes_curr
	,COUNT(DISTINCT
				CASE 
					WHEN P.SmokingIntakeData <= @rEndDate
						AND P.SmokingPreg36Data BETWEEN @rStartDate AND @rEndDate
						AND ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rStartDate AND @rEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rEndDate 
					THEN P.CLID
				END) Smoking_total_curr
	,COUNT(DISTINCT
				CASE 
					WHEN P.SmokingPreg36 <= @rEndDate
						AND ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rStartDate AND @rEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rEndDate 
					THEN P.CLID
				END) Smoking_36w_yes_curr
	,COUNT(DISTINCT
				CASE 
					WHEN P.SmokingIntakeMissing <= @rEndDate
						AND P.SmokingPreg36Data BETWEEN @rStartDate AND @rEndDate
						AND ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rStartDate AND @rEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rEndDate 
					THEN P.CLID
				END) Smoking_intake_missing_curr
	,COUNT(DISTINCT
				CASE 
					WHEN  P.SmokingIntakeData <= @rEndDate
						AND P.SmokingPreg36Missing BETWEEN @rStartDate AND @rEndDate
						AND ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rStartDate AND @rEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rEndDate 
					THEN P.CLID
				END) Smoking_36w_missing_curr
	,COUNT(DISTINCT
				CASE 
					WHEN P.SmokingIntakeMissing <= @rEndDate
						AND P.SmokingPreg36Missing BETWEEN @rStartDate AND @rEndDate
						AND ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rStartDate AND @rEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rEndDate 
					THEN P.CLID
				END) Smoking_both_missing_curr
	,COUNT(DISTINCT
				CASE 
					WHEN ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rStartDate AND @rEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rEndDate 
					THEN P.CLID
				END) Smoking_miss_total_curr
				
	,COUNT(DISTINCT
				CASE 
					WHEN P.SmokingPreg36Form BETWEEN @rStartDate AND @rEndDate AND P.SmokingIntakeForm <= @rEndDate 
					THEN P.CLID
				END) SurveyTotal
				
	,COUNT(DISTINCT
				CASE 
					WHEN P.SmokingIntake <= @rCompEndDate
						AND ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rCompStartDate AND @rCompEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rCompEndDate 
					THEN P.CLID
				END) Smoking_intake_yes_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.SmokingIntakeData <= @rCompEndDate
						AND P.SmokingPreg36Data BETWEEN @rCompStartDate AND @rCompEndDate
						AND ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rCompStartDate AND @rCompEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rCompEndDate 
					THEN P.CLID
				END) Smoking_total_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.SmokingPreg36 <= @rCompEndDate
						AND ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rCompStartDate AND @rCompEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rCompEndDate 
					THEN P.CLID
				END) Smoking_36w_yes_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.SmokingIntakeMissing <= @rCompEndDate
						AND P.SmokingPreg36Data BETWEEN @rCompStartDate AND @rCompEndDate
						AND ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rCompStartDate AND @rCompEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rCompEndDate 
					THEN P.CLID
				END) Smoking_intake_missing_comp
	,COUNT(DISTINCT
				CASE 
					WHEN  P.SmokingIntakeData <= @rCompEndDate
						AND P.SmokingPreg36Missing BETWEEN @rCompStartDate AND @rCompEndDate
						AND ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rCompStartDate AND @rCompEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rCompEndDate 
					THEN P.CLID
				END) Smoking_36w_missing_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.SmokingIntakeMissing <= @rCompEndDate
						AND P.SmokingPreg36Missing BETWEEN @rCompStartDate AND @rCompEndDate
						AND ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rCompStartDate AND @rCompEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rCompEndDate 
					THEN P.CLID
				END) Smoking_both_missing_comp
	,COUNT(DISTINCT
				CASE 
					WHEN ISNULL(P.SmokingPreg36Data,P.SmokingPreg36Missing) BETWEEN @rCompStartDate AND @rCompEndDate AND ISNULL(P.SmokingIntakeData,P.SmokingIntakeMissing) <= @rCompEndDate 
					THEN P.CLID
				END) Smoking_miss_total_comp
	,COUNT(DISTINCT
				CASE 
					WHEN P.SmokingPreg36Form BETWEEN @rCompStartDate AND @rCompEndDate AND P.SmokingIntakeForm <= @rCompEndDate 
					THEN P.CLID
				END) SurveyTotal_comp
	,P.CLID

FROM 

UV_Fidelity_CLID P

WHERE CASE
		WHEN @ReportType = 1 THEN 1
		WHEN @ReportType = 2 THEN P.StateID
		WHEN @ReportType = 3 THEN P.Site_ID
		WHEN @ReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))

GROUP BY 
	P.Site_ID
	,dbo.udf_StateVSTribal(P.Abbreviation,P.Site_ID) 
	,P.[US State]
	,P.StateID
	,P.AGENCY_INFO_0_NAME
	,P.ProgramID
	,P.CLID
	
END
GO
