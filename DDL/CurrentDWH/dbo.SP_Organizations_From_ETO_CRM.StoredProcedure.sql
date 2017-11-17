USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_Organizations_From_ETO_CRM]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_Organizations_From_ETO_CRM
--
CREATE PROCEDURE [dbo].[SP_Organizations_From_ETO_CRM]
 (@p_remote_db       nvarchar(60) = null)
AS
--
-- This script controls updates to the dbo.Organizations table in the Data Warehouse.
-- Processing ETO via dbo.Agencies, dbo.Teams, 
--            CRM via AccountBase, AccountExtensionBase, CustomerAddressBase
--
-- Database Links:
-- CRM: CRMsrvr.Nurse_FamilyPartnership_MSCRM 

-- History:
--   20130724 - New Procedure.
--   20130809 - Added Teams to the organizations.
--   20130923 - Excluded Teams, which are not being recorded in the WorkGroups Tables.
--              Removed address/phone fields from the Organizations table, held in addressess/telephones.
--              Changed ORG_Type_LOV to reference LOV.ETO_xref, and to store LOV_Item instead of index.
--   20140926: Updated to receive a parameter for specific remote database instead of defaulting to the local db.
--             This will accommodate writing to a test database on a test instance.
--             Also changed the SQL scripts to a shel execution of the script.


DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_Organizations_From_ETO_CRM'

DECLARE @v_remote_db     varchar(60)
DECLARE @SQL             varchar(MAX)
DECLARE @SQL1            varchar(MAX)
DECLARE @SQL2            varchar(MAX)
DECLARE @SQL3            varchar(MAX)

DECLARE @CRM_coursedate_cutover	datetime
set @CRM_coursedate_cutover = convert(datetime,'20101013',112)

IF @p_remote_db is not null
   set @v_remote_db = @p_remote_db +'.'
ELSE
   set @v_remote_Db = ''


print 'Starting: SP_Organizations_From_ETO_CRM'

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
----------------------------------------------------------------------------------------
print ' '
print 'Processing SP_Organizations_From_ETO_CRM - Processing Organizations from DW.Agencies'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Organizations from DW Agencies'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off '+
' insert into ' +@v_remote_db  +'dbo.Organizations'
 +' (DataSource'
 +' ,Source_Entity_ID'
 +' ,Full_NAME'
 +' ,Program_NAME'
 +' ,Org_Type_LOV'
 +' ,Org_Status_LOV'
 +' ,Email'
 +' ,Website '
 +' ,LOWINCOME_Criteria'
 +' ,LOWINCOME_Percent'
 +' ,LOWINCOME_Description '
 +' ,Initiation_Date'
 +' ,Date_First_Home_Visit'
 +' ,PPPL_Effective_Date'
 +' ,PPPL_Expiration_Date'
 +' ,Mileage_Rate '
 +' ,Service_Level_Covered_ID'
 +' ,Population_Served '
 +' ,Nbr_Billable_Teams'
 +' ,Initial_Agreement_Effective_Date'
 +' ,Initial_Agreement_Sign_Date'
 +' ,Initial_Agreement_Term_Date'
 +' ,Date_Created'
 +' ,Audit_Date'
 +' ,Entity_Disabled '
 +' ,CRM_AccountId '
 +' ,CRM_ID '
 +' ,LMS_OrganizationID '
 +' ,Last_CRM_Update'
 +' ,Last_LMS_Update'
 +' ,flag_update_LMS'
 +' ,flag_update_crm)'
--
set @SQL2 = '
 select isnull(Agencies.DataSource,''ETO'') as datasource'
     +' ,Agencies.Entity_ID'
     +' ,Agencies.AGENCY_INFO_0_NAME'
     +' ,null as program_name'
     +' ,LOVV.LOV_Item as Org_Type_LOV'
     +' ,null as Org_status_LOV'
     +' ,null as email'
     +' ,Agencies.AGENCY_INFO_1_WEBSITE'
     +' ,Agencies.AGENCY_INFO_1_LOWINCOME_CRITERA'
     +' ,Agencies.AGENCY_INFO_1_LOWINCOME_PERCENT'
     +' ,Agencies.AGENCY_INFO_1_LOWINCOME_DESCRIPTION'
     +' ,Agencies.AGENCY_INFO_1_INITIATION_DATE'
     +' ,Agencies.AGENCY_DATE_FIRST_HOME_VISIT'
     +' ,null as PPPL_Effective_Date'
     +' ,null as PPPL_Expiration_Date'
     +' ,Agencies.AGENCY_INFO_1_MILEAGE_RATE'
     +' ,null as Service_Level_Covered_ID'
     +' ,null as Population_Served '
     +' ,null as Nbr_Billable_Teams'
     +' ,null as Initial_Agreement_Effective_Date'
     +' ,null as Initial_Agreement_Sign_Date'
     +' ,null as Initial_Agreement_Term_Date'
     +' ,Agencies.Date_Created'
     +' ,Agencies.Audit_Date'
     +' ,Agencies.Entity_Disabled'
     +' ,Agencies.CRM_AccountId'
     +' ,Agencies.CRM_ID'
     +' ,Agencies.LMS_OrganizationID'
     +' ,Agencies.Last_CRM_Update'
     +' ,Agencies.Last_LMS_Update'
     +' ,Agencies.flag_update_LMS'
     +' ,Agencies.flag_update_crm'
+' from dbo.agencies'
+' left join dbo.view_LOV LOVV '
     +' on LOVV.Name = ''ORG_TYPE'''
     +' and LOVV.ETO_Xref = convert(char,Agencies.Entity_Type_ID)'
+' where not exists (select Org_ID '
                    +' from ' +@v_remote_db  +'dbo.Organizations org'
                   +' where org.datasource = isnull(Agencies.DataSource,''ETO'')'
                     +' and org.Source_Entity_ID = Agencies.Entity_ID)'

    print @SQL1
    print @SQL2
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar)
       +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar) 

    EXEC (@SQL1+@SQL2)


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Organizations from DW Agencies'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off '+
' update ' +@v_remote_db  +'dbo.Organizations'
  +' set Full_NAME = Agencies.AGENCY_INFO_0_NAME'
     +' ,Org_Type_LOV = LOVV.LOV_Item'
     --+',Org_Status_LOV = '
     --+',Email = '
     +' ,Website = Agencies.AGENCY_INFO_1_WEBSITE'
     +' ,LOWINCOME_Criteria = Agencies.AGENCY_INFO_1_LOWINCOME_CRITERA'
     +' ,LOWINCOME_Percent = Agencies.AGENCY_INFO_1_LOWINCOME_PERCENT'
     +' ,LOWINCOME_Description = Agencies.AGENCY_INFO_1_LOWINCOME_DESCRIPTION'
     +' ,Initiation_Date = Agencies.AGENCY_INFO_1_INITIATION_DATE'
     +' ,Date_First_Home_Visit = Agencies.AGENCY_DATE_FIRST_HOME_VISIT'
      --+',PPPL_Effective_Date = '
      --+',PPPL_Expiration_Date = '
     +' ,Mileage_Rate  = Agencies.AGENCY_INFO_1_MILEAGE_RATE'
      --+',Service_Level_Covered_ID = '
      --+',Population_Served = '
      --+',Nbr_Billable_Teams = '
      --+',Agreement_Effective_Date = '
      --+',Initial_Agreement_Sign_Date = '
      --+',Initial_Agreement_Term_Date = '
     +',Date_Created = Agencies.Date_Created'
     +' ,Audit_Date = Agencies.Audit_Date'
     +' ,Entity_Disabled = Agencies.Entity_Disabled'
     +' ,CRM_AccountId = Agencies.CRM_AccountId'
     +' ,CRM_ID  = Agencies.CRM_ID'
     +' ,LMS_OrganizationID = Agencies.LMS_OrganizationID'
     +' ,Last_CRM_Update = Agencies.Last_CRM_Update'
     +' ,Last_LMS_Update = Agencies.Last_LMS_Update'
     +' ,flag_update_LMS = Agencies.flag_update_LMS'
     +' ,flag_update_crm = Agencies.flag_update_crm'
+' from ' +@v_remote_db  +'dbo.Organizations'
+' inner join dbo.Agencies on organizations.Source_Entity_ID = Agencies.Entity_ID'
       +' and organizations.DataSource = isnull(Agencies.Datasource,''ETO'')'
+' left join dbo.view_LOV LOVV '
      +' on LOVV.Name = ''ORG_TYPE'''
     +' and LOVV.ETO_Xref = convert(char,Agencies.Entity_Type_ID)'
     +' and LOVV.ETO_Xref = convert(char,Agencies.Entity_Type_ID)'
+' where isnull(Organizations.Audit_Date,convert(datetime,''19700101'',112)) '
      +' < isnull(Agencies.Audit_Date,convert(datetime,''19700101'',112))'

    print @SQL1
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar)

    EXEC (@SQL1)

----------------------------------------------------------------------------------------
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing ETO Addresses from DW Agencies'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------
 
print '  Cont: SP_Organizations_From_ETO_CRM - Adding ETO Address Records'

set @SQL1 = 'set nocount off '+
' insert into ' +@v_remote_db  +'dbo.Organization_Addresses'
      +' (Org_ID,Address_type,Address1,Address2,City,State,ZipCode'
      +' ,county,Audit_Date)'
+' select Organizations.Org_ID'
      +' ,LOVV.LOV_Item'
      +' ,Agencies.Address1'
      +' ,Agencies.Address2'
      +' ,Agencies.City'
      +' ,Agencies.State'
      +' ,Agencies.ZipCode'
      +' ,Agencies.county'
      +' ,getdate()'
+' from ' +@v_remote_db  +'dbo.Organizations'
+' inner join dbo.Agencies'
   +' on Organizations.Source_Entity_ID = Agencies.Entity_ID'
+' join dbo.LOV_Names LOVN ON LOVN.Name = ''ADDRESS_TYPE'''
+' inner join dbo.LOV_Values LOVV on LOVV.LOV_Name_ID = LOVN.LOV_Name_ID'
   +' and LOVV.Value = ''PRIMARY'''
+' where organizations.datasource = ''ETO'''
  +' and not exists (select Org_Address_id'
                    +' from ' +@v_remote_db  +'dbo.Organization_Addresses '
                    +' where Organization_Addresses.Org_ID = Organizations.Org_ID'
                      +' and Organization_Addresses.Address_type = LOVV.LOV_Item)'

    print @SQL1
    EXEC (@SQL1)


print '  Cont: SP_Organizations_From_ETO_CRM - Updating ETO Address Records'

set @SQL1 = 'set nocount off '+
' update ' +@v_remote_db  +'dbo.Organization_Addresses'
   +' set Address1 = Agencies.Address1'
     +' ,Address2 = Agencies.Address2'
     +' ,City = Agencies.City'
     +' ,State = Agencies.State'
     +' ,ZipCode = Agencies.ZipCode'
     +' ,county = Agencies.county'
     +' ,AUdit_Date = getdate()'
+' from ' +@v_remote_db  +'dbo.Organization_Addresses OA'
+' inner join ' +@v_remote_db  +'dbo.Organizations on OA.Org_ID = Organizations.Org_ID'
+' inner join dbo.Agencies'
   +' on Organizations.Source_Entity_ID = Agencies.Entity_ID'
+' join dbo.LOV_Names LOVN ON LOVN.Name = ''ADDRESS_TYPE'''
+' inner join dbo.LOV_Values LOVV on LOVV.LOV_Name_ID = LOVN.LOV_Name_ID'
      +' and LOVV.Value = ''PRIMARY'''
+' where organizations.datasource = ''ETO'''
  +' and OA.Address_type = LOVV.LOV_Item'
  +' and ((isnull(OA.Address1,''xyz1234'') != isnull(Agencies.Address1,''xyz1234'') or'
        +' isnull(OA.Address2,''xyz1234'') != isnull(Agencies.Address2,''xyz1234'') or'
        +' isnull(OA.City,''xyz1234'') != isnull(Agencies.City,''xyz1234'') or'
        +' isnull(OA.State,''zz'') != isnull(Agencies.State,''zz'') or'
        +' isnull(OA.ZipCode,''xyz1234'') != isnull(Agencies.ZipCode,''xyz1234'') or'
        +' isnull(OA.county,''xyz1234'') != isnull(Agencies.county,''xyz1234''))'
       +' or OA.Audit_Date is null)'

    print @SQL1
    EXEC (@SQL1)

----------------------------------------------------------------------------------------
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing ETO Telephones DW Agencies'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

print '  Cont: SP_Organizations_From_ETO_CRM - Adding ETO Telephone Records'

set @SQL1 = 'set nocount off '+
' insert into ' +@v_remote_db  +'dbo.Organization_Telephones'
      +' (Org_ID,Telephone_type,Telephone,Audit_Date)'
+' select Organizations.Org_ID'
      +' ,LOVV.LOV_Item'
      +' ,Agencies.Phone1'
      +' ,getdate()'
+' from ' +@v_remote_db  +'dbo.Organizations'
+' inner join dbo.Agencies'
  +'  on Organizations.Source_Entity_ID = Agencies.Entity_ID'
+' join dbo.LOV_Names LOVN ON LOVN.Name = ''TELEPHONE_TYPE'''
+' inner join dbo.LOV_Values LOVV on LOVV.LOV_Name_ID = LOVN.LOV_Name_ID'
      +' and LOVV.Value = ''PRIMARY'''
+' where Organizations.Datasource = ''ETO'''
  +' and not exists (select Org_Telephone_id'
                    +' from ' +@v_remote_db  +'dbo.Organization_Telephones '
                   +' where Organization_Telephones.Org_ID = Organizations.Org_ID'
                     +' and Organization_Telephones.Telephone_type = LOVV.LOV_Item)'

    print @SQL1
    EXEC (@SQL1)


print '  Cont: SP_Organizations_From_ETO_CRM - Updating ETO Phone Records'

set @SQL1 = 'set nocount off '+
' update ' +@v_remote_db  +'dbo.Organization_Telephones'
 +' set Telephone = Agencies.Phone1'
    +' ,Audit_Date = getdate()'
+' from ' +@v_remote_db  +'dbo.Organization_Telephones OT'
+' inner join ' +@v_remote_db  +'dbo.Organizations on OT.Org_ID = Organizations.Org_ID'
+' inner join dbo.Agencies'
   +' on Organizations.Source_Entity_ID = Agencies.Entity_ID'
+' join dbo.LOV_Names LOVN ON LOVN.Name = ''TELEPHONE_TYPE'''
+' inner join dbo.LOV_Values LOVV on LOVV.LOV_Name_ID = LOVN.LOV_Name_ID'
      +' and LOVV.Value = ''PRIMARY'''
+' where Organizations.Datasource = ''ETO'''
  +' and OT.Telephone_type = LOVV.LOV_Item'
  +' and (isnull(OT.Telephone,''xyz1234'') != isnull(Agencies.phone1,''xyz1234'')'
       +' or OT.Audit_Date is null)'

    print @SQL1
    EXEC (@SQL1)


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
print ' '
print 'Processing SP_Organizations_From_ETO_CRM - Organizations from CRM'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Organizations from CRM'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off '+
' insert into ' +@v_remote_db  +'dbo.Organizations'
    +' (DataSource'
    +' ,Source_Entity_ID'
    +' ,Full_NAME'
    +' ,Program_NAME'
    +' ,Org_Type_LOV'
    +' ,Org_Status_LOV'
    +' ,Email'
    +' ,Website '
    +' ,LOWINCOME_Criteria'
    +' ,LOWINCOME_Percent'
    +' ,LOWINCOME_Description '
    +' ,Initiation_Date'
    +' ,Date_First_Home_Visit'
    +' ,PPPL_Effective_Date'
    +' ,PPPL_Expiration_Date'
    +' ,Mileage_Rate '
    +' ,Service_Level_Covered_ID'
    +' ,Population_Served '
    +' ,Nbr_Billable_Teams'
    +' ,Initial_Agreement_Effective_Date'
    +' ,Initial_Agreement_Sign_Date'
    +' ,Initial_Agreement_Term_Date'
    +' ,Date_Created'
    +' ,Audit_Date'
    +' ,Entity_Disabled '
    +' ,CRM_AccountId '
    +' ,CRM_ID '
    +' ,LMS_OrganizationID)'
--
set @SQL2 = '
  select ''CRM'' as DataSource'
     +' ,null as Source_Entity_ID'
     +' ,AB.Name as Full_NAME'
     +' ,AXB.New_ProgramName as Program_NAME'
     +' ,OrgLOV.lov_item as Org_Type_LOV'
     +' ,AB.StatusCode as Org_Status_LOV'
     +' ,AB.EmailAddress1 as Email'
     +' ,AB.WebSiteURL as Website '
     +' ,null as LOWINCOME_Criteria'
     +' ,null as LOWINCOME_Percent'
     +' ,null as LOWINCOME_Description '
     +' ,null as Initiation_Date'
     +' ,AXB.New_DateofFirstHomeVisit as Date_First_Home_Visit'
     +' ,AXB.New_PPPL_EffectiveDate as PPPL_Effective_Date'
     +' ,AXB.New_PPPLExpirationDate as PPPL_Expiration_Date'
     +' ,null as Mileage_Rate '
     +' ,null as Service_Level_Covered_ID'
     +' ,null as Population_Served '
     +' ,AXB.New_NumberBillableTeams as Nbr_Billable_Teams'
     +' ,AXB.New_AgreementEffectiveDate as Initial_Agreement_Effective_Date'
     +' ,AXB.New_InitialAgreementSignedDate as Initial_Agreement_Sign_Date'
     +' ,null as Initial_Agreement_Term_Date'
     +' ,AB.CreatedOn as Date_Created'
     +' ,AB.ModifiedOn as Audit_Date'
     +' ,(case when AB.StateCode = 2 then 1 else 0 end) as Entity_Disabled '
     +' ,AB.AccountID as CRM_AccountId'
     +' ,convert(varchar(36),AB.AccountID) as CRM_ID'
     +' ,AXB.New_LMS_OrgID as LMS_OrganizationID '
+' from CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.AccountBase AB'
+' left join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.AccountExtensionBase AXB'
     +' on AB.AccountID = AXB.AccountID'
  --+'left join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.Customeraddressbase CAB'
  --   +'  on AB.AccountID = CAB.parentid '
  --   +'  and CAB.AddressNumber = 1'
+' left join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.stringmap crmstates'
     +'  on AXB.New_StateProvince = crmstates.AttributeValue'
     +'  and crmstates.AttributeName = ''new_stateprovince'''
     +'  and crmstates.objecttypecode=2'
+' left join dbo.View_LOV OrgLOV on AB.customertypecode = OrgLOV.CRM_AttributeValue'
     +'  and CRM_AttributeName = ''customertypecode'''
     +'  and OrgLOV.Name = ''ORG_TYPE'''
+' where not exists (select org_id from ' +@v_remote_db  +'dbo.Organizations'
                   +' where Organizations.CRM_AccountId = AB.AccountID)'

    print @SQL1
    print @SQL2
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar)
       +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar) 

    EXEC (@SQL1+@SQL2)


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Organizations from CRM'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off '+
' update ' +@v_remote_db  +'dbo.Organizations'
  +' set Full_NAME = AB.Name'
     +' ,Program_NAME = AXB.New_ProgramName'
     +' ,Org_Type_LOV = OrgLOV.LOV_Item'
     --+',Org_Status_LOV = (select LOV_Item from dbo.View_LOV where Name = 'ORG_STATUS' and Value=convert(char,AB.StatusCode))'
     +' ,Org_Status_LOV = convert(char,AB.StatusCode)'
     +' ,Email = AB.EmailAddress1'
     +' ,Website  = AB.WebSiteURL'
      --+',LOWINCOME_Criteria ='
      --+',LOWINCOME_Percent ='
      --+',LOWINCOME_Description  ='
      --+',Initiation_Date ='
     +' ,Date_First_Home_Visit = AXB.New_DateofFirstHomeVisit'
     +' ,PPPL_Effective_Date = AXB.New_PPPL_EffectiveDate'
     +' ,PPPL_Expiration_Date = AXB.New_PPPLExpirationDate'
      --+',Mileage_Rate ='
      --+',Service_Level_Covered_ID = AXB.New_ServiceLevelCovered LOV'
      --+',Service_Level_Covered_ID ='
      --+',Population_Served ='
     +' ,Nbr_Billable_Teams = AXB.New_NumberBillableTeams'
     +' ,Initial_Agreement_Effective_Date = AXB.New_AgreementEffectiveDate'
     +' ,Initial_Agreement_Sign_Date = AXB.New_InitialAgreementSignedDate'
      --+',Initial_Agreement_Term_Date'
     +' ,Date_Created = AB.CreatedOn'
     +' ,Audit_Date = AB.ModifiedOn'
     +' ,Entity_Disabled = (case when AB.StateCode = 2 then 1 else 0 end)'
     +' ,CRM_AccountId = AB.AccountID'
     +' ,CRM_ID = convert(varchar(36),AB.AccountID)'
     +' ,LMS_OrganizationID = AXB.New_LMS_OrgID'
+' from ' +@v_remote_db  +'dbo.Organizations'
+' inner join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.AccountBase AB'
     +'  on Organizations.CRM_AccountID = AB.AccountID'
+' left join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.AccountExtensionBase AXB'
      +' on AB.AccountID = AXB.AccountID'
  --+'left join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.Customeraddressbase CAB'
  --    +' on AB.AccountID = CAB.parentid '
  --    +' and CAB.AddressNumber = 1'
+' left join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.stringmap crmstates'
      +' on AXB.New_StateProvince = crmstates.AttributeValue'
      +' and crmstates.AttributeName = ''new_stateprovince'''
      +' and crmstates.objecttypecode=2'
+' left join dbo.View_LOV OrgLOV on AB.customertypecode = OrgLOV.CRM_AttributeValue'
      +' and CRM_AttributeName = ''customertypecode'''
      +' and OrgLOV.Name = ''ORG_TYPE'''
+' where Organizations.DataSource = ''CRM'''
  +' and isnull(Organizations.Audit_Date,convert(datetime,''19700101'',112)) '
      +' < isnull(AB.ModifiedOn,convert(datetime,''19700101'',112))'

    print @SQL1
    EXEC (@SQL1)

----------------------------------------------------------------------------------------
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing CRM Addresses'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------
 
print '  Cont: SP_Organizations_From_CRM_CRM - Adding CRM Address Records'

set @SQL1 = 'set nocount off '+
' insert into ' +@v_remote_db  +'dbo.Organization_Addresses'
      +' (Org_ID,Address_type,Address1,Address2,City,State,ZipCode'
      +' ,county,Audit_Date)'
+' select Organizations.Org_ID'
      +' ,LOVV.LOV_Item'
      +' ,CAB.Line1'
      +' ,CAB.Line2'
      +' ,left(CAB.City,30) as City'
      +' ,left(crmstates.value,20) as state'
      +' ,CAB.PostalCode'
      +' ,CAB.county'
      +' ,getdate()'
+' from ' +@v_remote_db  +'dbo.Organizations'
+' inner join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.AccountBase AB'
     +'  on Organizations.CRM_AccountID = AB.AccountID'
+' left join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.AccountExtensionBase AXB'
     +'  on AB.AccountID = AXB.AccountID'
+' left join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.Customeraddressbase CAB'
     +'  on AB.AccountID = CAB.parentid '
     +'  and CAB.AddressNumber = 1'
+' left join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.stringmap crmstates'
     +'  on AXB.New_StateProvince = crmstates.AttributeValue'
     +'  and crmstates.AttributeName = ''new_stateprovince'''
     +'  and crmstates.objecttypecode=2'
+' join dbo.LOV_Names LOVN ON LOVN.Name = ''ADDRESS_TYPE'''
+' inner join dbo.LOV_Values LOVV on LOVV.LOV_Name_ID = LOVN.LOV_Name_ID'
      +' and LOVV.Value = ''PRIMARY'''
+' where organizations.datasource = ''CRM'''
  +' and not exists (select Org_Address_id'
                    +' from ' +@v_remote_db  +'dbo.Organization_Addresses '
                   +' where Organization_Addresses.Org_ID = Organizations.Org_ID'
                     +' and Organization_Addresses.Address_type = LOVV.LOV_Item)'

    print @SQL1
    EXEC (@SQL1)


/*    *** Commented section  ***
-- problem with comparison between systems:
-- Cannot resolve the collation conflict 
-- between "Latin1_General_CI_AI" and "SQL_Latin1_General_CP1_CI_AS" in the not equal to operation.

print '  Cont: SP_Organizations_From_CRM_CRM - Updating CRM Address Records'

set @SQL1 = 'set nocount off '+
' update ' +@v_remote_db  +'dbo.Organization_Addresses'
  +' set Address1 = CAB.Line1'
      +' ,Address2 = CAB.Line2'
      +' ,City = left(CAB.City,30)'
      +' ,State = left(crmstates.value,20)'
      +' ,ZipCode = CAB.PostalCode'
      +' ,county = CAB.county'
      +' ,Audit_Date = getdate()'
+' from ' +@v_remote_db  +'dbo.Organization_Addresses OA'
+' inner join dbo.Organizations on OA.Org_ID = Organizations.Org_ID'
+' inner join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.AccountBase AB'
      +' on Organizations.CRM_AccountID = AB.AccountID'
+' left join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.AccountExtensionBase AXB'
      +' on AB.AccountID = AXB.AccountID'
+' left join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.Customeraddressbase CAB'
     +'  on AB.AccountID = CAB.parentid '
     +'  and CAB.AddressNumber = 1'
+' left join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.stringmap crmstates'
      +' on AXB.New_StateProvince = crmstates.AttributeValue'
      +' and crmstates.AttributeName = 'new_stateprovince''
      +' and crmstates.objecttypecode=2'
+' join dbo.LOV_Names LOVN ON LOVN.Name = ''ADDRESS_TYPE'''
+' inner join dbo.LOV_Values LOVV on LOVV.LOV_Name_ID = LOVN.LOV_Name_ID'
      +' and LOVV.Value = ''PRIMARY'''
+' where organizations.datasource = ''CRM'''
  +' and OA.Address_type = LOVV.LOV_Item'
  +' and ((isnull(OA.Address1,''xyz1234'') != isnull(CAB.Line1,''xyz1234'') or'
       +'  isnull(OA.Address2,''xyz1234'') != isnull(CAB.Line2,''xyz1234'') or'
       +'  isnull(OA.City,''xyz1234'') != isnull(left(CAB.City,30),''xyz1234'') or'
       +'  isnull(OA.State,''xyz1234'') != isnull(left(crmstates.value,20),''xyz1234'') or'
       +'  isnull(OA.ZipCode,''xyz1234'') != isnull(CAB.PostalCode,''xyz1234'') or'
       +'  isnull(OA.county,''xyz1234'') != isnull(CAB.county,''xyz1234''))'
      +'  or OA.Audit_Date is null)'

    print @SQL1
    --EXEC (@SQL1)
*/

----------------------------------------------------------------------------------------
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing CRM Telephones'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

print '  Cont: SP_Organizations_From_CRM_CRM - Adding CRM Telephone Records'

-- Primary1 phone:
set @SQL1 = 'set nocount off '+
' insert into ' +@v_remote_db  +'dbo.Organization_Telephones'
      +' (Org_ID,Telephone_type,Telephone,Audit_Date)'
+' select Organizations.Org_ID'
      +' ,LOVV.LOV_Item'
      +' ,CAB.Telephone1'
      +' ,getdate()'
+' from ' +@v_remote_db  +'dbo.Organizations'
+' inner join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.AccountBase AB'
     +'  on Organizations.CRM_AccountID = AB.AccountID'
+' left join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.Customeraddressbase CAB'
     +'  on AB.AccountID = CAB.parentid '
     +'  and CAB.AddressNumber = 1'
+' join dbo.LOV_Names LOVN ON LOVN.Name = ''TELEPHONE_TYPE'''
+' inner join dbo.LOV_Values LOVV on LOVV.LOV_Name_ID = LOVN.LOV_Name_ID'
     +'  and LOVV.Value = ''PRIMARY1'''
+' where Organizations.Datasource = ''CRM'''
  +' and CAB.Telephone1 is not null'
  +' and not exists (select Org_Telephone_id'
                    +' from ' +@v_remote_db  +'dbo.Organization_Telephones '
                   +' where Organization_Telephones.Org_ID = Organizations.Org_ID'
                     +' and Organization_Telephones.Telephone_type = LOVV.LOV_Item)'

    print @SQL1
    EXEC (@SQL1)


-- Primary2 phone:
set @SQL1 = 'set nocount off '+
' insert into ' +@v_remote_db  +'dbo.Organization_Telephones'
      +' (Org_ID,Telephone_type,Telephone,Audit_Date)'
+' select Organizations.Org_ID'
      +' ,LOVV.LOV_Item'
      +' ,CAB.Telephone2'
      +' ,getdate()'
+' from ' +@v_remote_db  +'dbo.Organizations'
+' inner join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.AccountBase AB'
     +'  on Organizations.CRM_AccountID = AB.AccountID'
+' left join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.Customeraddressbase CAB'
     +'  on AB.AccountID = CAB.parentid '
     +'  and CAB.AddressNumber = 1'
+' join dbo.LOV_Names LOVN ON LOVN.Name = ''TELEPHONE_TYPE'''
+' inner join dbo.LOV_Values LOVV on LOVV.LOV_Name_ID = LOVN.LOV_Name_ID'
      +' and LOVV.Value = ''PRIMARY2'''
+' where Organizations.Datasource = ''CRM'''
  +' and CAB.Telephone2 is not null'
  +' and not exists (select Org_Telephone_id'
                    +' from ' +@v_remote_db  +'dbo.Organization_Telephones '
                   +' where Organization_Telephones.Org_ID = Organizations.Org_ID'
                     +' and Organization_Telephones.Telephone_type = LOVV.LOV_Item)
'
    print @SQL1
    EXEC (@SQL1)


-- Primary3 phone:
set @SQL1 = 'set nocount off '+
' insert into ' +@v_remote_db  +'dbo.Organization_Telephones'
      +' (Org_ID,Telephone_type,Telephone,Audit_Date)'
+' select Organizations.Org_ID'
      +' ,LOVV.LOV_Item'
      +' ,CAB.Telephone3'
      +' ,getdate()'
+' from ' +@v_remote_db  +'dbo.Organizations'
+' inner join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.AccountBase AB'
      +' on Organizations.CRM_AccountID = AB.AccountID'
+' left join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.Customeraddressbase CAB'
      +' on AB.AccountID = CAB.parentid '
      +' and CAB.AddressNumber = 1'
+' join dbo.LOV_Names LOVN ON LOVN.Name = ''TELEPHONE_TYPE'''
+' inner join dbo.LOV_Values LOVV on LOVV.LOV_Name_ID = LOVN.LOV_Name_ID'
      +' and LOVV.Value = ''PRIMARY3'''
+' where Organizations.Datasource = ''CRM'''
  +' and CAB.Telephone3 is not null'
  +' and not exists (select Org_Telephone_id'
                    +' from ' +@v_remote_db  +'dbo.Organization_Telephones '
                   +' where Organization_Telephones.Org_ID = Organizations.Org_ID'
                     +' and Organization_Telephones.Telephone_type = LOVV.LOV_Item)'

    print @SQL1
    EXEC (@SQL1)


-- Fax:
set @SQL1 = 'set nocount off '+
' insert into ' +@v_remote_db  +'dbo.Organization_Telephones'
      +' (Org_ID,Telephone_type,Telephone,Audit_Date)'
+' select Organizations.Org_ID'
      +' ,LOVV.LOV_Item'
      +' ,AB.Fax'
      +' ,getdate()'
+' from ' +@v_remote_db  +'dbo.Organizations'
+' inner join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.AccountBase AB'
      +' on Organizations.CRM_AccountID = AB.AccountID'
+' join dbo.LOV_Names LOVN ON LOVN.Name = ''TELEPHONE_TYPE'''
+' inner join dbo.LOV_Values LOVV on LOVV.LOV_Name_ID = LOVN.LOV_Name_ID'
       +' and LOVV.Value = ''PRIMARY3'''
+' where Organizations.Datasource = ''CRM'''
  +' and AB.Fax is not null'
  +' and not exists (select Org_Telephone_id'
                    +' from ' +@v_remote_db  +'dbo.Organization_Telephones '
                   +' where Organization_Telephones.Org_ID = Organizations.Org_ID'
                     +' and Organization_Telephones.Telephone_type = LOVV.LOV_Item)'

    print @SQL1
    EXEC (@SQL1)



/*    *** Commented section  ***
-- problem with comparison between systems:
-- Msg 468, Level 16, State 9, Line 16
-- Cannot resolve the collation conflict 
-- between "Latin1_General_CI_AI" and "SQL_Latin1_General_CP1_CI_AS" in the not equal to operation.

print '  Cont: SP_Organizations_From_CRM_CRM - Updating CRM Phone Records'

-- Primary1 phone:
set @SQL1 = 'set nocount off '+
' update ' +@v_remote_db  +'dbo.Organization_Telephones'
  +' set Telephone = CAB.Telephone1'
     +' ,Audit_Date = getdate()'
+' from ' +@v_remote_db  +'dbo.Organization_Telephones OT'
+' inner join dbo.Organizations on OT.Org_ID = Organizations.Org_ID'
+' inner join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.AccountBase AB'
     +'  on Organizations.CRM_AccountID = AB.AccountID'
+' left join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.Customeraddressbase CAB'
     +'  on AB.AccountID = CAB.parentid '
     +'  and CAB.AddressNumber = 1'
+' join dbo.LOV_Names LOVN ON LOVN.Name = ''TELEPHONE_TYPE''
+' inner join dbo.LOV_Values LOVV on LOVV.LOV_Name_ID = LOVN.LOV_Name_ID'
        and LOVV.Value = ''PRIMARY1'''
+' where Organizations.Datasource = ''CRM'''
  +' and OT.Telephone_type = LOVV.LOV_Item'
  +' and (isnull(OT.Telephone,''xyz1234'') != isnull(CAB.telephone1,''xyz1234'')'
       +' or OA.Audit_Date is null)'

    print @SQL1
    --EXEC (@SQL1)


-- Primary2 phone:
set @SQL1 = 'set nocount off '+
' update ' +@v_remote_db  +'dbo.Organization_Telephones
  +' set Telephone = CAB.Telephone2'
     +' ,Audit_Date = getdate()'
+' from ' +@v_remote_db  +'dbo.Organization_Telephones OT'
+' inner join dbo.Organizations on OT.Org_ID = Organizations.Org_ID'
+' inner join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.AccountBase AB'
     +'  on Organizations.CRM_AccountID = AB.AccountID'
+' left join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.Customeraddressbase CAB'
     +'  on AB.AccountID = CAB.parentid '
     +'  and CAB.AddressNumber = 1''
+' join dbo.LOV_Names LOVN ON LOVN.Name = 'TELEPHONE_TYPE'''
+' inner join dbo.LOV_Values LOVV on LOVV.LOV_Name_ID = LOVN.LOV_Name_ID'
     +'  and LOVV.Value = ''PRIMARY2'''
+' where Organizations.Datasource = ''CRM'''
  +' and OT.Telephone_type = LOVV.LOV_Item'
  +' and (isnull(OT.Telephone,''xyz1234'') != isnull(CAB.telephone2,''xyz1234'')'
       +' or OA.Audit_Date is null)'

    print @SQL1
    --EXEC (@SQL1)


-- Primary3 phone:
set @SQL1 = 'set nocount off '+
' update ' +@v_remote_db  +'dbo.Organization_Telephones'
  +' set Telephone = CAB.Telephone3'
     +' ,Audit_Date = getdate()'
+' from ' +@v_remote_db  +'dbo.Organization_Telephones OT'
+' inner join dbo.Organizations on OT.Org_ID = Organizations.Org_ID'
+' inner join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.AccountBase AB'
     +'  on Organizations.CRM_AccountID = AB.AccountID'
+' left join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.Customeraddressbase CAB'
     +'  on AB.AccountID = CAB.parentid '
     +'  and CAB.AddressNumber = 1'
+' join dbo.LOV_Names LOVN ON LOVN.Name = ''TELEPHONE_TYPE'''
+' inner join dbo.LOV_Values LOVV on LOVV.LOV_Name_ID = LOVN.LOV_Name_ID'
     +'  and LOVV.Value = ''PRIMARY3'''
+' where Organizations.Datasource = ''CRM'''
  +' and OT.Telephone_type = LOVV.LOV_Item'
  +' and (isnull(OT.Telephone,''xyz1234'') != isnull(CAB.telephone2,'xyz1234'')'
       +' or OA.Audit_Date is null)'

    print @SQL1
    --EXEC (@SQL1)


-- Fax phone:
set @SQL1 = 'set nocount off '+
' update ' +@v_remote_db  +'dbo.Organization_Telephones'
  +' set Telephone = AB.Fax'
     +' ,Audit_Date = getdate()'
+' from ' +@v_remote_db  +'dbo.Organization_Telephones OT'
+' inner join dbo.Organizations on OT.Org_ID = Organizations.Org_ID'
+' inner join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.AccountBase AB'
+' join dbo.LOV_Names LOVN ON LOVN.Name = ''TELEPHONE_TYPE'''
+' inner join dbo.LOV_Values LOVV on LOVV.LOV_Name_ID = LOVN.LOV_Name_ID'
       +' and LOVV.Value = ''Fax'''
+' where Organizations.Datasource = ''CRM'''
  +' and OT.Telephone_type = LOVV.LOV_Item'
  +' and (isnull(OT.Telephone,''xyz1234'') != isnull(AB.Fax,''xyz1234'')'
       +' or OA.Audit_Date is null)'

    print @SQL1
    --EXEC (@SQL1)
*/

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- Process Rollup Structure against established CRM:

/* Validation:

-- CRM Lookup Values:
select stringmap.attributename 
,(select COUNT(*) from CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.stringmap stringmap2 
   where stringmap2.objecttypecode=2 and stringmap2.attributename = stringmap.attributename)
from CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.stringmap stringmap
where 
 (select COUNT(*) from CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.stringmap stringmap2 
   where stringmap2.objecttypecode=2 and stringmap2.attributename = stringmap.attributename)
   > 0
group by stringmap.attributename
order by stringmap.attributename

-- list expected rollup of organizations from CRM mapping:
select Organizations.Org_ID, Organizations.CRM_AccountId, Organizations.Parent_Org_ID
      ,AB.Accountid as AB_AccountID, AB.ParentAccountID as AB_ParentAccountID
      ,ParentOrg.Org_ID as lookup_Parent_Org_ID
  from dbo.Organizations
  inner join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.AccountBase AB
       on AB.AccountID = Organizations.CRM_AccountId
  left join dbo.Organizations ParentOrg 
       on AB.ParentAccountID = ParentOrg.CRM_AccountId
 --where isnull(Organizations.Parent_Org_ID,999999999) != isnull(ParentOrg.Org_ID,999999999)
 order by organizations.org_id

*/

-- update the Org's Parent_ORG_ID retrieved from the CRM Mapping:
set @SQL1 = 'set nocount off '
+' update ' +@v_remote_db  +'dbo.Organizations'
  +' set Parent_Org_ID = ParentOrg.Org_ID'
+' from ' +@v_remote_db  +'dbo.Organizations'
+' inner join CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.AccountBase AB'
     +'  on AB.AccountID = Organizations.CRM_AccountId'
+' left join dbo.Organizations ParentOrg '
     +'  on AB.ParentAccountID = ParentOrg.CRM_AccountId'
+' where isnull(Organizations.Parent_Org_ID,999999999) != isnull(ParentOrg.Org_ID,999999999)'

    print @SQL1
    EXEC (@SQL1)

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


print '  End of Process: SP_Organizations_From_ETO_CRM'
GO
