USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_WORKGROUPS_FROM_ETO_CRM]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_WORKGROUPS_FROM_ETO_CRM
--
CREATE PROCEDURE [dbo].[SP_WORKGROUPS_FROM_ETO_CRM]
 (@p_remote_db       nvarchar(60) = null)
AS
--
-- This script controls updates to the dbo.WorkGroups tables in the Data Warehouse.
-- 
-- Processing ETO via dbo.Teams, 
--            CRM via AccountBase, AccountExtensionBase, CustomerAddressBase
--
-- Database Links:
-- CRM: CRMsrvr.Nurse_FamilyPartnership_MSCRM 

-- History:
--   20130923 - New Procedure.
--   20140926: Updated to receive a parameter for specific remote database instead of defaulting to the local db.
--             This will accommodate writing to a test database on a test instance.
--             Also changed the SQL scripts to a shel execution of the script.


DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_WORKGROUPS_FROM_ETO_CRM'

DECLARE @v_remote_db     varchar(60)
DECLARE @SQL             varchar(MAX)
DECLARE @SQL1            varchar(MAX)
DECLARE @SQL2            varchar(MAX)
DECLARE @SQL3            varchar(MAX)

IF @p_remote_db is not null
   set @v_remote_db = @p_remote_db +'.'
ELSE
   set @v_remote_Db = ''


print 'Starting: SP_WORKGROUPS_FROM_ETO_CRM'
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
----------------------------------------------------------------------------------------
print ' '
print 'Processing SP_WORKGROUPS_FROM_ETO_CRM - Processing WorkGroups from DW.Teams'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New WorkGroups from DW Teams'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off '+
   'insert into ' +@v_remote_db  +'dbo.WorkGroups'
      +' (Org_ID'
      +' ,DataSource'
      +' ,Source_WorkGroup_ID'
      +' ,WorkGroup_Name'
      +' ,WorkGroup_Effective_Date'
      +' ,WorkGroup_End_Date'
      +' ,WorkGroup_Type'
      +' ,NC_ID_NSO_1'
      +' ,NC_ID_NSO_2'
      +' ,NC_ID_SNC_1'
      +' ,NC_ID_SNC_2'
      +' ,WorkGroup_Status'
      +' ,Date_Created'
      +' ,Audit_Date'
      +' ,Entity_Disabled'
      +' ,Last_CRM_Update'
      +' ,flag_update_crm'
      +' ,CRM_ID'
      +' ,PRIMARY_SUPERVISOR_Contact_ID'
      +' ,SECONDARY_SUPERVISOR_Contact_ID'
      +' ,NUMERIC_FIELD_1'
      +' ,TEXT_FIELD_1'
      +' ,Program_ID_Staff_Supervision'
      +' ,Program_ID_NHV'
      +' ,Program_ID_Referrals'
      +' ,Programs_Audit_Date'
      +' ,State_ID)'
--
set @SQL2 = '
  select Organizations.Org_ID'
      +',isnull(Teams.DataSource,''ETO'')'
      +',Teams.Team_ID'
      +',Teams.Team_Name'
      +',Teams.Team_Effective_Date'
      +',Teams.Team_End_Date'
      +',lovv.LOV_Item as WorkGroup_Type'
      +',Teams.NC_ID_NSO_1'
      +',Teams.NC_ID_NSO_2'
      +',Teams.NC_ID_SNC_1'
      +',Teams.NC_ID_SNC_2'
      +',Teams.Team_Status'
      +',Teams.Date_Created'
      +',Teams.Audit_Date'
      +',Teams.Entity_Disabled'
      +',Teams.Last_CRM_Update'
      +',Teams.flag_update_crm'
      +',Teams.CRM_ID'
      --+',Teams.PRIMARY_SUPERVISOR'
      +',C1.Contact_Id as Primary_Supervisor_Contact_ID'
      --+',Teams.SECONDARY_SUPERVISOR'
      +',C2.Contact_Id as Secondary_Supervisor_Contact_ID'
      +',Teams.NUMERIC_FIELD_1'
      +',Teams.TEXT_FIELD_1'
      +',Teams.Program_ID_Staff_Supervision'
      +',Teams.Program_ID_NHV'
      +',Teams.Program_ID_Referrals'
      +',Teams.Programs_Audit_Date'
      +',Teams.State_ID'
--
+' from dbo.Teams'
+' join dbo.LOV_Names LOVN on LOVN.Name = ''WORKGROUP_TYPE'''
+' left join dbo.LOV_Values LOVV '
   +'on LOVN.LOV_Name_ID = LOVV.LOV_Name_ID'
 +' and LOVV.Value = ''Team'''
+' left join dbo.Agencies on Teams.Site_ID = Agencies.Site_ID'
+' left join dbo.Organizations on Agencies.Entity_Id = Organizations.Source_Entity_ID'
+' left join dbo.Contacts C1 on teams.PRIMARY_SUPERVISOR = C1.Source_Contact_ID'
      +' and ISNULL(Teams.DataSource,''ETO'') = C1.DataSource'
+' left join dbo.Contacts C2 on teams.Secondary_SUPERVISOR = C2.Source_Contact_ID'
      +' and ISNULL(Teams.DataSource,''ETO'') = C2.DataSource'
+' where not exists (select WorkGroup_ID'
                    +' from ' +@v_remote_db  +'dbo.WorkGroups WorkGroups'
                   +' where WorkGroups.datasource = ''ETO'''
                     +' and WorkGroups.Source_WorkGroup_ID = Teams.Team_ID)'
  +' and Teams.Entity_Type_ID = 21'   /*ETO Entitytype for Teams*/

    print @SQL1
    print @SQL2
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar)
       +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar) 

    EXEC (@SQL1+@SQL2)


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating WorkGroups from DW Teams'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off '+
+'update ' +@v_remote_db  +'dbo.WorkGroups'
  +' set Org_ID = Organizations.Org_ID'
     +' ,WorkGroup_Name = Teams.Team_Name'
     +' ,WorkGroup_Effective_Date = Teams.Team_Effective_Date'
     +' ,WorkGroup_End_Date = Teams.Team_End_Date'
     +' ,NC_ID_NSO_1 = Teams.NC_ID_NSO_1'
     +' ,NC_ID_NSO_2 = Teams.NC_ID_NSO_2'
     +' ,NC_ID_SNC_1 = Teams.NC_ID_SNC_1'
     +' ,NC_ID_SNC_2 = Teams.NC_ID_SNC_2'
     +' ,WorkGroup_Status = Teams.Team_Status'
     +' ,Date_Created = Teams.Date_Created'
     +' ,Audit_Date = Teams.Audit_Date'
     +' ,Entity_Disabled = Teams.Entity_Disabled'
     +' ,Last_CRM_Update = Teams.Last_CRM_Update'
     +' ,flag_update_crm = Teams.flag_update_crm'
     +' ,CRM_ID = Teams.CRM_ID'
     +' ,PRIMARY_SUPERVISOR_Contact_ID = C1.Contact_ID'
     +' ,SECONDARY_SUPERVISOR_Contact_ID = C2.Contact_ID'
     +' ,NUMERIC_FIELD_1 = Teams.NUMERIC_FIELD_1'
     +' ,TEXT_FIELD_1 = Teams.TEXT_FIELD_1'
     +' ,Program_ID_Staff_Supervision = Teams.Program_ID_Staff_Supervision'
     +' ,Program_ID_NHV = Teams.Program_ID_NHV'
     +' ,Program_ID_Referrals = Teams.Program_ID_Referrals'
     +' ,Programs_Audit_Date = Teams.Programs_Audit_Date'
     +' ,State_ID = Teams.State_ID'
set @SQL2 = '
     from ' +@v_remote_db  +'dbo.WorkGroups'
  +' inner join dbo.Teams on WorkGroups.Source_WorkGroup_ID = Teams.Team_ID'
        +' and WorkGroups.Datasource = isnull(Teams.DataSource,''ETO'')'
  +' left join dbo.Agencies on Teams.Site_ID = Agencies.Site_ID'
       +'  and isnull(Agencies.Datasource,''ETO'') = ''ETO'''
  +' left join dbo.Organizations on Agencies.Entity_Id = Organizations.Source_Entity_ID'
  +' left join dbo.Contacts C1 on teams.PRIMARY_SUPERVISOR = C1.Source_Contact_ID'
        +' and ISNULL(Teams.DataSource,''ETO'') = C1.DataSource'
  +' left join dbo.Contacts C2 on teams.Secondary_SUPERVISOR = C2.Source_Contact_ID'
        +' and ISNULL(Teams.DataSource,''ETO'') = C2.DataSource'
 +' where isnull(WorkGroups.Audit_Date,convert(datetime,''19700101'',112))'
       +' < isnull(Teams.Audit_Date,convert(datetime,''19700101'',112))'

    print @SQL1
    print @SQL2
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar)
       +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar) 

    EXEC (@SQL1+@SQL2)

----------------------------------------------------------------------------------------
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing ETO Addresses from DW Teams'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------
 
print '  Cont: SP_WORKGROUPS_FROM_ETO_CRM - Adding ETO Address Records'

set @SQL1 = 'set nocount off '+
 'insert into ' +@v_remote_db  +'dbo.WorkGroup_Addresses'
      +' (WorkGroup_ID,Address_type,Address_Name,Address1,Address2,City,State,ZipCode,county,Audit_Date)'
+' select WorkGroups.WorkGroup_ID'
      +' ,LOVV.LOV_Item'
      +' ,Teams.Address_Name'
      +' ,Teams.Address1'
      +' ,Teams.Address2'
      +' ,Teams.City'
      +' ,Teams.State'
      +' ,Teams.ZipCode'
      +' ,Teams.county'
      +' ,GETDATE()'
+' from ' +@v_remote_db  +'dbo.WorkGroups'
+' inner join dbo.Teams'
   +' on WorkGroups.Source_WorkGroup_ID = Teams.Team_ID'
+' join dbo.LOV_Names LOVN ON LOVN.Name = ''ADDRESS_TYPE'''
+' inner join dbo.LOV_Values LOVV on LOVV.LOV_Name_ID = LOVN.LOV_Name_ID'
     +'  and LOVV.Value = ''PRIMARY'''
+' where WorkGroups.datasource = ''ETO'''
  +' and not exists (select WorkGroup_Address_id'
                   +'  from ' +@v_remote_db  +'dbo.WorkGroup_Addresses'
                   +' where WorkGroup_Addresses.WorkGroup_ID = WorkGroups.WorkGroup_ID'
                     +' and WorkGroup_Addresses.Address_type = LOVV.LOV_Item)'

    print @SQL1
    EXEC (@SQL1)


print '  Cont: SP_WORKGROUPS_FROM_ETO_CRM - Updating ETO Address Records'

set @SQL1 = 'set nocount off '+
 'update ' +@v_remote_db  +'dbo.WorkGroup_Addresses'
  +' set Address1 = Teams.Address1'
     +' ,Address2 = Teams.Address2'
     +' ,Address_Name = Teams.Address_Name'
     +' ,City = Teams.City'
     +' ,State = Teams.State'
     +' ,ZipCode = Teams.ZipCode'
     +' ,county = Teams.county'
     +' ,Audit_Date = Teams.Audit_Date'
+' from ' +@v_remote_db  +'dbo.WorkGroup_Addresses Addr'
+' inner join ' +@v_remote_db  +'dbo.WorkGroups on Addr.WorkGroup_ID = WorkGroups.WorkGroup_ID'
+' inner join dbo.Teams'
   +' on WorkGroups.Source_WorkGroup_ID = Teams.Team_ID'
+' join dbo.LOV_Names LOVN ON LOVN.Name = ''ADDRESS_TYPE'''
+' inner join dbo.LOV_Values LOVV on LOVV.LOV_Name_ID = LOVN.LOV_Name_ID'
     +'  and LOVV.Value = ''PRIMARY'''
+' where WorkGroups.datasource = ''ETO'''
 +'  and Addr.Address_type = LOVV.LOV_Item'
 +'  and ((isnull(Addr.Address1,''xyz1234'') != isnull(Teams.Address1,''xyz1234'') or'
        +' isnull(Addr.Address2,''xyz1234'') != isnull(Teams.Address2,''xyz1234'') or'
        +' isnull(Addr.Address_Name,''xyz1234'') != isnull(Teams.Address_Name,''xyz1234'') or'
        +' isnull(Addr.City,''xyz1234'') != isnull(Teams.City,''xyz1234'') or'
        +' isnull(Addr.State,''zz'') != isnull(Teams.State,''zz'') or'
        +' isnull(Addr.ZipCode,''xyz1234'') != isnull(Teams.ZipCode,''xyz1234'') or'
        +' isnull(Addr.county,''xyz1234'') != isnull(Teams.county,''xyz1234''))'
       +' or Addr.Audit_Date is null)'

    print @SQL1
    EXEC (@SQL1)

----------------------------------------------------------------------------------------
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing ETO Telephones DW Teams'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

print '  Cont: SP_WORKGROUPS_FROM_ETO_CRM - Adding ETO Telephone Records'

set @SQL1 = 'set nocount off '+
 'insert into ' +@v_remote_db  +'dbo.WorkGroup_Telephones'
     +'  (WorkGroup_ID,Telephone_type,Telephone,Audit_Date)'
+' select WorkGroups.WorkGroup_ID'
      +' ,LOVV.LOV_Item'
      +' ,Teams.Phone1'
      +',getdate()'
+' from ' +@v_remote_db  +'dbo.WorkGroups'
+' inner join dbo.Teams'
    +' on WorkGroups.Source_WorkGroup_ID = Teams.Team_ID'
+' join dbo.LOV_Names LOVN ON LOVN.Name = ''TELEPHONE_TYPE'''
+' inner join dbo.LOV_Values LOVV on LOVV.LOV_Name_ID = LOVN.LOV_Name_ID'
      +' and LOVV.Value = ''PRIMARY'''
+' where WorkGroups.Datasource = ''ETO'''
  +' and not exists (select WorkGroup_Telephone_id'
                    +' from ' +@v_remote_db  +'dbo.WorkGroup_Telephones '
                   +' where WorkGroup_Telephones.WorkGroup_ID = WorkGroups.WorkGroup_ID'
                     +' and WorkGroup_Telephones.Telephone_type = LOVV.LOV_Item)'

    print @SQL1
    EXEC (@SQL1)


print '  Cont: SP_WORKGROUPS_FROM_ETO_CRM - Updating ETO Phone Records'

set @SQL1 = 'set nocount off '+
 'update ' +@v_remote_db  +'dbo.WorkGroup_Telephones'
  +' set Telephone = Teams.Phone1'
     +' ,Audit_Date = getdate()'
 +' from ' +@v_remote_db  +'dbo.WorkGroup_Telephones TEL'
 +' inner join dbo.WorkGroups on TEL.WorkGroup_ID = WorkGroups.WorkGroup_ID'
 +' inner join dbo.Teams'
   +' on WorkGroups.Source_WorkGroup_ID = Teams.Team_ID'
 +' join dbo.LOV_Names LOVN ON LOVN.Name = ''TELEPHONE_TYPE'''
 +' inner join dbo.LOV_Values LOVV on LOVV.LOV_Name_ID = LOVN.LOV_Name_ID'
       +' and LOVV.Value = ''PRIMARY'''
+'where WorkGroups.Datasource = ''ETO'''
 +' and TEL.Telephone_type = LOVV.LOV_Item'
 +' and (isnull(TEL.Telephone,''xyz1234'') != isnull(Teams.phone1,''xyz1234'')'
       +' or TEL.Audit_Date is null)'

    print @SQL1
    EXEC (@SQL1)


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


print '  End of Process: SP_WORKGROUPS_FROM_ETO_CRM'
GO
