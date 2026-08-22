--
-- PostgreSQL database dump
--

\restrict up8FhLKfDkgz3TBB0CkeVIeTwFETF3gaLMvhw82eBUZqNjbWXrZVt8s3UTJ1e75

-- Dumped from database version 18.4 (Debian 18.4-1.pgdg12+1)
-- Dumped by pg_dump version 18.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id uuid NOT NULL,
    action character varying(30) NOT NULL,
    created_at timestamp(6) without time zone,
    description character varying(200),
    entity_id uuid,
    entity_type character varying(50),
    ip_address character varying(50),
    request_method character varying(10),
    request_path character varying(255),
    user_email character varying(100),
    user_id uuid,
    CONSTRAINT audit_logs_action_check CHECK (((action)::text = ANY ((ARRAY['CREATE'::character varying, 'UPDATE'::character varying, 'DELETE'::character varying, 'TERMINATE'::character varying, 'RENEW'::character varying, 'PAYMENT'::character varying, 'UPLOAD'::character varying, 'ASSIGN'::character varying, 'RESOLVE'::character varying, 'LOGIN'::character varying, 'LOGOUT'::character varying, 'RESET_PASSWORD'::character varying])::text[])))
);


--
-- Name: contracts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contracts (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    deposit_amount numeric(15,2) NOT NULL,
    file_url character varying(255),
    move_in_date date NOT NULL,
    move_out_date date,
    notes text,
    status character varying(20) NOT NULL,
    room_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    CONSTRAINT contracts_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'EXPIRED'::character varying, 'TERMINATED'::character varying])::text[])))
);


--
-- Name: fee_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fee_configs (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    bicycle_price numeric(15,2) DEFAULT 0 NOT NULL,
    car_price numeric(15,2) DEFAULT 0 NOT NULL,
    elec_price numeric(15,2) NOT NULL,
    motorbike_price numeric(15,2) DEFAULT 0 NOT NULL,
    rent_default numeric(15,2) NOT NULL,
    service_fee numeric(15,2) NOT NULL,
    service_pro_rata boolean NOT NULL,
    vehicle_pro_rata boolean NOT NULL,
    water_mode character varying(20) NOT NULL,
    water_price numeric(15,2) NOT NULL,
    property_id uuid NOT NULL,
    CONSTRAINT fee_configs_water_mode_check CHECK (((water_mode)::text = ANY ((ARRAY['PERSON'::character varying, 'CUBIC'::character varying])::text[])))
);


--
-- Name: invoices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoices (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    checkout_url character varying(255),
    days_used integer,
    due_date date NOT NULL,
    elec_amount numeric(15,2) NOT NULL,
    invoice_month date NOT NULL,
    paid_at timestamp(6) without time zone,
    payment_link_id character varying(255),
    payment_method character varying(20),
    is_pro_rata boolean NOT NULL,
    rent_amount numeric(15,2) NOT NULL,
    service_amount numeric(15,2) NOT NULL,
    status character varying(20) NOT NULL,
    total_amount numeric(15,2) NOT NULL,
    transaction_id character varying(255),
    vehicle_amount numeric(15,2) NOT NULL,
    water_amount numeric(15,2) NOT NULL,
    contract_id uuid NOT NULL,
    room_id uuid NOT NULL,
    CONSTRAINT invoices_payment_method_check CHECK (((payment_method)::text = ANY ((ARRAY['PAYOS'::character varying, 'CASH'::character varying])::text[]))),
    CONSTRAINT invoices_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'PAID'::character varying, 'OVERDUE'::character varying])::text[])))
);


--
-- Name: maintenance_completion_images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance_completion_images (
    request_id uuid NOT NULL,
    image_url character varying(255)
);


--
-- Name: maintenance_images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance_images (
    request_id uuid NOT NULL,
    image_url character varying(255)
);


--
-- Name: maintenance_materials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance_materials (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    is_free_in_contract boolean,
    name character varying(100) NOT NULL,
    quantity integer NOT NULL,
    total_price numeric(15,2) NOT NULL,
    unit character varying(20) NOT NULL,
    unit_price numeric(15,2) NOT NULL,
    request_id uuid NOT NULL
);


--
-- Name: maintenance_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance_notes (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    note text NOT NULL,
    status character varying(20),
    actor_id uuid,
    request_id uuid NOT NULL,
    CONSTRAINT maintenance_notes_status_check CHECK (((status)::text = ANY ((ARRAY['OPEN'::character varying, 'ASSIGNED'::character varying, 'IN_PROGRESS'::character varying, 'PENDING_PAYMENT'::character varying, 'PENDING_REVIEW'::character varying, 'COMPLETED'::character varying, 'CANCELLED'::character varying, 'DONE'::character varying])::text[])))
);


--
-- Name: maintenance_preferred_slots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance_preferred_slots (
    request_id uuid NOT NULL,
    time_slot character varying(255)
);


--
-- Name: maintenance_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance_requests (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    attachment_video character varying(255),
    cancel_reason text,
    category character varying(30) NOT NULL,
    complain_reason text,
    confirm_slot_by_tenant boolean,
    confirmed_time_slot character varying(100),
    description text,
    expected_resolved_at timestamp(6) without time zone,
    is_complained boolean,
    is_overdue_sla boolean,
    material_cost numeric(15,2),
    material_paid_at timestamp(6) without time zone,
    priority character varying(20) NOT NULL,
    resolved_at timestamp(6) without time zone,
    started_at timestamp(6) without time zone,
    status character varying(20) NOT NULL,
    ticket_code character varying(30),
    title character varying(200) NOT NULL,
    assigned_to uuid,
    room_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    slot_declined_by_tenant boolean,
    completion_video character varying(255),
    CONSTRAINT maintenance_requests_category_check CHECK (((category)::text = ANY ((ARRAY['ELECTRIC'::character varying, 'PLUMBING'::character varying, 'AIR_CONDITIONER'::character varying, 'FURNITURE'::character varying, 'OTHER'::character varying])::text[]))),
    CONSTRAINT maintenance_requests_priority_check CHECK (((priority)::text = ANY ((ARRAY['NORMAL'::character varying, 'HIGH'::character varying, 'URGENT'::character varying])::text[]))),
    CONSTRAINT maintenance_requests_status_check CHECK (((status)::text = ANY ((ARRAY['OPEN'::character varying, 'ASSIGNED'::character varying, 'IN_PROGRESS'::character varying, 'PENDING_PAYMENT'::character varying, 'PENDING_REVIEW'::character varying, 'COMPLETED'::character varying, 'CANCELLED'::character varying, 'DONE'::character varying])::text[])))
);


--
-- Name: maintenance_reviews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance_reviews (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    comment character varying(1000),
    rating_stars integer NOT NULL,
    request_id uuid NOT NULL,
    technician_id uuid NOT NULL,
    tenant_id uuid NOT NULL
);


--
-- Name: meter_readings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.meter_readings (
    id uuid NOT NULL,
    elec_new bigint NOT NULL,
    elec_old bigint NOT NULL,
    reading_month date NOT NULL,
    recorded_at timestamp(6) without time zone NOT NULL,
    source character varying(20) NOT NULL,
    water_new bigint,
    water_old bigint,
    recorded_by uuid NOT NULL,
    room_id uuid NOT NULL,
    CONSTRAINT meter_readings_source_check CHECK (((source)::text = ANY ((ARRAY['MANUAL'::character varying, 'HUNONIC'::character varying])::text[])))
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id uuid NOT NULL,
    body text,
    created_at timestamp(6) without time zone NOT NULL,
    is_read boolean NOT NULL,
    ref_id uuid,
    title character varying(200) NOT NULL,
    type character varying(50),
    user_id uuid NOT NULL
);


--
-- Name: payment_event_receipts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_event_receipts (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    applied boolean NOT NULL,
    event_key character varying(255) NOT NULL,
    order_code character varying(255) NOT NULL,
    transaction_id character varying(255)
);


--
-- Name: payment_intents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_intents (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    checkout_url character varying(255),
    order_code character varying(255) NOT NULL,
    status character varying(30) NOT NULL,
    invoice_id uuid NOT NULL
);


--
-- Name: properties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.properties (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    address text NOT NULL,
    description text,
    floor_count integer,
    name character varying(100) NOT NULL,
    room_count integer,
    owner_id uuid NOT NULL,
    type uuid NOT NULL
);


--
-- Name: property_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.property_types (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    active boolean NOT NULL,
    code character varying(50) NOT NULL,
    description text,
    name character varying(100) NOT NULL
);


--
-- Name: room_images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.room_images (
    room_id uuid NOT NULL,
    image_url character varying(255)
);


--
-- Name: room_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.room_notes (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    content text NOT NULL,
    author_id uuid NOT NULL,
    room_id uuid NOT NULL
);


--
-- Name: rooms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rooms (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    area_m2 numeric(5,2),
    floor integer,
    max_people integer NOT NULL,
    rent_override numeric(15,2),
    room_number character varying(20) NOT NULL,
    status character varying(20) NOT NULL,
    property_id uuid NOT NULL,
    CONSTRAINT rooms_status_check CHECK (((status)::text = ANY ((ARRAY['EMPTY'::character varying, 'RENTED'::character varying, 'MAINTENANCE'::character varying])::text[])))
);


--
-- Name: sla_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sla_rules (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    category character varying(30) NOT NULL,
    max_hours integer NOT NULL,
    priority character varying(30) NOT NULL,
    CONSTRAINT sla_rules_category_check CHECK (((category)::text = ANY ((ARRAY['ELECTRIC'::character varying, 'PLUMBING'::character varying, 'AIR_CONDITIONER'::character varying, 'FURNITURE'::character varying, 'OTHER'::character varying])::text[]))),
    CONSTRAINT sla_rules_priority_check CHECK (((priority)::text = ANY ((ARRAY['NORMAL'::character varying, 'HIGH'::character varying, 'URGENT'::character varying])::text[])))
);


--
-- Name: upload_batch_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.upload_batch_items (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    content_type character varying(100),
    object_name character varying(255) NOT NULL,
    size_bytes bigint NOT NULL,
    status character varying(30) NOT NULL,
    batch_id uuid NOT NULL
);


--
-- Name: upload_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.upload_batches (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    cleanup_required boolean NOT NULL,
    domain_id uuid,
    domain_type character varying(40) NOT NULL,
    idempotency_key character varying(255) NOT NULL,
    status character varying(30) NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    is_active boolean NOT NULL,
    avatar_url character varying(255),
    email character varying(100) NOT NULL,
    full_name character varying(100) NOT NULL,
    password_hash character varying(255) NOT NULL,
    phone character varying(20),
    role character varying(30) NOT NULL,
    specialties character varying(255),
    auth_version bigint DEFAULT 0 NOT NULL,
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['ADMIN'::character varying, 'TENANT'::character varying, 'TECHNICIAN'::character varying])::text[])))
);


--
-- Name: vehicle_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicle_records (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    bicycle_count integer NOT NULL,
    car_count integer NOT NULL,
    motorbike_count integer NOT NULL,
    record_month date NOT NULL,
    room_id uuid NOT NULL
);


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.audit_logs (id, action, created_at, description, entity_id, entity_type, ip_address, request_method, request_path, user_email, user_id) FROM stdin;
400a7106-683d-4b2e-bc4d-39ca3a3d6760	CREATE	2026-07-26 13:09:01.626541	POST /api/users	\N	User	104.23.160.125	POST	/api/users	\N	\N
313e22a6-daba-4929-ba1c-3f9561da8f14	CREATE	2026-07-26 13:09:31.022655	POST /api/users	\N	User	104.23.160.66	POST	/api/users	\N	\N
33a03da8-5736-433f-bc51-256bcbe399e9	UPDATE	2026-07-26 13:10:04.919068	PUT /api/users/c5d65edf-fb24-4f93-b966-362f36e78370	\N	User	172.71.215.160	PUT	/api/users/c5d65edf-fb24-4f93-b966-362f36e78370	\N	\N
97231e7a-4e29-4c9b-b680-39b642df94fc	CREATE	2026-07-26 13:13:22.728366	POST /api/users	\N	User	104.23.160.125	POST	/api/users	\N	\N
e3168c72-5bb5-4f23-bae6-7d1824768932	CREATE	2026-07-26 13:13:46.91801	POST /api/users	\N	User	104.23.160.125	POST	/api/users	\N	\N
479f5087-b8c6-4d3f-9c17-a862cf7ff09b	CREATE	2026-07-26 13:15:06.624858	POST /api/users	\N	User	162.158.114.171	POST	/api/users	\N	\N
3843c2cf-8b70-47fb-9c9a-dff59b917d89	CREATE	2026-07-26 14:01:02.251125	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	162.159.98.56	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
7614e9f1-ca79-47fa-b0fc-dcfec299dc70	CREATE	2026-07-26 16:12:07.20605	POST /api/invoices/generate	\N	Invoice	162.158.179.49	POST	/api/invoices/generate	\N	\N
3e40a5e2-4d05-4c2d-84e0-1f347d248d15	CREATE	2026-07-27 04:54:03.801179	POST /api/properties	\N	Property	172.69.176.62	POST	/api/properties	\N	\N
5613ab4b-ddf4-45d1-bb23-dc7a5d679671	CREATE	2026-07-27 04:55:06.417844	POST /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms	\N	Property	172.69.176.62	POST	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms	\N	\N
6c7178b3-ab80-4b9f-9c60-7948960b9660	UPDATE	2026-07-27 04:55:13.517646	PUT /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	104.23.175.246	PUT	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
3248945c-348f-4c2f-9e3f-274d04b42833	CREATE	2026-07-27 04:55:31.823217	POST /api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/notes	\N	Room	172.71.152.77	POST	/api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/notes	\N	\N
47331545-56a9-4a4f-8da4-956d3689a06d	CREATE	2026-07-27 04:55:49.5703	POST /api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/notes	\N	Room	104.23.175.246	POST	/api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/notes	\N	\N
fa006a49-b1f5-4f90-985f-0b045e302f96	UPDATE	2026-07-27 04:56:31.275452	PUT /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.165.32	PUT	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
6c05b110-93ed-4d15-9cce-455e56056bd5	DELETE	2026-07-27 04:56:50.308166	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.165.32	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
d4e65229-d97d-423e-bb0c-313d5bfa3b3e	DELETE	2026-07-27 04:56:50.804888	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.68.164.63	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
43afc268-4828-4f01-bbdd-02c1230faa2b	DELETE	2026-07-27 04:56:52.083316	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.176.62	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
ad1f7015-8e5d-412e-a3c7-81d1176853d1	DELETE	2026-07-27 04:56:52.416015	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.165.32	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
21971544-c42c-4408-a2ad-90996e36e76d	DELETE	2026-07-27 04:56:54.174696	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.165.32	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
564a6781-6490-43de-bcfc-cd867cbc416a	DELETE	2026-07-27 04:56:54.483087	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.165.32	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
0d20f896-c770-4e86-88c1-ff7f9b13dd9c	DELETE	2026-07-27 04:56:55.20826	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.176.62	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
9e3c7762-ad17-4c03-9ac0-a69e31041069	DELETE	2026-07-27 04:56:55.4011	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.176.62	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
5ce50e10-35df-44e6-9d76-6d08be8bc53a	DELETE	2026-07-27 04:56:56.001727	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.176.62	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
a5baacd2-e4c7-42e6-9963-3e18ce338307	DELETE	2026-07-27 04:56:56.40555	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.165.32	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
d33d8d23-ec91-4aeb-8046-a5ef4af9f09d	DELETE	2026-07-27 04:56:56.702384	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.165.32	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
f244df0e-6deb-41e1-9b8b-30973a6a07c6	DELETE	2026-07-27 04:56:56.902468	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.176.62	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
3f365171-e548-4271-92c6-581a0f0020be	DELETE	2026-07-27 04:56:57.48155	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.176.62	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
16293737-0004-4283-a8b8-dba7a63088e9	DELETE	2026-07-27 04:56:57.80161	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.176.62	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
f1c80491-6944-4df8-bd14-08246fa7f78f	DELETE	2026-07-27 04:56:58.317952	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.68.164.63	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
5d2b3e0e-0769-45fb-8be3-64806c495e9f	DELETE	2026-07-27 04:56:58.483775	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.176.62	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
ef3e1e29-5423-4f9f-b183-93e83f854dc7	DELETE	2026-07-27 04:56:59.007408	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.176.62	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
f366787a-cb53-453d-a5d6-5130f0158f2f	DELETE	2026-07-27 04:56:59.211292	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.68.164.63	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
ad1b27e6-9bc6-4b11-b35e-2289f34445b1	CREATE	2026-07-27 07:08:15.450949	POST /api/maintenance/with-images	\N	MaintenanceRequest	162.158.179.50	POST	/api/maintenance/with-images	\N	\N
6908afad-21a9-4e95-972a-92d36bb2b304	DELETE	2026-07-27 04:57:02.857575	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.68.164.63	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
e4492391-b4bf-4c25-ac14-391e2082ad8a	DELETE	2026-07-27 04:57:03.095587	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.68.164.63	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
f4daa4ae-be0e-4bb6-9e72-34b44765c8f6	DELETE	2026-07-27 04:57:04.09228	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.165.32	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
07e3a41f-24b9-4778-8828-6d0b610dc646	DELETE	2026-07-27 04:57:04.50848	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.68.164.63	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
65d5762f-09e2-45e6-9389-4bab4be8d61c	UPDATE	2026-07-27 04:57:21.849139	PUT /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.176.62	PUT	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
a1acb977-2c75-4a7e-845b-8a8f3038df91	DELETE	2026-07-27 04:57:29.542421	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.176.62	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
c69c209b-235e-40bb-996e-3701f45b2fdd	DELETE	2026-07-27 04:57:30.249345	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.165.32	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
b8ce0ceb-dabc-4cbc-936b-313124168408	DELETE	2026-07-27 04:57:30.434605	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.68.164.63	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
73b47d7a-c281-4e63-a037-9c383353d85c	DELETE	2026-07-27 04:57:30.957646	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.68.164.63	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
dbbdb4e9-ed5b-4fe0-99df-bd69a6f1a4fe	DELETE	2026-07-27 04:57:31.11758	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.176.62	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
97358539-12db-4148-a21f-f4f98a59a4c3	DELETE	2026-07-27 04:57:31.686081	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.165.32	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
4463a934-c6d5-47b3-8f00-dea9270e2e6c	DELETE	2026-07-27 04:57:31.850185	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.165.32	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
b9c21349-d9c5-4b52-9da8-8aa241b3e756	DELETE	2026-07-27 04:57:32.621764	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.68.164.63	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
3276f95e-81df-4a81-a38d-2f9e0ab92d2f	DELETE	2026-07-27 04:57:33.304909	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.165.32	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
e7dd56f6-1404-46c0-b60e-489b33dcc807	DELETE	2026-07-27 04:57:33.642028	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.176.62	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
e1db24ba-f097-4788-adb4-2e24983c4e73	DELETE	2026-07-27 04:57:33.878483	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.68.164.63	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
06cb05c2-d863-4f15-a169-1fd898c3fa7b	CREATE	2026-08-06 13:08:53.084847	POST /api/rooms/b5000000-0000-0000-0000-000000000002/meter-readings	\N	Room	104.23.175.246	POST	/api/rooms/b5000000-0000-0000-0000-000000000002/meter-readings	\N	\N
938cc314-e134-429f-a7dc-2509471d8a46	CREATE	2026-08-06 13:09:51.335477	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	172.71.81.83	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
334f99d8-92b4-4b54-9cf1-54eeda31bc0b	CREATE	2026-08-06 13:10:31.733611	POST /api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	Room	172.71.152.78	POST	/api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	\N
49b26e18-bc49-4fcf-a48a-8bb7b9a34189	CREATE	2026-08-06 13:10:48.079661	POST /api/rooms/b5000000-0000-0000-0000-000000000003/meter-readings	\N	Room	172.71.218.225	POST	/api/rooms/b5000000-0000-0000-0000-000000000003/meter-readings	\N	\N
91752751-7c1b-4350-b86b-75249a45c616	CREATE	2026-08-06 13:11:11.893833	POST /api/rooms/b5000000-0000-0000-0000-000000000010/meter-readings	\N	Room	172.71.152.77	POST	/api/rooms/b5000000-0000-0000-0000-000000000010/meter-readings	\N	\N
beded52f-8df4-4b10-90a4-6fdcb6370f46	CREATE	2026-08-06 13:15:46.419583	POST /api/invoices/generate	\N	Invoice	162.158.179.49	POST	/api/invoices/generate	\N	\N
cd29f241-96d8-47bf-874b-8d65f2687026	CREATE	2026-08-06 13:17:46.200211	POST /api/invoices/generate	\N	Invoice	172.71.215.15	POST	/api/invoices/generate	\N	\N
bf5fca40-cb07-41e3-a131-a85d8d78c201	CREATE	2026-08-06 13:19:15.105865	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	104.23.175.246	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
99a6d4fe-1e88-441d-a28a-5981edb82a49	CREATE	2026-08-06 13:19:16.514241	POST /api/invoices/generate	\N	Invoice	172.71.152.77	POST	/api/invoices/generate	\N	\N
3618ed12-76b3-4278-aafd-9b5ea733282f	CREATE	2026-08-06 13:22:33.851096	POST /api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	Room	172.71.81.83	POST	/api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	\N
05ffb021-b2bf-43e7-ad99-82d40e4580a5	CREATE	2026-08-09 15:42:42.88164	POST /api/invoices/generate	\N	Invoice	172.68.211.105	POST	/api/invoices/generate	\N	\N
4431921f-cfbe-4b96-9a5b-ae446581e417	CREATE	2026-08-09 15:56:07.995428	POST /api/rooms/b5000000-0000-0000-0000-000000000010/meter-readings	\N	Room	162.158.88.170	POST	/api/rooms/b5000000-0000-0000-0000-000000000010/meter-readings	\N	\N
0eeb4fc0-0544-4840-9e1e-9017e698bc1c	DELETE	2026-07-27 04:57:04.90223	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.165.32	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
d4fbcc53-57fa-488c-b092-2a11a9f018ba	DELETE	2026-07-27 04:57:05.312888	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.68.164.63	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
120c44ec-5853-490f-9237-acc610c81a03	DELETE	2026-07-27 04:57:28.98143	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.165.32	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
7cbec923-aed7-4b06-a208-b670621299cf	DELETE	2026-07-27 04:57:29.157505	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.176.62	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
2ddb7913-40c7-4c14-8012-292af1e3bbac	DELETE	2026-07-27 04:57:29.71825	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.68.164.63	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
dddb1493-bdd6-4746-9c1e-66e035128ff9	DELETE	2026-07-27 04:57:32.41871	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.68.164.63	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
f9cd2071-be32-42e1-a575-eb3044458874	DELETE	2026-07-27 04:57:33.013311	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.165.32	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
e27fdc7a-e6d9-4aef-9588-bc3defd481e6	DELETE	2026-07-27 05:00:00.502182	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.69.165.32	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
2a5e348d-d987-4c0c-aedb-36fe06c4a2d0	DELETE	2026-07-27 05:00:01.005853	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.70.143.169	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
c4512e98-f4eb-4ec9-8237-6f7351389f28	DELETE	2026-07-27 05:00:15.001525	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	172.69.165.33	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
cf32ea63-ce47-4614-9d69-248189436f91	DELETE	2026-07-27 05:00:15.41801	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	172.69.165.32	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
8a36254c-b288-4573-af70-8ad4b4d75d59	DELETE	2026-07-27 05:00:48.402134	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	172.69.165.32	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
d63fb963-4245-4acc-a769-f7ba719c662c	DELETE	2026-07-27 05:00:48.914374	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	172.71.152.78	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
f45c8e04-8943-4d52-844c-ac92773d6490	CREATE	2026-07-27 06:53:32.302889	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.81.83	POST	/api/maintenance/with-images	\N	\N
f43fb5c0-e820-4a95-a369-0f6ae1e711a2	CREATE	2026-07-27 06:53:33.24309	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.68.211.105	POST	/api/maintenance/with-images	\N	\N
a44a38ec-2401-48af-92b5-0271aed0454d	CREATE	2026-07-27 06:53:39.6337	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.68.211.105	POST	/api/maintenance/with-images	\N	\N
391bc8b1-c6f9-47a5-a5e5-e028779e95d8	CREATE	2026-07-27 06:53:40.302338	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.81.83	POST	/api/maintenance/with-images	\N	\N
a1aaf4b2-87e2-4578-bbed-206768c056a0	CREATE	2026-07-27 06:53:59.027227	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.22.66.48	POST	/api/maintenance/with-images	\N	\N
f5fb1a76-d2de-4968-83b4-95660204a23f	CREATE	2026-07-27 06:53:59.601977	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.81.83	POST	/api/maintenance/with-images	\N	\N
ed4b5266-c630-4c06-ada7-5a451912a080	CREATE	2026-07-27 06:57:48.972244	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/with-images	\N	\N
a5d7e1c4-287c-4636-a2a9-3e7707538167	CREATE	2026-07-27 06:57:49.507722	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/with-images	\N	\N
35a7a58e-8ab7-4403-a935-4e1b93ea7225	CREATE	2026-07-27 06:58:00.236913	POST /api/notifications/9a854c32-b4c4-46f5-83cc-638de789e5ed/read	\N	Notification	172.68.211.104	POST	/api/notifications/9a854c32-b4c4-46f5-83cc-638de789e5ed/read	\N	\N
4fc9b91d-f76a-4297-9d09-2c369e4550d2	CREATE	2026-07-27 06:58:57.932637	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/with-images	\N	\N
565e6aa5-ea8e-4072-90d8-e8e471ea8475	CREATE	2026-07-27 06:58:58.522905	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/with-images	\N	\N
54880278-6ea1-4e1c-8e43-c16b1e06ebfb	CREATE	2026-07-27 06:59:03.027304	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/with-images	\N	\N
e9d5a9d3-6c3d-4255-b0aa-599c5307acdc	CREATE	2026-07-27 06:59:03.51215	POST /api/maintenance/with-images	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/with-images	\N	\N
efa0309b-c757-44b2-9247-1bb4588644d9	CREATE	2026-07-27 07:04:09.700686	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.81.84	POST	/api/maintenance/with-images	\N	\N
a42572c6-02eb-43ae-921c-fdea00fd7112	CREATE	2026-07-27 07:04:10.101413	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.82.19	POST	/api/maintenance/with-images	\N	\N
aaec6823-9801-4bdb-9faf-083a9b4ce654	CREATE	2026-07-27 07:04:20.626497	POST /api/maintenance/with-images	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/with-images	\N	\N
32bf1d4d-9006-40a3-b7cb-aff3d3d85b19	CREATE	2026-07-27 07:04:21.036493	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.23.175.144	POST	/api/maintenance/with-images	\N	\N
f8f07f58-fc90-4ee6-a55c-e193115b0e65	CREATE	2026-07-27 07:04:46.718505	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.23.175.144	POST	/api/maintenance/with-images	\N	\N
3de3f99f-31e0-48e6-a19d-8d7f2791e200	CREATE	2026-07-27 07:04:47.040638	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.23.175.144	POST	/api/maintenance/with-images	\N	\N
2b818595-7b8d-40a4-8f46-8b5795b9892e	CREATE	2026-07-27 07:04:53.603806	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.81.84	POST	/api/maintenance/with-images	\N	\N
c3feb355-c33e-4241-b187-ebe4878e4988	CREATE	2026-07-27 07:04:54.004822	POST /api/maintenance/with-images	\N	MaintenanceRequest	162.158.114.170	POST	/api/maintenance/with-images	\N	\N
2d86d190-3cd1-4c7b-982b-18aee16e5c83	CREATE	2026-07-27 07:05:01.101117	POST /api/maintenance/with-images	\N	MaintenanceRequest	162.158.114.170	POST	/api/maintenance/with-images	\N	\N
93c2dc01-b5ae-4517-869e-5ab43860635f	CREATE	2026-07-27 07:05:01.723776	POST /api/maintenance/with-images	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/with-images	\N	\N
ede4cf07-fa3a-4ad1-b385-adbe6a118cf1	CREATE	2026-07-27 07:07:52.524339	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.23.175.145	POST	/api/maintenance/with-images	\N	\N
4f96656e-12ab-4c5d-a29d-c66d636b53d1	CREATE	2026-07-27 07:07:52.995861	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.22.66.48	POST	/api/maintenance/with-images	\N	\N
45eae991-dc57-4c36-99ec-d6d980bb0bf8	CREATE	2026-07-27 07:08:15.118396	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/with-images	\N	\N
cf842c0c-791c-4a10-8bde-06704ce15976	CREATE	2026-07-27 07:08:58.53275	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/with-images	\N	\N
a58e844f-e203-41ec-8432-85836341e14c	CREATE	2026-07-27 07:10:19.516084	POST /api/maintenance/with-images	\N	MaintenanceRequest	162.158.179.50	POST	/api/maintenance/with-images	\N	\N
2e754678-5962-4984-92c8-46ea1cb114ee	CREATE	2026-08-06 13:08:56.522187	POST /api/invoices/generate	\N	Invoice	172.71.81.83	POST	/api/invoices/generate	\N	\N
c86bead8-b128-4239-aa20-2691bd8307a6	CREATE	2026-08-06 13:09:08.717595	POST /api/invoices/generate	\N	Invoice	172.71.152.77	POST	/api/invoices/generate	\N	\N
5717b0f9-e6ab-4b4d-a050-e48099382b48	CREATE	2026-08-06 13:11:35.759108	POST /api/rooms/b5000000-0000-0000-0000-000000000013/meter-readings	\N	Room	162.158.114.171	POST	/api/rooms/b5000000-0000-0000-0000-000000000013/meter-readings	\N	\N
392d8782-e844-484a-ab7e-b1bbafa74e08	CREATE	2026-08-06 13:12:41.316668	POST /api/invoices/generate	\N	Invoice	162.159.98.51	POST	/api/invoices/generate	\N	\N
be127cec-c062-4595-8129-fb1a75db9d65	CREATE	2026-08-06 13:12:55.847656	POST /api/invoices/generate	\N	Invoice	172.71.215.16	POST	/api/invoices/generate	\N	\N
72c6da1e-3574-4359-9b44-baa9c373fd20	CREATE	2026-08-06 13:13:06.094117	POST /api/invoices/generate	\N	Invoice	172.71.81.83	POST	/api/invoices/generate	\N	\N
c03f5ddf-bbac-4978-a59c-0d793cae8c52	CREATE	2026-08-06 13:13:22.99049	POST /api/invoices/generate	\N	Invoice	172.71.152.78	POST	/api/invoices/generate	\N	\N
cdcd71cf-10fa-4310-9634-3af72bc23f50	CREATE	2026-08-06 13:15:39.996597	POST /api/invoices/generate	\N	Invoice	162.158.179.49	POST	/api/invoices/generate	\N	\N
5751b7ff-c237-4b69-b69a-847a767ccdd8	CREATE	2026-08-06 13:17:26.14242	POST /api/invoices/generate	\N	Invoice	162.158.193.196	POST	/api/invoices/generate	\N	\N
2e176a2a-17cd-4703-ad8d-2ef9bb20b840	CREATE	2026-08-06 13:17:38.696715	POST /api/invoices/generate	\N	Invoice	162.158.114.170	POST	/api/invoices/generate	\N	\N
7d5ed2d0-bf2e-40b8-a38a-2aa959c5d22e	CREATE	2026-08-09 15:53:45.379361	POST /api/invoices/generate	\N	Invoice	172.71.215.15	POST	/api/invoices/generate	\N	\N
dc31ae9c-0995-498e-84b7-3bf87b5c1de9	CREATE	2026-08-09 15:55:57.46623	POST /api/rooms/b5000000-0000-0000-0000-000000000002/meter-readings	\N	Room	104.23.175.247	POST	/api/rooms/b5000000-0000-0000-0000-000000000002/meter-readings	\N	\N
e29412dc-7e2c-458d-ae6b-b8d86b8fea4e	CREATE	2026-08-09 15:55:58.580551	POST /api/rooms/b5000000-0000-0000-0000-000000000024/meter-readings	\N	Room	162.158.107.33	POST	/api/rooms/b5000000-0000-0000-0000-000000000024/meter-readings	\N	\N
a54868c0-a12c-4e31-91c2-4d7b8ad367fc	CREATE	2026-08-09 15:56:00.287125	POST /api/rooms/b5000000-0000-0000-0000-000000000014/meter-readings	\N	Room	104.23.175.247	POST	/api/rooms/b5000000-0000-0000-0000-000000000014/meter-readings	\N	\N
632f1317-12fd-44ae-810f-98b69e7a1c4b	CREATE	2026-08-09 15:56:01.090853	POST /api/rooms/b5000000-0000-0000-0000-000000000018/meter-readings	\N	Room	172.69.165.32	POST	/api/rooms/b5000000-0000-0000-0000-000000000018/meter-readings	\N	\N
7bdcdab8-007e-4f5e-a9a8-d6d042b56209	CREATE	2026-08-09 15:56:09.879596	POST /api/rooms/b5000000-0000-0000-0000-000000000021/meter-readings	\N	Room	162.159.98.236	POST	/api/rooms/b5000000-0000-0000-0000-000000000021/meter-readings	\N	\N
ae62b73a-ab5c-4acd-a254-98800f026bfa	CREATE	2026-08-09 15:56:12.695378	POST /api/rooms/b5000000-0000-0000-0000-000000000003/meter-readings	\N	Room	162.159.98.236	POST	/api/rooms/b5000000-0000-0000-0000-000000000003/meter-readings	\N	\N
8c18ad27-0d45-4e01-9453-7c8a578ad481	CREATE	2026-08-09 15:56:14.397154	POST /api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	Room	162.158.179.50	POST	/api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	\N
165e5f67-2713-4402-8dbe-dc86d9ef1a5d	CREATE	2026-08-09 15:56:22.395538	POST /api/invoices/generate	\N	Invoice	104.23.175.246	POST	/api/invoices/generate	\N	\N
c9bfed84-928f-461d-8222-87edd2f34511	CREATE	2026-08-09 16:01:33.697204	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.215.15	POST	/api/maintenance/with-images	\N	\N
03a427ce-4eae-4159-87cb-13e06785969b	CREATE	2026-07-27 07:08:58.871745	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.23.175.145	POST	/api/maintenance/with-images	\N	\N
7fae6b1f-1aad-47df-9be2-681d4bf99955	CREATE	2026-07-27 07:10:18.401283	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.23.175.145	POST	/api/maintenance/with-images	\N	\N
9e915c1c-21a3-4d1e-a1e0-8b774b958231	CREATE	2026-07-27 08:01:59.810082	POST /api/invoices/generate	\N	Invoice	172.69.176.62	POST	/api/invoices/generate	\N	\N
afe369e6-91b0-42a9-a9b5-49c9cb5595ad	UPDATE	2026-07-27 08:07:58.009091	PUT /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/fee-config	\N	Property	104.23.175.145	PUT	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/fee-config	\N	\N
c2d521c4-348e-483a-8af2-f448d82090f7	UPDATE	2026-07-27 08:10:18.474801	PUT /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/fee-config	\N	Property	104.22.66.48	PUT	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/fee-config	\N	\N
c5cdf6e5-f216-4297-9b2a-9fb5d13525bd	CREATE	2026-07-27 08:14:34.033087	POST /api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	Room	108.162.227.51	POST	/api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	\N
58a1faef-2511-4741-bc98-86892fd2fc7f	CREATE	2026-07-27 08:14:40.001526	POST /api/invoices/generate	\N	Invoice	172.71.218.225	POST	/api/invoices/generate	\N	\N
3144da53-0fea-40b4-8808-a844550a6269	CREATE	2026-07-27 08:18:27.257267	POST /api/invoices/generate	\N	Invoice	172.68.164.62	POST	/api/invoices/generate	\N	\N
0204dedf-dc6f-4590-848d-f752bd37dcd7	CREATE	2026-07-27 08:19:16.253555	POST /api/rooms/b5000000-0000-0000-0000-000000000001/notes	\N	Room	104.22.66.49	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/notes	\N	\N
ccbc9de7-4fa0-41f0-9ebd-698b9ac9f573	CREATE	2026-07-27 08:24:12.494305	POST /api/notifications/69c54269-c89c-4b2b-ae51-0a338ee41d91/read	\N	Notification	172.69.165.32	POST	/api/notifications/69c54269-c89c-4b2b-ae51-0a338ee41d91/read	\N	\N
55741cec-405e-467a-b52e-150d7cc215c3	TERMINATE	2026-07-27 08:24:59.301281	POST /api/contracts/b6000000-0000-0000-0000-000000000013/terminate	\N	Contract	172.71.152.77	POST	/api/contracts/b6000000-0000-0000-0000-000000000013/terminate	\N	\N
164d1d85-5d2b-4cfa-9fcd-8c1fd651707f	CREATE	2026-07-27 08:26:28.624679	POST /api/notifications/4bf68dd2-122e-4a0f-8b40-31f452f1529e/read	\N	Notification	108.162.227.52	POST	/api/notifications/4bf68dd2-122e-4a0f-8b40-31f452f1529e/read	\N	\N
49a67eec-2fd5-4e4e-97ea-1bff626b5b20	UPDATE	2026-07-27 08:28:35.202194	PUT /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	104.22.66.40	PUT	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
6791e129-1e9a-4ad5-9545-513ce7ed5872	CREATE	2026-07-27 08:30:48.015488	POST /api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/contracts	\N	Room	104.22.66.49	POST	/api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/contracts	\N	\N
b1b547a9-747b-48d1-8085-a3d606a8a4bd	CREATE	2026-07-27 08:46:17.501284	POST /api/invoices/generate	\N	Invoice	172.71.124.13	POST	/api/invoices/generate	\N	\N
281ed252-5d5e-4af8-a590-8be935c6ba8f	CREATE	2026-07-27 08:47:00.631793	POST /api/invoices/generate	\N	Invoice	162.158.108.108	POST	/api/invoices/generate	\N	\N
587fda6c-68e6-4456-9aa0-d4627044ff82	PAYMENT	2026-07-27 09:22:37.630538	POST /api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-online	\N	Invoice	172.69.176.62	POST	/api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-online	\N	\N
60b92000-100f-4d93-8a1a-54375e688a71	PAYMENT	2026-07-27 09:22:37.816332	POST /api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-online	\N	Invoice	172.69.176.62	POST	/api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-online	\N	\N
58f975a5-8a30-45c0-b2d6-6e46ba571f5a	CREATE	2026-07-27 09:22:52.272104	POST /api/notifications/1f56fba5-9a0b-4ce4-8cf3-6af88b2b9687/read	\N	Notification	172.70.208.106	POST	/api/notifications/1f56fba5-9a0b-4ce4-8cf3-6af88b2b9687/read	\N	\N
07958a7b-5755-4b71-91cd-c8d8d4aff818	CREATE	2026-07-27 09:26:03.302656	POST /api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/request-cash	\N	Invoice	172.69.165.32	POST	/api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/request-cash	\N	\N
1db26d74-1ccf-414e-8fa8-33c89dc3bfd4	PAYMENT	2026-07-27 09:26:06.448135	POST /api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-online	\N	Invoice	172.69.165.32	POST	/api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-online	\N	\N
01618879-d6cb-4e4f-bc6d-dd4d2cf6d9e4	PAYMENT	2026-07-27 09:26:06.627143	POST /api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-online	\N	Invoice	172.69.176.62	POST	/api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-online	\N	\N
2967f430-2d5f-442d-9e58-0650e2e0cd29	CREATE	2026-07-27 09:27:40.418821	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.23.175.145	POST	/api/maintenance/with-images	\N	\N
7e620304-fdf5-444f-be43-1cca94f8f2a9	CREATE	2026-07-27 09:27:41.104511	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.23.175.145	POST	/api/maintenance/with-images	\N	\N
ee47a6c9-e6ae-4757-84db-7d05dbdbfcf5	CREATE	2026-07-27 09:30:00.540322	POST /api/notifications/15cda31e-b0db-4e02-8356-3555e0cc650f/read	\N	Notification	162.158.88.171	POST	/api/notifications/15cda31e-b0db-4e02-8356-3555e0cc650f/read	\N	\N
a563d767-0209-40ef-85ac-b2af0090e0f6	CREATE	2026-07-27 09:30:04.403616	POST /api/notifications/47b2ab8e-6d70-4786-94ae-a10f00fae7c6/read	\N	Notification	172.69.165.33	POST	/api/notifications/47b2ab8e-6d70-4786-94ae-a10f00fae7c6/read	\N	\N
571a4a23-099a-48a5-b86f-701ad863b13a	CREATE	2026-07-27 09:30:06.234201	POST /api/notifications/107653cc-ea20-45e7-9afb-8dfb1ecd606d/read	\N	Notification	172.69.165.33	POST	/api/notifications/107653cc-ea20-45e7-9afb-8dfb1ecd606d/read	\N	\N
021b9af0-2620-4a3d-8c3c-d745106deb53	CREATE	2026-07-27 09:41:03.202037	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	172.71.152.78	POST	/api/maintenance/sla-rules	\N	\N
21402adf-3c54-4689-a5c9-09ddb7333d88	CREATE	2026-07-27 09:41:06.674002	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	172.71.152.78	POST	/api/maintenance/sla-rules	\N	\N
33a86f2d-9ac1-4554-91c8-c33f00b9b686	CREATE	2026-07-27 09:41:12.725565	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	104.23.175.145	POST	/api/maintenance/sla-rules	\N	\N
1ee6b8b7-2abc-4746-80d1-0e81a6f946df	CREATE	2026-07-27 09:41:39.49178	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	172.71.81.84	POST	/api/maintenance/sla-rules	\N	\N
5c835ed5-8fb4-4d1d-a013-8aa270caf391	CREATE	2026-07-27 09:41:50.411172	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	172.71.81.84	POST	/api/maintenance/sla-rules	\N	\N
6fb348e6-7c0c-48e1-ab3f-bb3e6ee4c861	CREATE	2026-07-27 09:41:58.188107	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	172.71.152.77	POST	/api/maintenance/sla-rules	\N	\N
809faf12-644e-4175-96f5-e77a432f0bff	CREATE	2026-07-27 09:42:03.28537	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	104.23.175.19	POST	/api/maintenance/sla-rules	\N	\N
bf7213d2-f44d-4a25-bf76-374b5d28b7aa	CREATE	2026-07-27 09:42:07.501728	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	172.71.152.78	POST	/api/maintenance/sla-rules	\N	\N
830fb790-c4d5-4487-b0a2-13f3a4930403	CREATE	2026-07-27 09:42:15.076068	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	104.23.175.145	POST	/api/maintenance/sla-rules	\N	\N
93388eae-775e-437a-8980-a6a502aa044c	CREATE	2026-07-27 09:42:21.244795	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	104.23.175.145	POST	/api/maintenance/sla-rules	\N	\N
6206b19f-9467-4536-b93f-2502cc8beb71	CREATE	2026-07-27 09:42:28.690065	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	172.71.152.77	POST	/api/maintenance/sla-rules	\N	\N
2b5e6a87-607a-44e2-ae1b-bd727aff062b	CREATE	2026-07-27 09:42:36.472493	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	172.71.152.77	POST	/api/maintenance/sla-rules	\N	\N
245d535d-2dc3-46e7-925f-7adfb99f7bd9	CREATE	2026-07-27 09:42:38.325078	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	172.71.81.84	POST	/api/maintenance/sla-rules	\N	\N
9a93e57f-88b2-4274-b3a2-703986bd3022	CREATE	2026-07-27 09:42:53.739241	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	172.71.152.77	POST	/api/maintenance/sla-rules	\N	\N
826504ac-0392-482e-9ed8-024123c855b8	CREATE	2026-07-27 09:42:57.08887	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	104.23.175.144	POST	/api/maintenance/sla-rules	\N	\N
e58823f5-8895-4a4a-be5c-1aadc2d3b162	CREATE	2026-07-27 09:43:09.002048	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	172.69.165.32	POST	/api/maintenance/sla-rules	\N	\N
1c4bf005-7889-433e-99c5-dc6d0c3d8211	DELETE	2026-07-27 09:43:15.691817	DELETE /api/maintenance/sla-rules/9f5798fc-6e7b-46d4-9a3a-af59fb831921	\N	MaintenanceRequest	172.69.165.32	DELETE	/api/maintenance/sla-rules/9f5798fc-6e7b-46d4-9a3a-af59fb831921	\N	\N
31550ef6-e17b-4f07-b6c0-d5edd08584e8	DELETE	2026-07-27 09:43:18.516367	DELETE /api/maintenance/sla-rules/49f466bd-2f85-429d-9cf3-77a7c7960a97	\N	MaintenanceRequest	172.71.81.84	DELETE	/api/maintenance/sla-rules/49f466bd-2f85-429d-9cf3-77a7c7960a97	\N	\N
40a1e005-8fd3-407c-b546-838dfd43841f	DELETE	2026-07-27 09:43:23.424281	DELETE /api/maintenance/sla-rules/c6d15220-7fb2-4438-970b-7bd10ff734d0	\N	MaintenanceRequest	172.71.152.77	DELETE	/api/maintenance/sla-rules/c6d15220-7fb2-4438-970b-7bd10ff734d0	\N	\N
9005b577-bb60-4c9e-988f-372d9ef445b5	DELETE	2026-07-27 09:43:25.451558	DELETE /api/maintenance/sla-rules/634ab5d6-6302-416c-99f9-802279d6dbe2	\N	MaintenanceRequest	172.70.143.168	DELETE	/api/maintenance/sla-rules/634ab5d6-6302-416c-99f9-802279d6dbe2	\N	\N
7899bea9-a14c-484e-8d50-b9d7d275333b	CREATE	2026-07-27 09:43:40.647764	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	172.71.152.77	POST	/api/maintenance/sla-rules	\N	\N
727955da-0d69-4db0-a85a-56918c9d17dc	CREATE	2026-07-27 09:43:47.092871	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	172.69.165.32	POST	/api/maintenance/sla-rules	\N	\N
ea347902-d182-4cba-b511-30e1bd72a2c1	CREATE	2026-07-27 09:43:56.544779	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	172.70.143.168	POST	/api/maintenance/sla-rules	\N	\N
054d0280-1603-4112-895d-2e732960507d	CREATE	2026-07-27 09:44:07.036108	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	172.71.152.77	POST	/api/maintenance/sla-rules	\N	\N
d086c01d-a410-437a-b399-2972dcc37f2b	CREATE	2026-07-27 09:44:14.016154	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	172.69.165.32	POST	/api/maintenance/sla-rules	\N	\N
76818b5a-c6ae-42cf-80f1-84896a2c854c	CREATE	2026-07-27 09:44:34.941751	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	172.69.165.32	POST	/api/maintenance/sla-rules	\N	\N
dd785750-abda-4b8c-ad70-39c07c9a948d	CREATE	2026-07-27 09:44:41.293426	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	172.71.152.77	POST	/api/maintenance/sla-rules	\N	\N
808ff110-e398-4d97-b4fa-51cce6ef74ad	CREATE	2026-07-27 09:44:45.71003	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	172.71.81.84	POST	/api/maintenance/sla-rules	\N	\N
efe52f2b-6876-4056-95ca-c92762c855d5	CREATE	2026-07-27 09:44:52.815512	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	172.71.81.84	POST	/api/maintenance/sla-rules	\N	\N
6fbb932e-0a2e-4fa7-a4b3-8137b4372cc2	CREATE	2026-07-27 09:44:56.425715	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	172.71.152.77	POST	/api/maintenance/sla-rules	\N	\N
77889890-daf8-426d-acc2-e6036be4e738	CREATE	2026-07-27 10:24:19.905088	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/with-images	\N	\N
a4b22135-292d-44f5-94c0-fa75da182909	CREATE	2026-07-27 10:24:20.723604	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/with-images	\N	\N
af988b5e-d4d9-4ea2-9596-6d9381db4609	CREATE	2026-07-27 10:25:32.823174	POST /api/maintenance/with-images	\N	MaintenanceRequest	162.158.193.197	POST	/api/maintenance/with-images	\N	\N
dee5fd00-3750-4fcb-9719-2747ec6929d3	CREATE	2026-07-27 10:25:35.146498	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/with-images	\N	\N
01059274-d572-49d4-8953-aacc0064bf06	UPDATE	2026-07-27 17:57:01.016688	PUT /api/property-types/b2000000-0000-0000-0000-000000000003	\N	Unknown	172.68.211.104	PUT	/api/property-types/b2000000-0000-0000-0000-000000000003	\N	\N
ae8d2a2f-f549-4530-96f0-029f588ef41a	CREATE	2026-07-27 17:57:53.436404	POST /api/invoices/generate	\N	Invoice	104.23.175.247	POST	/api/invoices/generate	\N	\N
65ac8f91-01b0-4db4-8db4-4d6fcdd00577	CREATE	2026-07-27 17:58:08.762722	POST /api/invoices/generate	\N	Invoice	104.23.175.247	POST	/api/invoices/generate	\N	\N
b8cdb849-dcde-44ff-9708-828c6be4cdcd	UPDATE	2026-07-27 17:59:57.206265	PUT /api/properties/b3000000-0000-0000-0000-000000000001/fee-config	\N	Property	104.23.175.246	PUT	/api/properties/b3000000-0000-0000-0000-000000000001/fee-config	\N	\N
69642848-c88e-4308-a83f-1cd5a76b6fb5	CREATE	2026-07-27 18:07:21.501182	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	172.71.124.29	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
f9b1cb65-0a62-43be-9fd4-11a7250cf0c9	CREATE	2026-07-27 18:07:33.317166	POST /api/invoices/generate	\N	Invoice	172.71.218.224	POST	/api/invoices/generate	\N	\N
0ea80463-7ecf-4547-9e16-58f99a45cdf4	CREATE	2026-07-27 18:07:38.821385	POST /api/invoices/generate	\N	Invoice	104.22.66.41	POST	/api/invoices/generate	\N	\N
5af6e171-7027-4eab-9a44-d748d8a56f5f	CREATE	2026-07-27 18:07:48.443444	POST /api/invoices/generate	\N	Invoice	172.71.124.13	POST	/api/invoices/generate	\N	\N
d03915c8-fdae-4658-84e2-8f4d0e51c2dd	CREATE	2026-07-28 01:49:23.812571	POST /api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/request-cash	\N	Invoice	172.71.81.84	POST	/api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/request-cash	\N	\N
8286a852-400c-47ab-97cf-aade8cf25235	CREATE	2026-07-28 01:50:01.575039	POST /api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/request-cash	\N	Invoice	172.71.81.84	POST	/api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/request-cash	\N	\N
cec963cb-848e-4319-a5e2-f3c55680d785	CREATE	2026-07-28 01:50:24.727744	POST /api/notifications/9588d8cd-4bf6-436d-8838-5925984488f6/read	\N	Notification	172.70.142.92	POST	/api/notifications/9588d8cd-4bf6-436d-8838-5925984488f6/read	\N	\N
da960c8f-2b23-4c27-a6e2-6c2bfd355a98	CREATE	2026-07-28 01:50:26.979822	POST /api/notifications/843d3b40-4c7f-47b6-95f6-948cb394852b/read	\N	Notification	162.158.108.109	POST	/api/notifications/843d3b40-4c7f-47b6-95f6-948cb394852b/read	\N	\N
41420266-7f17-42f9-b197-fde4daa16c69	PAYMENT	2026-07-28 01:51:29.910305	POST /api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-cash	\N	Invoice	172.70.93.65	POST	/api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-cash	\N	\N
61193cc8-f0f9-4dde-8330-f25b13f22209	PAYMENT	2026-07-28 01:51:30.157074	POST /api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-cash	\N	Invoice	104.23.176.4	POST	/api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-cash	\N	\N
9745a8e9-2c58-43b2-b6bc-3e4c901cafc6	PAYMENT	2026-07-28 01:51:32.073408	POST /api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-cash	\N	Invoice	104.23.175.247	POST	/api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-cash	\N	\N
99de520b-bf5d-4012-b0b5-985f0b7cc729	PAYMENT	2026-07-28 01:51:32.234664	POST /api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-cash	\N	Invoice	162.158.88.171	POST	/api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-cash	\N	\N
29320580-cef8-49cd-89e2-1a301a2af3d2	PAYMENT	2026-07-28 01:51:32.863798	POST /api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-cash	\N	Invoice	162.158.88.171	POST	/api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-cash	\N	\N
b18bc1d6-5cf8-4926-8f3d-d0a97c9959ad	PAYMENT	2026-07-28 01:51:33.013985	POST /api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-cash	\N	Invoice	172.70.93.65	POST	/api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-cash	\N	\N
9fab0ff4-4820-4a5b-9197-0d18e23a8c0e	PAYMENT	2026-07-28 01:51:33.621369	POST /api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-cash	\N	Invoice	104.23.176.4	POST	/api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-cash	\N	\N
c60e40d2-0727-4106-b4bd-8c277e97addf	PAYMENT	2026-07-28 01:51:33.794863	POST /api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-cash	\N	Invoice	172.70.93.65	POST	/api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-cash	\N	\N
55232e38-cc66-4cb5-96f6-9c370d533eb9	PAYMENT	2026-07-28 01:51:48.053685	POST /api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-online	\N	Invoice	172.68.164.62	POST	/api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-online	\N	\N
a2815105-c8e5-459c-8622-183405c0673e	PAYMENT	2026-07-28 01:51:48.213225	POST /api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-online	\N	Invoice	162.158.108.108	POST	/api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-online	\N	\N
db8657f9-fe58-4f07-8889-33709a282fba	PAYMENT	2026-07-28 01:51:49.441218	POST /api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-online	\N	Invoice	172.68.164.62	POST	/api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-online	\N	\N
1d3b36dd-6ac6-41ce-b8cd-e978714dd606	CREATE	2026-08-06 13:09:07.014733	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	104.23.175.247	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
82ccb9d6-58b2-472d-93ee-06950330144e	CREATE	2026-08-06 13:11:52.240778	POST /api/rooms/b5000000-0000-0000-0000-000000000024/meter-readings	\N	Room	162.159.98.51	POST	/api/rooms/b5000000-0000-0000-0000-000000000024/meter-readings	\N	\N
5ccd8493-c00a-4449-846d-23f6cfb23472	CREATE	2026-08-06 13:15:37.301068	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	162.159.98.50	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
50baac19-647b-4f32-be16-5d19c976a7d1	CREATE	2026-08-06 13:15:47.490555	POST /api/invoices/generate	\N	Invoice	172.71.81.84	POST	/api/invoices/generate	\N	\N
d6933389-2b49-4a6c-a579-6f289a77ce07	CREATE	2026-08-06 13:17:18.255143	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	172.71.152.78	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
8927f078-9c53-4c75-bce6-ae1e5f335fdf	CREATE	2026-08-06 13:17:24.393425	POST /api/invoices/generate	\N	Invoice	162.158.114.170	POST	/api/invoices/generate	\N	\N
a18f5727-617c-43ac-a97f-dd9070c9e0a5	CREATE	2026-08-06 13:17:30.890446	POST /api/invoices/generate	\N	Invoice	172.71.215.16	POST	/api/invoices/generate	\N	\N
eeec3aed-752c-41bd-aeea-38fee8a46864	CREATE	2026-08-06 13:17:50.489708	POST /api/invoices/generate	\N	Invoice	162.158.179.49	POST	/api/invoices/generate	\N	\N
ffb0db8c-5f3a-4b1e-88a8-39585e8991b8	CREATE	2026-08-06 13:18:14.3382	POST /api/invoices/generate	\N	Invoice	162.159.98.50	POST	/api/invoices/generate	\N	\N
4277adec-786c-41b6-8a02-69c9ba4dd4e1	CREATE	2026-08-09 15:54:04.780704	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	172.71.218.224	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
3e1c420f-81b0-4430-97cd-5f672177cda7	CREATE	2026-08-09 15:56:03.891659	POST /api/rooms/b5000000-0000-0000-0000-000000000025/meter-readings	\N	Room	104.23.175.247	POST	/api/rooms/b5000000-0000-0000-0000-000000000025/meter-readings	\N	\N
84293f58-5dd2-4902-8f10-94c64b2b9946	CREATE	2026-08-09 15:56:04.991487	POST /api/rooms/ce27f631-b495-48aa-9fc5-c60ec18a95eb/meter-readings	\N	Room	104.23.175.246	POST	/api/rooms/ce27f631-b495-48aa-9fc5-c60ec18a95eb/meter-readings	\N	\N
0f94c1de-063c-4e1b-acf0-4750583f857f	CREATE	2026-08-09 16:00:52.814113	POST /api/maintenance/with-images	\N	MaintenanceRequest	162.158.193.196	POST	/api/maintenance/with-images	\N	\N
d5271524-43f8-444d-b0d7-26e20def7207	CREATE	2026-08-09 16:04:39.999679	POST /api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/tenant-confirm-slot	\N	MaintenanceRequest	104.23.175.246	POST	/api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/tenant-confirm-slot	\N	\N
655f34f3-6067-4622-b8e8-22e52bd6964d	CREATE	2026-08-09 16:04:57.00947	POST /api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/start	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/start	\N	\N
cd74c702-ad90-4f78-a032-33f87ba2ba29	RESOLVE	2026-08-09 16:08:43.224572	POST /api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	\N
ddae6f75-dc7a-4b99-a22f-041552a9c9bd	CREATE	2026-08-09 16:10:40.71859	POST /api/maintenance/sla-rules	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/sla-rules	\N	\N
56a9c1b9-45ff-4603-b43a-a9eafa3609a7	PAYMENT	2026-07-28 01:51:49.596642	POST /api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-online	\N	Invoice	162.158.88.171	POST	/api/invoices/644f40d3-4f99-4d66-be61-6b855a095f31/pay-online	\N	\N
b11f85ee-186d-4fc8-a83d-fe93d70b4654	CREATE	2026-07-28 01:58:08.900726	POST /api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	Room	172.69.165.33	POST	/api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	\N
d9658394-333a-4e29-b719-b75c167891ee	CREATE	2026-07-28 01:58:23.001435	POST /api/invoices/generate	\N	Invoice	172.68.164.63	POST	/api/invoices/generate	\N	\N
d6dc5653-1b83-4058-8f53-7c9682e18434	CREATE	2026-07-28 01:58:33.404269	POST /api/invoices/generate	\N	Invoice	172.71.81.84	POST	/api/invoices/generate	\N	\N
89f5198b-b495-4e24-9d88-89ca24790bbc	CREATE	2026-07-28 01:58:40.419821	POST /api/invoices/generate	\N	Invoice	172.71.124.13	POST	/api/invoices/generate	\N	\N
729f5c3b-9c3e-4916-8950-1ca503850f88	CREATE	2026-07-28 01:58:47.537314	POST /api/invoices/generate	\N	Invoice	172.71.81.84	POST	/api/invoices/generate	\N	\N
4d7997ee-4f06-4950-a96f-1df44f14e972	CREATE	2026-07-28 02:04:08.301408	POST /api/notifications/read-all	\N	Notification	104.23.175.246	POST	/api/notifications/read-all	\N	\N
f2919aa6-bc54-42ab-874f-ab8fdbe8f0be	CREATE	2026-07-29 01:34:44.301451	POST /api/maintenance/with-images	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/with-images	\N	\N
f56c4164-f86f-423c-9c62-4d91e6bef8d4	CREATE	2026-07-29 01:34:48.201196	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.23.175.246	POST	/api/maintenance/with-images	\N	\N
0a1cfcde-885c-419a-973d-aeb9627a9fa8	CREATE	2026-07-29 01:35:49.408653	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.215.160	POST	/api/maintenance/with-images	\N	\N
a127d9f1-c7d7-453f-8a9d-5e2d0d9977b8	CREATE	2026-07-29 01:35:50.114732	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.81.83	POST	/api/maintenance/with-images	\N	\N
0ac5f407-0cef-4ab4-8fb1-b5c6a61bae05	CREATE	2026-07-29 03:03:35.508389	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.68.164.62	POST	/api/maintenance/with-images	\N	\N
9622a59b-77fd-44a6-89eb-15d4172f0f4e	CREATE	2026-07-29 03:03:36.105382	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.68.164.62	POST	/api/maintenance/with-images	\N	\N
abcd4504-089b-4242-ac52-169575bf6b0c	CREATE	2026-07-30 10:43:51.455888	POST /api/maintenance/with-images	\N	MaintenanceRequest	0:0:0:0:0:0:0:1	POST	/api/maintenance/with-images	tenant@example.com	a0000000-0000-0000-0000-000000000002
507f82a0-fd99-47dd-a300-55c565ab528c	CREATE	2026-07-30 10:46:27.52702	POST /api/maintenance/with-images	\N	MaintenanceRequest	0:0:0:0:0:0:0:1	POST	/api/maintenance/with-images	\N	\N
abe5ca82-d58d-4d3b-b223-a124927e0521	CREATE	2026-07-30 11:11:28.184636	POST /api/maintenance/with-images	\N	MaintenanceRequest	0:0:0:0:0:0:0:1	POST	/api/maintenance/with-images	tenant@example.com	a0000000-0000-0000-0000-000000000002
baa5540d-a0a1-437e-a148-237f2be3edbd	CREATE	2026-07-30 11:15:07.272338	POST /api/maintenance/with-images	\N	MaintenanceRequest	0:0:0:0:0:0:0:1	POST	/api/maintenance/with-images	tenant@example.com	a0000000-0000-0000-0000-000000000002
61611a19-a9d2-4e81-a1ee-e5d4823f384b	CREATE	2026-07-31 03:29:11.435548	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.23.176.4	POST	/api/maintenance/with-images	\N	\N
8af85c4f-49a0-405d-be13-23dc0ea55a0e	CREATE	2026-07-31 04:56:26.635838	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.23.175.246	POST	/api/maintenance/with-images	\N	\N
8450312c-0473-4dae-9554-5beba89ea146	CREATE	2026-07-31 04:56:27.3351	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/with-images	\N	\N
e80bba92-048f-4b74-8778-f21f8228a999	CREATE	2026-07-31 04:56:35.042555	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.23.175.246	POST	/api/maintenance/with-images	\N	\N
98da3c57-26b5-44c6-9641-c1a156bcedfd	ASSIGN	2026-07-31 05:01:17.833132	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/assign	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/assign	\N	\N
dd4f8e1d-9dd9-4fa8-b9d6-b4dcaf0d6d1d	CREATE	2026-07-31 07:06:26.701509	POST /api/notifications/8b7fd8ef-3500-4af3-8280-d819c785a0c1/read	\N	Notification	104.23.176.3	POST	/api/notifications/8b7fd8ef-3500-4af3-8280-d819c785a0c1/read	\N	\N
f2006e07-f1e2-4730-a796-0708ff96ee70	CREATE	2026-07-31 07:06:28.277715	POST /api/notifications/bbb7389d-a474-4cfc-9bc1-2afaacb5ea34/read	\N	Notification	162.158.114.171	POST	/api/notifications/bbb7389d-a474-4cfc-9bc1-2afaacb5ea34/read	\N	\N
889faeef-a2d9-438d-8291-d46a64ceaa1e	CREATE	2026-07-31 07:06:29.00585	POST /api/notifications/61daa033-3974-4da3-b531-ce723d40bc2d/read	\N	Notification	104.23.176.4	POST	/api/notifications/61daa033-3974-4da3-b531-ce723d40bc2d/read	\N	\N
691a7da9-7122-43f9-9a06-5a4782f4cc75	CREATE	2026-07-31 07:06:29.993962	POST /api/notifications/fb5cb159-02d8-47b0-8d15-3802f95847ab/read	\N	Notification	104.23.176.3	POST	/api/notifications/fb5cb159-02d8-47b0-8d15-3802f95847ab/read	\N	\N
6689508c-af21-457e-96cd-1ed1a2e301a6	CREATE	2026-07-31 07:06:30.093815	POST /api/notifications/6ef25f52-b4bb-4c1e-b9e2-9e472254e007/read	\N	Notification	162.158.179.49	POST	/api/notifications/6ef25f52-b4bb-4c1e-b9e2-9e472254e007/read	\N	\N
0eded5ae-927b-4a18-ad24-11be330f498d	CREATE	2026-07-31 07:07:51.995578	POST /api/notifications/read-all	\N	Notification	104.23.176.3	POST	/api/notifications/read-all	\N	\N
2f1a8903-4a70-4f9b-928d-69c2c5115f8b	CREATE	2026-07-31 07:08:06.207276	POST /api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings/hunonic-sync	\N	Room	162.159.98.51	POST	/api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings/hunonic-sync	\N	\N
6fec0360-9df2-4c51-a168-f6ba6f420bc9	CREATE	2026-07-31 07:09:03.809916	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/confirm-slot	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/confirm-slot	\N	\N
8bada4fd-22e3-4828-8103-67303e513500	CREATE	2026-07-31 07:09:09.805712	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/start	\N	MaintenanceRequest	104.23.176.4	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/start	\N	\N
749c63c0-6aa4-458c-bd36-9a6c6c87029c	CREATE	2026-07-31 07:09:29.598575	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.176.3	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
ec8d42ca-d2d0-46ae-83e1-bc1309406705	CREATE	2026-07-31 07:09:30.690111	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	162.158.179.50	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
d7f6e8d9-70f3-4e90-a193-bfbf24d8fe5d	CREATE	2026-07-31 07:09:54.999692	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/materials	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/materials	\N	\N
a078264c-2560-4a01-bb59-d80c2458c4de	CREATE	2026-07-31 07:10:08.703841	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/materials	\N	MaintenanceRequest	162.158.179.50	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/materials	\N	\N
3eb92d1d-80ef-4c3f-91f8-a4d578fa65f1	CREATE	2026-07-31 07:10:13.008147	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/notes	\N	MaintenanceRequest	162.158.179.50	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/notes	\N	\N
bc23060c-53e1-4ff4-8d67-6c16e10763e2	CREATE	2026-07-31 07:10:36.050622	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
03d06514-04c1-45bd-be9c-b485d07ad06d	CREATE	2026-07-31 07:10:36.821711	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
06e5b992-a10c-40c9-9554-65cb3c153190	CREATE	2026-07-31 07:10:56.330776	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	162.158.179.50	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
4adfcc48-bd36-44f0-a9e1-3e1a60ce0e1c	CREATE	2026-07-31 07:10:57.187757	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
919ccae1-ca8a-4a95-a2f0-43cd44e03fe0	CREATE	2026-07-31 07:27:28.057996	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/notes	\N	MaintenanceRequest	104.22.66.139	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/notes	\N	\N
372a5b39-f4c7-467f-9883-ba1624e50f73	CREATE	2026-07-31 07:33:52.516199	POST /api/notifications/095e2bfb-0bf5-460e-b6f5-363ec6aaa78b/read	\N	Notification	172.68.164.62	POST	/api/notifications/095e2bfb-0bf5-460e-b6f5-363ec6aaa78b/read	\N	\N
8ffa40e2-b673-4480-a523-23049ca7d4c4	CREATE	2026-07-31 08:30:00.534955	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.152.43	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
d22468cf-9730-4e3c-b975-00311636113e	CREATE	2026-07-31 08:34:07.055593	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/notes	\N	MaintenanceRequest	162.158.108.109	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/notes	\N	\N
caaabf2c-5d50-4b21-901e-b98d2b26b9ae	CREATE	2026-07-31 08:34:21.915172	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/notes	\N	MaintenanceRequest	162.158.108.109	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/notes	\N	\N
2d2f8f1f-d3dc-42b7-a7c8-d037a8ea9f4b	CREATE	2026-07-31 17:33:30.676643	POST /api/notifications/f35ce274-4953-4d0c-8721-30707924bad7/read	\N	Notification	162.158.179.50	POST	/api/notifications/f35ce274-4953-4d0c-8721-30707924bad7/read	\N	\N
6736bf8f-f5c4-45c4-9343-1deb3fbc24b9	CREATE	2026-07-31 17:33:30.676643	POST /api/notifications/ba2352e5-3ebe-4dcc-b3ee-20c3e18f5e49/read	\N	Notification	162.159.98.51	POST	/api/notifications/ba2352e5-3ebe-4dcc-b3ee-20c3e18f5e49/read	\N	\N
5e531e5c-ad36-4a03-85e4-a3fe691549e0	CREATE	2026-07-31 17:34:08.472598	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
24902a6d-89b3-4cdc-b6ef-ddeaffcf3301	CREATE	2026-07-31 17:34:10.211466	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
5ec8b93b-b19f-4906-babf-f48b1a08297c	CREATE	2026-07-31 17:35:10.258509	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	162.158.193.196	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
8e965444-540e-4c6f-899c-fce012339a0e	CREATE	2026-07-31 17:35:15.785464	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
818f065f-c3c8-40d5-9d51-2f09c3c05ca0	CREATE	2026-08-01 13:05:03.72194	POST /api/invoices/generate	\N	Invoice	162.159.98.50	POST	/api/invoices/generate	\N	\N
b557eb32-81be-43a0-b91e-8d2294544b42	CREATE	2026-08-01 13:05:53.473924	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	162.159.98.50	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
b30569bd-e245-4ad4-ba95-6c0e95b351b4	CREATE	2026-08-01 13:06:26.279166	POST /api/invoices/generate	\N	Invoice	104.23.175.247	POST	/api/invoices/generate	\N	\N
22890d3e-c77f-4ae0-bf62-ae5b0404a1af	CREATE	2026-08-01 13:06:35.586874	POST /api/invoices/generate	\N	Invoice	104.23.175.246	POST	/api/invoices/generate	\N	\N
5e4a39bb-d637-4783-bcef-8119b75772e3	CREATE	2026-08-01 13:06:43.199534	POST /api/invoices/generate	\N	Invoice	172.71.152.43	POST	/api/invoices/generate	\N	\N
a4447253-33e8-4bbb-b1ce-0d6fe442bb0d	CREATE	2026-08-01 13:22:07.171924	POST /api/invoices/generate	\N	Invoice	162.159.98.51	POST	/api/invoices/generate	\N	\N
4e421d6b-79b4-48ba-8f5c-6d81430e44b7	RESOLVE	2026-08-01 13:24:37.486008	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/resolve	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/resolve	\N	\N
546b323d-d31f-4c9a-859a-1661966bba2c	RESOLVE	2026-08-01 13:24:38.866241	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/resolve	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/resolve	\N	\N
50431ad6-d027-4928-b4b5-d4fdd724bd90	RESOLVE	2026-08-01 13:24:41.009573	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/resolve	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/resolve	\N	\N
a731232f-4a84-42d0-8c8d-bd206f494ac6	RESOLVE	2026-08-01 13:24:46.685543	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/resolve	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/resolve	\N	\N
41551d40-9aea-4371-a727-9742872cb326	RESOLVE	2026-08-01 13:24:54.840243	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/resolve	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/resolve	\N	\N
0edec87c-461a-4515-8bd4-fdb4355c802b	RESOLVE	2026-08-01 13:25:11.706561	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/resolve	\N	MaintenanceRequest	162.158.193.196	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/resolve	\N	\N
109899e5-5462-4abb-822b-0518b0a80dd3	RESOLVE	2026-08-01 13:25:41.845511	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/resolve	\N	MaintenanceRequest	162.158.193.196	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/resolve	\N	\N
d5d6d990-bac8-48f9-a9c9-74fa840e1792	RESOLVE	2026-08-01 13:26:16.272581	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/resolve	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/resolve	\N	\N
161174c3-828d-4573-b003-d12c8a47b428	RESOLVE	2026-08-01 13:26:46.495783	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/resolve	\N	MaintenanceRequest	162.158.179.50	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/resolve	\N	\N
32c3d49c-a5aa-4e35-9d6b-8fa3c502ed9f	RESOLVE	2026-08-01 13:27:35.929894	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/resolve	\N	MaintenanceRequest	162.158.193.196	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/resolve	\N	\N
6474e711-20f3-4fd6-860e-8848b6f93f2c	RESOLVE	2026-08-01 13:28:28.945798	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/resolve	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/resolve	\N	\N
11852099-2a05-4406-bc5d-81fba5e4fa96	RESOLVE	2026-08-01 13:28:59.102367	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/resolve	\N	MaintenanceRequest	172.71.152.44	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/resolve	\N	\N
3275969d-d1ce-4db9-8924-ba0341d9380a	CREATE	2026-08-01 13:33:56.883549	POST /api/invoices/7c135337-f51e-49fa-8731-3768446542f0/request-cash	\N	Invoice	104.23.175.247	POST	/api/invoices/7c135337-f51e-49fa-8731-3768446542f0/request-cash	\N	\N
8e92f049-a1be-4a91-b547-6b2aaa65ddd6	CREATE	2026-08-01 17:00:57.168826	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
cb04fd74-b144-46c0-850e-f28b2f864922	CREATE	2026-08-01 17:00:58.806285	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
c0b2d30c-037f-4cda-8969-e4bd04c3e537	CREATE	2026-08-01 17:01:01.430688	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
50e723b3-26ff-4586-8ea0-f1848c4b8df0	CREATE	2026-08-01 17:01:06.10769	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
156de291-ded1-4a9f-b6ce-f7767713f173	CREATE	2026-08-01 17:01:14.784324	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
1721323c-d2ae-407e-9f1d-90740c8aa36b	CREATE	2026-08-01 17:01:31.439004	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	162.158.193.196	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
b718580c-ff17-4b0b-a9c6-a3219ad29b61	CREATE	2026-08-01 17:02:02.06928	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
beb03d8a-f919-483f-a305-2eaad08dd309	CREATE	2026-08-01 17:02:32.822325	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
fdc41c7c-2eeb-4b82-b507-77c38209b600	CREATE	2026-08-01 17:03:03.517114	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
404c684d-6442-4ecd-91d9-2dd75889978c	CREATE	2026-08-01 17:03:34.271359	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
9d0e62be-1bd1-454c-94c4-1685f369876a	CREATE	2026-08-01 17:04:05.072491	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.70.142.63	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
b63e80f9-b5c3-4728-bf6d-c14d1c24a782	CREATE	2026-08-01 17:04:41.187571	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
966eb232-1d9a-4469-a773-5ec77e72a280	CREATE	2026-08-01 17:06:41.447236	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.68.211.105	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
5b8b26db-ed41-4ad3-bc10-22e4ddcdbf87	CREATE	2026-08-02 03:02:39.040655	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
cd2d3cc5-5b07-4126-81e9-8bbfd0f35874	CREATE	2026-08-02 03:02:40.961302	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.246	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
6a62ef95-2392-4573-850c-bde527dedd8c	CREATE	2026-08-02 03:02:43.974339	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	162.158.179.50	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
4eb72d49-073b-421a-a1a3-534d1d9f6d59	CREATE	2026-08-02 03:02:48.92664	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	162.158.193.196	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
a7c13296-2db7-49bd-9702-35a42900a8dc	CREATE	2026-08-02 03:02:57.881757	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
fc709103-4dee-4d02-81e3-d6f3c513a180	CREATE	2026-08-02 03:03:15.137141	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
9b91f1af-b14f-46ba-b850-4cb3a9930e96	CREATE	2026-08-02 03:03:45.993722	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.152.44	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
5e3f568c-9f2e-4430-ae9f-31ee07aaa3d2	CREATE	2026-08-02 03:03:56.372246	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/materials	\N	MaintenanceRequest	162.158.193.197	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/materials	\N	\N
21b1df7b-0dd3-4b1d-8989-f50587aaa30f	CREATE	2026-08-02 03:13:39.538122	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
bc0d0473-ce2b-4dd8-a9ca-2f076c642962	CREATE	2026-08-02 03:13:41.385488	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.246	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
31cca4ac-54df-4db0-aad7-888e494baab5	CREATE	2026-08-02 03:13:44.229407	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.152.44	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
5880c5ea-03ad-4622-92af-ad97fba705e2	CREATE	2026-08-02 03:13:49.079198	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.152.44	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
2a5e3d41-dd92-4898-9a90-e61afe705b08	CREATE	2026-08-02 03:13:57.961872	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
d0928a2b-0893-4b07-8992-b40a7254d3eb	CREATE	2026-08-02 03:14:06.123931	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	162.158.193.197	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
3644f852-b3bd-41f7-88ed-449573d5720c	CREATE	2026-08-02 03:14:07.956189	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
bb52c663-fd88-45f4-a7ba-07db4135a140	CREATE	2026-08-02 03:14:10.791431	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
0f72c91b-494a-472f-b7d5-e427887cde31	CREATE	2026-08-02 03:14:14.888005	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	162.158.179.50	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
4502e81c-e91a-4125-9cfa-fff8cf4c222a	CREATE	2026-08-02 03:14:15.693202	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.152.44	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
3d15fd04-e11a-4ca0-b5ee-7e139af6aa1e	CREATE	2026-08-02 03:14:24.536173	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
8b05b842-49fd-4b85-939a-8bc426ef5e71	CREATE	2026-08-02 03:14:25.714082	POST /api/notifications/b9f7fd7c-4524-4ae2-84a3-69981f0b111a/read	\N	Notification	104.23.175.246	POST	/api/notifications/b9f7fd7c-4524-4ae2-84a3-69981f0b111a/read	\N	\N
776fd288-21e1-468f-80b3-718f6fc7df27	CREATE	2026-08-02 03:14:41.405654	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
ce88d805-fa21-450b-bcd2-bf9d371d5482	CREATE	2026-08-02 03:14:42.022866	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.246	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
80dcc25c-42cd-40b2-85d1-d80f5007586b	CREATE	2026-08-02 03:14:43.881028	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
6dd85dae-decf-44be-abb4-dc33a6502cab	CREATE	2026-08-02 03:14:45.817932	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
19f9690e-67e7-4d85-a896-4da13c7d4bd1	CREATE	2026-08-02 03:14:46.778329	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
aa85fb20-ab25-4154-94ef-e29beb483da3	DELETE	2026-08-02 03:14:47.472727	DELETE /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/materials/41442478-b80f-4386-aa8e-159dfc2bfc04	\N	MaintenanceRequest	162.158.179.49	DELETE	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/materials/41442478-b80f-4386-aa8e-159dfc2bfc04	\N	\N
2ac2b970-0ac5-4499-aa8d-a75c03f52b1b	CREATE	2026-08-02 03:14:51.592795	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
760f3d58-b2d5-4ba8-90d4-a4bc1cec2824	CREATE	2026-08-02 03:15:00.413878	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
1781f919-8121-43cd-bb42-9e9e57530611	CREATE	2026-08-02 03:15:11.991696	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/materials	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/materials	\N	\N
a2832a2d-b2c6-4beb-9188-13c39786151f	CREATE	2026-08-02 03:15:12.373695	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
ed5109dd-bb85-4a48-b261-a7ae89349c8f	CREATE	2026-08-02 03:15:17.129134	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
8edb4a7d-4e69-4735-a188-978e4e4ee3b6	DELETE	2026-08-02 03:15:17.188482	DELETE /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/materials/2292f833-7b46-4fe4-93b1-9c2a3532678d	\N	MaintenanceRequest	172.71.218.224	DELETE	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/materials/2292f833-7b46-4fe4-93b1-9c2a3532678d	\N	\N
fb5c7c5d-85eb-47fe-b6b8-b86e4e82d97e	CREATE	2026-08-02 03:15:17.436542	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.152.43	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
9b16d1f0-e91d-4c79-bc1a-96c9337234c2	CREATE	2026-08-02 03:15:31.079373	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/materials	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/materials	\N	\N
286d28c7-0a4a-4cc5-8b7c-5a2c210830ff	DELETE	2026-08-02 03:15:40.677861	DELETE /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/materials/fbb9f423-f430-49af-afdf-f7571f886ad5	\N	MaintenanceRequest	104.23.175.247	DELETE	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/materials/fbb9f423-f430-49af-afdf-f7571f886ad5	\N	\N
882e474d-3dea-45bf-b30a-69eddc257ae1	CREATE	2026-08-02 03:15:43.455215	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.246	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
5fb83482-742a-43ca-ba6e-3d899681485e	CREATE	2026-08-02 03:15:47.980097	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.246	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
cb9bab80-3894-4984-9a11-6e43e098c65e	CREATE	2026-08-02 03:15:48.279329	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
d1b784bc-bce4-4343-af77-e25ff671925b	CREATE	2026-08-02 03:15:55.980949	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/materials	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/materials	\N	\N
c9935a91-127a-47d5-958e-892467e3f0e3	CREATE	2026-08-02 03:16:52.848139	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.246	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
3c016a53-c39d-4c7c-96af-8dcb3cd687cc	CREATE	2026-08-02 03:16:54.746484	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
6d1bdb51-ba8b-44e5-9ca2-6344ff77e9a4	CREATE	2026-08-02 03:16:57.677029	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	162.158.179.50	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
2cefd7e0-3f0c-4037-9592-cf5e6e36e07b	CREATE	2026-08-02 03:17:02.539248	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	162.158.179.50	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
3b2576a0-845a-402b-9df1-01efbd89b2e1	CREATE	2026-08-02 03:17:11.386545	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
7546f9f0-559d-43ea-bac0-a751d5940d5c	CREATE	2026-08-02 03:18:49.243192	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
d96d0cf5-dc0d-4cca-85f9-d410c9eecd3b	CREATE	2026-08-02 03:19:33.136192	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.152.44	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
a5f170c3-eb61-4e8f-906d-5dd28be25981	CREATE	2026-08-02 03:20:38.198801	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.152.44	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
8cd136ef-0e05-461d-9f46-ae047b52134c	CREATE	2026-08-02 03:21:20.346178	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	162.158.114.171	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
71d747ce-38a8-48a0-827a-5736e8056d95	CREATE	2026-08-02 03:21:36.665782	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	162.158.114.170	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
76b0e2ab-fb6f-4474-b58a-754036e44987	CREATE	2026-08-02 03:21:38.536459	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.152.44	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
8a3e99cf-aaba-4312-94a8-1e8509098af0	CREATE	2026-08-02 03:21:41.493002	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	162.158.114.171	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
dc5d519d-c653-442c-8ad2-588cea59601f	CREATE	2026-08-02 03:21:46.592914	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.152.44	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
7a6451f4-7332-40c6-b7c9-00cbcff17d32	DELETE	2026-08-02 07:13:33.489611	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	172.71.215.159	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
b9656822-b166-4164-b71b-35aac434a821	DELETE	2026-08-02 07:13:33.904277	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	172.68.211.104	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
3480e881-3449-42de-ac26-20e4e24d5512	UPDATE	2026-08-02 07:14:06.575493	PUT /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	162.159.98.50	PUT	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
49d16874-c6b0-49a8-8364-155fec408912	DELETE	2026-08-02 07:14:14.119273	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.68.211.104	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
661cf29d-62a3-4329-a4c6-9a99932905cf	DELETE	2026-08-02 07:14:14.540087	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.71.218.224	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
ceb43ff0-77d6-4994-8ac3-d40b23ad2dd0	DELETE	2026-08-02 07:14:28.574224	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	172.71.152.43	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
dacba6e6-c08a-4951-a346-8ef50f88af0d	DELETE	2026-08-02 07:14:28.913138	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	172.68.211.104	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
3c51b070-1cec-473a-aac7-c074eb46127c	UPDATE	2026-08-02 07:15:17.57203	PUT /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	Property	172.71.218.224	PUT	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0	\N	\N
cce71737-5594-45e6-8672-feb23cec62da	CREATE	2026-08-02 07:21:50.500722	POST /api/maintenance/with-images	\N	MaintenanceRequest	162.158.193.197	POST	/api/maintenance/with-images	\N	\N
c518d272-a242-4dde-bd81-ac9fbf9673df	CREATE	2026-08-02 07:22:01.821688	POST /api/notifications/a133e1a5-44cb-4a4b-bbd7-41b0243b9b2d/read	\N	Notification	104.23.175.247	POST	/api/notifications/a133e1a5-44cb-4a4b-bbd7-41b0243b9b2d/read	\N	\N
e1069b0b-546a-4885-bb4d-7d8452cdb4ad	ASSIGN	2026-08-02 07:23:34.772364	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/assign	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/assign	\N	\N
4875fdc9-f52a-4e03-a2b6-1fed0b4dfbb0	CREATE	2026-08-02 07:25:19.662971	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/confirm-slot	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/confirm-slot	\N	\N
def74102-3d3c-4d6b-a13d-34b1ab8baec8	CREATE	2026-08-02 07:26:04.172415	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/tenant-confirm-slot	\N	MaintenanceRequest	172.70.208.106	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/tenant-confirm-slot	\N	\N
03fce85a-0359-41da-bd33-c1c39f0a1965	CREATE	2026-08-02 07:26:11.711896	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/start	\N	MaintenanceRequest	172.71.152.43	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/start	\N	\N
e0f8d853-d0f5-4949-834e-0c5716680b5f	CREATE	2026-08-02 07:26:23.413263	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/notes	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/notes	\N	\N
4bdce3b2-9ca1-440d-9faa-e506ddb2dcdb	CREATE	2026-08-02 07:26:33.404307	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/completion-images	\N	MaintenanceRequest	162.158.193.196	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/completion-images	\N	\N
48dccc24-9c8c-4c33-961b-0b48b064b480	CREATE	2026-08-02 07:26:35.354549	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/completion-images	\N	MaintenanceRequest	162.158.193.196	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/completion-images	\N	\N
d8047ff4-f3fa-48bf-900b-e9386fde4159	CREATE	2026-08-02 07:26:38.314414	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/completion-images	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/completion-images	\N	\N
b479f659-aa46-4f85-8d40-66501d3f074c	CREATE	2026-08-02 07:26:43.363955	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/completion-images	\N	MaintenanceRequest	162.158.193.196	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/completion-images	\N	\N
0f7b9f35-1517-4921-b4e5-6434d0ed63a5	CREATE	2026-08-02 07:26:52.530636	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/completion-images	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/completion-images	\N	\N
daebccea-9783-45ba-8902-6160024cfe80	CREATE	2026-08-02 07:27:43.528395	POST /api/notifications/cc02f69a-e609-43f5-86d7-4cca52e08974/read	\N	Notification	172.68.211.105	POST	/api/notifications/cc02f69a-e609-43f5-86d7-4cca52e08974/read	\N	\N
d55a6e76-e4cd-4c23-8a18-7e1f3e3814b8	CREATE	2026-08-02 07:27:43.944218	POST /api/notifications/ff53f0d9-6b6b-4165-85d5-09c64fce0a6d/read	\N	Notification	172.71.215.159	POST	/api/notifications/ff53f0d9-6b6b-4165-85d5-09c64fce0a6d/read	\N	\N
d27b4690-8d34-47ee-982f-3965db432fc3	CREATE	2026-08-02 07:34:58.798354	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/materials	\N	MaintenanceRequest	162.158.179.50	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/materials	\N	\N
4e511c50-7a50-40ce-be58-5425a0b4b315	DELETE	2026-08-02 07:35:04.458242	DELETE /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/materials/e6596d7f-9ea7-444c-bfdc-94e3277e0744	\N	MaintenanceRequest	104.23.175.246	DELETE	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/materials/e6596d7f-9ea7-444c-bfdc-94e3277e0744	\N	\N
6b2b839f-2dae-422b-b1a3-f9264d4f45ce	CREATE	2026-08-02 07:40:25.480515	POST /api/rooms/b5000000-0000-0000-0000-000000000017/meter-readings	\N	Room	104.23.175.247	POST	/api/rooms/b5000000-0000-0000-0000-000000000017/meter-readings	\N	\N
2911d40f-c94f-4860-a965-6c04948cf9f2	CREATE	2026-08-02 07:40:29.008755	POST /api/invoices/generate	\N	Invoice	162.158.114.171	POST	/api/invoices/generate	\N	\N
3c0a3cac-6bf7-45e5-bd4f-03290cd70821	CREATE	2026-08-02 07:40:44.886795	POST /api/invoices/generate	\N	Invoice	104.23.175.246	POST	/api/invoices/generate	\N	\N
22e34b8f-514c-40b7-98f0-92ff25d11480	CREATE	2026-08-02 07:40:49.089935	POST /api/invoices/generate	\N	Invoice	104.23.175.246	POST	/api/invoices/generate	\N	\N
ee73c2fb-5642-48d8-8421-1e829e4b4f71	CREATE	2026-08-02 07:40:56.631743	POST /api/invoices/generate	\N	Invoice	104.23.175.247	POST	/api/invoices/generate	\N	\N
591839b8-569b-4182-842a-c6947f6482bb	CREATE	2026-08-02 07:41:16.533875	POST /api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	Room	172.71.218.225	POST	/api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	\N
633ff97d-a5fa-4b1d-85fc-f039346463e5	CREATE	2026-08-02 07:41:25.477353	POST /api/invoices/generate	\N	Invoice	162.159.98.50	POST	/api/invoices/generate	\N	\N
b48b81e4-57e5-4499-8a09-70c6d2b4c1a0	CREATE	2026-08-02 07:41:37.787892	POST /api/invoices/generate	\N	Invoice	162.158.179.49	POST	/api/invoices/generate	\N	\N
46a04108-ae95-4183-bf04-68a2cc0af50c	CREATE	2026-08-02 07:41:41.181394	POST /api/invoices/generate	\N	Invoice	104.23.175.246	POST	/api/invoices/generate	\N	\N
35b09d06-b67e-40e5-a536-7cf431be1850	CREATE	2026-08-02 07:41:53.846881	POST /api/invoices/a6471a5a-9a29-4d2e-9574-15a7d8d08520/request-cash	\N	Invoice	104.23.175.246	POST	/api/invoices/a6471a5a-9a29-4d2e-9574-15a7d8d08520/request-cash	\N	\N
60a9ba9c-1aa6-40ff-a2de-e377d141a6e3	PAYMENT	2026-08-02 07:41:56.821759	POST /api/invoices/a6471a5a-9a29-4d2e-9574-15a7d8d08520/pay-online	\N	Invoice	162.159.98.50	POST	/api/invoices/a6471a5a-9a29-4d2e-9574-15a7d8d08520/pay-online	\N	\N
f8db3475-2435-4859-ac8b-3cdf088ac308	PAYMENT	2026-08-02 07:41:57.1526	POST /api/invoices/a6471a5a-9a29-4d2e-9574-15a7d8d08520/pay-online	\N	Invoice	162.158.179.50	POST	/api/invoices/a6471a5a-9a29-4d2e-9574-15a7d8d08520/pay-online	\N	\N
1bba936d-379e-42cb-bbb6-efcd653acb5e	CREATE	2026-08-02 07:42:23.075675	POST /api/invoices/a6471a5a-9a29-4d2e-9574-15a7d8d08520/request-cash	\N	Invoice	172.68.211.105	POST	/api/invoices/a6471a5a-9a29-4d2e-9574-15a7d8d08520/request-cash	\N	\N
6a3563a8-821d-4b51-8b8a-dea2727ed826	CREATE	2026-08-02 07:42:31.76432	POST /api/notifications/de2a5933-43d2-4c37-887d-140f4c544615/read	\N	Notification	172.71.152.43	POST	/api/notifications/de2a5933-43d2-4c37-887d-140f4c544615/read	\N	\N
0dafcbab-4e94-41ef-ba70-0d71a93c1e37	CREATE	2026-08-02 07:42:53.416166	POST /api/notifications/cf9a322c-7804-4bb7-bfd4-f3a9a45883f8/read	\N	Notification	104.23.175.246	POST	/api/notifications/cf9a322c-7804-4bb7-bfd4-f3a9a45883f8/read	\N	\N
34386747-628a-4c34-b265-38f0ca47c507	PAYMENT	2026-08-02 07:42:59.185329	POST /api/invoices/a6471a5a-9a29-4d2e-9574-15a7d8d08520/pay-cash	\N	Invoice	172.70.208.107	POST	/api/invoices/a6471a5a-9a29-4d2e-9574-15a7d8d08520/pay-cash	\N	\N
b7e88def-bde3-4acc-992a-384b12e58880	CREATE	2026-08-06 13:09:40.798364	POST /api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	Room	172.71.81.83	POST	/api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	\N
4e0dcf25-5f52-45a3-bc96-86f8db77ac1d	CREATE	2026-08-06 13:11:20.456301	POST /api/rooms/e3d6477b-41ee-4b21-af42-6a9f042e6d08/meter-readings	\N	Room	162.159.98.51	POST	/api/rooms/e3d6477b-41ee-4b21-af42-6a9f042e6d08/meter-readings	\N	\N
c8457671-3936-470c-b3d8-e4a719170d9d	CREATE	2026-08-06 13:12:52.30406	POST /api/invoices/generate	\N	Invoice	172.71.81.84	POST	/api/invoices/generate	\N	\N
8b94c4d8-7ec3-4137-8005-d73f81d0e0a3	CREATE	2026-08-06 13:13:17.352199	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	172.71.81.84	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
5f71d520-c59f-44df-a53a-0efc2460136e	CREATE	2026-08-06 13:16:09.517711	POST /api/invoices/generate	\N	Invoice	172.68.211.104	POST	/api/invoices/generate	\N	\N
e30e11f5-fcba-451b-b9d3-a248cf3d96ad	CREATE	2026-08-06 13:19:37.29056	POST /api/invoices/generate	\N	Invoice	172.71.215.15	POST	/api/invoices/generate	\N	\N
0f4a882d-0e50-432a-95bb-c851dc6eece9	PAYMENT	2026-08-06 13:21:46.686975	POST /api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/pay-online	\N	Invoice	162.159.98.50	POST	/api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/pay-online	\N	\N
bbb57de3-226b-4d91-9ad4-83b5fc3d2d7c	CREATE	2026-08-09 15:54:06.490678	POST /api/invoices/generate	\N	Invoice	172.68.211.105	POST	/api/invoices/generate	\N	\N
0e997909-0ee9-4d98-9b85-ecf116005c7d	RESOLVE	2026-08-09 16:09:41.013549	POST /api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	\N
849dcbcc-dd34-43de-91ab-77b891f7970f	RESOLVE	2026-08-09 16:10:11.733704	POST /api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	MaintenanceRequest	104.23.175.246	POST	/api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	\N
03712fe4-16a0-42db-ba37-4e79bd609ef2	CREATE	2026-08-02 07:42:45.999731	POST /api/invoices/a6471a5a-9a29-4d2e-9574-15a7d8d08520/request-cash	\N	Invoice	104.23.175.246	POST	/api/invoices/a6471a5a-9a29-4d2e-9574-15a7d8d08520/request-cash	\N	\N
3639741f-33b1-41df-b0d5-745339a0392c	PAYMENT	2026-08-02 07:42:59.678503	POST /api/invoices/a6471a5a-9a29-4d2e-9574-15a7d8d08520/pay-cash	\N	Invoice	172.71.218.225	POST	/api/invoices/a6471a5a-9a29-4d2e-9574-15a7d8d08520/pay-cash	\N	\N
294de38a-b359-4758-9bf9-0916259f3c10	CREATE	2026-08-03 09:36:02.431831	POST /api/notifications/458d03c0-f6f0-4728-bbe2-947e87b3bb3c/read	\N	Notification	162.158.190.115	POST	/api/notifications/458d03c0-f6f0-4728-bbe2-947e87b3bb3c/read	\N	\N
21775aa2-46f0-4e90-9758-7370da8760dd	CREATE	2026-08-03 09:36:03.254233	POST /api/notifications/3f2d751b-c5ae-45af-b9d4-3b1a2f8213e3/read	\N	Notification	104.22.176.10	POST	/api/notifications/3f2d751b-c5ae-45af-b9d4-3b1a2f8213e3/read	\N	\N
0c446fc2-8e86-4f72-8a4b-77febbc09dbd	CREATE	2026-08-03 09:36:03.620666	POST /api/notifications/707f04b1-d63e-4c21-b472-36caff2c08fb/read	\N	Notification	162.158.108.108	POST	/api/notifications/707f04b1-d63e-4c21-b472-36caff2c08fb/read	\N	\N
b5d38d1f-f225-4771-b994-d3f8b3606148	CREATE	2026-08-03 09:36:04.995876	POST /api/notifications/0a1dcb70-d653-4fcf-ac87-2bd65ed1159a/read	\N	Notification	162.158.108.108	POST	/api/notifications/0a1dcb70-d653-4fcf-ac87-2bd65ed1159a/read	\N	\N
e3f2fcb1-371b-476c-b3a0-3ed1aa6041d1	CREATE	2026-08-03 09:36:05.861997	POST /api/notifications/143244d5-104a-414d-bb19-e5a72e585118/read	\N	Notification	162.158.190.115	POST	/api/notifications/143244d5-104a-414d-bb19-e5a72e585118/read	\N	\N
d191b0bc-a87f-4dd2-9c42-4e946dfd5361	DELETE	2026-08-04 07:16:30.21722	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	162.159.98.51	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
6b439d2b-bc50-4878-a094-f89295b9ba12	DELETE	2026-08-04 07:16:31.507597	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	172.70.93.65	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
1ba77bdc-945d-4049-a5df-f1d3e339c344	DELETE	2026-08-04 07:16:33.710675	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	172.68.164.63	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
932fa11b-be9a-4487-9d14-6375a4585070	DELETE	2026-08-04 07:16:37.90459	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	172.68.211.104	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
40c4fead-d799-49c4-acca-dc3a77ee619b	DELETE	2026-08-04 07:16:46.067167	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	104.23.175.246	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
64d5df1a-23b5-4351-8710-e3f23844094d	DELETE	2026-08-04 07:17:46.411367	DELETE /api/properties/b3000000-0000-0000-0000-000000000003/rooms/b5000000-0000-0000-0000-000000000023	\N	Property	172.70.93.64	DELETE	/api/properties/b3000000-0000-0000-0000-000000000003/rooms/b5000000-0000-0000-0000-000000000023	\N	\N
6df8f543-c084-4006-acb8-7aceb531fd6e	DELETE	2026-08-04 07:18:05.70388	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	172.68.164.62	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
81c262ad-60b3-44d0-9f6f-eb3630041dc1	DELETE	2026-08-04 07:18:06.902919	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	162.159.98.51	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
9e99adb1-c687-43e7-8815-6d87542b8091	DELETE	2026-08-04 07:18:09.068605	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	172.70.93.64	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
4b4332ae-6db3-4a68-9f93-e29613a5567f	DELETE	2026-08-04 07:18:13.316596	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	172.68.164.62	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
473e145b-b734-4475-91be-089d39eba6b2	DELETE	2026-08-04 07:18:21.578627	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	162.159.98.51	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
fa70abf1-b51f-4535-ab5f-b7e3974449bf	DELETE	2026-08-04 07:18:37.775035	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	104.23.175.246	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
009977b1-ca9f-4aa4-9ea4-17696931d87d	DELETE	2026-08-04 07:19:07.946723	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	162.159.98.51	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
97c40aed-a418-4420-8c4f-063727fef2ed	DELETE	2026-08-04 07:19:38.409563	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	104.23.176.3	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
caac5853-2407-48ee-8b69-996f79638255	CREATE	2026-08-04 07:19:55.018502	POST /api/users	\N	User	162.159.98.50	POST	/api/users	\N	\N
bb24f19f-68d6-41e6-abb9-58ba9c00ff94	DELETE	2026-08-04 07:20:08.703172	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	162.159.98.50	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
85eeb5ba-8942-40bf-8c6c-937309403b36	CREATE	2026-08-04 07:20:19.603685	POST /api/properties	\N	Property	104.23.175.247	POST	/api/properties	\N	\N
5f2fda54-7180-4a25-80e3-ba8d96326899	CREATE	2026-08-04 07:20:21.504054	POST /api/invoices/generate	\N	Invoice	104.23.175.246	POST	/api/invoices/generate	\N	\N
3bb8f75a-ef80-4c8e-89db-5683784c6544	DELETE	2026-08-04 07:20:28.135135	DELETE /api/properties/5db28242-7236-4fd2-b708-2db47fb47032	\N	Property	104.23.175.247	DELETE	/api/properties/5db28242-7236-4fd2-b708-2db47fb47032	\N	\N
5157863f-1980-4ee6-9252-8d1428489ad4	DELETE	2026-08-04 07:20:33.670212	DELETE /api/properties/b3000000-0000-0000-0000-000000000003	\N	Property	172.71.218.224	DELETE	/api/properties/b3000000-0000-0000-0000-000000000003	\N	\N
c6f8b8c9-1e63-4cb0-becd-e5f8ec04fe66	DELETE	2026-08-04 07:20:34.815941	DELETE /api/properties/b3000000-0000-0000-0000-000000000003	\N	Property	162.159.98.50	DELETE	/api/properties/b3000000-0000-0000-0000-000000000003	\N	\N
8faa9986-ca06-4f56-871e-5c76d679cbaa	DELETE	2026-08-04 07:20:37.012363	DELETE /api/properties/b3000000-0000-0000-0000-000000000003	\N	Property	104.23.175.247	DELETE	/api/properties/b3000000-0000-0000-0000-000000000003	\N	\N
420e19b2-c803-426b-8b48-304317ab2536	DELETE	2026-08-04 07:20:38.910341	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	104.23.175.247	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
ed949706-fd8b-4661-986e-07b354a81c11	DELETE	2026-08-04 07:20:41.164987	DELETE /api/properties/b3000000-0000-0000-0000-000000000003	\N	Property	104.23.175.246	DELETE	/api/properties/b3000000-0000-0000-0000-000000000003	\N	\N
01be2533-1d52-493b-873c-69cc242d2ef5	DELETE	2026-08-04 07:20:49.368783	DELETE /api/properties/b3000000-0000-0000-0000-000000000003	\N	Property	162.159.98.50	DELETE	/api/properties/b3000000-0000-0000-0000-000000000003	\N	\N
4b3b7118-3771-4937-b792-5a00bf10b760	DELETE	2026-08-04 07:21:12.203631	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	104.23.176.3	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
cd04b034-2a41-4084-beb2-111ae48682c8	DELETE	2026-08-04 07:21:12.621993	DELETE /api/properties/b3000000-0000-0000-0000-000000000003	\N	Property	172.71.218.224	DELETE	/api/properties/b3000000-0000-0000-0000-000000000003	\N	\N
74b89e46-1d47-46e3-b181-4fe390331808	DELETE	2026-08-04 07:21:42.413581	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	104.23.176.3	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
dfdc8342-ae2e-4736-a43f-c7829606d314	DELETE	2026-08-04 07:22:12.721886	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	104.23.175.247	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
eb29c897-07b5-4534-a84b-bfd756e3bec7	DELETE	2026-08-04 07:22:42.973207	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	104.23.175.247	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
814ee499-3778-4d83-8b8b-aa420c9653c5	DELETE	2026-08-04 07:23:13.320206	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	172.71.218.224	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
2757fdc2-cd8d-42da-ada2-89e1feb1e79b	DELETE	2026-08-04 07:23:43.566378	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	162.159.98.50	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
73b5f3b5-4ceb-4fb8-a782-e479b8166422	DELETE	2026-08-04 07:24:13.818661	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	104.23.175.146	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
7460fe52-a983-48e7-98ce-4b5ce575f944	CREATE	2026-08-06 13:09:49.140852	POST /api/rooms/b5000000-0000-0000-0000-000000000007/meter-readings	\N	Room	172.71.81.84	POST	/api/rooms/b5000000-0000-0000-0000-000000000007/meter-readings	\N	\N
8e9f34d3-a974-483b-8831-f939091b6206	CREATE	2026-08-06 13:10:56.833243	POST /api/rooms/b5000000-0000-0000-0000-000000000021/meter-readings	\N	Room	172.71.152.77	POST	/api/rooms/b5000000-0000-0000-0000-000000000021/meter-readings	\N	\N
8f8120a4-23b2-4fe8-bd93-f0a069313d85	CREATE	2026-08-06 13:12:25.786722	POST /api/rooms/b5000000-0000-0000-0000-000000000002/meter-readings	\N	Room	172.71.152.77	POST	/api/rooms/b5000000-0000-0000-0000-000000000002/meter-readings	\N	\N
3914b4a1-38b8-42f7-89ff-1c78b144a649	CREATE	2026-08-06 13:12:31.143883	POST /api/invoices/generate	\N	Invoice	162.159.98.50	POST	/api/invoices/generate	\N	\N
8a960486-78b1-4a58-96f8-a541999f4518	CREATE	2026-08-06 13:12:54.033942	POST /api/invoices/generate	\N	Invoice	172.71.81.83	POST	/api/invoices/generate	\N	\N
640a0840-c832-4254-b8d5-3e827c4478df	CREATE	2026-08-06 13:13:42.40146	POST /api/invoices/generate	\N	Invoice	162.158.193.197	POST	/api/invoices/generate	\N	\N
0e1d746a-64b7-4fd4-8222-1d622ec9c907	CREATE	2026-08-06 13:17:33.595004	POST /api/invoices/generate	\N	Invoice	162.158.114.170	POST	/api/invoices/generate	\N	\N
3aaa9202-fd94-4661-ba7a-63a45dc58922	CREATE	2026-08-06 13:18:48.075771	POST /api/invoices/7c135337-f51e-49fa-8731-3768446542f0/request-cash	\N	Invoice	172.71.215.15	POST	/api/invoices/7c135337-f51e-49fa-8731-3768446542f0/request-cash	\N	\N
34fdee43-c6c8-4b9e-8fc7-db54bfc07c7d	CREATE	2026-08-06 13:19:39.264182	POST /api/invoices/generate	\N	Invoice	172.71.218.224	POST	/api/invoices/generate	\N	\N
c3ab2407-79b4-41a8-814e-6a1620137da8	CREATE	2026-08-09 15:55:55.618137	POST /api/rooms/b5000000-0000-0000-0000-000000000022/meter-readings	\N	Room	172.68.211.105	POST	/api/rooms/b5000000-0000-0000-0000-000000000022/meter-readings	\N	\N
855c7b3a-6ba6-413f-ad28-140b0bc64bbc	CREATE	2026-08-09 15:55:59.489091	POST /api/rooms/b5000000-0000-0000-0000-000000000016/meter-readings	\N	Room	172.71.215.16	POST	/api/rooms/b5000000-0000-0000-0000-000000000016/meter-readings	\N	\N
2dc27d39-e09a-4fcb-b045-b61ecf5ef08c	CREATE	2026-08-09 15:56:07.086209	POST /api/rooms/fcf45ae0-98ba-4018-8181-1a9dbab9a472/meter-readings	\N	Room	162.159.98.237	POST	/api/rooms/fcf45ae0-98ba-4018-8181-1a9dbab9a472/meter-readings	\N	\N
0f3d0abf-2af0-4aa5-acb4-d147de955957	CREATE	2026-08-09 15:56:11.680834	POST /api/rooms/b5000000-0000-0000-0000-000000000012/meter-readings	\N	Room	172.71.218.225	POST	/api/rooms/b5000000-0000-0000-0000-000000000012/meter-readings	\N	\N
6fb6615d-7369-4872-865a-473cac039d24	CREATE	2026-08-09 15:56:23.085947	POST /api/invoices/generate	\N	Invoice	162.159.98.236	POST	/api/invoices/generate	\N	\N
c1638453-cc7e-4261-8fc5-e501bb752481	ASSIGN	2026-08-09 16:03:31.317424	POST /api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/assign	\N	MaintenanceRequest	172.71.215.15	POST	/api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/assign	\N	\N
af1c3000-425d-4425-9a57-77e971c77652	CREATE	2026-08-09 16:05:19.784268	POST /api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/materials	\N	MaintenanceRequest	172.71.215.15	POST	/api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/materials	\N	\N
2d8afe53-5686-4d64-b17c-cf47c13f6172	RESOLVE	2026-08-09 16:08:50.542414	POST /api/maintenance/483e9cdc-246b-48a5-9a8f-2327910f2b03/resolve	\N	MaintenanceRequest	162.159.98.237	POST	/api/maintenance/483e9cdc-246b-48a5-9a8f-2327910f2b03/resolve	\N	\N
ef9e8c05-4ddf-415b-bdec-e9a4d20e7e25	RESOLVE	2026-08-09 16:09:36.264055	POST /api/maintenance/229d8e58-ffbe-44d4-8909-3e92985cfe8c/resolve	\N	MaintenanceRequest	104.23.175.246	POST	/api/maintenance/229d8e58-ffbe-44d4-8909-3e92985cfe8c/resolve	\N	\N
5f23cbdf-9fa8-4081-8e3a-c048d9a65887	RESOLVE	2026-08-09 16:10:06.094023	POST /api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	MaintenanceRequest	104.23.175.246	POST	/api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	\N
c60f3982-5bc7-49bc-b67a-7ea116d6ac7b	CREATE	2026-08-04 07:24:02.302862	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	104.23.175.147	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
ab45be0b-63aa-4615-b16a-3474fdef7bf4	CREATE	2026-08-04 07:24:51.903041	POST /api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	Room	162.158.107.34	POST	/api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	\N
92a93435-11bb-4e15-8724-917a0474245c	DELETE	2026-08-04 07:25:14.402866	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	172.69.176.62	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
d0963624-2515-4103-9745-1da1d90ed4a0	CREATE	2026-08-04 07:25:25.603978	POST /api/rooms/b5000000-0000-0000-0000-000000000007/meter-readings	\N	Room	162.158.114.170	POST	/api/rooms/b5000000-0000-0000-0000-000000000007/meter-readings	\N	\N
7c94ee15-409d-4c45-8fe0-f1f5a797800d	DELETE	2026-08-04 07:26:14.765206	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	172.71.215.159	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
6f7f9881-029b-4771-b680-30552cfbc152	CREATE	2026-08-04 07:26:32.304035	POST /api/rooms/b5000000-0000-0000-0000-000000000009/meter-readings	\N	Room	104.23.175.18	POST	/api/rooms/b5000000-0000-0000-0000-000000000009/meter-readings	\N	\N
c7a0c411-0da0-43b5-94da-defaeba657a2	DELETE	2026-08-04 07:26:54.36051	DELETE /api/properties/b3000000-0000-0000-0000-000000000003	\N	Property	162.158.179.49	DELETE	/api/properties/b3000000-0000-0000-0000-000000000003	\N	\N
edbba1dd-3eee-4760-bbcd-e2e50a36b061	CREATE	2026-08-06 13:10:06.916558	POST /api/rooms/b5000000-0000-0000-0000-000000000009/meter-readings	\N	Room	162.159.98.51	POST	/api/rooms/b5000000-0000-0000-0000-000000000009/meter-readings	\N	\N
f5e63054-9e70-4ffc-9dd1-c604a9ac1a4c	CREATE	2026-08-06 13:10:25.435484	POST /api/rooms/b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6/meter-readings	\N	Room	172.71.215.15	POST	/api/rooms/b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6/meter-readings	\N	\N
1dc85061-f97a-4c60-ba55-479a437f572a	CREATE	2026-08-06 13:16:21.590075	POST /api/invoices/generate	\N	Invoice	172.71.152.77	POST	/api/invoices/generate	\N	\N
ed7f9818-08b3-4eba-bf1f-ec74568b574e	CREATE	2026-08-09 15:56:02.487628	POST /api/rooms/b5000000-0000-0000-0000-000000000013/meter-readings	\N	Room	104.23.175.246	POST	/api/rooms/b5000000-0000-0000-0000-000000000013/meter-readings	\N	\N
c5ca9670-36b4-45f1-8e2a-08a28ec9df67	CREATE	2026-08-09 15:56:06.085687	POST /api/rooms/e3d6477b-41ee-4b21-af42-6a9f042e6d08/meter-readings	\N	Room	172.68.211.105	POST	/api/rooms/e3d6477b-41ee-4b21-af42-6a9f042e6d08/meter-readings	\N	\N
a8e1927a-d17f-4259-bb3a-236b8acb5d48	CREATE	2026-08-09 15:56:16.279513	POST /api/rooms/b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6/meter-readings	\N	Room	172.71.218.225	POST	/api/rooms/b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6/meter-readings	\N	\N
5d0c7016-3f64-4f2b-a7b2-d3484add3ef2	CREATE	2026-08-09 15:56:16.980503	POST /api/rooms/b5000000-0000-0000-0000-000000000005/meter-readings	\N	Room	104.23.175.246	POST	/api/rooms/b5000000-0000-0000-0000-000000000005/meter-readings	\N	\N
b55c1afc-7b5f-44b5-b722-179166fd11c7	CREATE	2026-08-09 15:56:22.017946	POST /api/invoices/generate	\N	Invoice	104.23.175.247	POST	/api/invoices/generate	\N	\N
e2b15047-fb69-4942-b46a-71f4bff79c29	CREATE	2026-08-09 15:58:56.192752	POST /api/invoices/7c135337-f51e-49fa-8731-3768446542f0/request-cash	\N	Invoice	162.158.179.50	POST	/api/invoices/7c135337-f51e-49fa-8731-3768446542f0/request-cash	\N	\N
62c7092e-e0c3-41f7-92bb-3b4531d632cf	ASSIGN	2026-08-09 16:02:33.786315	POST /api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/assign	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/assign	\N	\N
f829e9fd-2622-4fe5-991a-19569371c2eb	RESOLVE	2026-08-09 16:08:45.695299	POST /api/maintenance/229d8e58-ffbe-44d4-8909-3e92985cfe8c/resolve	\N	MaintenanceRequest	104.23.175.246	POST	/api/maintenance/229d8e58-ffbe-44d4-8909-3e92985cfe8c/resolve	\N	\N
9534e783-8730-4c5f-9b41-c2828e50f91f	RESOLVE	2026-08-09 16:08:48.575955	POST /api/maintenance/229d8e58-ffbe-44d4-8909-3e92985cfe8c/resolve	\N	MaintenanceRequest	162.158.193.196	POST	/api/maintenance/229d8e58-ffbe-44d4-8909-3e92985cfe8c/resolve	\N	\N
44e5f9d1-94a2-4b71-93b3-9c789f244809	RESOLVE	2026-08-09 16:09:32.002622	POST /api/maintenance/229d8e58-ffbe-44d4-8909-3e92985cfe8c/resolve	\N	MaintenanceRequest	162.158.193.196	POST	/api/maintenance/229d8e58-ffbe-44d4-8909-3e92985cfe8c/resolve	\N	\N
f6e4f730-db68-457c-a70f-7548da76a3e7	RESOLVE	2026-08-09 16:09:59.4768	POST /api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	MaintenanceRequest	162.159.98.237	POST	/api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	\N
a9b51bb0-2509-46c0-9b8a-1e40df6b893b	DELETE	2026-08-04 07:24:44.060491	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	162.158.179.49	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
4c081b6e-a090-49c1-b41f-bb54061839e3	CREATE	2026-08-04 07:26:57.210984	POST /api/rooms/b5000000-0000-0000-0000-000000000005/meter-readings	\N	Room	172.68.164.62	POST	/api/rooms/b5000000-0000-0000-0000-000000000005/meter-readings	\N	\N
d23f81b4-c79d-4927-9d0c-38761fea9ca6	CREATE	2026-08-06 13:10:16.297774	POST /api/rooms/b5000000-0000-0000-0000-000000000005/meter-readings	\N	Room	162.159.98.50	POST	/api/rooms/b5000000-0000-0000-0000-000000000005/meter-readings	\N	\N
0ba61a06-eff2-4f04-b0a5-bd40e9c6bc35	CREATE	2026-08-06 13:10:39.456893	POST /api/rooms/b5000000-0000-0000-0000-000000000012/meter-readings	\N	Room	162.159.98.51	POST	/api/rooms/b5000000-0000-0000-0000-000000000012/meter-readings	\N	\N
ef455603-d854-44f3-b73c-ca3aea89f820	CREATE	2026-08-06 13:11:43.512797	POST /api/rooms/b5000000-0000-0000-0000-000000000018/meter-readings	\N	Room	162.159.98.51	POST	/api/rooms/b5000000-0000-0000-0000-000000000018/meter-readings	\N	\N
d3af0d93-4eb6-48fc-a8b4-a3a0f79c1584	CREATE	2026-08-06 13:12:09.292093	POST /api/rooms/b5000000-0000-0000-0000-000000000014/meter-readings	\N	Room	172.71.152.78	POST	/api/rooms/b5000000-0000-0000-0000-000000000014/meter-readings	\N	\N
fd29a232-7466-40e6-b9b2-409f4d45019b	CREATE	2026-08-06 13:12:42.396088	POST /api/invoices/generate	\N	Invoice	162.159.98.51	POST	/api/invoices/generate	\N	\N
297ebd8b-bcef-440d-8cb4-84c4c5abce55	CREATE	2026-08-06 13:12:46.519194	POST /api/invoices/generate	\N	Invoice	162.159.98.51	POST	/api/invoices/generate	\N	\N
7b00543b-64e0-43ef-8b8d-59842849a8de	CREATE	2026-08-06 13:12:57.405062	POST /api/invoices/generate	\N	Invoice	172.71.152.77	POST	/api/invoices/generate	\N	\N
5a8cdaf5-d846-46d7-be3a-efedf09b8811	CREATE	2026-08-09 15:56:08.997068	POST /api/rooms/b5000000-0000-0000-0000-000000000017/meter-readings	\N	Room	162.159.98.237	POST	/api/rooms/b5000000-0000-0000-0000-000000000017/meter-readings	\N	\N
8595c807-e4a5-445e-8d3b-fe7f29fef87a	CREATE	2026-08-09 15:56:37.979477	POST /api/invoices/generate	\N	Invoice	104.23.175.247	POST	/api/invoices/generate	\N	\N
3b4bb09c-8384-42c0-857b-da8aba6388e2	RESOLVE	2026-08-09 16:09:50.456087	POST /api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	MaintenanceRequest	104.23.175.246	POST	/api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	\N
952b5414-10a7-4892-9fef-2f74f57d4c0b	DELETE	2026-08-04 07:25:44.602684	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	172.70.93.65	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
078a1db4-97c5-4b91-9731-1556995f9520	CREATE	2026-08-06 13:11:04.098934	POST /api/rooms/b5000000-0000-0000-0000-000000000017/meter-readings	\N	Room	172.71.81.84	POST	/api/rooms/b5000000-0000-0000-0000-000000000017/meter-readings	\N	\N
10858a67-ca8a-44d4-bb15-c09b63c99e00	CREATE	2026-08-06 13:11:27.880238	POST /api/rooms/b5000000-0000-0000-0000-000000000025/meter-readings	\N	Room	172.68.211.105	POST	/api/rooms/b5000000-0000-0000-0000-000000000025/meter-readings	\N	\N
d8e5a9bc-808c-4505-81b9-d8402b7b6089	CREATE	2026-08-06 13:12:01.081278	POST /api/rooms/b5000000-0000-0000-0000-000000000016/meter-readings	\N	Room	162.158.179.49	POST	/api/rooms/b5000000-0000-0000-0000-000000000016/meter-readings	\N	\N
ab93d6a6-4eff-474d-b571-014ef9675d3e	CREATE	2026-08-06 13:12:17.401295	POST /api/rooms/b5000000-0000-0000-0000-000000000022/meter-readings	\N	Room	172.71.81.83	POST	/api/rooms/b5000000-0000-0000-0000-000000000022/meter-readings	\N	\N
7f620f0c-4890-4e40-b06a-387fe4ee1500	CREATE	2026-08-06 13:13:01.586327	POST /api/invoices/generate	\N	Invoice	172.71.81.83	POST	/api/invoices/generate	\N	\N
0779b3c3-19ea-46e8-bffb-6ce45f6336c0	CREATE	2026-08-06 13:13:20.1935	POST /api/invoices/generate	\N	Invoice	104.23.175.246	POST	/api/invoices/generate	\N	\N
f98d06aa-9f89-4db4-9dd8-f779365653a0	CREATE	2026-08-06 13:13:39.898066	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	162.158.114.171	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
1253a1e4-1e41-42a3-9b1c-cc71658723c8	CREATE	2026-08-06 13:14:01.877812	POST /api/invoices/7c135337-f51e-49fa-8731-3768446542f0/request-cash	\N	Invoice	172.68.211.104	POST	/api/invoices/7c135337-f51e-49fa-8731-3768446542f0/request-cash	\N	\N
c23c8f7b-154f-4557-bcaa-3bbd876a4fdf	CREATE	2026-08-09 15:56:10.880671	POST /api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	Room	162.158.179.50	POST	/api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	\N
f7ca9511-aff9-4ba0-a78f-61a10e72a26a	CREATE	2026-08-09 15:56:15.190492	POST /api/rooms/b5000000-0000-0000-0000-000000000007/meter-readings	\N	Room	172.68.211.105	POST	/api/rooms/b5000000-0000-0000-0000-000000000007/meter-readings	\N	\N
e76ceb5e-7de5-4079-b05e-9d67b9e3a85e	CREATE	2026-08-09 15:56:20.814346	POST /api/invoices/generate	\N	Invoice	162.159.98.237	POST	/api/invoices/generate	\N	\N
18508e7e-9a9a-4684-9ee9-35bc7440ffff	DELETE	2026-08-04 07:26:45.002774	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	172.69.176.63	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
ec52c89b-bc8c-4ed3-983d-f05a89a98ef0	DELETE	2026-08-04 07:27:15.503628	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	172.71.218.225	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
992b76e6-2eb8-4512-98e6-4a0d0a5ff706	CREATE	2026-08-04 07:27:18.808391	POST /api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	Room	104.23.175.18	POST	/api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	\N
64812645-2ff4-41c7-ab06-1d8677af2a7d	CREATE	2026-08-04 07:27:42.802554	POST /api/invoices/generate	\N	Invoice	104.23.175.147	POST	/api/invoices/generate	\N	\N
6d0ebca6-9ed4-4800-9bc1-c332dfc9e289	DELETE	2026-08-04 07:27:45.70379	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	172.71.215.160	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
1b4ce796-4ef3-4b14-97eb-f201a66362ad	DELETE	2026-08-04 07:28:15.858596	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	172.71.215.160	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
ac6120e4-1811-4ee4-ba19-27143737f541	CREATE	2026-08-04 07:28:20.764481	POST /api/notifications/999e6979-affe-4c85-965b-cc9051245cc1/read	\N	Notification	172.68.164.63	POST	/api/notifications/999e6979-affe-4c85-965b-cc9051245cc1/read	\N	\N
7195ed59-4114-4486-85ca-b4767ea43d89	UPDATE	2026-08-04 07:29:42.508603	PUT /api/properties/b3000000-0000-0000-0000-000000000001/rooms/b5000000-0000-0000-0000-000000000001	\N	Property	172.69.176.63	PUT	/api/properties/b3000000-0000-0000-0000-000000000001/rooms/b5000000-0000-0000-0000-000000000001	\N	\N
d13b0b5d-7846-4171-81b1-d89e94f401ae	UPDATE	2026-08-04 07:29:49.809603	PUT /api/properties/b3000000-0000-0000-0000-000000000001/rooms/b5000000-0000-0000-0000-000000000001	\N	Property	162.158.114.170	PUT	/api/properties/b3000000-0000-0000-0000-000000000001/rooms/b5000000-0000-0000-0000-000000000001	\N	\N
3a157793-4d2f-421c-b718-021e8e1fd095	RESOLVE	2026-08-04 07:30:49.202319	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
fd2befee-8c32-458f-bb2d-b605a5770b7b	RESOLVE	2026-08-04 07:30:50.35012	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
e5b7c43b-4aa7-482d-867f-143ccb6a4a46	RESOLVE	2026-08-04 07:30:52.541096	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
15bb95ec-ea36-4ecd-bf57-c3bec4cda29b	RESOLVE	2026-08-04 07:30:56.886902	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
b1aba850-a923-4624-808f-e906811c7c8e	ASSIGN	2026-08-04 07:30:58.002778	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/assign	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/assign	\N	\N
bcc4ece9-4bbf-494c-b9c3-6081567b3860	RESOLVE	2026-08-04 07:31:05.10873	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.70.93.64	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
997372a3-4259-4233-93c1-89a9f8bb0f53	ASSIGN	2026-08-04 07:31:20.403861	POST /api/maintenance/de307c0f-3c70-4767-9a77-6adb46585bb4/assign	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/de307c0f-3c70-4767-9a77-6adb46585bb4/assign	\N	\N
43a8b629-f9b0-4d35-bdd5-04d99817a2e0	RESOLVE	2026-08-04 07:31:21.403504	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.107.33	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
e14c7585-2736-456d-adca-7bad33be2302	CREATE	2026-08-04 07:32:36.706612	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/start	\N	MaintenanceRequest	172.71.215.160	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/start	\N	\N
0f9791c2-ce70-43c5-873c-ad56a00ab46b	CREATE	2026-08-04 07:34:22.812588	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
bfe72812-10ea-4f6b-9c1b-2bce342de947	CREATE	2026-08-04 07:34:24.707277	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
4c879d86-c1c6-4d65-a09f-c9502bd0b0c9	CREATE	2026-08-04 07:34:27.541987	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	162.158.193.196	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
11c9ef26-7e41-4b4d-acb5-13a32d8b2c8b	CREATE	2026-08-04 07:34:32.144573	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
1aea724c-57b1-4ca7-b0de-254230967db0	CREATE	2026-08-04 07:34:40.81133	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
ca8c5176-42b7-44ba-9410-bd5b9dad2442	CREATE	2026-08-04 07:34:57.71101	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
cff2d57b-3053-46fc-8c19-f040372e5e8e	CREATE	2026-08-04 07:35:28.451198	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	162.158.193.197	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
0da66dc9-daec-4178-b019-8ac8fecca20f	CREATE	2026-08-04 07:35:59.065944	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
0ba0637b-b78d-4d90-a580-b80e5b9e46d6	CREATE	2026-08-04 07:36:29.735438	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.68.164.62	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
b91b165d-220e-4c11-a32c-d6763b3398a8	CREATE	2026-08-04 07:37:00.414143	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
a6ce77b2-8010-46c5-b998-c559bdc65eac	CREATE	2026-08-04 07:37:31.093297	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.69.176.63	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
254e11f2-abaa-4a69-9cc1-864f6e940dd5	CREATE	2026-08-04 07:38:01.755531	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.68.164.62	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
a6f2a2ca-498a-472c-b4f4-01c00c94e3d1	CREATE	2026-08-04 07:38:32.435509	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.69.176.63	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
44a01b76-0127-4a91-b639-dca62274c7ce	CREATE	2026-08-04 07:39:03.190418	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
15a09f55-3e4c-4587-9aea-3fcd628ec444	CREATE	2026-08-04 07:39:33.828028	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
e7739a55-4910-4ac1-94a8-71162ae9f74d	CREATE	2026-08-04 07:40:04.632206	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	162.158.107.34	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
3ad8df35-8098-48dc-8db1-1c550259c668	CREATE	2026-08-04 07:40:35.372185	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.71.215.160	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
7e3d6aa7-5dd5-442d-9d22-a5d16f8c4281	CREATE	2026-08-04 07:41:06.060679	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
c8482605-a211-437f-91b7-734db37adacc	CREATE	2026-08-04 07:41:36.713614	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
54d030e3-ff65-4da6-b990-c17209fc54c7	CREATE	2026-08-04 07:42:07.418759	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
97329602-b807-4088-8e5c-71d3e6cbee3e	CREATE	2026-08-04 07:42:38.163994	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
aa6b938b-a69b-45d1-a009-7d8a54e1c290	CREATE	2026-08-04 07:43:08.864671	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
e776f888-7854-45a3-a092-1f6c36227572	CREATE	2026-08-04 07:43:39.528034	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
8083e0d4-2b52-4c99-ad0e-304546355769	CREATE	2026-08-04 07:44:10.248688	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
d1850d40-44bb-48b2-8fdc-dcef040ed635	CREATE	2026-08-04 07:44:40.905458	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
0d31d04a-f16d-479c-92ae-01205d588eb2	CREATE	2026-08-04 07:45:11.578029	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.70.208.106	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
8821f073-86a1-4dc2-b54b-9440c34c84d8	CREATE	2026-08-04 07:45:42.307958	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
31b20cae-e5a8-471e-9ce9-97cb1b8bf427	CREATE	2026-08-04 07:46:13.117286	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
f7863e91-16e1-4e8e-8fd8-3af459ec434a	CREATE	2026-08-04 07:46:43.861991	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.70.208.106	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
e76adc9e-1cb4-49c5-8112-f482702b9a77	CREATE	2026-08-04 07:47:14.70548	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
40c4a4ba-a7b6-4909-954e-a45dd9e52ee7	CREATE	2026-08-04 07:47:45.552975	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
30cf337f-8ac6-49f7-9e5f-c0a100c726c9	CREATE	2026-08-04 07:48:16.349189	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
52ffd643-523b-4d9a-bc51-4fa8e7446dfa	CREATE	2026-08-04 07:48:47.097271	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
89a61317-4a15-4ed4-bead-57882f5c10e6	CREATE	2026-08-04 07:49:17.85127	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
ab29e8a9-0e01-40db-8828-88c242240b6f	CREATE	2026-08-04 07:49:48.497692	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
37c6f780-95c3-4871-acae-4b03cbaca87a	RESOLVE	2026-08-04 07:50:15.921495	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
8052219f-2a09-4d4e-ba7b-7cc9eadc138d	RESOLVE	2026-08-04 07:50:46.071795	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
e00e908f-5e83-4f65-b4e2-a1d84d894d73	CREATE	2026-08-04 07:51:03.055224	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
8a7a42d3-d112-42df-a598-0033ccff7719	RESOLVE	2026-08-04 07:51:16.269069	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
41e5064e-fa96-4887-b6e9-95704be42927	CREATE	2026-08-04 07:56:14.455111	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.68.164.62	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
ffc5907b-46da-4e7c-b8ab-1b7dd72c5271	RESOLVE	2026-08-04 07:56:14.611171	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
a2d57364-08bb-448b-8cf0-54eb54e10d6e	RESOLVE	2026-08-04 07:56:44.76519	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.68.164.63	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
70775318-fbe1-4791-8203-b7123c2dd027	RESOLVE	2026-08-04 07:57:48.832468	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
7970c87d-cf1d-4804-940b-614bc298f536	RESOLVE	2026-08-04 07:58:19.009939	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
709fa0ee-3c48-456d-b7a6-f2d1f4867ee6	RESOLVE	2026-08-04 07:58:49.186915	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
9f243027-245a-4e6a-9297-04e885f2427c	RESOLVE	2026-08-04 07:59:19.506443	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.114.171	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
220598b3-e5e8-4c80-9e9a-b00356899a13	CREATE	2026-08-04 07:59:40.304074	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
cb43dc3f-afae-40a7-a0dc-743696c35903	RESOLVE	2026-08-04 07:59:49.649549	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
88cb49ca-4283-4a87-8019-caddd9240c9a	CREATE	2026-08-04 07:59:57.933573	POST /api/notifications/aa4c2260-197f-478a-945e-12d357655f97/read	\N	Notification	104.22.176.10	POST	/api/notifications/aa4c2260-197f-478a-945e-12d357655f97/read	\N	\N
8107bf2d-0657-499f-b701-99ae54c8aa81	UPDATE	2026-08-04 07:59:59.003836	PUT /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	162.158.179.49	PUT	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
d6787f52-f776-4756-a442-9b81a84035a7	RESOLVE	2026-08-04 08:00:11.807125	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.152.78	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
8914f43e-38e7-4003-823a-3690325158d9	RESOLVE	2026-08-04 08:00:12.934148	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.69.176.62	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
1e1dbb9f-99ea-4b8a-a6cf-db71d7aa12d4	RESOLVE	2026-08-04 08:00:19.785948	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
cbf63ac0-cd4a-44af-b03b-97df56fe305f	RESOLVE	2026-08-04 08:00:28.409297	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.107.34	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
bc05e301-c4c5-4592-b1f9-43a5f804aaab	RESOLVE	2026-08-04 08:00:40.700984	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
2d262461-a23a-42ee-afed-0f44baeadf08	RESOLVE	2026-08-04 08:01:40.784554	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
084df91f-b6dd-49f9-8454-bb8b946d6ef4	CREATE	2026-08-04 08:01:57.912218	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/materials	\N	MaintenanceRequest	172.70.208.106	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/materials	\N	\N
753b09df-314d-4f08-a064-13888581a127	DELETE	2026-08-04 08:02:24.108194	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	104.22.176.10	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
b11b726c-12a4-42d1-8648-d1f778327b23	DELETE	2026-08-04 08:02:32.210928	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	104.22.176.10	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
840f374b-eb3b-49fb-beab-f17413ad1ed9	CREATE	2026-08-06 13:12:40.373073	POST /api/invoices/generate	\N	Invoice	162.159.98.50	POST	/api/invoices/generate	\N	\N
1c207cdd-413f-4e58-be27-fa0285b065b9	CREATE	2026-08-06 13:15:58.990618	POST /api/invoices/generate	\N	Invoice	172.68.211.104	POST	/api/invoices/generate	\N	\N
bfc09441-ee3f-4c93-91a4-43caa8fd845d	CREATE	2026-08-06 13:17:20.302358	POST /api/invoices/generate	\N	Invoice	162.158.114.170	POST	/api/invoices/generate	\N	\N
71e010be-6ebd-4adb-96c4-6184bbad0ae8	CREATE	2026-08-06 13:18:10.939874	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	172.71.81.84	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
6740bda0-6cf9-4580-9786-3b4901aabca6	CREATE	2026-08-06 13:18:44.88585	POST /api/invoices/7c135337-f51e-49fa-8731-3768446542f0/request-cash	\N	Invoice	172.71.81.83	POST	/api/invoices/7c135337-f51e-49fa-8731-3768446542f0/request-cash	\N	\N
c464cb20-3401-4dc0-b938-768d7c8c0966	CREATE	2026-08-06 13:19:29.307041	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	172.71.152.78	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
1d2d043d-9eb9-40f2-98d1-8e6ba44c8a39	CREATE	2026-08-09 15:56:17.692283	POST /api/rooms/b5000000-0000-0000-0000-000000000009/meter-readings	\N	Room	172.71.218.224	POST	/api/rooms/b5000000-0000-0000-0000-000000000009/meter-readings	\N	\N
5b35c2e0-8643-46e8-b7f1-272334b18ad0	CREATE	2026-08-09 15:56:42.891662	POST /api/invoices/generate	\N	Invoice	162.159.98.237	POST	/api/invoices/generate	\N	\N
c30e19a4-83a0-442a-bb78-905c176f4307	CREATE	2026-08-09 16:03:51.879351	POST /api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/confirm-slot	\N	MaintenanceRequest	162.158.114.171	POST	/api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/confirm-slot	\N	\N
2973fa85-00fd-4cd9-940f-3e5f13ef3fb9	RESOLVE	2026-08-04 08:00:15.06513	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.70.143.168	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
72fe1eb5-0be8-48fc-8456-73fec8b2f8b7	RESOLVE	2026-08-04 08:00:19.174668	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.152.78	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
d21f7ee3-e4fc-4a31-9901-7972b20bac01	RESOLVE	2026-08-04 08:00:27.279786	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.22.176.10	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
d3434617-a1df-4356-a56f-72ed48b8a01c	RESOLVE	2026-08-04 08:00:43.388907	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.70.208.107	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
4359ba3a-7206-41a5-8bb4-a1dcda670b74	RESOLVE	2026-08-04 08:01:40.854715	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.114.171	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
022bc411-c6fd-4205-9d5c-b54a4524023b	DELETE	2026-08-04 08:02:17.923522	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	104.22.176.10	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
d183f604-68d9-4162-af02-411111582e09	DELETE	2026-08-04 08:02:20.023664	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	104.22.176.10	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
1f0a04a1-7f0b-4c0a-95b1-af2d4346cf34	CREATE	2026-08-04 08:02:21.924894	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	104.23.175.18	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
489b3582-c1a4-4fd5-a069-39f99f8ece8f	CREATE	2026-08-04 08:02:52.669746	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
f69d4011-ca60-4551-adcc-9b8f315ad1a0	RESOLVE	2026-08-04 08:03:19.373342	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.69.176.63	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
ef348d3f-662c-4071-8497-2c0ff0c5cb9b	CREATE	2026-08-06 13:13:51.730182	POST /api/invoices/generate	\N	Invoice	172.71.152.77	POST	/api/invoices/generate	\N	\N
989a4b99-272e-4c69-9e29-66d4d5c761f7	CREATE	2026-08-06 13:22:47.732534	POST /api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/request-cash	\N	Invoice	162.159.98.51	POST	/api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/request-cash	\N	\N
72a5b87a-05a5-4cdc-8c62-a1a8820c3713	CREATE	2026-08-09 16:05:34.682629	POST /api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/completion-images	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/completion-images	\N	\N
7f0aa48b-faa9-43ee-b597-45379377a339	RESOLVE	2026-08-16 16:03:19.879514	POST /api/maintenance/483e9cdc-246b-48a5-9a8f-2327910f2b03/resolve	\N	MaintenanceRequest	172.71.219.106	POST	/api/maintenance/483e9cdc-246b-48a5-9a8f-2327910f2b03/resolve	\N	\N
0b6aa180-a08f-4279-aa29-c0bd9f21057c	RESOLVE	2026-08-04 08:00:25.109456	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.68.164.63	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
4a19a266-6f18-470a-95af-508d79f0c0eb	RESOLVE	2026-08-04 08:00:26.255163	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.215.160	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
9fe4ed73-d203-47de-9730-4ca2bf713bb3	RESOLVE	2026-08-04 08:00:32.557214	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
b75ef10c-2c82-4127-bcbf-978fe1889c9f	CREATE	2026-08-04 08:00:50.028088	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
06fe4d34-176a-4774-a425-17ae55b27be5	CREATE	2026-08-04 08:01:20.65981	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.68.164.63	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
1188ac5a-81da-46c0-9526-b32aab48e4a6	CREATE	2026-08-04 08:01:37.287204	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/notes	\N	MaintenanceRequest	172.68.164.63	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/notes	\N	\N
c1f03cbe-985f-4d10-ac23-158fdf4171cb	RESOLVE	2026-08-04 08:01:49.079381	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.88.171	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
b231036c-700c-4b97-9d83-4c70034763d6	CREATE	2026-08-04 08:01:51.285259	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
bb4b9bc8-17f0-4219-ab5e-8433b14c20d0	DELETE	2026-08-04 08:02:16.816206	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	104.22.176.10	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
09e4ca33-0eb6-4b96-9746-b869d98769d9	RESOLVE	2026-08-04 08:02:19.185067	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.22.176.10	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
21d89ca6-1836-4651-9f7c-075567055529	DELETE	2026-08-04 08:02:48.391541	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	172.71.82.19	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
9318feea-681e-477c-896b-49593c12a032	RESOLVE	2026-08-04 08:02:49.278867	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.22.176.10	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
3d2450a6-cf8b-47d0-80d0-f6a024063e24	RESOLVE	2026-08-04 08:03:04.280472	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.114.171	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
68eb4804-2f3f-4d90-bec5-7cea0df88d68	RESOLVE	2026-08-04 08:03:04.357474	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
027f9ac6-46fd-46d0-831f-1430863823f6	DELETE	2026-08-04 08:03:18.482356	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	Property	172.69.176.63	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	\N	\N
620492cf-bead-4816-98a3-264451901820	RESOLVE	2026-08-04 08:03:34.499275	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
ef99956e-5231-4ced-aaf1-8ca775d5c6a1	RESOLVE	2026-08-04 08:03:34.610219	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
710bff0a-085a-452a-921b-379b0fc2b6cc	RESOLVE	2026-08-04 08:04:04.649665	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
9b7c2c71-9b35-4c43-b5b3-e87b53a1b833	RESOLVE	2026-08-04 08:04:04.828814	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
92aa858c-ab9e-4e42-88fd-a35e6f48a9a2	RESOLVE	2026-08-04 08:04:34.830491	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
37214a62-1169-4b0f-9eb8-3673484fa756	RESOLVE	2026-08-04 08:04:34.96332	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
34ed3288-d3b1-43ef-bac8-9ece334af2c5	RESOLVE	2026-08-04 08:05:04.998061	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
16b84411-b4ee-46f8-8d61-7c1ad48155f1	RESOLVE	2026-08-04 08:05:05.229135	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
b2a3f7c1-8328-48dc-b028-40d62aefc9b7	CREATE	2026-08-04 08:05:11.076145	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
c43fc93b-f57d-4b1b-958f-51389e5aedb0	CREATE	2026-08-04 08:05:41.746894	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.71.215.160	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
a1423834-fba7-4f4c-b2f5-f975300e384f	RESOLVE	2026-08-04 08:05:44.032082	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.68.211.105	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
3940ceae-546f-4502-9fc5-d126c102e3a7	RESOLVE	2026-08-04 08:05:44.203923	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
443c3dc8-dedb-4e15-9235-d376fda89fe1	RESOLVE	2026-08-04 08:06:26.546369	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
e9263d02-46fa-4a36-bd4d-78331bb6eaa9	RESOLVE	2026-08-04 08:06:26.632498	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
f565993c-21d0-4d3a-ac17-99d3940c781c	CREATE	2026-08-04 08:06:36.905669	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/tenant-confirm-slot	\N	MaintenanceRequest	172.68.211.105	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/tenant-confirm-slot	\N	\N
3e9c4086-bdec-432e-93fc-6cc997c39ca1	CREATE	2026-08-04 08:06:37.602901	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/tenant-confirm-slot	\N	MaintenanceRequest	172.68.211.105	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/tenant-confirm-slot	\N	\N
0b76751d-da7f-4159-9d0a-38edac3e4b81	CREATE	2026-08-04 08:06:43.973453	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
095e10d3-b71a-4a51-a348-f62a672ea7d6	CREATE	2026-08-04 08:06:56.512546	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
b80b903a-ad6e-4070-b50c-1fc864adde5a	CREATE	2026-08-04 08:10:14.964756	POST /api/properties	\N	Property	172.71.124.28	POST	/api/properties	\N	\N
0e45b86f-2f5a-4d01-b137-88c060ee21ac	CREATE	2026-08-04 08:06:58.122597	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
e7bf90c4-cd34-4602-9e4c-816abcb70381	CREATE	2026-08-04 08:07:11.122036	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
68de7858-2f0d-4e8e-b0e2-def54676e6a2	CREATE	2026-08-06 13:17:25.397763	POST /api/invoices/generate	\N	Invoice	162.158.193.196	POST	/api/invoices/generate	\N	\N
e33923c7-b1a7-4738-89cc-8ed170dab704	CREATE	2026-08-06 13:21:25.285832	POST /api/notifications/1f91599c-f6eb-4404-ac1f-6e11d0f69806/read	\N	Notification	162.159.98.51	POST	/api/notifications/1f91599c-f6eb-4404-ac1f-6e11d0f69806/read	\N	\N
09a46473-8d8a-49a9-b487-b6d816a0d582	CREATE	2026-08-06 13:22:13.023227	POST /api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/request-cash	\N	Invoice	162.159.98.50	POST	/api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/request-cash	\N	\N
63db14c4-55b8-4d56-9feb-7ad733420f1b	RENEW	2026-08-13 09:30:09.296942	POST /api/contracts/b6000000-0000-0000-0000-000000000001/renew	\N	Contract	104.22.176.10	POST	/api/contracts/b6000000-0000-0000-0000-000000000001/renew	\N	\N
b4c05724-9d11-429c-aae3-ae6f089a4cdb	RESOLVE	2026-08-16 16:03:22.432034	POST /api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	MaintenanceRequest	172.71.219.106	POST	/api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	\N
bde170ad-58dc-4e6d-bdde-6920ba5aaa55	CREATE	2026-08-04 08:07:00.727345	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
a049e5b2-77aa-4cc5-9325-8d50f2245864	CREATE	2026-08-04 08:08:15.907966	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
1f99657f-b0a6-499e-81c6-5797db22f22b	DELETE	2026-08-04 08:09:19.833457	DELETE /api/property-types/5b8e8e79-29c7-4d05-a262-6039268cbe25	\N	Unknown	172.70.189.48	DELETE	/api/property-types/5b8e8e79-29c7-4d05-a262-6039268cbe25	\N	\N
5f49fc5b-9ae1-4bbb-b908-ec409016ea35	CREATE	2026-08-04 08:09:38.314127	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
1f9502b4-58bd-4569-a9b5-50d290022770	RESOLVE	2026-08-04 08:10:40.414108	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
ff377529-5f63-4cfc-b359-9a683acf01ac	CREATE	2026-08-04 08:10:47.778063	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.71.215.160	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
f7d14fc3-de4b-4b8a-b3e7-ffdaca8fba17	RESOLVE	2026-08-04 08:11:40.718582	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
676d6483-52d0-480e-b242-34cfd924443a	CREATE	2026-08-04 08:11:55.157188	POST /api/notifications/e7496d55-6df6-4223-aa2a-4b6291de7b69/read	\N	Notification	162.159.98.51	POST	/api/notifications/e7496d55-6df6-4223-aa2a-4b6291de7b69/read	\N	\N
c1a0945f-d8ef-448a-851c-f0c5871d4fc6	RESOLVE	2026-08-04 08:14:11.60277	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
8e8dca21-5251-485a-922b-6bf2a324b1b3	RESOLVE	2026-08-04 08:15:12.025623	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
ae754644-c07c-4877-8592-3939b597d012	CREATE	2026-08-04 08:15:46.101393	POST /api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/request-cash	\N	Invoice	172.71.152.78	POST	/api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/request-cash	\N	\N
2a0fad6a-cc85-411a-a6ad-d02fc30a7932	PAYMENT	2026-08-04 08:15:54.997358	POST /api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/pay-online	\N	Invoice	172.70.208.106	POST	/api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/pay-online	\N	\N
46ece781-ff29-4ffc-a945-b71a1cbab391	RESOLVE	2026-08-04 08:16:12.425906	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
f8935e35-d646-4a2d-ac2b-7f4f4278caee	RESOLVE	2026-08-04 08:18:13.315	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.193.196	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
e3e685f6-0b32-4288-acfa-c17ad0312a94	CREATE	2026-08-06 13:22:37.698779	POST /api/invoices/generate	\N	Invoice	162.158.193.196	POST	/api/invoices/generate	\N	\N
4723f234-83c0-4b62-8f36-bd87d7476978	CREATE	2026-08-14 04:12:01.073659	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	162.158.107.34	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
ff1656b9-d7c1-4bf6-9d08-0f233de54d4e	CREATE	2026-08-14 04:12:19.873052	POST /api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	Room	104.23.175.246	POST	/api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	\N
6e15d203-6306-4ab2-9186-d2b34b04369c	CREATE	2026-08-14 04:12:29.668106	POST /api/rooms/b5000000-0000-0000-0000-000000000012/meter-readings	\N	Room	172.70.93.110	POST	/api/rooms/b5000000-0000-0000-0000-000000000012/meter-readings	\N	\N
480726a0-37d3-4d50-8362-d8e89c7f4664	CREATE	2026-08-14 04:23:26.527208	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.68.242.120	POST	/api/maintenance/with-images	\N	\N
e37ef6f7-98cc-4fb5-afec-e4e175f68108	CREATE	2026-08-19 06:50:54.572798	POST /api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	Room	172.68.164.170	POST	/api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	\N
bb2c9175-178d-4192-b452-16603aa4ef70	CREATE	2026-08-19 06:50:56.169612	POST /api/rooms/b5000000-0000-0000-0000-000000000007/meter-readings	\N	Room	172.68.164.170	POST	/api/rooms/b5000000-0000-0000-0000-000000000007/meter-readings	\N	\N
c900d20b-561c-4bd8-a123-794a4d3da772	CREATE	2026-08-19 06:50:59.555205	POST /api/rooms/b5000000-0000-0000-0000-000000000005/meter-readings	\N	Room	162.158.163.126	POST	/api/rooms/b5000000-0000-0000-0000-000000000005/meter-readings	\N	\N
f5a319b8-af68-4515-bf25-e6113b87743d	CREATE	2026-08-19 06:51:00.758632	POST /api/rooms/b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6/meter-readings	\N	Room	162.158.163.126	POST	/api/rooms/b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6/meter-readings	\N	\N
1a4cd26d-0874-4ae8-a785-6259f14c695d	CREATE	2026-08-19 06:51:11.870272	POST /api/rooms/ce27f631-b495-48aa-9fc5-c60ec18a95eb/meter-readings	\N	Room	104.23.175.247	POST	/api/rooms/ce27f631-b495-48aa-9fc5-c60ec18a95eb/meter-readings	\N	\N
7b11a8ec-3f63-4fe9-835b-c95792bd0ac0	CREATE	2026-08-19 06:51:21.070954	POST /api/rooms/b5000000-0000-0000-0000-000000000024/meter-readings	\N	Room	172.70.93.110	POST	/api/rooms/b5000000-0000-0000-0000-000000000024/meter-readings	\N	\N
b3a9fe99-4b9f-4acf-8a19-63ed4f34b6a1	CREATE	2026-08-19 06:51:25.063222	POST /api/rooms/b5000000-0000-0000-0000-000000000022/meter-readings	\N	Room	172.68.164.170	POST	/api/rooms/b5000000-0000-0000-0000-000000000022/meter-readings	\N	\N
dfef779f-b636-4b84-bc3e-f9db632f482d	CREATE	2026-08-19 06:57:25.554898	POST /api/invoices/generate	\N	Invoice	162.158.108.39	POST	/api/invoices/generate	\N	\N
63772b03-6a9c-4078-bf29-0e551f4e6895	RESOLVE	2026-08-19 07:00:11.855124	POST /api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	MaintenanceRequest	104.22.176.10	POST	/api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	\N
fa84df1d-b529-4d78-a83e-3905d64f7b29	CREATE	2026-08-19 07:01:49.673724	POST /api/users	\N	User	104.22.176.21	POST	/api/users	\N	\N
b3970224-8c9e-43a5-83ee-4e7e0fb5f2c4	CREATE	2026-08-19 07:06:13.280555	POST /api/maintenance/with-images	\N	MaintenanceRequest	162.158.88.170	POST	/api/maintenance/with-images	\N	\N
81f24226-97c6-443a-bc97-0358d489083d	CREATE	2026-08-19 07:06:40.096994	POST /api/maintenance/c05e9333-2746-4b7f-9a01-8182f91ffa93/cancel	\N	MaintenanceRequest	162.158.108.39	POST	/api/maintenance/c05e9333-2746-4b7f-9a01-8182f91ffa93/cancel	\N	\N
936f1a79-0797-4ae8-addc-526edfac499e	ASSIGN	2026-08-19 07:06:45.475097	POST /api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/assign	\N	MaintenanceRequest	162.158.88.170	POST	/api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/assign	\N	\N
539854a6-9827-4dad-9f95-5c848f82084d	CREATE	2026-08-19 07:06:48.422618	POST /api/notifications/8e48f483-b1e9-4eaa-81c0-b8b3be30d2b2/read	\N	Notification	162.158.108.39	POST	/api/notifications/8e48f483-b1e9-4eaa-81c0-b8b3be30d2b2/read	\N	\N
ddc06edb-5222-4a9d-afb3-9aca5ddf9288	CREATE	2026-08-19 07:06:54.084452	POST /api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/confirm-slot	\N	MaintenanceRequest	162.158.163.126	POST	/api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/confirm-slot	\N	\N
5999427a-5d6f-48b7-88ac-90f2fd837352	CREATE	2026-08-19 07:07:06.656011	POST /api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/tenant-confirm-slot	\N	MaintenanceRequest	162.158.108.39	POST	/api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/tenant-confirm-slot	\N	\N
50054656-9290-41a7-8ac6-874aa7ad74a8	CREATE	2026-08-19 07:07:09.66797	POST /api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/start	\N	MaintenanceRequest	162.158.108.39	POST	/api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/start	\N	\N
03c6f0c8-2232-483d-af36-77a8b143b466	CREATE	2026-08-04 08:07:14.662998	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	162.158.193.197	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
cd405d5c-7ed6-4f2d-9c77-6f6d415c6c29	CREATE	2026-08-04 08:07:19.732161	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
e776ddfd-3952-4d1e-a20c-937637b8b06e	CREATE	2026-08-04 08:07:36.359871	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
a9bb494f-6b21-4463-b611-28f4a3da9a50	CREATE	2026-08-04 08:07:45.290712	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.68.164.63	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
66a710f4-798f-4848-9f44-ea51d978a976	CREATE	2026-08-04 08:08:07.071146	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	162.158.193.197	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
b9a1452e-acf9-45f3-af18-d406543fdeb6	CREATE	2026-08-04 08:08:46.590259	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
12614951-2909-4b58-930a-6d3ae9ae0cfa	DELETE	2026-08-04 08:10:17.543832	DELETE /api/properties/c7297a51-0a69-4e2a-b72b-58f2081647b6	\N	Property	172.71.124.28	DELETE	/api/properties/c7297a51-0a69-4e2a-b72b-58f2081647b6	\N	\N
e2d008f9-668b-4787-8e2f-ed326149e788	RESOLVE	2026-08-04 08:10:40.354994	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.107.33	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
7a36fd85-0a10-4af5-9519-1d5113fc5bfc	CREATE	2026-08-04 08:11:34.843954	POST /api/notifications/7b3f7829-cbf9-44e9-9e7f-ec8abd6eb124/read	\N	Notification	172.69.176.63	POST	/api/notifications/7b3f7829-cbf9-44e9-9e7f-ec8abd6eb124/read	\N	\N
58db71c2-0304-4b64-a721-8cad0b4a3eb0	RESOLVE	2026-08-04 08:12:41.023544	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.68.164.63	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
0205b635-3745-4d23-ba51-54c7657d2404	CREATE	2026-08-04 08:14:11.60989	POST /api/invoices/generate	\N	Invoice	162.158.108.109	POST	/api/invoices/generate	\N	\N
8b7c294a-bc87-4fb2-8434-3364b951c748	CREATE	2026-08-04 08:15:28.633887	POST /api/notifications/fc2c27e7-0942-43ea-8dc4-0b72074345f4/read	\N	Notification	172.70.93.64	POST	/api/notifications/fc2c27e7-0942-43ea-8dc4-0b72074345f4/read	\N	\N
c73c6543-3072-4ff5-b111-5d7cc1f2c4ce	CREATE	2026-08-04 08:17:30.099685	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.68.211.105	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
3112f8b4-f13e-4f54-8dd0-c4b24da0870d	CREATE	2026-08-04 08:17:30.128378	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
0f1dd768-c7eb-4a2a-bbd5-994b5dd339c4	CREATE	2026-08-06 13:22:53.554466	POST /api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/request-cash	\N	Invoice	162.158.193.196	POST	/api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/request-cash	\N	\N
02162a97-93d9-4eeb-81cf-ed3934967e14	CREATE	2026-08-14 04:12:21.866383	POST /api/rooms/b5000000-0000-0000-0000-000000000007/meter-readings	\N	Room	172.71.124.28	POST	/api/rooms/b5000000-0000-0000-0000-000000000007/meter-readings	\N	\N
dbf03725-e097-487e-bd51-940757d97410	CREATE	2026-08-14 04:12:23.369095	POST /api/rooms/b5000000-0000-0000-0000-000000000009/meter-readings	\N	Room	172.70.93.110	POST	/api/rooms/b5000000-0000-0000-0000-000000000009/meter-readings	\N	\N
683924e6-5d0e-47c2-a0d4-237ece775395	CREATE	2026-08-14 04:12:34.371897	POST /api/rooms/b5000000-0000-0000-0000-000000000017/meter-readings	\N	Room	172.70.93.110	POST	/api/rooms/b5000000-0000-0000-0000-000000000017/meter-readings	\N	\N
8b49ba94-3dc1-4dde-9bc3-bc5f1a80f83e	CREATE	2026-08-14 04:12:37.362372	POST /api/rooms/ce27f631-b495-48aa-9fc5-c60ec18a95eb/meter-readings	\N	Room	172.71.81.99	POST	/api/rooms/ce27f631-b495-48aa-9fc5-c60ec18a95eb/meter-readings	\N	\N
5a5c1a99-30b3-45c4-85df-07f0c2607c4c	CREATE	2026-08-14 04:12:38.761622	POST /api/rooms/e3d6477b-41ee-4b21-af42-6a9f042e6d08/meter-readings	\N	Room	104.22.176.10	POST	/api/rooms/e3d6477b-41ee-4b21-af42-6a9f042e6d08/meter-readings	\N	\N
a68f1e70-4c0c-419f-98ce-b40f930af88e	CREATE	2026-08-19 06:50:58.159947	POST /api/rooms/b5000000-0000-0000-0000-000000000009/meter-readings	\N	Room	172.71.124.13	POST	/api/rooms/b5000000-0000-0000-0000-000000000009/meter-readings	\N	\N
175efab5-ab44-445b-8d59-9d79ff136a5c	CREATE	2026-08-19 06:51:04.057335	POST /api/rooms/b5000000-0000-0000-0000-000000000012/meter-readings	\N	Room	172.68.164.170	POST	/api/rooms/b5000000-0000-0000-0000-000000000012/meter-readings	\N	\N
2fc844a5-0dec-43b9-81f9-d37afd039033	CREATE	2026-08-04 08:08:37.658593	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
7a7a42a7-20a9-48a4-a6f5-4b5c69069c60	CREATE	2026-08-04 08:09:08.299347	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
aea17059-007e-4617-9ab3-74ccfc94b3f3	CREATE	2026-08-04 08:09:12.471336	POST /api/property-types	\N	Unknown	172.71.124.28	POST	/api/property-types	\N	\N
904f4b8d-0ea5-4224-b4c7-a1d168419a75	CREATE	2026-08-04 08:09:12.728421	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
b17a6338-d87c-4644-a3a3-2b05012445ed	CREATE	2026-08-04 08:09:14.451493	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
a05aef5f-fcad-4199-981e-e6fe7515e8eb	CREATE	2026-08-04 08:09:17.303695	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
3a917aec-6867-4007-b336-cdc4988ea319	CREATE	2026-08-04 08:09:21.978982	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
97872c01-d40b-4643-85cd-a7113d60cac7	CREATE	2026-08-04 08:09:30.798939	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	162.158.114.170	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
19d29bd1-e172-46b6-9cbd-2735c8eca382	CREATE	2026-08-04 08:09:38.92824	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
8e0fa51a-5bd0-47a8-a991-80a9ef8c72f5	RESOLVE	2026-08-04 08:09:40.01789	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
b29868a3-c932-4422-8aab-de54da0dc731	RESOLVE	2026-08-04 08:09:40.092289	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
4a74408b-c73a-491d-8859-bc7dfc64bbd2	CREATE	2026-08-04 08:09:47.888978	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
f72cc31b-dc97-44ab-ab75-229bcb762d1a	CREATE	2026-08-04 08:10:03.400911	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
4c40a6ec-1253-419b-861c-08cb34795200	CREATE	2026-08-04 08:10:05.087879	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	162.158.107.33	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
3d0c0ee5-fcd2-4975-acf7-92c480e1fbbe	RESOLVE	2026-08-04 08:10:10.190331	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
6797b943-4dc1-4097-b30e-b813a4e56982	RESOLVE	2026-08-04 08:10:10.264365	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
dcd644d8-c283-4e82-ab2b-4de95cec56ac	CREATE	2026-08-04 08:10:27.329611	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.71.215.160	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
d907f884-e439-4c53-af23-7b2add3f2097	CREATE	2026-08-04 08:10:47.691321	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	162.158.114.170	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
b47f02d4-2159-4b11-b125-cb1d2af7832b	RESOLVE	2026-08-04 08:11:10.564983	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
8fb7532b-934b-4213-a82c-a072fc01f784	RESOLVE	2026-08-04 08:11:10.570809	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.215.159	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
5d7012bb-6cac-4e86-a245-1fdb56d38d5a	CREATE	2026-08-04 08:11:36.697587	POST /api/notifications/e7496d55-6df6-4223-aa2a-4b6291de7b69/read	\N	Notification	172.69.176.63	POST	/api/notifications/e7496d55-6df6-4223-aa2a-4b6291de7b69/read	\N	\N
72505f82-9239-4bcc-a104-28759529fc70	RESOLVE	2026-08-04 08:11:40.70999	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.68.211.105	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
168a84e9-9aa4-4c7a-87ab-988a1b9ad4cf	CREATE	2026-08-04 08:11:55.065209	POST /api/notifications/d9f96b74-89ee-4f79-aa72-a1c264064db7/read	\N	Notification	172.71.215.159	POST	/api/notifications/d9f96b74-89ee-4f79-aa72-a1c264064db7/read	\N	\N
bf689e64-2af6-4ae4-b2d6-684940bc136f	CREATE	2026-08-04 08:11:55.066883	POST /api/notifications/7b3f7829-cbf9-44e9-9e7f-ec8abd6eb124/read	\N	Notification	172.71.215.159	POST	/api/notifications/7b3f7829-cbf9-44e9-9e7f-ec8abd6eb124/read	\N	\N
3297b6d0-bb31-4135-b6a1-4c96569fc54f	RESOLVE	2026-08-04 08:12:10.86738	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
0143b090-738f-4c71-9505-e9bfc1043655	RESOLVE	2026-08-04 08:13:11.130161	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
ba77577c-bb9f-42d7-a9bc-ca84ad6c2cad	RESOLVE	2026-08-04 08:13:11.185757	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.68.164.63	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
f77679b7-5d45-4144-9098-32dbbbb38275	RESOLVE	2026-08-04 08:13:41.290525	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.107.34	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
4ab60c29-57de-410d-860b-dc9379f8a4df	RESOLVE	2026-08-04 08:13:41.334324	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
0a7f2bfd-aece-4ee9-907f-a23e08d5c3da	RESOLVE	2026-08-04 08:14:11.703781	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
d974ab63-25d6-40a0-9586-f35b0bf6b33f	CREATE	2026-08-04 08:14:16.102781	POST /api/invoices/generate	\N	Invoice	172.71.82.19	POST	/api/invoices/generate	\N	\N
cdaafa16-aa46-4aba-b09d-4368b6d72536	RESOLVE	2026-08-04 08:14:41.86625	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
0df71de2-043a-489e-a235-5484bd9d5996	RESOLVE	2026-08-04 08:14:41.906023	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
a3d61fbf-f195-4f27-a56b-29d7f0553fbb	RESOLVE	2026-08-04 08:15:12.112094	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
6b1a18a8-626f-4896-b58d-d8ce90ce7037	CREATE	2026-08-04 08:11:35.836613	POST /api/notifications/d9f96b74-89ee-4f79-aa72-a1c264064db7/read	\N	Notification	172.71.218.225	POST	/api/notifications/d9f96b74-89ee-4f79-aa72-a1c264064db7/read	\N	\N
aece5f61-20c7-4120-ab03-98f1da0d4194	RESOLVE	2026-08-04 08:12:40.999478	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
4b0e0df0-7d24-44d5-8bed-64d99b5d4ced	PAYMENT	2026-08-04 08:16:08.056242	POST /api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/pay-online	\N	Invoice	172.70.143.168	POST	/api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/pay-online	\N	\N
1269fc7b-06d2-444f-8905-2e834fb496d3	CREATE	2026-08-04 08:16:20.124065	POST /api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/request-cash	\N	Invoice	172.71.152.77	POST	/api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/request-cash	\N	\N
023d7748-1c42-4f74-a785-0c0da422c58f	RESOLVE	2026-08-04 08:16:42.614789	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
d9b070d0-8e35-40da-aa3d-213013300214	RESOLVE	2026-08-04 08:17:12.831906	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
5e155eb7-b687-410d-8601-e74e4d12f0a2	CREATE	2026-08-06 13:24:57.890618	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	172.71.218.225	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
d06f6075-c2a8-4aa8-a22a-b5a0196a1a14	CREATE	2026-08-06 13:27:23.39586	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	172.68.211.104	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
468e0ea1-d965-484d-a3a1-019959a27f1c	CREATE	2026-08-06 13:27:50.212736	POST /api/invoices/generate	\N	Invoice	172.71.124.13	POST	/api/invoices/generate	\N	\N
0ca21470-b0c9-4b86-9949-0dd3003ea1d1	CREATE	2026-08-06 13:28:58.603325	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	172.71.215.16	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
ff17f370-5f24-470c-ade0-1e7dee9431ac	CREATE	2026-08-06 13:29:03.421493	POST /api/invoices/generate	\N	Invoice	104.23.175.247	POST	/api/invoices/generate	\N	\N
34118229-6dab-41d6-b255-fb9be4da4763	CREATE	2026-08-06 13:30:47.001505	POST /api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings/hunonic-sync	\N	Room	172.71.152.78	POST	/api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings/hunonic-sync	\N	\N
6b030580-127f-4cf7-9d85-c7c41537ccdc	CREATE	2026-08-06 13:30:49.873577	POST /api/invoices/generate	\N	Invoice	172.71.218.224	POST	/api/invoices/generate	\N	\N
37ebd4c8-b55a-406b-a73d-4863a450a2c1	CREATE	2026-08-14 04:12:24.766561	POST /api/rooms/b5000000-0000-0000-0000-000000000005/meter-readings	\N	Room	172.70.189.115	POST	/api/rooms/b5000000-0000-0000-0000-000000000005/meter-readings	\N	\N
d20475a6-08c1-4019-9054-edc2f4f0e4df	CREATE	2026-08-14 04:12:39.766689	POST /api/rooms/fcf45ae0-98ba-4018-8181-1a9dbab9a472/meter-readings	\N	Room	172.71.124.13	POST	/api/rooms/fcf45ae0-98ba-4018-8181-1a9dbab9a472/meter-readings	\N	\N
7d6b1314-5dab-4aae-82d6-a13518617f11	CREATE	2026-08-14 04:17:29.662584	POST /api/invoices/generate	\N	Invoice	172.70.93.110	POST	/api/invoices/generate	\N	\N
8b4cffe0-1d20-45d3-b9d2-c9e6ba29ffe9	CREATE	2026-08-19 06:51:02.463345	POST /api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	Room	172.70.143.215	POST	/api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	\N
6d5cff3c-7b68-4cde-93dc-3178d420ac15	CREATE	2026-08-19 06:51:15.066643	POST /api/rooms/fcf45ae0-98ba-4018-8181-1a9dbab9a472/meter-readings	\N	Room	162.158.190.116	POST	/api/rooms/fcf45ae0-98ba-4018-8181-1a9dbab9a472/meter-readings	\N	\N
f682b90a-b6a2-4470-99b4-1d48e6bc1e18	PAYMENT	2026-08-19 06:52:34.062263	POST /api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/pay-cash	\N	Invoice	162.158.108.38	POST	/api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/pay-cash	\N	\N
aa22d06f-ebea-4e04-8519-cefb1b662e12	CREATE	2026-08-19 06:57:07.582403	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	104.22.176.21	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
a294532b-4c2b-4c00-b160-2b2f798fa120	RESOLVE	2026-08-19 07:00:10.009823	POST /api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	MaintenanceRequest	104.22.176.10	POST	/api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	\N
d1db16fe-bd03-4f5f-8d72-598ab7738c10	RESOLVE	2026-08-19 07:00:10.584249	POST /api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	MaintenanceRequest	104.22.176.10	POST	/api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	\N
be3a4fb4-63f8-42c1-b950-fd27d7968e71	CREATE	2026-08-19 07:04:02.076234	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.70.208.106	POST	/api/maintenance/with-images	\N	\N
c5e5c9c2-2a5a-4f14-ba23-6b3c9fd7add5	RESOLVE	2026-08-04 08:12:10.864443	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
0407a686-574a-4ab0-a634-82a73fde614f	CREATE	2026-08-04 08:12:47.207709	POST /api/rooms/b5000000-0000-0000-0000-000000000003/contracts	\N	Room	104.22.176.10	POST	/api/rooms/b5000000-0000-0000-0000-000000000003/contracts	\N	\N
566e6afa-db6a-4125-9817-e4a5f63ca308	CREATE	2026-08-04 08:13:57.809755	POST /api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	Room	172.71.82.19	POST	/api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	\N
da4cdf67-dd8e-40a8-afbb-500741479af2	CREATE	2026-08-04 08:14:00.419339	POST /api/invoices/generate	\N	Invoice	104.22.176.10	POST	/api/invoices/generate	\N	\N
08981f09-0be6-4bc7-aa8b-d7e12ec28aec	RESOLVE	2026-08-04 08:15:42.369717	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
d8477a91-c286-4c69-84f5-72187273e813	PAYMENT	2026-08-04 08:15:55.310489	POST /api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/pay-online	\N	Invoice	172.71.152.77	POST	/api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/pay-online	\N	\N
ce65995f-590e-4920-a9c6-9eed0904c4d2	PAYMENT	2026-08-04 08:16:08.230501	POST /api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/pay-online	\N	Invoice	172.70.143.168	POST	/api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/pay-online	\N	\N
2b2cd157-0cd7-4b9d-9cdc-f5d96f52d642	RESOLVE	2026-08-04 08:16:42.719269	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
349d49e4-8bac-4706-a346-ce61c641e380	RESOLVE	2026-08-04 08:17:13.021878	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.179.50	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
d132aec7-59cf-4618-9ee6-4df06b05e0a9	RESOLVE	2026-08-04 08:17:43.000834	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
c0cb1c98-8ca7-4022-bc5a-933b6402c7ab	RESOLVE	2026-08-04 08:18:13.614646	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
d37f8e38-7db3-4049-9d17-972286dc1da9	CREATE	2026-08-06 13:25:01.513328	POST /api/invoices/generate	\N	Invoice	162.158.114.171	POST	/api/invoices/generate	\N	\N
de19c127-5840-41c3-980f-92fed05d9c3f	CREATE	2026-08-06 13:25:20.768159	POST /api/invoices/generate	\N	Invoice	162.158.114.171	POST	/api/invoices/generate	\N	\N
df9cd8f5-84fb-48f0-ae0f-916de50e014a	CREATE	2026-08-06 13:30:32.001147	POST /api/invoices/generate	\N	Invoice	172.71.218.224	POST	/api/invoices/generate	\N	\N
2698a8af-5b85-4231-837f-58c2ca04ff16	CREATE	2026-08-06 13:30:43.565425	POST /api/invoices/generate	\N	Invoice	172.71.218.224	POST	/api/invoices/generate	\N	\N
bb410d9a-9e6f-46b3-844f-037ef96afb1c	CREATE	2026-08-06 13:31:37.951316	POST /api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	Room	162.158.114.171	POST	/api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	\N
3b4e9db3-64b9-401e-bfc1-15e235982f2e	CREATE	2026-08-06 13:32:16.450821	POST /api/rooms/b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6/meter-readings	\N	Room	172.71.218.225	POST	/api/rooms/b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6/meter-readings	\N	\N
4e9502f8-6e3c-43bc-84ed-3280835eb1e9	CREATE	2026-08-14 04:12:25.962853	POST /api/rooms/b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6/meter-readings	\N	Room	172.70.208.107	POST	/api/rooms/b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6/meter-readings	\N	\N
3fb192e5-1be5-4b1b-9817-a64d53aab7b6	CREATE	2026-08-14 04:12:42.170954	POST /api/rooms/b5000000-0000-0000-0000-000000000013/meter-readings	\N	Room	172.70.189.115	POST	/api/rooms/b5000000-0000-0000-0000-000000000013/meter-readings	\N	\N
c169af52-a21e-4421-8e86-7af1c6a5459a	CREATE	2026-08-14 04:15:27.063745	POST /api/invoices/generate	\N	Invoice	162.158.108.38	POST	/api/invoices/generate	\N	\N
92103239-d7e6-49cd-8561-c9f3acd9d544	CREATE	2026-08-14 04:20:43.572462	POST /api/maintenance/with-images	\N	MaintenanceRequest	162.158.88.170	POST	/api/maintenance/with-images	\N	\N
6604a705-2f8b-421a-879a-5a1e8b623e7e	CREATE	2026-08-14 04:26:35.914438	POST /api/invoices/generate	\N	Invoice	172.68.211.104	POST	/api/invoices/generate	\N	\N
de12bbff-1ac8-4474-ac8e-72ed74932704	CREATE	2026-08-19 06:51:05.559391	POST /api/rooms/b5000000-0000-0000-0000-000000000003/meter-readings	\N	Room	172.68.164.170	POST	/api/rooms/b5000000-0000-0000-0000-000000000003/meter-readings	\N	\N
3af9bccc-5d34-4451-8b9f-0c33264e7c1f	CREATE	2026-08-19 06:51:10.066375	POST /api/rooms/b5000000-0000-0000-0000-000000000010/meter-readings	\N	Room	162.158.163.126	POST	/api/rooms/b5000000-0000-0000-0000-000000000010/meter-readings	\N	\N
b4f9d102-ab35-433e-9284-bb91ed01dc6f	CREATE	2026-08-19 06:51:19.666555	POST /api/rooms/b5000000-0000-0000-0000-000000000018/meter-readings	\N	Room	172.71.152.75	POST	/api/rooms/b5000000-0000-0000-0000-000000000018/meter-readings	\N	\N
660e7412-5e20-48b1-880b-ce41b57d7369	CREATE	2026-08-19 06:51:22.459291	POST /api/rooms/b5000000-0000-0000-0000-000000000016/meter-readings	\N	Room	172.71.81.99	POST	/api/rooms/b5000000-0000-0000-0000-000000000016/meter-readings	\N	\N
31eaf58b-aac3-4706-bd4a-47731ddd4ac0	PAYMENT	2026-08-19 06:52:29.056399	POST /api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-cash	\N	Invoice	172.69.176.63	POST	/api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-cash	\N	\N
cf3fc3a6-5c8d-4703-92e3-f5a75aac2885	PAYMENT	2026-08-19 06:52:35.555068	POST /api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-cash	\N	Invoice	162.158.108.38	POST	/api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-cash	\N	\N
b61dbc54-a326-4987-9c54-82e618fc3b76	CREATE	2026-08-04 08:15:35.113893	POST /api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/request-cash	\N	Invoice	162.158.108.108	POST	/api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/request-cash	\N	\N
2b5c2001-4bbb-408c-a91e-d5c13aa44e30	RESOLVE	2026-08-04 08:17:43.182524	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
10b5f80f-ebaa-4551-ac81-f4c8276be598	CREATE	2026-08-06 13:25:18.268829	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	172.68.211.104	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
9a7f658e-7624-4126-a6d7-e9d11d4f489f	CREATE	2026-08-06 13:27:26.063447	POST /api/invoices/generate	\N	Invoice	172.71.81.83	POST	/api/invoices/generate	\N	\N
bbf6b8e0-4b80-4a87-a08c-419d85a0c47b	CREATE	2026-08-06 13:27:52.842861	POST /api/invoices/generate	\N	Invoice	162.158.162.76	POST	/api/invoices/generate	\N	\N
86f665ab-7c9f-4e44-8935-2045d803fbba	CREATE	2026-08-06 13:32:00.334076	POST /api/rooms/b5000000-0000-0000-0000-000000000009/meter-readings	\N	Room	162.158.179.49	POST	/api/rooms/b5000000-0000-0000-0000-000000000009/meter-readings	\N	\N
5306f2e8-5650-43fe-b657-31f1fe957b42	CREATE	2026-08-06 13:33:34.919367	POST /api/invoices/generate	\N	Invoice	162.159.98.51	POST	/api/invoices/generate	\N	\N
3956033a-ca7f-4969-a383-322f9e5358f3	CREATE	2026-08-14 04:12:27.862373	POST /api/rooms/b5000000-0000-0000-0000-000000000003/meter-readings	\N	Room	172.70.93.110	POST	/api/rooms/b5000000-0000-0000-0000-000000000003/meter-readings	\N	\N
851d9f99-47bf-4da2-8c85-5ee76deef0d8	CREATE	2026-08-19 06:51:06.866401	POST /api/rooms/b5000000-0000-0000-0000-000000000021/meter-readings	\N	Room	172.71.124.28	POST	/api/rooms/b5000000-0000-0000-0000-000000000021/meter-readings	\N	\N
eba1252f-a741-4124-ab96-f9788587071c	CREATE	2026-08-19 06:51:26.162505	POST /api/rooms/b5000000-0000-0000-0000-000000000002/meter-readings	\N	Room	172.71.81.99	POST	/api/rooms/b5000000-0000-0000-0000-000000000002/meter-readings	\N	\N
0ef5f413-0115-47a5-9aad-dd868d0865b1	CREATE	2026-08-19 06:52:18.455324	POST /api/invoices/generate	\N	Invoice	172.70.143.214	POST	/api/invoices/generate	\N	\N
278530df-77a9-4993-b938-3fd20fb10a7c	CREATE	2026-08-19 06:57:44.8122	POST /api/invoices/630256f4-8c34-4f40-b621-917edd5dd826/request-cash	\N	Invoice	162.158.108.39	POST	/api/invoices/630256f4-8c34-4f40-b621-917edd5dd826/request-cash	\N	\N
5e9c02fe-49e9-4ead-8d8c-e2fcbcd1f825	PAYMENT	2026-08-19 06:58:04.655508	POST /api/invoices/630256f4-8c34-4f40-b621-917edd5dd826/pay-cash	\N	Invoice	162.158.108.39	POST	/api/invoices/630256f4-8c34-4f40-b621-917edd5dd826/pay-cash	\N	\N
be26d911-6fa6-4c92-a795-4329563e882e	RESOLVE	2026-08-19 07:00:07.31206	POST /api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	MaintenanceRequest	172.70.93.110	POST	/api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	\N
c2c601c8-5d74-4ed5-95e8-51ae6fc56db9	RESOLVE	2026-08-19 07:00:10.2071	POST /api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	MaintenanceRequest	172.70.93.110	POST	/api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	\N
c341db81-b4be-4a94-86bd-ddfc97e9589a	RESOLVE	2026-08-19 07:00:10.412273	POST /api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	MaintenanceRequest	172.70.189.116	POST	/api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	\N
3d3577b5-2fc3-4979-a228-967dd643a755	RESOLVE	2026-08-04 08:15:42.184199	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.68.164.62	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
07fd745c-e9ff-42ac-9ec3-6b50f7f415a0	RESOLVE	2026-08-04 08:16:12.506755	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
5334e081-afee-4d0d-99a9-026fb08d7ec4	RESOLVE	2026-08-04 08:18:43.576837	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.68.164.62	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
4ce3311c-2cf8-48a5-872f-6fff61b7b4be	RESOLVE	2026-08-04 08:18:43.86435	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.19	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
e4bfa045-d7ab-4712-abe4-4b1a2f5e9a4e	RESOLVE	2026-08-04 08:18:55.232766	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.108.109	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
198709ab-4aee-4c6f-97ec-40dcd14fc6bb	RESOLVE	2026-08-04 08:18:56.34705	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.152.78	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
ec88223a-0e20-468e-8e61-153482866f23	RESOLVE	2026-08-04 08:18:58.42444	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
11a212af-be6f-4ce1-8bc2-cad6b5d0954e	RESOLVE	2026-08-04 08:19:02.503735	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.152.78	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
4f0de135-9fe2-4552-94d0-de712c5dd25c	RESOLVE	2026-08-04 08:19:13.914965	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
e8280aa9-5802-4b85-92d7-0a8e4792944e	RESOLVE	2026-08-04 08:19:14.019042	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.70.208.106	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
ffad697d-1797-4418-bcac-70ae70973dd5	RESOLVE	2026-08-04 08:19:17.013925	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.70.208.106	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
660c46e6-923b-4653-99b0-f0cfe389a102	RESOLVE	2026-08-04 08:19:33.104083	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.70.208.106	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
d6f65a83-51e6-49b1-8792-818fd483cd10	RESOLVE	2026-08-04 08:19:44.087843	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
97c67a43-978a-4f89-87e8-4c852692efc9	RESOLVE	2026-08-04 08:19:44.237551	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
6b0f4e9a-de1f-4a30-b680-a476b17d1879	RESOLVE	2026-08-04 08:20:14.237258	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
036bb297-ca2c-4e12-b38e-b1f98abfab03	RESOLVE	2026-08-04 08:20:14.421631	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.68.164.62	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
b2913267-ff69-4124-831d-92790cf2aeac	RESOLVE	2026-08-04 08:20:44.479564	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
24858a0c-e2e3-412d-84e0-d04c29b2bf7a	RESOLVE	2026-08-04 08:20:44.596893	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.68.164.62	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
b90a315b-b8fe-48a2-95fb-3edced3d9fe9	RESOLVE	2026-08-04 08:21:14.643537	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
057573c7-95cb-463d-ac31-27d62c7ecef5	RESOLVE	2026-08-04 08:21:14.751957	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
d5fd3058-5c4f-45f5-bab2-bb7649b0e565	RESOLVE	2026-08-04 08:21:44.832531	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.68.164.62	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
b91fdbe0-2a65-40fb-a381-e01d59fcdf10	RESOLVE	2026-08-04 08:21:44.986034	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
6cb201aa-0608-4f52-89aa-ce7a23859eae	PAYMENT	2026-08-04 08:21:58.327004	POST /api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	Invoice	172.68.164.62	POST	/api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	\N
19464328-d2f7-4937-8cff-21242f3c484e	PAYMENT	2026-08-04 08:22:00.163316	POST /api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	Invoice	172.68.164.62	POST	/api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	\N
9689b783-e9f8-4311-9ab0-308534958b8f	CREATE	2026-08-04 08:22:08.940522	POST /api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/request-cash	\N	Invoice	104.23.175.147	POST	/api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/request-cash	\N	\N
e4d18599-62af-4fff-a0b6-0c8eaf4faa25	CREATE	2026-08-04 08:22:10.305879	POST /api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/request-cash	\N	Invoice	162.158.108.108	POST	/api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/request-cash	\N	\N
6c953a6c-f8bc-4d08-97c7-173b48545daa	CREATE	2026-08-04 08:22:12.39559	POST /api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/request-cash	\N	Invoice	162.158.108.108	POST	/api/invoices/cc0cd89c-886d-476e-a9f2-6a4a2649bb01/request-cash	\N	\N
fdde3b2f-18a0-4ca3-80f8-e3711d75922c	RESOLVE	2026-08-04 08:22:15.005229	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
e74a9ed1-2ac9-4b02-93ba-fa5a9156871d	RESOLVE	2026-08-04 08:22:15.203374	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
dee80f9e-b52d-4195-a909-a67155d7d980	PAYMENT	2026-08-04 08:22:19.381215	POST /api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	Invoice	162.158.179.49	POST	/api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	\N
36bafb75-37e1-4c97-9173-aa6dfd07bb95	PAYMENT	2026-08-04 08:22:19.76738	POST /api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	Invoice	104.23.175.146	POST	/api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	\N
9b39426d-ecd3-472c-863d-5191bba641e5	RESOLVE	2026-08-04 08:22:37.167025	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
8981559b-78d4-4ba8-bc39-23ca83c4eb02	RESOLVE	2026-08-04 08:22:45.181476	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
53c81be0-fc32-4ded-85a1-a601f78256bd	RESOLVE	2026-08-04 08:22:45.40584	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
ac7f64e4-1595-403c-ad48-92531b2380f2	CREATE	2026-08-05 06:01:41.110647	POST /api/invoices/generate	\N	Invoice	162.159.98.50	POST	/api/invoices/generate	\N	\N
2af818c4-21b4-4516-8a4e-4ba95781ebbf	CREATE	2026-08-04 08:22:49.575111	POST /api/invoices/7c135337-f51e-49fa-8731-3768446542f0/request-cash	\N	Invoice	162.158.179.49	POST	/api/invoices/7c135337-f51e-49fa-8731-3768446542f0/request-cash	\N	\N
deeeaea8-eac9-4c77-a2ec-fcff56438240	RESOLVE	2026-08-04 08:23:45.729702	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.70.208.107	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
4ee4a993-924a-4e3c-a576-8fc74bc36808	RESOLVE	2026-08-04 08:24:37.7098	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.70.189.48	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
8564f13b-7002-4284-a2ae-31c842ff9002	RESOLVE	2026-08-04 08:25:17.120175	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
de8829fa-a3f8-42d4-bbb0-5b74e086f9d2	RESOLVE	2026-08-04 08:25:47.21544	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
3e56882d-e5c8-4cc5-8681-e1597eb8fb28	RESOLVE	2026-08-04 08:25:47.441848	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.193.197	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
b46081a9-74db-4cb0-b64e-63200dfd7cdd	RESOLVE	2026-08-04 08:26:08.003344	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
a823e3f3-f43f-4f53-83ff-1b98372ea138	CREATE	2026-08-04 08:27:47.517777	POST /api/users	\N	User	172.69.165.33	POST	/api/users	\N	\N
b8706d8e-53c8-4e5c-a668-4f272205f2af	RESOLVE	2026-08-04 08:27:48.544638	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
3d315657-9c07-42d4-b55d-4a64d92f0f8c	CREATE	2026-08-06 13:25:32.984136	POST /api/invoices/generate	\N	Invoice	162.158.193.197	POST	/api/invoices/generate	\N	\N
4aebfd50-a651-4c8d-8c48-0feb01f749d7	CREATE	2026-08-06 13:30:39.405091	POST /api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings/hunonic-sync	\N	Room	172.71.218.225	POST	/api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings/hunonic-sync	\N	\N
58b820cf-f349-419a-abe1-917978b694f6	CREATE	2026-08-06 13:32:08.096697	POST /api/rooms/b5000000-0000-0000-0000-000000000005/meter-readings	\N	Room	172.71.218.224	POST	/api/rooms/b5000000-0000-0000-0000-000000000005/meter-readings	\N	\N
37eaa5a9-4207-4be2-87c8-d2c3b678621c	CREATE	2026-08-06 13:35:25.492422	POST /api/invoices/generate	\N	Invoice	172.71.218.224	POST	/api/invoices/generate	\N	\N
0ba37d87-be1c-4b3e-ac3f-00811c1fa6a7	CREATE	2026-08-14 04:12:31.37533	POST /api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	Room	104.22.176.10	POST	/api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	\N
df29be79-eb5a-46aa-bedd-da01c65dbb04	CREATE	2026-08-14 04:12:35.666378	POST /api/rooms/b5000000-0000-0000-0000-000000000010/meter-readings	\N	Room	162.158.108.38	POST	/api/rooms/b5000000-0000-0000-0000-000000000010/meter-readings	\N	\N
980f2cda-2877-46b5-852e-ed64e26a0584	CREATE	2026-08-14 04:12:47.366109	POST /api/rooms/b5000000-0000-0000-0000-000000000014/meter-readings	\N	Room	172.71.124.28	POST	/api/rooms/b5000000-0000-0000-0000-000000000014/meter-readings	\N	\N
b2fa5055-64c6-4350-a134-e74c409f3d0b	CREATE	2026-08-14 04:12:48.66178	POST /api/rooms/b5000000-0000-0000-0000-000000000022/meter-readings	\N	Room	172.71.152.77	POST	/api/rooms/b5000000-0000-0000-0000-000000000022/meter-readings	\N	\N
7d24ed99-f276-42e2-84c2-7ea90ae45bc7	CREATE	2026-08-14 04:12:52.622316	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	172.71.81.100	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
c064c01d-f2b6-4550-9ed9-13f6588c728b	CREATE	2026-08-19 06:51:08.454785	POST /api/rooms/b5000000-0000-0000-0000-000000000017/meter-readings	\N	Room	104.23.175.246	POST	/api/rooms/b5000000-0000-0000-0000-000000000017/meter-readings	\N	\N
fa03142e-fda1-40de-a3a1-3fd0426b797a	CREATE	2026-08-19 06:51:23.562718	POST /api/rooms/b5000000-0000-0000-0000-000000000014/meter-readings	\N	Room	104.23.175.247	POST	/api/rooms/b5000000-0000-0000-0000-000000000014/meter-readings	\N	\N
375cb72a-4d0e-4ff5-bc17-6ba2f0cfd0b2	RESOLVE	2026-08-19 07:00:08.496322	POST /api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	MaintenanceRequest	172.70.189.116	POST	/api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	\N
0efc37b3-4378-4f99-b2d0-0fcca664c9a3	CREATE	2026-08-19 07:09:27.961683	POST /api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/completion-images	\N	MaintenanceRequest	162.158.163.125	POST	/api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/completion-images	\N	\N
03e9a5b0-0068-46be-88d5-af4af263ff57	RESOLVE	2026-08-19 07:09:48.060912	POST /api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/resolve	\N	MaintenanceRequest	172.68.164.171	POST	/api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/resolve	\N	\N
a7b437aa-f0ec-4752-8fa8-608c59b9ca49	PAYMENT	2026-08-04 08:22:56.974194	POST /api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	Invoice	162.158.179.50	POST	/api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	\N
0b3861ea-39fd-47d5-bbf9-3f72370a51a9	CREATE	2026-08-04 08:23:28.776388	POST /api/notifications/236aa2a3-1aac-4b17-a6d9-155d795ac7b1/read	\N	Notification	104.23.175.146	POST	/api/notifications/236aa2a3-1aac-4b17-a6d9-155d795ac7b1/read	\N	\N
acfba7ab-9824-4347-9387-8e8aab1af921	RESOLVE	2026-08-04 08:24:46.903547	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.68.164.62	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
49c8d5a4-1d12-4414-a958-d7a355c854e1	RESOLVE	2026-08-04 08:26:17.903866	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
797699ec-f94c-4d55-a2ab-d53c429e21c5	RESOLVE	2026-08-04 08:27:18.402512	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
5b43defc-f032-4b50-8341-3d916b2de252	CREATE	2026-08-04 08:27:28.506529	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
23998116-82c6-4a79-9209-1614d288ca7e	CREATE	2026-08-04 08:27:50.26405	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
879bb5ed-941c-40a3-9e5b-49257977f813	RESOLVE	2026-08-04 08:28:18.374842	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
936aa02a-4246-41d8-8ecf-a79db9ff0c3d	RESOLVE	2026-08-04 08:28:18.693018	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
85a3aeec-b107-4797-9817-9895d2e28b9a	CREATE	2026-08-04 08:28:22.199669	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
1c766510-588b-464d-9e73-b52d4dde279c	RESOLVE	2026-08-04 08:28:48.833102	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
b741e3ad-47eb-4327-af62-9a38be81837f	RESOLVE	2026-08-04 08:29:18.829711	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.215.16	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
8cd24e3d-9186-4c78-b7a8-bc02b637135e	RESOLVE	2026-08-04 08:29:19.102985	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
dfaacfa2-fd52-49ec-adfd-ff65596066c5	RESOLVE	2026-08-04 08:29:49.279683	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.107.34	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
bf6f207a-2629-4c13-a632-22d34a10ad78	CREATE	2026-08-04 08:30:10.47826	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
28a96380-3ac8-4d4d-b5b7-b4bf4a3eab4c	RESOLVE	2026-08-04 08:30:19.428865	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.18	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
25465022-a751-4f8d-8276-4e1f371cb8d4	RESOLVE	2026-08-04 08:30:49.278326	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.70.208.107	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
46d0c924-48c6-42b2-b181-90523eaf6506	RESOLVE	2026-08-04 08:31:19.453054	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
5ada2da8-3213-4cfe-b45d-f8d2dcb3a75e	CREATE	2026-08-06 13:27:39.163718	POST /api/invoices/generate	\N	Invoice	172.71.124.13	POST	/api/invoices/generate	\N	\N
edfec86e-69d9-4965-932c-35ab59d1c8dd	CREATE	2026-08-06 13:30:30.195452	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	172.71.152.77	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
ab2e91e2-342d-4bd6-b3e7-14bbe59afb92	CREATE	2026-08-14 04:12:32.96192	POST /api/rooms/b5000000-0000-0000-0000-000000000021/meter-readings	\N	Room	172.71.124.13	POST	/api/rooms/b5000000-0000-0000-0000-000000000021/meter-readings	\N	\N
c1481be7-68f1-436e-80a4-a9bf3b5360e1	ASSIGN	2026-08-14 04:29:42.362513	POST /api/maintenance/c05e9333-2746-4b7f-9a01-8182f91ffa93/assign	\N	MaintenanceRequest	162.158.171.2	POST	/api/maintenance/c05e9333-2746-4b7f-9a01-8182f91ffa93/assign	\N	\N
f895f42c-7482-4c05-bd5c-e54dbeb0c8c5	CREATE	2026-08-19 06:51:13.755246	POST /api/rooms/e3d6477b-41ee-4b21-af42-6a9f042e6d08/meter-readings	\N	Room	104.23.175.246	POST	/api/rooms/e3d6477b-41ee-4b21-af42-6a9f042e6d08/meter-readings	\N	\N
aa472cb4-4111-4f3e-9dee-86c8fb630400	RESOLVE	2026-08-19 07:00:05.358853	POST /api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	MaintenanceRequest	172.70.189.116	POST	/api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	\N
dcb1bb9f-8a83-43be-98b5-399642f1855f	CREATE	2026-08-19 07:09:37.616876	POST /api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/completion-images	\N	MaintenanceRequest	162.158.163.125	POST	/api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/completion-images	\N	\N
4a08b174-0afd-4389-b49b-c8e767eedcbd	RESOLVE	2026-08-19 07:09:45.287477	POST /api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/resolve	\N	MaintenanceRequest	172.70.208.106	POST	/api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/resolve	\N	\N
b0a34940-f18b-445d-a609-ca8e30e8a704	RESOLVE	2026-08-19 07:09:47.456018	POST /api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/resolve	\N	MaintenanceRequest	172.70.208.106	POST	/api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/resolve	\N	\N
df699fb4-5ae1-4bfa-8334-1cffd5e2f389	RESOLVE	2026-08-19 07:09:47.845143	POST /api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/resolve	\N	MaintenanceRequest	172.70.208.106	POST	/api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/resolve	\N	\N
ba10156e-f782-41f6-941c-0e53dd923e31	PAYMENT	2026-08-04 08:22:57.602522	POST /api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	Invoice	104.23.175.146	POST	/api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	\N
cce14404-fb6f-4601-a579-4b8fafb0523f	RESOLVE	2026-08-04 08:23:37.413194	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.69.165.32	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
2046d48e-7db5-4b1b-99bf-9903c26c4aaf	RESOLVE	2026-08-04 08:24:16.405357	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
e9e0bb8e-ea65-4b60-b8ef-37674abfe3e2	CREATE	2026-08-06 13:30:51.354286	POST /api/invoices/generate	\N	Invoice	172.71.218.224	POST	/api/invoices/generate	\N	\N
815420d2-1c0b-4d3c-93fd-2f728dd021ad	CREATE	2026-08-06 13:54:49.392615	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	162.159.98.50	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
52b7229f-7caf-43c4-9d2b-f1a0c2670825	CREATE	2026-08-06 13:54:51.358252	POST /api/invoices/generate	\N	Invoice	104.23.175.247	POST	/api/invoices/generate	\N	\N
b80372f2-94de-47be-aac0-605e46e4d688	CREATE	2026-08-14 04:12:41.061468	POST /api/rooms/b5000000-0000-0000-0000-000000000025/meter-readings	\N	Room	172.71.81.100	POST	/api/rooms/b5000000-0000-0000-0000-000000000025/meter-readings	\N	\N
df5beaf5-c1c5-4c69-9ff9-4f37e5ccc149	CREATE	2026-08-14 04:12:43.561982	POST /api/rooms/b5000000-0000-0000-0000-000000000018/meter-readings	\N	Room	172.71.81.100	POST	/api/rooms/b5000000-0000-0000-0000-000000000018/meter-readings	\N	\N
6fa9980f-0663-47b3-81c8-0087fd56b492	CREATE	2026-08-14 04:12:44.87	POST /api/rooms/b5000000-0000-0000-0000-000000000024/meter-readings	\N	Room	172.68.242.120	POST	/api/rooms/b5000000-0000-0000-0000-000000000024/meter-readings	\N	\N
0afd7db6-5046-4719-b301-8976fb3d07be	CREATE	2026-08-14 04:12:46.261843	POST /api/rooms/b5000000-0000-0000-0000-000000000016/meter-readings	\N	Room	172.71.81.100	POST	/api/rooms/b5000000-0000-0000-0000-000000000016/meter-readings	\N	\N
81e3cc1d-6d61-461a-9fc4-c91068cc5b2b	CREATE	2026-08-19 06:51:16.869191	POST /api/rooms/b5000000-0000-0000-0000-000000000025/meter-readings	\N	Room	172.70.143.214	POST	/api/rooms/b5000000-0000-0000-0000-000000000025/meter-readings	\N	\N
51b24670-454d-429e-8b7b-6797a7013b2d	CREATE	2026-08-19 06:57:21.58473	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	104.22.176.21	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
400ab47b-1560-4464-ac88-6f760cce1f8e	RESOLVE	2026-08-04 08:23:07.299986	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.70.93.65	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
21eb1d69-a43a-4a82-9273-307821e81235	RESOLVE	2026-08-04 08:23:15.554272	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
f6746a6b-b56b-4f9f-bedc-c47855bbb5d6	RESOLVE	2026-08-04 08:26:17.604154	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
c8f4df72-34f6-4f64-9bcc-9bd8a958dfaf	CREATE	2026-08-06 13:31:10.859351	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	172.68.211.105	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
8421ca2e-783e-4d57-bb61-d4f0f1d11e05	CREATE	2026-08-14 04:12:50.362625	POST /api/rooms/b5000000-0000-0000-0000-000000000002/meter-readings	\N	Room	104.22.176.10	POST	/api/rooms/b5000000-0000-0000-0000-000000000002/meter-readings	\N	\N
4290efe6-0d60-4eb8-ad63-d71d7e00d0d9	CREATE	2026-08-14 04:17:16.566751	POST /api/invoices/generate	\N	Invoice	172.68.242.121	POST	/api/invoices/generate	\N	\N
3a220660-4bf0-4ba0-bce0-0952c6291cd4	CREATE	2026-08-19 06:51:18.354878	POST /api/rooms/b5000000-0000-0000-0000-000000000013/meter-readings	\N	Room	162.158.171.2	POST	/api/rooms/b5000000-0000-0000-0000-000000000013/meter-readings	\N	\N
894aa8fc-cb9a-401a-b48f-3cf399e738e6	RESOLVE	2026-08-19 07:00:09.285483	POST /api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	MaintenanceRequest	104.22.176.10	POST	/api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	\N
9212ec20-af6d-444f-86b3-691290472cd8	RESOLVE	2026-08-04 08:23:15.34191	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
c32d090a-5fe2-4cb4-9699-deddecba8cae	CREATE	2026-08-04 08:23:29.307157	POST /api/notifications/860c188c-98d8-45ed-9410-4ffdbff549cc/read	\N	Notification	162.158.193.197	POST	/api/notifications/860c188c-98d8-45ed-9410-4ffdbff549cc/read	\N	\N
e038e209-a82a-4007-a97c-b965053f14b7	RESOLVE	2026-08-04 08:23:45.574357	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.193.196	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
757868a0-5b2c-4316-b60e-46a28dfbe023	RESOLVE	2026-08-04 08:24:07.507115	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.69.176.62	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
a6022536-b346-45fc-8b14-2dfe4f430a84	RESOLVE	2026-08-04 08:24:16.509242	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
14da5c16-257b-4a93-a61f-d547defbcf33	RESOLVE	2026-08-04 08:24:46.770651	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
e2b0eb02-00e8-4c17-b074-047d169f774d	RESOLVE	2026-08-04 08:25:07.804079	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.70.189.48	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
55ad3dae-232f-4b4f-8c90-036232a9c20c	RESOLVE	2026-08-04 08:27:18.068289	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
ec0b7a6a-20a6-4be4-b5fa-c751655ea730	CREATE	2026-08-04 08:27:38.320341	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.71.215.16	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
d09dfebf-1774-422e-ba72-4b5ae4453b3d	CREATE	2026-08-06 13:32:27.799566	POST /api/rooms/b5000000-0000-0000-0000-000000000007/meter-readings	\N	Room	104.23.175.246	POST	/api/rooms/b5000000-0000-0000-0000-000000000007/meter-readings	\N	\N
d4973f87-37bb-4a66-a1c6-2157fc865d2d	CREATE	2026-08-14 04:26:33.610133	POST /api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	Room	172.70.208.107	POST	/api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	\N
1a25aab9-84e4-473e-b14e-f10f5fa84630	RESOLVE	2026-08-19 07:00:09.835953	POST /api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	MaintenanceRequest	172.70.189.116	POST	/api/maintenance/849c05ad-e3b6-4c8b-9f10-3db67d42a9e6/resolve	\N	\N
f4f821f8-a0ab-4144-9da0-a099ed4288d3	RESOLVE	2026-08-19 07:09:18.312654	POST /api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/resolve	\N	MaintenanceRequest	162.158.163.125	POST	/api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/resolve	\N	\N
2f15fba5-fbb2-495b-9c04-bb7cd9b65bc2	RESOLVE	2026-08-19 07:16:49.79485	POST /api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/resolve	\N	MaintenanceRequest	162.158.163.125	POST	/api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/resolve	\N	\N
d4e10e52-42a9-4550-93ab-2b3ec846b8be	RESOLVE	2026-08-04 08:25:17.024995	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.193.197	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
7a1a4c80-7b4e-466b-ac3f-adc0bb4028d2	RESOLVE	2026-08-04 08:25:37.909833	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.152.78	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
9f4e5180-65eb-453c-94f2-31242432d153	DELETE	2026-08-04 08:26:01.80347	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/b3ada61c-0802-4ca8-b2bc-7f4369493481	\N	Property	172.71.82.19	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/b3ada61c-0802-4ca8-b2bc-7f4369493481	\N	\N
e3e01ac0-9aa4-43f7-8d4e-cb37e9ff2a13	RESOLVE	2026-08-04 08:28:48.592933	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
f9c8f64a-c230-4e49-a1c5-fe63a1e20120	RESOLVE	2026-08-04 08:29:48.991128	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.193.196	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
c16829f0-cec1-4613-a0e9-b16ed034c37d	RESOLVE	2026-08-04 08:30:49.802725	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
17bd898c-94e2-4b3a-8708-60a1dc0330d5	RESOLVE	2026-08-04 08:31:19.966057	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
9076997f-ac48-4980-b0d5-0b6b785063de	RESOLVE	2026-08-04 08:32:21.504872	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
e38ca9f2-79fc-4a39-b66a-01ce43847d46	RESOLVE	2026-08-04 08:33:52.053664	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
5053bf84-dd2b-427c-a3c2-67049b6b7bde	CREATE	2026-08-06 13:34:47.304916	POST /api/invoices/generate	\N	Invoice	162.159.98.50	POST	/api/invoices/generate	\N	\N
27893b44-28bb-4598-a6f1-06bcbb5d3141	CREATE	2026-08-14 04:28:40.361603	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.22.176.10	POST	/api/maintenance/with-images	\N	\N
71dd447e-4d40-49bd-9f45-e2f6630f9542	CREATE	2026-08-14 04:30:12.487447	POST /api/maintenance/c05e9333-2746-4b7f-9a01-8182f91ffa93/confirm-slot	\N	MaintenanceRequest	104.22.176.10	POST	/api/maintenance/c05e9333-2746-4b7f-9a01-8182f91ffa93/confirm-slot	\N	\N
af442856-247e-457b-a7a1-6a29dc7b8ee8	CREATE	2026-08-19 07:07:38.454918	POST /api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/materials	\N	MaintenanceRequest	104.22.176.10	POST	/api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/materials	\N	\N
c185275a-b1e6-4b2f-8a88-d404c925833c	CREATE	2026-08-19 07:07:57.755559	POST /api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/completion-images	\N	MaintenanceRequest	162.158.108.39	POST	/api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/completion-images	\N	\N
24e59574-e9df-4b75-9f6e-5bae88648640	CREATE	2026-08-04 08:25:44.107214	POST /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms	\N	Property	172.71.152.78	POST	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms	\N	\N
dccb3e12-4eb7-4516-ab85-9f7136fba910	RESOLVE	2026-08-04 08:26:47.904368	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
a01e0511-1253-4bf2-9ff3-c010a60dcc04	RESOLVE	2026-08-04 08:26:48.202596	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
cc812e1a-ef13-4dad-ae96-6cbffdd92048	CREATE	2026-08-04 08:27:41.423238	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
3f076205-065d-4ca9-803f-2fd5a76b4fd2	RESOLVE	2026-08-04 08:27:48.225735	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
a9dc2ef9-fc3a-48d7-a9c8-992a51d4e175	CREATE	2026-08-04 08:28:04.697244	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.147	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
80d1e3b9-fc91-45dc-97e7-a5ff2ea4a397	RESOLVE	2026-08-04 08:30:19.129961	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
def9d813-b7ad-4339-8b9c-dd5c9127f12c	RESOLVE	2026-08-04 08:31:49.64398	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
e9726564-ac65-4f79-801d-09ac4004f93f	RESOLVE	2026-08-04 08:31:50.095122	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
a23dde75-7605-4860-a2b7-3dc29f355779	RESOLVE	2026-08-04 08:32:19.813232	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
8a207bf2-4579-45ac-8bd9-c376d83d02d7	RESOLVE	2026-08-04 08:32:51.571618	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.18	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
5f512f62-a337-49e6-ae87-d38fdd90be92	RESOLVE	2026-08-04 08:32:51.665948	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.18	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
e7007fae-4af1-4458-a06d-ba8376499211	RESOLVE	2026-08-04 08:33:21.835278	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
2a1bff8e-8d71-4f0b-8614-65efd03453e8	RESOLVE	2026-08-04 08:33:21.838039	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
f18f5c88-0bd3-450a-a505-db2daecb8ffb	RESOLVE	2026-08-04 08:33:51.97276	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
433aabda-9999-4294-8e12-aa757a8e55cf	RESOLVE	2026-08-04 08:34:22.138942	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
43f87545-de81-45e9-8895-a99208209909	RESOLVE	2026-08-04 08:34:22.290922	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.179.50	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
27d11a08-60b8-45a0-b22d-f2272eb5eb9b	RESOLVE	2026-08-04 08:34:52.32989	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
54450439-8120-43de-82e4-0164ac8573ed	RESOLVE	2026-08-04 08:34:53.507106	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
fe999c62-f506-49b8-9332-730231fa0a49	RESOLVE	2026-08-04 08:35:22.505343	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.68.164.62	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
a82e4e40-f522-419d-8329-b66366625cc6	RESOLVE	2026-08-04 08:35:23.665256	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.68.164.62	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
5aaa53dd-6df9-4204-9aa3-6ce8850f24f0	CREATE	2026-08-04 08:35:42.814131	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.68.164.62	POST	/api/maintenance/with-images	\N	\N
a9051b0f-fb01-4442-bfd8-5245a131aae6	CREATE	2026-08-04 08:35:46.684823	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.22.176.10	POST	/api/maintenance/with-images	\N	\N
3e4cca11-bdbc-4393-8bfa-fc40533535f2	RESOLVE	2026-08-04 08:35:52.815359	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
e5e8f79d-8197-4c3d-a9d6-76a7c7dfe6af	CREATE	2026-08-04 08:35:53.047983	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.22.176.10	POST	/api/maintenance/with-images	\N	\N
e8d220b0-cd7f-4221-89bc-466222f340a5	RESOLVE	2026-08-04 08:35:53.816482	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.68.164.62	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
a43a13ed-4e8c-45a4-9cbb-521e958da1b8	CREATE	2026-08-04 08:35:59.888153	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.124.28	POST	/api/maintenance/with-images	\N	\N
656405c0-65d1-4edd-945b-535634a1a72b	CREATE	2026-08-04 08:36:12.000205	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.22.176.10	POST	/api/maintenance/with-images	\N	\N
ab975f43-16df-43c1-8184-d42409ac40cb	RESOLVE	2026-08-04 08:36:23.069015	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	172.70.93.64	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
82256030-f0b5-454c-8c56-22022bc129b0	RESOLVE	2026-08-04 08:36:23.95505	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
9b0200a0-0af2-414e-ab4c-bbacd79d6900	CREATE	2026-08-04 08:36:32.003983	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.22.176.10	POST	/api/maintenance/with-images	\N	\N
77e8332a-09a5-441e-a5ea-871b30aa7d79	RESOLVE	2026-08-04 08:36:53.214766	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
fb5d997b-5984-4d36-b2d3-d8c1ac28c3a3	RESOLVE	2026-08-04 08:36:54.108696	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
ac8c111e-199d-48fa-a410-a6c1983e3927	CREATE	2026-08-04 08:37:04.822377	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.22.176.10	POST	/api/maintenance/with-images	\N	\N
3adc41b3-0e6d-4187-9f73-8aa2befc3138	RESOLVE	2026-08-04 08:37:23.380542	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.114.170	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
235fb644-c0fe-492f-930a-e92ab5f814d2	RESOLVE	2026-08-04 08:37:25.215895	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
a61f9280-4050-4277-b611-813969c76611	RESOLVE	2026-08-04 08:37:53.537864	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.107.33	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
f0e4cab3-5649-4851-8f11-9548b4bf456b	RESOLVE	2026-08-04 08:37:55.378703	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.19	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
83dbc92c-6422-4318-8803-66944895eedb	RESOLVE	2026-08-04 08:38:23.685939	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
cc9c68d8-e550-4a2f-8985-8f0f801ff4e2	RESOLVE	2026-08-04 08:38:25.533508	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.193.197	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
b628db4d-c0ca-4249-9787-3e88a2fd9b5c	RESOLVE	2026-08-04 08:38:53.852675	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
22bc7ee7-b85e-4c7f-9785-55707cb5b77a	RESOLVE	2026-08-04 08:38:55.697081	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
d97f1ab9-4dc6-463b-979c-42e0d696c50d	RESOLVE	2026-08-04 08:39:24.010809	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
83e8116d-9827-47dd-9a05-b0e036583811	RESOLVE	2026-08-04 08:39:25.837828	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
3013a7fc-25ac-49f6-85a9-b36d269fbaa5	RESOLVE	2026-08-04 08:39:54.245754	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	162.158.114.171	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
3e8a9642-123c-4ce3-aff6-8778140294bc	RESOLVE	2026-08-04 08:39:56.002944	POST /api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/e3a2fec5-a9ad-409f-944d-ef61236f54cc/resolve	\N	\N
2559b0e7-6be0-4110-a730-1aa0df2d462f	CREATE	2026-08-04 08:40:23.90646	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.70.208.106	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
73894afd-6583-4a68-8938-29b35e53de0a	CREATE	2026-08-04 08:40:24.205053	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
9ac3868d-3a74-4aed-a1cc-d4c8558b4a3e	CREATE	2026-08-04 08:42:09.00923	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
3066678a-28ad-4108-82a1-baace39f402b	CREATE	2026-08-04 08:50:27.010803	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.69.176.62	POST	/api/maintenance/with-images	\N	\N
09573f20-2bfa-4f86-9cd4-5bfe019d5c76	CREATE	2026-08-04 08:50:57.204319	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.23.175.146	POST	/api/maintenance/with-images	\N	\N
e458f19d-6716-4b03-911d-0ac802cc872b	ASSIGN	2026-08-04 08:51:51.502777	POST /api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/assign	\N	MaintenanceRequest	162.158.108.108	POST	/api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/assign	\N	\N
fb3b36c9-2465-427f-beb6-7daf34323c4a	ASSIGN	2026-08-04 08:52:03.912042	POST /api/maintenance/c5e0255e-0794-408f-9677-5db981f2d32f/assign	\N	MaintenanceRequest	162.158.108.108	POST	/api/maintenance/c5e0255e-0794-408f-9677-5db981f2d32f/assign	\N	\N
1812a439-df79-49c3-9bd2-622abd2a7d9d	CREATE	2026-08-04 08:56:57.105023	POST /api/maintenance/cbf3facb-8486-47b7-b951-cea864340b19/cancel	\N	MaintenanceRequest	172.71.124.29	POST	/api/maintenance/cbf3facb-8486-47b7-b951-cea864340b19/cancel	\N	\N
d18f061d-d810-4a3f-832e-60417a6861b6	CREATE	2026-08-04 08:57:07.005098	POST /api/maintenance/de427a93-5a73-4187-b30c-6b18f1d8073e/cancel	\N	MaintenanceRequest	104.22.176.10	POST	/api/maintenance/de427a93-5a73-4187-b30c-6b18f1d8073e/cancel	\N	\N
504ae13d-f33f-47f4-987d-82f4032ab78c	CREATE	2026-08-04 08:57:12.535327	POST /api/maintenance/9b31d59a-e23c-4ea5-9b4c-957406f94725/cancel	\N	MaintenanceRequest	104.22.176.10	POST	/api/maintenance/9b31d59a-e23c-4ea5-9b4c-957406f94725/cancel	\N	\N
94d47131-4091-4b9b-a99d-e7a6bf174906	CREATE	2026-08-04 08:57:17.302595	POST /api/maintenance/c2738e46-85d0-45f2-b0d6-ae16f04d1cad/cancel	\N	MaintenanceRequest	104.22.176.10	POST	/api/maintenance/c2738e46-85d0-45f2-b0d6-ae16f04d1cad/cancel	\N	\N
f97d82a5-9f6e-4eb5-99e2-1bec394fde03	RESOLVE	2026-08-04 08:57:47.786924	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/resolve	\N	MaintenanceRequest	162.158.88.170	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/resolve	\N	\N
8d7c90b5-0179-49f3-8180-15efa6642c1f	RESOLVE	2026-08-04 08:57:48.881805	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/resolve	\N	MaintenanceRequest	162.158.88.170	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/resolve	\N	\N
2b8509d4-3aaf-4883-a8b0-9fd8de603f0e	RESOLVE	2026-08-04 08:57:51.015931	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/resolve	\N	MaintenanceRequest	172.71.152.77	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/resolve	\N	\N
f2cd7011-29a8-4789-bb8e-639e8ec43c61	RESOLVE	2026-08-04 08:57:55.192254	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/resolve	\N	MaintenanceRequest	162.158.88.170	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/resolve	\N	\N
ab2842eb-3259-47a6-a745-ecc0b39b4fc3	CREATE	2026-08-04 08:58:56.105594	POST /api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/confirm-slot	\N	MaintenanceRequest	162.158.190.116	POST	/api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/confirm-slot	\N	\N
9318d1b7-2f5c-45e4-aeea-f56038cfe24b	CREATE	2026-08-04 08:59:06.640272	POST /api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/tenant-confirm-slot	\N	MaintenanceRequest	162.158.190.116	POST	/api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/tenant-confirm-slot	\N	\N
fd9e61b4-a5b6-41c2-829c-e463fa400d88	CREATE	2026-08-04 08:59:13.117323	POST /api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/start	\N	MaintenanceRequest	162.158.162.76	POST	/api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/start	\N	\N
9d0055da-7d22-4be2-8e3a-7af3523f01c5	CREATE	2026-08-04 08:59:28.815564	POST /api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/materials	\N	MaintenanceRequest	172.68.164.63	POST	/api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/materials	\N	\N
e70119bd-77bc-4674-b264-1f4975de3bd0	CREATE	2026-08-04 08:59:47.405945	POST /api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/completion-images	\N	MaintenanceRequest	172.68.164.63	POST	/api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/completion-images	\N	\N
06b13dcc-80f2-4159-a4b2-fa2d51999b43	CREATE	2026-08-04 08:59:53.806857	POST /api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/completion-images	\N	MaintenanceRequest	172.71.124.28	POST	/api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/completion-images	\N	\N
0329a06d-97d4-4570-bec3-6f582a487154	CREATE	2026-08-04 09:00:01.006251	POST /api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/completion-images	\N	MaintenanceRequest	162.158.108.109	POST	/api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/completion-images	\N	\N
08b3cfeb-b47c-466b-b8a0-e034233a120c	CREATE	2026-08-04 09:00:10.507288	POST /api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/completion-images	\N	MaintenanceRequest	172.71.124.28	POST	/api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/completion-images	\N	\N
72f7f1ef-ccca-46d0-ae14-94bc99e9dc85	CREATE	2026-08-04 09:00:33.805314	POST /api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/completion-images	\N	MaintenanceRequest	162.158.108.109	POST	/api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/completion-images	\N	\N
afc168cc-6825-4629-bcd6-7bfd04a7c891	RESOLVE	2026-08-04 09:00:51.040872	POST /api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/resolve	\N	MaintenanceRequest	172.71.152.78	POST	/api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/resolve	\N	\N
5140182c-3de1-4bd8-82b3-1332e62f6304	RESOLVE	2026-08-04 09:00:52.133292	POST /api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/resolve	\N	MaintenanceRequest	172.71.152.78	POST	/api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/resolve	\N	\N
0b4121db-5b7f-4c28-a60b-b5044a1ec29f	RESOLVE	2026-08-04 09:00:54.271203	POST /api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/resolve	\N	MaintenanceRequest	104.22.176.10	POST	/api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/resolve	\N	\N
e7cc4569-168f-4bb8-9a94-e68de1aeabc5	RESOLVE	2026-08-04 09:00:58.361505	POST /api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/resolve	\N	MaintenanceRequest	104.22.176.10	POST	/api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/resolve	\N	\N
8c215890-e1f7-47a4-bba4-8035d9e864a1	CREATE	2026-08-04 09:01:13.205875	POST /api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/completion-images	\N	MaintenanceRequest	104.22.176.10	POST	/api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/completion-images	\N	\N
a47290ee-b45e-44ce-b470-61cf19d3fa58	CREATE	2026-08-04 09:01:18.003315	POST /api/maintenance/c5e0255e-0794-408f-9677-5db981f2d32f/confirm-slot	\N	MaintenanceRequest	104.22.176.10	POST	/api/maintenance/c5e0255e-0794-408f-9677-5db981f2d32f/confirm-slot	\N	\N
6c934b61-ef61-4d16-8bc1-d536cfa27b31	CREATE	2026-08-04 09:01:23.579727	POST /api/maintenance/c5e0255e-0794-408f-9677-5db981f2d32f/tenant-confirm-slot	\N	MaintenanceRequest	172.71.152.78	POST	/api/maintenance/c5e0255e-0794-408f-9677-5db981f2d32f/tenant-confirm-slot	\N	\N
db916573-d1e5-4ef1-bf7e-c662b3c00f77	CREATE	2026-08-04 09:01:50.105611	POST /api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/completion-images	\N	MaintenanceRequest	172.71.124.28	POST	/api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/completion-images	\N	\N
e25afbed-bd9c-424d-b67d-d48801003ce0	CREATE	2026-08-04 09:01:56.011177	POST /api/maintenance/c5e0255e-0794-408f-9677-5db981f2d32f/tenant-confirm-slot	\N	MaintenanceRequest	172.71.152.78	POST	/api/maintenance/c5e0255e-0794-408f-9677-5db981f2d32f/tenant-confirm-slot	\N	\N
a1cd8277-9d42-4bbd-bfd4-ddfc1de1e907	CREATE	2026-08-04 09:01:56.112969	POST /api/maintenance/c5e0255e-0794-408f-9677-5db981f2d32f/tenant-confirm-slot	\N	MaintenanceRequest	172.71.82.18	POST	/api/maintenance/c5e0255e-0794-408f-9677-5db981f2d32f/tenant-confirm-slot	\N	\N
e1bb16c1-b3b1-4eee-a861-aa391e100d10	CREATE	2026-08-04 09:01:56.318635	POST /api/maintenance/c5e0255e-0794-408f-9677-5db981f2d32f/tenant-confirm-slot	\N	MaintenanceRequest	172.71.124.12	POST	/api/maintenance/c5e0255e-0794-408f-9677-5db981f2d32f/tenant-confirm-slot	\N	\N
9298b47b-877f-4192-9f1b-3d3c4994c007	CREATE	2026-08-04 09:02:27.010076	POST /api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/completion-images	\N	MaintenanceRequest	172.70.93.64	POST	/api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/completion-images	\N	\N
79d9ebcd-5eba-4563-b195-36d2be134e4b	CREATE	2026-08-04 09:03:03.502912	POST /api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/completion-images	\N	MaintenanceRequest	172.71.124.28	POST	/api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/completion-images	\N	\N
325f1867-e45f-4155-a831-1d5bdca86247	CREATE	2026-08-04 09:13:42.061445	POST /api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/completion-images	\N	MaintenanceRequest	172.69.176.63	POST	/api/maintenance/92b4e6ca-0abe-429e-8385-18666f89cd13/completion-images	\N	\N
b1bfe311-cad2-44ff-b024-ae9665c56d93	CREATE	2026-08-04 09:22:53.956076	POST /api/maintenance/with-images	\N	MaintenanceRequest	162.158.179.50	POST	/api/maintenance/with-images	\N	\N
db2f8c8a-6931-49ef-ad22-4ad96ea4ffbf	CREATE	2026-08-04 09:22:57.61446	POST /api/maintenance/with-images	\N	MaintenanceRequest	162.158.179.50	POST	/api/maintenance/with-images	\N	\N
23da41e5-a726-48d3-9b5f-8830821b7f50	CREATE	2026-08-04 09:23:02.320136	POST /api/maintenance/with-images	\N	MaintenanceRequest	162.158.179.50	POST	/api/maintenance/with-images	\N	\N
7bec0780-5c08-42ba-a906-bf6a9df7fbfe	CREATE	2026-08-04 09:23:09.357197	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	172.70.208.107	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
0c962948-e924-4a69-bbbb-9732bf6b9356	CREATE	2026-08-04 09:23:09.527749	POST /api/maintenance/with-images	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/with-images	\N	\N
1ab5268d-c4e5-4860-81d9-7a7dbbdcdcfe	CREATE	2026-08-04 09:28:53.517003	POST /api/maintenance/with-images	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/with-images	\N	\N
388ce7ca-ee65-47b3-87ea-078a20e2e7fb	CREATE	2026-08-04 09:29:09.877742	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.23.175.246	POST	/api/maintenance/with-images	\N	\N
ff1c46d3-95e7-4cb6-b1ef-453cf6b20f06	ASSIGN	2026-08-04 09:30:54.155934	POST /api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/assign	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/assign	\N	\N
a3272cfe-5bff-4dd3-9bb1-1f470e7dc6ed	CREATE	2026-08-04 09:32:01.556472	POST /api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/confirm-slot	\N	MaintenanceRequest	104.23.175.246	POST	/api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/confirm-slot	\N	\N
ddc6a3ba-4616-4903-b08e-f001b1b5b39e	CREATE	2026-08-04 09:32:03.774926	POST /api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/start	\N	MaintenanceRequest	172.68.164.62	POST	/api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/start	\N	\N
4dd58994-f5e6-4ab1-b3d6-126c4cc9f02a	CREATE	2026-08-04 09:33:49.283682	POST /api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/tenant-confirm-slot	\N	MaintenanceRequest	162.158.114.170	POST	/api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/tenant-confirm-slot	\N	\N
66b2f9b7-5a35-4cd6-8d38-066082b9bf4a	CREATE	2026-08-04 09:34:13.51879	POST /api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/notes	\N	MaintenanceRequest	162.158.114.170	POST	/api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/notes	\N	\N
619587b2-90d4-409b-9e35-e6f24cb5b527	CREATE	2026-08-04 09:34:21.686318	POST /api/notifications/e0500e8a-02cf-40bd-b43d-2090aeba4420/read	\N	Notification	104.23.175.247	POST	/api/notifications/e0500e8a-02cf-40bd-b43d-2090aeba4420/read	\N	\N
92c91c89-d511-4d01-9c50-ce4a7929090b	PAYMENT	2026-08-04 09:34:37.130053	POST /api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	Invoice	172.68.211.104	POST	/api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	\N
40a9a5c5-65cc-4218-bf3e-fe1bd5802a15	PAYMENT	2026-08-04 09:34:37.567546	POST /api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	Invoice	172.68.211.104	POST	/api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	\N
cdc9fe54-e737-416f-9534-bf5cdf7fb1bb	RENEW	2026-08-04 17:07:33.02525	POST /api/contracts/b6000000-0000-0000-0000-000000000002/renew	\N	Contract	172.70.93.65	POST	/api/contracts/b6000000-0000-0000-0000-000000000002/renew	\N	\N
b8b46f7d-4eeb-4ad2-994b-5b594e498c42	CREATE	2026-08-04 17:07:59.124156	POST /api/invoices/generate	\N	Invoice	162.158.179.50	POST	/api/invoices/generate	\N	\N
bf128dba-f0ad-4e9f-90fd-3db198e4c37c	RESOLVE	2026-08-04 17:08:06.419102	POST /api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/resolve	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/resolve	\N	\N
a20a690d-7b2d-4c63-9a34-bd06d380cdb9	RESOLVE	2026-08-04 17:08:07.919146	POST /api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/resolve	\N	MaintenanceRequest	104.23.175.246	POST	/api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/resolve	\N	\N
cc64f5fc-e95d-4adc-934b-826359a55cfa	RESOLVE	2026-08-04 17:08:08.731791	POST /api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/resolve	\N	MaintenanceRequest	162.158.193.231	POST	/api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/resolve	\N	\N
27d2afb0-ee82-4f19-a2d9-001ff4fc1d2c	ASSIGN	2026-08-04 17:08:23.823257	POST /api/maintenance/ee2e951d-6752-4790-8805-0a21dc2bf15a/assign	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/ee2e951d-6752-4790-8805-0a21dc2bf15a/assign	\N	\N
31998f89-b402-4451-be55-122913dde71c	DELETE	2026-08-05 02:25:15.062524	DELETE /api/properties/b3000000-0000-0000-0000-000000000001	\N	Property	104.23.175.247	DELETE	/api/properties/b3000000-0000-0000-0000-000000000001	\N	\N
9e1e1780-f730-4966-92b0-3c0408fd85de	DELETE	2026-08-05 02:57:15.364818	DELETE /api/properties/b3000000-0000-0000-0000-000000000001/rooms/b5000000-0000-0000-0000-000000000001	\N	Property	172.68.164.63	DELETE	/api/properties/b3000000-0000-0000-0000-000000000001/rooms/b5000000-0000-0000-0000-000000000001	\N	\N
a0893ebd-94c5-40cf-a9a8-acc4a1eecddf	CREATE	2026-08-05 03:04:20.170676	POST /api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/materials	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/materials	\N	\N
fb46d7f4-dde5-4563-906d-d18f29daf746	CREATE	2026-08-05 03:04:36.567464	POST /api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	\N
5e1aa14c-e80d-4120-8fd8-b0f4e3d53e40	CREATE	2026-08-05 03:04:40.064666	POST /api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	MaintenanceRequest	172.68.164.63	POST	/api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	\N
16500d72-95bf-4cf6-8539-368bffec812e	CREATE	2026-08-05 03:04:57.62407	POST /api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	\N
21917182-4948-496c-a7cf-79fab3f1b654	CREATE	2026-08-05 03:05:03.752733	POST /api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	MaintenanceRequest	104.23.175.246	POST	/api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	\N
af73d9f8-c809-4387-bb2b-cefe3206837b	CREATE	2026-08-05 03:05:04.462156	POST /api/notifications/053a1f70-1efd-4ba4-be2b-db18795fb3c8/read	\N	Notification	172.71.218.224	POST	/api/notifications/053a1f70-1efd-4ba4-be2b-db18795fb3c8/read	\N	\N
6ef25c60-b1df-49cb-86d9-ac7d92f4d5fb	CREATE	2026-08-05 03:05:04.921897	POST /api/notifications/87af5b6d-e69b-4926-a502-45f19915cc18/read	\N	Notification	172.71.218.224	POST	/api/notifications/87af5b6d-e69b-4926-a502-45f19915cc18/read	\N	\N
6e7427f5-bb4d-4eb1-a616-0f1c408f836e	CREATE	2026-08-05 03:05:14.514655	POST /api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	MaintenanceRequest	172.71.215.16	POST	/api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	\N
41c4eca0-8b7f-4791-8a46-72bebfded3e8	PAYMENT	2026-08-05 03:05:50.559619	POST /api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	Invoice	172.71.215.16	POST	/api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	\N
4539a800-a26a-46ec-b22a-fe7a33283278	PAYMENT	2026-08-05 03:05:51.107469	POST /api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	Invoice	104.23.175.246	POST	/api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	\N
3b7ef63e-4e05-4ede-a28b-f96b01e8742e	CREATE	2026-08-05 03:10:25.838722	POST /api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	MaintenanceRequest	172.70.93.65	POST	/api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	\N
f59b682d-a336-4c5a-91a0-a7fc8b762d7b	CREATE	2026-08-05 03:10:34.093408	POST /api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	MaintenanceRequest	172.68.211.105	POST	/api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	\N
787fe950-17b4-406a-ab27-4feb7623387d	CREATE	2026-08-05 03:11:00.79527	POST /api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	MaintenanceRequest	172.71.81.84	POST	/api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	\N
8e1ca77c-29b7-40b0-afa3-5b8139dfb7a4	CREATE	2026-08-05 03:11:46.082005	POST /api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	MaintenanceRequest	162.158.193.196	POST	/api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	\N
ddb2bba4-55da-48aa-859d-6b340ae8783a	PAYMENT	2026-08-05 03:12:53.521888	POST /api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	Invoice	172.70.208.107	POST	/api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	\N
20545b67-5b4a-4796-9216-8b7ad432cd00	PAYMENT	2026-08-05 03:12:53.925471	POST /api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	Invoice	172.70.93.64	POST	/api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	\N
c9d96360-c57f-4670-ab25-8a52397534d8	CREATE	2026-08-05 03:18:03.943799	POST /api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	MaintenanceRequest	172.71.215.15	POST	/api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	\N
ca595d10-cd7d-458a-9038-77b114c6738e	CREATE	2026-08-05 03:20:56.274853	POST /api/invoices/7c135337-f51e-49fa-8731-3768446542f0/request-cash	\N	Invoice	172.71.82.19	POST	/api/invoices/7c135337-f51e-49fa-8731-3768446542f0/request-cash	\N	\N
eba120eb-9d32-4d4e-83ed-76bab4db5b3d	CREATE	2026-08-05 03:22:36.058404	POST /api/invoices/generate	\N	Invoice	162.159.98.51	POST	/api/invoices/generate	\N	\N
e3c5be77-617b-4dca-99f3-abd25c2b03a1	CREATE	2026-08-05 03:23:54.765322	POST /api/notifications/9bbf4b00-a87d-4fb5-9838-9b381149d26a/read	\N	Notification	172.70.208.107	POST	/api/notifications/9bbf4b00-a87d-4fb5-9838-9b381149d26a/read	\N	\N
baaca93e-b282-4631-b1ea-2349bbcac884	CREATE	2026-08-05 03:27:50.090504	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.23.175.246	POST	/api/maintenance/with-images	\N	\N
15cbfc0c-db0d-4dd9-97ac-46600031b40e	CREATE	2026-08-05 03:27:57.497818	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/with-images	\N	\N
dd0726ec-059d-47bb-86d7-96a289854301	CREATE	2026-08-05 03:28:26.010564	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.70.93.64	POST	/api/maintenance/with-images	\N	\N
dbdb4388-0767-400e-a7ac-5dd158851eb2	CREATE	2026-08-05 03:28:35.306809	POST /api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	MaintenanceRequest	172.70.93.64	POST	/api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	\N
cf2fd256-4714-497b-8dc9-30851e5cbd9b	CREATE	2026-08-05 03:28:40.335465	POST /api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	\N
7518f17e-2215-4b1e-896c-d75085495ed5	CREATE	2026-08-05 03:28:49.541716	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
54a44ca4-b2cc-4092-8acf-81c7fdb7acdf	ASSIGN	2026-08-05 03:29:12.706699	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/assign	\N	MaintenanceRequest	172.70.208.106	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/assign	\N	\N
33275330-1936-4578-a84b-3c319a0a0b63	CREATE	2026-08-05 03:29:32.606617	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/confirm-slot	\N	MaintenanceRequest	172.71.215.15	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/confirm-slot	\N	\N
32980f2f-5de1-4e88-a681-01c3b5052dc8	CREATE	2026-08-05 03:29:45.40691	POST /api/notifications/2ac3c68c-c2c7-46d0-8190-57a0fe42638f/read	\N	Notification	172.71.82.19	POST	/api/notifications/2ac3c68c-c2c7-46d0-8190-57a0fe42638f/read	\N	\N
ea2ee21c-e5a5-4efb-8135-e789b77e81c9	CREATE	2026-08-05 03:29:45.818798	POST /api/notifications/5f082cb1-a218-40a6-b3e8-158433bf119e/read	\N	Notification	172.71.81.83	POST	/api/notifications/5f082cb1-a218-40a6-b3e8-158433bf119e/read	\N	\N
9b6a3929-6463-42e6-a88d-32bfd33984c8	CREATE	2026-08-05 03:29:46.2018	POST /api/notifications/82478989-e523-4193-bdf2-f6c87aa115ac/read	\N	Notification	172.68.211.105	POST	/api/notifications/82478989-e523-4193-bdf2-f6c87aa115ac/read	\N	\N
1632568d-4d22-4b81-925f-9f829d27caf6	CREATE	2026-08-05 03:29:46.606096	POST /api/notifications/fbb216e5-808c-40a5-8b3d-d7fe36d53451/read	\N	Notification	172.68.164.62	POST	/api/notifications/fbb216e5-808c-40a5-8b3d-d7fe36d53451/read	\N	\N
adf91a26-952c-4a96-bb3d-8adb220724bc	CREATE	2026-08-05 03:29:46.962022	POST /api/notifications/3453a8f2-96bc-4dad-bab2-2d453232b126/read	\N	Notification	172.68.164.62	POST	/api/notifications/3453a8f2-96bc-4dad-bab2-2d453232b126/read	\N	\N
c783b525-524f-4beb-a4cf-49361a1367e5	CREATE	2026-08-05 03:29:58.287137	POST /api/notifications/68e1371c-5a5b-4b35-8174-c9857102bccc/read	\N	Notification	172.70.93.64	POST	/api/notifications/68e1371c-5a5b-4b35-8174-c9857102bccc/read	\N	\N
f748868b-eb59-46c5-bff4-7b6a887b2ae1	CREATE	2026-08-05 03:30:38.306375	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/notes	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/notes	\N	\N
6f06f415-9185-4c2a-a0e8-30bff2e1c9ce	CREATE	2026-08-05 03:30:51.851412	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
a9fa72a9-bbad-420b-9b83-9ed76fd0f7f7	CREATE	2026-08-05 03:31:33.619023	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/materials	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/materials	\N	\N
a57669a3-2dc1-491f-9482-658322b8d8da	CREATE	2026-08-06 13:34:54.530338	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	172.71.215.15	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
6a3de548-a3b0-46c5-aeea-69a997be1575	CREATE	2026-08-14 04:31:24.305597	POST /api/notifications/1e2c4b00-84de-4369-93d1-73376aab9ac1/read	\N	Notification	104.22.176.10	POST	/api/notifications/1e2c4b00-84de-4369-93d1-73376aab9ac1/read	\N	\N
b56c3e7d-ec4c-4f9d-9d6d-447b3023292e	RESOLVE	2026-08-19 07:09:47.632496	POST /api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/resolve	\N	MaintenanceRequest	172.68.164.171	POST	/api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/resolve	\N	\N
7a1c761b-56af-461f-b379-58fac337b0d5	CREATE	2026-08-05 03:29:51.411178	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/tenant-confirm-slot	\N	MaintenanceRequest	172.68.164.62	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/tenant-confirm-slot	\N	\N
efdc2985-92f9-4dac-9b31-fe22e89c5c99	CREATE	2026-08-05 03:30:43.267057	POST /api/notifications/75a05010-54d7-43bc-b0dd-a7c86159705d/read	\N	Notification	104.23.175.247	POST	/api/notifications/75a05010-54d7-43bc-b0dd-a7c86159705d/read	\N	\N
b318d84b-7ec0-4511-abe3-244564e240f8	CREATE	2026-08-05 03:31:46.706443	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
62029fc8-1ad4-4dbe-9b58-be2d07a164d9	PAYMENT	2026-08-06 15:05:36.239577	POST /api/invoices/95fa58e3-2f13-410b-80c7-159fec6186f9/pay-cash	\N	Invoice	162.159.98.50	POST	/api/invoices/95fa58e3-2f13-410b-80c7-159fec6186f9/pay-cash	\N	\N
de45ef4c-0f50-4335-aa9c-834ef1811f0d	CREATE	2026-08-06 15:07:28.943154	POST /api/maintenance/483e9cdc-246b-48a5-9a8f-2327910f2b03/completion-images	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/483e9cdc-246b-48a5-9a8f-2327910f2b03/completion-images	\N	\N
a0bf96a2-934f-4067-9fd6-7f5432334019	CREATE	2026-08-14 04:31:27.015717	POST /api/notifications/af7089e9-7b9f-459f-9725-579b463eb248/read	\N	Notification	104.22.176.10	POST	/api/notifications/af7089e9-7b9f-459f-9725-579b463eb248/read	\N	\N
07d3a604-8e6e-49b7-9f14-fb73b0cd365c	CREATE	2026-08-19 07:10:46.995338	POST /api/notifications/2a79c1f9-5f5f-4d86-91e7-99020ce23e2c/read	\N	Notification	104.23.175.246	POST	/api/notifications/2a79c1f9-5f5f-4d86-91e7-99020ce23e2c/read	\N	\N
70199144-b696-45ce-8019-bd7d39779eb6	CREATE	2026-08-05 03:29:57.322795	POST /api/notifications/8a28fb87-b029-4a42-a20f-d67c87c146fc/read	\N	Notification	172.68.211.104	POST	/api/notifications/8a28fb87-b029-4a42-a20f-d67c87c146fc/read	\N	\N
7df4ecf0-7512-414c-a3c3-1f6351b5647e	CREATE	2026-08-05 03:30:01.006688	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/start	\N	MaintenanceRequest	162.158.193.197	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/start	\N	\N
02cb65fb-b009-47e5-acf7-0936f281402c	CREATE	2026-08-05 03:30:24.306936	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/materials	\N	MaintenanceRequest	162.158.193.197	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/materials	\N	\N
cf443b95-3f0f-4efd-9a94-599abfbee048	CREATE	2026-08-05 03:30:42.319384	POST /api/notifications/380a702d-4928-470d-9e1e-1bd01d0d4e1f/read	\N	Notification	104.23.175.247	POST	/api/notifications/380a702d-4928-470d-9e1e-1bd01d0d4e1f/read	\N	\N
a6d4b755-d3aa-494e-80c7-89cdf87ff9ce	CREATE	2026-08-05 03:30:42.817556	POST /api/notifications/823f4865-7e27-4235-a545-294822b84e81/read	\N	Notification	104.23.175.247	POST	/api/notifications/823f4865-7e27-4235-a545-294822b84e81/read	\N	\N
75fb7f34-47cd-4181-8919-1b83244f003a	CREATE	2026-08-05 03:30:59.142151	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
b764b8fd-1a67-4760-bda4-429cbf8f2bd2	CREATE	2026-08-05 03:31:40.753627	POST /api/notifications/c2dd6de2-daa6-4aef-850f-fb16700fb4f0/read	\N	Notification	162.159.98.51	POST	/api/notifications/c2dd6de2-daa6-4aef-850f-fb16700fb4f0/read	\N	\N
ab3806d2-b268-47cc-941d-f3043eccdad1	CREATE	2026-08-05 03:31:57.687908	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	172.71.215.15	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
77bbd447-396b-46e6-b03c-93bf39eb83da	CREATE	2026-08-05 03:32:03.327385	POST /api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/request-cash	\N	Invoice	172.71.215.15	POST	/api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/request-cash	\N	\N
cc87492d-6227-45b7-afad-64605fcd2506	RESOLVE	2026-08-05 03:33:50.619176	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/resolve	\N	MaintenanceRequest	172.68.164.63	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/resolve	\N	\N
4c2dc41a-0152-4d5b-bd46-b5253971c9b3	RESOLVE	2026-08-05 03:33:54.821461	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/resolve	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/resolve	\N	\N
1f8a6647-7208-4932-9509-e07afe613a6d	CREATE	2026-08-05 03:34:05.439303	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
c2b82e5f-05fb-45b0-88c7-b60d53aed6e5	CREATE	2026-08-05 03:34:30.175486	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
13e28c07-fa1e-4571-86fc-c1cd5674f53b	PAYMENT	2026-08-05 03:37:31.607001	POST /api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	Invoice	104.23.175.247	POST	/api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	\N
4110b1d3-a7af-4313-9e84-d4ad5565f7c8	PAYMENT	2026-08-05 03:37:31.891398	POST /api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	Invoice	104.23.175.247	POST	/api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	\N
3b733598-8584-4067-b334-a8229fb947c4	CREATE	2026-08-05 03:37:49.11793	POST /api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/request-cash	\N	Invoice	104.23.175.247	POST	/api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/request-cash	\N	\N
6e4849bf-cd31-4da3-9d76-f2df05d4ead8	CREATE	2026-08-05 03:39:13.316083	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	172.71.81.83	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
a5e8b211-0e6c-47c7-9c38-7581c20f596f	CREATE	2026-08-05 03:39:26.433496	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	162.158.179.50	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
880280d5-e09d-43d6-9f74-44e6d555e586	CREATE	2026-08-05 03:40:19.27056	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	162.158.114.171	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
e270bb83-d125-4e18-893b-88aadf486463	CREATE	2026-08-05 03:40:27.684459	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	172.68.164.62	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
21b55bd6-fcd2-4011-bd73-fb2768f99544	CREATE	2026-08-05 03:40:42.724966	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/materials	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/materials	\N	\N
f9353312-fe32-4d68-9c14-9f80dcfa2514	CREATE	2026-08-05 03:40:57.106447	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/notes	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/notes	\N	\N
9d9641ad-ecf7-4c70-8090-81268ebddd2b	CREATE	2026-08-05 03:41:05.190858	POST /api/notifications/b7864812-b418-4c3e-9f3b-24b302ca3cad/read	\N	Notification	162.158.193.197	POST	/api/notifications/b7864812-b418-4c3e-9f3b-24b302ca3cad/read	\N	\N
7d4aa9d5-c045-41cb-a715-fca9120df5da	CREATE	2026-08-05 03:41:05.805473	POST /api/notifications/821ab287-0290-4600-9a8a-4f8575c7933d/read	\N	Notification	172.68.164.62	POST	/api/notifications/821ab287-0290-4600-9a8a-4f8575c7933d/read	\N	\N
ee97305e-911b-4a7e-8a28-e6eb462f7265	CREATE	2026-08-05 03:41:11.24471	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	162.158.193.197	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
f1dd476e-5328-4394-8416-0e2998d648b4	CREATE	2026-08-05 03:41:32.336545	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	162.158.193.197	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
bab22620-c864-42b5-80cc-530ed707ec7e	RESOLVE	2026-08-05 03:44:37.606123	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/resolve	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/resolve	\N	\N
f7f45327-c0a9-4b02-909c-7d79119bc9f7	PAYMENT	2026-08-05 03:44:50.29013	POST /api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	Invoice	172.70.208.107	POST	/api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	\N
6d2cc822-0c3c-44d1-a790-9dff44eb94bd	PAYMENT	2026-08-05 03:44:50.561859	POST /api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	Invoice	162.158.179.49	POST	/api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	\N
1f6e1f0c-0e86-4415-abdc-5c7fc3b64250	CREATE	2026-08-05 03:46:40.698968	POST /api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	MaintenanceRequest	162.158.179.50	POST	/api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	\N
84ed7022-061c-46a1-b9bd-2eb780bc2a59	PAYMENT	2026-08-05 03:47:58.255526	POST /api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	Invoice	172.70.208.106	POST	/api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	\N
ac7a37d8-145b-44c6-9676-16d818b13397	PAYMENT	2026-08-05 03:47:58.701276	POST /api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	Invoice	162.158.114.170	POST	/api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	\N
10807258-141b-4866-ba59-2935c57eb74c	CREATE	2026-08-05 03:48:20.08625	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	172.70.208.106	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
6ba5eee1-083c-4ff5-b487-407fba861e11	CREATE	2026-08-05 06:04:48.806633	POST /api/invoices/generate	\N	Invoice	162.159.98.50	POST	/api/invoices/generate	\N	\N
52042908-9b9d-4735-8a00-0ce6b1c20df2	CREATE	2026-08-05 03:48:25.786688	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	172.70.208.106	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
c27a7840-3191-4a35-992d-18c628f6de3d	CREATE	2026-08-06 15:07:10.616322	POST /api/maintenance/2f6bcc81-68a7-46e1-b7b8-f98bf267fe53/confirm-slot	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/2f6bcc81-68a7-46e1-b7b8-f98bf267fe53/confirm-slot	\N	\N
a0386429-7bd0-48b9-86de-be2030892a9f	CREATE	2026-08-06 15:09:01.69579	POST /api/properties/e9a22c20-ade9-4541-9a58-f2b10a870651/rooms	\N	Property	162.159.98.50	POST	/api/properties/e9a22c20-ade9-4541-9a58-f2b10a870651/rooms	\N	\N
e3f9d2ab-302f-4bdd-b371-e346f580736c	PAYMENT	2026-08-06 15:13:20.072099	POST /api/invoices/c979cd05-f5aa-4903-8f9d-29e3e743ee51/pay-cash	\N	Invoice	172.71.152.78	POST	/api/invoices/c979cd05-f5aa-4903-8f9d-29e3e743ee51/pay-cash	\N	\N
331f0e38-311f-4a0c-b4f8-e7703aaca345	TERMINATE	2026-08-06 15:14:26.97634	POST /api/contracts/3f3987fa-7c26-48dd-96a1-b78c8237e4fe/terminate	\N	Contract	172.71.152.77	POST	/api/contracts/3f3987fa-7c26-48dd-96a1-b78c8237e4fe/terminate	\N	\N
c5e80f7d-f556-4061-8c2e-c0d6daf1aed7	CREATE	2026-08-14 04:31:38.224683	POST /api/notifications/9dbbcebf-4ac1-465c-a451-2815f8a569d1/read	\N	Notification	162.158.107.34	POST	/api/notifications/9dbbcebf-4ac1-465c-a451-2815f8a569d1/read	\N	\N
2c772fcb-ae09-414a-8061-d9a5a8e63506	CREATE	2026-08-20 13:02:42.875833	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	162.158.163.125	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
83f14fbd-f6a8-4621-9fe9-ffc2a741f614	CREATE	2026-08-05 03:48:41.54892	POST /api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/completion-images	\N	\N
b49f9e1f-7665-4c6f-bdbc-05cf6dc7d10a	CREATE	2026-08-05 03:52:21.598091	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	172.68.211.105	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
7bf51f2e-6ce0-4917-8547-c0e5b92ce9ce	CREATE	2026-08-05 03:55:18.407051	POST /api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/tenant-confirm-slot	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/tenant-confirm-slot	\N	\N
515c247f-5d5d-440b-8de1-c339cc9b1df7	CREATE	2026-08-05 03:55:23.410745	POST /api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/start	\N	MaintenanceRequest	162.158.193.196	POST	/api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/start	\N	\N
8fe38bec-143b-4bb4-ad95-62550f18f73c	CREATE	2026-08-06 15:08:08.002517	POST /api/users	\N	User	162.159.98.50	POST	/api/users	\N	\N
786984f7-5e4e-4534-bf93-432096600603	PAYMENT	2026-08-06 15:11:15.991024	POST /api/invoices/c979cd05-f5aa-4903-8f9d-29e3e743ee51/pay-online	\N	Invoice	172.71.152.77	POST	/api/invoices/c979cd05-f5aa-4903-8f9d-29e3e743ee51/pay-online	\N	\N
91df2b78-2519-48d2-8c67-c8a0dbfcabfe	CREATE	2026-08-06 15:16:58.256886	POST /api/invoices/generate	\N	Invoice	162.158.179.49	POST	/api/invoices/generate	\N	\N
c2587d94-5284-4f29-92c7-104c45e71996	CREATE	2026-08-06 15:21:59.894939	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.215.16	POST	/api/maintenance/with-images	\N	\N
ecc76728-eb8a-4ee9-ba4d-cd46bee9ea70	CREATE	2026-08-14 04:31:38.68325	POST /api/notifications/015c9b25-9656-428f-a025-cfa7ca28fcfa/read	\N	Notification	104.22.176.10	POST	/api/notifications/015c9b25-9656-428f-a025-cfa7ca28fcfa/read	\N	\N
ca148061-eb14-4df5-9892-42e77bc156a8	CREATE	2026-08-21 01:47:35.762988	POST /api/rooms/3697261c-44e6-4b47-9b9d-25277cc8da51/contracts	\N	Room	172.69.176.63	POST	/api/rooms/3697261c-44e6-4b47-9b9d-25277cc8da51/contracts	\N	\N
e5863f04-820f-4e02-b173-713a9f4e7749	TERMINATE	2026-08-21 01:48:59.854932	POST /api/contracts/5448b64c-a55f-40df-9378-c7b2a4e42a37/terminate	\N	Contract	162.158.88.171	POST	/api/contracts/5448b64c-a55f-40df-9378-c7b2a4e42a37/terminate	\N	\N
a709d6d7-5f29-451a-99ee-be2358328741	CREATE	2026-08-21 01:51:29.282809	POST /api/notifications/a3cb15a9-facb-4c6d-b513-fbe3a74fec86/read	\N	Notification	172.70.208.107	POST	/api/notifications/a3cb15a9-facb-4c6d-b513-fbe3a74fec86/read	\N	\N
152b4bd3-e476-4349-926f-c3eaba9f8ba6	CREATE	2026-08-21 01:52:03.368639	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.81.100	POST	/api/maintenance/with-images	\N	\N
0b394bae-6a9c-471d-b4fb-29b5d8cd69d8	CREATE	2026-08-21 01:52:12.216687	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.22.176.10	POST	/api/maintenance/with-images	\N	\N
f7b04830-84ef-4546-b057-c190b2d579c5	CREATE	2026-08-05 03:48:51.166732	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
abf603c3-e4f3-428c-afba-d58e9fc93090	CREATE	2026-08-06 15:10:16.506159	POST /api/rooms/3697261c-44e6-4b47-9b9d-25277cc8da51/contracts	\N	Room	104.23.175.246	POST	/api/rooms/3697261c-44e6-4b47-9b9d-25277cc8da51/contracts	\N	\N
ddff7303-6d5c-4799-9e43-5732a7b1a8e1	UPDATE	2026-08-06 15:12:48.621787	PUT /api/properties/e9a22c20-ade9-4541-9a58-f2b10a870651/rooms/3697261c-44e6-4b47-9b9d-25277cc8da51	\N	Property	104.23.175.247	PUT	/api/properties/e9a22c20-ade9-4541-9a58-f2b10a870651/rooms/3697261c-44e6-4b47-9b9d-25277cc8da51	\N	\N
f0f049b3-52de-4aa7-8dda-1e70d2eced4d	CREATE	2026-08-14 04:31:39.023433	POST /api/notifications/bc396edb-9c1f-45b2-8afc-4a7bcfdfdfb7/read	\N	Notification	162.158.107.34	POST	/api/notifications/bc396edb-9c1f-45b2-8afc-4a7bcfdfdfb7/read	\N	\N
766b7da6-a435-467b-aa13-5542db60e24b	CREATE	2026-08-21 01:49:58.692254	POST /api/rooms/3697261c-44e6-4b47-9b9d-25277cc8da51/contracts	\N	Room	172.70.143.214	POST	/api/rooms/3697261c-44e6-4b47-9b9d-25277cc8da51/contracts	\N	\N
32ee7482-5989-486a-8330-31efbec9f7dc	ASSIGN	2026-08-21 01:52:48.759441	POST /api/maintenance/ea9d94f1-b8ff-45da-9312-91c673eaa885/assign	\N	MaintenanceRequest	172.70.208.107	POST	/api/maintenance/ea9d94f1-b8ff-45da-9312-91c673eaa885/assign	\N	\N
56b65cf6-9bc4-4449-8ad6-e7c7ce24056f	PAYMENT	2026-08-05 03:49:11.45372	POST /api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	Invoice	162.159.98.50	POST	/api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	\N
82df21b1-694a-492b-8297-7e7189326cc1	CREATE	2026-08-05 03:52:25.633626	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	172.70.208.106	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
a67bcada-8c81-4dc5-8062-3073400f954b	CREATE	2026-08-06 15:11:00.581798	POST /api/rooms/3697261c-44e6-4b47-9b9d-25277cc8da51/meter-readings	\N	Room	162.159.98.50	POST	/api/rooms/3697261c-44e6-4b47-9b9d-25277cc8da51/meter-readings	\N	\N
5b0c699a-06bc-45e3-b696-adee286170ac	CREATE	2026-08-06 15:14:00.55019	POST /api/rooms/3697261c-44e6-4b47-9b9d-25277cc8da51/meter-readings	\N	Room	172.71.152.78	POST	/api/rooms/3697261c-44e6-4b47-9b9d-25277cc8da51/meter-readings	\N	\N
2ebe4f90-26de-4852-b030-2be803226302	CREATE	2026-08-06 15:14:04.896223	POST /api/invoices/generate	\N	Invoice	172.71.218.224	POST	/api/invoices/generate	\N	\N
3170849c-6e95-4280-a787-a321a85057f5	CREATE	2026-08-06 15:15:33.583209	POST /api/invoices/generate	\N	Invoice	172.70.208.107	POST	/api/invoices/generate	\N	\N
c22f516e-1982-424a-b60d-6c01f0d761e1	CREATE	2026-08-21 01:50:44.054214	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.124.29	POST	/api/maintenance/with-images	\N	\N
620be5d0-34e3-45b3-8cb2-e651ff8a80ee	CREATE	2026-08-21 01:50:57.945209	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.70.208.107	POST	/api/maintenance/with-images	\N	\N
f3af842c-68d6-4de1-9ace-89cbfc92e987	PAYMENT	2026-08-05 03:49:11.707301	POST /api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	Invoice	162.159.98.51	POST	/api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	\N
ffda2c5f-4591-4172-968f-0c223d934f8d	CREATE	2026-08-06 15:11:09.301722	POST /api/invoices/generate	\N	Invoice	172.71.152.77	POST	/api/invoices/generate	\N	\N
6c4dd028-ea98-4509-9015-15b1e676ddd0	CREATE	2026-08-06 15:16:44.145252	POST /api/rooms/ce27f631-b495-48aa-9fc5-c60ec18a95eb/contracts	\N	Room	172.71.81.83	POST	/api/rooms/ce27f631-b495-48aa-9fc5-c60ec18a95eb/contracts	\N	\N
85269712-7e35-4dfe-a134-76cd8e4e3ac6	CREATE	2026-08-06 15:22:27.490364	POST /api/maintenance/229d8e58-ffbe-44d4-8909-3e92985cfe8c/confirm-slot	\N	MaintenanceRequest	172.71.81.83	POST	/api/maintenance/229d8e58-ffbe-44d4-8909-3e92985cfe8c/confirm-slot	\N	\N
77fa0321-6f3c-4cf3-a3ca-1fd4c55f3ec9	CREATE	2026-08-21 02:02:30.278269	POST /api/notifications/e9d2a314-8a70-461e-b3a3-120efffb2062/read	\N	Notification	104.22.176.10	POST	/api/notifications/e9d2a314-8a70-461e-b3a3-120efffb2062/read	\N	\N
5ac0528b-9312-446e-9a72-c61ca2c6e18d	PAYMENT	2026-08-05 03:50:38.195652	POST /api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	Invoice	162.158.114.171	POST	/api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	\N
bcbcd618-e5b3-41e0-9be8-c3a0a5736ca7	PAYMENT	2026-08-05 03:50:38.473946	POST /api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	Invoice	172.70.208.106	POST	/api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	\N
759d4d7a-6414-4722-b4ed-a37409e65165	CREATE	2026-08-05 03:52:16.019618	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	172.68.211.105	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
64492fda-0594-42be-9efe-2d93e9565468	CREATE	2026-08-05 03:52:19.331302	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	172.70.208.107	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
b400dba1-e53c-40b1-a34c-89bd5c3ecc9a	CREATE	2026-08-05 03:52:22.865857	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	172.71.152.78	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
9a0734be-126a-4f49-add8-ecfe71ff5788	CREATE	2026-08-05 03:52:24.432024	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	172.70.93.65	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
6600c894-cd50-46f4-a20f-4e49354f9a34	CREATE	2026-08-05 03:52:27.014985	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	172.70.208.107	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
8d599cf8-baaa-4eba-9bce-46193258ae52	CREATE	2026-08-05 03:54:10.350346	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/with-images	\N	\N
ab6aabe0-f782-4086-b9d7-400157daaa57	ASSIGN	2026-08-05 03:54:37.611181	POST /api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/assign	\N	MaintenanceRequest	162.158.179.50	POST	/api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/assign	\N	\N
026466c3-f072-4d7e-a621-1c9e02b25f6b	CREATE	2026-08-05 03:55:12.017579	POST /api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/confirm-slot	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/confirm-slot	\N	\N
69f6a44e-5334-4513-b78e-6eed037f5599	CREATE	2026-08-05 03:55:15.938447	POST /api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/tenant-confirm-slot	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/tenant-confirm-slot	\N	\N
39d82fa6-bcf8-4a79-b07e-22e44f120b7b	CREATE	2026-08-06 15:13:17.161462	POST /api/invoices/c979cd05-f5aa-4903-8f9d-29e3e743ee51/request-cash	\N	Invoice	172.71.152.78	POST	/api/invoices/c979cd05-f5aa-4903-8f9d-29e3e743ee51/request-cash	\N	\N
5a7271f3-26a5-45e2-8c94-26bcd442c2eb	CREATE	2026-08-06 15:15:52.932822	POST /api/invoices/generate	\N	Invoice	162.159.98.51	POST	/api/invoices/generate	\N	\N
8412c267-cdd4-44dd-a2bd-12d8bfb3bfa6	CREATE	2026-08-06 15:16:54.793842	POST /api/rooms/ce27f631-b495-48aa-9fc5-c60ec18a95eb/meter-readings	\N	Room	172.71.81.83	POST	/api/rooms/ce27f631-b495-48aa-9fc5-c60ec18a95eb/meter-readings	\N	\N
7ba6e8e2-9f89-459c-a72c-92c20621b83b	CREATE	2026-08-22 13:17:36.508047	POST /api/maintenance/ea9d94f1-b8ff-45da-9312-91c673eaa885/cancel	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/ea9d94f1-b8ff-45da-9312-91c673eaa885/cancel	\N	\N
5d854fc4-b2fa-497b-a2bd-3e900f43c015	CREATE	2026-08-22 13:18:11.597007	POST /api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/completion-images	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/completion-images	\N	\N
afd6962e-1da6-44ab-b3f5-15c3012726f3	CREATE	2026-08-05 03:51:11.785182	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	162.158.114.170	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
05d13584-7246-4647-b3bb-5a1b013ca59d	CREATE	2026-08-05 03:52:17.817734	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	162.158.114.171	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
4e267171-33fb-4a20-9bfd-b59f2072a96c	CREATE	2026-08-05 03:52:28.303202	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	162.158.114.171	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
d0f54206-ca98-4c8f-8dc5-74a477d9cdf8	CREATE	2026-08-05 03:55:44.81087	POST /api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/materials	\N	MaintenanceRequest	162.158.193.196	POST	/api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/materials	\N	\N
3a60b239-4059-40e6-9068-856ffe35a46e	CREATE	2026-08-05 03:56:04.318158	POST /api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/notes	\N	MaintenanceRequest	162.158.193.196	POST	/api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/notes	\N	\N
1eb7f08e-1a20-4044-9397-3485636c2953	CREATE	2026-08-05 03:56:10.792193	POST /api/notifications/393f805d-a906-468e-bb5c-3282b4aefa9f/read	\N	Notification	162.158.114.171	POST	/api/notifications/393f805d-a906-468e-bb5c-3282b4aefa9f/read	\N	\N
23781687-7e60-4ba3-b3e4-cbf847bd0331	CREATE	2026-08-05 03:56:11.720652	POST /api/notifications/c52b4e07-de7f-42ef-93dc-0aa4222dede1/read	\N	Notification	104.23.175.247	POST	/api/notifications/c52b4e07-de7f-42ef-93dc-0aa4222dede1/read	\N	\N
0321aac2-2b08-4f4c-8610-34d0485caa1b	CREATE	2026-08-05 03:56:12.712363	POST /api/notifications/ad93ed37-3d5f-4f20-8ee3-ee041caabb57/read	\N	Notification	162.158.114.171	POST	/api/notifications/ad93ed37-3d5f-4f20-8ee3-ee041caabb57/read	\N	\N
0841c2d4-ed5f-4abe-b53b-461e85d06759	CREATE	2026-08-05 03:56:14.627267	POST /api/notifications/b0fb06ae-cb40-4ae0-890d-4b5768f634ce/read	\N	Notification	172.70.208.106	POST	/api/notifications/b0fb06ae-cb40-4ae0-890d-4b5768f634ce/read	\N	\N
e3b8e409-3dff-4bd0-ada9-a8256ff910ea	CREATE	2026-08-05 03:56:15.875174	POST /api/notifications/0a71848b-297e-4c6b-b505-84c83f11ebaf/read	\N	Notification	172.70.208.106	POST	/api/notifications/0a71848b-297e-4c6b-b505-84c83f11ebaf/read	\N	\N
c38144c4-6412-4fd1-9d00-4743beef50a5	CREATE	2026-08-05 03:56:16.323811	POST /api/notifications/dd80d18e-1da7-4329-a215-4b868f3310d6/read	\N	Notification	104.23.175.247	POST	/api/notifications/dd80d18e-1da7-4329-a215-4b868f3310d6/read	\N	\N
fa2bd19b-dbad-49e2-9203-8fd5477f7400	CREATE	2026-08-05 03:56:31.70693	POST /api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/materials	\N	MaintenanceRequest	172.70.93.64	POST	/api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/materials	\N	\N
4fabdb92-b714-4701-a137-cb6138765a05	CREATE	2026-08-05 03:56:41.306116	POST /api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/notes	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/notes	\N	\N
23d0060b-dab6-45f4-846d-dd8a709c2dc9	CREATE	2026-08-05 03:56:44.323708	POST /api/notifications/16b9d34d-eace-4393-972d-a4a98dd6db64/read	\N	Notification	172.71.218.225	POST	/api/notifications/16b9d34d-eace-4393-972d-a4a98dd6db64/read	\N	\N
9d2ab9e1-9fa8-447c-b948-3d6ea3aaca00	CREATE	2026-08-05 03:56:45.975389	POST /api/notifications/eb0d1176-c3c0-4da3-9966-b76363a3a19e/read	\N	Notification	172.68.164.63	POST	/api/notifications/eb0d1176-c3c0-4da3-9966-b76363a3a19e/read	\N	\N
679179d3-e67d-4eb5-b790-1439d5302ce6	CREATE	2026-08-05 03:56:59.596814	POST /api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/completion-images	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/completion-images	\N	\N
09f9a12d-b97f-475a-9320-067b9e4356f8	CREATE	2026-08-05 03:58:00.247737	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.70.208.106	POST	/api/maintenance/with-images	\N	\N
f3cd4d65-deb4-426a-a5f8-07dabe60ac6d	ASSIGN	2026-08-05 03:58:23.208338	POST /api/maintenance/b7b0c13c-2dbe-4d08-b81c-032624bfe278/assign	\N	MaintenanceRequest	162.158.193.197	POST	/api/maintenance/b7b0c13c-2dbe-4d08-b81c-032624bfe278/assign	\N	\N
5309f523-5456-49b2-8c40-38be6a8f8a63	ASSIGN	2026-08-05 03:59:38.706432	POST /api/maintenance/b7b0c13c-2dbe-4d08-b81c-032624bfe278/assign	\N	MaintenanceRequest	104.23.175.246	POST	/api/maintenance/b7b0c13c-2dbe-4d08-b81c-032624bfe278/assign	\N	\N
367953fc-6fa0-4d40-ae49-745204942eaf	CREATE	2026-08-05 03:59:48.065381	POST /api/notifications/4b691afd-0d41-4237-9f2b-ea9162a26897/read	\N	Notification	172.70.208.107	POST	/api/notifications/4b691afd-0d41-4237-9f2b-ea9162a26897/read	\N	\N
29d183be-6ebc-4cf1-b189-5e77e6816d02	CREATE	2026-08-05 03:59:59.923807	POST /api/maintenance/b7b0c13c-2dbe-4d08-b81c-032624bfe278/confirm-slot	\N	MaintenanceRequest	162.158.193.197	POST	/api/maintenance/b7b0c13c-2dbe-4d08-b81c-032624bfe278/confirm-slot	\N	\N
9558cb35-9071-4123-950c-b93c891fd590	CREATE	2026-08-05 04:00:06.552447	POST /api/maintenance/b7b0c13c-2dbe-4d08-b81c-032624bfe278/tenant-confirm-slot	\N	MaintenanceRequest	172.70.208.107	POST	/api/maintenance/b7b0c13c-2dbe-4d08-b81c-032624bfe278/tenant-confirm-slot	\N	\N
367ca7ef-bdba-42e0-9f92-3fb2ef72fb0b	CREATE	2026-08-05 04:00:27.412171	POST /api/maintenance/b7b0c13c-2dbe-4d08-b81c-032624bfe278/tenant-confirm-slot	\N	MaintenanceRequest	172.70.93.65	POST	/api/maintenance/b7b0c13c-2dbe-4d08-b81c-032624bfe278/tenant-confirm-slot	\N	\N
bcd69a93-957f-46ed-9d42-23eb58457e4e	CREATE	2026-08-05 04:00:33.50906	POST /api/maintenance/b7b0c13c-2dbe-4d08-b81c-032624bfe278/start	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/b7b0c13c-2dbe-4d08-b81c-032624bfe278/start	\N	\N
1eae19a9-923e-4cef-9cea-85e9ebbe4263	CREATE	2026-08-05 04:00:57.018869	POST /api/maintenance/b7b0c13c-2dbe-4d08-b81c-032624bfe278/materials	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/b7b0c13c-2dbe-4d08-b81c-032624bfe278/materials	\N	\N
ce4e1c20-40b1-48a2-9005-f4a053d0d643	CREATE	2026-08-05 04:01:39.754486	POST /api/notifications/c103d022-d4ed-4b92-a3b0-5a2ff57ab35a/read	\N	Notification	172.70.208.107	POST	/api/notifications/c103d022-d4ed-4b92-a3b0-5a2ff57ab35a/read	\N	\N
af874ac7-57b6-4a80-9260-a7902c9db3f7	CREATE	2026-08-05 04:01:40.022577	POST /api/notifications/c832f24c-3516-4cab-9399-e46937d5ab0f/read	\N	Notification	172.71.218.224	POST	/api/notifications/c832f24c-3516-4cab-9399-e46937d5ab0f/read	\N	\N
4d22e20b-a553-4808-98c3-fc3692ea4eac	CREATE	2026-08-05 04:01:40.39323	POST /api/notifications/12136bbe-cbbd-46e2-9286-918e9e492dcd/read	\N	Notification	162.159.98.51	POST	/api/notifications/12136bbe-cbbd-46e2-9286-918e9e492dcd/read	\N	\N
c2e07d9e-cf49-4919-adaf-bf18bc889783	CREATE	2026-08-05 04:01:40.772463	POST /api/notifications/f58f15e0-7cf5-48cc-9fde-a4653b9e0c02/read	\N	Notification	172.71.218.224	POST	/api/notifications/f58f15e0-7cf5-48cc-9fde-a4653b9e0c02/read	\N	\N
9cd9c884-2e28-4232-9df1-9a8aaaad1801	RESOLVE	2026-08-05 04:01:44.884091	POST /api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/resolve	\N	MaintenanceRequest	162.158.114.171	POST	/api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/resolve	\N	\N
0529e85d-5026-44a3-bac6-89817e309bf3	RESOLVE	2026-08-05 04:01:46.206545	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/resolve	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/resolve	\N	\N
40e6714f-9523-4a97-a58e-045787d0ad2f	CREATE	2026-08-05 04:02:53.112022	POST /api/properties	\N	Property	162.158.114.170	POST	/api/properties	\N	\N
568b81ed-6c0e-4283-a0b4-c00b23e32f01	UPDATE	2026-08-05 04:03:26.914115	PUT /api/properties/7a85c313-7865-49a2-9631-bd02cddc8dfe	\N	Property	162.159.98.50	PUT	/api/properties/7a85c313-7865-49a2-9631-bd02cddc8dfe	\N	\N
a449ed72-c994-4439-adb5-3ce31c4feefb	DELETE	2026-08-05 04:03:44.015636	DELETE /api/properties/7a85c313-7865-49a2-9631-bd02cddc8dfe	\N	Property	172.70.93.65	DELETE	/api/properties/7a85c313-7865-49a2-9631-bd02cddc8dfe	\N	\N
c2f64cc1-47c5-4c92-8f09-96b316364b2d	CREATE	2026-08-05 04:03:59.815067	POST /api/property-types	\N	Unknown	172.70.93.65	POST	/api/property-types	\N	\N
49201014-6c92-41b4-aa25-6af9ebfb991b	UPDATE	2026-08-05 04:04:07.378325	PUT /api/property-types/7e097bd1-3108-466b-92b4-fdb92d2959f4	\N	Unknown	172.68.164.63	PUT	/api/property-types/7e097bd1-3108-466b-92b4-fdb92d2959f4	\N	\N
f38cc8e5-fe37-456b-a1e3-68cf9df65e75	CREATE	2026-08-05 04:05:21.701308	POST /api/maintenance/b7b0c13c-2dbe-4d08-b81c-032624bfe278/completion-images	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/b7b0c13c-2dbe-4d08-b81c-032624bfe278/completion-images	\N	\N
4ca19beb-b426-4e27-9e41-38b23969dda3	CREATE	2026-08-05 04:06:11.653664	POST /api/notifications/1a7678ce-d4e4-47c8-889b-76c729ef47dd/read	\N	Notification	172.70.143.168	POST	/api/notifications/1a7678ce-d4e4-47c8-889b-76c729ef47dd/read	\N	\N
626485df-65d2-4877-946a-142d25285fa1	PAYMENT	2026-08-05 04:06:21.71768	POST /api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	Invoice	172.71.215.16	POST	/api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	\N
0192d592-349e-4599-a66d-f1fdb9264ab6	RESOLVE	2026-08-05 04:07:46.932927	POST /api/maintenance/c5615cfe-4f1a-4a3f-86b1-3727c9a02d68/resolve	\N	MaintenanceRequest	172.70.208.107	POST	/api/maintenance/c5615cfe-4f1a-4a3f-86b1-3727c9a02d68/resolve	\N	\N
6b84e4d1-d6b2-45c8-a741-261caa740437	CREATE	2026-08-05 04:08:02.294393	POST /api/notifications/c54f016b-0998-4510-bc96-fcfec6ab3386/read	\N	Notification	162.158.179.49	POST	/api/notifications/c54f016b-0998-4510-bc96-fcfec6ab3386/read	\N	\N
b9926539-c1b3-4364-8d51-deda4b06cc34	CREATE	2026-08-05 04:08:02.886875	POST /api/notifications/7ee571c3-3e9f-41a2-a0b8-001ce74a28a2/read	\N	Notification	172.71.215.15	POST	/api/notifications/7ee571c3-3e9f-41a2-a0b8-001ce74a28a2/read	\N	\N
99499b0d-6c78-4f8c-8c29-fba01a4ad61f	CREATE	2026-08-05 04:16:13.032631	POST /api/notifications/771e15e8-2cf5-4625-b410-1d0608143f24/read	\N	Notification	162.158.179.49	POST	/api/notifications/771e15e8-2cf5-4625-b410-1d0608143f24/read	\N	\N
5a016059-76c7-452a-808a-0a89bf0f3cc3	CREATE	2026-08-05 04:16:16.092798	POST /api/notifications/075074ef-8808-416f-a5ac-272af7d70f14/read	\N	Notification	162.158.179.49	POST	/api/notifications/075074ef-8808-416f-a5ac-272af7d70f14/read	\N	\N
cce3150b-055b-4023-b7d6-98efc5d27ac9	CREATE	2026-08-05 04:17:10.42336	POST /api/notifications/4122b3a4-dab8-4035-aa1b-4786bd38d72e/read	\N	Notification	172.69.165.32	POST	/api/notifications/4122b3a4-dab8-4035-aa1b-4786bd38d72e/read	\N	\N
83bc7153-f2d5-4ec6-8fc1-e13dddfb709c	CREATE	2026-08-06 15:15:06.380186	POST /api/rooms/3697261c-44e6-4b47-9b9d-25277cc8da51/contracts	\N	Room	162.158.193.196	POST	/api/rooms/3697261c-44e6-4b47-9b9d-25277cc8da51/contracts	\N	\N
26707572-8448-4f4a-ba66-8bd64b364482	ASSIGN	2026-08-06 15:22:18.995461	POST /api/maintenance/229d8e58-ffbe-44d4-8909-3e92985cfe8c/assign	\N	MaintenanceRequest	172.71.81.83	POST	/api/maintenance/229d8e58-ffbe-44d4-8909-3e92985cfe8c/assign	\N	\N
90d91c2e-e14e-455c-800b-b2f83ef1076d	CREATE	2026-08-22 13:18:21.893247	POST /api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/completion-images	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/completion-images	\N	\N
f41ec2db-525e-4634-a92b-9700ade655b7	DELETE	2026-08-05 04:04:11.419002	DELETE /api/property-types/7e097bd1-3108-466b-92b4-fdb92d2959f4	\N	Unknown	172.70.93.65	DELETE	/api/property-types/7e097bd1-3108-466b-92b4-fdb92d2959f4	\N	\N
2a875b63-bd11-4ee0-b6b0-1fed093dfbee	ASSIGN	2026-08-05 04:05:59.806307	POST /api/maintenance/c5615cfe-4f1a-4a3f-86b1-3727c9a02d68/assign	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/c5615cfe-4f1a-4a3f-86b1-3727c9a02d68/assign	\N	\N
cdb2d89e-ead8-4ac5-8506-98def5b0a8dc	CREATE	2026-08-05 04:06:11.417439	POST /api/notifications/0fa8cdc1-76a2-428c-856f-fc591c9a43c9/read	\N	Notification	172.71.152.77	POST	/api/notifications/0fa8cdc1-76a2-428c-856f-fc591c9a43c9/read	\N	\N
b4e0ec41-8ad9-4607-92cb-3b130f0e9cbe	CREATE	2026-08-05 04:06:14.117952	POST /api/maintenance/c5615cfe-4f1a-4a3f-86b1-3727c9a02d68/tenant-confirm-slot	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/c5615cfe-4f1a-4a3f-86b1-3727c9a02d68/tenant-confirm-slot	\N	\N
6b109b73-ac39-4de7-a451-47b50ecd3414	PAYMENT	2026-08-05 04:06:21.997981	POST /api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	Invoice	104.23.175.246	POST	/api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	\N
ba9d206a-9b4c-4916-a943-bee594826901	CREATE	2026-08-05 04:06:46.406415	POST /api/maintenance/c5615cfe-4f1a-4a3f-86b1-3727c9a02d68/start	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/c5615cfe-4f1a-4a3f-86b1-3727c9a02d68/start	\N	\N
74ff7d8a-0970-402f-a981-524a0d83abdc	CREATE	2026-08-05 04:07:17.260779	POST /api/maintenance/c5615cfe-4f1a-4a3f-86b1-3727c9a02d68/notes	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/c5615cfe-4f1a-4a3f-86b1-3727c9a02d68/notes	\N	\N
79ca8295-5780-44aa-b57d-818aa8a573a6	CREATE	2026-08-06 15:15:20.129522	POST /api/rooms/3697261c-44e6-4b47-9b9d-25277cc8da51/meter-readings	\N	Room	172.71.218.225	POST	/api/rooms/3697261c-44e6-4b47-9b9d-25277cc8da51/meter-readings	\N	\N
08779f9c-a31d-4551-9399-7b8b27ee9858	TERMINATE	2026-08-06 15:16:21.396163	POST /api/contracts/a0dbc53e-5b77-435a-81e0-43455a3f4fff/terminate	\N	Contract	172.71.152.78	POST	/api/contracts/a0dbc53e-5b77-435a-81e0-43455a3f4fff/terminate	\N	\N
14472fe9-157c-4f7f-be6c-82a47b4153f1	CREATE	2026-08-06 15:22:10.82589	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.152.77	POST	/api/maintenance/with-images	\N	\N
7df78949-626a-467b-8f4b-308637a712e5	CREATE	2026-08-22 13:40:54.432219	POST /api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/completion-images	\N	MaintenanceRequest	172.71.215.16	POST	/api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/completion-images	\N	\N
11ac3515-3bf1-498a-bce4-3a8a3dd30127	PAYMENT	2026-08-22 13:41:15.812493	POST /api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/pay-material	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/pay-material	\N	\N
37932849-7817-45d8-950c-208af283dd48	CREATE	2026-08-22 13:42:19.53838	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.215.16	POST	/api/maintenance/with-images	\N	\N
118ba505-a3fd-4b5a-a612-ec9c1852fcbb	CREATE	2026-08-22 13:46:40.262014	POST /api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/completion-images	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/completion-images	\N	\N
4e5166e0-c06c-4286-a3d2-94f3184c1e45	CREATE	2026-08-05 04:04:22.906161	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.70.208.106	POST	/api/maintenance/with-images	\N	\N
6685f297-c9d7-4820-a9c8-e4eaa1b0a172	CREATE	2026-08-05 04:04:26.014768	POST /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms	\N	Property	172.71.218.225	POST	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms	\N	\N
7bec999d-19f9-470f-99f9-faeed993586a	CREATE	2026-08-05 04:07:30.911744	POST /api/maintenance/c5615cfe-4f1a-4a3f-86b1-3727c9a02d68/completion-images	\N	MaintenanceRequest	172.71.215.15	POST	/api/maintenance/c5615cfe-4f1a-4a3f-86b1-3727c9a02d68/completion-images	\N	\N
32522d59-1162-46ba-a2fc-995f474a649f	CREATE	2026-08-05 04:08:03.773291	POST /api/notifications/2f89a744-baaa-4ca2-b759-430e216ddc47/read	\N	Notification	172.70.208.106	POST	/api/notifications/2f89a744-baaa-4ca2-b759-430e216ddc47/read	\N	\N
92702f35-61a0-4612-bcaa-afa27a5415ce	CREATE	2026-08-05 04:08:04.026092	POST /api/notifications/09a55b42-aaac-4186-932a-db6be8e68bc4/read	\N	Notification	172.71.215.15	POST	/api/notifications/09a55b42-aaac-4186-932a-db6be8e68bc4/read	\N	\N
0ebc5930-ee03-4d34-9b97-c741a4a35c80	CREATE	2026-08-05 04:09:55.70777	POST /api/rooms/95192562-e587-4da2-bac0-46d29aa261e9/contracts	\N	Room	172.68.211.104	POST	/api/rooms/95192562-e587-4da2-bac0-46d29aa261e9/contracts	\N	\N
877dd29d-0044-4060-9eab-9af2c7965092	CREATE	2026-08-05 04:10:51.808174	POST /api/invoices/generate	\N	Invoice	162.159.98.51	POST	/api/invoices/generate	\N	\N
38dd7df4-8ccb-4cd4-8671-277818e7e37f	UPDATE	2026-08-05 04:12:32.730721	PUT /api/users/6db2e50d-7ec6-43ae-8317-7712967e02eb	\N	User	172.70.208.107	PUT	/api/users/6db2e50d-7ec6-43ae-8317-7712967e02eb	\N	\N
fb199258-1396-4c8b-b7bc-0ccf52e68aca	CREATE	2026-08-05 04:16:13.520556	POST /api/notifications/5b5c9f9f-a56b-479a-b946-f8bf4dbc3cb0/read	\N	Notification	162.158.179.49	POST	/api/notifications/5b5c9f9f-a56b-479a-b946-f8bf4dbc3cb0/read	\N	\N
f2526b29-69f4-46b6-b1be-4075eef65a4a	CREATE	2026-08-05 04:16:16.886802	POST /api/notifications/f23c279d-5935-4eaf-a469-4a43f36096f4/read	\N	Notification	162.158.179.49	POST	/api/notifications/f23c279d-5935-4eaf-a469-4a43f36096f4/read	\N	\N
9857853a-6642-4d1e-a62c-3ab790f11355	CREATE	2026-08-05 04:17:10.719099	POST /api/notifications/e4e74a6a-b9e5-4cf4-9baa-193c7da5882d/read	\N	Notification	172.70.208.106	POST	/api/notifications/e4e74a6a-b9e5-4cf4-9baa-193c7da5882d/read	\N	\N
15aab2ee-020d-4db1-aba1-8fbadd48bbd7	CREATE	2026-08-05 04:18:24.51698	POST /api/users/me/change-password	\N	User	162.159.98.51	POST	/api/users/me/change-password	\N	\N
0e416d8f-765e-4d81-a62b-d800c19c84cb	CREATE	2026-08-06 15:15:25.504982	POST /api/invoices/generate	\N	Invoice	172.68.211.104	POST	/api/invoices/generate	\N	\N
3bd39249-2228-47b5-846c-facf054c5faa	CREATE	2026-08-06 15:16:14.761844	POST /api/properties/e9a22c20-ade9-4541-9a58-f2b10a870651/rooms	\N	Property	172.71.152.78	POST	/api/properties/e9a22c20-ade9-4541-9a58-f2b10a870651/rooms	\N	\N
dbfafc49-f876-49b8-817a-f2886e63cff6	PAYMENT	2026-08-06 15:18:53.443146	POST /api/invoices/90778511-703a-4e87-be04-1223be4918c2/pay-online	\N	Invoice	172.71.81.83	POST	/api/invoices/90778511-703a-4e87-be04-1223be4918c2/pay-online	\N	\N
9d10903c-83a0-4736-bd58-3cb9f964e615	CREATE	2026-08-22 13:40:57.711492	POST /api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/submit-review	\N	MaintenanceRequest	162.158.178.147	POST	/api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/submit-review	\N	\N
cdbc77b6-6320-4c08-864f-51d5b8101bff	RESOLVE	2026-08-22 13:41:24.811622	POST /api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/resolve	\N	MaintenanceRequest	172.71.215.16	POST	/api/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/resolve	\N	\N
01e4d6c0-ce4d-4272-a413-2730bda3687b	CREATE	2026-08-22 13:43:17.627133	POST /api/maintenance/69839fb2-7b7c-41fe-9a50-431b132a54ce/completion-images	\N	MaintenanceRequest	162.158.193.197	POST	/api/maintenance/69839fb2-7b7c-41fe-9a50-431b132a54ce/completion-images	\N	\N
ff9651c4-f2ea-4f8d-bf6b-139af5c4cbb2	RESOLVE	2026-08-22 13:43:42.212392	POST /api/maintenance/69839fb2-7b7c-41fe-9a50-431b132a54ce/resolve	\N	MaintenanceRequest	162.158.193.197	POST	/api/maintenance/69839fb2-7b7c-41fe-9a50-431b132a54ce/resolve	\N	\N
13a70c46-d821-472a-9069-82669b12fc2f	CREATE	2026-08-22 13:44:05.213391	POST /api/maintenance/69839fb2-7b7c-41fe-9a50-431b132a54ce/reviews	\N	MaintenanceRequest	104.23.175.246	POST	/api/maintenance/69839fb2-7b7c-41fe-9a50-431b132a54ce/reviews	\N	\N
332a7796-eb97-4357-a743-93423b691e0c	CREATE	2026-08-22 13:46:25.746325	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/submit-review	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/submit-review	\N	\N
154d30ef-82a2-42ee-93b9-6e98f0e9cf4f	CREATE	2026-08-22 13:46:53.215323	POST /api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/submit-review	\N	MaintenanceRequest	162.158.193.196	POST	/api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/submit-review	\N	\N
c18f341c-9527-46c1-855a-c4fdc540377f	CREATE	2026-08-05 04:04:37.129798	POST /api/rooms/95192562-e587-4da2-bac0-46d29aa261e9/notes	\N	Room	172.71.215.16	POST	/api/rooms/95192562-e587-4da2-bac0-46d29aa261e9/notes	\N	\N
a40ce050-6f62-4eab-8b66-b8bdff44053a	CREATE	2026-08-05 04:05:26.995814	POST /api/maintenance/b7b0c13c-2dbe-4d08-b81c-032624bfe278/completion-images	\N	MaintenanceRequest	172.71.152.77	POST	/api/maintenance/b7b0c13c-2dbe-4d08-b81c-032624bfe278/completion-images	\N	\N
c300e685-9731-41a9-89ca-fe5b5ca99586	CREATE	2026-08-05 04:06:07.106688	POST /api/maintenance/c5615cfe-4f1a-4a3f-86b1-3727c9a02d68/confirm-slot	\N	MaintenanceRequest	172.70.208.107	POST	/api/maintenance/c5615cfe-4f1a-4a3f-86b1-3727c9a02d68/confirm-slot	\N	\N
327b5618-34ee-4efb-a0c1-dfdea4bd6fde	CREATE	2026-08-05 04:06:11.893389	POST /api/notifications/c5802495-1095-47c1-885c-1cc0e38408ed/read	\N	Notification	172.70.93.65	POST	/api/notifications/c5802495-1095-47c1-885c-1cc0e38408ed/read	\N	\N
786e6e5a-0c74-4bdd-906d-bdcf697d8059	CREATE	2026-08-05 04:06:35.847665	POST /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms	\N	Property	162.158.114.171	POST	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms	\N	\N
1ab71c5d-4ea5-49fd-9267-608ee1b18557	DELETE	2026-08-05 04:06:49.216365	DELETE /api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/419ec2fd-9e3d-46b0-9de8-d9a88fc75c37	\N	Property	172.71.215.15	DELETE	/api/properties/c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e/rooms/419ec2fd-9e3d-46b0-9de8-d9a88fc75c37	\N	\N
37feaf49-8a9d-40ca-8ffc-f6f407160c15	CREATE	2026-08-05 04:07:11.336521	POST /api/maintenance/c5615cfe-4f1a-4a3f-86b1-3727c9a02d68/materials	\N	MaintenanceRequest	172.70.208.106	POST	/api/maintenance/c5615cfe-4f1a-4a3f-86b1-3727c9a02d68/materials	\N	\N
fc6d5ff6-8726-446e-bc12-5b525fa36a9f	RESOLVE	2026-08-05 04:07:48.879625	POST /api/maintenance/c5615cfe-4f1a-4a3f-86b1-3727c9a02d68/resolve	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/c5615cfe-4f1a-4a3f-86b1-3727c9a02d68/resolve	\N	\N
59c6906b-e520-47fa-a69d-c625854d4c69	CREATE	2026-08-05 04:08:02.615248	POST /api/notifications/a0cfe4d4-09ac-4a74-81c5-c2e7554e3dbf/read	\N	Notification	162.158.179.49	POST	/api/notifications/a0cfe4d4-09ac-4a74-81c5-c2e7554e3dbf/read	\N	\N
4ee70c6a-d770-4ded-8c7e-e7d6fc462700	CREATE	2026-08-05 04:10:43.414489	POST /api/rooms/95192562-e587-4da2-bac0-46d29aa261e9/meter-readings	\N	Room	162.158.179.49	POST	/api/rooms/95192562-e587-4da2-bac0-46d29aa261e9/meter-readings	\N	\N
1f224598-98a9-41e5-9278-f64ef3610261	UPDATE	2026-08-05 04:12:25.011625	PUT /api/users/6db2e50d-7ec6-43ae-8317-7712967e02eb	\N	User	172.70.208.107	PUT	/api/users/6db2e50d-7ec6-43ae-8317-7712967e02eb	\N	\N
eb2d1bb9-796c-46d0-bbed-2fc572e644cf	UPDATE	2026-08-05 04:12:29.121263	PUT /api/users/6db2e50d-7ec6-43ae-8317-7712967e02eb	\N	User	162.158.193.196	PUT	/api/users/6db2e50d-7ec6-43ae-8317-7712967e02eb	\N	\N
2e4150ba-7741-40f2-bade-992efaf880ba	UPDATE	2026-08-05 04:12:38.632662	PUT /api/users/6db2e50d-7ec6-43ae-8317-7712967e02eb	\N	User	172.70.208.106	PUT	/api/users/6db2e50d-7ec6-43ae-8317-7712967e02eb	\N	\N
4d06f7cd-3a3e-4e8d-82c7-41a4330dae97	CREATE	2026-08-05 04:16:13.91486	POST /api/notifications/327158d3-8343-4ebc-b3c3-8618f56080ad/read	\N	Notification	172.68.164.62	POST	/api/notifications/327158d3-8343-4ebc-b3c3-8618f56080ad/read	\N	\N
2f97346e-5f12-4b7e-91bc-54a7ec687ec6	CREATE	2026-08-05 04:16:14.419116	POST /api/notifications/7b4b230f-1cb8-4dde-a1bf-76ffa6fe0103/read	\N	Notification	172.69.165.32	POST	/api/notifications/7b4b230f-1cb8-4dde-a1bf-76ffa6fe0103/read	\N	\N
ea92a0a1-2f28-459a-a52e-05e79fa23642	CREATE	2026-08-05 04:16:14.618953	POST /api/notifications/a0d2df80-b317-4432-8e09-bfe388ef8822/read	\N	Notification	162.158.114.170	POST	/api/notifications/a0d2df80-b317-4432-8e09-bfe388ef8822/read	\N	\N
fa30a624-020e-447a-8b89-94de1ebf10e6	CREATE	2026-08-05 04:16:15.2188	POST /api/notifications/2a3de72a-1030-48a4-b5db-ddc2fda3f5c6/read	\N	Notification	172.68.164.62	POST	/api/notifications/2a3de72a-1030-48a4-b5db-ddc2fda3f5c6/read	\N	\N
1fe1cac6-39d6-43eb-b615-d102489555fb	CREATE	2026-08-05 04:16:15.531373	POST /api/notifications/9ba891e8-1d01-4397-8778-69eb8420c792/read	\N	Notification	172.69.165.32	POST	/api/notifications/9ba891e8-1d01-4397-8778-69eb8420c792/read	\N	\N
62591504-e4f9-45a2-afe1-b5c9c53dfcec	CREATE	2026-08-05 04:16:17.214757	POST /api/notifications/e562228b-4db6-4404-b3fa-5e3c0dbe8f9f/read	\N	Notification	172.68.164.62	POST	/api/notifications/e562228b-4db6-4404-b3fa-5e3c0dbe8f9f/read	\N	\N
458805b4-4e12-4ce4-9f0d-80f2d0045f5b	CREATE	2026-08-05 04:16:17.659688	POST /api/notifications/60e33835-20d5-4dca-bcfa-80c40d9fea78/read	\N	Notification	172.68.164.63	POST	/api/notifications/60e33835-20d5-4dca-bcfa-80c40d9fea78/read	\N	\N
5aaa760d-ea81-472c-9056-08263af31f2b	CREATE	2026-08-05 04:16:17.863192	POST /api/notifications/e8f2ccaf-4d0b-459b-814c-d84b4789a86c/read	\N	Notification	172.69.165.32	POST	/api/notifications/e8f2ccaf-4d0b-459b-814c-d84b4789a86c/read	\N	\N
e15e08d4-728d-467f-888b-196544595c4f	CREATE	2026-08-05 04:16:18.844398	POST /api/notifications/40063ec5-263d-4495-8c9a-3265673a372d/read	\N	Notification	162.158.179.49	POST	/api/notifications/40063ec5-263d-4495-8c9a-3265673a372d/read	\N	\N
2e2acc2f-8f6f-4b90-9a04-061ddddf5054	CREATE	2026-08-05 04:21:26.976813	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.215.16	POST	/api/maintenance/with-images	\N	\N
4dd84938-5ff7-4d00-b292-5c6f50f229a4	CREATE	2026-08-05 04:21:34.628461	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.68.164.63	POST	/api/maintenance/with-images	\N	\N
97f3c9c5-2236-42a2-acd7-541086bd531c	CREATE	2026-08-05 04:21:48.333709	POST /api/maintenance/with-images	\N	MaintenanceRequest	104.23.175.247	POST	/api/maintenance/with-images	\N	\N
f9509bb0-cd6a-48df-bb6c-e4db12bd7671	CREATE	2026-08-05 04:22:10.327877	POST /api/maintenance/with-images	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/with-images	\N	\N
545eae10-d391-4303-835c-b29e2de5e0d6	ASSIGN	2026-08-05 04:23:44.014915	POST /api/maintenance/05c52caf-2ab3-4473-8fcd-170dc1849e0c/assign	\N	MaintenanceRequest	162.158.193.196	POST	/api/maintenance/05c52caf-2ab3-4473-8fcd-170dc1849e0c/assign	\N	\N
e40948db-7c42-45e4-8ace-d3c84023079d	ASSIGN	2026-08-05 04:23:50.151729	POST /api/maintenance/05c52caf-2ab3-4473-8fcd-170dc1849e0c/assign	\N	MaintenanceRequest	172.68.164.63	POST	/api/maintenance/05c52caf-2ab3-4473-8fcd-170dc1849e0c/assign	\N	\N
a3b39fff-8b4c-4953-975b-9cdc10d003bc	CREATE	2026-08-05 04:24:12.921424	POST /api/maintenance/05c52caf-2ab3-4473-8fcd-170dc1849e0c/cancel	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/05c52caf-2ab3-4473-8fcd-170dc1849e0c/cancel	\N	\N
cb0e6aa4-edd6-42db-840d-51cb0e3ef50c	CREATE	2026-08-05 04:25:33.627749	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.70.208.107	POST	/api/maintenance/with-images	\N	\N
30100c9d-65e4-419b-985c-d8e3ae318b35	ASSIGN	2026-08-05 04:30:30.309117	POST /api/maintenance/60dab198-f686-47d1-9656-6b7314fbeae3/assign	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/60dab198-f686-47d1-9656-6b7314fbeae3/assign	\N	\N
b3e0a01b-abd0-400e-b458-46a36c5cd72f	CREATE	2026-08-05 04:30:47.442407	POST /api/maintenance/60dab198-f686-47d1-9656-6b7314fbeae3/start	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/60dab198-f686-47d1-9656-6b7314fbeae3/start	\N	\N
db8576d4-0f13-46a2-ae6c-0f49212b9b8b	CREATE	2026-08-05 04:31:00.002203	POST /api/notifications/2cf5ebe5-f158-4ba6-82ba-a7ceaef96be2/read	\N	Notification	162.158.162.76	POST	/api/notifications/2cf5ebe5-f158-4ba6-82ba-a7ceaef96be2/read	\N	\N
2a1e980c-451d-4dbe-9244-c6172185621a	CREATE	2026-08-05 04:31:00.446433	POST /api/notifications/aeb2c238-b20f-4e7c-b015-a9a21bac3f79/read	\N	Notification	172.70.208.107	POST	/api/notifications/aeb2c238-b20f-4e7c-b015-a9a21bac3f79/read	\N	\N
53a90bfe-7691-4ef1-aafa-3bb6c7394ba2	CREATE	2026-08-05 04:31:00.775253	POST /api/notifications/7c3f1295-0ed6-4bfe-bea5-5d035057cfa3/read	\N	Notification	172.71.218.225	POST	/api/notifications/7c3f1295-0ed6-4bfe-bea5-5d035057cfa3/read	\N	\N
2787724f-9453-468f-ae0f-db67c8b3c800	CREATE	2026-08-05 04:31:01.106487	POST /api/notifications/924bd9ef-0c05-4dc7-9a61-ba273cca04ac/read	\N	Notification	172.70.93.65	POST	/api/notifications/924bd9ef-0c05-4dc7-9a61-ba273cca04ac/read	\N	\N
238ff83a-c3fe-4cba-b7e9-a0e9f6ee4cce	CREATE	2026-08-05 04:31:01.481469	POST /api/notifications/b27b3e43-e880-4767-8db1-9d5d458d1e16/read	\N	Notification	162.158.179.49	POST	/api/notifications/b27b3e43-e880-4767-8db1-9d5d458d1e16/read	\N	\N
950f974b-79f2-46e3-bb34-79228cffcd92	CREATE	2026-08-05 04:33:53.724473	POST /api/maintenance/60dab198-f686-47d1-9656-6b7314fbeae3/completion-images	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/60dab198-f686-47d1-9656-6b7314fbeae3/completion-images	\N	\N
ffc39c96-2f6e-47d9-8c73-9b048503d30a	DELETE	2026-08-05 04:35:35.906749	DELETE /api/maintenance/60dab198-f686-47d1-9656-6b7314fbeae3/materials/7f02e183-4af5-49fa-b625-188f8f64ccb4	\N	MaintenanceRequest	172.71.215.15	DELETE	/api/maintenance/60dab198-f686-47d1-9656-6b7314fbeae3/materials/7f02e183-4af5-49fa-b625-188f8f64ccb4	\N	\N
26ac977f-d87f-4603-80b8-e18bc2e8a449	CREATE	2026-08-05 04:36:12.456876	POST /api/maintenance/60dab198-f686-47d1-9656-6b7314fbeae3/notes	\N	MaintenanceRequest	162.159.98.51	POST	/api/maintenance/60dab198-f686-47d1-9656-6b7314fbeae3/notes	\N	\N
a0b895ce-170a-4d9a-973c-d92a350d910a	CREATE	2026-08-05 04:36:19.537368	POST /api/notifications/571bc652-f0a3-4b86-8b8c-6ae6ae8fc656/read	\N	Notification	172.70.208.107	POST	/api/notifications/571bc652-f0a3-4b86-8b8c-6ae6ae8fc656/read	\N	\N
721e1e63-0b35-4f4d-aa6b-ea5039775703	CREATE	2026-08-05 04:36:21.804412	POST /api/notifications/fe20b9dc-1cc5-413d-96ed-ef1d2fa3e6a1/read	\N	Notification	172.71.218.225	POST	/api/notifications/fe20b9dc-1cc5-413d-96ed-ef1d2fa3e6a1/read	\N	\N
973a63db-fb40-4e50-ab81-b59aff948ec7	TERMINATE	2026-08-05 04:37:11.210364	POST /api/contracts/6e6f011b-8790-473c-a38c-7157ba2c5f44/terminate	\N	Contract	162.159.98.50	POST	/api/contracts/6e6f011b-8790-473c-a38c-7157ba2c5f44/terminate	\N	\N
5072eee4-baf4-48de-b17f-95cab16fb7e5	CREATE	2026-08-05 04:38:32.110896	POST /api/users/me/change-password	\N	User	172.70.208.106	POST	/api/users/me/change-password	\N	\N
68f2bb15-32d2-4dfd-b7f0-c36ec9d725d3	CREATE	2026-08-05 04:38:52.825012	POST /api/users/me/change-password	\N	User	162.158.114.171	POST	/api/users/me/change-password	\N	\N
a3d0765a-4fff-448e-a6aa-7ac672870aed	CREATE	2026-08-06 15:34:49.621375	POST /api/maintenance/229d8e58-ffbe-44d4-8909-3e92985cfe8c/tenant-confirm-slot	\N	MaintenanceRequest	172.71.152.78	POST	/api/maintenance/229d8e58-ffbe-44d4-8909-3e92985cfe8c/tenant-confirm-slot	\N	\N
5db98615-73a0-4df7-a737-ba999cda35aa	ASSIGN	2026-08-22 13:42:40.514759	POST /api/maintenance/69839fb2-7b7c-41fe-9a50-431b132a54ce/assign	\N	MaintenanceRequest	172.71.215.16	POST	/api/maintenance/69839fb2-7b7c-41fe-9a50-431b132a54ce/assign	\N	\N
88da8592-029c-46d7-883f-417e771cfea8	CREATE	2026-08-22 13:42:51.443655	POST /api/maintenance/69839fb2-7b7c-41fe-9a50-431b132a54ce/confirm-slot	\N	MaintenanceRequest	172.71.215.16	POST	/api/maintenance/69839fb2-7b7c-41fe-9a50-431b132a54ce/confirm-slot	\N	\N
f9775363-e09b-44a5-a130-bfed39c98bba	CREATE	2026-08-22 13:43:29.113253	POST /api/maintenance/69839fb2-7b7c-41fe-9a50-431b132a54ce/completion-images	\N	MaintenanceRequest	162.158.193.197	POST	/api/maintenance/69839fb2-7b7c-41fe-9a50-431b132a54ce/completion-images	\N	\N
12454b0e-a8b6-423d-9f92-7c1c96b9f120	CREATE	2026-08-05 04:33:39.962713	POST /api/maintenance/60dab198-f686-47d1-9656-6b7314fbeae3/completion-images	\N	MaintenanceRequest	172.68.164.63	POST	/api/maintenance/60dab198-f686-47d1-9656-6b7314fbeae3/completion-images	\N	\N
d3b45b3d-1092-4e70-84d7-cd59b3ed1484	CREATE	2026-08-05 04:35:33.611064	POST /api/maintenance/60dab198-f686-47d1-9656-6b7314fbeae3/materials	\N	MaintenanceRequest	172.69.165.32	POST	/api/maintenance/60dab198-f686-47d1-9656-6b7314fbeae3/materials	\N	\N
b2afe767-eaac-4dee-8e82-b87dc4d1fe38	CREATE	2026-08-05 04:35:45.910674	POST /api/maintenance/60dab198-f686-47d1-9656-6b7314fbeae3/materials	\N	MaintenanceRequest	162.158.114.170	POST	/api/maintenance/60dab198-f686-47d1-9656-6b7314fbeae3/materials	\N	\N
f50641ab-9e6c-4cf7-8417-2e8cb482debe	CREATE	2026-08-05 04:36:19.835163	POST /api/notifications/46513d35-25e3-4553-a0c5-35f1da0684df/read	\N	Notification	172.70.93.65	POST	/api/notifications/46513d35-25e3-4553-a0c5-35f1da0684df/read	\N	\N
4ddd50d1-36d0-42b6-910a-9416e0064a13	CREATE	2026-08-05 04:37:39.603569	POST /api/notifications/045fd9f2-0f2e-40d6-8350-c17fad93946b/read	\N	Notification	172.71.215.15	POST	/api/notifications/045fd9f2-0f2e-40d6-8350-c17fad93946b/read	\N	\N
218dd1a5-4fe9-4936-8416-48272b20a1b8	CREATE	2026-08-05 04:37:39.934146	POST /api/notifications/29915c3b-3e50-42f6-9956-73b7376b7019/read	\N	Notification	172.70.208.106	POST	/api/notifications/29915c3b-3e50-42f6-9956-73b7376b7019/read	\N	\N
33f8f091-cb39-489f-bb2d-e87fbb2d674e	CREATE	2026-08-05 04:37:40.195949	POST /api/notifications/c3c163f0-f8aa-40d6-8020-ba8533c777e5/read	\N	Notification	172.70.208.107	POST	/api/notifications/c3c163f0-f8aa-40d6-8020-ba8533c777e5/read	\N	\N
92db82fd-c33c-45a1-8bc5-f43d82f295b2	CREATE	2026-08-05 04:37:40.50483	POST /api/notifications/238a30cd-9a4e-49b5-900c-3a5a97d6cbbd/read	\N	Notification	104.23.175.247	POST	/api/notifications/238a30cd-9a4e-49b5-900c-3a5a97d6cbbd/read	\N	\N
0b548506-2e96-4226-a741-d7d0dda9c027	CREATE	2026-08-05 04:39:45.429546	POST /api/users/me/change-password	\N	User	104.23.175.246	POST	/api/users/me/change-password	\N	\N
22125204-8602-40e4-a1d9-3b0df0d4fa41	CREATE	2026-08-05 04:40:55.83068	POST /api/notifications/6cdfab36-3303-4286-80a9-97ceb82785fe/read	\N	Notification	172.70.208.107	POST	/api/notifications/6cdfab36-3303-4286-80a9-97ceb82785fe/read	\N	\N
fc009ff5-d40e-4eb7-afe5-2023b5c2c9be	PAYMENT	2026-08-05 04:41:02.463676	POST /api/invoices/f3b06edb-008c-4358-b278-d76c46356885/pay-online	\N	Invoice	172.70.208.107	POST	/api/invoices/f3b06edb-008c-4358-b278-d76c46356885/pay-online	\N	\N
be16fa94-75f4-474d-9b6a-c9f3ffbcc96e	PAYMENT	2026-08-05 04:41:02.944788	POST /api/invoices/f3b06edb-008c-4358-b278-d76c46356885/pay-online	\N	Invoice	172.68.211.104	POST	/api/invoices/f3b06edb-008c-4358-b278-d76c46356885/pay-online	\N	\N
ab0b0ae9-e9f2-450a-ba03-9fe796dc51d5	CREATE	2026-08-05 04:42:20.821816	POST /api/invoices/f3b06edb-008c-4358-b278-d76c46356885/request-cash	\N	Invoice	162.158.193.196	POST	/api/invoices/f3b06edb-008c-4358-b278-d76c46356885/request-cash	\N	\N
2b8c6173-61b0-46c7-b808-4f48708d9ff3	PAYMENT	2026-08-05 04:42:45.515121	POST /api/invoices/f3b06edb-008c-4358-b278-d76c46356885/pay-cash	\N	Invoice	172.70.208.107	POST	/api/invoices/f3b06edb-008c-4358-b278-d76c46356885/pay-cash	\N	\N
5ae470ce-ef55-48d3-bc0f-a7061ab0060f	PAYMENT	2026-08-05 04:42:45.780428	POST /api/invoices/f3b06edb-008c-4358-b278-d76c46356885/pay-cash	\N	Invoice	162.159.98.51	POST	/api/invoices/f3b06edb-008c-4358-b278-d76c46356885/pay-cash	\N	\N
118ae8f4-c382-4c41-b629-42aa9f317719	CREATE	2026-08-05 05:38:57.406637	POST /api/properties	\N	Property	172.69.176.63	POST	/api/properties	\N	\N
e5e0089d-32c2-4cda-a20b-ff418238c035	DELETE	2026-08-05 05:39:00.968254	DELETE /api/properties/77125651-46e9-4b35-922f-62a156d2c4e4	\N	Property	162.158.193.196	DELETE	/api/properties/77125651-46e9-4b35-922f-62a156d2c4e4	\N	\N
26215d9a-819b-4a91-8640-d4c91b794548	CREATE	2026-08-05 05:39:31.831409	POST /api/properties	\N	Property	162.159.98.51	POST	/api/properties	\N	\N
7d21dd2d-e675-47e0-a4f8-a61618d65e2f	CREATE	2026-08-05 05:44:17.226324	POST /api/properties/e9a22c20-ade9-4541-9a58-f2b10a870651/rooms	\N	Property	162.159.98.50	POST	/api/properties/e9a22c20-ade9-4541-9a58-f2b10a870651/rooms	\N	\N
5ae058ac-d719-4744-98c8-46268be20504	CREATE	2026-08-05 05:45:12.011126	POST /api/rooms/e3d6477b-41ee-4b21-af42-6a9f042e6d08/contracts	\N	Room	172.68.164.62	POST	/api/rooms/e3d6477b-41ee-4b21-af42-6a9f042e6d08/contracts	\N	\N
c7b991aa-611c-4529-8f83-d0f95098eddf	CREATE	2026-08-05 05:46:12.305138	POST /api/rooms/e3d6477b-41ee-4b21-af42-6a9f042e6d08/meter-readings	\N	Room	172.68.164.62	POST	/api/rooms/e3d6477b-41ee-4b21-af42-6a9f042e6d08/meter-readings	\N	\N
defd2bc8-d1e3-4cc1-b0c2-d9ec6a6bb397	CREATE	2026-08-05 05:46:18.912704	POST /api/invoices/generate	\N	Invoice	172.71.215.16	POST	/api/invoices/generate	\N	\N
4e9eb32d-e037-4778-9df5-1e3902236e5a	CREATE	2026-08-05 05:47:17.919171	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
bdd2dd2c-077f-4f30-883a-cfe0fffe7389	CREATE	2026-08-05 05:47:36.391573	POST /api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	MaintenanceRequest	172.71.215.16	POST	/api/maintenance/2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9/completion-images	\N	\N
2d96613a-9ccd-44dc-9e78-1d3cc514a711	CREATE	2026-08-05 05:48:08.826641	POST /api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	MaintenanceRequest	162.158.114.171	POST	/api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	\N
eff67c83-6e42-4856-8220-13bd1f1be07b	CREATE	2026-08-05 05:48:14.113965	POST /api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	MaintenanceRequest	172.71.152.78	POST	/api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	\N
927356fd-2054-4717-985d-530c1f39c51b	CREATE	2026-08-05 05:50:10.37071	POST /api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	MaintenanceRequest	162.158.114.171	POST	/api/maintenance/babc7312-1c6f-4670-8297-351d392a1996/completion-images	\N	\N
81f565ad-6a95-4c40-b191-8291329b8048	PAYMENT	2026-08-05 05:54:18.51737	POST /api/invoices/f1b6bd6a-59bf-442c-92f9-1a90b2ab8a31/pay-online	\N	Invoice	172.68.211.104	POST	/api/invoices/f1b6bd6a-59bf-442c-92f9-1a90b2ab8a31/pay-online	\N	\N
894c2163-2290-4305-b08e-7e70433bd198	PAYMENT	2026-08-05 05:54:19.133881	POST /api/invoices/f1b6bd6a-59bf-442c-92f9-1a90b2ab8a31/pay-online	\N	Invoice	172.71.152.77	POST	/api/invoices/f1b6bd6a-59bf-442c-92f9-1a90b2ab8a31/pay-online	\N	\N
c94d89a6-c581-40f8-89d7-d1f32fc5b0b5	CREATE	2026-08-05 05:54:31.239167	POST /api/invoices/f1b6bd6a-59bf-442c-92f9-1a90b2ab8a31/request-cash	\N	Invoice	172.68.164.63	POST	/api/invoices/f1b6bd6a-59bf-442c-92f9-1a90b2ab8a31/request-cash	\N	\N
42976c9e-9171-4beb-9b7b-33f9ffea99ed	PAYMENT	2026-08-05 05:54:39.930486	POST /api/invoices/f1b6bd6a-59bf-442c-92f9-1a90b2ab8a31/pay-cash	\N	Invoice	172.71.218.225	POST	/api/invoices/f1b6bd6a-59bf-442c-92f9-1a90b2ab8a31/pay-cash	\N	\N
8d72ae25-8ab5-4d12-aab0-ef2bccad656a	PAYMENT	2026-08-05 05:54:40.462421	POST /api/invoices/f1b6bd6a-59bf-442c-92f9-1a90b2ab8a31/pay-cash	\N	Invoice	162.159.98.50	POST	/api/invoices/f1b6bd6a-59bf-442c-92f9-1a90b2ab8a31/pay-cash	\N	\N
1e64a7a3-759b-494e-8134-36298a93f99b	CREATE	2026-08-05 05:56:09.429633	POST /api/users/me/change-password	\N	User	162.158.179.49	POST	/api/users/me/change-password	\N	\N
129f2085-aa7b-45ee-b920-52b07a2f8bd4	CREATE	2026-08-05 05:57:13.519989	POST /api/users	\N	User	104.23.175.247	POST	/api/users	\N	\N
29c23713-0fd1-4093-b0b1-202b4fb7fab2	CREATE	2026-08-05 05:57:42.31056	POST /api/properties/e9a22c20-ade9-4541-9a58-f2b10a870651/rooms	\N	Property	172.71.152.78	POST	/api/properties/e9a22c20-ade9-4541-9a58-f2b10a870651/rooms	\N	\N
fdcfd906-4283-4b2e-883b-5cc77b5371cd	CREATE	2026-08-05 06:00:54.006938	POST /api/rooms/b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6/contracts	\N	Room	162.158.193.197	POST	/api/rooms/b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6/contracts	\N	\N
9136b68d-4aa8-46f4-8000-63e43cc7347b	CREATE	2026-08-05 06:01:35.213571	POST /api/rooms/b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6/meter-readings	\N	Room	172.71.215.15	POST	/api/rooms/b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6/meter-readings	\N	\N
70d5f672-789a-4804-b601-22aa53018f7d	CREATE	2026-08-05 06:03:23.011068	POST /api/maintenance/with-images	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/with-images	\N	\N
32538f4d-742c-4443-a99b-e57c1300661f	CREATE	2026-08-05 06:09:30.217113	POST /api/invoices/95fa58e3-2f13-410b-80c7-159fec6186f9/request-cash	\N	Invoice	172.68.164.63	POST	/api/invoices/95fa58e3-2f13-410b-80c7-159fec6186f9/request-cash	\N	\N
1e5c6bed-f3d5-4312-8f7b-480502299256	PAYMENT	2026-08-05 06:09:33.500512	POST /api/invoices/95fa58e3-2f13-410b-80c7-159fec6186f9/pay-online	\N	Invoice	162.158.179.50	POST	/api/invoices/95fa58e3-2f13-410b-80c7-159fec6186f9/pay-online	\N	\N
156d856a-32fd-46b7-9106-fd146cbe4989	PAYMENT	2026-08-05 06:09:34.124843	POST /api/invoices/95fa58e3-2f13-410b-80c7-159fec6186f9/pay-online	\N	Invoice	162.159.98.50	POST	/api/invoices/95fa58e3-2f13-410b-80c7-159fec6186f9/pay-online	\N	\N
5aa0c4df-6152-483f-9229-7e448e6e184e	CREATE	2026-08-06 15:38:46.538949	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.152.78	POST	/api/maintenance/with-images	\N	\N
1832bccf-4491-4039-bbe4-42ec16f96f84	CREATE	2026-08-22 13:42:54.511944	POST /api/maintenance/69839fb2-7b7c-41fe-9a50-431b132a54ce/tenant-confirm-slot	\N	MaintenanceRequest	162.158.193.197	POST	/api/maintenance/69839fb2-7b7c-41fe-9a50-431b132a54ce/tenant-confirm-slot	\N	\N
ea30078f-588f-464b-aa54-66f575564486	CREATE	2026-08-22 13:42:58.81219	POST /api/maintenance/69839fb2-7b7c-41fe-9a50-431b132a54ce/start	\N	MaintenanceRequest	104.23.175.246	POST	/api/maintenance/69839fb2-7b7c-41fe-9a50-431b132a54ce/start	\N	\N
83c9eb48-adfe-4def-a8f9-5c1dcb368be2	CREATE	2026-08-22 13:43:34.823188	POST /api/maintenance/69839fb2-7b7c-41fe-9a50-431b132a54ce/submit-review	\N	MaintenanceRequest	162.158.178.146	POST	/api/maintenance/69839fb2-7b7c-41fe-9a50-431b132a54ce/submit-review	\N	\N
b472f7ce-6377-4a4d-8318-964fbf55723c	CREATE	2026-08-22 13:46:45.722957	POST /api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/submit-review	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/submit-review	\N	\N
2b61b2f3-2887-468a-b2f1-551e2b246510	CREATE	2026-08-05 06:03:31.448789	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.68.164.62	POST	/api/maintenance/with-images	\N	\N
4ede9f27-27dc-4da8-9cc4-fdc4a7aa4ac7	UPDATE	2026-08-05 06:04:39.031991	PUT /api/properties/e9a22c20-ade9-4541-9a58-f2b10a870651/fee-config	\N	Property	162.158.114.170	PUT	/api/properties/e9a22c20-ade9-4541-9a58-f2b10a870651/fee-config	\N	\N
e3fda01c-b769-467a-aa72-d4eb7dbf741f	ASSIGN	2026-08-05 06:22:20.411319	POST /api/maintenance/483e9cdc-246b-48a5-9a8f-2327910f2b03/assign	\N	MaintenanceRequest	172.69.165.32	POST	/api/maintenance/483e9cdc-246b-48a5-9a8f-2327910f2b03/assign	\N	\N
84ddc58d-6e0f-4d7d-b5c6-27587f5e57de	CREATE	2026-08-05 06:22:47.208536	POST /api/maintenance/10ce7228-811a-4908-a24a-6061f278cc7b/cancel	\N	MaintenanceRequest	104.23.175.246	POST	/api/maintenance/10ce7228-811a-4908-a24a-6061f278cc7b/cancel	\N	\N
cf254c5c-3c59-4fd8-a8d1-e3048d3bf12a	CREATE	2026-08-05 06:23:04.244027	POST /api/notifications/aaed81c0-48ef-4055-9f26-9c218bb6a67c/read	\N	Notification	172.68.164.63	POST	/api/notifications/aaed81c0-48ef-4055-9f26-9c218bb6a67c/read	\N	\N
f910978c-92c1-49c5-985d-a15892e7fbfb	CREATE	2026-08-05 06:26:30.206978	POST /api/maintenance/483e9cdc-246b-48a5-9a8f-2327910f2b03/start	\N	MaintenanceRequest	172.68.164.63	POST	/api/maintenance/483e9cdc-246b-48a5-9a8f-2327910f2b03/start	\N	\N
b480af6b-b7eb-4e92-8d4e-2781733db17b	CREATE	2026-08-05 06:26:47.725728	POST /api/maintenance/483e9cdc-246b-48a5-9a8f-2327910f2b03/materials	\N	MaintenanceRequest	162.158.114.171	POST	/api/maintenance/483e9cdc-246b-48a5-9a8f-2327910f2b03/materials	\N	\N
cd2ea222-b244-466c-8a3a-4670aed17945	CREATE	2026-08-05 06:27:15.786323	POST /api/maintenance/483e9cdc-246b-48a5-9a8f-2327910f2b03/notes	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/483e9cdc-246b-48a5-9a8f-2327910f2b03/notes	\N	\N
91c6c69b-09fa-4ac0-a77d-b38c363fd57a	CREATE	2026-08-05 06:27:58.324658	POST /api/maintenance/483e9cdc-246b-48a5-9a8f-2327910f2b03/completion-images	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/483e9cdc-246b-48a5-9a8f-2327910f2b03/completion-images	\N	\N
afbe253c-1aec-4994-ad83-5887269c43f0	CREATE	2026-08-05 06:29:08.918425	POST /api/maintenance/b8000000-0000-0000-0000-000000000001/confirm-slot	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/b8000000-0000-0000-0000-000000000001/confirm-slot	\N	\N
b3cf149b-6181-447c-8162-5f0fd0658381	CREATE	2026-08-05 06:30:07.243739	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/with-images	\N	\N
b047382a-162b-45b2-a613-ae75e88ff007	ASSIGN	2026-08-05 06:30:26.208909	POST /api/maintenance/2f6bcc81-68a7-46e1-b7b8-f98bf267fe53/assign	\N	MaintenanceRequest	162.158.179.49	POST	/api/maintenance/2f6bcc81-68a7-46e1-b7b8-f98bf267fe53/assign	\N	\N
2e1af6bc-e0b6-48d4-a479-109017114795	CREATE	2026-08-05 07:23:40.219736	POST /api/notifications/1358c027-5306-45d5-9ff4-2970132566d9/read	\N	Notification	162.159.98.50	POST	/api/notifications/1358c027-5306-45d5-9ff4-2970132566d9/read	\N	\N
6dfdbb89-0c84-4594-b24c-67cea57ec2ad	CREATE	2026-08-05 07:23:40.425097	POST /api/notifications/09a2b857-5a43-42fb-b840-806f6f69be20/read	\N	Notification	172.70.208.107	POST	/api/notifications/09a2b857-5a43-42fb-b840-806f6f69be20/read	\N	\N
13a261f3-0acc-4ba2-bb50-8e50c3d98b14	CREATE	2026-08-05 07:25:27.408832	POST /api/maintenance/c5e0255e-0794-408f-9677-5db981f2d32f/start	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/c5e0255e-0794-408f-9677-5db981f2d32f/start	\N	\N
4bed2df9-07de-42c4-a8a3-f9f3a59d7382	CREATE	2026-08-05 07:41:31.306272	POST /api/rooms/b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6/meter-readings	\N	Room	162.158.179.50	POST	/api/rooms/b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6/meter-readings	\N	\N
9f86026f-dd6b-4ce2-95ad-d6e919c37be9	CREATE	2026-08-05 07:41:38.907162	POST /api/invoices/generate	\N	Invoice	172.70.208.106	POST	/api/invoices/generate	\N	\N
3bb573c7-c776-4877-b191-9b84ac7c99db	CREATE	2026-08-05 07:41:45.109747	POST /api/invoices/generate	\N	Invoice	162.158.114.170	POST	/api/invoices/generate	\N	\N
d8bf31e6-009c-4414-b907-7f875ebbaf41	CREATE	2026-08-05 07:41:47.710541	POST /api/invoices/generate	\N	Invoice	172.68.211.105	POST	/api/invoices/generate	\N	\N
79a8c2de-6e1f-4390-8cb4-c15a776b311d	CREATE	2026-08-05 07:42:04.710186	POST /api/rooms/b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6/meter-readings	\N	Room	162.158.193.197	POST	/api/rooms/b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6/meter-readings	\N	\N
33c0ba7b-7971-49d3-8a5f-3ec83d143686	CREATE	2026-08-05 07:42:07.706161	POST /api/invoices/generate	\N	Invoice	162.159.98.50	POST	/api/invoices/generate	\N	\N
ba44d23e-56f5-4d34-9470-25fa1c12409a	CREATE	2026-08-05 07:42:22.707149	POST /api/rooms/e3d6477b-41ee-4b21-af42-6a9f042e6d08/meter-readings	\N	Room	162.158.193.196	POST	/api/rooms/e3d6477b-41ee-4b21-af42-6a9f042e6d08/meter-readings	\N	\N
b2310f51-5973-4715-b670-d726cbc11255	CREATE	2026-08-05 07:42:27.162402	POST /api/invoices/generate	\N	Invoice	162.159.98.50	POST	/api/invoices/generate	\N	\N
d22c3fc0-fb59-41db-bb65-f08d3d2a3e17	CREATE	2026-08-05 07:42:36.817694	POST /api/invoices/generate	\N	Invoice	172.70.208.107	POST	/api/invoices/generate	\N	\N
b73f1410-cfbc-4b1f-be4c-c53bd33bb4af	CREATE	2026-08-05 07:42:39.911403	POST /api/invoices/generate	\N	Invoice	172.71.218.224	POST	/api/invoices/generate	\N	\N
adcedd97-37d4-4ce4-941d-d669fa877bd5	CREATE	2026-08-05 07:43:05.050489	POST /api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	Room	172.68.164.63	POST	/api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	\N
797c2b65-80bf-4705-b76c-216312530d01	CREATE	2026-08-05 07:43:08.825102	POST /api/invoices/generate	\N	Invoice	172.71.81.83	POST	/api/invoices/generate	\N	\N
09713801-a7c0-4a2e-acc3-86f626b65ef0	CREATE	2026-08-05 07:43:13.418882	POST /api/invoices/generate	\N	Invoice	104.23.175.247	POST	/api/invoices/generate	\N	\N
6110c749-b776-432c-8004-0f64e3155478	CREATE	2026-08-05 07:43:19.13082	POST /api/invoices/generate	\N	Invoice	162.158.193.196	POST	/api/invoices/generate	\N	\N
944e627c-2ade-4bc9-8ed0-5f894a4d3325	CREATE	2026-08-05 07:43:21.026067	POST /api/invoices/generate	\N	Invoice	162.158.193.197	POST	/api/invoices/generate	\N	\N
def2c57b-9bd4-4b90-9e23-40d874d84f11	CREATE	2026-08-05 07:43:23.02216	POST /api/invoices/generate	\N	Invoice	172.70.208.107	POST	/api/invoices/generate	\N	\N
1e204283-9a42-4e73-8733-e6fe7dae0d1c	CREATE	2026-08-05 07:43:37.111128	POST /api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	Room	172.68.211.104	POST	/api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	\N
29bee1f5-0505-467b-a3e3-50c9e2f2a3f3	CREATE	2026-08-05 07:43:40.912269	POST /api/invoices/generate	\N	Invoice	172.68.211.105	POST	/api/invoices/generate	\N	\N
e6ba3d7a-2e35-41a8-9330-5a5354bd53c4	CREATE	2026-08-05 07:43:47.306845	POST /api/invoices/generate	\N	Invoice	162.159.98.50	POST	/api/invoices/generate	\N	\N
540eda00-337a-4b71-b166-8a6877302fa2	CREATE	2026-08-05 07:43:49.326072	POST /api/invoices/generate	\N	Invoice	162.158.193.196	POST	/api/invoices/generate	\N	\N
146f20a7-c03f-4c28-8131-4331c4fbba07	CREATE	2026-08-05 07:44:02.98856	POST /api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	Room	162.158.193.196	POST	/api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	\N
95079908-67cd-49a5-8f4b-254eab051797	CREATE	2026-08-05 07:44:07.522762	POST /api/invoices/generate	\N	Invoice	104.23.175.246	POST	/api/invoices/generate	\N	\N
b92aa094-32f0-4ad3-8a66-7d503a2707b3	CREATE	2026-08-05 07:44:09.032961	POST /api/invoices/generate	\N	Invoice	104.23.175.247	POST	/api/invoices/generate	\N	\N
c71a1a20-5b40-4562-9539-683203bbfbb2	CREATE	2026-08-05 07:44:29.33926	POST /api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	Room	172.68.164.62	POST	/api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	\N
3af880fc-bfdc-4e93-93a8-6e8c9144242d	CREATE	2026-08-05 07:44:33.751948	POST /api/invoices/generate	\N	Invoice	104.23.175.247	POST	/api/invoices/generate	\N	\N
93faeaa9-4ebc-437a-ae0d-7e4b3e4e6f8e	CREATE	2026-08-05 07:44:36.328522	POST /api/invoices/generate	\N	Invoice	104.23.175.247	POST	/api/invoices/generate	\N	\N
e3236b6b-789f-437d-be54-26d71a4945f7	CREATE	2026-08-05 07:44:49.208875	POST /api/rooms/b5000000-0000-0000-0000-000000000017/meter-readings	\N	Room	104.23.175.247	POST	/api/rooms/b5000000-0000-0000-0000-000000000017/meter-readings	\N	\N
10a5f178-1aa9-4d96-b6dc-245e87de7239	CREATE	2026-08-05 07:44:53.207039	POST /api/invoices/generate	\N	Invoice	162.158.179.50	POST	/api/invoices/generate	\N	\N
3dce0882-e68f-468f-ae70-5527a3aa5408	CREATE	2026-08-05 07:46:49.410467	POST /api/invoices/generate	\N	Invoice	172.68.211.104	POST	/api/invoices/generate	\N	\N
6dc12e81-361c-430d-a994-a1b9db529921	CREATE	2026-08-05 07:48:46.532419	POST /api/invoices/generate	\N	Invoice	104.23.175.246	POST	/api/invoices/generate	\N	\N
3945b93d-f714-4ce2-aa2c-241438595f02	CREATE	2026-08-05 07:48:48.050031	POST /api/invoices/generate	\N	Invoice	162.158.179.49	POST	/api/invoices/generate	\N	\N
19b31e75-8868-4998-a56c-f24ca0711c48	CREATE	2026-08-06 15:40:23.861293	POST /api/maintenance/483e9cdc-246b-48a5-9a8f-2327910f2b03/completion-images	\N	MaintenanceRequest	172.71.81.83	POST	/api/maintenance/483e9cdc-246b-48a5-9a8f-2327910f2b03/completion-images	\N	\N
a224eaac-3d3d-4aaa-9f1d-7f43fb087d7c	CREATE	2026-08-06 15:41:36.641253	POST /api/notifications/4154eac8-a970-41cc-8b28-51ee34314984/read	\N	Notification	172.71.218.224	POST	/api/notifications/4154eac8-a970-41cc-8b28-51ee34314984/read	\N	\N
08cf7009-6294-4bcf-bbab-ac9fe1d47ef8	CREATE	2026-08-06 15:41:37.482143	POST /api/notifications/28ce2088-8e50-4286-8a2c-5da0ed90b234/read	\N	Notification	172.71.152.77	POST	/api/notifications/28ce2088-8e50-4286-8a2c-5da0ed90b234/read	\N	\N
fb22c7c5-af4b-4fa6-b6c2-bc0771e9c0d8	CREATE	2026-08-06 15:41:38.158949	POST /api/notifications/e1089bf0-0a1d-4038-a01d-14239aa18059/read	\N	Notification	172.71.81.83	POST	/api/notifications/e1089bf0-0a1d-4038-a01d-14239aa18059/read	\N	\N
cb53526d-ceb5-4e49-9c2f-23569cb0c543	CREATE	2026-08-06 15:41:38.488959	POST /api/notifications/f645111b-c0e7-4fe1-af55-7ab44204bb92/read	\N	Notification	172.71.218.224	POST	/api/notifications/f645111b-c0e7-4fe1-af55-7ab44204bb92/read	\N	\N
a44634c5-6031-4387-ac1f-6888406a2452	CREATE	2026-08-06 15:41:38.871492	POST /api/notifications/8a8f38b2-3f18-4c60-a52c-c1d66053c2b0/read	\N	Notification	172.71.152.77	POST	/api/notifications/8a8f38b2-3f18-4c60-a52c-c1d66053c2b0/read	\N	\N
20e7e152-8a6b-4708-88e2-418300e477e0	CREATE	2026-08-06 15:41:39.278362	POST /api/notifications/c32782c6-01b5-4e1e-8d27-e6ca5f30b2c8/read	\N	Notification	172.71.215.15	POST	/api/notifications/c32782c6-01b5-4e1e-8d27-e6ca5f30b2c8/read	\N	\N
ebf6d55e-17cf-47b0-833e-c7269133b525	CREATE	2026-08-06 15:41:39.68519	POST /api/notifications/d5d82102-8532-4b2b-8561-01007b1b486a/read	\N	Notification	172.71.152.77	POST	/api/notifications/d5d82102-8532-4b2b-8561-01007b1b486a/read	\N	\N
d4fc21b5-3040-42d5-9e07-4e44a42175f3	RESOLVE	2026-08-06 15:41:42.390775	POST /api/maintenance/483e9cdc-246b-48a5-9a8f-2327910f2b03/resolve	\N	MaintenanceRequest	172.71.152.77	POST	/api/maintenance/483e9cdc-246b-48a5-9a8f-2327910f2b03/resolve	\N	\N
6dcd542c-e099-4e43-93a7-9b0dabb51036	RESOLVE	2026-08-06 15:41:45.498834	POST /api/maintenance/483e9cdc-246b-48a5-9a8f-2327910f2b03/resolve	\N	MaintenanceRequest	172.71.218.224	POST	/api/maintenance/483e9cdc-246b-48a5-9a8f-2327910f2b03/resolve	\N	\N
6d3ae656-c37a-426e-9c25-484db2f08620	RESOLVE	2026-08-06 15:41:46.385886	POST /api/maintenance/483e9cdc-246b-48a5-9a8f-2327910f2b03/resolve	\N	MaintenanceRequest	172.71.152.77	POST	/api/maintenance/483e9cdc-246b-48a5-9a8f-2327910f2b03/resolve	\N	\N
aaf9e25a-c680-4936-ad85-11ab43a7437a	CREATE	2026-08-22 13:46:14.931121	POST /api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	MaintenanceRequest	172.71.215.15	POST	/api/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion-images	\N	\N
df802e86-af62-486e-b7a0-b6f8b3c511e1	CREATE	2026-08-05 07:44:54.63615	POST /api/invoices/generate	\N	Invoice	172.70.208.106	POST	/api/invoices/generate	\N	\N
49e16638-6368-4391-991d-179a625ddc81	CREATE	2026-08-05 07:46:37.866143	POST /api/invoices/generate	\N	Invoice	172.69.165.32	POST	/api/invoices/generate	\N	\N
c63b620f-d750-434d-8143-bcd8bf73f807	CREATE	2026-08-05 07:47:01.015916	POST /api/invoices/generate	\N	Invoice	172.69.165.32	POST	/api/invoices/generate	\N	\N
c70b2150-adbc-46f0-b717-de2593738759	CREATE	2026-08-06 15:51:25.489594	POST /api/properties/e9a22c20-ade9-4541-9a58-f2b10a870651/rooms	\N	Property	172.71.81.83	POST	/api/properties/e9a22c20-ade9-4541-9a58-f2b10a870651/rooms	\N	\N
d2ee3041-fc67-427b-a2bc-6abc7b54bd78	CREATE	2026-08-06 15:51:59.804652	POST /api/users	\N	User	162.158.114.170	POST	/api/users	\N	\N
955b0627-2330-470e-9831-96c9aaa7ca01	CREATE	2026-08-22 13:46:49.221683	POST /api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/submit-review	\N	MaintenanceRequest	162.158.193.197	POST	/api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/submit-review	\N	\N
ad05ab7a-5aac-453e-b57a-1550da61f33d	CREATE	2026-08-05 07:44:59.874981	POST /api/invoices/generate	\N	Invoice	162.158.193.196	POST	/api/invoices/generate	\N	\N
ec5e691c-86d9-4155-85f2-04f12d234d11	CREATE	2026-08-06 15:52:47.016671	POST /api/rooms/fcf45ae0-98ba-4018-8181-1a9dbab9a472/contracts	\N	Room	172.70.143.168	POST	/api/rooms/fcf45ae0-98ba-4018-8181-1a9dbab9a472/contracts	\N	\N
6b78d092-eb43-4e7d-9b5c-1d774b6531b3	CREATE	2026-08-22 14:47:24.122127	POST /api/maintenance/with-images	\N	MaintenanceRequest	172.71.219.105	POST	/api/maintenance/with-images	\N	\N
b7e04fd0-6994-46c1-b097-9d4485abb7ee	ASSIGN	2026-08-22 14:47:53.719891	POST /api/maintenance/b7a2d2ad-c428-4c0d-8802-256afd8979d4/assign	\N	MaintenanceRequest	172.71.215.16	POST	/api/maintenance/b7a2d2ad-c428-4c0d-8802-256afd8979d4/assign	\N	\N
e02b18eb-c0d6-434e-a963-5703a74d71dc	RESOLVE	2026-08-22 14:48:29.646919	POST /api/maintenance/b7a2d2ad-c428-4c0d-8802-256afd8979d4/resolve	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/b7a2d2ad-c428-4c0d-8802-256afd8979d4/resolve	\N	\N
9f73523a-0b2d-4f96-ab0c-6bff4a189e7a	CREATE	2026-08-05 07:45:01.342341	POST /api/invoices/generate	\N	Invoice	162.158.193.196	POST	/api/invoices/generate	\N	\N
f22644e5-10cd-4ae3-9d2a-e88cb800b26d	CREATE	2026-08-05 07:46:36.746515	POST /api/invoices/generate	\N	Invoice	104.23.175.247	POST	/api/invoices/generate	\N	\N
8dd5c39e-b5a4-4976-9878-4b2a2efd54f4	CREATE	2026-08-05 07:47:48.91051	POST /api/invoices/generate	\N	Invoice	162.159.98.50	POST	/api/invoices/generate	\N	\N
39d6817b-d1a0-42ff-8d59-478d52304619	CREATE	2026-08-05 07:48:44.612446	POST /api/invoices/generate	\N	Invoice	172.71.215.15	POST	/api/invoices/generate	\N	\N
a69432ec-239f-4a79-8760-9c4401e3a5ca	CREATE	2026-08-06 15:53:03.465497	POST /api/rooms/fcf45ae0-98ba-4018-8181-1a9dbab9a472/meter-readings	\N	Room	172.71.152.78	POST	/api/rooms/fcf45ae0-98ba-4018-8181-1a9dbab9a472/meter-readings	\N	\N
72ac236e-9c13-47b5-9515-5fb76d9d099a	CREATE	2026-08-22 14:47:59.33373	POST /api/maintenance/b7a2d2ad-c428-4c0d-8802-256afd8979d4/confirm-slot	\N	MaintenanceRequest	172.71.219.105	POST	/api/maintenance/b7a2d2ad-c428-4c0d-8802-256afd8979d4/confirm-slot	\N	\N
768b4c51-fd93-4062-b2fd-dc67ed051659	CREATE	2026-08-22 14:48:02.219775	POST /api/maintenance/b7a2d2ad-c428-4c0d-8802-256afd8979d4/tenant-confirm-slot	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/b7a2d2ad-c428-4c0d-8802-256afd8979d4/tenant-confirm-slot	\N	\N
022283ce-e78c-4081-a821-f1c3d3467c2b	CREATE	2026-08-22 14:48:21.920683	POST /api/maintenance/b7a2d2ad-c428-4c0d-8802-256afd8979d4/submit-review	\N	MaintenanceRequest	172.71.219.105	POST	/api/maintenance/b7a2d2ad-c428-4c0d-8802-256afd8979d4/submit-review	\N	\N
1039d4c1-991e-4681-936b-cb27149e0da2	CREATE	2026-08-05 07:46:35.6379	POST /api/invoices/generate	\N	Invoice	104.23.175.246	POST	/api/invoices/generate	\N	\N
1952dcd4-e217-4e37-8ec8-500c140458d2	CREATE	2026-08-05 07:48:59.093385	POST /api/rooms/b5000000-0000-0000-0000-000000000022/meter-readings	\N	Room	162.159.98.51	POST	/api/rooms/b5000000-0000-0000-0000-000000000022/meter-readings	\N	\N
d277d137-c49e-499c-9637-5fb81c24dbf8	CREATE	2026-08-06 15:53:10.993895	POST /api/invoices/generate	\N	Invoice	162.158.114.171	POST	/api/invoices/generate	\N	\N
d8e26eae-6a03-4ce3-8ca4-d1e426f2ba40	PAYMENT	2026-08-06 15:53:23.989618	POST /api/invoices/0dbf774c-2d51-4fe4-854c-54314781e63c/pay-online	\N	Invoice	162.159.98.50	POST	/api/invoices/0dbf774c-2d51-4fe4-854c-54314781e63c/pay-online	\N	\N
15dd9c33-ff48-4f8d-be96-b97e2a8e4d01	CREATE	2026-08-22 14:48:04.642253	POST /api/maintenance/b7a2d2ad-c428-4c0d-8802-256afd8979d4/start	\N	MaintenanceRequest	172.68.211.104	POST	/api/maintenance/b7a2d2ad-c428-4c0d-8802-256afd8979d4/start	\N	\N
b7b2a9ab-f673-4f51-885d-d18b4599afde	CREATE	2026-08-05 07:46:46.532247	POST /api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	Room	172.68.164.62	POST	/api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	\N
c888d64a-4ec2-425c-af68-5cef20dbfbc1	CREATE	2026-08-05 07:47:14.662175	POST /api/notifications/1a1ab0ba-2fae-498c-9414-63ee9e35b006/read	\N	Notification	172.69.165.33	POST	/api/notifications/1a1ab0ba-2fae-498c-9414-63ee9e35b006/read	\N	\N
810749b8-9ae1-4aa0-90a5-93ed665a12e7	CREATE	2026-08-06 16:41:33.896979	POST /api/maintenance/with-images	\N	MaintenanceRequest	162.159.98.223	POST	/api/maintenance/with-images	\N	\N
0b515523-0834-4c10-bd80-63a25ab139ed	CREATE	2026-08-22 14:48:16.320484	POST /api/maintenance/b7a2d2ad-c428-4c0d-8802-256afd8979d4/completion-images	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/b7a2d2ad-c428-4c0d-8802-256afd8979d4/completion-images	\N	\N
798b1007-bb3e-4aba-8127-7ef84a5ee283	CREATE	2026-08-05 07:46:50.706171	POST /api/invoices/generate	\N	Invoice	172.70.208.107	POST	/api/invoices/generate	\N	\N
cedc3f14-cd7e-45a0-bc1d-68e75d5f453d	CREATE	2026-08-05 07:47:09.408434	POST /api/invoices/generate	\N	Invoice	162.159.98.50	POST	/api/invoices/generate	\N	\N
5cea9605-965c-40cb-9c26-6897581acdc4	CREATE	2026-08-05 07:48:26.721603	POST /api/rooms/b5000000-0000-0000-0000-000000000010/meter-readings	\N	Room	162.158.193.197	POST	/api/rooms/b5000000-0000-0000-0000-000000000010/meter-readings	\N	\N
f259a864-b46c-49b5-822b-8edfec356705	CREATE	2026-08-06 16:42:55.990972	POST /api/maintenance/229d8e58-ffbe-44d4-8909-3e92985cfe8c/start	\N	MaintenanceRequest	172.68.211.105	POST	/api/maintenance/229d8e58-ffbe-44d4-8909-3e92985cfe8c/start	\N	\N
cc35ffdf-dcd9-4e95-a332-e2a067258205	CREATE	2026-08-05 07:46:57.253742	POST /api/rooms/b5000000-0000-0000-0000-000000000005/meter-readings	\N	Room	172.70.208.106	POST	/api/rooms/b5000000-0000-0000-0000-000000000005/meter-readings	\N	\N
dc5f73f6-02cf-4239-a84a-f838887649a9	CREATE	2026-08-05 07:47:46.11131	POST /api/rooms/b5000000-0000-0000-0000-000000000024/meter-readings	\N	Room	162.158.193.196	POST	/api/rooms/b5000000-0000-0000-0000-000000000024/meter-readings	\N	\N
4a4a989d-9083-4e5c-b48e-31260bd7e526	CREATE	2026-08-05 07:48:29.052102	POST /api/invoices/generate	\N	Invoice	172.71.215.16	POST	/api/invoices/generate	\N	\N
e9b96248-08bb-4906-9347-7a167b244aaf	CREATE	2026-08-05 07:48:31.206743	POST /api/invoices/generate	\N	Invoice	172.71.152.77	POST	/api/invoices/generate	\N	\N
9816ef0b-c5f0-416c-a264-d202dcb46580	CREATE	2026-08-05 07:49:01.711879	POST /api/invoices/generate	\N	Invoice	172.69.165.32	POST	/api/invoices/generate	\N	\N
fbe7a592-a208-46ce-bfb2-e033d90c5d03	CREATE	2026-08-06 08:31:18.68985	POST /api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/completion-images	\N	MaintenanceRequest	172.71.218.225	POST	/api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/completion-images	\N	\N
ea5100cc-1389-4705-84b0-8f50146ddbb4	PAYMENT	2026-08-06 08:33:00.691275	POST /api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	Invoice	162.158.179.49	POST	/api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/pay-online	\N	\N
c0dd189a-77f4-49ad-98e4-fa2d4cdfa552	CREATE	2026-08-06 08:35:16.503401	POST /api/maintenance/with-images	\N	MaintenanceRequest	162.159.98.50	POST	/api/maintenance/with-images	\N	\N
54cfc545-ffe2-4fc1-a78c-84c8d25332a6	CREATE	2026-08-06 08:36:06.612885	POST /api/notifications/8d32b230-b6ad-4d15-bc6d-9501e500eb93/read	\N	Notification	162.158.193.197	POST	/api/notifications/8d32b230-b6ad-4d15-bc6d-9501e500eb93/read	\N	\N
0dee0da9-8f7b-43e5-acd1-2abb809482b2	CREATE	2026-08-06 08:36:07.457048	POST /api/notifications/071296b0-7d92-4811-a124-24d16201be87/read	\N	Notification	172.71.152.78	POST	/api/notifications/071296b0-7d92-4811-a124-24d16201be87/read	\N	\N
18c94568-f5c6-40db-b948-49e5841acdc9	CREATE	2026-08-06 08:36:07.848479	POST /api/notifications/af6ee173-d0b4-4c33-ae31-2916d89522bd/read	\N	Notification	172.68.211.105	POST	/api/notifications/af6ee173-d0b4-4c33-ae31-2916d89522bd/read	\N	\N
bb73965d-9bb0-43e1-a56f-295d0aa9a68b	CREATE	2026-08-06 08:36:08.504943	POST /api/notifications/6e3192d7-f9e8-4287-9493-96e135f664c6/read	\N	Notification	172.68.211.105	POST	/api/notifications/6e3192d7-f9e8-4287-9493-96e135f664c6/read	\N	\N
bce05c80-2b2e-430a-b61c-e4f82d635cde	CREATE	2026-08-06 08:36:10.147171	POST /api/notifications/5c726f68-7a2d-4b40-b21d-efc01184aabe/read	\N	Notification	162.158.179.49	POST	/api/notifications/5c726f68-7a2d-4b40-b21d-efc01184aabe/read	\N	\N
f22ce18c-2871-43fb-a5af-88f913b8c608	CREATE	2026-08-06 08:36:10.568035	POST /api/notifications/ba0a7554-86a4-4c06-b457-5dcd71d586b8/read	\N	Notification	162.158.193.197	POST	/api/notifications/ba0a7554-86a4-4c06-b457-5dcd71d586b8/read	\N	\N
dc915e08-06ab-4f5e-b8e8-9522e88dbc38	CREATE	2026-08-06 08:36:10.894876	POST /api/notifications/d3e08a81-ff8c-42fd-937c-a3770035acaf/read	\N	Notification	172.71.81.84	POST	/api/notifications/d3e08a81-ff8c-42fd-937c-a3770035acaf/read	\N	\N
8f0bfeb4-2d14-4d35-8e73-a258d0f854d2	CREATE	2026-08-06 08:36:27.764087	POST /api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/completion-images	\N	MaintenanceRequest	162.158.193.197	POST	/api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/completion-images	\N	\N
a593d75c-a62a-4378-a7c9-ffde15fbdd86	CREATE	2026-08-06 08:36:54.823119	POST /api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/completion-images	\N	MaintenanceRequest	172.70.208.107	POST	/api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/completion-images	\N	\N
f8837aba-aea4-4a06-93f8-00d15c618d8f	CREATE	2026-08-06 08:40:07.117492	POST /api/maintenance/with-images	\N	MaintenanceRequest	162.158.193.196	POST	/api/maintenance/with-images	\N	\N
407339fb-c192-40c6-8eb9-7140a2a1685f	CREATE	2026-08-06 08:40:25.510742	POST /api/maintenance/with-images	\N	MaintenanceRequest	162.158.193.196	POST	/api/maintenance/with-images	\N	\N
ba021646-3156-46c5-8671-7e3836da1bed	CREATE	2026-08-06 08:40:38.998968	POST /api/notifications/e8d24cc1-a103-41d3-b7ba-51d1e2af0f88/read	\N	Notification	104.23.175.246	POST	/api/notifications/e8d24cc1-a103-41d3-b7ba-51d1e2af0f88/read	\N	\N
4c06cd7e-ee0c-4b19-83b1-592b1174aa1d	CREATE	2026-08-06 08:40:39.522533	POST /api/notifications/95334331-451b-4201-a018-a5aa386acde9/read	\N	Notification	104.23.175.246	POST	/api/notifications/95334331-451b-4201-a018-a5aa386acde9/read	\N	\N
f9133f6a-5e46-438d-a6f8-58e5ad37ad93	CREATE	2026-08-06 08:40:40.009712	POST /api/notifications/29394940-ff1d-444e-8ab2-475f3b539ec8/read	\N	Notification	104.23.175.246	POST	/api/notifications/29394940-ff1d-444e-8ab2-475f3b539ec8/read	\N	\N
f8647f87-aab3-4c0c-8a96-072ae281d330	CREATE	2026-08-06 08:40:40.952538	POST /api/notifications/c8be609e-6dca-484e-8b4b-84634b3e6cfa/read	\N	Notification	172.71.81.83	POST	/api/notifications/c8be609e-6dca-484e-8b4b-84634b3e6cfa/read	\N	\N
5b95f485-5136-4d63-a83b-8b2be020887f	CREATE	2026-08-06 08:40:41.389879	POST /api/notifications/9f33d8a4-a419-4388-b7a7-2aa416dc2a1a/read	\N	Notification	172.71.81.83	POST	/api/notifications/9f33d8a4-a419-4388-b7a7-2aa416dc2a1a/read	\N	\N
ccc6d910-3621-4298-b70e-16e9c570e734	CREATE	2026-08-06 08:40:42.158115	POST /api/notifications/48009519-a99b-49da-85ba-11478676640b/read	\N	Notification	162.158.179.49	POST	/api/notifications/48009519-a99b-49da-85ba-11478676640b/read	\N	\N
13c0bee0-bcd2-44b2-8f6e-8564ce2c847c	CREATE	2026-08-06 08:40:42.590165	POST /api/notifications/f338be8a-a66f-40ef-96f9-02b4140411af/read	\N	Notification	172.71.81.83	POST	/api/notifications/f338be8a-a66f-40ef-96f9-02b4140411af/read	\N	\N
56445bd1-f8df-43b7-9b0f-aa6218018e03	CREATE	2026-08-06 08:40:42.890261	POST /api/notifications/d183e968-c352-4080-8456-1e2d8f9909ec/read	\N	Notification	162.158.193.196	POST	/api/notifications/d183e968-c352-4080-8456-1e2d8f9909ec/read	\N	\N
5899ca49-07c8-4fce-b6fd-90eec1af443a	CREATE	2026-08-06 08:41:58.41102	POST /api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/completion-images	\N	MaintenanceRequest	172.70.208.107	POST	/api/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/completion-images	\N	\N
f6e50c52-1013-44af-8450-b6e380cb3b30	CREATE	2026-08-06 08:51:25.999582	POST /api/users/me/change-password	\N	User	172.70.208.106	POST	/api/users/me/change-password	\N	\N
cb1d5a10-e686-41cc-a20c-b24056e6edea	CREATE	2026-08-06 08:52:02.290139	POST /api/users/me/change-password	\N	User	172.70.208.106	POST	/api/users/me/change-password	\N	\N
1910d003-4be4-4c25-b4f2-2a4a952fde60	CREATE	2026-08-06 12:24:06.893827	POST /api/invoices/generate	\N	Invoice	104.23.175.247	POST	/api/invoices/generate	\N	\N
8f6b8a9e-4810-4986-9c41-eab14e484a60	CREATE	2026-08-06 12:24:24.491239	POST /api/invoices/generate	\N	Invoice	172.71.81.84	POST	/api/invoices/generate	\N	\N
980174d2-5c62-4479-9f57-a97776f9b4f7	CREATE	2026-08-06 12:24:32.989895	POST /api/invoices/generate	\N	Invoice	104.23.175.247	POST	/api/invoices/generate	\N	\N
d5df7613-25ac-44e5-81a7-abd101b43329	CREATE	2026-08-06 12:25:04.000978	POST /api/invoices/generate	\N	Invoice	172.68.211.104	POST	/api/invoices/generate	\N	\N
a1fcb7cb-d38c-4888-9461-865a6937b921	CREATE	2026-08-06 12:30:50.689997	POST /api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings/hunonic-sync	\N	Room	162.159.98.51	POST	/api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings/hunonic-sync	\N	\N
487cbe12-06a5-442e-8af3-1ef34f44937d	CREATE	2026-08-06 12:31:53.590174	POST /api/invoices/generate	\N	Invoice	162.159.98.51	POST	/api/invoices/generate	\N	\N
74859f53-0790-4e2c-9519-61c4132b2286	CREATE	2026-08-06 12:33:24.00046	POST /api/invoices/generate	\N	Invoice	162.159.98.51	POST	/api/invoices/generate	\N	\N
0cb03504-5609-4798-a962-de2028086b93	CREATE	2026-08-06 12:33:36.293488	POST /api/invoices/generate	\N	Invoice	162.159.98.51	POST	/api/invoices/generate	\N	\N
67e4397b-6c9f-4160-b73f-876c5adb0ae5	CREATE	2026-08-06 12:34:09.496928	POST /api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings/hunonic-sync	\N	Room	162.159.98.51	POST	/api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings/hunonic-sync	\N	\N
3c3658ff-a46f-4591-bf39-abb7245dafb8	CREATE	2026-08-06 12:35:01.89698	POST /api/invoices/generate	\N	Invoice	172.71.81.84	POST	/api/invoices/generate	\N	\N
8e5fbb9c-e540-4e04-9454-05dab50f10c6	CREATE	2026-08-06 12:34:48.005309	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	104.23.175.246	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
c7d7a5bd-8a08-44df-941a-7b36c5028a81	CREATE	2026-08-06 12:34:56.590759	POST /api/invoices/generate	\N	Invoice	162.159.98.51	POST	/api/invoices/generate	\N	\N
be6b4fa7-dbff-4544-98e8-2d0660eb5bd9	CREATE	2026-08-06 12:35:55.491548	POST /api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/request-cash	\N	Invoice	172.71.81.83	POST	/api/invoices/f04eb140-899d-4bdb-b58c-4e30e87784d0/request-cash	\N	\N
ef657d40-a3e3-4760-84c6-a26ca05089e1	PAYMENT	2026-08-06 12:38:13.921261	POST /api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	Invoice	172.71.152.78	POST	/api/invoices/7c135337-f51e-49fa-8731-3768446542f0/pay-online	\N	\N
d532b417-6157-419e-a019-6c86e10f4937	CREATE	2026-08-06 12:39:02.490769	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	172.71.152.77	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
43d3d397-0fb3-4bf7-9ad4-0389fc716768	CREATE	2026-08-06 12:40:33.205842	POST /api/invoices/generate	\N	Invoice	172.71.81.84	POST	/api/invoices/generate	\N	\N
3d88e8e9-56c5-407d-b05d-5e91c2a5b4ec	CREATE	2026-08-06 12:41:15.961232	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	172.71.218.224	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
7e8ac045-a0f8-480c-9c53-2a6398e74776	CREATE	2026-08-06 12:43:20.97024	POST /api/invoices/generate	\N	Invoice	172.71.215.15	POST	/api/invoices/generate	\N	\N
7b7def71-1162-432f-b936-df763c0127ba	CREATE	2026-08-06 12:43:28.401841	POST /api/invoices/generate	\N	Invoice	172.71.81.84	POST	/api/invoices/generate	\N	\N
db46f987-80fb-4786-a698-b25afca93b1d	CREATE	2026-08-06 12:45:44.502565	POST /api/notifications/fe2225b6-e185-40a8-a83f-d3817db41938/read	\N	Notification	172.71.218.225	POST	/api/notifications/fe2225b6-e185-40a8-a83f-d3817db41938/read	\N	\N
72e7d111-b60d-415e-b967-e154ac46798e	CREATE	2026-08-06 12:49:23.842432	POST /api/rooms/b5000000-0000-0000-0000-000000000012/meter-readings	\N	Room	172.71.152.78	POST	/api/rooms/b5000000-0000-0000-0000-000000000012/meter-readings	\N	\N
a300774d-617e-4127-980b-8ad517aadb0e	CREATE	2026-08-06 12:52:21.526525	POST /api/rooms/b5000000-0000-0000-0000-000000000022/meter-readings	\N	Room	172.71.81.83	POST	/api/rooms/b5000000-0000-0000-0000-000000000022/meter-readings	\N	\N
a7fe6f5d-3226-419e-b703-2264905ec725	CREATE	2026-08-06 12:52:34.073093	POST /api/rooms/b5000000-0000-0000-0000-000000000002/meter-readings	\N	Room	172.71.152.78	POST	/api/rooms/b5000000-0000-0000-0000-000000000002/meter-readings	\N	\N
99ec8eeb-c850-4672-a3f9-e87b93235c7f	CREATE	2026-08-06 16:45:22.670077	POST /api/maintenance/229d8e58-ffbe-44d4-8909-3e92985cfe8c/completion-images	\N	MaintenanceRequest	172.71.152.78	POST	/api/maintenance/229d8e58-ffbe-44d4-8909-3e92985cfe8c/completion-images	\N	\N
94100979-2029-4c2b-a063-395ea8bcd055	CREATE	2026-08-06 16:47:42.253422	POST /api/maintenance/229d8e58-ffbe-44d4-8909-3e92985cfe8c/completion-images	\N	MaintenanceRequest	162.159.98.223	POST	/api/maintenance/229d8e58-ffbe-44d4-8909-3e92985cfe8c/completion-images	\N	\N
ab4d0707-fae7-42be-8be5-435c78876aee	CREATE	2026-08-06 12:39:07.096244	POST /api/invoices/generate	\N	Invoice	172.71.152.77	POST	/api/invoices/generate	\N	\N
5352bfb6-0672-47c6-8e3e-e7ced507ae85	CREATE	2026-08-06 12:40:15.311719	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	172.71.152.77	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
10b2a8ee-0cb3-4e3e-afa3-31d05b8f6f4e	CREATE	2026-08-06 12:41:49.402686	POST /api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	Room	172.71.218.225	POST	/api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	\N
e32da672-1a24-495d-9468-e9900f9d4554	CREATE	2026-08-06 12:41:58.019191	POST /api/invoices/generate	\N	Invoice	172.71.152.78	POST	/api/invoices/generate	\N	\N
996d2d5c-8e6d-4c8d-a0c1-7cae17c15a5d	CREATE	2026-08-06 12:43:09.390188	POST /api/invoices/generate	\N	Invoice	172.71.81.84	POST	/api/invoices/generate	\N	\N
27af7c4a-382b-4026-8593-d21ffc8f3484	CREATE	2026-08-06 12:43:18.403724	POST /api/invoices/generate	\N	Invoice	172.71.81.83	POST	/api/invoices/generate	\N	\N
e39756ae-403d-486a-a41e-2fed0adca525	CREATE	2026-08-06 12:43:19.462179	POST /api/invoices/generate	\N	Invoice	172.71.81.84	POST	/api/invoices/generate	\N	\N
4be65052-7dd0-46ab-880d-068f731585f3	CREATE	2026-08-06 12:44:29.803691	POST /api/invoices/generate	\N	Invoice	104.23.175.246	POST	/api/invoices/generate	\N	\N
b279309c-9c1e-4e05-8b20-b2ab5d7fca6f	CREATE	2026-08-06 12:45:12.294171	POST /api/invoices/generate	\N	Invoice	172.71.81.83	POST	/api/invoices/generate	\N	\N
925a3613-4710-4f65-b18c-091643c20fe9	CREATE	2026-08-06 12:47:13.61499	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	172.71.81.83	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
3efb2e9a-ee9b-41dd-a0d2-05bb90406b95	CREATE	2026-08-06 12:47:57.546087	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	162.159.98.50	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
7b55fb4e-ce2e-4099-ba19-cc77a08041e3	CREATE	2026-08-06 12:48:16.633958	POST /api/rooms/b5000000-0000-0000-0000-000000000007/meter-readings	\N	Room	172.71.81.83	POST	/api/rooms/b5000000-0000-0000-0000-000000000007/meter-readings	\N	\N
87e025fe-6acd-4e76-b784-c8886817ea28	CREATE	2026-08-06 12:49:56.105064	POST /api/rooms/b5000000-0000-0000-0000-000000000021/meter-readings	\N	Room	162.158.193.196	POST	/api/rooms/b5000000-0000-0000-0000-000000000021/meter-readings	\N	\N
ec8fe1f2-8ee8-4ff2-a63a-bda53226dc50	CREATE	2026-08-06 12:50:41.049081	POST /api/rooms/e3d6477b-41ee-4b21-af42-6a9f042e6d08/meter-readings	\N	Room	172.71.81.83	POST	/api/rooms/e3d6477b-41ee-4b21-af42-6a9f042e6d08/meter-readings	\N	\N
035f01c0-c342-43ce-a260-64fd8af5927d	CREATE	2026-08-06 12:51:40.960052	POST /api/rooms/b5000000-0000-0000-0000-000000000024/meter-readings	\N	Room	172.71.152.77	POST	/api/rooms/b5000000-0000-0000-0000-000000000024/meter-readings	\N	\N
81d5e834-0c91-4d5d-87fe-323a4a2d3796	CREATE	2026-08-06 12:51:53.938477	POST /api/rooms/b5000000-0000-0000-0000-000000000016/meter-readings	\N	Room	172.71.218.224	POST	/api/rooms/b5000000-0000-0000-0000-000000000016/meter-readings	\N	\N
d8e79380-9dc8-43df-b83c-9dc598f725e6	CREATE	2026-08-09 15:41:44.083388	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	162.158.193.197	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
d46b7a87-501c-4c96-a75b-3cf0d16df512	CREATE	2026-08-09 15:42:57.382747	POST /api/invoices/generate	\N	Invoice	172.71.218.225	POST	/api/invoices/generate	\N	\N
a5a47aae-67d3-4a85-9366-d39cba2d49b2	CREATE	2026-08-09 15:51:18.689645	POST /api/invoices/generate	\N	Invoice	104.23.175.246	POST	/api/invoices/generate	\N	\N
5293cf19-7bfc-4c52-87a9-a8a42ad48b04	CREATE	2026-08-06 12:41:18.593711	POST /api/invoices/generate	\N	Invoice	162.159.98.50	POST	/api/invoices/generate	\N	\N
3d5dc7cc-2cf4-43ed-aafd-0cc8adf7a5c4	CREATE	2026-08-06 12:42:04.113339	POST /api/invoices/generate	\N	Invoice	172.71.81.83	POST	/api/invoices/generate	\N	\N
2d9fdef7-59b9-450f-a43c-7467d6b02307	CREATE	2026-08-06 12:42:08.497877	POST /api/invoices/generate	\N	Invoice	172.68.211.104	POST	/api/invoices/generate	\N	\N
1b907b6b-09f4-4018-b1fd-738071f57045	CREATE	2026-08-06 12:42:11.309775	POST /api/invoices/generate	\N	Invoice	172.68.211.104	POST	/api/invoices/generate	\N	\N
6be0051b-2cbf-437e-9d7f-94e0c222b788	CREATE	2026-08-06 12:43:05.821835	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	172.71.218.225	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
3a11bb2c-62d9-41cb-ba8f-9f4d5c0dce39	CREATE	2026-08-06 12:43:13.089895	POST /api/invoices/generate	\N	Invoice	162.158.179.49	POST	/api/invoices/generate	\N	\N
3ef7d7f5-b215-47c0-a0ad-ddfacb31a4a4	CREATE	2026-08-06 12:43:44.367977	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	172.71.218.224	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
ec8bc38f-9f00-45c0-9ecb-9577426c98e3	CREATE	2026-08-06 12:44:12.880594	POST /api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	Room	172.71.81.84	POST	/api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	\N
35d2dc42-d3d7-464e-8b6e-216e239d27f1	CREATE	2026-08-06 12:44:17.142529	POST /api/invoices/generate	\N	Invoice	172.71.218.225	POST	/api/invoices/generate	\N	\N
fbf2f116-cbbb-4831-8eeb-c3812995ef37	CREATE	2026-08-06 12:45:07.759169	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	172.71.218.224	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
758e0efc-8ea8-42a6-9368-835614ece8e9	CREATE	2026-08-06 12:45:45.070145	POST /api/notifications/2d212af5-27e4-4d00-8258-47959503e4b4/read	\N	Notification	172.71.152.78	POST	/api/notifications/2d212af5-27e4-4d00-8258-47959503e4b4/read	\N	\N
df0f7654-1e37-4cfa-a176-2746f0805c3a	CREATE	2026-08-06 12:45:45.43254	POST /api/notifications/40315368-a208-4a3f-9431-9226034c33b9/read	\N	Notification	172.71.81.83	POST	/api/notifications/40315368-a208-4a3f-9431-9226034c33b9/read	\N	\N
5325fb16-de65-42e4-a98a-b39328d94cdb	CREATE	2026-08-06 12:45:46.280172	POST /api/notifications/ebfdb530-a604-4b65-9ce7-9e06e67d26a5/read	\N	Notification	172.71.152.77	POST	/api/notifications/ebfdb530-a604-4b65-9ce7-9e06e67d26a5/read	\N	\N
69e8732e-cc03-4dab-9d4c-661a7aa616ea	CREATE	2026-08-06 12:45:46.523124	POST /api/notifications/6d3325e5-cfef-4d8a-a40a-6f7289e70e95/read	\N	Notification	172.70.143.168	POST	/api/notifications/6d3325e5-cfef-4d8a-a40a-6f7289e70e95/read	\N	\N
1d637393-882f-4502-8c3b-6dbd8a41754c	CREATE	2026-08-06 12:45:47.478743	POST /api/notifications/fbee863c-900c-4e33-ac2d-b032a8132d29/read	\N	Notification	172.68.211.104	POST	/api/notifications/fbee863c-900c-4e33-ac2d-b032a8132d29/read	\N	\N
7d0722c5-2d74-4f51-ae7b-8c9654a83019	CREATE	2026-08-06 12:46:09.204957	POST /api/invoices/generate	\N	Invoice	172.68.211.104	POST	/api/invoices/generate	\N	\N
aadf717c-c76d-4bbd-9034-c9f7b0185143	CREATE	2026-08-06 12:46:29.490576	POST /api/invoices/generate	\N	Invoice	172.71.152.78	POST	/api/invoices/generate	\N	\N
673f35dc-362c-466e-b5cf-6c75ec5a149d	UPDATE	2026-08-06 12:47:03.096507	PUT /api/properties/b3000000-0000-0000-0000-000000000001/fee-config	\N	Property	162.158.179.50	PUT	/api/properties/b3000000-0000-0000-0000-000000000001/fee-config	\N	\N
34e100fa-c7cb-47fb-a480-6c99cba89453	CREATE	2026-08-06 12:47:15.791967	POST /api/invoices/generate	\N	Invoice	162.159.98.50	POST	/api/invoices/generate	\N	\N
abd847f0-d26e-4e73-8c76-48d9ec07dc05	CREATE	2026-08-06 12:47:21.719656	POST /api/invoices/generate	\N	Invoice	162.158.179.50	POST	/api/invoices/generate	\N	\N
f96aaf13-36ce-4897-832b-5db5c4ca81ce	CREATE	2026-08-06 12:47:59.329128	POST /api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	Room	172.71.81.84	POST	/api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	\N
79d98715-89e5-4d27-9e35-d46d5b28d47c	CREATE	2026-08-06 12:48:29.755537	POST /api/rooms/b5000000-0000-0000-0000-000000000009/meter-readings	\N	Room	162.159.98.50	POST	/api/rooms/b5000000-0000-0000-0000-000000000009/meter-readings	\N	\N
087fe4a8-9f0e-42d3-85df-0bef761712b0	CREATE	2026-08-06 12:48:41.88769	POST /api/rooms/b5000000-0000-0000-0000-000000000005/meter-readings	\N	Room	162.158.114.171	POST	/api/rooms/b5000000-0000-0000-0000-000000000005/meter-readings	\N	\N
a39cd567-41e8-4aa2-aace-fad85d0df9e7	CREATE	2026-08-06 12:48:56.802915	POST /api/rooms/b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6/meter-readings	\N	Room	172.71.218.225	POST	/api/rooms/b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6/meter-readings	\N	\N
9ffaaf04-2563-42b2-900f-2346ea10e7ae	CREATE	2026-08-06 12:49:09.549348	POST /api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	Room	172.71.218.225	POST	/api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	\N
24d6a43e-e867-4ba3-b44b-c9997f7fb69d	CREATE	2026-08-06 12:49:44.473142	POST /api/rooms/b5000000-0000-0000-0000-000000000003/meter-readings	\N	Room	172.71.215.15	POST	/api/rooms/b5000000-0000-0000-0000-000000000003/meter-readings	\N	\N
9635b4ad-4456-4973-b9b1-5470db3d8340	CREATE	2026-08-06 12:50:12.841176	POST /api/rooms/b5000000-0000-0000-0000-000000000017/meter-readings	\N	Room	172.71.152.77	POST	/api/rooms/b5000000-0000-0000-0000-000000000017/meter-readings	\N	\N
b649021e-9082-47b1-8f4c-d8b720f7ea56	CREATE	2026-08-06 12:50:27.786132	POST /api/rooms/b5000000-0000-0000-0000-000000000010/meter-readings	\N	Room	162.158.114.170	POST	/api/rooms/b5000000-0000-0000-0000-000000000010/meter-readings	\N	\N
9406c825-968f-488d-8a04-a9164022df39	CREATE	2026-08-06 12:51:02.460096	POST /api/rooms/b5000000-0000-0000-0000-000000000025/meter-readings	\N	Room	172.71.152.77	POST	/api/rooms/b5000000-0000-0000-0000-000000000025/meter-readings	\N	\N
32e6eedc-c424-4b3a-aa38-e5f3c16aeb28	CREATE	2026-08-06 12:51:13.98971	POST /api/rooms/b5000000-0000-0000-0000-000000000013/meter-readings	\N	Room	172.71.218.224	POST	/api/rooms/b5000000-0000-0000-0000-000000000013/meter-readings	\N	\N
9e289c80-e239-42bb-ab95-ba45b0596f8e	CREATE	2026-08-06 12:51:26.974186	POST /api/rooms/b5000000-0000-0000-0000-000000000018/meter-readings	\N	Room	172.71.215.16	POST	/api/rooms/b5000000-0000-0000-0000-000000000018/meter-readings	\N	\N
c80bcbc8-3277-43b1-819e-70031330a651	CREATE	2026-08-06 12:52:06.88972	POST /api/rooms/b5000000-0000-0000-0000-000000000014/meter-readings	\N	Room	172.71.152.77	POST	/api/rooms/b5000000-0000-0000-0000-000000000014/meter-readings	\N	\N
3f22722c-bf7b-4d3a-8c56-f0270236a54f	CREATE	2026-08-06 12:52:39.502199	POST /api/invoices/generate	\N	Invoice	172.71.81.84	POST	/api/invoices/generate	\N	\N
52994259-2b9b-47b2-a350-165a1305a6b2	CREATE	2026-08-06 12:52:46.799522	POST /api/invoices/generate	\N	Invoice	172.71.152.77	POST	/api/invoices/generate	\N	\N
2d55abcc-a72f-4aa0-831b-12dfb92f4cf9	CREATE	2026-08-06 12:52:50.035947	POST /api/invoices/generate	\N	Invoice	172.71.152.78	POST	/api/invoices/generate	\N	\N
fae6bf96-9629-469f-bec8-ac3f86b9d372	CREATE	2026-08-06 12:52:54.10629	POST /api/invoices/generate	\N	Invoice	162.158.179.50	POST	/api/invoices/generate	\N	\N
061d2795-40eb-4ce9-a05b-26820d687406	CREATE	2026-08-06 12:53:15.654484	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	172.68.211.105	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
03ebfdb4-1ca3-4644-b746-785620d04811	CREATE	2026-08-06 12:53:19.421853	POST /api/invoices/generate	\N	Invoice	104.23.175.246	POST	/api/invoices/generate	\N	\N
26229a57-279f-4418-abfc-b318a96daa73	CREATE	2026-08-06 12:56:04.402964	POST /api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	Room	172.71.81.83	POST	/api/rooms/b5000000-0000-0000-0000-000000000001/meter-readings	\N	\N
dcbdbfea-5b04-43d8-ae4d-811ac942fb66	CREATE	2026-08-06 12:56:08.252579	POST /api/invoices/generate	\N	Invoice	172.71.218.224	POST	/api/invoices/generate	\N	\N
634d096d-931b-4a61-9604-fcaa65504388	CREATE	2026-08-06 13:01:44.404347	POST /api/invoices/generate	\N	Invoice	162.159.98.51	POST	/api/invoices/generate	\N	\N
ca2d0d3a-dd96-4433-84a8-6988940cb515	CREATE	2026-08-06 13:01:47.290553	POST /api/invoices/generate	\N	Invoice	162.159.98.51	POST	/api/invoices/generate	\N	\N
a2d682fe-4674-4cf1-8b09-ab5ed4c00439	CREATE	2026-08-06 13:04:30.401982	POST /api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	Room	104.23.175.247	POST	/api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	\N
11744dbb-1477-4d19-ae77-7d9a33d5f7fe	CREATE	2026-08-06 13:04:40.662749	POST /api/rooms/b5000000-0000-0000-0000-000000000007/meter-readings	\N	Room	162.159.98.51	POST	/api/rooms/b5000000-0000-0000-0000-000000000007/meter-readings	\N	\N
32a95fec-a60c-4a34-83d1-478bd90c34e3	CREATE	2026-08-06 13:05:34.848488	POST /api/rooms/b5000000-0000-0000-0000-000000000009/meter-readings	\N	Room	162.159.98.50	POST	/api/rooms/b5000000-0000-0000-0000-000000000009/meter-readings	\N	\N
3a24858d-b8f5-41ea-b1f4-6d9e6a799d92	CREATE	2026-08-06 13:05:43.809317	POST /api/rooms/b5000000-0000-0000-0000-000000000005/meter-readings	\N	Room	172.71.152.78	POST	/api/rooms/b5000000-0000-0000-0000-000000000005/meter-readings	\N	\N
e6698ddc-699b-4958-812f-264102c2afb0	CREATE	2026-08-06 13:06:40.929537	POST /api/rooms/b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6/meter-readings	\N	Room	104.23.175.246	POST	/api/rooms/b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6/meter-readings	\N	\N
10ee4f23-7dce-4ae2-a50c-d6597cea43a3	CREATE	2026-08-06 13:07:38.891666	POST /api/rooms/b5000000-0000-0000-0000-000000000010/meter-readings	\N	Room	172.71.81.83	POST	/api/rooms/b5000000-0000-0000-0000-000000000010/meter-readings	\N	\N
9f58e621-9067-4047-9ed0-22fed713709b	CREATE	2026-08-06 13:07:47.697446	POST /api/rooms/e3d6477b-41ee-4b21-af42-6a9f042e6d08/meter-readings	\N	Room	172.71.152.77	POST	/api/rooms/e3d6477b-41ee-4b21-af42-6a9f042e6d08/meter-readings	\N	\N
865c96a5-4c5a-4107-b4dd-9f6823b3bc31	CREATE	2026-08-06 13:08:05.133927	POST /api/rooms/b5000000-0000-0000-0000-000000000013/meter-readings	\N	Room	172.71.152.77	POST	/api/rooms/b5000000-0000-0000-0000-000000000013/meter-readings	\N	\N
3b76ca79-170e-4312-8585-c107fc8c5e5d	CREATE	2026-08-06 13:08:14.016864	POST /api/rooms/b5000000-0000-0000-0000-000000000018/meter-readings	\N	Room	104.23.175.246	POST	/api/rooms/b5000000-0000-0000-0000-000000000018/meter-readings	\N	\N
107dfb0c-89d6-400b-9803-6f5a65abcd81	CREATE	2026-08-09 15:41:48.189741	POST /api/invoices/generate	\N	Invoice	172.71.215.16	POST	/api/invoices/generate	\N	\N
cfb03c87-b7f9-4bff-9519-4f6d86a68f64	CREATE	2026-08-06 13:06:51.176029	POST /api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	Room	162.158.179.50	POST	/api/rooms/26962280-8932-4cc6-b92f-ac0b9a570cd0/meter-readings	\N	\N
f14be19d-6faf-4be3-aeea-9bf1623dbc67	CREATE	2026-08-06 13:06:59.700601	POST /api/rooms/b5000000-0000-0000-0000-000000000012/meter-readings	\N	Room	162.159.98.50	POST	/api/rooms/b5000000-0000-0000-0000-000000000012/meter-readings	\N	\N
872cc8fa-9ccd-4edf-b328-2d889238cfb8	CREATE	2026-08-06 13:07:11.329733	POST /api/rooms/b5000000-0000-0000-0000-000000000003/meter-readings	\N	Room	172.68.211.104	POST	/api/rooms/b5000000-0000-0000-0000-000000000003/meter-readings	\N	\N
bcf4b716-65b9-4610-99eb-ced216458391	CREATE	2026-08-06 13:07:20.696594	POST /api/rooms/b5000000-0000-0000-0000-000000000021/meter-readings	\N	Room	162.159.98.50	POST	/api/rooms/b5000000-0000-0000-0000-000000000021/meter-readings	\N	\N
a3401f7b-24bb-4757-ad9a-06c5d14e381a	CREATE	2026-08-06 13:07:57.560219	POST /api/rooms/b5000000-0000-0000-0000-000000000025/meter-readings	\N	Room	172.71.218.224	POST	/api/rooms/b5000000-0000-0000-0000-000000000025/meter-readings	\N	\N
099be8a6-4bea-4f4a-9161-302f273353fc	CREATE	2026-08-06 13:08:21.576448	POST /api/rooms/b5000000-0000-0000-0000-000000000024/meter-readings	\N	Room	162.158.193.197	POST	/api/rooms/b5000000-0000-0000-0000-000000000024/meter-readings	\N	\N
c771bb29-c1f0-45f6-a11b-28acfb9916fd	CREATE	2026-08-06 13:08:36.355616	POST /api/rooms/b5000000-0000-0000-0000-000000000014/meter-readings	\N	Room	172.71.152.78	POST	/api/rooms/b5000000-0000-0000-0000-000000000014/meter-readings	\N	\N
0c037bc3-1cbb-490e-9d12-fa17d4d2e9d0	CREATE	2026-08-06 13:08:43.67477	POST /api/rooms/b5000000-0000-0000-0000-000000000022/meter-readings	\N	Room	162.158.179.49	POST	/api/rooms/b5000000-0000-0000-0000-000000000022/meter-readings	\N	\N
c859d709-a7c2-44f4-8a43-fd79c86f617c	CREATE	2026-08-09 15:41:57.680416	POST /api/invoices/generate	\N	Invoice	172.71.215.16	POST	/api/invoices/generate	\N	\N
667f433c-a6cd-4369-920a-ca09444420e1	CREATE	2026-08-06 13:07:31.397171	POST /api/rooms/b5000000-0000-0000-0000-000000000017/meter-readings	\N	Room	104.23.175.246	POST	/api/rooms/b5000000-0000-0000-0000-000000000017/meter-readings	\N	\N
56f246b2-7a06-45e8-a699-ff8ad85535df	CREATE	2026-08-06 13:08:29.399653	POST /api/rooms/b5000000-0000-0000-0000-000000000016/meter-readings	\N	Room	172.71.152.77	POST	/api/rooms/b5000000-0000-0000-0000-000000000016/meter-readings	\N	\N
3b041c99-4f60-461a-a39b-58470028090e	CREATE	2026-08-09 15:42:40.034712	POST /api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	Room	172.68.211.105	POST	/api/rooms/b5000000-0000-0000-0000-000000000004/meter-readings	\N	\N
\.


--
-- Data for Name: contracts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.contracts (id, created_at, updated_at, deposit_amount, file_url, move_in_date, move_out_date, notes, status, room_id, tenant_id) FROM stdin;
b6000000-0000-0000-0000-000000000003	2026-01-10 16:45:00	2026-06-30 11:45:00	30400000.00	\N	2026-01-15	\N	Khach la nhan vien ngan hang, thanh toan dung han.	ACTIVE	b5000000-0000-0000-0000-000000000004	b1000000-0000-0000-0000-000000000004
b6000000-0000-0000-0000-000000000004	2026-03-20 10:20:00	2026-06-30 11:45:00	37800000.00	\N	2026-04-01	\N	Gia dinh tre 3 nguoi, co 1 oto.	ACTIVE	b5000000-0000-0000-0000-000000000005	b1000000-0000-0000-0000-000000000005
b6000000-0000-0000-0000-000000000005	2026-02-10 13:05:00	2026-06-30 11:50:00	21000000.00	\N	2026-02-18	\N	Khach muon giu phong toi het Q1/2027.	ACTIVE	b5000000-0000-0000-0000-000000000007	b1000000-0000-0000-0000-000000000006
b6000000-0000-0000-0000-000000000006	2026-04-28 15:10:00	2026-06-30 11:50:00	23800000.00	\N	2026-05-05	\N	Can ho da co noi that, khach giu 1 xe may.	ACTIVE	b5000000-0000-0000-0000-000000000009	b1000000-0000-0000-0000-000000000007
b6000000-0000-0000-0000-000000000007	2026-02-06 10:00:00	2026-06-30 12:40:00	21800000.00	\N	2026-02-10	\N	Hop dong 12 thang, khach lam viec tai Thu Duc.	ACTIVE	b5000000-0000-0000-0000-000000000012	b1000000-0000-0000-0000-000000000010
b6000000-0000-0000-0000-000000000008	2026-02-12 10:00:00	2026-06-30 12:40:00	25600000.00	\N	2026-02-20	\N	Khach o mot nguoi, uu tien thanh toan PayOS.	ACTIVE	b5000000-0000-0000-0000-000000000013	b1000000-0000-0000-0000-000000000011
b6000000-0000-0000-0000-000000000009	2026-02-25 10:00:00	2026-06-30 12:40:00	32400000.00	\N	2026-03-01	\N	Nhom 3 nguoi, giu 2 xe may.	ACTIVE	b5000000-0000-0000-0000-000000000014	b1000000-0000-0000-0000-000000000012
b6000000-0000-0000-0000-000000000010	2026-02-08 10:00:00	2026-06-30 12:45:00	27800000.00	\N	2026-02-15	\N	Khach thue dai han, thanh toan vao ngay 03.	ACTIVE	b5000000-0000-0000-0000-000000000016	b1000000-0000-0000-0000-000000000013
b6000000-0000-0000-0000-000000000011	2026-02-28 10:00:00	2026-06-30 12:45:00	32800000.00	\N	2026-03-05	\N	Gia dinh 2 nguoi, giu 1 xe may va 1 xe dap.	ACTIVE	b5000000-0000-0000-0000-000000000017	b1000000-0000-0000-0000-000000000014
b6000000-0000-0000-0000-000000000012	2026-03-25 10:00:00	2026-06-30 12:45:00	41000000.00	\N	2026-04-01	\N	Can ho lon, khach co 1 oto.	ACTIVE	b5000000-0000-0000-0000-000000000018	b1000000-0000-0000-0000-000000000015
b6000000-0000-0000-0000-000000000014	2026-03-05 10:00:00	2026-06-30 12:50:00	20200000.00	\N	2026-03-12	\N	Khach lam viec ca dem, can ho yen tinh.	ACTIVE	b5000000-0000-0000-0000-000000000021	b1000000-0000-0000-0000-000000000017
b6000000-0000-0000-0000-000000000015	2026-04-01 10:00:00	2026-06-30 12:50:00	25200000.00	\N	2026-04-10	\N	Nhom khach tre, uu tien bao tri nhanh.	ACTIVE	b5000000-0000-0000-0000-000000000022	b1000000-0000-0000-0000-000000000018
b6000000-0000-0000-0000-000000000016	2026-02-20 10:00:00	2026-06-30 12:55:00	20600000.00	\N	2026-02-25	\N	Khach o mot nguoi, giu 1 xe may.	ACTIVE	b5000000-0000-0000-0000-000000000024	b1000000-0000-0000-0000-000000000019
b6000000-0000-0000-0000-000000000017	2026-03-15 10:00:00	2026-06-30 12:55:00	25400000.00	\N	2026-03-20	\N	Khach o 2 nguoi, hop dong 12 thang.	ACTIVE	b5000000-0000-0000-0000-000000000025	b1000000-0000-0000-0000-000000000020
b6000000-0000-0000-0000-000000000018	2026-01-12 10:00:00	2026-05-31 18:00:00	21600000.00	\N	2026-01-20	2026-05-31	Hop dong cu da ket thuc, phong da co khach moi tu thang 6.	EXPIRED	b5000000-0000-0000-0000-000000000010	b1000000-0000-0000-0000-000000000021
b6000000-0000-0000-0000-000000000013	2026-01-28 10:00:00	2026-07-27 08:24:59.137881	18400000.00	\N	2026-02-01	2026-07-27	Khach can gan Quan 1, thue 12 thang.	TERMINATED	b5000000-0000-0000-0000-000000000020	b1000000-0000-0000-0000-000000000016
3cb0c43a-de37-4c89-bf35-d4b88408bc72	2026-07-27 08:30:48.004637	2026-07-27 08:30:48.004637	15000000.00	\N	2026-07-27	\N	cọc 1 nữa	ACTIVE	26962280-8932-4cc6-b92f-ac0b9a570cd0	a0000000-0000-0000-0000-000000000002
df54e252-b333-43f9-81da-42b0a5b9731e	2026-08-04 08:12:47.069468	2026-08-04 08:12:47.069468	15000000.00	\N	2026-08-04	\N	không có	ACTIVE	b5000000-0000-0000-0000-000000000003	b1000000-0000-0000-0000-000000000004
95a1bfda-d60e-4a4e-922b-4416d51f7596	2026-08-04 17:07:32.22557	2026-08-04 17:07:32.22557	29600000.00	\N	2026-08-04	\N	Khach o 2 nguoi, giu 1 xe may.	ACTIVE	b5000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000003
b6000000-0000-0000-0000-000000000002	2026-03-01 09:30:00	2026-08-04 17:07:32.625197	29600000.00	\N	2026-03-10	2026-08-04	Khach o 2 nguoi, giu 1 xe may.	EXPIRED	b5000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000003
6e6f011b-8790-473c-a38c-7157ba2c5f44	2026-08-05 04:09:55.509662	2026-08-05 04:37:11.121906	12000000.00	\N	2026-05-08	2026-08-05	cọc 1 nữa	TERMINATED	95192562-e587-4da2-bac0-46d29aa261e9	3589890e-f56b-4dbc-84fc-12e319e1d750
1140f21c-c699-47f3-92ee-b1b31501daef	2026-08-05 05:45:11.906536	2026-08-05 05:45:11.906536	4000000.00	\N	2026-08-05	\N	\N	ACTIVE	e3d6477b-41ee-4b21-af42-6a9f042e6d08	a0000000-0000-0000-0000-000000000002
647600c0-962d-4cb3-9d27-8b1fb0e1d84a	2026-08-05 06:00:53.92083	2026-08-05 06:00:53.92083	5000000.00	\N	2026-07-01	\N	\N	ACTIVE	b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6	74ccd53e-4998-49a3-97e3-b918b60f4080
3f3987fa-7c26-48dd-96a1-b78c8237e4fe	2026-08-06 15:10:16.492932	2026-08-06 15:14:26.965376	4000000.00	\N	2026-07-18	2026-08-06	\N	TERMINATED	3697261c-44e6-4b47-9b9d-25277cc8da51	33712636-202b-4ff3-8011-2da710d65035
a0dbc53e-5b77-435a-81e0-43455a3f4fff	2026-08-06 15:15:06.368614	2026-08-06 15:16:21.32604	500.00	\N	2026-07-18	2026-08-06	\N	TERMINATED	3697261c-44e6-4b47-9b9d-25277cc8da51	33712636-202b-4ff3-8011-2da710d65035
0f230080-634c-4f81-90bf-b1a70e178077	2026-08-06 15:16:44.135169	2026-08-06 15:16:44.135169	500.00	\N	2026-07-30	\N	\N	ACTIVE	ce27f631-b495-48aa-9fc5-c60ec18a95eb	33712636-202b-4ff3-8011-2da710d65035
5d82e7d6-1243-41be-be3d-6c493f75ee30	2026-08-06 15:52:47.001031	2026-08-06 15:52:47.001031	1.00	\N	2026-07-29	\N	\N	ACTIVE	fcf45ae0-98ba-4018-8181-1a9dbab9a472	797e1cfb-d15e-4642-b968-faba2a872c4a
d334e2a7-af01-497c-8496-eff8a4751708	2026-08-13 09:30:09.281185	2026-08-13 09:30:09.281185	24400000.00	\N	2026-08-13	\N	Hop dong 12 thang, thanh toan vao ngay 05 hang thang.	ACTIVE	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002
b6000000-0000-0000-0000-000000000001	2026-01-25 14:10:00	2026-08-13 09:30:09.281948	24400000.00	\N	2026-02-01	2026-08-13	Hop dong 12 thang, thanh toan vao ngay 05 hang thang.	EXPIRED	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002
5448b64c-a55f-40df-9378-c7b2a4e42a37	2026-08-21 01:47:35.659359	2026-08-21 01:48:59.756775	10000000.00	\N	2026-08-21	2026-08-21	\N	TERMINATED	3697261c-44e6-4b47-9b9d-25277cc8da51	3589890e-f56b-4dbc-84fc-12e319e1d750
1da4374a-c3b6-46c1-a5f8-2ebc07945224	2026-08-21 01:49:58.681696	2026-08-21 01:49:58.681696	10000000.00	\N	2026-08-21	\N	ko có	ACTIVE	3697261c-44e6-4b47-9b9d-25277cc8da51	3589890e-f56b-4dbc-84fc-12e319e1d750
\.


--
-- Data for Name: fee_configs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.fee_configs (id, created_at, updated_at, bicycle_price, car_price, elec_price, motorbike_price, rent_default, service_fee, service_pro_rata, vehicle_pro_rata, water_mode, water_price, property_id) FROM stdin;
b4000000-0000-0000-0000-000000000001	2026-01-08 09:05:00	2026-06-30 10:00:00	50000.00	1200000.00	3800.00	120000.00	11800000.00	350000.00	f	f	CUBIC	18500.00	b3000000-0000-0000-0000-000000000001
b4000000-0000-0000-0000-000000000002	2026-01-08 09:20:00	2026-06-30 10:05:00	50000.00	1350000.00	4000.00	150000.00	14500000.00	450000.00	f	f	CUBIC	19000.00	b3000000-0000-0000-0000-000000000002
b4000000-0000-0000-0000-000000000003	2026-01-08 09:35:00	2026-06-30 10:10:00	40000.00	1100000.00	3800.00	120000.00	9900000.00	300000.00	f	f	CUBIC	18000.00	b3000000-0000-0000-0000-000000000003
b4000000-0000-0000-0000-000000000004	2026-01-08 09:50:00	2026-06-30 10:15:00	40000.00	1150000.00	3900.00	120000.00	11200000.00	320000.00	f	f	CUBIC	18500.00	b3000000-0000-0000-0000-000000000004
7f9a32e9-d763-482d-9135-e244cd752809	2026-07-27 04:54:03.705818	2026-07-27 08:10:18.463365	50000.00	2000000.00	0.00	150000.00	0.00	210000.00	f	f	PERSON	0.00	c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e
a61600fc-fe82-4f70-833a-0e0bfb7fce74	2026-08-05 05:39:31.741465	2026-08-05 06:04:38.813449	0.00	0.00	3800.00	20000.00	7000000.00	0.00	f	f	PERSON	100000.00	e9a22c20-ade9-4541-9a58-f2b10a870651
\.


--
-- Data for Name: invoices; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.invoices (id, created_at, updated_at, checkout_url, days_used, due_date, elec_amount, invoice_month, paid_at, payment_link_id, payment_method, is_pro_rata, rent_amount, service_amount, status, total_amount, transaction_id, vehicle_amount, water_amount, contract_id, room_id) FROM stdin;
b7000000-0000-0000-0000-000000000001	2026-06-01 08:30:00	2026-06-05 19:20:00	\N	\N	2026-06-07	418000.00	2026-06-01	2026-06-05 19:20:00	\N	CASH	f	12200000.00	350000.00	PAID	13273000.00	\N	120000.00	185000.00	b6000000-0000-0000-0000-000000000001	b5000000-0000-0000-0000-000000000001
b7000000-0000-0000-0000-000000000003	2026-06-01 09:00:00	2026-06-20 09:30:00	\N	\N	2026-06-10	396000.00	2026-06-01	\N	\N	\N	f	15200000.00	450000.00	OVERDUE	16424000.00	\N	150000.00	228000.00	b6000000-0000-0000-0000-000000000003	b5000000-0000-0000-0000-000000000004
b7000000-0000-0000-0000-000000000005	2026-06-01 10:00:00	2026-06-06 12:10:00	https://pay.payos.vn/demo/ld1204	27	2026-06-07	365000.00	2026-06-01	2026-06-06 12:10:00	PAYOS-DEMO-0901	PAYOS	t	10710000.00	320000.00	PAID	11705000.00	TXN-DEMO-LD1204	120000.00	190000.00	b6000000-0000-0000-0000-000000000006	b5000000-0000-0000-0000-000000000009
b7000000-0000-0000-0000-000000000006	2026-04-01 08:00:00	2026-04-05 18:30:00	\N	\N	2026-04-07	338000.00	2026-04-01	2026-04-05 18:30:00	\N	CASH	f	10900000.00	350000.00	PAID	11856000.00	\N	120000.00	148000.00	b6000000-0000-0000-0000-000000000007	b5000000-0000-0000-0000-000000000012
b7000000-0000-0000-0000-000000000007	2026-05-01 08:00:00	2026-05-06 09:20:00	https://pay.payos.vn/demo/t30502-05	\N	2026-05-07	361000.00	2026-05-01	2026-05-06 09:20:00	PAYOS-DEMO-1205	PAYOS	f	10900000.00	350000.00	PAID	11897000.00	TXN-DEMO-T30502-05	120000.00	166000.00	b6000000-0000-0000-0000-000000000007	b5000000-0000-0000-0000-000000000012
b7000000-0000-0000-0000-000000000009	2026-04-01 08:05:00	2026-04-04 20:10:00	\N	\N	2026-04-07	380000.00	2026-04-01	2026-04-04 20:10:00	\N	CASH	f	12800000.00	350000.00	PAID	13798000.00	\N	120000.00	148000.00	b6000000-0000-0000-0000-000000000008	b5000000-0000-0000-0000-000000000013
b7000000-0000-0000-0000-000000000010	2026-05-01 08:05:00	2026-05-15 08:05:00	\N	\N	2026-05-07	399000.00	2026-05-01	\N	\N	\N	f	12800000.00	350000.00	OVERDUE	13835000.00	\N	120000.00	166000.00	b6000000-0000-0000-0000-000000000008	b5000000-0000-0000-0000-000000000013
b7000000-0000-0000-0000-000000000012	2026-04-01 08:10:00	2026-04-07 11:35:00	https://pay.payos.vn/demo/t32101-04	\N	2026-04-07	494000.00	2026-04-01	2026-04-07 11:35:00	PAYOS-DEMO-1404	PAYOS	f	16200000.00	350000.00	PAID	17506000.00	TXN-DEMO-T32101-04	240000.00	222000.00	b6000000-0000-0000-0000-000000000009	b5000000-0000-0000-0000-000000000014
b7000000-0000-0000-0000-000000000013	2026-05-01 08:10:00	2026-05-05 17:45:00	\N	\N	2026-05-07	528000.00	2026-05-01	2026-05-05 17:45:00	\N	CASH	f	16200000.00	350000.00	PAID	17558000.00	\N	240000.00	240000.00	b6000000-0000-0000-0000-000000000009	b5000000-0000-0000-0000-000000000014
b7000000-0000-0000-0000-000000000015	2026-04-01 08:15:00	2026-04-05 09:00:00	\N	\N	2026-04-07	376000.00	2026-04-01	2026-04-05 09:00:00	\N	CASH	f	13900000.00	450000.00	PAID	15066000.00	\N	150000.00	190000.00	b6000000-0000-0000-0000-000000000010	b5000000-0000-0000-0000-000000000016
b7000000-0000-0000-0000-000000000016	2026-05-01 08:15:00	2026-05-04 13:25:00	https://pay.payos.vn/demo/p60603-05	\N	2026-05-07	401000.00	2026-05-01	2026-05-04 13:25:00	PAYOS-DEMO-1605	PAYOS	f	13900000.00	450000.00	PAID	15110000.00	TXN-DEMO-P60603-05	150000.00	209000.00	b6000000-0000-0000-0000-000000000010	b5000000-0000-0000-0000-000000000016
b7000000-0000-0000-0000-000000000018	2026-04-01 08:20:00	2026-04-06 21:00:00	\N	\N	2026-04-07	445000.00	2026-04-01	2026-04-06 21:00:00	\N	CASH	f	16400000.00	450000.00	PAID	17685000.00	\N	200000.00	190000.00	b6000000-0000-0000-0000-000000000011	b5000000-0000-0000-0000-000000000017
b7000000-0000-0000-0000-000000000019	2026-05-01 08:20:00	2026-05-07 10:10:00	\N	\N	2026-05-07	470000.00	2026-05-01	2026-05-07 10:10:00	\N	CASH	f	16400000.00	450000.00	PAID	17729000.00	\N	200000.00	209000.00	b6000000-0000-0000-0000-000000000011	b5000000-0000-0000-0000-000000000017
b7000000-0000-0000-0000-000000000020	2026-06-01 08:20:00	2026-06-20 08:20:00	\N	\N	2026-06-10	498000.00	2026-06-01	\N	\N	\N	f	16400000.00	450000.00	OVERDUE	17776000.00	\N	200000.00	228000.00	b6000000-0000-0000-0000-000000000011	b5000000-0000-0000-0000-000000000017
b7000000-0000-0000-0000-000000000021	2026-04-01 08:25:00	2026-04-03 12:15:00	https://pay.payos.vn/demo/p62811-04	\N	2026-04-07	610000.00	2026-04-01	2026-04-03 12:15:00	PAYOS-DEMO-1804	PAYOS	f	20500000.00	450000.00	PAID	23176000.00	TXN-DEMO-P62811-04	1350000.00	266000.00	b6000000-0000-0000-0000-000000000012	b5000000-0000-0000-0000-000000000018
b7000000-0000-0000-0000-000000000022	2026-05-01 08:25:00	2026-05-05 16:00:00	\N	\N	2026-05-07	640000.00	2026-05-01	2026-05-05 16:00:00	\N	CASH	f	20500000.00	450000.00	PAID	23225000.00	\N	1350000.00	285000.00	b6000000-0000-0000-0000-000000000012	b5000000-0000-0000-0000-000000000018
b7000000-0000-0000-0000-000000000024	2026-04-01 08:30:00	2026-04-06 15:40:00	\N	\N	2026-04-07	292000.00	2026-04-01	2026-04-06 15:40:00	\N	CASH	f	9200000.00	300000.00	PAID	10056000.00	\N	120000.00	144000.00	b6000000-0000-0000-0000-000000000013	b5000000-0000-0000-0000-000000000020
b7000000-0000-0000-0000-000000000025	2026-05-01 08:30:00	2026-05-06 11:15:00	https://pay.payos.vn/demo/a10612-05	\N	2026-05-07	315000.00	2026-05-01	2026-05-06 11:15:00	PAYOS-DEMO-2005	PAYOS	f	9200000.00	300000.00	PAID	10097000.00	TXN-DEMO-A10612-05	120000.00	162000.00	b6000000-0000-0000-0000-000000000013	b5000000-0000-0000-0000-000000000020
b7000000-0000-0000-0000-000000000027	2026-04-01 08:35:00	2026-04-04 10:30:00	\N	\N	2026-04-07	315000.00	2026-04-01	2026-04-04 10:30:00	\N	CASH	f	10100000.00	300000.00	PAID	10979000.00	\N	120000.00	144000.00	b6000000-0000-0000-0000-000000000014	b5000000-0000-0000-0000-000000000021
b7000000-0000-0000-0000-000000000028	2026-05-01 08:35:00	2026-05-18 08:35:00	\N	\N	2026-05-07	342000.00	2026-05-01	\N	\N	\N	f	10100000.00	300000.00	OVERDUE	11024000.00	\N	120000.00	162000.00	b6000000-0000-0000-0000-000000000014	b5000000-0000-0000-0000-000000000021
b7000000-0000-0000-0000-000000000030	2026-04-01 08:40:00	2026-04-05 08:50:00	https://pay.payos.vn/demo/a12806-04	\N	2026-04-07	395000.00	2026-04-01	2026-04-05 08:50:00	PAYOS-DEMO-2204	PAYOS	f	12600000.00	300000.00	PAID	13595000.00	TXN-DEMO-A12806-04	120000.00	180000.00	b6000000-0000-0000-0000-000000000015	b5000000-0000-0000-0000-000000000022
b7000000-0000-0000-0000-000000000031	2026-05-01 08:40:00	2026-05-07 19:00:00	\N	\N	2026-05-07	422000.00	2026-05-01	2026-05-07 19:00:00	\N	CASH	f	12600000.00	300000.00	PAID	13640000.00	\N	120000.00	198000.00	b6000000-0000-0000-0000-000000000015	b5000000-0000-0000-0000-000000000022
b7000000-0000-0000-0000-000000000033	2026-04-01 08:45:00	2026-04-03 18:00:00	\N	\N	2026-04-07	330000.00	2026-04-01	2026-04-03 18:00:00	\N	CASH	f	10300000.00	320000.00	PAID	11218000.00	\N	120000.00	148000.00	b6000000-0000-0000-0000-000000000016	b5000000-0000-0000-0000-000000000024
b7000000-0000-0000-0000-000000000034	2026-05-01 08:45:00	2026-05-06 22:00:00	https://pay.payos.vn/demo/ld0506-05	\N	2026-05-07	350000.00	2026-05-01	2026-05-06 22:00:00	PAYOS-DEMO-2405	PAYOS	f	10300000.00	320000.00	PAID	11256000.00	TXN-DEMO-LD0506-05	120000.00	166000.00	b6000000-0000-0000-0000-000000000016	b5000000-0000-0000-0000-000000000024
b7000000-0000-0000-0000-000000000036	2026-04-01 08:50:00	2026-04-07 09:30:00	\N	\N	2026-04-07	380000.00	2026-04-01	2026-04-07 09:30:00	\N	CASH	f	12700000.00	320000.00	PAID	13705000.00	\N	120000.00	185000.00	b6000000-0000-0000-0000-000000000017	b5000000-0000-0000-0000-000000000025
b7000000-0000-0000-0000-000000000037	2026-05-01 08:50:00	2026-05-05 14:30:00	\N	\N	2026-05-07	403000.00	2026-05-01	2026-05-05 14:30:00	\N	CASH	f	12700000.00	320000.00	PAID	13746000.00	\N	120000.00	203000.00	b6000000-0000-0000-0000-000000000017	b5000000-0000-0000-0000-000000000025
b7000000-0000-0000-0000-000000000038	2026-06-01 08:50:00	2026-06-18 08:50:00	\N	\N	2026-06-10	429000.00	2026-06-01	\N	\N	\N	f	12700000.00	320000.00	OVERDUE	13791000.00	\N	120000.00	222000.00	b6000000-0000-0000-0000-000000000017	b5000000-0000-0000-0000-000000000025
b7000000-0000-0000-0000-000000000002	2026-06-30 08:30:00	2026-07-27 08:00:00.602685	\N	\N	2026-07-05	452000.00	2026-06-01	\N	\N	\N	f	14800000.00	350000.00	OVERDUE	15932000.00	\N	120000.00	210000.00	b6000000-0000-0000-0000-000000000002	b5000000-0000-0000-0000-000000000002
b7000000-0000-0000-0000-000000000004	2026-06-30 09:10:00	2026-07-27 08:00:00.602805	\N	\N	2026-07-05	510000.00	2026-06-01	\N	\N	\N	f	18900000.00	450000.00	OVERDUE	21475000.00	\N	1350000.00	265000.00	b6000000-0000-0000-0000-000000000004	b5000000-0000-0000-0000-000000000005
b7000000-0000-0000-0000-000000000008	2026-06-30 08:00:00	2026-07-27 08:00:00.604254	\N	\N	2026-07-05	380000.00	2026-06-01	\N	\N	\N	f	10900000.00	350000.00	OVERDUE	11935000.00	\N	120000.00	185000.00	b6000000-0000-0000-0000-000000000007	b5000000-0000-0000-0000-000000000012
b7000000-0000-0000-0000-000000000011	2026-06-30 08:05:00	2026-07-27 08:00:00.604299	\N	\N	2026-07-05	421000.00	2026-06-01	\N	\N	\N	f	12800000.00	350000.00	OVERDUE	13876000.00	\N	120000.00	185000.00	b6000000-0000-0000-0000-000000000008	b5000000-0000-0000-0000-000000000013
b7000000-0000-0000-0000-000000000014	2026-06-30 08:10:00	2026-07-27 08:00:00.604341	\N	\N	2026-07-05	551000.00	2026-06-01	\N	\N	\N	f	16200000.00	350000.00	OVERDUE	17600000.00	\N	240000.00	259000.00	b6000000-0000-0000-0000-000000000009	b5000000-0000-0000-0000-000000000014
b7000000-0000-0000-0000-000000000017	2026-06-30 08:15:00	2026-07-27 08:00:00.604365	\N	\N	2026-07-05	429000.00	2026-06-01	\N	\N	\N	f	13900000.00	450000.00	OVERDUE	15157000.00	\N	150000.00	228000.00	b6000000-0000-0000-0000-000000000010	b5000000-0000-0000-0000-000000000016
b7000000-0000-0000-0000-000000000023	2026-06-30 08:25:00	2026-07-27 08:00:00.604999	\N	\N	2026-07-05	675000.00	2026-06-01	\N	\N	\N	f	20500000.00	450000.00	OVERDUE	23279000.00	\N	1350000.00	304000.00	b6000000-0000-0000-0000-000000000012	b5000000-0000-0000-0000-000000000018
b7000000-0000-0000-0000-000000000026	2026-06-30 08:30:00	2026-07-27 08:00:00.605034	\N	\N	2026-07-05	338000.00	2026-06-01	\N	\N	\N	f	9200000.00	300000.00	OVERDUE	10138000.00	\N	120000.00	180000.00	b6000000-0000-0000-0000-000000000013	b5000000-0000-0000-0000-000000000020
b7000000-0000-0000-0000-000000000029	2026-06-30 08:35:00	2026-07-27 08:00:00.60506	\N	\N	2026-07-05	365000.00	2026-06-01	\N	\N	\N	f	10100000.00	300000.00	OVERDUE	11065000.00	\N	120000.00	180000.00	b6000000-0000-0000-0000-000000000014	b5000000-0000-0000-0000-000000000021
b7000000-0000-0000-0000-000000000032	2026-06-30 08:40:00	2026-07-27 08:00:00.605082	\N	\N	2026-07-05	448000.00	2026-06-01	\N	\N	\N	f	12600000.00	300000.00	OVERDUE	13684000.00	\N	120000.00	216000.00	b6000000-0000-0000-0000-000000000015	b5000000-0000-0000-0000-000000000022
b7000000-0000-0000-0000-000000000035	2026-06-30 08:45:00	2026-07-27 08:00:00.605106	\N	\N	2026-07-05	372000.00	2026-06-01	\N	\N	\N	f	10300000.00	320000.00	OVERDUE	11297000.00	\N	120000.00	185000.00	b6000000-0000-0000-0000-000000000016	b5000000-0000-0000-0000-000000000024
9f0fb102-65c1-4983-a6c4-792ad48b4571	2026-07-26 16:12:04.409994	2026-07-27 08:00:00.60513	\N	\N	2026-07-10	752400.00	2026-07-01	\N	\N	\N	f	12200000.00	350000.00	OVERDUE	13302400.00	\N	0.00	0.00	b6000000-0000-0000-0000-000000000001	b5000000-0000-0000-0000-000000000001
c979cd05-f5aa-4903-8f9d-29e3e743ee51	2026-08-06 15:11:09.193839	2026-08-06 15:13:20.058804	https://pay.payos.vn/web/16e8120d192a4c0c9ad46c60c389684f	\N	2026-08-10	68400.00	2026-08-01	2026-08-06 15:13:20.058546	5459554155898706	CASH	f	6500000.00	0.00	PAID	6768400.00	\N	0.00	200000.00	3f3987fa-7c26-48dd-96a1-b78c8237e4fe	3697261c-44e6-4b47-9b9d-25277cc8da51
644f40d3-4f99-4d66-be61-6b855a095f31	2026-07-27 08:46:17.420669	2026-07-28 01:51:29.882922	\N	5	2026-07-10	0.00	2026-07-01	2026-07-28 01:51:29.882676	\N	CASH	t	806451.61	210000.00	PAID	1016451.61	\N	0.00	0.00	3cb0c43a-de37-4c89-bf35-d4b88408bc72	26962280-8932-4cc6-b92f-ac0b9a570cd0
f04eb140-899d-4bdb-b58c-4e30e87784d0	2026-08-04 07:27:40.213868	2026-08-19 06:52:28.956962	https://pay.payos.vn/web/c809e73e0b6341e9ba979977c81b1cea	\N	2026-08-10	272000.00	2026-08-01	2026-08-19 06:52:28.95474	4860992243093259	CASH	f	18900000.00	450000.00	PAID	20762000.00	\N	0.00	1140000.00	b6000000-0000-0000-0000-000000000004	b5000000-0000-0000-0000-000000000005
a6471a5a-9a29-4d2e-9574-15a7d8d08520	2026-08-02 07:41:25.419015	2026-08-02 07:42:59.116487	\N	\N	2026-08-10	0.00	2026-08-01	2026-08-02 07:42:59.116206	\N	CASH	f	5000000.00	210000.00	PAID	5210000.00	\N	0.00	0.00	3cb0c43a-de37-4c89-bf35-d4b88408bc72	26962280-8932-4cc6-b92f-ac0b9a570cd0
7c135337-f51e-49fa-8731-3768446542f0	2026-08-01 13:06:24.379574	2026-08-19 06:52:35.533436	https://pay.payos.vn/web/4bbe1a7fcd5d44799bf553c86bc0ff85	\N	2026-08-10	68400.00	2026-08-01	2026-08-19 06:52:35.532838	6136614890375946	CASH	f	12200000.00	350000.00	PAID	12988400.00	\N	0.00	370000.00	b6000000-0000-0000-0000-000000000001	b5000000-0000-0000-0000-000000000001
cdba4b04-3ca8-4996-833c-0048bf68296d	2026-08-02 07:40:28.677729	2026-08-11 08:00:01.679824	\N	\N	2026-08-10	6200000.00	2026-08-01	\N	\N	\N	f	16400000.00	450000.00	OVERDUE	61050000.00	\N	0.00	38000000.00	b6000000-0000-0000-0000-000000000011	b5000000-0000-0000-0000-000000000017
f3b06edb-008c-4358-b278-d76c46356885	2026-08-05 04:10:51.60603	2026-08-05 04:42:45.506117	\N	\N	2026-08-10	0.00	2026-08-01	2026-08-05 04:42:45.464742	\N	CASH	f	12200000.00	210000.00	PAID	12410000.00	\N	0.00	0.00	6e6f011b-8790-473c-a38c-7157ba2c5f44	95192562-e587-4da2-bac0-46d29aa261e9
90778511-703a-4e87-be04-1223be4918c2	2026-08-06 15:16:58.244723	2026-08-11 08:00:01.679912	https://pay.payos.vn/web/29e320101aca4617a7dc5bcfc2ddf8a2	\N	2026-08-10	0.00	2026-08-01	\N	8185192534234693	\N	f	1000.00	0.00	OVERDUE	101000.00	\N	0.00	100000.00	0f230080-634c-4f81-90bf-b1a70e178077	ce27f631-b495-48aa-9fc5-c60ec18a95eb
f1b6bd6a-59bf-442c-92f9-1a90b2ab8a31	2026-08-05 05:46:18.714181	2026-08-05 05:54:39.924375	\N	27	2026-08-10	0.00	2026-08-01	2026-08-05 05:54:39.924145	\N	CASH	t	5225806.45	0.00	PAID	5225806.45	\N	0.00	0.00	1140f21c-c699-47f3-92ee-b1b31501daef	e3d6477b-41ee-4b21-af42-6a9f042e6d08
8e596cb3-e94a-48fe-9954-844e520f2e1c	2026-08-04 07:27:40.70677	2026-08-11 08:00:01.679938	\N	\N	2026-08-10	285000.00	2026-08-01	\N	\N	\N	f	10500000.00	300000.00	OVERDUE	11499000.00	\N	0.00	414000.00	b6000000-0000-0000-0000-000000000005	b5000000-0000-0000-0000-000000000007
95fa58e3-2f13-410b-80c7-159fec6186f9	2026-08-05 06:01:41.006326	2026-08-06 15:05:36.231074	\N	\N	2026-08-10	0.00	2026-08-01	2026-08-06 15:05:36.23076	\N	CASH	f	7000000.00	0.00	PAID	7000000.00	\N	0.00	0.00	647600c0-962d-4cb3-9d27-8b1fb0e1d84a	b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6
e36d3e32-acf2-4031-af62-fb8c82b92619	2026-08-04 07:27:41.106897	2026-08-11 08:00:01.679956	\N	\N	2026-08-10	487500.00	2026-08-01	\N	\N	\N	f	11900000.00	320000.00	OVERDUE	14502000.00	\N	0.00	1794500.00	b6000000-0000-0000-0000-000000000006	b5000000-0000-0000-0000-000000000009
fa0879db-1e12-41ee-8fff-f293de4189ef	2026-08-06 12:52:38.622957	2026-08-11 08:00:01.680121	\N	\N	2026-08-10	152000000.00	2026-08-01	\N	\N	\N	f	12800000.00	350000.00	OVERDUE	172550000.00	\N	0.00	7400000.00	b6000000-0000-0000-0000-000000000008	b5000000-0000-0000-0000-000000000013
0dbf774c-2d51-4fe4-854c-54314781e63c	2026-08-06 15:53:10.836963	2026-08-11 08:00:01.679999	https://pay.payos.vn/web/b6af0c78a8f74b34beed11f33fc40ff2	\N	2026-08-10	0.00	2026-08-01	\N	4270230068832728	\N	f	1000.00	0.00	OVERDUE	101000.00	\N	0.00	100000.00	5d82e7d6-1243-41be-be3d-6c493f75ee30	fcf45ae0-98ba-4018-8181-1a9dbab9a472
afbd9554-aa7c-40e1-81ed-6fd768b31b9f	2026-08-05 07:47:48.661835	2026-08-11 08:00:01.680023	\N	\N	2026-08-10	390000.00	2026-08-01	\N	\N	\N	f	10300000.00	320000.00	OVERDUE	12860000.00	\N	0.00	1850000.00	b6000000-0000-0000-0000-000000000016	b5000000-0000-0000-0000-000000000024
f79fb673-1ab6-481f-b2f7-addfcb634def	2026-08-05 07:49:01.228463	2026-08-11 08:00:01.680044	\N	\N	2026-08-10	760000.00	2026-08-01	\N	\N	\N	f	12600000.00	300000.00	OVERDUE	17260000.00	\N	0.00	3600000.00	b6000000-0000-0000-0000-000000000015	b5000000-0000-0000-0000-000000000022
900306d5-a430-49bf-b5c5-d7a3161cad4b	2026-08-06 12:52:38.59384	2026-08-11 08:00:01.680102	\N	\N	2026-08-10	186200000.00	2026-08-01	\N	\N	\N	f	10900000.00	350000.00	OVERDUE	204850000.00	\N	0.00	7400000.00	b6000000-0000-0000-0000-000000000007	b5000000-0000-0000-0000-000000000012
88a58727-f640-496a-b1a3-80cfa3acda4d	2026-08-06 12:52:38.699199	2026-08-11 08:00:01.680141	\N	\N	2026-08-10	152000000.00	2026-08-01	\N	\N	\N	f	16200000.00	350000.00	OVERDUE	175950000.00	\N	0.00	7400000.00	b6000000-0000-0000-0000-000000000009	b5000000-0000-0000-0000-000000000014
37ed8c23-1291-4b04-9b8f-744c89b42b3c	2026-08-06 12:52:38.72828	2026-08-11 08:00:01.680161	\N	\N	2026-08-10	160000000.00	2026-08-01	\N	\N	\N	f	13900000.00	450000.00	OVERDUE	181950000.00	\N	0.00	7600000.00	b6000000-0000-0000-0000-000000000010	b5000000-0000-0000-0000-000000000016
71299135-fa55-482a-9679-bbb4dd57ad17	2026-08-06 12:52:38.89198	2026-08-11 08:00:01.680182	\N	\N	2026-08-10	160000000.00	2026-08-01	\N	\N	\N	f	20500000.00	450000.00	OVERDUE	188550000.00	\N	0.00	7600000.00	b6000000-0000-0000-0000-000000000012	b5000000-0000-0000-0000-000000000018
c2170b99-cd9f-430c-ba4e-a8e51293fd6e	2026-08-06 12:52:38.927465	2026-08-11 08:00:01.680201	\N	\N	2026-08-10	152000000.00	2026-08-01	\N	\N	\N	f	10100000.00	300000.00	OVERDUE	169600000.00	\N	0.00	7200000.00	b6000000-0000-0000-0000-000000000014	b5000000-0000-0000-0000-000000000021
1f86bcfd-5c7b-480c-9388-d9e9f53abb33	2026-08-06 12:52:39.098371	2026-08-11 08:00:01.680285	\N	\N	2026-08-10	156000000.00	2026-08-01	\N	\N	\N	f	12700000.00	320000.00	OVERDUE	176420000.00	\N	0.00	7400000.00	b6000000-0000-0000-0000-000000000017	b5000000-0000-0000-0000-000000000025
43a1debd-e6d3-4752-ad27-a68df77cfe0f	2026-08-06 12:52:39.399184	2026-08-11 08:00:01.680344	\N	28	2026-08-10	152000000.00	2026-08-01	\N	\N	\N	t	10477419.35	350000.00	OVERDUE	170227419.35	\N	0.00	7400000.00	df54e252-b333-43f9-81da-42b0a5b9731e	b5000000-0000-0000-0000-000000000003
eaee2c21-c729-4dc2-8f61-539fd6721831	2026-08-06 12:52:39.428266	2026-08-11 08:00:01.680373	\N	28	2026-08-10	152000000.00	2026-08-01	\N	\N	\N	t	13367741.94	350000.00	OVERDUE	173117741.94	\N	0.00	7400000.00	95a1bfda-d60e-4a4e-922b-4416d51f7596	b5000000-0000-0000-0000-000000000002
cc0cd89c-886d-476e-a9f2-6a4a2649bb01	2026-08-04 07:27:40.002923	2026-08-19 06:52:33.960262	https://pay.payos.vn/web/f661fde36b8c4e1caada7392bd405c1d	\N	2026-08-10	316000.00	2026-08-01	2026-08-19 06:52:33.959718	5508277029633135	CASH	f	15200000.00	450000.00	PAID	16593000.00	\N	0.00	627000.00	b6000000-0000-0000-0000-000000000003	b5000000-0000-0000-0000-000000000004
630256f4-8c34-4f40-b621-917edd5dd826	2026-08-19 06:57:24.855187	2026-08-19 06:58:04.648708	\N	\N	2026-09-10	3800.00	2026-09-01	2026-08-19 06:58:04.6483	\N	CASH	f	12200000.00	350000.00	PAID	12572300.00	\N	0.00	18500.00	d334e2a7-af01-497c-8496-eff8a4751708	b5000000-0000-0000-0000-000000000001
\.


--
-- Data for Name: maintenance_completion_images; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.maintenance_completion_images (request_id, image_url) FROM stdin;
7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185	https://pub-1415da6044694261bf385af30f6ca53a.r2.dev/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/completion/2642929e-8cd8-423d-a2f0-1cc0a6384064.jpg
69839fb2-7b7c-41fe-9a50-431b132a54ce	https://pub-1415da6044694261bf385af30f6ca53a.r2.dev/maintenance/69839fb2-7b7c-41fe-9a50-431b132a54ce/completion/2f30d99d-3134-4959-a218-2b883e3b1604.JPG
69839fb2-7b7c-41fe-9a50-431b132a54ce	https://pub-1415da6044694261bf385af30f6ca53a.r2.dev/maintenance/69839fb2-7b7c-41fe-9a50-431b132a54ce/completion/82c4c466-2bbb-4f95-ab24-cf9c7c38d481.png
db9a9713-3331-441f-84c5-ea3e5abb1197	https://pub-1415da6044694261bf385af30f6ca53a.r2.dev/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion/a5f2310b-0dcc-498d-83b6-1af0ebe3dfac.jpg
0f0f870b-8625-4306-84b4-61e3c78ae7e2	https://pub-1415da6044694261bf385af30f6ca53a.r2.dev/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/completion/8ad54522-d18e-45fd-83ac-e6edb0c3a905.jpg
b7a2d2ad-c428-4c0d-8802-256afd8979d4	https://pub-1415da6044694261bf385af30f6ca53a.r2.dev/maintenance/b7a2d2ad-c428-4c0d-8802-256afd8979d4/completion/a6a3834d-6611-4067-b17b-0f16f1231aa1.png
\.


--
-- Data for Name: maintenance_images; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.maintenance_images (request_id, image_url) FROM stdin;
b8000000-0000-0000-0000-000000000001	https://images.unsplash.com/photo-1505693416388-ac5ce068fe85
b8000000-0000-0000-0000-000000000002	https://images.unsplash.com/photo-1484154218962-a197022b5858
afc5b633-7812-4726-ad5d-a1de1587fadd	https://8f63bd728b52c55ace816a5f64c6d5fe.r2.cloudflarestorage.com/htr-minio/maintenance/afc5b633-7812-4726-ad5d-a1de1587fadd/9fc74627-c345-424d-97e7-cdaa78ec3420.png
2bee013f-38eb-4113-a2e0-a67a9385fe71	https://8f63bd728b52c55ace816a5f64c6d5fe.r2.cloudflarestorage.com/htr-minio/maintenance/2bee013f-38eb-4113-a2e0-a67a9385fe71/526b6a2e-8c3e-4ad9-853e-35d378c765e0.png
a1dc49c3-f49f-4a54-a478-20c063c80cc6	https://8f63bd728b52c55ace816a5f64c6d5fe.r2.cloudflarestorage.com/htr-minio/maintenance/a1dc49c3-f49f-4a54-a478-20c063c80cc6/be5b3ecf-29fe-48dd-b528-3afadfd2c847.jpg
85ae8e7b-b3f2-4640-9ace-f8fa69761a9d	https://8f63bd728b52c55ace816a5f64c6d5fe.r2.cloudflarestorage.com/htr-minio/maintenance/85ae8e7b-b3f2-4640-9ace-f8fa69761a9d/fe78466d-84f9-4304-bb3d-8df3057d2233.jpg
69839fb2-7b7c-41fe-9a50-431b132a54ce	https://pub-1415da6044694261bf385af30f6ca53a.r2.dev/maintenance/pending-03134da6-90b2-4faa-a87c-ac9734045826/4cfd9783-933f-4ae8-93b4-82eaf5ec4b60.jpg
b7a2d2ad-c428-4c0d-8802-256afd8979d4	https://pub-1415da6044694261bf385af30f6ca53a.r2.dev/maintenance/pending-3fd6cfbb-67a7-4937-b113-7c9f15c1ae2c/55f0faaf-6e01-47c5-92aa-00a7573b705b.png
\.


--
-- Data for Name: maintenance_materials; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.maintenance_materials (id, created_at, updated_at, is_free_in_contract, name, quantity, total_price, unit, unit_price, request_id) FROM stdin;
b4f9acc8-e9c9-4cb7-91d7-fb540f0c2498	2026-07-31 07:09:54.794358	2026-07-31 07:09:54.794358	f	Ông nước 1	1	50000.00	cái	50000.00	8721cde2-53f1-478e-842d-63cef0d8e17a
e4e2671e-a768-4da4-be33-3a1415243b94	2026-07-31 07:10:08.671249	2026-07-31 07:10:08.671249	f	Dây điện	5	625000.00	m	125000.00	8721cde2-53f1-478e-842d-63cef0d8e17a
69f7a7c5-7a12-4920-93ba-9ff026eac722	2026-08-02 03:15:55.965197	2026-08-02 03:15:55.965197	t	Ống nối nước	2	20000.00	cái	10000.00	8721cde2-53f1-478e-842d-63cef0d8e17a
e788665b-c38b-406e-955b-ab35359ed208	2026-08-04 08:01:57.802782	2026-08-04 08:01:57.802782	t	bóng đèn trần	1	0.00	cái	0.00	2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9
ec8c2bb7-d7dd-4dc9-9455-9b8d1f1c7c6e	2026-08-04 08:59:28.706968	2026-08-04 08:59:28.706968	f	Cao su non	1	5000.00	cuộn	5000.00	92b4e6ca-0abe-429e-8385-18666f89cd13
e5b2f4f8-4a25-42c4-8207-3a3840b9e349	2026-08-05 03:04:19.857007	2026-08-05 03:04:19.857007	f	Bản lề cửa	2	70000.00	cái	35000.00	babc7312-1c6f-4670-8297-351d392a1996
4741e076-5406-4757-b14d-2c432d943e74	2026-08-05 03:30:23.914142	2026-08-05 03:30:23.914142	f	ống thoát nước	1	40000.00	cái	40000.00	db9a9713-3331-441f-84c5-ea3e5abb1197
9adb66db-0e7e-4762-8229-12b26d4e5c0e	2026-08-05 03:31:33.565032	2026-08-05 03:31:33.565032	f	tiền công vệ sinh	1	200000.00	cái	200000.00	db9a9713-3331-441f-84c5-ea3e5abb1197
7f5b6173-e579-4bcc-8de6-20dbbc7c5c03	2026-08-05 03:40:42.547894	2026-08-05 03:40:42.547894	t	ống máy lạnh	1	10000.00	cái	10000.00	db9a9713-3331-441f-84c5-ea3e5abb1197
3971178d-2b20-4981-9ddb-d520e006f8df	2026-08-05 03:55:44.583629	2026-08-05 03:55:44.583629	f	dây điện	1	20000.00	cái	20000.00	0f0f870b-8625-4306-84b4-61e3c78ae7e2
326a3f72-ee03-4d6d-8e87-12c14ece8306	2026-08-05 03:56:31.580689	2026-08-05 03:56:31.580689	t	bóng đèn	1	10000.00	cái	10000.00	0f0f870b-8625-4306-84b4-61e3c78ae7e2
a725060f-841b-41bc-972d-0654a08b3fe7	2026-08-05 04:00:56.987751	2026-08-05 04:00:56.987751	f	Công thông cống	1	80000.00	cái	80000.00	b7b0c13c-2dbe-4d08-b81c-032624bfe278
6ff6d2c5-e8f2-4caa-94b8-c7ca81ef61e2	2026-08-05 04:07:11.267353	2026-08-05 04:07:11.267353	f	tiền vệ sinh	1	200000.00	cái	200000.00	c5615cfe-4f1a-4a3f-86b1-3727c9a02d68
7e245b96-9835-408d-ac62-93a2c619f76b	2026-08-05 04:35:45.883585	2026-08-05 04:35:45.883585	f	gas máy lạnh	1	150000.00	cái	150000.00	60dab198-f686-47d1-9656-6b7314fbeae3
290e0096-d17f-4303-942e-e6d8bbb1d439	2026-08-05 06:26:47.62025	2026-08-05 06:26:47.62025	t	Bản lề nhà vệ sinh	1	0.00	cái	0.00	483e9cdc-246b-48a5-9a8f-2327910f2b03
1acb6b0a-6dfb-4301-b538-ff3eed38cd7f	2026-08-09 16:05:19.488659	2026-08-09 16:05:19.488659	f	CP	1	50000.00	cái	50000.00	849c05ad-e3b6-4c8b-9f10-3db67d42a9e6
31081827-89c4-458a-b512-3a3c7832122c	2026-08-19 07:07:38.259728	2026-08-19 07:07:38.259728	f	Cp mới	1	50000.00	cái	50000.00	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185
\.


--
-- Data for Name: maintenance_notes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.maintenance_notes (id, created_at, updated_at, note, status, actor_id, request_id) FROM stdin;
2c2aab71-d9fa-4ba1-8f29-b806d46ff9a9	2026-07-27 06:53:31.704607	2026-07-27 06:53:31.704607	Tạo yêu cầu bảo trì mã MNT-20260727-808 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	2e661bb3-5cf3-462f-9cde-510a75a5d1a3
c7431650-4167-4b7e-8c53-ad3202aae1fd	2026-07-27 06:53:33.210217	2026-07-27 06:53:33.210217	Tạo yêu cầu bảo trì mã MNT-20260727-809 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	300cfc87-df62-4a88-9887-9034ad1266d5
a606bf7b-9f1a-47a4-9808-16c6493e0ecb	2026-07-27 06:53:39.606487	2026-07-27 06:53:39.606487	Tạo yêu cầu bảo trì mã MNT-20260727-810 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	04a53e7e-15a4-4a9d-afed-567596ae20c6
397231b4-01f6-49df-8085-f507012370db	2026-07-27 06:53:40.185137	2026-07-27 06:53:40.185137	Tạo yêu cầu bảo trì mã MNT-20260727-811 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	aa5bed2d-405c-4a8b-8ce3-bb9bfef19dfb
82b33a16-4954-4707-bbb6-46d8655299f6	2026-07-27 06:53:59.008056	2026-07-27 06:53:59.008056	Tạo yêu cầu bảo trì mã MNT-20260727-812 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	f9c6f0d8-16f0-483f-b043-d2e389493f60
b80c862f-871a-4f66-a132-eff6a4ccf1c0	2026-07-27 06:53:59.509208	2026-07-27 06:53:59.509208	Tạo yêu cầu bảo trì mã MNT-20260727-813 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	ed7264e5-49b9-43c1-9d82-2f63c8019d6e
d05ef54e-a36c-4504-8118-63df226a8bc8	2026-07-27 06:57:48.952982	2026-07-27 06:57:48.952982	Tạo yêu cầu bảo trì mã MNT-20260727-814 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	caf31977-a7ff-49eb-8166-c8e852487a09
d0a93594-1d46-4e23-9a92-2b758b195aa1	2026-07-27 06:57:49.408343	2026-07-27 06:57:49.408343	Tạo yêu cầu bảo trì mã MNT-20260727-815 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	8ce7171e-c161-4408-a821-3b0aed85847c
3c636877-8430-4556-bcc5-e7a0e408bfbb	2026-07-27 06:58:57.909226	2026-07-27 06:58:57.909226	Tạo yêu cầu bảo trì mã MNT-20260727-816 (HIGH)	OPEN	b1000000-0000-0000-0000-000000000002	536a593e-7fa7-4273-bcbd-bb776de0254e
2dc4249e-cb40-44b9-a09c-828598f13a56	2026-07-27 06:58:58.440907	2026-07-27 06:58:58.440907	Tạo yêu cầu bảo trì mã MNT-20260727-817 (HIGH)	OPEN	b1000000-0000-0000-0000-000000000002	dd480a87-1683-40f9-9839-48a4770ebebb
c2147bd7-2e64-4fb2-b558-84bf1fd3c111	2026-07-27 06:59:03.005756	2026-07-27 06:59:03.005756	Tạo yêu cầu bảo trì mã MNT-20260727-818 (HIGH)	OPEN	b1000000-0000-0000-0000-000000000002	84941eb2-0626-4f31-a574-745466e0a083
a2475c49-6e27-4d2e-afc6-d5495bad2e7d	2026-07-27 06:59:03.458322	2026-07-27 06:59:03.458322	Tạo yêu cầu bảo trì mã MNT-20260727-819 (HIGH)	OPEN	b1000000-0000-0000-0000-000000000002	a3ed57fb-af95-4f3d-9b8d-c8b24b7a4f3c
5823424e-32da-47ee-bd71-fb86b4483fdb	2026-07-27 07:04:09.601359	2026-07-27 07:04:09.601359	Tạo yêu cầu bảo trì mã MNT-20260727-820 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	8f3a647b-4162-4c49-8567-d09c35e04ad2
45a1943f-c510-464a-9dfd-2dcada7a6c47	2026-07-27 07:04:10.039865	2026-07-27 07:04:10.039865	Tạo yêu cầu bảo trì mã MNT-20260727-821 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	f9e43efa-0144-4dbe-820c-59e4141ceeb8
7a20c470-ee33-4a6d-ac9c-9669d0e048ac	2026-07-27 07:04:20.602376	2026-07-27 07:04:20.602376	Tạo yêu cầu bảo trì mã MNT-20260727-822 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	6d2de875-2fdb-45e7-b621-17bd86226815
40125513-e629-4607-8342-2991b3a35302	2026-07-27 07:04:21.010282	2026-07-27 07:04:21.010282	Tạo yêu cầu bảo trì mã MNT-20260727-823 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	08ee7530-a733-485e-b1bd-579a997d77fc
100c4b5f-a837-460f-9692-59b3f10311c9	2026-07-27 07:04:46.638685	2026-07-27 07:04:46.638685	Tạo yêu cầu bảo trì mã MNT-20260727-824 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	e3cbf44f-70c1-4065-b448-bfe6fd3eb84b
843bc7b5-5cbf-4d95-b624-570b57384c1e	2026-07-27 07:04:47.019326	2026-07-27 07:04:47.019326	Tạo yêu cầu bảo trì mã MNT-20260727-825 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	b37d3442-70c1-44a7-8b0f-c16e3d2d05fd
6762cf67-0c3b-45ec-b897-8c8d8e5934cf	2026-07-27 07:04:53.583863	2026-07-27 07:04:53.583863	Tạo yêu cầu bảo trì mã MNT-20260727-826 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	a37395c2-abfd-4627-a2ed-a449d870d276
0c0201c8-be61-4853-b4bd-5eabec3e91bf	2026-07-27 07:04:53.907491	2026-07-27 07:04:53.907491	Tạo yêu cầu bảo trì mã MNT-20260727-827 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	64f5b409-34d7-4499-9ad2-0fa043005180
c4ed344b-9e02-49f2-85e4-26406512247e	2026-07-27 07:05:00.837895	2026-07-27 07:05:00.837895	Tạo yêu cầu bảo trì mã MNT-20260727-828 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	2119d259-d667-4994-8cb4-2d4f7f483e5b
9a598802-68aa-488d-88b3-34fd709d4ece	2026-07-27 07:05:01.608438	2026-07-27 07:05:01.608438	Tạo yêu cầu bảo trì mã MNT-20260727-829 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	ad47bc66-00e6-465f-a441-04449b1d21ad
97219449-9e52-4e59-a00b-d5da1127dbf7	2026-07-27 07:07:52.429611	2026-07-27 07:07:52.429611	Tạo yêu cầu bảo trì mã MNT-20260727-830 (HIGH)	OPEN	b1000000-0000-0000-0000-000000000002	438c33ae-4853-4877-b39c-e7f07ae3e9b4
f605dee5-1e90-461e-a5f3-7799cbc4972a	2026-07-27 07:07:52.977709	2026-07-27 07:07:52.977709	Tạo yêu cầu bảo trì mã MNT-20260727-831 (HIGH)	OPEN	b1000000-0000-0000-0000-000000000002	cbf3b404-01fb-4818-bba9-f0887479ac1d
1ab21ecc-22f9-4db1-85b1-a75798239379	2026-07-27 07:08:15.098513	2026-07-27 07:08:15.098513	Tạo yêu cầu bảo trì mã MNT-20260727-832 (HIGH)	OPEN	b1000000-0000-0000-0000-000000000002	46ef6bd0-e132-490d-8261-763260644448
ea9f7299-8a8f-4e28-bdbc-375c8902681f	2026-07-27 07:08:15.430953	2026-07-27 07:08:15.430953	Tạo yêu cầu bảo trì mã MNT-20260727-833 (HIGH)	OPEN	b1000000-0000-0000-0000-000000000002	757ba10e-11c3-481b-a30b-1b826b7f8ff0
c1a47123-9b36-423d-b51f-3b309935bd70	2026-07-27 07:08:58.513359	2026-07-27 07:08:58.513359	Tạo yêu cầu bảo trì mã MNT-20260727-834 (HIGH)	OPEN	b1000000-0000-0000-0000-000000000002	86d24202-5c2b-480f-beb2-0915096f911e
71435734-0039-4df8-b778-1ff278124550	2026-07-27 07:08:58.850097	2026-07-27 07:08:58.850097	Tạo yêu cầu bảo trì mã MNT-20260727-835 (HIGH)	OPEN	b1000000-0000-0000-0000-000000000002	e0dd70bc-3417-4d3e-aa7c-b7710a2308da
3dd04ac6-6ed8-44cf-b269-51032ffbd6d2	2026-07-27 07:10:13.919858	2026-07-27 07:10:13.919858	Tạo yêu cầu bảo trì mã MNT-20260727-836 (HIGH)	OPEN	b1000000-0000-0000-0000-000000000002	afc5b633-7812-4726-ad5d-a1de1587fadd
a44d1e0e-c6a3-4dac-b01d-0f7eb07f51b3	2026-07-27 07:10:19.207933	2026-07-27 07:10:19.207933	Tạo yêu cầu bảo trì mã MNT-20260727-837 (HIGH)	OPEN	b1000000-0000-0000-0000-000000000002	2bee013f-38eb-4113-a2e0-a67a9385fe71
7594fc00-c4cf-43fd-9e85-efb945c248f0	2026-07-27 09:27:38.237007	2026-07-27 09:27:38.237007	Tạo yêu cầu bảo trì mã MNT-20260727-838 (HIGH)	OPEN	a0000000-0000-0000-0000-000000000002	dc04e66c-f7b1-4bf6-92b7-3128d587dc94
c326e9a0-87d9-4b65-ba1c-561eccb4d7b4	2026-07-27 09:27:40.816306	2026-07-27 09:27:40.816306	Tạo yêu cầu bảo trì mã MNT-20260727-839 (HIGH)	OPEN	a0000000-0000-0000-0000-000000000002	c6587d83-4725-4763-a7f1-fa8288d9b863
05feb587-0623-4a16-beab-a4b411aa88cf	2026-07-27 10:24:19.701215	2026-07-27 10:24:19.701215	Tạo yêu cầu bảo trì mã MNT-20260727-840 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	49fbc40e-667c-4252-9de8-57f155b09e78
13dabaac-03c3-49eb-bb67-c5bf0a3eb58d	2026-07-27 10:24:20.697888	2026-07-27 10:24:20.697888	Tạo yêu cầu bảo trì mã MNT-20260727-841 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	e5e71416-e20c-4297-bc9b-64733d07f45f
ab32d357-7930-4abd-9bc8-3289d6270bc4	2026-07-27 10:25:31.536255	2026-07-27 10:25:31.536255	Tạo yêu cầu bảo trì mã MNT-20260727-842 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	a1dc49c3-f49f-4a54-a478-20c063c80cc6
c3096072-0cb8-4ef0-a77f-2db3e9a2be7e	2026-07-27 10:25:34.729101	2026-07-27 10:25:34.729101	Tạo yêu cầu bảo trì mã MNT-20260727-843 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	85ae8e7b-b3f2-4640-9ace-f8fa69761a9d
b75352ad-c9b5-4c52-b942-d08ed8885b64	2026-07-27 13:08:27.191277	2026-07-27 13:08:27.191277	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-27T12:58:57.908348)	OPEN	\N	536a593e-7fa7-4273-bcbd-bb776de0254e
7e8ea7e4-3831-4609-a488-96bb1ac4c3b0	2026-07-27 13:08:27.192857	2026-07-27 13:08:27.192857	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-27T12:58:58.439841)	OPEN	\N	dd480a87-1683-40f9-9839-48a4770ebebb
8afaac64-46a8-4b63-8117-41054946fb7a	2026-07-27 13:08:27.193191	2026-07-27 13:08:27.193191	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-27T12:59:03.004817)	OPEN	\N	84941eb2-0626-4f31-a574-745466e0a083
97bd4a63-a0ef-4734-a8b2-9f28c81c49e4	2026-07-27 13:08:27.193409	2026-07-27 13:08:27.193409	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-27T12:59:03.457494)	OPEN	\N	a3ed57fb-af95-4f3d-9b8d-c8b24b7a4f3c
0b09bc4e-e21d-4c49-979a-19dee5fee883	2026-07-27 13:08:27.193608	2026-07-27 13:08:27.193608	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-27T13:07:52.428704)	OPEN	\N	438c33ae-4853-4877-b39c-e7f07ae3e9b4
d759560d-7de2-47ab-a6e4-1d8f0493bff1	2026-07-27 13:08:27.1938	2026-07-27 13:08:27.1938	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-27T13:07:52.976902)	OPEN	\N	cbf3b404-01fb-4818-bba9-f0887479ac1d
15639d3c-1aa7-4e9a-b723-4e10a13afba6	2026-07-27 13:08:27.194028	2026-07-27 13:08:27.194028	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-27T13:08:15.097635)	OPEN	\N	46ef6bd0-e132-490d-8261-763260644448
abde343a-ccb1-4fe3-b8f2-ac27ade0e0dd	2026-07-27 13:08:27.194621	2026-07-27 13:08:27.194621	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-27T13:08:15.429927)	OPEN	\N	757ba10e-11c3-481b-a30b-1b826b7f8ff0
4ed44b95-628a-43ed-9b0c-d6af118aeea7	2026-07-27 13:38:27.425886	2026-07-27 13:38:27.425886	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-27T13:08:58.512633)	OPEN	\N	86d24202-5c2b-480f-beb2-0915096f911e
e66d4edc-e8af-465b-acde-5d3cdaae040b	2026-07-27 13:38:27.42635	2026-07-27 13:38:27.42635	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-27T13:08:58.849179)	OPEN	\N	e0dd70bc-3417-4d3e-aa7c-b7710a2308da
903d15ee-b8fa-4851-b257-64490fb66feb	2026-07-27 13:38:27.426621	2026-07-27 13:38:27.426621	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-27T13:10:13.918996)	OPEN	\N	afc5b633-7812-4726-ad5d-a1de1587fadd
4a058fe1-f5ac-45cc-ad58-006d59330ac1	2026-07-27 13:38:27.426829	2026-07-27 13:38:27.426829	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-27T13:10:19.207190)	OPEN	\N	2bee013f-38eb-4113-a2e0-a67a9385fe71
50158f73-9430-41a2-ad78-652e978f63b6	2026-07-27 15:38:27.51873	2026-07-27 15:38:27.51873	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-27T15:27:38.236285)	OPEN	\N	dc04e66c-f7b1-4bf6-92b7-3128d587dc94
7b166562-b084-446e-b47f-39c519333e93	2026-07-27 15:38:29.100905	2026-07-27 15:38:29.100905	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-27T15:27:40.815658)	OPEN	\N	c6587d83-4725-4763-a7f1-fa8288d9b863
e94140c8-2a9d-4cd0-aba1-4f6ec1810f72	2026-07-28 07:08:30.206938	2026-07-28 07:08:30.206938	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-28T06:53:31.610002)	OPEN	\N	2e661bb3-5cf3-462f-9cde-510a75a5d1a3
243e0e7b-cb88-4ab7-bda7-104b1e9a75a4	2026-07-28 07:08:30.302714	2026-07-28 07:08:30.302714	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-28T06:53:33.209308)	OPEN	\N	300cfc87-df62-4a88-9887-9034ad1266d5
916401d0-6e2b-4e61-84c0-d4b26df6ff86	2026-07-28 07:08:30.303878	2026-07-28 07:08:30.303878	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-28T06:53:39.605437)	OPEN	\N	04a53e7e-15a4-4a9d-afed-567596ae20c6
52158d30-dc07-4452-bbe6-2d512a6674ef	2026-07-28 07:08:30.30477	2026-07-28 07:08:30.30477	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-28T06:53:40.184142)	OPEN	\N	aa5bed2d-405c-4a8b-8ce3-bb9bfef19dfb
0774b05f-a26c-406c-9aa4-982d47d98ed8	2026-07-28 07:08:30.40211	2026-07-28 07:08:30.40211	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-28T06:53:59.007012)	OPEN	\N	f9c6f0d8-16f0-483f-b043-d2e389493f60
2915bf47-f0bf-4dd0-899c-f2ebb1f5038f	2026-07-28 07:08:30.603236	2026-07-28 07:08:30.603236	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-28T06:53:59.508061)	OPEN	\N	ed7264e5-49b9-43c1-9d82-2f63c8019d6e
72b6fd7a-5e6f-4962-b548-4316354a0110	2026-07-28 07:08:30.604118	2026-07-28 07:08:30.604118	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-28T06:57:48.952294)	OPEN	\N	caf31977-a7ff-49eb-8166-c8e852487a09
dae448b4-2cb8-481d-a9c8-484fd1e315e6	2026-07-28 07:08:30.604649	2026-07-28 07:08:30.604649	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-28T06:57:49.406042)	OPEN	\N	8ce7171e-c161-4408-a821-3b0aed85847c
efe4178d-5e28-4600-b72e-1e3d2ac7a225	2026-07-28 07:08:30.605253	2026-07-28 07:08:30.605253	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-28T07:04:09.581064)	OPEN	\N	8f3a647b-4162-4c49-8567-d09c35e04ad2
72fb488a-642e-4aa2-9f20-b1bc65818256	2026-07-28 07:08:30.605658	2026-07-28 07:08:30.605658	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-28T07:04:10.038933)	OPEN	\N	f9e43efa-0144-4dbe-820c-59e4141ceeb8
f85256e9-ad58-41cb-98c8-5de7113a5f75	2026-07-28 07:08:30.701161	2026-07-28 07:08:30.701161	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-28T07:04:20.601223)	OPEN	\N	6d2de875-2fdb-45e7-b621-17bd86226815
5d9bff3a-8a33-410b-94ed-c31cc6d4925c	2026-07-28 07:08:30.702181	2026-07-28 07:08:30.702181	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-28T07:04:21.009118)	OPEN	\N	08ee7530-a733-485e-b1bd-579a997d77fc
2c5df7e5-83ef-429d-8e85-bedbcd7038e9	2026-07-28 07:08:30.702799	2026-07-28 07:08:30.702799	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-28T07:04:46.637264)	OPEN	\N	e3cbf44f-70c1-4065-b448-bfe6fd3eb84b
aa52933b-a8cc-4f3a-83e0-f81ea2946032	2026-07-28 07:08:30.704108	2026-07-28 07:08:30.704108	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-28T07:04:47.018499)	OPEN	\N	b37d3442-70c1-44a7-8b0f-c16e3d2d05fd
9848f78e-29d8-4c98-a3e6-82ce2567caaf	2026-07-28 07:08:30.800835	2026-07-28 07:08:30.800835	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-28T07:04:53.583095)	OPEN	\N	a37395c2-abfd-4627-a2ed-a449d870d276
164fc539-0cb2-4ef9-8806-e352cfeeeabd	2026-07-28 07:08:30.802545	2026-07-28 07:08:30.802545	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-28T07:04:53.906553)	OPEN	\N	64f5b409-34d7-4499-9ad2-0fa043005180
a788a495-9220-48e5-b935-863a497a7eda	2026-07-28 07:08:30.80336	2026-07-28 07:08:30.80336	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-28T07:05:00.837133)	OPEN	\N	2119d259-d667-4994-8cb4-2d4f7f483e5b
0aab7c8c-e13b-4b42-9c84-f81a7f26c329	2026-07-28 07:08:30.803874	2026-07-28 07:08:30.803874	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-28T07:05:01.607267)	OPEN	\N	ad47bc66-00e6-465f-a441-04449b1d21ad
bbcfc367-fc15-442c-be93-b681327a0ace	2026-07-28 10:38:33.501684	2026-07-28 10:38:33.501684	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-28T10:24:19.658984)	OPEN	\N	49fbc40e-667c-4252-9de8-57f155b09e78
14cc7289-0bf8-48c5-8874-7508c63b31dc	2026-07-28 10:38:33.502846	2026-07-28 10:38:33.502846	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-28T10:24:20.696978)	OPEN	\N	e5e71416-e20c-4297-bc9b-64733d07f45f
2262e344-1db6-42ce-adbb-078a6dd01ec3	2026-07-28 10:38:33.503217	2026-07-28 10:38:33.503217	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-28T10:25:31.535372)	OPEN	\N	a1dc49c3-f49f-4a54-a478-20c063c80cc6
ffb9ebf6-07a7-4f97-b844-a6532d1521b7	2026-07-28 10:38:33.503526	2026-07-28 10:38:33.503526	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-28T10:25:34.728250)	OPEN	\N	85ae8e7b-b3f2-4640-9ace-f8fa69761a9d
33349092-4ec5-4ab8-8ce0-0b972c002903	2026-07-29 01:34:43.408789	2026-07-29 01:34:43.408789	Tạo yêu cầu bảo trì mã MNT-20260729-844 (NORMAL)	OPEN	a0000000-0000-0000-0000-000000000002	6c0b25e4-a92e-40d9-8480-03e5efe58461
a2490384-eb21-4a73-b918-bb9375e32877	2026-07-29 01:34:45.301849	2026-07-29 01:34:45.301849	Tạo yêu cầu bảo trì mã MNT-20260729-845 (NORMAL)	OPEN	a0000000-0000-0000-0000-000000000002	7c657edc-5072-4c13-9e24-0dba94836489
45a92aab-14d5-4c7a-a7bb-e32e7954f505	2026-07-29 01:35:49.305845	2026-07-29 01:35:49.305845	Tạo yêu cầu bảo trì mã MNT-20260729-846 (NORMAL)	OPEN	a0000000-0000-0000-0000-000000000002	afab1b6d-6ae8-4337-84a6-982a90835589
c0275180-f07f-48d9-b037-deac193eed88	2026-07-29 01:35:49.905555	2026-07-29 01:35:49.905555	Tạo yêu cầu bảo trì mã MNT-20260729-847 (NORMAL)	OPEN	a0000000-0000-0000-0000-000000000002	ca7af936-6596-4ccf-ab2b-588a1ba131e7
5a45c453-b917-4e2f-90fa-61d77043363a	2026-07-29 03:03:34.911572	2026-07-29 03:03:34.911572	Tạo yêu cầu bảo trì mã MNT-20260729-848 (NORMAL)	OPEN	a0000000-0000-0000-0000-000000000002	b0544e1c-d3f6-4441-a690-c2c0bdd83920
f09a4432-2185-4a06-a03e-b723590f67ce	2026-07-29 03:03:35.808247	2026-07-29 03:03:35.808247	Tạo yêu cầu bảo trì mã MNT-20260729-849 (NORMAL)	OPEN	a0000000-0000-0000-0000-000000000002	e1f8ef7c-720f-4d71-ab02-e761f4cd93d2
230667a9-025d-42e2-b0f9-04c37014874f	2026-07-30 02:04:39.872043	2026-07-30 02:04:39.872043	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-30T01:34:43.407724)	OPEN	\N	6c0b25e4-a92e-40d9-8480-03e5efe58461
84d01a9a-ede6-45e5-a724-9a4d8e9dfe1f	2026-07-30 02:04:40.06945	2026-07-30 02:04:40.06945	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-30T01:34:45.205827)	OPEN	\N	7c657edc-5072-4c13-9e24-0dba94836489
c55df1c6-dddd-4462-b6c0-a8df72494563	2026-07-30 02:04:40.070494	2026-07-30 02:04:40.070494	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-30T01:35:49.304643)	OPEN	\N	afab1b6d-6ae8-4337-84a6-982a90835589
27aeb896-5793-410c-b7b8-85ede5fed731	2026-07-30 02:04:40.071255	2026-07-30 02:04:40.071255	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-30T01:35:49.904755)	OPEN	\N	ca7af936-6596-4ccf-ab2b-588a1ba131e7
3c8ffc12-cae4-401c-8f7c-8594852893d2	2026-07-30 03:04:40.702385	2026-07-30 03:04:40.702385	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-30T03:03:34.910572)	OPEN	\N	b0544e1c-d3f6-4441-a690-c2c0bdd83920
554f1391-742c-4455-b648-58ef98079583	2026-07-30 03:04:40.703243	2026-07-30 03:04:40.703243	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-30T03:03:35.807228)	OPEN	\N	e1f8ef7c-720f-4d71-ab02-e761f4cd93d2
b33a5913-d8cd-43a8-bccf-c5ddda72e4d2	2026-07-30 11:11:27.867579	2026-07-30 11:11:27.867579	Tạo yêu cầu bảo trì mã MNT-20260730-832 (NORMAL)	OPEN	a0000000-0000-0000-0000-000000000002	28774408-c16e-471f-b982-1fe505f5856b
98b79a00-fd82-4fa4-98c5-b0d259aa9ed1	2026-07-30 11:15:06.618024	2026-07-30 11:15:06.618024	Tạo yêu cầu bảo trì mã MNT-20260730-402 (NORMAL)	OPEN	a0000000-0000-0000-0000-000000000002	8342b2b1-d767-4869-acf7-97e27a5aa40f
1bd19284-026e-4e14-996a-57a08b1d2ce0	2026-07-31 03:29:10.744853	2026-07-31 03:29:10.744853	Tạo yêu cầu bảo trì mã MNT-20260731-937 (NORMAL)	OPEN	a0000000-0000-0000-0000-000000000002	3e412a56-e4c8-45ef-bc2c-488e118c0651
c681ddf7-3567-4b9a-b770-cbe95261f42e	2026-07-31 04:56:22.035927	2026-07-31 04:56:22.035927	Tạo yêu cầu bảo trì mã MNT-20260731-938 (NORMAL)	OPEN	a0000000-0000-0000-0000-000000000002	de307c0f-3c70-4767-9a77-6adb46585bb4
b733c44c-05a2-42d5-9818-121c765a933f	2026-07-31 04:56:27.148799	2026-07-31 04:56:27.148799	Tạo yêu cầu bảo trì mã MNT-20260731-939 (NORMAL)	OPEN	a0000000-0000-0000-0000-000000000002	2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9
9d65e918-d941-4b1a-a0e5-03b2591003dd	2026-07-31 04:56:34.936746	2026-07-31 04:56:34.936746	Tạo yêu cầu bảo trì mã MNT-20260731-940 (NORMAL)	OPEN	a0000000-0000-0000-0000-000000000002	8721cde2-53f1-478e-842d-63cef0d8e17a
25e64993-5be7-4d13-9ca1-fd55c83c2ea2	2026-07-31 05:01:17.432168	2026-07-31 05:01:17.432168	Phân công kỹ thuật viên: Nguyễn Đinh Gia Bảo	ASSIGNED	\N	8721cde2-53f1-478e-842d-63cef0d8e17a
fb9f1ccf-e4b9-4b32-be9b-0ec13bf47ae8	2026-07-31 07:09:03.297694	2026-07-31 07:09:03.297694	Đề xuất/Xác nhận khung giờ làm việc: Sáng mai (8:00 - 11:30)	ASSIGNED	\N	8721cde2-53f1-478e-842d-63cef0d8e17a
268656fb-7cb5-4be7-98c2-65db6af33b37	2026-07-31 07:09:09.702235	2026-07-31 07:09:09.702235	Kỹ thuật viên bắt đầu xử lý công việc	IN_PROGRESS	774a2c9e-8929-4d7c-80ca-14f62b9d9d56	8721cde2-53f1-478e-842d-63cef0d8e17a
c42c9642-e188-49a5-ad4f-7765f89ddc30	2026-07-31 07:09:54.895688	2026-07-31 07:09:54.895688	Thêm vật tư: Ông nước 1 x1 (50000 VNĐ)	IN_PROGRESS	\N	8721cde2-53f1-478e-842d-63cef0d8e17a
d4667823-0139-4036-9557-9d3153ac7a07	2026-07-31 07:10:08.677941	2026-07-31 07:10:08.677941	Thêm vật tư: Dây điện x5 (625000 VNĐ)	IN_PROGRESS	\N	8721cde2-53f1-478e-842d-63cef0d8e17a
d73f3667-f007-460a-a816-174a9e33024c	2026-07-31 07:10:12.948301	2026-07-31 07:10:12.948301	Done	IN_PROGRESS	774a2c9e-8929-4d7c-80ca-14f62b9d9d56	8721cde2-53f1-478e-842d-63cef0d8e17a
b1424f97-d6ee-4a1e-a42b-4ea853004eb8	2026-07-31 07:27:28.04594	2026-07-31 07:27:28.04594	Đã xong, hoàn thành	IN_PROGRESS	774a2c9e-8929-4d7c-80ca-14f62b9d9d56	8721cde2-53f1-478e-842d-63cef0d8e17a
ed6ba4ed-246f-4b7f-9384-5b23884252d7	2026-07-31 08:34:06.759493	2026-07-31 08:34:06.759493	dang di mua do	IN_PROGRESS	774a2c9e-8929-4d7c-80ca-14f62b9d9d56	8721cde2-53f1-478e-842d-63cef0d8e17a
2007b086-a4a3-485b-ba6d-80ef62edf53b	2026-07-31 08:34:21.814412	2026-07-31 08:34:21.814412	test	IN_PROGRESS	774a2c9e-8929-4d7c-80ca-14f62b9d9d56	8721cde2-53f1-478e-842d-63cef0d8e17a
cbb9c4d8-90b4-437c-a42c-75c3a3b6f5b4	2026-07-31 11:17:22.593288	2026-07-31 11:17:22.593288	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-31T11:11:27.865390)	OPEN	\N	28774408-c16e-471f-b982-1fe505f5856b
324fe537-87ef-478e-af42-629d237a7294	2026-07-31 11:17:22.99361	2026-07-31 11:17:22.99361	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-07-31T11:15:06.611562)	OPEN	\N	8342b2b1-d767-4869-acf7-97e27a5aa40f
a7506227-73f7-438d-b897-bc62ffb480b9	2026-08-01 03:50:32.422923	2026-08-01 03:50:32.422923	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-01T03:29:10.532504)	OPEN	\N	3e412a56-e4c8-45ef-bc2c-488e118c0651
2a12cb5e-9b32-4338-b77f-80ccf478305a	2026-08-09 16:05:19.679994	2026-08-09 16:05:19.679994	Thêm vật tư: CP x1 (50000 VNĐ)	IN_PROGRESS	\N	849c05ad-e3b6-4c8b-9f10-3db67d42a9e6
ebf2835d-851e-4e89-9a93-4f540570f156	2026-08-01 05:20:32.946298	2026-08-01 05:20:32.946298	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-01T04:56:22.034828)	OPEN	\N	de307c0f-3c70-4767-9a77-6adb46585bb4
30aff1d1-62d3-4701-bea7-bd852a30e51c	2026-08-01 05:20:32.95454	2026-08-01 05:20:32.95454	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-01T04:56:27.147594)	OPEN	\N	2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9
7c1f55d9-0d7a-4bff-9a2b-5dafddfb010d	2026-08-01 05:20:32.98049	2026-08-01 05:20:32.98049	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-01T04:56:34.935956)	IN_PROGRESS	\N	8721cde2-53f1-478e-842d-63cef0d8e17a
b7f13c05-a774-4645-be84-0a92b4114aad	2026-08-02 03:03:56.281921	2026-08-02 03:03:56.281921	Thêm vật tư: Ong noi nuoc x1 (0 VNĐ)	IN_PROGRESS	\N	8721cde2-53f1-478e-842d-63cef0d8e17a
c373fbf2-3ead-4fa8-8f07-76dc9b261a45	2026-08-02 03:14:47.372715	2026-08-02 03:14:47.372715	Xóa vật tư: Ong noi nuoc	IN_PROGRESS	\N	8721cde2-53f1-478e-842d-63cef0d8e17a
6ef321b8-4af4-4744-ad04-8d091ae20c91	2026-08-02 03:15:11.897474	2026-08-02 03:15:11.897474	Thêm vật tư: Ống nối nước x2 (20 VNĐ)	IN_PROGRESS	\N	8721cde2-53f1-478e-842d-63cef0d8e17a
65c8c238-4829-4b8e-ab5b-5e4340a99fe3	2026-08-02 03:15:17.136971	2026-08-02 03:15:17.136971	Xóa vật tư: Ống nối nước	IN_PROGRESS	\N	8721cde2-53f1-478e-842d-63cef0d8e17a
f030a4a5-2050-4a71-a4b8-5922732404c6	2026-08-02 03:15:31.05711	2026-08-02 03:15:31.05711	Thêm vật tư: Ống nối nước x2 (20000 VNĐ)	IN_PROGRESS	\N	8721cde2-53f1-478e-842d-63cef0d8e17a
ee819107-6709-4ed5-a68f-0b538d8dd34a	2026-08-02 03:15:40.585982	2026-08-02 03:15:40.585982	Xóa vật tư: Ống nối nước	IN_PROGRESS	\N	8721cde2-53f1-478e-842d-63cef0d8e17a
aef6262b-92c7-4c20-9e03-c162cc37d26e	2026-08-02 03:15:55.974569	2026-08-02 03:15:55.974569	Thêm vật tư: Ống nối nước x2 (20000 VNĐ)	IN_PROGRESS	\N	8721cde2-53f1-478e-842d-63cef0d8e17a
ef8d7b02-5307-44e7-a09e-858d18a50436	2026-08-02 07:21:50.278884	2026-08-02 07:21:50.278884	Tạo yêu cầu bảo trì mã MNT-20260802-176 (HIGH)	OPEN	a0000000-0000-0000-0000-000000000002	e3a2fec5-a9ad-409f-944d-ef61236f54cc
112926b6-4308-4b5c-8d14-bf1816be8364	2026-08-02 07:23:19.217337	2026-08-02 07:23:19.217337	Cập nhật thời gian SLA dự kiến: 2026-08-04T07:23	OPEN	\N	e3a2fec5-a9ad-409f-944d-ef61236f54cc
efc9fb98-89a2-4dd5-99ec-bbed9c8e7ce9	2026-08-02 07:23:34.383822	2026-08-02 07:23:34.383822	Phân công kỹ thuật viên: Trần Bá Lãm	ASSIGNED	\N	e3a2fec5-a9ad-409f-944d-ef61236f54cc
aaabdc88-1383-4d19-b02b-f069dae543c5	2026-08-02 07:25:19.633088	2026-08-02 07:25:19.633088	Đề xuất/Xác nhận khung giờ làm việc: Chiều mai (13:30 - 17:00)	ASSIGNED	\N	e3a2fec5-a9ad-409f-944d-ef61236f54cc
63ca9ddb-a385-48ea-bcf2-ffce95eaad67	2026-08-02 07:26:04.038827	2026-08-02 07:26:04.038827	Cư dân đã đồng ý khung giờ hẹn	ASSIGNED	a0000000-0000-0000-0000-000000000002	e3a2fec5-a9ad-409f-944d-ef61236f54cc
3c9abcaf-11da-4667-a364-674be0b50f18	2026-08-02 07:26:11.673646	2026-08-02 07:26:11.673646	Kỹ thuật viên bắt đầu xử lý công việc	IN_PROGRESS	7b70cfa6-d414-4165-b17c-dde2c4aea3ba	e3a2fec5-a9ad-409f-944d-ef61236f54cc
88d0812a-de40-4b58-9c5d-5f571cb50d43	2026-08-02 07:26:23.405257	2026-08-02 07:26:23.405257	đã cong	IN_PROGRESS	7b70cfa6-d414-4165-b17c-dde2c4aea3ba	e3a2fec5-a9ad-409f-944d-ef61236f54cc
0b99c374-db8c-4e01-bd91-8296237c239c	2026-08-02 07:34:58.785901	2026-08-02 07:34:58.785901	Thêm vật tư: cáo su non x1 (5000 VNĐ)	IN_PROGRESS	\N	e3a2fec5-a9ad-409f-944d-ef61236f54cc
3ca10387-e742-48f8-bfbe-70d88386310f	2026-08-02 07:35:04.446483	2026-08-02 07:35:04.446483	Xóa vật tư: cáo su non	IN_PROGRESS	\N	e3a2fec5-a9ad-409f-944d-ef61236f54cc
6249bbd2-c76a-474c-bee4-a6278a4a1ecb	2026-08-04 07:23:10.804641	2026-08-04 07:23:10.804641	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-04T07:23)	IN_PROGRESS	\N	e3a2fec5-a9ad-409f-944d-ef61236f54cc
b66bc7ca-349e-474a-8da7-75d821f59976	2026-08-04 07:30:57.70389	2026-08-04 07:30:57.70389	Phân công kỹ thuật viên: Nguyễn Đinh Gia Bảo	ASSIGNED	\N	2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9
b107df0f-e8e2-43f2-81fa-5013f604ecaf	2026-08-04 07:31:20.109269	2026-08-04 07:31:20.109269	Phân công kỹ thuật viên: Trần Bá Lãm	ASSIGNED	\N	de307c0f-3c70-4767-9a77-6adb46585bb4
2145a649-3758-4aaa-b3bc-b33815dd5757	2026-08-04 07:32:36.50351	2026-08-04 07:32:36.50351	Kỹ thuật viên bắt đầu xử lý công việc	IN_PROGRESS	774a2c9e-8929-4d7c-80ca-14f62b9d9d56	2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9
f2386966-902e-4832-869f-0198f49cbef7	2026-08-04 08:01:37.27616	2026-08-04 08:01:37.27616	Đang chờ đồ về để thay thế	IN_PROGRESS	774a2c9e-8929-4d7c-80ca-14f62b9d9d56	2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9
cb0c5eb7-8d86-4e34-abbd-931eb7684120	2026-08-04 08:01:57.904844	2026-08-04 08:01:57.904844	Thêm vật tư: bóng đèn trần x1 (0 VNĐ)	IN_PROGRESS	\N	2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9
e0685009-dd47-4ff7-a6c9-dd276b9f9631	2026-08-04 08:06:36.670571	2026-08-04 08:06:36.670571	Cư dân đã đồng ý khung giờ hẹn	IN_PROGRESS	a0000000-0000-0000-0000-000000000002	8721cde2-53f1-478e-842d-63cef0d8e17a
bfe27fe2-b719-4086-9279-f3fcd28f30d6	2026-08-04 08:06:37.228511	2026-08-04 08:06:37.228511	Cư dân đã đồng ý khung giờ hẹn	IN_PROGRESS	a0000000-0000-0000-0000-000000000002	8721cde2-53f1-478e-842d-63cef0d8e17a
b2e8a13f-1c7d-4509-ac4f-42cd2d597ee8	2026-08-04 08:35:40.109091	2026-08-04 08:35:40.109091	Tạo yêu cầu bảo trì mã MNT-20260804-107 (URGENT)	OPEN	b1000000-0000-0000-0000-000000000003	919b3461-8baf-4669-b0fc-e66c998d0c38
44b45b0d-2e8d-4ba9-9960-94a6e3349223	2026-08-04 08:35:46.207351	2026-08-04 08:35:46.207351	Tạo yêu cầu bảo trì mã MNT-20260804-108 (URGENT)	OPEN	b1000000-0000-0000-0000-000000000003	797fc693-e426-43c8-be82-06e318cd6b46
fc024f93-67c2-4b00-a6ed-f8f04fb5fe7b	2026-08-04 08:35:51.211371	2026-08-04 08:35:51.211371	Tạo yêu cầu bảo trì mã MNT-20260804-109 (URGENT)	OPEN	b1000000-0000-0000-0000-000000000003	5bd48f3a-3600-45a2-a302-3698710235a2
c09e6619-ead3-4a57-bee2-ebc03f44517b	2026-08-04 08:35:59.314681	2026-08-04 08:35:59.314681	Tạo yêu cầu bảo trì mã MNT-20260804-110 (URGENT)	OPEN	b1000000-0000-0000-0000-000000000003	c2738e46-85d0-45f2-b0d6-ae16f04d1cad
07afa830-a872-4a0f-8a2b-930981dd322b	2026-08-04 08:36:11.416016	2026-08-04 08:36:11.416016	Tạo yêu cầu bảo trì mã MNT-20260804-111 (URGENT)	OPEN	b1000000-0000-0000-0000-000000000003	9b31d59a-e23c-4ea5-9b4c-957406f94725
05f3fb17-b7a1-4cc4-a0df-28bd8d012b9c	2026-08-04 08:36:30.402468	2026-08-04 08:36:30.402468	Tạo yêu cầu bảo trì mã MNT-20260804-112 (URGENT)	OPEN	b1000000-0000-0000-0000-000000000003	de427a93-5a73-4187-b30c-6b18f1d8073e
4afe601d-68be-4568-857e-522f3d785a64	2026-08-04 08:37:04.323172	2026-08-04 08:37:04.323172	Tạo yêu cầu bảo trì mã MNT-20260804-113 (URGENT)	OPEN	b1000000-0000-0000-0000-000000000003	cbf3facb-8486-47b7-b951-cea864340b19
1de9ff1d-8467-4631-a70f-9b818addb918	2026-08-04 08:50:24.603818	2026-08-04 08:50:24.603818	Tạo yêu cầu bảo trì mã MNT-20260804-114 (URGENT)	OPEN	b1000000-0000-0000-0000-000000000003	c5e0255e-0794-408f-9677-5db981f2d32f
b51e7103-2ec3-4f7d-aba1-441c58f011cf	2026-08-04 08:50:57.119151	2026-08-04 08:50:57.119151	Tạo yêu cầu bảo trì mã MNT-20260804-115 (HIGH)	OPEN	b1000000-0000-0000-0000-000000000003	92b4e6ca-0abe-429e-8385-18666f89cd13
be43f6ec-7166-47e5-9b6e-62c542637d59	2026-08-04 08:51:50.935517	2026-08-04 08:51:50.935517	Phân công kỹ thuật viên: Trần Bá Lãm	ASSIGNED	\N	92b4e6ca-0abe-429e-8385-18666f89cd13
bc95952b-c1eb-4544-bc8b-bfa757e4cca7	2026-08-04 08:52:03.818756	2026-08-04 08:52:03.818756	Phân công kỹ thuật viên: Trần Bá Lãm	ASSIGNED	\N	c5e0255e-0794-408f-9677-5db981f2d32f
2b211cfe-27fb-457e-850f-c767d54b6436	2026-08-04 08:56:56.612227	2026-08-04 08:56:56.612227	Hủy phiếu bảo trì. Lý do: spam nhiều lần	CANCELLED	\N	cbf3facb-8486-47b7-b951-cea864340b19
f9c8c9e5-c102-49e0-b893-3f4a19f1fc3a	2026-08-04 08:57:05.706631	2026-08-04 08:57:05.706631	Hủy phiếu bảo trì. Lý do: spam nhiều lần	CANCELLED	\N	de427a93-5a73-4187-b30c-6b18f1d8073e
4fa1c3c9-7621-490d-bc46-3b7569440071	2026-08-04 08:57:12.506013	2026-08-04 08:57:12.506013	Hủy phiếu bảo trì. Lý do: spam nhiều lần	CANCELLED	\N	9b31d59a-e23c-4ea5-9b4c-957406f94725
0f4d936f-28fa-45aa-a37d-ef906d85b3aa	2026-08-04 08:57:17.12754	2026-08-04 08:57:17.12754	Hủy phiếu bảo trì. Lý do: spam nhiều lần	CANCELLED	\N	c2738e46-85d0-45f2-b0d6-ae16f04d1cad
2c8f10a3-946d-447c-bcdd-0e78ed35c57b	2026-08-04 08:58:54.504333	2026-08-04 08:58:54.504333	Đề xuất/Xác nhận khung giờ làm việc: Sáng mai (8:00 - 11:30)	ASSIGNED	\N	92b4e6ca-0abe-429e-8385-18666f89cd13
a21e081f-dd1f-4be1-9a56-156dc1438e6b	2026-08-04 08:59:06.559392	2026-08-04 08:59:06.559392	Cư dân đã đồng ý khung giờ hẹn	ASSIGNED	b1000000-0000-0000-0000-000000000003	92b4e6ca-0abe-429e-8385-18666f89cd13
130d91dd-5746-4e7a-90e9-bd0581cfedbf	2026-08-04 08:59:12.917987	2026-08-04 08:59:12.917987	Kỹ thuật viên bắt đầu xử lý công việc	IN_PROGRESS	7b70cfa6-d414-4165-b17c-dde2c4aea3ba	92b4e6ca-0abe-429e-8385-18666f89cd13
f267e260-4e37-4851-a2b4-fc52c561f8a1	2026-08-04 08:59:28.802903	2026-08-04 08:59:28.802903	Thêm vật tư: Cao su non x1 (5000 VNĐ)	IN_PROGRESS	\N	92b4e6ca-0abe-429e-8385-18666f89cd13
a02a6e2a-7ff6-4930-97e1-aac2cb1c6055	2026-08-04 09:01:16.340433	2026-08-04 09:01:16.340433	Đề xuất/Xác nhận khung giờ làm việc: Sáng mai (8:00 - 11:30)	ASSIGNED	\N	c5e0255e-0794-408f-9677-5db981f2d32f
aceb46d4-2ab5-4fbb-b8cc-20f40628e45b	2026-08-04 09:01:23.547594	2026-08-04 09:01:23.547594	Cư dân từ chối khung giờ hẹn	ASSIGNED	b1000000-0000-0000-0000-000000000003	c5e0255e-0794-408f-9677-5db981f2d32f
7b8b47ea-fe66-4875-ab6c-8d8e41ddb209	2026-08-04 09:01:54.514624	2026-08-04 09:01:54.514624	Cư dân từ chối khung giờ hẹn	ASSIGNED	b1000000-0000-0000-0000-000000000003	c5e0255e-0794-408f-9677-5db981f2d32f
8d42d3a9-16bc-4ce5-9154-9af2b6aaff92	2026-08-04 09:01:54.514624	2026-08-04 09:01:54.514624	Cư dân từ chối khung giờ hẹn	ASSIGNED	b1000000-0000-0000-0000-000000000003	c5e0255e-0794-408f-9677-5db981f2d32f
aec5483d-657c-4fdd-97f1-dce7ac4c31c2	2026-08-04 09:01:54.705703	2026-08-04 09:01:54.705703	Cư dân từ chối khung giờ hẹn	ASSIGNED	b1000000-0000-0000-0000-000000000003	c5e0255e-0794-408f-9677-5db981f2d32f
ce99f0f9-097c-47cb-ad8e-8367e47ca5b4	2026-08-04 09:22:52.458921	2026-08-04 09:22:52.458921	Tạo yêu cầu bảo trì mã MNT-20260804-057 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	e56e460b-511b-48af-b2ac-3d8e93a464cc
1bb50603-a966-46ab-9411-50701cc51ea7	2026-08-04 09:22:57.10313	2026-08-04 09:22:57.10313	Tạo yêu cầu bảo trì mã MNT-20260804-058 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	3ea22299-cbb4-4730-9ae1-aac56cf897b0
22ce7066-0216-42b7-8fd0-376095a2991e	2026-08-04 09:23:01.867609	2026-08-04 09:23:01.867609	Tạo yêu cầu bảo trì mã MNT-20260804-059 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	10929fc8-6e84-4107-af9f-50d2aa7fc9c5
a682a00c-e3f1-4018-8968-8794d7ed6d71	2026-08-04 09:23:08.66425	2026-08-04 09:23:08.66425	Tạo yêu cầu bảo trì mã MNT-20260804-060 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	babc7312-1c6f-4670-8297-351d392a1996
f50543b9-abe9-415e-bc40-8afd9af62239	2026-08-04 09:28:52.860994	2026-08-04 09:28:52.860994	Tạo yêu cầu bảo trì mã MNT-20260804-061 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	791b3bc7-973e-4ce9-b0f8-2c2bed1383d5
5695f17c-c446-4b44-a38e-9211969bcc8a	2026-08-04 09:29:09.76587	2026-08-04 09:29:09.76587	Tạo yêu cầu bảo trì mã MNT-20260804-062 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000002	ee2e951d-6752-4790-8805-0a21dc2bf15a
67c5d4e3-d377-4c0c-b0f0-ce5211810784	2026-08-04 09:30:53.567134	2026-08-04 09:30:53.567134	Phân công kỹ thuật viên: Nguyễn Đinh Gia Bảo	ASSIGNED	\N	babc7312-1c6f-4670-8297-351d392a1996
099ee692-76ed-4690-800f-817196e9e979	2026-08-04 09:32:01.355484	2026-08-04 09:32:01.355484	Đề xuất/Xác nhận khung giờ làm việc: Chiều mai (13:30 - 17:00)	ASSIGNED	\N	babc7312-1c6f-4670-8297-351d392a1996
04aab720-f0be-415e-8f9c-212b9ae7fc82	2026-08-04 09:32:03.738999	2026-08-04 09:32:03.738999	Kỹ thuật viên bắt đầu xử lý công việc	IN_PROGRESS	774a2c9e-8929-4d7c-80ca-14f62b9d9d56	babc7312-1c6f-4670-8297-351d392a1996
5aa860f0-3cef-4cec-b680-513688487256	2026-08-04 09:33:49.246137	2026-08-04 09:33:49.246137	Cư dân đã đồng ý khung giờ hẹn	IN_PROGRESS	b1000000-0000-0000-0000-000000000002	babc7312-1c6f-4670-8297-351d392a1996
06a9ea61-8a9e-415a-b3ed-955c059257d1	2026-08-04 09:34:13.416147	2026-08-04 09:34:13.416147	Đã mua khung cửa mới	IN_PROGRESS	774a2c9e-8929-4d7c-80ca-14f62b9d9d56	babc7312-1c6f-4670-8297-351d392a1996
55a3f0fe-07fd-44e5-bbe3-fdaa656962b6	2026-08-04 12:43:17.940592	2026-08-04 12:43:17.940592	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-04T12:35:51.210573)	OPEN	\N	5bd48f3a-3600-45a2-a302-3698710235a2
00650a8e-cf22-4c46-8145-ec2bb0dc3c63	2026-08-04 12:43:17.960486	2026-08-04 12:43:17.960486	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-04T12:35:46.206280)	OPEN	\N	797fc693-e426-43c8-be82-06e318cd6b46
6b9a7c0e-664a-4798-88c9-df6e788d4f8a	2026-08-04 12:43:17.966792	2026-08-04 12:43:17.966792	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-04T12:35:40.106894)	OPEN	\N	919b3461-8baf-4669-b0fc-e66c998d0c38
c00ac818-332a-434c-9bdb-4264f75a5296	2026-08-04 13:13:18.076823	2026-08-04 13:13:18.076823	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-04T12:50:24.515078)	ASSIGNED	\N	c5e0255e-0794-408f-9677-5db981f2d32f
c2f71133-dee3-43ba-8894-6cebcc908c9e	2026-08-04 15:13:18.203129	2026-08-04 15:13:18.203129	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-04T14:50:57.118421)	IN_PROGRESS	\N	92b4e6ca-0abe-429e-8385-18666f89cd13
58601c48-8aa1-49f7-aa9b-4db40783b840	2026-08-04 17:08:23.536297	2026-08-04 17:08:23.536297	Phân công kỹ thuật viên: Phan Duc Huy	ASSIGNED	\N	ee2e951d-6752-4790-8805-0a21dc2bf15a
453a9951-9ce7-4c3f-80ae-7026700c348e	2026-08-05 03:04:19.959878	2026-08-05 03:04:19.959878	Thêm vật tư: Bản lề cửa x2 (70000 VNĐ)	IN_PROGRESS	\N	babc7312-1c6f-4670-8297-351d392a1996
bd75dd4c-a50b-4222-80bf-7f56b969058b	2026-08-05 03:27:49.157726	2026-08-05 03:27:49.157726	Tạo yêu cầu bảo trì mã MNT-20260805-062 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000005	a4af8910-9741-45c9-81c7-a5fc5c5b6407
7d7fbc1f-5f7e-4628-aaad-e3876dd439b1	2026-08-05 03:27:57.068688	2026-08-05 03:27:57.068688	Tạo yêu cầu bảo trì mã MNT-20260805-063 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000005	94595db1-e24a-4a26-a28e-4a1e73bb8814
062ae6af-cff5-4d49-a83a-e348cc2139c4	2026-08-05 03:28:16.907807	2026-08-05 03:28:16.907807	Tạo yêu cầu bảo trì mã MNT-20260805-410 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000005	db9a9713-3331-441f-84c5-ea3e5abb1197
46870c51-219a-477f-b70f-e8e19db6a870	2026-08-05 03:29:12.313838	2026-08-05 03:29:12.313838	Phân công kỹ thuật viên: Nguyễn Đinh Gia Bảo	ASSIGNED	\N	db9a9713-3331-441f-84c5-ea3e5abb1197
f9be46d6-5e2a-4b03-9b41-e91e0eefd502	2026-08-05 03:29:32.107743	2026-08-05 03:29:32.107743	Đề xuất/Xác nhận khung giờ làm việc: Chiều Thứ Năm (06/08) (13:30 - 17:00)	ASSIGNED	\N	db9a9713-3331-441f-84c5-ea3e5abb1197
dd685381-f105-436d-9dd0-d80957e35970	2026-08-05 03:29:51.300376	2026-08-05 03:29:51.300376	Cư dân đã đồng ý khung giờ hẹn	ASSIGNED	b1000000-0000-0000-0000-000000000005	db9a9713-3331-441f-84c5-ea3e5abb1197
976c32a3-079f-4fd4-83cc-997eb33958d4	2026-08-05 03:30:00.609674	2026-08-05 03:30:00.609674	Kỹ thuật viên bắt đầu xử lý công việc	IN_PROGRESS	774a2c9e-8929-4d7c-80ca-14f62b9d9d56	db9a9713-3331-441f-84c5-ea3e5abb1197
9974c0e1-471f-4277-a252-ad80c213e936	2026-08-05 03:30:24.106782	2026-08-05 03:30:24.106782	Thêm vật tư: ống thoát nước x1 (40000 VNĐ)	IN_PROGRESS	\N	db9a9713-3331-441f-84c5-ea3e5abb1197
fcecba7c-8107-4097-a487-f6e73c743a99	2026-08-05 03:30:38.20699	2026-08-05 03:30:38.20699	Vệ sinh lại máy lạnh	IN_PROGRESS	774a2c9e-8929-4d7c-80ca-14f62b9d9d56	db9a9713-3331-441f-84c5-ea3e5abb1197
344da304-6a20-40d1-bc64-e868e5e4b638	2026-08-05 03:31:33.572581	2026-08-05 03:31:33.572581	Thêm vật tư: tiền công vệ sinh x1 (200000 VNĐ)	IN_PROGRESS	\N	db9a9713-3331-441f-84c5-ea3e5abb1197
512650a9-5c20-47e5-a861-2abbe4390b6d	2026-08-05 03:40:42.617807	2026-08-05 03:40:42.617807	Thêm vật tư: ống máy lạnh x1 (10000 VNĐ)	IN_PROGRESS	\N	db9a9713-3331-441f-84c5-ea3e5abb1197
e07755a1-cc57-487b-927e-1a42e3d086f3	2026-08-05 03:40:56.976304	2026-08-05 03:40:56.976304	kỹ thuật viên lỡ làm mất ốc	IN_PROGRESS	774a2c9e-8929-4d7c-80ca-14f62b9d9d56	db9a9713-3331-441f-84c5-ea3e5abb1197
8eaa9c24-e6b7-40d2-bdf1-28965625ba0c	2026-08-05 03:54:09.606693	2026-08-05 03:54:09.606693	Tạo yêu cầu bảo trì mã MNT-20260805-411 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000005	0f0f870b-8625-4306-84b4-61e3c78ae7e2
a0f59683-bd71-494e-831f-5d8eeda405ec	2026-08-05 03:54:37.014738	2026-08-05 03:54:37.014738	Phân công kỹ thuật viên: Nguyễn Đinh Gia Bảo	ASSIGNED	\N	0f0f870b-8625-4306-84b4-61e3c78ae7e2
4cac09b8-95c0-4462-b977-fb0afffc8b32	2026-08-05 03:55:11.409342	2026-08-05 03:55:11.409342	Đề xuất/Xác nhận khung giờ làm việc: Tối nay (18:00 - 20:30)	ASSIGNED	\N	0f0f870b-8625-4306-84b4-61e3c78ae7e2
e66c6ee7-927d-4099-91ee-900daa3afb7d	2026-08-05 03:55:15.89208	2026-08-05 03:55:15.89208	Cư dân từ chối khung giờ hẹn	ASSIGNED	b1000000-0000-0000-0000-000000000005	0f0f870b-8625-4306-84b4-61e3c78ae7e2
d1e39306-18ee-4985-b960-21fc29dcd230	2026-08-05 03:55:18.247889	2026-08-05 03:55:18.247889	Cư dân đã đồng ý khung giờ hẹn	ASSIGNED	b1000000-0000-0000-0000-000000000005	0f0f870b-8625-4306-84b4-61e3c78ae7e2
6741761e-3f04-4949-9d8b-9077586d8389	2026-08-05 03:55:23.011267	2026-08-05 03:55:23.011267	Kỹ thuật viên bắt đầu xử lý công việc	IN_PROGRESS	774a2c9e-8929-4d7c-80ca-14f62b9d9d56	0f0f870b-8625-4306-84b4-61e3c78ae7e2
f3848630-a32d-45ab-a5bc-6efbb13e4811	2026-08-05 03:55:44.613757	2026-08-05 03:55:44.613757	Thêm vật tư: dây điện x1 (20000 VNĐ)	IN_PROGRESS	\N	0f0f870b-8625-4306-84b4-61e3c78ae7e2
ddc501da-006e-4cd3-95ba-4b632789caad	2026-08-05 03:56:04.272415	2026-08-05 03:56:04.272415	dậy điện bị đứt	IN_PROGRESS	774a2c9e-8929-4d7c-80ca-14f62b9d9d56	0f0f870b-8625-4306-84b4-61e3c78ae7e2
d783c1a4-f8e9-4d4d-9136-d81a4f9a7946	2026-08-05 03:56:31.591042	2026-08-05 03:56:31.591042	Thêm vật tư: bóng đèn x1 (10000 VNĐ)	IN_PROGRESS	\N	0f0f870b-8625-4306-84b4-61e3c78ae7e2
c8fe743f-bb07-4d5b-be66-1725f1ed1d3f	2026-08-05 03:56:41.256735	2026-08-05 03:56:41.256735	lỡ làm rớt bóng đèn	IN_PROGRESS	774a2c9e-8929-4d7c-80ca-14f62b9d9d56	0f0f870b-8625-4306-84b4-61e3c78ae7e2
c97d3550-0205-4163-ba46-46131984c213	2026-08-05 03:57:59.725552	2026-08-05 03:57:59.725552	Tạo yêu cầu bảo trì mã MNT-20260805-412 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000005	b7b0c13c-2dbe-4d08-b81c-032624bfe278
cb6864c4-ee3f-4e7b-a93e-282b954f20f2	2026-08-05 03:59:38.110605	2026-08-05 03:59:38.110605	Phân công kỹ thuật viên: Kỹ thuật viên B	ASSIGNED	\N	b7b0c13c-2dbe-4d08-b81c-032624bfe278
65b77b60-1599-408e-af6e-40090719925f	2026-08-05 03:59:59.708447	2026-08-05 03:59:59.708447	Đề xuất/Xác nhận khung giờ làm việc: Sáng Thứ Năm (06/08) (8:00 - 11:30)	ASSIGNED	\N	b7b0c13c-2dbe-4d08-b81c-032624bfe278
3bfab21e-1cd7-4896-b028-6e29c25b9773	2026-08-05 04:00:06.524485	2026-08-05 04:00:06.524485	Cư dân từ chối khung giờ hẹn	ASSIGNED	b1000000-0000-0000-0000-000000000005	b7b0c13c-2dbe-4d08-b81c-032624bfe278
c756fb2c-6f98-4219-9da9-99c2b524521a	2026-08-05 04:00:27.382575	2026-08-05 04:00:27.382575	Cư dân đã đồng ý khung giờ hẹn	ASSIGNED	b1000000-0000-0000-0000-000000000005	b7b0c13c-2dbe-4d08-b81c-032624bfe278
c19e2bc8-af3a-4eaf-8277-9ab40b556665	2026-08-05 04:00:33.383569	2026-08-05 04:00:33.383569	Kỹ thuật viên bắt đầu xử lý công việc	IN_PROGRESS	a0000000-0000-0000-0000-000000000003	b7b0c13c-2dbe-4d08-b81c-032624bfe278
4c6d314d-fcec-4c49-b17f-082aef94de8d	2026-08-05 04:00:56.993457	2026-08-05 04:00:56.993457	Thêm vật tư: Công thông cống x1 (80000 VNĐ)	IN_PROGRESS	\N	b7b0c13c-2dbe-4d08-b81c-032624bfe278
6eb49edf-3791-406e-a16b-5962cd8c72aa	2026-08-05 04:04:22.233975	2026-08-05 04:04:22.233975	Tạo yêu cầu bảo trì mã MNT-20260805-413 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000005	c5615cfe-4f1a-4a3f-86b1-3727c9a02d68
93da870a-3e8e-48de-b7fd-07086e029113	2026-08-05 04:05:59.57384	2026-08-05 04:05:59.57384	Phân công kỹ thuật viên: Kỹ thuật viên B	ASSIGNED	\N	c5615cfe-4f1a-4a3f-86b1-3727c9a02d68
b7c1328f-124e-47cb-a264-6d98e0a6f3eb	2026-08-05 04:06:06.869548	2026-08-05 04:06:06.869548	Đề xuất/Xác nhận khung giờ làm việc: Sáng Thứ Năm (06/08) (8:00 - 11:30)	ASSIGNED	\N	c5615cfe-4f1a-4a3f-86b1-3727c9a02d68
a0be3e4b-e3e2-49c7-a603-5e6e60ff916b	2026-08-05 04:06:13.919097	2026-08-05 04:06:13.919097	Cư dân đã đồng ý khung giờ hẹn	ASSIGNED	b1000000-0000-0000-0000-000000000005	c5615cfe-4f1a-4a3f-86b1-3727c9a02d68
729262ff-ffb2-4b7a-81c7-564fc1702a59	2026-08-05 04:06:46.260031	2026-08-05 04:06:46.260031	Kỹ thuật viên bắt đầu xử lý công việc	IN_PROGRESS	a0000000-0000-0000-0000-000000000003	c5615cfe-4f1a-4a3f-86b1-3727c9a02d68
e9f88fbc-0024-47b6-8a3a-fdbabf25078c	2026-08-05 04:07:11.278	2026-08-05 04:07:11.278	Thêm vật tư: tiền vệ sinh x1 (200000 VNĐ)	IN_PROGRESS	\N	c5615cfe-4f1a-4a3f-86b1-3727c9a02d68
0065e897-6b14-41f8-bd5b-d480f4388ca6	2026-08-05 04:07:17.246987	2026-08-05 04:07:17.246987	vệ sinh điều hòa	IN_PROGRESS	a0000000-0000-0000-0000-000000000003	c5615cfe-4f1a-4a3f-86b1-3727c9a02d68
90c02042-65a5-4160-bb88-5f262c2f69c0	2026-08-05 04:21:26.416565	2026-08-05 04:21:26.416565	Tạo yêu cầu bảo trì mã MNT-20260805-414 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000003	a2ff625f-70a4-461f-9b5d-9557291b7925
3271cad0-13c0-4ceb-95d4-d3010fb2ce85	2026-08-05 04:21:34.1119	2026-08-05 04:21:34.1119	Tạo yêu cầu bảo trì mã MNT-20260805-415 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000003	fa3f4f63-780d-420b-b0a4-a0e2742133dc
d914bd37-1c57-47c2-9cc7-8cff0ca1364b	2026-08-05 04:21:47.707255	2026-08-05 04:21:47.707255	Tạo yêu cầu bảo trì mã MNT-20260805-416 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000003	6d80b26f-78f4-4e44-bed9-599026e0004c
8d845fbc-3d5a-459c-b816-4b7a9012111f	2026-08-05 04:22:10.283724	2026-08-05 04:22:10.283724	Tạo yêu cầu bảo trì mã MNT-20260805-417 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000003	05c52caf-2ab3-4473-8fcd-170dc1849e0c
d65932a1-9eee-4687-85ea-23eefc911810	2026-08-05 04:23:21.81044	2026-08-05 04:23:21.81044	Cập nhật thời gian SLA dự kiến: 2026-08-05T04:23	OPEN	\N	05c52caf-2ab3-4473-8fcd-170dc1849e0c
318e83dd-8e13-4c6d-b08d-83c43fadd328	2026-08-05 04:23:43.836358	2026-08-05 04:23:43.836358	Phân công kỹ thuật viên: Kỹ thuật viên B	ASSIGNED	\N	05c52caf-2ab3-4473-8fcd-170dc1849e0c
0804ca00-6d8f-4d38-98d1-a56ed0eb5e54	2026-08-05 04:23:50.110663	2026-08-05 04:23:50.110663	Phân công kỹ thuật viên: Trần Bá Lãm	ASSIGNED	\N	05c52caf-2ab3-4473-8fcd-170dc1849e0c
94ab63cf-eacf-41df-a467-859b74cfd698	2026-08-05 04:24:12.739896	2026-08-05 04:24:12.739896	Hủy phiếu bảo trì. Lý do: đã được xủ lý	CANCELLED	\N	05c52caf-2ab3-4473-8fcd-170dc1849e0c
ada462aa-cdff-420c-878d-de7273728a6e	2026-08-05 04:25:33.107585	2026-08-05 04:25:33.107585	Tạo yêu cầu bảo trì mã MNT-20260805-418 (NORMAL)	OPEN	b1000000-0000-0000-0000-000000000003	60dab198-f686-47d1-9656-6b7314fbeae3
752f1638-93c9-401e-b3fc-b44560e53b3e	2026-08-05 04:30:30.108962	2026-08-05 04:30:30.108962	Phân công kỹ thuật viên: Trần Bá Lãm	ASSIGNED	\N	60dab198-f686-47d1-9656-6b7314fbeae3
403114ec-2948-4794-8867-bdfcb697d019	2026-08-05 04:30:47.361648	2026-08-05 04:30:47.361648	Kỹ thuật viên bắt đầu xử lý công việc	IN_PROGRESS	7b70cfa6-d414-4165-b17c-dde2c4aea3ba	60dab198-f686-47d1-9656-6b7314fbeae3
a9d13fe4-32bd-4985-92b7-32dac32b3777	2026-08-05 04:35:33.519521	2026-08-05 04:35:33.519521	Thêm vật tư: gas máy lạnh x1 (1500000 VNĐ)	IN_PROGRESS	\N	60dab198-f686-47d1-9656-6b7314fbeae3
2c829473-ca80-4511-afe1-79e3beeeb154	2026-08-05 04:35:35.717578	2026-08-05 04:35:35.717578	Xóa vật tư: gas máy lạnh	IN_PROGRESS	\N	60dab198-f686-47d1-9656-6b7314fbeae3
46e2f884-d806-475e-b2a5-8a0061509a55	2026-08-05 04:35:45.889159	2026-08-05 04:35:45.889159	Thêm vật tư: gas máy lạnh x1 (150000 VNĐ)	IN_PROGRESS	\N	60dab198-f686-47d1-9656-6b7314fbeae3
3e9e3e7a-1676-4d18-ae72-9519780b3b44	2026-08-05 04:36:12.444443	2026-08-05 04:36:12.444443	đã mua dụng cụ	IN_PROGRESS	7b70cfa6-d414-4165-b17c-dde2c4aea3ba	60dab198-f686-47d1-9656-6b7314fbeae3
333d951f-ef01-4a7d-99cb-e6a71b1a6e0a	2026-08-05 06:03:17.020593	2026-08-05 06:03:17.020593	Tạo yêu cầu bảo trì mã MNT-20260805-419 (HIGH)	OPEN	74ccd53e-4998-49a3-97e3-b918b60f4080	10ce7228-811a-4908-a24a-6061f278cc7b
9d0d2ad0-1f4a-4c2a-a7fe-34b84dc73c6c	2026-08-05 06:03:31.307417	2026-08-05 06:03:31.307417	Tạo yêu cầu bảo trì mã MNT-20260805-420 (HIGH)	OPEN	74ccd53e-4998-49a3-97e3-b918b60f4080	483e9cdc-246b-48a5-9a8f-2327910f2b03
47e6368e-2756-4129-9cd8-3e78c04dd200	2026-08-05 06:22:18.310729	2026-08-05 06:22:18.310729	Phân công kỹ thuật viên: Vo Tuan Kiet	ASSIGNED	\N	483e9cdc-246b-48a5-9a8f-2327910f2b03
7a7936b6-0b78-452f-b366-00ecce87aeae	2026-08-05 06:22:45.909994	2026-08-05 06:22:45.909994	Hủy phiếu bảo trì. Lý do: Báo cáo bảo trì bị trùng lập	CANCELLED	\N	10ce7228-811a-4908-a24a-6061f278cc7b
911be13d-2720-4626-bc5d-d2c5c013c9d4	2026-08-05 06:26:30.112132	2026-08-05 06:26:30.112132	Kỹ thuật viên bắt đầu xử lý công việc	IN_PROGRESS	b1000000-0000-0000-0000-000000000008	483e9cdc-246b-48a5-9a8f-2327910f2b03
f864c1c5-2585-4122-a292-907074f082cf	2026-08-05 06:26:47.712696	2026-08-05 06:26:47.712696	Thêm vật tư: Bản lề nhà vệ sinh x1 (0 VNĐ)	IN_PROGRESS	\N	483e9cdc-246b-48a5-9a8f-2327910f2b03
f12b72d5-889f-4b77-8333-e3045f85414c	2026-08-05 06:27:15.776546	2026-08-05 06:27:15.776546	Đang chuẩn bị vật tư để sửa chửa	IN_PROGRESS	b1000000-0000-0000-0000-000000000008	483e9cdc-246b-48a5-9a8f-2327910f2b03
9cd89f9c-feb7-4b4a-8d3d-a3ff75cb5a41	2026-08-05 06:29:03.814524	2026-08-05 06:29:03.814524	Đề xuất/Xác nhận khung giờ làm việc: Sáng Thứ Năm (06/08) (8:00 - 11:30)	OPEN	\N	b8000000-0000-0000-0000-000000000001
468b6f36-6dc8-462c-9de5-7cac91d62c10	2026-08-05 06:30:07.06687	2026-08-05 06:30:07.06687	Tạo yêu cầu bảo trì mã MNT-20260805-421 (HIGH)	OPEN	74ccd53e-4998-49a3-97e3-b918b60f4080	2f6bcc81-68a7-46e1-b7b8-f98bf267fe53
4bce8333-4bfe-469d-8fe1-d42aa301de15	2026-08-05 06:30:26.009125	2026-08-05 06:30:26.009125	Phân công kỹ thuật viên: Vo Tuan Kiet	ASSIGNED	\N	2f6bcc81-68a7-46e1-b7b8-f98bf267fe53
8587275f-a68a-4cc2-851c-83a7bc88afda	2026-08-05 07:25:27.27072	2026-08-05 07:25:27.27072	Kỹ thuật viên bắt đầu xử lý công việc	IN_PROGRESS	7b70cfa6-d414-4165-b17c-dde2c4aea3ba	c5e0255e-0794-408f-9677-5db981f2d32f
57527df7-6f21-4e43-ad7f-500ecc8bdd56	2026-08-05 09:28:09.835604	2026-08-05 09:28:09.835604	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-05T09:23:08.663177)	IN_PROGRESS	\N	babc7312-1c6f-4670-8297-351d392a1996
2d201d4a-8c60-452c-96b1-367567583910	2026-08-05 09:28:09.84591	2026-08-05 09:28:09.84591	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-05T09:22:52.373173)	OPEN	\N	e56e460b-511b-48af-b2ac-3d8e93a464cc
30e5642c-0aa9-4710-9d07-02ee936153b0	2026-08-05 09:28:09.909325	2026-08-05 09:28:09.909325	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-05T09:22:57.102237)	OPEN	\N	3ea22299-cbb4-4730-9ae1-aac56cf897b0
49f6b15d-42f7-48fd-9870-d99ec3d38641	2026-08-05 09:28:09.919586	2026-08-05 09:28:09.919586	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-05T09:23:01.866682)	OPEN	\N	10929fc8-6e84-4107-af9f-50d2aa7fc9c5
5b5ec818-0bf5-4591-b12d-926cc7006122	2026-08-05 09:58:10.342199	2026-08-05 09:58:10.342199	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-05T09:28:52.860010)	OPEN	\N	791b3bc7-973e-4ce9-b0f8-2c2bed1383d5
c48ea4e8-d9c2-4cfc-abfa-63c917c6e13c	2026-08-05 09:58:10.350076	2026-08-05 09:58:10.350076	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-05T09:29:09.765027)	ASSIGNED	\N	ee2e951d-6752-4790-8805-0a21dc2bf15a
ea1e18bd-b47e-46e9-9288-6a60c3f4e047	2026-08-05 14:28:11.634726	2026-08-05 14:28:11.634726	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-05T14:03:31.306291)	IN_PROGRESS	\N	483e9cdc-246b-48a5-9a8f-2327910f2b03
43705bc3-69f7-4bd8-a4db-aca49dd9b46e	2026-08-05 18:58:14.908637	2026-08-05 18:58:14.908637	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-05T18:30:07.066047)	ASSIGNED	\N	2f6bcc81-68a7-46e1-b7b8-f98bf267fe53
ffb20061-7094-47df-9c42-c033a8dad55d	2026-08-06 03:28:16.107115	2026-08-06 03:28:16.107115	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-06T03:27:49.060782)	OPEN	\N	a4af8910-9741-45c9-81c7-a5fc5c5b6407
32411525-875d-41fc-a63d-bdfd89b7a116	2026-08-06 03:28:16.316727	2026-08-06 03:28:16.316727	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-06T03:27:57.067795)	OPEN	\N	94595db1-e24a-4a26-a28e-4a1e73bb8814
d366fd9e-1106-400f-98f9-74af64888133	2026-08-06 03:58:20.241106	2026-08-06 03:58:20.241106	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-06T03:28:16.212575)	IN_PROGRESS	\N	db9a9713-3331-441f-84c5-ea3e5abb1197
cbe537b1-95fb-4bab-ab65-2812f27d2552	2026-08-06 03:58:22.4067	2026-08-06 03:58:22.4067	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-06T03:57:59.724699)	IN_PROGRESS	\N	b7b0c13c-2dbe-4d08-b81c-032624bfe278
8c8214c1-2b46-4eba-934a-4afc265bcab4	2026-08-06 03:58:22.510907	2026-08-06 03:58:22.510907	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-06T03:54:09.578814)	IN_PROGRESS	\N	0f0f870b-8625-4306-84b4-61e3c78ae7e2
d292f950-502c-4446-b2ec-3f2cdc6ae756	2026-08-06 04:28:23.109669	2026-08-06 04:28:23.109669	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-06T04:04:22.233171)	IN_PROGRESS	\N	c5615cfe-4f1a-4a3f-86b1-3727c9a02d68
7904ed39-7f91-48a2-a1d7-a06c61fbb493	2026-08-06 04:28:23.221309	2026-08-06 04:28:23.221309	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-06T04:21:34.111135)	OPEN	\N	fa3f4f63-780d-420b-b0a4-a0e2742133dc
6bc1262f-9232-432a-9ee0-4881ac2069cb	2026-08-06 04:28:23.310821	2026-08-06 04:28:23.310821	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-06T04:21:26.415556)	OPEN	\N	a2ff625f-70a4-461f-9b5d-9557291b7925
c266dd8b-5973-4ba0-ad26-5b3a45554717	2026-08-06 04:28:23.317927	2026-08-06 04:28:23.317927	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-06T04:21:47.706162)	OPEN	\N	6d80b26f-78f4-4e44-bed9-599026e0004c
6ac63563-a363-46d7-b5e7-c3b867e56f82	2026-08-06 04:28:23.410841	2026-08-06 04:28:23.410841	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-06T04:25:33.106151)	IN_PROGRESS	\N	60dab198-f686-47d1-9656-6b7314fbeae3
43e813d2-cd5f-40ec-b537-87a448592004	2026-08-06 15:07:10.566039	2026-08-06 15:07:10.566039	Đề xuất/Xác nhận khung giờ làm việc: Sáng Thứ Sáu (07/08) (8:00 - 11:30)	ASSIGNED	\N	2f6bcc81-68a7-46e1-b7b8-f98bf267fe53
dd50fcad-0736-44f2-9be6-b6940dc52b9a	2026-08-06 15:22:10.515783	2026-08-06 15:22:10.515783	Tạo yêu cầu bảo trì mã MNT-20260806-491 (HIGH)	OPEN	33712636-202b-4ff3-8011-2da710d65035	229d8e58-ffbe-44d4-8909-3e92985cfe8c
f2b5123f-8551-4a1e-af19-884fd317174c	2026-08-06 15:22:18.691748	2026-08-06 15:22:18.691748	Phân công kỹ thuật viên: Vo Tuan Kiet	ASSIGNED	\N	229d8e58-ffbe-44d4-8909-3e92985cfe8c
63a88a9d-f9f9-4b4b-a1c5-cdb649157e30	2026-08-06 15:22:27.436144	2026-08-06 15:22:27.436144	Đề xuất/Xác nhận khung giờ làm việc: Tối nay (18:00 - 20:30)	ASSIGNED	\N	229d8e58-ffbe-44d4-8909-3e92985cfe8c
33424bef-ca94-401f-8a87-2da7ae646b15	2026-08-06 15:34:49.550328	2026-08-06 15:34:49.550328	Cư dân đã đồng ý khung giờ hẹn	ASSIGNED	33712636-202b-4ff3-8011-2da710d65035	229d8e58-ffbe-44d4-8909-3e92985cfe8c
9e9b0132-22f6-42bd-98cc-adb04d4fc1ef	2026-08-06 16:42:55.491432	2026-08-06 16:42:55.491432	Kỹ thuật viên bắt đầu xử lý công việc	IN_PROGRESS	b1000000-0000-0000-0000-000000000008	229d8e58-ffbe-44d4-8909-3e92985cfe8c
b8ebd5fe-4023-4a9c-ac3a-17a12c343bde	2026-08-06 21:30:35.691922	2026-08-06 21:30:35.691922	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-06T21:22:10.513911)	IN_PROGRESS	\N	229d8e58-ffbe-44d4-8909-3e92985cfe8c
07ec732a-1a1a-4989-b10f-4aba8f0a4d67	2026-08-09 16:01:33.186675	2026-08-09 16:01:33.186675	Tạo yêu cầu bảo trì mã MNT-20260809-282 (HIGH)	OPEN	b1000000-0000-0000-0000-000000000002	849c05ad-e3b6-4c8b-9f10-3db67d42a9e6
4fbe29ab-a25c-4d27-9c86-23553c27b668	2026-08-09 16:03:31.193473	2026-08-09 16:03:31.193473	Phân công kỹ thuật viên: Kỹ thuật viên B	ASSIGNED	\N	849c05ad-e3b6-4c8b-9f10-3db67d42a9e6
6932885e-dc6e-45cd-ac97-a239f3209932	2026-08-09 16:03:51.537441	2026-08-09 16:03:51.537441	Đề xuất/Xác nhận khung giờ làm việc: Sáng Thứ Hai (10/08) (8:00 - 11:30)	ASSIGNED	\N	849c05ad-e3b6-4c8b-9f10-3db67d42a9e6
4528c681-f13f-46db-83b1-9b71ebcc4386	2026-08-09 16:04:39.918743	2026-08-09 16:04:39.918743	Cư dân đã đồng ý khung giờ hẹn	ASSIGNED	b1000000-0000-0000-0000-000000000002	849c05ad-e3b6-4c8b-9f10-3db67d42a9e6
dc9e3edc-acee-4983-b9e6-c7a98e6b7471	2026-08-09 16:04:56.892621	2026-08-09 16:04:56.892621	Kỹ thuật viên bắt đầu xử lý công việc	IN_PROGRESS	a0000000-0000-0000-0000-000000000003	849c05ad-e3b6-4c8b-9f10-3db67d42a9e6
93f391bb-d097-44ad-be45-100621774309	2026-08-09 22:22:14.769736	2026-08-09 22:22:14.769736	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-09T22:01:33.184067)	IN_PROGRESS	\N	849c05ad-e3b6-4c8b-9f10-3db67d42a9e6
a03bddbc-e7dc-43c0-b2b6-0b841b7d0cca	2026-08-14 04:28:39.863888	2026-08-14 04:28:39.863888	Tạo yêu cầu bảo trì mã MNT-20260814-568 (HIGH)	OPEN	b1000000-0000-0000-0000-000000000005	c05e9333-2746-4b7f-9a01-8182f91ffa93
e6611a8b-7c37-4aea-9bd8-f8827851985a	2026-08-14 04:29:42.183164	2026-08-14 04:29:42.183164	Phân công kỹ thuật viên: Kỹ thuật viên B	ASSIGNED	\N	c05e9333-2746-4b7f-9a01-8182f91ffa93
d0a506fb-eb75-4018-8c0a-64912f8e6dc5	2026-08-14 04:30:12.414167	2026-08-14 04:30:12.414167	Đề xuất/Xác nhận khung giờ làm việc: Sáng Thứ Bảy (15/08) (8:00 - 11:30)	ASSIGNED	\N	c05e9333-2746-4b7f-9a01-8182f91ffa93
43185e1a-fdec-4bf8-8329-b37107f32124	2026-08-14 16:48:56.781673	2026-08-14 16:48:56.781673	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-14T16:28:39.767331)	ASSIGNED	\N	c05e9333-2746-4b7f-9a01-8182f91ffa93
89b104ce-2cad-4422-8cea-476b7e1d9023	2026-08-19 07:06:12.955864	2026-08-19 07:06:12.955864	Tạo yêu cầu bảo trì mã MNT-20260819-063 (HIGH)	OPEN	b1000000-0000-0000-0000-000000000002	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185
e10f4861-ef56-48f3-b433-f0d793cd91dd	2026-08-19 07:06:40.059515	2026-08-19 07:06:40.059515	Hủy phiếu bảo trì. Lý do: Bắt buộc huỷ	CANCELLED	\N	c05e9333-2746-4b7f-9a01-8182f91ffa93
7d91dc66-2327-4010-8b7d-8e6eb9e6ffdb	2026-08-19 07:06:45.174946	2026-08-19 07:06:45.174946	Phân công kỹ thuật viên: Kĩ Thuật Viên A	ASSIGNED	\N	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185
6db9406e-ddc3-4473-933b-2540b6be9aa5	2026-08-19 07:06:54.050812	2026-08-19 07:06:54.050812	Đề xuất/Xác nhận khung giờ làm việc: Chiều Thứ Năm (20/08) (13:30 - 17:00)	ASSIGNED	\N	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185
76b4eb44-3c6b-4981-905f-382dee5692b7	2026-08-19 07:07:06.428359	2026-08-19 07:07:06.428359	Cư dân đã đồng ý khung giờ hẹn	ASSIGNED	b1000000-0000-0000-0000-000000000002	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185
0beb7991-056a-4fc7-b0d6-cb2b8a83d46f	2026-08-19 07:07:09.570602	2026-08-19 07:07:09.570602	Kỹ thuật viên bắt đầu xử lý công việc	IN_PROGRESS	936bdf00-c9f0-4889-80fc-86f3a59d051e	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185
b1e89a00-c583-408f-8c66-da93dad4919e	2026-08-19 07:07:38.356102	2026-08-19 07:07:38.356102	Thêm vật tư: Cp mới x1 (50000 VNĐ)	IN_PROGRESS	\N	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185
3f7578f0-1a52-4b72-b949-c80538229c72	2026-08-19 13:31:56.612947	2026-08-19 13:31:56.612947	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-19T13:06:12.860776)	IN_PROGRESS	\N	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185
b741dd74-e333-4b10-97ef-97fde6b03464	2026-08-21 01:52:12.167828	2026-08-21 01:52:12.167828	Tạo yêu cầu bảo trì mã MNT-20260821-064 (NORMAL)	OPEN	3589890e-f56b-4dbc-84fc-12e319e1d750	ea9d94f1-b8ff-45da-9312-91c673eaa885
43cead72-d169-49be-8314-c1b2621c5846	2026-08-21 01:52:48.555214	2026-08-21 01:52:48.555214	Phân công kỹ thuật viên: Phan Duc Huy	ASSIGNED	\N	ea9d94f1-b8ff-45da-9312-91c673eaa885
3aacab28-03fb-4301-b4f3-e600ed27a66b	2026-08-22 02:01:58.455572	2026-08-22 02:01:58.455572	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-22T01:52:12.167097)	ASSIGNED	\N	ea9d94f1-b8ff-45da-9312-91c673eaa885
d6e75ec5-3973-4cf5-86af-401a2a4e6fcf	2026-08-22 13:17:35.699831	2026-08-22 13:17:35.699831	Hủy phiếu bảo trì. Lý do: nahhhhhhhhh	CANCELLED	\N	ea9d94f1-b8ff-45da-9312-91c673eaa885
30473c47-551b-4035-884a-a99a2930fc97	2026-08-22 13:40:56.812585	2026-08-22 13:40:56.812585	Báo giá vật tư: 50000.00 VNĐ, chuyển chờ thanh toán	PENDING_PAYMENT	936bdf00-c9f0-4889-80fc-86f3a59d051e	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185
1ce4d493-c0d9-4dd4-8408-1a1c22a85ab0	2026-08-22 13:41:15.563577	2026-08-22 13:41:15.563577	Đã xác nhận thanh toán chi phí vật tư: 50000.00 VNĐ	PENDING_REVIEW	b1000000-0000-0000-0000-000000000002	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185
7f7f9121-6769-4de1-ae7b-518f57326b43	2026-08-22 13:41:24.435649	2026-08-22 13:41:24.435649	Xác nhận nghiệm thu hoàn thành phiếu bảo trì	DONE	\N	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185
b986ec9b-ccd7-42ad-ab7b-486b6b2e81c7	2026-08-22 13:42:19.118272	2026-08-22 13:42:19.118272	Tạo yêu cầu bảo trì mã MNT-20260822-012 (HIGH)	OPEN	b1000000-0000-0000-0000-000000000002	69839fb2-7b7c-41fe-9a50-431b132a54ce
7c8ec64b-94f6-4627-9192-4261f720f31f	2026-08-22 13:42:40.01712	2026-08-22 13:42:40.01712	Phân công kỹ thuật viên: Kĩ Thuật Viên A	ASSIGNED	\N	69839fb2-7b7c-41fe-9a50-431b132a54ce
a18068d3-3071-4bff-b737-72c9d70d51d5	2026-08-22 13:42:51.393305	2026-08-22 13:42:51.393305	Đề xuất/Xác nhận khung giờ làm việc: Chiều Chủ Nhật (23/08) (13:30 - 17:00)	ASSIGNED	\N	69839fb2-7b7c-41fe-9a50-431b132a54ce
a11290c3-14b0-4c36-979f-d16d2ac7439a	2026-08-22 13:42:54.211695	2026-08-22 13:42:54.211695	Cư dân đã đồng ý khung giờ hẹn	ASSIGNED	b1000000-0000-0000-0000-000000000002	69839fb2-7b7c-41fe-9a50-431b132a54ce
c940bb05-c625-48b1-8c0d-50dd23ce257e	2026-08-22 13:42:58.712787	2026-08-22 13:42:58.712787	Kỹ thuật viên bắt đầu xử lý công việc	IN_PROGRESS	936bdf00-c9f0-4889-80fc-86f3a59d051e	69839fb2-7b7c-41fe-9a50-431b132a54ce
b5e92fa2-5996-47e2-af45-1aa9593818d3	2026-08-22 13:43:34.711492	2026-08-22 13:43:34.711492	Hoàn tất xử lý, gửi yêu cầu nghiệm thu cho cư dân/ban quản lý	PENDING_REVIEW	936bdf00-c9f0-4889-80fc-86f3a59d051e	69839fb2-7b7c-41fe-9a50-431b132a54ce
81833628-3bfc-4544-a2b8-2a76453714bb	2026-08-22 13:43:42.113764	2026-08-22 13:43:42.113764	Xác nhận nghiệm thu hoàn thành phiếu bảo trì	DONE	\N	69839fb2-7b7c-41fe-9a50-431b132a54ce
f3858c2d-a914-4afd-ac18-10fbbd5f7cde	2026-08-22 13:46:25.519536	2026-08-22 13:46:25.519536	Báo giá vật tư: 240000.00 VNĐ, chuyển chờ thanh toán	PENDING_PAYMENT	774a2c9e-8929-4d7c-80ca-14f62b9d9d56	db9a9713-3331-441f-84c5-ea3e5abb1197
ba323251-cbc1-4fb8-b68f-f5c97b6e1be8	2026-08-22 13:46:45.411001	2026-08-22 13:46:45.411001	Báo giá vật tư: 20000.00 VNĐ, chuyển chờ thanh toán	PENDING_PAYMENT	774a2c9e-8929-4d7c-80ca-14f62b9d9d56	0f0f870b-8625-4306-84b4-61e3c78ae7e2
94c14bdb-1a79-4408-ad9b-a14c6bb4439a	2026-08-22 13:46:49.117393	2026-08-22 13:46:49.117393	Báo giá vật tư: 20000.00 VNĐ, chuyển chờ thanh toán	PENDING_PAYMENT	774a2c9e-8929-4d7c-80ca-14f62b9d9d56	0f0f870b-8625-4306-84b4-61e3c78ae7e2
d37ae36d-fc23-44b0-8eb2-a6fe05000e7f	2026-08-22 13:46:53.117913	2026-08-22 13:46:53.117913	Báo giá vật tư: 20000.00 VNĐ, chuyển chờ thanh toán	PENDING_PAYMENT	774a2c9e-8929-4d7c-80ca-14f62b9d9d56	0f0f870b-8625-4306-84b4-61e3c78ae7e2
c1314c3d-5caa-4198-8bc4-bca021fa2af1	2026-08-22 14:47:23.322947	2026-08-22 14:47:23.322947	Tạo yêu cầu bảo trì mã MNT-20260822-124 (HIGH)	OPEN	b1000000-0000-0000-0000-000000000002	b7a2d2ad-c428-4c0d-8802-256afd8979d4
a257ae76-7abb-4045-8ab7-3349f79b0f4b	2026-08-22 14:47:52.947631	2026-08-22 14:47:52.947631	Phân công kỹ thuật viên: Kĩ Thuật Viên A	ASSIGNED	\N	b7a2d2ad-c428-4c0d-8802-256afd8979d4
9e468856-821a-4f31-9197-7ba4f77bebe5	2026-08-22 14:47:59.154949	2026-08-22 14:47:59.154949	Đề xuất/Xác nhận khung giờ làm việc: Sáng Chủ Nhật (23/08) (8:00 - 11:30)	ASSIGNED	\N	b7a2d2ad-c428-4c0d-8802-256afd8979d4
534bf53c-a692-4500-a418-5e189584483f	2026-08-22 14:48:02.125361	2026-08-22 14:48:02.125361	Cư dân đã đồng ý khung giờ hẹn	ASSIGNED	b1000000-0000-0000-0000-000000000002	b7a2d2ad-c428-4c0d-8802-256afd8979d4
281c0385-ad98-4273-ab5b-fc3067a2b636	2026-08-22 14:48:04.558072	2026-08-22 14:48:04.558072	Kỹ thuật viên bắt đầu xử lý công việc	IN_PROGRESS	936bdf00-c9f0-4889-80fc-86f3a59d051e	b7a2d2ad-c428-4c0d-8802-256afd8979d4
8d2c9a3e-1bf7-4ce9-9a40-76aee2d5a2fe	2026-08-22 14:48:21.283352	2026-08-22 14:48:21.283352	Hoàn tất xử lý, gửi yêu cầu nghiệm thu cho cư dân/ban quản lý	PENDING_REVIEW	936bdf00-c9f0-4889-80fc-86f3a59d051e	b7a2d2ad-c428-4c0d-8802-256afd8979d4
24cc77bc-9a92-42bc-bac2-6c48c6119475	2026-08-22 14:48:29.424689	2026-08-22 14:48:29.424689	Xác nhận nghiệm thu hoàn thành phiếu bảo trì	DONE	\N	b7a2d2ad-c428-4c0d-8802-256afd8979d4
\.


--
-- Data for Name: maintenance_preferred_slots; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.maintenance_preferred_slots (request_id, time_slot) FROM stdin;
2e661bb3-5cf3-462f-9cde-510a75a5d1a3	Tối (18:00 - 20:30)
300cfc87-df62-4a88-9887-9034ad1266d5	Tối (18:00 - 20:30)
04a53e7e-15a4-4a9d-afed-567596ae20c6	Tối (18:00 - 20:30)
aa5bed2d-405c-4a8b-8ce3-bb9bfef19dfb	Tối (18:00 - 20:30)
f9c6f0d8-16f0-483f-b043-d2e389493f60	Tối (18:00 - 20:30)
ed7264e5-49b9-43c1-9d82-2f63c8019d6e	Tối (18:00 - 20:30)
caf31977-a7ff-49eb-8166-c8e852487a09	Tối (18:00 - 20:30)
8ce7171e-c161-4408-a821-3b0aed85847c	Tối (18:00 - 20:30)
536a593e-7fa7-4273-bcbd-bb776de0254e	Chiều (13:30 - 17:00)
dd480a87-1683-40f9-9839-48a4770ebebb	Chiều (13:30 - 17:00)
84941eb2-0626-4f31-a574-745466e0a083	Chiều (13:30 - 17:00)
a3ed57fb-af95-4f3d-9b8d-c8b24b7a4f3c	Chiều (13:30 - 17:00)
8f3a647b-4162-4c49-8567-d09c35e04ad2	Chiều (13:30 - 17:00)
f9e43efa-0144-4dbe-820c-59e4141ceeb8	Chiều (13:30 - 17:00)
6d2de875-2fdb-45e7-b621-17bd86226815	Chiều (13:30 - 17:00)
08ee7530-a733-485e-b1bd-579a997d77fc	Chiều (13:30 - 17:00)
e3cbf44f-70c1-4065-b448-bfe6fd3eb84b	Chiều (13:30 - 17:00)
b37d3442-70c1-44a7-8b0f-c16e3d2d05fd	Chiều (13:30 - 17:00)
a37395c2-abfd-4627-a2ed-a449d870d276	Chiều (13:30 - 17:00)
64f5b409-34d7-4499-9ad2-0fa043005180	Chiều (13:30 - 17:00)
2119d259-d667-4994-8cb4-2d4f7f483e5b	Chiều (13:30 - 17:00)
ad47bc66-00e6-465f-a441-04449b1d21ad	Chiều (13:30 - 17:00)
438c33ae-4853-4877-b39c-e7f07ae3e9b4	Chiều (13:30 - 17:00)
cbf3b404-01fb-4818-bba9-f0887479ac1d	Chiều (13:30 - 17:00)
46ef6bd0-e132-490d-8261-763260644448	Chiều (13:30 - 17:00)
757ba10e-11c3-481b-a30b-1b826b7f8ff0	Chiều (13:30 - 17:00)
86d24202-5c2b-480f-beb2-0915096f911e	Chiều (13:30 - 17:00)
e0dd70bc-3417-4d3e-aa7c-b7710a2308da	Chiều (13:30 - 17:00)
afc5b633-7812-4726-ad5d-a1de1587fadd	Chiều (13:30 - 17:00)
2bee013f-38eb-4113-a2e0-a67a9385fe71	Chiều (13:30 - 17:00)
dc04e66c-f7b1-4bf6-92b7-3128d587dc94	Sáng (08:00 - 11:30)
c6587d83-4725-4763-a7f1-fa8288d9b863	Sáng (08:00 - 11:30)
49fbc40e-667c-4252-9de8-57f155b09e78	Chiều (13:30 - 17:00)
e5e71416-e20c-4297-bc9b-64733d07f45f	Chiều (13:30 - 17:00)
a1dc49c3-f49f-4a54-a478-20c063c80cc6	Chiều (13:30 - 17:00)
85ae8e7b-b3f2-4640-9ace-f8fa69761a9d	Chiều (13:30 - 17:00)
6c0b25e4-a92e-40d9-8480-03e5efe58461	Sáng (08:00 - 11:30)
6c0b25e4-a92e-40d9-8480-03e5efe58461	Chiều (13:30 - 17:00)
7c657edc-5072-4c13-9e24-0dba94836489	Sáng (08:00 - 11:30)
7c657edc-5072-4c13-9e24-0dba94836489	Chiều (13:30 - 17:00)
afab1b6d-6ae8-4337-84a6-982a90835589	Sáng (08:00 - 11:30)
ca7af936-6596-4ccf-ab2b-588a1ba131e7	Sáng (08:00 - 11:30)
b0544e1c-d3f6-4441-a690-c2c0bdd83920	Sáng (08:00 - 11:30)
b0544e1c-d3f6-4441-a690-c2c0bdd83920	Tối (18:00 - 20:30)
e1f8ef7c-720f-4d71-ab02-e761f4cd93d2	Sáng (08:00 - 11:30)
e1f8ef7c-720f-4d71-ab02-e761f4cd93d2	Tối (18:00 - 20:30)
3e412a56-e4c8-45ef-bc2c-488e118c0651	Sáng (08:00 - 11:30)
de307c0f-3c70-4767-9a77-6adb46585bb4	Sáng (08:00 - 11:30)
de307c0f-3c70-4767-9a77-6adb46585bb4	Chiều (13:30 - 17:00)
de307c0f-3c70-4767-9a77-6adb46585bb4	Tối (18:00 - 20:30)
de307c0f-3c70-4767-9a77-6adb46585bb4	Cuối tuần (Thứ 7 - CN)
2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9	Sáng (08:00 - 11:30)
2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9	Chiều (13:30 - 17:00)
2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9	Tối (18:00 - 20:30)
2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9	Cuối tuần (Thứ 7 - CN)
8721cde2-53f1-478e-842d-63cef0d8e17a	Sáng (08:00 - 11:30)
8721cde2-53f1-478e-842d-63cef0d8e17a	Chiều (13:30 - 17:00)
8721cde2-53f1-478e-842d-63cef0d8e17a	Tối (18:00 - 20:30)
8721cde2-53f1-478e-842d-63cef0d8e17a	Cuối tuần (Thứ 7 - CN)
e3a2fec5-a9ad-409f-944d-ef61236f54cc	Sáng (08:00 - 11:30)
919b3461-8baf-4669-b0fc-e66c998d0c38	Cuối tuần (Thứ 7 - CN)
797fc693-e426-43c8-be82-06e318cd6b46	Cuối tuần (Thứ 7 - CN)
5bd48f3a-3600-45a2-a302-3698710235a2	Cuối tuần (Thứ 7 - CN)
c2738e46-85d0-45f2-b0d6-ae16f04d1cad	Cuối tuần (Thứ 7 - CN)
9b31d59a-e23c-4ea5-9b4c-957406f94725	Cuối tuần (Thứ 7 - CN)
de427a93-5a73-4187-b30c-6b18f1d8073e	Cuối tuần (Thứ 7 - CN)
cbf3facb-8486-47b7-b951-cea864340b19	Cuối tuần (Thứ 7 - CN)
c5e0255e-0794-408f-9677-5db981f2d32f	Cuối tuần (Thứ 7 - CN)
92b4e6ca-0abe-429e-8385-18666f89cd13	Cuối tuần (Thứ 7 - CN)
e56e460b-511b-48af-b2ac-3d8e93a464cc	Chiều (13:30 - 17:00)
3ea22299-cbb4-4730-9ae1-aac56cf897b0	Chiều (13:30 - 17:00)
10929fc8-6e84-4107-af9f-50d2aa7fc9c5	Chiều (13:30 - 17:00)
babc7312-1c6f-4670-8297-351d392a1996	Chiều (13:30 - 17:00)
791b3bc7-973e-4ce9-b0f8-2c2bed1383d5	Chiều (13:30 - 17:00)
a4af8910-9741-45c9-81c7-a5fc5c5b6407	Chiều (13:30 - 17:00)
94595db1-e24a-4a26-a28e-4a1e73bb8814	Chiều (13:30 - 17:00)
db9a9713-3331-441f-84c5-ea3e5abb1197	Chiều (13:30 - 17:00)
0f0f870b-8625-4306-84b4-61e3c78ae7e2	Tối (18:00 - 20:30)
b7b0c13c-2dbe-4d08-b81c-032624bfe278	Chiều (13:30 - 17:00)
c5615cfe-4f1a-4a3f-86b1-3727c9a02d68	Chiều (13:30 - 17:00)
a2ff625f-70a4-461f-9b5d-9557291b7925	Tối (18:00 - 20:30)
fa3f4f63-780d-420b-b0a4-a0e2742133dc	Tối (18:00 - 20:30)
6d80b26f-78f4-4e44-bed9-599026e0004c	Tối (18:00 - 20:30)
05c52caf-2ab3-4473-8fcd-170dc1849e0c	Tối (18:00 - 20:30)
60dab198-f686-47d1-9656-6b7314fbeae3	Sáng (08:00 - 11:30)
10ce7228-811a-4908-a24a-6061f278cc7b	Sáng (08:00 - 11:30)
483e9cdc-246b-48a5-9a8f-2327910f2b03	Sáng (08:00 - 11:30)
2f6bcc81-68a7-46e1-b7b8-f98bf267fe53	Cuối tuần (Thứ 7 - CN)
849c05ad-e3b6-4c8b-9f10-3db67d42a9e6	Sáng (08:00 - 11:30)
c05e9333-2746-4b7f-9a01-8182f91ffa93	Chiều (13:30 - 17:00)
7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185	Chiều (13:30 - 17:00)
ea9d94f1-b8ff-45da-9312-91c673eaa885	Tối (18:00 - 20:30)
ea9d94f1-b8ff-45da-9312-91c673eaa885	Sáng (08:00 - 11:30)
ea9d94f1-b8ff-45da-9312-91c673eaa885	Cuối tuần (Thứ 7 - CN)
ea9d94f1-b8ff-45da-9312-91c673eaa885	Chiều (13:30 - 17:00)
69839fb2-7b7c-41fe-9a50-431b132a54ce	Chiều (13:30 - 17:00)
b7a2d2ad-c428-4c0d-8802-256afd8979d4	Chiều (13:30 - 17:00)
\.


--
-- Data for Name: maintenance_requests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.maintenance_requests (id, created_at, updated_at, attachment_video, cancel_reason, category, complain_reason, confirm_slot_by_tenant, confirmed_time_slot, description, expected_resolved_at, is_complained, is_overdue_sla, material_cost, material_paid_at, priority, resolved_at, started_at, status, ticket_code, title, assigned_to, room_id, tenant_id, slot_declined_by_tenant, completion_video) FROM stdin;
b8000000-0000-0000-0000-000000000002	2026-06-27 18:10:00	2026-06-30 08:15:00	\N	\N	FURNITURE	\N	\N	\N	Ban le cua phong tam keu lon, can them dau mo va siet lai.	\N	\N	\N	\N	\N	NORMAL	\N	\N	IN_PROGRESS	MNT-20260627-002	Cua phong tam bi keu	b1000000-0000-0000-0000-000000000009	b5000000-0000-0000-0000-000000000004	b1000000-0000-0000-0000-000000000004	\N	\N
b8000000-0000-0000-0000-000000000003	2026-06-24 19:45:00	2026-06-25 15:40:00	\N	\N	ELECTRIC	\N	\N	\N	Da thay bong den moi nhung van khong sang, nghi la do cong tac.	\N	\N	\N	\N	\N	NORMAL	2026-06-25 15:40:00	\N	DONE	MNT-20260624-003	Den ban cong khong sang	b1000000-0000-0000-0000-000000000008	b5000000-0000-0000-0000-000000000009	b1000000-0000-0000-0000-000000000007	\N	\N
86d24202-5c2b-480f-beb2-0915096f911e	2026-07-27 07:08:58.512904	2026-07-27 13:38:27.427098	\N	\N	AIR_CONDITIONER	\N	f	\N	Điều hòa mở thì lên nhưng mà không có hơi mát phà ra	2026-07-27 13:08:58.512633	f	t	0.00	\N	HIGH	\N	\N	OPEN	MNT-20260727-834	Điều hòa không mát	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
2e661bb3-5cf3-462f-9cde-510a75a5d1a3	2026-07-27 06:53:31.701374	2026-07-28 07:08:30.9033	\N	\N	AIR_CONDITIONER	\N	f	\N	bật máy lạnh điều hoà chảy nước ra từ máy lạnh thay vì chảy qua đường ống	2026-07-28 06:53:31.610002	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260727-808	điều hoà bị chảy nước	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
300cfc87-df62-4a88-9887-9034ad1266d5	2026-07-27 06:53:33.209694	2026-07-28 07:08:30.903573	\N	\N	AIR_CONDITIONER	\N	f	\N	bật máy lạnh điều hoà chảy nước ra từ máy lạnh thay vì chảy qua đường ống	2026-07-28 06:53:33.209308	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260727-809	điều hoà bị chảy nước	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
04a53e7e-15a4-4a9d-afed-567596ae20c6	2026-07-27 06:53:39.605817	2026-07-28 07:08:30.903731	\N	\N	AIR_CONDITIONER	\N	f	\N	bật máy lạnh điều hoà chảy nước ra từ máy lạnh thay vì chảy qua đường ống	2026-07-28 06:53:39.605437	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260727-810	điều hoà bị chảy nước	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
aa5bed2d-405c-4a8b-8ce3-bb9bfef19dfb	2026-07-27 06:53:40.184539	2026-07-28 07:08:30.903891	\N	\N	AIR_CONDITIONER	\N	f	\N	bật máy lạnh điều hoà chảy nước ra từ máy lạnh thay vì chảy qua đường ống	2026-07-28 06:53:40.184142	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260727-811	điều hoà bị chảy nước	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
f9c6f0d8-16f0-483f-b043-d2e389493f60	2026-07-27 06:53:59.007438	2026-07-28 07:08:30.904067	\N	\N	AIR_CONDITIONER	\N	f	\N	bật máy lạnh điều hoà chảy nước ra từ máy lạnh thay vì chảy qua đường ống	2026-07-28 06:53:59.007012	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260727-812	điều hoà bị chảy nước	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
ed7264e5-49b9-43c1-9d82-2f63c8019d6e	2026-07-27 06:53:59.508481	2026-07-28 07:08:30.904175	\N	\N	AIR_CONDITIONER	\N	f	\N	bật máy lạnh điều hoà chảy nước ra từ máy lạnh thay vì chảy qua đường ống	2026-07-28 06:53:59.508061	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260727-813	điều hoà bị chảy nước	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
caf31977-a7ff-49eb-8166-c8e852487a09	2026-07-27 06:57:48.952571	2026-07-28 07:08:30.904288	\N	\N	AIR_CONDITIONER	\N	f	\N	bật máy lạnh điều hoà chảy nước ra từ máy lạnh thay vì chảy qua đường ống	2026-07-28 06:57:48.952294	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260727-814	điều hoà bị chảy nước	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
b8000000-0000-0000-0000-000000000001	2026-06-29 20:35:00	2026-08-05 06:29:05.909249	\N	\N	AIR_CONDITIONER	\N	f	Sáng Thứ Năm (06/08) (8:00 - 11:30)	May lanh van chay nhung khong du mat, dac biet tu 20h tro di.	\N	\N	\N	\N	\N	HIGH	\N	\N	OPEN	MNT-20260629-001	Dieu hoa lanh yeu vao buoi toi	b1000000-0000-0000-0000-000000000008	b5000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000003	f	\N
e0dd70bc-3417-4d3e-aa7c-b7710a2308da	2026-07-27 07:08:58.849507	2026-07-27 13:38:27.427153	\N	\N	AIR_CONDITIONER	\N	f	\N	Điều hòa mở thì lên nhưng mà không có hơi mát phà ra	2026-07-27 13:08:58.849179	f	t	0.00	\N	HIGH	\N	\N	OPEN	MNT-20260727-835	Điều hòa không mát	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
afc5b633-7812-4726-ad5d-a1de1587fadd	2026-07-27 07:10:13.91939	2026-07-27 13:38:27.427176	\N	\N	AIR_CONDITIONER	\N	f	\N	Điều hòa mở thì lên nhưng mà không có hơi mát phà ra	2026-07-27 13:10:13.918996	f	t	0.00	\N	HIGH	\N	\N	OPEN	MNT-20260727-836	Điều hòa không mát	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
536a593e-7fa7-4273-bcbd-bb776de0254e	2026-07-27 06:58:57.908711	2026-07-27 13:08:27.195104	\N	\N	AIR_CONDITIONER	\N	f	\N	bật máy lại thì lên nhưng mà không có hơi lạnh phà ra	2026-07-27 12:58:57.908348	f	t	0.00	\N	HIGH	\N	\N	OPEN	MNT-20260727-816	điều hoà không hoạt động	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
dd480a87-1683-40f9-9839-48a4770ebebb	2026-07-27 06:58:58.440254	2026-07-27 13:08:27.195193	\N	\N	AIR_CONDITIONER	\N	f	\N	bật máy lại thì lên nhưng mà không có hơi lạnh phà ra	2026-07-27 12:58:58.439841	f	t	0.00	\N	HIGH	\N	\N	OPEN	MNT-20260727-817	điều hoà không hoạt động	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
84941eb2-0626-4f31-a574-745466e0a083	2026-07-27 06:59:03.005156	2026-07-27 13:08:27.195312	\N	\N	AIR_CONDITIONER	\N	f	\N	bật máy lại thì lên nhưng mà không có hơi lạnh phà ra	2026-07-27 12:59:03.004817	f	t	0.00	\N	HIGH	\N	\N	OPEN	MNT-20260727-818	điều hoà không hoạt động	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
a3ed57fb-af95-4f3d-9b8d-c8b24b7a4f3c	2026-07-27 06:59:03.45781	2026-07-27 13:08:27.19536	\N	\N	AIR_CONDITIONER	\N	f	\N	bật máy lại thì lên nhưng mà không có hơi lạnh phà ra	2026-07-27 12:59:03.457494	f	t	0.00	\N	HIGH	\N	\N	OPEN	MNT-20260727-819	điều hoà không hoạt động	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
438c33ae-4853-4877-b39c-e7f07ae3e9b4	2026-07-27 07:07:52.42906	2026-07-27 13:08:27.195383	\N	\N	AIR_CONDITIONER	\N	f	\N	Điều hòa mở thì lên nhưng mà không có hơi mát phà ra	2026-07-27 13:07:52.428704	f	t	0.00	\N	HIGH	\N	\N	OPEN	MNT-20260727-830	Điều hòa không mát	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
cbf3b404-01fb-4818-bba9-f0887479ac1d	2026-07-27 07:07:52.977202	2026-07-27 13:08:27.195401	\N	\N	AIR_CONDITIONER	\N	f	\N	Điều hòa mở thì lên nhưng mà không có hơi mát phà ra	2026-07-27 13:07:52.976902	f	t	0.00	\N	HIGH	\N	\N	OPEN	MNT-20260727-831	Điều hòa không mát	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
46ef6bd0-e132-490d-8261-763260644448	2026-07-27 07:08:15.098009	2026-07-27 13:08:27.195418	\N	\N	AIR_CONDITIONER	\N	f	\N	Điều hòa mở thì lên nhưng mà không có hơi mát phà ra	2026-07-27 13:08:15.097635	f	t	0.00	\N	HIGH	\N	\N	OPEN	MNT-20260727-832	Điều hòa không mát	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
757ba10e-11c3-481b-a30b-1b826b7f8ff0	2026-07-27 07:08:15.430335	2026-07-27 13:08:27.195433	\N	\N	AIR_CONDITIONER	\N	f	\N	Điều hòa mở thì lên nhưng mà không có hơi mát phà ra	2026-07-27 13:08:15.429927	f	t	0.00	\N	HIGH	\N	\N	OPEN	MNT-20260727-833	Điều hòa không mát	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
2bee013f-38eb-4113-a2e0-a67a9385fe71	2026-07-27 07:10:19.20749	2026-07-27 13:38:27.427206	\N	\N	AIR_CONDITIONER	\N	f	\N	Điều hòa mở thì lên nhưng mà không có hơi mát phà ra	2026-07-27 13:10:19.20719	f	t	0.00	\N	HIGH	\N	\N	OPEN	MNT-20260727-837	Điều hòa không mát	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
dc04e66c-f7b1-4bf6-92b7-3128d587dc94	2026-07-27 09:27:38.236561	2026-07-27 15:38:29.110755	\N	\N	PLUMBING	\N	f	\N	hehe asdasdawdasd asf	2026-07-27 15:27:38.236285	f	t	0.00	\N	HIGH	\N	\N	OPEN	MNT-20260727-838	Bi cai loz gi a	\N	26962280-8932-4cc6-b92f-ac0b9a570cd0	a0000000-0000-0000-0000-000000000002	\N	\N
c6587d83-4725-4763-a7f1-fa8288d9b863	2026-07-27 09:27:40.815979	2026-07-27 15:38:29.110854	\N	\N	PLUMBING	\N	f	\N	hehe asdasdawdasd asf	2026-07-27 15:27:40.815658	f	t	0.00	\N	HIGH	\N	\N	OPEN	MNT-20260727-839	Bi cai loz gi a	\N	26962280-8932-4cc6-b92f-ac0b9a570cd0	a0000000-0000-0000-0000-000000000002	\N	\N
8ce7171e-c161-4408-a821-3b0aed85847c	2026-07-27 06:57:49.406494	2026-07-28 07:08:30.904394	\N	\N	AIR_CONDITIONER	\N	f	\N	bật máy lạnh điều hoà chảy nước ra từ máy lạnh thay vì chảy qua đường ống	2026-07-28 06:57:49.406042	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260727-815	điều hoà bị chảy nước	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
8f3a647b-4162-4c49-8567-d09c35e04ad2	2026-07-27 07:04:09.581522	2026-07-28 07:08:30.904488	\N	\N	AIR_CONDITIONER	\N	f	\N	Điều hòa mở thì lên nhưng mà không có hơi phà ra	2026-07-28 07:04:09.581064	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260727-820	Điều hòa không mát	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
f9e43efa-0144-4dbe-820c-59e4141ceeb8	2026-07-27 07:04:10.039331	2026-07-28 07:08:30.904582	\N	\N	AIR_CONDITIONER	\N	f	\N	Điều hòa mở thì lên nhưng mà không có hơi phà ra	2026-07-28 07:04:10.038933	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260727-821	Điều hòa không mát	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
6d2de875-2fdb-45e7-b621-17bd86226815	2026-07-27 07:04:20.601638	2026-07-28 07:08:30.904675	\N	\N	AIR_CONDITIONER	\N	f	\N	Điều hòa mở thì lên nhưng mà không có hơi phà ra	2026-07-28 07:04:20.601223	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260727-822	Điều hòa không mát	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
08ee7530-a733-485e-b1bd-579a997d77fc	2026-07-27 07:04:21.009731	2026-07-28 07:08:30.90477	\N	\N	AIR_CONDITIONER	\N	f	\N	Điều hòa mở thì lên nhưng mà không có hơi phà ra	2026-07-28 07:04:21.009118	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260727-823	Điều hòa không mát	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
e3cbf44f-70c1-4065-b448-bfe6fd3eb84b	2026-07-27 07:04:46.637689	2026-07-28 07:08:30.904862	\N	\N	AIR_CONDITIONER	\N	f	\N	Điều hòa mở thì lên nhưng mà không có hơi phà ra	2026-07-28 07:04:46.637264	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260727-824	Điều hòa không mát	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
b37d3442-70c1-44a7-8b0f-c16e3d2d05fd	2026-07-27 07:04:47.018792	2026-07-28 07:08:30.905124	\N	\N	AIR_CONDITIONER	\N	f	\N	Điều hòa mở thì lên nhưng mà không có hơi phà ra	2026-07-28 07:04:47.018499	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260727-825	Điều hòa không mát	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
a37395c2-abfd-4627-a2ed-a449d870d276	2026-07-27 07:04:53.583399	2026-07-28 07:08:30.905278	\N	\N	AIR_CONDITIONER	\N	f	\N	Điều hòa mở thì lên nhưng mà không có hơi phà ra	2026-07-28 07:04:53.583095	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260727-826	Điều hòa không mát	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
64f5b409-34d7-4499-9ad2-0fa043005180	2026-07-27 07:04:53.906926	2026-07-28 07:08:30.905378	\N	\N	AIR_CONDITIONER	\N	f	\N	Điều hòa mở thì lên nhưng mà không có hơi phà ra	2026-07-28 07:04:53.906553	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260727-827	Điều hòa không mát	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
2119d259-d667-4994-8cb4-2d4f7f483e5b	2026-07-27 07:05:00.837434	2026-07-28 07:08:30.905477	\N	\N	AIR_CONDITIONER	\N	f	\N	Điều hòa mở thì lên nhưng mà không có hơi phà ra	2026-07-28 07:05:00.837133	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260727-828	Điều hòa không mát	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
ad47bc66-00e6-465f-a441-04449b1d21ad	2026-07-27 07:05:01.607676	2026-07-28 07:08:30.905572	\N	\N	AIR_CONDITIONER	\N	f	\N	Điều hòa mở thì lên nhưng mà không có hơi phà ra	2026-07-28 07:05:01.607267	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260727-829	Điều hòa không mát	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
49fbc40e-667c-4252-9de8-57f155b09e78	2026-07-27 10:24:19.659513	2026-07-28 10:38:33.504338	\N	\N	AIR_CONDITIONER	\N	f	\N	điều mở lên mà không có hơi mát	2026-07-28 10:24:19.658984	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260727-840	điều hoà không mát	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
e5e71416-e20c-4297-bc9b-64733d07f45f	2026-07-27 10:24:20.697286	2026-07-28 10:38:33.504468	\N	\N	AIR_CONDITIONER	\N	f	\N	điều mở lên mà không có hơi mát	2026-07-28 10:24:20.696978	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260727-841	điều hoà không mát	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
a1dc49c3-f49f-4a54-a478-20c063c80cc6	2026-07-27 10:25:31.53572	2026-07-28 10:38:33.504542	\N	\N	AIR_CONDITIONER	\N	f	\N	điều mở lên mà không có hơi mát	2026-07-28 10:25:31.535372	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260727-842	điều hoà không mát	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
85ae8e7b-b3f2-4640-9ace-f8fa69761a9d	2026-07-27 10:25:34.728633	2026-07-28 10:38:33.504614	\N	\N	AIR_CONDITIONER	\N	f	\N	điều mở lên mà không có hơi mát	2026-07-28 10:25:34.72825	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260727-843	điều hoà không mát	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
6c0b25e4-a92e-40d9-8480-03e5efe58461	2026-07-29 01:34:43.408172	2026-07-30 02:04:40.3681	\N	\N	OTHER	\N	f	\N	aaaaaaaaaa	2026-07-30 01:34:43.407724	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260729-844	a	\N	26962280-8932-4cc6-b92f-ac0b9a570cd0	a0000000-0000-0000-0000-000000000002	\N	\N
7c657edc-5072-4c13-9e24-0dba94836489	2026-07-29 01:34:45.301081	2026-07-30 02:04:40.371669	\N	\N	OTHER	\N	f	\N	aaaaaaaaaa	2026-07-30 01:34:45.205827	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260729-845	a	\N	26962280-8932-4cc6-b92f-ac0b9a570cd0	a0000000-0000-0000-0000-000000000002	\N	\N
afab1b6d-6ae8-4337-84a6-982a90835589	2026-07-29 01:35:49.30518	2026-07-30 02:04:40.371795	\N	\N	OTHER	\N	f	\N	1233333331235	2026-07-30 01:35:49.304643	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260729-846	123	\N	26962280-8932-4cc6-b92f-ac0b9a570cd0	a0000000-0000-0000-0000-000000000002	\N	\N
b0544e1c-d3f6-4441-a690-c2c0bdd83920	2026-07-29 03:03:34.911032	2026-07-30 03:04:40.704206	\N	\N	OTHER	\N	f	\N	sfhdsfhdfsadfghnmhgfdsdfg21424512easdsfa	2026-07-30 03:03:34.910572	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260729-848	asfasf	\N	26962280-8932-4cc6-b92f-ac0b9a570cd0	a0000000-0000-0000-0000-000000000002	\N	\N
e1f8ef7c-720f-4d71-ab02-e761f4cd93d2	2026-07-29 03:03:35.807628	2026-07-30 03:04:40.70436	\N	\N	OTHER	\N	f	\N	sfhdsfhdfsadfghnmhgfdsdfg21424512easdsfa	2026-07-30 03:03:35.807228	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260729-849	asfasf	\N	26962280-8932-4cc6-b92f-ac0b9a570cd0	a0000000-0000-0000-0000-000000000002	\N	\N
ca7af936-6596-4ccf-ab2b-588a1ba131e7	2026-07-29 01:35:49.905092	2026-07-30 02:04:40.3719	\N	\N	OTHER	\N	f	\N	1233333331235	2026-07-30 01:35:49.904755	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260729-847	123	\N	26962280-8932-4cc6-b92f-ac0b9a570cd0	a0000000-0000-0000-0000-000000000002	\N	\N
28774408-c16e-471f-b982-1fe505f5856b	2026-07-30 11:11:27.866586	2026-07-31 11:17:23.199875	\N	\N	OTHER	\N	f	\N	Valid local maintenance probe description	2026-07-31 11:11:27.86539	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260730-832	QA serialization probe	\N	26962280-8932-4cc6-b92f-ac0b9a570cd0	a0000000-0000-0000-0000-000000000002	\N	\N
8342b2b1-d767-4869-acf7-97e27a5aa40f	2026-07-30 11:15:06.613474	2026-07-31 11:17:23.294087	\N	\N	OTHER	\N	f	\N	Valid local maintenance response verification	2026-07-31 11:15:06.611562	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260730-402	QA serialization green probe	\N	26962280-8932-4cc6-b92f-ac0b9a570cd0	a0000000-0000-0000-0000-000000000002	\N	\N
3e412a56-e4c8-45ef-bc2c-488e118c0651	2026-07-31 03:29:10.632375	2026-08-01 03:50:32.576586	\N	\N	OTHER	\N	f	\N	sdlgsndklgjdljsd;lgjs;ldjg;slkfgsdfg	2026-08-01 03:29:10.532504	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260731-937	disjglsdnglsdglsq	\N	26962280-8932-4cc6-b92f-ac0b9a570cd0	a0000000-0000-0000-0000-000000000002	\N	\N
791b3bc7-973e-4ce9-b0f8-2c2bed1383d5	2026-08-04 09:28:52.860387	2026-08-05 09:58:10.357393	\N	\N	FURNITURE	\N	f	\N	cửa bị kẹt cứng không mở được	2026-08-05 09:28:52.86001	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260804-061	cửa bị ket	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
cbf3facb-8486-47b7-b951-cea864340b19	2026-08-04 08:37:04.32285	2026-08-04 08:56:56.704512	\N	spam nhiều lần	OTHER	\N	f	\N	Cần thay GPU 5090	2026-08-04 12:37:04.322592	f	f	0.00	\N	URGENT	\N	\N	CANCELLED	MNT-20260804-113	Máy tính lỗi thời	\N	b5000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000003	\N	\N
de427a93-5a73-4187-b30c-6b18f1d8073e	2026-08-04 08:36:30.315068	2026-08-04 08:57:05.706932	\N	spam nhiều lần	OTHER	\N	f	\N	Cần thay GPU 5090	2026-08-04 12:36:30.314818	f	f	0.00	\N	URGENT	\N	\N	CANCELLED	MNT-20260804-112	Máy tính lỗi thời	\N	b5000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000003	\N	\N
9b31d59a-e23c-4ea5-9b4c-957406f94725	2026-08-04 08:36:11.41533	2026-08-04 08:57:12.506494	\N	spam nhiều lần	OTHER	\N	f	\N	Cần thay GPU 5090	2026-08-04 12:36:11.414594	f	f	0.00	\N	URGENT	\N	\N	CANCELLED	MNT-20260804-111	Máy tính lỗi thời	\N	b5000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000003	\N	\N
c2738e46-85d0-45f2-b0d6-ae16f04d1cad	2026-08-04 08:35:59.313991	2026-08-04 08:57:17.127767	\N	spam nhiều lần	OTHER	\N	f	\N	Cần thay GPU 5090	2026-08-04 12:35:59.313623	f	f	0.00	\N	URGENT	\N	\N	CANCELLED	MNT-20260804-110	Máy tính lỗi thời	\N	b5000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000003	\N	\N
c5615cfe-4f1a-4a3f-86b1-3727c9a02d68	2026-08-05 04:04:22.233518	2026-08-06 04:28:24.115149	\N	\N	AIR_CONDITIONER	\N	t	Sáng Thứ Năm (06/08) (8:00 - 11:30)	điều hòa mở khoong mát	2026-08-06 04:04:22.233171	f	t	200000.00	\N	NORMAL	\N	2026-08-05 04:06:46.237918	IN_PROGRESS	MNT-20260805-413	Điều hòa không mát	a0000000-0000-0000-0000-000000000003	b5000000-0000-0000-0000-000000000005	b1000000-0000-0000-0000-000000000005	f	\N
e3a2fec5-a9ad-409f-944d-ef61236f54cc	2026-08-02 07:21:50.278117	2026-08-04 07:23:10.904762	\N	\N	PLUMBING	\N	t	Chiều mai (13:30 - 17:00)	Bị chảy nước	2026-08-04 07:23:00	f	t	0.00	\N	HIGH	\N	2026-08-02 07:26:11.592091	IN_PROGRESS	MNT-20260802-176	Vòi nước hỏng	7b70cfa6-d414-4165-b17c-dde2c4aea3ba	26962280-8932-4cc6-b92f-ac0b9a570cd0	a0000000-0000-0000-0000-000000000002	\N	\N
5bd48f3a-3600-45a2-a302-3698710235a2	2026-08-04 08:35:51.210879	2026-08-04 12:43:17.972893	\N	\N	OTHER	\N	f	\N	Cần thay GPU 5090	2026-08-04 12:35:51.210573	f	t	0.00	\N	URGENT	\N	\N	OPEN	MNT-20260804-109	Máy tính lỗi thời	\N	b5000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000003	\N	\N
de307c0f-3c70-4767-9a77-6adb46585bb4	2026-07-31 04:56:22.035314	2026-08-04 07:31:20.109795	\N	\N	OTHER	\N	f	\N	test with image	2026-08-01 04:56:22.034828	f	t	0.00	\N	NORMAL	\N	\N	ASSIGNED	MNT-20260731-938	test with image	7b70cfa6-d414-4165-b17c-dde2c4aea3ba	26962280-8932-4cc6-b92f-ac0b9a570cd0	a0000000-0000-0000-0000-000000000002	\N	\N
2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9	2026-07-31 04:56:27.148002	2026-08-04 07:32:36.503845	\N	\N	OTHER	\N	f	\N	test with image	2026-08-01 04:56:27.147594	f	t	0.00	\N	NORMAL	\N	2026-08-04 07:32:36.423108	IN_PROGRESS	MNT-20260731-939	test with image	774a2c9e-8929-4d7c-80ca-14f62b9d9d56	26962280-8932-4cc6-b92f-ac0b9a570cd0	a0000000-0000-0000-0000-000000000002	\N	\N
8721cde2-53f1-478e-842d-63cef0d8e17a	2026-07-31 04:56:34.936284	2026-08-04 08:06:36.673418	\N	\N	OTHER	\N	t	Sáng mai (8:00 - 11:30)	test with image	2026-08-01 04:56:34.935956	f	t	675000.00	\N	NORMAL	\N	2026-07-31 07:09:09.673689	IN_PROGRESS	MNT-20260731-940	test with image	774a2c9e-8929-4d7c-80ca-14f62b9d9d56	26962280-8932-4cc6-b92f-ac0b9a570cd0	a0000000-0000-0000-0000-000000000002	\N	\N
797fc693-e426-43c8-be82-06e318cd6b46	2026-08-04 08:35:46.206681	2026-08-04 12:43:17.973067	\N	\N	OTHER	\N	f	\N	Cần thay GPU 5090	2026-08-04 12:35:46.20628	f	t	0.00	\N	URGENT	\N	\N	OPEN	MNT-20260804-108	Máy tính lỗi thời	\N	b5000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000003	\N	\N
919b3461-8baf-4669-b0fc-e66c998d0c38	2026-08-04 08:35:40.107484	2026-08-04 12:43:17.973138	\N	\N	OTHER	\N	f	\N	Cần thay GPU 5090	2026-08-04 12:35:40.106894	f	t	0.00	\N	URGENT	\N	\N	OPEN	MNT-20260804-107	Máy tính lỗi thời	\N	b5000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000003	\N	\N
babc7312-1c6f-4670-8297-351d392a1996	2026-08-04 09:23:08.663598	2026-08-05 09:28:09.92869	\N	\N	FURNITURE	\N	t	Chiều mai (13:30 - 17:00)	cửa bị kẹt cứng không mở được	2026-08-05 09:23:08.663177	f	t	70000.00	\N	NORMAL	\N	2026-08-04 09:32:03.722259	IN_PROGRESS	MNT-20260804-060	cửa bị ket	774a2c9e-8929-4d7c-80ca-14f62b9d9d56	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
92b4e6ca-0abe-429e-8385-18666f89cd13	2026-08-04 08:50:57.11872	2026-08-04 15:13:18.213464	\N	\N	PLUMBING	\N	t	Sáng mai (8:00 - 11:30)	Bị nhỏ giọt	2026-08-04 14:50:57.118421	f	t	5000.00	\N	HIGH	\N	2026-08-04 08:59:12.887348	IN_PROGRESS	MNT-20260804-115	Vòi nước bị hỏng	7b70cfa6-d414-4165-b17c-dde2c4aea3ba	b5000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000003	\N	\N
a4af8910-9741-45c9-81c7-a5fc5c5b6407	2026-08-05 03:27:49.061302	2026-08-06 03:28:18.41769	\N	\N	AIR_CONDITIONER	\N	f	\N	máy lạnh rò gỉ nước	2026-08-06 03:27:49.060782	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260805-062	Máy lạnh chảy nước	\N	b5000000-0000-0000-0000-000000000005	b1000000-0000-0000-0000-000000000005	f	\N
fa3f4f63-780d-420b-b0a4-a0e2742133dc	2026-08-05 04:21:34.111437	2026-08-06 04:28:24.115368	\N	\N	FURNITURE	\N	f	\N	Của tủ bị kêu khi mở ra	2026-08-06 04:21:34.111135	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260805-415	Tủ bị hỏng	\N	b5000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000003	f	\N
a2ff625f-70a4-461f-9b5d-9557291b7925	2026-08-05 04:21:26.41598	2026-08-06 04:28:24.115432	\N	\N	FURNITURE	\N	f	\N	Của tủ bị kêu khi mở ra	2026-08-06 04:21:26.415556	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260805-414	Tủ bị hỏng	\N	b5000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000003	f	\N
db9a9713-3331-441f-84c5-ea3e5abb1197	2026-08-05 03:28:16.706553	2026-08-22 13:46:25.711479	\N	\N	AIR_CONDITIONER	\N	t	Chiều Thứ Năm (06/08) (13:30 - 17:00)	máy lạnh rò gỉ nước	2026-08-06 03:28:16.212575	f	t	240000.00	\N	NORMAL	\N	2026-08-05 03:30:00.44665	PENDING_PAYMENT	MNT-20260805-410	Máy lạnh chảy nước	774a2c9e-8929-4d7c-80ca-14f62b9d9d56	b5000000-0000-0000-0000-000000000005	b1000000-0000-0000-0000-000000000005	f	\N
05c52caf-2ab3-4473-8fcd-170dc1849e0c	2026-08-05 04:22:10.283381	2026-08-05 04:24:12.7423	\N	đã được xủ lý	FURNITURE	\N	f	\N	Của tủ bị kêu khi mở ra	2026-08-05 04:23:00	f	f	0.00	\N	NORMAL	\N	\N	CANCELLED	MNT-20260805-417	Tủ bị hỏng	7b70cfa6-d414-4165-b17c-dde2c4aea3ba	b5000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000003	f	\N
c5e0255e-0794-408f-9677-5db981f2d32f	2026-08-04 08:50:24.602738	2026-08-05 07:25:27.271867	\N	\N	OTHER	\N	f	Sáng mai (8:00 - 11:30)	Cần thay GPU 5090	2026-08-04 12:50:24.515078	f	t	0.00	\N	URGENT	\N	2026-08-05 07:25:27.245657	IN_PROGRESS	MNT-20260804-114	Máy tính lỗi thời	7b70cfa6-d414-4165-b17c-dde2c4aea3ba	b5000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000003	\N	\N
ee2e951d-6752-4790-8805-0a21dc2bf15a	2026-08-04 09:29:09.765337	2026-08-05 09:58:10.357549	\N	\N	OTHER	\N	f	\N	\N	2026-08-05 09:29:09.765027	f	t	0.00	\N	NORMAL	\N	\N	ASSIGNED	MNT-20260804-062		b1000000-0000-0000-0000-000000000009	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
94595db1-e24a-4a26-a28e-4a1e73bb8814	2026-08-05 03:27:57.06814	2026-08-06 03:28:18.417943	\N	\N	AIR_CONDITIONER	\N	f	\N	máy lạnh rò gỉ nước	2026-08-06 03:27:57.067795	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260805-063	Máy lạnh chảy nước	\N	b5000000-0000-0000-0000-000000000005	b1000000-0000-0000-0000-000000000005	f	\N
0f0f870b-8625-4306-84b4-61e3c78ae7e2	2026-08-05 03:54:09.579092	2026-08-22 13:46:45.513891	\N	\N	ELECTRIC	\N	t	Tối nay (18:00 - 20:30)	Đèn nhà vệ sinh mở không lên	2026-08-06 03:54:09.578814	f	t	20000.00	\N	NORMAL	\N	2026-08-05 03:55:22.848283	PENDING_PAYMENT	MNT-20260805-411	Đèn nhà vệ sinh không lên	774a2c9e-8929-4d7c-80ca-14f62b9d9d56	b5000000-0000-0000-0000-000000000005	b1000000-0000-0000-0000-000000000005	f	\N
b7b0c13c-2dbe-4d08-b81c-032624bfe278	2026-08-05 03:57:59.725015	2026-08-06 03:58:22.612117	\N	\N	PLUMBING	\N	t	Sáng Thứ Năm (06/08) (8:00 - 11:30)	ống thoát nước bị nghẽn không thoát nước	2026-08-06 03:57:59.724699	f	t	80000.00	\N	NORMAL	\N	2026-08-05 04:00:33.363878	IN_PROGRESS	MNT-20260805-412	Nước bị nghẽn	a0000000-0000-0000-0000-000000000003	b5000000-0000-0000-0000-000000000005	b1000000-0000-0000-0000-000000000005	f	\N
6d80b26f-78f4-4e44-bed9-599026e0004c	2026-08-05 04:21:47.706671	2026-08-06 04:28:24.115485	\N	\N	FURNITURE	\N	f	\N	Của tủ bị kêu khi mở ra	2026-08-06 04:21:47.706162	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260805-416	Tủ bị hỏng	\N	b5000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000003	f	\N
7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185	2026-08-19 07:06:12.861515	2026-08-22 13:41:24.437655	\N	\N	ELECTRIC	\N	t	Chiều Thứ Năm (20/08) (13:30 - 17:00)	Cp bị chập điện nổ	2026-08-19 13:06:12.860776	f	t	50000.00	2026-08-22 13:41:15.562725	HIGH	2026-08-22 13:41:24.41774	2026-08-19 07:07:09.550449	DONE	MNT-20260819-063	CP bị nổ	936bdf00-c9f0-4889-80fc-86f3a59d051e	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	f	\N
849c05ad-e3b6-4c8b-9f10-3db67d42a9e6	2026-08-09 16:01:33.184956	2026-08-09 22:22:14.778567	\N	\N	ELECTRIC	\N	t	Sáng Thứ Hai (10/08) (8:00 - 11:30)	Điều hoà bị chập mạnh điện bị hư	2026-08-09 22:01:33.184067	f	t	50000.00	\N	HIGH	\N	2026-08-09 16:04:56.867985	IN_PROGRESS	MNT-20260809-282	Điều hoà bị hư	a0000000-0000-0000-0000-000000000003	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	f	\N
10ce7228-811a-4908-a24a-6061f278cc7b	2026-08-05 06:03:17.019836	2026-08-05 06:22:45.911505	\N	Báo cáo bảo trì bị trùng lập	FURNITURE	\N	f	\N	Bản lề cửa nhà vệ sinh có hiện tượng bị nức	2026-08-05 14:03:17.019445	f	f	0.00	\N	HIGH	\N	\N	CANCELLED	MNT-20260805-419	Bản lề cửa bị hỏng	\N	b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6	74ccd53e-4998-49a3-97e3-b918b60f4080	f	\N
e56e460b-511b-48af-b2ac-3d8e93a464cc	2026-08-04 09:22:52.374336	2026-08-05 09:28:09.928802	\N	\N	FURNITURE	\N	f	\N	cửa bị kẹt cứng không mở được	2026-08-05 09:22:52.373173	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260804-057	cửa bị ket	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
3ea22299-cbb4-4730-9ae1-aac56cf897b0	2026-08-04 09:22:57.102612	2026-08-05 09:28:09.928839	\N	\N	FURNITURE	\N	f	\N	cửa bị kẹt cứng không mở được	2026-08-05 09:22:57.102237	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260804-058	cửa bị ket	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
10929fc8-6e84-4107-af9f-50d2aa7fc9c5	2026-08-04 09:23:01.867008	2026-08-05 09:28:09.928868	\N	\N	FURNITURE	\N	f	\N	cửa bị kẹt cứng không mở được	2026-08-05 09:23:01.866682	f	t	0.00	\N	NORMAL	\N	\N	OPEN	MNT-20260804-059	cửa bị ket	\N	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	\N	\N
483e9cdc-246b-48a5-9a8f-2327910f2b03	2026-08-05 06:03:31.306705	2026-08-05 14:28:13.118921	\N	\N	FURNITURE	\N	f	\N	Bản lề cửa nhà vệ sinh có hiện tượng bị nức	2026-08-05 14:03:31.306291	f	t	0.00	\N	HIGH	\N	2026-08-05 06:26:30.07581	IN_PROGRESS	MNT-20260805-420	Bản lề cửa bị hỏng	b1000000-0000-0000-0000-000000000008	b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6	74ccd53e-4998-49a3-97e3-b918b60f4080	f	\N
60dab198-f686-47d1-9656-6b7314fbeae3	2026-08-05 04:25:33.106569	2026-08-06 04:28:24.115533	\N	\N	AIR_CONDITIONER	\N	f	\N	máy lạnh bị ồn	2026-08-06 04:25:33.106151	f	t	150000.00	\N	NORMAL	\N	2026-08-05 04:30:47.341325	IN_PROGRESS	MNT-20260805-418	Máy lạnh có vấn đề	7b70cfa6-d414-4165-b17c-dde2c4aea3ba	b5000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000003	f	\N
2f6bcc81-68a7-46e1-b7b8-f98bf267fe53	2026-08-05 06:30:07.066427	2026-08-06 15:07:10.567907	\N	\N	AIR_CONDITIONER	\N	f	Sáng Thứ Sáu (07/08) (8:00 - 11:30)	Điều hòa khi sử dụng bị chảy nước nhỏ giọt	2026-08-05 18:30:07.066047	f	t	0.00	\N	HIGH	\N	\N	ASSIGNED	MNT-20260805-421	Điều hòa bị chảy nước	b1000000-0000-0000-0000-000000000008	b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6	74ccd53e-4998-49a3-97e3-b918b60f4080	f	\N
c05e9333-2746-4b7f-9a01-8182f91ffa93	2026-08-14 04:28:39.862279	2026-08-19 07:06:40.060944	\N	Bắt buộc huỷ	OTHER	\N	f	Sáng Thứ Bảy (15/08) (8:00 - 11:30)	Nổ Cpkạdhakjsdhakjdhs	2026-08-14 16:28:39.767331	f	t	0.00	\N	HIGH	\N	\N	CANCELLED	MNT-20260814-568	Cp bị nổ	a0000000-0000-0000-0000-000000000003	b5000000-0000-0000-0000-000000000005	b1000000-0000-0000-0000-000000000005	f	\N
229d8e58-ffbe-44d4-8909-3e92985cfe8c	2026-08-06 15:22:10.514258	2026-08-06 21:30:43.894139	\N	\N	PLUMBING	\N	t	Tối nay (18:00 - 20:30)	Khóa van nhưng nước vẫn bị rò rỉ nước	2026-08-06 21:22:10.513911	f	t	0.00	\N	HIGH	\N	2026-08-06 16:42:55.141368	IN_PROGRESS	MNT-20260806-491	Vòi nước bị rò rỉ	b1000000-0000-0000-0000-000000000008	ce27f631-b495-48aa-9fc5-c60ec18a95eb	33712636-202b-4ff3-8011-2da710d65035	f	\N
b7a2d2ad-c428-4c0d-8802-256afd8979d4	2026-08-22 14:47:23.320427	2026-08-22 14:48:29.427037	https://pub-1415da6044694261bf385af30f6ca53a.r2.dev/maintenance/pending-3fd6cfbb-67a7-4937-b113-7c9f15c1ae2c/video/59e3585c-35cf-457a-a5f1-c10a684c9399.mp4	\N	ELECTRIC	\N	t	Sáng Chủ Nhật (23/08) (8:00 - 11:30)	Cp bị nổ rồi cháy	2026-08-22 20:47:23.246063	f	f	0.00	\N	HIGH	2026-08-22 14:48:29.319028	2026-08-22 14:48:04.532164	DONE	MNT-20260822-124	Hư Cp	936bdf00-c9f0-4889-80fc-86f3a59d051e	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	f	\N
69839fb2-7b7c-41fe-9a50-431b132a54ce	2026-08-22 13:42:19.117228	2026-08-22 13:43:42.115375	https://pub-1415da6044694261bf385af30f6ca53a.r2.dev/maintenance/pending-03134da6-90b2-4faa-a87c-ac9734045826/video/d84817b6-fdce-4fe8-8673-32326d80b5d4.mp4	\N	AIR_CONDITIONER	\N	t	Chiều Chủ Nhật (23/08) (13:30 - 17:00)	Điều hoà bị rò rỉ điện và nước	2026-08-23 01:42:19.11663	f	f	0.00	\N	HIGH	2026-08-22 13:43:42.098784	2026-08-22 13:42:58.656458	DONE	MNT-20260822-012	Điều hoà chảy nước	936bdf00-c9f0-4889-80fc-86f3a59d051e	b5000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	f	\N
ea9d94f1-b8ff-45da-9312-91c673eaa885	2026-08-21 01:52:12.167368	2026-08-22 13:17:36.00069	\N	nahhhhhhhhh	ELECTRIC	\N	f	\N	Không có điện	2026-08-22 01:52:12.167097	f	t	0.00	\N	NORMAL	\N	\N	CANCELLED	MNT-20260821-064	Cúp điện	b1000000-0000-0000-0000-000000000009	3697261c-44e6-4b47-9b9d-25277cc8da51	3589890e-f56b-4dbc-84fc-12e319e1d750	f	\N
\.


--
-- Data for Name: maintenance_reviews; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.maintenance_reviews (id, created_at, updated_at, comment, rating_stars, request_id, technician_id, tenant_id) FROM stdin;
a9de68a4-0cdc-4311-a6c3-53eb72e57afa	2026-08-22 13:44:05.020197	2026-08-22 13:44:05.020197		5	69839fb2-7b7c-41fe-9a50-431b132a54ce	936bdf00-c9f0-4889-80fc-86f3a59d051e	b1000000-0000-0000-0000-000000000002
\.


--
-- Data for Name: meter_readings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.meter_readings (id, elec_new, elec_old, reading_month, recorded_at, source, water_new, water_old, recorded_by, room_id) FROM stdin;
17a52bc9-aa9b-4593-976e-5d871150f038	1	1	2026-08-01	2026-08-06 15:11:00.573786	MANUAL	1	1	c5d65edf-fb24-4f93-b966-362f36e78370	3697261c-44e6-4b47-9b9d-25277cc8da51
c91d265c-de92-4ae0-9806-44be842030d7	200	0	2026-07-01	2026-07-27 08:14:34.021627	MANUAL	100	0	a0000000-0000-0000-0000-000000000001	26962280-8932-4cc6-b92f-ac0b9a570cd0
3c5e2653-d5f6-4557-b335-b3e8e63e3c88	321	123	2026-08-01	2026-08-06 12:49:23.833372	MANUAL	321	123	a0000000-0000-0000-0000-000000000001	b5000000-0000-0000-0000-000000000012
da5bbcd0-51dd-4817-ba66-71cde4770cd3	500	0	2026-08-01	2026-08-05 04:10:43.21125	MANUAL	500	0	a0000000-0000-0000-0000-000000000001	95192562-e587-4da2-bac0-46d29aa261e9
82ff7d71-9a43-447c-82ba-58f4c49e578a	321	123	2026-08-01	2026-08-06 12:49:44.463721	MANUAL	321	123	a0000000-0000-0000-0000-000000000001	b5000000-0000-0000-0000-000000000003
1a7765f9-95d5-4973-bdf8-d5d53410192c	321	123	2026-08-01	2026-08-06 12:49:56.096552	MANUAL	312	123	a0000000-0000-0000-0000-000000000001	b5000000-0000-0000-0000-000000000021
b02b0ac8-35b5-4017-9f15-fc1f51104cf6	321	123	2026-08-01	2026-08-02 07:40:25.472961	MANUAL	321	123	a0000000-0000-0000-0000-000000000001	b5000000-0000-0000-0000-000000000017
0205a68e-125a-4635-b197-8fd75e44b262	321	123	2026-08-01	2026-08-05 07:48:26.712297	MANUAL	321	123	a0000000-0000-0000-0000-000000000001	b5000000-0000-0000-0000-000000000010
3417e726-145f-469d-8cc8-7bfc6a269a45	124	123	2026-08-01	2026-08-06 15:16:54.694229	MANUAL	124	123	a0000000-0000-0000-0000-000000000001	ce27f631-b495-48aa-9fc5-c60ec18a95eb
e0a91d0e-1003-4095-9999-e5d13163f075	124	123	2026-08-01	2026-08-05 05:46:12.294683	MANUAL	124	123	a0000000-0000-0000-0000-000000000001	e3d6477b-41ee-4b21-af42-6a9f042e6d08
f95baaa9-6167-4084-9dd1-d8b37666a082	124	123	2026-08-01	2026-08-06 15:53:03.449374	MANUAL	124	123	a0000000-0000-0000-0000-000000000001	fcf45ae0-98ba-4018-8181-1a9dbab9a472
a44d6e43-af96-4ab7-a0b2-149f23670493	321	123	2026-08-01	2026-08-06 12:51:02.453132	MANUAL	321	123	a0000000-0000-0000-0000-000000000001	b5000000-0000-0000-0000-000000000025
da781ef1-1881-4b63-8d82-028b15c32e1b	321	123	2026-08-01	2026-08-06 12:51:13.71581	MANUAL	321	123	a0000000-0000-0000-0000-000000000001	b5000000-0000-0000-0000-000000000013
d3fcd99c-5dcb-48c5-be33-33e015eacab4	321	123	2026-08-01	2026-08-06 12:51:26.96716	MANUAL	321	123	a0000000-0000-0000-0000-000000000001	b5000000-0000-0000-0000-000000000018
7e9be3ee-fffd-49b5-b84a-a6a83e5d0edb	321	123	2026-08-01	2026-08-05 07:47:46.044631	MANUAL	321	123	a0000000-0000-0000-0000-000000000001	b5000000-0000-0000-0000-000000000024
2cf28fb7-9b5f-46a3-bf4f-3f36e9628b04	321	123	2026-08-01	2026-08-06 12:51:53.930182	MANUAL	321	123	a0000000-0000-0000-0000-000000000001	b5000000-0000-0000-0000-000000000016
1df62e88-7683-4f95-ad4b-b2b4e383b57a	321	123	2026-08-01	2026-08-06 12:52:06.794405	MANUAL	321	123	a0000000-0000-0000-0000-000000000001	b5000000-0000-0000-0000-000000000014
69df9958-a89d-4ad6-9a1d-23bd25b706c2	321	123	2026-08-01	2026-08-05 07:48:59.086476	MANUAL	321	123	a0000000-0000-0000-0000-000000000001	b5000000-0000-0000-0000-000000000022
916add7f-b859-449e-a295-081e2e9672d7	312	123	2026-08-01	2026-08-06 12:52:34.062222	MANUAL	321	123	a0000000-0000-0000-0000-000000000001	b5000000-0000-0000-0000-000000000002
457026c7-82ea-48fc-9605-07c689aa0683	50000	40000	2026-07-01	2026-07-26 14:01:01.881325	MANUAL	400	200	ca179c8b-b6e8-4dee-860f-796c1f933814	b5000000-0000-0000-0000-000000000001
5993af76-3e9e-448a-b32a-d2d2da93676c	50002	50001	2026-09-01	2026-08-19 06:57:21.575931	MANUAL	402	401	a0000000-0000-0000-0000-000000000001	b5000000-0000-0000-0000-000000000001
5a874b26-a2a8-484d-a515-3676c3e4c895	50002	50000	2026-08-01	2026-08-01 13:05:53.276481	MANUAL	401	400	f74117ad-4070-4b4a-ae8f-33ef8b763bd8	b5000000-0000-0000-0000-000000000001
455779d5-6a3c-4aa6-9626-3f7576c1502f	322	123	2026-08-01	2026-08-04 07:24:51.808974	MANUAL	321	123	a0000000-0000-0000-0000-000000000001	b5000000-0000-0000-0000-000000000004
6e7c30b9-412e-4770-a37e-74af5c500901	321	123	2026-08-01	2026-08-04 07:25:25.530139	MANUAL	321	123	a0000000-0000-0000-0000-000000000001	b5000000-0000-0000-0000-000000000007
e58ca958-7713-4142-83f5-34d9aaabf1e3	321	123	2026-08-01	2026-08-04 07:26:32.212359	MANUAL	312	123	a0000000-0000-0000-0000-000000000001	b5000000-0000-0000-0000-000000000009
f14766b5-2a19-4a8c-8dc2-acb92ca3a79c	321	123	2026-08-01	2026-08-04 07:26:57.135004	MANUAL	321	123	a0000000-0000-0000-0000-000000000001	b5000000-0000-0000-0000-000000000005
5d6b824e-1b1c-46d4-99a6-f1d57be37eef	321	123	2026-08-01	2026-08-05 06:01:35.188099	MANUAL	321	123	a0000000-0000-0000-0000-000000000001	b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6
70d24aa5-b65b-49cb-a41b-f9bfac37e99a	222	200	2026-08-01	2026-08-02 07:41:16.519627	MANUAL	111	100	a0000000-0000-0000-0000-000000000001	26962280-8932-4cc6-b92f-ac0b9a570cd0
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.notifications (id, body, created_at, is_read, ref_id, title, type, user_id) FROM stdin;
228c42b1-3953-4732-bdc5-e3edb48c0822	điều hoà bị chảy nước - NORMAL	2026-07-27 06:53:31.705322	f	2e661bb3-5cf3-462f-9cde-510a75a5d1a3	New Maintenance Request MNT-20260727-808	MAINTENANCE	b1000000-0000-0000-0000-000000000001
4762b5d5-321c-4a67-943c-9b29f6c19ece	điều hoà bị chảy nước - NORMAL	2026-07-27 06:53:33.210352	f	300cfc87-df62-4a88-9887-9034ad1266d5	New Maintenance Request MNT-20260727-809	MAINTENANCE	b1000000-0000-0000-0000-000000000001
0cc18843-8cba-4f2e-983d-b0676b5b0838	điều hoà bị chảy nước - NORMAL	2026-07-27 06:53:39.60672	f	04a53e7e-15a4-4a9d-afed-567596ae20c6	New Maintenance Request MNT-20260727-810	MAINTENANCE	b1000000-0000-0000-0000-000000000001
5a212957-e470-403f-98ec-bdc9499ce442	điều hoà bị chảy nước - NORMAL	2026-07-27 06:53:40.185305	f	aa5bed2d-405c-4a8b-8ce3-bb9bfef19dfb	New Maintenance Request MNT-20260727-811	MAINTENANCE	b1000000-0000-0000-0000-000000000001
978854aa-be54-4a60-b8a7-9d7b2de3fd93	điều hoà bị chảy nước - NORMAL	2026-07-27 06:53:59.008259	f	f9c6f0d8-16f0-483f-b043-d2e389493f60	New Maintenance Request MNT-20260727-812	MAINTENANCE	b1000000-0000-0000-0000-000000000001
21b82209-f9a4-4c7c-a198-34f1ecfa6fce	điều hoà bị chảy nước - NORMAL	2026-07-27 06:53:59.509388	f	ed7264e5-49b9-43c1-9d82-2f63c8019d6e	New Maintenance Request MNT-20260727-813	MAINTENANCE	b1000000-0000-0000-0000-000000000001
b0696d6a-616a-4ef9-8c25-57af17bc94a1	điều hoà bị chảy nước - NORMAL	2026-07-27 06:57:48.953111	f	caf31977-a7ff-49eb-8166-c8e852487a09	New Maintenance Request MNT-20260727-814	MAINTENANCE	b1000000-0000-0000-0000-000000000001
f92e289c-f5a7-4608-8675-1c59d2fdea9d	điều hoà bị chảy nước - NORMAL	2026-07-27 06:57:49.408511	f	8ce7171e-c161-4408-a821-3b0aed85847c	New Maintenance Request MNT-20260727-815	MAINTENANCE	b1000000-0000-0000-0000-000000000001
9a854c32-b4c4-46f5-83cc-638de789e5ed	Invoice for 2026-07 is ready	2026-07-26 16:12:04.507568	t	9f0fb102-65c1-4983-a6c4-792ad48b4571	New Invoice	INVOICE	b1000000-0000-0000-0000-000000000002
15a926ab-d58a-4761-9cf1-e743adefb56b	điều hoà không hoạt động - HIGH	2026-07-27 06:58:57.90937	f	536a593e-7fa7-4273-bcbd-bb776de0254e	New Maintenance Request MNT-20260727-816	MAINTENANCE	b1000000-0000-0000-0000-000000000001
878cb543-b868-4799-954e-7d45740e459b	điều hoà không hoạt động - HIGH	2026-07-27 06:58:58.501252	f	dd480a87-1683-40f9-9839-48a4770ebebb	New Maintenance Request MNT-20260727-817	MAINTENANCE	b1000000-0000-0000-0000-000000000001
a70b7ba0-d9a3-486f-8ad0-12b3affe0ba2	điều hoà không hoạt động - HIGH	2026-07-27 06:59:03.005933	f	84941eb2-0626-4f31-a574-745466e0a083	New Maintenance Request MNT-20260727-818	MAINTENANCE	b1000000-0000-0000-0000-000000000001
94afa0f4-5608-46c1-ad22-24ad758feed1	điều hoà không hoạt động - HIGH	2026-07-27 06:59:03.458511	f	a3ed57fb-af95-4f3d-9b8d-c8b24b7a4f3c	New Maintenance Request MNT-20260727-819	MAINTENANCE	b1000000-0000-0000-0000-000000000001
fad5dd4e-539d-4d54-a9e3-504d12870b33	Điều hòa không mát - NORMAL	2026-07-27 07:04:09.601669	f	8f3a647b-4162-4c49-8567-d09c35e04ad2	New Maintenance Request MNT-20260727-820	MAINTENANCE	b1000000-0000-0000-0000-000000000001
3084d299-b8cc-4f51-8adb-57d4ab74e538	Điều hòa không mát - NORMAL	2026-07-27 07:04:10.040072	f	f9e43efa-0144-4dbe-820c-59e4141ceeb8	New Maintenance Request MNT-20260727-821	MAINTENANCE	b1000000-0000-0000-0000-000000000001
5ddbc2aa-bceb-4223-8185-f45835ecf183	Điều hòa không mát - NORMAL	2026-07-27 07:04:20.602636	f	6d2de875-2fdb-45e7-b621-17bd86226815	New Maintenance Request MNT-20260727-822	MAINTENANCE	b1000000-0000-0000-0000-000000000001
0ecf97f0-7bb9-450b-9e95-68fec0cc5a95	Điều hòa không mát - NORMAL	2026-07-27 07:04:21.010443	f	08ee7530-a733-485e-b1bd-579a997d77fc	New Maintenance Request MNT-20260727-823	MAINTENANCE	b1000000-0000-0000-0000-000000000001
b5188b0b-715e-4c04-bc16-cef3990a3d1e	Điều hòa không mát - NORMAL	2026-07-27 07:04:46.639044	f	e3cbf44f-70c1-4065-b448-bfe6fd3eb84b	New Maintenance Request MNT-20260727-824	MAINTENANCE	b1000000-0000-0000-0000-000000000001
4e624184-a1b5-4b88-b466-1ce27a47eb12	Điều hòa không mát - NORMAL	2026-07-27 07:04:47.019469	f	b37d3442-70c1-44a7-8b0f-c16e3d2d05fd	New Maintenance Request MNT-20260727-825	MAINTENANCE	b1000000-0000-0000-0000-000000000001
5dac5dd7-d4ed-4344-904f-048aae047148	Điều hòa không mát - NORMAL	2026-07-27 07:04:53.584038	f	a37395c2-abfd-4627-a2ed-a449d870d276	New Maintenance Request MNT-20260727-826	MAINTENANCE	b1000000-0000-0000-0000-000000000001
29644025-0847-4818-921d-70421227bf62	Điều hòa không mát - NORMAL	2026-07-27 07:04:53.907664	f	64f5b409-34d7-4499-9ad2-0fa043005180	New Maintenance Request MNT-20260727-827	MAINTENANCE	b1000000-0000-0000-0000-000000000001
e51312d2-bb0b-4808-9624-e3d7cb3f3200	Điều hòa không mát - NORMAL	2026-07-27 07:05:00.901115	f	2119d259-d667-4994-8cb4-2d4f7f483e5b	New Maintenance Request MNT-20260727-828	MAINTENANCE	b1000000-0000-0000-0000-000000000001
c566e185-b799-4f50-b43a-1dd8ebe2bcf7	Điều hòa không mát - NORMAL	2026-07-27 07:05:01.608703	f	ad47bc66-00e6-465f-a441-04449b1d21ad	New Maintenance Request MNT-20260727-829	MAINTENANCE	b1000000-0000-0000-0000-000000000001
39970a7f-edf3-4cf6-8d54-f9e65502c49e	Điều hòa không mát - HIGH	2026-07-27 07:07:52.429822	f	438c33ae-4853-4877-b39c-e7f07ae3e9b4	New Maintenance Request MNT-20260727-830	MAINTENANCE	b1000000-0000-0000-0000-000000000001
315c5327-8553-4b07-8f62-c096d0aa50d2	Điều hòa không mát - HIGH	2026-07-27 07:07:52.977855	f	cbf3b404-01fb-4818-bba9-f0887479ac1d	New Maintenance Request MNT-20260727-831	MAINTENANCE	b1000000-0000-0000-0000-000000000001
ea79022a-eebe-4e92-999d-9b9df2169582	Điều hòa không mát - HIGH	2026-07-27 07:08:15.098949	f	46ef6bd0-e132-490d-8261-763260644448	New Maintenance Request MNT-20260727-832	MAINTENANCE	b1000000-0000-0000-0000-000000000001
880a591e-87d2-4161-9602-cd60e68fcf3e	Điều hòa không mát - HIGH	2026-07-27 07:08:15.431165	f	757ba10e-11c3-481b-a30b-1b826b7f8ff0	New Maintenance Request MNT-20260727-833	MAINTENANCE	b1000000-0000-0000-0000-000000000001
3b9d8818-4ebe-4b97-8fbe-66111c4ede24	Điều hòa không mát - HIGH	2026-07-27 07:08:58.513485	f	86d24202-5c2b-480f-beb2-0915096f911e	New Maintenance Request MNT-20260727-834	MAINTENANCE	b1000000-0000-0000-0000-000000000001
83c156df-3a00-42c2-bd73-28e16c0d60b0	Điều hòa không mát - HIGH	2026-07-27 07:08:58.850302	f	e0dd70bc-3417-4d3e-aa7c-b7710a2308da	New Maintenance Request MNT-20260727-835	MAINTENANCE	b1000000-0000-0000-0000-000000000001
5647f220-7f34-4651-967c-195f336db407	Điều hòa không mát - HIGH	2026-07-27 07:10:13.920046	f	afc5b633-7812-4726-ad5d-a1de1587fadd	New Maintenance Request MNT-20260727-836	MAINTENANCE	b1000000-0000-0000-0000-000000000001
21eff793-bc10-4ecf-a77d-47d17d9cb1e3	Điều hòa không mát - HIGH	2026-07-27 07:10:19.208132	f	2bee013f-38eb-4113-a2e0-a67a9385fe71	New Maintenance Request MNT-20260727-837	MAINTENANCE	b1000000-0000-0000-0000-000000000001
b333952c-b289-46f0-aa8e-06f5833b60fe	Your invoice for 2026-06-01 is overdue	2026-07-27 08:00:00.304759	f	b7000000-0000-0000-0000-000000000008	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000010
72f94232-12f0-4d8f-98ba-4accd2734ad7	Your invoice for 2026-06-01 is overdue	2026-07-27 08:00:00.307877	f	b7000000-0000-0000-0000-000000000011	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000011
5f209c97-d0a3-4414-afbc-1c99c406f3f9	Your invoice for 2026-06-01 is overdue	2026-07-27 08:00:00.310799	f	b7000000-0000-0000-0000-000000000014	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000012
b0a05137-d2f4-489d-a0ac-1f71615bdf19	Your invoice for 2026-06-01 is overdue	2026-07-27 08:00:00.40152	f	b7000000-0000-0000-0000-000000000017	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000013
f237a5a6-6f22-4a0c-b525-6e1b29b117d5	Your invoice for 2026-06-01 is overdue	2026-07-27 08:00:00.405032	f	b7000000-0000-0000-0000-000000000023	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000015
8f589568-9745-41fc-adb6-dc000ef05c75	Your invoice for 2026-06-01 is overdue	2026-07-27 08:00:00.410169	f	b7000000-0000-0000-0000-000000000029	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000017
83401fbc-46fc-4cde-835e-17658f31eb0f	Your invoice for 2026-06-01 is overdue	2026-07-27 08:00:00.501387	f	b7000000-0000-0000-0000-000000000032	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000018
e3281afe-6789-48fa-8424-1f3eb1d75069	Your invoice for 2026-06-01 is overdue	2026-07-27 08:00:00.504731	f	b7000000-0000-0000-0000-000000000035	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000019
69c54269-c89c-4b2b-ae51-0a338ee41d91	Your invoice for 2026-06-01 is overdue	2026-07-27 08:00:00.407561	t	b7000000-0000-0000-0000-000000000026	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000016
4bf68dd2-122e-4a0f-8b40-31f452f1529e	Your invoice for 2026-06-01 is overdue	2026-07-27 08:00:00.205177	t	b7000000-0000-0000-0000-000000000002	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000003
1f56fba5-9a0b-4ce4-8cf3-6af88b2b9687	Invoice for 2026-07 is ready	2026-07-27 08:46:17.421055	t	644f40d3-4f99-4d66-be61-6b855a095f31	New Invoice	INVOICE	a0000000-0000-0000-0000-000000000002
47b2ab8e-6d70-4786-94ae-a10f00fae7c6	Bi cai loz gi a - HIGH	2026-07-27 09:27:38.237146	t	dc04e66c-f7b1-4bf6-92b7-3128d587dc94	New Maintenance Request MNT-20260727-838	MAINTENANCE	a0000000-0000-0000-0000-000000000001
236aa2a3-1aac-4b17-a6d9-155d795ac7b1	Your invoice for 2026-07-01 is overdue	2026-07-27 08:00:00.507424	t	9f0fb102-65c1-4983-a6c4-792ad48b4571	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000002
3453a8f2-96bc-4dad-bab2-2d453232b126	Your invoice for 2026-06-01 is overdue	2026-07-27 08:00:00.301152	t	b7000000-0000-0000-0000-000000000004	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000005
15cda31e-b0db-4e02-8356-3555e0cc650f	Bi cai loz gi a - HIGH	2026-07-27 09:27:40.816432	t	c6587d83-4725-4763-a7f1-fa8288d9b863	New Maintenance Request MNT-20260727-839	MAINTENANCE	a0000000-0000-0000-0000-000000000001
107653cc-ea20-45e7-9afb-8dfb1ecd606d	Khách thuê phòng 0001 chọn thanh toán tiền mặt cho hóa đơn 2026-07-01	2026-07-27 09:26:02.85184	t	644f40d3-4f99-4d66-be61-6b855a095f31	Yêu cầu thanh toán tiền mặt	INVOICE	a0000000-0000-0000-0000-000000000001
6406ed7e-2d4f-41f0-ab78-f0a80a5b0662	điều hoà không mát - NORMAL	2026-07-27 10:24:19.701488	f	49fbc40e-667c-4252-9de8-57f155b09e78	New Maintenance Request MNT-20260727-840	MAINTENANCE	b1000000-0000-0000-0000-000000000001
f8f045cf-4354-4cab-9e26-7d7180a3f431	điều hoà không mát - NORMAL	2026-07-27 10:24:20.700809	f	e5e71416-e20c-4297-bc9b-64733d07f45f	New Maintenance Request MNT-20260727-841	MAINTENANCE	b1000000-0000-0000-0000-000000000001
bacf9301-6719-49c2-ae94-90d654070f0a	điều hoà không mát - NORMAL	2026-07-27 10:25:31.536483	f	a1dc49c3-f49f-4a54-a478-20c063c80cc6	New Maintenance Request MNT-20260727-842	MAINTENANCE	b1000000-0000-0000-0000-000000000001
61d55694-f28a-426f-afe3-21b0f414384e	điều hoà không mát - NORMAL	2026-07-27 10:25:34.729268	f	85ae8e7b-b3f2-4640-9ace-f8fa69761a9d	New Maintenance Request MNT-20260727-843	MAINTENANCE	b1000000-0000-0000-0000-000000000001
ab31f682-521e-4f87-9527-a575b836f055	Phiếu bảo trì điều hoà không hoạt động đã quá hạn SLA.	2026-07-27 13:08:27.191786	f	536a593e-7fa7-4273-bcbd-bb776de0254e	Cảnh báo quá hạn SLA: MNT-20260727-816	MAINTENANCE	b1000000-0000-0000-0000-000000000001
62dba5e3-dbd5-436d-ab66-143f9b854215	Phiếu bảo trì điều hoà không hoạt động đã quá hạn SLA.	2026-07-27 13:08:27.19295	f	dd480a87-1683-40f9-9839-48a4770ebebb	Cảnh báo quá hạn SLA: MNT-20260727-817	MAINTENANCE	b1000000-0000-0000-0000-000000000001
39b5a384-9283-4255-b30a-235befd33874	Phiếu bảo trì điều hoà không hoạt động đã quá hạn SLA.	2026-07-27 13:08:27.193261	f	84941eb2-0626-4f31-a574-745466e0a083	Cảnh báo quá hạn SLA: MNT-20260727-818	MAINTENANCE	b1000000-0000-0000-0000-000000000001
65cd2e23-3e32-43b7-9ff2-0da4483e3d03	Phiếu bảo trì điều hoà không hoạt động đã quá hạn SLA.	2026-07-27 13:08:27.19347	f	a3ed57fb-af95-4f3d-9b8d-c8b24b7a4f3c	Cảnh báo quá hạn SLA: MNT-20260727-819	MAINTENANCE	b1000000-0000-0000-0000-000000000001
9fb5a0fa-897b-43e1-b5f3-1f5a60add2bf	Phiếu bảo trì Điều hòa không mát đã quá hạn SLA.	2026-07-27 13:08:27.193669	f	438c33ae-4853-4877-b39c-e7f07ae3e9b4	Cảnh báo quá hạn SLA: MNT-20260727-830	MAINTENANCE	b1000000-0000-0000-0000-000000000001
6baf6656-fec2-4b47-b00e-6110e41a81d3	Phiếu bảo trì Điều hòa không mát đã quá hạn SLA.	2026-07-27 13:08:27.19386	f	cbf3b404-01fb-4818-bba9-f0887479ac1d	Cảnh báo quá hạn SLA: MNT-20260727-831	MAINTENANCE	b1000000-0000-0000-0000-000000000001
78a679a3-e32b-46ec-ad88-ae1d688b5402	Phiếu bảo trì Điều hòa không mát đã quá hạn SLA.	2026-07-27 13:08:27.194089	f	46ef6bd0-e132-490d-8261-763260644448	Cảnh báo quá hạn SLA: MNT-20260727-832	MAINTENANCE	b1000000-0000-0000-0000-000000000001
3d56a4ce-4b00-43c8-a35d-1916b59f70e3	Phiếu bảo trì Điều hòa không mát đã quá hạn SLA.	2026-07-27 13:08:27.194686	f	757ba10e-11c3-481b-a30b-1b826b7f8ff0	Cảnh báo quá hạn SLA: MNT-20260727-833	MAINTENANCE	b1000000-0000-0000-0000-000000000001
6719f612-2377-4f81-aee5-726a84887e01	Phiếu bảo trì Điều hòa không mát đã quá hạn SLA.	2026-07-27 13:38:27.42611	f	86d24202-5c2b-480f-beb2-0915096f911e	Cảnh báo quá hạn SLA: MNT-20260727-834	MAINTENANCE	b1000000-0000-0000-0000-000000000001
c5b38a18-e5e7-4ae4-ba71-07cae7bf70f4	Phiếu bảo trì Điều hòa không mát đã quá hạn SLA.	2026-07-27 13:38:27.426443	f	e0dd70bc-3417-4d3e-aa7c-b7710a2308da	Cảnh báo quá hạn SLA: MNT-20260727-835	MAINTENANCE	b1000000-0000-0000-0000-000000000001
e1e2df02-c3ee-4d9a-9b85-58e80e820faa	Phiếu bảo trì Điều hòa không mát đã quá hạn SLA.	2026-07-27 13:38:27.426691	f	afc5b633-7812-4726-ad5d-a1de1587fadd	Cảnh báo quá hạn SLA: MNT-20260727-836	MAINTENANCE	b1000000-0000-0000-0000-000000000001
b38dd530-84c7-450c-8d4a-16ca5b5d19e4	Phiếu bảo trì Điều hòa không mát đã quá hạn SLA.	2026-07-27 13:38:27.426921	f	2bee013f-38eb-4113-a2e0-a67a9385fe71	Cảnh báo quá hạn SLA: MNT-20260727-837	MAINTENANCE	b1000000-0000-0000-0000-000000000001
9588d8cd-4bf6-436d-8838-5925984488f6	Khách thuê phòng 0001 chọn thanh toán tiền mặt cho hóa đơn 2026-07-01	2026-07-28 01:50:01.566833	t	644f40d3-4f99-4d66-be61-6b855a095f31	Yêu cầu thanh toán tiền mặt	INVOICE	a0000000-0000-0000-0000-000000000001
843d3b40-4c7f-47b6-95f6-948cb394852b	Khách thuê phòng 0001 chọn thanh toán tiền mặt cho hóa đơn 2026-07-01	2026-07-28 01:49:23.801467	t	644f40d3-4f99-4d66-be61-6b855a095f31	Yêu cầu thanh toán tiền mặt	INVOICE	a0000000-0000-0000-0000-000000000001
21cd16e9-b2b8-4bf5-b662-c3ae5620148e	Phiếu bảo trì Bi cai loz gi a đã quá hạn SLA.	2026-07-27 15:38:27.51903	t	dc04e66c-f7b1-4bf6-92b7-3128d587dc94	Cảnh báo quá hạn SLA: MNT-20260727-838	MAINTENANCE	a0000000-0000-0000-0000-000000000001
756c49a8-8fc1-498d-81ad-bc2f9cc96619	Phiếu bảo trì Bi cai loz gi a đã quá hạn SLA.	2026-07-27 15:38:29.101328	t	c6587d83-4725-4763-a7f1-fa8288d9b863	Cảnh báo quá hạn SLA: MNT-20260727-839	MAINTENANCE	a0000000-0000-0000-0000-000000000001
7163dec2-3a43-44d1-b384-cf9dec527fbe	Phiếu bảo trì điều hoà bị chảy nước đã quá hạn SLA.	2026-07-28 07:08:30.301513	f	2e661bb3-5cf3-462f-9cde-510a75a5d1a3	Cảnh báo quá hạn SLA: MNT-20260727-808	MAINTENANCE	b1000000-0000-0000-0000-000000000001
7b1c087a-37e6-4d51-b483-0cbb54afe372	Phiếu bảo trì điều hoà bị chảy nước đã quá hạn SLA.	2026-07-28 07:08:30.30295	f	300cfc87-df62-4a88-9887-9034ad1266d5	Cảnh báo quá hạn SLA: MNT-20260727-809	MAINTENANCE	b1000000-0000-0000-0000-000000000001
d59d8c61-3bdc-4d11-aa2f-dd525bda0a6e	Phiếu bảo trì điều hoà bị chảy nước đã quá hạn SLA.	2026-07-28 07:08:30.304224	f	04a53e7e-15a4-4a9d-afed-567596ae20c6	Cảnh báo quá hạn SLA: MNT-20260727-810	MAINTENANCE	b1000000-0000-0000-0000-000000000001
6ec30eff-5b79-4711-96d6-e847c07525f8	Phiếu bảo trì điều hoà bị chảy nước đã quá hạn SLA.	2026-07-28 07:08:30.401299	f	aa5bed2d-405c-4a8b-8ce3-bb9bfef19dfb	Cảnh báo quá hạn SLA: MNT-20260727-811	MAINTENANCE	b1000000-0000-0000-0000-000000000001
38124162-553a-4909-802a-f9efe77ae383	Phiếu bảo trì điều hoà bị chảy nước đã quá hạn SLA.	2026-07-28 07:08:30.4023	f	f9c6f0d8-16f0-483f-b043-d2e389493f60	Cảnh báo quá hạn SLA: MNT-20260727-812	MAINTENANCE	b1000000-0000-0000-0000-000000000001
0572138d-a8d5-4ad6-924e-19eb5c9efa2d	Phiếu bảo trì điều hoà bị chảy nước đã quá hạn SLA.	2026-07-28 07:08:30.603555	f	ed7264e5-49b9-43c1-9d82-2f63c8019d6e	Cảnh báo quá hạn SLA: MNT-20260727-813	MAINTENANCE	b1000000-0000-0000-0000-000000000001
89fd62b5-db52-430c-8880-8cefc148707d	Phiếu bảo trì điều hoà bị chảy nước đã quá hạn SLA.	2026-07-28 07:08:30.604283	f	caf31977-a7ff-49eb-8166-c8e852487a09	Cảnh báo quá hạn SLA: MNT-20260727-814	MAINTENANCE	b1000000-0000-0000-0000-000000000001
e001043e-1fde-49e7-b25d-93e34d9d468b	Phiếu bảo trì điều hoà bị chảy nước đã quá hạn SLA.	2026-07-28 07:08:30.604826	f	8ce7171e-c161-4408-a821-3b0aed85847c	Cảnh báo quá hạn SLA: MNT-20260727-815	MAINTENANCE	b1000000-0000-0000-0000-000000000001
950ba410-58e8-4e6c-9dc1-3f9968629709	Phiếu bảo trì Điều hòa không mát đã quá hạn SLA.	2026-07-28 07:08:30.605375	f	8f3a647b-4162-4c49-8567-d09c35e04ad2	Cảnh báo quá hạn SLA: MNT-20260727-820	MAINTENANCE	b1000000-0000-0000-0000-000000000001
af33e91b-b9e2-4666-aec4-1dcdf272c4d0	Phiếu bảo trì Điều hòa không mát đã quá hạn SLA.	2026-07-28 07:08:30.605768	f	f9e43efa-0144-4dbe-820c-59e4141ceeb8	Cảnh báo quá hạn SLA: MNT-20260727-821	MAINTENANCE	b1000000-0000-0000-0000-000000000001
da0ab46b-2bb9-4016-a765-e2cc2361d6e4	Phiếu bảo trì Điều hòa không mát đã quá hạn SLA.	2026-07-28 07:08:30.701535	f	6d2de875-2fdb-45e7-b621-17bd86226815	Cảnh báo quá hạn SLA: MNT-20260727-822	MAINTENANCE	b1000000-0000-0000-0000-000000000001
3335612f-f06f-4cb6-90a1-f92b226f42e0	Phiếu bảo trì 123 đã quá hạn SLA.	2026-07-30 02:04:40.071508	t	ca7af936-6596-4ccf-ab2b-588a1ba131e7	Cảnh báo quá hạn SLA: MNT-20260729-847	MAINTENANCE	a0000000-0000-0000-0000-000000000001
4f3c7571-d90b-4566-acde-01994180db5e	Phiếu bảo trì asfasf đã quá hạn SLA.	2026-07-30 03:04:40.702668	t	b0544e1c-d3f6-4441-a690-c2c0bdd83920	Cảnh báo quá hạn SLA: MNT-20260729-848	MAINTENANCE	a0000000-0000-0000-0000-000000000001
1f06af3d-34f5-4d34-a87a-71493b9cb88a	Phiếu bảo trì asfasf đã quá hạn SLA.	2026-07-30 03:04:40.703508	t	e1f8ef7c-720f-4d71-ab02-e761f4cd93d2	Cảnh báo quá hạn SLA: MNT-20260729-849	MAINTENANCE	a0000000-0000-0000-0000-000000000001
a292d5d2-5f6b-488c-a78b-63ded7f803a2	QA serialization probe - NORMAL	2026-07-30 11:11:27.868767	t	28774408-c16e-471f-b982-1fe505f5856b	New Maintenance Request MNT-20260730-832	MAINTENANCE	a0000000-0000-0000-0000-000000000001
e4f46ca6-1ff6-426e-9c97-fa324b87993e	cửa bị ket - NORMAL	2026-08-04 09:28:52.861171	f	791b3bc7-973e-4ce9-b0f8-2c2bed1383d5	New Maintenance Request MNT-20260804-061	MAINTENANCE	b1000000-0000-0000-0000-000000000001
496b9f98-4531-4952-95b8-5326194b8ca3	Phiếu bảo trì Điều hòa không mát đã quá hạn SLA.	2026-07-28 07:08:30.702348	f	08ee7530-a733-485e-b1bd-579a997d77fc	Cảnh báo quá hạn SLA: MNT-20260727-823	MAINTENANCE	b1000000-0000-0000-0000-000000000001
666a0eca-076c-4333-814a-3d262da7d831	Phiếu bảo trì Điều hòa không mát đã quá hạn SLA.	2026-07-28 07:08:30.702927	f	e3cbf44f-70c1-4065-b448-bfe6fd3eb84b	Cảnh báo quá hạn SLA: MNT-20260727-824	MAINTENANCE	b1000000-0000-0000-0000-000000000001
19c8974b-4d66-432d-82c0-131ceb7f2e28	Phiếu bảo trì Điều hòa không mát đã quá hạn SLA.	2026-07-28 07:08:30.704271	f	b37d3442-70c1-44a7-8b0f-c16e3d2d05fd	Cảnh báo quá hạn SLA: MNT-20260727-825	MAINTENANCE	b1000000-0000-0000-0000-000000000001
6ef83764-4aa5-4b9f-a47a-0943d768f094	Phiếu bảo trì Điều hòa không mát đã quá hạn SLA.	2026-07-28 07:08:30.801333	f	a37395c2-abfd-4627-a2ed-a449d870d276	Cảnh báo quá hạn SLA: MNT-20260727-826	MAINTENANCE	b1000000-0000-0000-0000-000000000001
283e3eed-a30f-447a-b6ce-e1f3b97ce858	Phiếu bảo trì Điều hòa không mát đã quá hạn SLA.	2026-07-28 07:08:30.802723	f	64f5b409-34d7-4499-9ad2-0fa043005180	Cảnh báo quá hạn SLA: MNT-20260727-827	MAINTENANCE	b1000000-0000-0000-0000-000000000001
c6ca8eb2-ff6e-4893-925e-150cbca2aadc	Phiếu bảo trì Điều hòa không mát đã quá hạn SLA.	2026-07-28 07:08:30.803492	f	2119d259-d667-4994-8cb4-2d4f7f483e5b	Cảnh báo quá hạn SLA: MNT-20260727-828	MAINTENANCE	b1000000-0000-0000-0000-000000000001
5c02fb0a-99d9-4764-bf83-51bd4151b8d6	Phiếu bảo trì Điều hòa không mát đã quá hạn SLA.	2026-07-28 07:08:30.804027	f	ad47bc66-00e6-465f-a441-04449b1d21ad	Cảnh báo quá hạn SLA: MNT-20260727-829	MAINTENANCE	b1000000-0000-0000-0000-000000000001
f9893675-cc32-484a-b141-1d95d3ba471f	Phiếu bảo trì điều hoà không mát đã quá hạn SLA.	2026-07-28 10:38:33.502043	f	49fbc40e-667c-4252-9de8-57f155b09e78	Cảnh báo quá hạn SLA: MNT-20260727-840	MAINTENANCE	b1000000-0000-0000-0000-000000000001
e2d8efe8-cefa-4afb-becf-7cf08fd15139	Phiếu bảo trì điều hoà không mát đã quá hạn SLA.	2026-07-28 10:38:33.502991	f	e5e71416-e20c-4297-bc9b-64733d07f45f	Cảnh báo quá hạn SLA: MNT-20260727-841	MAINTENANCE	b1000000-0000-0000-0000-000000000001
831d7715-ab67-4d01-a4a8-57a884548c3d	Phiếu bảo trì điều hoà không mát đã quá hạn SLA.	2026-07-28 10:38:33.50331	f	a1dc49c3-f49f-4a54-a478-20c063c80cc6	Cảnh báo quá hạn SLA: MNT-20260727-842	MAINTENANCE	b1000000-0000-0000-0000-000000000001
ab1ed029-34c5-466b-b8ee-8ac7a8cc6920	Phiếu bảo trì điều hoà không mát đã quá hạn SLA.	2026-07-28 10:38:33.503696	f	85ae8e7b-b3f2-4640-9ace-f8fa69761a9d	Cảnh báo quá hạn SLA: MNT-20260727-843	MAINTENANCE	b1000000-0000-0000-0000-000000000001
8b7fd8ef-3500-4af3-8280-d819c785a0c1	test with image - NORMAL	2026-07-31 04:56:34.937032	t	8721cde2-53f1-478e-842d-63cef0d8e17a	New Maintenance Request MNT-20260731-940	MAINTENANCE	a0000000-0000-0000-0000-000000000001
bbb7389d-a474-4cfc-9bc1-2afaacb5ea34	test with image - NORMAL	2026-07-31 04:56:27.23195	t	2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9	New Maintenance Request MNT-20260731-939	MAINTENANCE	a0000000-0000-0000-0000-000000000001
61daa033-3974-4da3-b531-ce723d40bc2d	QA serialization green probe - NORMAL	2026-07-30 11:15:06.620929	t	8342b2b1-d767-4869-acf7-97e27a5aa40f	New Maintenance Request MNT-20260730-402	MAINTENANCE	a0000000-0000-0000-0000-000000000001
fb5cb159-02d8-47b0-8d15-3802f95847ab	disjglsdnglsdglsq - NORMAL	2026-07-31 03:29:10.933759	t	3e412a56-e4c8-45ef-bc2c-488e118c0651	New Maintenance Request MNT-20260731-937	MAINTENANCE	a0000000-0000-0000-0000-000000000001
6ef25f52-b4bb-4c1e-b9e2-9e472254e007	test with image - NORMAL	2026-07-31 04:56:22.036118	t	de307c0f-3c70-4767-9a77-6adb46585bb4	New Maintenance Request MNT-20260731-938	MAINTENANCE	a0000000-0000-0000-0000-000000000001
1077b38d-8077-4763-a289-d1cfd154ff88	a - NORMAL	2026-07-29 01:34:43.408941	t	6c0b25e4-a92e-40d9-8480-03e5efe58461	New Maintenance Request MNT-20260729-844	MAINTENANCE	a0000000-0000-0000-0000-000000000001
e22c3363-a9ab-4db7-a44c-05bbd9dd7643	a - NORMAL	2026-07-29 01:34:45.30213	t	7c657edc-5072-4c13-9e24-0dba94836489	New Maintenance Request MNT-20260729-845	MAINTENANCE	a0000000-0000-0000-0000-000000000001
1602b334-66ff-45d8-9843-9d83a136b1c9	123 - NORMAL	2026-07-29 01:35:49.306069	t	afab1b6d-6ae8-4337-84a6-982a90835589	New Maintenance Request MNT-20260729-846	MAINTENANCE	a0000000-0000-0000-0000-000000000001
3faec0c4-e60f-400a-ad7d-6b57e67b6642	123 - NORMAL	2026-07-29 01:35:49.905699	t	ca7af936-6596-4ccf-ab2b-588a1ba131e7	New Maintenance Request MNT-20260729-847	MAINTENANCE	a0000000-0000-0000-0000-000000000001
c7a7a890-9c25-4ee7-9bf5-4c941c0db6af	asfasf - NORMAL	2026-07-29 03:03:34.911764	t	b0544e1c-d3f6-4441-a690-c2c0bdd83920	New Maintenance Request MNT-20260729-848	MAINTENANCE	a0000000-0000-0000-0000-000000000001
68ec497c-353d-478d-aa99-4be12f94a66e	asfasf - NORMAL	2026-07-29 03:03:35.808451	t	e1f8ef7c-720f-4d71-ab02-e761f4cd93d2	New Maintenance Request MNT-20260729-849	MAINTENANCE	a0000000-0000-0000-0000-000000000001
3b62f093-7ef4-432d-8488-4bd93f53a77b	Phiếu bảo trì a đã quá hạn SLA.	2026-07-30 02:04:39.97092	t	6c0b25e4-a92e-40d9-8480-03e5efe58461	Cảnh báo quá hạn SLA: MNT-20260729-844	MAINTENANCE	a0000000-0000-0000-0000-000000000001
cf20c280-02d3-4404-aae5-0b916f3f6f1b	Phiếu bảo trì a đã quá hạn SLA.	2026-07-30 02:04:40.069849	t	7c657edc-5072-4c13-9e24-0dba94836489	Cảnh báo quá hạn SLA: MNT-20260729-845	MAINTENANCE	a0000000-0000-0000-0000-000000000001
aa4f4efa-4ad7-497b-bf99-68489601ca74	Phiếu bảo trì 123 đã quá hạn SLA.	2026-07-30 02:04:40.070664	t	afab1b6d-6ae8-4337-84a6-982a90835589	Cảnh báo quá hạn SLA: MNT-20260729-846	MAINTENANCE	a0000000-0000-0000-0000-000000000001
095e2bfb-0bf5-460e-b6f5-363ec6aaa78b	Mã phiếu: MNT-20260731-940 - Khách hàng: Nguyễn Văn A	2026-07-31 05:01:17.433834	t	8721cde2-53f1-478e-842d-63cef0d8e17a	Phân công bảo trì: test with image	MAINTENANCE	774a2c9e-8929-4d7c-80ca-14f62b9d9d56
f35ce274-4953-4d0c-8721-30707924bad7	Phiếu bảo trì QA serialization probe đã quá hạn SLA.	2026-07-31 11:17:22.794319	t	28774408-c16e-471f-b982-1fe505f5856b	Cảnh báo quá hạn SLA: MNT-20260730-832	MAINTENANCE	a0000000-0000-0000-0000-000000000001
ba2352e5-3ebe-4dcc-b3ee-20c3e18f5e49	Phiếu bảo trì QA serialization green probe đã quá hạn SLA.	2026-07-31 11:17:22.993946	t	8342b2b1-d767-4869-acf7-97e27a5aa40f	Cảnh báo quá hạn SLA: MNT-20260730-402	MAINTENANCE	a0000000-0000-0000-0000-000000000001
0a7d6382-9760-43f1-acae-a2954ad9f9c9	Khách thuê phòng T3-12.08 chọn thanh toán tiền mặt cho hóa đơn 2026-08-01	2026-08-01 13:33:56.868257	f	7c135337-f51e-49fa-8731-3768446542f0	Yêu cầu thanh toán tiền mặt	INVOICE	b1000000-0000-0000-0000-000000000001
b9f7fd7c-4524-4ae2-84a3-69981f0b111a	Phiếu bảo trì test with image đã vượt thời gian xử lý dự kiến.	2026-08-01 05:20:32.981248	t	8721cde2-53f1-478e-842d-63cef0d8e17a	Khẩn cấp: Quá hạn SLA MNT-20260731-940	MAINTENANCE	774a2c9e-8929-4d7c-80ca-14f62b9d9d56
a133e1a5-44cb-4a4b-bbd7-41b0243b9b2d	Vòi nước hỏng - HIGH	2026-08-02 07:21:50.279147	t	e3a2fec5-a9ad-409f-944d-ef61236f54cc	New Maintenance Request MNT-20260802-176	MAINTENANCE	a0000000-0000-0000-0000-000000000001
ff53f0d9-6b6b-4165-85d5-09c64fce0a6d	Kỹ thuật viên đề xuất khung giờ: Sáng mai (8:00 - 11:30). Vui lòng xác nhận.	2026-07-31 07:09:03.300054	t	8721cde2-53f1-478e-842d-63cef0d8e17a	Lịch bảo trì MNT-20260731-940	MAINTENANCE	a0000000-0000-0000-0000-000000000002
458d03c0-f6f0-4728-bbe2-947e87b3bb3c	Phiếu bảo trì test with image đã quá hạn SLA.	2026-08-01 05:20:32.980841	t	8721cde2-53f1-478e-842d-63cef0d8e17a	Cảnh báo quá hạn SLA: MNT-20260731-940	MAINTENANCE	a0000000-0000-0000-0000-000000000001
3f2d751b-c5ae-45af-b9d4-3b1a2f8213e3	Phiếu bảo trì test with image đã quá hạn SLA.	2026-08-01 05:20:32.954815	t	2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9	Cảnh báo quá hạn SLA: MNT-20260731-939	MAINTENANCE	a0000000-0000-0000-0000-000000000001
707f04b1-d63e-4c21-b472-36caff2c08fb	Phiếu bảo trì test with image đã quá hạn SLA.	2026-08-01 05:20:32.946608	t	de307c0f-3c70-4767-9a77-6adb46585bb4	Cảnh báo quá hạn SLA: MNT-20260731-938	MAINTENANCE	a0000000-0000-0000-0000-000000000001
0a1dcb70-d653-4fcf-ac87-2bd65ed1159a	Phiếu bảo trì disjglsdnglsdglsq đã quá hạn SLA.	2026-08-01 03:50:32.474793	t	3e412a56-e4c8-45ef-bc2c-488e118c0651	Cảnh báo quá hạn SLA: MNT-20260731-937	MAINTENANCE	a0000000-0000-0000-0000-000000000001
860c188c-98d8-45ed-9410-4ffdbff549cc	Invoice for 2026-08 is ready	2026-08-01 13:06:24.382022	t	7c135337-f51e-49fa-8731-3768446542f0	New Invoice	INVOICE	b1000000-0000-0000-0000-000000000002
e8f2ccaf-4d0b-459b-814c-d84b4789a86c	Cư dân đã xác nhận lịch hẹn: Chiều mai (13:30 - 17:00)	2026-08-02 07:26:04.039191	t	e3a2fec5-a9ad-409f-944d-ef61236f54cc	Phản hồi lịch hẹn MNT-20260802-176	MAINTENANCE	7b70cfa6-d414-4165-b17c-dde2c4aea3ba
40063ec5-263d-4495-8c9a-3265673a372d	Mã phiếu: MNT-20260802-176 - Khách hàng: Nguyễn Văn A	2026-08-02 07:23:34.384187	t	e3a2fec5-a9ad-409f-944d-ef61236f54cc	Phân công bảo trì: Vòi nước hỏng	MAINTENANCE	7b70cfa6-d414-4165-b17c-dde2c4aea3ba
cc02f69a-e609-43f5-86d7-4cca52e08974	Kỹ thuật viên đề xuất khung giờ: Chiều mai (13:30 - 17:00). Vui lòng xác nhận.	2026-08-02 07:25:19.633458	t	e3a2fec5-a9ad-409f-944d-ef61236f54cc	Lịch bảo trì MNT-20260802-176	MAINTENANCE	a0000000-0000-0000-0000-000000000002
2063b831-6e3f-4179-917c-7376cbf96ebb	Invoice for 2026-08 is ready	2026-08-02 07:40:28.677986	f	cdba4b04-3ca8-4996-833c-0048bf68296d	New Invoice	INVOICE	b1000000-0000-0000-0000-000000000014
de2a5933-43d2-4c37-887d-140f4c544615	Khách thuê phòng 0001 chọn thanh toán tiền mặt cho hóa đơn 2026-08-01	2026-08-02 07:42:20.171815	t	a6471a5a-9a29-4d2e-9574-15a7d8d08520	Yêu cầu thanh toán tiền mặt	INVOICE	a0000000-0000-0000-0000-000000000001
cf9a322c-7804-4bb7-bfd4-f3a9a45883f8	Khách thuê phòng 0001 chọn thanh toán tiền mặt cho hóa đơn 2026-08-01	2026-08-02 07:42:45.988696	t	a6471a5a-9a29-4d2e-9574-15a7d8d08520	Yêu cầu thanh toán tiền mặt	INVOICE	a0000000-0000-0000-0000-000000000001
143244d5-104a-414d-bb19-e5a72e585118	Khách thuê phòng 0001 chọn thanh toán tiền mặt cho hóa đơn 2026-08-01	2026-08-02 07:41:53.833004	t	a6471a5a-9a29-4d2e-9574-15a7d8d08520	Yêu cầu thanh toán tiền mặt	INVOICE	a0000000-0000-0000-0000-000000000001
0ae6d088-a8ec-477d-b38c-4e08d3523b84	Invoice for 2026-08 is ready	2026-08-04 07:27:40.707165	f	8e596cb3-e94a-48fe-9954-844e520f2e1c	New Invoice	INVOICE	b1000000-0000-0000-0000-000000000006
bb8260c7-d454-4eaf-ab11-7b048bdb9a9d	Invoice for 2026-08 is ready	2026-08-04 07:27:41.107319	f	e36d3e32-acf2-4031-af62-fb8c82b92619	New Invoice	INVOICE	b1000000-0000-0000-0000-000000000007
999e6979-affe-4c85-965b-cc9051245cc1	Invoice for 2026-08 is ready	2026-08-02 07:41:25.419364	t	a6471a5a-9a29-4d2e-9574-15a7d8d08520	New Invoice	INVOICE	a0000000-0000-0000-0000-000000000002
aa4c2260-197f-478a-945e-12d357655f97	Phiếu bảo trì Vòi nước hỏng đã quá hạn SLA.	2026-08-04 07:23:10.806916	t	e3a2fec5-a9ad-409f-944d-ef61236f54cc	Cảnh báo quá hạn SLA: MNT-20260802-176	MAINTENANCE	a0000000-0000-0000-0000-000000000001
7b3f7829-cbf9-44e9-9e7f-ec8abd6eb124	Cư dân đã xác nhận lịch hẹn: Sáng mai (8:00 - 11:30)	2026-08-04 08:06:37.228756	t	8721cde2-53f1-478e-842d-63cef0d8e17a	Phản hồi lịch hẹn MNT-20260731-940	MAINTENANCE	774a2c9e-8929-4d7c-80ca-14f62b9d9d56
d9f96b74-89ee-4f79-aa72-a1c264064db7	Cư dân đã xác nhận lịch hẹn: Sáng mai (8:00 - 11:30)	2026-08-04 08:06:36.670907	t	8721cde2-53f1-478e-842d-63cef0d8e17a	Phản hồi lịch hẹn MNT-20260731-940	MAINTENANCE	774a2c9e-8929-4d7c-80ca-14f62b9d9d56
e7496d55-6df6-4223-aa2a-4b6291de7b69	Mã phiếu: MNT-20260731-939 - Khách hàng: Nguyễn Văn A	2026-08-04 07:30:57.70421	t	2fa70b5d-0f77-4c29-81ce-0d6131e4f6e9	Phân công bảo trì: test with image	MAINTENANCE	774a2c9e-8929-4d7c-80ca-14f62b9d9d56
fc2c27e7-0942-43ea-8dc4-0b72074345f4	Invoice for 2026-08 is ready	2026-08-04 07:27:40.003696	t	cc0cd89c-886d-476e-a9f2-6a4a2649bb01	New Invoice	INVOICE	b1000000-0000-0000-0000-000000000004
8a292924-5e43-496e-8667-baa9f0080f66	Khách thuê phòng P6-18.05 chọn thanh toán tiền mặt cho hóa đơn 2026-08-01	2026-08-04 08:15:35.019077	f	cc0cd89c-886d-476e-a9f2-6a4a2649bb01	Yêu cầu thanh toán tiền mặt	INVOICE	b1000000-0000-0000-0000-000000000001
32945332-bd99-4239-aadf-0b915ce1444a	Khách thuê phòng P6-18.05 chọn thanh toán tiền mặt cho hóa đơn 2026-08-01	2026-08-04 08:15:46.093083	f	cc0cd89c-886d-476e-a9f2-6a4a2649bb01	Yêu cầu thanh toán tiền mặt	INVOICE	b1000000-0000-0000-0000-000000000001
ec334e98-8b00-4d06-8ac0-8545e9f2d3d9	Khách thuê phòng P6-18.05 chọn thanh toán tiền mặt cho hóa đơn 2026-08-01	2026-08-04 08:16:20.117952	f	cc0cd89c-886d-476e-a9f2-6a4a2649bb01	Yêu cầu thanh toán tiền mặt	INVOICE	b1000000-0000-0000-0000-000000000001
58f8bd00-0f14-4977-bb77-6e06ce6ae956	Khách thuê phòng T3-12.08 chọn thanh toán tiền mặt cho hóa đơn 2026-08-01	2026-08-04 08:22:49.565838	f	7c135337-f51e-49fa-8731-3768446542f0	Yêu cầu thanh toán tiền mặt	INVOICE	b1000000-0000-0000-0000-000000000001
c2b481b8-18ef-4bd3-8bd1-3cbc4ddc00fb	Máy tính lỗi thời - URGENT	2026-08-04 08:35:40.109434	f	919b3461-8baf-4669-b0fc-e66c998d0c38	New Maintenance Request MNT-20260804-107	MAINTENANCE	b1000000-0000-0000-0000-000000000001
dfc06647-dcf3-4311-a24b-703d30d70485	Máy tính lỗi thời - URGENT	2026-08-04 08:35:46.20754	f	797fc693-e426-43c8-be82-06e318cd6b46	New Maintenance Request MNT-20260804-108	MAINTENANCE	b1000000-0000-0000-0000-000000000001
fad82bc6-9d65-4382-bfd4-899096e8a641	Máy tính lỗi thời - URGENT	2026-08-04 08:35:51.302773	f	5bd48f3a-3600-45a2-a302-3698710235a2	New Maintenance Request MNT-20260804-109	MAINTENANCE	b1000000-0000-0000-0000-000000000001
87a337e5-07dd-4b28-bfdb-9e6e094ee592	Máy tính lỗi thời - URGENT	2026-08-04 08:35:59.31489	f	c2738e46-85d0-45f2-b0d6-ae16f04d1cad	New Maintenance Request MNT-20260804-110	MAINTENANCE	b1000000-0000-0000-0000-000000000001
456cadf5-a339-4a9f-9a85-0db3dc67c01e	Máy tính lỗi thời - URGENT	2026-08-04 08:36:11.4162	f	9b31d59a-e23c-4ea5-9b4c-957406f94725	New Maintenance Request MNT-20260804-111	MAINTENANCE	b1000000-0000-0000-0000-000000000001
9d992882-bfa2-48b6-84ee-ebe71e136a6a	Máy tính lỗi thời - URGENT	2026-08-04 08:36:30.402845	f	de427a93-5a73-4187-b30c-6b18f1d8073e	New Maintenance Request MNT-20260804-112	MAINTENANCE	b1000000-0000-0000-0000-000000000001
938a7910-64a8-421c-bf8a-22298ba2cbf7	Máy tính lỗi thời - URGENT	2026-08-04 08:37:04.32328	f	cbf3facb-8486-47b7-b951-cea864340b19	New Maintenance Request MNT-20260804-113	MAINTENANCE	b1000000-0000-0000-0000-000000000001
d53e1c4b-76bf-46c9-a85a-d3bd8059c547	Máy tính lỗi thời - URGENT	2026-08-04 08:50:24.604068	f	c5e0255e-0794-408f-9677-5db981f2d32f	New Maintenance Request MNT-20260804-114	MAINTENANCE	b1000000-0000-0000-0000-000000000001
1199cac2-4b2a-4d18-9c3e-bcbce0626c42	Vòi nước bị hỏng - HIGH	2026-08-04 08:50:57.119366	f	92b4e6ca-0abe-429e-8385-18666f89cd13	New Maintenance Request MNT-20260804-115	MAINTENANCE	b1000000-0000-0000-0000-000000000001
129ba013-0687-42ac-887f-0088da0e5063	cửa bị ket - NORMAL	2026-08-04 09:22:52.461677	f	e56e460b-511b-48af-b2ac-3d8e93a464cc	New Maintenance Request MNT-20260804-057	MAINTENANCE	b1000000-0000-0000-0000-000000000001
cfb7a10f-ec6c-4edf-ba96-ad14581fd822	cửa bị ket - NORMAL	2026-08-04 09:22:57.103306	f	3ea22299-cbb4-4730-9ae1-aac56cf897b0	New Maintenance Request MNT-20260804-058	MAINTENANCE	b1000000-0000-0000-0000-000000000001
84bd117b-b8d8-4c4f-999b-c6aaa6f99645	cửa bị ket - NORMAL	2026-08-04 09:23:01.867795	f	10929fc8-6e84-4107-af9f-50d2aa7fc9c5	New Maintenance Request MNT-20260804-059	MAINTENANCE	b1000000-0000-0000-0000-000000000001
fc48ee78-f6a2-4832-aa73-0e24cf11a576	cửa bị ket - NORMAL	2026-08-04 09:23:08.756908	f	babc7312-1c6f-4670-8297-351d392a1996	New Maintenance Request MNT-20260804-060	MAINTENANCE	b1000000-0000-0000-0000-000000000001
7b4b230f-1cb8-4dde-a1bf-76ffa6fe0103	Cư dân từ chối khung giờ: Sáng mai (8:00 - 11:30)	2026-08-04 09:01:54.515078	t	c5e0255e-0794-408f-9677-5db981f2d32f	Phản hồi lịch hẹn MNT-20260804-114	MAINTENANCE	7b70cfa6-d414-4165-b17c-dde2c4aea3ba
a0d2df80-b317-4432-8e09-bfe388ef8822	Cư dân từ chối khung giờ: Sáng mai (8:00 - 11:30)	2026-08-04 09:01:54.515063	t	c5e0255e-0794-408f-9677-5db981f2d32f	Phản hồi lịch hẹn MNT-20260804-114	MAINTENANCE	7b70cfa6-d414-4165-b17c-dde2c4aea3ba
2a3de72a-1030-48a4-b5db-ddc2fda3f5c6	Cư dân đã xác nhận lịch hẹn: Sáng mai (8:00 - 11:30)	2026-08-04 08:59:06.55981	t	92b4e6ca-0abe-429e-8385-18666f89cd13	Phản hồi lịch hẹn MNT-20260804-115	MAINTENANCE	7b70cfa6-d414-4165-b17c-dde2c4aea3ba
9ba891e8-1d01-4397-8778-69eb8420c792	Cư dân từ chối khung giờ: Sáng mai (8:00 - 11:30)	2026-08-04 09:01:23.547968	t	c5e0255e-0794-408f-9677-5db981f2d32f	Phản hồi lịch hẹn MNT-20260804-114	MAINTENANCE	7b70cfa6-d414-4165-b17c-dde2c4aea3ba
075074ef-8808-416f-a5ac-272af7d70f14	Mã phiếu: MNT-20260804-114 - Khách hàng: Tran Gia Han	2026-08-04 08:52:03.818922	t	c5e0255e-0794-408f-9677-5db981f2d32f	Phân công bảo trì: Máy tính lỗi thời	MAINTENANCE	7b70cfa6-d414-4165-b17c-dde2c4aea3ba
f23c279d-5935-4eaf-a469-4a43f36096f4	Mã phiếu: MNT-20260804-115 - Khách hàng: Tran Gia Han	2026-08-04 08:51:50.935809	t	92b4e6ca-0abe-429e-8385-18666f89cd13	Phân công bảo trì: Vòi nước bị hỏng	MAINTENANCE	7b70cfa6-d414-4165-b17c-dde2c4aea3ba
e562228b-4db6-4404-b3fa-5e3c0dbe8f9f	Mã phiếu: MNT-20260731-938 - Khách hàng: Nguyễn Văn A	2026-08-04 07:31:20.109538	t	de307c0f-3c70-4767-9a77-6adb46585bb4	Phân công bảo trì: test with image	MAINTENANCE	7b70cfa6-d414-4165-b17c-dde2c4aea3ba
60e33835-20d5-4dca-bcfa-80c40d9fea78	Phiếu bảo trì Vòi nước hỏng đã vượt thời gian xử lý dự kiến.	2026-08-04 07:23:10.808296	t	e3a2fec5-a9ad-409f-944d-ef61236f54cc	Khẩn cấp: Quá hạn SLA MNT-20260802-176	MAINTENANCE	7b70cfa6-d414-4165-b17c-dde2c4aea3ba
4122b3a4-dab8-4035-aa1b-4786bd38d72e	Kỹ thuật viên đề xuất khung giờ: Sáng mai (8:00 - 11:30). Vui lòng xác nhận.	2026-08-04 09:01:16.340912	t	c5e0255e-0794-408f-9677-5db981f2d32f	Lịch bảo trì MNT-20260804-114	MAINTENANCE	b1000000-0000-0000-0000-000000000003
e4e74a6a-b9e5-4cf4-9baa-193c7da5882d	Kỹ thuật viên đề xuất khung giờ: Sáng mai (8:00 - 11:30). Vui lòng xác nhận.	2026-08-04 08:58:54.506144	t	92b4e6ca-0abe-429e-8385-18666f89cd13	Lịch bảo trì MNT-20260804-115	MAINTENANCE	b1000000-0000-0000-0000-000000000003
6aa7caa6-e862-41b8-a81c-b495a6a19964	 - NORMAL	2026-08-04 09:29:09.766044	f	ee2e951d-6752-4790-8805-0a21dc2bf15a	New Maintenance Request MNT-20260804-062	MAINTENANCE	b1000000-0000-0000-0000-000000000001
e0500e8a-02cf-40bd-b43d-2090aeba4420	Kỹ thuật viên đề xuất khung giờ: Chiều mai (13:30 - 17:00). Vui lòng xác nhận.	2026-08-04 09:32:01.355927	t	babc7312-1c6f-4670-8297-351d392a1996	Lịch bảo trì MNT-20260804-060	MAINTENANCE	b1000000-0000-0000-0000-000000000002
a3d71af5-4bff-480e-8fbb-f149b56d67a4	Phiếu bảo trì Máy tính lỗi thời đã quá hạn SLA.	2026-08-04 12:43:17.940877	f	5bd48f3a-3600-45a2-a302-3698710235a2	Cảnh báo quá hạn SLA: MNT-20260804-109	MAINTENANCE	b1000000-0000-0000-0000-000000000001
62398ef2-9fcf-480f-b17e-146d43cbc46d	Phiếu bảo trì Máy tính lỗi thời đã quá hạn SLA.	2026-08-04 12:43:17.960685	f	797fc693-e426-43c8-be82-06e318cd6b46	Cảnh báo quá hạn SLA: MNT-20260804-108	MAINTENANCE	b1000000-0000-0000-0000-000000000001
69003362-c46c-45ee-aef3-d26a07419bd3	Phiếu bảo trì Máy tính lỗi thời đã quá hạn SLA.	2026-08-04 12:43:17.966919	f	919b3461-8baf-4669-b0fc-e66c998d0c38	Cảnh báo quá hạn SLA: MNT-20260804-107	MAINTENANCE	b1000000-0000-0000-0000-000000000001
f08cbae6-78f4-4b66-a0ad-05ee0b80b0bb	Phiếu bảo trì Máy tính lỗi thời đã quá hạn SLA.	2026-08-04 13:13:18.077035	f	c5e0255e-0794-408f-9677-5db981f2d32f	Cảnh báo quá hạn SLA: MNT-20260804-114	MAINTENANCE	b1000000-0000-0000-0000-000000000001
1286806f-5900-4750-92e1-05e2a70b581e	Phiếu bảo trì Vòi nước bị hỏng đã quá hạn SLA.	2026-08-04 15:13:18.20336	f	92b4e6ca-0abe-429e-8385-18666f89cd13	Cảnh báo quá hạn SLA: MNT-20260804-115	MAINTENANCE	b1000000-0000-0000-0000-000000000001
facbf5c2-50c7-4c9d-8b3c-ea90eeab5fdd	Mã phiếu: MNT-20260804-062 - Khách hàng: Nguyen Minh Anh	2026-08-04 17:08:23.616941	f	ee2e951d-6752-4790-8805-0a21dc2bf15a	Phân công bảo trì: 	MAINTENANCE	b1000000-0000-0000-0000-000000000009
053a1f70-1efd-4ba4-be2b-db18795fb3c8	Cư dân đã xác nhận lịch hẹn: Chiều mai (13:30 - 17:00)	2026-08-04 09:33:49.246554	t	babc7312-1c6f-4670-8297-351d392a1996	Phản hồi lịch hẹn MNT-20260804-060	MAINTENANCE	774a2c9e-8929-4d7c-80ca-14f62b9d9d56
87af5b6d-e69b-4926-a502-45f19915cc18	Mã phiếu: MNT-20260804-060 - Khách hàng: Nguyen Minh Anh	2026-08-04 09:30:53.567615	t	babc7312-1c6f-4670-8297-351d392a1996	Phân công bảo trì: cửa bị ket	MAINTENANCE	774a2c9e-8929-4d7c-80ca-14f62b9d9d56
9890428e-07de-489c-b196-a0c4b210cf32	Khách thuê phòng T3-12.08 chọn thanh toán tiền mặt cho hóa đơn 2026-08-01	2026-08-05 03:20:56.267184	f	7c135337-f51e-49fa-8731-3768446542f0	Yêu cầu thanh toán tiền mặt	INVOICE	b1000000-0000-0000-0000-000000000001
9bbf4b00-a87d-4fb5-9838-9b381149d26a	Thêm vật tư: Bản lề cửa x2 (70000 VNĐ)	2026-08-05 03:04:19.962023	t	babc7312-1c6f-4670-8297-351d392a1996	Ghi chú tiến độ MNT-20260804-060	MAINTENANCE	b1000000-0000-0000-0000-000000000002
05a4dcec-40e3-45f4-b9ef-5de03cb6b51a	Máy lạnh chảy nước - NORMAL	2026-08-05 03:27:49.158059	f	a4af8910-9741-45c9-81c7-a5fc5c5b6407	New Maintenance Request MNT-20260805-062	MAINTENANCE	b1000000-0000-0000-0000-000000000001
0bea2557-1c87-4db6-be2d-517340c7f45f	Máy lạnh chảy nước - NORMAL	2026-08-05 03:27:57.068846	f	94595db1-e24a-4a26-a28e-4a1e73bb8814	New Maintenance Request MNT-20260805-063	MAINTENANCE	b1000000-0000-0000-0000-000000000001
be6cf686-a3b5-4541-aee0-71bb07ccd98c	Máy lạnh chảy nước - NORMAL	2026-08-05 03:28:17.016732	f	db9a9713-3331-441f-84c5-ea3e5abb1197	New Maintenance Request MNT-20260805-410	MAINTENANCE	b1000000-0000-0000-0000-000000000001
2ac3c68c-c2c7-46d0-8190-57a0fe42638f	Kỹ thuật viên đề xuất khung giờ: Chiều Thứ Năm (06/08) (13:30 - 17:00). Vui lòng xác nhận.	2026-08-05 03:29:32.108908	t	db9a9713-3331-441f-84c5-ea3e5abb1197	Lịch bảo trì MNT-20260805-410	MAINTENANCE	b1000000-0000-0000-0000-000000000005
5f082cb1-a218-40a6-b3e8-158433bf119e	Đề xuất/Xác nhận khung giờ làm việc: Chiều Thứ Năm (06/08) (13:30 - 17:00)	2026-08-05 03:29:32.10801	t	db9a9713-3331-441f-84c5-ea3e5abb1197	Ghi chú tiến độ MNT-20260805-410	MAINTENANCE	b1000000-0000-0000-0000-000000000005
82478989-e523-4193-bdf2-f6c87aa115ac	Phân công kỹ thuật viên: Nguyễn Đinh Gia Bảo	2026-08-05 03:29:12.314307	t	db9a9713-3331-441f-84c5-ea3e5abb1197	Ghi chú tiến độ MNT-20260805-410	MAINTENANCE	b1000000-0000-0000-0000-000000000005
fbb216e5-808c-40a5-8b3d-d7fe36d53451	Invoice for 2026-08 is ready	2026-08-04 07:27:40.214163	t	f04eb140-899d-4bdb-b58c-4e30e87784d0	New Invoice	INVOICE	b1000000-0000-0000-0000-000000000005
8a28fb87-b029-4a42-a20f-d67c87c146fc	Mã phiếu: MNT-20260805-410 - Khách hàng: Pham Thu Trang	2026-08-05 03:29:12.315141	t	db9a9713-3331-441f-84c5-ea3e5abb1197	Phân công bảo trì: Máy lạnh chảy nước	MAINTENANCE	774a2c9e-8929-4d7c-80ca-14f62b9d9d56
68e1371c-5a5b-4b35-8174-c9857102bccc	Cư dân đã xác nhận lịch hẹn: Chiều Thứ Năm (06/08) (13:30 - 17:00)	2026-08-05 03:29:51.30075	t	db9a9713-3331-441f-84c5-ea3e5abb1197	Phản hồi lịch hẹn MNT-20260805-410	MAINTENANCE	774a2c9e-8929-4d7c-80ca-14f62b9d9d56
380a702d-4928-470d-9e1e-1bd01d0d4e1f	Vệ sinh lại máy lạnh	2026-08-05 03:30:38.207502	t	db9a9713-3331-441f-84c5-ea3e5abb1197	Ghi chú tiến độ MNT-20260805-410	MAINTENANCE	b1000000-0000-0000-0000-000000000005
823f4865-7e27-4235-a545-294822b84e81	Thêm vật tư: ống thoát nước x1 (40000 VNĐ)	2026-08-05 03:30:24.107014	t	db9a9713-3331-441f-84c5-ea3e5abb1197	Ghi chú tiến độ MNT-20260805-410	MAINTENANCE	b1000000-0000-0000-0000-000000000005
75a05010-54d7-43bc-b0dd-a7c86159705d	Kỹ thuật viên bắt đầu xử lý công việc	2026-08-05 03:30:00.609978	t	db9a9713-3331-441f-84c5-ea3e5abb1197	Ghi chú tiến độ MNT-20260805-410	MAINTENANCE	b1000000-0000-0000-0000-000000000005
c2dd6de2-daa6-4aef-850f-fb16700fb4f0	Thêm vật tư: tiền công vệ sinh x1 (200000 VNĐ)	2026-08-05 03:31:33.572844	t	db9a9713-3331-441f-84c5-ea3e5abb1197	Ghi chú tiến độ MNT-20260805-410	MAINTENANCE	b1000000-0000-0000-0000-000000000005
8b6d9c2e-d849-4d4f-a811-36f0c2293278	Khách thuê phòng P6-25.02 chọn thanh toán tiền mặt cho hóa đơn 2026-08-01	2026-08-05 03:32:03.31555	f	f04eb140-899d-4bdb-b58c-4e30e87784d0	Yêu cầu thanh toán tiền mặt	INVOICE	b1000000-0000-0000-0000-000000000001
ed427c24-06be-45fc-bd94-dda996ab704a	Khách thuê phòng P6-25.02 chọn thanh toán tiền mặt cho hóa đơn 2026-08-01	2026-08-05 03:37:49.109854	f	f04eb140-899d-4bdb-b58c-4e30e87784d0	Yêu cầu thanh toán tiền mặt	INVOICE	b1000000-0000-0000-0000-000000000001
b7864812-b418-4c3e-9f3b-24b302ca3cad	Thêm vật tư: ống máy lạnh x1 (10000 VNĐ)	2026-08-05 03:40:42.618007	t	db9a9713-3331-441f-84c5-ea3e5abb1197	Ghi chú tiến độ MNT-20260805-410	MAINTENANCE	b1000000-0000-0000-0000-000000000005
821ab287-0290-4600-9a8a-4f8575c7933d	kỹ thuật viên lỡ làm mất ốc	2026-08-05 03:40:56.976647	t	db9a9713-3331-441f-84c5-ea3e5abb1197	Ghi chú tiến độ MNT-20260805-410	MAINTENANCE	b1000000-0000-0000-0000-000000000005
482ea9ac-029f-4a5c-8c3c-4db80b812537	Đèn nhà vệ sinh không lên - NORMAL	2026-08-05 03:54:09.606912	f	0f0f870b-8625-4306-84b4-61e3c78ae7e2	New Maintenance Request MNT-20260805-411	MAINTENANCE	b1000000-0000-0000-0000-000000000001
c52b4e07-de7f-42ef-93dc-0aa4222dede1	Đề xuất/Xác nhận khung giờ làm việc: Tối nay (18:00 - 20:30)	2026-08-05 03:55:11.409538	t	0f0f870b-8625-4306-84b4-61e3c78ae7e2	Ghi chú tiến độ MNT-20260805-411	MAINTENANCE	b1000000-0000-0000-0000-000000000005
ad93ed37-3d5f-4f20-8ee3-ee041caabb57	Kỹ thuật viên đề xuất khung giờ: Tối nay (18:00 - 20:30). Vui lòng xác nhận.	2026-08-05 03:55:11.415337	t	0f0f870b-8625-4306-84b4-61e3c78ae7e2	Lịch bảo trì MNT-20260805-411	MAINTENANCE	b1000000-0000-0000-0000-000000000005
b0fb06ae-cb40-4ae0-890d-4b5768f634ce	Kỹ thuật viên bắt đầu xử lý công việc	2026-08-05 03:55:23.011548	t	0f0f870b-8625-4306-84b4-61e3c78ae7e2	Ghi chú tiến độ MNT-20260805-411	MAINTENANCE	b1000000-0000-0000-0000-000000000005
0a71848b-297e-4c6b-b505-84c83f11ebaf	Thêm vật tư: dây điện x1 (20000 VNĐ)	2026-08-05 03:55:44.613935	t	0f0f870b-8625-4306-84b4-61e3c78ae7e2	Ghi chú tiến độ MNT-20260805-411	MAINTENANCE	b1000000-0000-0000-0000-000000000005
5b5c9f9f-a56b-479a-b946-f8bf4dbc3cb0	Phiếu bảo trì Máy tính lỗi thời đã vượt thời gian xử lý dự kiến.	2026-08-04 13:13:18.07733	t	c5e0255e-0794-408f-9677-5db981f2d32f	Khẩn cấp: Quá hạn SLA MNT-20260804-114	MAINTENANCE	7b70cfa6-d414-4165-b17c-dde2c4aea3ba
5c726f68-7a2d-4b40-b21d-efc01184aabe	Cư dân đã xác nhận lịch hẹn: Tối nay (18:00 - 20:30)	2026-08-05 03:55:18.248092	t	0f0f870b-8625-4306-84b4-61e3c78ae7e2	Phản hồi lịch hẹn MNT-20260805-411	MAINTENANCE	774a2c9e-8929-4d7c-80ca-14f62b9d9d56
ba0a7554-86a4-4c06-b457-5dcd71d586b8	Cư dân từ chối khung giờ: Tối nay (18:00 - 20:30)	2026-08-05 03:55:15.892433	t	0f0f870b-8625-4306-84b4-61e3c78ae7e2	Phản hồi lịch hẹn MNT-20260805-411	MAINTENANCE	774a2c9e-8929-4d7c-80ca-14f62b9d9d56
d3e08a81-ff8c-42fd-937c-a3770035acaf	Mã phiếu: MNT-20260805-411 - Khách hàng: Pham Thu Trang	2026-08-05 03:54:37.209445	t	0f0f870b-8625-4306-84b4-61e3c78ae7e2	Phân công bảo trì: Đèn nhà vệ sinh không lên	MAINTENANCE	774a2c9e-8929-4d7c-80ca-14f62b9d9d56
393f805d-a906-468e-bb5c-3282b4aefa9f	Phân công kỹ thuật viên: Nguyễn Đinh Gia Bảo	2026-08-05 03:54:37.014956	t	0f0f870b-8625-4306-84b4-61e3c78ae7e2	Ghi chú tiến độ MNT-20260805-411	MAINTENANCE	b1000000-0000-0000-0000-000000000005
dd80d18e-1da7-4329-a215-4b868f3310d6	dậy điện bị đứt	2026-08-05 03:56:04.272643	t	0f0f870b-8625-4306-84b4-61e3c78ae7e2	Ghi chú tiến độ MNT-20260805-411	MAINTENANCE	b1000000-0000-0000-0000-000000000005
16b9d34d-eace-4393-972d-a4a98dd6db64	lỡ làm rớt bóng đèn	2026-08-05 03:56:41.256983	t	0f0f870b-8625-4306-84b4-61e3c78ae7e2	Ghi chú tiến độ MNT-20260805-411	MAINTENANCE	b1000000-0000-0000-0000-000000000005
eb0d1176-c3c0-4da3-9966-b76363a3a19e	Thêm vật tư: bóng đèn x1 (10000 VNĐ)	2026-08-05 03:56:31.591181	t	0f0f870b-8625-4306-84b4-61e3c78ae7e2	Ghi chú tiến độ MNT-20260805-411	MAINTENANCE	b1000000-0000-0000-0000-000000000005
8efb21e8-b1bc-41b1-9898-c68896cd6e0c	Nước bị nghẽn - NORMAL	2026-08-05 03:57:59.725843	f	b7b0c13c-2dbe-4d08-b81c-032624bfe278	New Maintenance Request MNT-20260805-412	MAINTENANCE	b1000000-0000-0000-0000-000000000001
4b691afd-0d41-4237-9f2b-ea9162a26897	Phân công kỹ thuật viên: Kỹ thuật viên B	2026-08-05 03:59:38.110899	t	b7b0c13c-2dbe-4d08-b81c-032624bfe278	Ghi chú tiến độ MNT-20260805-412	MAINTENANCE	b1000000-0000-0000-0000-000000000005
c103d022-d4ed-4b92-a3b0-5a2ff57ab35a	Thêm vật tư: Công thông cống x1 (80000 VNĐ)	2026-08-05 04:00:56.993594	t	b7b0c13c-2dbe-4d08-b81c-032624bfe278	Ghi chú tiến độ MNT-20260805-412	MAINTENANCE	b1000000-0000-0000-0000-000000000005
c832f24c-3516-4cab-9399-e46937d5ab0f	Kỹ thuật viên bắt đầu xử lý công việc	2026-08-05 04:00:33.383868	t	b7b0c13c-2dbe-4d08-b81c-032624bfe278	Ghi chú tiến độ MNT-20260805-412	MAINTENANCE	b1000000-0000-0000-0000-000000000005
12136bbe-cbbd-46e2-9286-918e9e492dcd	Kỹ thuật viên đề xuất khung giờ: Sáng Thứ Năm (06/08) (8:00 - 11:30). Vui lòng xác nhận.	2026-08-05 03:59:59.712167	t	b7b0c13c-2dbe-4d08-b81c-032624bfe278	Lịch bảo trì MNT-20260805-412	MAINTENANCE	b1000000-0000-0000-0000-000000000005
f58f15e0-7cf5-48cc-9fde-a4653b9e0c02	Đề xuất/Xác nhận khung giờ làm việc: Sáng Thứ Năm (06/08) (8:00 - 11:30)	2026-08-05 03:59:59.708645	t	b7b0c13c-2dbe-4d08-b81c-032624bfe278	Ghi chú tiến độ MNT-20260805-412	MAINTENANCE	b1000000-0000-0000-0000-000000000005
976bdaba-c3e1-4426-8807-a2af50ac37ed	Điều hòa không mát - NORMAL	2026-08-05 04:04:22.234165	f	c5615cfe-4f1a-4a3f-86b1-3727c9a02d68	New Maintenance Request MNT-20260805-413	MAINTENANCE	b1000000-0000-0000-0000-000000000001
0fa8cdc1-76a2-428c-856f-fc591c9a43c9	Kỹ thuật viên đề xuất khung giờ: Sáng Thứ Năm (06/08) (8:00 - 11:30). Vui lòng xác nhận.	2026-08-05 04:06:06.87317	t	c5615cfe-4f1a-4a3f-86b1-3727c9a02d68	Lịch bảo trì MNT-20260805-413	MAINTENANCE	b1000000-0000-0000-0000-000000000005
1a7678ce-d4e4-47c8-889b-76c729ef47dd	Đề xuất/Xác nhận khung giờ làm việc: Sáng Thứ Năm (06/08) (8:00 - 11:30)	2026-08-05 04:06:06.869796	t	c5615cfe-4f1a-4a3f-86b1-3727c9a02d68	Ghi chú tiến độ MNT-20260805-413	MAINTENANCE	b1000000-0000-0000-0000-000000000005
c5802495-1095-47c1-885c-1cc0e38408ed	Phân công kỹ thuật viên: Kỹ thuật viên B	2026-08-05 04:05:59.574111	t	c5615cfe-4f1a-4a3f-86b1-3727c9a02d68	Ghi chú tiến độ MNT-20260805-413	MAINTENANCE	b1000000-0000-0000-0000-000000000005
c54f016b-0998-4510-bc96-fcfec6ab3386	Cư dân đã xác nhận lịch hẹn: Sáng Thứ Năm (06/08) (8:00 - 11:30)	2026-08-05 04:06:13.919344	t	c5615cfe-4f1a-4a3f-86b1-3727c9a02d68	Phản hồi lịch hẹn MNT-20260805-413	MAINTENANCE	a0000000-0000-0000-0000-000000000003
a0cfe4d4-09ac-4a74-81c5-c2e7554e3dbf	Mã phiếu: MNT-20260805-413 - Khách hàng: Pham Thu Trang	2026-08-05 04:05:59.610188	t	c5615cfe-4f1a-4a3f-86b1-3727c9a02d68	Phân công bảo trì: Điều hòa không mát	MAINTENANCE	a0000000-0000-0000-0000-000000000003
7ee571c3-3e9f-41a2-a0b8-001ce74a28a2	Cư dân đã xác nhận lịch hẹn: Sáng Thứ Năm (06/08) (8:00 - 11:30)	2026-08-05 04:00:27.382782	t	b7b0c13c-2dbe-4d08-b81c-032624bfe278	Phản hồi lịch hẹn MNT-20260805-412	MAINTENANCE	a0000000-0000-0000-0000-000000000003
2f89a744-baaa-4ca2-b759-430e216ddc47	Cư dân từ chối khung giờ: Sáng Thứ Năm (06/08) (8:00 - 11:30)	2026-08-05 04:00:06.524671	t	b7b0c13c-2dbe-4d08-b81c-032624bfe278	Phản hồi lịch hẹn MNT-20260805-412	MAINTENANCE	a0000000-0000-0000-0000-000000000003
09a55b42-aaac-4186-932a-db6be8e68bc4	Mã phiếu: MNT-20260805-412 - Khách hàng: Pham Thu Trang	2026-08-05 03:59:38.208114	t	b7b0c13c-2dbe-4d08-b81c-032624bfe278	Phân công bảo trì: Nước bị nghẽn	MAINTENANCE	a0000000-0000-0000-0000-000000000003
771e15e8-2cf5-4625-b410-1d0608143f24	Phiếu bảo trì Vòi nước bị hỏng đã vượt thời gian xử lý dự kiến.	2026-08-04 15:13:18.203558	t	92b4e6ca-0abe-429e-8385-18666f89cd13	Khẩn cấp: Quá hạn SLA MNT-20260804-115	MAINTENANCE	7b70cfa6-d414-4165-b17c-dde2c4aea3ba
327158d3-8343-4ebc-b3c3-8618f56080ad	Cư dân từ chối khung giờ: Sáng mai (8:00 - 11:30)	2026-08-04 09:01:54.705974	t	c5e0255e-0794-408f-9677-5db981f2d32f	Phản hồi lịch hẹn MNT-20260804-114	MAINTENANCE	7b70cfa6-d414-4165-b17c-dde2c4aea3ba
17e965dc-0a0c-46a5-9c82-02cc643e5894	Tủ bị hỏng - NORMAL	2026-08-05 04:21:26.416774	f	a2ff625f-70a4-461f-9b5d-9557291b7925	New Maintenance Request MNT-20260805-414	MAINTENANCE	b1000000-0000-0000-0000-000000000001
0f58de06-e2ed-45ba-80bf-37670d36f26f	Tủ bị hỏng - NORMAL	2026-08-05 04:21:34.112062	f	fa3f4f63-780d-420b-b0a4-a0e2742133dc	New Maintenance Request MNT-20260805-415	MAINTENANCE	b1000000-0000-0000-0000-000000000001
68a3cf2e-41f1-49b7-a4f7-829d4423235e	Tủ bị hỏng - NORMAL	2026-08-05 04:21:47.707429	f	6d80b26f-78f4-4e44-bed9-599026e0004c	New Maintenance Request MNT-20260805-416	MAINTENANCE	b1000000-0000-0000-0000-000000000001
00f1ada0-0b48-4686-a50b-a7eb4fe87131	Tủ bị hỏng - NORMAL	2026-08-05 04:22:10.283842	f	05c52caf-2ab3-4473-8fcd-170dc1849e0c	New Maintenance Request MNT-20260805-417	MAINTENANCE	b1000000-0000-0000-0000-000000000001
afa3f59e-2a36-4ee7-8127-33ce06e10867	Phân công kỹ thuật viên: Kỹ thuật viên B	2026-08-05 04:23:43.836534	f	05c52caf-2ab3-4473-8fcd-170dc1849e0c	Ghi chú tiến độ MNT-20260805-417	MAINTENANCE	b1000000-0000-0000-0000-000000000003
06bb86ef-1340-40d7-b281-7eedba06ae2f	Mã phiếu: MNT-20260805-417 - Khách hàng: Tran Gia Han	2026-08-05 04:23:43.838245	f	05c52caf-2ab3-4473-8fcd-170dc1849e0c	Phân công bảo trì: Tủ bị hỏng	MAINTENANCE	a0000000-0000-0000-0000-000000000003
4f6ee371-caa5-45a2-a691-1569f53875bd	Máy lạnh có vấn đề - NORMAL	2026-08-05 04:25:33.107817	f	60dab198-f686-47d1-9656-6b7314fbeae3	New Maintenance Request MNT-20260805-418	MAINTENANCE	b1000000-0000-0000-0000-000000000001
aeb2c238-b20f-4e7c-b015-a9a21bac3f79	Phân công kỹ thuật viên: Trần Bá Lãm	2026-08-05 04:30:30.109374	t	60dab198-f686-47d1-9656-6b7314fbeae3	Ghi chú tiến độ MNT-20260805-418	MAINTENANCE	b1000000-0000-0000-0000-000000000003
7c3f1295-0ed6-4bfe-bea5-5d035057cfa3	Hủy phiếu bảo trì. Lý do: đã được xủ lý	2026-08-05 04:24:12.740085	t	05c52caf-2ab3-4473-8fcd-170dc1849e0c	Ghi chú tiến độ MNT-20260805-417	MAINTENANCE	b1000000-0000-0000-0000-000000000003
924bd9ef-0c05-4dc7-9a61-ba273cca04ac	Phân công kỹ thuật viên: Trần Bá Lãm	2026-08-05 04:23:50.110868	t	05c52caf-2ab3-4473-8fcd-170dc1849e0c	Ghi chú tiến độ MNT-20260805-417	MAINTENANCE	b1000000-0000-0000-0000-000000000003
b27b3e43-e880-4767-8db1-9d5d458d1e16	Cập nhật thời gian SLA dự kiến: 2026-08-05T04:23	2026-08-05 04:23:21.810688	t	05c52caf-2ab3-4473-8fcd-170dc1849e0c	Ghi chú tiến độ MNT-20260805-417	MAINTENANCE	b1000000-0000-0000-0000-000000000003
46513d35-25e3-4553-a0c5-35f1da0684df	Lý do: đã được xủ lý	2026-08-05 04:24:12.741771	t	05c52caf-2ab3-4473-8fcd-170dc1849e0c	Phiếu bảo trì bị hủy: MNT-20260805-417	MAINTENANCE	7b70cfa6-d414-4165-b17c-dde2c4aea3ba
fe20b9dc-1cc5-413d-96ed-ef1d2fa3e6a1	Mã phiếu: MNT-20260805-417 - Khách hàng: Tran Gia Han	2026-08-05 04:23:50.112861	t	05c52caf-2ab3-4473-8fcd-170dc1849e0c	Phân công bảo trì: Tủ bị hỏng	MAINTENANCE	7b70cfa6-d414-4165-b17c-dde2c4aea3ba
c3c163f0-f8aa-40d6-8020-ba8533c777e5	Thêm vật tư: gas máy lạnh x1 (1500000 VNĐ)	2026-08-05 04:35:33.519686	t	60dab198-f686-47d1-9656-6b7314fbeae3	Ghi chú tiến độ MNT-20260805-418	MAINTENANCE	b1000000-0000-0000-0000-000000000003
6cdfab36-3303-4286-80a9-97ceb82785fe	Invoice for 2026-08 is ready	2026-08-05 04:10:51.606685	t	f3b06edb-008c-4358-b278-d76c46356885	New Invoice	INVOICE	3589890e-f56b-4dbc-84fc-12e319e1d750
48009519-a99b-49da-85ba-11478676640b	vệ sinh điều hòa	2026-08-05 04:07:17.247295	t	c5615cfe-4f1a-4a3f-86b1-3727c9a02d68	Ghi chú tiến độ MNT-20260805-413	MAINTENANCE	b1000000-0000-0000-0000-000000000005
f338be8a-a66f-40ef-96f9-02b4140411af	Thêm vật tư: tiền vệ sinh x1 (200000 VNĐ)	2026-08-05 04:07:11.278174	t	c5615cfe-4f1a-4a3f-86b1-3727c9a02d68	Ghi chú tiến độ MNT-20260805-413	MAINTENANCE	b1000000-0000-0000-0000-000000000005
d183e968-c352-4080-8456-1e2d8f9909ec	Kỹ thuật viên bắt đầu xử lý công việc	2026-08-05 04:06:46.260295	t	c5615cfe-4f1a-4a3f-86b1-3727c9a02d68	Ghi chú tiến độ MNT-20260805-413	MAINTENANCE	b1000000-0000-0000-0000-000000000005
224e3c05-251a-4781-901a-cc1b657eefa6	Invoice for 2026-08 is ready	2026-08-06 12:52:38.699538	f	88a58727-f640-496a-b1a3-80cfa3acda4d	New Invoice	INVOICE	b1000000-0000-0000-0000-000000000012
dd6f3dcf-36d9-4d74-a16a-6b67feddeed1	Invoice for 2026-08 is ready	2026-08-06 12:52:38.789859	f	37ed8c23-1291-4b04-9b8f-744c89b42b3c	New Invoice	INVOICE	b1000000-0000-0000-0000-000000000013
2cf5ebe5-f158-4ba6-82ba-a7ceaef96be2	Kỹ thuật viên bắt đầu xử lý công việc	2026-08-05 04:30:47.361866	t	60dab198-f686-47d1-9656-6b7314fbeae3	Ghi chú tiến độ MNT-20260805-418	MAINTENANCE	b1000000-0000-0000-0000-000000000003
571bc652-f0a3-4b86-8b8c-6ae6ae8fc656	Mã phiếu: MNT-20260805-418 - Khách hàng: Tran Gia Han	2026-08-05 04:30:30.112777	t	60dab198-f686-47d1-9656-6b7314fbeae3	Phân công bảo trì: Máy lạnh có vấn đề	MAINTENANCE	7b70cfa6-d414-4165-b17c-dde2c4aea3ba
29915c3b-3e50-42f6-9956-73b7376b7019	Xóa vật tư: gas máy lạnh	2026-08-05 04:35:35.717813	t	60dab198-f686-47d1-9656-6b7314fbeae3	Ghi chú tiến độ MNT-20260805-418	MAINTENANCE	b1000000-0000-0000-0000-000000000003
238a30cd-9a4e-49b5-900c-3a5a97d6cbbd	đã mua dụng cụ	2026-08-05 04:36:12.444621	t	60dab198-f686-47d1-9656-6b7314fbeae3	Ghi chú tiến độ MNT-20260805-418	MAINTENANCE	b1000000-0000-0000-0000-000000000003
045fd9f2-0f2e-40d6-8350-c17fad93946b	Thêm vật tư: gas máy lạnh x1 (150000 VNĐ)	2026-08-05 04:35:45.889332	t	60dab198-f686-47d1-9656-6b7314fbeae3	Ghi chú tiến độ MNT-20260805-418	MAINTENANCE	b1000000-0000-0000-0000-000000000003
7e411379-29ea-405e-9a6d-c68fc1d39318	Invoice for 2026-08 is ready	2026-08-05 05:46:18.714574	f	f1b6bd6a-59bf-442c-92f9-1a90b2ab8a31	New Invoice	INVOICE	a0000000-0000-0000-0000-000000000002
f2949853-8804-424e-8ef5-2e273399b743	Khách thuê phòng 001 chọn thanh toán tiền mặt cho hóa đơn 2026-08-01	2026-08-05 05:54:31.221972	f	f1b6bd6a-59bf-442c-92f9-1a90b2ab8a31	Yêu cầu thanh toán tiền mặt	INVOICE	c5d65edf-fb24-4f93-b966-362f36e78370
03215eb5-2380-47fd-ad4a-1565893163a1	Invoice for 2026-08 is ready	2026-08-05 06:01:41.006969	f	95fa58e3-2f13-410b-80c7-159fec6186f9	New Invoice	INVOICE	74ccd53e-4998-49a3-97e3-b918b60f4080
11f0d512-e286-4165-a470-dc5c71d03167	Phân công kỹ thuật viên: Vo Tuan Kiet	2026-08-05 06:22:18.311137	f	483e9cdc-246b-48a5-9a8f-2327910f2b03	Ghi chú tiến độ MNT-20260805-420	MAINTENANCE	74ccd53e-4998-49a3-97e3-b918b60f4080
c35aa9ab-3a77-4fe6-83ac-c4e195220f89	Mã phiếu: MNT-20260805-420 - Khách hàng: Nguyễn Thị Mai Nga	2026-08-05 06:22:18.408078	f	483e9cdc-246b-48a5-9a8f-2327910f2b03	Phân công bảo trì: Bản lề cửa bị hỏng	MAINTENANCE	b1000000-0000-0000-0000-000000000008
a1259075-7c5a-4916-95df-87d10e571553	Hủy phiếu bảo trì. Lý do: Báo cáo bảo trì bị trùng lập	2026-08-05 06:22:45.910157	f	10ce7228-811a-4908-a24a-6061f278cc7b	Ghi chú tiến độ MNT-20260805-419	MAINTENANCE	74ccd53e-4998-49a3-97e3-b918b60f4080
aaed81c0-48ef-4055-9f26-9c218bb6a67c	Bản lề cửa bị hỏng - HIGH	2026-08-05 06:03:17.020767	t	10ce7228-811a-4908-a24a-6061f278cc7b	New Maintenance Request MNT-20260805-419	MAINTENANCE	c5d65edf-fb24-4f93-b966-362f36e78370
d1cf561d-8ae1-47d8-9254-2125ce52ad3d	Kỹ thuật viên bắt đầu xử lý công việc	2026-08-05 06:26:30.112419	f	483e9cdc-246b-48a5-9a8f-2327910f2b03	Ghi chú tiến độ MNT-20260805-420	MAINTENANCE	74ccd53e-4998-49a3-97e3-b918b60f4080
2cb04ceb-5ff3-4664-bfc8-905786a08c70	Thêm vật tư: Bản lề nhà vệ sinh x1 (0 VNĐ)	2026-08-05 06:26:47.712858	f	483e9cdc-246b-48a5-9a8f-2327910f2b03	Ghi chú tiến độ MNT-20260805-420	MAINTENANCE	74ccd53e-4998-49a3-97e3-b918b60f4080
12d748de-dfbe-43da-bbb7-b88ad835df33	Đang chuẩn bị vật tư để sửa chửa	2026-08-05 06:27:15.776762	f	483e9cdc-246b-48a5-9a8f-2327910f2b03	Ghi chú tiến độ MNT-20260805-420	MAINTENANCE	74ccd53e-4998-49a3-97e3-b918b60f4080
36e974b7-2785-4f67-b214-d2e9bc696b06	Phân công kỹ thuật viên: Vo Tuan Kiet	2026-08-05 06:30:26.009349	f	2f6bcc81-68a7-46e1-b7b8-f98bf267fe53	Ghi chú tiến độ MNT-20260805-421	MAINTENANCE	74ccd53e-4998-49a3-97e3-b918b60f4080
8edd4ae0-d47f-49ab-b72c-48e8c5e5b737	Mã phiếu: MNT-20260805-421 - Khách hàng: Nguyễn Thị Mai Nga	2026-08-05 06:30:26.010279	f	2f6bcc81-68a7-46e1-b7b8-f98bf267fe53	Phân công bảo trì: Điều hòa bị chảy nước	MAINTENANCE	b1000000-0000-0000-0000-000000000008
1358c027-5306-45d5-9ff4-2970132566d9	Kỹ thuật viên đề xuất khung giờ: Sáng Thứ Năm (06/08) (8:00 - 11:30). Vui lòng xác nhận.	2026-08-05 06:29:03.817065	t	b8000000-0000-0000-0000-000000000001	Lịch bảo trì MNT-20260629-001	MAINTENANCE	b1000000-0000-0000-0000-000000000003
09a2b857-5a43-42fb-b840-806f6f69be20	Đề xuất/Xác nhận khung giờ làm việc: Sáng Thứ Năm (06/08) (8:00 - 11:30)	2026-08-05 06:29:03.814736	t	b8000000-0000-0000-0000-000000000001	Ghi chú tiến độ MNT-20260629-001	MAINTENANCE	b1000000-0000-0000-0000-000000000003
463654ca-ee1a-4019-a2cb-9d96f01c478e	Kỹ thuật viên bắt đầu xử lý công việc	2026-08-05 07:25:27.271092	f	c5e0255e-0794-408f-9677-5db981f2d32f	Ghi chú tiến độ MNT-20260804-114	MAINTENANCE	b1000000-0000-0000-0000-000000000003
1a1ab0ba-2fae-498c-9414-63ee9e35b006	Khách thuê phòng 0002 chọn thanh toán tiền mặt cho hóa đơn 2026-08-01	2026-08-05 04:42:20.804871	t	f3b06edb-008c-4358-b278-d76c46356885	Yêu cầu thanh toán tiền mặt	INVOICE	a0000000-0000-0000-0000-000000000001
32b76f7a-4719-4a01-9867-880f5a597b38	Invoice for 2026-08 is ready	2026-08-05 07:47:48.662091	f	afbd9554-aa7c-40e1-81ed-6fd768b31b9f	New Invoice	INVOICE	b1000000-0000-0000-0000-000000000019
f06381e8-4932-4d7a-a782-979adf7c69bb	Invoice for 2026-08 is ready	2026-08-05 07:49:01.2289	f	f79fb673-1ab6-481f-b2f7-addfcb634def	New Invoice	INVOICE	b1000000-0000-0000-0000-000000000018
a58d54ee-dce8-4d67-9b4d-c273be210796	Phiếu bảo trì cửa bị ket đã quá hạn SLA.	2026-08-05 09:28:09.836134	f	babc7312-1c6f-4670-8297-351d392a1996	Cảnh báo quá hạn SLA: MNT-20260804-060	MAINTENANCE	b1000000-0000-0000-0000-000000000001
95b58436-2a08-48dd-8ea8-b55761ad9b55	Phiếu bảo trì cửa bị ket đã quá hạn SLA.	2026-08-05 09:28:09.846067	f	e56e460b-511b-48af-b2ac-3d8e93a464cc	Cảnh báo quá hạn SLA: MNT-20260804-057	MAINTENANCE	b1000000-0000-0000-0000-000000000001
54e819c4-2798-4c32-a1d0-126265789c0b	Phiếu bảo trì cửa bị ket đã quá hạn SLA.	2026-08-05 09:28:09.909621	f	3ea22299-cbb4-4730-9ae1-aac56cf897b0	Cảnh báo quá hạn SLA: MNT-20260804-058	MAINTENANCE	b1000000-0000-0000-0000-000000000001
65dade99-ddd5-466e-9014-1638545e8f8d	Phiếu bảo trì cửa bị ket đã quá hạn SLA.	2026-08-05 09:28:09.919857	f	10929fc8-6e84-4107-af9f-50d2aa7fc9c5	Cảnh báo quá hạn SLA: MNT-20260804-059	MAINTENANCE	b1000000-0000-0000-0000-000000000001
a7ce2923-720d-4c02-8b9e-2c018db85894	Phiếu bảo trì cửa bị ket đã quá hạn SLA.	2026-08-05 09:58:10.342907	f	791b3bc7-973e-4ce9-b0f8-2c2bed1383d5	Cảnh báo quá hạn SLA: MNT-20260804-061	MAINTENANCE	b1000000-0000-0000-0000-000000000001
071296b0-7d92-4811-a124-24d16201be87	Phiếu bảo trì cửa bị ket đã vượt thời gian xử lý dự kiến.	2026-08-05 09:28:09.836346	t	babc7312-1c6f-4670-8297-351d392a1996	Khẩn cấp: Quá hạn SLA MNT-20260804-060	MAINTENANCE	774a2c9e-8929-4d7c-80ca-14f62b9d9d56
fe2225b6-e185-40a8-a83f-d3817db41938	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-05T09:29:09.765027)	2026-08-05 09:58:10.350278	t	ee2e951d-6752-4790-8805-0a21dc2bf15a	Ghi chú tiến độ MNT-20260804-062	MAINTENANCE	b1000000-0000-0000-0000-000000000002
2d212af5-27e4-4d00-8258-47959503e4b4	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-05T09:28:52.860010)	2026-08-05 09:58:10.342638	t	791b3bc7-973e-4ce9-b0f8-2c2bed1383d5	Ghi chú tiến độ MNT-20260804-061	MAINTENANCE	b1000000-0000-0000-0000-000000000002
40315368-a208-4a3f-9431-9226034c33b9	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-05T09:23:01.866682)	2026-08-05 09:28:09.919743	t	10929fc8-6e84-4107-af9f-50d2aa7fc9c5	Ghi chú tiến độ MNT-20260804-059	MAINTENANCE	b1000000-0000-0000-0000-000000000002
ebfdb530-a604-4b65-9ce7-9e06e67d26a5	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-05T09:22:57.102237)	2026-08-05 09:28:09.909507	t	3ea22299-cbb4-4730-9ae1-aac56cf897b0	Ghi chú tiến độ MNT-20260804-058	MAINTENANCE	b1000000-0000-0000-0000-000000000002
6d3325e5-cfef-4d8a-a40a-6f7289e70e95	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-05T09:22:52.373173)	2026-08-05 09:28:09.845984	t	e56e460b-511b-48af-b2ac-3d8e93a464cc	Ghi chú tiến độ MNT-20260804-057	MAINTENANCE	b1000000-0000-0000-0000-000000000002
fbee863c-900c-4e33-ac2d-b032a8132d29	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-05T09:23:08.663177)	2026-08-05 09:28:09.835889	t	babc7312-1c6f-4670-8297-351d392a1996	Ghi chú tiến độ MNT-20260804-060	MAINTENANCE	b1000000-0000-0000-0000-000000000002
0e17f66b-3cb7-4175-b8bd-c87674878855	Invoice for 2026-08 is ready	2026-08-06 12:52:38.892326	f	71299135-fa55-482a-9679-bbb4dd57ad17	New Invoice	INVOICE	b1000000-0000-0000-0000-000000000015
7baa7b28-b8ce-4687-9e1a-a875a627279c	Invoice for 2026-08 is ready	2026-08-06 12:52:38.927691	f	c2170b99-cd9f-430c-ba4e-a8e51293fd6e	New Invoice	INVOICE	b1000000-0000-0000-0000-000000000017
7250c84e-40d3-4bd3-8ecc-9d64e0bcfe63	Invoice for 2026-08 is ready	2026-08-06 12:52:39.09872	f	1f86bcfd-5c7b-480c-9388-d9e9f53abb33	New Invoice	INVOICE	b1000000-0000-0000-0000-000000000020
1383a10d-1c39-4539-9670-285e32ff6837	Invoice for 2026-08 is ready	2026-08-06 12:52:39.428554	f	eaee2c21-c729-4dc2-8f61-539fd6721831	New Invoice	INVOICE	b1000000-0000-0000-0000-000000000003
1f91599c-f6eb-4404-ac1f-6e11d0f69806	Invoice for 2026-08 is ready	2026-08-06 12:52:39.399549	t	43a1debd-e6d3-4752-ad27-a68df77cfe0f	New Invoice	INVOICE	b1000000-0000-0000-0000-000000000004
8a8f38b2-3f18-4c60-a52c-c1d66053c2b0	Điều hòa bị chảy nước - HIGH	2026-08-05 06:30:07.067038	t	2f6bcc81-68a7-46e1-b7b8-f98bf267fe53	New Maintenance Request MNT-20260805-421	MAINTENANCE	c5d65edf-fb24-4f93-b966-362f36e78370
c32782c6-01b5-4e1e-8d27-e6ca5f30b2c8	Khách thuê phòng 002 chọn thanh toán tiền mặt cho hóa đơn 2026-08-01	2026-08-05 06:09:30.131507	t	95fa58e3-2f13-410b-80c7-159fec6186f9	Yêu cầu thanh toán tiền mặt	INVOICE	c5d65edf-fb24-4f93-b966-362f36e78370
d5d82102-8532-4b2b-8561-01007b1b486a	Bản lề cửa bị hỏng - HIGH	2026-08-05 06:03:31.307623	t	483e9cdc-246b-48a5-9a8f-2327910f2b03	New Maintenance Request MNT-20260805-420	MAINTENANCE	c5d65edf-fb24-4f93-b966-362f36e78370
6c7c5b54-428f-493f-a25f-9e2bdfcc2b6c	Your invoice for 2026-08-01 is overdue	2026-08-11 08:00:00.084171	f	afbd9554-aa7c-40e1-81ed-6fd768b31b9f	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000019
422caebc-bb7a-496f-96aa-f309ea8d6625	Your invoice for 2026-08-01 is overdue	2026-08-11 08:00:00.087138	f	f79fb673-1ab6-481f-b2f7-addfcb634def	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000018
8d516c0f-5b38-4d08-bba9-75988269dd1f	Phiếu bảo trì  đã quá hạn SLA.	2026-08-05 09:58:10.350575	f	ee2e951d-6752-4790-8805-0a21dc2bf15a	Cảnh báo quá hạn SLA: MNT-20260804-062	MAINTENANCE	b1000000-0000-0000-0000-000000000001
4993ea8f-3747-49c3-92a9-382c186a8eea	Phiếu bảo trì  đã vượt thời gian xử lý dự kiến.	2026-08-05 09:58:10.350727	f	ee2e951d-6752-4790-8805-0a21dc2bf15a	Khẩn cấp: Quá hạn SLA MNT-20260804-062	MAINTENANCE	b1000000-0000-0000-0000-000000000009
2bd78df4-6a2f-4562-9ba9-1c1403248403	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-05T14:03:31.306291)	2026-08-05 14:28:11.635005	f	483e9cdc-246b-48a5-9a8f-2327910f2b03	Ghi chú tiến độ MNT-20260805-420	MAINTENANCE	74ccd53e-4998-49a3-97e3-b918b60f4080
9afb2dde-2753-4875-a34a-02d2b8aa412a	Phiếu bảo trì Bản lề cửa bị hỏng đã vượt thời gian xử lý dự kiến.	2026-08-05 14:28:11.638647	f	483e9cdc-246b-48a5-9a8f-2327910f2b03	Khẩn cấp: Quá hạn SLA MNT-20260805-420	MAINTENANCE	b1000000-0000-0000-0000-000000000008
7fe326b7-55d8-4a99-9d9a-8e246ec20692	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-05T18:30:07.066047)	2026-08-05 18:58:14.908985	f	2f6bcc81-68a7-46e1-b7b8-f98bf267fe53	Ghi chú tiến độ MNT-20260805-421	MAINTENANCE	74ccd53e-4998-49a3-97e3-b918b60f4080
362e7f7d-3c6a-43da-82d3-6ac039be1a36	Phiếu bảo trì Điều hòa bị chảy nước đã vượt thời gian xử lý dự kiến.	2026-08-05 18:58:15.20936	f	2f6bcc81-68a7-46e1-b7b8-f98bf267fe53	Khẩn cấp: Quá hạn SLA MNT-20260805-421	MAINTENANCE	b1000000-0000-0000-0000-000000000008
96d3c6a2-6a5a-4a8c-abb9-f0f453e0d0ec	Phiếu bảo trì Máy lạnh chảy nước đã quá hạn SLA.	2026-08-06 03:28:16.207787	f	a4af8910-9741-45c9-81c7-a5fc5c5b6407	Cảnh báo quá hạn SLA: MNT-20260805-062	MAINTENANCE	b1000000-0000-0000-0000-000000000001
bcc1186a-f5df-43aa-95fa-499148d3e48c	Phiếu bảo trì Máy lạnh chảy nước đã quá hạn SLA.	2026-08-06 03:28:18.30857	f	94595db1-e24a-4a26-a28e-4a1e73bb8814	Cảnh báo quá hạn SLA: MNT-20260805-063	MAINTENANCE	b1000000-0000-0000-0000-000000000001
48584288-ae5a-4d46-aab5-c1c173af4e1f	Phiếu bảo trì Máy lạnh chảy nước đã quá hạn SLA.	2026-08-06 03:58:20.241609	f	db9a9713-3331-441f-84c5-ea3e5abb1197	Cảnh báo quá hạn SLA: MNT-20260805-410	MAINTENANCE	b1000000-0000-0000-0000-000000000001
f79ed963-1ec5-4d7b-8ca3-6eb94b27c7f0	Phiếu bảo trì Nước bị nghẽn đã quá hạn SLA.	2026-08-06 03:58:22.409465	f	b7b0c13c-2dbe-4d08-b81c-032624bfe278	Cảnh báo quá hạn SLA: MNT-20260805-412	MAINTENANCE	b1000000-0000-0000-0000-000000000001
e83244df-07e4-4100-bbca-41b8d3d2792d	Phiếu bảo trì Nước bị nghẽn đã vượt thời gian xử lý dự kiến.	2026-08-06 03:58:22.410192	f	b7b0c13c-2dbe-4d08-b81c-032624bfe278	Khẩn cấp: Quá hạn SLA MNT-20260805-412	MAINTENANCE	a0000000-0000-0000-0000-000000000003
8b26adfd-5666-4ebb-bf82-0ed3ee636cfb	Phiếu bảo trì Đèn nhà vệ sinh không lên đã quá hạn SLA.	2026-08-06 03:58:22.511302	f	0f0f870b-8625-4306-84b4-61e3c78ae7e2	Cảnh báo quá hạn SLA: MNT-20260805-411	MAINTENANCE	b1000000-0000-0000-0000-000000000001
24be6c28-bf94-49cc-9cb8-e3c3dc734c42	Phiếu bảo trì Điều hòa không mát đã quá hạn SLA.	2026-08-06 04:28:23.206072	f	c5615cfe-4f1a-4a3f-86b1-3727c9a02d68	Cảnh báo quá hạn SLA: MNT-20260805-413	MAINTENANCE	b1000000-0000-0000-0000-000000000001
73a51c3e-312e-4007-965b-0c0735e65955	Phiếu bảo trì Điều hòa không mát đã vượt thời gian xử lý dự kiến.	2026-08-06 04:28:23.20632	f	c5615cfe-4f1a-4a3f-86b1-3727c9a02d68	Khẩn cấp: Quá hạn SLA MNT-20260805-413	MAINTENANCE	a0000000-0000-0000-0000-000000000003
b08a0471-c96d-44da-8e81-4e81456c43af	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-06T04:21:34.111135)	2026-08-06 04:28:23.221418	f	fa3f4f63-780d-420b-b0a4-a0e2742133dc	Ghi chú tiến độ MNT-20260805-415	MAINTENANCE	b1000000-0000-0000-0000-000000000003
70d2277a-fdeb-4ee4-aa8b-ef23d46d7392	Phiếu bảo trì Tủ bị hỏng đã quá hạn SLA.	2026-08-06 04:28:23.221802	f	fa3f4f63-780d-420b-b0a4-a0e2742133dc	Cảnh báo quá hạn SLA: MNT-20260805-415	MAINTENANCE	b1000000-0000-0000-0000-000000000001
bf485e8e-e61f-4991-926e-3af7e4bde158	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-06T04:21:26.415556)	2026-08-06 04:28:23.310953	f	a2ff625f-70a4-461f-9b5d-9557291b7925	Ghi chú tiến độ MNT-20260805-414	MAINTENANCE	b1000000-0000-0000-0000-000000000003
e78cd471-ce44-448c-bbf3-2638cd4e0611	Phiếu bảo trì Tủ bị hỏng đã quá hạn SLA.	2026-08-06 04:28:23.31197	f	a2ff625f-70a4-461f-9b5d-9557291b7925	Cảnh báo quá hạn SLA: MNT-20260805-414	MAINTENANCE	b1000000-0000-0000-0000-000000000001
1c9b59a9-0c51-4620-977e-074449387804	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-06T04:21:47.706162)	2026-08-06 04:28:23.318001	f	6d80b26f-78f4-4e44-bed9-599026e0004c	Ghi chú tiến độ MNT-20260805-416	MAINTENANCE	b1000000-0000-0000-0000-000000000003
eff0040a-fb46-43f4-93a5-a251cf583908	Phiếu bảo trì Tủ bị hỏng đã quá hạn SLA.	2026-08-06 04:28:23.318062	f	6d80b26f-78f4-4e44-bed9-599026e0004c	Cảnh báo quá hạn SLA: MNT-20260805-416	MAINTENANCE	b1000000-0000-0000-0000-000000000001
0e084291-4c5d-41ee-b545-140e823d1a70	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-06T04:25:33.106151)	2026-08-06 04:28:23.506391	f	60dab198-f686-47d1-9656-6b7314fbeae3	Ghi chú tiến độ MNT-20260805-418	MAINTENANCE	b1000000-0000-0000-0000-000000000003
67c79a76-adf4-460a-aac2-9ee5a12e82ea	Phiếu bảo trì Máy lạnh có vấn đề đã quá hạn SLA.	2026-08-06 04:28:23.506618	f	60dab198-f686-47d1-9656-6b7314fbeae3	Cảnh báo quá hạn SLA: MNT-20260805-418	MAINTENANCE	b1000000-0000-0000-0000-000000000001
8d32b230-b6ad-4d15-bc6d-9501e500eb93	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-06T04:04:22.233171)	2026-08-06 04:28:23.110033	t	c5615cfe-4f1a-4a3f-86b1-3727c9a02d68	Ghi chú tiến độ MNT-20260805-413	MAINTENANCE	b1000000-0000-0000-0000-000000000005
af6ee173-d0b4-4c33-ae31-2916d89522bd	Phiếu bảo trì Đèn nhà vệ sinh không lên đã vượt thời gian xử lý dự kiến.	2026-08-06 03:58:22.512445	t	0f0f870b-8625-4306-84b4-61e3c78ae7e2	Khẩn cấp: Quá hạn SLA MNT-20260805-411	MAINTENANCE	774a2c9e-8929-4d7c-80ca-14f62b9d9d56
6e3192d7-f9e8-4287-9493-96e135f664c6	Phiếu bảo trì Máy lạnh chảy nước đã vượt thời gian xử lý dự kiến.	2026-08-06 03:58:20.241674	t	db9a9713-3331-441f-84c5-ea3e5abb1197	Khẩn cấp: Quá hạn SLA MNT-20260805-410	MAINTENANCE	774a2c9e-8929-4d7c-80ca-14f62b9d9d56
e8d24cc1-a103-41d3-b7ba-51d1e2af0f88	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-06T03:54:09.578814)	2026-08-06 03:58:22.511089	t	0f0f870b-8625-4306-84b4-61e3c78ae7e2	Ghi chú tiến độ MNT-20260805-411	MAINTENANCE	b1000000-0000-0000-0000-000000000005
95334331-451b-4201-a018-a5aa386acde9	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-06T03:57:59.724699)	2026-08-06 03:58:22.408913	t	b7b0c13c-2dbe-4d08-b81c-032624bfe278	Ghi chú tiến độ MNT-20260805-412	MAINTENANCE	b1000000-0000-0000-0000-000000000005
29394940-ff1d-444e-8ab2-475f3b539ec8	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-06T03:28:16.212575)	2026-08-06 03:58:20.241439	t	db9a9713-3331-441f-84c5-ea3e5abb1197	Ghi chú tiến độ MNT-20260805-410	MAINTENANCE	b1000000-0000-0000-0000-000000000005
c8be609e-6dca-484e-8b4b-84634b3e6cfa	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-06T03:27:57.067795)	2026-08-06 03:28:16.316891	t	94595db1-e24a-4a26-a28e-4a1e73bb8814	Ghi chú tiến độ MNT-20260805-063	MAINTENANCE	b1000000-0000-0000-0000-000000000005
9f33d8a4-a419-4388-b7a7-2aa416dc2a1a	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-06T03:27:49.060782)	2026-08-06 03:28:16.107769	t	a4af8910-9741-45c9-81c7-a5fc5c5b6407	Ghi chú tiến độ MNT-20260805-062	MAINTENANCE	b1000000-0000-0000-0000-000000000005
74f59379-008b-489b-8f57-8037feb9a2b7	Khách thuê phòng P6-25.02 chọn thanh toán tiền mặt cho hóa đơn 2026-08-01	2026-08-06 12:35:55.391844	f	f04eb140-899d-4bdb-b58c-4e30e87784d0	Yêu cầu thanh toán tiền mặt	INVOICE	b1000000-0000-0000-0000-000000000001
3ab7ac99-1f5d-42e8-8f5c-df1667b4e54d	Invoice for 2026-08 is ready	2026-08-06 12:52:38.595148	f	900306d5-a430-49bf-b5c5-d7a3161cad4b	New Invoice	INVOICE	b1000000-0000-0000-0000-000000000010
c85c3a94-b019-49cb-8343-7b0e30260a1b	Invoice for 2026-08 is ready	2026-08-06 12:52:38.623208	f	fa0879db-1e12-41ee-8fff-f293de4189ef	New Invoice	INVOICE	b1000000-0000-0000-0000-000000000011
f645111b-c0e7-4fe1-af55-7ab44204bb92	Phiếu bảo trì Bản lề cửa bị hỏng đã quá hạn SLA.	2026-08-05 14:28:11.637879	t	483e9cdc-246b-48a5-9a8f-2327910f2b03	Cảnh báo quá hạn SLA: MNT-20260805-420	MAINTENANCE	c5d65edf-fb24-4f93-b966-362f36e78370
a3cb15a9-facb-4c6d-b513-fbe3a74fec86	Phiếu bảo trì Máy lạnh có vấn đề đã vượt thời gian xử lý dự kiến.	2026-08-06 04:28:23.506693	t	60dab198-f686-47d1-9656-6b7314fbeae3	Khẩn cấp: Quá hạn SLA MNT-20260805-418	MAINTENANCE	7b70cfa6-d414-4165-b17c-dde2c4aea3ba
8053b947-e544-4733-9ff7-157b3f4feefc	Khách thuê phòng T3-12.08 chọn thanh toán tiền mặt cho hóa đơn 2026-08-01	2026-08-06 13:14:01.859523	f	7c135337-f51e-49fa-8731-3768446542f0	Yêu cầu thanh toán tiền mặt	INVOICE	b1000000-0000-0000-0000-000000000001
a6ce6e52-6737-4a0a-9e9f-7ef166331993	Khách thuê phòng T3-12.08 chọn thanh toán tiền mặt cho hóa đơn 2026-08-01	2026-08-06 13:18:44.878945	f	7c135337-f51e-49fa-8731-3768446542f0	Yêu cầu thanh toán tiền mặt	INVOICE	b1000000-0000-0000-0000-000000000001
1105acbe-3fc1-4ba6-a9ae-c33b4095aa17	Khách thuê phòng T3-12.08 chọn thanh toán tiền mặt cho hóa đơn 2026-08-01	2026-08-06 13:18:48.069263	f	7c135337-f51e-49fa-8731-3768446542f0	Yêu cầu thanh toán tiền mặt	INVOICE	b1000000-0000-0000-0000-000000000001
16ab2de5-df8a-4b0b-8cbb-3909cea1bc83	Khách thuê phòng P6-18.05 chọn thanh toán tiền mặt cho hóa đơn 2026-08-01	2026-08-06 13:22:13.005562	f	cc0cd89c-886d-476e-a9f2-6a4a2649bb01	Yêu cầu thanh toán tiền mặt	INVOICE	b1000000-0000-0000-0000-000000000001
3ee0852a-cd75-429e-9f3c-0ffc8bc1dfcd	Khách thuê phòng P6-18.05 chọn thanh toán tiền mặt cho hóa đơn 2026-08-01	2026-08-06 13:22:47.725683	f	cc0cd89c-886d-476e-a9f2-6a4a2649bb01	Yêu cầu thanh toán tiền mặt	INVOICE	b1000000-0000-0000-0000-000000000001
d704c622-0b62-491b-bf4d-1492a63d70c5	Khách thuê phòng P6-18.05 chọn thanh toán tiền mặt cho hóa đơn 2026-08-01	2026-08-06 13:22:53.546824	f	cc0cd89c-886d-476e-a9f2-6a4a2649bb01	Yêu cầu thanh toán tiền mặt	INVOICE	b1000000-0000-0000-0000-000000000001
96a3ffd6-f226-4271-a181-5a50edb51345	Đề xuất/Xác nhận khung giờ làm việc: Sáng Thứ Sáu (07/08) (8:00 - 11:30)	2026-08-06 15:07:10.566355	f	2f6bcc81-68a7-46e1-b7b8-f98bf267fe53	Ghi chú tiến độ MNT-20260805-421	MAINTENANCE	74ccd53e-4998-49a3-97e3-b918b60f4080
237691c3-dad4-40f2-9686-0bed81fd880b	Kỹ thuật viên đề xuất khung giờ: Sáng Thứ Sáu (07/08) (8:00 - 11:30). Vui lòng xác nhận.	2026-08-06 15:07:10.567439	f	2f6bcc81-68a7-46e1-b7b8-f98bf267fe53	Lịch bảo trì MNT-20260805-421	MAINTENANCE	74ccd53e-4998-49a3-97e3-b918b60f4080
18613558-d380-4fcb-a90c-f4e5a3d1d836	Invoice for 2026-08 is ready	2026-08-06 15:11:09.194267	f	c979cd05-f5aa-4903-8f9d-29e3e743ee51	New Invoice	INVOICE	33712636-202b-4ff3-8011-2da710d65035
9ebcce28-e037-4ae1-859b-05932969a183	Invoice for 2026-08 is ready	2026-08-06 15:16:58.244971	f	90778511-703a-4e87-be04-1223be4918c2	New Invoice	INVOICE	33712636-202b-4ff3-8011-2da710d65035
96756cd4-232d-4804-b22c-45b63a65e719	Phân công kỹ thuật viên: Vo Tuan Kiet	2026-08-06 15:22:18.69192	f	229d8e58-ffbe-44d4-8909-3e92985cfe8c	Ghi chú tiến độ MNT-20260806-491	MAINTENANCE	33712636-202b-4ff3-8011-2da710d65035
37c585dc-ff53-4a12-9bc9-9a34a9c0e966	Mã phiếu: MNT-20260806-491 - Khách hàng: Lê Đức Anh	2026-08-06 15:22:18.692886	f	229d8e58-ffbe-44d4-8909-3e92985cfe8c	Phân công bảo trì: Vòi nước bị rò rỉ	MAINTENANCE	b1000000-0000-0000-0000-000000000008
b1714876-5a8c-400d-80cc-845e40ecf322	Đề xuất/Xác nhận khung giờ làm việc: Tối nay (18:00 - 20:30)	2026-08-06 15:22:27.436325	f	229d8e58-ffbe-44d4-8909-3e92985cfe8c	Ghi chú tiến độ MNT-20260806-491	MAINTENANCE	33712636-202b-4ff3-8011-2da710d65035
094a10e9-e0ba-4bc5-8271-31227319461f	Kỹ thuật viên đề xuất khung giờ: Tối nay (18:00 - 20:30). Vui lòng xác nhận.	2026-08-06 15:22:27.437741	f	229d8e58-ffbe-44d4-8909-3e92985cfe8c	Lịch bảo trì MNT-20260806-491	MAINTENANCE	33712636-202b-4ff3-8011-2da710d65035
8ab4ffab-082d-4a4b-b4a8-b568e921e7bb	Cư dân đã xác nhận lịch hẹn: Tối nay (18:00 - 20:30)	2026-08-06 15:34:49.550839	f	229d8e58-ffbe-44d4-8909-3e92985cfe8c	Phản hồi lịch hẹn MNT-20260806-491	MAINTENANCE	b1000000-0000-0000-0000-000000000008
4154eac8-a970-41cc-8b28-51ee34314984	Vòi nước bị rò rỉ - HIGH	2026-08-06 15:22:10.516029	t	229d8e58-ffbe-44d4-8909-3e92985cfe8c	New Maintenance Request MNT-20260806-491	MAINTENANCE	c5d65edf-fb24-4f93-b966-362f36e78370
28ce2088-8e50-4286-8a2c-5da0ed90b234	Khách thuê phòng 003 chọn thanh toán tiền mặt cho hóa đơn 2026-08-01	2026-08-06 15:13:17.117717	t	c979cd05-f5aa-4903-8f9d-29e3e743ee51	Yêu cầu thanh toán tiền mặt	INVOICE	c5d65edf-fb24-4f93-b966-362f36e78370
e1089bf0-0a1d-4038-a01d-14239aa18059	Phiếu bảo trì Điều hòa bị chảy nước đã quá hạn SLA.	2026-08-05 18:58:15.209165	t	2f6bcc81-68a7-46e1-b7b8-f98bf267fe53	Cảnh báo quá hạn SLA: MNT-20260805-421	MAINTENANCE	c5d65edf-fb24-4f93-b966-362f36e78370
b416f4cb-d4ca-4934-a5e1-3fdc7ddb9371	Invoice for 2026-08 is ready	2026-08-06 15:53:10.837306	f	0dbf774c-2d51-4fe4-854c-54314781e63c	New Invoice	INVOICE	797e1cfb-d15e-4642-b968-faba2a872c4a
0d585d90-aed1-4b14-8688-22ab5df5e1a1	Kỹ thuật viên bắt đầu xử lý công việc	2026-08-06 16:42:55.491652	f	229d8e58-ffbe-44d4-8909-3e92985cfe8c	Ghi chú tiến độ MNT-20260806-491	MAINTENANCE	33712636-202b-4ff3-8011-2da710d65035
915ef553-be8a-4f19-af64-4524eef63b5e	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-06T21:22:10.513911)	2026-08-06 21:30:35.692264	f	229d8e58-ffbe-44d4-8909-3e92985cfe8c	Ghi chú tiến độ MNT-20260806-491	MAINTENANCE	33712636-202b-4ff3-8011-2da710d65035
3b00fd8a-fe76-4935-a9cc-9e51305ce8a4	Phiếu bảo trì Vòi nước bị rò rỉ đã quá hạn SLA.	2026-08-06 21:30:35.891692	f	229d8e58-ffbe-44d4-8909-3e92985cfe8c	Cảnh báo quá hạn SLA: MNT-20260806-491	MAINTENANCE	c5d65edf-fb24-4f93-b966-362f36e78370
64fe22ae-b8e0-4eb1-999f-e794660503ac	Phiếu bảo trì Vòi nước bị rò rỉ đã vượt thời gian xử lý dự kiến.	2026-08-06 21:30:40.690937	f	229d8e58-ffbe-44d4-8909-3e92985cfe8c	Khẩn cấp: Quá hạn SLA MNT-20260806-491	MAINTENANCE	b1000000-0000-0000-0000-000000000008
e74a0eea-5676-4b7d-bf55-e5d0d7563cc5	Khách thuê phòng T3-12.08 chọn thanh toán tiền mặt cho hóa đơn 2026-08-01	2026-08-09 15:58:56.183008	f	7c135337-f51e-49fa-8731-3768446542f0	Yêu cầu thanh toán tiền mặt	INVOICE	b1000000-0000-0000-0000-000000000001
6e1f7746-4631-4e98-8411-fe09a9ede07a	Điều hoà bị hư - HIGH	2026-08-09 16:01:33.279869	f	849c05ad-e3b6-4c8b-9f10-3db67d42a9e6	New Maintenance Request MNT-20260809-282	MAINTENANCE	b1000000-0000-0000-0000-000000000001
665241db-2a3e-433a-86d3-a3bc3c903e3a	Phân công kỹ thuật viên: Kỹ thuật viên B	2026-08-09 16:03:31.193706	f	849c05ad-e3b6-4c8b-9f10-3db67d42a9e6	Ghi chú tiến độ MNT-20260809-282	MAINTENANCE	b1000000-0000-0000-0000-000000000002
36a61428-b876-4a56-b69f-5881e4f897da	Mã phiếu: MNT-20260809-282 - Khách hàng: Nguyen Minh Anh	2026-08-09 16:03:31.282844	f	849c05ad-e3b6-4c8b-9f10-3db67d42a9e6	Phân công bảo trì: Điều hoà bị hư	MAINTENANCE	a0000000-0000-0000-0000-000000000003
8d8aacf6-e240-4d45-b19e-25300042d124	Đề xuất/Xác nhận khung giờ làm việc: Sáng Thứ Hai (10/08) (8:00 - 11:30)	2026-08-09 16:03:51.53768	f	849c05ad-e3b6-4c8b-9f10-3db67d42a9e6	Ghi chú tiến độ MNT-20260809-282	MAINTENANCE	b1000000-0000-0000-0000-000000000002
774ced94-a6ea-446f-acc9-f94fc3e88a97	Kỹ thuật viên đề xuất khung giờ: Sáng Thứ Hai (10/08) (8:00 - 11:30). Vui lòng xác nhận.	2026-08-09 16:03:51.542457	f	849c05ad-e3b6-4c8b-9f10-3db67d42a9e6	Lịch bảo trì MNT-20260809-282	MAINTENANCE	b1000000-0000-0000-0000-000000000002
42bc2cf5-5fa4-4883-bb01-5accf8ce092e	Cư dân đã xác nhận lịch hẹn: Sáng Thứ Hai (10/08) (8:00 - 11:30)	2026-08-09 16:04:39.91908	f	849c05ad-e3b6-4c8b-9f10-3db67d42a9e6	Phản hồi lịch hẹn MNT-20260809-282	MAINTENANCE	a0000000-0000-0000-0000-000000000003
d9b6c224-a840-449b-8f3f-40b0d57dff09	Kỹ thuật viên bắt đầu xử lý công việc	2026-08-09 16:04:56.892894	f	849c05ad-e3b6-4c8b-9f10-3db67d42a9e6	Ghi chú tiến độ MNT-20260809-282	MAINTENANCE	b1000000-0000-0000-0000-000000000002
a085646c-ddb0-4ba8-9443-1bc8dfb0370d	Thêm vật tư: CP x1 (50000 VNĐ)	2026-08-09 16:05:19.680237	f	849c05ad-e3b6-4c8b-9f10-3db67d42a9e6	Ghi chú tiến độ MNT-20260809-282	MAINTENANCE	b1000000-0000-0000-0000-000000000002
3c79638b-33f1-4ede-bc11-e2f60ab99719	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-09T22:01:33.184067)	2026-08-09 22:22:14.769958	f	849c05ad-e3b6-4c8b-9f10-3db67d42a9e6	Ghi chú tiến độ MNT-20260809-282	MAINTENANCE	b1000000-0000-0000-0000-000000000002
6bee793b-40ce-4a8f-ac65-ffb2ce39173f	Phiếu bảo trì Điều hoà bị hư đã quá hạn SLA.	2026-08-09 22:22:14.772217	f	849c05ad-e3b6-4c8b-9f10-3db67d42a9e6	Cảnh báo quá hạn SLA: MNT-20260809-282	MAINTENANCE	b1000000-0000-0000-0000-000000000001
494f7f6d-9f71-4df6-baa9-49e5e4b968fa	Phiếu bảo trì Điều hoà bị hư đã vượt thời gian xử lý dự kiến.	2026-08-09 22:22:14.772373	f	849c05ad-e3b6-4c8b-9f10-3db67d42a9e6	Khẩn cấp: Quá hạn SLA MNT-20260809-282	MAINTENANCE	a0000000-0000-0000-0000-000000000003
3f9d03a3-88a8-42e2-9013-922d21999b95	Your invoice for 2026-08-01 is overdue	2026-08-11 08:00:00.013828	f	cdba4b04-3ca8-4996-833c-0048bf68296d	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000014
5767f01e-18e6-4e6d-85d2-269c5896b89d	Your invoice for 2026-08-01 is overdue	2026-08-11 08:00:00.017955	f	90778511-703a-4e87-be04-1223be4918c2	Invoice Overdue	INVOICE	33712636-202b-4ff3-8011-2da710d65035
d7144e52-91c0-4d14-8c2f-6b93efd5d4f7	Your invoice for 2026-08-01 is overdue	2026-08-11 08:00:00.022097	f	8e596cb3-e94a-48fe-9954-844e520f2e1c	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000006
7735ef37-c365-4683-9c22-79474b987308	Your invoice for 2026-08-01 is overdue	2026-08-11 08:00:00.024485	f	e36d3e32-acf2-4031-af62-fb8c82b92619	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000007
bb7618a0-2a04-4422-9b82-099649071329	Your invoice for 2026-08-01 is overdue	2026-08-11 08:00:00.079958	f	0dbf774c-2d51-4fe4-854c-54314781e63c	Invoice Overdue	INVOICE	797e1cfb-d15e-4642-b968-faba2a872c4a
c5b98329-b430-4fa4-9d78-1a08bb4267f5	Your invoice for 2026-08-01 is overdue	2026-08-11 08:00:00.183323	f	7c135337-f51e-49fa-8731-3768446542f0	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000002
658fee7c-317e-432c-9226-cd863b656f43	Your invoice for 2026-08-01 is overdue	2026-08-11 08:00:01.284146	f	900306d5-a430-49bf-b5c5-d7a3161cad4b	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000010
10798108-9d17-4531-9ddf-e7fae0b5f337	Your invoice for 2026-08-01 is overdue	2026-08-11 08:00:01.286653	f	fa0879db-1e12-41ee-8fff-f293de4189ef	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000011
0b306967-505e-4a51-b991-9715ea8b4749	Your invoice for 2026-08-01 is overdue	2026-08-11 08:00:01.382546	f	88a58727-f640-496a-b1a3-80cfa3acda4d	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000012
28556687-b0c5-40be-b4be-2449cb0ef66c	Your invoice for 2026-08-01 is overdue	2026-08-11 08:00:01.385333	f	37ed8c23-1291-4b04-9b8f-744c89b42b3c	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000013
9e20c653-2e82-4219-afe3-9692e2fcf5c2	Your invoice for 2026-08-01 is overdue	2026-08-11 08:00:01.480149	f	71299135-fa55-482a-9679-bbb4dd57ad17	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000015
ca330b9d-ca1e-4e7a-adc8-0e86ccaa7131	Your invoice for 2026-08-01 is overdue	2026-08-11 08:00:01.482867	f	c2170b99-cd9f-430c-ba4e-a8e51293fd6e	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000017
22682df6-a03a-4fb8-b606-328390fd8689	Your invoice for 2026-08-01 is overdue	2026-08-11 08:00:01.485233	f	1f86bcfd-5c7b-480c-9388-d9e9f53abb33	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000020
ad6c10f0-b86e-44d0-8713-105aa862a458	Your invoice for 2026-08-01 is overdue	2026-08-11 08:00:01.579965	f	43a1debd-e6d3-4752-ad27-a68df77cfe0f	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000004
ed5266c0-594a-4731-90a1-ac18b6e37eb9	Your invoice for 2026-08-01 is overdue	2026-08-11 08:00:01.584021	f	eaee2c21-c729-4dc2-8f61-539fd6721831	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000003
6e4e21bb-d6ae-4c75-b8c2-155a105fbd14	Cp bị nổ - HIGH	2026-08-14 04:28:39.866115	f	c05e9333-2746-4b7f-9a01-8182f91ffa93	New Maintenance Request MNT-20260814-568	MAINTENANCE	b1000000-0000-0000-0000-000000000001
78399b03-6390-4cb9-8731-bfa227624f0f	Mã phiếu: MNT-20260814-568 - Khách hàng: Pham Thu Trang	2026-08-14 04:29:42.184501	f	c05e9333-2746-4b7f-9a01-8182f91ffa93	Phân công bảo trì: Cp bị nổ	MAINTENANCE	a0000000-0000-0000-0000-000000000003
1e2c4b00-84de-4369-93d1-73376aab9ac1	Your invoice for 2026-08-01 is overdue	2026-08-11 08:00:01.586603	t	cc0cd89c-886d-476e-a9f2-6a4a2649bb01	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000004
af7089e9-7b9f-459f-9725-579b463eb248	Kỹ thuật viên đề xuất khung giờ: Sáng Thứ Bảy (15/08) (8:00 - 11:30). Vui lòng xác nhận.	2026-08-14 04:30:12.415336	t	c05e9333-2746-4b7f-9a01-8182f91ffa93	Lịch bảo trì MNT-20260814-568	MAINTENANCE	b1000000-0000-0000-0000-000000000005
9dbbcebf-4ac1-465c-a451-2815f8a569d1	Đề xuất/Xác nhận khung giờ làm việc: Sáng Thứ Bảy (15/08) (8:00 - 11:30)	2026-08-14 04:30:12.414344	t	c05e9333-2746-4b7f-9a01-8182f91ffa93	Ghi chú tiến độ MNT-20260814-568	MAINTENANCE	b1000000-0000-0000-0000-000000000005
015c9b25-9656-428f-a025-cfa7ca28fcfa	Phân công kỹ thuật viên: Kỹ thuật viên B	2026-08-14 04:29:42.183439	t	c05e9333-2746-4b7f-9a01-8182f91ffa93	Ghi chú tiến độ MNT-20260814-568	MAINTENANCE	b1000000-0000-0000-0000-000000000005
bc396edb-9c1f-45b2-8afc-4a7bcfdfdfb7	Your invoice for 2026-08-01 is overdue	2026-08-11 08:00:00.179913	t	f04eb140-899d-4bdb-b58c-4e30e87784d0	Invoice Overdue	INVOICE	b1000000-0000-0000-0000-000000000005
d8b69bfa-aa98-45ad-b2a0-1adb5bedcc11	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-14T16:28:39.767331)	2026-08-14 16:48:56.781874	f	c05e9333-2746-4b7f-9a01-8182f91ffa93	Ghi chú tiến độ MNT-20260814-568	MAINTENANCE	b1000000-0000-0000-0000-000000000005
ef1f5439-4a42-47ba-9478-fa7fcb1daa23	Phiếu bảo trì Cp bị nổ đã quá hạn SLA.	2026-08-14 16:48:56.784763	f	c05e9333-2746-4b7f-9a01-8182f91ffa93	Cảnh báo quá hạn SLA: MNT-20260814-568	MAINTENANCE	b1000000-0000-0000-0000-000000000001
02162b37-183b-47f1-9783-b71bb7221eee	Phiếu bảo trì Cp bị nổ đã vượt thời gian xử lý dự kiến.	2026-08-14 16:48:56.784979	f	c05e9333-2746-4b7f-9a01-8182f91ffa93	Khẩn cấp: Quá hạn SLA MNT-20260814-568	MAINTENANCE	a0000000-0000-0000-0000-000000000003
9655180a-0212-4799-8d29-a627ebc60f5f	Invoice for 2026-09 is ready	2026-08-19 06:57:24.857491	f	630256f4-8c34-4f40-b621-917edd5dd826	New Invoice	INVOICE	b1000000-0000-0000-0000-000000000002
ec1a88c3-c461-462c-8dcc-427b7f63702c	Khách thuê phòng T3-12.08 chọn thanh toán tiền mặt cho hóa đơn 2026-09-01	2026-08-19 06:57:44.801955	f	630256f4-8c34-4f40-b621-917edd5dd826	Yêu cầu thanh toán tiền mặt	INVOICE	b1000000-0000-0000-0000-000000000001
a7cead9d-a4b8-4d5b-a425-c1a7adbf7bb0	CP bị nổ - HIGH	2026-08-19 07:06:12.956224	f	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185	New Maintenance Request MNT-20260819-063	MAINTENANCE	b1000000-0000-0000-0000-000000000001
9e435ff2-657b-4eb6-b231-209aa91575b6	Hủy phiếu bảo trì. Lý do: Bắt buộc huỷ	2026-08-19 07:06:40.059852	f	c05e9333-2746-4b7f-9a01-8182f91ffa93	Ghi chú tiến độ MNT-20260814-568	MAINTENANCE	b1000000-0000-0000-0000-000000000005
ccc4ea4f-d3c6-4fa9-ba28-dcb5908a012a	Lý do: Bắt buộc huỷ	2026-08-19 07:06:40.060043	f	c05e9333-2746-4b7f-9a01-8182f91ffa93	Phiếu bảo trì bị hủy: MNT-20260814-568	MAINTENANCE	a0000000-0000-0000-0000-000000000003
01b169a9-f155-4193-9a30-a58ec6a50963	Phân công kỹ thuật viên: Kĩ Thuật Viên A	2026-08-19 07:06:45.175217	f	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185	Ghi chú tiến độ MNT-20260819-063	MAINTENANCE	b1000000-0000-0000-0000-000000000002
8e48f483-b1e9-4eaa-81c0-b8b3be30d2b2	Mã phiếu: MNT-20260819-063 - Khách hàng: Nguyen Minh Anh	2026-08-19 07:06:45.178884	t	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185	Phân công bảo trì: CP bị nổ	MAINTENANCE	936bdf00-c9f0-4889-80fc-86f3a59d051e
09f41030-96d3-45b0-b003-c0541b562831	Đề xuất/Xác nhận khung giờ làm việc: Chiều Thứ Năm (20/08) (13:30 - 17:00)	2026-08-19 07:06:54.05106	f	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185	Ghi chú tiến độ MNT-20260819-063	MAINTENANCE	b1000000-0000-0000-0000-000000000002
a1b6d57d-537f-4225-93ae-cd7cbf00b1b1	Kỹ thuật viên đề xuất khung giờ: Chiều Thứ Năm (20/08) (13:30 - 17:00). Vui lòng xác nhận.	2026-08-19 07:06:54.053282	f	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185	Lịch bảo trì MNT-20260819-063	MAINTENANCE	b1000000-0000-0000-0000-000000000002
3ef1ac66-09a9-473d-b1f6-d87a4bb1e456	Kỹ thuật viên bắt đầu xử lý công việc	2026-08-19 07:07:09.570894	f	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185	Ghi chú tiến độ MNT-20260819-063	MAINTENANCE	b1000000-0000-0000-0000-000000000002
f4096cbf-e68c-4812-87b4-f90356e616e3	Thêm vật tư: Cp mới x1 (50000 VNĐ)	2026-08-19 07:07:38.356286	f	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185	Ghi chú tiến độ MNT-20260819-063	MAINTENANCE	b1000000-0000-0000-0000-000000000002
2a79c1f9-5f5f-4d86-91e7-99020ce23e2c	Cư dân đã xác nhận lịch hẹn: Chiều Thứ Năm (20/08) (13:30 - 17:00)	2026-08-19 07:07:06.454569	t	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185	Phản hồi lịch hẹn MNT-20260819-063	MAINTENANCE	936bdf00-c9f0-4889-80fc-86f3a59d051e
4d26c4e7-8eff-411c-bcf3-a0a47ae603fc	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-19T13:06:12.860776)	2026-08-19 13:31:56.613148	f	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185	Ghi chú tiến độ MNT-20260819-063	MAINTENANCE	b1000000-0000-0000-0000-000000000002
ddc50925-0ed2-4302-830f-b4921d469644	Phiếu bảo trì CP bị nổ đã quá hạn SLA.	2026-08-19 13:31:56.615135	f	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185	Cảnh báo quá hạn SLA: MNT-20260819-063	MAINTENANCE	b1000000-0000-0000-0000-000000000001
a6463211-441b-4e67-91e4-eef25bd34553	Phiếu bảo trì CP bị nổ đã vượt thời gian xử lý dự kiến.	2026-08-19 13:31:56.615405	f	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185	Khẩn cấp: Quá hạn SLA MNT-20260819-063	MAINTENANCE	936bdf00-c9f0-4889-80fc-86f3a59d051e
c1db5b84-6072-4463-be4b-cc5519867b31	Cúp điện - NORMAL	2026-08-21 01:52:12.167951	f	ea9d94f1-b8ff-45da-9312-91c673eaa885	New Maintenance Request MNT-20260821-064	MAINTENANCE	c5d65edf-fb24-4f93-b966-362f36e78370
a5273acb-7baf-48ab-b384-b1977c263d0d	Mã phiếu: MNT-20260821-064 - Khách hàng: Phạm Ngọc Trai	2026-08-21 01:52:48.559907	f	ea9d94f1-b8ff-45da-9312-91c673eaa885	Phân công bảo trì: Cúp điện	MAINTENANCE	b1000000-0000-0000-0000-000000000009
e9d2a314-8a70-461e-b3a3-120efffb2062	Phân công kỹ thuật viên: Phan Duc Huy	2026-08-21 01:52:48.555454	t	ea9d94f1-b8ff-45da-9312-91c673eaa885	Ghi chú tiến độ MNT-20260821-064	MAINTENANCE	3589890e-f56b-4dbc-84fc-12e319e1d750
495c4d28-53d1-4d40-a54a-54892f57de77	CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (2026-08-22T01:52:12.167097)	2026-08-22 02:01:58.456007	f	ea9d94f1-b8ff-45da-9312-91c673eaa885	Ghi chú tiến độ MNT-20260821-064	MAINTENANCE	3589890e-f56b-4dbc-84fc-12e319e1d750
b595e9ca-682e-4833-9a79-3d0bdfcfffe4	Phiếu bảo trì Cúp điện đã quá hạn SLA.	2026-08-22 02:01:59.356615	f	ea9d94f1-b8ff-45da-9312-91c673eaa885	Cảnh báo quá hạn SLA: MNT-20260821-064	MAINTENANCE	c5d65edf-fb24-4f93-b966-362f36e78370
0953e620-0461-48a6-8db1-6ac272fb3d42	Phiếu bảo trì Cúp điện đã vượt thời gian xử lý dự kiến.	2026-08-22 02:01:59.357244	f	ea9d94f1-b8ff-45da-9312-91c673eaa885	Khẩn cấp: Quá hạn SLA MNT-20260821-064	MAINTENANCE	b1000000-0000-0000-0000-000000000009
dbacdca6-4a5c-4e65-b9fe-02c4f48fb9ef	Hủy phiếu bảo trì. Lý do: nahhhhhhhhh	2026-08-22 13:17:35.894721	f	ea9d94f1-b8ff-45da-9312-91c673eaa885	Ghi chú tiến độ MNT-20260821-064	MAINTENANCE	3589890e-f56b-4dbc-84fc-12e319e1d750
c9706b9a-047e-4a29-9eaf-851b22c44390	Lý do: nahhhhhhhhh	2026-08-22 13:17:35.895888	f	ea9d94f1-b8ff-45da-9312-91c673eaa885	Phiếu bảo trì bị hủy: MNT-20260821-064	MAINTENANCE	b1000000-0000-0000-0000-000000000009
120d181c-ee46-44c4-8c71-dfe7f83a9588	Báo giá vật tư: 50000.00 VNĐ, chuyển chờ thanh toán	2026-08-22 13:40:56.815596	f	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185	Ghi chú tiến độ MNT-20260819-063	MAINTENANCE	b1000000-0000-0000-0000-000000000002
98521d36-b35d-46d6-9413-13fccd1faed8	Vui lòng kiểm tra và xác nhận chi phí vật tư: 50000.00 VNĐ	2026-08-22 13:40:57.116857	f	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185	Cập nhật bảo trì MNT-20260819-063	MAINTENANCE	b1000000-0000-0000-0000-000000000002
8e57050b-841e-47df-914a-447333611fbd	Cư dân đã thanh toán 50000.00 VNĐ. Phiếu chuyển sang chờ nghiệm thu.	2026-08-22 13:41:15.620326	f	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185	Đã thanh toán vật tư MNT-20260819-063	MAINTENANCE	936bdf00-c9f0-4889-80fc-86f3a59d051e
cfd58c5c-be02-4eee-9f3f-964b64338f34	Xác nhận nghiệm thu hoàn thành phiếu bảo trì	2026-08-22 13:41:24.435905	f	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185	Ghi chú tiến độ MNT-20260819-063	MAINTENANCE	b1000000-0000-0000-0000-000000000002
d70b2809-b431-4e6b-8f6c-9c829f759916	Phiếu bảo trì đã hoàn thành: CP bị nổ	2026-08-22 13:41:24.436705	f	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185	Nghiệm thu thành công MNT-20260819-063	MAINTENANCE	b1000000-0000-0000-0000-000000000002
5d259ce9-7a08-4c7e-bdad-b5ca4a1ab80c	Điều hoà chảy nước - HIGH	2026-08-22 13:42:19.118597	f	69839fb2-7b7c-41fe-9a50-431b132a54ce	New Maintenance Request MNT-20260822-012	MAINTENANCE	b1000000-0000-0000-0000-000000000001
4740ac6a-994d-4461-a395-79e8cf0216f6	Phân công kỹ thuật viên: Kĩ Thuật Viên A	2026-08-22 13:42:40.017386	f	69839fb2-7b7c-41fe-9a50-431b132a54ce	Ghi chú tiến độ MNT-20260822-012	MAINTENANCE	b1000000-0000-0000-0000-000000000002
4d98b370-3837-45cd-8d2e-98decb72b5ae	Mã phiếu: MNT-20260822-012 - Khách hàng: Nguyen Minh Anh	2026-08-22 13:42:40.018282	f	69839fb2-7b7c-41fe-9a50-431b132a54ce	Phân công bảo trì: Điều hoà chảy nước	MAINTENANCE	936bdf00-c9f0-4889-80fc-86f3a59d051e
8d75ea7e-ea93-4501-b807-e2f48d1691a6	Đề xuất/Xác nhận khung giờ làm việc: Chiều Chủ Nhật (23/08) (13:30 - 17:00)	2026-08-22 13:42:51.393571	f	69839fb2-7b7c-41fe-9a50-431b132a54ce	Ghi chú tiến độ MNT-20260822-012	MAINTENANCE	b1000000-0000-0000-0000-000000000002
9bb5afd9-357c-4a25-8cd0-bed6fb1e1545	Kỹ thuật viên đề xuất khung giờ: Chiều Chủ Nhật (23/08) (13:30 - 17:00). Vui lòng xác nhận.	2026-08-22 13:42:51.394602	f	69839fb2-7b7c-41fe-9a50-431b132a54ce	Lịch bảo trì MNT-20260822-012	MAINTENANCE	b1000000-0000-0000-0000-000000000002
1bd6e7e9-dafe-48fd-a8cd-a12648638713	Cư dân đã xác nhận lịch hẹn: Chiều Chủ Nhật (23/08) (13:30 - 17:00)	2026-08-22 13:42:54.212266	f	69839fb2-7b7c-41fe-9a50-431b132a54ce	Phản hồi lịch hẹn MNT-20260822-012	MAINTENANCE	936bdf00-c9f0-4889-80fc-86f3a59d051e
8387170a-2950-4eac-9bb1-1fd07c230b96	Kỹ thuật viên bắt đầu xử lý công việc	2026-08-22 13:42:58.713094	f	69839fb2-7b7c-41fe-9a50-431b132a54ce	Ghi chú tiến độ MNT-20260822-012	MAINTENANCE	b1000000-0000-0000-0000-000000000002
a632c4a1-c781-426a-a510-8be00d88ace5	Hoàn tất xử lý, gửi yêu cầu nghiệm thu cho cư dân/ban quản lý	2026-08-22 13:43:34.711735	f	69839fb2-7b7c-41fe-9a50-431b132a54ce	Ghi chú tiến độ MNT-20260822-012	MAINTENANCE	b1000000-0000-0000-0000-000000000002
14b9e93c-5b69-4aba-8ed5-53b3ec6f8b7b	Kỹ thuật viên đã xử lý xong, vui lòng nghiệm thu	2026-08-22 13:43:34.72459	f	69839fb2-7b7c-41fe-9a50-431b132a54ce	Cập nhật bảo trì MNT-20260822-012	MAINTENANCE	b1000000-0000-0000-0000-000000000002
78999c7f-b3a8-4c4b-9e5c-86f547d6b031	Xác nhận nghiệm thu hoàn thành phiếu bảo trì	2026-08-22 13:43:42.113965	f	69839fb2-7b7c-41fe-9a50-431b132a54ce	Ghi chú tiến độ MNT-20260822-012	MAINTENANCE	b1000000-0000-0000-0000-000000000002
0d04435f-6371-4912-9f18-99cc7cf9817b	Phiếu bảo trì đã hoàn thành: Điều hoà chảy nước	2026-08-22 13:43:42.114652	f	69839fb2-7b7c-41fe-9a50-431b132a54ce	Nghiệm thu thành công MNT-20260822-012	MAINTENANCE	b1000000-0000-0000-0000-000000000002
705f80f3-c6ab-4fa5-bdaf-e0cf78e25629	Khách thuê Nguyen Minh Anh đánh giá: 	2026-08-22 13:44:05.111951	f	a9de68a4-0cdc-4311-a6c3-53eb72e57afa	Nhận đánh giá mới: 5 sao	REVIEW	936bdf00-c9f0-4889-80fc-86f3a59d051e
dc7f3f12-2224-4f6d-9b05-7d89aa94201d	Báo giá vật tư: 240000.00 VNĐ, chuyển chờ thanh toán	2026-08-22 13:46:25.519744	f	db9a9713-3331-441f-84c5-ea3e5abb1197	Ghi chú tiến độ MNT-20260805-410	MAINTENANCE	b1000000-0000-0000-0000-000000000005
c50b1784-b8c7-4681-a2cf-4f3f3937cf06	Vui lòng kiểm tra và xác nhận chi phí vật tư: 240000.00 VNĐ	2026-08-22 13:46:25.619354	f	db9a9713-3331-441f-84c5-ea3e5abb1197	Cập nhật bảo trì MNT-20260805-410	MAINTENANCE	b1000000-0000-0000-0000-000000000005
02b679ab-acec-4ccb-8761-de9de2afb412	Báo giá vật tư: 20000.00 VNĐ, chuyển chờ thanh toán	2026-08-22 13:46:45.411637	f	0f0f870b-8625-4306-84b4-61e3c78ae7e2	Ghi chú tiến độ MNT-20260805-411	MAINTENANCE	b1000000-0000-0000-0000-000000000005
6125a180-5041-4b9b-87e4-337cd2d13670	Vui lòng kiểm tra và xác nhận chi phí vật tư: 20000.00 VNĐ	2026-08-22 13:46:45.513338	f	0f0f870b-8625-4306-84b4-61e3c78ae7e2	Cập nhật bảo trì MNT-20260805-411	MAINTENANCE	b1000000-0000-0000-0000-000000000005
52bc5c0b-b7d0-4794-883d-75ff85e236c6	Báo giá vật tư: 20000.00 VNĐ, chuyển chờ thanh toán	2026-08-22 13:46:49.11764	f	0f0f870b-8625-4306-84b4-61e3c78ae7e2	Ghi chú tiến độ MNT-20260805-411	MAINTENANCE	b1000000-0000-0000-0000-000000000005
1c5933fe-a985-416d-9f52-a6a28e76a88d	Vui lòng kiểm tra và xác nhận chi phí vật tư: 20000.00 VNĐ	2026-08-22 13:46:49.129803	f	0f0f870b-8625-4306-84b4-61e3c78ae7e2	Cập nhật bảo trì MNT-20260805-411	MAINTENANCE	b1000000-0000-0000-0000-000000000005
0fcf489f-cc46-422e-b10d-5b64e4b6736b	Báo giá vật tư: 20000.00 VNĐ, chuyển chờ thanh toán	2026-08-22 13:46:53.118155	f	0f0f870b-8625-4306-84b4-61e3c78ae7e2	Ghi chú tiến độ MNT-20260805-411	MAINTENANCE	b1000000-0000-0000-0000-000000000005
be60a9bb-db9b-44e4-b23d-14a5f04d17ee	Vui lòng kiểm tra và xác nhận chi phí vật tư: 20000.00 VNĐ	2026-08-22 13:46:53.130771	f	0f0f870b-8625-4306-84b4-61e3c78ae7e2	Cập nhật bảo trì MNT-20260805-411	MAINTENANCE	b1000000-0000-0000-0000-000000000005
623e2870-404e-40af-85cd-358a47e3c1a7	Hư Cp - HIGH	2026-08-22 14:47:23.32541	f	b7a2d2ad-c428-4c0d-8802-256afd8979d4	New Maintenance Request MNT-20260822-124	MAINTENANCE	b1000000-0000-0000-0000-000000000001
67572769-e0ff-49c4-b7b4-119aca098bfe	Phân công kỹ thuật viên: Kĩ Thuật Viên A	2026-08-22 14:47:52.948011	f	b7a2d2ad-c428-4c0d-8802-256afd8979d4	Ghi chú tiến độ MNT-20260822-124	MAINTENANCE	b1000000-0000-0000-0000-000000000002
f5475dd3-c498-423d-9efc-0bdc61b22297	Mã phiếu: MNT-20260822-124 - Khách hàng: Nguyen Minh Anh	2026-08-22 14:47:53.02082	f	b7a2d2ad-c428-4c0d-8802-256afd8979d4	Phân công bảo trì: Hư Cp	MAINTENANCE	936bdf00-c9f0-4889-80fc-86f3a59d051e
3e5f7e7d-1fd1-42dc-8043-55ebe11d75ac	Đề xuất/Xác nhận khung giờ làm việc: Sáng Chủ Nhật (23/08) (8:00 - 11:30)	2026-08-22 14:47:59.219111	f	b7a2d2ad-c428-4c0d-8802-256afd8979d4	Ghi chú tiến độ MNT-20260822-124	MAINTENANCE	b1000000-0000-0000-0000-000000000002
3ac90adc-d56c-4653-867c-7afb644459ee	Kỹ thuật viên đề xuất khung giờ: Sáng Chủ Nhật (23/08) (8:00 - 11:30). Vui lòng xác nhận.	2026-08-22 14:47:59.220612	f	b7a2d2ad-c428-4c0d-8802-256afd8979d4	Lịch bảo trì MNT-20260822-124	MAINTENANCE	b1000000-0000-0000-0000-000000000002
afeefb46-dfd1-4cf3-9207-c339393ff031	Cư dân đã xác nhận lịch hẹn: Sáng Chủ Nhật (23/08) (8:00 - 11:30)	2026-08-22 14:48:02.125729	f	b7a2d2ad-c428-4c0d-8802-256afd8979d4	Phản hồi lịch hẹn MNT-20260822-124	MAINTENANCE	936bdf00-c9f0-4889-80fc-86f3a59d051e
1c67981c-b906-446c-a64c-3b8f43a85a51	Kỹ thuật viên bắt đầu xử lý công việc	2026-08-22 14:48:04.558356	f	b7a2d2ad-c428-4c0d-8802-256afd8979d4	Ghi chú tiến độ MNT-20260822-124	MAINTENANCE	b1000000-0000-0000-0000-000000000002
588ce3cf-bedc-4c12-92be-cfa9f79843f7	Hoàn tất xử lý, gửi yêu cầu nghiệm thu cho cư dân/ban quản lý	2026-08-22 14:48:21.283749	f	b7a2d2ad-c428-4c0d-8802-256afd8979d4	Ghi chú tiến độ MNT-20260822-124	MAINTENANCE	b1000000-0000-0000-0000-000000000002
90483b28-cccb-4116-a7cd-b9f878b1c03b	Kỹ thuật viên đã xử lý xong, vui lòng nghiệm thu	2026-08-22 14:48:21.302882	f	b7a2d2ad-c428-4c0d-8802-256afd8979d4	Cập nhật bảo trì MNT-20260822-124	MAINTENANCE	b1000000-0000-0000-0000-000000000002
de8123b2-0502-4f1f-a4d5-81bba0baf9a2	Xác nhận nghiệm thu hoàn thành phiếu bảo trì	2026-08-22 14:48:29.425062	f	b7a2d2ad-c428-4c0d-8802-256afd8979d4	Ghi chú tiến độ MNT-20260822-124	MAINTENANCE	b1000000-0000-0000-0000-000000000002
7cbc3e37-10a2-481c-ab0e-a3a21b789ecc	Phiếu bảo trì đã hoàn thành: Hư Cp	2026-08-22 14:48:29.426125	f	b7a2d2ad-c428-4c0d-8802-256afd8979d4	Nghiệm thu thành công MNT-20260822-124	MAINTENANCE	b1000000-0000-0000-0000-000000000002
\.


--
-- Data for Name: payment_event_receipts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.payment_event_receipts (id, created_at, updated_at, applied, event_key, order_code, transaction_id) FROM stdin;
\.


--
-- Data for Name: payment_intents; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.payment_intents (id, created_at, updated_at, checkout_url, order_code, status, invoice_id) FROM stdin;
\.


--
-- Data for Name: properties; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.properties (id, created_at, updated_at, address, description, floor_count, name, room_count, owner_id, type) FROM stdin;
b3000000-0000-0000-0000-000000000001	2026-01-08 09:00:00	2026-06-30 10:00:00	159 Xa lo Ha Noi, Phuong Thao Dien, TP Thu Duc, TP.HCM	Can ho huu nghi cho nhom khach di lam tai khu dong thanh pho.	25	Masteri Thao Dien - Toa T3	150	b1000000-0000-0000-0000-000000000001	b2000000-0000-0000-0000-000000000001
b3000000-0000-0000-0000-000000000002	2026-01-08 09:15:00	2026-06-30 10:05:00	208 Nguyen Huu Canh, Phuong 22, Quan Binh Thanh, TP.HCM	Can ho huong song, phu hop cho gia dinh tre va nhan su van phong.	30	Vinhomes Central Park - Park 6	200	b1000000-0000-0000-0000-000000000001	b2000000-0000-0000-0000-000000000001
b3000000-0000-0000-0000-000000000003	2026-01-08 09:30:00	2026-06-30 10:10:00	346 Ben Van Don, Phuong 1, Quan 4, TP.HCM	Can ho gan trung tam, de di Quan 1 va khu Ben Nghe.	20	The Gold View - Block A	120	b1000000-0000-0000-0000-000000000001	b2000000-0000-0000-0000-000000000001
b3000000-0000-0000-0000-000000000004	2026-01-08 09:45:00	2026-06-30 10:15:00	67 Mai Chi Tho, Phuong An Phu, TP Thu Duc, TP.HCM	Can ho co san noi that co ban, thich hop cho nguoi o lau dai.	22	Lexington Residence - Block LD	140	b1000000-0000-0000-0000-000000000001	b2000000-0000-0000-0000-000000000001
c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e	2026-07-27 04:54:03.70541	2026-08-02 07:14:06.566089	Số 2 Tôn Đức Thắng, P.Bến Nghé, Quận 1	Grand Marina Saigon là khu phức hợp bất động sản hàng hiệu (Branded Residences) quy mô lớn mang tầm cỡ quốc tế, tọa lạc ngay tại lõi trung tâm Quận 1, TP. Hồ Chí Minh. Dự án là sự hợp tác chiến lược giữa nhà phát triển bất động sản hàng đầu Việt Nam – Masterise Homes và tập đoàn khách sạn lớn nhất thế giới – Marriott International.	46	Grand Marina Saigon	4000	a0000000-0000-0000-0000-000000000001	b2000000-0000-0000-0000-000000000001
e9a22c20-ade9-4541-9a58-f2b10a870651	2026-08-05 05:39:31.741291	2026-08-05 05:39:31.741291	175/3/54/8+175/3/54/10 Hồ Văn Long, phường Bình Tân, Tp. Hồ Chí Minh	 Quy mô: 37 phòng duplex hoạt động full công suất. - Đường trước nhà: Hẻm 1 sẹc 7m xe tải quay đầu, oto đậu cửa. - Vị trí: ngay đường Hồ Văn Long ra Đường số 7 - Đường M1 nối dài, thuận tiện di chuyển qua Tân Bình, Tân Phú, Phú Nhuận, Bình Thạnh. Ngay sát Khu công nghiệp Tân Bình - KCN Vĩnh Lộc sầm uất dân cư. - Kết cấu Tòa nhà: 1 Hầm + 5 tầng (1 trệt 1 lửng 3 lầu sân thượng) - Diện tích Tòa nhà: + 9,7m x 18m (164 m2) full thổ cư; + DT xây dựng: 144 m2; + DT sàn: 700 m2; + Diện tích đất thực tế: 220 m2 (có sân sau 4m x18m).	7	Căn hộ dịch vụ giá rẻ	37	c5d65edf-fb24-4f93-b966-362f36e78370	b2000000-0000-0000-0000-000000000002
\.


--
-- Data for Name: property_types; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.property_types (id, created_at, updated_at, active, code, description, name) FROM stdin;
16cd9648-d83d-423c-95e4-2a0dc845c1ff	2026-07-26 10:49:15.339105	2026-07-26 10:49:15.339105	t	CONDO	\N	Chung cư
b2000000-0000-0000-0000-000000000001	2026-01-05 08:40:00	2026-06-28 09:15:00	t	CONDO_PREMIUM	Can ho trong cac khu chung cu trung va cao cap tai TP.HCM	Chung cu
b2000000-0000-0000-0000-000000000002	2026-01-05 08:45:00	2026-06-28 09:15:00	t	SERVICED_APARTMENT	Can ho cho thue theo thang, co don dep va quan ly van hanh	Can ho dich vu
b2000000-0000-0000-0000-000000000003	2026-01-05 08:50:00	2026-06-28 09:15:00	t	MINI_APARTMENT	Loai hinh studio va can ho nho trong khu dan cu noi thanh	Can ho mini
2e17c830-4be5-40f5-a0d9-6c60f0fc52ec	2026-08-05 04:03:59.806897	2026-08-05 04:03:59.806897	t	HOSTEL	Ký túc xá	Hostel
a2ccaa43-2ccf-488e-9f5b-d79d8a183e7d	2026-08-06 04:30:34.994137	2026-08-06 04:30:34.994137	t	BOARDING_HOUSE	\N	Nhà trọ
\.


--
-- Data for Name: room_images; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.room_images (room_id, image_url) FROM stdin;
b5000000-0000-0000-0000-000000000001	https://images.unsplash.com/photo-1505693416388-ac5ce068fe85
b5000000-0000-0000-0000-000000000004	https://images.unsplash.com/photo-1494526585095-c41746248156
b5000000-0000-0000-0000-000000000007	https://images.unsplash.com/photo-1484154218962-a197022b5858
b5000000-0000-0000-0000-000000000009	https://images.unsplash.com/photo-1502672260266-1c1ef2d93688
\.


--
-- Data for Name: room_notes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.room_notes (id, created_at, updated_at, content, author_id, room_id) FROM stdin;
353519e1-daff-4a3b-9c45-eebc705de061	2026-07-27 04:55:31.811435	2026-07-27 04:55:31.811435	ko có	a0000000-0000-0000-0000-000000000001	26962280-8932-4cc6-b92f-ac0b9a570cd0
c2b5df3a-02fc-4e51-be12-ca2c24b747d0	2026-07-27 04:55:49.561395	2026-07-27 04:55:49.561395	alô	a0000000-0000-0000-0000-000000000001	26962280-8932-4cc6-b92f-ac0b9a570cd0
5dac303a-2b1f-4765-8b6e-46569346c73b	2026-07-27 08:19:16.244117	2026-07-27 08:19:16.244117	không ở thi  đi nấu ăn	a0000000-0000-0000-0000-000000000001	b5000000-0000-0000-0000-000000000001
5be22e04-9004-44eb-bd3d-1296291ed087	2026-08-05 04:04:37.115077	2026-08-05 04:04:37.115077	khoong co	a0000000-0000-0000-0000-000000000001	95192562-e587-4da2-bac0-46d29aa261e9
\.


--
-- Data for Name: rooms; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rooms (id, created_at, updated_at, area_m2, floor, max_people, rent_override, room_number, status, property_id) FROM stdin;
b5000000-0000-0000-0000-000000000002	2026-01-10 08:20:00	2026-06-30 11:00:00	68.50	17	3	14800000.00	T3-17.03	RENTED	b3000000-0000-0000-0000-000000000001
b5000000-0000-0000-0000-000000000004	2026-01-10 08:30:00	2026-06-30 11:05:00	54.20	18	2	15200000.00	P6-18.05	RENTED	b3000000-0000-0000-0000-000000000002
b5000000-0000-0000-0000-000000000005	2026-01-10 08:35:00	2026-06-30 11:05:00	79.80	25	4	18900000.00	P6-25.02	RENTED	b3000000-0000-0000-0000-000000000002
b5000000-0000-0000-0000-000000000006	2026-01-10 08:40:00	2026-06-30 11:05:00	48.00	9	2	14100000.00	P6-09.01	MAINTENANCE	b3000000-0000-0000-0000-000000000002
b5000000-0000-0000-0000-000000000007	2026-01-10 08:45:00	2026-06-30 11:10:00	64.00	15	3	10500000.00	A1-15.07	RENTED	b3000000-0000-0000-0000-000000000003
b5000000-0000-0000-0000-000000000008	2026-01-10 08:50:00	2026-06-30 11:10:00	71.50	22	3	11800000.00	A1-22.09	EMPTY	b3000000-0000-0000-0000-000000000003
b5000000-0000-0000-0000-000000000009	2026-01-10 08:55:00	2026-06-30 11:15:00	58.00	12	2	11900000.00	LD-12.04	RENTED	b3000000-0000-0000-0000-000000000004
b5000000-0000-0000-0000-000000000010	2026-01-10 09:00:00	2026-06-30 11:15:00	47.50	8	2	10800000.00	LD-08.02	RENTED	b3000000-0000-0000-0000-000000000004
b5000000-0000-0000-0000-000000000011	2026-01-10 09:05:00	2026-06-30 11:15:00	83.20	20	4	16400000.00	LD-20.01	EMPTY	b3000000-0000-0000-0000-000000000004
b5000000-0000-0000-0000-000000000012	2026-02-05 08:10:00	2026-06-30 12:10:00	45.00	5	2	10900000.00	T3-05.02	RENTED	b3000000-0000-0000-0000-000000000001
b5000000-0000-0000-0000-000000000013	2026-02-05 08:15:00	2026-06-30 12:10:00	57.50	9	2	12800000.00	T3-09.06	RENTED	b3000000-0000-0000-0000-000000000001
b5000000-0000-0000-0000-000000000014	2026-02-05 08:20:00	2026-06-30 12:10:00	72.00	21	3	16200000.00	T3-21.01	RENTED	b3000000-0000-0000-0000-000000000001
b5000000-0000-0000-0000-000000000015	2026-02-05 08:25:00	2026-06-30 12:10:00	46.80	26	2	11300000.00	T3-26.09	EMPTY	b3000000-0000-0000-0000-000000000001
b5000000-0000-0000-0000-000000000016	2026-02-05 08:30:00	2026-06-30 12:15:00	50.60	6	2	13900000.00	P6-06.03	RENTED	b3000000-0000-0000-0000-000000000002
b5000000-0000-0000-0000-000000000017	2026-02-05 08:35:00	2026-06-30 12:15:00	63.40	12	3	16400000.00	P6-12.08	RENTED	b3000000-0000-0000-0000-000000000002
b5000000-0000-0000-0000-000000000018	2026-02-05 08:40:00	2026-06-30 12:15:00	86.00	28	4	20500000.00	P6-28.11	RENTED	b3000000-0000-0000-0000-000000000002
b5000000-0000-0000-0000-000000000019	2026-02-05 08:45:00	2026-06-30 12:15:00	52.70	31	2	14900000.00	P6-31.07	EMPTY	b3000000-0000-0000-0000-000000000002
b5000000-0000-0000-0000-000000000021	2026-02-05 08:55:00	2026-06-30 12:20:00	55.60	11	2	10100000.00	A1-11.02	RENTED	b3000000-0000-0000-0000-000000000003
b5000000-0000-0000-0000-000000000022	2026-02-05 09:00:00	2026-06-30 12:20:00	76.20	28	3	12600000.00	A1-28.06	RENTED	b3000000-0000-0000-0000-000000000003
b5000000-0000-0000-0000-000000000024	2026-02-05 09:10:00	2026-06-30 12:25:00	44.80	5	2	10300000.00	LD-05.06	RENTED	b3000000-0000-0000-0000-000000000004
b5000000-0000-0000-0000-000000000025	2026-02-05 09:15:00	2026-06-30 12:25:00	62.50	16	3	12700000.00	LD-16.08	RENTED	b3000000-0000-0000-0000-000000000004
b5000000-0000-0000-0000-000000000026	2026-02-05 09:20:00	2026-06-30 12:25:00	88.50	24	4	17100000.00	LD-24.03	EMPTY	b3000000-0000-0000-0000-000000000004
b5000000-0000-0000-0000-000000000027	2026-02-05 09:25:00	2026-06-30 12:25:00	51.40	27	2	11400000.00	LD-27.09	EMPTY	b3000000-0000-0000-0000-000000000004
b5000000-0000-0000-0000-000000000020	2026-02-05 08:50:00	2026-07-27 08:24:59.137747	42.30	6	2	9200000.00	A1-06.12	EMPTY	b3000000-0000-0000-0000-000000000003
26962280-8932-4cc6-b92f-ac0b9a570cd0	2026-07-27 04:55:06.306553	2026-08-02 07:15:17.471689	500.00	1	9	5000000.00	0001	RENTED	c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e
b5000000-0000-0000-0000-000000000001	2026-01-10 08:15:00	2026-08-04 07:29:49.74164	52.00	12	3	12200000.00	T3-12.08	RENTED	b3000000-0000-0000-0000-000000000001
b5000000-0000-0000-0000-000000000003	2026-01-10 08:25:00	2026-08-04 08:12:47.103716	49.30	8	2	11600000.00	T3-08.11	RENTED	b3000000-0000-0000-0000-000000000001
95192562-e587-4da2-bac0-46d29aa261e9	2026-08-05 04:04:25.992273	2026-08-05 04:37:11.121805	300.00	1	10	12200000.00	0002	EMPTY	c4c909db-d1f8-4cd7-b4f4-b9e710b0d74e
e3d6477b-41ee-4b21-af42-6a9f042e6d08	2026-08-05 05:44:17.212015	2026-08-05 05:45:11.907831	15.00	1	3	6000000.00	001	RENTED	e9a22c20-ade9-4541-9a58-f2b10a870651
b8e262fa-62d0-4369-88f9-9f9bbeb5d1e6	2026-08-05 05:57:42.224184	2026-08-05 06:00:53.921865	20.00	1	2	7000000.00	002	RENTED	e9a22c20-ade9-4541-9a58-f2b10a870651
ce27f631-b495-48aa-9fc5-c60ec18a95eb	2026-08-06 15:16:14.748975	2026-08-06 15:16:44.135918	20.00	2	1	1000.00	004	RENTED	e9a22c20-ade9-4541-9a58-f2b10a870651
fcf45ae0-98ba-4018-8181-1a9dbab9a472	2026-08-06 15:51:25.393103	2026-08-06 15:52:47.002165	14.00	2	1	1000.00	005	RENTED	e9a22c20-ade9-4541-9a58-f2b10a870651
3697261c-44e6-4b47-9b9d-25277cc8da51	2026-08-06 15:09:01.393152	2026-08-21 01:49:58.682376	15.00	1	2	1000.00	003	RENTED	e9a22c20-ade9-4541-9a58-f2b10a870651
\.


--
-- Data for Name: sla_rules; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sla_rules (id, created_at, updated_at, category, max_hours, priority) FROM stdin;
029aed66-c6b5-4c63-b0f5-89964a3cf2ab	2026-07-27 09:42:15.068435	2026-07-27 09:42:15.068435	ELECTRIC	24	NORMAL
7cf683b1-5426-4dd2-89a1-36616cda5890	2026-07-27 09:42:21.235579	2026-07-27 09:42:21.235579	PLUMBING	24	NORMAL
7596978f-b9b0-45b9-9523-129df7299ba8	2026-07-27 09:42:28.682811	2026-07-27 09:42:28.682811	AIR_CONDITIONER	24	NORMAL
6e6ef82d-2192-4c24-9fed-7e5ade7c6ec8	2026-07-27 09:42:36.464994	2026-07-27 09:42:36.464994	FURNITURE	24	NORMAL
fcd7b29b-83f3-4f74-80ac-3373fb669b2a	2026-07-27 09:43:40.639854	2026-07-27 09:43:40.639854	ELECTRIC	6	HIGH
65654c72-ee5b-40f3-ab2b-31db7dc88011	2026-07-27 09:43:47.085043	2026-07-27 09:43:47.085043	PLUMBING	6	HIGH
9e402fcd-a031-4322-90c7-3dd9f317d2d5	2026-07-27 09:43:56.536788	2026-07-27 09:43:56.536788	AIR_CONDITIONER	12	HIGH
59991408-1e2d-4175-ab65-2656814c9f7e	2026-07-27 09:44:07.025783	2026-07-27 09:44:07.025783	FURNITURE	8	HIGH
8d40a734-a7ff-44d5-919a-670ac250d190	2026-07-27 09:44:13.921531	2026-07-27 09:44:13.921531	OTHER	12	HIGH
d8033b33-533d-4a1a-87fc-dfdb8923c92d	2026-07-27 09:44:34.933871	2026-07-27 09:44:34.933871	ELECTRIC	3	URGENT
3e0251f7-c4e7-464f-a743-e338a608585c	2026-07-27 09:44:41.283491	2026-07-27 09:44:41.283491	PLUMBING	3	URGENT
afff54a9-c61d-4271-8e75-bec78edfdf23	2026-07-27 09:44:45.702178	2026-07-27 09:44:45.702178	AIR_CONDITIONER	4	URGENT
ec42a598-6805-429e-b748-0dd3520a4aee	2026-07-27 09:44:52.791733	2026-07-27 09:44:52.791733	FURNITURE	4	URGENT
30ef1e7c-69a1-49a6-9fdd-2fc1e6bf1a66	2026-07-27 09:44:56.418021	2026-07-27 09:44:56.418021	OTHER	4	URGENT
1de0e179-7b0e-4dc8-bdb1-4954db4ddf67	2026-07-27 09:42:38.317392	2026-08-09 16:10:40.679862	OTHER	6	NORMAL
\.


--
-- Data for Name: upload_batch_items; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.upload_batch_items (id, created_at, updated_at, content_type, object_name, size_bytes, status, batch_id) FROM stdin;
6ce0773b-0ac1-435f-8880-1e91cfda512c	2026-08-22 13:40:53.518089	2026-08-22 13:40:53.518089	image/jpeg	https://pub-1415da6044694261bf385af30f6ca53a.r2.dev/maintenance/7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185/completion/2642929e-8cd8-423d-a2f0-1cc0a6384064.jpg	76573	UPLOADED	7cb2615a-a6c5-4f35-82f2-e54ad455954c
97afaf66-9f7b-408d-aa8b-3fdaabeccbff	2026-08-22 13:42:17.929723	2026-08-22 13:42:17.929723	image/jpeg	https://pub-1415da6044694261bf385af30f6ca53a.r2.dev/maintenance/pending-03134da6-90b2-4faa-a87c-ac9734045826/4cfd9783-933f-4ae8-93b4-82eaf5ec4b60.jpg	76573	UPLOADED	b1c8c7d5-19ab-4459-b438-6bab881e6ce9
48abeb8a-209e-4215-b468-99536f6a258e	2026-08-22 13:42:18.88491	2026-08-22 13:42:18.88491	video/mp4	https://pub-1415da6044694261bf385af30f6ca53a.r2.dev/maintenance/pending-03134da6-90b2-4faa-a87c-ac9734045826/video/d84817b6-fdce-4fe8-8673-32326d80b5d4.mp4	1306880	UPLOADED	b1c8c7d5-19ab-4459-b438-6bab881e6ce9
dabd2545-242d-46ff-8e40-5ec111c45834	2026-08-22 13:43:17.211097	2026-08-22 13:43:17.211097	image/jpeg	https://pub-1415da6044694261bf385af30f6ca53a.r2.dev/maintenance/69839fb2-7b7c-41fe-9a50-431b132a54ce/completion/2f30d99d-3134-4959-a218-2b883e3b1604.JPG	16613843	UPLOADED	5a18c634-ea69-4df9-abb0-d1cf2bf222dd
3d26a9e2-c9ac-430c-a1a3-22538cf89b9d	2026-08-22 13:43:28.944281	2026-08-22 13:43:28.944281	image/png	https://pub-1415da6044694261bf385af30f6ca53a.r2.dev/maintenance/69839fb2-7b7c-41fe-9a50-431b132a54ce/completion/82c4c466-2bbb-4f95-ab24-cf9c7c38d481.png	40834	UPLOADED	7a17960c-3121-4065-95c0-9b3cc1e0c57a
0ebf826d-e62a-4f70-8c2b-51ecd1d214d5	2026-08-22 13:46:14.764819	2026-08-22 13:46:14.764819	image/jpeg	https://pub-1415da6044694261bf385af30f6ca53a.r2.dev/maintenance/db9a9713-3331-441f-84c5-ea3e5abb1197/completion/a5f2310b-0dcc-498d-83b6-1af0ebe3dfac.jpg	150693	UPLOADED	2e4a2aa5-3afc-47aa-a4ae-d1be310728e1
53715471-280e-4d1f-b55c-37ea99051ad6	2026-08-22 13:46:40.192884	2026-08-22 13:46:40.192884	image/jpeg	https://pub-1415da6044694261bf385af30f6ca53a.r2.dev/maintenance/0f0f870b-8625-4306-84b4-61e3c78ae7e2/completion/8ad54522-d18e-45fd-83ac-e6edb0c3a905.jpg	271337	UPLOADED	a3d74633-bfc8-46e0-a80a-ee3f337eb57f
53944ce0-a750-49d5-850e-78fc805b8d77	2026-08-22 14:47:21.825987	2026-08-22 14:47:21.825987	image/png	https://pub-1415da6044694261bf385af30f6ca53a.r2.dev/maintenance/pending-3fd6cfbb-67a7-4937-b113-7c9f15c1ae2c/55f0faaf-6e01-47c5-92aa-00a7573b705b.png	233770	UPLOADED	dbca1919-a193-4ed7-98e2-560b35075a73
c4f39fb0-fc5c-4c1a-888f-7ef037c05f72	2026-08-22 14:47:22.929894	2026-08-22 14:47:22.929894	video/mp4	https://pub-1415da6044694261bf385af30f6ca53a.r2.dev/maintenance/pending-3fd6cfbb-67a7-4937-b113-7c9f15c1ae2c/video/59e3585c-35cf-457a-a5f1-c10a684c9399.mp4	1306880	UPLOADED	dbca1919-a193-4ed7-98e2-560b35075a73
ce77d4c2-235d-41e6-a55b-532c25602e05	2026-08-22 14:48:15.94451	2026-08-22 14:48:15.94451	image/png	https://pub-1415da6044694261bf385af30f6ca53a.r2.dev/maintenance/b7a2d2ad-c428-4c0d-8802-256afd8979d4/completion/a6a3834d-6611-4067-b17b-0f16f1231aa1.png	204898	UPLOADED	68966dc0-d662-4308-91e6-8a21d381f018
\.


--
-- Data for Name: upload_batches; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.upload_batches (id, created_at, updated_at, cleanup_required, domain_id, domain_type, idempotency_key, status) FROM stdin;
68966dc0-d662-4308-91e6-8a21d381f018	2026-08-22 14:48:15.52425	2026-08-22 14:48:16.223994	f	b7a2d2ad-c428-4c0d-8802-256afd8979d4	MAINTENANCE_COMPLETION	128cdcc7-b57c-4f73-bcc4-e0ef7aa7a376	COMPLETED
f71aa3f2-6c61-4a76-8cdd-dce4b0b38df3	2026-08-14 04:20:40.463923	2026-08-14 04:23:56.077992	f	\N	MAINTENANCE_REQUEST	53a74fae-8787-41f4-83c0-b4d24e4e0854	CLEANED
a9e23fdc-8983-4465-8a4b-2db93e7ed7d3	2026-08-14 04:23:26.061873	2026-08-14 04:23:56.078023	f	\N	MAINTENANCE_REQUEST	abba736e-ff5a-44d5-b1ee-2a3129fb985c	CLEANED
b62b7ffd-0fab-4468-a1fc-1cbe059ea1a8	2026-08-14 04:28:39.561696	2026-08-14 04:28:40.177823	f	c05e9333-2746-4b7f-9a01-8182f91ffa93	MAINTENANCE_REQUEST	63cfeef9-e35f-4bf4-a419-4fcaa7aa9f6b	COMPLETED
8954ecec-68e9-45be-9431-e10d5c3d6b60	2026-08-19 07:06:12.770195	2026-08-19 07:06:13.17024	f	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185	MAINTENANCE_REQUEST	1ed1fcb2-bb84-4efa-9e2e-08e3fb00ef9b	COMPLETED
9424e73d-ef80-4f99-a04b-0e5919be7734	2026-08-19 07:03:58.267974	2026-08-19 07:06:59.763499	f	\N	MAINTENANCE_REQUEST	e43b92e6-f39d-4a74-84b8-c631ff7fb791	CLEANED
ea3c082d-45a6-418e-a259-6861a98f02c9	2026-08-19 07:07:57.031265	2026-08-19 07:11:59.782232	f	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185	MAINTENANCE_COMPLETION	740336e0-6ed6-4601-b6b4-33b5a1759cfe	CLEANED
177606ac-4430-4596-8c51-dd8759d2d34d	2026-08-19 07:09:27.186666	2026-08-19 07:11:59.78227	f	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185	MAINTENANCE_COMPLETION	f1f3443b-29d9-4989-bd83-7599a07a5e3e	CLEANED
78024367-016d-4cc9-815d-ae7d810a7682	2026-08-19 07:09:37.198367	2026-08-19 07:11:59.782291	f	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185	MAINTENANCE_COMPLETION	559ec6f1-d7b7-4c0c-92ec-7c7872e779ac	CLEANED
e65f499d-80be-4dbd-8683-08a93051d84a	2026-08-21 01:50:43.375643	2026-08-21 01:52:04.246894	f	\N	MAINTENANCE_REQUEST	3df817d5-40e3-42cd-857b-5b804cb85a9e	CLEANED
1153ab70-34ea-4805-8119-b2d04ab8729e	2026-08-21 01:50:57.509159	2026-08-21 01:52:04.24692	f	\N	MAINTENANCE_REQUEST	71fb1c18-43fc-414f-9a4e-f906ec50077b	CLEANED
2132b145-64f4-449e-b0cd-7f04946d1eb8	2026-08-21 01:52:02.981114	2026-08-21 01:52:04.246937	f	\N	MAINTENANCE_REQUEST	20720170-bab0-4547-86e9-d2bea68d9f62	CLEANED
b2282fdd-a41e-4d04-a6e9-307645b13844	2026-08-21 01:52:12.15513	2026-08-21 01:52:12.189486	f	ea9d94f1-b8ff-45da-9312-91c673eaa885	MAINTENANCE_REQUEST	678ad593-b2d0-4d87-84fd-f68125b21f22	COMPLETED
894b1633-1d80-4fd9-be91-956b906804a7	2026-08-22 13:18:08.293391	2026-08-22 13:19:31.568244	f	0f0f870b-8625-4306-84b4-61e3c78ae7e2	MAINTENANCE_COMPLETION	a89710bf-1eac-4498-bae0-e97f0d400e98	CLEANED
29d6edca-35bb-4a35-a689-52e95918f921	2026-08-22 13:18:21.387189	2026-08-22 13:19:31.56833	f	0f0f870b-8625-4306-84b4-61e3c78ae7e2	MAINTENANCE_COMPLETION	c6640dcc-386f-441c-974e-babcab104089	CLEANED
7cb2615a-a6c5-4f35-82f2-e54ad455954c	2026-08-22 13:40:50.419304	2026-08-22 13:40:54.22111	f	7683ad3d-5bb9-4fb4-b18d-73fd7e1cd185	MAINTENANCE_COMPLETION	3c58dd56-6ff2-4d76-b7a4-c4c055df1033	COMPLETED
b1c8c7d5-19ab-4459-b438-6bab881e6ce9	2026-08-22 13:42:17.611514	2026-08-22 13:42:19.415032	f	69839fb2-7b7c-41fe-9a50-431b132a54ce	MAINTENANCE_REQUEST	d377f222-8224-4a18-8bbe-50a4ec3fe5fa	COMPLETED
5a18c634-ea69-4df9-abb0-d1cf2bf222dd	2026-08-22 13:43:10.411552	2026-08-22 13:43:17.414055	f	69839fb2-7b7c-41fe-9a50-431b132a54ce	MAINTENANCE_COMPLETION	8d8ebdf2-64de-43ad-8748-e9c50a25cd71	COMPLETED
7a17960c-3121-4065-95c0-9b3cc1e0c57a	2026-08-22 13:43:28.525824	2026-08-22 13:43:28.968833	f	69839fb2-7b7c-41fe-9a50-431b132a54ce	MAINTENANCE_COMPLETION	cb7188e2-3e50-4d8a-bd7e-6e5e8da2006e	COMPLETED
2e4a2aa5-3afc-47aa-a4ae-d1be310728e1	2026-08-22 13:46:14.485127	2026-08-22 13:46:14.818072	f	db9a9713-3331-441f-84c5-ea3e5abb1197	MAINTENANCE_COMPLETION	07be997b-5df7-424b-8f69-abc845dad695	COMPLETED
a3d74633-bfc8-46e0-a80a-ee3f337eb57f	2026-08-22 13:46:39.718207	2026-08-22 13:46:40.224018	f	0f0f870b-8625-4306-84b4-61e3c78ae7e2	MAINTENANCE_COMPLETION	7f675aa5-130b-4145-9628-ec9f6f958230	COMPLETED
dbca1919-a193-4ed7-98e2-560b35075a73	2026-08-22 14:47:18.627128	2026-08-22 14:47:23.633716	f	b7a2d2ad-c428-4c0d-8802-256afd8979d4	MAINTENANCE_REQUEST	6df10cda-0ad2-4b42-b92c-ca80a439bd53	COMPLETED
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, created_at, updated_at, is_active, avatar_url, email, full_name, password_hash, phone, role, specialties, auth_version) FROM stdin;
a0000000-0000-0000-0000-000000000002	2026-07-26 13:02:29.166456	2026-07-26 13:02:29.166456	t	\N	tenant@example.com	Nguyễn Văn A	$2a$10$2fmWQAXWyE1ZRBpssWHhjeEu1YbdaXSlHyQWntleOEP/7NVGc3Oke	0912345678	TENANT	\N	0
a0000000-0000-0000-0000-000000000003	2026-07-26 13:02:29.301035	2026-07-26 13:02:29.301035	t	\N	tech@example.com	Kỹ thuật viên B	$2a$10$hwlFSpr2KivOP1/.rYUy8.cjiz7aIm0BkzJU95bpH0aisJQQ8oX8O	0923456789	TECHNICIAN	\N	0
ca179c8b-b6e8-4dee-860f-796c1f933814	2026-07-26 13:09:01.172148	2026-07-26 13:09:01.172148	t	\N	haunguyen@htr.demo	Nguyễn Vủ Hậu	$2a$10$74fglEif5XrmNeAKnNHMwe7aA9gNXOR1xLky0YlzFZj4HkF9aFBeG	0123456789	ADMIN	\N	0
774a2c9e-8929-4d7c-80ca-14f62b9d9d56	2026-07-26 13:13:22.365011	2026-07-26 13:13:22.365011	t	\N	baonguyen@htr.demo	Nguyễn Đinh Gia Bảo	$2a$10$gQ8XwGiuf37.kbYRRo5GAuv3eTdwgXMu5lR.ZpbRD2Ja4A7gmGuVy		TECHNICIAN	\N	0
7b70cfa6-d414-4165-b17c-dde2c4aea3ba	2026-07-26 13:13:46.56289	2026-07-26 13:13:46.56289	t	\N	lamtran@htr.demo	Trần Bá Lãm	$2a$10$9ZIo6HgDORfE9avj6N91ZeGkWMiPeWp5CJvjEAVSdn5bGYqLMiYQW		TECHNICIAN	\N	0
b1000000-0000-0000-0000-000000000008	2026-01-07 09:15:00	2026-06-28 16:20:00	t	\N	tuankiet.vo@demo-htr.vn	Vo Tuan Kiet	$2a$10$fr3SC2uOVtvpzbUTU4.73O9u/PAe/2CFGO6fVN7k/MQwQ3HBvrjue	0916123008	TECHNICIAN	\N	0
b1000000-0000-0000-0000-000000000006	2026-01-06 10:40:00	2026-06-29 19:00:00	t	\N	hoangnam.doan@demo-htr.vn	Doan Hoang Nam	$2a$10$fr3SC2uOVtvpzbUTU4.73O9u/PAe/2CFGO6fVN7k/MQwQ3HBvrjue	0908123006	TENANT	\N	0
b1000000-0000-0000-0000-000000000016	2026-02-02 09:30:00	2026-06-30 12:00:00	t	\N	hamy.trinh@demo-htr.vn	Trinh Ha My	$2a$10$fr3SC2uOVtvpzbUTU4.73O9u/PAe/2CFGO6fVN7k/MQwQ3HBvrjue	0908123016	TENANT	\N	0
b1000000-0000-0000-0000-000000000002	2026-01-06 10:00:00	2026-06-29 18:40:00	t	\N	minhanh.nguyen@demo-htr.vn	Nguyen Minh Anh	$2a$10$fr3SC2uOVtvpzbUTU4.73O9u/PAe/2CFGO6fVN7k/MQwQ3HBvrjue	0908123002	TENANT	\N	0
b1000000-0000-0000-0000-000000000014	2026-02-02 09:20:00	2026-06-30 12:00:00	t	\N	ngocdiep.lam@demo-htr.vn	Lam Ngoc Diep	$2a$10$fr3SC2uOVtvpzbUTU4.73O9u/PAe/2CFGO6fVN7k/MQwQ3HBvrjue	0908123014	TENANT	\N	0
b1000000-0000-0000-0000-000000000012	2026-02-02 09:10:00	2026-06-30 12:00:00	t	\N	baongoc.huynh@demo-htr.vn	Huynh Bao Ngoc	$2a$10$fr3SC2uOVtvpzbUTU4.73O9u/PAe/2CFGO6fVN7k/MQwQ3HBvrjue	0908123012	TENANT	\N	0
b1000000-0000-0000-0000-000000000004	2026-01-06 10:20:00	2026-06-29 18:50:00	t	\N	quocbao.le@demo-htr.vn	Le Quoc Bao	$2a$10$fr3SC2uOVtvpzbUTU4.73O9u/PAe/2CFGO6fVN7k/MQwQ3HBvrjue	0908123004	TENANT	\N	0
b1000000-0000-0000-0000-000000000022	2026-02-02 10:00:00	2026-06-30 12:00:00	t	\N	minhtri.vo@demo-htr.vn	Vo Minh Tri	$2a$10$fr3SC2uOVtvpzbUTU4.73O9u/PAe/2CFGO6fVN7k/MQwQ3HBvrjue	0908123022	TENANT	\N	0
b1000000-0000-0000-0000-000000000021	2026-02-02 09:55:00	2026-06-30 12:00:00	t	\N	baochau.pham@demo-htr.vn	Pham Bao Chau	$2a$10$fr3SC2uOVtvpzbUTU4.73O9u/PAe/2CFGO6fVN7k/MQwQ3HBvrjue	0908123021	TENANT	\N	0
b1000000-0000-0000-0000-000000000020	2026-02-02 09:50:00	2026-06-30 12:00:00	t	\N	thaiha.nguyen@demo-htr.vn	Nguyen Thai Ha	$2a$10$fr3SC2uOVtvpzbUTU4.73O9u/PAe/2CFGO6fVN7k/MQwQ3HBvrjue	0908123020	TENANT	\N	0
b1000000-0000-0000-0000-000000000001	2026-01-05 08:30:00	2026-08-04 08:19:38.587273	f	\N	quan.hoang@demo-htr.vn	Hoang Minh Quan	$2a$10$fr3SC2uOVtvpzbUTU4.73O9u/PAe/2CFGO6fVN7k/MQwQ3HBvrjue	0909123001	ADMIN	\N	0
6db2e50d-7ec6-43ae-8317-7712967e02eb	2026-07-26 13:15:06.268662	2026-08-05 04:12:38.626403	t	\N	user1@htr.demo	Người Dùng 2	$2a$10$fr3SC2uOVtvpzbUTU4.73O9u/PAe/2CFGO6fVN7k/MQwQ3HBvrjue	0901234567	TENANT	\N	0
a0000000-0000-0000-0000-000000000001	2026-07-26 13:02:29.031214	2026-08-05 04:39:45.423577	t	\N	admin@example.com	Quản trị viên	$2a$10$VL1Qeg.K5HtaIU3TXBZuKuaGote/FnTH9G3gXo4UjKcVdM92ZLb6.	0909123456	ADMIN	\N	0
c5d65edf-fb24-4f93-b966-362f36e78370	2026-07-26 13:09:30.667816	2026-08-05 05:56:09.41847	t	\N	leminh@htr.demo	Lê Quốc Minh	$2a$10$Ee4lReFCrXGiohEK8.rLJuphFT/kepxaTtT46ssDL5nHLebjnPLKW	0123456789	ADMIN	\N	0
b1000000-0000-0000-0000-000000000009	2026-01-07 09:25:00	2026-06-28 16:25:00	t	\N	duchuy.phan@demo-htr.vn	Phan Duc Huy	$2a$10$fr3SC2uOVtvpzbUTU4.73O9u/PAe/2CFGO6fVN7k/MQwQ3HBvrjue	0916123009	TECHNICIAN	\N	0
b1000000-0000-0000-0000-000000000019	2026-02-02 09:45:00	2026-06-30 12:00:00	t	\N	vietlong.duong@demo-htr.vn	Duong Viet Long	$2a$10$fr3SC2uOVtvpzbUTU4.73O9u/PAe/2CFGO6fVN7k/MQwQ3HBvrjue	0908123019	TENANT	\N	0
b1000000-0000-0000-0000-000000000007	2026-01-06 10:50:00	2026-06-29 19:05:00	t	\N	khanhlinh.bui@demo-htr.vn	Bui Khanh Linh	$2a$10$fr3SC2uOVtvpzbUTU4.73O9u/PAe/2CFGO6fVN7k/MQwQ3HBvrjue	0908123007	TENANT	\N	0
b1000000-0000-0000-0000-000000000017	2026-02-02 09:35:00	2026-06-30 12:00:00	t	\N	ducanh.ta@demo-htr.vn	Ta Duc Anh	$2a$10$fr3SC2uOVtvpzbUTU4.73O9u/PAe/2CFGO6fVN7k/MQwQ3HBvrjue	0908123017	TENANT	\N	0
b1000000-0000-0000-0000-000000000013	2026-02-02 09:15:00	2026-06-30 12:00:00	t	\N	thanhtung.cao@demo-htr.vn	Cao Thanh Tung	$2a$10$fr3SC2uOVtvpzbUTU4.73O9u/PAe/2CFGO6fVN7k/MQwQ3HBvrjue	0908123013	TENANT	\N	0
b1000000-0000-0000-0000-000000000023	2026-02-02 10:05:00	2026-06-30 12:00:00	t	\N	ngoclam.tran@demo-htr.vn	Tran Ngoc Lam	$2a$10$fr3SC2uOVtvpzbUTU4.73O9u/PAe/2CFGO6fVN7k/MQwQ3HBvrjue	0908123023	TENANT	\N	0
b1000000-0000-0000-0000-000000000015	2026-02-02 09:25:00	2026-06-30 12:00:00	t	\N	quangvinh.ngo@demo-htr.vn	Ngo Quang Vinh	$2a$10$fr3SC2uOVtvpzbUTU4.73O9u/PAe/2CFGO6fVN7k/MQwQ3HBvrjue	0908123015	TENANT	\N	0
b1000000-0000-0000-0000-000000000010	2026-02-02 09:00:00	2026-06-30 12:00:00	t	\N	nhatminh.dang@demo-htr.vn	Dang Nhat Minh	$2a$10$fr3SC2uOVtvpzbUTU4.73O9u/PAe/2CFGO6fVN7k/MQwQ3HBvrjue	0908123010	TENANT	\N	0
b1000000-0000-0000-0000-000000000011	2026-02-02 09:05:00	2026-06-30 12:00:00	t	\N	phuongvy.mai@demo-htr.vn	Mai Phuong Vy	$2a$10$fr3SC2uOVtvpzbUTU4.73O9u/PAe/2CFGO6fVN7k/MQwQ3HBvrjue	0908123011	TENANT	\N	0
b1000000-0000-0000-0000-000000000018	2026-02-02 09:40:00	2026-06-30 12:00:00	t	\N	khanhchi.luu@demo-htr.vn	Luu Khanh Chi	$2a$10$fr3SC2uOVtvpzbUTU4.73O9u/PAe/2CFGO6fVN7k/MQwQ3HBvrjue	0908123018	TENANT	\N	0
f74117ad-4070-4b4a-ae8f-33ef8b763bd8	2026-08-04 07:19:55.011004	2026-08-04 07:19:55.011004	t	\N	chez1s.home@gmail.com	Duc Tri Bui	$2a$10$z2XHlOO/2wL9f4hEExds1uLk5lrs3XWwjlLuKBPKwmWtEXJfqIKUe		ADMIN	\N	0
3589890e-f56b-4dbc-84fc-12e319e1d750	2026-08-04 08:27:47.415724	2026-08-04 08:27:47.415724	t	\N	ngoctrai@demo-htr.vn	Phạm Ngọc Trai	$2a$10$2lNQ.nnBq5JZTPcjlWnSv.B5tMygFXGQhpik.pB5Uc58t.NrsApOq	0901234567	TENANT	\N	0
b1000000-0000-0000-0000-000000000003	2026-01-06 10:10:00	2026-08-05 04:18:24.509852	t	\N	giahan.tran@demo-htr.vn	Tran Gia Han	$2a$10$/FP96l7hxGpQs/THX/Rn9enhktym9DBwZjYhPt1TF09XBjFd8b2Ve	0908123003	TENANT	\N	0
74ccd53e-4998-49a3-97e3-b918b60f4080	2026-08-05 05:57:13.415992	2026-08-05 05:57:13.415992	t	\N	mainga@gmail.com	Nguyễn Thị Mai Nga	$2a$10$6i3Zscj.NavEKu/j5znwqO5ZmwGAVwGUEtV9ourlbvK/MwJaiV1V2	0987654321	TENANT	\N	0
b1000000-0000-0000-0000-000000000005	2026-01-06 10:30:00	2026-08-06 08:52:02.203	t	\N	thutrang.pham@demo-htr.vn	Pham Thu Trang	$2a$10$geO8p1RzmP4lKqNYAvNgzeO4CbgIsLcz.GC7gwsqMzZF5usiq69Gm	0908123005	TENANT	\N	0
33712636-202b-4ff3-8011-2da710d65035	2026-08-06 15:08:07.994066	2026-08-06 15:08:07.994066	t	\N	ducanh@gmail.com	Lê Đức Anh	$2a$10$g5BiPwBleuYBwRCv5CjOSeoeyvxbAhAWOVb/ISPGg2C51ZnNUH1Ty	0987654321	TENANT	\N	0
797e1cfb-d15e-4642-b968-faba2a872c4a	2026-08-06 15:51:59.796712	2026-08-06 15:51:59.796712	t	\N	minh@gmail.com	Minh Le Quốc	$2a$10$19Uq7V9jq5fqcRDlzr0Z8.x4cbH4DsjJHSvwUr6anK2RTmoWYI9iq	0987654321	TENANT	\N	0
936bdf00-c9f0-4889-80fc-86f3a59d051e	2026-08-19 07:01:49.664284	2026-08-19 07:01:49.664284	t	\N	ktvA@gmail.com	Kĩ Thuật Viên A	$2a$10$0Vddin8JlvUIDiblALYuoewDZ/InOiO26LD0vw6GexsQhnQCHkivG	0987654321	TECHNICIAN	\N	0
\.


--
-- Data for Name: vehicle_records; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vehicle_records (id, created_at, updated_at, bicycle_count, car_count, motorbike_count, record_month, room_id) FROM stdin;
\.


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: contracts contracts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contracts
    ADD CONSTRAINT contracts_pkey PRIMARY KEY (id);


--
-- Name: fee_configs fee_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fee_configs
    ADD CONSTRAINT fee_configs_pkey PRIMARY KEY (id);


--
-- Name: invoices invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_pkey PRIMARY KEY (id);


--
-- Name: maintenance_materials maintenance_materials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_materials
    ADD CONSTRAINT maintenance_materials_pkey PRIMARY KEY (id);


--
-- Name: maintenance_notes maintenance_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_notes
    ADD CONSTRAINT maintenance_notes_pkey PRIMARY KEY (id);


--
-- Name: maintenance_requests maintenance_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_requests
    ADD CONSTRAINT maintenance_requests_pkey PRIMARY KEY (id);


--
-- Name: maintenance_reviews maintenance_reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_reviews
    ADD CONSTRAINT maintenance_reviews_pkey PRIMARY KEY (id);


--
-- Name: meter_readings meter_readings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meter_readings
    ADD CONSTRAINT meter_readings_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: payment_event_receipts payment_event_receipts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_event_receipts
    ADD CONSTRAINT payment_event_receipts_pkey PRIMARY KEY (id);


--
-- Name: payment_intents payment_intents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_intents
    ADD CONSTRAINT payment_intents_pkey PRIMARY KEY (id);


--
-- Name: properties properties_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties
    ADD CONSTRAINT properties_pkey PRIMARY KEY (id);


--
-- Name: property_types property_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.property_types
    ADD CONSTRAINT property_types_pkey PRIMARY KEY (id);


--
-- Name: room_notes room_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_notes
    ADD CONSTRAINT room_notes_pkey PRIMARY KEY (id);


--
-- Name: rooms rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT rooms_pkey PRIMARY KEY (id);


--
-- Name: sla_rules sla_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sla_rules
    ADD CONSTRAINT sla_rules_pkey PRIMARY KEY (id);


--
-- Name: users uk6dotkott2kjsp8vw4d0m25fb7; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT uk6dotkott2kjsp8vw4d0m25fb7 UNIQUE (email);


--
-- Name: rooms uk7s0egtid5n0bnl3bp5gky363p; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT uk7s0egtid5n0bnl3bp5gky363p UNIQUE (property_id, room_number);


--
-- Name: property_types uk9batpytvjmqq6ffd1m6hl6f65; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.property_types
    ADD CONSTRAINT uk9batpytvjmqq6ffd1m6hl6f65 UNIQUE (code);


--
-- Name: fee_configs ukc6w98o78bahdtcr6rh4g2ddyj; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fee_configs
    ADD CONSTRAINT ukc6w98o78bahdtcr6rh4g2ddyj UNIQUE (property_id);


--
-- Name: invoices ukce5sakiuequenkvtpxkc9r5gq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT ukce5sakiuequenkvtpxkc9r5gq UNIQUE (room_id, invoice_month);


--
-- Name: upload_batches ukghpjf630hdq7db1jog4842rpq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.upload_batches
    ADD CONSTRAINT ukghpjf630hdq7db1jog4842rpq UNIQUE (idempotency_key);


--
-- Name: payment_event_receipts ukif4v051y7sff2wfof6uyfuidl; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_event_receipts
    ADD CONSTRAINT ukif4v051y7sff2wfof6uyfuidl UNIQUE (event_key);


--
-- Name: payment_intents ukkpxs8vx3qfqoy6v7lywovuvs3; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_intents
    ADD CONSTRAINT ukkpxs8vx3qfqoy6v7lywovuvs3 UNIQUE (order_code);


--
-- Name: vehicle_records ukprs7rh4qandy9pxaweg2xr8pm; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_records
    ADD CONSTRAINT ukprs7rh4qandy9pxaweg2xr8pm UNIQUE (room_id, record_month);


--
-- Name: meter_readings uktc58ahse5sqo7sdw0fs6sxcyw; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meter_readings
    ADD CONSTRAINT uktc58ahse5sqo7sdw0fs6sxcyw UNIQUE (room_id, reading_month);


--
-- Name: upload_batch_items upload_batch_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.upload_batch_items
    ADD CONSTRAINT upload_batch_items_pkey PRIMARY KEY (id);


--
-- Name: upload_batches upload_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.upload_batches
    ADD CONSTRAINT upload_batches_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vehicle_records vehicle_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_records
    ADD CONSTRAINT vehicle_records_pkey PRIMARY KEY (id);


--
-- Name: maintenance_reviews fk21od1cdq8pwvhrn7depda9rvw; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_reviews
    ADD CONSTRAINT fk21od1cdq8pwvhrn7depda9rvw FOREIGN KEY (technician_id) REFERENCES public.users(id);


--
-- Name: properties fk32k2h9s30s0ukftb8hj947ef2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties
    ADD CONSTRAINT fk32k2h9s30s0ukftb8hj947ef2 FOREIGN KEY (owner_id) REFERENCES public.users(id);


--
-- Name: rooms fk35r032kwh410ggyqcbqrnhcut; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT fk35r032kwh410ggyqcbqrnhcut FOREIGN KEY (property_id) REFERENCES public.properties(id);


--
-- Name: maintenance_requests fk36gtbymrxk1glfp8at3vsg19y; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_requests
    ADD CONSTRAINT fk36gtbymrxk1glfp8at3vsg19y FOREIGN KEY (assigned_to) REFERENCES public.users(id);


--
-- Name: maintenance_preferred_slots fk4a8o73posk9tppibqfu5t2hsk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_preferred_slots
    ADD CONSTRAINT fk4a8o73posk9tppibqfu5t2hsk FOREIGN KEY (request_id) REFERENCES public.maintenance_requests(id);


--
-- Name: room_notes fk4kk5ytv1vbce0sboappu2dh7t; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_notes
    ADD CONSTRAINT fk4kk5ytv1vbce0sboappu2dh7t FOREIGN KEY (room_id) REFERENCES public.rooms(id);


--
-- Name: maintenance_completion_images fk6lcvaen0cotjab5xdmd2dlwso; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_completion_images
    ADD CONSTRAINT fk6lcvaen0cotjab5xdmd2dlwso FOREIGN KEY (request_id) REFERENCES public.maintenance_requests(id);


--
-- Name: payment_intents fk8d5o0e14e7pi75wj8tiddlcvr; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_intents
    ADD CONSTRAINT fk8d5o0e14e7pi75wj8tiddlcvr FOREIGN KEY (invoice_id) REFERENCES public.invoices(id);


--
-- Name: maintenance_notes fk9qtjotkneka6wxa3c0oyhtnut; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_notes
    ADD CONSTRAINT fk9qtjotkneka6wxa3c0oyhtnut FOREIGN KEY (actor_id) REFERENCES public.users(id);


--
-- Name: notifications fk9y21adhxn0ayjhfocscqox7bh; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk9y21adhxn0ayjhfocscqox7bh FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: maintenance_materials fkcehospb6yt4vytoxrdsp2ew5b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_materials
    ADD CONSTRAINT fkcehospb6yt4vytoxrdsp2ew5b FOREIGN KEY (request_id) REFERENCES public.maintenance_requests(id);


--
-- Name: maintenance_requests fkcndie7sbh4o14jhu4yvro53jy; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_requests
    ADD CONSTRAINT fkcndie7sbh4o14jhu4yvro53jy FOREIGN KEY (room_id) REFERENCES public.rooms(id);


--
-- Name: invoices fkdyk9stbe14c67a8x3pcqg6k5f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT fkdyk9stbe14c67a8x3pcqg6k5f FOREIGN KEY (room_id) REFERENCES public.rooms(id);


--
-- Name: invoices fkeads7q9fktwtsgdwmp1x16eqc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT fkeads7q9fktwtsgdwmp1x16eqc FOREIGN KEY (contract_id) REFERENCES public.contracts(id);


--
-- Name: vehicle_records fkf94b26gj79i5x35re0neofsgo; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_records
    ADD CONSTRAINT fkf94b26gj79i5x35re0neofsgo FOREIGN KEY (room_id) REFERENCES public.rooms(id);


--
-- Name: meter_readings fkfcfh4ant2u95m90uf1ok8mb6m; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meter_readings
    ADD CONSTRAINT fkfcfh4ant2u95m90uf1ok8mb6m FOREIGN KEY (room_id) REFERENCES public.rooms(id);


--
-- Name: room_notes fki52q627uh2k6vik426le7cs6k; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_notes
    ADD CONSTRAINT fki52q627uh2k6vik426le7cs6k FOREIGN KEY (author_id) REFERENCES public.users(id);


--
-- Name: maintenance_reviews fkihr1aknn8nb8fkm9e5j9212rb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_reviews
    ADD CONSTRAINT fkihr1aknn8nb8fkm9e5j9212rb FOREIGN KEY (request_id) REFERENCES public.maintenance_requests(id);


--
-- Name: upload_batch_items fkjd533c3by59mbn5ljoopicxy1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.upload_batch_items
    ADD CONSTRAINT fkjd533c3by59mbn5ljoopicxy1 FOREIGN KEY (batch_id) REFERENCES public.upload_batches(id);


--
-- Name: contracts fkju1b0xobla9t8oexrb8lpi8jq; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contracts
    ADD CONSTRAINT fkju1b0xobla9t8oexrb8lpi8jq FOREIGN KEY (room_id) REFERENCES public.rooms(id);


--
-- Name: maintenance_requests fkm1h380tkvba23mb1lfpb404t0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_requests
    ADD CONSTRAINT fkm1h380tkvba23mb1lfpb404t0 FOREIGN KEY (tenant_id) REFERENCES public.users(id);


--
-- Name: maintenance_notes fkmjgl437efs2tvvwpfuoyeutwc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_notes
    ADD CONSTRAINT fkmjgl437efs2tvvwpfuoyeutwc FOREIGN KEY (request_id) REFERENCES public.maintenance_requests(id);


--
-- Name: maintenance_reviews fknlabficldkk31wchxdqrvuhdo; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_reviews
    ADD CONSTRAINT fknlabficldkk31wchxdqrvuhdo FOREIGN KEY (tenant_id) REFERENCES public.users(id);


--
-- Name: meter_readings fknlr3cadcl4cgtbj7qf66obv4g; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meter_readings
    ADD CONSTRAINT fknlr3cadcl4cgtbj7qf66obv4g FOREIGN KEY (recorded_by) REFERENCES public.users(id);


--
-- Name: maintenance_images fkpdb2qj1gjaanrl19cgxojnv6h; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_images
    ADD CONSTRAINT fkpdb2qj1gjaanrl19cgxojnv6h FOREIGN KEY (request_id) REFERENCES public.maintenance_requests(id);


--
-- Name: fee_configs fkqn1bpxm5pon0nl80b6dlifj2s; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fee_configs
    ADD CONSTRAINT fkqn1bpxm5pon0nl80b6dlifj2s FOREIGN KEY (property_id) REFERENCES public.properties(id);


--
-- Name: contracts fkra7p26cb32ydditq6ab80pv6l; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contracts
    ADD CONSTRAINT fkra7p26cb32ydditq6ab80pv6l FOREIGN KEY (tenant_id) REFERENCES public.users(id);


--
-- Name: properties fksnlo5na1p1eo5m5wlblbfuuce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.properties
    ADD CONSTRAINT fksnlo5na1p1eo5m5wlblbfuuce FOREIGN KEY (type) REFERENCES public.property_types(id);


--
-- Name: room_images fktky1jnwoh1hv50m263p2vlt0y; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_images
    ADD CONSTRAINT fktky1jnwoh1hv50m263p2vlt0y FOREIGN KEY (room_id) REFERENCES public.rooms(id);


--
-- PostgreSQL database dump complete
--

\unrestrict up8FhLKfDkgz3TBB0CkeVIeTwFETF3gaLMvhw82eBUZqNjbWXrZVt8s3UTJ1e75

