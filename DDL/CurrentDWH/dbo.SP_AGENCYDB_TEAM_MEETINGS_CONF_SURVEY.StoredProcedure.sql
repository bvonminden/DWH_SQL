USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_TEAM_MEETINGS_CONF_SURVEY]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_TEAM_MEETINGS_CONF_SURVEY
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_TEAM_MEETINGS_CONF_SURVEY]
 (@p_datasource      nvarchar(10) = null
 ,@p_no_delete_opt   nvarchar(2)  = null
 ,@p_no_exec_flag    nvarchar(10) = 'N')
AS
--
-- This script controls integration of AgencyDB Surveys to the Data Warehouse 
-- TEAM_MEETINGS_CONF_SURVEY table.
--
-- Will exclude from DW if Site Does not exist in dbo.agencies
--
-- Table effected - dbo.Clients
--
-- Insert: select and insert when record is found to be missing in the DW.
-- Update: select and update when record exists in DW and has been changed but has been changed flagged by Audit_Date.
--
-- IDs translated via DW/AgencyDB Non_ETO_Xref mapping:
--    CL_EN_GEN_ID (lookup, using DW.Client_ID)
--    ClientID     (lookup, using DW.Client_ID)
--    NurseID      (lookup, using DW.Entity_ID)
--
-- History:
--   20130401 - New Procedure.
--   20140626 - Removed IA_StaffID (was being populated with non_eto data).
--   20140917 - Added population of Master_SurveyID colummn.
--   20140930 - Changed to utilize the ETO SurveyResponse record if found, 
--              creating the xref from the client-defined ID mapping to the orig ETO_SurveyResponseID
--              Else if not identified: create new xref record with next available Non_Entity_ID in sequence.
--   20140930 - Added option to not delete records.  This is to accommodate initial AgencyDB loads 
--              of smaller incremented batches while Agecncy is cleaning up data.  Option is 'Y' to inhibit delete.
--   20150218 - Added validation to re-mapping to ensure that the eto_surveyresponseid actually exists in the DW
--              for the site id, else will bypass re-mapping (thus creating new record to DW).
--              Added update to DW. Survey table's datasource for positive re-mappings.
--              Added option to not actually execute the SQL statements, used for validation/troubleshooting purposes.
--   20160706 - Added additional conditional logic to match siteid when looking up xrefs to entities and clients,
--              to accommodate multiple sites within the same AgencyDB, using same numbering scheme between sites.


DECLARE @count          smallint
DECLARE @stop_flag      nvarchar(2)
DECLARE @Process        nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)
DECLARE @Agency_TableName        nvarchar(50)
DECLARE @Agency_Full_TableName   nvarchar(100)

set @process          = 'SP_AGENCYDB_TEAM_MEETINGS_CONF_SURVEY'
set @DW_Tablename     = 'TEAM_MEETINGS_CONF_SURVEY'
set @Agency_Tablename = 'TEAM_MEETINGS_CONF_SURVEY'
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)
DECLARE @SQL1            nvarchar(MAX)
DECLARE @SQL2            nvarchar(MAX)
DECLARE @SQL3            nvarchar(MAX)

print 'Processing SP_AGENCYDB_TEAM_MEETINGS_CONF_SURVEY: Datasource = ' +isnull(@p_datasource,'NULL')
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

----------------------------------------------------------------------------------------
print 'Cont: Insert new Records - AgencyDB=' + @AgencyDB
print 'AgencyDB Server=' +@AgencyDB_Srvr

-- Extraction for Client:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------


----------------------------------------------------------------------------------------
-- clearout secondary replicated ETO_SurveyResponseID from the AgencyDB Survey table:
-- If the ETO_SureveyResponseID is not cleared for the secondary records,
-- then the next process which creates the Non_ETO_SurveyResponse_Xref will fail
-- due to the unique constraint on SurveyResponseID (coming from the mapped ETO_SurveyResponseID)

set @SQL = ''
set @SQL = 'set nocount off 
 Declare DupsCursor cursor for
 select distinct(dups.ETO_SurveyResponseID) 
 from  ' +@Agency_Full_TableName +' dups
  where (select COUNT(*) from ' +@Agency_Full_TableName +' dups2
  where dups2.ETO_SurveyResponseID = dups.ETO_SurveyResponseID) > 1
 Declare @Dup_ETO_SurveyResponseID int
 Open DupsCursor
 Fetch next from DupsCursor into @Dup_ETO_SurveyResponseID
 While @@FETCH_STATUS = 0
 Begin 
 update ' +@Agency_Full_TableName +'
 set ETO_SurveyResponseID = null
 where SurveyResponseID in 
 (select SurveyResponseID
  from (
 select ROW_NUMBER() OVER (ORDER BY atbl.ETO_SurveyResponseID) AS Row
      ,atbl.SurveyResponseID, atbl.SurveyDate, atbl.ETO_SurveyResponseID
 from ' +@Agency_Full_TableName +' atbl
 where atbl.ETO_SurveyResponseID = @Dup_ETO_SurveyResponseID) duprecs
 where ROW > 1)
 Fetch next from DupsCursor into @Dup_ETO_SurveyResponseID
 End				
 CLOSE DupsCursor
 DEALLOCATE DupsCursor'


    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)

----------------------------------------------------------------------------------------

-- create non_ETO xref entries for new SurveyResponse records from AgencyDB (that originated from ETO):
print ' '
print 'creating non_ETO_Xref for AgencyDB surveys that have been mapped to existing DW surveys'
set @SQL = 'set nocount off '+
    ' set identity_insert dbo.non_eto_SurveyResponse_xref on '
    +' insert into dbo.Non_ETO_SurveyResponse_Xref'
    +' (SurveyResponseID, Non_ETO_ID, Non_ETO_Site_ID, Source, DW_TableName)'
    +'
     select ETO_SurveyResponseID, SurveyResponseID, Atbl.SiteID, ''' +@p_datasource +''''  +',''' +@DW_TableName +''''
    +'
     from ' +@Agency_Full_TableName +' Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' where isnull(Atbl.ETO_SurveyResponseID,0) != 0'
    +' and not exists (select dwxref.SurveyResponseID'
                      +' from dbo.Non_ETO_SurveyResponse_Xref dwxref'
                     +' where dwxref.source = ''' +@p_datasource +''''
                     +' and dwxref.Non_ETO_ID = Atbl.SurveyResponseID'
                     +' and dwxref.DW_tableName = ''' +@DW_TableName +''''
                     +' and dwxref.Non_ETO_Site_ID = atbl.SiteID)'
    +' and exists (select SurveyResponseID from dbo.' +@DW_TableName 
                     +' dtbl where dtbl.SurveyResponseID = ETO_SurveyResponseID'
                     +' and dtbl.siteid = Atbl.SiteID)'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)


-- update the DW Survey's datasource for any new re-mapping of non-eto-exref records to an existing ETO record:
print ' '
print 'updating dw Survey table datasource for remapped surveys'
set @SQL = 'set nocount off '+
     ' update dbo.' +@DW_TableName 
       +' set DataSource = dwxref.source'
      +' from dbo.Non_ETO_SurveyResponse_Xref dwxref'
      +' inner join ' +@DW_TableName +' dwtbl on dwxref.SurveyResponseID = dwtbl.SurveyResponseID'
            +' and dwxref.Source != isnull(dwtbl.DataSource,''ETO'')'
      +' where dwxref.source = ''' +@p_datasource +''''

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    exec (@SQL)



-- update the DW SurveyResponses table datasource for any new re-mapping of non-eto-exref records to an existing ETO record:
print ' '
print 'updating dw.surveyresponses datasource for remapped surveys'
set @SQL = 'set nocount off '+
     ' update dbo.SurveyResponses'
       +' set DataSource = dwxref.source'
      +' from dbo.Non_ETO_SurveyResponse_Xref dwxref'
      +' inner join dbo.SurveyResponses dwtbl on dwxref.SurveyResponseID = dwtbl.SurveyResponseID'
            +' and dwxref.Source != isnull(dwtbl.DataSource,''ETO'')'
      +' where dwxref.source = ''' +@p_datasource +''''

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    exec (@SQL)


----------------------------------------------------------------------------------------

-- For AgencyDB records that DO NOT originate from ETO:
-- create non_ETO xref entries for new SurveyResponse records from AgencyDB:
print ' '
print 'Creating xref for surveys not yet existing in DW'
set @SQL = 'set nocount off '+
    ' set identity_insert dbo.non_eto_SurveyResponse_xref off '
    +' insert into dbo.Non_ETO_SurveyResponse_Xref'
    +' (Non_ETO_ID, Non_ETO_Site_ID, Source, DW_TableName)'
    +'
     select SurveyResponseID, Atbl.SiteID, ''' +@p_datasource +''''  +',''' +@DW_TableName +''''
    +'
     from ' +@Agency_Full_TableName +' Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' where not exists (select dwxref.SurveyResponseID'
    +' from dbo.Non_ETO_SurveyResponse_Xref dwxref'
    +' where dwxref.source = ''' +@p_datasource +''''
    +'   and dwxref.Non_ETO_ID = Atbl.SurveyResponseID'
    +'   and dwxref.DW_tableName = ''' +@DW_TableName +''''
    +'   and dwxref.Non_ETO_Site_ID = atbl.SiteID)'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)


-- Assign new NON-ETO xref ID to new records from AgencyDB:
print ' '
print 'Updating AgencyDB source table with DW xref indexes'
set @SQL = 'set nocount off '+
    'update ' +@Agency_Full_TableName
    +' Set [DW_SurveyResponseID] = dwxref.[SurveyResponseID]'
    +'
     from ' +@Agency_Full_TableName +' Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' inner join dbo.Non_ETO_SurveyResponse_Xref dwxref'
       +' on dwxref.Non_ETO_ID = Atbl.SurveyResponseID and dwxref.source = ''' +@p_datasource +''''
      +' and dwxref.DW_tableName = ''' +@DW_TableName +''''
    +' Where dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)



set @SQL1 = 'set nocount off'
    +' insert into dbo.TEAM_MEETINGS_CONF_SURVEY'
    +' ([SurveyResponseID],[DataSource],[ElementsProcessed]'
    +' ,[SurveyID]'
    +' ,[SurveyDate]'
    +' ,[AuditDate]'
    +' ,[CL_EN_GEN_ID]'
    +' ,[SiteID]'
    +' ,[ProgramID]'
    --+' ,[IA_StaffID]'
    +' ,[ClientID]'
    --+' ,[RespondentID]'
    --+' ,[Entity_ID_Mapped]'
    +' ,[AGENCY_MEETING_0_TYPE]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE1]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE10]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE2]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE3]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE4]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE5]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE6]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE7]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE8]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE9]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF1]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF10]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF2]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF3]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF4]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF5]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF6]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF7]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF8]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF9]'
    +' ,[AGENCY_MEETING_1_LENGTH]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF1]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF10]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF11]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF12]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF13]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF14]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF15]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF16]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF17]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF18]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF19]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF2]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF20]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF3]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF4]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF5]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF6]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF7]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF8]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF9]'
    +' ,[Master_SurveyID]'
    +' ,[DW_AuditDate])'
    +'
     SELECT  DW_SurveyResponseID as SurveyResponseID, ''' +@p_datasource +''''
    +' ,1'
    +' ,Atbl.[SurveyID]'
    +' ,Atbl.[SurveyDate]'
    +' ,Atbl.[AuditDate]'
    +' ,Agencies.Entity_ID'    -- CL_EN_GEN_ID ascertained from lookup via siteid
    +' ,Atbl.[SiteID]'
    +' ,Atbl.[ProgramID]'
    --+' ,Atbl.[IA_StaffID]'
    +' ,cxref2.Client_ID'
    --+' ,Atbl.[RespondentID]'
    --+' ,Atbl.[Entity_ID_Mapped]'
    +' ,Atbl.[AGENCY_MEETING_0_TYPE]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE1]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE10]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE2]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE3]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE4]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE5]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE6]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE7]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE8]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE9]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF1]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF10]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF2]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF3]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF4]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF5]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF6]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF7]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF8]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF9]'
    +' ,Atbl.[AGENCY_MEETING_1_LENGTH]'

set @SQL2 = '
     ,dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF1],Atbl.SiteID,NULL) as ATTENDEES_STAFF1'
    +' ,dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF10],Atbl.SiteID,NULL) as ATTENDEES_STAFF10'
    +' ,dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF11],Atbl.SiteID,NULL) as ATTENDEES_STAFF11'
    +' ,dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF12],Atbl.SiteID,NULL) as ATTENDEES_STAFF12'
    +' ,dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF13],Atbl.SiteID,NULL) as ATTENDEES_STAFF13'
    +' ,dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF14],Atbl.SiteID,NULL) as ATTENDEES_STAFF14'
    +' ,dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF15],Atbl.SiteID,NULL) as ATTENDEES_STAFF15'
    +' ,dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF16],Atbl.SiteID,NULL) as ATTENDEES_STAFF16'
    +' ,dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF17],Atbl.SiteID,NULL) as ATTENDEES_STAFF17'
    +' ,dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF18],Atbl.SiteID,NULL) as ATTENDEES_STAFF18'
    +' ,dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF19],Atbl.SiteID,NULL) as ATTENDEES_STAFF19'
    +' ,dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF2],Atbl.SiteID,NULL) as ATTENDEES_STAFF2'
    +' ,dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF20],Atbl.SiteID,NULL) as ATTENDEES_STAFF20'
    +' ,dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF3],Atbl.SiteID,NULL) as ATTENDEES_STAFF3'
    +' ,dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF4],Atbl.SiteID,NULL) as ATTENDEES_STAFF4'
    +' ,dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF5],Atbl.SiteID,NULL) as ATTENDEES_STAFF5'
    +' ,dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF6],Atbl.SiteID,NULL) as ATTENDEES_STAFF6'
    +' ,dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF7],Atbl.SiteID,NULL) as ATTENDEES_STAFF7'
    +' ,dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF8],Atbl.SiteID,NULL) as ATTENDEES_STAFF8'
    +' ,dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF9],Atbl.SiteID,NULL) as ATTENDEES_STAFF9'
    +', ms.SourceSurveyID'

set @SQL3 = '
    ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.TEAM_MEETINGS_CONF_SURVEY Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' left join dbo.Non_ETO_Client_Xref cxref2 on cxref2.Source =  ''' +@p_datasource +''''
    +'   and cxref2.Non_ETO_ID = Atbl.ClientID'
    +'   and cxref2.Non_ETO_Site_ID = Atbl.SiteID' 
    +'  left join dbo.Agencies on Atbl.SiteID = Agencies.Site_Id'
    +' left join dbo.Mstr_Surveys ms on Atbl.SurveyID = ms.SurveyID'
    +' where Atbl.DW_SurveyResponseID is not null'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'
    +' and not exists (select dwsurvey.SurveyResponseID'
    +' from dbo.TEAM_MEETINGS_CONF_SURVEY dwsurvey'
    +' where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and dwsurvey.SurveyResponseID = Atbl.DW_SurveyResponseID)'
     

    print @SQL1 
    print @SQL2
    print @SQL3
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) 
         +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
         +', SQL3 Length = ' +CAST(LEN(@SQL3) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL1+@SQL2+@SQL3)


----------------------------------------------------------------------------------------
print 'Cont: Update changes'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off'
    +' update dbo.TEAM_MEETINGS_CONF_SURVEY'
    +' Set [SurveyID] = Atbl.[SurveyID]'    
    +', [SurveyDate] = Atbl.[SurveyDate]'
    +', [AuditDate] = Atbl.[AuditDate]'
    +', [CL_EN_GEN_ID] = Agencies.Entity_ID'
    +', [SiteID] = Atbl.[SiteID]'
    +', [ProgramID] = Atbl.[ProgramID]'
    --+', [IA_StaffID] = Atbl.[IA_StaffID]'
    +', [ClientID] = cxref2.Client_ID'
    --+' ,[RespondentID] = Atbl.[RespondentID]'
    --+' ,[Entity_ID_Mapped]Atbl.[Entity_ID_Mapped]'
    +' ,[AGENCY_MEETING_0_TYPE] = Atbl.[AGENCY_MEETING_0_TYPE]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE1] = Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE1]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE10] = Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE10]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE2] = Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE2]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE3] = Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE3]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE4] = Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE4]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE5] = Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE5]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE6] = Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE6]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE7] = Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE7]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE8] = Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE8]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE9] = Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE9]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF1] = Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF1]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF10] = Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF10]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF2] = Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF2]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF3] = Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF3]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF4] = Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF4]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF5] = Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF5]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF6] = Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF6]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF7] = Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF7]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF8] = Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF8]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF9] = Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF9]'
    +' ,[AGENCY_MEETING_1_LENGTH] = Atbl.[AGENCY_MEETING_1_LENGTH]'
set @SQL2 = '
     ,[AGENCY_MEETING_1_ATTENDEES_STAFF1] = dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF1],Atbl.SiteID,NULL)'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF10] = dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF10],Atbl.SiteID,NULL)'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF11] = dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF11],Atbl.SiteID,NULL)'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF12] = dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF12],Atbl.SiteID,NULL)'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF13] = dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF13],Atbl.SiteID,NULL)'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF14] = dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF14],Atbl.SiteID,NULL)'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF15] = dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF15],Atbl.SiteID,NULL)'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF16] = dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF16],Atbl.SiteID,NULL)'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF17] = dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF17],Atbl.SiteID,NULL)'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF18] = dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF18],Atbl.SiteID,NULL)'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF19] = dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF19],Atbl.SiteID,NULL)'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF2] = dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF2],Atbl.SiteID,NULL)'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF20] = dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF20],Atbl.SiteID,NULL)'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF3] = dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF3],Atbl.SiteID,NULL)'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF4] = dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF4],Atbl.SiteID,NULL)'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF5] = dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF5],Atbl.SiteID,NULL)'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF6] = dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF6],Atbl.SiteID,NULL)'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF7] = dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF7],Atbl.SiteID,NULL)'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF8] = dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF8],Atbl.SiteID,NULL)'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF9] = dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''' +@p_datasource +''''+',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF9],Atbl.SiteID,NULL)'
    +', [Master_SurveyID] = ms.SourceSurveyID'

set @SQL3 = ', [DW_AuditDate] = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from dbo.TEAM_MEETINGS_CONF_SURVEY dwsurvey'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.TEAM_MEETINGS_CONF_SURVEY Atbl'
    +' on dwsurvey.SurveyResponseID = Atbl.DW_SurveyResponseID'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' left join dbo.Non_ETO_Client_Xref cxref2 on cxref2.Source =  ''' +@p_datasource +''''
    +'   and cxref2.Non_ETO_ID = Atbl.ClientID' 
    +'   and cxref2.Non_ETO_Site_ID = Atbl.SiteID'
    +'  left join dbo.Agencies on Atbl.SiteID = Agencies.Site_Id'
    +' left join dbo.Mstr_Surveys ms on Atbl.SurveyID = ms.SurveyID'
    +'
     where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'
    +' and isnull(dwsurvey.AuditDate,convert(datetime,''19700101'',112)) <'
    +' isnull(Atbl.AuditDate,convert(datetime,''19700101'',112))'

    print @SQL1 
    print @SQL2
    print @SQL3
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) 
         +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
         +', SQL3 Length = ' +CAST(LEN(@SQL3) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL1+@SQL2+@SQL3)



----------------------------------------------------------------------------------------
print 'Cont: Delete Contacts that no longer exist in AgencyDB'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Deleting ETO Deletions'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

if upper(isnull(@p_no_delete_opt,'n')) != 'Y'
BEGIN

set @SQL ='set nocount off '+
   ' delete dbo.' +@DW_TableName
    +' from dbo.' +@DW_TableName +' dwsurvey'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = dwsurvey.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' where dwsurvey.DataSource = ''' +@p_datasource +''''
      +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', dwsurvey.SiteID) is null'
      +' and not exists (select Atbl.DW_SurveyResponseID'
                        +' from ' +@Agency_Full_TableName +' Atbl'
                       +' where DW_SurveyResponseID = dwsurvey.SurveyResponseID)'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)


-- housecleaning of xref table
print 'Cont: Delete unreferrenced xref records'
set @SQL ='set nocount off '+
   ' delete dbo.Non_ETO_SurveyResponse_Xref'
    +' from dbo.Non_ETO_SurveyResponse_Xref dwxref'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = dwxref.Non_ETO_Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''

    +' where dwxref.source = ''' +@p_datasource +''''
      +' and dwxref.DW_tableName = ''' +@DW_TableName +''''
      +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', dwxref.Non_ETO_Site_ID) is null'

    +' and not exists (select Atbl.SurveyResponseID'
                      +' from ' +@Agency_Full_TableName +' Atbl'
                     +' where SurveyResponseID = dwxref.Non_ETO_ID)'

    +' and not exists (select dwsurvey.SurveyResponseID'
                      +' from ' +@DW_TableName +' dwsurvey'
                     +' where dwsurvey.SurveyResponseID = dwxref.SurveyResponseID)'

    print @SQL
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

print 'End of Process: SP_AGENCYDB_TEAM_MEETINGS_CONF_SURVEY'
GO
