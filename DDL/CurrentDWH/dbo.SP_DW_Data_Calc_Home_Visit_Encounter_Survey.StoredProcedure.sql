USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_DW_Data_Calc_Home_Visit_Encounter_Survey]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_DW_Data_Calc_Home_Visit_Encounter_Survey
CREATE PROCEDURE [dbo].[SP_DW_Data_Calc_Home_Visit_Encounter_Survey]
  @p_surveyResponseID int,
  @p_debug_level smallint = 0
AS
-- This script does custom data Calculations for the Home_Visit_Encounter_Survey 
-- ** This is a sub process called from dbo.SP_ETO_to_DW_survey_Responses_Part_B_local **
--
-- Parameters:
--   p_surveyResponseid 
--   p_debug_level = null, 3 
--        (allows ability to display what is being processed, and display sql code
--         null = default display of survey being processed
--         3 = display SQL code

-- History: 
--   20150416 - New SUbpart Procedure.
--              Home_Visit_Encounter: populate Time_Start / Time_End columns
--              based upon individual component columns.
--   20150504 - Added formatting of hours to 2 chars with leading zero.



DECLARE @runtime 	datetime
DECLARE @Process	nvarchar(50)
set @process = 'SP_DW_Data_Calc_Home_Visit_Encounter_Survey'
set @runtime = getdate()

DECLARE @SurveyID	int
DECLARE @SurveyType	nvarchar(10)
DECLARE @DW_TableName	nvarchar(50)
DECLARE @sql            nvarchar(4000)
DECLARE @count		smallint

DECLARE @update_flag                nvarchar(2)
DECLARE @CLIENT_TIME_0_START_VISIT    nvarchar(500)
DECLARE @CLIENT_TIME_1_END_VISIT      nvarchar(500)
DECLARE @CLIENT_TIME_1_DURATION_VISIT nvarchar(500)
DECLARE @CLIENT_TIME_FROM_AMPM  nvarchar(500)
DECLARE @CLIENT_TIME_FROM_HR    nvarchar(500)
DECLARE @CLIENT_TIME_FROM_MIN   nvarchar(500)
DECLARE @CLIENT_TIME_TO_AMPM    nvarchar(500)
DECLARE @CLIENT_TIME_TO_HR      nvarchar(500)
DECLARE @CLIENT_TIME_TO_MIN     nvarchar(500)



IF @p_debug_level = 3
   print 'Start Process: Home_Visit_Encounter_Survey SurveyResponseID=' +ltrim(convert(char,@p_SurveyResponseID))
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
         ,index_1 = @p_SurveyResponseID
         ,index_2 = null
         ,index_3 = null
    where Process = @process

----------------------------------------------------------------------------------------
-- Process for Time calculations
----------------------------------------------------------------------------------------
IF @p_debug_level = 3
   print 'Process Time Calculations'

-- Initialize:
set @update_flag = 'N'
set @CLIENT_TIME_0_START_VISIT = null
set @CLIENT_TIME_1_END_VISIT = null
set @CLIENT_TIME_FROM_AMPM = null
set @CLIENT_TIME_FROM_HR = null
set @CLIENT_TIME_FROM_MIN = null
set @CLIENT_TIME_TO_AMPM = null
set @CLIENT_TIME_TO_HR = null
set @CLIENT_TIME_TO_MIN = null

select @CLIENT_TIME_0_START_VISIT = CLIENT_TIME_0_START_VISIT
      ,@CLIENT_TIME_1_END_VISIT = CLIENT_TIME_1_END_VISIT
      ,@CLIENT_TIME_FROM_AMPM = CLIENT_TIME_FROM_AMPM
      ,@CLIENT_TIME_FROM_HR = CLIENT_TIME_FROM_HR
      ,@CLIENT_TIME_FROM_MIN = CLIENT_TIME_FROM_MIN
      ,@CLIENT_TIME_TO_AMPM = CLIENT_TIME_TO_AMPM
      ,@CLIENT_TIME_TO_HR = CLIENT_TIME_TO_HR
      ,@CLIENT_TIME_TO_MIN = CLIENT_TIME_TO_MIN
  from dbo.Home_Visit_Encounter_Survey
 where SurveyResponseID = @p_surveyResponseID


-- Format Start Time:
IF @CLIENT_TIME_FROM_HR is not null and 
   @CLIENT_TIME_FROM_MIN is not null and
   @CLIENT_TIME_FROM_AMPM is not null
BEGIN
   set @update_flag = 'Y'
   set @CLIENT_TIME_0_START_VISIT = right(replicate('0',2) +@CLIENT_TIME_FROM_HR,2) +':'
                                 +@CLIENT_TIME_FROM_MIN +' '
                                 +@CLIENT_TIME_FROM_AMPM
END

-- Format End Time:
IF @CLIENT_TIME_TO_HR is not null and 
   @CLIENT_TIME_TO_MIN is not null and
   @CLIENT_TIME_TO_AMPM is not null
BEGIN
   set @update_flag = 'Y'
   set @CLIENT_TIME_1_END_VISIT = right(replicate('0',2) +@CLIENT_TIME_TO_HR,2) +':'
                               +@CLIENT_TIME_TO_MIN +' '
                               +@CLIENT_TIME_TO_AMPM
END


IF @update_flag = 'Y'
BEGIN

   IF @p_debug_level = 3
      print 'Updating SurveyResponseID=' +convert(char,@p_SurveyResponseID)
             +', CLIENT_TIME_0_START=' +@CLIENT_TIME_0_START_VISIT
             +', CLIENT_TIME_1_END_VISIT=' +@CLIENT_TIME_1_END_VISIT

   update dbo.Home_Visit_Encounter_Survey
      set CLIENT_TIME_0_START_VISIT = @CLIENT_TIME_0_START_VISIT
         ,CLIENT_TIME_1_END_VISIT   = @CLIENT_TIME_1_END_VISIT
    where SurveyResponseID = @p_SurveyResponseID
END

----------------------------------------------------------------------------------------

set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process

IF @p_debug_level = 3
   print 'End Process: SP_DW_Data_Calc_Home_Visit_Encounter_Survey'
GO
