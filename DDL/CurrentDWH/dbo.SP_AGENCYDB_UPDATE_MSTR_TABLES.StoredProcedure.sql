USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_UPDATE_MSTR_TABLES]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_UPDATE_MSTR_TABLES
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_UPDATE_MSTR_TABLES]
 (@p_AgencyDB      nvarchar(30) = null)
AS
--
-- This script controls the update of AgencyDB Mstr tables from the Data Warehouse 
--   Create a cursor of AgencyDBs, then process each database accordingly.
--   ** Can override cursor selection by running with a AgencyDB parameter for only one AgencyDB.
--
--
-- Table effected - dbo.Mstr_Entity_Attributes
--                  dbo.Mstr_Entity_Attribute_Choices
--                  dbo.Mstr_SurveyElements
--                  dbo.Mstr_SurveyElementChoices
--                  dbo.Mstr_Classes
--
-- Insert: select and insert when record is found to be missing in the DW.
-- Update: select and update when record exists in DW and has been changed but has been changed flagged by Audit_Date.
--
-- History:
--   20140806 - New Procedure.
--   20141103 - Amended to remove SurveyElements which have a Stimulus starting with 'XXX'.  
--              These are old elements which have been made obsolete within ETO.
--   20151111 - Added the copy of the dbo.Mstr_Surveys table, for only surveys having 'MASTER' in the name.
--              Added conditional allow of retired elements prefixed with 'XXX' for exclusive choices typeid=2,
--              needed for initial load of historical data having retired answers.
--              Amended to only load form element data for surveys identified in dbo.mstr_surveys of the AgencyDB (masters only).
--   20160801 - Amended to remove mstr_surveys that are no longer identified as master, or no longer exist in DW.
--   20161003 - Added the Mstr_SurveyElements.IsRequired column.
--   20161003 - Added the Mstr_Entity_Attributes.IsRequired column.
--   20161026 - Added the inclusion of retired 'xxx' for exclusive choice elements.
--   20161128 - Added the processing of AgencyDB_Mstr_Table_Columns_xref, and Client Demographics.

DECLARE @count          smallint
DECLARE @stop_flag      nvarchar(2)
DECLARE @Process        nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)

set @process = 'SP_AGENCYDB_UPDATE_MSTR_TABLES'
set @DW_Tablename = null
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)
DECLARE @SQL1           varchar(MAX)
DECLARE @SQL2           varchar(MAX)

print 'Processing SP_AGENCYDB_UPDATE_MSTR_TABLES: AgencyDB = ' +isnull(@p_AgencyDB,'NULL')
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
-- Process the AgencyDB Cursor
----------------------------------------------------------------------------------------

DECLARE AgencyDBCursor Cursor for
select distinct(LOV.value)
  from dbo.view_lov LOV
 where Name='AGENCYDB_BY_DATASOURCE'
   -- exclude DB not using Mstr tables
   and LOV.Value != 'OklahomaStaging'
   -- qualified selection:
   and isnull(@p_AgencyDB,'abcdefg') in ('abcdefg',LOV.value)
 order by LOV.Value;

OPEN AgencyDBCursor

FETCH next from AgencyDBCursor
      into @AgencyDB

WHILE @@FETCH_STATUS = 0
BEGIN

----------------------------------------------------------------------------------------
print ''
print 'Cont: Process Entity_Attributes - AgencyDB=' + @AgencyDB


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off'
    +' insert into ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Entity_Attributes'
    +' ([CDID]'
    +' ,[CxAttributeName]'
    +' ,[SiteID]'
    +' ,[CxDTypeID]'
    +' ,[CxDType]'
    +' ,[Org_Type]'
    +' ,[Ind_Type]'
    +' ,[SequenceOrder]'
    +' ,[RecordAsNumeric]'
    +' ,[RecordAsArbitraryText]'
    +' ,[IsProgramSpecific]'
    +' ,[Disabled]'
    +' ,[AuditDate]'
    +' ,[Pseudonym]'
    +' ,[DW_Extend_NonExclusive_Columns]'
    +' ,[DW_record_choice_as_seqnbr]'
    +' ,[Attributes_Last_Updated]'
    +' ,[IsRequired]'
    +' ,[DW_TableName])'
set @SQL2 = '
     SELECT DWTbl.[CDID]'
    +', DWTbl.[CxAttributeName]'
    +', DWTbl.[SiteID]'
    +', DWTbl.[CxDTypeID]'
    +', DWTbl.[CxDType]'
    +', DWTbl.[Org_Type]'
    +', DWTbl.[Ind_Type]'
    +', DWTbl.[SequenceOrder]'
    +', DWTbl.[RecordAsNumeric]'
    +', DWTbl.[RecordAsArbitraryText]'
    +', DWTbl.[IsProgramSpecific]'
    +', DWTbl.[Disabled]'
    +', DWTbl.[AuditDate]'
    +', DWTbl.[Pseudonym]'
    +', DWTbl.[DW_Extend_NonExclusive_Columns]'
    +', DWTbl.[DW_record_choice_as_seqnbr]'
    +', DWTbl.[Attributes_Last_Updated]'
    +' ,DWTbl.[IsRequired]'
    +', DWTbl.[DW_TableName]'
    +'
     from dbo.Mstr_Entity_Attributes DWTbl'
    +' where not exists (select Atbl.CDID'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Entity_Attributes Atbl'
    +' where Atbl.CDID = DWTbl.CDID)'

    print @SQL1
    print @SQL2
    --print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
    EXEC (@SQL1+@SQL2)


-- Update changes:
set @SQL1 = 'set nocount off'
    +' update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Entity_Attributes'
    +' Set CxAttributeName = DWTbl.[CxAttributeName]'
    +', SiteID = DWTbl.[SiteID]'
    +', CxDTypeID = DWTbl.[CxDTypeID]'
    +', CxDType = DWTbl.[CxDType]'
    +', Org_Type = DWTbl.[Org_Type]'
    +', Ind_Type = DWTbl.[Ind_Type]'
    +', SequenceOrder = DWTbl.[SequenceOrder]'
    +', RecordAsNumeric = DWTbl.[RecordAsNumeric]'
    +', RecordAsArbitraryText = DWTbl.[RecordAsArbitraryText]'
    +', IsProgramSpecific = DWTbl.[IsProgramSpecific]'
    +', Disabled = DWTbl.[Disabled]'
    +', AuditDate = DWTbl.[AuditDate]'
    +', Pseudonym = DWTbl.[Pseudonym]'
    +', DW_Extend_NonExclusive_Columns = DWTbl.[DW_Extend_NonExclusive_Columns]'
    +', DW_record_choice_as_seqnbr = DWTbl.[DW_record_choice_as_seqnbr]'
    +', Attributes_Last_Updated = DWTbl.[Attributes_Last_Updated]'
    +', DW_TableName = DWTbl.[DW_TableName]'
    +' ,[IsRequired] = DWTbl.[IsRequired]'
    +'
    from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Entity_Attributes Atbl'
    +' inner join dbo.Mstr_Entity_Attributes DWTbl on Atbl.CDID = DWTbl.CDID'
    +' where isnull(Atbl.AuditDate,convert(datetime,''19700101'',112)) < '
    +' isnull(DWTbl.AuditDate,convert(datetime,''19700101'',112))'
    +'    or isnull(Atbl.Attributes_Last_Updated,convert(datetime,''19700101'',112)) < '
    +' isnull(DWTbl.Attributes_Last_Updated,convert(datetime,''19700101'',112))'

    print @SQL1
    EXEC (@SQL1)


-- Remove no longer existing Attributes
set @SQL ='set nocount off '+
    ' delete ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Entity_Attributes'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Entity_Attributes Atbl'
    +' where not exists (select DWTbl.CDID'
    +' from dbo.Mstr_Entity_Attributes DWTbl'
    +' where Atbl.CDID = dWTbl.CDID)'

    print @SQL
    EXEC (@SQL)


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
print ''
print ''
print 'Cont: Process Entity_Attribute_Choices - AgencyDB=' + @AgencyDB


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off'
    +' insert into ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Entity_Attribute_Choices'
    +' ([CDDTVID]'
    +' ,[CDID]'
    +' ,[TextValue]'
    +' ,[Disabled]'
    +' ,[SequenceOrder]'
    +' ,[AuditDate]'
    +' ,[CRM_AttributeName]'
    +' ,[CRM_AttributeValue])'
set @SQL2 = '
     SELECT DWTbl.[CDDTVID]'
    +' ,DWTbl.[CDID]'
    +' ,DWTbl.[TextValue]'
    +' ,DWTbl.[Disabled]'
    +' ,DWTbl.[SequenceOrder]'
    +' ,DWTbl.[AuditDate]'
    +' ,DWTbl.[CRM_AttributeName]'
    +' ,DWTbl.[CRM_AttributeValue]'
    +'
     from dbo.Mstr_Entity_Attribute_Choices DWTbl'
    +' where not exists (select Atbl.CDDTVID'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Entity_Attribute_Choices Atbl'
    +' where Atbl.CDDTVID = DWTbl.CDDTVID)'

    print @SQL1
    print @SQL2
    --print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
    EXEC (@SQL1+@SQL2)


-- Update changes:
set @SQL1 = 'set nocount off'
    +' update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Entity_Attribute_Choices'
    +' Set [CDDTVID] = DWTbl.[CDDTVID]'
    +' , [CDID] = DWTbl.[CDID]'
    +' , [TextValue] = DWTbl.[TextValue]'
    +' , [Disabled] = DWTbl.[Disabled]'
    +' , [SequenceOrder] = DWTbl.[SequenceOrder]'
    +' , [AuditDate] = DWTbl.[AuditDate]'
    +' , [CRM_AttributeName] = DWTbl.[CRM_AttributeName]'
    +' , [CRM_AttributeValue] = DWTbl.[CRM_AttributeValue]'
    +'
    from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Entity_Attribute_Choices Atbl'
    +' inner join dbo.Mstr_Entity_Attribute_Choices DWTbl on Atbl.CDDTVID = DWTbl.CDDTVID'
    +' where isnull(Atbl.AuditDate,convert(datetime,''19700101'',112)) < '
    +' isnull(DWTbl.AuditDate,convert(datetime,''19700101'',112))'

    print @SQL1
    EXEC (@SQL1)


-- Remove no longer existing Attributes
set @SQL ='set nocount off '+
    ' delete ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Entity_Attribute_Choices'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Entity_Attribute_Choices Atbl'
    +' where not exists (select DWTbl.CDDTVID'
    +' from dbo.Mstr_Entity_Attribute_Choices DWTbl'
    +' where Atbl.CDDTVID = dWTbl.CDDTVID)'

    print @SQL
    EXEC (@SQL)


----------------------------------------------------------------------------------------
-- Surveys
----------------------------------------------------------------------------------------
print ''
print ''
print 'Cont: Process Surveys - AgencyDB=' + @AgencyDB


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing Surveys'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off'
    +' insert into ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Surveys'
    +' ( [SurveyID]'
    +' , [SurveyType]'
    +' , [SurveyName]'
    +' , [SecuredProgramID]'
    +' , [SourceSurveyID]'
    +' , [TakeOnlyOnce]'
    +' , [TakeOnlyOncePerEnroll]'
    +' , [disabled]'
    +' , [AuditDate]'
    +' , [DW_TableName])'
set @SQL2 = '
     SELECT DWTbl.[SurveyID]'
    +' , DWTbl.[SurveyType]'
    +' , DWTbl.[SurveyName]'
    +' , DWTbl.[SecuredProgramID]'
    +' , DWTbl.[SourceSurveyID]'
    +' , DWTbl.[TakeOnlyOnce]'
    +' , DWTbl.[TakeOnlyOncePerEnroll]'
    +' , DWTbl.[disabled]'
    +' , DWTbl.[AuditDate]'
    +' , DWTbl.[DW_TableName]'
    +'
     from dbo.Mstr_Surveys DWTbl'
    +' where (Dwtbl.SurveyName like ''%MST%'' or Dwtbl.SurveyName like ''%MASTER%'')'
    +' and not exists (select Atbl.SurveyID'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Surveys Atbl'
    +' where Atbl.SurveyID = DWTbl.SurveyID)'

    print @SQL1
    print @SQL2
    --print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
    EXEC (@SQL1+@SQL2)


-- Update changes:
set @SQL1 = 'set nocount off'
    +' update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Surveys'
    +' set [SurveyType] = DWTbl.[SurveyType]'
    +' ,[SurveyName] = DWTbl.[SurveyName]'
    +' ,[SecuredProgramID] = DWTbl.[SecuredProgramID]'
    +' ,[SourceSurveyID] = DWTbl.[SourceSurveyID]'
    +' ,[TakeOnlyOnce] = DWTbl.[TakeOnlyOnce]'
    +' ,[TakeOnlyOncePerEnroll] = DWTbl.[TakeOnlyOncePerEnroll]'
    +' ,[disabled] = DWTbl.[disabled]'
    +' ,[AuditDate] = DWTbl.[AuditDate]'
    +' ,[DW_TableName] = DWTbl.[DW_TableName]'
    +'
    from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Surveys Atbl'
    +' inner join dbo.Mstr_Surveys DWTbl on Atbl.SurveyID = DWTbl.SurveyID'
    +' where isnull(Atbl.AuditDate,convert(datetime,''19700101'',112)) < '
    +' isnull(DWTbl.AuditDate,convert(datetime,''19700101'',112))'

    print @SQL1
    EXEC (@SQL1)


-- Remove Surveys that are no longer named as as 'MASTER':
set @SQL ='set nocount off '+
    ' delete ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Surveys'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Surveys Atbl'
    +' inner join dbo.mstr_surveys dwtbl on atbl.surveyid = dwtbl.surveyid'
    +' where (Dwtbl.SurveyName not like ''%MST%'' and Dwtbl.SurveyName not like ''%MASTER%'')'
    print @SQL
    EXEC (@SQL)


-- Remove Surveys that are no longer exist within DW:
set @SQL ='set nocount off '+
    ' delete ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Surveys'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Surveys Atbl'
    +' where not exists (select ams.SurveyID'
                        +' from dbo.Mstr_Surveys ams'
                       +' where Atbl.SurveyID = ams.SurveyID)'
    print @SQL
   EXEC (@SQL)



----------------------------------------------------------------------------------------
-- Survey Elements
----------------------------------------------------------------------------------------
print ''
print ''
print 'Cont: Process SurveyElements - AgencyDB=' + @AgencyDB


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing Survey Elements'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off'
    +' insert into ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_SurveyElements'
    +' ( [SurveyElementID]'
    +' , [SurveyID]'
    +' , [SequenceOrder]'
    +' , [Stimulus]'
    +' , [Pseudonym]'
    +' , [SurveyElementTypeID]'
    +' , [SurveyElementType]'
    +' , [SourceSurveyElementID]'
    +' , [SurveyComment]'
    +' , [EntityTypeID]'
    +' , [EntitySubTypeID]'
    +' , [sourceSurveyElementID]'
    +' , [DW_Field]'
    +' , [DW_record_choice_as_seqnbr]'
    +' , [DW_Extend_NonExclusive_Columns]'
    +' , [IsRequired]'
    +' , [AuditDate])'
set @SQL2 = '
     SELECT DWTbl.[SurveyElementID]'
    +' , DWTbl.[SurveyID]'
    +' , DWTbl.[SequenceOrder]'
    +' , DWTbl.[Stimulus]'
    +' , DWTbl.[Pseudonym]'
    +' , DWTbl.[SurveyElementTypeID]'
    +' , DWTbl.[SurveyElementType]'
    +' , DWTbl.[SourceSurveyElementID]'
    +' , DWTbl.[SurveyComment]'
    +' , DWTbl.[EntityTypeID]'
    +' , DWTbl.[EntitySubTypeID]'
    +' , DWTbl.[sourceSurveyElementID]'
    +' , DWTbl.[DW_Field]'
    +' , DWTbl.[DW_record_choice_as_seqnbr]'
    +' , DWTbl.[DW_Extend_NonExclusive_Columns]'
    +' , DWTbl.[IsRequired]'
    +' , DWTbl.[AuditDate]'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Surveys ams'
    +' inner join dbo.Mstr_SurveyElements DWTbl on ams.surveyid = Dwtbl.surveyid'
    +' where not exists (select Atbl.SurveyElementID'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_SurveyElements Atbl'
    +' where Atbl.SurveyElementID = DWTbl.SurveyElementID)'
    +' and (isnull(Dwtbl.SurveyElementTypeID,1) in (1,2) or '
        +' (Dwtbl.SurveyElementTypeID not in (1,2) and Dwtbl.Stimulus not like ''XXX%'') )'

    print @SQL1
    print @SQL2
    --print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
    EXEC (@SQL1+@SQL2)


-- Update changes:
set @SQL1 = 'set nocount off'
    +' update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_SurveyElements'
    +' Set [SurveyID] = DWTbl.[SurveyID]'
    +' ,[SequenceOrder] = DWTbl.[SequenceOrder]'
    +' ,[Stimulus] = DWTbl.[Stimulus]'
    +' ,[Pseudonym] = DWTbl.[Pseudonym]'
    +' ,[SurveyElementTypeID] = DWTbl.[SurveyElementTypeID]'
    +' ,[SurveyElementType] = DWTbl.[SurveyElementType]'
    +' ,[SourceSurveyElementID] = DWTbl.[SourceSurveyElementID]'
    +' ,[SurveyComment] = DWTbl.[SurveyComment]'
    +' ,[EntityTypeID] = DWTbl.[EntityTypeID]'
    +' ,[EntitySubTypeID] = DWTbl.[EntitySubTypeID]'
    +' ,[sourceSurveyElementID] = DWTbl.[sourceSurveyElementID]'
    +' ,[DW_Field] = DWTbl.[DW_Field]'
    +' ,[DW_record_choice_as_seqnbr] = DWTbl.[DW_record_choice_as_seqnbr]'
    +' ,[DW_Extend_NonExclusive_Columns] = DWTbl.[DW_Extend_NonExclusive_Columns]'
    +' ,[IsRequired] = DWTbl.[IsRequired]'
    +' ,[AuditDate] = DWTbl.[AuditDate]'
    +'
    from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_SurveyElements Atbl'
    +' inner join dbo.Mstr_SurveyElements DWTbl on Atbl.SurveyElementID = DWTbl.SurveyElementID'
    +' where isnull(Atbl.AuditDate,convert(datetime,''19700101'',112)) < '
    +' isnull(DWTbl.AuditDate,convert(datetime,''19700101'',112))'

    print @SQL1
    EXEC (@SQL1)


-- Remove no longer existing Elements
set @SQL ='set nocount off '+
    ' delete ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_SurveyElements'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_SurveyElements Atbl'
    +' where not exists (select DWTbl.SurveyElementID'
                        +' from dbo.Mstr_SurveyElements DWTbl'
                       +' where Atbl.SurveyElementID = dWTbl.SurveyElementID)'

    print @SQL
    EXEC (@SQL)


-- Remove Elements no longer identified to the AgencyDB Mstr_Surveys table:
set @SQL ='set nocount off '+
    ' delete ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_SurveyElements'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_SurveyElements Atbl'
    +' where not exists (select ams.SurveyID'
                        +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Surveys ams'
                       +' where Atbl.SurveyID = ams.SurveyID)'

    print @SQL
    EXEC (@SQL)


-- Remove obsolete Elements
set @SQL ='set nocount off '+
    ' delete ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_SurveyElements'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_SurveyElements Atbl'
    +' inner join dbo.Mstr_SurveyElements DWTbl on Atbl.SurveyElementID = DWTbl.SurveyElementID'
    +' where (isnull(Dwtbl.SurveyElementTypeID,1) not in (1,2) and Dwtbl.Stimulus like ''XXX%'' )'

    print @SQL
    EXEC (@SQL)

----------------------------------------------------------------------------------------
-- Survey Element Choices
----------------------------------------------------------------------------------------
print ''
print ''
print 'Cont: Process SurveyElementChoices - AgencyDB=' + @AgencyDB


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing Survey Element Choices'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off'
    +' insert into ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_SurveyElementChoices'
    +' ([SurveyElementChoiceID]'
    +' ,[SurveyElementID]'
    +' ,[Sequence]'
    +' ,[choice]'
    +' ,[Weight]'
    +' ,[CDDTVID]'
    +' ,[AuditDate])'
set @SQL2 = '
     SELECT DWTbl.[SurveyElementChoiceID]'
    +' ,DWTbl.[SurveyElementID]'
    +' ,DWTbl.[Sequence]'
    +' ,DWTbl.[choice]'
    +' ,DWTbl.[Weight]'
    +' ,DWTbl.[CDDTVID]'
    +' ,DWTbl.[AuditDate]'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_SurveyElements ames'
    +' inner join dbo.Mstr_SurveyElementChoices DWTbl on ames.SurveyElementID = Dwtbl.SurveyElementID'
    +' where not exists (select Atbl.SurveyElementChoiceID'
                        +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_SurveyElementChoices Atbl'
                       +' where Atbl.SurveyElementChoiceID = DWTbl.SurveyElementChoiceID)'
                       +' and (ames.SurveyElementTypeID in (1,2) or '
                            +' (ames.SurveyElementTypeID not in (1,2) and ames.Stimulus not like ''XXX%'') )'

    print @SQL1
    print @SQL2
    --print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
    EXEC (@SQL1+@SQL2)


-- Update changes:
set @SQL1 = 'set nocount off'
    +' update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_SurveyElementChoices'
    +' Set [SurveyElementID] = DWTbl.[SurveyElementID]'
    +' ,[Sequence] = DWTbl.[Sequence]'
    +' ,[choice] = DWTbl.[choice]'
    +' ,[Weight] = DWTbl.[Weight]'
    +' ,[CDDTVID] = DWTbl.[CDDTVID]'
    +' ,[AuditDate] = DWTbl.[AuditDate]'
    +'
    from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_SurveyElementChoices Atbl'
    +' inner join dbo.Mstr_SurveyElementChoices DWTbl on Atbl.SurveyElementChoiceID = DWTbl.SurveyElementChoiceID'
    +' where isnull(Atbl.AuditDate,convert(datetime,''19700101'',112)) < '
    +' isnull(DWTbl.AuditDate,convert(datetime,''19700101'',112))'

    print @SQL1
    EXEC (@SQL1)


-- Remove no longer existing Choices
set @SQL ='set nocount off '+
    ' delete ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_SurveyElementChoices'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_SurveyElementChoices Atbl'
    +' where not exists (select DWTbl.SurveyElementChoiceID'
    +' from dbo.Mstr_SurveyElementChoices DWTbl'
    +' where Atbl.SurveyElementChoiceID = dWTbl.SurveyElementChoiceID)'

    print @SQL
    EXEC (@SQL)


-- Remove choices no longer identified with an AgencyDB Mstr_SurveyElement
set @SQL ='set nocount off '+
    ' delete ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_SurveyElementChoices'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_SurveyElementChoices Atbl'
    +' where not exists (select ame.SurveyElementID'
                        +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_SurveyElements ame'
                       +' where Atbl.SurveyElementID = ame.SurveyElementID)'

    print @SQL
    EXEC (@SQL)


-- Remove Obsolete Choices
set @SQL ='set nocount off '+
    ' delete ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_SurveyElementChoices'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_SurveyElementChoices Atbl'
    +' inner join dbo.Mstr_SurveyElements mse on Atbl.SurveyElementID = mse.SurveyElementID'
    +' where (mse.SurveyElementTypeID not in (1, 2) and mse.Stimulus like ''XXX%'')'

    print @SQL
    EXEC (@SQL)


----------------------------------------------------------------------------------------
-- Classes
----------------------------------------------------------------------------------------
print ''
print ''
print 'Cont: Process Classes - AgencyDB=' + @AgencyDB


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing Classes'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off'
    +' insert into ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Classes'
    +' ( [ClassID]'
    +' , [ClassName]'
    +' , [ClassDescription]'
    +' , [Disabled]'
    +' , [Mstr_SurveyID]'
    +' , [SurveyID])
     SELECT tc.[ClassID]'
    +' , tc.[ClassName]'
    +' , tc.[ClassDescription]'
    +' , ms.[Disabled]'
    +' , etos.[SourceSurveyID]'
    +' , ms.[SurveyID]'
    +'
  from dbo.mstr_surveys ms'
  +' left join lmssrvr.tracker3.dbo.tracker_classes tc'
      +'  on substring(ms.SurveyName,25,LEN(ms.SurveyName)) = convert(varchar,tc.ClassDescription)'
  +' left join etosolaris.dbo.Surveys etos on ms.SurveyID = etos.surveyid'
+' where ms.SurveyName like ''%Educ%'''
+' and ms.surveyname not like ''%MASTER%'''
+' and ms.disabled = 0'
+' and tc.classid is not null'
+' and not exists (select Atbl.ClassID'
                  +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Classes Atbl'
                  +' where Atbl.ClassID = tc.ClassID)'

    print @SQL1
    EXEC (@SQL1)


-- Update for disabled or re-enabled class offering:
set @SQL1 = 'set nocount off'
    +' update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Classes'
    +' set [Disabled] = DWTbl.[Disabled]'
    +'
    from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Classes Atbl'
    +' inner join dbo.Mstr_Surveys DWTbl on Atbl.SurveyID = DWTbl.SurveyID'
    +' left join lmssrvr.tracker3.dbo.tracker_classes tc'
        +'  on Atbl.ClassID = tc.ClassID'
    +' where isnull(Atbl.disabled,0) != isnull(Dwtbl.disabled,0)'

    print @SQL1
    EXEC (@SQL1)



----------------------------------------------------------------------------------------
-- Master AgencyDB Table Column xref
----------------------------------------------------------------------------------------
print ''
print ''
print 'Cont: Process Mstr_AgencyDB_Table_Column_Xref - AgencyDB=' + @AgencyDB


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing Mstr_AgencyDB_Table_Column_Xref'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------
set @SQL1 = 'set nocount off'
    +' insert into ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_AgencyDB_Table_Column_Xref'
    +' (Table_Name, Column_Name, DW_Column_Name, DW_Table_Name, DB_Profile, Comments)'
set @SQL2 = '
  select isnull(tblxref.Column_Name_Xref,xref.Table_name) as Table_Name'
    +' ,case when tblxref.Column_Name = ''*TABLENAME*'' and xref.Column_Name = ''*TABLENAME*'' then tblxref.Column_Name'
      +' else xref.Column_Name_Xref end as Column_Name'
    +' ,xref.Column_Name as dw_column_name '
    +' ,xref.Table_name as dw_Table_name '
    +' ,xref.DB_Profile'
    +' ,null as comments'
    +' from dbo.Mstr_Table_Column_Xref xref'
    +' left join dbo.Mstr_Table_Column_Xref tblxref '
      +' on xref.Table_Name = tblxref.Table_Name and tblxref.Column_Name = ''*TABLENAME*'''
   +' where isnull(xref.Exclude_flag,0) = 0 '
     +' and xref.Column_Name_Xref != ''*EXCLUDE*'''
     +' and (select COUNT(*) '
           +'  from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_AgencyDB_Table_Column_Xref axref'
           +' where axref.Table_Name = isnull(tblxref.Column_Name_Xref,xref.Table_name)'
             +' and axref.Column_Name = '
                  +' case when tblxref.Column_Name = ''*TABLENAME*'' and xref.Column_Name = ''*TABLENAME*'' then tblxref.Column_Name'
                         +' else xref.Column_Name_Xref end) = 0'

    print @SQL1
    print @SQL2
    --print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
    EXEC (@SQL1+@SQL2)


-- Remove no longer existing Elements
set @SQL1 = 'set nocount off'
    +' delete ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_AgencyDB_Table_Column_Xref'
    +'
    from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_AgencyDB_Table_Column_Xref Atbl'
+' where (select count(*) from dbo.Mstr_Table_Column_Xref DWTbl'
       +'  where DWTbl.Table_Name = Atbl.DW_Table_Name'
          +' and Dwtbl.Column_Name = Atbl.DW_Column_Name) = 0'

    print @SQL1
    EXEC (@SQL1)


----------------------------------------------------------------------------------------
-- Master Client Demographics
----------------------------------------------------------------------------------------
print ''
print ''
print 'Cont: Process Mstr_Client_Demographics - AgencyDB=' + @AgencyDB

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing Mstr_Client_Demographics'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off'
    +' insert into ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Client_Demographics'
    +'  ([CDID]'
    +'  ,[SiteID]'
    +'  ,[CxDemographicName]'
    +'  ,[CxDTypeID]'
    +'  ,[CxDType]'
    +'  ,[RecordAsNumeric]'
    +'  ,[RecordAsArbitraryText]'
    +'  ,[IsProgramSpecific]'
    +'  ,[SequenceOrder]'
    +'  ,[IsRequired]'
    +'  ,[Disabled]'
    +'  ,[EntityTypeID]'
    +'  ,[EntityType]'
    +'  ,[EntitySubTypeID]'
    +'  ,[AuditStaffID]'
    +'  ,[AuditDate]'
    +'  ,[SharedAcrossEnterprise]'
    +'  ,[AcceptAsDataPoint]'
    +'  ,[CxDescription]'
    +'  ,[ProgramID]'
    +'  ,[CustomSettings]'
    +'  ,[CDID_Source]'
    +'  ,[RepositoryItemID]'
    +'  ,[Pseudonym]'
    +'  ,[DW_Extend_NonExclusive_Columns]'
    +'  ,[DW_record_choice_as_seqnbr]'
    +'  ,[Demographics_Last_Updated])'
set @SQL2 = '
  select [CDID]'
    +'  ,[SiteID]'
    +'  ,[CxDemographicName]'
    +'  ,[CxDTypeID]'
    +'  ,[CxDType]'
    +'  ,[RecordAsNumeric]'
    +'  ,[RecordAsArbitraryText]'
    +'  ,[IsProgramSpecific]'
    +'  ,[SequenceOrder]'
    +'  ,[IsRequired]'
    +'  ,[Disabled]'
    +'  ,[EntityTypeID]'
    +'  ,[EntityType]'
    +'  ,[EntitySubTypeID]'
    +'  ,[AuditStaffID]'
    +'  ,[AuditDate]'
    +'  ,[SharedAcrossEnterprise]'
    +'  ,[AcceptAsDataPoint]'
    +'  ,[CxDescription]'
    +'  ,[ProgramID]'
    +'  ,[CustomSettings]'
    +'  ,[CDID_Source]'
    +'  ,[RepositoryItemID]'
    +'  ,[Pseudonym]'
    +'  ,[DW_Extend_NonExclusive_Columns]'
    +'  ,[DW_record_choice_as_seqnbr]'
    +'  ,[Demographics_Last_Updated]
  FROM dbo.Mstr_Client_Demographics dwtbl'
+' where (select COUNT(*) '
        +'  from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Client_Demographics atbl'
        +' where atbl.CDID = dwtbl.CDID) = 0'

    print @SQL1
    print @SQL2
    --print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
    EXEC (@SQL1+@SQL2)


-- Update changes:
set @SQL1 = 'set nocount off'
    +' update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Client_Demographics'
  +' set [SiteID] = dwtbl.[SiteID]'
    +'  ,[CxDemographicName] = dwtbl.[CxDemographicName]'
    +'  ,[CxDTypeID] = dwtbl.[CxDTypeID]'
    +'  ,[CxDType] = dwtbl.[CxDType]'
    +'  ,[RecordAsNumeric] = dwtbl.[RecordAsNumeric]'
    +'  ,[RecordAsArbitraryText] = dwtbl.[RecordAsArbitraryText]'
    +'  ,[IsProgramSpecific] = dwtbl.[IsProgramSpecific]'
    +'  ,[SequenceOrder] = dwtbl.[SequenceOrder]'
    +'  ,[IsRequired] = dwtbl.[IsRequired]'
    +'  ,[Disabled] = dwtbl.[Disabled]'
    +'  ,[EntityTypeID] = dwtbl.[EntityTypeID]'
    +'  ,[EntityType] = dwtbl.[EntityType]'
    +'  ,[EntitySubTypeID] = dwtbl.[EntitySubTypeID]'
    +'  ,[AuditStaffID] = dwtbl.[AuditStaffID]'
    +'  ,[AuditDate] = dwtbl.[AuditDate]'
    +'  ,[SharedAcrossEnterprise] = dwtbl.[SharedAcrossEnterprise]'
    +'  ,[AcceptAsDataPoint] = dwtbl.[AcceptAsDataPoint]'
    +'  ,[CxDescription] = dwtbl.[CxDescription]'
    +'  ,[ProgramID] = dwtbl.[ProgramID]'
    +'  ,[CustomSettings] = dwtbl.[CustomSettings]'
    +'  ,[CDID_Source] = dwtbl.[CDID_Source]'
    +'  ,[RepositoryItemID] = dwtbl.[RepositoryItemID]'
    +'  ,[Pseudonym] = dwtbl.[Pseudonym]'
    +'  ,[DW_Extend_NonExclusive_Columns] = dwtbl.[DW_Extend_NonExclusive_Columns]'
    +'  ,[DW_record_choice_as_seqnbr] = dwtbl.[DW_record_choice_as_seqnbr]'
    +'  ,[Demographics_Last_Updated] = dwtbl.[Demographics_Last_Updated]
  from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Client_Demographics atbl'
    +' inner join dbo.Mstr_Client_Demographics DWTbl on Atbl.CDID = DWTbl.CDID'
    +' where isnull(Atbl.AuditDate,convert(datetime,''19700101'',112)) < '
    +' isnull(DWTbl.AuditDate,convert(datetime,''19700101'',112))'

    print @SQL1
    EXEC (@SQL1)


-- Remove no longer existing Elements
set @SQL1 = 'set nocount off'
    +' delete ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Client_Demographics'
    +'
    from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Client_Demographics Atbl'
+' where (select count(*) from dbo.Mstr_Client_Demographics DWTbl'
       +'  where DWTbl.CDID = Atbl.CDID) = 0'

    print @SQL1
    EXEC (@SQL1)

----------------------------------------------------------------------------------------
-- Mstr_Client_Demographic_Choices
----------------------------------------------------------------------------------------
print ''
print ''
print 'Cont: Process Mstr_Client_Demographic_Choices - AgencyDB=' + @AgencyDB


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off'
    +' insert into ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Client_Demographic_Choices'
    +' ([CDDTVID]'
    +' ,[CDID]'
    +' ,[TextValue]'
    +' ,[Disabled]'
    +' ,[SequenceOrder]'
    +' ,[AuditDate])'
set @SQL2 = '
     SELECT DWTbl.[CDDTVID]'
    +' ,DWTbl.[CDID]'
    +' ,DWTbl.[TextValue]'
    +' ,DWTbl.[Disabled]'
    +' ,DWTbl.[SequenceOrder]'
    +' ,DWTbl.[AuditDate]'
    +'
     from dbo.Mstr_Client_Demographic_Choices DWTbl'
    +' where not exists (select Atbl.CDDTVID'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Client_Demographic_Choices Atbl'
    +' where Atbl.CDDTVID = DWTbl.CDDTVID)'

    print @SQL1
    print @SQL2
    --print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
    EXEC (@SQL1+@SQL2)


-- Update changes:
set @SQL1 = 'set nocount off'
    +' update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Client_Demographic_Choices'
    +' Set [CDDTVID] = DWTbl.[CDDTVID]'
    +' , [CDID] = DWTbl.[CDID]'
    +' , [TextValue] = DWTbl.[TextValue]'
    +' , [Disabled] = DWTbl.[Disabled]'
    +' , [SequenceOrder] = DWTbl.[SequenceOrder]'
    +' , [AuditDate] = DWTbl.[AuditDate]'
    +'
    from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Client_Demographic_Choices Atbl'
    +' inner join dbo.Mstr_Client_Demographic_Choices DWTbl on Atbl.CDDTVID = DWTbl.CDDTVID'
    +' where isnull(Atbl.AuditDate,convert(datetime,''19700101'',112)) < '
    +' isnull(DWTbl.AuditDate,convert(datetime,''19700101'',112))'

    print @SQL1
    EXEC (@SQL1)


-- Remove no longer existing Attributes
set @SQL ='set nocount off '+
    ' delete ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Client_Demographic_Choices'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Client_Demographic_Choices Atbl'
    +' where not exists (select DWTbl.CDDTVID'
    +' from dbo.Mstr_Client_Demographic_Choices DWTbl'
    +' where Atbl.CDDTVID = dWTbl.CDDTVID)'

    print @SQL
    EXEC (@SQL)

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- Continue Cursor:
   FETCH next from AgencyDBCursor
         into @AgencyDB

END -- End of AgencyDBCursor loop

CLOSE AgencyDBCursor
DEALLOCATE AgencyDBCursor

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


print 'End of Process: SP_AGENCYDB_UPDATE_MSTR_TABLES'
GO
