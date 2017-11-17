USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_list_indexes]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Antoniette Jenik
-- Create date: 10/24/2012	
-- Description:	lists the indexes on the current database
-- =============================================
CREATE PROCEDURE [dbo].[usp_list_indexes]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
		select  
			*
		from sys.indexes i  
		join sys.objects o on i.object_id = o.object_id 
		join sys.index_columns ic on ic.object_id = i.object_id  
			and ic.index_id = i.index_id 
		join sys.columns co on co.object_id = i.object_id  
			and co.column_id = ic.column_id 
		where i.[type] = 2  
		and i.is_unique = 0  
		and i.is_primary_key = 0 
		and o.[type] = 'U' 
		--and ic.is_included_column = 0 
		order by o.[name], i.[name], ic.is_included_column, ic.key_ordinal 
END
GO
