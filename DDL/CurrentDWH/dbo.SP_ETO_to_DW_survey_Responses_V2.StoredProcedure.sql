USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_ETO_to_DW_survey_Responses_V2]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_ETO_to_DW_survey_Responses_V2
CREATE PROCEDURE [dbo].[SP_ETO_to_DW_survey_Responses_V2]
  @p_surveyid   int = null,
  @p_TableName  nvarchar(50) = null,
  @p_begdate    smalldatetime = null,
  @p_enddate    smalldatetime = null,
  @p_debug_level smallint = 0,
  @p_no_exec_flag    nvarchar(10) = 'N'
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
--   20160427 - V2 - New version update from dbo.SP_ETO_to_DW_survey_Responses_Local

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
--   20160427 - V2: rework to streamline the dynamic SQL scripts to process by table_name instead of SurveyID.
--                - Condensed processing by tablename instead of by surveyid.
--                  This is to reduce the overhead caused by each dynamic execution of a SQL statement.
--                - Added runtime parm for selecting a specific survey table name.
--                - Added runtime parm @p_no_exec_flag to build sql scripts, but not actually execute them... for debuging/evaluation.

DECLARE @p_ETOSRVRDB	nvarchar(50)
set @p_ETOSRVRDB = 'etosolaris'

DECLARE @Process	nvarchar(50)
set @process = 'SP_ETO_TO_DW_SURVEY_RESPONSES_V2'

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

-- end date not being used
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
   print 'Start Process: SP_ETO_to_DW_Survey_Responses_V2 - Building SurveyCursor'
   print '  p_surveyid = ' +rtrim(isnull(convert(varchar,@p_surveyid),'NULL'))
        +', p_TableName = ' +isnull(@p_TableName,'NULL')
        +', p_begdate = ' +rtrim(isnull(convert(char,@p_begdate),'NULL'))
        +', p_enddate = ' +rtrim(isnull(convert(char,@p_enddate),'NULL'))
        +', p_enddate = ' +rtrim(isnull(convert(char,@p_debug_level),'NULL'))
        +', p_no_exec_flag = ' +isnull(@p_no_exec_flag,'NULL')

DECLARE SurveyCursor Cursor for
select DW_TableName, SurveyType
  from dbo.Mstr_surveys
 where DW_TableName is not null
   and isnull(@p_surveyID,999999) in (999999,SurveyID)
   and isnull(@p_TableName,'alltbls') in ('alltbls',DW_TableName)
   and (select count(*) 
          from etosolaris.dbo.SurveyResponses 
         where SurveyID=Mstr_surveys.SurveyID) > 0
 group by DW_TableName, SurveyType
 order by DW_TableName


OPEN  SurveyCursor

FETCH next from  SurveyCursor
      into @DW_TableName
          ,@SurveyType


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


print ' '
print 'processing table: ' +@DW_Tablename +', surveytype=' +@SurveyType


----------------------------------------------------------------------------------------
-- For each DW_Table / Survey ID, insert the basic survey fields for any Survey Response
-- not yet existing in the DW survey table
-- Validate that respective Entity/Client Survey exists from filtered ETO extraction
----------------------------------------------------------------------------------------
   IF @p_debug_level = 3
      print ' '
      print 'Inserting new survey records: ' +@DW_TableName 

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
          ETOSurveyResponses.SurveyResponseID, ETOSurveyResponses.SurveyID'
          +', ETOSurveyResponses.ProgramID'
          +', ETOSurveyResponses.SurveyDate, ETOSurveyResponses.CL_EN_GEN_ID,ETOSurveyResponses.AuditDate
          ,CASE when ETOPStaff.SiteID IS null then ETOStaff.SiteID else ETOPStaff.SiteID END, 0, ms.SourceSurveyID
          from dbo.Mstr_surveys ms
          inner join ' +@P_ETOSRVRDB +'.dbo.SurveyResponses ETOSurveyResponses
                on ms.SurveyID = ETOSurveyResponses.SurveyID
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
set @SQL = @SQL +' 
where ms.DW_TableName = ''' +@DW_TableName +'''
 and (select count(*) from ' + +@DW_TableName +' tbl
     where tbl.SurveyResponseID = ETOSurveyResponses.SurveyResponseID) = 0
 and ETOSurveyResponses.DraftSavedOn is null
 and ETOSurveyResponses.SurveyDate >= convert(datetime,''' 
      +Convert(varchar(20),@BegDate,120) +''',120) 
 and ' +convert(varchar,isnull(@p_surveyID,999999)) +' in (999999,MS.SurveyID)'
   set @SQL = @SQL +'
 and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = isnull(ETOPStaff.SiteID,ETOStaff.SiteID)
                      and isnull(ex2.tables_to_ignore,'''') not like ''%' +@DW_TableName +'%'' )'

   IF @p_debug_level = 3
      print ' '
      Print @SQL

   IF upper(@p_no_exec_flag) != 'Y'
      EXEC (@SQL)


----------------------------------------------------------------------------------------
-- Process the survey elements, updating all DW Survey records
-- that have the ElementsProcessed bit still set to null
----------------------------------------------------------------------------------------
   IF @p_debug_level = 3
      print ' '
      print 'Processing Elements for ' +@DW_TableName 

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
         Select SurveyResponseID, SurveyID
           FROM  '+@DW_TableName +'
          where ' +convert(varchar,isnull(@p_surveyID,999999)) +' in (999999,SurveyID) 
            and isnull(ElementsProcessed,0) != 1 and isnull(DataSource,''ETO'') = ''ETO''
							
         Declare @SurveyResponseID int		
         Declare @SurveyID int
         Open notprocessed
							
         Fetch next from notprocessed into @SurveyResponseID, @SurveyID
							
         While @@FETCH_STATUS = 0
         Begin
            Exec SP_ETO_to_DW_Survey_Responses_Part_B_local @SurveyID, @SurveyResponseID '
                +',' +isnull(convert(varchar,@p_debug_level),'0') +',null 
            Fetch next from notprocessed into @SurveyResponseID, @SurveyID
         End			
				
         CLOSE notprocessed
         DEALLOCATE notprocessed'

      IF @p_debug_level = 3
         print ' '
         Print @SQL

      IF upper(@p_no_exec_flag) != 'Y'
         exec (@SQL)


----------------------------------------------------------------------------------------
-- Process the DW Survey table against ETO Survey Responses, 
--   - Deleting non existing ETO responses from the DW (deleted within ETO)
----------------------------------------------------------------------------------------

   IF @p_debug_level = 3
      print ' '
      print 'Deleting deleted ETO Responses'

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
      +' where isnull(DataSource,''ETO'') = ''ETO'''
      +' and not exists (select SurveyResponseID from '
      +@P_ETOSRVRDB +'.dbo.SurveyResponses SR '
      +'where SR.SurveyResponseID = ' +@DW_TableName +'.SurveyResponseID)'
   set @SQL = @SQL +' and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = ' + @DW_TableName + '.SiteId
                      and isnull(ex2.tables_to_ignore,'''') not like ''%' +@DW_TableName +'%'')'
    IF @p_debug_level = 3
       print ' '
       Print @SQL

   IF upper(@p_no_exec_flag) != 'Y'
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
      print ' '
      print 'Adding new records to DW.SurveyResponses'

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
       print ' '
       Print @SQL

    IF upper(@p_no_exec_flag) != 'Y'
       EXEC (@SQL)


----------------------------------------------------------------------------------------
-- Remove non-existing SurveyResponses from the DW SurveyResponses table
----------------------------------------------------------------------------------------

   IF @p_debug_level = 3
      print ' '
      print 'Removing non-existing records from DW.SurveyResponses'

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
       print ' '
       Print @SQL

   IF upper(@p_no_exec_flag) != 'Y'
      EXEC (@SQL)


----------------------------------------------------------------------------------------
-- Continue
----------------------------------------------------------------------------------------

   FETCH next from  SurveyCursor
         into @DW_TableName
             ,@SurveyType
   
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
print 'End Process: SP_ETO_to_DW_Survey_Responses_V2'
GO
