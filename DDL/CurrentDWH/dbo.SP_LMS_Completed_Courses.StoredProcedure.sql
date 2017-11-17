USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_LMS_Completed_Courses]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_LMS_Completed_Courses
CREATE procedure [dbo].[SP_LMS_Completed_Courses]
 (@p_date_since   smalldatetime = null)
AS
-- This procedure will extract newly completed LMS Courses

-- References DB: LMSSRVR.Tracker3, CRMSRVR.Nurse_FamilyPartnership_MSCRM

-- History:
--   20111104 - Added truncation to dw.reason for education setting to 40 chars.
--   20130826 - Added new field to hold the actual LMS Course LongName 'LMS_LongName'
--              Added new field to hold the what is calculated for CRM course_name 'LMS_Comments'.
--   20140529 - Added qualifier to update completed courses for non-disabled IA_Staff records.  This 
--              removes the confusion if historical records exist for another site/entity.
--   20150828 - Added additional qualifying condition to inserting completed courses 
--              based upon IA_Staff CRM_ContactID is not null.  
--              This is to prevent needless updates to secondary ETO staff records.
--   20150910 - Added the IA_Staff validation matchup to disregard staff record when flag_Transfer != 0.
--              This is to allow another staff record to take precedence in receiving history.
--   20170707 - Updated to set course# 15 in CRM. Was being applied to course 14.

DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_LMS_COMPLETED_COURSES'

DECLARE @date_since		smalldatetime
set  @date_since = isnull(@p_date_since,convert(varchar,getdate(),112))

DECLARE @RecID			int
DECLARE @Entity_id		int
DECLARE @LMS_StudentCourseID	int
DECLARE @Course_Name		nvarchar(40)
DECLARE @Completion_date	datetime	
DECLARE @ContactID		uniqueidentifier
DECLARE @CourseNbr		smallint
DECLARE @SQL			nvarchar(4000)

DECLARE @new_course1		nvarchar(40)
DECLARE @new_course2		nvarchar(40)
DECLARE @new_course3		nvarchar(40)
DECLARE @new_course4		nvarchar(40)
DECLARE @new_course5		nvarchar(40)
DECLARE @new_course6		nvarchar(40)
DECLARE @new_course7		nvarchar(40)
DECLARE @new_course8		nvarchar(40)
DECLARE @new_course9		nvarchar(40)
DECLARE @new_course10		nvarchar(40)
DECLARE @new_course11		nvarchar(40)
DECLARE @new_course12		nvarchar(40)
DECLARE @new_course13		nvarchar(40)
DECLARE @new_course14		nvarchar(40)
DECLARE @new_course15		nvarchar(40)
DECLARE @new_course16		nvarchar(40)


print 'Begin Procedure: SP_LMS_Completed_Courses since: ' +convert(varchar,@date_since,120)

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
-- Add new LMS Completed Courses to the DW table
----------------------------------------------------------------------------------------
-- Insert into the DW_Completed_Courses Table:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New DW Completed Courses'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

insert into dbo.DW_Completed_Courses
       (Entity_id, LMS_StudentCourseID, Course_Name, Completion_date, 
        Reason_For_Education, LMS_LongName, LMS_Comments)
       Select IA_Staff.Entity_ID
             ,SCI.StudentCourseID
             ,left(isnull((case when convert(varchar,TC.CommentsForStudents) = '' 
                                then TC.LongName 
                                else convert(varchar,TC.CommentsForStudents) END),
                          TC.LongName),40)
             ,SCI.MostRecentCompletionDate
             ,left(students.Identifier5,40)
             ,TC.LongName
             ,left(isnull((case when convert(varchar,TC.CommentsForStudents) = '' 
                                then TC.LongName 
                                else convert(varchar,TC.CommentsForStudents) END),
                          TC.LongName),40)
         from dbo.IA_Staff
         inner join LMSSRVR.Tracker3.dbo.Tracker_StudentCourseInformation SCI
                 on IA_Staff.LMS_StudentID = SCI.StudentID
         inner join LMSSRVR.Tracker3.dbo.Tracker_Courses TC
               on SCI.CourseID = TC.CourseID
         inner join LMSSRVR.Tracker3.dbo.Tracker_Students students
                 on IA_Staff.LMS_StudentID = students.StudentID
        where IA_Staff.LMS_StudentID is not null
          and IA_Staff.Disabled = 0
          and IA_Staff.CRM_ContactID is not null
          and isnull(IA_Staff.flag_Transfer,0) = 0
          and SCI.MostRecentCompletionDate > @date_since
          and not exists (select LMS_StudentCourseID 
                            from dbo.DW_Completed_Courses DWCC
                           where DWCC.LMS_StudentCourseID = SCI.StudentCourseID);


----------------------------------------------------------------------------------------
-- Flag DW Completed Courses that are no longer identified as completed in LMS
----------------------------------------------------------------------------------------

/*
Update dbo.DW_Completed_Courses
       set Completion_date = SCI.MostRecentCompletionDate
  from from LMSSRVR.Tracker3.Tracker_studentCourseInformation SCI
  inner join dbo.DW_Completed_Courses DWCC
          on DWCC.StudentCourseID = SCI.StudentCourseID
  Where SCI.MostRecentCompletionDate > @date_since
    and SCI.MostRecentCompletionDate != DWCC.Completion_Date;

*/

----------------------------------------------------------------------------------------
-- Push LMS completed course to CRM
----------------------------------------------------------------------------------------

DECLARE CourseCursor Cursor for
select DWCC.RecID
      ,DWCC.Entity_id
      ,DWCC.LMS_StudentCourseID
      ,DWCC.Course_Name
      ,DWCC.Completion_date
      ,IA_STAFF.CRM_ContactID
  from dbo.DW_Completed_Courses DWCC
  inner join IA_Staff
    on DWCC.Entity_ID = IA_Staff.Entity_ID
 where DWCC.CRM_Course_Nbr is null
   and DWCC.ContactID is null
   and DWCC.COurse_Name != ''
   and DWCC.LMS_StudentCourseID is not null
   and IA_Staff.CRM_COntactID is not null

OPEN CourseCursor

FETCH next from CourseCursor
      into @RecID
          ,@Entity_ID
          ,@LMS_StudentCourseID
          ,@Course_Name
          ,@Completion_date
          ,@ContactID


WHILE @@FETCH_STATUS = 0
BEGIN


   select @new_course1 = New_Course1,   @new_course2 = New_Course2
         ,@new_course3 = New_Course3,   @new_course4 = New_Course4
         ,@new_course5 = New_Course5,   @new_course6 = New_Course6
         ,@new_course7 = New_Course7,   @new_course8 = New_Course8
         ,@new_course9 = New_Course9,   @new_course10 = New_Course10
         ,@new_course11 = New_Course11, @new_course12 = New_Course12
         ,@new_course13 = New_Course13, @new_course14 = New_Course14
         ,@new_course15 = New_Course15, @new_course16 = New_Course16
     from CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase ContactExtensionBase
    where ContactID = @ContactID

    IF @new_course1 is null
       set @CourseNbr=1
    ELSE IF @new_course2 is null
       set @CourseNbr=2
    ELSE IF @new_course3 is null
       set @CourseNbr=3
    ELSE IF @new_course4 is null
       set @CourseNbr=4
    ELSE IF @new_course5 is null
       set @CourseNbr=5
    ELSE IF @new_course6 is null
       set @CourseNbr=6
    ELSE IF @new_course7 is null
       set @CourseNbr=7
    ELSE IF @new_course8 is null
       set @CourseNbr=8
    ELSE IF @new_course9 is null
       set @CourseNbr=9
    ELSE IF @new_course10 is null
       set @CourseNbr=10
    ELSE IF @new_course11 is null
       set @CourseNbr=11
    ELSE IF @new_course12 is null
       set @CourseNbr=12
    ELSE IF @new_course13 is null
       set @CourseNbr=13
    ELSE IF @new_course14 is null
       set @CourseNbr=14
    ELSE IF @new_course15 is null
       set @CourseNbr=15
    ELSE IF @new_course16 is null
       set @CourseNbr=16

    set @SQL= ' update CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase
          set New_Course' +convert(varchar,@courseNbr) +' = ''' +@Course_Name +'''
          , New_Course' +convert(varchar,@courseNbr) +'CompletionDate = ''' 
          +convert(varchar,dateadd(hour,7,@Completion_date)) +'''
        where ContactID = ''' +convert(varchar(36),@ContactID,126) +''''
   -- print @SQL
    exec (@SQL)

    update dbo.DW_Completed_Courses
       set ContactID = @COntactID
          ,CRM_Course_Nbr = @CourseNbr
     where RecID = @RecID


   FETCH next from CourseCursor
         into @RecID
             ,@Entity_ID
             ,@LMS_StudentCourseID
             ,@Course_Name
             ,@Completion_date
             ,@ContactID

END -- End of CourseCursor loop

CLOSE CourseCursor
DEALLOCATE CourseCursor

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

PRINT 'End of Procedure: SP_LMS_Completed_Courses'
GO
