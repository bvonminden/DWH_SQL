USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_EntityProfile_ClientsServed]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_EntityProfile_ClientsServed]
( @StartDate DATE, @EndDate DATE, @Team VARCHAR(max))

AS

--DECLARE @StartDate DATE, @EndDate DATE, @Team VARCHAR(max)
--SET @StartDate = CAST('1/1/2013' AS DATE)
--SET @EndDate = CAST ('12/31/2013' AS DATE)
--SET @Team = '1394'

--------------- CLIENTS SERVED POPULATION ----------------- (CTE)
;WITH Clients_Served AS
(SELECT DISTINCT 
	CL_EN_GEN_ID
	,ProgramID
FROM UV_Fidelity_aHVES
WHERE CLIENT_COMPLETE_0_VISIT = 'Completed'
AND SurveyDate BETWEEN @StartDate AND @EndDate
AND ProgramID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Team)))

SELECT COUNT(CL_EN_GEN_ID) Clients_Served
FROM Clients_Served
GO
