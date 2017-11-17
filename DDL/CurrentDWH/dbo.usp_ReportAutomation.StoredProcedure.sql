USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_ReportAutomation]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_ReportAutomation]
(@ReportName INT, @EndDate DATE)

AS


--DECLARE @ReportName INT, @EndDate DATE
--SET @ReportName = 1
--SET @EndDate = CAST('3/31/2014' AS DATE)

SELECT

p.*
,Param.*
,CASE @ReportName WHEN 7 THEN 'CSV' WHEN 6 THEN 'WORD' ELSE 'PDF' END ReportFormat

,'/IT Reports/' + CASE
				WHEN @ReportName = 1 THEN 'Fidelity'
				WHEN @ReportName = 2 THEN 'CSE'
				WHEN @ReportName = 3 THEN 'Outcome'
				WHEN @ReportName = 4 THEN 'Quarterly Reports'
				WHEN @ReportName = 5 THEN 'MIECHV Testing Folder'
				WHEN @ReportName = 6 THEN 'Operational Efficiency'
				WHEN @ReportName = 7 THEN 'MIECHV Testing Folder'
				END + '/'+ CASE
				WHEN @ReportName = 1 THEN 'Fidelity'
				WHEN @ReportName = 2 THEN 'CSE'
				WHEN @ReportName = 3 THEN 'Outcome'
				WHEN @ReportName = 4 THEN 'Quarterly'
				WHEN @ReportName = 5 THEN 'MIECHV Benchmark'
				WHEN @ReportName = 6 THEN 'Operational Efficiency'
				WHEN @ReportName = 7 THEN 'MIECHV Benchmark Data File'
				END + ' Report'  [ReportPath]

	,RIGHT('000' + CAST(CASE WHEN P.StateID IN (102,103) THEN P.StateID ELSE ISNULL(dbo.udf_StatevTribalOrigState(P.SiteID),P.StateID) END AS VARCHAR(50)),3) 
		+ CAST(CASE WHEN @ReportName = 7 THEN 5 ELSE @ReportName END AS VARCHAR(5)) + CASE WHEN @ReportName = 7 THEN '4' ELSE '2' END
		+ RIGHT('0000' + CAST(CASE 
								WHEN P.StateID = P.siteid 
								THEN '' 
								ELSE P.SiteID 
							  END AS VARCHAR(50)),4) [FileName]

	,'\\nfpden.local\shares\Data\Reports\' + CASE @ReportName WHEN 6 THEN CAST(RIGHT(YEAR(DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1)),2) AS VARCHAR(50)) ELSE CAST (RIGHT(YEAR(@EndDate),2) AS VARCHAR(50)) END
		+ '\' + CASE @ReportName WHEN 6 THEN CAST(DATEPART(M,DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1)) AS VARCHAR(50)) ELSE CAST(DATEPART(QQ,@EndDate) AS VARCHAR(50)) END + '\' [OutputPath]

	,CAST(CASE
						WHEN @ReportName = 1 THEN 'Fidelity'
						WHEN @ReportName = 2 THEN 'CSE'
						WHEN @ReportName = 3 THEN 'Outcome'
						WHEN @ReportName = 4 THEN 'Quarterly'
						WHEN @ReportName = 5 THEN 'Benchmark'
						WHEN @ReportName = 6 THEN 'Operational Efficiency'
						WHEN @ReportName = 7 THEN 'BenchmarkData'
					 END + '_' + P.[Clean Site] + CASE @ReportName WHEN 6 THEN '_M' + CAST(DATEPART(M,DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1)) AS VARCHAR(50)) + '_' + CAST (RIGHT(YEAR(DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1)),2) AS VARCHAR(50)) ELSE '_Q' + CAST(DATEPART(QQ,@EndDate) AS VARCHAR(50)) + '_' + CAST (RIGHT(YEAR(@EndDate),2) AS VARCHAR(50)) END AS VARCHAR(200))  [AltFileName]

	,CAST('\\nfpden.local\shares\Data\Reports\' + 
					CASE
						WHEN @ReportName = 1 THEN 'Fidelity'
						WHEN @ReportName = 2 THEN 'CSE'
						WHEN @ReportName = 3 THEN 'Outcome'
						WHEN @ReportName = 4 THEN 'Quarterly'
						WHEN @ReportName = 5 THEN 'Benchmark'
						WHEN @ReportName = 6 THEN 'Operational Efficiency'
						WHEN @ReportName = 7 THEN 'BenchmarkData'
					 END +'\' + CASE @ReportName WHEN 6 THEN CAST (RIGHT(YEAR(DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1)),4) AS VARCHAR(50)) ELSE CAST (RIGHT(YEAR(@EndDate),4) AS VARCHAR(50)) END
		+ CASE @ReportName WHEN 6 THEN '\M' + CAST(DATEPART(M,DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE())-1, -1)) AS VARCHAR(50))  ELSE '\Q' + CAST(DATEPART(QQ,@EndDate) AS VARCHAR(50)) END + '\' + P.Abbreviation + '\' + CASE WHEN P.AGENCY_INFO_0_NAME IS NULL THEN '' ELSE P.[Clean Site] + '\' END AS VARCHAR(200)) [AltOutputPath]


,CASE @ReportName WHEN 7 THEN 'CSV' WHEN 6 THEN 'doc' ELSE 'PDF' END ReportExtension

,CASE WHEN @ReportName = 6 THEN DATEADD(MONTH,-11,CAST(CAST(MONTH(@EndDate) AS VARCHAR) + '/1/' +  CAST(YEAR(@EndDate) AS VARCHAR) AS DATE))
	   ELSE DATEADD(MONTH,-2,CAST(CAST(MONTH(@EndDate) AS VARCHAR) + '/1/' +  CAST(YEAR(@EndDate) AS VARCHAR) AS DATE))
	   END StartDate
,@EndDate EndDate
,CASE WHEN @ReportName IN (1,3) THEN DATEADD(MONTH,-14,CAST(CAST(MONTH(@EndDate) AS VARCHAR) + '/1/' +  CAST(YEAR(@EndDate) AS VARCHAR) AS DATE))
	  ELSE NULL END CompStartDate
,CASE WHEN @ReportName IN (1,3) THEN DATEADD(MONTH,-12,@EndDate)
	  ELSE NULL END CompEndDate

FROM 


		(select distinct
		p.[US State],p.StateID siteid,P.[US State] [Clean Site],p.Abbreviation,null Site,NULL AGENCY_INFO_0_NAME, '2' ReportType,p.StateID 
		from UV_PAS p

		UNION 

		SELECT DISTINCT
		U.[US State],u.StateID,U.[US State],U.Abbreviation,NULL,NULL, '2' ReportType ,u.StateID

		FROM UC_State U
		WHERE U.Abbreviation = 'NYC'

		union

		select distinct
		p.[US State],p.SiteID,dbo.udf_RemoveSpecialChars(p.AGENCY_INFO_0_NAME),p.Abbreviation,p.Site,p.AGENCY_INFO_0_NAME ,'3' ReportType,p.StateID
		from UV_PAS p
		where p.ProgramName NOT LIKE '%TEST%') p
LEFT OUTER JOIN
	(SELECT 
		DATA.Name
		,DATA.Path
		,MAX(CASE WHEN DATA.Parameter = 'ReportType' THEN Parameter END) ReportTypeP
		,MAX(CASE WHEN DATA.Parameter = 'ParentEntity' THEN Parameter END) ParentEntityP
		,MAX(CASE WHEN DATA.Parameter = 'REName' THEN Parameter END) RENameP
		,MAX(CASE WHEN DATA.Parameter = 'StartDate' THEN Parameter END) StartDateP
		,MAX(CASE WHEN DATA.Parameter = 'EndDate' THEN Parameter END) EndDateP
		,MAX(CASE WHEN DATA.Parameter = 'CompStartDate' THEN Parameter END) CompStartDateP
		,MAX(CASE WHEN DATA.Parameter = 'CompEndDate' THEN Parameter END) CompEndDateP
		,MAX(CASE WHEN DATA.Parameter = 'Site' THEN Parameter END) SiteP
		,MAX(CASE WHEN DATA.Parameter = 'Quarter' THEN Parameter END) QuarterP
		,MAX(CASE WHEN DATA.Parameter = 'QuarterYear' THEN Parameter END) QuarterYearP
		,MAX(CASE WHEN DATA.Parameter = 'AgencyID' THEN Parameter END) AgencyIDP
		,MAX(CASE WHEN DATA.Parameter = 'State' THEN Parameter END) StateP
		,MAX(CASE WHEN DATA.Parameter = 'TribalBirths' THEN Parameter END) TribalBirthsP

	FROM
	(SELECT 
		REPLACE(REPLACE(CONVERT(VARCHAR,T.Parameter.query('.')),'<Name>',''),'</Name>','') Parameter
		,Cat.Name
		,Cat.Path
	FROM 
		(SELECT CAST(C.Parameter AS XML) Parameter, C.Name ,C.Path FROM ReportServer..Catalog C) Cat
		cross apply Parameter.nodes('/Parameters/Parameter/Name') as T(Parameter)
	) DATA
	WHERE 
	DATA.Name = 
		CASE WHEN @ReportName = 1 THEN 'Fidelity Report'
			 WHEN @ReportName = 2 THEN 'MIECHV Benchmark Report'
			 WHEN @ReportName = 3 THEN 'Outcome Report'
			 WHEN @ReportName = 4 THEN 'Quarterly Report'
			 WHEN @ReportName = 5 THEN 'MIECHV Benchmark Data File Report'
			 WHEN @ReportName = 6 THEN 'Operational Efficiency Report'
			 WHEN @ReportName = 7 THEN 'Operational Efficiency'
		END
	GROUP BY DATA.Name, DATA.Path) Param
	ON 1=1
GO
