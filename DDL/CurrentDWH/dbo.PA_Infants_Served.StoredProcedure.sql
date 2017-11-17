USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[PA_Infants_Served]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[PA_Infants_Served] 
	-- Add the parameters for the stored procedure here

	@from_date varchar (25),
	@to_date varchar (25)
	
	AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	


Select CL_EN_GEN_ID into #tmpclients from

(SELECT DISTINCT CL_EN_GEN_ID
FROM         dbo.Alternative_Encounter_Survey
WHERE     SurveyDate BETWEEN @from_date AND @to_date AND SiteID IN (202, 207, 91, 198, 211, 203, 212, 215, 199, 213, 204, 214, 208, 200, 209, 240, 216, 
                      233, 248, 241, 234, 224) UNION

SELECT DISTINCT CL_EN_GEN_ID
FROM         dbo.Home_Visit_Encounter_Survey
WHERE     SurveyDate BETWEEN @from_date AND @to_date AND SiteID IN (202, 207, 91, 198, 211, 203, 212, 215, 199, 213, 204, 214, 208, 200, 209, 240, 216, 
                      233, 248, 241, 234, 224)) GO;



                      
select COUNT (INFANT_BIRTH_0_DOB) As count1, COUNT (INFANT_BIRTH_0_DOB2) as count2, COUNT (INFANT_BIRTH_0_DOB3) as count3 into #tmpinfantcount
from dbo.Infant_Birth_Survey
where INFANT_BIRTH_0_DOB <= @to_date  and CL_EN_GEN_ID in (
SELECT distinct [CL_EN_GEN_ID]
FROM #tmpclients);


select (count1 + count2 + count3) As InfantsServed
from #tmpinfantcount;


drop table #tmpclients
drop table #tmpinfantcount;

END


GO
