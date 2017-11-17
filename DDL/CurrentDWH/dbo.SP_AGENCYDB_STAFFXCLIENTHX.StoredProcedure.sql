USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_STAFFXCLIENTHX]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_STAFFXCLIENTHX
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_STAFFXCLIENTHX]
 (@p_datasource      nvarchar(10) = null)
AS
--
-- This script controls integration of AgencyDB Surveys to the Data Warehouse 
-- STAFFXCLIENTHX table.
--
-- Will exclude from DW if Site Does not exist in dbo.agencies
--
-- Table effected - dbo.STAFFXCLIENTHX
--
-- Insert: select and insert when record is found to be missing in the DW.
-- Update: select and update when record exists in DW and has been changed but has been changed flagged by Audit_Date.
--
-- IDs translated via DW/AgencyDB Non_ETO_Xref mapping:
--    ClientID     (lookup, using DW.Client_ID)
--
-- History:
--   20130325 - New Procedure.
--   20140114 - Added new translation for StaffID coming from the AgencyDB via dbo.Non_ETO_Staff_Xref
--   20140128 - Added StaffXClient table to the integration.
--   20140326 - Added Site_ID qualifier by datasource, to allow multiple datasources to share the same AgencyDB.
--              Added database trigger to inhibit the processing of this procedure (defaulting as always process).
--                This trigger is used to bypass the process w/o having to modify the SSIS integration packages.
--              Added site_id to non-ETO_Xref.  This will allow the site_id to represent uniqueness between companies,
--                thus allowing the same source id to be utilized by different Agencydb sites (company).
--   20140910 - Amended to include Entity_ID.
--   20141002 - Added delete to StaffXClient to remove End-Dated records.
--   20160628 - Corrected qualifier on auditsxref for matching source.
--   20160706 - Added additional conditional logic to match siteid when looking up xrefs to entities and clients,
--              to accommodate multiple sites within the same AgencyDB, using same numbering scheme between sites.


DECLARE @count        smallint
DECLARE @stop_flag  nvarchar(2)
DECLARE @Process      nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)

set @process = 'SP_AGENCYDB_STAFFXCLIENTHX'
set @DW_Tablename = 'STAFFXCLIENTHX'
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)

print 'Processing SP_AGENCYDB_STAFFXCLIENTHX: Datasource = ' +isnull(@p_datasource,'NULL')
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

-- create non_ETO xref entries for new StaffXClientHX records from AgencyDB:
set @SQL = 'set nocount off '+
    ' insert into Non_ETO_StaffXClientHX_Xref'
    +' (Non_ETO_ID, Non_ETO_Site_ID, Source)'
    +'
     select StaffXClientID, Astaff.Site_ID, ''' +@p_datasource +''''
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.STAFFXCLIENTHX Atbl'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.IA_Staff Astaff'
          +' on Atbl.StaffID = Astaff.Entity_ID'

    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd'
          +' on asbd.Site_ID = Astaff.Site_ID'
          +' and asbd.DataSource =  ''' +@p_datasource +''''

    +' where not exists (select dwxref.StaffXClientID'
                        +' from dbo.Non_ETO_StaffXClientHX_Xref dwxref'
                       +' where dwxref.source = ''' +@p_datasource +''''
                         +' and dwxref.Non_ETO_ID = Atbl.StaffXClientID'
                         +' and dwxref.Non_ETO_Site_ID = Astaff.Site_ID)'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Astaff.Site_ID) is null'

    print @SQL
    EXEC (@SQL)


-- Update the AgencyDB records with the DW Non_ETO_Xref index:
print 'Updating AgencyDB source table with DW xref indexes'
set @SQL = 'set nocount off '+
    'update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.STAFFXCLIENTHX'
    +' Set [DW_StaffXClientID] = dwxref.[StaffXClientID]'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.STAFFXCLIENTHX Atbl'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.IA_Staff Astaff'
          +' on Atbl.StaffID = Astaff.Entity_ID'

    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd'
          +' on asbd.Site_ID = Astaff.Site_ID'
          +' and asbd.DataSource =  ''' +@p_datasource +''''

    +' inner join Non_ETO_StaffXClientHX_Xref dwxref'
          +' on dwxref.Non_ETO_ID = Atbl.StaffXClientID and dwxref.source = ''' +@p_datasource +''''

    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Astaff.Site_ID) is null'

    print @SQL
    EXEC (@SQL)


----------------------------------------------------------------------------------------
-- process StafXClient records:

-- insert new DW record:
set @SQL = 'set nocount off'
    +' insert into dbo.STAFFXCLIENTHX'
    +' ([StaffxClientID]'
    +' ,Datasource'
    +' ,[StaffID]'
    +' ,[CLID]'
    +' ,[ProgramID]'
    +' ,[StartDate]'
    +' ,[EndDate]'
    +' ,[AuditStaffID]'
    +' ,[AuditDate]'
    +' ,[Entity_ID])'
    +'
     SELECT  DW_StaffXClientID as StaffXClientID, ''' +@p_datasource +''''
    +' ,sxref.[StaffID]'
    +' ,cxref1.Client_ID'
    +' ,Atbl.[ProgramID]'
    +' ,Atbl.[StartDate]'
    +' ,Atbl.[EndDate]'
    +' ,auditsxref.[StaffID]'
    +' ,Atbl.[AuditDate]'
    +' ,(select max(sxe.EntityID) from dbo.StaffXEntities sxe where sxe.StaffID = sxref.StaffID)'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.STAFFXCLIENTHX Atbl'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.IA_Staff Astaff'
          +' on Atbl.StaffID = Astaff.Entity_ID'

    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd'
          +' on asbd.Site_ID = Astaff.Site_ID'
          +' and asbd.DataSource =  ''' +@p_datasource +''''

    +' inner join dbo.Non_ETO_Client_Xref cxref1'
          +' on cxref1.Source =  ''' +@p_datasource +''''
          +' and cxref1.Non_ETO_ID = Atbl.CLID'  
          +' and cxref1.Non_ETO_Site_ID = Astaff.Site_ID' 

    +' inner join dbo.Non_ETO_Staff_Xref sxref'
          +' on sxref.Source =  ''' +@p_datasource +''''
          +' and sxref.Non_ETO_ID = Atbl.StaffID'  
          +' and sxref.Non_ETO_Site_ID = Astaff.Site_ID' 

    +' inner join dbo.Non_ETO_Staff_Xref auditsxref'
          +'  on auditsxref.Source =  ''' +@p_datasource +''''
          +' and auditsxref.Non_ETO_ID = Atbl.AuditStaffID'
          +' and auditsxref.Non_ETO_Site_ID = Astaff.Site_ID'  

    +' where Atbl.DW_StaffXClientID is not null'
      +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Astaff.Site_ID) is null'
      +' and not exists (select dwtbl.StaffXClientID'
                        +' from dbo.STAFFXCLIENTHX dwtbl'
                       +' where dwtbl.StaffXClientID = Atbl.DW_StaffXClientID)'
     

    print @SQL
    print 'Length = ' +CAST(LEN(@SQL) as varchar)
    EXEC (@SQL)



print 'Cont: Update changes'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------


set @SQL = 'set nocount off'
    +' update dbo.STAFFXCLIENTHX'
    +' Set [CLID] = cxref1.Client_ID'
    +', [StaffID] = sxref.[StaffID]'
    +', [ProgramID] = Atbl.[ProgramID]'
    +', [StartDate] = Atbl.[StartDate]'
    +', [EndDate] = Atbl.[EndDate]'
    +', [AuditStaffID] = auditsxref.[StaffID]'
    +', [AuditDate] = Atbl.[AuditDate]'
    +', [Entity_ID] = (select max(sxe.EntityID) from dbo.StaffXEntities sxe where sxe.StaffID = sxref.StaffID)'
    +'
     from dbo.STAFFXCLIENTHX dwtbl'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.STAFFXCLIENTHX Atbl'

    +'   on dwtbl.StaffXClientID = Atbl.DW_StaffXClientID'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.IA_Staff Astaff on Atbl.StaffID = Astaff.Entity_ID'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Astaff.Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''

    +' inner join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source =  ''' +@p_datasource +''''
    +'   and cxref1.Non_ETO_ID = Atbl.CLID' 
    +'   and cxref1.Non_ETO_Site_ID = Astaff.Site_ID' 

    +' inner join dbo.Non_ETO_Staff_Xref sxref on sxref.Source =  ''' +@p_datasource +''''
    +'   and sxref.Non_ETO_ID = Atbl.StaffID' 
    +'   and sxref.Non_ETO_Site_ID = Astaff.Site_ID' 

    +' inner join dbo.Non_ETO_Staff_Xref auditsxref on sxref.Source =  ''' +@p_datasource +''''
    +'   and auditsxref.Non_ETO_ID = Atbl.AuditStaffID'
    +'   and auditsxref.Non_ETO_Site_ID = Astaff.Site_ID'  
    +'
     where isnull(dwtbl.AuditDate,convert(datetime,''19700101'',112)) <'
        +' isnull(Atbl.AuditDate,convert(datetime,''19700101'',112))'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Astaff.Site_ID) is null'

    print @SQL
    EXEC (@SQL)



----------------------------------------------------------------------------------------
print 'Cont: Delete records that no longer exist in AgencyDB'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Deleting non existing StaffXClientHX'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL ='set nocount off '+
    ' delete dbo.STAFFXCLIENTHX'
    +' from dbo.STAFFXCLIENTHX dwtbl'

    +' inner join Non_ETO_StaffXClientHX_Xref dwxref'
    +'   on dwxref.StaffXClientID = dwtbl.StaffXClientID and dwxref.source = ''' +@p_datasource +''''

    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = dwxref.Non_ETO_Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''

    +' where dwtbl.DataSource = ''' +@p_datasource +''''
      +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', dwxref.Non_ETO_Site_ID) is null'
      +' and not exists (select Atbl.StaffXClientID'
                        +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.STAFFXCLIENTHX Atbl'
                       +' where atbl.StaffXClientID = dwxref.Non_ETO_ID)'

    print @SQL
    EXEC (@SQL)



----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

print ' '
print 'Cont: Processing for StaffXClient Table (inserts)'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing StaffxClient table'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- insert new DW record:
set @SQL = 'set nocount off'
    +' insert into dbo.STAFFXCLIENT'
    +' ([StaffxClientID]'
    +' ,Datasource'
    +' ,[StaffID]'
    +' ,[CLID]'
    +' ,[ProgramID]'
    +' ,[AuditStaffID]'
    +' ,[AuditDate]'
    +' ,[Entity_ID])'
    +'
     SELECT  DW_StaffXClientID as StaffXClientID, ''' +@p_datasource +''''
    +' ,sxref.[StaffID]'
    +' ,cxref1.Client_ID'
    +' ,Atbl.[ProgramID]'
    +' ,auditsxref.[StaffID]'
    +' ,atbl.[AuditDate]'
    +' ,(select max(sxe.EntityID) from dbo.StaffXEntities sxe where sxe.StaffID = sxref.StaffID)'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.STAFFXCLIENTHX Atbl'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.IA_Staff Astaff on Atbl.StaffID = Astaff.Entity_ID'

    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Astaff.Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''

    +' inner join dbo.Non_ETO_StaffXClientHX_Xref xref on xref.source = ''' +@p_datasource +''''
    +'  and atbl.StaffXClientID = xref.Non_ETO_ID'

    +' inner join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source =  ''' +@p_datasource +''''
    +'   and cxref1.Non_ETO_ID = Atbl.CLID'  
    +'   and cxref1.Non_ETO_Site_ID = Astaff.Site_ID' 

    +' inner join dbo.Non_ETO_Staff_Xref sxref on sxref.Source =  ''' +@p_datasource +''''
    +'   and sxref.Non_ETO_ID = Atbl.StaffID' 
    +'   and sxref.Non_ETO_Site_ID = Astaff.Site_ID' 

    +' inner join dbo.Non_ETO_Staff_Xref auditsxref on sxref.Source =  ''' +@p_datasource +''''
    +'   and auditsxref.Non_ETO_ID = Atbl.AuditStaffID'
    +'   and auditsxref.Non_ETO_Site_ID = Astaff.Site_ID' 
 
    +' where not exists (select dwtbl.StaffXClientID'
                        +' from dbo.STAFFXCLIENT dwtbl'
                       +' where dwtbl.StaffXClientID = xref.StaffXClientID)'
    +' and Atbl.[EndDate] is null'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Astaff.Site_ID) is null'
     

    print @SQL
    print 'Length = ' +CAST(LEN(@SQL) as varchar)
    EXEC (@SQL)


print ' '
print 'Cont: Processing for StaffXClient Table (Updates)'

set @SQL = 'set nocount off'
    +' update dbo.STAFFXCLIENT'
    +' Set [CLID] = cxref1.Client_ID'
    +', [StaffID] = sxref.[StaffID]'
    +', [ProgramID] = Atbl.[ProgramID]'
    +', [AuditStaffID] = auditsxref.[StaffID]'
    +', [AuditDate] = Atbl.[AuditDate]'
    +', [Entity_ID] = (select max(sxe.EntityID) from dbo.StaffXEntities sxe where sxe.StaffID = sxref.StaffID)'
    +'
     from dbo.STAFFXCLIENT dwtbl'
    +' inner join dbo.Non_ETO_StaffXClientHX_Xref xref on xref.source = ''' +@p_datasource +''''
    +'  and dwtbl.StaffXClientID = xref.StaffXClientID'

    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.STAFFXCLIENTHX Atbl'
    +'   on xref.non_ETO_ID = Atbl.StaffXClientID'

    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.IA_Staff Astaff on Atbl.StaffID = Astaff.Entity_ID'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Astaff.Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''

    +' inner join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source =  ''' +@p_datasource +''''
    +'   and cxref1.Non_ETO_ID = Atbl.CLID' 
    +'   and cxref1.Non_ETO_Site_ID = Astaff.Site_ID' 

    +' inner join dbo.Non_ETO_Staff_Xref sxref on sxref.Source =  ''' +@p_datasource +''''
    +'   and sxref.Non_ETO_ID = Atbl.StaffID' 
    +'   and sxref.Non_ETO_Site_ID = Astaff.Site_ID' 

    +' inner join dbo.Non_ETO_Staff_Xref auditsxref on sxref.Source =  ''' +@p_datasource +''''
    +'   and auditsxref.Non_ETO_ID = Atbl.AuditStaffID'
    +'   and auditsxref.Non_ETO_Site_ID = Astaff.Site_ID' 
    +'
     where dwtbl.Datasource = ''' +@p_datasource +''''
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Astaff.Site_ID) is null'
    +' and isnull(dwtbl.AuditDate,convert(datetime,''19700101'',112)) <'
        +' isnull(Atbl.AuditDate,convert(datetime,''19700101'',112))'
    +' and Atbl.EndDate is null'

    print @SQL
    EXEC (@SQL)



print ' '
print 'Cont: Processing for StaffXClient Table (Delete End_Dated Records)'


set @SQL ='set nocount off '+
    ' delete dbo.STAFFXCLIENT'
    +' from dbo.STAFFXCLIENT dwtbl'

    +' inner join Non_ETO_StaffXClientHX_Xref dwxref'
    +'   on dwxref.StaffXClientID = dwtbl.StaffXClientID and dwxref.source = ''' +@p_datasource +''''

    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.IA_Staff Astaff on Atbl.StaffID = Astaff.Entity_ID'

    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = dwxref.Non_ETO_Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''

    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.STAFFXCLIENTHX Atbl'
       +' on dwxref.Non_ETO_ID = atbl.StaffXClientID'
    +'   and dwxref.Non_ETO_Site_ID = Astaff.Site_ID' 

    +' where dwtbl.DataSource = ''' +@p_datasource +''''
      +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', dwxref.Non_ETO_Site_ID) is null'
      +' and atbl.enddate is not null'

    print @SQL
    --EXEC (@SQL)


print ' '
print 'Cont: Processing for StaffXClient Table (Delete removed records from AgencyDB)'


set @SQL ='set nocount off '+
    ' delete dbo.STAFFXCLIENT'
    +' from dbo.STAFFXCLIENT dwtbl'

    +' inner join Non_ETO_StaffXClientHX_Xref dwxref'
    +'   on dwxref.StaffXClientID = dwtbl.StaffXClientID and dwxref.source = ''' +@p_datasource +''''

    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = dwxref.Non_ETO_Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''

    +' where dwtbl.DataSource = ''' +@p_datasource +''''
      +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', dwxref.Non_ETO_Site_ID) is null'
      +' and not exists (select Atbl.StaffXClientID'
                        +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.STAFFXCLIENTHX Atbl'
                       +' where atbl.StaffXClientID = dwxref.Non_ETO_ID'
                       +'   and Astaff.Site_ID = dwxref.Non_ETO_Site_ID)'

    print @SQL
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

print 'End of Process: SP_AGENCYDB_STAFFXCLIENTHX'
GO
