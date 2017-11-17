USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_OK_EDINBURGH_SURVEY]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_OK_EDINBURGH_SURVEY
--
CREATE PROCEDURE [dbo].[SP_OK_EDINBURGH_SURVEY]
 (@p_AnswerID       int = null)
AS
--
-- This script controls integration of Oklahoma Surveys to the Data Warehouse 
-- EDINBURGH_Survey table.
--
-- ** Defaulting Datasource as 'OKLAHOMA'
--               Audit_StaffID = 4614, EntityID=13048, name=Data Migration2, for site 260
--               SurveyID = 1580 All Edinburgh Postnatal Depression forms
--
-- Table effected - dbo.EDINBURGH_Survey
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
--   20140320 - Force SiteID = 260

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

set @process = 'SP_OK_EDINBURGH_SURVEY'
set @DW_Tablename = 'EDINBURGH_SURVEY'
set @Source_Tablename = 'VIEW_EDINBURGH'
Set @p_stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()
set @p_datasource = 'OKLAHOMA'
set @ETO_SurveyID = 1580
set @ETO_AuditStaffID = 4614

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)

print 'Processing SP_OK_EDINBURGH_SURVEY: Datasource = ' +isnull(@p_datasource,'NULL')
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
print 'Processing SP_OK_EDINBURGH_SURVEY - retrieving datasource DB Srvr from LOV tables'

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
set @SQL = 'update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.EDINBURGH_Survey'
    +' Set [DW_SurveyResponseID] = dwxref.[SurveyResponseID]'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +' Atbl'
    +' inner join dbo.Non_ETO_SurveyResponse_Xref dwxref'
    +' on dwxref.Non_ETO_ID = Atbl.AnswerID and dwxref.source = ''' +@p_datasource +''''
    +' and dwxref.DW_tableName = ''' +@DW_TableName +''''

    print @SQL
    --EXEC (@SQL)
*/


set @SQL = 'set nocount off'
    +' insert into dbo.EDINBURGH_Survey'
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
    +' ,[CLIENT_EPDS_1_ABLE_TO_LAUGH]'
    +' ,[CLIENT_EPDS_1_ENJOY_THINGS]'
    +' ,[CLIENT_EPDS_1_BLAME_SELF]'
    +' ,[CLIENT_EPDS_1_ANXIOUS_WORRIED]'
    +' ,[CLIENT_EPDS_1_SCARED_PANICKY]'
    +' ,[CLIENT_EPDS_1_THINGS_GETTING_ON_TOP]'
    +' ,[CLIENT_EPDS_1_DIFFICULTY_SLEEPING]'
    +' ,[CLIENT_EPDS_1_SAD_MISERABLE]'
    +' ,[CLIENT_EPDS_1_BEEN_CRYING]'
    --+' ,[CLIENT_EPDS_1_HARMING_SELF]'
    +' ,[CLIENT_0_ID_NSO]'
    +' ,[NURSE_PERSONAL_0_NAME]'
    +' ,[CLIENT_0_ID_AGENCY]'
   -- +' ,[LA_CTY_OQ10_EDPS]'
    --+' ,[LA_CTY_PHQ9_SCORE_EDPS]'
    --+' ,[LA_CTY_STRESS_INDEX_EDPS]'
    --+' ,[CLIENT_EPS_TOTAL_SCORE]'
    +' ,[DW_AuditDate])'
    +'
     SELECT  dwxref.SurveyResponseID as SurveyResponseID, ''' +@p_datasource +''''
    +' ,1'
    +' ,'+convert(varchar,@ETO_SurveyID) 
    +' ,Atbl.[Date]'
    +' ,Atbl.[ChgDateTime]'
    +' ,cxref1.Client_ID'
    +' ,260'
    +' ,Atbl.[ProgramID]'
    --+' ,Atbl.[IA_StaffID]'
    +' ,cxref1.Client_ID'
    --+' ,Atbl.[RespondentID]'
    +' ,Atbl.[FIRST Name]'
    +' ,Atbl.[Last Name]'
    --+' ,Atbl.[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +' ,Atbl.[CLIENT_EPDS_1_ABLE_TO_LAUGH]'
    +' ,Atbl.[CLIENT_EPDS_1_ENJOY_THINGS]'
    +' ,Atbl.[CLIENT_EPDS_1_BLAME_SELF]'
    +' ,Atbl.[CLIENT_EPDS_1_ANXIOUS_WORRIED]'
    +' ,Atbl.[CLIENT_EPDS_1_SCARED_PANICKY]'
    +' ,Atbl.[CLIENT_EPDS_1_THINGS_GETTING_ON_TOP]'
    +' ,Atbl.[CLIENT_EPDS_1_DIFFICULTY_SLEEPING]'
    +' ,Atbl.[CLIENT_EPDS_1_SAD_MISERABLE]'
    +' ,Atbl.[CLIENT_EPDS_1_BEEN_CRYING]'
    --+' ,Atbl.[CLIENT_EPDS_1_HARMING_SELF]'
    +' ,cxref1.Client_ID'
    +' ,exref1.Entity_ID'
    +' ,Atbl.[CLIENT_0_ID_AGENCY]'
    --+' ,Atbl.[LA_CTY_OQ10_EDPS]'
    --+' ,Atbl.[LA_CTY_PHQ9_SCORE_EDPS]'
    --+' ,Atbl.[LA_CTY_STRESS_INDEX_EDPS]'
    --+' ,Atbl.[CLIENT_EPS_TOTAL_SCORE]'
    +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +' Atbl'
    +' inner join Non_ETO_SurveyResponse_Xref dwxref on dwxref.source = ''' +@p_datasource +''''
    +'  and atbl.AnswerID = dwxref.non_ETO_ID'
    +' left join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source =  ''' +@p_datasource +''''
    +'   and cxref1.Non_ETO_ID = Atbl.Client_0_ID_Agency' 
    +' left join dbo.Non_ETO_Entity_Xref exref1 on exref1.Source =  ''' +@p_datasource +''''
    +'   and exref1.Non_ETO_ID = Atbl.NURSEID' 
    +' where not exists (select dwsurvey.SurveyResponseID'
    +' from dbo.EDINBURGH_Survey dwsurvey'
    +' where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and dwsurvey.SurveyResponseID = dwxref.SurveyResponseID)'
     

    print @SQL
    print 'Length = ' +CAST(LEN(@SQL) as varchar)
    EXEC (@SQL)

--   and exists (select nfpagencies.Site_ID
--                     from dbo.Agencies nfpagencies
--                    where nfpagencies.Site_Id = Sites.SiteId);

----------------------------------------------------------------------------------------
print '  Cont: SP_OK_EDINBURGH_SURVEY - Update changes'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL = 'set nocount off'
    +' update dbo.EDINBURGH_Survey'
    +' Set [SurveyID] = ' +convert(varchar,@ETO_SurveyID) 
    +', [SurveyDate] = Atbl.[Date]'
    +', [AuditDate] = Atbl.[ChgDateTime]'
    +', [CL_EN_GEN_ID] = cxref1.Client_ID'
    --+', [SiteID] = Atbl.[SiteCode]'
    +', [ProgramID] = Atbl.[ProgramID]'
    --+', [IA_StaffID] = Atbl.[IA_StaffID]'
    +', [ClientID] = cxref1.Client_ID'
    --+', [RespondentID] = Atbl.[RespondentID]'
    --+', [CLIENT_PERSONAL_0_NAME_FIRST] = Atbl.[First Name]'
    +', [CLIENT_PERSONAL_0_NAME_LAST] = Atbl.[Last Name]'
    --+', [CLIENT_PERSONAL_0_DOB_INTAKE] = Atbl.[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +', [CLIENT_EPDS_1_ABLE_TO_LAUGH] = Atbl.[CLIENT_EPDS_1_ABLE_TO_LAUGH]'
    +', [CLIENT_EPDS_1_ENJOY_THINGS] = Atbl.[CLIENT_EPDS_1_ENJOY_THINGS]'
    +', [CLIENT_EPDS_1_BLAME_SELF] = Atbl.[CLIENT_EPDS_1_BLAME_SELF]'
    +', [CLIENT_EPDS_1_ANXIOUS_WORRIED] = Atbl.[CLIENT_EPDS_1_ANXIOUS_WORRIED]'
    +', [CLIENT_EPDS_1_SCARED_PANICKY] = Atbl.[CLIENT_EPDS_1_SCARED_PANICKY]'
    +', [CLIENT_EPDS_1_THINGS_GETTING_ON_TOP] = Atbl.[CLIENT_EPDS_1_THINGS_GETTING_ON_TOP]'
    +', [CLIENT_EPDS_1_DIFFICULTY_SLEEPING] = Atbl.[CLIENT_EPDS_1_DIFFICULTY_SLEEPING]'
    +', [CLIENT_EPDS_1_SAD_MISERABLE] = Atbl.[CLIENT_EPDS_1_SAD_MISERABLE]'
    +', [CLIENT_EPDS_1_BEEN_CRYING] = Atbl.[CLIENT_EPDS_1_BEEN_CRYING]'
    --+', [CLIENT_EPDS_1_HARMING_SELF] = Atbl.[CLIENT_EPDS_1_HARMING_SELF]'
    +', [CLIENT_0_ID_NSO] = cxref1.Client_ID'
    +', [NURSE_PERSONAL_0_NAME]= exref1.Entity_ID'
    +', [CLIENT_0_ID_AGENCY] = Atbl.[CLIENT_0_ID_AGENCY]'
    --+', [LA_CTY_OQ10_EDPS] = Atbl.[LA_CTY_OQ10_EDPS]'
    --+', [LA_CTY_PHQ9_SCORE_EDPS] = Atbl.[LA_CTY_PHQ9_SCORE_EDPS]'
   -- +', [LA_CTY_STRESS_INDEX_EDPS] = Atbl.[LA_CTY_STRESS_INDEX_EDPS]'
    --+', [CLIENT_EPS_TOTAL_SCORE] = Atbl.[CLIENT_EPS_TOTAL_SCORE]'
    +', [DW_AuditDate] = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from dbo.EDINBURGH_Survey dwsurvey'
    +' inner join Non_ETO_SurveyResponse_Xref dwxref on dwxref.source = ''' +@p_datasource +''''
    +'  and dwsurvey.SurveyResponseID = dwxref.SurveyResponseID'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +' Atbl'
    +' on dwxref.Non_ETO_ID = Atbl.AnswerID'
    +' left join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source =  ''' +@p_datasource +''''
    +'   and cxref1.Non_ETO_ID = Atbl.Client_0_ID_Agency' 
    +' left join dbo.Non_ETO_Entity_Xref exref1 on exref1.Source =  ''' +@p_datasource +''''
    +'   and exref1.Non_ETO_ID = Atbl.NURSEID' 
    +'
     where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and isnull(dwsurvey.AuditDate,convert(datetime,''19700101'',112)) <'
    +' isnull(Atbl.ChgDateTime,convert(datetime,''19700101'',112))'

    print @SQL
    EXEC (@SQL)



----------------------------------------------------------------------------------------
print '  Cont: SP_OK_EDINBURGH_SURVEY - Delete Contacts that no longer exist in AgencyDB'

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
    +' inner join Non_ETO_SurveyResponse_Xref dwxref on dwxref.datasource = ''' +@p_datasource +''''
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

print 'End of Process: SP_OK_EDINBURGH_SURVEY'
GO
