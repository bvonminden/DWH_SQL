USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_QrtlyRpt_DMH20]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_QrtlyRpt_DMH20] 

AS
BEGIN

---------------------------------------------------------------------------------
Select Staffid as 'Nurse', CLID as 'Client', ProgramID 
into #Populationprep
from dbo.StaffxClient
where Staffid in

(2844
,9985
,9571
,8965
,8966
,9979
,9935
,9931
,9878
,8814
,8916
,9553
,9958
,8692
,8691
,9500
,1533
,10054
,2855
,8690
,8812
,11652
,8813
,8694
,8810
,8809
,9572
,8811
,11266
,2841
,9988
)

Insert into #Populationprep
Select Staffid as 'Nurse', CLID as 'Client', ProgramID

From dbo.StaffxClientHx

where

StartDate >= '2011-01-01' and EndDate <= '2014-03-31'
and Staffid in

(2844
,9985
,9571
,8965
,8966
,9979
,9935
,9931
,9878
,8814
,8916
,9553
,9958
,8692
,8691
,9500
,1533
,10054
,2855
,8690
,8812
,11652
,8813
,8694
,8810
,8809
,9572
,8811
,11266
,2841
,9988)

Select

	Distinct(Client) as 'Client'
	, Nurse
	, ProgramID 
	
Into #Population

From

	#Populationprep
	
Group By

	ProgramID
	, Nurse
	, Client

----------------------------------------------------------------------------------
--Time Frame
------------
Declare @Start date
Declare @End Date
Set @Start = '2011-01-01'
Set @End = '2014-03-31'

----------------------------------------------------------------------------------
Declare	@Quarter INT
Declare	@QuarterYear INT
Declare @QuarterDate VARCHAR(50)

Set @Quarter = 1
Set @QuarterYear = 2011
 
SET @QuarterDate =	(
						CASE 
							WHEN @Quarter = 1 THEN '3/31/'+CAST(@QuarterYear AS VARCHAR(4)) 
							WHEN @Quarter = 2 THEN '6/30/'+CAST(@QuarterYear AS VARCHAR(4)) 
							WHEN @Quarter = 3 THEN '9/30/'+CAST(@QuarterYear AS VARCHAR(4)) 
							WHEN @Quarter = 4 THEN '12/31/'+CAST(@QuarterYear AS VARCHAR(4)) 
						END
					)
DECLARE @QuarterStart DATE SET @QuarterStart = DATEADD(DD,1,DATEADD(M,-3,CAST(@QuarterDate AS DATE))) 


SET QUOTED_IDENTIFIER ON

SET NOCOUNT ON;
WITH DATASET AS (
SELECT

	#Population.Nurse
	, EAD.ProgramID
	, EAD.CLID
	, EAD.CaseNumber
	, DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID) [State]
	, PAS.SITE [Site]
	, PAS.SiteID,MAX(CASE WHEN PAS.ProgramName LIKE '%BRONX%' AND A.State = 'NY' THEN 1 END) [VNS]
	, DataWarehouse.dbo.udf_fn_GetCleanProg(PAS.ProgramID) ProgramName

	, CASE
		WHEN MAX(
				CASE
					WHEN HHS.CLIENT_SUBSTANCE_ALCOHOL_0_14DAY IS NOT NULL
						AND DataWarehouse.dbo.fnGetFormName(HHS.SurveyID) LIKE '%36%'
					THEN 1 ELSE 0
				END) = 1
			AND MAX(
				CASE
					WHEN HHS.CLIENT_SUBSTANCE_ALCOHOL_0_14DAY IS NOT NULL
						AND DataWarehouse.dbo.fnGetFormName(HHS.SurveyID) LIKE '%INTAKE%'
					THEN 1 ELSE 0
				END) = 1
		THEN 1 ELSE 0
	END [Smoking Data Completed]
		
	, CASE
		WHEN MAX(
				CASE
					WHEN HHS.CLIENT_SUBSTANCE_ALCOHOL_0_14DAY IS NOT NULL
						AND DataWarehouse.dbo.fnGetFormName(HHS.SurveyID) LIKE '%36%'
					THEN 1 ELSE 0
				END) = 1
			AND MAX(
				CASE
					WHEN HHS.CLIENT_SUBSTANCE_ALCOHOL_0_14DAY IS NOT NULL
						AND DataWarehouse.dbo.fnGetFormName(HHS.SurveyID) LIKE '%INTAKE%'
					THEN 1 ELSE 0
				END) = 1
		THEN MAX( 
				CASE
					WHEN HHS.CLIENT_SUBSTANCE_ALCOHOL_0_14DAY > 0
						AND DataWarehouse.dbo.fnGetFormName(HHS.SurveyID) LIKE '%36%'
					THEN 1 ELSE 0
				END)
	END [Smoked in last 48 - 36 weeks]
	
	, CASE
		WHEN MAX(
				CASE
					WHEN HHS.CLIENT_SUBSTANCE_ALCOHOL_0_14DAY IS NOT NULL
						AND DataWarehouse.dbo.fnGetFormName(HHS.SurveyID) LIKE '%36%'
					THEN 1 ELSE 0
				END) = 1
			AND MAX(
				CASE
					WHEN HHS.CLIENT_SUBSTANCE_ALCOHOL_0_14DAY IS NOT NULL
						AND DataWarehouse.dbo.fnGetFormName(HHS.SurveyID) LIKE '%INTAKE%'
					THEN 1 ELSE 0
				END) = 1
		THEN MAX(
				CASE
					WHEN HHS.CLIENT_SUBSTANCE_ALCOHOL_0_14DAY > 0
						AND DataWarehouse.dbo.fnGetFormName(HHS.SurveyID) LIKE '%INTAKE%'
					THEN 1 ELSE 0
				END)
	END [Smoked in last 48 - Intake]

From
	
	DataWarehouse..Clients C
	INNER JOIN DataWarehouse..UV_EADT EAD
		ON EAD.CLID = C.Client_Id
		AND EAD.ProgramStartDate < = @End
		
		Inner Join #Population on #Population.Client = EAD.CLID and #Population.ProgramID = EAD.ProgramID

		INNER JOIN DataWarehouse..UV_PAS PAS
			ON PAS.ProgramID = EAD.ProgramID 
			
			INNER JOIN DataWarehouse..Agencies A
				ON A.Site_ID = PAS.SiteID

			INNER JOIN DataWarehouse..Health_Habits_Survey HHS
				ON HHS.CL_EN_GEN_ID = EAD.CLID
				AND HHS.SurveyDate < = @End
				AND HHS.ProgramID = EAD.ProgramID
				AND (DataWarehouse.dbo.fnGetFormName(HHS.SurveyID) LIKE '%36%'
						OR DataWarehouse.dbo.fnGetFormName(HHS.SurveyID) LIKE '%INTAKE%'
					)
		LEFT JOIN DataWarehouse..UC_Client_Exclusion_YWCA YWCA 
			ON YWCA.CLID = EAD.CLID AND EAD.SiteID = 222
      LEFT JOIN DataWarehouse..Tribal_Survey TS
            ON TS.CL_EN_GEN_ID = EAD.CLID
            AND TS.ProgramID = EAD.ProgramID

	WHERE
		YWCA.CLID IS NULL

	GROUP BY 
	
	#Population.Nurse
	, EAD.ProgramID
	, EAD.CLID
	, EAD.CaseNumber
	,DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID)
	,PAS.SITE 
	,PAS.SiteID
	,DataWarehouse.dbo.udf_fn_GetCleanProg(PAS.ProgramID) 


)

SELECT

	Nurse
	, ProgramID
	, CLID 
	, D.State
	, D.Site
	, D.SiteID,D.VNS
	, D.ProgramName
	, SUM(D.[Smoking Data Completed]) [Smoking Data Completed]
	, SUM(D.[Smoked in last 48 - 36 weeks]) [Smoked in last 48 - 36 weeks]
	, SUM(D.[Smoked in last 48 - Intake]) [Smoked in last 48 - Intake]

	
Into #TableAprep

From DATASET D

GROUP BY

	Nurse
	, ProgramID
	, CLID 
	, D.State
	, D.Site
	, D.SiteID,D.VNS
	, D.ProgramName
	
---------------------------------------------------------------------------------

Select 

	(Case
		When Nurse in (8966, 99791, 8965, 2844, 9985, 9571, 9979)
		then
		'1'
		When Nurse in (9931)
		then
		'3'
		When Nurse in (8810, 9572, 8809, 8694, 8813, 8812, 9988, 2841, 11266, 8811, 9935, 8690, 11652)
		then
		'4'
		When Nurse in (8916, 9958, 9553, 8814)
		then
		'6'
		When Nurse in (9878)
		then
		'7'
		When Nurse in (2855, 8692, 1533, 10054, 9500, 8691)
		then
		'8'
		else
		'0'
		end) as 'Spa'
	, (FName + ' ' + LName) as 'Name'
	, Nurse
	, #TableAprep.ProgramID
	, CLID	
	, State
	, UV_pas.Site
	, UV_pas.SiteID
	, VNS
	, UV_pas.ProgramName
	, [Smoking Data Completed]
	, [Smoked in last 48 - 36 weeks]
	, [Smoked in last 48 - Intake]

From

	#TableAprep
	left join UV_PAS on UV_pas.ProgramID = #TableAprep.ProgramID
	left join Staff on Staff.StaffID = #TableAprep.Nurse	
	

	
---------------------------------------------------------------------------------
Drop Table #Populationprep
Drop Table #Population
Drop Table #TableAprep

END
GO
