USE [dwh_test]
GO
/****** Object:  StoredProcedure [survey_views].[usp_etl_select_Referrals_To_NFP]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_etl_select_Referrals_To_NFP]  
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
	vbase.REFERRAL_PROSPECT_0_SOURCE_CODE,
	vbase.REFERRAL_SOURCE_PRIMARY_0_NAME,
	vbase.REFERRAL_SOURCE_PRIMARY_1_LOCATION,
	vbase.REFERRAL_SOURCE_SECONDARY_0_NAME,
	vbase.REFERRAL_SOURCE_SECONDARY_1_LOCATION,
	vbase.REFERRAL_PROSPECT_0_NOTES,
	vbase.REFERRAL_PROSPECT_DEMO_1_PLANG,
	vbase.REFERRAL_PROSPECT_DEMO_1_NAME_FIRST,
	vbase.REFERRAL_PROSPECT_DEMO_0_NAME_LAST,
	vbase.REFERRAL_PROSPECT_DEMO_1_DOB,
	vbase.REFERRAL_PROSPECT_DEMO_1_STREET,
	vbase.REFERRAL_PROSPECT_DEMO_1_STREET2,
	vbase.REFERRAL_PROSPECT_DEMO_1_ZIP,
	vbase.REFERRAL_PROSPECT_DEMO_1_WORK,
	vbase.REFERRAL_PROSPECT_DEMO_1_PHONE_HOME,
	vbase.REFERRAL_PROSPECT_DEMO_1_CELL,
	vbase.REFERRAL_PROSPECT_DEMO_1_EMAIL,
	vbase.REFERRAL_PROSPECT_DEMO_1_EDD,
	vbase.REFERRAL_PROSPECT_0_WAIT_LIST,
	vbase.REFERRAL_PROSPECT_0_FOLLOWUP_NURSE,
	--vbase.DW_AuditDate,
	--vbase.DataSource,
	--vbase.LA_CTY_REFERRAL_SCHOOL,
	--vbase.LA_CTY_REFERRAL_SOURCE_OTH,
	vbase.CLIENT_0_ID_NSO
	--vbase.Master_SurveyID

	from survey_views.f_select_Referrals_To_NFP_Program(@_hash_profile,@p_export_profile_id) vbase

		if @p_etl_session_token is not null
		begin

			declare @_completed datetime=getdate();
		
			insert into survey_views.survey_export_sessions (session_token, extract_procedure, number_of_records, time_completed, survey_name, file_name, export_profile_id, profile_name, site_id, agency_name)
			select 
			@p_etl_session_token,
			@_my_name,
			count(responses.SurveyResponseID) as [Count],
			@_completed,
			'Referrals_to_NFP_Survey',
			'Referrals_To_NFP.txt',
			ep.ExportProfileID,
			ep.ProfileName,
			ee.SiteID,
			ee.AgencyName

			from survey_views.ExportEntities ee 
			 inner join survey_views.f_select_Referrals_To_NFP_Program(@_hash_profile,@p_export_profile_id) responses 
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
