USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[USP_Build_DMProgramAndSites]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Teds ProgramAndSites Script
-- Create date: 12/1/2015
-- Description:	This will create the DM ProgramAndSites data used in the the Datamart for Logi
-- =============================================
CREATE PROCEDURE [dbo].[USP_Build_DMProgramAndSites]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
IF OBJECT_ID('dbo.[DMProgramsAndSites]', 'U') IS NOT NULL
  DROP TABLE dbo.[DMProgramsAndSites]; 

CREATE TABLE [dbo].DMProgramsAndSites(
	ProgramID INT NOT NULL
		,CONSTRAINT PK_DimProgramsAndSites_UniqueID PRIMARY KEY CLUSTERED ([ProgramID])
	,ProgramIDReferral INT NOT NULL
		,CONSTRAINT UQ_DimProgramsAndSites_ProgramIDReferral UNIQUE(ProgramIDReferral)
	,ProgramIDStaffSupervision INT NOT NULL
		,CONSTRAINT UQ_DimProgramsAndSites_ProgramIDStaffSupervision UNIQUE(ProgramIDStaffSupervision)
    ,ProgramName varchar(500)
	,SiteID INT NOT NULL
	,StateID INT NOT NULL
	,TeamID INT
	,TeamName varchar(100) NOT NULL
	,SiteName varchar(100) NOT NULL
	,StateName varchar(100) NOT NULL
	,StateAbbr varchar(10) NOT NULL
	,StartDate DATE NOT NULL
	,EndDate DATE NULL
	,Disabled INT
)

-- One row per team
INSERT INTO DMProgramsAndSites
SELECT
	 pas.[ProgramID]
	,pas.[Program_ID_Referrals] as [ProgramIDReferral]
	,pas.[Program_ID_Staff_Supervision] as [ProgramIDStaffSupervision]
	,pas.[ProgramName]
	,pas.[SiteID]
	,pas.[StateID]
	,pas.[Team_Id] as [TeamID]
	,pas.[Team_Name] as [TeamName]
	,pas.[Site] as [SiteName]
	,pas.[US State] as [StateName]
	,pas.[Abbreviation] as [StateAbbr]
	,E.DateCreated  as [StartDate]
	,CASE WHEN e.Disabled = 1 THEN  e.AuditDate END EndDate 
	,e.Disabled
FROM [DataWarehouse].[dbo].[UC_PAS] pas
INNER JOIN etosolaris..Entities e on e.EntityID = pas.Team_Id
Order by stateID

END

GO
