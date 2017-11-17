USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Element10_VisitPhase]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

---------------------
----Element 10
----PhaseOfVisit
---------------------

CREATE PROCEDURE [dbo].[usp_Fid_Element10_VisitPhase]
(	@StartDate		Date 
	,@EndDate		Date 
	,@Team			VARCHAR(max)
)
AS

If object_id('tempdb..#SurveyDetails10a') is not null
	Drop Table #SurveyDetails10a
	
If object_id('tempdb..#SurveyDetails10b') is not null
	Drop Table #SurveyDetails10b

If object_id('tempdb..#SurveyDetails10c') is not null
	Drop Table #SurveyDetails10c
		
If object_id('tempdb..#IBS') is not null
	Drop Table #IBS

If object_id('tempdb..#EAD') is not null
	Drop Table #EAD

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
/*
Calculated Variable
PhaseOfVisit

Measure
Creates a temp table listing the phase for each visit that occurred during the period 
that is associated with the entity

*/
----------------------------------------------------------------------------------------------
----NOTE:  Not using survey CTE here, since all of the surveys in the report period 
----are being used in calculations, not just the latest
----------------------------------------------------------------------------------------------
----temp tables used in visit phase
SELECT 
	CL_EN_GEN_ID
	,ProgramID
	,SurveyDate
	,SurveyResponseID
	,INFANT_BIRTH_0_DOB
	,ROW_NUMBER() OVER(PARTITION BY CL_EN_GEN_ID, ProgramID ORDER BY SurveyDate DESC, SurveyResponseID DESC) LatestSurvey
INTO #IBS
FROM Infant_Birth_Survey

SELECT 
	CLID
	,ProgramID
	,ProgramStartDate
	,ROW_NUMBER() OVER(PARTITION BY CLID, ProgramID ORDER BY ProgramStartDate) EarliestEnrollment
INTO #EAD
FROM EnrollmentAndDismissal					
----end temp tables used in visit phase
----------------------------------------------------------------------------------------------
SELECT 
	survey.CL_EN_GEN_ID CLID
	,survey.SurveyDate
	,survey.SurveyResponseID
	,CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT
	,CLIENT_DOMAIN_0_MATERNAL_VISIT
	,CLIENT_DOMAIN_0_PERSHLTH_VISIT
	,CLIENT_DOMAIN_0_LIFECOURSE_VISIT
	,CLIENT_DOMAIN_0_FRNDFAM_VISIT
------------------------------------------------------------------------------------------------------------------
----replaces udf_PhasebyDate()function
,CASE 
	WHEN survey.CL_EN_GEN_ID IS NOT NULL AND #EAD.CLID IS NOT NULL	----client has survey and enrollment records
		THEN				
	CASE 
		WHEN survey.SurveyDate BETWEEN #EAD.ProgramStartDate AND DATEADD(DAY,-1,#IBS.INFANT_BIRTH_0_DOB)
			OR #IBS.INFANT_BIRTH_0_DOB IS NULL
		THEN 'Pregnancy'
		WHEN survey.SurveyDate BETWEEN #IBS.INFANT_BIRTH_0_DOB AND DATEADD(DAY,365.24,#IBS.INFANT_BIRTH_0_DOB)
		THEN 'Infancy'
		WHEN survey.SurveyDate BETWEEN DATEADD(DAY,365.25,#IBS.INFANT_BIRTH_0_DOB) AND DATEADD(DAY,730.5,#IBS.INFANT_BIRTH_0_DOB)
		THEN 'Toddler'
	END
		ELSE NULL ----no client id on home visit survey
END PhaseOfVisit --[Visit Phase function] 
------------------------------------------------------------------------------------------------------------------
	,pas.StateAbbr
	,pas.[State]
	,pas.StateID
	,pas.SiteID
	,pas.SiteName
	,pas.ProgramID
	,pas.TeamName
	,pas.NationalID
	,pas.NationalName
	
----------------------------------------------------------------------------------------------
INTO #SurveyDetails10a	

FROM ----get only the surveys needed
	(SELECT SurveyResponseID, ProgramID, CL_EN_GEN_ID, SiteID, SurveyDate, NURSE_PERSONAL_0_NAME,
			CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT, CLIENT_DOMAIN_0_MATERNAL_VISIT, CLIENT_DOMAIN_0_PERSHLTH_VISIT,
			CLIENT_DOMAIN_0_LIFECOURSE_VISIT, CLIENT_DOMAIN_0_FRNDFAM_VISIT		
	FROM HOME_VISIT_ENCOUNTER_SURVEY survey
		JOIN Mstr_surveys ms ON ms.SurveyID = survey.SurveyID ----replaces udf_fn_GetFormname() function
	WHERE (SurveyDate >= @rStartDate AND SurveyDate <= @rEndDate) 
		AND CLIENT_COMPLETE_0_VISIT = 'Completed'	
		AND NURSE_PERSONAL_0_NAME IS NOT NULL		
	)survey	
----------------------------------------------------------------------------------------------

	JOIN dbo.UV_PASWithTribal pas ON pas.ProgramID = survey.ProgramID
		AND pas.ProgramType = 2
					
----------------------------------------------------------------------------------------------
	LEFT JOIN UC_Client_Exclusion_YWCA ywca ON ywca.CLID = survey.CL_EN_GEN_ID
		AND survey.SiteID = 222 					
--------------------------------------------------------------------------------------------
	--------this LEFT JOINs are used for determining visit phase 
	--------from DBO.udf_PhasebyDate() function 
	LEFT JOIN #EAD ON #EAD.CLID = survey.CL_EN_GEN_ID
		AND #EAD.ProgramID = survey.ProgramID
		AND #EAD.EarliestEnrollment = 1
	LEFT JOIN #IBS ON #IBS.CL_EN_GEN_ID = #EAD.CLID
		AND #IBS.ProgramID = #EAD.ProgramID		
		AND #IBS.LatestSurvey = 1			
--------------------------------------------------------------------------------------------
WHERE ywca.CLID IS NULL	
		 
--------------------------------------------------------------------------------------------
-----DETAIL DATA
-----detail records are in the temp table, can get the detail by using report parms for National

----#SurveyDetails10a --- every record
--SELECT * FROM #SurveyDetails10a ORDER BY CLID, ProgramID, SurveyResponseID

-----------------------------
-------DETAIL DATA
------client detail records, 4b, with yes/no/aggregates
--SELECT #SurveyDetails10a.*, parm.Value TeamParmValue  
--FROM #SurveyDetails10a
--	JOIN @TeamTable parm							----report selection
--		ON parm.Value = #SurveyDetails10a.ProgramID	----TeamTable contains team program ids
				
--------===========================================================================================
------for testing

----ORDER BY CLID, ProgramID

--ORDER BY StateID, SiteID, ProgramID, CLID

----for testing
------===========================================================================================


-------------------------------------------------------------------------------------------

-----GROUP DATA
-------used for testing

SELECT 
	StateAbbr, [State], StateID
	,SiteID, SiteName
	,ProgramID, TeamName
	,NationalID, NationalName

------Pregnancy------
	,SUM(CASE WHEN PhaseOfVisit = 'Pregnancy' THEN 1 ELSE 0 END) VisitPerPhaseTotal_Pregnancy
	------PERSHLTH------
	,SUM(CASE WHEN PhaseOfVisit = 'Pregnancy' THEN CLIENT_DOMAIN_0_PERSHLTH_VISIT ELSE 0 END) PhaseSum_Pregnancy_PERS
	,CASE 
		WHEN SUM(CASE WHEN PhaseOfVisit = 'Pregnancy' THEN 1 ELSE 0 END) = 0 
			THEN 0
			ELSE 
			CAST(ROUND(CAST(SUM(CASE WHEN PhaseOfVisit = 'Pregnancy' THEN CLIENT_DOMAIN_0_PERSHLTH_VISIT ELSE 0 END) as decimal) / 
				CAST(SUM(CASE WHEN PhaseOfVisit = 'Pregnancy' THEN 1 ELSE 0 END) as decimal) ,1) as decimal(10,1)) 
	END PhaseAvg_Pregnancy_PERS
	------ENVIRONHLTH------
	,SUM(CASE WHEN PhaseOfVisit = 'Pregnancy' THEN CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT ELSE 0 END) PhaseSum_Pregnancy_ENV
	,CASE 
		WHEN SUM(CASE WHEN PhaseOfVisit = 'Pregnancy' THEN 1 ELSE 0 END) = 0 
			THEN 0
			ELSE 
				CAST(ROUND(CAST(SUM(CASE WHEN PhaseOfVisit = 'Pregnancy' THEN CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT ELSE 0 END) as decimal) / 
					CAST(SUM(CASE WHEN PhaseOfVisit = 'Pregnancy' THEN 1 ELSE 0 END) as decimal) ,1) as decimal(10,1))
	END PhaseAvg_Pregnancy_ENV	
	------LIFECOURSE------
	,SUM(CASE WHEN PhaseOfVisit = 'Pregnancy' THEN CLIENT_DOMAIN_0_LIFECOURSE_VISIT ELSE 0 END) PhaseSum_Pregnancy_LIFE
	,CASE 
		WHEN SUM(CASE WHEN PhaseOfVisit = 'Pregnancy' THEN 1 ELSE 0 END) = 0 
			THEN 0
			ELSE 
				CAST(ROUND(CAST(SUM(CASE WHEN PhaseOfVisit = 'Pregnancy' THEN CLIENT_DOMAIN_0_LIFECOURSE_VISIT ELSE 0 END) as decimal) / 
					CAST(SUM(CASE WHEN PhaseOfVisit = 'Pregnancy' THEN 1 ELSE 0 END) as decimal) ,1) as decimal(10,1)) 
	END PhaseAvg_Pregnancy_LIFE
	------MATERNAL------
	,SUM(CASE WHEN PhaseOfVisit = 'Pregnancy' THEN CLIENT_DOMAIN_0_MATERNAL_VISIT ELSE 0 END) PhaseSum_Pregnancy_MAT
	,CASE 
		WHEN SUM(CASE WHEN PhaseOfVisit = 'Pregnancy' THEN 1 ELSE 0 END) = 0 
			THEN 0
			ELSE 
				CAST(ROUND(CAST(SUM(CASE WHEN PhaseOfVisit = 'Pregnancy' THEN CLIENT_DOMAIN_0_MATERNAL_VISIT ELSE 0 END) as decimal) / 
					CAST(SUM(CASE WHEN PhaseOfVisit = 'Pregnancy' THEN 1 ELSE 0 END) as decimal) ,1) as decimal(10,1))
	END PhaseAvg_Pregnancy_MAT
	------FRNDFAM------
	,SUM(CASE WHEN PhaseOfVisit = 'Pregnancy' THEN CLIENT_DOMAIN_0_FRNDFAM_VISIT ELSE 0 END) PhaseSum_Pregnancy_FAM
	,CASE 
		WHEN SUM(CASE WHEN PhaseOfVisit = 'Pregnancy' THEN 1 ELSE 0 END) = 0 
			THEN 0
			ELSE 
				CAST(ROUND(CAST(SUM(CASE WHEN PhaseOfVisit = 'Pregnancy' THEN CLIENT_DOMAIN_0_FRNDFAM_VISIT ELSE 0 END) as decimal) / 
					CAST(SUM(CASE WHEN PhaseOfVisit = 'Pregnancy' THEN 1 ELSE 0 END) as decimal) ,1) as decimal(10,1))
	END PhaseAvg_Pregnancy_FAM

------Infancy------
	,SUM(CASE WHEN PhaseOfVisit = 'Infancy' THEN 1 ELSE 0 END) VisitPerPhaseTotal_Infancy
	------PERSHLTH------
	,SUM(CASE WHEN PhaseOfVisit = 'Infancy' THEN CLIENT_DOMAIN_0_PERSHLTH_VISIT ELSE 0 END) PhaseSum_Infancy_PERS
	,CASE 
		WHEN SUM(CASE WHEN PhaseOfVisit = 'Infancy' THEN 1 ELSE 0 END) = 0 
			THEN 0
			ELSE 
			CAST(ROUND(CAST(SUM(CASE WHEN PhaseOfVisit = 'Infancy' THEN CLIENT_DOMAIN_0_PERSHLTH_VISIT ELSE 0 END) as decimal) / 
				CAST(SUM(CASE WHEN PhaseOfVisit = 'Infancy' THEN 1 ELSE 0 END) as decimal) ,1) as decimal(10,1)) 
	END PhaseAvg_Infancy_PERS
	------ENVIRONHLTH------
	,SUM(CASE WHEN PhaseOfVisit = 'Infancy' THEN CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT ELSE 0 END) PhaseSum_Infancy_ENV
	,CASE 
		WHEN SUM(CASE WHEN PhaseOfVisit = 'Infancy' THEN 1 ELSE 0 END) = 0 
			THEN 0
			ELSE 
				CAST(ROUND(CAST(SUM(CASE WHEN PhaseOfVisit = 'Infancy' THEN CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT ELSE 0 END) as decimal) / 
					CAST(SUM(CASE WHEN PhaseOfVisit = 'Infancy' THEN 1 ELSE 0 END) as decimal) ,1) as decimal(10,1))
	END PhaseAvg_Infancy_ENV	
	------LIFECOURSE------
	,SUM(CASE WHEN PhaseOfVisit = 'Infancy' THEN CLIENT_DOMAIN_0_LIFECOURSE_VISIT ELSE 0 END) PhaseSum_Infancy_LIFE
	,CASE 
		WHEN SUM(CASE WHEN PhaseOfVisit = 'Infancy' THEN 1 ELSE 0 END) = 0 
			THEN 0
			ELSE 
				CAST(ROUND(CAST(SUM(CASE WHEN PhaseOfVisit = 'Infancy' THEN CLIENT_DOMAIN_0_LIFECOURSE_VISIT ELSE 0 END) as decimal) / 
					CAST(SUM(CASE WHEN PhaseOfVisit = 'Infancy' THEN 1 ELSE 0 END) as decimal) ,1) as decimal(10,1)) 
	END PhaseAvg_Infancy_LIFE
	------MATERNAL------
	,SUM(CASE WHEN PhaseOfVisit = 'Infancy' THEN CLIENT_DOMAIN_0_MATERNAL_VISIT ELSE 0 END) PhaseSum_Infancy_MAT
	,CASE 
		WHEN SUM(CASE WHEN PhaseOfVisit = 'Infancy' THEN 1 ELSE 0 END) = 0 
			THEN 0
			ELSE 
				CAST(ROUND(CAST(SUM(CASE WHEN PhaseOfVisit = 'Infancy' THEN CLIENT_DOMAIN_0_MATERNAL_VISIT ELSE 0 END) as decimal) / 
					CAST(SUM(CASE WHEN PhaseOfVisit = 'Infancy' THEN 1 ELSE 0 END) as decimal) ,1) as decimal(10,1))
	END PhaseAvg_Infancy_MAT
	------FRNDFAM------
	,SUM(CASE WHEN PhaseOfVisit = 'Infancy' THEN CLIENT_DOMAIN_0_FRNDFAM_VISIT ELSE 0 END) PhaseSum_Infancy_FAM
	,CASE 
		WHEN SUM(CASE WHEN PhaseOfVisit = 'Infancy' THEN 1 ELSE 0 END) = 0 
			THEN 0
			ELSE 
				CAST(ROUND(CAST(SUM(CASE WHEN PhaseOfVisit = 'Infancy' THEN CLIENT_DOMAIN_0_FRNDFAM_VISIT ELSE 0 END) as decimal) / 
					CAST(SUM(CASE WHEN PhaseOfVisit = 'Infancy' THEN 1 ELSE 0 END) as decimal) ,1) as decimal(10,1))
	END PhaseAvg_Infancy_FAM

--------Toddler------
	,SUM(CASE WHEN PhaseOfVisit = 'Toddler' THEN 1 ELSE 0 END) VisitPerPhaseTotal_Toddler
	------PERSHLTH------
	,SUM(CASE WHEN PhaseOfVisit = 'Toddler' THEN CLIENT_DOMAIN_0_PERSHLTH_VISIT ELSE 0 END) PhaseSum_Toddler_PERS
	,CASE 
		WHEN SUM(CASE WHEN PhaseOfVisit = 'Toddler' THEN 1 ELSE 0 END) = 0 
			THEN 0
			ELSE 
			CAST(ROUND(CAST(SUM(CASE WHEN PhaseOfVisit = 'Toddler' THEN CLIENT_DOMAIN_0_PERSHLTH_VISIT ELSE 0 END) as decimal) / 
				CAST(SUM(CASE WHEN PhaseOfVisit = 'Toddler' THEN 1 ELSE 0 END) as decimal) ,1) as decimal(10,1)) 
	END PhaseAvg_Toddler_PERS
	------ENVIRONHLTH------
	,SUM(CASE WHEN PhaseOfVisit = 'Toddler' THEN CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT ELSE 0 END) PhaseSum_Toddler_ENV
	,CASE 
		WHEN SUM(CASE WHEN PhaseOfVisit = 'Toddler' THEN 1 ELSE 0 END) = 0 
			THEN 0
			ELSE 
				CAST(ROUND(CAST(SUM(CASE WHEN PhaseOfVisit = 'Toddler' THEN CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT ELSE 0 END) as decimal) / 
					CAST(SUM(CASE WHEN PhaseOfVisit = 'Toddler' THEN 1 ELSE 0 END) as decimal) ,1) as decimal(10,1))
	END PhaseAvg_Toddler_ENV	
	------LIFECOURSE------
	,SUM(CASE WHEN PhaseOfVisit = 'Toddler' THEN CLIENT_DOMAIN_0_LIFECOURSE_VISIT ELSE 0 END) PhaseSum_Toddler_LIFE
	,CASE 
		WHEN SUM(CASE WHEN PhaseOfVisit = 'Toddler' THEN 1 ELSE 0 END) = 0 
			THEN 0
			ELSE 
				CAST(ROUND(CAST(SUM(CASE WHEN PhaseOfVisit = 'Toddler' THEN CLIENT_DOMAIN_0_LIFECOURSE_VISIT ELSE 0 END) as decimal) / 
					CAST(SUM(CASE WHEN PhaseOfVisit = 'Toddler' THEN 1 ELSE 0 END) as decimal) ,1) as decimal(10,1)) 
	END PhaseAvg_Toddler_LIFE
	------MATERNAL------
	,SUM(CASE WHEN PhaseOfVisit = 'Toddler' THEN CLIENT_DOMAIN_0_MATERNAL_VISIT ELSE 0 END) PhaseSum_Toddler_MAT
	,CASE 
		WHEN SUM(CASE WHEN PhaseOfVisit = 'Toddler' THEN 1 ELSE 0 END) = 0 
			THEN 0
			ELSE 
				CAST(ROUND(CAST(SUM(CASE WHEN PhaseOfVisit = 'Toddler' THEN CLIENT_DOMAIN_0_MATERNAL_VISIT ELSE 0 END) as decimal) / 
					CAST(SUM(CASE WHEN PhaseOfVisit = 'Toddler' THEN 1 ELSE 0 END) as decimal) ,1) as decimal(10,1))
	END PhaseAvg_Toddler_MAT
	------FRNDFAM------
	,SUM(CASE WHEN PhaseOfVisit = 'Toddler' THEN CLIENT_DOMAIN_0_FRNDFAM_VISIT ELSE 0 END) PhaseSum_Toddler_FAM
	,CASE 
		WHEN SUM(CASE WHEN PhaseOfVisit = 'Toddler' THEN 1 ELSE 0 END) = 0 
			THEN 0
			ELSE 
				CAST(ROUND(CAST(SUM(CASE WHEN PhaseOfVisit = 'Toddler' THEN CLIENT_DOMAIN_0_FRNDFAM_VISIT ELSE 0 END) as decimal) / 
					CAST(SUM(CASE WHEN PhaseOfVisit = 'Toddler' THEN 1 ELSE 0 END) as decimal) ,1) as decimal(10,1))
	END PhaseAvg_Toddler_FAM
INTO #SurveyDetails10b

FROM #SurveyDetails10a
	--JOIN @TeamTable parm							----report selection
	--	ON parm.Value = #SurveyDetails10a.ProgramID	----TeamTable contains team program ids

GROUP BY
	StateAbbr, [State], StateID
	,SiteID, SiteName
	,ProgramID, TeamName
	,NationalID, NationalName
					
----------------------------------------------------------------------------------------
----obtain nationa/state/site/team aggregates

SELECT 
	--b.*
	b.StateAbbr, b.State, b.StateID
	,b.SiteID, b.SiteName
	,b.ProgramID, b.TeamName
	,b.NationalID, b.NationalName
	
	----aggregates

----Table 1
----PREG
----National Preg
	--,SUM(VisitPerPhaseTotal_Pregnancy) OVER() NationalVisitsPregnancy 
	------PERS
	--,SUM(PhaseSum_Pregnancy_PERS) OVER() NationalSumPregPERS
	,CASE WHEN SUM(VisitPerPhaseTotal_Pregnancy) OVER() <> 0
		THEN	SUM(PhaseSum_Pregnancy_PERS) OVER() / SUM(VisitPerPhaseTotal_Pregnancy) OVER()
	END NationalMeanPregPERS
	----ENV
	--,SUM(PhaseSum_Pregnancy_ENV) OVER() NationalSumPregENV
	,CASE WHEN SUM(VisitPerPhaseTotal_Pregnancy) OVER() <> 0
		THEN	SUM(PhaseSum_Pregnancy_ENV) OVER() / SUM(VisitPerPhaseTotal_Pregnancy) OVER()
	END NationalMeanPregENV
	----LIFE
	--,SUM(PhaseSum_Pregnancy_LIFE) OVER() NationalSumPregLIFE
	,CASE WHEN SUM(VisitPerPhaseTotal_Pregnancy) OVER() <> 0
		THEN	SUM(PhaseSum_Pregnancy_LIFE) OVER() / SUM(VisitPerPhaseTotal_Pregnancy) OVER()
	END NationalMeanPregLIFE
	----MAT
	--,SUM(PhaseSum_Pregnancy_MAT) OVER() NationalSumPregMAT
	,CASE WHEN SUM(VisitPerPhaseTotal_Pregnancy) OVER() <> 0
		THEN	SUM(PhaseSum_Pregnancy_MAT) OVER() / SUM(VisitPerPhaseTotal_Pregnancy) OVER()
	END NationalMeanPregMAT
	----FAM
	--,SUM(PhaseSum_Pregnancy_FAM) OVER() NationalSumPregFAM
	,CASE WHEN SUM(VisitPerPhaseTotal_Pregnancy) OVER() <> 0
		THEN	SUM(PhaseSum_Pregnancy_FAM) OVER() / SUM(VisitPerPhaseTotal_Pregnancy) OVER()
	END NationalMeanPregFAM
----State Preg
	--,SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID) StateVisitsPregnancy 
	----PERS
	--,SUM(PhaseSum_Pregnancy_PERS) OVER(PARTITION BY StateID) StateSumPregPERS
	,CASE WHEN SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID) <> 0
		THEN	SUM(PhaseSum_Pregnancy_PERS) OVER(PARTITION BY StateID) / SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID)
	END StateMeanPregPERS
	----ENV
	--,SUM(PhaseSum_Pregnancy_ENV) OVER(PARTITION BY StateID) StateSumPregENV
	,CASE WHEN SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID) <> 0
		THEN	SUM(PhaseSum_Pregnancy_ENV) OVER(PARTITION BY StateID) / SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID)
	END StateMeanPregENV
	----LIFE
	--,SUM(PhaseSum_Pregnancy_LIFE) OVER(PARTITION BY StateID) StateSumPregLIFE
	,CASE WHEN SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID) <> 0
		THEN	SUM(PhaseSum_Pregnancy_LIFE) OVER(PARTITION BY StateID) / SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID)
	END StateMeanPregLIFE
	----MAT
	--,SUM(PhaseSum_Pregnancy_MAT) OVER(PARTITION BY StateID) StateSumPregMAT
	,CASE WHEN SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID) <> 0
		THEN	SUM(PhaseSum_Pregnancy_MAT) OVER(PARTITION BY StateID) / SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID)
	END StateMeanPregMAT
	----FAM
	--,SUM(PhaseSum_Pregnancy_FAM) OVER(PARTITION BY StateID) StateSumPregFAM
	,CASE WHEN SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID) <> 0
		THEN	SUM(PhaseSum_Pregnancy_FAM) OVER(PARTITION BY StateID) / SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID)
	END StateMeanPregFAM
----Site Preg
	--,SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID, SiteID) AgencyVisitsPregnancy 
	------PERS
	--,SUM(PhaseSum_Pregnancy_PERS) OVER(PARTITION BY StateID, SiteID) AgencySumPregPERS
	,CASE WHEN SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID, SiteID) <> 0
		THEN	SUM(PhaseSum_Pregnancy_PERS) OVER(PARTITION BY StateID, SiteID) / SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID, SiteID)
	END AgencyMeanPregPERS
	----ENV
	--,SUM(PhaseSum_Pregnancy_ENV) OVER(PARTITION BY StateID, SiteID) AgencySumPregENV
	,CASE WHEN SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID, SiteID) <> 0
		THEN	SUM(PhaseSum_Pregnancy_ENV) OVER(PARTITION BY StateID, SiteID) / SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID, SiteID)
	END AgencyMeanPregENV
	----LIFE
	--,SUM(PhaseSum_Pregnancy_LIFE) OVER(PARTITION BY StateID, SiteID) AgencySumPregLIFE
	,CASE WHEN SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID, SiteID) <> 0
		THEN	SUM(PhaseSum_Pregnancy_LIFE) OVER(PARTITION BY StateID, SiteID) / SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID, SiteID)
	END AgencyMeanPregLIFE
	----MAT
	--,SUM(PhaseSum_Pregnancy_MAT) OVER(PARTITION BY StateID, SiteID) AgencySumPregMAT
	,CASE WHEN SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID, SiteID) <> 0
		THEN	SUM(PhaseSum_Pregnancy_MAT) OVER(PARTITION BY StateID, SiteID) / SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID, SiteID)
	END AgencyMeanPregMAT
	----FAM
	--,SUM(PhaseSum_Pregnancy_FAM) OVER(PARTITION BY StateID, SiteID) AgencySumPregFAM
	,CASE WHEN SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID, SiteID) <> 0
		THEN	SUM(PhaseSum_Pregnancy_FAM) OVER(PARTITION BY StateID, SiteID) / SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID, SiteID)
	END AgencyMeanPregFAM
----Team Preg
	--,SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamVisitsPregnancy 
	------PERS
	--,SUM(PhaseSum_Pregnancy_PERS) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamSumPregPERS
	,CASE WHEN SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID, SiteID, ProgramID) <> 0
		THEN	SUM(PhaseSum_Pregnancy_PERS) OVER(PARTITION BY StateID, SiteID, ProgramID) / SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID, SiteID, ProgramID)
	END TeamMeanPregPERS
	----ENV
	--,SUM(PhaseSum_Pregnancy_ENV) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamSumPregENV
	,CASE WHEN SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID, SiteID, ProgramID) <> 0
		THEN	SUM(PhaseSum_Pregnancy_ENV) OVER(PARTITION BY StateID, SiteID, ProgramID) / SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID, SiteID, ProgramID)
	END TeamMeanPregENV
	----LIFE
	--,SUM(PhaseSum_Pregnancy_LIFE) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamSumPregLIFE
	,CASE WHEN SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID, SiteID, ProgramID) <> 0
		THEN	SUM(PhaseSum_Pregnancy_LIFE) OVER(PARTITION BY StateID, SiteID, ProgramID) / SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID, SiteID, ProgramID)
	END TeamMeanPregLIFE
	----MAT
	--,SUM(PhaseSum_Pregnancy_MAT) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamSumPregMAT
	,CASE WHEN SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID, SiteID, ProgramID) <> 0
		THEN	SUM(PhaseSum_Pregnancy_MAT) OVER(PARTITION BY StateID, SiteID, ProgramID) / SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID, SiteID, ProgramID)
	END TeamMeanPregMAT
	----FAM
	--,SUM(PhaseSum_Pregnancy_FAM) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamSumPregFAM
	,CASE WHEN SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID, SiteID, ProgramID) <> 0
		THEN	SUM(PhaseSum_Pregnancy_FAM) OVER(PARTITION BY StateID, SiteID, ProgramID) / SUM(VisitPerPhaseTotal_Pregnancy) OVER(PARTITION BY StateID, SiteID, ProgramID)
	END TeamMeanPregFAM
		
----Table 2	
----INF
	----National Inf
	--,SUM(VisitPerPhaseTotal_Infancy) OVER() NationalVisitsInfancy
	------PERS
	--,SUM(PhaseSum_Infancy_PERS) OVER() NationalSumInfPERS
	,CASE WHEN SUM(VisitPerPhaseTotal_Infancy) OVER() <> 0
		THEN	SUM(PhaseSum_Infancy_PERS) OVER() / SUM(VisitPerPhaseTotal_Infancy) OVER()
	END NationalMeanInfPERS
	----ENV
	--,SUM(PhaseSum_Infancy_ENV) OVER() NationalSumInfENV
	,CASE WHEN SUM(VisitPerPhaseTotal_Infancy) OVER() <> 0
		THEN	SUM(PhaseSum_Infancy_ENV) OVER() / SUM(VisitPerPhaseTotal_Infancy) OVER()
	END NationalMeanInfENV
	----LIFE
	--,SUM(PhaseSum_Infancy_LIFE) OVER() NationalSumInfLIFE
	,CASE WHEN SUM(VisitPerPhaseTotal_Infancy) OVER() <> 0
		THEN	SUM(PhaseSum_Infancy_LIFE) OVER() / SUM(VisitPerPhaseTotal_Infancy) OVER()
	END NationalMeanInfLIFE
	----MAT
	--,SUM(PhaseSum_Infancy_MAT) OVER() NationalSumInfMAT
	,CASE WHEN SUM(VisitPerPhaseTotal_Infancy) OVER() <> 0
		THEN	SUM(PhaseSum_Infancy_MAT) OVER() / SUM(VisitPerPhaseTotal_Infancy) OVER()
	END NationalMeanInfMAT
	----FAM
	--,SUM(PhaseSum_Infancy_FAM) OVER() NationalSumInfFAM
	,CASE WHEN SUM(VisitPerPhaseTotal_Infancy) OVER() <> 0
		THEN	SUM(PhaseSum_Infancy_FAM) OVER() / SUM(VisitPerPhaseTotal_Infancy) OVER()
	END NationalMeanInfFAM
----State Inf
	--,SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID) StateVisitsInfancy
	----PERS
	--,SUM(PhaseSum_Infancy_PERS) OVER(PARTITION BY StateID) StateSumInfPERS
	,CASE WHEN SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID) <> 0
		THEN	SUM(PhaseSum_Infancy_PERS) OVER(PARTITION BY StateID) / SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID)
	END StateMeanInfPERS
	----ENV
	--,SUM(PhaseSum_Infancy_ENV) OVER(PARTITION BY StateID) StateSumInfENV
	,CASE WHEN SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID) <> 0
		THEN	SUM(PhaseSum_Infancy_ENV) OVER(PARTITION BY StateID) / SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID)
	END StateMeanInfENV
	----LIFE
	--,SUM(PhaseSum_Infancy_LIFE) OVER(PARTITION BY StateID) StateSumInfLIFE
	,CASE WHEN SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID) <> 0
		THEN	SUM(PhaseSum_Infancy_LIFE) OVER(PARTITION BY StateID) / SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID)
	END StateMeanInfLIFE
	----MAT
	--,SUM(PhaseSum_Infancy_MAT) OVER(PARTITION BY StateID) StateSumInfMAT
	,CASE WHEN SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID) <> 0
		THEN	SUM(PhaseSum_Infancy_MAT) OVER(PARTITION BY StateID) / SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID)
	END StateMeanInfMAT
	----FAM
	--,SUM(PhaseSum_Infancy_FAM) OVER(PARTITION BY StateID) StateSumInfFAM
	,CASE WHEN SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID) <> 0
		THEN	SUM(PhaseSum_Infancy_FAM) OVER(PARTITION BY StateID) / SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID)
	END StateMeanInfFAM
----Site Inf
	--,SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID, SiteID) AgencyVisitsInfancy
	------PERS
	--,SUM(PhaseSum_Infancy_PERS) OVER(PARTITION BY StateID, SiteID) AgencySumInfPERS
	,CASE WHEN SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID, SiteID) <> 0
		THEN	SUM(PhaseSum_Infancy_PERS) OVER(PARTITION BY StateID, SiteID) / SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID, SiteID)
	END AgencyMeanInfPERS
	--ENV
	--,SUM(PhaseSum_Infancy_ENV) OVER(PARTITION BY StateID, SiteID) AgencySumInfENV
	,CASE WHEN SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID, SiteID) <> 0
		THEN	SUM(PhaseSum_Infancy_ENV) OVER(PARTITION BY StateID, SiteID) / SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID, SiteID)
	END AgencyMeanInfENV
	--LIFE
	--,SUM(PhaseSum_Infancy_LIFE) OVER(PARTITION BY StateID, SiteID) AgencySumInfLIFE
	,CASE WHEN SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID, SiteID) <> 0
		THEN	SUM(PhaseSum_Infancy_LIFE) OVER(PARTITION BY StateID, SiteID) / SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID, SiteID)
	END AgencyMeanInfLIFE
	--MAT
	--,SUM(PhaseSum_Infancy_MAT) OVER(PARTITION BY StateID, SiteID) AgencySumInfMAT
	,CASE WHEN SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID, SiteID) <> 0
		THEN	SUM(PhaseSum_Infancy_MAT) OVER(PARTITION BY StateID, SiteID) / SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID, SiteID)
	END AgencyMeanInfMAT
	--FAM
	--,SUM(PhaseSum_Infancy_FAM) OVER(PARTITION BY StateID, SiteID) AgencySumInfFAM
	,CASE WHEN SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID, SiteID) <> 0
		THEN	SUM(PhaseSum_Infancy_FAM) OVER(PARTITION BY StateID, SiteID) / SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID, SiteID)
	END AgencyMeanInfFAM
----Team Inf
	--,SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamVisitsInfancy
	------PERS
	--,SUM(PhaseSum_Infancy_PERS) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamSumInfPERS
	,CASE WHEN SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID, SiteID, ProgramID) <> 0
		THEN	SUM(PhaseSum_Infancy_PERS) OVER(PARTITION BY StateID, SiteID, ProgramID) / SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID, SiteID, ProgramID)
	END TeamMeanInfPERS
	--ENV
	--,SUM(PhaseSum_Infancy_ENV) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamSumInfENV
	,CASE WHEN SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID, SiteID, ProgramID) <> 0
		THEN	SUM(PhaseSum_Infancy_ENV) OVER(PARTITION BY StateID, SiteID, ProgramID) / SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID, SiteID, ProgramID)
	END TeamMeanInfENV
	--LIFE
	--,SUM(PhaseSum_Infancy_LIFE) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamSumInfLIFE
	,CASE WHEN SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID, SiteID, ProgramID) <> 0
		THEN	SUM(PhaseSum_Infancy_LIFE) OVER(PARTITION BY StateID, SiteID, ProgramID) / SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID, SiteID, ProgramID)
	END TeamMeanInfLIFE
	--MAT
	--,SUM(PhaseSum_Infancy_MAT) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamSumInfMAT
	,CASE WHEN SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID, SiteID, ProgramID) <> 0
		THEN	SUM(PhaseSum_Infancy_MAT) OVER(PARTITION BY StateID, SiteID, ProgramID) / SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID, SiteID, ProgramID)
	END TeamMeanInfMAT
	--FAM
	--,SUM(PhaseSum_Infancy_FAM) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamSumInfFAM
	,CASE WHEN SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID, SiteID, ProgramID) <> 0
		THEN	SUM(PhaseSum_Infancy_FAM) OVER(PARTITION BY StateID, SiteID, ProgramID) / SUM(VisitPerPhaseTotal_Infancy) OVER(PARTITION BY StateID, SiteID, ProgramID)
	END TeamMeanInfFAM
	
	
----Table 3
----TODD
----National Todd
	--,SUM(VisitPerPhaseTotal_Toddler) OVER() NationalVisitsToddler
	------PERS
	--,SUM(PhaseSum_Toddler_PERS) OVER() NationalSumToddPERS
	,CASE WHEN SUM(VisitPerPhaseTotal_Toddler) OVER() <> 0
		THEN	SUM(PhaseSum_Toddler_PERS) OVER() / SUM(VisitPerPhaseTotal_Toddler) OVER()
	END NationalMeanToddPERS
	----ENV
	--,SUM(PhaseSum_Toddler_ENV) OVER() NationalSumToddENV
	,CASE WHEN SUM(VisitPerPhaseTotal_Toddler) OVER() <> 0
		THEN	SUM(PhaseSum_Toddler_ENV) OVER() / SUM(VisitPerPhaseTotal_Toddler) OVER()
	END NationalMeanToddENV
	----LIFE
	--,SUM(PhaseSum_Toddler_LIFE) OVER() NationalSumToddLIFE
	,CASE WHEN SUM(VisitPerPhaseTotal_Toddler) OVER() <> 0
		THEN	SUM(PhaseSum_Toddler_LIFE) OVER() / SUM(VisitPerPhaseTotal_Toddler) OVER()
	END NationalMeanToddLIFE
	----MAT
	--,SUM(PhaseSum_Toddler_MAT) OVER() NationalSumToddMAT
	,CASE WHEN SUM(VisitPerPhaseTotal_Toddler) OVER() <> 0
		THEN	SUM(PhaseSum_Toddler_MAT) OVER() / SUM(VisitPerPhaseTotal_Toddler) OVER()
	END NationalMeanToddMAT
	----FAM
	--,SUM(PhaseSum_Toddler_FAM) OVER() NationalSumToddFAM
	,CASE WHEN SUM(VisitPerPhaseTotal_Toddler) OVER() <> 0
		THEN	SUM(PhaseSum_Toddler_FAM) OVER() / SUM(VisitPerPhaseTotal_Toddler) OVER()
	END NationalMeanToddFAM
----State Todd
	--,SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID) StateVisitsToddler
	------PERS
	--,SUM(PhaseSum_Toddler_PERS) OVER(PARTITION BY StateID) StateSumToddPERS
	,CASE WHEN SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID) <> 0
		THEN	SUM(PhaseSum_Toddler_PERS) OVER(PARTITION BY StateID) / SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID)
	END StateMeanToddPERS
	----ENV
	--,SUM(PhaseSum_Toddler_ENV) OVER(PARTITION BY StateID) StateSumToddENV
	,CASE WHEN SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID) <> 0
		THEN	SUM(PhaseSum_Toddler_ENV) OVER(PARTITION BY StateID) / SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID)
	END StateMeanToddENV
	----LIFE
	--,SUM(PhaseSum_Toddler_LIFE) OVER(PARTITION BY StateID) StateSumToddLIFE
	,CASE WHEN SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID) <> 0
		THEN	SUM(PhaseSum_Toddler_LIFE) OVER(PARTITION BY StateID) / SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID)
	END StateMeanToddLIFE
	----MAT
	--,SUM(PhaseSum_Toddler_MAT) OVER(PARTITION BY StateID) StateSumToddMAT
	,CASE WHEN SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID) <> 0
		THEN	SUM(PhaseSum_Toddler_MAT) OVER(PARTITION BY StateID) / SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID)
	END StateMeanToddMAT
	----FAM
	--,SUM(PhaseSum_Toddler_FAM) OVER(PARTITION BY StateID) StateSumToddFAM
	,CASE WHEN SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID) <> 0
		THEN	SUM(PhaseSum_Toddler_FAM) OVER(PARTITION BY StateID) / SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID)
	END StateMeanToddFAM
----Site Todd
	--,SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID, SiteID) AgencyVisitsToddler
	------PERS
	--,SUM(PhaseSum_Toddler_PERS) OVER(PARTITION BY StateID, SiteID) AgencySumToddPERS
	,CASE WHEN SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID, SiteID) <> 0
		THEN	SUM(PhaseSum_Toddler_PERS) OVER(PARTITION BY StateID, SiteID) / SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID, SiteID)
	END AgencyMeanToddPERS
	----ENV
	--,SUM(PhaseSum_Toddler_ENV) OVER(PARTITION BY StateID, SiteID) AgencySumToddENV
	,CASE WHEN SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID, SiteID) <> 0
		THEN	SUM(PhaseSum_Toddler_ENV) OVER(PARTITION BY StateID, SiteID) / SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID, SiteID)
	END AgencyMeanToddENV
	----LIFE
	--,SUM(PhaseSum_Toddler_LIFE) OVER(PARTITION BY StateID, SiteID) AgencySumToddLIFE
	,CASE WHEN SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID, SiteID) <> 0
		THEN	SUM(PhaseSum_Toddler_LIFE) OVER(PARTITION BY StateID, SiteID) / SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID, SiteID)
	END AgencyMeanToddLIFE
	----MAT
	--,SUM(PhaseSum_Toddler_MAT) OVER(PARTITION BY StateID, SiteID) AgencySumToddMAT
	,CASE WHEN SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID, SiteID) <> 0
		THEN	SUM(PhaseSum_Toddler_MAT) OVER(PARTITION BY StateID, SiteID) / SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID, SiteID)
	END AgencyMeanToddMAT
	----FAM
	--,SUM(PhaseSum_Toddler_FAM) OVER(PARTITION BY StateID, SiteID) AgencySumToddFAM
	,CASE WHEN SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID, SiteID) <> 0
		THEN	SUM(PhaseSum_Toddler_FAM) OVER(PARTITION BY StateID, SiteID) / SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID, SiteID)
	END AgencyMeanToddFAM
----Team Todd
	--,SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamVisitsToddler
	------PERS
	--,SUM(PhaseSum_Toddler_PERS) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamSumToddPERS
	,CASE WHEN SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID, SiteID, ProgramID) <> 0
		THEN	SUM(PhaseSum_Toddler_PERS) OVER(PARTITION BY StateID, SiteID, ProgramID) / SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID, SiteID, ProgramID)
	END TeamMeanToddPERS
	----ENV
	--,SUM(PhaseSum_Toddler_ENV) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamSumToddENV
	,CASE WHEN SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID, SiteID, ProgramID) <> 0
		THEN	SUM(PhaseSum_Toddler_ENV) OVER(PARTITION BY StateID, SiteID, ProgramID) / SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID, SiteID, ProgramID)
	END TeamMeanToddENV
	----LIFE
	--,SUM(PhaseSum_Toddler_LIFE) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamSumToddLIFE
	,CASE WHEN SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID, SiteID, ProgramID) <> 0
		THEN	SUM(PhaseSum_Toddler_LIFE) OVER(PARTITION BY StateID, SiteID, ProgramID) / SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID, SiteID, ProgramID)
	END TeamMeanToddLIFE
	----MAT
	--,SUM(PhaseSum_Toddler_MAT) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamSumToddMAT
	,CASE WHEN SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID, SiteID, ProgramID) <> 0
		THEN	SUM(PhaseSum_Toddler_MAT) OVER(PARTITION BY StateID, SiteID, ProgramID) / SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID, SiteID, ProgramID)
	END TeamMeanToddMAT
	----FAM
	--,SUM(PhaseSum_Toddler_FAM) OVER(PARTITION BY StateID, SiteID, ProgramID) TeamSumToddFAM
	,CASE WHEN SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID, SiteID, ProgramID) <> 0
		THEN	SUM(PhaseSum_Toddler_FAM) OVER(PARTITION BY StateID, SiteID, ProgramID) / SUM(VisitPerPhaseTotal_Toddler) OVER(PARTITION BY StateID, SiteID, ProgramID)
	END TeamMeanToddFAM
	
INTO #SurveyDetails10c

FROM #SurveyDetails10b b
----------------------------------------------------------------------------------------

SELECT c.*
FROM #SurveyDetails10c c
	JOIN @TeamTable parm							----report selection
		ON parm.Value = c.ProgramID	----TeamTable contains team program ids

----------------------------------------------------------------------------------------

-------used for testing

--ORDER BY State, SiteID, ProgramID

-------used for testing
----------------------------------------------------------------------------------------


GO
