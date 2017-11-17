USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_STAFFXENTITIES]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_STAFFXENTITIES
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_STAFFXENTITIES]
 (@p_datasource      nvarchar(10) = null
 ,@p_no_exec_flag    nvarchar(10) = 'N')
AS
--
-- This script controls integration of AgencyDB Surveys to the Data Warehouse 
-- STAFFXENTITIES table.
--
-- Multipart process:
--   - create a Staff_Xreff for each unique StaffID found in the AgencyDB
--        this will generate a unique Non_ETO_StaffID that will interface with ETO records.
--   - Create a baseline StaffXEntity_Xref
--        copied from the Agencydb the StaffXEntity table (staffid, entityid)
--              or built fron the AgencyDB IA_Staff table (Entity_ID = StaffID)
--   - Integrate into the actual DW StaffXEntities table, 
--        using the StaffXEntity_Xref table, pulling in corresponding StaffID and EntityID xref translations.
--   
--
-- Table effected - dbo.STAFFXENTITIES
--
-- Insert: select and insert when record is found to be missing in the DW.
-- Update: select and update when record exists in DW and has been changed but has been changed flagged by Audit_Date.
--
-- IDs translated via DW/AgencyDB Non_ETO_Xref mapping:
--    StaffID     (lookup, using DW.non_ETO_Staff_Xref - non_ETO_ID + Datasource)
--    EnityID     (lookup, using DW.non_ETO_Entity_xref - non_ETO_ID + Datasource)
--
-- History:
--   20131220 - New Procedure.
--   20140326 - Added Site_ID qualifier by datasource, to allow multiple datasources to share the same AgencyDB.
--              Added database trigger to inhibit the processing of this procedure (defaulting as always process).
--                This trigger is used to bypass the process w/o having to modify the SSIS integration packages.
--   20140918 - Amended to bypass IA_Staff from the AgencyDB if they do not exist in the DW.IA_Staff table.
--              Drive the load based upon what has been loaded into the DW.IA_staff 
--              instead of what may be at the AgencyDB that could have been bypassed from the load.
--   20141001 - Changed to utilize the ETO StaffXEnties record if found.  
--   02150212 - Added update to DW.StaffXEntities.datasource for positive re-mappings (from ETO to new source).
--              Added option to not actually execute the SQL statements, used for validation/troubleshooting purposes.

DECLARE @count          smallint
DECLARE @stop_flag      nvarchar(2)
DECLARE @Process        nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)
DECLARE @Source_TableName        nvarchar(50)
DECLARE @Agency_Full_TableName   nvarchar(100)

set @process            = 'SP_AGENCYDB_STAFFXENTITIES'
--set @DW_Tablename     = 'STAFFXENTITIES'
--set @Source_Tablename = 'STAFFXENTITY'
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)

print 'Processing SP_AGENCYDB_STAFFXENTITIES: Datasource = ' +isnull(@p_datasource,'NULL')
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

-- Extraction for insert:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- Part 1: create a StaffID for the entity within the Non_ETO_STAFF_Xref.
--         Use existing ETO StaffID if found, else default next to next ID in seq.

-- create non_ETO xref entries for AgencyDB IA_Staff records (that originated from ETO):
print' '
print 'Creating Non_ETO_STAFF_Xref (Originating from ETO)'
set @SQL = 'set nocount off '+
    ' set identity_insert dbo.Non_ETO_STAFF_Xref on '
    +' insert into Non_ETO_STAFF_Xref'
    +' (StaffID, Non_ETO_ID, Non_ETO_Site_ID, Prior_Source, Source)'
    +'
     select sxe.StaffID,Atbl.Entity_ID, Atbl.Site_ID, ''ETO'', ''' +@p_datasource +''''
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.IA_Staff Atbl'
    +' inner join dbo.Non_ETO_Entity_Xref xref on xref.Non_ETO_ID = Atbl.Entity_ID'
    +'   and xref.Source =  ''' +@p_datasource +''''

    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''

    +' inner join dbo.StaffXEntities sxe on xref.Entity_ID = sxe.EntityID and sxe.TargetSiteID = atbl.Site_ID'
    +'   and isnull(sxe.DataSource,''ETO'') = ''ETO'''

    +' where not exists (select dwxref.StaffID'
                        +' from dbo.Non_ETO_STAFF_Xref dwxref'
                       +' where dwxref.source = ''' +@p_datasource +''''
                         +' and dwxref.Non_ETO_ID = Atbl.Entity_ID'
                         +' and dwxref.Non_ETO_Site_ID = atbl.Site_ID)'
      +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.Site_ID) is null'
    +' group by sxe.StaffID,Atbl.Entity_ID, Atbl.Site_ID'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)


-- create non_ETO xref entries for new AgencyDB (equating Entity_ID = Staff_ID, for new records not from ETO):
print' '
print 'Creating Non_ETO_STAFF_Xref (Not originating from ETO)'
set @SQL = 'set nocount off '+
    ' set identity_insert dbo.Non_ETO_STAFF_Xref off '
    +' insert into Non_ETO_STAFF_Xref'
    +' (Non_ETO_ID, Non_ETO_Site_ID, Source)'
    +'
     select distinct(Atbl.Entity_ID), Atbl.Site_ID, ''' +@p_datasource +''''
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.IA_Staff Atbl'
    +' inner join dbo.Non_ETO_Entity_Xref xref on xref.Non_ETO_ID = Atbl.Entity_ID'
    +'   and xref.Source =  ''' +@p_datasource +''''

    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''

    +' where not exists (select dwxref.StaffID'
                        +' from dbo.Non_ETO_STAFF_Xref dwxref'
                       +' where dwxref.source = ''' +@p_datasource +''''
                         +' and dwxref.Non_ETO_ID = xref.Non_ETO_ID'
                         +' and dwxref.Non_ETO_Site_ID = atbl.Site_ID)'
     +' and not exists (select staffid from dbo.StaffXEntities sxe '
                      +' where sxe.EntityID = xref.Entity_ID '
                        +' and sxe.DataSource = ''' +@p_datasource +''''
                        +' and sxe.TargetSiteID = atbl.Site_ID)'
     +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.Site_ID) is null'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)

---------------------------------------------

-- Part 2: create Non_ETO_STAFFXENTITIES_Xref entries, to parallel the ETO table.
--         Will attempt to map to existing ETO records, else will create new records with next seq ID.
--         This will then feed the the DW.STAFFXENTITIES table for add/updates.

-- create non_ETO xref entries for new STAFFXENTITIES records from IA_Staff records loaded from AgencyDB:
-- with combined indexes on source StaffID, Entity_ID, Target_SiteID
--  ** for staff records already existing in ETO:

print' '
print 'Creating Non_ETO_STAFFXENTITIES_Xref (Originating from ETO)'
set @SQL = 'set nocount off '+
    ' set identity_insert Non_ETO_STAFFXENTITIES_Xref on '
    +' insert into Non_ETO_STAFFXENTITIES_Xref'
    +' (sxe.StaffXEntityID, Non_ETO_StaffID, Non_ETO_EntityID, Non_ETO_TargetSiteID, Prior_Source, Source)'
    +'
     select sxe.StaffXEntityID, nes.StaffID, AIA_Staff.Entity_ID, AIA_Staff.Site_ID, isnull(sxe.DataSource,''ETO''), ''' +@p_datasource +''''
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.IA_Staff AIA_Staff'
    +' inner join dbo.Non_ETO_Entity_Xref xref on xref.Non_ETO_ID = AIA_Staff.Entity_ID'
          +' and xref.Source =  ''' +@p_datasource +''''

    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = AIA_Staff.Site_ID'
          +' and asbd.DataSource =  ''' +@p_datasource +''''

    +' inner join dbo.Non_ETO_Staff_Xref nes on AIA_Staff.Entity_ID = nes.Non_ETO_ID'
          +' and nes.Non_ETO_Site_ID = AIA_Staff.Site_ID'

          +' and nes.Source = ''' +@p_datasource +''''
    +' inner join dbo.StaffXEntities sxe on xref.Entity_ID = sxe.EntityID and sxe.TargetSiteID = AIA_Staff.Site_ID'
          +' and isnull(sxe.DataSource,''ETO'') = ''ETO'''

    +' where not exists (select dwxref.StaffXEntityID'
                        +' from dbo.Non_ETO_STAFFXENTITIES_Xref dwxref'
                       +' where dwxref.source = ''' +@p_datasource +''''
                         +' and dwxref.Non_ETO_StaffID = nes.StaffID'
                         +' and dwxref.Non_ETO_EntityID = AIA_Staff.Entity_ID'
                        +' and isnull(dwxref.Non_ETO_TargetSiteID,999999999) = isnull(AIA_Staff.Site_ID,999999999)'
                      +' )'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', AIA_Staff.Site_ID) is null'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)


-- update the StaffXEntities datasource for any new re-mapping of non-eto-exref records to an existing ETO record:
print' '
print'remapping datasource:'
set @SQL = 'set nocount off '+
     ' update dbo.StaffXEntities'
       +' set DataSource = dwxref.source'
      +' from dbo.Non_ETO_STAFFXENTITIES_Xref dwxref'
     +' inner join dbo.StaffXEntities on dwxref.StaffXEntityID = StaffXEntities.StaffXEntityID'
           +' and dwxref.prior_source = isnull(StaffXEntities.datasource,''ETO'')'
     +' where dwxref.Source =  ''' +@p_datasource +''''
       +' and dwxref.Prior_Source is not null'
       +' and dwxref.Prior_Source != dwxref.Source'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    exec (@SQL)



-- create non_ETO xref entries for new STAFFXENTITIES records from IA_Staff records loaded from AgencyDB:
-- with combined indexes on source StaffID, Entity_ID, Target_SiteID

print' '
print 'Creating Non_ETO_STAFFXENTITIES_Xref (Not originating from ETO)'
set @SQL = 'set nocount off '+
    ' set identity_insert Non_ETO_STAFFXENTITIES_Xref off '
    +' insert into Non_ETO_STAFFXENTITIES_Xref'
    +' (Non_ETO_StaffID, Non_ETO_EntityID, Non_ETO_TargetSiteID, Source)'
    +'
     select nes.StaffID, AIA_Staff.Entity_ID, AIA_Staff.Site_ID, ''' +@p_datasource +''''
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.IA_Staff AIA_Staff'
    +' inner join dbo.Non_ETO_Entity_Xref xref on xref.Non_ETO_ID = AIA_Staff.Entity_ID'
    +'   and xref.Source =  ''' +@p_datasource +''''

    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = AIA_Staff.Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''

    +' inner join dbo.Non_ETO_Staff_Xref nes on AIA_Staff.Entity_ID = nes.Non_ETO_ID'
          +' and nes.Non_ETO_Site_ID = AIA_Staff.Site_ID'
          +' and nes.Source = ''' +@p_datasource +''''

    +' where not exists (select dwxref.StaffXEntityID'
                        +' from dbo.Non_ETO_STAFFXENTITIES_Xref dwxref'
                       +' where dwxref.source = ''' +@p_datasource +''''
                         +' and dwxref.Non_ETO_StaffID = nes.StaffID'
                         +' and dwxref.Non_ETO_EntityID = AIA_Staff.Entity_ID'
                        +' and isnull(dwxref.Non_ETO_TargetSiteID,999999999) = isnull(AIA_Staff.Site_ID,999999999)'
                      +' )'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', AIA_Staff.Site_ID) is null'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)


---------------------------------------------

-- Part 3: Merge the non_eto_StaffXEntities table in to the main StaffXEntities table:

-- insert new DW record:
print' '
print 'Merging into actual StaffXEntities table'
set @SQL = 'set nocount off'
    +' insert into dbo.StaffXEntities'
    +' ([StaffXEntityID]'
    +' ,Datasource'
    +' ,[StaffID]'
    +' ,[EntityID]'
    +' ,[TargetSiteID]'
    +' ,[AuditDate])'
    +'
     SELECT  StaffXEntityID as StaffXEntityID, ''' +@p_datasource +''''
    +' ,atbl.Non_ETO_StaffID'
    +' ,exref1.Entity_ID'
    +' ,Atbl.non_ETO_TargetSiteID'
    +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from dbo.Non_ETO_StaffXEntities_Xref Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = atbl.non_ETO_TargetSiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    -- xref to non_ETO StaffID
    +' left join dbo.Non_ETO_Staff_Xref sxref1 on sxref1.Source =  ''' +@p_datasource +''''
    +'   and sxref1.Non_ETO_ID = Atbl.Non_ETO_StaffID'  
    -- xref to non_ETO Entity_ID
    +' left join dbo.Non_ETO_Entity_Xref exref1 on exref1.Source =  ''' +@p_datasource +''''
    +'   and exref1.Non_ETO_ID = Atbl.Non_ETO_EntityID'  
    +' where not exists (select dwtbl.StaffXEntityID'
    +' from dbo.StaffXEntities dwtbl'
    +' where dwtbl.StaffXEntityID = Atbl.StaffXEntityID)'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', atbl.non_ETO_TargetSiteID) is null'
     

    print @SQL
    print 'Length = ' +CAST(LEN(@SQL) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)


----------------------------------------------------------------------------------------
print 'Cont: Update changes'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- not being executed

set @SQL = 'set nocount off'
    +' update dbo.' +@DW_Tablename
    +' Set [EntityID] = exref1.Entity_ID'
    +', [StaffID] = exref1.[StaffID]'
    +', [TargetSiteD] = exref1.Site_ID'
    +', [AuditDate] = Atbl.[AuditDate]'
    +'
     from dbo.' +@DW_Tablename +' dwtbl'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +' Atbl'
    +'   on dwtbl.StaffXEntityID = Atbl.DW_StaffXEntityID'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = atbl.TargetSiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' left join dbo.Non_ETO_Staff_Xref sxref1 on sxref1.Source =  ''' +@p_datasource +''''
    +'   and sxref1.Non_ETO_ID = Atbl.StaffID'  
    +' left join dbo.Non_ETO_Entity_Xref exref1 on exref1.Source =  ''' +@p_datasource +''''
    +'   and exref1.Non_ETO_ID = Atbl.EntityID' 
    +'
     where isnull(dwtbl.AuditDate,convert(datetime,''19700101'',112)) <'
    +' isnull(Atbl.AuditDate,convert(datetime,''19700101'',112))'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', atbl.TargetSiteID) is null'

-- don't process (may not be required, as that staff and entity should not go-away becuase of 
-- references to survey data)
    --print @SQL
    --IF upper(@p_no_exec_flag) != 'Y'
    ----EXEC (@SQL)



----------------------------------------------------------------------------------------
print 'Cont: Delete records that no longer exist in AgencyDB'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Deleting ETO Deletions'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

/*
set @SQL = 'set nocount off '+
    ' delete dbo.StaffXEntities'
    +' from dbo.' +@DW_Tablename 
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = atbl.TargetSiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' where DataSource = @p_datasource'
    +' and not exists (select Atbl.DW_SurveyResponseID'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo' +@Source_Tablename +' Atbl'
    +' where DW_SurveyResponseID = STAFFXENTITIES.SurveyResponseID)
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', atbl.TargetSiteID) is null'
*/


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

print 'End of Process: SP_AGENCYDB_STAFFXENTITIES'
GO
