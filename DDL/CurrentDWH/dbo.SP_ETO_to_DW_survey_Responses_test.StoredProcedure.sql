USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_ETO_to_DW_survey_Responses_test]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_ETO_to_DW_survey_Responses_test
CREATE PROCEDURE [dbo].[SP_ETO_to_DW_survey_Responses_test]
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
-- History: 20101205 - process survey inserts only if surveys exist in ETO
--                     Broke out actually element updates to part_b so that DW survey responses
--                     could be filtered for elements not yet processed.

DECLARE @p_ETOSRVRDB	nvarchar(50)
set @p_ETOSRVRDB = 'ETOSRVR.etosolaris'

DECLARE @Process	nvarchar(50)
set @process = 'SP_ETO_TO_DW_SURVEY_RESPONSES_TEST'

DECLARE @SurveyID	int
DECLARE @SurveyType	nvarchar(10)
DECLARE @DW_TableName	nvarchar(50)
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
print 'Start Process: SP_ETO_to_DW_Survey_Responses (TEST) - Building SurveyCursor'

DECLARE SurveyCursor Cursor for
select SurveyID
      ,SurveyType
      ,DW_TableName
  from dbo.Mstr_surveys
 where isnull(@p_surveyID,999999) in (999999,SurveyID)
   and DW_TableName is not null
   and (select count(*) 
          from ETOSRVR.etosolaris.dbo.SurveyResponses 
         where SurveyID=Mstr_surveys.SurveyID) > 0
--   and disabled = 0;


OPEN  SurveyCursor

FETCH next from  SurveyCursor
      into @SurveyID
          ,@SurveyType
          ,@DW_TableName

WHILE @@FETCH_STATUS = 0
BEGIN

   set nocount on
   update dbo.process_log 
      set Action = 'Processing Survey Cursor'
         ,Phase = null
         ,Comment = null
         ,index_1 = @SurveyID
         ,index_2 = null
         ,index_3 = null
         ,LogDate = getdate()
    where Process = @process

----------------------------------------------------------------------------------------
-- For each Survey ID, insert the basic survey fields for any Survey Response
-- not yet existing in the DW survey table
-- Validate that respective Entity/Client Survey exists from filtered ETO extraction
----------------------------------------------------------------------------------------
   IF @p_debug_level = 3
      print 'Cont: SP_ETO_to_DW_Survey_Responses - Inserting new survey records '
       +@DW_TableName +', SurveyID=' +convert(varchar,@SurveyID)
/*
-- Build insert with basic fields:
   set @SQL = ''
   IF @p_debug_Level = 0
      set @SQL = 'set nocount on '
   set @SQL = @SQL +'INSERT into ' +@DW_TableName +'
        ([SurveyResponseID],[SurveyID],[ProgramID],[surveydate],[CL_EN_GEN_ID],[AuditDate],[SiteId])
        select 
          ETOSurveyResponses.SurveyResponseID, '+convert(varchar,@SurveyID)
          +', ETOSurveyResponses.ProgramID'
          +', ETOSurveyResponses.SurveyDate, ETOSurveyResponses.CL_EN_GEN_ID,ETOSurveyResponses.AuditDate
          ,ETOSTAFF.SiteID
          from ' +@P_ETOSRVRDB +'.dbo.Surveys etosurveys
          inner join ' +@P_ETOSRVRDB +'.dbo.SurveyResponses ETOSurveyResponses
                on etosurveys.SurveyID = ETOSurveyResponses.SurveyID
	  INNER JOIN ' +@P_ETOSRVRDB +'.dbo.Staff ETOStaff
		ON ETOSurveyResponses.AuditStaffID = ETOStaff.staffid'


-- continue:
   set @SQL = @SQL +' where not exists (select SurveyResponseID from ' +@DW_TableName +'
                            where SurveyResponseID = ETOSurveyResponses.SurveyResponseID)
           and ETOSurveyResponses.SurveyDate >= convert(datetime,''' 
               +Convert(varchar(20),@BegDate,120) +''',120)
           and etosurveys.SurveyID = ' +convert(varchar,@SurveyID)

   IF @p_debug_level = 3
      Print @SQL
   EXEC (@SQL)

*/
----------------------------------------------------------------------------------------
-- Process the survey elements, updating all DW Survey records
-- that have the ElementsProcessed bit still set to null
----------------------------------------------------------------------------------------
   IF @p_debug_level = 3
      print 'Cont: SP_ETO_to_DW_Survey_Responses - Processing Elements for '
       +@DW_TableName +', SurveyID=' +convert(varchar,@SurveyID)

/*
      set @SQL = ''
      IF @p_debug_Level = 0
         set @SQL = 'set nocount on '
      Set @SQL = @SQL +'
         Declare notprocessed cursor for
         Select SurveyResponseID
           FROM  '+@DW_TableName +'
          where surveyId = '+convert(varchar,@SurveyID) +'
            and isnull(ElementsProcessed,0) != 1
							
         Declare @SurveyResponseID int
         Open notprocessed
							
         Fetch next from notprocessed into @SurveyResponseID
							
         While @@FETCH_STATUS = 0
         Begin
            Exec SP_ETO_to_DW_Survey_Responses_Part_B ' +convert(varchar,@SurveyID) +',@SurveyResponseID
            Fetch next from notprocessed into @SurveyResponseID
         End			
				
         CLOSE notprocessed
         DEALLOCATE notprocessed'

      IF @p_debug_level = 3
         Print @SQL
      exec (@SQL)

*/
----------------------------------------------------------------------------------------
-- Process the DW Survey table against ETO Survey Responses, 
--   - Deleting non existing ETO responses from the DW (deleted within ETO)
----------------------------------------------------------------------------------------

   IF @p_debug_level = 3
      print 'Cont: SP_ETO_to_DW_Survey_Responses - Deleting deleted ETO Responses'


   set nocount on
   update dbo.process_log 
      set Phase = 'Removed non-existing ETO Surveys'
         ,LogDate = getdate()
    where Process = @process

----------------------------------------------------------------------------------------
-- Continue
----------------------------------------------------------------------------------------

   FETCH next from  SurveyCursor
         into @SurveyID
             ,@SurveyType
             ,@DW_TableName
   
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

print 'End Process: SP_ETO_to_DW_Survey_Responses (TEST)'
GO
