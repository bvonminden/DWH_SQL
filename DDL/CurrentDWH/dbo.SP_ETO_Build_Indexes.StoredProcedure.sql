USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_ETO_Build_Indexes]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.ETO_Build_Indexes
--
CREATE PROCEDURE [dbo].[SP_ETO_Build_Indexes]
AS
--
-- This creates indexes on the etosolaris database which is copied nightly from ETO.

-- USE [etosolaris]
-- GO

-- ETO ables which Indexes are applied:
-- Staff
-- Surveys
-- SurveyElements
-- SurveyResponses
-- SurveyElementResponses
-- SurveyElementResponseChoice
-- SurveyElementResponseText
-- SurveyElementResponseDate
-- SurveyElementResponseECR
-- SurveyElementResponsePCR


--------------------------------------------------------
-- Staff:
--------------------------------------------------------

/****** Object:  Index [PK_Staff]    Script Date: 10/25/2010 16:21:18 ******/
ALTER TABLE [etosolaris].[dbo].[Staff] ADD  CONSTRAINT [PK_Staff] PRIMARY KEY CLUSTERED 
(
	[StaffID] ASC
)WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]

--------------------------------------------------------
-- Surveys:
--------------------------------------------------------

/****** Object:  Index [PK_Surveys]    Script Date: 10/25/2010 16:18:53 ******/
ALTER TABLE [etosolaris].[dbo].[Surveys] ADD  CONSTRAINT [PK_Surveys] PRIMARY KEY CLUSTERED 
(
	[SurveyID] ASC
)WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]

--------------------------------------------------------
-- SurveyElements:
--------------------------------------------------------

/****** Object:  Index [IX_SurveyElements]    Script Date: 10/09/2010 11:25:44 ******/

CREATE NONCLUSTERED INDEX [IX_SurveyElements] ON [etosolaris].[dbo].[SurveyElements] 
(
	[SurveyID] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]


/****** Object:  Index [IX_SurveyElements_Source]    Script Date: 10/09/2010 11:26:06 ******/
CREATE NONCLUSTERED INDEX [IX_SurveyElements_Source] ON [etosolaris].[dbo].[SurveyElements] 
(
	[SurveyElementID_Source] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]


/****** Object:  Index [PK_SurveyElements]    Script Date: 10/09/2010 11:26:25 ******/
ALTER TABLE [etosolaris].[dbo].[SurveyElements] ADD  CONSTRAINT [PK_SurveyElements] PRIMARY KEY CLUSTERED 
(
	[SurveyElementID] ASC
)WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]



--------------------------------------------------------
--  SurveyResponses:
--------------------------------------------------------

/****** Object:  Index [PK_SurveyResponses]    Script Date: 10/25/2010 16:26:48 ******/
ALTER TABLE [etosolaris].[dbo].[SurveyResponses] ADD  CONSTRAINT [PK_SurveyResponses] PRIMARY KEY CLUSTERED 
(
	[SurveyResponseID] ASC
)WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]


/****** Object:  Index [IX_SurveyResponses]    Script Date: 10/25/2010 16:27:37 ******/
CREATE NONCLUSTERED INDEX [IX_SurveyResponses] ON [etosolaris].[dbo].[SurveyResponses] 
(
	[SurveyID] ASC,
	[CL_EN_GEN_ID] ASC,
	[SurveyDate] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]


--------------------------------------------------------
--  SurveyElementResponses:
--------------------------------------------------------


/****** Object:  Index [IX_SurveyElementResponses]    Script Date: 10/09/2010 11:18:03 ******/
CREATE NONCLUSTERED INDEX [IX_SurveyElementResponses] ON [etosolaris].[dbo].[SurveyElementResponses] 
(
	[SurveyElementID] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]


/****** Object:  Index [IX_SurveyElementResponses_1]    Script Date: 10/09/2010 11:18:27 ******/
CREATE NONCLUSTERED INDEX [IX_SurveyElementResponses_1] ON [etosolaris].[dbo].[SurveyElementResponses] 
(
	[SurveyResponseID] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]


/****** Object:  Index [IX_SurveyElementResponses_Source]    Script Date: 10/09/2010 11:18:48 ******/
CREATE NONCLUSTERED INDEX [IX_SurveyElementResponses_Source] ON [etosolaris].[dbo].[SurveyElementResponses] 
(
	[SurveyElementResponseID_Source] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]


/****** Object:  Index [PK_SurveyElementResponses]    Script Date: 10/09/2010 11:19:10 ******/
ALTER TABLE [etosolaris].[dbo].[SurveyElementResponses] ADD  CONSTRAINT [PK_SurveyElementResponses] PRIMARY KEY CLUSTERED 
(
	[SurveyElementResponseID] ASC
)WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]



--------------------------------------------------------
-- SurveyElementResponseChoice:
--------------------------------------------------------

/****** Object:  Index [IX_SurveyElementResponseChoice]    Script Date: 10/09/2010 10:53:35 ******/
CREATE CLUSTERED INDEX [IX_SurveyElementResponseChoice] ON [etosolaris].[dbo].[SurveyElementResponseChoice] 
(
	[SurveyElementResponseID] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]


/****** Object:  Index [PK_SurveyElementResponseChoice]    Script Date: 10/09/2010 10:54:24 ******/
ALTER TABLE [etosolaris].[dbo].[SurveyElementResponseChoice] ADD  CONSTRAINT [PK_SurveyElementResponseChoice] PRIMARY KEY NONCLUSTERED 
(
	[SurveyElementResponseChoiceID] ASC
)WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]



--------------------------------------------------------
-- SurveyElementResponseText:
--------------------------------------------------------


/****** Object:  Index [IX_SurveyElementResponseText]    Script Date: 10/09/2010 11:34:06 ******/
CREATE CLUSTERED INDEX [IX_SurveyElementResponseText] ON [etosolaris].[dbo].[SurveyElementResponseText] 
(
	[SurveyElementResponseID] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]


/****** Object:  Index [PK_SurveyElementResponseText]    Script Date: 10/09/2010 11:34:41 ******/
ALTER TABLE [etosolaris].[dbo].[SurveyElementResponseText] ADD  CONSTRAINT [PK_SurveyElementResponseText] PRIMARY KEY NONCLUSTERED 
(
	[SurveyElementResponseTextID] ASC
)WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]




--------------------------------------------------------
-- SurveyElementResponseDate:
--------------------------------------------------------


/****** Object:  Index [IX_SurveyElementResponseDate]    Script Date: 10/09/2010 11:38:43 ******/
CREATE CLUSTERED INDEX [IX_SurveyElementResponseDate] ON [etosolaris].[dbo].[SurveyElementResponseDate] 
(
	[SurveyElementResponseID] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]


/****** Object:  Index [PK_SurveyElementResponseDate]    Script Date: 10/09/2010 11:39:05 ******/
ALTER TABLE [etosolaris].[dbo].[SurveyElementResponseDate] ADD  CONSTRAINT [PK_SurveyElementResponseDate] PRIMARY KEY NONCLUSTERED 
(
	[SurveyElementResponseDateID] ASC
)WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]



--------------------------------------------------------
-- SurveyElementResponseECR:
--------------------------------------------------------


/****** Object:  Index [IX_SurveyElementResponseECR]    Script Date: 10/09/2010 11:42:14 ******/
CREATE NONCLUSTERED INDEX [IX_SurveyElementResponseECR] ON [etosolaris].[dbo].[SurveyElementResponseECR] 
(
	[SurveyElementResponseECRID] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]


/****** Object:  Index [IX_SurveyElementResponseECR_1]    Script Date: 10/09/2010 11:42:34 ******/
CREATE CLUSTERED INDEX [IX_SurveyElementResponseECR_1] ON [etosolaris].[dbo].[SurveyElementResponseECR] 
(
	[SurveyElementResponseID] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]


/****** Object:  Index [IX_SurveyElementResponseECR_2]    Script Date: 10/09/2010 11:42:51 ******/
CREATE NONCLUSTERED INDEX [IX_SurveyElementResponseECR_2] ON [etosolaris].[dbo].[SurveyElementResponseECR] 
(
	[EntityID] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]



--------------------------------------------------------
-- SurveyElementResponsePCR:
--------------------------------------------------------


/****** Object:  Index [IX_SurveyElementResponsePCR]    Script Date: 10/09/2010 11:45:36 ******/
CREATE NONCLUSTERED INDEX [IX_SurveyElementResponsePCR] ON [etosolaris].[dbo].[SurveyElementResponsePCR] 
(
	[SurveyElementResponsePCRID] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]


/****** Object:  Index [IX_SurveyElementResponsePCR_1]    Script Date: 10/09/2010 11:45:58 ******/
CREATE CLUSTERED INDEX [IX_SurveyElementResponsePCR_1] ON [etosolaris].[dbo].[SurveyElementResponsePCR] 
(
	[SurveyElementResponseID] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]


/****** Object:  Index [IX_SurveyElementResponsePCR_2]    Script Date: 10/09/2010 11:46:21 ******/
CREATE NONCLUSTERED INDEX [IX_SurveyElementResponsePCR_2] ON [etosolaris].[dbo].[SurveyElementResponsePCR] 
(
	[CLID] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]



GO
