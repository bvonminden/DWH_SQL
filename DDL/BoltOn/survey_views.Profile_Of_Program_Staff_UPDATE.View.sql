USE [dwh_test]
GO
/****** Object:  View [survey_views].[Profile_Of_Program_Staff_UPDATE]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [survey_views].[Profile_Of_Program_Staff_UPDATE] as select * from survey_views.f_select_Profile_Of_Program_Staff_UPDATE(null,null)
GO
