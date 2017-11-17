USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_UPDATE_MSTR_LOVs]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- drop proc dbo.SP_AGENCYDB_UPDATE_MSTR_LOVs
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_UPDATE_MSTR_LOVs]
 (@p_AgencyDB      nvarchar(30) = null
 ,@p_no_exec_flag    nvarchar(10) = 'N')
AS
--
-- This script controls the update of AgencyDB Mstr LOV tables within the AgencyDB.
--   The LOV_Names and LOV_Values tables will be used in the AgencyDB for Constraint validation and translations.
--   The data to populate the LOV tables may come from a varied source of either tables, other LOVs, 
--   or a hard coded list.
--
--   Creates a cursor of AgencyDBs, then process each database accordingly.
--   ** Can override cursor selection by running with a AgencyDB parameter for only one AgencyDB.
--
--
-- Table effected - dbo.LOV_Names
--                  dbo.LOV_Values
--
-- Inserts new records to AgencyDB when LOV_Values do not yet exist.  
-- Delete does not occur, but will evaluate between databases, and when the source 
--    no longer contain an active indicator,value, then the AgencyDB LOV_Value record is disabled.
--
-- History:
--   20151210 - New Procedure.
--
-- List of LOVs being maintaintained:
--   'ReasonForDismissal' - sourced from etosolaris.dbo.ReasonsForDismissal
--   'ReasonForReferral'  - sourced from etosolaris.dbo.ReasonsForReferral

DECLARE @count          smallint
DECLARE @stop_flag      nvarchar(2)
DECLARE @Process        nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)

set @process = 'SP_AGENCYDB_UPDATE_MSTR_LOVs'
set @DW_Tablename = null
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)
DECLARE @SQL1           varchar(MAX)
DECLARE @SQL2           varchar(MAX)

print 'Processing SP_AGENCYDB_UPDATE_MSTR_LOVs: AgencyDB = ' +isnull(@p_AgencyDB,'NULL')
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
-- Process the AgencyDB Cursor
----------------------------------------------------------------------------------------

DECLARE AgencyDBCursor Cursor for
select distinct(LOV.value)
  from dbo.view_lov LOV
 where Name='AGENCYDB_BY_DATASOURCE'
   -- exclude DB not using Mstr tables
   and LOV.Value != 'OklahomaStaging'
   -- qualified selection:
   and isnull(@p_AgencyDB,'abcdefg') in ('abcdefg',LOV.value)
 order by LOV.Value;

OPEN AgencyDBCursor

FETCH next from AgencyDBCursor
      into @AgencyDB

WHILE @@FETCH_STATUS = 0
BEGIN

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
print ''
print '  Processing AgencyDB:' + @AgencyDB +' - ReasonForDismissal'


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'ReasonForDismissal'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- Insert initial LOV_Name:
Set @SQL1 = 'set nocount off'
    +' insert into ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.LOV_Names'
    +' (Name) '
    +' select ''ReasonForDismissal'''
    +' where not exists (select Atbl.Name'
                        +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.LOV_Names Atbl'
                       +' where Atbl.Name = ''ReasonForDismissal'')'

    print ' '
    print @SQL1
    --print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
       EXEC (@SQL1)



-- Insert LOV_Values (Item list):
set @SQL1 = 'set nocount off'
    +' insert into ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.LOV_Values'
    +' (LOV_Name_ID,LOV_Item, Disabled)
     SELECT lovn.LOV_Name_ID'
        +' ,SrcTbl.ReasonForDismissal'
        +' ,0'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.LOV_Names lovn'
       +' ,etosolaris.dbo.ReasonsForDismissal SrcTbl'
    +' where lovn.Name = ''ReasonForDismissal'''
      +' and SrcTbl.disabled = 0'
      +' and not exists (select lovv.LOV_Value_ID'
                        +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.LOV_Values lovv'
                       +' where lovv.LOV_Name_ID = lovn.LoV_Name_ID'
                         +' and lovv.LOV_Item = SrcTbl.ReasonForDismissal)'
      +' group by lovn.LOV_Name_ID, SrcTbl.ReasonForDismissal'

    print ' '
    print @SQL1
    --print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
       EXEC (@SQL1)


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
print ''
print '  Processing AgencyDB:' + @AgencyDB +' - ReasonForReferral'


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'ReasonForReferral'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- Insert initial LOV_Name:
Set @SQL1 = 'set nocount off'
    +' insert into ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.LOV_Names'
    +' (Name) '
    +' select ''ReasonForReferral'''
    +' where not exists (select Atbl.Name'
                        +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.LOV_Names Atbl'
                       +' where Atbl.Name = ''ReasonForReferral'')'

    print ' '
    print @SQL1
    --print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
       EXEC (@SQL1)



-- Insert LOV_Values (Item list):
set @SQL1 = 'set nocount off'
    +' insert into ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.LOV_Values'
    +' (LOV_Name_ID,LOV_Item, Disabled)
     SELECT lovn.LOV_Name_ID'
        +' ,SrcTbl.ReasonForReferral'
        +' ,0'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.LOV_Names lovn'
       +' ,etosolaris.dbo.ReasonsForReferral SrcTbl'
    +' where lovn.Name = ''ReasonForReferral'''
      +' and SrcTbl.disabled = 0'
      +' and not exists (select lovv.LOV_Value_ID'
                        +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.LOV_Values lovv'
                       +' where lovv.LOV_Name_ID = lovn.LoV_Name_ID'
                         +' and lovv.LOV_Item = SrcTbl.ReasonForReferral)'
      +' group by lovn.LOV_Name_ID, SrcTbl.ReasonForReferral'

    print ' '
    print @SQL1
    --print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
       EXEC (@SQL1)


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- Continue Cursor:
   FETCH next from AgencyDBCursor
         into @AgencyDB

END -- End of AgencyDBCursor loop

CLOSE AgencyDBCursor
DEALLOCATE AgencyDBCursor

----------------------------------------------------------------------------------------
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------


print 'End of Process: SP_AGENCYDB_UPDATE_MSTR_LOVs'
GO
