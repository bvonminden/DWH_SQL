USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_masters_update_client_demographics]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_masters_update_client_demographics
--
CREATE PROCEDURE [dbo].[SP_masters_update_client_demographics]
AS
--
-- This script controls the replicated client_demographics master table in the Data Warehouse.
--
-- DW - Update/Insert process for ETO client demographics
-- Table effected - dbo.client_demographics
--
-- Insert: select and insert when ETO client_demographics is found to be missing in the DW.
-- Update: select and update when ETO client_demographics exists in DW and has been changed in ETO.

-- History:
--   20161003 - Added updates for IsRequired.
--   20161118 - Added the integration of choice values to be used in metadata preparation.
--              Also added the logging of this process.


DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_MASTERS_CLIENT_DEMOGRAPHICS'

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
print 'Process SP_masters_update_client_demographics - Insert non-existing demographics'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Demographics'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

insert into dbo.Mstr_client_demographics
      (CDID
      ,CxDemographicName
      ,SiteID
      ,CxDTypeID
      ,CxDType
      ,EntityTypeID
      ,EntityType
      ,SequenceOrder
      ,RecordAsNumeric
      ,RecordAsArbitraryText
      ,IsProgramSpecific
      ,Disabled
      ,AuditDate
      ,SharedAcrossEnterprise
      ,AcceptAsDataPoint
      ,CxDescription
      ,ProgramID
      ,CustomSettings
      ,CDID_Source
      ,IsRequired)
select CxDemographics.CDID
      ,CxDemographics.CxDemographicName
      ,CxDemographics.SiteID
      ,CxDemographics.CxDTypeID
      ,CxDemographicTypes.CxDType
      ,CxAttributeXEntityType.EntityTypeID
      ,EntityTypes.EntityType
      ,CxDemographics.SequenceOrder
      ,CxDemographics.RecordAsNumeric
      ,CxDemographics.RecordAsArbitraryText
      ,CxDemographics.IsProgramSpecific
      ,CxDemographics.Disabled
      ,CxDemographics.AuditDate
      ,CxDemographics.SharedAcrossEnterprise
      ,CxDemographics.AcceptAsDataPoint
      ,CxDemographics.CxDescription
      ,CxDemographics.ProgramID
      ,CxDemographics.CustomSettings
      ,CxDemographics.CDID_Source
      ,CxDemographics.IsRequired
  from ETOSRVR.etosolaris.dbo.CxDemographics CxDemographics
  left join ETOSRVR.etosolaris.dbo.CxDemographicTypes CxDemographicTypes 
       on CxDemographics.CxDTypeid = CxDemographicTypes.CxDTypeid
  left join ETOSRVR.etosolaris.dbo.CxAttributeXEntityType CxAttributeXEntityType
         on CxDemographics.CDID = CxAttributeXEntityType.CDID
  left join ETOSRVR.etosolaris.dbo.EntityTypes EntityTypes
         on CxAttributeXEntityType.EntityTypeID = EntityTypes.EntityTypeID
 where CxDemographics.disabled = 0
   and not exists (select CDID
                     from dbo.Mstr_Client_Demographics nfpdemog
                    where nfpdemog.CDID = CxDemographics.CDID);



print ' '
print '  Cont: SP_masters_update_client_demographics - Update changed demographics'
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Demographics'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

update nfpdemog
   set CxDemographicName = CxDemographics.CxDemographicName
      ,SiteID = CxDemographics.SiteID
      ,CxDTypeID = CxDemographics.CxDTypeID
      ,CxDType = CxDemographicTypes.CxDType
      ,EntityTypeID = CxAttributeXEntityType.EntityTypeID
      ,EntityType = EntityTypes.EntityType
      ,SequenceOrder = CxDemographics.SequenceOrder
      ,RecordAsNumeric = CxDemographics.RecordAsNumeric
      ,RecordAsArbitraryText = CxDemographics.RecordAsArbitraryText
      ,IsProgramSpecific = CxDemographics.IsProgramSpecific
      ,Disabled = CxDemographics.Disabled
      ,AuditDate = CxDemographics.AuditDate
      ,SharedAcrossEnterprise = CxDemographics.SharedAcrossEnterprise
      ,AcceptAsDataPoint = CxDemographics.AcceptAsDataPoint
      ,CxDescription = CxDemographics.CxDescription
      ,ProgramID = CxDemographics.ProgramID
      ,CustomSettings= CxDemographics.CustomSettings
      ,CDID_Source = CxDemographics.CDID_Source
      ,IsRequired = CxDemographics.IsRequired
  from dbo.Mstr_Client_Demographics nfpdemog
  INNER JOIN ETOSRVR.etosolaris.dbo.CxDemographics CxDemographics
          on CxDemographics.CDID = nfpdemog.CDID
  left join ETOSRVR.etosolaris.dbo.CxDemographicTypes CxDemographicTypes 
       on CxDemographics.CxDTypeid = CxDemographicTypes.CxDTypeid
  left join ETOSRVR.etosolaris.dbo.CxAttributeXEntityType CxAttributeXEntityType
         on CxDemographics.CDID = CxAttributeXEntityType.CDID
  left join ETOSRVR.etosolaris.dbo.EntityTypes EntityTypes
         on CxAttributeXEntityType.EntityTypeID = EntityTypes.EntityTypeID
  where CxDemographics.AuditDate > nfpdemog.AuditDate;


----------------------------------------------------------------------------------------
print ' '
print '  Cont: SP_masters_update_client_demographics - Add New Demographic Choices'
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Maintain Demographic Choices'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

insert into dbo.Mstr_Client_Demographic_Choices
      (CDDTVID
      ,CDID
      ,TextValue
      ,Disabled
      ,SequenceOrder
      ,AuditDate)
    select Cxdtext.CDDTVID
          ,cxD.CDID
          ,Cxdtext.TextValue
          ,Cxdtext.Disabled
          ,Cxdtext.sequenceOrder
          ,Cxdtext.AuditDate
      from etosolaris.dbo.CxDemographicsDefinedTextValues Cxdtext
     inner join etosolaris.dbo.cxDemographics cxD
           on Cxdtext.CDID = cxD.cdid
     where not exists (select CDID 
                         from dbo.Mstr_Client_Demographic_Choices nfpdc
                        where nfpdc.CDDTVID = Cxdtext.CDDTVID)


print ' '
print ' Cont: SP_masters_update_client_demographics - Update Existing Demographic choices'

update dbo.Mstr_Client_Demographic_Choices
   set TextValue = Cxdtext.TextValue
      ,Disabled = Cxdtext.Disabled
      ,SequenceOrder = Cxdtext.sequenceOrder
      ,AuditDate = Cxdtext.AuditDate
  from dbo.Mstr_Client_Demographic_Choices nfpdc
  inner join etosolaris.dbo.CxDemographicsDefinedTextValues Cxdtext
           on Cxdtext.CDDTVID = nfpdc.CDDTVID
  where Cxdtext.AuditDate > nfpdc.AuditDate;


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

print '  End of Process: SP_masters_update_client_demographics'
GO
