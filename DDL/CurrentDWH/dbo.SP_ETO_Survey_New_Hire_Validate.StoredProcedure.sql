USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_ETO_Survey_New_Hire_Validate]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_ETO_Survey_New_Hire_Validate
--
CREATE PROCEDURE [dbo].[SP_ETO_Survey_New_Hire_Validate]
AS
--
-- This process reads the New Hire Survey, making preliminary validations,
-- such as existing Enitity, emails, etc. 

Print 'StartingSP_ETO_Survey_New_Hire_Validate'

DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_ETO_SURVEY_NEW_HIRE_VALIDATE'

DECLARE @Entity_ID		int
DECLARE @SurveyResponseID	int
DECLARE @SurveyID		int
DECLARE @SurveyDate		datetime
DECLARE @SiteID			int
DECLARE @NEW_HIRE_NAME_FIRST	nvarchar(100)
DECLARE @NEW_HIRE_NAME_LAST	nvarchar(100)
DECLARE @NEW_HIRE_EMAIL		nvarchar(200)
DECLARE @NEW_HIRE_REASON_FOR_HIRE 	nvarchar(100)
DECLARE @NEW_HIRE_PREVIOUS_NFP_WORK	nvarchar(100)
DECLARE @NEW_HIRE_SUP_EMAIL	nvarchar(100)
DECLARE @NEW_HIRE_SUP_NAME	nvarchar(100)
DECLARE @NEW_HIRE_TEAM_NAME	nvarchar(100)
declare @indx			int

DECLARE @Validation_Ind		nvarchar(10)
DECLARE @Validation_Comment	nvarchar(100)
DECLARE @return_stat        	int

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
-- Build and process cursor for New Hires
----------------------------------------------------------------------------------------
DECLARE NewHireCursor Cursor for
select SurveyResponseID
      ,SurveyID
      ,SurveyDate
      ,SiteID
      ,NEW_HIRE_1_NAME_FIRST
      ,NEW_HIRE_0_NAME_LAST
      ,NEW_HIRE_0_EMAIL
      ,NEW_HIRE_0_REASON_FOR_HIRE
      ,NEW_HIRE_0_PREVIOUS_NFP_WORK
      ,NEW_HIRE_SUP_0_EMAIL
      ,NEW_HIRE_SUP_0_NAME
      ,NEW_HIRE_0_TEAM_NAME
  from dbo.New_hire_Survey 
 where Validation_Ind is null;

OPEN NewHireCursor

FETCH next from NewHireCursor
      into @SurveyResponseID
          ,@SurveyID
          ,@SurveyDate
          ,@SiteID
          ,@NEW_HIRE_NAME_FIRST
          ,@NEW_HIRE_NAME_LAST
          ,@NEW_HIRE_EMAIL
          ,@NEW_HIRE_REASON_FOR_HIRE
          ,@NEW_HIRE_PREVIOUS_NFP_WORK
          ,@NEW_HIRE_SUP_EMAIL
          ,@NEW_HIRE_SUP_NAME
          ,@NEW_HIRE_TEAM_NAME

WHILE @@FETCH_STATUS = 0
BEGIN

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Validation survey responseID'
      ,Index_1 = @SurveyResponseID
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------
   set nocount on
   set @Validation_Ind = null
   set @Validation_Comment = null


------------
-- Errors:
------------


   IF @Validation_Ind is null
   BEGIN
--    Validate on LastName, FirstName, Email - Error if found:
      set @Entity_id = null
      select @Entity_ID = Entity_ID
        from dbo.IA_Staff
       where Last_Name = @NEW_HIRE_NAME_LAST
         and First_Name = @NEW_HIRE_NAME_FIRST
         and Email = @NEW_HIRE_EMAIL;

      IF @Entity_ID is not null and
        upper(@NEW_HIRE_PREVIOUS_NFP_WORK) != 'YES'
      BEGIN
         set @Validation_Ind = 'ERROR'
         set @Validation_Comment = 'Duplicate Name, Email; Entity_ID='
                  +convert(varchar,@Entity_ID)
      END
   END  -- end single validation


   IF @Validation_Ind is null
   BEGIN
--    Validate Email has been supplied:
      IF @NEW_HIRE_EMAIL is null
      BEGIN
         set @Validation_Ind = 'ERROR'
         set @Validation_Comment = 'New Hire Email has not been supplied'
      END
   END  -- end single validation


   IF @Validation_Ind is null
   BEGIN
--    Validate Email contains '@'
      IF PATINDEX ( '%@%' ,@NEW_HIRE_SUP_EMAIL ) = 0
      BEGIN
         set @Validation_Ind = 'ERROR'
         set @Validation_Comment = 'New Hire Email does not contain @ sign'
      END
   END  -- end single validation


   IF @Validation_Ind is null
   BEGIN
--    Validate Supervisor Email has been supplied:
      IF @NEW_HIRE_SUP_EMAIL is null
      BEGIN
         set @Validation_Ind = 'ERROR'
         set @Validation_Comment = 'Supervisor Email has not been supplied'
      END
   END  -- end single validation


   IF @Validation_Ind is null
   BEGIN
--    Validate Email Addresses are different:
      IF isnull(@NEW_HIRE_EMAIL,'XX') = isnull(@NEW_HIRE_SUP_EMAIL,'YY')
      BEGIN
         set @Validation_Ind = 'Error'
         set @Validation_Comment = 'New Hire and Supervisor Emails are the same'
      END
   END  -- end single validation


------------
-- Warnings:
------------

   IF @Validation_Ind is null
   BEGIN
--    Validate Email domains are the same between New Hire and Supervisor:
      IF substring(@NEW_HIRE_EMAIL,charindex('@',@NEW_HIRE_EMAIL)+1,LEN(@NEW_HIRE_EMAIL)) != 
         substring(@NEW_HIRE_SUP_EMAIL,charindex('@',@NEW_HIRE_SUP_EMAIL)+1,LEN(@NEW_HIRE_SUP_EMAIL))
      BEGIN
         set @Validation_Ind = 'Warning'
         set @Validation_Comment = 'Email Domain is not the same between New Hire and Supervisor'
      END
   END  -- end single validation


   IF @Validation_Ind is null
   BEGIN
--    Set warning if found to be a re-hire:
      IF upper(@NEW_HIRE_TEAM_NAME) is null
      BEGIN
         set @Validation_Ind = 'Warning'
         set @Validation_Comment = 'No Team Name Identified'
      END
   END  -- end single validation


   IF @Validation_Ind is null
   BEGIN
--    Set warning if found to be a replacement hire:
      set @indx = 0
      select @indx = charindex('REPLACEMENT',upper(@NEW_HIRE_REASON_FOR_HIRE))
      IF @indx > 0
      BEGIN
         set @Validation_Ind = 'Warning'
         set @Validation_Comment = 'Hired as a replacement'
      END
   END  -- end single validation


   IF @Validation_Ind is null
   BEGIN
--    Set warning if found to be a re-hire:
      IF upper(@NEW_HIRE_PREVIOUS_NFP_WORK) = 'YES'
      BEGIN
         set @Validation_Ind = 'Warning'
         set @Validation_Comment = 'Found to be a Re-Hire'
      END
   END  -- end single validation


   IF @Validation_Ind is null
   BEGIN
--    Validate on LastName, FirstName, - Warning if found:
      select @count = count(*)
        from dbo.IA_Staff
       where Last_Name = @NEW_HIRE_NAME_LAST
         and First_Name = @NEW_HIRE_NAME_FIRST;

      IF @count != 0
      BEGIN
         set @Validation_Ind = 'Warning'
         set @Validation_Comment = 'Duplicate(s) First/Last Name found'
      END
   END  -- end single validation


   IF @Validation_Ind is null
   BEGIN
--    Set warning if Supervisor not supplied:
      IF upper(@NEW_HIRE_SUP_NAME) is null
      BEGIN
         set @Validation_Ind = 'Warning'
         set @Validation_Comment = 'Supervisor Name not supplied'
      END
   END  -- end single validation




--------------------------------------------
-- Continue:
--------------------------------------------

   IF @Validation_Ind is null
      set @Validation_Ind = 'Validated'

   Update New_Hire_Survey
      set Validation_Ind = @Validation_Ind
         ,Validation_Comment = @Validation_Comment
    where SurveyResponseID = @SurveyResponseID;

   FETCH next from NewHireCursor
         into @SurveyResponseID
             ,@SurveyID
             ,@SurveyDate
             ,@SiteID
             ,@NEW_HIRE_NAME_FIRST
             ,@NEW_HIRE_NAME_LAST
             ,@NEW_HIRE_EMAIL
             ,@NEW_HIRE_REASON_FOR_HIRE
             ,@NEW_HIRE_PREVIOUS_NFP_WORK
             ,@NEW_HIRE_SUP_EMAIL
             ,@NEW_HIRE_SUP_NAME
             ,@NEW_HIRE_TEAM_NAME

END -- End of NewHireCursor loop

CLOSE NewHireCursor
DEALLOCATE NewHireCursor

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------
Print 'Completed SP_ETO_Survey_New_Hire_Validate'
GO
