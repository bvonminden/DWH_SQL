USE [dwh_test]
GO
/****** Object:  StoredProcedure [survey_views].[usp_etl_exportprofiles_update_status]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [survey_views].[usp_etl_exportprofiles_update_status]
	@p_export_profile_id int,
	@p_result char(1)
AS
BEGIN
	SET NOCOUNT ON;





END
GO
