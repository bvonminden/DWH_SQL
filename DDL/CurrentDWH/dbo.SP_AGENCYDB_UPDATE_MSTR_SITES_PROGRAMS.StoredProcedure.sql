USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_UPDATE_MSTR_SITES_PROGRAMS]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_UPDATE_MSTR_SITES_PROGRAMS
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_UPDATE_MSTR_SITES_PROGRAMS]
 (@p_AgencyDB      nvarchar(30) = null
 ,@p_no_exec_flag    nvarchar(10) = 'N')
AS
--
-- This script controls the update of AgencyDB Mstr_Sites and Mstr_Programs from the Data Warehouse.
-- Will also maintain the AgencyDB related Teams and Program updates from the DW.

-- Table effected - dbo.Mstr_Sites
--                  dbo.Mstr_Programs
--                  dbo.Teams    (Teams relating only to the AgencyDB)
--                  dbo.Programs (Programs relating only to the AgencyDB)
--
--
--   Creates a cursor of AgencyDBs, then process each database accordingly.
--   ** Can override cursor selection by running with a AgencyDB parameter for only one AgencyDB.
--      Excluding SIte 74,78 (training site)
--
-- Insert: select and insert when record is found to be missing in the DW.
-- Update: select and update when record exists in DW and has been changed but has been changed flagged by Audit_Date.
--
-- History:
--   20150811 - New Procedure.
--   20160201 - Amended Mstr Insert to exclude programs that are flagged as disabled.
--              Amended to delete Mstr Programs which have been flagged as disabled in the DW.
--              Added the insertion of New Teams and Programs for just the AgencyDB (dbo.teams, dbo.programs)
--   20160205 - Amend to update AgencyDB local Team / Program tables.  AgencyDB has become master of the data.
--   20160629 - Amended to update the Programs.CRM_new_nfpagencylocationid as master data defined from within the DataWarehouse.

DECLARE @count          smallint
DECLARE @stop_flag      nvarchar(2)
DECLARE @Process        nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)

set @process = 'SP_AGENCYDB_UPDATE_MSTR_SITES_PROGRAMS'
set @DW_Tablename = null
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)
DECLARE @SQL1           varchar(MAX)
DECLARE @SQL2           varchar(MAX)

print 'Processing SP_AGENCYDB_UPDATE_MSTR_SITES_PROGRAMS: AgencyDB = ' +isnull(@p_AgencyDB,'NULL')
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
select LOV.Value
  from dbo.view_lov LOV
 where Name='AGENCYDB_BY_DATASOURCE'
   -- exclude DB not using Mstr tables
   and LOV.Value != 'OklahomaStaging'
   -- optional qualified selection:
   and isnull(@p_AgencyDB,'abcdefg') in ('abcdefg',LOV.value)
 Group by LOV.Value
 order by LOV.Value;

OPEN AgencyDBCursor

FETCH next from AgencyDBCursor
      into @AgencyDB

WHILE @@FETCH_STATUS = 0
BEGIN

----------------------------------------------------------------------------------------
print ''
print 'Cont: Process Agencies - AgencyDB=' + @AgencyDB


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing Agencies'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off'
    +' insert into ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Sites'
    +' ([Site_ID]'
    +' ,[Site_Name]'
    +' ,[City]'
    +' ,[State]'
    +' ,[ZipCode]'
    +' ,[county]'
    +' ,[Audit_Date]'
    +' ,[Site_Disabled]'
    +' ,[Entity_Type_ID]'
    +' ,[Entity_Type])'
set @SQL2 = '
     SELECT'
    +'  DWTbl.[Site_ID]' 
    +' ,DWTbl.[AGENCY_INFO_0_NAME]'
    +' ,DWTbl.[City]'
    +' ,DWTbl.[State]'
    +' ,DWTbl.[ZipCode]'
    +' ,DWTbl.[county]'
    +' ,DWTbl.[Audit_Date]'
    +' ,DWTbl.[Site_Disabled]'
    +' ,DWTbl.[Entity_Type_ID]'
    +' ,DWTbl.[Entity_Type]'
    +'
     from dbo.Agencies DWTbl'
    +' where not exists (select Atbl.Site_ID'
                        +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Sites Atbl'
                       +' where Atbl.Site_ID = DWTbl.Site_ID)'
    +' and DWTbl.Site_id not in (74,78)'

    print @SQL1
    print @SQL2
    --print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
       EXEC (@SQL1+@SQL2)



-- Update changes:
set @SQL1 = 'set nocount off'
    +' update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Sites'
    +' Set' 
    +'  [Site_Name] = DWTbl.[AGENCY_INFO_0_NAME]'
    +' ,[City] = DWTbl.[City]'
    +' ,[State] = DWTbl.[State]'
    +' ,[ZipCode] = DWTbl.[ZipCode]'
    +' ,[county] = DWTbl.[county]'
    +' ,[Audit_Date] = DWTbl.[Audit_Date]'
    +' ,[Site_Disabled] = DWTbl.[Site_Disabled]'
    +' ,[Entity_Type_ID] = DWTbl.[Entity_Type_ID]'
    +' ,[Entity_Type] = DWTbl.[Entity_Type]'
    +'
    from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Sites Atbl'
    +' inner join dbo.Agencies DWTbl on Atbl.Site_ID = DWTbl.Site_ID'
    +' where isnull(Atbl.Audit_Date,convert(datetime,''19700101'',112)) < '
    +' isnull(DWTbl.Audit_Date,convert(datetime,''19700101'',112))'

    print @SQL1
    IF upper(@p_no_exec_flag) != 'Y'
       EXEC (@SQL1)


----------------------------------------------------------------------------------------
-- Master Programs
----------------------------------------------------------------------------------------
print ''
print 'Cont: Process Programs - AgencyDB=' + @AgencyDB


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing Programs'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off'
    +' insert into ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Programs'
    +' ([Program_ID]'
    +' ,[Program_Name]'
    +' ,[Site_ID]'
    +' ,[AuditDate]'
set @SQL2 = ')
     SELECT'
    +'  DWTbl.[Program_ID]'
    +' ,DWTbl.[Program_Name]'
    +' ,DWTbl.[Site_ID]'
    +' ,DWTbl.[AuditDate]'
    +'
     from dbo.Programs DWTbl'
    +' where isnull(DWtbl.disabled,0) = 0'
    +' and not exists (select Atbl.Program_ID'
                        +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Programs Atbl'
                       +' where Atbl.Program_ID = DWTbl.Program_ID)'
    +' and exists (select Sites.Site_ID'
                   +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Sites Sites'
                  +' where Sites.Site_ID = DWTbl.Site_ID)'

    print @SQL1
    print @SQL2
    --print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
       EXEC (@SQL1+@SQL2)


-- Update changes:
set @SQL1 = 'set nocount off'
    +' update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Programs'
    +' Set' 
    +'  [Program_Name] = DWTbl.[Program_Name]'
    +' ,[Site_ID] = DWTbl.[Site_ID]'
    +' ,[AuditDate] = DWTbl.[AuditDate]'
    +'
    from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Programs Atbl'
    +' inner join dbo.Programs DWTbl on Atbl.Program_ID = DWTbl.Program_ID'
    +' where isnull(Atbl.AuditDate,convert(datetime,''19700101'',112)) < '
    +' isnull(DWTbl.AuditDate,convert(datetime,''19700101'',112))'

    print @SQL1
    IF upper(@p_no_exec_flag) != 'Y'
       EXEC (@SQL1)



-- Delete disabled Programs from AgencyDB:
set @SQL1 = 'set nocount off'
    +' delete from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Programs'
    +' where program_id in'
    +' (select atbl.program_id '
       +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Programs atbl'
       +' inner join dbo.Programs dwtbl on atbl.program_id = dwtbl.program_id' 
       +' where dwtbl.Program_ID = 1)'

    print @SQL1
    IF upper(@p_no_exec_flag) != 'Y'
       EXEC (@SQL1)


----------------------------------------------------------------------------------------
-- Local AgencyDB Programs
----------------------------------------------------------------------------------------
print ''
print 'Cont: AgencyDB only Programs - AgencyDB=' + @AgencyDB


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing Programs'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------


set @SQL1 = 'set nocount off'
    +' insert into ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Programs'
    +' ([Program_ID]'
    +' ,[Program_Name]'
    +' ,[Site_ID]'
    +' ,[AuditDate]'
    +' ,[Supervisor_ID]'
    +' ,[Team_Group_Name]'
    +' ,CRM_new_nfpagencylocationid'
    +' ,[Team_ID]'
    +' ,[Disabled]'
set @SQL2 = ')
     SELECT'
    +'  DWTbl.[Program_ID]'
    +' ,DWTbl.[Program_Name]'
    +' ,DWTbl.[Site_ID]'
    +' ,DWTbl.[AuditDate]'
    +' ,exref1.Non_ETO_ID'
    +' ,DWTbl.[Team_Group_Name]'
    +' ,DWTbl.CRM_new_nfpagencylocationid'
    +' ,DWTbl.[Team_ID]'
    +' ,DWTbl.[Disabled]'
    +'
     from dbo.Programs DWTbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = DWTbl.Site_ID'
    +' inner join dbo.view_lov LOV on asbd.DataSource = lov.lov_item'
            +' and LOV.value = ''' +@AgencyDB +''''

    +' left join dbo.Non_ETO_Entity_Xref exref1'
            +' on exref1.Source =  asbd.DataSource'   
            +' and exref1.Entity_ID = DWTbl.Supervisor_ID'

    +' where isnull(DWtbl.disabled,0) = 0'
      +' and not exists (select Atbl.Program_ID'
                        +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Programs Atbl'
                       +' where Atbl.Program_ID = DWTbl.Program_ID)'

    print @SQL1
    print @SQL2
    --print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
       EXEC (@SQL1+@SQL2)


-- Update changes 
-- (as of 2/5/2015: not used, replaced by AgencyDB being the master once the new team and program 
--  have been sent to the AgencyDB.  dbo.SP_AgencyDB_Teams_Update, dbo.SP_AgencyDB_Programs_Update control flow back to DW)
set @SQL1 = 'set nocount off'
    +' update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Programs'
    +' Set' 
    +'  [Program_Name] = DWTbl.[Program_Name]'
    +' ,[AuditDate] = DWTbl.[AuditDate]'
    +' ,[Team_Group_Name] = DwTbl.[Team_Group_Name]'
    +' ,CRM_new_nfpagencylocationid = DwTbl.CRM_new_nfpagencylocationid'
    +' ,[Team_ID] = DwTbl.[Team_ID]'
    +' ,[Disabled] = DwTbl.[Disabled]'
    +'
    from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Programs Atbl'
    +' inner join dbo.Programs DWTbl on Atbl.Program_ID = DWTbl.Program_ID'
    +' where isnull(Atbl.AuditDate,convert(datetime,''19700101'',112)) < '
    +' isnull(DWTbl.AuditDate,convert(datetime,''19700101'',112))'

  --  print @SQL1
  --  IF upper(@p_no_exec_flag) != 'Y'
  --     EXEC (@SQL1)



----------------------------------------------------------------------------------------
-- AgencyDB Only Teams
----------------------------------------------------------------------------------------
print ''
print 'Cont: AgencyDB only Teams - AgencyDB=' + @AgencyDB


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing Teams'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------


set @SQL1 = 'set nocount off'
    +' insert into ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Teams'
    +' (Team_ID'
    +' ,Team_Name'
    +' ,Address1'
    +' ,Address2'
    +' ,City'
    +' ,State'
    +' ,ZipCode'
    +' ,county'
    +' ,Phone1'
    +' ,Date_Created'
    +' ,Audit_Date'
    +' ,Entity_Disabled'
    +' ,CRM_ID'
    +' ,DataSource'
    +' ,Program_ID_Staff_Supervision'
    +' ,Program_ID_NHV'
    +' ,Program_ID_Referrals'
    +' ,Programs_Audit_Date'
set @SQL2 = ')
     SELECT'
    +'  DWTbl.Team_ID'
    +' ,DWTbl.Team_Name'
    +' ,DWTbl.Address1'
    +' ,DWTbl.Address2'
    +' ,DWTbl.City'
    +' ,DWTbl.State'
    +' ,DWTbl.ZipCode'
    +' ,DWTbl.county'
    +' ,DWTbl.Phone1'
    +' ,DWTbl.Date_Created'
    +' ,DWTbl.Audit_Date'
    +' ,DWTbl.Entity_Disabled'
    +' ,DWTbl.CRM_ID'
    +' ,DWTbl.DataSource'
    +' ,DWTbl.Program_ID_Staff_Supervision'
    +' ,DWTbl.Program_ID_NHV'
    +' ,DWTbl.Program_ID_Referrals'
    +' ,DWTbl.Programs_Audit_Date'
    +'
     from dbo.Teams DWTbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = DWTbl.Site_ID'
    +' inner join dbo.view_lov LOV on asbd.DataSource = lov.lov_item'
            +' and LOV.value = ''' +@AgencyDB +''''
    +' where isnull(DWtbl.Entity_Disabled,0) = 0'
      +' and not exists (select Atbl.Team_ID'
                        +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Teams Atbl'
                       +' where Atbl.Team_ID = DWTbl.Team_ID)'

    print @SQL1
    print @SQL2
    --print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
       EXEC (@SQL1+@SQL2)


-- Update changes:
-- (as of 2/5/2015: not used, replaced by AgencyDB being the master once the new team and program 
--  have been sent to the AgencyDB.  dbo.SP_AgencyDB_Teams_Update, dbo.SP_AgencyDB_Programs_Update control flow back to DW)
set @SQL1 = 'set nocount off'
    +' update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Teams'
    +' Set' 
    +'  Team_Name = DWTbl.Team_Name'
    +' ,Address1 = DWTbl.Address1'
    +' ,Address2 = DWTbl.Address2'
    +' ,City = DWTbl.City'
    +' ,State = DWTbl.State'
    +' ,ZipCode = DWTbl.ZipCode'
    +' ,county = DWTbl.county'
    +' ,Phone1 = DWTbl.Phone1'
    +' ,Date_Created = DWTbl.Date_Created'
    +' ,Audit_Date = DWTbl.Audit_Date'
    +' ,Entity_Disabled = DWTbl.Entity_Disabled'
    +' ,CRM_ID = DWTbl.CRM_ID'
    +' ,DataSource = DWTbl.DataSource'
    +' ,Program_ID_Staff_Supervision = DWTbl.Program_ID_Staff_Supervision'
    +' ,Program_ID_NHV = DWTbl.Program_ID_NHV'
    +' ,Program_ID_Referrals = DWTbl.Program_ID_Referrals'
    +' ,Programs_Audit_Date = DWTbl.Programs_Audit_Date'
    +' ,Disabled = DWTbl.Disabled'
    +'
    from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Teams Atbl'
    +' inner join dbo.Teams DWTbl on Atbl.Team_ID = DWTbl.Team_ID'
    +' where Atbl.Team_Name != DWTbl.Team_Name'
    +' or Atbl.Address1 != DWTbl.Address1'
    +' or Atbl.Address2 != DWTbl.Address2'
    +' or Atbl.City != DWTbl.City'
    +' or Atbl.State != DWTbl.State'
    +' or Atbl.ZipCode != DWTbl.ZipCode'
    +' or Atbl.county != DWTbl.county'
    +' or Atbl.Phone1 != DWTbl.Phone1'
    +' or Atbl.CRM_ID != DWTbl.CRM_ID'
    +' or Atbl.Program_ID_Staff_Supervision != DWTbl.Program_ID_Staff_Supervision'
    +' or Atbl.Program_ID_NHV != DWTbl.Program_ID_NHV'
    +' or Atbl.Program_ID_Referrals != DWTbl.Program_ID_Referrals'
    +' or Atbl.Programs_Audit_Date != DWTbl.Programs_Audit_Date'
    +' or Atbl.Disabled != DWTbl.Disabled'

  --  print @SQL1
  --  IF upper(@p_no_exec_flag) != 'Y'
  --     EXEC (@SQL1)


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


print 'End of Process: SP_AGENCYDB_UPDATE_MSTR_SITES_PROGRAMS'
GO
