USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_CONTACTS_FROM_IA_STAFF]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- dbo.SP_CONTACTS_FROM_IA_STAFF '[REM-DT1].DataWarehouse'

-- drop proc dbo.SP_CONTACTS_FROM_IA_STAFF
--
CREATE PROCEDURE [dbo].[SP_CONTACTS_FROM_IA_STAFF]
 (@p_remote_db       nvarchar(60) = null)
AS
--
-- This script controls updates to the DW tables: Contacts, Affiliates, Affiliate_Details
--   via the IA_Staff table.
--   ** This is a temporary process until the NSO Contact maintenance forms are in place.


-- dbo.Contacts Table:
--    This table will contain a single master contract record for an individual.  This will be entered 
--    via the DW form interfaces.  Once entered, the Contact_ID will be manually attached the ETO Entity 
--    record upon manual set-up into ETO.  This will identify the relationship between ETO and the DW.
--
-- dbo.Affiliates Table:
--    In ETO, secondary entity records will exist for a single individual, relating each to the unique 
--    site being logged into.  All entity records for a single individual will be related to the user's
--    ETO LoginID.  Using this ID, the master and secondary entity records will recorded into the 
--    Contact_Entites table to identify the individual sites a user has accessed, which will be a 
--    reference point for related survey responses by entity, back to one single Contact.
--
-- ** Only standard attributes may be maintained in ETO, such as name, phone, address.
--    All other attributes will be maintained via the DW form interfaces.
--
-- History:
--   20130510: New Procedure
--   20130731: Removed affiliates, affiliate_details
--             Added Contact_Addresses, Contact_Telephones.
--   20130923: Removed Address and Telephones from dbo.contacts.
--   20131025: Updates to add/remove specific columns.
--   20140926: Updated to receive a parameter for specific remote database instead of defaulting to the local db.
--             This will accommodate writing to a test database on a test instance.
--             Also changed the SQL scripts to a shel execution of the script.
--   20150120: Table amendment to accommodate historical tracking by rec_effective_date / rec_end_date.
--             New tables: dbo.COntacts for static data, dbo.Contact_Details for non-static data.


DECLARE @count		smallint
DECLARE @runtime 	datetime
DECLARE @Process	nvarchar(50)
set @process = 'SP_CONTACTS_FROM_IA_STAFF'

DECLARE @v_remote_db     varchar(60)
DECLARE @SQL             varchar(MAX)
DECLARE @SQL1            varchar(MAX)
DECLARE @SQL2            varchar(MAX)
DECLARE @SQL3            varchar(MAX)


set @runtime = getdate()
DECLARE @CRM_coursedate_cutover	datetime
set @CRM_coursedate_cutover = convert(datetime,'20101013',112)

IF @p_remote_db is not null
   set @v_remote_db = @p_remote_db +'.'
ELSE
   set @v_remote_Db = ''

print 'Starting: SP_CONTACTS_FROM_IA_STAFF'
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
print '  Cont: SP_CONTACTS_FROM_IA_STAFF - Insert New Contacts'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Inserting New Contact'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- first create a Contacts (Master static data record):

set @SQL1 = 'set nocount off '+
    +' insert into ' +@v_remote_db  +'dbo.contacts'
    +' (DataSource, DataSource_ID'
    +' ,[Full_Name]'
    +' ,[Last_Name]'
    +' ,[First_Name]'
    +' ,[Middle_Name]'
    +' ,[Prefix]'
    +' ,[Suffix]'
    +' ,[NURSE_0_ETHNICITY]'
    +' ,[NURSE_1_RACE]'
    +' ,[NURSE_1_RACE_0]'
    +' ,[NURSE_1_RACE_1]'
    +' ,[NURSE_1_RACE_2]'
    +' ,[NURSE_1_RACE_3]'
    +' ,[NURSE_1_RACE_4]'
    +' ,[NURSE_1_RACE_5]'
    +' ,[NURSE_0_GENDER]'
    +' ,[NURSE_0_BIRTH_YEAR]'
    +' ,[ETO_Disabled]'
    +' ,[CRM_ContactId]'
    +' ,[LMS_StudentID]'
    +' ,[ETO_LoginID]'
    +' ,[Last_CRM_Update]'
    +' ,[Last_LMS_Update]'
    +' ,[flag_update_LMS]'
    +' ,[flag_update_crm]'
    +' ,[flag_dont_push_to_CRM]'
    +' ,[flag_disregard_disabled]'
    +' ,[Date_Created]'
    +' ,[Audit_Date])'
set @SQL2 = '
    select isnull(IA_Staff.Datasource,''ETO'')'
    +' ,IA_Staff.entity_id'
    +' ,IA_Staff.[Full_Name]'
    +' ,IA_Staff.[Last_Name]'
    +' ,IA_Staff.[First_Name]'
    +' ,IA_Staff.[Middle_Name]'
    +' ,IA_Staff.[Prefix]'
    +' ,IA_Staff.[Suffix]'
    +' ,IA_Staff.[NURSE_0_ETHNICITY]'
    +' ,IA_Staff.[NURSE_1_RACE]'
    +' ,IA_Staff.[NURSE_1_RACE_0]'
    +' ,IA_Staff.[NURSE_1_RACE_1]'
    +' ,IA_Staff.[NURSE_1_RACE_2]'
    +' ,IA_Staff.[NURSE_1_RACE_3]'
    +' ,IA_Staff.[NURSE_1_RACE_4]'
    +' ,IA_Staff.[NURSE_1_RACE_5]'
    +' ,IA_Staff.[NURSE_0_GENDER]'
    +' ,IA_Staff.[NURSE_0_BIRTH_YEAR]'
    +' ,IA_Staff.[Disabled]'
    +' ,IA_Staff.[CRM_ContactId]'
    +' ,IA_Staff.[LMS_StudentID]'
    +' ,IA_Staff.[ETO_LoginID]'
    +' ,IA_Staff.[Last_CRM_Update]'
    +' ,IA_Staff.[Last_LMS_Update]'
    +' ,IA_Staff.[flag_update_LMS]'
    +' ,IA_Staff.[flag_update_crm]'
    +' ,IA_Staff.[flag_dont_push_to_CRM]'
    +' ,IA_Staff.[flag_disregard_disabled]'
    +' ,IA_Staff.Date_Created'
    +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
set @SQL2 = @SQL2 +'
    from dbo.IA_Staff'
-- don't write if Entity_ID or ETO_LoginID already exists:
    +' where not exists (select contact_id '
                       +'  from ' +@v_remote_db  +'dbo.contacts cid '
                       +' where cid.datasource_id = IA_Staff.Entity_ID '
                       +' and cid.datasource = isnull(IA_Staff.Datasource,''ETO'') )'
      +' and not exists (select contact_id '
                       +'  from ' +@v_remote_db  +'dbo.Contacts c1 '
                       +' where isnull(c1.ETO_LoginID,''999999998'') = isnull(IA_Staff.ETO_LoginID,''999999999'')) '

-- exclude specific people (nso staff and known exceptions):
--      +' and IA_Staff.Full_Name not in '
--      +'     (select lov_item from dbo.view_lov where name=''SP_CONTACTS_FROM_IA_STAFF_NAME_EXCLUSION'')'

  --and IA_Staff.Entity_Subtype != 'Staff'
    +'  and IA_Staff.CRM_ContactId is not null'

    print @SQL1
    print @SQL2
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar)
       +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar) 

    EXEC (@SQL1+@SQL2)


set @SQL1 = 'set nocount off '+
    +' insert into ' +@v_remote_db  +'dbo.contact_Details'
    +' ([Contact_ID]'
    +' ,Rec_Effective_date'
    +' ,Rec_End_date'
    +' ,[Site_ID]'
    +' ,[Program_ID]'
    +' ,[Email]'
    +' ,[Supervised_By_ID]'
    +' ,[Start_Date]'
    +' ,[Termination_Date]'
    +' ,[NHV_ID]'
    +' ,[NURSE_0_YEAR_COMMHEALTH_EXPERIENCE]'
    +' ,[NURSE_0_YEAR_NURSING_EXPERIENCE]'
    +' ,[NURSE_0_YEAR_MATERNAL_EXPERIENCE]'
    +' ,[NURSE_0_FIRST_HOME_VISIT_DATE]'
    +' ,[NURSE_0_LANGUAGE]'
    +' ,[NURSE_0_YEAR_SUPERVISOR_EXPERIENCE]'
    +' ,[NURSE_0_ID_AGENCY]'
    +' ,[NURSE_0_PROGRAM_POSITION1]'
    +' ,[NURSE_0_PROGRAM_POSITION2]'
    +' ,[NURSE_PROFESSIONAL_1_REASON_HIRE]'
    +' ,[Date_Created]'
    +' ,[Audit_Date]'
    +' ,[Audit_Staff_ID])'
set @SQL2 = '
      select cid.Contact_ID'
    +' ,IA_Staff.[Audit_Date]'               -- Rec_Effective_date'
    +' ,convert(datetime,''99991231'',112)'  -- Rec_End_date'
    +' ,IA_Staff.[Site_ID]'
    +' ,IA_Staff.[Program_ID]'
    +' ,IA_Staff.[Email]'
    +' ,IA_Staff.[Supervised_By_ID]'
    +' ,IA_Staff.[START_DATE]'
    +' ,IA_Staff.[Termination_Date]'
    +' ,IA_Staff.[NHV_ID]'
    +' ,IA_Staff.[NURSE_0_YEAR_COMMHEALTH_EXPERIENCE]'
    +' ,IA_Staff.[NURSE_0_YEAR_NURSING_EXPERIENCE]'
    +' ,IA_Staff.[NURSE_0_YEAR_MATERNAL_EXPERIENCE]'
    +' ,IA_Staff.[NURSE_0_FIRST_HOME_VISIT_DATE]'
    +' ,IA_Staff.[NURSE_0_LANGUAGE]'
    +' ,IA_Staff.[NURSE_0_YEAR_SUPERVISOR_EXPERIENCE]'
    +' ,IA_Staff.[NURSE_0_ID_AGENCY]'
    +' ,IA_Staff.[NURSE_0_PROGRAM_POSITION1]'
    +' ,IA_Staff.[NURSE_0_PROGRAM_POSITION2]'
    +' ,IA_Staff.[NURSE_PROFESSIONAL_1_REASON_HIRE]'
    +' ,IA_Staff.[Date_Created]'
    +' ,IA_Staff.[Audit_Date]'
    +' ,IA_Staff.[Audit_Staff_ID]'
set @SQL3 = '
      from dbo.IA_Staff'
    +' inner join ' +@v_remote_db  +'dbo.contacts cid '
          +' on IA_Staff.Entity_ID = cid.DataSource_ID'
          +' and isnull(IA_Staff.Datasource,''ETO'') = cid.Datasource'
--  don't write if contaxt already exists:
    +' where not exists (select contact_id '
                       +'  from ' +@v_remote_db  +'dbo.contact_details c1 '
                       +' where c1.contact_id = cid.contact_id) '

    print @SQL1
    print @SQL2
    print @SQL3
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar)
       +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar) 
       +', SQL3 Length = ' +CAST(LEN(@SQL3) as varchar)

    EXEC (@SQL1+@SQL2+@SQL3)



----------------------------------------------------------------------------------------
print '  Cont: SP_CONTACTS_FROM_IA_STAFF - Update staff Contacts Changes'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Contact Info'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off '+
  ' update ' +@v_remote_db  +'dbo.Contacts'
    +' set Contacts.[Full_Name] = IA_Staff.[Full_Name]'
       +' ,Contacts.[Last_Name] = IA_Staff.[Last_Name]'
       +' ,Contacts.[First_Name] = IA_Staff.[First_Name]'
       +' ,Contacts.[Middle_Name] = IA_Staff.[Middle_Name]'
       +' ,Contacts.[Prefix] = IA_Staff.[Prefix]'
       +' ,Contacts.[Suffix] = IA_Staff.[Suffix]'
       +' ,Contacts.[NURSE_0_ETHNICITY] = IA_Staff.[NURSE_0_ETHNICITY]'
       +' ,Contacts.[NURSE_1_RACE] = IA_Staff.[NURSE_1_RACE]'
       +' ,Contacts.[NURSE_1_RACE_0] = IA_Staff.[NURSE_1_RACE_0]'
       +' ,Contacts.[NURSE_1_RACE_1] = IA_Staff.[NURSE_1_RACE_1]'
       +' ,Contacts.[NURSE_1_RACE_2] = IA_Staff.[NURSE_1_RACE_2]'
       +' ,Contacts.[NURSE_1_RACE_3] = IA_Staff.[NURSE_1_RACE_3]'
       +' ,Contacts.[NURSE_1_RACE_4] = IA_Staff.[NURSE_1_RACE_4]'
       +' ,Contacts.[NURSE_1_RACE_5] = IA_Staff.[NURSE_1_RACE_5]'
       +' ,Contacts.[NURSE_0_GENDER] = IA_Staff.[NURSE_0_GENDER]'
       +' ,Contacts.[NURSE_0_BIRTH_YEAR] = IA_Staff.[NURSE_0_BIRTH_YEAR]'
       +' ,Contacts.[Date_Created] = IA_Staff.[Date_Created]'
       +' ,Contacts.[Audit_Date] = IA_Staff.[Audit_Date]'
       +' ,Contacts.[ETO_Disabled] = IA_Staff.[Disabled]'
       +' ,Contacts.[CRM_ContactId] = IA_Staff.[CRM_ContactId]'
       +' ,Contacts.[LMS_StudentID] = IA_Staff.[LMS_StudentID]'
       +' ,Contacts.[ETO_LoginID] = IA_Staff.[ETO_LoginID]'
       +' ,Contacts.[Last_CRM_Update] = IA_Staff.[Last_CRM_Update]'
       +' ,Contacts.[Last_LMS_Update] = IA_Staff.[Last_LMS_Update]'
       +' ,Contacts.[flag_update_LMS] = IA_Staff.[flag_update_LMS]'
       +' ,Contacts.[flag_update_crm] = IA_Staff.[flag_update_crm]'
       +' ,Contacts.[flag_dont_push_to_CRM] = IA_Staff.[flag_dont_push_to_CRM]'
       +' ,Contacts.[flag_disregard_disabled] = IA_Staff.[flag_disregard_disabled]'
set @SQL2 = '
    from ' +@v_remote_db  +'dbo.Contacts'
+' inner join dbo. IA_Staff on Contacts.DataSource_ID = IA_Staff.Entity_ID'
     +' and Contacts.DataSource = IA_Staff.DataSource'
+'  where isnull(IA_Staff.Audit_Date,convert(datetime,''19700101'',112)) > '
      +'  isnull(Contacts.Audit_Date,convert(datetime,''19691231'',112))'

    print @SQL1
    print @SQL2
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar)
       +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar) 

    EXEC (@SQL1+@SQL2)




----------------------------------------------------------------------------------------
print '  Cont: SP_CONTACTS_FROM_IA_STAFF - Update staff Contact_Details Changes'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Contact Info'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off '+
  ' update ' +@v_remote_db  +'dbo.Contact_Details'
    +' set Rec_Effective_Date = IA_Staff.[Audit_Date]' 
       +' ,CDTL.[Site_ID] = IA_Staff.[Site_ID]'
       +' ,CDTL.[Program_ID] = IA_Staff.[Program_ID]'
       +' ,CDTL.[Email] = IA_Staff.[Email]'
       +' ,CDTL.[Supervised_By_ID] = IA_Staff.[Supervised_By_ID]'
       +' ,CDTL.[START_DATE] = IA_Staff.[START_DATE]'
       +' ,CDTL.[Termination_Date] = IA_Staff.[Termination_Date]'
       +' ,CDTL.[NHV_ID] = IA_Staff.[NHV_ID]'
       +' ,CDTL.[NURSE_0_YEAR_COMMHEALTH_EXPERIENCE] = IA_Staff.[NURSE_0_YEAR_COMMHEALTH_EXPERIENCE]'
       +' ,CDTL.[NURSE_0_YEAR_NURSING_EXPERIENCE] = IA_Staff.[NURSE_0_YEAR_NURSING_EXPERIENCE]'
       +' ,CDTL.[NURSE_0_YEAR_MATERNAL_EXPERIENCE] = IA_Staff.[NURSE_0_YEAR_MATERNAL_EXPERIENCE]'
       +' ,CDTL.[NURSE_0_FIRST_HOME_VISIT_DATE] = IA_Staff.[NURSE_0_FIRST_HOME_VISIT_DATE]'
       +' ,CDTL.[NURSE_0_LANGUAGE] = IA_Staff.[NURSE_0_LANGUAGE]'
       +' ,CDTL.[NURSE_0_YEAR_SUPERVISOR_EXPERIENCE] = IA_Staff.[NURSE_0_YEAR_SUPERVISOR_EXPERIENCE]'
       +' ,CDTL.[NURSE_0_ID_AGENCY] = IA_Staff.[NURSE_0_ID_AGENCY]'
       +' ,CDTL.[NURSE_0_PROGRAM_POSITION1] = IA_Staff.[NURSE_0_PROGRAM_POSITION1]'
       +' ,CDTL.[NURSE_0_PROGRAM_POSITION2] = IA_Staff.[NURSE_0_PROGRAM_POSITION2]'
       +' ,CDTL.[NURSE_PROFESSIONAL_1_REASON_HIRE] = IA_Staff.[NURSE_PROFESSIONAL_1_REASON_HIRE]'
       +' ,CDTL.[Date_Created] = IA_Staff.[Date_Created]'
       +' ,CDTL.[Audit_Date] = IA_Staff.[Audit_Date]'
set @SQL2 = '
    from ' +@v_remote_db  +'dbo.Contacts'
+' inner join ' +@v_remote_db  +'dbo.Contact_Details CDTL on Contacts.Contact_ID = CDTL.Contact_ID'
     +' and CDTL.Rec_End_Date = convert(datetime,''99991231'',112)'
+' inner join dbo. IA_Staff on Contacts.DataSource_ID = IA_Staff.Entity_ID'
     +' and Contacts.DataSource = IA_Staff.DataSource'
+'  where isnull(IA_Staff.Audit_Date,convert(datetime,''19700101'',112)) > '
      +'  isnull(Contacts.Audit_Date,convert(datetime,''19691231'',112))'


    print @SQL1
    print @SQL2
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar)
       +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar) 

    EXEC (@SQL1+@SQL2)



----------------------------------------------------------------------------------------

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing Addresses'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------
 
print '  Cont: SP_CONTACTS_FROM_IA_STAFF - Adding Address Records'

set @SQL1 = 'set nocount off '+
 ' insert into ' +@v_remote_db  +'dbo.Contact_Addresses'
    +' (Contact_ID,Address_type,Rec_Effective_Date, Rec_End_Date, Address1,Address2,City,State,ZipCode'
    +' ,county,Phone1,Phone2,Phone3,Fax,Audit_Date)'
+' select Contacts.Contact_ID'
      +' ,LOVV.LOV_Item'
      +' ,IA_Staff.[Audit_Date]'               -- Rec_Effective_date'
      +' ,convert(datetime,''99991231'',112)'  --Rec_End_date'
      +' ,IA_Staff.Address1'
      +' ,IA_Staff.Address2'
      +' ,IA_Staff.City'
      +' ,IA_Staff.State'
      +' ,IA_Staff.ZipCode'
      +' ,IA_Staff.county'
      +' ,IA_Staff.Phone1'
      +' ,null as phone2, null as phone3, null as fax'
      +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
  +' from ' +@v_remote_db  +'dbo.Contacts'
  +' inner join dbo.IA_Staff on Contacts.DataSource_ID = IA_Staff.Entity_ID'
  +' and Contacts.DataSource = isnull(IA_Staff.DataSource,''ETO'')'
  +' join dbo.LOV_Names LOVN ON LOVN.Name = ''ADDRESS_TYPE'''
  +' inner join dbo.LOV_Values LOVV on LOVV.LOV_Name_ID = LOVN.LOV_Name_ID'
  +'  and LOVV.Value = ''PRIMARY'''
  +' where not exists (select rec_id'
                      +' from ' +@v_remote_db  +'dbo.Contact_Addresses '
                     +' where Contact_Addresses.contact_id = contacts.Contact_ID'
                       +' and Contact_Addresses.Address_type = LOVV.LOV_Item)'

    print @SQL1
    EXEC (@SQL1)


print '  Cont: SP_CONTACTS_FROM_IA_STAFF - Updating Address Records'

set @SQL1 = 'set nocount off '+
' update ' +@v_remote_db  +'dbo.Contact_Addresses'
  +' set Address1 = IA_Staff.Address1'
     +' ,Address2 = IA_Staff.Address2'
     +' ,City = IA_Staff.City'
     +' ,State = IA_Staff.State'
     +' ,ZipCode = IA_Staff.ZipCode'
     +' ,county = IA_Staff.county'
     +' ,Phone1 = IA_Staff.Phone1'
     +' ,Audit_date = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
 +' from ' +@v_remote_db  +'dbo.Contact_Addresses CA'
 +' inner join ' +@v_remote_db  +'dbo.Contacts on CA.Contact_ID = Contacts.Contact_Id'
 +' inner join dbo.IA_Staff'
    +' on Contacts.DataSource_ID = IA_Staff.Entity_ID'
    +' and Contacts.DataSource = isnull(IA_Staff.DataSource,''ETO'')'
 +' join dbo.LOV_Names LOVN ON LOVN.Name = ''ADDRESS_TYPE'''
 +' inner join dbo.LOV_Values LOVV on LOVV.LOV_Name_ID = LOVN.LOV_Name_ID'
        +' and LOVV.Value = ''PRIMARY'''
+' where CA.Address_type = LOVV.LOV_Item'
  +' and ((isnull(CA.Address1,''xyz1234'') != isnull(IA_Staff.Address1,''xyz1234'') or'
        +' isnull(CA.Address2,''xyz1234'') != isnull(IA_Staff.Address2,''xyz1234'') or'
        +' isnull(CA.City,''xyz1234'') != isnull(IA_Staff.City,''xyz1234'') or'
        +' isnull(CA.State,''zz'') != isnull(IA_Staff.State,''zz'') or'
        +' isnull(CA.ZipCode,''xyz1234'') != isnull(IA_Staff.ZipCode,''xyz1234'') or'
        +' isnull(CA.county,''xyz1234'') != isnull(IA_Staff.county,''xyz1234'') or'
        +' isnull(CA.Phone1,''xyz1234'') != isnull(IA_Staff.Phone1,''xyz1234''))'
        +' or CA.Audit_Date is null)'

    print @SQL1
    EXEC (@SQL1)

----------------------------------------------------------------------------------------

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing Telephones'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

print '  Cont: SP_CONTACTS_FROM_IA_STAFF - Adding Telephone Records'

set @SQL1 = 'set nocount off '+
' insert into ' +@v_remote_db  +'dbo.Contact_Telephones'
    +'  (Contact_ID, Telephone_type, Rec_Effective_Date, Rec_End_Date, Telephone,Audit_Date)'
+' select Contacts.Contact_ID'
      +' ,LOVV.LOV_Item'
      +', IA_Staff.[Audit_Date]'               -- Rec_Effective_date'
      +', convert(datetime,''99991231'',112)'  --Rec_End_date'
      +' ,IA_Staff.Phone1'
      +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
 +' from ' +@v_remote_db  +'dbo.Contacts'
 +' inner join ' +@v_remote_db  +'dbo.IA_Staff'
   +' on Contacts.DataSource_ID = IA_Staff.Entity_ID'
   +' and Contacts.DataSource = isnull(IA_Staff.DataSource,''ETO'')'
 +' join dbo.LOV_Names LOVN ON LOVN.Name = ''TELEPHONE_TYPE'''
 +' inner join dbo.LOV_Values LOVV on LOVV.LOV_Name_ID = LOVN.LOV_Name_ID'
   +' and LOVV.Value = ''PRIMARY'''
+' where not exists (select Rec_id'
                    +' from ' +@v_remote_db  +'dbo.Contact_Telephones '
                   +' where Contact_Telephones.contact_id = Contacts.Contact_ID'
                     +' and Contact_Telephones.Telephone_type = LOVV.LOV_Item)'

    print @SQL1
    EXEC (@SQL1)


print '  Cont: SP_CONTACTS_FROM_IA_STAFF - Updating Phone Records'

set @SQL1 = 'set nocount off '+
' update ' +@v_remote_db  +'dbo.Contact_Telephones'
  +' set Telephone = IA_Staff.Phone1'
     +' ,Audit_date = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
 +' from ' +@v_remote_db  +'dbo.Contact_Telephones CT'
 +' inner join ' +@v_remote_db  +'dbo.Contacts on CT.Contact_ID = Contacts.Contact_Id'
 +' inner join dbo.IA_Staff'
   +' on Contacts.DataSource_ID = IA_Staff.Entity_ID'
   +' and Contacts.DataSource = isnull(IA_Staff.DataSource,''ETO'')'
 +' join dbo.LOV_Names LOVN ON LOVN.Name = ''TELEPHONE_TYPE'''
 +' inner join dbo.LOV_Values LOVV on LOVV.LOV_Name_ID = LOVN.LOV_Name_ID'
   +' and LOVV.Value = ''PRIMARY'''
+' where CT.Telephone_type = LOVV.LOV_Item'
 +'  and (isnull(CT.Telephone,''xyz1234'') != isnull(IA_Staff.phone1,''xyz1234'')'
      +' or CT.Audit_Date is null)'

    print @SQL1
    EXEC (@SQL1)

----------------------------------------------------------------------------------------
-- update disabled ETO entities becuase the disabled flag does not trigger an Audit Date
----------------------------------------------------------------------------------------
/*  commented section:
update Contacts
   set Disabled = 1
from Contacts 
 where Entity_id in
 (select Entityid
  from dbo.Contacts
  inner join ETOSRVR.etosolaris.dbo.Entities
     on Entities.EntityID = Contacts.Entity_Id
 where Entities.Disabled = 1
   and Contacts.Disabled = 0)

update Contacts
   set Disabled = 0
from Contacts 
 where Entity_id in
 (select Entityid
  from dbo.Contacts
  inner join ETOSRVR.etosolaris.dbo.Entities
     on Entities.EntityID = Contacts.Entity_Id
 where Entities.Disabled = 0
   and Contacts.Disabled = 1)
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

print 'End of Process: SP_CONTACTS_FROM_IA_STAFF'
GO
