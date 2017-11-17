USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISMCVDUA_TX2Mos]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Sheri Scott
-- Create date: 6/29/2016
-- Description:	Extract of MICHVEI data where the SiteID from the Survey is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- *********************************************
-- Modified by: Jingjing
-- Modified Date: 11/29/2016
-- Decription: Change it from "select ClientID from dbo.ExportExcludeClients" to "select ISNULL(ClientID,'') from dbo.ExportExcludeClients" 
--			   since the ClientID could be NULL which will affect the data extract pulling data from data warehouse and result in blank files in some 
--             recipients folders.
-- *********************************************
-- Modified by: Jingjing Gao
-- Modified Date: 1/4/2017
-- Description: Three columns are removed from "[dbo].[TX_SupMiechv2mo_AgencySurvey]":
-- MIECHV_PFS_FAMILY_2MO_PP, 
-- MIECHV_PFS_SOCIAL_2MO_PP, 
-- MIECHV_PFS_CONCRETE_2MO_PP
-- Store procedure is modified accordingly.
-- =============================================
CREATE PROCEDURE [dbo].[SSISMCVDUA_TX2Mos]
	@ProfileID INT
AS
BEGIN
	
	SET NOCOUNT ON;

  SELECT [SurveyResponseID]
      ,[ElementsProcessed]
      ,[SurveyID]
      ,[Master_SurveyID]
      ,[SurveyDate]
      ,[AuditDate]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CL_EN_GEN_ID])) AS [CL_EN_GEN_ID]
      ,[SiteID]
      ,[ProgramID]
      ,[IA_StaffID]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[ClientID])) AS [ClientID]
      ,[RespondentID]
      ,[DW_AuditDate]
      ,[DataSource]
      ,[MIECHV_READ_12MO_PP_1]
      ,[MIECHV_READ_12MO_PP_2]
      ,[MIECHV_READ_12MO_PP_3]
      ,[MIECHV_READ_2MO_PP_1]
      ,[MIECHV_READ_2MO_PP_2]
      ,[MIECHV_READ_2MO_PP_3]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_NSO])) AS [CLIENT_0_ID_NSO]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_FIRST])) AS [CLIENT_PERSONAL_0_NAME_FIRST]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_PERSONAL_0_NAME_LAST])) AS [CLIENT_PERSONAL_0_NAME_LAST]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[MIECHV_READ_IID_12MO_PP_1])) AS [MIECHV_READ_IID_12MO_PP_1]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[MIECHV_READ_IID_12MO_PP_2])) AS [MIECHV_READ_IID_12MO_PP_2]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[MIECHV_READ_IID_12MO_PP_3])) AS [MIECHV_READ_IID_12MO_PP_3]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[MIECHV_READ_IID_2MO_PP_1])) AS [MIECHV_READ_IID_2MO_PP_1]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[MIECHV_READ_IID_2MO_PP_2])) AS [MIECHV_READ_IID_2MO_PP_2]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[MIECHV_READ_IID_2MO_PP_3])) AS [MIECHV_READ_IID_2MO_PP_3]
      ,HASHBYTES('SHA1',CONVERT(NVARCHAR(4000),[CLIENT_0_ID_AGENCY])) AS [CLIENT_0_ID_AGENCY]
      ,[MIECHV_PFS_CHILD_DEV_12_12MO_PP]
      ,[MIECHV_PFS_CHILD_DEV_12_2MO_PP]
      ,[MIECHV_PFS_CHILD_DEV_13_12MO_PP]
      ,[MIECHV_PFS_CHILD_DEV_13_2MO_PP]
      ,[MIECHV_PFS_CHILD_DEV_14_12MO_PP]
      ,[MIECHV_PFS_CHILD_DEV_14_2MO_PP]
      ,[MIECHV_PFS_CHILD_DEV_15_12MO_PP]
      ,[MIECHV_PFS_CHILD_DEV_15_2MO_PP]
      ,[MIECHV_PFS_CHILD_DEV_16_12MO_PP]
      ,[MIECHV_PFS_CHILD_DEV_16_2MO_PP]
      ,[MIECHV_PFS_CONCRETE_12MO_PP]
      --,[MIECHV_PFS_CONCRETE_2MO_PP]	/***Delete column on 1/4/2017****/
      ,[MIECHV_PFS_FAMILY_12MO_PP]
      --,[MIECHV_PFS_FAMILY_2MO_PP]		/***Delete column on 1/4/2017****/
      ,[MIECHV_PFS_NURTURE_12MO_PP]
      ,[MIECHV_PFS_NURTURE_2MO_PP]
      ,[MIECHV_PFS_SOCIAL_12MO_PP]
      --,[MIECHV_PFS_SOCIAL_2MO_PP]		/***Delete column on 1/4/2017****/
      ,[MIECHV_SUPPORTED_BY_INCOME_12MO_PP]
      ,[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,[NURSE_PERSONAL_0_NAME]
      ,[TX_FUNDING_SOURCE_2MO_PP]
  FROM [DataWarehouse].[dbo].[TX_SupMiechv2mo_AgencySurvey] s
  WHERE CL_EN_GEN_ID NOT IN (select ISNULL(ClientID,'') from dbo.ExportExcludeClients where SiteID = s.SiteID)
	
END
GO
