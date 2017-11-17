USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_HRSA_MIECHV_Master]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

--Funding '1' = Competive, '2' = Formula, '3' = Tribal, '1,2,3'
--California Teams
--SET @Teams =  '1535,1557,1554,1394,1820,1617,1397,1755,818,824,1773,1400,1668,1620,1770,965,968,836,1388,1391,839,884,887,842,827,821,1764,962,1779,848,1767,830,845,1752,833,1712,815,1744,1404,851'

--California NHV
--SET @NHV = '-1,19107,20810,20808,19251,20809,18827,20697,19000,20794,27252,18869,20378,7505,7497,24821,24924,20920,6393,21141,23622,21797,25727,22704,21343,25637,26301,22282,27157,7436,7986,25307,24822,7658,7122,6397,26862,22705,25359,22272,8631,7880,18634,7984,8114,11723,8785,6981,20797,7836,26927,21486,7097,6985,8780,25203,7660,24788,22134,23789,23628,22281,7993,21688,26093,9310,21371,6996,24537,22866,20362,6975,7455,21532,21793,8414,21344,21121,7990,7839,21485,6338,20667,21316,7094,19230,21802,9323,7894,20017,25299,18868,18638,13846,8116,23004,6395,25082,21480,22430,9322,8788,22129,8641,9319,14108,24787,26280,7982,21250,7071,24417,18872,9321,10000443,26914,7299,8632,7305,7080,21402,27156,21145,24679,7668,18828,20386,20407,22943,19130,26251,21401,8653,27155,26767,25384,8654,9317,24406,7484,7495,8650,21366,13569,21687,23673,20647,23002,6385,7124,26926,26148,22255,21400,7112,21674,6991,21663,24453,8118,20986,8782,9324,22526,25624,18871,21800,7068,26616,14106,7988,10000438,7844,21745,26365,19229,25864,21079,7066,26691,21367,9311,26340,22241,9314,7662,22310,22273,7432,21152,14187,27028,20948,19778,7107,22286,8655,7073,6973,26011,25833,7430,20988,9329,20312,26794,9320,9325,9328,18633,24637,27258,18632,6968,27228,26179,13964,21144,24445,20491,22305,21961,7301,7656,20161,21673,20985,22326,21382,19274,8422,21431,22047,7332,19573,21383,20003,20921,6381,19235,20385,8648,21264,7499,21341,9312,8002,7329,21792,21932,14268,9313,25741,8009,20987,20698,24196,21868,26915,25256,21345,24178,20955,26755,8651,21479,24011,22130,21686,22333,18873,20298,9318,6342,24760,23971,22706,7886,22271,14032,26391,9326'


CREATE PROCEDURE [dbo].[usp_HRSA_MIECHV_Master]
	(@StartDate DATE
	,@EndDate Date
	,@FundingType VARCHAR(MAX)
	,@Teams VARCHAR(MAX)
	,@NHV VARCHAR(MAX)) 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	--SET NOCOUNT ON;
	
   DECLARE @RtnTable TABLE --(CLID INT, ProgramID smallint, ReportStartDate DATETIME, ReportEndDate DATETIME, ReportYear VARCHAR(50))
   
   (
   SiteName NVARCHAR(200)
	,[Agencies Site_ID] INT
	,[State] INT
	,Abbreviation NVARCHAR(255)
	,CLID INT
	,ProgramID INT
	,ProgramStartDate DATETIME	
	,[Newly Enrolled MIECHV During Reporting Period] INT
	,[MIECHV Served During Reporting Period] INT
	,[MIECHV Infants Born During Reporting Period] INT
	,[MIECHV Infants Served During Reporting Period] INT
	,INFANT_BIRTH_0_DOB DATETIME
	,[Pregnant during reporting period] INT
	,[Client Insurance - Unknown]	 INT
	,[Child Insurance - Unknown]	INT
	,[Client Insurance - None]	INT
	,[Child Insurance - None] INT
	,[Medicaid Client] INT
	,[Medicaid Child] INT
	,[Private Client] INT
	,[Private Child] INT
	,[Military Client] INT
	,[Military Child] INT
	, Client_Insurance_Status VARCHAR(500)
	,CLIENT_MARITAL_0_STATUS VARCHAR(500)
	,[Education Level]  	VARCHAR(500)
	,[Education Level Sorting] INT
	,[Clients Age] VARCHAR(500)
	,[Clients Age Sorting] INT
	,[Child Age at End of Quarter] VARCHAR(500)
	,INFANT_PERSONAL_0_GENDER VARCHAR(500)
	,[Hispanic or Latino] INT
	,[Not Hispanic or Latino] INT
	,[Declined Ethnicity] INT
	,[Unrecorded Ethnicity] INT	
	,ClientEthnicity VARCHAR(500)
	,[American Indian] INT
	,[Asian] INT
	,[Black] INT
	,[Native Hawaiian] INT
	,[White] INT
	,[More than one race] INT
	,[Declined Race] INT
	,[Unrecorded Race] INT
	, ClientRace VARCHAR(500)
	,[Employment Status] VARCHAR(500)
	,[Education/Training Status] VARCHAR(500)
	,[Primary Language] VARCHAR(500)
	,LowIncomeCriteria INT
	,PregnantUnder21 INT
	,TobaccoUser INT
	,Military INT
	,[Currently Rcv Svcs] VARCHAR(500)
	,[Home visits during reporting period] INT
	,FundingType INT	
	,ReportYear VARCHAR(50)
	)
	
	
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
		
		INSERT INTO @RtnTable      --(CLID, ProgramID, ReportStartDate, ReportEndDate  , ReportYear)
					(
					SiteName 
					,[Agencies Site_ID] 
					,[State] 
					,Abbreviation 
					,CLID 
					,ProgramID 
					,ProgramStartDate 	
					,[Newly Enrolled MIECHV During Reporting Period] 
					,[MIECHV Served During Reporting Period] 
					,[MIECHV Infants Born During Reporting Period] 
					,[MIECHV Infants Served During Reporting Period] 
					,INFANT_BIRTH_0_DOB 
					,[Pregnant during reporting period] 
					,[Client Insurance - Unknown]	 
					,[Child Insurance - Unknown]	
					,[Client Insurance - None]	
					,[Child Insurance - None] 
					,[Medicaid Client] 
					,[Medicaid Child] 
					,[Private Client] 
					,[Private Child] 
					,[Military Client] 
					,[Military Child] 
					,Client_Insurance_Status
					,CLIENT_MARITAL_0_STATUS 
					,[Education Level]  	
					,[Education Level Sorting] 
					,[Clients Age] 
					,[Clients Age Sorting] 
					,[Child Age at End of Quarter] 
					,INFANT_PERSONAL_0_GENDER 
					,[Hispanic or Latino] 
					,[Not Hispanic or Latino] 
					,[Declined Ethnicity] 
					,[Unrecorded Ethnicity] 
					,ClientEthnicity	
					,[American Indian] 
					,[Asian] 
					,[Black] 
					,[Native Hawaiian] 
					,[White] 
					,[More than one race] 
					,[Declined Race] 
					,[Unrecorded Race] 
					,ClientRace
					,[Employment Status] 
					,[Education/Training Status] 
					,[Primary Language] 
					,LowIncomeCriteria 
					,PregnantUnder21 
					,TobaccoUser 
					,Military 
					,[Currently Rcv Svcs] 
					,[Home visits during reporting period] 
					,FundingType 
					,ReportYear 
					)
			EXEC usp_HRSA_MIECHV_Summary @CurrentStartDate, @CurrentEndDate, @FundingType, @Teams, @NHV 
		SET @intFlag = @intFlag + 1
	END
	
	SELECT			SiteName 
					,[Agencies Site_ID] 
					,[State] 
					,Abbreviation 
					,CLID 
					,ProgramID 
					,ProgramStartDate 	
					,[Newly Enrolled MIECHV During Reporting Period] 
					,[MIECHV Served During Reporting Period] 
					,[MIECHV Infants Born During Reporting Period] 
					,[MIECHV Infants Served During Reporting Period] 
					,INFANT_BIRTH_0_DOB 
					,[Pregnant during reporting period] 
					,[Client Insurance - Unknown]	 
					,[Child Insurance - Unknown]	
					,[Client Insurance - None]	
					,[Child Insurance - None] 
					,[Medicaid Client] 
					,[Medicaid Child] 
					,[Private Client] 
					,[Private Child] 
					,[Military Client] 
					,[Military Child] 
					,Client_Insurance_Status
					,CLIENT_MARITAL_0_STATUS 
					,[Education Level]  	
					,[Education Level Sorting] 
					,[Clients Age] 
					,[Clients Age Sorting] 
					,[Child Age at End of Quarter] 
					,INFANT_PERSONAL_0_GENDER 
					,[Hispanic or Latino] 
					,[Not Hispanic or Latino] 
					,[Declined Ethnicity] 
					,[Unrecorded Ethnicity] 
					,ClientEthnicity	
					,[American Indian] 
					,[Asian] 
					,[Black] 
					,[Native Hawaiian] 
					,[White] 
					,[More than one race] 
					,[Declined Race] 
					,[Unrecorded Race] 
					,ClientRace
					,[Employment Status] 
					,[Education/Training Status] 
					,[Primary Language] 
					,LowIncomeCriteria 
					,PregnantUnder21 
					,TobaccoUser 
					,Military 
					,[Currently Rcv Svcs] 
					,[Home visits during reporting period] 
					,FundingType 
					,ReportYear 
					 FROM @RtnTable
	
	
END
GO
