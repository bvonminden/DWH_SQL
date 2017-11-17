USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Trib_Element_7]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Fid_Trib_Element_7]
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
--	,@Tribal_PM	VARCHAR(10)
--	,@Data INT
--SET @StartDate		 = CAST('1/1/2014' AS DATE)
--SET @EndDate		 = DATEADD(D,-1,DATEADD(YEAR,1,@StartDate))
--SET @CompStartDate	 = CAST('1/1/2013' AS DATE)
--SET @CompEndDate	 = DATEADD(D,-1,DATEADD(YEAR,1,@CompStartDate))
--SET @ParentEntity	 = 14
--SET @REName			 = NULL
--SET @ReportType		 = 2
--SET @Tribal_PM		 = 1
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


--IF @Data = 0
--BEGIN
--WITH InfDOB AS
--(
--SELECT  
--	IB.CL_EN_GEN_ID
--	,IB.ProgramID
--	,MIN(IB.BD1) BD1
--	,MIN(IB.BD2) BD2
--	,MIN(IB.DOB) DOB
--	,MIN(IB.SurveyDate) MinSurvDate
--	,MAX(IB.SurveyDate) MaxSurvDate
--	,MIN(IB.SurveyRank) Ranking
--FROM 

--(
--	SELECT I.CL_EN_GEN_ID,I.ProgramID,I.INFANT_BIRTH_0_DOB DOB,1 [SurveyRank],I.SurveyDate,(DATEADD(YEAR,1,I.INFANT_BIRTH_0_DOB)) BD1
--	,(DATEADD(YEAR,2,I.INFANT_BIRTH_0_DOB)) BD2

--	FROM DataWarehouse..Infant_Birth_Survey I
--	UNION ALL
--	SELECT I.CL_EN_GEN_ID,I.ProgramID,MIN(I.INFANT_BIRTH_0_DOB) DOB
--		,CASE 
--			WHEN DataWarehouse.dbo.fnGetFormName(I.SurveyID) LIKE '%6%' THEN 2
--			WHEN DataWarehouse.dbo.fnGetFormName(I.SurveyID) LIKE '%12%' THEN 2
--			WHEN DataWarehouse.dbo.fnGetFormName(I.SurveyID) LIKE '%18%' THEN 3
--			WHEN DataWarehouse.dbo.fnGetFormName(I.SurveyID) LIKE '%24%' THEN 3
--		 END [SurveyRank]
--		,MAX(I.SurveyDate) SurveyDate,MAX(DATEADD(YEAR,1,I.INFANT_BIRTH_0_DOB)) BD1
--	,MAX(DATEADD(YEAR,2,I.INFANT_BIRTH_0_DOB)) BD2

--	FROM DataWarehouse..Infant_Health_Survey I
--	GROUP BY I.CL_EN_GEN_ID,I.ProgramID,CASE 
--			WHEN DataWarehouse.dbo.fnGetFormName(I.SurveyID) LIKE '%6%' THEN 2
--			WHEN DataWarehouse.dbo.fnGetFormName(I.SurveyID) LIKE '%12%' THEN 2
--			WHEN DataWarehouse.dbo.fnGetFormName(I.SurveyID) LIKE '%18%' THEN 3
--			WHEN DataWarehouse.dbo.fnGetFormName(I.SurveyID) LIKE '%24%' THEN 3
--		 END
--) IB

--GROUP BY IB.CL_EN_GEN_ID,IB.ProgramID)

SELECT
	dbo.udf_StateVSTribal(AC.Abbreviation,AC.Site_ID) [State]
	,AC.[US State]
	,AC.StateID
	,AC.Site_ID
	,AC.AGENCY_INFO_0_NAME
	,AC.ProgramID
	,dbo.udf_fn_GetCleanProg(AC.ProgramID) ProgramName
	,CASE WHEN AC.Site_ID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
		WHEN AC.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName END ReportingEntity
		
		,COUNT(DISTINCT 
				CASE WHEN ISNULL(I.DOB,DATEADD(DAY,1,@rEndDate)) > @rStartDate
						AND AC.ProgramStartDate <= @rEndDate 
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@rEndDate)) >= @rStartDate
						AND ISNULL(I.DOB,DATEADD(DAY,1,@rEndDate)) > AC.ProgramStartDate
					 THEN AC.CLID END) Preg_served_curr
		,COUNT(DISTINCT 
				CASE WHEN ISNULL(I.DOB,DATEADD(DAY,1,@rEndDate)) > @rStartDate
						AND AC.ProgramStartDate <= @rEndDate 
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@rEndDate)) >= @rStartDate
						AND ISNULL(AC.EndDate,@rEndDate) > = I.DOB
						AND I.DOB BETWEEN @rStartDate AND @rEndDate
						AND ISNULL(I.DOB,DATEADD(DAY,1,@rEndDate)) > AC.ProgramStartDate
					 THEN AC.CLID END) Preg_completed_curr
		,COUNT(DISTINCT 
				CASE WHEN ISNULL(I.DOB,DATEADD(DAY,1,@rEndDate)) > @rStartDate
						AND AC.ProgramStartDate <= @rEndDate 
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@rEndDate)) >= @rStartDate
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@rEndDate)) > @rEndDate
						AND (I.DOB > @rEndDate OR I.DOB IS NULL)
						AND ISNULL(I.DOB,DATEADD(DAY,1,@rEndDate)) > AC.ProgramStartDate
					 THEN AC.CLID END) Preg_still_active_curr
		,COUNT(DISTINCT 
				CASE WHEN ISNULL(I.DOB,DATEADD(DAY,1,@rEndDate)) > @rStartDate
						AND AC.ProgramStartDate <= @rEndDate 
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@rEndDate)) >= @rStartDate
						AND AC.EndDate BETWEEN @rStartDate AND @rEndDate
						AND (AC.EndDate < I.DOB OR I.DOB IS NULL)
						AND ISNULL(I.DOB,DATEADD(DAY,1,@rEndDate)) > AC.ProgramStartDate
					 THEN AC.CLID END) Preg_leftprog_curr
		,COUNT(DISTINCT 
				CASE WHEN ISNULL(I.DOB,DATEADD(DAY,1,@rEndDate)) > @rEndDate
						AND AC.ProgramStartDate <= @rEndDate 
						--AND ISNULL(AC.EndDate,DATEADD(DAY,1,@rEndDate)) >= @rStartDate
						AND AC.EndDate <= @rEndDate
						AND AC.GestAge_EDD BETWEEN @rStartDate AND @rEndDate
						AND (AC.EndDate < I.DOB OR I.DOB IS NULL)
						AND ISNULL(I.DOB,DATEADD(DAY,1,@rEndDate)) > AC.ProgramStartDate
					 THEN AC.CLID END) Preg_leftprogCHC_curr
		--- Preg_RetainedPercent calculated
		,COUNT(DISTINCT 
				CASE WHEN I.DOB <= @rEndDate
						AND I.BD1 > @rStartDate
						AND ISNULL(AC.EndDate,@rEndDate) > = I.DOB
						AND AC.ProgramStartDate <= @rEndDate AND ISNULL(AC.EndDate,@rEndDate) >= @rStartDate
					 THEN AC.CLID END) Inf_served_curr
		,COUNT(DISTINCT 
				CASE WHEN I.DOB <= @rEndDate
						AND I.BD1 > @rStartDate
						AND ISNULL(AC.EndDate,@rEndDate) > = I.DOB
						AND AC.ProgramStartDate <= @rEndDate AND ISNULL(AC.EndDate,@rEndDate) >= @rStartDate
						AND ISNULL(AC.EndDate,@rEndDate) > = I.BD1
						AND I.BD1 BETWEEN @rStartDate AND @rEndDate
					 THEN AC.CLID END) Inf_completed_curr
		,COUNT(DISTINCT 
				CASE WHEN I.DOB <= @rEndDate
						AND I.BD1 > @rStartDate
						AND ISNULL(AC.EndDate,@rEndDate) > = I.DOB
						AND AC.ProgramStartDate <= @rEndDate AND ISNULL(AC.EndDate,@rEndDate) >= @rStartDate
						AND I.BD1 > @rEndDate
						AND I.DOB IS NOT NULL
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@rEndDate))> @rEndDate
					 THEN AC.CLID END) Inf_still_active_curr
					 
		,COUNT(DISTINCT 
				CASE WHEN I.DOB <= @rEndDate
						AND I.BD1 > @rStartDate
						AND ISNULL(AC.EndDate,@rEndDate) > = I.DOB
						AND AC.ProgramStartDate <= @rEndDate AND ISNULL(AC.EndDate,@rEndDate) >= @rStartDate
						AND AC.EndDate < I.BD1
						AND AC.EndDate BETWEEN @rStartDate AND @rEndDate
						--AND I.BD1 > @rEndDate
					 THEN AC.CLID END) Inf_leftprog_curr
		,COUNT(DISTINCT 
				CASE WHEN I.DOB <= @rEndDate
						AND I.BD1 > @rStartDate
						AND ISNULL(AC.EndDate,@rEndDate) > = I.DOB
						AND AC.ProgramStartDate <= @rEndDate --AND ISNULL(AC.EndDate,@rEndDate) >= @rStartDate
						AND AC.EndDate < I.BD1
						AND I.BD1 BETWEEN @rStartDate AND @rEndDate
						AND AC.EndDate BETWEEN I.DOB AND @rEndDate
						--AND I.BD1 > @rEndDate
					 THEN AC.CLID END) Inf_leftprogCHC_curr
		--- Inf_RetainedPercent calcualted
		,COUNT(DISTINCT 
				CASE WHEN I.BD1 <= @rEndDate
						AND I.BD2 > @rStartDate
						AND ISNULL(AC.EndDate,@rEndDate) > = I.BD1
						AND AC.ProgramStartDate <= @rEndDate AND ISNULL(AC.EndDate,@rEndDate) >= @rStartDate
					 THEN AC.CLID END) Tod_served_curr
		,COUNT(DISTINCT 
				CASE WHEN I.BD1 <= @rEndDate
						AND I.BD2 > @rStartDate
						AND ISNULL(AC.EndDate,@rEndDate) > = I.BD1
						AND AC.ProgramStartDate <= @rEndDate AND ISNULL(AC.EndDate,@rEndDate) >= @rStartDate
						AND AC.ReasonForDismissal = 'Child reached 2nd birthday'
						AND AC.EndDate BETWEEN @rStartDate AND @rEndDate
					 THEN AC.CLID END) Tod_completed_curr
		,COUNT(DISTINCT 
				CASE WHEN I.BD1 <= @rEndDate
						AND I.BD2 > @rStartDate
						AND ISNULL(AC.EndDate,@rEndDate) > = I.BD1
						AND AC.ProgramStartDate <= @rEndDate AND ISNULL(AC.EndDate,@rEndDate) >= @rStartDate
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@rEndDate)) > @rEndDate
					 THEN AC.CLID END) Tod_still_active_curr
		,COUNT(DISTINCT 
				CASE WHEN I.BD1 <= @rEndDate
						AND I.BD2 > @rStartDate
						AND ISNULL(AC.EndDate,@rEndDate) > = I.BD1
						AND AC.ProgramStartDate <= @rEndDate AND ISNULL(AC.EndDate,@rEndDate) >= @rStartDate
						AND AC.ReasonForDismissal <> 'Child reached 2nd birthday'
						AND AC.EndDate BETWEEN @rStartDate AND @rEndDate
					 THEN AC.CLID END) Tod_leftprog_curr
		,COUNT(DISTINCT 
				CASE WHEN I.BD1 <= @rEndDate
						AND AC.EndDate BETWEEN I.BD1 AND DATEADD(DAY,-1,I.BD2)
						AND AC.ProgramStartDate <= @rEndDate --AND ISNULL(AC.EndDate,@rEndDate) >= @rStartDate
						AND ISNULL(AC.ReasonForDismissal,'') <> 'Child reached 2nd birthday'
						AND I.BD2 BETWEEN @rStartDate AND @rEndDate
					 THEN AC.CLID END) Tod_leftprogCHC_curr
		,COUNT(DISTINCT
				CASE WHEN ISNULL(I.BD2, (DATEADD(YEAR,2,AC.GestAge_EDD))) BETWEEN @rStartDate AND @rEndDate	
						AND AC.EndDate < ISNULL(I.BD2, (DATEADD(YEAR,2,AC.GestAge_EDD)))						
						AND AC.ReasonForDismissal <> 'Child reached 2nd birthday'	
						AND AC.ProgramStartDate <= @rEndDate						
					 THEN AC.CLID END) ToddlerSecondBD_curr		
		,COUNT(DISTINCT
				CASE WHEN AC.EndDate BETWEEN @rStartDate AND @rEndDate
						AND AC.ReasonForDismissal = 'Child reached 2nd birthday'
					 THEN AC.CLID END) ToddlerGraduated_curr

		--- Tod_RetainedPercent calcualted
		,COUNT(DISTINCT 
				CASE WHEN ISNULL(AC.EndDate,@rEndDate) > @rStartDate 
						AND AC.ProgramStartDate <= @rEndDate AND ISNULL(AC.EndDate,@rEndDate) >= @rStartDate
					 THEN AC.CLID END) Total_served_curr
		,COUNT(DISTINCT 
				CASE WHEN ISNULL(AC.EndDate,@rEndDate) > @rStartDate 
						AND AC.ProgramStartDate <= @rEndDate AND ISNULL(AC.EndDate,@rEndDate) >= @rStartDate
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@rEndDate)) > @rEndDate
					 THEN AC.CLID END) Total_still_active_curr
		,COUNT(DISTINCT 
				CASE WHEN ISNULL(AC.EndDate,@rEndDate) > @rStartDate 
						AND AC.ProgramStartDate <= @rEndDate AND ISNULL(AC.EndDate,@rEndDate) >= @rStartDate
						AND AC.ReasonForDismissal = 'Child reached 2nd birthday'
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@rEndDate)) BETWEEN @rStartDate AND @rEndDate   
					 THEN AC.CLID END) Total_graduated_curr
		,COUNT(DISTINCT 
				CASE WHEN ISNULL(AC.EndDate,@rEndDate) > @rStartDate 
						AND AC.ProgramStartDate <= @rEndDate AND ISNULL(AC.EndDate,@rEndDate) >= @rStartDate
						AND AC.ReasonForDismissal <> 'Child reached 2nd birthday'
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@rEndDate)) BETWEEN @rStartDate AND @rEndDate
					 THEN AC.CLID END) Total_leftprog_curr
		--- Total_RetainedPercent calcualted
				
		,COUNT(DISTINCT
				CASE WHEN 
						(I.BD2 BETWEEN @rStartDate AND @rEndDate
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@rEndDate)) > I.BD2)
						OR
						(AC.ReasonForDismissal = 'Child reached 2nd birthday'
						AND AC.EndDate BETWEEN @rStartDate AND @rEndDate)
					 THEN AC.CLID END) ToddlerGradorAct_curr
		--,COUNT(DISTINCT
		--		CASE WHEN AC.EndDate BETWEEN @rStartDate AND @rEndDate
		--				AND AC.ReasonForDismissal <> 'Child reached 2nd birthday'
		--			 THEN AC.CLID END) Total_LeftProg_curr


		---- Comparative period
	,COUNT(DISTINCT 
				CASE WHEN ISNULL(IComp.DOB,DATEADD(DAY,1,@rCompEndDate)) > @rCompStartDate
						AND AC.ProgramStartDate <= @rCompEndDate 
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@rCompEndDate)) >= @rCompStartDate
						AND ISNULL(IComp.DOB,DATEADD(DAY,1,@rCompEndDate)) > AC.ProgramStartDate
					 THEN AC.CLID END) Preg_served_comp
		,COUNT(DISTINCT 
				CASE WHEN ISNULL(IComp.DOB,DATEADD(DAY,1,@rCompEndDate)) > @rCompStartDate
						AND AC.ProgramStartDate <= @rCompEndDate 
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@rCompEndDate)) >= @rCompStartDate
						AND ISNULL(AC.EndDate,@rCompEndDate) > = IComp.DOB
						AND IComp.DOB BETWEEN @rCompStartDate AND @rCompEndDate
						AND ISNULL(IComp.DOB,DATEADD(DAY,1,@rCompEndDate)) > AC.ProgramStartDate
					 THEN AC.CLID END) Preg_completed_comp
		,COUNT(DISTINCT 
				CASE WHEN ISNULL(IComp.DOB,DATEADD(DAY,1,@rCompEndDate)) > @rCompStartDate
						AND AC.ProgramStartDate <= @rCompEndDate 
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@rCompEndDate)) >= @rCompStartDate
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@rCompEndDate)) > @rCompEndDate
						AND (IComp.DOB > @rCompEndDate OR IComp.DOB IS NULL)
						AND ISNULL(IComp.DOB,DATEADD(DAY,1,@rCompEndDate)) > AC.ProgramStartDate
					 THEN AC.CLID END) Preg_still_active_comp
		,COUNT(DISTINCT 
				CASE WHEN ISNULL(IComp.DOB,DATEADD(DAY,1,@rCompEndDate)) > @rCompStartDate
						AND AC.ProgramStartDate <= @rCompEndDate 
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@rCompEndDate)) >= @rCompStartDate
						AND AC.EndDate BETWEEN @rCompStartDate AND @rCompEndDate
						AND (AC.EndDate < IComp.DOB OR IComp.DOB IS NULL)
						AND ISNULL(IComp.DOB,DATEADD(DAY,1,@rCompEndDate)) > AC.ProgramStartDate
					 THEN AC.CLID END) Preg_leftprog_comp
		,COUNT(DISTINCT 
				CASE WHEN ISNULL(IComp.DOB,DATEADD(DAY,1,@rCompEndDate)) > @rCompEndDate
						AND AC.ProgramStartDate <= @rCompEndDate 
						--AND ISNULL(AC.EndDate,DATEADD(DAY,1,@rCompEndDate)) >= @rCompStartDate
						AND AC.EndDate <= @rCompEndDate
						AND AC.GestAge_EDD BETWEEN @rCompStartDate AND @rCompEndDate
						AND (AC.EndDate < IComp.DOB OR IComp.DOB IS NULL)
						AND ISNULL(IComp.DOB,DATEADD(DAY,1,@rCompEndDate)) > AC.ProgramStartDate
					 THEN AC.CLID END) Preg_leftprogCHC_comp
		--- Preg_RetainedPercent calculated
		,COUNT(DISTINCT 
				CASE WHEN IComp.DOB <= @rCompEndDate
						AND IComp.BD1 > @rCompStartDate
						AND ISNULL(AC.EndDate,@rCompEndDate) > = IComp.DOB
						AND AC.ProgramStartDate <= @rCompEndDate AND ISNULL(AC.EndDate,@rCompEndDate) >= @rCompStartDate
					 THEN AC.CLID END) Inf_served_comp
		,COUNT(DISTINCT 
				CASE WHEN IComp.DOB <= @rCompEndDate
						AND IComp.BD1 > @rCompStartDate
						AND ISNULL(AC.EndDate,@rCompEndDate) > = IComp.DOB
						AND AC.ProgramStartDate <= @rCompEndDate AND ISNULL(AC.EndDate,@rCompEndDate) >= @rCompStartDate
						AND ISNULL(AC.EndDate,@rCompEndDate) > = IComp.BD1
						AND IComp.BD1 BETWEEN @rCompStartDate AND @rCompEndDate
					 THEN AC.CLID END) Inf_completed_comp
		,COUNT(DISTINCT 
				CASE WHEN IComp.DOB <= @rCompEndDate
						AND IComp.BD1 > @rCompStartDate
						AND ISNULL(AC.EndDate,@rCompEndDate) > = IComp.DOB
						AND AC.ProgramStartDate <= @rCompEndDate AND ISNULL(AC.EndDate,@rCompEndDate) >= @rCompStartDate
						AND IComp.BD1 > @rCompEndDate
						AND IComp.DOB IS NOT NULL
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@rCompEndDate))> @rCompEndDate
					 THEN AC.CLID END) Inf_still_active_comp
					 
		,COUNT(DISTINCT 
				CASE WHEN IComp.DOB <= @rCompEndDate
						AND IComp.BD1 > @rCompStartDate
						AND ISNULL(AC.EndDate,@rCompEndDate) > = IComp.DOB
						AND AC.ProgramStartDate <= @rCompEndDate AND ISNULL(AC.EndDate,@rCompEndDate) >= @rCompStartDate
						AND AC.EndDate < IComp.BD1
						AND AC.EndDate BETWEEN @rCompStartDate AND @rCompEndDate
						--AND IComp.BD1 > @rCompEndDate
					 THEN AC.CLID END) Inf_leftprog_comp
		,COUNT(DISTINCT 
				CASE WHEN IComp.DOB <= @rCompEndDate
						AND IComp.BD1 > @rCompStartDate
						AND ISNULL(AC.EndDate,@rCompEndDate) > = IComp.DOB
						AND AC.ProgramStartDate <= @rCompEndDate --AND ISNULL(AC.EndDate,@rCompEndDate) >= @rCompStartDate
						AND AC.EndDate < IComp.BD1
						AND IComp.BD1 BETWEEN @rCompStartDate AND @rCompEndDate
						AND AC.EndDate BETWEEN IComp.DOB AND @rCompEndDate
						--AND IComp.BD1 > @rCompEndDate
					 THEN AC.CLID END) Inf_leftprogCHC_comp
		--- Inf_RetainedPercent calcualted
		,COUNT(DISTINCT 
				CASE WHEN IComp.BD1 <= @rCompEndDate
						AND IComp.BD2 > @rCompStartDate
						AND ISNULL(AC.EndDate,@rCompEndDate) > = IComp.BD1
						AND AC.ProgramStartDate <= @rCompEndDate AND ISNULL(AC.EndDate,@rCompEndDate) >= @rCompStartDate
					 THEN AC.CLID END) Tod_served_comp
		,COUNT(DISTINCT 
				CASE WHEN IComp.BD1 <= @rCompEndDate
						AND IComp.BD2 > @rCompStartDate
						AND ISNULL(AC.EndDate,@rCompEndDate) > = IComp.BD1
						AND AC.ProgramStartDate <= @rCompEndDate AND ISNULL(AC.EndDate,@rCompEndDate) >= @rCompStartDate
						AND AC.ReasonForDismissal = 'Child reached 2nd birthday'
						AND AC.EndDate BETWEEN @rCompStartDate AND @rCompEndDate
					 THEN AC.CLID END) Tod_completed_comp
		,COUNT(DISTINCT 
				CASE WHEN IComp.BD1 <= @rCompEndDate
						AND IComp.BD2 > @rCompStartDate
						AND ISNULL(AC.EndDate,@rCompEndDate) > = IComp.BD1
						AND AC.ProgramStartDate <= @rCompEndDate AND ISNULL(AC.EndDate,@rCompEndDate) >= @rCompStartDate
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@rCompEndDate)) > @rCompEndDate
					 THEN AC.CLID END) Tod_still_active_comp
		,COUNT(DISTINCT 
				CASE WHEN IComp.BD1 <= @rCompEndDate
						AND IComp.BD2 > @rCompStartDate
						AND ISNULL(AC.EndDate,@rCompEndDate) > = IComp.BD1
						AND AC.ProgramStartDate <= @rCompEndDate AND ISNULL(AC.EndDate,@rCompEndDate) >= @rCompStartDate
						AND AC.ReasonForDismissal <> 'Child reached 2nd birthday'
						AND AC.EndDate BETWEEN @rCompStartDate AND @rCompEndDate
					 THEN AC.CLID END) Tod_leftprog_comp
		,COUNT(DISTINCT 
				CASE WHEN IComp.BD1 <= @rCompEndDate
						AND AC.EndDate BETWEEN IComp.BD1 AND DATEADD(DAY,-1,IComp.BD2)
						AND AC.ProgramStartDate <= @rCompEndDate --AND ISNULL(AC.EndDate,@rCompEndDate) >= @rCompStartDate
						AND ISNULL(AC.ReasonForDismissal,'') <> 'Child reached 2nd birthday'
						AND IComp.BD2 BETWEEN @rCompStartDate AND @rCompEndDate
					 THEN AC.CLID END) Tod_leftprogCHC_comp
		,COUNT(DISTINCT
			CASE WHEN ISNULL(IComp.BD2, (DATEADD(YEAR,2,AC.GestAge_EDD))) BETWEEN @rCompStartDate AND @rCompEndDate			
					AND AC.EndDate < ISNULL(IComp.BD2, (DATEADD(YEAR,2,AC.GestAge_EDD)))										
					AND AC.ReasonForDismissal <> 'Child reached 2nd birthday'	
					AND AC.ProgramStartDate <= @rCompEndDate						
				 THEN AC.CLID END) ToddlerSecondBD_comp	
		,COUNT(DISTINCT
				CASE WHEN AC.EndDate BETWEEN @rCompStartDate AND @rCompEndDate
						AND AC.ReasonForDismissal = 'Child reached 2nd birthday'
					 THEN AC.CLID END) ToddlerGraduated_comp

		--- Tod_RetainedPercent calcualted
		,COUNT(DISTINCT 
				CASE WHEN ISNULL(AC.EndDate,@rCompEndDate) > @rCompStartDate 
						AND AC.ProgramStartDate <= @rCompEndDate AND ISNULL(AC.EndDate,@rCompEndDate) >= @rCompStartDate
					 THEN AC.CLID END) Total_served_comp
		,COUNT(DISTINCT 
				CASE WHEN ISNULL(AC.EndDate,@rCompEndDate) > @rCompStartDate 
						AND AC.ProgramStartDate <= @rCompEndDate AND ISNULL(AC.EndDate,@rCompEndDate) >= @rCompStartDate
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@rCompEndDate)) > @rCompEndDate
					 THEN AC.CLID END) Total_still_active_comp
		,COUNT(DISTINCT 
				CASE WHEN ISNULL(AC.EndDate,@rCompEndDate) > @rCompStartDate 
						AND AC.ProgramStartDate <= @rCompEndDate AND ISNULL(AC.EndDate,@rCompEndDate) >= @rCompStartDate
						AND AC.ReasonForDismissal = 'Child reached 2nd birthday'
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@rCompEndDate)) BETWEEN @rCompStartDate AND @rCompEndDate   
					 THEN AC.CLID END) Total_graduated_comp
		,COUNT(DISTINCT 
				CASE WHEN ISNULL(AC.EndDate,@rCompEndDate) > @rCompStartDate 
						AND AC.ProgramStartDate <= @rCompEndDate AND ISNULL(AC.EndDate,@rCompEndDate) >= @rCompStartDate
						AND AC.ReasonForDismissal <> 'Child reached 2nd birthday'
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@rCompEndDate)) BETWEEN @rCompStartDate AND @rCompEndDate
					 THEN AC.CLID END) Total_leftprog_comp
		--- Total_RetainedPercent calcualted
				
		,COUNT(DISTINCT
				CASE WHEN 
						(IComp.BD2 BETWEEN @rCompStartDate AND @rCompEndDate
						AND ISNULL(AC.EndDate,DATEADD(DAY,1,@rCompEndDate)) > IComp.BD2)
						OR
						(AC.ReasonForDismissal = 'Child reached 2nd birthday'
						AND AC.EndDate BETWEEN @rCompStartDate AND @rCompEndDate)
					 THEN AC.CLID END) ToddlerGradorAct_comp
		--,COUNT(DISTINCT
		--		CASE WHEN AC.EndDate BETWEEN @rCompStartDate AND @rCompEndDate
		--				AND AC.ReasonForDismissal <> 'Child reached 2nd birthday'
		--			 THEN AC.CLID END) Total_LeftProg_comp


FROM DataWarehouse..UV_Fidelity_CLID AC
LEFT JOIN 
	(SELECT CL_EN_GEN_ID, ProgramID, INFANT_BIRTH_0_DOB DOB, DATEADD(YEAR,1,INFANT_BIRTH_0_DOB) BD1, DATEADD(YEAR,2,INFANT_BIRTH_0_DOB) BD2 FROM DataWarehouse..Infant_Birth_Survey) I
	ON AC.CLID = I.CL_EN_GEN_ID AND AC.ProgramID = I.ProgramID
LEFT JOIN 
	(SELECT CL_EN_GEN_ID, ProgramID, INFANT_BIRTH_0_DOB DOB, DATEADD(YEAR,1,INFANT_BIRTH_0_DOB) BD1, DATEADD(YEAR,2,INFANT_BIRTH_0_DOB) BD2 FROM DataWarehouse..Infant_Birth_Survey) IComp
	ON AC.CLID = IComp.CL_EN_GEN_ID AND AC.ProgramID = IComp.ProgramID
WHERE CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN AC.StateID
		WHEN @rReportType = 3 THEN AC.Site_ID
		WHEN @rReportType = 4 THEN AC.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))
	 AND AC.RankingLatest = 1


	  AND AC.Tribal = 1
	  AND AC.Tribal_PM IN( SELECT * FROM dbo.udf_ParseMultiParam(@rTribal_PM))
	  	
GROUP BY
	AC.Site_ID
	,dbo.udf_StateVSTribal(AC.Abbreviation,AC.Site_ID) 
	,AC.[US State]
	,AC.StateID
	,AC.AGENCY_INFO_0_NAME
	,AC.ProgramID
	
	
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
	,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
      
FROM DataWarehouse..UV_PAS P
WHERE CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN P.StateID
		WHEN @rReportType = 3 THEN P.SiteID
		WHEN @rReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))
		
		

--END

--ELSE ------------------------- DATA Return ----------------------
--BEGIN

--SELECT 1
--END

GO
