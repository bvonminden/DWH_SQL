USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Fid_Out_TableLoad]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Fid_Out_TableLoad]
		@StartDate DATE --= '7/1/2012',
		,@EndDate DATE --= '6/30/2013',
		,@CompStartDate DATE --= '7/1/2011',
		,@CompEndDate DATE --= '6/30/2012',
		,@ParentEntity VARCHAR(4000) --= N'1',
		,@REName VARCHAR(50) --= NULL,
		,@ReportType VARCHAR(50) --= N'1',
		,@Data INT --= 0

AS 

--DECLARE
--		@StartDate DATE = '7/1/2012',
--		@EndDate DATE = '6/30/2013',
--		@CompStartDate DATE = '7/1/2011',
--		@CompEndDate DATE = '6/30/2012',
--		@ParentEntity VARCHAR(4000) = N'1',
--		@REName VARCHAR(50) = NULL,
--		@ReportType VARCHAR(50) = N'1',
--		@Data INT = 0

TRUNCATE TABLE UC_Fid_Outcome_1

INSERT INTO UC_Fid_Outcome_1
EXEC DataWarehouse.[dbo].[usp_Fid_Outcome_1]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data

TRUNCATE TABLE UC_Fid_Outcome_2_37

INSERT INTO UC_Fid_Outcome_2_37
EXEC DataWarehouse.[dbo].[usp_Fid_Outcome_2]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data
		,36.999999


TRUNCATE TABLE UC_Fid_Outcome_2_39

INSERT INTO UC_Fid_Outcome_2_39
EXEC DataWarehouse.[dbo].[usp_Fid_Outcome_2]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data
		,38.999999


TRUNCATE TABLE UC_Fid_Outcome_3_37

INSERT INTO UC_Fid_Outcome_3_37
EXEC DataWarehouse.[dbo].[usp_Fid_Outcome_3]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data
		,36.999999

TRUNCATE TABLE UC_Fid_Outcome_3_39

INSERT INTO UC_Fid_Outcome_3_39
EXEC DataWarehouse.[dbo].[usp_Fid_Outcome_3]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data
		,38.999999

TRUNCATE TABLE UC_Fid_Outcome_4

INSERT INTO UC_Fid_Outcome_4
EXEC DataWarehouse.[dbo].[usp_Fid_Outcome_4]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data

TRUNCATE TABLE UC_Fid_Outcome_5

INSERT INTO UC_Fid_Outcome_5
EXEC DataWarehouse.[dbo].[usp_Fid_Outcome_5]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data

TRUNCATE TABLE UC_Fid_Outcome_6

INSERT INTO UC_Fid_Outcome_6
EXEC DataWarehouse.[dbo].[usp_Fid_Outcome_6]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data

TRUNCATE TABLE UC_Fid_Outcome_7

INSERT INTO UC_Fid_Outcome_7
EXEC DataWarehouse.[dbo].[usp_Fid_Outcome_7]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data

TRUNCATE TABLE UC_Fid_Outcome_8

INSERT INTO UC_Fid_Outcome_8
EXEC DataWarehouse.[dbo].[usp_Fid_Outcome_8]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data

TRUNCATE TABLE UC_Fid_Outcome_10

INSERT INTO UC_Fid_Outcome_10
EXEC DataWarehouse.[dbo].[usp_Fid_Outcome_10]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data

TRUNCATE TABLE UC_Fid_Outcome_11b

INSERT INTO UC_Fid_Outcome_11b
EXEC DataWarehouse.[dbo].[usp_Fid_Outcome_11b]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data

TRUNCATE TABLE UC_Fid_Outcome_11c

INSERT INTO UC_Fid_Outcome_11c
EXEC DataWarehouse.[dbo].[usp_Fid_Outcome_11c]
		@StartDate
		,@EndDate
		,@CompStartDate
		,@CompEndDate
		,@ParentEntity
		,@REName
		,@ReportType
		,@Data
GO
