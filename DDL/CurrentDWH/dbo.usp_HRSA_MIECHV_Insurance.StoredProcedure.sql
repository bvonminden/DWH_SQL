USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_HRSA_MIECHV_Insurance]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	1. Determine how many fiscal reporting years (oct 1 - sept 30) are contained in the start and end date
--				2.  For each of the fiscal reporting years (oct 1 - sept 30) contained in the start and end date,
--				3.  Pass the start and end date of the reporting year  into the function and union all the results
-- =============================================

--SET @StartDate = '10/1/2012'
--SET @EndDate = '9/30/2014'

--SET @FundingType = 1  --Competitive

--SET @Teams =  '1535,1557,1554,1394,1820,1617,1397,1755,818,824,1773,1400,1668,1620,1770,965,968,836,1388,1391,839,884,887,842,827,821,1764,962,1779,848,1767,830,845,1752,833,1712,815,1744,1404,851'  --California
--1535,1557,1554,1394,1820,1617,1397,1755,818,824,1773,1400,1668,1620,1770,965,968,836,1388,1391,839,884,887,842,827,821,1764,962,1779,848,1767,830,845,1752,833,1712,815,1744,1404,851  

--SET @NHV = '-1,19107,20810,20808,19251,20809,18827,20697,19000,20794,27252,18869,20378,7505,7497,24821,24924,20920,6393,21141,23622,21797,25727,22704,21343,25637,26301,22282,27157,7436,7986,25307,24822,7658,7122,6397,26862,22705,25359,22272,8631,7880,18634,7984,8114,11723,8785,6981,20797,7836,26927,21486,7097,6985,8780,25203,7660,24788,22134,23789,23628,22281,7993,21688,26093,9310,21371,6996,24537,22866,20362,6975,7455,21532,21793,8414,21344,21121,7990,7839,21485,6338,20667,21316,7094,19230,21802,9323,7894,20017,25299,18868,18638,13846,8116,23004,6395,25082,21480,22430,9322,8788,22129,8641,9319,14108,24787,26280,7982,21250,7071,24417,18872,9321,10000443,26914,7299,8632,7305,7080,21402,27156,21145,24679,7668,18828,20386,20407,22943,19130,26251,21401,8653,27155,26767,25384,8654,9317,24406,7484,7495,8650,21366,13569,21687,23673,20647,23002,6385,7124,26926,26148,22255,21400,7112,21674,6991,21663,24453,8118,20986,8782,9324,22526,25624,18871,21800,7068,26616,14106,7988,10000438,7844,21745,26365,19229,25864,21079,7066,26691,21367,9311,26340,22241,9314,7662,22310,22273,7432,21152,14187,27028,20948,19778,7107,22286,8655,7073,6973,26011,25833,7430,20988,9329,20312,26794,9320,9325,9328,18633,24637,27258,18632,6968,27228,26179,13964,21144,24445,20491,22305,21961,7301,7656,20161,21673,20985,22326,21382,19274,8422,21431,22047,7332,19573,21383,20003,20921,6381,19235,20385,8648,21264,7499,21341,9312,8002,7329,21792,21932,14268,9313,25741,8009,20987,20698,24196,21868,26915,25256,21345,24178,20955,26755,8651,21479,24011,22130,21686,22333,18873,20298,9318,6342,24760,23971,22706,7886,22271,14032,26391,9326'
-- -1,19107,20810,20808,19251,20809,18827,20697,19000,20794,27252,18869,20378,7505,7497,24821,24924,20920,6393,21141,23622,21797,25727,22704,21343,25637,26301,22282,27157,7436,7986,25307,24822,7658,7122,6397,26862,22705,25359,22272,8631,7880,18634,7984,8114,11723,8785,6981,20797,7836,26927,21486,7097,6985,8780,25203,7660,24788,22134,23789,23628,22281,7993,21688,26093,9310,21371,6996,24537,22866,20362,6975,7455,21532,21793,8414,21344,21121,7990,7839,21485,6338,20667,21316,7094,19230,21802,9323,7894,20017,25299,18868,18638,13846,8116,23004,6395,25082,21480,22430,9322,8788,22129,8641,9319,14108,24787,26280,7982,21250,7071,24417,18872,9321,10000443,26914,7299,8632,7305,7080,21402,27156,21145,24679,7668,18828,20386,20407,22943,19130,26251,21401,8653,27155,26767,25384,8654,9317,24406,7484,7495,8650,21366,13569,21687,23673,20647,23002,6385,7124,26926,26148,22255,21400,7112,21674,6991,21663,24453,8118,20986,8782,9324,22526,25624,18871,21800,7068,26616,14106,7988,10000438,7844,21745,26365,19229,25864,21079,7066,26691,21367,9311,26340,22241,9314,7662,22310,22273,7432,21152,14187,27028,20948,19778,7107,22286,8655,7073,6973,26011,25833,7430,20988,9329,20312,26794,9320,9325,9328,18633,24637,27258,18632,6968,27228,26179,13964,21144,24445,20491,22305,21961,7301,7656,20161,21673,20985,22326,21382,19274,8422,21431,22047,7332,19573,21383,20003,20921,6381,19235,20385,8648,21264,7499,21341,9312,8002,7329,21792,21932,14268,9313,25741,8009,20987,20698,24196,21868,26915,25256,21345,24178,20955,26755,8651,21479,24011,22130,21686,22333,18873,20298,9318,6342,24760,23971,22706,7886,22271,14032,26391,9326


CREATE PROCEDURE [dbo].[usp_HRSA_MIECHV_Insurance] 
	(@StartDate DATE
	,@EndDate Date
	,@FundingType VARCHAR(MAX)
	,@Teams VARCHAR(MAX)
	,@NHV VARCHAR(MAX)) 
AS



	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	--SET NOCOUNT ON;
	
   DECLARE @RtnTable TABLE (CLID INT, ProgramID smallint, ReportStartDate DATETIME, ReportEndDate DATETIME, ReportYear VARCHAR(50))
	
	--What is the first fiscal year contained in the startdate?
	DECLARE @FirstStartDate DATETIME
	DECLARE @FirstEndDate DATETIME	
	
	SET @FirstStartDate = 
	CASE
		WHEN  (@StartDate BETWEEN '10/1/2008' AND '9/30/2009') THEN '10/1/2008'
		WHEN  (@StartDate BETWEEN '10/1/2009' AND '9/30/2010') THEN '10/1/2009'
		WHEN  (@StartDate BETWEEN '10/1/2010' AND '9/30/2011') THEN '10/1/2010'
		WHEN  (@StartDate BETWEEN '10/1/2011' AND '9/30/2012') THEN '10/1/2011'
		WHEN  (@StartDate BETWEEN '10/1/2012' AND '9/30/2013') THEN '10/1/2012'
		WHEN  (@StartDate BETWEEN '10/1/2013' AND '9/30/2014') THEN '10/1/2013'
		WHEN  (@StartDate BETWEEN '10/1/2014' AND '9/30/2015') THEN '10/1/2014'
		WHEN  (@StartDate BETWEEN '10/1/2015' AND '9/30/2016') THEN '10/1/2015'
		WHEN  (@StartDate BETWEEN '10/1/2016' AND '9/30/2017') THEN '10/1/2016'
		WHEN  (@StartDate BETWEEN '10/1/2017' AND '9/30/2018') THEN '10/1/2017'
		WHEN  (@StartDate BETWEEN '10/1/2018' AND '9/30/2019') THEN '10/1/2018'
		WHEN  (@StartDate BETWEEN '10/1/2019' AND '9/30/2020') THEN '10/1/2019'
	END
	
	SET @FirstEndDate = DATEADD(year, 1, @FirstStartDate)
	SET @FirstEndDate = DATEADD (day,-1, @FirstEndDate)
	
	--How many years in the date range?
	DECLARE @LastStartDate DATETIME
	DECLARE @LastEndDate DATETIME
	DECLARE @NumberOfYears INT
	
	SET @LastStartDate = 
	CASE
		WHEN  (@EndDate BETWEEN '10/1/2008' AND '9/30/2009') THEN '10/1/2008'
		WHEN  (@EndDate BETWEEN '10/1/2009' AND '9/30/2010') THEN '10/1/2009'
		WHEN  (@EndDate BETWEEN '10/1/2010' AND '9/30/2011') THEN '10/1/2010'
		WHEN  (@EndDate BETWEEN '10/1/2011' AND '9/30/2012') THEN '10/1/2011'
		WHEN  (@EndDate BETWEEN '10/1/2012' AND '9/30/2013') THEN '10/1/2012'
		WHEN  (@EndDate BETWEEN '10/1/2013' AND '9/30/2014') THEN '10/1/2013'
		WHEN  (@EndDate BETWEEN '10/1/2014' AND '9/30/2015') THEN '10/1/2014'
		WHEN  (@EndDate BETWEEN '10/1/2015' AND '9/30/2016') THEN '10/1/2015'
		WHEN  (@EndDate BETWEEN '10/1/2016' AND '9/30/2017') THEN '10/1/2016'
		WHEN  (@EndDate BETWEEN '10/1/2017' AND '9/30/2018') THEN '10/1/2017'
		WHEN  (@EndDate BETWEEN '10/1/2018' AND '9/30/2019') THEN '10/1/2018'
		WHEN  (@EndDate BETWEEN '10/1/2019' AND '9/30/2020') THEN '10/1/2019'
	END
		
	SET @LastEndDate = DATEADD(year, 1, @LastStartDate)
	SET @LastEndDate = DATEADD(day, -1, @LastEndDate)
	
	SET @NumberOfYears = (SELECT 
                         DATEDIFF(YEAR, @FirstStartDate, @LastStartDate) + 
                         CASE 
                           WHEN MONTH(@LastStartDate) < MONTH(@FirstStartDate) THEN -1 
                           WHEN MONTH(@LastStartDate) > MONTH(@FirstStartDate) THEN 0 
                           ELSE 
                             CASE WHEN DAY(@LastStartDate) < DAY(@FirstStartDate) THEN -1 ELSE 0 END 
                         END)
	
	-- Invoke the function for each year
	DECLARE @intFlag INT
	SET @intFlag = 0
	WHILE (@intFlag <= @NumberOfYears)
	BEGIN
		DECLARE @CurrentStartDate DATETIME
		DECLARE @CurrentEndDate DATETIME
		SET @CurrentStartDate = DATEADD(year, @intFlag, @FirstStartDate)
		SET @CurrentEndDate = DATEADD(year, @intFlag, @FirstEndDate)
		
		INSERT INTO @RtnTable (CLID, ProgramID, ReportStartDate, ReportEndDate  , ReportYear)
			SELECT HM.CLID, HM.ProgramID, HM.ReportStartDate, HM.ReportEndDate, HM.ReportYear 
			FROM udf_HRSA_MIECHV_Insurance(@CurrentStartDate, @CurrentEndDate, @FundingType,@Teams) HM
		SET @intFlag = @intFlag + 1
	END
	
		
	----CTE
	--; WITH GovtCommSrvcsSurvey_client AS
	--(	SELECT MAX(SurveyResponseID) latestSurveyResponseID, CL_EN_GEN_ID CLID, ProgramID 
	--FROM Govt_Comm_Srvcs_Survey ----do not filter surveys by date, per Kyla Krause 9/11/2014
	--WHERE (DataWarehouse.dbo.fnGetFormName(SurveyID) = 'Use of Government & Community Services-Intake'			----used for client
	--		OR DataWarehouse.dbo.fnGetFormName(SurveyID) = 'Use of Government & Community Services-Infancy 12'	----child & client
	--		OR DataWarehouse.dbo.fnGetFormName(SurveyID) = 'Use of Government & Community Services-Toddler 24')	----child & client
	--GROUP BY CL_EN_GEN_ID, ProgramID 
	--)
	
	
	SELECT RT.CLID, RT.ProgramID, RT.ReportYear
	
	----Unknown Insurance
	,CASE WHEN GCClient.CL_EN_GEN_ID IS NULL 
				THEN 1 ELSE 0 
	END ClientInsuranceUnknown
	
	----No Insurance	   
	,CASE WHEN (GCClient.SERVICE_USE_0_MEDICAID_CLIENT NOT IN (2,5) OR GCClient.SERVICE_USE_0_MEDICAID_CLIENT IS NULL)
				AND (GCClient.SERVICE_USE_0_SCHIP_CLIENT NOT IN (2,5) OR GCClient.SERVICE_USE_0_SCHIP_CLIENT IS NULL)
				AND (GCClient.[SERVICE_USE_MILITARY_INS_CLIENT ] NOT IN (2,5) OR GCClient.[SERVICE_USE_MILITARY_INS_CLIENT ] IS NULL)
				AND (GCClient.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT NOT IN (2,5) OR GCClient.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IS NULL)
				AND GCClient.CL_EN_GEN_ID IS NOT NULL
					THEN 1 ELSE 0
	END ClientInsuranceNone	
	
	----Medicaid	  		
	,CASE WHEN GCClient.SERVICE_USE_0_MEDICAID_CLIENT IN (2,5) 
				OR GCClient.SERVICE_USE_0_SCHIP_CLIENT IN (2,5) 
					THEN 1 ELSE 0 
	END MedicaidClient	
	
	----Private Insurance 
	,CASE WHEN GCClient.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IN (2,5) 
					THEN 1 ELSE 0 
	END PrivateClient	
		
	----Military Insurance
	,CASE WHEN GCClient.[SERVICE_USE_MILITARY_INS_CLIENT ] IN (2,5) 
				THEN 1 ELSE 0 
	END MilitaryClient	
	
	--Rollup these values into a single column that you can group by
	,CASE 
		WHEN GCClient.CL_EN_GEN_ID IS NULL THEN 'Unknown/Did Not Report'
		WHEN (GCClient.SERVICE_USE_0_MEDICAID_CLIENT NOT IN (2,5) OR GCClient.SERVICE_USE_0_MEDICAID_CLIENT IS NULL)
				AND (GCClient.SERVICE_USE_0_SCHIP_CLIENT NOT IN (2,5) OR GCClient.SERVICE_USE_0_SCHIP_CLIENT IS NULL)
				AND (GCClient.[SERVICE_USE_MILITARY_INS_CLIENT ] NOT IN (2,5) OR GCClient.[SERVICE_USE_MILITARY_INS_CLIENT ] IS NULL)
				AND (GCClient.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT NOT IN (2,5) OR GCClient.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IS NULL)
				AND GCClient.CL_EN_GEN_ID IS NOT NULL THEN 'No Insurance Coverage'
		WHEN GCClient.SERVICE_USE_0_MEDICAID_CLIENT IN (2,5) 
				OR GCClient.SERVICE_USE_0_SCHIP_CLIENT IN (2,5) THEN 'Medicaid/SCHIP'
		WHEN GCClient.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IN (2,5) THEN 'Private or Other'
		WHEN GCClient.[SERVICE_USE_MILITARY_INS_CLIENT ] IN (2,5) THEN 'Tri-Care(Military)'
	END AS Client_Insurance_Status	
	
	FROM UV_EADT EAD 
	----------Team parm selection
	JOIN DataWarehouse.dbo.udf_ParseMultiParam(@Teams) parmTeams ON parmTeams.Value = EAD.ProgramID		----report selection for teams
	----------MIECHV funded
	JOIN @RtnTable RT
		ON RT.CLID = EAD.CLID
		AND RT.ProgramID = EAD.ProgramID
		--AND HM.[Served During Reporting Period] = 1	
	JOIN Clients C ON C.Client_Id = EAD.CLID  
	JOIN UV_PAS PAS ON PAS.ProgramID = EAD.ProgramID  
	
	--LEFT JOIN GovtCommSrvcsSurvey_client gsclient ON gsclient.CLID = EAD.CLID AND gsclient.ProgramID = EAD.ProgramID	
	--LEFT JOIN Govt_Comm_Srvcs_Survey GCClient ON GCClient.SurveyResponseID = gsclient.latestSurveyResponseID 
	--NOOO----filter on latest survey
	
	LEFT JOIN Govt_Comm_Srvcs_Survey GCClient ON GCClient.ClientID = RT.CLID AND GCClient.SurveyDate BETWEEN RT.ReportStartDate AND RT.ReportEndDate  
	
	
	----------NHV parm selection
	--LEFT JOIN StfToClientByEndDate sc ON sc.CLID = EAD.CLID
	--						AND sc.ProgramID = EAD.ProgramID
	--						AND sc.Ranking = 1
	--LEFT JOIN dbo.fn_FID_Staff_list('1/1/1900',@EndDate) S ON S.Entity_ID = sc.EntityID
	--													AND S.ProgramID = sc.ProgramID	
	
	--JOIN DataWarehouse.dbo.udf_ParseMultiParam(@NHV) parmNHV ON parmNHV.Value = CASE						----report selection for nurses
	--																				WHEN sc.EntityID > 0 
	--																				THEN sc.EntityID		----specific NHV selected
	--																				ELSE -1					----Unassigned NHV selected
	--																			END
	
	--DBO.udf_HRSA_MIECHV_ServedEnrolled_v3(@StartDate, @EndDate,@FundingType,@Teams) HM	
	--SELECT @FirstStartDate, @FirstEndDate, @LastStartDate, @LastEndDate, @NumberOfYears
	
	WHERE ISNULL( EAD.EndDate, GETDATE() ) >= @StartDate AND EAD.ProgramStartDate <= @EndDate
		AND EAD.RankingLatest = 1
	
	
	
GO
