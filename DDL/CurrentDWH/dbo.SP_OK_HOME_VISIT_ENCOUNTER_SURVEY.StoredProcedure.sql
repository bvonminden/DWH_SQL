USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_OK_HOME_VISIT_ENCOUNTER_SURVEY]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_OK_HOME_VISIT_ENCOUNTER_SURVEY
--
CREATE PROCEDURE [dbo].[SP_OK_HOME_VISIT_ENCOUNTER_SURVEY]
 (@p_AnswerID       int = null)
AS
--
-- This script controls integration of Oklahoma Surveys to the Data Warehouse 
-- HOME_VISIT_ENCOUNTER_Survey table.
--
-- ** Defaulting Datasource as 'OKLAHOMA'
--               SurveyID = 1581 (master survey)
--               Audit_StaffID = 4614, EntityID=13048, name=Data Migration2, for site 260
--
-- Table effected - dbo.Home_Visit_Encounter_Survey
--
-- Insert: select and insert when record is found to be missing in the DW.
-- Update: select and update when record exists in DW and has been changed but has been changed flagged by Audit_Date.
--
-- IDs translated via DW/AgencyDB Non_ETO_Xref mapping:
--    CL_EN_GEN_ID (lookup, using DW.Client_ID)
--    ClientID     (lookup, using DW.Client_ID)
--    NurseID      (lookup, using DW.Entity_ID)
--
-- History:
--   2013218 - New Procedure.

DECLARE @p_datasource nvarchar(10)
DECLARE @count        smallint
DECLARE @p_stop_flag  nvarchar(2)
DECLARE @Process      nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)
DECLARE @Source_TableName nvarchar(50)
DECLARE @ETO_SurveyID        int
DECLARE @ETO_AuditStaffID    int
DECLARE @SurveyResponseID    int
DECLARE @Non_ETO_ID          int

set @process = 'SP_OK_HOME_VISIT_ENCOUNTER_SURVEY'
set @DW_Tablename = 'HOME_VISIT_ENCOUNTER_SURVEY'
set @Source_Tablename = 'VIEW_VISITS'
Set @p_stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()
set @p_datasource = 'OKLAHOMA'
set @ETO_SurveyID = 1581
set @ETO_AuditStaffID = 4614

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)
DECLARE @SQL1            varchar(MAX)
DECLARE @SQL2            varchar(MAX)

print 'Processing SP_OK_HOME_VISIT_ENCOUNTER_SURVEY: Datasource = ' +isnull(@p_datasource,'NULL')
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
print 'Processing SP_OK_HOME_VISIT_ENCOUNTER_SURVEY - retrieving datasource DB Srvr from LOV tables'

set @AgencyDB = null;
select @AgencyDB = Value
  from dbo.View_LOV
 where Name = 'AGENCYDB_BY_DATASOURCE'
   and lOV_Item = @p_datasource

IF @AgencyDB is null
BEGIN
   --set @p_flag_stop = 'X';
   print 'Unable to retrieve LOV AgencyDB for datasource, job stopped'
   set nocount on
   update dbo.process_log 
   set Comment = 'failed, can''t retrieve LOV AgencyDB for datasource'
      ,LogDate = getdate()
 where Process = @process

END
ELSE
BEGIN

----------------------------------------------------------------------------------------
print 'Processing SP_Contacts - Insert new Records - AgencyDB=' + @AgencyDB
print 'AgencyDB Server=' +@AgencyDB_Srvr

-- Extraction for Client:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- create non_ETO xref entries for new SurveyResponse records from AgencyDB:
set @SQL =  'set nocount off'
    +' insert into dbo.Non_ETO_SurveyResponse_Xref'
    +' (Non_ETO_ID, Source, DW_TableName)'
    +'
     select Atbl.AnswerID, ''' +@p_datasource +''''  +',''' +@DW_TableName +''''
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +' Atbl'
    +' where not exists (select dwxref.SurveyResponseID'
    +' from dbo.Non_ETO_SurveyResponse_Xref dwxref'
    +' where dwxref.source = ''' +@p_datasource +''''
    +' and dwxref.Non_ETO_ID = Atbl.AnswerID'
    +' and dwxref.DW_tableName = ''' +@DW_TableName +''''
    +' )'

    print @SQL
    EXEC (@SQL)

/*  bypassed because source may be a view
-- Assign new NON-ETO xref ID to new records from AgencyDB:
set @SQL = 'update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +'
    +' Set [DW_SurveyResponseID] = dwxref.[SurveyResponseID]'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +' Atbl'
    +' inner join dbo.Non_ETO_SurveyResponse_Xref dwxref'
    +' on dwxref.Non_ETO_ID = Atbl.AnswerID and dwxref.source = ''' +@p_datasource +''''
    +' and dwxref.DW_tableName = ''' +@DW_TableName +''''

    print @SQL
    --EXEC (@SQL)
*/


----------------------------------------------------------------------------------------
-- Build and process cursor
-- A cursor is used to trap out bad dada, while allowing a successful subsequent inserts 
----------------------------------------------------------------------------------------

DECLARE SurveyCursor Cursor for
select xref.surveyresponseid, non_ETO_ID
  from dbo.Non_ETO_SurveyResponse_Xref xref
 where xref.source = @p_datasource
   and xref.DW_TableName = 'HOME_VISIT_ENCOUNTER_SURVEY'
   and isnull(@p_AnswerID,'99999999') in ('99999999',xref.Non_ETO_ID)
   and not exists (select surveyresponseid
                     from dbo.Home_Visit_Encounter_Survey tbl
                    where tbl.surveyresponseid = xref.surveyresponseid)
   --bypass:
   --and xref.non_eto_id not in (2704033)

OPEN SurveyCursor

FETCH next from SurveyCursor
      into @SurveyResponseID
          ,@Non_ETO_ID

WHILE @@FETCH_STATUS = 0
BEGIN


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Responses'
      ,LogDate = getdate()
      ,Index_1 = @SurveyResponseID
      ,Index_2 = @Non_ETO_ID
 where Process = @process
---------------------------------------------


   insert into dbo.HOME_VISIT_ENCOUNTER_Survey
      ([SurveyResponseID],[DataSource],[ElementsProcessed]
      ,[SurveyID]
      ,[SurveyDate]
      ,[AuditDate]
      ,[CL_EN_GEN_ID]
      ,[SiteID]
      ,[ProgramID]
      ,[IA_StaffID]
      ,[ClientID]
      ,[RespondentID]
      ,[CLIENT_0_ID_NSO]
      ,[CLIENT_PERSONAL_0_NAME_FIRST]
      ,[CLIENT_PERSONAL_0_NAME_LAST]
      ,[CLIENT_PERSONAL_0_DOB_INTAKE]
      ,[CLIENT_TIME_0_START_VISIT]
      ,[CLIENT_TIME_1_END_VISIT]
      ,[NURSE_MILEAGE_0_VIS]
      ,[NURSE_PERSONAL_0_NAME]
      ,[CLIENT_COMPLETE_0_VISIT]
      ,[CLIENT_LOCATION_0_VISIT]
      ,[CLIENT_ATTENDEES_0_AT_VISIT]
      ,[CLIENT_INVOLVE_0_CLIENT_VISIT]
      ,[CLIENT_INVOLVE_1_GRNDMTHR_VISIT]
      ,[CLIENT_INVOLVE_1_PARTNER_VISIT]
      ,[CLIENT_CONFLICT_0_CLIENT_VISIT]
      ,[CLIENT_CONFLICT_1_GRNDMTHR_VISIT]
      ,[CLIENT_CONFLICT_1_PARTNER_VISIT]
      ,[CLIENT_UNDERSTAND_0_CLIENT_VISIT]
      ,[CLIENT_UNDERSTAND_1_GRNDMTHR_VISIT]
      ,[CLIENT_UNDERSTAND_1_PARTNER_VISIT]
      ,[CLIENT_DOMAIN_0_PERSHLTH_VISIT]
      ,[CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT]
      ,[CLIENT_DOMAIN_0_LIFECOURSE_VISIT]
      ,[CLIENT_DOMAIN_0_MATERNAL_VISIT]
      ,[CLIENT_DOMAIN_0_FRNDFAM_VISIT]
      ,[CLIENT_DOMAIN_0_TOTAL_VISIT]
      ,[CLIENT_CONTENT_0_PERCENT_VISIT]
      ,[CLIENT_ATTENDEES_0_OTHER_VISIT_DESC]
      ,[CLIENT_TIME_1_DURATION_VISIT]
      ,[CLIENT_0_ID_AGENCY]
      ,[CLIENT_CHILD_INJURY_0_PREVENTION]
      ,[CLIENT_IPV_0_SAFETY_PLAN]
      ,[CLIENT_PRENATAL_VISITS_WEEKS]
      ,[CLIENT_NO_REFERRAL]
      ,[CLIENT_PRENATAL_VISITS]
      ,[CLIENT_SCREENED_SRVCS]
      ,[CLIENT_VISIT_SCHEDULE]
      ,[DW_AuditDate])
    SELECT dwxref.SurveyResponseID as SurveyResponseID, @p_datasource, 1
          ,convert(varchar,@ETO_SurveyID)
          ,Atbl.[AnswerDate]
          ,Atbl.[ChgDateTime]
          ,cxref1.Client_ID
          ,Atbl.[SiteID]
          ,Atbl.[ProgramID]
          ,null     /* convert(varchar,@ETO_AuditStaffID) */
          ,null     /*,cxref1.Client_ID*/
          ,null     /* Atbl.[RespondentID]*/
          ,cxref1.Client_ID
          ,Atbl.[#First Name]
          ,Atbl.[#Last Name]
          ,null     /* Atbl.[CLIENT_PERSONAL_0_DOB_INTAKE]*/
          ,Atbl.[CLIENT_TIME_0_START_VISIT]
          ,Atbl.[CLIENT_TIME_1_END_VISIT]
          ,Atbl.[NURSE_MILEAGE_0_VIS]
          ,exref1.Entity_ID
          ,Atbl.[CLIENT_COMPLETE_0_VISIT]
          ,Atbl.[CLIENT_LOCATION_0_VISIT]
          ,Atbl.[CLIENT_ATTENDEES_0_AT_VISIT]
          ,Atbl.[CLIENT_INVOLVE_0_CLIENT_VISIT]
          ,Atbl.[CLIENT_INVOLVE_1_GRNDMTHR_VISIT]
          ,Atbl.[CLIENT_INVOLVE_1_PARTNER_VISIT]
          ,Atbl.[CLIENT_CONFLICT_0_CLIENT_VISIT]
          ,Atbl.[CLIENT_CONFLICT_1_GRNDMTHR_VISIT]
          ,Atbl.[CLIENT_CONFLICT_1_PARTNER_VISIT]
          ,Atbl.[CLIENT_UNDERSTAND_0_CLIENT_VISIT]
          ,Atbl.[CLIENT_UNDERSTAND_1_GRNDMTHR_VISIT]
          ,Atbl.[CLIENT_UNDERSTAND_1_PARTNER_VISIT]
          ,Atbl.[CLIENT_DOMAIN_0_PERSHLTH_VISIT]
          ,Atbl.[CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT]
          ,Atbl.[CLIENT_DOMAIN_0_LIFECOURSE_VISIT]
          ,Atbl.[CLIENT_DOMAIN_0_MATERNAL_VISIT]
          ,Atbl.[CLIENT_DOMAIN_0_FRNDFAM_VISIT]
          ,Atbl.[CLIENT_DOMAIN_0_TOTAL_VISIT]
          ,null     /* Atbl.[CLIENT_CONTENT_0_PERCENT_VISIT]*/
          ,null     /* Atbl.[CLIENT_ATTENDEES_0_OTHER_VISIT_DESC]*/
          ,Atbl.[CLIENT_TIME_1_DURATION_VISIT]
          ,Atbl.[CLIENT_0_ID_AGENCY]
          ,null     /* Atbl.[CLIENT_CHILD_INJURY_0_PREVENTION]*/
          ,null     /* Atbl.[CLIENT_IPV_0_SAFETY_PLAN]*/
          ,null     /* Atbl.[CLIENT_PRENATAL_VISITS_WEEKS]*/
          ,null     /* Atbl.[CLIENT_NO_REFERRAL]*/
          ,null     /* Atbl.[CLIENT_PRENATAL_VISITS]*/
          ,null     /* Atbl.[CLIENT_SCREENED_SRVCS]*/
          ,null     /* Atbl.[CLIENT_VISIT_SCHEDULE]*/
          ,convert(datetime,convert(varchar(23),@runtime,126),126)
     from  AGENCYDBSRVR.OklahomaStaging.dbo.VIEW_VISITS Atbl
    inner join Non_ETO_SurveyResponse_Xref dwxref on dwxref.source =  @p_datasource
           and atbl.AnswerID = dwxref.non_ETO_ID
    left join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source = @p_datasource
          and cxref1.Non_ETO_ID = Atbl.Client_0_ID_Agency
    left join dbo.Non_ETO_Entity_Xref exref1 on exref1.Source = @p_datasource
          and exref1.Non_ETO_ID = Atbl.Nurse_Personal_0_Name 
   where Atbl.AnswerID = @Non_ETO_ID
     and not exists (select dwsurvey.SurveyResponseID
                       from dbo.HOME_VISIT_ENCOUNTER_Survey dwsurvey
                      where dwsurvey.Datasource = @p_datasource
                        and dwsurvey.SurveyResponseID = @SurveyResponseID)



----------------------------------------------------------------------------------------
-- continue in cursor
----------------------------------------------------------------------------------------

   FETCH next from SurveyCursor
         into @SurveyResponseID
             ,@Non_ETO_ID

END -- End of SurveyCursor loop

CLOSE SurveyCursor
DEALLOCATE SurveyCursor




----------------------------------------------------------------------------------------
print '  Cont: SP_OK_HOME_VISIT_ENCOUNTER_SURVEY - Update changes'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off'
    +'  update dbo.HOME_VISIT_ENCOUNTER_Survey'
    +' Set [ElementsProcessed] = 1'
    --+', [SurveyID] = ' +Convert(varchar,@ETO_SurveyID)
    +', [SurveyDate] = Atbl.[AnswerDate]'
    +', [AuditDate] = Atbl.[ChgDateTime]'
    +', [CL_EN_GEN_ID] = cxref1.Client_ID'
    +', [SiteID] = Atbl.[SiteID]'
    +', [ProgramID] = Atbl.[ProgramID]'
    --+', [IA_StaffID] = Atbl.[IA_StaffID]'
    --+', [ClientID] = cxref2.Client_ID'
    --+', [RespondentID] = Atbl.[RespondentID]'
    +', [CLIENT_0_ID_NSO] = cxref1.Client_ID'
    +', [CLIENT_PERSONAL_0_NAME_FIRST] = Atbl.[#First Name]'
    +', [CLIENT_PERSONAL_0_NAME_LAST] = Atbl.[#Last Name]'
    --+', [CLIENT_PERSONAL_0_DOB_INTAKE] = Atbl.[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +', [CLIENT_TIME_0_START_VISIT] = Atbl.[CLIENT_TIME_0_START_VISIT]'
    +', [CLIENT_TIME_1_END_VISIT] = Atbl.[CLIENT_TIME_1_END_VISIT]'
    +', [NURSE_MILEAGE_0_VIS] = Atbl.[NURSE_MILEAGE_0_VIS]'
    +', [NURSE_PERSONAL_0_NAME] = exref1.Entity_ID'
    +', [CLIENT_COMPLETE_0_VISIT] = Atbl.[CLIENT_COMPLETE_0_VISIT]'
    +', [CLIENT_LOCATION_0_VISIT] = Atbl.[CLIENT_LOCATION_0_VISIT]'
    +', [CLIENT_ATTENDEES_0_AT_VISIT] = Atbl.[CLIENT_ATTENDEES_0_AT_VISIT]'
    +', [CLIENT_INVOLVE_0_CLIENT_VISIT] = Atbl.[CLIENT_INVOLVE_0_CLIENT_VISIT]'
    +', [CLIENT_INVOLVE_1_GRNDMTHR_VISIT] = Atbl.[CLIENT_INVOLVE_1_GRNDMTHR_VISIT]'
    +', [CLIENT_INVOLVE_1_PARTNER_VISIT] = Atbl.[CLIENT_INVOLVE_1_PARTNER_VISIT]'
    +', [CLIENT_CONFLICT_0_CLIENT_VISIT] = Atbl.[CLIENT_CONFLICT_0_CLIENT_VISIT]'
    +', [CLIENT_CONFLICT_1_GRNDMTHR_VISIT] = Atbl.[CLIENT_CONFLICT_1_GRNDMTHR_VISIT]'
    +', [CLIENT_CONFLICT_1_PARTNER_VISIT] = Atbl.[CLIENT_CONFLICT_1_PARTNER_VISIT]'
    +', [CLIENT_UNDERSTAND_0_CLIENT_VISIT] = Atbl.[CLIENT_UNDERSTAND_0_CLIENT_VISIT]'
    +', [CLIENT_UNDERSTAND_1_GRNDMTHR_VISIT] = Atbl.[CLIENT_UNDERSTAND_1_GRNDMTHR_VISIT]'
    +', [CLIENT_UNDERSTAND_1_PARTNER_VISIT] = Atbl.[CLIENT_UNDERSTAND_1_PARTNER_VISIT]'
    +', [CLIENT_DOMAIN_0_PERSHLTH_VISIT] = Atbl.[CLIENT_DOMAIN_0_PERSHLTH_VISIT]'
    +', [CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT] = Atbl.[CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT]'
    +', [CLIENT_DOMAIN_0_LIFECOURSE_VISIT] = Atbl.[CLIENT_DOMAIN_0_LIFECOURSE_VISIT]'
    +', [CLIENT_DOMAIN_0_MATERNAL_VISIT] = Atbl.[CLIENT_DOMAIN_0_MATERNAL_VISIT]'
    +', [CLIENT_DOMAIN_0_FRNDFAM_VISIT] = Atbl.[CLIENT_DOMAIN_0_FRNDFAM_VISIT]'
    +', [CLIENT_DOMAIN_0_TOTAL_VISIT] = Atbl.[CLIENT_DOMAIN_0_TOTAL_VISIT]'
    --+', [CLIENT_CONTENT_0_PERCENT_VISIT] = Atbl.[CLIENT_CONTENT_0_PERCENT_VISIT]'
    --+', [CLIENT_ATTENDEES_0_OTHER_VISIT_DESC] = Atbl.[CLIENT_ATTENDEES_0_OTHER_VISIT_DESC]'
    +', [CLIENT_TIME_1_DURATION_VISIT] = Atbl.[CLIENT_TIME_1_DURATION_VISIT]'
    +', [CLIENT_0_ID_AGENCY] = Atbl.[CLIENT_0_ID_AGENCY]'
    --+', [CLIENT_CHILD_INJURY_0_PREVENTION] = Atbl.[CLIENT_CHILD_INJURY_0_PREVENTION]'
    --+', [CLIENT_IPV_0_SAFETY_PLAN] = Atbl.[CLIENT_IPV_0_SAFETY_PLAN]'
    --+', [CLIENT_PRENATAL_VISITS_WEEKS] = Atbl.[CLIENT_PRENATAL_VISITS_WEEKS]'
    --+', [CLIENT_NO_REFERRAL] = Atbl.[CLIENT_NO_REFERRAL]'
    --+', [CLIENT_PRENATAL_VISITS] = Atbl.[CLIENT_PRENATAL_VISITS]'
    --+', [CLIENT_SCREENED_SRVCS] = Atbl.[CLIENT_SCREENED_SRVCS]'
    --+', [CLIENT_VISIT_SCHEDULE] = Atbl.[CLIENT_VISIT_SCHEDULE]'
    +', [DW_AuditDate] = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from dbo.HOME_VISIT_ENCOUNTER_Survey dwsurvey'
    +' inner join Non_ETO_SurveyResponse_Xref dwxref on dwxref.source = ''' +@p_datasource +''''
    +'  and dwsurvey.SurveyResponseID = dwxref.SurveyResponseID'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +' Atbl'
    +' on dwxref.Non_ETO_ID = Atbl.AnswerID'
    +' left join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source =  ''' +@p_datasource +''''
    +'   and cxref1.Non_ETO_ID = Atbl.Client_0_ID_Agency' 
    +' left join dbo.Non_ETO_Entity_Xref exref1 on exref1.Source =  ''' +@p_datasource +''''
    +'   and exref1.Non_ETO_ID = Atbl.Nurse_Personal_0_Name' 
    +'
     where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and isnull(dwsurvey.AuditDate,convert(datetime,''19700101'',112)) < '
    +' isnull(Atbl.ChgDateTime,convert(datetime,''19700101'',112))'


    print @SQL1
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar)
    EXEC (@SQL1)



----------------------------------------------------------------------------------------
print '  Cont: SP_OK_HOME_VISIT_ENCOUNTER_SURVEY - Delete Contacts that no longer exist in AgencyDB'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Deleting ETO Deletions'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

/*
set @SQL =
    ' delete dbo.dbo.' +@Source_Tablename +'
    +' from dbo' +@Source_Tablename +' dwsurvey'
    +' inner join Non_ETO_SurveyResponse_Xref dwxref on dwxref.source = ''' +@p_datasource +''''
    +'  and dwsurvey.SurveyResponseID = dwxref.SurveyResponseID'
    +' where DataSource = @p_datasource'
    +' and not exists (select Atbl.AnswerID'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +' Atbl'
    +' where AnswerID = xref.Non_ETO_ID)
*/


----------------------------------------------------------------------------------------
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

END /* end of stop validation */

print 'End of Process: SP_OK_HOME_VISIT_ENCOUNTER_SURVEY'
GO
