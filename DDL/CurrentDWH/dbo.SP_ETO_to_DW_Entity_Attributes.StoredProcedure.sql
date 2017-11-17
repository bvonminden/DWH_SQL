USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_ETO_to_DW_Entity_Attributes]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--drop proc dbo.SP_ETO_to_DW_Entity_Attributes
CREATE PROCEDURE [dbo].[SP_ETO_to_DW_Entity_Attributes]
  @p_type         nvarchar(10),
  @p_forceupdate  bit = 0,
  @p_debug_level  smallint = 0
AS
-- Script to extract all Entity custom attributes as flattened row:
-- EntityID, followed by Attribute collumns labeled as the Attribute.CDID
-- 
-- Parameters:
--   p_type = Entity Type to process (Ind: 22 admin, 16-Ind; Org: 22-Business, null - all)
--   p_forceupdate = null, 1;  1 will trigger all updated regardless of last date updated.
--   p_debug_level = null, 0, 3 
--        (allows ability to display what is being processed, and display sql code
--         null = default display of survey being processed
--         3 = display SQL code

--
-- Steps:
-- Define variables used in process.
-- Defines a query for the basic attribute master indexes.
-- Define an Inner query that extracts the actual attributes.
-- Build a cursor to read and format a list of attribute indexes.
-- Execute a main query (with all the other pieces) extracting a pivot of attributes:

-- Uses DW dbo.view_ETO_Entity_Attributes to consolidate attribute fields by eantity,cdid
-- For non-exclusive attributes, the DW attribute may be flagged to extend the
-- columns out for each available choice.

-- History:
--   20110131 - Changed the attribute_last_update to = max(auditdate) for eto attribute, instead of curr sysdate.
--              problems would arise from ETO changes continuing before this process was actually run, 
--              thus never getting updated to the DW staff record.
--   20130422 - Added logic to excude specific sites via dbo.Sites_Excluded table.
--   20140701 - Changed the way cdxtypeid #4 stores data, from using attribute text sequence to actual text value.
--   20161220 - Added specific qualifier for Attribute 'CRM_ID' tying it specifically to Agency type organization types.
--              This is becuase it's changed to a property type attriute so it doesn't show on the ETO forms, thus preventing
--              ETO from displaying the CRM Account ID to the ETO users.

DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_ENTITY_ATTRIBUTES'


DECLARE @forceupdate	bit
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
DECLARE @Attributes_Last_Updated datetime
DECLARE @TableName          nvarchar(50)
DECLARE @ColumnName         nvarchar(50)
DECLARE @ColumnNameExtended nvarchar(50)
DECLARE @ColumnAttribute    nvarchar(50)
DECLARE @return_stat        int
DECLARE @SQL                nvarchar(2000)

set @forceupdate = 0

print 'Starting procedure SP_ETO_to_DW_Entity_attributes ' +@P_Type +','+convert(varchar,@p_forceupdate)
IF @p_forceupdate = 1
   begin
   set @forceupdate = 1
   print '** forcing update due to run parameter' 
   end

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
-- Build and process cursor for all entity attributes 
-- (updated from ETO to the master DW tbl)
----------------------------------------------------------------------------------------

DECLARE AttributeCursor Cursor for
select CDID
      ,CxDTypeID
      ,case when pseudonym = 'CRM_ID' then 1 else Org_type end
      ,Ind_Type
      ,SequenceOrder
      ,RecordAsNumeric
      ,RecordAsArbitraryText
      ,IsProgramSpecific
      ,Pseudonym
      ,dw_extend_NonExclusive_columns
      ,DW_record_choice_as_seqnbr
      ,Attributes_Last_Updated
  from dbo.Mstr_Entity_Attributes Entity_Attributes
 where (Org_Type = 1 or Ind_Type = 1 or pseudonym = 'CRM_ID')
   and CxDTypeID in (2,3,4,5,6)
   and Pseudonym is not null;

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
          ,@Attributes_Last_Updated

WHILE @@FETCH_STATUS = 0
BEGIN

 IF (upper(@P_Type) = 'ORG') and (@Org_Type = 1)
    set @TableName = 'Agencies'

 ELSE IF (upper(@P_Type) = 'IND') and (@Ind_Type = 1)
    set @TableName = 'IA_Staff'

 ELSE
    set @TableName = null

 IF @TableName is not null
 BEGIN

   set @ColumnName = @Pseudonym

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing pseudonym'
      ,comment = @TableName +'.' + @Pseudonym
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

   IF @CxDTypeID = 1
      set @ColumnAttribute = 'bit null'
   IF @CxDTypeID = 2
      set @ColumnAttribute = 'numeric(15,5) null'
   IF @CxDTypeID IN (3,4,5)
      set @ColumnAttribute = 'nvarchar(2000) null'
   IF @CxDTypeID = (6)
      set @ColumnAttribute = 'datetime null'


   print 'Processing Attribute CDID=' +convert(varchar,@CDID) +', Pseudonym=' +@Pseudonym

----------------------------------------------------------------------------------------
-- process for non-exclusive attributes:
----------------------------------------------------------------------------------------
   IF (@CxDTypeID = 5) and (@dw_extend_NonExclusive_columns = 1)
      BEGIN

--       Initialize the main concatenated field:

--       Check for existing table column, add one if not already found:
         EXEC @return_stat = dbo.SP_add_nonexisting_tbl_column @TableName,@ColumnName,@ColumnAttribute

         IF @forceupdate = 1
            BEGIN
               set @SQL= 'set nocount on UPDATE  dbo.'+ @TableName + ' set [' + Left(@ColumnName,100)+ '] = null
                ,flag_update_CRM = 1
                where [' + Left(@ColumnName,100)+ '] is not null'
            END
         ELSE
            BEGIN

               set @SQL = ''
               IF @p_debug_Level = 0
                  set @SQL = 'set nocount on '

               set @SQL= @SQL +'UPDATE  dbo.'+ @TableName + ' set [' + Left(@ColumnName,100)+ '] = null
                ,flag_update_CRM = 1
                FROM  dbo.' + @TableName + ' 
                where [' + Left(@ColumnName,100)+ '] is not null
                  and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = ' + @TableName + '.Site_Id)
                  and (select isnull(max(auditdate),CONVERT(datetime,''20990101'',112)) 
                         from dbo.view_ETO_Entity_Attributes veea
                        where veea.CDID = ' +convert(varchar,@CDID) +'
                          and veea.EntityID = ' +@TableName +'.Entity_ID)
                       >=  convert(datetime,'''
                  +convert(varchar,isnull(@Attributes_Last_Updated,CONVERT(datetime,'19690101',112)),120) +''',120)'
            END

         IF @p_debug_level = 3
            Print @SQL
         exec (@SQL)


--       Build and process cursor for choices:

         DECLARE @CDDTVID	int
         DECLARE @ChoiceSequenceOrder	smallint
         DECLARE @TextValue	nvarchar(100)

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
               into @CDDTVID
                   ,@ChoiceSequenceOrder
                   ,@TextValue

         WHILE @@FETCH_STATUS = 0
         BEGIN


            IF @ChoiceSequenceOrder is null
               set @ColumnNameExtended = @ColumnName
            ELSE
            BEGIN
               set @ColumnNameExtended = @ColumnName +'_' +convert(varchar,@ChoiceSequenceOrder)

--             Check for existing table column, add one if not already found:
               EXEC @return_stat = dbo.SP_add_nonexisting_tbl_column @TableName,@ColumnNameExtended,@ColumnAttribute
            END


            set @SQL = ''
            IF @p_debug_Level = 0
               set @SQL = 'set nocount on '

            set @SQL= @SQL +'UPDATE  dbo.'+ @TableName + ' set [' + Left(@ColumnNameExtended,100)+ '] = '

            IF @DW_record_choice_as_seqnbr = 1 and @ChoiceSequenceOrder is not null
               BEGIN
                  set @SQL = @SQL + ' case when veea.ChoiceSequence = ' +convert(varchar,@ChoiceSequenceOrder) 
                         +' then  veea.ChoiceSequence else null end'
               END
            ELSE
               BEGIN
                  IF @ChoiceSequenceOrder is not null
                     set @SQL = @SQL + ' case when veea.ChoiceSequence = ' +convert(varchar,@ChoiceSequenceOrder)
                        +'  then  veea.TextValue else null end'
                  ELSE
                     set @SQL = @SQL + ' case when veea.TextValue = ''' +@TextValue +'''
                        then left(isnull([' + Left(@ColumnNameExtended,100)+ ']  + ''; '','''') +veea.TextValue,2000) 
                        else  [' + Left(@ColumnNameExtended,100)+ '] end'
               END



            set @SQL = @SQL + ' ,flag_update_CRM = 1
             FROM  dbo.' + @TableName + ' 
             INNER JOIN dbo.view_ETO_Entity_Attributes veea
                   on veea.EntityID = ' +@TableName +'.Entity_ID
             where veea.CDID = ' +convert(varchar,@CDID)

             set @SQL = @SQL + ' and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = ' + @TableName + '.Site_Id) '

            IF @forceupdate != 1
               BEGIN
               set @SQL = @SQL +'
                  and isnull(veea.AuditDate,convert(datetime,''19700101'',112)) > convert(datetime,'''
                   +convert(varchar,isnull(@Attributes_Last_Updated,CONVERT(datetime,'19690101',112)),120) +''',120)'
-- commented section
--                  and ((isnull(veea.AuditDate,convert(datetime,''19690101'',112)) >= isnull(' +@TableName +'.Audit_Date,CONVERT(datetime,''19700101'',112)) ) or
--                       (isnull(' +@TableName +'.Audit_Date,convert(datetime,''19700101'',112)) >= convert(datetime,'''
--                        +convert(varchar,isnull(@Attributes_Last_Updated,CONVERT(datetime,'19690101',112)),120) +''',120)))'

               END

            IF @p_debug_level = 3
               Print @SQL
            exec (@SQL)



            FETCH next from ChoiceCursor
                  into @CDDTVID
                      ,@ChoiceSequenceOrder
                      ,@TextValue

         END -- End while loop for choices

         CLOSE ChoiceCursor
         DEALLOCATE ChoiceCursor

      END -- End process for non-exclusive

----------------------------------------------------------------------------------------
-- process for all other attribute types:
----------------------------------------------------------------------------------------
   ELSE
      BEGIN

--       If type is non-exclusive and not flagged for column extending,
--       then concatenate all values:
--         IF @CxDTypeID IN (5)

--       Check for existing table column, add one if not already found:
         EXEC @return_stat = dbo.SP_add_nonexisting_tbl_column @TableName,@ColumnName,@ColumnAttribute

--       Create and execute a SQL script to process all updates:
         set @SQL = ''
         IF @p_debug_Level = 0
            set @SQL = 'set nocount on '

         set @SQL= @SQL +'UPDATE  dbo.'+ @TableName + ' set [' + Left(@ColumnName,100)+ '] = '
         
         IF @CxDtypeID in (1)
           set @SQL = @SQL + 'left(veea.TextValue,1)'
         IF @CxDtypeID in (2)
--           set @SQL = @SQL + 'cast( veea.TextValue as int)'
           set @SQL = @SQL + 'dbo.fnCleanNumericString(left(veea.TextValue,1000))'
         IF @CxDtypeID in (3,5)
           set @SQL = @SQL + 'veea.TextValue'
         IF @CxDtypeID = 6
           set @SQL = @SQL + 'veea.DateValue'
         IF @CxDtypeID in (4)
           set @SQL = @SQL + 'veea.TextValue'
           --set @SQL = @SQL + 'isnull(convert(varchar,veea.TextSequence),veea.TextValue)'

         set @SQL = @SQL + ' ,flag_update_CRM = 1
          FROM  dbo.' + @TableName + ' 
          INNER JOIN dbo.view_ETO_Entity_Attributes veea
                on veea.EntityID = ' +@TableName +'.Entity_ID
          where veea.CDID = ' +convert(varchar,@CDID)

         set @SQL = @SQL + ' and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = ' + @TableName + '.Site_Id) '

         IF @forceupdate != 1
            BEGIN
               set @SQL = @SQL +'
                  and isnull(veea.AuditDate,convert(datetime,''19700101'',112)) > convert(datetime,'''
                   +convert(varchar,isnull(@Attributes_Last_Updated,CONVERT(datetime,'19690101',112)),120) +''',120)'
-- commented section
--                  and ((isnull(veea.AuditDate,convert(datetime,''19690101'',112)) >= isnull(' +@TableName +'.Audit_Date,CONVERT(datetime,''19700101'',112)) ) or
--                       (isnull(' +@TableName +'.Audit_Date,convert(datetime,''19700101'',112)) >= convert(datetime,'''
--                        +convert(varchar,isnull(@Attributes_Last_Updated,CONVERT(datetime,'19690101',112)),120) +''',120)))'
            END

         IF @p_debug_level = 3
            Print @SQL
         exec (@SQL)

      END -- End process for all other attributes

-- Wrap up by updating the Attributes_Last_Update with the current date:
   print '  Wrapup - Updating Mstr_Entity_Attributes.Attributes_last_updated'
   update dbo.Mstr_Entity_Attributes
      set Attributes_last_updated = 
            (select MAX(AuditDate)
               from dbo.view_ETO_Entity_Attributes veea
              where veea.CDID = @CDID)
    where CDID = @CDID;

 END  /* check for @tablename is not null */

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
             ,@Attributes_Last_Updated

END -- End of AttributeCursor loop

CLOSE AttributeCursor
DEALLOCATE AttributeCursor

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------


print 'EOJ - SP_ETO_to_DW_Entity_Attributes'
GO
