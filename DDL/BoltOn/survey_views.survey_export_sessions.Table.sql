USE [dwh_test]
GO
/****** Object:  Table [survey_views].[survey_export_sessions]    Script Date: 11/27/2017 1:28:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [survey_views].[survey_export_sessions](
	[session_token] [varchar](50) NOT NULL,
	[extract_procedure] [varchar](256) NOT NULL,
	[number_of_records] [int] NOT NULL,
	[time_completed] [datetime] NULL,
	[survey_name] [varchar](256) NULL,
	[table_name] [varchar](256) NULL,
	[file_name] [varchar](256) NULL,
	[export_profile_id] [int] NOT NULL,
	[profile_name] [varchar](256) NULL,
	[site_id] [int] NOT NULL,
	[agency_name] [varchar](256) NULL,
 CONSTRAINT [PK_survey_export_sessions] PRIMARY KEY CLUSTERED 
(
	[session_token] ASC,
	[extract_procedure] ASC,
	[export_profile_id] ASC,
	[site_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
INSERT [survey_views].[survey_export_sessions] ([session_token], [extract_procedure], [number_of_records], [time_completed], [survey_name], [table_name], [file_name], [export_profile_id], [profile_name], [site_id], [agency_name]) VALUES (N'fff', N'usp_etl_select_Alternative_Encounter', 8, CAST(N'2017-11-27T10:33:06.460' AS DateTime), N'Alternative_Encounter_Survey', NULL, N'Alternative_Encounter.txt', 10, N'North Carolina', 163, N'Nurse-Family Partnership of Cleveland County')
INSERT [survey_views].[survey_export_sessions] ([session_token], [extract_procedure], [number_of_records], [time_completed], [survey_name], [table_name], [file_name], [export_profile_id], [profile_name], [site_id], [agency_name]) VALUES (N'fff', N'usp_etl_select_Alternative_Encounter', 9, CAST(N'2017-11-27T10:33:06.460' AS DateTime), N'Alternative_Encounter_Survey', NULL, N'Alternative_Encounter.txt', 10, N'North Carolina', 193, N'Wake County Nurse-Family Partnership')
INSERT [survey_views].[survey_export_sessions] ([session_token], [extract_procedure], [number_of_records], [time_completed], [survey_name], [table_name], [file_name], [export_profile_id], [profile_name], [site_id], [agency_name]) VALUES (N'wdwdxewxwe', N'usp_etl_select_ASQ3', 9, CAST(N'2017-11-27T10:24:27.790' AS DateTime), N'ASQ-3', N'ASQ_3', N'ASG3.txt', 10, N'North Carolina', 163, N'Nurse-Family Partnership of Cleveland County')
INSERT [survey_views].[survey_export_sessions] ([session_token], [extract_procedure], [number_of_records], [time_completed], [survey_name], [table_name], [file_name], [export_profile_id], [profile_name], [site_id], [agency_name]) VALUES (N'wdwdxewxwe', N'usp_etl_select_ASQ3', 4, CAST(N'2017-11-27T10:24:27.790' AS DateTime), N'ASQ-3', N'ASQ_3', N'ASG3.txt', 10, N'North Carolina', 193, N'Wake County Nurse-Family Partnership')
INSERT [survey_views].[survey_export_sessions] ([session_token], [extract_procedure], [number_of_records], [time_completed], [survey_name], [table_name], [file_name], [export_profile_id], [profile_name], [site_id], [agency_name]) VALUES (N'wdwdxewxwe', N'usp_etl_select_ASQ3', 5, CAST(N'2017-11-27T10:24:27.790' AS DateTime), N'ASQ-3', N'ASQ_3', N'ASG3.txt', 10, N'North Carolina', 358, N'Eastern Band of Cherokee Indians NFP')
