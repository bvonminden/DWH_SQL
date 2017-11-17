USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_ETO_Copy_SurveyResponses]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_ETO_Copy_SurveyResponses
--
CREATE PROCEDURE [dbo].[SP_ETO_Copy_SurveyResponses]
 (@p_auditdate_override  datetime = null,
  @p_restart  varchar = null)
AS
--
-- This script controls copying of ETO Survey Response tables
-- Only inserting what does not already exist, deleteting what does not exist in ETO.
--
-- ** Survey responses are never updated in ETO, only deleted and re-added as new response **
--
-- Tables effected
--    etosolaris.dbo.Survey_ElementResponses
--    etosolaris.dbo.Survey_ElementResponseArbText
--    etosolaris.dbo.Survey_ElementResponseNumeric
--    etosolaris.dbo.Survey_ElementResponseBoolean
--    etosolaris.dbo.Survey_ElementResponseChoice
--    etosolaris.dbo.Survey_ElementResponseDate
--    etosolaris.dbo.Survey_ElementResponseECR
--    etosolaris.dbo.Survey_ElementResponsePCR
--    etosolaris.dbo.Survey_ElementResponseFileAttachment
--    etosolaris.dbo.Survey_ElementResponseImage
--
-- History:
--   20110126: fixed deletion phase for a better qualifier.
--   20111010 - Updated for ETO upgrade, replacing SurveyElementResponseText table with
--              dbo.SurveyElementResponseNumeric for Numeric fields
--              dbo.SurveyElementResponseArbText for text fields.
--   20120117 - Set Temporary hold on deleting surveys until full re-sync.
--   20120118 - Added a window of time (30 minutes) to exclude any survey with an auditdate within window of time.
--              This is an attenpt to exclude half entered survey responses which are still open at the time of integration.
--              Changed process to first evaluate the survey responses not yet existing in the local etosolaris,
--              then process all response elements for each.
--   20120120 - Rework for better performance through the VPN.
--   20131221 - Added parameter to specify a specific audit date for use in recover of lost records.
--              Increased window of search days for new responses, from 1 day to 10 days.
--   20140318 - Changed IP address for SSI server update.
--   20150330 - Changed IP address for new SSI server.
--   20150402 - Reformat of queries trying to optimise the selection coming from SSI / VPN.
--              Also added step updates to the New_SurveyResponses_from_ETO table to assist in ssis pkg restarts
--              so that the same surveyresponse is not processed twice for each subsequent child table.
--              Will set the New_SurveyResponses_from_ETO.Processed bit, indicating completed all steps.
--   20150408 - Added a re-start parameter to bypass the initial load of new surveys from ETO, thus
--              to process only the previously identified records in dbo.New_SurveyResponses_from_ETO.
--   20170327 - Changed IP Address for new AWS Server 10.35.1.129.

DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_ETO_COPY_SURVEYREPSPONSES'

DECLARE @last_AuditDate datetime
DECLARE @Date_Window    datetime
DECLARE @Records_Processed int
DECLARE @Step_nbr       int

-- set window of time to exclude from integration (add 2 hours between EST (SSI)/ MST (NFP), subtract 30 minutes)
select @Date_Window = dateadd(MINUTE,-30,dateadd(HOUR,2,GETDATE()))

set @Records_Processed = 0


-- 1 = Non Exclusive Choice - SurveyElementChoices ,SurveyElementResponseChoice?
-- 2 = Exclusive Choice - SurveyElementChoices
-- 3, 4 = Arbitrary Prose - SurveyElementResponseArbText
-- 6, 7, 8 = Percent/Money/Number - SurveyElementResponseNumeric
-- 9 = Boolean - SurveyElementResponseBoolean 
-- 10 = Date - SurveyElementResponseDate
-- 11 = PCR - SurveyElementResponsePCR
-- 12 = ECR - SurveyElementResponseECR


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

IF isnull(@p_restart,'N') = 'Y'
   BEGIN
   print 'restarting w/o initial load of New SurveyResponses'
   END
ELSE
BEGIN 

----------------------------------------------------------------------------------------
print 'Processing SP_ETO_Copy_SurveyResponses - loading table: New_SurveyResponses_from_ETO'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = ' New_SurveyResponses_from_ETO'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------
-- Prepare table of new survey responses to download from ETO via the vpn
set @Step_nbr = 0

delete dbo.New_SurveyResponses_from_ETO
 where processed = 1

IF @p_auditdate_override is null 
   select @last_auditdate = dateadd(day,-10,MAX(auditdate)) from etosolaris.dbo.SurveyResponses
ELSE
  BEGIN
   set @date_window = @p_auditdate_override
   set @last_Auditdate = dateadd(day,-10,@p_auditdate_override)
  END

--print convert(varchar,@p_auditdate_override) +', ' +convert(varchar,@date_window) +', ' +convert(varchar,@last_auditdate)

insert into dbo.New_SurveyResponses_from_ETO
select SR.SurveyResponseID, SR.AuditDate, 0, 0
  from [10.35.1.129].etosolaris.dbo.SurveyResponses SR
 where sr.AuditDate < @date_window 
   and sr.AuditDate >= @last_auditdate 
   and not exists (select SurveyResponseID
                     from etosolaris.dbo.SurveyResponses LocalTBL
                    where LocalTBL.SurveyResponseID = SR.SurveyResponseID)
   and not exists (select SurveyResponseID
                     from  dbo.New_SurveyResponses_from_ETO LocalTBL
                    where LocalTBL.SurveyResponseID = SR.SurveyResponseID);

----------------------------------------------------------------------------------------
END -- end of restart/no restart parameter condition

----------------------------------------------------------------------------------------
set @Step_nbr = 1
-- print 'Processing SP_ETO_Copy_SurveyResponses - Step ' +rtrim(convert(char,@Step_nbr)) +': SurveyElementResponses

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Step ' +rtrim(convert(char,@Step_nbr)) +': SurveyElementResponses'
      ,LogDate = getdate()
      ,index_1 = null
      ,index_2 = null
 where Process = @process

insert into etosolaris.dbo.SurveyElementResponses
select ESER.*
  from dbo.New_SurveyResponses_from_ETO nsr
  inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponses ESER
        on nsr.SurveyResponseID = eser.SurveyResponseID
 where isnull(nsr.step_processed,0) < @Step_nbr
   and not exists (select SurveyElementResponseID
                     from etosolaris.dbo.SurveyElementResponses LocalTBL
                    where LocalTBL.SurveyElementResponseID = ESER.SurveyElementResponseID);

-- commented 4/2/2015 (original version):
--  from [10.35.1.129].etosolaris.dbo.SurveyElementResponses ESER
-- where ESER.SurveyResponseID in
--                   (select SurveyResponseID from dbo.New_SurveyResponses_from_ETO) 
--   and not exists (select SurveyElementResponseID
--                     from etosolaris.dbo.SurveyElementResponses LocalTBL
--                    where LocalTBL.SurveyElementResponseID = ESER.SurveyElementResponseID);

 
-- update control records as processed for this step:
update dbo.New_SurveyResponses_from_ETO
   set step_processed = @Step_nbr
 where step_processed < @step_nbr

--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
set @Step_nbr = 2
-- print 'Processing SP_ETO_Copy_SurveyResponses - Step ' +rtrim(convert(char,@Step_nbr)) +': SurveyElementResponseChoice

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Step ' +rtrim(convert(char,@Step_nbr)) +': SurveyElementResponseChoice'
      ,LogDate = getdate()
      ,index_1 = null
      ,index_2 = null
 where Process = @process

insert into etosolaris.dbo.SurveyElementResponseChoice                   
select TBL.*  
  from dbo.New_SurveyResponses_from_ETO nsr
  inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponses ESER
        on nsr.SurveyResponseID = eser.SurveyResponseID
  inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponseChoice TBL
     on ESER.SurveyElementResponseID = TBL.SurveyElementResponseID
 where isnull(nsr.step_processed,0) < @Step_nbr
   and not exists (select SurveyElementResponseChoiceID
                     from etosolaris.dbo.SurveyElementResponseChoice LocalTBL
                    where LocalTBL.SurveyElementResponseChoiceID = TBL.SurveyElementResponseChoiceID);

-- commented 4/2/2015 (original version):
--  from [10.35.1.129].etosolaris.dbo.SurveyElementResponses ESER
--  inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponseChoice TBL
--     on ESER.SurveyElementResponseID = TBL.SurveyElementResponseID
--  where ESER.SurveyResponseID in
--                   (select SurveyResponseID from dbo.New_SurveyResponses_from_ETO)
--   and not exists (select SurveyElementResponseChoiceID
--                     from etosolaris.dbo.SurveyElementResponseChoice LocalTBL
--                    where LocalTBL.SurveyElementResponseChoiceID = TBL.SurveyElementResponseChoiceID);

 
-- update control records as processed for this step:
update dbo.New_SurveyResponses_from_ETO
   set step_processed = @Step_nbr
 where step_processed < @step_nbr

--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
set @Step_nbr = 3
-- print 'Processing SP_ETO_Copy_SurveyResponses - Step ' +rtrim(convert(char,@Step_nbr)) +': SurveyElementResponseArbText'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Step ' +rtrim(convert(char,@Step_nbr)) +': SurveyElementResponseArbText'
      ,LogDate = getdate()
      ,index_1 = null
      ,index_2 = null
 where Process = @process

insert into etosolaris.dbo.SurveyElementResponseArbText
select TBL.*
  from dbo.New_SurveyResponses_from_ETO nsr
  inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponses ESER
        on nsr.SurveyResponseID = eser.SurveyResponseID
  inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponseArbText TBL
     on ESER.SurveyElementResponseID = TBL.SurveyElementResponseID
 where isnull(nsr.step_processed,0) < @Step_nbr
   and not exists (select SurveyElementResponseArbTextID
                     from etosolaris.dbo.SurveyElementResponseArbText LocalTBL
                    where LocalTBL.SurveyElementResponseArbTextID = TBL.SurveyElementResponseArbTextID);


-- commented 4/2/2015 (original version):
--  from [10.35.1.129].etosolaris.dbo.SurveyElementResponses ESER
--  inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponseArbText TBL
--     on ESER.SurveyElementResponseID = TBL.SurveyElementResponseID
--  where ESER.SurveyResponseID in
--                   (select SurveyResponseID from dbo.New_SurveyResponses_from_ETO)
--   and not exists (select SurveyElementResponseArbTextID
--                     from etosolaris.dbo.SurveyElementResponseArbText LocalTBL
--                    where LocalTBL.SurveyElementResponseArbTextID = TBL.SurveyElementResponseArbTextID);


-- update control records as processed for this step:
update dbo.New_SurveyResponses_from_ETO
   set step_processed = @Step_nbr
 where step_processed < @step_nbr

--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- 
set @Step_nbr = 4
-- print 'Processing SP_ETO_Copy_SurveyResponses - Step ' +rtrim(convert(char,@Step_nbr)) +': SurveyElementResponseNumeric'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Step ' +rtrim(convert(char,@Step_nbr)) +': SurveyElementResponseNumeric'
      ,LogDate = getdate()
      ,index_1 = null
      ,index_2 = null
 where Process = @process

insert into etosolaris.dbo.SurveyElementResponseNumeric                   
select TBL.*
  from dbo.New_SurveyResponses_from_ETO nsr
  inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponses ESER
        on nsr.SurveyResponseID = eser.SurveyResponseID
  inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponseNumeric TBL
     on ESER.SurveyElementResponseID = TBL.SurveyElementResponseID
 where isnull(nsr.step_processed,0) < @Step_nbr
   and not exists (select SurveyElementResponseNumericID
                     from etosolaris.dbo.SurveyElementResponseNumeric LocalTBL
                    where LocalTBL.SurveyElementResponseNumericID = TBL.SurveyElementResponseNumericID);

-- commented 4/2/2015 (original version):
--  from [10.35.1.129].etosolaris.dbo.SurveyElementResponses ESER
--  inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponseNumeric TBL
--     on ESER.SurveyElementResponseID = TBL.SurveyElementResponseID
--  where ESER.SurveyResponseID in
--                   (select SurveyResponseID from dbo.New_SurveyResponses_from_ETO)
--   and not exists (select SurveyElementResponseNumericID
--                     from etosolaris.dbo.SurveyElementResponseNumeric LocalTBL
--                    where LocalTBL.SurveyElementResponseNumericID = TBL.SurveyElementResponseNumericID);


-- update control records as processed for this step:
update dbo.New_SurveyResponses_from_ETO
   set step_processed = @Step_nbr
 where step_processed < @step_nbr

--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- 
set @Step_nbr = 5
-- print 'Processing SP_ETO_Copy_SurveyResponses - Step ' +rtrim(convert(char,@Step_nbr)) +': SurveyElementResponseBoolean'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Step ' +rtrim(convert(char,@Step_nbr)) +': SurveyElementResponseBoolean'
      ,LogDate = getdate()
      ,index_1 = null
      ,index_2 = null
 where Process = @process

insert into etosolaris.dbo.SurveyElementResponseBoolean 
select TBL.*
  from dbo.New_SurveyResponses_from_ETO nsr
  inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponses ESER
        on nsr.SurveyResponseID = eser.SurveyResponseID
  inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponseBoolean TBL
     on ESER.SurveyElementResponseID = TBL.SurveyElementResponseID
 where isnull(nsr.step_processed,0) < @Step_nbr
   and not exists (select SurveyElementResponseBooleanID
                     from etosolaris.dbo.SurveyElementResponseBoolean LocalTBL
                    where LocalTBL.SurveyElementResponseBooleanID = TBL.SurveyElementResponseBooleanID);

-- commented 4/2/2015 (original version):
--  from [10.35.1.129].etosolaris.dbo.SurveyElementResponses ESER
--  inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponseBoolean TBL
--     on ESER.SurveyElementResponseID = TBL.SurveyElementResponseID
--  where ESER.SurveyResponseID in
--                   (select SurveyResponseID from dbo.New_SurveyResponses_from_ETO)
--   and not exists (select SurveyElementResponseBooleanID
--                     from etosolaris.dbo.SurveyElementResponseBoolean LocalTBL
--                    where LocalTBL.SurveyElementResponseBooleanID = TBL.SurveyElementResponseBooleanID);

-- update control records as processed for this step:
update dbo.New_SurveyResponses_from_ETO
   set step_processed = @Step_nbr
 where step_processed < @step_nbr


--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- 
set @Step_nbr = 6
-- print 'Processing SP_ETO_Copy_SurveyResponses - Step ' +rtrim(convert(char,@Step_nbr)) +': SurveyElementResponseDate'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Step ' +rtrim(convert(char,@Step_nbr)) +': SurveyElementResponseDate'
      ,LogDate = getdate()
      ,index_1 = null
      ,index_2 = null
 where Process = @process

insert into etosolaris.dbo.SurveyElementResponseDate                   
select TBL.*
  from dbo.New_SurveyResponses_from_ETO nsr
  inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponses ESER
        on nsr.SurveyResponseID = eser.SurveyResponseID
  inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponseDate TBL
     on ESER.SurveyElementResponseID = TBL.SurveyElementResponseID
 where isnull(nsr.step_processed,0) < @Step_nbr
   and not exists (select SurveyElementResponseDateID
                     from etosolaris.dbo.SurveyElementResponseDate LocalTBL
                    where LocalTBL.SurveyElementResponseDateID = TBL.SurveyElementResponseDateID);

-- commented 4/2/2015 (original version):
--  from [10.35.1.129].etosolaris.dbo.SurveyElementResponses ESER
--  inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponseDate TBL
--     on ESER.SurveyElementResponseID = TBL.SurveyElementResponseID
--  where ESER.SurveyResponseID in
--                   (select SurveyResponseID from dbo.New_SurveyResponses_from_ETO)
--   and not exists (select SurveyElementResponseDateID
--                     from etosolaris.dbo.SurveyElementResponseDate LocalTBL
--                    where LocalTBL.SurveyElementResponseDateID = TBL.SurveyElementResponseDateID);

 
-- update control records as processed for this step:
update dbo.New_SurveyResponses_from_ETO
   set step_processed = @Step_nbr
 where step_processed < @step_nbr

--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
set @Step_nbr = 7
-- print 'Processing SP_ETO_Copy_SurveyResponses - Step ' +rtrim(convert(char,@Step_nbr)) +': SurveyElementResponsePCR'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Step ' +rtrim(convert(char,@Step_nbr)) +': SurveyElementResponsePCR'
      ,LogDate = getdate()
      ,index_1 = null
      ,index_2 = null
 where Process = @process

insert into etosolaris.dbo.SurveyElementResponsePCR                   
select TBL.*
  from dbo.New_SurveyResponses_from_ETO nsr
  inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponses ESER
        on nsr.SurveyResponseID = eser.SurveyResponseID
  inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponsePCR TBL
     on ESER.SurveyElementResponseID = TBL.SurveyElementResponseID
 where isnull(nsr.step_processed,0) < @Step_nbr
   and not exists (select SurveyElementResponsePCRID
                     from etosolaris.dbo.SurveyElementResponsePCR LocalTBL
                    where LocalTBL.SurveyElementResponsePCRID = TBL.SurveyElementResponsePCRID);

-- commented 4/2/2015 (original version):
--  from [10.35.1.129].etosolaris.dbo.SurveyElementResponses ESER
--  inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponsePCR TBL
--     on ESER.SurveyElementResponseID = TBL.SurveyElementResponseID
--  where ESER.SurveyResponseID in
--                   (select SurveyResponseID from dbo.New_SurveyResponses_from_ETO)
--   and not exists (select SurveyElementResponsePCRID
--                     from etosolaris.dbo.SurveyElementResponsePCR LocalTBL
--                    where LocalTBL.SurveyElementResponsePCRID = TBL.SurveyElementResponsePCRID);


-- update control records as processed for this step:
update dbo.New_SurveyResponses_from_ETO
   set step_processed = @Step_nbr
 where step_processed < @step_nbr

--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
set @Step_nbr = 8
-- print 'Processing SP_ETO_Copy_SurveyResponses - Step ' +rtrim(convert(char,@Step_nbr)) +': SurveyElementResponseECR'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Step ' +rtrim(convert(char,@Step_nbr)) +': SurveyElementResponseECR'
      ,LogDate = getdate()
      ,index_1 = null
      ,index_2 = null
 where Process = @process

insert into etosolaris.dbo.SurveyElementResponseECR                   
select TBL.*
  from dbo.New_SurveyResponses_from_ETO nsr
  inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponses ESER
        on nsr.SurveyResponseID = eser.SurveyResponseID
  inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponseECR TBL
     on ESER.SurveyElementResponseID = TBL.SurveyElementResponseID
 where isnull(nsr.step_processed,0) < @Step_nbr
   and not exists (select SurveyElementResponseECRID
                     from etosolaris.dbo.SurveyElementResponseECR LocalTBL
                    where LocalTBL.SurveyElementResponseECRID = TBL.SurveyElementResponseECRID);

-- commented 4/2/2015 (original version):
--  from [10.35.1.129].etosolaris.dbo.SurveyElementResponses ESER
--  inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponseECR TBL
--     on ESER.SurveyElementResponseID = TBL.SurveyElementResponseID
--  where ESER.SurveyResponseID in
--                   (select SurveyResponseID from dbo.New_SurveyResponses_from_ETO)
--   and not exists (select SurveyElementResponseECRID
--                     from etosolaris.dbo.SurveyElementResponseECR LocalTBL
--                    where LocalTBL.SurveyElementResponseECRID = TBL.SurveyElementResponseECRID);


-- update control records as processed for this step:
update dbo.New_SurveyResponses_from_ETO
   set step_processed = @Step_nbr
 where step_processed < @step_nbr

--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- 
set @Step_nbr = 9
-- print 'Processing SP_ETO_Copy_SurveyResponses - Step ' +rtrim(convert(char,@Step_nbr)) +': SurveyResponses'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Step ' +rtrim(convert(char,@Step_nbr)) +': SurveyResponses'
      ,LogDate = getdate()
      ,index_1 = null
      ,index_2 = null
 where Process = @process

insert into etosolaris.dbo.SurveyResponses                   
select TBL.*
  from dbo.New_SurveyResponses_from_ETO nsr
  inner join [10.35.1.129].etosolaris.dbo.SurveyResponses TBL
        on nsr.SurveyResponseID = tbl.SurveyResponseID
 where isnull(nsr.step_processed,0) < @Step_nbr
   and not exists (select SurveyResponseID
                     from etosolaris.dbo.SurveyResponses LocalTBL
                    where LocalTBL.SurveyResponseID = TBL.SurveyResponseID);

-- commented 4/2/2015 (original version):
--  from [10.35.1.129].etosolaris.dbo.SurveyResponses TBL
-- where TBL.SurveyResponseID in (select SurveyResponseID from dbo.New_SurveyResponses_from_ETO)
--   and not exists (select SurveyResponseID
--                     from etosolaris.dbo.SurveyResponses LocalTBL
--                    where LocalTBL.SurveyResponseID = TBL.SurveyResponseID);

-- update control records as processed for this step and fully processed:
update dbo.New_SurveyResponses_from_ETO
   set step_processed = @Step_nbr
      ,processed = 1
 where step_processed < @step_nbr

----------------------------------------------------------------------------------------
--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- 
set @Step_nbr = 10
print 'Processing SP_ETO_Copy_SurveyResponses - Step ' +rtrim(convert(char,@Step_nbr)) +': SurveyResponses (cleanup deletions)'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Step ' +rtrim(convert(char,@Step_nbr)) +': SurveyResponses (cleanup deletions)'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

delete etosolaris.dbo.SurveyResponses
  from etosolaris.dbo.SurveyResponses tbl
 where tbl.SurveyResponseID 
           not in (select SurveyResponseID
                     from [10.35.1.129].etosolaris.dbo.SurveyResponses ETOTBL
                    where ETOTBL.SurveyResponseID = tbl.SurveyResponseID);

/*  1/18/2012: remain commented becuase ETO/SSI is not deleting old child records
delete etosolaris.dbo.SurveyElementResponses
  from etosolaris.dbo.SurveyElementResponses  tbl
 where tbl.SurveyResponseID 
           not in (select SurveyResponseID
                     from etosolaris.dbo.SurveyResponses SR
                    where SR.SurveyResponseID = tbl.SurveyResponseID);

delete etosolaris.dbo.SurveyElementResponseBoolean
  from etosolaris.dbo.SurveyElementResponseBoolean tbl
 where tbl.SurveyElementResponseID
           not in (select SurveyElementResponseID
                     from etosolaris.dbo.SurveyElementResponses SER
                    where SER.SurveyElementResponseID = tbl.SurveyElementResponseID);  

delete etosolaris.dbo.SurveyElementResponseChoice 
  from etosolaris.dbo.SurveyElementResponseChoice tbl
 where tbl.SurveyElementResponseID 
           not in (select SurveyElementResponseID
                     from etosolaris.dbo.SurveyElementResponses SER
                    where SER.SurveyElementResponseID = tbl.SurveyElementResponseID); 

delete etosolaris.dbo.SurveyElementResponseDate 
  from etosolaris.dbo.SurveyElementResponseDate tbl
 where tbl.SurveyElementResponseID 
           not in (select SurveyElementResponseID
                     from etosolaris.dbo.SurveyElementResponses SER
                    where SER.SurveyElementResponseID = tbl.SurveyElementResponseID);

delete etosolaris.dbo.SurveyElementResponseECR 
  from etosolaris.dbo.SurveyElementResponseECR tbl
 where tbl.SurveyElementResponseID 
           not in (select SurveyElementResponseID
                     from etosolaris.dbo.SurveyElementResponses SER
                    where SER.SurveyElementResponseID = tbl.SurveyElementResponseID);

delete etosolaris.dbo.SurveyElementResponsePCR 
  from etosolaris.dbo.SurveyElementResponsePCR tbl
 where tbl.SurveyElementResponseID 
           not in (select SurveyElementResponseID
                     from .etosolaris.dbo.SurveyElementResponses SER
                    where SER.SurveyElementResponseID = tbl.SurveyElementResponseID);
*/
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

print 'End of Process: SP_ETO_Copy_SurveyResponses'
GO
