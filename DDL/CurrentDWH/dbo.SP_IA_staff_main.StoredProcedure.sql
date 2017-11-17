USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_IA_staff_main]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_IA_staff_main
--
CREATE PROCEDURE [dbo].[SP_IA_staff_main]
AS
--
-- This script controls updates to the IA_Staff table in the Data Warehouse.
-- Processing ETO Entities identified as Non-Individuals.
--
-- Will exclude from DW if Site Does not exist in dbo.agencies
--
-- Table effected - dbo.IA_Staff
--
-- Insert: select and insert when ETO IA_Staff entity is found to be missing in the DW.
-- Update: select and update when ETO IA_Staff entity exists in DW and has been changed in ETO.
--
-- History:
--   20110126 - Added closing routing to update DW disabled flag to active for re-activated
--              ETO records not triggering an audit_date change.
--   20100614 - Replaced Custom Entity Attributes process SP_ETO_to_DW_Entity_Attributes
--              with re-written proc: sp_eto_to_dw_entity_attributes_staff.
--   20110713 - Added the update of the ia_staff.full_name=entities.entityname when contact info is updated.
--              This is because ETO does not update the entities auditdate when a contact name changes, but it
--              does update the entities field.
--   20120306 - Added conditional selection and updates based upon the field DataSource being null.
--   20130326 - Added logic to populate IA_Staff.ETO_LoginID.
--   20130422 - Added logic to exclude specific sites via dbo.Sites_Excluded table.
--   20130530 - Moved the logic of updating the ETO_LoginID below IA_Staff Updates. 
--              This accommodates the changes to the AuditStaffID to reflect a new LoginID.
--   20130731 - Added logic to integrate the Entities.IntegrationID as the manually entered Contact_ID.
--   20140115 - Added logic to ignore excluded sites when the 'IA_STAFF' is included in the tables_to_ignore field.


DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_IA_STAFF_MAIN'

DECLARE @CRM_coursedate_cutover	datetime
set @CRM_coursedate_cutover = convert(datetime,'20101013',112)

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
print 'Processing SP_IA_staff_main - Insert new staff members'
-- Extraction for Entity:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Staff'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- Basic IA_Staff info (standard attributes):
insert into dbo.IA_Staff
      (Entity_ID
      ,Site_ID
      ,Full_Name
      ,Last_Name
      ,First_Name
      ,Middle_Name
      ,Prefix
      ,Suffix
      ,Entity_Type_ID
      ,Entity_Type 
      ,Entity_SubType_ID
      ,Entity_SubType 
--      ,Program_ID
      ,Address1
      ,Address2 
      ,City
      ,State
      ,ZipCode
      ,County
      ,Email
      ,Phone1
      ,Date_Created
      ,Audit_Date
      ,Contacts_Audit_Date
      ,Audit_Staff_ID
      ,Disabled)
select Entities.EntityID
      ,Sites.SiteID
      ,EntityName
      ,replace(EContacts.Lname,'''''','''')
      ,EContacts.FName
      ,EContacts.MiddleInitial
      ,Prefixes.Prefix
      ,Suffixes.Suffix
      ,EntityXEntityType.EntityTypeID
      ,EntityTypes.EntityType 
      ,EntityXEntityType.EntitySubTypeID
      ,EntitySubTypes.EntitySubType 
--      (mult programs, so use program_ID as the xref to CRM TeaM Location, via programs proc)
--      ,Entities.ProgramID
--      ,Entities.Address1
--      ,Entities.Address2
--      ,EZipCodes.City
--      ,EZipCodes.State 
--      ,Entities.ZipCode
--      ,EZipCodes.County
      ,EContacts.Address1
      ,EContacts.Address2
      ,ECZipCodes.City
      ,ECZipCodes.State
      ,EContacts.ZipCode
      ,ECZipCodes.County
      ,EContacts.Email
      ,Entities.GeneralPhoneNumber
      ,Entities.DateCreated
      ,Entities.AuditDate
      ,EContacts.AuditDate
      ,Entities.AuditStaffID
      ,Entities.Disabled
  from ETOSRVR.etosolaris.dbo.Entities Entities
  -- FYI Note: Possible secondary Type / Subtype selections
  LEFT JOIN ETOSRVR.etosolaris.dbo.EntityXEntityType EntityXEntityType
       JOIN ETOSRVR.etosolaris.dbo.EntityTypes EntityTypes
            ON EntityXEntityType.EntityTypeID = EntityTypes.EntityTypeID
  LEFT JOIN ETOSRVR.etosolaris.dbo.EntitySubTypes EntitySubTypes
            ON EntityXEntityType.EntitySubTypeID = EntitySubTypes.EntitySubTypeID
            ON Entities.EntityID = EntityXEntityType.EntityID
  LEFT JOIN ETOSRVR.etosolaris.dbo.Staff Staff
       on Entities.AuditStaffID = Staff.StaffID 
--  LEFT JOIN ETOSRVR.etosolaris.dbo.ZipCodes EZipCodes   -- called locally from copied table
  LEFT JOIN PostalCodesUnduplicated  EZipCodes
	ON Entities.ZipCode = EZipCodes.ZipCode
  LEFT JOIN ETOSRVR.etosolaris.dbo.sites Sites
       on Staff.SiteID = Sites.SiteID
  LEFT Join ETOSRVR.etosolaris.dbo.EntityXEntityContact ECX
       on Entities.EntityID = ECX.EntityID 
          and ECX.EntityXEntityContactTypeID is null
  LEFT Join ETOSRVR.etosolaris.dbo.entitycontacts EContacts
       on ECX.EntityContactID = EContacts.EntityContactID
  LEFT Join ETOSRVR.etosolaris.dbo.EntityXEntityContactTypes ECType
       on ECX.EntityXEntityContactTypeID = ECType.EntityXEntityContactTypeID
--  LEFT JOIN ETOSRVR.etosolaris.dbo.ZipCodes ECZipCodes   -- called locally from copied table
  LEFT JOIN PostalCodesUnduplicated  ECZipCodes 
       ON EContacts.ZipCode = ECZipCodes.ZipCode
  LEFT JOIN ETOSRVR.etosolaris.dbo.Suffixes Suffixes
       ON EContacts.SuffixID = Suffixes.SuffixID
       and Suffixes.Disabled = 0
  LEFT JOIN ETOSRVR.etosolaris.dbo.Prefixes Prefixes
       ON EContacts.PrefixID = Prefixes.PrefixID
 where Entities.IsIndividual = 1
-- discregard disabled test entites:
   and upper(substring(isnull(EContacts.LName,'abcd'),1,4)) not in ('TEST','FAKE')
   and upper(substring(isnull(EContacts.FName,'abcd'),1,4)) not in ('TEST','FAKE')
   and upper(substring(isnull(EntityName,'abcd'),1,4)) not in ('TEST','FAKE')
   and ECX.EntityContactID = (select max(ECX2.EntityContactID)
                               from ETOSRVR.etosolaris.dbo.EntityXEntityContact ECX2
                              where ECX2.EntityID = ECX.EntityID 
                                and ECX2.EntityXEntityContactTypeID is null)
   and not exists (select nfpiastaff.Entity_ID
                     from dbo.IA_Staff nfpiastaff
                    where nfpiastaff.Entity_Id = Entities.EntityId)
   and exists (select nfpagencies.Site_ID
                     from dbo.Agencies nfpagencies
                    where nfpagencies.Site_Id = Sites.SiteId)
   and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = Sites.SiteId
                      and isnull(ex2.tables_to_ignore,'') not like '%IA_STAFF%');


----------------------------------------------------------------------------------------
print '  Cont: SP_IA_staff_main - Update staff standard attribute changes'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Staff'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- Basic IA_Staff info (standard attributes):
update dbo.IA_Staff
   set Full_Name = Entities.EntityName
      ,Site_ID = Sites.SiteID
      ,Entity_Type_ID = EntityXEntityType.EntityTypeID
      ,Entity_Type  = EntityTypes.EntityType
      ,Entity_SubType_ID = EntityXEntityType.EntitySubTypeID
      ,Entity_SubType  = EntitySubTypes.EntitySubType
--      (mult programs, so use program_ID as the xref to CRM TeaM Location, via programs proc)
--      ,Program_ID = Entities.ProgramID
--      ,Address1 = Entities.Address1
--      ,Address2  = Entities.Address2
--      ,City = ZipCodes.City
--      ,State = ZipCodes.State
--      ,ZipCode = Entities.ZipCode
--      ,County = ZipCodes.County
      ,Phone1 = Entities.GeneralPhoneNumber
      ,Audit_Date = Entities.AuditDate
      ,Audit_Staff_ID = Entities.AuditStaffID
      ,Disabled = Entities.Disabled
  from dbo.IA_Staff IA_Staff
  INNER JOIN ETOSRVR.etosolaris.dbo.Entities Entities
          ON Entities.EntityID = IA_Staff.Entity_ID
  -- FYI Note: Possible secondary Type / Subtype selections
  LEFT JOIN ETOSRVR.etosolaris.dbo.EntityXEntityType EntityXEntityType
       JOIN ETOSRVR.etosolaris.dbo.EntityTypes EntityTypes
         ON EntityXEntityType.EntityTypeID = EntityTypes.EntityTypeID
  LEFT JOIN ETOSRVR.etosolaris.dbo.EntitySubTypes EntitySubTypes
         ON EntityXEntityType.EntitySubTypeID = EntitySubTypes.EntitySubTypeID
         ON Entities.EntityID = EntityXEntityType.EntityID
  LEFT JOIN ETOSRVR.etosolaris.dbo.Staff Staff
         on Entities.AuditStaffID = Staff.StaffID 
  LEFT JOIN ETOSRVR.etosolaris.dbo.sites Sites
         on Staff.SiteID = Sites.SiteID
 where Entities.IsIndividual = 1
--   and Entities.Disabled = 0
   and (isnull(IA_Staff.Audit_Date,convert(datetime,'19700101',112)) < Entities.AuditDate
        or Entity_Type_ID != EntityXEntityType.EntityTypeID
        or Entity_SubType_ID != EntityXEntityType.EntitySubTypeID)
   and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = Sites.SiteId
                      and isnull(ex2.tables_to_ignore,'') not like '%IA_STAFF%');



----------------------------------------------------------------------------------------
print '  Cont: SP_IA_staff_main - Update staff Contacts Changes'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Contact Info'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- Basic IA_Staff info (Contact attributes):
update dbo.IA_Staff
   set Full_Name = Entities.EntityName
      ,Last_Name = replace(EContacts.Lname,'''''','''')
      ,First_Name = EContacts.FName
      ,Middle_Name = EContacts.MiddleInitial
      ,Prefix = Prefixes.Prefix
      ,Suffix = Suffixes.Suffix
      ,Address1 = EContacts.Address1
      ,Address2  = EContacts.Address2
      ,City = ECZipCodes.City
      ,State = ECZipCodes.State
      ,ZipCode = EContacts.ZipCode
      ,County = ECZipCodes.County
      ,Email = EContacts.Email
      ,Contacts_Audit_Date = EContacts.AuditDate
  from dbo.IA_Staff IA_Staff
  INNER JOIN ETOSRVR.etosolaris.dbo.Entities Entities
          ON Entities.EntityID = IA_Staff.Entity_ID
  LEFT Join ETOSRVR.etosolaris.dbo.EntityXEntityContact ECX
       on Entities.EntityID = ECX.EntityID 
          and ECX.EntityXEntityContactTypeID is null
  LEFT Join ETOSRVR.etosolaris.dbo.entitycontacts EContacts
       on ECX.EntityContactID = EContacts.EntityContactID
  LEFT Join ETOSRVR.etosolaris.dbo.EntityXEntityContactTypes ECType
       on ECX.EntityXEntityContactTypeID = ECType.EntityXEntityContactTypeID
--  LEFT JOIN ETOSRVR.etosolaris.dbo.ZipCodes ECZipCodes   -- called locally from copied table
  LEFT JOIN PostalCodesUnduplicated ECZipCodes 
       ON EContacts.ZipCode = ECZipCodes.ZipCode
  LEFT JOIN ETOSRVR.etosolaris.dbo.Suffixes Suffixes
       ON EContacts.SuffixID = Suffixes.SuffixID
       and Suffixes.Disabled = 0
  LEFT JOIN ETOSRVR.etosolaris.dbo.Prefixes Prefixes
       ON EContacts.PrefixID = Prefixes.PrefixID
 where Entities.IsIndividual = 1
   and ECX.EntityContactID = (select max(ECX2.EntityContactID)
                                from ETOSRVR.etosolaris.dbo.EntityXEntityContact ECX2
                               where ECX2.EntityID = ECX.EntityID)
   and EContacts.AuditDate >
         isnull(IA_Staff.Contacts_Audit_Date,convert(datetime,'19700101',112))
   and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = IA_Staff.Site_Id
                      and isnull(ex2.tables_to_ignore,'') not like '%IA_STAFF%');



-- update IA_Staff ETO_LoginID:
update dbo.IA_Staff
   set ETO_LoginID = staff.LoginID
  from dbo.IA_Staff
  inner join etosolaris.dbo.staff staff on IA_Staff.Last_Name = staff.lname
  inner join etosolaris.dbo.staffxentities 
     on IA_Staff.Entity_Id = staffxentities.entityid
     and IA_Staff.site_id = staffxentities.TargetSiteID
     and staffxentities.staffid = staff.staffid
 where isnull(IA_Staff.datasource,'ETO') = 'ETO'
   and IA_Staff.ETO_LoginID is null;


-- update IA_Staff ETO_IntegrationID:
update dbo.IA_Staff
   set ETO_IntegrationID = ltrim(staff.IntegrationID)
  from dbo.IA_Staff
  inner join etosolaris.dbo.staff staff on IA_Staff.Last_Name = staff.lname
  inner join etosolaris.dbo.staffxentities 
     on IA_Staff.Entity_Id = staffxentities.entityid
     and IA_Staff.site_id = staffxentities.TargetSiteID
     and staffxentities.staffid = staff.staffid
 where isnull(IA_Staff.datasource,'ETO') = 'ETO'
   and Staff.IntegrationID != ' '
   and IA_Staff.ETO_IntegrationID is null;

-- update IA_Staff Contact_ID:
update dbo.IA_Staff
   set DW_Contact_ID = Contacts.Contact_ID
  from dbo.IA_Staff
  inner join dbo.Contacts on dbo.fnCleanINTString (IA_Staff.ETO_IntegrationID)
             = Contacts.Contact_ID
 where IA_Staff.ETO_IntegrationID is not null
   and IA_Staff.DW_Contact_ID is null

----------------------------------------------------------------------------------------
print '  Cont: SP_IA_staff_main - Delete ETO Deleted Entities'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Deleting ETO Deletions'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

delete dbo.IA_Staff
  from dbo.IA_Staff
 where isnull(DataSource,'ETO') = 'ETO'
   and not exists (select EntityID
                     from ETOSRVR.etosolaris.dbo.Entities Entities
                    where EntityID = IA_Staff.Entity_ID)
   and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = IA_Staff.Site_Id
                      and isnull(ex2.tables_to_ignore,'') not like '%IA_STAFF%')



----------------------------------------------------------------------------------------
PRINT 'Calling SP_ETO_to_DW_Entity_Attributes for Individuals/Staff'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Calling Attributes Process IND'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

exec SP_ETO_to_DW_Entity_Attributes_Staff

-- (Optional parameters p_entity_id, p_debug_level; defaulting to all w/no debug)


/*
----------------------------------------------------------------------------------------
PRINT 'Mapping New_Hire_Survey records to entered ETO IA_Staff record'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Relating NewHire Survery with IA_Staff'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

update dbo.New_Hire_Survey 
   set Entity_Id_Mapped = IA_Staff.Entity_ID
  from dbo.New_Hire_Survey nhs
  inner join IA_Staff
         on nhs.new_hire_0_name_last = IA_Staff.Last_Name
        and nhs.new_hire_1_name_first = IA_Staff.First_Name
        and nhs.new_hire_0_email = IA_Staff.email
  where nhs.validation_ind = 'Validated'
    and nhs.Entity_ID_Mapped is null

*/

----------------------------------------------------------------------------------------
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Migrating CRM Courses'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- Insert into the DW_Completed_Courses Table:
insert into dbo.DW_Completed_Courses
       (Entity_id, ContactID, CRM_Course_Nbr, Course_Name, Completion_date, 
        Reason_For_Education)

       Select IA_Staff.Entity_ID
             ,CCC.ContactID
             ,CCC.Course_Nbr
             ,CCC.Course_Name
             ,CCC.Completion_Date
             ,ccc.Reason_For_Education
         from dbo.IA_Staff
         inner join dbo.crm_completed_courses CCC
                 on IA_Staff.CRM_ContactID = CCC.ContactID
        where IA_Staff.CRM_ContactID is not null
          and CCC.Completion_Date < @CRM_coursedate_cutover
          and (select count(*)
                 from dbo.DW_Completed_Courses DWCC
                where DWCC.ContactID = CCC.ContactID
                 and DWCC.CRM_Course_Nbr = CCC.Course_Nbr) = 0;


----------------------------------------------------------------------------------------
-- update disabled ETO entities becuase the disabled flag does not trigger an Audit Date
----------------------------------------------------------------------------------------
update IA_Staff
   set Disabled = 1
from IA_Staff 
 where Entity_id in
 (select Entityid
  from dbo.IA_Staff
  inner join ETOSRVR.etosolaris.dbo.Entities
     on Entities.EntityID = IA_Staff.Entity_Id
 where Entities.Disabled = 1
   and IA_Staff.Disabled = 0)
   and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = IA_Staff.Site_Id
                      and isnull(ex2.tables_to_ignore,'') not like '%IA_STAFF%')

update IA_Staff
   set Disabled = 0
from IA_Staff 
 where Entity_id in
 (select Entityid
  from dbo.IA_Staff
  inner join ETOSRVR.etosolaris.dbo.Entities
     on Entities.EntityID = IA_Staff.Entity_Id
 where Entities.Disabled = 0
   and IA_Staff.Disabled = 1)
   and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = IA_Staff.Site_Id
                      and isnull(ex2.tables_to_ignore,'') not like '%IA_STAFF%')

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

print 'End of Process: SP_IA_staff_main'
GO
