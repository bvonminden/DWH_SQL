USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_HRSA_MIECHV_Summary_Chart1]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_HRSA_MIECHV_Summary_Chart1]
(@StartDate DATE
 ,@EndDate Date
 ,@FundingType VARCHAR(MAX)
 ,@Teams VARCHAR(MAX)
 ,@NHV VARCHAR(MAX))  
 AS

-------------------------------------------------------------------------------------------------
------for testing

--DECLARE @StartDate date			SET @StartDate = '10/1/2013'
--DECLARE @EndDate date				SET @EndDate = '9/30/2014'

----DECLARE @FundingType VARCHAR(MAX)	SET @FundingType = '1'	----Competitive
----DECLARE @FundingType VARCHAR(MAX)	SET @FundingType = '2'	----Formula
----DECLARE @FundingType VARCHAR(MAX)	SET @FundingType = '3'	----Tribal
--DECLARE @FundingType VARCHAR(MAX)	SET @FundingType = '1,2,3'	----all 3

--Colorado Teams
--SET @Teams = '1576,971,974,977,983,980,986,989,992,995,998,1887,1001,1004,1007,1010,2010,1013,854,857,1988,860,863,866,1943,869,1922,1925'

--California Teams
--SET @Teams =  '1535,1557,1554,1394,1820,1617,1397,1755,818,824,1773,1400,1668,1620,1770,965,968,836,1388,1391,839,884,887,842,827,821,1764,962,1779,848,1767,830,845,1752,833,1712,815,1744,1404,851'

--California NHV
--SET @NHV = '-1,19107,20810,20808,19251,20809,18827,20697,19000,20794,27252,18869,20378,7505,7497,24821,24924,20920,6393,21141,23622,21797,25727,22704,21343,25637,26301,22282,27157,7436,7986,25307,24822,7658,7122,6397,26862,22705,25359,22272,8631,7880,18634,7984,8114,11723,8785,6981,20797,7836,26927,21486,7097,6985,8780,25203,7660,24788,22134,23789,23628,22281,7993,21688,26093,9310,21371,6996,24537,22866,20362,6975,7455,21532,21793,8414,21344,21121,7990,7839,21485,6338,20667,21316,7094,19230,21802,9323,7894,20017,25299,18868,18638,13846,8116,23004,6395,25082,21480,22430,9322,8788,22129,8641,9319,14108,24787,26280,7982,21250,7071,24417,18872,9321,10000443,26914,7299,8632,7305,7080,21402,27156,21145,24679,7668,18828,20386,20407,22943,19130,26251,21401,8653,27155,26767,25384,8654,9317,24406,7484,7495,8650,21366,13569,21687,23673,20647,23002,6385,7124,26926,26148,22255,21400,7112,21674,6991,21663,24453,8118,20986,8782,9324,22526,25624,18871,21800,7068,26616,14106,7988,10000438,7844,21745,26365,19229,25864,21079,7066,26691,21367,9311,26340,22241,9314,7662,22310,22273,7432,21152,14187,27028,20948,19778,7107,22286,8655,7073,6973,26011,25833,7430,20988,9329,20312,26794,9320,9325,9328,18633,24637,27258,18632,6968,27228,26179,13964,21144,24445,20491,22305,21961,7301,7656,20161,21673,20985,22326,21382,19274,8422,21431,22047,7332,19573,21383,20003,20921,6381,19235,20385,8648,21264,7499,21341,9312,8002,7329,21792,21932,14268,9313,25741,8009,20987,20698,24196,21868,26915,25256,21345,24178,20955,26755,8651,21479,24011,22130,21686,22333,18873,20298,9318,6342,24760,23971,22706,7886,22271,14032,26391,9326'


------------===========================================================================================
----CTEs
;WITH StfToClientByEndDate AS
(	SELECT StaffID, CLID, ProgramID, EndDate, EntityID 
		,RANK() OVER(PARTITION BY CLID, ProgramID ORDER BY EndDate DESC) Ranking
	FROM 
	(	----staff to client records, current and history
		SELECT StaffID, CLID, ProgramID, NULL EndDate, Entity_Id EntityID FROM StaffxClient
		UNION ALL
		SELECT StaffID, CLID, ProgramID, EndDate, Entity_Id EntityID FROM StaffxClientHx
	)sxc
	WHERE ISNULL( sxc.EndDate, DATEADD(DAY,1,@EndDate) ) >= @StartDate
)
--===========================================================================================
,DemographicsSurvey AS
(	SELECT MAX(SurveyResponseID) latestSurveyResponseID, CL_EN_GEN_ID CLID, ProgramID 
	FROM Demographics_Survey 
	WHERE SurveyDate < @EndDate
		AND (DataWarehouse.dbo.fnGetFormName(SurveyID) = 'Demographics: Pregnancy Intake'
			OR DataWarehouse.dbo.fnGetFormName(SurveyID) = 'Demographics Update: Infancy 12 Months'
			OR DataWarehouse.dbo.fnGetFormName(SurveyID) = 'Demographics Update: Toddler 24 Months')
	GROUP BY CL_EN_GEN_ID, ProgramID 
)
--===========================================================================================
,GovtCommSrvcsSurvey_child AS
(	SELECT MAX(SurveyResponseID) latestSurveyResponseID, CL_EN_GEN_ID CLID, ProgramID 
	FROM Govt_Comm_Srvcs_Survey ----do not filter surveys by date, per Kyla Krause 9/11/2014
	WHERE (DataWarehouse.dbo.fnGetFormName(SurveyID) = 'Use of Government & Community Services-Birth'			----used for child
			OR DataWarehouse.dbo.fnGetFormName(SurveyID) = 'Use of Government & Community Services-Infancy 12'	----child & client
			OR DataWarehouse.dbo.fnGetFormName(SurveyID) = 'Use of Government & Community Services-Toddler 24')	----child & client
	GROUP BY CL_EN_GEN_ID, ProgramID 
)	
,GovtCommSrvcsSurvey_client AS
(	SELECT MAX(SurveyResponseID) latestSurveyResponseID, CL_EN_GEN_ID CLID, ProgramID 
	FROM Govt_Comm_Srvcs_Survey ----do not filter surveys by date, per Kyla Krause 9/11/2014
	WHERE (DataWarehouse.dbo.fnGetFormName(SurveyID) = 'Use of Government & Community Services-Intake'			----used for client
			OR DataWarehouse.dbo.fnGetFormName(SurveyID) = 'Use of Government & Community Services-Infancy 12'	----child & client
			OR DataWarehouse.dbo.fnGetFormName(SurveyID) = 'Use of Government & Community Services-Toddler 24')	----child & client
	GROUP BY CL_EN_GEN_ID, ProgramID 
)
----===========================================================================================

SELECT DISTINCT
	PAS.AGENCY_INFO_0_NAME SiteName
	,PAS.SiteID [Agencies Site_ID]
	,PAS.[StateID] [State]
	,PAS.Abbreviation
	,EAD.CLID
	,EAD.ProgramID
	,EAD.ProgramStartDate

---------------------------------------------
---Newly Enrolled and Served
---------------------------------------------
	,hm.[Newly Enrolled MIECHV During Reporting Period]
	,hm.[MIECHV Served During Reporting Period]
	,hm.[MIECHV Infants Born During Reporting Period]
	,hm.[MIECHV Infants Served During Reporting Period]
	,hm.INFANT_BIRTH_0_DOB
	,hm.[Pregnant during reporting period]
	,hm.HVESSurveyDateYear
	,hm.ReportingYear	
	
---------------------------------------------
----Enrollees and Children: Insurance Status
---------------------------------------------	
	
	----Unknown Insurance
	,CASE WHEN GCClient.CL_EN_GEN_ID IS NULL 
				THEN 1 ELSE 0 
	END [Client Insurance - Unknown]	
	,CASE WHEN GCChild.CL_EN_GEN_ID IS NULL 
			AND hm.INFANT_BIRTH_0_DOB <= @EndDate 
				THEN 1 ELSE 0 
	END [Child Insurance - Unknown]	

	----No Insurance	   
	,CASE WHEN (GCClient.SERVICE_USE_0_MEDICAID_CLIENT NOT IN (2,5) OR GCClient.SERVICE_USE_0_MEDICAID_CLIENT IS NULL)
				AND (GCClient.SERVICE_USE_0_SCHIP_CLIENT NOT IN (2,5) OR GCClient.SERVICE_USE_0_SCHIP_CLIENT IS NULL)
				AND (GCClient.[SERVICE_USE_MILITARY_INS_CLIENT ] NOT IN (2,5) OR GCClient.[SERVICE_USE_MILITARY_INS_CLIENT ] IS NULL)
				AND (GCClient.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT NOT IN (2,5) OR GCClient.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IS NULL)
				AND GCClient.CL_EN_GEN_ID IS NOT NULL
					THEN 1 ELSE 0
	END [Client Insurance - None]	
	,CASE WHEN (GCChild.SERVICE_USE_0_MEDICAID_CHILD NOT IN (2,5) OR GCChild.SERVICE_USE_0_MEDICAID_CHILD IS NULL)
				AND (GCChild.SERVICE_USE_0_SCHIP_CHILD NOT IN (2,5) OR GCChild.SERVICE_USE_0_SCHIP_CHILD IS NULL)
				AND (GCChild.[SERVICE_USE_MILITARY_INS_CHILD] NOT IN (2,5) OR GCChild.[SERVICE_USE_MILITARY_INS_CHILD] IS NULL)
				AND (GCChild.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD NOT IN (2,5) OR GCChild.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD IS NULL)
				AND GCChild.CL_EN_GEN_ID IS NOT NULL
				AND hm.INFANT_BIRTH_0_DOB <= @EndDate
					THEN 1 ELSE 0 
	END [Child Insurance - None]
	
	----Medicaid	  		
	,CASE WHEN GCClient.SERVICE_USE_0_MEDICAID_CLIENT IN (2,5) 
				OR GCClient.SERVICE_USE_0_SCHIP_CLIENT IN (2,5) 
					THEN 1 ELSE 0 
	END [Medicaid Client]	
	,CASE WHEN (GCChild.SERVICE_USE_0_MEDICAID_CHILD IN (2,5) 
				OR GCChild.SERVICE_USE_0_SCHIP_CHILD IN (2,5)) 
				AND hm.INFANT_BIRTH_0_DOB <= @EndDate 
					THEN 1 ELSE 0 
	END [Medicaid Child]		
	
	----Private Insurance 
	,CASE WHEN GCClient.SERVICE_USE_0_PRIVATE_INSURANCE_CLIENT IN (2,5) 
					THEN 1 ELSE 0 
	END [Private Client]	
	,CASE WHEN (GCChild.SERVICE_USE_0_PRIVATE_INSURANCE_CHILD IN (2,5)) 
				AND hm.INFANT_BIRTH_0_DOB <= @EndDate 
					THEN 1 ELSE 0 
	END [Private Child]	
	
	----Military Insurance
	,CASE WHEN GCClient.[SERVICE_USE_MILITARY_INS_CLIENT ] IN (2,5) 
				THEN 1 ELSE 0 
	END [Military Client]	
	,CASE WHEN GCChild.SERVICE_USE_MILITARY_INS_CHILD IN (2,5) 
				AND hm.INFANT_BIRTH_0_DOB <= @EndDate 
					THEN 1 ELSE 0 
	END [Military Child]
	
---------------------------------------------------
----Selected Characteristics by Ethnicity and Race
---------------------------------------------------
	----Client Marital Status
	,ISNULL(DD.CLIENT_MARITAL_0_STATUS,'Unknown') CLIENT_MARITAL_0_STATUS
	
	----Education Level
	,CASE
			WHEN DD.CLIENT_SCHOOL_MIDDLE_HS = 'Yes - high school or GED program (includes alternative and technical programs)'
				OR (DD.CLIENT_EDUCATION_0_HS_GED LIKE '%NO%' 
					AND DD.CLIENT_EDUCATION_1_ENROLLED_CURRENT = 'YES')
						THEN 'Currently enrolled in high school'
			WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 4748.25 AND 6939.75
				AND (DD.CLIENT_EDUCATION_1_ENROLLED_CURRENT LIKE '%NO%' 
					OR DD.CLIENT_SCHOOL_MIDDLE_HS LIKE '%NOT%')
						THEN 'Of high school age, not enrolled'
			WHEN (DD.CLIENT_EDUCATION_0_HS_GED LIKE '%NO%' 
					AND (DD.CLIENT_EDUCATION_1_ENROLLED_CURRENT LIKE '%NO%' 
						OR DD.CLIENT_SCHOOL_MIDDLE_HS LIKE '%NOT%'))
				AND (DD.CLIENT_SCHOOL_MIDDLE_HS <>'Yes - high school or GED program (includes alternative and technical programs)'
					OR DD.CLIENT_SCHOOL_MIDDLE_HS LIKE '%MIDDLE%')
						THEN 'Less than HS diploma'
			WHEN DD.CLIENT_EDUCATION_0_HS_GED LIKE '%GED%'
					THEN 'GED'
			WHEN DD.CLIENT_EDUCATION_0_HS_GED LIKE '%HIGH%'
					THEN 'HS diploma'
			WHEN DD.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%SOME COLLEGE%'
					THEN 'Some college/training'
			WHEN DD.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%ASSOC%'
				OR DD.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCA%'
				OR DD.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%VOCA%'
					THEN 'Technical Training Certification, Associate''s Degree'
			WHEN DD.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%BACH%'
				OR DD.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%MAST%'
				OR DD.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%DOCT%'
					THEN 'Bachelor''s Degree, or higher'
			ELSE 'Unknown/Did Not Report'
	END [Education Level]  	
	,CASE
		WHEN DD.CLIENT_SCHOOL_MIDDLE_HS = 'Yes - high school or GED program (includes alternative and technical programs)'
		OR (DD.CLIENT_EDUCATION_0_HS_GED LIKE '%NO%' 
			AND DD.CLIENT_EDUCATION_1_ENROLLED_CURRENT = 'YES')
				THEN 1
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 4748.25 AND 6939.75
		AND (DD.CLIENT_EDUCATION_1_ENROLLED_CURRENT LIKE '%NO%' 
			OR DD.CLIENT_SCHOOL_MIDDLE_HS LIKE '%NOT%')
				THEN 2
		WHEN (DD.CLIENT_EDUCATION_0_HS_GED LIKE '%NO%' 
		AND (DD.CLIENT_EDUCATION_1_ENROLLED_CURRENT LIKE '%NO%' 
			OR DD.CLIENT_SCHOOL_MIDDLE_HS LIKE '%NOT%'))
				THEN 3
		WHEN DD.CLIENT_EDUCATION_0_HS_GED LIKE '%GED%'
			THEN 4
		WHEN DD.CLIENT_EDUCATION_0_HS_GED LIKE '%HIGH%'
			THEN 5
		WHEN DD.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%SOME COLLEGE%'
			THEN 6
		WHEN DD.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%ASSOC%'
			OR DD.CLIENT_EDUCATION_0_HS_GED LIKE '%VOCA%'
			OR DD.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%VOCA%'
				THEN 7
		WHEN DD.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%BACH%'
			OR DD.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%MAST%'
			OR DD.CLIENT_EDUCATION_1_HIGHER_EDUC_COMP LIKE '%DOCT%'
				THEN 8
		ELSE 10
	END [Education Level Sorting]
	
	--Client Age
	,CASE
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 0 AND 3652.49 THEN 'Under 10'
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 3652.5 AND 5478.74 THEN '10-14' 
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 5478.75 AND 6574.49 THEN '15-17'
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 6574.5 AND 7304.99 THEN '18-19'
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 7305 AND 8035.49 THEN '20-21'
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 8035.5 AND 9131.24 THEN '22-24'
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 9131.25 AND 10957.49 THEN '25-29'
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 10957.5 AND 12783.74 THEN '30-34'
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 12783.75 AND 16436.24 THEN '35-44'
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 16436.25 AND 20088.74 THEN '45-54'
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 20088.75 AND 23741.24 THEN '55-64'
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) >= 23741.25 THEN '65+'
		ELSE 'Unknown/Did Not Report'
	 END [Clients Age]
	,CASE
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 0 AND 3652.49 THEN 1
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 3652.5 AND 5478.74 THEN 2
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 5478.75 AND 6574.49 THEN 3
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 6574.5 AND 7304.99 THEN 4
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 7305 AND 8035.49 THEN 5
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 8035.5 AND 9131.24 THEN 6
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 9131.25 AND 10957.49 THEN 7
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 10957.5 AND 12783.74 THEN 8
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 12783.75 AND 16436.24 THEN 9
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 16436.25 AND 20088.74 THEN 10
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) BETWEEN 20088.75 AND 23741.24 THEN 11
		WHEN DATEDIFF(DAY,C.DOB,EAD.ProgramStartDate) >= 23741.25 THEN 12
		ELSE 13
	 END [Clients Age Sorting] 
	 
	 ----Child Age
	,CASE
		WHEN hm.[MIECHV Infants Served During Reporting Period] = 1 
			AND hm.[Child Age at End of Quarter] < 1 
				THEN 'Under 1 year' 
		WHEN hm.[MIECHV Infants Served During Reporting Period] = 1 
			AND hm.[Child Age at End of Quarter] BETWEEN 1 AND 2 
				THEN '1-2 years'
		WHEN hm.[MIECHV Infants Served During Reporting Period] = 1 
			AND hm.[Child Age at End of Quarter] > 2 
				THEN 'Over 2 years' 
		WHEN hm.[MIECHV Infants Served During Reporting Period] = 1 
			AND hm.[Child Age at End of Quarter] IS NULL
				THEN 'Unknown' 
	END	[Child Age at End of Quarter]
	
	----Child Gender	
   ,IsNull(hm.INFANT_PERSONAL_0_GENDER, 'Unknown') INFANT_PERSONAL_0_GENDER
   	
	----Ethnicity
	,CASE WHEN hm.[Home visits during reporting period] >= 1 
		THEN 
			CASE 
				WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY = 'Hispanic or Latina'
					THEN 1 ELSE 0 
		   END 
	END [Hispanic or Latino]
	,CASE WHEN hm.[Home visits during reporting period] >= 1 
		THEN 
			CASE 
				WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY = 'Not Hispanic or Latina'
					THEN 1 ELSE 0 
		   END 
	END [Not Hispanic or Latino]
	,CASE WHEN hm.[Home visits during reporting period] >= 1 
		THEN 
			CASE 
				WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY ='Declined to self-identify'
					THEN 1 ELSE 0 
		   END 
	END [Declined Ethnicity]
	,CASE WHEN hm.[Home visits during reporting period] >= 1 
		THEN 
			CASE 
				WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY IS NULL
					THEN 1 ELSE 0 
		   END 
	END [Unrecorded Ethnicity]
	
	,CASE
		WHEN hm.[Home visits during reporting period] >= 1 
		THEN 
			CASE 
				WHEN C.DEMO_CLIENT_INTAKE_0_ETHNICITY IS NULL THEN 'Unrecorded'
				ELSE C.DEMO_CLIENT_INTAKE_0_ETHNICITY				
			END 
		END AS ClientEthnicity
	
	----Race
	,CASE WHEN hm.[Home visits during reporting period] >= 1 
		THEN 
			CASE 
				WHEN C.DEMO_CLIENT_INTAKE_0_RACE LIKE '%AMERICAN INDIAN%' 
				AND C.DEMO_CLIENT_INTAKE_0_RACE NOT LIKE '%;%'
					THEN 1 ELSE 0
		   END 
	END [American Indian]
	,CASE WHEN hm.[Home visits during reporting period] >= 1 
		THEN 
			CASE 
				WHEN C.DEMO_CLIENT_INTAKE_0_RACE LIKE '%Asian%' 
				AND C.DEMO_CLIENT_INTAKE_0_RACE NOT LIKE '%;%'
					THEN 1 ELSE 0 
		   END 
	END [Asian]
	,CASE WHEN hm.[Home visits during reporting period] >= 1 
		THEN 
			CASE 
				WHEN C.DEMO_CLIENT_INTAKE_0_RACE LIKE '%Black%' 
				AND C.DEMO_CLIENT_INTAKE_0_RACE NOT LIKE '%;%'
					THEN 1 ELSE 0 
		   END 
	END [Black]
	,CASE WHEN hm.[Home visits during reporting period] >= 1 
		THEN 
			CASE 
				WHEN C.DEMO_CLIENT_INTAKE_0_RACE LIKE '%Native Hawaiian%' 
				AND C.DEMO_CLIENT_INTAKE_0_RACE NOT LIKE '%;%'
					THEN 1 ELSE 0 
		   END 
	END [Native Hawaiian]
	,CASE WHEN hm.[Home visits during reporting period] >= 1 
		THEN 
			CASE 
				WHEN C.DEMO_CLIENT_INTAKE_0_RACE LIKE '%White%' 
				AND C.DEMO_CLIENT_INTAKE_0_RACE NOT LIKE '%;%'
					THEN 1 ELSE 0 
		   END 
	END [White]
	,CASE WHEN hm.[Home visits during reporting period] >= 1 
		THEN 
			CASE 
				WHEN C.DEMO_CLIENT_INTAKE_0_RACE LIKE '%;%'
					THEN 1 ELSE 0 
		   END 
	END [More than one race]
	,CASE WHEN hm.[Home visits during reporting period] >= 1 
		THEN 
			CASE 
				WHEN C.DEMO_CLIENT_INTAKE_0_RACE = 'Declined to self-identify'
					THEN 1 ELSE 0
		   END 
	END [Declined Race]
	,CASE WHEN hm.[Home visits during reporting period] >= 1 
		THEN 
			CASE 
				WHEN C.DEMO_CLIENT_INTAKE_0_RACE IS NULL
					THEN 1 ELSE 0 
		   END 
	END [Unrecorded Race]
	
	,CASE
		WHEN hm.[Home visits during reporting period] >= 1 
			THEN 
				CASE
					WHEN C.DEMO_CLIENT_INTAKE_0_RACE IS NOT NULL
						THEN 
							CASE	
								WHEN C.DEMO_CLIENT_INTAKE_0_RACE NOT LIKE '%;%' THEN C.DEMO_CLIENT_INTAKE_0_RACE 
								ELSE 'More Than One Race'
							END
 						ELSE 'Unrecorded'
				END
		END AS ClientRace
	
---------------------------------------------------
----Employment Status
---------------------------------------------------
	,CASE
		WHEN DD.CLIENT_WORKING_0_CURRENTLY_WORKING LIKE '%FULL%' 
			THEN 'Employed Full-Time'
		WHEN DD.CLIENT_WORKING_0_CURRENTLY_WORKING LIKE '%part%' 
			THEN 'Employed Part-Time'
		WHEN DD.CLIENT_WORKING_0_CURRENTLY_WORKING LIKE '%no%' 
			THEN 'Not Employed'
		WHEN DD.CLIENT_WORKING_0_CURRENTLY_WORKING IS NOT NULL
			THEN 'Other'
		ELSE 'Unknown/Did Not Report'
	END [Employment Status]

---------------------------------------------------
----Education/Training Status
---------------------------------------------------
	,CASE
		WHEN DD.CLIENT_EDUCATION_1_ENROLLED_FTPT LIKE '%TIME%' 
			OR DD.CLIENT_SCHOOL_MIDDLE_HS <> 'NOT ENROLLED' 
				THEN 'Student/Trainee'
		WHEN DD.CLIENT_EDUCATION_1_ENROLLED_CURRENT LIKE '%NO%' 
			OR DD.CLIENT_SCHOOL_MIDDLE_HS = 'NOT ENROLLED' 
				THEN 'Not a Student/Trainee'
		WHEN DD.CLIENT_EDUCATION_1_ENROLLED_CURRENT IS NOT NULL
			OR DD.CLIENT_SCHOOL_MIDDLE_HS IS NOT NULL
				THEN 'Other'
		ELSE 'Unknown/Did Not Report'
	END [Education/Training Status]
		
---------------------------------------------------
----Primary Language
---------------------------------------------------
	,CASE WHEN hm.[MIECHV Infants Served During Reporting Period] = 1 THEN
		CASE
			WHEN C.DEMO_CLIENT_INTAKE_0_LANGUAGE LIKE '%english%' 
				OR C.CLIENT_PERSONAL_LANGUAGE_1_DESC LIKE '%ENGLISH%'
					THEN 'English'
			WHEN C.DEMO_CLIENT_INTAKE_0_LANGUAGE LIKE '%Spanish%' 
				OR C.CLIENT_PERSONAL_LANGUAGE_1_DESC LIKE '%Spanish%'
					THEN 'Spanish'
			WHEN C.DEMO_CLIENT_INTAKE_0_LANGUAGE LIKE '%Arabic%' 
				OR C.CLIENT_PERSONAL_LANGUAGE_1_DESC LIKE '%Arabic%'
					THEN 'Arabic'
			WHEN C.DEMO_CLIENT_INTAKE_0_LANGUAGE LIKE '%Russian%' 
				OR C.CLIENT_PERSONAL_LANGUAGE_1_DESC LIKE '%Russian%'
					THEN 'Russian'
			WHEN C.DEMO_CLIENT_INTAKE_0_LANGUAGE LIKE '%Vietnamese%' 
				OR C.CLIENT_PERSONAL_LANGUAGE_1_DESC LIKE '%Vietnamese%'
					THEN 'Vietnamese'
			WHEN C.DEMO_CLIENT_INTAKE_0_LANGUAGE LIKE '%Cantonese%' 
				OR C.CLIENT_PERSONAL_LANGUAGE_1_DESC LIKE '%cantonese%' 
				OR C.CLIENT_PERSONAL_LANGUAGE_1_DESC LIKE '%chinese%'
					THEN 'Chinese*'
			WHEN C.DEMO_CLIENT_INTAKE_0_LANGUAGE LIKE '%French%' 
				OR C.CLIENT_PERSONAL_LANGUAGE_1_DESC LIKE '%french%' 
					THEN 'French'
			WHEN C.DEMO_CLIENT_INTAKE_0_LANGUAGE LIKE '%Italian%' 
				OR C.CLIENT_PERSONAL_LANGUAGE_1_DESC LIKE '%italian%' 
					THEN 'Italian'
			WHEN C.DEMO_CLIENT_INTAKE_0_LANGUAGE LIKE '%Japanese%' 
				OR C.CLIENT_PERSONAL_LANGUAGE_1_DESC LIKE '%japanese%' 
					THEN 'Japanese'
			WHEN C.DEMO_CLIENT_INTAKE_0_LANGUAGE LIKE '%Korean%' 
				OR C.CLIENT_PERSONAL_LANGUAGE_1_DESC LIKE '%korean%' 
					THEN 'Korean'
			WHEN C.DEMO_CLIENT_INTAKE_0_LANGUAGE LIKE '%Polish%' 
				OR C.CLIENT_PERSONAL_LANGUAGE_1_DESC LIKE '%polish%' 
					THEN 'Polish'
			WHEN C.DEMO_CLIENT_INTAKE_0_LANGUAGE LIKE '%Tagalog%' 
				OR C.CLIENT_PERSONAL_LANGUAGE_1_DESC LIKE '%tagalog%' 
					THEN 'Tagalog'
			WHEN C.DEMO_CLIENT_INTAKE_0_LANGUAGE LIKE '%Tribal Languages%' 
				OR C.CLIENT_PERSONAL_LANGUAGE_1_DESC LIKE '%tribal%' 
					THEN 'Tribal Languages'
			WHEN C.DEMO_CLIENT_INTAKE_0_LANGUAGE IS NOT NULL 
				OR C.CLIENT_PERSONAL_LANGUAGE_1_DESC IS NOT NULL
					THEN 'Other'
			ELSE 'Unknown/Did Not Report'
		END
	END  [Primary Language]
		
---------------------------------------------
----Priority Populations
---------------------------------------------
	,CASE WHEN EAD.ProgramStartDate BETWEEN @StartDate AND @EndDate
		THEN
			CASE WHEN DD.CLIENT_INCOME_1_LOW_INCOME_QUALIFY = 'Yes' 
				THEN 1 
				ELSE 0 
			END 
		ELSE 0
	END LowIncomeCriteria
	,CASE WHEN EAD.ProgramStartDate BETWEEN @StartDate AND @EndDate
		THEN
			CASE WHEN DATEDIFF(YY, C.DOB, EAD.ProgramStartDate) < 21 
				THEN 1 
				ELSE 0 
			END 
		ELSE 0
	END PregnantUnder21
	,CASE WHEN EAD.ProgramStartDate BETWEEN @StartDate AND @EndDate
		THEN
			CASE WHEN HHI.CLIENT_SUBSTANCE_CIG_1_LAST_48 > 0 
				THEN 1 
				ELSE 0 
			END 
		ELSE 0
	END TobaccoUser
	,CASE WHEN EAD.ProgramStartDate BETWEEN @StartDate AND @EndDate
		THEN
			CASE WHEN DD.CLIENT_MILITARY <> 'None' AND DD.CLIENT_MILITARY IS NOT NULL 
				THEN 1 
				ELSE 0 
			END 
		ELSE 0
	END Military

---------------------------------------------
---Family Retention and Home Visits
---------------------------------------------
	,hm.[Currently Rcv Svcs]	 
	,hm.[Home visits during reporting period]
	
	,hm.FundingType		
	
	--Rollup these values into a single column that you can group by
	----Unknown Insurance
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
JOIN DBO.udf_HRSA_MIECHV_Summary(@StartDate, @EndDate,@FundingType,@Teams) HM
		ON HM.CLID = EAD.CLID
		AND HM.ProgramID = EAD.ProgramID
		AND HM.[Served During Reporting Period] = 1	
							
	JOIN Clients C ON C.Client_Id = EAD.CLID  
	JOIN UV_PAS PAS ON PAS.ProgramID = EAD.ProgramID  

	LEFT JOIN DemographicsSurvey ds ON ds.CLID = EAD.CLID
										AND ds.ProgramID = EAD.ProgramID
	LEFT JOIN Demographics_Survey DD ON DD.SurveyResponseID = ds.latestSurveyResponseID ----filter on latest survey
															
	----govt child
	LEFT JOIN GovtCommSrvcsSurvey_child gschild ON gschild.CLID = EAD.CLID
										AND gschild.ProgramID = EAD.ProgramID	
	LEFT JOIN Govt_Comm_Srvcs_Survey GCChild ON GCChild.SurveyResponseID = gschild.latestSurveyResponseID ----filter on latest survey
	----govt client
	LEFT JOIN GovtCommSrvcsSurvey_client gsclient ON gsclient.CLID = EAD.CLID
										AND gsclient.ProgramID = EAD.ProgramID	
	LEFT JOIN Govt_Comm_Srvcs_Survey GCClient ON GCClient.SurveyResponseID = gsclient.latestSurveyResponseID ----filter on latest survey

	LEFT JOIN Health_Habits_Survey HHI ON HHI.CL_EN_GEN_ID = EAD.CLID
														AND HHI.ProgramID = EAD.ProgramID
														AND HHI.SurveyDate < = @EndDate
														AND DataWarehouse.dbo.fnGetFormName(HHI.SurveyID) LIKE '%INTAKE%'	
														AND EAD.ProgramStartDate BETWEEN @StartDate AND @EndDate
	----------NHV parm selection
	LEFT JOIN StfToClientByEndDate sc ON sc.CLID = EAD.CLID
							AND sc.ProgramID = EAD.ProgramID
							AND sc.Ranking = 1
	LEFT JOIN dbo.fn_FID_Staff_list('1/1/1900',@EndDate) S ON S.Entity_ID = sc.EntityID
													AND S.ProgramID = sc.ProgramID	
	JOIN DataWarehouse.dbo.udf_ParseMultiParam(@NHV) parmNHV ON parmNHV.Value = CASE						----report selection for nurses
																					WHEN sc.EntityID > 0 
																					THEN sc.EntityID		----specific NHV selected
																					ELSE -1					----Unassigned NHV selected
																				END															
	
WHERE ISNULL( EAD.EndDate, GETDATE() ) >= @StartDate AND EAD.ProgramStartDate <= @EndDate
		AND EAD.RankingLatest = 1

GO
