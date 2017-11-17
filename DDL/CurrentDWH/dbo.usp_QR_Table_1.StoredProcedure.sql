USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_QR_Table_1]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_QR_Table_1] 
	-- Add the parameters for the stored procedure here
	@Quarter INT 
	,@QuarterYear INT 
	,@ReportType VARCHAR(50)
	,@State VARCHAR(5)
	,@AgencyID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.


    -- Insert statements for procedure here
DECLARE @QuarterDate VARCHAR(50) 
SET @QuarterDate =	(
						CASE 
							WHEN @Quarter = 1 THEN '3/31/'+CAST(@QuarterYear AS VARCHAR(4)) 
							WHEN @Quarter = 2 THEN '6/30/'+CAST(@QuarterYear AS VARCHAR(4)) 
							WHEN @Quarter = 3 THEN '9/30/'+CAST(@QuarterYear AS VARCHAR(4)) 
							WHEN @Quarter = 4 THEN '12/31/'+CAST(@QuarterYear AS VARCHAR(4)) 
						END
					)
DECLARE @QuarterStart DATE SET @QuarterStart = DATEADD(DD,1,DATEADD(M,-3,CAST(@QuarterDate AS DATE))) 

IF OBJECT_ID('dbo.UC_QR_Table_1_MOTEST', 'U') IS NOT NULL DROP TABLE dbo.UC_QR_Table_1

SET QUOTED_IDENTIFIER ON
SET NOCOUNT ON;
WITH HV2 AS
(
SELECT 
		H.CL_EN_GEN_ID
		,MAX(H.SurveyDate) LastVisit
		,MIN(H.SurveyDate) FirstVisit
		,H.ProgramID
	FROM DataWarehouse..UV_HVES H
	WHERE H.SurveyDate < = @QuarterDate
	GROUP BY H.CL_EN_GEN_ID, H.ProgramID
)

	
	
SELECT 
	DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID) [State]
	,PAS.SITE
	,PAS.SiteID,MAX(CASE WHEN PAS.ProgramName LIKE '%BRONX%' AND A.State = 'NY' THEN 1 END) [VNS]
	,DataWarehouse.dbo.udf_fn_GetCleanProg(PAS.ProgramID) ProgramName
	,@Quarter [Quarter]
	,@QuarterDate [QuarterDate]
	,@QuarterStart [QuarterStart]
	,@QuarterYear [QuarterYear]
	,CASE
		WHEN @ReportType = 'National' THEN 1
	END [National]
	,COUNT(DISTINCT CASE
			WHEN EAD.RankingOrig = 1 
				AND EAD.ProgramStartDate BETWEEN @QuarterStart AND @QuarterDate
			THEN EAD.CLID
		END) [New Clients Enrolled]
	,ISNULL(COUNT(DISTINCT
				CASE
					WHEN EAD.CLID <> EAD.CaseNumber
						AND EAD.RankingLatest = 1
						AND EAD.RankingOrig > 1
						AND EAD3.EndDate > = @QuarterStart

							AND ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
					THEN EAD.CLID
				END) 
		,0) [Clients Transferred In]
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN DATEDIFF(DD,EAD.ProgramStartDate,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD) > 161
					AND MHS.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
					AND EAD.ProgramStartDate BETWEEN @QuarterStart AND @QuarterDate
					--AND EAD2.CLID IS NULL

							AND ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
				THEN EAD.CLID
			END
		),0) [Enrolled by 16 Weeks Gestation]
	,ISNULL(COUNT(DISTINCT
			CASE
				WHEN IBS.INFANT_BIRTH_0_DOB BETWEEN @QuarterStart AND @QuarterDate
					AND EAD.RankingLatest =1
					--AND EAD2.CLID IS NULL

							AND ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
				THEN EAD.CLID
			END
		),0) + ISNULL(COUNT(DISTINCT CASE
						WHEN IBS.INFANT_BIRTH_0_DOB BETWEEN @QuarterStart AND @QuarterDate
							AND IBS.INFANT_0_ID_NSO2 IS NOT NULL
							AND EAD.RankingLatest =1
							--AND EAD2.CLID IS NULL

							AND ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
						THEN EAD.CLID
					  END
					),0) + ISNULL(COUNT(DISTINCT CASE
									WHEN IBS.INFANT_BIRTH_0_DOB BETWEEN @QuarterStart AND @QuarterDate
										AND IBS.INFANT_0_ID_NSO3 IS NOT NULL
										AND EAD.RankingLatest =1
										--AND EAD2.CLID IS NULL

							AND ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
									THEN EAD.CLID
								  END
								),0) [Babies Born]
	,COUNT(DISTINCT
				CASE
					WHEN DataWarehouse.dbo.udf_ClientGraduated(@QuarterDate,EAD.CLID) = 1

							AND ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
					THEN EAD.CLID
				END) [Clients Graduated]
	,COUNT(DISTINCT 
				CASE 
					WHEN EAD.CLID = EAD.CaseNumber
						AND EAD.CLID <> EAD2.CLID
						AND EAD.RankingOrig = 1
						AND EAD.RankingLatest > 1
						AND EAD.ProgramID <> EAD2.ProgramID
						AND EAD.EndDate BETWEEN @QuarterStart AND @QuarterDate

							AND ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
					THEN EAD.CLID 
				END) [Clients Transferred Out]
	,ISNULL(COUNT(DISTINCT
					CASE
					WHEN ((EAD.EndDate BETWEEN @QuarterStart AND @QuarterDate
						AND	EAD.ReasonForDismissal NOT LIKE '%2%' )
						OR	((DATEDIFF(DAY,EDD.EDD,EAD.EndDate)) < 700
							AND	(EAD.ReasonForDismissal IS NULL
								AND DATEDIFF(DAY,(HVES.SurveyDate),@QuarterDate) > 180)))

							AND ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
						THEN EAD.CLID
					END
				),0)  [Clients Who Left Early]
	,ISNULL(COUNT(DISTINCT
					CASE
					WHEN HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate

							AND ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
					THEN EAD.CLID
					END
				),0) [Clients Served]
				
				
	,ISNULL(COUNT(DISTINCT CASE
					WHEN IBS.INFANT_BIRTH_0_DOB IS NOT NULL
						AND HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate

							AND ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
					THEN EAD.CLID
					END
				),0) + ISNULL(COUNT(DISTINCT CASE
						WHEN IBS.INFANT_BIRTH_0_DOB IS NOT NULL
							AND IBS.INFANT_0_ID_NSO2 IS NOT NULL
							AND HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate

							AND ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
						THEN EAD.CLID
					  END
					),0) + ISNULL(COUNT(DISTINCT CASE
									WHEN IBS.INFANT_BIRTH_0_DOB IS NOT NULL
										AND IBS.INFANT_0_ID_NSO3 IS NOT NULL
										AND HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate

							AND ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
									THEN EAD.CLID
								  END
								),0) [Babies Served]
	,ISNULL(COUNT(DISTINCT 
				CASE WHEN AC.ProgramStartDate < = @QuarterDate
						AND AC.EndDate > @QuarterDate
						AND EAD.RankingLatest = 1

							AND ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
					THEN AC.CLID
					END),0) [Active Clients at the End of the Quarter]
	,ISNULL(SUM(
					CASE
						WHEN	(
									EDD.EDD IS NULL 
									OR EDD.EDD > HVES.SurveyDate
								)

							AND HVES.CLIENT_COMPLETE_0_VISIT = 'Completed'
							AND HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
							AND HVES.Form = 'Home Visit'

							AND ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
						THEN 1
					END
				),0) [Visits During Pregnancy]
	,ISNULL(SUM(
					CASE
						WHEN DATEDIFF(DAY,EDD.EDD,HVES.SurveyDate) BETWEEN 0 AND 365.25
							AND HVES.CLIENT_COMPLETE_0_VISIT = 'Completed'
							AND HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
							AND HVES.Form = 'Home Visit'
							AND EDD.EDD IS NOT NULL
							AND HVES.SurveyDate >= EDD.EDD

							AND ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
						THEN 1
					END
				),0) [Visits During Infancy]
	,ISNULL(SUM(
					CASE
						WHEN DATEDIFF(DAY,EDD.EDD,HVES.SurveyDate) >= 365.25
							AND HVES.CLIENT_COMPLETE_0_VISIT = 'Completed'
							AND HVES.SurveyDate BETWEEN @QuarterStart AND @QuarterDate
							AND HVES.Form = 'Home Visit'
							AND EDD.EDD IS NOT NULL
							AND HVES.SurveyDate > EDD.EDD

							AND ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart

						THEN 1
					END
				),0) [Visits During Toddlerhood]
	,[CLIENT_TRIBAL_0_PARITY]
	
INTO UC_QR_Table_1
FROM DataWarehouse..UV_EADT EAD
	
	LEFT JOIN DataWarehouse..UV_EADT EAD2
		ON EAD2.CaseNumber = EAD.CaseNumber
		AND EAD2.RankingLatest = 1
		AND EAD2.ProgramStartDate < = @QuarterDate 
	LEFT JOIN DataWarehouse..UV_EADT EAD3
		ON EAD3.CaseNumber = EAD.CaseNumber
		AND EAD3.RankingLatest > 1
		AND EAD3.EndDate BETWEEN @QuarterStart AND @QuarterDate 
	INNER JOIN DataWarehouse..UV_EADT E2
		ON E2.CaseNumber = EAD.CaseNumber
		AND E2.RankingOrig = 1
	INNER JOIN DataWarehouse..UV_PAS PAS
		ON PAS.ProgramID = EAD.ProgramID 
	INNER JOIN DataWarehouse..Agencies A
		ON A.Site_ID = PAS.SiteID
	LEFT JOIN DataWarehouse..Maternal_Health_Survey MHS
		ON MHS.CL_EN_GEN_ID = EAD.CLID
		AND MHS.SurveyDate < = @QuarterDate
	LEFT JOIN DataWarehouse..Infant_Birth_Survey IBS
		ON IBS.CL_EN_GEN_ID = EAD.CLID
		AND IBS.SurveyDate < = @QuarterDate
	LEFT JOIN DataWarehouse..UV_HVES HVES
		ON HVES.CL_EN_GEN_ID = EAD.CLID
		AND HVES.SurveyDate < = @QuarterDate
	LEFT JOIN DataWarehouse..UV_EDD EDD
		ON EDD.CaseNumber = EAD.CaseNumber	
	LEFT JOIN HV2
		ON HV2.CL_EN_GEN_ID = EAD.CLID
		AND HV2.ProgramID = EAD.ProgramID
	LEFT JOIN DataWarehouse..UC_Client_Exclusion_YWCA YWCA 
		ON YWCA.CLID = EAD.CLID AND PAS.SiteID = 222
	LEFT JOIN DataWarehouse..Tribal_Survey TS
		ON TS.CL_EN_GEN_ID = EAD.CLID
		AND TS.ProgramID = EAD.ProgramID
	LEFT JOIN DataWarehouse..AC_Dates AC
		ON AC.CLID = EAD.CLID 
		AND AC.ProgramID = EAD.ProgramID
WHERE
	YWCA.CLID IS NULL
	--AND ISNULL(EAD.EndDate,GETDATE()) > @QuarterStart
	AND EAD.ProgramStartDate < = @QuarterDate 
	--AND (TS.CLIENT_TRIBAL_0_PARITY LIKE '%PRIMIP%' OR TS.CLIENT_TRIBAL_0_PARITY IS NULL)
	--AND ead.SiteID = 345
GROUP BY 	DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID)
	,PAS.Site
	,PAS.SiteID
	,DataWarehouse.dbo.udf_fn_GetCleanProg(PAS.ProgramID) 
	--,PAS.SiteID
	,EAD.ProgramID
	,[CLIENT_TRIBAL_0_PARITY]

UNION ALL

SELECT DISTINCT
	DataWarehouse.dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
	,P.SITE
	,P.SiteID
	,(CASE WHEN P.ProgramName LIKE '%BRONX%' AND P.Abbreviation = 'NY' THEN 1 END) [VNS]
	,DataWarehouse.dbo.udf_fn_GetCleanProg(P.ProgramID) ProgramName
	,@Quarter [Quarter]
	,@QuarterDate [QuarterDate]
	,@QuarterStart [QuarterStart]
	,@QuarterYear [QuarterYear]
	,CASE
		WHEN @ReportType = 'National' THEN 1
	END [National]
	,0,0,0,0,0,0,0,0,0,0,0,0,0,NULL
	
FROM DataWarehouse..UV_PAS P
	--INNER JOIN DataWarehouse..Tribal_Survey T
	--	ON T.SiteID = P.SiteID	
	--	AND T.CLIENT_TRIBAL_0_PARITY IS NOT NULL
--WHERE p.SiteID = 345
UNION ALL

SELECT DISTINCT
	DataWarehouse.dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
	,P.SITE
	,P.SiteID
	,(CASE WHEN P.ProgramName LIKE '%BRONX%' AND P.Abbreviation = 'NY' THEN 1 END) [VNS]
	,DataWarehouse.dbo.udf_fn_GetCleanProg(P.ProgramID) ProgramName
	,@Quarter [Quarter]
	,@QuarterDate [QuarterDate]
	,@QuarterStart [QuarterStart]
	,@QuarterYear [QuarterYear]
	,CASE
		WHEN @ReportType = 'National' THEN 1
	END [National]
	,0,0,0,0,0,0,0,0,0,0,0,0,0,'Multiparous (pregnant with a second or subsequent child)'
	
FROM DataWarehouse..UV_PAS P
	INNER JOIN DataWarehouse..Tribal_Survey T
		ON T.SiteID = P.SiteID	
		AND T.CLIENT_TRIBAL_0_PARITY IS NOT NULL
--WHERE p.SiteID = 345		
UNION ALL

SELECT DISTINCT
	DataWarehouse.dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
	,P.SITE
	,P.SiteID
	,(CASE WHEN P.ProgramName LIKE '%BRONX%' AND P.Abbreviation = 'NY' THEN 1 END) [VNS]
	,DataWarehouse.dbo.udf_fn_GetCleanProg(P.ProgramID) ProgramName
	,@Quarter [Quarter]
	,@QuarterDate [QuarterDate]
	,@QuarterStart [QuarterStart]
	,@QuarterYear [QuarterYear]
	,CASE
		WHEN @ReportType = 'National' THEN 1
	END [National]
	,0,0,0,0,0,0,0,0,0,0,0,0,0,'Primiparous (pregnant with her first child)'
	
FROM DataWarehouse..UV_PAS P
	INNER JOIN DataWarehouse..Tribal_Survey T
		ON T.SiteID = P.SiteID	
		AND T.CLIENT_TRIBAL_0_PARITY IS NOT NULL
--WHERE p.SiteID = 345	
--OPTION(RECOMPILE)
END

--exec [dbo].[usp_QR_DatePrep]
--select * from UC_QR_Table_1
--select * from UV_ReportAutomation_QR

GO
