USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Form1b]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_Form1b]

@Start date
,@End date

AS

--Declare @Start date
--Declare @End date

--Set @Start = '2014-05-01'
--Set @End = '2015-04-30'


--------------------------------------------------------------------------------------------------
--Starting Population - Served
------------------------------

Select

	Distinct(CL_EN_GEN_ID) as 'CL_EN_GEN_ID'
	, SiteID
	, ProgramID
	
Into #Population

From

	Home_Visit_Encounter_Survey

Where

	SurveyDate >= @Start and SurveyDate <= @End
	
---------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------
DECLARE @Team VARCHAR(4000)
SET @Team = '854,857,1988,860,863,866,1943,869,971,974,977,983,980,986,989,992,995,998,1887,1001,1004,1007,1010,2010,1013,1576,1922,1925' -- CO

SELECT 

COUNT(*)
--Distinct(V.CL_EN_GEN_ID)
--, V.ProgramID


FROM UV_Fidelity_aHVES V
INNER JOIN --- Limit to active clients during time frame with MIECHV funding
       (SELECT DISTINCT EAD.CLID,EAD.ProgramID
       FROM UV_EADT EAD
       JOIN UV_PAS P
              ON EAD.ProgramID = P.ProgramID
       JOIN DataWarehouse..Client_Funding_Survey CFS
              ON EAD.CLID = CFS.CL_EN_GEN_ID
              AND EAD.ProgramID = CFS.ProgramID
              AND (CFS.CLIENT_FUNDING_0_SOURCE_MIECHVP_COM IS NOT NULL OR CFS.CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM IS NOT NULL) ---Could add time frame requirements
       WHERE EAD.ProgramStartDate <= @End AND EAD.EndDate >=@Start
              AND P.ProgramID IN(SELECT * FROM dbo.udf_ParseMultiParam(@Team))) CLID
       ON V.CL_EN_GEN_ID = CLID.CLID
       AND V.ProgramID = CLID.ProgramID
       
inner join #Population on #Population.CL_EN_GEN_ID = V.CL_EN_GEN_ID and #Population.ProgramID = V.ProgramID

WHERE V.CLIENT_COMPLETE_0_VISIT = 'Completed' 
AND V.SurveyDate BETWEEN @Start AND @End

------------------------------------------------------------------------------------

Drop Table #Population
GO
