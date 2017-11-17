USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_OE_Dashboard_Outcomes]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_OE_Dashboard_Outcomes]

	@Startdate date
	, @Enddate date
	, @Team varchar(4000)

AS

--declare	@Startdate date
--declare	 @Enddate date
--declare @Team varchar(4000)

--set	@Startdate = '2013-04-01'
--set @Enddate = '2014-03-31'
--set @Team  = 1820

SELECT

	UV_PAS.Abbreviation
	, UV_PAS.Site
	, UV_PAS.Team_Name
	
	, COUNT(DISTINCT
				CASE 
					WHEN UV_Fidelity_CLID.DOB BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID END) Eth_BirthTotal
					
	, COUNT(DISTINCT
				CASE 
					WHEN UV_Fidelity_CLID.GestAge BETWEEN 18 AND 36.999999
						AND UV_Fidelity_CLID.DOB BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID END) TotalPrematureCount
					
	, COUNT(DISTINCT
				CASE 
					WHEN UV_Fidelity_CLID.Grams BETWEEN 430 AND 2499.999999
						AND UV_Fidelity_CLID.O2DOB BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID END) LowWeightCount
					
	, COUNT(DISTINCT
				CASE
					WHEN UV_Fidelity_CLID.BreastMilk = 'Yes'
						AND UV_Fidelity_CLID.O2DOB BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID
				END) BreastFeedingCount
				
				
	, COUNT(DISTINCT
				CASE
					WHEN UV_Fidelity_CLID.BreastMilk IS NOT NULL 
						AND UV_Fidelity_CLID.O2DOB BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID
				END) BreastFeedingTotal
				
	, COUNT(DISTINCT	
				CASE
					WHEN UV_Fidelity_CLID.Breast6_Yes BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID
				END) Breast6_Yes
				
	, COUNT(DISTINCT	
				CASE
					WHEN UV_Fidelity_CLID.Breast6_Data BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID
				END) Breast6_Data
								
	, COUNT(DISTINCT	
				CASE
					WHEN UV_Fidelity_CLID.Breast12_Yes BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID
				END) Breast12_Yes
				
	, COUNT(DISTINCT	
				CASE
					WHEN UV_Fidelity_CLID.Breast12_Data BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID
				END) Breast12_Data
				
	, COUNT(DISTINCT	
				CASE
					WHEN UV_Fidelity_CLID.Preg6_Yes BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID
				END) Preg6_Yes
				
	, COUNT(DISTINCT	
				CASE
					WHEN UV_Fidelity_CLID.Preg6_Data BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID
				END) Preg6_Data
				
	, COUNT(DISTINCT	
				CASE
					WHEN UV_Fidelity_CLID.Preg12_Yes BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID
				END) Preg12_Yes
				
	, COUNT(DISTINCT	
				CASE
					WHEN UV_Fidelity_CLID.Preg12_Data BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID
				END) Preg12_Data

	, COUNT(DISTINCT	
				CASE
					WHEN UV_Fidelity_CLID.Preg18_Yes BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID
				END) Preg18_Yes
				
	, COUNT(DISTINCT	
				CASE
					WHEN UV_Fidelity_CLID.Preg18_Data BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID
				END) Preg18_Data
				
	, COUNT(DISTINCT	
				CASE
					WHEN UV_Fidelity_CLID.Preg24_Yes BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID
				END) Preg24_Yes
				
	, COUNT(DISTINCT	
				CASE
					WHEN UV_Fidelity_CLID.Preg24_Data BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID
				END) Preg24_Data
				
	, COUNT(DISTINCT	
				CASE
					WHEN UV_Fidelity_CLID.Immuniz6_Yes BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID
				END) Immuniz6_Yes
				
	, COUNT(DISTINCT	
				CASE
					WHEN UV_Fidelity_CLID.Immuniz6_Data BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID
				END) Immuniz6_Data
				
	, COUNT(DISTINCT	
				CASE
					WHEN UV_Fidelity_CLID.Immuniz12_Yes BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID
				END) Immuniz12_Yes
				
	, COUNT(DISTINCT	
				CASE
					WHEN UV_Fidelity_CLID.Immuniz12_Data BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID
				END) Immuniz12_Data
				
	, COUNT(DISTINCT	
				CASE
					WHEN UV_Fidelity_CLID.Immuniz18_Yes BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID
				END) Immuniz18_Yes
				
	, COUNT(DISTINCT	
				CASE
					WHEN UV_Fidelity_CLID.Immuniz18_Data BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID
				END) Immuniz18_Data
				
	, COUNT(DISTINCT	
				CASE
					WHEN UV_Fidelity_CLID.Immuniz24_Yes BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID
				END) Immuniz24_Yes
				
	, COUNT(DISTINCT	
				CASE
					WHEN UV_Fidelity_CLID.Immuniz24_Data BETWEEN @StartDate AND @EndDate
					THEN UV_Fidelity_CLID.CLID
				END) Immuniz24_Data
				
				
				
FROM

	UV_Fidelity_CLID
	INNER JOIN UV_PAS ON UV_PAS.ProgramID = UV_Fidelity_CLID.ProgramID
	
Where UV_PAS.ProgramID in (SELECT * FROM dbo.udf_ParseMultiParam (@Team))
		
Group By 

	UV_PAS.Abbreviation
	, UV_PAS.Site
	, UV_PAS.Team_Name
GO
