DROP FUNCTION [survey_views].[f_get_sites_for_profile_id]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [survey_views].[f_get_sites_for_profile_id]
(
	@p_profile_id		int	= null,
	@p_exclude_tribal	bit	= 0
)
RETURNS 
@sites TABLE 
(
	siteid int not null primary key
)
AS
BEGIN

	if @p_profile_id is null
	begin

		insert into @sites
		select 
			distinct
		ee.SiteID
		from survey_views.ExportProfile ep 
			inner join survey_views.ExportEntities ee on ep.ExportProfileID=ee.ExportProfileID
	end
	else
	begin

		insert into @sites
		select 
		ee.SiteID
		from survey_views.ExportProfile ep 
			inner join survey_views.ExportEntities ee on ep.ExportProfileID=ee.ExportProfileID
		where 
		ee.ExportDisabled=0
		and
		ep.ExportProfileID=@p_profile_id
		and
		ee.ExcludeTribal=@p_exclude_tribal;

	end;

	
	RETURN 
END
GO
