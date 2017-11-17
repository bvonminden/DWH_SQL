USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_CRM_Contacts]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop procedure dbo.sp_crm_contacts

CREATE procedure [dbo].[SP_CRM_Contacts]
 (@p_entity_id       int = null)
AS
-- This procedure processes the IA_Staff from the DataWarehouse, to either
-- update existing CRM Contacts information, or to create new CRM Contact

-- ** Will bypass any IA_Staff person who's name is numeric (CIS History),
--    or any IA_Staff who's associated Agency does not have a CRM_AccountID
--    or IA_Staff.NURSE_0_PROGRAM_POSITION is null (IT people)
--
-- ** Special process for go-live load:
--    Match on EMAIL only.  IF not matched, don't push to CRM
--    Trigger is p_entity_id = 99999998  (seven 9s and one 8)
--
-- 3 step process
--   - Processes DW IA_Staff persons who do not yet have a CRM_ContactID or 
--     have been modified since last processing (AuditDate > Last_CRM_Update).
--   - Process Staff Update Survey that have not yet been applied (mapped_entity_id is null).
--   - Process Program (Team) changes that have been done since Last_CRM_Team_Update.
--
--  History: 20101213 - Added validation that the IA_Staff.CRM_ContactID still exists.
--                      IF not, it will consider the Staff record as new and proceed with re-matching.
--                      This is a recovery procedure when a CRM record is deleted because it 
--                      was newly created becuase of faulty ETO data entry (name or email matching).
--                      ** A deleted CRM contact record can still exist, but is flagged as DelettionStateCode=2.
--     20110110 - Fixed reversal of firstname/lastname in ETO_CRM_LMS_xref.
--     20110112 - Modified to map new ETO Entity to existing CRM record when already assigned to an entityid,
--                the provision is that the old entity is first disabled, allowing the new entity to take control.
--                Also re-assigns the DW_Completed_Courses to the new Entity, reseting the sync_phase.
--     20110210 - Fixed problem occuring when contacts were being re-mapped, the contact information
--                was not getting updated on the first update.  This was due to the IA_Staff.CRM_ContactID
--                had not been updated yet, which occured at the end of the update process.  It is the 
--                CRM_ContactID which is used as the join item during updates.
--     20110518 - Changed the update for Start_Date to update for all active Entities.
--     20110603 - Added process_log message for new staff mapping to existing (unassigned) CRM contact.
--     20110621 - Added email to CRM_Contacts_Log. Added loging when name or email changes in CRM.
--                Removed logging of disabled Staff records when CRM already assigned to another Staff Entity.
--                Changed to not re-map if Staff is disabled.  This is to prevent needless remapping on each 
--                integration session for multiple disable records for the same person who had history at other sites.
--     20110713 - Added inclusion of qualification for update to CRM against ia_staff.contacts_audit_date.
--                Will also update the ia_staff.last_crm_updated with the greatest of the two audit dates.
--     20111005 - Added column to IA_STAFF.flag_disregard_disabled, to not overwrite CRM contact status 
--                during CRM contact_status reset.  This allows CRM contact record to remain active even
--                when ETO is disabled.
--     20111019 - Process changes for CRM.New_ContactType (admin, nurse, partner, etc): no longer pulling from Staff_Update_Survey,
--                now pulling only from the IA_Staff record using new attributes.  New fields added:
--                  CRM.New_ContactType = IA_Staff.NURSE_0_PROGRAM_POSITION1
--                  CRM.new_secondarycontacttype = IA_Staff.NURSE_0_PROGRAM_POSITION2
--                  CRM.new_programstaffrole = IA_Staff.NURSE_PROFESSIONAL_1_REASON_HIRE
--                  CRM.new_fteother = Staff_Update_Survey.NURSE_PROFESSIONAL_1_ADMIN_ASST_FTE
--                                   + Staff_Update_Survey.NURSE_PROFESSIONAL_1_OTHER_FTE
--     20111104 - Changed reson for hire to lookup crm_attributevalue for numeric translation.
--     20120120 - Added logic during record update, contactextensionbase.new_contactstatus for flag_disregard_disabled
--     20120414 - Added bypass to non-ETO datasource.  Temporary until LMS datasource is considered real source.
--     20120430 - Added processing for selected non_eto data source to be pushed to CRM,
--                ** non-eto source, will default crm contact indicators to 'no-contact', 
--                   and an 'Unassigned' DW Agency / CRM acccount, untill otherwise assigned.
--     20121104 - Changed to accommodate CRM Upgrade (10/29/2012):
--                  - Changed CRM.ContactBase OwningUser to OwnerID,
--                  - Removed CRM.ContactBase.AccountID (still related via lookup for OwningBusunessUnit),
--                  - Removed the qualified resetting of DW.CRM_ContactID when the CRM.ContactBase DeletionState_Code is set.
--                    This was used when CRM didn't actually delete the record, but just indicated it as such.
--                  - Changed ContactExtensionbase updates/adds to retrieve AccountExtentionBase via the DW.AccountID instead
--                    of using the now removed CRM.ContactBase.AccountID.
--                Fixed DoNotContactBIt to use variable.
--     20121108 - Added accountid info to be added back into the contactbase table, 
--                defined as parentcustomerid, parentcustomeridtype, parencustomername (pulled from accountbase).
--     20130826 - Changed datasource qualification to push all but LMS to CRM.
--     20140122 - Added logic to re-map new ETO entities that were found to already exist for LMS non_ETO entity.
--                  Will disable the old non-ETO entity, and remove xrefs and links to CRM/LMS (LMS datasource).
--                Removed go-live special processing (from 2012).
--     20150714 - Amended FTE process to use primary/secondary FTE fields, evaluating the primary/secondary role
--                for which CRM FTE field is to be populated (NHV, Supervisor, Other).
--     20150818 - Amended to bypass IA_Staff records where flag_NSO_Transfer = 1.
--     20150910 - Renamed flag_NSO_Transfer to flag_Transfer to cover all transfer scenarios,
--                to exclude any transfered record from processing further, thus allowing another 
--                IA_Staff record to take precedence.

-- TO DO:
--     Fixed redundant notification of disabled entities trying to be linked with crm contacts
--     that are associated to a valid active entity.
--     -  CRM Update for CRM.new_programstaffrole = IA_Staff.NURSE_PROFESSIONAL_1_REASON_HIRE ??
--        how to resolve nul values coming from ETO/DW, don't want to overwrite what is already in CRM.

-- ** special return to stop processing of this procedure 6/10/2011 while debugging error
--return


-- Database Links:
-- CRM: CRMsrvr.Nurse_FamilyPartnership_MSCRM.

DECLARE @Process	nvarchar(50)
set @process = 'SP_CRM_CONTACTS'

DECLARE @insert_count		smallint
DECLARE @update_count		smallint
DECLARE @bypassed_count		smallint
DECLARE @cursor_count		int
DECLARE @transaction_count	int
set @insert_count = 0
set @update_count = 0
set @bypassed_count = 0
set @cursor_count = 0
set @transaction_count = 0

DECLARE @golive_trigger bit
DECLARE @Entity_ID	int
DECLARE @Last_Name	nvarchar(50)
DECLARE @First_Name	nvarchar(50)
DECLARE @Middle_Name	nvarchar(50)
DECLARE @Email  	nvarchar(200)
DECLARE @prior_Last_Name	nvarchar(50)
DECLARE @prior_First_Name	nvarchar(50)
DECLARE @prior_Email  		nvarchar(200)
DECLARE @Agency_Entity_ID	int
DECLARE @CRM_ContactID	uniqueidentifier
DECLARE @CRM_AccountID	uniqueidentifier
DECLARE @Lookup_ContactID	uniqueidentifier
DECLARE @Site_ID        int
DECLARE @Start_Date	datetime
DECLARE @Disabled       bit
DECLARE @flag_update_CRM bit
DECLARE @Audit_Date	datetime
DECLARE @Contacts_Audit_Date	datetime
DECLARE @SurveyResponseID        int
DECLARE @SurveyDate       datetime
DECLARE @Exit		nvarchar(10)
DECLARE @count		smallint
DECLARE @DataSource     nvarchar(10)

-- Calculated fields (conditional and Survey Fields):
DECLARE @New_ContactStatus	int		-- Status Code (0-active, 1-inactive)		
DECLARE @New_ed_nursing		int		-- Staff_Update_Survey Last degree CRM lov index
DECLARE @New_ed_other		int		-- Staff_Update_Survey Last degree CRM lov index
DECLARE @New_change_specific	nvarchar(200)	-- Staff_Update_Survey
DECLARE @New_change_start_date	datetime	-- Staff_Update_Survey
DECLARE @New_HireDate		datetime	-- New_Hire_Survey
DECLARE @New_ResignationDate	datetime	-- Staff Update Survey
DECLARE @New_FTEasNFPSupervisor	numeric(23,10)	-- Staff Update Survey
DECLARE @New_FTEasNHV		numeric(23,10)	-- Staff Update Survey
DECLARE @New_FTEAdminAsst	numeric(23,10)	-- Staff Update Survey
DECLARE @New_FTEOther		numeric(23,10)	-- Staff Update Survey
--DECLARE @New_ContactType  	numeric(23,10)	-- Staff Update Survey
DECLARE @New_NFPAgencyLocationID uniqueidentifier
DECLARE @New_CRM_ContactStatus	int		-- Status Code (0-active, 1-inactive)

DECLARE @DoNotContact_bit   bit
DECLARE @DoNotPhone          bit
DECLARE @DoNotFax            bit
DECLARE @DoNotPostalMail     bit
DECLARE @DoNotBulkEMail      bit
DECLARE @DoNotBulkPostalMail bit
DECLARE @DoNotSendMM         bit

-- Existing fields from CRM
DECLARE @CRM_ContactStatus	int		-- Status Code (0-active, 1-inactive)
DECLARE @CRM_NFPAgencyLocationID uniqueidentifier

DECLARE @xref_Entity_ID		int
DECLARE @xref_LMS_StudentID	int
DECLARE @xref_CRM_ContactID	uniqueidentifier
DECLARE @XREF_DataSource	nvarchar(10)
DECLARE @XREF_disabled		bit
DECLARE @xref_oldstaff_found	bit
DECLARE @new_CRM_ContactiD	uniqueidentifier
DECLARE @new_CRM_CustomerAddressiD	uniqueidentifier
DECLARE @CreateDate		datetime

DECLARE @SQL            nvarchar(4000)
DECLARE @bypass_flag    nvarchar(10)
DECLARE @DW_CRM_ContactID_Update_flag    nvarchar(10)
DECLARE @DW_completed_course_reset_entityid_flag    nvarchar(10)
DECLARE @return_id      int
DECLARE @qualified_ctr  smallint
DECLARE @return_value   nvarchar(50)

SET @return_id = null
SET @qualified_ctr = 0

print 'Begin Procedure: SP_CRM_Contacts - IA_Staff'

IF @p_entity_Id = 99999998
   BEGIN
      set @golive_trigger = 1
      set @p_entity_id = null
   END

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
-- Update the Staff record to force a CRM update if the Program Supervisor info has changed.
----------------------------------------------------------------------------------------
update ia_staff
  set Flag_Update_CRM = 1
  from dbo.IA_Staff
  inner join CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactBase CB
       on CB.ContactID = IA_Staff.CRM_ContactID
  left join dbo.IA_Staff suprstaff
       on dbo.FN_DW_Entity_Supervisor_ID (IA_Staff.Entity_Id) = suprstaff.Entity_Id 
 where IA_Staff.CRM_ContactID is not null
   and IA_Staff.Disabled = 0
   and isnull(IA_Staff.flag_dont_push_to_CRM,0) = 0
   and (CB.ManagerName != suprstaff.full_name COLLATE SQL_Latin1_General_CP1_CI_AI
    or CB.ManagerPhone != dbo.FN_Format_Phone_vs1(SuprStaff.Phone1,'0') )
   and IA_Staff.NURSE_0_PROGRAM_POSITION1 IS NOT NULL
   and isnumeric(substring(IA_Staff.Full_Name,1,1)) = 0
   and isnumeric(SUBSTRING(IA_Staff.last_name,1,1)) = 0
   and isnumeric(SUBSTRING(IA_Staff.first_name,1,1)) = 0
   and isnull(ia_staff.flag_Transfer,0) = 0;

----------------------------------------------------------------------------------------
-- Process the STaff Cursor
----------------------------------------------------------------------------------------
DECLARE StaffCursor Cursor for
select IA_Staff.Entity_ID
      ,IA_Staff.Last_Name
      ,IA_Staff.First_Name
      ,IA_Staff.Middle_Name
      ,IA_Staff.Email
      ,IA_Staff.CRM_ContactID
      ,Agencies.Entity_ID as Agency_Entity_ID
      ,Agencies.CRM_AccountID
      ,IA_Staff.Site_ID
      ,IA_Staff.Start_Date
      ,IA_Staff.Disabled
      ,IA_Staff.Audit_Date
      ,IA_Staff.Contacts_Audit_Date
      ,isnull(IA_Staff.flag_update_CRM,0)
      ,IA_Staff.DataSource
  from dbo.IA_Staff
  left join dbo.Agencies
         on IA_Staff.Site_ID = Agencies.Site_Id
 where (IA_Staff.Audit_Date > isnull(IA_Staff.Last_CRM_Update,convert(datetime,'19700101',112)) or
        IA_Staff.Contacts_Audit_Date > isnull(IA_Staff.Last_CRM_Update,convert(datetime,'19700101',112)) or
        IA_Staff.CRM_ContactID is null or
        isnull(IA_Staff.flag_update_CRM,0) = 1)
   and IA_Staff.NURSE_0_PROGRAM_POSITION1 IS NOT NULL
   and isnull(IA_Staff.flag_dont_push_to_CRM,0) = 0
   and isnumeric(substring(IA_Staff.Full_Name,1,1)) = 0
   and isnumeric(SUBSTRING(last_name,1,1)) = 0
   and isnumeric(SUBSTRING(first_name,1,1)) = 0
   and Agencies.Entity_Disabled = 0
   and Agencies.Site_Disabled = 0
   and Agencies.CRM_AccountID is not null
-- testing
   and isnull(@p_entity_id,'99999999') in ('99999999',ia_staff.entity_id)
   and isnull(IA_Staff.DataSource,'ETO')  not in ('LMS')
   and isnull(ia_staff.flag_Transfer,0) = 0
 order by IA_Staff.Entity_ID;

OPEN StaffCursor

FETCH next from StaffCursor
      into @Entity_ID
          ,@Last_Name
          ,@First_Name
          ,@Middle_Name
          ,@Email
          ,@CRM_ContactID
          ,@Agency_Entity_ID
          ,@CRM_AccountID
          ,@Site_ID
          ,@Start_Date
          ,@Disabled
          ,@Audit_Date
          ,@Contacts_Audit_Date
          ,@flag_update_CRM
          ,@DataSource

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
  set @bypass_flag = 'N'
  set @DW_CRM_ContactID_Update_flag = 'N'
  set @DW_completed_course_reset_entityid_flag = 'N'



--Validations:

  IF @CRM_ContactID is not null
    BEGIN

       -- 20101213: Check to see if CRM_Contact_ID still exists in CRM.
       --   If not found, reset CRM_ContactID to null so that re-validation can occur.

       select @count = count(*) 
         from CRMSrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactBase
        where ContactID = @CRM_ContactID

       IF @count = 0
          BEGIN
             set @CRM_ContactID = null
             insert into CRM_Contacts_Log
                    (Entity_ID, LogDate, Last_Name, First_Name, Middle_Name, Email, Action, Status, Comment)
                    Values (@Entity_ID, getdate()
                            ,@Last_Name, @First_Name, @Middle_Name, @Email
                            ,'New Staff','Warning'
                            ,'Mapped CRM record no longer exists, Re-evaluating as new ETO Record')
          END

      
       IF @Crm_ContactID is null
          -- Reset establed, reset xref
          BEGIN

            update dbo.IA_Staff 
               set CRM_ContactID = null
                  ,LMS_StudentID = null
             where Entity_ID = @Entity_ID
 
            update dbo.ETO_CRM_LMS_xref 
               set CRM_ContactID = null
                  ,LMS_StudentID =  null
           where Entity_ID = @Entity_ID

          END

    END  /* End of CRM_Contact_ID not null Validation */


-- Validate Email

   IF @Email is null
      BEGIN
         SET @bypass_flag = 'Y'
         IF @CRM_ContactID is null
            BEGIN
            insert into CRM_Contacts_Log
                  (Entity_ID, LogDate, Last_Name, First_Name, Middle_Name, Email, Action, Status, Comment)
                  Values (@Entity_ID, getdate()
                         ,@Last_Name, @First_Name, @Middle_Name, @Email
                         ,'New Staff','FAILED'
                         ,'Blank Email Address')
            END
         ELSE
            BEGIN
            insert into CRM_Contacts_Log
                  (Entity_ID, LogDate, Last_Name, First_Name, Middle_Name, Email, Action, Status, Comment)
                  Values (@Entity_ID, getdate()
                         ,@Last_Name, @First_Name, @Middle_Name, @Email
                         ,'Existing CRM Update','FAILED'
                         ,'Blank Email Address')
            END
      END

   IF @CRM_ContactID is null and @bypass_flag != 'Y'
   BEGIN

--  IA_Staff.CRM_ContactID not yet found, check if Staff is already in CRM. 
--    IF CRM lookup found:
--       Check if ContactID is already assigned in the IA_Staff (duplicate)
--       IF Duplicate found, create error log and bypass,
--       ELSE attach the found ContactID to the IA_Staff record.
--       Check to see if Staff record needs to update CRM Contact.
--    ELSE, consider IA_Staff a new Contact to push to CRM.


--     Lookup Parms: Lastname, FirstName, MiddleName, CRM_Account, Email
       select @lookup_ContactID = dbo.FN_CRM_Contact_Lookup_by_name(@last_name,@first_name,null,null,@Email)


       IF @lookup_ContactID = 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF'
          BEGIN
             SET @bypass_flag = 'Y'
             insert into CRM_Contacts_Log
                   (Entity_ID, LogDate, Last_Name, First_Name, Middle_Name, Email, Action, Status, Comment)
                   Values (@Entity_ID, getdate()
                          ,@Last_Name, @First_Name, @Middle_Name, @Email
                          ,'New Staff','FAILED'
                          ,'Cannot process: multiple name matches for CRM Contacts')
          END             
       ELSE
       IF @lookup_ContactID is not null
       BEGIN
          set @xref_CRM_ContactID = null
          set @xref_LMS_StudentID = null
          set @xref_DataSource = null
          set @xref_disabled = 0
          set @xref_oldstaff_found = 0
          select @xref_Entity_ID = xref.Entity_ID
                ,@xref_CRM_ContactID = xref.CRM_ContactID
                ,@xref_LMS_StudentID = xref.LMS_StudentID
                ,@xref_DataSource = isnull(oldstaff.Datasource,'ETO')
                ,@xref_disabled = oldstaff.disabled
                ,@xref_oldstaff_found = case when oldstaff.entity_id is not null then 1 else 0 END
            from dbo.ETO_CRM_LMS_xref xref
            left join dbo.IA_Staff oldstaff on xref.Entity_ID = oldstaff.entity_ID
           where xref.CRM_COntactID = @lookup_ContactID;

          IF @xref_CRM_ContactID is not null 
          BEGIN
             IF @xref_Entity_ID is null 
                BEGIN
                set @CRM_ContactID = @lookup_ContactID
                set @DW_CRM_ContactID_Update_Flag = 'Y'
                insert into CRM_Contacts_Log
                    (Entity_ID, LogDate, Last_Name, First_Name, Middle_Name, Email, Action, Status, Comment)
                     Values (@Entity_ID, getdate()
                            ,@Last_Name, @First_Name, @Middle_Name, @Email
                            ,'New Staff','MAPPED_TO_OLD_CRM'
                            ,'CRM Contact mapped to existing CRM Contact: ' +convert(varchar(36),@xref_CRM_ContactID))
                END

             ELSE IF @xref_Entity_ID != @Entity_ID
              BEGIN
                -- RE-Map if no old reference actually found
                --        if old reference is disabled, but new record is active
                --        if old reference is a non-ETO from LMS
                IF (@xref_oldstaff_found = 0)
                   OR (@xref_oldstaff_found = 1 and @xref_disabled = 1 and @disabled = 0)
                   OR (@xref_oldstaff_found = 1 and isnull(@xref_datasource,'ETO') = 'LMS')
                   BEGIN
                      -- remap becuase oldstaff is disabled or non_eto LMS or no longer exists in IA_Staff
                      set @CRM_ContactID = @lookup_ContactID
                      set @DW_CRM_ContactID_Update_Flag = 'Y'
                      set @DW_completed_course_reset_entityid_flag = 'Y'
                      insert into CRM_Contacts_Log
                         (Entity_ID, LogDate, Last_Name, First_Name, Middle_Name, Email, Action, Status, Comment)
                         Values (@Entity_ID, getdate()
                             ,@Last_Name, @First_Name, @Middle_Name, @Email
                             ,'New Staff','REMAPPED'
                             ,'CRM Contact re-mapped from disabled Entity_ID: ' +convert(varchar,@xref_Entity_ID))

                      -- disable old entity if not already done:
                      IF @xref_oldstaff_found = 1 and @xref_disabled = 0
                         BEGIN
                         update dbo.IA_Staff
                            set disabled = 1
                          where Entity_ID = @xref_entity_ID
                         END
                   END

                ELSE
                   BEGIN
                      SET @bypass_flag = 'Y'
                      IF @disabled = 0
                         insert into CRM_Contacts_Log
                            (Entity_ID, LogDate, Last_Name, First_Name, Middle_Name, Email, Action, Status, Comment)
                            Values (@Entity_ID, getdate()
                                ,@Last_Name, @First_Name, @Middle_Name, @Email
                                ,'New Staff','FAILED'
                                ,'CRM Contact name match already assigned to Entity_ID: ' +convert(varchar,@xref_Entity_ID))
                   END 
              END             
          END

       END -- End proc for found Contact ID
   END -- End validation for missing ia_staff contact id


   IF (@CRM_ContactID is null) and (@disabled = 1) and (@bypass_flag = 'N')
--   Found that ETO record is disabled (inactivated) and not attached to CRM record, 
--     so bypass and reset any forced update flags.
     BEGIN
      set @bypass_flag='Y'
      IF @flag_update_CRM = 1
        BEGIN
         update dbo.IA_Staff
            set flag_update_crm = 0
          where entity_id = @entity_id
        END
     END
----------------------------------------------------------------------------------------
-- process for new CRM Contact
----------------------------------------------------------------------------------------

    IF (@CRM_ContactID is null) and (@bypass_flag = 'N')
    BEGIN

      set nocount on
      update dbo.process_log 
         set Phase = 'New Contact - Insert'
            ,LogDate = getdate()
       where Process = @process


--       print 'Processing new CRM Contact: '+@Last_Name +', ' +@First_Name 
--          +', Entity_ID=' +convert(varchar,@Entity_ID)

--     Create the xref record:
       set @xref_Entity_ID = null
       select @xref_Entity_ID = Entity_ID
         from dbo.ETO_CRM_LMS_xref
        where Entity_ID = @Entity_ID

       IF @xref_Entity_ID is null
       BEGIN
          insert into dbo.ETO_CRM_LMS_xref (Entity_ID, Site_ID) 
             values (@Entity_ID, @Site_ID)
       END


       set @new_CRM_ContactID= NEWID()
       set @createdate = getdate()

       IF @DataSource is null 
          BEGIN
           set @DoNotContact_bit = 0
          END
       ELSE
          BEGIN
           set @DoNotContact_bit  = 1
          END

--  ** Forcing the CRM OwnerID field to the systemuserid of Lisa Harshman **
--     select * from CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.systemuser where lastname ='Harshman'
-- C7F16468-60F3-DF11-889F-000C296B1B62
-- orig: C8F692D3-55D1-DF11-8B12-000C296B1B62
-- systemuserbase, lastname=harshman=877643E9-4CA5-DD11-B758-00188B4D760D


--  Add to the CRM ContactBase table:
       Set @SQL = 'set nocount on 
        insert into CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactBase
          (ContactID,Owningbusinessunit,ownerID
           ,LastName, FirstName, MiddleName, FullName, YomiFullName
           ,Salutation,Suffix,EmailAddress1, Telephone1,GenderCode
           ,ParticipatesInWorkflow, IsBackofficeCustomer,DoNotPhone, DoNotFax, DoNotPostalMail
           ,DoNotBulkEMail, DoNotBulkPostalMail, IsPrivate, CreditOnHold, DoNotSendMM, Merged
           ,statecode, exchangerate, statuscode, createdon, modifiedon
           ,ManagerName ,ManagerPhone,ParentCustomerID,ParentCustomerIDTYpe,ParentCustomerIDName)
          select ''' +convert(varchar(36),@new_CRM_ContactID) +'''
                ,crmab.OwningBusinessUnit
                ,''877643E9-4CA5-DD11-B758-00188B4D760D''
                ,IA_Staff.Last_Name
                ,IA_Staff.First_Name
                ,IA_Staff.Middle_Name
                ,IA_Staff.Full_Name
                ,IA_Staff.Full_Name
                ,IA_Staff.prefix
                ,IA_Staff.suffix
                ,IA_Staff.Email
                ,dbo.FN_Format_Phone_vs1(IA_Staff.Phone1,''0'')
                ,(CASE when isnumeric(IA_Staff.NURSE_0_GENDER) = 1
                      then IA_Staff.NURSE_0_GENDER
                      else dbo.FN_Entity_Attribute_Pseudonym_Seq(''NURSE_0_GENDER'',IA_Staff.NURSE_0_GENDER) END)
                ,0
                ,0
                ,' +convert(varchar,@DoNotContact_bit) +'
                ,' +convert(varchar,@DoNotContact_bit) +'
                ,' +convert(varchar,@DoNotContact_bit) +'
                ,' +convert(varchar,@DoNotContact_bit) +'
                ,' +convert(varchar,@DoNotContact_bit) +'
                ,0
                ,0
                ,' +convert(varchar,@DoNotContact_bit) +'
                ,0
                ,0
                ,1.0000000000
                ,1
                ,convert(datetime,'''+convert(varchar(23),@CreateDate,126)+''',126)
                ,convert(datetime,'''+convert(varchar(23),@CreateDate,126)+''',126)
                ,SuprStaff.Full_Name
                ,dbo.FN_Format_Phone_vs1(SuprStaff.Phone1,''0'')
                ,crmab.AccountID
                ,crmab.BusinessTypeCode
                ,crmab.Name
            from dbo.IA_Staff
            left join dbo.Agencies
                   on IA_Staff.Site_ID = Agencies.Site_Id
            left join dbo.Ia_Staff SuprStaff
                   on dbo.FN_DW_Entity_Supervisor_ID(IA_Staff.Entity_ID) = SuprStaff.Entity_ID
            left  join CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.AccountBase crmab 
                   on Agencies.CRM_AccountID = crmab.AccountID
           where IA_Staff.Entity_ID = ' +convert(varchar,@Entity_ID)
       -- print @SQL
       EXEC (@SQL)


--  Add to the CRM ContactExtensionBase table:
       Set @SQL = 'set nocount on 
        insert into CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase
          (ContactID, New_ContactStatus, New_ContactType, new_secondarycontacttype, New_LocationID
          ,New_StateProvince, New_AgencyID, New_ProgramStaffRole
          ,New_StateReport, New_ReceiveHolidayCards, New_PromotetoSupervisor, New_QualityControlReport
          ,New_ImplementationReport, New_DemonstratedSupportforNFP, New_1st_MonthlyCommRev
          ,New_2nd_MonthlyCommtoIAsRev, New_TBHFlag, New_VocusContact
          ,New_OrigNFPServiceStartDate, New_HireDate,New_ManagerSupervisoremail,New_EmergencyContactName )
          select ''' +convert(varchar(36),@new_CRM_ContactID) +'''
                ,(case when IA_Staff.Disabled = 0 then 1 else 2 end)
                ,(CASE when isnumeric(IA_Staff.NURSE_0_PROGRAM_POSITION1) = 1
                      then IA_Staff.NURSE_0_PROGRAM_POSITION1
                      else dbo.FN_Entity_Attribute_Pseudonym_Seq(''NURSE_0_PROGRAM_POSITION1'',IA_Staff.NURSE_0_PROGRAM_POSITION1) END)
                ,(CASE when isnumeric(IA_Staff.NURSE_0_PROGRAM_POSITION2) = 1
                      then IA_Staff.NURSE_0_PROGRAM_POSITION2
                      else dbo.FN_Entity_Attribute_Pseudonym_Seq(''NURSE_0_PROGRAM_POSITION2'',IA_Staff.NURSE_0_PROGRAM_POSITION2) END)
                ,null -- New_LocationID
                ,crmaeb.New_StateProvince
                ,crmaeb.New_AgencyID
                ,(CASE when isnumeric(IA_Staff.NURSE_PROFESSIONAL_1_REASON_HIRE) = 1
                      then IA_Staff.NURSE_PROFESSIONAL_1_REASON_HIRE
                      else dbo.FN_Entity_Attribute_Pseudonym_Seq(''NURSE_PROFESSIONAL_1_REASON_HIRE'',IA_Staff.NURSE_PROFESSIONAL_1_REASON_HIRE) END)
                ,0,0,0,0,0,0,0,0,0,0
                ,dateadd(hour,7,IA_Staff.Start_Date)
                ,dateadd(hour,7,IA_Staff.Start_Date)
                ,SuprStaff.email
                ,IA_Staff.NURSE_PERSONAL_0_ER_CONTACT
            from dbo.IA_Staff
            left join dbo.Ia_Staff SuprStaff
                   on dbo.FN_DW_Entity_Supervisor_ID(IA_Staff.Entity_ID) = SuprStaff.Entity_ID
            left join dbo.Agencies
                   on IA_Staff.Site_ID = Agencies.Site_Id
            left  join CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.AccountExtensionBase crmaeb 
                   on Agencies.CRM_AccountID = crmaeb.AccountID
           where IA_Staff.Entity_ID = ' +convert(varchar,@Entity_ID)
       --print @SQL
       EXEC (@SQL)


--  Add to the CRM CustomerAddressBase table:

       set @new_CRM_CustomerAddressID = NEWID()

       Set @SQL = 'set nocount on 
        insert into CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.CustomerAddressBase
          (ParentID,CustomerAddressID,AddressNumber,ObjectTypeCode,AddressTypeCode,Name
          ,PrimaryContactName,Line1,Line2,Line3,City,StateOrProvince,County,Country,PostalCode
          ,Telephone1,CreatedOn,ModifiedOn)
         select ''' +convert(varchar(36),@new_CRM_ContactID) +'''
               ,''' +convert(varchar(36),@new_CRM_CustomerAddressID) +'''
               ,1,2,null,null
               ,null --PrimaryContactName
               ,IA_Staff.Address1
               ,IA_Staff.Address2
               ,null --Address3
               ,IA_Staff.City
               ,IA_Staff.State
               ,IA_Staff.County
               ,null --Country
               ,IA_Staff.ZipCode
               ,dbo.FN_Format_Phone_vs1(IA_Staff.Phone1,''0'')
               ,convert(datetime,'''+convert(varchar(23),@CreateDate,126)+''',126)
               ,convert(datetime,'''+convert(varchar(23),@CreateDate,126)+''',126)
            from dbo.IA_Staff
           where IA_Staff.Entity_ID = ' +convert(varchar,@Entity_ID)
       --print @SQL
       EXEC (@SQL)


--     Update Xref with New CRM_ContactID
       BEGIN
          update dbo.ETO_CRM_LMS_xref 
             set CRM_ContactID = @new_CRM_ContactID
                ,CRM_AccountID =  @CRM_AccountID
                ,CRM_FirstName = @First_Name
                ,CRM_LastName = @Last_Name
                ,CRM_email = @Email
                ,ETO_How_Matched = 'New CRM Contact'
           where Entity_ID = @Entity_ID;
       END

       -- Update Staff record with ContactID:
       update dbo.IA_Staff
          set CRM_ContactID = @new_CRM_ContactID
             ,Last_CRM_Update = convert(datetime,dbo.FN_GREATEST(@Audit_Date,@Contacts_Audit_Date),120)
             ,flag_update_Crm = 0
        where Entity_ID = @Entity_ID


       -- Add Log Record:
       insert into CRM_Contacts_Log
           (Entity_ID, LogDate, Last_Name, First_Name, Middle_Name, Email, Action, Status
            ,Comment, CRM_ContactID)
           Values (@Entity_ID, getdate()
                  ,@Last_Name, @First_Name, @Middle_Name, @Email
                  ,'New Staff','OK',null, @new_CRM_ContactID)

       set @insert_count = @insert_count + 1

    END -- Process for new CRM Contact

----------------------------------------------------------------------------------------
-- process CRM Contact update
----------------------------------------------------------------------------------------

    IF (@CRM_ContactID is not null) and (@bypass_flag = 'N')
    BEGIN
      set nocount on
      update dbo.process_log 
         set Phase = 'Existing Contact - Update'
            ,LogDate = getdate()
       where Process = @process
--       print 'updating CRM records for '+@Last_Name +', ' +@First_Name 
--          +' ContactID= ' +convert(varchar(36),@CRM_ContactID) 

       IF @DW_CRM_ContactID_Update_Flag = 'Y'
          BEGIN
             -- DW tables have been refreshed, so re-establish known ContactID from xref:
             update dbo.IA_Staff
                set CRM_ContactID = @CRM_ContactID
                   ,LMS_StudentID = @xref_LMS_StudentID
              where Entity_ID = @Entity_ID   
          END;

--     Get previous name and email used for comparison logging:
       select @prior_Last_Name = ContactBase.LastName
             ,@prior_First_Name = ContactBase.FirstName
             ,@prior_Email = ContactBase.EmailAddress1
         from CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactBase
        where ContactBase.ContactID = @CRM_ContactID

       IF @Last_Name != @Prior_Last_Name or
          @First_Name != @Prior_First_Name or
          @Email != @Prior_Email
          BEGIN
             -- Add Log Record:
             insert into CRM_Contacts_Log
                 (Entity_ID, LogDate, Last_Name, First_Name, Middle_Name, Email, Action, Status
                  ,Comment, CRM_ContactID)
                 Values (@Entity_ID, getdate()
                        ,@Last_Name, @First_Name, @Middle_Name, @Email
                        ,'Name/Email Changed','OK',null, @CRM_ContactID)
          END


--     Get previous status used for comparison updates:
       select @CRM_ContactStatus = ContactExtensionBase.New_ContactStatus
         from CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase
        where ContactExtensionBase.ContactID = @CRM_ContactID

       set @createdate = getdate()

       IF @DataSource is null 
          BEGIN
           set @DoNotContact_bit = 0
          END
       ELSE
          BEGIN
           set @DoNotContact_bit  = 1
          END

       Set @SQL = 'set nocount on 
         update CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactBase
             set OwningBusinessUnit = crmab.OwningBusinessUnit
                ,LastName = IA_Staff.Last_Name
                ,FirstName = IA_Staff.First_Name
                ,MiddleName = IA_Staff.Middle_Name
                ,FullName = IA_Staff.Full_Name
                ,YomiFullName = IA_Staff.Full_Name
                ,Salutation = IA_Staff.prefix
                ,suffix = IA_Staff.suffix
                ,EmailAddress1 = isnull(IA_Staff.Email,null)
                ,Telephone1 = dbo.FN_Format_Phone_vs1(IA_Staff.Phone1,''0'')
  --              ,GenderCode = IA_Staff.Nurse_0_Gender
  --              ,GenderCode = coalesce(IA_Staff.Nurse_0_Gender,GenderCodePLTable.gendercode)
                ,modifiedon = convert(datetime,'''+convert(varchar(23),@createdate,126)+''',126)
                ,ManagerName = SuprStaff.Full_Name
                ,ManagerPhone = dbo.FN_Format_Phone_vs1(SuprStaff.Phone1,''0'')
                ,DoNotPhone = ' +convert(varchar,@DoNotContact_bit) +'
                ,DoNotFax = ' +convert(varchar,@DoNotContact_bit) +'
                ,DoNotPostalMail = ' +convert(varchar,@DoNotContact_bit) +'
                ,DoNotBulkEMail = ' +convert(varchar,@DoNotContact_bit) +'
                ,DoNotBulkPostalMail = ' +convert(varchar,@DoNotContact_bit) +'
                ,DoNotSendMM = ' +convert(varchar,@DoNotContact_bit) +'
                ,ParentCustomerID = crmab.AccountID
                ,ParentCustomerIDType = crmab.BusinessTYpeCode
                ,ParentCustomerIDName = crmab.Name
            from CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactBase 
            inner join dbo.IA_Staff
                    on IA_Staff.CRM_ContactID = ContactBase.ContactID
            left join dbo.Agencies
                   on IA_Staff.Site_ID = Agencies.Site_Id
            left join dbo.Ia_Staff SuprStaff
                   on dbo.FN_DW_Entity_Supervisor_ID(IA_Staff.Entity_ID) = SuprStaff.Entity_ID
            left outer join CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.AccountBase crmab 
                   on Agencies.CRM_AccountID = crmab.AccountID
           where ContactBase.ContactID = ''' +convert(varchar(36),@CRM_ContactID) +'''
             and IA_Staff.Entity_ID = ' +convert(varchar,@Entity_ID)
       --print @SQL
       EXEC (@SQL)



--     Check to see if record exists for ContactExtensionBase, if not add it instead:
       select @count = count(*) 
         from CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase
        where ContactID = @CRM_ContactID

     IF @count = 0
     BEGIN

--     Add to the CRM ContactExtensionBase table:
       Set @SQL = 'set nocount on 
        insert into CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase
          (ContactID, New_ContactStatus, New_ContactType, new_secondarycontacttype, New_LocationID
          ,New_StateProvince, New_AgencyID, New_ProgramStaffRole
          ,New_StateReport, New_ReceiveHolidayCards, New_PromotetoSupervisor, New_QualityControlReport
          ,New_ImplementationReport, New_DemonstratedSupportforNFP, New_1st_MonthlyCommRev
          ,New_2nd_MonthlyCommtoIAsRev, New_TBHFlag, New_VocusContact
          ,New_OrigNFPServiceStartDate, New_HireDate,New_ManagerSupervisoremail,New_EmergencyContactName )
          select ''' +convert(varchar(36),@CRM_ContactID) +'''
                ,(case when IA_Staff.Disabled = 0 then 1 else 2 end)
                ,(CASE when isnumeric(IA_Staff.NURSE_0_PROGRAM_POSITION1) = 1
                      then IA_Staff.NURSE_0_PROGRAM_POSITION1
                      else dbo.FN_Entity_Attribute_Pseudonym_Seq(''NURSE_0_PROGRAM_POSITION1'',IA_Staff.NURSE_0_PROGRAM_POSITION1) END)
                ,(CASE when isnumeric(IA_Staff.NURSE_0_PROGRAM_POSITION2) = 1
                      then IA_Staff.NURSE_0_PROGRAM_POSITION2
                      else dbo.FN_Entity_Attribute_Pseudonym_Seq(''NURSE_0_PROGRAM_POSITION2'',IA_Staff.NURSE_0_PROGRAM_POSITION2) END)
                ,null -- New_LocationID
                ,crmaeb.New_StateProvince
                ,crmaeb.New_AgencyID
                ,(CASE when isnumeric(IA_Staff.NURSE_PROFESSIONAL_1_REASON_HIRE) = 1
                      then IA_Staff.NURSE_PROFESSIONAL_1_REASON_HIRE
                      else dbo.FN_Entity_Attribute_Pseudonym_Seq(''NURSE_PROFESSIONAL_1_REASON_HIRE'',IA_Staff.NURSE_PROFESSIONAL_1_REASON_HIRE) END)
                ,0,0,0,0,0,0,0,0,0,0
                ,dateadd(hour,7,IA_Staff.Start_Date)
                ,dateadd(hour,7,IA_Staff.Start_Date)
                ,SuprStaff.email
                ,IA_Staff.NURSE_PERSONAL_0_ER_CONTACT
            from dbo.IA_Staff
            left join dbo.Agencies
                   on IA_Staff.Site_ID = Agencies.Site_Id
            left join dbo.Ia_Staff SuprStaff
                   on dbo.FN_DW_Entity_Supervisor_ID(IA_Staff.Entity_ID) = SuprStaff.Entity_ID
            inner join CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactBase ContactBase
                    on IA_Staff.CRM_ContactID = ContactBase.ContactID
            left  join CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.AccountExtensionBase crmaeb 
                   on Agencies.CRM_AccountID = crmaeb.AccountID
           where IA_Staff.Entity_ID = ' +convert(varchar,@Entity_ID)
       --print @SQL
       EXEC (@SQL)

     END
     ELSE
     BEGIN

-- fields to yet to be mapped for update to ContactExtensionBase:
             --   ,New_LocationID = 
             --   ,New_ProgramStaffRole =

       Set @SQL = 'set nocount on 
         update CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase
             set New_OrigNFPServiceStartDate = coalesce(ContactExtensionBase.New_OrigNFPServiceStartDate, IA_Staff.Start_Date)
                ,New_ContactStatus = (case when IA_Staff.Disabled = 0 then 1 when isnull(IA_Staff.flag_disregard_disabled,0) = 1 then New_Contactstatus else 2 end)
                ,New_COntactType = dbo.FN_Entity_Attribute_Pseudonym_Seq(''NURSE_0_PROGRAM_POSITION1'',IA_Staff.NURSE_0_PROGRAM_POSITION1)
                ,new_secondarycontacttype = dbo.FN_Entity_Attribute_Pseudonym_Seq(''NURSE_0_PROGRAM_POSITION2'',IA_Staff.NURSE_0_PROGRAM_POSITION2)
                ,New_StateProvince = crmaeb.New_StateProvince
                ,New_AgencyID = crmaeb.New_AgencyID
                ,New_ManagerSupervisoremail = SuprStaff.email
                ,New_EmergencyContactName = IA_Staff.NURSE_PERSONAL_0_ER_CONTACT'

--        IF @New_StartDate is not null
--           set @SQL = @SQL +',New_HireDate = IA_Staff.Start_Date '
--         --  set @SQL = @SQL +',New_HireDate = dateadd(hour,7,convert(datetime,''' +convert(varchar(23),@StartDate,126) +''',126)) '

        -- commented and replaced 20110518 to update for all active Entities:
        --IF @CRM_ContactStatus = 2 and @Disabled = 0 and (@Start_Date is not null)
        --   set @SQL = @SQL +',New_HireDate = dateadd(hour,7,IA_Staff.Start_Date)' 

        IF @Disabled = 0 and (@Start_Date is not null)
           set @SQL = @SQL +',New_HireDate = dateadd(hour,7,IA_Staff.Start_Date)' 

        set @SQL = @SQL +'
            from CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase 
            inner join dbo.IA_Staff
                    on IA_Staff.CRM_ContactID = ContactExtensionBase.ContactID
            left join dbo.Agencies
                   on IA_Staff.Site_ID = Agencies.Site_Id
            left join dbo.Ia_Staff SuprStaff
                   on dbo.FN_DW_Entity_Supervisor_ID(IA_Staff.Entity_ID) = SuprStaff.Entity_ID
            inner join CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactBase ContactBase
                    on IA_Staff.CRM_ContactID = ContactBase.ContactID
            left  join CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.AccountExtensionBase crmaeb 
                   on Agencies.CRM_AccountID = crmaeb.AccountID
           where ContactExtensionBase.ContactID = ''' +convert(varchar(36),@CRM_ContactID) +'''
             and IA_Staff.Entity_ID = ' +convert(varchar,@Entity_ID)

       -- print @SQL
       EXEC (@SQL)

     END -- End either insert or update for contact extension base


--   Address information:

       Set @SQL = 'set nocount on 
         update CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.CustomerAddressBase
            set Line1 = IA_Staff.Address1
               ,Line2 = IA_Staff.Address2
               ,City = IA_Staff.City
               ,StateOrProvince = IA_Staff.State
               ,County = IA_Staff.County
           --    ,Country =
               ,PostalCode = IA_Staff.ZipCode
               ,Telephone1 = dbo.FN_Format_Phone_vs1(IA_Staff.Phone1,''0'')
           --    ,PrimaryContactName =
               ,Modifiedon = convert(datetime,'''+convert(varchar(23),@CreateDate,126)+''',126)
            from CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.CustomerAddressBase 
            inner join dbo.IA_Staff
                    on IA_Staff.CRM_ContactID = CustomerAddressBase.ParentID
           where IA_Staff.Entity_ID = ' +convert(varchar,@Entity_ID) +'
             and CustomerAddressBase.AddressNumber = 1'
       --print @SQL
       EXEC (@SQL)


       set @update_count = @update_count + 1

       IF @DW_CRM_ContactID_Update_Flag = 'Y'
          BEGIN
             -- DW tables have been refreshed, so re-establish known ContactID from xref:
             -- update the audit last update indicators.
             update dbo.IA_Staff
                set Last_CRM_Update = convert(datetime,dbo.FN_GREATEST(@Audit_Date,@Contacts_Audit_Date),120)
                   ,flag_update_Crm = 0
              where Entity_ID = @Entity_ID   

              -- Update xref to reflect the new IA_Staff entity
              BEGIN
              update dbo.ETO_CRM_LMS_xref
                 set Entity_ID = @Entity_ID
               where CRM_ContactID = @CRM_ContactID
              END

              -- Update new EntityID for DW_Completed_Courses Table:
              -- (set the sync_phase so ETO will be updated with completed coures for new entity)
              IF @DW_completed_course_reset_entityid_flag = 'Y'
              BEGIN
                 BEGIN
                 update dbo.DW_Completed_Courses
                    set entity_id = @Entity_ID
                       ,sync_phase = null
                  where contactId = @CRM_ContactID
                  END

                  -- Update the old IA_Staff Entity removing the CRM_ContactID / LMS_StudentID
                 BEGIN
                 update dbo.IA_Staff
                    set CRM_ContactID = null
                       ,LMS_StudentID = null
                  where Entity_ID = @xref_Entity_ID
                 END
              END
          END
       ELSE
--       Update Last_CRM_UPdate date:
         BEGIN
          update dbo.IA_Staff
             set Last_CRM_Update = convert(datetime,dbo.FN_GREATEST(@Audit_Date,@Contacts_Audit_Date),120)
                ,flag_update_Crm = 0
           where Entity_ID = @Entity_ID
         END


    END
----------------------------------------------------------------------------------------
-- continue in cursor
----------------------------------------------------------------------------------------

   IF @bypass_flag = 'Y'
      set @bypassed_count = @bypassed_count + 1

   FETCH next from StaffCursor
         into @Entity_ID
             ,@Last_Name
             ,@First_Name
             ,@Middle_Name
             ,@Email
             ,@CRM_ContactID
             ,@Agency_Entity_ID
             ,@CRM_AccountID
             ,@Site_ID
             ,@Start_Date
             ,@Disabled
             ,@Audit_Date
             ,@Contacts_Audit_Date
             ,@flag_update_CRM
             ,@DataSource

END -- End of StaffCursor loop

CLOSE StaffCursor
DEALLOCATE StaffCursor

print 'IA_Staff Members Processed: ' +convert(varchar,@cursor_count)
print 'CRM Contacts Added:         ' +convert(varchar,@insert_count)
print 'CRM Contacts Updated:       ' +convert(varchar,@update_count)
print 'CRM Bypassed Staff:         ' +convert(varchar,@bypassed_count)



----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- Process the Staff_Update_Survey Cursor
----------------------------------------------------------------------------------------

print 'Begin Procedure: SP_CRM_Contacts - Staff_Update_Survey'

set @cursor_count = 0
set @transaction_count = 0

DECLARE StaffUpdate_Cursor Cursor for
select IA_Staff.Entity_ID
      ,IA_Staff.CRM_ContactID
      ,SUS.SurveyResponseID
      ,SUS.SurveyDate
      ,case when sus.NURSE_PRIMARY_ROLE   = 'Nurse Home Visitor'
             and sus.NURSE_SECONDARY_ROLE = 'Nurse Home Visitor'
             then sus.NURSE_PRIMARY_ROLE_FTE + sus.NURSE_SECONDARY_ROLE_FTE
            when sus.NURSE_PRIMARY_ROLE   = 'Nurse Home Visitor' then sus.NURSE_PRIMARY_ROLE_FTE 
            when sus.NURSE_SECONDARY_ROLE = 'Nurse Home Visitor' then sus.NURSE_SECONDARY_ROLE_FTE 
            else null end as HOME_VISITOR_FTE
      ,case when sus.NURSE_PRIMARY_ROLE   = 'Nurse Supervisor' 
             and sus.NURSE_SECONDARY_ROLE = 'Nurse Supervisor'
             then sus.NURSE_PRIMARY_ROLE_FTE +  sus.NURSE_SECONDARY_ROLE_FTE
            when sus.NURSE_PRIMARY_ROLE   = 'Nurse Supervisor' then sus.NURSE_PRIMARY_ROLE_FTE
            when sus.NURSE_SECONDARY_ROLE = 'Nurse Supervisor' then sus.NURSE_SECONDARY_ROLE_FTE 
            else null end as SUPERVISOR_FTE
      ,case when isnull(sus.NURSE_PRIMARY_ROLE,'x')    not in ('x','Nurse Home Visitor', 'Nurse Supervisor') 
             and isnull(sus.NURSE_SECONDARY_ROLE,'x')  not in ('x','Nurse Home Visitor', 'Nurse Supervisor') 
             then isnull(sus.NURSE_PRIMARY_ROLE_FTE,0) + isnull(sus.NURSE_SECONDARY_ROLE_FTE,0)
            when isnull(sus.NURSE_PRIMARY_ROLE,'x')   not in ('x','Nurse Home Visitor', 'Nurse Supervisor') then sus.NURSE_PRIMARY_ROLE_FTE 
            when isnull(sus.NURSE_SECONDARY_ROLE,'x') not in ('x','Nurse Home Visitor', 'Nurse Supervisor') then sus.NURSE_SECONDARY_ROLE_FTE
            else null end as OTHER_FTE
      ,dateadd(hour,7,NURSE_STATUS_0_CHANGE_TERMINATE_DATE)
      ,CASE when isnumeric(NURSE_EDUCATION_0_NURSING_DEGREES) = 1
            then NURSE_EDUCATION_0_NURSING_DEGREES
            else dbo.FN_Survey_Element_Choice_Seq(SUS.SurveyID,'NURSE_EDUCATION_0_NURSING_DEGREES'
                                       ,NURSE_EDUCATION_0_NURSING_DEGREES,'x')
            END as Ed_Degree_Nursing
      ,CASE when isnumeric(NURSE_EDUCATION_1_OTHER_DEGREES) = 1
            then NURSE_EDUCATION_1_OTHER_DEGREES
            else dbo.FN_Survey_Element_Choice_Seq(SUS.SurveyID,'NURSE_EDUCATION_1_OTHER_DEGREES'
                                       ,NURSE_EDUCATION_1_OTHER_DEGREES,'x')
            END as Ed_Degree_Other
      ,dateadd(hour,7,NURSE_STATUS_0_CHANGE_START_DATE)
      ,NURSE_STATUS_0_CHANGE_SPECIFIC as New_change_specific	
  from Staff_Update_Survey SUS
  inner join dbo.IA_Staff
          on SUS.CL_EN_GEN_ID = IA_Staff.Entity_Id
  inner join CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase CEB
          on IA_Staff.CRM_ContactID = CEB.ContactID
 where SUS.Entity_ID_Mapped is null
   and IA_Staff.CRM_ContactID IS NOT NULL
   and isnull(IA_Staff.flag_dont_push_to_CRM,0) = 0
   and isnull(ia_staff.flag_Transfer,0) = 0
-- testing
   and isnull(@p_entity_id,'99999999') in ('99999999',SUS.CL_EN_GEN_ID)
 order by SUS.SurveyDate;

OPEN StaffUpdate_Cursor

FETCH next from StaffUpdate_Cursor
      into @Entity_ID
          ,@CRM_ContactID
          ,@SurveyResponseID
          ,@SurveyDate
          ,@New_FTEasNHV
          ,@New_FTEasNFPSupervisor
          ,@New_FTEOther
          ,@New_ResignationDate
          ,@New_ed_nursing
          ,@New_ed_other
          ,@New_change_start_date
          ,@New_change_specific

WHILE @@FETCH_STATUS = 0
BEGIN

-- print 'processing entityid=' +convert(varchar,@entity_id)

   set nocount on
   update dbo.process_log 
      set Action = 'Processing Staff_Update_Survey'
         ,Phase = null
         ,Comment = null
         ,index_1 = @Entity_ID
         ,index_2 = @SurveyResponseID
         ,index_3 = null
         ,LogDate = getdate()
    where Process = @process

  set nocount on
  set @cursor_count = @cursor_count + 1
  set @bypass_flag = 'N'

-- fields yet to be mapped for update to ContactExtensionBase:
--   ,New_LocationID = 
--   ,New_ProgramStaffRole =

-- xref to CRM lov via function
-- function parms: surveyid, pseudonym, choicetext,weightflag
-- dbo.FN_Survey_Element_Choice_Seq(1729,'NURSE_EDUCATION_1_OTHER_DEGREES','Bachelor’s degree','x')


      IF @New_ed_nursing is not null
         BEGIN
           update CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase 
              set New_Ed_Nursing = @New_ed_nursing
            where ContactID = convert(varchar(36),@CRM_ContactID)
            set @transaction_count = @transaction_count + 1
         END


      IF @New_ed_other is not null
         BEGIN
           update CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase 
              set New_Ed_other = @New_ed_other
            where ContactID = convert(varchar(36),@CRM_ContactID)
            set @transaction_count = @transaction_count + 1
         END

-- no longer being used 10/19/2011
--      IF @New_ContactType is not null
--         BEGIN
--           update CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase 
--              set New_ContactType = @New_ContactType
--            where ContactID = convert(varchar(36),@CRM_ContactID)
--            set @transaction_count = @transaction_count + 1
--         END


      IF @New_ResignationDate is not null
         BEGIN 
           update CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase 
              set New_ResignationDate = @New_ResignationDate
            where ContactID = convert(varchar(36),@CRM_ContactID)
            set @transaction_count = @transaction_count + 1
         END


--  Rule of applying multiple FTE fields from survey:
--  IF all 3 fte fields are null, then dont update CRM.
--  If any one of the 3 FTE fields are supplied, then update all 3 CRM FTE fields
--    from the survey, setting zero to the null FTE fields.

      IF (@New_FTEasNHV is not null) or
         (@New_FTEasNFPSupervisor is not null) or
         (@New_FTEOther is not null)
         BEGIN
           update CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase 
              set New_FTEasNHV = isnull(@New_FTEasNHV,0)
                 ,New_FTEasNFPSupervisor = isnull(@New_FTEasNFPSupervisor,0)
                 ,New_FTEOther = isnull(@New_FTEOther,0)
            where ContactID = convert(varchar(36),@CRM_ContactID)
            set @transaction_count = @transaction_count + 1
         END


--    Promote to Supervisor:
      IF @New_change_specific is not null
         BEGIN
           set nocount on 
           update CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase 
              set New_PromotetoSupervisor = 1
            where ContactID = convert(varchar(36),@CRM_ContactID)
           IF @New_change_start_date is not null
              BEGIN
                set nocount on 
                update CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase 
                   set New_DateofPromotion = dateadd(hour,7,@new_change_start_Date)
                 where ContactID = convert(varchar(36),@CRM_ContactID)
              END
            set @transaction_count = @transaction_count + 1
         END


--    Update Survey record so it's not to be processed again:
      update Staff_Update_Survey
         set Entity_ID_Mapped = @Entity_ID
       where SurveyResponseID = @SurveyResponseID;


   FETCH next from StaffUpdate_Cursor
         into @Entity_ID
             ,@CRM_ContactID
             ,@SurveyResponseID
             ,@SurveyDate
             ,@New_FTEasNHV
             ,@New_FTEasNFPSupervisor
             ,@New_FTEOther
             ,@New_ResignationDate
             ,@New_ed_nursing
             ,@New_ed_other
             ,@New_change_start_date
             ,@New_change_specific


END -- End of StaffUpdate_Cursor loop

CLOSE StaffUpdate_Cursor
DEALLOCATE StaffUpdate_Cursor

print 'Staff_Update_Surveys Processed:     ' +convert(varchar,@cursor_count)
print 'Survey Transactions Applied to CRM: ' +convert(varchar,@transaction_count)


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- Process the Teams
-- CRM Teams are related via ETO Programs/Program Groups
--   In the SP_Programs_Main process, all Eto Programs are related to an actual 
--   CRM NFPAgencyLocationExtenstionBase record which is the team.
--   This process finds the Entities supervised team, and updates the CRM record
--    to reflect team changes.
-- don't overwrite contact if mapped ETO/CRM team is null,
-- only update if found to be different.
----------------------------------------------------------------------------------------
print 'Updating new Program/Teams in CRM Contacts'

set nocount off
update CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase
   set New_NFPAgencyLocationID = programs.CRM_new_nfpagencylocationid
  from CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase CEB
  inner join ia_staff
    on IA_Staff.CRM_ContactId = CEB.contactid
  inner join dbo.Programs
    on dbo.FN_DW_Entity_Supervised_Program_ID(IA_Staff.Entity_Id) = programs.program_id
 where programs.CRM_new_nfpagencylocationid is not null
   and isnull(IA_Staff.flag_dont_push_to_CRM,0) = 0
   and (ceb.New_NFPAgencyLocationID is null or
        ceb.New_NFPAgencyLocationID != programs.CRM_new_nfpagencylocationid)
   and isnull(ia_staff.flag_Transfer,0) = 0


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- Reset crm Contact Status flag for ETO records that had a change in the disabled flad
-- but not having the audit date reflect the change.
-- Inactivating Disabled Staff / Re-activate active Staff
----------------------------------------------------------------------------------------
print 'Inactivating disabled CRM Contacts'

update CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase
   set New_ContactStatus = 2
 where ContactID in
 (select CEB.ContactID
  from dbo.IA_Staff
  inner join CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase CEB
         on CEB.ContactID = IA_Staff.CRM_ContactID
 where IA_Staff.Disabled = 1
   and isnull(IA_Staff.flag_disregard_disabled,0) = 0
   and isnull(IA_Staff.flag_dont_push_to_CRM,0) = 0
   and CEB.New_ContactStatus != 2
   and IA_Staff.NURSE_0_PROGRAM_POSITION1 IS NOT NULL
   and isnumeric(substring(IA_Staff.Full_Name,1,1)) = 0
   and isnumeric(SUBSTRING(last_name,1,1)) = 0
   and isnumeric(SUBSTRING(first_name,1,1)) = 0  
   and isnull(IA_Staff.flag_Transfer,0) = 0 )
   
print 'Re-activating CRM Contacts'

update CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase
   set New_ContactStatus = 1
 where ContactID in
 (select CEB.ContactID
  from dbo.IA_Staff
  inner join CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase CEB
         on CEB.ContactID = IA_Staff.CRM_ContactID
 where IA_Staff.Disabled = 0
   and isnull(IA_Staff.flag_disregard_disabled,0) = 0
   and isnull(IA_Staff.flag_dont_push_to_CRM,0) = 0
   and CEB.New_ContactStatus != 1
   and IA_Staff.NURSE_0_PROGRAM_POSITION1 IS NOT NULL
   and isnumeric(substring(IA_Staff.Full_Name,1,1)) = 0
   and isnumeric(SUBSTRING(last_name,1,1)) = 0
   and isnumeric(SUBSTRING(first_name,1,1)) = 0
   and isnull(ia_staff.flag_Transfer,0) = 0 )
   

set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process


PRINT 'End of Procedure: SP_CRM_Contacts'

GO
