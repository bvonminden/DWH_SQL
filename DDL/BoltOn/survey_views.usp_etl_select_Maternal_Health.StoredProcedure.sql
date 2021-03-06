USE [dwh_test]
GO
/****** Object:  StoredProcedure [survey_views].[usp_etl_select_Maternal_Health]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_etl_select_Maternal_Health]  
(
 @p_export_profile_id int,
  @p_entity_filter char(5)=null,
  @p_etl_session_token varchar(50) = null
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

	vbase.SurveyResponseID,
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
	vbase.NURSE_PERSONAL_0_NAME,
	vbase.CLIENT_HEALTH_PREGNANCY_0_LIVE_BIRTHS,
	vbase.CLIENT_HEALTH_PREGNANCY_0_DOCTOR_VISIT,
	vbase.CLIENT_HEALTH_PREGNANCY_0_WKS_PRENATAL_CARE,
	vbase.CLIENT_HEALTH_PREGNANCY_0_EDD,
	vbase.CLIENT_HEALTH_GENERAL_0_CONCERNS,
	vbase.CLIENT_HEALTH_GENERAL_WEIGHT_0_POUNDS,
	vbase.CLIENT_HEALTH_BELIEF_0_LITTLE_CONTROL,
	vbase.CLIENT_HEALTH_BELIEF_0_CANT_SOLVE,
	vbase.CLIENT_HEALTH_BELIEF_0_LITTLE_CAN_DO,
	vbase.CLIENT_HEALTH_BELIEF_0_FEEL_HELPLESS,
	vbase.CLIENT_HEALTH_BELIEF_0_FEEL_PUSHED_AROUND,
	vbase.CLIENT_HEALTH_BELIEF_0_FUTURE_CONTROL,
	vbase.[CLIENT_HEALTH_BELIEF_ 0_DO_ANYTHING],
	vbase.CLIENT_HEALTH_GENERAL_0_OTHER,
	vbase.CLIENT_HEALTH_GENERAL_HEIGHT_0_FEET,
	vbase.CLIENT_HEALTH_GENERAL_HEIGHT_1_INCHES,
	vbase.CLIENT_0_ID_AGENCY,
	--vbase.DW_AuditDate,
	--vbase.DataSource,
	--vbase.LA_CTY_MENTAL_MAT_HEALTH,
	--vbase.LA_CTY_PHYSICAL_MAT_HEALTH,
	--vbase.LA_CTY_DX_OTHER_MAT_HEALTH,
	--vbase.LA_CTY_DSM_DX_MAT_HEALTH,
	vbase.CLIENT_HEALTH_GENERAL_0_PRE_GEST_BP,
	vbase.CLIENT_HEALTH_GENERAL_0_PRE_GEST_DIABETES,
	vbase.CLIENT_HEALTH_GENERAL_0_PRE_GEST_HEART,
	vbase.CLIENT_HEALTH_GENERAL_0_PRE_GEST_KIDNEYS,
	vbase.CLIENT_HEALTH_GENERAL_0_PRE_GEST_STI,
	vbase.CLIENT_HEALTH_GENERAL_0_PRE_GEST_UTI,
	vbase.CLIENT_HEALTH_GENERAL_0_PRE_GEST_VI,
	vbase.CLIENT_HEALTH_GENERAL_CURRENT_WEIGHT_0_POUNDS,
	--vbase.Master_SurveyID,
	vbase.CLIENT_HEALTH_GENERAL_0_CONCERNS2,
	vbase.CLIENT_HEALTH_GENERAL_0_ADDICTION,
	vbase.CLIENT_HEALTH_GENERAL_0_MENTAL_HEALTH

	from survey_views.f_select_Maternal_Health_Assessment(@_hash_profile,@p_export_profile_id) vbase

		if @p_etl_session_token is not null
		begin

			declare @_completed datetime=getdate();
		
			insert into survey_views.survey_export_sessions (session_token, extract_procedure, number_of_records, time_completed, survey_name, file_name, export_profile_id, profile_name, site_id, agency_name)
			select 
			@p_etl_session_token,
			@_my_name,
			count(responses.SurveyResponseID) as [Count],
			@_completed,
			'Maternal_Health_Survey',
			'Maternal_Health.txt',
			ep.ExportProfileID,
			ep.ProfileName,
			ee.SiteID,
			ee.AgencyName

			from survey_views.ExportEntities ee 
			 inner join survey_views.f_select_Maternal_Health_Assessment(@_hash_profile,@p_export_profile_id) responses 
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
