USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_ETO_to_DW_survey_Responses_local]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_ETO_to_DW_survey_Responses_local
CREATE PROCEDURE [dbo].[SP_ETO_to_DW_survey_Responses_local]
  @p_surveyid   int = null,
  @p_begdate    smalldatetime = null,
  @p_enddate    smalldatetime = null,
  @p_debug_level smallint = 0
AS
-- This script processes the ETO assessment surveys into the Data Warehouse.
--
-- 1. This utilizes the established ETO sproc to flatten out the Survey into
--    a single record as columns for each element, writing to a temporary table.
-- 2. The flattend table is then read, 
--    to either insert the corresponding DW assessment table.
-- 3. Delete DW Surveys which no longer exist in ETO.
--    ** ETO modifications to Survey Responses actually deletes the entire Survey
--       and then writes the new Survey Response, creating a new ResponseID.
--
-- Parameters:
--   p_surveyid = SurveyID, if 0, will process all surveys flatfile tables
--   p_debug_level = null, 3 
--        (allows ability to display what is being processed, and display sql code
--         null = default display of survey being processed
--         3 = display SQL code

-- Processing Steps:
--   Build table of Surveys to process, then for each Survey:
--     Add a non-existing DW Survey entry for the ETO response
--       (qualify response will have an existing DW Agency, Entity, Client record)
--     For all DW responses that have a false ElementsProcessed flag, process elements.
--
-- Special processing flag: ElementsProcessed, is set to 1 (processed) when 
-- all elements have been updated for an individual survey response.  This inhibits
-- it from being processed again.  (Updates are not required, becuase ETO maintains 
-- surveys by deleting the old response adding a new updated survey response).
--
-- History: 
--   20101205 - process survey inserts only if surveys exist in ETO
--              Broke out actually element updates to part_b so that DW survey responses
--              could be filtered for elements not yet processed.
--   20101214 - created to hit etosolaris locallaly, not called via etosrvr
--              removed dates being passed to part_b.
--   20110126 - Modified to exclude 'Draft' Survey Responses. 
--              Changed process to count actual responses in ETO for survey,
--              allowing for DW delete when none actually exist in ETO,
--              but still only processing adds for surveys that actually exist.
--   20110203 - Changed the site relationship from who entered survey to program.auditstaffid.
--   20120306 - Added conditional selection and updates based upon the field DataSource being null.
--   20121001 - Added null pseudonym to exec statement that call part-b.
--   20130422 - Added logic to exclude specific sites via dbo.Sites_Excluded table.
--   20140115 - Added logic to ignore excluded sites when the DW_Tablename is included in the tables_to_ignore field.
--   20140829 - Added New column to survey record 'Master_SurveyID', and populate accordingly.
--   20141010 - Added processing to populate and maintain the DW SurveyResponses table.
--   20150410 - Added Additional logging of processing steps.
--   20160112 - changed to not use the ETOSRVR as a db link, calling instead locally from etosolaris.

DECLARE @p_ETOSRVRDB	nvarchar(50)
set @p_ETOSRVRDB = 'etosolaris'

DECLARE @Process	nvarchar(50)
set @process = 'SP_ETO_TO_DW_SURVEY_RESPONSES_LOCAL'

DECLARE @SurveyID	int
DECLARE @SurveyType	nvarchar(10)
DECLARE @DW_TableName	nvarchar(50)
DECLARE @ResponsesCount int
DECLARE @SurveyResponseID	int
DECLARE @SurveyElementID	int
DECLARE @SurveyElementTypeID	smallint
DECLARE @SequenceOrder	smallint
DECLARE @Pseudonym	nvarchar(100)
DECLARE @DW_record_choice_as_seqnbr bit
DECLARE @DW_Extend_NonExclusive_Columns bit
DECLARE @Column		nvarchar(100)
DECLARE @Select_Fields	nvarchar(1900)
DECLARE @Surveys_Ctr	int
DECLARE @begdate	datetime
DECLARE @enddate	datetime
DECLARE @sql            nvarchar(4000)
DECLARE @count		smallint


IF @p_begdate is null
   Set @begdate = convert(datetime,'01/01/1950',101)
ELSE
   Set @begdate = @p_begdate

IF @p_enddate is null
   Set @enddate = convert(datetime,'01/01/2050',101)
ELSE
   Set @enddate = @p_enddate

set @Surveys_Ctr = 0

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
-- Build and process cursor for each Survey 
-- (updated from ETO to the master DW tbl)
----------------------------------------------------------------------------------------
if isnull(@p_debug_level,0) > 0
   print 'Start Process: SP_ETO_to_DW_Survey_Responses_local - Building SurveyCursor'

DECLARE SurveyCursor Cursor for
select SurveyID
      ,SurveyType
      ,DW_TableName
      ,(select count(*) 
          from etosolaris.dbo.SurveyResponses 
         where SurveyID=Mstr_surveys.SurveyID) as ResponsesCount
  from dbo.Mstr_surveys
 where isnull(@p_surveyID,999999) in (999999,SurveyID)
   and DW_TableName is not null
--   and disabled = 0;


OPEN  SurveyCursor

FETCH next from  SurveyCursor
      into @SurveyID
          ,@SurveyType
          ,@DW_TableName
          ,@ResponsesCount

WHILE @@FETCH_STATUS = 0
BEGIN

   set nocount on
   update dbo.process_log 
      set Action = 'Processing Survey Cursor'
         ,Phase = null
         ,Comment = @DW_TableName
         ,index_1 = @SurveyID
         ,index_2 = null
         ,index_3 = null
         ,LogDate = getdate()
    where Process = @process

-- process only for surveys that have responses in ETO:
 IF @ResponsesCount > 0
 BEGIN
----------------------------------------------------------------------------------------
-- For each Survey ID, insert the basic survey fields for any Survey Response
-- not yet existing in the DW survey table
-- Validate that respective Entity/Client Survey exists from filtered ETO extraction
----------------------------------------------------------------------------------------
   IF @p_debug_level = 3
      print 'Cont: SP_ETO_to_DW_Survey_Responses - Inserting new survey records '
       +@DW_TableName +', SurveyID=' +convert(varchar,@SurveyID)

   set nocount on
   update dbo.process_log 
      set Phase = 'Insert basic Survey recs w/o element data'
         ,LogDate = getdate()
    where Process = @process

-- Build insert with basic fields:
   set @SQL = ''
   IF @p_debug_Level = 0
      set @SQL = 'set nocount on '
   set @SQL = @SQL +'INSERT into ' +@DW_TableName +'
        ([SurveyResponseID],[SurveyID],[ProgramID],[surveydate],[CL_EN_GEN_ID],[AuditDate],[SiteId],[ElementsProcessed],[Master_SurveyID])
        select 
          ETOSurveyResponses.SurveyResponseID, '+convert(varchar,@SurveyID)
          +', ETOSurveyResponses.ProgramID'
          +', ETOSurveyResponses.SurveyDate, ETOSurveyResponses.CL_EN_GEN_ID,ETOSurveyResponses.AuditDate
          ,CASE when ETOPStaff.SiteID IS null then ETOStaff.SiteID else ETOPStaff.SiteID END, 0, etosurveys.SourceSurveyID
          from ' +@P_ETOSRVRDB +'.dbo.Surveys etosurveys
          inner join ' +@P_ETOSRVRDB +'.dbo.SurveyResponses ETOSurveyResponses
                on etosurveys.SurveyID = ETOSurveyResponses.SurveyID
	  INNER JOIN ' +@P_ETOSRVRDB +'.dbo.Staff ETOStaff
		ON ETOSurveyResponses.AuditStaffID = ETOStaff.staffid
	  LEFT JOIN ' +@P_ETOSRVRDB +'.dbo.Programs ETOProg
		ON ETOSurveyResponses.ProgramID = ETOProg.programid
          LEFT JOIN ' +@P_ETOSRVRDB +'.dbo.Staff ETOPStaff
                on ETOProg.AuditStaffID = ETOPStaff.StaffID'
/*
   -- Varify that either the EntityID or ClientID exists in the DW (filtered eto data)
   IF @SurveyType = 'Client'
   BEGIN
      set @SQL = @SQL +' INNER JOIN dbo.Clients Clients 
          on Clients.Client_ID = ETOSurveyResponses.CL_EN_GEN_ID' 
   END

   IF @SurveyType = 'Entity'
   BEGIN
      IF upper(substring(@DW_TableName,1,6)) = 'AGENCY'
      BEGIN
         set @SQL = @SQL +' INNER JOIN dbo.Agencies Agencies 
          on Agencies.Entity_ID = ETOSurveyResponses.CL_EN_GEN_ID' 
      END
      ELSE
      BEGIN
         set @SQL = @SQL +' INNER JOIN dbo.IA_Staff IA_Staff 
          on IA_Staff.Entity_ID = ETOSurveyResponses.CL_EN_GEN_ID'
      END
   END
*/

-- continue:
   set @SQL = @SQL +' where not exists (select SurveyResponseID from ' +@DW_TableName +'
                            where SurveyResponseID = ETOSurveyResponses.SurveyResponseID)
           and ETOSurveyResponses.DraftSavedOn is null
           and ETOSurveyResponses.SurveyDate >= convert(datetime,''' 
               +Convert(varchar(20),@BegDate,120) +''',120)
           and etosurveys.SurveyID = ' +convert(varchar,@SurveyID)
   set @SQL = @SQL +' and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = isnull(ETOPStaff.SiteID,ETOStaff.SiteID)
                      and isnull(ex2.tables_to_ignore,'''') not like ''%' +@DW_TableName +'%'' )'

   IF @p_debug_level = 3
      Print @SQL
   EXEC (@SQL)


----------------------------------------------------------------------------------------
-- Process the survey elements, updating all DW Survey records
-- that have the ElementsProcessed bit still set to null
----------------------------------------------------------------------------------------
   IF @p_debug_level = 3
      print 'Cont: SP_ETO_to_DW_Survey_Responses - Processing Elements for '
       +@DW_TableName +', SurveyID=' +convert(varchar,@SurveyID)

   set nocount on
   update dbo.process_log 
      set Phase = 'Processing elements calling Part_B_local'
         ,LogDate = getdate()
    where Process = @process

      set @SQL = ''
      IF @p_debug_Level = 0
         set @SQL = 'set nocount on '
      Set @SQL = @SQL +'
         Declare notprocessed cursor for
         Select SurveyResponseID
           FROM  '+@DW_TableName +'
          where surveyId = '+convert(varchar,@SurveyID) +'
            and isnull(ElementsProcessed,0) != 1 and DataSource is null
							
         Declare @SurveyResponseID int
         Open notprocessed
							
         Fetch next from notprocessed into @SurveyResponseID
							
         While @@FETCH_STATUS = 0
         Begin
            Exec SP_ETO_to_DW_Survey_Responses_Part_B_local ' +convert(varchar,@SurveyID) +',@SurveyResponseID '
                +',' +isnull(convert(varchar,@p_debug_level),'0') +',null 
            Fetch next from notprocessed into @SurveyResponseID
         End			
				
         CLOSE notprocessed
         DEALLOCATE notprocessed'

      IF @p_debug_level = 3
         Print @SQL
      exec (@SQL)

  END  /* end of phase to process only surveys with responses in ETO */

----------------------------------------------------------------------------------------
-- Process the DW Survey table against ETO Survey Responses, 
--   - Deleting non existing ETO responses from the DW (deleted within ETO)
----------------------------------------------------------------------------------------

   IF @p_debug_level = 3
      print 'Cont: SP_ETO_to_DW_Survey_Responses - Deleting deleted ETO Responses'

   set nocount on
   update dbo.process_log 
      set Phase = 'Removing Surveys no longer existing in ETO'
         ,LogDate = getdate()
    where Process = @process


   set @SQL = ''
   IF @p_debug_Level = 0
      set @SQL = 'set nocount on '
   Set @SQL = @SQL +'DELETE ' +@DW_TableName
      +' from dbo.' +@DW_TableName 
      +' where SurveyID = ' +convert(varchar,@SurveyID)
      +' and DataSource is null'
      +' and not exists (select SurveyResponseID from '
      +@P_ETOSRVRDB +'.dbo.SurveyResponses SR '
      +'where SR.SurveyResponseID = ' +@DW_TableName +'.SurveyResponseID)'
   set @SQL = @SQL +' and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = ' + @DW_TableName + '.SiteId
                      and isnull(ex2.tables_to_ignore,'''') not like ''%' +@DW_TableName +'%'')'
    IF @p_debug_level = 3
       Print @SQL
    EXEC (@SQL)

   set nocount on
   update dbo.process_log 
      set Phase = 'Removed non-existing ETO Surveys'
         ,LogDate = getdate()
    where Process = @process


----------------------------------------------------------------------------------------
-- Add new SurveyResponses to the DW SurveyResponses table
----------------------------------------------------------------------------------------

   IF @p_debug_level = 3
      print 'Cont: Adding new records to DW.SurveyResponses'

   update dbo.process_log 
      set Phase = 'Adding new records to DW.SurveyResponses'
         ,LogDate = getdate()
    where Process = @process

   set @SQL = ''
   IF @p_debug_Level = 0
      set @SQL = 'set nocount on '

   set @SQL = @SQL 
+' Insert into dbo.SurveyResponses'
+' (SurveyResponseID'
+', SurveyID'
+', SurveyDate'
+', CL_EN_GEN_ID'
+', SiteID'
+', ProgramID'
+', AuditStaffID'
+', AuditDate'
+', ResponseCreationDate'
+', SurveyResponderType'
+', DataSource)'
+'
 select dwtbl.SurveyResponseID'
    +' ,dwtbl.SurveyID'
    +' ,dwtbl.SurveyDate'
    +' ,dwtbl.CL_EN_GEN_ID'
    +' ,dwtbl.SiteID'
    +' ,dwtbl.ProgramID'
    +' ,esr.AuditStaffID'
    +' ,dwtbl.AuditDate'
    +' ,esr.ResponseCreationDate'
    +' ,esr.SurveyResponderType'
    +' ,''ETO'' as DataSource'
 +' from dbo.' +@DW_TableName +' dwtbl'
 +' inner join etosolaris.dbo.SurveyResponses esr on dwtbl.SurveyResponseID = esr.SurveyResponseID'
+' where ISNULL(DataSource,''ETO'') = ''ETO'''
  +' and not exists (Select sr2.SurveyResponseID'
                    +' from dbo.SurveyResponses SR2'
                   +' where SR2.SurveyResponseID = dwtbl.SurveyResponseID)'

    IF @p_debug_level = 3
       Print @SQL
    EXEC (@SQL)


----------------------------------------------------------------------------------------
-- Remove non-existing SurveyResponses from the DW SurveyResponses table
----------------------------------------------------------------------------------------

   IF @p_debug_level = 3
      print 'Cont: Removing non-existing records from DW.SurveyResponses'

   update dbo.process_log 
      set Phase = 'Del non-existing records from DW.SurveyResponses'
         ,LogDate = getdate()
    where Process = @process

   set @SQL = ''
   IF @p_debug_Level = 0
      set @SQL = 'set nocount on '

   set @SQL = @SQL 
+' delete from dbo.SurveyResponses where SurveyResponseID in'
+' (select sr.SurveyResponseID'
   +' from dbo.SurveyResponses sr'
   +' inner join dbo.Mstr_surveys ms on sr.surveyID = ms.surveyID'
  +' where ISNULL(DataSource,''ETO'') = ''ETO'''
    +' and upper(ms.DW_TableName) = upper(''' +@DW_TableName +''')'
    +' and not exists (Select dwtbl.SurveyResponseID'
                     +' from dbo.' +@DW_TableName +' dwtbl'
                    +' where dwtbl.SurveyResponseID = sr.SurveyResponseID) )'

    IF @p_debug_level = 3
       Print @SQL
    EXEC (@SQL)


----------------------------------------------------------------------------------------
-- Continue
----------------------------------------------------------------------------------------

   FETCH next from  SurveyCursor
         into @SurveyID
             ,@SurveyType
             ,@DW_TableName
             ,@ResponsesCount
   
END -- While loop for Survey Cursor

CLOSE SurveyCursor
DEALLOCATE SurveyCursor

set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process

if isnull(@p_debug_level,0) > 0
print 'End Process: SP_ETO_to_DW_Survey_Responses_local'
GO
