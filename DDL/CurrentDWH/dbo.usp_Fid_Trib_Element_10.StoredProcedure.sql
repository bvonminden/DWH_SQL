USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Trib_Element_10]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Fid_Trib_Element_10]
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
	--@StartDate		Date 
	--,@EndDate		Date 
	--,@CompStartDate	Date 
	--,@CompEndDate	Date 
	--,@ParentEntity Varchar(4000)
	--,@REName VARCHAR(50) 
	--,@ReportType VARCHAR(50) 
	--,@Data INT
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
SET @rREName			 = @REName
SET @rReportType		 = @ReportType
SET @rTribal_PM		 = @Tribal_PM
SET @rData			 = @Data;


IF @rData = 0
BEGIN


SELECT 
	dbo.udf_StateVSTribal(HVES.Abbreviation,HVES.Site_ID) [State]
	,HVES.[US State]
	,HVES.StateID
	,HVES.Site_ID [Site_ID]
	,HVES.AGENCY_INFO_0_NAME
	,HVES.ProgramID
	,dbo.udf_fn_GetCleanProg(HVES.ProgramID) ProgramName
	,CASE WHEN HVES.Site_ID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
		WHEN HVES.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName END ReportingEntity
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Pregnancy'
				AND HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate
			THEN HVES.CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT
		 END),0) PhaseSumPreg_ENV
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Pregnancy'
				AND HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate
			THEN HVES.CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT
		 END),0) PhaseSumPregComp_ENV
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Pregnancy'
				AND HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate
			THEN HVES.CLIENT_DOMAIN_0_MATERNAL_VISIT
		 END),0) PhaseSumPreg_MAT
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Pregnancy'
				AND HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate
			THEN HVES.CLIENT_DOMAIN_0_MATERNAL_VISIT
		 END),0) PhaseSumPregComp_MAT
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Pregnancy'
				AND HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate
			THEN HVES.CLIENT_DOMAIN_0_PERSHLTH_VISIT
		 END),0) PhaseSumPreg_PERS
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Pregnancy'
				AND HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate
			THEN HVES.CLIENT_DOMAIN_0_PERSHLTH_VISIT
		 END),0) PhaseSumPregComp_PERS
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Pregnancy'
				AND HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate
			THEN HVES.CLIENT_DOMAIN_0_LIFECOURSE_VISIT
		 END),0) PhaseSumPreg_LIFE
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Pregnancy'
				AND HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate
			THEN HVES.CLIENT_DOMAIN_0_LIFECOURSE_VISIT
		 END),0) PhaseSumPregComp_LIFE
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Pregnancy'
				AND HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate
			THEN HVES.CLIENT_DOMAIN_0_FRNDFAM_VISIT
		 END),0) PhaseSumPreg_FAM
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Pregnancy'
				AND HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate
			THEN HVES.CLIENT_DOMAIN_0_FRNDFAM_VISIT
		 END),0) PhaseSumPregComp_FAM

	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Infancy'
				AND HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate
			THEN HVES.CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT
		 END),0) PhaseSumInf_ENV
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Infancy'
				AND HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate
			THEN HVES.CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT
		 END),0) PhaseSumInfComp_ENV
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Infancy'
				AND HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate
			THEN HVES.CLIENT_DOMAIN_0_MATERNAL_VISIT
		 END),0) PhaseSumInf_MAT
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Infancy'
				AND HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate
			THEN HVES.CLIENT_DOMAIN_0_MATERNAL_VISIT
		 END),0) PhaseSumInfComp_MAT
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Infancy'
				AND HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate
			THEN HVES.CLIENT_DOMAIN_0_PERSHLTH_VISIT
		 END),0) PhaseSumInf_PERS
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Infancy'
				AND HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate
			THEN HVES.CLIENT_DOMAIN_0_PERSHLTH_VISIT
		 END),0) PhaseSumInfComp_PERS
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Infancy'
				AND HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate
			THEN HVES.CLIENT_DOMAIN_0_LIFECOURSE_VISIT
		 END),0) PhaseSumInf_LIFE
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Infancy'
				AND HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate
			THEN HVES.CLIENT_DOMAIN_0_LIFECOURSE_VISIT
		 END),0) PhaseSumInfComp_LIFE
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Infancy'
				AND HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate
			THEN HVES.CLIENT_DOMAIN_0_FRNDFAM_VISIT
		 END),0) PhaseSumInf_FAM
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Infancy'
				AND HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate
			THEN HVES.CLIENT_DOMAIN_0_FRNDFAM_VISIT
		 END),0) PhaseSumInfComp_FAM

	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Toddler'
				AND HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate
			THEN HVES.CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT
		 END),0) PhaseSumTodd_ENV
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Toddler'
				AND HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate
			THEN HVES.CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT
		 END),0) PhaseSumToddComp_ENV
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Toddler'
				AND HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate
			THEN HVES.CLIENT_DOMAIN_0_MATERNAL_VISIT
		 END),0) PhaseSumTodd_MAT
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Toddler'
				AND HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate
			THEN HVES.CLIENT_DOMAIN_0_MATERNAL_VISIT
		 END),0) PhaseSumToddComp_MAT
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Toddler'
				AND HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate
			THEN HVES.CLIENT_DOMAIN_0_PERSHLTH_VISIT
		 END),0) PhaseSumTodd_PERS
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Toddler'
				AND HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate
			THEN HVES.CLIENT_DOMAIN_0_PERSHLTH_VISIT
		 END),0) PhaseSumToddComp_PERS
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Toddler'
				AND HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate
			THEN HVES.CLIENT_DOMAIN_0_LIFECOURSE_VISIT
		 END),0) PhaseSumTodd_LIFE
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Toddler'
				AND HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate
			THEN HVES.CLIENT_DOMAIN_0_LIFECOURSE_VISIT
		 END),0) PhaseSumToddComp_LIFE
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Toddler'
				AND HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate
			THEN HVES.CLIENT_DOMAIN_0_FRNDFAM_VISIT
		 END),0) PhaseSumTodd_FAM
	,ISNULL(SUM(CASE
			WHEN HVES.[Visit Phase]  = 'Toddler'
				AND HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate
			THEN HVES.CLIENT_DOMAIN_0_FRNDFAM_VISIT
		 END),0) PhaseSumToddComp_FAM

	,COUNT(DISTINCT
			CASE
				WHEN HVES.[Visit Phase]  = 'Pregnancy'
					AND HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate
				THEN HVES.SurveyResponseID
			END) VisitperPhaseTotalPreg
	,COUNT(DISTINCT
			CASE
				WHEN HVES.[Visit Phase]  = 'Pregnancy'
					AND HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate
				THEN HVES.SurveyResponseID
			END) VisitperPhaseTotalPregComp
	,COUNT(DISTINCT
			CASE
				WHEN HVES.[Visit Phase]  = 'Infancy'
					AND HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate
				THEN HVES.SurveyResponseID
			END) VisitperPhaseTotalInf
	,COUNT(DISTINCT
			CASE
				WHEN HVES.[Visit Phase]  = 'Infancy'
					AND HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate
				THEN HVES.SurveyResponseID
			END) VisitperPhaseTotalInfComp
	,COUNT(DISTINCT
			CASE
				WHEN HVES.[Visit Phase]  = 'Toddler'
					AND HVES.SurveyDate BETWEEN @rStartDate AND @rEndDate
				THEN HVES.SurveyResponseID
			END) VisitperPhaseTotalTodd
	,COUNT(DISTINCT
			CASE
				WHEN HVES.[Visit Phase]  = 'Toddler'
					AND HVES.SurveyDate BETWEEN @rCompStartDate AND @rCompEndDate
				THEN HVES.SurveyResponseID
			END) VisitperPhaseTotalToddComp
FROM DataWarehouse..UV_Fidelity_HVES HVES
		
WHERE CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN HVES.StateID
		WHEN @rReportType = 3 THEN HVES.SiteID
		WHEN @rReportType = 4 THEN HVES.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))

	  AND HVES.Tribal = 1
	  AND HVES.Tribal_PM IN( SELECT * FROM dbo.udf_ParseMultiParam(@rTribal_PM))

GROUP BY 
	HVES.Site_ID
	,dbo.udf_StateVSTribal(HVES.Abbreviation,HVES.Site_ID) 
	,HVES.[US State]
	,HVES.StateID
	,HVES.Site_ID
	,HVES.AGENCY_INFO_0_NAME
	,HVES.ProgramID
	
	
UNION

SELECT 
	dbo.udf_StateVSTribal(PAS.Abbreviation,PAS.SiteID) [State]
	,PAS.[US State]
	,PAS.StateID
	,PAS.SiteID [Site_ID]
	,PAS.AGENCY_INFO_0_NAME
	,PAS.ProgramID
	,dbo.udf_fn_GetCleanProg(PAS.ProgramID) ProgramName
	,CASE WHEN PAS.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @REName 
		WHEN PAS.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @REName END ReportingEntity
      ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
      
FROM DataWarehouse..UV_PAS PAS
WHERE CASE
		WHEN @ReportType = 1 THEN 1
		WHEN @ReportType = 2 THEN PAS.StateID
		WHEN @ReportType = 3 THEN PAS.SiteID
		WHEN @ReportType = 4 THEN PAS.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))


END

ELSE ------------------------- DATA Return ----------------------
BEGIN



SELECT 1
	

END

GO
