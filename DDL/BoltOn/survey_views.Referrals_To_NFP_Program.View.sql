USE [dwh_test]
GO
/****** Object:  View [survey_views].[Referrals_To_NFP_Program]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [survey_views].[Referrals_To_NFP_Program] as select * from survey_views.f_select_Referrals_To_NFP_Program(null,null)
GO
