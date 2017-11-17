USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Element_13]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Fid_Element_13]
(	@StartDate		Date 
	,@EndDate		Date 
	,@CompStartDate	Date 
	,@CompEndDate	Date 
	,@ParentEntity Varchar(4000)
	,@REName	VARCHAR(50) 
	,@ReportType	VARCHAR(50) 
	,@Data INT
)

AS
--DECLARE 
--	@StartDate		Date 
--	,@EndDate		Date 
--	,@CompStartDate	Date 
--	,@CompEndDate	Date 
--	,@ParentEntity Varchar(4000)
--	,@REName VARCHAR(50) 
--	,@ReportType INT
--	,@Data INT
--SET @StartDate		 = CAST('4/1/2012' AS DATE)
--SET @EndDate		 = DATEADD(D,-1,DATEADD(YEAR,1,@StartDate))
--SET @CompStartDate	 = CAST('4/1/2011' AS DATE)
--SET @CompEndDate	 = DATEADD(D,-1,DATEADD(YEAR,1,@CompStartDate))
--SET @ParentEntity	 = 14
--SET @REName			 = NULL
--SET @ReportType		 = 2
--SET @Data			 = 1;

DECLARE 
	@rStartDate		Date 
	,@rEndDate		Date 
	,@rCompStartDate	Date 
	,@rCompEndDate	Date 
	,@rParentEntity Varchar(4000)
	,@rREName VARCHAR(50) 
	,@rReportType VARCHAR(50) 
	,@rData INT
SET @rStartDate		 = @StartDate
SET @rEndDate		 = @EndDate
SET @rCompStartDate	 = @CompStartDate
SET @rCompEndDate	 = @CompEndDate
SET @rParentEntity	 = @ParentEntity
SET @rREName		 = @REName
SET @rReportType	 = @ReportType
SET @rData			 = @Data;



--IF @rData = 0
--BEGIN

--SELECT 
--	dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
--	,P.[US State]
--	,P.StateID
--	,P.SiteID [Site_ID]
--	,P.AGENCY_INFO_0_NAME
--	,P.ProgramID
--	,dbo.udf_fn_GetCleanProg(P.ProgramID) ProgramName
--	,CASE WHEN P.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
--		WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName END ReportingEntity

--	,ISNULL(MAX(aa.HV_COUNT_curr),0) HV_COUNT_curr
--	,ISNULL(MAX(aa.HV_FTE_curr),0) HV_FTE_curr
--	,ISNULL(MAX(aa.S_Count_curr),0) S_Count_curr
--	,ISNULL(MAX(aa.S_FTE_curr),0) S_FTE_curr
--	,ISNULL(MAX(aa.MISSING_curr),0) MISSING_curr

--	,ISNULL(MAX(b.HV_COUNT_comp),0) HV_COUNT_comp
--	,ISNULL(MAX(b.HV_FTE_comp),0) HV_FTE_comp
--	,ISNULL(MAX(b.S_Count_comp),0) S_Count_comp
--	,ISNULL(MAX(b.S_FTE_comp),0) S_FTE_comp
--	,ISNULL(MAX(b.MISSING_comp),0) MISSING_comp

--FROM

--	(SELECT DISTINCT ProgramID
--	FROM fn_FID_Staff_list (@rCompStartDate,@rEndDate)) ROOT


--INNER JOIN UV_PAS P
--	ON (ROOT.ProgramID = P.Program_ID_NHV
--	OR ROOT.ProgramID = P.Program_ID_Referrals
--	OR ROOT.ProgramID = P.Program_ID_Staff_Supervision)

--LEFT OUTER JOIN
--(SELECT
--	DATA1.ProgramID
--	,ISNULL(COUNT(DISTINCT CASE WHEN (DATA1.HV_FTE > 0 OR DATA1.NHV_Flag =1) AND DATA1.NS_Flag <> 1 AND ISNULL(DATA1.S_FTE,0) = 0
--						 THEN DATA1.Entity_Id END),0) HV_COUNT_curr
--	,ISNULL(SUM(CASE WHEN (DATA1.HV_FTE > 0 OR DATA1.NHV_Flag =1) AND DATA1.NS_Flag <> 1 AND ISNULL(DATA1.S_FTE,0) = 0 THEN DATA1.HV_FTE END),0) HV_FTE_curr
--	,ISNULL(COUNT(DISTINCT CASE WHEN DATA1.NS_Flag = 1 OR DATA1.S_FTE > 0 THEN DATA1.Entity_Id END),0) S_Count_curr
--	,ISNULL(SUM(CASE WHEN DATA1.NS_Flag = 1 OR DATA1.S_FTE > 0 THEN DATA1.S_FTE END),0) S_FTE_curr
--	,ISNULL(COUNT(DISTINCT CASE WHEN DATA1.NS_Flag = 1 AND ISNULL(DATA1.S_FTE,0) = 0 THEN DATA1.Entity_Id END),0) MISSING_curr
--FROM
--	(SELECT * FROM fn_FID_Staff_list (@rStartDate,@rEndDate) WHERE EndDate IS NULL or EndDate > @rEndDate
--	) DATA1

--GROUP BY 
--	DATA1.ProgramID) aa 
--	ON P.ProgramID = aa.ProgramID
	
--LEFT OUTER JOIN
--(SELECT
--	DATA2.ProgramID
--	,ISNULL(COUNT(DISTINCT CASE WHEN (DATA2.HV_FTE > 0 OR DATA2.NHV_Flag =1) AND DATA2.NS_Flag <> 1 AND ISNULL(DATA2.S_FTE,0) = 0
--						 THEN DATA2.Entity_Id END),0) HV_COUNT_comp
--	,ISNULL(SUM(CASE WHEN (DATA2.HV_FTE > 0 OR DATA2.NHV_Flag =1) AND DATA2.NS_Flag <> 1 AND ISNULL(DATA2.S_FTE,0) = 0 THEN DATA2.HV_FTE END),0) HV_FTE_comp
--	,ISNULL(COUNT(DISTINCT CASE WHEN DATA2.NS_Flag = 1 OR DATA2.S_FTE > 0 THEN DATA2.Entity_Id END),0) S_Count_comp
--	,ISNULL(SUM(CASE WHEN DATA2.NS_Flag = 1 OR DATA2.S_FTE > 0 THEN DATA2.S_FTE END),0) S_FTE_comp
--	,ISNULL(COUNT(DISTINCT CASE WHEN DATA2.NS_Flag = 1 AND ISNULL(DATA2.S_FTE,0) = 0 THEN DATA2.Entity_Id END),0) MISSING_comp
--FROM
--	(SELECT * FROM fn_FID_Staff_list (@rCompStartDate,@rCompEndDate) WHERE EndDate IS NULL or EndDate > @rEndDate
--	) DATA2
	
--GROUP BY 
--	DATA2.ProgramID
	
	
--	) b
--	ON P.ProgramID = b.ProgramID


--WHERE CASE
--		WHEN @rReportType = 1 THEN 1
--		WHEN @rReportType = 2 THEN P.StateID
--		WHEN @rReportType = 3 THEN P.SiteID
--		WHEN @rReportType = 4 THEN P.ProgramID
--	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))

--GROUP BY 
--	P.SiteID
--	,dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) 
--	,P.[US State]
--	,P.StateID
--	,P.AGENCY_INFO_0_NAME
--	,P.ProgramID
	
	
--UNION

--SELECT 
--	dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
--	,P.[US State]
--	,P.StateID
--	,P.SiteID [Site_ID]
--	,P.AGENCY_INFO_0_NAME
--	,P.ProgramID
--	,dbo.udf_fn_GetCleanProg(P.ProgramID) ProgramName
--	,CASE WHEN P.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
--		WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName END ReportingEntity
--      ,0,0,0,0,0,0,0,0,0,0
      
--FROM UV_PAS P
--WHERE CASE
--		WHEN @rReportType = 1 THEN 1
--		WHEN @rReportType = 2 THEN P.StateID
--		WHEN @rReportType = 3 THEN P.SiteID
--		WHEN @rReportType = 4 THEN P.ProgramID
--	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))
	  
	  
--END

--ELSE ------------------------- DATA Return ----------------------
--BEGIN


SELECT 
	dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
	,P.[US State]
	,P.StateID
	,P.SiteID [Site_ID]
	,P.AGENCY_INFO_0_NAME
	,P.ProgramID
	,dbo.udf_fn_GetCleanProg(P.ProgramID) ProgramName
	,CASE WHEN P.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
		WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName END ReportingEntity

	,aa.HV_COUNT_curr HV_COUNT_curr
	,aa.HV_FTE_curr HV_FTE_curr
	,aa.S_Count_curr S_Count_curr
	,aa.S2_Count_curr S2_Count_curr
	,aa.S_FTE_curr S_FTE_curr
	,aa.MISSING_curr MISSING_curr
	,aa.MissingNSPosition_curr
	,aa.MissingNHVPosition_curr

	,b.HV_COUNT_comp HV_COUNT_comp
	,b.HV_FTE_comp HV_FTE_comp
	,b.S_Count_comp S_Count_comp
	,b.S2_Count_comp S2_Count_comp
	,b.S_FTE_comp S_FTE_comp
	,b.MISSING_comp MISSING_comp
	,b.MissingNSPosition_comp
	,b.MissingNHVPosition_comp
	,ROOT.Entity_Id

FROM

	(SELECT DISTINCT ProgramID,Entity_Id
	FROM fn_FID_Staff_listv2 (@rCompStartDate,@rEndDate)) ROOT


INNER JOIN UV_PAS P
	ON (ROOT.ProgramID = P.Program_ID_NHV
	OR ROOT.ProgramID = P.Program_ID_Referrals
	OR ROOT.ProgramID = P.Program_ID_Staff_Supervision)

LEFT OUTER JOIN
(SELECT DISTINCT
	DATA1.ProgramID,Entity_Id
	,(CASE WHEN (DATA1.HV_FTE > 0 OR DATA1.NHV_Flag =1) AND DATA1.NS_Flag <> 1 AND ISNULL(DATA1.S_FTE,0) = 0
						 THEN DATA1.Entity_Id END) HV_COUNT_curr
	,(CASE WHEN (DATA1.HV_FTE > 0 OR DATA1.NHV_Flag =1) AND DATA1.NS_Flag <> 1 AND ISNULL(DATA1.S_FTE,0) = 0 THEN DATA1.HV_FTE END) HV_FTE_curr
	,(CASE WHEN DATA1.NS_Flag = 1 OR DATA1.S_FTE > 0 THEN DATA1.Entity_Id END) S_Count_curr
	,(CASE WHEN DATA1.NS_Flag = 1 THEN DATA1.Entity_Id END) S2_Count_curr
	,(CASE WHEN DATA1.NS_Flag = 1 OR DATA1.S_FTE > 0 THEN DATA1.S_FTE END) S_FTE_curr
	,(CASE WHEN DATA1.NS_Flag = 1 AND ISNULL(DATA1.S_FTE,0) = 0 THEN DATA1.Entity_Id END) MISSING_curr
	,(CASE WHEN DATA1.S_FTE > 0 AND DATA1.NS_Flag <> 1 THEN DATA1.Entity_Id END) MissingNSPosition_curr
	,(CASE WHEN DATA1.HV_FTE > 0 AND DATA1.NHV_Flag <> 1 THEN DATA1.Entity_Id END) MissingNHVPosition_curr
FROM
	(SELECT * FROM fn_FID_Staff_listv2 (@rStartDate,@rEndDate) WHERE EndDate IS NULL or EndDate > @rEndDate
	) DATA1

--GROUP BY 
	--DATA1.ProgramID,Entity_Id
	) aa 
	ON P.ProgramID = aa.ProgramID
	AND ROOT.Entity_Id = aa.Entity_Id
	
LEFT OUTER JOIN
(SELECT DISTINCT
	DATA2.ProgramID,Entity_Id
	,(CASE WHEN (DATA2.HV_FTE > 0 OR DATA2.NHV_Flag =1) AND DATA2.NS_Flag <> 1 AND ISNULL(DATA2.S_FTE,0) = 0
						 THEN DATA2.Entity_Id END) HV_COUNT_comp
	,(CASE WHEN (DATA2.HV_FTE > 0 OR DATA2.NHV_Flag =1) AND DATA2.NS_Flag <> 1 AND ISNULL(DATA2.S_FTE,0) = 0 THEN DATA2.HV_FTE END) HV_FTE_comp
	,(CASE WHEN DATA2.NS_Flag = 1 OR DATA2.S_FTE > 0 THEN DATA2.Entity_Id END) S_Count_comp
	,(CASE WHEN DATA2.NS_Flag = 1 THEN DATA2.Entity_Id END) S2_Count_comp
	,(CASE WHEN DATA2.NS_Flag = 1 OR DATA2.S_FTE > 0 THEN DATA2.S_FTE END) S_FTE_comp
	,(CASE WHEN DATA2.NS_Flag = 1 AND ISNULL(DATA2.S_FTE,0) = 0 THEN DATA2.Entity_Id END) MISSING_comp
	,(CASE WHEN DATA2.S_FTE > 0 AND DATA2.NS_Flag <> 1 THEN DATA2.Entity_Id END) MissingNSPosition_comp
	,(CASE WHEN DATA2.HV_FTE > 0 AND DATA2.NHV_Flag <> 1 THEN DATA2.Entity_Id END) MissingNHVPosition_comp
FROM
	(SELECT * FROM fn_FID_Staff_listv2 (@rCompStartDate,@rCompEndDate) WHERE EndDate IS NULL or EndDate > @rCompEndDate
	) DATA2
	
	--GROUP BY 
	--	DATA2.ProgramID,Entity_Id
	
	
	) b
	ON P.ProgramID = b.ProgramID
	AND ROOT.Entity_Id = b.Entity_Id


WHERE CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN P.StateID
		WHEN @rReportType = 3 THEN P.SiteID
		WHEN @rReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))

--GROUP BY 
--	P.SiteID
--	,dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) 
--	,P.[US State]
--	,P.StateID
--	,P.AGENCY_INFO_0_NAME
--	,P.ProgramID
--	,ROOT.Entity_Id
	

--END
GO
