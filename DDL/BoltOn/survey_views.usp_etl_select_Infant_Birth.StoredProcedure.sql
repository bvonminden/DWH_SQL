USE [dwh_test]
GO
/****** Object:  StoredProcedure [survey_views].[usp_etl_select_Infant_Birth]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_etl_select_Infant_Birth]  
(
 @p_export_profile_id int,
  @p_entity_filter char(5)=null,
  @p_etl_session_token varchar(50)=null
)
as
begin


set nocount on;
declare		@_rec_count int;
declare		@_my_name varchar(256);
set			@_my_name = OBJECT_NAME(@@PROCID);


declare  @_hash_profile   char(10);


set   @_hash_profile   = (select top 1 isnull('SA',hash_policy) from survey_views.f_get_survey_etl_work() where ExportProfileID=@p_export_profile_id);

begin transaction


	select 

	vbase. SurveyResponseID,
	vbase.ElementsProcessed,
	vbase.SurveyID,
	vbase.SurveyDate,
	vbase.AuditDate,
	vbase.CL_EN_GEN_ID,
	vbase.SiteID,
	vbase.ProgramID,
	vbase.IA_StaffID,
	vbase.ClientID,
	vbase.RespondentID,
	vbase.INFANT_0_ID_NSO,
	vbase.[INFANT_PERSONAL_0_FIRST NAME],
	vbase.INFANT_BIRTH_0_DOB,
	vbase.CLIENT_0_ID_NSO,
	vbase.CLIENT_PERSONAL_0_NAME_FIRST,
	vbase.CLIENT_PERSONAL_0_NAME_LAST,
	vbase.NURSE_PERSONAL_0_NAME,
	vbase.INFANT_BIRTH_1_MULTIPLE_BIRTHS,
	vbase.INFANT_PERSONAL_0_ETHNICITY,
	vbase.INFANT_PERSONAL_0_RACE,
	vbase.INFANT_PERSONAL_0_GENDER,
	vbase.INFANT_BIRTH_1_WEIGHT_GRAMS,
	vbase.INFANT_BIRTH_1_WEIGHT_POUNDS,
	vbase.INFANT_BIRTH_1_GEST_AGE,
	vbase.INFANT_BIRTH_1_NICU,
	vbase.INFANT_BIRTH_1_NICU_DAYS,
	vbase.CLIENT_WEIGHT_0_PREG_GAIN,
	vbase.INFANT_BREASTMILK_0_EVER_BIRTH,
	vbase.INFANT_0_ID_NSO2,
	vbase.[INFANT_PERSONAL_0_FIRST NAME2],
	vbase.INFANT_BIRTH_0_DOB2,
	vbase.INFANT_PERSONAL_0_ETHNICITY2,
	vbase.INFANT_PERSONAL_0_ETHNICITY3,
	vbase.INFANT_PERSONAL_0_RACE2,
	vbase.INFANT_PERSONAL_0_RACE3,
	vbase.INFANT_PERSONAL_0_GENDER2,
	vbase.INFANT_BIRTH_1_WEIGHT_GRAMS2,
	vbase.INFANT_BIRTH_1_GEST_AGE2,
	vbase.INFANT_BIRTH_1_NICU2,
	vbase.INFANT_BIRTH_1_NICU_DAYS2,
	vbase.INFANT_0_ID_NSO3,
	vbase.INFANT_BIRTH_0_DOB3,
	vbase.INFANT_PERSONAL_0_GENDER3,
	vbase.INFANT_BIRTH_1_WEIGHT_GRAMS3,
	vbase.INFANT_BIRTH_1_WEIGHT_POUNDS3,
	vbase.INFANT_BIRTH_1_GEST_AGE3,
	vbase.INFANT_BIRTH_1_NICU3,
	vbase.INFANT_BIRTH_1_NICU_DAYS3,
	vbase.INFANT_BREASTMILK_0_EVER_BIRTH2,
	vbase.INFANT_BREASTMILK_0_EVER_BIRTH3,
	vbase.INFANT_BIRTH_1_WEIGHT_MEASURE,
	vbase.INFANT_BIRTH_1_WEIGHT_OUNCES,
	vbase.INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS,
	vbase.INFANT_BIRTH_1_WEIGHT_MEASURE2,
	vbase.INFANT_BIRTH_1_WEIGHT_MEASURE3,
	vbase.INFANT_BIRTH_1_WEIGHT_OUNCES3,
	vbase.INFANT_BIRTH_1_WEIGHT_POUNDS2,
	vbase.INFANT_BIRTH_1_WEIGHT_OUNCES2,
	vbase.[INFANT_PERSONAL_0_FIRST NAME3],
	vbase.CLIENT_0_ID_AGENCY,
	vbase.[INFANT_PERSONAL_0_LAST NAME],
	--vbase.DW_AuditDate,
	--vbase.DataSource,
	vbase.INFANT_BIRTH_0_CLIENT_ER,
	--vbase.INFANT_BIRTH_0_CLIENT_URGENT CARE,
	vbase.INFANT_BIRTH_1_NICU_R2,
	vbase.INFANT_BIRTH_1_NICU_R2_2,
	vbase.INFANT_BIRTH_1_NICU_R2_3,
	vbase.INFANT_BIRTH_1_NURSERY_R2,
	vbase.INFANT_BIRTH_1_NURSERY_R2_2,
	vbase.INFANT_BIRTH_1_NURSERY_R2_3,
	vbase.INFANT_BIRTH_0_CLIENT_ER_TIMES,
	--vbase.INFANT_BIRTH_0_CLIENT_URGENT CARE_TIMES,
	vbase.INFANT_BIRTH_1_NICU_DAYS_R2,
	vbase.INFANT_BIRTH_1_NICU_DAYS_R2_2,
	vbase.INFANT_BIRTH_1_NICU_DAYS_R2_3,
	vbase.INFANT_BIRTH_1_NURSERY_DAYS_R2,
	vbase.INFANT_BIRTH_1_NURSERY_DAYS_R2_2,
	vbase.INFANT_BIRTH_1_NURSERY_DAYS_R2_3,
	vbase.INFANT_BIRTH_1_NICU_NURSERY_PURPOSE,
	vbase.INFANT_BIRTH_1_NICU_NURSERY_PURPOSE2,
	vbase.INFANT_BIRTH_1_NICU_NURSERY_PURPOSE3,
	vbase.INFANT_BIRTH_1_DELIVERY,
	vbase.INFANT_BIRTH_1_HEARING_SCREEN,
	vbase.INFANT_BIRTH_1_HEARING_SCREEN2,
	vbase.INFANT_BIRTH_1_HEARING_SCREEN3,
	vbase.INFANT_BIRTH_1_LABOR,
	vbase.INFANT_BIRTH_1_NEWBORN_SCREEN,
	vbase.INFANT_BIRTH_1_NEWBORN_SCREEN2,
	vbase.INFANT_BIRTH_1_NEWBORN_SCREEN3,
	vbase.INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER,
	vbase.INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER2,
	vbase.INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER3,
	--vbase.Master_SurveyID,
	vbase.INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS2,
	vbase.INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS3,
	--vbase.LastModified,
	--vbase.Archive_Record,
	vbase.INFANT_INSURANCE_TYPE,
	vbase.INFANT_INSURANCE_TYPE2,
	vbase.INFANT_INSURANCE_TYPE3,
	vbase.INFANT_BIRTH_COSLEEP,
	vbase.INFANT_BIRTH_COSLEEP2,
	vbase.INFANT_BIRTH_COSLEEP3,
	vbase.INFANT_BIRTH_READ,
	vbase.INFANT_BIRTH_READ2,
	vbase.INFANT_BIRTH_READ3,
	vbase.INFANT_BIRTH_SLEEP_BACK,
	vbase.INFANT_BIRTH_SLEEP_BACK2,
	vbase.INFANT_BIRTH_SLEEP_BACK3,
	vbase.INFANT_BIRTH_SLEEP_BEDDING,
	vbase.INFANT_BIRTH_SLEEP_BEDDING2,
	vbase.INFANT_BIRTH_SLEEP_BEDDING3,
	vbase.INFANT_INSURANCE,
	vbase.INFANT_INSURANCE2,
	vbase.INFANT_INSURANCE3,
	vbase.INFANT_INSURANCE_OTHER,
	vbase.INFANT_INSURANCE_OTHER2,
	vbase.INFANT_INSURANCE_OTHER3

	from survey_views.f_select_Infant_Birth(@_hash_profile,@p_export_profile_id) vbase

		if @p_etl_session_token is not null
		begin

			declare @_completed datetime=getdate();
		
			insert into survey_views.survey_export_sessions (session_token, extract_procedure, number_of_records, time_completed, survey_name, file_name, export_profile_id, profile_name, site_id, agency_name)
			select 
			@p_etl_session_token,
			@_my_name,
			count(responses.SurveyResponseID) as [Count],
			@_completed,
			'Infant_Birth_Survey',
			'Infant_Birth.txt',
			ep.ExportProfileID,
			ep.ProfileName,
			ee.SiteID,
			ee.AgencyName

			from survey_views.ExportEntities ee 
			 inner join survey_views.f_select_Infant_Birth(@_hash_profile,@p_export_profile_id) responses 
														on responses.SiteID=ee.SiteID
			 inner join survey_views.ExportProfile ep	on ee.ExportProfileID=ep.ExportProfileID
			where
				ee.ExportProfileID=@p_export_profile_id
			group by
			ep.ExportProfileID,
			ep.ProfileName,
			ee.AgencyName,
			ee.SiteID;


		end

commit transaction;
 
end;


GO
