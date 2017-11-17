USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_COMIECHV_rpt]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_COMIECHV_rpt]
	-- Add the parameters for the stored procedure here
	@EndDate DATE
	,@StartDate DATE
	,@StateID INT
	,@SiteID VARCHAR(4000)
	,@FundingType INT
AS

--DECLARE 
--	@EndDate DATE
--	,@StartDate DATE
--	,@StateID INT
--	,@FundingType INT
	
--SET @EndDate = '9/13/2013'
--SET @StartDate = '10/1/2012'
--SET @StateID = 6 --CO
--SET @FundingType = 1 --Competitive
--EXEC [dbo].[usp_COMIECV_CLID]

SELECT 
	COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					--AND DATEADD(DAY,84,C.ProgramStartDate) BETWEEN @StartDate AND @EndDate
					AND B1C1T_new.SurveyDate BETWEEN @StartDate AND @EndDate
					AND (B1C1T1_new.PrenatalVisits = 1 OR B1C1T1_new.reached12w = 1)
				THEN C.CLID
			END) B1C1T
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					--AND DATEADD(DAY,84,C.ProgramStartDate) BETWEEN @StartDate AND @EndDate
					AND B1C1T_new.SurveyDate BETWEEN @StartDate AND @EndDate
					AND B1C1T1_new.PrenatalVisits = 1
				THEN C.CLID
			END) B1C1T1
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND C.Preg36 BETWEEN @StartDate AND @EndDate
					AND C.B1C2T <= @EndDate
				THEN C.CLID
			END) B1C2T
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND C.Preg36 BETWEEN @StartDate AND @EndDate
					AND C.B1C2T1 <= @EndDate
				THEN C.CLID
			END) B1C2T1
	,COUNT(DISTINCT
			CASE
				WHEN  C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND C.Inf6Mo BETWEEN @StartDate AND @EndDate
					AND C.Inf6Mo <= ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate))
					AND B1C3.SurveyDate <= @EndDate
				THEN C.CLID
			END) B1C3N
	,COUNT(DISTINCT
			CASE
				WHEN  C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND C.Inf6Mo BETWEEN @StartDate AND @EndDate
					AND C.Inf6Mo <= ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate))
					AND B1C3_Baseline.SurveyDate <= DATEADD(MONTH,6,@EndDate)
				THEN C.CLID
			END) B1C3N_BaseLine
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND C.Inf6Mo BETWEEN @StartDate AND @EndDate
					AND C.Inf6Mo <= ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate))
				THEN C.CLID
			END) B1C3D
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND C.Inf6Mo BETWEEN @StartDate AND @EndDate
					AND C.Inf6Mo <= ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate))
					AND B1C4.SurveyDate <= @EndDate
				THEN C.CLID
			END) B1C4N
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND C.Inf6Mo BETWEEN @StartDate AND @EndDate
					AND C.Inf6Mo <= ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate))
					AND B1C4_Baseline.SurveyDate <= DATEADD(MONTH,6,@EndDate)
				THEN C.CLID
			END) B1C4N_BaseLine
	,COUNT(DISTINCT
			CASE
				WHEN  C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND C.Inf6Mo BETWEEN @StartDate AND @EndDate
					AND C.Inf6Mo <= ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate))
				THEN C.CLID
			END) B1C4D
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND C.Inf6Mo BETWEEN @StartDate AND @EndDate
					AND C.Inf6Mo <= ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate))
					AND B1C5.SurveyDate <= @EndDate
				THEN C.CLID
			END) B1C5N
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND C.Inf6Mo BETWEEN @StartDate AND @EndDate
					AND C.Inf6Mo <= ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate))
					AND B1C5_BaseLine.SurveyDate <= DATEADD(MONTH,6,@EndDate)
				THEN C.CLID
			END) B1C5N_BaseLine
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND C.Inf6Mo BETWEEN @StartDate AND @EndDate
					AND C.Inf6Mo <= ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate))
				THEN C.CLID
			END) B1C5D
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND C.ProgramStartDate <= ISNULL(C.InfantDOB,DATEADD(D,1,@EndDate))
					AND B1C6N.SurveyDate <= @EndDate
					AND IBS_Birth.SurveyDate BETWEEN @StartDate AND @EndDate
				THEN C.CLID
			END) B1C6N
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND C.ProgramStartDate <= ISNULL(C.InfantDOB,DATEADD(D,1,@EndDate))
					AND B1C6N_BaseLine.SurveyDate <= DATEADD(Month,8,@EndDate)
					AND IBS_Birth.SurveyDate BETWEEN @StartDate AND @EndDate
				THEN C.CLID
			END) B1C6N_BaseLine
	,COUNT(DISTINCT
	
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND C.ProgramStartDate <= ISNULL(C.InfantDOB,DATEADD(D,1,@EndDate))
					AND IBS_Birth.SurveyDate BETWEEN @StartDate AND @EndDate
				THEN C.CLID
			END) B1C6D
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND C.ProgramStartDate <= ISNULL(C.InfantDOB,DATEADD(D,1,@EndDate))
					AND IHS6M.SurveyDate BETWEEN @StartDate AND @EndDate
					AND B1C7.SurveyDate <= @EndDate
				THEN C.CLID
			END) B1C7N
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND C.ProgramStartDate <= ISNULL(C.InfantDOB,DATEADD(D,1,@EndDate))
					AND IHS6M.SurveyDate BETWEEN @StartDate AND @EndDate
					AND B1C7_BaseLine.SurveyDate <= DATEADD(MONTH,6,@EndDate)
				THEN C.CLID
			END) B1C7N_BaseLine
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND C.ProgramStartDate <= ISNULL(C.InfantDOB,DATEADD(D,1,@EndDate))
					AND IHS6M.SurveyDate BETWEEN @StartDate AND @EndDate
				THEN C.CLID
			END) B1C7D

	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= C.Inf6Mo
					AND C.Inf6Mo BETWEEN @StartDate AND @EndDate
					AND C.B1C8A <= @EndDate
				THEN C.CLID
			END) B1C8A
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= C.Inf6Mo
					AND C.Inf6Mo BETWEEN @StartDate AND @EndDate
					AND C.B1C8B <= @EndDate
				THEN C.CLID
			END) B1C8B
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= C.Inf6Mo
					AND C.Inf6Mo BETWEEN @StartDate AND @EndDate
					AND C.B1C8A <= @EndDate
					AND C.B1C8T1A <= @EndDate
				THEN C.CLID
			END) B1C8T1A
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= C.Inf6Mo
					AND C.Inf6Mo BETWEEN @StartDate AND @EndDate
					AND C.B1C8B <= @EndDate
					AND C.B1C8T1B <= @EndDate
				THEN C.CLID
			END) B1C8T1B
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND IHS6M.SurveyDate BETWEEN @StartDate AND	DATEADD(DAY,-1,DATEADD(MONTH,6,@StartDate))
					AND B2C1.SurveyDate <= @EndDate
				THEN C.CLID
			END) B2C1C1N
	,COUNT(DISTINCT
			CASE
				WHEN  C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND IHS6M.SurveyDate BETWEEN @StartDate AND DATEADD(DAY,-1,DATEADD(MONTH,6,@StartDate))
				THEN C.CLID
			END) B2C1C1D
	,COUNT(DISTINCT
			CASE
				WHEN C.B2C1C2N <= @EndDate
					AND C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND IHS12M.SurveyDate BETWEEN DATEADD(MONTH,6,@StartDate) AND @EndDate
				THEN C.CLID
			END) B2C1C2N
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND IHS12M.SurveyDate BETWEEN DATEADD(MONTH,6,@StartDate) AND @EndDate
				THEN C.CLID
			END) B2C1C2D
			
	--,SUM( Changed 5/12/14 to remove sum and count clients
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND DSInt.SurveyDate BETWEEN @StartDate AND	DATEADD(DAY,-1,DATEADD(MONTH,6,@StartDate))
				THEN C.B2C2C1N
			END) B2C2C1N
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND DSInt.SurveyDate BETWEEN @StartDate AND	DATEADD(DAY,-1,DATEADD(MONTH,6,@StartDate))
				THEN C.CLID
			END) B2C2C1D
	--,SUM( Changed 5/12/14 to remove sum and count clients
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND DS6M.SurveyDate BETWEEN DATEADD(MONTH,6,@StartDate) AND @EndDate
				THEN C.B2C2C2N
			END) B2C2C2N
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND DS6M.SurveyDate BETWEEN DATEADD(MONTH,6,@StartDate) AND @EndDate 
				THEN C.CLID
			END) B2C2C2D
	,COUNT(DISTINCT
			CASE
				WHEN B2C3.SurveyDate BETWEEN C.ProgramStartDate AND DATEADD(DAY,365.25,C.ProgramStartDate)
					AND B2C3D.SurveyDate BETWEEN C.ProgramStartDate AND DATEADD(DAY,365.25,C.ProgramStartDate)
					AND B2C3D.SurveyDate BETWEEN @StartDate AND @EndDate
					AND C.InfantDOB <= @EndDate 
				THEN C.CLID
			END) B2C3N
	,COUNT(DISTINCT
			CASE
				WHEN B2C3_BaseLine.SurveyDate BETWEEN C.ProgramStartDate AND DATEADD(DAY,730.5,C.ProgramStartDate)
					AND B2C3D.SurveyDate BETWEEN C.ProgramStartDate AND DATEADD(DAY,365.25,C.ProgramStartDate)
					AND B2C3D.SurveyDate BETWEEN @StartDate AND @EndDate
					AND C.InfantDOB <= @EndDate 
				THEN C.CLID
			END) B2C3N_baseline
	,COUNT(DISTINCT
			CASE
				WHEN B2C3D.SurveyDate BETWEEN C.ProgramStartDate AND DATEADD(DAY,365.25,C.ProgramStartDate)
					AND B2C3D.SurveyDate BETWEEN @StartDate AND @EndDate
					AND C.InfantDOB <= @EndDate 
				THEN C.CLID
			END) B2C3D

	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND B2C4C1.SurveyDate BETWEEN DATEADD(MONTH,6,@StartDate) AND @EndDate
					AND IHS6M.SurveyDate BETWEEN @StartDate AND DATEADD(DAY,-1,DATEADD(MONTH,6,@StartDate))
				THEN C.CLID
			END) B2C4C1N
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND IHS6M.SurveyDate BETWEEN @StartDate AND DATEADD(DAY,-1,DATEADD(MONTH,6,@StartDate))
				THEN C.CLID
			END) B2C4C1D
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND B2C4C2.SurveyDate BETWEEN DATEADD(MONTH,6,@StartDate) AND @EndDate
					AND IHS12M.SurveyDate BETWEEN DATEADD(MONTH,6,@StartDate) AND @EndDate
				THEN C.CLID
			END) B2C4C2N
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND IHS12M.SurveyDate BETWEEN DATEADD(MONTH,6,@StartDate) AND @EndDate
				THEN C.CLID
			END) B2C4C2D

	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND IHS12M.SurveyDate BETWEEN DATEADD(MONTH,6,@StartDate) AND @EndDate
					AND B2C5.SurveyDate BETWEEN DATEADD(MONTH,6,@StartDate) AND @EndDate
				THEN C.CLID
			END) B2C5N
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND IHS12M.SurveyDate BETWEEN DATEADD(MONTH,6,@StartDate) AND @EndDate
					AND B2C5_BaseLine.SurveyDate BETWEEN DATEADD(MONTH,6,@StartDate) AND DATEADD(MONTH,12,@EndDate)
				THEN C.CLID
			END) B2C5N_BaseLine
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND IHS12M.SurveyDate BETWEEN DATEADD(MONTH,6,@StartDate) AND @EndDate
				THEN C.CLID
			END) B2C5D
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate < = @EndDate
					AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND HV.SurveyDate BETWEEN @StartDate AND @EndDate
					AND C.Inf6Mo <= @EndDate
					AND B3C1.SurveyDate BETWEEN @StartDate AND @EndDate
				THEN C.CLID
			END) B3C1N
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate < = @EndDate
					AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND HV.SurveyDate BETWEEN @StartDate AND @EndDate
					AND C.Inf6Mo <= @EndDate
					AND B3C1_BaseLine.SurveyDate BETWEEN @StartDate AND DATEADD(MONTH,12,@EndDate)
				THEN C.CLID
			END) B3C1N_BaseLine
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate < = @EndDate
					AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND HV.SurveyDate BETWEEN @StartDate AND @EndDate
					AND C.Inf6Mo BETWEEN @StartDate AND @EndDate --C.Inf6Mo <= @EndDate
				THEN C.CLID
			END) B3C1D
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate < = @EndDate
					AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND B3C26.INFANT_HOME_0_TOTAL IS NOT NULL
					AND B3C2T18.SurveyDate BETWEEN @StartDate AND @EndDate
				THEN C.CLID
			END) B3C2T
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate < = @EndDate
					AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND B3C26.SurveyDate <= @EndDate
					AND B3C2T18.SurveyDate BETWEEN @StartDate AND @EndDate
					AND B3C2T18.INFANT_HOME_0_TOTAL > B3C26.INFANT_HOME_0_TOTAL
				THEN C.CLID
			END) B3C2T1
	
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate < = @EndDate
					AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND B3C3T18.SurveyDate BETWEEN @StartDate AND @EndDate
					AND B3C36.SurveyDate <= @EndDate
				THEN C.CLID
			END) B3C3T
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate < = @EndDate
					AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND B3C3T18.SurveyDate BETWEEN @StartDate AND @EndDate
					AND B3C36.SurveyDate <= @EndDate
					AND (B3C3T18.INFANT_HOME_1_ACCEPTANCE > B3C36.INFANT_HOME_1_ACCEPTANCE
						 OR B3C3T18.INFANT_HOME_1_RESPONSIVITY > B3C36.INFANT_HOME_1_RESPONSIVITY)
				THEN C.CLID
			END) B3C3T1
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND C.Inf6Mo BETWEEN @StartDate AND @EndDate
					AND C.Inf6Mo <= ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate))
					AND B1C5.SurveyDate <= @EndDate
				THEN C.CLID
			END) B3C4N
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND C.Inf6Mo BETWEEN @StartDate AND @EndDate
					AND C.Inf6Mo <= ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate))
					AND B1C5_BaseLine.SurveyDate <= DATEADD(MONTH,6,@EndDate)
				THEN C.CLID
			END) B3C4N_BaseLine
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND C.Inf6Mo BETWEEN @StartDate AND @EndDate
					AND C.Inf6Mo <= ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate))
				THEN C.CLID
			END) B3C4D
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND (
							IHS6M.SurveyDate BETWEEN @StartDate AND @EndDate
							OR IHS12M.SurveyDate BETWEEN @StartDate AND @EndDate
						)
					AND B3C5.SurveyDate <= @EndDate --AND B3C5.SurveyDate <= C.Tod12Mo
				THEN C.CLID
			END) B3C5N
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND (
							IHS6M.SurveyDate BETWEEN @StartDate AND @EndDate
							OR IHS12M.SurveyDate BETWEEN @StartDate AND @EndDate
						)
				THEN C.CLID
			END) B3C5D

	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND (
							IHS6M.SurveyDate BETWEEN @StartDate AND @EndDate
							OR IHS12M.SurveyDate BETWEEN @StartDate AND @EndDate
						)
					AND B3C6.SurveyDate <= @EndDate --AND B3C6.SurveyDate <= C.Tod12Mo
				THEN C.CLID
			END) B3C6N
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND (
							IHS6M.SurveyDate BETWEEN @StartDate AND @EndDate
							OR IHS12M.SurveyDate BETWEEN @StartDate AND @EndDate
						)
				THEN C.CLID
			END) B3C6D

	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND (
							IHS6M.SurveyDate BETWEEN @StartDate AND @EndDate
							OR IHS12M.SurveyDate BETWEEN @StartDate AND @EndDate
						)
					AND B3C7.SurveyDate <= @EndDate --AND B3C7.SurveyDate <= C.Tod12Mo
				THEN C.CLID
			END) B3C7N
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND (
							IHS6M.SurveyDate BETWEEN @StartDate AND @EndDate
							OR IHS12M.SurveyDate BETWEEN @StartDate AND @EndDate
						)
				THEN C.CLID
			END) B3C7D

	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND (
							IHS6M.SurveyDate BETWEEN @StartDate AND @EndDate
							OR IHS12M.SurveyDate BETWEEN @StartDate AND @EndDate
						)
					AND B3C8.SurveyDate <= @EndDate --AND B3C8.SurveyDate <= C.Tod12Mo
				THEN C.CLID
			END) B3C8N
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND (
							IHS6M.SurveyDate BETWEEN @StartDate AND @EndDate
							OR IHS12M.SurveyDate BETWEEN @StartDate AND @EndDate
						)
				THEN C.CLID
			END) B3C8D

	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND (
							IHS6M.SurveyDate BETWEEN @StartDate AND @EndDate
							OR IHS12M.SurveyDate BETWEEN @StartDate AND @EndDate
						)
					AND B3C9.SurveyDate <= @EndDate --AND B3C9.SurveyDate <= C.Tod12Mo
				THEN C.CLID
			END) B3C9N
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND (
							IHS6M.SurveyDate BETWEEN @StartDate AND @EndDate
							OR IHS12M.SurveyDate BETWEEN @StartDate AND @EndDate
						)
				THEN C.CLID
			END) B3C9D
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <=  @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND B4C3N <= @EndDate
				THEN C.CLID
			END) B4C3N
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <=  @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
				THEN C.CLID
			END) B4C3D	

	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND B4C4N <= @EndDate
					AND C.B4C4D <= @EndDate
				THEN C.CLID
			END) B4C4N
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND B4C4N <= DATEADD(MONTH,12,@EndDate)
					AND C.B4C4D <= @EndDate
				THEN C.CLID
			END) B4C4N_BaseLine
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND C.B4C4D <= @EndDate
				THEN C.CLID
			END) B4C4D

	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND B4C5N <= @EndDate
					AND B4C4D <= @EndDate
				THEN C.CLID
			END) B4C5N
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND B4C5N <= DATEADD(MONTH,12,@EndDate)
					AND B4C4D <= @EndDate
				THEN C.CLID
			END) B4C5N_BaseLine
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND C.B4C4D <= @EndDate
				THEN C.CLID
			END) B4C5D

	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND DSInt.SurveyDate <= @EndDate
					AND DS12M.SurveyDate BETWEEN @StartDate AND @EndDate
				THEN C.CLID
			END) B5C1T
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND DSInt.SurveyDate <= @EndDate
					AND DS12M.SurveyDate BETWEEN @StartDate AND @EndDate
					AND B5C1T112M.[Household Income] > B5C1T1Int.[Household Income]
				THEN C.CLID
			END) B5C1T1

	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND B5C2TInt.SurveyDate <= @EndDate
					AND B5C2T12M.SurveyDate BETWEEN @StartDate AND @EndDate
				THEN C.CLID
			END) B5C2T
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND B5C2T12M.HighestEdLvl > B5C2TInt.HighestEdLvl
					AND B5C2T12M.SurveyDate BETWEEN @StartDate AND @EndDate
					AND B5C2TInt.SurveyDate <= @EndDate
				THEN C.CLID
			END) B5C2T1
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= C.Inf6Mo
					AND C.Inf6Mo BETWEEN @StartDate AND @EndDate
					AND C.B1C8A <= @EndDate
				THEN C.CLID
			END) B5C3A
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= C.Inf6Mo
					AND C.Inf6Mo BETWEEN @StartDate AND @EndDate
					AND C.B1C8B <= @EndDate
				THEN C.CLID
			END) B5C3B
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= C.Inf6Mo
					AND C.Inf6Mo BETWEEN @StartDate AND @EndDate
					AND C.B1C8A <= @EndDate
					AND C.B1C8T1A <= @EndDate
				THEN C.CLID
			END) B5C3T1A
	,COUNT(DISTINCT
			CASE
				WHEN C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= C.Inf6Mo
					AND C.Inf6Mo BETWEEN @StartDate AND @EndDate
					AND C.B1C8B <= @EndDate
					AND C.B1C8T1B <= @EndDate
				THEN C.CLID
			END) B5C3T1B
	,COUNT(DISTINCT
			CASE
				WHEN  C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND B6C1N <= @EndDate
					AND C.Tod12Mo > @StartDate
				THEN C.CLID
			END) B6C1N
	,COUNT(DISTINCT
			CASE
				WHEN  C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND B6C1N <= DATEADD(MONTH,12,@EndDate)
					AND C.Tod12Mo > @StartDate
				THEN C.CLID
			END) B6C1N_BaseLine
	,COUNT(DISTINCT
			CASE
				WHEN  C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND C.Tod12Mo > @StartDate
				THEN C.CLID
			END) B6C1D

	,COUNT(DISTINCT
			CASE
				WHEN  C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND B6C2N <= @EndDate
					AND C.Tod12Mo > @StartDate
				THEN C.CLID
			END) B6C2N

	,COUNT(DISTINCT
			CASE
				WHEN  C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND B6C2N <= DATEADD(MONTH,12,@EndDate)
					AND C.Tod12Mo > @StartDate
				THEN C.CLID
			END) B6C2N_BaseLine
	,COUNT(DISTINCT
			CASE
				WHEN  C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND C.Tod12Mo > @StartDate
				THEN C.CLID
			END) B6C2D
	,COUNT(DISTINCT
			CASE
				WHEN  C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND B6C5 <= @EndDate
					AND C.Tod12Mo > @StartDate
				THEN C.CLID
			END) B6C5N	
	,COUNT(DISTINCT
			CASE
				WHEN  C.ProgramStartDate <= @EndDate AND ISNULL(C.EndDate,DATEADD(DAY,1,@EndDate)) >= @StartDate
					AND B6C5 <= DATEADD(MONTH,12,@EndDate)
					AND C.Tod12Mo > @StartDate
				THEN C.CLID
			END) B6C5N_BaseLine		

FROM UC_COMIECV_CLID C
	INNER JOIN UV_PAS P
		ON P.ProgramID = C.ProgramID
		AND P.StateID IN (@StateID)
		AND P.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam(@SiteID))
		AND CASE WHEN @FundingType = 1 THEN 'Competitive' ELSE 'Formula' END = C.FundingSource
	LEFT JOIN 
		(
			SELECT MAX(H.SurveyDate) SurveyDate,H.CL_EN_GEN_ID,H.ProgramID
			FROM  Home_Visit_Encounter_Survey H
			WHERE H.SurveyDate BETWEEN @StartDate AND @EndDate
				AND H.CLIENT_COMPLETE_0_VISIT = 'Completed'
			GROUP BY H.CL_EN_GEN_ID,H.ProgramID
		) HV
		ON HV.CL_EN_GEN_ID = C.CLID
		AND HV.ProgramID = C.ProgramID

LEFT OUTER JOIN   -- clients with a gcss intake from and all insurances blank
	(SELECT
		GCSS.CL_EN_GEN_ID
		,MAX(GCSS.SurveyDate) SurveyDate
		,ProgramId
	FROM Govt_Comm_Srvcs_Survey GCSS
	WHERE 
		(ISNULL(GCSS.SERVICE_USE_0_MEDICAID_CLIENT,0) NOT IN (2,5)
		AND ISNULL(GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT,0) NOT IN (2,5)
		AND ISNULL(GCSS.SERVICE_USE_0_SCHIP_CLIENT,0) NOT IN (2,5)
		AND ISNULL(GCSS.[SERVICE_USE_MILITARY_INS_CLIENT ],0) NOT IN (2,5))
		
		AND dbo.fnGetFormName(GCSS.SurveyID) like '%INTAKE%'
		AND GCSS.SurveyDate <= @EndDate
	GROUP BY GCSS.CL_EN_GEN_ID,ProgramID) B1C1T
	ON C.CLID = B1C1T.CL_EN_GEN_ID
	AND C.ProgramID = B1C1T.ProgramID

LEFT JOIN
	(SELECT 
		GCSS.ProgramID
		,GCSS.CL_EN_GEN_ID
		,MAX(GCSS.SurveyDate) SurveyDate
	FROM Govt_Comm_Srvcs_Survey GCSS
	WHERE (GCSS.SERVICE_USE_PCP_CLIENT_PRENATAL <> 2 OR GCSS.SERVICE_USE_PCP_CLIENT_PRENATAL IS NULL)
		AND (GCSS.SERVICE_USE_PCP_CLIENT_WELLWOMAN <> 2 OR GCSS.SERVICE_USE_PCP_CLIENT_WELLWOMAN IS NULL)
		AND dbo.fnGetFormName(GCSS.SurveyID) like '%INTAKE%'
		AND GCSS.SurveyDate <= @EndDate
	GROUP BY GCSS.CL_EN_GEN_ID, GCSS.ProgramID) B1C1T_new
	ON C.CLID = B1C1T_new.CL_EN_GEN_ID
	AND C.ProgramID = B1C1T_new.ProgramID

LEFT OUTER JOIN  -- clients with a gcss 36preg from and  insurance
	(SELECT
		GCSS.CL_EN_GEN_ID
		,MAX(GCSS.SurveyDate) SurveyDate, ProgramID
	FROM Govt_Comm_Srvcs_Survey GCSS
	WHERE 
		(GCSS.SERVICE_USE_0_MEDICAID_CLIENT IN (2,5)
		OR GCSS.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IN (2,5)
		OR GCSS.SERVICE_USE_0_SCHIP_CLIENT IN (2,5)
		OR GCSS.[SERVICE_USE_MILITARY_INS_CLIENT ] IN (2,5))
		AND dbo.fnGetFormName(GCSS.SurveyID) like '%Birth%'
		AND GCSS.SurveyDate <= @EndDate
	GROUP BY ProgramID, GCSS.CL_EN_GEN_ID) B1C1T1
	ON C.CLID = B1C1T1.CL_EN_GEN_ID 
	AND C.ProgramID = B1C1T1.ProgramID
	
LEFT OUTER JOIN -- added 11/4/14 to replace B1C1
	(SELECT EAD.ProgramID, EAD.CLID, MAX(CASE WHEN HVES.CLIENT_PRENATAL_VISITS = 'Yes' THEN 1 ELSE 0 END) PrenatalVisits, MAX(CASE WHEN DATEADD(WEEK,12,EAD.ProgramStartDate) <= @EndDate THEN 1 END) reached12w
	FROM UV_EADT EAD
	LEFT JOIN Home_Visit_Encounter_Survey HVES ON EAD.ProgramID = HVES.ProgramID AND EAD.CLID = HVES.CL_EN_GEN_ID
	WHERE HVES.SurveyDate <= DATEADD(WEEK,12,EAD.ProgramStartDate)
		AND HVES.SurveyDate <= @EndDate
	GROUP BY EAD.ProgramID, EAD.CLID) B1C1T1_new
	ON B1C1T1_new.ProgramID = C.ProgramID
	AND C.CLID = B1C1T1_new.CLID

LEFT OUTER JOIN
	(SELECT GCSS.CL_EN_GEN_ID, MAX(GCSS.SurveyDate) SurveyDate, ProgramID
	FROM Govt_Comm_Srvcs_Survey GCSS
	WHERE (GCSS.SERVICE_USE_PCP_CLIENT_WELLWOMAN IN (2,5)  OR GCSS.SERVICE_USE_0_PCP_WELL_CLIENT IN (2,5))
		AND dbo.fnGetFormName(GCSS.SurveyID) IN ('Use of Government & Community Services-Infancy 6','Use of Government & Community Services-Birth','Use of Government & Community Services-Intake')
		AND GCSS.SurveyDate <= @EndDate
	GROUP BY ProgramID, GCSS.CL_EN_GEN_ID) B1C3
	ON C.CLID = B1C3.CL_EN_GEN_ID
	AND C.ProgramID = B1C3.ProgramID
LEFT OUTER JOIN
	(SELECT GCSS.CL_EN_GEN_ID, MAX(GCSS.SurveyDate) SurveyDate, ProgramID
	FROM Govt_Comm_Srvcs_Survey GCSS
	WHERE (GCSS.SERVICE_USE_PCP_CLIENT_WELLWOMAN IN (2,5)  OR GCSS.SERVICE_USE_0_PCP_WELL_CLIENT IN (2,5))
		AND dbo.fnGetFormName(GCSS.SurveyID) IN ('Use of Government & Community Services-Infancy 6','Use of Government & Community Services-Birth','Use of Government & Community Services-Intake')
		AND GCSS.SurveyDate <= DATEADD(MONTH,6,@EndDate)
	GROUP BY ProgramID, GCSS.CL_EN_GEN_ID) B1C3_Baseline
	ON C.CLID = B1C3_Baseline.CL_EN_GEN_ID
	AND C.ProgramID = B1C3_Baseline.ProgramID
LEFT OUTER JOIN
	(SELECT DISTINCT DS.CL_EN_GEN_ID, MAX(DS.SurveyDate) SurveyDate, ProgramID
	FROM Demographics_Survey DS
	WHERE DS.CLIENT_BC_0_USED_6MONTHS IN ('Yes','No')
		AND DBO.fnGetFormName(DS.SurveyID) = 'Demographics Update: Infancy 6 Months'
		AND DS.SurveyDate <= @EndDate
	GROUP BY ProgramID, DS.CL_EN_GEN_ID) B1C4
	ON C.CLID = B1C4.CL_EN_GEN_ID
	AND C.ProgramID = B1C4.ProgramID	
LEFT OUTER JOIN
	(SELECT DISTINCT DS.CL_EN_GEN_ID, MAX(DS.SurveyDate) SurveyDate, ProgramID
	FROM Demographics_Survey DS
	WHERE DS.CLIENT_BC_0_USED_6MONTHS IN ('Yes','No')
		AND DBO.fnGetFormName(DS.SurveyID) = 'Demographics Update: Infancy 6 Months'
		AND DS.SurveyDate <= DATEADD(MONTH,6,@EndDate)
	GROUP BY ProgramID, DS.CL_EN_GEN_ID) B1C4_Baseline
	ON C.CLID = B1C4_Baseline.CL_EN_GEN_ID
	AND C.ProgramID = B1C4_Baseline.ProgramID	
LEFT OUTER JOIN --Most recent instance of client being screened for depression w/ edinburgh prior to 6 mos
	(SELECT DISTINCT PH.CL_EN_GEN_ID, MAX(PH.SurveyDate) SurveyDate, ProgramID
	FROM PHQ_Survey  PH
	WHERE DBO.fnGetFormName(PH.SurveyID) IN ('PHQ-9-Infancy 4-6 mos'
											,'PHQ-9-Infancy 1-4 wks'
											,'PHQ-9-Intake'
											,'PHQ-9-Infancy 1-8 wks'
											,'PHQ-9-Pregnancy 36 wks')
		AND PH.SurveyDate <= @EndDate
	GROUP BY ProgramID, PH.CL_EN_GEN_ID
	
	UNION

	SELECT DISTINCT ES.CL_EN_GEN_ID, MAX(ES.SurveyDate) SurveyDate, ProgramID
	FROM Edinburgh_Survey  ES
	WHERE DBO.fnGetFormName(ES.SurveyID) IN ('Edinburgh Postnatal Depression-Infancy 4-6 mos'
											,'Edinburgh Postnatal Depression-Pregnancy-36 wks'
											,'Edinburgh Postnatal Depression-Infancy 1-8 wks'
											,'Edinburgh Postnatal Depression-Infancy 1-4 wks'
											,'Edinburgh Postnatal Depression-Intake')
		AND ES.SurveyDate <= @EndDate
	GROUP BY ProgramID, ES.CL_EN_GEN_ID) B1C5 
	ON C.CLID = B1C5.CL_EN_GEN_ID
	AND C.ProgramID = B1C5.ProgramID
LEFT OUTER JOIN --Most recent instance of client being screened for depression w/ edinburgh prior to 6 mos
	(SELECT DISTINCT PH.CL_EN_GEN_ID, MAX(PH.SurveyDate) SurveyDate, ProgramID
	FROM PHQ_Survey  PH
	WHERE DBO.fnGetFormName(PH.SurveyID) IN ('PHQ-9-Infancy 4-6 mos'
											,'PHQ-9-Infancy 1-4 wks'
											,'PHQ-9-Intake'
											,'PHQ-9-Infancy 1-8 wks'
											,'PHQ-9-Pregnancy 36 wks')
		AND PH.SurveyDate <= DATEADD(MONTH,6,@EndDate)
	GROUP BY ProgramID, PH.CL_EN_GEN_ID
	
	UNION

	SELECT DISTINCT ES.CL_EN_GEN_ID, MAX(ES.SurveyDate) SurveyDate, ProgramID
	FROM Edinburgh_Survey  ES
	WHERE DBO.fnGetFormName(ES.SurveyID) IN ('Edinburgh Postnatal Depression-Infancy 4-6 mos'
											,'Edinburgh Postnatal Depression-Pregnancy-36 wks'
											,'Edinburgh Postnatal Depression-Infancy 1-8 wks'
											,'Edinburgh Postnatal Depression-Infancy 1-4 wks'
											,'Edinburgh Postnatal Depression-Intake')
		AND ES.SurveyDate <= DATEADD(MONTH,6,@EndDate)
	GROUP BY ProgramID, ES.CL_EN_GEN_ID) B1C5_BaseLine
	ON C.CLID = B1C5_BaseLine.CL_EN_GEN_ID
	AND C.ProgramID = B1C5_BaseLine.ProgramID
LEFT OUTER JOIN
	(SELECT DISTINCT IBS.CL_EN_GEN_ID, MAX(IBS.SurveyDate) SurveyDate, ProgramID
	FROM Infant_Birth_Survey IBS
	WHERE IBS.SurveyDate <= @EndDate
	GROUP BY ProgramID, IBS.CL_EN_GEN_ID) IBS_Birth
	ON C.CLID = IBS_Birth.CL_EN_GEN_ID
	AND C.ProgramID = IBS_Birth.ProgramId	
LEFT OUTER JOIN
	(SELECT DISTINCT IBS.CL_EN_GEN_ID, MAX(IBS.SurveyDate) SurveyDate, ProgramID
	FROM Infant_Birth_Survey IBS
	WHERE IBS.INFANT_BREASTMILK_0_EVER_BIRTH = 'YES'
		AND IBS.SurveyDate <= @EndDate
	GROUP BY ProgramID, IBS.CL_EN_GEN_ID) B1C6N
	ON C.CLID = B1C6N.CL_EN_GEN_ID
	AND C.ProgramID = B1C6N.ProgramId	
LEFT OUTER JOIN
	(SELECT DISTINCT IBS.CL_EN_GEN_ID, MAX(IBS.SurveyDate) SurveyDate, ProgramID
	FROM Infant_Birth_Survey IBS
	WHERE IBS.INFANT_BREASTMILK_0_EVER_BIRTH = 'YES'
		AND IBS.SurveyDate <= DATEADD(MONTH,8,@EndDate)
	GROUP BY ProgramID, IBS.CL_EN_GEN_ID) B1C6N_BaseLine
	ON C.CLID = B1C6N_BaseLine.CL_EN_GEN_ID
	AND C.ProgramID = B1C6N_BaseLine.ProgramId	
LEFT OUTER JOIN
	(SELECT DISTINCT IBS.CL_EN_GEN_ID, MAX(IBS.SurveyDate) SurveyDate, ProgramID
	FROM Infant_Health_Survey IBS
	WHERE dbo.fnGetFormName(IBS.SurveyID) LIKE '%6%'
		AND IBS.SurveyDate <= @EndDate
	GROUP BY ProgramID, IBS.CL_EN_GEN_ID) IHS6M
	ON C.CLID = IHS6M.CL_EN_GEN_ID
	AND C.ProgramID = IHS6M.ProgramId	
LEFT OUTER JOIN
	(SELECT DISTINCT IBS.CL_EN_GEN_ID, MAX(IBS.SurveyDate) SurveyDate, ProgramID
	FROM Infant_Health_Survey IBS
	WHERE dbo.fnGetFormName(IBS.SurveyID) LIKE '%12%'
		AND IBS.SurveyDate <= @EndDate
	GROUP BY ProgramID, IBS.CL_EN_GEN_ID) IHS12M
	ON C.CLID = IHS12M.CL_EN_GEN_ID
	AND C.ProgramID = IHS12M.ProgramId	

LEFT OUTER JOIN
	(SELECT DISTINCT IBS.CL_EN_GEN_ID, MAX(IBS.SurveyDate) SurveyDate, ProgramID
	FROM Demographics_Survey IBS
	WHERE dbo.fnGetFormName(IBS.SurveyID) LIKE '%Intake%'
		AND IBS.SurveyDate <= @EndDate
	GROUP BY ProgramID, IBS.CL_EN_GEN_ID) DSInt
	ON C.CLID = DSInt.CL_EN_GEN_ID
	AND C.ProgramID = DSInt.ProgramId	

LEFT OUTER JOIN
	(SELECT DISTINCT IBS.CL_EN_GEN_ID, MAX(IBS.SurveyDate) SurveyDate, ProgramID
	FROM Demographics_Survey IBS
	WHERE dbo.fnGetFormName(IBS.SurveyID) LIKE '%6%'
		AND IBS.SurveyDate <= @EndDate
	GROUP BY ProgramID, IBS.CL_EN_GEN_ID) DS6M
	ON C.CLID = DS6M.CL_EN_GEN_ID
	AND C.ProgramID = DS6M.ProgramId	

LEFT OUTER JOIN
	(SELECT DISTINCT IBS.CL_EN_GEN_ID, MAX(IBS.SurveyDate) SurveyDate, ProgramID
	FROM Demographics_Survey IBS
	WHERE dbo.fnGetFormName(IBS.SurveyID) LIKE '%12%'
		AND IBS.SurveyDate <= @EndDate
	GROUP BY ProgramID, IBS.CL_EN_GEN_ID) DS12M
	ON C.CLID = DS12M.CL_EN_GEN_ID
	AND C.ProgramID = DS12M.ProgramId	
	
LEFT OUTER JOIN
	(SELECT DISTINCT IHS.CL_EN_GEN_ID, MAX(IHS.SurveyDate) SurveyDate, ProgramID
	FROM Infant_Health_Survey IHS
	WHERE IHS.INFANT_HEALTH_PROVIDER_0_APPT_R2 = 'Yes' 
		AND dbo.fnGetFormName(IHS.SurveyID) LIKE '%6%'
		AND IHS.SurveyDate <= @EndDate
	GROUP BY ProgramID, IHS.CL_EN_GEN_ID) B1C7
	ON C.CLID = B1C7.CL_EN_GEN_ID
	AND C.ProgramID = B1C7.ProgramID
LEFT OUTER JOIN
	(SELECT DISTINCT IHS.CL_EN_GEN_ID, MAX(IHS.SurveyDate) SurveyDate, ProgramID
	FROM Infant_Health_Survey IHS
	WHERE IHS.INFANT_HEALTH_PROVIDER_0_APPT_R2 = 'Yes' 
		AND dbo.fnGetFormName(IHS.SurveyID) LIKE '%6%'
		AND IHS.SurveyDate <= DATEADD(MONTH,6,@EndDate)
	GROUP BY ProgramID, IHS.CL_EN_GEN_ID) B1C7_BaseLine
	ON C.CLID = B1C7_BaseLine.CL_EN_GEN_ID
	AND C.ProgramID = B1C7_BaseLine.ProgramID
	
LEFT OUTER JOIN
	(SELECT IHS.CL_EN_GEN_ID, MAX(IHS.SurveyDate) SurveyDate, ProgramID
	FROM Infant_Health_Survey IHS
	WHERE INFANT_HEALTH_ER_0_HAD_VISIT = 'YES'
		AND dbo.fnGetFormName(IHS.SurveyID) LIKE '%6%'
		AND IHS.SurveyDate <= @EndDate
	GROUP BY ProgramID, IHS.CL_EN_GEN_ID) B2C1
	ON C.CLID = B2C1.CL_EN_GEN_ID
	AND C.ProgramID = B2C1.ProgramID

LEFT OUTER JOIN
	(SELECT HVES.CL_EN_GEN_ID, MIN(HVES.SurveyDate) SurveyDate, HVES.ProgramID,HVES.CLIENT_CHILD_INJURY_0_PREVENTION
	FROM Home_Visit_Encounter_Survey HVES
		INNER JOIN Infant_Birth_Survey IB
			ON IB.CL_EN_GEN_ID = HVES.CL_EN_GEN_ID 
			AND IB.ProgramID = HVES.ProgramID
			AND DATEADD(DAY,365.25,IB.INFANT_BIRTH_0_DOB) > HVES.SurveyDate
	WHERE HVES.CLIENT_COMPLETE_0_VISIT = 'COMPLETED'
		AND HVES.CLIENT_CHILD_INJURY_0_PREVENTION IS NOT NULL
		AND HVES.SurveyDate BETWEEN @StartDate AND @EndDate
	GROUP BY HVES.ProgramID, HVES.CL_EN_GEN_ID,HVES.CLIENT_CHILD_INJURY_0_PREVENTION) B2C3
	ON C.CLID = B2C3.CL_EN_GEN_ID
	AND C.ProgramID = B2C3.ProgramID

LEFT OUTER JOIN
	(SELECT HVES.CL_EN_GEN_ID, MIN(HVES.SurveyDate) SurveyDate, HVES.ProgramID,HVES.CLIENT_CHILD_INJURY_0_PREVENTION
	FROM Home_Visit_Encounter_Survey HVES
		INNER JOIN Infant_Birth_Survey IB
			ON IB.CL_EN_GEN_ID = HVES.CL_EN_GEN_ID 
			AND IB.ProgramID = HVES.ProgramID
			AND DATEADD(DAY,365.25,IB.INFANT_BIRTH_0_DOB) > HVES.SurveyDate
	WHERE HVES.CLIENT_COMPLETE_0_VISIT = 'COMPLETED'
		AND HVES.CLIENT_CHILD_INJURY_0_PREVENTION IS NOT NULL
		AND HVES.SurveyDate BETWEEN @StartDate AND DATEADD(MONTH,12,@EndDate)
	GROUP BY HVES.ProgramID, HVES.CL_EN_GEN_ID,HVES.CLIENT_CHILD_INJURY_0_PREVENTION) B2C3_BaseLine
	ON C.CLID = B2C3_BaseLine.CL_EN_GEN_ID
	AND C.ProgramID = B2C3_BaseLine.ProgramID
	
LEFT OUTER JOIN
	(SELECT IHS.CL_EN_GEN_ID, MAX(IHS.SurveyDate) SurveyDate, ProgramID,dbo.fnGetFormName(IHS.SurveyID) FormName
	FROM Infant_Health_Survey IHS
	WHERE IHS.INFANT_HEALTH_ER_0_HAD_VISIT = 'Yes' AND IHS.INFANT_HEALTH_ER_1_TYPE LIKE '%INJURY%' 
	AND (dbo.fnGetFormName(IHS.SurveyID) LIKE '%6%')
	AND IHS.SurveyDate <= @EndDate
	GROUP BY ProgramID, IHS.CL_EN_GEN_ID,dbo.fnGetFormName(IHS.SurveyID)) B2C4C1
	ON C.CLID = B2C4C1.CL_EN_GEN_ID
	AND C.ProgramID = B2C4C1.ProgramID
	
LEFT OUTER JOIN
	(SELECT IHS.CL_EN_GEN_ID, MAX(IHS.SurveyDate) SurveyDate, ProgramID,dbo.fnGetFormName(IHS.SurveyID) FormName
	FROM Infant_Health_Survey IHS
	WHERE IHS.INFANT_HEALTH_ER_0_HAD_VISIT = 'Yes' AND IHS.INFANT_HEALTH_ER_1_TYPE LIKE '%INJURY%' 
	AND ( dbo.fnGetFormName(IHS.SurveyID) LIKE '%12%') 
	AND IHS.SurveyDate <= @EndDate
	GROUP BY ProgramID, IHS.CL_EN_GEN_ID,dbo.fnGetFormName(IHS.SurveyID)) B2C4C2
	ON C.CLID = B2C4C2.CL_EN_GEN_ID
	AND C.ProgramID = B2C4C2.ProgramID		
LEFT OUTER JOIN 
	(SELECT HVES.CL_EN_GEN_ID, MIN(HVES.SurveyDate) SurveyDate, ProgramID
	FROM Home_Visit_Encounter_Survey HVES
	WHERE HVES.CLIENT_COMPLETE_0_VISIT = 'Completed'
	AND HVES.SurveyDate BETWEEN @StartDate AND @EndDate 
	GROUP BY ProgramID, HVES.CL_EN_GEN_ID) B2C3D
	ON C.CLID = B2C3D.CL_EN_GEN_ID
	AND B2C3D.SurveyDate <= DATEADD(DAY,365.25,C.ProgramStartDate)
	AND C.ProgramID = B2C3D.ProgramID


LEFT OUTER JOIN
	(SELECT IHS.CL_EN_GEN_ID, MAX(IHS.SurveyDate) SurveyDate, ProgramID
	FROM Infant_Health_Survey IHS
	WHERE (IHS.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL = 'Yes' OR IHS.INFANT_SOCIAL_SERVICES_0_REFERRAL = 'Yes')
		AND dbo.fnGetFormName(IHS.SurveyID) LIKE '%12%'
		AND IHS.SurveyDate BETWEEN @StartDate AND @EndDate
	GROUP BY ProgramID, IHS.CL_EN_GEN_ID) B2C5
	ON c.CLID = B2C5.CL_EN_GEN_ID
	AND c.ProgramID = B2C5.ProgramID
LEFT OUTER JOIN
	(SELECT IHS.CL_EN_GEN_ID, MAX(IHS.SurveyDate) SurveyDate, ProgramID
	FROM Infant_Health_Survey IHS
	WHERE (IHS.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL = 'Yes' OR IHS.INFANT_SOCIAL_SERVICES_0_REFERRAL = 'Yes')
		AND dbo.fnGetFormName(IHS.SurveyID) LIKE '%12%'
		AND IHS.SurveyDate BETWEEN @StartDate AND DATEADD(MONTH,12,@EndDate)
	GROUP BY ProgramID, IHS.CL_EN_GEN_ID) B2C5_BaseLine
	ON c.CLID = B2C5_BaseLine.CL_EN_GEN_ID
	AND c.ProgramID = B2C5_BaseLine.ProgramID


LEFT JOIN 
	(
		SELECT IHS.CL_EN_GEN_ID,MAX(IHS.SurveyDate) SurveyDate, IHS.ProgramID
		FROM Infant_Health_Survey IHS
		WHERE IHS.INFANT_HOME_1_LEARNING IS NOT NULL
			AND dbo.fnGetFormName(IHS.SurveyID) LIKE '%6%'
			AND IHS.SurveyDate <=@EndDate
		GROUP BY IHS.CL_EN_GEN_ID,IHS.ProgramID
	) B3C1
	ON B3C1.CL_EN_GEN_ID = c.CLID
	AND B3C1.ProgramID = c.ProgramID
LEFT JOIN 
	(
		SELECT IHS.CL_EN_GEN_ID,MAX(IHS.SurveyDate) SurveyDate, IHS.ProgramID
		FROM Infant_Health_Survey IHS
		WHERE IHS.INFANT_HOME_1_LEARNING IS NOT NULL
			AND dbo.fnGetFormName(IHS.SurveyID) LIKE '%6%'
			AND IHS.SurveyDate <= DATEADD(MONTH,12,@EndDate)
		GROUP BY IHS.CL_EN_GEN_ID,IHS.ProgramID
	) B3C1_BaseLine
	ON B3C1_BaseLine.CL_EN_GEN_ID = c.CLID
	AND B3C1_BaseLine.ProgramID = c.ProgramID

LEFT JOIN 
	(
		SELECT IHS.CL_EN_GEN_ID,MAX(IHS.SurveyDate) SurveyDate, IHS.ProgramID,MAX(IHS.INFANT_HOME_0_TOTAL) INFANT_HOME_0_TOTAL 
		FROM Infant_Health_Survey IHS
		WHERE IHS.INFANT_HOME_0_TOTAL IS NOT NULL
			AND dbo.fnGetFormName(IHS.SurveyID) LIKE '%6%'
			AND IHS.SurveyDate <= @EndDate
		GROUP BY IHS.CL_EN_GEN_ID,IHS.ProgramID
	) B3C26
	ON B3C26.CL_EN_GEN_ID = C.CLID
	AND B3C26.ProgramID = C.ProgramID


LEFT JOIN 
	(
		SELECT IHS.CL_EN_GEN_ID,MAX(IHS.SurveyDate) SurveyDate, IHS.ProgramID,MAX(IHS.INFANT_HOME_0_TOTAL) INFANT_HOME_0_TOTAL 
		FROM Infant_Health_Survey IHS
		WHERE IHS.INFANT_HOME_0_TOTAL IS NOT NULL
			AND dbo.fnGetFormName(IHS.SurveyID) LIKE '%18%'
			AND IHS.SurveyDate BETWEEN @StartDate AND @EndDate
		GROUP BY IHS.CL_EN_GEN_ID,IHS.ProgramID
	) B3C2T18
	ON B3C2T18.CL_EN_GEN_ID = C.CLID
	AND B3C2T18.ProgramID = C.ProgramID

LEFT JOIN 
	(
		SELECT IHS.CL_EN_GEN_ID,MAX(IHS.SurveyDate) SurveyDate, IHS.ProgramID,MAX(IHS.INFANT_HOME_1_ACCEPTANCE) INFANT_HOME_1_ACCEPTANCE 
			,MAX(IHS.INFANT_HOME_1_RESPONSIVITY) INFANT_HOME_1_RESPONSIVITY
		FROM Infant_Health_Survey IHS
		WHERE IHS.INFANT_HOME_1_ACCEPTANCE IS NOT NULL
			AND IHS.INFANT_HOME_1_RESPONSIVITY IS NOT NULL
			AND dbo.fnGetFormName(IHS.SurveyID) LIKE '%6%'
			AND IHS.SurveyDate <= @EndDate
		GROUP BY IHS.CL_EN_GEN_ID,IHS.ProgramID
	) B3C36
	ON B3C36.CL_EN_GEN_ID = C.CLID
	AND B3C36.ProgramID = C.ProgramID


LEFT JOIN 
	(
		SELECT IHS.CL_EN_GEN_ID,MAX(IHS.SurveyDate) SurveyDate, IHS.ProgramID,MAX(IHS.INFANT_HOME_1_ACCEPTANCE) INFANT_HOME_1_ACCEPTANCE 
			,MAX(IHS.INFANT_HOME_1_RESPONSIVITY) INFANT_HOME_1_RESPONSIVITY
		FROM Infant_Health_Survey IHS
		WHERE IHS.INFANT_HOME_1_ACCEPTANCE IS NOT NULL
			AND IHS.INFANT_HOME_1_RESPONSIVITY IS NOT NULL
			AND dbo.fnGetFormName(IHS.SurveyID) LIKE '%18%'
			AND IHS.SurveyDate BETWEEN @StartDate AND @EndDate
		GROUP BY IHS.CL_EN_GEN_ID,IHS.ProgramID
	) B3C3T18
	ON B3C3T18.CL_EN_GEN_ID = C.CLID
	AND B3C3T18.ProgramID = C.ProgramID

LEFT JOIN 
	(
		SELECT IHS.CL_EN_GEN_ID,MAX(IHS.SurveyDate) SurveyDate, IHS.ProgramID
		FROM Infant_Health_Survey IHS
		WHERE IHS.INFANT_AGES_STAGES_1_COMM IS NOT NULL
			AND IHS.INFANT_HEALTH_NO_ASQ_COMM IS NULL
			AND (dbo.fnGetFormName(IHS.SurveyID) LIKE '%6%'
					OR dbo.fnGetFormName(IHS.SurveyID) LIKE '%12%')
			AND IHS.SurveyDate BETWEEN @StartDate AND @EndDate
		GROUP BY IHS.CL_EN_GEN_ID,IHS.ProgramID
	) B3C5
	ON B3C5.CL_EN_GEN_ID = C.CLID
	AND B3C5.ProgramID = C.ProgramID

LEFT JOIN 
	(
		SELECT IHS.CL_EN_GEN_ID,MAX(IHS.SurveyDate) SurveyDate, IHS.ProgramID
		FROM Infant_Health_Survey IHS
		WHERE (IHS.INFANT_HEALTH_NO_ASQ_COMM IS NULL OR IHS.INFANT_HEALTH_NO_ASQ_COMM = 'Parent declined further screening')
			AND (dbo.fnGetFormName(IHS.SurveyID) LIKE '%6%'
					OR dbo.fnGetFormName(IHS.SurveyID) LIKE '%12%')
			AND IHS.SurveyDate BETWEEN @StartDate AND @EndDate
		GROUP BY IHS.CL_EN_GEN_ID,IHS.ProgramID
	) B3C5D
	ON B3C5D.CL_EN_GEN_ID = C.CLID
	AND B3C5D.ProgramID = C.ProgramID

LEFT JOIN 
	(
		SELECT IHS.CL_EN_GEN_ID,MAX(IHS.SurveyDate) SurveyDate, IHS.ProgramID
		FROM Infant_Health_Survey IHS
		WHERE IHS.INFANT_AGES_STAGES_1_PSOLVE IS NOT NULL
			AND IHS.INFANT_HEALTH_NO_ASQ_PROBLEM IS NULL
			AND IHS.SurveyDate BETWEEN @StartDate AND @EndDate
			AND (dbo.fnGetFormName(IHS.SurveyID) LIKE '%6%'
					OR dbo.fnGetFormName(IHS.SurveyID) LIKE '%12%')
		GROUP BY IHS.CL_EN_GEN_ID,IHS.ProgramID
	) B3C6
	ON B3C6.CL_EN_GEN_ID = C.CLID
	AND B3C6.ProgramID = C.ProgramID

LEFT JOIN 
	(
		SELECT IHS.CL_EN_GEN_ID,MAX(IHS.SurveyDate) SurveyDate, IHS.ProgramID
		FROM Infant_Health_Survey IHS
		WHERE (IHS.INFANT_HEALTH_NO_ASQ_PROBLEM IS NULL OR IHS.INFANT_HEALTH_NO_ASQ_PROBLEM = 'Parent declined further screening')
			AND IHS.SurveyDate BETWEEN @StartDate AND @EndDate
			AND (dbo.fnGetFormName(IHS.SurveyID) LIKE '%6%'
					OR dbo.fnGetFormName(IHS.SurveyID) LIKE '%12%')
		GROUP BY IHS.CL_EN_GEN_ID,IHS.ProgramID
	) B3C6D
	ON B3C6D.CL_EN_GEN_ID = C.CLID
	AND B3C6D.ProgramID = C.ProgramID

LEFT JOIN 
	(
		SELECT IHS.CL_EN_GEN_ID,MAX(IHS.SurveyDate) SurveyDate, IHS.ProgramID
		FROM Infant_Health_Survey IHS
		WHERE IHS.INFANT_AGES_STAGES_1_PSOCIAL IS NOT NULL
			AND IHS.INFANT_HEALTH_NO_ASQ_PERSONAL IS NULL
			AND IHS.SurveyDate BETWEEN @StartDate AND @EndDate
			AND (dbo.fnGetFormName(IHS.SurveyID) LIKE '%6%'
					OR dbo.fnGetFormName(IHS.SurveyID) LIKE '%12%')
		GROUP BY IHS.CL_EN_GEN_ID,IHS.ProgramID
	) B3C7
	ON B3C7.CL_EN_GEN_ID = C.CLID
	AND B3C7.ProgramID = C.ProgramID

LEFT JOIN 
	(
		SELECT IHS.CL_EN_GEN_ID,MAX(IHS.SurveyDate) SurveyDate, IHS.ProgramID
		FROM Infant_Health_Survey IHS
		WHERE (IHS.INFANT_HEALTH_NO_ASQ_PERSONAL IS NULL OR IHS.INFANT_HEALTH_NO_ASQ_PERSONAL = 'Parent declined further screening')
			AND IHS.SurveyDate BETWEEN @StartDate AND @EndDate
			AND (dbo.fnGetFormName(IHS.SurveyID) LIKE '%6%'
					OR dbo.fnGetFormName(IHS.SurveyID) LIKE '%12%')
		GROUP BY IHS.CL_EN_GEN_ID,IHS.ProgramID
	) B3C7D
	ON B3C7D.CL_EN_GEN_ID = C.CLID
	AND B3C7D.ProgramID = C.ProgramID

LEFT JOIN 
	(
		SELECT IHS.CL_EN_GEN_ID,MAX(IHS.SurveyDate) SurveyDate, IHS.ProgramID
		FROM Infant_Health_Survey IHS
		WHERE IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL IS NOT NULL
			AND IHS.INFANT_HEALTH_NO_ASQ_TOTAL IS NULL
			AND IHS.SurveyDate BETWEEN @StartDate AND @EndDate
			AND (dbo.fnGetFormName(IHS.SurveyID) LIKE '%6%'
					OR dbo.fnGetFormName(IHS.SurveyID) LIKE '%12%')
		GROUP BY IHS.CL_EN_GEN_ID,IHS.ProgramID
	) B3C8
	ON B3C8.CL_EN_GEN_ID = C.CLID
	AND B3C8.ProgramID = C.ProgramID

LEFT JOIN 
	(
		SELECT IHS.CL_EN_GEN_ID,MAX(IHS.SurveyDate) SurveyDate, IHS.ProgramID
		FROM Infant_Health_Survey IHS
		WHERE (IHS.INFANT_HEALTH_NO_ASQ_TOTAL IS NULL OR IHS.INFANT_HEALTH_NO_ASQ_TOTAL = 'Parent declined further screening')
			AND IHS.SurveyDate BETWEEN @StartDate AND @EndDate
			AND (dbo.fnGetFormName(IHS.SurveyID) LIKE '%6%'
					OR dbo.fnGetFormName(IHS.SurveyID) LIKE '%12%')
		GROUP BY IHS.CL_EN_GEN_ID,IHS.ProgramID
	) B3C8D
	ON B3C8D.CL_EN_GEN_ID = C.CLID
	AND B3C8D.ProgramID = C.ProgramID

LEFT JOIN 
	(
		SELECT IHS.CL_EN_GEN_ID,MAX(IHS.SurveyDate) SurveyDate, IHS.ProgramID
		FROM Infant_Health_Survey IHS
		WHERE IHS.INFANT_AGES_STAGES_1_GMOTOR IS NOT NULL
			AND IHS.INFANT_AGES_STAGES_1_FMOTOR IS NOT NULL
			AND IHS.INFANT_HEALTH_NO_ASQ_GROSS IS NULL
			AND IHS.INFANT_HEALTH_NO_ASQ_FINE IS NULL
			AND IHS.SurveyDate BETWEEN @StartDate AND @EndDate
			AND (dbo.fnGetFormName(IHS.SurveyID) LIKE '%6%'
					OR dbo.fnGetFormName(IHS.SurveyID) LIKE '%12%')
		GROUP BY IHS.CL_EN_GEN_ID,IHS.ProgramID
	) B3C9
	ON B3C9.CL_EN_GEN_ID = C.CLID
	AND B3C9.ProgramID = C.ProgramID

LEFT JOIN 
	(
		SELECT IHS.CL_EN_GEN_ID,MAX(IHS.SurveyDate) SurveyDate, IHS.ProgramID
		FROM Infant_Health_Survey IHS
		WHERE (IHS.INFANT_HEALTH_NO_ASQ_GROSS IS NULL OR IHS.INFANT_HEALTH_NO_ASQ_GROSS = 'Parent declined further screening')
			AND (IHS.INFANT_HEALTH_NO_ASQ_FINE IS NULL OR IHS.INFANT_HEALTH_NO_ASQ_FINE = 'Parent declined further screening')
			AND IHS.SurveyDate BETWEEN @StartDate AND @EndDate
			AND (dbo.fnGetFormName(IHS.SurveyID) LIKE '%6%'
					OR dbo.fnGetFormName(IHS.SurveyID) LIKE '%12%')
		GROUP BY IHS.CL_EN_GEN_ID,IHS.ProgramID
	) B3C9D
	ON B3C9D.CL_EN_GEN_ID = C.CLID
	AND B3C9D.ProgramID = C.ProgramID
LEFT JOIN 
	(
		SELECT D.CL_EN_GEN_ID, MAX(D.SurveyDate) SurveyDate, D.ProgramID, MAX(CASE 
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%dependent%' THEN 0
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE 'Less than %6%000' THEN 3000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%6%001%9%000' THEN 7500
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%6%001%12%000' THEN 9000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%9%001%12%000' THEN 10500
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%12%001%16%000' THEN 14000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%12%001%20%000' THEN 16000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%16%001%20%000' THEN 18000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%20%001%30%000' THEN 25000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%30%001%40%000' THEN 35000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE 'Over%30%000' THEN 35000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE 'Over%40%000' THEN 45000
						END) [Household Income]
			,dbo.fnGetFormName(D.SurveyID) FormName
		FROM Demographics_Survey D
		WHERE ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) IS NOT NULL 
			AND (dbo.fnGetFormName(D.SurveyID) LIKE '%INTAKE%' AND D.SurveyDate <= @EndDate)
			
		GROUP BY D.CL_EN_GEN_ID, D.ProgramID,dbo.fnGetFormName(D.SurveyID)
	)B5C1T1Int
		ON B5C1T1Int.CL_EN_GEN_ID = C.CLID
		AND B5C1T1Int.ProgramID = C.ProgramID


LEFT JOIN 
	(
		SELECT D.CL_EN_GEN_ID, MAX(D.SurveyDate) SurveyDate, D.ProgramID, MAX(CASE 
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%dependent%' THEN 0
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE 'Less than %6%000' THEN 3000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%6%001%9%000' THEN 7500
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%6%001%12%000' THEN 9000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%9%001%12%000' THEN 10500
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%12%001%16%000' THEN 14000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%12%001%20%000' THEN 16000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%16%001%20%000' THEN 18000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%20%001%30%000' THEN 25000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE '%30%001%40%000' THEN 35000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE 'Over%30%000' THEN 35000
							WHEN ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) LIKE 'Over%40%000' THEN 45000
						END) [Household Income]
			,dbo.fnGetFormName(D.SurveyID) FormName
		FROM Demographics_Survey D
		WHERE ISNULL(D.CLIENT_INCOME_0_HH_INCOME,D.CLIENT_INCOME_AMOUNT) IS NOT NULL 
			AND dbo.fnGetFormName(D.SurveyID) LIKE '%12%' AND D.SurveyDate BETWEEN @StartDate AND @EndDate
			
		GROUP BY D.CL_EN_GEN_ID, D.ProgramID,dbo.fnGetFormName(D.SurveyID)
	)B5C1T112M
		ON B5C1T112M.CL_EN_GEN_ID = C.CLID
		AND B5C1T112M.ProgramID = C.ProgramID
		
LEFT JOIN 
	(
		SELECT D.CL_EN_GEN_ID, MAX(D.SurveyDate) SurveyDate, D.ProgramID
			,MAX(CASE 
				WHEN D.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%Doctorate%' THEN 19
				WHEN D.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%Professional%' THEN 18
				WHEN D.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%Master%' THEN 17
				WHEN D.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%Bachelor%' THEN 16
				WHEN D.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%Associate%' THEN 15
				WHEN D.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%Some%college%' THEN 14				
				WHEN D.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%Vocational%' THEN 13
				WHEN D.CLIENT_EDUCATION_0_HS_GED LIKE '%YES%' THEN 12
				ELSE D.CLIENT_EDUCATION_1_HS_GED_LAST_GRADE
			END) HighestEdLvl
		FROM Demographics_Survey D
		WHERE D.CLIENT_EDUCATION_1_ENROLLED_PLAN = 'Yes' 
			AND dbo.fnGetFormName(D.SurveyID) IN ('Demographics: Pregnancy Intake')
			AND D.SurveyDate <= @EndDate
		GROUP BY D.CL_EN_GEN_ID,D.ProgramID,dbo.fnGetFormName(D.SurveyID)
	) B5C2TInt
	ON B5C2TInt.CL_EN_GEN_ID = C.CLID
	AND B5C2TInt.ProgramID = C.ProgramID

LEFT JOIN 
	(
		SELECT D.CL_EN_GEN_ID, MAX(D.SurveyDate) SurveyDate, D.ProgramID
			,MAX(CASE 
				WHEN D.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%Doctorate%' THEN 19
				WHEN D.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%Professional%' THEN 18
				WHEN D.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%Master%' THEN 17
				WHEN D.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%Bachelor%' THEN 16
				WHEN D.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%Associate%' THEN 15
				WHEN D.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%Some%college%' THEN 14				
				WHEN D.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%Vocational%' THEN 13
				WHEN D.CLIENT_EDUCATION_0_HS_GED LIKE '%YES%' THEN 12
				ELSE D.CLIENT_EDUCATION_1_HS_GED_LAST_GRADE
			END) HighestEdLvl
		FROM Demographics_Survey D
		WHERE D.CLIENT_EDUCATION_1_ENROLLED_PLAN = 'Yes' 
			AND dbo.fnGetFormName(D.SurveyID) IN ('Demographics Update: Infancy 12 Months')
			AND D.SurveyDate <= @EndDate
		GROUP BY D.CL_EN_GEN_ID,D.ProgramID,dbo.fnGetFormName(D.SurveyID)
	) B5C2T12M
	ON B5C2T12M.CL_EN_GEN_ID = C.CLID
	AND B5C2T12M.ProgramID = C.ProgramID
	
WHERE C.ProgramStartDate < = @EndDate
	AND ISNULL(C.EndDate,@EndDate) >= @StartDate
	
	
	
	
	
	
	
	
	
/*
	,COUNT(DISTINCT
			CASE
				WHEN 1
				THEN C.CLID
			END)
			
*/
GO
