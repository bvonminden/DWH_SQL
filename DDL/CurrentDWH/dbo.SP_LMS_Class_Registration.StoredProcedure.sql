USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_LMS_Class_Registration]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--drop proc dbo.SP_LMS_Class_Registration
CREATE procedure [dbo].[SP_LMS_Class_Registration]
 (@p_Entity_ID        int,
  @p_StudentID        int,
  @p_ClassName        nvarchar(100),
  @p_Reason           nvarchar(100),
  @p_validate_field   nvarchar(30) = null,
  @SurveyResponseID   int = null)
AS
-- This procedure will attemt to Register a student into an LMS Class
--
-- Accepts p_validate_field to validate either on 'CLASSNAME' or 'CLASSDESCRIPTION'
-- defaulting to 'CLASSNAME'.
--
-- History:
--   20110419: Added validation to not register for a previously registered course.

-- References DB LMSSRVR.Tracker3

DECLARE @Process	nvarchar(50)
set @process = 'SP_LMS_CLASS_REGISTRATION'

DECLARE @count		smallint
DECLARE @insert_count		smallint
DECLARE @update_count		smallint
DECLARE @bypassed_count		smallint
DECLARE @cursor_count		smallint
set @insert_count = 0
set @update_count = 0
set @bypassed_count = 0
set @cursor_count = 0


DECLARE @New_ClassStudentAssignmentID	int
DECLARE @New_StudentAssignmentID	int
DECLARE @New_StudentCourseID		int
DECLARE @ClassID			int
DECLARE @CourseID			int


DECLARE @SQL            nvarchar(2000)
DECLARE @bypass_flag    nvarchar(10)
DECLARE @return_id      nvarchar(36)
DECLARE @qualified_ctr  smallint
DECLARE @return_value   nvarchar(50)

SET @return_id = null
SET @qualified_ctr = 0

--print 'Begin Procedure: SP_LMS_Class_Registration'

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
-- Validate this student exists in LMS
----------------------------------------------------------------------------------------
set @bypass_flag = 'N';
set @count = 0
 select @count = count(*) 
   from LMSSRVR.Tracker3.dbo.Tracker_Students
  where StudentID = @p_studentid;

IF @count = 0
BEGIN
--  Student does not exist
    set @bypass_Flag = 'Y'
    
    insert into LMS_ClassReg_Log
                (Entity_ID, LogDate, StudentID, ClassName, Validation_Ind, Comment,SurveyResponseID)
         Values (@p_Entity_ID, getdate(), @p_StudentID, @p_ClassName, 'ERROR',
                'StudentID does not exist in LMS, Student not assigned',@SurveyResponseID)
END

----------------------------------------------------------------------------------------
-- Validate this class exists in LMS
----------------------------------------------------------------------------------------
  set @bypass_flag = 'N';
  set @count = 0

-- Validate that only one unique class / course combination exists
IF @p_validate_field = 'CLASSDESCRIPTION'
   BEGIN
   select @count = count(*) 
     from LMSSRVR.Tracker3.dbo.Tracker_Classes Tracker_Classes
    where convert(varchar,Tracker_Classes.ClassDescription) = @P_ClassName;
   END
ELSE
   BEGIN
   select @count = count(*) 
     from LMSSRVR.Tracker3.dbo.Tracker_Classes Tracker_Classes
    where Tracker_Classes.ClassName = @P_ClassName;
   END

IF @count = 0
BEGIN
--  COurse does not exist
    set @bypass_Flag = 'Y'
    
    insert into LMS_ClassReg_Log
                (Entity_ID, LogDate, StudentID, ClassName, Validation_Ind, Comment,SurveyResponseID)
         Values (@p_Entity_ID, getdate(), @p_StudentID, @p_ClassName, 'ERROR',
                'Class does not exist in LMS, Student not assigned',@SurveyResponseID)
END

IF @count > 1
BEGIN
--  More than one class defined
    set @bypass_Flag = 'Y'
    
    insert into LMS_ClassReg_Log
                (Entity_ID, LogDate, StudentID, ClassName, Validation_Ind, Comment,SurveyResponseID)
         Values (@p_Entity_ID, getdate(), @p_StudentID, @p_ClassName, 'ERROR',
                'More than one class exists in LMS, Student not assigned',@SurveyResponseID)
END


  IF @bypass_flag = 'N'
  BEGIN

----------------------------------------------------------------------------------------
-- Create ClassStudentAssignment record
----------------------------------------------------------------------------------------

--     Build the next available Record ID:
       Select @New_ClassStudentAssignmentID = max(ClassStudentAssignmentID) + 1 
         from LMSSRVR.Tracker3.dbo.Tracker_ClassStudentAssignment

--     Get ClassID:
       IF @p_validate_field = 'CLASSDESCRIPTION'
          BEGIN
             select @classid = Tracker_Classes.classid
               from LMSSRVR.Tracker3.dbo.Tracker_Classes Tracker_Classes
              where convert(varchar,Tracker_Classes.ClassDescription) = @P_ClassName;
           END
       ELSE
          BEGIN
             select @classid = Tracker_Classes.classid
               from LMSSRVR.Tracker3.dbo.Tracker_Classes Tracker_Classes
              where Tracker_Classes.ClassName = @P_ClassName;
           END


--     Validation to see if class had already been registered in the past:
       set @count = 0
       select @count = count(*) 
         from LMSSRVR.Tracker3.dbo.Tracker_ClassStudentAssignment
        where ClassID = @ClassID
          and StudentID = @p_StudentID;

       IF @count > 0
          BEGIN
             insert into LMS_ClassReg_Log
                (Entity_ID, LogDate, StudentID, ClassName, Validation_Ind, Comment,SurveyResponseID)
             Values (@p_Entity_ID, getdate(), @p_StudentID, @p_ClassName, 'ERROR',
                'DUPLICATE Entity Registration, Student not assigned',@SurveyResponseID)
          END
       ELSE

          BEGIN
             
             insert into LMSSRVR.Tracker3.dbo.Tracker_ClassStudentAssignment
                      (ClassID
                      ,StudentID)
               values (@ClassID
                      ,@p_StudentID);

             insert into LMS_ClassReg_Log
                (Entity_ID, LogDate, StudentID, ClassName,  Validation_Ind, Comment,SurveyResponseID)
                Values (@p_Entity_ID, getdate(), @p_StudentID, @p_ClassName,
                      'OK','Student Assigned to Class',@SurveyResponseID)

             IF @p_reason is not null
             BEGIN
                update LMSSRVR.Tracker3.dbo.tracker_students
                   set Identifier5 = @p_reason
                 where StudentID = @p_studentID;
             END

          END -- end insert new ClassStudentAssignment


  END -- validity check 'Bypass_flag'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------
--PRINT 'End of Procedure: SP_LMS_Class_Registration'
GO
