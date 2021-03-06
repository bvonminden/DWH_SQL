USE [dwh_test]
GO
/****** Object:  StoredProcedure [survey_views].[usp_etl_select_Relationships]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [survey_views].[usp_etl_select_Relationships]  
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
	vbase.NURSE_PERSONAL_0_NAME,
	vbase.CLIENT_ABUSE_EMOTION_0_PHYSICAL_PARTNER,
	vbase.CLIENT_ABUSE_HIT_0_SLAP_PARTNER,
	vbase.CLIENT_ABUSE_TIMES_0_HURT_LAST_YR,
	vbase.CLIENT_ABUSE_TIMES_0_SLAP_PUSH_PARTNER,
	vbase.CLIENT_ABUSE_TIMES_0_PUNCH_KICK_PARTNER,
	vbase.CLIENT_ABUSE_TIMES_0_BURN_BRUISE_PARTNER,
	vbase.CLIENT_ABUSE_TIMES_0_HEAD_PERM_INJURY_PARTNER,
	vbase.CLIENT_ABUSE_TIMES_0_ABUSE_WEAPON_PARTNER,
	vbase.CLIENT_ABUSE_FORCED_0_SEX,
	vbase.CLIENT_ABUSE_FORCED_1_SEX_LAST_YR,
	vbase.CLIENT_ABUSE_HIT_0_SLAP_LAST_TIME,
	vbase.CLIENT_ABUSE_TIMES_0_HURT_SINCE_LAST_TIME,
	vbase.CLIENT_ABUSE_AFRAID_0_PARTNER,
	vbase.CLIENT_0_ID_AGENCY
	--vbase.ABUSE_EMOTION_0_PHYSICAL_PARTNER,
	--vbase.DW_AuditDate,
	--vbase.DataSource,
	--vbase.Master_SurveyID

	from survey_views.f_select_Relationship_Assessment(@_hash_profile,@p_export_profile_id) vbase


		if @p_etl_session_token is not null
		begin

			declare @_completed datetime=getdate();
		
			insert into survey_views.survey_export_sessions (session_token, extract_procedure, number_of_records, time_completed, survey_name, file_name, export_profile_id, profile_name, site_id, agency_name)
			select 
			@p_etl_session_token,
			@_my_name,
			count(responses.SurveyResponseID) as [Count],
			@_completed,
			'Relationship_Survey',
			'Relationships.txt',
			ep.ExportProfileID,
			ep.ProfileName,
			ee.SiteID,
			ee.AgencyName

			from survey_views.ExportEntities ee 
			 inner join survey_views.f_select_Relationship_Assessment(@_hash_profile,@p_export_profile_id) responses 
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
