USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Element_4r]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Fid_Element_4r]
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
--SET @StartDate		 = CAST('1/1/2014' AS DATE)
--SET @EndDate		 = DATEADD(D,-1,DATEADD(YEAR,1,@StartDate))
--SET @CompStartDate	 = CAST('1/1/2013' AS DATE)
--SET @CompEndDate	 = DATEADD(D,-1,DATEADD(YEAR,1,@CompStartDate))
--SET @ParentEntity	 = 150
--SET @REName			 = NULL
--SET @ReportType		 = 3
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


SELECT
	dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
	,P.[US State]
	,P.StateID
	,P.SiteID Site_ID
	,P.AGENCY_INFO_0_NAME
	,P.ProgramID
	,dbo.udf_fn_GetCleanProg(P.ProgramID) ProgramName
	,CASE WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
		WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName END ReportingEntity
	
		,COUNT(DISTINCT 
				CASE WHEN RN.SurveyDate BETWEEN @StartDate AND @EndDate
						AND EAD.EndDate IS NOT NULL
					 THEN EAD.CLID END) Total_Referrals_curr
		,COUNT(DISTINCT 
				CASE WHEN RN.SurveyDate BETWEEN @StartDate AND @EndDate
						AND EAD.EndDate IS NOT NULL
						AND EAD.ReasonForDismissal = 'Unable to locate'
					 THEN EAD.CLID END) Referrals_not_loc_curr
		,COUNT(DISTINCT 
				CASE WHEN RN.SurveyDate BETWEEN @StartDate AND @EndDate
						AND EAD.EndDate IS NOT NULL
						AND EAD.ReasonForDismissal IN('Did not meet local criteria','Did not meet NFP criteria')
					 THEN EAD.CLID END) Referrals_not_meeting_prog_crit_curr
		,COUNT(DISTINCT 
				CASE WHEN RN.SurveyDate BETWEEN @StartDate AND @EndDate
						AND EAD.EndDate IS NOT NULL
						AND EAD.ReasonForDismissal IS NULL
					 THEN EAD.CLID END) Referrals_disp_missing_curr
		,COUNT(DISTINCT 
				CASE WHEN RN.SurveyDate BETWEEN @StartDate AND @EndDate
						AND EAD.EndDate IS NOT NULL
						AND EAD.ReasonForDismissal NOT IN('Did not meet local criteria','Did not meet NFP criteria')
					 THEN EAD.CLID END) Eligible_referrals_curr
		,COUNT(DISTINCT 
				CASE WHEN RN.SurveyDate BETWEEN @StartDate AND @EndDate
						AND EAD.EndDate IS NOT NULL
						AND EAD.ReasonForDismissal NOT IN('Did not meet local criteria','Did not meet NFP criteria')
						AND EAD.ReasonForDismissal = 'Program full'
					 THEN EAD.CLID END) Eligible_referrals_not_en_full_curr
		,COUNT(DISTINCT 
				CASE WHEN RN.SurveyDate BETWEEN @StartDate AND @EndDate
						AND EAD.EndDate IS NOT NULL
						AND EAD.ReasonForDismissal NOT IN('Did not meet local criteria','Did not meet NFP criteria')
						AND EAD.ReasonForDismissal = 'Refused participation'
					 THEN EAD.CLID END) Eligible_referrals_not_en_refus_curr
		,COUNT(DISTINCT 
				CASE WHEN RN.SurveyDate BETWEEN @StartDate AND @EndDate
						AND EAD.EndDate IS NOT NULL
						AND EAD.ReasonForDismissal NOT IN('Did not meet local criteria','Did not meet NFP criteria')
						AND EAD.ReasonForDismissal NOT IN('Program full','Did not meet local criteria','Did not meet NFP criteria')
					 THEN EAD.CLID END) Eligible_referrals_not_en_had_space_curr
		,COUNT(DISTINCT 
				CASE WHEN RN.SurveyDate BETWEEN @StartDate AND @EndDate
						AND EAD.EndDate IS NOT NULL
						AND EAD.ReasonForDismissal NOT IN('Did not meet local criteria','Did not meet NFP criteria')
						AND EAD.ReasonForDismissal = 'Enrolled in NFP'
					 THEN EAD.CLID END) Eligible_referrals_enrolled_curr

----------------------- Comp phase ------------------------
					 
		,COUNT(DISTINCT 
				CASE WHEN RN.SurveyDate BETWEEN @CompStartDate AND @CompEndDate
						AND EAD.EndDate IS NOT NULL
					 THEN EAD.CLID END) Total_Referrals_comp
		,COUNT(DISTINCT 
				CASE WHEN RN.SurveyDate BETWEEN @CompStartDate AND @CompEndDate
						AND EAD.EndDate IS NOT NULL
						AND EAD.ReasonForDismissal = 'Unable to locate'
					 THEN EAD.CLID END) Referrals_not_loc_comp
		,COUNT(DISTINCT 
				CASE WHEN RN.SurveyDate BETWEEN @CompStartDate AND @CompEndDate
						AND EAD.EndDate IS NOT NULL
						AND EAD.ReasonForDismissal IN('Did not meet local criteria','Did not meet NFP criteria')
					 THEN EAD.CLID END) Referrals_not_meeting_prog_crit_comp
		,COUNT(DISTINCT 
				CASE WHEN RN.SurveyDate BETWEEN @CompStartDate AND @CompEndDate
						AND EAD.EndDate IS NOT NULL
						AND EAD.ReasonForDismissal IS NULL
					 THEN EAD.CLID END) Referrals_disp_missing_comp
		,COUNT(DISTINCT 
				CASE WHEN RN.SurveyDate BETWEEN @CompStartDate AND @CompEndDate
						AND EAD.EndDate IS NOT NULL
						AND EAD.ReasonForDismissal NOT IN('Did not meet local criteria','Did not meet NFP criteria')
					 THEN EAD.CLID END) Eligible_referrals_comp
		,COUNT(DISTINCT 
				CASE WHEN RN.SurveyDate BETWEEN @CompStartDate AND @CompEndDate
						AND EAD.EndDate IS NOT NULL
						AND EAD.ReasonForDismissal NOT IN('Did not meet local criteria','Did not meet NFP criteria')
						AND EAD.ReasonForDismissal = 'Program full'
					 THEN EAD.CLID END) Eligible_referrals_not_en_full_comp
		,COUNT(DISTINCT 
				CASE WHEN RN.SurveyDate BETWEEN @CompStartDate AND @CompEndDate
						AND EAD.EndDate IS NOT NULL
						AND EAD.ReasonForDismissal NOT IN('Did not meet local criteria','Did not meet NFP criteria')
						AND EAD.ReasonForDismissal = 'Refused participation'
					 THEN EAD.CLID END) Eligible_referrals_not_en_refus_comp
		,COUNT(DISTINCT 
				CASE WHEN RN.SurveyDate BETWEEN @CompStartDate AND @CompEndDate
						AND EAD.EndDate IS NOT NULL
						AND EAD.ReasonForDismissal NOT IN('Did not meet local criteria','Did not meet NFP criteria')
						AND EAD.ReasonForDismissal NOT IN('Program full','Did not meet local criteria','Did not meet NFP criteria')
					 THEN EAD.CLID END) Eligible_referrals_not_en_had_space_comp
		,COUNT(DISTINCT 
				CASE WHEN RN.SurveyDate BETWEEN @StartDate AND @EndDate
						AND EAD.EndDate IS NOT NULL
						AND EAD.ReasonForDismissal NOT IN('Did not meet local criteria','Did not meet NFP criteria')
						AND EAD.ReasonForDismissal = 'Enrolled in NFP'
					 THEN EAD.CLID END) Eligible_referrals_enrolled_comp


FROM Referrals_to_NFP_Survey RN
JOIN EnrollmentAndDismissal EAD 
	ON RN.ProgramID = EAD.ProgramID AND RN.CL_EN_GEN_ID = EAD.CLID
JOIN UV_PAS P ON EAD.ProgramID = P.Program_ID_Referrals

WHERE CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN P.StateID
		WHEN @rReportType = 3 THEN P.SiteID
		WHEN @rReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))
	 --AND AC.RankingLatest = 1
	  	
GROUP BY
	P.SiteID
	,dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) 
	,P.[US State]
	,P.StateID
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
	,CASE WHEN P.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
		WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName END ReportingEntity
	,0,0,0,0,0,0,0,0,0 ,0,0,0,0,0,0,0,0,0
      
FROM UV_PAS P
WHERE CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN P.StateID
		WHEN @rReportType = 3 THEN P.SiteID
		WHEN @rReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))
		
		
GO
