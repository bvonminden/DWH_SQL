USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_RE_DATASOURCE_SURVEYS]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_RE_DATASOURCE_SURVEYS
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_RE_DATASOURCE_SURVEYS]
 (@p_datasource      nvarchar(10)
 ,@p_update_option   nvarchar(10)
 ,@p_no_exec_flag    nvarchar(10) = 'N')
AS
--
-- This procedure is used to Re-DataSource the surveys coming from the AgencyDB,
-- as an initializing process when an Agency is first setup to be integrated via the AgencyDB process.
-- ** this is run manually, and only needed once for a site setup.
--
-- This updates all the Survey records pertaining to the AgencyDB SiteID, 
-- setting the DataSource to the AgencyDB DataSource,
-- so that nightly integration will effect only those records matching the AgencyDB DataSource.
--
-- Update Options: 
--    'ALL'   - update change datasource for all site records, 
--    'MATCH' - update only survey records that have a corresponding AgencyDB Survey record on ETO_SurveyResponseID.
--              Used on sites (SC 218) that have history in ETO, not included in the AgencyDB.
--
-- History:
--   20150213 - New Procedure.
--
-- LOV lookup driven for the surveys to update:
-- LOV_Name: AGENCYDB_SURVEY_TABLE_NAMES'
--           LOV_Values.LOV_Item = DW Survey Table Name
--           LOV_Values.Value    = AgencyDB Survey Table Name


DECLARE @count        smallint
DECLARE @stop_flag    nvarchar(2)
DECLARE @Process      nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)
DECLARE @Agency_TableName   nvarchar(50)
DECLARE @Agency_full_TableName   nvarchar(100)
DECLARE @Trial_Mode     nvarchar(30)

set @process = 'SP_AGENCYDB_RE_DATASOURCE_SURVEYS'
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()
set @Trial_Mode = ' '

DECLARE @AgencyDB       nvarchar(50)
DECLARE @SQL            nvarchar(4000)

If @p_no_exec_flag = 'Y'
   set @Trial_Mode = ' (Trial Mode - NO UPDATE)'

print 'Processing SP_AGENCYDB_RE_DATASOURCE_SURVEYS: Datasource = ' +isnull(@p_datasource,'NULL')
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

print 'Cont: Processing - AgencyDB=' + @AgencyDB
print 'AgencyDB Server=' +@AgencyDB_Srvr

----------------------------------------------------------------------------------------
-- Build and process cursor of Surveys to processes 
----------------------------------------------------------------------------------------

DECLARE SurveyNameCursor Cursor for
select LOV_Item as DW_SurveyTable
      ,Value    as AgencyDB_SurveyTable
     from dbo.View_LOV
    where Name = 'AGENCYDB_SURVEY_TABLE_NAMES'

OPEN SurveyNameCursor

FETCH next from SurveyNameCursor
      into @DW_TableName
          ,@Agency_TableName

WHILE @@FETCH_STATUS = 0
BEGIN

-- format full table name with network path:
SET @Agency_Full_Tablename = @AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Agency_Tablename 


----------------------------------------------------------------------------------------
print ' '
print 'Processing Tables: DW = ' + @DW_TableName +', Agency=' +@Agency_TableName

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Survey: ' +@DW_TableName
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------


-- Update DataSource:
IF upper(@p_update_option) = 'MATCH'
BEGIN
IF @DW_Tablename in ('EnrollmentAndDismissal')
  print '** MATCH Exclusion for table: ' +@DW_TableName
ELSE
   Begin
   print 'MATCH Only Update for site records' +@Trial_Mode
   set @SQL = 'set nocount off '+
    'update ' +@DW_TableName
    +' Set DataSource = ''' +@p_datasource +''''
    +'
     from ' +@DW_TableName +' dwtbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = dwtbl.SiteID'
      +' and asbd.DataSource =  ''' +@p_datasource +''''
    +' inner join ' +@Agency_Full_TableName +' Atbl'
       +' on dwtbl.SurveyResponseID = Atbl.ETO_SurveyResponseID'
    +' Where dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'
      +' and isnull(dwtbl.DataSource,''ETO'') != ''' +@p_datasource +''''

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
       EXEC (@SQL)
   END
END


IF upper(@p_update_option) = 'ALL'
BEGIN
print 'ALL Update for site records' +@Trial_Mode
set @SQL = 'set nocount off '+
    'update ' +@DW_TableName
    +' Set DataSource = ''' +@p_datasource +''''
    +'
     from ' +@DW_TableName +' dwtbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = dwtbl.SiteID'
      +' and asbd.DataSource =  ''' +@p_datasource +''''
    +' Where dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', asbd.Site_ID) is null'
      +' and isnull(dwtbl.DataSource,''ETO'') != ''' +@p_datasource +''''

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
      EXEC (@SQL)
END

----------------------------------------------------------------------------------------
-- COntinue and retrieve next record in cursor
   FETCH next from SurveyNameCursor
         into @DW_TableName
             ,@Agency_TableName

END -- End of SurveyNameCursor loop

CLOSE SurveyNameCursor
DEALLOCATE SurveyNameCursor

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

print 'End of Process: SP_AGENCYDB_RE_DATASOURCE_SURVEYS'
GO
