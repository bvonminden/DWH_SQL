DROP FUNCTION [survey_views].[f_hash_field]
GO
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
	@p_Requested_Hash	bit,
	@p_Value_To_Hash	varchar(4000)
)
RETURNS varchar(4000)
AS
BEGIN
	
	if @p_Requested_Hash=0
	begin
		return 	@p_Value_To_Hash;	
	end;


	return convert(varchar,hashbytes('SHA2_256',@p_Value_To_Hash),2);
	
END
GO
