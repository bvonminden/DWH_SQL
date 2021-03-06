USE [dwh_test]
GO
/****** Object:  StoredProcedure [survey_views].[usp_etl_select_Infant_Health]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_etl_select_Infant_Health]  
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
	vbase.INFANT_PERSONAL_0_NAME_FIRST,
	vbase.INFANT_BIRTH_0_DOB,
	vbase.CLIENT_0_ID_NSO,
	vbase.CLIENT_PERSONAL_0_NAME_FIRST,
	vbase.CLIENT_PERSONAL_0_NAME_LAST,
	vbase.NURSE_PERSONAL_0_NAME,
	vbase.INFANT_HEALTH_PROVIDER_0_PRIMARY,
	vbase.INFANT_HEALTH_IMMUNIZ_0_UPDATE,
	vbase.INFANT_HEALTH_IMMUNIZ_1_RECORD,
	vbase.INFANT_HEALTH_LEAD_0_TEST,
	vbase.INFANT_HEALTH_HEIGHT_0_INCHES,
	vbase.INFANT_HEALTH_HEIGHT_1_PERCENT,
	vbase.INFANT_HEALTH_HEAD_0_CIRC_INCHES,
	vbase.INFANT_HEALTH_ER_0_HAD_VISIT,
	vbase.INFANT_HEALTH_ER_1_TYPE,
	vbase.INFANT_HEALTH_ER_1_INJ_DATE1,
	vbase.INFANT_HEALTH_ER_1_INJ_DATE2,
	vbase.INFANT_HEALTH_ER_1_INJ_DATE3,
	vbase.INFANT_HEALTH_ER_1_INGEST_DATE1,
	vbase.INFANT_HEALTH_ER_1_INGEST_DATE2,
	vbase.INFANT_HEALTH_ER_1_INGEST_DATE3,
	vbase.INFANT_HEALTH_HOSP_0_HAD_VISIT,
	vbase.INFANT_BREASTMILK_0_EVER_IHC,
	vbase.INFANT_BREASTMILK_1_CONT,
	vbase.INFANT_HEALTH_HOSP_1_INJ_DATE1,
	vbase.INFANT_HEALTH_HOSP_1_INJ_DATE2,
	vbase.INFANT_HEALTH_HOSP_1_INJ_DATE3,
	vbase.INFANT_HEALTH_HOSP_1_INGEST_DATE1,
	vbase.INFANT_HEALTH_HOSP_1_INGEST_DATE2,
	vbase.INFANT_HEALTH_HOSP_1_INGEST_DATE3,
	vbase.INFANT_HEALTH_HOSP_1_TYPE,
	vbase.INFANT_BREASTMILK_1_AGE_STOP,
	vbase.INFANT_BREASTMILK_1_WEEK_STOP,
	vbase.INFANT_BREASTMILK_1_EXCLUSIVE_WKS,
	vbase.INFANT_SOCIAL_SERVICES_0_REFERRAL,
	vbase.INFANT_SOCIAL_SERVICES_1_REFDATE1,
	vbase.INFANT_SOCIAL_SERVICES_1_REFDATE2,
	vbase.INFANT_SOCIAL_SERVICES_1_REFDATE3,
	vbase.INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL,
	vbase.INFANT_SOCIAL_SERVICES_1_NHV_REFDATE1,
	vbase.INFANT_SOCIAL_SERVICES_1_NHV_REFDATE2,
	vbase.INFANT_SOCIAL_SERVICES_1_NHV_REFDATE3,
	vbase.INFANT_HEALTH_WEIGHT_0_POUNDS,
	vbase.INFANT_HEALTH_WEIGHT_1_OUNCES,
	vbase.INFANT_HEALTH_WEIGHT_1_OZ,
	vbase.INFANT_HEALTH_WEIGHT_1_PERCENT,
	vbase.CLIENT_0_ID_AGENCY,
	vbase.INFANT_AGES_STAGES_1_COMM,
	vbase.INFANT_AGES_STAGES_0_VERSION,
	vbase.INFANT_AGES_STAGES_1_GMOTOR,
	vbase.INFANT_AGES_STAGES_1_FMOTOR,
	vbase.INFANT_AGES_STAGES_1_PSOLVE,
	vbase.INFANT_AGES_STAGES_1_PSOCIAL,
	vbase.INFANT_AGES_STAGES_SE_0_EMOTIONAL,
	vbase.INFANT_PERSONAL_0_NAME_LAST,
	vbase.INFANT_HEALTH_HEAD_1_REPORT,
	vbase.INFANT_HEALTH_HEIGHT_1_REPORT,
	vbase.INFANT_HEALTH_PROVIDER_0_APPT,
	vbase.INFANT_HEALTH_WEIGHT_1_REPORT,
	vbase.INFANT_HEALTH_ER_1_OTHERDT1,
	vbase.INFANT_HEALTH_ER_1_INGEST_TREAT1,
	vbase.INFANT_HEALTH_ER_1_INGEST_TREAT2,
	vbase.INFANT_HEALTH_ER_1_INGEST_TREAT3,
	vbase.INFANT_HEALTH_ER_1_INJ_TREAT1,
	vbase.INFANT_HEALTH_ER_1_INJ_TREAT2,
	vbase.INFANT_HEALTH_ER_1_OTHER,
	vbase.INFANT_HEALTH_ER_1_OTHER_REASON1,
	vbase.INFANT_HEALTH_ER_1_OTHER_REASON2,
	vbase.INFANT_HEALTH_ER_1_OTHER_REASON3,
	vbase.INFANT_HEALTH_ER_1_OTHERDT2,
	vbase.INFANT_HEALTH_ER_1_OTHERDT3,
	vbase.INFANT_HOME_0_TOTAL,
	vbase.INFANT_HOME_1_ACCEPTANCE,
	vbase.INFANT_HOME_1_EXPERIENCE,
	vbase.INFANT_HOME_1_INVOLVEMENT,
	vbase.INFANT_HOME_1_LEARNING,
	vbase.INFANT_HOME_1_ORGANIZATION,
	vbase.INFANT_HOME_1_RESPONSIVITY,
	vbase.INFANT_SOCIAL_SERVICES_1_NHV_REASON1,
	vbase.INFANT_SOCIAL_SERVICES_1_NHV_REASON2,
	vbase.INFANT_SOCIAL_SERVICES_1_NHV_REASON3,
	vbase.INFANT_SOCIAL_SERVICES_1_REASON1,
	vbase.INFANT_SOCIAL_SERVICES_1_REASON2,
	vbase.INFANT_SOCIAL_SERVICES_1_REASON3,
	--vbase.NFANT_HEALTH_ER_1_INJ_TREAT3,
	--vbase.DW_AuditDate,
	--vbase.DataSource,
	vbase.INFANT_HEALTH_ER_1_INJ_ERvsUC1,
	vbase.INFANT_HEALTH_PROVIDER_0_APPT_R2,
	vbase.INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2,
	vbase.INFANT_HEALTH_ER_1_INGEST_ERvsUC1,
	vbase.INFANT_HEALTH_ER_1_INGEST_ERvsUC2,
	vbase.INFANT_HEALTH_ER_1_INGEST_ERvsUC3,
	vbase.INFANT_HEALTH_ER_1_INJ_ERvsUC2,
	vbase.INFANT_HEALTH_ER_1_OTHER_ERvsUC1,
	vbase.INFANT_HEALTH_ER_1_OTHER_ERvsUC2,
	vbase.INFANT_HEALTH_NO_ASQ_COMM,
	vbase.INFANT_HEALTH_NO_ASQ_FINE,
	vbase.INFANT_HEALTH_NO_ASQ_GROSS,
	vbase.INFANT_HEALTH_NO_ASQ_PERSONAL,
	vbase.INFANT_HEALTH_NO_ASQ_PROBLEM,
	vbase.INFANT_HEALTH_NO_ASQ_TOTAL,
	vbase.INFANT_HEALTH_ER_1_INJ_ERvsUC3,
	vbase.INFANT_HEALTH_ER_1_OTHER_ERvsUC3,
	vbase.INFANT_HEALTH_ER_1_INJ_TREAT3,
	vbase.INFANT_PERSONAL_0_SSN,
	vbase.INFANT_HEALTH_ER_1_INGEST_DAYS1,
	vbase.INFANT_HEALTH_ER_1_INGEST_DAYS2,
	vbase.INFANT_HEALTH_ER_1_INGEST_DAYS3,
	vbase.INFANT_HEALTH_ER_1_INJ_DAYS1,
	vbase.INFANT_HEALTH_ER_1_INJ_DAYS2,
	vbase.INFANT_HEALTH_ER_1_INJ_DAYS3,
	--vbase.Master_SurveyID,
	vbase.INFANT_HEALTH_IMMUNIZ_UPDATE_NO,
	vbase.INFANT_HEALTH_IMMUNIZ_UPDATE_YES,
	vbase.INFANT_HEALTH_DENTIST,
	vbase.INFANT_HEALTH_DENTIST_STILL_EBF,
	vbase.INFANT_SOCIAL_SERVICES_1_NHV_REASON1_OTHER,
	vbase.INFANT_SOCIAL_SERVICES_1_NHV_REASON2_OTHER,
	vbase.INFANT_SOCIAL_SERVICES_1_NHV_REASON3_OTHER,
	vbase.INFANT_SOCIAL_SERVICES_1_REASON1_OTHER,
	vbase.INFANT_SOCIAL_SERVICES_1_REASON2_OTHER,
	vbase.INFANT_SOCIAL_SERVICES_1_REASON3_OTHER,
	--vbase.Archive_Record,
	vbase.INFANT_INSURANCE_TYPE,
	vbase.INFANT_AGES_STAGES_SE_VERSION,
	vbase.INFANT_BIRTH_COSLEEP,
	vbase.INFANT_BIRTH_READ,
	vbase.INFANT_BIRTH_SLEEP_BACK,
	vbase.INFANT_BIRTH_SLEEP_BEDDING,
	vbase.INFANT_HEALTH_DENTAL_SOURCE,
	vbase.INFANT_INSURANCE,
	vbase.INFANT_INSURANCE_OTHER

	from survey_views.f_select_Infant_Health_Care(@_hash_profile,@p_export_profile_id) vbase


		if @p_etl_session_token is not null
		begin

			declare @_completed datetime=getdate();
		
			insert into survey_views.survey_export_sessions (session_token, extract_procedure, number_of_records, time_completed, survey_name, file_name, export_profile_id, profile_name, site_id, agency_name)
			select 
			@p_etl_session_token,
			@_my_name,
			count(responses.SurveyResponseID) as [Count],
			@_completed,
			'Infant_Health_Survey',
			'Infant_Health.txt',
			ep.ExportProfileID,
			ep.ProfileName,
			ee.SiteID,
			ee.AgencyName

			from survey_views.ExportEntities ee 
			 inner join survey_views.f_select_Infant_Health_Care(@_hash_profile,@p_export_profile_id) responses 
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

commit transaction
 
end;


GO
