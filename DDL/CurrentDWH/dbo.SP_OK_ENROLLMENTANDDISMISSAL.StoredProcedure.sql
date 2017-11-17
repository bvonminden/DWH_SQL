USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_OK_ENROLLMENTANDDISMISSAL]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_OK_ENROLLMENTANDDISMISSAL
--
CREATE PROCEDURE [dbo].[SP_OK_ENROLLMENTANDDISMISSAL]
 (@p_SurveyResponseID       int = null)
AS
--
-- This script controls integration of Oklahoma Surveys to the Data Warehouse 
-- ENROLLMENTANDDISMISSAL table.
--
-- ** Defaulting: Datasource as 'OKLAHOMA'
--                Audit_StaffID = 4614, EntityID=13048, name=Data Migration2, for site 260
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
--   20131218 - New Procedure.

DECLARE @p_datasource nvarchar(10)
DECLARE @count        smallint
DECLARE @p_stop_flag  nvarchar(2)
DECLARE @Process      nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr    nvarchar(30)
DECLARE @DW_TableName     nvarchar(50)
DECLARE @Source_TableName nvarchar(50)
DECLARE @ETO_Audit_StaffID     int

set @process = 'SP_OK_ENROLLMENTANDDISMISSAL'
set @DW_Tablename = 'ENROLLMENTANDDISMISSAL'
set @Source_Tablename = 'VIEW_ENROLLMENTANDDISMISSAL_DW'
Set @p_stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()
set @p_datasource = 'OKLAHOMA'
set @ETO_Audit_StaffID = 4614

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)

print 'Processing SP_OK_ENROLLMENTANDDISMISSAL: Datasource = ' +isnull(@p_datasource,'NULL')
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
print 'Processing SP_OK_ENROLLMENTANDDISMISSAL - retrieving datasource DB Srvr from LOV tables'

set @AgencyDB = null;
select @AgencyDB = Value
  from dbo.View_LOV
 where Name = 'AGENCYDB_BY_DATASOURCE'
   and lOV_Item = @p_datasource

IF @AgencyDB is null
BEGIN
   --set @p_flag_stop = 'X';
   print 'Unable to retrieve LOV AgencyDB for datasource, job stopped'
   set nocount on
   update dbo.process_log 
   set Comment = 'failed, can''t retrieve LOV AgencyDB for datasource'
      ,LogDate = getdate()
 where Process = @process

END
ELSE
BEGIN

----------------------------------------------------------------------------------------
print 'Processing SP_Contacts - Insert new Records - AgencyDB=' + @AgencyDB
print 'AgencyDB Server=' +@AgencyDB_Srvr

-- Extraction for Client:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL = 'insert into '+@DW_Tablename +
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
    +' ,[AuditStaffID]'
    +' ,[AuditDate])'
    +'
     SELECT  ''' +@p_datasource +''''
    +' , '''+@Source_Tablename +''''
    +' ,Atbl.AnswerID'
    +' ,cxref1.Client_ID'
    +' ,cxref1.Client_ID as CaseNumber' 
    +' ,Atbl.[SiteID]'
    +' ,Atbl.[ProgramID]'
    +' ,Atbl.[ProgramStartDate]'
    +' ,Atbl.[EndDate]'
    +' ,Atbl.[ReasonForDismissal]'
    +' ,' +convert(varchar,@ETO_Audit_StaffID)
    +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +' Atbl'
    +' left join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source =  ''' +@p_datasource +''''
    +'   and cxref1.Non_ETO_ID = Atbl.CLID' 
    +' where not exists (select xtbl.recid from dbo.ENROLLMENTANDDISMISSAL xtbl'
                   +' where xtbl.DataSource = ''' +@p_datasource +''''
                   +' and xtbl.SourceTable = '''+@Source_Tablename +''''
                   +' and xtbl.SourceTableID = Atbl.AnswerID)'
     

    print @SQL
    print 'Length = ' +CAST(LEN(@SQL) as varchar)
    EXEC (@SQL)


----------------------------------------------------------------------------------------
print 'Processing SP_Contacts - Updating changed Records'
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL = 'Update dbo.ENROLLMENTANDDISMISSAL'
    +' set CLID = cxref1.Client_ID'
    +' ,CaseNumber = cxref1.Client_ID' 
    +' ,SiteID = Atbl.[SiteID]'
    +' ,ProgramID = Atbl.[ProgramID]'
    +' ,ProgramStartDate = Atbl.[ProgramStartDate]'
    +' ,EndDate = Atbl.[EndDate]'
    +' ,ReasonForDismissal = Atbl.[ReasonForDismissal]'
    +', [DW_AuditDate] = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from dbo.ENROLLMENTANDDISMISSAL ead'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +' Atbl'
    +'   on ead.SourceTableID = Atbl.AnswerID'
    +' left join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source =  ''' +@p_datasource +''''
    +'   and cxref1.Non_ETO_ID = Atbl.CLID' 
    +' WHERE ead.DataSource = ''' +@p_datasource +''''
    +' and ead.SourceTable = '''+@Source_Tablename +''''
    +' and isnull(ead.AuditDate,convert(datetime,''19700101'',112)) != Atbl.AuditDate'     

    print @SQL
    print 'Length = ' +CAST(LEN(@SQL) as varchar)
    --EXEC (@SQL)


----------------------------------------------------------------------------------------
print 'Processing SP_Contacts - Deleting Records'
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Deleting Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL = 'delete from dbo.ENROLLMENTANDDISMISSAL'
    +' where RecID in ('
    +' Select RecID'
    +'
     from dbo.ENROLLMENTANDDISMISSAL ead'
    +' WHERE ead.DataSource = ''' +@p_datasource +''''
    +' and ead.SourceTable = '''+@Source_Tablename +''''
    +' and not exists (select RecID from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +' Atbl'    
       +' where Atbl.RecId = ead.SourceTableID) )'

    print @SQL
    print 'Length = ' +CAST(LEN(@SQL) as varchar)
    --EXEC (@SQL)


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

print 'End of Process: SP_OK_ENROLLMENTANDDISMISSAL'
GO
