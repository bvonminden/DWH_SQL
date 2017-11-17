USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_masters_update_entity_attributes]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_masters_update_entity_attributes
--
CREATE PROCEDURE [dbo].[SP_masters_update_entity_attributes]
AS
--
-- This script controls the replicated Entity Attributes master table in the Data Warehouse.
--
-- Table effected - dbo.Mstr_Entity_Attributes
--
-- Insert: select and insert when ETO attribute is found to be missing in the DW.
-- Update: select and update when ETO attribute exists in DW and has been changed in ETO.

-- History:
--   20161003 - Added IsRequired.

DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_MASTERS_UPDATE_ENTITY_ATTRIBUTES'

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
print 'Process SP_masters_update_entity_attributes - Insert non-existing attributes'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Attributes'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

insert into dbo.Mstr_Entity_Attributes
      (CDID
      ,CxAttributeName
      ,SiteID
      ,CxDTypeID
      ,CxDType
      ,Org_Type
      ,Ind_Type
      ,SequenceOrder
      ,RecordAsNumeric
      ,RecordAsArbitraryText
      ,IsProgramSpecific
      ,Disabled
      ,IsRequired
      ,AuditDate)
select CxAttributes.CDID
      ,CxAttributes.CxAttributeName
      ,CxAttributes.SiteID
      ,CxAttributes.CxDTypeID
      ,CxAttributeTypes.CxDType
      ,dbo.FN_Attrib_Entity_Type_In(CxAttributes.CDID,'org')
      ,dbo.FN_Attrib_Entity_Type_In(CxAttributes.CDID,'ind')
      ,CxAttributes.SequenceOrder
      ,CxAttributes.RecordAsNumeric
      ,CxAttributes.RecordAsArbitraryText
      ,CxAttributes.IsProgramSpecific
      ,CxAttributes.Disabled
      ,CxAttributes.IsRequired
      ,CxAttributes.AuditDate
  from ETOSRVR.etosolaris.dbo.CxAttributes CxAttributes
  left join ETOSRVR.etosolaris.dbo.CxAttributeTypes CxAttributeTypes 
       on CxAttributes.CxDTypeid = CxAttributeTypes.CxDTypeid
 where CxAttributes.disabled = 0
   and not exists (select CDID
                     from dbo.Mstr_Entity_Attributes nfpattrib
                    where nfpattrib.CDID = CxAttributes.CDID);


print ' '
print '  Cont: SP_masters_update_entity_attributes - Update changed attributes'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Attributes'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

update nfpattrib
   set CxAttributeName = CxAttributes.CxAttributeName
      ,SiteID = CxAttributes.SiteID
      ,CxDTypeID = CxAttributes.CxDTypeID
      ,CxDType = CxAttributeTypes.CxDType
      ,Org_type = dbo.FN_Attrib_Entity_Type_In(CxAttributes.CDID,'org')
      ,Ind_type = dbo.FN_Attrib_Entity_Type_In(CxAttributes.CDID,'ind')
      ,SequenceOrder = CxAttributes.SequenceOrder
      ,RecordAsNumeric = CxAttributes.RecordAsNumeric
      ,RecordAsArbitraryText = CxAttributes.RecordAsArbitraryText
      ,IsProgramSpecific = CxAttributes.IsProgramSpecific
      ,Disabled = CxAttributes.Disabled
      ,IsRequired = CxAttributes.IsRequired
      ,AuditDate = CxAttributes.AuditDate
  from dbo.Mstr_Entity_Attributes nfpattrib
  INNER JOIN ETOSRVR.etosolaris.dbo.CxAttributes CxAttributes
          on CxAttributes.CDID = nfpattrib.CDID
  left join ETOSRVR.etosolaris.dbo.CxAttributeTypes CxAttributeTypes 
       on CxAttributes.CxDTypeid = CxAttributeTypes.CxDTypeid
  where CxAttributes.AuditDate > nfpattrib.AuditDate;


print ' '
print '  Cont: SP_masters_update_entity_attributes - Update non-existing attribute choices'

insert into dbo.Mstr_Entity_Attribute_Choices
      (CDDTVID
      ,CDID
      ,TextValue
      ,Disabled
      ,SequenceOrder
      ,AuditDate)
    select cxatext.CDDTVID
          ,cxa.CDID
          ,cxatext.TextValue
          ,cxatext.Disabled
          ,cxatext.sequenceOrder
          ,cxatext.AuditDate
      from ETOSRVR.etosolaris.dbo.CxAttributesDefinedTextValues cxatext
     inner join ETOSRVR.etosolaris.dbo.CxAttributes cxa
           on cxatext.CDID = cxa.cdid
     where not exists (select CDID 
                         from dbo.Mstr_Entity_Attribute_Choices nfpac
                        where nfpac.CDDTVID = cxatext.CDDTVID)


print ' '
print '  Cont: SP_masters_update_entity_attributes - Update changed attribute choices'

update dbo.Mstr_Entity_Attribute_Choices
   set TextValue = cxatext.TextValue
      ,Disabled = cxatext.Disabled
      ,SequenceOrder = cxatext.sequenceOrder
      ,AuditDate = cxatext.AuditDate
  from dbo.Mstr_Entity_Attribute_Choices nfpac
  inner join ETOSRVR.etosolaris.dbo.CxAttributesDefinedTextValues cxatext
           on cxatext.CDDTVID = nfpac.CDDTVID
  where cxatext.AuditDate > nfpac.AuditDate;

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

print '  End of Process: SP_masters_update_entity_attributes'
GO
