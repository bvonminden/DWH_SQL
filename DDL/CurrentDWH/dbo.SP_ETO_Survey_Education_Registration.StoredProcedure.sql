USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_ETO_Survey_Education_Registration]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_ETO_Survey_Education_Registration
--
CREATE PROCEDURE [dbo].[SP_ETO_Survey_Education_Registration]
AS
--
-- This process reads the Education_Registration_Survey Table and attemts to register
-- into LMS.  Updates Validation_Ind as processed.

-- History
--   20111020 - Changed to no longer update CRM.New_ProgramStaffRole with reson for education.
--              New CRM Field is now New_educationattendance.
--   20160407 - Added additional info to display statements to help troubleshooting.
--              Added conditional lookup of LMS Class bassed upon classid supplied in survey (from AgencyDB).

print 'Begin Procedure: SP_ETO_Survey_Education_Registration'

DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_ETO_SURVEY_EDUCATION_REGISTRATION'

DECLARE @insert_count		smallint
DECLARE @update_count		smallint
DECLARE @bypassed_count		smallint
DECLARE @cursor_count		smallint
set @insert_count = 0
set @update_count = 0
set @bypassed_count = 0
set @cursor_count = 0

DECLARE @SurveyID		int
DECLARE @SurveyResponseID	int
DECLARE @Entity_ID		int
DECLARE @LMS_StudentID		int
DECLARE @CRM_ContactID		uniqueidentifier
DECLARE @SurveyName		nvarchar(80)
DECLARE @Reason_for_Educ	nvarchar(80)
DECLARE @ClassName		nvarchar(80)
DECLARE @ClassID		int
DECLARE @Weight			int
DECLARE @validate_field		nvarchar(30)


set nocount on

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
-- Build an API cursor of new Completed Courses
----------------------------------------------------------------------------------------
DECLARE SurveyCursor Cursor for
Select surv.SurveyResponseID
      ,MS.SurveyID
      ,MS.SurveyName
      ,surv.CL_EN_GEN_ID
      ,IA_Staff.LMS_StudentID
      ,surv.EDUC_REGISTER_0_REASON
      ,IA_Staff.CRM_ContactID
      ,CASE when isnumeric(EDUC_REGISTER_0_REASON) = 1
            then EDUC_REGISTER_0_REASON
            else dbo.FN_Survey_Element_Choice_Seq(surv.SurveyID,'EDUC_REGISTER_0_REASON'
                                       ,EDUC_REGISTER_0_REASON,'x')
            END as Weight
      ,surv.LMS_classid
  from dbo.Education_Registration_Survey surv
  left Join dbo.Mstr_Surveys MS
         on surv.SurveyID = MS.SurveyID
  left Join dbo.IA_Staff
         on surv.CL_EN_GEN_ID = IA_Staff.Entity_ID
 where Validation_Ind is null
   and IA_Staff.LMS_StudentID is not null;

OPEN SurveyCursor

FETCH next from SurveyCursor
      into @SurveyResponseID
          ,@SurveyID
          ,@SurveyName
          ,@Entity_ID
          ,@LMS_StudentID
          ,@Reason_for_Educ
          ,@CRM_ContactID
          ,@Weight
          ,@ClassID


WHILE @@FETCH_STATUS = 0
BEGIN

   set @cursor_count = @cursor_count + 1

   If @classid is not null 
     BEgin
      set @validate_field = 'CLASSNAME'
      -- retrieve classname via supplied classid:
      select @ClassName = ClassName
        from lmssrvr.tracker3.dbo.tracker_classes
       where ClassID = @ClassID
     END
   ELSE
   BEGIN
      set @validate_field = 'CLASSDESCRIPTION'
   -- Build the classname from the Survey Name
   -- Survey Name is prefixed as 'Education Registration: '
   -- expecting the actual course name to begin in position 24:
      set @ClassName = substring(@SurveyName,25,LEN(@SurveyName))

   -- Verify if Class actually exists in LMS:
      select @ClassID = ClassID
        from lmssrvr.tracker3.dbo.tracker_classes
       where convert(varchar,ClassDescription) = @ClassName
   END

   print 'class validation for Entity_ID=' +convert(varchar,@Entity_ID) +', SurveyResponseID=' +convert(varchar,@SurveyResponseID)
          +', ClassName=' +@ClassName +', LMS ClassID=' +isnull(convert(varchar,@ClassID),'')

   Print 'executing SP_LMS_Class_Registration '+convert(varchar,@Entity_ID) +', ' +convert(varchar,@LMS_StudentID)
          +', ' +convert(varchar,@ClassName) +', ' +@Reason_for_Educ +', ''CLASSDESCRIPTION'', ' +convert(varchar,@SurveyResponseID)

   IF @ClassID is not null
      BEGIN
      exec SP_LMS_Class_Registration @Entity_ID, @LMS_StudentID, @ClassName, @Reason_for_Educ, @validate_field, @SurveyResponseID

--    Update Survey validation as processed:
      update dbo.Education_Registration_Survey
         set Validation_Ind = 'x'
            ,ClassName = @ClassName
            ,LMS_ClassID = isnull(LMS_ClassID,@ClassID)
       where SurveyResponseID = @SurveyResponseID
      END


--    Update CRM with the Reason for Education:
      IF @CRM_ContactID is not null and
         @Weight is not null
      BEGIN
         set nocount on 
         update CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase
            set New_educationattendance = @weight
          where ContactExtensionBase.ContactID = @CRM_ContactID 
      END


   FETCH next from SurveyCursor
         into @SurveyResponseID
             ,@SurveyID
             ,@SurveyName
             ,@Entity_ID
             ,@LMS_StudentID
             ,@Reason_for_Educ
             ,@CRM_ContactID
             ,@Weight
             ,@ClassID


END -- End of SurveyCursor loop

CLOSE SurveyCursor
DEALLOCATE SurveyCursor

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

print 'New Education Registrations Processed: ' +convert(varchar,@cursor_count)
PRINT 'End of Procedure: SP_ETO_Survey_Education_Registration'
GO
