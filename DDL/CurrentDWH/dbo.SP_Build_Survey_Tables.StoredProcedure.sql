USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_Build_Survey_Tables]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--drop proc dbo.SP_Build_Survey_Tables
CREATE PROCEDURE [dbo].[SP_Build_Survey_Tables]
AS
-- This script checks for the existance of survey tables and columns in the DW.
-- If found not to exist, then the table will be created, and an
-- alter table done for each missing column.
--
-- Columns will be based upon each element within a survey, and like column
-- attributes applied.
--
--
-- Parameters:
--   p_surveyid = SurveyID, if 0, will process all surveys flatfile tables
--   p_staffid = The StaffID plug value to create the table name.
--
-- 
-- Steps:
-- Build cursor of surveys.
-- For each survey, check for the existance of the table.
-- If not existing, create table with the basic table fields of:
--    surveyid, entityid, clientid, surveyresponsedate, surveyresponseid
--
-- History:
--   20120120 - changed logic to validate existance within cursor, instead of 
--              processing each table/items separately.
--   20120306 - Added new column 'DataSource' to surveys
--   20140903 - Added new column 'Master_SurveyID' to surveys.
--   20160908 - Added new column 'Archive_Record' to Surveys, 
--              to designate that this is the archive record, which is to be deleted from the datasource (eto).

print 'Starting SP_Build_Survey_Tables'

DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_BUILD_SURVEY_TABLES'

DECLARE @cursor_count		smallint
set @cursor_count = 0

DECLARE @SurveyType		char(10)
DECLARE @SurveyName		varchar(200)
DECLARE @DW_Survey_TableName    nvarchar(100)
DECLARE @ElementTypeID	 	smallint
DECLARE @pseudonym		varchar(100)
DECLARE @sql                    nvarchar(2000)
DECLARE @return_stat		int

----------------------------------------------------------------------------------------
-- Initiate the Process Log
----------------------------------------------------------------------------------------

-- Check for existance for this process, if not found, add one:
select @count = count(*) from dbo.process_log where Process = @Process

set nocount on

IF @count = 0 
   insert into dbo.process_log (Process, LogDate, BegDate, EndDate, Action, Phase, Comment)
      Values (@Process, getdate(),getdate(),null,'Starting',null,null)
ELSE
   update dbo.process_log 
      set BegDate = getdate()
         ,EndDate = null
         ,LogDate = getdate()
         ,Action = 'Start'
         ,Phase = null
         ,Comment = null
         ,index_1 = null
         ,index_2 = null
         ,index_3 = null
    where Process = @process

----------------------------------------------------------------------------------------

DECLARE SurveyCursor Cursor FOR 
select distinct 
       Surveys.SurveyType
      ,Surveys.DW_TableName
 from dbo.Mstr_Surveys Surveys 
where surveyid >= 1575
--  and Disabled = 0
  and DW_TableName is not null
  and not exists (SELECT T.[name]
                    FROM sys.[tables] T 
                   where t.name = DW_TableName);

-- Process the master surveys cursor:
--
OPEN SurveyCursor
FETCH NEXT FROM SurveyCursor 
      INTO @SurveyType
          ,@DW_Survey_TableName;


WHILE @@FETCH_STATUS = 0
  BEGIN

     set @cursor_count = @cursor_count + 1

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing FOR '+@DW_Survey_TableName
      ,Index_1 = null
      ,LogDate = getdate()
 where Process = @process
--------------------------------------------- 

----------------------------------------------------------------------------------------
--   Create Survey table with basic columns
----------------------------------------------------------------------------------------

     print '-------------------'
     print 'Processing DW_TableName=' +@DW_Survey_TableName

--   Check for existing table, 
--     if not existing, create table with basic common fields:
        if not exists (SELECT T.[name]
                         FROM sys.[tables] T 
                        where t.name = @DW_Survey_TableName)
           BEGIN
             print 'Tbl does not exist, creating table dbo.'+@DW_Survey_TableName 
             set @SQL = 'CREATE TABLE dbo.' + @DW_Survey_TableName 
                 +' ([SurveyResponseID] int PRIMARY KEY'
                 +', [ElementsProcessed] bit NULL'
                 +', [SurveyID] int NULL'
                 +', [Master_SurveyID] int NULL'
                 +', [SurveyDate] datetime NULL'
                 +', [AuditDate] datetime NULL'
                 +', [CL_EN_GEN_ID] int NULL'
                 +', [SiteID] int NULL'
                 +', [ProgramID] int NULL'
                 +', [IA_StaffID] int NULL'
                 +', [ClientID] int NULL'
                 +', [RespondentID] int NULL '
                 +', [DW_AuditDate] datetime NULL' 
                 +', [DataSource] nvarchar(10) NULL'
                 +', [Archive_Record] bit NULL)'  
            print @sql
            exec (@SQL)
            set @SQL = 'CREATE INDEX '+@DW_Survey_TableName +'_ElementsProcessed_ndx on ' + @DW_Survey_TableName 
                +' (ElementsProcessed)'  
            print @sql
            exec (@SQL)
            set @SQL = 'CREATE INDEX '+@DW_Survey_TableName +'_SurveyID_ndx on ' + @DW_Survey_TableName 
                +' (SurveyID)'  
            print @sql
            exec (@SQL)


           IF  @DW_Survey_TableName in ('Staff_Update_Survey')
           BEGIN
              set @SQL = 'CREATE INDEX '+@DW_Survey_TableName +'_CL_EN_GEN_ID_ndx on ' + @DW_Survey_TableName 
                +' (CL_EN_GEN_ID)'  
               print @sql
               exec (@SQL)
           END
 
        END

----------------------------------------------------------------------------------------
-- Add special validation columns to specific tables
----------------------------------------------------------------------------------------

     IF  @DW_Survey_TableName in ('New_Hire_Survey','Education_Registration_Survey')
     BEGIN
        
        EXEC @return_stat = dbo.SP_add_nonexisting_tbl_column @DW_Survey_TableName, 'Validation_Ind', 'nvarchar(100)'

        EXEC @return_stat = dbo.SP_add_nonexisting_tbl_column @DW_Survey_TableName, 'Validation_Comment', 'nvarchar(100)'
     END

     IF @SurveyType = 'Entity'
     BEGIN
        EXEC @return_stat = dbo.SP_add_nonexisting_tbl_column @DW_Survey_TableName, 'Entity_ID_Mapped', 'int'
     END


--   Continue with next Survey

     FETCH NEXT FROM SurveyCursor
      INTO @SurveyType
          ,@DW_Survey_Tablename;

  END  -- End while of Survey Cursor

CLOSE SurveyCursor
DEALLOCATE SurveyCursor


----------------------------------------------------------------------------------------
-- Add Elements to the Survey Table
----------------------------------------------------------------------------------------

--   Create a cursor to contain all elements in the survey, 
--   Then process each element, checking for existance,
--   altering the table if found to be missing:

DECLARE ElementsCursor Cursor FOR 
select distinct 
       Surveys.SurveyType
      ,Surveys.DW_TableName          
      ,SurveyElements.SurveyElementTypeID
      ,SurveyElements.pseudonym
  from dbo.Mstr_Surveys Surveys
  inner join dbo.Mstr_SurveyElements SurveyElements 
        on Surveys.surveyid = SurveyElements.surveyid
 where DW_TableName is not null
   and pseudonym is not null
   and SurveyElementTypeID <= 12
   and not exists (SELECT AC.[name]
                     FROM sys.[tables] T 
                     INNER JOIN sys.[all_columns] AC ON T.[object_id] = AC.[object_id] 
                    where t.name = DW_TableName
                      and ac.name = pseudonym);

--      Process the Elements cursor:
--
     OPEN ElementsCursor
     FETCH NEXT FROM ElementsCursor 
           INTO @SurveyType
               ,@DW_Survey_Tablename
               ,@ElementTypeID
               ,@pseudonym;

     WHILE @@FETCH_STATUS = 0
       BEGIN


        --print 'ElementID Pseudonym=' +@Pseudonym

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing Pseudonym'
      ,comment = @Pseudonym
      ,LogDate = getdate()
      ,Index_2 = null
 where Process = @process
--------------------------------------------- 

--      Check for existing table, 
--       (if not existing, table with basic common fields)
        if not exists (SELECT AC.[name]
                         FROM sys.[tables] T 
                        INNER JOIN sys.[all_columns] AC ON T.[object_id] = AC.[object_id] 
                        where t.name = @DW_Survey_TableName
                          and ac.name = @pseudonym)
        BEGIN
            print 'Column does not exist, creating new column: dbo.'+ @DW_Survey_TableName+'.'+@pseudonym
            set @SQL = 'Alter TABLE dbo.' + @DW_Survey_TableName 
              + ' ADD [' + Left(@pseudonym,100)+ '] '
              IF @ElementTypeID in (1) 
                 set @SQL = @SQL + ' nvarchar(3000) null'
              IF @ElementTypeID in (2) 
                 set @SQL = @SQL + ' varchar(500) null'
                -- (Stored as a number but gets converted to the full name field)
                -- set @SQL = @SQL + ' smallint null'
              IF  @ElementTypeID in (3,4) 
                 set @SQL = @SQL + ' varchar(7000) null'
              IF  @ElementTypeID in (6,7,8) 
                 set @SQL = @SQL + ' numeric(18,5) null'
              IF  @ElementTypeID in (9) 
                 set @SQL = @SQL + ' bit null'
              IF  @ElementTypeID in (10) 
                 set @SQL = @SQL + ' smalldatetime null'
              IF  @ElementTypeID in (11,12) 
                 set @SQL = @SQL + ' nvarchar(100) null'
                -- (Stored as a number but gets converted to the full name field)
                -- set @SQL = @SQL + ' int null'

            --print @sql
            exec (@SQL)
           END
--        Else
--           BEGIN
--               print 'Column Exists'
--           END

     FETCH NEXT FROM ElementsCursor 
           INTO @SurveyType
               ,@DW_Survey_Tablename
               ,@ElementTypeID
               ,@pseudonym;

END  -- End of Elements Cursor

CLOSE ElementsCursor
DEALLOCATE ElementsCursor


-- wrapup:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

print 'Surveys Processed: ' +convert(varchar,@cursor_count)
print 'End of Process - SP_Build_Survey_Tables'
GO
