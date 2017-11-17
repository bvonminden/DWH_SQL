USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_OK_IA_STAFF]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_OK_IA_STAFF
--
CREATE PROCEDURE [dbo].[SP_OK_IA_STAFF]
 (@p_Nurseid       int = null)
AS
--
-- This script controls integration of Oklahoma Staff to the Data Warehous IA_Staff table.
--
-- ** Defaulting Datasource as 'OKLAHOMA'
--               Audit_StaffID = 4614, EntityID=13048, name=Data Migration2, for site 260
----
-- Table effected - dbo.IA_Staff
--
-- History:
--   20131219 - New Procedure.
--   20140115 - Added logic to create Non_ETO_Entity_Xref records for missing IA_Staff Records for site 260.
--              Concept is that ETO will still receive new staff members, but will contain the OK NurseID.
--   20140214 - Added site_id to non-ETO_Xref.  This will allow the site_id to represent uniqueness between companies,
--              thus allowing the same entity_id's to be utilized by different AgencyDB sites (company).
--

DECLARE @Source_TableName nvarchar(50)
DECLARE @DW_TableName nvarchar(50)
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @p_datasource   nvarchar(10)
DECLARE @p_stop_flag    nvarchar(2)
DECLARE @Process        nvarchar(50)
DECLARE @count          smallint
DECLARE @runtime 	datetime

set @process = 'SP_OK_IA_STAFF'
set @DW_Tablename = 'IA_Staff'
--set @Source_Tablename = 'VIEW_New_Staff_DW'
Set @p_stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @p_datasource = 'OKLAHOMA'

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)
DECLARE @OK_NurseID     int
DECLARE @Entity_ID	int


-- Defaults:
DECLARE @ETO_Site_ID           int
DECLARE @ETO_Audit_StaffID     int
DECLARE @ETO_Entity_Type_ID    smallint
DECLARE @ETO_Entity_Type       nvarchar(20)
DECLARE @ETO_Entity_Subtype_ID smallint
DECLARE @ETO_Entity_Subtype    nvarchar(20)

Set @ETO_Site_ID = 260
set @ETO_Audit_StaffID = 4614
set @ETO_Entity_Type_ID = 22
set @ETO_Entity_Type = 'Administrative'
set @ETO_Entity_Subtype_ID = 1167
set @ETO_Entity_Subtype = 'Nursing Staff'
set @runtime = getdate()

print 'Processing SP_OK_IA_STAFF: Datasource = ' +isnull(@p_datasource,'NULL')
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
print 'Processing SP_OK_IA_STAFF - retrieving datasource DB Srvr from LOV tables'

set @AgencyDB = null;
select @AgencyDB = Value
  from dbo.View_LOV
 where Name = 'AGENCYDB_BY_DATASOURCE'
   and lOV_Item = @p_datasource

IF @AgencyDB is null
BEGIN
   --set @p_flag_stop = 'X';
   print 'Unable to retrieve LOV AgencyDB for datasource=' +isnull(@AgencyDB,'') +', job stopped'
   set nocount on
   update dbo.process_log 
   set Comment = 'failed, can''t retrieve LOV AgencyDB for datasource'
      ,LogDate = getdate()
 where Process = @process

END
ELSE
BEGIN


----------------------------------------------------------------------------------------
-- Populate DW.Non_ETO_Enitities_Xref table from existing ETO Entities for site 260:
--  (Only populates if entity_ID and nurseid does not exist in xref)

-- ** allow for identity column to be supplied by setting identity_insert on/off:

set @SQL = 'set identity_insert dbo.Non_ETO_Entity_Xref ON
insert into dbo.Non_ETO_Entity_Xref
       (Entity_ID, Non_ETO_ID, Non_ETO_Site_ID, Source)
select ia_staff.entity_id, ia_staff.Nurse_0_ID_Agency as Non_ETO_ID, IA_Staff.Site_ID, ''OKLAHOMA''
  from IA_Staff 
 where Site_ID=260
   and ((Entity_Subtype != ''Staff'') or
        (Entity_Subtype = ''Staff'' and
         CRM_ContactId is not null and
         nurse_0_id_agency is null))
   and not exists (select Entity_ID from dbo.Non_ETO_Entity_Xref xref2
       where xref2.Non_ETO_ID = IA_Staff.Nurse_0_ID_Agency and xref2.source = ''OKLAHOMA'')
   and not exists (select Entity_ID from dbo.Non_ETO_Entity_Xref xref2
       where xref2.Entity_ID = IA_Staff.Entity_ID and xref2.source = ''OKLAHOMA'')
set identity_insert dbo.Non_ETO_Entity_Xref off'

print @SQL
--print 'SQL Length = ' +CAST(LEN(@SQL) as varchar)
EXEC (@SQL)



----------------------------------------------------------------------------------------
print 'Processing SP_Contacts - Insert new staff members - AgencyDB=' + @AgencyDB
print 'AgencyDB Server=' +@AgencyDB_Srvr

-- Extraction for Entity:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Staff'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------


----------------------------------------------------------------------------------------
-- Build and process cursor
----------------------------------------------------------------------------------------

DECLARE StaffCursor Cursor for
select okdata.nurseid
  from View_OK_Nurses_NotIN_DW  okdata
 where not exists (select xref.entity_id
                     from dbo.Non_ETO_Entity_Xref xref
                    where xref.Non_ETO_ID = okdata.nurseid
                      and xref.source = @p_datasource)
   and okdata.nurseid is not null
   and isnull(@p_Nurseid,'99999999') in ('99999999',okdata.NurseID)

OPEN StaffCursor

FETCH next from StaffCursor
      into @ok_nurseid

WHILE @@FETCH_STATUS = 0
BEGIN


-- create non_ETO xref entries for new IA_Staff records from AgencyDB:
   insert into dbo.Non_ETO_Entity_Xref (Non_ETO_ID, Source)
     values (@OK_NurseID, @p_datasource)

   set @Entity_ID = null;

   select @Entity_ID = xref.Entity_ID
     from dbo.Non_ETO_Entity_Xref xref
    where xref.Non_ETO_ID = @ok_nurseid
      and xref.source = @p_datasource


   IF @Entity_ID is not null
   BEGIN
      insert into dbo.IA_Staff
            (Entity_ID
             ,DataSource
             ,Nurse_0_ID_Agency
             ,Full_Name
             ,First_Name
             ,Last_Name
             ,Site_ID
             ,Program_ID
             ,Entity_Type_ID
             ,Entity_Type
             ,Entity_Subtype_ID
             ,Entity_Subtype
             ,Date_Created
             ,Audit_Date
             ,Audit_Staff_ID)
      Values (@Entity_ID
             ,@p_datasource
             ,@OK_NurseID
             ,@OK_NurseID
             ,@OK_NurseID
             ,null
             ,@ETO_Site_ID
             ,null
             ,@ETO_Entity_Type_ID
             ,@ETO_Entity_Type
             ,@ETO_Entity_Subtype_ID
             ,@ETO_Entity_Subtype
             ,@runtime
             ,@runtime
             ,@ETO_Audit_StaffID)
   END

----------------------------------------------------------------------------------------
-- continue in cursor
----------------------------------------------------------------------------------------

   FETCH next from StaffCursor
         into @ok_nurseid

END -- End of StaffCursor loop

CLOSE StaffCursor
DEALLOCATE StaffCursor

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

print 'End of Process: SP_OK_IA_STAFF'
GO
