USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_BreastfeedingInitCont]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_BreastfeedingInitCont]
AS
 
SELECT 
	CLID [Client ID]
	,CaseNumber [Case Number]
	,MAX(CASE 
		WHEN SurveyName LIKE '%birth%' AND BreastmilkEver IS NOT NULL
			THEN BreastmilkEver
			ELSE ''
	END) [Breastmilk Ever - Birth]
	,MAX(CASE 
		WHEN SurveyName LIKE '%6%' AND BreastmilkEver IS NOT NULL
			THEN BreastmilkEver
			ELSE ''
	END) [Breastmilk Ever - 6 mos]
	,MAX(CASE 
		WHEN SurveyName LIKE '%6%' AND BreastmilkContinued IS NOT NULL
			THEN BreastmilkEver
			ELSE ''
	END) [Breastmilk Continued - 6 mos]
	,MAX(CASE 
		WHEN SurveyName LIKE '%12%' AND BreastmilkEver IS NOT NULL
			THEN BreastmilkEver
			ELSE ''
	END) [Breastmilk Ever - 12 mos]
	,MAX(CASE 
		WHEN SurveyName LIKE '%12%' AND BreastmilkContinued IS NOT NULL
			THEN BreastmilkEver
			ELSE ''
	END) [Breastmilk Continued - 12 mos]
	,InfantDOB	[Infant Date of Birth]
	,ClientDelvAge [Client Delivery Age]
	,ClientRace [Client Race]
	,MaritalStatus [Marital Status]
	,LowIncCriteria	[Low Income Criteria]
	,CASE
		WHEN CLIENT_INCOME_0_HH_INCOME IS NOT NULL
			THEN CLIENT_INCOME_0_HH_INCOME
		WHEN CLIENT_INCOME_AMOUNT IS NOT NULL
			THEN CLIENT_INCOME_AMOUNT
		ELSE ''
	END [Income Range]		
	,[State]
	,Agency
	,Program
	
FROM
(		----detail records, ranked on enrollment
		SELECT 
			EAD.CLID
			,EAD.CaseNumber
			,pas.StateID
			,pas.Abbreviation [State]
			,pas.[SiteID]
			,pas.AGENCY_INFO_0_NAME Agency
			,pas.ProgramID
			,dbo.udf_fn_GetCleanProg(pas.ProgramID) Program	
			,IBSAndIHS.SurveyName
			,IBSAndIHS.BreastmilkEver
			,IBSAndIHS.BreastmilkContinued
			,Client.InfantDOB
			,CAST(Client.ClientDelvAge AS DECIMAL(10,3)) ClientDelvAge
			,Client.ClientRace			
			,ISNULL(Demographics.CLIENT_MARITAL_0_STATUS,'') MaritalStatus
			,ISNULL(Demographics.CLIENT_INCOME_1_LOW_INCOME_QUALIFY,'') LowIncCriteria
			,Demographics.CLIENT_INCOME_AMOUNT
			,Demographics.CLIENT_INCOME_0_HH_INCOME

			,RANK() OVER(PARTITION BY EAD.CLID, EAD.ProgramID 
						ORDER BY ISNULL(EAD.EndDate,DATEADD(DAY,1,GETDATE())) DESC, EAD.RecID DESC) RankingLatest
	
		FROM (	SELECT 
					EAD.CLID
					,EAD.ProgramID 
					,EAD.SiteID
					,EAD.ProgramStartDate
					,EAD.EndDate
					,EAD.ReasonForDismissal
					,EAD.RecID
					,EAD.CaseNumber

				FROM UV_EADT EAD
			)EAD
		
		JOIN UV_PAS pas ON pas.ProgramID = EAD.ProgramID

		LEFT JOIN ---- Demographics
			(	SELECT 
					DS.CL_EN_GEN_ID
					,DS.ProgramID
					,DS.CLIENT_INCOME_1_LOW_INCOME_QUALIFY
					,CLIENT_INCOME_AMOUNT 
					,CLIENT_INCOME_0_HH_INCOME
					,DS.CLIENT_MARITAL_0_STATUS					
					,RANK() OVER(PARTITION BY DS.CL_EN_GEN_ID,DS.ProgramID 
									ORDER BY DS.SurveyResponseID DESC) Rank									
				FROM Demographics_Survey DS
				WHERE dbo.fnGetFormName(DS.SurveyID) = 'Demographics: Pregnancy Intake'
			) Demographics ON Demographics.ProgramID = EAD.ProgramID 
				AND Demographics.CL_EN_GEN_ID = EAD.CLID 
				AND Demographics.Rank = 1

		LEFT JOIN ---- Client/infant birth info
			(SELECT
				C.Client_Id CLID
				,IBS.ProgramID
				,IBS.INFANT_BIRTH_0_DOB InfantDOB
				,C.DEMO_CLIENT_INTAKE_0_RACE ClientRace
				,DATEDIFF(DAY,C.DOB,IBS.INFANT_BIRTH_0_DOB)/365.25 ClientDelvAge				
			FROM Clients C
				JOIN (SELECT 
						BS.CL_EN_GEN_ID
						,BS.ProgramID
						,BS.INFANT_BIRTH_0_DOB
						,RANK() OVER(Partition By BS.CL_EN_GEN_ID,BS.ProgramID 
									Order By BS.SurveyDate DESC,BS.SurveyResponseID DESC) Rank
					 FROM Infant_Birth_Survey BS	
					 WHERE BS.INFANT_BIRTH_0_DOB IS NOT NULL
					) IBS ON IBS.CL_EN_GEN_ID = C.client_id 
						AND IBS.Rank = 1
			) Client ON Client.CLID = EAD.CLID 
				AND Client.ProgramID = EAD.ProgramID

		LEFT JOIN ----combined surveys - infant birth and infant health w/breastmilk info
			(	SELECT 
					 ibs.ProgramID
					, ibs.CL_EN_GEN_ID Client
					, ms.SurveyName
					, ibs.INFANT_BREASTMILK_0_EVER_BIRTH BreastmilkEver	
					, '' BreastmilkContinued
					, RANK() OVER(Partition By ibs.CL_EN_GEN_ID,ibs.ProgramID
							Order By ibs.SurveyDate DESC,ibs.SurveyResponseID DESC) Rank
				FROM Infant_Birth_Survey ibs
					LEFT JOIN Mstr_surveys ms on ms.SurveyID = ibs.SurveyID		----birth
				WHERE 	ibs.CL_EN_GEN_ID IS NOT NULL							----remove surveys where client id is blank
					AND ibs.ProgramID IS NOT NULL								----remove where no program id
				UNION ALL
				SELECT 
					 ihs.ProgramID
					, ihs.CL_EN_GEN_ID Client
					, ms.SurveyName
					, ihs.INFANT_BREASTMILK_0_EVER_IHC  BreastmilkEver	
					, ihs.INFANT_BREASTMILK_1_CONT  BreastmilkContinued	
					, RANK() OVER(Partition By ihs.CL_EN_GEN_ID,ihs.ProgramID, SurveyName ----get latest 6 & 12
							Order By ihs.SurveyDate DESC,ihs.SurveyResponseID DESC) Rank
				FROM Infant_Health_Survey ihs 
					LEFT JOIN Mstr_surveys ms on ms.SurveyID = ihs.SurveyID
				WHERE 	ms.SurveyName LIKE '%6%' OR ms.SurveyName LIKE '%12%'		----6 & 12 mos		
					AND ihs.CL_EN_GEN_ID IS NOT NULL								----remove surveys where client id is blank
					AND ihs.ProgramID IS NOT NULL									----remove where no program id
				) IBSAndIHS ON IBSAndIHS.Client = EAD.CLID
					AND IBSAndIHS.ProgramID = EAD.ProgramID  
					AND IBSAndIHS.Rank = 1
)AllRecs

WHERE RankingLatest = 1								--latest enrollment 
	AND (Stateid IN (30,38)							--NJ, PA
		OR SiteID IN (193,165,163,170,176,164) )	--Wake, Guilford, Cleveland, Care Ring, Robeson, Pitt
	AND ClientRace = 'Black or African American'
---------------------------------------------------------------------------------
----run for each of these date ranges, put into separate tabs of the same Excel document
---------------------------------------------------------------------------------
	--AND InfantDOB >= '2/1/2012' AND InfantDOB <= '2/28/2013'	----added this on own since only partial 2014-2015 avail
	--AND InfantDOB >= '2/1/2013' AND InfantDOB <= '2/28/2014'	----1st date range
	AND InfantDOB >= '2/1/2014' AND InfantDOB <= '2/28/2015'	----2nd date range ??? we are only partway into 2014 ???
------------------------------------------------------------------------------------
	
GROUP BY 
	CLID
	,CaseNumber
	,InfantDOB	
	,ClientDelvAge 
	,ClientRace
	,MaritalStatus
	,LowIncCriteria	
	,CLIENT_INCOME_AMOUNT 
	,CLIENT_INCOME_0_HH_INCOME
	,[State]
	,Agency
	,Program
		
ORDER BY State, Agency, CLID
GO
