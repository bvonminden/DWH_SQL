USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_ENTITYXPROGRAMS]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_ENTITYXPROGRAMS
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_ENTITYXPROGRAMS]
 (@p_datasource      nvarchar(10) = null
 ,@p_no_delete_opt   nvarchar(2)  = null
 ,@p_no_exec_flag    nvarchar(10) = 'N')
AS
--
-- This script controls integration of AgencyDB Surveys to the Data Warehouse 
-- ENTITYXPROGRAMS table.
--
-- Table effected - dbo.ENTITYXPROGRAMS  
--                  dbo.ENTITYXPROGRAMHX 
--
-- IDs translated via DW/AgencyDB Non_ETO_Xref mapping:
--    EntityID     (lookup, using DW.Entity_ID)
--
-- History:
--   20131112 - New Procedure.
--   20140326 - Added Site_ID qualifier by datasource, to allow multiple datasources to share the same AgencyDB.
--              Added database trigger to inhibit the processing of this procedure (defaulting as always process).
--                This trigger is used to bypass the process w/o having to modify the SSIS integration packages.
--   20140708 - changed to use agencydb in all calls (replacing agencydb10)
--   20140930 - Added option to not delete records.  This is to accommodate initial AgencyDB loads 
--              of smaller incremented batches while Agecncy is cleaning up data.  Option is 'Y' to inhibit delete.
--   20150301 - Updated for better maintenance from AgencyDB and for newly started integrations.
--   20150310 - Changed to move historical records not in sync to EntityxProgramsHX_ETOx.
--              This is becuase the EntityXProgramHX_ID is no longer valid, and can not be left null in
--              the EntityxProgramsHX table.
--   20150401 - Amended to include all programs for an entity.  Originally just pulled in '%HOME%' programs only.
--              Uncommented the delete entityxprograms records no longer existing in AgencyDB.
--   20161101 - Fixed problem in qualifying updates to EntityXPrograms (joining progams to the entityxprograms by program_id).
--              Also reworked start/end date comparisons for update.
--
-- Process:
--   - sync up betwen AgencyDB and DW via non_eto_entities per entity_id and start_date
--      (used as a starting point for new AgencyDB integration that has moved from ETO)
--   - Move to EntityXProgramHX where old ETO records are not re-synced.
--   - Add new current EntityxPrograms from AgencyDB by start_date.
--   - Update current EntityxPrograms from AgencyDB with any new end_date.

DECLARE @count        smallint
DECLARE @stop_flag  nvarchar(2)
DECLARE @Process      nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)

set @process = 'SP_AGENCYDB_ENTITYXPROGRAMS'
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)

print 'Processing SP_AGENCYDB_ENTITYXPROGRAMS: Datasource = ' +isnull(@p_datasource,'NULL')
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
print 'Cont: Check for run inhibit trigger'

IF dbo.FN_Check_Process_Inhibitor (@process, @p_datasource, null) is not null 

BEGIN
   set @stop_flag = 'X';
   print 'Process Inhibited via Process_Inhibitor Table, job stopped'
   set nocount on
   update dbo.process_log 
   set Comment = 'Process Inhibited via Process_Inhibitor Table, job stopped'
      ,LogDate = getdate()
 where Process = @process
END

IF @stop_flag is null
BEGIN
   print 'Processing SP_AGENCYDB_IA_STAFF - Validate datasource DBSrvr from LOV tables'

   set @AgencyDB = null;
   select @AgencyDB = Value
     from dbo.View_LOV
    where Name = 'AGENCYDB_BY_DATASOURCE'
      and lOV_Item = @p_datasource

   IF @AgencyDB is null
   BEGIN
      set @stop_flag = 'X';
      print 'Unable to retrieve LOV AgencyDB for datasource=' +isnull(@AgencyDB,'') +', job stopped'
      set nocount on
      update dbo.process_log 
      set Comment = 'failed, can''t retrieve LOV AgencyDB for datasource'
         ,LogDate = getdate()
    where Process = @process
   END
END 

IF @stop_flag is null 
BEGIN

----------------------------------------------------------------------------------------
print ' '
print 'AgencyDB Server=' +@AgencyDB_Srvr +', AgencyDB ' + @AgencyDB

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Sync up New Integration Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

print ' '
print 're-sync AgencyDB to DW on Entity/start_Date for existing ETO records'
set @SQL = 'set nocount off '+
   ' update dbo.ENTITYXPROGRAMS'
     +' set datasource = ''' +@p_datasource +''''
         +',EntityXProgram_ID = aexp.RecID'
    +' from dbo.ENTITYXPROGRAMS exp'
    +' inner join dbo.Programs on exp.program_ID = Programs.Program_ID'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd'
          +' on asbd.Site_ID = Programs.Site_ID'
          +' and asbd.DataSource =  ''' +@p_datasource +''''
    +' inner join dbo.non_eto_entity_xref neex'
          +' on exp.entity_id = neex.entity_id'
          +' and neex.Source = ''' +@p_datasource +''''
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.ENTITYXPROGRAMHX aexp'
          +' on neex.non_eto_id = aexp.EntityID'
          +' and aexp.ProgramID = exp.Program_ID'
          +' and convert(char,aexp.startdate,112) = convert(char,exp.StartDate,112)'
    +' where isnull(exp.DataSource,''ETO'') != ''' +@p_datasource +''''

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)



print ' '
print 'Move to history all Site ETO records not in sync with the AgencyDB (by Site_ID)'
set @SQL = 'set nocount off '+
   ' insert into dbo.ENTITYXPROGRAMHX_ETOx'
     +' (DataSource, EntityXProgramID, EntityID, ProgramID, StartDate, EndDate, AuditDate) 
select exp.datasource +''x'''
   +',exp.EntityXProgram_ID'
   +',exp.Entity_ID'
   +',exp.Program_ID'
   +',exp.StartDate'
   +',exp.EndDate'
   +',exp.AuditDate
 from dbo.ENTITYXPROGRAMS exp'
+' inner join dbo.Programs on exp.program_ID = Programs.Program_ID'
+' inner join dbo.AgencyDB_Sites_By_DataSource asbd'
      +' on asbd.Site_ID = Programs.Site_ID'
      +' and asbd.DataSource =  ''' +@p_datasource +''''
+' where isnull(exp.DataSource,''ETO'') = ''ETO'''
  +' and not exists (select recid from dbo.EntityXProgramHx_ETOx exph'
                   +' where exph.ProgramID = programs.Program_ID'
                     +' and exph.StartDate = exp.StartDate'
                     +' and exph.EntityXProgramID = exp.EntityXProgram_ID'
                     +' and exph.EntityID = exp.Entity_ID)'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)


print ' '
print 'Remove all ETO records for site that are not in sync with the AgencyDB'
set @SQL = 'set nocount off '+
   ' delete from dbo.ENTITYXPROGRAMS'
   +' where RecID in (
select exp.RecID
 from dbo.ENTITYXPROGRAMS exp'
+' inner join dbo.Programs on exp.program_ID = Programs.Program_ID'
+' inner join dbo.AgencyDB_Sites_By_DataSource asbd'
      +' on asbd.Site_ID = Programs.Site_ID'
      +' and asbd.DataSource =  ''' +@p_datasource +''''
+' where isnull(exp.DataSource,''ETO'') = ''ETO'''
  +' and exists (select recid from dbo.EntityXProgramHx_ETOx exph'
               +' where exph.ProgramID = programs.Program_ID'
                 +' and exph.StartDate = exp.StartDate'
                 +' and exph.EntityXProgramID = exp.EntityXProgram_ID'
                 +' and exph.EntityID = exp.Entity_ID)'
+')'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)

---------------------------------------------
-- Maintain the EntityXPrograms table:

print ' '
print 'Inserting new records from AgencyDB'
set @SQL = 'set nocount off '+
   'insert into dbo.ENTITYXPROGRAMS'
    +' ([DataSource]'
    +' ,[EntityXProgram_ID]'
    +' ,[Entity_ID]'
    +' ,[Program_ID]'
    +' ,[StartDate]'
    +' ,[EndDate]'
    +' ,[AuditDate])'
    +'
     SELECT  ''' +@p_datasource +''''
    +' ,aexp.RecID'
    +' ,exref1.Entity_ID'
    +' ,aexp.ProgramID'
    +' ,aexp.STARTDATE'
    +' ,aexp.ENDDATE'
    +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.ENTITYXPROGRAMHX aexp'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.IA_Staff ais on aexp.entityid = ais.entity_id'

    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = ais.Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''

    +' Inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Programs on aexp.programid = Programs.Program_ID'

    +' left join dbo.Non_ETO_Entity_Xref exref1 on exref1.Source =  ''' +@p_datasource +''''
    +'   and exref1.Non_ETO_ID = aexp.EntityID' 

    +' Where not exists (select RecID from dbo.EntityXPrograms exp'
                       +' where exp.DataSource = ''' +@p_datasource +''''
                         +' and exp.EntityxProgram_ID = aexp.RecID'
                       +')'
      +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', ais.Site_ID) is null'
     

    print @SQL
    print 'Length = ' +CAST(LEN(@SQL) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)



-- Updates for End Dated records
print ' '
print 'Updating existing records linked between AgencyDB and DW'
set @SQL = 'set nocount off '+
   'update dbo.ENTITYXPROGRAMS'
    +' set Entity_ID = exref1.Entity_ID'
    +' ,StartDate = aexp.StartDate'
    +' ,EndDate = aexp.EndDate'
    +' ,AuditDate = '
    +'   convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from dbo.programs'

    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = programs.Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''

    +' inner join dbo.EntityXPrograms exp on Programs.program_id = exp.program_id'

    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.ENTITYXPROGRAMHX aexp on exp.EntityXProgram_ID = aexp.RecID'

    +' left join dbo.Non_ETO_Entity_Xref exref1 on exref1.Source =  ''' +@p_datasource +''''
    +'   and exref1.Non_ETO_ID = aexp.EntityID' 

    +' Where exp.datasource = ''' +@p_datasource +''''
    +'   and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', programs.Site_ID) is null
       and ((isnull(exp.startdate,''1970-01-01 00:00:00.000'') 
               != isnull(aexp.startdate,''1970-01-01 00:00:00.000'')) or
       (isnull(exp.enddate,''1970-01-01 00:00:00.000'') 
               != isnull(aexp.enddate,''1970-01-01 00:00:00.000'')) or
       (isnull(exref1.entity_id,isnull(exp.entity_id,999999999)) 
               != isnull(exp.entity_id,999999999)))'
     

    print @SQL
    print 'Length = ' +CAST(LEN(@SQL) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)


----------------------------------------------------------------------------------------
-- Remove records that no longer exist in AgencyDb

if upper(isnull(@p_no_delete_opt,'n')) != 'Y'
BEGIN

print ' '
print 'Removing records where no longer exising in AgencyDB'
set @SQL = 'set nocount off '+
   'delete dbo.ENTITYXPROGRAMS'
    +'
     from dbo.ENTITYXPROGRAMS exp'
    +' inner join dbo.programs on exp.program_id = programs.program_ID' 

    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = programs.Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''

    +' Where exp.datasource = ''' +@p_datasource +''''
    +'   and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', programs.Site_ID) is null'
    +'   and not exists (select aexp.recid from ' +@AgencyDB_Srvr +'.' +@AgencyDB 
                          +'.dbo.ENTITYXPROGRAMHX aexp where exp.EntityXProgram_ID = aexp.RecID)'

    print @SQL
    print 'Length = ' +CAST(LEN(@SQL) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)
END

----------------------------------------------------------------------------------------
-- Maintain EntityXProgramHX table:


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

END /* end of stop validation */

print 'End of Process: SP_AGENCYDB_ENTITYXPROGRAMS'
GO
