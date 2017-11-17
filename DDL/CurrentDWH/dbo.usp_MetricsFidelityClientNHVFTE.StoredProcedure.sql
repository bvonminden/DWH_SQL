USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_MetricsFidelityClientNHVFTE]    Script Date: 11/16/2017 10:44:32 AM ******/
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
CREATE PROCEDURE [dbo].[usp_MetricsFidelityClientNHVFTE]
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
	
	--DECLARE @EndDate As DATE = CAST('1/1/2014' AS DATE);--CAST(GETDATE() AS DATE);
    DECLARE @FirstDayOfMonth DATETIME
    
	--First day of month containing RefDate
	SET @FirstDayOfMonth = DATEADD(dd, -(DAY(@RefDate)-1), @RefDate)
	
CREATE TABLE #FID_Staff(USState VARCHAR(50), SumFTE_curr NUMERIC, CountNHV2_curr NUMERIC )

INSERT INTO #FID_Staff(USState, SumFTE_curr, CountNHV2_curr)
-- Adapted from fn_Fidelity_Staff_El12 
	SELECT 
	dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
	,(SUMScurr.SumFTE) SumFTE_curr
		--,(SUMScurr.CountNHV) CountNHV_curr
		,(SUMScurr.CountNHV2) CountNHV2_curr
		--,(SUMScurr.SumClients) SumClients_curr
		--,(SUMScurr.MissingFTE) MissingFTE_curr
		--,(SUMScurr.MissingPosition) MissingPosition_curr
		FROM
		(SELECT DISTINCT ProgramID,Entity_Id
		FROM dbo.fn_FID_Staff_list (@FirstDayOfMonth,@LastDayOfMonth)) ROOT

		INNER JOIN UV_PAS P
			ON (ROOT.ProgramID = P.Program_ID_NHV
			OR ROOT.ProgramID = P.Program_ID_Referrals
			OR ROOT.ProgramID = P.Program_ID_Staff_Supervision)
		
		LEFT OUTER JOIN
		(SELECT 
			DATA1.ProgramID,DATA1.Entity_Id
			,(DATA1.HV_FTE) SumFTE
			,(CASE WHEN (DATA1.NHV_Flag = 1 OR ISNULL(DATA1.HV_FTE,0) > 0) THEN DATA1.Entity_Id END) CountNHV
			,(CASE WHEN (DATA1.NHV_Flag = 1 ) THEN DATA1.Entity_Id END) CountNHV2
			,(CASE WHEN (DATA1.NHV_Flag = 1 OR ISNULL(DATA1.HV_FTE,0) > 0) THEN DATA1.Clients END) SumClients
			,(CASE WHEN DATA1.NHV_Flag = 1 AND ISNULL(DATA1.HV_FTE,0) = 0 THEN DATA1.Entity_Id END) MissingFTE
			,(CASE WHEN DATA1.HV_FTE > 0 AND ISNULL(DATA1.NHV_Flag,0) = 0 THEN DATA1.Entity_Id END) MissingPosition
		FROM
			(SELECT s.*,cl.Clients,CL.EntityID,CL.StaffID
			FROM dbo.fn_FID_Staff_list (@FirstDayOfMonth,@LastDayOfMonth) S
			
			LEFT OUTER JOIN
				(SELECT 
					SC.StaffID
					,SE.EntityID
					,SC.ProgramID
					,COUNT(DISTINCT SC.CLID) Clients
				FROM StaffxClientHx SC
					INNER JOIN StaffXEntities SE
						ON SC.StaffID = SE.StaffID
				WHERE ISNULL(SC.EndDate,@LastDayOfMonth) > @FirstDayOfMonth
					AND SC.StartDate <= @LastDayOfMonth
				GROUP BY SC.StaffID,SC.ProgramID,SE.EntityID) CL
				ON S.Entity_Id = CL.EntityID
					AND CL.ProgramID IN (S.Program_ID_NHV,S.Program_ID_Referrals,S.Program_ID_Staff_Supervision)
					
			WHERE S.EndDate IS NULL OR S.EndDate > @LastDayOfMonth) DATA1
			--GROUP BY DATA1.ProgramID,DATA1.Entity_Id
			) SUMSCurr
		ON P.ProgramID = SUMSCurr.ProgramID
		AND SUMSCurr.Entity_Id = ROOT.Entity_Id

		UNION

		SELECT 
			dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
			,NULL
			,NULL
		FROM UV_PAS P
	
;WITH US_STATE AS     
(
	SELECT DISTINCT PAS.Abbreviation Abbr
	FROM UV_PAS PAS
), 

FidClientTeams AS
(
--For now just get one loop of the function.  Later we'll need trend data so we'll loop through 12 or more times.
SELECT DISTINCT FSEC.clients ClientCount,FSEC.ProgramID, FSEC.SiteID , FSEC.StateID, PAS.Abbreviation Abbr FROM fn_Fidelity_Staff_El12_Clients(@FirstDayOfMonth, @LastDayOfMonth , 1) AS FSEC
INNER JOIN UV_PAS PAS ON PAS.StateID = FSEC.StateID
),

FidClientState AS
(
	SELECT FCT.Abbr Abbr, SUM(FCT.ClientCount) ClientCount
	FROM FidClientTeams FCT
	GROUP BY FCT.Abbr
),

NHVFTE AS
(
	SELECT USState, SUM(SumFTE_curr) SumFTE
	FROM #FID_Staff	
	GROUP BY USState
	--WHERE SUMFTE_curr IS NOT NULL
),

NHVCount AS 
(
	SELECT USState, COUNT(CountNHV2_curr) CountNHV
	FROM #FID_Staff	
	WHERE CountNHV2_curr IS NOT NULL
	GROUP BY USState
	
)

SELECT ST.Abbr, FCS.ClientCount, FTE.SumFTE, CT.CountNHV
FROM US_STATE ST 
INNER JOIN FidClientState FCS ON FCS.Abbr = ST.Abbr
INNER JOIN NHVFTE FTE ON FTE.USState = ST.Abbr
INNER JOIN NHVCount CT ON CT.USState = ST.Abbr
ORDER BY ST.Abbr
END


GO
