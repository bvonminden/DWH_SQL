USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[sp_CompareALLAgencyDBdataWithDataWarehouse]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Sheri Scott
-- Create date: 12/18/2015
-- Description:	Compares the data in an agency database to the data in the DateWarehouse.
-- =============================================
CREATE PROCEDURE [dbo].[sp_CompareALLAgencyDBdataWithDataWarehouse] 
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @SQL NVARCHAR(MAX),
			@AgencyDB nvarchar(max),
			@TableName varchar(100),
			@ColumnName varchar(100),
			@ColumnValue nvarchar(max),
			@DBfetchStatus bit,
			@TableFetchStatus bit,
			@TableCnt INT = 0,
			@TempTableName NVARCHAR(MAX)
			
	declare DBcursor cursor for 
		SELECT name FROM AGENCYDBSRVR.master.dbo.sysdatabases 
		WHERE name like 'AgencyDB%' 
		AND upper(name) not like '%TEST%' 
		AND UPPER(name) not like '%TEMPLATE%'
		
	open DBcursor
	fetch next from DBcursor into @AgencyDB
	
	set @DBfetchStatus = @@FETCH_STATUS
	
	while @DBfetchStatus = 0
	begin 
	
		declare @objcursor as cursor 
		 
		declare 
			@vsql        as nvarchar(max)
			,@vquery    as nvarchar(max)
			,@id        as int
			,@value        as varchar(50)

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
		
		set @TableFetchStatus = @@FETCH_STATUS

		while (@TableFetchStatus = 0)
		begin
			
			if (exists (select * from DataWarehouse.INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'dbo' and TABLE_NAME = @TableName))
			begin 
			
				--SET @TempTableName = (SELECT name FROM tempdb.sys.objects WHERE type='U' AND name LIKE '#TempTable%')
				
				--IF @TempTableName IS NOT NULL
				--begin
				--	print @TempTableName
				--	set @SQL = 'DROP TABLE dbo.' + @TempTableName
				--	exec (@SQL)
				--end
				
					--set @SQL = 'SELECT TOP 0 * INTO #TempTable FROM ' + @TableName
					
					EXEC ('SELECT TOP 0 * INTO #TempTable FROM ' + @TableName +'; SELECT * FROM #TempTable;')
					
					--SELECT * FROM #TempTable
					
					set @TableCnt = @TableCnt + 1
					
					set @SQL = 'SELECT @ColumnName = name FROM sys.columns WHERE object_id = OBJECT_ID(''dbo.' + @TableName + ''') and column_id = 1'
					
					EXEC sp_executesql @SQL, N'@ColumnName varchar(100) OUTPUT', @ColumnName OUTPUT
					
					set @SQL = 'INSERT INTO #TempTable SELECT A.* FROM AGENCYDBSRVR.' + @AgencyDB + '.dbo.' + @TableName + ' A LEFT JOIN DataWarehouse.dbo.' + @TableName + ' D ON A.' + @ColumnName + ' = D.' + @ColumnName + ' WHERE D.' + @ColumnName + ' IS NULL'
					
					print @SQL
					
					SELECT 'AGENCYDBSRVR.' + @AgencyDB + '.dbo.' + @TableName DatabaseName
					
					exec sp_executesql @SQL, N'@ColumnValue nvarchar(max) OUTPUT', @ColumnValue = @ColumnValue output;
				
					if @@ROWCOUNT > 0 
					begin
						
						PRINT '*********** ' + @AgencyDB + '.dbo.' + @TableName + ' has data that''s not in the data warehouse ************'
					
						SET @SQL = 'bcp "select * from #TempTable" queryout C:\CompareDBs\' + @AgencyDB + '-' + @TableName + '.txt -c -t -T -S localhost'
			    
						exec (@SQL)
						
					end
					
				set @SQL = 'INSERT INTO #TempTable SELECT D.* FROM DataWarehouse.dbo.' + @TableName + ' D LEFT JOIN AGENCYDBSRVR.' + @AgencyDB + '.dbo.' + @TableName + ' A ON A.' + @ColumnName + ' = D.' + @ColumnName + ' WHERE A.' + @ColumnName + ' IS NULL'
				
				print @SQL 
				
				SELECT 'DataWarehouse.dbo.' + @TableName DatabaseName
				
				exec sp_executesql @SQL, N'@ColumnValue nvarchar(max) OUTPUT', @ColumnValue = @ColumnValue output;
			
				if @@ROWCOUNT > 0 
				begin
				
					PRINT '*********** ' + @TableName + ' has data that''s not in the ' + @AgencyDB + ' database ************'
					
					SET @SQL = 'bcp "select * from #TempTable" queryout C:\CompareDBs\DW-' + @TableName + '.txt -c -t -T -S localhost'
		    
					exec (@SQL)
					
				end
				
				drop table #TempTable
				
			end 
			
			fetch next from @objcursor into @TableName
			
			set @TableFetchStatus = @@FETCH_STATUS
			
		end
		 
		close @objcursor
		deallocate @objcursor
		
		fetch next from DBcursor into @AgencyDB
		
		set @DBfetchStatus = @@FETCH_STATUS
		
	end 
	
	close DBcursor
	deallocate DBcursor
	 
END
GO
