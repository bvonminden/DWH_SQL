USE [dwh_test]
GO
/****** Object:  Table [survey_views].[etl_extract_types]    Script Date: 11/27/2017 1:28:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [survey_views].[etl_extract_types](
	[export_type_id] [int] NOT NULL,
	[export_profile_code] [char](1) NOT NULL,
	[extract_procedure] [varchar](500) NOT NULL,
	[extract_file_name] [varchar](100) NOT NULL,
	[field_hashing] [bit] NOT NULL,
	[include_tribal] [bit] NOT NULL,
	[include_at_risk] [bit] NOT NULL,
	[extract_format] [char](3) NOT NULL,
 CONSTRAINT [PK_etl_extract_types] PRIMARY KEY CLUSTERED 
(
	[export_profile_code] ASC,
	[export_type_id] ASC,
	[extract_procedure] ASC,
	[extract_file_name] ASC,
	[field_hashing] ASC,
	[include_tribal] ASC,
	[include_at_risk] ASC,
	[extract_format] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [survey_views].[etl_extract_types] ADD  CONSTRAINT [DF_etl_extract_configurations_field_hashing]  DEFAULT ((1)) FOR [field_hashing]
GO
ALTER TABLE [survey_views].[etl_extract_types] ADD  CONSTRAINT [DF_etl_extract_configurations_include_tribal]  DEFAULT ((0)) FOR [include_tribal]
GO
ALTER TABLE [survey_views].[etl_extract_types] ADD  CONSTRAINT [DF_etl_extract_configurations_include_at_risk]  DEFAULT ((0)) FOR [include_at_risk]
GO
ALTER TABLE [survey_views].[etl_extract_types] ADD  CONSTRAINT [DF_etl_extract_configurations_extract_format]  DEFAULT ('BCP') FOR [extract_format]
GO
