USE [dwh_test]
GO
/****** Object:  StoredProcedure [survey_views].[usp_etl_select_Home_Visit_Encounter]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_etl_select_Home_Visit_Encounter]  
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
	vbase.CLIENT_0_ID_NSO,
	vbase.CLIENT_PERSONAL_0_NAME_FIRST,
	vbase.CLIENT_PERSONAL_0_NAME_LAST,
	vbase.CLIENT_PERSONAL_0_DOB_INTAKE,
	vbase.CLIENT_TIME_0_START_VISIT,
	vbase.CLIENT_TIME_1_END_VISIT,
	vbase.NURSE_MILEAGE_0_VIS,
	vbase.NURSE_PERSONAL_0_NAME,
	vbase.CLIENT_COMPLETE_0_VISIT,
	vbase.CLIENT_LOCATION_0_VISIT,
	vbase.CLIENT_ATTENDEES_0_AT_VISIT,
	vbase.CLIENT_INVOLVE_0_CLIENT_VISIT,
	vbase.CLIENT_INVOLVE_1_GRNDMTHR_VISIT,
	vbase.CLIENT_INVOLVE_1_PARTNER_VISIT,
	vbase.CLIENT_CONFLICT_0_CLIENT_VISIT,
	vbase.CLIENT_CONFLICT_1_GRNDMTHR_VISIT,
	vbase.CLIENT_CONFLICT_1_PARTNER_VISIT,
	vbase.CLIENT_UNDERSTAND_0_CLIENT_VISIT,
	vbase.CLIENT_UNDERSTAND_1_GRNDMTHR_VISIT,
	vbase.CLIENT_UNDERSTAND_1_PARTNER_VISIT,
	vbase.CLIENT_DOMAIN_0_PERSHLTH_VISIT,
	vbase.CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT,
	vbase.CLIENT_DOMAIN_0_LIFECOURSE_VISIT,
	vbase.CLIENT_DOMAIN_0_MATERNAL_VISIT,
	vbase.CLIENT_DOMAIN_0_FRNDFAM_VISIT,
	vbase.CLIENT_DOMAIN_0_TOTAL_VISIT,
	vbase.CLIENT_CONTENT_0_PERCENT_VISIT,
	vbase.CLIENT_ATTENDEES_0_OTHER_VISIT_DESC,
	vbase.CLIENT_TIME_1_DURATION_VISIT,
	vbase.CLIENT_0_ID_AGENCY,
	vbase.CLIENT_CHILD_INJURY_0_PREVENTION,
	vbase.CLIENT_IPV_0_SAFETY_PLAN,
	--vbase.DW_AuditDate,
	--vbase.DataSource,
	vbase.CLIENT_PRENATAL_VISITS_WEEKS,
	vbase.CLIENT_NO_REFERRAL,
	vbase.CLIENT_PRENATAL_VISITS,
	vbase.CLIENT_SCREENED_SRVCS,
	vbase.CLIENT_VISIT_SCHEDULE,
	--vbase.Master_SurveyID,
	vbase.CLIENT_PLANNED_VISIT_SCH,
	vbase.CLIENT_TIME_FROM_AMPM,
	vbase.CLIENT_TIME_FROM_HR,
	vbase.CLIENT_TIME_FROM_MIN,
	vbase.CLIENT_TIME_TO_AMPM,
	vbase.CLIENT_TIME_TO_HR,
	vbase.CLIENT_TIME_TO_MIN,
	--vbase.temp_time_start,
	--vbase.temp_time_end,
	--vbase.Old_CLIENT_TIME_0_START_Visit,
	--vbase.Old_CLIENT_TIME_1_END_Visit,
	--vbase.old_CLIENT_TIME_1_DURATION_VISIT,
	--vbase.temp_DURATION,
	--vbase.LastModified,
	--vbase.Archive_Record,
	vbase.INFANT_HEALTH_ER_1_TYPE,
	vbase.INFANT_HEALTH_HOSP_1_TYPE,
	vbase.INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2,
	vbase.CLIENT_CHILD_DEVELOPMENT_CONCERN,
	vbase.CLIENT_CONT_HLTH_INS,
	vbase.INFANT_HEALTH_ER_0_HAD_VISIT,
	vbase.INFANT_HEALTH_ER_1_INGEST_ERvsUC1,
	vbase.INFANT_HEALTH_ER_1_INGEST_ERvsUC2,
	vbase.INFANT_HEALTH_ER_1_INGEST_ERvsUC3,
	vbase.INFANT_HEALTH_ER_1_INGEST_TREAT1,
	vbase.INFANT_HEALTH_ER_1_INGEST_TREAT2,
	vbase.INFANT_HEALTH_ER_1_INGEST_TREAT3,
	vbase.INFANT_HEALTH_ER_1_INJ_ERvsUC1,
	vbase.INFANT_HEALTH_ER_1_INJ_ERvsUC2,
	vbase.INFANT_HEALTH_ER_1_INJ_ERvsUC3,
	vbase.INFANT_HEALTH_ER_1_INJ_TREAT1,
	vbase.INFANT_HEALTH_ER_1_INJ_TREAT2,
	vbase.INFANT_HEALTH_ER_1_INJ_TREAT3,
	vbase.INFANT_HEALTH_ER_1_OTHER,
	vbase.INFANT_HEALTH_ER_1_OTHER_ERvsUC1,
	vbase.INFANT_HEALTH_ER_1_OTHER_ERvsUC2,
	vbase.INFANT_HEALTH_ER_1_OTHER_ERvsUC3,
	vbase.INFANT_HEALTH_HOSP_0_HAD_VISIT,
	vbase.INFANT_HEALTH_PROVIDER_0_APPT_R2,
	vbase.INFANT_HEALTH_ER_1_OTHER_REASON1,
	vbase.INFANT_HEALTH_ER_1_OTHER_REASON2,
	vbase.INFANT_HEALTH_ER_1_OTHER_REASON3,
	vbase.INFANT_HEALTH_ER_1_INGEST_DAYS1,
	vbase.INFANT_HEALTH_ER_1_INGEST_DAYS2,
	vbase.INFANT_HEALTH_ER_1_INGEST_DAYS3,
	vbase.INFANT_HEALTH_ER_1_INJ_DAYS1,
	vbase.INFANT_HEALTH_ER_1_INJ_DAYS2,
	vbase.INFANT_HEALTH_ER_1_INJ_DAYS3,
	vbase.INFANT_HEALTH_ER_1_INGEST_DATE1,
	vbase.INFANT_HEALTH_ER_1_INGEST_DATE2,
	vbase.INFANT_HEALTH_ER_1_INGEST_DATE3,
	vbase.INFANT_HEALTH_ER_1_INJ_DATE1,
	vbase.INFANT_HEALTH_ER_1_INJ_DATE2,
	vbase.INFANT_HEALTH_ER_1_INJ_DATE3,
	vbase.INFANT_HEALTH_ER_1_OTHERDT1,
	vbase.INFANT_HEALTH_ER_1_OTHERDT2,
	vbase.INFANT_HEALTH_ER_1_OTHERDT3,
	vbase.INFANT_HEALTH_HOSP_1_INGEST_DATE1,
	vbase.INFANT_HEALTH_HOSP_1_INGEST_DATE2,
	vbase.INFANT_HEALTH_HOSP_1_INGEST_DATE3,
	vbase.INFANT_HEALTH_HOSP_1_INJ_DATE1,
	vbase.INFANT_HEALTH_HOSP_1_INJ_DATE2,
	vbase.INFANT_HEALTH_HOSP_1_INJ_DATE3

	from survey_views.f_select_Home_Visit_Encounter(@_hash_profile,@p_export_profile_id) vbase


		if @p_etl_session_token is not null
		begin

			declare @_completed datetime=getdate();
		
			insert into survey_views.survey_export_sessions (session_token, extract_procedure, number_of_records, time_completed, survey_name, file_name, export_profile_id, profile_name, site_id, agency_name)
			select 
			@p_etl_session_token,
			@_my_name,
			count(responses.SurveyResponseID) as [Count],
			@_completed,
			'Home_Visit_Encounter_Survey',
			'Home_Visit_Encounter.txt',
			ep.ExportProfileID,
			ep.ProfileName,
			ee.SiteID,
			ee.AgencyName

			from survey_views.ExportEntities ee 
			 inner join survey_views.f_select_Home_Visit_Encounter(@_hash_profile,@p_export_profile_id) responses 
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
