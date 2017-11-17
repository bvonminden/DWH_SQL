USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_MetricsNHVCaseload2]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Andrew Grant
-- Create date: 12/24/2014
-- Description:	"Established" nurses are defined as those who completed unit 2 education more than one year before a reference date
--				"New" nurses completed unit 2 education less than one year after the reference date
--              This report partitions new and established nurses based on a parameterized reference date,
--				WHO HAVE CLIENTS on a caseload as of that reference date
--				and displays a count of nurses and their caseloads grouped by state and rolled up nationally.
--				Oklahoma is a special case, because they do not use ETO so there is no client-nurse association for caseload.
--				Oklahoma clients are not included in this dataset; instead, they are counted in a separate stored procedure.
-- =============================================
CREATE PROCEDURE [dbo].[usp_MetricsNHVCaseload2]
	-- Add the parameters for the stored procedure here
	@RefDate DATETIME
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
		DECLARE @StartDate DateTime
SET @StartDate = '1/1/1995'

SELECT DISTINCT S.Entity_Id, S.[US State]
INTO #NHV_Metrics
FROM 	fn_FID_Staff_list(@StartDate, @RefDate) S 
INNER JOIN UV_PAS PAS ON S.ProgramID = PAS.ProgramID
INNER JOIN StaffxClientHx SXCH ON SXCH.Entity_ID = S.Entity_Id
WHERE (@RefDate BETWEEN S.StartDate AND S.EndDate OR S.EndDate IS NULL) AND (@RefDate BETWEEN SXCH.StartDate AND SXCH.EndDate OR SXCH.EndDate IS NULL) 
AND S.[US State] <> 'Oklahoma'
ORDER BY S.Entity_Id



SELECT ST.US_State, ISNULL(NNC.NewNurseCount, 0) NewNurseCount, 
					ISNULL(NNCC.NewNurseCaseloadCount,0) NewNurseCaseloadCount,
					ISNULL(ENC.EstablishedNurseCount, 0) EstablishedNurseCount,
					ISNULL(ENCC.EstablishedNurseCaseloadCount, 0) EstablishedNurseCaseloadCount,
					ISNULL(UC.UnassignedClients, 0) UnassignedClients
					
FROM 
-- Get a list of all the states for the left joins
(SELECT DISTINCT [US State] US_State FROM UV_PAS PAS WHERE PAS.[US State] <> 'Oklahoma') ST

LEFT OUTER JOIN
	--New Nurse Count NNC
	(
	SELECT 
	--Need to set the alias for the rollup grouping
	a.US_State US_STATE,
	 
	COUNT(a.US_State) AS NewNurseCount FROM 
		( SELECT DISTINCT
		CC.Entity_ID CL_EN_GEN_ID, CC.[Completion_Date] UNIT_2_DT
		,RANK() OVER(Partition By CC.Entity_ID Order By CC.Completion_Date DESC,CC.RecID DESC) Rank, 
		#NHV_Metrics.[US State] AS US_State
		FROM  dbo.UV_Ed_CourseCompleted  CC
		INNER JOIN #NHV_Metrics ON CC.Entity_ID = #NHV_Metrics.Entity_Id
		WHERE CC.Course_ID = 7
		AND CC.Completion_Date > DATEADD(yy, -1, @RefDate) 
		) a
		WHERE a.Rank = 1
		GROUP BY a.US_State 
	) NNC
ON NNC.US_STATE = ST.US_State	

LEFT OUTER JOIN
( --New nurse caseload count (NNCC)
SELECT 
	--Need to set the alias for the rollup grouping
	a.US_State AS US_STATE, 
	COUNT(a.US_State) AS NewNurseCaseloadCount FROM 
	( SELECT DISTINCT
		CC.Entity_ID CL_EN_GEN_ID, SCH.CLID, CC.[Completion_Date] UNIT_2_DT
		,RANK() OVER(Partition By CC.Entity_ID Order By CC.Completion_Date DESC,CC.RecID DESC) Rank, 
		PAS.[US State] AS US_State
		FROM  dbo.UV_Ed_CourseCompleted  CC
		INNER JOIN StaffxClientHx SCH ON CC.Entity_ID = SCH.Entity_Id
		INNER JOIN UV_PAS PAS ON SCH.ProgramID = PAS.ProgramID
		WHERE @RefDate > SCH.StartDate AND (@RefDate < SCH.EndDate OR SCH.EndDate IS NULL) 
		AND CC.Course_ID = 7
		AND CC.Completion_Date > DATEADD(yy, -1, @RefDate) 
	) a
		
WHERE a.Rank = 1
GROUP BY a.US_State 
) NNCC
ON ST.US_State = NNCC.US_STATE 


LEFT OUTER JOIN
	--Established Nurse Count (ENC)
	(
	SELECT 
	--Need to set the alias for the rollup grouping
	a.US_State AS US_STATE, 
	COUNT(a.US_State) AS EstablishedNurseCount FROM 
		( SELECT DISTINCT
		CC.Entity_ID CL_EN_GEN_ID, CC.[Completion_Date] UNIT_2_DT
		,RANK() OVER(Partition By CC.Entity_ID Order By CC.Completion_Date DESC,CC.RecID DESC) Rank, 
		#NHV_Metrics.[US State] AS US_State
		FROM  dbo.UV_Ed_CourseCompleted  CC
		INNER JOIN #NHV_Metrics ON CC.Entity_ID = #NHV_Metrics.Entity_Id
		WHERE CC.Course_ID = 7
		AND CC.Completion_Date <= DATEADD(yy, -1, @RefDate) 
		) a
		WHERE a.Rank = 1
		GROUP BY a.US_State 
	) ENC
ON ENC.US_STATE = ST.US_State	

LEFT OUTER JOIN
	--EstablishedNurseCaseloadCount (ENCC)
	(
	SELECT 
	--Need to set the alias for the rollup grouping
	a.US_State AS US_STATE, 
	COUNT(a.US_State) AS EstablishedNurseCaseloadCount FROM 
	( SELECT DISTINCT
		CC.Entity_ID CL_EN_GEN_ID, SCH.CLID, CC.[Completion_Date] UNIT_2_DT
		,RANK() OVER(Partition By CC.Entity_ID Order By CC.Completion_Date DESC,CC.RecID DESC) Rank, 
		PAS.[US State] AS US_State
		FROM  dbo.UV_Ed_CourseCompleted  CC
		INNER JOIN StaffxClientHx SCH ON CC.Entity_ID = SCH.Entity_Id
		INNER JOIN UV_PAS PAS ON SCH.ProgramID = PAS.ProgramID
		WHERE @RefDate > SCH.StartDate AND (@RefDate < SCH.EndDate OR SCH.EndDate IS NULL) 
		AND CC.Course_ID = 7
		AND CC.Completion_Date <= DATEADD(yy, -1, @RefDate) 
	) a
		
		WHERE a.Rank = 1
		GROUP BY a.US_State 
	) ENCC
ON ENCC.US_STATE = ST.US_State	

LEFT OUTER JOIN 	
(
	--This counts enrolled clients with no enrollment end date who are not assigned to an NHV
	SELECT 
	--Need to set the alias for the rollup grouping
	a.US_State 	AS US_STATE,
	COUNT (a.US_STATE) AS UnassignedClients FROM 
	(SELECT DISTINCT 
		EAD.CLID, PAS.[US State] US_STATE, SCH.Entity_ID
		FROM UV_EADT EAD
		INNER JOIN UV_PAS PAS ON PAS.ProgramID = EAD.ProgramID
		LEFT OUTER JOIN StaffxClientHx SCH ON EAD.CLID = SCH.CLID
		WHERE EAD.RankingLatest = 1 AND @RefDate > SCH.StartDate AND (@RefDate < SCH.EndDate OR EAD.EndDate IS NULL)
			AND SCH.Entity_ID IS NULL	 
	) a
	GROUP BY a.US_State 
	) UC
ON UC.US_STATE = ST.US_State

ORDER BY ST.US_State	


DROP TABLE #NHV_Metrics
END
GO
