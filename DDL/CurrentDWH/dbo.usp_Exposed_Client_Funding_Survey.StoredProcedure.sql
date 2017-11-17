USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Exposed_Client_Funding_Survey]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_Exposed_Client_Funding_Survey]

@Start date
,@End date

AS

Select 

SurveyResponseID
, ElementsProcessed
, SurveyID
, SurveyDate
, AuditDate
, CL_EN_GEN_ID
, Client_Funding_Survey.SiteID
, Client_Funding_Survey.ProgramID
, IA_StaffID
, ClientID
, RespondentID
, CLIENT_FUNDING_0_SOURCE_MIECHVP_COM
, CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM
, CLIENT_FUNDING_0_SOURCE_OTHER
, CLIENT_FUNDING_0_SOURCE_OTHER_TXT
, CLIENT_FUNDING_1_END_MIECHVP_COM
, CLIENT_FUNDING_1_END_MIECHVP_FORM
, CLIENT_FUNDING_1_END_OTHER
, CLIENT_FUNDING_1_START_MIECHVP_COM
, CLIENT_FUNDING_1_START_MIECHVP_FORM
, CLIENT_FUNDING_1_START_OTHER
, NURSE_PERSONAL_0_NAME
, DW_AuditDate
, DataSource
, CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL
, CLIENT_FUNDING_1_END_MIECHVP_TRIBAL
, CLIENT_FUNDING_1_START_MIECHVP_TRIBAL
, ProgramsAndSites.ProgramName
, ProgramsAndSites.Site
, AGENCY_INFO_0_NAME
, AGENCY_INFO_1_INITIATION_DATE
, AGENCY_DATE_FIRST_HOME_VISIT
, [US State]
, Abbreviation
, StateID
, Team_Name
, PRIMARY_SUPERVISOR
, SECONDARY_SUPERVISOR
, Program_ID_Staff_Supervision
, Program_ID_Referrals
, Program_ID_NHV
, City
, AGENCY_INFO_1_LOWINCOME_CRITERA
, AGENCY_INFO_1_LOWINCOME_PERCENT
, AGENCY_INFO_1_LOWINCOME_DESCRIPTION
, Team_Id
, CleanAgencyName
, CleanSiteName
, CleanTeamName

From

Client_Funding_Survey
left Join ProgramsAndSites on ProgramsAndSites.ProgramID = Client_Funding_Survey.ProgramID
Left Join UV_PAS on UV_Pas.ProgramID = Client_Funding_Survey.ProgramID
GO
