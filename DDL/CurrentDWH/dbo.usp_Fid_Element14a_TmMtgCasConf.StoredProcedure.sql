USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Element14a_TmMtgCasConf]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_Fid_Element14a_TmMtgCasConf]
(	@StartDate		Date 
	,@EndDate		Date 
	,@Team			VARCHAR(MAX) 
)
AS

If object_id('tempdb..#SurveyDetails14a1') is not null
	Drop Table #SurveyDetails14a1

If object_id('tempdb..#SurveyDetails14a2') is not null
	Drop Table #SurveyDetails14a2
	
------===========================================================================================
--for testing

--DECLARE 
--	@StartDate		Date 
--	,@EndDate		Date 
--	,@Team			VARCHAR(MAX)

--SET @StartDate		 = CAST('4/1/2014' AS DATE)
--SET @EndDate		 = CAST('3/31/2015' AS DATE)
--------all teams
--SET @Team = '748,779,780,781,812,815,818,821,824,827,830,833,836,839,842,845,848,851,854,857,860,863,866,869,872,875,878,881,884,887,890,893,896,899,902,905,908,911,914,917,920,923,926,929,932,935,938,941,944,947,950,953,956,959,962,965,968,971,974,977,980,983,986,989,992,995,998,1001,1004,1007,1010,1013,1016,1019,1022,1025,1028,1031,1034,1037,1040,1043,1047,1049,1052,1055,1058,1061,1064,1067,1070,1073,1076,1079,1082,1085,1088,1091,1094,1097,1100,1103,1106,1109,1112,1115,1118,1121,1124,1127,1130,1133,1136,1139,1142,1145,1148,1151,1154,1157,1160,1163,1166,1169,1172,1175,1178,1181,1184,1187,1190,1193,1196,1199,1202,1205,1208,1211,1213,1217,1221,1224,1227,1230,1233,1236,1239,1242,1244,1247,1250,1253,1256,1259,1262,1265,1268,1271,1274,1277,1280,1283,1286,1289,1292,1295,1298,1301,1304,1307,1310,1313,1316,1319,1322,1325,1328,1331,1334,1337,1340,1343,1346,1349,1352,1355,1358,1361,1364,1367,1370,1373,1376,1379,1382,1385,1388,1391,1394,1397,1400,1404,1406,1409,1412,1415,1418,1421,1424,1427,1430,1433,1436,1439,1443,1446,1449,1452,1454,1457,1461,1463,1467,1469,1472,1475,1478,1481,1484,1487,1490,1493,1496,1499,1502,1505,1508,1511,1514,1517,1520,1523,1526,1529,1532,1535,1538,1554,1557,1560,1563,1566,1570,1573,1576,1581,1584,1587,1599,1602,1605,1608,1611,1617,1620,1623,1626,1638,1641,1644,1647,1651,1655,1658,1661,1664,1668,1671,1674,1677,1680,1683,1688,1694,1697,1700,1703,1706,1709,1712,1715,1718,1722,1727,1730,1739,1744,1746,1749,1752,1755,1758,1761,1764,1767,1770,1773,1776,1779,1782,1785,1790,1793,1796,1799,1802,1805,1808,1811,1814,1817,1820,1823,1826,1829,1832,1835,1838,1841,1844,1848,1851,1854,1857,1860,1863,1868,1871,1875,1879,1884,1887,1891,1894,1897,1900,1903,1906,1909,1912,1915,1918,1922,1925,1928,1931,1934,1937,1940,1943,1946,1949,1952,1955,1958,1961,1964,1967,1970,1973,1976,1979,1982,1985,1988,1992,1995,1998,2001,2004,2007,2010,2013,2016,2020,2023,2026,2032'

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
DECLARE @x XML  
SELECT @x = CAST('<A>'+ REPLACE(@rTeam,',','</A><A>')+ '</A>' AS XML) 
INSERT INTO @TeamTable             
SELECT t.value('.', 'int') AS inVal 
FROM @x.nodes('/A') AS x(t) 

----------------------------------------------------------------------------------------------
----replaces fn_Fidelity_Agency

	SELECT 
		TS.SurveyDate
		,TS.CL_EN_GEN_ID NurseID
		,TS.ProgramID----this is the staff suprevision program ID
		,TS.SurveyResponseID				
		,TS.AGENCY_MEETING_0_TYPE
		,CASE WHEN TS.AGENCY_MEETING_0_TYPE = ('Case Conference') THEN 1 ELSE 0 END MeetingsCase
		,CASE WHEN TS.AGENCY_MEETING_0_TYPE = ('Team Meeting') THEN 1 ELSE 0 END  MeetingsTeam
		,RANK() OVER(PARTITION BY TS.SurveyDate,TS.CL_EN_GEN_ID,TS.ProgramID,TS.AGENCY_MEETING_0_TYPE 
			ORDER BY TS.SurveyDate DESC,TS.SurveyResponseID DESC) RankingLatest
	INTO #SurveyDetails14a1
	FROM Team_Meetings_Conf_Survey TS		
	WHERE TS.SurveyDate BETWEEN @rStartDate AND @rEndDate			
	------  ==>>  put in 2nd temp table ==>> AND SurveysByDate.RankingLatest = 1
	
----replaces fn_Fidelity_Agency
------------=================================================================================

SELECT DISTINCT 
	survey.SurveyDate
	,survey.NurseID
	,survey.SurveyResponseID
	,survey.AGENCY_MEETING_0_TYPE
	,survey.MeetingsTeam
	,survey.MeetingsCase	

	,pas.StateAbbr
	,pas.[State]
	,pas.StateID
	,pas.SiteID
	,pas.SiteName
	,pas.ProgramID		----this is the pas nhv program ID that corresponds to the stf supv ProgramID = Team parameter
	,pas.TeamName
	,pas.NationalID
	,pas.NationalName
	
	------aggregates	
	------National
	,SUM(survey.MeetingsTeam) OVER() NationalTotalTeam
	,SUM(survey.MeetingsCase) OVER() NationalTotalCase
	----State
	,SUM(survey.MeetingsTeam)  
		OVER (PARTITION BY pasStf.StateID) StateTotalTeam
	,SUM(survey.MeetingsCase)
		OVER (PARTITION BY pasStf.StateID) StateTotalCase	
	----Agency
	,SUM(survey.MeetingsTeam)  
		OVER (PARTITION BY pasStf.StateID, pasStf.SiteID) AgencyTotalTeam
	,SUM(survey.MeetingsCase)
		OVER (PARTITION BY pasStf.StateID, pasStf.SiteID) AgencyTotalCase
	----Program/Team
	,SUM(survey.MeetingsTeam)  
		OVER (PARTITION BY pasStf.StateID, pasStf.SiteID, pasStf.ProgramID) ProgramTotalTeam
	,SUM(survey.MeetingsCase)
		OVER (PARTITION BY pasStf.StateID, pasStf.SiteID, pasStf.ProgramID) ProgramTotalCase
			
INTO #SurveyDetails14a2

FROM #SurveyDetails14a1 survey	

	JOIN UV_PASWithTribal pasStf ON pasStf.ProgramID = survey.ProgramID
	JOIN UV_PASWithTribal pas ON (pas.SiteID = pasStf.SiteID 
								AND pas.ProgramNumber = pasStf.ProgramNumber
								AND pas.ProgramType = 2)	----NOTE: nhv IDs corresponding to staff supv IDs

WHERE survey.RankingLatest = 1

------------------------------------------------------
SELECT #SurveyDetails14a2.*
	,parm.Value TeamParmValue  
FROM #SurveyDetails14a2
	JOIN @TeamTable parm								----report selection
		ON parm.Value = #SurveyDetails14a2.ProgramID	----TeamTable contains team program ids

----===========================================================================================
----for testing

--ORDER BY StateID, SiteID, ProgramID, SurveyDate, NurseID, SurveyResponseID--

----for testing
------===========================================================================================
GO
