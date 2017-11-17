USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_DW_Refresh_survey_Responses_2nd]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_DW_Refresh_survey_Responses_2nd
CREATE PROCEDURE [dbo].[SP_DW_Refresh_survey_Responses_2nd]
  @p_surveyResponseID int = null,
  @p_pseudonym nvarchar(50) = null,
  @p_debug_level smallint = 0
AS
-- This script refreshes speceific SurveyResponses from Local ETOSOLARIS to the DataWarehouse survey table.
--
-- ** 2nd version to run against table dbo.SurveyResponses_DW_Refresh_2nd
--    Table is loaded manually outside of regular integration processing as needed.
--    (copied from the original 12/13/2014 to run simultaniously with the ETO refresh for ASQ03_Survey)
--
--
-- Parameters:
--   p_surveyResonseid = SurveyResponseID to refresh
--   p_debug_level = null, 3 
--        (allows ability to display what is being processed, and display sql code
--         null = default display of survey being processed
--         3 = display SQL code
--
-- Steps:
--   Verify the VPN connection (count surveyelementresponses)
--   Delete the individual SurveyElementResponses record(s) from the response tables (text ,choice, boolean, date, elements)
--   For each of the individual response tables, insert locally, the non existing records from the VPN table
--
-- History: 
--   20110810 - New Procedure
--   20111011 - Added cursor where clause for non-processed (unless specific p_surveyresponse specied)
--   20111215 - Added update to survey record for master items such as CL_EN_GEN_ID, Program_ID, etc.
--   20121001 - Added parm for pseudonym to optionally process just one column instead of entire response.
--               ** if supplied, will not update the record's master columns.
--   20130523 - Added SiteID to items being updated due to client transfer.
--   20130619 - Added bit trigger for xfer_only updates within the dbo.SurveyResponses_DW_Refresh record.
--              This will update only the key items from a client transfer (SiteID, ProgramID)
--              w/o processing each dynamic column.
--   20141212 - updated the extract of the xfer_only trigger to replace null value as zero.

DECLARE @p_vpnsrvrDB	nvarchar(50)
DECLARE @p_ETOSRVRDB	nvarchar(50)
set @p_ETOSRVRDB = 'ETOSRVR.etosolaris'


DECLARE @Process	nvarchar(50)
set @process = 'SP_DW_REFRESH_SURVEY_RESPONSES_2nd'

DECLARE @SurveyID			int
DECLARE @SurveyResponseID		int
DECLARE @SurveyElementResponseID	int
DECLARE @DW_TableName			nvarchar(50)
DECLARE @DW_Date_Refreshed 		datetime
DECLARE @comments			varchar(100)
DECLARE @xfer_only			bit

DECLARE @sql            nvarchar(4000)
DECLARE @count		smallint


IF @p_debug_level = 3
   print 'Start Process: SP_DW_Refresh_Survey_Responses_2nd - SurveyResponseID=' +isnull(convert(varchar,@p_surveyresponseid),'null')

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
-- Setup for either Single refresh or 
-- Multiple Refreshes from the SurveyResponses_DW_Refresh_2nd table
----------------------------------------------------------------------------------------

IF @p_surveyresponseid is not null
BEGIN
   -- Check for existance of response in refresh table, if not found, add it:
   set @count = 0
   Select @count = count(*) 
     from SurveyResponses_DW_Refresh_2nd 
    where SurveyResponseID = @p_surveyresponseID;

   IF @count = 0
      BEGIN
      insert into SurveyResponses_DW_Refresh_2nd 
             (SurveyResponseID, DW_Date_Refreshed)
             values (@p_surveyresponseid,null)
      END
   ELSE
      BEGIN
      UPDATE SurveyResponses_DW_Refresh_2nd 
         set DW_Date_Refreshed = null
            ,processed = 0
       where SurveyResponseID = @p_surveyresponseid
      END
END


----------------------------------------------------------------------------------------
-- Build and process a cursor for qualified Survey Responses to refresh
----------------------------------------------------------------------------------------

DECLARE SurveyCursor Cursor for
select sr.SurveyID
      ,srdr.SurveyResponseID
      ,ms.DW_TableName
      ,srdr.DW_Date_Refreshed
      ,isnull(srdr.xfer_only,0)
  from dbo.SurveyResponses_DW_Refresh_2nd srdr
  left join etosolaris.dbo.surveyresponses sr
     on srdr.SurveyResponseID = sr.SurveyResponseID
  left join dbo.Mstr_surveys ms
     on sr.SurveyID = ms.SurveyID
 where isnull(@p_surveyresponseid,0) in (0,srdr.SurveyResponseID)
   and isnull(srdr.processed,0) = 0
   --and ms.DW_TableName is not null;

OPEN  SurveyCursor

FETCH next from  SurveyCursor
      into @SurveyID
          ,@SurveyResponseID
          ,@DW_TableName
          ,@DW_Date_Refreshed
          ,@xfer_only


WHILE @@FETCH_STATUS = 0
BEGIN

   print convert(varchar,@surveyID) +', ' +convert(varchar,@surveyresponseID) +', ' +@DW_TableName+', ' +isnull(convert(varchar,@DW_Date_Refreshed),'null')

   set @comments = null

   IF @comments is null and @SurveyID is null
      set @comments = 'SurveyResponse not found'
   IF @comments is null and @DW_TableName is null
      set @comments = 'Survey not mapped for DW Survey Table'

   IF @comments is not null
   BEGIN
      UPDATE SurveyResponses_DW_Refresh_2nd 
         set comments = @comments
            ,DW_TableName = @DW_TableName
       where SurveyResponseID = @surveyresponseid
   END

   IF @comments is null and
      (@DW_Date_Refreshed is null or
       @p_surveyresponseid is not null)
   BEGIN

----------------------------------------------------------------------------------------
-- Delete existing response from Survey table
----------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------
-- Reload response table entry from eto tables
----------------------------------------------------------------------------------------

    IF @p_pseudonym is null
    BEGIN
--    Update for master items which are not survey elements:
      set @SQL = ' '
      IF @p_debug_Level = 0
         set @SQL = 'set nocount on '

      Set @SQL = @SQL +'update ' +@DW_TableName
      +' set ProgramID = ETOSurveyResponses.ProgramID
        ,SiteID = CASE when ETOPStaff.SiteID IS null then ETOStaff.SiteID else ETOPStaff.SiteID END
        ,CL_EN_GEN_ID = ETOSurveyResponses.CL_EN_GEN_ID, AuditDate = ETOSurveyResponses.AuditDate 
        FROM  ' + @DW_TableName + '
          INNER JOIN etosolaris.dbo.SurveyResponses ETOSurveyResponses
          on ' +@DW_TableName + '.SurveyResponseID = ETOSurveyResponses.SurveyResponseID
          INNER JOIN etosolaris.dbo.Staff ETOStaff
            ON  ETOSurveyResponses.AuditStaffID = ETOStaff.staffid
	  LEFT JOIN ETOSRVR.etosolaris.dbo.Programs ETOProg
            ON ETOSurveyResponses.ProgramID = ETOProg.programid
          LEFT JOIN ETOSRVR.etosolaris.dbo.Staff ETOPStaff
            on ETOProg.AuditStaffID = ETOPStaff.StaffID
          Where ' + @DW_TableName + '.SurveyResponseID = '+convert(varchar,@SurveyResponseID)
      IF @p_debug_level = 3
         Print @SQL
      exec (@SQL)
    END


    IF @xfer_only = 0 
      Exec SP_ETO_to_DW_Survey_Responses_Part_B_local @SurveyID, @SurveyResponseID, null, @p_pseudonym

--    wrapup:
      UPDATE SurveyResponses_DW_Refresh_2nd 
         set DW_Date_Refreshed = getdate()
            ,DW_TableName = @DW_TableName
            ,processed = 1
       where SurveyResponseID = @surveyresponseid


   END /* end validation to process */

   FETCH next from  SurveyCursor
         into @SurveyID
             ,@SurveyResponseID
             ,@DW_TableName
             ,@DW_Date_Refreshed
             ,@xfer_only

END -- While loop for Survey Cursor

CLOSE SurveyCursor
DEALLOCATE SurveyCursor


----------------------------------------------------------------------------------------
-- Wrapup
----------------------------------------------------------------------------------------

set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process

IF @p_debug_level = 3
   print 'End Process: dbo.SP_DW_Refresh_survey_Responses_2nd'
GO
