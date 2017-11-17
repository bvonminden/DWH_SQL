USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_UV_PAS]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_UV_PAS]
	-- Add the parameters for the stored procedure here
AS
BEGIN

IF OBJECT_ID('dbo.UC_PAS', 'U') IS NOT NULL DROP TABLE dbo.UC_PAS;

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
SELECT
	PAS.ProgramID
	,PAS.ProgramName
	,PAS.SiteID
	,PAS.Site
	,A.AGENCY_INFO_0_NAME
	,A.AGENCY_INFO_1_INITIATION_DATE
	,A.AGENCY_DATE_FIRST_HOME_VISIT
	,CASE WHEN U.[US State] = 'New Hampshire' THEN 'Vermont' ELSE U.[US State] END [US State]
	,CASE WHEN U.Abbreviation = 'NH' THEN 'VT' ELSE U.Abbreviation END Abbreviation
	,CASE WHEN U.StateID = 29 THEN 45 ELSE U.StateID END StateID
	,T.Team_Name
	,T.PRIMARY_SUPERVISOR
	,T.SECONDARY_SUPERVISOR
	,T.Program_ID_Staff_Supervision
	,T.Program_ID_Referrals
	,T.Program_ID_NHV
	,A.City
	,A.AGENCY_INFO_1_LOWINCOME_CRITERA
	,A.AGENCY_INFO_1_LOWINCOME_PERCENT
	,A.AGENCY_INFO_1_LOWINCOME_DESCRIPTION
	,T.Team_Id
	,REPLACE(dbo.udf_RemoveSpecialChars(A.AGENCY_INFO_0_NAME),' ','') CleanAgencyName
	,REPLACE(dbo.udf_RemoveSpecialChars(PAS.Site),' ','') CleanSiteName
	,REPLACE(dbo.udf_RemoveSpecialChars(T.Team_Name),' ','') CleanTeamName
INTO UC_PAS

FROM Agencies A 
	INNER JOIN dbo.ProgramsAndSites PAS 
		ON PAS.SiteID = A.Site_ID 
			AND PAS.ProgramName LIKE '%NURSE%' 
			AND PAS.ProgramName NOT LIKE '%TEST%' 
			AND PAS.ProgramName NOT LIKE '%TRAIN%' 
			AND PAS.ProgramName NOT LIKE '%PROOF%' 
			AND PAS.ProgramName NOT LIKE '%DEMO%' 
			AND PAS.Site NOT LIKE '%TEST%' 
			AND PAS.Site NOT LIKE '%TRAIN%' 
			AND PAS.Site NOT LIKE '%DEMO%' 
			AND PAS.Site NOT LIKE '%PROOF%' 

	LEFT OUTER JOIN dbo.Teams T 
		ON T.Program_ID_NHV = PAS.ProgramID 

	LEFT OUTER JOIN dbo.UC_State U 
		ON U.Abbreviation = dbo.udf_StateVSTribal(A.State,A.Site_ID)
WHERE A.Entity_Id NOT IN(9930) AND PAS.ProgramID <> 980--(9930,24497) --A.End_Date IS NULL
		
END
GO
