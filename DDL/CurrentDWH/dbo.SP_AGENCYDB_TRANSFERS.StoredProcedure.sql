USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_TRANSFERS]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_TRANSFERS
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_TRANSFERS]
 (@p_datasource      nvarchar(10) = null
 ,@p_no_delete_opt   nvarchar(2)  = null
 ,@p_no_exec_flag    nvarchar(10) = 'N')
AS
--
-- This script controls integration of AgencyDB to the Data Warehouse TRANSFERS table.
--
-- Will exclude from DW if Site Does not exist in dbo.agencies
--
-- Table effected - dbo.Transfers
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
--   20151207 - New Procedure.

DECLARE @count          smallint
DECLARE @stop_flag      nvarchar(2)
DECLARE @Process        nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)
DECLARE @Agency_TableName   nvarchar(50)
DECLARE @Agency_Full_TableName   nvarchar(100)

set @process          = 'SP_AGENCYDB_TRANSFERS'
set @DW_Tablename     = 'TRANSFERS'
set @Agency_Tablename = 'TRANSFERS'
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)

print 'Processing SP_AGENCYDB_TRANSFERS: Datasource = ' +isnull(@p_datasource,'NULL')
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
-- clearout secondary replicated ETO_TransferID from the AgencyDB Survey table:
-- If the ETO_SureveyResponseID is not cleared for the secondary records,
-- then the next process which creates the non_eto_Transfers_xref will fail
-- due to the unique constraint on TransferID (coming from the mapped ETO_TransferID)

set @SQL = ''
set @SQL = 'set nocount off 
 Declare DupsCursor cursor for
 select distinct(dups.ETO_TransferID) 
 from  ' +@Agency_Full_TableName +' dups
  where (select COUNT(*) from ' +@Agency_Full_TableName +' dups2
  where dups2.ETO_TransferID = dups.ETO_TransferID) > 1
 Declare @Dup_ETO_TransferID int
 Open DupsCursor
 Fetch next from DupsCursor into @Dup_ETO_TransferID
 While @@FETCH_STATUS = 0
 Begin 
 update ' +@Agency_Full_TableName +'
 set ETO_TransferID = null
 where TransferID in 
 (select TransferID
  from (
 select ROW_NUMBER() OVER (ORDER BY atbl.ETO_TransferID) AS Row
      ,atbl.TransferID, atbl.AuditDate, atbl.ETO_TransferID
 from ' +@Agency_Full_TableName +' atbl
 where atbl.ETO_TransferID = @Dup_ETO_TransferID) duprecs
 where ROW > 1)
 Fetch next from DupsCursor into @Dup_ETO_TransferID
 End				
 CLOSE DupsCursor
 DEALLOCATE DupsCursor'


    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
       EXEC (@SQL)

----------------------------------------------------------------------------------------

-- update the DW datasource for AgencyDB mapping to an existing ETO record:
print ' '
print 'updating dw table datasource for AgencyDB/ETO mapped records'
set @SQL = 'set nocount off 
   update dbo.' +@DW_TableName 
       +' set DataSource = ''' +@p_datasource +''''
       +' ,Datasource_ID = Atbl.TransferID
     from ' +@Agency_Full_TableName +' Atbl'
  +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Clients AClients on Atbl.CLID = AClients.Client_id'
  +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = AClients.Site_ID'
  +'   and asbd.DataSource =  ''' +@p_datasource +''''
  +' inner join ' +@DW_TableName +' dwtbl on atbl.ETO_TransferID = dwtbl.TransferID'
  +' where atbl.ETO_TransferID is not null'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', AClients.Site_ID) is null'
    +' and isnull(dwtbl.DataSource,''ETO'') = ''ETO'''
    +' and not exists (select dwtbl2.TransferID'
                      +' from dbo.TRANSFERS dwtbl2'
                     +' where dwtbl2.Datasource = ''' +@p_datasource +''''
                       +' and dwtbl2.Datasource_ID = Atbl.TransferID)'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
       exec (@SQL)

----------------------------------------------------------------------------------------


print ' '
set @SQL = 'set nocount off'
    +' insert into dbo.TRANSFERS'
    +' ([Datasource]'
    +' ,[Datasource_ID]'
    +' ,[CLReferralID]'
    +' ,[CLID]'
    +' ,[ProgramID_From]'
    +' ,[ReferredTo]'
    +' ,[EntityID]'
    +' ,[TargetSiteID]'
    +' ,[TargetProgramID]'
    +' ,[ReferralDate]'
    +' ,[DateReferralClosed]'
    +' ,[ReasonForDismissal]'
    +' ,[ReasonForReferral]'
    +' ,[CLReferralHxID]'
    +' ,[ReferralStatus]'
    +' ,[Notes]'
    +' ,[TimeSpentonReferral]'
    +' ,[AuditStaffID]'
    +' ,[AuditDate]'
    +')
     SELECT  ''' +@p_datasource +''''
    +' ,Atbl.[TransferID]'
    +' ,Atbl.[CLReferralID]'
    +' ,cxref1.Client_ID'
    +' ,Atbl.[ProgramID_From]'
    +' ,Atbl.[ReferredTo]'
    +' ,exref1.Entity_ID'
    +' ,Atbl.[TargetSiteID]'
    +' ,Atbl.[TargetProgramID]'
    +' ,Atbl.[ReferralDate]'
    +' ,Atbl.[DateReferralClosed]'
    +' ,Atbl.[ReasonForDismissal]'
    +' ,Atbl.[ReasonForReferral]'
    +' ,Atbl.[CLReferralHxID]'
    +' ,Atbl.[ReferralStatus]'
    +' ,Atbl.[Notes]'
    +' ,Atbl.[TimeSpentonReferral]'
    +' ,Atbl.[AuditStaffID]'
    +' ,Atbl.[AuditDate]'
    +'
     from ' +@Agency_Full_TableName +' Atbl'
  +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Clients AClients on Atbl.CLID = AClients.Client_id'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = AClients.Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' left join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source =  ''' +@p_datasource +''''
    +'   and cxref1.Non_ETO_ID = Atbl.CLID' 
    +' left join dbo.Non_ETO_Entity_Xref exref1 on exref1.Source =  ''' +@p_datasource +''''
    +'   and exref1.Non_ETO_ID = Atbl.EntityID' 
    +' where dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', AClients.Site_ID) is null'
      +' and not exists (select dwtbl.TransferID'
                        +' from dbo.TRANSFERS dwtbl'
                       +' where dwtbl.Datasource = ''' +@p_datasource +''''
                         +' and dwtbl.Datasource_ID = Atbl.TransferID)'
     

    print @SQL
    print 'Length = ' +CAST(LEN(@SQL) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
       EXEC (@SQL)

----------------------------------------------------------------------------------------
print ' '
print 'Cont: Update changes'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL = 'set nocount off'
    +' update dbo.TRANSFERS'
    +' Set [CLReferralID] = Atbl.[CLReferralID]'
    +' ,CLID = cxref1.Client_ID'
    +' ,ProgramID_From = Atbl.[ProgramID_From]'
    +' ,[ReferredTo] = Atbl.[ReferredTo]'
    +' ,[EntityID] = exref1.Entity_ID'
    +' ,[TargetSiteID] = Atbl.[TargetSiteID]'
    +' ,[TargetProgramID] = Atbl.[TargetProgramID]'
    +' ,[ReferralDate] = Atbl.[ReferralDate]'
    +' ,[DateReferralClosed] = Atbl.[DateReferralClosed]'
    +' ,[ReasonForDismissal] = Atbl.[ReasonForDismissal]'
    +' ,[ReasonForReferral] = Atbl.[ReasonForReferral]'
    +' ,[CLReferralHxID] = Atbl.[CLReferralHxID]'
    +' ,[ReferralStatus] = Atbl.[ReferralStatus]'
    +' ,[Notes] = Atbl.[Notes]'
    +' ,[TimeSpentonReferral] = Atbl.[TimeSpentonReferral]'
    +' ,[AuditStaffID] = Atbl.[AuditStaffID]'
    +' ,[AuditDate] = Atbl.[AuditDate]'
    +'
     from dbo.TRANSFERS dwtbl'
    +' inner join ' +@Agency_Full_TableName +' Atbl'
    +'   on dwtbl.Datasource_ID = Atbl.TransferID'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Clients AClients on Atbl.CLID = AClients.Client_id'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = AClients.Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' left join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source =  ''' +@p_datasource +''''
    +'   and cxref1.Non_ETO_ID = Atbl.CLID' 
    +' left join dbo.Non_ETO_Entity_Xref exref1 on exref1.Source =  ''' +@p_datasource +''''
    +'   and exref1.Non_ETO_ID = Atbl.EntityID'
    +'
     where dwtbl.Datasource = ''' +@p_datasource +''''
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', AClients.Site_ID) is null'
    +' and isnull(dwtbl.AuditDate,convert(datetime,''19700101'',112)) < '
    +' isnull(Atbl.AuditDate,convert(datetime,''19700101'',112))'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
       EXEC (@SQL)


----------------------------------------------------------------------------------------
-- Update AgencyDB with DW_TransferID:
print ' '
print 'Updating AgencyDB source table with DW indexes'
set @SQL = 'set nocount off '+
    'update ' +@Agency_Full_TableName
    +' Set [DW_TransferID] = dwtbl.[TransferID]'
    +'
     from ' +@Agency_Full_TableName +' Atbl'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Clients AClients on Atbl.CLID = AClients.Client_id'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = AClients.Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' inner join dbo.Transfers dwtbl'
       +' on dwtbl.Datasource_ID = Atbl.TransferID and dwtbl.Datasource = ''' +@p_datasource +''''
    +' Where dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', AClients.Site_ID) is null'
      +' and isnull(Atbl.DW_TransferID,999999999) != Dwtbl.TransferID'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
       EXEC (@SQL)

----------------------------------------------------------------------------------------
print ' '
print 'Cont: Delete records that no longer exist in AgencyDB'

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
    +' from dbo.' +@DW_TableName +' dwtbl'
    +' inner join dbo.Clients on dwtbl.CLID = Clients.Client_ID'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Clients.Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' where dwtbl.DataSource = ''' +@p_datasource +''''
      +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Clients.Site_ID) is null'
      +' and not exists (select Atbl.TransferID'
                        +' from ' +@Agency_Full_TableName +' Atbl'
                       +' where atbl.TransferID = dwtbl.Datasource_ID)'

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

print 'End of Process: SP_AGENCYDB_TRANSFERS'
GO
