USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_MetricsActiveClient]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Andrew Grant
-- Create date: 12/24/2014
-- Description:	Per the requirements, I used the definition of "Active" Clients from the report "Active Clients by Agency and State". 
-- That report defines "Active" Client as a client with a home visit prior to the @enddate (@RefDate), with a program start date prior to the @enddate,
-- and a Program EndDate after the @enddate.  It doesn't check for clients with null Program EndDates, because this field is calculated to be exactly two years
-- after the child's DOB.
-- =============================================
CREATE PROCEDURE [dbo].[usp_MetricsActiveClient]
	-- Add the parameters for the stored procedure here
	@RefDate DATETIME
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    --DECLARE @EndDate As DATE = CAST('1/1/2014' AS DATE);--CAST(GETDATE() AS DATE);
    DECLARE @LastDayOfMonth DATETIME

	----Last Day of Month containing the @RefDate
	SET @LastDayOfMonth = DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,@RefDate)+1,0))
    
	
;WITH HV2 AS
(
				SELECT 
						H.CL_EN_GEN_ID
						,MAX(H.SurveyDate) LastVisit
						,MIN(H.SurveyDate) FirstVisit
						,H.ProgramID
					FROM DataWarehouse..UV_HVES H
					WHERE H.SurveyDate < = @LastDayOfMonth
					GROUP BY H.CL_EN_GEN_ID, H.ProgramID
				)

	
	
SELECT 
	--EAD.CaseNumber,
	--EAD.CLID,
	--EAD.ProgramID
	--,
	A.State
	,COUNT(*) AS ClientCount
	--,C.First_Name
	--,C.Last_Name
	--,MAX(EAD.ProgramStartDate) MostRecentProgStartDate
	--,MIN(HV2.FirstVisit) FirstVisit
	--,MAX(HV2.LastVisit) LastVisit
	--,MAX(IBS.INFANT_BIRTH_0_DOB) INFANT_BIRTH_0_DOB
	--,DATEDIFF(D,MAX(IBS.INFANT_BIRTH_0_DOB),@LastDayOfMonth) InfantAge
	--,PAS.ProgramName MostRecentSite
	--,MAX(EAD.EndDate) LatestEndDate
	--,A.AGENCY_INFO_0_NAME [Agency]
	--,A.State [Agency's State]
	
		
FROM DataWarehouse..AC_Dates AC
	INNER JOIN DataWarehouse..UV_EADT EAD
		ON EAD.CLID = AC.CLID
		AND EAD.ProgramID = AC.ProgramID
		AND EAD.RankingLatest = 1
	INNER JOIN DataWarehouse..ProgramsAndSites PAS
		ON PAS.ProgramID = EAD.ProgramID 
	LEFT JOIN HV2
		ON HV2.CL_EN_GEN_ID = EAD.CLID
		AND HV2.ProgramID = EAD.ProgramID
	INNER JOIN DataWarehouse..Agencies A
		ON A.Site_ID = PAS.SiteID
	LEFT JOIN DataWarehouse..Infant_Birth_Survey IBS
		ON IBS.CL_EN_GEN_ID = EAD.CLID
	LEFT JOIN DataWarehouse..Clients C
		ON C.Client_Id = EAD.CLID

WHERE AC.ProgramStartDate <= @LastDayOfMonth
	AND AC.EndDate > @LastDayOfMonth		
GROUP BY 	
	--EAD.CaseNumber,
	--EAD.CLID,
	--EAD.ProgramID
	--,
	A.State
	--,C.First_Name
	--,C.Last_Name
	--,PAS.ProgramName 
	--,A.AGENCY_INFO_0_NAME 
	--,A.State 
		
	
Order By A.State
END


GO
