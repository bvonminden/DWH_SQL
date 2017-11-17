USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_ETO_to_DW_Entity_Attributes_Staff]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_ETO_to_DW_Entity_Attributes_Staff
CREATE PROCEDURE [dbo].[SP_ETO_to_DW_Entity_Attributes_Staff]
  @p_entity_id    int = null,
  @p_debug_level  smallint = 0
AS
-- This script controls the update of Staff Entity Attributes.  
--
-- Step 1: Validate that all inteded Entity Attributes are created as columns in IA_Staff table.
-- Step 2: Extract all IA_Staff records who's Last_Attribute_Update has been exceeded by
--         an ETO attribute change occuring based upon it's AuditDate.  
--         (or extract explicit Entity from runtime parm)
-- Step 3: Create a cursor of all Entity Attributes which pertain to Staff.
-- Step 4: Process the IA_Staff record by building an SQL update statement for all attributes.
--         (creates one SQL statement to update the entire group of attributes for an entity,
--          will update all attributes setting to null for any not selected within ETO)
--
--
-- Parameters:
--   p_entity_id = option to process just one entity  (default null for all IA_Staff with changes)
--                 When used, the entity_id specified will will force their entire attributes 
--                 to update regardless of last_attribut_update date.
--   p_debug_level = null, 0, 3 
--        (allows ability to display what is being processed, and display sql code
--         null = default display of survey being processed
--         3 = display SQL code
--
--
-- ** Uses View - dbo.view_ETO_Entity_Attributes to consolidate attribute fields by entity,cdid
-- For non-exclusive attributes, the DW attribute may be flagged to extend the
-- columns out for each available choice.
--
--
-- History:
--   20110613 - Re-write of original process (sp_eto_to_dw_entity_attributes) to process by employee
--              utilizing the new date field: IA_Staff.Last_Attribute_Update.  This will force an entire
--              update to the staff record for anytime any of their attributes change, and to allow for re-sync.
--   20110722 - Changed non-exclusive data lookup on clid,cdid,cddtvid (using cddtvid instead of seqnumber).
--   20111020 - Changed how the data type 'directed value' is stored in DW, changing from seq# to actual text value.
--   20111222 - Added replace statement to text values to remove imbedded quotes.
--   20120905 - Re-established source code from production stored procedure.
--              Changed attribute selection based upon the dbo.mstr_entity_attribute.DW_TableName = 'IA_Staff'. 
--   20130418 - Changed the stripping of imbedded single quotes from text values,
--              to replacing instead with an MS-Word apostrophe.
--   20130422 - Added logic to exclude specific sites via dbo.Sites_Excluded table.
--   20140212 - Added logic to ignore excluded sites when the 'IA_STAFF' is included in the tables_to_ignore field.


DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_ENTITY_ATTRIBUTES_STAFF'


DECLARE @entity_Id	int
DECLARE @CDID		int
DECLARE @CxDTypeID	int
DECLARE @Org_type	bit
DECLARE @Ind_type	bit
DECLARE @SequenceOrder	smallint
DECLARE @RecordAsNumeric	bit
DECLARE @RecordAsArbitraryText	bit
DECLARE @IsProgramSpecific  bit
DECLARE @Pseudonym          nvarchar(50)
DECLARE @dw_extend_NonExclusive_columns bit
DECLARE @DW_record_choice_as_seqnbr	bit
DECLARE @veea_entityid      int
DECLARE @veea_textvalue     nvarchar(2000)
DECLARE @veea_datevalue     smalldatetime
DECLARE @veea_choicesequence  smallint
DECLARE @veea_TextSequence    smallint
DECLARE @Last_Attribute_Update datetime
DECLARE @max_Attribute_Auditdate datetime
DECLARE @ColumnName         nvarchar(50)
DECLARE @ColumnNameExtended nvarchar(50)
DECLARE @ColumnAttribute    nvarchar(50)
DECLARE @return_stat        int
DECLARE @SQL                varchar(8000)
DECLARE @concatfield        nvarchar(2000)
DECLARE @colctr             int
DECLARE @fldctr             int
DECLARE @itemctr            int


print 'Starting procedure SP_ETO_to_DW_Entity_Attributes_Staff, p_entity_id='+convert(varchar,@p_entity_Id)

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


-- Validate that all columns exist for attributes/choices, if not process will add column.
exec dbo.SP_Validate_Entity_Attribute_Columns 'IA_Staff'

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- Build a cursor of entities that have attributes found to have been changed
-- since the last_attribute_update 
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

DECLARE EntityCursor Cursor for
select IA_Staff.Entity_ID
      ,CASE when @p_entity_id is not null then CONVERT(datetime,'19690101',112)
            else isnull(IA_Staff.Last_Attribute_Update,CONVERT(datetime,'19690101',112)) END
      ,isnull(MAX(veea.auditdate),CONVERT(datetime,'19690101',112))
  from dbo.IA_Staff 
  inner join dbo.view_ETO_Entity_Attributes veea
          on IA_Staff.Entity_ID = veea.EntityID
 where isnull(@p_entity_id,99999999) in (99999999,IA_Staff.Entity_ID)
   and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = IA_Staff.Site_Id
                      and isnull(ex2.tables_to_ignore,'') not like '%IA_STAFF%')
 group by IA_Staff.Entity_ID,Last_Attribute_Update 


OPEN EntityCursor

FETCH next from EntityCursor
      into @entity_id
          ,@last_attribute_update
          ,@max_attribute_auditdate

WHILE @@FETCH_STATUS = 0
BEGIN

IF @p_entity_id is not null or
   @last_attribute_update < @max_attribute_auditdate
   BEGIN


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing Entity'
      ,comment = 'IA_Staff'
      ,LogDate = getdate()
      ,Index_1 = @entity_id
 where Process = @process
---------------------------------------------

----------------------------------------------------------------------------------------
-- Build and process cursor for all entity attributes 
-- (grab only the attributes selected by the entity)
----------------------------------------------------------------------------------------

-- Initilize the beginning of the SQL statement, zero column counter:

set @SQL = ''

IF @p_debug_Level = 0
   set @SQL = 'set nocount on '

set @SQL= @SQL +'UPDATE  dbo.IA_Staff set '
set @colctr = 0


DECLARE AttributeCursor Cursor for
select mea.CDID
      ,mea.CxDTypeID
      ,mea.Org_Type
      ,mea.Ind_Type
      ,mea.SequenceOrder
      ,mea.RecordAsNumeric
      ,mea.RecordAsArbitraryText
      ,mea.IsProgramSpecific
      ,mea.Pseudonym
      ,mea.dw_extend_NonExclusive_columns
      ,mea.DW_record_choice_as_seqnbr
  from dbo.Mstr_Entity_Attributes mea
 where upper(mea.DW_TableName) = 'IA_STAFF'
   --(mea.Org_Type = 1 for Agencies; Ind_Type = 1 for staff)
   and mea.CxDTypeID in (2,3,4,5,6)
   and mea.Pseudonym is not null;

-- CXDTypeID: 1=Boolean, 2=Numeric, 3=Arbitrary Text, 4=Defined Text Values,
--            5=Non-Exclusive Choices, 6= Date

OPEN AttributeCursor

FETCH next from AttributeCursor
      into @CDID
          ,@CxDTypeID
          ,@Org_Type
          ,@Ind_Type
          ,@SequenceOrder
          ,@RecordAsNumeric
          ,@RecordAsArbitraryText
          ,@IsProgramSpecific
          ,@Pseudonym
          ,@dw_extend_NonExclusive_columns
          ,@DW_record_choice_as_seqnbr

WHILE @@FETCH_STATUS = 0
BEGIN

   set @ColumnName = @Pseudonym

   IF @CxDTypeID = 1
      set @ColumnAttribute = 'bit null'
   IF @CxDTypeID = 2
      set @ColumnAttribute = 'numeric(15,5) null'
   IF @CxDTypeID IN (3,4,5)
      set @ColumnAttribute = 'nvarchar(2000) null'
   IF @CxDTypeID = (6)
      set @ColumnAttribute = 'datetime null'

   IF @p_debug_level = 3
      print 'Processing Attribute CDID=' +convert(varchar,@CDID) +', Pseudonym=' +@Pseudonym

----------------------------------------------------------------------------------------
-- process for non-exclusive attributes:
--       Initialize the basic update SQL statement and concatenated work field.
--       Then when build a cursor of selected choices, creating either one concatenated field
--         or multiple SQL 'set' statetments for corresponding columns per choice.
--       Once cursor is completed, finalize the update SQL statement and execute it.
----------------------------------------------------------------------------------------
   IF (@CxDTypeID = 5)
      BEGIN

--       Build a cursor for selected choices 
--       then then concatenate the choices into one  field,
--       also if flagged to extend the choices as individual columns,
--       create indiividual SQL set statements where for each unique column/choice:

         set @concatfield = '[' + Left(@ColumnName,100) +'] = NULL'
         set @fldctr = 0

         DECLARE @mstr_CDDTVID	int
         DECLARE @mstr_ChoiceSequenceOrder	smallint
         DECLARE @mstr_TextValue	nvarchar(100)

         DECLARE ChoiceCursor  Cursor for
         select CDDTVID
               ,CxAttributesDefinedTextValues.SequenceOrder
               ,CxAttributesDefinedTextValues.TextValue
           from dbo.Mstr_Entity_Attributes Entity_Attributes
           left join ETOSRVR.etosolaris.dbo.CxAttributesDefinedTextValues CxAttributesDefinedTextValues
                  on Entity_Attributes.CDID = CxAttributesDefinedTextValues.CDID
          where Entity_Attributes.CDID = @CDID
            and CxAttributesDefinedTextValues.Disabled = 0
          order by SequenceOrder;

         OPEN ChoiceCursor

         FETCH next from ChoiceCursor
               into @mstr_CDDTVID
                   ,@mstr_ChoiceSequenceOrder
                   ,@mstr_TextValue

         WHILE @@FETCH_STATUS = 0
         BEGIN

--          Get the actual corresponding attribute value for the Entity
--          (no data will be returned if choice not selected for entity)
            set @veea_entityid = null
            set @veea_textvalue = null
            set @veea_datevalue = null
            set @veea_textsequence = null
            set @veea_choicesequence = null

            select @veea_entityid = veea.entityid
                  ,@veea_choicesequence = veea.choicesequence
              from dbo.view_ETO_Entity_Attributes veea
             where veea.EntityID = @entity_id
               and veea.cdid = @cdid
               and veea.CDDTVID = @mstr_CDDTVID


            IF @dw_extend_NonExclusive_columns = 1 and @mstr_ChoiceSequenceOrder is not null
               -- update choice responses to individual columns
               BEGIN

                  set @ColumnNameExtended = @ColumnName +'_' +convert(varchar,@mstr_ChoiceSequenceOrder)

                  set @colctr = @colctr + 1
                  IF @colctr != 1
                     -- multiple columns being updated, add comma separator
                     set @SQL = @SQL + ', '

                  set @SQL = @SQL +' [' + Left(@ColumnNameExtended,100)+ '] = '

                  IF @veea_entityid is null
                     -- initialize non-selected attribute to null
                     set @SQL = @SQL +'NULL'
                  ELSE
                     BEGIN
                        IF @DW_record_choice_as_seqnbr = 1
                           set @SQL = @SQL + convert(varchar,@veea_choiceSequence)
                        ELSE
                           set @SQL = @SQL +'''' +@mstr_textvalue +''''
                     END
               END


            -- update choice, appended into one main field
            IF @veea_entityid is not null
               BEGIN
                  set @fldctr = @fldctr + 1

                  -- Special bypass to not concatenate NURSE_0_PROGRAM_POSITION (used for special CRM matchup)
                  IF @ColumnName != 'NURSE_0_PROGRAM_POSITION'
                   BEGIN
                     IF @fldctr = 1
                        -- initialize with column name to update
                        set @concatfield = ' [' + Left(@ColumnName,100)+ '] = ''' 
                     ELSE
                        -- multiple fields being concatenated, add colon separator within concatenation
                        set @concatfield = @concatfield +';' 

                     IF @DW_record_choice_as_seqnbr = 1 and @mstr_ChoiceSequenceOrder is not null
                        set @concatfield = @concatfield + convert(varchar,@mstr_ChoiceSequenceOrder)
                     ELSE
                        set @concatfield = @concatfield + @mstr_TextValue
                   END
                  ELSE
                   BEGIN
                     -- last field only:
                     IF @DW_record_choice_as_seqnbr = 1 and @mstr_ChoiceSequenceOrder is not null
                        set @concatfield = ' [' + Left(@ColumnName,100)+ '] = ''' +convert(varchar,@mstr_ChoiceSequenceOrder)
                     ELSE
                        set @concatfield = ' [' + Left(@ColumnName,100)+ '] = ''' +@mstr_TextValue
                   END

               END

            FETCH next from ChoiceCursor
                  into @mstr_CDDTVID
                      ,@mstr_ChoiceSequenceOrder
                      ,@mstr_TextValue

         END -- End while loop for choices

         CLOSE ChoiceCursor
         DEALLOCATE ChoiceCursor


         -- add the final concatenation to the SQL statement:
         set @colctr = @colctr + 1
         IF @colctr != 1
            -- not the first column in SQL statement, add comma separator
            set @SQL = @SQL +',' +@concatfield
         ELSE
            set @SQL = @SQL +@concatfield 

         IF @fldctr != 0 
            -- add closing quote (only if date has been suppied)
            set @SQL = @SQL +''''


      END -- End process for non-exclusive

----------------------------------------------------------------------------------------
-- process for all other attribute types:
----------------------------------------------------------------------------------------
   ELSE
      BEGIN

--       CXDTypeID: 1=Boolean, 2=Numeric, 3=Arbitrary Text, 4=Defined Text Values,
--                  5=Non-Exclusive Choices, 6= Date

--       Get the actual attribute value for the Entity:
         set @veea_entityid = null
         set @veea_textvalue = null
         set @veea_datevalue = null
         set @veea_textsequence = null

         select @veea_entityid = veea.entityid
               ,@veea_textvalue = veea.textvalue
               ,@veea_datevalue = veea.datevalue
               ,@veea_textsequence = veea.textsequence
           from dbo.view_ETO_Entity_Attributes veea
          where veea.EntityID = @entity_id
            and veea.cdid = @cdid


         set @colctr = @colctr + 1
         IF @colctr != 1
            -- not the first column in SQL statement, add comma separator
            set @SQL = @SQL + ','

         set @SQL= @SQL +'[' + Left(@ColumnName,100)+ '] = '

         IF @veea_entityid is null 
            -- No selection made for attribute, default to null
            set @SQL = @SQL +'NULL'
         ELSE
         BEGIN
            IF @CxDtypeID in (1)
              set @SQL = @SQL +'''' +left(@veea_TextValue ,1) +''''
            IF @CxDtypeID in (2)
              set @SQL = @SQL +convert(varchar,dbo.fnCleanNumericString(@veea_TextValue))
            IF @CxDtypeID in (3,4,5)
              set @SQL = @SQL +'''' +replace(@veea_TextValue,char(39),'’') +''''
            IF @CxDtypeID = 6
              set @SQL = @SQL  +'convert(datetime,''' +convert(varchar,@veea_DateValue,120) +''',120)'
           -- changed to text instead 10/20/2011
           -- IF @CxDtypeID in (4)
           --   set @SQL = @SQL +'''' +isnull(convert(varchar,@veea_TextSequence),@veea_TextValue) +''''
         END

      END -- End process for all other attributes


   FETCH next from AttributeCursor
         into @CDID
             ,@CxDTypeID
             ,@Org_Type
             ,@Ind_Type
             ,@SequenceOrder
             ,@RecordAsNumeric
             ,@RecordAsArbitraryText
             ,@IsProgramSpecific
             ,@Pseudonym
             ,@dw_extend_NonExclusive_columns
             ,@DW_record_choice_as_seqnbr

END -- End While for AttributeCursor loop

CLOSE AttributeCursor
DEALLOCATE AttributeCursor

-- wrapup the SQL statement, the execute:
-- (add Last_Attribute_Update with the max attribute change date, set trigger to update CRM)

         
   IF @colctr != 0
   BEGIN
       set @SQL = @SQL +',flag_update_CRM = 1,Last_Attribute_Update = ' 
           +'convert(datetime,''' +convert(varchar,@max_attribute_auditdate,113) +''',113)'
           +' FROM  dbo.IA_Staff where Entity_ID = ' +convert(varchar, @entity_id)
             
       IF @p_debug_level = 3
           Print @SQL
       exec (@SQL)
   END


END  -- go/no go validation prior to attributes cursor, for selected staff or actual auditdate change

-------------------------------------
-- Continue with next Entity Record:
-------------------------------------

FETCH next from EntityCursor
      into @entity_id
          ,@last_attribute_update
          ,@max_attribute_auditdate


END -- End While for EntityCursorloop

CLOSE EntityCursor
DEALLOCATE EntityCursor


---------------------------------------------
--   wrapup with update to Process Log     --
---------------------------------------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

print 'EOJ - SP_ETO_to_DW_Entity_Attributes_Staff'

GO
