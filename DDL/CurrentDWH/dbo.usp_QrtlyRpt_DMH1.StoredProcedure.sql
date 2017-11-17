USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_QrtlyRpt_DMH1]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_QrtlyRpt_DMH1] 

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
Set @QuarterDate =	(
						CASE 
							WHEN @Quarter = 1 THEN '3/31/'+CAST(@QuarterYear AS VARCHAR(4)) 
							WHEN @Quarter = 2 THEN '6/30/'+CAST(@QuarterYear AS VARCHAR(4)) 
							WHEN @Quarter = 3 THEN '9/30/'+CAST(@QuarterYear AS VARCHAR(4)) 
							WHEN @Quarter = 4 THEN '12/31/'+CAST(@QuarterYear AS VARCHAR(4)) 
						END
					)
DECLARE @QuarterStart DATE
SET @QuarterStart = DATEADD(DD,1,DATEADD(M,-3,CAST(@QuarterDate AS DATE))) 


SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON;
WITH HV2 AS
(
SELECT 
		H.CL_EN_GEN_ID
		,MAX(H.SurveyDate) LastVisit
		,MIN(H.SurveyDate) FirstVisit
		,H.ProgramID
	FROM DataWarehouse..UV_HVES H
	WHERE H.SurveyDate < = @End
	GROUP BY H.CL_EN_GEN_ID, H.ProgramID
)

SELECT 

	#Population.Nurse
	,EAD.ProgramID
	,EAD.CLID
	
	,COUNT(DISTINCT CASE
			WHEN EAD.RankingOrig = 1 
				AND EAD.ProgramStartDate BETWEEN @Start AND @End
			THEN EAD.CLID
		END) [New Clients Enrolled]
	
	,ISNULL(COUNT(DISTINCT
				CASE
					WHEN EAD.CLID <> EAD.CaseNumber
						AND EAD.RankingLatest = 1
						AND EAD.RankingOrig > 1
						AND EAD3.EndDate > = @Start
					THEN EAD.CLID
				END) 
		,0) [Clients Transferred In]
	
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN DATEDIFF(DD,EAD.ProgramStartDate,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) > 161
					AND MHS.SurveyDate BETWEEN @Start AND @End
					AND EAD.ProgramStartDate BETWEEN @Start AND @End	
				THEN EAD.CLID
			END
		),0) [Enrolled by 16 Weeks Gestation]
	
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN IBS.INFANT_BIRTH_0_DOB BETWEEN @Start AND @End
					AND EAD.RankingLatest = 1
				THEN EAD.CLID
			END
		),0) + ISNULL(COUNT(DISTINCT CASE
						WHEN IBS.INFANT_BIRTH_0_DOB BETWEEN @Start AND @End
							AND IBS.INFANT_0_ID_NSO2 IS NOT NULL
							AND EAD.RankingLatest = 1
						THEN EAD.CLID
					  END
					),0) + ISNULL(COUNT(DISTINCT CASE
									WHEN IBS.INFANT_BIRTH_0_DOB BETWEEN @Start AND @End
										AND IBS.INFANT_0_ID_NSO3 IS NOT NULL
										AND EAD.RankingLatest = 1
									THEN EAD.CLID
								  END
								),0) [Babies Born]
	
	,COUNT(DISTINCT
				CASE
					WHEN DataWarehouse.dbo.udf_ClientGraduated(@QuarterDate,EAD.CLID) = 1
					THEN EAD.CLID
				END) [Clients Graduated]
	
	,COUNT(DISTINCT 
				CASE 
					WHEN EAD.CLID = EAD.CaseNumber
						AND EAD.CLID <> EAD2.CLID
						AND EAD.RankingOrig = 1
						AND EAD.RankingLatest > 1
						AND EAD.ProgramID <> EAD2.ProgramID
						AND EAD.EndDate BETWEEN @Start AND @End
					THEN EAD.CLID 
				END) [Clients Transferred Out]
	
	,ISNULL(COUNT(DISTINCT
					CASE
					WHEN (EAD.EndDate BETWEEN @Start AND @End
						AND	EAD.ReasonForDismissal NOT LIKE '%2%' )
						OR	((DATEDIFF(DAY,EDD.EDD,EAD.EndDate)) < 700
							AND	(EAD.ReasonForDismissal IS NULL
								AND DATEDIFF(DAY,(HVES.SurveyDate),@QuarterDate) > 180))
						THEN EAD.CLID
					END
				),0)  [Clients Who Left Early]
	
	,ISNULL(COUNT(DISTINCT
					CASE
					WHEN HVES.SurveyDate BETWEEN @Start AND @End
					THEN EAD.CLID
					END
				),0) [Clients Served]
							
	,ISNULL(COUNT(DISTINCT CASE
					WHEN IBS.INFANT_BIRTH_0_DOB IS NOT NULL
						AND HVES.SurveyDate BETWEEN @Start AND @End
					THEN EAD.CLID
					END
				),0) + ISNULL(COUNT(DISTINCT CASE
						WHEN IBS.INFANT_BIRTH_0_DOB IS NOT NULL
							AND IBS.INFANT_0_ID_NSO2 IS NOT NULL
							AND HVES.SurveyDate BETWEEN @Start AND @End
						THEN EAD.CLID
					  END
					),0) + ISNULL(COUNT(DISTINCT CASE
									WHEN IBS.INFANT_BIRTH_0_DOB IS NOT NULL
										AND IBS.INFANT_0_ID_NSO3 IS NOT NULL
										AND HVES.SurveyDate BETWEEN @Start AND @End
									THEN EAD.CLID
								  END
								),0) [Babies Served]
	
	,ISNULL(COUNT(DISTINCT 
				CASE WHEN AC.ProgramStartDate < = @End
						AND AC.EndDate > @QuarterDate
						AND EAD.RankingLatest = 1
					THEN AC.CLID
					END),0) [Active Clients at the End of the Quarter]
	
	,ISNULL(SUM(
					CASE
						WHEN	(
									EDD.EDD IS NULL 
									OR EDD.EDD > HVES.SurveyDate
								)

							AND HVES.CLIENT_COMPLETE_0_VISIT = 'Completed'
							AND HVES.SurveyDate BETWEEN @Start AND @End
							AND HVES.Form = 'Home Visit'
						THEN 1
					END
				),0) [Visits During Pregnancy]
	
	,ISNULL(SUM(
					CASE
						WHEN DATEDIFF(DAY,EDD.EDD,HVES.SurveyDate) BETWEEN 0 AND 365.25
							AND HVES.CLIENT_COMPLETE_0_VISIT = 'Completed'
							AND HVES.SurveyDate BETWEEN @Start AND @End
							AND HVES.Form = 'Home Visit'
							AND EDD.EDD IS NOT NULL
							AND HVES.SurveyDate >= EDD.EDD
						THEN 1
					END
				),0) [Visits During Infancy]
	
	,ISNULL(SUM(
					CASE
						WHEN DATEDIFF(DAY,EDD.EDD,HVES.SurveyDate) >= 365.25
							AND HVES.CLIENT_COMPLETE_0_VISIT = 'Completed'
							AND HVES.SurveyDate BETWEEN @Start AND @End
							AND HVES.Form = 'Home Visit'
							AND EDD.EDD IS NOT NULL
							AND HVES.SurveyDate > EDD.EDD

						THEN 1
					END
				),0) [Visits During Toddlerhood]
				
into #TableAprep

FROM DataWarehouse..UV_EADT EAD

	Inner Join #Population on #Population.Client = EAD.CLID and #Population.ProgramID = EAD.ProgramID
	
	INNER JOIN DataWarehouse..UV_EADT EAD2
		ON EAD2.CaseNumber = EAD.CaseNumber
		AND EAD2.RankingLatest = 1
		AND EAD2.ProgramStartDate < = @End 
	LEFT JOIN DataWarehouse..UV_EADT EAD3
		ON EAD3.CaseNumber = EAD.CaseNumber
		AND EAD3.RankingLatest > 1
		AND EAD3.EndDate BETWEEN @Start AND @End 
	INNER JOIN DataWarehouse..UV_EADT E2
		ON E2.CaseNumber = EAD.CaseNumber
		AND E2.RankingOrig = 1
		
	INNER JOIN DataWarehouse..UV_PAS PAS
		ON PAS.ProgramID = EAD.ProgramID 
		
	INNER JOIN DataWarehouse..Agencies A
		ON A.Site_ID = PAS.SiteID
		
	LEFT JOIN DataWarehouse..Maternal_Health_Survey MHS
		ON MHS.CL_EN_GEN_ID = EAD.CLID
		AND MHS.SurveyDate < = @End
	LEFT JOIN DataWarehouse..Infant_Birth_Survey IBS
		ON IBS.CL_EN_GEN_ID = EAD.CLID
		AND IBS.SurveyDate < = @End
	LEFT JOIN DataWarehouse..UV_HVES HVES
		ON HVES.CL_EN_GEN_ID = EAD.CLID
		AND HVES.SurveyDate < = @End
	LEFT JOIN DataWarehouse..UV_EDD EDD
		ON EDD.CaseNumber = EAD.CaseNumber	
	LEFT JOIN HV2
		ON HV2.CL_EN_GEN_ID = EAD.CLID
		AND HV2.ProgramID = EAD.ProgramID
	LEFT JOIN DataWarehouse..UC_Client_Exclusion_YWCA YWCA 
		ON YWCA.CLID = EAD.CLID AND PAS.SiteID = 222
	LEFT JOIN DataWarehouse..Tribal_Survey TS
		ON TS.CL_EN_GEN_ID = EAD.CLID
		AND TS.ProgramID = EAD.ProgramID
	LEFT JOIN DataWarehouse..AC_Dates AC
		ON AC.CLID = EAD.CLID 
		AND AC.ProgramID = EAD.ProgramID
WHERE

	YWCA.CLID IS NULL
	AND ISNULL(EAD.EndDate,GETDATE()) > @Start
	AND EAD.ProgramStartDate < = @End 
	
GROUP BY
 
	#Population.Nurse
	,EAD.ProgramID
	,EAD.CLID

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
, [New Clients Enrolled]
, [Clients Transferred In]
, [Enrolled by 16 Weeks Gestation]
, [Babies Born]
, [Clients Graduated]
, [Clients Transferred Out]
, [Clients Who Left Early]
, [Clients Served]			
, [Babies Served]
, [Active Clients at the End of the Quarter]
, [Visits During Pregnancy]
, [Visits During Infancy]
, [Visits During Toddlerhood] 

From #TableAprep
left join UV_PAS on UV_pas.ProgramID = #TableAprep.ProgramID
left join Staff on Staff.StaffID = #TableAprep.Nurse 


Drop Table #Populationprep
Drop Table #Population
Drop Table #TableAprep

End




GO
