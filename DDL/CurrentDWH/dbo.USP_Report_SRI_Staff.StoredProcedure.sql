USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[USP_Report_SRI_Staff]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[USP_Report_SRI_Staff] 
(@StartDate		DATE
	,@EndDate		DATE
	,@ProgramID			VARCHAR(4000)
	--,@Tribal	INT
	)


AS

--DECLARE 
--	@StartDate		DATE
--	,@EndDate		DATE
--	,@ProgramID			VARCHAR(4000)
--SET @StartDate		= CAST('7/1/2013' AS DATE)
--SET @EndDate		= CAST('6/30/2014' AS DATE)
--SET @ProgramID			= '1373'--'1576,971,974,977,983,980,986,989,992,995,998,1887,1001,1004,1007,1010,2010,1013,854,857,1988,860,863,866,1943,869,1922,1925'

DECLARE 
	@rStartDate		DATE
	,@rEndDate		DATE
	,@rTeam			NVARCHAR(4000)
SET @rStartDate		= @StartDate
SET @rEndDate		= @EndDate 
SET @rTeam			= @ProgramID


		SELECT 
			P.StateAbbr State
			,P.StateName [US State]
			,P.StateID
			,P.SiteID Site_ID
			,P.SiteName AGENCY_INFO_0_NAME
			,P.ProgramID
			,P.TeamName Team_Name
			,N.NurseID Entity_Id
			,ROOT.NHVFTE_12 SumFTE
			,CASE WHEN ROOT.NHV = 'NHV' THEN ROOT.NurseID END CountNHV
			,ROOT.NHVFTE_12 HV_FTE
			,CASE WHEN ROOT.NHV = 'NHV' THEN ROOT.NurseID END CountNHV2
			,NULL MissingFTE
			,NULL MissingPosition
			,CASE WHEN ROOT.Edu = 'Doctorate' THEN ROOT.EduNurseID END Doctorate_curr
			,CASE WHEN ROOT.Edu = 'Master''s Degree' THEN ROOT.EduNurseID END Masters_curr
			,CASE WHEN ROOT.Edu = 'Bachelors'' Degree' THEN ROOT.EduNurseID END Bachelors_curr
			,CASE WHEN ROOT.Edu = 'Associate Degrees' THEN ROOT.EduNurseID END Associates_curr
			,CASE WHEN ROOT.Edu = 'Not applicable' THEN ROOT.EduNurseID END NA_curr
			,CASE WHEN ROOT.Edu = 'Diploma' THEN ROOT.EduNurseID END Diploma_curr
			,CASE WHEN ROOT.Edu = 'Missing' THEN ROOT.EduNurseID END Missing_curr
			,ROOT.EduNurseID Total_curr
			,CASE WHEN ROOT.Unit3CompDate IS NOT NULL AND ROOT.NHV = 'NHV' THEN ROOT.NurseID END NHVeduCompleteCount
			,CASE WHEN ROOT.NHVFTE_12 > 0 THEN ROOT.NurseID END NHVeduTotal
			,CASE WHEN ROOT.Unit4CompDate IS NOT NULL AND ROOT.NS = 'NS' THEN ROOT.NurseID END NSeduCompleteCount
			,CASE WHEN ROOT.NSFTE_12 > 0 THEN ROOT.NurseID END NSeduTotal
			,F.ActiveClientsAtEnd clients
			,CASE WHEN ROOT.NHV = 'NHV' THEN ROOT.NurseID END HV_COUNT
			,ROOT.NHVFTE_12 HV_wFLAG_FTE
			,CASE WHEN ROOT.NS = 'NS' THEN ROOT.NurseID END S_Count
			,ROOT.NSFTE_12 S_FTE
			,CASE WHEN ROOT.NS = 'NS' AND ROOT.NSFTE_12 IS NULL THEN ROOT.NurseID END NS_MISSING_FTE



		FROM

			(SELECT 
				N.NurseID
				,N.ProgramID
				,N.NursePrimaryRole
				,N.NurseSecondaryRole
				,CASE WHEN N.NursePrimaryRole = 'Nurse Home Visitor' OR N.NurseSecondaryRole = 'Nurse Home Visitor' 
							OR N.NursePrimaryRole = 'Nurse Supervisor' OR N.NurseSecondaryRole = 'Nurse Supervisor' 
					  THEN 	CASE 
								WHEN NE.Edu = 7 THEN 'Doctorate' 
								WHEN NE.Edu = 6 THEN 'Master''s Degree'
								WHEN NE.Edu = 5 THEN 'Bachelors'' Degree'
								WHEN NE.Edu = 4 THEN 'Associate Degrees'
								WHEN NE.Edu = 3 THEN 'Diploma'
								WHEN NE.Edu = 2 THEN 'Not applicable'
								WHEN NE.Edu = 1 THEN 'Missing' 
							END 
						END Edu
				,CASE WHEN N.NursePrimaryRole = 'Nurse Home Visitor' OR N.NurseSecondaryRole = 'Nurse Home Visitor' 
							OR N.NursePrimaryRole = 'Nurse Supervisor' OR N.NurseSecondaryRole = 'Nurse Supervisor' THEN N.NurseID END EduNurseID
				,CASE WHEN (N.NursePrimaryRole = 'Nurse Home Visitor' OR N.NurseSecondaryRole = 'Nurse Home Visitor') AND 
							(N.NursePrimaryRole <> 'Nurse Supervisor' OR N.NursePrimaryRole IS NULL) AND (N.NurseSecondaryRole <> 'Nurse Supervisor' OR N.NurseSecondaryRole IS NULL) THEN 'NHV' END NHV
				,CASE WHEN N.NursePrimaryRole = 'Nurse Supervisor' OR N.NurseSecondaryRole = 'Nurse Supervisor' THEN 'NS' END NS
				
				,CASE WHEN (N.NursePrimaryRole = 'Nurse Home Visitor' OR N.NurseSecondaryRole = 'Nurse Home Visitor') AND 
							(N.NursePrimaryRole <> 'Nurse Supervisor' OR N.NursePrimaryRole IS NULL) AND (N.NurseSecondaryRole <> 'Nurse Supervisor' OR N.NurseSecondaryRole IS NULL) THEN 'NHV' 
							END NHV_13
				,CASE WHEN (N.NursePrimaryRole = 'Nurse Supervisor' OR N.NurseSecondaryRole = 'Nurse Supervisor') AND 
							(N.NursePrimaryRole <> 'Nurse Home Visitor' OR N.NursePrimaryRole IS NULL) AND (N.NurseSecondaryRole <> 'Nurse Home Visitor' OR N.NurseSecondaryRole IS NULL) THEN 'NHV' 
							END NS_13
				,CASE 
					WHEN (N.NursePrimaryRole = 'Nurse Supervisor' OR N.NurseSecondaryRole = 'Nurse Supervisor') AND
					(N.NursePrimaryRole <> 'Nurse Home Visitor' OR N.NursePrimaryRole IS NULL) AND (N.NurseSecondaryRole <> 'Nurse Home Visitor' OR N.NurseSecondaryRole IS NULL) 
					THEN 
						CASE 
							WHEN N.NursePrimaryRole = 'Nurse Supervisor' THEN N.NursePrimaryRoleFTE
							WHEN N.NurseSecondaryRole = 'Nurse Supervisor' THEN N.NurseSecondaryRoleFTE
						END
				END NSFTE_13
				
				,CASE WHEN N.NursePrimaryRole = 'Nurse Home Visitor' OR N.NurseSecondaryRole = 'Nurse Home Visitor' THEN 'NHV' END NHV_12
				,CASE 
					WHEN N.NursePrimaryRole = 'Nurse Home Visitor' OR N.NurseSecondaryRole = 'Nurse Home Visitor' 
					THEN 
						CASE 
							WHEN N.NursePrimaryRole = 'Nurse Home Visitor' THEN N.NursePrimaryRoleFTE
							WHEN N.NurseSecondaryRole = 'Nurse Home Visitor' THEN N.NurseSecondaryRoleFTE
						END
				END NHVFTE_12
				,CASE 
					WHEN N.NursePrimaryRole = 'Nurse Supervisor' OR N.NurseSecondaryRole = 'Nurse Supervisor' 
					THEN 'NS' 
				END NS_12
				,CASE 
					WHEN N.NursePrimaryRole = 'Nurse Supervisor' OR N.NurseSecondaryRole = 'Nurse Supervisor' 
					THEN 
						CASE 
							WHEN N.NursePrimaryRole = 'Nurse Supervisor' THEN N.NursePrimaryRoleFTE
							WHEN N.NurseSecondaryRole = 'Nurse Supervisor' THEN N.NurseSecondaryRoleFTE
						END
				END NSFTE_12
				,N.Unit3CompDate
				,N.Unit4CompDate
				--,NHV.EffectiveDate NHVStartDate
				--,NS.EffectiveDate NSStartDate
				,DATEDIFF(DAY,NHV.EffectiveDate,@rEndDate) DaysSinceNHVStart
				,DATEDIFF(DAY,NS.EffectiveDate,@rEndDate) DaysSinceNSStart
				,ROW_NUMBER() OVER(PARTITION BY N.NurseID, N.ProgramID ORDER BY N.EffectiveDate DESC) RowNum
				,N.EndFlag
			FROM FactNurseEnrollment N
			LEFT JOIN (SELECT 
							NurseID
							,MAX(CASE 
								WHEN Edu = 'Doctorate' THEN 7 
								WHEN Edu = 'Master''s Degree' THEN 6 
								WHEN Edu = 'Bachelors'' Degree' THEN 5
								WHEN Edu = 'Associate Degrees' THEN 4
								WHEN Edu = 'Diploma' THEN 3 
								WHEN Edu = 'Not applicable' THEN 2 
								WHEN Edu IS NULL THEN 1 
							END) Edu
						FROM FactNurseEnrollment 
						WHERE EffectiveDate < @rEndDate
						GROUP BY NurseID) NE ON N.NurseID = NE.NurseID
			LEFT JOIN (SELECT
							NurseID
							,ProgramID
							,EffectiveDate
							,ROW_NUMBER() OVER(PARTITION BY NurseID, ProgramID ORDER BY EffectiveDate) RowNum 
						FROM FactNurseEnrollment 
						WHERE NursePrimaryRole = 'Nurse Home Visitor' OR NurseSecondaryRole = 'Nurse Home Visitor') NHV 
					ON N.NurseID = NHV.NurseID AND N.ProgramID = NHV.ProgramID AND NHV.RowNum = 1
			LEFT JOIN (SELECT
							NurseID
							,ProgramID
							,EffectiveDate
							,ROW_NUMBER() OVER(PARTITION BY NurseID, ProgramID ORDER BY EffectiveDate) RowNum 
						FROM FactNurseEnrollment 
						WHERE NursePrimaryRole = 'Nurse Supervisor' OR NurseSecondaryRole = 'Nurse Supervisor') NS 
					ON N.NurseID = NS.NurseID AND N.ProgramID = NS.ProgramID AND NS.RowNum = 1
			WHERE N.EffectiveDate < @rEndDate
			) ROOT
		FULL JOIN DimProgramsAndSites P ON ROOT.ProgramID = P.ProgramID
		LEFT JOIN AggFidelity F ON F.GroupID = 1 AND F.ProgramID = P.ProgramID AND F.LastDay = @EndDate
		LEFT JOIN DimNurse N ON ROOT.NurseID = N.NurseID     
		WHERE ROOT.RowNum = 1 AND ROOT.EndFlag IS NULL
		AND (P.ProgramID IN (SELECT * FROM dbo.udf_ParseMultiParam(@rTeam)))
		AND (ROOT.NHV = 'NHV' OR ROOT.NS = 'NS')
GO
