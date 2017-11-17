USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Element9_NhvNsComplInitialEdu]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_Fid_Element9_NhvNsComplInitialEdu]
(	@StartDate		Date 
	,@EndDate		Date 
	,@Team			VARCHAR(MAX) 
)
AS

If object_id('tempdb..#SurveyDetails9a') is not null
	Drop Table #SurveyDetails9a

If object_id('tempdb..#SurveyDetails9b') is not null
	Drop Table #SurveyDetails9b

If object_id('tempdb..#SurveyDetails9c') is not null
	Drop Table #SurveyDetails9c
			
------===========================================================================================
------for testing

--DECLARE 
--	@StartDate		Date 
--	,@EndDate		Date 
--	,@Team			VARCHAR(MAX)
	
--SET @StartDate		 = CAST('4/1/2014' AS DATE)
--SET @EndDate		 = CAST('3/31/2015' AS DATE)

--------all teams
--SET @Team = '1857,812,1700,1605,1808,1532,872,875,878,1937,911,914,1796,1949,1823,1985,1820,1764,1767,1770,1752,1755,1779,815,1744,818,821,824,1773,830,833,1712,827,836,839,842,845,848,851,962,965,968,884,887,1668,1388,1391,1535,1557,1394,1397,1400,1404,1554,1617,1620,1576,971,974,977,983,980,986,989,992,995,998,1887,1001,1004,1007,1010,2010,1013,854,857,1988,860,863,866,1943,869,1922,1925,1671,881,1928,944,947,1566,1647,1655,1658,1967,1973,1976,1982,2032,1703,1709,893,1894,1860,1761,950,1602,1581,1584,1454,1461,1608,1688,1697,2001,1912,953,1047,1049,1052,1641,1055,1058,956,959,1016,1019,1031,1034,1037,1064,1070,1073,1076,1587,1651,1079,890,920,917,899,1749,1563,1758,1793,2013,1805,1871,1706,935,938,941,896,902,905,1722,908,923,926,1900,1061,1067,1082,1814,1817,1829,1992,1995,1040,1043,1739,1715,1022,1025,1028,1085,1848,1148,1151,1154,1979,1891,1157,1088,1091,1094,1097,1100,1897,1103,1106,1109,1626,1112,1115,1118,1121,1124,1127,1130,1133,1136,1139,1142,1145,1169,1172,1163,1166,1175,1178,1181,1184,1187,1961,1160,1906,1244,929,932,1538,1409,1436,1439,1443,1446,1449,1452,1457,1463,1467,1472,1412,1475,1478,1481,1484,1487,1490,1560,1915,1415,1418,1421,1424,1427,1430,1433,1611,1727,1190,1193,1934,1854,2023,1799,1802,1844,1199,1202,1205,1208,1694,1213,1217,1946,1221,1227,1790,1746,1224,1230,1236,1661,1242,779,780,781,1370,1253,1256,1940,1247,1239,1884,1250,1280,1196,1211,1233,1259,1262,1268,1274,1283,1289,1298,1310,1998,1349,1295,1301,1286,1313,1644,2004,2007,1826,1316,1265,1863,1352,1322,1304,1307,1623,1680,1683,1599,1868,1832,1838,1782,1785,1776,2016,2020,748,1469,1638,1337,1346,1319,1334,1343,1358,1361,1364,1355,1271,1964,1277,1292,1664,1909,1875,1903,1841,1851,1970,1674,1677,1373,1379,1382,1376,1952,1385,1573,1406,1367,1325,1328,1331,1918,1931,1879,1835,1811,1340,1730,1718,1955,1958,2026,1493,1520,1523,1526,1529,1570,1496,1499,1502,1505,1508,1511,1514,1517'

--for testing
------===========================================================================================

----Declare and set variables to parameters so that optimizer skips what is called parameter sniffing
DECLARE 
	@rStartDate		Date 
	,@rEndDate		Date 
	,@rTeam			VARCHAR(max)
SET @rStartDate		= @StartDate
SET @rEndDate		= @EndDate
SET @rTeam			= @Team

------===========================================================================================
----split multi parameters into table
DECLARE @TeamTable TABLE(Value BIGINT) 
DECLARE @xt XML  
SELECT @xt = CAST('<A>'+ REPLACE(@rTeam,',','</A><A>')+ '</A>' AS XML) 
INSERT INTO @TeamTable             
SELECT t.value('.', 'int') AS inVal 
FROM @xt.nodes('/A') AS xt(t) 
----------------------------------------------------------------------------------------------
DECLARE	@LastSymp INT
SET @LastSymp = (	SELECT YEAR(MAX(ed.[Completion_Date])) ANNUAL_DT
					FROM dbo.UV_Ed_CourseCompleted ed
					WHERE ed.Course_ID = 1
						AND ed.Completion_Date <= @EndDate )


;WITH StfInfo AS
(	------from fn_FID_Staff_list & from fn_Fidelity_Staff_El9	
	SELECT
		stf.Entity_Id
		,stf.ProgramID
		,stf.Full_Name
		,stf.StartDate
		,stf.EndDate
		,stf.HireDate
		,CASE WHEN stf.HV_FTE > 0 OR stf.NHV_Flag > 0 THEN 1 ELSE NULL END NhvFte
		,CASE WHEN stf.S_FTE > 0 OR stf.NS_Flag > 0 THEN 1 ELSE NULL END NsFte
		
		,NHV_Hire_Date NHVStartDate
		,NS_Hire_Date NSStartDate
		
		,CASE	----NHV
			WHEN (latestcourse.Unit3DT IS NULL) AND (stf.HV_FTE > 0 OR stf.NHV_Flag > 0)
				AND ISNULL(NHV_Hire_Date,	CASE WHEN (stf.HV_FTE > 0 OR stf.NHV_Flag > 0) 
												THEN ISNULL(stf.HireDate,stf.StartDate) 
											END
							) IS NOT NULL
					THEN DATEDIFF(MONTH, ISNULL(NHV_Hire_Date,	CASE WHEN (stf.HV_FTE > 0 OR stf.NHV_Flag > 0) 
																	THEN ISNULL(stf.HireDate,stf.StartDate) 
																END),@rEndDate
								)
					ELSE NULL
			END NhvMonths
		,CASE	----NS
			WHEN (latestcourse.Unit4DT IS NULL) AND (stf.S_FTE > 0 OR stf.NS_Flag > 0)
				AND ISNULL(NS_Hire_Date,
							CASE WHEN (stf.S_FTE > 0 OR stf.NS_Flag > 0) 
									THEN ISNULL(stf.HireDate,stf.StartDate) 
							END) IS NOT NULL
					THEN DATEDIFF(MONTH,ISNULL(NS_Hire_Date,
								CASE WHEN (stf.S_FTE > 0 OR stf.NS_Flag > 0) THEN ISNULL(stf.HireDate,stf.StartDate) END),@rEndDate)
					ELSE NULL
			END NsMonths
		
		----Legacy completion date will be in both UNIT_3_DT and UNIT_4_DT, only way to decide which it should be is to look at whether NHV or NS
		,CASE	
			WHEN (LatestCourse.UNIT3or4DT IS NULL) --AND (stf.HV_FTE > 0 OR stf.NHV_Flag > 0) AND (stf.S_FTE = 0 AND stf.NS_Flag = 0)
				THEN LatestCourse.Unit3DT	
			WHEN (LatestCourse.UNIT3or4DT IS NOT NULL) AND (stf.HV_FTE > 0 OR stf.NHV_Flag > 0) AND ( (stf.S_FTE = 0 OR stf.S_FTE IS NULL) AND (stf.NS_Flag = 0 OR stf.NS_Flag IS NULL) )--when legacy and NHV then Unit3DT
				THEN
					CASE WHEN (LatestCourse.UNIT3or4DT > LatestCourse.UNIT3DT) OR (LatestCourse.UNIT3DT IS NULL) --if legacy and both dates are present, take the later of the two
						THEN LatestCourse.UNIT3or4DT		
						ELSE LatestCourse.UNIT3DT
					END
		END Unit3DT
		,CASE 
			WHEN (LatestCourse.UNIT3or4DT IS NULL) --AND (stf.S_FTE > 0 OR stf.NS_Flag > 0)
				THEN LatestCourse.Unit4DT				
			WHEN (LatestCourse.UNIT3or4DT IS NOT NULL) AND (stf.S_FTE > 0 OR stf.NS_Flag > 0) --when legacy and NS then Unit4DT
				THEN
					CASE WHEN (LatestCourse.UNIT3or4DT > LatestCourse.UNIT4DT) OR (LatestCourse.UNIT4DT IS NULL)	--if legacy and both dates are present, take the later of the two
						THEN LatestCourse.UNIT3or4DT		
						ELSE LatestCourse.UNIT4DT
					END		
		END Unit4DT
		,LatestCourse.AnnualDT
			
	FROM dbo.fn_FID_Staff_list (@rStartDate,@rEndDate) stf

	LEFT OUTER JOIN ----NHV AND NS earliest hire date, entity/agency level, Staff_Update_Survey & New_Hire_Survey
		(SELECT 
			NhvNs_St.CL_EN_GEN_ID
			,NhvNs_St.SiteID
			,MIN(NhvNs_St.NHV_Hire_Date) NHV_Hire_Date
			,MIN(NhvNs_St.NS_Hire_Date) NS_Hire_Date
		 FROM 
			(SELECT 
				SUS.CL_EN_GEN_ID
				,SUS.SiteID
				,CASE 
					WHEN (SUS.NURSE_PROFESSIONAL_1_NEW_ROLE = 'Nurse Home Visitor' OR SUS.NURSE_PROFESSIONAL_1_HOME_VISITOR_FTE > 0)
						THEN ISNULL(SUS.NURSE_STATUS_0_CHANGE_START_DATE,SUS.SurveyDate)
				END NHV_Hire_Date
				,CASE 
					WHEN (SUS.NURSE_PROFESSIONAL_1_NEW_ROLE = 'Nurse Supervisor' OR SUS.NURSE_PROFESSIONAL_1_SUPERVISOR_FTE > 0)
						THEN ISNULL(SUS.NURSE_STATUS_0_CHANGE_START_DATE,SUS.SurveyDate)
				END NS_Hire_Date
			FROM Staff_Update_Survey SUS
			WHERE (	(SUS.NURSE_PROFESSIONAL_1_NEW_ROLE = 'Nurse Home Visitor' OR SUS.NURSE_PROFESSIONAL_1_HOME_VISITOR_FTE > 0)
				OR (SUS.NURSE_PROFESSIONAL_1_NEW_ROLE = 'Nurse Supervisor' OR SUS.NURSE_PROFESSIONAL_1_SUPERVISOR_FTE > 0) )
				AND SUS.SurveyDate <= @rEndDate

			UNION

			SELECT 
				NHS.CL_EN_GEN_ID
				,NHS.SiteID
				,CASE 
					WHEN NHS.NEW_HIRE_1_ROLE = 'Nurse Home Visitor' 
						THEN ISNULL(NHS.NEW_HIRE_0_HIRE_DATE,NHS.SurveyDate)
				END NHV_Hire_Date
				,CASE 
					WHEN NHS.NEW_HIRE_1_ROLE = 'Nurse Supervisor'
						THEN ISNULL(NHS.NEW_HIRE_0_HIRE_DATE,NHS.SurveyDate)
				END NS_Hire_Date
			FROM New_Hire_Survey NHS
			WHERE (	(NHS.NEW_HIRE_1_ROLE = 'Nurse Home Visitor'
				OR NHS.NEW_HIRE_1_ROLE = 'Nurse Supervisor') )
				AND NHS.SurveyDate <= @rEndDate
		) NhvNs_St
		 WHERE (NhvNs_St.NHV_Hire_Date IS NOT NULL 
			OR NhvNs_St.NS_Hire_Date IS NOT NULL)
		 GROUP BY NhvNs_St.CL_EN_GEN_ID
				,NhvNs_St.SiteID
	) NhvNs_Start 
		ON NhvNs_Start.CL_EN_GEN_ID = stf.Entity_Id 
		AND NhvNs_Start.SiteID = stf.SiteID  

	LEFT OUTER JOIN ----NHV Unit 3 AND NS Unit 4/Annual UV_Ed_CourseCompleted
		(SELECT 
			COURSE.CL_EN_GEN_ID
			,MAX(COURSE.UNIT_3_DT) Unit3DT			----to get all 4 dates on to 1 record
			,MAX(COURSE.UNIT_4_DT) Unit4DT			----to get all 4 dates on to 1 record
			,MAX(COURSE.UNIT_3or4_DT) Unit3or4DT	----to get all 4 dates on to 1 record
			,MAX(COURSE.ANNUAL_DT) AnnualDT			----to get all 4 dates on to 1 record
		FROM
			(	
					SELECT 
					ED.Entity_ID CL_EN_GEN_ID
					,ED.CourseName
					,CASE WHEN ED.Course_ID = 6
							THEN ED.[Completion_Date] 
					END UNIT_3_DT 
					,CASE WHEN ED.Course_ID = 2
							THEN ED.[Completion_Date] 
					END UNIT_4_DT 
					,CASE 
						WHEN ED.Course_ID IS NULL ----legacy
							THEN ED.[Completion_Date] 				
					END UNIT_3or4_DT ----could be Unit 3 or Unit 4, if entity = NHV then Unit 3, if entity = NS then Unit 4
					,CASE WHEN ED.Course_ID = 1
							THEN ED.[Completion_Date] 
					END ANNUAL_DT ----Symposium
					,CASE WHEN ED.Course_ID = 6
						THEN RANK() OVER(Partition By ED.Entity_ID, ED.Course_ID Order By ED.Completion_Date DESC,ED.RecID DESC)
					END RankUnit3				
					,CASE WHEN ED.Course_ID = 2
						THEN RANK() OVER(Partition By ED.Entity_ID, ED.Course_ID Order By ED.Completion_Date DESC,ED.RecID DESC)
					END RankUnit4				
					,CASE WHEN ED.CourseName = 'LEGACY'
						THEN RANK() OVER(Partition By ED.Entity_ID, ED.CourseName Order By ED.Completion_Date DESC,ED.RecID DESC)
					END RankUnit3or4
					,CASE WHEN ED.Course_ID = 1
						THEN RANK() OVER(Partition By ED.Entity_ID, ED.Course_ID Order By ED.Completion_Date DESC,ED.RecID DESC)
					END RankAnnual
				FROM  dbo.UV_Ed_CourseCompleted ED
				WHERE (ED.Course_ID IN (6, 2, 1)	OR ED.CourseName = 'LEGACY'	)	--Course ID 6 = Unit 3, --Course ID 2 = Sup Unit 4, --Course ID 1 = Symposium					
					AND ED.Completion_Date <= @rEndDate
			)COURSE
			WHERE (RankUnit3 = 1
					OR RankUnit4 = 1
					OR RankUnit3or4 = 1
					OR RankAnnual = 1)				
			GROUP BY COURSE.CL_EN_GEN_ID
		)LatestCourse ON LatestCourse.CL_EN_GEN_ID = stf.Entity_Id
		
----from fn_FID_Staff_list &  from fn_Fidelity_Staff_El9
) --end cte

------------=================================================================================
-----#SurveyDetails9a will contain the initial education details
-----#SurveyDetails9b will add row numbers for the various counts in order to calculate aggregates
-----#SurveyDetails9c will calculate aggregates
SELECT 
	pas.Abbreviation StateAbbr
	,pas.[US State] [State]
	,pas.StateID
	,pas.SiteID
	,pas.Site SiteName
	,pas.ProgramID
	,CASE 
		WHEN pas.Team_Name IS NOT NULL
			THEN pas.Team_Name
		WHEN pas.Team_Name IS NULL AND pas.ProgramName like '%Nurse Home Visiting-%'
			THEN 
				REPLACE(
					REPLACE(pas.ProgramName, SUBSTRING(pas.ProgramName,1,CHARINDEX('-',pas.ProgramName)), '' ) ---replace text up to 1st dash in program name with nothing
						,'Nurse Home Visiting-','') ---replace 'Nurse Home Visiting-' in the program name with nothing
		WHEN pas.Team_Name IS NULL AND pas.ProgramName like '%Referral and Intake-%'
			THEN 
				REPLACE(
					REPLACE(pas.ProgramName, SUBSTRING(pas.ProgramName,1,CHARINDEX('-',pas.ProgramName)), '' ) ---replace text up to 1st dash in program name with nothing
						,'Referral and Intake-','') ---replace 'Referral and Intake-' in program name with nothing
		WHEN pas.Team_Name IS NULL AND pas.ProgramName like '%Staff Supervision-%'
			THEN 
				REPLACE(
					REPLACE(pas.ProgramName, SUBSTRING(pas.ProgramName,1,CHARINDEX('-',pas.ProgramName)), '' ) ---replace text up to 1st dash in program name with nothing
						,'Staff Supervision-','') ---replace 'Staff Supervision-' in program name with nothing
			ELSE NULL ----if NULL, then whatever program this is will need to be looked into
		END TeamName
	,1 NationalID
	,'National' NationalName
		
	,stf.Entity_Id
	,MAX(	CASE WHEN stf.EndDate IS NULL OR stf.EndDate > @rEndDate ----active during reporting period
			  THEN
				CASE 
					WHEN stf.Unit3DT IS NOT NULL	----Unit 3 complete
						AND stf.NhvFte IS NOT NULL	
						AND stf.NhvFte > 0			----NHV FTE
						AND stf.NsFte IS NULL		----and not NS FTE
					THEN  stf.Entity_Id
				END
			END) NHVEduComplete

	,MAX(	CASE WHEN stf.EndDate IS NULL OR stf.EndDate > @rEndDate ----active during reporting period
			  THEN
				CASE 
					WHEN stf.NhvFte IS NOT NULL
						AND stf.NhvFte > 0			----NHV FTE
						AND stf.NsFte IS NULL		----and not NS FTE
					THEN  stf.Entity_Id
				END
			END) NHVEduTotal
	
	,MAX(	CASE WHEN stf.EndDate IS NULL OR stf.EndDate > @rEndDate ----active during reporting period
			  THEN
				CASE 
					WHEN stf.Unit3DT IS NULL		----Unit 3 not complete
						AND stf.NhvMonths >9			----NHV more than 9 months
						AND stf.NhvFte IS NOT NULL	----NHV FTE
						AND stf.NhvFte > 0
						AND stf.NsFte IS NULL		----and not NS FTE
					THEN  stf.Entity_Id
				END
			END) NHVEduEligible
					
	,MAX(	CASE WHEN stf.EndDate IS NULL OR stf.EndDate > @rEndDate ----active during reporting period
			  THEN
				CASE 
					WHEN stf.Unit3DT IS NULL		----Unit 3 not complete
						AND stf.NhvMonths <= 9		----NHV 9 months or less
						AND stf.NhvFte IS NOT NULL	----NHV FTE
						AND stf.NhvFte > 0
						AND stf.NsFte IS NULL		----and not NS FTE
					THEN  stf.Entity_Id
				END
			END) NHVEduPotential

	,MAX(	CASE WHEN stf.EndDate IS NULL OR stf.EndDate > @rEndDate ----active during reporting period
			  THEN
				CASE 
					WHEN  stf.Unit4DT IS NOT NULL	----Unit 4 complete
						AND stf.NsFte IS NOT NULL	----NS FTE
						AND stf.NsFte > 0
					THEN  stf.Entity_Id
				END
			END) NSEduComplete
			
	,MAX(	CASE WHEN stf.EndDate IS NULL OR stf.EndDate > @rEndDate ----active during reporting period
			  THEN
				CASE 
					WHEN stf.NsFte IS NOT NULL		----NS FTE
						AND stf.NsFte > 0
					THEN  stf.Entity_Id
				END
			END) NSEduTotal
							
	,MAX(	CASE WHEN stf.EndDate IS NULL OR stf.EndDate > @rEndDate ----active during reporting period
			  THEN
				CASE 
					WHEN stf.Unit4DT IS NULL		----Unit 4 not complete
						AND stf.NsMonths > 7			----NS more than 7 months
						AND stf.NsFte IS NOT NULL	----NS FTE
						AND stf.NsFte > 0
					THEN  stf.Entity_Id
				END
			END) NSEduEligible

	,MAX(	CASE WHEN stf.EndDate IS NULL OR stf.EndDate > @rEndDate ----active during reporting period
			  THEN
				CASE 
					WHEN stf.Unit4DT IS NULL		----Unit 4 not complete
						AND stf.NsMonths <= 7		----7 months or less
						AND stf.NsFte IS NOT NULL	----NS FTE
						AND stf.NsFte > 0
					THEN  stf.Entity_Id
				END
			END) NSEduPotential

	,MAX(	CASE WHEN stf.EndDate IS NULL OR stf.EndDate > @rEndDate ----active during reporting period
			  THEN
				CASE 
					WHEN YEAR(stf.AnnualDt) = @LastSymp	----year of NS last symposium = latest NFP symposium
						AND stf.NsFte IS NOT NULL		----NS FTE
						AND stf.NsFte > 0
					THEN  stf.Entity_Id
				END
			END) NSEduAnnual
	
	,MAX(	CASE WHEN stf.EndDate IS NULL OR stf.EndDate > @rEndDate ----active during reporting period
			  THEN
				CASE 
					WHEN ((stf.Unit4Dt BETWEEN CAST('5/31/'+CAST(@LastSymp-1 AS VARCHAR) AS DATE)	----Unit 4 completed between last 2 symposiums
							AND CAST('5/31/'+CAST(@LastSymp AS VARCHAR) AS DATE))					----or year of Unit 4 = year of last symposium
							OR YEAR(stf.Unit4Dt) = YEAR(@LastSymp))
						AND (YEAR(stf.AnnualDt) <> @LastSymp OR stf.AnnualDt IS NULL)		----and year of NS annual <> year of last NFP symposium OR NS annual not complete
						AND stf.Unit4Dt IS NOT NULL										----Unit 4 DT complete
						AND stf.NsFte IS NOT NULL										----NS FTE
						AND stf.NsFte > 0
					THEN  stf.Entity_Id
				END
			END) NSEduAnnualNotEligible
			
	,MAX(	CASE WHEN stf.EndDate IS NULL OR stf.EndDate > @rEndDate ----active during reporting period
			  THEN
				CASE 
					WHEN (stf.Unit4Dt NOT BETWEEN CAST('5/31/'+CAST(@LastSymp-1 AS VARCHAR) AS DATE)	----Unit 4 completed between last 2 symposiums
							AND CAST('5/31/'+CAST(@LastSymp AS VARCHAR) AS DATE)						----or Unit 4 not complete
							OR stf.Unit4Dt IS NULL)
						AND (YEAR(stf.AnnualDt) <> @LastSymp OR stf.AnnualDt IS NULL)		----and year of NS annual <> year of last NFP symposium OR NS annual date blank
						AND stf.NsFte IS NOT NULL										----NS FTE
						AND stf.NsFte > 0
					THEN stf.Entity_Id
				END
			END) NSEduAnnualMissing				

INTO #SurveyDetails9a
																						
FROM StfInfo stf
	INNER JOIN UV_PAS pas ON pas.ProgramID = stf.ProgramID

GROUP BY
	pas.Abbreviation
	,pas.[US State]
	,pas.StateID
	,pas.SiteID
	,pas.Site
	,pas.ProgramID
	,CASE 
		WHEN pas.Team_Name IS NOT NULL
			THEN pas.Team_Name
		WHEN pas.Team_Name IS NULL AND pas.ProgramName like '%Nurse Home Visiting-%'
			THEN 
				REPLACE(
					REPLACE(pas.ProgramName, SUBSTRING(pas.ProgramName,1,CHARINDEX('-',pas.ProgramName)), '' ) ---replace text up to 1st dash in program name with nothing
						,'Nurse Home Visiting-','') ---replace 'Nurse Home Visiting-' in the program name with nothing
		WHEN pas.Team_Name IS NULL AND pas.ProgramName like '%Referral and Intake-%'
			THEN 
				REPLACE(
					REPLACE(pas.ProgramName, SUBSTRING(pas.ProgramName,1,CHARINDEX('-',pas.ProgramName)), '' ) ---replace text up to 1st dash in program name with nothing
						,'Referral and Intake-','') ---replace 'Referral and Intake-' in program name with nothing
		WHEN pas.Team_Name IS NULL AND pas.ProgramName like '%Staff Supervision-%'
			THEN 
				REPLACE(
					REPLACE(pas.ProgramName, SUBSTRING(pas.ProgramName,1,CHARINDEX('-',pas.ProgramName)), '' ) ---replace text up to 1st dash in program name with nothing
						,'Staff Supervision-','') ---replace 'Staff Supervision-' in program name with nothing
			ELSE NULL ----if NULL, then whatever program this is will need to be looked into
		END

	,stf.Entity_Id

------===========================================================================================
-----#SurveyDetails9b will add row numbers - this can be done in previous step, but would look really messy---this only adds 1 second to the run time, so prefer to do this way
-----#SurveyDetails9c will calculate aggregates

SELECT #SurveyDetails9a.*
	----row numbers to be used in aggregates in order to calculate distinct count of ids
	
	----NHV
	,Row_Number() OVER(Partition By Entity_ID, NHVEduComplete Order By Entity_ID) RowNurseCompleteNHV
	,Row_Number() OVER(Partition By Entity_ID, NHVEduEligible Order By Entity_ID) RowNurseEligibleNHV
	,Row_Number() OVER(Partition By Entity_ID, NHVEduPotential Order By Entity_ID) RowNursePotentialNHV
	,Row_Number() OVER(Partition By Entity_ID, NHVEduTotal Order By Entity_ID) RowNurseTotalNHV
	----NS
	,Row_Number() OVER(Partition By Entity_ID, NSEduComplete Order By Entity_ID) RowNurseCompleteNS
	,Row_Number() OVER(Partition By Entity_ID, NSEduEligible Order By Entity_ID) RowNurseEligibleNS
	,Row_Number() OVER(Partition By Entity_ID, NSEduPotential Order By Entity_ID) RowNursePotentialNS
	,Row_Number() OVER(Partition By Entity_ID, NSEduTotal Order By Entity_ID) RowNurseTotalNS
	----NS Annual
	,Row_Number() OVER(Partition By Entity_ID, NSEduAnnual Order By Entity_ID) RowNurseNSAnnual
	,Row_Number() OVER(Partition By Entity_ID, NSEduAnnualNotEligible Order By Entity_ID) RowNurseNotEligibleNSAnnual
	,Row_Number() OVER(Partition By Entity_ID, NSEduAnnualMissing Order By Entity_ID) RowNurseMissingNSAnnual

INTO #SurveyDetails9b

FROM #SurveyDetails9a

--------===========================================================================================
-----#SurveyDetails9c will calculate aggregates

SELECT #SurveyDetails9b.*

	------aggregates	
	
	------NHV
	------National
	,SUM(CASE WHEN NHVEduComplete IS NOT NULL AND RowNurseCompleteNHV = 1 THEN 1 ELSE 0 END) OVER() NationalEduCompleteNHV
	,SUM(CASE WHEN NHVEduEligible IS NOT NULL AND RowNurseEligibleNHV = 1 THEN 1 ELSE 0 END) OVER() NationalEduEligibleNHV
	,SUM(CASE WHEN NHVEduPotential IS NOT NULL AND RowNursePotentialNHV = 1 THEN 1 ELSE 0 END) OVER() NationalEduPotentialNHV
	,SUM(CASE WHEN NHVEduTotal IS NOT NULL AND RowNurseTotalNHV = 1 THEN 1 ELSE 0 END) OVER() NationalEduTotalNHV
	------State
	,SUM(CASE WHEN NHVEduComplete IS NOT NULL AND RowNurseCompleteNHV = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY StateID) StateEduCompleteNHV
	,SUM(CASE WHEN NHVEduEligible IS NOT NULL AND RowNurseEligibleNHV = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY StateID) StateEduEligibleNHV
	,SUM(CASE WHEN NHVEduPotential IS NOT NULL AND RowNursePotentialNHV = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY StateID) StateEduPotentialNHV
	,SUM(CASE WHEN NHVEduTotal IS NOT NULL AND RowNurseTotalNHV = 1 THEN 1 ELSE 0 END)
		OVER (PARTITION BY StateID) StateEduTotalNHV
	------Agency
	,SUM(CASE WHEN NHVEduComplete IS NOT NULL AND RowNurseCompleteNHV = 1 THEN 1 ELSE 0 END)  
		OVER (PARTITION BY StateID, SiteID) AgencyEduCompleteNHV
	,SUM(CASE WHEN NHVEduEligible IS NOT NULL AND RowNurseEligibleNHV = 1 THEN 1 ELSE 0 END)
		OVER (PARTITION BY StateID, SiteID) AgencyEduEligibleNHV
	,SUM(CASE WHEN NHVEduPotential IS NOT NULL AND RowNursePotentialNHV = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY StateID, SiteID) AgencyEduPotentialNHV
	,SUM(CASE WHEN NHVEduTotal IS NOT NULL AND RowNurseTotalNHV = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY StateID, SiteID) AgencyEduTotalNHV
	------Team
	,SUM(CASE WHEN NHVEduComplete IS NOT NULL THEN 1 ELSE 0 END)  
		OVER (PARTITION BY StateID, SiteID, ProgramID) TeamEduCompleteNHV
	,SUM(CASE WHEN NHVEduEligible IS NOT NULL THEN 1 ELSE 0 END)
		OVER (PARTITION BY StateID, SiteID, ProgramID) TeamEduEligibleNHV
	,SUM(CASE WHEN NHVEduPotential IS NOT NULL THEN 1 ELSE 0 END) 
		OVER (PARTITION BY StateID, SiteID, ProgramID) TeamEduPotentialNHV
	,SUM(CASE WHEN NHVEduTotal IS NOT NULL THEN 1 ELSE 0 END) 
		OVER (PARTITION BY StateID, SiteID, ProgramID) TeamEduTotalNHV

	------NS
	------National	
	,SUM(CASE WHEN NSEduComplete IS NOT NULL AND RowNurseCompleteNS = 1 THEN 1 ELSE 0 END) OVER() NationalEduCompleteNS
	,SUM(CASE WHEN NSEduEligible IS NOT NULL AND RowNurseEligibleNS = 1 THEN 1 ELSE 0 END) OVER() NationalEduEligibleNS
	,SUM(CASE WHEN NSEduPotential IS NOT NULL AND RowNursePotentialNS = 1 THEN 1 ELSE 0 END) OVER() NationalEduPotentialNS
	,SUM(CASE WHEN NSEduTotal IS NOT NULL AND RowNurseTotalNS = 1 THEN 1 ELSE 0 END) OVER() NationalEduTotalNS
	------State
	,SUM(CASE WHEN NSEduComplete IS NOT NULL AND RowNurseCompleteNS = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY StateID) StateEduCompleteNS
	,SUM(CASE WHEN NSEduEligible IS NOT NULL AND RowNurseEligibleNS = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY StateID) StateEduEligibleNS
	,SUM(CASE WHEN NSEduPotential IS NOT NULL AND RowNursePotentialNS = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY StateID) StateEduPotentialNS
	,SUM(CASE WHEN NSEduTotal IS NOT NULL AND RowNurseTotalNS = 1 THEN 1 ELSE 0 END)
		OVER (PARTITION BY StateID) StateEduTotalNS
	-------Agency
	,SUM(CASE WHEN NSEduComplete IS NOT NULL AND RowNurseCompleteNS = 1 THEN 1 ELSE 0 END)  
		OVER (PARTITION BY StateID, SiteID) AgencyEduCompleteNS
	,SUM(CASE WHEN NSEduEligible IS NOT NULL AND RowNurseEligibleNS = 1 THEN 1 ELSE 0 END)
		OVER (PARTITION BY StateID, SiteID) AgencyEduEligibleNS
	,SUM(CASE WHEN NSEduPotential IS NOT NULL AND RowNursePotentialNS = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY StateID, SiteID) AgencyEduPotentialNS
	,SUM(CASE WHEN NSEduTotal IS NOT NULL AND RowNurseTotalNS = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY StateID, SiteID) AgencyEduTotalNS
	--------Team
	,SUM(CASE WHEN NSEduComplete IS NOT NULL THEN 1 ELSE 0 END)  
		OVER (PARTITION BY StateID, SiteID, ProgramID) TeamEduCompleteNS
	,SUM(CASE WHEN NSEduEligible IS NOT NULL THEN 1 ELSE 0 END)
		OVER (PARTITION BY StateID, SiteID, ProgramID) TeamEduEligibleNS
	,SUM(CASE WHEN NSEduPotential IS NOT NULL THEN 1 ELSE 0 END) 
		OVER (PARTITION BY StateID, SiteID, ProgramID) TeamEduPotentialNS
	,SUM(CASE WHEN NSEduTotal IS NOT NULL THEN 1 ELSE 0 END) 
		OVER (PARTITION BY StateID, SiteID, ProgramID) TeamEduTotalNS

	------NS Annual
	------National	
	,SUM(CASE WHEN NSEduAnnual IS NOT NULL AND RowNurseNSAnnual = 1 THEN 1 ELSE 0 END) OVER() NationalEduNSAnnual
	,SUM(CASE WHEN NSEduAnnualNotEligible IS NOT NULL AND RowNurseNotEligibleNSAnnual = 1 THEN 1 ELSE 0 END) OVER() NationalEduNotEligibleNSAnnual
	,SUM(CASE WHEN NSEduAnnualMissing IS NOT NULL AND RowNurseMissingNSAnnual = 1 THEN 1 ELSE 0 END) OVER() NationalEduMissingNSAnnual
	--------State
	,SUM(CASE WHEN NSEduAnnual IS NOT NULL AND RowNurseNSAnnual = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY StateID) StateEduNSAnnual
	,SUM(CASE WHEN NSEduAnnualNotEligible IS NOT NULL AND RowNurseNotEligibleNSAnnual = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY StateID) StateEduNotEligibleNSAnnual
	,SUM(CASE WHEN NSEduAnnualMissing IS NOT NULL AND RowNurseMissingNSAnnual = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY StateID) StateEduMissingNSAnnual
	------Agency
	,SUM(CASE WHEN NSEduAnnual IS NOT NULL AND RowNurseNSAnnual = 1 THEN 1 ELSE 0 END)  
		OVER (PARTITION BY StateID, SiteID) AgencyEduNSAnnual
	,SUM(CASE WHEN NSEduAnnualNotEligible IS NOT NULL AND RowNurseNotEligibleNSAnnual = 1 THEN 1 ELSE 0 END)
		OVER (PARTITION BY StateID, SiteID) AgencyEduNotEligibleNSAnnual
	,SUM(CASE WHEN NSEduAnnualMissing IS NOT NULL AND RowNurseMissingNSAnnual = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY StateID, SiteID) AgencyEduMissingNSAnnual
	------Team
	,SUM(CASE WHEN NSEduAnnual IS NOT NULL THEN 1 ELSE 0 END)  
		OVER (PARTITION BY StateID, SiteID, ProgramID) TeamEduNSAnnual
	,SUM(CASE WHEN NSEduAnnualNotEligible IS NOT NULL THEN 1 ELSE 0 END)
		OVER (PARTITION BY StateID, SiteID, ProgramID) TeamEduNotEligibleNSAnnual
	,SUM(CASE WHEN NSEduAnnualMissing IS NOT NULL THEN 1 ELSE 0 END) 
		OVER (PARTITION BY StateID, SiteID, ProgramID) TeamEduMissingNSAnnual

INTO #SurveyDetails9c

FROM #SurveyDetails9b

--===========================================================================================
----filter the result set on team(s) chosen

SELECT 
	c.NationalID
	,c.NationalName
	,c.StateAbbr
	,c.[State]
	,c.StateID
	,c.SiteID 
	,c.SiteName
	,c.ProgramID
	,c.TeamName
	--,c.Entity_Id
	,c.NHVEduComplete, c.NHVEduEligible, c.NHVEduPotential, c.NHVEduTotal
	,c.NSEduComplete, c.NSEduEligible, c.NSEduPotential, c.NSEduTotal
	,c.NSEduAnnual, c.NSEduAnnualNotEligible, c.NSEduAnnualMissing
	
	,c.NationalEduCompleteNHV, c.NationalEduEligibleNHV,  c.NationalEduPotentialNHV, c.NationalEduTotalNHV
	,c.StateEduCompleteNHV, c.StateEduEligibleNHV,  c.StateEduPotentialNHV, c.StateEduTotalNHV
	,c.AgencyEduCompleteNHV, c.AgencyEduEligibleNHV,  c.AgencyEduPotentialNHV, c.AgencyEduTotalNHV
	,c.TeamEduCompleteNHV, c.TeamEduEligibleNHV,  c.TeamEduPotentialNHV, c.TeamEduTotalNHV

	,c.NationalEduCompleteNS, c.NationalEduEligibleNS,  c.NationalEduPotentialNS, c.NationalEduTotalNS
	,c.StateEduCompleteNS, c.StateEduEligibleNS,  c.StateEduPotentialNS, c.StateEduTotalNS
	,c.AgencyEduCompleteNS, c.AgencyEduEligibleNS,  c.AgencyEduPotentialNS, c.AgencyEduTotalNS
	,c.TeamEduCompleteNS, c.TeamEduEligibleNS,  c.TeamEduPotentialNS, c.TeamEduTotalNS
	
	,c.NationalEduNSAnnual, c.NationalEduNotEligibleNSAnnual,  c.NationalEduMissingNSAnnual
	,c.StateEduNSAnnual, c.StateEduNotEligibleNSAnnual,  c.StateEduMissingNSAnnual
	,c.AgencyEduNSAnnual, c.AgencyEduNotEligibleNSAnnual,  c.AgencyEduMissingNSAnnual
	,c.TeamEduNSAnnual, c.TeamEduNotEligibleNSAnnual,  c.TeamEduMissingNSAnnual

FROM #SurveyDetails9c c
	JOIN @TeamTable parm			----report selection
		ON parm.Value = c.ProgramID	----TeamTable contains team program ids

--===========================================================================================
----for testing

--ORDER BY StateID, SiteID, ProgramID, Entity_id

----for testing
------===========================================================================================
GO
