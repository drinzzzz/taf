--
-- PostgreSQL database dump
--

\restrict PIePVuD1KZ1vXhFcYB25gs4hWMfQMMsBfSplxDJrIKVyp6E7k4CM85hl11S3amQ

-- Dumped from database version 16.12
-- Dumped by pg_dump version 16.12

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY public.pfa_visit_plans DROP CONSTRAINT IF EXISTS pfa_visit_plans_expo_id_fkey;
ALTER TABLE IF EXISTS ONLY public.pfa_halls DROP CONSTRAINT IF EXISTS pfa_halls_expo_id_fkey;
ALTER TABLE IF EXISTS ONLY public.pfa_expos DROP CONSTRAINT IF EXISTS pfa_expos_venue_id_fkey;
ALTER TABLE IF EXISTS ONLY public.pfa_booths DROP CONSTRAINT IF EXISTS pfa_booths_hall_id_fkey;
ALTER TABLE IF EXISTS ONLY public.pfa_booths DROP CONSTRAINT IF EXISTS pfa_booths_expo_id_fkey;
ALTER TABLE IF EXISTS ONLY public.pfa_booths DROP CONSTRAINT IF EXISTS pfa_booths_exhibitor_id_fkey;
ALTER TABLE IF EXISTS ONLY public.pfa_booth_visits DROP CONSTRAINT IF EXISTS pfa_booth_visits_booth_id_fkey;
DROP INDEX IF EXISTS public.pfa_booths_expo_hall_booth;
ALTER TABLE IF EXISTS ONLY public.pfa_visit_plans DROP CONSTRAINT IF EXISTS pfa_visit_plans_pkey;
ALTER TABLE IF EXISTS ONLY public.pfa_venues DROP CONSTRAINT IF EXISTS pfa_venues_pkey;
ALTER TABLE IF EXISTS ONLY public.pfa_venues DROP CONSTRAINT IF EXISTS pfa_venues_name_city_key;
ALTER TABLE IF EXISTS ONLY public.pfa_halls DROP CONSTRAINT IF EXISTS pfa_halls_pkey;
ALTER TABLE IF EXISTS ONLY public.pfa_halls DROP CONSTRAINT IF EXISTS pfa_halls_expo_id_code_key;
ALTER TABLE IF EXISTS ONLY public.pfa_expos DROP CONSTRAINT IF EXISTS pfa_expos_short_code_year_key;
ALTER TABLE IF EXISTS ONLY public.pfa_expos DROP CONSTRAINT IF EXISTS pfa_expos_pkey;
ALTER TABLE IF EXISTS ONLY public.pfa_exhibitors DROP CONSTRAINT IF EXISTS pfa_exhibitors_pkey;
ALTER TABLE IF EXISTS ONLY public.pfa_exhibitors DROP CONSTRAINT IF EXISTS pfa_exhibitors_name_key;
ALTER TABLE IF EXISTS ONLY public.pfa_booths DROP CONSTRAINT IF EXISTS pfa_booths_pkey;
ALTER TABLE IF EXISTS ONLY public.pfa_booth_visits DROP CONSTRAINT IF EXISTS pfa_booth_visits_pkey;
DROP TABLE IF EXISTS public.pfa_visit_plans;
DROP TABLE IF EXISTS public.pfa_venues;
DROP TABLE IF EXISTS public.pfa_halls;
DROP TABLE IF EXISTS public.pfa_expos;
DROP TABLE IF EXISTS public.pfa_exhibitors;
DROP TABLE IF EXISTS public.pfa_booths;
DROP TABLE IF EXISTS public.pfa_booth_visits;
SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: pfa_booth_visits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pfa_booth_visits (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    booth_id uuid NOT NULL,
    visit_date date,
    is_planned boolean DEFAULT true,
    planned_order integer,
    actual_arrival time without time zone,
    actual_departure time without time zone,
    rating smallint,
    notes text,
    photos text[],
    follow_up text,
    social_ready boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT pfa_booth_visits_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


--
-- Name: pfa_booths; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pfa_booths (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    expo_id uuid NOT NULL,
    hall_id uuid NOT NULL,
    exhibitor_id uuid,
    booth_number character varying(20) NOT NULL,
    booth_size character varying(20),
    booth_type character varying(20),
    raw_text text,
    ocr_confidence real DEFAULT 0,
    pos_x integer,
    pos_y integer,
    is_verified boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: pfa_exhibitors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pfa_exhibitors (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(400) NOT NULL,
    name_en character varying(400),
    brand character varying(400),
    category character varying(100),
    sub_category character varying(100),
    country character varying(50) DEFAULT '中国'::character varying,
    first_seen_year integer,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: pfa_expos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pfa_expos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    venue_id uuid,
    name character varying(200) NOT NULL,
    name_en character varying(300),
    short_code character varying(20) NOT NULL,
    year integer NOT NULL,
    start_date date,
    end_date date,
    total_exhibitors integer,
    total_halls integer,
    overview_image character varying(300),
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: pfa_halls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pfa_halls (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    expo_id uuid NOT NULL,
    code character varying(10) NOT NULL,
    name character varying(100),
    name_en character varying(200),
    floor character varying(10),
    image_file character varying(300),
    booth_count integer DEFAULT 0,
    raw_ocr_text text,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: pfa_venues; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pfa_venues (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    name_en character varying(200),
    short_code character varying(20),
    city character varying(50) NOT NULL,
    district character varying(100),
    address text,
    total_area_sqm integer,
    hall_count integer,
    metro_station character varying(100),
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: pfa_visit_plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pfa_visit_plans (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    expo_id uuid NOT NULL,
    plan_name character varying(200),
    visit_date date,
    hall_order text[],
    booth_sequence uuid[],
    estimated_minutes integer,
    status character varying(20) DEFAULT 'planning'::character varying,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Data for Name: pfa_booth_visits; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pfa_booth_visits (id, booth_id, visit_date, is_planned, planned_order, actual_arrival, actual_departure, rating, notes, photos, follow_up, social_ready, created_at) FROM stdin;
\.


--
-- Data for Name: pfa_booths; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pfa_booths (id, expo_id, hall_id, exhibitor_id, booth_number, booth_size, booth_type, raw_text, ocr_confidence, pos_x, pos_y, is_verified, created_at) FROM stdin;
\.


--
-- Data for Name: pfa_exhibitors; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pfa_exhibitors (id, name, name_en, brand, category, sub_category, country, first_seen_year, created_at) FROM stdin;
868ed2f4-56a7-4785-b1ba-38e695c14f74	滴露	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
8f8b68fc-3b39-4284-ae16-9fdda0ecb3f1	米团数智 Miture	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
f941f738-157d-4115-bb81-b9f462e73868	伯纳天纯 Pure Natural	\N	\N	\N	\N	中国	\N	2026-08-07 20:04:25.048155
ea74444c-50f0-4c83-9cd0-a7230c91cf35	空青	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
38d3919e-de65-4231-88fa-904bc8de0797	声博士	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
78b47dc7-45c6-4491-8c51-c239dcc30928	谷米 Gomi	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
996c5222-66d4-48cd-9a48-5018889c6017	乐金环境 Cobos	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
bc1cdcdc-eed2-41ff-9635-407cf1191f72	山东雅尚名品	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
4e2231a2-6e6f-4a2a-874a-9fe78a34fbc1	乐宠它	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
34ff73aa-4949-43b6-abf7-0a29dbbd2fce	艾露森友会	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
7b398cc4-f6df-4ac5-b13a-663b0e9c01ea	安眠	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
c8e92a5d-14e6-43b3-a47b-0617ce094efc	黑	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
a212fca3-8bcc-4c16-953d-ce5d38837174	星杭科技	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
af93b762-fcc2-433d-9413-26316fb12691	伟文 Weaving	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
10ddb386-ed4c-4d81-84dd-f41e698ab9c3	戴亭乐	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
29aa46ff-872c-4af7-8896-855774d1b124	贝小	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
459dfeed-362b-4ce5-bbf7-5959351dfeb6	夸贝 DDLCOL	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
24be6dd8-84f7-4d01-8504-712a51a2b7d4	Bxxm pet 爆宠	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
033d387a-0930-42e6-9336-ab73c682663c	W.Mollis	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
7ce39841-e5b9-40cb-bfb9-222a0c1a9a28	魔兽师	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
f0c7235b-3d2b-44f9-a69b-a271d376a940	Coraltrucks	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
81af0614-2a55-4e3c-9a35-bb67f665a580	星辰智宠	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
0008054e-b8e5-4871-b1d1-267f0e376fd9	悉宠	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
e099be20-4197-4143-9f43-b7d7001d2ef0	万鼎	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
6c71eade-6d72-42cd-9b45-62ee076a586e	敬诚	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
00c8febd-1f82-413f-bb14-4dee805dff1f	爱立方 LOVE AROUND	\N	\N	\N	\N	中国	\N	2026-08-07 20:04:25.048155
08d868d4-cccf-4f0e-a6a2-a9e09524cb24	玫斯 METZ	\N	\N	\N	\N	中国	\N	2026-08-07 20:04:25.048155
8954897c-7fc4-4a4f-8b4c-f373ce3e0f47	好爸爸 Kispa	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
e475615b-4a9a-4c85-adcd-79241f763752	新菱 SUNLIN	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
15185f43-fbb2-4f9e-945a-2af47bfaf122	爱丽思 IRIS	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
3b171dcb-6beb-4614-99df-0da4735ba2ba	荣燊花园	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
0a4bf5b2-6dfb-40ec-80f3-e420e7578e28	必盈科技	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
15f9260a-0600-4532-9e33-7a5a44d9e005	瑞森卡尔	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
3ef0062d-2c9f-41fc-bee6-daf0e742ef9a	舒乐氏 SoleusAir	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
22201f6f-3003-4d1b-aa8c-13d97ef61b09	英宠摄影	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
18179c55-8b4b-4876-91fb-40951efdf8e7	龙乐谷	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
234a561d-ea25-46e2-bbbc-6f503d51a9be	paaaata	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
7e36cece-c94a-4e80-9c52-f8c4043bc03f	喵卫 扫床机器人	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
40a07bc4-eb13-4fda-b2ee-5498765622e9	宠会说 三棵小草	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
c33b6283-4b12-4bbe-aad1-eedb0c6c0efb	益贝特	\N	\N	\N	\N	中国	\N	2026-08-07 20:06:23.341589
03ff2ed0-0b7b-42c5-a4f4-8a51395d6388	宠享科技	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
21fae4e6-6ba9-4447-bf7e-45203727cef1	佩特家 智能猫别墅	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
d585de8e-003e-455c-b588-c6b4bc19cde9	帕帕尼 PAPANI	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
d55f097d-b7a7-4874-a649-471093f31199	myPetta 派塔	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
f9dd03e1-95a0-443a-af52-4a4b3f4ab5ba	佩优优 PetYoYo	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
ae5d11e4-687f-441f-99a9-cbbde26ab146	众宠科技	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
9788d930-ded2-4822-b081-0961c5e06859	巴贝奇 babagi	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
f97f8801-b2a6-4f60-a9cf-7df4819dffc7	趴趴爪	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
8f87fc08-0ab9-4829-9305-59a5412d6388	宠信	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
0d01735f-7072-4f45-a5df-99945b9d7a2d	有迹	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
b307161d-ad52-4236-8a66-c29908f0d480	豆柴 Docile	\N	\N	\N	\N	中国	\N	2026-08-07 20:04:25.048155
9b6d566e-5029-4f44-b3ce-6190ab38151d	华兴 Huaxing	\N	\N	\N	\N	中国	\N	2026-08-07 20:04:25.048155
688d5a03-6b79-435b-8ff8-a716c26d7a5f	OKI	\N	\N	\N	\N	中国	\N	2026-08-07 20:04:25.048155
47f4b23a-02b3-4b14-a2dd-da2245ffe3ef	飞派	\N	\N	\N	\N	中国	\N	2026-08-07 20:04:25.048155
2089b434-8ae5-46bc-92c5-9b3675ecc954	先锋 Funyoung	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
76fe5037-37ac-48a5-8799-8bd8f4398464	米唯 Mivi	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
d373537e-4064-447e-b9f1-997f9150a66a	星之屋	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
a6c587dc-e09a-411c-950f-be155bd4c67a	贝大奇	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
83650473-d9da-4ef8-aba6-ea38b83b2a1f	锦辰智能	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
67c59f5d-da52-4c87-b142-6928f347e42a	上恰贸易	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
0a64714c-c787-43c3-83ff-f89787c69f17	伶宠科技	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
c8a0f4ea-e99c-48f7-9187-daf82ff9fb1d	NINIPAWS 尼尼帕斯	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
f7367cdd-4e05-4452-8970-61e489f874ab	宠洁仕	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
1cbbde1c-414b-4693-b194-6e6b34def807	登虹	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
15cd949b-7235-4dca-b29e-a095dadd12e6	Gemipet	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
ac9068d2-4961-4180-9947-8a733a9f0327	家超	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
23f9bb39-cc68-4ace-97ba-4916ce442aa9	中国平安	\N	\N	\N	\N	中国	\N	2026-08-07 20:06:23.341589
4426e08a-b228-4bd7-849f-88b99fb391d0	宁波	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
48cbf592-0b69-4acf-a00a-1a05ee1bfca3	烁壳 Soikoi	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
aabfa5c2-0c8f-4a8f-a0d7-6ad65ff83378	品智好	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
9f5f5a53-f8ca-4ab1-9f29-202bdfd3f4cf	贝兔兔 Beitutu	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
707d46cf-fd45-419d-a7e1-1f920c984068	狼璟 Wolf Spring	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
0cb27a16-396e-4387-ae31-0d625ad41d46	三合塑业	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
29603b6d-3c6c-4003-93c0-6b52612d30a1	绒壳 FUREASE	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
9d411bb6-0e9f-4d14-acc9-0ece5fb99992	曼宠	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
073aeaf7-926c-4bf3-be92-fa410b6c52b8	DHC	\N	\N	\N	\N	中国	\N	2026-08-07 20:06:23.341589
7945bb53-f06e-401f-aa5b-2ddcea4a69a0	夏蒙电器 SHARMOON ELECTRIC	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
8fc3257c-6dbf-4c7b-882e-25446aee1271	卫仕	\N	\N	\N	\N	中国	\N	2026-08-07 20:06:23.341589
f29c2533-caef-4c8d-9c72-049ad3ce3411	谷登	\N	\N	\N	\N	中国	\N	2026-08-07 20:06:23.341589
ed7441a5-8fe1-4ef2-a1d1-e570ab69891c	宠上宠 petsuper	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
b0101afe-99ea-4f0d-a189-1f2459f16b48	聆瞳	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
aef0fb22-3a76-4777-ac72-9636cfe57705	迪锐	\N	\N	\N	\N	中国	\N	2026-08-09 10:15:43.067702
23d8c562-f248-4a3b-9d9a-fa992c37f6b0	BLUE	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
a42e6179-f639-46df-adbe-f1573d20e973	贝利宠物	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
f11df049-55db-430d-82cc-f84143cd97fe	iCICCO	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
86e96a5f-e64f-4338-bbd6-dea41a0028d9	宠帅	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
9dc40d99-db9c-4ac5-b12e-078b12ca8e35	呵宝MDC	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
d3b2bd68-bc2e-40f1-8b24-00ade7e66ccf	耶利儿	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
c4969474-8d25-4f9c-ba7c-a4ba60f425e7	赞乐	\N	\N	\N	\N	中国	\N	2026-08-07 20:06:23.341589
325765a5-d5eb-409c-998b-3d33bc8bdabc	严医森	\N	\N	\N	\N	中国	\N	2026-08-07 20:06:23.341589
82ac2961-e678-4b29-85ff-cde9c64033ce	乐益添	\N	\N	\N	\N	中国	\N	2026-08-07 20:06:23.341589
b9c2b245-dddc-481f-a783-7d421be6b5bc	MUUDOG 目目哆格	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
40fb9b26-5dc7-4ea1-894f-710791fd467b	艾嘉 Marksign	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
76c60a53-89aa-4c13-a1c7-6a1893dbaa09	利常宠物包	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
56548eaf-7ac5-49a9-9e1e-aeb776c1796d	凯瑞酷域 CAPFER	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
b810472e-da91-42c3-8c99-f7ae15eb616f	帅克集团	\N	\N	\N	\N	中国	\N	2026-08-07 20:05:07.037986
94ce425a-afb4-47fa-b5c7-39d217307d16	万嘉	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
13658b0f-e8f2-4679-b0fc-9a89508ad087	HuHu pink	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
1a0a9d46-c86f-4661-91b5-6e04678d9433	优时	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
9a01e512-f56a-48b5-9f99-9194be11b15d	CLEERUNR	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
66c7417a-4747-4b25-8a64-34082d4818fe	PORT 青岸宠物	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
a209cea8-bf73-4685-8099-afebdf5f7baf	Hazo 赫岛	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
785433df-c7a0-4225-affb-b5210962a140	臻爱毛球 FurReal	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
b86ffe8f-b21c-418c-a3ce-14e0d7f96a0c	咕噜 Purpy	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
7545d6b5-bf28-4dbe-b9cc-a347ea1ffe59	ToddleWoddle	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
c161fef5-49d4-4920-9d89-1281b0b864f3	米南宠物	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
6afd90c2-b8d6-41e6-8e6d-062df8465770	凯帝亚	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
e4fb259f-baf0-4ce1-8527-84708499f5c8	娜诺宠物 Nanoope	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
c64518f7-988f-4be4-a8e5-57c8336ac8ac	KJM吉美扣具	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
706291dd-4d78-492d-ba03-f589b69d5423	宫囍 & 巴卜卜	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
32359e27-81bd-41bb-8e51-d761a7451b48	大饼宠物 AR by dbBoutiques	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
8fee438e-235b-4908-a52e-5bbd71b82417	Nyotail Bigbibi	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
8212fb84-ad50-46fa-82d7-d635abc34806	山东亿盛宠物 Yisheng Pets 金冠宝贝	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
c69f2221-d82e-4084-a90f-790047224354	楷航 Wan talk Pet	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
2c590060-6d69-427e-835d-f779be4e30c1	Hoooot dog	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
4eac7171-2eca-4ddb-a9f5-0b6bfbc18fb1	德高	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
a6c4ae70-3716-487c-96e0-25583b9fe02a	益宝宠生 YBPL	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
6b8e5191-14f0-4a96-bbc5-cfac4413afdd	宠觅	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
a0055d00-95a4-4ec3-9c83-0335907a826f	EASY	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
d2667834-7cb7-462b-acc2-b2c3308a9a77	WonderFold Pet	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
fa7ad44f-9ff4-41d5-95c6-f2c0e7fe7d45	亿龙	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
90f5ffd7-67fc-42d0-8ee9-15cc06c48cee	固家	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
65a7259d-c5cc-4465-8222-3788a228cce6	MR. ROPE	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
77e848ec-4f55-487c-b5c4-e3b9b6859500	Doggie	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
50f196aa-0326-4a4c-b3fc-f1ee01902224	乐霸 HIPRA	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
bf75b20c-6baf-43c2-8ba1-0fbb6838c4b6	璐硕	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
c78e46eb-4aee-470d-9a54-ee4d2dd84796	宇芯	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
e160dbab-05bb-411b-9bff-d7ce45c92694	玉龙布艺	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
1a99c029-6437-4da0-8e6f-cee1c852bb1f	振宁	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
b8828227-05c7-4f3f-96a7-2a3a612f1332	牧宠	\N	\N	\N	\N	中国	\N	2026-08-07 20:06:23.341589
8cbdb887-342f-476a-b934-fc9997fe28d9	枭泽	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
4c1866a4-fae2-4094-9467-be628603b361	元医	\N	\N	\N	\N	中国	\N	2026-08-07 20:06:23.341589
6155a2c0-58a5-4b36-b671-33e7fb428966	JOLINPET	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
51717487-bab4-493c-ac6c-51b56aac41d0	MikDaddy 宠物服饰	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
3f2583eb-551c-41fe-8dba-2b3985095de1	米高	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
d2843e3b-0149-4587-bba1-37d0b980cfbd	WANGWANGMIAO	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
6416c8e1-7546-4e38-9703-24c91cc483f4	Ohmypet	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
9ada05ba-e0ae-45e0-8dc0-eb5bde26fe3b	Pawzseek	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
16eba666-99e7-4505-b929-1357cd659788	鲜粮说 FreshTalk	\N	\N	\N	\N	中国	\N	2026-08-07 20:05:07.037986
3d759522-e23d-4e68-a4ad-3961aa1e656b	森诺 Senno	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
52fe8324-73aa-48d8-9e1e-358b60b7059d	嗨皮	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
167fc02c-84d4-42e2-acbb-6dc5cd380fd6	熙牧慈	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
e2052f3b-1c86-4e4e-b0bb-8186ad10d38c	齐达户外	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
4e8eeb48-81cd-4bed-9b9b-43c9877d1e81	嘉上	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
8e2e6e1b-9205-417d-9337-aaee25d4501d	富鼎	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
9b77ee3f-8771-4e67-a039-d1f4a96b0714	爪爪古蒂 Paw's Goodie	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
285b02f0-5fef-4b93-8e28-ab055a1ea10a	旺盈	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
e5d31386-7d57-4e63-959f-5086015c3d6b	卡贝拉	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
7b744f03-6b12-4f3b-b07f-21339fa35db3	奥普林	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
177ec494-4962-4aba-aba8-f04e8fe8bea3	爱娲	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
c7997afb-7a87-476f-a8d1-c22f5e8b2491	SEEMDOG	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
e52f6cb7-f6fd-4151-a6c9-c2fa03c65850	petseek	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
31971bba-5fa5-47db-8e04-3eb60cb178d0	LAST LOCK	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
042b802e-074b-4008-9923-06ac46a3c18a	Yilong	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
4643734d-6967-4745-bcf7-a498e7451d03	BuddyArmor	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
27d0afdb-2446-4b9b-a59e-ac0c23b6acbd	陪伴它 巴朗宠物	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
bfca851e-5067-41d5-99aa-2e3a1032f554	绳子先生	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
7a428255-467f-4eb5-9707-176ea4fb3028	云峰 泰联 techlink pets	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
eab9ceaa-12ba-4fab-8849-a386df71608a	Yuxinbaby	\N	\N	\N	\N	中国	\N	2026-08-09 10:16:35.811373
d4f735cc-b45c-4472-9464-07cbf388cf02	景蓝希 CAT	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
987add87-268e-4a0f-ae37-171fa7295e58	湖南利达	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
bb7bbe26-ffd2-444f-ac58-54fde63ef393	墨山	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
c8fbad5f-3654-4a04-bcca-7e11327a5fd8	FOFOs 两只福狸	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
81872b25-bea9-497c-bd89-cf56c89ff957	宁城袜袜	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
f340714b-d7c6-4e42-b85d-8c8d9491566d	海城冠源	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
3991b321-d7d6-45af-8c8b-9acea33f85a7	祺龙	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
eff968ec-1d68-4a9c-8439-cfc7e92534e8	黄白豆宠品	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
2267e389-42fe-4a25-80bd-ab0532443ad7	上海朗枫	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
9c7fc7cc-0892-4868-94a7-5dd3758e0d31	山东铲铲	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
30876c9e-ee4e-4ce8-b39c-0965acbba894	华鲲猫砂	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
da999ebb-e513-4375-8882-d89f7e64e2b7	霖铂雅宠	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
13a9859c-8d08-4fa2-adca-4cbc7b1b6b1f	喜萌	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
5c330385-72ae-4126-9783-29a2457a3152	超人强 SUPERQ	\N	\N	\N	\N	中国	\N	2026-08-07 20:06:50.304106
3a496288-d422-460c-9e36-a1049088591e	宠贝星	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
39f9ada4-5bb3-4155-b405-7828cc3f3a67	它宠 TA PET	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
e4382d63-0576-4e48-a8c4-86a7cf50e42c	金澳鸟笼 Jin Ao petcage	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
a351db61-2aed-4cbe-91ab-80aa6bf80a86	澳菲尔德	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
a5e6ef8a-1b72-439d-acd7-21735a33fecf	山东瑗羽	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
f0105424-74c4-4a7e-a886-d314ced9d784	仟佰特	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
6c93860b-a9e7-4643-b247-a3e730d9e84b	fuka 富伡	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
dcdc55f4-7f9a-4356-8e77-80804c891c59	墨华玩具	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
f3899ca2-b781-4083-bec9-997fdfd65867	博森	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
7faa1c1a-d855-4ed8-99d8-d305351d01cf	潮州恩宠陶瓷	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
3c4830c4-be99-48e6-ad2b-68c6b5aaaa6b	杭州	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
b52a0d4e-ebfc-487d-a6de-70b7f17d2ee9	青光	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
a11a9a8b-f863-4f32-abbc-29738bdf4173	悦	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
6a58ef8c-2f8a-4ad4-8a72-3323709bafd8	黑山	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
7281c762-158d-4524-844e-b51f784f8b1e	汉贝	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
3da6cf72-9e83-4eac-9946-3e7eb19de731	ABST爱贝斯特	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
9c1a5ea2-8239-40c5-9194-e942d94711f0	ONIARI	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
63d3655e-ee53-489c-92ba-5ee031316e7b	Moco doudou	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
debdab08-1db5-4f7c-9ea0-f6477d7728c4	ROIROI洛伊宠物	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
f8e5b028-b85a-47bb-8cf9-69a81f13a69a	Fluff Nook毛茸茸Pet	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
b2d17392-8c44-4459-a778-33c63da130ef	檬宠星 MengChong Xing	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
b4a39465-e22d-45e0-ac2e-f5675bd9b57b	摩宠 Moorpet	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
f6f54267-6396-44b3-9b96-a96be7e8fc27	HAOOWO	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
b56ffde9-a87f-4cae-82bc-e340474ed478	诺薇娜 Novina	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
b1b58ebc-bdc6-436c-98c3-8b93476702a9	VIGOROUS	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
b7066972-7038-4020-8124-30c8851a903b	宠小探 PET EXPLORER	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
0d2cc7e0-18fc-4ebb-b395-6fff213bc293	翠恩	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
cf6296c2-1e77-4890-925d-24f7b19b35b7	浩	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
55a24341-13b8-454f-a803-41611c9ab00f	伊贝斯	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
ef4505d6-8f69-4d8c-a641-a3eaded08852	ANFFO	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
8a946a75-38af-4056-8899-7bc802a1257d	山木 SANMUK	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
83fe58ff-ae88-4926-9ab3-085f4a7e9b68	蒂诗澜	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
86fd1ba2-e33e-488d-a58e-c907ffe7e3d7	宠辰	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
760a3cab-0f56-47a5-a3c1-3a2711b07acd	滴心喵 Targin Mew	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
fdc9f17e-0323-4e3a-bc4b-d024ec928247	上海领养之家	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
83ddf7d4-a29d-4c14-89ea-422910658675	胖夫夫	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
3794fe3d-11e7-462d-88e7-37be72fb024e	上海领养日	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
18eb1176-2681-4ac6-a5c2-dc49bfe0bf95	上海宠物友好日	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
c8e10262-ea0f-4a9f-adc6-357101087243	高架猫救援 shangha	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
ab17e291-d336-4ead-88ca-63db21cf523e	攀越	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
a4190f53-8d9c-492b-a72e-4d1b6e5a05f5	遵联化工	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
532d4b1d-f67e-482c-abe3-b2918888b083	欧适园 oasispark	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
16ed08eb-ba84-4a24-9c8a-1b4422514b38	解忧森林	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
a68149f2-7245-4400-bac9-9b891ec53e8d	艾米宝贝	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
d52b06cb-5a95-47b6-932c-29ad26db6e67	纨宠 诺物	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
d2211f7d-78b5-483e-ba36-e29dc7d4be42	创攀 Champion metal	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
80e093e1-8bb6-42d7-9735-8942e37177f3	橙皮宠物	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
69651f9d-5c5e-4d30-a4b8-7fc165d128af	诺	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
e8da35f2-fe70-4b9b-af6d-d2b1de6db650	喵仙儿	\N	\N	\N	\N	中国	\N	2026-08-07 20:09:54.45334
574ee210-dc6e-46eb-bd9d-0a733ab23ae5	瑞澜	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
c1a21704-59e1-4abd-89c7-f2a8ff59fdc5	馨宇诺 Warm Universe	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
2ee01434-a39d-4603-a2b3-d4a62ef61e8d	幸运工猫	\N	\N	\N	\N	中国	\N	2026-08-09 10:17:22.817006
0a2c6e1a-486a-4d16-a33c-204250aa3082	雅立Youngli	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
95257fc4-07dc-4a51-90b7-483b78faff7b	硕主 OneZoo	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
75ef0be1-0fe6-49f7-8756-5623b4341bdd	临沂坤承	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
16387f66-6379-462f-a931-1c742919435b	盛达	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
f89a5c07-8010-48c5-a22f-175e598990bd	PSITTACUS	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
55830f50-b58e-4e3b-a915-82b1ece41c5a	嘉之源	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
b265fe7c-5f7b-4466-aefd-4e8f9c97e582	金秋界	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
7e2c9909-b1c3-4a9a-be1b-dca5be93383d	巨峰	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
77f2a049-636b-4168-b632-a318234e1066	3A	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
739556d0-f7b6-49e6-b308-81ddee9cbab6	宠趣坊	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
ad31896c-bda2-437b-92b3-0370057708f6	筑筑的蜜蜜花园	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
79130bd6-d9be-49b9-86d0-982a17d99bab	翔羽	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
60ae3a52-1979-420a-a5ac-178e3c75a3e3	精灵族	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
932437ac-c402-4ac4-aaa6-de25e3caa90a	双马工艺	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
16fc6868-9fba-4e81-b5e8-cdebf6a2bce7	臻邦宠物	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
a83f8afb-6640-4d86-b06f-62420ed28f3c	杜老汉	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
31e5451a-06c0-44c1-a22d-2de3a7779336	小提牧	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
bd7df814-17c2-4d8a-b474-a9190a19177e	鑫粒亨	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
8f69a067-207e-40e8-a0a3-fac4c83f7c58	麦道	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
85f675be-8243-45f6-921a-8d6f3685ebfd	守护鹦鹉	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
18ae585d-2550-4691-a332-56193cf4f056	行动亚洲	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
0ef2e9ce-d6eb-43fb-ba62-310cf2251baa	维特摩轮	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
cd0a3bdc-05e4-44ec-8c31-2cafcc13af50	绿洲环游	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
004f769a-0765-4de9-aef0-3b38f08acb71	安	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
04cf6ed3-8173-4abe-abe1-368e7c47eb43	贝瑞宠食 Berry	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
5dbc2be7-c670-4c18-a27b-8ae530557a57	Dr Parrot	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
89ce51e0-7a98-4f76-a3a6-21dc287cb901	渣幂	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
b0e503ca-9881-4fa3-9093-97cd99cfdfd8	小	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
98ccc9e6-2d1d-411b-b901-0847f37d6fd0	oh my little	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
3dcb99df-b8ac-489a-854a-a4c7f0a9048a	欢羽	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
6491c799-72f9-4977-b34b-b5c0c4d663a9	否臻	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
64280dc9-8af4-4432-8db3-69d9f18f7371	优嗖	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
4eb820c4-73c2-4618-8647-5737560106c6	爬满*	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
1d0fff40-0d7f-4a91-b895-1cc75a9a8d8a	富鑫	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
5b72c73b-0b35-4eaf-9f5b-b74e04cfb6be	木古西	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
ca793309-3c25-4c0a-9ccc-8de4830d8d5f	POPOGLOW	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
811b6a9b-398a-4953-b85a-10e040948d7f	魔花 Witte Molen	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
599bd174-f38a-4412-ae4f-8a18cecf74bc	娜塔莎 NATASSA	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
434d6368-6e52-4a3c-93cb-548dc6fd14a3	pet food	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
2c160a22-3091-47ba-b08a-887b0c25fc50	鹦鹉博士	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
48ec85b7-02e8-49f8-838b-18bec1579f41	囧家	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
b5881d07-e843-4859-8b3a-5c77bc2adaaa	百洛仕 F10SC Hagen Hari Hagen Exo Terra	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
d48658d3-b07a-4ea7-b078-8205f418fec6	YOOSOPET	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
36560cf1-33f7-4c51-8b73-ba0cdada383e	养爬姑娘	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
d27bd6ff-4e11-45f3-8898-e8c618f527a0	SRBA国际 天竺鼠锦标赛	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
0cad0e3e-1e5d-47d8-9b6b-1fc11ca6877d	美克	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
1174524c-fbd2-4991-8427-ad6e7ac2e51f	洛娱奇特	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
70bbeeb0-1a2a-420a-8389-6a1b6e5c4bb8	喵星宠物	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
aa6a9f51-8ec0-46bc-935e-67bbfaf88bd6	新派	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
f06c7bd3-d07a-414a-84ce-51588e47167d	卡酷	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
e869fc18-2648-4fe7-a348-dd989b08448a	异宠	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
f8219cf8-692f-486e-a066-f4e0d1e02438	Greenstory 童话世界牧场 Burgess Excel	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
85f19d85-41df-47d5-986c-0603f7e58304	豪庭	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
10591e90-237d-4ce2-aba4-f5abccf6cea5	宠之最 PET FOREVER	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
36128397-d513-4046-a51d-0c4cf66d127a	威霸 (简报)	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
84ab1cda-9fa4-4c92-ab37-e81cab01a0d2	OPM	\N	\N	\N	\N	中国	\N	2026-08-07 20:09:54.45334
4f78d685-4bb9-49c4-b202-287368b840d3	蓉源	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
e8c1ec9b-8976-4f87-8606-2fecb28a34ee	机动	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
7455c6d2-2edb-4054-8ec2-5c2c99b58841	予诺 佑宠 YUNO	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
c3a5a33c-8861-4cbc-b06c-66dda4f71f57	喵	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
8d53c73b-ade2-4160-ad60-a3e4f49b2111	古鳞精怪	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
66840bae-5b6b-4187-9226-dd187087e6d0	维尼小镇	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
feb46e50-a7f3-4edd-9528-6d2006e6e20e	为鹉帝	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
0321a012-069b-4275-8c5f-c45a7a30142e	言之易	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
5066f406-f4aa-4b43-ae56-95cd6efd0b22	喵米鲜圃	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
8546d100-a56e-4a7d-87a7-c8da9fe2a1ae	宠艾哒 Chong Aida	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
2bd70776-0abe-4504-9124-87c48f080054	安森	\N	\N	\N	\N	中国	\N	2026-08-07 20:09:54.45334
4b606530-289e-4b64-b216-6af8f31ac3bb	Dmmzoo	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
efb2757a-f342-4ec1-b8cc-da71beb5a4d1	萌叔	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
82a95970-0578-4cef-9a9f-18cdccabc3f9	顺婷 居梦	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
f700f414-3179-4ffb-b97e-1b358dd0649b	喵大园	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
51a87664-190d-4455-9ffc-ce929ecd15d5	Meshy	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
983f8352-0efb-4766-a9f1-45ba94a6045b	苏猎	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
ea56f3b0-6f93-4793-9f30-24cff525de19	学术猫	\N	\N	\N	\N	中国	\N	2026-08-07 20:09:54.45334
773baa40-3019-430d-8430-4e3470141f68	百轩	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
43629dee-411a-4cbf-a6ac-2cc0d4e7849c	宠睿	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
74f7f578-fcea-4d17-8559-25869d69f513	玉芙莱	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
eccef3f7-df01-4d04-9d2f-cf9af74bd2a7	毛猫最爱	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
8b26f908-1558-4781-8ac5-3d471796cf56	暖绒萌宠	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
e1647f60-44cb-4cc2-b2e3-f57c6f7e9c45	宠塑	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
3374d387-e988-426e-b6ce-49dd5af07646	iavyspace	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
5b742409-70ea-47eb-82cb-726163c6ebff	帕森物联	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
3efe6c71-45f7-4412-a11e-e5aaa9ed65bf	江霁	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
dfe9438e-8df2-43f8-bb97-ce842e0f648b	安徽鲜酵	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
42306f9e-1236-4ddf-99b9-2d49b386714b	Paine del	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
d9c749e6-fd5d-4afd-93ef-df565feca84c	咕噜 Purry	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
f01d0954-cfed-401b-bf0d-f3c0ad1bbb8a	新高度兔贝滋	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
6ee018ee-74c4-434f-82b2-5523225a25c5	神奇动物在家里	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
c302f6fa-920b-4592-824d-10c65f1a2d14	蜜袋鼯在萌萌森林	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
0c8c525b-f7d1-4771-9d86-1715c58d5c82	万萌	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
e1eb946f-46c4-40b6-bcad-635ce45ae3db	宠现江湖	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
02a849d8-0229-4577-b9bf-8cea2135d8ff	辽宇	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
b7511ffc-8560-436d-8e2b-dd17908f2b3c	宠哆	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
3bfa8d3f-6bd7-4339-9bb3-683194dd2c12	喵草集	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
bb603d40-873a-4a0a-b75e-37d6f0f11094	百特美	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
b5500657-5fc7-48c1-aa2d-bae55667dea4	优必隆	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
ea7a5217-c499-4d46-964e-0e2bd39217a1	加成达	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
461b46f0-4428-443f-bd86-650e94c3dd66	瑞鼎毛毡	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
8fd04de3-9a52-4b15-b237-f77392a12572	LALAHOME	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
9903237e-b7e9-4b85-b2d7-2bed70f923e0	意潇	\N	\N	\N	\N	中国	\N	2026-08-09 10:18:14.708453
387e939b-adde-412f-beb6-d43142ad5e09	慢奇	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
058b4d27-5da0-402a-b21b-0485d3e5213f	哈妮尔	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
090bf45d-963c-4449-a9a8-6267f9eae2dc	犬赛候赛区	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
169e9fde-f178-4f41-b029-3678a10dc40e	盒马	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
5db747f1-2bb3-4a2c-a5f8-7cddeab0e9a8	乐优	\N	\N	\N	\N	中国	\N	2026-08-07 20:11:22.567049
ecf77e78-a16f-42b5-a8d0-aaa855cd8b98	派蒂	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
f00bdab6-ec19-4247-860c-ba572fd12334	鼎博	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
28969ad0-0845-498a-8d12-e6ebde21bf93	昂立	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
96481b41-3534-4c60-ab86-1e49f658e588	中辉 宠物	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
3230b01a-fe7a-4024-b9d0-ade69f642d72	宠爱王国2026年第三届上海国际美容师邀请赛	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
2ffd38cd-5b17-4d05-b924-8acbdf83eeb0	娲宝科技 VABOO	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
84d9bf27-4b7f-435f-bd7d-9f30068f840a	FRESHIPPO	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
971924c2-4b7a-4dc7-8cc8-6cd0625cf8cc	PAIDI	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
f50b047e-c3f7-4e2c-affe-8c1597cb4186	麦利仕 鑫都	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
ea9aedb9-3006-48f5-a25a-418c37070976	佩蒂	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
f29eeaa7-cd50-4aa5-b3ca-211aa35bb2ee	东塑	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
1ed8c9db-8c89-4136-9681-1c7ff7173879	宠安坊	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
216fee1a-f245-42ee-b25c-6d4203f21b68	有哇周边	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
1f2774e0-3769-4aed-a754-3adcdf09588e	劲耐德	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
25db78ab-191e-4a81-8fd0-848f94912109	泰满嘟 Tinental	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
5ed0d607-dd29-4a4a-b0a0-d48bfb6b67e5	斯塔比 SGSTUBBY	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
4983a78f-1216-419d-a7ce-8c3b3008dbf8	清轩纯业	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
d2aa0b98-1376-4e11-8ccf-66ebd39799f5	龙爱亿嘉	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
89c4741a-0c2e-443a-becc-f98363c99613	墩墩猫	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
5ca46c4f-ddcc-4265-a1e4-551219decc0c	台州国贸	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
35e60d90-b6bd-46a2-a9f3-bc0027c1eb3e	蚂蚁HR	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
bdb47ca8-a90e-46d9-bc61-22b7baa0cf28	萌小泽 PetChat	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
61a4b1eb-7478-4a29-923c-cdc06869a3fb	摩牙出行 MOTA PETPAP	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
befd91d7-9b38-487f-a2a3-14d42c5a5503	山东斯昱	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
7c2ba5de-08c7-48ef-b6fe-ab23884daf52	康斯坦	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
d885dcf3-4c11-4f9b-bdff-9c6687d89c86	贝乐佳	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
996d0c96-daab-48c5-9ff2-d41db2762e2f	江苏	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
c9ccbd47-166b-4855-a8da-ac32154c1c38	呆萌猫	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
ce9aefdb-fe40-4c87-a963-67384631109a	uocapet 养它	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
5f48d87d-aef3-4a9a-b9dd-299b809e7b1e	猫岛 CatsIsland	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
74f62a92-fc82-49c5-a17c-e66c3790a9fc	雅士达	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
72478024-e901-4395-a969-cc730a47d51b	悠澜	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
b463c3f5-b8c1-401c-83b3-763d203bf53a	米老鸭	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
9b40849b-4f7d-4808-b303-4e310b9fa1ff	香道尔	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
9e564233-54b4-47ad-a7ea-e4f1f8b0ad6d	爱博尔	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
cac4e787-1a69-45db-8a57-1dce424b894b	建星笼具	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
dfde108e-98f7-41c9-8473-0927f294a2d2	富宝	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
2a77cf14-0e20-484b-9ed2-7e4c6e1f60e3	福赛生物	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
83baf939-71a8-4ce4-b479-58b0d47b44b0	美宠汇	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
81d4aff0-115a-472a-9acc-90bb07251943	煜烁	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
9b3036d0-455b-4e9d-a45e-1e12becf7c87	多莱米 DOREMI	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
2f0b2d13-e889-4428-b170-4a996d9fcbd7	洁博	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
daf537e0-8ab8-4277-ac8d-6bca3bbbf984	洁优	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
163647d8-62f3-459b-a7d1-e21aa102cd99	飞谷剪刀	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
7a9b8bda-3848-485a-b00a-7d8201b909e3	炼之钢	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
efb4d75a-1675-4725-9bbc-fc6f2ec7a1e0	番茄尾巴	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
8723c92d-50f9-488e-b995-a6d66a75dae9	星光陶瓷	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
d7bc187f-c461-41eb-9879-f1cca6a524ac	新华莎罗雅	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
d5989b39-6b8b-4df5-9922-c0ec075dafcd	永军宠物	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
fff0aabb-6f8f-401b-b5ec-780749c18e81	微盟	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
d9d49f3d-7526-4ebc-be2d-9c3c72bf319a	堂宠猫咖	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
930be98c-467e-4454-a84e-ad4ffc753c3a	精纯电子	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
1da1fb1d-71cc-4ef8-ac91-d9251923ac33	运宝	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
da088e1c-1ccf-431b-8212-42cef22f8fbb	驰邦药业	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
57295a68-a820-4fe0-9798-e6d7a968ba0b	泽鑫笼具	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
d03334f1-7a38-4e96-ac5b-373373c84f61	娜娜尔	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
eec03344-6fde-413d-bd86-155a6b1077a7	伟成工艺品	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
64a2d723-31ae-46c1-8c2e-5c934e265718	圣达	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
4ccfbd9b-e954-489f-a6f3-e0173cc9ffc0	准安一稳	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
f798bbb3-2f4a-47d0-adae-aae0c192691d	宠客防	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
b84bea07-7758-45fd-9ff0-f5144457f510	宏安塑胶	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
2aec0a1b-5e70-4e0d-a212-606097e89873	轩泽塑料	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
40175778-b74d-4bc7-ab07-e0e880d049b2	艺富	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
b417a68d-ba41-4d22-b8a5-de8558fef52a	中澳	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
c2295e13-c797-4c36-9dca-431befb93f26	净佩丽	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
5a1f1e8d-675e-42be-89d6-097cd4129c42	益群游乐	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
cda6d969-a3a0-4ffe-9e0a-224ac320ce1f	恩悠	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
97589732-ef48-4f99-a5d4-c087554236a9	盛龙阁	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
994cc708-4187-4065-bb86-2d0cd2df0f5d	姜灏先生	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
b9821a66-d107-4595-b21a-f7f74eb86bad	尾巴树	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
31cbb8e4-f689-43e0-9ea0-a63c941cb8ba	珂莉	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
90829aa7-924a-4f7b-847c-6dfab7d59ebc	迪普	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
ea2f21ce-f67b-47af-adde-7baf12354b5f	尤利威	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
3bd3d24e-22d3-4904-8fa1-24874160a3d9	宠乐园	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
da2e6637-9305-4cfa-8613-fb310bf53656	金润	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
14552aa4-26fa-4171-bc79-c56111bcb718	喇叭坊	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
1d08de98-52fa-48ea-bdd1-263c7d3c2b3d	慕君	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
a88836fb-c68a-4684-b9e8-5b6fa66d489b	自由能	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
8fa3ae19-8b4a-472f-beda-67c9bb4fa658	名峰家具	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
410b0a55-202d-41bf-9f5b-813df029b425	康原硅胶制品	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
aabbd090-a7ba-4f51-946d-72416b78aace	雪森宠物浴池	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
b2592702-660a-486c-b811-c7d7764e2e1f	守护犬具	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
fdfc0a6c-7486-43c8-8960-c736f55b6fc0	五蕴	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
6472bc6a-fa5b-4157-8ca5-743385d3faaa	禾贸	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
fd5dbb56-4095-41d7-aa86-4ae60e6c729e	龙达	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
91486bf3-6b44-4b98-a03f-6b986ac018cd	善德来	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
4613730b-08e7-482f-beca-590349936cb0	ASTERMON 阿斯卡	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
748bbfa1-e8fd-4299-b8a9-8b03191e85a9	木羽 Muyu	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
a0f79360-3f9f-4520-a3e4-f265da46d895	安瑞	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
ee4c872e-94aa-4b63-9b62-0c7437f41d88	KOTABATHS	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
1586b91c-bca4-45e0-b219-be2c72f8c023	哇噢	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
e39f0ad0-484e-420d-ab00-16017c86ef21	张五五金	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
360f122e-686e-4d6c-b0fd-95f247d892f2	瀚城纸业	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
85f81dcb-999f-4056-bcae-647c84769b62	铂宠之选 PLATINUM choice	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
6e8df2d1-45f1-4026-9a6c-65dc0e60c7e3	乘视	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
e42e3402-2559-4439-b004-b07f89f5cb39	施大师	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
0b71c2a8-c024-4c27-ae33-b39245db09e3	三千宠	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
e21aac97-b991-4afd-a84a-6e760f2cfa34	丽莉萌宠	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
6751179d-e924-4dd1-be0c-70a5458f4c71	橡树宠物 OkePet	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
bd555c99-8720-40d5-8969-b24f8f0409f4	志森宠物	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
c475e21b-455f-4bad-9712-3bfa2f791021	DOCO	\N	\N	\N	\N	中国	\N	2026-08-07 20:14:03.04259
1d60fb2e-d9fa-459b-9d33-907ead448258	BEBEROAD	\N	\N	\N	\N	中国	\N	2026-08-07 20:14:03.04259
95c212ce-084e-4754-ae57-03fe507bc532	COZEHI	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
50bcf75c-a886-4c75-b4d3-af24d821617a	益尔康	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
9c1862e3-91a1-4e68-bffc-6b2596878225	DCD	\N	\N	\N	\N	中国	\N	2026-08-07 20:14:03.04259
9806c912-0359-4b00-8fd0-ac6b2bb12983	宠物	\N	\N	\N	\N	中国	\N	2026-08-07 20:14:03.04259
605c4ba6-4a54-487f-941d-b5ec4c002866	爪哈	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
3bafdc99-0f4e-4e46-a516-52ffa2fb2354	欧瑞斯特 ORSUT	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
807ffe87-1509-4ea2-9f63-e305a92e8d42	科品诺	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
a7ca8e67-4aa3-448c-857c-0f13d4a66699	宠憨宠物用品	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
320aaea0-e512-46b9-a897-d8b8a9e96b17	烁坭陶瓷	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
438e2bb5-25b2-42f0-955d-a06afc8cc046	汪喵方程式	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
99914bd7-9e9f-448b-acdd-6295e276f87f	MGUPALS 已天膳	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
627cb09f-444d-4bdd-b7ce-7e358dbee67d	旌权	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
50629c6c-5765-471f-a1c0-168f3a214c1d	深圳咬吞甜	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
26131e83-8705-4e76-b3bb-f861ca33640f	田园猫咪	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
a6a36d0a-4e44-4c12-bd66-0a732d833420	智迪宠物	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
930932fe-4956-4cee-93c6-c177b03b4298	喵达达	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
8d30349d-8f67-4eac-8917-811d0f8c488e	曼泰宠物	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
0087d1df-7b2e-4299-a8fc-b12166ac7eea	瑞恰	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
b122dd68-37de-4e42-b8be-2b624419ad43	贝乐塑业	\N	\N	\N	\N	中国	\N	2026-08-09 10:19:19.933914
a41f3632-a4d5-4456-a933-29e1baa46dcc	卓为	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:23.098922
3d4fb59c-cfbe-41df-9849-2837e2dede49	海荣 超润	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:23.098922
c25e0d64-001b-48ed-9a79-bdd765564669	仕爵	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:23.098922
b417f792-bbd8-41d8-b6c6-6faeb7f451f2	五方ADP	\N	\N	\N	\N	中国	\N	2026-08-07 20:08:04.789414
5f07afe2-df34-4c65-ae04-ff708cc04601	洗衣	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:23.098922
f5bb49a6-1a03-48b1-bea0-e6fc25398ce5	三	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:23.098922
2c69a035-2784-4b0d-9be6-d3355a2299f5	牧朗	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:23.098922
87c61fc6-f8ce-4369-bee9-ccce0f9d63b5	乾山	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:23.098922
6754ae24-0fed-4514-9a09-ad3e39a277ad	艾	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:23.098922
ae7f18e6-475c-4041-b83d-84cf9b317a3f	泽	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:23.098922
ec3bb8b5-3534-428d-b4b2-4252bfa27254	国泰民安 GTMA	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:23.098922
3b53919a-c154-4379-911a-acd8ebc7dc3e	可亚鑫德 上海珮樾 KYXD & SHPY	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:23.098922
96cca925-8324-41b3-92a7-b9485a552e76	全泉	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:23.098922
495be76d-eca9-4aba-9d94-4445c9e37cf4	亚华 & 屿派	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:23.098922
4321cc27-9e6a-4a73-ab26-3771f2c941e5	辰陇	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:23.098922
be103e11-4a9d-4478-af28-1d6076882d72	猎雀	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:23.098922
f4403121-b31c-4065-8b13-146b66d3ac74	联单	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:23.098922
45049ce7-6534-4158-af2d-dd8443034994	派对生物 E6 Q01	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:23.098922
cd444f9e-f0bc-42e8-8861-1a1c0d1de52e	育贝	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
72bd7ce8-8888-43bc-b2d3-602fbdde3c51	胖小乖	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
44d95c8f-b109-471f-89c0-043d85ed386b	巴尔曼	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
f050d09d-960b-46bd-8f5f-9a5ca675955d	冠	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
ec28f080-a837-4bdb-bdc6-aab77fab3743	天趣	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
7d3d7b92-9cbc-486c-8333-e20dc25b881a	卡曼秀	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
a6bc333e-8e84-43c6-acb6-805419c81133	空压得	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
8da6de38-132c-40de-aec1-27df99507ce5	C3帕缇朵	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
289f26d0-740d-4f81-b7a3-e1d9ddb65df8	纯能	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
70e45acb-3af8-4c0d-af21-7c7132999446	大玛仕	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
1b808f34-6270-4756-bb68-179ec7455c62	荣宠	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
b7d309f8-0c64-47fb-b6d0-2c7890631178	贤纯	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
9f0a676e-b4c5-49b8-bdd4-39e9f425b627	卡麦思	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
a780becb-bccf-4649-9b33-a768b07327e5	贝尔曼奇	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
60d8b168-0f27-453c-a661-0232c4ff6268	优品	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
2997bc60-f521-41c1-a0c5-a66fe5f1c86a	龙乐绽	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
937db4aa-600c-4e10-8c6d-4db5e39a9815	喵奇林	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
ee145f6a-45b3-4481-ae93-4fbc982d174b	探鲜叔叔	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
ff730f37-4cf5-441f-98f3-3cc1f76fe0a3	猫跃 MaoQuan	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
3c5291ca-739a-4f14-b14f-df6b403029c0	Lounge	\N	\N	\N	\N	中国	\N	2026-08-07 20:08:04.789414
a9b0738a-1403-4e09-8b1e-23d696fdcdc4	A.P.D.C. & mind up	\N	\N	\N	\N	中国	\N	2026-08-07 20:08:04.789414
370fc4d1-4c79-4086-9d89-e738d7afe9a2	霍丁 雷尔夫 尼可多多	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
5ea6ce7e-faa9-4f0f-988c-cc48695b5cde	(text too small)	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
66735d20-441b-4e8a-8d21-15618b61dc8b	尾浪	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
34252a85-d8ef-4f22-949a-37c8c02c8581	原野天纯	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
ef76a085-6676-4c45-8d0b-6f2dea21dc1f	蒜溪	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
944541c4-e5fb-4977-b3b8-be5da63b5b60	中食美科	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
d3089cbb-b85f-4c53-b0cc-f85766ce1c62	小鲜引	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
e66256ba-c829-4a55-bfe8-0709e214a6ca	它它物语	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
142cc32f-0196-490e-a653-5d6a7fe0730f	艾派鸿	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
1ab2c1b5-335b-4f7a-afe4-af755b405a96	贝	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
dee2aad6-96ca-412a-8d28-ccb1827f227d	肺部	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
bd56f3c7-236c-41a3-b127-88556dde48db	美登高	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
c868eef4-5184-4c80-bb10-668675722126	仙森元	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
9195dfd9-35ed-4951-9c87-fa0c73addad5	馨	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
b7cca756-d574-49d8-82bb-17b8222923dd	可汗牧场	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
6bc333d4-ea65-46bf-be10-0896c019232e	大场开发区	\N	\N	\N	\N	中国	\N	2026-08-09 10:20:43.01848
6c09f2da-73d8-4bc3-9ec8-38fb902b8130	TMALL 天猫家清	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
ed798365-7039-43e2-afe8-bffa6d398b17	小红书 宠物 - 土猫土狗 大赏	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
afb4a16f-68d3-43a1-93e2-39ae84ee213a	LanKiaZz	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
0cdb49e1-68e8-4370-b57e-a5e89f3dc1de	Kala&Boo!	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
ed3889b4-342a-47bb-a93f-8f84209de3db	Petite Cute	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
1615f57e-bd7c-469d-a2a6-1aedd627f338	Fluffy Unity	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
a5255062-c7dc-4145-8655-10bba0d8537f	顾月手作	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
faf9425b-c74a-4a18-851b-64935fc23a0c	宅日参乐	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
53cdb4f4-1270-4250-a38b-e506296b1dca	嗦吉	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
aa3d6635-f58c-41bf-918b-909fcc278638	RUI RUI POMBOO	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
66fac91f-1033-4dde-98b4-c1a3a0f52404	召开小喵	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
632aa89c-0fe5-463e-8b03-ed2d97885fdb	KIDS GOGOGO	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
ae6a40d7-9881-4329-8fa6-b71f98efd163	LITTLE SAGE	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
bc48b204-9b12-4870-a262-eb7d5d6d45c6	Mini Pawe Hone	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
65b5227f-eb50-4030-b4f8-5a802f4eb2ba	monom Petokay	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
37c069b0-02b7-40e0-9a5d-34862f874580	KNOT COOKO	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
89cca420-8210-4cca-a6f6-1fa4990931db	RUPET	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
e1413baa-937c-4cb4-8960-d66e25fa23c0	我家之堡	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
4784b83d-3bd0-4e23-b24d-cd6720083cd7	Daada WANLOVE	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
18e714dd-ff2f-4c78-93f7-44646e9414e3	LuffaLove	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
eed0fa16-6ac4-4b15-9324-541d3fcbb21e	比瑞吉 Nature Bridge	\N	\N	\N	\N	中国	\N	2026-08-07 20:11:48.883982
e81d9b69-e633-4235-9f2d-a91b43a11520	VTLWG	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
3436ed8a-0208-479e-b3b6-ab6a3ba577a4	ZZE by zenzura	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
b193ca0a-11ce-45aa-b396-d6ae3e40dc27	BULUBU	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
5bdeb748-1022-41a3-ab88-231f41f7cc50	E8D28 E8D29	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
6d8f7085-119d-44e3-aa78-4d1b4263d2fa	US cococle	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
15c8f42e-05ef-4243-ae7f-70e0d0ca144a	一狗一猫 pet	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
8f1efbdc-cd8d-4f3b-86ed-7be49496da14	大副 D&U	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
1a3311aa-e4b5-494b-a664-81abcdab4dab	BLUE 柔刚糖型	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
b7488425-0691-41f7-bbce-74a3aba99a64	DOM	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
0de8224c-dd6e-4018-b02a-9b8ce823593c	Peperock	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
285c4eb7-de43-497b-b498-e8fa1f55f724	Moone Pets	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
f1710b1b-dbc6-4f59-a4a7-5c5ce577b7f0	Tafy	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
b9ed8d74-6fda-460f-b34c-1000173ba48d	LEEWUSA	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
90b8a864-7fe6-4276-8973-c4dfe62342a4	护卫神	\N	\N	\N	\N	中国	\N	2026-08-07 20:11:48.883982
76c2cd4f-9894-4a96-a666-c4ad22954ecb	NaTang Pet	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
8b159948-28bc-40bb-9b51-0a38419fe4d2	姨脚兽	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
bdc1b86c-7ae8-4776-b42e-44e9cfe46017	Fisher 逸派	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
b65a672b-868c-4ee8-b1bc-f412a66bdc01	Omo Ono	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
afff318b-572c-4ce7-bcc2-e5f319766993	HAHALO PAJAMA	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
88ccc4c4-0022-4a17-ac66-491b3e4c5b4c	李李荷 Lilie	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
8ab9dcaa-2fae-4418-8857-28023d7b3b26	DOGPAWS	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
42c65a84-17ed-481d-a10f-76a3c250bcf9	WOO'O	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
2de1729e-ce88-40a0-a9e1-86e24bcd8fad	Pawlov	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
caa63fae-80a7-444c-8ac1-055014aa64f2	PIUPAW	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
c299174a-baab-4060-8908-efaff4cf626c	CANIRUN	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
daff78f0-0170-4e07-b96a-1cba334c4419	DDI	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
d488d54a-db41-4330-bbad-5c9d246b9e2f	堆筑 MIAOZHU	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
cf583ebe-4739-4110-9d07-e0448a0301c8	切黑 CHEWTOYS CO.	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
d0160130-ab17-4e34-99c0-5a3302a8cbec	Little Weaver 织娱	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
ab7560fd-4a19-4564-866e-b440b40b1d25	MOCHIPOP 毛气泡	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
dfaf20e4-cec0-484a-a83d-48f3b0be656d	DOMIESLAND 领趣乐园	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
7b0deb8d-c14e-4582-ac69-d2259b346972	N.W.Campus 爱物学院	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
d25f3556-cdde-47b1-ac0b-1c00cbb39ace	NUMIZUMI	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
19ea1331-0714-49f9-8ac0-b6f468f8b1c6	MyPuppyMe	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
743fd112-bc65-4d98-ae5f-581079501e8a	Three Kilometers	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
9ac3c0a8-3ed6-472f-920a-cc3374d226cb	JumbleBagel	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
660d8d80-bfb5-4096-853c-40b8974f0f15	SNAP / AL 休闲尾巴	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
572df218-2df5-4456-83fa-59e49c4643a5	OPOFO BPF	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
d22613e6-1d64-40c5-b1cf-1a8618500e05	MEYSALI	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
9827c13f-7bf7-44cc-a8e8-324e71071f10	Purru	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
9c1011df-0448-4218-8d6c-e916a2ac66a0	MCHOKK	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
0049634c-8dba-423b-bfd4-62ca84ce5edf	Litpa	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
1b8b273e-4c9c-437a-be95-b094e5264f80	Shelly	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
bbe7487e-0fe8-4319-bccf-20b34a702e4f	Hiturr	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
7e0898f4-652f-4e36-84a7-fd0f19c98c19	Wiggly Woo	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
d32ae421-c25f-4af4-915a-7fff55d23463	OK PET, BirdonWag	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
4a188fc4-2484-45c2-b2df-771c68fd9f13	纯仕	\N	\N	\N	\N	中国	\N	2026-08-07 20:11:48.883982
5a68531a-6c07-4446-b3ef-a49938bc93de	JOLIPET	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
cfa540fc-45d4-437c-a687-c013b22a9c93	萌选品 拓展品牌	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
20a63b24-1df7-4fcc-aa19-32241ee6c8d8	Paworful	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
d185123d-162f-40b5-af63-06bff5b2bc92	mararound	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
a927e85c-44b9-408c-8403-1b46e62a764d	三只松 somegae	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
6dafd7de-b08b-46c9-a01e-a973e048c80e	HOH	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
48ddc34e-de34-4bec-b528-75890e432087	Ricel	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
aa7c095a-652f-4fbc-9ff9-021ab483e143	EXO	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
9d79354d-ee1a-4307-919b-f86b7fb0fb03	EXG	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
bf3897c8-5c6c-4c21-b0d1-d4401397a9d1	EXC	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
96978a51-38a7-408c-b4ac-1abf10f29f2f	EXZ	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
0811a001-7918-44ea-a584-51cbe6bd26e3	EXB	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
319e1bd3-c7e8-467f-814c-1e19adcae3e3	EXM	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:11.755418
1dcad4b9-633a-486f-886f-c4eddd49cee5	萌力量 Truelovepet	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:37.980352
3896b0c6-c9c1-4842-be6a-647a999cffc4	爱利福	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:37.980352
b57ade43-5eb7-41bf-bc28-6f6ce94745cb	奥兹 Aoji 诺德 Nuode	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:37.980352
184247dc-9e49-494d-85c2-7a01fe6e0881	美斯蓓 MEISIBEI	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:37.980352
7d5e2f3e-6df6-432e-a9c2-7ae6dae9588d	华野	\N	\N	\N	\N	中国	\N	2026-08-07 20:14:03.04259
22ec6b92-de06-4f6c-8d69-b0be1c2a8531	嗨小皮	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:37.980352
bed0613d-16a5-48f3-a497-4bceb5d8d02b	钱	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:37.980352
df0c30ba-8de6-451e-ae78-7d6a87d55fd1	涯奇	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:37.980352
65143a59-fa85-4a62-9c4c-3d7baf6b36f5	宠熹	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:37.980352
6a8d6932-4448-4b33-92d4-fd28b97ce4ae	霖犇	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:37.980352
48b0cfc2-6136-45c1-8292-fe021204c6fa	自	\N	\N	\N	\N	中国	\N	2026-08-09 10:21:37.980352
0d4310b1-47e1-46c6-9784-e762c047ba56	嘉蓝	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
835a0077-6151-4a74-992e-82255f8df65b	晋宠 Jin Chong	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
951b3e95-6219-4d9c-ab5a-0841c06753d5	中国宠物	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
a8cd5e11-b02e-4fe2-81f7-691d1cd35641	萌趣	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
53811c89-fd48-45fb-9183-050b7485179a	安瑞佳	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
e215b48a-fa9f-438b-a3e2-cfc1face079a	NiYa妮吖 | 甜心爱厨 | 甄鲜传	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
65a550e9-154c-4af1-b5a6-0778ba96903d	莱可L·C Pals	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
12864013-c2d8-4597-86cf-3944441ced83	宠盾 CHONGDUN	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
8c89c230-031f-48af-9792-bc9dcf0843e7	KANABLU	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
4df76e96-faa3-433c-82dc-29ee6f35a54f	Jin Chong Pet Food	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
2fbbd37d-da4d-4aff-b65d-2132734524f7	JoinPets	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
a8e462ec-bc73-4c3d-81cd-18e1dab26f2c	全硕	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
c28a6744-76e6-4ce3-895a-df4c01366959	澜泊湾	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
23630729-2f71-4280-8693-2d7737c3ed6a	亚禾	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
ca53d7ff-1960-4c14-a05f-3081a39086d6	时令四季	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
53d3c6e8-521d-497e-8d4f-1c8ce5337c33	陌丽花	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
5f551d55-6f4a-41d1-81b3-ca80302537a9	宝宠	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
ba8ca455-2382-4ff2-b42d-1615243ae08e	康康	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
08ca7a55-1b15-4bd4-9c9a-d00fc763d0d5	嘟懵	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
8e559beb-2997-45de-b81b-0a765e1dff52	Alove Miceauty	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
ea02b188-19ca-4531-a96f-a023b025f6ce	有鱼 Fish-1n	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
2aa81942-2796-45df-bae8-54076a94dcdb	觅新鲜 臻粹	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
14aa1359-e104-4015-a5b7-9a28299120db	Bona Joy	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
5615aed7-7b80-4adb-9495-98d2766e5eaa	京宠	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
3b6756d1-589d-4021-9352-13acaefd6e33	猫打球	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
062a4ccf-3840-4976-b5a2-51e8796c2b67	保仕特	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
f6e387dc-41d1-4802-a38a-96c7a0bebaf0	犬它	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
dde16061-68d7-4c8d-a88a-782dba0fff8c	海岛喵	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
95d89861-fc52-4919-a164-5d7e8a9dabae	极蓝	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
d1c9314f-1bfc-4b44-80a7-cb33cf8cc64d	江西日报东西部	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
2f653fe3-c738-4917-9ae1-e140b34525fe	味上	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
19c47ca6-87fa-4a55-aed9-7c7f6774f005	UOK	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
12cbfd93-8395-4eff-b6ee-4a0f4e2d6906	Pet CakeDay	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
1b78ded0-235e-4401-929c-08b7b94474f4	海纳	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
c6b4e46b-9996-4136-8bb1-97f99869e235	绝派	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
430444b7-5af5-44d5-8588-b60757d7b0dc	伊鲁漠思	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:02.726286
90044d68-bfd6-430d-a2ea-053486892dad	倍普森 bpeseen	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
3cd66bb7-20e7-4a0f-b86e-ad71bad6d9db	瑞	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
f8a363a9-f83b-43c9-af36-037dd7432d21	欧吉	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
585f0a54-6584-4090-8c70-6f5b0774a795	夕愫豆子	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
acfc6621-e400-4e8d-ad8a-c99b456d716e	兰舜生物	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
81bb232e-7148-43fb-bde1-540ca3faa615	功能	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
cd88fa9c-b10b-4a50-a481-8b7313c25367	研伴	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
79f504f5-f2bf-4669-8686-77dcf7d0b28d	精博	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
0b364bb9-b3c5-4343-a405-e73368b69b08	拜方	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
a5bce0f2-247e-4e16-bed4-6cef6654713a	科普普	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
364e49af-d570-44dc-9187-524ce365f49f	龙衡	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
be4d4712-7822-43b6-9097-5cec64a550f1	中博绿亚	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
f5454dac-d1c1-49ff-8d5c-bbba992e6a64	牧园小新	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
33425037-ec27-43b3-940b-3a3804c97b8b	正昇生物	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
fbc16e23-97fe-449e-a9cb-b90b024ccc09	福建原森	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
18f87766-b2da-4aa8-845a-d63ef26674a0	瑞辰宠物医院集团	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
30ff2a07-f9ca-4478-aa9f-417821871e9f	华生维克 Hs·viko	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
abb13bea-2fef-4d26-9208-acc00d369f98	上海溶健农林	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
d0f78451-48da-434c-b313-1a1fdbd6c8d2	比拜尔 BIBAIER	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
5c731c4d-805b-41bf-ba0d-bb41d1f4b57d	康斯加	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
53e0fe20-e8b0-4bca-ad19-743313a85e7a	皇宠健康	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
57982d1c-9c05-4cad-8971-6f4a267b2722	新际生物	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
b6255a09-f5e6-4e42-95df-8288cc434d2a	吉宠 (添赐力 /博乐丹)	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
c06d4b0e-b102-47d5-ac66-4150f65cfe64	润康	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
c15e2a6c-98d3-4910-8f02-97b400e2b7e7	组卫 安格馨 Angahin	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
3f8a138d-0bb6-4817-a213-7d54dc9d5cdb	速楽可	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
b63c26d8-d666-4d23-97df-fc57cc88302d	土盛堂	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
0e5c22c3-8163-422e-a010-1bd0701835f8	纳川	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:29.600132
73ba6284-14cc-4273-a7a7-0718687c7455	京东健康 JD Health	\N	\N	\N	\N	中国	\N	2026-08-07 20:12:22.19577
0498b5b0-46bc-4ebb-8f6b-5fa4dc16f8b9	沃莫	\N	\N	\N	\N	中国	\N	2026-08-07 20:12:22.19577
0eea0dc4-ae3a-4b9b-9603-0ed889d588ff	Catlink	\N	\N	\N	\N	中国	\N	2026-08-07 20:12:45.709996
c86f7c5c-00aa-471f-971d-d16a2f9d0860	超伦 carewin	\N	\N	\N	\N	中国	\N	2026-08-07 20:12:45.709996
15e5f2ee-8549-4bf8-b8f1-7cac836e6cc2	北去 Petree	\N	\N	\N	\N	中国	\N	2026-08-07 20:12:45.709996
18709af1-1cbd-479f-8535-57e802c490fe	博联宠物	\N	\N	\N	\N	中国	\N	2026-08-07 20:17:23.529596
1c92440e-8744-4cff-8e35-a5c0a5af3268	尚成生物 ShangCheng	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
b1e211c5-9752-4dbe-a108-274b37a902d5	亚华	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
78e02769-82b5-415b-b759-df028b6a1d49	灵咘	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
f6c3726d-4494-4a3c-851f-ebc6ba8637ca	香佩特 Pawscen	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
8026fef5-9feb-4b5c-88c9-a929472030fb	依宠 康源	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
b06755c0-927c-4ecd-b5ce-9ba073403c67	英优 YOUNG	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
2aeeeffc-2f8f-43fe-affb-465022eb215e	波咕	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
d0699172-eb1d-4d8b-896b-d666d9b12965	杰泰	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
3ff3209a-f762-4fc1-a169-97f59bcb6ff7	念星客	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
77e62206-36d2-4a7a-a2ee-19b115d9e7e8	祈尘	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
fcc1e1a6-b943-4f1e-9600-171fddd56853	必康动物医疗 BK Healthcare	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
c1e8d3ac-5997-4549-af5c-8e14e6390f96	翰林航宇 Dr. Pharm	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
4adcaa57-49a7-40c5-874b-7da8ebdf4e28	医麟宠物	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
342d7712-335e-405e-b7ee-c24984e84bf2	觅投克生物	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
2b821c24-a7ca-490a-a516-e6ecdde816fd	屹禾	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
8b9d92bc-81fe-4207-bbbf-b1bac5cc4173	贝芯宠	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
3b297081-c15f-459f-9347-24b14d265d6c	合肥宠维元	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
0b203c32-d6e6-46db-892a-8c3b9c4f36ab	新三益	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
783554c2-29dd-400b-87de-796ad9f63f92	润道眼科	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
90310189-eb11-4b37-860c-c115ce1eedb1	康必持	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
2a012ee5-f0b3-4610-9ba8-a90c102528b0	Ingredia	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
2af82bda-b59b-4a09-b697-f3ef8fb60b56	上海普佳	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
4fd424eb-9d04-4d2a-afb8-09f0a2945a79	新格诺康	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
33701317-d2b7-4087-818f-f690089b2eb3	海伯基因	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
918e5a22-517a-41a4-a139-4fc3396cd754	波波酷	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
3af3d58d-a935-4c54-ac1c-2c641d0b4f5f	奥普康	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
47091975-f3ed-47b5-b0a5-f1dad88c73d6	睿速	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
d8a1719a-decf-497a-9def-ec5ce2f1e7b5	Lingboo	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
475b4d13-12ab-4279-b44e-65164a353477	新宠之康	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
a082281d-324a-4702-ada3-9d2285e7dbd9	派恩	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
9deb8af2-4643-482e-8708-75c71921ff84	瑞特	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
e3e7314f-6992-4377-895c-f7de86ee1e4e	玩美	\N	\N	\N	\N	中国	\N	2026-08-07 20:14:03.04259
b979f5f3-d3e3-442a-a0d8-740d0739e609	欣时代	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
a10a2655-861d-42fe-ad47-5825659dfe7f	远征	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
a8403540-cd8d-4ad3-863d-a543bea57d79	宠威	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
5b986b8a-d363-4201-b84b-acf1018f5603	JASMOVA	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
a6379b3d-b073-4fa8-aebc-de6bb7072bec	尼古拉	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
74cee373-db72-45f8-8c05-02ed59b39e69	新科华大	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
cf5af9a6-89f7-45c3-8e5e-1fcde46f6f26	丸博生物	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
54b6a45f-b6ff-42b4-97f5-52dcff499a79	灵泽	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
687e131f-92f0-4665-81c9-2adac3285979	悠乐维	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
da5c5960-6ea2-4de3-86af-3a05d62694f8	Repolar	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
a1e60d5e-9e34-4c24-a854-3bbb23f038c2	桐惠	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
98666999-910d-4b18-993f-efa5b5c67bc3	农泰克	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
cf19ae3c-43bd-41a6-bfb6-c6fdcb9ebc18	萌邦AI	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
1f66d5e4-7b35-4dcc-8d88-3c6b2970c71f	畅启	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
7b28deef-4b9d-4d9d-913e-ad7d677b4bc1	哈总高科	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
293335be-aba3-4ce9-8464-5520e07a54c2	法米娜 FARMINA 维倍思 VET'S BEST 欧世宝 OXBOO 牧野奇迹 FURRY WONDER 舒普瑞	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
18df9965-3a62-41ba-9429-33e03c4b0a69	pronature 枫趣 pink 粉钻 Greedy family 贪吃家族	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
d3ecb70d-9b64-4d2b-8d38-fdeed331091f	AminAvast 胺肾 MOATPET 慕特派帝 MDPY-1	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
f036c4f2-f0c1-4ad9-b44b-4c87164ea73f	或熙 Derbe	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
be345005-99e9-40b1-add8-ac38dace808d	Oxyfresh 奥可亲 Detenele 等它 Nature's Miracle 天然奇迹	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
ae943af9-f152-4adc-8802-4759c26520d9	Nasta Group Forza10 Natural Code Bab'in First Mate	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
c6fe3b60-cf82-48f1-a646-2aefc9245999	Wolfsblute Fellicita Wildcat WildesLand Herrmann	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
d9683931-9360-4cd9-8ae9-b666691bcdc9	SELECT BALANCE 倍适选	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
87277342-4978-4731-96df-d035b94d1e9c	TAKI 舍然大喜	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
9ce81ca3-4dcc-4d27-bcd9-a46b8ee12ff5	Magazoo	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
7aa47d5d-5ea2-4841-a001-0612d57505f8	希瑟雷诺 Sceilingo	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
bdf27f9e-0493-48a5-a828-609db606ee55	梅亚 奶奶	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
516640bd-a91a-4d84-be7e-a6537c0fb245	法国茵尼 瑞典	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
1281569a-8f6f-489a-ab30-e95f97a3d403	ine	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
b4669fad-a32e-441a-8dfb-e955db926b89	s	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
f9ffe7ba-fc3f-409f-80a6-42276ada4bca	爱	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
dbd2e731-9f55-431d-a3ad-4a99787fea91	lerHloh泽爱	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
1a2dac69-af30-4d7e-9dfc-139f5a6f7e5d	life+ 综艺, 虎扬	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
49f66423-0864-4410-a086-c63bf16e9810	"综艺, 虎扬"	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
d029b767-d7bd-4e52-bd02-12ef6123cc7c	一度 传媒	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
19aebc08-fbff-461b-bf18-33d0f58ebfb2	OcluVet 欧可明	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
07b7146d-7a26-475f-9e6e-d653e5763a59	郝波宠业频道	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
1001f685-f01f-4dc7-a680-8c961049ac73	乐嘟	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
42f7908d-ee59-4eef-9ead-c8fc17c35c6b	Epanal	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
831986bd-b514-46d9-8405-6c05bb18a80c	Chow	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
d3b48023-1273-4a9d-8072-04f7377c5765	Saudi Pet & Vet Expo	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
cea1d1ea-9db3-4aca-baba-071856244b80	创然	\N	\N	\N	\N	中国	\N	2026-08-07 20:17:23.529596
dccd0ac8-0254-4d36-a3fe-719f901c9f23	Petzoo Eurasia	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
8d8deb22-3e42-4158-b87a-49a875622459	Herbal Pet Food	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
36f455bc-519a-4bb9-a9e4-c974779d6b10	ZUPREEM	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
66587888-cd45-45ce-8b19-c3010c7733f1	SmartBalance (NZ)	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
1b74e9f4-bba7-430a-b031-d39fa9c7bb0a	ownat sanicat	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
18434f98-09b9-4f58-a42b-6df76c785acb	WILLDAIFLEX	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
dc083853-87c2-408f-b0b7-8f416c981545	O'dless	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
04f92d3e-5cea-4b68-8153-e3d16fa266fd	TailTempt	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
e9e1a868-c14b-46e4-8834-711172a3d6ba	Reddy 瑞荻	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
79c56861-a053-4347-8e60-92bb512be812	加毅 famiclear	\N	\N	\N	\N	中国	\N	2026-08-09 10:22:53.88402
7eae8479-afec-4833-91a4-ae00bac9475b	NZ Riverland	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
a27c69ba-09c6-4e3e-a92d-4403c4f73a97	Twinkling Star 萃星爆毛粉	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
b5e167e1-9969-48e0-8c3d-07953ec22ceb	JEIUKANG	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
131a03dc-9f49-4a8c-aa4d-f663e8248050	The Wagging Blue	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
b069fb93-dfbe-4366-8ec3-98aec99ac789	WOORIGA FARM	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
b382878c-1a93-42b9-bf9b-fd3f9825960a	合台Hitide	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
71a1f74d-07da-4e0d-8a6d-32645e39c0db	欢欢	\N	\N	\N	\N	中国	\N	2026-08-07 20:19:35.520943
c24a168f-df72-41b7-95d8-2327e2d1322c	K9	\N	\N	\N	\N	中国	\N	2026-08-07 20:19:35.520943
0fe3dc9d-8a6f-4bcb-b262-404536e68d75	味当家	\N	\N	\N	\N	中国	\N	2026-08-07 20:19:35.520943
cd10791e-74cf-4460-bd80-096cf70bd1d4	长胜饲养员	\N	\N	\N	\N	中国	\N	2026-08-07 20:19:35.520943
c0c9e738-8d91-483d-9620-deaa3c4d5493	GNT PHARMA	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
f9b94040-f336-45d6-8c31-e46512fb253a	little bitty	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
64b647ab-268d-4e76-b5f3-b58175b23dff	WILDWASH ZOOLOGY WAG&BRIGHT ALWAYS YOUR FRIEND	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
2e41cbba-a44b-499c-8515-6906fd46a6f8	猫倍思 Cat's Best	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
0fc0886b-c80c-42b1-938a-e65767ab3eb8	PETCHEN 展示	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
f7c5b89f-cd54-4232-8a46-4d8238146d99	Petech鲜刻猫砂 Wildbrain沃贝	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
4cba812e-2749-4f44-84d0-f1f9a3c0115b	PowAir 派逸森	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
be1508a6-bac9-4438-abd9-c3a70c2e7c0d	Natural Balance	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
f543c0bf-6cdc-4c9f-b041-2aae09e9df8a	YourVet	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
5cbe6817-49a7-48b3-8e90-8740e31f0d20	GOODAY	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
e814a64c-841e-4ddc-ad23-4d4277252719	KOREA DAYLION	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
3fc9f5b5-b21f-4e4e-8c90-a1c918d4b756	SK	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
7ca3e5ff-7be4-432d-8898-b82edf0980e6	东南亚宠物用品展	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
0e0da8b6-facb-4a8a-ab4b-dc635b612937	VICINO	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
73ee8091-7e41-4598-a391-e154da3c1352	Melaniene wman	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
9278ab7b-d157-4e07-9952-2f849f77ffd7	Gourmete	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
8bb01e32-a2cb-48b6-8076-ea8fc31ea33a	Goodmate	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
8a8d3b71-309c-4eb0-8709-13c65998ef02	NZTE	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
980b8b6a-a793-47f8-ad0e-84d8ea0cc9b9	Zeal	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
22c71f64-bd6e-4f8c-b3eb-4680e9425e58	Unipharm	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
65492e1b-89c9-4100-b13e-b1f2048fa19e	Kiwi Country	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
54d12f28-116c-4818-868b-9ba2b660b535	Oko Pet	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
f4210ba9-886f-4f08-9579-2fba0dc8ff36	New Origin NZ LTD	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
9c47b955-19ae-47cd-9aa6-7544b17c1af7	Azure	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
e5a4c29a-99f5-4302-ab6d-664e95723108	Cranimals	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
38de4453-c32a-4830-b86b-7539a1b8040f	Black Sheep Organics黑羊	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
f8029f9b-f5c9-4936-83a6-ae2942f9cc8b	now fresh	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
be583185-96f9-4901-b1e0-e3a850bdd6da	KOTRA/IAKPP	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
d7b39ed1-daf3-4710-8d87-3e633af2b150	DIGIRAY	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
4df03109-a603-459b-81fc-67c7e7727016	MEDISOLVE	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
3ee47ffd-1feb-4bbf-884e-68b74574301c	VISIONMED	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
a3c7a7cc-7aeb-42ca-9350-10e8e12d608c	IM SUSU BIODOT	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
812bf447-d6d8-4407-b5ea-ffaa58556069	JWORLD INDUSTRY	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
fd793b7d-0c70-49d2-92e8-885ce12dafb2	上海源鲜 ORIFRESH	\N	\N	\N	\N	中国	\N	2026-08-07 20:19:35.520943
791dbfa2-786b-4c49-9979-c6bf83b1ba55	EVERYONCE	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
cfdb71d2-579c-4ecc-ac49-f189f3b20b9b	OMIONE	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
504e4c3e-3050-4c00-b6c8-1e938df66ae5	LE SEUI	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
4eaf5c5e-b137-4a60-a366-e28e3d61eb99	SUNNY SIDE UP	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
674fc08d-8e54-41c8-a950-bb9ce9860b3f	BEAUTIFUL SMILE	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
35b23171-2b42-49da-b714-6910108b3bf1	天猫	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
ed102e6f-ced8-40c9-8dcc-abb7142bc212	心灵鸡汤	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
5db7ecb8-ed74-4b84-9a0f-827c0d1f947c	悦伊	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
2d51af30-09b5-4429-9950-ecfa19c493c5	Petizen	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
ff6e77d6-09a6-45fc-9e69-2c4b33c6a578	Royal-Pets	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
a2a4998d-c7d0-414a-b467-e8de105eb9db	NG 恩萃	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
92ba2a6c-80c0-47dc-99d0-b4fdb3d7a001	活动区	\N	\N	\N	\N	中国	\N	2026-08-07 20:19:35.520943
3434322a-5600-4c42-a724-e8bcf598e526	US Grains & Council	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
36f79567-e98e-4659-9848-4b0e4fd62bcf	PureLuxe Pet Food	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
511e55c4-2ba5-4c0e-83c1-38d0be7a1013	Evans Natural Provisions	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
e18e7718-5948-41f8-ae06-866e0ea67bf6	US Agricultural Trade Office	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
c23ef0f0-74be-4576-97c8-b68ee36a7db7	Timberwoof Naturals	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
cd03cf24-9ddd-4b1f-adef-1279c896fe2b	BrightPet Nutrition Group	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
1602afb5-aff6-44dd-9c94-a3ae65e4f79a	Honeywell	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
7216a569-aa94-475a-a1d7-c2adbb34c259	Stella & Chewy's 星益生趣 Anamaet 爱娜玛特	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
090fb48f-6a65-4520-8767-6375921aef60	ORIJEN 原始猎食渴望 ACANA 爱肯拿	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
a77c40fe-9fe5-4fec-b2b8-530b56425407	欧恩焙 Oven-Baked 比利玛格 Billy+Margot	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
30b28bdd-f4c3-43c9-af94-a1fbee7005a3	日本展团 JETRO	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
ccfa83eb-edd3-4fd5-a5d0-8b6351d64cbc	ZEAL 真致	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
d62fb83c-e54c-4994-9ad0-85db352d7435	爱德胜 Addiction	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
0a87995c-dd96-4ddb-bfd3-fe1ca35258c8	MjAMjAM Venandi	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
9f317c09-1e24-40b6-9f6e-bd3b602dc270	animonda 爱诺德	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
50b3c612-0f3b-46d3-a01d-658252d470f3	自然魔法 Nature Magi	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
8ebf43fd-3546-4bcc-8002-f938cbc3a466	迈阿咪 Miamor & 卡帝维特 Kattovit	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
2eed4199-a60d-4878-9a6a-b7e5704baf91	VIF 偷偷	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
b0fddb5c-379e-4aea-b06e-0acffb39549b	Kelly&Co's	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
090c49e9-1b01-4b8d-9266-7e2fdac6b48e	高爷家 Gaoyea	\N	\N	\N	\N	中国	\N	2026-08-08 15:40:51.565772
67a35da4-a914-48a0-841a-1b854afa3a19	阿丽猫厨房	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
af42210f-f4bd-4f27-9712-1f03c725c724	美宠	\N	\N	\N	\N	中国	\N	2026-08-08 15:40:51.565772
f0f8ccbf-ba9a-4302-93cd-f5e19934d1c0	SmartHeart 慧心 Me-O 咪欧	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
a549e79b-e3f0-4421-977a-b42feeb8019a	Goodies	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
d105c292-060c-4823-bcdf-31c734db2ef4	small batch 时佰集	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
645ba1f2-9420-4573-8164-ec2f646b7926	joypet 加宜宠物	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
8c82ff44-3288-49a1-89e3-ca22fcc80cd2	Poland Pavilion 波兰	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
7c583f49-e562-4f0f-ae97-946f49ece108	Hmklabou 喜马	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
9a931f1e-046f-46b3-8331-9c6007276b63	STANLEY DHC	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
2f0558bb-4272-46b0-90f4-aa759bd42ab9	VIP LOUNGE	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
423af3e3-eb57-4325-ac53-9dd133ad1531	绿洲计划	\N	\N	\N	\N	中国	\N	2026-08-07 20:15:55.115106
739abfdb-8e32-482b-bd92-0ac6c1a10f52	Nature's Protection/Fromm 福摩/Fera Pets	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
b6137786-7d4a-4563-baf7-8fa59f47f3c3	DAVIS戴维斯 EVOLVE亿沃 MITO5051咪妥 OFFICINALIS	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
f4f5feee-677e-4f85-be28-6680353a6dcd	Meni-One	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
46b7ab28-d292-4b36-bc4c-799fdc9b8289	船记	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
ba4ae3de-9e2b-44e0-b015-f8805bd6e956	Pethana	\N	\N	\N	\N	中国	\N	2026-08-09 10:24:36.994151
24fbf71d-4e7d-4dc1-a505-f328113a4d64	鸿瑞	\N	\N	\N	\N	中国	\N	2026-08-09 10:25:15.537495
4233fd39-478b-45d3-b083-d932349801d8	希	\N	\N	\N	\N	中国	\N	2026-08-09 10:25:15.537495
31adbffa-7543-43eb-83d9-83d9c615dce7	晟泰	\N	\N	\N	\N	中国	\N	2026-08-09 10:25:15.537495
3a68c8eb-0f08-4b23-999d-bad038d85895	金奥	\N	\N	\N	\N	中国	\N	2026-08-09 10:25:15.537495
123ec946-5b4a-4144-876c-a96664817db2	华用联	\N	\N	\N	\N	中国	\N	2026-08-09 10:25:15.537495
c7032dcd-bbf8-4dbf-9ccb-c356bc66e7a2	Sanzyme	\N	\N	\N	\N	中国	\N	2026-08-09 10:25:15.537495
7a395b46-22ee-43ae-ab87-37f225f441ad	TÜV	\N	\N	\N	\N	中国	\N	2026-08-09 10:25:15.537495
10685e4a-ebc1-4d20-8673-ee2f45cbba97	润昕	\N	\N	\N	\N	中国	\N	2026-08-09 10:25:15.537495
61b7515a-08d9-45b8-a9b9-61b0dd71633d	幕	\N	\N	\N	\N	中国	\N	2026-08-09 10:25:15.537495
ca918916-8366-4eb7-a16f-02fb281c7a14	海	\N	\N	\N	\N	中国	\N	2026-08-09 10:25:15.537495
dc37102d-1062-4790-834d-87568d1cef58	万图明生物	\N	\N	\N	\N	中国	\N	2026-08-09 10:25:15.537495
8d0c2890-79b6-428d-89c9-7312663e6cfa	宁波贸基	\N	\N	\N	\N	中国	\N	2026-08-09 10:25:15.537495
d88fd2a1-fc68-4bb1-bc15-9f44170344ea	珐玛珈	\N	\N	\N	\N	中国	\N	2026-08-09 10:25:35.753124
f31d40f3-7dca-4b6e-8750-e5c4cbb19c5f	NOOKI	\N	\N	\N	\N	中国	\N	2026-08-07 20:20:04.249922
fc0ba66b-6490-4cca-972c-172339a6dc9c	钲昌机械	\N	\N	\N	\N	中国	\N	2026-08-09 10:25:48.364421
f32e47b6-83d0-4a7d-905c-13260c23784e	羊	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:00.815045
ab5386ef-54cd-4e1f-b48b-0446b4528ea8	聚佳	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:00.815045
b94894f9-e9cf-428e-be51-28a3d893785d	万顺	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:00.815045
dd1aa0f9-7047-4448-b311-6d6b2464dc7e	优	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:00.815045
7de539a1-0683-43e5-95ea-175a59ee1178	平瑞丰	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:00.815045
d1cb6d1b-5429-4936-b9f8-7cf752144b7c	Tagtail	\N	\N	\N	\N	中国	\N	2026-08-07 20:20:04.249922
0383f2f1-d076-457c-9d56-9eb9487ca5a0	明利	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:00.815045
64f55364-eb78-49b4-a1a8-5f0c27f90171	沪捷	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:00.815045
0e813e12-3e6d-4d78-88ed-6796bf436f4e	精锐	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:00.815045
23c89e46-3c48-4c56-ac49-00e944c72296	卫群	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:00.815045
2e5654eb-b59b-47e0-b8d6-b57ef8bc2b96	柏丽	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:00.815045
cce1f682-835a-45cf-817a-190d98e47cf0	科瑞	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:00.815045
1837d9b8-ad83-4f3a-92a6-ff5c22017382	艾玛	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:00.815045
54006d87-083a-45ba-9bc4-33ee6dfdbbf2	箔乐	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:00.815045
6f1965cc-79eb-408a-9239-f55fe97a16b0	培迪 peidi	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:00.815045
7a034199-f095-4e05-ae31-e1540cbf571f	玉环	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:00.815045
cb2015c8-19c1-4bba-86eb-b28b55b7683c	飞獒	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:00.815045
086f020b-8e24-4a63-9db1-da8f1a25f958	喜润	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:00.815045
1a873765-421f-46c2-bd8d-b46b5f43130e	广东	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:00.815045
770ff724-8eb0-4839-8c45-ac4777ee8f09	飞爪	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:00.815045
8ddec28e-526a-453d-8824-30453ef67c80	北国	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:00.815045
3130d0f5-3310-48bb-901f-873ef5814414	英联	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:00.815045
534a48e4-4f68-4ea9-8d12-42f5a651aa72	礼正	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:00.815045
9f090e0c-85dc-47b2-844b-70a1c4d7857d	星晟	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:00.815045
8380279a-746f-4ca5-b9d1-dabfcd1fc3ee	金沃	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:00.815045
ba709da7-72e9-489d-aacc-9fb607d5a5c8	FluffyWorld 毛球世界	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
463fd3e8-a540-42e3-9ab2-ffbeda567ddb	ugoo	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
8724714a-13fd-4051-9eef-1e350a68486f	珍	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
e4097880-fbe0-4b4e-a092-1257203d728a	HEART	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
329f7432-6327-42eb-8977-2b6ccdcc3a74	萌派	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
9ec2274e-b793-43af-b397-2cbb78f3944d	内海	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
d2d929c2-ad30-4bb5-a0e2-3edadbf5c6d8	多宝丽	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
c5aee6c7-0319-4802-8a76-2d1080202381	富士樱	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
5f3b1af2-8e04-4d5b-8566-61c30397ee1d	奇愈记	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
4544196e-c80c-4f7f-996f-0d6e529aaed1	哆	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
4bc7eb77-8b13-494f-97b5-f642473fa8f2	ALAZA	\N	\N	\N	\N	中国	\N	2026-08-07 20:20:04.249922
b8ae79bc-3363-4f2d-8eb6-69544c3eeb11	Lickimat	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
82e63ce5-e312-43c5-b83e-4a9a7fbc59ef	七十迈	\N	\N	\N	\N	中国	\N	2026-08-07 20:20:04.249922
e090d5ce-0b5c-4eab-841e-520670454ec1	爪淘 Zhuatao	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
a5ce9c2a-53cb-4e8e-bd7e-1561141685e5	亮佳洁 lankit / 艾力斯	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
a4c34bae-0cf3-411c-878e-4ad57da341d2	pets	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
890d9044-0f1a-43a1-97d4-0c57fd72f36a	毛逗科技	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
564b3b9d-2891-461e-9a9a-cdc6d757b15a	赞乘	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
f1a4e748-7a6a-4967-8ded-b1bb6e8f18b6	嘉木	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
4e1d638b-9aae-4c59-82dd-9313fae8a444	卡乐迪	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
9848c604-9142-4cf5-85f3-6e0ff3ea6111	家朵宠馨宝	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
1f222ead-e24c-437e-a075-c5a7370d267c	Payoner	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
324722ff-1d32-4578-ae5a-0cec765ccd3f	英纳	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
d1251a13-5786-4c72-aaa9-47a524c4e93f	嘉	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
2e55b4b8-166d-4be9-ada8-2bc7cb31df5e	亨嘉	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
4de6e75f-8d0e-4ace-a1a9-1854d4056439	鑫鼎塑业	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
159e96b7-878b-40e0-b23e-5fe712588f77	三又二分之一	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
b6ecff0b-203e-4463-9f87-972d1b274fc9	胖西瓜	\N	\N	\N	\N	中国	\N	2026-08-07 20:20:04.249922
4e1ca105-7bb6-40d6-9a16-8e0e48b333d8	锦晟	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
2bf1ba6c-f32d-4136-a94a-523b2882c0bb	宠	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
936d994c-1e66-458d-9ff9-2448568f3422	易路洁 eco-dean	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
98e079dc-8412-434f-9466-5036ed416926	Kaggia 咖家宠物	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
f1bc75fe-7957-44a8-b042-54488c0f9979	帝尔 DIIL	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
5636d5ef-f969-497a-98e5-fe7b0fd0fe60	猫王	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
949568b8-1c06-4420-baf8-6d6a7c4a3125	品诺 PinLuo	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
30c9f7f8-3ce4-4eb5-97b8-b65efc177e31	宠灵	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
daace5b8-95f5-491c-b4ce-7f7484c2ec99	小爪印	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
e8921be7-6bbe-46ff-81c6-b8038097c4f6	乐它	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
18bcc194-f1d9-4ef7-a28d-056f4ad8a8fb	宝睿 ST Pethlp	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
321c6b06-e4cb-4e4f-ac12-777b28319dad	会议论坛区	\N	\N	\N	\N	中国	\N	2026-08-07 20:17:58.717965
64f29a3a-c5f0-4c7d-9b8c-dd697faae067	绿科化工	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
0c6e16b6-1f40-4ce2-8c5b-0e6cc82dfc6d	HiDREAM宠生几何	\N	\N	\N	\N	中国	\N	2026-08-09 10:26:25.578841
5a7f6dce-1f30-4b95-b6bf-c9ce18df0684	西安	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:03.79486
ef0bd542-0845-47fb-8da8-a819f7b9dc9f	高晶	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:03.79486
bb07e60f-41d3-4851-9037-7f75c544df68	东恒	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:03.79486
d850efc7-10b1-47be-81d9-365215ef0955	星可瑞	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:03.79486
74071831-71c4-4a1c-af2e-d7813940097d	深圳信站	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:03.79486
a302e84d-5183-4e97-9907-edf566e3bcc6	山河	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:03.79486
670ca988-09e7-4b6c-9e23-1b6ba4148298	精致	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
758763de-0a94-4407-a032-a66295ea7200	新奇町	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
d593e277-b0e3-4cd3-afe0-11ffc71be8f0	宠淘淘	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
ef3891f6-45fa-4fbc-bb49-2209ec768b23	萌聪喵	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
ced54f41-146e-4582-a809-323a892023f3	Ju	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
3d8b8579-b745-408e-a7dd-b43f93e44c1f	papo	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
870e808f-d3d1-48cf-a417-ddcb5ae4eaea	榕威	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
0a3b72df-d895-49f4-a661-8253ab2bc20f	LEZHP	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
e7cdfaae-0f7d-4d47-a3dd-fa914f1dac58	小孩儿和猫	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
7714e8f7-8c7c-43b6-a43c-ce6b8236868b	dian	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
cc364a5a-7c0f-4505-90c8-c7365838755a	Paworld	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
43f8145d-81c2-4cf2-abea-fa86c81a4763	Decopark 吴可趴可	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
250a23da-d9aa-489b-9956-2de1bccb17a5	GENKI	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
f1fa4bac-5cca-43c1-affd-23b3f668d5f5	meoof	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
b2b2ba67-0ee0-4add-80f5-1688b02a2fb4	萌萌	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
b764ae58-d067-430b-8d4a-9bd3d16eb25b	毛毛与屿	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
c9373323-b850-4d0a-ac51-e22c8018e99b	换儿	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
753ae134-9ffb-4fa4-9e38-08cc916c4e93	LOVELY DAILY 绎仁文化	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
598ffdba-1822-42a1-99d4-9207be358193	英之堡	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
64fa84b0-51d3-407c-b001-578187b41e23	朗际	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
4bfc55bd-6912-4763-86da-13613be2b9ac	丁厂长	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
5a73b821-b011-48e9-a0ab-0cf38fd34b9d	旺 PDP	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
4bb68917-7898-4597-9fee-022b91251c26	吧啦	\N	\N	\N	\N	中国	\N	2026-08-07 20:20:04.249922
eaf3758a-e910-4362-816c-9488a2a2bc08	木奕之间	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
3c38130d-99ec-4fbd-82ec-ef4dd6d8a589	朗图	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
824843fb-1bd9-42b7-8211-a340ed9f4a64	天净猫砂 NeoClean	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
98d5d973-d043-4871-8511-c8aedf5a4d28	小猫勤宠	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
4bbd6a90-e662-43a5-969d-3a1ddb9aefd8	红纺文化 盼酷星球 pancoat planet	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
e90375da-6f1e-473b-8639-80de1a52fe3d	倪可露 Nikoro	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
776d1682-dfc4-48de-a972-9b504ed613c1	华元宠物 Hoopet 喵小元 MIAO XIAO YUAN 艾禾美 ARM&HAMMER	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
8e63e022-ca6a-4eb7-9315-5795f1af3c03	加拿大 OPANZ 小爪印	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
7553df94-f5fd-4773-8d21-527e5af4b2f7	旭	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
1c2f835d-a13f-47c8-b09d-88683bf042e5	有赞 YOUP!	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
9331d311-5e06-4445-9312-322f965e17f6	CLEAN STEP	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
cb078404-ef04-425a-95d7-98603f159f05	京悦昶和	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
6ff35080-d607-4958-93d8-73ea295475c6	映宠	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
e18bd1d8-36a5-47c5-8e7a-c0cda62bdfe5	咪莱哆	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
ae39d334-769c-4c50-b399-aa32bb3959fb	运扬 温得	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
87f9f42d-411d-427c-a08e-4752f6ad640f	德荣 D&R	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
f3e05cc5-be5e-47f0-843a-9aef39046af3	Smileplus	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
84b8e5cf-d0b7-489e-a498-1adabd382d87	玄鸟 工具	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
a9cd99bb-1382-46ee-9e4b-263252a764b1	阿默 Amo	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
f57ae153-5835-4d55-9535-3ce1553ae0b1	宁波繁简	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
f1ed5ea7-37c1-4c2a-a15e-6abe8040bd69	鸿健	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:18.687224
54eec28a-17e2-4815-b2ac-ce3b85d2fca5	霏知 FIZZIFYZZY	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
ce0b51c5-e7d3-44c7-b4ba-34f4c7a25d36	皮小兽猫砂 PIXIAOSHOU CAT LITTER	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
df360c51-c13c-470f-8de6-2b6c73179563	宠物嘉	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
a3f7910d-b14e-4c2d-bae6-b79022199ced	杭州海慕 Hellomoon	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
f134f420-4b89-436a-86f7-e52472467756	窝里横	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
03a67bf3-ee5d-4c4f-b0b8-c712349b8cea	凡思	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
a17b85be-c66b-485a-a376-cc5d1b0d5525	Pawny	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
ff0d270a-2a49-4339-bdb5-f391399adbf4	比利时 M-PETS	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
2cd1f2ad-7278-4766-847e-879d9875bd9a	PURDY派递	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
e38f26ae-e555-43c4-b185-bab009b04d05	avalon	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
ee40085f-89d8-4320-ab5e-75f4b82a95ea	UnTouTou BROWNIES D's chat	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
685aff5d-49cd-4be9-b769-bc780ae32f9d	多乐米	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
b4f6080c-40fd-4dd8-b364-b8914541f0ec	doubaod	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
831ea778-fd9f-4ed3-9e3e-169390cc087a	Breezytail 福来之尾 Tailhigh Pet Paradise 纽滋宠 RIFRUF Maxmolly	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
60ff70e4-5910-43aa-b212-0e86ac59172a	囧宝	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
c6b1085f-1ccc-4b49-8f70-f555e3ecc733	超	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
dbf777ad-4e50-4114-85a7-1d33de705a13	旺门宠物	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
e8d77d94-2b1e-44d7-bf80-b5f8631b885d	凡爱 KONG FAMIPET	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
6199892b-b891-4183-a6b8-627f9747f326	卡啦酷宠 KARA PET	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
1c293e84-00da-442b-bbad-eea02cf110cd	孚	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
547a040a-1244-4458-a36a-950db8a28495	觅嗷 Mioloo	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
864ae857-9c47-4128-86b5-393cfba2c514	Green	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
858b36fd-4066-4327-9fbc-952b78287c38	多塔宠物	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
873e89f8-c11f-4d9c-a152-75fb45280650	邓氏	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
269b9440-9b0c-4d20-bdea-2438f544ed38	宜特EETOYS 無谷 怡宠星 帕奇宠	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
150303b4-06a5-4d72-8388-fe8f812a4494	森·多利	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
86c0c2fa-a312-4c86-a5dc-9db14bc776ff	PETZOO BITE ME EZYDOG iCANDOR AIRBUGGY HUNTER CLOUD 7 MyFamily HARRY'S PET 椰椰家YEVENITE ITSDOG PLAY PET PAWTY JOYSER Ainoap Anelement	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
8725ba6b-8460-47e5-8a76-9eaa9c524129	派力德 PETLEAD	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
0fc71e6a-853c-4f7d-a5d9-a01537a58210	NW学院 / DaBO塔倍 / CHIC PUPPY	\N	\N	\N	\N	中国	\N	2026-08-09 10:27:48.67152
6bc7acf3-89b4-4b0d-9668-c0a8394cce7f	蜜禧 听它说	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:14.083479
42d38f60-ba6b-4c42-b42d-f3009fcbc39b	寻本 宠百惠	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:14.083479
09831823-b590-477b-9a4b-dc64c7a5206a	WUI 与你	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:14.083479
a8b09807-2bc6-4c2a-bb1c-14ac4d459c3e	Nakip	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:14.083479
4b06bb60-5676-41cd-aae4-46566c625521	熙贝	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:14.083479
50051692-0985-472e-a7bf-d2b8229c9aaf	诗娅	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:14.083479
b5cca699-e77e-4fdf-af44-3055db249470	关谷庄	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:14.083479
5e550404-ec30-4d4b-a1ce-30a3b82b0b90	零条 天狗 棒能 主食代	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:14.083479
183e19b9-0c8a-47eb-a779-96acabbf3a0b	胡子 弯弯	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:14.083479
7876e2ad-952f-48ca-81da-9702a00a446f	Cuve group	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:14.083479
49544b2e-de73-471b-9c46-4c410932948e	格吾安 GUAN 东边 DONG BIAN 莱野 LAIYE	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:14.083479
bd19074f-3407-450a-844d-7b8ade9d1329	布兰德 Bright 猫儿游记 THE CAT'S TRSAVE L 配加 Pegapet	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:14.083479
19ec68f7-963d-41da-a157-945e77b1b51e	大连圣诺	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:14.083479
4382eabf-1e9a-4458-84b2-e167722863b6	清营	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:14.083479
c8d09fd6-a54f-4533-9e8f-7d880a548a10	鑫宠优源	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:14.083479
c6dd52f5-7fa6-4fbe-93a8-c430aca76eb2	莞佳	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:14.083479
fa12c786-e5db-4f76-aa4f-d4796ff448c5	元气软软 Yuanqi Ruanruan	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:14.083479
9c0efa4a-d64b-475f-a844-c65997ff116a	Ruey Jenr 奢哲国际 Iv San Bernard 伊珊娜 Vanesia梵希娅 Wellness宠物健康 Gimborn俊宝 Soulmate思慕特 Health Extension 维采康廷 Heiniger梵茵儿	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:14.083479
ceb7a548-f7f6-4037-bdab-72b0748bdb82	派森 PETSENSE	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:14.083479
5cb225ab-ba74-4452-bdf2-dd3104a95400	喵知味 Meowlicious	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:14.083479
14e8546c-f0e9-4ea4-92f0-2b21cb9e706c	诚实一口 HONESTBITE 酥醒 SU XING	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:14.083479
30fafb7b-eec0-4eac-b107-d5b80ab2f4e4	猎味	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:14.083479
30e47217-b700-4504-a46f-1e89b70cd88d	布袋	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:39.668763
d5aff076-88e0-4b06-9a9a-8a22c0670dd5	伴它	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:39.668763
30a9f894-3e78-4a8c-be6e-a3104a7507a2	熊	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:39.668763
296655b2-5a32-41c2-a119-6f8bbeb574a7	仟亿金牌	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:39.668763
fca21141-fc33-4ab5-a9ab-6391dc6970eb	汇亿新	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:39.668763
a0a2b505-57b8-48dc-b639-61d9af9c800d	多宝	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:39.668763
403c0c68-7e70-4c4f-b6ed-07bfc34c25c3	爱宠	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:39.668763
79101140-d819-443c-a46b-4514c8e97aa7	紧急集合 | 千巴公园	\N	\N	\N	\N	中国	\N	2026-08-09 10:28:39.668763
c990a204-3109-40e3-95d0-f976a28e7f66	梓桐 Shandong Zitong Packaging	\N	\N	\N	\N	中国	\N	2026-08-09 10:29:09.98267
1cf066ca-ae6a-42f0-9577-9a7d3a149e37	峰海包装 Fenghai Packaging	\N	\N	\N	\N	中国	\N	2026-08-09 10:29:09.98267
c5caf7b1-c266-44f9-a94e-fbfca6ebd860	展彤包装 Zhantong Packaging	\N	\N	\N	\N	中国	\N	2026-08-09 10:29:09.98267
a88fbc80-f12e-4112-b69d-1a6e10803184	思享包装	\N	\N	\N	\N	中国	\N	2026-08-09 10:29:19.51431
5f54ed9f-f8ed-4aa9-b7be-c0b2bd543e90	伯尼纳	\N	\N	\N	\N	中国	\N	2026-08-07 20:19:14.455302
371cf3a7-80ae-4033-949c-a11e5024d2ea	浙江恒熙	\N	\N	\N	\N	中国	\N	2026-08-09 10:29:19.51431
5d17bc6a-c7ed-4cc6-a84c-09bd6c88bf66	箔洱特	\N	\N	\N	\N	中国	\N	2026-08-09 10:29:29.502371
0ff1bc1d-d132-45ea-bfd0-5ad0cf626c6e	明月安欣	\N	\N	\N	\N	中国	\N	2026-08-07 20:19:14.455302
e1a304e7-a1c5-4cb0-8f5d-ff3be7ba7cb3	康大	\N	\N	\N	\N	中国	\N	2026-08-07 20:19:14.455302
53c552ea-9d33-42d1-899d-6ca94bfcd7ef	格林富特	\N	\N	\N	\N	中国	\N	2026-08-07 20:19:14.455302
acdf9596-af7d-4d80-9a82-01dc8a0ccfec	山东亚宠	\N	\N	\N	\N	中国	\N	2026-08-07 20:19:14.455302
0b6214fe-a83b-4390-8334-84691a2bae23	万耀维盛	\N	\N	\N	\N	中国	\N	2026-08-07 20:19:14.455302
e4e47b04-2dc0-4a19-b06b-0931a84883e2	卡尔	\N	\N	\N	\N	中国	\N	2026-08-07 20:19:14.455302
8c65dd05-7100-44a2-b604-b6f12dc2327e	维芙尼	\N	\N	\N	\N	中国	\N	2026-08-07 20:19:14.455302
bdb73a4c-ae92-4d3a-94a2-3b360cfc6b82	火星碗	\N	\N	\N	\N	中国	\N	2026-08-07 20:19:14.455302
fab12edf-fc59-45fe-a870-36ebc37c62b7	蔚蓝探索	\N	\N	\N	\N	中国	\N	2026-08-07 20:19:14.455302
9e2ae1fb-2a89-401e-b7a7-0111ef1b7222	信鹏	\N	\N	\N	\N	中国	\N	2026-08-07 20:19:14.455302
a810b94c-2cd4-417d-b2f7-0b25ff5c4618	亿博	\N	\N	\N	\N	中国	\N	2026-08-07 20:19:14.455302
73509be7-40d2-4e46-9dc4-785c282872ba	米澳	\N	\N	\N	\N	中国	\N	2026-08-07 20:19:14.455302
35a176e0-c9f4-4dc4-9959-00136b1dcaf7	鼎望	\N	\N	\N	\N	中国	\N	2026-08-07 20:19:14.455302
83298c0a-fa7a-4402-b091-72276fbd0483	营润	\N	\N	\N	\N	中国	\N	2026-08-07 20:19:14.455302
62e767ad-04a4-4e68-9f77-ac33b69390a1	功能区	\N	\N	\N	\N	中国	\N	2026-08-07 20:04:25.048155
49968591-6a50-4bb6-8a21-d5f44d71d47f	Vanpet	\N	\N	\N	\N	中国	\N	2026-08-07 20:55:08.191641
7ea635ab-6bf5-45ec-8e92-e4122907bc1e	阿飞和巴弟	\N	\N	\N	\N	中国	\N	2026-08-07 20:56:07.587698
c82cfd83-0455-423e-a602-0c764c48a8e7	品卓 守护天使	\N	\N	\N	\N	中国	\N	2026-08-07 20:56:07.587698
7c961017-3f11-4574-8b36-444a07956e05	多美洁 Tropiclean	\N	\N	\N	\N	中国	\N	2026-08-07 21:01:36.649156
e23c94cd-f39a-490f-87f2-1e0fa5e3660e	伊纳宝 INABA	\N	\N	\N	\N	中国	\N	2026-08-07 21:01:36.649156
8f2809b8-8b57-4234-a50b-b26e75691da5	京东	\N	\N	\N	\N	中国	\N	2026-08-07 21:01:36.649156
26824d1d-eea8-48dd-b738-ea732c4636eb	宠之优品	\N	\N	\N	\N	中国	\N	2026-08-07 21:01:52.16346
f75262c3-f88c-49a3-9e90-bd0c5ba1ddac	希德罗	\N	\N	\N	\N	中国	\N	2026-08-07 21:01:52.16346
dbf0b9e9-7ea0-433b-89f2-3f9a7ec8b877	盛喜 ShengXi	\N	\N	\N	\N	中国	\N	2026-08-07 21:01:52.16346
e468f186-ef0c-425e-9a7c-161200d4b3cd	达洋宠物 Dayang Pet	\N	\N	\N	\N	中国	\N	2026-08-08 10:58:26.462044
0b143ad1-5862-4a74-b419-f6a86ba8fff8	集宠区 G-PETS	\N	\N	\N	\N	中国	\N	2026-08-08 10:58:26.462044
021afd73-e0e2-4121-a293-6298d99463a0	金瑞源	\N	\N	\N	\N	中国	\N	2026-08-08 11:08:10.487984
d8504d40-8940-4472-826c-21f49920c599	海派	\N	\N	\N	\N	中国	\N	2026-08-08 11:08:10.487984
20ddf152-42d8-4afd-bb0e-8e318ed61f5c	佳鑫	\N	\N	\N	\N	中国	\N	2026-08-08 11:08:10.487984
2da59f94-a2a1-4903-9dcb-3e3010b17e44	宠管家	\N	\N	\N	\N	中国	\N	2026-08-08 11:08:10.487984
4be2f987-9ffe-40f7-b17e-bd2b0efce065	笑宠	\N	\N	\N	\N	中国	\N	2026-08-08 11:09:40.949064
a6d52420-68d2-44ab-bab7-5a3c4ef9c307	毛茸茸	\N	\N	\N	\N	中国	\N	2026-08-08 11:09:40.949064
fbcb336c-c1d3-46d6-86b4-4f441c16ebdc	WANPY 顽皮®	\N	\N	\N	\N	中国	\N	2026-08-08 11:10:57.172546
9c61db58-5275-40f1-a4d3-389147b15c0d	路斯 Luscious	\N	\N	\N	\N	中国	\N	2026-08-08 11:10:57.172546
b7edf629-9ccb-4a57-a4e1-b40478bf6b97	洛阳朗威	\N	\N	\N	\N	中国	\N	2026-08-08 11:11:17.857312
ee572729-d734-42ed-a825-41f18ad248b8	雅博	\N	\N	\N	\N	中国	\N	2026-08-08 11:11:17.857312
0db238dd-c063-4580-aedc-5be2963634ba	淘宠	\N	\N	\N	\N	中国	\N	2026-08-08 11:11:45.764654
d7df889d-9a01-4504-bf74-7d3a16462aab	坤昊	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:37.501395
94c2d1d5-e1c9-4539-a52f-8e649a92c784	休息区	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:37.501395
9697173f-e26f-4600-815a-7995f25430eb	天伟电机	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:37.501395
8246e659-7d89-4b58-9cf2-05e8f42a21c3	任远冻干机	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:37.501395
605cefcc-6bb0-4440-9f91-6d628e23883d	富腾电机	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:37.501395
0ac73330-f70d-4b84-8ca6-2c810c2c0b9a	付工机械	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:37.501395
a1746e7c-50bd-498f-9014-c8eec4ddcd86	科盛机械	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:37.501395
88f82e8c-a76a-4c66-9b87-def45a65fddf	东旭亚	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:37.501395
936ae46e-cebc-491a-b9ad-d197a77f6937	惠友 HUIYOU	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:37.501395
6435c0f7-bb97-4edd-aea9-ea9feb512dcf	达润	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:37.501395
b6ce0725-dc56-42d7-8abc-890f38a7e22a	博洋电器	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:37.501395
87229f15-c791-4a14-845f-a229147d4544	华美万邦	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:37.501395
b70837c5-9e41-4e7d-bfd7-f7fb014feca3	迈特瑞	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:37.501395
c1e9ec94-86c8-4ebe-aa63-fa1af21abc7e	瑞鑫达	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:37.501395
e6c2aa1a-b8f1-4834-a198-c004bf7daaf6	航天东方	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:37.501395
e0398fd6-620a-4f37-8a1c-5b72aace6d6f	乐味	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:37.501395
7b549b48-54d5-4f58-8a71-f75962df3d47	福瑞达	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:37.501395
0885cc23-03d2-488e-a225-514fece2e037	天津创鑫	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:37.501395
01be665e-a487-4334-897d-ac919abb9f3c	山东佳合 (海派集团)	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
2e91395e-15fd-417f-892a-9f80d83c84a0	建明工业	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
59ab73f8-e35e-4060-a05a-0387be201192	海大	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
d69f6a7d-1162-4e57-a54b-27ea3641f957	成都祥钰	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
c08c6fe6-03d3-4d89-9993-96734efbada9	欧陆分析	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
690eaa13-a630-4107-9e86-2a5147ecabe7	久诚	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
f9186911-549b-4206-87c8-6934d3c425e0	丞善实业	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
48022740-6089-4263-891d-9bdb59b0e305	宛珠	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
8ad92136-7a72-47e8-b43d-973f500a1dc7	必维	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
2f16bfcf-ba8a-4a02-855e-27ec11b20304	澳优	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
1b79694c-bda2-41c3-90be-c443699bad6d	布鲁克	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
997489f9-b6bf-4b00-a636-0f9bf6bd3966	朗适	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
d6544885-1231-4abd-a7b6-d922d42d95c5	金四海	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
bbb7ebb9-5d90-4a4e-9f09-5f2afd2ddb41	临沂绿洲	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
87a037ca-23be-411c-b091-1051544e5861	康绿森	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
6772e37e-a830-4225-b426-c9495217e0dc	根源生物	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
212af8dc-9383-456a-9352-3b84a9ae8f8f	美味源	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
ee5d5dfc-95f7-436f-8a31-b776c9b5fc32	华测 CTI	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
f38d2fab-374b-40ba-8932-55081433abc9	欣宇辉	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
571d000c-9499-4b77-9849-fcf0f1e3b84f	LALLEMAND 拉曼动物营养	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
8f766c0c-ce65-4415-9223-0575a3daf374	奥迈生物	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
215b60df-51b1-4912-bd5c-2c196ca706de	五丰海洋生物	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
5ed0ad82-8958-4997-a98a-5acd1475024c	伯迅生物	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
fa9b3cf0-2405-4bb0-9fd0-dfa95646d7f8	奥特奇	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
fea95629-65bb-4b1c-b5f0-5edba99d3e36	河北鑫达	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
c4b4c8ab-6a5c-4193-9e77-2f7c5f7528b9	中农合规	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
4faf6b93-b2df-4537-bf11-1dcf0df08fc8	圆大生物 SKUNY	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
d27fe553-030f-4b96-9661-95fac51b58b0	龙沙制药 Lonza	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
c65353f1-8f3c-4748-9111-42326e1a162a	迅杰光远	\N	\N	\N	\N	中国	\N	2026-08-08 15:36:58.423796
dac97230-4380-43c4-9960-f5b9389775f0	松川	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:18.402299
bd32bab3-726d-4a0c-a570-b8788a6f8f8e	今超越智能	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:18.402299
e9bd4cc5-0f9b-4093-9cc2-178a13c758a2	日本世高 System Square	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:18.402299
331bc81d-cbe1-452a-9521-a37439423009	南云智能	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:18.402299
f37ab7c8-79b1-4d9c-b7eb-6fc688d74282	华富润达	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:18.402299
e5017520-3695-4b8a-b07c-bb930e3c0a2b	欧迈威	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:18.402299
f64772da-e910-4670-89dc-b30d350862de	青岛科瑞	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:18.402299
4e0064b6-1f63-4677-92f5-a0f07f5176f7	山东申德 SDET	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:18.402299
469dd5ce-9c29-4609-b29d-668878a5ba79	思美克 CMK	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:18.402299
71bce9bf-fe0b-4b1a-89bb-96250da266f4	伊诺威	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:18.402299
41bbb33a-5328-40c9-8578-ea21be4d1551	金鑫净化 JINXIN	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:18.402299
20f44bdd-6ef7-44a0-a2b0-d1a9e4c93c23	佑天元	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:18.402299
4aee33bd-d4c2-4c44-b4da-1ef33c6f466c	天津太雅 TIANJIN YES	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:18.402299
c2b2e990-8d2c-4856-ba7f-94c3570fdde3	鼎润 Dingrun	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:18.402299
981e2a90-1a4b-4bbb-aa07-dc52ee8d6322	春光	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:18.402299
b28a35e0-f36c-4c6d-b141-875adcdf28cf	三生和	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:18.402299
804056be-1fbe-454a-bffb-3d8a0cbd7976	瑞泰包装	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:30.224883
0e63191d-d79a-49ff-87ad-49613616dc65	VEMAG威迈格	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:30.224883
ecd0a3ef-a9d6-41e0-a503-ada057b9f78a	鸿祥瑞	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:30.224883
027768ad-6044-4d5a-a309-05e1da81589d	好为尔	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:30.224883
c9cb593e-afdf-489c-9f1a-bd1751e51824	志伟机械	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:30.224883
1eafb8c6-1499-4fc9-a55c-f03c6c6007e6	精派机械 King Pack	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:30.224883
fbf0200a-cdd3-4553-b3cb-47a4ab8e3cd2	江华机械	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:30.224883
a02d339b-fca6-4087-a982-fbec31a2392e	鲁佳	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:30.224883
372aecc7-4536-4b25-ab47-5900d4a4ff13	三马净化	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:30.224883
2cbd8846-71ff-4438-b3ee-f4e47a596e12	广州和易	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:30.224883
08a4ba0e-f280-4dab-b649-ea4908bc6e0f	怀力普	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:30.224883
3752399f-7929-4b09-9698-ffb97f50c851	常州新马	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:30.224883
effb9108-3bd3-45f3-8298-ef4299aea61f	天津盛泰 Tianjin Shengtai	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:30.224883
34177cce-7c92-4c3f-a2fa-de1dc88311a0	格律克	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:30.224883
be035c74-65cf-441b-bb44-8ad75584f091	得利时	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:30.224883
750c16f4-787b-4bd2-b1ff-3fdf96931456	诚业股份 CHENGYE	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:30.224883
f03c11d2-07eb-4e1c-95ae-f3e616fb91cd	泉州天发	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:30.224883
aec149f0-7d7f-4dd9-a755-eefa2000014b	佛山晖佰	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:30.224883
70a72997-c3e6-4449-bbd5-46fe81f6d9bc	瑞志机械	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:30.224883
ff469faa-2127-4680-8cf2-98b7d96b03f9	港龙	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:30.224883
55d52a7e-47a1-48e7-b5fb-78c08bc109aa	森沃	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:30.224883
9a28af94-79ff-4790-bd72-8e4873fdcdc4	天发机械	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:30.224883
5af738ac-8b25-40a0-8a81-db9a63e910ba	远东机械	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:30.224883
80248d85-37e3-4e49-96c9-11553fce9d4f	新力	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:30.224883
207984c1-9223-48c3-81d6-2bcbb7f3a2bf	名德机械 MINGDE MACHINERY	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:30.224883
1d08d327-887b-41f5-9e3f-f788d410e8f6	盛荣	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
725baa94-7c30-4a16-91bb-0f5ec30e8cc1	中瑞制罐	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
1c252dd1-d8b2-4ac6-86e8-67664ec5269e	宣航科技	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
28279ef0-cc81-4ba1-a8d3-5d1851ba2e3c	森奇	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
0e3cc135-305c-4de2-8a16-48c46a164ba3	豪门印刷	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
df359db9-fe3a-4aa3-ae8b-de6650ecb940	夹河彩印	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
8abb448f-c814-4462-a8b4-7c5a08812cc8	伍星	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
f0d64d5a-84ee-4dc4-a68c-5f7638880b47	心合包装	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
98f89662-a1f9-4542-bbfb-614166b0e90c	博浩彩印	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
3c637ce2-0a4a-409f-8c83-813bbced8db0	多普纸罐	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
b4dcf87f-e4cf-4bb9-8bc0-28980beeb7bf	群乐包装	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
71ca2754-2b03-4200-8613-6ffe59daad27	海赢	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
e56f9611-0842-41d6-882b-51f9a9ad2d0a	博升	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
da3169f8-3387-4115-b3e2-2ac42372093b	鑫盛制罐	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
69e936c9-58ab-4a67-a938-52d41376b56f	肆海八荒	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
f68a9150-02ab-4f33-a3aa-294f6c400dbe	兴泰	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
48e802be-3054-4d0c-bba6-6e33a11d1399	鸿亿	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
f54cf8b9-2f21-47f2-ac72-ffad94661866	金泉设计	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
67c3ff30-e8d6-4b89-91bc-88a1bfcb2b61	励志	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
9fe3fac2-3855-4f63-b6d6-9d5a269a4fa3	恒缘塑业	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
f4836a4e-8ce9-468e-9e36-5d57ce42d150	方泓	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
2c1f8967-9bae-49b7-9611-79997c65da8d	通赢	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
daad71a1-6d4b-41be-a00a-af74d46a22c7	欧达雅	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
d1a7c7a8-f753-4cd7-b194-95df8695c806	文祥印务	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
5d6a8353-176a-42b1-9ad4-acb9ee54fc8d	烟台美丰	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
a3c4b665-c8ce-498b-a4fb-c658fbb43b6a	益美莱	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
0f0cec4c-7a25-465c-9e8a-7fba11190d95	英特	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
268ea185-b2b7-4433-bbb3-0d2c9ef0fbc2	花园铝塑	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
35a59807-d70c-4708-8c4b-67111c93c0ba	隆盛	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
69ab6e53-cb1e-4f76-a096-f6ad6b8e8f34	高志远	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
cb40594d-7ac5-4c28-b881-d0a6029af57e	优好包装	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
9e94869d-98bb-4f9f-9f03-16eecbe3d740	创佳	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
1643c3bb-06eb-4fea-8ac0-7a8c7e9834ec	台州祥珑	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
41da44ce-e76d-42cc-a682-c561bb7ae7df	恒地	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
23b60bdc-bf39-4ee7-9dfa-43556908ca55	众鑫	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
ddb2a672-7560-418e-a752-b639991f2cfe	小森	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
03872754-60df-4244-bacb-d7516b2518b8	臻致包装	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
d95ea32a-0a12-4e60-85a3-f3b9821226b2	联昌	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
481930bc-0435-4000-b3cb-56f78417542d	丹青包装	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
c9e5f540-35cc-4f20-850a-43f7a03a9230	禾谷	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
677963e8-ba25-4246-aba1-f36bf4102638	雅信	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
26cc2187-786b-44dd-9d45-d5fffe23a4e5	派瑞特	\N	\N	\N	\N	中国	\N	2026-08-08 15:37:43.281727
647dbde1-fb44-4cb2-9765-00a7504d741c	德必福	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:06.930337
2e12176a-d767-424c-83b1-9f5ca556c910	帝斯曼	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:06.930337
bc634916-c2e8-4e5f-bea7-bb597ceac4c8	翼邦	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:06.930337
3a6730c4-5331-40e8-b940-f79a4441f732	泛亚	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:06.930337
c2b77142-27db-4f8c-9e5a-2879eb35ee15	江苏益宠 (派乐博)	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:06.930337
54ffdce2-5129-4c7a-a20f-6dbad7af2bf7	山东泽海	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:06.930337
544c65d1-57e7-4431-8444-aac7e2f18282	宠贝冠	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:06.930337
3fd4be61-7c0c-4bf7-aa20-745ac8894982	正润生物	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:06.930337
8901e986-86c6-4564-881d-fa4c02e93547	盛美诺	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:06.930337
962df428-6d18-41c6-8b59-7bf0590e0975	爱必思福	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:06.930337
10585d61-4135-4f6e-b98a-cbc1371703ac	玉琪	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:06.930337
fd1813eb-a224-4acd-a8b1-6672881ea8ad	索纳克 Sonac	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:06.930337
ff933fc1-395f-4ad0-ada5-33499f41fb46	吉宝	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:06.930337
afaae4e3-a38d-4c72-94df-6e8dada56340	嘉必优	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:06.930337
be96b343-a875-44fa-a16b-8eea3be827da	悉源生物	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:06.930337
4f7e5a5f-817b-45fa-bebe-f82446fdfdc9	爱普	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:06.930337
dbc15cf3-74fb-4e3f-aa70-42e3bcbf469e	中科昊盈	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:06.930337
3cf30dee-63c7-4f9e-a863-8406771609ff	贝福沃	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:06.930337
06529949-2a02-4865-a4ee-67c215af5c5f	美拉的	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:06.930337
188526d6-bb41-43f8-9ab7-98820f8d0681	一致魔芋	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:06.930337
642601eb-8c21-4b4a-bbc8-e2f01ec7da38	星火优品	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:06.930337
6d0d7f9e-03ea-4f6f-acae-f849a4fc9eec	泰多泰	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:06.930337
3ab91c70-7b35-4395-af2c-c3669ac7123d	唐朝	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:06.930337
99df0151-8be7-4776-8b9e-67ca7de53f75	南通银琪	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:06.930337
3cb43324-f259-437c-bac0-1a94e1624aff	干霸 SUPER DRY	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:06.930337
cbc90f66-5a01-4991-9ec2-245428e9c17d	方大	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:18.275159
dd548511-1442-4987-a5b6-d11297ce1510	巨龙包装	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:18.275159
b5c94720-379c-4d1d-81ce-c4fabb73969f	远大包装	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:18.275159
92261d61-9b34-48a1-869b-c7ff5d7f9a11	星灿包装	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:18.275159
7bbd9e24-96fc-4e4d-9800-893740d31a49	顺立安	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:18.275159
4fca2e05-43d3-459d-997c-73cddca1f744	雄县新联	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:18.275159
f9329b46-95a7-4e84-900f-5d69349fa11c	乔悦	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:18.275159
e8f1a19d-2ca4-4c1b-b99f-77611dfef19b	万辉包装	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:18.275159
0386fc51-1bd2-4218-9f2f-260f2b1407a9	光明塑业	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:18.275159
6f5f53e0-5c5b-4dd4-9223-14d870aa8ba7	南新印务	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:18.275159
4b416286-54e8-491c-9497-3f10568a0bf7	奥华包装	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:18.275159
d6d0d806-92db-43d8-80ab-b2224ea0d272	京澳	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:18.275159
b6c78b60-073d-49c4-af36-bdc98c086852	兴安恒达	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:18.275159
1ac21f99-eabd-49cb-bc4b-f4d2b8cf6e5b	顶天包装	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:18.275159
7b644eca-b27d-4169-a4d6-6abee7883022	泰耀	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:18.275159
e29966ed-aa89-4b62-b107-641b81e7541e	万利	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:18.275159
45b39e02-5aee-4f80-836b-5fc9b99693f7	易食包	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:18.275159
943719b7-dcc0-46f3-8519-526875fc2200	大锐数智包装	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:27.217611
a107521e-cee3-4dae-9955-6dd590a0ea3b	汇利集团	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:27.217611
785612b7-06ce-4230-b2a5-d799164dfc5c	中兴	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:27.217611
9a3d81ff-a9a7-49ef-9031-291ea3c8142e	乐华塑业	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:27.217611
1396e98d-53e8-4d4a-9058-1d145e169561	跨越	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:27.217611
5e9ff9a6-8a9f-4937-ac47-1a80ab1e9f97	宁波时代	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:27.217611
b92885a8-ba28-4fda-bd3c-cd0d975e0c55	华康	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:27.217611
8afdfd6d-9523-41cc-9ea7-3da7d03cf97d	鼎诺包装	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:27.217611
b3b73845-3160-4d8e-ba3f-2190d2349a59	智优捷	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:27.217611
e7bae36e-c74d-47b5-a6c0-fa2c44e2232b	青天	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:27.217611
3d782686-b97f-42b7-be1d-3478251ea47d	金多丰	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:27.217611
faa9afe0-4a8b-495c-bdc4-82838cca12de	馨华和荣	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:27.217611
0c22b794-88b9-451f-93dd-ef9b3322f3ab	诚德	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:27.217611
06feda79-7b9f-45b9-8dfb-53fa8dec552b	其尚包装	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:27.217611
4a5f156d-dd83-454c-8b9b-0797f0b2ce1a	泰宝	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:27.217611
970b4b3e-fc54-4856-a602-1391aea3a44a	东泽控股	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:27.217611
d8561e13-8a30-408e-8386-4092c63f2124	量子云码	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:27.217611
0df002fd-bb18-4359-b69a-8a33821ac9f5	卡乐包装	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:27.217611
c42c663c-50c5-4061-97c0-d2c968302820	正昌宠粮工程	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:42.030608
04d41e9e-519a-4b58-9080-9f44d4771200	吕工机械	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:42.030608
8327032f-aa0f-4180-9e32-889543892b19	大川机械	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:42.030608
6f46b8fb-5ceb-4516-b5e5-d4ab7ed70a44	春秋食品机械 CHUNQIU FOOD MACHINERY	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:42.030608
a6f2b22f-e8ec-4917-bf78-bdb9a689d6d2	百越达	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:42.030608
53294df8-562e-452e-96a2-166d192aa6f7	汉普	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:42.030608
1357059f-60fc-48c6-b53d-9797c6ac183f	布勒 Buhler	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:42.030608
9c11fae1-fb62-4c20-94b6-cae7e85dd980	弘敏智能	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:42.030608
5e4171e4-cd8b-4da2-ac1c-981706f6f3b9	丰胜 FAMSCEND	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:42.030608
cf0ae0af-7083-44bb-8dcf-3ef7f4c0dff2	晨圣链网	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:42.030608
f8445981-21fe-4fc9-bec0-84f3432f7a17	鑫吉祥	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:42.030608
082a2066-3d86-4b88-94ff-482c6c9d3fc4	多科 Dookoo	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:42.030608
08b9a548-d5c8-4d79-ab22-bb0343fe7013	成瑞	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:42.030608
341b1b01-6dee-40f0-81a6-0b40e19fc18c	翔声智能	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:42.030608
381f4e56-55bd-4478-b95f-ca04451fde11	欣大欣	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:42.030608
47481e66-c9be-4fc5-89f0-61f396b8ed0b	龙韵祺	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:42.030608
7252fe28-8957-4058-b309-38efd8def219	山东真诺ARROW	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:42.030608
1344ccd4-3493-403e-85b5-b9775aaf9924	豫吉	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:42.030608
442c3dde-ee0e-408c-9ce7-b49ad5528429	太易 TECHIK	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:42.030608
fdc20a65-379f-4965-bb35-8d407ea02df7	科润德	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:50.489381
d3aec9af-3795-43eb-8d9e-6901b558eae9	晓全	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:50.489381
19a20f95-2278-43a8-bfec-577fb66b333f	鼎泰盛 DTS	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:50.489381
fe71f2a1-cb54-4745-a320-68caf5f5abb4	润立智能	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:50.489381
48d8d3bc-d370-4900-8b40-4fe54c97dbd4	英迈	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:50.489381
e9175cf4-6e71-4a99-aef2-cf3b3b1f633d	宇笙	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:50.489381
59a3d0b9-dbe7-4d1a-8f9c-e928b59728db	义龙	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:50.489381
6fc2583f-c8b4-4223-b563-811c993d4fe3	灵璧商务局	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:50.489381
7f33b900-fb69-4a70-bffd-65d973f2068c	捷讯光电	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:50.489381
ebdbfe0b-9181-401d-97b9-034210f837b8	宏锐	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:50.489381
99e09250-d234-4f0d-b4c0-e6b3680b2ce3	CPM	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:50.489381
839a7848-efcb-492b-881b-9d3219405caf	步琦	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:50.489381
432e2392-606f-4c47-88b5-8ade3c688936	法斯特	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:50.489381
816acc73-1c69-4a26-88e6-4b0a5e9149aa	天润工贸	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:50.489381
05a421bc-2141-4e19-8007-bdebe1cb4ac2	鑫盛链条	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:50.489381
7a613fc8-f725-471f-803e-0c063fed46c3	唯艺	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:50.489381
20d2594f-3a5c-4106-b655-c34a01cc8b4b	天华塑业	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:50.489381
80f10f8b-e2ee-4356-90a8-830d3305704c	华氏纪元	\N	\N	\N	\N	中国	\N	2026-08-08 15:38:50.489381
4a8f5190-3e8a-4c3c-92a8-15477005366c	疯狂小狗 CRAZYDOG	\N	\N	\N	\N	中国	\N	2026-08-08 15:40:34.912764
147081a8-f93c-4b69-897b-cacfc3542d8d	诺和	\N	\N	\N	\N	中国	\N	2026-08-08 15:42:29.151145
322e5d0a-b89b-4caa-a653-8a890d4b892b	杰人	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:38.406222
f3564d90-15ee-4b25-b531-a48056ca1d78	Biocorp	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:38.406222
b5c8da1f-36d6-4d22-a770-3a76c137bcd2	超悦	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:38.406222
c3db5221-30f0-46a6-9ffd-008f421012e0	protia	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:38.406222
869aa778-cc3f-47a8-8a07-2606b21e7029	阿极宠	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:38.406222
7c508a2d-046b-4f01-bbc9-b1ffa94db222	科瑞特	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:38.406222
32155225-69f5-49ea-947c-b899a4f8fb6a	东典	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:38.406222
fa6f4976-a179-463b-aa13-a4a075186421	益远	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:38.406222
b94fa46f-859c-4bd2-b77c-11dd3e5f1aac	乐派	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:38.406222
ae56ae16-efed-44c9-bfc1-d0e5efaf7c07	三只小猫	\N	\N	\N	\N	中国	\N	2026-08-08 15:54:30.742445
9d8c240c-8f16-42e9-afe1-1a92622fd2e1	文博	\N	\N	\N	\N	中国	\N	2026-08-08 15:56:01.260413
25d8b29d-9ea3-4b3a-985a-335f06079379	吉咪	\N	\N	\N	\N	中国	\N	2026-08-08 15:58:08.847984
4196b6a4-cc26-4d5e-9207-95493eb0f618	派派猫粮	\N	\N	\N	\N	中国	\N	2026-08-08 15:58:08.847984
0858fbaf-cc22-42dd-b791-5c92fa6fc728	思宝	\N	\N	\N	\N	中国	\N	2026-08-08 16:01:15.097709
b834b576-24a7-4e67-93fa-15a1e06e1d4a	广东铭康	\N	\N	\N	\N	中国	\N	2026-08-08 16:06:16.498295
4fde17e8-6113-406d-a26c-7252ea76d6a8	洋工 YANAGONG MACHINERY	\N	\N	\N	\N	中国	\N	2026-08-08 16:06:37.578755
1aa33e03-59af-43bc-999b-08f8373f93eb	长乐健康	\N	\N	\N	\N	中国	\N	2026-08-08 16:07:30.45291
94515b92-c530-4904-8e47-3a29e9eb785b	新一深视	\N	\N	\N	\N	中国	\N	2026-08-08 16:09:10.990037
4086d490-da84-4624-a836-31ee57dedd89	Kashima	\N	\N	\N	\N	中国	\N	2026-08-08 16:11:20.733916
79b29f2d-1827-4d12-b122-7d613af4b527	同食	\N	\N	\N	\N	中国	\N	2026-08-08 16:12:55.06869
4f5f8950-7561-46e6-9b00-1f7e3d1daf52	相生之宠	\N	\N	\N	\N	中国	\N	2026-08-08 16:14:46.49529
2d8f51cc-017c-45c2-ada2-18339496305f	普润	\N	\N	\N	\N	中国	\N	2026-08-08 16:15:05.947664
0561e42b-da5f-4012-9e12-ce3370d952fa	海尔 Haier	\N	\N	\N	\N	中国	\N	2026-08-08 22:26:36.979191
8811cd07-c6c2-48fd-a434-4c20633f5db2	霍尼韦尔 Honeywell	\N	\N	\N	\N	中国	\N	2026-08-08 22:26:36.979191
98929965-2b96-425f-9900-45ea51c868c5	Bubi	\N	\N	\N	\N	中国	\N	2026-08-08 22:26:36.979191
9005357f-38b2-40fc-b929-5a49c5ceb091	华强立诚	\N	\N	\N	\N	中国	\N	2026-08-08 22:29:45.122241
ba15e636-1aa3-42b7-b76e-c7e74d67c5d4	丰德嘉	\N	\N	\N	\N	中国	\N	2026-08-08 22:30:11.123535
643fcbb8-95b1-4311-b67d-76a6e7766b70	Knotia	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
cfef58e7-f673-4c6f-bc09-28dd88a448c9	Nooké × 萌指数	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
dd5c5120-4368-454c-822d-65a29b9f110c	比亚迪 BYD	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
94b9d5fc-d41c-402f-a1ea-bf674111d948	艾踏 Artes	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
9062ed09-3452-43f6-873f-753b3e72467c	DAQQAB 德克泊	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
c21603ff-ebf8-40cf-9235-ea73b976b7df	KICA	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
6a54375e-d52d-458d-a350-a8b6b9a6a4dd	安拓浦	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
cdbdea05-d1f6-434a-91ad-b672147ce3fb	旺旺集团	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
3f853009-c92c-4112-8b1f-da97b2dc59df	PAW DREAM 爪之梦	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
740f2e07-ff05-412b-864e-eb1098bab662	派比智能 Pabbi	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
d77899c0-373b-46c3-ac72-a7f26a2b01b4	圣晖电子	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
c84c8593-9f44-44eb-8262-b10a0652212e	宁波麦艺	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
9a34cd18-1eaf-45a1-a33b-91cee5b991ef	小宠科技	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
1f4ad601-4988-4b75-855a-6a462a1d248c	尚银	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
776aa50e-649b-45db-b678-0092777ddf93	来旺兄弟 L&W Bros.	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
fb1c9ba0-6433-4672-91f8-6549a9fb4768	喵星公民 MeowSC	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
76e0867b-b1c8-489f-adcf-a8391e62e14c	持创 Chichuang	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
fb2631c7-7f8a-48f4-9bd5-bc318067d0e7	Jirpet	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
355ab9a1-ac0a-47bf-a642-db29c2652580	佩特萌 iPETMON	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
d823d21d-9295-490c-b503-420f72626eca	多尼斯 DOGNESS	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
fd7ecbec-41cc-4155-8ce2-237cdd853cc8	浙江朝泓 ZHAOHONG	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
440f7967-651e-45b8-b981-619f7df7a9b6	峰亚电器 FENGYA ELECTRICS	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
bfd89ee3-a8f6-4082-8bc9-259f58f7096f	兽牙好美	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
fa99a887-c900-432c-a83f-c847778bb1a3	德米电器	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
e61cb636-0c98-4402-8865-97b00904bdd5	美扬电器	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
f13e0ad4-3460-443c-8846-70fba707926b	宁波佩特	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
768ad3a8-b064-43b8-b887-9d218ece4d72	康派温	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
c8baf1f1-450a-4aaf-9437-8e11b080fd98	BK	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
6aba8516-f5d1-4dfd-a038-8c0f552bc1bf	彼得宠	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
4c3cabd1-48c9-47f8-afb2-d123c6672bf5	宠悦悦	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
b92b742f-ca33-48c2-a2a9-5cebd43e80a0	美艾斯 measepet	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
6bf97453-191b-4c2f-8137-697be346754e	小壹elspet	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
99f6ea06-e9fd-4a8a-b24c-6f88cc250a6d	雷龙 Lelopets	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
6c104dfe-27b1-40a1-919a-8da18330c8f6	苏州盛康KUDI	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
994ff117-c6cb-4e74-96c6-ad0dfd596a07	优得顺	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
6378e8e4-edf8-4eb6-bbdf-13a5c680452b	优米迪	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
556313a9-e823-4eda-810b-f7d1507a09a0	志逸鸿	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
9f8d77b1-0446-4e07-b973-b220969651b7	迈亚	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
5c11dfd7-d993-4d39-bdef-3989283eb5aa	ELSAMILU	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
9f2ccfcd-3c35-4229-bc41-1cbe89b6b2e5	MoliBoli 茉莉宝莉	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
3a87b6ee-6fbd-405d-9253-0a0984040a64	维他纺织 Vita Textile	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
aa5dbb53-fad8-4844-a5a9-42c83709d98c	宣城宠爱	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
35e2232d-773d-445b-92f8-17b3fcce33ea	奇滨	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
fea8e445-b1a8-4be1-a599-5baefc7aed77	苏玛仕	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
85bacf4d-8a06-4e49-946a-0257d2a485e3	恋宠	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
f15a8b02-f96f-4642-a1c7-b64e9475a292	拍拍工业	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
7a862862-d613-4bfc-bf51-77d7bf0f190c	惠尔美	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
114f6ad7-e62e-4a82-97d7-ba08809408ed	郅泰	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:04.988224
fd2934ed-b367-4742-981a-bc0d1a96a258	Uppapets	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
ba1dafd6-24e7-4b85-8289-40836360b3bd	pettrip 贝途	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
36e179e5-3cce-4014-8e2d-7064451c75f9	愉悦	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
cd667f1a-fe45-4cd5-a2a3-fb53918468c6	汪酱 幼稚园	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
84872c8f-b779-413d-b5a3-8ae330c59322	Dobby's Dream	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
0b96902f-6384-42c3-a810-22507170fd76	PalettePet	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
08e00dc8-903e-49b6-b933-78af85339025	恒嘉	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
c418134d-7cff-4390-b421-e0e71cc448b8	Bebe Faith 贝贝菲斯	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
4fbfb5a5-0905-443e-b58a-93138409e1c3	易泰宠物	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
71a8a590-18fb-4da6-b54a-608bc2eb5996	华旺 huawang	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
242b0584-c1bf-4d08-b6cc-a9236eaaf1bf	FaLa Pet	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
5793d111-00be-4b0d-be46-f4dd85cf5413	babynight	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
5d8e3b95-a7a5-437c-b828-80687287ee07	聚乐派 大方	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
4fb05419-3060-447a-96cd-b86d0d4a4821	kiyott	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
3b1eccc7-857c-41de-9573-b7ffb500126a	青岛唯宠	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
cd1cca7c-93a0-4651-8c9c-db5408cf4374	乐运宠 Lucky pet	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
f191a953-55b7-4a14-a07d-de97e2221056	宁波爱可宠物 Aicoly	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
040c74c2-f32d-48f0-ab72-d438a416a9e3	金艺	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
38a76c3f-16a8-4ca4-bab7-9e3f6f0f1686	REBACCO	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
ce0fe9c5-a430-4daf-bf89-acfbb538fb6c	Bello	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
866e31e6-f606-4030-9e3f-b07c9f327f14	舒兰朵	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
39e038c3-dd03-492c-9c8a-07606317de42	森烨	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
c1d508d6-772c-4aaa-b262-4af3c9685ce0	塔拉蕾	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
4cc3beb5-8014-4036-a123-acb9d760d6dd	小谷粒	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
1bc0d5b8-26af-4505-aa2e-f93f44a19b83	ParisDog	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
1c0ca79b-dbc6-474a-ba99-f15d1208937b	特鲁 True	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
127bb6c9-d0aa-45f2-ad01-82b8e0eaa072	Z.PAW	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
fcdbc96c-db57-4967-9837-6610545b581f	汤尼熊 TawneyBear	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
d47f2190-bc61-4d93-9f82-4dc665b79238	BORORO	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
7eebdbfe-3b33-4c9d-84ed-baf99200adcb	萌御 PETMAN	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
68a3f9c2-36c7-424b-8df7-2e049480480c	P.PET	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
815b83bd-96fd-444b-8549-185eb9eeaa4f	Doggie Doggie	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
2683e2d5-9e3b-4066-9505-bdcc3efef37f	StrawBerry.Qiao	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
03f03920-06d5-420c-88ce-f90fefa29d11	URNAME O 你的名字	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
05bfd1f7-de6a-45bd-89e3-0d0b6906388b	福福宠物 FUKUFUKU PET	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
8ffaa74c-03b7-43a4-95ad-50c4d35827c0	毛精灵	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
61213ea2-5cdf-437a-a5d1-fbaf0c309295	道哥	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
0eaf6490-4c28-4317-a8e1-2f4bec236f74	小狗力量	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
e7bdb1e1-72f2-43c8-bc75-22de45d9748f	简泊壹宠 JIANBO 1 PET	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
a28a7129-0236-4898-9f24-33568105efc6	拓禾 TOPHE	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
e67dbdb9-5de2-450a-a023-26b2c1ed3f4b	鹰宝	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
c13eb1ff-bc77-4ff8-aacc-f959c77a4240	博尔斯	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
068c7d3d-f75f-4445-b6f4-4f6617f65297	戴饭团	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
92d3835f-a579-422c-90ec-70fc2afce8bd	英莱儿 Ylier	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
9e6992d3-206d-42e5-b50d-827cfa8891d1	哈宠 Hapet	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
4b378fd5-d7ca-46dd-b9d0-8a11d755c4db	众云	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
247863c1-347e-406f-9453-bc00dc39bfb9	EDENPETZ 宜德士	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
3a2dd337-9b0c-4265-a9e7-d057a2cf9068	创创狗宠物用品 (DJJ & FOKWOW)	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
9bd3a0e3-2b4a-4853-b6de-e912322f89bd	班尼迪克 Benedict	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
15b93791-6a7c-4d99-9701-9e80b8e18a49	Hello Friends 幸福里服饰	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
2e1b66e1-5295-40a2-9a0e-a740225a550e	优贝思	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
44b44894-4442-42f2-a6c9-fd79d80b108d	COCOFREE	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
019a3c90-a71e-45a3-a9ca-b4934c058d6f	万喜达	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
8ebd103b-d633-496b-9de8-850e21cf614f	开天	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
aeca1ecc-00de-4216-9290-74c04654fd68	美真	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
899724a4-7d28-4c42-b609-1c405edc8989	三合	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
356629f5-dc06-48f0-88c0-e3d88ee8bdc7	天泰	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
2600e7e3-0da5-41de-a65f-52bb1da68eff	vivapeby	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
53a153c0-5197-49b2-a7db-e8c6ba846e1e	Autumn Bless	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
f901fcdf-df8a-4a4a-bbaf-fd087527db17	悦佰兔 YBtoopet	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
a359b379-130f-41c4-8f71-b39c9c82b381	宠阳	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
dca5c556-85d6-44b3-8e31-e428c6bfdceb	广越	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
e4e186f2-d60c-4ac8-8d4b-bf5cf463d152	乐菲	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
98b5f060-e41a-4418-b794-7567252ab61f	比克斯比	\N	\N	\N	\N	中国	\N	2026-08-08 22:39:59.374219
f14daa9e-4eb0-4eae-8430-3ae35b3fe410	鸿鑫宠物	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
5143c5c6-df10-4019-b21c-ad8d1869e411	宠米特 Chongmite	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
6b5a6af3-d0f5-4a3a-918f-9ea16c77099f	润正猫砂	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
ee942160-d78e-449c-bfe4-c6c5562fda75	平瑞猫砂	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
8ae003a7-8973-4f70-b72a-9f39657ff78a	恺特派特	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
76394d81-4c46-401a-8e66-ba59eb0771c6	上海宸漫	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
4d82b4a9-76c0-4949-a40e-6fadb8a80f67	吉吉猫	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
15af8b04-c6e9-48d1-bcbd-7983b3a4aeb0	海森 HAISEN PET	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
d307b14e-a120-41ef-88de-9118c0cb9b4d	益蔻	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
1d16c5f1-33ed-47e7-b27b-0aca10e982fc	漫喵	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
bcd8b0e0-1d5e-45b6-bf3e-e23b41330413	脉特宝	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
905424ff-309e-4932-b1fb-975f6c7b80d3	纳米萌宝	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
acb75315-9b93-4cb1-ad77-b8db879aea27	它帮猫砂	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
ef03b8d6-ec9f-440b-94f2-b33d2adadd44	山东猫砂	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
a9c214e7-aa70-4f46-959f-7c201e92b639	卡咪奇	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
74547132-3ca2-47c4-b3a8-03f908c64781	喵特	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
2378155a-867d-4fd0-8d76-7e19aed52f73	山上动物	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
08ebfeba-e169-4456-9dbc-e221a51a2533	上海坤晟	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
f31fdbb1-b4af-4c5d-b01a-265712820a86	聚宸猫砂	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
440ff1c5-d186-40fc-8f97-c8d086361068	柚卡 ukor	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
22a38a06-2cbb-4569-a8a3-ee949ef7d80e	沃贝儿	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
34a8d32a-c722-4bba-bc3b-af488afa8db7	凯趣	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
1b9123f5-a6d6-4801-8c50-482fc8449773	中凯	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
c9faff7c-1f5a-4f9b-9a45-765fe919e837	環威科技	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
f5043e90-adbd-4510-b480-c795349c3d4e	梦丽雅	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
46d7feea-dcdd-4ca0-a0bb-2e9df97e4ee6	宠悠然	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
626ab1a9-2d5d-4b5d-a437-5d2c6c789c96	奥正	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
14f2bccc-ad73-471e-ab4f-a6a5ce4b8f07	诺高	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
f8c6aaaa-31ab-4686-ab71-00396b9de1a9	蒙宏新材料	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
b4007a02-9a13-44eb-b630-c72d7ade068f	极护	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
789d387d-3310-498c-9890-dcea863dfd1a	中诺	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
c32469a1-5773-4fb3-9199-376bd243a5c4	壹宠宠物	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
029b50db-17d4-4e2c-b95a-3a3b5bd19d99	臻垣	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
4bc50a06-8724-4ce3-b08b-8180e969c44a	思宇星	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
15bb1046-fea1-4ec2-9917-4b63aef25a0e	安静剪刀	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
276fc37a-5176-4b20-802c-c46a7b90bd4e	炫酷	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
e0c0cddc-b81d-427d-b5cb-5bdc3db7443b	云鹰	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
7e62c98b-828d-40f4-962f-3d97e9d1af08	达摩电子	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
fee0c4bb-1885-4ef0-b581-0d2ec148383d	喵尔代夫	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
18282109-9922-43ad-9e09-f9da9cd14e75	烟台美翌	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
f9aa1944-8269-418c-9383-9b589dc18fc7	旭昊宠物	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
3b982f74-907e-46c9-a449-b13fa94791a6	咪小豆	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
ef522fda-86fa-437f-b11d-dca47b602920	神士科技	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
f9591cf0-c29f-4d6d-8150-66d8f0e583da	瑞欣美耐	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
a45aad91-33e0-436f-a7f2-bae59b438a6a	喵乐趣	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
374a30d3-95b2-4c5e-be24-6567ca19c7b5	远丰	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
86890479-e1cf-4a88-badc-e31d0ac0b6c2	昇合	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
13fc35ad-7324-465a-8f23-8c377d1e5a38	硕吉化工	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
af6db0ab-07ec-4bf6-a8b4-e6a7199a4a4b	喵想树	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
9769aca5-1424-4511-a85b-05a286d9b5ae	江苏呜咔咔 WOO-KAKA	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
979ea289-b7fa-46ea-869d-d615cbc2d4c2	泰禾 TAIHE PRODUCT	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
21ae46bb-26fb-41db-b5aa-b98e23670b9d	星美科技 Xingmei Technology	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
7a35b224-fc78-4448-aee6-b17bb64917e5	爱宠跳动	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
3046d978-c0be-4f7a-a8c3-93cc89fddf9e	中盈猫砂 zy-catlitter	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
7d10893c-e4c8-43a2-96ff-b88b8467443b	源沐屋	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
4c656b40-7049-42e8-8cc2-439deecb7ba8	拜格斯	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
98237da4-3dac-422f-97be-62a37b19aa1b	辽宁名宠 Ming Chong Cat Litter	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
5c081ae1-108f-4e21-bc63-52560146814b	红姐猫砂工厂	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
bd5f7de3-3e0c-4368-8074-52f96a84a31f	山上观 SMILE TIME	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
fd11f9f3-cb09-45f1-bace-d1a39e4b1f6a	火星来电 MarsMail	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
079eb308-0fdd-47ba-a764-ec31b3ed1f94	腾尚	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
cba1f55d-d6f2-4c6a-8b78-19b8921ea5e7	沃爱	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
eda10d99-0ac3-491f-ad25-70426be89436	沐宠	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
ad5bd0a6-e396-4481-b265-0a315f998b4f	哼唧兽	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
4aaea2cc-b31b-4871-b178-3f92130edc2f	科乐奇	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
91462659-242b-43ec-b63f-9a4c5590a907	孩提乐	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
9acc3ef3-94b0-473e-92d6-d0352b7dd435	米它	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
fb3fd508-499a-4499-b205-405d0fd98618	宇宙狗 Cosmic dog	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
b36bfa2f-1d7e-4216-bcc1-3fdfe642d05a	千尺	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
faa84a82-6479-4a81-90c4-784c8c60f1f3	它说	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
f994686a-8150-48e7-96af-5e2b8f367312	申子辰	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
4c077f87-36fd-47d6-a68b-37206963c784	御峰	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
3092d903-c068-4198-83ba-49a7d2eb697d	宠莱	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
f1ba1f9a-ed67-4aae-a796-4cf9c04e7009	美尔	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
b0d02004-c96b-4ad8-a11b-32f604cfef27	比高	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
51cbc7ea-b792-4c4b-b971-8f552d6a600f	广海大	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
e26d3404-957c-460f-9fb2-f2d9a4d25907	它基金	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
6695be76-a654-4798-8ad6-315f93af4540	萌兽港	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
fb940d55-627e-4274-ba19-19e4a67e294c	而行工作犬	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
280521b0-b280-4e81-a5aa-b132e987b44d	启明	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
9f836b39-c355-4581-907f-f7551091ff2c	动福办	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
f6f11dc1-e98c-4264-b6b3-599fc7871895	九尾	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
ccfa83ea-7e9e-4eea-b98a-24100f4335c6	小豹贝	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
0443940e-b46e-4dec-8ac9-77a1f2a22dd2	华峰剑麻	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
ec411e0d-208d-4533-8965-d1fb90437ba2	魔术袋 Magic Pocket	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
eeb98205-b894-4441-83f3-4e3818231109	廊坊大爱	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
d6ae19b7-7ce4-47eb-addf-bcbaaf525d6f	温州飞恒	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
7496e755-82f9-4861-a873-8e77f51480b2	辰阳	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
db2c05dd-fbf1-42d0-aacf-657cf1a92958	振德	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
b767d9d4-7a17-4efb-b7f8-d41325fbf2b0	巨辉	\N	\N	\N	\N	中国	\N	2026-08-08 22:40:43.828621
7625dfa9-abd6-47d1-b9cf-d6a1bf9ef5a1	广州韧拓 NEKTON	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
bd7ee44f-f41e-40c3-a0fd-0d21ad683252	宠心悦	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
83decbd5-dc52-4e29-825a-d50ba8cc926e	丝络宝	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
ff29b635-693d-4541-aac7-971c6fea0312	开元 Kaiyuan	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
9907153c-26d7-4115-8ec5-39a04b666774	美好家园 Wonderful Home	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
f6f2a372-7f38-4dc8-a8c6-9f1329fafeb5	比利时凡赛尔 Versele	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
e5fbf79f-d6ea-4a67-bbbf-f144720f1f74	Gugi	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
67514fd1-79bc-4708-b069-9053be6bb7d4	迷你农场	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
cf0e17a0-3014-4c91-bea7-070f8dabbf27	高多吉	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
b882816a-6d51-48f2-8c86-4017432f7193	欧萌	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
1021ff56-92d2-4ab6-ac82-da2defa118f4	中正	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
594fd3db-0672-41d1-8afa-c324fd1a096c	Pet Metro	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
e6481ca1-3b78-4f0c-878c-be1e5aec057a	VETAFARM 兽医农场	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
7a0d1a38-0167-403a-b11b-e17abb84e402	手养日记 Sooyum	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
ed0c58ef-e44d-48ce-8462-2bc00465fba5	兔博士 DR BUNNY	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
285d2a57-f683-4668-ae36-190f87f6725a	怪兽盒子 petag倍泰吉	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
d3c81199-cb56-42cb-a4a0-61b5d8e64ec5	异界 AR	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
9eee2fcf-e763-4cf7-8717-72a8464c8cf6	宠尔顿 PILTON	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
05e8cb14-e623-424b-a9a1-83cf36a9e78e	洲游生物	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
ad0c842b-a68d-4794-b964-68ea9b547e02	极问 GIXONE	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
d2b1ff0b-f720-414a-9669-c356664382b8	宠物行业白皮书	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
0f288923-aada-4ced-9ca7-be1d64e30a2e	瑞朋	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
4275cfac-c38f-4db1-9a64-97e58d4a5062	贝依	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
d4d17af8-0bad-418f-bd33-79eaacedf13f	中海龙	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
16cdc4ea-f909-45ed-b2a5-3de20bec4378	游鸟屋	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
24cb0c4e-766c-49a9-a75d-d9580fdc1551	宠臻	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
6d96d58d-b137-4bb6-a588-90350d9ad818	方科	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
dbd2a4c5-eafe-4ffb-bade-a15016ac30cf	福建诺奥	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
deef47a9-1dd1-489f-b38f-edded940e704	欧洋	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
64c99387-353f-4ae4-9be2-ffc26f43a357	美泰	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
f9cdddff-9432-4afb-9c4e-1e8210d3a8c0	义乌智宠	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
37d16b6c-c432-4ea0-ae4d-c614ddc56299	鼠王萌宠	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
1fd78358-2a4c-4aba-904f-26f3c7a35c91	爬托邦	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
d2f439c9-4d7f-4670-9cf9-54ebf85ab297	小飞鼠	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
2fa9448d-3bcb-4f71-96e1-af3ac6110d6f	宠波尔果然宠	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
60716245-399e-4c4e-98fd-0dd4b3c1cb61	ADVINCI 达芬奇黑洞	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
42cfbea6-2bb3-40fd-abca-732921b858c2	泰祥	\N	\N	\N	\N	中国	\N	2026-08-08 22:41:37.68833
7fba3b6f-d86c-4882-94ba-feda48758d70	博仕宠食	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
44471a10-ca16-4bf7-b24e-c88f8ec04630	宠伊宠 CHONG YI CHONG	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
1c469ced-0c4c-42fe-bbcf-9af781e5019f	派丝芙	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
a79c304f-a372-4d9c-9103-2e7e013c234e	腾晟优宠	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
eb71a09e-4686-4637-afb8-066de4bd0090	朝辉	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
7fd0f6e5-db0e-4a86-adb7-c2f91a4bb961	华米	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
175f6240-8911-43a0-a20b-bb58034c6d76	鲁祥	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
e6dca863-12b5-4030-9afb-da732dc6cca6	新际	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
4b6b346b-5f09-4da4-8aa9-d55db670e0cd	九命台风	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
562d5853-3bf1-467f-9be7-a0d61d323a8c	冠能	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
29f47244-3902-440a-a3d3-f170f69d0cb1	鑫瑞昇	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
d0adfec9-7d5c-448b-917d-6f00e24fb042	卷鲜森	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
f17303bf-f096-495b-b838-28eda69e7e4c	山东宝亿	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
d452e592-9061-4077-999a-e0fd05498f66	萌贝 Reward	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
c2c8053e-8328-4f7c-9b52-d17018b4d0e8	华宠	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
5f65b391-8fe7-4ee2-90c7-29515a6cac51	鲜宠	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
748b1528-6fbd-4d9c-8385-7a8809b13709	亿达	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
442ce40a-9683-4d48-bda6-591a5e35146f	臻宠	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
a705e9d3-5811-4ac4-b2a3-142473d62da8	心宠	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
f4bb110f-164a-47c0-b597-db5e0e3ffd2a	汤恩诺 Tangennuo	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
f8ed3521-5f87-4759-bf18-455155c02b01	吉欧特	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
30d5a1b5-a210-4513-8e7e-7a0acf024758	乐佳	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
382288be-e628-4792-8276-5a88126c4533	好理想	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
cb90bd7e-6751-4093-ba59-2c40231d1a21	美团	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
8cd914f9-b6e5-4eef-80e8-91024916fc98	聚一富	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
bbba783d-073e-4d99-bdd3-2c625d8c8068	安徽玉茂	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
e4a9878b-85bb-431c-9cd4-436ccfc399af	富腾	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
2b101ec5-fe89-48e1-bc6c-203b3b60c62a	宏美刀剪	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
381b1b6a-3297-4443-82a8-f48abf59b83f	亿信	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
898758fa-4206-42a8-9967-7f41bf300d67	乐丰	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
cf7e33fd-3cbb-4118-909c-a24029fdf0b8	逸腾	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
793cdcb4-834c-4c67-8560-c73cb1a4c4f6	智宠未来	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
c57c5a20-df6f-428e-8c7a-bef63bca1fe9	宝仕利	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
59e66bb7-37b8-4297-a436-ccba63d4a836	潮州长顿	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
74a654aa-cea7-4e01-bef4-1788acea463c	美滔美淘	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
c95e3dd3-4278-4f51-abe7-7173ee376172	润东	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
6cbfc157-5cf7-464f-8b3a-74fceff8e9d5	宠堆堆	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
5d1be1de-eb99-411f-9ea3-25b44d96672c	莱恩迪	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
811cd4ea-a9e0-4dd0-a14f-dada4ec04412	苏旭	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
f1979c5a-7301-4b65-844b-ed91e04545ea	赛利得	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
31eeb961-d1e6-45a8-b95c-b43a7b16a9ea	福通	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
81d6b7de-b954-483c-ad99-674e269dab49	佰仕泰	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
e39b82d3-88e0-4af7-9d59-c6e2fae7aebb	小布在家	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
d1f1a23f-52b7-424d-b6a7-139204808b67	布丢	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
c8fa9274-44ea-42a7-958a-6887bbf6964f	徐大力	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
9e99f211-e751-4aa8-9d22-3752bad66f2a	兴达	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
b3cf940a-377e-4419-8647-f7aa3afe9892	Staree星宝	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
d1433e82-1173-40bd-9bc1-4d26cb094841	怡享	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
d737390f-c524-44c6-894a-0f22de0cb2ce	丽晖塑胶	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
d2e5428e-9c07-41a1-9a23-da10684086d1	久瑞	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
ebf1895e-6b6c-429f-8a16-2522951b57c3	大美	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
0e2e06f9-915b-4dc1-b5c4-5d909166c2be	鹤立	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
1f6b9629-9a50-46a0-baa2-3a0ded6278df	小潼	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
9b10a492-51f8-412c-99df-7aa1a10152a2	换享宝宝	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
6c4978e7-42fc-4731-8e00-5f3ee04e98ff	友客	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
3aa920f5-08f1-4dd3-8a5a-94d9a88f14d2	饮文宠物	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
c915ddb9-979b-4fab-bdaf-4c726857efcd	芭芭家族	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
c2c63e05-2536-476e-87a2-f30d24dbad39	朗蒙	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
866cfeb2-1098-441c-ae0c-33f17316cc14	洁美	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
425e4981-0fc5-4a12-a078-8d31e6a80484	豆醇宠物	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
f61bfa62-1bea-4686-97f0-db0c84462001	唯森特	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
649a94a5-208b-4b3d-a3bf-f77e61ac2aab	龙爱宠	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
fd9a1a62-9377-4d33-a400-6a829124e67f	迪尼 DINI	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
921c3e31-4263-4698-a280-b94aabb242fe	五季	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
67eb7347-cf6e-4073-9a1f-a26748eb235b	圣丰	\N	\N	\N	\N	中国	\N	2026-08-08 22:42:20.874612
7f2ae07c-3f1a-4406-aa12-a5116b01e11a	哆啦哌 Dora Legend	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:14.692416
d258aabd-851c-423e-a5d9-45fe70d221ce	齐康佰欧	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:14.692416
7959acc1-ec23-4328-b93e-d69ef51e73fc	蒙源泰丰	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:14.692416
1e89ccdf-0f00-4459-88b6-e994f54fb004	禾森	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:14.692416
bf922091-bb5e-47af-ac2f-0487d5ffff9d	山东迈旭	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:14.692416
181f3616-48ed-4cff-baa7-06779d4f1e32	华福兴	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:14.692416
ee4ac1fb-215e-483d-bc1e-543690c9af15	泰宠 TAI PET	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:14.692416
e1e03868-a0e0-40c4-99fa-fafc458d57f5	博宠 BOPET	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:14.692416
24784af3-208c-4a4f-9782-54dfd3e26c03	科乐宠物 keler	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:14.692416
f9fde43d-bf60-4477-8d36-e74ebfe141f7	皓泰	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:14.692416
c360c0d2-e2d9-477b-944d-8e625047807c	赛西	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:14.692416
7c6c8fc6-5d59-408a-a6c6-32bfb9b24476	中罐	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:14.692416
f8e33341-433c-4e71-9870-e19ebbbd5274	培悦宠物 Peiyue Pet Products	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:14.692416
0a3e1e2c-cf29-4bb1-8fb5-bcb5535578bd	福茂宠食	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:14.692416
0f61f47c-c6ce-4056-8d37-efdf170b09ba	云蒙谷	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:14.692416
eb4ea81a-242b-4802-bff1-4bbd984c01fb	汇聚	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:14.692416
1fdb51a0-22d0-457e-bfee-157fe6bfe4b8	萌宠冻干	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:14.692416
66604fdd-71f1-4ba0-bdc7-93e51041ab9e	妙兜 MIAODOU	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:36.047077
eabc257c-19a8-40dd-bd97-d84491dd6c4c	怪老板 GUAI BOSS	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:36.047077
150f999f-b421-48a1-8486-3babace17b0c	猫爸爸 的厨房	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:36.047077
cb722220-7443-45e9-844c-822d64df8197	好日子	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:36.047077
d7bd4a84-1979-43b6-8168-1c358270fce9	海伦阿姨的厨房	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:36.047077
6f2d70f7-a446-4cc5-b1db-8e3ace58cee6	一贯	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:36.047077
5745c261-32a2-477c-83c9-5b6085291b56	泰多乐	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:36.047077
a3d46115-4622-4ca2-ad77-994e2980148a	科宠	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:36.047077
27b0928f-0cbe-4bd4-b938-91db63266ef3	金球	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:36.047077
25fe61b1-a83e-425d-a9e4-b3060308a5bc	凯萌炜	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:36.047077
d9844149-8b51-48d4-aebc-d011b6d7a90a	太阳家 SUN PETS	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:36.047077
611778a0-0e61-4500-a597-ffc60dde0be9	丸味 MARUMI	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:36.047077
b1107702-7f7d-466b-b00d-ed187b5e7713	乌力乌力 Wuli Wuli	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:36.047077
376b098f-fbb9-467e-aba9-7ee18d9ce71c	Care 好主人	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:36.047077
60c685c0-8498-4aa6-8f7b-27cd04685b2a	鲜本源	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:36.047077
840b6873-fa05-435a-a0ba-c8cded1b1139	匹卡噗 pikapoo	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:36.047077
8a99fa5d-1c51-4fcc-93b7-04b8d5f0a265	信元发育宝 SINGEN	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:36.047077
d14d8b3a-b9df-46c1-8f00-3de853636188	御宠 ROYALPET	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:36.047077
1897b940-b8f2-4a46-9d03-c642d264da60	喵彩 Cator	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:36.047077
e010a9bd-9806-433d-a766-8b5d03d6fe80	高格	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:36.047077
2240f3b3-2f64-4ecc-8fe0-fe63ccf3d3f1	瑞吉	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:36.047077
d4d34de6-fd78-4810-9613-dc7f46f2fe6e	鲜萌宠物	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:36.047077
fc14f83c-a17b-47f7-8e84-6c535c4a923c	抖音	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:36.047077
2359db26-d7fa-41e9-8c39-217982312acc	Wagoo	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:36.047077
960c90db-7b22-4d3a-bbbf-b91fd388dc84	凡雪	\N	\N	\N	\N	中国	\N	2026-08-08 22:43:36.047077
e96c4c59-73e7-4e85-b18f-796ee79ce09d	小红书	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:06.622265
0f4dd34e-9b5e-4aa2-b6ac-1d73e2375dc2	ARTE	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:06.622265
fad100c1-4c72-4944-9f67-373d15493bbd	贵族 NOBPETS	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
1364c1fb-f401-4289-811c-6772cc824a5f	光明优宠 BRIGHT UPET	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
bf276268-2604-4568-90db-bb7ab850e128	有个圈 CircleCare	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
a9be960e-1054-4340-9996-0e7131485da6	澳爵 ALLJOY	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
85d854ea-0f2f-45f3-bb42-920718f5bebd	in 麦德氏	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
d6259f4f-7ec2-4633-a44a-a181a3f45c60	雀巢 普瑞纳 PURINA	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
005dd501-3b49-49bc-af6a-cb2827fcc8ed	海洋之星 SEA FAIRY	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
6db251df-13d4-43c6-8f4a-5f7d516d8b3b	倍内菲 Benefits -Countryside	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
ba03e369-1424-4254-9cb7-9dd7f8b523b2	简沫 JANEM 怪兜 GUAID 纯想 PURE	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
f7680d37-67a3-4cab-ae01-b4ca83f28cf7	心粮 MAST	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
121c88ca-c523-41ff-8d47-a2ed8323fe32	蓝氏 LEGENDSANDY	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
f305bc30-c9c8-4fc4-9ee4-60ae82cfbd93	珍挚	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
e64bb56b-9dd9-4c9e-b39d-79e413c0a362	阿卡强	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
e4d2ca83-b5eb-41a1-b5ba-551329d7c0d6	凯斯迪	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
f99c87c0-79f9-4199-9027-488f50c339dc	凤毛麟角	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
a1736796-b505-42f6-bb2b-e0535d1c87c0	腾讯营销	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
d791412d-1c8e-41da-8b98-5cf159fba502	爪爪印记	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
16dd6a99-cc38-4e40-9dee-17f2f8d8f349	顽皮家族 Naughty Family	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
f7a6932c-044d-4b06-8550-3340fd82be28	比乐 BILE	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
92c4a2d9-e516-4636-8570-0185f6ca6f3b	乖宝集团 麦富迪 Gambol Myfoodie	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
e3306c43-9d38-427d-9721-9a9b73df174a	约翰农场 JOHN'S FARMS	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
1179e997-302f-4597-9216-25eb7fea3a21	洛菲可 丸美家 斯蒂欧 NOTWO	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
035422b2-a500-43c7-858c-810188522591	可亚鑫德 KYXD petfoods	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
d25e7d91-306d-4f7b-8275-1c2b390de549	美斯 MISE	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
a2eb38bc-cabc-4ee5-acd3-99c1c5d059d0	亿点野心	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
95255749-5c82-4cae-b00d-74dcc57a3cba	优米可 Yumico	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
b015fc93-77b1-4f4d-bf7e-a1c64b7947ba	鲁宠协	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
58c51b14-7b44-4122-b8df-724b02c2974d	伴宠吉	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
0da4a4b9-70c5-4fc7-abf4-57a48db853e8	佰萃	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
d6dfa17d-713d-4ab6-9d97-6f1aa2e1c6e5	宠派猫	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:29.354989
b8296a8f-c6ba-4bc9-a738-eef30c69a923	爱巴克	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:47.285276
b316c2b3-8728-4b67-8856-745a3ae3d74f	6毫克+	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:47.285276
6f614cf0-b9f6-4f73-844a-656507b7b863	冠生	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:47.285276
43bbf8c0-9f70-4eee-97fe-2b6b083ec482	星时界	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:47.285276
efbb9187-43ee-4210-92fe-798ca5998f75	亚维纳	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:47.285276
d48bdb84-5c8b-4ed1-9e8d-f083f31f34d9	胖虎	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:47.285276
811ecdc8-6974-414c-9d5f-788d3cfca291	艾尔 Aier	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:47.285276
d6403389-0341-4809-b29f-a9354d1f8dd3	鲜朗 ROSY FRESH	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:47.285276
ae7d4e2c-e410-4eac-9d71-b58e6dbc36e7	鲜生纪 FRESH ERA	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:47.285276
23a55b37-0fc0-49a0-a561-c12fa21fdd5d	亚鲁特集团 YALUTE WOOLF/久生	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:47.285276
d8b78859-b195-475b-aa5e-49d8251c0f32	金故	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:47.285276
3a275f0b-9ef1-4734-b06e-88b72c6b231b	派得 pai de	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:47.285276
c13209f2-8f7f-4612-92cd-d2d67677d51e	加西亚 & 耐思科	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:47.285276
0ab967f2-e0a6-4baf-a899-7289f025260f	简粒 Oneness	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:47.285276
e1063bd3-c078-48bb-8d03-ab830a25637b	科盛	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:47.285276
fa58d91d-0f8f-4606-b957-676ee99cb25d	哈尼	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:47.285276
8fd37cc1-e1d0-4949-953a-87ffb6a5631c	哈茨	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:47.285276
4a2dd76f-390d-4d9b-9af7-005ce0d9797c	诚实营养	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:47.285276
589d6ea1-e890-4222-8131-b64dd8cf9ace	伯宝 BOPA	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:47.285276
f24eea47-d4eb-47fe-8a9a-87736e503c74	益伴	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:47.285276
3993caec-c024-407f-af1b-db432fa49de9	萌太奇	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:47.285276
5268415d-f150-48a2-bd92-60268adc5a90	中鲨 JOINSHA	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:47.285276
110cfc95-caa8-4099-9993-9f712e7d5470	纯福 CHUN	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:47.285276
44928b43-ea52-41a8-8fa2-b51720c8b80f	如天	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:47.285276
1f33ccb7-6330-4ed6-a8b7-3de60d0b5afd	OMARURU 奥马鲁鲁	\N	\N	\N	\N	中国	\N	2026-08-08 22:44:47.285276
d48749bb-3836-4fda-bb90-c7ce697ed5f0	DR.VET 唯特医生	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
ebf76dfd-b950-4913-b489-d940d6846aa3	华宠生物	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
493e10e7-68d3-446d-a153-f9cd1b6bf2f1	DOLOSH 都乐时	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
b5febd1b-3c1b-4bb3-a34e-b3180224db2b	佑多萌	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
87f09e02-f65f-4266-9926-2f3f32bf3ab7	迈瑞氏 iMolly	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
1ce3d693-dc91-4afa-a838-47b1bda85dde	Lander1 蓝波万	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
23701436-5e69-4dd1-92b0-53ab3fdf7e84	cdVet 施德维特	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
eb8da495-b290-4306-b646-178020415577	中科宠爱	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
2bf8aebf-ee6f-4696-bb7e-4754e257297f	大威宠&宠四方	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
1142a2eb-c499-4f5b-8bdd-91889a6b2c7a	礼蓝动保 Elanco	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
6db98ab2-3179-49d9-a508-36441d3fafe1	众安保险 ZhongAn Insurance	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
123fa684-7046-416b-b5c0-ac7f029ae92d	洛卫家 lovidovi	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
ea74f7bc-2d0d-40ad-9dea-659333e723ec	强生宠儿	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
f67799e1-7653-45f6-aa36-4e893c3dfda0	粤朗小宠	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
3cae9201-30ab-4c3f-a545-ae4dda90bbfa	犹乐仕	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
0ea1c947-d991-462d-ab56-e22396c1380f	景隆生物	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
c4e9b84e-d893-4063-817c-0bf0c315debe	伊尹实业 Yiyin Industrial	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
bbd5db62-0574-4c65-9eb5-d451c1dbb731	宝来利来	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
1084e3c2-91f4-42f0-9fe7-7967655a3abe	威曼	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
37b28781-2262-47db-91f7-ed03672da4f1	尚爱嘉宠	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
d5d2f139-04b7-405c-a715-82f3e882a10e	星帮尼	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
d15dc737-26c8-48c8-b159-1c5d64350736	杰特贝林	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
cec66d8d-229a-4967-9b0f-98e2a79022b5	宇晟	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
012dc114-8fa4-444a-af12-bd01e7ed73ab	兴宠伴	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
d8dc1c85-b839-419e-a2be-2bb9b081c231	澳滋麦	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
fc76d700-f2fc-4c7f-9a2a-2bc306b1c77f	赛安芙	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
0f68ff2b-9590-4860-a52a-1250a0aa9455	半合生物	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
169b779c-5a45-4481-81ab-13adfbc679c2	酷宠冠	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:12.615882
0231060a-7511-4a7b-9d4a-7e4fd8dce7b1	奥奈 Aonai	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:38.406222
09739d40-a452-4419-a0d3-df6545efe8c1	CHARM 野性魅力	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:38.406222
173d307a-7e6b-480f-991e-bd905dffbe78	爱喜雅 (AIXIA)	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:38.406222
4130722a-2c0c-45fd-8d5a-ef89c8173998	Dr.Clauder's 克劳德医生 Vitakraft 卫塔卡夫 NUTRIPE 纽萃宝	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:38.406222
3635c969-a7dc-4b78-b174-b5960b860e4b	APPLAWS 爱普士	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:38.406222
f1ddf06c-e738-425b-b8dd-a7ec935f2d55	Hazelnut Island 榛子岛	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:38.406222
b55cc881-c7a7-4891-94c0-4a1d05871bdc	YD International	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:38.406222
3448f255-fca5-4465-b95e-2007d387d0df	乐芳希施 LAFANCYS	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:38.406222
4eefc275-44de-4f57-a1a0-84e6f6352da6	Puff帕芙 Elato杜莎	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:38.406222
c0433ae2-723f-48cd-831e-82d3b8806086	Kit Cat Altimate Pet	\N	\N	\N	\N	中国	\N	2026-08-08 22:45:38.406222
374ae9f4-8dc2-4c8d-a9a5-d8f4b0caa3b7	Pet-Nutrients	\N	\N	\N	\N	中国	\N	2026-08-08 22:46:20.360543
536a20bf-dd49-4f64-847d-3e3ddc8da5b9	NZ Pet Foods	\N	\N	\N	\N	中国	\N	2026-08-08 22:46:20.360543
bc107bd3-c1a8-41ef-b9f0-faa62a0ca1c4	K9 Natural	\N	\N	\N	\N	中国	\N	2026-08-08 22:46:20.360543
84dd91cc-4c04-4a70-bb2a-699bb9bcc45a	PASSION PET(GROUP)	\N	\N	\N	\N	中国	\N	2026-08-08 22:46:20.360543
422b19c0-56c7-479c-9c31-d1b81a7a074c	CHICKEN SOUP FOR THE SOUL	\N	\N	\N	\N	中国	\N	2026-08-08 22:46:20.360543
723d08fe-a929-4392-b710-4d6bc91d8806	香港威龙/WELLON	\N	\N	\N	\N	中国	\N	2026-08-08 22:46:20.360543
e8c26a03-d230-4765-b462-f89bc71f927c	SWEEPY	\N	\N	\N	\N	中国	\N	2026-08-08 22:46:20.360543
d5c5038e-a5a9-4555-95eb-f36e18f3f5f3	JLCNT	\N	\N	\N	\N	中国	\N	2026-08-08 22:46:20.360543
bb7aa3ec-e70c-4f80-9bbe-8fed6041b8c1	BOONDOG	\N	\N	\N	\N	中国	\N	2026-08-08 22:46:20.360543
2990e91b-00d0-411c-9c1c-7268ae8430bd	小红书电商	\N	\N	\N	\N	中国	\N	2026-08-08 22:46:20.360543
710c10d3-e2eb-4818-8faf-233d2c017e15	Nutrisource	\N	\N	\N	\N	中国	\N	2026-08-08 22:46:20.360543
cf46b4b0-a88e-495f-a4f8-2d9f41251d3e	狮王 艾宠	\N	\N	\N	\N	中国	\N	2026-08-08 22:46:20.360543
345d110a-b610-47df-8ba2-b42fc4ce2065	BUDDY BELTS	\N	\N	\N	\N	中国	\N	2026-08-08 22:46:20.360543
e5333b5f-a898-4316-9756-d7e4fc0178c6	BARD	\N	\N	\N	\N	中国	\N	2026-08-08 22:46:20.360543
f9d98f89-958c-45f8-8e41-adb57f5dc61e	商贸配对区 Business Matching Area	\N	\N	\N	\N	中国	\N	2026-08-08 22:46:20.360543
369c9389-0ca7-479f-91ae-706387c1c582	赛傅生物 biology	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:16.418027
eadd7f14-0b5f-4a96-aee2-64de142e027e	京元瑞环	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:16.418027
fe243162-2726-411c-bece-3f39a62c9875	科碧恩Corbion	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:16.418027
cf042afc-b69d-4f0c-9682-e3e98c22d025	鼎兴	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:16.418027
061b0dd0-4700-4e82-9c90-55f22a174774	南宁庞博	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:16.418027
57221813-e30d-4d2a-9e80-8487bfd41ad4	银沙香料 Silversands Aromatic	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:16.418027
407d3bc5-a52e-404d-9345-3cef194c6e52	康普生物	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:16.418027
e47c0161-eea3-4564-82ea-51a15a12e8eb	辉大蛋白	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:16.418027
aa741d12-6953-436b-8b0a-f73c0844f3da	乐萌宝	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:16.418027
d9859e99-896c-4ff0-ac85-e3afd6293325	河北嘉蒂芬 (西里西亚)	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:16.418027
b3970e86-33fa-4eea-aaa9-0f5918c016a5	圣康食品	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:16.418027
362655e1-2242-4925-9cd4-13e2b0f4f124	上海沛愉 PEIYU	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:39.091316
e666e89b-ea4d-42bf-8a14-dffae9287067	数部 Shugao	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:39.091316
12eae158-9fdb-4a79-a23e-adf5c791d4ff	思辟德 SPEED PACK	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:39.091316
bfa30c88-a3d9-43cf-bbde-7449f5192468	上海石田 ISHIDA	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:39.091316
95c644af-2c76-4707-add4-a2b6e1c2a6e5	本优 Beyond	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:39.091316
463ff38b-ba67-4b2d-be9a-85141b16052f	大川包装	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:39.091316
32fdcd15-eda9-4197-bbc2-73daf9abab3f	双龙 Shuanglong	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:39.091316
fded94e7-865c-4859-ad20-fe6e6309d5e7	上海古川	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:39.091316
f04e9e01-aa06-4565-a98f-1baa6e02056d	微现检测 VIXDETECT	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:39.091316
5874d57d-f03e-46b0-aaa7-be8b4f4de1c4	晓进机械 XIAOJIN MACHINERY	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:39.091316
bb0cdfa2-6af5-47e0-99b6-78ec782ca010	梵歌智能	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:39.091316
c928b187-7e35-456c-845f-e6666085f471	祥海机械	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:51.653387
a790cf49-5dd4-43d2-aacd-cd7565446f33	汤姆森智能 Thomson intelligent	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:51.653387
cb2dc024-244c-40f4-b48e-97214319eca1	江宁机械 JOINER MACHINERY	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:51.653387
6a106dcf-7744-4de5-aae8-17c4d2333aae	纳诺智能	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:51.653387
68806352-fe80-4c75-ae8e-edcde3923fcf	无锡意凯 YEKEEY	\N	\N	\N	\N	中国	\N	2026-08-08 22:47:51.653387
d2ffa0c8-edd8-4bfc-a160-53f23e884c5a	望文包装	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:03.354262
fed17bd6-5f8f-4c3d-b328-c5f31782138b	青岛鑫凯顺	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:03.354262
7befcaa4-c007-4b28-9929-7cc4a2011375	海牛	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:03.354262
6ba5d183-bbfc-48f2-9cf9-9203cbc8901e	高密佳怡	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:03.354262
d995ab7f-1d75-468f-8ec1-5ecbb30ebd92	天惠印刷	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:03.354262
94017da8-761d-4d7c-a559-650949111870	创屹包装	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:03.354262
fdbf6954-f930-43b1-b91d-de80a10cd837	路腾包装	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:03.354262
8420cc69-19dd-4adb-bcf2-a1f10d548817	诺亚迪	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:03.354262
726208c0-835c-4156-aeb1-c7b26ef04443	余姚瑞达	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:03.354262
48cb618c-0536-429e-a391-2692f7a62332	鹏宇包装	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:03.354262
300d77ee-4268-4b4d-b190-f8fa52533e68	印得高	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:03.354262
34ad6967-b902-409e-b43c-a400946eb704	汇多多	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
79de0f8d-c46a-4eae-b15c-432e10eddfb4	小胖子	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
0aa09c8a-72e3-4308-9697-da3bf4759605	翔胜	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
196b880b-92be-461a-9071-f6c9ede50749	KISSGROOMING	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
9a296a49-33a2-4b1e-9129-4668fb1bcedd	泊艺特	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
191b58cf-f955-49f3-8f05-1d03898a96e3	优瑞 URey	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
e39e0275-eaa1-41a3-96e0-6634d3fb6713	畅沐-希伯艾玛HeberEmma	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
b116c8de-a09b-474a-bfa5-40cf75ba935c	郎之家	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
756e7f30-1d81-4f29-8494-2bc2fb305d56	翩翩	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
514bce1f-e1d2-4ff0-b1b1-8236c7f33392	山东喜高 - 爪墅	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
2b7e0c0c-566c-44ce-99fb-9a318623cb96	爱鹿 ARRU	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
337a680d-0965-45d6-a7d1-81d60e1bab80	中美日化 WHARNEY	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
dd534328-ece0-43bf-af31-233c5e914b0e	山东百合	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
41c25b5f-6158-43a3-96b1-8e22d39e2baf	扬爪 COCOYO	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
5ebc3c79-2dd9-4003-8260-9907f2319869	雪貂留香 XUEDIAO	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
fb4b0db9-7e50-45e2-af07-b0595f6b9e18	homerun 霍曼	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
cb4baa8c-db65-441a-813f-e7698bbfcd1d	艾尔法	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
14b55d42-775f-4f02-b0ce-ab942d09bcb4	善宠	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
bae212ec-6d7b-49d2-a13d-c82611652d2b	恒发	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
965bbc93-c911-49df-acd0-5310fb2e5e46	爱舒乐 doggodoug	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
16777e7d-b2d4-457e-8867-cffec72ef8bf	春舟 Chunzhou	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
53b23d6c-eb8a-4715-bdbd-92feeada3bf5	小盛大和 XSDH 盛合集团	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
b435712b-46a6-4fc6-833a-c6be65d89e88	城市理享	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
3e0c4048-b299-4601-b8cb-855bc6cdbddf	吉常宝	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
f5641d50-297c-4d06-82fe-bb833cf79e87	福丸 FUKUMARU	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
493e3d12-a54d-4fb3-b5b2-29ea0f8943e9	多格漫 DoggyMan	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
633ec002-b4f0-4f69-8289-a1509184d4a5	康全	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
91210d94-29c4-4e56-9bf7-f944680e1be2	优康利莱	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
1c3c1a87-6c4a-4b95-8b50-508bea5f0a0a	芳华正茂	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
86a4a4e1-21c4-4bda-8dca-e36f0a1cd2eb	可尾	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
fd01c720-0e0c-40bf-8865-4d0446eb69dd	梦牵梦	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
68e33276-1f54-427b-a4ac-7fd9336ed930	舒邦优尚	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
94bd6cd8-6f33-4af1-8486-7dfffe40988d	比克塑胶	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:27.038512
a12be1ef-7229-4986-8761-ffe65ea7f807	乔优	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:57.200604
e55778b5-0ad7-42ca-a606-67ab0436c05c	上诚机械	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:57.200604
815e4f53-fc97-4b0e-bc11-ca0509b8a845	优葵希	\N	\N	\N	\N	中国	\N	2026-08-08 22:48:57.200604
39afd8d3-cafe-4d94-be4b-06326c246b78	新财鑫	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:07.826581
599c0d2a-bf40-4d71-91cd-edfce2aac9d3	艺霖机械	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:07.826581
28700bfc-c405-4f53-995f-75c60eb49dbe	汕头恒一	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:07.826581
444d5030-5521-454c-9abe-5ffbc2121598	镭德杰	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:07.826581
ce7fb7d8-1c4c-4aa9-a5c2-61e5f3c90080	海尔曼 Herrmann	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:07.826581
4069eac4-a0e3-4286-a464-1165ea8e61ca	海旻	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:07.826581
d27dc7e1-cdd5-432d-ab56-adc6823de00f	悦尚	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
6157b45d-4dac-4edd-bb85-e050ca173496	亿宁通	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
6aaf1aa3-4a72-4f97-afb4-95058f06d031	afp	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
566069de-43f5-4064-82b1-d3ad80290533	哈曼尼	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
1703b888-38e2-411e-bcd2-1a58e04c74bb	佩格小猫	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
5d968edf-4e4b-4146-aa6c-87fd85ea852f	猫咪旺农场 CATWANT	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
021f3cb1-cca5-4c49-88f3-c8255aa80455	水木生	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
3fd4db24-43ab-4b26-9955-e7efda9a214a	GEOMCAT 几何猫	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
03ad3bd1-e0ef-4483-bde0-7c3eb3bb8740	SUXPOCAT	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
fb1485a0-83a2-42a6-8aa7-7f27dbd480c5	未卡 VETRESKA GIMMO	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
360b059b-b6fe-4c35-b6e7-b3b0db59b89e	许翠花 XCH	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
98279873-104d-40dc-a2ac-3e78a861c054	pidan	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
7dc1538d-a544-4ad4-b690-2e6ff9568a10	维尼塔 Yuup!	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
18252b1d-a908-4341-b108-2c6484ac10e6	小主王座	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
6a1dd0b6-4918-4321-92a7-221557d8fd59	喵与森林	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
31ab0a30-a7b0-40c5-8c17-1331998a2b3c	科德士	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
f54f3e9a-2522-496c-bb13-376f45b7f941	派瑞弗 Purfy	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
67a8ac35-5621-44f4-b14d-81530c3f441d	佩应美 Pet in beauty	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
05609885-b1b9-43fc-ab7c-47f5abc85f93	富萌 FURDOMUS	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
beb689e7-2d65-4a2e-a136-51c421d78f57	honeycare 好命家	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
951b19d9-f2b9-48d6-b468-3e6fd28d4d16	美佳爽 Haki Haki	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
68f1cc4e-9964-4c6c-89b0-0e8f791f9ab2	小沐 XIAOMU	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
ada2a0f4-e7bd-4bf8-b3e7-5813e658e555	鸟语花香 PET MARVEL 纳新宠食 NAXIN	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
392c7595-5b45-4023-8408-4cd218c12116	卓越明睿 Sagacity 克莉斯汀森 Chris Christensen	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
17ce32f4-249e-4a00-9e7e-f5b630adfa8c	麦宝隆	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
6380a417-a12d-4465-9902-40cc0c66e45e	岩旭	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
cd8f40a8-5d12-4b0f-872e-b1a0a76304e9	祥业	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
0d62b312-5272-4da4-9ef9-fcaf82256517	MOEWS 慕喜	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
b6618d09-765b-46f3-9fc9-7446497be200	泰亿	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
995ecec1-b62c-4c14-a050-9837a22dceaa	正润	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
fd85bf69-bad5-4775-b80a-5601a018d7d3	乐妃	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
c467ef0c-ac23-402f-b064-2c2a5c8b46e7	马龙骑	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
6b265793-59a7-4a12-8b47-b47753ae0a9b	索亚	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
2bd50fcb-b05b-4e2b-b9cb-fcff9298e2e8	星米陶瓷	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
2a316c6e-6685-49d6-8d7e-abedb0d2e5a3	伊点爱	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
1dd61faa-6799-4049-8744-6bb1d4925aaa	哈特丽 HATELI	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
9b1559d0-a5a2-431e-b3b8-e0d6244463ff	天喆	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
3ce50c9a-7a05-477c-a9f9-c498e034a4a6	斯拜若SPIRAL	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
51ca585d-f742-4797-9797-78f391e5dbe7	ZOOLAND*ARKIKA	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
bee66fb8-26bf-486c-a850-5c6488c18366	安美希	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
3c6f8284-155d-4ef9-a249-5ab58d0b58ad	亳州叁叁	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
1dadf16c-94a7-4b9d-a3d4-f3a6558831e6	振辉	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
ef420a41-fd8e-4664-aa06-dbe2dc04f440	喜多鱼	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
038c7009-b7e0-44ed-86de-80cfb181e689	花杠猫	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
2c2eaa37-5258-4301-8adf-aff94df838e0	魔力金MoliGen	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
710d5ff0-61f5-46e2-ad78-19fc2cc28f0e	华元宠物 Hoopet 富美内特 FURminator	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:22.984844
7e06124f-44e5-41ad-985e-4756957a041d	顶爱生物	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
97919d4a-de1a-406c-b9e5-1c91695adbf7	帅客	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
e6e499d0-3a7d-4d99-9be9-9c3f3542a731	塑权塑业	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
f837f340-da49-4f32-b44d-84b920428219	Cotties&Co.	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
6f476571-01ad-4a0f-86e5-55d131b1c0be	贞爱有它	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
57377e86-e744-4e90-bec9-77fbb25c3fcb	V-PET 英国 For Pets, For Planet	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
bd830e41-0f9b-4cbd-8973-52b5b783f0dc	宠老板 PetsBoss	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
cd1578e9-107e-48ce-a43f-d2f4a5e78dd7	Non-stop dogwear 朗斯拓	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
0e13bf44-de3c-45bd-bce2-f864482987b7	嬉皮狗 Hipidog	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
06060884-6286-4f17-9683-48907cbf3534	宠有引力 petgravity	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
cff316c1-2582-4dbb-b14b-a7014d0bd392	咪欧	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
5fecfe97-da5a-4b57-aa8c-c8f3f02d02de	皮皮淘 Taotaopets	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
02ff64b9-ba31-42f5-8858-a6d995f00982	趣派 cheepet	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
c2e82261-e017-4dee-acae-3bb360b36b8c	DOGADOGO	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
785f868f-eb16-44ff-a45f-f2e93b6c6bbe	Tuff Hound 它愿	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
78f6efab-4f1d-4b4e-b1be-4ff13bb80538	keevii	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
849fe6e3-2919-4e97-8ae3-60deb944b75c	艾窝 AIWO 在野在乐 ZYZL	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
23a5befd-59b6-48e3-869f-e07336dc2816	休普 SuperDesign	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
0662b9f3-f2d8-4634-9d3e-5d081e05d04c	Truelove 真爱	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
dd68100c-05cc-40f3-89d5-d2fe55db03fc	蛮果宠物 Mango	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
664b4f9c-570a-40e8-852f-a7263b173d3b	承剪	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
ae285acf-0d24-409d-bebe-78cd60684deb	宠贝趣	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
580e762f-a1f4-4f7c-9429-8bccbf5e26be	Q-Monster	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
9091a5ba-34fe-4a43-bea3-6311042b5919	莱诺 Laroo 帕鲁克 Plike	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
1cdbd943-9f4f-4d55-a5b3-adecccbeae77	MOOKIPET	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
eb0bed25-09f2-48d0-bf77-d71f5ddb1544	BlackDoggy	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
234b7886-613d-48e4-b720-6cc4d6a8c966	贵为 GiGwi	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
f13a47ac-f5ba-453e-8bbc-a3ede3d91add	zeze	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
950fbdc2-807a-4a9c-bc99-33803015deda	派思维 PETSVILLE	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
266d6fb6-5a43-4f78-93f6-c72fcb073d1d	美妙	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
888d2ed3-c39d-4ee7-b307-17046c2e1f7d	Winkoo	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
dc509638-ad7a-415f-b084-28ed0c9c993b	东顺	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
52b41df3-e7e9-4004-b652-ad2f7a4e6710	得乐DELE	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
903d9c86-d95b-43e1-baec-abf7605746c8	海多格	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
69be9018-5536-470c-b480-9ddfe605e782	Meow BuBu	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
56e32c33-6467-412a-8d9b-b593ad4b825d	KIX	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
e6f43aad-e1f0-4ae5-a2d5-8f45824eff02	Paws Holic 爪迷	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
ded62650-1ca8-4dee-b044-169675c1879c	菲达 Fida	\N	\N	\N	\N	中国	\N	2026-08-08 22:49:57.682871
8bc4ab3e-afaa-4636-8c0b-6398081a1446	悦物	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
2e6109a8-550f-4d8a-9838-b276fabb1f47	健宠	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
73d06ce9-f87c-47b3-bd77-ad8546338fe3	华众	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
167fe0e4-e7ae-4fd8-bebf-e605ddcb29d4	KaKe	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
ea89f93e-769c-4537-ad8b-d73acacee99b	斯派尔	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
ed10879b-62dd-4470-8c48-d5998ba0b299	惜时 SEEDS in	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
4087dad9-1e7b-4905-987c-75ca0e7a51f9	澳博天纯 AUPRO 好好商店 luvmarket	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
65dd8f72-5fb0-4358-b11a-cf0e3d98f912	奶思 naisi	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
370c2f8a-5225-4b37-abd0-e1b08d5df943	尾巴生活 FURRYTAIL	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
b3be17b4-cdc4-4edf-a179-56f864b79845	抖音商城 百大萌主 请就位	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
9aa27d08-2ff6-4867-b587-89c900590c2e	黑尔岛 Heal island	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
b1e497a7-ac39-4d6e-8711-02d55e6609d4	宠立方	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
12a2f5d9-cb5f-44b5-adfb-b1c015d124f4	北狼	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
e82e2f03-f836-49bc-97dc-f9c5fb644925	爱那多	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
4480c0b3-f146-4648-abac-43b10d562980	猫大力 Cat Dali	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
02e16fdf-4068-444f-b5aa-9f8905e54856	鹏禹天派	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
d3525b0a-2835-4942-8369-450358c1c8be	光明粮油 BRIGHT OIL & FOOD	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
0b03dbdb-bdc4-4a57-a870-d7deb6487b74	Gnawlers 风沫客 Dentalight Howbone 毫棒	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
899c5347-40b8-42bc-8fbe-621f346ecdc9	生生不息 PET-EVER	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
9acc8fae-61af-4ef1-a40d-c1eb0ddccf26	珍珠匠 翡冷翠	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
77b77720-912a-4545-8f32-6966671b3116	莱可宝 Likable	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
8e8f69f4-5fa5-4aa0-9a40-2cb88b0d90a8	优基 UG	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
31b0b8f8-3020-47e5-ba47-5171c342b63d	伴鲜 FreshBond	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
ba99c14e-defb-4fb5-920a-35522f62e301	贵宾休息室 VIP LOUNGE	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
5b3c08f0-f18b-4f75-9839-a1aea65e8579	万物欢喜 warmfancy	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
3e55217f-4caa-4e04-8d8a-10c6765cc666	萌力怪物	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
751699a8-938c-4030-b42c-a03172c2ff6e	心养日记	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
f8209114-4909-4067-8621-579bf52d9d8e	麦健	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
295eccca-2027-4dfe-a67b-adb481b98cdb	简醇	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
567752ec-7482-4395-9675-d85df74a4fee	芙哩与芙噜 FLFLOO	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
4e189964-ef5d-49fa-bfc3-455a787442fb	奈夫 Nice food 法丽Cherie	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:29.500848
a7f4947d-a5e1-4c56-88ea-ade1841d41d5	怪兽故事	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:52.077938
d0c1ffdf-fcd5-4a0b-a60a-a21328a81dd9	二人一物 ERONE	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:52.077938
7765d58b-3f26-476a-b5d0-e7bbd1034cfd	笨初初	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:52.077938
acdac512-f112-46a9-910e-255ab972b4ce	喵犬厨房	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:52.077938
6b9961c9-7398-4455-a2da-9f7cedabef32	佩乐其	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:52.077938
7693ee66-09d7-4a29-932a-84458d9174f7	yeeepet	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:52.077938
abc3e52f-9e4c-46b3-b025-a775cdb2944d	魔球 MOJO	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:52.077938
80be1383-f1ef-40a6-b4f5-8827f8270da2	兽医张旭 Vet's Secret	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:52.077938
1170255f-148d-49c6-89f9-da1c3094f363	弗列加特 & 汪臻醇 FREGATE&CCR	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:52.077938
e1258edf-8807-43a8-bb93-9dc4beb151c2	小佩 PETKIT 食物链 FOODCHAIN	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:52.077938
011c0efd-1aa8-40d3-b714-5d15d6de2a5b	天元宠物 Hangzhou Tianyuan Pet	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:52.077938
a13f42cc-02bf-4b12-8ab4-d65abd794c3e	佩蒂 Peidi	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:52.077938
3f0c8466-6ff1-48e6-bdd1-ea988afafa36	鲜时 Freshkita	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:52.077938
dc8ef309-8d31-4060-bf88-259d49d30bab	玛氏宠物 Mars Pet Nutrition	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:52.077938
7739befd-fe88-4b12-9720-f733c92573c8	纽顿 Nutram Number	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:52.077938
f51a06b6-67bd-4f08-a5ed-ab4a78650eb8	露思 Lusi	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:52.077938
0331d471-6cfe-4149-bd66-6d384a5d5025	虎衍 HUYAN	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:52.077938
a2d2bdab-6fe6-4ed4-b094-8f13b77f1215	馋猫馋狗	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:52.077938
a85627ab-dc88-4ba5-8c37-f531dbbdbfff	醇粹 Purich	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:52.077938
cdd699d4-b6ad-48d1-8ce4-d48a85889934	着迷 JOYME 也味 YW	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:52.077938
c57be278-6606-4e29-91dc-356e1c3645cf	江小傲 Jiangxiao'ao 汪爸爸 Dog Daddy	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:52.077938
16292d19-291e-450a-84db-5383e126b2ee	Labeen 靓贝	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:52.077938
2287f531-dc4a-4721-a2cf-50c32902dcd2	领先 TOPTREES	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:52.077938
02c336f1-0434-4fd8-8154-921f5064c46e	它一生 多艾宠	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:52.077938
df7e08f7-c864-440b-9381-0ba8f929946a	唯宠	\N	\N	\N	\N	中国	\N	2026-08-08 22:50:52.077938
9c65f7aa-abe4-463c-83b4-1bb18f6c1b3e	科泰小麦蛋白 wheat protein	\N	\N	\N	\N	中国	\N	2026-08-08 22:51:11.104257
41eb4647-7ba5-4aac-aaf6-e7c91fbbc51f	江苏同源 Tong yuan Biothecnolig	\N	\N	\N	\N	中国	\N	2026-08-08 22:51:11.104257
9cdf6d50-1570-4397-a119-45ecf531ff55	麦海 Maihai Biotech	\N	\N	\N	\N	中国	\N	2026-08-08 22:51:11.104257
48a8558e-e075-4b6a-8641-af510a0edaeb	中科初肽 Zhongke Chupeptide	\N	\N	\N	\N	中国	\N	2026-08-08 22:51:11.104257
ee691e56-4c38-46fe-b852-1026a5e86510	協力膠盒廠	\N	\N	\N	\N	中国	\N	2026-08-08 22:51:23.371372
e57be904-37e3-4312-9d05-4db25fea8b5e	禾玺包装	\N	\N	\N	\N	中国	\N	2026-08-08 22:51:23.371372
33e29966-e913-4c3b-bd6c-8dc45f612bbd	杭州神彩Seciapack	\N	\N	\N	\N	中国	\N	2026-08-08 22:51:32.487748
f947f406-37da-4ec8-9980-4376da422fc9	仰恩 Gracepack	\N	\N	\N	\N	中国	\N	2026-08-08 22:51:32.487748
4d2ed7f8-ecc0-45ee-8031-428c670ba667	绿派包装 Green packaging	\N	\N	\N	\N	中国	\N	2026-08-08 22:51:32.487748
73d99908-fbdd-4745-a9dc-f5118895cd6d	青州宏源	\N	\N	\N	\N	中国	\N	2026-08-08 22:51:32.487748
2aac9d64-22b8-418f-8fa8-80d9d209bba1	金鼎sumpot	\N	\N	\N	\N	中国	\N	2026-08-08 22:51:42.489682
f56d95e3-1286-4ca5-8905-ad1fdecb57f5	LWT 尼为智能	\N	\N	\N	\N	中国	\N	2026-08-08 22:51:42.489682
\.


--
-- Data for Name: pfa_expos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pfa_expos (id, venue_id, name, name_en, short_code, year, start_date, end_date, total_exhibitors, total_halls, overview_image, created_at, updated_at) FROM stdin;
10a40e8a-fa02-4097-9752-c68e0900d5ad	bd70d1b0-4b4a-41b2-8e05-69dde6575987	亚洲宠物展览会	Pet Fair Asia	PFA	2026	\N	\N	2023	0	index_plan.jpg	2026-08-07 19:48:47.518736	2026-08-07 19:48:47.518736
\.


--
-- Data for Name: pfa_halls; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pfa_halls (id, expo_id, code, name, name_en, floor, image_file, booth_count, raw_ocr_text, created_at) FROM stdin;
3d5631ac-6898-4c71-837d-ddfd1aff9a56	10a40e8a-fa02-4097-9752-c68e0900d5ad	W6	供应链·检测合规	Supply Chain · Compliance	\N	W6.jpg	30	\N	2026-08-07 20:01:27.849976
355e9a0d-4194-4b6b-9300-706778432b8b	10a40e8a-fa02-4097-9752-c68e0900d5ad	W7	供应链	Supply Chain	\N	W7.jpg	22	\N	2026-08-07 20:01:27.849976
9d565200-837e-49f8-9bb9-ffe200abe36e	10a40e8a-fa02-4097-9752-c68e0900d5ad	N6	供应链·加工原料	Supply Chain · Processing	\N	N6.jpg	54	\N	2026-08-07 20:01:27.849976
a43ed9f0-2f29-4e54-9fe5-63d4efdd6fd7	10a40e8a-fa02-4097-9752-c68e0900d5ad	N7	供应链·加工机械	Supply Chain · Machinery	\N	N7.jpg	31	\N	2026-08-07 19:49:10.152224
98294a78-6a0b-4f6d-8982-14f086bdfc71	10a40e8a-fa02-4097-9752-c68e0900d5ad	N8	供应链·包装输送	Supply Chain · Packaging	\N	N8.jpg	34	\N	2026-08-07 19:49:10.152224
ddd03092-63db-45eb-b935-feec84051f59	10a40e8a-fa02-4097-9752-c68e0900d5ad	N9	供应链·包装材料	Supply Chain · Materials	\N	N9.jpg	78	\N	2026-08-07 20:01:27.849976
4c50e785-1faa-4d74-a68b-e5b8e58d543d	10a40e8a-fa02-4097-9752-c68e0900d5ad	W11	供应链	Supply Chain	\N	W11.jpg	42	\N	2026-08-08 15:48:20.78904
a5eba2c3-29d9-4b64-922a-923113128e73	10a40e8a-fa02-4097-9752-c68e0900d5ad	W8	供应链	Supply Chain	\N	W8.jpg	24	\N	2026-08-07 20:01:27.849976
6d6c48a5-e2d7-4304-95fa-1de8c26ef725	10a40e8a-fa02-4097-9752-c68e0900d5ad	W9	供应链	Supply Chain	\N	W9.jpg	22	\N	2026-08-07 20:01:27.849976
94aad6f1-8039-4dd3-9bea-f647e045f7f4	10a40e8a-fa02-4097-9752-c68e0900d5ad	W10	供应链	Supply Chain	\N	W10.jpg	24	\N	2026-08-07 20:01:27.849976
2e98bebb-4397-4272-8f87-c672db07ace9	10a40e8a-fa02-4097-9752-c68e0900d5ad	N1	宠物食品	Pet Food	\N	N1.jpg	51	\N	2026-08-07 20:01:27.849976
e2aefee6-20dc-4b16-af79-b42f45b3896c	10a40e8a-fa02-4097-9752-c68e0900d5ad	N2	宠物食品	Pet Food	\N	N2.jpg	65	\N	2026-08-07 19:49:10.152224
eca8ed9a-a1f3-4319-8455-2c4f05c3fe25	10a40e8a-fa02-4097-9752-c68e0900d5ad	N3	宠物医疗与保健	Pet Healthcare & Nutrition	\N	N3.jpg	72	\N	2026-08-07 20:01:27.849976
840f44f5-e42a-40bc-aade-1a8fb38456db	10a40e8a-fa02-4097-9752-c68e0900d5ad	N4	进口宠物产品	Import Pet Products	\N	N4.jpg	103	\N	2026-08-07 20:01:27.849976
2b82b52f-52d9-4d4d-b0c0-0102f22b7949	10a40e8a-fa02-4097-9752-c68e0900d5ad	N5	进口宠物产品	Import Pet Products	\N	N5.jpg	101	\N	2026-08-07 19:49:10.152224
c977cdec-aea2-4cb0-9e55-7a979d14d8de	10a40e8a-fa02-4097-9752-c68e0900d5ad	W1	宠物用品	Comprehensive Pet Products	\N	W1.jpg	72	\N	2026-08-07 20:01:27.849976
9e7b8b58-fb65-4dce-93b2-328389382554	10a40e8a-fa02-4097-9752-c68e0900d5ad	W2	宠物用品·猫产品专区	Pet Products · Cat Zone	\N	W2.jpg	94	\N	2026-08-07 19:49:10.152224
2d43161d-b991-4322-9ede-cf469743ca99	10a40e8a-fa02-4097-9752-c68e0900d5ad	W3	宠物用品	Comprehensive Pet Products	\N	W3.jpg	71	\N	2026-08-07 19:49:10.152224
81ce2627-b60e-4408-8975-81a3c9c32044	10a40e8a-fa02-4097-9752-c68e0900d5ad	W4	宠物食品	Pet Food	\N	W4.jpg	58	\N	2026-08-07 20:01:27.849976
ba116e62-1842-49df-8a18-3de58d9309bd	10a40e8a-fa02-4097-9752-c68e0900d5ad	W5	宠物食品	Pet Food	\N	W5.jpg	44	\N	2026-08-07 20:01:27.849976
6441603b-3a04-4b5a-8035-3ccf2234604d	10a40e8a-fa02-4097-9752-c68e0900d5ad	E1	智能家居·宠物生活方式	Smart Home · Pet Lifestyle	\N	E1.jpg	124	\N	2026-08-07 20:01:27.849976
bde6f973-cd46-4c2d-8f3d-4f0a2b367f77	10a40e8a-fa02-4097-9752-c68e0900d5ad	E2	出行及旅行·服装配饰	Travel & Accessories	\N	E2.jpg	140	\N	2026-08-07 19:49:10.152224
08fbcbf2-e60d-48d8-bb81-cf56f02d50ad	10a40e8a-fa02-4097-9752-c68e0900d5ad	E3	宠物用品	Comprehensive Pet Products	\N	E3.jpg	157	\N	2026-08-07 19:49:10.152224
0d841b76-905a-440d-94f1-2f3cb8e4a5b4	10a40e8a-fa02-4097-9752-c68e0900d5ad	E4	小宠·爬宠·水族	Small Animals · Reptile · Aquarium	\N	E4.jpg	142	\N	2026-08-07 20:01:27.849976
cedf8ea5-3e48-4870-936f-578bec486cc4	10a40e8a-fa02-4097-9752-c68e0900d5ad	E5	宠物用品	Comprehensive Pet Products	\N	E5.jpg	189	\N	2026-08-07 19:49:10.152224
66b156f3-5086-4725-8628-88255110afdf	10a40e8a-fa02-4097-9752-c68e0900d5ad	E6	宠物食品	Pet Food	\N	E6.jpg	58	\N	2026-08-07 20:01:27.849976
ddfbcb16-6912-4d7a-80ef-0b575a857e9b	10a40e8a-fa02-4097-9752-c68e0900d5ad	E7	宠物食品·功能性食品	Pet Food · Functional Diet	\N	E7.jpg	73	\N	2026-08-07 20:01:27.849976
54c76ee5-96bc-4d8b-81fc-0407195285d5	10a40e8a-fa02-4097-9752-c68e0900d5ad	E8	初创企业·设计师宠物区	Start-Up · Designer Pet Zone	\N	E8.jpg	86	\N	2026-08-07 20:01:27.849976
\.


--
-- Data for Name: pfa_venues; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pfa_venues (id, name, name_en, short_code, city, district, address, total_area_sqm, hall_count, metro_station, created_at, updated_at) FROM stdin;
bd70d1b0-4b4a-41b2-8e05-69dde6575987	上海新国际博览中心	Shanghai New International Expo Centre	SNIEC	上海	浦东新区	\N	\N	\N	7号线花木路站	2026-08-07 19:48:47.517634	2026-08-07 19:48:47.517634
\.


--
-- Data for Name: pfa_visit_plans; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pfa_visit_plans (id, expo_id, plan_name, visit_date, hall_order, booth_sequence, estimated_minutes, status, created_at) FROM stdin;
\.


--
-- Name: pfa_booth_visits pfa_booth_visits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pfa_booth_visits
    ADD CONSTRAINT pfa_booth_visits_pkey PRIMARY KEY (id);


--
-- Name: pfa_booths pfa_booths_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pfa_booths
    ADD CONSTRAINT pfa_booths_pkey PRIMARY KEY (id);


--
-- Name: pfa_exhibitors pfa_exhibitors_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pfa_exhibitors
    ADD CONSTRAINT pfa_exhibitors_name_key UNIQUE (name);


--
-- Name: pfa_exhibitors pfa_exhibitors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pfa_exhibitors
    ADD CONSTRAINT pfa_exhibitors_pkey PRIMARY KEY (id);


--
-- Name: pfa_expos pfa_expos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pfa_expos
    ADD CONSTRAINT pfa_expos_pkey PRIMARY KEY (id);


--
-- Name: pfa_expos pfa_expos_short_code_year_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pfa_expos
    ADD CONSTRAINT pfa_expos_short_code_year_key UNIQUE (short_code, year);


--
-- Name: pfa_halls pfa_halls_expo_id_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pfa_halls
    ADD CONSTRAINT pfa_halls_expo_id_code_key UNIQUE (expo_id, code);


--
-- Name: pfa_halls pfa_halls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pfa_halls
    ADD CONSTRAINT pfa_halls_pkey PRIMARY KEY (id);


--
-- Name: pfa_venues pfa_venues_name_city_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pfa_venues
    ADD CONSTRAINT pfa_venues_name_city_key UNIQUE (name, city);


--
-- Name: pfa_venues pfa_venues_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pfa_venues
    ADD CONSTRAINT pfa_venues_pkey PRIMARY KEY (id);


--
-- Name: pfa_visit_plans pfa_visit_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pfa_visit_plans
    ADD CONSTRAINT pfa_visit_plans_pkey PRIMARY KEY (id);


--
-- Name: pfa_booths_expo_hall_booth; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX pfa_booths_expo_hall_booth ON public.pfa_booths USING btree (expo_id, hall_id, booth_number);


--
-- Name: pfa_booth_visits pfa_booth_visits_booth_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pfa_booth_visits
    ADD CONSTRAINT pfa_booth_visits_booth_id_fkey FOREIGN KEY (booth_id) REFERENCES public.pfa_booths(id);


--
-- Name: pfa_booths pfa_booths_exhibitor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pfa_booths
    ADD CONSTRAINT pfa_booths_exhibitor_id_fkey FOREIGN KEY (exhibitor_id) REFERENCES public.pfa_exhibitors(id);


--
-- Name: pfa_booths pfa_booths_expo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pfa_booths
    ADD CONSTRAINT pfa_booths_expo_id_fkey FOREIGN KEY (expo_id) REFERENCES public.pfa_expos(id);


--
-- Name: pfa_booths pfa_booths_hall_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pfa_booths
    ADD CONSTRAINT pfa_booths_hall_id_fkey FOREIGN KEY (hall_id) REFERENCES public.pfa_halls(id);


--
-- Name: pfa_expos pfa_expos_venue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pfa_expos
    ADD CONSTRAINT pfa_expos_venue_id_fkey FOREIGN KEY (venue_id) REFERENCES public.pfa_venues(id);


--
-- Name: pfa_halls pfa_halls_expo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pfa_halls
    ADD CONSTRAINT pfa_halls_expo_id_fkey FOREIGN KEY (expo_id) REFERENCES public.pfa_expos(id);


--
-- Name: pfa_visit_plans pfa_visit_plans_expo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pfa_visit_plans
    ADD CONSTRAINT pfa_visit_plans_expo_id_fkey FOREIGN KEY (expo_id) REFERENCES public.pfa_expos(id);


--
-- PostgreSQL database dump complete
--

\unrestrict PIePVuD1KZ1vXhFcYB25gs4hWMfQMMsBfSplxDJrIKVyp6E7k4CM85hl11S3amQ

