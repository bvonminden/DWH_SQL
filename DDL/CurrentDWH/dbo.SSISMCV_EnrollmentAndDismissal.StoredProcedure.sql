USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISMCV_EnrollmentAndDismissal]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Michael Osborn
-- Create date: 2/15/2015
-- Description:	Extract of MICHVEI data where the SiteID from the Survey is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing Gao
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSISMCV_EnrollmentAndDismissal]
	-- Add the parameters for the stored procedure here
	@ProfileID INT
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT [RecID]
		  ,[CLID]
		  ,[SourceTable]
		  ,[SiteID]
		  ,[ProgramID]
		  ,[ProgramStartDate]
		  ,[EndDate]
		  ,[TerminationReasonID]
		  ,[ReasonForDismissalID]
		  ,[ReasonForDismissal]
		  ,[Disabled]
		  ,[AuditStaffID]
		  ,[AuditDate]
		  ,[ProgramSpecific]
		  ,[EmploymentSpecific]
		  ,[EducationSpecific]
		  ,[RejectionSpecific]
		  ,[MatchSpecific]
		  ,[SequenceOrder]
		  ,[ReasonForDismissalID_Source]
		  ,[SourceReasonForDismissalID]
		  ,[CaseNumber]
		  ,[DataSource]
		  ,[SourceTableID]
		  ,[LastModified]
	FROM  [DataWarehouse].[dbo].[EnrollmentAndDismissal] s
	WHERE s.CLID in (select CL_EN_GEN_ID from View_MIECHVP_Cleints 
						   where siteid in(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ISNULL(ExportDisabled,0) != 1))
	AND s.ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
	AND s.CLID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
  
END

GO
