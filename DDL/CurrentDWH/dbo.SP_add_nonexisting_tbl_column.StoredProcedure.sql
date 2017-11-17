USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_add_nonexisting_tbl_column]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_add_nonexisting_tbl_column
CREATE PROCEDURE [dbo].[SP_add_nonexisting_tbl_column]
  @p_tablename    nvarchar(50),
  @p_columnname   nvarchar(50),
  @p_attribute    nvarchar(50),
  @return_status  int = 0 output
AS
BEGIN

-- This scripts checks for the existance of a specified column,
-- If it does not exist, then it addes the column using the specified
-- column attributes

-- Return Status: 
--   0 = Column already Exists, no action taken
--   1 = Column successfully added
--  -1 = Error occured while trying to add column

   DECLARE @SQL	nvarchar(2000)

   IF not exists (SELECT AC.[name]
                    FROM sys.[tables] T 
                    INNER JOIN sys.[all_columns] AC ON T.[object_id] = AC.[object_id] 
                    where t.name = @p_tablename
                      and ac.name = @p_columnname)
      BEGIN
         BEGIN TRY
            --print 'Column does not exist: '+@p_tablename +'.'+@p_columnname
            set @SQL = 'Alter TABLE dbo.' + @p_tablename 
                + ' ADD [' + Left(@p_columnname,100)+ '] '
                + @p_attribute

            --print 'SQL=' +@sql
            exec (@SQL)
            set @return_status = 1
         END TRY
         BEGIN CATCH
            set @return_status = -1
            print @SQL
         END CATCH
      END
   ELSE
      BEGIN
         set @return_status = 0
      END

   return @return_status

END
GO
