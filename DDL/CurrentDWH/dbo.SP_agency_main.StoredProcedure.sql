USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_agency_main]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_agency_main
--
CREATE PROCEDURE [dbo].[SP_agency_main]
AS
--
-- This script controls updates to the Agency table in the Data Warehouse.
-- Processing ETO Entities identified as Non-Individuals.
--
-- Table effected - dbo.Agencies
--
-- Insert: select and insert when ETO agency entity is found to be missing in the DW.
-- Update: select and update when ETO agency entity exists in DW and has been changed in ETO.
--
-- Database Links:
-- CRM: CRMsrvr.Nurse_FamilyPartnership_MSCRM 

-- History:
--   20120306 - Added conditional selection and updates based upon the field DataSource being null.
--   20120924 - Added harded coded list of entity types to be considered as Agencies.
--   20130422 - Added logic to exclude processing of specified sites via dbo.Sites_Excluded.
--   20130530 - Added logic to disable agencies when found to be disabled in ETO, 
--              because ETO does not set an AuditDate change for the disable feature.
--   20140927 - Amended the changes section to convert any null value of auditdate to a default for comparison purposes.
--   20160329 - Added the inclusion of the ETO Sites.Site (name) as Site_Name for the benefit of the ProgramsandSites table population.


DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_AGENCY_MAIN'

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
print ' '
print 'Processing SP_agency_main - Insert new Agencies'
-- Extraction for Agency:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Agencies'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- Basic Agency info (standard attributes):
insert into dbo.Agencies
      (Entity_ID
      ,AGENCY_INFO_0_NAME
      ,Site_ID
      ,Site_Alias
      ,Entity_Type_ID
      ,Entity_Type 
      ,Entity_SubType_ID
      ,Entity_SubType 
      ,Agency_Status
      ,Program_ID
      ,Address1
      ,Address2 
      ,City
      ,State
      ,ZipCode
      ,County
      ,Phone1
      ,Site_Address1
      ,Site_Address2
      ,Site_City
      ,Site_State
      ,Site_ZipCode
      ,Site_County
      ,Site_Phone1
      ,Date_Created
      ,Audit_Date
      ,Site_Audit_Date
      ,Audit_Staff_ID
      ,Entity_Disabled
      ,Site_Disabled
      ,Site_Name)
select Entities.EntityID
      ,EntityName
      ,Sites.SiteID
      ,Sites.SiteAlias
      ,EntityXEntityType.EntityTypeID
      ,EntityTypes.EntityType 
      ,EntityXEntityType.EntitySubTypeID
      ,EntitySubTypes.EntitySubType 
      ,null as agency_status
      ,Entities.ProgramID
      ,Entities.Address1
      ,Entities.Address2 
      ,EZipCodes.City
      ,EZipCodes.State
      ,Entities.ZipCode
      ,EZipCodes.County
      ,Entities.GeneralPhoneNumber
      ,Sites.Address1 as Site_Address1
      ,Sites.Address2 as Site_Address2
      ,SZipCodes.City as Site_City
      ,SZipCodes.State as Site_State
      ,Sites.ZipCode as Site_ZipCode
      ,SZipCodes.County as Site_County
      ,Sites.PhoneNumber
      ,Entities.DateCreated
      ,Entities.AuditDate
      ,Sites.AuditDate
      ,Entities.AuditStaffID
      ,Entities.disabled
      ,Sites.disabled
      ,Sites.Site
  from ETOSRVR.etosolaris.dbo.Entities Entities
  -- FYI Note: Possible secondary Type / Subtype selections
  LEFT JOIN ETOSRVR.etosolaris.dbo.EntityXEntityType EntityXEntityType
       JOIN ETOSRVR.etosolaris.dbo.EntityTypes EntityTypes
         ON EntityXEntityType.EntityTypeID = EntityTypes.EntityTypeID
  LEFT JOIN ETOSRVR.etosolaris.dbo.EntitySubTypes EntitySubTypes
         ON EntityXEntityType.EntitySubTypeID = EntitySubTypes.EntitySubTypeID
         ON Entities.EntityID = EntityXEntityType.EntityID
  LEFT JOIN ETOSRVR.etosolaris.dbo.Staff Staff
         on Entities.AuditStaffID = Staff.StaffID 
--  LEFT JOIN ETOSRVR.etosolaris.dbo.ZipCodes EZipCodes -- called locally from copied table
  LEFT JOIN dbo.PostalCodesUnduplicated EZipCodes
	 ON Entities.ZipCode = EZipCodes.ZipCode
  LEFT JOIN ETOSRVR.etosolaris.dbo.sites Sites
         on Staff.SiteID = Sites.SiteID
--  LEFT JOIN ETOSRVR.etosolaris.dbo.ZipCodes SZipCodes  -- called locally from copied table
  LEFT JOIN dbo.PostalCodesUnduplicated SZipCodes
	 ON Sites.ZipCode = SZipCodes.ZipCode
 where Entities.IsIndividual = 0
-- Agency Entity Types:
   and EntityXEntityType.EntityTypeID in (17,18)
-- discregard disabled test entites:
   and upper(substring(Entities.EntityName,1,4)) not in('TEST','FAKE')
   and not exists (select nfpagencies.Entity_ID
                     from dbo.Agencies nfpagencies
                    where nfpagencies.Entity_Id = Entities.EntityId)
   and not exists (select Entity_ID from dbo.Agencies_Excluded ex1
                    where ex1.Entity_Id = Entities.EntityId)
   and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = Sites.SiteId);



----------------------------------------------------------------------------------------
print '  Cont: SP_agency_main - Updating Agencies basic changes'
-- Extraction for Agency:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Agencies'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

Update dbo.Agencies
   set AGENCY_INFO_0_NAME = EntityName
      ,Entity_Type_ID = EntityXEntityType.EntityTypeID
      ,Entity_Type  = EntityTypes.EntityType 
      ,Entity_SubType_ID = EntityXEntityType.EntitySubTypeID
      ,Entity_SubType  = EntitySubTypes.EntitySubType 
--      ,Agency_Status = 
      ,Program_ID = Entities.ProgramID
      ,Address1 = Entities.Address1 
      ,Address2  = Entities.Address2
      ,City = EZipCodes.City
      ,State = EZipCodes.State
      ,ZipCode = Entities.ZipCode
      ,County = EZipCodes.County
      ,Phone1 = Entities.GeneralPhoneNumber
      ,Audit_Date = Entities.AuditDate
      ,Audit_Staff_ID = Entities.AuditStaffID
      ,Entity_Disabled = Entities.disabled
  from dbo.Agencies Agencies
  INNER JOIN ETOSRVR.etosolaris.dbo.Entities Entities
          ON Entities.EntityID = Agencies.Entity_ID
  -- FYI Note: Possible secondary Type / Subtype selections
  LEFT JOIN ETOSRVR.etosolaris.dbo.EntityXEntityType EntityXEntityType
       JOIN ETOSRVR.etosolaris.dbo.EntityTypes EntityTypes
         ON EntityXEntityType.EntityTypeID = EntityTypes.EntityTypeID
  LEFT JOIN ETOSRVR.etosolaris.dbo.EntitySubTypes EntitySubTypes
         ON EntityXEntityType.EntitySubTypeID = EntitySubTypes.EntitySubTypeID
         ON Entities.EntityID = EntityXEntityType.EntityID
  LEFT JOIN ETOSRVR.etosolaris.dbo.Staff Staff
         on Entities.AuditStaffID = Staff.StaffID 
--  LEFT JOIN ETOSRVR.etosolaris.dbo.ZipCodes EZipCodes   -- called locally from copied table
  LEFT JOIN PostalCodesUnduplicated EZipCodes   
	 ON Entities.ZipCode = EZipCodes.ZipCode
  LEFT JOIN ETOSRVR.etosolaris.dbo.sites Sites
         on Staff.SiteID = Sites.SiteID
 where Entities.IsIndividual = 0
   and isnull(Agencies.Audit_Date,convert(datetime,'19700101',112)) <
       isnull(Entities.AuditDate, convert(datetime,'19700101',112))
   and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = Sites.SiteId);



print '  Cont: SP_agency_main - Updating Agencies Site changes'
-- Extraction for Agency:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Agency Site Changes'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

Update dbo.Agencies
   set Site_ID = Sites.SiteID
      ,Site_Alias = Sites.SiteAlias
      ,Site_Address1 = Sites.Address1
      ,Site_Address2 = Sites.Address2
      ,Site_City = SZipCodes.City
      ,Site_State = SZipCodes.State
      ,Site_ZipCode = Sites.ZipCode
      ,Site_County = SZipCodes.County
      ,Site_Phone1 = Sites.PhoneNumber
      ,Site_Audit_Date = Sites.AuditDate
      ,Site_Disabled = Sites.disabled
      ,Site_Name = Sites.Site
  from dbo.Agencies Agencies
  INNER JOIN ETOSRVR.etosolaris.dbo.Entities Entities
          ON Entities.EntityID = Agencies.Entity_ID
  LEFT JOIN ETOSRVR.etosolaris.dbo.Staff Staff
         on Entities.AuditStaffID = Staff.StaffID 
  LEFT JOIN ETOSRVR.etosolaris.dbo.sites Sites
         on Staff.SiteID = Sites.SiteID
--  LEFT JOIN ETOSRVR.etosolaris.dbo.ZipCodes SZipCodes   -- called locally from copied table
  LEFT JOIN PostalCodesUnduplicated SZipCodes  
	 ON Sites.ZipCode = SZipCodes.ZipCode
 where Entities.IsIndividual = 0
   and isnull(Agencies.Audit_Date,convert(datetime,'19700101',112)) <
       isnull(Sites.AuditDate, convert(datetime,'19700101',112));



----------------------------------------------------------------------------------------
print '  Cont: SP_Agency_main - Delete ETO Deleted Entities'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Deleting ETO Deletions'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

delete dbo.Agencies
  from dbo.Agencies
 where DataSource is null
   and not exists (select EntityID
                     from ETOSRVR.etosolaris.dbo.Entities Entities
                    where EntityID = Agencies.Entity_ID)



----------------------------------------------------------------------------------------
PRINT 'Calling SP_ETO_to_DW_Entity_Attributes for ORG'

-- Entity Types:
--1	Employer
--2	Referral Source
--6	Funding Source
--7	Education Institution
--16	Individuals
--17	Businesses
--18	Service Providers
--21	Billing Provider
--22	Administrative
--23	Classes
--50	Property
--1000	Vendor

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'CAlling Entity Attributes for ORG'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

exec SP_ETO_to_DW_Entity_Attributes 'ORG'



----------------------------------------------------------------------------------------
PRINT 'Validating existing new CRM_ID in CRM'
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Validating CRM AccountIDs'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

Update dbo.Agencies
   set CRM_AccountID = CRM_AccountBase.AccountID
  from dbo.Agencies
  inner join CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.AccountBase CRM_AccountBase
          on Agencies.CRM_ID = convert(varchar(36),CRM_AccountBase.AccountID)
 where Agencies.CRM_ID is not null
   and Agencies.CRM_AccountID is null;


----------------------------------------------------------------------------------------
-- update disabled ETO entities because the disabled flag does not trigger an Audit Date
----------------------------------------------------------------------------------------
update dbo.agencies
   set Entity_Disabled = 1
from dbo.agencies 
 where Entity_id in
 (select Entity_Id
  from dbo.Agencies
  inner join ETOSRVR.etosolaris.dbo.Entities
     on Entities.EntityID = Agencies.Entity_Id
 where Entities.Disabled = 1
   and Agencies.Entity_Disabled = 0
   and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = Agencies.Site_Id) );


----------------------------------------------------------------------------------------
PRINT 'Mapping CRM_ID to LMS_OrgID'
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Mapping CRM to LMS_OrgID'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

Update dbo.Agencies
   set LMS_OrganizationID = CRM_AccountExtensionBase.New_LMS_OrgID
  from dbo.Agencies
  inner join CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.AccountExtensionBase CRM_AccountExtensionBase
          on Agencies.CRM_ID = convert(varchar(36),CRM_AccountExtensionBase.AccountID)
 where Agencies.CRM_ID is not null
   and Agencies.LMS_OrganizationID is null

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------


print '  End of Process: SP_agency_main'
GO
