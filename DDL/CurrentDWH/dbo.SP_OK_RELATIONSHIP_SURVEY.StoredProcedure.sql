USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_OK_RELATIONSHIP_SURVEY]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_OK_RELATIONSHIP_SURVEY
--
CREATE PROCEDURE [dbo].[SP_OK_RELATIONSHIP_SURVEY]
 (@p_AnswerID       int = null)
AS
--
-- This script controls integration of Oklahoma Surveys to the Data Warehouse 
-- RELATIONSHIP_Survey table.
--
-- ** Defaulting Datasource as 'OKLAHOMA'
--               Audit_StaffID = 4614, EntityID=13048, name=Data Migration2, for site 260
--               SurveyID = 1612 Relationship Assessment: Infancy - 12 Months MASTER
--                          1725 Relationship Assessment: Pregnancy - 36 Weeks MASTER
--                          1577 Relationship Assessment: Pregnancy-Intake MASTER
--               SiteID = 260
--
-- Table effected - dbo.RELATIONSHIP_Survey
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
--   20131219 - New Procedure.

DECLARE @p_datasource nvarchar(10)
DECLARE @count        smallint
DECLARE @p_stop_flag  nvarchar(2)
DECLARE @Process      nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)
DECLARE @Source_TableName1 nvarchar(50)
DECLARE @Source_TableName2 nvarchar(50)
DECLARE @Source_TableName3 nvarchar(50)
DECLARE @ETO_SurveyID_Intake        int
DECLARE @ETO_SurveyID_12        int
DECLARE @ETO_SurveyID_36        int
DECLARE @ETO_AuditStaffID    int

set @process = 'SP_OK_RELATIONSHIP_SURVEY'
set @DW_Tablename = 'RELATIONSHIP_SURVEY'
set @Source_Tablename1 = 'VIEW_RELATIONSHIPINTAKE'
set @Source_Tablename2 = 'VIEW_RELATIONSHIP12'
set @Source_Tablename3 = 'VIEW_RELATIONSHIP36'
Set @p_stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()
set @p_datasource = 'OKLAHOMA'
set @ETO_SurveyID_Intake = 1612
set @ETO_SurveyID_12 = 1725
set @ETO_SurveyID_36 = 1577
set @ETO_AuditStaffID = 4614

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)
DECLARE @SQL1            varchar(MAX)
DECLARE @SQL2            varchar(MAX)
DECLARE @SQL3            varchar(MAX)

print 'Processing SP_OK_RELATIONSHIP_SURVEY: Datasource = ' +isnull(@p_datasource,'NULL')
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
print 'Processing SP_OK_RELATIONSHIP_SURVEY - retrieving datasource DB Srvr from LOV tables'

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
     from (select AnswerID from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename1 
    +'   UNION ALL select AnswerID from '
    +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename2 
    +'   UNION ALL select AnswerID from '
    +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename3 
    +' )Atbl'
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
set @SQL = 'update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.RELATIONSHIP_Survey'
    +' Set [DW_SurveyResponseID] = dwxref.[SurveyResponseID]'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename1 +' Atbl'
    +' inner join dbo.Non_ETO_SurveyResponse_Xref dwxref'
    +' on dwxref.Non_ETO_ID = Atbl.AnswerID and dwxref.source = ''' +@p_datasource +''''
    +' and dwxref.DW_tableName = ''' +@DW_TableName +''''

    print @SQL
    --EXEC (@SQL)
*/



set @SQL1 = 'set nocount off'
    +' insert into dbo.RELATIONSHIP_Survey'
    +' ([SurveyResponseID],[DataSource],[ElementsProcessed]'
    +' ,[SurveyID]'
    +' ,[SurveyDate]'
    +' ,[AuditDate]'
    +' ,[CL_EN_GEN_ID]'
    +' ,[SiteID]'
    +' ,[ProgramID]'
    --+' ,[IA_StaffID]'
    +' ,[ClientID]'
    --+' ,[RespondentID]'
    +' ,[CLIENT_PERSONAL_0_NAME_FIRST]'
    +' ,[CLIENT_PERSONAL_0_NAME_LAST]'
    --+' ,[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +' ,[NURSE_PERSONAL_0_NAME]'
    +' ,[CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER]'
    +' ,[CLIENT_ABUSE_HIT_0_SLAP_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_HURT_LAST_YR]'
    +' ,[CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER]'
    +' ,[CLIENT_ABUSE_FORCED_0_SEX]'
    +' ,[CLIENT_ABUSE_FORCED_1_SEX_LAST_YR]'
    +' ,[CLIENT_ABUSE_AFRAID_0_PARTNER]'
    --+' ,[CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME]'
    --+' ,[CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME]'
    +' ,[CLIENT_0_ID_AGENCY]'
    --+' ,[ABUSE_EMOTION_0_PHYSICAL_PARTNER]'
    +' ,[DW_AuditDate])'
    +'
     SELECT  dwxref.SurveyResponseID as SurveyResponseID, ''' +@p_datasource +''''
    +' ,1'
    +' ,case when Atbl.Source_TableNbr = 1 then ' +convert(varchar,@ETO_SurveyID_Intake )
          +' when Atbl.Source_TableNbr = 2 then ' +convert(varchar,@ETO_SurveyID_12 )
          +' when Atbl.Source_TableNbr = 3 then ' +convert(varchar,@ETO_SurveyID_36 ) +' END'
    +' ,Atbl.SurveyDate'
    +' ,Atbl.[ChgDateTime]'
    +' ,cxref1.Client_ID'
    +' ,''260'' as SiteID'
    +' ,Atbl.[ProgramID]'
    --+' ,Atbl.[IA_StaffID]'
    +' ,cxref1.Client_ID'
    --+' ,Atbl.[RespondentID]'
    +' ,Atbl.[FIRST_Name]'
    +' ,Atbl.[Last_NAME]'
    --+' ,Atbl.[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +' ,exref1.Entity_ID'
    +' ,Atbl.[CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER]'
    +' ,Atbl.[CLIENT_ABUSE_HIT_0_SLAP_PARTNER]'
    +' ,Atbl.[CLIENT_ABUSE_TIMES_0_HURT_LAST_YR]'
    +' ,Atbl.[CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER]'
    +' ,Atbl.[CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER]'
    +' ,Atbl.[CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER]'
    +' ,Atbl.[CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER]'
    +' ,Atbl.[CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER]'
    +' ,Atbl.[CLIENT_ABUSE_FORCED_0_SEX]'
    +' ,Atbl.[CLIENT_ABUSE_FORCED_1_SEX_LAST_YR]'
    +' ,Atbl.[CLIENT_ABUSE_AFRAID_0_PARTNER]'
    --+' ,Atbl.[CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME]'
    --+' ,Atbl.[CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME]'
    +' ,Atbl.[CLIENT_0_ID_AGENCY]'
    --+' ,Atbl.[ABUSE_EMOTION_0_PHYSICAL_PARTNER]'
    +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'

set @SQL2 = '
     from (select '
    +' 1 as Source_TableNbr'
    +' ,AnswerID'
    +' ,[Date] as SurveyDate'
    +' ,[ChgDateTime]'
    +' ,[CLIENT_0_ID_AGENCY]'
    +' ,NURSEID'
    --+' ,[SiteCode] as SiteID'
    +' ,[ProgramID]'
    --+' ,[IA_StaffID]'
    --+' ,[RespondentID]'
    +' ,[#FIRST Name] as First_Name'
    +' ,[#Last NAME] as Last_Name'
    --+' ,[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +' ,[CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER]'
    +' ,[CLIENT_ABUSE_HIT_0_SLAP_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_HURT_LAST_YR]'
    +' ,[CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER]'
    +' ,[CLIENT_ABUSE_FORCED_0_SEX]'
    +' ,[CLIENT_ABUSE_FORCED_1_SEX_LAST_YR]'
    +' ,[CLIENT_ABUSE_AFRAID_0_PARTNER]'
    --+' ,[CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME]'
    --+' ,[CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME]'
    --+' ,[ABUSE_EMOTION_0_PHYSICAL_PARTNER]'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename1 

    +'
 UNION ALL select '
    +' 2 as Source_TableNbr'
    +' ,AnswerID'
    +' ,[Date] as SurveyDate'
    +' ,[ChgDateTime]'
    +' ,[CLIENT_0_ID_AGENCY]'
    +' ,NURSEID'
    --+' ,[SiteCode] as SiteID'
    +' ,[ProgramID]'
    --+' ,[IA_StaffID]'
    --+' ,[RespondentID]'
    +' ,[#FIRST Name] as First_Name'
    +' ,[#Last NAME] as Last_Name'
    --+' ,[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +' ,[CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER]'
    +' ,[CLIENT_ABUSE_HIT_0_SLAP_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_HURT_LAST_YR]'
    +' ,[CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER]'
    +' ,[CLIENT_ABUSE_FORCED_0_SEX]'
    +' ,[CLIENT_ABUSE_FORCED_1_SEX_LAST_YR]'
    +' ,[CLIENT_ABUSE_AFRAID_0_PARTNER]'
    --+' ,[CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME]'
    --+' ,[CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME]' 
    --+' ,[ABUSE_EMOTION_0_PHYSICAL_PARTNER]'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename2 

    +'
 UNION ALL select '
    +' 3 as Source_TableNbr'
    +' ,AnswerID'
    +' ,[Date] as SurveyDate'
    +' ,[ChgDateTime]'
    +' ,[CLIENT_0_ID_AGENCY]'
    +' ,NURSEID'
    --+' ,[SiteCode] as SiteID'
    +' ,[ProgramID]'
    --+' ,[IA_StaffID]'
    --+' ,[RespondentID]'
    +' ,[#FIRST Name] as First_Name'
    +' ,[#Last NAME] as Last_Name'
    --+' ,[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +' ,[CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER]'
    +' ,[CLIENT_ABUSE_HIT_0_SLAP_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_HURT_LAST_YR]'
    +' ,[CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER]'
    +' ,[CLIENT_ABUSE_FORCED_0_SEX]'
    +' ,[CLIENT_ABUSE_FORCED_1_SEX_LAST_YR]'
    +' ,[CLIENT_ABUSE_AFRAID_0_PARTNER]'
    --+' ,[CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME]'
    --+' ,[CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME]' 
    --+' ,[ABUSE_EMOTION_0_PHYSICAL_PARTNER]'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename3 
    +' ) Atbl
'
set @SQL3 =     
    +' inner join Non_ETO_SurveyResponse_Xref dwxref on dwxref.source = ''' +@p_datasource +''''
    +'  and atbl.AnswerID = dwxref.non_ETO_ID'
    +' left join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source =  ''' +@p_datasource +''''
    +'   and cxref1.Non_ETO_ID = Atbl.Client_0_ID_Agency' 
    +' left join dbo.Non_ETO_Entity_Xref exref1 on exref1.Source =  ''' +@p_datasource +''''
    +'   and exref1.Non_ETO_ID = Atbl.NURSEID' 
    +' where not exists (select dwsurvey.SurveyResponseID'
    +' from dbo.RELATIONSHIP_Survey dwsurvey'
    +' where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and dwsurvey.SurveyResponseID = dwxref.SurveyResponseID)'
     

    print @SQL1
    print @SQL2
    print @SQL3
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) 
         +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
         +', SQL3 Length = ' +CAST(LEN(@SQL3) as varchar)
    EXEC (@SQL1+@SQL2+@SQL3)



----------------------------------------------------------------------------------------
print '  Cont: SP_OK_RELATIONSHIP_SURVEY - Update changes'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off'
    +' update dbo.RELATIONSHIP_Survey'
    +' set [SurveyDate] = Atbl.[SurveyDate]'
    +', [AuditDate] = Atbl.[ChgDateTime]'
    +', [CL_EN_GEN_ID] = cxref1.Client_ID'
    --+', [SiteID] = Atbl.[SiteCode]'
    --+', [ProgramID] = Atbl.[ProgramID]'
    --+', [IA_StaffID] = Atbl.[IA_StaffID]'
    +', [ClientID] = cxref1.Client_ID'
    --+', [RespondentID] = Atbl.[RespondentID]'
    --+', [CLIENT_PERSONAL_0_NAME_FIRST] = Atbl.[CLIENT_PERSONAL_0_NAME_FIRST]'
    +', [CLIENT_PERSONAL_0_NAME_LAST] = Atbl.[LAST_NAME]'
    --+', [CLIENT_PERSONAL_0_DOB_INTAKE] = Atbl.[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +' ,[NURSE_PERSONAL_0_NAME] = exref1.Entity_ID'
    +' ,[CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER] = Atbl.[CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER]'
    +' ,[CLIENT_ABUSE_HIT_0_SLAP_PARTNER] = Atbl.[CLIENT_ABUSE_HIT_0_SLAP_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_HURT_LAST_YR] = Atbl.[CLIENT_ABUSE_TIMES_0_HURT_LAST_YR]'
    +' ,[CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER] = Atbl.[CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER] = Atbl.[CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER] = Atbl.[CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER] = Atbl.[CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER] = Atbl.[CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER]'
    +' ,[CLIENT_ABUSE_FORCED_0_SEX] = Atbl.[CLIENT_ABUSE_FORCED_0_SEX]'
    +' ,[CLIENT_ABUSE_FORCED_1_SEX_LAST_YR] = Atbl.[CLIENT_ABUSE_FORCED_1_SEX_LAST_YR]'
    --+' ,[CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME] = Atbl.[CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME]'
    --+' ,[CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME] = Atbl.[CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME]'
    +' ,[CLIENT_ABUSE_AFRAID_0_PARTNER] = Atbl.[CLIENT_ABUSE_AFRAID_0_PARTNER]'
    +' ,[CLIENT_0_ID_AGENCY] = Atbl.[CLIENT_0_ID_AGENCY]'
    --+' ,[ABUSE_EMOTION_0_PHYSICAL_PARTNER] = Atbl.[ABUSE_EMOTION_0_PHYSICAL_PARTNER]'
    +', [DW_AuditDate] = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from dbo.RELATIONSHIP_Survey dwsurvey'
    +' inner join Non_ETO_SurveyResponse_Xref dwxref on dwxref.source = ''' +@p_datasource +''''
    +'  and dwsurvey.SurveyResponseID = dwxref.SurveyResponseID'
set @sql2 = ' 
    inner join (select '
    +' 1 as Source_TableNbr'
    +' ,AnswerID'
    +' ,[Date] as SurveyDate'
    +' ,[ChgDateTime]'
    +' ,[CLIENT_0_ID_AGENCY]'
    +' ,NURSEID'
    --+' ,[SiteCode] as SiteID'
    +' ,[ProgramID]'
    --+' ,[IA_StaffID]'
    --+' ,[RespondentID]'
    +' ,[#FIRST Name] as First_Name'
    +' ,[#Last NAME] as Last_Name'
    --+' ,[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +' ,[CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER]'
    +' ,[CLIENT_ABUSE_HIT_0_SLAP_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_HURT_LAST_YR]'
    +' ,[CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER]'
    +' ,[CLIENT_ABUSE_FORCED_0_SEX]'
    +' ,[CLIENT_ABUSE_FORCED_1_SEX_LAST_YR]'
    +' ,[CLIENT_ABUSE_AFRAID_0_PARTNER]'
    --+' ,[CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME]'
    --+' ,[CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME]'
    --+' ,[ABUSE_EMOTION_0_PHYSICAL_PARTNER]'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename1 
    +'
 UNION ALL select '
    +' 2 as Source_TableNbr'
    +' ,AnswerID'
    +' ,[Date] as SurveyDate'
    +' ,[ChgDateTime]'
    +' ,[CLIENT_0_ID_AGENCY]'
    +' ,NURSEID'
    --+' ,[SiteCode] as SiteID'
    +' ,[ProgramID]'
    --+' ,[IA_StaffID]'
    --+' ,[RespondentID]'
    +' ,[#FIRST Name] as First_Name'
    +' ,[#Last NAME] as Last_Name'
    --+' ,[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +' ,[CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER]'
    +' ,[CLIENT_ABUSE_HIT_0_SLAP_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_HURT_LAST_YR]'
    +' ,[CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER]'
    +' ,[CLIENT_ABUSE_FORCED_0_SEX]'
    +' ,[CLIENT_ABUSE_FORCED_1_SEX_LAST_YR]'
    +' ,[CLIENT_ABUSE_AFRAID_0_PARTNER]'
    --+' ,[CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME]'
    --+' ,[CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME]' 
    --+' ,[ABUSE_EMOTION_0_PHYSICAL_PARTNER]'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename2 
    +'
 UNION ALL select '
    +' 3 as Source_TableNbr'
    +' ,AnswerID'
    +' ,[Date] as SurveyDate'
    +' ,[ChgDateTime]'
    +' ,[CLIENT_0_ID_AGENCY]'
    +' ,NURSEID'
    --+' ,[SiteCode] as SiteID'
    +' ,[ProgramID]'
    --+' ,[IA_StaffID]'
    --+' ,[RespondentID]'
    +' ,[#FIRST Name] as First_Name'
    +' ,[#Last NAME] as Last_Name'
    --+' ,[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +' ,[CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER]'
    +' ,[CLIENT_ABUSE_HIT_0_SLAP_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_HURT_LAST_YR]'
    +' ,[CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER]'
    +' ,[CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER]'
    +' ,[CLIENT_ABUSE_FORCED_0_SEX]'
    +' ,[CLIENT_ABUSE_FORCED_1_SEX_LAST_YR]'
    +' ,[CLIENT_ABUSE_AFRAID_0_PARTNER]'
    --+' ,[CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME]'
    --+' ,[CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME]' 
    --+' ,[ABUSE_EMOTION_0_PHYSICAL_PARTNER]'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename3 
    +' ) Atbl on dwxref.Non_ETO_ID = Atbl.AnswerID'

    +' 
left join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source =  ''' +@p_datasource +''''
    +'   and cxref1.Non_ETO_ID = Atbl.Client_0_ID_Agency' 
    +' 
left join dbo.Non_ETO_Entity_Xref exref1 on exref1.Source =  ''' +@p_datasource +''''
    +'   and exref1.Non_ETO_ID = Atbl.NURSEID' 
    +'
     where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and isnull(dwsurvey.AuditDate,convert(datetime,''19700101'',112)) <'
    +' isnull(Atbl.ChgDateTime,convert(datetime,''19700101'',112))'

    print @SQL1
    print @SQL2
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) 
         +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
    EXEC (@SQL1+@SQL2)



----------------------------------------------------------------------------------------
print '  Cont: SP_OK_RELATIONSHIP_SURVEY - Delete Contacts that no longer exist in AgencyDB'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Deleting ETO Deletions'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

/*
set @SQL =
    ' delete dbo.dbo.' +@Source_Tablename1 +'
    +' from dbo' +@Source_Tablename1 +' dwsurvey'
    +' inner join Non_ETO_SurveyResponse_Xref dwxref on dwxref.datasource = ''' +@p_datasource +''''
    +'  and dwsurvey.SurveyResponseID = dwxref.SurveyResponseID'
    +' where DataSource = @p_datasource'
    +' and not exists (select Atbl.AnswerID'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename1 +' Atbl'
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

print 'End of Process: SP_OK_RELATIONSHIP_SURVEY'
GO
