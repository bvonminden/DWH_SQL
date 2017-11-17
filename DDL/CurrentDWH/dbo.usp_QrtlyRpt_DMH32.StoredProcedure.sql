USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_QrtlyRpt_DMH32]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_QrtlyRpt_DMH32] 

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


SELECT 
	
	#Population.Nurse
	,EAD.ProgramID
	,EAD.CLID
	
	, DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID) [State]
	,PAS.SITE [Site]
	,PAS.SiteID,MAX(CASE WHEN PAS.ProgramName LIKE '%BRONX%' AND A.State = 'NY' THEN 1 END) [VNS]
	,DataWarehouse.dbo.udf_fn_GetCleanProg(PAS.ProgramID) ProgramName

	,COUNT(DISTINCT
			CASE
				WHEN DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%'
				THEN C.Client_ID
			END) [Number of Clients Intake]
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND (
							DIN.CLIENT_SCHOOL_MIDDLE_HS = 'Not enrolled'
							OR DIN.CLIENT_EDUCATION_1_ENROLLED_TYPE NOT IN ('College','High school or GED program','Middle school (6th - 7th & 8th grades)','Post-high school vocational/technical training program')
						)
				THEN C.Client_ID
			END) [No Diploma Not in School Intake]
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND (
							DIN.CLIENT_SCHOOL_MIDDLE_HS <> 'Not enrolled'
							OR DIN.CLIENT_EDUCATION_1_ENROLLED_TYPE IN ('College','High school or GED program','Middle school (6th - 7th & 8th grades)','Post-high school vocational/technical training program')
						)
				THEN C.Client_ID
			END) [No Diploma In School Intake]		
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND (
							DIN.CLIENT_SCHOOL_MIDDLE_HS IS NULL
							AND DIN.CLIENT_EDUCATION_1_ENROLLED_TYPE IS NULL
						)
				THEN C.Client_ID
			END) [No Diploma Missing Intake]	

,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND D6.CLIENT_EDUCATION_0_HS_GED IS NOT NULL
				THEN C.Client_ID
			END) [Number of Clients 6 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND ((D6.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR D6.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND (
							D6.CLIENT_SCHOOL_MIDDLE_HS = 'Not enrolled'
							OR D6.CLIENT_EDUCATION_1_ENROLLED_TYPE NOT IN ('College','High school or GED program','Middle school (6th - 7th & 8th grades)','Post-high school vocational/technical training program')
						))
				THEN C.Client_ID
			END) [No Diploma Not in School 6 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND ((D6.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR D6.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
						AND (
								D6.CLIENT_SCHOOL_MIDDLE_HS <> 'Not enrolled'
								OR D6.CLIENT_EDUCATION_1_ENROLLED_TYPE IN ('College','High school or GED program','Middle school (6th - 7th & 8th grades)','Post-high school vocational/technical training program')
							))
				THEN C.Client_ID
			END) [No Diploma In School 6 Mos]		
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND ((D6.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR D6.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
						AND (
								D6.CLIENT_SCHOOL_MIDDLE_HS IS NULL
								AND D6.CLIENT_EDUCATION_1_ENROLLED_TYPE IS NULL
							))
				THEN C.Client_ID
			END) [No Diploma Missing 6 Mos]
			
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND D6.CLIENT_EDUCATION_1_ENROLLED_CURRENT = 'NO'
					AND (D6.CLIENT_EDUCATION_0_HS_GED LIKE '%YES%' AND D6.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%VOCATION%')
				THEN C.Client_ID
			END) [Completed Diploma Not in School 6 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND D6.CLIENT_EDUCATION_1_ENROLLED_CURRENT <> 'NO'
					AND (D6.CLIENT_EDUCATION_0_HS_GED LIKE '%YES%' AND D6.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%VOCATION%')
				THEN C.Client_ID
			END) [Completed Diploma In School 6 Mos]		
	,COUNT(DISTINCT
			CASE
				WHEN (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%' OR DIN.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCATION%')
					AND D6.CLIENT_EDUCATION_1_ENROLLED_CURRENT IS NULL
					AND (D6.CLIENT_EDUCATION_0_HS_GED LIKE '%YES%' AND D6.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%VOCATION%')
				THEN C.Client_ID
			END) [Completed Diploma Missing 6 Mos]

	
Into #TableAprep

FROM DataWarehouse..Clients C

	INNER JOIN DataWarehouse..UV_EADT EAD
		ON EAD.CLID = C.Client_Id
		AND EAD.ProgramStartDate < = @End 
		
	Inner Join #Population on #Population.Client = EAD.CLID and #Population.ProgramID = EAD.ProgramID	
		
	INNER JOIN DataWarehouse..UV_PAS PAS
		ON PAS.ProgramID = EAD.ProgramID 
		
		INNER JOIN DataWarehouse..Agencies A
			ON A.Site_ID = PAS.SiteID
	LEFT JOIN DataWarehouse..Demographics_Survey DIN
		ON DIN.CL_EN_GEN_ID = EAD.CLID
		AND DIN.ProgramID = EAD.ProgramID
		AND DIN.SurveyDate < = @End
		AND DataWarehouse.dbo.fnGetFormName(DIN.SurveyID) LIKE '%DEMOGRAP%INTAKE%'
	LEFT JOIN DataWarehouse..Demographics_Survey D6
		ON D6.CL_EN_GEN_ID = EAD.CLID
		AND D6.ProgramID = EAD.ProgramID
		AND D6.SurveyDate < = @End
		AND DataWarehouse.dbo.fnGetFormName(D6.SurveyID) LIKE '%DEMOGRAP%6%'
	LEFT JOIN DataWarehouse..UC_Client_Exclusion_YWCA YWCA 
		ON YWCA.CLID = EAD.CLID AND EAD.SiteID = 222
	LEFT JOIN DataWarehouse..Tribal_Survey TS
            ON TS.CL_EN_GEN_ID = EAD.CLID
            AND TS.ProgramID = EAD.ProgramID
WHERE
	YWCA.CLID IS NULL
	AND  EAD.ProgramStartDate < = @End	
	AND (DIN.CLIENT_EDUCATION_0_HS_GED NOT LIKE '%YES%'
		OR D6.CLIENT_EDUCATION_0_HS_GED IS NOT NULL)

GROUP BY

	#Population.Nurse
	,EAD.ProgramID
	,EAD.CLID 
	, DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID)
	,PAS.SITE 
	,PAS.SiteID
	,DataWarehouse.dbo.udf_fn_GetCleanProg(PAS.ProgramID) 

----------------------------------------------------------------------------------------------

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
, [State]
, [VNS]
, [Number of Clients Intake]
, [No Diploma Not in School Intake]
, [No Diploma In School Intake]		
, [No Diploma Missing Intake]	
, [Number of Clients 6 Mos]
, [No Diploma Not in School 6 Mos]
, [No Diploma In School 6 Mos]		
, [No Diploma Missing 6 Mos]
, [Completed Diploma Not in School 6 Mos]
, [Completed Diploma In School 6 Mos]		
, [Completed Diploma Missing 6 Mos]

From #TableAprep
left join UV_PAS on UV_pas.ProgramID = #TableAprep.ProgramID
left join Staff on Staff.StaffID = #TableAprep.Nurse 


Drop Table #Populationprep
Drop Table #Population
Drop Table #TableAprep

End




GO
