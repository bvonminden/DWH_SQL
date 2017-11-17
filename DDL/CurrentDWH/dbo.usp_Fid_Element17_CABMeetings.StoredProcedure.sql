USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Element17_CABMeetings]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_Fid_Element17_CABMeetings]
(	@StartDate		Date 
	,@EndDate		Date 
	,@Site		VARCHAR(max) 
)
AS

If object_id('tempdb..#SurveyDetails17a') is not null
	Drop Table #SurveyDetails17a

If object_id('tempdb..#SurveyDetails17b') is not null
	Drop Table #SurveyDetails17b
	
------===========================================================================================
--for testing

--DECLARE 
--	@StartDate		Date 
--	,@EndDate		Date 
--	--,@Team			VARCHAR(max)
--	,@Site			VARCHAR(max)

--SET @StartDate		 = CAST('7/1/2013' AS DATE)
--SET @EndDate		 = CAST('6/30/2014' AS DATE)

------all sites
--SET @Site = '355,95,311,288,288,261,115,116,116,116,117,117,117,117,344,380,343,329,330,331,325,326,333,96,96,97,98,99,99,100,101,101,102,103,104,105,106,107,108,138,139,139,124,124,304,256,256,256,256,257,257,257,257,257,257,257,279,140,140,141,142,142,143,144,145,146,147,147,148,149,150,150,150,151,109,110,110,111,112,113,113,114,371,372,305,123,123,135,135,135,297,301,301,374,376,377,378,394,312,314,125,366,356,328,136,287,282,283,258,258,289,289,289,289,369,137,171,172,173,173,174,175,152,153,154,154,155,156,157,158,159,160,161,284,299,162,118,119,130,126,324,277,327,337,337,340,359,313,127,128,129,131,132,133,133,134,120,121,121,166,167,168,342,342,346,382,383,169,170,323,315,163,164,165,176,176,192,193,194,379,365,195,177,178,179,180,181,181,182,183,184,293,185,186,186,187,187,188,188,189,190,190,191,191,196,196,205,205,206,206,206,206,206,206,201,367,210,122,122,122,260,260,260,260,260,260,260,260,260,260,260,260,260,260,260,260,260,260,260,260,260,260,260,260,260,260,260,290,321,197,197,197,354,389,338,339,351,198,198,198,198,198,199,199,199,200,207,207,207,207,207,208,208,209,91,91,91,248,211,212,212,213,214,214,215,216,202,203,204,224,224,233,234,240,241,217,218,218,219,242,243,235,236,296,384,385,345,244,225,225,220,237,230,230,292,308,308,286,358,347,349,334,335,332,386,388,86,255,295,238,239,245,246,247,221,222,222,223,227,227,228,229,302,368,361,361,350,353,375,306,307,249,250,251,252,252,253,253,254,226,231,231,231,231,373,363,348,341,232,322,316,316,316,316,259,259,259,259,259,259,259,259,259,259,259,259,259,259'

--for testing
------===========================================================================================
----Declare and set variables to parameters so that optimizer skips what is called parameter sniffing
DECLARE 
	@rStartDate		Date 
	,@rEndDate		Date 
	,@rSite			VARCHAR(max)
SET @rStartDate		= @StartDate
SET @rEndDate		= @EndDate
SET @rSite			= @Site
------===========================================================================================
----split multi parameters into table
DECLARE @SiteTable TABLE(Value BIGINT) 
DECLARE @x XML  
SELECT @x = CAST('<A>'+ REPLACE(@rSite,',','</A><A>')+ '</A>' AS XML) 
INSERT INTO @SiteTable             
SELECT t.value('.', 'int') AS inVal 
FROM @x.nodes('/A') AS x(t) 

----------------------------------------------------------------------------------------------
--survey info
SELECT 
	DISTINCT		
	APS.SiteID			
	,CASE 
		WHEN APS.AGENCY_INFO_BOARD_0_MEETING_DATE01 BETWEEN @rStartDate AND @rEndDate
			THEN APS.AGENCY_INFO_BOARD_0_MEETING_DATE01
	END Meetings01					
	,CASE 
		WHEN APS.AGENCY_INFO_BOARD_0_MEETING_DATE02 BETWEEN @rStartDate AND @rEndDate
			THEN APS.AGENCY_INFO_BOARD_0_MEETING_DATE02
	END Meetings02
	,CASE 
		WHEN APS.AGENCY_INFO_BOARD_0_MEETING_DATE03 BETWEEN @rStartDate AND @rEndDate
			THEN APS.AGENCY_INFO_BOARD_0_MEETING_DATE03
	END Meetings03
	,CASE 
		WHEN APS.AGENCY_INFO_BOARD_0_MEETING_DATE04 BETWEEN @rStartDate AND @rEndDate
			THEN APS.AGENCY_INFO_BOARD_0_MEETING_DATE04
	END Meetings04
	,Floor((DATEDIFF(MONTH,@rStartDate,@rEndDate)+1)/3) MeetingsExpected

INTO #SurveyDetails17a

FROM Agency_Profile_Survey APS 
	
WHERE (APS.AGENCY_INFO_BOARD_0_MEETING_DATE01 BETWEEN @rStartDate AND @rEndDate
		OR APS.AGENCY_INFO_BOARD_0_MEETING_DATE02 BETWEEN @rStartDate AND @rEndDate	
		OR APS.AGENCY_INFO_BOARD_0_MEETING_DATE03 BETWEEN @rStartDate AND @rEndDate	
		OR APS.AGENCY_INFO_BOARD_0_MEETING_DATE04 BETWEEN @rStartDate AND @rEndDate
		)
	AND  APS.CL_EN_GEN_ID IS NOT NULL

-------------------------------------------------------------------------------------------

-------DETAIL DATA
-------client detail records with aggregates for all agencies, not just those with meeting #s
SELECT 
	AgencyCounts.State
	,AgencyCounts.[US State]
	,AgencyCounts.Abbreviation
	,AgencyCounts.StateID
	,AgencyCounts.SiteID
	,AgencyCounts.SiteName
	,AgencyCounts.ProgramID
	,AgencyCounts.ProgramName
	,AgencyCounts.NationalID
	,AgencyCounts.NationalName
	
	--aggregates		
	----------National
	,SUM(AgencyCounts.TotalMeetings) OVER() NationalMeetings
	,SUM(AgencyCounts.TotalMeetingsExpected) OVER() NationalMeetingsExpected	
	,SUM(AgencyCounts.TotalMeetings01) OVER() NationalMeetings01
	,SUM(AgencyCounts.TotalMeetings02) OVER() NationalMeetings02
	,SUM(AgencyCounts.TotalMeetings03) OVER() NationalMeetings03
	,SUM(AgencyCounts.TotalMeetings04) OVER() NationalMeetings04
	----------State
	,SUM(AgencyCounts.TotalMeetings) 
		OVER (PARTITION BY StateID) StateMeetings
	,SUM(AgencyCounts.TotalMeetingsExpected) 
		OVER (PARTITION BY StateID) StateMeetingsExpected
	,SUM(AgencyCounts.TotalMeetings01) 
		OVER (PARTITION BY StateID) StateMeetings01
	,SUM(AgencyCounts.TotalMeetings02) 
		OVER (PARTITION BY StateID) StateMeetings02
	,SUM(AgencyCounts.TotalMeetings03) 
		OVER (PARTITION BY StateID) StateMeetings03
	,SUM(AgencyCounts.TotalMeetings04) 
		OVER (PARTITION BY StateID) StateMeetings04
	----------Agency
	,SUM(AgencyCounts.TotalMeetings)  
		OVER (PARTITION BY StateID, SiteID) AgencyMeetings
	,SUM(AgencyCounts.TotalMeetingsExpected) 
		OVER (PARTITION BY StateID, SiteID) AgencyMeetingsExpected
	,SUM(AgencyCounts.TotalMeetings01) 
		OVER (PARTITION BY StateID, SiteID) AgencyMeetings01
	,SUM(AgencyCounts.TotalMeetings02) 
		OVER (PARTITION BY StateID, SiteID) AgencyMeetings02
	,SUM(AgencyCounts.TotalMeetings03) 
		OVER (PARTITION BY StateID, SiteID) AgencyMeetings03
	,SUM(AgencyCounts.TotalMeetings04) 
		OVER (PARTITION BY StateID, SiteID) AgencyMeetings04
		
INTO #SurveyDetails17b

FROM
(
	SELECT ----obtains # meeting per agency
		dbo.udf_StateVSTribal(pas.Abbreviation,pas.SiteID) [State]
		,pas.[US State]
		,pas.Abbreviation
		,pas.StateID
		,pas.SiteID 
		,pas.AGENCY_INFO_0_NAME	SiteName	
		,'' ProgramID
		,'' ProgramName		
		,'1' NationalID
		,'National' NationalName
		,COUNT(DISTINCT a.Meetings01) TotalMeetings01
		,COUNT(DISTINCT a.Meetings02) TotalMeetings02
		,COUNT(DISTINCT a.Meetings03) TotalMeetings03
		,COUNT(DISTINCT a.Meetings04) TotalMeetings04
		,COUNT(DISTINCT a.Meetings01) 
			+ COUNT(DISTINCT a.Meetings02)
			+ COUNT(DISTINCT a.Meetings03) 
			+ COUNT(DISTINCT a.Meetings04) TotalMeetings
		,MAX(CASE WHEN a.MeetingsExpected IS NULL
			THEN Floor((DATEDIFF(MONTH,@rStartDate,@rEndDate)+1)/3)
			ELSE a.MeetingsExpected
		END) TotalMeetingsExpected

	FROM UV_PAS pas
		LEFT JOIN #SurveyDetails17a a ON a.SiteID = pas.SiteID	----joined this way intentionally

	GROUP BY 
		dbo.udf_StateVSTribal(pas.Abbreviation,pas.SiteID) 
		,pas.[US State]
		,pas.Abbreviation
		,pas.StateID
		,pas.SiteID 
		,pas.AGENCY_INFO_0_NAME
		
)AgencyCounts

-------------------------------------------------------------------------------------------

-------DETAIL DATA
-------client detail records filtered on report selection
SELECT DISTINCT b.*
	,a.Meetings01, a.Meetings02, a.Meetings03, a.Meetings04
	--, parm.Value SiteParmValue  
FROM #SurveyDetails17b b
	LEFT JOIN #SurveyDetails17a a ON a.SiteID = b.SiteID
----****This report filter cannot be added to the previous step because the aggregates 
----****	'for all records' will not be calculated properly
	JOIN @SiteTable parm			----report selection
		ON parm.Value = b.SiteID	----TeamTable contains team program ids

------===========================================================================================
----for testing

--ORDER BY b.StateID, b.SiteID

----for testing
------===========================================================================================
GO
