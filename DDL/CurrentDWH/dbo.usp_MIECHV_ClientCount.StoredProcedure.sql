USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_MIECHV_ClientCount]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_MIECHV_ClientCount] 
AS


------begin CTEs
;WITH HVES AS
(	SELECT 
		CL_EN_GEN_ID CLID
		,ProgramID
		,SiteID 
		,MIN(SurveyDate) minSurveyDate	--first visit
		,MAX(SurveyDate) maxSurveyDate	--last visit
	FROM Home_Visit_Encounter_Survey 
	WHERE CLIENT_COMPLETE_0_VISIT = 'Completed'
	GROUP BY 
		CL_EN_GEN_ID 
		,ProgramID 
		,SiteID 
)
,StfToClient AS
(	SELECT CLID, EntityID
		,ROW_NUMBER() OVER(PARTITION BY CLID  ORDER BY EntityID) AS RowNumberNurse1	----per Kyla, list all nurses ever associated with client
	FROM 
	(	----staff to client records, current and history
		SELECT StaffID, CLID, ProgramID, NULL EndDate, Entity_Id EntityID FROM StaffxClient
		UNION ALL
		SELECT StaffID, CLID, ProgramID, EndDate, Entity_Id EntityID FROM StaffxClientHx
	)sxcg
	GROUP BY CLID, EntityID
)------end CTEs


--------------------------------------------------
----run this portion for grouped data (below)
--------------------------------------------------

-------------------grouped recs/agency counts

SELECT 
	[State ID]
	,[State]
	,[Site ID]
	,[Site Name]			
	,COUNT(CLID) [Number Distinct Clients]
	,SUM(CASE WHEN Competitive <> '' THEN 1 ELSE 0 END) [Competitive]			
	,SUM(CASE WHEN Formula <> '' THEN 1 ELSE 0 END) [Formula]			
	,SUM(CASE WHEN Tribal <> '' THEN 1 ELSE 0 END) [Tribal]			

FROM
(	

--------------------------------------------------
----run this portion for grouped data (above)
--------------------------------------------------


	--------------------------------------------------
	----run this portion for details/filters (below)
	--------------------------------------------------

	----detail recs grouped on funding source to produce list with distinct client ids
	SELECT 
		AllDetailRecs.CLID
		,CAST(AllDetailRecs.ProgramStartDate AS DATE) [Program Start Date]
		,CAST(AllDetailRecs.ProgramEndDate AS DATE) [Program End Date]
		,MAX(AllDetailRecs.Competitive) Competitive	----grouped so only 1 record per client
		,MAX(AllDetailRecs.Formula) Formula ----grouped so only 1 record per client
		,MAX(AllDetailRecs.Tribal) Tribal ----grouped so only 1 record per client
		,CAST(AllDetailRecs.FirstHomeVisit AS DATE) [First Home Visit]
		,CAST(AllDetailRecs.LastHomeVisit AS DATE)	[Last Home Visit]
		
		----below grouped so only 1 record per client 
		,MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 1 THEN AllDetailRecs.IAStfNurseID END) [Nurse1ID]
		,CAST(MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 1 THEN AllDetailRecs.IAStfNurseStartDate END) AS DATE) [Nurse1StartDate] 
		,MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 2 THEN AllDetailRecs.IAStfNurseID END) [Nurse2ID]
		,CAST(MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 2 THEN AllDetailRecs.IAStfNurseStartDate END) AS DATE) [Nurse2StartDate]
		,MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 3 THEN AllDetailRecs.IAStfNurseID END) [Nurse3ID]
		,CAST(MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 3 THEN AllDetailRecs.IAStfNurseStartDate END) AS DATE) [Nurse3StartDate]
		,MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 4 THEN AllDetailRecs.IAStfNurseID END) [Nurse4ID]
		,CAST(MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 4 THEN AllDetailRecs.IAStfNurseStartDate END) AS DATE) [Nurse4StartDate]
		,MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 5 THEN AllDetailRecs.IAStfNurseID END) [Nurse5ID]
		,CAST(MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 5 THEN AllDetailRecs.IAStfNurseStartDate END) AS DATE) [Nurse5StartDate]

		,MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 6 THEN AllDetailRecs.IAStfNurseID END) [Nurse6ID]
		,CAST(MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 6 THEN AllDetailRecs.IAStfNurseStartDate END) AS DATE) [Nurse6StartDate] 
		,MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 7 THEN AllDetailRecs.IAStfNurseID END) [Nurse7ID]
		,CAST(MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 7 THEN AllDetailRecs.IAStfNurseStartDate END) AS DATE) [Nurse7StartDate]
		,MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 8 THEN AllDetailRecs.IAStfNurseID END) [Nurse8ID]
		,CAST(MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 8 THEN AllDetailRecs.IAStfNurseStartDate END) AS DATE) [Nurse8StartDate]
		,MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 9 THEN AllDetailRecs.IAStfNurseID END) [Nurse9ID]
		,CAST(MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 9 THEN AllDetailRecs.IAStfNurseStartDate END) AS DATE) [Nurse9StartDate]
		,MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 10 THEN AllDetailRecs.IAStfNurseID END) [Nurse10ID]
		,CAST(MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 10 THEN AllDetailRecs.IAStfNurseStartDate END) AS DATE) [Nurse10StartDate]
	
		----only saw 10 max, but added these just in case
		,MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 11 THEN AllDetailRecs.IAStfNurseID END) [Nurse11ID]
		,CAST(MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 11 THEN AllDetailRecs.IAStfNurseStartDate END) AS DATE) [Nurse11StartDate] 
		,MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 12 THEN AllDetailRecs.IAStfNurseID END) [Nurse12ID]
		,CAST(MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 12 THEN AllDetailRecs.IAStfNurseStartDate END) AS DATE) [Nurse12StartDate]
		,MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 13 THEN AllDetailRecs.IAStfNurseID END) [Nurse13ID]
		,CAST(MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 13 THEN AllDetailRecs.IAStfNurseStartDate END) AS DATE) [Nurse13StartDate]
		,MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 14 THEN AllDetailRecs.IAStfNurseID END) [Nurse14ID]
		,CAST(MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 14 THEN AllDetailRecs.IAStfNurseStartDate END) AS DATE) [Nurse14StartDate]
		,MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 15 THEN AllDetailRecs.IAStfNurseID END) [Nurse15ID]
		,CAST(MAX(CASE WHEN AllDetailRecs.RowNumberNurse = 15 THEN AllDetailRecs.IAStfNurseStartDate END) AS DATE) [Nurse15StartDate]
		----above grouped so only 1 record per client	
		
		,AllDetailRecs.StateID [State ID]
		,AllDetailRecs.[State]
		,AllDetailRecs.SiteID [Site ID]
		,AllDetailRecs.SiteName [Site Name]
		,AllDetailRecs.ProgramID [Program ID]
		,AllDetailRecs.ProgramName [Program Name]		

	FROM
	(		---------------all detail recs
			SELECT 
				EAD.CLID
				,EAD.ProgramStartDate
				,EAD.EndDate ProgramEndDate
				,CASE WHEN CF.CLIENT_FUNDING_0_SOURCE_MIECHVP_COM IS NOT NULL THEN 'Competitive' ELSE '' END Competitive
				,CASE WHEN CF.CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM IS NOT NULL THEN 'Formula' ELSE '' END Formula
				,CASE WHEN CF.CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL IS NOT NULL THEN 'Tribal' ELSE '' END Tribal
				,HVES.minSurveyDate FirstHomeVisit
				,HVES.maxSurveyDate LastHomeVisit			

				,s3.Entity_Id IAStfNurseID
				,s3.Start_Date IAStfNurseStartDate
				,ROW_NUMBER() OVER(PARTITION BY EAD.CLID  ORDER BY s3.Start_Date, s3.Entity_Id) AS RowNumberNurse

				,pas.StateID
				,pas.Abbreviation [State]
				,pas.SiteID
				,pas.AGENCY_INFO_0_NAME SiteName
				,pas.ProgramID
				,pas.ProgramName		
							
			FROM UV_EADT EAD

				JOIN UV_PAS pas ON pas.ProgramID = EAD.ProgramID 
								AND pas.SiteID = EAD.SiteID

				LEFT JOIN Client_Funding_Survey CF ON CF.CL_EN_GEN_ID = EAD.CLID 
													AND CF.ProgramID = EAD.ProgramID 
													AND (CF.CLIENT_FUNDING_1_START_MIECHVP_COM >= '10/1/2010'
														OR CF.CLIENT_FUNDING_1_START_MIECHVP_FORM >= '10/1/2010'
														OR CF.CLIENT_FUNDING_1_START_MIECHVP_TRIBAL >= '10/1/2010')

				LEFT JOIN HVES ON HVES.CLID = EAD.CLID 
								AND HVES.ProgramID = EAD.ProgramID 
							
				LEFT JOIN StfToClient sc ON sc.CLID = EAD.CLID			----per Kyla, list all nurses ever associated with client
											------AND sc.ProgramID = EAD.ProgramID
				LEFT JOIN IA_Staff s3 ON s3.Entity_Id = sc.EntityID		----per Kyla, list all nurses ever associated with client
										------AND s3.Site_ID = EAD.SiteID
			
			WHERE EAD.RankingLatest = 1

			----run a total of 6 times and put each result set into the same spreadsheet, but on separate worksheets/tabs
				----2 times for NJ, 1 is details and 1 is grouped
				----2 for MI, 1 is details and 1 is grouped
				----2 for ALL but NJ & MI, 1 is details and 1 is grouped
			
			
				--PER KYLA, do not filter/limit to MIECHV funding, get ALL enrolled for NJ & MI
				AND pas.StateID = 30	----NJ agencies				
				--AND pas.StateID = 22	----MI agencies				
							
			
			/*
				--PER KYLA, filter/limit to MIECHV funding for ALL except for NJ & MI			
				AND (CLIENT_FUNDING_0_SOURCE_MIECHVP_COM IS NOT NULL 
					OR CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM IS NOT NULL 
					OR CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL IS NOT NULL) 					
				AND pas.StateID NOT IN (30,22)	---- exclude NJ & MI agencies, which are run separately and not limited to MIECHV			
			*/
		
		----------AND EAD.CLID = 650668 ----use for testing, this client has had 10 nurses
				
		GROUP BY
				EAD.CLID
				,EAD.ProgramStartDate
				,EAD.EndDate
				,CASE WHEN CF.CLIENT_FUNDING_0_SOURCE_MIECHVP_COM IS NOT NULL THEN 'Competitive' ELSE '' END 
				,CASE WHEN CF.CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM IS NOT NULL THEN 'Formula' ELSE '' END 
				,CASE WHEN CF.CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL IS NOT NULL THEN 'Tribal' ELSE '' END 
				,HVES.minSurveyDate
				,HVES.maxSurveyDate
				,s3.Entity_Id 
				,s3.Start_Date 
				,pas.StateID
				,pas.Abbreviation 
				,pas.SiteID
				,pas.AGENCY_INFO_0_NAME 
				,pas.ProgramID
				,pas.ProgramName		
		
		
	)AllDetailRecs
	GROUP BY
		AllDetailRecs.CLID
		,AllDetailRecs.ProgramStartDate
		,AllDetailRecs.ProgramEndDate
		,AllDetailRecs.FirstHomeVisit
		,AllDetailRecs.LastHomeVisit	
		,AllDetailRecs.StateID
		,AllDetailRecs.[State]
		,AllDetailRecs.SiteID
		,AllDetailRecs.SiteName
		,AllDetailRecs.ProgramID
		,AllDetailRecs.ProgramName		

		----detail sort - comment out when running grouped data
		--ORDER BY CLID

	--------------------------------------------------
	----run this portion for details/filters (above)
	--------------------------------------------------


--------------------------------------------------
----run this portion for grouped data (below)
--------------------------------------------------

)MIECHVGrpCounts

GROUP BY
	[State ID]
	,[State]
	,[Site ID]
	,[Site Name]			


ORDER BY [State], [Site Name]

--------------------------------------------------
----run this portion for grouped data (above)
--------------------------------------------------


GO
