USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_RELOAD_CLIENT_SURVEY_RESULTS 1 year]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		Robert MacKinnon
-- Create date: 01/23/2017
-- Description:	Reload datawarehouse nfp_client_survey_results_1_year from same table name in 
--              nursefamilypartnership on REM-DB5\SQLNFP_COMM 
-- =============================================
CREATE PROCEDURE [dbo].[SP_RELOAD_CLIENT_SURVEY_RESULTS 1 year]
	-- Add the parameters for the stored procedure here
	@SiteID INT 
AS
BEGIN

select distinct ItemID
into #ItemID
from [REM-B4].[DataWarehouse].[nfp_client_survey_results_1_year]

insert into [REM-B4].[DataWarehouse].[nfp_client_survey_results_1_year] (
	[ItemID],
	[ClientName],
	[ClientID],
	[NHV_Name],
	[NHV_ID],
	[DateOfReport],
	[SurveyDueDate],
	[Question1],
	[Question2],
	[Question3],
	[Question4],
	[Question5],
	[Question6],
	[Question7],
	[Question8],
	[Question9],
	[Question10],
	[Question11],
	[Question12],
	[Question13],
	[Comments],
	[AgencyName],
	[AgencyID],
	[TeamName],
	[TeamID],
	[ETO_CaseNo],
	[Passcode],
	[Status],
	[StatusDate])
select distinct [ItemID],
	[ClientName],
	[ClientID],
	[NHV_Name],
	[NHV_ID],
	[DateOfReport],
	[SurveyDueDate],
	[Question1],
	[Question2],
	[Question3],
	[Question4],
	[Question5],
	[Question6],
	[Question7],
	[Question8],
	[Question9],
	[Question10],
	[Question11],
	[Question12],
	[Question13],
	[Comments],
	[AgencyName],
	[AgencyID],
	[TeamName],
	[TeamID],
	[ETO_CaseNo],
	[Passcode],
	[Status],
	[StatusDate]
from [REM-DB5\SQLNFP_COMM].[nursefamilypartnership].[dbo].[nfp_client_survey_results_1_year] db5
where ItemID
not in (select ItemID from #ItemID)

drop table #ItemID



END



GO
