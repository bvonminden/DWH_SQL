USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_Remove_Recs_for_SiteIDs]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SP_Remove_Recs_for_SiteIDs] 
	@p_SiteIDs varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @Tname varchar(50),@Cname varchar(50), @SQL varchar(100)

    DECLARE TablesWithSiteID CURSOR FOR
    
    SELECT t.name, c.name
	FROM sys.columns c
		JOIN sys.tables t ON c.object_id = t.object_id
	WHERE upper(c.name) LIKE 'SITE%ID'
	order by t.name
	
	OPEN TablesWithSiteID
	
	FETCH NEXT FROM TablesWithSiteID into @Tname, @Cname
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @SQL = 'DELETE FROM ' + @Tname + ' WHERE ' + @Cname + ' IN (' + @p_SiteIDs + ')'
		
		EXEC (@SQL)
		
		SELECT @Tname, @@ROWCOUNT
		
		FETCH NEXT FROM TablesWithSiteID INTO @Tname, @Cname
		
	END
	
CLOSE TablesWithSiteID

END
GO
