USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_ENROLLMENTANDDISMISSAL]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_ENROLLMENTANDDISMISSAL
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_ENROLLMENTANDDISMISSAL]
 (@p_datasource      nvarchar(10) = null
 ,@p_no_delete_opt   nvarchar(2)  = null
 ,@p_no_exec_flag    nvarchar(10) = 'N')
AS
--
-- This script controls integration of AgencyDB Surveys to the Data Warehouse 
-- ENROLLMENTANDDISMISSAL table.
--
-- Will exclude from DW if Site Does not exist in dbo.agencies
--
-- Table effected - dbo.EnrollmentAndDismissal
--
-- Step 1: Delete existing EnrollmentAndDismissal records 
--         (should have already been donein the nightly interface, just making sure).
-- Step 2: Insert all AgencyDB.EnrollmentAndDismissal records into DW.
--
-- IDs translated via DW/AgencyDB Non_ETO_Xref mapping:
--    ClientID     (lookup, using DW.Client_ID)
--
-- History:
--   20130325 - New Procedure.
--   20130828 - Added CaseNumber, poplulated with same data as CLID.
--   20131111 - Added new columns to EnrollmentAndDissmissal to identify SourceTableID
--              so that table does not have to be deleted of old records first.
--              Will no insert when not existing, update when found changed at agencydb level.
--   20140326 - Added Site_ID qualifier by datasource, to allow multiple datasources to share the same AgencyDB.
--              Added database trigger to inhibit the processing of this procedure (defaulting as always process).
--                This trigger is used to bypass the process w/o having to modify the SSIS integration packages.
--   20140930 - Added option to not delete records.  This is to accommodate initial AgencyDB loads 
--              of smaller incremented batches while Agecncy is cleaning up data.  Option is 'Y' to inhibit delete.
--   20150328 - Added validation to re-mapping to ensure that the eto_surveyresponseid actually exists in the DW
--              for the site id, else will bypass re-mapping (thus creating new record to DW).
--              Added update to DW. Survey table's datasource for positive re-mappings.
--              Added option to not actually execute the SQL statements, used for validation/troubleshooting purposes.
--   20161201 - Amended the Update statement to update the CLID. Found that it can change from what originally may have in AgencyDB.

DECLARE @count        smallint
DECLARE @stop_flag  nvarchar(2)
DECLARE @Process      nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)
DECLARE @Agency_TableName   nvarchar(50)
DECLARE @Agency_Full_TableName   nvarchar(100)

set @process          = 'SP_AGENCYDB_ENROLLMENTANDDISMISSAL'
set @DW_Tablename     = 'ENROLLMENTANDDISMISSAL'
set @Agency_Tablename = 'ENROLLMENTANDDISMISSAL'
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)

print 'Processing SP_AGENCYDB_ENROLLMENTANDDISMISSAL: Datasource = ' +isnull(@p_datasource,'NULL')
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
   print 'Validate datasource DBSrvr from LOV tables'

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

-- format full table name with network path:
SET @Agency_Full_Tablename = @AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Agency_Tablename 

print 'AgencyDB=' + @AgencyDB +', AgencyDB Server=' +@AgencyDB_Srvr
----------------------------------------------------------------------------------------

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Re-sync between AgencyDb/DW'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

----------------------------------------------------------------------------------------

-- Re-sync non_ETO records to AgencyDB by Client, ProgramStartDate (that originated from ETO):
print ' '
print 'creating non_ETO_Xref for AgencyDB surveys that have been mapped to existing DW surveys'
set @SQL = 'set nocount off '+
+' Update dbo.ENROLLMENTANDDISMISSAL'
   +' set DataSource = ''' +@p_datasource +''''
       +',SourceTable = ''ENROLLMENTANDDISMISSAL'''
       +',SourceTableID = Atbl.RecID
   from dbo.ENROLLMENTANDDISMISSAL ead'
+' inner join dbo.Programs on ead.ProgramID = Programs.Program_ID'
+' inner join dbo.AgencyDB_Sites_By_DataSource asbd '
      +' on programs.Site_ID = asbd.Site_ID'
      +' and asbd.DataSource =  ''' +@p_datasource +''''
+' Inner join Non_ETO_Client_Xref xref on ead.CLID = xref.Client_ID'
+' Inner join ' +@Agency_Full_TableName +' Atbl'
      +' on xref.non_eto_id = atbl.CLID'
      +' and ead.ProgramID = atbl.ProgramID'
      +' and ead.ProgramStartDate = Atbl.ProgramStartDate'
+' where isnull(ead.DataSource,''ETO'') = ''ETO'''
+' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)



----------------------------------------------------------------------------------------
print ' '
print 'Inserting new Enrollment And Dismissal records'
print 'CONT: Insert new Records - AgencyDB=' + @AgencyDB
print 'AgencyDB Server=' +@AgencyDB_Srvr

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL = 'set nocount off '+
    'insert into dbo.ENROLLMENTANDDISMISSAL'
    +' ([DataSource]'
    +' ,[SourceTable]'
    +' ,[SourceTableID]'
    +' ,[CLID]'
    +' ,[CaseNumber]'
    +' ,[SiteID]'
    +' ,[ProgramID]'
    +' ,[ProgramStartDate]'
    +' ,[EndDate]'
    +' ,[ReasonForDismissal]'
    +' ,[AuditDate])'
    +'
     SELECT  ''' +@p_datasource +''''
    +' ,''ENROLLMENTANDDISMISSAL'''
    +' ,Atbl.RecID'
    +' ,cxref1.Client_ID'
    +' ,cxref1.Client_ID as CaseNumber' 
    +' ,Atbl.[SiteID]'
    +' ,Atbl.[ProgramID]'
    +' ,Atbl.[ProgramStartDate]'
    +' ,Atbl.[EndDate]'
    +' ,Atbl.[ReasonForDismissal]'
    +' ,Atbl.[AuditDate]'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.ENROLLMENTANDDISMISSAL Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' left join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source =  ''' +@p_datasource +''''
    +'   and cxref1.Non_ETO_ID = Atbl.CLID' 
    +' where not exists (select xtbl.RecID from dbo.ENROLLMENTANDDISMISSAL xtbl'
                   +' where isnull(xtbl.DataSource,''ETO'') = ''' +@p_datasource +''''
                   +' and xtbl.SourceTable = ''ENROLLMENTANDDISMISSAL'''
                   +' and xtbl.SourceTableID = Atbl.RecID)'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'
     

    print @SQL
    print 'Length = ' +CAST(LEN(@SQL) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)


----------------------------------------------------------------------------------------
print ' '
print 'Updateing Enrollment And Dismissal records'
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL = 'set nocount off '+
    'Update dbo.ENROLLMENTANDDISMISSAL'
    +' set CLID = cxref1.Client_ID' 
    +' ,CaseNumber = cxref1.Client_ID' 
    +' ,SiteID = Atbl.[SiteID]'
    +' ,ProgramID = Atbl.[ProgramID]'
    +' ,ProgramStartDate = Atbl.[ProgramStartDate]'
    +' ,EndDate = Atbl.[EndDate]'
    +' ,ReasonForDismissal = Atbl.[ReasonForDismissal]'
    +' ,AuditDate = Atbl.[AuditDate]'
    +'
     from dbo.ENROLLMENTANDDISMISSAL ead'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.ENROLLMENTANDDISMISSAL Atbl'
    +'   on ead.SourceTableID = Atbl.RecID'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' left join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source =  ''' +@p_datasource +''''
    +'   and cxref1.Non_ETO_ID = Atbl.CLID' 
    +' WHERE isnull(ead.DataSource,''ETO'') = ''' +@p_datasource +''''
    +' and ead.SourceTable = ''ENROLLMENTANDDISMISSAL'''
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'
    +' and isnull(ead.AuditDate,convert(datetime,''19700101'',112)) != Atbl.AuditDate'     

    print @SQL
    print 'Length = ' +CAST(LEN(@SQL) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)


----------------------------------------------------------------------------------------
print 'CONT: Deleting Records'
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Deleting Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

IF upper(isnull(@p_no_delete_opt,'n')) != 'Y'
BEGIN

set @SQL = 'set nocount off '+
    'delete from dbo.ENROLLMENTANDDISMISSAL'
    +' where RecID in ('
    +' Select RecID'
    +'
     from dbo.ENROLLMENTANDDISMISSAL ead'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = ead.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' WHERE isnull(ead.DataSource,''ETO'') = ''' +@p_datasource +''''
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', ead.SiteID) is null'
    +' and ead.SourceTable = ''ENROLLMENTANDDISMISSAL'''
    +' and not exists (select RecID from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.ENROLLMENTANDDISMISSAL Atbl'    
       +' where Atbl.RecId = ead.SourceTableID) )'

    print @SQL
    print 'Length = ' +CAST(LEN(@SQL) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)
END

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

print 'End of Process: SP_AGENCYDB_ENROLLMENTANDDISMISSAL'
GO
