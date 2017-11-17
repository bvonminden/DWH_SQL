USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISDUA_MIHOPE_Custom_StaffxClientHx]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Jingjing
-- Create date: 03/10/2017
-- Export Requirements:
-- 1)	De-identified data for customer
-- 2)	Provide the same data set with identifiable data on the S drive for the NSO
-- 3)	Join with MIHOPE provided table to provide the MIHOPE ID with the corresponding NSO ID (which will be hashed)
-- 4)	We need to provide a table so they can cross reference EntityID with Nurse Name 
-- 5)	Parameter on the export – no SurveyDates or ProgramStartDates after 12/31/2016
-- 6)	Parameter on the export – only data from the following siteIDs and only data for the provided CLID/CL_EN_GENs/ClientId (SiteIDs: 289, 179, 185, 103, 163, 212, 251, 287)
-- =============================================
CREATE PROCEDURE [dbo].[SSISDUA_MIHOPE_Custom_StaffxClientHx]
	-- Add the parameters for the stored procedure here
	@ProfileID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
SELECT [StaffxClientID]
      ,[StaffID]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLID])) AS[CLID]
      ,StudyID
      ,[ProgramID]
      ,[StartDate]
      ,[EndDate]
      ,[AuditStaffID]
      ,[AuditDate]
      ,[DataSource]
      ,[Entity_ID]
      ,[LastModified]
  FROM [DataWarehouse].[dbo].[StaffxClientHx] s
			  INNER JOIN [DataWarehouse].[dbo].[MIHOPE_Custom_Extract_Clients] m
      ON s.CLID = m.Clientid_NFP
	 where [CLID] IN (SELECT [Clientid_NFP] FROM [DataWarehouse].[dbo].[MIHOPE_Custom_Extract_Clients])
	 and ProgramID NOT IN (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = 52)
	   AND [CLID] NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID in (SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = 52 AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1))
	   

END


GO
