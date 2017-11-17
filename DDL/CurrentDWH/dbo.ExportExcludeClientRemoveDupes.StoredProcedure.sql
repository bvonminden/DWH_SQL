USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[ExportExcludeClientRemoveDupes]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ExportExcludeClientRemoveDupes] 
AS
BEGIN
	
	SET NOCOUNT ON;

	--Set null ClientIDs equal to the CaseNumbers
	UPDATE [DataWarehouse].[dbo].[ExportExcludeClients]
	SET ClientID = CaseNumber
	WHERE ClientID IS NULL;

    
	--Remove duplicate records
	WITH cte AS (
	SELECT [SiteID],[ClientID],[CaseNumber],ROW_NUMBER() 
	  OVER(PARTITION BY [SiteID],[ClientID],[CaseNumber] ORDER BY [LastModified] DESC) AS [rn]
	  FROM [DataWarehouse].[dbo].[ExportExcludeClients]
	  )
	DELETE cte WHERE [rn] > 1;

END
GO
