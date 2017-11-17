USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_Survey_Non_ETO_Xref_Process]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- drop proc dbo.SP_AGENCYDB_Survey_Non_ETO_Xref_Process
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_Survey_Non_ETO_Xref_Process]
 (@p_process               nvarchar(100)
 ,@p_datasource            nvarchar(10)
 ,@p_DW_Tablename          nvarchar(100)
 ,@p_Agency_Full_TableName nvarchar(100)
 ,@p_no_exec_flag          nvarchar(10)  = 'N')
AS
--
-- This script controls the preliminary processing of the AgencyDB Survey to the DataWarehouse
-- by creating, maintaining, updating the dbo.Non_ETO_SurveyResponse_Xref table
--
-- This is a generic common process that is used by all the AgencyDB Survey table integration processes to:
-- 1. AgencyDB record: identify / null-out the ETO_SurveyResponseID that is found to occur more that once in the AgencyDB table.
-- 2. Re-map xref'd survey records that have had an AgencyDB SurveyResponseID change.
-- 3. Create a Non_ETO_SurveyResponse_Xref record for the AgencyDB Survey records that identify an original ETO_SurveyResponseID.
--    This creates the positive link back to the original ETO SurveyResponse w/o delete/re-adding records from the first AgencyDB load.
-- 4. Update the datasource for the DW Survey Table records linking back to the AgencyDB via the Non_ETO_SurveyResponses_xref table.
-- 5. Update the DW SurveyResponses table for records linking back to the AgencyDB via the Non_ETO_SurveyResponses_xref table.
-- 6. Create new Non_ETO_SurveyResponse_Xref records for AgencyDB Survey records that have not been yet cross referenced (new responses).
-- 7. Update the AgencyDB Survey records with the latest DW_SurveyResponseID cross reference.
--
-- Parameters:
--   @p_process - (required) AgencyDB process name to validate whether table or site is to be processed
--   @P_datasource - (required) AgencyDB datasource identifier
--   @p_DW_Tablename - (required) Name of DW table being processed
--   @p_Agency_Full_TableName - (required) fully qualified AgencyDB table name that includes the servername
--   @p_no_exec_flag - (optional) when set to 'Y', will just display the dynamic scripts w/o actually executing it.
--
-- History:
--   20161114 - New Procedure.


DECLARE @SQL            varchar(MAX)

print '----------------------------------------------------------------------------------------------------------------'
print 'Running Sub procedure SP_AGENCYDB_Survey_Non_ETO_Xref_Process'
print '  @p_process: ' +@p_process +', @p_datasource: ' +@p_datasource +', p_dw_tablename: ' +@p_dw_tablename
     +', @p_agency_Full_tablename: ' +@p_Agency_Full_Tablename +', @p_no_exec_flag: ' +isnull(@p_No_exec_flag,'Null')

----------------------------------------------------------------------------------------
-- Step 1:
-- clearout secondary replicated ETO_SurveyResponseID from the AgencyDB Survey table:
-- If the ETO_SureveyResponseID is not cleared for the secondary records,
-- then the next process which creates the Non_ETO_SurveyResponse_Xref will fail
-- due to the unique constraint on SurveyResponseID (coming from the mapped ETO_SurveyResponseID)

print ' '
print 'Step 1: AgencyDB record: identify / null-out the ETO_SurveyResponseID found to occur more that once in the AgencyDB table'
set @SQL = ''
set @SQL = 'set nocount off 
 Declare DupsCursor cursor for
 select distinct(dups.ETO_SurveyResponseID) 
 from  ' +@p_Agency_Full_TableName +' dups
  where (select COUNT(*) from ' +@p_Agency_Full_TableName +' dups2
  where dups2.ETO_SurveyResponseID = dups.ETO_SurveyResponseID) > 1
 Declare @Dup_ETO_SurveyResponseID int
 Open DupsCursor
 Fetch next from DupsCursor into @Dup_ETO_SurveyResponseID
 While @@FETCH_STATUS = 0
 Begin 
 update ' +@p_Agency_Full_TableName +'
 set ETO_SurveyResponseID = null
 where SurveyResponseID in 
 (select SurveyResponseID
  from (
 select ROW_NUMBER() OVER (ORDER BY atbl.ETO_SurveyResponseID) AS Row
      ,atbl.SurveyResponseID, atbl.SurveyDate, atbl.ETO_SurveyResponseID
 from ' +@p_Agency_Full_TableName +' atbl
 where atbl.ETO_SurveyResponseID = @Dup_ETO_SurveyResponseID) duprecs
 where ROW > 1)
 Fetch next from DupsCursor into @Dup_ETO_SurveyResponseID
 End				
 CLOSE DupsCursor
 DEALLOCATE DupsCursor'


    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)


----------------------------------------------------------------------------------------
-- Step 2:
-- Process previously xref'd AgencyDB Survey records, that have since had a SurveyResponseID change at AgencyDB level
-- (should this step not be run, the following step to create a new xref record will fail - unique key constraint
--  becuase a duplicate DW SurveyResponseID already exists for the previously xref'd record)
print ' '
print 'Step 2: Re-map xref survey records that have had an AgencyDB SurveyResponseID change'

-- update existing DW Survey Record with a null AuditDate to trigger an integration update to the record:
set @SQL = 'set nocount off '+
     ' update dbo.' +@p_DW_Tablename 
       +' set AuditDate = null'
   +' from dbo.' +@p_DW_Tablename +' dwtbl'
   +' inner join dbo.Non_ETO_SurveyResponse_Xref dwxref on dwtbl.SurveyResponseID = dwxref.SurveyResponseID'
   +' inner join ' +@p_Agency_Full_TableName +' Atbl'
     +' on dwxref.SurveyResponseID = Atbl.ETO_SurveyResponseID'
  +' where dwxref.Source = ''' +@p_datasource +''''
    +' and not exists (select dwxref2.surveyresponseid '
                      +' from dbo.Non_ETO_SurveyResponse_Xref dwxref2'
                     +' where dwxref2.Non_ETO_ID = Atbl.SurveyResponseID)'
    +' and exists (select dwtbl.SurveyResponseID'
                  +' from ' +@p_DW_Tablename  +' dwtbl'
                 +' where dwtbl.SurveyResponseID = dwxref.SurveyResponseID)'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)

-- update xref record with new AgencyDB SurveyResponseID:
set @SQL = 'set nocount off '+
 +' update dbo.Non_ETO_SurveyResponse_Xref'
    +' set Non_ETO_ID = Atbl.SurveyResponseID'
   +' from dbo.Non_ETO_SurveyResponse_Xref dwxref'
  +' inner join ' +@p_Agency_Full_TableName +' Atbl'
     +' on dwxref.SurveyResponseID = Atbl.ETO_SurveyResponseID'
  +' where dwxref.Source = ''' +@p_datasource +''''
    +' and not exists (select dwxref2.surveyresponseid '
                      +' from dbo.Non_ETO_SurveyResponse_Xref dwxref2'
                     +' where dwxref2.Non_ETO_ID = Atbl.SurveyResponseID)'
    +' and exists (select dwtbl.SurveyResponseID'
                  +' from ' +@p_DW_Tablename  +' dwtbl'
                 +' where dwtbl.SurveyResponseID = dwxref.SurveyResponseID)'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)

----------------------------------------------------------------------------------------
-- Step 3:
-- create non_ETO xref entries for new SurveyResponse records from AgencyDB (that originated from ETO):
print ' '
print 'Step 3: Creating non_ETO_Xref for AgencyDB surveys that have been mapped to existing DW surveys'
set @SQL = 'set nocount off '+
    ' set identity_insert dbo.non_eto_SurveyResponse_xref on '
    +' insert into dbo.Non_ETO_SurveyResponse_Xref'
    +' (SurveyResponseID, Non_ETO_ID, Non_ETO_Site_ID, Source, DW_TableName)'
    +'
     select ETO_SurveyResponseID, SurveyResponseID, Atbl.SiteID, ''' +@p_datasource +''''  +',''' +@p_DW_Tablename +''''
    +'
     from ' +@p_Agency_Full_TableName +' Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' where isnull(Atbl.ETO_SurveyResponseID,0) != 0'
    +' and not exists (select dwxref.SurveyResponseID'
                      +' from dbo.Non_ETO_SurveyResponse_Xref dwxref'
                     +' where dwxref.source = ''' +@p_datasource +''''
                       +' and dwxref.Non_ETO_ID = Atbl.SurveyResponseID'
                       +' and dwxref.DW_tableName = ''' +@p_DW_Tablename +''''
                       +' and dwxref.Non_ETO_Site_ID = atbl.SiteID)'
    +' and exists (select SurveyResponseID from dbo.' +@p_DW_Tablename 
                     +' dtbl where dtbl.SurveyResponseID = ETO_SurveyResponseID'
                     +' and dtbl.siteid = Atbl.SiteID)'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@p_process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)


----------------------------------------------------------------------------------------
-- Step 4:
-- update the DW Survey's datasource for any new re-mapping of non-eto-exref records to an existing ETO record:
print ' '
print 'Step 4: Updating dw Survey table datasource for remapped surveys'
set @SQL = 'set nocount off '+
     ' update dbo.' +@p_DW_Tablename 
       +' set DataSource = dwxref.source'
      +' from dbo.Non_ETO_SurveyResponse_Xref dwxref'
      +' inner join ' +@p_DW_Tablename +' dwtbl on dwxref.SurveyResponseID = dwtbl.SurveyResponseID'
            +' and dwxref.Source != isnull(dwtbl.DataSource,''ETO'')'
      +' where dwxref.source = ''' +@p_datasource +''''

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    exec (@SQL)


----------------------------------------------------------------------------------------
-- Step 5:
-- update the DW SurveyResponses table datasource for any new re-mapping of non-eto-exref records to an existing ETO record:
print ' '
print 'Step 5: Updating dw.surveyresponses datasource for remapped surveys'
set @SQL = 'set nocount off '+
     ' update dbo.SurveyResponses'
       +' set DataSource = dwxref.source'
      +' from dbo.Non_ETO_SurveyResponse_Xref dwxref'
      +' inner join dbo.SurveyResponses dwtbl on dwxref.SurveyResponseID = dwtbl.SurveyResponseID'
            +' and dwxref.Source != isnull(dwtbl.DataSource,''ETO'')'
      +' where dwxref.source = ''' +@p_datasource +''''

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    exec (@SQL)


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- Step 6:
-- For AgencyDB records that DO NOT originate from ETO:
-- create non_ETO xref entries for new SurveyResponse records from AgencyDB:
print ' '
print 'Step 6: Creating xref for surveys not yet existing in DW'
set @SQL = 'set nocount off '+
    ' set identity_insert dbo.non_eto_SurveyResponse_xref off '
    +' insert into dbo.Non_ETO_SurveyResponse_Xref'
      +' (Non_ETO_ID, Non_ETO_Site_ID, Source, DW_TableName)'
    +'
     select SurveyResponseID, Atbl.SiteID, ''' +@p_datasource +''''  +',''' +@p_DW_Tablename +''''
    +'
     from ' +@p_Agency_Full_TableName +' Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +' and asbd.DataSource =  ''' +@p_datasource +''''
    +' where not exists (select dwxref.SurveyResponseID'
                        +' from dbo.Non_ETO_SurveyResponse_Xref dwxref'
                       +' where dwxref.source = ''' +@p_datasource +''''
                         +' and dwxref.Non_ETO_ID = Atbl.SurveyResponseID'
                         +' and dwxref.DW_tableName = ''' +@p_DW_Tablename +''''
                         +' and dwxref.Non_ETO_Site_ID = atbl.SiteID)'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@p_process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)

----------------------------------------------------------------------------------------
-- Step 7:
-- Assign new NON-ETO xref ID to new records from AgencyDB:
print ' '
print 'Step 7: Updating AgencyDB source table with DW xref indexes'
set @SQL = 'set nocount off '+
    'update ' +@p_Agency_Full_TableName
    +' Set [DW_SurveyResponseID] = dwxref.[SurveyResponseID]'
    +'
     from ' +@p_Agency_Full_TableName +' Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' inner join dbo.Non_ETO_SurveyResponse_Xref dwxref'
       +' on dwxref.Non_ETO_ID = Atbl.SurveyResponseID and dwxref.source = ''' +@p_datasource +''''
      +' and dwxref.DW_tableName = ''' +@p_DW_Tablename +''''
    +' Where dbo.FN_Check_Process_Inhibitor ('''+@p_process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)


----------------------------------------------------------------------------------------

print 'End of Process: SP_AGENCYDB_Survey_Non_ETO_Xref_Process'
print '----------------------------------------------------------------------------------------------------------------'
GO
