USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_Clients_main]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_Clients_main
--
CREATE PROCEDURE [dbo].[SP_Clients_main]
AS
--
-- This script controls updates to the Clients table in the Data Warehouse.
-- Processing ETO Entities identified as Non-Individuals.
--
-- Table effected - dbo.Clients
--
-- Insert: select and insert when ETO Client is found to be missing in the DW.
-- Update: select and update when ETO Client exists in DW and has been changed in ETO.
--
-- History:
--   20110714 - Added CaseNumber to dbo.Clients table.
--   20120306 - Added conditional selection and updates based upon the field DataSource being null.
--   20121129 - Added Reason for Referral field update.
--   20130422 - Added logic to exclude specific sites via dbo.Sites_Excluded table.
--   20150122 - Added the inclusion of SSN from etosolaris.clients.


DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_CLIENTS_MAIN'

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
print 'Processing SP_Clients_main - Insert new Clients'
-- Extraction for Clients:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Clients'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- Basic Clients info (standard attributes):
insert into dbo.Clients
      (Client_ID
      ,Site_ID
      ,Last_Name
      ,First_Name
      ,Middle_Name
      ,Prefix
      ,Suffix
      ,DOB
      ,Gender 
      ,Marital_Status
      ,Address1
      ,Address2 
      ,City
      ,State
      ,ZipCode
      ,County
      ,Email
      ,Home_Phone
      ,Cell_Phone
      ,Work_Phone
      ,Work_Phone_Extension
      ,Pager
      ,Date_Created
      ,Audit_Date
      ,Audit_Staff_ID
      ,Disabled
      ,Funding_Entity_ID
      ,Referral_Entity_ID
      ,Assigned_Staff_ID
      ,CaseNumber
      ,SSN)
select Clients.CLID
      ,Sites.SiteID
      ,Clients.Lname
      ,Clients.FName
      ,Clients.MiddleInitial
      ,Prefixes.Prefix
      ,Suffixes.Suffix
      ,Clients.DOB
      ,Clients.Gender 
      ,Clients.MaritalStatusID
      ,Clients.Address1
      ,Clients.Address2
      ,CZipCodes.City
      ,CZipCodes.State
      ,Clients.ZipCode
      ,CZipCodes.County
      ,Clients.Email
      ,Clients.HomePhone
      ,Clients.CellPhone
      ,Clients.WorkPhone
      ,Clients.WorkPhoneExtension
      ,Clients.Pager
      ,Clients.DateCreated
      ,Clients.AuditDate
      ,Clients.AuditStaffID
      ,Clients.Disabled
      ,Clients.FundingEntityID
      ,Clients.ReferralEntityID
      ,Clients.AssignedStaffID
      ,Clients.CaseNumber
      ,Clients.SSN
  from ETOSRVR.etosolaris.dbo.Clients Clients
  LEFT JOIN ETOSRVR.etosolaris.dbo.Staff Staff
       on Clients.AuditStaffID = Staff.StaffID 
--  LEFT JOIN ETOSRVR.etosolaris.dbo.ZipCodes CZipCodes   -- called locally from copied table
  LEFT JOIN PostalCodesUnduplicated  CZipCodes
	ON Clients.ZipCode = CZipCodes.ZipCode
  LEFT JOIN ETOSRVR.etosolaris.dbo.sites Sites
       on Staff.SiteID = Sites.SiteID
--  LEFT Join ETOSRVR.etosolaris.dbo.ClientAddresses CAddress
--       on Clients.CLID = CAddress.CLID
--  LEFT JOIN ETOSRVR.etosolaris.dbo.ZipCodes CAZipCodes
--       ON CAddress.ZipCode = CAZipCodes.ZipCode
  LEFT JOIN ETOSRVR.etosolaris.dbo.Suffixes Suffixes
       ON Clients.SuffixID = Suffixes.SuffixID
       and Suffixes.Disabled = 0
  LEFT JOIN ETOSRVR.etosolaris.dbo.Prefixes Prefixes
       ON Clients.PrefixID = Prefixes.PrefixID
 WHERE not exists (select nfpclients.Client_ID
                     from dbo.clients nfpclients
                    where nfpclients.Client_Id = Clients.CLID)
   and exists (select nfpagencies.Site_ID
                     from dbo.Agencies nfpagencies
                    where nfpagencies.Site_Id = Sites.SiteId)
   and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = Sites.SiteId);



----------------------------------------------------------------------------------------
print '  Cont: SP_Clients_main - Update Client standard attribute changes'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Clients'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- Basic Clients info (standard attributes):

update dbo.Clients
   set Site_ID = Sites.SiteID
      ,Last_Name = Clients.Lname
      ,First_Name = Clients.FName
      ,Middle_Name = Clients.MiddleInitial
      ,Prefix = Prefixes.Prefix
      ,Suffix = Suffixes.Suffix
      ,DOB = Clients.DOB
      ,Gender = Clients.Gender 
      ,Marital_Status = Clients.MaritalStatusID
      ,Address1 = Clients.Address1
      ,Address2 = Clients.Address2
      ,City = CZipCodes.City
      ,State = CZipCodes.State
      ,ZipCode = Clients.ZipCode
      ,County = CZipCodes.County
      ,Email = Clients.Email
      ,Home_Phone = Clients.HomePhone
      ,Cell_Phone = Clients.CellPhone
      ,Work_Phone = Clients.WorkPhone
      ,Work_Phone_Extension = Clients.WorkPhoneExtension
      ,Pager = Clients.Pager
      ,Audit_Date = Clients.AuditDate
      ,Audit_Staff_ID = Clients.AuditStaffID
      ,Disabled = Clients.Disabled
      ,Funding_Entity_ID = Clients.FundingEntityID
      ,Referral_Entity_ID = Clients.ReferralEntityID
      ,Assigned_Staff_ID = Clients.AssignedStaffID
      ,CaseNumber = Clients.CaseNumber
      ,SSN = Clients.SSN
  from dbo.Clients NFPClients
  INNER JOIN ETOSRVR.etosolaris.dbo.Clients Clients
        on Clients.CLID = NFPCLIENTS.Client_ID
  LEFT JOIN ETOSRVR.etosolaris.dbo.Staff Staff
       on Clients.AuditStaffID = Staff.StaffID 
--  LEFT JOIN ETOSRVR.etosolaris.dbo.ZipCodes CZipCodes   -- called locally from copied table
  LEFT JOIN PostalCodesUnduplicated  CZipCodes
	ON Clients.ZipCode = CZipCodes.ZipCode
  LEFT JOIN ETOSRVR.etosolaris.dbo.sites Sites
       on Staff.SiteID = Sites.SiteID
--  LEFT Join ETOSRVR.etosolaris.dbo.ClientAddresses CAddress
--       on Clients.CLID = CAddress.CLID
--  LEFT JOIN ETOSRVR.etosolaris.dbo.ZipCodes CAZipCodes
--       ON CAddress.ZipCode = CAZipCodes.ZipCode
  LEFT JOIN ETOSRVR.etosolaris.dbo.Suffixes Suffixes
       ON Clients.SuffixID = Suffixes.SuffixID
       and Suffixes.Disabled = 0
  LEFT JOIN ETOSRVR.etosolaris.dbo.Prefixes Prefixes
       ON Clients.PrefixID = Prefixes.PrefixID
 where isnull(NFPClients.Audit_Date,convert(datetime,'19700101',112)) < Clients.AuditDate
   and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = Sites.SiteId);


-- Update the Reason for Referral (if found to be changed)

update dbo.Clients
   set ReasonForReferral = rfr.ReasonForReferral
  from dbo.Clients
  left join etosolaris.dbo.CLReferrals clr
    on clients.Client_Id = clr.CLID 
  left join etosolaris.dbo.ReasonsForReferral rfr
    on clr.ReasonForReferralID = rfr.ReasonForReferralID
 where clr.ReasonForReferralID is not null
   and isnull(clients.ReasonForReferral,'x') != isnull(rfr.ReasonForReferral,'x')
   and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = Clients.Client_Id)
 


----------------------------------------------------------------------------------------
print '  Cont: SP_Clients_main - Delete ETO Deleted Entities'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Deleting ETO Deletions'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

delete dbo.Clients
  from dbo.Clients
 where isnull(DataSource,'ETO') = 'ETO'
   and not exists (select CLID
                     from ETOSRVR.etosolaris.dbo.Clients etoclients
                    where etoclients.CLID = Clients.Client_ID)



----------------------------------------------------------------------------------------
print 'Calling SP_ETO_to_DW_Client_Demographics'
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Calling Client Demographics'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

exec SP_ETO_to_DW_Client_Demographics


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

print ' '
print '  End of Process: SP_Clients_main'
GO
