USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_Kentico_Synchronize]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_Kentico_Synchronize
--
CREATE PROCEDURE [dbo].[SP_Kentico_Synchronize]
AS
--
-- This script controls the synchronized updates to the Kentico system.
-- 
-- Will sync Kentico CMS_Users to the Systems_Xref table,
-- Will push Name and Email changes to Kentico,
-- Will push the email address to the Kentico Username field.
--
-- History:
--   20140104 - New Procedure.
--   20140228 - Added inclusion of non-eto staff.
--   20140312 - Added update for fullname field.
--   20140320 - Included Datasource_Disabled=0 in qualifier for mapping Kentico to DW, to allow
--              mapping to multiple IA_Staff records in case previous staff recs have been disabled.
--   20160518 - Added validation for CMS_User.UserName (email) changes, that it doesn not already exist in the CMS_User table.
--              If exists, will cause a failure due to unique constraint in CMS_User.UserName field.

DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
DECLARE @runtime 	datetime
set @process = 'SP_Kentico_Synchronize'
set @runtime = getdate()

DECLARE @CMS_UserID	int
DECLARE @CMS_UserName	nvarchar(200)
DECLARE @CMS_FirstName	nvarchar(50)
DECLARE @CMS_LastName	nvarchar(50)
DECLARE @CMS_MiddleName	nvarchar(50)
DECLARE @CMS_FullName	nvarchar(200)
DECLARE @CMS_Email	nvarchar(200)
DECLARE @DW_Entity_ID	int
DECLARE @DW_First_Name	nvarchar(50)
DECLARE @DW_Last_Name	nvarchar(50)
DECLARE @DW_Middle_Name	nvarchar(50)
DECLARE @DW_Full_Name	nvarchar(200)
DECLARE @DW_Email	nvarchar(200)
DECLARE @DW_Datasource  nvarchar(10)
DECLARE @Update_Flag    varchar(1)
DECLARE @UserName_Usage_Count  int

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
print 'Processing SP_Kentico_Synchronize - Inserting Systems_Xref with new IA_Staff'
-- Extraction for Entity:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Inserting Systems_Xref with new IA_Staff'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

insert into dbo.systems_xref 
(entity_id, lms_studentid, CRM_ContactID, last_name, first_name, middle_name, email, site_id,  CRM_AccountID
,datasource, datasource_disabled, NurseID_Agency)
select ia_staff.entity_id, ia_staff.lms_studentid, ia_staff.crm_contactid
      ,ia_staff.last_name, ia_staff.first_name, ia_staff.middle_name, ia_staff.email, ia_staff.site_id
      ,agencies.CRM_AccountID
      ,ISNULL(ia_staff.datasource,'ETO') 
      ,ia_staff.disabled
      ,ia_staff.nurse_0_id_agency
  from dbo.IA_Staff
  left join dbo.Agencies on IA_Staff.Site_ID = agencies.Site_ID
 where not exists (select Entity_ID from dbo.systems_xref xref2
                    where xref2.Entity_ID = IA_Staff.Entity_ID)
   and (IA_Staff.CRM_ContactID is not null or
        nurse_0_id_agency is not null)


----------------------------------------------------------------------------------------
print 'Processing SP_Kentico_Synchronize - Updating Systems_Xref with IA_Staff changes'
-- Extraction for Entity:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Systems_Xref with IA_Staff changes'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------
update dbo.Systems_Xref
   set LMS_StudentID = ia_staff.lms_studentid
      ,CRM_ContactID = ia_staff.crm_contactid
      ,CRM_AccountID = Agencies.CRM_AccountID
      ,Last_Name = ia_staff.last_name
      ,First_Name = ia_staff.first_name
      ,Middle_Name = ia_staff.middle_name
      ,email = ia_staff.email
      ,Site_ID = ia_staff.site_id
      ,Datasource = ISNULL(ia_staff.datasource,'ETO') 
      ,Datasource_disabled = ia_staff.disabled
      ,NurseID_Agency = ia_staff.nurse_0_id_agency
  from dbo.systems_xref xref
  left join dbo.IA_Staff on xref.Entity_ID = IA_Staff.Entity_Id
  left join dbo.Agencies on IA_Staff.Site_ID = agencies.Site_ID
 where xref.Entity_ID is not null
   and (isnull(ia_staff.lms_studentid,99999999) != isnull(xref.LMS_StudentID,99999999) or
        ia_staff.CRM_ContactID != xref.CRM_ContactID or
        ia_staff.Last_Name != xref.Last_Name or
        ia_staff.first_name != xref.First_Name or
        ia_staff.middle_name != xref.Middle_Name or
        ia_staff.email != xref.email or
        ia_staff.site_id != xref.Site_ID or
        ia_staff.Disabled != xref.Datasource_disabled)


   
----------------------------------------------------------------------------------------
print 'Processing SP_Kentico_Synchronize - mapping to Systems_Xref'
-- Extraction for Entity:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'mapping to Systems_Xref'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- map Kentico CMS to IA_Staff via Name and Email:
update systems_xref
   set CMS_UserID = Cuser.UserID
  from dbo.systems_xref xref
  inner join dbo.IA_Staff on xref.Entity_ID = IA_Staff.Entity_ID
  inner join [REM-DB5\SQLNFP_COMM].nursefamilypartnership.dbo.cms_user cuser
     on upper(IA_Staff.last_name) = upper(cuser.LastName) and
        upper(IA_Staff.First_Name) = upper(cuser.FirstName) and
        upper(IA_Staff.Email) = upper(cuser.email)
 where xref.CRM_ContactID is not null
 and IA_Staff.Full_Name not in ('Suzie Ahlers','Maria Martinez','Bear Miller','Kim Miller',
                       'Ann Stager','Joie Pereira','Jay  Stricklin','Jay Stricklin'
                       ,'Mary Beth Wenger', 'Elly Yost','Quen Zorrah')
 and not exists (select xref2.CMS_Userid from dbo.systems_xref xref2
                    where xref2.CMS_Userid = cuser.Userid
                      and xref2.datasource_disabled = 0) 



----------------------------------------------------------------------------------------
print '  Cont: SP_Kentico_Synchronize - Update Names and Email'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Update Names and Email'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------


-- !! log changes to Kentico for Lisa !!

DECLARE UpdatesCursor Cursor for
select cuser.UserID
      ,cuser.UserName
      ,cuser.FirstName
      ,cuser.LastName
      ,cuser.MiddleName
      ,cuser.Fullname
      --,replace(RTRIM(ltrim(cuser.firstname))
      --                +' ' +RTRIM(ltrim(cuser.middlename))
      --                +' ' +RTRIM(ltrim(cuser.lastname)),'  ',' ')
      --          as calculated_fullname
      ,cuser.Email
      ,IA_Staff.Entity_ID
      ,IA_Staff.First_Name
      ,IA_Staff.Last_Name
      ,IA_Staff.Middle_Name
      ,IA_Staff.Full_Name
      ,IA_Staff.Email
      ,IA_Staff.Datasource
  from [REM-DB5\SQLNFP_COMM].nursefamilypartnership.dbo.cms_user cuser
  inner join dbo.Systems_Xref xref on cuser.UserID = xref.CMS_UserID
  inner join dbo.IA_Staff on xref.Entity_ID = IA_Staff.Entity_Id
 where ia_staff.disabled = 0
   -- temporary exclusions per Lisa:
   and cuser.userid not in (4023,3946,1958,1242,932,4002,845)
   and Ia_Staff.Entity_ID not in (9400)  -- Joy Youngblood
   and ( (IA_Staff.Email is not null and 
          cuser.email != IA_Staff.Email) 
       or ((isnull(IA_Staff.datasource,'ETO') != 'LMS') and
            (cuser.firstname != IA_Staff.First_Name or
             cuser.lastname != IA_Staff.Last_Name or
             cuser.middlename != IA_Staff.Middle_Name or
             cuser.fullname != IA_Staff.Full_Name) ) 
       or ((isnull(IA_Staff.datasource,'ETO') = 'LMS') and
           (cuser.firstname != IA_Staff.First_Name or
            cuser.lastname != IA_Staff.Last_Name or
            cuser.fullname != IA_Staff.Full_Name) )
       )

OPEN UpdatesCursor

FETCH next from UpdatesCursor
      into @CMS_UserID
          ,@CMS_UserName
          ,@CMS_FirstName
          ,@CMS_LastName
          ,@CMS_MiddleName
          ,@CMS_FullName
          ,@CMS_Email
          ,@DW_Entity_ID
          ,@DW_First_Name
          ,@DW_Last_Name
          ,@DW_Middle_Name
          ,@DW_Full_Name
          ,@DW_Email
          ,@DW_Datasource


WHILE @@FETCH_STATUS = 0
BEGIN

  set nocount on
  set @Update_Flag = 'N'

-- Log Changes:
   If @CMS_FirstName != @DW_First_Name or
      @CMS_LastName != @DW_Last_Name or
      @CMS_fullName != @DW_Full_Name or
      (@DW_DataSource != 'LMS' and 
       isnull(@CMS_MiddleName,'xyz123') != isnull(@DW_Middle_Name,'xyz123'))
     BEGIN
      set @update_flag = 'Y'
      insert into dbo.Kentico_Updates_log (Entity_ID, CMS_UserID, logdate, Column_Name, Old_Data, New_Data)
         values (@DW_Entity_ID, @CMS_UserID, @Runtime, 'Name: Last,First Middle', 
                 @CMS_LastName +', ' +@CMS_FirstName +' ' +isnull(@CMS_Middlename,'') +'('+@CMS_FullName +')',
                 @DW_Last_Name +', ' +@DW_First_Name +' ' +isnull(@DW_Middle_name,'') +'('+@DW_Full_Name +')' )
     END

   IF @CMS_Email != @DW_Email and 
      @DW_Email is not null
     BEGIN
      set @update_flag = 'Y'
      insert into dbo.Kentico_Updates_log (Entity_ID, CMS_UserID, logdate, Column_Name, Old_Data, New_Data)
         values (@DW_Entity_ID, @CMS_UserID, @Runtime, 'Email', isnull(@CMS_Email,''), @DW_Email)
     END


-- Update Statement:

   IF @update_flag = 'Y' 
     BEGIN
      update [REM-DB5\SQLNFP_COMM].nursefamilypartnership.dbo.cms_user
         set FirstName = @DW_First_Name
            ,LastName = @DW_Last_Name
            ,MiddleName = case when @DW_Datasource != 'LMS' then @DW_Middle_Name
                               else Middlename  END
            ,FullName = @DW_Full_Name
            ,Email = @DW_Email
       where UserId = @CMS_UserID
     END


   FETCH next from UpdatesCursor
      into @CMS_UserID
          ,@CMS_UserName
          ,@CMS_FirstName
          ,@CMS_LastName
          ,@CMS_MiddleName
          ,@CMS_FullName
          ,@CMS_Email
          ,@DW_Entity_ID
          ,@DW_First_Name
          ,@DW_Last_Name
          ,@DW_Middle_Name
          ,@DW_Full_Name
          ,@DW_Email
          ,@DW_Datasource

END -- End of UpdatesCursor loop

CLOSE UpdatesCursor
DEALLOCATE UpdatesCursor



----------------------------------------------------------------------------------------
print '  Cont: SP_Kentico_Synchronize - update Username from email'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'update Username from email'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

DECLARE UpdatesCursor Cursor for
select cuser.UserID
      ,cuser.UserName
      ,cuser.Email
      ,IA_Staff.Entity_ID
      ,(select count(*) 
          from [REM-DB5\SQLNFP_COMM].nursefamilypartnership.dbo.cms_user cuser2
         where cuser2.UserName = cuser.Email) as UserName_Usage_Count
  from [REM-DB5\SQLNFP_COMM].nursefamilypartnership.dbo.cms_user cuser
  left join dbo.Systems_Xref xref on cuser.userid = xref.CMS_UserID
  left join dbo.IA_Staff on xref.Entity_ID = IA_Staff.Entity_Id
 where cuser.Email is not null 
   and cuser.UserName != cuser.Email
   and xref.Entity_ID is not null
   and IA_Staff.Disabled = 0
   --and isnull(IA_Staff.DataSource,'ETO') = 'ETO'


OPEN UpdatesCursor

FETCH next from UpdatesCursor
      into @CMS_UserID
          ,@CMS_UserName
          ,@CMS_Email
          ,@DW_Entity_ID
          ,@UserName_Usage_Count

WHILE @@FETCH_STATUS = 0
BEGIN

  set nocount on

-- Log Changes:
  IF @UserName_Usage_Count = 0
  BEGIN
     BEGIN
      insert into dbo.Kentico_Updates_log (Entity_ID, CMS_UserID, logdate, Column_Name, Old_Data, New_Data)
         values (@DW_Entity_ID, @CMS_UserID, @Runtime, 'UserName', @CMS_UserName, @CMS_Email)
     END

     -- Update Statement:
     IF @UserName_Usage_Count = 0
     BEGIN
         update [REM-DB5\SQLNFP_COMM].nursefamilypartnership.dbo.cms_user
            set UserName = @CMS_Email
          where UserId = @CMS_UserID
     END
   END
   ELSE
   -- log that UserName already exists, don't update CMS:
   BEGIN
      insert into dbo.Kentico_Updates_log (Entity_ID, CMS_UserID, logdate, Column_Name, Old_Data, New_Data)
         values (@DW_Entity_ID, @CMS_UserID, @Runtime, 'UserName - Failed Duplicate', @CMS_UserName, @CMS_Email +' (Already Exists)' )
   END


   FETCH next from UpdatesCursor
      into @CMS_UserID
          ,@CMS_UserName
          ,@CMS_Email
          ,@DW_Entity_ID
          ,@UserName_Usage_Count

END -- End of UpdatesCursor loop

CLOSE UpdatesCursor
DEALLOCATE UpdatesCursor


----------------------------------------------------------------------------------------
-- wrap up
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

print 'End of Process: SP_Kentico_Synchronize'
GO
