USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_LMS_Organizations]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_LMS_Organizations
CREATE PROCEDURE [dbo].[SP_LMS_Organizations]
AS
-- This script controls the Organization Updates to LMS from the Data Warehouse.
-- Will create a cursor to process all Agencies where AuditDate exceeds the Last_LMS_Update.
--
--  References the LMSsrvr.Tracker3 db, CRMSRVr.Nurse_FamilyPartnership_MSCRM db

-- Processing steps:
-- Build Cursor of Agencies
--
-- History:
--    20110124: changed the retrieval of new organizationid after an add.
--    20110126: changed to use the CRM.accountbase.name instead of agency name from ETO.
--    20140103: Added remapping to existing tracker_organizations if no other link exists with DW.Agencies.
--    20160811: Amended to truncate the length of the logged agency name to 100 chars.  
--              Truncation error was occurring when CRM had a name change extending beyond 100 chars.

DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_LMS_ORGANIZATIONS'

DECLARE @insert_count		smallint
DECLARE @update_count		smallint
DECLARE @bypassed_count		smallint
DECLARE @cursor_count		smallint
set @insert_count = 0
set @update_count = 0
set @bypassed_count = 0
set @cursor_count = 0

DECLARE @Entity_ID		int
DECLARE @temp_Entity_ID		int
DECLARE @Site_ID		int
DECLARE @LMS_OrganizationID	int
DECLARE @temp_LMS_OrganizationID	int
DECLARE @CRM_AccountID		uniqueidentifier
DECLARE @AuditDate		datetime
DECLARE @Last_LMS_Update	datetime
DECLARE @AGENCY_INFO_0_NAME     nvarchar(200)
DECLARE @Address1		nvarchar(100)
DECLARE @Address2		nvarchar(100)
DECLARE @City			nvarchar(30)
DECLARE @State			nvarchar(2)
DECLARE @ZipCode		nvarchar(10)
DECLARE @Country		nvarchar(10)
DECLARE @EMail			nvarchar(100)
DECLARE @phone1			nvarchar(20)
DECLARE @website		nvarchar(100)
DECLARE @New_OrganizationID	int

DECLARE @SQL               nvarchar(2000)
DECLARE @bypass_flag       nvarchar(10)
DECLARE @update_CRM_flag   nvarchar(10)
DECLARE @return_id         nvarchar(36)
DECLARE @qualified_ctr     smallint
DECLARE @return_value      nvarchar(50)

SET @return_id = null
SET @qualified_ctr = 0

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
-- Build and process cursor
----------------------------------------------------------------------------------------
print 'Process SP_Update_LMS_Organizations'

DECLARE Agencies_Cursor Cursor FOR 
select Agencies.Entity_ID
      ,Agencies.Site_ID
      ,Agencies.CRM_AccountID
      ,Agencies.LMS_OrganizationID
--      ,Agencies.AGENCY_INFO_0_NAME
      ,crmab.Name
      ,Agencies.Audit_Date
      ,Agencies.Last_LMS_Update
      ,Agencies.Address1
      ,Agencies.Address2
      ,Agencies.City
      ,Agencies.State
      ,Agencies.ZipCode
      ,null as Country
      ,null as email
      ,Agencies.Phone1
      ,Agencies.AGENCY_INFO_1_WEBSITE
 from dbo.Agencies Agencies 
 left join crmsrvr.nurse_familypartnership_mscrm.dbo.accountbase crmab
   on Agencies.CRM_AccountID = crmab.accountID
where Agencies.Audit_Date >= isnull(Agencies.Last_LMS_Update,convert(datetime,'19700101',112))
--  and Agencies.Entity_Disabled = 0
  and Agencies.SIte_Disabled = 0
  and Agencies.CRM_Accountid is not null;


-- Process the Agencies cursor:
--
OPEN Agencies_Cursor
FETCH NEXT FROM Agencies_Cursor
      INTO @Entity_ID
          ,@Site_ID
          ,@CRM_AccountID
          ,@LMS_OrganizationID
          ,@AGENCY_INFO_0_NAME
          ,@AuditDate
          ,@Last_LMS_Update
          ,@Address1
          ,@Address2
          ,@City
          ,@State
          ,@ZipCode
          ,@Country
          ,@email
          ,@Phone1
          ,@Website


WHILE @@FETCH_STATUS = 0
  BEGIN

     set @cursor_count = @cursor_count + 1
     set @update_CRM_Flag = 'N'

/*     print  'Entity=' +convert(varchar,@Entity_ID)
           +', Site_ID=' +convert(varchar,@Site_ID)
           +', CRM_ID=' +convert(varchar,@CRM_ID)
           +', LMS_Organization_ID=' +convert(varchar,@LMS_Organization_ID)
           +', CRM_AccountID=' +convert(varchar,@CRM_AccountID)
           +', AuditDate='+convert(varchar,@AuditDate,101)
           +', Last_LMS_Update='+convert(varchar,@Last_LMS_Update,101)
*/


--   Validation
     set @bypass_flag = 'N'

     IF @LMS_OrganizationID is not null
     -- check for existing Organization in Tracker:
        Set @count = 0
        BEGIN
        select @count = count(*)
          from LMSsrvr.Tracker3.dbo.Tracker_Organizations
         where OrganizationID = @LMS_OrganizationID
        END
        IF @Count = 0
           BEGIN
           -- Org no longer exists in LMS, reset as if new record:
           SET @LMS_OrganizationID = null
           END


     IF @LMS_OrganizationID is null
        BEGIN
           select @LMS_OrganizationID = CRM_AccountExtensionBase.New_LMS_OrgID
             from CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.AccountExtensionBase CRM_AccountExtensionBase
            where CRM_AccountExtensionBase.AccountID = @CRM_AccountID

           IF @LMS_OrganizationID is not null
              set @update_CRM_Flag = 'Y'

        END

     IF @LMS_OrganizationID is null
     BEGIN
--      Verify that Org does not already exist:
        select @count = count(*)
          from LMSsrvr.Tracker3.dbo.Tracker_Organizations
         where Organization = @AGENCY_INFO_0_NAME

        IF @count != 0
        BEGIN
           IF @count = 1
              BEGIN
              -- check to see if it a link already exists with dbo.agencies, if not, re-map to this agency
              select @temp_LMS_OrganizationID = OrganizationID
                from LMSsrvr.Tracker3.dbo.Tracker_Organizations
               where Organization = @AGENCY_INFO_0_NAME

              select @count = count(*)
                from dbo.Agencies
               where LMS_OrganizationID = @temp_LMS_OrganizationID

              IF @count != 0
                 BEGIN
                 -- fail - already mapped to another agency record, report such:
                 set @bypass_flag = 'Y'
                    BEGIN
                    set @temp_Entity_ID = null
                    select @temp_Entity_ID = Entity_ID
                      from dbo.Agencies
                     where LMS_OrganizationID = @temp_LMS_OrganizationID
                    END
                 insert into LMS_Organization_Log
                      (Entity_ID, LogDate, Organization_Name, Action, Status, Comment, OrganizationID)
                      Values (@Entity_ID, getdate(),@AGENCY_INFO_0_NAME, 'ADD', 'FAIL',
                            'Organization Name is already used by entity_ID='+convert(varchar,@temp_entity_ID),null)
                 END
              ELSE
                 BEGIN
                 -- Re-map and set for update: 
                    Set @update_CRM_Flag = 'Y'
                    Set @LMS_OrganizationID = @temp_LMS_OrganizationID 
                    insert into LMS_Organization_Log
                      (Entity_ID, LogDate, Organization_Name, Action, Status, Comment, OrganizationID)
                      Values (@Entity_ID, getdate(),@AGENCY_INFO_0_NAME, 'REMAP', 'SUCCESSFUL',
                            'Re-map Organization to existing LMS_OrganizationID',@LMS_OrganizationID)
                 END
              END
           ELSE
              BEGIN
              -- fail - multiple lms organizations exist for same name:
              set @bypass_flag = 'Y'
              insert into LMS_Organization_Log
                   (Entity_ID, LogDate, Organization_Name, Action, Status, Comment, OrganizationID)
                   Values (@Entity_ID, getdate(),@AGENCY_INFO_0_NAME, 'ADD', 'FAIL',
                         'Cannot re-map, multiple LMS Organization exist for same Name',null)
              END
        END
     END
 
----------------------------------------------------------------------------------------
-- process for new Orgaization in LMS
----------------------------------------------------------------------------------------

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Organizations'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

    IF (@LMS_OrganizationID is null) and (@bypass_flag = 'N')
    BEGIN

       print 'Processing new Organization: '+@AGENCY_INFO_0_NAME +', Organizationid=' +@return_value +';'

--     Build the next available OrganizationID:
--       Select @New_OrganizationID = max(OrganizationID) + 1 from LMSsrvr.tracker3.dbo.Tracker_Organizations

          BEGIN
             insert into LMSsrvr.tracker3.dbo.Tracker_Organizations
                      (Organization
                      ,Address1
                      ,Address2
                      ,City
                      ,State
                      ,ZipCode
                      ,Country
                      ,Telephone1
                      ,Telephone2
                      ,Fax
                      ,Email
                      ,Web)
               values (@AGENCY_INFO_0_NAME
                      ,@Address1
                      ,@Address2
                      ,@City
                      ,@State
                      ,@ZipCode
                      ,@Country
                      ,@Phone1
                      ,null
                      ,null
                      ,@Email
                      ,left(@Website,50));

             set @insert_count = @insert_count + 1
--             set @New_OrganizationID = @@Identity

            select @New_OrganizationID = OrganizationID
               from LMSsrvr.Tracker3.dbo.Tracker_Organizations
              where Organization = @AGENCY_INFO_0_NAME

--        Update the DW record with the new LMS ID:
             Update dbo.Agencies
                set LMS_OrganizationID = @New_OrganizationID
                   ,Last_LMS_Update = getdate()
              where Entity_id = @Entity_ID


--        Update the CRM Account record with the new LMS ID:
             Update CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.AccountExtensionBase 
                set New_LMS_OrgID = @New_OrganizationID
              where AccountID = @CRM_AccountID


             insert into LMS_Organization_Log
                (Entity_ID, LogDate, Organization_Name, Action, Status, Comment, OrganizationID)
                Values (@Entity_ID, getdate(),@AGENCY_INFO_0_NAME, 'ADD', 'SUCCESSFUL',
                      null,@New_OrganizationID)

          END  -- end insert phase


    END -- Process for new Organization

----------------------------------------------------------------------------------------
-- process for existing Orgaization in LMS
----------------------------------------------------------------------------------------

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Organizations'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

    IF @LMS_OrganizationID is not null
       BEGIN

          update LMSsrvr.Tracker3.dbo.Tracker_Organizations
             set Organization = @AGENCY_INFO_0_NAME
                ,Address1 = @Address1
                ,Address2 = @Address2
                ,City = @City
                ,State = @State
                ,ZipCode = @ZipCode
                ,Country = @Country
                ,Telephone1 = @Phone1
                 --,Telephone1 = 
                 --,Fax = 
                 --,Email =
                ,Web = left(@Website,50)
             where OrganizationID = @LMS_OrganizationID;

           set @update_count = @update_count + 1
           --print 'updated LMS Organization_ID: '+convert(varchar,@LMS_OrganizationID)


           IF @update_CRM_flag = 'Y'
              BEGIN

              Update dbo.Agencies
                 set Last_LMS_Update = getdate()
                    ,LMS_OrganizationID = @LMS_OrganizationID
               where Entity_id = @Entity_ID

              Update CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.AccountExtensionBase 
                 set New_LMS_OrgID = @lms_OrganizationID
               where AccountID = @CRM_AccountID

              END
           ELSE
              BEGIN
              Update dbo.Agencies
                 set Last_LMS_Update = getdate()
               where Entity_id = @Entity_ID
              END


           insert into LMS_Organization_Log
              (Entity_ID, LogDate, Organization_Name, Action, Status, Comment, OrganizationID)
               Values (@Entity_ID, getdate(),left(@AGENCY_INFO_0_NAME,100), 'UPDATE', 'SUCCESSFUL',
                       null,@LMS_OrganizationID)

       END

----------------------------------------------------------------------------------------
-- Continue in Cursor
----------------------------------------------------------------------------------------

     FETCH NEXT FROM Agencies_Cursor
      INTO @Entity_ID
          ,@Site_ID
          ,@CRM_AccountID
          ,@LMS_OrganizationID
          ,@AGENCY_INFO_0_NAME
          ,@AuditDate
          ,@Last_LMS_Update
          ,@Address1
          ,@Address2
          ,@City
          ,@State
          ,@ZipCode
          ,@Country
          ,@email
          ,@Phone1
          ,@Website;

  END
CLOSE Agencies_Cursor
DEALLOCATE Agencies_Cursor

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

print 'Agencies Processed:  ' +convert(varchar,@cursor_count)
print 'LMS New Organizations Added: ' +convert(varchar,@insert_count)
print 'LMS Organizations Updated:   ' +convert(varchar,@update_count)
print 'LMS Organizations Bypassed:  ' +convert(varchar,@bypassed_count)
print 'End of Process SP_update_LMS_Organizations'
GO
