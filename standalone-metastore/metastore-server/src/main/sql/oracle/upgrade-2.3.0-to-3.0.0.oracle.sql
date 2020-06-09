SELECT 'Upgrading MetaStore schema from 2.3.0 to 3.0.0' AS Status from dual;

-- HIVE-21336 safeguards from failures from indices being too long
ALTER SESSION SET NLS_LENGTH_SEMANTICS=BYTE;

--@041-HIVE-16556.oracle.sql;
CREATE TABLE METASTORE_DB_PROPERTIES
(
  PROPERTY_KEY VARCHAR(255) NOT NULL,
  PROPERTY_VALUE VARCHAR(1000) NOT NULL,
  DESCRIPTION VARCHAR(1000)
);

ALTER TABLE METASTORE_DB_PROPERTIES ADD CONSTRAINT PROPERTY_KEY_PK PRIMARY KEY (PROPERTY_KEY);

--@042-HIVE-16575.oracle.sql;
CREATE INDEX CONSTRAINTS_CT_INDEX ON KEY_CONSTRAINTS(CONSTRAINT_TYPE);

--@043-HIVE-16922.oracle.sql;
UPDATE SERDE_PARAMS
SET PARAM_KEY='collection.delim'
WHERE PARAM_KEY='colelction.delim';

--@044-HIVE-16997.oracle.sql;
ALTER TABLE PART_COL_STATS ADD BIT_VECTOR BLOB NULL;
ALTER TABLE TAB_COL_STATS ADD BIT_VECTOR BLOB NULL;

--@045-HIVE-16886.oracle.sql;
INSERT INTO NOTIFICATION_SEQUENCE (NNI_ID, NEXT_EVENT_ID) SELECT 1,1 FROM DUAL WHERE NOT EXISTS ( SELECT NEXT_EVENT_ID FROM NOTIFICATION_SEQUENCE);

--@046-HIVE-17566.oracle.sql;
CREATE TABLE WM_RESOURCEPLAN
(
    RP_ID NUMBER NOT NULL,
    "NAME" VARCHAR2(128) NOT NULL,
    QUERY_PARALLELISM NUMBER(10),
    STATUS VARCHAR2(20) NOT NULL,
    DEFAULT_POOL_ID NUMBER
);

ALTER TABLE WM_RESOURCEPLAN ADD CONSTRAINT WM_RESOURCEPLAN_PK PRIMARY KEY (RP_ID);

CREATE UNIQUE INDEX UNIQUE_WM_RESOURCEPLAN ON WM_RESOURCEPLAN ("NAME");


CREATE TABLE WM_POOL
(
    POOL_ID NUMBER NOT NULL,
    RP_ID NUMBER NOT NULL,
    PATH VARCHAR2(1024) NOT NULL,
    ALLOC_FRACTION NUMBER,
    QUERY_PARALLELISM NUMBER(10),
    SCHEDULING_POLICY VARCHAR2(1024)
);

ALTER TABLE WM_POOL ADD CONSTRAINT WM_POOL_PK PRIMARY KEY (POOL_ID);

CREATE UNIQUE INDEX UNIQUE_WM_POOL ON WM_POOL (RP_ID, PATH);
ALTER TABLE WM_POOL ADD CONSTRAINT WM_POOL_FK1 FOREIGN KEY (RP_ID) REFERENCES WM_RESOURCEPLAN (RP_ID);

ALTER TABLE WM_RESOURCEPLAN ADD CONSTRAINT WM_RESOURCEPLAN_FK1 FOREIGN KEY (DEFAULT_POOL_ID) REFERENCES WM_POOL (POOL_ID);

CREATE TABLE WM_TRIGGER
(
    TRIGGER_ID NUMBER NOT NULL,
    RP_ID NUMBER NOT NULL,
    "NAME" VARCHAR2(128) NOT NULL,
    TRIGGER_EXPRESSION VARCHAR2(1024),
    ACTION_EXPRESSION VARCHAR2(1024),
    IS_IN_UNMANAGED NUMBER(1) DEFAULT 0 NOT NULL CHECK (IS_IN_UNMANAGED IN (1,0))
);

ALTER TABLE WM_TRIGGER ADD CONSTRAINT WM_TRIGGER_PK PRIMARY KEY (TRIGGER_ID);

CREATE UNIQUE INDEX UNIQUE_WM_TRIGGER ON WM_TRIGGER (RP_ID, "NAME");

ALTER TABLE WM_TRIGGER ADD CONSTRAINT WM_TRIGGER_FK1 FOREIGN KEY (RP_ID) REFERENCES WM_RESOURCEPLAN (RP_ID);


CREATE TABLE WM_POOL_TO_TRIGGER
(
    POOL_ID NUMBER NOT NULL,
    TRIGGER_ID NUMBER NOT NULL
);

ALTER TABLE WM_POOL_TO_TRIGGER ADD CONSTRAINT WM_POOL_TO_TRIGGER_PK PRIMARY KEY (POOL_ID, TRIGGER_ID);

ALTER TABLE WM_POOL_TO_TRIGGER ADD CONSTRAINT WM_POOL_TO_TRIGGER_FK1 FOREIGN KEY (POOL_ID) REFERENCES WM_POOL (POOL_ID);

ALTER TABLE WM_POOL_TO_TRIGGER ADD CONSTRAINT WM_POOL_TO_TRIGGER_FK2 FOREIGN KEY (TRIGGER_ID) REFERENCES WM_TRIGGER (TRIGGER_ID);


CREATE TABLE WM_MAPPING
(
    MAPPING_ID NUMBER NOT NULL,
    RP_ID NUMBER NOT NULL,
    ENTITY_TYPE VARCHAR2(128) NOT NULL,
    ENTITY_NAME VARCHAR2(128) NOT NULL,
    POOL_ID NUMBER NOT NULL,
    ORDERING NUMBER(10)
);

ALTER TABLE WM_MAPPING ADD CONSTRAINT WM_MAPPING_PK PRIMARY KEY (MAPPING_ID);

CREATE UNIQUE INDEX UNIQUE_WM_MAPPING ON WM_MAPPING (RP_ID, ENTITY_TYPE, ENTITY_NAME);

ALTER TABLE WM_MAPPING ADD CONSTRAINT WM_MAPPING_FK1 FOREIGN KEY (RP_ID) REFERENCES WM_RESOURCEPLAN (RP_ID);

ALTER TABLE WM_MAPPING ADD CONSTRAINT WM_MAPPING_FK2 FOREIGN KEY (POOL_ID) REFERENCES WM_POOL (POOL_ID);

-- Upgrades for Schema Registry objects
ALTER TABLE "SERDES" ADD "DESCRIPTION" VARCHAR(4000);
ALTER TABLE "SERDES" ADD "SERIALIZER_CLASS" VARCHAR(4000);
ALTER TABLE "SERDES" ADD "DESERIALIZER_CLASS" VARCHAR(4000);
ALTER TABLE "SERDES" ADD "SERDE_TYPE" INTEGER;

CREATE TABLE "I_SCHEMA" (
  "SCHEMA_ID" number primary key,
  "SCHEMA_TYPE" number not null,
  "NAME" varchar2(256) unique,
  "DB_ID" number references "DBS" ("DB_ID"),
  "COMPATIBILITY" number not null,
  "VALIDATION_LEVEL" number not null,
  "CAN_EVOLVE" number(1) not null,
  "SCHEMA_GROUP" varchar2(256),
  "DESCRIPTION" varchar2(4000)
);

CREATE TABLE "SCHEMA_VERSION" (
  "SCHEMA_VERSION_ID" number primary key,
  "SCHEMA_ID" number references "I_SCHEMA" ("SCHEMA_ID"),
  "VERSION" number not null,
  "CREATED_AT" number not null,
  "CD_ID" number references "CDS" ("CD_ID"), 
  "STATE" number not null,
  "DESCRIPTION" varchar2(4000),
  "SCHEMA_TEXT" clob,
  "FINGERPRINT" varchar2(256),
  "SCHEMA_VERSION_NAME" varchar2(256),
  "SERDE_ID" number references "SERDES" ("SERDE_ID"), 
  UNIQUE ("SCHEMA_ID", "VERSION")
);


-- 048-HIVE-14498
CREATE TABLE MV_CREATION_METADATA
(
    MV_CREATION_METADATA_ID NUMBER NOT NULL,
    CAT_NAME VARCHAR2(256) NOT NULL,
    DB_NAME VARCHAR2(128) NOT NULL,
    TBL_NAME VARCHAR2(256) NOT NULL,
    TXN_LIST CLOB NULL
);

ALTER TABLE MV_CREATION_METADATA ADD CONSTRAINT MV_CREATION_METADATA_PK PRIMARY KEY (MV_CREATION_METADATA_ID);

CREATE UNIQUE INDEX UNIQUE_TABLE ON MV_CREATION_METADATA ("DB_NAME", "TBL_NAME");

CREATE TABLE MV_TABLES_USED
(
    MV_CREATION_METADATA_ID NUMBER NOT NULL,
    TBL_ID NUMBER NOT NULL
);

ALTER TABLE MV_TABLES_USED ADD CONSTRAINT MV_TABLES_USED_FK1 FOREIGN KEY (MV_CREATION_METADATA_ID) REFERENCES MV_CREATION_METADATA (MV_CREATION_METADATA_ID);

ALTER TABLE MV_TABLES_USED ADD CONSTRAINT MV_TABLES_USED_FK2 FOREIGN KEY (TBL_ID) REFERENCES TBLS (TBL_ID);

ALTER TABLE COMPLETED_TXN_COMPONENTS ADD CTC_TIMESTAMP timestamp NULL;

UPDATE COMPLETED_TXN_COMPONENTS SET CTC_TIMESTAMP = CURRENT_TIMESTAMP;

ALTER TABLE COMPLETED_TXN_COMPONENTS MODIFY(CTC_TIMESTAMP DEFAULT CURRENT_TIMESTAMP);

ALTER TABLE COMPLETED_TXN_COMPONENTS MODIFY(CTC_TIMESTAMP NOT NULL);

CREATE INDEX COMPLETED_TXN_COMPONENTS_INDEX ON COMPLETED_TXN_COMPONENTS (CTC_DATABASE, CTC_TABLE, CTC_PARTITION);

-- 049-HIVE-18489
UPDATE FUNC_RU
  SET RESOURCE_URI = 's3a' || SUBSTR(RESOURCE_URI, 4)
  WHERE RESOURCE_URI LIKE 's3n://%' ;

UPDATE SKEWED_COL_VALUE_LOC_MAP
  SET LOCATION = 's3a' || SUBSTR(LOCATION, 4)
  WHERE LOCATION LIKE 's3n://%' ;

UPDATE SDS
  SET LOCATION = 's3a' || SUBSTR(LOCATION, 4)
  WHERE LOCATION LIKE 's3n://%' ;

UPDATE DBS
  SET DB_LOCATION_URI = 's3a' || SUBSTR(DB_LOCATION_URI, 4)
  WHERE DB_LOCATION_URI LIKE 's3n://%' ;

-- HIVE-18192
CREATE TABLE TXN_TO_WRITE_ID (
  T2W_TXNID NUMBER(19) NOT NULL,
  T2W_DATABASE VARCHAR2(128) NOT NULL,
  T2W_TABLE VARCHAR2(256) NOT NULL,
  T2W_WRITEID NUMBER(19) NOT NULL
);

CREATE UNIQUE INDEX TBL_TO_TXN_ID_IDX ON TXN_TO_WRITE_ID (T2W_DATABASE, T2W_TABLE, T2W_TXNID);
CREATE UNIQUE INDEX TBL_TO_WRITE_ID_IDX ON TXN_TO_WRITE_ID (T2W_DATABASE, T2W_TABLE, T2W_WRITEID);

CREATE TABLE NEXT_WRITE_ID (
  NWI_DATABASE VARCHAR2(128) NOT NULL,
  NWI_TABLE VARCHAR2(256) NOT NULL,
  NWI_NEXT NUMBER(19) NOT NULL
);

CREATE UNIQUE INDEX NEXT_WRITE_ID_IDX ON NEXT_WRITE_ID (NWI_DATABASE, NWI_TABLE);

ALTER TABLE COMPACTION_QUEUE RENAME COLUMN CQ_HIGHEST_TXN_ID TO CQ_HIGHEST_WRITE_ID;

ALTER TABLE COMPLETED_COMPACTIONS RENAME COLUMN CC_HIGHEST_TXN_ID TO CC_HIGHEST_WRITE_ID;

-- Modify txn_components/completed_txn_components tables to add write id.
ALTER TABLE TXN_COMPONENTS ADD TC_WRITEID number(19);
ALTER TABLE COMPLETED_TXN_COMPONENTS ADD CTC_WRITEID number(19);

-- HIVE-18726
-- add a new column to support default value for DEFAULT constraint
ALTER TABLE KEY_CONSTRAINTS ADD DEFAULT_VALUE VARCHAR(400);
ALTER TABLE KEY_CONSTRAINTS MODIFY (PARENT_CD_ID NULL);

ALTER TABLE HIVE_LOCKS MODIFY(HL_TXNID NOT NULL);

-- HIVE-18755, add catalogs
-- new catalogs table
CREATE TABLE CTLGS (
    CTLG_ID NUMBER PRIMARY KEY,
    "NAME" VARCHAR2(256),
    "DESC" VARCHAR2(4000),
    LOCATION_URI VARCHAR2(4000) NOT NULL,
    UNIQUE ("NAME")
);

-- Insert a default value.  The location is TBD.  Hive will fix this when it starts
INSERT INTO CTLGS VALUES (1, 'hive', 'Default catalog for Hive', 'TBD');

-- Drop the unique index on DBS
DROP INDEX UNIQUE_DATABASE;

-- Add the new column to the DBS table, can't put in the not null constraint yet
ALTER TABLE DBS ADD CTLG_NAME VARCHAR2(256);

-- Update all records in the DBS table to point to the Hive catalog
UPDATE DBS 
  SET "CTLG_NAME" = 'hive';

-- Add the not null constraint
ALTER TABLE DBS MODIFY CTLG_NAME DEFAULT 'hive' NOT NULL;

-- Put back the unique index 
CREATE UNIQUE INDEX UNIQUE_DATABASE ON DBS ("NAME", CTLG_NAME);

-- Add the foreign key
ALTER TABLE DBS ADD CONSTRAINT CTLGS_FK FOREIGN KEY (CTLG_NAME) REFERENCES CTLGS ("NAME") INITIALLY DEFERRED;

-- Add columns to table stats and part stats
ALTER TABLE TAB_COL_STATS ADD CAT_NAME VARCHAR2(256);
ALTER TABLE PART_COL_STATS ADD CAT_NAME VARCHAR2(256);

-- Set the existing column names to Hive
UPDATE TAB_COL_STATS
  SET CAT_NAME = 'hive';
UPDATE PART_COL_STATS
  SET CAT_NAME = 'hive';

-- Add the not null constraint
ALTER TABLE TAB_COL_STATS MODIFY CAT_NAME NOT NULL;
ALTER TABLE PART_COL_STATS MODIFY CAT_NAME NOT NULL;

-- Rebuild the index for Part col stats.  No such index for table stats, which seems weird
DROP INDEX PCS_STATS_IDX;
CREATE INDEX PCS_STATS_IDX ON PART_COL_STATS (CAT_NAME, DB_NAME,TABLE_NAME,COLUMN_NAME,PARTITION_NAME);

-- Add column to partition events
ALTER TABLE PARTITION_EVENTS ADD CAT_NAME VARCHAR2(256);
UPDATE PARTITION_EVENTS
  SET CAT_NAME = 'hive' WHERE DB_NAME IS NOT NULL;

-- Add column to notification log
ALTER TABLE NOTIFICATION_LOG ADD CAT_NAME VARCHAR2(256);
UPDATE NOTIFICATION_LOG
  SET CAT_NAME = 'hive' WHERE DB_NAME IS NOT NULL;

CREATE TABLE REPL_TXN_MAP (
  RTM_REPL_POLICY varchar(256) NOT NULL,
  RTM_SRC_TXN_ID number(19) NOT NULL,
  RTM_TARGET_TXN_ID number(19) NOT NULL,
  PRIMARY KEY (RTM_REPL_POLICY, RTM_SRC_TXN_ID)
);

INSERT INTO SEQUENCE_TABLE (SEQUENCE_NAME, NEXT_VAL) SELECT 'org.apache.hadoop.hive.metastore.model.MNotificationLog',1 FROM DUAL WHERE NOT EXISTS ( SELECT NEXT_VAL FROM SEQUENCE_TABLE WHERE SEQUENCE_NAME = 'org.apache.hadoop.hive.metastore.model.MNotificationLog');

-- HIVE-18747
CREATE TABLE MIN_HISTORY_LEVEL (
  MHL_TXNID number(19) NOT NULL,
  MHL_MIN_OPEN_TXNID number(19) NOT NULL,
  PRIMARY KEY(MHL_TXNID)
);

CREATE INDEX MIN_HISTORY_LEVEL_IDX ON MIN_HISTORY_LEVEL (MHL_MIN_OPEN_TXNID);

CREATE TABLE RUNTIME_STATS (
  RS_ID NUMBER primary key,
  CREATE_TIME NUMBER(10) NOT NULL,
  WEIGHT NUMBER(10) NOT NULL,
  PAYLOAD BLOB
);

CREATE INDEX IDX_RUNTIME_STATS_CREATE_TIME ON RUNTIME_STATS(CREATE_TIME);

-- HIVE-18193
-- Populate NEXT_WRITE_ID for each Transactional table and set next write ID same as next txn ID
INSERT INTO NEXT_WRITE_ID (NWI_DATABASE, NWI_TABLE, NWI_NEXT)
    SELECT * FROM
        (SELECT DB.NAME, TBL_INFO.TBL_NAME FROM DBS DB,
            (SELECT TBL.DB_ID, TBL.TBL_NAME FROM TBLS TBL,
                (SELECT TBL_ID FROM TABLE_PARAMS WHERE PARAM_KEY='transactional' AND to_char(PARAM_VALUE)='true') TBL_PARAM
            WHERE TBL.TBL_ID=TBL_PARAM.TBL_ID) TBL_INFO
        where DB.DB_ID=TBL_INFO.DB_ID) DB_TBL_NAME,
        (SELECT NTXN_NEXT FROM NEXT_TXN_ID) NEXT_WRITE;

-- Populate TXN_TO_WRITE_ID for each aborted/open txns and set write ID equal to txn ID
INSERT INTO TXN_TO_WRITE_ID (T2W_DATABASE, T2W_TABLE, T2W_TXNID, T2W_WRITEID)
    SELECT * FROM
        (SELECT DB.NAME, TBL_INFO.TBL_NAME FROM DBS DB,
            (SELECT TBL.DB_ID, TBL.TBL_NAME FROM TBLS TBL,
                (SELECT TBL_ID FROM TABLE_PARAMS WHERE PARAM_KEY='transactional' AND to_char(PARAM_VALUE)='true') TBL_PARAM
            WHERE TBL.TBL_ID=TBL_PARAM.TBL_ID) TBL_INFO
        where DB.DB_ID=TBL_INFO.DB_ID) DB_TBL_NAME,
        (SELECT TXN_ID, TXN_ID as WRITE_ID FROM TXNS) TXN_INFO;

-- Update TXN_COMPONENTS and COMPLETED_TXN_COMPONENTS for write ID which is same as txn ID
UPDATE TXN_COMPONENTS SET TC_WRITEID = TC_TXNID;
UPDATE COMPLETED_TXN_COMPONENTS SET CTC_WRITEID = CTC_TXNID;

ALTER TABLE TBLS ADD OWNER_TYPE VARCHAR2(10) NULL;

-- HIVE-23211: Fix metastore schema differences between init scripts, and upgrade scripts
-- Not updating possible NULL values, since if NULLs existing in this table, the upgrade should fail
ALTER TABLE TXN_COMPONENTS MODIFY (TC_TXNID  NOT NULL);
ALTER TABLE COMPLETED_TXN_COMPONENTS MODIFY (CTC_TXNID  NOT NULL);

-- These lines need to be last.  Insert any changes above.
UPDATE VERSION SET SCHEMA_VERSION='3.0.0', VERSION_COMMENT='Hive release version 3.0.0' where VER_ID=1;
SELECT 'Finished upgrading MetaStore schema from 2.3.0 to 3.0.0' AS Status from dual;

