USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Element7_ActiveClientsPhases]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_Fid_Element7_ActiveClientsPhases]
(	@StartDate		Date 
	,@EndDate		Date 
	,@Team			VARCHAR(max)
)
AS
--------===========================================================================================
--for testing

--DECLARE 
--	@StartDate		Date 
--	,@EndDate		Date 
--	,@Team			VARCHAR(max)

--SET @StartDate		 = CAST('1/1/2014' AS DATE)
--SET @EndDate		 = CAST('12/31/2014' AS DATE)

------------all teams
--SET @Team = '748,779,780,781,812,815,818,821,824,827,830,833,836,839,842,845,848,851,854,857,860,863,866,869,872,875,878,881,884,887,890,893,896,899,902,905,908,911,914,917,920,923,926,929,932,935,938,941,944,947,950,953,956,959,962,965,968,971,974,977,980,983,986,989,992,995,998,1001,1004,1007,1010,1013,1016,1019,1022,1025,1028,1031,1034,1037,1040,1043,1047,1049,1052,1055,1058,1061,1064,1067,1070,1073,1076,1079,1082,1085,1088,1091,1094,1097,1100,1103,1106,1109,1112,1115,1118,1121,1124,1127,1130,1133,1136,1139,1142,1145,1148,1151,1154,1157,1160,1163,1166,1169,1172,1175,1178,1181,1184,1187,1190,1193,1196,1199,1202,1205,1208,1211,1213,1217,1221,1224,1227,1230,1233,1236,1239,1242,1244,1247,1250,1253,1256,1259,1262,1265,1268,1271,1274,1277,1280,1283,1286,1289,1292,1295,1298,1301,1304,1307,1310,1313,1316,1319,1322,1325,1328,1331,1334,1337,1340,1343,1346,1349,1352,1355,1358,1361,1364,1367,1370,1373,1376,1379,1382,1385,1388,1391,1394,1397,1400,1404,1406,1409,1412,1415,1418,1421,1424,1427,1430,1433,1436,1439,1443,1446,1449,1452,1454,1457,1461,1463,1467,1469,1472,1475,1478,1481,1484,1487,1490,1493,1496,1499,1502,1505,1508,1511,1514,1517,1520,1523,1526,1529,1532,1535,1538,1554,1557,1560,1563,1566,1570,1573,1576,1581,1584,1587,1599,1602,1605,1608,1611,1617,1620,1623,1626,1638,1641,1644,1647,1651,1655,1658,1661,1664,1668,1671,1674,1677,1680,1683,1688,1694,1697,1700,1703,1706,1709,1712,1715,1718,1722,1727,1730,1739,1744,1746,1749,1752,1755,1758,1761,1764,1767,1770,1773,1776,1779,1782,1785,1790,1793,1796,1799,1802,1805,1808,1811,1814,1817,1820,1823,1826,1829,1832,1835,1838,1841,1844,1848,1851,1854,1857,1860,1863,1868,1871,1875,1879,1884,1887,1891,1894,1897,1900,1903,1906,1909,1912,1915,1918,1922,1925,1928,1931,1934,1937,1940,1943,1946,1949,1952,1955,1958,1961,1964,1967,1970,1973,1976,1979,1982,1985,1988,1992,1995,1998,2001,2004,2007,2010,2013,2016,2020,2023,2026,2032'

--------------------IN
------SET @Team = '1608,1688,1697,2001'

----------------CO
--SET @Team = '854,857,860,863,866,869,971,974,977,980,983,986,989,992,995,998,1001,1004,1007,1010,1013,1576,1887,1922,1925,1943,1988,2010'

------------AZ
--SET @Team = '872,875,878,911,914,1532,1796,1823,1937,1949,1985'
----------az south phoen
--------SET @Team = '875,878,1937'

----for testing
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
DECLARE @x XML  
SELECT @x = CAST('<A>'+ REPLACE(@rTeam,',','</A><A>')+ '</A>' AS XML) 
INSERT INTO @TeamTable             
SELECT t.value('.', 'int') AS inVal 
FROM @x.nodes('/A') AS x(t) 

-----------------------------------------------------------------------------------------
;WITH El7Details AS
(
	SELECT 		
	
		DISTINCT
	
		'1' NationalID
		,'National' NationalName
		,pas.Abbreviation
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
			END Team_Name
		
		-------------------------------
		,mhv.GestAge_EDD EDD
		---HAS NOT BEEN IMPLEMENTED YET as of 2/19/2015	
		---IMPLEMENTED 3/26/2015
		,(DATEADD(YEAR,1,mhv.GestAge_EDD)) ED1
		,(DATEADD(YEAR,2,mhv.GestAge_EDD)) ED2
		---HAS NOT BEEN IMPLEMENTED YET as of 2/19/2015	
		-------------------------------

		,inf.DOB
		,inf.BD1
		,inf.BD2
		--,inf.MinSurvDate
		--,inf.MaxSurvDate
		
		,ead.CLID
		,ead.CaseNumber
		,ead.ProgramStartDate
		,ead.EndDate ProgramEndDate
		,ead.ReasonForDismissal
		--,inf.CL_EN_GEN_ID

		,RANK() OVER(PARTITION BY ead.CLID, ead.ProgramID ORDER BY ISNULL(ead.EndDate, DATEADD(DAY,1,GETDATE())) DESC, ead.RecID DESC) RankingLatest

	------for Table 1
	------Pregnancy Phase
	
		,CASE WHEN ISNULL(inf.DOB,DATEADD(DAY,1,@rEndDate)) > @rStartDate				--inf dob after rpt start date
					AND ISNULL(inf.DOB,DATEADD(DAY,1,@rEndDate)) > ead.ProgramStartDate	--inf dob after pgm start date
					AND ead.ProgramStartDate <= @rEndDate								--pgm start date before/on rpt end date
					AND ISNULL(ead.EndDate,DATEADD(DAY,1,@rEndDate)) >= @rStartDate		--pgm end date after/on rpt start date
			 THEN ead.CLID--1
			 --ELSE 0
		END PregPhaseServed
		,CASE WHEN ISNULL(inf.DOB,DATEADD(DAY,1,@rEndDate)) > @rStartDate				--inf dob after rpt start date
					AND ISNULL(inf.DOB,DATEADD(DAY,1,@rEndDate)) > ead.ProgramStartDate	--inf dob after pgm start date
					AND inf.DOB BETWEEN @rStartDate AND @rEndDate						--inf dob between rpt dates
					AND ead.ProgramStartDate <= @rEndDate								--pgm start date before/on rpt end date
					AND ISNULL(ead.EndDate,DATEADD(DAY,1,@rEndDate)) >= @rStartDate		--pgm end date after/on rpt start date
					AND ISNULL(ead.EndDate,@rEndDate) >= inf.DOB						--pgm end date after/on inf dob				
			 THEN ead.CLID--1
			 --ELSE 0
		END PregPhaseCompleted	
		,CASE WHEN ISNULL(inf.DOB,DATEADD(DAY,1,@rEndDate)) > @rStartDate				--inf dob after rpt start date
					AND ISNULL(inf.DOB,DATEADD(DAY,1,@rEndDate)) > ead.ProgramStartDate	--inf dob after pgm start date
					AND (inf.DOB > @rEndDate OR inf.DOB IS NULL)						--inf dob after rpt end date or null
					AND ead.ProgramStartDate <= @rEndDate								--pgm start date before/on rpt end date
					AND ISNULL(ead.EndDate,DATEADD(DAY,1,@rEndDate)) >= @rStartDate		--pgm end date after/on rpt start date
					AND ISNULL(ead.EndDate,DATEADD(DAY,1,@rEndDate)) > @rEndDate		--pgm end date after rpt end date
			 THEN ead.CLID--1
			 --ELSE 0
		END PregPhaseStillActive
		,CASE WHEN ISNULL(inf.DOB,DATEADD(DAY,1,@rEndDate)) > @rStartDate				--inf dob after rpt start date
					AND ISNULL(inf.DOB,DATEADD(DAY,1,@rEndDate)) > ead.ProgramStartDate	--inf dob after pgm start date
					AND (inf.DOB > ead.EndDate OR inf.DOB IS NULL)						--inf dob after pgm end date or null
					AND ead.ProgramStartDate <= @rEndDate								--pgm start date before/on rpt end date

					AND ISNULL(ead.EndDate,DATEADD(DAY,1,@rEndDate)) >= @rStartDate		--pgm end date after/on rpt start date
					AND ead.EndDate BETWEEN @rStartDate AND @rEndDate					--pgm end date between rpt dates
			 THEN ead.CLID--1
			 --ELSE 0
		END PregPhaseLeftProgram
		,CASE WHEN ISNULL(inf.DOB,DATEADD(DAY,1,@rEndDate)) > @rEndDate					--inf dob after rpt end date
					AND ISNULL(inf.DOB,DATEADD(DAY,1,@rEndDate)) > ead.ProgramStartDate	--inf dob after pgm start date
					AND (inf.DOB > ead.EndDate OR inf.DOB IS NULL)						--inf dob after pgm end date or null
					AND ead.ProgramStartDate <= @rEndDate								--pgm start date before/on rpt end date
					AND ead.EndDate <= @rEndDate										--pgm end date before/on rpt end date
					AND mhv.GestAge_EDD BETWEEN @rStartDate AND @rEndDate				--est delivery date between rpt dates 
			 THEN ead.CLID--1
			 --ELSE 0
		END PregPhaseLeftPgmBfEDD

		------for Table 2
		------Infancy Phase
	
		,CASE WHEN inf.DOB <= @rEndDate
					AND ISNULL(ead.EndDate,@rEndDate) >= inf.DOB
					AND inf.BD1 > @rStartDate
					AND ead.ProgramStartDate <= @rEndDate 
					AND ISNULL(ead.EndDate,@rEndDate) >= @rStartDate
			 THEN ead.CLID--1
			 --ELSE 0
		END InfPhaseServed
		,CASE WHEN inf.DOB <= @rEndDate
					AND ISNULL(ead.EndDate,@rEndDate) > = inf.DOB
					AND inf.BD1 > @rStartDate
					AND ISNULL(ead.EndDate,@rEndDate) > = inf.BD1
					AND inf.BD1 BETWEEN @rStartDate AND @rEndDate
					AND ead.ProgramStartDate <= @rEndDate 
					AND ISNULL(ead.EndDate,@rEndDate) >= @rStartDate
			 THEN ead.CLID--1
			 --ELSE 0
		END InfPhaseCompleted
		,CASE WHEN inf.DOB <= @rEndDate
					AND inf.DOB IS NOT NULL
					AND ISNULL(ead.EndDate,@rEndDate) > = inf.DOB
					AND inf.BD1 > @rStartDate
					AND inf.BD1 > @rEndDate
					AND ead.ProgramStartDate <= @rEndDate 
					AND ISNULL(ead.EndDate,@rEndDate) >= @rStartDate
					AND ISNULL(ead.EndDate,DATEADD(DAY,1,@rEndDate))> @rEndDate
			 THEN ead.CLID--1
			 --ELSE 0
		END InfPhaseStillActive
		,CASE WHEN inf.DOB <= @rEndDate
					AND ISNULL(ead.EndDate,@rEndDate) >= inf.DOB
					AND inf.BD1 > @rStartDate
					AND ead.EndDate < inf.BD1
					AND ead.ProgramStartDate <= @rEndDate 
					AND ISNULL(ead.EndDate,@rEndDate) >= @rStartDate
					AND ead.EndDate BETWEEN @rStartDate AND @rEndDate				 
			 THEN ead.CLID--1
			 --ELSE 0
		END InfPhaseLeftProgram
		,CASE WHEN inf.DOB <= @rEndDate
					AND ISNULL(ead.EndDate,@rEndDate) >= inf.DOB
					AND inf.BD1 > @rStartDate
					AND inf.BD1 BETWEEN @rStartDate AND @rEndDate
					AND ead.ProgramStartDate <= @rEndDate 
					AND ead.EndDate < inf.BD1
					AND ead.EndDate BETWEEN inf.DOB AND @rEndDate
			 THEN ead.CLID--1
			 --ELSE 0
		END InfPhaseLeftPgmBf1stBD

	----for Table 3
	----Toddler Phase
	
		,CASE WHEN inf.BD1 <= @rEndDate
					AND inf.BD1 <= ISNULL(ead.EndDate,@rEndDate)
					AND inf.BD2 > @rStartDate
					AND ead.ProgramStartDate <= @rEndDate 
					AND ISNULL(ead.EndDate,@rEndDate) >= @rStartDate
			 THEN ead.CLID--1
			 --ELSE 0
		END ToddPhaseServed			
		,CASE WHEN inf.BD1 <= @rEndDate
					AND inf.BD1 <= ISNULL(ead.EndDate,@rEndDate)
					AND inf.BD2 > @rStartDate
					AND ead.ProgramStartDate <= @rEndDate 
					AND ISNULL(ead.EndDate,@rEndDate) >= @rStartDate
					AND ead.EndDate BETWEEN @rStartDate AND @rEndDate
					AND ead.ReasonForDismissal = 'Child reached 2nd birthday'
			 THEN ead.CLID--1
			 --ELSE 0
		END ToddPhaseCompleted	
		,CASE WHEN inf.BD1 <= @rEndDate
					AND inf.BD1 <= ISNULL(ead.EndDate,@rEndDate)
					AND inf.BD2 > @rStartDate
					AND ead.ProgramStartDate <= @rEndDate 
					AND ISNULL(ead.EndDate,@rEndDate) >= @rStartDate
					AND ISNULL(ead.EndDate,DATEADD(DAY,1,@rEndDate)) > @rEndDate
			 THEN ead.CLID--1
			 --ELSE 0
		END ToddPhaseStillActive
		,CASE WHEN inf.BD1 <= @rEndDate
					AND inf.BD1 <= ISNULL(ead.EndDate,@rEndDate)
					AND inf.BD2 > @rStartDate
					AND ead.ProgramStartDate <= @rEndDate 
					AND ISNULL(ead.EndDate,@rEndDate) >= @rStartDate
					AND ead.EndDate BETWEEN @rStartDate AND @rEndDate
					AND ead.ReasonForDismissal <> 'Child reached 2nd birthday'
			 THEN ead.CLID--1
			 --ELSE 0
		END ToddPhaseLeftProgram			
		,CASE WHEN inf.BD1 <= @rEndDate
					AND ead.EndDate BETWEEN inf.BD1 AND DATEADD(DAY,-1,inf.BD2)
					AND inf.BD2 BETWEEN @rStartDate AND @rEndDate
					AND ead.ProgramStartDate <= @rEndDate 
					AND ISNULL(ead.ReasonForDismissal,'') <> 'Child reached 2nd birthday'
			 THEN ead.CLID--1
			 --ELSE 0
		END ToddPhaseLeftPgmBf2ndBD			

	----for Table 5
	----Actual Graduation		
		
		--,CASE WHEN inf.BD2 BETWEEN @rStartDate AND @rEndDate
		--	 THEN ead.CLID--1
		--	 --ELSE 0
		--END ToddPhaseSecondBD
		---HAS NOT BEEN IMPLEMENTED YET as of 2/19/2015	
		---IMPLEMENTED 3/26/2015
		,CASE WHEN ISNULL(inf.BD2, (DATEADD(YEAR,2,mhv.GestAge_EDD))) BETWEEN @rStartDate AND @rEndDate	--2nd bd during rpt period
				AND ead.EndDate < ISNULL(inf.BD2, (DATEADD(YEAR,2,mhv.GestAge_EDD)))						--pgm end date before 2nd bd
				AND ead.ReasonForDismissal <> 'Child reached 2nd birthday'						--dismissal reason NOT 2nd bd
				AND ead.ProgramStartDate <= @rEndDate						-- started program on or before the report period end date
			 THEN ead.CLID--1
			 --ELSE 0
		END ToddPhaseSecondBD			
		---HAS NOT BEEN IMPLEMENTED YET as of 2/19/2015			
		,CASE WHEN 
				(inf.BD2 BETWEEN @rStartDate AND @rEndDate						--2nd bd during rpt period
				AND ISNULL(ead.EndDate,DATEADD(DAY,1,@rEndDate)) > inf.BD2)		--pgm end date after 2nd bd
				OR																--or
				(ead.ReasonForDismissal = 'Child reached 2nd birthday'			--dismissal reason = 2nd bd
				AND ead.EndDate BETWEEN @rStartDate AND @rEndDate)				--pgm end date during rpt period
			 THEN ead.CLID--1
			 --ELSE 0
		END ToddlerGradOrActive

	----Table 4
	----Expected Graduation
	
		,CASE WHEN ISNULL(ead.EndDate,@rEndDate) > @rStartDate 
						AND ead.ProgramStartDate <= @rEndDate AND ISNULL(ead.EndDate,@rEndDate) >= @rStartDate
			 THEN ead.CLID--1
			 --ELSE 0
		END TotalServed				
		,CASE WHEN ISNULL(ead.EndDate,@rEndDate) > @rStartDate 
						AND ead.ProgramStartDate <= @rEndDate AND ISNULL(ead.EndDate,@rEndDate) >= @rStartDate
						AND ISNULL(ead.EndDate,DATEADD(DAY,1,@rEndDate)) > @rEndDate
			 THEN ead.CLID--1
			 --ELSE 0
		END TotalStillActive				
		,CASE WHEN ISNULL(ead.EndDate,@rEndDate) > @rStartDate 
						AND ead.ProgramStartDate <= @rEndDate AND ISNULL(ead.EndDate,@rEndDate) >= @rStartDate
						AND ead.ReasonForDismissal = 'Child reached 2nd birthday'
						AND ISNULL(ead.EndDate,DATEADD(DAY,1,@rEndDate)) BETWEEN @rStartDate AND @rEndDate   
			 THEN ead.CLID--1
			 --ELSE 0
		END TotalGraduated					
		,CASE WHEN ISNULL(ead.EndDate,@rEndDate) > @rStartDate 
						AND ead.ProgramStartDate <= @rEndDate AND ISNULL(ead.EndDate,@rEndDate) >= @rStartDate
						AND ead.ReasonForDismissal <> 'Child reached 2nd birthday'
						AND ISNULL(ead.EndDate,DATEADD(DAY,1,@rEndDate)) BETWEEN @rStartDate AND @rEndDate
			 THEN ead.CLID--1
			 --ELSE 0
		END TotalLeftProgram	
	
	FROM EnrollmentAndDismissal ead
		INNER JOIN UV_PAS pas ON pas.ProgramID = ead.ProgramID 

		LEFT JOIN 
			(	SELECT 
					CL_EN_GEN_ID
					,ProgramID
					,INFANT_BIRTH_0_DOB DOB
					,DATEADD(YEAR,1,INFANT_BIRTH_0_DOB) BD1
					,DATEADD(YEAR,2,INFANT_BIRTH_0_DOB) BD2 
				FROM Infant_Birth_Survey
			) inf ON inf.CL_EN_GEN_ID = ead.CLID
					AND inf.ProgramID = ead.ProgramID


		LEFT JOIN
			(	SELECT
					CL_EN_GEN_ID
					,ProgramID
					,(CLIENT_HEALTH_PREGNANCY_0_EDD) GestAge_EDD
					,RANK () OVER(PARTITION BY CL_EN_GEN_ID,ProgramID ORDER BY SurveyDate DESC, SurveyResponseID) Ranking
				FROM Maternal_Health_Survey
			)mhv ON mhv.ProgramID = ead.ProgramID
					AND mhv.CL_EN_GEN_ID = ead.CLID
					AND mhv.Ranking = 1		
	-------------------------------------------------------------------------------------------
		LEFT JOIN UC_Client_Exclusion_YWCA ywca ON ywca.CLID = ead.CLID
			AND ead.SiteID = 222 

	WHERE ywca.CLID IS NULL			
			
)--end cte El7Details
------===========================================================================================
,El7DetailsWAggregates AS
(------DETAIL DATA PLUS Aggregates
	SELECT 
		El7Details.NationalID
		,El7Details.NationalName	
		,El7Details.Abbreviation StateAbbr
		,El7Details.[US State] [State]
		,El7Details.StateID
		,El7Details.SiteID
		,El7Details.Site SiteName
		,El7Details.ProgramID
		,El7Details.Team_Name TeamName	
		-------------------------------
		,El7Details.EDD
		-------------------------------
		,El7Details.DOB
		,El7Details.BD1
		,El7Details.BD2
		--,El7Details.MinSurvDate
		--,El7Details.MaxSurvDate		
		,El7Details.CLID
		,El7Details.CaseNumber
		,El7Details.ProgramStartDate
		,El7Details.ProgramEndDate 
		,El7Details.ReasonForDismissal
		--,El7Details.RankingLatest
	
		----T1
		,El7Details.PregPhaseServed
		,El7Details.PregPhaseCompleted 
		,El7Details.PregPhaseStillActive
		,El7Details.PregPhaseLeftProgram
		,El7Details.PregPhaseLeftPgmBfEDD 
		----T2
		,El7Details.InfPhaseServed
		,El7Details.InfPhaseCompleted
		,El7Details.InfPhaseStillActive
		,El7Details.InfPhaseLeftProgram
		,El7Details.InfPhaseLeftPgmBf1stBD
		--T3
		,El7Details.ToddPhaseServed
		,El7Details.ToddPhaseCompleted
		,El7Details.ToddPhaseStillActive
		,El7Details.ToddPhaseLeftProgram	
		,El7Details.ToddPhaseLeftPgmBf2ndBD	
		----for T4
		,El7Details.TotalServed
		,El7Details.TotalStillActive
		,El7Details.TotalGraduated
		,El7Details.TotalLeftProgram
		----for T5
		,El7Details.ToddPhaseSecondBD				
		,El7Details.ToddlerGradOrActive

--		------aggregates

--		------T1 Pregnancy
--		--------National
		,SUM(CASE WHEN PregPhaseServed IS NOT NULL THEN 1 ELSE 0 END) OVER() NationalPregServed 
		,SUM(CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) OVER() NationalPregCompleted
		,SUM(CASE WHEN PregPhaseStillActive IS NOT NULL THEN 1 ELSE 0 END) OVER() NationalPregStillAct
		,SUM(CASE WHEN PregPhaseLeftProgram IS NOT NULL THEN 1 ELSE 0 END) OVER() NationalPregLeftPgm
		,SUM(CASE WHEN PregPhaseLeftPgmBfEDD IS NOT NULL THEN 1 ELSE 0 END) OVER() NationalPregLeftPgmBfEDD		
		,CASE WHEN SUM((CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN PregPhaseLeftPgmBfEDD IS NOT NULL THEN 1 ELSE 0 END)) OVER() = 0	--denominator
			THEN 0.0
			ELSE CAST(ROUND( --percent
						CAST(SUM((CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END)) OVER() as decimal)  --numerator
						/	
						CAST(SUM((CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN PregPhaseLeftPgmBfEDD IS NOT NULL THEN 1 ELSE 0 END)) OVER() as decimal) 		 
				* 100 ,1) as decimal(10,1)) 
		END NationalPregClRetention		
		----------State	
		,SUM(CASE WHEN PregPhaseServed IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID) StatePregServed 
		,SUM(CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID) StatePregCompleted
		,SUM(CASE WHEN PregPhaseStillActive IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID) StatePregStillAct
		,SUM(CASE WHEN PregPhaseLeftProgram IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID) StatePregLeftPgm
		,SUM(CASE WHEN PregPhaseLeftPgmBfEDD IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID) StatePregLeftPgmBfEDD
		,CASE WHEN SUM((CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN PregPhaseLeftPgmBfEDD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID) = 0	--denominator
			THEN 0.0
			ELSE CAST(ROUND( --percent
						CAST(SUM((CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID) as decimal)  --numerator
						/	
						CAST(SUM((CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN PregPhaseLeftPgmBfEDD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID) as decimal) 		 
				* 100 ,1) as decimal(10,1)) 
		END StatePregClRetention		
--		--------Agency
		,SUM(CASE WHEN PregPhaseServed IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID) AgencyPregServed 
		,SUM(CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID) AgencyPregCompleted
		,SUM(CASE WHEN PregPhaseStillActive IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID) AgencyPregStillAct
		,SUM(CASE WHEN PregPhaseLeftProgram IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID) AgencyPregLeftPgm
		,SUM(CASE WHEN PregPhaseLeftPgmBfEDD IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID) AgencyPregLeftPgmBfEDD
		,CASE WHEN SUM((CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN PregPhaseLeftPgmBfEDD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID) = 0	--denominator
			THEN 0.0
			ELSE CAST(ROUND( --percent
						CAST(SUM((CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID) as decimal)  --numerator
						/	
						CAST(SUM((CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN PregPhaseLeftPgmBfEDD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID) as decimal) 		 
				* 100 ,1) as decimal(10,1)) 
		END AgencyPregClRetention		
		--------Program/Team
		,SUM(CASE WHEN PregPhaseServed IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamPregServed 
		,SUM(CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamPregCompleted
		,SUM(CASE WHEN PregPhaseStillActive IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamPregStillAct
		,SUM(CASE WHEN PregPhaseLeftProgram IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamPregLeftPgm
		,SUM(CASE WHEN PregPhaseLeftPgmBfEDD IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamPregLeftPgmBfEDD
		,CASE WHEN SUM((CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN PregPhaseLeftPgmBfEDD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID, ProgramID) = 0	--denominator
			THEN 0.0
			ELSE CAST(ROUND( --percent
						CAST(SUM((CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID, ProgramID) as decimal)  --numerator
						/	
						CAST(SUM((CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN PregPhaseLeftPgmBfEDD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID, ProgramID) as decimal) 		 
				* 100 ,1) as decimal(10,1)) 
		END TeamPregClRetention

--		------T2 Infancy		
--		--------National
		,SUM(CASE WHEN InfPhaseServed IS NOT NULL THEN 1 ELSE 0 END) OVER() NationalInfServed 
		,SUM(CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) OVER() NationalInfCompleted
		,SUM(CASE WHEN InfPhaseStillActive IS NOT NULL THEN 1 ELSE 0 END) OVER() NationalInfStillAct
		,SUM(CASE WHEN InfPhaseLeftProgram IS NOT NULL THEN 1 ELSE 0 END) OVER() NationalInfLeftPgm
		,SUM(CASE WHEN InfPhaseLeftPgmBf1stBD IS NOT NULL THEN 1 ELSE 0 END) OVER() NationalInfLeftPgmBf1stBD		
		,CASE WHEN SUM((CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseLeftPgmBf1stBD IS NOT NULL THEN 1 ELSE 0 END)) OVER() = 0	--denominator
			THEN 0.0
			ELSE CAST(ROUND( --percent
						CAST(SUM((CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END)) OVER() as decimal)  --numerator
						/	
						CAST(SUM((CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseLeftPgmBf1stBD IS NOT NULL THEN 1 ELSE 0 END)) OVER() as decimal) 		 
				* 100 ,1) as decimal(10,1)) 
		END NationalInfClRetention
--		----------State	
		,SUM(CASE WHEN InfPhaseServed IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID) StateInfServed 
		,SUM(CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID) StateInfCompleted
		,SUM(CASE WHEN InfPhaseStillActive IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID) StateInfStillAct
		,SUM(CASE WHEN InfPhaseLeftProgram IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID) StateInfLeftPgm
		,SUM(CASE WHEN InfPhaseLeftPgmBf1stBD IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID) StateInfLeftPgmBf1stBD
		,CASE WHEN SUM((CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseLeftPgmBf1stBD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID) = 0	--denominator
			THEN 0.0
			ELSE CAST(ROUND( --percent
						CAST(SUM((CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID) as decimal)  --numerator
						/	
						CAST(SUM((CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseLeftPgmBf1stBD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID) as decimal) 		 
				* 100 ,1) as decimal(10,1)) 
		END StateInfClRetention
--		--------Agency
		,SUM(CASE WHEN InfPhaseServed IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID) AgencyInfServed 
		,SUM(CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID) AgencyInfCompleted
		,SUM(CASE WHEN InfPhaseStillActive IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID) AgencyInfStillAct
		,SUM(CASE WHEN InfPhaseLeftProgram IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID) AgencyInfLeftPgm
		,SUM(CASE WHEN InfPhaseLeftPgmBf1stBD IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID) AgencyInfLeftPgmBf1stBD
		,CASE WHEN SUM((CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseLeftPgmBf1stBD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID) = 0	--denominator
			THEN 0.0
			ELSE CAST(ROUND( --percent
						CAST(SUM((CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID) as decimal)  --numerator
						/	
						CAST(SUM((CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseLeftPgmBf1stBD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID) as decimal) 		 
				* 100 ,1) as decimal(10,1)) 
		END AgencyInfClRetention
--		--------Program/Team
		,SUM(CASE WHEN InfPhaseServed IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamInfServed 
		,SUM(CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamInfCompleted
		,SUM(CASE WHEN InfPhaseStillActive IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamInfStillAct
		,SUM(CASE WHEN InfPhaseLeftProgram IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamInfLeftPgm
		,SUM(CASE WHEN InfPhaseLeftPgmBf1stBD IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamInfLeftPgmBf1stBD
		,CASE WHEN SUM((CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseLeftPgmBf1stBD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID, ProgramID) = 0	--denominator
			THEN 0.0
			ELSE CAST(ROUND( --percent
						CAST(SUM((CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID, ProgramID) as decimal)  --numerator
						/	
						CAST(SUM((CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseLeftPgmBf1stBD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID, ProgramID) as decimal) 		 
				* 100 ,1) as decimal(10,1)) 
		END TeamInfClRetention

--		-----T3 Toddlerhood
--		--------National
		,SUM(CASE WHEN ToddPhaseServed IS NOT NULL THEN 1 ELSE 0 END) OVER() NationalToddServed 
		,SUM(CASE WHEN ToddPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) OVER() NationalToddCompleted
		,SUM(CASE WHEN ToddPhaseStillActive IS NOT NULL THEN 1 ELSE 0 END) OVER() NationalToddStillAct
		,SUM(CASE WHEN ToddPhaseLeftProgram IS NOT NULL THEN 1 ELSE 0 END) OVER() NationalToddLeftPgm
		,SUM(CASE WHEN ToddPhaseLeftPgmBf2ndBD IS NOT NULL THEN 1 ELSE 0 END) OVER() NationalToddLeftPgmBf2ndBD		
		,CASE WHEN SUM((CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseLeftPgmBf2ndBD IS NOT NULL THEN 1 ELSE 0 END)) OVER() = 0	--denominator
			THEN 0.0
			ELSE CAST(ROUND( --percent
						CAST(SUM((CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END)) OVER() as decimal)  --numerator
						/	
						CAST(SUM((CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseLeftPgmBf2ndBD IS NOT NULL THEN 1 ELSE 0 END)) OVER() as decimal) 		 
				* 100 ,1) as decimal(10,1)) 
		END NationalToddfClRetention
--		----------State	
		,SUM(CASE WHEN ToddPhaseServed IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID) StateToddServed 
		,SUM(CASE WHEN ToddPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID) StateToddCompleted
		,SUM(CASE WHEN ToddPhaseStillActive IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID) StateToddStillAct
		,SUM(CASE WHEN ToddPhaseLeftProgram IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID) StateToddLeftPgm
		,SUM(CASE WHEN ToddPhaseLeftPgmBf2ndBD IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID) StateToddLeftPgmBf2ndBD
		,CASE WHEN SUM((CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseLeftPgmBf2ndBD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID) = 0	--denominator
			THEN 0.0
			ELSE CAST(ROUND( --percent
						CAST(SUM((CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID) as decimal)  --numerator
						/	
						CAST(SUM((CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseLeftPgmBf2ndBD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID) as decimal) 		 
				* 100 ,1) as decimal(10,1)) 
		END StateToddfClRetention
		--------Agency
		,SUM(CASE WHEN ToddPhaseServed IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID) AgencyToddServed 
		,SUM(CASE WHEN ToddPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID) AgencyToddCompleted
		,SUM(CASE WHEN ToddPhaseStillActive IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID) AgencyToddStillAct
		,SUM(CASE WHEN ToddPhaseLeftProgram IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID) AgencyToddLeftPgm
		,SUM(CASE WHEN ToddPhaseLeftPgmBf2ndBD IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID) AgencyToddLeftPgmBf2ndBD
		,CASE WHEN SUM((CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseLeftPgmBf2ndBD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID) = 0	--denominator
			THEN 0.0
			ELSE CAST(ROUND( --percent
						CAST(SUM((CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID) as decimal)  --numerator
						/	
						CAST(SUM((CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseLeftPgmBf2ndBD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID) as decimal) 		 
				* 100 ,1) as decimal(10,1)) 
		END AgencyToddfClRetention
--		--------Program/Team
		,SUM(CASE WHEN ToddPhaseServed IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamToddServed 
		,SUM(CASE WHEN ToddPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamToddCompleted
		,SUM(CASE WHEN ToddPhaseStillActive IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamToddStillAct
		,SUM(CASE WHEN ToddPhaseLeftProgram IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamToddLeftPgm
		,SUM(CASE WHEN ToddPhaseLeftPgmBf2ndBD IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamToddLeftPgmBf2ndBD
		,CASE WHEN SUM((CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseLeftPgmBf2ndBD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID, ProgramID) = 0	--denominator
			THEN 0.0
			ELSE CAST(ROUND( --percent
						CAST(SUM((CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID, ProgramID) as decimal)  --numerator
						/	
						CAST(SUM((CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseLeftPgmBf2ndBD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID, ProgramID) as decimal) 		 
				* 100 ,1) as decimal(10,1)) 
		END TeamToddfClRetention

--		-----T4 Expected Grad Rate 
--		--------National	
		,SUM(CASE WHEN TotalServed IS NOT NULL THEN 1 ELSE 0 END) OVER() NationalTotalServed 
		,SUM(CASE WHEN TotalStillActive IS NOT NULL THEN 1 ELSE 0 END) OVER() NationalTotalStillAct
		,SUM(CASE WHEN TotalGraduated IS NOT NULL THEN 1 ELSE 0 END) OVER() NationalTotalGrad
		,SUM(CASE WHEN TotalLeftProgram IS NOT NULL THEN 1 ELSE 0 END) OVER() NationalTotalLeftPgm		
		,CAST(ROUND( --percent
			CAST(SUM((CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END)) OVER() as decimal)  --numerator
			/	CASE WHEN SUM((CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) +			
								(CASE WHEN PregPhaseLeftPgmBfEDD IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseLeftPgmBf1stBD IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseLeftPgmBf2ndBD IS NOT NULL THEN 1 ELSE 0 END)) OVER() = 0	--denominator
					THEN 1.00
					ELSE CAST(SUM((CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) +
								(CASE WHEN PregPhaseLeftPgmBfEDD IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseLeftPgmBf1stBD IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseLeftPgmBf2ndBD IS NOT NULL THEN 1 ELSE 0 END)) OVER() as decimal)  
				END 
		* 100 ,1) as decimal(10,1)) NationalTotalExpGrad
--		----------State	
		,SUM(CASE WHEN TotalServed IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID) StateTotalServed 
		,SUM(CASE WHEN TotalStillActive IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID) StateTotalStillAct
		,SUM(CASE WHEN TotalGraduated IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID) StateTotalGrad
		,SUM(CASE WHEN TotalLeftProgram IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID) StateTotalLeftPgm
		,CAST(ROUND( --percent
			CAST(SUM((CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID) as decimal)  --numerator
			/	CASE WHEN SUM((CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) +			
								(CASE WHEN PregPhaseLeftPgmBfEDD IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseLeftPgmBf1stBD IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseLeftPgmBf2ndBD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID) = 0	--denominator
					THEN 1.00
					ELSE CAST(SUM((CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) +
								(CASE WHEN PregPhaseLeftPgmBfEDD IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseLeftPgmBf1stBD IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseLeftPgmBf2ndBD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID) as decimal)  
				END 
		* 100 ,1) as decimal(10,1)) StateTotalExpGrad
--		--------Agency
		,SUM(CASE WHEN TotalServed IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID) AgencyTotalServed 
		,SUM(CASE WHEN TotalStillActive IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID) AgencyTotalStillAct
		,SUM(CASE WHEN TotalGraduated IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID) AgencyTotalGrad
		,SUM(CASE WHEN TotalLeftProgram IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID) AgencyTotalLeftPgm
		,CAST(ROUND( --percent
			CAST(SUM((CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID) as decimal)  --numerator
			/	CASE WHEN SUM((CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) +			
								(CASE WHEN PregPhaseLeftPgmBfEDD IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseLeftPgmBf1stBD IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseLeftPgmBf2ndBD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID) = 0	--denominator
					THEN 1.00
					ELSE CAST(SUM((CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) +
								(CASE WHEN PregPhaseLeftPgmBfEDD IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseLeftPgmBf1stBD IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseLeftPgmBf2ndBD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID) as decimal)  
				END 
		* 100 ,1) as decimal(10,1)) AgencyTotalExpGrad
--		--------Program/Team
		,SUM(CASE WHEN TotalServed IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamTotalServed 
		,SUM(CASE WHEN TotalStillActive IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamTotalStillAct
		,SUM(CASE WHEN TotalGraduated IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamTotalGrad
		,SUM(CASE WHEN TotalLeftProgram IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamTotalLeftPgm
		,CAST(ROUND( --percent
			CAST(SUM((CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID, ProgramID) as decimal)  --numerator
			/	CASE WHEN SUM((CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) +			
								(CASE WHEN PregPhaseLeftPgmBfEDD IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseLeftPgmBf1stBD IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseLeftPgmBf2ndBD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID, ProgramID) = 0	--denominator
					THEN 1.00
					ELSE CAST(SUM((CASE WHEN PregPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseCompleted IS NOT NULL THEN 1 ELSE 0 END) +
								(CASE WHEN PregPhaseLeftPgmBfEDD IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN InfPhaseLeftPgmBf1stBD IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseLeftPgmBf2ndBD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID, ProgramID) as decimal)  
				END 
		* 100 ,1) as decimal(10,1)) TeamTotalExpGrad
		
--		-----T5 Actual Grad Rate 
--		------National	
		,SUM(CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END) OVER() NationalToddGradOrAct
		,SUM(CASE WHEN ToddPhaseSecondBD IS NOT NULL THEN 1 ELSE 0 END) OVER() NationalToddSecondBD		
		,CAST(ROUND( --percent
			CAST(SUM((CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END)) OVER() as decimal)  --numerator
			/	CASE WHEN SUM((CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseSecondBD IS NOT NULL THEN 1 ELSE 0 END)) OVER() = 0	--denominator
					THEN 1.00
					ELSE CAST(SUM((CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseSecondBD IS NOT NULL THEN 1 ELSE 0 END)) OVER() as decimal)  
				END 
		* 100 ,1) as decimal(10,1)) NationalTotalActGrad
--		----------State	
		,SUM(CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID) StateToddGradOrAct
		,SUM(CASE WHEN ToddPhaseSecondBD IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID) StateToddSecondBD
		,CAST(ROUND( --percent
			CAST(SUM((CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID) as decimal)  --numerator
			/	CASE WHEN SUM((CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseSecondBD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID) = 0	--denominator
					THEN 1.00
					ELSE CAST(SUM((CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseSecondBD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID) as decimal)  
				END 
		* 100 ,1) as decimal(10,1)) StateTotalActGrad
--		--------Agency
		,SUM(CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID) AgencyToddGradOrAct
		,SUM(CASE WHEN ToddPhaseSecondBD IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID) AgencyToddSecondBD
		,CAST(ROUND( --percent
			CAST(SUM((CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID) as decimal)  --numerator
			/	CASE WHEN SUM((CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseSecondBD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID) = 0	--denominator
					THEN 1.00
					ELSE CAST(SUM((CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseSecondBD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID) as decimal)  
				END 
		* 100 ,1) as decimal(10,1)) AgencyTotalActGrad
--		--------Program/Team
		,SUM(CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamToddGradOrAct
		,SUM(CASE WHEN ToddPhaseSecondBD IS NOT NULL THEN 1 ELSE 0 END) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamToddSecondBD
		,CAST(ROUND( --percent
			CAST(SUM((CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID, ProgramID) as decimal)  --numerator
			/	CASE WHEN SUM((CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseSecondBD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID, ProgramID) = 0	--denominator
					THEN 1.00
					ELSE CAST(SUM((CASE WHEN ToddlerGradOrActive IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN ToddPhaseSecondBD IS NOT NULL THEN 1 ELSE 0 END)) OVER(PARTITION BY StateID, SiteID, ProgramID) as decimal)  
				END 
		* 100 ,1) as decimal(10,1)) TeamTotalActGrad

	FROM El7Details 
	WHERE El7Details.RankingLatest = 1
		AND--cut down on # records/time	----to 58,50 recs/0.37 secs  from  202,372 recs/1.50 mins
		(
			PregPhaseServed IS NOT NULL OR 
			PregPhaseCompleted IS NOT NULL OR 
			PregPhaseStillActive IS NOT NULL OR
			PregPhaseLeftProgram IS NOT NULL OR
			PregPhaseLeftPgmBfEDD IS NOT NULL OR

			InfPhaseServed IS NOT NULL OR 
			InfPhaseCompleted IS NOT NULL OR 
			InfPhaseStillActive IS NOT NULL OR 
			InfPhaseLeftProgram IS NOT NULL OR 
			InfPhaseLeftPgmBf1stBD IS NOT NULL OR 

			ToddPhaseServed IS NOT NULL OR 
			ToddPhaseCompleted IS NOT NULL OR 
			ToddPhaseStillActive IS NOT NULL OR
			ToddPhaseLeftProgram IS NOT NULL OR
			ToddPhaseLeftPgmBf2ndBD IS NOT NULL OR

			ToddPhaseSecondBD IS NOT NULL OR 
			ToddlerGradOrActive IS NOT NULL OR

			TotalServed IS NOT NULL OR
			TotalStillActive IS NOT NULL  OR
			TotalGraduated IS NOT NULL  OR
			TotalLeftProgram IS NOT NULL 			
		)

)--end cte El7DetailsWAggregates

------===========================================================================================

SELECT El7DetailsWAggregates.*
FROM El7DetailsWAggregates
	JOIN @TeamTable parm								----report selection
		ON parm.Value = El7DetailsWAggregates.ProgramID	----TeamTable contains team program ids

----===========================================================================================
----for testing

--ORDER BY StateID, SiteID, ProgramID--, CLID

--ORDER BY CLID, StateID, SiteID, ProgramID

----for testing
------===========================================================================================

GO
