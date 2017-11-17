USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISDUA_MIHOPE_Custom_Clients]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Jingjing
-- Create date: 03/10/2017
-- Description:	Extract of Client data where the SiteID from Clients is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- Export Requirements:
-- 1)	De-identified data for customer
-- 2)	Provide the same data set with identifiable data on the S drive for the NSO
-- 3)	Join with MIHOPE provided table to provide the MIHOPE ID with the corresponding NSO ID (which will be hashed)
-- 4)	We need to provide a table so they can cross reference EntityID with Nurse Name 
-- 5)	Parameter on the export – no SurveyDates or ProgramStartDates after 12/31/2016
-- 6)	Parameter on the export – only data from the following siteIDs and only data for the provided CLID/CL_EN_GENs/ClientId (SiteIDs: 289, 179, 185, 103, 163, 212, 251, 287)
-- =============================================
CREATE PROCEDURE [dbo].[SSISDUA_MIHOPE_Custom_Clients]
	-- Add the parameters for the stored procedure here
	@ProfileID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT DISTINCT HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),c.[Client_Id])) AS [Client_Id]
		  ,c.[Site_ID]
		  ,StudyID
		  ,c.[INFANT_BIRTH_0_DOB]
	FROM dbo.Clients c
	
    INNER JOIN [DataWarehouse].[dbo].[MIHOPE_Custom_Extract_Clients] m
	ON c.Client_Id = m.Clientid_NFP
	WHERE c.Site_ID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	AND c.Client_Id NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = c.Site_ID)
	AND c.Client_Id IN (SELECT [Clientid_NFP] FROM [DataWarehouse].[dbo].[MIHOPE_Custom_Extract_Clients])

END

GO
