USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_masters_update_surveys]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_masters_update_surveys
--
CREATE PROCEDURE [dbo].[SP_masters_update_surveys]
AS
--
-- ** Using ETO Sandbox
--
-- This script controls the replicated Surveys master table in the Data Warehouse.
--
-- DW - Update/Insert process for ETO Surveys
-- Table effected - dbo.Mstr_surveys
--
-- Insert: select and insert when ETO survey is found to be missing in the DW.
-- Update: select and update when ETO survey exists in DW and has been changed in ETO.
--
-- Processes Surveys with ID >= 1575 (NFP created), and not Disabled.
--

DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_MASTERS_UPDATE_SURVEYS'

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
print ' '
print 'Processing SP_masters_update_surveys - Insert new Surveys'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Surveys'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

insert into dbo.Mstr_surveys
       (SurveyID
       ,SurveyType
       ,SurveyName
       ,SecuredProgramID
       ,SourceSurveyID
       ,TakeOnlyOnce
       ,TakeOnlyOncePerEnroll
       ,disabled
       ,AuditDate)
select etoSurveys.SurveyID
      ,etoSurveys.SurveyType
      ,etoSurveys.SurveyName
      ,etoSurveys.SecuredProgramID
      ,etoSurveys.SourceSurveyID
      ,etoSurveys.TakeOnlyOnce
      ,etoSurveys.TakeOnlyOncePerEnroll
      ,disabled
      ,etoSurveys.AuditDate
 from ETOSRVR.etosolaris.dbo.Surveys etoSurveys
where etoSurveys.surveyid is not null
  and etoSurveys.surveyid >= 1575
--  and etoSurveys.Disabled = 0
  and not exists (select SurveyID
                  from dbo.Mstr_Surveys nfpsurveys
                 where etosurveys.SurveyId = nfpsurveys.SurveyId);

print ' '
print '  Cont: SP_masters_update_surveys - Update changed Surveys'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Update Existing Surveys'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

update nfpsurveys
   set SurveyType = etoSurveys.SurveyType
      ,SurveyName = etoSurveys.SurveyName
      ,SecuredProgramID = etoSurveys.SecuredProgramID
      ,SourceSurveyID = etoSurveys.SourceSurveyID
      ,TakeOnlyOnce = etoSurveys.TakeOnlyOnce
      ,TakeOnlyOncePerEnroll = etoSurveys.TakeOnlyOncePerEnroll
      ,disabled = etoSurveys.disabled
      ,AuditDate = etoSurveys.AuditDate
 from dbo.Mstr_surveys nfpsurveys
 join ETOSRVR.etosolaris.dbo.Surveys etoSurveys 
      on nfpsurveys.SurveyId = etosurveys.SurveyId
 where etoSurveys.auditdate > 
       convert(datetime,convert(varchar,isnull(nfpSurveys.auditdate,CONVERT(datetime,'19690101',112)),120),120)


print ' '
print '  Cont: SP_masters_update_surveys - Propagate DW Tablename from MASTER record'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Proagate DW Tablenames'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

update nfpsurveys
   set DW_TableName = mstrsurveys.DW_TableName
 from dbo.Mstr_surveys nfpsurveys
 join dbo.Mstr_surveys mstrsurveys 
      on nfpsurveys.SourceSurveyId = mstrsurveys.SurveyId
where nfpsurveys.SourceSurveyID is not null
  and mstrsurveys.DW_TableName is not null
  and isnull(nfpsurveys.DW_TableName,'xx') != mstrsurveys.DW_TableName;

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

print '  End of Process SP_masters_update_surveys'
GO
