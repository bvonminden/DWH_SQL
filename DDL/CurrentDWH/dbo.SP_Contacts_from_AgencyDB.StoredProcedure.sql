USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_Contacts_from_AgencyDB]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_Contacts_from_AgencyDB
--
CREATE PROCEDURE [dbo].[SP_Contacts_from_AgencyDB]
 (@p_datasource      nvarchar(10) = null
 ,@p_entity_id       int = null)
AS
--
-- This script controls integration of Agency DB Clients to the Data Warehous Contacts tables.
-- Processing ETO Entities identified as Non-Individuals.
--
-- Will exclude from DW if Site Does not exist in dbo.agencies
--
-- Table effected - dbo.Contacts
--
-- Insert: select and insert when Contact is found to be missing in the DW.
-- Update: select and update when Contact exists in DW and has been changed but has been changed flagged by Audit_Date.
--
-- History:
--   20130325 - New Procedure.


DECLARE @count        smallint
DECLARE @p_stop_flag  nvarchar(2)
DECLARE @Process      nvarchar(50)
DECLARE @AgencyDB_Srvr  nvarchar(30)

set @process = 'SP_CONTACTS_FROM_AGENCYDB'
Set @p_stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            nvarchar(4000)

print 'Processing SP_Contacts_from_AgencyDB: Datasource = ' +isnull(@p_datasource,'NULL')
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
print 'Processing SP_Contacts_from_AgencyDB - retrieving datasource DB Srvr from LOV tables'

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
print 'Processing SP_Contacts - Insert new records - AgencyDB=' + @AgencyDB
print 'AgencyDB Server=' +@AgencyDB_Srvr

-- Extraction for Entity:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Record'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL = 
     ' insert into dbo.contacts'
    +' ([DataSource],[Source_Contact_ID],[Site_ID]'
    +' ,[Full_Name],[Last_Name],[First_Name],[Middle_Name]'
    +' ,[Prefix],[Suffix],[Entity_Type_ID],[Entity_Type],[Entity_Subtype],[Entity_Subtype_ID]'
    +' ,[Program_ID],[Address1],[Address2],[City],[State],[ZipCode],[county],[Email],[Phone1]'
    +' ,[Supervised_By_ID],[START_DATE],[Termination_Date]'
    +' ,[NHV_ID],[NURSE_0_ETHNICITY]'
    +' ,[NURSE_1_RACE],[NURSE_1_RACE_0],[NURSE_1_RACE_1],[NURSE_1_RACE_2],[NURSE_1_RACE_3]'
    +' ,[NURSE_1_RACE_4],[NURSE_1_RACE_5],[NURSE_0_GENDER]'
    +' ,[NURSE_0_YEAR_COMMHEALTH_EXPERIENCE],[NURSE_0_YEAR_NURSING_EXPERIENCE]'
    +' ,[NURSE_0_YEAR_MATERNAL_EXPERIENCE],[NURSE_0_FIRST_HOME_VISIT_DATE]'
    +' ,[NURSE_0_LANGUAGE],[NURSE_0_YEAR_SUPERVISOR_EXPERIENCE],[NURSE_0_BIRTH_YEAR]'
    +' ,[NURSE_0_ID_AGENCY],[NURSE_0_PROGRAM_POSITION1],[NURSE_0_PROGRAM_POSITION2]'
    +' ,[NURSE_PROFESSIONAL_1_REASON_HIRE]'
    +' ,[Date_Created],[Audit_Date],[Audit_Staff_ID]'
    +' ,[flag_disregard_disabled])'
    +'
     select ''' +@p_datasource +''''
    +' , entity_id as source_contact_id,AIS.[Site_ID]'
    +' ,AIS.[Full_Name],AIS.[Last_Name],AIS.[First_Name],AIS.[Middle_Name]'
    +' ,AIS.[Prefix],AIS.[Suffix],AIS.[Entity_Type_ID],AIS.[Entity_Type],AIS.[Entity_Subtype],AIS.[Entity_Subtype_ID]'
    +' ,AIS.[Program_ID],AIS.[Address1],AIS.[Address2],AIS.[City],AIS.[State],AIS.[ZipCode],AIS.[county]'
    +' ,AIS.[Email],AIS.[Phone1],AIS.[Supervised_By_ID],AIS.[START_DATE],AIS.[Termination_Date]'
    +' ,AIS.[NHV_ID],AIS.[NURSE_0_ETHNICITY]'
    +' ,AIS.[NURSE_1_RACE],AIS.[NURSE_1_RACE_0],AIS.[NURSE_1_RACE_1],AIS.[NURSE_1_RACE_2],AIS.[NURSE_1_RACE_3]'
    +' ,AIS.[NURSE_1_RACE_4],AIS.[NURSE_1_RACE_5],AIS.[NURSE_0_GENDER]'
    +' ,AIS.[NURSE_0_YEAR_COMMHEALTH_EXPERIENCE],AIS.[NURSE_0_YEAR_NURSING_EXPERIENCE]'
    +' ,AIS.[NURSE_0_YEAR_MATERNAL_EXPERIENCE],AIS.[NURSE_0_FIRST_HOME_VISIT_DATE]'
    +' ,AIS.[NURSE_0_LANGUAGE],AIS.[NURSE_0_YEAR_SUPERVISOR_EXPERIENCE],AIS.[NURSE_0_BIRTH_YEAR]'
    +' ,AIS.[NURSE_0_ID_AGENCY],AIS.[NURSE_0_PROGRAM_POSITION1],AIS.[NURSE_0_PROGRAM_POSITION2]'
    +' ,AIS.[NURSE_PROFESSIONAL_1_REASON_HIRE]'
    +' ,AIS.[Date_Created],AIS.[Audit_Date],AIS.[Audit_Staff_ID]'
    +' ,AIS.[flag_disregard_disabled]'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.IA_Staff AIS'
    +' where not exists (select Contacts.Contact_ID'
    +' from dbo.Contacts'
    +' where Contacts.Datasource = ''' +@p_datasource +''''
    +' and Contacts.Source_Contact_Id = AIS.Entity_Id)'

    print @SQL
    EXEC (@SQL)

--   and exists (select nfpagencies.Site_ID
--                     from dbo.Agencies nfpagencies
--                    where nfpagencies.Site_Id = Sites.SiteId);

----------------------------------------------------------------------------------------
print '  Cont: SP_Contacts_from_AgencyDB - Update record changes'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Staff'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL = 'update dbo.Contacts'
    +' Set [Site_ID] = AIS.[Site_ID]'
    +', [Full_Name] = AIS.[Full_Name]'
    +', [Last_Name] = AIS.[Last_Name]'
    +', [First_Name] = AIS.[First_Name]'
    +', [Middle_Name] = AIS.[Middle_Name]'
    +', [Prefix] = AIS.[Prefix]'
    +', [Suffix] = AIS.[Suffix]'
    +', [Entity_Type_ID] = AIS.[Entity_Type_ID]'
    +', [Entity_Type] = AIS.[Entity_Type]'
    +', [Entity_Subtype] = AIS.[Entity_Subtype]'
    +', [Entity_Subtype_ID] = AIS.[Entity_Subtype_ID]'
    +', [Program_ID] = AIS.[Program_ID]'
    +', [Address1] = AIS.[Address1]'
    +', [Address2] = AIS.[Address2]'
    +', [City] = AIS.[City]'
    +', [State] = AIS.[State]'
    +', [ZipCode] = AIS.[ZipCode]'
    +', [county] = AIS.[county]'
    +', [Email] = AIS.[Email]'
    +', [Phone1] = AIS.[Phone1]'
    +', [Supervised_By_ID] = AIS.[Supervised_By_ID]'
    +', [START_DATE] = AIS.[START_DATE]'
    +', [Termination_Date] = AIS.[Termination_Date]'
    +', [NHV_ID] = AIS.[NHV_ID]'
    +', [NURSE_0_ETHNICITY] = AIS.[NURSE_0_ETHNICITY]'
    +', [NURSE_1_RACE] = AIS.[NURSE_1_RACE]'
    +', [NURSE_1_RACE_0] = AIS.[NURSE_1_RACE_0]'
    +', [NURSE_1_RACE_1] = AIS.[NURSE_1_RACE_1]'
    +', [NURSE_1_RACE_2] = AIS.[NURSE_1_RACE_2]'
    +', [NURSE_1_RACE_3] = AIS.[NURSE_1_RACE_3]'
    +', [NURSE_1_RACE_4] = AIS.[NURSE_1_RACE_4]'
    +', [NURSE_1_RACE_5] = AIS.[NURSE_1_RACE_5]'
    +', [NURSE_0_GENDER] = AIS.[NURSE_0_GENDER]'
    +', [NURSE_0_YEAR_COMMHEALTH_EXPERIENCE] = AIS.[NURSE_0_YEAR_COMMHEALTH_EXPERIENCE]'
    +', [NURSE_0_YEAR_NURSING_EXPERIENCE] = AIS.[NURSE_0_YEAR_NURSING_EXPERIENCE]'
    +', [NURSE_0_YEAR_MATERNAL_EXPERIENCE] = AIS.[NURSE_0_YEAR_MATERNAL_EXPERIENCE]'
    +', [NURSE_0_FIRST_HOME_VISIT_DATE] = AIS.[NURSE_0_FIRST_HOME_VISIT_DATE]'
    +', [NURSE_0_LANGUAGE] = AIS.[NURSE_0_LANGUAGE]'
    +', [NURSE_0_YEAR_SUPERVISOR_EXPERIENCE] = AIS.[NURSE_0_YEAR_SUPERVISOR_EXPERIENCE]'
    +', [NURSE_0_BIRTH_YEAR] = AIS.[NURSE_0_BIRTH_YEAR]'
    +', [NURSE_0_ID_AGENCY] = AIS.[NURSE_0_ID_AGENCY]'
    +', [NURSE_0_PROGRAM_POSITION1] = AIS.[NURSE_0_PROGRAM_POSITION1]'
    +', [NURSE_0_PROGRAM_POSITION2] = AIS.[NURSE_0_PROGRAM_POSITION2]'
    +', [NURSE_PROFESSIONAL_1_REASON_HIRE] = AIS.[NURSE_PROFESSIONAL_1_REASON_HIRE]'
    +', [Date_Created] = AIS.[Date_Created]'
    +', [Audit_Date] = AIS.[Audit_Date]'
    +', [Contacts_Audit_Date] = AIS.[Contacts_Audit_Date]'
    +', [Audit_Staff_ID] = AIS.[Audit_Staff_ID]'
    +'
     from dbo.Contacts '
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.IA_Staff AIS'
    +' on Contacts.Source_Contact_ID = AIS.Entity_ID'
    +'
     where Contacts.Datasource = ''' +@p_datasource +''''
    +' and isnull(Contacts.Audit_Date,convert(datetime,''19700101'',112)) < AIS.Audit_Date'

    print @SQL
    --EXEC (@SQL)



----------------------------------------------------------------------------------------
print '  Cont: SP_Contacts_from_AgencyDB - Delete Contacts that no longer exist in AgencyDB'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Deleting ETO Deletions'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

/*
set @SQL =
    ' delete dbo.Contacts'
    +' from dbo.Contacts'
    +' where DataSource = @p_datasource'
    +' and not exists (select AIS.Entity_ID'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.IA_Staff AIS'
    +' where Entity_ID = Contacts.Source_Contact_ID)
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

print 'End of Process: SP_Contacts_from_AgencyDB'
GO
