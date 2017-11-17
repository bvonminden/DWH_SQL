USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_ETO_to_DW_survey_Responses_by_DW_Tablename]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_ETO_to_DW_survey_Responses_by_DW_Tablename
CREATE PROCEDURE [dbo].[SP_ETO_to_DW_survey_Responses_by_DW_Tablename]
  @p_dw_tablename  varchar(50),
  @p_begdate    smalldatetime = null,
  @p_enddate    smalldatetime = null,
  @p_debug_level smallint = 0
AS
-- This script calls the SP_ETO_to_DW_survey_Responses for only the surveys associated
-- to a specified DW_TableName (survey table).
--
-- History:
--   20101206 - New process

DECLARE @p_ETOSRVRDB	nvarchar(50)
set @p_ETOSRVRDB = 'ETOSRVR.etosolaris'

DECLARE @Process	nvarchar(50)
set @process = 'SP_ETO_TO_DW_SURVEY_RESPONSES_BY_DW_TABLENAME'

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
         ,Phase = @p_dw_tablename
         ,Comment = null
         ,index_1 = null
         ,index_2 = null
         ,index_3 = null
    where Process = @process

----------------------------------------------------------------------------------------
-- Build and process cursor for each Survey 
-- (updated from ETO to the master DW tbl)
----------------------------------------------------------------------------------------
print 'Start Process: SP_ETO_to_DW_Survey_Responses_by_Tablename - ' +@p_dw_tablename

DECLARE DWSurveyCursor Cursor for
select SurveyID
      ,SurveyType
      ,DW_TableName
  from dbo.Mstr_surveys
 where DW_TableName = @p_dw_tablename
   and (select count(*) 
          from ETOSRVR.etosolaris.dbo.SurveyResponses 
         where SurveyID=Mstr_surveys.SurveyID) > 0
--   and disabled = 0;


OPEN  DWSurveyCursor

FETCH next from  DWSurveyCursor
      into @SurveyID
          ,@SurveyType
          ,@DW_TableName

WHILE @@FETCH_STATUS = 0
BEGIN

   set nocount on
   update dbo.process_log 
      set Action = 'Processing Survey Cursor'
         ,Comment = null
         ,index_1 = @SurveyID
         ,index_2 = null
         ,index_3 = null
         ,LogDate = getdate()
    where Process = @process


----------------------------------------------------------------------------------------
-- Process by individual surveys found
----------------------------------------------------------------------------------------
   IF @p_debug_level = 3
      print 'Cont: SP_ETO_to_DW_Survey_Responses_by_Tablename - Processing Elements for '
       +@DW_TableName +', SurveyID=' +convert(varchar,@SurveyID)


      set @SQL = ''
      set @SQL = 'Exec SP_ETO_to_DW_Survey_Responses ' +convert(varchar,@SurveyID)
           +',null,null,' + isnull(convert(varchar,@p_debug_level),'0')

      IF @p_debug_level = 3
         Print @SQL
      exec (@SQL)


----------------------------------------------------------------------------------------
-- Continue
----------------------------------------------------------------------------------------

   FETCH next from DWSurveyCursor
         into @SurveyID
             ,@SurveyType
             ,@DW_TableName
   
END -- While loop for Survey Cursor

CLOSE DWSurveyCursor
DEALLOCATE DWSurveyCursor

set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,LogDate = getdate()
 where Process = @process

print 'End Process: SP_ETO_to_DW_Survey_Responsess_by_DW_Tablename'
GO
