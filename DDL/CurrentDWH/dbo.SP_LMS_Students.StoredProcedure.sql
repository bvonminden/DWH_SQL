USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_LMS_Students]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- drop proc dbo.SP_LMS_Students
CREATE procedure [dbo].[SP_LMS_Students]
 (@p_entity_id       int = null)
AS
-- This procedure processes the IA_Staff from the DataWarehouse, to either
-- update existing LMS Student information, or to create new LMS studen,
-- ** New students will be automatically enrolled in preliminary courses.
--
-- ** Will bypass any IA_Staff person who's associated Agency does not have a CRM_AccountID
--    or IA_Staff.NURSE_0_PROGRAM_POSITION is null (IT people

--  References the LMSsrvr.Tracker3 db

-- Steps:
--   Build a cursor of DW IA_Staff persons who do not yet have an LMS_StudentID.
--   Parse cursor, verify if there is not already a match in the LMS by name.
--   If no match found, then insert a new student, call function to enroll in courses.
--
-- History:
--    20110126: Added OrganizationID to Student Update.
--              Added Supervisor name to department field of LMS Students record.
--    20110312: Added comparison of Program Audit_Date to trigger an update due to a 
--              program record change (supervisor changed perhaps).
--    20110405: Added logic to attached new ETO entity to existing Student,
--              disregarding validation on existing UserID
--    20110624: Added validation to check for existing student in LMS, log and bypass if not existing.
--     20111005 - Added column to IA_STAFF.flag_disregard_disabled, to not overwrite LMS Employment Status 
--                during LMS reset.  This allows LMS Student record to remain active even
--                when ETO is disabled.
--    20111025: Changed to use IA_Staff.NURSE_0_PROGRAM_POSITION1 for new role.
--    20111109: Replaced hard coded auto enroll courses with LOV lookup for 'LMS_AUTOENROLL_BY_ROLE'
--    20111111: Added date validation against ia_staff.contacts_audit_date (along with regular audit_date).  
--              This will include any changes for the email address.
--    20111121: Changed validation for existing username on new students.  
--              If LMS student record is not fully assigned to a DW / CRM link, 
--              then try to match upon name.  If matches up, use the current studentid, else fail.
--    20120412: Added qualifier to migrate only IA_STAFF.DataSourse is null.
--              Verified re-mapping based upon username and name match.
--    20120422: Accomodated the re-mapping of new ETO Entity to an existing LMS Student record
--              having a DW IA_Staff ref to a non-ETO Entity.  This will allow ETO to overtake the record.
--    20130829: Changed initial qualification of people to exclude the datasource 'LMS', to accommodate 
--              other datasources besides ETO.
--    20140113: Added update to the Tracker_Student.UserName field, using changed email address.
--              Will log change in the dbo.LMS_UserName_Changed_Log table.
--    20150819: Amended to not process IA_Staff records  when flag_NSO_Transfer is set:
--              Inserts, updates, EmploymentStatus updates.
--    20150901: Changed the LMS EmploymentStatus != IA_Staff.disabled update to process for  
--              all datasources != 'LMS', and to disregard secondary IA_Staff records.
--    20150910: Renamed flag_NSO_Transfer to flag_Transfer to cover all transfer scenarios,
--              to exclude any transfered record from processing further, thus allowing another 
--              IA_Staff record to take precedence.
--    20160330: Added the Identifier3 to the LMS Student record update.  This is to re-establish DW_Entity_ID for remaped staff.
--    20160422: Added logic in the update for last_LMS_updated to replace any null value from a contact_update to use auditdate.

DECLARE @Process	nvarchar(50)
set @process = 'SP_LMS_STUDENTS'


DECLARE @runtime 		datetime
DECLARE @insert_count		smallint
DECLARE @update_count		smallint
DECLARE @bypassed_count		smallint
DECLARE @cursor_count		smallint
set @insert_count = 0
set @update_count = 0
set @bypassed_count = 0
set @cursor_count = 0

DECLARE @Entity_ID	int
DECLARE @Last_Name	nvarchar(50)
DECLARE @First_Name	nvarchar(50)
DECLARE @Middle_Name	nvarchar(50)
DECLARE @Email  	nvarchar(200)
DECLARE @Phone1  	nvarchar(100)
DECLARE @Agency_State  	nvarchar(10)
DECLARE @State  	nvarchar(10)
DECLARE @Entity_Subtype	nvarchar(20)
DECLARE @role		nvarchar(100)
DECLARE @Site_ID	int
DECLARE @LMS_OrganizationID	nvarchar(100)
DECLARE @LMS_StudentID	int
DECLARE @CRM_ContactID	uniqueidentifier
DECLARE @Last_Identity	varchar(36)
DECLARE @suprv_Email 	nvarchar(200)
DECLARE @suprv_name 	nvarchar(100)
DECLARE @New_StudentID	int
DECLARE @UserName  	nvarchar(200)
DECLARE @Password 	nvarchar(50)
DECLARE @Exit		nvarchar(10)
DECLARE @username_ctr	smallint
DECLARE @count		smallint
DECLARE @build_username_as nvarchar(10)
DECLARE @ETO_ClassName	nvarchar(50)
DECLARE @Audit_Date	datetime
DECLARE @Contacts_Audit_Date datetime
DECLARE @disabled	bit
DECLARE @LMS_UserName 	nvarchar(255)

DECLARE @temp_lms_studentid  int
DECLARE @temp_lms_contactid  nvarchar(50)
DECLARE @temp_lms_entityid int
DECLARE @temp_lms_last_name nvarchar(50)
DECLARE @temp_lms_first_name nvarchar(50)
DECLARE @temp_staff_entity_id int
DECLARE @temp_datasource nvarchar(20)

DECLARE @SQL            nvarchar(2000)
DECLARE @bypass_flag    nvarchar(10)
DECLARE @found_match_flag    nvarchar(10)
DECLARE @return_id      int
DECLARE @qualified_ctr  smallint
DECLARE @return_value   nvarchar(50)


set @runtime = getdate()
SET @return_id = null
SET @qualified_ctr = 0

print 'Begin Procedure: SP_LMS_Students'

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
-- Preliminary process to set update flag is supervisor info has changed
----------------------------------------------------------------------------------------
update ia_staff
  set Flag_Update_LMS = 1
where Entity_id in
(select ia_staff.entity_Id
  from dbo.IA_Staff
  inner join LMSsrvr.Tracker3.dbo.Tracker_Students TS
       on TS.StudentID = IA_Staff.LMS_StudentID
  left join dbo.IA_Staff suprstaff
       on dbo.FN_DW_Entity_Supervisor_ID (IA_Staff.Entity_Id) = suprstaff.Entity_Id
 where IA_Staff.LMS_StudentID is not null
   and IA_Staff.Disabled = 0
   and (TS.Identifier8 != suprstaff.email or TS.Department != suprstaff.full_name)
   and IA_Staff.NURSE_0_PROGRAM_POSITION1 IS NOT NULL
   and isnumeric(substring(IA_Staff.Full_Name,1,1)) = 0
   and isnumeric(SUBSTRING(IA_Staff.last_name,1,1)) = 0
   and isnumeric(SUBSTRING(IA_Staff.first_name,1,1)) = 0)
;

----------------------------------------------------------------------------------------
-- Build and process cursor
----------------------------------------------------------------------------------------
DECLARE StaffCursor Cursor for
select IA_Staff.Entity_ID
      ,IA_Staff.Last_Name
      ,IA_Staff.First_Name
      ,IA_Staff.Middle_Name
      ,IA_Staff.EMail
      ,IA_Staff.phone1
      ,IA_Staff.State
      ,IA_Staff.entity_subtype
      ,IA_Staff.nurse_0_program_position1
      ,IA_Staff.Site_ID
      ,Agencies.LMS_OrganizationID
      ,IA_Staff.LMS_StudentID
      ,IA_Staff.CRM_ContactID
      ,Agencies.State
      ,suprstaff.full_name
      ,suprstaff.email
      ,IA_Staff.Audit_Date
      ,IA_Staff.Contacts_Audit_Date
      ,IA_Staff.disabled
  from dbo.IA_Staff
  left join dbo.Agencies
         on IA_Staff.Site_ID = Agencies.Site_Id
  left join dbo.IA_Staff suprstaff
       on dbo.FN_DW_Entity_Supervisor_ID (IA_Staff.Entity_Id) = suprstaff.Entity_Id
 where (IA_Staff.LMS_StudentID is null or
        IA_Staff.Audit_Date > isnull(IA_Staff.Last_LMS_Update,convert(datetime,'19700101',112)) or
        IA_Staff.Contacts_Audit_Date > isnull(IA_Staff.Last_LMS_Update,convert(datetime,'19700101',112)) or
        isnull(IA_Staff.Flag_Update_LMS,0) = 1
        )
   and isnull(IA_Staff.flag_Transfer,0) = 0
   and isnull(IA_Staff.DataSource,'ETO') not in ('LMS')
   and IA_Staff.NURSE_0_PROGRAM_POSITION1 IS NOT NULL
--     dont push unless already matched or setup in CRM:
   and IA_Staff.CRM_ContactID is not null
   and Agencies.Entity_Disabled = 0
   and Agencies.Site_Disabled = 0
   and Agencies.LMS_OrganizationID is not null
   and isnumeric(substring(IA_Staff.Full_Name,1,1)) = 0
   and isnumeric(SUBSTRING(IA_Staff.last_name,1,1)) = 0
   and isnumeric(SUBSTRING(IA_Staff.first_name,1,1)) = 0
-- testing
   and isnull(@p_entity_id,'99999999') in ('99999999',ia_staff.entity_id);

OPEN StaffCursor

FETCH next from StaffCursor
      into @Entity_ID
          ,@Last_Name
          ,@First_Name
          ,@Middle_Name
          ,@Email
          ,@Phone1
          ,@State
          ,@entity_subtype
          ,@role
          ,@Site_ID
          ,@LMS_OrganizationID
          ,@LMS_StudentID
          ,@CRM_ContactID
          ,@Agency_State
          ,@suprv_name
          ,@suprv_email
          ,@Audit_Date
          ,@Contacts_Audit_Date
          ,@disabled

WHILE @@FETCH_STATUS = 0
BEGIN

   set nocount on
   update dbo.process_log 
      set Action = 'Processing IA_Staff'
         ,Phase = null
         ,Comment = null
         ,index_1 = @Entity_ID
         ,index_2 = null
         ,index_3 = null
         ,LogDate = getdate()
    where Process = @process


  set nocount on
  set @cursor_count = @cursor_count + 1
  set @bypass_flag = 'N';
  set @found_match_flag = 'N';
  set @build_username_as = 'email'

--Validations:

-- Validate for missing email - student update:
  IF (@bypass_flag != 'Y') and
     (@LMS_StudentID is not null) and 
     (@email is null)
     BEGIN
        set @bypassed_count = @bypassed_count + 1
        set @bypass_flag = 'Y'
        insert into LMS_Student_Log
           (Entity_ID, LogDate, Name, Action, Status, Comment)
           Values (@Entity_ID, getdate()
                   ,@Last_Name +', ' +@First_Name
                   ,'Update Student','FAILED'
                   ,'Email address may not be blank')
     END


-- Validate for missing OrganizationID:
  IF (@bypass_flag != 'Y') and
     (@LMS_StudentID is null) and 
     (@LMS_OrganizationID is null)
     BEGIN
        set @bypassed_count = @bypassed_count + 1
        set @bypass_flag = 'Y'
        insert into LMS_Student_Log
           (Entity_ID, LogDate, Name, Action, Status, Comment)
           Values (@Entity_ID, getdate()
                   ,@Last_Name +', ' +@First_Name
                   ,'Add Student','FAILED'
                   ,'Data Warehouse LMS_OrgainzationID found to be null for Site: ' +convert(varchar,@Site_ID))
     END

-- Validate for missing email - new student:
  IF (@bypass_flag != 'Y') and
     (@LMS_StudentID is null) and 
     (@email is null)
     BEGIN
        set @bypassed_count = @bypassed_count + 1
        set @bypass_flag = 'Y'
        insert into LMS_Student_Log
           (Entity_ID, LogDate, Name, Action, Status, Comment)
           Values (@Entity_ID, getdate()
                   ,@Last_Name +', ' +@First_Name
                   ,'Add Student','FAILED'
                   ,'Email address is null, required for LMS UserName')
     END

-- Validate new student, check for existing LMS by username:
  IF (@bypass_flag != 'Y') and
     (@LMS_StudentID is null)
     BEGIN
       set @count = 0
       select @count = count(*) from LMSsrvr.Tracker3.dbo.Tracker_Students where UserName = @email
       IF @count > 0
          BEGIN
               -- Retrieve the LMS record and check for a match to the current entity
               -- Bypass if StudentID references an active Entity other than current:
               select @temp_lms_studentid = ts.studentid
                     ,@temp_lms_contactid = ts.identifier0
                     ,@temp_lms_entityid = ts.identifier3
                     ,@temp_lms_last_name = ts.lastname
                     ,@temp_lms_first_name = ts.firstname
                     ,@temp_staff_entity_id = ia_staff.entity_id
                     ,@temp_datasource = ia_staff.datasource
                 from LMSsrvr.Tracker3.dbo.Tracker_Students ts
                 left join dbo.IA_Staff on ts.StudentID = IA_Staff.LMS_StudentID
                where  ts.UserName = @email
                  and isnull(ia_staff.disabled,0) = 0

            IF (@temp_staff_entity_id is not null and
                @temp_datasource is null) or
               (@temp_lms_last_name != @last_name) or
               (@temp_lms_first_name != @first_name) 
               BEGIN
                  set @bypassed_count = @bypassed_count + 1
                  set @bypass_flag = 'Y'
                  insert into LMS_Student_Log
                     (Entity_ID, LogDate, Name, Action, Status, Comment)
                    Values (@Entity_ID, getdate()
                           ,@Last_Name +', ' +@First_Name
                           ,'Add Student','FAILED'
                           ,'Email already exists as LMS UserName, StudentID='+convert(varchar,@temp_lms_studentid))
               END
            ELSE
              -- Consider to be a match, flag for a reset and continue:
              set @found_match_flag = 'Y'

          END  -- existing LMS found, validation for match
     END  -- end new student validation / match on user name 


-- Validate new student, check for existing by last_name, first_name:
  IF (@bypass_flag != 'Y') and
     (@LMS_StudentID is null) and
     (@found_match_flag != 'Y')
--          (converted Staff: the LMS_StudentID should already have been re-established 
--           during the SP_CRM_Contacts process, and would not hit this validation)
     BEGIN
       set @count = 0
       select @count = count(*) from LMSsrvr.Tracker3.dbo.Tracker_Students 
        where upper(LastName) = upper(@Last_Name)
          and upper(FirstName) = upper(@First_Name)
          and upper(email) = upper(@email)

       IF @count = 1
          select @temp_lms_studentid = ts.studentid
                ,@temp_lms_contactid = ts.identifier0
                ,@temp_lms_entityid = ts.identifier3
                ,@temp_lms_last_name = ts.lastname
                ,@temp_lms_first_name = ts.firstname
                ,@temp_staff_entity_id = ia_staff.entity_id
            from LMSsrvr.Tracker3.dbo.Tracker_Students ts
            left join dbo.IA_Staff on ts.StudentID = IA_Staff.LMS_StudentID
           where upper(ts.LastName) = upper(@Last_Name)
             and upper(ts.FirstName) = upper(@First_Name)
             and upper(ts.email) = upper(@email)
             and isnull(ia_staff.disabled,0) = 0

-- temporarily bypass re-map for this case:
       IF @count > 0
               BEGIN
                  set @bypassed_count = @bypassed_count + 1
                  set @bypass_flag = 'Y'
                  insert into LMS_Student_Log
                     (Entity_ID, LogDate, Name, Action, Status, Comment)
               Values (@Entity_ID, getdate()
                       ,@Last_Name +', ' +@First_Name
                       ,'Add Student','FAILED'
                       ,'Validition failed for existing name in LMS (Manually Verify)')
               END

     END -- end new student validation / match on last,first name 

--  When match found then reset and build match:
  IF (@bypass_flag != 'Y') and
     (@found_match_flag = 'Y') and
     (@LMS_StudentID is null)
     BEGIN
       -- reset CRM
       IF (@temp_lms_contactid is not null) and
          (@temp_lms_contactid != @CRM_ContactID)
          BEGIN
            update CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase
               set new_lms_studentid = null
             where contactid = @temp_lms_ContactID

            update CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase
              set new_lms_studentid = @temp_lms_studentid
             where contactid = @CRM_ContactID
          END

       -- reset XREF
       IF (@temp_lms_entityid is not null) and
          (@temp_lms_entityid != @Entity_ID)
          BEGIN
            -- dissassociate old xref:
            update dbo.ETO_CRM_LMS_xref
               set LMS_StudentID = null
             where Entity_ID = @temp_lms_entityid
          END

          -- associate to correct xref if found:
          update dbo.ETO_CRM_LMS_xref
             set LMS_StudentID = @temp_lms_studentid
           where Entity_ID = @Entity_ID

       -- reset LMS
       BEGIN
         update LMSsrvr.Tracker3.dbo.Tracker_Students
            set identifier0 = @CRM_ContactID
               ,identifier3 = @Entity_ID
          where StudentID = @temp_lms_studentid
       END

       -- Update IA_Staff record
       BEGIN
         update dbo.IA_Staff
            set LMS_StudentID = @temp_lms_studentid
               ,DataSource = null
          where Entity_id = @Entity_ID
       END

       -- Add log record for re-match:
       insert into LMS_Student_Log
                 (Entity_ID, LogDate, Name, Action, Status, Comment)
          Values (@Entity_ID, getdate()
                  ,@Last_Name +', ' +@First_Name
                  ,'Add Student','REMAPPED'
                  ,'Found existing student, able to remap to ETO Entity')

       -- finalize re-mapping, so that an LMS update can occur:
       set @LMS_StudentID = @temp_lms_studentid

       -- remove non-ETO xref:
       IF @temp_datasource is not null and
          @temp_staff_entity_id is not null
       BEGIN
         delete from dbo.Non_ETO_Entity_Xref
          where Entity_ID = @temp_staff_entity_id
       END

    END  -- reset and match
   
    -- check to see if LMS_StudentID still exists:
   
    IF (@LMS_StudentID is null) and (@disabled = 1) and (@bypass_flag = 'N') 
       -- force bypass because ETO Entity is disabled
       set @bypass_flag = 'Y'

----------------------------------------------------------------------------------------
-- process for new student
----------------------------------------------------------------------------------------

    IF (@LMS_StudentID is null) and (@bypass_flag = 'N')
    BEGIN

      set nocount on
      update dbo.process_log 
         set Phase = 'New Student'
            ,LogDate = getdate()
            ,comment = +@Last_Name +', ' +@First_Name
       where Process = @process

--     Verify that student does not already exist:
       EXEC @return_value = dbo.SP_LMS_Student_Lookup_by_Name @Last_Name,@First_Name,
                       @Middle_Name,@LMS_OrganizationID,@Email
 
--       print 'Processing new Student: '+@Last_Name +', ' +@First_Name +', Studentid=' +@return_value +';'


--     Build the next available StudentID:
       Select @New_StudentID = max(StudentID) + 1 from LMSsrvr.Tracker3.dbo.Tracker_Students

       IF @build_username_as = 'email'
          set @username = @email

/*
--     **Username currently being built as the student's email address. 
--       This section left in the code, should ever the firstname, lastname be used again:
       IF @build_username_as = 'name'
       BEGIN
--        Build UserName:
          set @exit = null
          set @username_ctr = 0
          while @exit is null
          BEGIN
             
             IF @username_ctr = 0
                set @UserName = substring(@First_Name,1,1) +@Last_Name
             IF @username_ctr = 1
                set @UserName = substring(@First_Name,1,1) +isnull(substring(@Middle_Name,1,1),'') +@Last_Name
             IF @username_ctr > 1
                set @UserName = substring(@First_Name,1,1) +@Last_Name +convert(varchar,@username_ctr)

             set @username = LOWER(@username)

             select @count = count(*) from LMSsrvr.Tracker3.dbo.Tracker_Students where UserName = @UserName
             IF @count = 0
               set @exit = 'x'
             
             set @username_ctr = @username_ctr + 1
          END
       END
*/

       -- Special LMS encryption for 'Welcome2NFP'
       set @Password = 'f5zxqvWX3012w/SvTmM/ZQ=='

       IF @return_value = 0
          BEGIN
            
             insert into LMSsrvr.Tracker3.dbo.Tracker_Students
                      (UserName
                      ,Password
                      ,LastName
                      ,FirstName
                      ,MiddleInitial
                      ,OrganizationID
                      ,Department
                      ,TelephoneNumber
                      ,Email
                      ,FaxNumber
                      ,Telephone2
                      ,Cellphone
                      ,Pager
                      ,Identifier0
                      ,Identifier1
                      ,Identifier2
                      ,Identifier3
                      ,Identifier4
                      ,Identifier5
                      ,Identifier6
                      ,Identifier7
                      ,Identifier8
                      ,Identifier9
                      ,DateIdentifier
                      ,Administrator
                      ,Reporter
                      ,EmploymentStatus)
               values (@UserName
                      ,@Password
                      ,@Last_Name
                      ,@First_Name
                      ,substring(@Middle_Name,1,1)
                      ,@LMS_OrganizationID
                      ,@suprv_name
                      ,@Phone1
                      ,@Email
                      ,null  -- FaxNumber
                      ,null  -- Telephone2
                      ,null  -- Cellphone
                      ,null  -- Pager
                      ,convert(varchar(36),@CRM_ContactID) -- Identifier0 (CRM ContactID)
                      ,null  -- Identifier1
                      ,coalesce(@State,@agency_State)  -- Identifier2 (State Worked)
                      ,@Entity_ID                      -- Identifier3  (ETO Entity_ID)
                      ,null  -- Identifier4
                      ,null  -- Identifier5 (Reason for Education)
                      ,null  -- Identifier6
                      ,@role                           -- Identifier7 (Primary Contact Type)
                      ,@suprv_email                    -- Identifier8 (Supervisor Email)
                      ,null  -- Identifier9
                      ,null  -- getdate()
                      ,0
                      ,0
                      ,0);

            -- set @New_StudentID = @@Identity
            select @New_StudentID = studentid
               from LMSsrvr.Tracker3.dbo.Tracker_Students
              where UserName = @UserName

            set nocount on
            update dbo.process_log 
               set Phase = 'New Student - insert success, Ent=' +convert(varchar,@Entity_ID)
                  ,LogDate = getdate()
                  ,Index_2 = @New_StudentID
             where Process = @process

--           Update the DW record with the new LMS Student ID:
             Update dbo.IA_Staff
                set LMS_StudentID = @New_StudentID
                   ,Last_LMS_UPdate = convert(datetime,dbo.FN_GREATEST(@Audit_Date,isnull(@Contacts_Audit_Date,@Audit_Date)),120)
                   ,Flag_Update_LMS = 0
              where Entity_id = @Entity_ID

             Update dbo.ETO_CRM_LMS_xref
                set LMS_StudentID = @New_StudentID
              where Entity_id = @Entity_ID

             Update CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase
                set new_lms_studentid = @New_StudentID
              where contactid = @CRM_ContactID

             insert into LMS_Student_Log
                (Entity_ID, LogDate, Name, Action, Status, Comment, StudentID, UserNAme, Password)
               Values (@Entity_ID, getdate()
                       ,@Last_Name +', ' +@First_Name
                       ,'Add Student','SUCCESSFUL'
                       ,'New Student Added to LMS',@New_StudentID,@UserName,@Password)

             set @insert_count = @insert_count + 1


      set nocount on
      update dbo.process_log 
         set Phase = 'New Student - Auto enroll class'
            ,LogDate = getdate()
            ,Index_2 = @New_StudentID
       where Process = @process

--    Enroll new student into the ETO Course:

--    Nurse_0_Program_Position1 field:
--      State Nurse Consultant
--      NFP Partner
--      Administrator
--      Data Entry / Administrative
--      Nurse Home Visitor
--      Other
--      Supervisor

            set @ETO_ClassName = null
            BEGIN
               select @ETO_ClassName = lv.value
                 from dbo.LOV_names ln
                inner join dbo.LOV_Values lv on ln.LOV_Name_ID = lv.LOV_Name_ID
                where ln.Name = 'LMS_AUTOENROLL_BY_ROLE'
                  and lv.LOV_Item = @Role
            END
      
            IF @ETO_ClassNAme is not null
               exec SP_LMS_Class_Registration @Entity_ID, @New_StudentID, @ETO_ClassName, 'NewHire','CLASSNAME'
            ELSE
               BEGIN
               insert into LMS_Student_Log
                  (Entity_ID, LogDate, Name, Action, Status, Comment)
                   Values (@Entity_ID, getdate()
                          ,@Last_Name +', ' +@First_Name
                          ,'New Student Enrollment','WARNING'
                          ,'Could not assign Automatic ClassReg, Role= ' + isnull(@role,''))
               END

          END -- end insert new student phase

       ELSE
          BEGIN

             set @bypassed_count = @bypassed_count + 1

             insert into LMS_Student_Log
                (Entity_ID, LogDate, Name, Action, Status, Comment)
                Values (@Entity_ID, getdate()
                       ,@Last_Name +', ' +@First_Name
                       ,'Add Student','FAILED'
                       ,'Missing DW LMS_StudentID, Student ID already exists as: ' + @return_value)

       END  -- Check for OK to add new student


    END -- Process for new student

----------------------------------------------------------------------------------------
-- process LMS update
----------------------------------------------------------------------------------------

    IF (@LMS_StudentID is not null) and (@bypass_flag = 'N')
    BEGIN

      set nocount on
      update dbo.process_log 
         set Phase = 'Student Update'
            ,LogDate = getdate()
            ,Index_2 = @LMS_StudentID
       where Process = @process

       
       update LMSsrvr.Tracker3.dbo.Tracker_Students
          set LastName = @Last_Name
             ,FirstName = @First_Name
             ,MiddleInitial= substring(@Middle_Name,1,1)
             ,TelephoneNumber = @Phone1
             ,Email = @Email
             ,Identifier2 = coalesce(@State,@agency_State)
             ,Identifier3 = @Entity_ID
             ,Identifier7 = @role
             ,Identifier8 = @suprv_email
             ,OrganizationID = @LMS_OrganizationID
             --,UserName
             ,Department = @suprv_name
        where StudentID = @LMS_StudentID;

       set @update_count = @update_count + 1
     print 'updated LMS Student_ID: '+convert(varchar,@LMS_StudentID) +', Entity_ID: ' +convert(varchar,@Entity_ID)

       Update dbo.IA_Staff
          set Last_LMS_Update = convert(datetime,dbo.FN_GREATEST(@Audit_Date,isnull(@Contacts_Audit_Date,@Audit_Date)),120)
             ,Flag_Update_LMS = 0
        where Entity_id = @Entity_ID


--     Contine - Check for change to UserName via Email
       BEGIN
          select @LMS_UserName = UserName
            from LMSsrvr.Tracker3.dbo.Tracker_Students
           where StudentID = @LMS_StudentID;
       END

       IF @LMS_UserName != @Email
       BEGIN
          -- log and update for UserName Change:
          insert into dbo.LMS_UserName_Changed_Log (StudentID, Entity_ID, LogDate, Old_UserName, New_UserName)
                 values (@LMS_StudentID, @Entity_ID, @runtime, @Lms_UserName, @Email)

          update LMSsrvr.Tracker3.dbo.Tracker_Students 
             set Username = @Email
           where StudentID = @LMS_StudentID;

       END

    END
----------------------------------------------------------------------------------------
-- continue in cursor
----------------------------------------------------------------------------------------

   FETCH next from StaffCursor
         into @Entity_ID
             ,@Last_Name
             ,@First_Name
             ,@Middle_Name
             ,@Email
             ,@Phone1
             ,@State
             ,@entity_subtype
             ,@role
             ,@Site_ID
             ,@LMS_OrganizationID
             ,@LMS_StudentID
             ,@CRM_ContactID
             ,@Agency_State
             ,@suprv_name
             ,@suprv_email
             ,@Audit_Date
             ,@Contacts_Audit_Date
             ,@disabled

END -- End of StaffCursor loop

CLOSE StaffCursor
DEALLOCATE StaffCursor

set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process


print 'IA_Staff Members Processed: ' +convert(varchar,@cursor_count)
print 'LMS New Students Added:     ' +convert(varchar,@insert_count)
print 'LMS Students Updated:       ' +convert(varchar,@update_count)
print 'LMS Bypassed Msgs:          ' +convert(varchar,@bypassed_count)


----------------------------------------------------------------------------------------
-- Update Student EmploymentStatus based upon ETO Disable flag
----------------------------------------------------------------------------------------

print 'Updating Employment Status changes'
set nocount off
update LMSsrvr.Tracker3.dbo.tracker_students
   set EmploymentStatus = CASE when ia_staff.disabled = 0 then 0 else 1 END
  from LMSsrvr.Tracker3.dbo.tracker_students students
 inner join dbo.ia_staff
     on ia_staff.LMS_StudentID = students.StudentID
 where isnull(ia_staff.flag_Transfer,0) = 0
   and ia_staff.disabled != isnull(students.employmentstatus,0)
   and ia_staff.CRM_ContactID is not null
   and isnull(ia_staff.DataSource,'ETO') != 'LMS'
   and isnull(IA_Staff.flag_disregard_disabled,0) = 0


PRINT 'End of Procedure: SP_LMS_Students'
GO
