-- ============================================================
-- Subscription & Billing Management Platform
-- MySQL DDL Script — BINARY(16) UUIDs throughout
-- MySQL 8.0+ required
-- ============================================================

-- ============================================================
-- DOMAIN 1: CUSTOMER & IDENTITY MANAGEMENT
-- ============================================================

CREATE TABLE user (
    id            BINARY(16)      NOT NULL DEFAULT (UUID_TO_BIN(UUID(), TRUE)),
    name          VARCHAR(150)    NOT NULL,
    email         VARCHAR(255)    NOT NULL,
    password_hash VARCHAR(255)    NOT NULL,
    role          ENUM('ADMIN', 'BILLING_MANAGER', 'FINANCE_ANALYST', 'SUPPORT', 'COMPLIANCE_USER', 'VIEWER')
                                  NOT NULL DEFAULT 'VIEWER',
    is_active     BOOLEAN         NOT NULL DEFAULT TRUE,
    last_login    DATETIME        NULL,
    created_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_user       PRIMARY KEY (id),
    CONSTRAINT uq_user_email UNIQUE (email)
);

CREATE TABLE customer (
    id              BINARY(16)   NOT NULL DEFAULT (UUID_TO_BIN(UUID(), TRUE)),
    name            VARCHAR(150) NOT NULL,
    email           VARCHAR(255) NOT NULL,
    phone           VARCHAR(30)  NULL,
    company         VARCHAR(150) NULL,
    billing_address TEXT         NULL,
    tax_id          VARCHAR(50)  NULL,
    status          ENUM('ACTIVE', 'SUSPENDED', 'CHURNED', 'TRIAL') NOT NULL DEFAULT 'ACTIVE',
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_customer       PRIMARY KEY (id),
    CONSTRAINT uq_customer_email UNIQUE (email)
);

CREATE TABLE audit_log (
    id          BINARY(16)  NOT NULL DEFAULT (UUID_TO_BIN(UUID(), TRUE)),
    user_id     BINARY(16)  NOT NULL,
    entity_type VARCHAR(50) NOT NULL COMMENT 'E.g. INVOICE, PAYMENT, SUBSCRIPTION',
    entity_id   BINARY(16)  NOT NULL,
    action      ENUM('CREATE', 'UPDATE', 'DELETE', 'BILLING_RUN') NOT NULL,
    old_values  JSON        NULL     COMMENT 'Snapshot before change',
    new_values  JSON        NULL     COMMENT 'Snapshot after change',
    ip_address  VARCHAR(45) NULL     COMMENT 'Supports IPv4 and IPv6',
    created_at  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_audit_log  PRIMARY KEY (id),
    CONSTRAINT fk_audit_user FOREIGN KEY (user_id)
        REFERENCES user(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_audit_entity  (entity_type, entity_id),
    INDEX idx_audit_user    (user_id),
    INDEX idx_audit_created (created_at)
);

-- ============================================================
-- DOMAIN 2: PLAN & SUBSCRIPTION MANAGEMENT
-- ============================================================

CREATE TABLE plan (
    id            BINARY(16)     NOT NULL DEFAULT (UUID_TO_BIN(UUID(), TRUE)),
    name          VARCHAR(100)   NOT NULL,
    description   TEXT           NULL,
    base_price    DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    billing_cycle ENUM('MONTHLY', 'QUARTERLY', 'ANNUAL', 'USAGE') NOT NULL DEFAULT 'MONTHLY',
    plan_type     ENUM('FLAT', 'PER_SEAT', 'USAGE_BASED', 'TIERED') NOT NULL DEFAULT 'FLAT',
    trial_days    INT            NOT NULL DEFAULT 0,
    is_active     BOOLEAN        NOT NULL DEFAULT TRUE,
    created_at    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_plan        PRIMARY KEY (id),
    CONSTRAINT uq_plan_name   UNIQUE (name),
    CONSTRAINT chk_plan_price CHECK (base_price >= 0),
    CONSTRAINT chk_plan_trial CHECK (trial_days >= 0)
);

CREATE TABLE plan_feature (
    id            BINARY(16)   NOT NULL DEFAULT (UUID_TO_BIN(UUID(), TRUE)),
    plan_id       BINARY(16)   NOT NULL,
    feature_name  VARCHAR(100) NOT NULL COMMENT 'E.g. api_calls, storage_gb, seats',
    feature_value VARCHAR(100) NOT NULL COMMENT 'Limit or entitlement value',
    unit          VARCHAR(50)  NULL     COMMENT 'Unit of measure e.g. calls, GB',
    CONSTRAINT pk_plan_feature      PRIMARY KEY (id),
    CONSTRAINT fk_plan_feature_plan FOREIGN KEY (plan_id)
        REFERENCES plan(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_plan_feature_plan (plan_id)
);

CREATE TABLE discount (
    id            BINARY(16)     NOT NULL DEFAULT (UUID_TO_BIN(UUID(), TRUE)),
    code          VARCHAR(50)    NOT NULL,
    discount_type ENUM('FLAT', 'PERCENTAGE') NOT NULL DEFAULT 'PERCENTAGE',
    value         DECIMAL(10, 2) NOT NULL,
    valid_from    DATE           NOT NULL,
    valid_until   DATE           NULL,
    max_uses      INT            NULL     COMMENT 'NULL means unlimited',
    used_count    INT            NOT NULL DEFAULT 0,
    is_active     BOOLEAN        NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_discount        PRIMARY KEY (id),
    CONSTRAINT uq_discount_code   UNIQUE (code),
    CONSTRAINT chk_discount_value CHECK (value > 0),
    CONSTRAINT chk_discount_dates CHECK (valid_until IS NULL OR valid_until >= valid_from),
    INDEX idx_discount_code   (code),
    INDEX idx_discount_active (is_active)
);

CREATE TABLE subscription (
    id                BINARY(16)     NOT NULL DEFAULT (UUID_TO_BIN(UUID(), TRUE)),
    customer_id       BINARY(16)     NOT NULL,
    plan_id           BINARY(16)     NOT NULL,
    status            ENUM('ACTIVE', 'TRIAL', 'PAUSED', 'CANCELLED', 'PAST_DUE') NOT NULL DEFAULT 'TRIAL',
    start_date        DATE           NOT NULL,
    end_date          DATE           NULL,
    trial_end_date    DATE           NULL,
    next_billing_date DATE           NOT NULL,
    current_mrr       DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    quantity          INT            NOT NULL DEFAULT 1,
    created_at        DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_subscription          PRIMARY KEY (id),
    CONSTRAINT fk_subscription_customer FOREIGN KEY (customer_id)
        REFERENCES customer(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_subscription_plan     FOREIGN KEY (plan_id)
        REFERENCES plan(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_subscription_quantity CHECK (quantity > 0),
    CONSTRAINT chk_subscription_mrr      CHECK (current_mrr >= 0),
    INDEX idx_subscription_customer     (customer_id),
    INDEX idx_subscription_plan         (plan_id),
    INDEX idx_subscription_status       (status),
    INDEX idx_subscription_next_billing (next_billing_date)
);

CREATE TABLE subscription_addon (
    id              BINARY(16)     NOT NULL DEFAULT (UUID_TO_BIN(UUID(), TRUE)),
    subscription_id BINARY(16)     NOT NULL,
    addon_name      VARCHAR(100)   NOT NULL,
    price           DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    quantity        INT            NOT NULL DEFAULT 1,
    CONSTRAINT pk_subscription_addon PRIMARY KEY (id),
    CONSTRAINT fk_addon_subscription FOREIGN KEY (subscription_id)
        REFERENCES subscription(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_addon_price    CHECK (price >= 0),
    CONSTRAINT chk_addon_quantity CHECK (quantity > 0),
    INDEX idx_addon_subscription (subscription_id)
);

CREATE TABLE subscription_discount (
    id              BINARY(16) NOT NULL DEFAULT (UUID_TO_BIN(UUID(), TRUE)),
    subscription_id BINARY(16) NOT NULL,
    discount_id     BINARY(16) NOT NULL,
    applied_at      DATE       NOT NULL DEFAULT (CURRENT_DATE),
    expires_at      DATE       NULL,
    CONSTRAINT pk_subscription_discount     PRIMARY KEY (id),
    CONSTRAINT fk_sub_discount_subscription FOREIGN KEY (subscription_id)
        REFERENCES subscription(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_sub_discount_discount     FOREIGN KEY (discount_id)
        REFERENCES discount(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uq_sub_discount UNIQUE (subscription_id, discount_id),
    INDEX idx_sub_discount_sub  (subscription_id),
    INDEX idx_sub_discount_disc (discount_id)
);

-- ============================================================
-- DOMAIN 3: BILLING ENGINE
-- ============================================================

CREATE TABLE tax_rule (
    id        BINARY(16)    NOT NULL DEFAULT (UUID_TO_BIN(UUID(), TRUE)),
    name      VARCHAR(100)  NOT NULL COMMENT 'E.g. Karnataka GST 18%',
    region    VARCHAR(20)   NOT NULL COMMENT 'Country or state code e.g. IN-KA, US-CA',
    rate      DECIMAL(6, 4) NOT NULL COMMENT 'E.g. 0.1800 for 18%',
    tax_type  ENUM('GST', 'VAT', 'SALES_TAX', 'SERVICE_TAX') NOT NULL,
    is_active BOOLEAN       NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_tax_rule  PRIMARY KEY (id),
    CONSTRAINT chk_tax_rate CHECK (rate >= 0 AND rate <= 1),
    INDEX idx_tax_rule_region (region),
    INDEX idx_tax_rule_active (is_active)
);

CREATE TABLE billing_job (
    id                      BINARY(16)     NOT NULL DEFAULT (UUID_TO_BIN(UUID(), TRUE)),
    scheduled_date          DATE           NOT NULL,
    status                  ENUM('PENDING', 'RUNNING', 'COMPLETED', 'FAILED') NOT NULL DEFAULT 'PENDING',
    subscriptions_processed INT            NOT NULL DEFAULT 0,
    invoices_generated      INT            NOT NULL DEFAULT 0,
    total_amount            DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    started_at              DATETIME       NULL,
    completed_at            DATETIME       NULL,
    error_log               TEXT           NULL,
    CONSTRAINT pk_billing_job      PRIMARY KEY (id),
    CONSTRAINT uq_billing_job_date UNIQUE (scheduled_date),
    INDEX idx_billing_job_status (status),
    INDEX idx_billing_job_date   (scheduled_date)
);

CREATE TABLE invoice (
    id              BINARY(16)     NOT NULL DEFAULT (UUID_TO_BIN(UUID(), TRUE)),
    subscription_id BINARY(16)     NOT NULL,
    billing_job_id  BINARY(16)     NULL     COMMENT 'NULL for manually created invoices',
    invoice_number  VARCHAR(50)    NOT NULL,
    issue_date      DATE           NOT NULL,
    due_date        DATE           NOT NULL,
    subtotal        DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    discount_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    tax_amount      DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    total_amount    DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    status          ENUM('DRAFT', 'SENT', 'PAID', 'OVERDUE', 'VOID') NOT NULL DEFAULT 'DRAFT',
    notes           TEXT           NULL,
    created_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_invoice         PRIMARY KEY (id),
    CONSTRAINT uq_invoice_number  UNIQUE (invoice_number),
    CONSTRAINT fk_invoice_sub     FOREIGN KEY (subscription_id)
        REFERENCES subscription(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_invoice_billing FOREIGN KEY (billing_job_id)
        REFERENCES billing_job(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_invoice_amounts CHECK (
        subtotal >= 0 AND discount_amount >= 0
        AND tax_amount >= 0 AND total_amount >= 0),
    CONSTRAINT chk_invoice_dates  CHECK (due_date >= issue_date),
    INDEX idx_invoice_subscription (subscription_id),
    INDEX idx_invoice_billing_job  (billing_job_id),
    INDEX idx_invoice_status       (status),
    INDEX idx_invoice_due_date     (due_date)
);

CREATE TABLE invoice_line_item (
    id              BINARY(16)     NOT NULL DEFAULT (UUID_TO_BIN(UUID(), TRUE)),
    invoice_id      BINARY(16)     NOT NULL,
    description     VARCHAR(255)   NOT NULL,
    quantity        INT            NOT NULL DEFAULT 1,
    unit_price      DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    discount_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    line_total      DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    CONSTRAINT pk_invoice_line_item  PRIMARY KEY (id),
    CONSTRAINT fk_line_item_invoice  FOREIGN KEY (invoice_id)
        REFERENCES invoice(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_line_item_quantity CHECK (quantity > 0),
    CONSTRAINT chk_line_item_amounts  CHECK (
        unit_price >= 0 AND discount_amount >= 0 AND line_total >= 0),
    INDEX idx_line_item_invoice (invoice_id)
);

-- ============================================================
-- DOMAIN 4: PAYMENTS & COLLECTIONS
-- ============================================================

CREATE TABLE payment_method (
    id             BINARY(16)   NOT NULL DEFAULT (UUID_TO_BIN(UUID(), TRUE)),
    customer_id    BINARY(16)   NOT NULL,
    method_type    ENUM('CARD', 'BANK_TRANSFER', 'UPI', 'WALLET') NOT NULL DEFAULT 'CARD',
    provider_token VARCHAR(255) NOT NULL COMMENT 'Tokenised vault reference — never raw card data',
    last_four      CHAR(4)      NULL     COMMENT 'Last 4 digits for display only',
    expiry_date    DATE         NULL,
    is_default     BOOLEAN      NOT NULL DEFAULT FALSE,
    is_active      BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_payment_method          PRIMARY KEY (id),
    CONSTRAINT fk_payment_method_customer FOREIGN KEY (customer_id)
        REFERENCES customer(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_payment_method_customer (customer_id),
    INDEX idx_payment_method_default  (customer_id, is_default)
);

CREATE TABLE payment (
    id                BINARY(16)     NOT NULL DEFAULT (UUID_TO_BIN(UUID(), TRUE)),
    invoice_id        BINARY(16)     NOT NULL,
    payment_method_id BINARY(16)     NULL     COMMENT 'NULL for manual/offline payments',
    amount            DECIMAL(12, 2) NOT NULL,
    status            ENUM('PENDING', 'SUCCESS', 'FAILED', 'REFUNDED') NOT NULL DEFAULT 'PENDING',
    transaction_id    VARCHAR(255)   NULL     COMMENT 'Gateway-issued transaction reference',
    gateway_response  TEXT           NULL     COMMENT 'Raw gateway response payload',
    paid_at           DATETIME       NULL,
    created_at        DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_payment         PRIMARY KEY (id),
    CONSTRAINT fk_payment_invoice FOREIGN KEY (invoice_id)
        REFERENCES invoice(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_payment_method  FOREIGN KEY (payment_method_id)
        REFERENCES payment_method(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_payment_amount CHECK (amount > 0),
    INDEX idx_payment_invoice        (invoice_id),
    INDEX idx_payment_method         (payment_method_id),
    INDEX idx_payment_status         (status),
    INDEX idx_payment_transaction_id (transaction_id)
);

CREATE TABLE dunning_event (
    id             BINARY(16) NOT NULL DEFAULT (UUID_TO_BIN(UUID(), TRUE)),
    invoice_id     BINARY(16) NOT NULL,
    event_type     ENUM('EMAIL_REMINDER', 'RETRY_CHARGE', 'SUSPENSION_WARNING', 'FINAL_NOTICE') NOT NULL,
    attempt_number INT        NOT NULL DEFAULT 1,
    scheduled_at   DATETIME   NOT NULL,
    sent_at        DATETIME   NULL,
    status         ENUM('PENDING', 'SENT', 'FAILED', 'SKIPPED') NOT NULL DEFAULT 'PENDING',
    CONSTRAINT pk_dunning_event   PRIMARY KEY (id),
    CONSTRAINT fk_dunning_invoice FOREIGN KEY (invoice_id)
        REFERENCES invoice(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_dunning_attempt CHECK (attempt_number > 0),
    INDEX idx_dunning_invoice      (invoice_id),
    INDEX idx_dunning_status       (status),
    INDEX idx_dunning_scheduled_at (scheduled_at)
);

-- ============================================================
-- JUNCTION: TAX RULE <-> INVOICE  (many-to-many)
-- ============================================================

CREATE TABLE invoice_tax (
    id          BINARY(16)     NOT NULL DEFAULT (UUID_TO_BIN(UUID(), TRUE)),
    invoice_id  BINARY(16)     NOT NULL,
    tax_rule_id BINARY(16)     NOT NULL,
    rate        DECIMAL(6, 4)  NOT NULL COMMENT 'Snapshot of rate at time of invoicing',
    tax_amount  DECIMAL(12, 2) NOT NULL,
    CONSTRAINT pk_invoice_tax         PRIMARY KEY (id),
    CONSTRAINT fk_invoice_tax_invoice FOREIGN KEY (invoice_id)
        REFERENCES invoice(id) ON DELETE CASCADE,
    CONSTRAINT fk_invoice_tax_rule    FOREIGN KEY (tax_rule_id)
        REFERENCES tax_rule(id) ON DELETE RESTRICT,
    CONSTRAINT uq_invoice_tax UNIQUE (invoice_id, tax_rule_id),
    INDEX idx_invoice_tax_invoice (invoice_id)
);

-- ============================================================
-- HELPER VIEWS — human-readable UUIDs
-- ============================================================

CREATE OR REPLACE VIEW v_customer AS
SELECT
    BIN_TO_UUID(id, TRUE) AS id,
    name, email, phone, company,
    billing_address, tax_id, status,
    created_at, updated_at
FROM customer;

CREATE OR REPLACE VIEW v_subscription AS
SELECT
    BIN_TO_UUID(id, TRUE)          AS id,
    BIN_TO_UUID(customer_id, TRUE) AS customer_id,
    BIN_TO_UUID(plan_id, TRUE)     AS plan_id,
    status, start_date, end_date, trial_end_date,
    next_billing_date, current_mrr, quantity,
    created_at, updated_at
FROM subscription;

CREATE OR REPLACE VIEW v_invoice AS
SELECT
    BIN_TO_UUID(id, TRUE)              AS id,
    BIN_TO_UUID(subscription_id, TRUE) AS subscription_id,
    BIN_TO_UUID(billing_job_id, TRUE)  AS billing_job_id,
    invoice_number, issue_date, due_date,
    subtotal, discount_amount, tax_amount, total_amount,
    status, notes, created_at
FROM invoice;

CREATE OR REPLACE VIEW v_payment AS
SELECT
    BIN_TO_UUID(id, TRUE)                AS id,
    BIN_TO_UUID(invoice_id, TRUE)        AS invoice_id,
    BIN_TO_UUID(payment_method_id, TRUE) AS payment_method_id,
    amount, status, transaction_id,
    gateway_response, paid_at, created_at
FROM payment;
