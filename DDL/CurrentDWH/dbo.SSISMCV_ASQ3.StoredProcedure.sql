USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISMCV_ASQ3]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	Extract of ASQ  data where the SiteID from ASQ_Survey is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- =============================================
CREATE PROCEDURE [dbo].[SSISMCV_ASQ3]
	-- Add the parameters for the stored procedure here
	@ProfileID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--DECLARE @ProfileID AS INT
--SET @ProfileID = 27

SELECT [SurveyResponseID]
		  ,[ElementsProcessed]
		  ,[SurveyID]
		  ,[SurveyDate]
		  ,[AuditDate]
		  ,[CL_EN_GEN_ID]
		  ,[SiteID]
		  ,[ProgramID]
		  ,[IA_StaffID]
		  ,[ClientID]
		  ,[RespondentID]
		  ,[DW_AuditDate]
		  ,[DataSource]
		  ,[INFANT_HEALTH_NO_ASQ_COMM]
		  ,[INFANT_HEALTH_NO_ASQ_FINE]
		  ,[INFANT_HEALTH_NO_ASQ_GROSS]
		  ,[INFANT_HEALTH_NO_ASQ_PERSONAL]
		  ,[INFANT_HEALTH_NO_ASQ_PROBLEM]
		  ,[CLIENT_0_ID_AGENCY]
		  ,[CLIENT_0_ID_NSO]
		  ,[CLIENT_PERSONAL_0_NAME_FIRST]
		  ,[CLIENT_PERSONAL_0_NAME_LAST]
		  ,[INFANT_0_ID_NSO]
		  ,[INFANT_PERSONAL_0_NAME_FIRST]
		  ,[INFANT_PERSONAL_0_NAME_LAST]
		  ,[INFANT_AGES_STAGES_1_COMM]
		  ,[INFANT_AGES_STAGES_1_FMOTOR]
		  ,[INFANT_AGES_STAGES_1_GMOTOR]
		  ,[INFANT_AGES_STAGES_1_PSOCIAL]
		  ,[INFANT_AGES_STAGES_1_PSOLVE]
		  ,[INFANT_BIRTH_0_DOB]
		  ,[NURSE_PERSONAL_0_NAME]
		  ,[Master_SurveyID]
FROM [DataWarehouse].[dbo].[ASQ3_Survey] s
where CL_EN_GEN_ID in (select CL_EN_GEN_ID from View_MIECHVP_Cleints 
                       where siteid in(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ISNULL(ExportDisabled,0) != 1))
and ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID)
AND CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
  
END

GO
