--
-- PostgreSQL database dump
--

\restrict WNUTDz6CVPCE4NjdJtbxnmZAyMEkhVWQtfccpkJKGphq0ELbKYb8GVkpNZ41led

-- Dumped from database version 15.14 (Debian 15.14-1.pgdg13+1)
-- Dumped by pg_dump version 15.14 (Debian 15.14-1.pgdg13+1)

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
-- Name: public; Type: SCHEMA; Schema: -; Owner: trace
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO trace;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: trace
--

COMMENT ON SCHEMA public IS '';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: sync_verified_flag(); Type: FUNCTION; Schema: public; Owner: trace
--

CREATE FUNCTION public.sync_verified_flag() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.verified := (NEW.status = 'verified');
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.sync_verified_flag() OWNER TO trace;

--
-- Name: trg_update_timestamp(); Type: FUNCTION; Schema: public; Owner: trace
--

CREATE FUNCTION public.trg_update_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_update_timestamp() OWNER TO trace;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.audit_logs (
    id integer NOT NULL,
    tenant_id integer,
    "user" character varying(255),
    method character varying(8),
    path character varying(255),
    status integer,
    ip character varying(64),
    payload jsonb,
    created_at timestamp without time zone
);


ALTER TABLE public.audit_logs OWNER TO trace;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.audit_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.audit_logs_id_seq OWNER TO trace;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: batch_clone_audit; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.batch_clone_audit (
    id integer NOT NULL,
    actor text NOT NULL,
    actor_role text,
    ip_address text,
    parent_batch_code text NOT NULL,
    child_batch_code text NOT NULL,
    used_quantity numeric(18,3),
    unit text,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.batch_clone_audit OWNER TO trace;

--
-- Name: batch_clone_audit_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.batch_clone_audit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.batch_clone_audit_id_seq OWNER TO trace;

--
-- Name: batch_clone_audit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.batch_clone_audit_id_seq OWNED BY public.batch_clone_audit.id;


--
-- Name: batch_lineage; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.batch_lineage (
    id integer NOT NULL,
    parent_batch_id integer,
    child_batch_id integer,
    event_id integer,
    transformation_type text,
    created_at timestamp with time zone DEFAULT now(),
    tenant_id integer
);


ALTER TABLE public.batch_lineage OWNER TO trace;

--
-- Name: batch_lineage_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.batch_lineage_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.batch_lineage_id_seq OWNER TO trace;

--
-- Name: batch_lineage_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.batch_lineage_id_seq OWNED BY public.batch_lineage.id;


--
-- Name: batch_links; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.batch_links (
    id integer NOT NULL,
    parent_batch_id integer NOT NULL,
    child_batch_id integer NOT NULL,
    material_used numeric(12,3),
    unit character varying(10) DEFAULT 'kg'::character varying,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.batch_links OWNER TO trace;

--
-- Name: batch_links_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.batch_links_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.batch_links_id_seq OWNER TO trace;

--
-- Name: batch_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.batch_links_id_seq OWNED BY public.batch_links.id;


--
-- Name: batch_usage_log; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.batch_usage_log (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    parent_batch_id integer NOT NULL,
    child_batch_id integer,
    event_id integer,
    used_quantity numeric(18,3) NOT NULL,
    unit character varying(50) DEFAULT 'kg'::character varying,
    purpose text,
    note text,
    created_at timestamp without time zone DEFAULT now(),
    created_by character varying(100)
);


ALTER TABLE public.batch_usage_log OWNER TO trace;

--
-- Name: batch_usage_log_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.batch_usage_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.batch_usage_log_id_seq OWNER TO trace;

--
-- Name: batch_usage_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.batch_usage_log_id_seq OWNED BY public.batch_usage_log.id;


--
-- Name: batch_usages; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.batch_usages (
    id integer NOT NULL,
    parent_batch_id integer,
    child_batch_id integer,
    used_quantity numeric(18,3) NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.batch_usages OWNER TO trace;

--
-- Name: batch_usages_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.batch_usages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.batch_usages_id_seq OWNER TO trace;

--
-- Name: batch_usages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.batch_usages_id_seq OWNED BY public.batch_usages.id;


--
-- Name: batches; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.batches (
    id integer NOT NULL,
    code character varying(255) NOT NULL,
    product_code character varying(64) NOT NULL,
    mfg_date date,
    country character varying(64),
    status character varying(32),
    parent_batch_id integer,
    created_at timestamp without time zone DEFAULT now(),
    tenant_id integer NOT NULL,
    blockchain_tx_hash character varying(100),
    material_type character varying(64),
    description text,
    origin_farm_id integer,
    source_epcis_id integer,
    certificates jsonb,
    origin jsonb,
    farm_id integer,
    supplier_id integer,
    farm_batch_id integer,
    supplier_batch_id integer,
    manufacturer_batch_id integer,
    brand_batch_id integer,
    farm_batch_code character varying(64),
    supplier_batch_code character varying(64),
    manufacturer_batch_code character varying(64),
    brand_batch_code character varying(64),
    quantity numeric(12,3),
    unit character varying(10),
    owner_role character varying(50),
    level character varying(50),
    next_level_cloned_at timestamp without time zone,
    remaining_quantity numeric(14,3),
    used_quantity numeric(18,3) DEFAULT 0,
    converted_from_unit text,
    converted_rate numeric(18,6),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.batches OWNER TO trace;

--
-- Name: batches_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.batches_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.batches_id_seq OWNER TO trace;

--
-- Name: batches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.batches_id_seq OWNED BY public.batches.id;


--
-- Name: blockchain_anchors; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.blockchain_anchors (
    id integer NOT NULL,
    tenant_id integer,
    anchor_type character varying(64),
    ref character varying(255),
    tx_hash character varying(128),
    network character varying(64),
    meta jsonb,
    bundle_id character varying(255),
    batch_hash character varying(128),
    block_number bigint,
    status character varying(32) DEFAULT 'pending'::character varying,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    dpp_id integer,
    epcis_event_id integer,
    ipfs_cid character varying(255)
);


ALTER TABLE public.blockchain_anchors OWNER TO trace;

--
-- Name: blockchain_anchors_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.blockchain_anchors_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.blockchain_anchors_id_seq OWNER TO trace;

--
-- Name: blockchain_anchors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.blockchain_anchors_id_seq OWNED BY public.blockchain_anchors.id;


--
-- Name: blockchain_proofs; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.blockchain_proofs (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    batch_code character varying(255) NOT NULL,
    network character varying(100) DEFAULT 'polygon'::character varying,
    tx_hash character varying(255),
    block_number bigint,
    root_hash character varying(255) NOT NULL,
    status character varying(50) DEFAULT 'PENDING'::character varying,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    contract_address character varying(255),
    published_by character varying(255),
    published_at timestamp with time zone
);


ALTER TABLE public.blockchain_proofs OWNER TO trace;

--
-- Name: blockchain_proofs_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.blockchain_proofs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.blockchain_proofs_id_seq OWNER TO trace;

--
-- Name: blockchain_proofs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.blockchain_proofs_id_seq OWNED BY public.blockchain_proofs.id;


--
-- Name: brands; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.brands (
    id integer NOT NULL,
    name character varying(128) NOT NULL,
    owner character varying(128),
    website character varying(255),
    created_at timestamp without time zone DEFAULT now(),
    tenant_id integer
);


ALTER TABLE public.brands OWNER TO trace;

--
-- Name: brands_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.brands_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.brands_id_seq OWNER TO trace;

--
-- Name: brands_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.brands_id_seq OWNED BY public.brands.id;


--
-- Name: compliance_results; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.compliance_results (
    id integer NOT NULL,
    tenant_id integer,
    batch_code character varying(64),
    scheme character varying(64),
    pass_flag boolean,
    details jsonb
);


ALTER TABLE public.compliance_results OWNER TO trace;

--
-- Name: compliance_results_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.compliance_results_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.compliance_results_id_seq OWNER TO trace;

--
-- Name: compliance_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.compliance_results_id_seq OWNED BY public.compliance_results.id;


--
-- Name: configs_blockchain; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.configs_blockchain (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    chain_name character varying(64) NOT NULL,
    rpc_url character varying(255) NOT NULL,
    contract_address character varying(255) NOT NULL,
    network character varying(64),
    abi_id integer,
    is_default boolean DEFAULT true,
    config_json jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    description character varying(255),
    version text DEFAULT 'v2'::text,
    updated_by text DEFAULT 'system'::text,
    private_key text
);


ALTER TABLE public.configs_blockchain OWNER TO trace;

--
-- Name: configs_blockchain_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.configs_blockchain_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.configs_blockchain_id_seq OWNER TO trace;

--
-- Name: configs_blockchain_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.configs_blockchain_id_seq OWNED BY public.configs_blockchain.id;


--
-- Name: credentials; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.credentials (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id integer,
    subject character varying(255),
    type character varying(64),
    jws text,
    status character varying(32),
    hash_hex character varying(128),
    created_at timestamp without time zone DEFAULT now(),
    issued_at timestamp without time zone,
    vc_payload jsonb,
    proof_tx character varying(128),
    chain character varying(64),
    public_key_base64 character varying(255),
    document_id integer,
    doc_bundle_id character varying(64),
    verified boolean DEFAULT false,
    verify_error text,
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.credentials OWNER TO trace;

--
-- Name: credentials_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.credentials_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.credentials_id_seq OWNER TO trace;

--
-- Name: credentials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.credentials_id_seq OWNED BY public.credentials.id;


--
-- Name: customers; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.customers (
    id integer NOT NULL,
    code character varying(64) NOT NULL,
    name character varying(255) NOT NULL,
    country character varying(64),
    contact_email character varying(255),
    created_at timestamp without time zone DEFAULT now(),
    tenant_id integer
);


ALTER TABLE public.customers OWNER TO trace;

--
-- Name: customers_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.customers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.customers_id_seq OWNER TO trace;

--
-- Name: customers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.customers_id_seq OWNED BY public.customers.id;


--
-- Name: customs; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.customs (
    id integer NOT NULL,
    customer_id integer NOT NULL,
    document_number character varying(128) NOT NULL,
    country character varying(128) NOT NULL,
    tenant_id integer
);


ALTER TABLE public.customs OWNER TO trace;

--
-- Name: customs_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.customs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.customs_id_seq OWNER TO trace;

--
-- Name: customs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.customs_id_seq OWNED BY public.customs.id;


--
-- Name: data_sharing_agreements; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.data_sharing_agreements (
    id integer NOT NULL,
    tenant_id integer,
    partner character varying(255),
    scope jsonb,
    terms jsonb
);


ALTER TABLE public.data_sharing_agreements OWNER TO trace;

--
-- Name: data_sharing_agreements_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.data_sharing_agreements_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.data_sharing_agreements_id_seq OWNER TO trace;

--
-- Name: data_sharing_agreements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.data_sharing_agreements_id_seq OWNED BY public.data_sharing_agreements.id;


--
-- Name: documents; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.documents (
    id integer NOT NULL,
    tenant_id integer,
    title character varying(255),
    hash character varying(128),
    path character varying(512),
    meta jsonb,
    file_name character varying(255),
    file_type character varying(128),
    file_size bigint,
    file_hash character varying(128),
    vc_payload jsonb,
    issued_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    vc_id uuid,
    doc_bundle_id character varying(64),
    hash_hex character varying(128),
    vc_hash_hex character varying(128),
    verified boolean DEFAULT false,
    batch_code character varying(64)
);


ALTER TABLE public.documents OWNER TO trace;

--
-- Name: documents_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.documents_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.documents_id_seq OWNER TO trace;

--
-- Name: documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.documents_id_seq OWNED BY public.documents.id;


--
-- Name: domains; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.domains (
    id integer NOT NULL,
    name character varying(128) NOT NULL,
    code character varying(64) NOT NULL,
    tenant_id integer
);


ALTER TABLE public.domains OWNER TO trace;

--
-- Name: domains_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.domains_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.domains_id_seq OWNER TO trace;

--
-- Name: domains_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.domains_id_seq OWNED BY public.domains.id;


--
-- Name: dpp_passports; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.dpp_passports (
    id integer NOT NULL,
    tenant_id integer,
    product_code character varying(64),
    payload jsonb,
    version character varying(16) DEFAULT '1.0'::character varying,
    batch_id integer,
    status character varying(32) DEFAULT 'draft'::character varying,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    product_description jsonb,
    composition jsonb,
    supply_chain jsonb,
    transport jsonb,
    documentation jsonb,
    environmental_impact jsonb,
    social_impact jsonb,
    animal_welfare jsonb,
    circularity jsonb,
    health_safety jsonb,
    brand_info jsonb,
    digital_identity jsonb,
    quantity_info jsonb,
    cost_info jsonb,
    use_phase jsonb,
    end_of_life jsonb,
    linked_epcis jsonb,
    linked_blockchain jsonb
);


ALTER TABLE public.dpp_passports OWNER TO trace;

--
-- Name: dpp_passports_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.dpp_passports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dpp_passports_id_seq OWNER TO trace;

--
-- Name: dpp_passports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.dpp_passports_id_seq OWNED BY public.dpp_passports.id;


--
-- Name: dpp_templates; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.dpp_templates (
    id integer NOT NULL,
    name character varying(128) NOT NULL,
    schema jsonb DEFAULT '{}'::jsonb NOT NULL,
    tenant_id integer,
    tier character varying(32) DEFAULT 'supplier'::character varying NOT NULL,
    template_name character varying(128) DEFAULT 'default'::character varying NOT NULL,
    product_id integer,
    static_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    dynamic_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.dpp_templates OWNER TO trace;

--
-- Name: dpp_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.dpp_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dpp_templates_id_seq OWNER TO trace;

--
-- Name: dpp_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.dpp_templates_id_seq OWNED BY public.dpp_templates.id;


--
-- Name: emissions; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.emissions (
    id integer NOT NULL,
    batch_id integer NOT NULL,
    co2_kg double precision NOT NULL,
    recorded_at timestamp without time zone DEFAULT now() NOT NULL,
    tenant_id integer
);


ALTER TABLE public.emissions OWNER TO trace;

--
-- Name: emissions_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.emissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.emissions_id_seq OWNER TO trace;

--
-- Name: emissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.emissions_id_seq OWNED BY public.emissions.id;


--
-- Name: epcis_events; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.epcis_events (
    id integer NOT NULL,
    tenant_id integer,
    event_type character varying(128),
    batch_code character varying(255),
    product_code character varying(255),
    event_time timestamp with time zone,
    action character varying(10),
    biz_step character varying(128),
    disposition character varying(128),
    read_point character varying(255),
    biz_location character varying(255),
    epc_list jsonb,
    ilmd jsonb,
    extensions jsonb,
    event_time_zone_offset character varying(10),
    biz_transaction_list jsonb,
    context jsonb DEFAULT '[]'::jsonb,
    event_id text,
    event_hash text,
    doc_bundle_id character varying(255),
    vc_hash_hex text,
    verified boolean DEFAULT false,
    verify_error text,
    raw_payload jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    batch_id integer,
    dpp_id integer,
    dpp_passport_id integer,
    is_active boolean DEFAULT true,
    material_name character varying(255),
    owner_role character varying(50),
    input_quantity numeric(14,3),
    input_uom character varying(10),
    output_quantity numeric(14,3),
    output_uom character varying(10),
    last_modified_by character varying(64),
    last_modified_at timestamp without time zone
);


ALTER TABLE public.epcis_events OWNER TO trace;

--
-- Name: epcis_events_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.epcis_events_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.epcis_events_id_seq OWNER TO trace;

--
-- Name: epcis_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.epcis_events_id_seq OWNED BY public.epcis_events.id;


--
-- Name: events; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.events (
    id integer NOT NULL,
    batch_code character varying(64) NOT NULL,
    product_code character varying(64) NOT NULL,
    event_time timestamp without time zone,
    biz_step character varying(128),
    disposition character varying(128),
    data jsonb,
    tenant_id integer
);


ALTER TABLE public.events OWNER TO trace;

--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.events_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.events_id_seq OWNER TO trace;

--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.events_id_seq OWNED BY public.events.id;


--
-- Name: fabric_events; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.fabric_events (
    id integer NOT NULL,
    tx_id character varying(128),
    block_number bigint,
    chaincode_id character varying(128),
    event_name character varying(128),
    payload jsonb,
    status character varying(32) DEFAULT 'RECEIVED'::character varying,
    ts timestamp without time zone DEFAULT now(),
    tenant_id integer
);


ALTER TABLE public.fabric_events OWNER TO trace;

--
-- Name: fabric_events_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.fabric_events_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fabric_events_id_seq OWNER TO trace;

--
-- Name: fabric_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.fabric_events_id_seq OWNED BY public.fabric_events.id;


--
-- Name: farms; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.farms (
    id integer NOT NULL,
    tenant_id integer,
    name character varying(128) NOT NULL,
    code character varying(64),
    gln character varying(64),
    location jsonb,
    size_ha numeric,
    certification jsonb,
    contact_info jsonb,
    created_at timestamp with time zone DEFAULT now(),
    farm_type character varying(64),
    status character varying(32) DEFAULT 'active'::character varying,
    extra_data jsonb DEFAULT '{}'::jsonb
);


ALTER TABLE public.farms OWNER TO trace;

--
-- Name: farms_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.farms_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.farms_id_seq OWNER TO trace;

--
-- Name: farms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.farms_id_seq OWNED BY public.farms.id;


--
-- Name: materials; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.materials (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    name character varying(255) NOT NULL,
    scientific_name character varying(255),
    stages jsonb,
    dpp_notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.materials OWNER TO trace;

--
-- Name: materials_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.materials_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.materials_id_seq OWNER TO trace;

--
-- Name: materials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.materials_id_seq OWNED BY public.materials.id;


--
-- Name: polygon_abi; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.polygon_abi (
    id integer NOT NULL,
    name text,
    abi jsonb,
    created_at timestamp without time zone DEFAULT now(),
    tenant_id integer
);


ALTER TABLE public.polygon_abi OWNER TO trace;

--
-- Name: polygon_abi_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.polygon_abi_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.polygon_abi_id_seq OWNER TO trace;

--
-- Name: polygon_abi_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.polygon_abi_id_seq OWNED BY public.polygon_abi.id;


--
-- Name: polygon_anchors; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.polygon_anchors (
    id integer NOT NULL,
    tx_hash character varying(100),
    anchor_type character varying(50),
    ref_id character varying(64),
    status character varying(32),
    ts timestamp without time zone DEFAULT now(),
    meta jsonb,
    tenant_id integer,
    network character varying(64),
    block_number bigint,
    is_active boolean DEFAULT true,
    dpp_passport_id integer,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.polygon_anchors OWNER TO trace;

--
-- Name: polygon_anchors_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.polygon_anchors_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.polygon_anchors_id_seq OWNER TO trace;

--
-- Name: polygon_anchors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.polygon_anchors_id_seq OWNED BY public.polygon_anchors.id;


--
-- Name: polygon_logs; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.polygon_logs (
    id integer NOT NULL,
    tx_hash character varying(128),
    method character varying(128),
    params jsonb,
    result jsonb,
    tenant_id integer
);


ALTER TABLE public.polygon_logs OWNER TO trace;

--
-- Name: polygon_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.polygon_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.polygon_logs_id_seq OWNER TO trace;

--
-- Name: polygon_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.polygon_logs_id_seq OWNED BY public.polygon_logs.id;


--
-- Name: polygon_subscriptions; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.polygon_subscriptions (
    id integer NOT NULL,
    anchor_id integer NOT NULL,
    event_name character varying(128) NOT NULL,
    callback_url character varying(255) NOT NULL,
    tenant_id integer
);


ALTER TABLE public.polygon_subscriptions OWNER TO trace;

--
-- Name: polygon_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.polygon_subscriptions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.polygon_subscriptions_id_seq OWNER TO trace;

--
-- Name: polygon_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.polygon_subscriptions_id_seq OWNED BY public.polygon_subscriptions.id;


--
-- Name: portals; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.portals (
    id integer NOT NULL,
    name character varying(128) NOT NULL,
    url character varying(255) NOT NULL,
    tenant_id integer NOT NULL
);


ALTER TABLE public.portals OWNER TO trace;

--
-- Name: portals_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.portals_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.portals_id_seq OWNER TO trace;

--
-- Name: portals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.portals_id_seq OWNED BY public.portals.id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.products (
    id integer NOT NULL,
    code character varying(64) NOT NULL,
    name character varying(255) NOT NULL,
    category character varying(128),
    created_at timestamp without time zone DEFAULT now(),
    tenant_id integer,
    material_id integer,
    brand character varying(255),
    gtin character varying(50)
);


ALTER TABLE public.products OWNER TO trace;

--
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.products_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.products_id_seq OWNER TO trace;

--
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.products_id_seq OWNED BY public.products.id;


--
-- Name: rbac_permissions; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.rbac_permissions (
    id integer NOT NULL,
    name character varying(128) NOT NULL,
    code character varying(64) NOT NULL,
    role_id integer NOT NULL,
    tenant_id integer
);


ALTER TABLE public.rbac_permissions OWNER TO trace;

--
-- Name: rbac_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.rbac_permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.rbac_permissions_id_seq OWNER TO trace;

--
-- Name: rbac_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.rbac_permissions_id_seq OWNED BY public.rbac_permissions.id;


--
-- Name: rbac_role_bindings; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.rbac_role_bindings (
    id integer NOT NULL,
    tenant_id integer,
    user_id integer,
    role_id integer
);


ALTER TABLE public.rbac_role_bindings OWNER TO trace;

--
-- Name: rbac_role_bindings_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.rbac_role_bindings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.rbac_role_bindings_id_seq OWNER TO trace;

--
-- Name: rbac_role_bindings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.rbac_role_bindings_id_seq OWNED BY public.rbac_role_bindings.id;


--
-- Name: rbac_roles; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.rbac_roles (
    id integer NOT NULL,
    name character varying(64) NOT NULL,
    tenant_id integer NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.rbac_roles OWNER TO trace;

--
-- Name: rbac_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.rbac_roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.rbac_roles_id_seq OWNER TO trace;

--
-- Name: rbac_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.rbac_roles_id_seq OWNED BY public.rbac_roles.id;


--
-- Name: rbac_scopes; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.rbac_scopes (
    id integer NOT NULL,
    tenant_id integer,
    resource character varying(64) NOT NULL,
    action character varying(16) NOT NULL,
    constraint_expr jsonb
);


ALTER TABLE public.rbac_scopes OWNER TO trace;

--
-- Name: rbac_scopes_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.rbac_scopes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.rbac_scopes_id_seq OWNER TO trace;

--
-- Name: rbac_scopes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.rbac_scopes_id_seq OWNED BY public.rbac_scopes.id;


--
-- Name: sensor_events; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.sensor_events (
    id integer NOT NULL,
    epcis_event_id integer,
    sensor_meta jsonb,
    sensor_reports jsonb,
    tenant_id integer
);


ALTER TABLE public.sensor_events OWNER TO trace;

--
-- Name: sensor_events_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.sensor_events_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sensor_events_id_seq OWNER TO trace;

--
-- Name: sensor_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.sensor_events_id_seq OWNED BY public.sensor_events.id;


--
-- Name: split_policy; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.split_policy (
    role text NOT NULL,
    mode text NOT NULL,
    CONSTRAINT split_policy_mode_check CHECK ((mode = ANY (ARRAY['FULL'::text, 'SPLIT'::text])))
);


ALTER TABLE public.split_policy OWNER TO trace;

--
-- Name: suppliers; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.suppliers (
    id integer NOT NULL,
    tenant_id integer,
    code character varying(64) NOT NULL,
    name character varying(255) NOT NULL,
    country character varying(64),
    contact_email character varying(255),
    phone character varying(64),
    address character varying(255),
    factory_location character varying(255),
    certification jsonb,
    user_id integer,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.suppliers OWNER TO trace;

--
-- Name: suppliers_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.suppliers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.suppliers_id_seq OWNER TO trace;

--
-- Name: suppliers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.suppliers_id_seq OWNED BY public.suppliers.id;


--
-- Name: tenants; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.tenants (
    id integer NOT NULL,
    name character varying(128) NOT NULL,
    code character varying(64),
    created_at timestamp without time zone DEFAULT now(),
    email character varying(255),
    phone character varying(32),
    address text,
    is_active boolean DEFAULT true
);


ALTER TABLE public.tenants OWNER TO trace;

--
-- Name: tenants_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.tenants_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tenants_id_seq OWNER TO trace;

--
-- Name: tenants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.tenants_id_seq OWNED BY public.tenants.id;


--
-- Name: ui_menus; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.ui_menus (
    id integer NOT NULL,
    label character varying(128) NOT NULL,
    path character varying(255) NOT NULL,
    role_id integer NOT NULL,
    tenant_id integer
);


ALTER TABLE public.ui_menus OWNER TO trace;

--
-- Name: ui_menus_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.ui_menus_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ui_menus_id_seq OWNER TO trace;

--
-- Name: ui_menus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.ui_menus_id_seq OWNED BY public.ui_menus.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: trace
--

CREATE TABLE public.users (
    id integer NOT NULL,
    tenant_id integer,
    username character varying(64) NOT NULL,
    name character varying(128),
    email character varying(255),
    role character varying(32),
    password_hash character varying(255),
    created_at timestamp without time zone DEFAULT now(),
    is_active boolean NOT NULL
);


ALTER TABLE public.users OWNER TO trace;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: trace
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO trace;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trace
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: v_batch_overview; Type: VIEW; Schema: public; Owner: trace
--

CREATE VIEW public.v_batch_overview AS
 SELECT b.id,
    b.code AS batch_code,
    b.tenant_id,
    b.owner_role,
    b.status,
    b.quantity,
    b.unit,
    COALESCE(sum(((e.ilmd ->> 'input_quantity'::text))::numeric), (0)::numeric) AS used_quantity,
    GREATEST((b.quantity - COALESCE(sum(((e.ilmd ->> 'input_quantity'::text))::numeric), (0)::numeric)), (0)::numeric) AS remaining_quantity,
    max(e.event_time) AS last_event_time
   FROM (public.batches b
     LEFT JOIN public.epcis_events e ON ((((e.batch_code)::text = (b.code)::text) AND (e.tenant_id = b.tenant_id))))
  GROUP BY b.id, b.code, b.tenant_id, b.owner_role, b.status, b.quantity, b.unit;


ALTER TABLE public.v_batch_overview OWNER TO trace;

--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: batch_clone_audit id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batch_clone_audit ALTER COLUMN id SET DEFAULT nextval('public.batch_clone_audit_id_seq'::regclass);


--
-- Name: batch_lineage id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batch_lineage ALTER COLUMN id SET DEFAULT nextval('public.batch_lineage_id_seq'::regclass);


--
-- Name: batch_links id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batch_links ALTER COLUMN id SET DEFAULT nextval('public.batch_links_id_seq'::regclass);


--
-- Name: batch_usage_log id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batch_usage_log ALTER COLUMN id SET DEFAULT nextval('public.batch_usage_log_id_seq'::regclass);


--
-- Name: batch_usages id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batch_usages ALTER COLUMN id SET DEFAULT nextval('public.batch_usages_id_seq'::regclass);


--
-- Name: batches id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batches ALTER COLUMN id SET DEFAULT nextval('public.batches_id_seq'::regclass);


--
-- Name: blockchain_anchors id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.blockchain_anchors ALTER COLUMN id SET DEFAULT nextval('public.blockchain_anchors_id_seq'::regclass);


--
-- Name: blockchain_proofs id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.blockchain_proofs ALTER COLUMN id SET DEFAULT nextval('public.blockchain_proofs_id_seq'::regclass);


--
-- Name: brands id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.brands ALTER COLUMN id SET DEFAULT nextval('public.brands_id_seq'::regclass);


--
-- Name: compliance_results id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.compliance_results ALTER COLUMN id SET DEFAULT nextval('public.compliance_results_id_seq'::regclass);


--
-- Name: configs_blockchain id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.configs_blockchain ALTER COLUMN id SET DEFAULT nextval('public.configs_blockchain_id_seq'::regclass);


--
-- Name: customers id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.customers ALTER COLUMN id SET DEFAULT nextval('public.customers_id_seq'::regclass);


--
-- Name: customs id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.customs ALTER COLUMN id SET DEFAULT nextval('public.customs_id_seq'::regclass);


--
-- Name: data_sharing_agreements id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.data_sharing_agreements ALTER COLUMN id SET DEFAULT nextval('public.data_sharing_agreements_id_seq'::regclass);


--
-- Name: documents id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.documents ALTER COLUMN id SET DEFAULT nextval('public.documents_id_seq'::regclass);


--
-- Name: domains id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.domains ALTER COLUMN id SET DEFAULT nextval('public.domains_id_seq'::regclass);


--
-- Name: dpp_passports id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.dpp_passports ALTER COLUMN id SET DEFAULT nextval('public.dpp_passports_id_seq'::regclass);


--
-- Name: dpp_templates id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.dpp_templates ALTER COLUMN id SET DEFAULT nextval('public.dpp_templates_id_seq'::regclass);


--
-- Name: emissions id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.emissions ALTER COLUMN id SET DEFAULT nextval('public.emissions_id_seq'::regclass);


--
-- Name: epcis_events id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.epcis_events ALTER COLUMN id SET DEFAULT nextval('public.epcis_events_id_seq'::regclass);


--
-- Name: events id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.events ALTER COLUMN id SET DEFAULT nextval('public.events_id_seq'::regclass);


--
-- Name: fabric_events id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.fabric_events ALTER COLUMN id SET DEFAULT nextval('public.fabric_events_id_seq'::regclass);


--
-- Name: farms id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.farms ALTER COLUMN id SET DEFAULT nextval('public.farms_id_seq'::regclass);


--
-- Name: materials id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.materials ALTER COLUMN id SET DEFAULT nextval('public.materials_id_seq'::regclass);


--
-- Name: polygon_abi id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.polygon_abi ALTER COLUMN id SET DEFAULT nextval('public.polygon_abi_id_seq'::regclass);


--
-- Name: polygon_anchors id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.polygon_anchors ALTER COLUMN id SET DEFAULT nextval('public.polygon_anchors_id_seq'::regclass);


--
-- Name: polygon_logs id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.polygon_logs ALTER COLUMN id SET DEFAULT nextval('public.polygon_logs_id_seq'::regclass);


--
-- Name: polygon_subscriptions id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.polygon_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.polygon_subscriptions_id_seq'::regclass);


--
-- Name: portals id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.portals ALTER COLUMN id SET DEFAULT nextval('public.portals_id_seq'::regclass);


--
-- Name: products id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.products ALTER COLUMN id SET DEFAULT nextval('public.products_id_seq'::regclass);


--
-- Name: rbac_permissions id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.rbac_permissions ALTER COLUMN id SET DEFAULT nextval('public.rbac_permissions_id_seq'::regclass);


--
-- Name: rbac_role_bindings id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.rbac_role_bindings ALTER COLUMN id SET DEFAULT nextval('public.rbac_role_bindings_id_seq'::regclass);


--
-- Name: rbac_roles id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.rbac_roles ALTER COLUMN id SET DEFAULT nextval('public.rbac_roles_id_seq'::regclass);


--
-- Name: rbac_scopes id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.rbac_scopes ALTER COLUMN id SET DEFAULT nextval('public.rbac_scopes_id_seq'::regclass);


--
-- Name: sensor_events id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.sensor_events ALTER COLUMN id SET DEFAULT nextval('public.sensor_events_id_seq'::regclass);


--
-- Name: suppliers id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.suppliers ALTER COLUMN id SET DEFAULT nextval('public.suppliers_id_seq'::regclass);


--
-- Name: tenants id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.tenants ALTER COLUMN id SET DEFAULT nextval('public.tenants_id_seq'::regclass);


--
-- Name: ui_menus id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.ui_menus ALTER COLUMN id SET DEFAULT nextval('public.ui_menus_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.audit_logs (id, tenant_id, "user", method, path, status, ip, payload, created_at) FROM stdin;
1	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 17:56:06.144502
2	1	unknown	POST	/api/users/login	200	172.19.0.1	\N	2025-10-26 17:56:09.423359
3	1	unknown	OPTIONS	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-26 17:56:09.559998
4	1	unknown	OPTIONS	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-26 17:56:09.580214
5	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-26 17:56:09.671905
6	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-26 17:56:09.989443
7	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-26 17:56:09.999971
8	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 17:56:16.170035
9	1	unknown	GET	/docs	200	172.19.0.1	\N	2025-10-26 17:56:26.860594
10	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 17:56:27.245253
11	1	unknown	GET	/openapi.json	200	172.19.0.1	\N	2025-10-26 17:56:27.396451
12	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 17:56:37.358474
13	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 17:56:47.447568
14	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 17:56:58.565267
15	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 17:57:08.668795
16	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 17:57:18.805957
17	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 17:57:29.849805
18	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 17:57:39.950656
19	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 17:57:50.036489
20	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 17:58:01.130226
21	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 17:58:11.269942
22	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 17:58:21.375579
23	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 17:58:32.630916
24	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 17:58:42.841927
25	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 17:58:52.953334
26	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 17:59:04.11096
27	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 17:59:14.228072
28	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 17:59:24.336895
29	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 17:59:35.389161
30	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 17:59:45.525367
31	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 17:59:55.625992
32	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:00:06.706516
33	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:00:16.809564
34	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:00:27.938578
35	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:00:38.076536
36	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:00:58.972843
37	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:01:09.07098
38	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:01:19.206903
39	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:01:30.292132
40	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:01:40.395721
41	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:01:50.595182
42	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:02:01.665815
43	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:02:11.796654
44	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:02:21.923525
45	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:02:33.033168
46	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:02:43.210833
47	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:02:53.377684
48	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:03:04.559214
49	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:03:20.809082
50	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:03:30.892814
51	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:03:41.986915
52	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:03:52.107505
53	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:04:02.217325
54	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:04:13.333527
55	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:04:23.524788
56	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:04:33.618309
57	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:04:44.756108
58	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:04:54.867297
59	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:05:04.977683
60	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:05:16.076101
61	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:05:26.19747
62	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:05:36.306466
63	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:05:47.411824
64	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:05:57.517797
65	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:06:08.104498
66	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:06:18.77184
67	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:06:28.884767
68	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:06:39.990248
69	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:06:58.253269
70	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:07:08.357569
71	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:07:19.457981
72	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:07:29.563691
73	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:07:39.680114
74	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:07:50.802319
75	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:08:00.938976
76	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:08:11.05613
77	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:08:22.183239
78	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:08:32.290617
79	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:08:42.403387
80	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:08:53.50462
81	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:09:07.57812
82	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:09:18.695858
83	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:09:28.780848
84	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:09:38.909092
85	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:09:54.117192
86	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:10:04.282642
87	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:10:14.392058
88	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:10:25.501374
89	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:10:35.596836
90	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:10:45.707429
91	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:10:56.834841
92	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:11:06.927522
93	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:11:17.022155
94	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:11:28.141694
95	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:11:38.24503
96	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:11:48.334454
97	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:12:02.647364
98	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:12:12.756236
99	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:12:23.864391
100	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:12:34.073547
101	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:12:44.21788
102	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:12:55.367722
103	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:13:05.49661
104	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:13:17.057634
105	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:13:27.610552
106	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:13:38.766452
107	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:13:48.869972
108	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:13:59.460951
109	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:14:09.584309
110	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:14:19.676189
111	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:14:30.834589
112	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:14:50.070321
113	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:15:01.165631
114	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:15:11.283227
115	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:15:21.387271
116	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:15:32.593748
117	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:15:42.704846
118	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:15:52.836374
119	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:16:11.215455
120	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:16:21.272472
121	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:16:32.415948
122	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:16:42.559952
123	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:16:52.742536
124	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:17:03.952106
125	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:17:14.113368
126	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:17:24.242685
127	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:17:35.34411
128	1	unknown	POST	/auth/login	200	172.19.0.1	\N	2025-10-26 18:17:50.322069
129	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:17:55.607796
130	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:18:06.727989
131	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:18:16.809798
132	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:18:26.934036
133	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:18:38.058362
134	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:18:48.154205
135	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:18:58.244131
136	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:19:09.372243
137	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:19:19.467946
138	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:19:29.572348
139	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:19:40.682701
140	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:19:50.80138
141	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:20:00.895279
142	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:20:12.010166
143	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:20:22.102936
144	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:20:32.218002
145	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:20:43.338401
146	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:20:53.466441
147	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:21:03.577098
148	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:21:14.741345
149	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:21:24.966564
150	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:21:35.065195
151	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:21:46.15123
152	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:21:56.245644
153	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:22:06.375821
154	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:22:17.488382
155	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:22:27.591164
156	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:22:48.070171
157	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:22:58.204572
158	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:23:08.315695
159	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:23:19.462304
160	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:23:29.584932
161	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:23:39.716716
162	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:23:50.832155
163	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:24:00.937336
164	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:24:11.043292
165	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 18:24:22.423636
166	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 20:16:16.780808
167	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 20:16:29.337462
168	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:13:33.080313
169	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:13:43.291797
170	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:13:54.078712
171	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:14:04.210619
172	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:14:14.390211
173	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:14:25.411954
174	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:14:35.740311
175	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:14:45.914303
176	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:14:56.788129
177	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:15:07.022236
178	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:15:17.18871
179	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:15:28.471541
180	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:15:39.271954
181	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:15:49.441243
182	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:16:00.37285
183	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:16:10.561492
184	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:16:20.755781
185	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:16:31.819792
186	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:16:42.048745
187	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:16:52.212573
188	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:17:03.148548
189	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:17:13.336393
190	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:17:23.507547
191	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:17:34.852312
192	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:17:45.437182
193	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:17:57.052414
194	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:18:07.319129
195	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:18:17.57204
196	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:18:28.801651
197	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:18:39.000229
198	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:18:49.18213
199	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:19:00.219195
200	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:19:10.383177
201	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:19:20.547143
202	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:19:31.552012
203	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:19:41.706137
204	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:19:51.861396
205	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:20:02.838952
206	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:20:12.978471
207	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:20:23.141385
208	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:20:34.088482
209	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:20:44.208833
210	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:20:54.424486
211	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:21:05.565382
212	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:21:15.798684
213	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:21:25.969803
214	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:21:36.911874
215	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:21:47.025395
216	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:21:57.145932
217	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:22:08.125743
218	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:22:18.289547
219	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:22:28.407857
220	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:22:39.367998
221	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:22:49.613849
222	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:23:00.053482
223	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:23:11.118402
224	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:23:21.250952
225	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:23:31.367515
226	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:23:42.324719
227	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:23:52.436682
228	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:24:02.596336
229	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:24:13.521815
230	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:24:23.626763
231	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:24:33.77873
232	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:24:44.997438
233	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:24:55.720838
234	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:25:06.271235
235	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:25:17.935169
236	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:25:28.621323
237	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:25:39.695447
238	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:25:49.894459
239	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:26:00.092066
240	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:26:11.128147
241	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:26:21.362904
242	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:26:31.559716
243	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:26:42.614582
244	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:26:52.807592
245	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:27:03.036083
246	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:27:14.098085
247	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:27:24.304888
248	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:27:34.471604
249	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:27:45.901528
250	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:27:56.36148
251	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:28:06.597096
252	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:28:17.633304
253	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:28:28.477709
254	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:28:38.83558
255	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:28:50.082626
256	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:29:00.31856
257	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:29:10.525639
258	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:29:21.628038
259	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:29:31.780463
260	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:29:41.946301
261	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:29:53.003429
262	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:30:03.160217
263	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:30:13.29863
264	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:30:24.364128
265	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:30:34.514667
266	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:30:44.891138
267	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:30:56.318722
268	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:31:06.564243
269	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:31:16.738767
270	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:31:27.89259
271	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:31:38.097162
272	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:31:48.264621
273	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:31:59.46307
274	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:32:09.692957
275	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:32:19.895703
276	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:32:31.037307
277	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:32:41.246031
278	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:32:51.467469
279	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:33:02.657188
280	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:33:12.945742
281	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:33:24.134981
282	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:33:34.345576
283	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:33:44.502501
284	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:33:55.824356
285	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:34:05.99746
286	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:34:16.162746
287	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:34:27.348346
288	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:34:37.586563
289	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:34:47.777935
290	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:34:59.11359
291	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:35:09.493862
292	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:35:19.739078
293	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:35:30.897615
294	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:35:41.099086
295	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:35:51.266586
296	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:36:02.435897
297	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:36:12.605922
298	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:36:22.765653
299	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:36:33.863554
300	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:36:44.026862
301	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:36:54.154191
302	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:37:05.37858
303	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:37:15.58189
304	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:37:25.801501
305	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:37:36.909928
306	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:37:47.064834
307	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:37:57.296262
308	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:38:08.525217
309	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:38:18.704319
310	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:38:29.036482
311	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:38:40.261383
312	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:38:50.454711
313	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:39:00.642557
314	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:39:11.854334
315	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:39:22.027517
316	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:39:32.194165
317	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:39:43.321879
318	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:39:53.46069
319	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:40:03.616253
320	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:40:14.743804
321	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:40:24.927641
322	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:40:35.221319
323	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:40:46.38636
324	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:40:56.552537
325	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:41:06.736909
326	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:41:17.951383
327	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:41:28.215212
328	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:41:39.392793
329	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:41:49.79225
330	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:42:00.026875
331	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:42:11.178251
332	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:42:21.349925
333	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:42:31.519401
334	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:42:42.693942
335	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:42:52.851809
336	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:43:03.000696
337	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:43:14.163692
338	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:43:24.31735
339	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:43:34.486031
340	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:43:45.590611
341	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:43:55.978811
342	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:44:06.158758
343	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:44:17.315175
344	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:44:27.658049
345	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:44:37.939475
346	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:44:49.092287
347	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:44:59.259217
348	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:45:09.603479
349	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:45:20.777886
350	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:45:30.96664
351	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:45:41.152499
352	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:45:52.292807
353	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:46:02.471538
354	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:46:12.678008
355	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:46:23.814723
356	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:46:33.971717
357	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:46:44.201864
358	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:46:55.33843
359	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:47:05.485117
360	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:47:15.700793
361	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:47:27.023662
362	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:47:37.186886
363	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:47:47.704597
364	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:47:58.86646
365	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:48:09.056635
366	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:48:19.343807
367	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:48:30.654918
368	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:48:40.878127
369	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:48:51.109287
370	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:49:02.225359
371	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:49:12.401074
372	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:49:22.583481
373	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:49:33.687191
374	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:49:43.820852
375	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:49:54.941688
376	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:50:05.081449
377	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:50:15.23326
378	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:50:26.563628
379	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:50:36.731167
380	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:50:46.917474
381	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:50:58.040664
382	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:51:08.380209
383	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:51:18.55981
384	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:51:29.702185
385	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:51:40.083112
386	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:51:50.406802
387	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:52:01.568848
388	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:52:11.737784
389	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:52:21.901877
390	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:52:32.99969
391	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:52:43.181122
392	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:52:53.33673
393	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:53:04.423996
394	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:53:14.565092
395	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:53:24.786846
396	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:53:35.862375
397	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:53:46.047762
398	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:53:56.257823
399	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:54:07.362373
400	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:54:17.544429
401	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:54:27.866131
402	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:54:39.007353
403	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:54:49.182645
404	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:54:59.354557
405	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:55:10.645691
406	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:55:20.857013
407	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:55:31.054639
408	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:55:42.159322
409	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:55:52.33835
410	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:56:02.52354
411	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:56:13.199118
412	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:56:23.374044
413	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:56:33.531948
414	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:56:44.189794
415	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:56:54.349441
416	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:57:04.491414
417	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:57:15.141448
418	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:57:25.335063
419	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:57:35.485888
420	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:57:46.119526
421	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:57:56.426125
422	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:58:06.600671
423	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:58:17.255909
424	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:58:28.18994
425	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:58:38.972702
426	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:58:49.271738
427	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:58:59.477341
428	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:59:10.041667
429	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:59:20.236265
430	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:59:30.678596
431	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:59:41.39757
432	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-26 23:59:51.590222
433	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:00:01.762443
434	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:00:12.441424
435	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:00:22.624161
436	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:00:32.789664
437	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:00:43.472279
438	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:00:53.668294
439	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:01:03.802574
440	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:01:14.422339
441	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:01:24.616285
442	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:01:34.763656
443	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:01:45.294358
444	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:01:55.475786
445	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:02:05.612502
446	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:02:16.208683
447	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:02:26.49745
448	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:02:36.733974
449	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:02:47.355874
450	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:02:57.517279
451	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:03:07.656081
452	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:03:18.129696
453	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:03:28.344143
454	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:03:38.70709
455	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:03:49.362432
456	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:03:59.596126
457	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:04:09.827342
458	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:04:20.377792
459	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:04:30.954138
460	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:04:41.239169
461	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:04:51.78188
462	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:05:02.018104
463	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:05:12.231694
464	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:05:22.769834
465	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:05:32.979837
466	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:05:43.173181
467	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:05:53.690246
468	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:06:03.891595
469	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:06:14.405371
470	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:06:24.615053
471	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:06:34.800895
472	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:06:45.312278
473	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:06:55.480401
474	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:07:05.661294
475	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:07:16.121844
476	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:07:26.28622
477	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:07:36.443819
478	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:07:47.064296
479	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:07:57.334451
480	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:08:08.168379
481	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:08:20.762464
482	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:08:31.175195
483	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:08:41.343355
484	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:08:51.905284
485	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:09:02.013956
486	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:09:12.124536
487	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:09:22.579923
488	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:13:46.732563
489	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:13:56.855034
490	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:14:07.086119
491	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:14:17.190656
492	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:14:27.292594
493	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:14:37.658811
494	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:14:47.841858
495	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:14:57.988295
496	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:15:08.463479
497	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:15:18.587052
498	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:15:28.699092
499	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:15:39.022809
500	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:15:49.127496
501	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:15:59.263107
502	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:16:09.62658
503	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:16:19.843268
504	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:16:30.024441
505	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:16:40.471932
506	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:16:50.732763
507	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:17:00.847609
508	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:17:11.139112
509	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:17:21.258174
510	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:17:31.381504
511	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:17:41.732644
512	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:17:51.862298
513	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:18:01.98465
514	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:18:12.300388
515	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:18:22.411818
516	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:18:32.538377
517	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:18:42.855894
518	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:18:52.973342
519	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 00:19:03.119044
520	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:21:26.987442
521	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:21:37.105306
522	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:21:47.326592
523	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:21:57.46818
524	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:22:07.604688
525	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:22:17.882701
526	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:22:27.991927
527	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:22:38.114715
528	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:22:48.445781
529	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:22:58.573074
530	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:23:08.692578
531	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:23:19.013705
532	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:23:29.140257
533	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:23:39.254019
534	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:23:49.563382
535	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:23:59.689135
536	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:24:09.790817
537	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:24:20.104268
538	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:24:30.21296
539	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:24:40.319333
540	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:24:50.661646
541	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:25:00.799581
542	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:25:10.910894
543	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:25:21.197219
544	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:25:31.306489
545	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:25:41.420934
546	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:25:51.71141
547	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:26:01.827884
548	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:26:11.949534
549	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:26:22.238453
550	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:26:32.34494
551	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:26:42.563838
552	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:26:52.934962
553	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:27:03.129484
554	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:27:13.260313
555	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:27:23.627627
556	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:27:33.737677
557	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:27:43.848519
558	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:27:54.155044
559	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:28:04.271806
560	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:28:14.391105
561	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:28:24.678952
562	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:28:34.784268
563	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:28:44.917809
564	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:28:55.220967
565	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:29:05.337652
566	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:29:15.449745
567	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:29:25.708909
568	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:29:35.817006
569	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:29:45.913402
570	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:29:56.193882
571	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:30:06.3183
572	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:30:16.410142
573	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:30:26.720321
574	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:30:36.842337
575	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:30:46.944132
576	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:30:57.249486
577	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:31:07.36535
578	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:31:25.440327
579	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:31:35.506056
580	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:31:45.619352
581	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:31:55.906298
582	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:32:06.016829
583	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:32:16.139703
584	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:32:26.446993
585	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:32:36.57145
586	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:32:46.673209
587	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:32:56.940497
588	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:33:07.04929
589	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:33:17.158737
590	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:33:27.437256
591	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:33:37.548337
592	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:33:47.678712
593	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:33:57.961205
594	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:34:08.06512
595	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:34:18.208511
596	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:34:28.505036
597	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:34:38.637201
598	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:34:40.098998
599	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:34:48.770939
600	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:34:59.052516
601	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:35:09.15515
602	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:35:19.273933
603	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:35:29.557405
604	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:35:39.687028
605	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:35:49.795349
606	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:36:00.073426
607	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:36:10.190176
608	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:36:20.302356
609	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:36:30.584132
610	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:36:40.724451
611	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:36:50.850486
612	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:37:01.134397
613	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:37:11.252317
614	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:37:21.361309
615	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:37:31.658932
616	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:37:41.770279
617	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:37:51.863856
618	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:38:02.154159
619	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:38:12.247339
620	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:38:22.350533
621	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:38:32.6412
622	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:38:42.757537
623	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:38:52.861644
624	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:39:03.1359
625	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:39:13.329278
626	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:39:23.534864
627	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:39:33.859517
628	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:39:43.99548
629	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:39:54.268878
630	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:40:04.377087
631	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:40:14.539135
632	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:40:24.843681
633	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:40:34.958031
634	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:40:45.065493
635	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:40:55.367631
636	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:41:05.474923
637	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:41:15.57114
638	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:41:25.874212
639	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:41:35.974143
640	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:41:46.097647
641	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:41:56.414588
642	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:42:06.524907
643	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:42:16.641667
644	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:42:26.939415
645	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:42:37.042748
646	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:42:47.168066
647	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:42:57.462762
648	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:43:07.57669
649	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:43:17.681797
650	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:43:27.976138
651	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:43:38.080835
652	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:43:48.168621
653	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:43:58.476477
654	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:44:08.600942
655	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:44:18.752472
656	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:44:29.031348
657	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:44:39.151337
658	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:44:49.278729
659	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:44:59.544944
660	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:45:09.646162
661	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:45:19.760031
662	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:45:30.036524
663	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:45:40.161786
664	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:45:50.29027
665	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:46:05.349102
666	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:46:15.511593
667	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:46:25.70916
668	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:46:36.089449
669	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:46:46.26704
670	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:46:56.595996
671	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:47:06.856749
672	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:47:16.978302
673	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:47:27.273756
674	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:47:37.391869
675	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:47:47.5032
676	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:47:57.774603
677	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:48:07.909252
678	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:48:18.027729
679	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:48:28.395791
680	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:48:38.503288
681	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:48:48.621306
682	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:48:58.926034
683	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:49:09.056401
684	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:49:19.170787
685	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:49:29.469906
686	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:49:39.5914
687	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:49:49.813179
688	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:50:00.121932
689	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:50:10.232639
690	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:50:20.37256
691	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:50:30.697841
692	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:50:40.831404
693	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:50:50.937744
694	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:51:01.252434
695	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:51:11.368747
696	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:51:21.496458
697	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:51:31.799495
698	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:51:41.924255
699	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:51:52.039694
700	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:52:02.337712
701	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:52:12.448439
702	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:52:22.612895
703	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:52:32.909577
704	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:52:43.037842
705	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:52:53.181468
706	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:53:03.452032
707	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:53:13.581731
708	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:53:23.697658
709	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:53:33.998434
710	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:53:44.123985
711	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:53:54.239102
712	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:54:04.517053
713	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:54:14.63637
714	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:54:24.760487
715	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:54:35.034074
716	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:54:45.14612
717	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:54:55.260887
718	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:55:05.555074
719	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:55:15.665441
720	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:55:25.781669
721	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:55:36.070047
722	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:55:46.251944
723	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:55:56.441603
724	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:56:06.78416
725	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:56:16.920239
726	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:56:27.034848
727	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:56:37.322229
728	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:56:47.461457
729	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:56:57.587893
730	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:57:07.912941
731	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:57:18.054085
732	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:57:28.185587
733	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:57:38.469857
734	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:57:48.593268
735	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:57:58.72567
736	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:58:09.060597
737	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:58:19.279187
738	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:58:29.422593
739	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:58:39.712631
740	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:58:49.839822
741	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:58:59.952817
742	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:59:10.245807
743	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:59:20.359085
744	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:59:30.494423
745	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:59:40.792817
746	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 01:59:50.917035
747	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:00:01.218935
748	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:00:11.333316
749	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:00:21.462181
750	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:00:31.873465
751	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:00:41.998052
752	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:00:52.126269
753	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:01:02.412925
754	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:01:12.533632
755	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:01:22.659152
756	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:01:33.007625
757	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:01:43.163818
758	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:01:53.278624
759	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:02:03.550053
760	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:02:13.686011
761	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:02:23.832843
762	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:02:34.12364
763	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:02:44.268481
764	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:02:54.387025
765	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:03:04.681265
766	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:03:14.797363
767	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:03:24.911171
768	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:03:35.215646
769	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:03:45.39188
770	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:03:55.521905
771	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:04:05.817974
772	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:04:15.946304
773	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:04:26.061326
774	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:04:36.350913
775	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:04:46.516288
776	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:04:56.713408
777	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:05:07.031169
778	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:05:17.196471
779	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:05:27.363115
780	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:05:37.660358
781	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:05:47.777797
782	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:05:57.887754
783	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:06:08.159212
784	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:06:18.31617
785	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:06:28.453776
786	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:06:38.738239
787	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:06:48.833117
788	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:06:58.933658
789	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:07:09.243744
790	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:07:19.355896
791	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:07:29.492341
792	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:07:39.828538
793	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:07:49.951038
794	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:08:00.06771
795	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:08:10.354145
796	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:08:20.474801
797	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:08:30.584505
798	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:08:40.891668
799	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:08:51.023778
800	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:09:01.147823
801	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:09:11.422071
802	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:09:21.529255
803	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:09:31.654716
804	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:09:41.931577
805	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:09:52.035701
806	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:10:02.145719
807	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:10:12.424284
808	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:10:22.532625
809	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:10:32.644937
810	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:10:42.96749
811	1	unknown	GET	/docs	200	172.19.0.1	\N	2025-10-27 02:10:58.597359
812	1	unknown	GET	/openapi.json	200	172.19.0.1	\N	2025-10-27 02:10:59.204159
813	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:11:01.317785
814	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:11:11.66184
815	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:11:21.768912
816	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:11:31.883409
817	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:11:42.167097
818	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:11:52.279215
819	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:12:02.407405
820	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:12:12.69498
821	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:12:22.827432
822	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:12:32.966352
823	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:12:43.268182
824	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:12:53.389217
825	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:13:03.50959
826	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:13:13.802324
827	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:13:23.917521
828	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:13:34.040798
829	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:13:44.31771
830	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:13:54.450021
831	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:14:04.5856
832	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:14:14.882395
833	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:14:25.090912
834	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:14:35.212069
835	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:14:45.502618
836	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:14:56.056215
837	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:15:06.143818
838	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:15:16.289146
839	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:15:26.385015
840	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:15:36.473174
841	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:15:46.751923
842	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:15:56.849598
843	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:16:07.233529
844	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:16:17.44438
845	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:16:27.608629
846	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:16:37.907461
847	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:16:48.119355
848	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:16:58.244562
849	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:17:08.520478
850	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:17:18.62043
851	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:17:28.737235
852	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:17:39.010724
853	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:17:49.137464
854	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:17:59.249384
855	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:18:09.525958
856	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:18:19.64657
857	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:18:29.765179
858	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:18:40.077679
859	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:18:50.205955
860	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:19:00.374198
861	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:19:10.744302
862	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:19:20.875718
863	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:19:31.008371
864	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:19:41.290057
865	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:19:51.437189
866	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:20:01.541785
867	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:20:11.819194
868	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:20:21.944041
869	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:20:32.058252
870	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:20:42.332938
871	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:20:52.44959
872	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:21:02.547239
873	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:21:12.824244
874	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:21:22.976488
875	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:21:33.085446
876	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:21:43.384041
877	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:21:53.499182
878	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:22:03.61484
879	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:22:13.903603
880	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:22:24.027194
881	1	unknown	GET	/docs	200	172.19.0.1	\N	2025-10-27 02:22:40.392542
882	1	unknown	GET	/openapi.json	200	172.19.0.1	\N	2025-10-27 02:22:40.964423
883	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:22:42.935291
884	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:22:53.090755
885	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:23:03.213433
886	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:23:13.536556
887	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:23:23.667931
888	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:23:33.811477
889	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:23:44.093647
890	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:23:54.239431
891	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:24:04.378408
892	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:24:14.680552
893	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:24:24.813988
894	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:24:34.956975
895	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:24:45.270975
896	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:24:55.369602
897	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:25:05.495748
898	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:25:15.815994
899	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:25:25.951346
900	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:25:36.073485
901	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:25:46.343064
902	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:25:56.458977
903	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:26:06.56855
904	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:26:20.690595
905	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:26:30.813423
906	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:26:41.11427
907	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:26:51.247423
908	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:27:01.357786
909	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:27:11.638696
910	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:27:21.745158
911	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:27:31.876345
912	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:27:42.162242
913	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:27:52.301876
914	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:28:02.430976
915	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:28:12.71839
916	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:28:22.829627
917	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:28:32.980066
918	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:28:43.313445
919	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:28:53.443072
920	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:29:03.576656
921	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:29:13.857053
922	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:29:23.965947
923	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:29:34.100204
924	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:29:44.383751
925	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:29:54.505998
926	1	unknown	GET	/docs	200	172.19.0.1	\N	2025-10-27 02:33:00.785188
927	1	unknown	GET	/openapi.json	200	172.19.0.1	\N	2025-10-27 02:33:01.457988
928	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:33:02.117405
929	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:33:12.231721
930	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:33:22.521583
931	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:33:32.641626
932	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:33:42.936067
933	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:33:53.050444
934	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:34:03.168093
935	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:34:13.453811
936	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:34:23.59633
937	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:34:33.702145
938	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:34:43.997331
939	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:34:54.109956
940	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:35:04.221051
941	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:35:14.495945
942	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:35:24.610578
943	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:35:34.720185
944	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:35:44.996487
945	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:35:55.131313
946	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:36:05.253067
947	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:36:15.570541
948	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:36:25.709199
949	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:36:35.849048
950	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:36:46.108648
951	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:36:56.244911
952	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:37:06.358268
953	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:37:16.643877
954	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:37:26.777014
955	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:37:36.917434
956	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:37:47.218422
957	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-27 02:37:57.339361
958	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:33:58.649658
959	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:34:09.651392
960	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:34:19.763056
961	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:34:29.886651
962	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:34:40.898337
963	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:34:51.006628
964	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:35:01.107218
965	1	unknown	GET	/api/users	401	172.19.0.1	\N	2025-10-28 04:35:07.356757
966	1	unknown	GET	/api/bindings	401	172.19.0.1	\N	2025-10-28 04:35:07.424549
967	1	unknown	GET	/api/scopes	401	172.19.0.1	\N	2025-10-28 04:35:07.611109
968	1	unknown	GET	/api/roles	401	172.19.0.1	\N	2025-10-28 04:35:07.601158
977	1	unknown	POST	/auth/login	200	172.19.0.1	\N	2025-10-28 04:35:26.167953
985	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:35:43.393311
990	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:36:34.791248
995	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:37:27.323336
1000	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:38:19.754002
1005	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:39:11.151069
2388	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:39:16.286482
2393	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:40:11.91503
2398	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:41:04.30367
2403	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:41:58.357986
2408	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:42:51.022092
2413	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:43:43.814291
2418	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:44:34.4177
2423	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:45:25.093778
2428	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:46:15.716181
2433	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 08:46:57.614256
971	1	unknown	GET	/api/tenants	401	172.19.0.1	\N	2025-10-28 04:35:07.610961
970	1	unknown	GET	/api/users	401	172.19.0.1	\N	2025-10-28 04:35:07.613465
976	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:35:22.094212
978	1	unknown	OPTIONS	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 04:35:26.703451
979	1	unknown	OPTIONS	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 04:35:26.716798
981	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 04:35:26.764391
984	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:35:32.219728
987	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:36:03.583678
989	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:36:24.695271
992	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:36:56.093788
994	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:37:17.214518
997	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:37:48.480832
999	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:38:08.760296
1002	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:38:39.977203
1004	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:39:01.046663
1007	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:39:32.345708
1147	1	unknown	OPTIONS	/api/tenants	200	172.19.0.1	\N	2025-10-28 05:59:54.746141
1141	1	unknown	OPTIONS	/api/bindings	200	172.19.0.1	\N	2025-10-28 05:59:54.783211
1159	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:00:02.301559
1162	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:00:33.886032
1164	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:00:55.184608
1167	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:01:26.795217
1169	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:01:47.632827
1172	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:02:18.832484
1174	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:02:39.853837
1177	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:03:11.514585
1179	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:03:31.905025
1182	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:04:04.10475
1184	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:04:24.962132
1187	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:04:56.613413
1189	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:05:18.033684
1192	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:05:48.80644
1194	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:06:10.857263
1197	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:06:43.029049
1199	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:07:03.592619
1202	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:07:35.287735
1204	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:07:57.488171
1207	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:08:28.440352
1209	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:08:49.789122
1212	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:09:20.287608
1214	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:09:41.592346
1217	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:10:12.825848
1219	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:10:33.628229
1699	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 07:24:56.743419
1709	1	unknown	GET	/api/scopes/	200	172.19.0.1	\N	2025-10-28 07:24:57.259607
1713	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:25:26.967215
1718	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:26:18.681901
1723	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:27:11.469659
1728	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:28:04.841151
1733	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:28:56.854522
2146	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:10:52.249042
2148	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:11:12.795046
2150	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:11:33.098968
2152	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:11:53.572391
2154	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:12:14.022322
2156	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:12:34.288173
2158	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:12:54.822576
2160	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:13:15.518345
2162	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:13:36.069639
2164	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:13:56.304771
2166	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:14:16.896285
2168	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:14:39.245538
2170	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:15:00.050986
2172	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:15:20.586124
2174	1	unknown	OPTIONS	/api/tenants	200	172.19.0.1	\N	2025-10-28 08:15:26.013375
2176	1	unknown	GET	/api/tenants	307	172.19.0.1	\N	2025-10-28 08:15:26.145155
2389	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:39:27.624829
2394	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:40:22.223652
2399	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:41:15.358952
2404	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:42:08.659002
2409	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:43:02.168974
2414	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:43:53.938236
2419	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:44:44.535138
2424	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:45:35.257826
2429	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:46:25.874621
972	1	unknown	GET	/api/roles	401	172.19.0.1	\N	2025-10-28 04:35:07.741015
1144	1	unknown	OPTIONS	/api/roles	200	172.19.0.1	\N	2025-10-28 05:59:54.759633
1143	1	unknown	OPTIONS	/api/roles	200	172.19.0.1	\N	2025-10-28 05:59:54.775725
1157	1	unknown	GET	/api/scopes	401	172.19.0.1	\N	2025-10-28 05:59:54.839908
1160	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:00:13.606124
1163	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:00:45.078352
1168	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:01:36.971014
1173	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:02:29.748265
1178	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:03:21.710514
1183	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:04:14.364893
1188	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:05:07.782446
1193	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:06:00.560638
1198	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:06:53.241317
1203	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:07:45.69285
1208	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:08:38.574085
1213	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:09:31.420958
1218	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:10:22.98735
1700	1	unknown	OPTIONS	/api/scopes	200	172.19.0.1	\N	2025-10-28 07:24:56.756421
1705	1	unknown	OPTIONS	/api/scopes/	200	172.19.0.1	\N	2025-10-28 07:24:57.12768
1714	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:25:37.095242
1719	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:26:29.84679
1724	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:27:21.733636
1729	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:28:15.065386
1734	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:29:08.109481
2147	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:11:02.384179
2149	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:11:22.930649
2151	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:11:43.466864
2153	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:12:03.672611
2155	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:12:24.146409
2157	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:12:44.700758
2159	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:13:05.058715
2161	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:13:25.660732
2163	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:13:46.184898
2165	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:14:06.774506
2167	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:14:28.03646
2169	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:14:49.824299
2171	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:15:10.458839
2173	1	unknown	OPTIONS	/api/roles	200	172.19.0.1	\N	2025-10-28 08:15:25.963892
2175	1	unknown	OPTIONS	/api/scopes	200	172.19.0.1	\N	2025-10-28 08:15:26.046975
2177	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 08:15:26.153357
2178	1	unknown	GET	/api/scopes	307	172.19.0.1	\N	2025-10-28 08:15:26.253259
2183	1	unknown	OPTIONS	/api/roles/	200	172.19.0.1	\N	2025-10-28 08:15:26.307447
2184	1	unknown	OPTIONS	/api/scopes/	200	172.19.0.1	\N	2025-10-28 08:15:26.321109
2190	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:15:31.377773
2195	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:16:22.418643
2390	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:39:39.072404
2395	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:40:32.661907
2400	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:41:26.546946
2405	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:42:19.020304
2410	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:43:12.790983
2415	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:44:04.018871
2420	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:44:54.678423
2425	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:45:45.386457
2430	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:46:35.823483
2434	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:47:06.350782
973	1	unknown	GET	/api/bindings	401	172.19.0.1	\N	2025-10-28 04:35:07.742913
1149	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 05:59:54.760845
1154	1	unknown	GET	/api/scopes	401	172.19.0.1	\N	2025-10-28 05:59:54.837338
1704	1	unknown	OPTIONS	/api/bindings	200	172.19.0.1	\N	2025-10-28 07:24:56.762616
2179	1	unknown	GET	/api/roles	307	172.19.0.1	\N	2025-10-28 08:15:26.23801
2180	1	unknown	OPTIONS	/api/bindings	200	172.19.0.1	\N	2025-10-28 08:15:26.215885
2185	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 08:15:26.43317
2186	1	unknown	GET	/api/scopes/	200	172.19.0.1	\N	2025-10-28 08:15:26.52268
2188	1	unknown	GET	/api/roles/	200	172.19.0.1	\N	2025-10-28 08:15:26.533574
2191	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:15:41.501797
2194	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:16:12.296585
2196	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:16:32.527802
2391	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:39:50.426849
2396	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:40:42.974321
2401	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:41:37.774393
2406	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:42:29.487694
2411	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:43:23.029659
2416	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:44:14.11755
2421	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:45:04.837647
2426	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:45:55.516142
2431	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:46:45.925471
974	1	unknown	GET	/api/tenants	401	172.19.0.1	\N	2025-10-28 04:35:07.744498
1148	1	unknown	OPTIONS	/api/tenants	200	172.19.0.1	\N	2025-10-28 05:59:54.751561
1156	1	unknown	GET	/api/roles	401	172.19.0.1	\N	2025-10-28 05:59:54.839378
1740	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 07:29:32.929797
1739	1	unknown	GET	/api/tenants	307	172.19.0.1	\N	2025-10-28 07:29:32.928614
1737	1	unknown	GET	/api/scopes	307	172.19.0.1	\N	2025-10-28 07:29:32.929242
1736	1	unknown	GET	/api/scopes	307	172.19.0.1	\N	2025-10-28 07:29:32.930637
1741	1	unknown	OPTIONS	/api/tenants/	200	172.19.0.1	\N	2025-10-28 07:29:33.01422
1743	1	unknown	GET	/api/scopes/	200	172.19.0.1	\N	2025-10-28 07:29:33.114417
1744	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 07:29:33.123121
1745	1	unknown	GET	/api/tenants/	200	172.19.0.1	\N	2025-10-28 07:29:33.162372
1746	1	unknown	GET	/api/scopes/	200	172.19.0.1	\N	2025-10-28 07:29:33.214706
1747	1	unknown	GET	/api/tenants/	200	172.19.0.1	\N	2025-10-28 07:29:33.231824
1748	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 07:29:33.238299
1749	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:29:33.631291
1751	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:29:54.213809
1752	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:30:05.484774
1753	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:30:15.624997
1754	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:30:25.753154
1756	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:30:47.210959
1757	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:30:57.317858
1758	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:31:08.463708
1759	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:31:18.833336
1761	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:31:40.284386
1762	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:31:50.490961
2181	1	unknown	OPTIONS	/api/tenants/	200	172.19.0.1	\N	2025-10-28 08:15:26.288022
2189	1	unknown	GET	/api/tenants/	200	172.19.0.1	\N	2025-10-28 08:15:26.534581
2193	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:16:01.883158
2392	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:40:01.533729
2397	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:40:53.525275
2402	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:41:48.029054
2407	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:42:39.856949
2412	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:43:33.471722
2417	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:44:24.228208
2422	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:45:14.970034
2427	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:46:05.586975
2432	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:46:56.073192
975	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:35:11.992454
982	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 04:35:30.434755
986	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:35:53.469768
991	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:36:45.944242
996	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:37:37.450472
1001	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:38:29.871761
1006	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:39:22.23033
1142	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 05:59:54.74987
1151	1	unknown	GET	/api/roles	401	172.19.0.1	\N	2025-10-28 05:59:54.829512
1166	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:01:16.63672
1171	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:02:07.862011
1176	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:03:01.314371
1181	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:03:53.850943
1186	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:04:46.375055
1191	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:05:38.437742
1196	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:06:31.694039
1201	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:07:25.101504
1206	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:08:17.916685
1211	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:09:10.101309
1216	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:10:02.582124
1221	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:10:54.923084
1738	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 07:29:32.931015
2182	1	unknown	OPTIONS	/api/bindings/	200	172.19.0.1	\N	2025-10-28 08:15:26.303629
2187	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 08:15:26.533121
2192	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:15:51.728934
2197	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:16:42.939338
2435	1	unknown	GET	/api/users	403	172.19.0.1	\N	2025-10-28 08:47:16.253242
2438	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:47:37.846548
2442	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 08:47:38.499806
2446	1	unknown	OPTIONS	/api/roles	200	172.19.0.1	\N	2025-10-28 08:47:40.651197
2451	1	unknown	OPTIONS	/api/scopes	200	172.19.0.1	\N	2025-10-28 08:47:40.713334
2455	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 08:47:40.739691
2463	1	unknown	GET	/api/scopes/	200	172.19.0.1	\N	2025-10-28 08:47:40.830691
2466	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 08:47:40.859758
2471	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:48:08.234682
2476	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:48:59.047165
2481	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:49:49.894251
2486	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:50:40.679639
2491	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:51:31.459452
2496	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:52:22.13833
2501	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:53:12.746106
2506	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:54:03.187686
2511	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:54:53.746856
2517	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:55:34.368769
2522	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:56:24.923384
2525	1	unknown	GET	/api/tenants	307	172.19.0.1	\N	2025-10-28 08:56:33.111895
2531	1	unknown	GET	/api/scopes	307	172.19.0.1	\N	2025-10-28 08:56:33.157924
2534	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 08:56:33.177822
2539	1	unknown	GET	/api/tenants/	200	172.19.0.1	\N	2025-10-28 08:56:33.257357
2543	1	unknown	GET	/api/roles/	200	172.19.0.1	\N	2025-10-28 08:56:33.351945
2546	1	unknown	GET	/api/scopes/	200	172.19.0.1	\N	2025-10-28 08:56:33.396023
2549	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:56:45.01243
2554	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:57:35.646595
2559	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:58:26.257546
2564	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:59:16.696458
2569	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:00:07.398595
2574	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:00:58.214125
2579	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:01:48.911876
2584	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:02:39.709864
2589	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:03:30.530455
2594	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:04:21.1993
2599	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:05:12.243053
2604	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:06:03.047174
2609	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:06:53.803751
2614	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:07:44.546682
2619	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:08:35.2848
2624	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:09:25.920916
2629	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:10:16.79374
2634	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:11:07.520968
2639	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:11:58.213177
2644	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:12:48.847595
2649	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:13:39.543054
2654	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:14:30.335023
2659	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:15:21.042662
2664	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:16:11.773264
2669	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:17:02.822734
2674	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:17:53.523596
2679	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:18:44.286911
2684	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:19:35.027909
2689	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:20:25.764287
2694	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:21:16.525819
2699	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:22:07.474462
2704	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:22:58.369217
2709	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:23:49.219183
2712	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 09:23:53.526608
2716	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 09:24:01.488771
1009	1	unknown	OPTIONS	/api/tenants	200	172.19.0.1	\N	2025-10-28 04:39:51.882473
1023	1	unknown	GET	/api/bindings	403	172.19.0.1	\N	2025-10-28 04:40:10.919866
1028	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:40:59.695808
1033	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:41:52.060236
1038	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:42:43.574026
1043	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:43:36.05559
1150	1	unknown	GET	/api/users	401	172.19.0.1	\N	2025-10-28 05:59:54.7767
1161	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:00:23.755538
1165	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:01:05.321358
1170	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:01:57.736647
1175	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:02:50.09455
1180	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:03:42.181865
1185	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:04:36.227782
1190	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:05:28.17627
1195	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:06:21.526904
1200	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:07:14.885888
1205	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:08:07.702092
1210	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:08:59.957348
1215	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:09:51.777816
1220	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:10:43.741939
1735	1	unknown	GET	/api/tenants	307	172.19.0.1	\N	2025-10-28 07:29:32.927529
2198	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:17:02.266309
2199	1	unknown	POST	/auth/login	200	172.19.0.1	\N	2025-10-28 08:17:07.450768
2200	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 08:17:08.443658
2201	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 08:17:08.49599
2203	1	unknown	GET	/api/roles	307	172.19.0.1	\N	2025-10-28 08:17:12.568538
2205	1	unknown	GET	/api/roles	307	172.19.0.1	\N	2025-10-28 08:17:12.621386
2209	1	unknown	GET	/api/scopes	307	172.19.0.1	\N	2025-10-28 08:17:12.649002
2218	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:17:12.711646
2220	1	unknown	GET	/api/scopes/	200	172.19.0.1	\N	2025-10-28 08:17:12.733566
2436	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:47:16.451216
2440	1	unknown	OPTIONS	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 08:47:38.449653
2443	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 08:47:38.534682
2448	1	unknown	GET	/api/roles	307	172.19.0.1	\N	2025-10-28 08:47:40.667257
2464	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 08:47:40.836975
2469	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:47:47.96065
2474	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:48:38.561684
2479	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:49:29.683939
2484	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:50:20.41297
2489	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:51:11.203414
2494	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:52:01.847479
2499	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:52:52.62438
2504	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:53:43.072258
2509	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:54:33.490618
2514	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:55:24.184367
2520	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:56:04.701843
2523	1	unknown	GET	/api/tenants	307	172.19.0.1	\N	2025-10-28 08:56:33.087266
2529	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 08:56:33.152805
2535	1	unknown	OPTIONS	/api/roles/	200	172.19.0.1	\N	2025-10-28 08:56:33.18312
2544	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 08:56:33.380429
2550	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:56:55.147782
2555	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:57:45.820008
2560	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:58:36.30353
2565	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:59:26.743501
2570	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:00:17.583456
2575	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:01:08.359689
2580	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:01:59.067829
2585	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:02:49.828668
2590	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:03:40.656763
2595	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:04:31.397578
2600	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:05:22.345274
2605	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:06:13.187491
2610	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:07:03.992345
2615	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:07:54.650889
2620	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:08:45.389978
2625	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:09:36.133303
2630	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:10:26.935282
2635	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:11:17.626686
2640	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:12:08.312373
2645	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:12:59.047937
2650	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:13:49.676463
2655	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:14:40.459959
2660	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:15:31.303797
2665	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:16:21.883658
2670	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:17:12.927538
2675	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:18:03.732065
2680	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:18:54.391563
2685	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:19:45.159572
2690	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:20:35.974987
2695	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:21:26.634369
2700	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:22:17.634109
2705	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:23:08.608943
2710	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 09:23:53.407242
2717	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:24:09.542273
2721	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:24:40.028774
1010	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 04:39:51.88569
1222	1	unknown	POST	/auth/login	200	172.19.0.1	\N	2025-10-28 06:11:21.218796
1223	1	unknown	OPTIONS	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 06:11:22.718756
1226	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:11:38.147602
1228	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:11:59.512426
1230	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:12:19.864062
1232	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:12:40.731955
1234	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:13:02.233081
1236	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:13:23.226145
1238	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:13:44.020865
1240	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:14:04.879632
1242	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:14:26.174514
1244	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:14:46.984284
1246	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:15:08.948985
1248	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:15:29.50191
1250	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:15:50.882781
1252	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:16:11.836105
1254	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:16:33.314955
1256	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:16:53.840122
1258	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:17:15.147691
1260	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:17:35.466873
1262	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:17:57.278268
1264	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:18:18.018294
1266	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:18:38.259563
1268	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:18:59.15278
1742	1	unknown	OPTIONS	/api/tenants/	200	172.19.0.1	\N	2025-10-28 07:29:33.024253
1750	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:29:43.85388
1755	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:30:37.091626
1760	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:31:29.100737
2202	1	unknown	GET	/api/tenants	307	172.19.0.1	\N	2025-10-28 08:17:12.556768
2204	1	unknown	GET	/api/tenants	307	172.19.0.1	\N	2025-10-28 08:17:12.576335
2437	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:47:26.585202
2441	1	unknown	OPTIONS	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 08:47:38.468638
2444	1	unknown	OPTIONS	/api/tenants	200	172.19.0.1	\N	2025-10-28 08:47:40.634258
2449	1	unknown	OPTIONS	/api/bindings	200	172.19.0.1	\N	2025-10-28 08:47:40.671085
2452	1	unknown	OPTIONS	/api/bindings	200	172.19.0.1	\N	2025-10-28 08:47:40.721766
2459	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 08:47:40.786046
2460	1	unknown	GET	/api/roles/	200	172.19.0.1	\N	2025-10-28 08:47:40.803646
2461	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 08:47:40.822406
2468	1	unknown	GET	/api/tenants/	200	172.19.0.1	\N	2025-10-28 08:47:40.867137
2473	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:48:28.439882
2478	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:49:19.482138
2483	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:50:10.231087
2488	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:51:01.090577
2493	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:51:51.705427
2498	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:52:42.456332
2503	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:53:32.937046
2508	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:54:23.471915
2513	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:55:14.064069
2519	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:55:54.585451
2527	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 08:56:33.137154
2532	1	unknown	GET	/api/roles	307	172.19.0.1	\N	2025-10-28 08:56:33.160826
2538	1	unknown	OPTIONS	/api/scopes/	200	172.19.0.1	\N	2025-10-28 08:56:33.210809
2541	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 08:56:33.262182
2551	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:57:05.273188
2556	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:57:55.935306
2561	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:58:46.462578
2566	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:59:36.939309
2571	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:00:27.785834
2576	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:01:18.509947
2581	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:02:09.211164
2586	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:03:00.027579
2591	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:03:50.769407
2596	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:04:41.650572
2601	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:05:32.587066
2606	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:06:23.315092
2611	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:07:14.107909
2616	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:08:04.854019
2621	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:08:55.500333
2626	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:09:46.253633
2631	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:10:37.065098
2636	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:11:27.795184
2641	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:12:18.430622
2646	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:13:09.158398
2651	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:13:59.872836
2656	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:14:50.587228
2661	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:15:41.406052
2666	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:16:32.190197
2671	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:17:23.082594
2676	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:18:13.830218
2681	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:19:04.596233
2686	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:19:55.256417
2691	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:20:46.113881
2696	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:21:36.856288
2701	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:22:27.874845
2706	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:23:18.715415
2711	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 09:23:53.408401
1011	1	unknown	OPTIONS	/api/roles	200	172.19.0.1	\N	2025-10-28 04:39:51.889427
1019	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 04:39:51.966247
1025	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:40:28.43633
1030	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:41:20.817965
1035	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:42:12.275707
1040	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:43:04.690345
1045	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:43:57.245962
1224	1	unknown	OPTIONS	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 06:11:22.782888
1225	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:11:27.363225
1227	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:11:49.312991
1229	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:12:09.692505
1231	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:12:30.037748
1233	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:12:51.809185
1235	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:13:13.084194
1237	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:13:33.858353
1239	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:13:54.197572
1241	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:14:15.198456
1243	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:14:36.705509
1245	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:14:57.30543
1247	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:15:19.156558
1249	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:15:40.670113
1251	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:16:01.234582
1253	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:16:22.007417
1255	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:16:43.540384
1257	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:17:04.105431
1259	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:17:25.327172
1261	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:17:46.323734
1263	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:18:07.384235
1265	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:18:28.141582
1267	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:18:48.992539
1763	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:32:11.873345
1764	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:32:22.04416
1765	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:32:32.282666
1766	1	unknown	GET	/api/roles	307	172.19.0.1	\N	2025-10-28 07:32:38.501281
1769	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 07:32:38.582382
1780	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 07:32:38.945833
1787	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:33:04.019762
1792	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:33:57.143401
1797	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:34:50.069169
1802	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:35:41.793223
1807	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:36:35.186511
1812	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:37:27.594042
1817	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:38:20.718693
1822	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:39:12.513717
1827	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:40:05.775231
2206	1	unknown	GET	/api/scopes	307	172.19.0.1	\N	2025-10-28 08:17:12.623463
2210	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 08:17:12.65832
2212	1	unknown	GET	/api/roles/	200	172.19.0.1	\N	2025-10-28 08:17:12.672025
2214	1	unknown	GET	/api/scopes/	200	172.19.0.1	\N	2025-10-28 08:17:12.701675
2222	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 08:17:32.276938
2226	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:18:03.590643
2231	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:18:54.741262
2236	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:19:45.911032
2241	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:20:36.863174
2246	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:21:28.289298
2251	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:22:19.453939
2256	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:23:10.7338
2261	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:24:02.051249
2266	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:24:53.293455
2271	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:25:44.396311
2276	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:26:35.413301
2281	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:27:26.733373
2286	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:28:17.974077
2291	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:29:08.824174
2296	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:29:59.902041
2301	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:31:03.300952
2306	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:31:54.939958
2311	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:32:45.981183
2316	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:33:37.525787
2321	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:34:28.400247
2326	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:35:19.916216
2331	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:36:37.81319
2336	1	unknown	OPTIONS	/api/tenants	200	172.19.0.1	\N	2025-10-28 08:37:35.784396
2341	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 08:37:35.994084
2347	1	unknown	GET	/api/tenants	307	172.19.0.1	\N	2025-10-28 08:37:36.353627
2352	1	unknown	GET	/api/scopes	307	172.19.0.1	\N	2025-10-28 08:37:37.135432
2355	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 08:37:38.147343
2358	1	unknown	OPTIONS	/farms	200	172.19.0.1	\N	2025-10-28 08:37:56.062357
2363	1	unknown	GET	/batches/	404	172.19.0.1	\N	2025-10-28 08:37:56.316282
2368	1	unknown	OPTIONS	/api/roles/	200	172.19.0.1	\N	2025-10-28 08:37:57.622164
2375	1	unknown	GET	/api/scopes/	200	172.19.0.1	\N	2025-10-28 08:37:58.128016
2380	1	unknown	GET	/api/roles/	200	172.19.0.1	\N	2025-10-28 08:37:58.628206
2384	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:38:33.757758
2439	1	unknown	POST	/auth/login	200	172.19.0.1	\N	2025-10-28 08:47:37.846862
2447	1	unknown	GET	/api/tenants	307	172.19.0.1	\N	2025-10-28 08:47:40.652073
2453	1	unknown	GET	/api/roles	307	172.19.0.1	\N	2025-10-28 08:47:40.723051
2456	1	unknown	GET	/api/scopes	307	172.19.0.1	\N	2025-10-28 08:47:40.76508
1012	1	unknown	OPTIONS	/api/bindings	200	172.19.0.1	\N	2025-10-28 04:39:51.893173
1269	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:19:30.583939
1270	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:19:40.712267
1271	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:19:51.371246
1767	1	unknown	GET	/api/roles	307	172.19.0.1	\N	2025-10-28 07:32:38.574857
1777	1	unknown	GET	/api/roles/	200	172.19.0.1	\N	2025-10-28 07:32:38.849128
1778	1	unknown	GET	/api/tenants/	200	172.19.0.1	\N	2025-10-28 07:32:38.936612
1781	1	unknown	GET	/api/scopes/	200	172.19.0.1	\N	2025-10-28 07:32:38.963693
1782	1	unknown	GET	/api/tenants/	200	172.19.0.1	\N	2025-10-28 07:32:38.978961
1786	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:32:53.825504
1791	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:33:46.958394
1796	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:34:38.949599
1801	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:35:31.680778
1806	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:36:24.037422
1811	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:37:16.945185
1816	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:38:09.482415
1821	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:39:02.364688
1826	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:39:55.499815
2207	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 08:17:12.635794
2215	1	unknown	GET	/api/roles/	200	172.19.0.1	\N	2025-10-28 08:17:12.703286
2219	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 08:17:12.727654
2224	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:17:43.352818
2229	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:18:34.215898
2234	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:19:25.381254
2239	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:20:16.593028
2244	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:21:07.715111
2249	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:21:58.872688
2254	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:22:50.375009
2259	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:23:41.487528
2264	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:24:32.727705
2269	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:25:23.940716
2274	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:26:15.021811
2279	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:27:06.238985
2284	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:27:57.375824
2289	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:28:48.572225
2294	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:29:39.41102
2299	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:30:42.472626
2304	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:31:34.289857
2309	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:32:25.759464
2314	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:33:16.845634
2319	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:34:07.986302
2324	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:34:59.26479
2329	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:36:13.73797
2334	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:37:14.006657
2339	1	unknown	OPTIONS	/api/scopes	200	172.19.0.1	\N	2025-10-28 08:37:35.927506
2345	1	unknown	OPTIONS	/api/bindings	200	172.19.0.1	\N	2025-10-28 08:37:36.294939
2349	1	unknown	GET	/api/scopes	307	172.19.0.1	\N	2025-10-28 08:37:36.903117
2356	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 08:37:38.35611
2361	1	unknown	OPTIONS	/batches/	200	172.19.0.1	\N	2025-10-28 08:37:56.156534
2366	1	unknown	GET	/batches/	404	172.19.0.1	\N	2025-10-28 08:37:56.497038
2372	1	unknown	OPTIONS	/api/roles/	200	172.19.0.1	\N	2025-10-28 08:37:57.731012
2378	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 08:37:58.584725
2385	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:38:44.256834
2445	1	unknown	OPTIONS	/api/roles	200	172.19.0.1	\N	2025-10-28 08:47:40.635434
2450	1	unknown	GET	/api/tenants	307	172.19.0.1	\N	2025-10-28 08:47:40.692814
2454	1	unknown	OPTIONS	/api/scopes	200	172.19.0.1	\N	2025-10-28 08:47:40.73222
2457	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 08:47:40.771783
2462	1	unknown	GET	/api/tenants/	200	172.19.0.1	\N	2025-10-28 08:47:40.829786
2470	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:47:58.128528
2475	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:48:48.731372
2480	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:49:39.785002
2485	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:50:30.557511
2490	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:51:21.309071
2495	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:52:12.018613
2500	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:53:02.595653
2505	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:53:53.194508
2510	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:54:43.614158
2516	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 08:55:26.989952
2521	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:56:14.826355
2524	1	unknown	GET	/api/scopes	307	172.19.0.1	\N	2025-10-28 08:56:33.105605
2528	1	unknown	OPTIONS	/api/tenants/	200	172.19.0.1	\N	2025-10-28 08:56:33.150758
2533	1	unknown	OPTIONS	/api/tenants/	200	172.19.0.1	\N	2025-10-28 08:56:33.168258
2537	1	unknown	OPTIONS	/api/roles/	200	172.19.0.1	\N	2025-10-28 08:56:33.210106
2540	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 08:56:33.260076
2545	1	unknown	GET	/api/tenants/	200	172.19.0.1	\N	2025-10-28 08:56:33.386868
2548	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:56:34.897873
2553	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:57:25.501909
2558	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:58:16.055916
2563	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:59:06.584373
2568	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:59:57.199628
2573	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:00:48.083745
2578	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:01:38.801462
2583	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:02:29.576751
2588	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:03:20.329004
2593	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:04:11.083349
2598	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:05:02.117655
1013	1	unknown	OPTIONS	/api/tenants	200	172.19.0.1	\N	2025-10-28 04:39:51.896392
1272	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:20:02.878345
1273	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:20:13.274436
1274	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:20:24.094669
1275	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:20:34.376306
1276	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:20:45.299297
1277	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:20:55.538708
1278	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:21:05.868405
1279	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:21:16.706062
1280	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:21:27.742434
1281	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:21:37.951859
1282	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:21:48.729026
1283	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:21:58.90317
1284	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:22:09.181487
1285	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:22:20.762839
1286	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:22:31.042851
1287	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:22:41.234445
1288	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:22:52.433418
1289	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:23:02.794755
1290	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:23:12.967379
1291	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:23:24.168191
1292	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:23:34.394634
1293	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:23:44.529818
1294	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:23:55.677265
1295	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:24:06.080387
1296	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:24:16.311011
1297	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:24:26.899055
1298	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:24:37.177771
1299	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:24:47.341486
1300	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:24:58.241146
1301	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:25:08.415631
1302	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:25:18.560959
1303	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:25:29.573349
1304	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:25:39.711563
1305	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:25:49.884299
1306	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:26:00.375492
1307	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:26:11.54751
1308	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:26:21.696864
1309	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:26:32.247914
1310	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:26:42.40313
1311	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:26:52.590956
1312	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:27:03.208652
1313	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:27:13.396044
1314	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:27:23.607024
1315	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:27:34.04328
1316	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:27:44.906712
1317	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:27:55.059908
1318	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:28:05.266255
1319	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:28:16.301666
1320	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:28:26.579587
1321	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:28:36.758745
1322	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:28:48.047169
1323	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:28:58.117908
1324	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:29:08.842775
1325	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:29:19.14545
1326	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:29:29.734182
1327	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:29:39.88446
1328	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:29:50.941321
1329	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:30:01.292332
1330	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:30:11.416672
1331	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:30:22.613521
1332	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:30:32.587814
1333	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:30:42.738405
1334	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:30:52.929663
1335	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:31:04.163964
1336	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:31:14.33325
1337	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:31:24.501748
1338	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:31:35.409237
1339	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:31:45.619218
1340	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:31:55.764331
1341	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:32:06.81634
1342	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:32:17.048697
1343	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:32:27.214069
1344	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:32:37.56514
1345	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:32:47.71573
1346	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:32:57.896083
1347	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:33:08.841957
1348	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:33:19.006485
1349	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:33:29.188407
1350	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:33:39.743582
1351	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:33:49.891123
1352	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:34:00.798806
1353	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:34:11.583521
1354	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:34:21.710096
1355	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:34:31.851453
1356	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:34:42.685374
1357	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:34:53.459675
1358	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:35:03.651328
1014	1	unknown	OPTIONS	/api/roles	200	172.19.0.1	\N	2025-10-28 04:39:51.899625
1359	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:35:13.945028
1360	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:35:24.119653
1361	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:35:34.247007
1362	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:35:45.575361
1363	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:35:55.767067
1364	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:36:05.970533
1365	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:36:16.421272
1366	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:36:27.606085
1367	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:36:37.73661
1368	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:36:48.298657
1369	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:36:58.481523
1370	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:37:08.652197
1371	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:37:19.895292
1372	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:37:30.106207
1373	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:37:40.222147
1374	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:37:50.649293
1375	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:38:00.795876
1376	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:38:10.984938
1377	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:38:22.121352
1378	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:38:32.292777
1379	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:38:42.509675
1380	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:38:53.043623
1381	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:39:04.016777
1382	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:39:14.866239
1383	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:39:24.978236
1384	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:39:35.194494
1385	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:39:45.877495
1386	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:39:56.136681
1387	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:40:06.389874
1388	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:40:17.153361
1389	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:40:27.288877
1390	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:40:37.419874
1391	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:40:47.946044
1392	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:40:58.245029
1393	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:41:09.31556
1394	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:41:19.190892
1395	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:41:29.43422
1396	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:41:40.434089
1397	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:41:50.293537
1398	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:42:00.571085
1768	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 07:32:38.574456
1774	1	unknown	OPTIONS	/api/roles/	200	172.19.0.1	\N	2025-10-28 07:32:38.756663
1779	1	unknown	GET	/api/roles/	200	172.19.0.1	\N	2025-10-28 07:32:38.944381
1785	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:32:43.535777
1790	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:33:35.728174
1795	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:34:28.808404
1800	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:35:21.573003
1805	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:36:13.299129
1810	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:37:06.325752
1815	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:37:59.163675
1820	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:38:52.222965
1825	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:39:44.158158
1830	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:40:37.39797
2208	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 08:17:12.64394
2211	1	unknown	GET	/api/tenants/	200	172.19.0.1	\N	2025-10-28 08:17:12.668207
2213	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 08:17:12.688466
2217	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 08:17:12.710528
2221	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:17:22.825913
2225	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:17:53.463566
2230	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:18:44.60891
2235	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:19:35.508331
2240	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:20:26.717347
2245	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:21:18.120356
2250	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:22:08.978037
2255	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:23:00.568705
2260	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:23:51.883822
2265	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:24:43.149569
2270	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:25:34.071361
2275	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:26:25.277432
2280	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:27:16.62219
2285	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:28:07.583821
2290	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:28:58.697831
2295	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:29:49.713126
2300	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:30:52.978296
2305	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:31:44.444341
2310	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:32:35.870957
2315	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:33:26.979976
2320	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:34:18.281667
2325	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:35:09.840989
2330	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:36:25.964634
2335	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:37:25.290363
2340	1	unknown	OPTIONS	/api/bindings	200	172.19.0.1	\N	2025-10-28 08:37:35.92868
2344	1	unknown	OPTIONS	/api/roles	200	172.19.0.1	\N	2025-10-28 08:37:36.239046
2350	1	unknown	GET	/api/roles	307	172.19.0.1	\N	2025-10-28 08:37:36.925879
2354	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:37:37.436015
2360	1	unknown	OPTIONS	/suppliers	200	172.19.0.1	\N	2025-10-28 08:37:56.15487
2365	1	unknown	GET	/farms	404	172.19.0.1	\N	2025-10-28 08:37:56.450178
1015	1	unknown	OPTIONS	/api/scopes	200	172.19.0.1	\N	2025-10-28 04:39:51.903071
1399	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:42:14.283792
1400	1	unknown	OPTIONS	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 06:42:19.935483
1402	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:42:25.563117
1404	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:42:46.087379
1406	1	unknown	GET	/api/dashboard/summary	403	172.19.0.1	\N	2025-10-28 06:43:04.93542
1408	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:43:16.992357
1410	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:43:37.612644
1412	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:43:58.339841
1414	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:44:19.042762
1416	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:44:39.521021
1418	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:45:00.971929
1420	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:45:21.501698
1422	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:45:41.789763
1424	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:46:02.527804
1426	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:46:23.204897
1428	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:46:44.239955
1430	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:47:04.925538
1432	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:47:26.469053
1434	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:47:47.339036
1436	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:48:08.831921
1438	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:48:30.335424
1440	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:48:50.792694
1442	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:49:12.028767
1444	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:49:32.587284
1446	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:49:52.915263
1448	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:50:13.568089
1450	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:50:34.63787
1770	1	unknown	GET	/api/scopes	307	172.19.0.1	\N	2025-10-28 07:32:38.581115
1776	1	unknown	OPTIONS	/api/bindings/	200	172.19.0.1	\N	2025-10-28 07:32:38.848613
1783	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 07:32:38.981426
1788	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:33:15.281519
1793	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:34:07.295112
1798	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:35:00.204926
1803	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:35:52.893059
1808	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:36:45.326958
1813	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:37:37.76853
1818	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:38:30.890444
1823	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:39:23.757271
1828	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:40:15.959335
2216	1	unknown	GET	/api/tenants/	200	172.19.0.1	\N	2025-10-28 08:17:12.707193
2227	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:18:13.969429
2232	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:19:04.83863
2237	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:19:56.076827
2242	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:20:47.285204
2247	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:21:38.413532
2252	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:22:29.767193
2257	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:23:21.140765
2262	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:24:12.456907
2267	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:25:03.41239
2272	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:25:54.4974
2277	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:26:45.803911
2282	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:27:36.850208
2287	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:28:28.087452
2292	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:29:19.110901
2297	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:30:10.146
2302	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:31:13.520526
2307	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:32:05.106781
2312	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:32:56.479614
2317	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:33:47.678093
2322	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:34:38.978539
2327	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:35:30.016254
2332	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:36:50.834494
2337	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 08:37:35.838716
2342	1	unknown	OPTIONS	/api/tenants	200	172.19.0.1	\N	2025-10-28 08:37:36.152034
2346	1	unknown	GET	/api/roles	307	172.19.0.1	\N	2025-10-28 08:37:36.335531
2351	1	unknown	GET	/api/tenants	307	172.19.0.1	\N	2025-10-28 08:37:36.932056
2357	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:37:48.859398
2362	1	unknown	GET	/farms	404	172.19.0.1	\N	2025-10-28 08:37:56.285922
2367	1	unknown	GET	/suppliers	404	172.19.0.1	\N	2025-10-28 08:37:56.499014
2371	1	unknown	OPTIONS	/api/bindings/	200	172.19.0.1	\N	2025-10-28 08:37:57.716154
2373	1	unknown	GET	/api/tenants/	200	172.19.0.1	\N	2025-10-28 08:37:58.108836
2381	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:38:00.214335
2386	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:38:54.834124
2458	1	unknown	GET	/api/scopes	307	172.19.0.1	\N	2025-10-28 08:47:40.785615
2465	1	unknown	GET	/api/roles/	200	172.19.0.1	\N	2025-10-28 08:47:40.85016
2467	1	unknown	GET	/api/scopes/	200	172.19.0.1	\N	2025-10-28 08:47:40.865366
2472	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:48:18.397002
2477	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:49:09.289384
2482	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:50:00.068973
2487	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:50:50.92848
2492	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:51:41.595078
2497	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:52:32.319564
2502	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:53:22.960236
2507	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:54:13.3444
2512	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:55:03.858499
2515	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 08:55:26.952767
1016	1	unknown	OPTIONS	/api/scopes	200	172.19.0.1	\N	2025-10-28 04:39:51.907161
1401	1	unknown	OPTIONS	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 06:42:19.992666
1403	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:42:35.903958
1405	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:42:56.494878
1407	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:43:06.715441
1409	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:43:27.451729
1411	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:43:47.831673
1413	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:44:08.488599
1415	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:44:29.363704
1417	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:44:50.676245
1419	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:45:11.118948
1421	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:45:31.61867
1423	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:45:52.277389
1425	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:46:12.667137
1427	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:46:34.095903
1429	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:46:54.758327
1431	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:47:15.238848
1433	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:47:36.979845
1435	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:47:58.18822
1437	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:48:19.017563
1439	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:48:40.507199
1441	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:49:01.789937
1443	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:49:22.193925
1445	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:49:42.741336
1447	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:50:03.377125
1449	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:50:23.76974
1771	1	unknown	GET	/api/tenants	307	172.19.0.1	\N	2025-10-28 07:32:38.585541
1775	1	unknown	OPTIONS	/api/bindings/	200	172.19.0.1	\N	2025-10-28 07:32:38.846514
1784	1	unknown	GET	/api/scopes/	200	172.19.0.1	\N	2025-10-28 07:32:38.989908
1789	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:33:25.580667
1794	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:34:18.614649
1799	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:35:10.344291
1804	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:36:03.035378
1809	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:36:56.199253
1814	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:37:49.008987
1819	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:38:41.045365
1824	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:39:33.97325
1829	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:40:27.256339
2223	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:17:32.950396
2228	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:18:24.088276
2233	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:19:15.261375
2238	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:20:06.198973
2243	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:20:57.420295
2248	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:21:48.760792
2253	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:22:39.880004
2258	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:23:31.370831
2263	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:24:22.599082
2268	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:25:13.800811
2273	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:26:04.617163
2278	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:26:56.035198
2283	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:27:47.247194
2288	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:28:38.284129
2293	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:29:29.294395
2298	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:30:32.305833
2303	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:31:24.043806
2308	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:32:15.816032
2313	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:33:06.61726
2318	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:33:57.851528
2323	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:34:49.032612
2328	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:35:53.209892
2333	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:37:02.274939
2338	1	unknown	OPTIONS	/api/roles	200	172.19.0.1	\N	2025-10-28 08:37:35.892742
2343	1	unknown	OPTIONS	/api/scopes	200	172.19.0.1	\N	2025-10-28 08:37:36.191176
2348	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 08:37:36.729035
2353	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 08:37:37.345637
2359	1	unknown	OPTIONS	/batches/	200	172.19.0.1	\N	2025-10-28 08:37:56.115913
2364	1	unknown	GET	/suppliers	404	172.19.0.1	\N	2025-10-28 08:37:56.352045
2369	1	unknown	OPTIONS	/api/tenants/	200	172.19.0.1	\N	2025-10-28 08:37:57.643054
2376	1	unknown	GET	/api/roles/	200	172.19.0.1	\N	2025-10-28 08:37:58.172741
2377	1	unknown	GET	/api/tenants/	200	172.19.0.1	\N	2025-10-28 08:37:58.57907
2382	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:38:11.6834
2387	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:39:05.668565
2518	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:55:44.482588
2526	1	unknown	GET	/api/roles	307	172.19.0.1	\N	2025-10-28 08:56:33.118886
2530	1	unknown	OPTIONS	/api/scopes/	200	172.19.0.1	\N	2025-10-28 08:56:33.155904
2536	1	unknown	OPTIONS	/api/bindings/	200	172.19.0.1	\N	2025-10-28 08:56:33.185228
2542	1	unknown	GET	/api/scopes/	200	172.19.0.1	\N	2025-10-28 08:56:33.271876
2547	1	unknown	GET	/api/roles/	200	172.19.0.1	\N	2025-10-28 08:56:33.438794
2552	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:57:15.377233
2557	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:58:05.927201
2562	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:58:56.44541
2567	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:59:47.075328
2572	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:00:37.912958
2577	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:01:28.674646
2582	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:02:19.345957
2587	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:03:10.144243
2592	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:04:00.941986
1017	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 04:39:51.911347
1451	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:50:44.785157
1453	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:51:05.362607
1455	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:51:25.686603
1457	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:51:46.492631
1459	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:52:07.36957
1461	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:52:27.943074
1463	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:52:48.373658
1465	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:53:09.395662
1467	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:53:30.888176
1772	1	unknown	GET	/api/tenants	307	172.19.0.1	\N	2025-10-28 07:32:38.5998
2370	1	unknown	OPTIONS	/api/scopes/	200	172.19.0.1	\N	2025-10-28 08:37:57.695927
2374	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 08:37:58.1127
2379	1	unknown	GET	/api/scopes/	200	172.19.0.1	\N	2025-10-28 08:37:58.605119
2383	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:38:22.835574
2597	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:04:51.853106
2602	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:05:42.703843
2607	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:06:33.499261
2612	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:07:24.214581
2617	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:08:14.974103
2622	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:09:05.663429
2627	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:09:56.374764
2632	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:10:47.216683
2637	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:11:37.911812
2642	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:12:28.613715
2647	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:13:19.275735
2652	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:14:09.978813
2657	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:15:00.813963
2662	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:15:51.500855
2667	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:16:42.382694
2672	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:17:33.274269
2677	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:18:23.94619
2682	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:19:14.736575
2687	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:20:05.442587
2692	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:20:56.213527
2697	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:21:46.967998
2702	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:22:38.077763
2707	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:23:28.880541
2713	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 09:23:53.550774
2719	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:24:29.787106
2723	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:25:00.341156
1018	1	unknown	OPTIONS	/api/bindings	200	172.19.0.1	\N	2025-10-28 04:39:51.925166
1452	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:50:54.936326
1454	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:51:15.552902
1456	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:51:36.110112
1458	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:51:57.077152
1460	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:52:17.566473
1462	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:52:38.198338
1464	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:52:59.213132
1466	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:53:19.695678
1773	1	unknown	GET	/api/scopes	307	172.19.0.1	\N	2025-10-28 07:32:38.607417
2603	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:05:52.846102
2608	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:06:43.687906
2613	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:07:34.418377
2618	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:08:25.07447
2623	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:09:15.771695
2628	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:10:06.681752
2633	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:10:57.325051
2638	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:11:48.018521
2643	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:12:38.741203
2648	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:13:29.441828
2653	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:14:20.106712
2658	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:15:10.931312
2663	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:16:01.683437
2668	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:16:52.516544
2673	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:17:43.417228
2678	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:18:34.184775
2683	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:19:24.869847
2688	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:20:15.655682
2693	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:21:06.436757
2698	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:21:57.160399
2703	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:22:48.234442
2708	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:23:39.095669
2714	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:23:59.337127
2720	1	unknown	OPTIONS	/api/users/8	200	172.19.0.1	\N	2025-10-28 09:24:34.560646
2724	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:25:10.480303
1020	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 04:39:52.060064
1024	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:40:18.338183
1029	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:41:09.781311
1034	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:42:02.167926
1039	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:42:54.568968
1044	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:43:46.222454
1468	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:53:57.05705
1469	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:54:08.452151
1470	1	unknown	OPTIONS	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 06:54:15.892962
1474	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:54:18.685337
1475	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 06:54:22.729203
1476	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 06:54:22.777563
1478	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 06:54:29.152474
1480	1	unknown	OPTIONS	/api/roles	200	172.19.0.1	\N	2025-10-28 06:54:29.185241
1482	1	unknown	OPTIONS	/api/bindings	200	172.19.0.1	\N	2025-10-28 06:54:29.21009
1485	1	unknown	OPTIONS	/api/scopes	200	172.19.0.1	\N	2025-10-28 06:54:29.236975
1489	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:54:51.00249
1494	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:55:42.771635
1499	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:56:36.645017
1504	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:57:28.373875
1509	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:58:21.594766
1514	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:59:14.340578
1519	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:00:06.225554
1524	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:00:58.551848
1529	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:01:51.217038
1831	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:41:07.469244
1832	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:41:17.617642
1833	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:41:28.758528
1834	1	unknown	GET	/api/users	403	172.19.0.1	\N	2025-10-28 07:41:35.310182
1835	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:41:38.90615
1836	1	unknown	GET	/api/tenants	307	172.19.0.1	\N	2025-10-28 07:41:40.86222
1837	1	unknown	GET	/api/tenants/	403	172.19.0.1	\N	2025-10-28 07:41:40.883495
1838	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:41:49.145985
1839	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:42:00.385914
1840	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:42:10.562258
1841	1	unknown	POST	/auth/login	200	172.19.0.1	\N	2025-10-28 07:42:15.48802
1842	1	unknown	OPTIONS	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 07:42:16.107687
1843	1	unknown	OPTIONS	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 07:42:16.123156
1844	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 07:42:16.186714
1845	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 07:42:16.208101
1847	1	unknown	OPTIONS	/api/tenants	200	172.19.0.1	\N	2025-10-28 07:42:20.48366
1848	1	unknown	OPTIONS	/api/roles	200	172.19.0.1	\N	2025-10-28 07:42:20.506093
1850	1	unknown	OPTIONS	/api/scopes	200	172.19.0.1	\N	2025-10-28 07:42:20.516436
1853	1	unknown	OPTIONS	/api/scopes	200	172.19.0.1	\N	2025-10-28 07:42:20.558422
1856	1	unknown	GET	/api/scopes	307	172.19.0.1	\N	2025-10-28 07:42:20.571679
1869	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 07:42:20.768746
1871	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:42:20.792897
1874	1	unknown	GET	/api/tenants/	200	172.19.0.1	\N	2025-10-28 07:42:20.838753
1878	1	unknown	GET	/api/tenants	307	172.19.0.1	\N	2025-10-28 07:42:45.390984
1884	1	unknown	GET	/api/scopes	307	172.19.0.1	\N	2025-10-28 07:42:45.461939
1886	1	unknown	GET	/api/tenants/	200	172.19.0.1	\N	2025-10-28 07:42:45.578686
1892	1	unknown	GET	/api/roles/	200	172.19.0.1	\N	2025-10-28 07:42:45.877127
1896	1	unknown	GET	/api/roles/	200	172.19.0.1	\N	2025-10-28 07:42:45.983186
2715	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 09:24:01.461449
2718	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:24:19.664393
2722	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:24:50.147712
1021	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:39:57.25136
1026	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:40:38.547676
1031	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:41:30.954406
1036	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:42:23.360949
1041	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:43:14.779942
1046	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:44:07.342014
1471	1	unknown	OPTIONS	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 06:54:15.935309
1472	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 06:54:15.965508
1473	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 06:54:15.99381
1477	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:54:28.9755
1479	1	unknown	OPTIONS	/api/tenants	200	172.19.0.1	\N	2025-10-28 06:54:29.157415
1481	1	unknown	OPTIONS	/api/scopes	200	172.19.0.1	\N	2025-10-28 06:54:29.187881
1483	1	unknown	OPTIONS	/api/roles	200	172.19.0.1	\N	2025-10-28 06:54:29.218766
1486	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 06:54:29.242299
1488	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:54:39.600174
1493	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:55:32.584059
1498	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:56:25.468997
1503	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:57:18.173585
1508	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:58:11.348518
1513	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:59:03.859031
1518	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:59:55.83347
1523	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:00:48.404973
1528	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:01:40.581278
1533	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:02:32.496608
1846	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 07:42:20.480979
1849	1	unknown	OPTIONS	/api/roles	200	172.19.0.1	\N	2025-10-28 07:42:20.512461
1851	1	unknown	OPTIONS	/api/bindings	200	172.19.0.1	\N	2025-10-28 07:42:20.52944
1855	1	unknown	OPTIONS	/api/bindings	200	172.19.0.1	\N	2025-10-28 07:42:20.562899
1860	1	unknown	GET	/api/roles	307	172.19.0.1	\N	2025-10-28 07:42:20.611137
1866	1	unknown	OPTIONS	/api/scopes/	200	172.19.0.1	\N	2025-10-28 07:42:20.730917
1870	1	unknown	GET	/api/scopes/	200	172.19.0.1	\N	2025-10-28 07:42:20.788254
1873	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 07:42:20.833434
1877	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:42:42.205603
1883	1	unknown	GET	/api/roles	307	172.19.0.1	\N	2025-10-28 07:42:45.452934
1889	1	unknown	OPTIONS	/api/bindings/	200	172.19.0.1	\N	2025-10-28 07:42:45.818345
1891	1	unknown	GET	/api/scopes/	200	172.19.0.1	\N	2025-10-28 07:42:45.868586
1894	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 07:42:45.927699
1899	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:43:03.77186
2725	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:25:33.106211
2726	1	unknown	GET	/api/users	401	172.19.0.1	\N	2025-10-28 09:25:35.586339
2727	1	unknown	GET	/api/users	401	172.19.0.1	\N	2025-10-28 09:25:35.593591
2728	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 09:25:40.199768
2730	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:25:42.859726
2733	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 09:25:49.459769
2735	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:26:03.452723
2737	1	unknown	OPTIONS	/api/users/6	200	172.19.0.1	\N	2025-10-28 09:26:18.241838
2738	1	unknown	PUT	/api/users/6	200	172.19.0.1	{"name": "Phan Minh Toàn", "role": "data_staff", "email": "huynhat@gmail.com"}	2025-10-28 09:26:18.258435
1022	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:40:07.35544
1027	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:40:49.602162
1032	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:41:41.079737
1037	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:42:33.463335
1042	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:43:25.850444
1047	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:44:17.449703
1484	1	unknown	OPTIONS	/api/tenants	200	172.19.0.1	\N	2025-10-28 06:54:29.234719
1491	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:55:11.198416
1496	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:56:05.011456
1501	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:56:57.119095
1506	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:57:50.523328
1511	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:58:43.434795
1516	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:59:34.764393
1521	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:00:27.877492
1526	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:01:20.192471
1531	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:02:11.765575
1852	1	unknown	OPTIONS	/api/tenants	200	172.19.0.1	\N	2025-10-28 07:42:20.546426
1857	1	unknown	GET	/api/roles	307	172.19.0.1	\N	2025-10-28 07:42:20.582086
1863	1	unknown	GET	/api/tenants	307	172.19.0.1	\N	2025-10-28 07:42:20.623529
1865	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 07:42:20.667336
1867	1	unknown	GET	/api/roles/	200	172.19.0.1	\N	2025-10-28 07:42:20.743285
1872	1	unknown	GET	/api/roles/	200	172.19.0.1	\N	2025-10-28 07:42:20.808798
1875	1	unknown	GET	/api/scopes/	200	172.19.0.1	\N	2025-10-28 07:42:20.848703
1880	1	unknown	GET	/api/scopes	307	172.19.0.1	\N	2025-10-28 07:42:45.414904
1882	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 07:42:45.457698
1885	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 07:42:45.54677
1887	1	unknown	OPTIONS	/api/roles/	200	172.19.0.1	\N	2025-10-28 07:42:45.78193
1893	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 07:42:45.889739
1895	1	unknown	GET	/api/scopes/	200	172.19.0.1	\N	2025-10-28 07:42:45.938705
2729	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 09:25:40.24876
2731	1	unknown	OPTIONS	/api/users/7	200	172.19.0.1	\N	2025-10-28 09:25:49.4171
2732	1	unknown	DELETE	/api/users/7	200	172.19.0.1	\N	2025-10-28 09:25:49.441259
2734	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:25:53.175969
2736	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:26:13.66971
2739	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 09:26:18.27297
1048	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 04:44:32.239559
1051	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:44:47.864727
1056	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:45:40.207636
1061	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:46:32.605363
1487	1	unknown	OPTIONS	/api/bindings	200	172.19.0.1	\N	2025-10-28 06:54:29.302245
1492	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:55:22.432539
1497	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:56:15.170571
1502	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:57:07.825141
1507	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:58:00.820588
1512	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:58:53.587143
1517	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:59:45.723779
1522	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:00:38.03727
1527	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:01:30.346585
1532	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:02:22.338318
1854	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 07:42:20.555565
1858	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 07:42:20.587157
1861	1	unknown	OPTIONS	/api/tenants/	200	172.19.0.1	\N	2025-10-28 07:42:20.617896
1864	1	unknown	OPTIONS	/api/scopes/	200	172.19.0.1	\N	2025-10-28 07:42:20.654139
1868	1	unknown	GET	/api/tenants/	200	172.19.0.1	\N	2025-10-28 07:42:20.764322
1876	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:42:32.014887
1881	1	unknown	GET	/api/tenants	307	172.19.0.1	\N	2025-10-28 07:42:45.431772
1898	1	unknown	GET	/api/users	403	172.19.0.1	\N	2025-10-28 07:42:56.210166
2740	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:26:23.79139
2742	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 09:26:36.187745
2743	1	unknown	POST	/api/users	400	172.19.0.1	{"name": "Phan Minh Nhật", "role": "supplier", "email": "huynhat812011@gmail.com"}	2025-10-28 09:26:36.200628
2745	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:26:54.299951
2746	1	unknown	POST	/api/users	200	172.19.0.1	{"name": "Phan Minh Nhật", "role": "supplier", "email": "huynhat81@gmail.com"}	2025-10-28 09:26:55.297302
2748	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:27:04.464744
2750	1	unknown	OPTIONS	/batches/	200	172.19.0.1	\N	2025-10-28 09:27:16.426958
2752	1	unknown	OPTIONS	/farms	200	172.19.0.1	\N	2025-10-28 09:27:16.440791
2755	1	unknown	OPTIONS	/batches/	200	172.19.0.1	\N	2025-10-28 09:27:16.465342
2759	1	unknown	GET	/batches/	404	172.19.0.1	\N	2025-10-28 09:27:16.483577
2763	1	unknown	GET	/farms	404	172.19.0.1	\N	2025-10-28 09:27:19.869065
2768	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:27:24.708857
2773	1	unknown	OPTIONS	/api/batches	200	172.19.0.1	\N	2025-10-28 09:27:52.077138
2777	1	unknown	OPTIONS	/api/batches/	200	172.19.0.1	\N	2025-10-28 09:27:52.113633
2780	1	unknown	GET	/batches/	404	172.19.0.1	\N	2025-10-28 09:27:58.265667
2785	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:28:05.404139
2790	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:28:56.097628
2795	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:29:46.855401
2800	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:30:37.567452
2805	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:31:28.406583
2810	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:32:19.156627
2815	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:33:09.915536
2820	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:34:00.68924
2825	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:34:51.534365
2830	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:35:42.317565
2835	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:36:33.132507
2840	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:37:24.238776
2845	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:38:15.032999
2850	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:39:07.004573
2855	1	unknown	OPTIONS	/api/batches/	200	172.19.0.1	\N	2025-10-28 09:39:30.702497
2857	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:39:47.713127
2862	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:40:38.659509
2865	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 09:40:41.581405
2867	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:40:48.79525
2871	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:41:29.383405
2876	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:42:20.207059
2881	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:43:11.076322
2886	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:44:01.835033
1049	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 04:44:32.311574
1054	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:45:19.129447
1059	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:46:11.432505
1064	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:47:03.807519
1490	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:55:01.017443
1495	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:55:53.18008
1500	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:56:46.851374
1505	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:57:40.203001
1510	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:58:32.827818
1515	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 06:59:24.522728
1520	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:00:16.762566
1525	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:01:08.786524
1530	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:02:01.502236
1859	1	unknown	GET	/api/tenants	307	172.19.0.1	\N	2025-10-28 07:42:20.593885
1862	1	unknown	GET	/api/scopes	307	172.19.0.1	\N	2025-10-28 07:42:20.617851
1879	1	unknown	GET	/api/roles	307	172.19.0.1	\N	2025-10-28 07:42:45.390717
1888	1	unknown	OPTIONS	/api/roles/	200	172.19.0.1	\N	2025-10-28 07:42:45.791092
1890	1	unknown	GET	/api/tenants/	200	172.19.0.1	\N	2025-10-28 07:42:45.843818
1897	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:42:52.515523
2741	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:26:34.041475
2744	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:26:44.163181
2747	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 09:26:55.316648
2749	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:27:14.601222
2751	1	unknown	GET	/batches/	404	172.19.0.1	\N	2025-10-28 09:27:16.436223
2753	1	unknown	OPTIONS	/suppliers	200	172.19.0.1	\N	2025-10-28 09:27:16.448779
2754	1	unknown	GET	/farms	404	172.19.0.1	\N	2025-10-28 09:27:16.463603
2756	1	unknown	OPTIONS	/suppliers	200	172.19.0.1	\N	2025-10-28 09:27:16.47923
2760	1	unknown	GET	/suppliers	404	172.19.0.1	\N	2025-10-28 09:27:16.490363
2765	1	unknown	GET	/batches/	404	172.19.0.1	\N	2025-10-28 09:27:19.886777
2770	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:27:34.96127
2775	1	unknown	GET	/api/batches	307	172.19.0.1	\N	2025-10-28 09:27:52.089321
2778	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:27:55.186732
2784	1	unknown	GET	/farms	404	172.19.0.1	\N	2025-10-28 09:27:58.2979
2789	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:28:45.952249
2794	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:29:36.73097
2799	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:30:27.455819
2804	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:31:18.302935
2809	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:32:09.058809
2814	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:32:59.696723
2819	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:33:50.576724
2824	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:34:41.419308
2829	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:35:32.127299
2834	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:36:22.911972
2839	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:37:13.993037
2844	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:38:04.938115
2849	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:38:56.811557
2854	1	unknown	OPTIONS	/api/suppliers	200	172.19.0.1	\N	2025-10-28 09:39:30.697398
2856	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:39:37.562235
2861	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:40:28.435512
2870	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:41:19.263151
2874	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:41:59.877683
2879	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:42:50.675259
2884	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:43:41.580235
2889	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:44:32.323282
1050	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:44:37.743043
1055	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:45:30.108967
1060	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:46:21.546685
1534	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:02:58.100966
1535	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:03:08.297899
1536	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:03:18.912191
1537	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:03:29.085777
1542	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:04:22.454883
1547	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:05:14.648646
1552	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:06:07.344708
1557	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:07:00.014292
1562	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:07:53.044119
1567	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:08:44.880229
1572	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:09:37.619445
1577	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:10:29.284567
1582	1	unknown	OPTIONS	/api/scopes	200	172.19.0.1	\N	2025-10-28 07:10:56.024634
1587	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 07:10:56.057576
1591	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:11:12.504231
1596	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:12:04.946545
1601	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:12:56.87694
1606	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:13:50.081249
1611	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:14:42.379163
1616	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:15:35.488801
1621	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:16:27.383764
1626	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:17:20.260089
1631	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:18:13.41554
1900	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:43:14.086333
1905	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:44:07.029811
1910	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:44:59.299471
1915	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:45:52.294087
1920	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:46:45.392124
1925	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:47:37.061808
1930	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:48:30.050152
1935	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:49:22.805128
1940	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:50:16.047809
1945	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:51:07.936128
2757	1	unknown	OPTIONS	/farms	200	172.19.0.1	\N	2025-10-28 09:27:16.481935
2762	1	unknown	GET	/batches/	404	172.19.0.1	\N	2025-10-28 09:27:19.866824
2766	1	unknown	GET	/suppliers	404	172.19.0.1	\N	2025-10-28 09:27:19.890858
2771	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:27:45.068937
2776	1	unknown	OPTIONS	/api/batches/	200	172.19.0.1	\N	2025-10-28 09:27:52.113396
2779	1	unknown	GET	/batches/	404	172.19.0.1	\N	2025-10-28 09:27:58.25842
2783	1	unknown	GET	/suppliers	404	172.19.0.1	\N	2025-10-28 09:27:58.297518
2788	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:28:35.838697
2793	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:29:26.542751
2798	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:30:17.322893
2803	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:31:08.159456
2808	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:31:58.847403
2813	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:32:49.586735
2818	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:33:40.485315
2823	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:34:31.164278
2828	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:35:22.002467
2833	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:36:12.800242
2838	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:37:03.804588
2843	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:37:54.715126
2848	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:38:46.89953
2853	1	unknown	OPTIONS	/api/farms	200	172.19.0.1	\N	2025-10-28 09:39:30.679794
2860	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:40:18.318202
2866	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 09:40:41.618408
2869	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:41:09.160845
2873	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:41:49.753569
2878	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:42:40.55416
2883	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:43:31.367057
2888	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:44:22.201273
1052	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:44:58.880924
1057	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:45:50.321895
1062	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:46:42.71192
1538	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:03:39.505751
1543	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:04:32.64553
1548	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:05:24.621779
1553	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:06:17.504794
1558	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:07:10.213919
1563	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:08:03.298876
1568	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:08:55.486273
1573	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:09:47.749151
1578	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:10:39.642156
1583	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 07:10:56.035797
1588	1	unknown	OPTIONS	/api/scopes	200	172.19.0.1	\N	2025-10-28 07:10:56.067687
1594	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:11:44.187393
1599	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:12:36.535175
1604	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:13:28.252877
1609	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:14:21.030562
1614	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:15:14.053972
1619	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:16:06.968896
1624	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:16:58.907942
1629	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:17:51.801768
1634	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:18:44.918273
1901	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:43:24.249482
1906	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:44:18.258344
1911	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:45:10.524492
1916	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:46:02.497394
1921	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:46:55.505388
1926	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:47:48.297758
1931	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:48:41.153897
1936	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:49:32.978449
1941	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:50:26.292656
1946	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:51:19.064593
2758	1	unknown	GET	/suppliers	404	172.19.0.1	\N	2025-10-28 09:27:16.482377
2764	1	unknown	GET	/suppliers	404	172.19.0.1	\N	2025-10-28 09:27:19.878354
2769	1	unknown	GET	/batches/	404	172.19.0.1	\N	2025-10-28 09:27:34.573307
2774	1	unknown	GET	/api/batches	307	172.19.0.1	\N	2025-10-28 09:27:52.08097
2782	1	unknown	GET	/suppliers	404	172.19.0.1	\N	2025-10-28 09:27:58.286371
2786	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:28:15.515103
2791	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:29:06.312071
2796	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:29:56.979253
2801	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:30:47.759186
2806	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:31:38.602402
2811	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:32:29.285332
2816	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:33:20.02762
2821	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:34:10.917623
2826	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:35:01.638032
2831	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:35:52.462242
2836	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:36:43.247748
2841	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:37:34.513529
2846	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:38:25.222972
2851	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:39:17.129083
2858	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:39:57.857728
2863	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 09:40:41.468738
2868	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:40:58.946624
2872	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:41:39.614755
2877	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:42:30.298553
2882	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:43:21.196312
2887	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:44:12.04843
1053	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:45:09.005993
1058	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:46:01.337436
1063	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:46:52.812061
1539	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:03:50.83649
1544	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:04:42.809457
1549	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:05:36.011709
1554	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:06:27.745599
1559	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:07:20.606058
1564	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:08:13.57921
1569	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:09:06.418508
1574	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:09:58.21918
1579	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:10:50.6519
1584	1	unknown	OPTIONS	/api/tenants	200	172.19.0.1	\N	2025-10-28 07:10:56.041793
1589	1	unknown	OPTIONS	/api/bindings	200	172.19.0.1	\N	2025-10-28 07:10:56.106578
1593	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:11:33.981494
1598	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:12:25.328235
1603	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:13:18.028035
1608	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:14:10.761283
1613	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:15:03.772736
1618	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:15:55.848998
1623	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:16:48.752
1628	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:17:41.58388
1633	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:18:33.806559
1902	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:43:35.462202
1907	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:44:28.399942
1912	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:45:20.689748
1917	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:46:13.815752
1922	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:47:05.641321
1927	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:47:58.492285
1932	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:48:51.372453
1937	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:49:44.254179
1942	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:50:36.489574
1947	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:51:29.193697
2761	1	unknown	GET	/farms	404	172.19.0.1	\N	2025-10-28 09:27:16.495055
2767	1	unknown	GET	/farms	404	172.19.0.1	\N	2025-10-28 09:27:19.891165
2772	1	unknown	OPTIONS	/api/batches	200	172.19.0.1	\N	2025-10-28 09:27:52.076805
2781	1	unknown	GET	/farms	404	172.19.0.1	\N	2025-10-28 09:27:58.279514
2787	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:28:25.646482
2792	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:29:16.430148
2797	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:30:07.199631
2802	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:30:57.922842
2807	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:31:48.748837
2812	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:32:39.487726
2817	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:33:30.14797
2822	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:34:21.053209
2827	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:35:11.874601
2832	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:36:02.672536
2837	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:36:53.437885
2842	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:37:44.610382
2847	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:38:35.449242
2852	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:39:27.259069
2859	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:40:08.111348
2864	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 09:40:41.497967
2875	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:42:10.097244
2880	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:43:00.814758
2885	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:43:51.69539
2890	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:44:42.526462
1065	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:54:48.527067
1066	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:54:58.551955
1067	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:55:08.676705
1068	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:55:19.727243
1069	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:55:29.847739
1070	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:55:39.97618
1071	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:55:51.072037
1072	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:56:01.196406
1073	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:56:11.316799
1074	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:56:22.358845
1075	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:56:32.483557
1540	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:04:01.195772
1545	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:04:53.376941
1550	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:05:46.185391
1555	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:06:39.047313
1560	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:07:32.153682
1565	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:08:24.329085
1570	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:09:16.688675
1575	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:10:08.377791
1580	1	unknown	OPTIONS	/api/tenants	200	172.19.0.1	\N	2025-10-28 07:10:55.977922
1585	1	unknown	OPTIONS	/api/roles	200	172.19.0.1	\N	2025-10-28 07:10:56.044412
1592	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:11:22.677257
1597	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:12:15.155778
1602	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:13:07.670622
1607	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:14:00.28358
1612	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:14:52.562945
1617	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:15:45.641427
1622	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:16:38.52969
1627	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:17:30.405885
1632	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:18:23.629429
1903	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:43:45.711156
1908	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:44:39.03727
1913	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:45:31.023513
1918	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:46:24.15155
1923	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:47:16.791947
1928	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:48:09.704162
1933	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:49:01.530359
1938	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:49:54.579124
1943	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:50:47.64149
2891	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:45:19.302948
2892	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:45:29.370563
2893	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:45:39.618394
2894	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:45:49.75801
2896	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:46:10.139436
2903	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 09:46:28.792046
2905	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:46:40.614398
2909	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:47:11.083969
2911	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:47:21.193778
2914	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:47:41.557039
2917	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:48:11.954638
2920	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:48:42.358295
2923	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:49:12.837613
2926	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:49:43.286204
2929	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:50:13.742093
2932	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:50:44.232214
2935	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:51:14.682269
2938	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:51:45.217966
2941	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:52:15.753232
2944	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:52:46.173713
2947	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:53:16.644086
2950	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:53:47.132246
2953	1	unknown	GET	/api/api/batches	404	172.19.0.1	\N	2025-10-28 09:54:08.009718
2956	1	unknown	OPTIONS	/api/batches/	200	172.19.0.1	\N	2025-10-28 09:54:11.080868
2959	1	unknown	OPTIONS	/api/suppliers	200	172.19.0.1	\N	2025-10-28 09:54:11.165242
2962	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:54:37.910643
2966	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:55:18.749182
2969	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:55:49.46256
2972	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:56:19.886321
2975	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:56:50.354121
2978	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:57:20.87948
2981	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:57:51.35347
2984	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:58:21.836889
2987	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:58:52.272795
2990	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:59:22.835415
2993	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:59:53.272936
2996	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:00:23.697823
2999	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:00:54.168697
3002	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:01:24.605313
3005	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:01:55.020372
3008	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:02:25.492489
3011	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:02:56.00856
3014	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:03:26.549251
3017	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:03:56.986421
3020	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:04:27.551479
3023	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:04:57.966399
3026	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:05:28.456704
3029	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:05:58.919069
3032	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:06:29.346436
1076	1	unknown	OPTIONS	/api/tenants	200	172.19.0.1	\N	2025-10-28 04:56:42.702051
1086	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:56:49.041716
1091	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:57:40.580903
1096	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:58:33.007811
1101	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:59:25.370257
1106	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 05:00:17.195964
1541	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:04:11.347675
1546	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:05:04.483125
1551	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:05:56.129565
1556	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:06:49.248868
1561	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:07:42.48401
1566	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:08:34.635449
1571	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:09:27.249591
1576	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:10:19.384736
1581	1	unknown	OPTIONS	/api/bindings	200	172.19.0.1	\N	2025-10-28 07:10:56.010566
1586	1	unknown	OPTIONS	/api/roles	200	172.19.0.1	\N	2025-10-28 07:10:56.056995
1590	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:11:00.75833
1595	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:11:54.435384
1600	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:12:46.717764
1605	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:13:38.920321
1610	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:14:32.237486
1615	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:15:24.302819
1620	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:16:17.09424
1625	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:17:10.108731
1630	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:18:02.164323
1904	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:43:56.294721
1909	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:44:49.162954
1914	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:45:42.168101
1919	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:46:34.273513
1924	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:47:26.913854
1929	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:48:19.878556
1934	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:49:12.688078
1939	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:50:04.841902
1944	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:50:57.781005
2895	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:45:59.921383
2898	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:46:20.254866
2900	1	unknown	OPTIONS	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 09:46:28.714996
2902	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 09:46:28.759737
2904	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:46:30.397973
2907	1	unknown	GET	/api/batches/	403	172.19.0.1	\N	2025-10-28 09:46:57.91757
2912	1	unknown	GET	/api/batches/	403	172.19.0.1	\N	2025-10-28 09:47:21.440401
2915	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:47:51.663132
2918	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:48:22.070194
2921	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:48:52.475964
2924	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:49:22.947096
2927	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:49:53.415132
2930	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:50:23.852893
2933	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:50:54.347663
2936	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:51:24.825363
2939	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:51:55.432565
2942	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:52:25.85466
2945	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:52:56.300613
2948	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:53:26.788681
2951	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:53:57.230225
2954	1	unknown	OPTIONS	/api/batches/	200	172.19.0.1	\N	2025-10-28 09:54:10.910103
2957	1	unknown	OPTIONS	/api/farms	200	172.19.0.1	\N	2025-10-28 09:54:11.120571
2961	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:54:27.709046
2964	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:54:58.147688
2967	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:55:28.98461
2970	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:55:59.572995
2973	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:56:30.019092
2976	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:57:00.570803
2979	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:57:31.005345
2982	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:58:01.463755
2985	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:58:31.96521
2988	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:59:02.411684
2991	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:59:32.955241
2994	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:00:03.385898
2997	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:00:33.821749
3000	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:01:04.272663
3003	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:01:34.705936
3006	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:02:05.122241
3009	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:02:35.623812
3012	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:03:06.113466
3015	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:03:36.672909
3018	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:04:07.166399
3021	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:04:37.65773
3024	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:05:08.07457
3027	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:05:38.65034
3030	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:06:09.153438
3033	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:06:39.548155
3036	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:07:10.061466
3039	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:07:40.490325
3042	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:08:10.951138
3045	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:08:41.418861
3048	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:09:11.895335
3051	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:09:42.367974
1077	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 04:56:42.702425
1087	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:56:59.138474
1092	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:57:51.617862
1097	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:58:43.117899
1102	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:59:35.504961
1107	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 05:00:28.277818
1635	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:19:15.101774
1636	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:19:25.191994
1637	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:19:35.384636
1638	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:19:46.499637
1639	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:19:56.683608
1640	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 07:20:03.938591
1641	1	unknown	GET	/api/users	401	172.19.0.1	\N	2025-10-28 07:20:03.956619
1642	1	unknown	GET	/api/tenants	401	172.19.0.1	\N	2025-10-28 07:20:03.975952
1646	1	unknown	GET	/api/scopes	401	172.19.0.1	\N	2025-10-28 07:20:04.00882
1647	1	unknown	GET	/api/users	401	172.19.0.1	\N	2025-10-28 07:20:04.020258
1652	1	unknown	GET	/api/bindings/	401	172.19.0.1	\N	2025-10-28 07:20:04.143884
1659	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 07:20:22.056283
1948	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:51:54.898559
1949	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:52:05.016875
1950	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:52:15.250948
1951	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:52:26.423978
1952	1	unknown	GET	/api/users	403	172.19.0.1	\N	2025-10-28 07:52:33.88451
1953	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:52:36.545313
1954	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:52:46.77875
1955	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:52:57.459357
1956	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:53:07.587066
1957	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:53:18.323427
1958	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:53:28.981168
1959	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:53:39.182424
1960	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:53:50.275098
1961	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:54:00.522439
1962	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:54:10.652938
1963	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:54:21.684676
1964	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:54:31.801366
1965	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:54:41.92141
1966	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:54:53.080661
1967	1	unknown	POST	/auth/login	200	172.19.0.1	\N	2025-10-28 07:54:58.610337
1968	1	unknown	OPTIONS	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 07:54:58.852279
1969	1	unknown	OPTIONS	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 07:54:58.875422
1970	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 07:54:58.932779
1971	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 07:54:58.954465
1972	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 07:54:59.963149
1973	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 07:54:59.995236
1975	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 07:55:03.422143
1977	1	unknown	OPTIONS	/api/tenants	200	172.19.0.1	\N	2025-10-28 07:55:03.435939
1979	1	unknown	OPTIONS	/api/roles	200	172.19.0.1	\N	2025-10-28 07:55:03.456164
1983	1	unknown	GET	/api/tenants	307	172.19.0.1	\N	2025-10-28 07:55:03.489091
1987	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 07:55:03.521724
1997	1	unknown	OPTIONS	/api/bindings/	200	172.19.0.1	\N	2025-10-28 07:55:03.589986
2000	1	unknown	OPTIONS	/api/bindings/	200	172.19.0.1	\N	2025-10-28 07:55:03.650213
2010	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:55:24.193872
2015	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:56:15.730785
2020	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:57:07.840916
2025	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:58:00.867431
2030	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:58:52.026145
2035	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:59:44.182001
2040	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:00:37.869971
2045	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:01:29.461896
2897	1	unknown	GET	/api/batches/	403	172.19.0.1	\N	2025-10-28 09:46:12.705676
2899	1	unknown	POST	/auth/login	200	172.19.0.1	\N	2025-10-28 09:46:27.855374
2901	1	unknown	OPTIONS	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 09:46:28.734822
2906	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:46:50.746886
2908	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:47:00.857276
2910	1	unknown	GET	/api/suppliers	403	172.19.0.1	\N	2025-10-28 09:47:17.033034
2913	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:47:31.367064
2916	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:48:01.813598
2919	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:48:32.176
2922	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:49:02.593668
2925	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:49:33.071679
2928	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:50:03.534915
2931	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:50:33.992348
2934	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:51:04.462219
2937	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:51:34.997534
2940	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:52:05.53326
2943	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:52:36.068642
2946	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:53:06.519048
2949	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:53:37.006896
2952	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:54:07.451843
2955	1	unknown	OPTIONS	/api/farms	200	172.19.0.1	\N	2025-10-28 09:54:10.931285
2958	1	unknown	OPTIONS	/api/suppliers	200	172.19.0.1	\N	2025-10-28 09:54:11.141918
2960	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:54:17.579606
2963	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:54:48.03339
2965	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:55:08.512605
2968	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:55:39.266132
1078	1	unknown	OPTIONS	/api/tenants	200	172.19.0.1	\N	2025-10-28 04:56:42.705517
1090	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:57:30.462782
1095	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:58:22.899434
1100	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:59:14.356728
1105	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 05:00:06.9387
1643	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 07:20:03.993879
1651	1	unknown	OPTIONS	/api/bindings/	200	172.19.0.1	\N	2025-10-28 07:20:04.122166
1656	1	unknown	POST	/auth/login	200	172.19.0.1	\N	2025-10-28 07:20:20.931077
1974	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:55:03.207873
1976	1	unknown	OPTIONS	/api/tenants	200	172.19.0.1	\N	2025-10-28 07:55:03.429395
1978	1	unknown	OPTIONS	/api/scopes	200	172.19.0.1	\N	2025-10-28 07:55:03.45118
1981	1	unknown	OPTIONS	/api/scopes	200	172.19.0.1	\N	2025-10-28 07:55:03.472149
1986	1	unknown	OPTIONS	/api/bindings	200	172.19.0.1	\N	2025-10-28 07:55:03.507396
1991	1	unknown	GET	/api/scopes	307	172.19.0.1	\N	2025-10-28 07:55:03.541761
1993	1	unknown	OPTIONS	/api/scopes/	200	172.19.0.1	\N	2025-10-28 07:55:03.570591
1998	1	unknown	OPTIONS	/api/roles/	200	172.19.0.1	\N	2025-10-28 07:55:03.59143
2004	1	unknown	GET	/api/scopes/	200	172.19.0.1	\N	2025-10-28 07:55:03.696005
2009	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:55:13.511722
2014	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:56:05.558233
2019	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:56:57.605524
2024	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:57:49.699575
2029	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:58:41.918546
2034	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:59:33.980515
2039	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:00:26.655629
2044	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:01:18.936228
2971	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:56:09.790696
2974	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:56:40.223925
2977	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:57:10.755836
2980	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:57:41.22768
2983	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:58:11.713775
2986	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:58:42.141817
2989	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:59:12.746634
2992	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 09:59:43.164056
2995	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:00:13.589095
2998	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:00:44.048551
3001	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:01:14.49066
3004	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:01:44.926394
3007	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:02:15.323822
3010	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:02:45.884899
3013	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:03:16.45361
3016	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:03:46.869531
3019	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:04:17.439924
3022	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:04:47.866895
3025	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:05:18.278615
3028	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:05:48.759346
3031	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:06:19.25207
3034	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:06:49.647368
3037	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:07:20.193436
3040	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:07:50.634369
3043	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:08:21.084504
3046	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:08:51.543703
3049	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:09:22.012392
3052	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:09:52.475817
3055	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:10:22.945807
3058	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:10:53.388302
3061	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:11:24.334398
1079	1	unknown	OPTIONS	/api/roles	200	172.19.0.1	\N	2025-10-28 04:56:42.703617
1089	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:57:20.342733
1094	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:58:11.863085
1099	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:59:04.255692
1104	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:59:56.784176
1644	1	unknown	GET	/api/scopes	401	172.19.0.1	\N	2025-10-28 07:20:03.997192
1650	1	unknown	OPTIONS	/api/bindings/	200	172.19.0.1	\N	2025-10-28 07:20:04.086188
1655	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:20:18.226957
1658	1	unknown	OPTIONS	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 07:20:22.015405
1980	1	unknown	OPTIONS	/api/roles	200	172.19.0.1	\N	2025-10-28 07:55:03.47017
1985	1	unknown	GET	/api/roles	307	172.19.0.1	\N	2025-10-28 07:55:03.506437
1990	1	unknown	GET	/api/roles	307	172.19.0.1	\N	2025-10-28 07:55:03.537184
1994	1	unknown	OPTIONS	/api/roles/	200	172.19.0.1	\N	2025-10-28 07:55:03.572468
1999	1	unknown	OPTIONS	/api/scopes/	200	172.19.0.1	\N	2025-10-28 07:55:03.592884
2003	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 07:55:03.689924
2008	1	unknown	GET	/api/scopes/	200	172.19.0.1	\N	2025-10-28 07:55:03.752284
2013	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:55:55.421769
2018	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:56:46.937341
2023	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:57:39.362032
2028	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:58:31.786776
2033	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:59:22.919348
2038	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:00:16.302893
2043	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:01:08.718956
3035	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:06:59.747494
3038	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:07:30.307442
3041	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:08:00.758845
3044	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:08:31.199171
3047	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:09:01.682949
3050	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:09:32.132301
3053	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:10:02.588976
3056	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:10:33.071132
3059	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:11:03.584532
1080	1	unknown	OPTIONS	/api/scopes	200	172.19.0.1	\N	2025-10-28 04:56:42.715656
1088	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:57:09.246321
1093	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:58:01.750744
1098	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:58:54.162042
1103	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:59:45.621707
1645	1	unknown	GET	/api/roles	401	172.19.0.1	\N	2025-10-28 07:20:03.998867
1648	1	unknown	GET	/api/tenants	401	172.19.0.1	\N	2025-10-28 07:20:04.03228
1653	1	unknown	GET	/api/bindings/	401	172.19.0.1	\N	2025-10-28 07:20:04.162017
1657	1	unknown	OPTIONS	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 07:20:21.986636
1660	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 07:20:22.091156
1982	1	unknown	OPTIONS	/api/bindings	200	172.19.0.1	\N	2025-10-28 07:55:03.483205
1984	1	unknown	GET	/api/scopes	307	172.19.0.1	\N	2025-10-28 07:55:03.502288
1988	1	unknown	GET	/api/tenants	307	172.19.0.1	\N	2025-10-28 07:55:03.525907
1992	1	unknown	OPTIONS	/api/tenants/	200	172.19.0.1	\N	2025-10-28 07:55:03.56327
1996	1	unknown	OPTIONS	/api/tenants/	200	172.19.0.1	\N	2025-10-28 07:55:03.578683
2001	1	unknown	GET	/api/roles/	200	172.19.0.1	\N	2025-10-28 07:55:03.682857
2006	1	unknown	GET	/api/roles/	200	172.19.0.1	\N	2025-10-28 07:55:03.742992
2011	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:55:34.389442
2016	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:56:26.508893
2021	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:57:18.248675
2026	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:58:11.036169
2031	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:59:02.649269
2036	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:59:54.531476
2041	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:00:48.1057
2046	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:01:39.665864
3054	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:10:12.820418
3057	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:10:43.292605
3060	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:11:13.977823
1081	1	unknown	OPTIONS	/api/scopes	200	172.19.0.1	\N	2025-10-28 04:56:42.72211
1649	1	unknown	GET	/api/roles	401	172.19.0.1	\N	2025-10-28 07:20:04.036031
1654	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:20:07.076905
1989	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 07:55:03.528315
1995	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 07:55:03.576115
2002	1	unknown	GET	/api/tenants/	200	172.19.0.1	\N	2025-10-28 07:55:03.683751
2005	1	unknown	GET	/api/tenants/	200	172.19.0.1	\N	2025-10-28 07:55:03.724403
2007	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 07:55:03.74726
2012	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:55:44.647208
2017	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:56:36.678748
2022	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:57:29.190239
2027	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:58:21.206283
2032	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:59:12.775207
2037	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:00:05.282954
2042	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:00:58.547711
2047	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:01:50.230976
3062	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:11:34.536824
3065	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:12:05.056343
3068	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:12:35.545773
3071	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:13:06.017968
3074	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:13:36.529353
3077	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:14:06.947791
3080	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:14:37.423406
3083	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:15:07.905277
3086	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:15:38.484022
3089	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:16:08.926041
3092	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:16:39.408337
3095	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:17:09.899206
3098	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:17:40.342434
3101	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:18:10.836252
3104	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:18:41.29297
3107	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:19:11.82007
3110	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:19:42.275064
3113	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:20:12.730886
3116	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:20:43.235207
3119	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:21:13.770258
3122	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:21:44.543264
3125	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:22:15.496162
1082	1	unknown	OPTIONS	/api/bindings	200	172.19.0.1	\N	2025-10-28 04:56:42.723189
1661	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 07:20:26.66985
1666	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:20:38.645566
1671	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:21:31.384383
1676	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:22:24.655071
1681	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:23:16.37213
1686	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:24:09.722449
2048	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:02:14.262984
2049	1	unknown	POST	/auth/login	200	172.19.0.1	\N	2025-10-28 08:02:18.909342
2050	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 08:02:19.933845
2051	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 08:02:19.958973
2052	1	unknown	GET	/api/roles	307	172.19.0.1	\N	2025-10-28 08:02:23.65509
2055	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 08:02:23.782278
2064	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 08:02:24.008473
2069	1	unknown	GET	/api/roles/	200	172.19.0.1	\N	2025-10-28 08:02:24.04804
2077	1	unknown	GET	/api/roles	307	172.19.0.1	\N	2025-10-28 08:02:57.130543
2082	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 08:02:57.152976
2084	1	unknown	GET	/api/roles/	200	172.19.0.1	\N	2025-10-28 08:02:57.298131
2085	1	unknown	GET	/api/scopes/	200	172.19.0.1	\N	2025-10-28 08:02:57.329321
2090	1	unknown	GET	/api/tenants/	200	172.19.0.1	\N	2025-10-28 08:02:57.36682
2096	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:03:46.245943
2101	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:04:37.561762
2106	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:05:29.330442
2111	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:06:20.543805
2116	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:07:11.701446
2121	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:08:02.841292
2126	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:08:53.733281
2131	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:09:44.948432
2134	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:09:55.074679
3063	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:11:44.77929
3066	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:12:15.286841
3069	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:12:45.783944
3072	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:13:16.256002
3075	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:13:46.712379
3078	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:14:17.181092
3081	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:14:47.654934
3084	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:15:18.119904
3087	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:15:48.727374
3090	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:16:19.15168
3093	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:16:49.689176
3096	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:17:20.110375
3099	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:17:50.628444
3102	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:18:21.055194
3105	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:18:51.496891
3108	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:19:21.924563
3111	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:19:52.396991
3114	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:20:22.854603
3117	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:20:53.34545
3120	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:21:23.90435
3123	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:21:54.805666
1083	1	unknown	OPTIONS	/api/bindings	200	172.19.0.1	\N	2025-10-28 04:56:42.723766
1662	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 07:20:26.736855
1663	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 07:20:26.809449
1668	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:20:59.988228
1673	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:21:52.833985
1678	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:22:45.003296
1683	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:23:37.619628
1688	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:24:30.539445
2053	1	unknown	GET	/api/tenants	307	172.19.0.1	\N	2025-10-28 08:02:23.705148
2056	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 08:02:23.891024
3064	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:11:54.972703
3067	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:12:25.445274
3070	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:12:55.893189
3073	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:13:26.37538
3076	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:13:56.814315
3079	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:14:27.299828
3082	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:14:57.768153
3085	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:15:28.296464
3088	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:15:58.833057
3091	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:16:29.304681
3094	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:16:59.789779
3097	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:17:30.237543
3100	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:18:00.730116
3103	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:18:31.174679
3106	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:19:01.594428
3109	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:19:32.049618
3112	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:20:02.504784
3115	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:20:32.978992
3118	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:21:03.506406
3121	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:21:34.172782
3124	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:22:05.081022
1084	1	unknown	OPTIONS	/api/roles	200	172.19.0.1	\N	2025-10-28 04:56:42.724497
1664	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 07:20:26.911376
1669	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:21:10.13055
1674	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:22:03.122887
1679	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:22:56.122995
1684	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:23:47.837235
2054	1	unknown	GET	/api/scopes	307	172.19.0.1	\N	2025-10-28 08:02:23.77695
2070	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:02:24.414279
2074	1	unknown	GET	/api/roles	307	172.19.0.1	\N	2025-10-28 08:02:57.105402
2078	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 08:02:57.134041
2083	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 08:02:57.16201
2086	1	unknown	GET	/api/tenants/	200	172.19.0.1	\N	2025-10-28 08:02:57.334013
2092	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:03:05.488428
2097	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:03:56.358122
2102	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:04:48.335159
2107	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:05:39.799242
2112	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:06:30.654958
2117	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:07:21.825872
2122	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:08:12.972239
2127	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:09:04.137559
2132	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 08:09:51.32261
2135	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:10:05.502581
3126	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:28:37.297629
3127	1	unknown	POST	/auth/login	200	172.19.0.1	\N	2025-10-28 10:28:40.020316
3128	1	unknown	OPTIONS	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 10:28:40.973066
3129	1	unknown	OPTIONS	/api/batches/	200	172.19.0.1	\N	2025-10-28 10:28:46.152573
3130	1	unknown	OPTIONS	/api/farms	200	172.19.0.1	\N	2025-10-28 10:28:46.169226
3131	1	unknown	OPTIONS	/api/suppliers	200	172.19.0.1	\N	2025-10-28 10:28:46.180606
3145	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:29:48.700748
3150	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:27:59.24425
3155	1	unknown	OPTIONS	/api/farms	200	172.19.0.1	\N	2025-10-28 12:28:11.576073
3160	1	unknown	GET	/api/suppliers	401	172.19.0.1	\N	2025-10-28 12:28:12.295478
3165	1	unknown	GET	/api/farms	405	172.19.0.1	\N	2025-10-28 12:28:17.441739
3170	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:28:21.11169
3175	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:29:12.901996
3180	1	unknown	GET	/api/farms	405	172.19.0.1	\N	2025-10-28 12:29:57.592361
3185	1	unknown	GET	/api/suppliers	401	172.19.0.1	\N	2025-10-28 12:29:57.659496
3190	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:30:44.915754
3195	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:31:35.865083
3200	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:32:26.919168
1085	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 04:56:42.735808
1665	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:20:28.451876
1670	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:21:21.266899
1675	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:22:13.298342
1680	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:23:06.237656
1685	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:23:58.518325
2057	1	unknown	GET	/api/scopes	307	172.19.0.1	\N	2025-10-28 08:02:23.948991
2060	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 08:02:23.971719
2063	1	unknown	GET	/api/tenants/	200	172.19.0.1	\N	2025-10-28 08:02:24.001871
2066	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 08:02:24.023708
2071	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:02:34.839009
2079	1	unknown	GET	/api/tenants	307	172.19.0.1	\N	2025-10-28 08:02:57.138274
2087	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 08:02:57.337991
2089	1	unknown	GET	/api/scopes/	200	172.19.0.1	\N	2025-10-28 08:02:57.364331
2094	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:03:25.725437
2099	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:04:16.967343
2104	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:05:08.964436
2109	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:06:00.064639
2114	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:06:51.188202
2119	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:07:42.356528
2124	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:08:33.504577
2129	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:09:24.428781
3132	1	unknown	OPTIONS	/api/batches/	200	172.19.0.1	\N	2025-10-28 10:28:46.198844
3139	1	unknown	GET	/api/farms	405	172.19.0.1	\N	2025-10-28 10:29:03.612118
3141	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:29:07.798394
3146	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:29:58.946115
3151	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:28:10.246293
3154	1	unknown	OPTIONS	/api/batches/	200	172.19.0.1	\N	2025-10-28 12:28:11.574371
3159	1	unknown	GET	/api/farms	405	172.19.0.1	\N	2025-10-28 12:28:12.261419
3164	1	unknown	GET	/api/batches/	401	172.19.0.1	\N	2025-10-28 12:28:17.429183
3169	1	unknown	GET	/api/suppliers	401	172.19.0.1	\N	2025-10-28 12:28:17.497035
3174	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:29:02.601246
3179	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:29:53.843504
3184	1	unknown	GET	/api/batches/	401	172.19.0.1	\N	2025-10-28 12:29:57.656444
3189	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:30:34.703714
3194	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:31:25.640633
3199	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:32:16.693133
1108	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 05:00:38.394807
1113	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 05:01:30.828703
1118	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 05:02:22.311943
1123	1	unknown	OPTIONS	/farms	200	172.19.0.1	\N	2025-10-28 05:58:49.573979
1129	1	unknown	GET	/farms	404	172.19.0.1	\N	2025-10-28 05:58:49.671825
1134	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 05:58:50.503503
1667	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:20:49.79452
1672	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:21:41.51829
1677	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:22:34.817665
1682	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:23:27.476783
1687	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:24:19.856171
2058	1	unknown	GET	/api/roles	307	172.19.0.1	\N	2025-10-28 08:02:23.95938
2062	1	unknown	GET	/api/scopes/	200	172.19.0.1	\N	2025-10-28 08:02:23.999111
3133	1	unknown	OPTIONS	/api/suppliers	200	172.19.0.1	\N	2025-10-28 10:28:46.195244
3136	1	unknown	GET	/api/farms	405	172.19.0.1	\N	2025-10-28 10:28:46.270783
1109	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 05:00:48.51217
1114	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 05:01:40.94629
1119	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 05:02:33.39418
1124	1	unknown	OPTIONS	/suppliers	200	172.19.0.1	\N	2025-10-28 05:58:49.575962
1128	1	unknown	OPTIONS	/farms	200	172.19.0.1	\N	2025-10-28 05:58:49.671195
1132	1	unknown	GET	/farms	404	172.19.0.1	\N	2025-10-28 05:58:49.712379
1137	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 05:59:22.125641
1689	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:24:44.066814
1690	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:24:55.3425
1691	1	unknown	OPTIONS	/api/tenants	200	172.19.0.1	\N	2025-10-28 07:24:56.602711
1692	1	unknown	OPTIONS	/api/scopes	200	172.19.0.1	\N	2025-10-28 07:24:56.625593
1693	1	unknown	OPTIONS	/api/users	200	172.19.0.1	\N	2025-10-28 07:24:56.655076
1696	1	unknown	GET	/api/scopes	307	172.19.0.1	\N	2025-10-28 07:24:56.717445
2059	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 08:02:23.960317
2067	1	unknown	GET	/api/scopes/	200	172.19.0.1	\N	2025-10-28 08:02:24.044051
2073	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:02:55.053609
2076	1	unknown	GET	/api/scopes	307	172.19.0.1	\N	2025-10-28 08:02:57.128901
2081	1	unknown	GET	/api/scopes	307	172.19.0.1	\N	2025-10-28 08:02:57.148584
2088	1	unknown	GET	/api/roles/	200	172.19.0.1	\N	2025-10-28 08:02:57.355554
2093	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:03:15.588991
2098	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:04:06.800257
2103	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:04:58.653724
2108	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:05:49.931237
2113	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:06:41.067566
2118	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:07:31.953768
2123	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:08:23.093685
2128	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:09:14.30478
3134	1	unknown	OPTIONS	/api/farms	200	172.19.0.1	\N	2025-10-28 10:28:46.205302
3142	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:29:18.021942
3147	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:30:09.155886
3157	1	unknown	OPTIONS	/api/suppliers	200	172.19.0.1	\N	2025-10-28 12:28:11.619355
3163	1	unknown	GET	/api/batches/	401	172.19.0.1	\N	2025-10-28 12:28:12.437092
3168	1	unknown	GET	/api/suppliers	401	172.19.0.1	\N	2025-10-28 12:28:17.477123
3173	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:28:52.444203
3178	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:29:43.668774
3183	1	unknown	GET	/api/batches/	401	172.19.0.1	\N	2025-10-28 12:29:57.640197
3188	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:30:24.458644
3193	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:31:15.464033
3198	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:32:06.480204
1110	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 05:00:59.54892
1115	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 05:01:51.07818
1120	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 05:02:52.286444
1127	1	unknown	OPTIONS	/suppliers	200	172.19.0.1	\N	2025-10-28 05:58:49.653793
1133	1	unknown	GET	/suppliers	404	172.19.0.1	\N	2025-10-28 05:58:49.708465
1138	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 05:59:32.278107
1694	1	unknown	OPTIONS	/api/roles	200	172.19.0.1	\N	2025-10-28 07:24:56.681303
1701	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 07:24:56.759012
1712	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:25:15.813584
1717	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:26:08.528675
1722	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:27:01.302058
1727	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:27:53.59795
1732	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:28:46.666945
2061	1	unknown	GET	/api/tenants	307	172.19.0.1	\N	2025-10-28 08:02:23.970353
2065	1	unknown	GET	/api/roles/	200	172.19.0.1	\N	2025-10-28 08:02:24.009173
2068	1	unknown	GET	/api/tenants/	200	172.19.0.1	\N	2025-10-28 08:02:24.046007
3135	1	unknown	GET	/api/farms	405	172.19.0.1	\N	2025-10-28 10:28:46.231333
3137	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:28:47.36834
3140	1	unknown	GET	/api/farms	405	172.19.0.1	\N	2025-10-28 10:29:03.650004
3143	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:29:28.176338
3148	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:30:19.636927
3153	1	unknown	OPTIONS	/api/batches/	200	172.19.0.1	\N	2025-10-28 12:28:11.53964
3158	1	unknown	GET	/api/farms	405	172.19.0.1	\N	2025-10-28 12:28:11.735667
3162	1	unknown	GET	/api/suppliers	401	172.19.0.1	\N	2025-10-28 12:28:12.39484
3167	1	unknown	GET	/api/batches/	401	172.19.0.1	\N	2025-10-28 12:28:17.471151
3172	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:28:42.061041
3177	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:29:33.451573
3182	1	unknown	GET	/api/suppliers	401	172.19.0.1	\N	2025-10-28 12:29:57.634288
3187	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:30:14.287611
3192	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:31:05.291859
3197	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:31:56.304874
1111	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 05:01:09.678067
1116	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 05:02:02.112344
1121	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 05:58:39.372453
1125	1	unknown	OPTIONS	/batches/	200	172.19.0.1	\N	2025-10-28 05:58:49.64895
1131	1	unknown	GET	/batches/	404	172.19.0.1	\N	2025-10-28 05:58:49.692876
1136	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 05:59:11.939442
1695	1	unknown	OPTIONS	/api/bindings	200	172.19.0.1	\N	2025-10-28 07:24:56.70034
1702	1	unknown	GET	/api/scopes	307	172.19.0.1	\N	2025-10-28 07:24:56.766657
2072	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:02:44.943647
2075	1	unknown	GET	/api/tenants	307	172.19.0.1	\N	2025-10-28 08:02:57.119574
2080	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 08:02:57.148229
2091	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 08:02:57.367221
2095	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:03:36.135776
2100	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:04:27.11656
2105	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:05:19.178083
2110	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:06:10.427313
2115	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:07:01.302005
2120	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:07:52.484022
2125	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:08:43.617714
2130	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:09:34.839764
2133	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 08:09:51.635837
3138	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:28:57.514212
3144	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:29:38.432498
3149	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 10:30:40.386498
3152	1	unknown	OPTIONS	/api/farms	200	172.19.0.1	\N	2025-10-28 12:28:11.540754
3156	1	unknown	OPTIONS	/api/suppliers	200	172.19.0.1	\N	2025-10-28 12:28:11.586364
3161	1	unknown	GET	/api/batches/	401	172.19.0.1	\N	2025-10-28 12:28:12.309436
3166	1	unknown	GET	/api/farms	405	172.19.0.1	\N	2025-10-28 12:28:17.464563
3171	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:28:31.82713
3176	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:29:23.206076
3181	1	unknown	GET	/api/farms	405	172.19.0.1	\N	2025-10-28 12:29:57.628876
3186	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:30:04.063302
3191	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:30:55.131589
3196	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:31:46.090736
3201	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 12:32:37.084194
1112	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 05:01:19.792759
1117	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 05:02:12.204071
1122	1	unknown	OPTIONS	/batches/	200	172.19.0.1	\N	2025-10-28 05:58:49.511002
1126	1	unknown	GET	/batches/	404	172.19.0.1	\N	2025-10-28 05:58:49.65193
1130	1	unknown	GET	/suppliers	404	172.19.0.1	\N	2025-10-28 05:58:49.682287
1135	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 05:59:00.725769
1697	1	unknown	OPTIONS	/api/tenants	200	172.19.0.1	\N	2025-10-28 07:24:56.717207
1703	1	unknown	GET	/api/bindings	307	172.19.0.1	\N	2025-10-28 07:24:56.76876
1706	1	unknown	OPTIONS	/api/scopes/	200	172.19.0.1	\N	2025-10-28 07:24:57.13227
1708	1	unknown	GET	/api/scopes/	200	172.19.0.1	\N	2025-10-28 07:24:57.217144
1711	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:25:05.541229
1716	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:25:58.407326
1721	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:26:50.141386
1726	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:27:43.292813
1731	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:28:36.421868
2136	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:10:21.522089
2137	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:10:31.683752
2138	1	unknown	POST	/auth/login	200	172.19.0.1	\N	2025-10-28 08:10:40.383197
2139	1	unknown	OPTIONS	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 08:10:41.153941
2140	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 08:10:41.190071
2142	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 08:10:41.222323
1145	1	unknown	OPTIONS	/api/scopes	200	172.19.0.1	\N	2025-10-28 05:59:54.76866
1139	1	unknown	OPTIONS	/api/scopes	200	172.19.0.1	\N	2025-10-28 05:59:54.749112
1140	1	unknown	OPTIONS	/api/bindings	200	172.19.0.1	\N	2025-10-28 05:59:54.767374
1146	1	unknown	GET	/api/bindings	401	172.19.0.1	\N	2025-10-28 05:59:54.777848
1152	1	unknown	GET	/api/tenants	401	172.19.0.1	\N	2025-10-28 05:59:54.836206
1153	1	unknown	GET	/api/tenants	401	172.19.0.1	\N	2025-10-28 05:59:54.836638
1155	1	unknown	GET	/api/users	401	172.19.0.1	\N	2025-10-28 05:59:54.837891
1158	1	unknown	GET	/api/bindings	401	172.19.0.1	\N	2025-10-28 05:59:54.840802
1698	1	unknown	OPTIONS	/api/roles	200	172.19.0.1	\N	2025-10-28 07:24:56.729459
1707	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 07:24:57.20749
1710	1	unknown	GET	/api/bindings/	200	172.19.0.1	\N	2025-10-28 07:24:57.271033
1715	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:25:47.258869
1720	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:26:39.970286
1725	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:27:33.001364
1730	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 07:28:25.202468
2141	1	unknown	OPTIONS	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 08:10:41.203575
2143	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 08:10:42.135268
2144	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 08:10:45.605172
2145	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 08:10:45.614638
969	1	unknown	GET	/api/scopes	401	172.19.0.1	\N	2025-10-28 04:35:07.609741
980	1	unknown	GET	/api/dashboard/summary	200	172.19.0.1	\N	2025-10-28 04:35:26.745685
983	1	unknown	GET	/api/users	200	172.19.0.1	\N	2025-10-28 04:35:30.494185
988	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:36:14.573721
993	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:37:06.216102
998	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:37:58.597421
1003	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:38:50.951717
1008	1	unknown	GET	/health	200	127.0.0.1	\N	2025-10-28 04:39:42.562973
\.


--
-- Data for Name: batch_clone_audit; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.batch_clone_audit (id, actor, actor_role, ip_address, parent_batch_code, child_batch_code, used_quantity, unit, created_at) FROM stdin;
1	hoanghuongngannn@gmail.com	supplier	\N	BRAND-001	BRAND-001-MANUFACTURER-251111-0759	4300.000	kg	2025-11-11 07:59:19.888676
2	hoanghuongngannn@gmail.com	farm	\N	GARMENT-002	GARMENT-002-SUPPLIER-251112-1535	5200.000	kg	2025-11-12 15:35:00.314847
3	hoanghuongngannn@gmail.com	supplier	\N	GARMENT-002-SUPPLIER-251112-1535	GARMENT-002-SUPPLIER-251112-1535-MANUFACTURER-251113-0225	5200.000	kg	2025-11-13 02:25:41.065517
4	nttrungg205@gmail.com	manufacturer	\N	GARMENT-002-SUPPLIER-251112-1535-MANUFACTURER-251113-0225	GARMENT-002-SUPPLIER-251112-1535-MANUFACTURER-251113-0225-BRAND-251113-0531	3000.000	kg	2025-11-13 05:31:01.372107
5	nhu.nguyentm06@gmail.com	farm	\N	GARMENT-001	GARMENT-001-SUPPLIER-251119-0812	4500.000	kg	2025-11-19 08:12:58.16266
6	hoanghuongngannn@gmail.com	supplier	\N	GARMENT-001-SUPPLIER-251119-0812	GARMENT-001-SUPPLIER-251119-0812-MANUFACTURER-251119-0817	4500.000	kg	2025-11-19 08:17:06.237214
7	nttrungg205@gmail.com	manufacturer	\N	GARMENT-001-SUPPLIER-251119-0812-MANUFACTURER-251119-0817	GARMENT-001-SUPPLIER-251119-0812-MANUFACTURER-251119-0817-BRAND-251119-0824	2000.000	kg	2025-11-19 08:24:46.384718
\.


--
-- Data for Name: batch_lineage; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.batch_lineage (id, parent_batch_id, child_batch_id, event_id, transformation_type, created_at, tenant_id) FROM stdin;
\.


--
-- Data for Name: batch_links; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.batch_links (id, parent_batch_id, child_batch_id, material_used, unit, created_at) FROM stdin;
\.


--
-- Data for Name: batch_usage_log; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.batch_usage_log (id, tenant_id, parent_batch_id, child_batch_id, event_id, used_quantity, unit, purpose, note, created_at, created_by) FROM stdin;
\.


--
-- Data for Name: batch_usages; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.batch_usages (id, parent_batch_id, child_batch_id, used_quantity, created_at) FROM stdin;
2	15	28	4300.000	2025-11-11 07:59:19.888676
3	14	29	5200.000	2025-11-12 15:35:00.314847
4	29	30	5200.000	2025-11-13 02:25:41.065517
5	30	31	3000.000	2025-11-13 05:31:01.372107
6	13	32	4500.000	2025-11-19 08:12:58.16266
7	32	33	4500.000	2025-11-19 08:17:06.237214
8	33	34	2000.000	2025-11-19 08:24:46.384718
\.


--
-- Data for Name: batches; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.batches (id, code, product_code, mfg_date, country, status, parent_batch_id, created_at, tenant_id, blockchain_tx_hash, material_type, description, origin_farm_id, source_epcis_id, certificates, origin, farm_id, supplier_id, farm_batch_id, supplier_batch_id, manufacturer_batch_id, brand_batch_id, farm_batch_code, supplier_batch_code, manufacturer_batch_code, brand_batch_code, quantity, unit, owner_role, level, next_level_cloned_at, remaining_quantity, used_quantity, converted_from_unit, converted_rate, updated_at) FROM stdin;
2	LOT-2025-10	T-SHIRT	2025-10-31	VN	\N	\N	2025-10-19 03:41:47.408365	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	kg	farm	\N	\N	\N	0.000	\N	\N	2025-11-13 06:48:36.554093+00
8	LOT-2025-10-27	A123456	2025-10-28	VN	active	\N	2025-10-28 14:51:13.472344	1	\N	Coton	ABC	\N	\N	\N	\N	4	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	kg	farm	\N	\N	\N	0.000	\N	\N	2025-11-13 06:48:36.554093+00
9	COTTON-001	COTTON-FIBER	2025-11-01	VN	active	\N	2025-11-01 02:40:06.466552	1	\N	fiber	High quality cotton fiber harvested from Bình Thuận	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	COTTON-001	\N	\N	\N	5000.000	kg	farm	\N	\N	\N	0.000	\N	\N	2025-11-13 06:48:36.554093+00
10	COTTON-002	COTTON-FIBER	2025-11-01	VN	active	\N	2025-11-01 02:40:06.466552	1	\N	fiber	Organic cotton harvested from Nghệ An	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	COTTON-002	\N	\N	\N	6200.000	kg	farm	\N	\N	\N	0.000	\N	\N	2025-11-13 06:48:36.554093+00
11	FABRIC-001	COTTON-FABRIC	2025-11-01	VN	active	\N	2025-11-01 02:40:06.488189	1	\N	woven	Woven fabric made from cotton fiber	\N	\N	\N	\N	\N	\N	9	\N	\N	\N	COTTON-001	FABRIC-001	\N	\N	4800.000	kg	farm	\N	\N	\N	0.000	\N	\N	2025-11-13 06:48:36.554093+00
12	FABRIC-002	COTTON-FABRIC	2025-11-01	VN	active	\N	2025-11-01 02:40:06.488189	1	\N	knit	Knitted fabric made from organic cotton	\N	\N	\N	\N	\N	\N	10	\N	\N	\N	COTTON-002	FABRIC-002	\N	\N	5900.000	kg	farm	\N	\N	\N	0.000	\N	\N	2025-11-13 06:48:36.554093+00
21	F-001	123456	2025-11-03	VN	active	\N	2025-11-03 13:06:44.243426	1	\N	Cotton	ABC	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	50.000	\N	\N	\N	\N	\N	0.000	\N	\N	2025-11-13 06:48:36.554093+00
15	BRAND-001	TSHIRT-MEN-XL	2025-11-01	VN	READY_FOR_NEXT_LEVEL	\N	2025-11-01 02:40:06.500518	1	\N	retail	Final packaged men T-shirts for retail	\N	\N	\N	\N	\N	\N	\N	\N	13	\N	\N	\N	GARMENT-001	BRAND-001	4300.000	kg	farm	\N	\N	\N	0.000	\N	\N	2025-11-13 08:01:15.31123+00
24	BRAND-002-MANUFACTURER-251106-0255	TSHIRT-WOMEN-M	2025-11-01	VN	OPEN	\N	2025-11-06 02:55:41.070852	1	\N	retail	Final packaged women T-shirts for retail	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	5000.000	kg	manufacturer	\N	\N	\N	0.000	\N	\N	2025-11-13 06:48:36.554093+00
25	BRAND-002-MANUFACTURER-251110-0143	TSHIRT-WOMEN-M	2025-11-01	VN	OPEN	\N	2025-11-10 01:43:16.014235	1	\N	retail	Final packaged women T-shirts for retail	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	5000.000	kg	manufacturer	\N	\N	\N	0.000	\N	\N	2025-11-13 06:48:36.554093+00
27	BRAND-002-MANUFACTURER-251110-1358	TSHIRT-WOMEN-M	2025-11-01	VN	OPEN	\N	2025-11-10 13:58:28.484117	1	\N	retail	Cloned from BRAND-002	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2000.000	kg	manufacturer	\N	\N	\N	0.000	\N	\N	2025-11-13 06:48:36.554093+00
28	BRAND-001-MANUFACTURER-251111-0759	TSHIRT-MEN-XL	2025-11-01	VN	OPEN	\N	2025-11-11 07:59:19.888676	1	\N	retail	Cloned from BRAND-001	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4300.000	kg	manufacturer	\N	\N	\N	0.000	kg	1.000000	2025-11-13 06:48:36.554093+00
14	GARMENT-002	TSHIRT-WOMEN	2025-11-01	VN	CLOSED	\N	2025-11-01 02:40:06.497408	1	\N	textile	Women T-shirts manufactured from FABRIC-002	\N	\N	\N	\N	\N	\N	\N	12	\N	\N	\N	FABRIC-002	GARMENT-002	\N	5200.000	kg	farm	\N	\N	\N	0.000	\N	\N	2025-11-13 06:48:36.554093+00
30	GARMENT-002-SUPPLIER-251112-1535-MANUFACTURER-251113-0225	TSHIRT-WOMEN	2025-11-01	VN	OPEN	\N	2025-11-13 02:25:41.065517	1	\N	textile	Cloned from GARMENT-002-SUPPLIER-251112-1535	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	5200.000	kg	manufacturer	\N	\N	\N	0.000	kg	1.000000	2025-11-13 06:48:36.554093+00
29	GARMENT-002-SUPPLIER-251112-1535	TSHIRT-WOMEN	2025-11-01	VN	CLOSED	\N	2025-11-12 15:35:00.314847	1	\N	textile	Cloned from GARMENT-002	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	5200.000	kg	supplier	\N	\N	\N	0.000	kg	1.000000	2025-11-13 06:48:36.554093+00
31	GARMENT-002-SUPPLIER-251112-1535-MANUFACTURER-251113-0225-BRAND-251113-0531	TSHIRT-WOMEN	2025-11-01	VN	READY_FOR_NEXT_LEVEL	\N	2025-11-13 05:31:01.372107	1	\N	textile	Cloned from GARMENT-002-SUPPLIER-251112-1535-MANUFACTURER-251113-0225	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	3000.000	kg	brand	\N	\N	\N	0.000	kg	1.000000	2025-11-14 08:39:17.270475+00
13	GARMENT-001	TSHIRT-MEN	2025-11-01	VN	CLOSED	\N	2025-11-01 02:40:06.497408	1	\N	textile	Men T-shirts manufactured from FABRIC-001	\N	\N	\N	\N	\N	\N	\N	11	\N	\N	\N	FABRIC-001	GARMENT-001	\N	4500.000	kg	farm	\N	\N	\N	0.000	\N	\N	2025-11-13 06:48:36.554093+00
33	GARMENT-001-SUPPLIER-251119-0812-MANUFACTURER-251119-0817	TSHIRT-MEN	2025-11-01	VN	OPEN	\N	2025-11-19 08:17:06.237214	1	\N	textile	Cloned from GARMENT-001-SUPPLIER-251119-0812	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4500.000	kg	manufacturer	\N	\N	\N	0.000	kg	1.000000	2025-11-19 08:17:06.237214+00
32	GARMENT-001-SUPPLIER-251119-0812	TSHIRT-MEN	2025-11-01	VN	CLOSED	\N	2025-11-19 08:12:58.16266	1	\N	textile	Cloned from GARMENT-001	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4500.000	kg	supplier	\N	\N	\N	0.000	kg	1.000000	2025-11-19 08:12:58.16266+00
34	GARMENT-001-SUPPLIER-251119-0812-MANUFACTURER-251119-0817-BRAND-251119-0824	TSHIRT-MEN	2025-11-01	VN	READY_FOR_NEXT_LEVEL	\N	2025-11-19 08:24:46.384718	1	\N	textile	Cloned from GARMENT-001-SUPPLIER-251119-0812-MANUFACTURER-251119-0817	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2000.000	kg	brand	\N	\N	\N	0.000	kg	1.000000	2025-11-19 08:29:15.56341+00
\.


--
-- Data for Name: blockchain_anchors; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.blockchain_anchors (id, tenant_id, anchor_type, ref, tx_hash, network, meta, bundle_id, batch_hash, block_number, status, created_at, updated_at, dpp_id, epcis_event_id, ipfs_cid) FROM stdin;
1	1	\N	\N	\N	polygon	\N	BATCH20251018-01-RUOJ	d9a59fbd9fa7bd48bd79fe50e51ca58f5bc6d5252cf0773fb43fcdb127f26830	\N	prepared	2025-10-18 07:50:49.91621+00	2025-10-18 07:50:49.91621+00	\N	\N	\N
2	1	epcis_batch	LOT-2025-10	0x09ec771dd984b8f8db24948b8ad358ea88a1e93d3c279d6249c960f591773d37	polygon	{"events": 3}	\N	eb71d14dd8881ea2d7faf1b4b76f185ca3da304cfd12bb6208e4a5e0cc41ba57	1159546	CONFIRMED	2025-10-20 07:48:47.190986+00	2025-10-21 15:01:09.028977+00	\N	\N	\N
\.


--
-- Data for Name: blockchain_proofs; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.blockchain_proofs (id, tenant_id, batch_code, network, tx_hash, block_number, root_hash, status, created_at, updated_at, contract_address, published_by, published_at) FROM stdin;
1	1	LOT-2025-10	polygon	0x254ce12cc2cdeb3c19161d675476b19fc5dd8bdca61f68cb57954d51a0afef02	28029228	038a35d0ce74cdb10aba40630151d6e4bfb30cfaf7942494e39eb2282ecea3e6	CONFIRMED	2025-10-21 14:23:52.55369+00	2025-10-22 06:56:23.332411+00	\N	\N	\N
32	1	BRAND-001	polygon	0xbb19fd2f090abe87c8f63c566ecb3c6929fd28e171d2da4439f2ff69fbbe067d	28981438	f8d66563e2cf3270d13ba6c65f8f75fa7b6bc6ca97e265fedce743334ef3cc94	CONFIRMED	2025-11-13 08:01:09.407687+00	2025-11-13 08:01:09.407687+00	\N	\N	\N
24	1	GARMENT-002-SUPPLIER-251112-1535-MANUFACTURER-251113-0225-BRAND-251113-0531	polygon	0x2d21fd36f70c6f058ece6186b99f91096c6d0f933f041b06973c2c9e11030b68	29025779	bd625513c02e102b3f54cb475dd59e5d0fd8dc7addf55a017d0c56da42d6e319	CONFIRMED	2025-11-13 06:00:44.771103+00	2025-11-14 08:39:09.936523+00	\N	\N	\N
36	1	GARMENT-001-SUPPLIER-251119-0812-MANUFACTURER-251119-0817-BRAND-251119-0824	polygon	0x88114b12aeeaa3c778f886d7236cb16acbf2fdfd9e966979c6dce45580f51e1d	29241465	3238d287945ec601ccf162d097f0db34fe3ba83f7c1eaa5f72985d7161bed443	CONFIRMED	2025-11-19 08:29:08.557894+00	2025-11-19 08:29:08.557894+00	\N	\N	\N
\.


--
-- Data for Name: brands; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.brands (id, name, owner, website, created_at, tenant_id) FROM stdin;
\.


--
-- Data for Name: compliance_results; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.compliance_results (id, tenant_id, batch_code, scheme, pass_flag, details) FROM stdin;
\.


--
-- Data for Name: configs_blockchain; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.configs_blockchain (id, tenant_id, chain_name, rpc_url, contract_address, network, abi_id, is_default, config_json, created_at, updated_at, description, version, updated_by, private_key) FROM stdin;
33	1	Polygon Amoy	https://rpc-amoy.polygon.technology	0x297E721A8d0B48B1b395D726Fc44C19e7CeadBBB	polygon-amoy	\N	t	{}	2025-10-22 04:13:28.261494+00	2025-10-22 04:13:28.261494+00	\N	v2	system	\N
23	1	Polygon Amoy	https://rpc-amoy.polygon.technology	0xc68E9eA73360Cf7bA9C18eE09053967147a3256d	polygon-amoy	\N	t	{"abi": [{"name": "Anchored", "type": "event", "inputs": [{"name": "ref", "type": "string", "indexed": false, "internalType": "string"}, {"name": "rootHash", "type": "bytes32", "indexed": false, "internalType": "bytes32"}, {"name": "sender", "type": "address", "indexed": true, "internalType": "address"}], "anonymous": false}, {"name": "anchor", "type": "function", "inputs": [{"name": "ref", "type": "string", "internalType": "string"}, {"name": "rootHash", "type": "bytes32", "internalType": "bytes32"}], "outputs": [], "stateMutability": "nonpayable"}, {"name": "get", "type": "function", "inputs": [{"name": "ref", "type": "string", "internalType": "string"}], "outputs": [{"name": "", "type": "bytes32", "internalType": "bytes32"}], "stateMutability": "view"}, {"name": "proofs", "type": "function", "inputs": [{"name": "", "type": "string", "internalType": "string"}], "outputs": [{"name": "", "type": "bytes32", "internalType": "bytes32"}], "stateMutability": "view"}], "chain_id": 80002}	2025-10-21 12:06:59.652776+00	2025-10-22 03:59:36.501578+00	\N	v2	system	\N
41	1	Fabric	http://localhost:8022	tracecc	fabric	1	t	{"gateway_url": "http://localhost:8022", "channel_name": "mychannel", "chaincode_name": "tracecc", "connection_profile": "{\\n  \\"fabric\\": {\\n    \\"chain_name\\": \\"Fabric\\",\\n    \\"rpc_url\\": \\"http://localhost:8022\\",\\n    \\"contract_address\\": \\"basic\\",\\n    \\"network\\": \\"fabric\\",\\n    \\"abi_id\\": 1,\\n    \\"config_json\\": {\\n      \\"gateway_url\\": \\"http://localhost:8022\\",\\n      \\"channel_name\\": \\"mychannel\\",\\n      \\"chaincode_name\\": \\"basic\\",\\n      \\"connection_profile\\": \\"{\\\\n  \\\\\\"name\\\\\\": \\\\\\"test-network\\\\\\",\\\\n  \\\\\\"version\\\\\\": \\\\\\"1.0.0\\\\\\",\\\\n  \\\\\\"client\\\\\\": {\\\\n    \\\\\\"organization\\\\\\": \\\\\\"Org1\\\\\\",\\\\n    \\\\\\"connection\\\\\\": {\\\\n      \\\\\\"timeout\\\\\\": {\\\\n        \\\\\\"peer\\\\\\": { \\\\\\"endorser\\\\\\": \\\\\\"300\\\\\\" },\\\\n        \\\\\\"orderer\\\\\\": \\\\\\"300\\\\\\"\\\\n      }\\\\n    }\\\\n  },\\\\n  \\\\\\"organizations\\\\\\": {\\\\n    \\\\\\"Org1\\\\\\": {\\\\n      \\\\\\"mspid\\\\\\": \\\\\\"Org1MSP\\\\\\",\\\\n      \\\\\\"peers\\\\\\": [\\\\\\"peer0.org1.example.com\\\\\\"],\\\\n      \\\\\\"certificateAuthorities\\\\\\": [\\\\\\"ca.org1.example.com\\\\\\"]\\\\n    }\\\\n  },\\\\n  \\\\\\"orderers\\\\\\": {\\\\n    \\\\\\"orderer.example.com\\\\\\": {\\\\n      \\\\\\"url\\\\\\": \\\\\\"grpcs://orderer.example.com:7050\\\\\\",\\\\n      \\\\\\"tlsCACerts\\\\\\": { \\\\\\"path\\\\\\": \\\\\\"/home/minhnhat81/fabric-dev/fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem\\\\\\" }\\\\n    }\\\\n  },\\\\n  \\\\\\"peers\\\\\\": {\\\\n    \\\\\\"peer0.org1.example.com\\\\\\": {\\\\n      \\\\\\"url\\\\\\": \\\\\\"grpcs://peer0.org1.example.com:7051\\\\\\",\\\\n      \\\\\\"tlsCACerts\\\\\\": { \\\\\\"path\\\\\\": \\\\\\"/home/minhnhat81/fabric-dev/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt\\\\\\" }\\\\n    }\\\\n  },\\\\n  \\\\\\"certificateAuthorities\\\\\\": {\\\\n    \\\\\\"ca.org1.example.com\\\\\\": {\\\\n      \\\\\\"url\\\\\\": \\\\\\"http://ca.org1.example.com:7054\\\\\\",\\\\n      \\\\\\"caName\\\\\\": \\\\\\"ca-org1\\\\\\"\\\\n    }\\\\n  }\\\\n}\\\\n\\"\\n    }\\n  }\\n}\\n"}	2025-10-24 08:25:45.626172+00	2025-10-24 08:25:45.626172+00	\N	v2	system	\N
25	1	Polygon Amoy	https://rpc-amoy.polygon.technology	0xa3B4F56A2d8Bf6A93ffF0Bb828a832375a2C5852	polygon-amoy	\N	t	{"abi": [{"name": "Anchored", "type": "event", "inputs": [{"name": "ref", "type": "string", "indexed": false, "internalType": "string"}, {"name": "rootHash", "type": "bytes32", "indexed": false, "internalType": "bytes32"}, {"name": "sender", "type": "address", "indexed": true, "internalType": "address"}], "anonymous": false}, {"name": "anchor", "type": "function", "inputs": [{"name": "ref", "type": "string", "internalType": "string"}, {"name": "rootHash", "type": "bytes32", "internalType": "bytes32"}], "outputs": [], "stateMutability": "nonpayable"}, {"name": "get", "type": "function", "inputs": [{"name": "ref", "type": "string", "internalType": "string"}], "outputs": [{"name": "", "type": "bytes32", "internalType": "bytes32"}], "stateMutability": "view"}, {"name": "proofs", "type": "function", "inputs": [{"name": "", "type": "string", "internalType": "string"}], "outputs": [{"name": "", "type": "bytes32", "internalType": "bytes32"}], "stateMutability": "view"}], "chain_id": 80002}	2025-10-21 12:08:04.58592+00	2025-10-22 03:59:36.501578+00	\N	v2	system	\N
12	1	Polygon Amoy	https://rpc-amoy.polygon.technology	0x755533D680EC8AfCE19c375eB14734618473EC59	polygon-amoy	\N	t	{"abi": [{"name": "Anchored", "type": "event", "inputs": [{"name": "ref", "type": "string", "indexed": false, "internalType": "string"}, {"name": "rootHash", "type": "bytes32", "indexed": false, "internalType": "bytes32"}, {"name": "sender", "type": "address", "indexed": true, "internalType": "address"}], "anonymous": false}, {"name": "anchor", "type": "function", "inputs": [{"name": "ref", "type": "string", "internalType": "string"}, {"name": "rootHash", "type": "bytes32", "internalType": "bytes32"}], "outputs": [], "stateMutability": "nonpayable"}, {"name": "get", "type": "function", "inputs": [{"name": "ref", "type": "string", "internalType": "string"}], "outputs": [{"name": "", "type": "bytes32", "internalType": "bytes32"}], "stateMutability": "view"}, {"name": "proofs", "type": "function", "inputs": [{"name": "", "type": "string", "internalType": "string"}], "outputs": [{"name": "", "type": "bytes32", "internalType": "bytes32"}], "stateMutability": "view"}], "chain_id": 80002}	2025-10-21 08:23:18.09421+00	2025-10-22 03:59:36.501578+00	\N	v2	system	\N
14	1	Polygon Amoy	https://rpc-amoy.polygon.technology	0xFdd34AeD38B79Cd7e68F960fBa231C4126C629f6	polygon-amoy	\N	t	{"abi": [{"name": "Anchored", "type": "event", "inputs": [{"name": "ref", "type": "string", "indexed": false, "internalType": "string"}, {"name": "rootHash", "type": "bytes32", "indexed": false, "internalType": "bytes32"}, {"name": "sender", "type": "address", "indexed": true, "internalType": "address"}], "anonymous": false}, {"name": "anchor", "type": "function", "inputs": [{"name": "ref", "type": "string", "internalType": "string"}, {"name": "rootHash", "type": "bytes32", "internalType": "bytes32"}], "outputs": [], "stateMutability": "nonpayable"}, {"name": "get", "type": "function", "inputs": [{"name": "ref", "type": "string", "internalType": "string"}], "outputs": [{"name": "", "type": "bytes32", "internalType": "bytes32"}], "stateMutability": "view"}, {"name": "proofs", "type": "function", "inputs": [{"name": "", "type": "string", "internalType": "string"}], "outputs": [{"name": "", "type": "bytes32", "internalType": "bytes32"}], "stateMutability": "view"}], "chain_id": 80002}	2025-10-21 10:15:02.2792+00	2025-10-22 03:59:36.501578+00	\N	v2	system	\N
17	1	Polygon Amoy	https://rpc-amoy.polygon.technology	0x8D2FC69d9f0be7cac8A624A5309ce08959b7Ec6A	polygon-amoy	\N	t	{"abi": [{"name": "Anchored", "type": "event", "inputs": [{"name": "ref", "type": "string", "indexed": false, "internalType": "string"}, {"name": "rootHash", "type": "bytes32", "indexed": false, "internalType": "bytes32"}, {"name": "sender", "type": "address", "indexed": true, "internalType": "address"}], "anonymous": false}, {"name": "anchor", "type": "function", "inputs": [{"name": "ref", "type": "string", "internalType": "string"}, {"name": "rootHash", "type": "bytes32", "internalType": "bytes32"}], "outputs": [], "stateMutability": "nonpayable"}, {"name": "get", "type": "function", "inputs": [{"name": "ref", "type": "string", "internalType": "string"}], "outputs": [{"name": "", "type": "bytes32", "internalType": "bytes32"}], "stateMutability": "view"}, {"name": "proofs", "type": "function", "inputs": [{"name": "", "type": "string", "internalType": "string"}], "outputs": [{"name": "", "type": "bytes32", "internalType": "bytes32"}], "stateMutability": "view"}], "chain_id": 80002}	2025-10-21 11:53:18.849115+00	2025-10-22 03:59:36.501578+00	\N	v2	system	\N
20	1	Polygon Amoy	https://rpc-amoy.polygon.technology	0x02e95D03EEd8b0A0CE541C6b82b36F675cFdc1E2	polygon-amoy	\N	t	{"abi": [{"name": "Anchored", "type": "event", "inputs": [{"name": "ref", "type": "string", "indexed": false, "internalType": "string"}, {"name": "rootHash", "type": "bytes32", "indexed": false, "internalType": "bytes32"}, {"name": "sender", "type": "address", "indexed": true, "internalType": "address"}], "anonymous": false}, {"name": "anchor", "type": "function", "inputs": [{"name": "ref", "type": "string", "internalType": "string"}, {"name": "rootHash", "type": "bytes32", "internalType": "bytes32"}], "outputs": [], "stateMutability": "nonpayable"}, {"name": "get", "type": "function", "inputs": [{"name": "ref", "type": "string", "internalType": "string"}], "outputs": [{"name": "", "type": "bytes32", "internalType": "bytes32"}], "stateMutability": "view"}, {"name": "proofs", "type": "function", "inputs": [{"name": "", "type": "string", "internalType": "string"}], "outputs": [{"name": "", "type": "bytes32", "internalType": "bytes32"}], "stateMutability": "view"}], "chain_id": 80002}	2025-10-21 12:02:56.458076+00	2025-10-22 03:59:36.501578+00	\N	v2	system	\N
27	1	Polygon Amoy	https://rpc-amoy.polygon.technology	0x6a6FcCC39894B4b32AcAB4fD3d2caFC6112dF9c6	polygon-amoy	\N	t	{"abi": [{"name": "Anchored", "type": "event", "inputs": [{"name": "ref", "type": "string", "indexed": false, "internalType": "string"}, {"name": "rootHash", "type": "bytes32", "indexed": false, "internalType": "bytes32"}, {"name": "sender", "type": "address", "indexed": true, "internalType": "address"}], "anonymous": false}, {"name": "anchor", "type": "function", "inputs": [{"name": "ref", "type": "string", "internalType": "string"}, {"name": "rootHash", "type": "bytes32", "internalType": "bytes32"}], "outputs": [], "stateMutability": "nonpayable"}, {"name": "get", "type": "function", "inputs": [{"name": "ref", "type": "string", "internalType": "string"}], "outputs": [{"name": "", "type": "bytes32", "internalType": "bytes32"}], "stateMutability": "view"}, {"name": "proofs", "type": "function", "inputs": [{"name": "", "type": "string", "internalType": "string"}], "outputs": [{"name": "", "type": "bytes32", "internalType": "bytes32"}], "stateMutability": "view"}], "chain_id": 80002}	2025-10-21 12:21:19.09068+00	2025-10-22 03:59:36.501578+00	\N	v2	system	\N
29	1	Polygon Amoy	https://rpc-amoy.polygon.technology	0xD6C688a964dcbe69D2Ec9008128a308dC9e985E7	polygon-amoy	\N	t	{"abi": [{"name": "Anchored", "type": "event", "inputs": [{"name": "ref", "type": "string", "indexed": false, "internalType": "string"}, {"name": "rootHash", "type": "bytes32", "indexed": false, "internalType": "bytes32"}, {"name": "sender", "type": "address", "indexed": true, "internalType": "address"}], "anonymous": false}, {"name": "anchor", "type": "function", "inputs": [{"name": "ref", "type": "string", "internalType": "string"}, {"name": "rootHash", "type": "bytes32", "internalType": "bytes32"}], "outputs": [], "stateMutability": "nonpayable"}, {"name": "get", "type": "function", "inputs": [{"name": "ref", "type": "string", "internalType": "string"}], "outputs": [{"name": "", "type": "bytes32", "internalType": "bytes32"}], "stateMutability": "view"}, {"name": "proofs", "type": "function", "inputs": [{"name": "", "type": "string", "internalType": "string"}], "outputs": [{"name": "", "type": "bytes32", "internalType": "bytes32"}], "stateMutability": "view"}], "chain_id": 80002}	2025-10-21 12:56:00.077721+00	2025-10-22 03:59:36.501578+00	\N	v2	system	\N
31	1	Polygon Amoy	https://rpc-amoy.polygon.technology	0x185eAB40cFa1f157aBd36D07374e207777298B90	polygon-amoy	\N	t	{"abi": [{"name": "Anchored", "type": "event", "inputs": [{"name": "ref", "type": "string", "indexed": false, "internalType": "string"}, {"name": "rootHash", "type": "bytes32", "indexed": false, "internalType": "bytes32"}, {"name": "sender", "type": "address", "indexed": true, "internalType": "address"}], "anonymous": false}, {"name": "anchor", "type": "function", "inputs": [{"name": "ref", "type": "string", "internalType": "string"}, {"name": "rootHash", "type": "bytes32", "internalType": "bytes32"}], "outputs": [], "stateMutability": "nonpayable"}, {"name": "get", "type": "function", "inputs": [{"name": "ref", "type": "string", "internalType": "string"}], "outputs": [{"name": "", "type": "bytes32", "internalType": "bytes32"}], "stateMutability": "view"}, {"name": "proofs", "type": "function", "inputs": [{"name": "", "type": "string", "internalType": "string"}], "outputs": [{"name": "", "type": "bytes32", "internalType": "bytes32"}], "stateMutability": "view"}], "chain_id": 80002}	2025-10-21 15:54:10.302155+00	2025-10-22 03:59:36.501578+00	\N	v2	system	\N
44	1	Polygon Amoy	https://rpc-amoy.polygon.technology	0xaDE5C136136533857D72308ae2bDc158Bc730379	polygon-amoy	\N	t	{}	2025-11-13 06:39:37.90545+00	2025-11-13 06:39:37.90545+00	\N	v2	system	\N
47	1	Polygon	https://rpc-amoy.polygon.technology	0xaDE5C136136533857D72308ae2bDc158Bc730379	polygon	1	t	{"mode": "real", "rpc_url": "https://rpc-amoy.polygon.technology", "chain_id": 80002, "gas_limit": 2000000, "private_key": "f0c54b8453ef55ec8549554627695744940b5a6df6a25ea7c8297fae86533d4f", "max_fee_gwei": 80, "contract_address": "0xaDE5C136136533857D72308ae2bDc158Bc730379", "priority_fee_gwei": 30}	2025-11-13 06:43:11.03704+00	2025-11-13 06:43:11.03704+00	\N	v2	system	\N
\.


--
-- Data for Name: credentials; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.credentials (id, tenant_id, subject, type, jws, status, hash_hex, created_at, issued_at, vc_payload, proof_tx, chain, public_key_base64, document_id, doc_bundle_id, verified, verify_error, updated_at) FROM stdin;
6ed71b36-9525-4651-8ca6-8036220ab0a0	1	did:example:TH01	DocumentCredential	eyJhbGciOiAiRWREU0EiLCAidHlwIjogIkpXVCJ9.eyJzdWIiOiAiZGlkOmV4YW1wbGU6VEgwMSIsICJ0eXBlIjogIkRvY3VtZW50Q3JlZGVudGlhbCIsICJoYXNoIjogImE2MjhjZWNmNDk2MDEzODk3OTJiYmY2ZmZkZWRkNjMyMmJkNmNlNDZmMTIyZTFjMDQzZjcxNGY1MWI2MjE3MjYiLCAiaWF0IjogMTc2MDc3MTU2OX0.8tXFVDrEi53XBAthWItu5JSQ9PaHR_DCmbpL0IfGrPOqQnjmF4DEYPRrcB9ONTQpaHWc8D1Y-KeLHbtWiQOpDA	verified	a628cecf49601389792bbf6ffdedd6322bd6ce46f122e1c043f714f51b621726	2025-10-18 07:12:49.051381	\N	{"iat": 1760771569, "sub": "did:example:TH01", "hash": "a628cecf49601389792bbf6ffdedd6322bd6ce46f122e1c043f714f51b621726", "type": "DocumentCredential"}	\N	\N	iRptB+wAKV+8j4E1iCF0PyGOzE6ymtfNENDYeW6Ty+M=	\N	\N	t	\N	2025-10-18 07:12:49.051381+00
39c93358-b70f-42e3-97b5-97ff7f8b2e31	1	did:example:TH02	DocumentCredential	eyJhbGciOiAiRWREU0EiLCAidHlwIjogIkpXVCJ9.eyJzdWIiOiAiZGlkOmV4YW1wbGU6VEgwMiIsICJ0eXBlIjogIkRvY3VtZW50Q3JlZGVudGlhbCIsICJoYXNoIjogIjI0OTYxMDg2NzJlYWFhNGU1NmY5ODJkNjVmOWI4NjY3ZmE1YzczZjk3MTg2MWQ1NTVmM2U4MjRmODhjNjQwOGEiLCAiaWF0IjogMTc2MDc3MjU5OH0.bbDeYVeKbCXhRtUFHUlxpONt1fjRJrzEttg9_75LXv2yVQdHj78ToaDeGLPTuaRZfQU5I_KsopWG9lj7w5ueCg	verified	2496108672eaaa4e56f982d65f9b8667fa5c73f971861d555f3e824f88c6408a	2025-10-18 07:29:58.915118	\N	{"iat": 1760772598, "sub": "did:example:TH02", "hash": "2496108672eaaa4e56f982d65f9b8667fa5c73f971861d555f3e824f88c6408a", "type": "DocumentCredential"}	\N	\N	eSnmfq7s4tHPq8mZn1RYfPdu2evWEtqglymqyInIUeQ=	\N	\N	t	\N	2025-10-18 07:29:58.915118+00
b6ede3f8-cb49-4b6a-b859-cec9b8051838	1	did:example:1	DocumentCredential	eyJhbGciOiAiRWREU0EiLCAidHlwIjogIkpXVCJ9.eyJzdWIiOiAiZGlkOmV4YW1wbGU6MSIsICJ0eXBlIjogIkRvY3VtZW50Q3JlZGVudGlhbCIsICJoYXNoIjogImRkZWQzMDc5ODc3YjUxY2NiNTg4YjgxZmVkNWZhNmY4MTcwNzgxNDhlMzM1MTgxNTBiYzViNDE1N2E2ZGU2MTAiLCAiaWF0IjogMTc2MDc3Mzc2NH0.jZ-LoH6W_JGsYcCb5-8IcBUgeMfEIWIzJtQbIUE5D9Pzrynhlp_rn4YY0kipTap6qFM15UZ-XRCG61fdERmyAA	verified	dded3079877b51ccb588b81fed5fa6f817078148e33518150bc5b4157a6de610	2025-10-18 07:49:24.006005	\N	{"iat": 1760773764, "sub": "did:example:1", "hash": "dded3079877b51ccb588b81fed5fa6f817078148e33518150bc5b4157a6de610", "type": "DocumentCredential"}	\N	\N	DS5svl6aueSsLaon9J7oA3MEG6YcSwnlMT8u/miojM0=	\N	\N	t	\N	2025-10-18 07:49:24.006005+00
\.


--
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.customers (id, code, name, country, contact_email, created_at, tenant_id) FROM stdin;
\.


--
-- Data for Name: customs; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.customs (id, customer_id, document_number, country, tenant_id) FROM stdin;
\.


--
-- Data for Name: data_sharing_agreements; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.data_sharing_agreements (id, tenant_id, partner, scope, terms) FROM stdin;
\.


--
-- Data for Name: documents; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.documents (id, tenant_id, title, hash, path, meta, file_name, file_type, file_size, file_hash, vc_payload, issued_at, created_at, vc_id, doc_bundle_id, hash_hex, vc_hash_hex, verified, batch_code) FROM stdin;
1	1	\N	\N	app/static/uploads/2e4870e7-7f73-4eff-8042-759fcd7130e7_CO-20251015-TH01_Certificate_of_Origin_(CO).pdf	\N	CO-20251015-TH01_Certificate_of_Origin_(CO).pdf	application/pdf	2128	dded3079877b51ccb588b81fed5fa6f817078148e33518150bc5b4157a6de610	{"type": ["VerifiableCredential", "DocumentCredential"], "issuer": "did:example:1", "@context": ["https://www.w3.org/2018/credentials/v1"], "issuanceDate": "2025-10-18T06:59:58.603620Z", "credentialSubject": {"meta": {"file_size": 2128, "file_type": "application/pdf", "original_name": "CO-20251015-TH01_Certificate_of_Origin_(CO).pdf"}, "storage": "app/static/uploads/2e4870e7-7f73-4eff-8042-759fcd7130e7_CO-20251015-TH01_Certificate_of_Origin_(CO).pdf", "fileHash": "dded3079877b51ccb588b81fed5fa6f817078148e33518150bc5b4157a6de610", "fileName": "CO-20251015-TH01_Certificate_of_Origin_(CO).pdf", "fileType": "application/pdf"}}	2025-10-18 06:59:58.603852	2025-10-18 06:59:58.603852	\N	BATCH20251018-01-RUOJ	\N	a628cecf49601389792bbf6ffdedd6322bd6ce46f122e1c043f714f51b621726	f	\N
2	1	\N	\N	app/static/uploads/18a5b617-3cec-4d1a-8dd9-eeef7031d6ef_GOTS-TH-2025-023_Global_Organic_Textile_Standard_(GOTS)_Certificate.pdf	\N	GOTS-TH-2025-023_Global_Organic_Textile_Standard_(GOTS)_Certificate.pdf	application/pdf	2187	2496108672eaaa4e56f982d65f9b8667fa5c73f971861d555f3e824f88c6408a	{"type": ["VerifiableCredential", "DocumentCredential"], "issuer": "did:example:1", "@context": ["https://www.w3.org/2018/credentials/v1"], "issuanceDate": "2025-10-18T06:59:58.775301Z", "credentialSubject": {"meta": {"file_size": 2187, "file_type": "application/pdf", "original_name": "GOTS-TH-2025-023_Global_Organic_Textile_Standard_(GOTS)_Certificate.pdf"}, "storage": "app/static/uploads/18a5b617-3cec-4d1a-8dd9-eeef7031d6ef_GOTS-TH-2025-023_Global_Organic_Textile_Standard_(GOTS)_Certificate.pdf", "fileHash": "2496108672eaaa4e56f982d65f9b8667fa5c73f971861d555f3e824f88c6408a", "fileName": "GOTS-TH-2025-023_Global_Organic_Textile_Standard_(GOTS)_Certificate.pdf", "fileType": "application/pdf"}}	2025-10-18 06:59:58.77538	2025-10-18 06:59:58.775381	\N	BATCH20251018-01-RUOJ	\N	b94715fd499539c0a2232d05b409b36c4b29019889ae2d1c9fac24aaa4fcedb5	f	\N
3	1	\N	\N	app/static/uploads/b70d608f-b3e7-4903-9bb6-8c5635358c5e_GRS-TH-2025-045_Global_Recycled_Standard_(GRS)_Certificate.pdf	\N	GRS-TH-2025-045_Global_Recycled_Standard_(GRS)_Certificate.pdf	application/pdf	2147	7b02bdc977f782697c5f0228bc375ce2addd72c79e22bcf7809fbfac5ccbb896	{"type": ["VerifiableCredential", "DocumentCredential"], "issuer": "did:example:1", "@context": ["https://www.w3.org/2018/credentials/v1"], "issuanceDate": "2025-10-19T05:58:44.788099Z", "credentialSubject": {"meta": {"file_size": 2147, "file_type": "application/pdf", "original_name": "GRS-TH-2025-045_Global_Recycled_Standard_(GRS)_Certificate.pdf"}, "storage": "app/static/uploads/b70d608f-b3e7-4903-9bb6-8c5635358c5e_GRS-TH-2025-045_Global_Recycled_Standard_(GRS)_Certificate.pdf", "fileHash": "7b02bdc977f782697c5f0228bc375ce2addd72c79e22bcf7809fbfac5ccbb896", "fileName": "GRS-TH-2025-045_Global_Recycled_Standard_(GRS)_Certificate.pdf", "fileType": "application/pdf"}}	2025-10-19 05:58:44.789066	2025-10-19 05:58:44.789069	\N	BATCH20251019-01-BEGQ	\N	2f447920f6c10881db82e4317a340035b581960620ee2c6197a74a132a4df5bd	f	\N
\.


--
-- Data for Name: domains; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.domains (id, name, code, tenant_id) FROM stdin;
\.


--
-- Data for Name: dpp_passports; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.dpp_passports (id, tenant_id, product_code, payload, version, batch_id, status, created_at, updated_at, product_description, composition, supply_chain, transport, documentation, environmental_impact, social_impact, animal_welfare, circularity, health_safety, brand_info, digital_identity, quantity_info, cost_info, use_phase, end_of_life, linked_epcis, linked_blockchain) FROM stdin;
\.


--
-- Data for Name: dpp_templates; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.dpp_templates (id, name, schema, tenant_id, tier, template_name, product_id, static_data, dynamic_data, description, is_active, created_at, updated_at) FROM stdin;
13	DPP 2	[{"key": "product_name", "type": "string", "label": "Product Name"}, {"key": "batch_number", "type": "string", "label": "Batch Number"}, {"key": "manufacture_date", "type": "date", "label": "Manufacture Date"}, {"key": "expiry_date", "type": "date", "label": "Expiry Date"}]	1	supplier	default	\N	{"use_phase": {"instructions": "A"}, "brand_info": {"brand": "A", "contact": "A"}, "composition": {"materials": "A", "percentages": "A"}, "end_of_life": {"recycle_guideline": "A"}, "health_safety": {"policy": "A", "certified_by": "A"}, "social_impact": {"factory": "A", "certifications": "A"}, "animal_welfare": {"notes": "A", "standard": "A"}, "digital_identity": {"qr": "11111", "did": "1111", "ipfs_cid": "1111"}, "product_description": {"gtin": "111", "name": "A", "model": "B"}}	{"cost_info": {"currency": "2", "labor_cost": "2", "transport_cost": "2"}, "transport": {"co2_per_km": "1", "distance_km": "1"}, "circularity": {"waste_reused": "0", "packaging_recycled": "2"}, "supply_chain": "222", "documentation": "2222", "quantity_info": {"unit": "2", "batch": "2", "weight": "2"}, "environmental_impact": {"co2": "2", "unit": "2", "water": "2", "electricity": "1"}}	A	t	2025-10-30 12:28:28.67373+00	2025-10-30 12:28:28.673736+00
14	DPP 3	{}	1	supplier	default	\N	{"use_phase": {"instructions": "A"}, "brand_info": {"brand": "A", "contact": "A"}, "composition": {"materials": ["A", "B"], "percentages": [50, 50], "materials_block": [{"name": "A", "percentage": 50}, {"name": "B", "percentage": 50}]}, "end_of_life": {"recycle_guideline": "A"}, "health_safety": {"policy": "A", "certified_by": ""}, "social_impact": {"factory": "A", "certifications": "A"}, "animal_welfare": {"notes": "A", "standard": "A"}, "digital_identity": {"qr": "A", "did": "A", "ipfs_cid": "A"}, "product_description": {"gtin": "A", "name": "A", "model": "A"}}	{"cost_info": {"labor_cost": 2, "transport_cost": 2}, "transport": {"co2_per_km": 2, "distance_km": 2}, "circularity": {"waste_reused": 2, "packaging_recycled": 2}, "supply_chain": {"updated_at": "1"}, "documentation": {"file": "a"}, "quantity_info": {"batch": "A", "weight": 2}, "environmental_impact": {"co2": 2, "water": 2, "electricity": 2}}	A	t	2025-10-30 15:19:30.530998+00	2025-10-30 15:19:30.531005+00
15	Organic Cotton Fabric DPP	[{"type": "string", "field": "gtin"}, {"type": "array", "field": "materials_block"}, {"type": "number", "field": "co2"}]	1	supplier	fabric_dpp_v1	\N	{"use_phase": {"instructions": "Wash at 30°C. Avoid bleach. Air dry for best results."}, "brand_info": {"brand": "GreenTextile Co.", "contact": "contact@greentextile.com"}, "composition": {"materials": ["Organic Cotton", "Recycled Polyester"], "percentages": [80, 20], "materials_block": [{"name": "Organic Cotton", "percentage": 80}, {"name": "Recycled Polyester", "percentage": 20}]}, "end_of_life": {"recycle_guideline": "Can be recycled or composted; check local textile recycling."}, "health_safety": {"policy": "Complies with OEKO-TEX 100", "certified_by": "OEKO-TEX Association"}, "social_impact": {"factory": "GreenTextile Factory", "certifications": [{"name": "Fair Trade Certified", "number": "FT-00221", "issued_by": "Fairtrade International"}, {"name": "GOTS", "number": "GOTS-2024-9987", "issued_by": "Control Union"}]}, "animal_welfare": {"notes": "No animal materials used", "standard": "N/A - Plant-based textile"}, "digital_identity": {"qr": "https://ipfs.io/ipfs/QmX1234", "did": "did:greentextile:cotton12345", "ipfs_cid": "QmX1234"}, "product_description": {"gtin": "8945123900123", "name": "Organic Cotton Fabric", "model": "OCF-2025"}}	{"cost_info": {"labor_cost": 1.8, "transport_cost": 0.6}, "transport": {"co2_per_km": 0.12, "distance_km": 600}, "circularity": {"waste_reused": 10, "packaging_recycled": 95}, "supply_chain": [{"tier": 1, "supplier": "Organic Cotton Farm Co-op, India", "updated_at": "2025-09-10"}, {"tier": 2, "supplier": "GreenTextile Spinning Mill", "updated_at": "2025-09-15"}], "documentation": [{"file": "https://docs.greentextile.com/fairtrade-cert.pdf", "issued_by": "Fairtrade International"}, {"file": "https://docs.greentextile.com/gots-cert.pdf", "issued_by": "Control Union"}], "quantity_info": {"batch": "BATCH-OCF-001", "weight": 350}, "environmental_impact": {"co2": 1.2, "water": 450, "electricity": 5.5}}	Template for organic cotton fabric material tracing and sustainability reporting.	t	2025-10-30 15:33:01.090116+00	2025-10-30 15:33:01.090126+00
\.


--
-- Data for Name: emissions; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.emissions (id, batch_id, co2_kg, recorded_at, tenant_id) FROM stdin;
\.


--
-- Data for Name: epcis_events; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.epcis_events (id, tenant_id, event_type, batch_code, product_code, event_time, action, biz_step, disposition, read_point, biz_location, epc_list, ilmd, extensions, event_time_zone_offset, biz_transaction_list, context, event_id, event_hash, doc_bundle_id, vc_hash_hex, verified, verify_error, raw_payload, created_at, updated_at, batch_id, dpp_id, dpp_passport_id, is_active, material_name, owner_role, input_quantity, input_uom, output_quantity, output_uom, last_modified_by, last_modified_at) FROM stdin;
1	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	[]	urn:uuid:fbaae889-1404-4c7f-b047-8d5838c2c9ce	10efddbb728194b785f5ef0b09b7dcfbca56ead196da7e58786d0a5dd544ba65	BATCH20251018-01-RUOJ	\N	f	\N	\N	2025-10-18 07:34:03.978197+00	2025-10-20 02:15:42.754936+00	\N	\N	\N	t	\N	FARM	\N	\N	\N	\N	\N	\N
2	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	[]	urn:uuid:8653b9a2-3240-4d3b-9eef-478c2b4d8def	bc3b92044364f6db99f243c34a2241919ed47d5b9395bba78e55516b765b0d17	BATCH20251018-01-RUOJ	\N	f	\N	\N	2025-10-18 07:34:03.978197+00	2025-10-20 02:15:42.754936+00	\N	\N	\N	t	\N	FARM	\N	\N	\N	\N	\N	\N
3	1	ObjectEvent	LOT-0001	TSHIRT	2025-10-15 01:30:00+00	ADD	urn:epcglobal:cbv:bizstep:packing	urn:epcglobal:cbv:disp:packed	urn:epc:id:sgln:8938501000400.line3	urn:epc:id:sgln:8938501000400	["urn:epc:id:sgtin:8938501.000123.001"]	\N	\N	+07:00	[{"id": "urn:epcglobal:cbv:bt:12345", "type": "po"}, {"id": "urn:epcglobal:cbv:bt:INV:20251015", "type": "inv"}]	["https://ref.gs1.org/standards/epcis/epcis-context.jsonld", {"gs1": "https://gs1.org/voc/", "example": "https://example.org/epcis/"}]	urn:uuid:df039f41-a5ef-4761-88fd-6443e344c263	e210283bf4c5d8cd4325464c55de76267a7f2423e6acf74dd1f20b34bd6b5af0	BATCH20251018-01-KXK2	\N	f	\N	\N	2025-10-18 08:23:09.446644+00	2025-10-20 02:15:42.754936+00	\N	\N	\N	t	\N	FARM	\N	\N	\N	\N	\N	\N
4	1	ObjectEvent	LOT-0001	TSHIRT	2025-10-18 07:30:00+00	ADD	urn:epcglobal:cbv:bizstep:shipping	urn:epcglobal:cbv:disp:in_transit	urn:epc:id:sgln:8938501000400.dock3	urn:epc:id:sgln:8938501000400.warehouseB	["urn:epc:id:sscc:8938501.000123.0001"]	\N	\N	+07:00	[{"id": "urn:epcglobal:cbv:bt:PO:20251018", "type": "po"}, {"id": "urn:epcglobal:cbv:bt:INV:20251018", "type": "inv"}, {"id": "urn:epcglobal:cbv:bt:DESADV:20251018", "type": "desadv"}]	["https://ref.gs1.org/standards/epcis/epcis-context.jsonld", {"gs1": "https://gs1.org/voc/", "example": "https://example.org/epcis/"}]	urn:uuid:def31e3a-14a0-4b3d-9b61-1d878d143596	91d56216753f7af8bd03a8127527901ac8f6b053530597aa65b74a42f7ef69f1	BATCH20251018-01-SQ2X	\N	f	\N	\N	2025-10-18 08:55:11.228894+00	2025-10-20 02:15:42.754936+00	\N	\N	\N	t	\N	FARM	\N	\N	\N	\N	\N	\N
5	1	ObjectEvent	LOT-2025-10	TSHIRT	\N	ADD	urn:epcglobal:cbv:bizstep:receiving	urn:epcglobal:cbv:disp:active	urn:epc:id:sgln:8938501000400.line3	urn:epc:id:sgln:8938501000400	[]	\N	\N	\N	[]	["https://ref.gs1.org/standards/epcis/epcis-context.jsonld", {"gs1": "https://gs1.org/voc/", "example": "https://example.org/epcis/"}]	urn:uuid:7b3df996-8200-4072-8fea-232b8913b8a2	b481775381de0a3f436d9d97f3c217fa3271502f326a67a779c06ce5b0ba3136	BATCH20251019-01-BEGQ	\N	f	\N	\N	2025-10-19 10:24:34.396696+00	2025-10-20 02:15:42.754936+00	\N	\N	\N	t	\N	FARM	\N	\N	\N	\N	\N	\N
6	1	AggregationEvent	LOT-2025-10	TSHIRT	2025-10-20 04:26:44.199+00	ADD	urn:epcglobal:cbv:bizstep:manufacturing	urn:epcglobal:cbv:disp:in_progress	urn:epc:id:sgln:8938501000400.line3	urn:epc:id:sgln:8938501000400	[]	\N	\N	+07:00	[]	["https://ref.gs1.org/standards/epcis/epcis-context.jsonld", {"gs1": "https://gs1.org/voc/", "example": "https://example.org/epcis/"}]	urn:uuid:5aba2359-ab25-40eb-8bbf-df844a66ac4a	f7794353132a3c10515f5091f32bf498af662015677e6e01019b401fecfb32f1	BATCH20251018-01-RUOJ	\N	f	\N	\N	2025-10-19 15:06:51.977086+00	2025-10-20 02:15:42.754936+00	\N	\N	\N	t	\N	FARM	\N	\N	\N	\N	\N	\N
7	1	ObjectEvent	LOT-2025-10	TSHIRT	2025-10-20 04:44:57+00	ADD	urn:epcglobal:cbv:bizstep:packing	urn:epcglobal:cbv:disp:in_progress	urn:epc:id:sgln:8938501000400.line3	urn:epc:id:sgln:8938501000400	[]	\N	\N	+07:00	[]	["https://ref.gs1.org/standards/epcis/epcis-context.jsonld", {"gs1": "https://gs1.org/voc/", "example": "https://example.org/epcis/"}]	urn:uuid:fe659bec-9545-4a4f-81ff-3563073922e5	e84c08e80203310122f9855db7f2d90484893635e0d9467a46de2497e3c874ae	BATCH20251019-01-BEGQ	\N	f	\N	\N	2025-10-20 04:45:47.27606+00	2025-10-20 04:45:47.27606+00	\N	\N	\N	t	\N	FARM	\N	\N	\N	\N	\N	\N
8	1	ObjectEvent	F-001	TSHIRT	2025-11-03 14:02:25+00	ADD	urn:epcglobal:cbv:bizstep:receiving	urn:epcglobal:cbv:disp:active	urn:epc:id:sgln:8938501000400.line3	urn:epc:id:sgln:8938501000400	["urn:epc:id:sgtin:Comapny.prefix"]	{"dpp": {"use_phase": {"instructions": "Wash at 30°C. Avoid bleach. Air dry for best results."}, "brand_info": {"brand": "GreenTextile Co.", "contact": "contact@greentextile.com"}, "composition": {"materials": ["Organic Cotton", "Recycled Polyester"], "percentages": [80, 20], "materials_block": [{"name": "Organic Cotton", "percentage": 80}, {"name": "Recycled Polyester", "percentage": 20}]}, "end_of_life": {"recycle_guideline": "Can be recycled or composted; check local textile recycling."}, "health_safety": {"policy": "Complies with OEKO-TEX 100", "certified_by": "OEKO-TEX Association"}, "social_impact": {"factory": "GreenTextile Factory", "certifications": [{"name": "Fair Trade Certified", "number": "FT-00221", "issued_by": "Fairtrade International"}, {"name": "GOTS", "number": "GOTS-2024-9987", "issued_by": "Control Union"}]}, "animal_welfare": {"notes": "No animal materials used", "standard": "N/A - Plant-based textile"}, "digital_identity": {"qr": "https://ipfs.io/ipfs/QmX1234", "did": "did:greentextile:cotton12345", "ipfs_cid": "QmX1234"}, "product_description": {"gtin": "8945123900123", "name": "Organic Cotton Fabric", "model": "OCF-2025"}}, "Color": "blue"}	null	+07:00	[{"id": "12345", "type": "po"}]	["https://ref.gs1.org/standards/epcis/epcis-context.jsonld", {"gs1": "https://gs1.org/voc/", "example": "https://example.org/epcis/"}]	urn:uuid:8ca861fb-0cc1-4429-bb1f-fecdffde03f5	977af4bd275c7254285ea18ea13cf789b5f1ef01ff6a45881fcd70ff3f96a6ec	BATCH20251019-01-BEGQ	\N	f	\N	\N	2025-11-03 14:10:47.880678+00	2025-11-03 14:10:47.880678+00	\N	\N	\N	t	\N	FARM	\N	\N	\N	\N	\N	\N
9	1	ObjectEvent	F-001	\N	2025-11-03 14:45:29+00	ADD	urn:epcglobal:cbv:bizstep:receiving	urn:epcglobal:cbv:disp:active	urn:epc:id:sgln:8938501000400.line3	urn:epc:id:sgln:8938501000400	["urn:epc:id:sgtin:Comapny.prefix"]	{"dpp": {"use_phase": {"instructions": "Wash at 30°C. Avoid bleach. Air dry for best results."}, "brand_info": {"brand": "GreenTextile Co.", "contact": "contact@greentextile.com"}, "composition": {"materials": ["Organic Cotton", "Recycled Polyester"], "percentages": [80, 20], "materials_block": [{"name": "Organic Cotton", "percentage": 80}, {"name": "Recycled Polyester", "percentage": 20}]}, "end_of_life": {"recycle_guideline": "Can be recycled or composted; check local textile recycling."}, "health_safety": {"policy": "Complies with OEKO-TEX 100", "certified_by": "OEKO-TEX Association"}, "social_impact": {"factory": "GreenTextile Factory", "certifications": [{"name": "Fair Trade Certified", "number": "FT-00221", "issued_by": "Fairtrade International"}, {"name": "GOTS", "number": "GOTS-2024-9987", "issued_by": "Control Union"}]}, "animal_welfare": {"notes": "No animal materials used", "standard": "N/A - Plant-based textile"}, "digital_identity": {"qr": "https://ipfs.io/ipfs/QmX1234", "did": "did:greentextile:cotton12345", "ipfs_cid": "QmX1234"}, "product_description": {"gtin": "8945123900123", "name": "Organic Cotton Fabric", "model": "OCF-2025"}}, "Color": "blue"}	null	+07:00	[{"id": "12345", "type": "po"}]	["https://ref.gs1.org/standards/epcis/epcis-context.jsonld", {"gs1": "https://gs1.org/voc/", "example": "https://example.org/epcis/"}]	urn:uuid:43c276cd-d3b5-42d8-a74c-e532e06d7a5b	00e913d296068a884e61741992b018f03a4583639ee45fd32a4fac39b934ccee	BATCH20251019-01-BEGQ	\N	f	\N	\N	2025-11-03 14:48:23.323035+00	2025-11-03 14:48:23.323035+00	\N	\N	\N	t	\N	FARM	\N	\N	\N	\N	\N	\N
34	1	ObjectEvent	BRAND-002	\N	2025-11-11 02:54:21+00	ADD	urn:epcglobal:cbv:bizstep:receiving	urn:epcglobal:cbv:disp:active	"urn:epc:id:sgln:8938501000400.line3"	"urn:epc:id:sgln:undefined"	["urn:epc:id:sgtin:Comapny.prefix"]	{}	\N	\N	[]	[]	urn:uuid:e8f4c11d-ab10-44f3-946e-a22195f0938d	3e127fc51efef9ab5e9ddb7eb8121cc68e7aff331690f27637ea1659300581ff	BATCH20251019-01-BEGQ	\N	f	\N	\N	2025-11-11 02:54:40.382168+00	2025-11-11 02:54:40.382168+00	\N	\N	\N	t	\N	SUPPLIER	\N	\N	\N	\N	\N	\N
37	1	ObjectEvent	GARMENT-002	\N	2025-11-12 15:34:25+00	ADD	urn:epcglobal:cbv:bizstep:receiving	urn:epcglobal:cbv:disp:active	"urn:epc:id:sgln:8938501000400.line3"	"urn:epc:id:sgln:undefined"	["urn:epc:id:sgtin:Comapny.prefix"]	{}	\N	\N	[]	[]	urn:uuid:06f63519-4364-40f3-ba00-612eedb00cbc	6f28d06dce1fcd37d769c28eb955685c36883449a91afede65a9f05b16411c13	BATCH20251019-01-BEGQ	\N	f	\N	\N	2025-11-12 15:34:50.053096+00	2025-11-12 15:34:50.053096+00	\N	\N	\N	t	\N	SUPPLIER	\N	\N	\N	\N	\N	\N
38	1	ObjectEvent	GARMENT-002-SUPPLIER-251112-1535	\N	2025-11-13 02:06:57+00	ADD	urn:epcglobal:cbv:bizstep:shipping	urn:epcglobal:cbv:disp:active	"urn:epc:id:sgln:8938501000400.line3"	"urn:epc:id:sgln:undefined"	["urn:epc:id:sgtin:Comapny.prefix"]	{}	\N	\N	[]	[]	urn:uuid:4f95da26-d79d-4284-bca0-090327684c12	4e4623212aa672811eab0b4d0b242091abec767afbfe6fcf6c9599a1914ee808	BATCH20251019-01-BEGQ	\N	f	\N	\N	2025-11-13 02:07:24.001773+00	2025-11-13 02:07:24.001773+00	\N	\N	\N	t	\N	SUPPLIER	\N	\N	\N	\N	\N	\N
39	1	ObjectEvent	GARMENT-002-SUPPLIER-251112-1535-MANUFACTURER-251113-0225	GAR1001	2025-11-13 02:45:24+00	ADD	urn:epcglobal:cbv:bizstep:manufacturing	urn:epcglobal:cbv:disp:active	"urn:epc:id:sgln:8938501000400.line3"	"urn:epc:id:sgln:undefined"	["urn:epc:id:sgtin:Comapny.prefix"]	{}	\N	\N	[]	[]	urn:uuid:cabc3516-e2b4-4011-a569-eec42b915930	4ecb5c7d2c19e21357b93f4fc7643f651f6f917d01545ad58bc28da239233086	BATCH20251019-01-BEGQ	\N	f	\N	\N	2025-11-13 02:45:55.307445+00	2025-11-13 02:45:55.307445+00	\N	\N	\N	t	\N	MANUFACTURER	\N	\N	\N	\N	\N	\N
35	1	ObjectEvent	BRAND-001	\N	2025-11-11 05:00:47+00	ADD	urn:epcglobal:cbv:bizstep:receiving	urn:epcglobal:cbv:disp:active	"urn:epc:id:sgln:8938501000400.line3\\""	"urn:epc:id:sgln:undefined"	["urn:epc:id:sgtin:Comapny.prefix"]	{"dpp": {"cost_info": {"labor_cost": "2", "transport_cost": "2"}, "transport": {"distance": "20", "co2_per_km": "20"}, "use_phase": {"instructions": "Wash at 30°C. Avoid bleach. Air dry for best results."}, "brand_info": {"brand": "GreenTextile Co.", "contact": "contact@greentextile.com"}, "circularity": {"reusability": "20", "waste_reduction": "20", "recycled_content": "20"}, "composition": {"materials": ["Organic Cotton", "Recycled Polyester"], "percentages": [80, 20], "materials_block": [{"name": "Organic Cotton", "percentage": 80}, {"name": "Recycled Polyester", "percentage": 20}]}, "end_of_life": {"recycle_guideline": "Can be recycled or composted; check local textile recycling."}, "supply_chain": {"tier": "3", "supplier": "3", "updated_at": "3"}, "documentation": {"file": "a", "issued_by": "a"}, "health_safety": {"policy": "Complies with OEKO-TEX 100", "certified_by": "OEKO-TEX Association"}, "quantity_info": {"batch": "456789", "weight": "200"}, "social_impact": {"factory": "GreenTextile Factory", "certifications": [{"name": "Fair Trade Certified", "number": "FT-00221", "issued_by": "Fairtrade International"}, {"name": "GOTS", "number": "GOTS-2024-9987", "issued_by": "Control Union"}]}, "animal_welfare": {"notes": "No animal materials used", "standard": "N/A - Plant-based textile"}, "digital_identity": {"qr": "https://ipfs.io/ipfs/QmX1234", "did": "did:greentextile:cotton12345", "ipfs_cid": "QmX1234"}, "product_description": {"gtin": "8945123900123", "name": "Organic Cotton Fabric", "model": "OCF-2025"}, "environmental_impact": {"co2": "1", "water": "11", "energy": "11"}}, "Color": "red"}	\N	\N	[{"id": "23579", "type": "po"}]	[]	urn:uuid:84eb7428-fd84-4e43-bda6-e04dc7c95a7c	dd975f4ea86069181db070a15f2a41196c9dc8357fe81ba8e8baedb34bd1672c	BATCH20251019-01-BEGQ	\N	f	\N	\N	2025-11-11 05:01:09.927377+00	2025-11-11 05:01:09.927377+00	\N	\N	\N	t	\N	SUPPLIER	\N	\N	\N	\N	\N	\N
41	1	ObjectEvent	GARMENT-002-SUPPLIER-251112-1535-MANUFACTURER-251113-0225-BRAND-251113-0531	GAR1001	2025-11-13 05:56:45+00	ADD	urn:epcglobal:cbv:bizstep:receiving	urn:epcglobal:cbv:disp:active	"urn:epc:id:sgln:8938501000400.line3"	"urn:epc:id:sgln:undefined"	["urn:epc:id:sgtin:Comapny.prefix"]	{"dpp": {"use_phase": {"instructions": "Wash at 30°C. Avoid bleach. Air dry for best results."}, "brand_info": {"brand": "GreenTextile Co.", "contact": "contact@greentextile.com"}, "composition": {"materials": ["Organic Cotton", "Recycled Polyester"], "percentages": [80, 20], "materials_block": [{"name": "Organic Cotton", "percentage": 80}, {"name": "Recycled Polyester", "percentage": 20}]}, "end_of_life": {"recycle_guideline": "Can be recycled or composted; check local textile recycling."}, "health_safety": {"policy": "Complies with OEKO-TEX 100", "certified_by": "OEKO-TEX Association"}, "social_impact": {"factory": "GreenTextile Factory", "certifications": [{"name": "Fair Trade Certified", "number": "FT-00221", "issued_by": "Fairtrade International"}, {"name": "GOTS", "number": "GOTS-2024-9987", "issued_by": "Control Union"}]}, "animal_welfare": {"notes": "No animal materials used", "standard": "N/A - Plant-based textile"}, "digital_identity": {"qr": "https://ipfs.io/ipfs/QmX1234", "did": "did:greentextile:cotton12345", "ipfs_cid": "QmX1234"}, "product_description": {"gtin": "8945123900123", "name": "Organic Cotton Fabric", "model": "OCF-2025"}}, "Color": "red"}	\N	\N	[{"id": "12345", "type": "po"}]	[]	urn:uuid:e5dc7c77-300d-48b9-aa19-811b38064002	c4367b96e85bff0e2eb70861d6d9e410a1ae022ed6bad99456de22cf5cd5a0c9	BATCH20251019-01-BEGQ	\N	f	\N	\N	2025-11-13 05:57:40.438746+00	2025-11-13 05:57:40.438746+00	\N	\N	\N	t	\N	BRAND	\N	\N	\N	\N	\N	\N
36	1	ObjectEvent	BRAND-001	\N	2025-11-11 05:41:54+00	ADD	urn:epcglobal:cbv:bizstep:shipping	urn:epcglobal:cbv:disp:active	"urn:epc:id:sgln:8938501000400.line3"	"urn:epc:id:sgln:undefined"	["urn:epc:id:sgtin:Comapny.prefix"]	{"dpp": {"use_phase": {"instructions": "Wash at 30°C. Avoid bleach. Air dry for best results."}, "brand_info": {"brand": "GreenTextile Co.", "contact": "contact@greentextile.com"}, "composition": {"materials": ["Organic Cotton", "Recycled Polyester"], "percentages": [80, 20], "materials_block": [{"name": "Organic Cotton", "percentage": 80}, {"name": "Recycled Polyester", "percentage": 20}]}, "end_of_life": {"recycle_guideline": "Can be recycled or composted; check local textile recycling."}, "health_safety": {"policy": "Complies with OEKO-TEX 100", "certified_by": "OEKO-TEX Association"}, "social_impact": {"factory": "GreenTextile Factory", "certifications": [{"name": "Fair Trade Certified", "number": "FT-00221", "issued_by": "Fairtrade International"}, {"name": "GOTS", "number": "GOTS-2024-9987", "issued_by": "Control Union"}]}, "animal_welfare": {"notes": "No animal materials used", "standard": "N/A - Plant-based textile"}, "digital_identity": {"qr": "https://ipfs.io/ipfs/QmX1234", "did": "did:greentextile:cotton12345", "ipfs_cid": "QmX1234"}, "product_description": {"gtin": "8945123900123", "name": "Organic Cotton Fabric", "model": "OCF-2025"}}, "Color": "red"}	\N	\N	[{"id": "12345", "type": "po"}]	[]	urn:uuid:fe739347-dbe0-447a-aceb-3f5c38074103	73ec5e971f286244971df710c67f65cb3b92fdeebc099cb64006e90f6bd9c380	BATCH20251019-01-BEGQ	\N	f	\N	\N	2025-11-11 05:43:12.751431+00	2025-11-11 05:43:12.751431+00	\N	\N	\N	t	\N	SUPPLIER	\N	\N	\N	\N	\N	\N
42	1	ObjectEvent	GARMENT-001	\N	2025-11-19 08:09:21+00	ADD	urn:epcglobal:cbv:bizstep:receiving	urn:epcglobal:cbv:disp:active	"urn:epc:id:sgln:8938501000400.line3"	"urn:epc:id:sgln:undefined"	["urn:epc:id:sgtin:Comapny.prefix"]	{"dpp": {"cost_info": {"labor_cost": "1", "transport_cost": "1"}, "transport": {"distance": "1", "co2_per_km": "1"}, "use_phase": {"instructions": "Wash at 30°C. Avoid bleach. Air dry for best results."}, "brand_info": {"brand": "GreenTextile Co.", "contact": "contact@greentextile.com"}, "circularity": {"reusability": "1", "waste_reduction": "1", "recycled_content": "1"}, "composition": {"materials": ["Organic Cotton", "Recycled Polyester"], "percentages": [80, 20], "materials_block": [{"name": "Organic Cotton", "percentage": 80}, {"name": "Recycled Polyester", "percentage": 20}]}, "end_of_life": {"recycle_guideline": "Can be recycled or composted; check local textile recycling."}, "supply_chain": {"tier": "1", "supplier": "1", "updated_at": "1"}, "documentation": {"file": "1", "issued_by": "1"}, "health_safety": {"policy": "Complies with OEKO-TEX 100", "certified_by": "OEKO-TEX Association"}, "quantity_info": {"batch": "1"}, "social_impact": {"factory": "GreenTextile Factory", "certifications": [{"name": "Fair Trade Certified", "number": "FT-00221", "issued_by": "Fairtrade International"}, {"name": "GOTS", "number": "GOTS-2024-9987", "issued_by": "Control Union"}]}, "animal_welfare": {"notes": "No animal materials used", "standard": "N/A - Plant-based textile"}, "digital_identity": {"qr": "https://ipfs.io/ipfs/QmX1234", "did": "did:greentextile:cotton12345", "ipfs_cid": "QmX1234"}, "product_description": {"gtin": "8945123900123", "name": "Organic Cotton Fabric", "model": "OCF-2025"}, "environmental_impact": {"co2": "1", "water": "1", "energy": "1"}}, "Color": "red"}	\N	\N	[{"id": "456789", "type": "po"}]	[]	urn:uuid:179e8d0f-a982-4df5-923b-b62695e207da	3d1f19eb438a70e5c93ddb86a533878352e95d9b5da1866566722eb10aeb3370	BATCH20251019-01-BEGQ	\N	f	\N	\N	2025-11-19 08:10:51.446599+00	2025-11-19 08:10:51.446599+00	\N	\N	\N	t	\N	FARM	\N	\N	\N	\N	\N	\N
40	1	ObjectEvent	GARMENT-002-SUPPLIER-251112-1535-MANUFACTURER-251113-0225	GAR1001	2025-11-13 05:41:18+00	ADD	urn:epcglobal:cbv:bizstep:shipping	urn:epcglobal:cbv:disp:active	"urn:epc:id:sgln:8938501000400.line3\\\\\\"\\""	"urn:epc:id:sgln:undefined"	["urn:epc:id:sgtin:Comapny.prefix"]	{"dpp": {"cost_info": {"labor_cost": "1", "transport_cost": "1"}, "transport": {"distance": "1", "co2_per_km": "1"}, "use_phase": {"instructions": "Wash at 30°C. Avoid bleach. Air dry for best results."}, "brand_info": {"brand": "GreenTextile Co.", "contact": "contact@greentextile.com"}, "circularity": {"reusability": "1", "waste_reduction": "1", "recycled_content": "1"}, "composition": {"materials": ["Organic Cotton", "Recycled Polyester"], "percentages": [80, 20], "materials_block": [{"name": "Organic Cotton", "percentage": 80}, {"name": "Recycled Polyester", "percentage": 20}]}, "end_of_life": {"recycle_guideline": "Can be recycled or composted; check local textile recycling."}, "supply_chain": {"tier": "1", "supplier": "1", "updated_at": "1"}, "documentation": {"file": "1", "issued_by": "1"}, "health_safety": {"policy": "Complies with OEKO-TEX 100", "certified_by": "OEKO-TEX Association"}, "quantity_info": {"batch": "1", "weight": "1"}, "social_impact": {"factory": "GreenTextile Factory", "certifications": [{"name": "Fair Trade Certified", "number": "FT-00221", "issued_by": "Fairtrade International"}, {"name": "GOTS", "number": "GOTS-2024-9987", "issued_by": "Control Union"}]}, "animal_welfare": {"notes": "No animal materials used", "standard": "N/A - Plant-based textile"}, "digital_identity": {"qr": "https://ipfs.io/ipfs/QmX1234", "did": "did:greentextile:cotton12345", "ipfs_cid": "QmX1234"}, "product_description": {"gtin": "8945123900123", "name": "Organic Cotton Fabric", "model": "OCF-2025"}, "environmental_impact": {"co2": "1", "water": "1", "energy": "1"}}, "Color": "blue"}	\N	\N	[{"id": "456789", "type": "po"}]	[]	urn:uuid:8c22889e-f160-439a-ba6e-3940aecf4c8c	986a26b28325e2007844e348cc4ddd89508d536f660a2bcf65a395886fd77287	BATCH20251019-01-BEGQ	\N	f	\N	\N	2025-11-13 05:42:15.481164+00	2025-11-13 05:42:15.481164+00	\N	\N	\N	t	\N	MANUFACTURER	\N	\N	\N	\N	\N	\N
43	1	ObjectEvent	GARMENT-001	\N	2025-11-19 08:10:51+00	ADD	urn:epcglobal:cbv:bizstep:shipping	urn:epcglobal:cbv:disp:active	"urn:epc:id:sgln:8938501000400.line3"	"urn:epc:id:sgln:undefined"	["urn:epc:id:sgtin:Comapny.prefix"]	{"dpp": {"use_phase": {"instructions": "Wash at 30°C. Avoid bleach. Air dry for best results."}, "brand_info": {"brand": "GreenTextile Co.", "contact": "contact@greentextile.com"}, "composition": {"materials": ["Organic Cotton", "Recycled Polyester"], "percentages": [80, 20], "materials_block": [{"name": "Organic Cotton", "percentage": 80}, {"name": "Recycled Polyester", "percentage": 20}]}, "end_of_life": {"recycle_guideline": "Can be recycled or composted; check local textile recycling."}, "health_safety": {"policy": "Complies with OEKO-TEX 100", "certified_by": "OEKO-TEX Association"}, "social_impact": {"factory": "GreenTextile Factory", "certifications": [{"name": "Fair Trade Certified", "number": "FT-00221", "issued_by": "Fairtrade International"}, {"name": "GOTS", "number": "GOTS-2024-9987", "issued_by": "Control Union"}]}, "animal_welfare": {"notes": "No animal materials used", "standard": "N/A - Plant-based textile"}, "digital_identity": {"qr": "https://ipfs.io/ipfs/QmX1234", "did": "did:greentextile:cotton12345", "ipfs_cid": "QmX1234"}, "product_description": {"gtin": "8945123900123", "name": "Organic Cotton Fabric", "model": "OCF-2025"}}, "Color": "N/A"}	\N	\N	[{"id": "456789", "type": "po"}]	[]	urn:uuid:13c4a853-90d9-4b3a-9a31-410c4a711b40	497c25d1c4d1efd9e5a52b37467f0b553156820fc1656417d16eacc2ba135b66	BATCH20251018-01-RUOJ	\N	f	\N	\N	2025-11-19 08:12:05.651741+00	2025-11-19 08:12:05.651741+00	\N	\N	\N	t	\N	FARM	\N	\N	\N	\N	\N	\N
44	1	ObjectEvent	GARMENT-001-SUPPLIER-251119-0812	\N	2025-11-19 08:13:57+00	ADD	urn:epcglobal:cbv:bizstep:receiving	urn:epcglobal:cbv:disp:active	"urn:epc:id:sgln:8938501000400.line3"	"urn:epc:id:sgln:undefined"	["urn:epc:id:sgtin:Comapny.prefix"]	{"dpp": {"cost_info": {"labor_cost": "1", "transport_cost": "1"}, "transport": {"distance": "1", "co2_per_km": "1"}, "use_phase": {"instructions": "Wash at 30°C. Avoid bleach. Air dry for best results."}, "brand_info": {"brand": "GreenTextile Co.", "contact": "contact@greentextile.com"}, "circularity": {"reusability": "1", "waste_reduction": "1", "recycled_content": "1"}, "composition": {"materials": ["Organic Cotton", "Recycled Polyester"], "percentages": [80, 20], "materials_block": [{"name": "Organic Cotton", "percentage": 80}, {"name": "Recycled Polyester", "percentage": 20}]}, "end_of_life": {"recycle_guideline": "Can be recycled or composted; check local textile recycling."}, "supply_chain": {"tier": "2", "supplier": "2", "updated_at": "2"}, "documentation": {"file": "1", "issued_by": "1"}, "health_safety": {"policy": "Complies with OEKO-TEX 100", "certified_by": "OEKO-TEX Association"}, "quantity_info": {"batch": "1", "weight": "1"}, "social_impact": {"factory": "GreenTextile Factory", "certifications": [{"name": "Fair Trade Certified", "number": "FT-00221", "issued_by": "Fairtrade International"}, {"name": "GOTS", "number": "GOTS-2024-9987", "issued_by": "Control Union"}]}, "animal_welfare": {"notes": "No animal materials used", "standard": "N/A - Plant-based textile"}, "digital_identity": {"qr": "https://ipfs.io/ipfs/QmX1234", "did": "did:greentextile:cotton12345", "ipfs_cid": "QmX1234"}, "product_description": {"gtin": "8945123900123", "name": "Organic Cotton Fabric", "model": "OCF-2025"}, "environmental_impact": {"co2": "1", "water": "1", "energy": "1"}}, "Color": "Red"}	\N	\N	[{"id": "12345", "type": "po"}]	[]	urn:uuid:869b9421-3766-44ec-921c-67763f3aaee2	bf0b129edcfc6e915d0ad06977a305a5c26af574e033cd7ba129183adea59276	BATCH20251019-01-BEGQ	\N	f	\N	\N	2025-11-19 08:15:15.311085+00	2025-11-19 08:15:15.311085+00	\N	\N	\N	t	\N	SUPPLIER	\N	\N	\N	\N	\N	\N
45	1	ObjectEvent	GARMENT-001-SUPPLIER-251119-0812	\N	2025-11-19 08:15:15+00	ADD	urn:epcglobal:cbv:bizstep:shipping	urn:epcglobal:cbv:disp:active	"urn:epc:id:sgln:8938501000400.line3"	"urn:epc:id:sgln:undefined"	["urn:epc:id:sgtin:Comapny.prefix"]	{"dpp": {"cost_info": {}, "transport": {}, "use_phase": {"instructions": "Wash at 30°C. Avoid bleach. Air dry for best results."}, "brand_info": {"brand": "GreenTextile Co.", "contact": "contact@greentextile.com"}, "circularity": {}, "composition": {"materials": ["Organic Cotton", "Recycled Polyester"], "percentages": [80, 20], "materials_block": [{"name": "Organic Cotton", "percentage": 80}, {"name": "Recycled Polyester", "percentage": 20}]}, "end_of_life": {"recycle_guideline": "Can be recycled or composted; check local textile recycling."}, "supply_chain": {}, "documentation": {}, "health_safety": {"policy": "Complies with OEKO-TEX 100", "certified_by": "OEKO-TEX Association"}, "quantity_info": {}, "social_impact": {"factory": "GreenTextile Factory", "certifications": [{"name": "Fair Trade Certified", "number": "FT-00221", "issued_by": "Fairtrade International"}, {"name": "GOTS", "number": "GOTS-2024-9987", "issued_by": "Control Union"}]}, "animal_welfare": {"notes": "No animal materials used", "standard": "N/A - Plant-based textile"}, "digital_identity": {"qr": "https://ipfs.io/ipfs/QmX1234", "did": "did:greentextile:cotton12345", "ipfs_cid": "QmX1234"}, "product_description": {"gtin": "8945123900123", "name": "Organic Cotton Fabric", "model": "OCF-2025"}, "environmental_impact": {}}, "Color": "red"}	\N	\N	[{"id": "12345", "type": "po"}]	[]	urn:uuid:104ec0d3-53d7-4d81-9b2e-023a99faf0bc	f7f0a6bac89084498de2042dce058772b4b3ba49940f8d451917c9087a7e82ce	BATCH20251018-01-RUOJ	\N	f	\N	\N	2025-11-19 08:16:38.00208+00	2025-11-19 08:16:38.00208+00	\N	\N	\N	t	\N	SUPPLIER	\N	\N	\N	\N	\N	\N
46	1	ObjectEvent	GARMENT-001-SUPPLIER-251119-0812-MANUFACTURER-251119-0817	\N	2025-11-19 08:18:00+00	ADD	urn:epcglobal:cbv:bizstep:receiving	urn:epcglobal:cbv:disp:active	"urn:epc:id:sgln:8938501000400.line3"	"urn:epc:id:sgln:undefined"	["urn:epc:id:sgtin:Comapny.prefix"]	{"dpp": {"cost_info": {"labor_cost": "1", "transport_cost": "1"}, "transport": {"distance": "1", "co2_per_km": "1"}, "use_phase": {"instructions": "Wash at 30°C. Avoid bleach. Air dry for best results."}, "brand_info": {"brand": "GreenTextile Co.", "contact": "contact@greentextile.com"}, "circularity": {"reusability": "1", "waste_reduction": "1", "recycled_content": "1"}, "composition": {"materials": ["Organic Cotton", "Recycled Polyester"], "percentages": [80, 20], "materials_block": [{"name": "Organic Cotton", "percentage": 80}, {"name": "Recycled Polyester", "percentage": 20}]}, "end_of_life": {"recycle_guideline": "Can be recycled or composted; check local textile recycling."}, "supply_chain": {"tier": "3", "supplier": "3", "updated_at": "3"}, "documentation": {"file": "A", "issued_by": "A"}, "health_safety": {"policy": "Complies with OEKO-TEX 100", "certified_by": "OEKO-TEX Association"}, "quantity_info": {"batch": "1", "weight": "1"}, "social_impact": {"factory": "GreenTextile Factory", "certifications": [{"name": "Fair Trade Certified", "number": "FT-00221", "issued_by": "Fairtrade International"}, {"name": "GOTS", "number": "GOTS-2024-9987", "issued_by": "Control Union"}]}, "animal_welfare": {"notes": "No animal materials used", "standard": "N/A - Plant-based textile"}, "digital_identity": {"qr": "https://ipfs.io/ipfs/QmX1234", "did": "did:greentextile:cotton12345", "ipfs_cid": "QmX1234"}, "product_description": {"gtin": "8945123900123", "name": "Organic Cotton Fabric", "model": "OCF-2025"}, "environmental_impact": {"co2": "1", "water": "1", "energy": "1"}}, "Color": "red"}	\N	\N	[{"id": "12345", "type": "po"}]	[]	urn:uuid:5110e206-c5af-41f2-a7e7-13478d0af870	a36618da3d91c1ab3dd4fe18a36d8b75b1416f642f24b3d71b2b248ebd9abe1e	BATCH20251019-01-BEGQ	\N	f	\N	\N	2025-11-19 08:19:21.008594+00	2025-11-19 08:19:21.008594+00	\N	\N	\N	t	\N	MANUFACTURER	\N	\N	\N	\N	\N	\N
50	1	ObjectEvent	GARMENT-001-SUPPLIER-251119-0812-MANUFACTURER-251119-0817-BRAND-251119-0824	GAR1001	2025-11-19 08:25:09+00	ADD	urn:epcglobal:cbv:bizstep:receiving	urn:epcglobal:cbv:disp:active	"urn:epc:id:sgln:8938501000400.line3"	"urn:epc:id:sgln:undefined"	["urn:epc:id:sgtin:Comapny.prefix"]	{"dpp": {"cost_info": {}, "transport": {"distance": "2", "co2_per_km": "2"}, "use_phase": {"instructions": "Wash at 30°C. Avoid bleach. Air dry for best results."}, "brand_info": {"brand": "GreenTextile Co.", "contact": "contact@greentextile.com"}, "circularity": {"reusability": "20", "waste_reduction": "20", "recycled_content": "20"}, "composition": {"materials": ["Organic Cotton", "Recycled Polyester"], "percentages": [80, 20], "materials_block": [{"name": "Organic Cotton", "percentage": 80}, {"name": "Recycled Polyester", "percentage": 20}]}, "end_of_life": {"recycle_guideline": "Can be recycled or composted; check local textile recycling."}, "supply_chain": {"tier": "4", "supplier": "4", "updated_at": "4"}, "documentation": {"file": "A", "issued_by": "A"}, "health_safety": {"policy": "Complies with OEKO-TEX 100", "certified_by": "OEKO-TEX Association"}, "quantity_info": {"batch": "123456", "weight": "2000"}, "social_impact": {"factory": "GreenTextile Factory", "certifications": [{"name": "Fair Trade Certified", "number": "FT-00221", "issued_by": "Fairtrade International"}, {"name": "GOTS", "number": "GOTS-2024-9987", "issued_by": "Control Union"}]}, "animal_welfare": {"notes": "No animal materials used", "standard": "N/A - Plant-based textile"}, "digital_identity": {"qr": "https://ipfs.io/ipfs/QmX1234", "did": "did:greentextile:cotton12345", "ipfs_cid": "QmX1234"}, "product_description": {"gtin": "8945123900123", "name": "Organic Cotton Fabric", "model": "OCF-2025"}, "environmental_impact": {"co2": "20", "water": "20", "energy": "20"}}, "Color": "Red"}	\N	\N	[{"id": "456789", "type": "po"}]	[]	urn:uuid:b53bf44c-3fb4-41d4-a72c-e6d044b209f3	a15582cc1cd71a32dd08a66fece904ae6c1167745ab972527d9ea19f8284ab2e	BATCH20251019-01-BEGQ	\N	f	\N	\N	2025-11-19 08:26:51.417397+00	2025-11-19 08:26:51.417397+00	\N	\N	\N	t	\N	BRAND	\N	\N	\N	\N	\N	\N
47	1	ObjectEvent	GARMENT-001-SUPPLIER-251119-0812-MANUFACTURER-251119-0817	GAR1001	2025-11-19 08:19:21+00	ADD	urn:epcglobal:cbv:bizstep:manufacturing	urn:epcglobal:cbv:disp:active	"urn:epc:id:sgln:8938501000400.line3"	"urn:epc:id:sgln:undefined"	["urn:epc:id:sgtin:Comapny.prefix"]	{"dpp": {"use_phase": {"instructions": "Wash at 30°C. Avoid bleach. Air dry for best results."}, "brand_info": {"brand": "GreenTextile Co.", "contact": "contact@greentextile.com"}, "composition": {"materials": ["Organic Cotton", "Recycled Polyester"], "percentages": [80, 20], "materials_block": [{"name": "Organic Cotton", "percentage": 80}, {"name": "Recycled Polyester", "percentage": 20}]}, "end_of_life": {"recycle_guideline": "Can be recycled or composted; check local textile recycling."}, "health_safety": {"policy": "Complies with OEKO-TEX 100", "certified_by": "OEKO-TEX Association"}, "social_impact": {"factory": "GreenTextile Factory", "certifications": [{"name": "Fair Trade Certified", "number": "FT-00221", "issued_by": "Fairtrade International"}, {"name": "GOTS", "number": "GOTS-2024-9987", "issued_by": "Control Union"}]}, "animal_welfare": {"notes": "No animal materials used", "standard": "N/A - Plant-based textile"}, "digital_identity": {"qr": "https://ipfs.io/ipfs/QmX1234", "did": "did:greentextile:cotton12345", "ipfs_cid": "QmX1234"}, "product_description": {"gtin": "8945123900123", "name": "Organic Cotton Fabric", "model": "OCF-2025"}}, "Color": "Red"}	\N	\N	[{"id": "N/A", "type": "po"}]	[]	urn:uuid:756008f4-39e6-41c8-8c67-d1872ce065e7	716fddb27352a97ea2b45ca03ca2f51914bd8a644f9f5330b305b6435320ff01	BATCH20251019-01-BEGQ	\N	f	\N	\N	2025-11-19 08:20:29.424526+00	2025-11-19 08:20:29.424526+00	\N	\N	\N	t	\N	MANUFACTURER	\N	\N	\N	\N	\N	\N
48	1	ObjectEvent	GARMENT-001-SUPPLIER-251119-0812-MANUFACTURER-251119-0817	GAR1001	2025-11-19 08:20:29+00	ADD	urn:epcglobal:cbv:bizstep:packing	urn:epcglobal:cbv:disp:active	"urn:epc:id:sgln:8938501000400.line3"	"urn:epc:id:sgln:undefined"	["urn:epc:id:sgtin:Comapny.prefix"]	{"dpp": {"use_phase": {"instructions": "Wash at 30°C. Avoid bleach. Air dry for best results."}, "brand_info": {"brand": "GreenTextile Co.", "contact": "contact@greentextile.com"}, "composition": {"materials": ["Organic Cotton", "Recycled Polyester"], "percentages": [80, 20], "materials_block": [{"name": "Organic Cotton", "percentage": 80}, {"name": "Recycled Polyester", "percentage": 20}]}, "end_of_life": {"recycle_guideline": "Can be recycled or composted; check local textile recycling."}, "health_safety": {"policy": "Complies with OEKO-TEX 100", "certified_by": "OEKO-TEX Association"}, "social_impact": {"factory": "GreenTextile Factory", "certifications": [{"name": "Fair Trade Certified", "number": "FT-00221", "issued_by": "Fairtrade International"}, {"name": "GOTS", "number": "GOTS-2024-9987", "issued_by": "Control Union"}]}, "animal_welfare": {"notes": "No animal materials used", "standard": "N/A - Plant-based textile"}, "digital_identity": {"qr": "https://ipfs.io/ipfs/QmX1234", "did": "did:greentextile:cotton12345", "ipfs_cid": "QmX1234"}, "product_description": {"gtin": "8945123900123", "name": "Organic Cotton Fabric", "model": "OCF-2025"}}, "Color": "red"}	\N	\N	[{"id": "456789", "type": "po"}]	[]	urn:uuid:9001568c-4151-4916-835a-438890cfe681	9114cf138cc4029485f9682c1570db2f201f25d1b8a0103da3f5f1b71ab86eee	BATCH20251018-01-RUOJ	\N	f	\N	\N	2025-11-19 08:21:29.856754+00	2025-11-19 08:21:29.856754+00	\N	\N	\N	t	\N	MANUFACTURER	\N	\N	\N	\N	\N	\N
49	1	ObjectEvent	GARMENT-001-SUPPLIER-251119-0812-MANUFACTURER-251119-0817	GAR1001	2025-11-19 08:21:30+00	ADD	urn:epcglobal:cbv:bizstep:shipping	urn:epcglobal:cbv:disp:active	"urn:epc:id:sgln:8938501000400.line3"	"urn:epc:id:sgln:undefined"	["urn:epc:id:sgtin:Comapny.prefix"]	{"dpp": {"cost_info": {"labor_cost": "N/A", "transport_cost": "N/A"}, "transport": {"distance": "2", "co2_per_km": "2"}, "use_phase": {"instructions": "Wash at 30°C. Avoid bleach. Air dry for best results."}, "brand_info": {"brand": "GreenTextile Co.", "contact": "contact@greentextile.com"}, "circularity": {"reusability": "20", "waste_reduction": "20", "recycled_content": "20"}, "composition": {"materials": ["Organic Cotton", "Recycled Polyester"], "percentages": [80, 20], "materials_block": [{"name": "Organic Cotton", "percentage": 80}, {"name": "Recycled Polyester", "percentage": 20}]}, "end_of_life": {"recycle_guideline": "Can be recycled or composted; check local textile recycling."}, "supply_chain": {"tier": "3", "supplier": "3", "updated_at": "3"}, "documentation": {"file": "A", "issued_by": "A"}, "health_safety": {"policy": "Complies with OEKO-TEX 100", "certified_by": "OEKO-TEX Association"}, "quantity_info": {}, "social_impact": {"factory": "GreenTextile Factory", "certifications": [{"name": "Fair Trade Certified", "number": "FT-00221", "issued_by": "Fairtrade International"}, {"name": "GOTS", "number": "GOTS-2024-9987", "issued_by": "Control Union"}]}, "animal_welfare": {"notes": "No animal materials used", "standard": "N/A - Plant-based textile"}, "digital_identity": {"qr": "https://ipfs.io/ipfs/QmX1234", "did": "did:greentextile:cotton12345", "ipfs_cid": "QmX1234"}, "product_description": {"gtin": "8945123900123", "name": "Organic Cotton Fabric", "model": "OCF-2025"}, "environmental_impact": {"co2": "20", "water": "20", "energy": "20"}}, "Color": "red"}	\N	\N	[{"id": "456789", "type": "po"}]	[]	urn:uuid:37b12c65-e751-4fe9-a67a-cea156be5f8f	637ca66595f458d60d7bac9916ffa8f600efaceed0c2b22a9b741396ed0751c5	BATCH20251019-01-BEGQ	\N	f	\N	\N	2025-11-19 08:23:46.277887+00	2025-11-19 08:23:46.277887+00	\N	\N	\N	t	\N	MANUFACTURER	\N	\N	\N	\N	\N	\N
51	1	ObjectEvent	GARMENT-001-SUPPLIER-251119-0812-MANUFACTURER-251119-0817-BRAND-251119-0824	\N	2025-11-21 03:57:25+00	ADD	urn:epcglobal:cbv:bizstep:packing	urn:epcglobal:cbv:disp:active	"urn:epc:id:sgln:8938501000400.line3"	"urn:epc:id:sgln:undefined"	["urn:epc:id:sgtin:Comapny.prefix"]	{"dpp": {"cost_info": {"labor_cost": "1", "transport_cost": "1"}, "transport": {"distance": "1", "co2_per_km": "1"}, "use_phase": {"instructions": "Wash at 30°C. Avoid bleach. Air dry for best results."}, "brand_info": {"brand": "GreenTextile Co.", "contact": "contact@greentextile.com"}, "circularity": {"reusability": "1", "waste_reduction": "1", "recycled_content": "1"}, "composition": {"materials": ["Organic Cotton", "Recycled Polyester"], "percentages": [80, 20], "materials_block": [{"name": "Organic Cotton", "percentage": 80}, {"name": "Recycled Polyester", "percentage": 20}]}, "end_of_life": {"recycle_guideline": "Can be recycled or composted; check local textile recycling."}, "supply_chain": {"tier": "1", "supplier": "1", "updated_at": "1"}, "documentation": {"file": "1", "issued_by": "1"}, "health_safety": {"policy": "Complies with OEKO-TEX 100", "certified_by": "OEKO-TEX Association"}, "quantity_info": {"batch": "1", "weight": "1"}, "social_impact": {"factory": "GreenTextile Factory", "certifications": [{"name": "Fair Trade Certified", "number": "FT-00221", "issued_by": "Fairtrade International"}, {"name": "GOTS", "number": "GOTS-2024-9987", "issued_by": "Control Union"}]}, "animal_welfare": {"notes": "No animal materials used", "standard": "N/A - Plant-based textile"}, "digital_identity": {"qr": "https://ipfs.io/ipfs/QmX1234", "did": "did:greentextile:cotton12345", "ipfs_cid": "QmX1234"}, "product_description": {"gtin": "8945123900123", "name": "Organic Cotton Fabric", "model": "OCF-2025"}, "environmental_impact": {"co2": "1", "water": "1", "energy": "1"}}, "Color": "red"}	\N	\N	[{"id": "12345", "type": "po"}]	[]	urn:uuid:ee2ac231-31c1-4077-8d74-ce9b96136ead	5877a996a2dbf16965cf597948e45ee444c463b17c4cc45edacf1d5123acd2e4	BATCH20251019-01-BEGQ	\N	f	\N	\N	2025-11-21 04:11:10.329144+00	2025-11-21 04:11:10.329144+00	\N	\N	\N	t	\N	ADMIN	\N	\N	\N	\N	\N	\N
52	1	AssociationEvent	GARMENT-001-SUPPLIER-251119-0812-MANUFACTURER-251119-0817-BRAND-251119-0824	GAR1001	2025-11-21 05:15:03+00	ADD	urn:epcglobal:cbv:bizstep:storing	urn:epcglobal:cbv:disp:active	"urn:epc:id:sgln:8938501000400.line3"	"urn:epc:id:sgln:8938501000400.line1"	["urn:epc:id:sgtin:Comapny.prefix"]	{"dpp": {"cost_info": {"labor_cost": "1", "transport_cost": "1"}, "transport": {"distance": "1", "co2_per_km": "1"}, "use_phase": {"instructions": "Wash at 30°C. Avoid bleach. Air dry for best results."}, "brand_info": {"brand": "GreenTextile Co.", "contact": "contact@greentextile.com"}, "circularity": {"reusability": "1", "waste_reduction": "1", "recycled_content": "1"}, "composition": {"materials": ["Organic Cotton", "Recycled Polyester"], "percentages": [80, 20], "materials_block": [{"name": "Organic Cotton", "percentage": 80}, {"name": "Recycled Polyester", "percentage": 20}]}, "end_of_life": {"recycle_guideline": "Can be recycled or composted; check local textile recycling."}, "supply_chain": {"tier": "1", "supplier": "1", "updated_at": "1"}, "documentation": {"file": "1", "issued_by": "1"}, "health_safety": {"policy": "Complies with OEKO-TEX 100", "certified_by": "OEKO-TEX Association"}, "quantity_info": {"batch": "1", "weight": "1"}, "social_impact": {"factory": "GreenTextile Factory", "certifications": [{"name": "Fair Trade Certified", "number": "FT-00221", "issued_by": "Fairtrade International"}, {"name": "GOTS", "number": "GOTS-2024-9987", "issued_by": "Control Union"}]}, "animal_welfare": {"notes": "No animal materials used", "standard": "N/A - Plant-based textile"}, "digital_identity": {"qr": "https://ipfs.io/ipfs/QmX1234", "did": "did:greentextile:cotton12345", "ipfs_cid": "QmX1234"}, "product_description": {"gtin": "8945123900123", "name": "Organic Cotton Fabric", "model": "OCF-2025"}, "environmental_impact": {"co2": "1", "water": "1", "energy": "1"}}, "Color": "red"}	\N	\N	[{"id": "12345", "type": "po"}]	[]	urn:uuid:f82c2d8a-c272-4cf2-aec9-dd133c2aa4a5	e1b27ffd5a87639d8c442df766f1de46402d72a105ee0fbf2820a7c7a48f4ad6	BATCH20251019-01-BEGQ	\N	f	\N	\N	2025-11-21 05:17:34.417857+00	2025-11-21 05:17:34.417857+00	\N	\N	\N	t	\N	ADMIN	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.events (id, batch_code, product_code, event_time, biz_step, disposition, data, tenant_id) FROM stdin;
\.


--
-- Data for Name: fabric_events; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.fabric_events (id, tx_id, block_number, chaincode_id, event_name, payload, status, ts, tenant_id) FROM stdin;
\.


--
-- Data for Name: farms; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.farms (id, tenant_id, name, code, gln, location, size_ha, certification, contact_info, created_at, farm_type, status, extra_data) FROM stdin;
3	1	Binh Duong Cotton Farm	FARM-BD-001	8938501000001	{"country": "VN", "province": "Binh Duong"}	120.5	{"GOTS": true, "Organic": true}	null	2025-10-27 06:39:15.725246+00	cotton	active	{}
4	1	Phan Minh Nhat	1234	1111	{"country": "Vietnam", "district": "qqqq", "latitude": 22222222, "province": "An Giang", "longitude": 2222222}	\N	{"issuer": "eeee", "standard": "eeeee", "valid_until": "2025-10-15"}	{"email": "g@gg.com", "phone": "11111111", "person": "eeeeee"}	2025-10-27 09:25:51.687656+00	er	active	{}
\.


--
-- Data for Name: materials; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.materials (id, tenant_id, name, scientific_name, stages, dpp_notes, created_at, updated_at) FROM stdin;
1	1	Cotton	Gossypium hirsutum	["Harvesting", "Ginning", "Cleaning", "Spinning", "Weaving", "Garment Production"]	GOTS, OCS	2025-10-31 16:37:41.124601	2025-10-31 16:37:41.124601
2	1	Bamboo	Bambusa vulgaris	["Cutting", "Crushing & Soaking", "Retting", "Spinning", "Weaving", "Garment Production"]	FSC, bio-based 99%	2025-10-31 16:37:41.124601	2025-10-31 16:37:41.124601
3	1	Piñatex (Pineapple Fiber)	Ananas comosus (leaf)	["Leaf Collection", "Decortication", "Washing & Drying", "Spinning", "Nonwoven Fabric", "Cutting & Sewing"]	Agro-waste, vegan	2025-10-31 16:37:41.124601	2025-10-31 16:37:41.124601
4	1	Banana Fiber	Musa textilis (pseudo stem)	["Stem Cutting", "Decortication", "Boiling & Scraping", "Spinning", "Weaving", "Garment Production"]	Agro-waste, compostable	2025-10-31 16:37:41.124601	2025-10-31 16:37:41.124601
5	1	Jute	Corchorus capsularis	["Harvesting", "Water Retting", "Fiber Separation", "Spinning", "Sack Weaving", "Sewing"]	Biodegradable	2025-10-31 16:37:41.124601	2025-10-31 16:37:41.124601
6	1	Ramie	Boehmeria nivea	["Harvesting", "Decortication", "Degumming", "Spinning", "Weaving", "Sewing"]	High strength	2025-10-31 16:37:41.124601	2025-10-31 16:37:41.124601
7	1	Silk	Bombyx mori	["Silkworm Rearing", "Cocoon Collection", "Boiling", "Reeling", "Silk Weaving", "Garment Production"]	GOTS Silk	2025-10-31 16:37:41.124601	2025-10-31 16:37:41.124601
8	1	Wool	Ovis aries	["Shearing", "Washing", "Carding", "Spinning", "Knitting", "Garment Production"]	RWS, ZQ Wool	2025-10-31 16:37:41.124601	2025-10-31 16:37:41.124601
9	1	Camel Hair	Camelus	["Shearing", "Washing", "Carding", "Spinning", "Weaving", "Garment Production"]	Animal welfare	2025-10-31 16:37:41.124601	2025-10-31 16:37:41.124601
10	1	Cashmere	Capra hircus	["Combing", "Washing", "Dehairing", "Spinning", "Weaving", "Garment Production"]	SFA Certified	2025-10-31 16:37:41.124601	2025-10-31 16:37:41.124601
11	1	Viscose (Rayon)	Wood / Bamboo Pulp	["Wood Chipping", "Xanthation", "Fiber Extrusion", "Washing", "Spinning", "Weaving"]	FSC, CanopyStyle	2025-10-31 16:37:41.124601	2025-10-31 16:37:41.124601
12	1	Lyocell (Tencel)	Eucalyptus Wood	["Dissolving Pulp", "Extrusion", "Washing", "Spinning", "Weaving", "Garment Production"]	Closed-loop, Lenzing	2025-10-31 16:37:41.124601	2025-10-31 16:37:41.124601
13	1	Modal	Beech Wood	["Dissolving Pulp", "Extrusion", "Washing", "Spinning", "Weaving", "Garment Production"]	Lenzing Modal	2025-10-31 16:37:41.124601	2025-10-31 16:37:41.124601
14	1	Recycled Polyester (rPET)	Plastic Bottles	["Bottle Collection", "Crushing", "Melting", "Fiber Extrusion", "Spinning", "Weaving"]	GRS, rPET certified	2025-10-31 16:37:41.124601	2025-10-31 16:37:41.124601
15	1	Recycled Nylon (Econyl)	Fishing Nets	["Collection", "Depolymerization", "Polymerization", "Fiber Extrusion", "Spinning", "Weaving"]	GRS, Ocean waste	2025-10-31 16:37:41.124601	2025-10-31 16:37:41.124601
16	1	Coir Fiber	Coconut Husk	["Husk Separation", "Water Retting", "Fiber Extraction", "Spinning", "Mat Weaving"]	Agro-waste	2025-10-31 16:37:41.124601	2025-10-31 16:37:41.124601
17	1	Lotus Fiber	Nelumbo nucifera (stem)	["Stem Cutting", "Manual Fiber Extraction", "Washing", "Spinning", "Weaving", "Garment Production"]	Handmade, VN origin	2025-10-31 16:37:41.124601	2025-10-31 16:37:41.124601
18	1	Pine Leaf Fiber	Ananas comosus	["Leaf Collection", "Fiber Extraction", "Washing", "Spinning", "Weaving", "Garment Production"]	Piñafelt	2025-10-31 16:37:41.124601	2025-10-31 16:37:41.124601
19	1	Corn Fiber (PLA)	Zea mays	["Fermentation", "Polymerization", "Fiber Extrusion", "Spinning", "Weaving", "Garment Production"]	Compostable	2025-10-31 16:37:41.124601	2025-10-31 16:37:41.124601
20	1	Coffee Yarn (S.Cafe)	Coffee Grounds	["Drying", "Polymer Mixing", "Fiber Extrusion", "Spinning", "Weaving", "Garment Production"]	Upcycled	2025-10-31 16:37:41.124601	2025-10-31 16:37:41.124601
\.


--
-- Data for Name: polygon_abi; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.polygon_abi (id, name, abi, created_at, tenant_id) FROM stdin;
\.


--
-- Data for Name: polygon_anchors; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.polygon_anchors (id, tx_hash, anchor_type, ref_id, status, ts, meta, tenant_id, network, block_number, is_active, dpp_passport_id, created_at) FROM stdin;
1	0x09ec771dd984b8f8db24948b8ad358ea88a1e93d3c279d6249c960f591773d37	epcis_batch	LOT-2025-10	CONFIRMED	2025-10-20 07:48:47.190986	{"root_hash": "eb71d14dd8881ea2d7faf1b4b76f185ca3da304cfd12bb6208e4a5e0cc41ba57"}	\N	\N	\N	t	\N	2025-10-26 18:15:42.828837+00
2	0x09ec771dd984b8f8db24948b8ad358ea88a1e93d3c279d6249c960f591773d37	epcis_batch	LOT-2025-10	CONFIRMED	2025-10-21 09:29:59.059583	{"root_hash": "eb71d14dd8881ea2d7faf1b4b76f185ca3da304cfd12bb6208e4a5e0cc41ba57"}	\N	\N	\N	t	\N	2025-10-26 18:15:42.828837+00
\.


--
-- Data for Name: polygon_logs; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.polygon_logs (id, tx_hash, method, params, result, tenant_id) FROM stdin;
1	0x09ec771dd984b8f8db24948b8ad358ea88a1e93d3c279d6249c960f591773d37	storeProof	{"root_hash": "eb71d14dd8881ea2d7faf1b4b76f185ca3da304cfd12bb6208e4a5e0cc41ba57", "batch_code": "LOT-2025-10"}	{"ts": "2025-10-20T07:48:47.202852+00:00", "tx_hash": "0x09ec771dd984b8f8db24948b8ad358ea88a1e93d3c279d6249c960f591773d37", "block_number": 1159546}	\N
2	0x09ec771dd984b8f8db24948b8ad358ea88a1e93d3c279d6249c960f591773d37	storeProof	{"root_hash": "eb71d14dd8881ea2d7faf1b4b76f185ca3da304cfd12bb6208e4a5e0cc41ba57", "batch_code": "LOT-2025-10"}	{"ts": "2025-10-21T09:29:59.102966+00:00", "tx_hash": "0x09ec771dd984b8f8db24948b8ad358ea88a1e93d3c279d6249c960f591773d37", "block_number": 1159546}	\N
\.


--
-- Data for Name: polygon_subscriptions; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.polygon_subscriptions (id, anchor_id, event_name, callback_url, tenant_id) FROM stdin;
\.


--
-- Data for Name: portals; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.portals (id, name, url, tenant_id) FROM stdin;
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.products (id, code, name, category, created_at, tenant_id, material_id, brand, gtin) FROM stdin;
1	GAR1002	Áo Sơ Mi Linen	Garment	2025-10-29 02:50:40.440494	1	\N	\N	\N
2	GAR1003	Quần Jeans Recycled Denim	Garment	2025-10-29 02:50:40.440494	1	\N	\N	\N
3	GAR1004	Áo Khoác Gió RPET	Outerwear	2025-10-29 02:50:40.440494	1	\N	\N	\N
4	GAR1005	Giày Sneaker Canvas	Footwear	2025-10-29 02:50:40.440494	1	\N	\N	\N
6	GAR1007	Mũ Len Wool RWS	Accessories	2025-10-29 02:50:40.440494	1	\N	\N	\N
7	GAR1008	Khăn Quàng Cổ Bamboo Fiber	Accessories	2025-10-29 02:50:40.440494	1	\N	\N	\N
8	GAR1009	Áo Polo Recycled Polyester	Garment	2025-10-29 02:50:40.440494	1	\N	\N	\N
9	GAR1010	Quần Short Hemp	Garment	2025-10-29 02:50:40.440494	1	\N	\N	\N
1001	GAR1001	Áo Thun Cotton Org	Garment	2025-10-29 02:44:30.587681	1	1	\N	\N
5	GAR1006	Túi Tote Organic Cotton	Accessories	2025-10-29 02:50:40.440494	1	1	\N	\N
\.


--
-- Data for Name: rbac_permissions; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.rbac_permissions (id, name, code, role_id, tenant_id) FROM stdin;
1	full_access	superadmin_all	1	1
2	manage_tenant	admin_crud	2	1
3	data_ops	data_staff_rw	3	1
4	supplier_readonly	supplier_read	4	1
5	Full Access	ALL_PRIVILEGES	1	1
\.


--
-- Data for Name: rbac_role_bindings; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.rbac_role_bindings (id, tenant_id, user_id, role_id) FROM stdin;
1	1	1	2
2	1	3	1
\.


--
-- Data for Name: rbac_roles; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.rbac_roles (id, name, tenant_id, description, is_active, created_at) FROM stdin;
1	superadmin	1	System-wide administrator	t	2025-10-27 15:24:47.653916+00
2	admin	1	Tenant administrator	t	2025-10-27 15:24:47.653916+00
3	data_staff	1	Data operator	t	2025-10-27 15:24:47.653916+00
4	supplier	1	Supplier user	t	2025-10-27 15:24:47.653916+00
\.


--
-- Data for Name: rbac_scopes; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.rbac_scopes (id, tenant_id, resource, action, constraint_expr) FROM stdin;
1	1	*	*	{}
2	1	products	read	{"tenant_id": "${tenant_id}"}
3	1	products	create	{"tenant_id": "${tenant_id}"}
4	1	products	update	{"tenant_id": "${tenant_id}"}
5	1	products	delete	{"tenant_id": "${tenant_id}"}
6	1	batches	read	{"tenant_id": "${tenant_id}"}
7	1	batches	create	{"tenant_id": "${tenant_id}"}
8	1	batches	update	{"tenant_id": "${tenant_id}"}
9	1	batches	delete	{"tenant_id": "${tenant_id}"}
10	1	suppliers	read	{"tenant_id": "${tenant_id}"}
11	1	suppliers	create	{"tenant_id": "${tenant_id}"}
12	1	suppliers	update	{"tenant_id": "${tenant_id}"}
13	1	suppliers	delete	{"tenant_id": "${tenant_id}"}
16	1	users	*	{}
17	1	configs	*	{}
18	1	roles	*	{}
19	1	scopes	*	{}
20	1	users	read	{}
21	1	configs	read	{}
\.


--
-- Data for Name: sensor_events; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.sensor_events (id, epcis_event_id, sensor_meta, sensor_reports, tenant_id) FROM stdin;
\.


--
-- Data for Name: split_policy; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.split_policy (role, mode) FROM stdin;
farm	FULL
supplier	FULL
manufacturer	SPLIT
brand	SPLIT
\.


--
-- Data for Name: suppliers; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.suppliers (id, tenant_id, code, name, country, contact_email, phone, address, factory_location, certification, user_id, created_at) FROM stdin;
6	1	SUP-VN001	Coton Vietnam Co., Ltd.	VN	contact@cotonvn.com	+84 28 3945 1122	Lot B, Road 3, Tan Binh Industrial Park, Ho Chi Minh City	Tan Binh, HCMC	{"GOTS": {"status": "Certified", "expiry_date": "2026-05-10"}, "ISO9001": {"status": "Certified", "cert_no": "VN-ISO-2024-9912"}, "OekoTex": {"status": "Certified", "expiry_date": "2025-11-30"}}	1	2025-10-29 07:07:48.2758
7	\N	SUP-456	Phan Minh Nhat	VN	huynhat2gmail.com	123456789	37/3 Thien Ho Duong, Ward 1, Go Vap	TB	{}	\N	2025-10-30 06:49:50.318947
8	\N	SUP-123456	Phan Minh Nhat	VN	nhả@gmail.com	123456	37/3 Thien Ho Duong, Ward 1, Go Vap	TB	{}	\N	2025-10-30 06:51:04.54805
10	1	SUP-2468023456	Toàn Phan	VN	toan@gmail.com	0988888888	Long Hưng	Biên Hòa	{"GOTS": {"status": "Certified", "expiry_date": "2026-05-10"}, "ISO9001": {"status": "Certified", "cert_no": "VN-ISO-2024-9912"}, "OekoTex": {"status": "Certified", "expiry_date": "2025-11-30"}}	9	2025-10-30 07:05:44.11893
\.


--
-- Data for Name: tenants; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.tenants (id, name, code, created_at, email, phone, address, is_active) FROM stdin;
1	Global Trace Ltd	globaltrace	2025-10-16 09:17:13.81165	admin@globaltrace.com	+84-900-000-001	H├á Nß╗Öi, Viß╗çt Nam	t
2	EcoChain Pte Ltd	ecochain	2025-10-16 09:17:13.81165	contact@ecochain.io	+65-900-000-002	Singapore	t
3	Smart Textile Corp	smarttextile	2025-10-16 09:17:13.81165	support@smarttextile.com	+49-900-000-003	Berlin, Germany	t
4	AgriChain Co.	agrichain	2025-10-16 09:17:13.81165	info@agrichain.vn	+84-912-345-678	Cß║ºn Th╞í, Viß╗çt Nam	t
5	GreenFoot Ltd	greenfoot	2025-10-16 09:17:13.81165	hello@greenfoot.org	+81-555-8888	Tokyo, Japan	f
\.


--
-- Data for Name: ui_menus; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.ui_menus (id, label, path, role_id, tenant_id) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: trace
--

COPY public.users (id, tenant_id, username, name, email, role, password_hash, created_at, is_active) FROM stdin;
2	1	operator1	Operator One	operator1@example.com	operator	$2b$12$LYTteHkAAX5NiTlZvDX9n.22UcJ6xmtKZtkPrSvnWSM.u/hdLKhdK	2025-10-16 15:42:41.831985	t
3	1	superadmin	Super Administrator	superadmin@example.com	superadmin	$2b$12$n1C84XGDugatRxtq4xkiau01zOi4ra.jgTZTU1m7BKjKwQ7BBgI0O	2025-10-27 16:26:52.099344	t
6	1	huynhat812011	Phan Minh Toàn	huynhat@gmail.com	data_staff	$2b$12$E4E0AinPDKvelK8TkqUp2.bLl3h13fubr0nmkvCzMBfsDqlsSV3Zq	2025-10-28 03:30:54.192428	t
9	1	huynhat81	Phan Minh Nhật	huynhat81@gmail.com	supplier	$2b$12$zx1Z5fM0U6OEm4.ykgKv0uhHzKLP7sCRNH2b3i/cE57T5vbn9AJYy	2025-10-28 09:26:55.034001	t
11	1	supplier01	Minh Quân	hoanghuongngannn@gmail.com	supplier	$2b$12$3dfUZAFyLjp0s1Sde0SH1uPx9JEpbUvKPmrXQWvTp0ivaj8Y9vaCa	2025-11-04 14:55:22.38595	t
12	1	farm01	Nhat Quynh	nhu.nguyentm06@gmail.com	farm	$2b$12$df6oEhmRe5GzZmiMMlwmeuq4qr4y5X/KpNG7EXKoQyyu1/PKUiUtK	2025-11-04 15:00:21.860692	t
1	1	admin	Admin	admin@example.com	admin	$2b$12$4.Xo06dacNkai65pnTBoJOC18TTxaoveFsUq4S7ZoBBk2yTkq73Ym	2025-10-16 09:22:54.225629	t
13	1	manufacturer01	Nguyen Thanh Nhan	nttrungg205@gmail.com	manufacturer	$2b$12$Eev2SVPZ7Ig1rSZZ.ZnDoOkceHwpBpeqaBgUDsde9BuZy0MN93s3y	2025-11-13 02:44:49.482714	t
14	1	brand01	Ho Yen Oanh	hoaithuong3648@gmail.com	brand	$2b$12$3dxRiG6B2uRlycHE/nIKW.dMMJt5gxam74VONCRTJzV9umFZf8NKO	2025-11-13 05:35:54.464225	t
\.


--
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.audit_logs_id_seq', 3201, true);


--
-- Name: batch_clone_audit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.batch_clone_audit_id_seq', 7, true);


--
-- Name: batch_lineage_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.batch_lineage_id_seq', 1, false);


--
-- Name: batch_links_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.batch_links_id_seq', 2, true);


--
-- Name: batch_usage_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.batch_usage_log_id_seq', 1, true);


--
-- Name: batch_usages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.batch_usages_id_seq', 8, true);


--
-- Name: batches_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.batches_id_seq', 34, true);


--
-- Name: blockchain_anchors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.blockchain_anchors_id_seq', 2, true);


--
-- Name: blockchain_proofs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.blockchain_proofs_id_seq', 36, true);


--
-- Name: brands_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.brands_id_seq', 1, false);


--
-- Name: compliance_results_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.compliance_results_id_seq', 1, false);


--
-- Name: configs_blockchain_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.configs_blockchain_id_seq', 47, true);


--
-- Name: credentials_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.credentials_id_seq', 1, false);


--
-- Name: customers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.customers_id_seq', 1, false);


--
-- Name: customs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.customs_id_seq', 1, false);


--
-- Name: data_sharing_agreements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.data_sharing_agreements_id_seq', 1, false);


--
-- Name: documents_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.documents_id_seq', 3, true);


--
-- Name: domains_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.domains_id_seq', 1, false);


--
-- Name: dpp_passports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.dpp_passports_id_seq', 1, false);


--
-- Name: dpp_templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.dpp_templates_id_seq', 15, true);


--
-- Name: emissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.emissions_id_seq', 1, false);


--
-- Name: epcis_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.epcis_events_id_seq', 52, true);


--
-- Name: events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.events_id_seq', 1, false);


--
-- Name: fabric_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.fabric_events_id_seq', 1, false);


--
-- Name: farms_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.farms_id_seq', 4, true);


--
-- Name: materials_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.materials_id_seq', 20, true);


--
-- Name: polygon_abi_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.polygon_abi_id_seq', 1, false);


--
-- Name: polygon_anchors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.polygon_anchors_id_seq', 2, true);


--
-- Name: polygon_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.polygon_logs_id_seq', 2, true);


--
-- Name: polygon_subscriptions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.polygon_subscriptions_id_seq', 1, false);


--
-- Name: portals_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.portals_id_seq', 1, false);


--
-- Name: products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.products_id_seq', 9, true);


--
-- Name: rbac_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.rbac_permissions_id_seq', 5, true);


--
-- Name: rbac_role_bindings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.rbac_role_bindings_id_seq', 2, true);


--
-- Name: rbac_roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.rbac_roles_id_seq', 5, true);


--
-- Name: rbac_scopes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.rbac_scopes_id_seq', 23, true);


--
-- Name: sensor_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.sensor_events_id_seq', 1, false);


--
-- Name: suppliers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.suppliers_id_seq', 10, true);


--
-- Name: tenants_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.tenants_id_seq', 5, true);


--
-- Name: ui_menus_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.ui_menus_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trace
--

SELECT pg_catalog.setval('public.users_id_seq', 14, true);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: batch_clone_audit batch_clone_audit_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batch_clone_audit
    ADD CONSTRAINT batch_clone_audit_pkey PRIMARY KEY (id);


--
-- Name: batch_lineage batch_lineage_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batch_lineage
    ADD CONSTRAINT batch_lineage_pkey PRIMARY KEY (id);


--
-- Name: batch_links batch_links_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batch_links
    ADD CONSTRAINT batch_links_pkey PRIMARY KEY (id);


--
-- Name: batch_usage_log batch_usage_log_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batch_usage_log
    ADD CONSTRAINT batch_usage_log_pkey PRIMARY KEY (id);


--
-- Name: batch_usages batch_usages_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batch_usages
    ADD CONSTRAINT batch_usages_pkey PRIMARY KEY (id);


--
-- Name: batches batches_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batches
    ADD CONSTRAINT batches_pkey PRIMARY KEY (id);


--
-- Name: blockchain_anchors blockchain_anchors_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.blockchain_anchors
    ADD CONSTRAINT blockchain_anchors_pkey PRIMARY KEY (id);


--
-- Name: blockchain_proofs blockchain_proofs_batch_code_uniq; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.blockchain_proofs
    ADD CONSTRAINT blockchain_proofs_batch_code_uniq UNIQUE (batch_code);


--
-- Name: blockchain_proofs blockchain_proofs_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.blockchain_proofs
    ADD CONSTRAINT blockchain_proofs_pkey PRIMARY KEY (id);


--
-- Name: brands brands_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.brands
    ADD CONSTRAINT brands_pkey PRIMARY KEY (id);


--
-- Name: compliance_results compliance_results_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.compliance_results
    ADD CONSTRAINT compliance_results_pkey PRIMARY KEY (id);


--
-- Name: configs_blockchain configs_blockchain_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.configs_blockchain
    ADD CONSTRAINT configs_blockchain_pkey PRIMARY KEY (id);


--
-- Name: credentials credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.credentials
    ADD CONSTRAINT credentials_pkey PRIMARY KEY (id);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);


--
-- Name: customs customs_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.customs
    ADD CONSTRAINT customs_pkey PRIMARY KEY (id);


--
-- Name: data_sharing_agreements data_sharing_agreements_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.data_sharing_agreements
    ADD CONSTRAINT data_sharing_agreements_pkey PRIMARY KEY (id);


--
-- Name: documents documents_file_hash_key; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_file_hash_key UNIQUE (file_hash);


--
-- Name: documents documents_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_pkey PRIMARY KEY (id);


--
-- Name: domains domains_code_key; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.domains
    ADD CONSTRAINT domains_code_key UNIQUE (code);


--
-- Name: domains domains_name_key; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.domains
    ADD CONSTRAINT domains_name_key UNIQUE (name);


--
-- Name: domains domains_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.domains
    ADD CONSTRAINT domains_pkey PRIMARY KEY (id);


--
-- Name: dpp_passports dpp_passports_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.dpp_passports
    ADD CONSTRAINT dpp_passports_pkey PRIMARY KEY (id);


--
-- Name: dpp_templates dpp_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.dpp_templates
    ADD CONSTRAINT dpp_templates_pkey PRIMARY KEY (id);


--
-- Name: emissions emissions_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.emissions
    ADD CONSTRAINT emissions_pkey PRIMARY KEY (id);


--
-- Name: epcis_events epcis_events_event_hash_key; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.epcis_events
    ADD CONSTRAINT epcis_events_event_hash_key UNIQUE (event_hash);


--
-- Name: epcis_events epcis_events_event_id_key; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.epcis_events
    ADD CONSTRAINT epcis_events_event_id_key UNIQUE (event_id);


--
-- Name: epcis_events epcis_events_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.epcis_events
    ADD CONSTRAINT epcis_events_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: fabric_events fabric_events_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.fabric_events
    ADD CONSTRAINT fabric_events_pkey PRIMARY KEY (id);


--
-- Name: farms farms_code_key; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.farms
    ADD CONSTRAINT farms_code_key UNIQUE (code);


--
-- Name: farms farms_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.farms
    ADD CONSTRAINT farms_pkey PRIMARY KEY (id);


--
-- Name: materials materials_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_pkey PRIMARY KEY (id);


--
-- Name: polygon_abi polygon_abi_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.polygon_abi
    ADD CONSTRAINT polygon_abi_pkey PRIMARY KEY (id);


--
-- Name: polygon_anchors polygon_anchors_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.polygon_anchors
    ADD CONSTRAINT polygon_anchors_pkey PRIMARY KEY (id);


--
-- Name: polygon_logs polygon_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.polygon_logs
    ADD CONSTRAINT polygon_logs_pkey PRIMARY KEY (id);


--
-- Name: polygon_subscriptions polygon_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.polygon_subscriptions
    ADD CONSTRAINT polygon_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: portals portals_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.portals
    ADD CONSTRAINT portals_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: rbac_permissions rbac_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.rbac_permissions
    ADD CONSTRAINT rbac_permissions_pkey PRIMARY KEY (id);


--
-- Name: rbac_role_bindings rbac_role_bindings_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.rbac_role_bindings
    ADD CONSTRAINT rbac_role_bindings_pkey PRIMARY KEY (id);


--
-- Name: rbac_roles rbac_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.rbac_roles
    ADD CONSTRAINT rbac_roles_pkey PRIMARY KEY (id);


--
-- Name: rbac_scopes rbac_scopes_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.rbac_scopes
    ADD CONSTRAINT rbac_scopes_pkey PRIMARY KEY (id);


--
-- Name: sensor_events sensor_events_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.sensor_events
    ADD CONSTRAINT sensor_events_pkey PRIMARY KEY (id);


--
-- Name: split_policy split_policy_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.split_policy
    ADD CONSTRAINT split_policy_pkey PRIMARY KEY (role);


--
-- Name: suppliers suppliers_code_key; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_code_key UNIQUE (code);


--
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (id);


--
-- Name: tenants tenants_code_key; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_code_key UNIQUE (code);


--
-- Name: tenants tenants_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_pkey PRIMARY KEY (id);


--
-- Name: ui_menus ui_menus_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.ui_menus
    ADD CONSTRAINT ui_menus_pkey PRIMARY KEY (id);


--
-- Name: blockchain_proofs uq_blockchain_batch; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.blockchain_proofs
    ADD CONSTRAINT uq_blockchain_batch UNIQUE (batch_code);


--
-- Name: rbac_roles uq_roles_tenant_name; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.rbac_roles
    ADD CONSTRAINT uq_roles_tenant_name UNIQUE (tenant_id, name);


--
-- Name: rbac_scopes uq_scopes_tenant_resource_action; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.rbac_scopes
    ADD CONSTRAINT uq_scopes_tenant_resource_action UNIQUE (tenant_id, resource, action);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: credentials ux_credentials_tenant_hash; Type: CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.credentials
    ADD CONSTRAINT ux_credentials_tenant_hash UNIQUE (tenant_id, hash_hex);


--
-- Name: idx_batch_lineage_child; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_batch_lineage_child ON public.batch_lineage USING btree (child_batch_id);


--
-- Name: idx_batch_lineage_parent; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_batch_lineage_parent ON public.batch_lineage USING btree (parent_batch_id);


--
-- Name: idx_batch_links_child; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_batch_links_child ON public.batch_links USING btree (child_batch_id);


--
-- Name: idx_batch_links_parent; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_batch_links_parent ON public.batch_links USING btree (parent_batch_id);


--
-- Name: idx_batches_origin_farm; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_batches_origin_farm ON public.batches USING btree (origin_farm_id);


--
-- Name: idx_batches_parent_batch; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_batches_parent_batch ON public.batches USING btree (parent_batch_id);


--
-- Name: idx_batches_tenant; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_batches_tenant ON public.batches USING btree (tenant_id);


--
-- Name: idx_batches_tenant_id; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_batches_tenant_id ON public.batches USING btree (tenant_id);


--
-- Name: idx_blockchain_status; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_blockchain_status ON public.blockchain_proofs USING btree (status);


--
-- Name: idx_blockchain_tenant_batch; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_blockchain_tenant_batch ON public.blockchain_proofs USING btree (tenant_id, batch_code);


--
-- Name: idx_blockchain_txhash; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_blockchain_txhash ON public.blockchain_proofs USING btree (tx_hash);


--
-- Name: idx_configs_blockchain_tenant; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_configs_blockchain_tenant ON public.configs_blockchain USING btree (tenant_id);


--
-- Name: idx_configs_blockchain_tenant_network; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_configs_blockchain_tenant_network ON public.configs_blockchain USING btree (tenant_id, network);


--
-- Name: idx_documents_tenant; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_documents_tenant ON public.documents USING btree (tenant_id);


--
-- Name: idx_dpp_passport_batch; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_dpp_passport_batch ON public.dpp_passports USING btree (batch_id);


--
-- Name: idx_dpp_passport_status; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_dpp_passport_status ON public.dpp_passports USING btree (status);


--
-- Name: idx_dpp_passport_tenant; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_dpp_passport_tenant ON public.dpp_passports USING btree (tenant_id);


--
-- Name: idx_epcis_batch_id; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_epcis_batch_id ON public.epcis_events USING btree (batch_id);


--
-- Name: idx_epcis_events_tenant; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_epcis_events_tenant ON public.epcis_events USING btree (tenant_id);


--
-- Name: idx_materials_tenant; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_materials_tenant ON public.materials USING btree (tenant_id);


--
-- Name: idx_rbac_permissions_role; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_rbac_permissions_role ON public.rbac_permissions USING btree (role_id);


--
-- Name: idx_rbac_permissions_role_id; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_rbac_permissions_role_id ON public.rbac_permissions USING btree (role_id);


--
-- Name: idx_rbac_permissions_role_id_tenant_id; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_rbac_permissions_role_id_tenant_id ON public.rbac_permissions USING btree (role_id, tenant_id);


--
-- Name: idx_rbac_role_bindings_user; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_rbac_role_bindings_user ON public.rbac_role_bindings USING btree (user_id);


--
-- Name: idx_rbac_role_bindings_user_id; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_rbac_role_bindings_user_id ON public.rbac_role_bindings USING btree (user_id);


--
-- Name: idx_rbac_roles_name; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_rbac_roles_name ON public.rbac_roles USING btree (name);


--
-- Name: idx_rbac_roles_tenant_name; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_rbac_roles_tenant_name ON public.rbac_roles USING btree (tenant_id, name);


--
-- Name: idx_rbac_scopes_resource_action; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_rbac_scopes_resource_action ON public.rbac_scopes USING btree (resource, action);


--
-- Name: idx_rbac_scopes_tenant_resource_action; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX idx_rbac_scopes_tenant_resource_action ON public.rbac_scopes USING btree (tenant_id, resource, action);


--
-- Name: ix_batches_code; Type: INDEX; Schema: public; Owner: trace
--

CREATE UNIQUE INDEX ix_batches_code ON public.batches USING btree (code);


--
-- Name: ix_batches_id; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX ix_batches_id ON public.batches USING btree (id);


--
-- Name: ix_brands_name; Type: INDEX; Schema: public; Owner: trace
--

CREATE UNIQUE INDEX ix_brands_name ON public.brands USING btree (name);


--
-- Name: ix_customers_code; Type: INDEX; Schema: public; Owner: trace
--

CREATE UNIQUE INDEX ix_customers_code ON public.customers USING btree (code);


--
-- Name: ix_epcis_events_batch_code; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX ix_epcis_events_batch_code ON public.epcis_events USING btree (batch_code);


--
-- Name: ix_epcis_events_product_code; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX ix_epcis_events_product_code ON public.epcis_events USING btree (product_code);


--
-- Name: ix_events_batch_code; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX ix_events_batch_code ON public.events USING btree (batch_code);


--
-- Name: ix_events_id; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX ix_events_id ON public.events USING btree (id);


--
-- Name: ix_events_product_code; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX ix_events_product_code ON public.events USING btree (product_code);


--
-- Name: ix_products_code; Type: INDEX; Schema: public; Owner: trace
--

CREATE UNIQUE INDEX ix_products_code ON public.products USING btree (code);


--
-- Name: ix_products_id; Type: INDEX; Schema: public; Owner: trace
--

CREATE INDEX ix_products_id ON public.products USING btree (id);


--
-- Name: ix_tenants_name; Type: INDEX; Schema: public; Owner: trace
--

CREATE UNIQUE INDEX ix_tenants_name ON public.tenants USING btree (name);


--
-- Name: ix_users_username; Type: INDEX; Schema: public; Owner: trace
--

CREATE UNIQUE INDEX ix_users_username ON public.users USING btree (username);


--
-- Name: ux_blockchain_anchors_bundle_net; Type: INDEX; Schema: public; Owner: trace
--

CREATE UNIQUE INDEX ux_blockchain_anchors_bundle_net ON public.blockchain_anchors USING btree (tenant_id, bundle_id, network);


--
-- Name: ux_documents_tenant_hash; Type: INDEX; Schema: public; Owner: trace
--

CREATE UNIQUE INDEX ux_documents_tenant_hash ON public.documents USING btree (tenant_id, file_hash);


--
-- Name: credentials trg_sync_verified; Type: TRIGGER; Schema: public; Owner: trace
--

CREATE TRIGGER trg_sync_verified BEFORE INSERT OR UPDATE ON public.credentials FOR EACH ROW EXECUTE FUNCTION public.sync_verified_flag();


--
-- Name: configs_blockchain update_configs_blockchain_timestamp; Type: TRIGGER; Schema: public; Owner: trace
--

CREATE TRIGGER update_configs_blockchain_timestamp BEFORE UPDATE ON public.configs_blockchain FOR EACH ROW EXECUTE FUNCTION public.trg_update_timestamp();


--
-- Name: audit_logs audit_logs_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: batch_lineage batch_lineage_child_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batch_lineage
    ADD CONSTRAINT batch_lineage_child_batch_id_fkey FOREIGN KEY (child_batch_id) REFERENCES public.batches(id) ON DELETE CASCADE;


--
-- Name: batch_lineage batch_lineage_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batch_lineage
    ADD CONSTRAINT batch_lineage_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.epcis_events(id) ON DELETE SET NULL;


--
-- Name: batch_lineage batch_lineage_parent_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batch_lineage
    ADD CONSTRAINT batch_lineage_parent_batch_id_fkey FOREIGN KEY (parent_batch_id) REFERENCES public.batches(id) ON DELETE CASCADE;


--
-- Name: batch_lineage batch_lineage_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batch_lineage
    ADD CONSTRAINT batch_lineage_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: batch_links batch_links_child_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batch_links
    ADD CONSTRAINT batch_links_child_batch_id_fkey FOREIGN KEY (child_batch_id) REFERENCES public.batches(id) ON DELETE CASCADE;


--
-- Name: batch_links batch_links_parent_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batch_links
    ADD CONSTRAINT batch_links_parent_batch_id_fkey FOREIGN KEY (parent_batch_id) REFERENCES public.batches(id) ON DELETE CASCADE;


--
-- Name: batch_usage_log batch_usage_log_child_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batch_usage_log
    ADD CONSTRAINT batch_usage_log_child_batch_id_fkey FOREIGN KEY (child_batch_id) REFERENCES public.batches(id) ON DELETE SET NULL;


--
-- Name: batch_usage_log batch_usage_log_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batch_usage_log
    ADD CONSTRAINT batch_usage_log_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.epcis_events(id) ON DELETE SET NULL;


--
-- Name: batch_usage_log batch_usage_log_parent_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batch_usage_log
    ADD CONSTRAINT batch_usage_log_parent_batch_id_fkey FOREIGN KEY (parent_batch_id) REFERENCES public.batches(id) ON DELETE CASCADE;


--
-- Name: batch_usages batch_usages_child_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batch_usages
    ADD CONSTRAINT batch_usages_child_batch_id_fkey FOREIGN KEY (child_batch_id) REFERENCES public.batches(id);


--
-- Name: batch_usages batch_usages_parent_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batch_usages
    ADD CONSTRAINT batch_usages_parent_batch_id_fkey FOREIGN KEY (parent_batch_id) REFERENCES public.batches(id);


--
-- Name: batches batches_brand_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batches
    ADD CONSTRAINT batches_brand_batch_id_fkey FOREIGN KEY (brand_batch_id) REFERENCES public.batches(id) ON DELETE SET NULL;


--
-- Name: batches batches_farm_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batches
    ADD CONSTRAINT batches_farm_batch_id_fkey FOREIGN KEY (farm_batch_id) REFERENCES public.batches(id) ON DELETE SET NULL;


--
-- Name: batches batches_manufacturer_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batches
    ADD CONSTRAINT batches_manufacturer_batch_id_fkey FOREIGN KEY (manufacturer_batch_id) REFERENCES public.batches(id) ON DELETE SET NULL;


--
-- Name: batches batches_origin_farm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batches
    ADD CONSTRAINT batches_origin_farm_id_fkey FOREIGN KEY (origin_farm_id) REFERENCES public.farms(id) ON DELETE SET NULL;


--
-- Name: batches batches_parent_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batches
    ADD CONSTRAINT batches_parent_batch_id_fkey FOREIGN KEY (parent_batch_id) REFERENCES public.batches(id);


--
-- Name: batches batches_source_epcis_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batches
    ADD CONSTRAINT batches_source_epcis_id_fkey FOREIGN KEY (source_epcis_id) REFERENCES public.epcis_events(id) ON DELETE SET NULL;


--
-- Name: batches batches_supplier_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batches
    ADD CONSTRAINT batches_supplier_batch_id_fkey FOREIGN KEY (supplier_batch_id) REFERENCES public.batches(id) ON DELETE SET NULL;


--
-- Name: blockchain_anchors blockchain_anchors_dpp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.blockchain_anchors
    ADD CONSTRAINT blockchain_anchors_dpp_id_fkey FOREIGN KEY (dpp_id) REFERENCES public.dpp_passports(id) ON DELETE SET NULL;


--
-- Name: blockchain_anchors blockchain_anchors_epcis_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.blockchain_anchors
    ADD CONSTRAINT blockchain_anchors_epcis_event_id_fkey FOREIGN KEY (epcis_event_id) REFERENCES public.epcis_events(id) ON DELETE SET NULL;


--
-- Name: blockchain_anchors blockchain_anchors_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.blockchain_anchors
    ADD CONSTRAINT blockchain_anchors_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: brands brands_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.brands
    ADD CONSTRAINT brands_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: compliance_results compliance_results_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.compliance_results
    ADD CONSTRAINT compliance_results_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: configs_blockchain configs_blockchain_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.configs_blockchain
    ADD CONSTRAINT configs_blockchain_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: credentials credentials_document_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.credentials
    ADD CONSTRAINT credentials_document_id_fkey FOREIGN KEY (document_id) REFERENCES public.documents(id);


--
-- Name: credentials credentials_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.credentials
    ADD CONSTRAINT credentials_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: customers customers_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: customs customs_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.customs
    ADD CONSTRAINT customs_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id);


--
-- Name: customs customs_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.customs
    ADD CONSTRAINT customs_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: data_sharing_agreements data_sharing_agreements_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.data_sharing_agreements
    ADD CONSTRAINT data_sharing_agreements_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: documents documents_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: domains domains_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.domains
    ADD CONSTRAINT domains_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: dpp_passports dpp_passports_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.dpp_passports
    ADD CONSTRAINT dpp_passports_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.batches(id) ON DELETE SET NULL;


--
-- Name: dpp_passports dpp_passports_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.dpp_passports
    ADD CONSTRAINT dpp_passports_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: emissions emissions_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.emissions
    ADD CONSTRAINT emissions_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.batches(id);


--
-- Name: emissions emissions_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.emissions
    ADD CONSTRAINT emissions_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: epcis_events epcis_events_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.epcis_events
    ADD CONSTRAINT epcis_events_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.batches(id) ON DELETE SET NULL;


--
-- Name: epcis_events epcis_events_dpp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.epcis_events
    ADD CONSTRAINT epcis_events_dpp_id_fkey FOREIGN KEY (dpp_id) REFERENCES public.dpp_passports(id) ON DELETE SET NULL;


--
-- Name: epcis_events epcis_events_dpp_passport_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.epcis_events
    ADD CONSTRAINT epcis_events_dpp_passport_id_fkey FOREIGN KEY (dpp_passport_id) REFERENCES public.dpp_passports(id);


--
-- Name: epcis_events epcis_events_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.epcis_events
    ADD CONSTRAINT epcis_events_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: events events_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: fabric_events fabric_events_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.fabric_events
    ADD CONSTRAINT fabric_events_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: farms farms_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.farms
    ADD CONSTRAINT farms_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: batches fk_batches_farm; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.batches
    ADD CONSTRAINT fk_batches_farm FOREIGN KEY (farm_id) REFERENCES public.farms(id) ON DELETE SET NULL;


--
-- Name: epcis_events fk_epcis_tenant; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.epcis_events
    ADD CONSTRAINT fk_epcis_tenant FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: products fk_products_materials; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT fk_products_materials FOREIGN KEY (material_id) REFERENCES public.materials(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: documents fk_vc; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT fk_vc FOREIGN KEY (vc_id) REFERENCES public.credentials(id);


--
-- Name: polygon_abi polygon_abi_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.polygon_abi
    ADD CONSTRAINT polygon_abi_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: polygon_anchors polygon_anchors_dpp_passport_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.polygon_anchors
    ADD CONSTRAINT polygon_anchors_dpp_passport_id_fkey FOREIGN KEY (dpp_passport_id) REFERENCES public.dpp_passports(id);


--
-- Name: polygon_anchors polygon_anchors_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.polygon_anchors
    ADD CONSTRAINT polygon_anchors_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: polygon_logs polygon_logs_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.polygon_logs
    ADD CONSTRAINT polygon_logs_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: polygon_subscriptions polygon_subscriptions_anchor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.polygon_subscriptions
    ADD CONSTRAINT polygon_subscriptions_anchor_id_fkey FOREIGN KEY (anchor_id) REFERENCES public.polygon_anchors(id);


--
-- Name: polygon_subscriptions polygon_subscriptions_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.polygon_subscriptions
    ADD CONSTRAINT polygon_subscriptions_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: portals portals_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.portals
    ADD CONSTRAINT portals_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: products products_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id);


--
-- Name: products products_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: rbac_permissions rbac_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.rbac_permissions
    ADD CONSTRAINT rbac_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.rbac_roles(id);


--
-- Name: rbac_permissions rbac_permissions_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.rbac_permissions
    ADD CONSTRAINT rbac_permissions_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: rbac_role_bindings rbac_role_bindings_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.rbac_role_bindings
    ADD CONSTRAINT rbac_role_bindings_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.rbac_roles(id);


--
-- Name: rbac_role_bindings rbac_role_bindings_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.rbac_role_bindings
    ADD CONSTRAINT rbac_role_bindings_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: rbac_role_bindings rbac_role_bindings_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.rbac_role_bindings
    ADD CONSTRAINT rbac_role_bindings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: rbac_roles rbac_roles_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.rbac_roles
    ADD CONSTRAINT rbac_roles_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: rbac_scopes rbac_scopes_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.rbac_scopes
    ADD CONSTRAINT rbac_scopes_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: sensor_events sensor_events_epcis_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.sensor_events
    ADD CONSTRAINT sensor_events_epcis_event_id_fkey FOREIGN KEY (epcis_event_id) REFERENCES public.epcis_events(id);


--
-- Name: sensor_events sensor_events_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.sensor_events
    ADD CONSTRAINT sensor_events_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: suppliers suppliers_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: suppliers suppliers_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: ui_menus ui_menus_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.ui_menus
    ADD CONSTRAINT ui_menus_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.rbac_roles(id);


--
-- Name: ui_menus ui_menus_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.ui_menus
    ADD CONSTRAINT ui_menus_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: users users_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trace
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: trace
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


--
-- PostgreSQL database dump complete
--

\unrestrict WNUTDz6CVPCE4NjdJtbxnmZAyMEkhVWQtfccpkJKGphq0ELbKYb8GVkpNZ41led

