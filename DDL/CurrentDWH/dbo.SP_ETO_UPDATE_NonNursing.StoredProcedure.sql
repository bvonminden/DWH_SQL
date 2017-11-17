USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_ETO_UPDATE_NonNursing]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_ETO_UPDATE_NonNursing
--
CREATE PROCEDURE [dbo].[SP_ETO_UPDATE_NonNursing]
AS
--
-- This is a special update process for the real ETO database at SSI
-- to ammend specific original converted data

DECLARE @count			smallint
DECLARE @insert_count		smallint
DECLARE @update_count		smallint
DECLARE @update_isindividual	smallint
DECLARE @update_contacts	smallint
DECLARE @update_entityid	smallint
DECLARE @bypassed_count		smallint
DECLARE @cursor_count		int
DECLARE @transaction_count	int
set @insert_count = 0
set @update_count = 0
set @update_isindividual = 0
set @update_contacts = 0
set @update_entityID = 0
set @bypassed_count = 0
set @cursor_count = 0
set @transaction_count = 0

DECLARE @bypass_flag nvarchar(2)

DECLARE @recid		int
DECLARE @entity_id	int
DECLARE @entity_name	nvarchar(100)
DECLARE @email		nvarchar(100)
DECLARE @address1	nvarchar(50)
DECLARE @address2	nvarchar(50)
DECLARE @zipcode	nvarchar(10)
DECLARE @EntityContactID int
DECLARE @IsIndividual	bit


print 'Processing SP_ETO_UPDATE_NonNursing'

set nocount on
----------------------------------------------------------------------------------------
-- Process the Cursor
----------------------------------------------------------------------------------------
DECLARE UpdateCursor Cursor for
select recid
      ,entity_id
      ,[Entity Name]
      ,email
      ,[address 1]
      ,[address 2]
      ,[Zip Code]
  from dbo.ViewNonNursing
 where ETO_Updated is null;

OPEN UpdateCursor

FETCH next from UpdateCursor
      into @recid
          ,@Entity_ID
          ,@Entity_Name
          ,@email
          ,@address1
          ,@address1
          ,@zipcode

WHILE @@FETCH_STATUS = 0
BEGIN

   set @cursor_count = @cursor_count + 1
   set @bypass_flag = 'N'

   IF @entity_id is null
   BEGIN

--      select @entity_id = Entities.entityid
--            ,@EntityContactID = EC.EntityContactID
--        from [192.168.35.83].etosolaris.dbo.Entities
--        inner join [192.168.35.83].etosolaris.dbo.EntityXEntityContact ECX
--           on Entities.EntityID = ECX.EntityID
--        inner join [192.168.35.83].etosolaris.dbo.EntityContacts EC
--           on ECX.EntityContactID = EC.EntityContactID
--       where Entities.EntityName = @Entity_Name
--         and EC.Email = @email

      select @entity_id = Entities.entityid
        from [192.168.35.83].etosolaris.dbo.Entities
       where Entities.EntityName = @Entity_Name

      IF @entity_id is null
         set @bypass_flag = 'Y'
      ELSE
         update dbo.ViewNonNursing
            set entity_id = @entity_id
          where recid = @recid
   END


   IF @bypass_flag != 'Y'
   BEGIN

      select @isindividual = isindividual
        from [192.168.35.83].etosolaris.dbo.entities
       where entityid = @Entity_ID

      IF @isindividual = 0
         BEGIN
         set @update_isindividual = @update_isindividual + 1
/*
   --   update [192.168.35.83].dbo.entities
         set isindividual = 1
       where entityid = @Entity_ID
*/
         END




   END

----------------------------------------------------------------------------------------
-- continue in cursor
----------------------------------------------------------------------------------------

   IF @bypass_flag = 'Y'
      set @bypassed_count = @bypassed_count + 1

   FETCH next from UpdateCursor
         into @recid
             ,@Entity_ID
             ,@Entity_Name
             ,@email
             ,@address1
             ,@address1
             ,@zipcode

END -- End of UpdateCursor loop

CLOSE UpdateCursor
DEALLOCATE UpdateCursor


---------------------------------------------

print 'Records processed:     '+convert(varchar,@cursor_count)
print 'IsIndividual updated:  '+convert(varchar,@update_isindividual)
print 'Contacts updated:      '+convert(varchar,@update_contacts)
print 'Bypassed:              '+convert(varchar,@bypassed_count)

print 'End of Process: SP_ETO_UPDATE_NonNursing'
GO
