USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Template_Header]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_Template_Header]
	-- Add the parameters for the stored procedure here
	@State VARCHAR(MAX)
	,@Agency VARCHAR(MAX)
	,@Team VARCHAR(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
SELECT

	CASE
		WHEN (SELECT COUNT(DISTINCT ProgramID)
				FROM UV_PAS
				WHERE SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Agency))) <> 
			(SELECT COUNT(DISTINCT ProgramID)
				FROM UV_PAS
				WHERE ProgramID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Team)))
		THEN LEFT((SELECT DISTINCT Team_Name + ', '
				FROM UV_PAS
				WHERE ProgramID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Team))
				FOR XML PATH ('')),LEN((SELECT DISTINCT Team_Name + ', '
				FROM UV_PAS
				WHERE ProgramID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Team))
				FOR XML PATH ('')))-1)

		WHEN (SELECT COUNT(DISTINCT SiteID)
				FROM UV_PAS
				WHERE StateID IN (SELECT * FROM dbo.udf_ParseMultiParam(@State))) <>
			(SELECT COUNT(DISTINCT SiteID)
				FROM UV_PAS
				WHERE SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Agency)))
		THEN LEFT((SELECT DISTINCT Site + ', '
				FROM UV_PAS
				WHERE SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Agency))
				FOR XML PATH ('')),LEN((SELECT DISTINCT Site + ', '
				FROM UV_PAS
				WHERE SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Agency))
				FOR XML PATH ('')))-1)				
				
		WHEN (SELECT COUNT(DISTINCT StateID)
				FROM UV_PAS) <> 
			(SELECT COUNT(DISTINCT StateID)
				FROM UV_PAS
				WHERE StateID IN (SELECT * FROM dbo.udf_ParseMultiParam(@State)))
		THEN  LEFT((SELECT DISTINCT [US State] + ', '
				FROM UV_PAS
				WHERE StateID IN (SELECT * FROM dbo.udf_ParseMultiParam(@State))
				FOR XML PATH ('')),LEN((SELECT DISTINCT [US State] + ', '
				FROM UV_PAS
				WHERE StateID IN (SELECT * FROM dbo.udf_ParseMultiParam(@State))
				FOR XML PATH ('')))-1)

		ELSE 'National'
		END
		,CASE
		WHEN (SELECT COUNT(DISTINCT ProgramID)
				FROM UV_PAS
				WHERE SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Agency))) <> 
			(SELECT COUNT(DISTINCT ProgramID)
				FROM UV_PAS
				WHERE ProgramID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Team)))
		THEN 'Team'

		WHEN (SELECT COUNT(DISTINCT SiteID)
				FROM UV_PAS
				WHERE StateID IN (SELECT * FROM dbo.udf_ParseMultiParam(@State))) <>
			(SELECT COUNT(DISTINCT SiteID)
				FROM UV_PAS
				WHERE SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Agency)))
		THEN 'Agency'			
				
		WHEN (SELECT COUNT(DISTINCT StateID)
				FROM UV_PAS) <> 
			(SELECT COUNT(DISTINCT StateID)
				FROM UV_PAS
				WHERE StateID IN (SELECT * FROM dbo.udf_ParseMultiParam(@State)))
		THEN  'State'

		ELSE 'National'
		END RptLvl
END
GO
