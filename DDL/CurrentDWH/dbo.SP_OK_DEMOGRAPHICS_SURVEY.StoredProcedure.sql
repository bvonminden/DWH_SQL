USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_OK_DEMOGRAPHICS_SURVEY]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_OK_DEMOGRAPHICS_SURVEY
--
CREATE PROCEDURE [dbo].[SP_OK_DEMOGRAPHICS_SURVEY]
 (@p_AnswerID       int = null)
AS
--
-- This script controls integration of Oklahoma Surveys to the Data Warehouse 
-- DEMOGRAPHICS_SURVEY table.
--
-- ** Defaulting Datasource as 'OKLAHOMA'
--               Audit_StaffID = 4614, EntityID=13048, name=Data Migration2, for site 260
--               SurveyID = 1575 Demographics: Pregnancy Intake MASTER
--                          1702 Demographics Update MASTER
--                          1702 Demographics Update MASTER
--               SiteID = 260
--
-- Table effected - dbo.DEMOGRAPHICS_SURVEY
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
--   20140401 - New Procedure.
--   20140827 - Changed for source datacolumn change: Client_Income_Sources to Client_Income_Source.

DECLARE @p_datasource nvarchar(10)
DECLARE @count        smallint
DECLARE @p_stop_flag  nvarchar(2)
DECLARE @Process      nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)
DECLARE @Source_TableName nvarchar(50)
DECLARE @Source_TableName1 nvarchar(50)
DECLARE @Source_TableName2 nvarchar(50)
DECLARE @Source_TableName3 nvarchar(50)
DECLARE @ETO_SiteID             int
DECLARE @ETO_SurveyID_Intake    int
DECLARE @ETO_SurveyID_update    int
DECLARE @ETO_SurveyID_update24  int
DECLARE @ETO_AuditStaffID       int

set @process = 'SP_OK_DEMOGRAPHICS_SURVEY'
set @DW_Tablename = 'DEMOGRAPHICS_SURVEY'
set @Source_Tablename = 'VIEW_DEMOGRAPHICS_COMBINED'
--set @Source_Tablename1 = 'VIEW_DEMO_INTAKE'
--set @Source_Tablename2 = 'VIEW_DEMO_UPDATE'
--set @Source_Tablename3 = 'VIEW_DEMO_UPDATE24'
Set @p_stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()
set @p_datasource = 'OKLAHOMA'
set @ETO_SiteID = 260
set @ETO_SurveyID_Intake = 1575
set @ETO_SurveyID_Update = 1702
set @ETO_SurveyID_Update24 = 1702
set @ETO_AuditStaffID = 4614

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)
DECLARE @SQL1            varchar(MAX)
DECLARE @SQL2            varchar(MAX)
DECLARE @SQL3            varchar(MAX)

print 'Processing SP_OK_DEMOGRAPHICS_SURVEY: Datasource = ' +isnull(@p_datasource,'NULL')
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
print 'Processing SP_OK_DEMOGRAPHICS_SURVEY - retrieving datasource DB Srvr from LOV tables'

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
set @SQL = 'update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.DEMOGRAPHICS_SURVEY'
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
    +' ,[CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED]'
    +' ,[CLIENT_MARITAL_0_STATUS]'
    +' ,[CLIENT_BIO_DAD_0_CONTACT_WITH]'
    +' ,[CLIENT_LIVING_0_WITH]'
    +' ,[CLIENT_LIVING_1_WITH_OTHERS]'
    +' ,[CLIENT_EDUCATION_0_HS_GED]'
    +' ,[CLIENT_EDUCATION_1_HS_GED_LAST_GRADE]'
    +' ,[CLIENT_EDUCATION_1_HIGHER_EDUC_COMP]'
    +' ,[CLIENT_EDUCATION_1_ENROLLED_CURRENT]'
    +' ,[CLIENT_EDUCATION_1_ENROLLED_TYPE]'
    +' ,[CLIENT_EDUCATION_1_ENROLLED_PLAN]'
    +' ,[CLIENT_WORKING_0_CURRENTLY_WORKING]'
    +' ,[CLIENT_INCOME_0_HH_INCOME]'
    +' ,[CLIENT_INCOME_1_LOW_INCOME_QUALIFY]'
    +' ,[CLIENT_0_ID_NSO]'
    +' ,[CLIENT_PERSONAL_0_NAME_FIRST]'
    +' ,[CLIENT_PERSONAL_0_NAME_LAST]'
    +' ,[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +' ,[CLIENT_PERSONAL_0_ETHNICITY_INTAKE]'
    +' ,[CLIENT_PERSONAL_0_RACE]'
    +' ,[CLIENT_PERSONAL_LANGUAGE_0_INTAKE]'
    +' ,[CLIENT_0_ID_AGENCY]'
    +' ,[CLIENT_WORKING_1_WORKED_SINCE_BIRTH]'
    +' ,[CLIENT_WORKING_1_WORKED_SINCE_BIRTH_MONTHS]'
    +' ,[CLIENT_BC_0_USED_6MONTHS]'
    +' ,[CLIENT_BC_1_NOT_USED_REASON]'
    +' ,[CLIENT_BC_1_FREQUENCY]'
    +' ,[CLIENT_BC_1_TYPES]'
    +' ,[CLIENT_SUBPREG_0_BEEN_PREGNANT]'
    +' ,[CLIENT_SUBPREG_1_BEGIN_MONTH]'
    +' ,[CLIENT_SUBPREG_1_BEGIN_YEAR]'
    +' ,[CLIENT_SUBPREG_1_PLANNED]'
    +' ,[CLIENT_SUBPREG_1_OUTCOME]'
    +' ,[CLIENT_SECOND_0_CHILD_DOB]'
    +' ,[CLIENT_SECOND_1_CHILD_GENDER]'
    +' ,[CLIENT_SECOND_1_CHILD_BW_POUNDS]'
    +' ,[CLIENT_SECOND_1_CHILD_BW_OZ]'
    +' ,[CLIENT_SECOND_1_CHILD_NICU]'
    +' ,[CLIENT_SECOND_1_CHILD_NICU_DAYS]'
    +' ,[CLIENT_BIO_DAD_1_TIME_WITH]'
/*    ,[ADULTS_1_ENROLL_NO]'
    +' ,[ADULTS_1_ENROLL_PT]'
    +' ,[ADULTS_1_CARE_10]'
    +' ,[ADULTS_1_CARE_20]'
    +' ,[ADULTS_1_CARE_30]'
    +' ,[ADULTS_1_CARE_40]'
    +' ,[ADULTS_1_CARE_LESS10]'
    +' ,[ADULTS_1_COMPLETE_GED]'
    +' ,[ADULTS_1_COMPLETE_HS]'
    +' ,[ADULTS_1_COMPLETE_HS_NO]'
    +' ,[ADULTS_1_ED_TECH]'
    +' ,[ADULTS_1_ED_ASSOCIATE]'
    +' ,[ADULTS_1_ED_BACHELOR]'
    +' ,[ADULTS_1_ED_MASTER]'
    +' ,[ADULTS_1_ED_NONE]'
    +' ,[ADULTS_1_ED_POSTGRAD]'
    +' ,[ADULTS_1_ED_SOME_COLLEGE]'
    +' ,[ADULTS_1_ED_UNKNOWN]'
    +' ,[ADULTS_1_ENROLL_FT]'
    +' ,[ADULTS_1_INS_NO]'
    +' ,[ADULTS_1_INS_PRIVATE]'
    +' ,[ADULTS_1_INS_PUBLIC]'
    +' ,[ADULTS_1_WORK_10]'
    +' ,[ADULTS_1_WORK_20]'
    +' ,[ADULTS_1_WORK_37]'
    +' ,[ADULTS_1_WORK_LESS10]'
    +' ,[ADULTS_1_WORK_UNEMPLOY]'
*/
    +' ,[CLIENT_CARE_0_ER_HOSP]'
    +' ,[CLIENT_EDUCATION_1_ENROLLED_FTPT]'
    +' ,[CLIENT_INCOME_1_HH_SOURCES]'
    +' ,[CLIENT_WORKING_1_CURRENTLY_WORKING_HRS]'
    +' ,[CLIENT_EDUCATION_1_ENROLLED_PT_HRS]'
    +' ,[CLIENT_SCHOOL_MIDDLE_HS]'
    +' ,[CLIENT_ED_PROG_TYPE]'
    +' ,[CLIENT_PROVIDE_CHILDCARE]'
    +' ,[CLIENT_WORKING_2_CURRENTLY_WORKING_NO]'
    +' ,[CLIENT_CARE_0_ER]'
    +' ,[CLIENT_CARE_0_URGENT]'
    +' ,[CLIENT_CARE_0_ER_TIMES]'
    +' ,[CLIENT_CARE_0_URGENT_TIMES]'
    +' ,[CLIENT_INCOME_IN_KIND]'
    +' ,[CLIENT_INCOME_SOURCES]'
    +' ,[CLIENT_MILITARY]'
    +' ,[CLIENT_INCOME_AMOUNT]'
    +' ,[CLIENT_WORKING_1_CURRENTLY_WORKING_NO]'
    +' ,[CLIENT_INCOME_INKIND_OTHER]'
    +' ,[CLIENT_INCOME_OTHER_SOURCES]'
    +' ,[DW_AuditDate])'

set @SQL2 = '
     SELECT  dwxref.SurveyResponseID as SurveyResponseID, ''' +@p_datasource +''''
    +' ,1'
    +' ,case when Atbl.Source_TableNbr = 1 then ' +convert(varchar,@ETO_SurveyID_Intake )
          +' when Atbl.Source_TableNbr = 2 then ' +convert(varchar,@ETO_SurveyID_update )
          +' when Atbl.Source_TableNbr = 3 then ' +convert(varchar,@ETO_SurveyID_update24 ) +' END as SurveyID'
    +' ,Atbl.[SurveyDate]'
    +' ,Atbl.[ChgDateTime] as AuditDate'
    +' ,cxref1.Client_ID as CL_EN_GEN_ID'
    +' , '+convert(varchar,@ETO_SiteID) +' as SiteID'
    +' ,Atbl.ProgramID as [ProgramID]'
    +' ,cxref1.Client_ID as [ClientID]'
    +' ,exref1.Entity_ID as [NURSE_PERSONAL_0_NAME]'
    +' ,Atbl.[CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED]'
    +' ,Atbl.[CLIENT_MARITAL_0_STATUS]'
    +' ,Atbl.[CLIENT_BIO_DAD_0_CONTACT_WITH]'
    +' ,Atbl.[CLIENT_LIVING_0_WITH]'
    +' ,Atbl.[CLIENT_LIVING_1_WITH_OTHERS]'
    +' ,Atbl.[CLIENT_EDUCATION_0_HS_GED]'
    +' ,Atbl.[CLIENT_EDUCATION_1_HS_GED_LAST_GRADE]'
    +' ,Atbl.[CLIENT_EDUCATION_1_HIGHER_EDUC_COMP]'
    +' ,Atbl.[CLIENT_EDUCATION_1_ENROLLED_CURRENT]'
    +' ,Atbl.[CLIENT_EDUCATION_1_ENROLLED_TYPE]'
    +' ,Atbl.[CLIENT_EDUCATION_1_ENROLLED_PLAN]'
    +' ,Atbl.[CLIENT_WORKING_0_CURRENTLY_WORKING]'
    +' ,Atbl.[CLIENT_INCOME_0_HH_INCOME]'
    +' ,Atbl.[CLIENT_INCOME_1_LOW_INCOME_QUALIFY]'
    +' ,Atbl.[CLIENT_0_ID_NSO]'
    +' ,Atbl.[First_Name_Created] as [CLIENT_PERSONAL_0_NAME_FIRST]'
    +' ,Atbl.[Last_Name_Created] as [CLIENT_PERSONAL_0_NAME_LAST]'
    +' ,Atbl.[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +' ,Atbl.[CLIENT_PERSONAL_0_ETHNICITY_INTAKE]'
    +' ,Atbl.[CLIENT_PERSONAL_0_RACE]'
    +' ,Atbl.[CLIENT_PERSONAL_LANGUAGE_0_INTAKE]'
    +' ,Atbl.[CLIENT_0_ID_AGENCY]'
    +' ,Atbl.[CLIENT_WORKING_1_WORKED_SINCE_BIRTH]'
    +' ,Atbl.[CLIENT_WORKING_1_WORKED_SINCE_BIRTH_MONTHS]'
    +' ,Atbl.[CLIENT_BC_0_USED_6MONTHS]'
    +' ,Atbl.[CLIENT_BC_1_NOT_USED_REASON]'
    +' ,Atbl.[CLIENT_BC_1_FREQUENCY]'
    +' ,Atbl.[CLIENT_BC_1_TYPES]'
    +' ,Atbl.[CLIENT_SUBPREG_0_BEEN_PREGNANT]'
    +' ,Atbl.[CLIENT_SUBPREG_1_BEGIN_MONTH]'
    +' ,Atbl.[CLIENT_SUBPREG_1_BEGIN_YEAR]'
    +' ,Atbl.[CLIENT_SUBPREG_1_PLANNED]'
    +' ,Atbl.[CLIENT_SUBPREG_1_OUTCOME]'
    +' ,Atbl.[CLIENT_SECOND_0_CHILD_DOB]'
    +' ,Atbl.[CLIENT_SECOND_1_CHILD_GENDER]'
    +' ,Atbl.[CLIENT_SECOND_1_CHILD_BW_POUNDS]'
    +' ,Atbl.[CLIENT_SECOND_1_CHILD_BW_OZ]'
    +' ,Atbl.[CLIENT_SECOND_1_CHILD_NICU]'
    +' ,Atbl.[CLIENT_SECOND_1_CHILD_NICU_DAYS]'
    +' ,Atbl.[CLIENT_BIO_DAD_1_TIME_WITH]'
/*    ,Atbl.[ADULTS_1_ENROLL_NO]'
    +' ,Atbl.[ADULTS_1_ENROLL_PT]'
    +' ,Atbl.[ADULTS_1_CARE_10]'
    +' ,Atbl.[ADULTS_1_CARE_20]'
    +' ,Atbl.[ADULTS_1_CARE_30]'
    +' ,Atbl.[ADULTS_1_CARE_40]'
    +' ,Atbl.[ADULTS_1_CARE_LESS10]'
    +' ,Atbl.[ADULTS_1_COMPLETE_GED]'
    +' ,Atbl.[ADULTS_1_COMPLETE_HS]'
    +' ,Atbl.[ADULTS_1_COMPLETE_HS_NO]'
    +' ,Atbl.[ADULTS_1_ED_TECH]'
    +' ,Atbl.[ADULTS_1_ED_ASSOCIATE]'
    +' ,Atbl.[ADULTS_1_ED_BACHELOR]'
    +' ,Atbl.[ADULTS_1_ED_MASTER]'
    +' ,Atbl.[ADULTS_1_ED_NONE]'
    +' ,Atbl.[ADULTS_1_ED_POSTGRAD]'
    +' ,Atbl.[ADULTS_1_ED_SOME_COLLEGE]'
    +' ,Atbl.[ADULTS_1_ED_UNKNOWN]'
    +' ,Atbl.[ADULTS_1_ENROLL_FT]'
    +' ,Atbl.[ADULTS_1_INS_NO]'
    +' ,Atbl.[ADULTS_1_INS_PRIVATE]'
    +' ,Atbl.[ADULTS_1_INS_PUBLIC]'
    +' ,Atbl.[ADULTS_1_WORK_10]'
    +' ,Atbl.[ADULTS_1_WORK_20]'
    +' ,Atbl.[ADULTS_1_WORK_37]'
    +' ,Atbl.[ADULTS_1_WORK_LESS10]'
    +' ,Atbl.[ADULTS_1_WORK_UNEMPLOY]'
*/
    +' ,Atbl.[CLIENT_CARE_0_ER_HOSP]'
    +' ,Atbl.[CLIENT_EDUCATION_1_ENROLLED_FTPT]'
    +' ,Atbl.[CLIENT_INCOME_1_HH_SOURCES]'
    +' ,Atbl.[CLIENT_WORKING_1_CURRENTLY_WORKING_HRS]'
    +' ,Atbl.[CLIENT_EDUCATION_1_ENROLLED_PT_HRS]'
    +' ,Atbl.[CLIENT_SCHOOL_MIDDLE_HS]'
    +' ,Atbl.[CLIENT_ED_PROG_TYPE]'
    +' ,Atbl.[CLIENT_PROVIDE_CHILDCARE]'
    +' ,Atbl.[CLIENT_WORKING_2_CURRENTLY_WORKING_NO]'
    +' ,Atbl.[CLIENT_CARE_0_ER]'
    +' ,Atbl.[CLIENT_CARE_0_URGENT]'
    +' ,Atbl.[CLIENT_CARE_0_ER_TIMES]'
    +' ,Atbl.[CLIENT_CARE_0_URGENT_TIMES]'
    +' ,Atbl.[CLIENT_INCOME_IN_KIND]'
    +' ,Atbl.[CLIENT_INCOME_SOURCE]'
    +' ,Atbl.[CLIENT_MILITARY]'
    +' ,Atbl.[CLIENT_INCOME_AMOUNT]'
    +' ,Atbl.[CLIENT_WORKING_1_CURRENTLY_WORKING_NO]'
    +' ,Atbl.[CLIENT_INCOME_INKIND_OTHER]'
    +' ,Atbl.[CLIENT_INCOME_OTHER_SOURCES]'
    +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +' Atbl'
    +' inner join Non_ETO_SurveyResponse_Xref dwxref on dwxref.source = ''' +@p_datasource +''''
    +'  and atbl.AnswerID = dwxref.non_ETO_ID'
    +' 
     left join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source =  ''' +@p_datasource +''''
    +'   and cxref1.Non_ETO_ID = Atbl.Client_0_ID_Agency' 
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
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) 
         +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
    EXEC (@SQL1+@SQL2)



----------------------------------------------------------------------------------------
print '  Cont: SP_OK_DEMOGRAPHICS_SURVEY - Update changes'

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
    --+', [ProgramID] = Atbl.[ProgramID]'
    --+', [IA_StaffID] = Atbl.[IA_StaffID]'
    +', [ClientID] = cxref1.Client_ID'
    --+', [RespondentID] = Atbl.[RespondentID]''
    +' ,[NURSE_PERSONAL_0_NAME] = exref1.Entity_ID'
    +' ,[CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED] = Atbl.[CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED]'
    +' ,[CLIENT_MARITAL_0_STATUS] = Atbl.[CLIENT_MARITAL_0_STATUS]'
    +' ,[CLIENT_BIO_DAD_0_CONTACT_WITH] = Atbl.[CLIENT_BIO_DAD_0_CONTACT_WITH]'
    +' ,[CLIENT_LIVING_0_WITH] = Atbl.[CLIENT_LIVING_0_WITH]'
    +' ,[CLIENT_LIVING_1_WITH_OTHERS] = Atbl.[CLIENT_LIVING_1_WITH_OTHERS]'
    +' ,[CLIENT_EDUCATION_0_HS_GED] = Atbl.[CLIENT_EDUCATION_0_HS_GED]'
    +' ,[CLIENT_EDUCATION_1_HS_GED_LAST_GRADE] = Atbl.[CLIENT_EDUCATION_1_HS_GED_LAST_GRADE]'
    +' ,[CLIENT_EDUCATION_1_HIGHER_EDUC_COMP] = Atbl.[CLIENT_EDUCATION_1_HIGHER_EDUC_COMP]'
    +' ,[CLIENT_EDUCATION_1_ENROLLED_CURRENT] = Atbl.[CLIENT_EDUCATION_1_ENROLLED_CURRENT]'
    +' ,[CLIENT_EDUCATION_1_ENROLLED_TYPE] = Atbl.[CLIENT_EDUCATION_1_ENROLLED_TYPE]'
    +' ,[CLIENT_EDUCATION_1_ENROLLED_PLAN] = Atbl.[CLIENT_EDUCATION_1_ENROLLED_PLAN]'
    +' ,[CLIENT_WORKING_0_CURRENTLY_WORKING] = Atbl.[CLIENT_WORKING_0_CURRENTLY_WORKING]'
    +' ,[CLIENT_INCOME_0_HH_INCOME] = Atbl.[CLIENT_INCOME_0_HH_INCOME]'
    +' ,[CLIENT_INCOME_1_LOW_INCOME_QUALIFY] = Atbl.[CLIENT_INCOME_1_LOW_INCOME_QUALIFY]'
    +' ,[CLIENT_0_ID_NSO] = Atbl.[CLIENT_0_ID_NSO]'
    +' ,[CLIENT_PERSONAL_0_NAME_FIRST] = Atbl.[First_Name_created]'
    +' ,[CLIENT_PERSONAL_0_NAME_LAST] = Atbl.[Last_Name_created]'
    +' ,[CLIENT_PERSONAL_0_DOB_INTAKE] = Atbl.[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +' ,[CLIENT_PERSONAL_0_ETHNICITY_INTAKE] = Atbl.[CLIENT_PERSONAL_0_ETHNICITY_INTAKE]'
    +' ,[CLIENT_PERSONAL_0_RACE] = Atbl.[CLIENT_PERSONAL_0_RACE]'
    +' ,[CLIENT_PERSONAL_LANGUAGE_0_INTAKE] = Atbl.[CLIENT_PERSONAL_LANGUAGE_0_INTAKE]'
    +' ,[CLIENT_0_ID_AGENCY] = Atbl.[CLIENT_0_ID_AGENCY]'
    +' ,[CLIENT_WORKING_1_WORKED_SINCE_BIRTH] = Atbl.[CLIENT_WORKING_1_WORKED_SINCE_BIRTH]'
    +' ,[CLIENT_WORKING_1_WORKED_SINCE_BIRTH_MONTHS] = Atbl.[CLIENT_WORKING_1_WORKED_SINCE_BIRTH_MONTHS]'
    +' ,[CLIENT_BC_0_USED_6MONTHS] = Atbl.[CLIENT_BC_0_USED_6MONTHS]'
    +' ,[CLIENT_BC_1_NOT_USED_REASON] = Atbl.[CLIENT_BC_1_NOT_USED_REASON]'
    +' ,[CLIENT_BC_1_FREQUENCY] = Atbl.[CLIENT_BC_1_FREQUENCY]'
    +' ,[CLIENT_BC_1_TYPES] = Atbl.[CLIENT_BC_1_TYPES]'
    +' ,[CLIENT_SUBPREG_0_BEEN_PREGNANT] = Atbl.[CLIENT_SUBPREG_0_BEEN_PREGNANT]'
    +' ,[CLIENT_SUBPREG_1_BEGIN_MONTH] = Atbl.[CLIENT_SUBPREG_1_BEGIN_MONTH]'
    +' ,[CLIENT_SUBPREG_1_BEGIN_YEAR] = Atbl.[CLIENT_SUBPREG_1_BEGIN_YEAR]'
    +' ,[CLIENT_SUBPREG_1_PLANNED] = Atbl.[CLIENT_SUBPREG_1_PLANNED]'
    +' ,[CLIENT_SUBPREG_1_OUTCOME] = Atbl.[CLIENT_SUBPREG_1_OUTCOME]'
    +' ,[CLIENT_SECOND_0_CHILD_DOB] = Atbl.[CLIENT_SECOND_0_CHILD_DOB]'
    +' ,[CLIENT_SECOND_1_CHILD_GENDER] = Atbl.[CLIENT_SECOND_1_CHILD_GENDER]'
    +' ,[CLIENT_SECOND_1_CHILD_BW_POUNDS] = Atbl.[CLIENT_SECOND_1_CHILD_BW_POUNDS]'
    +' ,[CLIENT_SECOND_1_CHILD_BW_OZ] = Atbl.[CLIENT_SECOND_1_CHILD_BW_OZ]'
    +' ,[CLIENT_SECOND_1_CHILD_NICU] = Atbl.[CLIENT_SECOND_1_CHILD_NICU]'
    +' ,[CLIENT_SECOND_1_CHILD_NICU_DAYS] = Atbl.[CLIENT_SECOND_1_CHILD_NICU_DAYS]'
    +' ,[CLIENT_BIO_DAD_1_TIME_WITH] = Atbl.[CLIENT_BIO_DAD_1_TIME_WITH]'
    +' ,[CLIENT_CARE_0_ER_HOSP] = Atbl.[CLIENT_CARE_0_ER_HOSP]'

    set @SQL2 =  '
       ,[CLIENT_EDUCATION_1_ENROLLED_FTPT] = Atbl.[CLIENT_EDUCATION_1_ENROLLED_FTPT]'
    +' ,[CLIENT_INCOME_1_HH_SOURCES] = Atbl.[CLIENT_INCOME_1_HH_SOURCES]'
    +' ,[CLIENT_WORKING_1_CURRENTLY_WORKING_HRS] = Atbl.[CLIENT_WORKING_1_CURRENTLY_WORKING_HRS]'
    +' ,[CLIENT_EDUCATION_1_ENROLLED_PT_HRS] = Atbl.[CLIENT_EDUCATION_1_ENROLLED_PT_HRS]'
    +' ,[CLIENT_SCHOOL_MIDDLE_HS] = Atbl.[CLIENT_SCHOOL_MIDDLE_HS]'
    +' ,[CLIENT_ED_PROG_TYPE] = Atbl.[CLIENT_ED_PROG_TYPE]'
    +' ,[CLIENT_PROVIDE_CHILDCARE] = Atbl.[CLIENT_PROVIDE_CHILDCARE]'
    +' ,[CLIENT_WORKING_2_CURRENTLY_WORKING_NO] = Atbl.[CLIENT_WORKING_2_CURRENTLY_WORKING_NO]'
    +' ,[CLIENT_CARE_0_ER] = Atbl.[CLIENT_CARE_0_ER]'
    +' ,[CLIENT_CARE_0_URGENT] = Atbl.[CLIENT_CARE_0_URGENT]'
    +' ,[CLIENT_CARE_0_ER_TIMES] = Atbl.[CLIENT_CARE_0_ER_TIMES]'
    +' ,[CLIENT_CARE_0_URGENT_TIMES] = Atbl.[CLIENT_CARE_0_URGENT_TIMES]'
    +' ,[CLIENT_INCOME_IN_KIND] = Atbl.[CLIENT_INCOME_IN_KIND]'
    +' ,[CLIENT_INCOME_SOURCES] = Atbl.[CLIENT_INCOME_SOURCE]'
    +' ,[CLIENT_MILITARY] = Atbl.[CLIENT_MILITARY]'
    +' ,[CLIENT_INCOME_AMOUNT] = Atbl.[CLIENT_INCOME_AMOUNT]'
    +' ,[CLIENT_WORKING_1_CURRENTLY_WORKING_NO] = Atbl.[CLIENT_WORKING_1_CURRENTLY_WORKING_NO]'
    +' ,[CLIENT_INCOME_INKIND_OTHER] = Atbl.[CLIENT_INCOME_INKIND_OTHER]'
    +' ,[CLIENT_INCOME_OTHER_SOURCES] = Atbl.[CLIENT_INCOME_OTHER_SOURCES]'
    +', [DW_AuditDate] = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from dbo.' +@DW_TableName +' dwsurvey'
    +' inner join Non_ETO_SurveyResponse_Xref dwxref on dwxref.source = ''' +@p_datasource +''''
    +'  and dwsurvey.SurveyResponseID = dwxref.SurveyResponseID'
    +' 
inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +' Atbl'
    +' on dwxref.Non_ETO_ID = Atbl.AnswerID'
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
print '  Cont: SP_OK_DEMOGRAPHICS_SURVEY - Delete Contacts that no longer exist in AgencyDB'

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

print 'End of Process: SP_OK_DEMOGRAPHICS_SURVEY'
GO
