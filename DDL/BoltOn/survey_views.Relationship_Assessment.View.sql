USE [dwh_test]
GO
/****** Object:  View [survey_views].[Relationship_Assessment]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [survey_views].[Relationship_Assessment] as select * from survey_views.f_select_Relationship_Assessment(null,null)
GO
