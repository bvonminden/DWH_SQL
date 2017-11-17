USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_TableLoad]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Fid_TableLoad]

--DECLARE
		@StartDate DATE --= '7/1/2012',
		,@EndDate DATE --= '6/30/2013',
		,@CompStartDate DATE --= '7/1/2011',
		,@CompEndDate DATE --= '6/30/2012',
		,@ParentEntity VARCHAR(4000) --= N'1',
		,@REName VARCHAR(50) --= NULL,
		,@ReportType VARCHAR(50) --= N'1',
		,@Data INT --= 0

AS 


--	set	@StartDate  = '7/1/2012'
--	set	@EndDate  = '6/30/2013'
--	set	@CompStartDate  = '7/1/2011'
--	set	@CompEndDate  = '6/30/2012'
--	set	@ParentEntity  = N'1'
--	set	@REName  = NULL
--	set	@ReportType = N'1'
--	set	@Data  = 0

TRUNCATE TABLE UC_Fid_Element_1

INSERT INTO UC_Fid_Element_1
EXEC [dbo].[usp_Fid_Element_1]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data

TRUNCATE TABLE UC_Fid_Element_2

INSERT INTO UC_Fid_Element_2
EXEC [dbo].[usp_Fid_Element_2]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data

TRUNCATE TABLE UC_Fid_Element_3

INSERT INTO UC_Fid_Element_3
EXEC [dbo].[usp_Fid_Element_3]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data

TRUNCATE TABLE UC_Fid_Element_4

INSERT INTO UC_Fid_Element_4
EXEC [dbo].[usp_Fid_Element_4]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data

TRUNCATE TABLE UC_Fid_Element_4r

INSERT INTO UC_Fid_Element_4r
EXEC [dbo].[usp_Fid_Element_4r]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data

TRUNCATE TABLE UC_Fid_Element_5

INSERT INTO UC_Fid_Element_5
EXEC [dbo].[usp_Fid_Element_5]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data

TRUNCATE TABLE UC_Fid_Element_6

INSERT INTO UC_Fid_Element_6
EXEC [dbo].[usp_Fid_Element_6]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data


TRUNCATE TABLE UC_Fid_Element_7

INSERT INTO UC_Fid_Element_7
EXEC [dbo].[usp_Fid_Element_7_Agency]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data
		

INSERT INTO UC_Fid_Element_7
EXEC [dbo].[usp_Fid_Element_7]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data


TRUNCATE TABLE UC_Fid_Element_8

INSERT INTO UC_Fid_Element_8
EXEC [dbo].[usp_Fid_Element_8]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data

TRUNCATE TABLE UC_Fid_Element_9

INSERT INTO UC_Fid_Element_9
EXEC [dbo].[usp_Fid_Element_9]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data

TRUNCATE TABLE UC_Fid_Element_10

INSERT INTO UC_Fid_Element_10
EXEC [dbo].[usp_Fid_Element_10]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data

TRUNCATE TABLE UC_Fid_Element_12

INSERT INTO UC_Fid_Element_12
EXEC [dbo].[usp_Fid_Element_12]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data

TRUNCATE TABLE UC_Fid_Element_13

INSERT INTO UC_Fid_Element_13
EXEC [dbo].[usp_Fid_Element_13]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data

TRUNCATE TABLE UC_Fid_Element_14a

INSERT INTO UC_Fid_Element_14a
EXEC [dbo].[usp_Fid_Element_14a]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data

TRUNCATE TABLE UC_Fid_Element_14b

INSERT INTO UC_Fid_Element_14b
EXEC [dbo].[usp_Fid_Element_14b]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data

TRUNCATE TABLE UC_Fid_Element_17

INSERT INTO UC_Fid_Element_17
EXEC [dbo].[usp_Fid_Element_17]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data
		
--CREATE TABLE UC_Fid_Element_12_Clients (clients INT, ProgramID SMALLINT,SiteID SMALLINT,StateID SMALLINT, Cat VARCHAR(20))
TRUNCATE TABLE UC_Fid_Element_12_Clients

INSERT INTO UC_Fid_Element_12_Clients
SELECT AVG(c.clients) clients, c.ProgramID,c.SiteID,c.StateID, 'COMP' Cat
FROM DataWarehouse.dbo.fn_Fidelity_Staff_El12_Clients (@CompStartDate,@CompEndDate,1) c
GROUP BY c.ProgramID,c.SiteID,c.StateID

UNION ALL

SELECT AVG(c.clients) clients, c.ProgramID,c.SiteID,c.StateID, 'CURR' Cat
FROM DataWarehouse.dbo.fn_Fidelity_Staff_El12_Clients (@StartDate,@EndDate,1) c
GROUP BY c.ProgramID,c.SiteID,c.StateID

UNION ALL

SELECT AVG(c.clients) clients, c.ProgramID,c.SiteID,c.StateID, 'AVGAVG_COMP' Cat
FROM DataWarehouse.dbo.fn_Fidelity_Staff_El12_Clients (@CompStartDate,@CompEndDate,12) c
GROUP BY c.ProgramID,c.SiteID,c.StateID

UNION ALL

SELECT AVG(c.clients) clients, c.ProgramID,c.SiteID,c.StateID, 'AVGAVG_CURR' Cat
FROM DataWarehouse.dbo.fn_Fidelity_Staff_El12_Clients (@StartDate,@EndDate,12) c
GROUP BY c.ProgramID,c.SiteID,c.StateID
GO
