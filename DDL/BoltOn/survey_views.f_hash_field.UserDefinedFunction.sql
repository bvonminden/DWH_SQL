USE [dwh_test]
GO
/****** Object:  UserDefinedFunction [survey_views].[f_hash_field]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [survey_views].[f_hash_field]
(
	@p_Value_To_Hash	varchar(4000)
)
RETURNS varchar(4000)
AS
BEGIN
	
	return convert(varchar,hashbytes('SHA2_256',@p_Value_To_Hash),2);
	
END
GO
