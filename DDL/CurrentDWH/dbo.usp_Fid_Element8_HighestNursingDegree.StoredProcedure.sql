USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Element8_HighestNursingDegree]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_Fid_Element8_HighestNursingDegree]
(	@StartDate		Date 
	,@EndDate		Date 
	,@Team			VARCHAR(MAX) 
)
AS

If object_id('tempdb..#SurveyDetails8') is not null
	Drop Table #SurveyDetails8
	
------===========================================================================================
------for testing

--DECLARE 
--	@StartDate		Date 
--	,@EndDate		Date 
--	,@Team			VARCHAR(MAX)
--	,@Agency			VARCHAR(MAX)
	
--SET @StartDate		 = CAST('4/1/2014' AS DATE)
--SET @EndDate		 = CAST('3/31/2015' AS DATE)

--------all teams
--SET @Team = '1857,1700,812,1605,1808,1532,872,875,878,1937,911,914,1796,1949,1823,1985,1820,1752,1755,1764,1767,1770,1779,851,848,845,842,839,836,827,1712,833,830,1773,824,821,818,1744,815,962,965,968,884,887,1668,1388,1391,1535,1557,1394,1397,1400,1404,1554,1617,1620,1576,860,863,866,1943,869,1988,857,854,971,974,977,983,980,986,989,992,995,998,1887,1001,1004,1007,1010,2010,1013,1922,1925,1671,881,1928,944,947,1566,1647,1655,1658,1967,1973,1976,1982,2032,1703,1709,893,1894,1860,1761,950,1581,1584,1602,1454,1461,1608,1688,1697,2001,1912,953,1047,1049,1052,1641,1055,1058,956,959,1016,1019,1031,1034,1037,1064,1070,1073,1076,1587,1651,1079,890,920,899,917,1563,1749,1758,1793,2013,1805,1706,1871,896,902,935,938,941,905,1722,908,923,926,1900,1061,1067,1082,1814,1817,1829,1739,1992,1995,1040,1043,1148,1151,1085,1848,1022,1025,1028,1715,1154,1979,1891,1157,1088,1091,1094,1097,1100,1897,1103,1106,1109,1626,1112,1115,1118,1121,1124,1127,1130,1133,1136,1139,1142,1145,1169,1172,1160,1163,1166,1175,1178,1181,1184,1187,1961,1906,1244,929,932,1538,1409,1436,1439,1443,1446,1449,1452,1457,1463,1467,1472,1412,1475,1478,1481,1484,1487,1490,1560,1915,1415,1418,1421,1424,1427,1430,1433,1611,1190,1193,1934,1854,2023,1727,1799,1802,1844,1199,1202,1205,1208,1694,1213,1217,1946,1221,1196,1211,1233,781,780,779,1253,1256,1940,1247,1239,1884,1250,1280,1227,1790,1746,1224,1230,1236,1661,1242,1259,1262,1268,1274,1283,1289,1370,1298,1310,1998,1349,1295,1301,1286,1313,1644,2004,2007,1826,1265,1863,1316,1322,1352,1304,1307,1623,1599,1680,1683,1868,2016,2020,1832,1838,1782,1785,1776,1638,1469,1337,1346,1271,1964,1277,1319,1334,1343,1358,1361,1364,1355,748,1292,1664,1875,1903,1909,1841,1851,1970,1674,1677,1367,1325,1328,1331,1918,1373,1379,1382,1376,1952,1385,1573,1406,1931,1879,1835,1811,1730,1340,1718,1955,1958,2026,1493,1520,1523,1526,1529,1570,1496,1499,1502,1505,1508,1511,1514,1517'

----for testing
------===========================================================================================
----split multi parameters into table
DECLARE @TeamTable TABLE(Value BIGINT) 
DECLARE @xt XML  
SELECT @xt = CAST('<A>'+ REPLACE(@Team,',','</A><A>')+ '</A>' AS XML) 
INSERT INTO @TeamTable             
SELECT t.value('.', 'int') AS inVal 
FROM @xt.nodes('/A') AS xt(t) 
----------------------------------------------------------------------------------------------
------from fn_FID_Staff_list & fn_Fidelity_Staff_El8
;WITH StfInfo AS
(		SELECT 
			SiteID
			,ProgramID
			,Entity_Id
			,Row_Number() OVER(Partition By Entity_Id, SiteID 
					Order By SiteID desc) RowNumberByAgency ----used for aggregates so that only at team level can entity count > 1 
		FROM dbo.fn_FID_Staff_list (@StartDate, @EndDate)	
		WHERE (EndDate > @EndDate OR EndDate IS NULL) 
			AND (NHV_Flag > 0 
				OR NS_Flag > 0 
				OR HV_FTE > 0 
				OR S_FTE > 0)	
) --end cte
----from fn_FID_Staff_list & fn_Fidelity_Staff_El8
------------=================================================================================

SELECT DISTINCT
	p.Abbreviation StateAbbr
	,p.[US State] [State]
	,p.StateID
	,p.SiteID
	,p.Site SiteName
	,p.ProgramID
	,CASE 
		WHEN p.Team_Name IS NOT NULL
			THEN p.Team_Name
		WHEN p.Team_Name IS NULL AND p.ProgramName like '%Nurse Home Visiting-%'
			THEN 
				REPLACE(
					REPLACE(p.ProgramName, SUBSTRING(p.ProgramName,1,CHARINDEX('-',p.ProgramName)), '' ) ---replace text up to 1st dash in program name with nothing
						,'Nurse Home Visiting-','') ---replace 'Nurse Home Visiting-' in the program name with nothing
		WHEN p.Team_Name IS NULL AND p.ProgramName like '%Referral and Intake-%'
			THEN 
				REPLACE(
					REPLACE(p.ProgramName, SUBSTRING(p.ProgramName,1,CHARINDEX('-',p.ProgramName)), '' ) ---replace text up to 1st dash in program name with nothing
						,'Referral and Intake-','') ---replace 'Referral and Intake-' in program name with nothing
		WHEN p.Team_Name IS NULL AND p.ProgramName like '%Staff Supervision-%'
			THEN 
				REPLACE(
					REPLACE(p.ProgramName, SUBSTRING(p.ProgramName,1,CHARINDEX('-',p.ProgramName)), '' ) ---replace text up to 1st dash in program name with nothing
						,'Staff Supervision-','') ---replace 'Staff Supervision-' in program name with nothing
			ELSE NULL ----if NULL, then whatever program this is will need to be looked into
		END TeamName
	,1 NationalID
	,'National' NationalName	
	
	,(CASE WHEN edu.Degree = 1 THEN stf.Entity_Id END) Doctorate
	,(CASE WHEN edu.Degree = 2 THEN stf.Entity_Id END) Masters
	,(CASE WHEN edu.Degree = 3 THEN stf.Entity_Id END) Bachelors
	,(CASE WHEN edu.Degree = 4 THEN stf.Entity_Id END) Associates
	,(CASE WHEN edu.Degree = 5 THEN stf.Entity_Id END) Diploma
	,(CASE WHEN edu.Degree = 6 THEN stf.Entity_Id END) NA
	,(CASE WHEN ISNULL(Edu.Degree,7) = 7 THEN stf.Entity_Id END) Missing
	,(CASE WHEN ISNULL(Edu.Degree,7) BETWEEN 1 AND 7 THEN stf.Entity_Id END) TotalDegrees

	--------aggregates	
	--------National
	,SUM(CASE WHEN edu.Degree = 1 AND RowNumberByAgency = 1 THEN 1 ELSE 0 END) OVER() NationalDoctorate
	,SUM(CASE WHEN edu.Degree = 2 AND RowNumberByAgency = 1 THEN 1 ELSE 0 END) OVER() NationalMasters
	,SUM(CASE WHEN edu.Degree = 3 AND RowNumberByAgency = 1 THEN 1 ELSE 0 END) OVER() NationalBachelors
	,SUM(CASE WHEN edu.Degree = 4 AND RowNumberByAgency = 1 THEN 1 ELSE 0 END) OVER() NationalAssociates
	,SUM(CASE WHEN edu.Degree = 5 AND RowNumberByAgency = 1 THEN 1 ELSE 0 END) OVER() NationalDiploma
	,SUM(CASE WHEN edu.Degree = 6 AND RowNumberByAgency = 1 THEN 1 ELSE 0 END) OVER() NationalNA
	,SUM(CASE WHEN ISNULL(Edu.Degree,7) = 7 AND RowNumberByAgency = 1 THEN 1 ELSE 0 END) OVER() NationalMissing
	,SUM(CASE WHEN ISNULL(Edu.Degree,7) BETWEEN 1 AND 7 AND RowNumberByAgency = 1 THEN 1 ELSE 0 END) OVER() NationalTotal

	--------State
	,SUM(CASE WHEN edu.Degree = 1 AND RowNumberByAgency = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY p.StateID) StateDoctorate
	,SUM(CASE WHEN edu.Degree = 2 AND RowNumberByAgency = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY p.StateID) StateMasters
	,SUM(CASE WHEN edu.Degree = 3 AND RowNumberByAgency = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY p.StateID) StateBachelors
	,SUM(CASE WHEN edu.Degree = 4 AND RowNumberByAgency = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY p.StateID) StateAssociates
	,SUM(CASE WHEN edu.Degree = 5 AND RowNumberByAgency = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY p.StateID) StateDiploma
	,SUM(CASE WHEN edu.Degree = 6 AND RowNumberByAgency = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY p.StateID) StateNA
	,SUM(CASE WHEN ISNULL(Edu.Degree,7) = 7 AND RowNumberByAgency = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY p.StateID) StateMissing
	,SUM(CASE WHEN ISNULL(Edu.Degree,7) BETWEEN 1 AND 7 AND RowNumberByAgency = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY p.StateID) StateTotal
	
	--------Agency
	,SUM(CASE WHEN edu.Degree = 1 AND RowNumberByAgency = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY p.StateID, p.SiteID) AgencyDoctorate
	,SUM(CASE WHEN edu.Degree = 2 AND RowNumberByAgency = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY p.StateID, p.SiteID) AgencyMasters
	,SUM(CASE WHEN edu.Degree = 3 AND RowNumberByAgency = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY p.StateID, p.SiteID) AgencyBachelors
	,SUM(CASE WHEN edu.Degree = 4 AND RowNumberByAgency = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY p.StateID, p.SiteID) AgencyAssociates
	,SUM(CASE WHEN edu.Degree = 5 AND RowNumberByAgency = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY p.StateID, p.SiteID) AgencyDiploma
	,SUM(CASE WHEN edu.Degree = 6 AND RowNumberByAgency = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY p.StateID, p.SiteID) AgencyNA
	,SUM(CASE WHEN ISNULL(Edu.Degree,7) = 7 AND RowNumberByAgency = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY p.StateID, p.SiteID) AgencyMissing
	,SUM(CASE WHEN ISNULL(Edu.Degree,7) BETWEEN 1 AND 7 AND RowNumberByAgency = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY p.StateID, p.SiteID) AgencyTotal

	--------Team/Program
	,SUM(CASE WHEN edu.Degree = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY p.StateID, p.SiteID, p.ProgramID) TeamDoctorate
	,SUM(CASE WHEN edu.Degree = 2 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY p.StateID, p.SiteID, p.ProgramID) TeamMasters
	,SUM(CASE WHEN edu.Degree = 3 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY p.StateID, p.SiteID, p.ProgramID) TeamBachelors
	,SUM(CASE WHEN edu.Degree = 4 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY p.StateID, p.SiteID, p.ProgramID) TeamAssociates
	,SUM(CASE WHEN edu.Degree = 5 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY p.StateID, p.SiteID, p.ProgramID) TeamDiploma
	,SUM(CASE WHEN edu.Degree = 6 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY p.StateID, p.SiteID, p.ProgramID) TeamNA
	,SUM(CASE WHEN ISNULL(Edu.Degree,7) = 7 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY p.StateID, p.SiteID, p.ProgramID) TeamMissing
	,SUM(CASE WHEN ISNULL(Edu.Degree,7) BETWEEN 1 AND 7 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY p.StateID, p.SiteID, p.ProgramID) TeamTotal
----------------------------------------------------------------------------------------
INTO #SurveyDetails8

FROM UV_PAS p
	JOIN StfInfo stf ON stf.ProgramID = P.ProgramID	----cte								
	LEFT JOIN	----from fn_Fidelity_Staff_El8
	(	SELECT
			sus.CL_EN_GEN_ID
			,sus.SiteID
			,MIN(CASE 
					WHEN sus.NURSE_EDUCATION_0_NURSING_DEGREES LIKE '%Doctor%' THEN 1 
					 WHEN sus.NURSE_EDUCATION_0_NURSING_DEGREES LIKE 'Master%' THEN 2
					 WHEN sus.NURSE_EDUCATION_0_NURSING_DEGREES LIKE 'Bachelor%' THEN 3
					 WHEN sus.NURSE_EDUCATION_0_NURSING_DEGREES LIKE 'Associate%' THEN 4
					 WHEN sus.NURSE_EDUCATION_0_NURSING_DEGREES LIKE 'Diplom%' THEN 5 
					 WHEN sus.NURSE_EDUCATION_0_NURSING_DEGREES LIKE 'Not app%' THEN 6  
					 WHEN sus.NURSE_EDUCATION_0_NURSING_DEGREES IS NULL THEN 7 
				END) Degree
		FROM Staff_Update_Survey sus
		WHERE sus.SurveyDate <= @EndDate
		GROUP BY sus.CL_EN_GEN_ID, sus.SiteID
	) Edu ON stf.Entity_Id = Edu.CL_EN_GEN_ID
		AND stf.SiteID = Edu.SiteID

------===========================================================================================

SELECT #SurveyDetails8.*
FROM #SurveyDetails8
	JOIN @TeamTable parm							----report selection
		ON parm.Value = #SurveyDetails8.ProgramID	----TeamTable contains team program ids
		
----===========================================================================================
----for testing

--ORDER BY StateID, SiteID, ProgramID, TotalDegrees

----for testing
------===========================================================================================
GO
