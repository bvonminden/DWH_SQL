USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[sp_CompareAgencyDataWithDataWarehouse]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Sheri Scott
-- Create date: 12/18/2015
-- Description:	Compares the data in an agency database to the data in the DateWarehouse.
-- =============================================
CREATE PROCEDURE [dbo].[sp_CompareAgencyDataWithDataWarehouse] 
	@AgencyDB varchar(100)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @SQL NVARCHAR(MAX),
			@TableName varchar(100),
			@ColumnName varchar(100),
			@ColumnValue nvarchar(max),
			@SiteID INT,
			@SiteIDCol varchar(50)
	
	declare @objcursor as cursor 
	 
	declare 
		 @vsql      as nvarchar(max)
		,@vquery    as nvarchar(max)
		,@id        as int
		,@value     as varchar(50)

	set @SQL = 'SELECT top 1 @SiteID = SiteID FROM AGENCYDBSRVR.' + @AgencyDB + '.dbo.Agencies'
	
	EXEC sp_executesql @SQL, N'@SiteID varchar(50) OUTPUT', @SiteID OUTPUT
	
	set @vquery = 'SELECT name FROM AGENCYDBSRVR.' + @AgencyDB + '.sys.sysobjects 
	WHERE xtype=''U'' 
	AND name NOT LIKE ''xx%'' 
	AND name NOT LIKE ''Z%'' 
	AND name NOT IN (''LOV_Names'',''LOV_Values'',''sysdiagrams'',''dtproperties'',''process_Log'')' 

	set @vsql = 'set @cursor = cursor forward_only static for ' + @vquery + ' open @cursor;'
	 
	exec sys.sp_executesql
		@vsql
		,N'@cursor cursor output'
		,@objcursor output
	    
	fetch next from @objcursor into @TableName

	while (@@fetch_status = 0)
	begin
		
		if (exists (select * from DataWarehouse.INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'dbo' and TABLE_NAME = @TableName))
		begin
		
			set @SQL = 'SELECT @ColumnName = name FROM sys.columns WHERE object_id = OBJECT_ID(''dbo.' + @TableName + ''') and column_id = 1'
			
			EXEC sp_executesql @SQL, N'@ColumnName varchar(100) OUTPUT', @ColumnName OUTPUT
			
			set @SQL = 'SELECT @SiteIDCol = name FROM sys.columns WHERE object_id = OBJECT_ID(''dbo.' + @TableName + ''') and name like ''%Site%'''
			
			EXEC sp_executesql @SQL, N'@SiteIDCol varchar(100) OUTPUT', @SiteIDCol OUTPUT
			
			set @SQL = 'SELECT * FROM AGENCYDBSRVR.' + @AgencyDB + '.dbo.' + @TableName + ' A LEFT JOIN DataWarehouse.dbo.' + @TableName + ' D ON A.' + @ColumnName + ' = D.' + @ColumnName + ' WHERE D.' + @ColumnName + ' IS NULL'
			
			SELECT 'AGENCYDBSRVR.dbo.' + @TableName DatabaseName
			
			exec sp_executesql @SQL, N'@ColumnValue nvarchar(max) OUTPUT', @ColumnValue = @ColumnValue output;
		
			if @@ROWCOUNT > 0 
				PRINT '*********** ' + @TableName + ' has data that''s not in the data warehouse ************'
			
			if isnull(@SiteIDCol,'') != ''
				set @SQL = 'SELECT * FROM DataWarehouse.dbo.' + @TableName + ' D LEFT JOIN AGENCYDBSRVR.' + @AgencyDB + '.dbo.' + @TableName + ' A ON A.' + @ColumnName + ' = D.' + @ColumnName + ' WHERE A.' + @ColumnName + ' IS NULL AND A.' + @SiteIDCol + ' = D.' + @SiteIDCol
			else
				set @SQL = 'SELECT * FROM DataWarehouse.dbo.' + @TableName + ' D LEFT JOIN AGENCYDBSRVR.' + @AgencyDB + '.dbo.' + @TableName + ' A ON A.' + @ColumnName + ' = D.' + @ColumnName + ' WHERE A.' + @ColumnName + ' IS NULL'
			
			SELECT 'DataWarehouse.dbo.' + @TableName DatabaseName
			
			exec sp_executesql @SQL, N'@ColumnValue nvarchar(max) OUTPUT', @ColumnValue = @ColumnValue output;
		
			if @@ROWCOUNT > 0 
				PRINT '*********** ' + @TableName + ' has data that''s not in the agency database ************'
			
		end
	    
		SET @SQL = ''
	    
		fetch next from @objcursor into @TableName
	end
	 
	close @objcursor
	deallocate @objcursor
 
END
GO
