--
-- PostgreSQL database dump
--

\restrict hchC3KIRDXi6eN8sdKEiFKnuSpNyyWGYWcrVaCjcu6v2GS1cF15Vz0q4Ix2m04k

-- Dumped from database version 14.21 (Ubuntu 14.21-1.pgdg22.04+1)
-- Dumped by pg_dump version 14.21 (Ubuntu 14.21-1.pgdg22.04+1)

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

--
-- Name: appointment_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.appointment_status AS ENUM (
    'SCHEDULED',
    'COMPLETED',
    'CANCELLED',
    'NO_SHOW',
    'CONFIRMED',
    'IN_PROGRESS'
);


ALTER TYPE public.appointment_status OWNER TO postgres;

--
-- Name: audit_action; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.audit_action AS ENUM (
    'USER_CREATED',
    'USER_UPDATED',
    'USER_DELETED',
    'LOGIN',
    'TOKEN_REFRESH',
    'LOGOUT',
    'ACTIVATE',
    'DEACTIVATE',
    'PASSWORD_CHANGED',
    'PATIENT_CREATED',
    'PATIENT_UPDATED',
    'PATIENT_DELETED',
    'REPORT_CREATED',
    'REPORT_UPDATED',
    'REPORT_APPROVED',
    'REPORT_FINALIZED',
    'IMAGE_UPLOADED',
    'LAB_UPLOADED',
    'APPOINTMENT_CREATED',
    'APPOINTMENT_UPDATED',
    'APPOINTMENT_CANCELLED',
    'APPOINTMENT_COMPLETED',
    'VISIT_STARTED',
    'VISIT_UPDATED',
    'VISIT_COMPLETED'
);


ALTER TYPE public.audit_action OWNER TO postgres;

--
-- Name: condition_category; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.condition_category AS ENUM (
    'CHRONIC',
    'ALLERGY'
);


ALTER TYPE public.condition_category OWNER TO postgres;

--
-- Name: gender; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.gender AS ENUM (
    'MALE',
    'FEMALE'
);


ALTER TYPE public.gender OWNER TO postgres;

--
-- Name: image_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.image_type AS ENUM (
    'XRAY',
    'SKIN'
);


ALTER TYPE public.image_type OWNER TO postgres;

--
-- Name: report_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.report_status AS ENUM (
    'DRAFT',
    'CONFIRMED',
    'REVIEWED',
    'CANCELLED',
    'APPROVED',
    'FINALIZED'
);


ALTER TYPE public.report_status OWNER TO postgres;

--
-- Name: user_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.user_role AS ENUM (
    'DOCTOR',
    'ASSISTANT',
    'ADMIN'
);


ALTER TYPE public.user_role OWNER TO postgres;

--
-- Name: visit_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.visit_status AS ENUM (
    'IN_PROGRESS',
    'COMPLETED',
    'WAITING',
    'CANCELLED'
);


ALTER TYPE public.visit_status OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: admins; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admins (
    id integer NOT NULL,
    user_id integer NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.admins OWNER TO postgres;

--
-- Name: admins_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admins_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.admins_id_seq OWNER TO postgres;

--
-- Name: admins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admins_id_seq OWNED BY public.admins.id;


--
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


ALTER TABLE public.alembic_version OWNER TO postgres;

--
-- Name: appointment_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.appointment_types (
    id integer NOT NULL,
    doctor_id integer NOT NULL,
    name character varying(150) NOT NULL,
    description text,
    duration_minutes integer,
    default_fee numeric(10,2),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.appointment_types OWNER TO postgres;

--
-- Name: appointment_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.appointment_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.appointment_types_id_seq OWNER TO postgres;

--
-- Name: appointment_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.appointment_types_id_seq OWNED BY public.appointment_types.id;


--
-- Name: appointments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.appointments (
    id integer NOT NULL,
    patient_id integer NOT NULL,
    doctor_id integer NOT NULL,
    appointment_type_id integer,
    start_time timestamp with time zone NOT NULL,
    status public.appointment_status DEFAULT 'SCHEDULED'::public.appointment_status NOT NULL,
    reason text,
    is_urgent boolean DEFAULT false NOT NULL,
    is_paid boolean DEFAULT false NOT NULL,
    fee numeric(10,2),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.appointments OWNER TO postgres;

--
-- Name: appointments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.appointments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.appointments_id_seq OWNER TO postgres;

--
-- Name: appointments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.appointments_id_seq OWNED BY public.appointments.id;


--
-- Name: assistants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.assistants (
    id integer NOT NULL,
    user_id integer NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    date_of_birth date,
    gender public.gender,
    phone_number character varying(30),
    country character varying(100),
    region character varying(100),
    city character varying(100),
    clinic_name character varying(200),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.assistants OWNER TO postgres;

--
-- Name: assistants_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.assistants_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.assistants_id_seq OWNER TO postgres;

--
-- Name: assistants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.assistants_id_seq OWNED BY public.assistants.id;


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_logs (
    id integer NOT NULL,
    user_id integer,
    action public.audit_action NOT NULL,
    entity_type character varying(100),
    entity_id integer,
    details text,
    ip_address character varying(45),
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.audit_logs OWNER TO postgres;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.audit_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.audit_logs_id_seq OWNER TO postgres;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: doctors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.doctors (
    id integer NOT NULL,
    user_id integer NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    date_of_birth date,
    gender public.gender,
    phone_number character varying(30),
    country character varying(100),
    region character varying(100),
    city character varying(100),
    clinic_name character varying(200),
    specialization character varying(150),
    license_number character varying(100),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.doctors OWNER TO postgres;

--
-- Name: doctors_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.doctors_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.doctors_id_seq OWNER TO postgres;

--
-- Name: doctors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.doctors_id_seq OWNED BY public.doctors.id;


--
-- Name: lab_reports; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lab_reports (
    id integer NOT NULL,
    visit_id integer NOT NULL,
    report_url character varying(500) NOT NULL,
    ai_interpreted_summary text,
    original_text text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.lab_reports OWNER TO postgres;

--
-- Name: lab_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lab_reports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lab_reports_id_seq OWNER TO postgres;

--
-- Name: lab_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lab_reports_id_seq OWNED BY public.lab_reports.id;


--
-- Name: medical_conditions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.medical_conditions (
    id integer NOT NULL,
    name character varying(200) NOT NULL,
    category public.condition_category,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.medical_conditions OWNER TO postgres;

--
-- Name: medical_conditions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.medical_conditions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.medical_conditions_id_seq OWNER TO postgres;

--
-- Name: medical_conditions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.medical_conditions_id_seq OWNED BY public.medical_conditions.id;


--
-- Name: medical_images; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.medical_images (
    id integer NOT NULL,
    visit_id integer NOT NULL,
    image_url character varying(500) NOT NULL,
    image_type public.image_type NOT NULL,
    ai_diagnosis text,
    doctor_notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.medical_images OWNER TO postgres;

--
-- Name: medical_images_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.medical_images_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.medical_images_id_seq OWNER TO postgres;

--
-- Name: medical_images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.medical_images_id_seq OWNED BY public.medical_images.id;


--
-- Name: medical_reports; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.medical_reports (
    id integer NOT NULL,
    visit_id integer NOT NULL,
    doctor_id integer NOT NULL,
    doctor_voice_transcription text,
    ai_diagnosis text,
    ai_medications jsonb,
    ai_recommendations jsonb,
    ai_follow_up character varying(500),
    doctor_notes text,
    status public.report_status DEFAULT 'DRAFT'::public.report_status NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.medical_reports OWNER TO postgres;

--
-- Name: medical_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.medical_reports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.medical_reports_id_seq OWNER TO postgres;

--
-- Name: medical_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.medical_reports_id_seq OWNED BY public.medical_reports.id;


--
-- Name: patient_conditions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.patient_conditions (
    id integer NOT NULL,
    patient_id integer NOT NULL,
    condition_id integer NOT NULL,
    diagnosed_date date,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.patient_conditions OWNER TO postgres;

--
-- Name: patient_conditions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.patient_conditions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.patient_conditions_id_seq OWNER TO postgres;

--
-- Name: patient_conditions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.patient_conditions_id_seq OWNED BY public.patient_conditions.id;


--
-- Name: patients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.patients (
    id integer NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    date_of_birth date,
    gender public.gender,
    national_id character varying(50),
    phone character varying(30),
    email character varying(255),
    address text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.patients OWNER TO postgres;

--
-- Name: patients_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.patients_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.patients_id_seq OWNER TO postgres;

--
-- Name: patients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.patients_id_seq OWNED BY public.patients.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    role public.user_role NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: visits; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.visits (
    id integer NOT NULL,
    appointment_id integer NOT NULL,
    chief_complaint text,
    blood_pressure character varying(20),
    heart_rate integer,
    temperature numeric(4,1),
    weight numeric(5,2),
    height numeric(5,2),
    notes text,
    status public.visit_status DEFAULT 'IN_PROGRESS'::public.visit_status NOT NULL,
    start_time timestamp with time zone,
    end_time timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.visits OWNER TO postgres;

--
-- Name: visits_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.visits_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.visits_id_seq OWNER TO postgres;

--
-- Name: visits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.visits_id_seq OWNED BY public.visits.id;


--
-- Name: admins id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admins ALTER COLUMN id SET DEFAULT nextval('public.admins_id_seq'::regclass);


--
-- Name: appointment_types id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointment_types ALTER COLUMN id SET DEFAULT nextval('public.appointment_types_id_seq'::regclass);


--
-- Name: appointments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments ALTER COLUMN id SET DEFAULT nextval('public.appointments_id_seq'::regclass);


--
-- Name: assistants id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assistants ALTER COLUMN id SET DEFAULT nextval('public.assistants_id_seq'::regclass);


--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: doctors id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctors ALTER COLUMN id SET DEFAULT nextval('public.doctors_id_seq'::regclass);


--
-- Name: lab_reports id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lab_reports ALTER COLUMN id SET DEFAULT nextval('public.lab_reports_id_seq'::regclass);


--
-- Name: medical_conditions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medical_conditions ALTER COLUMN id SET DEFAULT nextval('public.medical_conditions_id_seq'::regclass);


--
-- Name: medical_images id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medical_images ALTER COLUMN id SET DEFAULT nextval('public.medical_images_id_seq'::regclass);


--
-- Name: medical_reports id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medical_reports ALTER COLUMN id SET DEFAULT nextval('public.medical_reports_id_seq'::regclass);


--
-- Name: patient_conditions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_conditions ALTER COLUMN id SET DEFAULT nextval('public.patient_conditions_id_seq'::regclass);


--
-- Name: patients id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patients ALTER COLUMN id SET DEFAULT nextval('public.patients_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: visits id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visits ALTER COLUMN id SET DEFAULT nextval('public.visits_id_seq'::regclass);


--
-- Data for Name: admins; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admins (id, user_id, first_name, last_name, created_at, updated_at) FROM stdin;
1	1	Updated	Admin	2026-02-21 17:28:25.989937+00	2026-02-21 18:52:19.331347+00
\.


--
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alembic_version (version_num) FROM stdin;
\.


--
-- Data for Name: appointment_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.appointment_types (id, doctor_id, name, description, duration_minutes, default_fee, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: appointments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.appointments (id, patient_id, doctor_id, appointment_type_id, start_time, status, reason, is_urgent, is_paid, fee, created_at, updated_at) FROM stdin;
2	1	2	\N	2026-03-01 15:47:00+00	CANCELLED	[URGENT]	t	t	200.00	2026-03-01 15:48:09.214252+00	2026-03-01 17:28:08.400584+00
6	8	2	\N	2026-03-01 16:35:00+00	CANCELLED		t	t	0.00	2026-03-01 16:36:33.251371+00	2026-03-01 17:28:11.298609+00
1	5	2	\N	2026-03-01 15:32:00+00	CANCELLED		f	t	0.00	2026-03-01 15:33:30.751998+00	2026-03-01 17:28:13.681656+00
3	7	2	\N	2026-03-01 15:52:00+00	CANCELLED		f	f	200.00	2026-03-01 15:52:58.238852+00	2026-03-01 17:28:15.637304+00
4	5	2	\N	2026-03-01 16:07:00+00	CANCELLED		f	f	200.00	2026-03-01 16:08:05.669441+00	2026-03-01 17:28:17.636321+00
5	1	2	\N	2026-03-01 16:34:00+00	CANCELLED		f	f	0.00	2026-03-01 16:35:02.743029+00	2026-03-01 17:28:19.811215+00
7	8	2	\N	2026-03-01 16:53:00+00	CANCELLED		f	f	200.00	2026-03-01 16:54:27.399474+00	2026-03-01 17:28:44.814168+00
8	8	2	\N	2026-03-01 17:26:00+00	CANCELLED		f	t	200.00	2026-03-01 17:27:18.27398+00	2026-03-01 17:28:47.614782+00
9	8	1	\N	2026-03-01 17:29:00+00	SCHEDULED		f	t	200.00	2026-03-01 17:30:44.05082+00	2026-03-01 17:31:04.943639+00
10	8	2	\N	2026-03-01 17:31:00+00	SCHEDULED		f	t	200.00	2026-03-01 17:31:49.942398+00	2026-03-01 17:31:49.942398+00
11	1	2	\N	2026-03-01 17:42:00+00	SCHEDULED		f	t	300.00	2026-03-01 17:43:44.728661+00	2026-03-01 17:43:44.728661+00
12	5	2	\N	2026-03-01 17:55:00+00	SCHEDULED		f	f	100.00	2026-03-01 17:56:42.42445+00	2026-03-01 17:56:42.42445+00
13	7	2	\N	2026-03-01 17:56:00+00	SCHEDULED		f	t	300.00	2026-03-01 17:57:36.646682+00	2026-03-01 17:57:36.646682+00
14	7	1	\N	2026-03-01 17:57:00+00	SCHEDULED		f	t	300.00	2026-03-01 17:58:32.405251+00	2026-03-01 17:58:32.405251+00
15	5	2	\N	2026-03-01 17:59:00+00	SCHEDULED		f	f	250.00	2026-03-01 18:00:10.512645+00	2026-03-01 18:00:10.512645+00
16	1	2	\N	2026-03-02 11:23:00+00	SCHEDULED		f	t	300.00	2026-03-02 11:24:21.202317+00	2026-03-02 11:24:21.202317+00
17	8	2	\N	2026-03-02 11:25:00+00	SCHEDULED		f	t	100.00	2026-03-02 11:26:17.879841+00	2026-03-02 11:26:17.879841+00
18	5	1	\N	2026-03-02 11:42:00+00	SCHEDULED		f	f	300.00	2026-03-02 11:43:45.21403+00	2026-03-02 11:43:45.21403+00
19	9	1	\N	2026-03-02 14:38:00+00	SCHEDULED		f	t	300.00	2026-03-02 14:39:51.128315+00	2026-03-02 14:39:51.128315+00
20	8	2	\N	2026-03-02 14:54:00+00	SCHEDULED		f	f	200.00	2026-03-02 14:55:18.431535+00	2026-03-02 14:55:18.431535+00
21	9	2	\N	2026-03-02 14:57:00+00	SCHEDULED		f	f	200.00	2026-03-02 14:57:54.53995+00	2026-03-02 14:57:54.53995+00
\.


--
-- Data for Name: assistants; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.assistants (id, user_id, first_name, last_name, date_of_birth, gender, phone_number, country, region, city, clinic_name, created_at, updated_at) FROM stdin;
1	3	Sara	Ali	\N	\N	+201098765432	\N	\N	Alexandria	Al Shifa Clinic	2026-02-21 18:51:05.829966+00	2026-02-21 18:51:33.274593+00
2	6	Salma	Alhasan	\N	\N	01546787548	\N	\N	\N	Alshefa	2026-03-02 15:55:08.448163+00	2026-03-02 15:55:08.448163+00
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_logs (id, user_id, action, entity_type, entity_id, details, ip_address, created_at) FROM stdin;
1	1	LOGIN	user	1	Successful login.	\N	2026-02-21 17:45:39.025182+00
2	1	LOGIN	user	1	Successful login.	\N	2026-02-21 18:15:35.575438+00
3	\N	LOGIN	user	\N	Failed login attempt.	\N	2026-02-21 18:47:16.400613+00
4	1	LOGIN	user	1	Successful login.	\N	2026-02-21 18:47:39.885042+00
5	1	USER_CREATED	doctor	1	{"email": "dr.ahmed@clinic.com", "name": "Ahmed Hassan"}	\N	2026-02-21 18:49:26.885352+00
6	1	USER_UPDATED	doctor	1	{"clinic_name": "New Clinic Name", "specialization": "Cardiology"}	\N	2026-02-21 18:50:36.010909+00
7	1	USER_CREATED	assistant	1	{"email": "assistant@clinic.com"}	\N	2026-02-21 18:51:05.829966+00
8	1	USER_UPDATED	assistant	1	{"city": "Alexandria"}	\N	2026-02-21 18:51:33.274593+00
9	1	USER_UPDATED	admin	1	{"first_name": "Updated"}	\N	2026-02-21 18:52:19.331347+00
10	1	LOGIN	user	1	Successful login.	\N	2026-02-22 00:11:45.016032+00
11	1	LOGIN	user	1	Successful login.	\N	2026-02-22 00:19:51.837222+00
12	1	USER_UPDATED	doctor	1	{"clinic_name": "Old Clinic Name"}	\N	2026-02-22 00:20:40.112513+00
13	1	LOGIN	user	1	Successful login.	\N	2026-02-22 00:46:39.314599+00
14	1	LOGIN	user	1	Successful login.	\N	2026-02-22 00:48:16.470355+00
15	1	LOGIN	user	1	Successful login.	\N	2026-02-22 00:49:31.633782+00
16	1	LOGIN	user	1	Successful login.	\N	2026-02-22 00:52:34.911084+00
17	1	LOGIN	user	1	Successful login.	\N	2026-02-22 00:56:36.135695+00
18	1	LOGIN	user	1	Successful login.	\N	2026-02-22 01:05:13.218527+00
19	2	LOGIN	user	2	Successful login.	\N	2026-02-22 20:30:12.804251+00
20	2	LOGIN	user	2	Successful login.	\N	2026-02-22 20:30:22.410517+00
21	2	LOGIN	user	2	Successful login.	\N	2026-02-22 20:31:29.431936+00
22	3	LOGIN	user	3	Successful login.	\N	2026-02-22 21:41:54.87119+00
23	2	LOGIN	user	2	Successful login.	\N	2026-02-22 21:42:00.197323+00
24	2	LOGIN	user	2	Successful login.	\N	2026-02-22 21:42:22.452441+00
25	1	LOGIN	user	1	Successful login.	\N	2026-02-22 21:50:02.321131+00
26	2	LOGIN	user	2	Successful login.	\N	2026-02-22 21:54:00.526563+00
27	3	LOGIN	user	3	Successful login.	\N	2026-02-22 21:54:52.496765+00
28	2	LOGIN	user	2	Successful login.	\N	2026-02-22 21:55:33.167718+00
29	3	LOGIN	user	3	Successful login.	\N	2026-02-22 21:55:38.294929+00
30	2	LOGIN	user	2	Successful login.	\N	2026-02-22 21:56:52.604999+00
31	1	LOGIN	user	1	Successful login.	\N	2026-02-22 22:08:14.679398+00
32	2	LOGIN	user	2	Successful login.	\N	2026-02-22 22:13:12.911707+00
33	2	LOGIN	user	2	Successful login.	\N	2026-02-22 22:13:59.502987+00
34	2	LOGIN	user	2	Successful login.	\N	2026-02-22 22:29:14.366839+00
35	2	LOGIN	user	2	Successful login.	\N	2026-02-22 22:35:41.970923+00
36	2	LOGIN	user	2	Successful login.	\N	2026-02-25 10:48:03.472712+00
37	1	LOGIN	user	1	Successful login.	\N	2026-02-25 11:01:41.542725+00
38	2	LOGIN	user	2	Successful login.	\N	2026-02-25 11:09:05.517732+00
39	2	LOGIN	user	2	Successful login.	\N	2026-02-25 11:17:39.602227+00
40	2	LOGIN	user	2	Successful login.	\N	2026-02-25 11:42:03.69822+00
41	1	LOGIN	user	1	Successful login.	\N	2026-02-25 11:48:14.311965+00
42	3	LOGIN	user	3	Successful login.	\N	2026-02-25 11:49:26.211149+00
43	3	LOGIN	user	3	Successful login.	\N	2026-02-25 11:49:44.332951+00
44	2	LOGIN	user	2	Successful login.	\N	2026-02-25 11:56:25.116864+00
45	2	PATIENT_CREATED	patient	1	{"name": "Ahmed Omar"}	\N	2026-02-25 11:56:56.131199+00
46	1	LOGIN	user	1	Successful login.	\N	2026-02-25 11:58:54.242283+00
47	1	USER_CREATED	doctor	2	{"email": "tarekomar30303012615776@gmail.com", "name": "Ahmed Mohsen"}	\N	2026-02-25 11:58:54.780735+00
48	4	LOGIN	user	4	Successful login.	\N	2026-02-25 11:59:11.339925+00
49	2	LOGIN	user	2	Successful login.	\N	2026-02-25 15:25:05.121253+00
50	2	LOGIN	user	2	Successful login.	\N	2026-02-25 16:59:06.67326+00
51	2	LOGIN	user	2	Successful login.	\N	2026-02-25 17:08:39.432543+00
52	2	LOGIN	user	2	Successful login.	\N	2026-02-25 17:12:47.413048+00
53	2	LOGIN	user	2	Successful login.	\N	2026-02-28 18:42:22.025915+00
54	1	LOGIN	user	1	Successful login.	\N	2026-02-28 19:42:25.536953+00
55	1	LOGIN	user	1	Successful login.	\N	2026-02-28 19:50:47.149404+00
56	2	LOGIN	user	2	Successful login.	\N	2026-03-01 15:31:22.618396+00
57	2	PATIENT_CREATED	patient	5	{"name": "Shady Hany"}	\N	2026-03-01 15:32:07.264852+00
58	3	LOGIN	user	3	Successful login.	\N	2026-03-01 15:33:02.683647+00
59	3	APPOINTMENT_CREATED	appointment	1	{"patient_id": 5, "doctor_id": 2, "start_time": "2026-03-01 17:32:00+02:00"}	\N	2026-03-01 15:33:30.751998+00
60	2	LOGIN	user	2	Successful login.	\N	2026-03-01 15:47:51.174907+00
61	2	APPOINTMENT_CREATED	appointment	2	{"patient_id": 1, "doctor_id": 2, "start_time": "2026-03-01 17:47:00+02:00"}	\N	2026-03-01 15:48:09.214252+00
62	3	LOGIN	user	3	Successful login.	\N	2026-03-01 15:48:41.741999+00
63	2	LOGIN	user	2	Successful login.	\N	2026-03-01 15:51:44.21037+00
64	2	PATIENT_CREATED	patient	7	{"name": "Ramy Hassan"}	\N	2026-03-01 15:52:30.295352+00
65	2	APPOINTMENT_CREATED	appointment	3	{"patient_id": 7, "doctor_id": 2, "start_time": "2026-03-01 17:52:00+02:00"}	\N	2026-03-01 15:52:58.238852+00
66	3	LOGIN	user	3	Successful login.	\N	2026-03-01 15:53:10.667608+00
67	2	LOGIN	user	2	Successful login.	\N	2026-03-01 16:07:57.92325+00
68	2	APPOINTMENT_CREATED	appointment	4	{"patient_id": 5, "doctor_id": 2, "start_time": "2026-03-01 18:07:00+02:00"}	\N	2026-03-01 16:08:05.669441+00
69	3	LOGIN	user	3	Successful login.	\N	2026-03-01 16:08:13.518136+00
70	3	LOGIN	user	3	Successful login.	\N	2026-03-01 16:34:20.440344+00
71	2	LOGIN	user	2	Successful login.	\N	2026-03-01 16:34:30.206015+00
72	3	LOGIN	user	3	Successful login.	\N	2026-03-01 16:34:39.534664+00
73	3	APPOINTMENT_CREATED	appointment	5	{"patient_id": 1, "doctor_id": 2, "start_time": "2026-03-01 18:34:00+02:00"}	\N	2026-03-01 16:35:02.743029+00
74	3	PATIENT_CREATED	patient	8	{"name": "Lila Ali"}	\N	2026-03-01 16:35:49.739473+00
75	3	APPOINTMENT_CREATED	appointment	6	{"patient_id": 8, "doctor_id": 2, "start_time": "2026-03-01 18:35:00+02:00"}	\N	2026-03-01 16:36:33.251371+00
76	3	LOGIN	user	3	Successful login.	\N	2026-03-01 16:39:11.98053+00
77	2	LOGIN	user	2	Successful login.	\N	2026-03-01 16:39:28.037276+00
78	2	LOGIN	user	2	Successful login.	\N	2026-03-01 16:52:16.055266+00
79	3	LOGIN	user	3	Successful login.	\N	2026-03-01 16:52:31.369654+00
80	3	APPOINTMENT_UPDATED	appointment	2	{"from": "SCHEDULED", "to": "CONFIRMED"}	\N	2026-03-01 16:52:40.239718+00
81	2	LOGIN	user	2	Successful login.	\N	2026-03-01 16:54:00.498775+00
82	2	APPOINTMENT_CREATED	appointment	7	{"patient_id": 8, "doctor_id": 2, "start_time": "2026-03-01 18:53:00+02:00"}	\N	2026-03-01 16:54:27.399474+00
83	3	LOGIN	user	3	Successful login.	\N	2026-03-01 16:54:39.898554+00
84	2	LOGIN	user	2	Successful login.	\N	2026-03-01 17:27:04.467148+00
85	2	APPOINTMENT_CREATED	appointment	8	{"patient_id": 8, "doctor_id": 2, "start_time": "2026-03-01 19:26:00+02:00"}	\N	2026-03-01 17:27:18.27398+00
86	3	LOGIN	user	3	Successful login.	\N	2026-03-01 17:27:46.027568+00
87	3	LOGIN	user	3	Successful login.	\N	2026-03-01 17:28:03.560594+00
88	3	APPOINTMENT_CANCELLED	appointment	2	{"from": "CONFIRMED", "to": "CANCELLED"}	\N	2026-03-01 17:28:08.400584+00
89	3	APPOINTMENT_CANCELLED	appointment	6	{"from": "SCHEDULED", "to": "CANCELLED"}	\N	2026-03-01 17:28:11.298609+00
90	3	APPOINTMENT_CANCELLED	appointment	1	{"from": "SCHEDULED", "to": "CANCELLED"}	\N	2026-03-01 17:28:13.681656+00
91	3	APPOINTMENT_CANCELLED	appointment	3	{"from": "SCHEDULED", "to": "CANCELLED"}	\N	2026-03-01 17:28:15.637304+00
92	3	APPOINTMENT_CANCELLED	appointment	4	{"from": "SCHEDULED", "to": "CANCELLED"}	\N	2026-03-01 17:28:17.636321+00
93	3	APPOINTMENT_CANCELLED	appointment	5	{"from": "SCHEDULED", "to": "CANCELLED"}	\N	2026-03-01 17:28:19.811215+00
97	3	LOGIN	user	3	Successful login.	\N	2026-03-01 17:30:13.561739+00
98	3	APPOINTMENT_CREATED	appointment	9	{"patient_id": 8, "doctor_id": 1, "start_time": "2026-03-01 19:29:00+02:00"}	\N	2026-03-01 17:30:44.05082+00
99	3	APPOINTMENT_UPDATED	appointment	9	{"fee": "200.0"}	\N	2026-03-01 17:31:04.943639+00
94	3	APPOINTMENT_CANCELLED	appointment	7	{"from": "SCHEDULED", "to": "CANCELLED"}	\N	2026-03-01 17:28:44.814168+00
95	3	APPOINTMENT_CANCELLED	appointment	8	{"from": "SCHEDULED", "to": "CANCELLED"}	\N	2026-03-01 17:28:47.614782+00
96	3	LOGIN	user	3	Successful login.	\N	2026-03-01 17:29:23.552733+00
100	2	LOGIN	user	2	Successful login.	\N	2026-03-01 17:31:29.54202+00
101	2	APPOINTMENT_CREATED	appointment	10	{"patient_id": 8, "doctor_id": 2, "start_time": "2026-03-01 19:31:00+02:00"}	\N	2026-03-01 17:31:49.942398+00
102	2	LOGIN	user	2	Successful login.	\N	2026-03-01 17:43:27.234564+00
103	2	APPOINTMENT_CREATED	appointment	11	{"patient_id": 1, "doctor_id": 2, "start_time": "2026-03-01 19:42:00+02:00"}	\N	2026-03-01 17:43:44.728661+00
104	3	LOGIN	user	3	Successful login.	\N	2026-03-01 17:44:10.725899+00
105	2	LOGIN	user	2	Successful login.	\N	2026-03-01 17:44:46.746242+00
106	2	LOGIN	user	2	Successful login.	\N	2026-03-01 17:56:25.132526+00
107	2	APPOINTMENT_CREATED	appointment	12	{"patient_id": 5, "doctor_id": 2, "start_time": "2026-03-01 19:55:00+02:00"}	\N	2026-03-01 17:56:42.42445+00
108	3	LOGIN	user	3	Successful login.	\N	2026-03-01 17:57:00.697163+00
109	3	APPOINTMENT_CREATED	appointment	13	{"patient_id": 7, "doctor_id": 2, "start_time": "2026-03-01 19:56:00+02:00"}	\N	2026-03-01 17:57:36.646682+00
110	2	LOGIN	user	2	Successful login.	\N	2026-03-01 17:57:46.886324+00
111	3	LOGIN	user	3	Successful login.	\N	2026-03-01 17:58:08.635386+00
112	3	APPOINTMENT_CREATED	appointment	14	{"patient_id": 7, "doctor_id": 1, "start_time": "2026-03-01 19:57:00+02:00"}	\N	2026-03-01 17:58:32.405251+00
113	2	LOGIN	user	2	Successful login.	\N	2026-03-01 17:58:41.606652+00
114	2	APPOINTMENT_CREATED	appointment	15	{"patient_id": 5, "doctor_id": 2, "start_time": "2026-03-01 19:59:00+02:00"}	\N	2026-03-01 18:00:10.512645+00
115	3	LOGIN	user	3	Successful login.	\N	2026-03-01 18:00:26.026532+00
116	2	LOGIN	user	2	Successful login.	\N	2026-03-01 18:01:22.757134+00
117	2	LOGIN	user	2	Successful login.	\N	2026-03-02 11:19:55.980311+00
118	3	LOGIN	user	3	Successful login.	\N	2026-03-02 11:20:19.622397+00
119	2	LOGIN	user	2	Successful login.	\N	2026-03-02 11:20:44.412859+00
120	3	LOGIN	user	3	Successful login.	\N	2026-03-02 11:21:03.266251+00
121	\N	LOGIN	user	\N	Failed login attempt.	\N	2026-03-02 11:22:07.053013+00
122	4	LOGIN	user	4	Successful login.	\N	2026-03-02 11:22:37.708589+00
123	3	LOGIN	user	3	Successful login.	\N	2026-03-02 11:24:00.797595+00
124	3	APPOINTMENT_CREATED	appointment	16	{"patient_id": 1, "doctor_id": 2, "start_time": "2026-03-02 13:23:00+02:00"}	\N	2026-03-02 11:24:21.202317+00
125	4	LOGIN	user	4	Successful login.	\N	2026-03-02 11:24:49.4228+00
126	2	LOGIN	user	2	Successful login.	\N	2026-03-02 11:25:57.751261+00
127	2	APPOINTMENT_CREATED	appointment	17	{"patient_id": 8, "doctor_id": 2, "start_time": "2026-03-02 13:25:00+02:00"}	\N	2026-03-02 11:26:17.879841+00
128	3	LOGIN	user	3	Successful login.	\N	2026-03-02 11:26:36.791548+00
129	2	LOGIN	user	2	Successful login.	\N	2026-03-02 11:42:53.85588+00
130	3	LOGIN	user	3	Successful login.	\N	2026-03-02 11:43:29.093094+00
131	3	APPOINTMENT_CREATED	appointment	18	{"patient_id": 5, "doctor_id": 1, "start_time": "2026-03-02 13:42:00+02:00"}	\N	2026-03-02 11:43:45.21403+00
132	3	LOGIN	user	3	Successful login.	\N	2026-03-02 11:43:52.329955+00
133	2	LOGIN	user	2	Successful login.	\N	2026-03-02 11:43:59.081801+00
134	2	LOGIN	user	2	Successful login.	\N	2026-03-02 14:37:03.063492+00
135	2	PATIENT_CREATED	patient	9	{"name": "Mariem Abdelaziz"}	\N	2026-03-02 14:38:04.356649+00
136	3	LOGIN	user	3	Successful login.	\N	2026-03-02 14:38:47.864333+00
137	3	APPOINTMENT_CREATED	appointment	19	{"patient_id": 9, "doctor_id": 1, "start_time": "2026-03-02 16:38:00+02:00"}	\N	2026-03-02 14:39:51.128315+00
138	2	LOGIN	user	2	Successful login.	\N	2026-03-02 14:40:31.454495+00
139	2	LOGIN	user	2	Successful login.	\N	2026-03-02 14:54:11.449613+00
140	2	LOGIN	user	2	Successful login.	\N	2026-03-02 14:55:10.66437+00
141	2	APPOINTMENT_CREATED	appointment	20	{"patient_id": 8, "doctor_id": 2, "start_time": "2026-03-02 16:54:00+02:00"}	\N	2026-03-02 14:55:18.431535+00
142	2	LOGIN	user	2	Successful login.	\N	2026-03-02 14:57:46.484243+00
143	2	APPOINTMENT_CREATED	appointment	21	{"patient_id": 9, "doctor_id": 2, "start_time": "2026-03-02 16:57:00+02:00"}	\N	2026-03-02 14:57:54.53995+00
144	1	LOGIN	user	1	Successful login.	\N	2026-03-02 15:04:43.811927+00
145	2	LOGIN	user	2	Successful login.	\N	2026-03-02 15:27:02.576403+00
146	3	LOGIN	user	3	Successful login.	\N	2026-03-02 15:27:13.309131+00
147	2	LOGIN	user	2	Successful login.	\N	2026-03-02 15:29:28.624982+00
148	1	LOGIN	user	1	Successful login.	\N	2026-03-02 15:53:14.356128+00
149	1	USER_CREATED	doctor	3	{"email": "mohamedmousaa1004@gmail.com", "name": "Mohamed Mousa"}	\N	2026-03-02 15:53:15.130559+00
150	1	LOGIN	user	1	Successful login.	\N	2026-03-02 15:55:07.868505+00
151	1	USER_CREATED	assistant	2	{"email": "tarekomar1303@gmail.com"}	\N	2026-03-02 15:55:08.448163+00
152	6	LOGIN	user	6	Successful login.	\N	2026-03-02 15:55:46.369048+00
153	2	LOGIN	user	2	Successful login.	\N	2026-03-02 15:56:09.370948+00
154	5	LOGIN	user	5	Successful login.	\N	2026-03-02 15:56:27.453505+00
155	6	LOGIN	user	6	Successful login.	\N	2026-03-02 15:56:46.012709+00
\.


--
-- Data for Name: doctors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.doctors (id, user_id, first_name, last_name, date_of_birth, gender, phone_number, country, region, city, clinic_name, specialization, license_number, created_at, updated_at) FROM stdin;
1	2	Ahmed	Hassan	1985-06-15	MALE	+201234567890	Egypt	Cairo	Cairo	Old Clinic Name	Cardiology	EG-12345	2026-02-21 18:49:26.885352+00	2026-02-22 00:20:40.112513+00
2	4	Ahmed	Mohsen	1990-01-17	MALE	0125484984	Egypt	Alexandria	Stanley	bdbshx722	medical	822731	2026-02-25 11:58:54.780735+00	2026-02-25 11:58:54.780735+00
3	5	Mohamed	Mousa	2002-01-01	MALE	01245587954	UAE	Dubai	Bur Dubai	Alshefa	Heart diseases	84827	2026-03-02 15:53:15.130559+00	2026-03-02 15:53:15.130559+00
\.


--
-- Data for Name: lab_reports; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.lab_reports (id, visit_id, report_url, ai_interpreted_summary, original_text, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: medical_conditions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.medical_conditions (id, name, category, description, created_at, updated_at) FROM stdin;
1	Alzheimer's Disease	CHRONIC	A progressive neurologic disorder that causes the brain to shrink and brain cells to die, leading to memory loss and cognitive decline.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
2	Allergic Asthma	ALLERGY	A subtype of asthma triggered specifically by allergens such as pollen, dust mites, or pet dander, leading to airway inflammation and breathing difficulties.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
3	Allergic Conjunctivitis	ALLERGY	Inflammation of the eye’s conjunctiva due to allergens like pollen or dust, causing red, itchy, watery eyes.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
4	Allergic Rhinitis (Hay Fever)	ALLERGY	Inflammation of the nasal mucous membrane caused by allergens like pollen, resulting in sneezing, runny or stuffy nose, and itchy eyes.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
5	Anaphylaxis	ALLERGY	A severe, potentially life-threatening allergic reaction that can cause airway constriction, a dangerous drop in blood pressure, and shock.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
6	Arthritis	CHRONIC	A chronic condition characterized by inflammation of the joints, causing pain, stiffness, and reduced mobility (umbrella term including osteoarthritis and rheumatoid arthritis).	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
7	Asthma	CHRONIC	A long-term inflammatory disease of the airways that causes wheezing, coughing, chest tightness, and shortness of breath. It can be allergic or non-allergic and requires ongoing management.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
8	Atopic Dermatitis (Eczema)	ALLERGY	A chronic inflammatory skin condition often linked to allergic reactions, characterized by itchiness, redness, and rash.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
9	Contact Dermatitis	ALLERGY	A red, itchy skin rash caused by direct contact with an allergenic substance, such as poison ivy, certain metals, or fragrances.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
10	Coronary Artery Disease	CHRONIC	A common heart condition where the major blood vessels supplying the heart struggle to send enough blood, oxygen, and nutrients.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
11	Cow's Milk Allergy	ALLERGY	An abnormal immune response to the proteins found in cow's milk, primarily affecting infants and young children.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
12	Crohn's Disease	CHRONIC	A type of inflammatory bowel disease (IBD) that causes chronic inflammation of the digestive tract.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
13	Cystic Fibrosis	CHRONIC	A genetic, chronic disease that severely damages the lungs, digestive system, and other organs by producing thick, sticky mucus.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
14	Depression	CHRONIC	A persistent mental health disorder affecting mood, thoughts, and daily functioning.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
15	Diabetes Mellitus	CHRONIC	A chronic condition in which the body cannot properly produce or use insulin, leading to high blood sugar levels.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
16	Drug Allergy	ALLERGY	An immune system reaction to medications that can cause skin rash, itching, hives, or more severe symptoms.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
17	Dust Mite Allergy	ALLERGY	Hypersensitivity to dust mite droppings that triggers symptoms such as sneezing, wheezing, or eczema.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
18	Egg Allergy	ALLERGY	A food allergy triggered by proteins in eggs, leading to symptoms like rash, gastrointestinal upset, or respiratory issues.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
19	Epilepsy	CHRONIC	A central nervous system disorder in which brain activity becomes abnormal, causing repeated seizures.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
20	Endometriosis	CHRONIC	A painful disorder in which tissue similar to the lining of the uterus grows outside the uterus.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
21	Fibromyalgia	CHRONIC	A disorder characterized by widespread musculoskeletal pain accompanied by fatigue, sleep, memory, and mood issues.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
22	Food Allergy	ALLERGY	An immune system reaction to certain foods such as milk, eggs, peanuts, or shellfish, which can cause symptoms from mild to severe anaphylaxis.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
23	Heart Disease (Cardiovascular Disease)	CHRONIC	A group of chronic conditions affecting the heart and blood vessels, including coronary artery disease and heart failure.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
24	Heart Failure	CHRONIC	A chronic, progressive condition in which the heart muscle is unable to pump enough blood to meet the body's needs.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
25	Chronic Kidney Disease	CHRONIC	A condition characterized by a gradual loss of kidney function over time, preventing the body from filtering waste properly.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
26	Chronic Obstructive Pulmonary Disease (COPD)	CHRONIC	A chronic lung disease usually caused by smoking or exposure to irritants, which makes breathing increasingly difficult over time.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
27	Hypertension (High Blood Pressure)	CHRONIC	A long-term condition in which the force of blood against artery walls is high, increasing the risk of heart disease and stroke.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
28	Insect Venom Allergy	ALLERGY	A severe allergic reaction triggered by the stings of insects such as bees, wasps, hornets, and fire ants.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
29	Latex Allergy	ALLERGY	An allergic reaction to specific proteins found in natural rubber latex.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
30	Mold Allergy	ALLERGY	An immune overreaction to mold spores inhaled from the air, causing respiratory and sinus symptoms.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
31	Multiple Sclerosis	CHRONIC	A potentially disabling disease where the immune system attacks the protective myelin sheath that covers nerve fibers.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
32	Obesity	CHRONIC	Excessive body weight leading to numerous health issues including diabetes and heart disease.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
33	Oral Allergy Syndrome	ALLERGY	A type of food allergy classified by a cluster of allergic reactions in the mouth and throat in response to eating certain fresh fruits or nuts.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
34	Osteoarthritis	CHRONIC	The most common form of arthritis, occurring when the protective cartilage that cushions the ends of bones wears down over time.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
35	Osteoporosis	CHRONIC	A bone disease that develops when bone mineral density and bone mass decrease, making bones weak and brittle.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
36	Parkinson's Disease	CHRONIC	A progressive nervous system disorder that affects movement, often presenting with tremors, stiffness, and loss of balance.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
37	Peanut Allergy	ALLERGY	An immune reaction to peanuts that can lead to hives, swelling, asthma symptoms, or anaphylaxis upon exposure.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
38	Pet Dander Allergy	ALLERGY	An allergic reaction to proteins found in an animal's skin cells, saliva, or urine.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
39	Psoriasis	CHRONIC	A chronic skin disease that causes red, itchy, scaly patches, most commonly on the knees, elbows, trunk, and scalp.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
40	Rheumatoid Arthritis	CHRONIC	A chronic inflammatory autoimmune disorder that primarily affects the lining of the joints.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
41	Schizophrenia	CHRONIC	A severe chronic mental disorder in which people interpret reality abnormally, often involving hallucinations and delusions.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
42	Sesame Allergy	ALLERGY	An allergic reaction to sesame seeds, which can cause itching, skin rash, respiratory symptoms, or anaphylaxis.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
43	Shellfish Allergy	ALLERGY	An abnormal immune response to the proteins in certain marine animals, including crustaceans and mollusks.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
44	Systemic Lupus Erythematosus	CHRONIC	A systemic autoimmune disease that occurs when the body's immune system attacks its own tissues and organs.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
45	Tree Nut Allergy	ALLERGY	An allergic reaction to the proteins found in tree nuts, such as walnuts, almonds, cashews, and pistachios.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
46	Type 1 Diabetes	CHRONIC	A chronic autoimmune condition in which the pancreas produces little or no insulin.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
47	Type 2 Diabetes	CHRONIC	A chronic condition that affects the way the body processes blood sugar (glucose), often linked to lifestyle factors.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
48	Urticaria (Hives)	ALLERGY	A skin condition marked by raised, red, itchy welts often from allergic reactions but also other triggers like infections or stress.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
49	Wheat Allergy	ALLERGY	An allergic reaction to foods containing wheat, which can cause symptoms ranging from mild hives to severe anaphylaxis.	2026-02-21 19:05:37.913808+00	2026-02-21 19:05:37.913808+00
\.


--
-- Data for Name: medical_images; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.medical_images (id, visit_id, image_url, image_type, ai_diagnosis, doctor_notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: medical_reports; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.medical_reports (id, visit_id, doctor_id, doctor_voice_transcription, ai_diagnosis, ai_medications, ai_recommendations, ai_follow_up, doctor_notes, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: patient_conditions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.patient_conditions (id, patient_id, condition_id, diagnosed_date, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: patients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.patients (id, first_name, last_name, date_of_birth, gender, national_id, phone, email, address, created_at, updated_at) FROM stdin;
1	Ahmed	Omar	\N	MALE		01115424848	\N		2026-02-25 11:56:56.131199+00	2026-02-25 11:56:56.131199+00
5	Shady	Hany	\N	MALE	1627383847	011245484	\N		2026-03-01 15:32:07.264852+00	2026-03-01 15:32:07.264852+00
7	Ramy	Hassan	\N	MALE	17263815493	0125467844	\N		2026-03-01 15:52:30.295352+00	2026-03-01 15:52:30.295352+00
8	Lila	Ali	\N	MALE	\N	0114248456	\N	\N	2026-03-01 16:35:49.739473+00	2026-03-01 16:35:49.739473+00
9	Mariem	Abdelaziz	\N	MALE	1382372883837	012487604	\N		2026-03-02 14:38:04.356649+00	2026-03-02 14:38:04.356649+00
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, email, password_hash, role, is_active, created_at, updated_at) FROM stdin;
1	admin@system.com	$2b$12$BnkkOPHQS6bk7ynde6/lGuOJhawI6lmltrRd7YgFjeNBc6LtHnXDe	ADMIN	t	2026-02-21 17:28:25.989937+00	2026-02-21 17:28:25.989937+00
2	dr.ahmed@clinic.com	$2b$12$hCL/u7gVqiCJCKkLmmZ7kekmeWGLPuBiarz06W4lsC1Q2Yuu9qaT6	DOCTOR	t	2026-02-21 18:49:26.885352+00	2026-02-21 18:49:26.885352+00
3	assistant@clinic.com	$2b$12$ZZkV8kXx0dsuSoB3eqnxGOzeu00ir3OKvPMS4sWUUwmUPxzcIEFsa	ASSISTANT	t	2026-02-21 18:51:05.829966+00	2026-02-21 18:51:05.829966+00
4	tarekomar30303012615776@gmail.com	$2b$12$p8GVBstwtSXaHGFv7KgrdeGoL87iqWapS5Dy8aV0ua1GJ7.Me0h26	DOCTOR	t	2026-02-25 11:58:54.780735+00	2026-02-25 11:58:54.780735+00
5	mohamedmousaa1004@gmail.com	$2b$12$I0EEbgJe6YoQDecMxBalPu6DT/BLeVnps2nCZssGg1NP/r79t76aa	DOCTOR	t	2026-03-02 15:53:15.130559+00	2026-03-02 15:53:15.130559+00
6	tarekomar1303@gmail.com	$2b$12$pwKNmOQy.gTJcOUM88D2P.K10Ox3FhS9SVXYfQ2g9fz/MPK8cg0WO	ASSISTANT	t	2026-03-02 15:55:08.448163+00	2026-03-02 15:55:08.448163+00
\.


--
-- Data for Name: visits; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.visits (id, appointment_id, chief_complaint, blood_pressure, heart_rate, temperature, weight, height, notes, status, start_time, end_time, created_at, updated_at) FROM stdin;
\.


--
-- Name: admins_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.admins_id_seq', 1, true);


--
-- Name: appointment_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.appointment_types_id_seq', 1, false);


--
-- Name: appointments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.appointments_id_seq', 21, true);


--
-- Name: assistants_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.assistants_id_seq', 2, true);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.audit_logs_id_seq', 155, true);


--
-- Name: doctors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.doctors_id_seq', 3, true);


--
-- Name: lab_reports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.lab_reports_id_seq', 1, false);


--
-- Name: medical_conditions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.medical_conditions_id_seq', 49, true);


--
-- Name: medical_images_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.medical_images_id_seq', 1, false);


--
-- Name: medical_reports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.medical_reports_id_seq', 1, false);


--
-- Name: patient_conditions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.patient_conditions_id_seq', 1, false);


--
-- Name: patients_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.patients_id_seq', 9, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 6, true);


--
-- Name: visits_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.visits_id_seq', 1, false);


--
-- Name: admins admins_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: appointment_types appointment_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointment_types
    ADD CONSTRAINT appointment_types_pkey PRIMARY KEY (id);


--
-- Name: appointments appointments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_pkey PRIMARY KEY (id);


--
-- Name: assistants assistants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assistants
    ADD CONSTRAINT assistants_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: doctors doctors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctors
    ADD CONSTRAINT doctors_pkey PRIMARY KEY (id);


--
-- Name: lab_reports lab_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lab_reports
    ADD CONSTRAINT lab_reports_pkey PRIMARY KEY (id);


--
-- Name: medical_conditions medical_conditions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medical_conditions
    ADD CONSTRAINT medical_conditions_pkey PRIMARY KEY (id);


--
-- Name: medical_images medical_images_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medical_images
    ADD CONSTRAINT medical_images_pkey PRIMARY KEY (id);


--
-- Name: medical_reports medical_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medical_reports
    ADD CONSTRAINT medical_reports_pkey PRIMARY KEY (id);


--
-- Name: patient_conditions patient_conditions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_conditions
    ADD CONSTRAINT patient_conditions_pkey PRIMARY KEY (id);


--
-- Name: patients patients_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT patients_pkey PRIMARY KEY (id);


--
-- Name: admins uq_admins_user_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT uq_admins_user_id UNIQUE (user_id);


--
-- Name: assistants uq_assistants_user_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assistants
    ADD CONSTRAINT uq_assistants_user_id UNIQUE (user_id);


--
-- Name: doctors uq_doctors_license_number; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctors
    ADD CONSTRAINT uq_doctors_license_number UNIQUE (license_number);


--
-- Name: doctors uq_doctors_user_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctors
    ADD CONSTRAINT uq_doctors_user_id UNIQUE (user_id);


--
-- Name: medical_conditions uq_medical_conditions_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medical_conditions
    ADD CONSTRAINT uq_medical_conditions_name UNIQUE (name);


--
-- Name: medical_reports uq_medical_reports_visit_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medical_reports
    ADD CONSTRAINT uq_medical_reports_visit_id UNIQUE (visit_id);


--
-- Name: patient_conditions uq_patient_conditions_patient_condition; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_conditions
    ADD CONSTRAINT uq_patient_conditions_patient_condition UNIQUE (patient_id, condition_id);


--
-- Name: patients uq_patients_national_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT uq_patients_national_id UNIQUE (national_id);


--
-- Name: visits uq_visits_appointment_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visits
    ADD CONSTRAINT uq_visits_appointment_id UNIQUE (appointment_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: visits visits_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visits
    ADD CONSTRAINT visits_pkey PRIMARY KEY (id);


--
-- Name: ix_admins_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_admins_user_id ON public.admins USING btree (user_id);


--
-- Name: ix_appointment_types_doctor_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_appointment_types_doctor_id ON public.appointment_types USING btree (doctor_id);


--
-- Name: ix_appointments_appointment_type_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_appointments_appointment_type_id ON public.appointments USING btree (appointment_type_id);


--
-- Name: ix_appointments_doctor_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_appointments_doctor_id ON public.appointments USING btree (doctor_id);


--
-- Name: ix_appointments_patient_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_appointments_patient_id ON public.appointments USING btree (patient_id);


--
-- Name: ix_appointments_start_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_appointments_start_time ON public.appointments USING btree (start_time);


--
-- Name: ix_appointments_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_appointments_status ON public.appointments USING btree (status);


--
-- Name: ix_assistants_clinic_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_assistants_clinic_name ON public.assistants USING btree (clinic_name);


--
-- Name: ix_assistants_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_assistants_user_id ON public.assistants USING btree (user_id);


--
-- Name: ix_audit_logs_action; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_audit_logs_action ON public.audit_logs USING btree (action);


--
-- Name: ix_audit_logs_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_audit_logs_created_at ON public.audit_logs USING btree (created_at);


--
-- Name: ix_audit_logs_entity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_audit_logs_entity ON public.audit_logs USING btree (entity_type, entity_id);


--
-- Name: ix_audit_logs_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_audit_logs_user_id ON public.audit_logs USING btree (user_id);


--
-- Name: ix_doctors_clinic_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_doctors_clinic_name ON public.doctors USING btree (clinic_name);


--
-- Name: ix_doctors_specialization; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_doctors_specialization ON public.doctors USING btree (specialization);


--
-- Name: ix_doctors_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_doctors_user_id ON public.doctors USING btree (user_id);


--
-- Name: ix_lab_reports_visit_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_lab_reports_visit_id ON public.lab_reports USING btree (visit_id);


--
-- Name: ix_medical_conditions_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_medical_conditions_category ON public.medical_conditions USING btree (category);


--
-- Name: ix_medical_conditions_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_medical_conditions_name ON public.medical_conditions USING btree (name);


--
-- Name: ix_medical_images_image_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_medical_images_image_type ON public.medical_images USING btree (image_type);


--
-- Name: ix_medical_images_visit_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_medical_images_visit_id ON public.medical_images USING btree (visit_id);


--
-- Name: ix_medical_reports_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_medical_reports_created_at ON public.medical_reports USING btree (created_at);


--
-- Name: ix_medical_reports_doctor_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_medical_reports_doctor_id ON public.medical_reports USING btree (doctor_id);


--
-- Name: ix_medical_reports_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_medical_reports_status ON public.medical_reports USING btree (status);


--
-- Name: ix_medical_reports_visit_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_medical_reports_visit_id ON public.medical_reports USING btree (visit_id);


--
-- Name: ix_patient_conditions_condition_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_patient_conditions_condition_id ON public.patient_conditions USING btree (condition_id);


--
-- Name: ix_patient_conditions_patient_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_patient_conditions_patient_id ON public.patient_conditions USING btree (patient_id);


--
-- Name: ix_patients_last_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_patients_last_name ON public.patients USING btree (last_name);


--
-- Name: ix_patients_national_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_patients_national_id ON public.patients USING btree (national_id);


--
-- Name: ix_patients_phone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_patients_phone ON public.patients USING btree (phone);


--
-- Name: ix_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_users_email ON public.users USING btree (email);


--
-- Name: ix_users_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_users_role ON public.users USING btree (role);


--
-- Name: ix_visits_appointment_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_visits_appointment_id ON public.visits USING btree (appointment_id);


--
-- Name: ix_visits_start_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_visits_start_time ON public.visits USING btree (start_time);


--
-- Name: ix_visits_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_visits_status ON public.visits USING btree (status);


--
-- Name: admins admins_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: appointment_types appointment_types_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointment_types
    ADD CONSTRAINT appointment_types_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(id);


--
-- Name: appointments appointments_appointment_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_appointment_type_id_fkey FOREIGN KEY (appointment_type_id) REFERENCES public.appointment_types(id);


--
-- Name: appointments appointments_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(id);


--
-- Name: appointments appointments_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id);


--
-- Name: assistants assistants_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assistants
    ADD CONSTRAINT assistants_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: doctors doctors_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.doctors
    ADD CONSTRAINT doctors_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: lab_reports lab_reports_visit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lab_reports
    ADD CONSTRAINT lab_reports_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES public.visits(id);


--
-- Name: medical_images medical_images_visit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medical_images
    ADD CONSTRAINT medical_images_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES public.visits(id);


--
-- Name: medical_reports medical_reports_doctor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medical_reports
    ADD CONSTRAINT medical_reports_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(id);


--
-- Name: medical_reports medical_reports_visit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medical_reports
    ADD CONSTRAINT medical_reports_visit_id_fkey FOREIGN KEY (visit_id) REFERENCES public.visits(id);


--
-- Name: patient_conditions patient_conditions_condition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_conditions
    ADD CONSTRAINT patient_conditions_condition_id_fkey FOREIGN KEY (condition_id) REFERENCES public.medical_conditions(id);


--
-- Name: patient_conditions patient_conditions_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_conditions
    ADD CONSTRAINT patient_conditions_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patients(id);


--
-- Name: visits visits_appointment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visits
    ADD CONSTRAINT visits_appointment_id_fkey FOREIGN KEY (appointment_id) REFERENCES public.appointments(id);


--
-- PostgreSQL database dump complete
--

\unrestrict hchC3KIRDXi6eN8sdKEiFKnuSpNyyWGYWcrVaCjcu6v2GS1cF15Vz0q4Ix2m04k

