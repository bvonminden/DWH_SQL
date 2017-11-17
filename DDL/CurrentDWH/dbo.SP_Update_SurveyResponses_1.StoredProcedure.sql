USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_Update_SurveyResponses_1]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec dbo.SP_Update_SurveyResponses_1 'ETO_SURVEYRESPONSES'
-- drop proc dbo.SP_Update_SurveyResponses_1
--
CREATE PROCEDURE [dbo].[SP_Update_SurveyResponses_1]
 (@p_process       varchar(30) = null)
AS
--
-- This process reads the SurveyResponses_Updates table to apply changes to the actual survey table.
-- This is to accommodate changed survey responses when they should not have been in ETO.
--
-- Processes: 
--   'VALIDATE compares local SurveyResponses against ETO (VPN), reporting differences in Comments.
--   'DW_SURVEYUPDATE' Updates the actual DW Survey record with the correct CL_EN_GEN_ID
--   'ETO_SURVEYRESPONSES' Updates the local ETO SurveyResponses table.


print 'Begin Procedure: SP_Update_SurveyResponses'

DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_Update_SurveyResponses'

DECLARE @insert_count		int
DECLARE @update_count		int
DECLARE @bypassed_count		int
DECLARE @cursor_count		int
set @insert_count = 0
set @update_count = 0
set @bypassed_count = 0
set @cursor_count = 0

DECLARE @SurveyResponseID	int
DECLARE @surveyid		int
DECLARE @ETO_CL_EN_GEN_ID	int
DECLARE @LOCAL_CL_EN_GEN_ID	int
DECLARE @Flag_ETO_SurveyResponses_Updated	int
DECLARE @Flag_DW_Survey_Updated	bit
DECLARE @tbl_Comments		varchar(300)
DECLARE @DW_Tablename		varchar(50)


DECLARE @loc_SurveyDate		datetime
DECLARE @loc_AuditStaffID	smallint
DECLARE @loc_AuditDate		datetime
DECLARE @loc_ResponseCreationDate	datetime
DECLARE @loc_Identifier		varchar(200)
DECLARE @loc_ClCaseID		varchar(50)
DECLARE @loc_ProgramID		smallint
DECLARE @loc_ApprovalStatus	bit
DECLARE @loc_SurveyResponseID_Source	int

DECLARE @eto_SurveyID		int
DECLARE @eto_SurveyDate		datetime
DECLARE @eto_AuditStaffID	smallint
DECLARE @eto_AuditDate		datetime
DECLARE @eto_ResponseCreationDate	datetime
DECLARE @eto_Identifier		varchar(200)
DECLARE @eto_ClCaseID		varchar(50)
DECLARE @eto_ProgramID		smallint
DECLARE @eto_ApprovalStatus	bit
DECLARE @eto_SurveyResponseID_Source	int

DECLARE @Comments	varchar(200)
DECLARE @SQL		varchar(2000)

set nocount on

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
         ,Phase = @p_process
         ,Comment = null
         ,index_1 = null
         ,index_2 = null
         ,index_3 = null
    where Process = @process

----------------------------------------------------------------------------------------
-- Build an cursor of Survey Responses found to have been updated
----------------------------------------------------------------------------------------
DECLARE SurveyCursor Cursor for
Select sru.SurveyResponseID
      ,sru.surveyid
      ,sru.ETO_CL_EN_GEN_ID
      ,sru.LOCAL_CL_EN_GEN_ID
      ,sru.Flag_ETO_SurveyResponses_Updated
      ,sru.Flag_DW_Survey_Updated
      ,sru.comments
      ,ms.DW_Tablename
  from dbo.SurveyResponses_Updates sru
  inner join dbo.Mstr_surveys ms on sru.surveyid = ms.SurveyID;

OPEN SurveyCursor

FETCH next from SurveyCursor
      into @SurveyResponseID
          ,@surveyid
          ,@ETO_CL_EN_GEN_ID
          ,@LOCAL_CL_EN_GEN_ID
          ,@Flag_ETO_SurveyResponses_Updated
          ,@Flag_DW_Survey_Updated
          ,@tbl_comments
          ,@DW_Tablename


WHILE @@FETCH_STATUS = 0
BEGIN


   set @cursor_count = @cursor_count + 1
   set @comments = ''

set nocount on
update dbo.process_log 
   set Phase = null
      ,index_1=@SurveyResponseID
      ,index_2=@cursor_count
      ,LogDate = getdate()
 where Process = @process

  if upper(@p_process) = 'VALIDATE' and @tbl_Comments is null
  BEGIN
   select @loc_SurveyDate = SurveyDate
         ,@loc_AuditStaffID = AuditStaffID
         ,@loc_AuditDate = AuditDate
         ,@loc_ResponseCreationDate = ResponseCreationDate
         ,@loc_Identifier = Identifier
         ,@loc_ClCaseID = ClCaseID
         ,@loc_ProgramID = ProgramID
         ,@loc_ApprovalStatus = ApprovalStatus
         ,@loc_SurveyResponseID_Source	= SUrveyResponseID_Source
     from ETOSRVR.etosolaris.dbo.surveyresponses
    where SurveyResponseID = @SurveyResponseID;


   select @eto_SurveyID = SurveyID
         ,@eto_SurveyDate = SurveyDate
         ,@eto_AuditStaffID = AuditStaffID
         ,@eto_AuditDate = AuditDate
         ,@eto_ResponseCreationDate = ResponseCreationDate
         ,@eto_Identifier = Identifier
         ,@eto_ClCaseID = ClCaseID
         ,@eto_ProgramID = ProgramID
         ,@eto_ApprovalStatus = ApprovalStatus
         ,@eto_SurveyResponseID_Source	= SUrveyResponseID_Source
     from [192.168.35.83].etosolaris.dbo.surveyresponses
    where SurveyResponseID = @SurveyResponseID;

    IF @SurveyID != @eto_SurveyID
       set @comments = @comments +' SurveyID: ' +convert(varchar,@SurveyID) +'/' +convert(varchar,@eto_SurveyID)
    IF @loc_SurveyDate != @eto_SurveyDate
       set @comments = @comments +' SurveyDate: ' +convert(varchar,@loc_SurveyDate) +'/' +convert(varchar,@eto_SurveyDate)
    IF @loc_AuditStaffID != @eto_AuditStaffID
       set @comments = @comments +' AuditStaffID: ' +convert(varchar,@loc_AuditStaffID) +'/' +convert(varchar,@eto_AuditStaffID)
    IF @loc_AuditDate != @eto_AuditDate
       set @comments = @comments +' AuditDate: ' +convert(varchar,@loc_AuditDate) +'/' +convert(varchar,@eto_AuditDate)
    IF @loc_ResponseCreationDate != @eto_ResponseCreationDate
       set @comments = @comments +' ResponseCreationDate: ' +convert(varchar,@loc_ResponseCreationDate) +'/' +convert(varchar,@eto_ResponseCreationDate)
    IF @loc_Identifier != @eto_Identifier
       set @comments = @comments +' Identifier: ' +@loc_Identifier +'/' +@eto_Identifier
    IF @loc_ClCaseID != @eto_ClCaseID
       set @comments = @comments +'@ClCaseID: ' +@loc_ClCaseID +'/' +@eto_ClCaseID
    IF @loc_ProgramID != @eto_ProgramID
       set @comments = @comments +' ProgramID: ' +convert(varchar,@loc_ProgramID) +'/' +convert(varchar,@eto_ProgramID)
    --IF @loc_ApprovalStatus != @eto_ApprovalStatus
    --   set @comments = @comments +' ApprovalStatus: ' +convert(varchar,@loc_ApprovalStatus) +'/' +convert(varchar,@eto_ApprovalStatus)
    IF @loc_SurveyResponseID_Source != @eto_SurveyResponseID_Source
       set @comments = @comments +' SurveyResponseID_Source: ' +convert(varchar,@loc_SurveyResponseID_Source) +'/' +convert(varchar,@eto_SurveyResponseID_Source)

    update dbo.SurveyResponses_Updates
       set Comments = @Comments
          ,ETO_SurveyResponseDate = @eto_SurveyDate
     where SurveyResponseID = @SurveyresponseID

  END  /* end of validate process */


  IF upper(@p_process) = 'DW_SURVEYUPDATE' and @flag_dw_survey_updated is null
  BEGIN

     Set @SQL = 'set nocount on 
        update dbo.' +@DW_Tablename +' set CL_EN_GEN_ID = ' +convert(varchar,@ETO_CL_EN_GEN_ID )
        +' where SurveyResponseID = '+convert(varchar,@SurveyResponseID)

     -- print @SQL
     exec(@SQL)

     update dbo.SurveyResponses_Updates
        set Flag_DW_Survey_Updated = 1
      where SurveyResponseID = @SurveyResponseID


  END  /* end of Update process for DW_Survey Tables */


  IF upper(@p_process) = 'ETO_SURVEYRESPONSES' and @Flag_ETO_SurveyResponses_Updated is null
  BEGIN

     Set @SQL = 'set nocount on 
        update ETOSRVR.etosolaris.dbo.SurveyResponses set CL_EN_GEN_ID = ' +convert(varchar,@ETO_CL_EN_GEN_ID )
        +' where SurveyResponseID = '+convert(varchar,@SurveyResponseID)

     -- print @SQL
     exec(@SQL)

     update dbo.SurveyResponses_Updates
        set Flag_ETO_SurveyResponses_Updated = 1
      where SurveyResponseID = @SurveyResponseID


  END  /* end of Update process for DW_Survey Tables */


   FETCH next from SurveyCursor
         into @SurveyResponseID
             ,@surveyid
             ,@ETO_CL_EN_GEN_ID
             ,@LOCAL_CL_EN_GEN_ID
             ,@Flag_ETO_SurveyResponses_Updated
             ,@Flag_DW_Survey_Updated
             ,@tbl_comments
             ,@DW_Tablename


END /* End of SurveyCursor loop */

CLOSE SurveyCursor
DEALLOCATE SurveyCursor

print 'Records Processed: ' +convert(varchar,@cursor_count)

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

PRINT 'End of Procedure: SP_Update_SurveyResponses_1'
GO
