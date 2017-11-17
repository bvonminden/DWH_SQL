USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_MetricsUnit2Education]    Script Date: 11/16/2017 10:44:32 AM ******/
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
CREATE PROCEDURE [dbo].[usp_MetricsUnit2Education]
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

	--First day of month containing RefDate
    DECLARE @FirstDayOfMonth DATETIME
    SET @FirstDayOfMonth = DATEADD(dd, -(DAY(@RefDate)-1), @RefDate)

	----Last Day of Month containing the @RefDate
    DECLARE @LastDayOfMonth DATETIME
	SET @LastDayOfMonth = DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,@RefDate)+1,0))	

	SELECT DISTINCT S.Entity_Id, S.[US State]
	INTO #NHV_Metrics
	FROM 	fn_FID_Staff_list(@StartDate, @RefDate) S 
	INNER JOIN UV_PAS PAS ON S.ProgramID = PAS.ProgramID
	INNER JOIN StaffxClientHx SXCH ON SXCH.Entity_ID = S.Entity_Id
	WHERE (@RefDate BETWEEN S.StartDate AND S.EndDate OR S.EndDate IS NULL) AND (@RefDate BETWEEN SXCH.StartDate AND SXCH.EndDate OR SXCH.EndDate IS NULL) 
	--AND S.[US State] <> 'Oklahoma'
	ORDER BY S.Entity_Id
	
	SELECT ST.US_State, ISNULL(NC.NurseCount, 0) NurseCount
	FROM 
	-- Get a list of all the states for the left joins
	(SELECT DISTINCT [US State] US_State FROM UV_PAS PAS) ST

	LEFT OUTER JOIN
		--Nurse Count NC
		(
		SELECT 
		a.US_State US_STATE,
		 
		COUNT(a.US_State) AS NurseCount FROM 
			( SELECT DISTINCT
			CC.Entity_ID CL_EN_GEN_ID, CC.[Completion_Date] UNIT_2_DT
			,RANK() OVER(Partition By CC.Entity_ID Order By CC.Completion_Date DESC,CC.RecID DESC) Rank, 
			#NHV_Metrics.[US State] AS US_State
			FROM  dbo.UV_Ed_CourseCompleted  CC
			INNER JOIN #NHV_Metrics ON CC.Entity_ID = #NHV_Metrics.Entity_Id
			WHERE CC.Course_ID = 7
			AND CC.Completion_Date BETWEEN @FirstDayOfMonth AND @LastDayOfMonth
			) a
			WHERE a.Rank = 1
			GROUP BY a.US_State 
		) NC
	ON NC.US_STATE = ST.US_State	

	ORDER BY ST.US_State	


	DROP TABLE #NHV_Metrics
END
GO
