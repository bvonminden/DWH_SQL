USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_Validate_Entity_Attribute_Columns]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_Validate_Entity_Attribute_Columns
CREATE PROCEDURE [dbo].[SP_Validate_Entity_Attribute_Columns]
  @p_tablename    varchar(30) = null,
  @p_debug_level  smallint = 0
AS

-- This procedure validates that all Master Entity Attributes exist as columns in the Data Warehouse Table. 
-- If they do no, than a new column is added with the master field attributes for the defined pseudonym.
--
-- History:
--   20110614 - New Procedure created.
--   20120831 - Added table processing for Teams.
--              Added specific DW_TableName to the MSTR_Attributes table.


DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_VALIDATE_ENTITY_ATTRIBUTE_COLUMNS'


DECLARE @tablename	varchar(50)
DECLARE @CDID		int
DECLARE @CxDTypeID	int
DECLARE @Org_type	bit
DECLARE @Ind_type	bit
DECLARE @RecordAsNumeric	bit
DECLARE @RecordAsArbitraryText	bit
DECLARE @IsProgramSpecific  bit
DECLARE @Pseudonym          nvarchar(50)
DECLARE @dw_tablename       nvarchar(50)
DECLARE @dw_extend_NonExclusive_columns bit
DECLARE @ColumnName         nvarchar(50)
DECLARE @ColumnNameExtended nvarchar(50)
DECLARE @ColumnAttribute    nvarchar(50)
DECLARE @mstr_CDDTVID	    int
DECLARE @mstr_ChoiceSequenceOrder smallint
DECLARE @return_stat        int
DECLARE @SQL                varchar(8000)


print 'Starting procedure SP_Validate_Entity_Attribute_Columns, p_tablename= '+isnull(@p_tablename,'')

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
-- Build a cursor of entities attributes
-- since the last_attribute_update 
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

DECLARE AttributeCursor Cursor for
select mea.CDID
      ,mea.CxDTypeID
      ,mea.Org_Type
      ,mea.Ind_Type
      ,mea.RecordAsNumeric
      ,mea.RecordAsArbitraryText
      ,mea.IsProgramSpecific
      ,mea.Pseudonym
      ,mea.dw_extend_NonExclusive_columns
      ,mea.DW_TableName
  from dbo.Mstr_Entity_Attributes mea
 where mea.DW_TableName is not null
   -- and (mea.Org_Type = 1 or Ind_Type = 1)
   and mea.CxDTypeID in (2,3,4,5,6,7,8)
   and mea.Pseudonym is not null;

-- CXDTypeID: 1=Boolean, 2=Numeric, 3=Arbitrary Text, 4=Defined Text Values,
--            5=Non-Exclusive Choices, 6=Date, 7=Arbitrary Text Area,
--            8=Entity Cross Reference
--            (etosolaris.dbo.cxattributetypes)

OPEN AttributeCursor

FETCH next from AttributeCursor
      into @CDID
          ,@CxDTypeID
          ,@Org_Type
          ,@Ind_Type
          ,@RecordAsNumeric
          ,@RecordAsArbitraryText
          ,@IsProgramSpecific
          ,@Pseudonym
          ,@dw_extend_NonExclusive_columns
          ,@dw_tablename

WHILE @@FETCH_STATUS = 0
BEGIN


 IF (upper(@p_tablename) = 'AGENCIES') and (upper(@dw_tablename) = 'AGENCIES')
    set @TableName = 'Agencies'

 ELSE IF (upper(@p_tablename) = 'TEAMS') and (upper(@dw_tablename) = 'TEAMS')
    set @TableName = 'Teams'

 ELSE IF (upper(@P_tablename) = 'IA_STAFF') and (upper(@dw_tablename) = 'IA_STAFF')
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
      ,comment = @tablename +'.' +@Pseudonym
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

   IF @CxDTypeID = 1
      set @ColumnAttribute = 'bit null'
   IF @CxDTypeID = 2
      set @ColumnAttribute = 'numeric(15,5) null'
   IF @CxDTypeID IN (3,4,5,7)
      set @ColumnAttribute = 'nvarchar(2000) null'
   IF @CxDTypeID = (6)
      set @ColumnAttribute = 'datetime null'
   IF @CxDTypeID = (8)
      set @ColumnAttribute = 'int'

   IF @p_debug_level = 3
      print 'Processing Attribute CDID=' +convert(varchar,@CDID) +', Pseudonym=' +@Pseudonym

-- Check for existing table column, add one if not already found:
   EXEC @return_stat = dbo.SP_add_nonexisting_tbl_column @tablename,@ColumnName,@ColumnAttribute

----------------------------------------------------------------------------------------
-- process for non-exclusive attributes that are recorded as unique columns
----------------------------------------------------------------------------------------
   IF (@CxDTypeID = 5) and (@dw_extend_NonExclusive_columns = 1)
      BEGIN


         DECLARE ChoiceCursor  Cursor for
         select CDDTVID
               ,CxAttributesDefinedTextValues.SequenceOrder
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

         WHILE @@FETCH_STATUS = 0
         BEGIN

            IF @mstr_ChoiceSequenceOrder is not null
               BEGIN

                  set @ColumnNameExtended = @ColumnName +'_' +convert(varchar,@mstr_ChoiceSequenceOrder)

--                Check for existing table column, add one if not already found:
                  EXEC @return_stat = dbo.SP_add_nonexisting_tbl_column  @tablename,@ColumnNameExtended,@ColumnAttribute

               END

            FETCH next from ChoiceCursor
                  into @mstr_CDDTVID
                      ,@mstr_ChoiceSequenceOrder

         END -- End while loop for choices

         CLOSE ChoiceCursor
         DEALLOCATE ChoiceCursor

      END -- End process for non-exclusive

 END -- End validation for proper table/entity attribute

   FETCH next from AttributeCursor
         into @CDID
             ,@CxDTypeID
             ,@Org_Type
             ,@Ind_Type
             ,@RecordAsNumeric
             ,@RecordAsArbitraryText
             ,@IsProgramSpecific
             ,@Pseudonym
             ,@dw_extend_NonExclusive_columns
             ,@dw_tablename

END -- End While for AttributeCursor loop

CLOSE AttributeCursor
DEALLOCATE AttributeCursor


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

print 'EOJ - SP_Validate_Entity_Attribute_Columns'

GO
