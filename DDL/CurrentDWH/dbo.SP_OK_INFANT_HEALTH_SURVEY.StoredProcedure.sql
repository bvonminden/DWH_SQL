USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_OK_INFANT_HEALTH_SURVEY]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_OK_INFANT_HEALTH_SURVEY
--
CREATE PROCEDURE [dbo].[SP_OK_INFANT_HEALTH_SURVEY]
 (@p_AnswerID       int = null)
AS
--
-- This script controls integration of Oklahoma Surveys to the Data Warehouse 
-- INFANT_HEALTH_SURVEY table.
--
-- ** Defaulting Datasource as 'OKLAHOMA'
--               Audit_StaffID = 4614, EntityID=13048, name=Data Migration2, for site 260
--               SurveyID = 1585 Infant Health Care MASTER
--               SiteID = 260
--
-- Table effected - dbo.INFANT_HEALTH_SURVEY
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
--   20140425 - New Procedure.

DECLARE @p_datasource nvarchar(10)
DECLARE @count        smallint
DECLARE @p_stop_flag  nvarchar(2)
DECLARE @Process      nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)
DECLARE @Source_TableName nvarchar(50)
DECLARE @ETO_SiteID             int
DECLARE @ETO_SurveyID_Infant_Health6    int
DECLARE @ETO_SurveyID_Infant_Health24    int
DECLARE @ETO_AuditStaffID       int

set @process = 'SP_OK_INFANT_HEALTH_SURVEY'
set @DW_Tablename = 'INFANT_HEALTH_SURVEY'
set @Source_Tablename = 'VIEW_INFANT_HEALTH_COMBINED'
Set @p_stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()
set @p_datasource = 'OKLAHOMA'
set @ETO_SiteID = 260
set @ETO_SurveyID_Infant_Health6 = 1585
set @ETO_SurveyID_Infant_Health24 = 1585
set @ETO_AuditStaffID = 4614

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)
DECLARE @SQL1            varchar(MAX)
DECLARE @SQL2            varchar(MAX)
DECLARE @SQL3            varchar(MAX)

print 'Processing SP_OK_INFANT_HEALTH_SURVEY: Datasource = ' +isnull(@p_datasource,'NULL')
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
print 'Processing SP_OK_INFANT_HEALTH_SURVEY - retrieving datasource DB Srvr from LOV tables'

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
set @SQL = 'update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo. ''' +@p_datasource +''''
    +' Set [DW_SurveyResponseID] = dwxref.[SurveyResponseID]'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +' Atbl'
    +' inner join dbo.Non_ETO_SurveyResponse_Xref dwxref'
    +' on dwxref.Non_ETO_ID = Atbl.AnswerID and dwxref.source = ''' +@p_datasource +''''
    +' and dwxref.DW_tableName = ''' +@DW_TableName +''''

    print @SQL
    --EXEC (@SQL)
*/



set @SQL1 = 'set nocount off'
    +' insert into dbo.' +@DW_TableName
    +' ([SurveyResponseID],[DataSource],[ElementsProcessed]'
    +' ,[SurveyID]'
    +' ,[SurveyDate]'
    +' ,[AuditDate]'
    +' ,[CL_EN_GEN_ID]'
    +' ,[SiteID]'
    +' ,[ProgramID]'
    +' ,[ClientID]'
    +' ,[NURSE_PERSONAL_0_NAME]'
    +' ,[INFANT_0_ID_NSO]'
    +' ,[INFANT_PERSONAL_0_NAME_FIRST]'
    +' ,[INFANT_PERSONAL_0_NAME_LAST]'
    +' ,[INFANT_BIRTH_0_DOB]'
    +' ,[CLIENT_0_ID_NSO]'
    +' ,[CLIENT_PERSONAL_0_NAME_FIRST]'
    +' ,[CLIENT_PERSONAL_0_NAME_LAST]'
    +' ,[INFANT_HEALTH_PROVIDER_0_PRIMARY]'
    +' ,[INFANT_HEALTH_IMMUNIZ_0_UPDATE]'
    +' ,[INFANT_HEALTH_IMMUNIZ_1_RECORD]'
    +' ,[INFANT_HEALTH_LEAD_0_TEST]'
    +' ,[INFANT_HEALTH_HEIGHT_0_INCHES]'
    +' ,[INFANT_HEALTH_HEIGHT_1_PERCENT]'
    +' ,[INFANT_HEALTH_HEAD_0_CIRC_INCHES]'
    +' ,[INFANT_HEALTH_ER_0_HAD_VISIT]'
    +' ,[INFANT_HEALTH_ER_1_TYPE]'
    +' ,[INFANT_HEALTH_ER_1_INJ_DATE1]'
    +' ,[INFANT_HEALTH_ER_1_INJ_DATE2]'
    +' ,[INFANT_HEALTH_ER_1_INJ_DATE3]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_DATE1]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_DATE2]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_DATE3]'
    +' ,[INFANT_HEALTH_HOSP_0_HAD_VISIT]'
    +' ,[INFANT_BREASTMILK_0_EVER_IHC]'
    +' ,[INFANT_BREASTMILK_1_CONT]'
    +' ,[INFANT_HEALTH_HOSP_1_INJ_DATE1]'
    +' ,[INFANT_HEALTH_HOSP_1_INJ_DATE2]'
    +' ,[INFANT_HEALTH_HOSP_1_INJ_DATE3]'
    +' ,[INFANT_HEALTH_HOSP_1_INGEST_DATE1]'
    +' ,[INFANT_HEALTH_HOSP_1_INGEST_DATE2]'
    +' ,[INFANT_HEALTH_HOSP_1_INGEST_DATE3]'
    +' ,[INFANT_HEALTH_HOSP_1_TYPE]'
    +' ,[INFANT_BREASTMILK_1_AGE_STOP]'
    +' ,[INFANT_BREASTMILK_1_WEEK_STOP]'
    +' ,[INFANT_BREASTMILK_1_EXCLUSIVE_WKS]'
    +' ,[INFANT_SOCIAL_SERVICES_0_REFERRAL]'
    +' ,[INFANT_SOCIAL_SERVICES_1_REFDATE1]'
    +' ,[INFANT_SOCIAL_SERVICES_1_REFDATE2]'
    +' ,[INFANT_SOCIAL_SERVICES_1_REFDATE3]'
    +' ,[INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL]'
    +' ,[INFANT_SOCIAL_SERVICES_1_NHV_REFDATE1]'
    +' ,[INFANT_SOCIAL_SERVICES_1_NHV_REFDATE2]'
    +' ,[INFANT_SOCIAL_SERVICES_1_NHV_REFDATE3]'
    +' ,[INFANT_HEALTH_WEIGHT_0_POUNDS]'
    +' ,[INFANT_HEALTH_WEIGHT_1_OUNCES]'
    +' ,[INFANT_HEALTH_WEIGHT_1_OZ]'
    +' ,[INFANT_HEALTH_WEIGHT_1_PERCENT]'
    +' ,[CLIENT_0_ID_AGENCY]'
    +' ,[INFANT_HOME_0_TOTAL]'
    +' ,[INFANT_HOME_1_ACCEPTANCE]'
    +' ,[INFANT_HOME_1_EXPERIENCE]'
    +' ,[INFANT_HOME_1_INVOLVEMENT]'
    +' ,[INFANT_HOME_1_LEARNING]'
    +' ,[INFANT_HOME_1_ORGANIZATION]'
    +' ,[INFANT_HOME_1_RESPONSIVITY]'
    +' ,[DW_AuditDate])'

set @SQL2 = '
     SELECT  dwxref.SurveyResponseID as SurveyResponseID, ''' +@p_datasource +''''
    +' ,1'
    +' ,case when Atbl.Source_TableNbr = 1 then ' +convert(varchar,@ETO_SurveyID_Infant_Health6 )
          +' when Atbl.Source_TableNbr = 2 then ' +convert(varchar,@ETO_SurveyID_Infant_Health24 ) +' END as SurveyID'
    +' ,Atbl.[SurveyDate]'
    +' ,Atbl.[ChgDateTime] as AuditDate'
    +' ,cxref1.Client_ID as CL_EN_GEN_ID'
    +' , '+convert(varchar,@ETO_SiteID) +' as SiteID'
    +' ,Atbl.[ProgramID]'
    +' ,cxref1.Client_ID as [ClientID]'
    +' ,exref1.Entity_ID as [NURSE_PERSONAL_0_NAME]'
    +' ,Atbl.[BABYID] as [INFANT_0_ID_NSO]'
    +' ,Atbl.[INFANT_PERSONAL_0_NAME_FIRST]'
    +' ,Atbl.[INFANT_PERSONAL_0_NAME_LAST]'
    +' ,null as [INFANT_BIRTH_0_DOB]'
    +' ,cxref1.Client_ID as [CLIENT_0_ID_NSO]'
    +' ,Clients.First_Name as [CLIENT_PERSONAL_0_NAME_FIRST]'
    +' ,Clients.Last_Name as [CLIENT_PERSONAL_0_NAME_LAST]'
    +' ,Atbl.[INFANT_HEALTH_PROVIDER_0_PRIMARY]'
    +' ,null as [INFANT_HEALTH_IMMUNIZ_0_UPDATE]'
    +' ,null as [INFANT_HEALTH_IMMUNIZ_1_RECORD]'
    +' ,Atbl.[INFANT_HEALTH_LEAD_0_TEST]'
    +' ,Atbl.[INFANT_HEALTH_HEIGHT_0_INCHES]'
    +' ,Atbl.[INFANT_HEALTH_HEIGHT_1_PERCENT]'
    +' ,Atbl.[INFANT_HEALTH_HEAD_0_CIRC_INCHES]'
    +' ,Atbl.[INFANT_HEALTH_ER_0_HAD_VISIT]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_TYPE]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INJ_DATE1]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INJ_DATE2]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INJ_DATE3]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INGEST_DATE1]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INGEST_DATE2]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INGEST_DATE3]'
    +' ,Atbl.[INFANT_HEALTH_HOSP_0_HAD_VISIT]'
    +' ,Atbl.[INFANT_BREASTMILK_0_EVER_IHC]'
    +' ,Atbl.[INFANT_BREASTMILK_1_CONT]'
    +' ,Atbl.[INFANT_HEALTH_HOSP_1_INJ_DATE1]'
    +' ,Atbl.[INFANT_HEALTH_HOSP_1_INJ_DATE2]'
    +' ,Atbl.[INFANT_HEALTH_HOSP_1_INJ_DATE3]'
    +' ,Atbl.[INFANT_HEALTH_HOSP_1_INGEST_DATE1]'
    +' ,Atbl.[INFANT_HEALTH_HOSP_1_INGEST_DATE2]'
    +' ,Atbl.[INFANT_HEALTH_HOSP_1_INGEST_DATE3]'
    +' ,Atbl.[INFANT_HEALTH_HOSP_1_TYPE]'
    +' ,Atbl.[INFANT_BREASTMILK_1_AGE_STOP]'
    +' ,Atbl.[INFANT_BREASTMILK_1_WEEK_STOP]'
    +' ,Atbl.[INFANT_BREASTMILK_1_EXCLUSIVE_WKS]'
    +' ,Atbl.[INFANT_SOCIAL_SERVICES_0_REFERRAL]'
    +' ,Atbl.[INFANT_SOCIAL_SERVICES_1_REFDATE1]'
    +' ,Atbl.[INFANT_SOCIAL_SERVICES_1_REFDATE2]'
    +' ,Atbl.[INFANT_SOCIAL_SERVICES_1_REFDATE3]'
    +' ,Atbl.[INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL]'
    +' ,Atbl.[INFANT_SOCIAL_SERVICES_1_NHV_REFDATE1]'
    +' ,Atbl.[INFANT_SOCIAL_SERVICES_1_NHV_REFDATE2]'
    +' ,Atbl.[INFANT_SOCIAL_SERVICES_1_NHV_REFDATE3]'
    +' ,Atbl.[INFANT_HEALTH_WEIGHT_0_POUNDS]'
    +' ,Atbl.[INFANT_HEALTH_WEIGHT_1_OUNCES]'
    +' ,(round(isnull(Atbl.[INFANT_HEALTH_WEIGHT_0_POUNDS],0),0)*16) + isnull(Atbl.[INFANT_HEALTH_WEIGHT_1_OUNCES],0) as [INFANT_BIRTH_1_WEIGHT_1_OZ]'
    +' ,Atbl.[INFANT_HEALTH_WEIGHT_1_PERCENT]'
    +' ,Atbl.[CLIENT_0_ID_AGENCY]'
    +' ,Atbl.[INFANT_HOME_0_TOTAL]'
    +' ,Atbl.[INFANT_HOME_1_ACCEPTANCE]'
    +' ,Atbl.[INFANT_HOME_1_EXPERIENCE]'
    +' ,Atbl.[INFANT_HOME_1_INVOLVEMENT]'
    +' ,Atbl.[INFANT_HOME_1_LEARNING]'
    +' ,Atbl.[INFANT_HOME_1_ORGANIZATION]'
    +' ,Atbl.[INFANT_HOME_1_RESPONSIVITY]'
    +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +' Atbl'
    +'
     inner join Non_ETO_SurveyResponse_Xref dwxref on dwxref.source = ''' +@p_datasource +''''
    +'  and atbl.AnswerID = dwxref.non_ETO_ID'
    +' 
     left join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source =  ''' +@p_datasource +''''
    +'   and cxref1.Non_ETO_ID = Atbl.Client_0_ID_Agency' 
    +' 
     left join dbo.Clients on cxref1.Client_ID = Clients.Client_ID' 
    +' 
     left join dbo.Non_ETO_Entity_Xref exref1 on exref1.Source =  ''' +@p_datasource +''''
    +'   and exref1.Non_ETO_ID = Atbl.NURSEID' 
    +' 
     where not exists (select dwsurvey.SurveyResponseID'
    +' from dbo.' +@DW_TableName +' dwsurvey'
    +' where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and dwsurvey.SurveyResponseID = dwxref.SurveyResponseID)'
     

    print @SQL1
    print @SQL2
    print @SQL3
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) 
       +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
       +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
    EXEC (@SQL1+@SQL2+@SQL3)



----------------------------------------------------------------------------------------
print '  Cont: SP_OK_INFANT_HEALTH_SURVEY - Update changes'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off'
    +' update dbo.' +@DW_TableName
    +' set [SurveyDate] = Atbl.[SurveyDate]'
    +', [AuditDate] = Atbl.[ChgDateTime]'
    +', [CL_EN_GEN_ID] = cxref1.Client_ID'
    --+', [SiteID] = @ETO_SiteID'
    +', [ProgramID] = Atbl.[ProgramID]'
    --+', [IA_StaffID] = Atbl.[IA_StaffID]'
    +', [ClientID] = cxref1.Client_ID'
    --+', [RespondentID] = Atbl.[RespondentID]''
    +' ,[NURSE_PERSONAL_0_NAME] = exref1.Entity_ID'
    +' ,[INFANT_0_ID_NSO] = Atbl.[BABYID]'
    +' ,[INFANT_PERSONAL_0_NAME_FIRST] = Atbl.[INFANT_PERSONAL_0_NAME_FIRST]'
    +' ,[INFANT_PERSONAL_0_NAME_LAST] = Atbl.[INFANT_PERSONAL_0_NAME_LAST]'
    --+' ,[INFANT_BIRTH_0_DOB] = Atbl.[INFANT_BIRTH_0_DOB]'
    +' ,[CLIENT_0_ID_NSO] = cxref1.Client_ID'
    +' ,[CLIENT_PERSONAL_0_NAME_FIRST] = Clients.First_Name'
    +' ,[CLIENT_PERSONAL_0_NAME_LAST] = Clients.Last_Name'
    +' ,[INFANT_HEALTH_PROVIDER_0_PRIMARY] = Atbl.[INFANT_HEALTH_PROVIDER_0_PRIMARY]'
    --+' ,[INFANT_HEALTH_IMMUNIZ_0_UPDATE] = Atbl.[INFANT_HEALTH_IMMUNIZ_0_UPDATE]'
    --+' ,[INFANT_HEALTH_IMMUNIZ_1_RECORD] = Atbl.[INFANT_HEALTH_IMMUNIZ_1_RECORD]'
    +' ,[INFANT_HEALTH_LEAD_0_TEST] = Atbl.[INFANT_HEALTH_LEAD_0_TEST]'
    +' ,[INFANT_HEALTH_HEIGHT_0_INCHES] = Atbl.[INFANT_HEALTH_HEIGHT_0_INCHES]'
    +' ,[INFANT_HEALTH_HEIGHT_1_PERCENT] = Atbl.[INFANT_HEALTH_HEIGHT_1_PERCENT]'
    +' ,[INFANT_HEALTH_HEAD_0_CIRC_INCHES] = Atbl.[INFANT_HEALTH_HEAD_0_CIRC_INCHES]'
    +' ,[INFANT_HEALTH_ER_0_HAD_VISIT] = Atbl.[INFANT_HEALTH_ER_0_HAD_VISIT]'
    +' ,[INFANT_HEALTH_ER_1_TYPE] = Atbl.[INFANT_HEALTH_ER_1_TYPE]'
    +' ,[INFANT_HEALTH_ER_1_INJ_DATE1] = Atbl.[INFANT_HEALTH_ER_1_INJ_DATE1]'
    +' ,[INFANT_HEALTH_ER_1_INJ_DATE2] = Atbl.[INFANT_HEALTH_ER_1_INJ_DATE2]'
    +' ,[INFANT_HEALTH_ER_1_INJ_DATE3] = Atbl.[INFANT_HEALTH_ER_1_INJ_DATE3]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_DATE1] = Atbl.[INFANT_HEALTH_ER_1_INGEST_DATE1]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_DATE2] = Atbl.[INFANT_HEALTH_ER_1_INGEST_DATE2]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_DATE3] = Atbl.[INFANT_HEALTH_ER_1_INGEST_DATE3]'
    +' ,[INFANT_HEALTH_HOSP_0_HAD_VISIT] = Atbl.[INFANT_HEALTH_HOSP_0_HAD_VISIT]'
    +' ,[INFANT_BREASTMILK_0_EVER_IHC] = Atbl.[INFANT_BREASTMILK_0_EVER_IHC]'
    +' ,[INFANT_BREASTMILK_1_CONT] = Atbl.[INFANT_BREASTMILK_1_CONT]'
    +' ,[INFANT_HEALTH_HOSP_1_INJ_DATE1] = Atbl.[INFANT_HEALTH_HOSP_1_INJ_DATE1]'
    +' ,[INFANT_HEALTH_HOSP_1_INJ_DATE2] = Atbl.[INFANT_HEALTH_HOSP_1_INJ_DATE2]'
    +' ,[INFANT_HEALTH_HOSP_1_INJ_DATE3] = Atbl.[INFANT_HEALTH_HOSP_1_INJ_DATE3]'
    +' ,[INFANT_HEALTH_HOSP_1_INGEST_DATE1] = Atbl.[INFANT_HEALTH_HOSP_1_INGEST_DATE1]'
    +' ,[INFANT_HEALTH_HOSP_1_INGEST_DATE2] = Atbl.[INFANT_HEALTH_HOSP_1_INGEST_DATE2]'
    +' ,[INFANT_HEALTH_HOSP_1_INGEST_DATE3] = Atbl.[INFANT_HEALTH_HOSP_1_INGEST_DATE3]'
    +' ,[INFANT_HEALTH_HOSP_1_TYPE] = Atbl.[INFANT_HEALTH_HOSP_1_TYPE]'
    +' ,[INFANT_BREASTMILK_1_AGE_STOP] = Atbl.[INFANT_BREASTMILK_1_AGE_STOP]'
    +' ,[INFANT_BREASTMILK_1_WEEK_STOP] = Atbl.[INFANT_BREASTMILK_1_WEEK_STOP]'
    +' ,[INFANT_BREASTMILK_1_EXCLUSIVE_WKS] = Atbl.[INFANT_BREASTMILK_1_EXCLUSIVE_WKS]'
    +' ,[INFANT_SOCIAL_SERVICES_0_REFERRAL] = Atbl.[INFANT_SOCIAL_SERVICES_0_REFERRAL]'
    +' ,[INFANT_SOCIAL_SERVICES_1_REFDATE1] = Atbl.[INFANT_SOCIAL_SERVICES_1_REFDATE1]'
    +' ,[INFANT_SOCIAL_SERVICES_1_REFDATE2] = Atbl.[INFANT_SOCIAL_SERVICES_1_REFDATE2]'
    +' ,[INFANT_SOCIAL_SERVICES_1_REFDATE3] = Atbl.[INFANT_SOCIAL_SERVICES_1_REFDATE3]'

set @SQL2 = ',[INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL] = Atbl.[INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL]'
    +' ,[INFANT_SOCIAL_SERVICES_1_NHV_REFDATE1] = Atbl.[INFANT_SOCIAL_SERVICES_1_NHV_REFDATE1]'
    +' ,[INFANT_SOCIAL_SERVICES_1_NHV_REFDATE2] = Atbl.[INFANT_SOCIAL_SERVICES_1_NHV_REFDATE2]'
    +' ,[INFANT_SOCIAL_SERVICES_1_NHV_REFDATE3] = Atbl.[INFANT_SOCIAL_SERVICES_1_NHV_REFDATE3]'
    +' ,[INFANT_HEALTH_WEIGHT_0_POUNDS] = Atbl.[INFANT_HEALTH_WEIGHT_0_POUNDS]'
    +' ,[INFANT_HEALTH_WEIGHT_1_OUNCES] = Atbl.[INFANT_HEALTH_WEIGHT_1_OUNCES]'
    +' ,[INFANT_HEALTH_WEIGHT_1_OZ] = (round(isnull(Atbl.[INFANT_HEALTH_WEIGHT_0_POUNDS],0),0)*16) + isnull(Atbl.[INFANT_HEALTH_WEIGHT_1_OUNCES],0)'
    +' ,[INFANT_HEALTH_WEIGHT_1_PERCENT] = Atbl.[INFANT_HEALTH_WEIGHT_1_PERCENT]'
    +' ,[CLIENT_0_ID_AGENCY] = Atbl.[CLIENT_0_ID_AGENCY]'
    --+' ,[INFANT_AGES_STAGES_1_COMM] = Atbl.[INFANT_AGES_STAGES_1_COMM]'
    --+' ,[INFANT_AGES_STAGES_0_VERSION] = Atbl.[INFANT_AGES_STAGES_0_VERSION]'
    --+' ,[INFANT_AGES_STAGES_1_GMOTOR] = Atbl.[INFANT_AGES_STAGES_1_GMOTOR]'
    --+' ,[INFANT_AGES_STAGES_1_FMOTOR] = Atbl.[INFANT_AGES_STAGES_1_FMOTOR]'
    --+' ,[INFANT_AGES_STAGES_1_PSOLVE] = Atbl.[INFANT_AGES_STAGES_1_PSOLVE]'
    --+' ,[INFANT_AGES_STAGES_1_PSOCIAL] = Atbl.[INFANT_AGES_STAGES_1_PSOCIAL]'
    --+' ,[INFANT_AGES_STAGES_SE_0_EMOTIONAL] = Atbl.[INFANT_AGES_STAGES_SE_0_EMOTIONAL]'
    --+' ,[INFANT_HEALTH_HEAD_1_REPORT] = Atbl.[INFANT_HEALTH_HEAD_1_REPORT]'
    --+' ,[INFANT_HEALTH_HEIGHT_1_REPORT] = Atbl.[INFANT_HEALTH_HEIGHT_1_REPORT]'
    --+' ,[INFANT_HEALTH_PROVIDER_0_APPT] = Atbl.[INFANT_HEALTH_PROVIDER_0_APPT]'
    --+' ,[INFANT_HEALTH_WEIGHT_1_REPORT] = Atbl.[INFANT_HEALTH_WEIGHT_1_REPORT]'
    --+' ,[INFANT_HEALTH_ER_1_OTHERDT1] = Atbl.[INFANT_HEALTH_ER_1_OTHERDT1]'
    --+' ,[INFANT_HEALTH_ER_1_INGEST_TREAT1] = Atbl.[INFANT_HEALTH_ER_1_INGEST_TREAT1]'
    --+' ,[INFANT_HEALTH_ER_1_INGEST_TREAT2] = Atbl.[INFANT_HEALTH_ER_1_INGEST_TREAT2]'
    --+' ,[INFANT_HEALTH_ER_1_INGEST_TREAT3] = Atbl.[INFANT_HEALTH_ER_1_INGEST_TREAT3]'
    --+' ,[INFANT_HEALTH_ER_1_INJ_TREAT1] = Atbl.[INFANT_HEALTH_ER_1_INJ_TREAT1]'
    --+' ,[INFANT_HEALTH_ER_1_INJ_TREAT2] = Atbl.[INFANT_HEALTH_ER_1_INJ_TREAT2]'
    --+' ,[INFANT_HEALTH_ER_1_OTHER] = Atbl.[INFANT_HEALTH_ER_1_OTHER]'
    --+' ,[INFANT_HEALTH_ER_1_OTHER_REASON1] = Atbl.[INFANT_HEALTH_ER_1_OTHER_REASON1]'
    --+' ,[INFANT_HEALTH_ER_1_OTHER_REASON2] = Atbl.[INFANT_HEALTH_ER_1_OTHER_REASON2]'
    --+' ,[INFANT_HEALTH_ER_1_OTHER_REASON3] = Atbl.[INFANT_HEALTH_ER_1_OTHER_REASON3]'
    --+' ,[INFANT_HEALTH_ER_1_OTHERDT2] = Atbl.[INFANT_HEALTH_ER_1_OTHERDT2]'
    --+' ,[INFANT_HEALTH_ER_1_OTHERDT3] = Atbl.[INFANT_HEALTH_ER_1_OTHERDT3]'
    +' ,[INFANT_HOME_0_TOTAL] = Atbl.[INFANT_HOME_0_TOTAL]'
    +' ,[INFANT_HOME_1_ACCEPTANCE] = Atbl.[INFANT_HOME_1_ACCEPTANCE]'
    +' ,[INFANT_HOME_1_EXPERIENCE] = Atbl.[INFANT_HOME_1_EXPERIENCE]'
    +' ,[INFANT_HOME_1_INVOLVEMENT] = Atbl.[INFANT_HOME_1_INVOLVEMENT]'
    +' ,[INFANT_HOME_1_LEARNING] = Atbl.[INFANT_HOME_1_LEARNING]'
    +' ,[INFANT_HOME_1_ORGANIZATION] = Atbl.[INFANT_HOME_1_ORGANIZATION]'

set @SQL3 = ',[INFANT_HOME_1_RESPONSIVITY] = Atbl.[INFANT_HOME_1_RESPONSIVITY]'
    --+' ,[INFANT_SOCIAL_SERVICES_1_NHV_REASON1] = Atbl.[INFANT_SOCIAL_SERVICES_1_NHV_REASON1]'
    --+' ,[INFANT_SOCIAL_SERVICES_1_NHV_REASON2] = Atbl.[INFANT_SOCIAL_SERVICES_1_NHV_REASON2]'
    --+' ,[INFANT_SOCIAL_SERVICES_1_NHV_REASON3] = Atbl.[INFANT_SOCIAL_SERVICES_1_NHV_REASON3]'
    --+' ,[INFANT_SOCIAL_SERVICES_1_REASON1] = Atbl.[INFANT_SOCIAL_SERVICES_1_REASON1]'
    --+' ,[INFANT_SOCIAL_SERVICES_1_REASON2] = Atbl.[INFANT_SOCIAL_SERVICES_1_REASON2]'
    --+' ,[INFANT_SOCIAL_SERVICES_1_REASON3] = Atbl.[INFANT_SOCIAL_SERVICES_1_REASON3]'
    --+' ,[NFANT_HEALTH_ER_1_INJ_TREAT3] = Atbl.[NFANT_HEALTH_ER_1_INJ_TREAT3]'
    --+' ,[INFANT_HEALTH_ER_1_INJ_ERvsUC1] = Atbl.[INFANT_HEALTH_ER_1_INJ_ERvsUC1]'
    --+' ,[INFANT_HEALTH_PROVIDER_0_APPT_R2] = Atbl.[INFANT_HEALTH_PROVIDER_0_APPT_R2]'
    --+' ,[INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2] = Atbl.[INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2]'
    --+' ,[INFANT_HEALTH_ER_1_INGEST_ERvsUC1] = Atbl.[INFANT_HEALTH_ER_1_INGEST_ERvsUC1]'
    --+' ,[INFANT_HEALTH_ER_1_INGEST_ERvsUC2] = Atbl.[INFANT_HEALTH_ER_1_INGEST_ERvsUC2]'
    --+' ,[INFANT_HEALTH_ER_1_INGEST_ERvsUC3] = Atbl.[INFANT_HEALTH_ER_1_INGEST_ERvsUC3]'
    --+' ,[INFANT_HEALTH_ER_1_INJ_ERvsUC2] = Atbl.[INFANT_HEALTH_ER_1_INJ_ERvsUC2]'
    --+' ,[INFANT_HEALTH_ER_1_OTHER_ERvsUC1] = Atbl.[INFANT_HEALTH_ER_1_OTHER_ERvsUC1]'
    --+' ,[INFANT_HEALTH_ER_1_OTHER_ERvsUC2] = Atbl.[INFANT_HEALTH_ER_1_OTHER_ERvsUC2]'
    --+' ,[INFANT_HEALTH_NO_ASQ_COMM] = Atbl.[INFANT_HEALTH_NO_ASQ_COMM]'
    --+' ,[INFANT_HEALTH_NO_ASQ_FINE] = Atbl.[INFANT_HEALTH_NO_ASQ_FINE]'
    --+' ,[INFANT_HEALTH_NO_ASQ_GROSS] = Atbl.[INFANT_HEALTH_NO_ASQ_GROSS]'
    --+' ,[INFANT_HEALTH_NO_ASQ_PERSONAL] = Atbl.[INFANT_HEALTH_NO_ASQ_PERSONAL]'
    --+' ,[INFANT_HEALTH_NO_ASQ_PROBLEM] = Atbl.[INFANT_HEALTH_NO_ASQ_PROBLEM]'
    --+' ,[INFANT_HEALTH_NO_ASQ_TOTAL] = Atbl.[INFANT_HEALTH_NO_ASQ_TOTAL]'
    --+' ,[INFANT_HEALTH_ER_1_INJ_ERvsUC3] = Atbl.[INFANT_HEALTH_ER_1_INJ_ERvsUC3]'
    --+' ,[INFANT_HEALTH_ER_1_OTHER_ERvsUC3] = Atbl.[INFANT_HEALTH_ER_1_OTHER_ERvsUC3]'
    --+' ,[INFANT_HEALTH_ER_1_INJ_TREAT3] = Atbl.[INFANT_HEALTH_ER_1_INJ_TREAT3]'
    +', [DW_AuditDate] = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from dbo.' +@DW_TableName +' dwsurvey'
    +' 
     inner join Non_ETO_SurveyResponse_Xref dwxref on dwxref.source = ''' +@p_datasource +''''
    +'  and dwsurvey.SurveyResponseID = dwxref.SurveyResponseID'
    +' 
     inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +' Atbl'
    +' on dwxref.Non_ETO_ID = Atbl.AnswerID'
    +' 
     left join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source =  ''' +@p_datasource +''''
    +'   and cxref1.Non_ETO_ID = Atbl.Client_0_ID_Agency' 
    +' 
     left join dbo.Clients on cxref1.Client_ID = Clients.Client_ID' 
    +' 
     left join dbo.Non_ETO_Entity_Xref exref1 on exref1.Source =  ''' +@p_datasource +''''
    +'   and exref1.Non_ETO_ID = Atbl.NURSEID' 
    +'
     where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and isnull(dwsurvey.AuditDate,convert(datetime,''19700101'',112)) <'
    +' isnull(Atbl.ChgDateTime,convert(datetime,''19700101'',112))'

    print @SQL1
    print @SQL2
    print @SQL3
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) 
       +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
       +', SQL3 Length = ' +CAST(LEN(@SQL3) as varchar)
    EXEC (@SQL1+@SQL2+@SQL3)



----------------------------------------------------------------------------------------
print '  Cont: SP_OK_INFANT_HEALTH_SURVEY - Delete Contacts that no longer exist in AgencyDB'

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

print 'End of Process: SP_OK_INFANT_HEALTH_SURVEY'
GO
