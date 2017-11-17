USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fidelity_HVES]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_Fidelity_HVES]

AS


IF OBJECT_ID('dbo.UC_Fidelity_HVES', 'U') IS NOT NULL DROP TABLE dbo.UC_Fidelity_HVES;

IF OBJECT_ID('tempdb..##UC_Client_Exclusion_YWCA') IS NOT NULL DROP TABLE ##UC_Client_Exclusion_YWCA

Create Table ##UC_Client_Exclusion_YWCA 
(
	[RowID] [int] IDENTITY(1,1) NOT NULL,
	CLID float,
	CaseNumber nvarchar(255)
	PRIMARY KEY (RowID)
)

Insert INTO ##UC_Client_Exclusion_YWCA
Select * from dbo.UC_Client_Exclusion_YWCA
		
SELECT 
	HVES.CL_EN_GEN_ID 	
	,HVES.ProgramID
	,HVES.SiteID
	--,Cast(HVES.SurveyDate as date) as SurveyDate
	,Cast(HVES.SurveyDate as date) as SurveyDate
	,HVES.SurveyResponseID
	,HVES.NURSE_PERSONAL_0_NAME
	,HVES.CLIENT_TIME_0_START_VISIT	
	,HVES.CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT
	,HVES.CLIENT_DOMAIN_0_MATERNAL_VISIT
	,HVES.CLIENT_DOMAIN_0_PERSHLTH_VISIT
	,HVES.CLIENT_DOMAIN_0_LIFECOURSE_VISIT
	,HVES.CLIENT_DOMAIN_0_FRNDFAM_VISIT
	,CASE WHEN HVES.CLIENT_LOCATION_0_VISIT LIKE 'Client%' THEN 1 ELSE 0 END Home_Visit
	,RANK() OVER(Partition By HVES.NURSE_PERSONAL_0_NAME,HVES.SurveyDate,HVES.CLIENT_TIME_0_START_VISIT,HVES.ProgramID,HVES.SiteID Order By HVES.CL_EN_GEN_ID,HVES.SurveyResponseID DESC) Rank_dup
	,SUM(1) OVER(Partition By HVES.NURSE_PERSONAL_0_NAME,HVES.SurveyDate,HVES.CLIENT_TIME_0_START_VISIT,HVES.ProgramID,HVES.SiteID) Count_dup
	,DBO.udf_PhasebyDate(HVES.CL_EN_GEN_ID,HVES.SurveyDate,HVES.ProgramID) [Visit Phase]

	,CASE WHEN TS.CL_EN_GEN_ID IS NOT NULL THEN 1 ELSE 0 END Tribal
	,CASE WHEN TS.CLIENT_TRIBAL_0_PARITY = 'Primiparous (pregnant with her first child)' THEN 1
		  WHEN TS.CLIENT_TRIBAL_0_PARITY = 'Multiparous (pregnant with a second or subsequent child)' THEN 2 END Tribal_PM
INTO UC_Fidelity_HVES
FROM Home_Visit_Encounter_Survey HVES

	LEFT JOIN ##UC_Client_Exclusion_YWCA YWCA 
		ON YWCA.CLID = HVES.CL_EN_GEN_ID
		AND HVES.SiteID = 222

LEFT JOIN Tribal_Survey TS
	ON HVES.CL_EN_GEN_ID = TS.CL_EN_GEN_ID
	AND HVES.ProgramID = TS.ProgramID

WHERE HVES.CLIENT_COMPLETE_0_VISIT = 'Completed'
AND HVES.NURSE_PERSONAL_0_NAME IS NOT NULL
AND YWCA.CLID IS NULL

GO
