USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_Merge_SurveyResponses]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_Merge_SurveyResponses
CREATE PROCEDURE [dbo].[SP_Merge_SurveyResponses]
  @p_debug_level smallint = 0
AS
-- This script processes the Merged ETO SurveyResponses by updating the 
-- appropriate DW Table with the latest CL_EN_GEN_ID found from the etosolaris db.
--
-- History: 
--   20120509 - New procedure.

DECLARE @p_ETOSRVRDB	nvarchar(50)
set @p_ETOSRVRDB = 'etosolaris'

DECLARE @Process	nvarchar(50)
set @process = 'SP_MERGE_SURVEYRESPONSES'

DECLARE @SurveyID	int
DECLARE @DW_TableName	nvarchar(50)
DECLARE @sql            nvarchar(4000)
DECLARE @count		smallint

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
-- Build and process cursor for each DW Survey Table
----------------------------------------------------------------------------------------
if isnull(@p_debug_level,0) > 0
   print 'Start Process: SP_ETO_to_DW_Survey_Responses_local - Building SurveyCursor'

DECLARE SurveyCursor Cursor for
select distinct ms.DW_TableName
  from dbo.Client_Survey_Merge_Log csml
  inner join dbo.Mstr_surveys ms on csml.surveyid = ms.surveyid
 where processed = 0
 order by ms.DW_TableName;


OPEN  SurveyCursor

FETCH next from  SurveyCursor
      into @DW_TableName

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

   Print 'Processing table: ' +@DW_TableName

-- Process actual SurveyResponse Update:
   set @SQL = 'set nocount off '
   set @SQL = @SQL + ' update ' +@DW_TableName +' set CL_EN_GEN_ID = csml.CL_EN_GEN_ID_New'
   set @SQL = @SQL + ' from ' +@DW_TableName +' DWST'
   set @SQL = @SQL + ' inner join dbo.Client_Survey_Merge_Log csml on dwst.surveyresponseid = csml.surveyresponseid'
   set @SQL = @SQL + ' where csml.processed = 0'


   IF @p_debug_level = 3
      Print @SQL
   EXEC (@SQL)

-- Mark log record as processed:
   set @SQL = 'set nocount on '
   set @SQL = @SQL + ' update dbo.Client_Survey_Merge_Log'
   set @SQL = @SQL + ' set processed = 1'
   set @SQL = @SQL + ' from dbo.Client_Survey_Merge_Log csml'
   set @SQL = @SQL + ' inner join '+@DW_TableName +' dwst on dwst.surveyresponseid = csml.surveyresponseid'
   set @SQL = @SQL + ' where csml.processed = 0'
   set @SQL = @SQL + ' and dwst.CL_EN_GEN_ID = csml.CL_EN_GEN_ID_New'

   IF @p_debug_level = 3
      Print @SQL
   EXEC (@SQL)



----------------------------------------------------------------------------------------
-- Continue
----------------------------------------------------------------------------------------

   FETCH next from  SurveyCursor
         into @DW_TableName
   
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
print 'End Process: SP_Merge_SurveyResponses'
GO
