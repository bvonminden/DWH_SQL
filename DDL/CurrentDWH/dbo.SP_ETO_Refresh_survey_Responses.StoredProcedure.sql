USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_ETO_Refresh_survey_Responses]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_ETO_Refresh_survey_Responses
CREATE PROCEDURE [dbo].[SP_ETO_Refresh_survey_Responses]
  @p_surveyResponseID int = null,
  @p_update_dw         varchar(2) = null,
  @p_debug_level       smallint = 0
AS
-- This script refreshes speceific SurveyResponses from ETO (via VPN) to the local etosolaris db
-- and then to refreshe the corresponding DataWarehouse survey table.
--
-- Parameters:
--   p_surveyResonseid = SurveyResponseID to refresh
--   p_update_dw = Y/N to process corresponding DW table for survey repsponse processed (null = No)
--   p_debug_level = null, 3 
--        (allows ability to display what is being processed, and display sql code
--         null = default display of survey being processed
--         3 = display SQL code
--

-- Uses the dbo.SurveyResponse_DW_Refresh table to process multiple survey responses.
--    If parm @p_surveyResponseID is null, then will process all available entries which have a null ETO_Date_Refreshed.
--

-- Steps:
--   Verify the VPN connection (count surveyelementresponses)
--   Delete the individual SurveyElementResponses record(s) from the response tables (text ,choice, boolean, date, elements)
--   For each of the individual response tables, insert locally, the non existing records from the VPN table
--
-- History: 
--   20110810 - New Procedure
--   20111011 - Added cursor where clause for non-processed (unless specific p_surveyresponse specied)
--   20111107 - Updated for ETO upgrade, replacing SurveyElementResponseText with
--              dbo.SurveyElementResponseNumeric for Numeric fields
--              dbo.SurveyElementResponseArbText for text fields
--   20121001 - Added null parm value when calling the sproc dbo.SP_DW_Refresh_survey_Responses.
--   20130619 - Added bit trigger for xfer_only updates within the dbo.SurveyResponses_DW_Refresh record.
--              This will update only the key items from a client transfer (AuditStaffID, ProgramID)
--              w/o processing each dynamic column.
--   20140318 - Changed IP address for SSI server update.
--   20141212 - updated the extract of the xfer_only trigger to replace null value as zero.
--   20150330 - Changed IP address for new SSI Server.
--   201703270 - Changed IP address for new SSI Server.

DECLARE @p_vpnsrvrDB	nvarchar(50)
DECLARE @p_ETOSRVRDB	nvarchar(50)
set @p_VPNSRVRDB = '[10.35.1.129].etosolaris'
set @p_ETOSRVRDB = 'ETOSRVR.etosolaris'


DECLARE @Process	nvarchar(50)
set @process = 'SP_ETO_REFRESH_SURVEY_RESPONSES'

DECLARE @SurveyID			int
DECLARE @SurveyResponseID		int
DECLARE @ETO_Date_Refreshed 		datetime
DECLARE @comments			varchar(100)
DECLARE @xfer_only			bit

DECLARE @sql            nvarchar(4000)
DECLARE @count		smallint



IF @p_debug_level = 3
   print 'Start Process: SP_ETO_Refresh_Survey_Responses - SurveyResponseID=' +@p_surveyresponseid

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
-- Check for existing VPN connection
----------------------------------------------------------------------------------------

set @count = 0

select @count = count(*)
  from [10.35.1.129].etosolaris.dbo.Surveys;


IF @count = 0
      update dbo.process_log 
         set comment = 'No VPN Connection'
       where Process = @process
ELSE
BEGIN

----------------------------------------------------------------------------------------
-- Setup for either Single refresh or 
-- Multiple Refreshes from the SurveyResponses_DW_Refresh table
----------------------------------------------------------------------------------------

IF @p_surveyresponseid is not null
BEGIN
   -- Check for existance of response in refresh table, if not found, add it:
   set @count = 0
   Select @count = count(*) 
     from SurveyResponses_DW_Refresh 
    where SurveyResponseID = @p_surveyresponseID;

   IF @count = 0
      BEGIN
      insert into SurveyResponses_DW_Refresh
             (SurveyResponseID)
             values (@p_surveyresponseid)
      END
   ELSE
      BEGIN
      UPDATE SurveyResponses_DW_Refresh 
         set ETO_Date_Refreshed = null
            ,processed = 0
       where SurveyResponseID = @p_surveyresponseid
      END
END


----------------------------------------------------------------------------------------
-- Build and process a cursor for qualified Survey Responses to refresh
----------------------------------------------------------------------------------------

DECLARE ETO_SurveyCursor Cursor for
select sr.SurveyID
      ,srdr.SurveyResponseID
      ,srdr.ETO_Date_Refreshed
      ,isnull(srdr.xfer_only,0)
  from dbo.SurveyResponses_DW_Refresh srdr
  left join etosolaris.dbo.surveyresponses sr
     on srdr.SurveyResponseID = sr.SurveyResponseID
 where isnull(@p_surveyresponseid,0) in (0,srdr.SurveyResponseID)
   and isnull(srdr.processed,0) = 0;

OPEN  ETO_SurveyCursor

FETCH next from  ETO_SurveyCursor
      into @SurveyID
          ,@SurveyResponseID
          ,@ETO_Date_Refreshed
          ,@xfer_only


WHILE @@FETCH_STATUS = 0
BEGIN

   set @comments = null

   IF @comments is null and @SurveyID is null
      set @comments = 'ETO SurveyResponse not found'

   IF @comments is not null
   BEGIN
      UPDATE SurveyResponses_DW_Refresh 
         set comments = @comments
       where SurveyResponseID = @surveyresponseid
   END


   IF @comments is null and
      (@ETO_Date_Refreshed is null or
       @p_surveyresponseid is not null)
   BEGIN


      update dbo.process_log 
         set index_1 = @SurveyResponseID
       where Process = @process

----------------------------------------------------------------------------------------
-- Delete existing response table entries 
----------------------------------------------------------------------------------------

  IF @xfer_only = 0
  BEGIN

-- Delete Dates:
   delete etosolaris.dbo.SurveyElementResponseDate
    where SurveyElementResponseID in 
           (select tbl.SurveyElementResponseID
              from etosolaris.dbo.SurveyElementResponseDate tbl
              inner join etosolaris.dbo.SurveyElementResponses ser
                 on ser.SurveyElementResponseID = tbl.SurveyElementResponseID
              where ser.SurveyResponseID = @surveyresponseid);

-- Delete Text:
   delete etosolaris.dbo.SurveyElementResponseArbText
    where SurveyElementResponseID in 
           (select tbl.SurveyElementResponseID
              from etosolaris.dbo.SurveyElementResponseArbText tbl
              inner join etosolaris.dbo.SurveyElementResponses ser
                 on ser.SurveyElementResponseID = tbl.SurveyElementResponseID
              where ser.SurveyResponseID = @surveyresponseid);

-- Delete Numeric:
   delete etosolaris.dbo.SurveyElementResponseNumeric
    where SurveyElementResponseID in 
           (select tbl.SurveyElementResponseID
              from etosolaris.dbo.SurveyElementResponseNumeric tbl
              inner join etosolaris.dbo.SurveyElementResponses ser
                 on ser.SurveyElementResponseID = tbl.SurveyElementResponseID
              where ser.SurveyResponseID = @surveyresponseid);

-- Delete Choices:
   delete etosolaris.dbo.SurveyElementResponseChoice
    where SurveyElementResponseID in 
           (select tbl.SurveyElementResponseID
              from etosolaris.dbo.SurveyElementResponseChoice tbl
              inner join etosolaris.dbo.SurveyElementResponses ser
                 on ser.SurveyElementResponseID = tbl.SurveyElementResponseID
              where ser.SurveyResponseID = @surveyresponseid);

-- Delete ECR:
   delete etosolaris.dbo.SurveyElementResponseECR
    where SurveyElementResponseID in 
           (select tbl.SurveyElementResponseID
              from etosolaris.dbo.SurveyElementResponseECR tbl
              inner join etosolaris.dbo.SurveyElementResponses ser
                 on ser.SurveyElementResponseID = tbl.SurveyElementResponseID
              where ser.SurveyResponseID = @surveyresponseid);

-- Delete PCR:
   delete etosolaris.dbo.SurveyElementResponsePCR
    where SurveyElementResponseID in 
           (select tbl.SurveyElementResponseID
              from etosolaris.dbo.SurveyElementResponsePCR tbl
              inner join etosolaris.dbo.SurveyElementResponses ser
                 on ser.SurveyElementResponseID = tbl.SurveyElementResponseID
              where ser.SurveyResponseID = @surveyresponseid);

-- Delete Boolean:
   delete etosolaris.dbo.SurveyElementResponseBoolean
    where SurveyElementResponseID in 
           (select tbl.SurveyElementResponseID
              from etosolaris.dbo.SurveyElementResponseBoolean tbl
              inner join etosolaris.dbo.SurveyElementResponses ser
                 on ser.SurveyElementResponseID = tbl.SurveyElementResponseID
              where ser.SurveyResponseID = @surveyresponseid);

-- Delete Final Survey List of Response Elements:
   delete etosolaris.dbo.SurveyElementResponses
    where SurveyElementResponseID in 
          (select tbl.SurveyElementResponseID
              from etosolaris.dbo.SurveyElementResponses tbl
              inner join etosolaris.dbo.SurveyElements se
                 on tbl.SurveyElementID = se.SurveyElementID
              where tbl.SurveyResponseID = @surveyresponseid
                and se.SurveyElementTypeID in (1,2,3,4,6,7,8,9,10,11,12));

  END  /* end of conditional check for not an xfer_only transaction */


----------------------------------------------------------------------------------------
-- Update SurveyResponse master table
----------------------------------------------------------------------------------------

  update etosolaris.dbo.SurveyResponses
     set SurveyDate = vpnSR.SurveyDate
        ,CL_EN_GEN_ID = vpnsr.CL_EN_GEN_ID
        ,Password = vpnSR.Password
        ,AuditStaffID = vpnSr.AuditStaffID
        ,AuditDate = vpnSR.AuditDate
        ,ResponseCreationDate = vpnSR.ResponseCreationDate
        ,Identifier = vpnSR.Identifier
        ,ClCaseID = vpnSR.ClCaseID
        ,ProgramID = vpnSR.ProgramID
        ,DraftSavedOn = vpnSR.DraftSavedOn
        ,ApprovalStatus = vpnSR.ApprovalStatus
        ,SurveyResponseID_Source = vpnSR.SurveyResponseID_Source
    from etosolaris.dbo.SurveyResponses localSR
    inner join [10.35.1.129].etosolaris.dbo.SurveyResponses vpnSR
       on localSR.SurveyResponseID = vpnsr.SurveyResponseID
    where localSR.SurveyResponseID = @surveyresponseid


----------------------------------------------------------------------------------------
-- Reload response table entries from vpn tables
----------------------------------------------------------------------------------------

  IF @xfer_only = 0
  BEGIN

-- Refresh main list of Survey Response Elements:
   insert into etosolaris.dbo.SurveyElementResponses
   select tbl.* 
     from [10.35.1.129].etosolaris.dbo.SurveyElementResponses tbl
    where tbl.SurveyResponseID = @surveyresponseid
      and not exists (select SurveyElementResponseID
                        from etosolaris.dbo.SurveyElementResponses
                       where SurveyElementResponseID = tbl.SurveyElementResponseID)

-- Refresh Dates:
   insert into etosolaris.dbo.SurveyElementResponseDate
   select tbl.* 
     from [10.35.1.129].etosolaris.dbo.SurveyElementResponses ser
     inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponseDate tbl
        on tbl.SurveyElementResponseID = ser.SurveyElementResponseID
    where ser.SurveyResponseID = @surveyresponseid
      and not exists (select SurveyElementResponseID
                        from etosolaris.dbo.SurveyElementResponseDate
                       where SurveyElementResponseID = tbl.SurveyElementResponseID)

-- Refresh Text:
   insert into etosolaris.dbo.SurveyElementResponseArbText
   select tbl.* 
     from [10.35.1.129].etosolaris.dbo.SurveyElementResponses ser
     inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponseArbText tbl
        on tbl.SurveyElementResponseID = ser.SurveyElementResponseID
    where ser.SurveyResponseID = @surveyresponseid
      and not exists (select SurveyElementResponseID
                        from etosolaris.dbo.SurveyElementResponseArbText
                       where SurveyElementResponseID = tbl.SurveyElementResponseID)

-- Refresh Numeric:
   insert into etosolaris.dbo.SurveyElementResponseNumeric
   select tbl.* 
     from [10.35.1.129].etosolaris.dbo.SurveyElementResponses ser
     inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponseNumeric tbl
        on tbl.SurveyElementResponseID = ser.SurveyElementResponseID
    where ser.SurveyResponseID = @surveyresponseid
      and not exists (select SurveyElementResponseID
                        from etosolaris.dbo.SurveyElementResponseNumeric
                       where SurveyElementResponseID = tbl.SurveyElementResponseID)


-- Refresh Choices:
   insert into etosolaris.dbo.SurveyElementResponseChoice
   select tbl.* 
     from [10.35.1.129].etosolaris.dbo.SurveyElementResponses ser
     inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponseChoice tbl
        on tbl.SurveyElementResponseID = ser.SurveyElementResponseID
    where ser.SurveyResponseID = @surveyresponseid
      and not exists (select SurveyElementResponseID
                        from etosolaris.dbo.SurveyElementResponseChoice
                       where SurveyElementResponseID = tbl.SurveyElementResponseID)

-- Refresh ECR:
   insert into etosolaris.dbo.SurveyElementResponseECR
   select tbl.* 
     from [10.35.1.129].etosolaris.dbo.SurveyElementResponses ser
     inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponseECR tbl
        on tbl.SurveyElementResponseID = ser.SurveyElementResponseID
    where ser.SurveyResponseID = @surveyresponseid
      and not exists (select SurveyElementResponseID
                        from etosolaris.dbo.SurveyElementResponseECR
                       where SurveyElementResponseID = tbl.SurveyElementResponseID)

-- Refresh PCR:
   insert into etosolaris.dbo.SurveyElementResponsePCR
   select tbl.* 
     from [10.35.1.129].etosolaris.dbo.SurveyElementResponses ser
     inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponsePCR tbl
        on tbl.SurveyElementResponseID = ser.SurveyElementResponseID
    where ser.SurveyResponseID = @surveyresponseid
      and not exists (select SurveyElementResponseID
                        from etosolaris.dbo.SurveyElementResponsePCR
                       where SurveyElementResponseID = tbl.SurveyElementResponseID)

-- Refresh Boolean:
   insert into etosolaris.dbo.SurveyElementResponseBoolean
   select tbl.* 
     from [10.35.1.129].etosolaris.dbo.SurveyElementResponses ser
     inner join [10.35.1.129].etosolaris.dbo.SurveyElementResponseBoolean tbl
        on tbl.SurveyElementResponseID = ser.SurveyElementResponseID
    where ser.SurveyResponseID = @surveyresponseid
      and not exists (select SurveyElementResponseID
                        from etosolaris.dbo.SurveyElementResponseBoolean
                       where SurveyElementResponseID = tbl.SurveyElementResponseID)

  END  /* end of conditional check for not an xfer_only transaction */

----------------------------------------------------------------------------------------
--    wrapup for individual response:
      UPDATE SurveyResponses_DW_Refresh 
         set ETO_Date_Refreshed = getdate()
       where SurveyResponseID = @surveyresponseid

      IF upper(substring(@p_update_dw,1,1)) = 'Y'
         BEGIN
            Exec SP_DW_Refresh_Survey_Responses @SurveyResponseID, null, null
         END


   END /* end validation to process */

   FETCH next from  ETO_SurveyCursor
         into @SurveyID
             ,@SurveyResponseID
             ,@ETO_Date_Refreshed
             ,@xfer_only

END -- While loop for Survey Cursor

CLOSE ETO_SurveyCursor
DEALLOCATE ETO_SurveyCursor


END  /* vpn connection verification */

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
   print 'End Process: dbo.SP_ETO_Refresh_survey_Responses'
GO
