USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Element12_NHVCaseload]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_Fid_Element12_NHVCaseload]
(	@StartDate		Date 
	,@EndDate		Date 
	,@Team			VARCHAR(max)
)
AS

--------------------------------------------------------------------------------------------------------------------------
----for testing

--DECLARE
--	@StartDate	Date
--	,@EndDate	Date
--	,@Team		VARCHAR(max)

--SET @StartDate		= CAST('1/1/2014' AS DATE)
--SET @EndDate		= CAST('12/31/2014' AS DATE)

--------all teams
--SET @Team = '1224,1958,1808,1394,1820,1493,896,1617,1651,1319,1879,917,854,1844,1912,1826,1538,929,932,1163,1166,1976,1061,1040,1397,1677,1563,1157,1496,1499,1043,1644,1502,2016,1906,1838,1109,1611,1928,881,1505,1409,1412,1415,1418,1421,1424,1427,1430,1433,1436,1439,1443,1446,1449,1452,1457,1463,1467,1472,1475,1478,1915,1481,1484,1487,1490,1298,1376,1952,1367,935,1253,1233,1244,1709,2020,1755,1931,1508,1196,1605,857,1988,1793,2013,1854,1584,1658,860,1937,1700,1909,1868,971,974,1088,1875,1903,977,1154,1706,1623,1829,1674,1511,1079,1715,1805,1894,812,1782,1608,1688,1697,2001,1514,923,1310,1998,1121,1124,1982,1322,818,1703,1271,1964,1967,1091,824,1773,1749,986,2023,1304,1955,890,1871,1461,1454,1730,899,1325,1576,1811,1400,1213,1799,1638,863,1668,1352,1570,1802,1620,2004,1358,1217,1946,1718,1307,2007,1770,866,1943,1340,1817,1094,1127,1130,1925,980,1190,1934,1193,902,1343,1346,1973,1897,989,1256,1940,1626,1587,1239,1884,1286,1236,1661,779,780,781,1221,1022,1242,1211,1025,1028,1283,1313,1250,1280,1268,1247,1148,1370,1289,983,1301,1295,1602,1532,1328,1922,1739,992,1680,1683,920,1133,965,968,938,944,947,1566,1761,1517,1355,1097,1139,1985,1647,1274,1520,1277,1891,1857,1136,869,1142,1145,956,1055,1016,1019,1031,1034,1058,1037,1064,1049,1052,1641,1070,1073,1047,1076,959,926,1900,995,1331,1160,836,1085,1848,1992,1851,1535,1388,1391,1259,1262,1758,1292,839,884,887,842,827,821,1764,962,1779,848,1115,1118,1265,1863,1918,1655,1767,1316,1373,830,845,875,878,1004,1067,1112,1100,1349,1379,998,1887,953,1082,1841,1752,1785,941,1995,1523,1694,1385,1573,1334,1169,1172,1199,833,1202,1712,1205,1208,1230,1832,1382,815,1227,905,1722,1744,1790,1746,1103,1007,1010,2010,1404,911,1796,914,1949,851,748,1526,1727,1469,950,1554,1557,1560,1106,1337,1001,1671,1860,1979,1175,1178,1181,1184,1187,1961,893,1151,1970,1013,1664,1529,1835,1599,1776,908,1406,1823,872,1814,1361,1364,1581'

----------------CO
--SET @Team = '854,857,860,863,866,869,971,974,977,980,983,986,989,992,995,998,1001,1004,1007,1010,1013,1576,1887,1922,1925,1943,1988,2010'

----for testing
------===========================================================================================

DECLARE
@rStartDate Date
, @rEndDate Date
, @rTeam varchar(max)
, @rRepeat INT

SET @rStartDate = @StartDate
SET @rEndDate = @EndDate
SET @rTeam = @Team
SET @rRepeat = (DATEDIFF(MONTH,@rStartDate,@rEndDate)+1)

----Tables for staff details and aggregates

----S T A F F    I N F O
DECLARE @StaffDetails TABLE
(  	[Counter] [int] NULL,
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	
	[National] [varchar](50) NULL,
	[NationalID] [smallint] NULL,	
	[State] [varchar](50) NULL,
	[US State] [nvarchar](255) NULL,
	[StateID] [int] NULL,
	[SiteID] [smallint] NULL,
	[SiteName] [nvarchar](200) NULL,
	[ProgramID] [smallint] NULL,
	[TeamName] [varchar](500) NULL,
	
	[SumFTE] [numeric](18, 5) NULL,
	[CountNHV2] [int] NULL,
	[CountNHV] [int] NULL,
	[MissingFTE] [int] NULL,
	[MissingPosition] [int] NULL,
	[EntityId] [int] NULL
	
)	-- end staff detail table variable 

----C L I E N T    I N F O
DECLARE @ClientDetails TABLE
(  	[Counter] [int] NULL,
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	
	[National] [varchar](50) NULL,
	[NationalID] [smallint] NULL,	
	[State] [varchar](50) NULL,
	[US State] [nvarchar](255) NULL,
	[StateID] [int] NULL,
	[SiteID] [smallint] NULL,
	[SiteName] [nvarchar](200) NULL,
	[ProgramID] [smallint] NULL,
	[TeamName] [varchar](500) NULL,

	[ClientID] [int] NULL
	
)	-- end staff detail table variable 

---- S T A F F    and    C L I E N T
DECLARE @Aggregates TABLE
(   [Counter] [int] NULL,
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	
	[NationalID] [smallint] NULL,		
	[StateID] [int] NULL,
	[SiteID] [smallint] NULL,
	[ProgramID] [smallint] NULL,
	
	[NationalClientCount] [int] NULL,
	[StateClientCount] [int] NULL,
	[AgencyClientCount] [int] NULL,
	[TeamClientCount] [int] NULL,
	
	[NationalCountNHV2] [int] NULL,
	[NationalSumFTE] [numeric](18, 2) NULL,
	[NationalCountNHV] [int] NULL,
	[NationalMissingFTE] [int] NULL,
	[NationalMissingPosition] [int] NULL,
	
	[StateCountNHV2] [int] NULL,
	[StateSumFTE] [numeric](18, 2) NULL,
	[StateCountNHV] [int] NULL,
	[StateMissingFTE] [int] NULL,
	[StateMissingPosition] [int] NULL,

	[AgencyCountNHV2] [int] NULL,
	[AgencySumFTE] [numeric](18, 2) NULL,
	[AgencyCountNHV] [int] NULL,
	[AgencyMissingFTE] [int] NULL,
	[AgencyMissingPosition] [int] NULL,

	[TeamCountNHV2] [int] NULL,
	[TeamSumFTE] [numeric](18, 2) NULL,
	[TeamCountNHV] [int] NULL,
	[TeamMissingFTE] [int] NULL,
	[TeamMissingPosition] [int] NULL	
	
)	--end aggregated table varible
------===========================================================================================

----split multi parameters into table
DECLARE @TeamTable TABLE(Value BIGINT) 
DECLARE @x XML  
SELECT @x = CAST('<A>'+ REPLACE(@rTeam,',','</A><A>')+ '</A>' AS XML) 
INSERT INTO @TeamTable             
SELECT t.value('.', 'int') AS inVal 
FROM @x.nodes('/A') AS x(t) 

-----------------------------------------------------------------------------------------
----S T A F F    I N F O

DECLARE @StfCounter INT, @StfStartDate DATE, @StfEndDate DATE
SET @StfCounter = 0
SET @StfStartDate = @rStartDate
SET @StfEndDate = @rEndDate

--begin while, this performs tne iterations and inserts the records to the details table variable
WHILE @StfCounter < @rRepeat
BEGIN
		---- insert details records for all of the iterations
		INSERT INTO @StaffDetails(
									[Counter], [StartDate], [EndDate]
									,[National], [NationalID] 
									,[State], [US State], [StateID], [SiteID], [SiteName], [ProgramID], [TeamName]
									,[SumFTE], [CountNHV2], [CountNHV], [MissingFTE], [MissingPosition], [EntityId]	)
		
		SELECT 
			@StfCounter [Counter]
			,@StfStartDate StartDate
			,@StfEndDate EndDate
			,'National' [National]
			,1 NationalID
			,StaffInfo.Abbreviation [State]
			,StaffInfo.[US State]
			,StaffInfo.StateID
			,StaffInfo.SiteID
			,StaffInfo.AGENCY_INFO_0_NAME SiteName
			,StaffInfo.ProgramID
			,StaffInfo.ProgramName	TeamName		
	
			,(StaffInfo.HV_FTE) SumFTE		
			,CASE WHEN (StaffInfo.NHV_Flag = 1) 
				THEN StaffInfo.Entity_Id
			END CountNHV2
			,CASE WHEN (StaffInfo.NHV_Flag = 1 OR ISNULL(StaffInfo.HV_FTE,0) > 0) 
				THEN StaffInfo.Entity_Id
				END CountNHV
			,CASE WHEN StaffInfo.NHV_Flag = 1 AND ISNULL(StaffInfo.HV_FTE,0) = 0 
				THEN StaffInfo.Entity_Id
			END MissingFTE
			,CASE WHEN StaffInfo.HV_FTE > 0 AND ISNULL(StaffInfo.NHV_Flag,0) = 0 
				THEN StaffInfo.Entity_Id
			END MissingPosition			

			,StaffInfo.Entity_Id EntityID

		FROM dbo.fn_FID_Staff_list (@StfStartDate,@StfEndDate) StaffInfo	
						  
		WHERE (StaffInfo.EndDate IS NULL OR StaffInfo.EndDate > @StfEndDate)
			AND StaffInfo.Entity_Id IS NOT NULL
			AND (	StaffInfo.NHV_Flag > 0 OR StaffInfo.HV_FTE > 0 )

		----reset counter and dates for next iteration
		SET @StfCounter = @StfCounter + 1	
		SET @StfStartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @StfStartDate)-1, 0)	--First day of previous month
		SET @StfEndDate = DATEADD(MONTH, DATEDIFF(MONTH, -1, @StfEndDate)-1, -1)		--Last Day of previous month

END --end while, this performs tne iterations and inserts the records to the details table variable

----@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
----S T A F F    I N F O
----select the details from details table variable, only

--SELECT *
--FROM @StaffDetails
--ORDER BY  [Counter], StateID, SiteID, ProgramID, EntityId

---------------------------------------------------------------------------------------------------------------------------
----S T A F F    I N F O
----insert team numbers into aggregates table variable

INSERT INTO @Aggregates([Counter], [StartDate], [EndDate]
								,[NationalID]--, [National]
								,[StateID]--, [State], [US State]
								,[SiteID]--, [SiteName]
								,[ProgramID]--, [TeamName]
								,[TeamCountNHV2], [TeamSumFTE], [TeamCountNHV], [TeamMissingFTE], [TeamMissingPosition] )
SELECT 
	0 [Counter]
	,sd.StartDate
	,sd.EndDate
	,sd.NationalID
	,sd.StateID
	,sd.SiteID
	,sd.ProgramID

	,COUNT(DISTINCT sd.CountNHV2) TeamCountNHV2
	,SUM(sd.SumFTE) TeamSumFTE
	,COUNT(DISTINCT sd.CountNHV) TeamCountNHV
	,COUNT(DISTINCT sd.MissingFTE) TeamMissingFTE
	,COUNT(DISTINCT sd.MissingPosition) TeamMissingPosition

FROM @StaffDetails sd
WHERE sd.[Counter] = 0

GROUP BY
	sd.StartDate
	,sd.EndDate
	,sd.NationalID
	,sd.StateID
	,sd.SiteID
	,sd.ProgramID
	
----S T A F F    I N F O
----update site numbers into aggregates table variable

UPDATE agg 
SET agg.[AgencyCountNHV2] = sd.a
	,agg.[AgencySumFTE] = sd.b
	,agg.[AgencyCountNHV] = sd.c
	,agg.[AgencyMissingFTE] = sd.d
	,agg.[AgencyMissingPosition] = sd.e
FROM @Aggregates agg
	LEFT JOIN 
		(	SELECT SiteID 
				,COUNT(DISTINCT CountNHV2) a
				,SUM(SumFTE) b
				,COUNT(DISTINCT CountNHV) c
				,COUNT(DISTINCT MissingFTE) d
				,COUNT(DISTINCT MissingPosition) e
			FROM @StaffDetails
			WHERE [Counter] = 0
			GROUP BY SiteID
		) sd ON sd.SiteID = agg.SiteID

----S T A F F    I N F O
----update state numbers into aggregates table variable

UPDATE agg 
SET agg.[StateCountNHV2] = sd.a
	,agg.[StateSumFTE] = sd.b
	,agg.[StateCountNHV] = sd.c
	,agg.[StateMissingFTE] = sd.d
	,agg.[StateMissingPosition] = sd.e
FROM @Aggregates agg
	LEFT JOIN 
		(	SELECT StateID 
				,COUNT(DISTINCT CountNHV2) a
				,SUM(SumFTE) b
				,COUNT(DISTINCT CountNHV) c
				,COUNT(DISTINCT MissingFTE) d
				,COUNT(DISTINCT MissingPosition) e
			FROM @StaffDetails
			WHERE [Counter] = 0
			GROUP BY StateID
		) sd ON sd.StateID = agg.StateID

----S T A F F    I N F O
----update national numbers into aggregates table variable

UPDATE agg 
SET agg.[NationalCountNHV2] = sd.a
	,agg.[NationalSumFTE] = sd.b
	,agg.[NationalCountNHV] = sd.c
	,agg.[NationalMissingFTE] = sd.d
	,agg.[NationalMissingPosition] = sd.e
FROM @Aggregates agg
	LEFT JOIN 
		(	SELECT NationalID 
				,COUNT(DISTINCT CountNHV2) a
				,SUM(SumFTE) b
				,COUNT(DISTINCT CountNHV) c
				,COUNT(DISTINCT MissingFTE) d
				,COUNT(DISTINCT MissingPosition) e
			FROM @StaffDetails
			WHERE [Counter] = 0
			GROUP BY NationalID
		) sd ON sd.NationalID = agg.NationalID
		
-----------------------------------------------------------------
----S T A F F    I N F O
----select the aggregates from aggregates table variable, only

--SELECT *
--FROM @StaffAggregates
--ORDER BY [Counter], NationalID, StateID, SiteID, ProgramID	

------@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
------@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

----C L I E N T    I N F O

DECLARE @ClCounter INT, @ClStartDate DATE, @ClEndDate DATE
SET @ClCounter = 0
SET @ClStartDate = @rStartDate
SET @ClEndDate = @rEndDate

--begin while, this performs tne iterations and inserts the records to the details table variable
WHILE @ClCounter < @rRepeat
BEGIN
		---- insert details records for all of the iterations
		INSERT INTO @ClientDetails(
									[Counter], [StartDate], [EndDate]
									,[National], [NationalID] 
									,[State], [US State], [StateID], [SiteID], [SiteName], [ProgramID], [TeamName]
									,[ClientID]	)
		
		SELECT 
			DISTINCT			
			@ClCounter [Counter]
			,@ClStartDate StartDate
			,@ClEndDate EndDate			
			,'National' [National]
			,1 NationalID
			,P.Abbreviation [State]
			,P.[US State]
			,P.StateID
			,P.SiteID
			,P.AGENCY_INFO_0_NAME SiteName
			,P.ProgramID
			,P.ProgramName	TeamName		

			,EAD.CLID

		FROM UV_EADT EAD
			LEFT OUTER JOIN UV_PAS P
				ON EAD.ProgramID IN (P.Program_ID_NHV
									,P.Program_ID_Referrals
									,P.Program_ID_Staff_Supervision)
			LEFT OUTER JOIN
				(	SELECT DISTINCT HVES.CL_EN_GEN_ID, HVES.ProgramID
					FROM Home_Visit_Encounter_Survey HVES
					WHERE HVES.SurveyDate <= @ClEndDate
						AND HVES.CLIENT_COMPLETE_0_VISIT = 'Completed'
				) HVES ON EAD.CLID = HVES.CL_EN_GEN_ID
						AND EAD.ProgramID = HVES.ProgramID
			LEFT OUTER JOIN
				(	SELECT AES.CL_EN_GEN_ID, AES.ProgramID
					FROM Alternative_Encounter_Survey AES
					WHERE AES.CLIENT_TALKED_0_WITH_ALT LIKE '%Client;%'
						OR AES.CLIENT_TALKED_0_WITH_ALT  = 'Client'
						AND AES.SurveyDate <= @ClEndDate
				) AES ON EAD.CLID = AES.CL_EN_GEN_ID
					AND EAD.ProgramID = AES.ProgramID
				
		WHERE EAD.ProgramStartDate <= @ClEndDate 
			AND ISNULL(EAD.EndDate,DATEADD(D,1,@ClEndDate)) >= @ClEndDate
			AND (HVES.CL_EN_GEN_ID IS NOT NULL OR AES.CL_EN_GEN_ID IS NOT NULL)
			AND P.PROGRAMID IS NOT NULL
			
		----reset counter and dates for next iteration
		SET @ClCounter = @ClCounter + 1	
		SET @ClStartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @ClStartDate)-1, 0)	--First day of previous month
		SET @ClEndDate = DATEADD(MONTH, DATEDIFF(MONTH, -1, @ClEndDate)-1, -1)		--Last Day of previous month
	
END --end while, this performs tne iterations and inserts the records to the details table variable

----@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
----C L I E N T    I N F O
----select the details from details table variable, only

--SELECT *
--FROM @ClientDetails
--ORDER BY [Counter], StateID, SiteID, ProgramID, ClientId

---------------------------------------------------------------------------------------------------------------------------
----C L I E N T    I N F O
------update team numbers into aggregates table variable

UPDATE agg
SET agg.[TeamClientCount] = cd.a
FROM @Aggregates agg
	LEFT JOIN 
		(	
			SELECT ProgramID 
				,COUNT(DISTINCT ClientId) a
			FROM @ClientDetails
			WHERE [Counter] = 0
			GROUP BY ProgramID
		) cd ON cd.ProgramID = agg.ProgramID
	
----C L I E N T    I N F O
------update site numbers into aggregates table variable

UPDATE agg 
SET agg.[AgencyClientCount] = cd.a
FROM @Aggregates agg
	LEFT JOIN 
		(	
			SELECT SiteID 
				,COUNT(DISTINCT ClientId) a
			FROM @ClientDetails
			WHERE [Counter] = 0
			GROUP BY SiteID
		) cd ON cd.SiteID = agg.SiteID

----C L I E N T    I N F O
------update state numbers into aggregates table variable

UPDATE agg 
SET agg.[StateClientCount] = cd.a

FROM @Aggregates agg
	LEFT JOIN 
		(	SELECT StateID 
				,COUNT(DISTINCT ClientID) a

			FROM @ClientDetails
			WHERE [Counter] = 0
			GROUP BY StateID
		) cd ON cd.StateID = agg.StateID

----C L I E N T    I N F O
------update national numbers into aggregates table variable

UPDATE agg 
SET agg.[NationalClientCount] = cd.a

FROM @Aggregates agg
	LEFT JOIN 
		(	SELECT NationalID 
				,COUNT(DISTINCT ClientID) a

			FROM @ClientDetails
			WHERE [Counter] = 0
			GROUP BY NationalID
		) cd ON cd.NationalID = agg.NationalID
		
-------------------------------------------------------------------
----C L I E N T    I N F O
------select the aggregates from aggregates table variable, only

--SELECT *
--FROM @ClientAggregates
--ORDER BY [Counter], NationalID, StateID, SiteID, ProgramID	

------@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
--------join aggregates to details, then filter the results

----COMBINE/UNION ALL    S T A F F    and    C L I E N T    Info
									
SELECT 
	cd.[Counter]
	,cd.StartDate
	,cd.EndDate
	,cd.[National]
	,cd.NationalID
	,cd.[State]
	,cd.[US State]
	,cd.StateID
	,cd.SiteID
	,cd.SiteName
	,cd.ProgramID
	,cd.TeamName
	
	,cd.ClientID ID

	,agg.[NationalClientCount]
	,agg.[StateClientCount]
	,agg.[AgencyClientCount]
	,agg.[TeamClientCount]
	
	,agg.[NationalCountNHV2]
	,agg.[NationalSumFTE] 
	,agg.[NationalCountNHV]
	,agg.[NationalMissingFTE] 
	,agg.[NationalMissingPosition]
	
	,agg.[StateCountNHV2] 
	,agg.[StateSumFTE] 
	,agg.[StateCountNHV]
	,agg.[StateMissingFTE] 
	,agg.[StateMissingPosition] 

	,agg.[AgencyCountNHV2]
	,agg.[AgencySumFTE] 
	,agg.[AgencyCountNHV] 
	,agg.[AgencyMissingFTE]
	,agg.[AgencyMissingPosition]

	,agg.[TeamCountNHV2]
	,agg.[TeamSumFTE] 
	,agg.[TeamCountNHV] 
	,agg.[TeamMissingFTE] 
	,agg.[TeamMissingPosition] 

FROM @ClientDetails cd
	JOIN @TeamTable parm				----report selection
		ON parm.Value = cd.ProgramID	----TeamTable contains team program ids
	LEFT JOIN @Aggregates agg ON agg.[Counter] = cd.[Counter]
									AND agg.ProgramID = cd.ProgramID
									AND cd.[Counter] = 0

UNION ALL

SELECT 
	sd.[Counter]
	,sd.StartDate
	,sd.EndDate
	,sd.[National]
	,sd.NationalID
	,sd.[State]
	,sd.[US State]
	,sd.StateID
	,sd.SiteID
	,sd.SiteName
	,sd.ProgramID
	,sd.TeamName
	
	,sd.EntityID ID
	
	,agg.[NationalClientCount]
	,agg.[StateClientCount]
	,agg.[AgencyClientCount]
	,agg.[TeamClientCount]
	
	,agg.[NationalCountNHV2]
	,agg.[NationalSumFTE] 
	,agg.[NationalCountNHV]
	,agg.[NationalMissingFTE] 
	,agg.[NationalMissingPosition]
	
	,agg.[StateCountNHV2] 
	,agg.[StateSumFTE] 
	,agg.[StateCountNHV]
	,agg.[StateMissingFTE] 
	,agg.[StateMissingPosition] 

	,agg.[AgencyCountNHV2]
	,agg.[AgencySumFTE] 
	,agg.[AgencyCountNHV] 
	,agg.[AgencyMissingFTE]
	,agg.[AgencyMissingPosition]

	,agg.[TeamCountNHV2]
	,agg.[TeamSumFTE] 
	,agg.[TeamCountNHV] 
	,agg.[TeamMissingFTE] 
	,agg.[TeamMissingPosition] 

FROM @StaffDetails sd
	JOIN @TeamTable parm				----report selection
		ON parm.Value = sd.ProgramID	----TeamTable contains team program ids
	LEFT JOIN @Aggregates agg ON agg.[Counter] = sd.[Counter]
									AND agg.ProgramID = sd.ProgramID
									AND sd.[Counter] = 0										
WHERE agg.[NationalCountNHV2] IS NOT NULL
--------------------------------------------------------------------------------------
------for testing

--ORDER BY [Counter], NationalID, StateID, SiteID, ProgramID, ID

------for testing
--------------------------------------------------------------------------------------




GO
