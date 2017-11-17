USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Element5_OneToOneVisit]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

---------------------
----Element 5
----OneOnOne
---------------------

CREATE PROCEDURE [dbo].[usp_Fid_Element5_OneToOneVisit]
(	@StartDate		Date 
	,@EndDate		Date 
	,@Team			VARCHAR(max) 
)
AS

If object_id('tempdb..#SurveyDetails5a') is not null
	Drop Table #SurveyDetails5a
	
If object_id('tempdb..#SurveyDetails5b') is not null
	Drop Table #SurveyDetails5b
	
------===========================================================================================
--for testing

--DECLARE 
--	@StartDate		Date 
--	,@EndDate		Date 
--	,@Team			VARCHAR(max)

--SET @StartDate		 = CAST('4/1/2014' AS DATE)
--SET @EndDate		 = CAST('3/31/2015' AS DATE)
--------all teams
--SET @Team = '1224,1958,1808,1394,1820,1493,896,1617,1651,1319,1879,917,854,1844,1912,1826,1538,929,932,1163,1166,1976,1061,1040,1397,1677,1563,1157,1496,1499,1043,1644,1502,2016,1906,1838,1109,1611,1928,881,1505,1409,1412,1415,1418,1421,1424,1427,1430,1433,1436,1439,1443,1446,1449,1452,1457,1463,1467,1472,1475,1478,1915,1481,1484,1487,1490,1298,1376,1952,1367,935,1253,1233,1244,1709,2020,1755,1931,1508,1196,1605,857,1988,1793,2013,1854,1584,1658,860,1937,1700,1909,1868,971,974,1088,1875,1903,977,1154,1706,1623,1829,1674,1511,1079,1715,1805,1894,812,1782,1608,1688,1697,2001,1514,923,1310,1998,1121,1124,1982,1322,818,1703,1271,1964,1967,1091,824,1773,1749,986,2023,1304,1955,890,1871,1461,1454,1730,899,1325,1576,1811,1400,1213,1799,1638,863,1668,1352,1570,1802,1620,2004,1358,1217,1946,1718,1307,2007,1770,866,1943,1340,1817,1094,1127,1130,1925,980,1190,1934,1193,902,1343,1346,1973,1897,989,1256,1940,1626,1587,1239,1884,1286,1236,1661,779,780,781,1221,1022,1242,1211,1025,1028,1283,1313,1250,1280,1268,1247,1148,1370,1289,983,1301,1295,1602,1532,1328,1922,1739,992,1680,1683,920,1133,965,968,938,944,947,1566,1761,1517,1355,1097,1139,1985,1647,1274,1520,1277,1891,1857,1136,869,1142,1145,956,1055,1016,1019,1031,1034,1058,1037,1064,1049,1052,1641,1070,1073,1047,1076,959,926,1900,995,1331,1160,836,1085,1848,1992,1851,1535,1388,1391,1259,1262,1758,1292,839,884,887,842,827,821,1764,962,1779,848,1115,1118,1265,1863,1918,1655,1767,1316,1373,830,845,875,878,1004,1067,1112,1100,1349,1379,998,1887,953,1082,1841,1752,1785,941,1995,1523,1694,1385,1573,1334,1169,1172,1199,833,1202,1712,1205,1208,1230,1832,1382,815,1227,905,1722,1744,1790,1746,1103,1007,1010,2010,1404,911,1796,914,1949,851,748,1526,1727,1469,950,1554,1557,1560,1106,1337,1001,1671,1860,1979,1175,1178,1181,1184,1187,1961,893,1151,1970,1013,1664,1529,1835,1599,1776,908,1406,1823,872,1814,1361,1364,1581'

----for testing
------===========================================================================================

----split multi parameters into table
DECLARE @TeamTable TABLE(Value BIGINT) 
DECLARE @x XML  
SELECT @x = CAST('<A>'+ REPLACE(@Team,',','</A><A>')+ '</A>' AS XML) 
INSERT INTO @TeamTable             
SELECT t.value('.', 'int') AS inVal 
FROM @x.nodes('/A') AS x(t) 

----------------------------------------------------------------------------------------------
/*
Calculated Variable
OneOnOne

Measure
Calculates the percentage and count of  Completed Home Visits involving only one client

Numerator
Count of Completed Home Visits involving only one client for a specific entity during a given time period

Denominator 
Count of Completed Home Visits  for a specific entity during a given time period

*/
----------------------------------------------------------------------------------------------
----get surveys and flag where one-on-one 
SELECT SurveyResponseID
	, ProgramID
	, CL_EN_GEN_ID CLID
	, SiteID
	, NURSE_PERSONAL_0_NAME NurseID
	, SurveyDate
	, CLIENT_TIME_0_START_VISIT
	, 1 OneOnOneTotal
	, CASE WHEN COUNT(*) OVER(Partition By NURSE_PERSONAL_0_NAME, SurveyDate, 
						UPPER(CLIENT_TIME_0_START_VISIT), ProgramID, SiteID) = 1
		THEN 1 ELSE 0
	END OneOnOneYes	
	, CASE WHEN COUNT(*) OVER(Partition By NURSE_PERSONAL_0_NAME, SurveyDate, 
						UPPER(CLIENT_TIME_0_START_VISIT), ProgramID, SiteID) <> 1
		THEN 1 ELSE 0
	END OneOnOneNo	

INTO #SurveyDetails5a
FROM HOME_VISIT_ENCOUNTER_SURVEY survey
WHERE (SurveyDate >= @StartDate AND SurveyDate <= @EndDate) 
	AND CLIENT_COMPLETE_0_VISIT = 'Completed'
	AND survey.NURSE_PERSONAL_0_NAME IS NOT NULL
	
----------------------------------------------------------	
----calculate aggregates while adding other necessary information
SELECT 
	survey.SurveyResponseID
	,survey.CLID
	,survey.NurseID
	,survey.SurveyDate
	,UPPER(survey.CLIENT_TIME_0_START_VISIT) CLIENT_TIME_0_START_VISIT
	,survey.OneOnOneTotal
	,survey.OneOnOneYes
	
	,pas.Abbreviation StateAbbr
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
	
----**** these particular aggregates cannot be done in the previous step because a Windows function
----**** cannot contain another Windows function; OneOnOneYes is calculated/partitioned with a Windows function
	
	----aggregates	
	
	----National
	,SUM(OneOnOneYes) OVER() NationalTotalYes
	,SUM(OneOnOneNo) OVER() NationalTotalNo
	,SUM(OneOnOneTotal) OVER() NationalTotalHasData
	
	----State
	,SUM(OneOnOneYes) 
		OVER (PARTITION BY pas.StateID) StateTotalYes
	,SUM(OneOnOneNo) 
		OVER (PARTITION BY pas.StateID) StateTotalNo
	,SUM(OneOnOneTotal) 
		OVER (PARTITION BY pas.StateID) StateTotalHasData
	
	----Agency
	,SUM(OneOnOneYes) 
		OVER (PARTITION BY pas.StateID, pas.SiteID) AgencyTotalYes
	,SUM(OneOnOneNo) 
		OVER (PARTITION BY pas.StateID, pas.SiteID) AgencyTotalNo
	,SUM(OneOnOneTotal) 
		OVER (PARTITION BY pas.StateID, pas.SiteID) AgencyTotalHasData
	
	----Program/Team
	,SUM(OneOnOneYes) 
		OVER (PARTITION BY pas.StateID, pas.SiteID, pas.ProgramID) ProgramTotalYes
	,SUM(OneOnOneNo) 
		OVER (PARTITION BY pas.StateID, pas.SiteID, pas.ProgramID) ProgramTotalNo
	,SUM(OneOnOneTotal) 
		OVER (PARTITION BY pas.StateID, pas.SiteID, pas.ProgramID) ProgramTotalHasData
	
	----Nurse
	,SUM(OneOnOneYes) 
		OVER (PARTITION BY pas.StateID, pas.SiteID, pas.ProgramID, survey.NurseID) NurseTotalYes
	,SUM(OneOnOneNo) 
		OVER (PARTITION BY pas.StateID, pas.SiteID, pas.ProgramID, survey.NurseID) NurseTotalNo
	,SUM(OneOnOneTotal) 
		OVER (PARTITION BY pas.StateID, pas.SiteID, pas.ProgramID, survey.NurseID) NurseTotalHasData

INTO #SurveyDetails5b
		
FROM #SurveyDetails5a survey
	JOIN UV_PAS pas ON pas.ProgramID = survey.ProgramID
	
	LEFT JOIN UC_Client_Exclusion_YWCA ywca ON ywca.CLID = survey.CLID
		AND survey.SiteID = 222 					
											
WHERE ywca.CLID IS NULL

-------------------------------------------------------------------------------------------

-----DETAIL DATA
-----client detail records 
SELECT #SurveyDetails5b.*
	, parm.Value TeamParmValue  
FROM #SurveyDetails5b 
----****This report filter cannot be added to the previous step because the aggregates 
----****	'for all records' will not be calculated properly
	JOIN @TeamTable parm							----report selection
		ON parm.Value = #SurveyDetails5b.ProgramID	----TeamTable contains team program ids

------===========================================================================================
----for testing

--ORDER BY NurseID, SurveyDate, UPPER(CLIENT_TIME_0_START_VISIT), CLID, SurveyResponseID

----for testing
------===========================================================================================
GO
