USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_MetricsOklahomaFamilies]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Andrew Grant
-- Create date: 1/2/2015
-- Description:	The state of OK does not use ETO, so we can't determine caseloads
--				The best we can do is figure out active clients and active nurses in a time frame
-- =============================================
CREATE PROCEDURE [dbo].[usp_MetricsOklahomaFamilies]
	@RefDate DATETIME
AS
BEGIN

	DECLARE @StartDate DateTime
	SET @StartDate = '1/1/1995'
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    DECLARE @RefDateMinus6mo DateTime
    --1 months before RefDate
	SET @RefDateMinus6mo = DATEADD(mm, -1, @RefDate)

	SELECT COUNT (DISTINCT HVE.CL_EN_GEN_ID) AS Families
	FROM Home_Visit_Encounter_Survey HVE 
	INNER JOIN UV_PAS PAS ON PAS.ProgramID = HVE.ProgramID
	WHERE PAS.[US State] = 'Oklahoma' AND SurveyDate > @RefDateMinus6Mo
END
GO
