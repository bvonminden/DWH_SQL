USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_masters_update_survey_element_choices]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_masters_update_survey_element_choices
--
CREATE PROCEDURE [dbo].[SP_masters_update_survey_element_choices]
AS
--
-- ** Using ETO Sandbox
--
--This script controls the replicated Surveys master table in the Data Warehouse.
--
-- Table effected - dbo.Mstr_Surveys_elements
----
-- Insert: select and insert when ETO survey is found to be missing in the DW.
-- Update: select and update when ETO survey exists in DW and has been changed in ETO.
--


DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_MASTERS_UPDATE_SURVEY_ELEMENT_CHOICES'

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
print 'Process SP_masters_update_survey_element_choices - Insert non-existing choices'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Choices'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- copy ETO Servey Element Choices:
insert into dbo.Mstr_SurveyElementChoices
      (SurveyElementChoiceID
      ,SUrveyElementID
      ,Sequence
      ,Choice
      ,Weight
      ,AuditDate
      ,CDDTVID)   
Select etoSurveyElementChoices.SurveyElementChoiceID
      ,etoSurveyElementChoices.SurveyElementID
      ,etoSurveyElementChoices.Sequence
      ,etoSurveyElementChoices.Choice
      ,etoSurveyElementChoices.Weight
      ,etoSurveyElementChoices.AuditDate
      ,etoSurveyElementChoices.CDDTVID
  from ETOSRVR.etosolaris.dbo.surveys etosurveys
  join ETOSRVR.etosolaris.dbo.surveyelements etosurveyelements
       on (etosurveys.surveyid = etosurveyelements.surveyid)
  join ETOSRVR.etosolaris.dbo.SurveyElementChoices etoSurveyElementChoices
       on (etosurveyelements.SurveyElementID = etoSurveyElementChoices.SurveyElementID)
 where exists (select SurveyID
                from dbo.Mstr_Surveys nfpsurveys
               where etosurveys.SurveyId = nfpsurveys.SurveyId)
  and not exists (select nfpsurveyelementChoices.SurveyElementChoiceID
                    from dbo.Mstr_SurveyElementChoices nfpsurveyelementChoices
                   where etosurveyElementChoices.SurveyElementChoiceId = 
                         nfpsurveyElementChoices.SurveyElementChoiceId);


print ' '
print '  Cont: SP_masters_update_survey_element_choices - Update existing changed choices'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Choices'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- Update from ETO Servey Element Choices:
update NFPSurveyElementChoices
   set sequence = etosurveyelementChoices.sequence
      ,choice  = etosurveyelementChoices.choice 
      ,weight = etosurveyelementChoices.weight
      ,CDDTVID = etosurveyelementChoices.CDDTVID
      ,AuditDate = etosurveyelementChoices.AuditDate
 from dbo.Mstr_SurveyElementChoices NFPSurveyElementChoices
 join ETOSRVR.etosolaris.dbo.surveyelementChoices etosurveyelementChoices
       on (NFPSurveyElementChoices.surveyelementChoiceid = 
           etosurveyelementChoices.surveyelementChoiceid)
where etosurveyelementChoices.auditdate > nfpsurveyelementChoices.auditdate;

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

print 'End of SP_masters_update_survey_element_choices'
GO
