USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Trib_Element_9]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Fid_Trib_Element_9]
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
--	,@LastSymp INT
--	,@Data INT
--SET @StartDate		 = CAST('4/1/2012' AS DATE)
--SET @EndDate		 = DATEADD(D,-1,DATEADD(YEAR,1,@StartDate))
--SET @CompStartDate	 = CAST('4/1/2011' AS DATE)
--SET @CompEndDate	 = DATEADD(D,-1,DATEADD(YEAR,1,@CompStartDate))
--SET @ParentEntity	 = 1073
--SET @REName			 = NULL
--SET @LastSymp		 = 2012
--SET @ReportType		 = 4;
--SET @Data			 = 0

DECLARE 
	@rStartDate		Date 
	,@rEndDate		Date 
	,@rCompStartDate	Date 
	,@rCompEndDate	Date 
	,@rParentEntity Varchar(4000)
	,@rREName VARCHAR(50) 
	,@rReportType VARCHAR(50) 
	,@rData INT
	,@LastSymp	INT
	,@LastSymp_Comp	INT
SET @rStartDate		 = @StartDate
SET @rEndDate		 = @EndDate
SET @rCompStartDate	 = @CompStartDate
SET @rCompEndDate	 = @CompEndDate
SET @rParentEntity	 = @ParentEntity
SET @rREName		 = @REName
SET @rReportType	 = @ReportType
SET @rData			 = @Data;

SET @LastSymp = 
	(SELECT 
	--	YEAR(MAX(CCS.Completion_Date)) ANNUAL_DT
	--FROM DW_Completed_Courses CCS
	--	LEFT OUTER JOIN Education_Courses EC
	--	INNER JOIN Education_Detail ED
	--	ON EC.Course_ID = ED.Course_ID
	--	ON (CCS.LMS_Comments = ED.[Course Description] OR CCS.LMS_LongName = ED.[Course Description])
	--WHERE ED.Course_ID = 1
	--	AND CCS.Completion_Date < 
	YEAR(MAX(ED.[Completion_Date])) ANNUAL_DT
	FROM  DataWarehouse.dbo.UV_Ed_CourseCompleted ED
	WHERE ED.Course_ID = 1
		AND ED.Completion_Date <= @rEndDate)

SET @LastSymp_Comp = 
	(SELECT 
	--	YEAR(MAX(CCS.Completion_Date)) ANNUAL_DT
	--FROM DW_Completed_Courses CCS
	--	LEFT OUTER JOIN Education_Courses EC
	--	INNER JOIN Education_Detail ED
	--	ON EC.Course_ID = ED.Course_ID
	--	ON (CCS.LMS_Comments = ED.[Course Description] OR CCS.LMS_LongName = ED.[Course Description])
	--WHERE ED.Course_ID = 1
	--	AND CCS.Completion_Date < 
	YEAR(MAX(ED.[Completion_Date])) ANNUAL_DT
	FROM  DataWarehouse.dbo.UV_Ed_CourseCompleted ED
	WHERE ED.Course_ID = 1
		AND ED.Completion_Date <= @rCompEndDate)

SELECT 
	ROOT.Entity_Id
	,dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
	,P.[US State]
	,P.StateID
	,P.SiteID [Site_ID]
	,P.AGENCY_INFO_0_NAME
	,P.ProgramID
	,dbo.udf_fn_GetCleanProg(P.ProgramID) ProgramName
	,CASE WHEN P.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
		WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName END ReportingEntity
		
	,MAX(
				CASE 
					WHEN a.UNIT_3_DT IS NOT NULL
						AND a.NHV_FTE IS NOT NULL
						AND a.NHV_FTE > 0
						AND a.NS_FTE IS NULL
					THEN  a.Entity_Id
				END) NHVeduCompleteCount
	,MAX(
				CASE 
					WHEN a.NHV_FTE IS NOT NULL
						AND a.NHV_FTE > 0
						AND a.NS_FTE IS NULL
					THEN  a.Entity_Id
				END) NHVeduTotal
	--NHVeduCompletePercent =   NHVeduCompletePercent/NHVeduTotal
	,MAX(
				CASE 
					WHEN a.UNIT_3_DT IS NULL
						AND a.NHV_MONTHs >9
						AND a.NHV_FTE IS NOT NULL
						AND a.NHV_FTE > 0
						AND a.NS_FTE IS NULL
					THEN  a.Entity_Id
				END) NHVeduEligibleCount
	-- NHVeduEligiblePercent = NHVeduEligiblePercent/NHVeduTotal
	,MAX(
				CASE 
					WHEN a.UNIT_3_DT IS NULL
						AND a.NHV_MONTHs <= 9
						AND a.NHV_FTE IS NOT NULL
						AND a.NHV_FTE > 0
						AND a.NS_FTE IS NULL
					THEN  a.Entity_Id
				END) NHVeduPotentialCount
	--NHVeduPotentialPercent = NHVeduPotentialPercent/NHVeduTotal
	,MAX(
				CASE 
					WHEN a.UNIT_4_DT IS NOT NULL
						AND a.NS_FTE IS NOT NULL
						AND a.NS_FTE > 0
					THEN  a.Entity_Id
				END) NSeduCompleteCount
	,MAX(
				CASE 
					WHEN a.NS_FTE IS NOT NULL
						AND a.NS_FTE > 0
					THEN  a.Entity_Id
				END) NSeduTotal
	--NSeduCompletePercent =  NSeduCompletePercent/NSeduTotal
	,MAX(
				CASE 
					WHEN a.UNIT_4_DT IS NULL
						AND a.NS_MONTHs > 7
						AND a.NS_FTE IS NOT NULL
						AND a.NS_FTE > 0
					THEN  a.Entity_Id
				END) NSeduEligibleCount
	--NSeduEligiblePercent = NSeduEligiblePercent/NSeduTotal
	,MAX(
				CASE 
					WHEN a.UNIT_4_DT IS NULL
						AND a.NS_MONTHs <= 7
						AND a.NS_FTE IS NOT NULL
						AND a.NS_FTE > 0
					THEN  a.Entity_Id
				END) NSeduPotentialCount
	--NSeduPotentialPercent = NSeduPotentialPercent/NSeduTotal
	,MAX(
				CASE 
					WHEN YEAR(a.ANNUAL_DT) = @LastSymp
						AND a.NS_FTE IS NOT NULL
						AND a.NS_FTE > 0
					THEN  a.Entity_Id
				END) NSeduAnnualCount
	--NSeduAnnualPercent = NSeduAnnualPercent/NSeduTotal
	,MAX(
				CASE 
					WHEN ((a.UNIT_4_DT BETWEEN CAST('5/31/'+CAST(@LastSymp-1 AS VARCHAR) AS DATE)
							AND CAST('5/31/'+CAST(@LastSymp AS VARCHAR) AS DATE))
						OR YEAR(a.UNIT_4_DT) = YEAR(@LastSymp))
						AND (YEAR(a.ANNUAL_DT) <> @LastSymp OR a.ANNUAL_DT IS NULL)
						AND a.UNIT_4_DT IS NOT NULL
						AND a.NS_FTE IS NOT NULL
						AND a.NS_FTE > 0
					THEN  a.Entity_Id
				END) NSeduNotEligibleCount
	,MAX(
				CASE 
					WHEN (a.UNIT_4_DT NOT BETWEEN CAST('5/31/'+CAST(@LastSymp-1 AS VARCHAR) AS DATE)
							AND CAST('5/31/'+CAST(@LastSymp AS VARCHAR) AS DATE) OR a.UNIT_4_DT IS NULL)
						AND (YEAR(a.ANNUAL_DT) <> @LastSymp OR a.ANNUAL_DT IS NULL)
						AND a.NS_FTE IS NOT NULL
						AND a.NS_FTE > 0
					THEN a.Entity_Id
				END) NSeduAnnualMissing
				
				
	,MAX(
				CASE 
					WHEN b.UNIT_3_DT IS NOT NULL
						AND b.NHV_FTE IS NOT NULL
						AND b.NHV_FTE > 0
						AND b.NS_FTE IS NULL
					THEN  b.Entity_Id
				END) NHVeduCompleteCount_comp
	,MAX(
				CASE 
					WHEN b.NHV_FTE IS NOT NULL
						AND b.NHV_FTE > 0
						AND b.NS_FTE IS NULL
					THEN  b.Entity_Id
				END) NHVeduTotal_comp
	--NHVeduCompletePercent =   NHVeduCompletePercent/NHVeduTotal
	,MAX(
				CASE 
					WHEN b.UNIT_3_DT IS NULL
						AND b.NHV_MONTHs >9
						AND b.NHV_FTE IS NOT NULL
						AND b.NHV_FTE > 0
						AND b.NS_FTE IS NULL
					THEN  b.Entity_Id
				END) NHVeduEligibleCount_comp
	-- NHVeduEligiblePercent = NHVeduEligiblePercent/NHVeduTotal
	,MAX(
				CASE 
					WHEN b.UNIT_3_DT IS NULL
						AND b.NHV_MONTHs <= 9
						AND b.NHV_FTE IS NOT NULL
						AND b.NHV_FTE > 0
						AND b.NS_FTE IS NULL
					THEN  b.Entity_Id
				END) NHVeduPotentialCount_comp
	--NHVeduPotentialPercent = NHVeduPotentialPercent/NHVeduTotal
	,MAX(
				CASE 
					WHEN b.UNIT_4_DT IS NOT NULL
						AND b.NS_FTE IS NOT NULL
						AND b.NS_FTE > 0
					THEN  b.Entity_Id
				END) NSeduCompleteCount_comp
	,MAX(
				CASE 
					WHEN b.NS_FTE IS NOT NULL
						AND b.NS_FTE > 0
					THEN  b.Entity_Id
				END) NSeduTotal_comp
	--NSeduCompletePercent =  NSeduCompletePercent/NSeduTotal
	,MAX(
				CASE 
					WHEN b.UNIT_4_DT IS NULL
						AND b.NS_MONTHs > 7
						AND b.NS_FTE IS NOT NULL
						AND b.NS_FTE > 0
					THEN  b.Entity_Id
				END) NSeduEligibleCount_comp
	--NSeduEligiblePercent = NSeduEligiblePercent/NSeduTotal
	,MAX(
				CASE 
					WHEN b.UNIT_4_DT IS NULL
						AND b.NS_MONTHs <= 7
						AND b.NS_FTE IS NOT NULL
						AND b.NS_FTE > 0
					THEN  b.Entity_Id
				END) NSeduPotentialCount_comp
	--NSeduPotentialPercent = NSeduPotentialPercent/NSeduTotal

	,MAX(
				CASE 
					WHEN YEAR(b.ANNUAL_DT) = @LastSymp_comp
						AND b.NS_FTE IS NOT NULL
						AND b.NS_FTE > 0
					THEN  b.Entity_Id
				END) NSeduAnnualCount_comp
	--NSeduAnnualPercent = NSeduAnnualPercent/NSeduTotal
	,MAX(
				CASE 
					WHEN ((b.UNIT_4_DT BETWEEN CAST('5/31/'+CAST(@LastSymp_comp-1 AS VARCHAR) AS DATE)
							AND CAST('5/31/'+CAST(@LastSymp_comp AS VARCHAR) AS DATE))
						OR YEAR(b.UNIT_4_DT) = YEAR(@LastSymp_comp))
						AND (YEAR(b.ANNUAL_DT) <> @LastSymp_comp OR b.ANNUAL_DT IS NULL)
						AND b.UNIT_4_DT IS NOT NULL
						AND b.NS_FTE IS NOT NULL
						AND b.NS_FTE > 0
					THEN  b.Entity_Id
				END) NSeduNotEligibleCount_comp
	,MAX(
				CASE 
					WHEN (b.UNIT_4_DT NOT BETWEEN CAST('5/31/'+CAST(@LastSymp_comp-1 AS VARCHAR) AS DATE)
							AND CAST('5/31/'+CAST(@LastSymp_comp AS VARCHAR) AS DATE) OR b.UNIT_4_DT IS NULL)
						AND (YEAR(b.ANNUAL_DT) <> @LastSymp_comp OR b.ANNUAL_DT IS NULL)
						AND b.NS_FTE IS NOT NULL
						AND b.NS_FTE > 0
					THEN b.Entity_Id
				END) NSeduAnnualMissing_comp

FROM  DataWarehouse.dbo.fn_FID_Staff_listv2(@rCompStartDate,@rEndDate) ROOT

INNER JOIN DataWarehouse..UV_PAS P
	ON ROOT.ProgramID IN (P.Program_ID_NHV,P.Program_ID_Referrals,P.Program_ID_Staff_Supervision)
	
LEFT OUTER JOIN
	(SELECT *
	FROM DataWarehouse.dbo.fn_Fidelity_Staff_El9 (@rStartDate,@rEndDate) S
	WHERE S.EndDate IS NULL OR S.EndDate > @rEndDate) a
	ON ROOT.ProgramID = a.ProgramID
		and a.Entity_Id = ROOT.Entity_Id

LEFT OUTER JOIN
	(SELECT *
	FROM DataWarehouse.dbo.fn_Fidelity_Staff_El9 (@rCompStartDate,@rCompEndDate) S
	WHERE S.EndDate IS NULL OR S.EndDate > @rCompEndDate) b
	ON ROOT.ProgramID = b.ProgramID
		and b.Entity_Id = ROOT.Entity_Id

WHERE CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN P.StateID
		WHEN @rReportType = 3 THEN P.SiteID
		WHEN @rReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))


GROUP BY 
	ROOT.Entity_Id
	,P.ProgramID
	,P.SiteID
	,dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) 
	,P.[US State]
	,P.StateID
	,P.AGENCY_INFO_0_NAME
	,CASE WHEN @ReportType <> 3 THEN NULL ELSE P.ProgramID END 
	,CASE WHEN @ReportType <> 3 THEN NULL ELSE dbo.udf_fn_GetCleanProg(P.ProgramID) END
	
	
--UNION

--SELECT 
--	dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
--	,P.[US State]
--	,P.StateID
--	,P.SiteID [Site_ID]
--	,P.AGENCY_INFO_0_NAME
--	,CASE WHEN @ReportType <> 3 THEN NULL ELSE P.ProgramID END ProgramID
--	,CASE WHEN @ReportType <> 3 THEN NULL ELSE dbo.udf_fn_GetCleanProg(P.ProgramID) END ProgramName
--	,CASE WHEN P.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
--		WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName END ReportingEntity
--    ,0,0,0,0,0,0,0,0,0,0 ,0,0,0,0,0,0,0,0,0,0,0,0
      
--FROM UV_PAS P
--WHERE CASE
--		WHEN @rReportType = 1 THEN 1
--		WHEN @rReportType = 2 THEN P.StateID
--		WHEN @rReportType = 3 THEN P.SiteID
--		WHEN @rReportType = 4 THEN P.ProgramID
--	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))

GO
