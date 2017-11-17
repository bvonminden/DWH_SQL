USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_ParentEntityHRSA]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_ParentEntityHRSA]
	-- Add the parameters for the stored procedure here
	@States VARCHAR(MAX)
	,@Sites VARCHAR(MAX)
	,@Teams VARCHAR(MAX)
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
				WHERE SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Sites))) <> 
			(SELECT COUNT(DISTINCT ProgramID)
				FROM UV_PAS
				WHERE ProgramID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Teams)))
		THEN LEFT((SELECT DISTINCT Team_Name + ', '
				FROM UV_PAS
				WHERE ProgramID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Teams))
				FOR XML PATH ('')),LEN((SELECT DISTINCT Team_Name + ', '
				FROM UV_PAS
				WHERE ProgramID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Teams))
				FOR XML PATH ('')))-1)

		WHEN (SELECT COUNT(DISTINCT SiteID)
				FROM UV_PAS
				WHERE StateID IN (SELECT * FROM dbo.udf_ParseMultiParam(@States))) <>
			(SELECT COUNT(DISTINCT SiteID)
				FROM UV_PAS
				WHERE SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Sites)))
		THEN LEFT((SELECT DISTINCT Site + ', '
				FROM UV_PAS
				WHERE SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Sites))
				FOR XML PATH ('')),LEN((SELECT DISTINCT Site + ', '
				FROM UV_PAS
				WHERE SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Sites))
				FOR XML PATH ('')))-1)				
				
		WHEN (SELECT COUNT(DISTINCT StateID)
				FROM UV_PAS) <> 
			(SELECT COUNT(DISTINCT StateID)
				FROM UV_PAS
				WHERE StateID IN (SELECT * FROM dbo.udf_ParseMultiParam(@States)))
		THEN  LEFT((SELECT DISTINCT [US State] + ', '
				FROM UV_PAS
				WHERE StateID IN (SELECT * FROM dbo.udf_ParseMultiParam(@States))
				FOR XML PATH ('')),LEN((SELECT DISTINCT [US State] + ', '
				FROM UV_PAS
				WHERE StateID IN (SELECT * FROM dbo.udf_ParseMultiParam(@States))
				FOR XML PATH ('')))-1)
		--ELSE LEFT((SELECT DISTINCT [US State] + ', '
		--		FROM UV_PAS
		--		WHERE StateID IN (SELECT * FROM dbo.udf_ParseMultiParam(@States))
		--		FOR XML PATH ('')),LEN((SELECT DISTINCT [US State] + ', '
		--		FROM UV_PAS
		--		WHERE StateID IN (SELECT * FROM dbo.udf_ParseMultiParam(@States))
		--		FOR XML PATH ('')))-1)
	--	END
	--,CASE	

	--	ELSE LEFT((SELECT DISTINCT Site + ', '
	--			FROM UV_PAS
	--			WHERE SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Sites))
	--			FOR XML PATH ('')),LEN((SELECT DISTINCT Site + ', '
	--			FROM UV_PAS
	--			WHERE SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Sites))
	--			FOR XML PATH ('')))-1)
	--	END
	--,CASE

		ELSE 'National'
		END
		,CASE
		WHEN (SELECT COUNT(DISTINCT ProgramID)
				FROM UV_PAS
				WHERE SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Sites))) <> 
			(SELECT COUNT(DISTINCT ProgramID)
				FROM UV_PAS
				WHERE ProgramID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Teams)))
		THEN 'Team'

		WHEN (SELECT COUNT(DISTINCT SiteID)
				FROM UV_PAS
				WHERE StateID IN (SELECT * FROM dbo.udf_ParseMultiParam(@States))) <>
			(SELECT COUNT(DISTINCT SiteID)
				FROM UV_PAS
				WHERE SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam(@Sites)))
		THEN 'Agency'			
				
		WHEN (SELECT COUNT(DISTINCT StateID)
				FROM UV_PAS) <> 
			(SELECT COUNT(DISTINCT StateID)
				FROM UV_PAS
				WHERE StateID IN (SELECT * FROM dbo.udf_ParseMultiParam(@States)))
		THEN  'State'

		ELSE 'National'
		END RptLvl
END
GO
