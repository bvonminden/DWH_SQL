USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_QrtlyRpt_DMHphq9]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_QrtlyRpt_DMHphq9] 

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




Set @Quarter = 1
Set @QuarterYear = 2011

DECLARE @QuarterDate VARCHAR(50) 
SET @QuarterDate =	'2014-03-31'

--(
--						CASE 
--							WHEN @Quarter = 1 THEN '3/31/'+CAST(@QuarterYear AS VARCHAR(4)) 
--							WHEN @Quarter = 2 THEN '6/30/'+CAST(@QuarterYear AS VARCHAR(4)) 
--							WHEN @Quarter = 3 THEN '9/30/'+CAST(@QuarterYear AS VARCHAR(4)) 
--							WHEN @Quarter = 4 THEN '12/31/'+CAST(@QuarterYear AS VARCHAR(4)) 
--						END
--					)
DECLARE @QuarterStart DATE

SET @QuarterStart = '2011-01-01' 

--DATEADD(DD,1,DATEADD(M,-3,CAST(@QuarterDate AS DATE))) 


Select

	#Population.Nurse
	,EAD.ProgramID
	,EAD.CLID
	,PHQ.SurveyResponseID


		,( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(PHQ.SurveyID) LIKE '%Preg%36%' THEN 1
					else 0
				END
			  ) [PHQ-9 Survey Taken at 36 Weeks]
		,( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND ((dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%1%8%' OR dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%1%4%') OR dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%1%4%') THEN 1
					else 0
				END
			  ) [PHQ-9 Survey Taken at Infancy 1-4 weeks]
		,( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%4%6%' THEN 1
					else 0
				END
			  ) [PHQ-9 Survey Taken at Infancy 4-6 mos]
		,( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%12%' THEN 1
					else 0
				END
			  ) [PHQ-9 Survey Taken at Infancy 12 mos]

		,( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(PHQ.SurveyID) LIKE '%Preg%36%' THEN PHQ.CLIENT_PHQ9_0_TOTAL_SCORE
					else 0
				END
			  ) [PHQ-9 Score at 36 Weeks]
		,( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND ((dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%1%8%' OR dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%1%4%') OR dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%1%4%') THEN PHQ.CLIENT_PHQ9_0_TOTAL_SCORE
					else 0
				END
			  ) [PHQ-9 Score at Infancy 1-4 weeks]
		,( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%4%6%' THEN PHQ.CLIENT_PHQ9_0_TOTAL_SCORE
					else 0
				END
			  ) [PHQ-9 Score at Infancy 4-6 mos]
		,( 
				CASE 
					WHEN PHQ.CL_EN_GEN_ID IS NOT NULL
						AND dbo.fngetFormName(PHQ.SurveyID) LIKE '%Inf%12%' THEN PHQ.CLIENT_PHQ9_0_TOTAL_SCORE
					else 0
				END
			  ) [PHQ-9 Score at Infancy 12 mos]
			  
into #TableAprep

			
	FROM DataWarehouse..EnrollmentAndDismissal EAD
	
	left outer Join #Population on #Population.Client = EAD.CLID and #Population.ProgramID = EAD.ProgramID
	
		--INNER JOIN [DataWarehouse].[dbo].[Client_Funding_Survey] CFS
		--	ON CFS.CL_EN_GEN_ID = EAD.CLID
		--	AND CFS.ProgramID = EAD.ProgramID
		--	AND (
		--			CFS.CLIENT_FUNDING_1_START_MIECHVP_COM BETWEEN '10/1/2010' AND @End
		--			OR CFS.CLIENT_FUNDING_1_START_MIECHVP_FORM BETWEEN '10/1/2010' AND @End
		--			OR CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL BETWEEN '10/1/2010' AND @End
		--		)	
	
		INNER JOIN DataWarehouse..Clients C
			ON C.Client_Id = EAD.CLID
			AND C.Last_Name <> 'Fake'

		--LEFT JOIN DataWarehouse..Maternal_Health_Survey MHS
		--	ON MHS.CL_EN_GEN_ID = EAD.CLID
		--	AND MHS.ProgramID = EAD.ProgramID
		--	AND MHS.SurveyDate < = @QuarterDate
		--LEFT JOIN DataWarehouse..Health_Habits_Survey HHS
		--	ON HHS.CL_EN_GEN_ID = EAD.CLID
		--	AND HHS.ProgramID = EAD.ProgramID
		--	AND HHS.SurveyDate < = @QuarterDate
		--LEFT JOIN DataWarehouse..Mstr_surveys MS_H
		--	ON MS_H.SurveyID = HHS.SurveyID
		--LEFT JOIN DataWarehouse..Govt_Comm_Srvcs_Survey GCSS
		--	ON GCSS.CL_EN_GEN_ID = EAD.CLID
		--	AND GCSS.ProgramID = EAD.ProgramID
		--	AND GCSS.SurveyDate < = @QuarterDate
		--LEFT JOIN DataWarehouse..Mstr_surveys MS_G
		--	ON MS_G.SurveyID = GCSS.SurveyID
		--LEFT JOIN DataWarehouse..Demographics_Survey DS
		--	ON DS.CL_EN_GEN_ID = EAD.CLID
		--	AND DS.ProgramID = EAD.ProgramID
		--	AND DS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate

		LEFT JOIN DataWarehouse..Edinburgh_Survey ES
			ON ES.CL_EN_GEN_ID = EAD.CLID
			AND ES.ProgramID = EAD.ProgramID
			AND ES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate

		LEFT JOIN DataWarehouse..Infant_Birth_Survey IBS
			ON IBS.CL_EN_GEN_ID = EAD.CLID
			AND IBS.ProgramID = EAD.ProgramID
			AND IBS.SurveyDate < = @QuarterDate
		LEFT JOIN DataWarehouse..Infant_Health_Survey IHS
			ON IHS.CL_EN_GEN_ID = EAD.CLID
			AND IHS.ProgramID = EAD.ProgramID
			AND IHS.SurveyDate < = @QuarterDate

		LEFT JOIN DataWarehouse..Infant_Health_Survey IHS2
			ON IHS2.CL_EN_GEN_ID = EAD.CLID
			AND IHS2.ProgramID = EAD.ProgramID
			AND IHS2.SurveyDate < = @QuarterDate
			AND IHS2.SurveyID IN (
									SELECT MS_IHS2.SurveyID
									FROM DataWarehouse..Mstr_surveys MS_IHS2
									WHERE MS_IHS2.SurveyName LIKE '%INFANT%6%'
								)
		LEFT JOIN DataWarehouse..PHQ_Survey PHQ
			ON PHQ.CL_EN_GEN_ID = EAD.CLID
			AND PHQ.ProgramID = EAD.ProgramID
			AND PHQ.SurveyDate BETWEEN @QuarterStart AND @QuarterDate

		INNER JOIN DataWarehouse..UV_PAS PAS
			ON PAS.ProgramID = EAD.ProgramID
			
		INNER JOIN DataWarehouse..Agencies A
			ON A.Site_ID = PAS.SiteID
		LEFT JOIN DataWarehouse..UV_EDD EDD
			ON EDD.CaseNumber = EAD.CaseNumber
		--LEFT JOIN DataWarehouse..Home_Visit_Encounter_Survey HVES
		--	ON HVES.CL_EN_GEN_ID = EAD.CLID
		--	AND HVES.SurveyDate BETWEEN @QuarterStart
		--	AND CASE
		--		WHEN IBS.INFANT_BIRTH_0_DOB > @QuarterDate
		--			THEN @QuarterDate
		--			ELSE IBS.INFANT_BIRTH_0_DOB
		--		END
				
	--where PHQ.SurveyResponseID = 6910743
																
	--GROUP BY
	
	--	#Population.Nurse
	--	,EAD.ProgramID
	--	,EAD.CLID
	--	,PHQ.SurveyResponseID
		--,EAD.CaseNumber
		--,PAS.ProgramName
		--,PAS.Site
		--,PAS.SiteID
		--,DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID)
		--,CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_COM]
		--,CFS.[CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM]
		--,CFS.[CLIENT_FUNDING_0_SOURCE_OTHER]
		--,CFS.[CLIENT_FUNDING_0_SOURCE_OTHER_TXT]
		--,CFS.[CLIENT_FUNDING_1_END_MIECHVP_COM]
		--,CFS.[CLIENT_FUNDING_1_END_MIECHVP_FORM]
		--,CFS.[CLIENT_FUNDING_1_END_OTHER]
		--,CFS.[CLIENT_FUNDING_1_START_MIECHVP_COM]
		--,CFS.[CLIENT_FUNDING_1_START_MIECHVP_FORM]
		--,CFS.[CLIENT_FUNDING_1_START_OTHER]
		--,MHS.CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE
		--,EDD.EDD
		--,DataWarehouse.dbo.udf_fnGestAgeEnroll(EAD.CLID)
		--,CFS.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL
		--,CFS.CLIENT_FUNDING_1_END_MIECHVP_TRIBAL
		





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
, [PHQ-9 Survey Taken at 36 Weeks]
, [PHQ-9 Survey Taken at Infancy 1-4 weeks]
, [PHQ-9 Survey Taken at Infancy 4-6 mos]
, [PHQ-9 Survey Taken at Infancy 12 mos]
, [PHQ-9 Score at 36 Weeks]
, [PHQ-9 Score at Infancy 1-4 weeks]
, [PHQ-9 Score at Infancy 4-6 mos]
, [PHQ-9 Score at Infancy 12 mos]


From #TableAprep
left join UV_PAS on UV_pas.ProgramID = #TableAprep.ProgramID
left join Staff on Staff.StaffID = #TableAprep.Nurse 
where nurse is not null


Drop Table #Populationprep
Drop Table #Population
Drop Table #TableAprep

end
GO
