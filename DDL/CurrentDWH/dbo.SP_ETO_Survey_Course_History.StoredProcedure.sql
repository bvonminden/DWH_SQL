USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_ETO_Survey_Course_History]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_ETO_Survey_Course_History
--
CREATE PROCEDURE [dbo].[SP_ETO_Survey_Course_History]
AS
--
-- This process reads the ETO Completed_Courses_Survey table to update the Sync_Phase
-- in the DW_Completed_Courses table as successfully process through ETO.

-- Sync_PHases:
--   null - New Completed Course
--   1    - Extracted to API for ETO Survey Update
--   2    - Success Survey Received from ETO

print 'Begin Procedure: SP_ETO_Survey_Course_History'

DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_ETO_SURVEY_COURSE_HISTORY'

DECLARE @insert_count		smallint
DECLARE @update_count		smallint
DECLARE @bypassed_count		smallint
DECLARE @cursor_count		smallint
set @insert_count = 0
set @update_count = 0
set @bypassed_count = 0
set @cursor_count = 0

DECLARE @RecID	int
DECLARE @SurveyResponseID	int
DECLARE @Entity_ID		int
DECLARE @Course_Name		nvarchar(80)
DECLARE @Completion_date	datetime


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
Select CCS.SurveyResponseID
      ,CCS.CL_EN_GEN_ID
      ,CCS.Course_Completion_0_Name111
      ,CCS.Course_Completion_0_Date111
  from dbo.Course_Completion_Survey CCS
 where not exists (select SurveyResponseID
                     from dbo.DW_Completed_Courses DWCC
                    where DWCC.ETO_SurveyResponseID = CCS.SurveyResponseID);

OPEN SurveyCursor

FETCH next from SurveyCursor
      into @SurveyResponseID
          ,@Entity_ID
          ,@Course_Name
          ,@Completion_Date


WHILE @@FETCH_STATUS = 0
BEGIN

   set @cursor_count = @cursor_count + 1

   select @RecID = RecID from dbo.DW_Completed_Courses
    where Entity_ID = @Entity_ID
      and Course_Name = @Course_Name
      and convert(varchar(8),Completion_Date,112) = convert(varchar(8),@Completion_Date,112);

    IF @RecID is not null
       BEGIN
       update dbo.DW_Completed_Courses
          set Sync_Phase = '2'
             ,ETO_SurveyResponseID = @SurveyResponseID
        where RecID = @RecID
       END

   FETCH next from SurveyCursor
         into @SurveyResponseID
             ,@Entity_ID
             ,@Course_Name
             ,@Completion_Date


END -- End of SurveyCurso loop

CLOSE SurveyCursor
DEALLOCATE SurveyCursor

print 'New Completed Courses Processed: ' +convert(varchar,@cursor_count)

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

PRINT 'End of Procedure: SP_ETO_Survey_Course_History'
GO
