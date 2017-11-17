USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISDUA_Transfers]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Jingjing Gao
-- Create date: 10/07/2016
-- Description:	Extract of AgencyProfile data where the SiteID from Agency_Profile_Survey is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSISDUA_Transfers]
	@ProfileID INT
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT [TransferID]
      ,[Datasource]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLReferralID])) AS [CLReferralID]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLID])) AS [CLID]
      ,[ProgramID_From]
      ,[ReferredTo]
      ,[EntityID]
      ,[TargetSiteID]
      ,[TargetProgramID]
      ,[ReferralDate]
      ,[DateReferralClosed]
      ,[ReasonForDismissal]
      ,[ReasonForReferral]
      ,[CLReferralHxID]
      ,[ReferralStatus]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[Notes])) AS [Notes]
      ,[TimeSpentonReferral]
      ,[AuditStaffID]
      ,[AuditDate]
      ,[DW_TableName]
      ,[DW_AuditDate]
      ,[Datasource_ID]
  FROM [DataWarehouse].[dbo].[Transfers] s
	WHERE TargetSiteID IN(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
	  AND ProgramID_From not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	  AND CLID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.TargetSiteID)

END


GO
