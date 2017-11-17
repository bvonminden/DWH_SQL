USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_masters_update_survey_elements]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--drop proc dbo.SP_masters_update_survey_elements
--
CREATE PROCEDURE [dbo].[SP_masters_update_survey_elements]
AS
--
-- ** Using ETO Sandbox
--
--This script controls the replicated Surveys master table in the Data Warehouse.
--
-- Table effected - dbo.Mstr_surveys_elements
--
-- Processes Surveys with ID >= 1575 (NFP created), and not Disabled.
--
-- Insert: select and insert when ETO survey is found to be missing in the DW.
-- Update: select and update when ETO survey exists in DW and has been changed in ETO.
--
-- History:
--   20160420: Added a new column to identify surveyelement records which have been deleted from ETO.
--             The Mstr_SurveyElements record is not actually deleted because it could referenced elsewhere.
--   20161111: Added filter to setting 'Removed_from_ETO' to exlcude processing of columns identified as 'Non_Element_Column',
--             which have been added manually to be reported on the data dictionary for standard survey or custom columns.

DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_MASTERS_UPDATE_SURVEY_ELEMENTS'

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
print 'Process SP_masters_update_survey_elements - Insert non-existing elements'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Elements'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- copy ETO Servey Elements:
insert into dbo.Mstr_SurveyElements
      (surveyelementid
      ,surveyid
      ,sequenceorder
      ,stimulus
      ,Pseudonym
      ,surveyelementtypeid
      ,surveyelementtype
      ,surveycomment
      ,entityTypeid
      ,entitysubtypeid
      ,sourcesurveyelementid
      ,IsRequired
      ,AuditDate)
select etosurveyelements.surveyelementid
      ,etosurveyelements.surveyid
      ,etosurveyelements.sequenceorder
      ,etosurveyelements.stimulus
      ,REPLACE(REPLACE(REPLACE(Replace(Replace(Replace(Replace(Replace(Replace(REPLACE( REPLACE(REPLACE(Replace(Replace(Replace(Replace(Replace( Replace(Replace(ReplacE(Replace(Replace( etosurveyelements.Pseudonym , '(', ''), ')', ''), '-', ''),'"',''),'''','') ,'?',''),'/',''),'@','') ,'&#39;',''),'&#34;','') ,'\',''),'.','') ,',','' ),'<br>','') ,':',''),'#',''),'!',''),'[','{'),']','}'),'*','' ),'&','_and_'),'$','')
      ,etosurveyelements.surveyelementtypeid
      ,etosurveyelementtypes.surveyelementtype
      ,etosurveyelements.surveycomment
      ,etosurveyelements.entityTypeid
      ,etosurveyelements.entitysubtypeid
      ,etosurveyelements.sourcesurveyelementid
      ,etosurveyelements.IsRequired
      ,etosurveyelements.AuditDate
 from ETOSRVR.etosolaris.dbo.surveys etosurveys
 inner join ETOSRVR.etosolaris.dbo.surveyelements etosurveyelements
        on (etosurveys.surveyid = etosurveyelements.surveyid)
 left join ETOSRVR.etosolaris.dbo.surveyelementtypes etosurveyelementtypes
        on (etosurveyelements.surveyelementtypeid = etosurveyelementtypes.surveyelementtypeid)
where etosurveys.surveyid >= 1575 
--  and etosurveys.Disabled = 0
  and exists (select SurveyID
                from dbo.Mstr_Surveys nfpsurveys
               where etosurveys.SurveyId = nfpsurveys.SurveyId)
  and not exists (select SurveyElementID
                from dbo.Mstr_SurveyElements nfpsurveyelements
               where etosurveyelements.SurveyElementId = nfpsurveyelements.SurveyElementId);


print ' '
print '  Cont: SP_masters_update_survey_elements - Update existing changed elements'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Elements'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- Update from ETO Servey Elements:
update NFPSurveyElements
   set sequenceorder = etosurveyelements.sequenceorder
      ,stimulus  = etosurveyelements.stimulus 
      ,pseudonym = 
           REPLACE(REPLACE(REPLACE(Replace(Replace(Replace(Replace(Replace(Replace(REPLACE( REPLACE(REPLACE(Replace(Replace(Replace(Replace(Replace( Replace(Replace(ReplacE(Replace(Replace(etosurveyelements.pseudonym , '(', ''), ')', ''), '-', ''),'"',''),'''','') ,'?',''),'/',''),'@','') ,'&#39;',''),'&#34;','') ,'\',''),'.','') ,',','' ),'<br>','') ,':',''),'#',''),'!',''),'[','{'),']','}'),'*','' ),'&','_and_'),'$','')
      ,surveyelementtypeid = etosurveyelements.surveyelementtypeid
      ,surveyelementtype = etosurveyelementtypes.surveyelementtype
      ,surveycomment = etosurveyelements.surveycomment
      ,entityTypeid = etosurveyelements.entityTypeid
      ,entitysubtypeid = etosurveyelements.entitysubtypeid
      ,sourcesurveyelementid = etosurveyelements.sourcesurveyelementid
      ,IsRequired = etosurveyelements.IsRequired
      ,AuditDate = etosurveyelements.AuditDate
 from dbo.Mstr_SurveyElements NFPSurveyElements
 join ETOSRVR.etosolaris.dbo.surveyelements etosurveyelements
       on (NFPSurveyElements.surveyelementid = etosurveyelements.surveyelementid)
 left join ETOSRVR.etosolaris.dbo.surveyelementtypes etosurveyelementtypes
       on (etosurveyelements.surveyelementtypeid = etosurveyelementtypes.surveyelementtypeid)
where etosurveyelements.auditdate > nfpsurveyelements.auditdate;



-- update when records are found to no longer exist in etosolaris:
update dbo.Mstr_SurveyElements
   set Removed_From_ETO = 1
  from dbo.Mstr_SurveyElements nse
 where ISNULL(Removed_From_ETO,0) = 0
   and isnull(non_element_column,0) = 0
   and not exists (select ese.SurveyElementID
                     from ETOSRVR.etosolaris.dbo.surveyelements ese 
                    where ese.SurveyElementID = nse.SurveyElementID)



--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

print 'End of Process SP_masters_update_survey_elements'
GO
