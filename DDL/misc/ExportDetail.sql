USE [dwh_test]
GO
/****** Object:  StoredProcedure [survey_views].[usp_etl_select_Session_Export_Detail]    Script Date: 11/27/2017 1:35:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [survey_views].[usp_etl_select_Session_Export_Detail]
(
	@p_session_token varchar(50)
)
as
begin


select * from survey_views.f_get_survey_etl_detail(@p_session_token);



end