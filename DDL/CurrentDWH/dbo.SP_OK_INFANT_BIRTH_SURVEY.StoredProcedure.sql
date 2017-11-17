USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_OK_INFANT_BIRTH_SURVEY]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_OK_INFANT_BIRTH_SURVEY
--
CREATE PROCEDURE [dbo].[SP_OK_INFANT_BIRTH_SURVEY]
 (@p_AnswerID       int = null)
AS
--
-- This script controls integration of Oklahoma Surveys to the Data Warehouse 
-- INFANT_BIRTH_SURVEY table.
--
-- ** Defaulting Datasource as 'OKLAHOMA'
--               Audit_StaffID = 4614, EntityID=13048, name=Data Migration2, for site 260
--               SurveyID = 1584 Infant Birth MASTER
--               SiteID = 260
--
-- Table effected - dbo.INFANT_BIRTH_SURVEY
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
DECLARE @ETO_SurveyID_Infant_Birth    int
DECLARE @ETO_AuditStaffID       int

set @process = 'SP_OK_INFANT_BIRTH_SURVEY'
set @DW_Tablename = 'INFANT_BIRTH_SURVEY'
set @Source_Tablename = 'INFANT_BIRTH_TBL'
Set @p_stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()
set @p_datasource = 'OKLAHOMA'
set @ETO_SiteID = 260
set @ETO_SurveyID_Infant_Birth = 1584
set @ETO_AuditStaffID = 4614

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)
DECLARE @SQL1            varchar(MAX)
DECLARE @SQL2            varchar(MAX)
DECLARE @SQL3            varchar(MAX)

print 'Processing SP_OK_INFANT_BIRTH_SURVEY: Datasource = ' +isnull(@p_datasource,'NULL')
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
print 'Processing SP_OK_INFANT_BIRTH_SURVEY - retrieving datasource DB Srvr from LOV tables'

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
set @SQL = 'update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@DW_TableName
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
    +' ,[INFANT_PERSONAL_0_FIRST NAME]'
    +' ,[INFANT_PERSONAL_0_LAST NAME]'
    +' ,[INFANT_BIRTH_0_DOB]'
    +' ,[CLIENT_0_ID_NSO]'
    +' ,[CLIENT_PERSONAL_0_NAME_FIRST]'
    +' ,[CLIENT_PERSONAL_0_NAME_LAST]'
    +' ,[INFANT_BIRTH_1_MULTIPLE_BIRTHS]'
    +' ,[INFANT_PERSONAL_0_ETHNICITY]'
    +' ,[INFANT_PERSONAL_0_RACE]'
    +' ,[INFANT_PERSONAL_0_GENDER]'
    +' ,[INFANT_BIRTH_1_WEIGHT_GRAMS]'
    +' ,[INFANT_BIRTH_1_WEIGHT_POUNDS]'
    +' ,[INFANT_BIRTH_1_GEST_AGE]'
    +' ,[INFANT_BIRTH_1_NICU]'
    +' ,[INFANT_BIRTH_1_NICU_DAYS]'
    +' ,[CLIENT_WEIGHT_0_PREG_GAIN]'
    +' ,[INFANT_BREASTMILK_0_EVER_BIRTH]'
    +' ,[INFANT_0_ID_NSO2]'
    +' ,[INFANT_PERSONAL_0_FIRST NAME2]'
    +' ,[INFANT_BIRTH_0_DOB2]'
    +' ,[INFANT_PERSONAL_0_ETHNICITY2]'
    +' ,[INFANT_PERSONAL_0_ETHNICITY3]'
    +' ,[INFANT_PERSONAL_0_RACE2]'
    +' ,[INFANT_PERSONAL_0_RACE3]'
    +' ,[INFANT_PERSONAL_0_GENDER2]'
    +' ,[INFANT_BIRTH_1_WEIGHT_GRAMS2]'
    +' ,[INFANT_BIRTH_1_GEST_AGE2]'
    +' ,[INFANT_BIRTH_1_NICU2]'
    +' ,[INFANT_BIRTH_1_NICU_DAYS2]'
    +' ,[INFANT_0_ID_NSO3]'
    +' ,[INFANT_BIRTH_0_DOB3]'
    +' ,[INFANT_PERSONAL_0_GENDER3]'
    +' ,[INFANT_BIRTH_1_WEIGHT_GRAMS3]'
    +' ,[INFANT_BIRTH_1_WEIGHT_POUNDS3]'
    +' ,[INFANT_BIRTH_1_GEST_AGE3]'
    +' ,[INFANT_BIRTH_1_NICU3]'
    +' ,[INFANT_BIRTH_1_NICU_DAYS3]'
    +' ,[INFANT_BREASTMILK_0_EVER_BIRTH2]'
    +' ,[INFANT_BREASTMILK_0_EVER_BIRTH3]'
    +' ,[INFANT_BIRTH_1_WEIGHT_MEASURE]'
    +' ,[INFANT_BIRTH_1_WEIGHT_OUNCES]'
    +' ,[INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS]'
    +' ,[INFANT_BIRTH_1_WEIGHT_MEASURE2]'
    +' ,[INFANT_BIRTH_1_WEIGHT_MEASURE3]'
    +' ,[INFANT_BIRTH_1_WEIGHT_OUNCES3]'
    +' ,[INFANT_BIRTH_1_WEIGHT_POUNDS2]'
    +' ,[INFANT_BIRTH_1_WEIGHT_OUNCES2]'
    +' ,[INFANT_PERSONAL_0_FIRST NAME3]'
    +' ,[CLIENT_0_ID_AGENCY]'
    +' ,[INFANT_BIRTH_0_CLIENT_ER]'
    +' ,[INFANT_BIRTH_0_CLIENT_URGENT CARE]'
    +' ,[INFANT_BIRTH_1_NICU_R2]'
    +' ,[INFANT_BIRTH_1_NICU_R2_2]'
    +' ,[INFANT_BIRTH_1_NICU_R2_3]'
    +' ,[INFANT_BIRTH_1_NURSERY_R2]'
    +' ,[INFANT_BIRTH_1_NURSERY_R2_2]'
    +' ,[INFANT_BIRTH_1_NURSERY_R2_3]'
    +' ,[INFANT_BIRTH_0_CLIENT_ER_TIMES]'
    +' ,[INFANT_BIRTH_0_CLIENT_URGENT CARE_TIMES]'
    +' ,[INFANT_BIRTH_1_NICU_DAYS_R2]'
    +' ,[INFANT_BIRTH_1_NICU_DAYS_R2_2]'
    +' ,[INFANT_BIRTH_1_NICU_DAYS_R2_3]'
    +' ,[INFANT_BIRTH_1_NURSERY_DAYS_R2]'
    +' ,[INFANT_BIRTH_1_NURSERY_DAYS_R2_2]'
    +' ,[INFANT_BIRTH_1_NURSERY_DAYS_R2_3]'
    +' ,[DW_AuditDate])'

set @SQL2 = '
     SELECT  dwxref.SurveyResponseID as SurveyResponseID, ''' +@p_datasource +''''
    +' ,1'
    +' ,' +convert(varchar,@ETO_SurveyID_Infant_Birth ) +' as SurveyID'
    +' ,Atbl.[SurveyDate]'
    +' ,Atbl.[ChgDateTime] as AuditDate'
    +' ,cxref1.Client_ID as CL_EN_GEN_ID'
    +' , '+convert(varchar,@ETO_SiteID) +' as SiteID'
    +' ,TeamMappingTbl.ProgramID_NHV as [ProgramID]'
    +' ,cxref1.Client_ID as [ClientID]'
    +' ,exref1.Entity_ID as [NURSE_PERSONAL_0_NAME]'
    +' ,Atbl.[INFANT_0_ID_NSO]'
    +' ,Atbl.[INFANT_0_ID_NSO] AS [INFANT_PERSONAL_0_FIRST NAME]'
    +' ,ClinicSite.Sitecode as[INFANT_PERSONAL_0_LAST NAME]'
    +' ,Atbl.[INFANT_BIRTH_0_DOB]'
    +' ,cxref1.Client_ID as [CLIENT_0_ID_NSO]'
    +' ,Clients.First_Name as [CLIENT_PERSONAL_0_NAME_FIRST]'
    +' ,Clients.Last_Name as [CLIENT_PERSONAL_0_NAME_LAST]'
    +' ,Atbl.[INFANT_BIRTH_1_MULTIPLE_BIRTHS]'
    +' ,Atbl.[INFANT_PERSONAL_0_ETHNICITY]'
    +' ,Atbl.[INFANT_PERSONAL_0_RACE]'
    +' ,Atbl.[INFANT_PERSONAL_0_GENDER]'
    +' ,isnull(Atbl.[INFANT_BIRTH_1_WEIGHT_GRAMS],0)'
    +' ,isnull(Atbl.[INFANT_BIRTH_1_WEIGHT_POUNDS],0)'
    +' ,isnull(Atbl.[INFANT_BIRTH_1_GEST_AGE],0)'
    +' ,Atbl.[INFANT_BIRTH_1_NICU]'
    +' ,Atbl.[INFANT_BIRTH_1_NICU_DAYS]'
    +' ,null as [CLIENT_WEIGHT_0_PREG_GAIN]'
    +' ,null as [INFANT_BREASTMILK_0_EVER_BIRTH]'
    +' ,null as [INFANT_0_ID_NSO2]'
    +' ,null as [INFANT_PERSONAL_0_FIRST NAME2]'
    +' ,null as [INFANT_BIRTH_0_DOB2]'
    +' ,null as [INFANT_PERSONAL_0_ETHNICITY2]'
    +' ,null as [INFANT_PERSONAL_0_ETHNICITY3]'
    +' ,null as [INFANT_PERSONAL_0_RACE2]'
    +' ,null as [INFANT_PERSONAL_0_RACE3]'
    +' ,null as [INFANT_PERSONAL_0_GENDER2]'
    +' ,0 as [INFANT_BIRTH_1_WEIGHT_GRAMS2]'
    +' ,null as [INFANT_BIRTH_1_GEST_AGE2]'
    +' ,null as [INFANT_BIRTH_1_NICU2]'
    +' ,null as [INFANT_BIRTH_1_NICU_DAYS2]'
    +' ,null as [INFANT_0_ID_NSO3]'
    +' ,null as [INFANT_BIRTH_0_DOB3]'
    +' ,null as [INFANT_PERSONAL_0_GENDER3]'
    +' ,0 as [INFANT_BIRTH_1_WEIGHT_GRAMS3]'
    +' ,0 as [INFANT_BIRTH_1_WEIGHT_POUNDS3]'
    +' ,null as [INFANT_BIRTH_1_GEST_AGE3]'
    +' ,null as [INFANT_BIRTH_1_NICU3]'
    +' ,null as [INFANT_BIRTH_1_NICU_DAYS3]'
    +' ,null as [INFANT_BREASTMILK_0_EVER_BIRTH2]'
    +' ,null as [INFANT_BREASTMILK_0_EVER_BIRTH3]'
    +' ,null as [INFANT_BIRTH_1_WEIGHT_MEASURE]'
    +' ,isnull(Atbl.[INFANT_BIRTH_1_WEIGHT_OUNCES],0)'
    +' ,case when isnull(Atbl.[INFANT_BIRTH_1_WEIGHT_POUNDS],0) + isnull(Atbl.[INFANT_BIRTH_1_WEIGHT_OUNCES],0) != 0
        then round((((isnull(Atbl.[INFANT_BIRTH_1_WEIGHT_POUNDS],0)*16) + isnull(Atbl.[INFANT_BIRTH_1_WEIGHT_OUNCES],0)) / 0.035274),3) end
 as [INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS]'
    +' ,null as [INFANT_BIRTH_1_WEIGHT_MEASURE2]'
    +' ,null as [INFANT_BIRTH_1_WEIGHT_MEASURE3]'
    +' ,0 as [INFANT_BIRTH_1_WEIGHT_OUNCES3]'
    +' ,0 as [INFANT_BIRTH_1_WEIGHT_POUNDS2]'
    +' ,0 as [INFANT_BIRTH_1_WEIGHT_OUNCES2]'
    +' ,null as [INFANT_PERSONAL_0_FIRST NAME3]'
    +' ,Atbl.[CLIENT_0_ID_AGENCY]'
    +' ,null as [INFANT_BIRTH_0_CLIENT_ER]'
    +' ,null as [INFANT_BIRTH_0_CLIENT_URGENT CARE]'
    +' ,null as [INFANT_BIRTH_1_NICU_R2]'
    +' ,null as [INFANT_BIRTH_1_NICU_R2_2]'
    +' ,null as [INFANT_BIRTH_1_NICU_R2_3]'
    +' ,null as [INFANT_BIRTH_1_NURSERY_R2]'
    +' ,null as [INFANT_BIRTH_1_NURSERY_R2_2]'
    +' ,null as [INFANT_BIRTH_1_NURSERY_R2_3]'
    +' ,null as [INFANT_BIRTH_0_CLIENT_ER_TIMES]'
    +' ,null as [INFANT_BIRTH_0_CLIENT_URGENT CARE_TIMES]'
    +' ,null as [INFANT_BIRTH_1_NICU_DAYS_R2]'
    +' ,null as [INFANT_BIRTH_1_NICU_DAYS_R2_2]'
    +' ,null as [INFANT_BIRTH_1_NICU_DAYS_R2_3]'
    +' ,null as [INFANT_BIRTH_1_NURSERY_DAYS_R2]'
    +' ,null as [INFANT_BIRTH_1_NURSERY_DAYS_R2_2]'
    +' ,null as [INFANT_BIRTH_1_NURSERY_DAYS_R2_3]'
    +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'

set @SQL3 = '
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +' Atbl'
    +' 
     inner join Non_ETO_SurveyResponse_Xref dwxref on dwxref.source = ''' +@p_datasource +''''
    +'  and atbl.AnswerID = dwxref.non_ETO_ID'
    +' 
     left join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Clinic Clinic'
    +'  on Atbl.SiteCode = Clinic.Clinic_no'
    +' 
     left join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.ClinicSite ClinicSite'
    +'  on Clinic.ClinicID = ClinicSite.ClinicID'
    +' 
     left join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.TeamMappingTbl TeamMappingTbl'
    +'  on ClinicSite.SiteCode = TeamMappingTbl.SiteCode'
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
         +', SQL3 Length = ' +CAST(LEN(@SQL3) as varchar)
    EXEC (@SQL1+@SQL2+@SQL3)



----------------------------------------------------------------------------------------
print '  Cont: SP_OK_INFANT_BIRTH_SURVEY - Update changes'

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
    +', [ProgramID] = TeamMappingTbl.ProgramID_NHV'
    --+', [IA_StaffID] = Atbl.[IA_StaffID]'
    +', [ClientID] = cxref1.Client_ID'
    --+', [RespondentID] = Atbl.[RespondentID]''
    +' ,[NURSE_PERSONAL_0_NAME] = exref1.Entity_ID'
    +' ,[INFANT_0_ID_NSO] = Atbl.[INFANT_0_ID_NSO]'
    +' ,[INFANT_PERSONAL_0_FIRST NAME] = Atbl.[INFANT_0_ID_NSO]'
    +' ,[INFANT_PERSONAL_0_LAST NAME] = ClinicSite.Sitecode'
    +' ,[INFANT_BIRTH_0_DOB] = Atbl.[INFANT_BIRTH_0_DOB]'
    +' ,[CLIENT_0_ID_NSO] = cxref1.Client_ID'
    +' ,[CLIENT_0_ID_AGENCY] = Atbl.[CLIENT_0_ID_AGENCY]'
    +' ,[CLIENT_PERSONAL_0_NAME_FIRST] = Clients.First_Name'
    +' ,[CLIENT_PERSONAL_0_NAME_LAST] = Clients.Last_Name'
    +' ,[INFANT_BIRTH_1_MULTIPLE_BIRTHS] = Atbl.[INFANT_BIRTH_1_MULTIPLE_BIRTHS]'
    +' ,[INFANT_PERSONAL_0_ETHNICITY] = Atbl.[INFANT_PERSONAL_0_ETHNICITY]'
    +' ,[INFANT_PERSONAL_0_RACE] = Atbl.[INFANT_PERSONAL_0_RACE]'
    +' ,[INFANT_PERSONAL_0_GENDER] = Atbl.[INFANT_PERSONAL_0_GENDER]'
    +' ,[INFANT_BIRTH_1_WEIGHT_GRAMS] = isnull(Atbl.[INFANT_BIRTH_1_WEIGHT_GRAMS],0)'
    +' ,[INFANT_BIRTH_1_WEIGHT_POUNDS] = isnull(Atbl.[INFANT_BIRTH_1_WEIGHT_POUNDS],0)'
    +' ,[INFANT_BIRTH_1_GEST_AGE] = Atbl.[INFANT_BIRTH_1_GEST_AGE]'
    +' ,[INFANT_BIRTH_1_NICU] = Atbl.[INFANT_BIRTH_1_NICU]'
    +' ,[INFANT_BIRTH_1_NICU_DAYS] = Atbl.[INFANT_BIRTH_1_NICU_DAYS]'
    --+' ,[CLIENT_WEIGHT_0_PREG_GAIN] = Atbl.[CLIENT_WEIGHT_0_PREG_GAIN]'
    --+' ,[INFANT_BREASTMILK_0_EVER_BIRTH] = Atbl.[INFANT_BREASTMILK_0_EVER_BIRTH]'
    --+' ,[INFANT_0_ID_NSO2] = Atbl.[INFANT_0_ID_NSO2]'
    --+' ,[INFANT_PERSONAL_0_FIRST NAME2] = Atbl.[INFANT_PERSONAL_0_FIRST NAME2]'
    --+' ,[INFANT_BIRTH_0_DOB2] = Atbl.[INFANT_BIRTH_0_DOB2]'
    --+' ,[INFANT_PERSONAL_0_ETHNICITY2] = Atbl.[INFANT_PERSONAL_0_ETHNICITY2]'
    --+' ,[INFANT_PERSONAL_0_ETHNICITY3] = Atbl.[INFANT_PERSONAL_0_ETHNICITY3]'
    --+' ,[INFANT_PERSONAL_0_RACE2] = Atbl.[INFANT_PERSONAL_0_RACE2]'
    --+' ,[INFANT_PERSONAL_0_RACE3] = Atbl.[INFANT_PERSONAL_0_RACE3]'
    --+' ,[INFANT_PERSONAL_0_GENDER2] = Atbl.[INFANT_PERSONAL_0_GENDER2]'
    --+' ,[INFANT_BIRTH_1_WEIGHT_GRAMS2] = isnull(Atbl.[INFANT_BIRTH_1_WEIGHT_GRAMS2],0)'
    --+' ,[INFANT_BIRTH_1_GEST_AGE2] = Atbl.[INFANT_BIRTH_1_GEST_AGE2]'
    --+' ,[INFANT_BIRTH_1_NICU2] = Atbl.[INFANT_BIRTH_1_NICU2]'
    --+' ,[INFANT_BIRTH_1_NICU_DAYS2] = Atbl.[INFANT_BIRTH_1_NICU_DAYS2]'
    --+' ,[INFANT_0_ID_NSO3] = Atbl.[INFANT_0_ID_NSO3]'
    --+' ,[INFANT_BIRTH_0_DOB3] = Atbl.[INFANT_BIRTH_0_DOB3]'
    --+' ,[INFANT_PERSONAL_0_GENDER3] = Atbl.[INFANT_PERSONAL_0_GENDER3]'
    --+' ,[INFANT_BIRTH_1_WEIGHT_GRAMS3] = isnull(Atbl.[INFANT_BIRTH_1_WEIGHT_GRAMS3],0)'
    --+' ,[INFANT_BIRTH_1_WEIGHT_POUNDS3] = isnull(Atbl.[INFANT_BIRTH_1_WEIGHT_POUNDS3],0)'
    --+' ,[INFANT_BIRTH_1_GEST_AGE3] = Atbl.[INFANT_BIRTH_1_GEST_AGE3]'
    --+' ,[INFANT_BIRTH_1_NICU3] = Atbl.[INFANT_BIRTH_1_NICU3]'
    --+' ,[INFANT_BIRTH_1_NICU_DAYS3] = Atbl.[INFANT_BIRTH_1_NICU_DAYS3]'
    --+' ,[INFANT_BREASTMILK_0_EVER_BIRTH2] = Atbl.[INFANT_BREASTMILK_0_EVER_BIRTH2]'
    --+' ,[INFANT_BREASTMILK_0_EVER_BIRTH3] = Atbl.[INFANT_BREASTMILK_0_EVER_BIRTH3]'
    --+' ,[INFANT_BIRTH_1_WEIGHT_MEASURE] = Atbl.[INFANT_BIRTH_1_WEIGHT_MEASURE]'
    +' ,[INFANT_BIRTH_1_WEIGHT_OUNCES] = isnull(Atbl.[INFANT_BIRTH_1_WEIGHT_OUNCES],0)'
    +' ,[INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS] = 
case when isnull(Atbl.[INFANT_BIRTH_1_WEIGHT_POUNDS],0) + isnull(Atbl.[INFANT_BIRTH_1_WEIGHT_OUNCES],0) != 0
        then round((((isnull(Atbl.[INFANT_BIRTH_1_WEIGHT_POUNDS],0)*16) + isnull(Atbl.[INFANT_BIRTH_1_WEIGHT_OUNCES],0)) / 0.035274),3) end'
    --+' ,[INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS] = Atbl.[INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS]'
    --+' .[INFANT_BIRTH_1_WEIGHT_MEASURE2] = Atbl.[INFANT_BIRTH_1_WEIGHT_MEASURE2]'
    --+' ,[INFANT_BIRTH_1_WEIGHT_MEASURE3] = Atbl.[INFANT_BIRTH_1_WEIGHT_MEASURE3]'
    --+' ,[INFANT_BIRTH_1_WEIGHT_OUNCES3] = isnull(Atbl.[INFANT_BIRTH_1_WEIGHT_OUNCES3],0)'
    --+' ,[INFANT_BIRTH_1_WEIGHT_POUNDS2] = isnull(Atbl.[INFANT_BIRTH_1_WEIGHT_POUNDS2],0)'
    --+' ,[INFANT_BIRTH_1_WEIGHT_OUNCES2] = isnull(Atbl.[INFANT_BIRTH_1_WEIGHT_OUNCES2],0)'
    --+' ,[INFANT_PERSONAL_0_FIRST NAME3] = Atbl.[INFANT_PERSONAL_0_FIRST NAME3]'
    --+' ,[INFANT_BIRTH_0_CLIENT_ER] = Atbl.[INFANT_BIRTH_0_CLIENT_ER]'
    --+' ,[INFANT_BIRTH_0_CLIENT_URGENT CARE] = Atbl.[INFANT_BIRTH_0_CLIENT_URGENT CARE]'
    --+' ,[INFANT_BIRTH_1_NICU_R2] = Atbl.[INFANT_BIRTH_1_NICU_R2]'
    --+' ,[INFANT_BIRTH_1_NICU_R2_2] = Atbl.[INFANT_BIRTH_1_NICU_R2_2]'
    --+' ,[INFANT_BIRTH_1_NICU_R2_3] = Atbl.[INFANT_BIRTH_1_NICU_R2_3]'
    --+' ,[INFANT_BIRTH_1_NURSERY_R2] = Atbl.[INFANT_BIRTH_1_NURSERY_R2]'
    --+' ,[INFANT_BIRTH_1_NURSERY_R2_2] = Atbl.[INFANT_BIRTH_1_NURSERY_R2_2]'
    --+' ,[INFANT_BIRTH_1_NURSERY_R2_3] = Atbl.[INFANT_BIRTH_1_NURSERY_R2_3]'
    --+' ,[INFANT_BIRTH_0_CLIENT_ER_TIMES] = Atbl.[INFANT_BIRTH_0_CLIENT_ER_TIMES]'
    --+' ,[INFANT_BIRTH_0_CLIENT_URGENT CARE_TIMES] = Atbl.[INFANT_BIRTH_0_CLIENT_URGENT CARE_TIMES]'
    --+' ,[INFANT_BIRTH_1_NICU_DAYS_R2] = Atbl.[INFANT_BIRTH_1_NICU_DAYS_R2]'
    --+' ,[INFANT_BIRTH_1_NICU_DAYS_R2_2] = Atbl.[INFANT_BIRTH_1_NICU_DAYS_R2_2]'
    --+' ,[INFANT_BIRTH_1_NICU_DAYS_R2_3] = Atbl.[INFANT_BIRTH_1_NICU_DAYS_R2_3]'
    --+' ,[INFANT_BIRTH_1_NURSERY_DAYS_R2] = Atbl.[INFANT_BIRTH_1_NURSERY_DAYS_R2]'
    --+' ,Atbl.[INFANT_BIRTH_1_NURSERY_DAYS_R2_2] = Atbl.[INFANT_BIRTH_1_NURSERY_DAYS_R2_2]'
    --+' ,Atbl.[INFANT_BIRTH_1_NURSERY_DAYS_R2_3] = Atbl.[INFANT_BIRTH_1_NURSERY_DAYS_R2_3]'
    +', [DW_AuditDate] = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from dbo.' +@DW_TableName +' dwsurvey'
    +' inner join Non_ETO_SurveyResponse_Xref dwxref on dwxref.source = ''' +@p_datasource +''''
    +'  and dwsurvey.SurveyResponseID = dwxref.SurveyResponseID'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +' Atbl'
    +' on dwxref.Non_ETO_ID = Atbl.AnswerID'
    +' 
     left join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Clinic Clinic'
    +'  on Atbl.SiteCode = Clinic.Clinic_no'
    +' 
     left join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.ClinicSite ClinicSite'
    +'  on Clinic.ClinicID = ClinicSite.ClinicID'
    +' 
     left join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.TeamMappingTbl TeamMappingTbl'
    +'  on ClinicSite.SiteCode = TeamMappingTbl.SiteCode'
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
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) 
    EXEC (@SQL1)



----------------------------------------------------------------------------------------
print '  Cont: SP_OK_INFANT_BIRTH_SURVEY - Delete Contacts that no longer exist in AgencyDB'

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

print 'End of Process: SP_OK_INFANT_BIRTH_SURVEY'
GO
