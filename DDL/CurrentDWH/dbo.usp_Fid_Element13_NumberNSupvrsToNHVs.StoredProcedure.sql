USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Element13_NumberNSupvrsToNHVs]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_Fid_Element13_NumberNSupvrsToNHVs]
(	@StartDate		Date 
	,@EndDate		Date 
	,@Team			VARCHAR(MAX) 
)
AS

If object_id('tempdb..#SurveyDetails13') is not null
	Drop Table #SurveyDetails13

------===========================================================================================
------for testing

--DECLARE 
--	@StartDate		Date 
--	,@EndDate		Date 
--	,@Team			VARCHAR(MAX)
--	,@Agency			VARCHAR(MAX)
	
--SET @StartDate		 = CAST('7/1/2013' AS DATE)
--SET @EndDate		 = CAST('6/30/2014' AS DATE)

--------all teams
--SET @Team = '1857,1700,812,1605,1808,1532,872,875,878,1937,911,914,1796,1949,1823,1985,1820,1752,1755,1764,1767,1770,1779,851,848,845,842,839,836,827,1712,833,830,1773,824,821,818,1744,815,962,965,968,884,887,1668,1388,1391,1535,1557,1394,1397,1400,1404,1554,1617,1620,1576,860,863,866,1943,869,1988,857,854,971,974,977,983,980,986,989,992,995,998,1887,1001,1004,1007,1010,2010,1013,1922,1925,1671,881,1928,944,947,1566,1647,1655,1658,1967,1973,1976,1982,2032,1703,1709,893,1894,1860,1761,950,1581,1584,1602,1454,1461,1608,1688,1697,2001,1912,953,1047,1049,1052,1641,1055,1058,956,959,1016,1019,1031,1034,1037,1064,1070,1073,1076,1587,1651,1079,890,920,899,917,1563,1749,1758,1793,2013,1805,1706,1871,896,902,935,938,941,905,1722,908,923,926,1900,1061,1067,1082,1814,1817,1829,1739,1992,1995,1040,1043,1148,1151,1085,1848,1022,1025,1028,1715,1154,1979,1891,1157,1088,1091,1094,1097,1100,1897,1103,1106,1109,1626,1112,1115,1118,1121,1124,1127,1130,1133,1136,1139,1142,1145,1169,1172,1160,1163,1166,1175,1178,1181,1184,1187,1961,1906,1244,929,932,1538,1409,1436,1439,1443,1446,1449,1452,1457,1463,1467,1472,1412,1475,1478,1481,1484,1487,1490,1560,1915,1415,1418,1421,1424,1427,1430,1433,1611,1190,1193,1934,1854,2023,1727,1799,1802,1844,1199,1202,1205,1208,1694,1213,1217,1946,1221,1196,1211,1233,781,780,779,1253,1256,1940,1247,1239,1884,1250,1280,1227,1790,1746,1224,1230,1236,1661,1242,1259,1262,1268,1274,1283,1289,1370,1298,1310,1998,1349,1295,1301,1286,1313,1644,2004,2007,1826,1265,1863,1316,1322,1352,1304,1307,1623,1599,1680,1683,1868,2016,2020,1832,1838,1782,1785,1776,1638,1469,1337,1346,1271,1964,1277,1319,1334,1343,1358,1361,1364,1355,748,1292,1664,1875,1903,1909,1841,1851,1970,1674,1677,1367,1325,1328,1331,1918,1373,1379,1382,1376,1952,1385,1573,1406,1931,1879,1835,1811,1730,1340,1718,1955,1958,2026,1493,1520,1523,1526,1529,1570,1496,1499,1502,1505,1508,1511,1514,1517'

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
DECLARE @xt XML  
SELECT @xt = CAST('<A>'+ REPLACE(@rTeam,',','</A><A>')+ '</A>' AS XML) 
INSERT INTO @TeamTable             
SELECT t.value('.', 'int') AS inVal 
FROM @xt.nodes('/A') AS xt(t) 
----------------------------------------------------------------------------------------------
------from fn_FID_Staff_list
;WITH StfInfo AS
(
	SELECT DISTINCT
		CASE 
			WHEN (EndDate > @rEndDate OR EndDate IS NULL)	--active during reporting period
				AND ((ISNULL(HV_FTE,0) > 0 OR NHV_Flag = 1)	--nhv
				AND (ISNULL(S_FTE,0) = 0 AND NS_Flag = 0))	--and not supv
					THEN Entity_Id 
		END NhvID			
		,CASE 
			WHEN (EndDate > @rEndDate OR EndDate IS NULL)	--active during reporting period
				AND (HV_FTE > 0 AND NHV_Flag <> 1)			--nhv position missing
					THEN Entity_Id							
		END NHVPositionMissing	
		,CASE 
			WHEN (EndDate > @rEndDate OR EndDate IS NULL)	--active during reporting period
				AND (ISNULL(S_FTE,0) > 0 OR NS_Flag = 1)	--supv	
					THEN Entity_Id							
		END NsID
		,CASE 
			WHEN (EndDate > @rEndDate OR EndDate IS NULL)	--active during reporting period 
				AND NS_Flag = 1								--ns position
					THEN Entity_Id							
		END NsPosition
		,CASE 
			WHEN (EndDate > @rEndDate OR EndDate IS NULL)	--active during reporting period
				AND (S_FTE > 0 AND NS_Flag <> 1)			--ns position missing
					THEN Entity_Id							
		END NsPositionMissing			
		,CASE 
			WHEN (EndDate > @rEndDate OR EndDate IS NULL)	--active during reporting period
				AND (S_FTE > 0 OR NS_Flag = 1)				--ns FTE
					THEN S_FTE								
		END NsFTE		
		,CASE 
			WHEN (EndDate > @rEndDate OR EndDate IS NULL)	--active during reporting period
				AND (ISNULL(S_FTE,0) = 0 AND NS_Flag = 1)	--ns FTE missing
					THEN Entity_Id							
		END NsFTEMissing	
										
		,Entity_Id
		,ProgramID		

		----these row numbers are used to count unique IDs in aggregates and are partioned by Entity_Id, SiteID 
		,Row_Number() OVER(PARTITION BY CASE 
											WHEN (EndDate > @rEndDate OR EndDate IS NULL)	
												AND ((ISNULL(HV_FTE,0) > 0 OR NHV_Flag = 1)	
												AND (ISNULL(S_FTE,0) = 0 AND NS_Flag = 0))	
													THEN Entity_Id 
										END, SiteID 
							ORDER BY SiteID, ProgramID
							) NHVRowNumber	

		,Row_Number() OVER(PARTITION BY CASE 
											WHEN (EndDate > @rEndDate OR EndDate IS NULL)	
												AND (HV_FTE > 0 AND NHV_Flag <> 1) 
													THEN Entity_Id							
										END, SiteID 
							ORDER BY SiteID, ProgramID
							) NHVPosMissRowNumber	
		
		,Row_Number() OVER(PARTITION BY CASE 
											WHEN (EndDate > @rEndDate OR EndDate IS NULL)	
												AND (ISNULL(S_FTE,0) > 0 OR NS_Flag = 1)	
													THEN Entity_Id							
										END, SiteID 
							ORDER BY SiteID, ProgramID
							) NSRowNumber	
 
		,Row_Number() OVER(PARTITION BY CASE 
											WHEN (EndDate > @rEndDate OR EndDate IS NULL)
												AND NS_Flag = 1 
													THEN Entity_Id							
										END, SiteID 
							ORDER BY SiteID, ProgramID
							) NsPosRowNumber	
 
		,Row_Number() OVER(PARTITION BY CASE 
											WHEN (EndDate > @rEndDate OR EndDate IS NULL)	
												AND (S_FTE > 0 AND NS_Flag <> 1)
													THEN Entity_Id						
										END, SiteID 
							ORDER BY SiteID, ProgramID
							) NsPosMissRowNumber	
 
 		,Row_Number() OVER(PARTITION BY CASE 
											WHEN (EndDate > @rEndDate OR EndDate IS NULL)	
												AND (ISNULL(S_FTE,0) = 0 AND NS_Flag = 1)
													THEN Entity_Id							
										END, SiteID 
							ORDER BY SiteID, ProgramID
							) NsFTEMissRowNumber	

	FROM dbo.fn_FID_Staff_list (@rStartDate, @rEndDate) 

) --end cte
----from fn_FID_Staff_list
------------=================================================================================

SELECT 

	'1' NationalID
	,'National' NationalName
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

	,stf.NhvID	
	,stf.NhvPositionMissing
	,stf.NsID
	,stf.NsPosition
	,stf.NsPositionMissing
	,stf.NsFTE
	,stf.NsFTEMissing	
	,stf.Entity_Id
	
	--------aggregates	
	--------National
	,SUM(CASE WHEN stf.NsPosition IS NOT NULL AND NsPosRowNumber = 1 THEN 1 ELSE 0 END) OVER() NationalNsPosition
	,SUM(CASE WHEN stf.NsFTE > 0 THEN stf.NsFTE ELSE 0 END) OVER() NationalNsFte ----sum all FTEs
	,SUM(CASE WHEN stf.NsID IS NOT NULL AND NSRowNumber = 1 THEN 1 ELSE 0 END) OVER() NationalNs
	,SUM(CASE WHEN stf.NhvID IS NOT NULL AND NHVRowNumber = 1 THEN 1 ELSE 0 END) OVER() NationalNhv
	,SUM(CASE WHEN stf.NsFTEMissing IS NOT NULL AND NsFTEMissRowNumber = 1 THEN 1 ELSE 0 END) OVER() NationalNsFteMissing
	,SUM(CASE WHEN stf.NsPositionMissing IS NOT NULL AND NsPosMissRowNumber = 1 THEN 1 ELSE 0 END) OVER() NationalNsPosMissing
	,SUM(CASE WHEN stf.NhvPositionMissing IS NOT NULL AND NHVPosMissRowNumber = 1 THEN 1 ELSE 0 END) OVER() NationalNhvPosMissing

	----------State
	,SUM(CASE WHEN stf.NsPosition IS NOT NULL AND NsPosRowNumber = 1 THEN 1 ELSE 0 END)
		OVER (PARTITION BY pas.StateID) StatesNsPosition
	,SUM(CASE WHEN stf.NsFTE > 0 THEN stf.NsFTE ELSE 0 END) ----sum all FTEs
		OVER (PARTITION BY pas.StateID) StateNsFte
	,SUM(CASE WHEN stf.NsID IS NOT NULL AND NSRowNumber = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY pas.StateID) StateNs
	,SUM(CASE WHEN stf.NhvID IS NOT NULL AND NHVRowNumber = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY pas.StateID) StateNhv
	,SUM(CASE WHEN stf.NsFTEMissing IS NOT NULL AND NsFTEMissRowNumber = 1 THEN 1 ELSE 0 END)
		OVER (PARTITION BY pas.StateID) StateNsFteMissing
	,SUM(CASE WHEN stf.NsPositionMissing IS NOT NULL AND NsPosMissRowNumber = 1 THEN 1 ELSE 0 END)
		OVER (PARTITION BY pas.StateID) StateNsPosMissing
	,SUM(CASE WHEN stf.NhvPositionMissing IS NOT NULL AND NHVPosMissRowNumber = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY pas.StateID) StateNhvPosMissing
	
	----------Agency
	,SUM(CASE WHEN stf.NsPosition IS NOT NULL AND NsPosRowNumber = 1 THEN 1 ELSE 0 END)
		OVER (PARTITION BY pas.StateID, pas.SiteID) AgencyNsPosition
	,SUM(CASE WHEN stf.NsFTE > 0 THEN stf.NsFTE ELSE 0 END) ----sum all FTEs
		OVER (PARTITION BY pas.StateID, pas.SiteID) AgencyNsFte
	,SUM(CASE WHEN stf.NsID IS NOT NULL AND NSRowNumber = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY pas.StateID, pas.SiteID) AgencyNs
	,SUM(CASE WHEN stf.NhvID IS NOT NULL AND NHVRowNumber = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY pas.StateID, pas.SiteID) AgencyNhv
	,SUM(CASE WHEN stf.NsFTEMissing IS NOT NULL AND NsFTEMissRowNumber = 1 THEN 1 ELSE 0 END)
		OVER (PARTITION BY pas.StateID, pas.SiteID) AgencyNsFteMissing
	,SUM(CASE WHEN stf.NsPositionMissing IS NOT NULL AND NsPosMissRowNumber = 1 THEN 1 ELSE 0 END)
		OVER (PARTITION BY pas.StateID, pas.SiteID) AgencyNsPosMissing
	,SUM(CASE WHEN stf.NhvPositionMissing IS NOT NULL AND NHVPosMissRowNumber = 1 THEN 1 ELSE 0 END) 
		OVER (PARTITION BY pas.StateID, pas.SiteID) AgencyNhvPosMissing

	----------Team/Program
	,SUM(CASE WHEN stf.NsPosition IS NOT NULL THEN 1 ELSE 0 END)
		OVER (PARTITION BY pas.StateID, pas.SiteID, pas.ProgramID) TeamNsPosition
	,SUM(CASE WHEN stf.NsFTE > 0 THEN stf.NsFTE ELSE 0 END) ----sum all FTEs
		OVER (PARTITION BY pas.StateID, pas.SiteID, pas.ProgramID) TeamNsFte
	,SUM(CASE WHEN stf.NsID IS NOT NULL THEN 1 ELSE 0 END) 
		OVER (PARTITION BY pas.StateID, pas.SiteID, pas.ProgramID) TeamNs
	,SUM(CASE WHEN stf.NhvID IS NOT NULL THEN 1 ELSE 0 END) 
		OVER (PARTITION BY pas.StateID, pas.SiteID, pas.ProgramID) TeamNhv
	,SUM(CASE WHEN stf.NsFTEMissing IS NOT NULL THEN 1 ELSE 0 END)
		OVER (PARTITION BY pas.StateID, pas.SiteID, pas.ProgramID) TeamNsFteMissing
	,SUM(CASE WHEN stf.NsPositionMissing IS NOT NULL THEN 1 ELSE 0 END)
		OVER (PARTITION BY pas.StateID, pas.SiteID, pas.ProgramID) TeamNsPosMissing
	,SUM(CASE WHEN stf.NhvPositionMissing IS NOT NULL THEN 1 ELSE 0 END) 
		OVER (PARTITION BY pas.StateID, pas.SiteID, pas.ProgramID) TeamNhvPosMissing
		
INTO #SurveyDetails13

FROM StfInfo stf 
	JOIN UV_PAS pas ON pas.ProgramID = stf.ProgramID

------===========================================================================================
SELECT #SurveyDetails13.*
FROM #SurveyDetails13
	JOIN @TeamTable parm							----report selection
		ON parm.Value = #SurveyDetails13.ProgramID	----TeamTable contains team program ids
		
----===========================================================================================
----for testing

--ORDER BY StateID, SiteID, ProgramID, Entity_id

----for testing
------===========================================================================================
GO
