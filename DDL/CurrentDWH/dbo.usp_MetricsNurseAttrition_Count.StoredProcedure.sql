USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_MetricsNurseAttrition_Count]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_MetricsNurseAttrition_Count]
	@RefDate DATETIME
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @StartDate DATETIME
	DECLARE @EndDate DATETIME

	--First day of month containing RefDate
	SET @StartDate = DATEADD(dd, -(DAY(@RefDate)-1), @RefDate)

	--First day of the month AFTER the month containing RefDate
	SET @EndDate = DATEADD(dd, -(DAY(DATEADD(mm,1,@RefDate))-1), DATEADD(mm,1,@RefDate))

	SELECT COUNT(ST.Entity_Id) AS NursesLeftProgram
	FROM fn_FID_Staff_list('1/1/1995', GETDATE()) ST
	INNER JOIN UV_PAS PAS ON ST.ProgramID = PAS.ProgramID
	WHERE (ST.EndDate BETWEEN @StartDate AND @EndDate) AND (PrimRole = 'Nurse Home Visitor' OR SecRole = 'Nurse Home Visitor')
	
END
GO
