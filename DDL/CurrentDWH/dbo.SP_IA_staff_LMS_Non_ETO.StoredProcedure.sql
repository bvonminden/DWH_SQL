USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_IA_staff_LMS_Non_ETO]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_IA_staff_LMS_Non_ETO
--
CREATE PROCEDURE [dbo].[SP_IA_staff_LMS_Non_ETO]
AS
--
-- This script controls updates to the IA_Staff table in the Data Warehouse.
-- Processing for Non-ETO Entities which come from LMS.
--
-- Table effected - dbo.IA_Staff
--
-- Insert: select and insert when ETO IA_Staff entity is found to be missing in the DW.
-- Update: select and update when ETO IA_Staff entity exists in DW and has been changed in LMS.
--
-- History:
--   20120120 - New Program
--   20120531 - Accommodate LMS employment_status of 2 for disabled
--   20120924 - Changed SSIS package seq from 116 to 162, to run after 80-staff, 140-contacts, 160-lms students
--   20131001 - Added linking of pre-existing CRM records to the non-ETO IA_Staff record.
--              Changed the population IA_Staff.Phone1 to use Tracker_Students.TelephoneNumber
--                (was originally using Telephone2).
--   20140313 - Changed the formatting of Full_Name to eliminate double spaces for blank middle initial.
--   20140624 - Added additional ways to trigger a link to an existing CRM record to an existing LMS/DW connection.
--              Along with the name/email match, will force if LMS supplies the CRM ContactID.
--   20140910 - Fixed full name to accommodate null values.
--   20150207 - Added site_id to the initial Non_ETO_Entity_Xref record, to help marry-up from agencydb integration.
--   20150901 - Added the creation of non-eto staff records for active students who may be mapped to an existing
--              disabled IA_Staff record, which has been flagged as flag_NSO_Tranfer = 1.
--              Only create if LMS EmploymentStatus = 0.
--   20150910 - Renamed flag_NSO_Transfer to flag_Transfer to cover all transfer scenarios,
--              to exclude any transfered record from processing further, thus allowing another 
--              IA_Staff record to take precedence.


DECLARE @RunAuditDate   datetime
DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_IA_STAFF_LMS_Non_ETO'
set @RunAuditDate = getdate()

DECLARE @CRM_coursedate_cutover	datetime
set @CRM_coursedate_cutover = convert(datetime,'20101013',112)

DECLARE @Entity_ID		int
DECLARE @last_Name		nvarchar(50)
DECLARE @First_Name		nvarchar(50)
DECLARE @Middle_Name		nvarchar(50)
DECLARE @LMS_StudentID		int
DECLARE @Site_ID		int
DECLARE @Lookup_ContactID	uniqueidentifier
DECLARE @LMS_CRM_ContactID	uniqueidentifier
DECLARE @Email			nvarchar(50)
DECLARE @bypass_flag		nvarchar(10)
DECLARE @xref_Entity_ID		int
DECLARE @xref_LMS_StudentID	int
DECLARE @xref_CRM_ContactID	uniqueidentifier

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
print 'Processing SP_IA_staff_Non_ETO_LMS - Insert new staff members'
-- Extraction for Entity:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Staff'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- Create an XREF record for Entity_ID / Student_ID:
insert into dbo.Non_ETO_Entity_Xref
       (Non_ETO_ID, Source, Non_ETO_Site_ID)
select ts.StudentID,'LMS', Agencies.Site_ID
  from LMSsrvr.Tracker3.dbo.Tracker_Students ts
  left join dbo.Agencies on ts.OrganizationID = Agencies.LMS_OrganizationID
 where isnull(ts.EmploymentStatus,0) = 0
   -- a primary staff record does not exist based upon studentid:
   and not exists (select Entity_ID
                     from dbo.IA_Staff
                    where IA_Staff.LMS_StudentId = ts.StudentID
                       and IA_Staff.CRM_ContactId is not null
                       and isnull(IA_Staff.flag_Transfer,0) = 0)
   -- a primary staff record does not exist based upon crm_contactid:
   and not exists (select Entity_ID
                     from dbo.IA_Staff
                    where convert(varchar(36),IA_Staff.CRM_ContactId) = ts.identifier0
                       and isnull(IA_Staff.flag_Transfer,0) = 0)
   -- already exists as a non-eto entity coming from LMS:
   and not exists (select Entity_ID
                     from dbo.Non_ETO_Entity_Xref xref
                    where xref.Non_ETO_ID = ts.StudentID
                      and xref.source = 'LMS')

-- ** note: only imports if StudentID and ContactID does not exist in IA_Staff

-- Basic IA_Staff info:
insert into dbo.IA_Staff
      (Entity_ID
      ,DataSource
      ,LMS_StudentID
      ,CRM_ContactID
      ,Site_ID
      ,Full_Name
      ,Last_Name
      ,First_Name
      ,Middle_Name
      ,Email
      ,Phone1
      ,nurse_0_program_position1
      ,Date_Created
      ,Audit_Date
      ,Disabled)
select xref.Entity_ID
      ,'LMS' as DataSource
      ,ts.StudentID
      ,cb.ContactID
      ,Agencies.Site_ID
      --,ts.FirstName +' ' +isnull(ts.MiddleInitial,'') +' ' +ts.LastName as full_name
      ,replace(RTRIM(ltrim(isnull(ts.FirstName,'')))
                      +' ' +RTRIM(ltrim(isnull(ts.MiddleInitial,'')))
                      +' ' +RTRIM(ltrim(isnull(ts.LastName,''))),'  ',' ')
                as full_name
      ,ts.LastName
      ,ts.FirstName
      ,ts.MiddleInitial
      ,ts.email
      ,ts.telephoneNumber
      ,ts.identifier7 as role
      ,@RunAuditDate  --GETDATE()
      ,@RunAuditDate  --GETDATE()
      ,ts.EmploymentStatus
  from LMSsrvr.Tracker3.dbo.Tracker_Students ts
  inner join dbo.Non_ETO_Entity_Xref xref on ts.StudentID = xref.Non_ETO_ID
  left join CRMSrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactBase cb 
        on ts.identifier0 = convert(varchar(36),cb.contactid)
  left join dbo.Agencies on ts.OrganizationID = Agencies.LMS_OrganizationID
 where xref.source = 'LMS'
   and isnull(ts.EmploymentStatus,0) = 0
   -- a primary staff record does not exist for new non-eto entity_id:
   and not exists (select Entity_ID
                     from dbo.IA_Staff
                    where IA_Staff.Entity_Id = xref.Entity_ID)
   -- a primary staff record does not exist based upon studentid:
   and not exists (select Entity_ID
                     from dbo.IA_Staff
                    where IA_Staff.LMS_StudentId = ts.StudentID
                       and IA_Staff.CRM_ContactId is not null
                      and isnull(IA_Staff.flag_Transfer,0) = 0)
   -- a primary staff record does not exist based upon crm_contactid:
   and not exists (select Entity_ID
                     from dbo.IA_Staff
                    where convert(varchar(36),IA_Staff.CRM_ContactId) = ts.identifier0
                      and isnull(IA_Staff.flag_Transfer,0) = 0)


-- Update the Student Record with the newly inserted Entity_ID:
update LMSsrvr.Tracker3.dbo.Tracker_Students
  set identifier3 = xref.Entity_ID
 from LMSsrvr.Tracker3.dbo.Tracker_Students ts
 inner join dbo.Non_ETO_Entity_Xref xref  on ts.studentid = xref.Non_ETO_ID
 where xref.Source = 'LMS'
   and identifier3 is null

----------------------------------------------------------------------------------------
-- Updated IA_Staff for changes
----------------------------------------------------------------------------------------

/*
-- select comparison for manual validation:
select IA_Staff.Entity_ID
      ,ts.identifier3
      ,IA_Staff.LMS_StudentID
      ,IA_Staff.CRM_ContactID
      ,ts.identifier0
      ,IA_Staff.Last_Name
      ,ts.LastName
      ,IA_Staff.First_Name
      ,ts.FirstName
      ,IA_Staff.Middle_Name
      ,ts.MiddleInitial
      ,IA_Staff.Email
      ,ts.Email
      ,IA_Staff.Phone1
      ,ts.telephoneNumber
      ,IA_Staff.nurse_0_program_position1
      ,ts.identifier7
      ,IA_Staff.Site_ID
      ,Agencies.Site_ID
      ,Agencies.Entity_ID as Agency_Entity_ID
      ,Agencies.CRM_AccountID
      ,Agencies.LMS_OrganizationID
      ,ts.OrganizationID
      ,IA_Staff.Audit_Date
      ,IA_Staff.Disabled
      ,ts.EmploymentStatus
*/

update IA_Staff
   set IA_Staff.Last_Name = ts.LastName
      ,IA_Staff.First_Name = ts.FirstName
      ,IA_Staff.Middle_Name = ts.MiddleInitial
      ,IA_Staff.Email = ts.Email
      ,IA_Staff.Phone1 = ts.telephoneNumber
      ,IA_Staff.nurse_0_program_position1 = ts.identifier7
      ,IA_Staff.Site_ID = Agencies.Site_ID
      ,IA_Staff.Disabled = ts.EmploymentStatus
      ,IA_Staff.Audit_Date = @RunAuditDate
      ,IA_Staff.Full_Name = replace(RTRIM(ltrim(isnull(ts.FirstName,'')))
                      +' ' +RTRIM(ltrim(isnull(ts.MiddleInitial,'')))
                      +' ' +RTRIM(ltrim(isnull(ts.LastName,''))),'  ',' ')
  from dbo.IA_Staff
  left join dbo.Non_ETO_Entity_Xref xref  on IA_Staff.Entity_ID = xref.Entity_ID
  left join LMSsrvr.Tracker3.dbo.Tracker_Students ts  on IA_Staff.LMS_StudentID = ts.StudentID
  left join dbo.Agencies on ts.OrganizationID = Agencies.LMS_OrganizationID
 where xref.Source = 'LMS'
   and ts.Identifier3 = IA_Staff.Entity_ID
   and (isnull(IA_Staff.Last_Name,'xxxxx') != isnull(ts.LastName,'xxxxx')
        or isnull(IA_Staff.First_name,'xxxxx') != isnull(ts.FirstName,'xxxxx')
        or isnull(IA_Staff.Middle_Name,'xxxxx') != isnull(ts.MiddleInitial,'xxxxx')
        or isnull(IA_Staff.Email,'xxxxx') != isnull(ts.email,'xxxxx')
        or isnull(IA_Staff.phone1,'xxxxx') != isnull(ts.telephonenumber,'xxxxx') 
        or isnull(IA_Staff.NURSE_0_PROGRAM_POSITION1,'xxxxx') != isnull(ts.identifier7,'xxxxx') 
        or isnull(IA_Staff.Site_ID,989898) != isnull(Agencies.Site_ID,989898) 
        or isnull(IA_Staff.Disabled,0) != (CASE when isnull(ts.EmploymentStatus,0) = 0 then 0 else 1 END)
       )

----------------------------------------------------------------------------------------
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Migrating LMS Completed Courses'
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
         inner join dbo.Non_ETO_Entity_Xref xref on IA_Staff.Entity_ID = xref.Entity_ID
         inner join dbo.crm_completed_courses CCC
                 on IA_Staff.CRM_ContactID = CCC.ContactID
        where IA_Staff.CRM_ContactID is not null
          and CCC.Completion_Date < @CRM_coursedate_cutover
          and (select count(*)
                 from dbo.DW_Completed_Courses DWCC
                where DWCC.ContactID = CCC.ContactID
                 and DWCC.CRM_Course_Nbr = CCC.Course_Nbr) = 0;



----------------------------------------------------------------------------------------
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Linking pre-existing CRM Contacts'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

DECLARE LMSCRM_Cursor Cursor for
select IA_Staff.Entity_Id
      ,IA_Staff.Last_Name
      ,IA_Staff.First_Name
      ,IA_Staff.Middle_Name
      ,IA_Staff.LMS_StudentID
      ,IA_Staff.Email
      ,IA_Staff.Site_ID
      ,dbo.FN_CRM_Contact_Lookup_by_name (ia_staff.last_name,ia_staff.first_name,null,null,IA_Staff.email) as crmid
      ,cb.Contactid as LMS_CRM_ContactID
  from dbo.IA_Staff 
  inner join LMSsrvr.Tracker3.dbo.Tracker_Students ts  on IA_Staff.LMS_StudentID = ts.StudentID
  left join CRMSrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactBase cb
        on ts.identifier0 = convert(varchar(36),cb.contactid)
 where IA_Staff.DataSource = 'LMS'
   and IA_Staff.CRM_ContactId is null
   and IA_Staff.disabled = 0
   and (dbo.FN_CRM_Contact_Lookup_by_name (ia_staff.last_name,ia_staff.first_name,ia_staff.middle_name,null,IA_Staff.email) is not null
        or cb.ContactID is not null)

OPEN LMSCRM_Cursor

FETCH next from LMSCRM_CURSOR
      into @Entity_ID
          ,@Last_Name
          ,@First_Name
          ,@Middle_Name
          ,@LMS_StudentID
          ,@Email
          ,@Site_ID
          ,@Lookup_ContactID
          ,@LMS_CRM_ContactID

WHILE @@FETCH_STATUS = 0
BEGIN

   set @bypass_flag = 'N'

   IF (@Lookup_ContactID = 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF' and
       @LMS_CRM_ContactID is not null) or
      (@Lookup_ContactID is null and @LMS_CRM_ContactID is not null)
      set @Lookup_ContactID = @LMS_CRM_ContactID

   IF @Lookup_ContactID = 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF'
       BEGIN
          SET @bypass_flag = 'Y'
          insert into CRM_Contacts_Log
                (Entity_ID, LogDate, Last_Name, First_Name, Middle_Name, Email, Action, Status, Comment)
                Values (@Entity_ID, getdate()
                       ,@Last_Name, @First_Name, @Middle_Name, @Email
                       ,'Non-ETO Staff','FAILED'
                       ,'Cannot process: multiple name matches for CRM Contacts')
       END    

   ELSE
-- look for existing xref record
   BEGIN
       set @xref_Entity_ID = null
       set @xref_CRM_ContactID = null
       set @xref_LMS_StudentID = null
       select @xref_Entity_ID = Entity_ID
             ,@xref_CRM_ContactID = CRM_ContactID
             ,@xref_LMS_StudentID = LMS_StudentID
         from dbo.ETO_CRM_LMS_xref
        where CRM_COntactID = @lookup_ContactID;

       IF @xref_Entity_ID is null 
          BEGIN
             insert into CRM_Contacts_Log
                 (Entity_ID, LogDate, Last_Name, First_Name, Middle_Name, Email
                  ,CRM_ContactID, Action, Status, Comment)
                  Values (@Entity_ID, getdate()
                         ,@Last_Name, @First_Name, @Middle_Name, @Email, @Lookup_ContactID
                         ,'Non-ETO Staff','MAPPED_TO_OLD_CRM'
                         ,'LMS Student mapped to existing CRM Contact: ' +convert(varchar(36),@xref_CRM_ContactID))
          END         
       ELSE IF @xref_Entity_ID != @Entity_ID
          -- Verify that the found entity_id actually exists in DW (may have been deleted)
          BEGIN
          select @count = count(*) from dbo.IA_Staff 
           where Entity_ID = @xref_Entity_ID
             and disabled = 0
          IF @count = 0 
             BEGIN
                insert into CRM_Contacts_Log
                   (Entity_ID, LogDate, Last_Name, First_Name, Middle_Name, Email
                    ,CRM_ContactID, Action, Status, Comment)
                   Values (@Entity_ID, getdate()
                          ,@Last_Name, @First_Name, @Middle_Name, @Email, @Lookup_ContactID
                          ,'Non-ETO Staff','REMAPPED'
                          ,'LMS Student re-mapped from disabled Entity_ID: ' +convert(varchar,@xref_Entity_ID))
             END
          ELSE
             BEGIN
                SET @bypass_flag = 'Y'
                insert into CRM_Contacts_Log
                      (Entity_ID, LogDate, Last_Name, First_Name, Middle_Name, Email
                       ,CRM_ContactID, Action, Status, Comment)
                      Values (@Entity_ID, getdate()
                             ,@Last_Name, @First_Name, @Middle_Name, @Email, @Lookup_ContactID
                             ,'Non-ETO Staff','FAILED'
                             ,'LMS Student name match already assigned to Entity_ID: ' +convert(varchar,@xref_Entity_ID))
             END 
          END  
   END  /* validate for pre-existing ETO_CRM_LMS_xref entries */


   IF @bypass_flag != 'Y'
      BEGIN
         update IA_Staff
            set CRM_ContactID = @Lookup_ContactID
          where Entity_ID = @Entity_ID

         update LMSsrvr.Tracker3.dbo.Tracker_Students
            set Identifier0 = @Lookup_ContactID
          where StudentID = @LMS_StudentID

         IF @xref_CRM_ContactID is null
            BEGIN
               insert into dbo.ETO_CRM_LMS_xref (Entity_ID, Site_ID, LMS_StudentID, CRM_ContactID) 
                  values (@Entity_ID, @Site_ID, @LMS_StudentID, @Lookup_ContactID)
            END
         ELSE
            BEGIN
               update dbo.ETO_CRM_LMS_xref
                  set entity_id = @Entity_ID
                     ,LMS_StudentID = @LMS_StudentID
                where CRM_ContactID = @Lookup_ContactID
            END
      END

   FETCH next from LMSCRM_CURSOR
         into @Entity_ID
             ,@Last_Name
             ,@First_Name
             ,@Middle_Name
             ,@LMS_StudentID
             ,@Email
             ,@Site_ID
             ,@Lookup_ContactID
             ,@LMS_CRM_ContactID

END  /* End of LMSCRM_Cursor loop */

CLOSE LMSCRM_Cursor
DEALLOCATE LMSCRM_Cursor


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

print 'End of Process: SP_IA_staff_LMS_Non_ETO'
GO
