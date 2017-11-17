USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_ETO_UPDATE_NurseProfile]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_ETO_UPDATE_NurseProfile
--
CREATE PROCEDURE [dbo].[SP_ETO_UPDATE_NurseProfile]
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
DECLARE @new_contacts		smallint
DECLARE @bypassed_count		smallint
DECLARE @cursor_count		int
DECLARE @transaction_count	int
set @insert_count = 0
set @update_count = 0
set @update_isindividual = 0
set @update_contacts = 0
set @update_entityID = 0
set @new_contacts = 0
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
DECLARE @eto_IsIndividual	bit

DECLARE @New_EntityContactID	int


print 'Processing SP_ETO_UPDATE_NurseProfile'

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
      ,eto_isindividual
  from dbo.ViewNurseProfile
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
          ,@eto_isindividual

WHILE @@FETCH_STATUS = 0
BEGIN

   set @cursor_count = @cursor_count + 1
   set @bypass_flag = 'N'

   IF @entity_id is null
   BEGIN


      select @entity_id = Entities.entityid
 --       from [192.168.35.83].etosolaris.dbo.Entities
        from etosolaris.dbo.Entities
       where Entities.EntityName = @Entity_Name

      IF @entity_id is null
         set @bypass_flag = 'Y'
      ELSE
         update dbo.ViewNurseProfile
            set entity_id = @entity_id
          where recid = @recid
   END


   IF @bypass_flag != 'Y'
   BEGIN

      select @isindividual = isindividual
  --      from [192.168.35.83].etosolaris.dbo.entities
        from etosolaris.dbo.entities
       where entityid = @Entity_ID

      IF @isindividual = 0
         BEGIN
         set @update_isindividual = @update_isindividual + 1
         update dbo.ViewNurseProfile
            set eto_isindividual = 0
          where recid = @recid
/*
   --   update [192.168.35.83].dbo.entities
         set isindividual = 1
       where entityid = @Entity_ID
*/
         END
      ELSE
         BEGIN
         update dbo.ViewNurseProfile
            set eto_isindividual = 1
          where recid = @recid 
         END


--    Find the Contact record:
      set @EntityContactID = null
      select @EntityContactID = EC.EntityContactID
 --       from [192.168.35.83].etosolaris.dbo.EntityXEntityContact ECX
 --       inner join [192.168.35.83].etosolaris.dbo.EntityContacts EC
 --          on ECX.EntityContactID = EC.EntityContactID
        from etosolaris.dbo.EntityXEntityContact ECX
        inner join etosolaris.dbo.EntityContacts EC
           on ECX.EntityContactID = EC.EntityContactID
       where ECX.EntityID = @Entity_ID

      IF @EntityContactID is not null
      BEGIN
/*
    --     update [192.168.35.83].etosolaris.dbo.EntityContacts
            set address1 = @address1
               ,address2 = @address2
               ,zipcode = @zipcode
          where EntityContactID = @EntityContactID
        */

         set @update_contacts = @update_contacts + 1
         update dbo.ViewNurseProfile
            set ETO_Updated = 1
          where recid = @recid 
      END
      ELSE
      BEGIN
--      Create Contact Record:
/*
        insert into [192.168.35.83].etosolaris.dbo.EntityContacts
           values (EntityContactID, EntityID_MoveAfterMigration, Title, PrefixID,
                   FName, MiddleInitial, LName, SuffixID, Email
                   Address1, Address2, ZipCode, Notes, AuditStaffID, AuditDate,
                   IsGeneral, EntityContactID_Source)
            (null,-1,null,null
            ,@entityname(firstname)
            ,null --@entityname(firstname)
            ,@entityname(lastname)
            ,null
            ,@emai
            ,@address1
            ,@address2
            ,@zipcode
            ,null
            ,null  --auditstaffid
            ,getdate()
            ,0,null)



             set @New_EntityContactID = @@Identity

*/

        set @new_contacts = @new_contacts + 1

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
             ,@eto_isindividual

END -- End of UpdateCursor loop

CLOSE UpdateCursor
DEALLOCATE UpdateCursor


---------------------------------------------

print 'Records processed:     '+convert(varchar,@cursor_count)
print 'IsIndividual updated:  '+convert(varchar,@update_isindividual)
print 'Contacts updated:      '+convert(varchar,@update_contacts)
print 'Contacts Created:      '+convert(varchar,@new_contacts)
print 'Bypassed:              '+convert(varchar,@bypassed_count)

print 'End of Process: SP_ETO_UPDATE_NurseProfile'
GO
