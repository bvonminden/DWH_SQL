USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_ETO_CRM_LMS_xref]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_ETO_CRM_LMS_xref
CREATE procedure [dbo].[SP_ETO_CRM_LMS_xref]
AS
--
-- This procedure attements to create the xref between ETO, CRM, and LMS for IA Staff
--
-- LMS to CRM Match: LastName, FirstName, Email; NAme only.

-- Database Links:
-- CRM: CRMsrvr.Nurse_Familypartnership_MSCRM.
-- LMS: LMSsrvr.Tracker3. 

DECLARE @CRM_count		smallint
DECLARE @LMS_count		smallint
DECLARE @LMS_mult_count		smallint
DECLARE @ETO_count		smallint
DECLARE @cursor_count		smallint
DECLARE @count			smallint
set @CRM_count = 0
set @LMS_count = 0
set @LMS_mult_count = 0
set @ETO_count = 0
set @cursor_count = 0

DECLARE @Entity_ID	int
DECLARE @Site_ID	int
DECLARE @CRM_AccountID	uniqueidentifier
DECLARE @CRM_ContactID	uniqueidentifier
DECLARE @CRM_LMS_OrgID	int
DECLARE @LMS_StudentID	int
DECLARE @Last_Name	nvarchar(50)
DECLARE @First_Name	nvarchar(50)
DECLARE @Email  	nvarchar(100)
DECLARE @StudentID	int

DECLARE @return_value   nvarchar(50)


----------------------------------------------------------------------------------------
-- Insert new CRM Records
----------------------------------------------------------------------------------------
print 'adding new CRM records not previously loaded into the xref table'

insert into dbo.ETO_CRM_LMS_xref
   (CRM_ContactID, CRM_AccountID, CRM_LMS_ORGID, CRM_FirstName, CRM_LastName, CRM_email)
   select cb.ContactId, cb.AccountID, aeb.New_LMS_OrgID, cb.FirstName, cb.LastName, cb.EmailAddress1
     from CRMsrvr.Nurse_Familypartnership_MSCRM.dbo.contactbase cb
     Left join CRMsrvr.Nurse_Familypartnership_MSCRM.dbo.accountextensionbase aeb
            on cb.AccountID = aeb.AccountID
    where not exists (select xref2.CRM_ContactID
                        from dbo.ETO_CRM_LMS_xref xref2
                       where xref2.CRM_ContactID = cb.ContactID);



----------------------------------------------------------------------------------------
-- Match CRM Records to LMS Students by CRM_ContactID = LMS_Identifier0
----------------------------------------------------------------------------------------
print 'Updating LMS_StudentID xref based on CRM_ContactID in LMS Student record'

update dbo.ETO_CRM_LMS_xref
  set LMS_StudentID = tracker_students.StudentID
     ,LMS_How_Matched = 'CRM_ContactID'
 from dbo.ETO_CRM_LMS_xref xref
 inner join LMSsrvr.Tracker3.dbo.tracker_students tracker_students
         on tracker_students.Identifier0 =  convert(varchar(36),xref.CRM_ContactID)
 where LMS_StudentID is null;

----------------------------------------------------------------------------------------
-- Build and process cursor
----------------------------------------------------------------------------------------
print 'updating remaining xref based upon name match'

DECLARE xrefCursor Cursor for
select xref.Entity_ID
      ,xref.CRM_ContactID
      ,xref.CRM_LMS_OrgID
      ,xref.LMS_StudentID
      ,xref.CRM_LastName
      ,xref.CRM_FirstName
      ,xref.CRM_EMail
  from dbo.ETO_CRM_LMS_xref xref
 where LMS_StudentID is null;

OPEN xrefCursor

FETCH next from XREFCursor
      into @Entity_ID
          ,@CRM_ContactID
          ,@CRM_LMS_OrgID
          ,@LMS_StudentID
          ,@Last_Name
          ,@First_Name
          ,@Email

WHILE @@FETCH_STATUS = 0
BEGIN

   set nocount on
   set @cursor_count = @cursor_count + 1
   set @return_value = 0


   IF @return_value = 0
   BEGIN
--    Try to match on just name / OrgID / email:

      EXEC @return_value = dbo.SP_LMS_Student_Lookup_by_Name @Last_Name,@First_Name,
                       null,@CRM_LMS_OrgID,@Email

      IF @return_Value = 99999999
         BEGIN
            update dbo.ETO_CRM_LMS_xref
               set LMS_Multiple_StudentIDs = 'X'
             where CRM_ContactID = @CRM_ContactID
            set @LMS_mult_count = @LMS_mult_count + 1
         END
      ELSE
      IF @return_Value !=0
         BEGIN
            update dbo.ETO_CRM_LMS_xref
               set LMS_StudentID = convert(int,@return_value)
                  ,LMS_How_Matched = 'by name,orgid,email'
             where CRM_ContactID = @CRM_ContactID
            set @LMS_count = @LMS_count + 1
         END
   END

   IF @return_value = 0
   BEGIN
--    Try to match on just name / OrgID:

      EXEC @return_value = dbo.SP_LMS_Student_Lookup_by_Name @Last_Name,@First_Name,
                       null,@CRM_LMS_OrgID,null

      IF @return_Value = 99999999
         BEGIN
            update dbo.ETO_CRM_LMS_xref
               set LMS_Multiple_StudentIDs = 'X'
             where CRM_ContactID = @CRM_ContactID
            set @LMS_mult_count = @LMS_mult_count + 1
         END
      ELSE
      IF @return_Value !=0
         BEGIN
            update dbo.ETO_CRM_LMS_xref
               set LMS_StudentID = convert(int,@return_value)
                  ,LMS_How_Matched = 'by name, orgid'
             where CRM_ContactID = @CRM_ContactID
            set @LMS_count = @LMS_count + 1
         END
   END

   IF @return_value = 0
   BEGIN
--    Try to match on just name / email:

      EXEC @return_value = dbo.SP_LMS_Student_Lookup_by_Name @Last_Name,@First_Name,
                       null,null,@Email

      IF @return_Value = 99999999
         BEGIN
            update dbo.ETO_CRM_LMS_xref
               set LMS_Multiple_StudentIDs = 'X'
             where CRM_ContactID = @CRM_ContactID
            set @LMS_mult_count = @LMS_mult_count + 1
         END
      ELSE
      IF @return_Value !=0
         BEGIN
            update dbo.ETO_CRM_LMS_xref
               set LMS_StudentID = convert(int,@return_value)
                  ,LMS_How_Matched = 'by name and email'
             where CRM_ContactID = @CRM_ContactID
            set @LMS_count = @LMS_count + 1
         END
   END

   IF @return_value = 0
   BEGIN
--    Try to match on just name:
      EXEC @return_value = dbo.SP_LMS_Student_Lookup_by_Name @Last_Name,@First_Name,
                       null,null,null

      IF @return_Value = 99999999
         BEGIN
            update dbo.ETO_CRM_LMS_xref
               set LMS_Multiple_StudentIDs = 'X'
             where CRM_ContactID = @CRM_ContactID
            set @LMS_mult_count = @LMS_mult_count + 1
          END
      ELSE
        IF @return_Value !=0
          BEGIN
             update dbo.ETO_CRM_LMS_xref
                set LMS_StudentID = convert(int,@return_value)
                    ,LMS_How_Matched = 'by name only'
              where CRM_ContactID = @CRM_ContactID
             set @LMS_count = @LMS_count + 1
           END

   END


----------------------------------------------------------------------------------------
-- continue in cursor
----------------------------------------------------------------------------------------

   FETCH next from XREFCursor
         into @Entity_ID
              ,@CRM_ContactID
              ,@CRM_LMS_OrgID
              ,@LMS_StudentID
              ,@Last_Name
              ,@First_Name
              ,@Email

END -- End of XREFCursor loop

CLOSE XREFCursor
DEALLOCATE XREFCursor


print 'ETO_CRM_LMS_xref Processed: ' +convert(varchar,@cursor_count)
print 'LMS StudentIDs updated:     ' +convert(varchar,@LMS_count)
print 'ETO Entities updated:       ' +convert(varchar,@ETO_count)

PRINT 'End of Procedure: SP_ETO_CRM_LMS_xref'

GO
