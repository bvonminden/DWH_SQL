USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_validate_staff_load_file]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_validate_staff_load_file
CREATE procedure [dbo].[SP_validate_staff_load_file]
 (@p_entity_id       int = null)
AS
-- This procedure validates the load data (dbo.load_data_staff_validation)
-- against what was actually loaded into ETO, validating correctness of initial load


DECLARE @Process	nvarchar(50)
set @process = 'SP_CRM_CONTACTS'

DECLARE @insert_count		smallint
DECLARE @update_count		smallint
DECLARE @bypassed_count		smallint
DECLARE @cursor_count		int
DECLARE @transaction_count	int
set @insert_count = 0
set @update_count = 0
set @bypassed_count = 0
set @cursor_count = 0
set @transaction_count = 0


DECLARE @recid		int
DECLARE @Entity_ID	int
DECLARE @site_ID	int
DECLARE @site_name	nvarchar(100)
DECLARE @team_name	nvarchar(100)
DECLARE @home_visitor_id nvarchar(50)
DECLARE @First_Name	nvarchar(50)
DECLARE @Last_Name	nvarchar(50)
DECLARE @business_phone	nvarchar(50)
DECLARE @Email  	nvarchar(50)
DECLARE @address1	nvarchar(50)
DECLARE @address2	nvarchar(50)
DECLARE @address3	nvarchar(50)
DECLARE @City		nvarchar(50)
DECLARE @State		nvarchar(50)
DECLARE @zipcode	nvarchar(50)
DECLARE @contacttype	nvarchar(50)
DECLARE @subtype	nvarchar(50)
DECLARE @gender		nvarchar(50)
DECLARE @ethnicity	nvarchar(50)
DECLARE @year_of_birth	nvarchar(50)
DECLARE @hire_date	date
DECLARE @contact_status	nvarchar(50)
DECLARE @fte_as_NHV	numeric(10,5)
DECLARE @fte_as_NHV_supervisor numeric(10,5)
DECLARE @fte_other	numeric(10,5)
DECLARE @ed_nursing	nvarchar(50)
DECLARE @ed_other	nvarchar(50)
DECLARE @promote_to_supervisor nvarchar(50)
DECLARE @date_of_promotion date
DECLARE @resignation_date date
DECLARE @years_Supervisor_role numeric(10,5)
DECLARE @language	nvarchar(50)
DECLARE @home_visitor_id_verified bit
DECLARE @business_phone_verified bit
DECLARE @Email_verified bit
DECLARE @address1_verified bit
DECLARE @address2_verified bit
DECLARE @City_verified bit
DECLARE @State_verified bit
DECLARE @zipcode_verified bit
DECLARE @contacttype_verified bit
DECLARE @entity_type_verified bit
DECLARE @subtype_verified bit
DECLARE @gender_verified bit
DECLARE @ethnicity_verified bit
DECLARE @year_of_birth_verified	 bit
DECLARE @hire_date_verified bit
DECLARE @contact_status_verified bit
DECLARE @fte_as_NHV_verified bit
DECLARE @fte_as_NHV_supervisor_verified bit
DECLARE @fte_other_verified bit
DECLARE @ed_nursing_verified bit
DECLARE @ed_other_verified bit
DECLARE @promote_to_supervisor_verified bit
DECLARE @date_of_promotion_verified bit
DECLARE @resignation_date_verified bit
DECLARE @years_Supervisor_role_verified bit
DECLARE @language_verified bit
DECLARE @IsIndividual_verified bit
DECLARE @IsIndividual   bit

DECLARE @validated_ind	nvarchar(10)
DECLARE @validated_comment nvarchar(100)

-- IA_Staff
DECLARE @IAS_Entity_id int
DECLARE @IAS_Site_id int
DECLARE @IAS_home_visitor_id nvarchar(50)
DECLARE @IAS_First_Name	nvarchar(50)
DECLARE @IAS_Last_Name	nvarchar(50)
DECLARE @IAS_phone1	nvarchar(50)
DECLARE @IAS_Email  	nvarchar(50)
DECLARE @IAS_address1	nvarchar(50)
DECLARE @IAS_address2	nvarchar(50)
DECLARE @IAS_address3	nvarchar(50)
DECLARE @IAS_City		nvarchar(50)
DECLARE @IAS_State		nvarchar(50)
DECLARE @IAS_zipcode	nvarchar(50)
DECLARE @IAS_Disabled	bit
DECLARE @IAS_contact_Status	nvarchar(20)
DECLARE @IAS_contacttype	nvarchar(50)
DECLARE @IAS_entity_type	nvarchar(50)
DECLARE @IAS_subtype	nvarchar(50)
DECLARE @IAS_gender		nvarchar(50)
DECLARE @IAS_ethnicity	nvarchar(50)
DECLARE @IAS_year_of_birth	nvarchar(50)
DECLARE @IAS_hire_date	date
DECLARE @IAS_fte_as_NHV	numeric(10,5)
DECLARE @IAS_fte_as_NHV_supervisor numeric(10,5)
DECLARE @IAS_fte_other	numeric(10,5)
DECLARE @IAS_ed_nursing	nvarchar(50)
DECLARE @IAS_ed_other	nvarchar(50)
DECLARE @IAS_promote_to_supervisor nvarchar(50)
DECLARE @IAS_date_of_promotion date
DECLARE @IAS_resignation_date date
DECLARE @IAS_years_Supervisor_role numeric(10,5)
DECLARE @IAS_language	nvarchar(50)

DECLARE @Exit		nvarchar(10)
DECLARE @count		smallint
DECLARE @SQL            nvarchar(4000)
DECLARE @bypass_flag    nvarchar(10)
DECLARE @DW_CRM_ContactID_Update_flag    nvarchar(10)
DECLARE @return_id      int
DECLARE @qualified_ctr  smallint
DECLARE @return_value   nvarchar(50)

SET @return_id = null
SET @qualified_ctr = 0

print 'Begin Procedure: SP_validate_staff_load_file'

set nocount on
----------------------------------------------------------------------------------------
-- Process the STaff Cursor
----------------------------------------------------------------------------------------
DECLARE StaffCursor Cursor for
select recid
      ,EntityID
      ,site_ID
      ,program_name
      ,team_name
      ,home_visitor_id
      ,First_Name
      ,Last_Name
      ,business_phone
      ,Email
      ,address1
      ,address2
      ,address3
      ,City
      ,State
      ,zipcode
      ,contacttype
      ,subtype
      ,gender
      ,ethnicity
      ,year_of_birth	
      ,hiire_date
      ,contact_status
      ,fte_as_NHV
      ,fte_as_NHV_supervisor
      ,fte_other
      ,ed_nursing
      ,ed_other
      ,promote_to_supervisor
      ,date_of_promotion
      ,resignation_date
      ,years_Supervisor_role
      ,language
      ,home_visitor_id_verified
      ,business_phone_verified
      ,Email_verified
      ,address1_verified
      ,address2_verified
      ,City_verified
      ,State_verified
      ,zipcode_verified
      ,contacttype_verified
      ,entity_type_verified
      ,subtype_verified
      ,gender_verified
      ,ethnicity_verified
      ,year_of_birth_verified	
      ,hire_date_verified
      ,contact_status_verified
      ,fte_as_NHV_verified
      ,fte_as_NHV_supervisor_verified
      ,fte_other_verified
      ,ed_nursing_verified
      ,ed_other_verified
      ,promote_to_supervisor_verified
      ,date_of_promotion_verified
      ,resignation_date_verified
      ,years_Supervisor_role_verified
      ,language_verified
      ,IsIndividual_verified
  from dbo.load_data_staff_verification
 where validate_ind is null or
       validate_ind != 'OK';

OPEN StaffCursor

FETCH next from StaffCursor
      into @recid
          ,@Entity_ID
          ,@site_ID
          ,@site_name
          ,@team_name
          ,@home_visitor_id
          ,@First_Name
          ,@Last_Name
          ,@business_phone
          ,@Email
          ,@address1
          ,@address2
          ,@address3
          ,@City
          ,@State
          ,@zipcode
          ,@contacttype
          ,@subtype
          ,@gender
          ,@ethnicity
          ,@year_of_birth	
          ,@hire_date
          ,@contact_status
          ,@fte_as_NHV
          ,@fte_as_NHV_supervisor
          ,@fte_other
          ,@ed_nursing
          ,@ed_other
          ,@promote_to_supervisor
          ,@date_of_promotion
          ,@resignation_date
          ,@years_Supervisor_role
          ,@language
          ,@home_visitor_id_verified
          ,@business_phone_verified
          ,@Email_verified
          ,@address1_verified
          ,@address2_verified
          ,@City_verified
          ,@State_verified
          ,@zipcode_verified
          ,@contacttype_verified
          ,@entity_type_verified
          ,@subtype_verified
          ,@gender_verified
          ,@ethnicity_verified
          ,@year_of_birth_verified	
          ,@hire_date_verified
          ,@contact_status_verified
          ,@fte_as_NHV_verified
          ,@fte_as_NHV_supervisor_verified
          ,@fte_other_verified
          ,@ed_nursing_verified
          ,@ed_other_verified
          ,@promote_to_supervisor_verified
          ,@date_of_promotion_verified
          ,@resignation_date_verified
          ,@years_Supervisor_role_verified
          ,@language_verified
          ,@IsIndividual_verified

WHILE @@FETCH_STATUS = 0
BEGIN

--   print 'lastname=' +@last_name

   IF @site_id is null
   BEGIN
      select @count = count(*) 
        from dbo.agencies
       where agency_info_0_name = @site_name

      IF @count = 1
         BEGIN
            update dbo.load_data_staff_verification
               set site_id = (select site_id 
                                 from dbo.agencies
                                where agency_info_0_name = @site_name)
                  ,site_name_verified = 1
             where recid = @recid
         END
   END


   IF @entity_id is null
   BEGIN

--      select @count = count(*) 
--        from dbo.IA_Staff
--       where last_name = @last_name
--         and first_name = @first_name
--         and email = @email

      select @count = count(*) 
        from ETOSRVR.etosolaris.dbo.Entities
       where EntityName = @first_name +' ' +@last_name

      if @count = 1
         BEGIN
            select @Entity_ID = EntityID 
              from ETOSRVR.etosolaris.dbo.Entities
             where EntityName = @first_name +' ' +@last_name

            update dbo.load_data_staff_verification
               set entityid = @Entity_Id
                  ,email_verified = 1
             where recid = @recid
         END
   END

   IF @Entity_ID is not null
   BEGIN
      select @IAS_site_ID = site_ID
            --,@IAS_program_name = 
            --,@IAS_team_name = 
            ,@IAS_home_visitor_id = nurse_0_id_agency
            ,@IAS_phone1 = Phone1
            ,@IAS_Email = Email
            ,@IAS_address1 = Address1
            ,@IAS_address1 = Address2
            ,@IAS_City = City
            ,@IAS_State = State
            ,@IAS_zipcode = ZipCode
            ,@IAS_Disabled = Disabled
            ,@IAS_contacttype = nurse_0_program_position
            ,@IAS_Entity_Type = entity_type
            ,@IAS_subtype = entity_subtype
            ,@IAS_gender = nurse_0_gender
            ,@IAS_ethnicity = nurse_0_ethnicity
            --,@IAS_year_of_birth = nurse_0_birth_year
            ,@IAS_hire_date = start_date
            ,@IAS_contact_status = disabled
            --,@IAS_fte_as_NHV = 
            --,@IAS_fte_as_NHV_supervisor = 
            --,@IAS_fte_other = 
            --,@IAS_ed_nursing = 
            --,@IAS_ed_other = 
            --,@IAS_promote_to_supervisor = 
            --,@IAS_date_of_promotion = 
            --,@IAS_resignation_date = 
            ,@IAS_years_Supervisor_role = nurse_0_year_supervisor_experience
            ,@IAS_language = nurse_0_language
        from dbo.IA_Staff
       where entity_id = @entity_id;


      IF @isindividual_verified is null and
         @entity_ID is not null
         BEGIN
            select @isindividual = isindividual
              from ETOSRVR.etosolaris.dbo.Entities
             where EntityID = @entity_id
            IF @isindividual = 1
               update dbo.load_data_staff_verification
                  set isindividual_verified = 1
                where recid = @recid
         END


      IF @contact_status_verified is null and
         ((@contact_status = 'Active' and
           @IAS_Disabled = 0) or
          (@contact_status = 'Inactive' and
           @IAS_Disabled = 1) )
         BEGIN
            update dbo.load_data_staff_verification
               set contact_status_verified = 1
             where recid = @recid
         END

      IF @entity_type_verified is null and
         @IAS_entity_type = 'Administrative'
         BEGIN
            update dbo.load_data_staff_verification
               set entity_type_verified = 1
             where recid = @recid
         END

      IF @subtype_verified is null and
         @subtype = @IAS_Subtype
         BEGIN
            update dbo.load_data_staff_verification
               set subtype_verified = 1
             where recid = @recid
         END

      IF @years_Supervisor_role_verified is null and
         isnull(@years_Supervisor_role,9999) = isnull(@IAS_years_Supervisor_role,9999)
         BEGIN
            update dbo.load_data_staff_verification
               set years_Supervisor_role_verified = 1
             where recid = @recid
         END

      IF @home_visitor_id_verified is null and
         isnull(@home_visitor_id,'') = isnull(@IAS_home_visitor_id,'')
         BEGIN
            update dbo.load_data_staff_verification
               set home_visitor_id_verified = 1
             where recid = @recid
         END

      IF @business_phone_verified is null and
         @business_Phone = @IAS_phone1
         BEGIN
            update dbo.load_data_staff_verification
               set business_phone_verified = 1
             where recid = @recid
         END

      IF @address1_verified is null and
         @address1 = @IAS_address1
         BEGIN
            update dbo.load_data_staff_verification
               set address1_verified = 1
             where recid = @recid
         END

      IF @address2_verified is null and
         @address2 = @IAS_address2
         BEGIN
            update dbo.load_data_staff_verification
               set address2_verified = 1
             where recid = @recid
         END

      IF @city_verified is null and
         @IAS_city = @IAS_city
         BEGIN
            update dbo.load_data_staff_verification
               set city_verified = 1
             where recid = @recid
         END

      IF @state_verified is null and
         @state = @IAS_state
         BEGIN
            update dbo.load_data_staff_verification
               set state_verified = 1
             where recid = @recid
         END

      IF @zipcode_verified is null and
         @zipcode = @IAS_zipcode
         BEGIN
            update dbo.load_data_staff_verification
               set zipcode_verified = 1
             where recid = @recid
         END

      IF @hire_date_verified is null and
         convert(datetime,@hire_date) = @IAS_hire_date
         BEGIN
            update dbo.load_data_staff_verification
               set hire_date_verified = 1
             where recid = @recid
         END


      IF @gender_verified is null and
         isnull(@gender,'') = isnull(@IAS_gender,'')
         BEGIN
            update dbo.load_data_staff_verification
               set gender_verified = 1
             where recid = @recid
         END

      IF @ethnicity_verified is null and
         isnull(@ethnicity,'') = isnull(@IAS_ethnicity,'')
         BEGIN
            update dbo.load_data_staff_verification
               set ethnicity_verified = 1
             where recid = @recid
         END


--  Validation agains Staff Update Survey:

      select @count = count(*)
        from dbo.staff_update_survey
       where cl_en_gen_id = @entity_id;

      IF @count = 1
      BEGIN

         select @IAS_fte_as_NHV = nurse_professional_1_home_visitor_fte
               ,@IAS_fte_as_NHV_supervisor = nurse_professional_1_supervisor_fte
               ,@IAS_fte_other = nurse_professional_1_admin_asst_fte
               ,@IAS_ed_nursing = nurse_education_0_nursing_degrees
               ,@IAS_ed_other = nurse_education_1_other_degrees
               ,@IAS_resignation_date = nurse_status_0_change_terminate_date
           from dbo.staff_update_survey
          where cl_en_gen_id = @entity_id;

         IF @fte_as_NHV_verified is null and
            isnull(@fte_as_NHV,99999) = isnull(@IAS_fte_as_NHV,99999)
            BEGIN
               update dbo.load_data_staff_verification
                  set fte_as_NHV_verified = 1
                where recid = @recid
            END

         IF @fte_as_NHV_supervisor_verified is null and
            isnull(@fte_as_NHV_supervisor,99999) = isnull(@IAS_fte_as_NHV_supervisor,99999)
            BEGIN
               update dbo.load_data_staff_verification
                  set fte_as_NHV_supervisor_verified = 1
                where recid = @recid
            END

         IF @fte_other_verified is null and
            isnull(@fte_other,99999) = isnull(@IAS_fte_other,99999)
            BEGIN
               update dbo.load_data_staff_verification
                  set fte_other_verified = 1
                where recid = @recid
            END

         IF @ed_nursing_verified is null and
            isnull(@ed_nursing,'') = isnull(@IAS_ed_nursing,'')
            BEGIN
               update dbo.load_data_staff_verification
                  set ed_nursing_verified = 1
                where recid = @recid
            END

         IF @ed_other_verified is null and
            isnull(@ed_other,'') = isnull(@IAS_ed_other,'')
            BEGIN
               update dbo.load_data_staff_verification
                  set ed_other_verified = 1
                where recid = @recid
            END

         IF @resignation_date_verified is null and
            ((@resignation_date is null and @IAS_resignation_date is null) or
             convert(datetime,@resignation_date) = @IAS_resignation_date)
            BEGIN
               update dbo.load_data_staff_verification
                  set resignation_date_verified = 1
                where recid = @recid
            END

      END    /* Staff Update Survey found */
      ELSE
      BEGIN

--       set validations when fields are found to be null

         IF @fte_as_NHV_verified is null and @fte_as_NHV is null
            BEGIN
               update dbo.load_data_staff_verification
                  set fte_as_NHV_verified = 1
                where recid = @recid
            END

         IF @fte_as_NHV_supervisor_verified is null and @fte_as_NHV_supervisor is null
            BEGIN
               update dbo.load_data_staff_verification
                  set fte_as_NHV_supervisor_verified = 1
                where recid = @recid
            END

         IF @fte_other_verified is null and @fte_other is null
            BEGIN
               update dbo.load_data_staff_verification
                  set fte_other_verified = 1
                where recid = @recid
            END

         IF @ed_nursing_verified is null and isnull(@ed_nursing,'') = ''
            BEGIN
               update dbo.load_data_staff_verification
                  set ed_nursing_verified = 1
                where recid = @recid
            END

         IF @ed_other_verified is null and isnull(@ed_other,'') = ''
            BEGIN
               update dbo.load_data_staff_verification
                  set ed_other_verified = 1
                where recid = @recid
            END

         IF @resignation_date_verified is null and @resignation_date is null
            BEGIN
               update dbo.load_data_staff_verification
                  set resignation_date_verified = 1
                where recid = @recid
            END

      END  /* Staff Update Survey not found*/

   END
----------------------------------------------------------------------------------------
-- continue in cursor
----------------------------------------------------------------------------------------

   IF @bypass_flag = 'Y'
      set @bypassed_count = @bypassed_count + 1

   FETCH next from StaffCursor
         into @recid
             ,@Entity_ID
             ,@site_ID
             ,@site_name
             ,@team_name
             ,@home_visitor_id
             ,@First_Name
             ,@Last_Name
             ,@business_phone
             ,@Email
             ,@address1
             ,@address2
             ,@address3
             ,@City
             ,@State
             ,@zipcode
             ,@contacttype
             ,@subtype
             ,@gender
             ,@ethnicity
             ,@year_of_birth	
             ,@hire_date
             ,@contact_status
             ,@fte_as_NHV
             ,@fte_as_NHV_supervisor
             ,@fte_other
             ,@ed_nursing
             ,@ed_other
             ,@promote_to_supervisor
             ,@date_of_promotion
             ,@resignation_date
             ,@years_Supervisor_role
             ,@language
             ,@home_visitor_id_verified
             ,@business_phone_verified
             ,@Email_verified
             ,@address1_verified
             ,@address2_verified
             ,@City_verified
             ,@State_verified
             ,@zipcode_verified
             ,@contacttype_verified
             ,@entity_type_verified
             ,@subtype_verified
             ,@gender_verified
             ,@ethnicity_verified
             ,@year_of_birth_verified	
             ,@hire_date_verified
             ,@contact_status_verified
             ,@fte_as_NHV_verified
             ,@fte_as_NHV_supervisor_verified
             ,@fte_other_verified
             ,@ed_nursing_verified
             ,@ed_other_verified
             ,@promote_to_supervisor_verified
             ,@date_of_promotion_verified
             ,@resignation_date_verified
             ,@years_Supervisor_role_verified
             ,@language_verified
             ,@IsIndividual_verified

END -- End of StaffCursor loop

CLOSE StaffCursor
DEALLOCATE StaffCursor


--print 'IA_Staff Members Processed: ' +convert(varchar,@cursor_count)
--print 'CRM Contacts Added:         ' +convert(varchar,@insert_count)
--print 'CRM Contacts Updated:       ' +convert(varchar,@update_count)
--print 'CRM Bypassed Msgs:          ' +convert(varchar,@bypassed_count)

PRINT 'End of Procedure: SP_validate_staff_load_file'

GO
