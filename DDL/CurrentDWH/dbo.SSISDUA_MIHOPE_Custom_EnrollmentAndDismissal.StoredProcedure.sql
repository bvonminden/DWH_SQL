USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISDUA_MIHOPE_Custom_EnrollmentAndDismissal]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Jingjing Gao
-- Create date: 03/09/2017
-- Description:	Custom extract of EnrollmentAndDismissal data where the SiteID from [EnrollmentAndDismissal] is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID. 
-- Export Requirements:
-- 1)	De-identified data for customer
-- 2)	Provide the same data set with identifiable data on the S drive for the NSO
-- 3)	Join with MIHOPE provided table to provide the MIHOPE ID with the corresponding NSO ID (which will be hashed)
-- 4)	We need to provide a table so they can cross reference EntityID with Nurse Name 
-- 5)	Parameter on the export – no SurveyDates or ProgramStartDates after 12/31/2016
-- 6)	Parameter on the export – only data from the following siteIDs and only data for the provided CLID/CL_EN_GENs/ClientId (SiteIDs: 289, 179, 185, 103, 163, 212, 251, 287)
-- =============================================
CREATE PROCEDURE [dbo].[SSISDUA_MIHOPE_Custom_EnrollmentAndDismissal]
	-- Add the parameters for the stored procedure here
	@ProfileID INT 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
SELECT HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLID])) AS [CLID]
		  ,[StudyID]
		  ,[SiteID]
		  ,[ProgramID]
		  ,[ProgramStartDate]
		  ,[EndDate]
		  ,[ReasonForDismissal]
		 
	  FROM [DataWarehouse].[dbo].[EnrollmentAndDismissal] s
	  INNER JOIN [DataWarehouse].[dbo].[MIHOPE_Custom_Extract_Clients] m
	  ON s.CLID = m.Clientid_NFP
			WHERE SiteID IN (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
			AND ProgramID NOT IN (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
			AND CLID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
			AND CLID IN (SELECT [Clientid_NFP] FROM [DataWarehouse].[dbo].[MIHOPE_Custom_Extract_Clients])
			AND [ProgramStartDate] < '20170101'
	  ORDER BY ProgramStartDate
	  
END

GO
