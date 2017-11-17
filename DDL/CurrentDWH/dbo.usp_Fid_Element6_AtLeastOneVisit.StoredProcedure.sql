USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Element6_AtLeastOneVisit]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

---------------------
----Element 6
----Table 2 
---------------------

CREATE PROCEDURE [dbo].[usp_Fid_Element6_AtLeastOneVisit]
(	@StartDate		Date 
	,@EndDate		Date 
	,@Team	VARCHAR(MAX) 
)
AS

If object_id('tempdb..#SurveyDetails6a') is not null
	Drop Table #SurveyDetails6a

If object_id('tempdb..#SurveyDetails6b') is not null
	Drop Table #SurveyDetails6b
	
-------------------------------------------------------------------------------------------
----for testing

------===========================================================================================
------for testing

--DECLARE 
--	@StartDate		Date 
--	,@EndDate		Date 
--	,@Team			VARCHAR(MAX)
	
--------curr	
--SET @StartDate		 = CAST('4/1/2014' AS DATE)
--SET @EndDate		 = CAST('3/31/2015' AS DATE)

------------comp
----------SET @StartDate		 = CAST('4/1/2013' AS DATE)
----------SET @EndDate		 = CAST('3/31/2014' AS DATE)


--------------all teams
--SET @Team = '748,779,780,781,812,815,818,821,824,827,830,833,836,839,842,845,848,851,854,857,860,863,866,869,872,875,878,881,884,887,890,893,896,899,902,905,908,911,914,917,920,923,926,929,932,935,938,941,944,947,950,953,956,959,962,965,968,971,974,977,980,983,986,989,992,995,998,1001,1004,1007,1010,1013,1016,1019,1022,1025,1028,1031,1034,1037,1040,1043,1047,1049,1052,1055,1058,1061,1064,1067,1070,1073,1076,1082,1085,1088,1091,1094,1097,1100,1103,1106,1109,1112,1115,1118,1121,1124,1127,1130,1133,1136,1139,1142,1145,1148,1151,1154,1157,1160,1163,1166,1169,1172,1175,1178,1181,1184,1187,1190,1193,1196,1199,1202,1205,1208,1211,1213,1217,1221,1224,1227,1230,1233,1236,1239,1242,1244,1247,1250,1253,1256,1259,1262,1265,1268,1271,1274,1277,1280,1283,1286,1289,1292,1295,1298,1301,1304,1307,1310,1313,1316,1319,1322,1325,1328,1331,1334,1337,1340,1343,1346,1349,1352,1355,1358,1361,1364,1367,1370,1373,1376,1379,1382,1385,1388,1391,1394,1397,1400,1404,1406,1409,1412,1415,1418,1421,1424,1427,1430,1433,1436,1439,1443,1446,1449,1452,1454,1457,1461,1463,1467,1469,1472,1475,1478,1481,1484,1487,1490,1493,1496,1499,1502,1505,1508,1511,1514,1517,1520,1523,1526,1529,1532,1535,1538,1554,1557,1560,1563,1566,1570,1573,1576,1581,1584,1587,1599,1602,1605,1608,1611,1617,1620,1623,1626,1638,1641,1644,1647,1651,1655,1658,1661,1664,1668,1671,1674,1677,1680,1683,1688,1694,1697,1700,1703,1706,1709,1712,1715,1718,1722,1727,1730,1739,1744,1746,1749,1752,1755,1758,1761,1764,1767,1770,1773,1776,1779,1782,1785,1790,1793,1796,1799,1802,1805,1808,1811,1814,1817,1820,1823,1826,1829,1832,1835,1838,1841,1844,1848,1851,1854,1857,1860,1863,1868,1871,1875,1879,1884,1887,1891,1894,1897,1900,1903,1906,1909,1912,1915,1918,1922,1928,1931,1934,1937,1940,1943,1946,1949,1952,1955,1958,1961,1964,1967,1970,1973,1976,1979,1982,1985,1988,1992,1995,1998,2001,2004,2007,2010,2013,2016,2020,2023,2026,2032,2035,2038,2041,2044,2049,2052'

--------OK
--------SET @Team = '1409,1412,1415,1418,1421,1424,1427,1430,1433,1436,1439,1443,1446,1449,1452,1457,1463,1467,1472,1475,1478,1481,1484,1487,1490,1560,1915'

--------VI
------SET @Team = '1841'

DECLARE 
	@rStartDate		Date 
	,@rEndDate		Date 
	,@rTeam			VARCHAR(MAX)
SET @rStartDate = @StartDate
SET @rEndDate = @EndDate
SET @rTeam = @Team

------for testing
----===========================================================================================
----split multi parameters into table
DECLARE @TeamTable TABLE(Value BIGINT) 
DECLARE @xt XML  
SELECT @xt = CAST('<A>'+ REPLACE(@rTeam,',','</A><A>')+ '</A>' AS XML) 
INSERT INTO @TeamTable             
SELECT t.value('.', 'int') AS inVal 
FROM @xt.nodes('/A') AS xt(t) 
----------------------------------------------------------------------------------------------

SELECT 
	survey.CL_EN_GEN_ID CLID
	,survey.NURSE_PERSONAL_0_NAME NurseID
	,survey.SurveyDate
	,survey.SurveyResponseID
	,survey.CLIENT_LOCATION_0_VISIT
	,CASE WHEN survey.CLIENT_LOCATION_0_VISIT LIKE 'Client%' THEN 1 ELSE 0 END HomeVisit	
	,1 CompletedVisit	
	
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

	---used to count distinct client ids
	,Row_Number() OVER(Partition By pas.ProgramID, survey.CL_EN_GEN_ID                          Order By pas.ProgramID, survey.CL_EN_GEN_ID                         ) RowNumberCompletedVisit
	,Row_Number() OVER(Partition By pas.ProgramID, survey.CL_EN_GEN_ID, CLIENT_LOCATION_0_VISIT Order By pas.ProgramID, survey.CL_EN_GEN_ID, CLIENT_LOCATION_0_VISIT) RowNumberHomeVisit

----------------------------------------------------------------------------------------------
INTO #SurveyDetails6a	

FROM ----get only the surveys needed
	(	SELECT SurveyResponseID, ProgramID, CL_EN_GEN_ID, SiteID, SurveyDate, CLIENT_LOCATION_0_VISIT, NURSE_PERSONAL_0_NAME
		FROM HOME_VISIT_ENCOUNTER_SURVEY survey
			JOIN Mstr_surveys ms ON ms.SurveyID = survey.SurveyID 
		WHERE (SurveyDate >= @rStartDate AND SurveyDate <= @rEndDate) 
			AND CLIENT_COMPLETE_0_VISIT = 'Completed'	
			AND NURSE_PERSONAL_0_NAME IS NOT NULL		
	)survey	
	
	JOIN UV_PAS pas ON pas.ProgramID = survey.ProgramID

	LEFT JOIN UC_Client_Exclusion_YWCA ywca ON ywca.CLID = survey.CL_EN_GEN_ID
		AND survey.SiteID = 222 					
											
WHERE ywca.CLID IS NULL

-------------------------------------------------------------------------------------------
SELECT 

	a.CLID
	,a.SurveyDate
	,a.SurveyResponseID
	,a.CLIENT_LOCATION_0_VISIT
	,a.HomeVisit	
	,a.CompletedVisit		
	,a.[State]
	,a.StateAbbr
	,a.StateID
	,a.SiteID
	,a.SiteName
	,a.ProgramID
	,a.TeamName
	,a.NationalID
	,a.NationalName		
	---used to count distinct client ids
	,a.RowNumberHomeVisit
	,a.RowNumberCompletedVisit

	------aggregates	

----T2	
	------National  
	,SUM(CASE WHEN a.CLID IS NOT NULL AND RowNumberCompletedVisit = 1 AND CompletedVisit = 1 THEN 1 ELSE 0 END) 
		OVER() NationalAtLeast1CompletedVisit
	,SUM(CASE WHEN a.CLID IS NOT NULL AND RowNumberHomeVisit = 1 AND HomeVisit = 1 THEN 1 ELSE 0 END) 
		OVER() NationalAtLeast1HomeVisit
	------State
	,SUM(CASE WHEN a.CLID IS NOT NULL AND RowNumberCompletedVisit = 1 AND CompletedVisit = 1 THEN 1 ELSE 0 END)  
		OVER (PARTITION BY a.StateID) StateAtLeast1CompletedVisit
	,SUM(CASE WHEN a.CLID IS NOT NULL AND RowNumberHomeVisit = 1 AND HomeVisit = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY a.StateID) StateAtLeast1HomeVisit
	------Agency
	,SUM(CASE WHEN a.CLID IS NOT NULL AND RowNumberCompletedVisit = 1 AND CompletedVisit = 1 THEN 1 ELSE 0 END)  
		OVER (PARTITION BY a.StateID, a.SiteID) AgencyAtLeast1CompletedVisit
	,SUM(CASE WHEN a.CLID IS NOT NULL AND RowNumberHomeVisit = 1 AND HomeVisit = 1 THEN 1 ELSE 0 END)
		OVER (PARTITION BY a.StateID, a.SiteID) AgencyAtLeast1HomeVisit
	------Program/Team
	,SUM(CASE WHEN a.CLID IS NOT NULL AND RowNumberCompletedVisit = 1 AND CompletedVisit = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY a.StateID, a.SiteID, a.ProgramID) TeamAtLeast1CompletedVisit
	,SUM(CASE WHEN a.CLID IS NOT NULL AND RowNumberHomeVisit = 1 AND HomeVisit = 1 THEN 1 ELSE 0 END)
		OVER (PARTITION BY a.StateID, a.SiteID, a.ProgramID) TeamAtLeast1HomeVisit
	--------Client
	,SUM(CASE WHEN a.CLID IS NOT NULL AND RowNumberCompletedVisit = 1 AND CompletedVisit = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY a.StateID, a.SiteID, a.ProgramID/*, a.NurseID*/, a.CLID) ClientAtLeast1CompletedVisit
	,SUM(CASE WHEN a.CLID IS NOT NULL AND RowNumberHomeVisit = 1 AND HomeVisit = 1 THEN 1 ELSE 0 END)
		OVER (PARTITION BY a.StateID, a.SiteID, a.ProgramID/*, a.NurseID*/, a.CLID) ClientAtLeast1HomeVisit


INTO #SurveyDetails6b

FROM #SurveyDetails6a a

-----------------------------------------------------------------------------------------------------------------

------ b has details plus aggregates
SELECT 

	b.CLID, b.CLIENT_LOCATION_0_VISIT
	,b.HomeVisit, b.CompletedVisit		
	,b.[State], b.StateAbbr, b.StateID
	,b.SiteID, b.SiteName
	,b.ProgramID, b.TeamName
	,b.NationalID, b.NationalName		
	,b.RowNumberHomeVisit, b.RowNumberCompletedVisit
	
	,b.NationalAtLeast1CompletedVisit, NationalAtLeast1HomeVisit
	,b.StateAtLeast1CompletedVisit, StateAtLeast1HomeVisit
	,b.AgencyAtLeast1CompletedVisit, AgencyAtLeast1HomeVisit
	,b.TeamAtLeast1CompletedVisit, TeamAtLeast1HomeVisit
	,b.ClientAtLeast1HomeVisit, b.ClientAtLeast1CompletedVisit
	
	,CASE WHEN b.NationalAtLeast1CompletedVisit > 0 THEN
		CAST(	ROUND( CAST(b.NationalAtLeast1HomeVisit as decimal) / CAST(b.NationalAtLeast1CompletedVisit as decimal) * 100  ,1) as decimal(10,1) ) 
	END NationalVisitsInHomePerClientPercent
	,CASE WHEN b.StateAtLeast1CompletedVisit > 0 THEN
		CAST(	ROUND( CAST(b.StateAtLeast1HomeVisit as decimal) / CAST(b.StateAtLeast1CompletedVisit as decimal) * 100  ,1) as decimal(10,1) ) 
	END StateVisitsInHomePerClientPercent
	,CASE WHEN b.AgencyAtLeast1CompletedVisit > 0 THEN
		CAST(	ROUND( CAST(b.AgencyAtLeast1HomeVisit as decimal) / CAST(b.AgencyAtLeast1CompletedVisit as decimal) * 100  ,1) as decimal(10,1) ) 
	END AgencyVisitsInHomePerClientPercent
	,CASE WHEN b.TeamAtLeast1CompletedVisit > 0 THEN
		CAST(	ROUND( CAST(b.TeamAtLeast1HomeVisit as decimal) / CAST(b.TeamAtLeast1CompletedVisit as decimal) * 100  ,1) as decimal(10,1) ) 
	END TeamVisitsInHomePerClientPercent
	,CASE WHEN b.ClientAtLeast1CompletedVisit > 0 THEN
		CAST(	ROUND( CAST(b.ClientAtLeast1HomeVisit as decimal) / CAST(b.ClientAtLeast1CompletedVisit as decimal) * 100  ,1) as decimal(10,1) ) 
	END ClientVisitsInHomePerClientPercent
FROM #SurveyDetails6b b
	JOIN @TeamTable parm			----report selection
		ON parm.Value = b.ProgramID	----TeamTable contains team program ids
		
-------------------------------------------------------------------------------------------
-------for testing

--ORDER BY StateID, SiteID, ProgramID, CLID, CLIENT_LOCATION_0_VISIT, SurveyDate

-------for testing
----------------------------------------------------------------------------------------

GO
