-- task 1

SET client_min_messages TO WARNING;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE customers (
    customer_id BIGSERIAL PRIMARY KEY,
    iin VARCHAR(12) UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone VARCHAR(20),
    email TEXT,
    status VARCHAR(10) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    daily_limit_kzt NUMERIC(20,2) DEFAULT 1000000.00
);

CREATE TABLE accounts (
    account_id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    account_number TEXT UNIQUE NOT NULL,
    currency VARCHAR(3) NOT NULL CHECK (currency IN ('KZT','USD','EUR','RUB')),
    balance NUMERIC(20,2) NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    opened_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    closed_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE exchange_rates (
    rate_id BIGSERIAL PRIMARY KEY,
    from_currency VARCHAR(3) NOT NULL,
    to_currency VARCHAR(3) NOT NULL,
    rate NUMERIC(30,10) NOT NULL,
    valid_from TIMESTAMP WITH TIME ZONE NOT NULL,
    valid_to TIMESTAMP WITH TIME ZONE
);

CREATE TABLE transactions (
    transaction_id BIGSERIAL PRIMARY KEY,
    from_account_id BIGINT REFERENCES accounts(account_id),
    to_account_id BIGINT REFERENCES accounts(account_id),
    amount NUMERIC(20,2) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    exchange_rate NUMERIC(30,10),
    amount_kzt NUMERIC(20,2),
    type VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    completed_at TIMESTAMP WITH TIME ZONE,
    description TEXT
);

CREATE TABLE audit_log (
    log_id BIGSERIAL PRIMARY KEY,
    table_name TEXT,
    record_id BIGINT,
    action VARCHAR(10) NOT NULL,
    old_values JSONB,
    new_values JSONB,
    changed_by TEXT,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    ip_address TEXT
);

CREATE TABLE salary_batch_runs (
    run_id BIGSERIAL PRIMARY KEY,
    company_account_id BIGINT REFERENCES accounts(account_id),
    total_amount NUMERIC(20,2),
    successful_count INT,
    failed_count INT,
    failed_details JSONB,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    finished_at TIMESTAMP WITH TIME ZONE
);

INSERT INTO customers (iin, full_name, phone, email, status, daily_limit_kzt) VALUES
('870101123456','Jotaro Kujo','+77010000001','jotaro@example.com','active',5000000),
('880202234567','Joseph Joestar','+77010000002','joseph@example.com','active',2000000),
('890303345678','Dio Brando','+77010000003','dio@example.com','blocked',1000000),
('900404456789','Kira Yoshikage','+77010000004','kira@example.com','active',3000000),
('910505567890','Lisa Lisa','+77010000005','lisa@example.com','active',1500000),
('920606678901','Enrico Pucci','+77010000006','pucci@example.com','frozen',1000000),
('930707789012','Giorno Giovanna','+77010000007','giorno@example.com','active',2500000),
('940808890123','Muhammad Avdol','+77010000008','avdol@example.com','active',4000000),
('950909901234','Noriaki Kakyoin','+77010000009','kakyoin@example.com','active',1000000),
('961010012345','Speedwagon Foundation','+77010000010','payroll@speedwagon.org','active',10000000);

INSERT INTO accounts (customer_id, account_number, currency, balance, is_active) VALUES
(1,'KZ01ACC0000000001','KZT',1000000,true),
(1,'KZ01ACC0000000002','USD',2000,true),
(2,'KZ02ACC0000000003','KZT',500000,true),
(3,'KZ03ACC0000000004','EUR',1000,true),
(4,'KZ04ACC0000000005','KZT',150000,true),
(5,'KZ05ACC0000000006','RUB',80000,true),
(6,'KZ06ACC0000000007','KZT',20000,false),
(7,'KZ07ACC0000000008','USD',500,true),
(8,'KZ08ACC0000000009','KZT',300000,true),
(10,'KZ10ACC0000000101','KZT',10000000,true);

INSERT INTO exchange_rates (from_currency,to_currency,rate,valid_from,valid_to) VALUES
('USD','KZT',470.50,now()-interval '30 days',now()+interval '30 days'),
('EUR','KZT',510.75,now()-interval '30 days',now()+interval '30 days'),
('RUB','KZT',5.50,now()-interval '30 days',now()+interval '30 days'),
('KZT','KZT',1,now()-interval '1 year',now()+interval '1 year'),
('USD','EUR',0.92,now()-interval '30 days',now()+interval '30 days'),
('EUR','USD',1.09,now()-interval '30 days',now()+interval '30 days');

INSERT INTO transactions (from_account_id,to_account_id,amount,currency,exchange_rate,amount_kzt,type,status,created_at,completed_at,description) VALUES
(2,3,100,'USD',470.50,47050,'transfer','completed',now()-interval '5 days',now()-interval '5 days','test'),
(1,5,10000,'KZT',1,10000,'transfer','completed',now()-interval '3 days',now()-interval '3 days','pay'),
(8,1,200000,'KZT',1,200000,'transfer','completed',now()-interval '1 days',now()-interval '1 days','salary'),
(NULL,1,5000,'KZT',1,5000,'deposit','completed',now()-interval '10 days',now()-interval '10 days','deposit'),
(1,4,50,'USD',470.5,23525,'transfer','completed',now()-interval '2 days',now()-interval '2 days',''),
(5,6,20000,'RUB',5.50,110000,'failed','failed',now()-interval '4 days',NULL,'fail'),
(9,8,100000,'KZT',1,100000,'transfer','completed',now()-interval '6 days',now()-interval '6 days',''),
(10,1,1500000,'KZT',1,1500000,'deposit','completed',now()-interval '40 days',now()-interval '40 days','fund'),
(10,7,100000,'KZT',1,100000,'salary','completed',now()-interval '20 days',now()-interval '20 days',''),
(1,8,10,'USD',470.5,4705,'transfer','completed',now()-interval '2 hours',now()-interval '2 hours','');

INSERT INTO audit_log(table_name,record_id,action,old_values,new_values,changed_by,ip_address)
VALUES ('customers',1,'INSERT',NULL,to_jsonb((SELECT c FROM customers c WHERE customer_id=1)),'system','127.0.0.1');

CREATE INDEX idx_customers_iin ON customers(iin);
CREATE INDEX idx_accounts_customer_currency ON accounts(customer_id,currency) INCLUDE(balance);
CREATE INDEX idx_accounts_account_number_hash ON accounts USING HASH(account_number);
CREATE INDEX idx_accounts_active ON accounts(account_number) WHERE is_active = true;
CREATE INDEX idx_customers_email_lower ON customers(lower(email));
CREATE INDEX idx_auditlog_old_gin ON audit_log USING GIN(old_values);
CREATE INDEX idx_auditlog_new_gin ON audit_log USING GIN(new_values);
CREATE INDEX idx_transactions_created_at_brin ON transactions USING BRIN(created_at);

CREATE OR REPLACE FUNCTION process_transfer(
    p_from_account_number TEXT,
    p_to_account_number TEXT,
    p_amount NUMERIC,
    p_currency VARCHAR,
    p_description TEXT,
    p_initiator TEXT DEFAULT 'system'
)
RETURNS TABLE(result_code INT, result_message TEXT)
LANGUAGE plpgsql AS
$$
DECLARE
    v_from_acc RECORD;
    v_to_acc RECORD;
    v_rate NUMERIC := 1;
    v_amount_kzt NUMERIC;
    v_customer_limit NUMERIC;
    v_today_total NUMERIC;
    v_save TEXT := 'sp';
BEGIN
    IF p_amount <= 0 THEN RETURN QUERY SELECT 1001,'Amount must be positive'; RETURN; END IF;

    SELECT * INTO v_from_acc FROM accounts WHERE account_number=p_from_account_number FOR UPDATE;
    IF NOT FOUND THEN RETURN QUERY SELECT 1002,'Source account not found'; RETURN; END IF;

    SELECT * INTO v_to_acc FROM accounts WHERE account_number=p_to_account_number FOR UPDATE;
    IF NOT FOUND THEN RETURN QUERY SELECT 1003,'Destination account not found'; RETURN; END IF;

    IF NOT v_from_acc.is_active THEN RETURN QUERY SELECT 1004,'Source inactive'; RETURN; END IF;
    IF NOT v_to_acc.is_active THEN RETURN QUERY SELECT 1005,'Destination inactive'; RETURN; END IF;

    SELECT daily_limit_kzt INTO v_customer_limit FROM customers WHERE customer_id=v_from_acc.customer_id AND status='active';
    IF NOT FOUND THEN RETURN QUERY SELECT 1006,'Sender inactive'; RETURN; END IF;

    IF p_currency='KZT' THEN
        v_rate := 1;
    ELSE
        SELECT rate INTO v_rate FROM exchange_rates
        WHERE from_currency=p_currency AND to_currency='KZT'
          AND valid_from <= now() AND (valid_to IS NULL OR valid_to >= now())
        ORDER BY valid_from DESC LIMIT 1;
        IF v_rate IS NULL THEN RETURN QUERY SELECT 1010,'Rate missing'; RETURN; END IF;
    END IF;

    v_amount_kzt := ROUND(p_amount * v_rate,2);

    SELECT COALESCE(SUM(amount_kzt),0) INTO v_today_total
    FROM transactions t
    WHERE t.from_account_id IN (SELECT account_id FROM accounts WHERE customer_id=v_from_acc.customer_id)
      AND t.created_at::date=current_date AND t.status='completed';

    IF v_today_total + v_amount_kzt > v_customer_limit THEN RETURN QUERY SELECT 1011,'Daily limit exceeded'; RETURN; END IF;

    EXECUTE 'SAVEPOINT '||v_save;

    BEGIN
        DECLARE
            v_debit_amount NUMERIC;
            v_conv_src NUMERIC := 1;
            v_conv_to NUMERIC := 1;
        BEGIN
            IF p_currency=v_from_acc.currency THEN
                v_debit_amount := p_amount;
            ELSE
                SELECT rate INTO v_conv_src FROM exchange_rates WHERE from_currency=p_currency AND to_currency=v_from_acc.currency ORDER BY valid_from DESC LIMIT 1;
                IF v_conv_src IS NULL THEN
                    SELECT rate INTO v_conv_src FROM exchange_rates WHERE from_currency=p_currency AND to_currency='KZT' ORDER BY valid_from DESC LIMIT 1;
                    SELECT rate INTO v_conv_to FROM exchange_rates WHERE from_currency='KZT' AND to_currency=v_from_acc.currency ORDER BY valid_from DESC LIMIT 1;
                    v_debit_amount := p_amount * v_conv_src * v_conv_to;
                ELSE
                    v_debit_amount := p_amount * v_conv_src;
                END IF;
            END IF;

            IF v_from_acc.balance < v_debit_amount THEN
                EXECUTE 'ROLLBACK TO SAVEPOINT '||v_save;
                RETURN QUERY SELECT 1013,'Insufficient funds';
                RETURN;
            END IF;

            DECLARE
                v_credit_amount NUMERIC;
                v_rate_dest NUMERIC;
            BEGIN
                IF p_currency=v_to_acc.currency THEN
                    v_credit_amount := p_amount;
                ELSE
                    SELECT rate INTO v_rate_dest FROM exchange_rates WHERE from_currency=p_currency AND to_currency=v_to_acc.currency ORDER BY valid_from DESC LIMIT 1;
                    IF v_rate_dest IS NULL THEN
                        SELECT rate INTO v_rate_dest FROM exchange_rates WHERE from_currency=p_currency AND to_currency='KZT' ORDER BY valid_from DESC LIMIT 1;
                        SELECT rate INTO v_conv_to FROM exchange_rates WHERE from_currency='KZT' AND to_currency=v_to_acc.currency ORDER BY valid_from DESC LIMIT 1;
                        v_credit_amount := p_amount * v_rate_dest * v_conv_to;
                    ELSE
                        v_credit_amount := p_amount * v_rate_dest;
                    END IF;
                END IF;

                UPDATE accounts SET balance=balance - v_debit_amount WHERE account_id=v_from_acc.account_id;
                UPDATE accounts SET balance=balance + v_credit_amount WHERE account_id=v_to_acc.account_id;

                INSERT INTO transactions(from_account_id,to_account_id,amount,currency,exchange_rate,amount_kzt,type,status,created_at,completed_at,description)
                VALUES(v_from_acc.account_id,v_to_acc.account_id,p_amount,p_currency,v_rate,v_amount_kzt,'transfer','completed',now(),now(),p_description);

                RETURN QUERY SELECT 0,'OK';
                RETURN;
            END;
        END;
    EXCEPTION WHEN OTHERS THEN
        EXECUTE 'ROLLBACK TO SAVEPOINT '||v_save;
        RETURN QUERY SELECT 1999,'Error';
        RETURN;
    END;
END;
$$;

-- task 2

CREATE OR REPLACE VIEW customer_balance_summary AS
SELECT
  c.customer_id,
  c.full_name,
  c.iin,
  a.account_id,
  a.account_number,
  a.currency,
  a.balance,
  ROUND(a.balance * COALESCE(er.rate,1)::numeric,2) AS balance_kzt,
  c.daily_limit_kzt,
  CASE WHEN c.daily_limit_kzt > 0
       THEN ROUND((COALESCE(t.sum_kzt,0)/c.daily_limit_kzt)*100,2)
       END AS daily_limit_util_percent,
  SUM(ROUND(a.balance * COALESCE(er.rate,1)::numeric,2)) OVER (PARTITION BY c.customer_id) AS total_balance_kzt,
  RANK() OVER (ORDER BY SUM(ROUND(a.balance * COALESCE(er.rate,1)::numeric,2)) OVER (PARTITION BY c.customer_id) DESC)
FROM customers c
JOIN accounts a ON a.customer_id=c.customer_id
LEFT JOIN LATERAL (
  SELECT rate FROM exchange_rates WHERE from_currency=a.currency AND to_currency='KZT'
  ORDER BY valid_from DESC LIMIT 1
) er ON true
LEFT JOIN LATERAL (
  SELECT SUM(amount_kzt) AS sum_kzt
  FROM transactions t2
  WHERE t2.from_account_id IN (SELECT account_id FROM accounts WHERE customer_id=c.customer_id)
    AND t2.created_at::date=current_date AND t2.status='completed'
) t ON true;

CREATE OR REPLACE VIEW daily_transaction_report AS
SELECT
  date_trunc('day',created_at) AS day,
  type,
  COUNT(*) AS cnt,
  SUM(amount_kzt) AS total_volume_kzt,
  ROUND(AVG(amount_kzt)::numeric,2) AS avg_amount_kzt,
  SUM(SUM(amount_kzt)) OVER (ORDER BY date_trunc('day',created_at)) AS running_total_kzt,
  LAG(SUM(amount_kzt)) OVER (ORDER BY date_trunc('day',created_at)) AS prev_day_total_kzt,
  CASE
    WHEN LAG(SUM(amount_kzt)) OVER (ORDER BY date_trunc('day',created_at)) IS NULL THEN NULL
    ELSE ROUND(
      (SUM(amount_kzt) - LAG(SUM(amount_kzt)) OVER (ORDER BY date_trunc('day',created_at)))
      / LAG(SUM(amount_kzt)) OVER (ORDER BY date_trunc('day',created_at)) * 100
    ,2)
  END AS day_over_day_growth_pct
FROM transactions
GROUP BY date_trunc('day',created_at), type;

CREATE OR REPLACE VIEW suspicious_activity_view
WITH (security_barrier=true) AS
SELECT
  t.transaction_id,
  t.from_account_id,
  t.to_account_id,
  t.amount,
  t.currency,
  t.amount_kzt,
  t.created_at,
  (t.amount_kzt > 5000000) AS flag_large_amount,
  EXISTS (
    SELECT 1 FROM (
      SELECT count(*) AS cnt
      FROM transactions t2
      WHERE t2.from_account_id=t.from_account_id
        AND t2.created_at >= t.created_at - interval '1 hour'
        AND t2.created_at <= t.created_at + interval '1 hour'
      GROUP BY date_trunc('hour',t2.created_at)
    ) s WHERE s.cnt > 10
  ) AS flag_many_in_hour,
  EXISTS(
    SELECT 1 FROM transactions t3
    WHERE t3.from_account_id=t.from_account_id
      AND t3.created_at > t.created_at - interval '1 minute'
      AND t3.created_at < t.created_at
  ) AS flag_rapid_sequence
FROM transactions t
WHERE t.status='completed';

-- task 3

CREATE INDEX idx_iin ON customers(iin);
CREATE INDEX idx_acc_customer_currency ON accounts(customer_id,currency) INCLUDE(balance);
CREATE INDEX idx_acc_hash ON accounts USING HASH(account_number);
CREATE INDEX idx_acc_partial ON accounts(account_number) WHERE is_active=true;
CREATE INDEX idx_email_lower ON customers(lower(email));
CREATE INDEX idx_audit_old ON audit_log USING GIN(old_values);
CREATE INDEX idx_audit_new ON audit_log USING GIN(new_values);
CREATE INDEX idx_tx_brin ON transactions USING BRIN(created_at);

-- task 4

CREATE OR REPLACE FUNCTION process_salary_batch(
    p_company_account_number TEXT,
    p_payments JSONB,
    p_initiator TEXT DEFAULT 'system'
)
RETURNS JSONB
LANGUAGE plpgsql AS
$$
DECLARE
    v_company_acc RECORD;
    v_total NUMERIC := 0;
    v_payment JSONB;
    v_iin TEXT;
    v_amount NUMERIC;
    v_description TEXT;
    v_failed JSONB := '[]'::jsonb;
    v_success INT := 0;
    v_failed_count INT := 0;
BEGIN
    SELECT * INTO v_company_acc FROM accounts WHERE account_number=p_company_account_number FOR UPDATE;
    IF NOT FOUND THEN RETURN jsonb_build_object('status','error','message','company account not found'); END IF;

    PERFORM pg_advisory_lock(hashtext(p_company_account_number)::bigint);

    FOR v_payment IN SELECT * FROM jsonb_array_elements(p_payments)
    LOOP
        v_iin := v_payment->>'iin';
        v_amount := (v_payment->>'amount')::numeric;
        IF v_amount IS NULL OR v_amount <= 0 THEN
            v_failed := v_failed || jsonb_build_object('iin',v_iin,'amount',v_amount,'reason','invalid amount');
            v_failed_count := v_failed_count + 1;
            CONTINUE;
        END IF;
        v_total := v_total + v_amount;
    END LOOP;

    IF v_company_acc.balance < v_total THEN
        PERFORM pg_advisory_unlock(hashtext(p_company_account_number)::bigint);
        RETURN jsonb_build_object('status','error','message','insufficient funds');
    END IF;

    CREATE TEMP TABLE tmp_batch_changes(to_account_id BIGINT, amount NUMERIC) ON COMMIT DROP;

    FOR v_payment IN SELECT * FROM jsonb_array_elements(p_payments)
    LOOP
        v_iin := v_payment->>'iin';
        v_amount := (v_payment->>'amount')::numeric;
        v_description := v_payment->>'description';

        DECLARE
            v_cust BIGINT;
            v_acc RECORD;
        BEGIN
            SELECT customer_id INTO v_cust FROM customers WHERE iin=v_iin LIMIT 1;
            IF NOT FOUND THEN
                v_failed := v_failed || jsonb_build_object('iin',v_iin,'amount',v_amount,'reason','customer not found');
                v_failed_count := v_failed_count + 1;
                CONTINUE;
            END IF;

            SELECT * INTO v_acc FROM accounts WHERE customer_id=v_cust AND currency='KZT' AND is_active=true LIMIT 1;
            IF NOT FOUND THEN
                SELECT * INTO v_acc FROM accounts WHERE customer_id=v_cust AND is_active=true LIMIT 1;
            END IF;

            IF NOT FOUND THEN
                v_failed := v_failed || jsonb_build_object('iin',v_iin,'amount',v_amount,'reason','recipient account not found');
                v_failed_count := v_failed_count + 1;
                CONTINUE;
            END IF;

            INSERT INTO tmp_batch_changes VALUES(v_acc.account_id,v_amount);
            v_success := v_success + 1;

            INSERT INTO transactions(from_account_id,to_account_id,amount,currency,exchange_rate,amount_kzt,type,status,created_at,description)
            VALUES(v_company_acc.account_id,v_acc.account_id,v_amount,'KZT',1,v_amount,'salary','pending',now(),v_description);
        END;
    END LOOP;

    UPDATE accounts SET balance = balance - sub.total_out
    FROM (SELECT SUM(amount) AS total_out FROM tmp_batch_changes) sub
    WHERE accounts.account_id=v_company_acc.account_id;

    UPDATE accounts a SET balance = a.balance + t.amount
    FROM tmp_batch_changes t
    WHERE a.account_id=t.to_account_id;

    UPDATE transactions SET status='completed', completed_at=now()
    WHERE from_account_id=v_company_acc.account_id AND status='pending';

    INSERT INTO salary_batch_runs(company_account_id,total_amount,successful_count,failed_count,failed_details,started_at,finished_at)
    VALUES(v_company_acc.account_id,(SELECT COALESCE(SUM(amount),0) FROM tmp_batch_changes),v_success,v_failed_count,v_failed,now(),now());

    PERFORM pg_advisory_unlock(hashtext(p_company_account_number)::bigint);

    RETURN jsonb_build_object('status','ok','successful_count',v_success,'failed_count',v_failed_count,'failed_details',v_failed);
END;
$$;

CREATE MATERIALIZED VIEW salary_batch_summary AS
SELECT * FROM salary_batch_runs ORDER BY started_at DESC;


EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM accounts WHERE account_number = 'KZ01ACC0000000001';

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM accounts WHERE customer_id = 1 AND currency = 'KZT';

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM audit_log WHERE new_values @> '{"changed_by":"system"}';

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM accounts WHERE is_active = true AND account_number = 'KZ01ACC0000000001';

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM customers WHERE lower(email) = lower('jotaro@example.com');


-- Test cases
SELECT * FROM process_transfer('KZ01ACC0000000002','KZ02ACC0000000003', 10, 'USD', 'test transfer', 'tester');

SELECT * FROM process_transfer('KZ01ACC0000000002','KZ02ACC0000000003', 100000000, 'USD', 'too big', 'tester');

UPDATE customers SET status='blocked' WHERE customer_id=1;
SELECT * FROM process_transfer('KZ01ACC0000000001','KZ02ACC0000000003', 100, 'KZT', 'blocked test');
UPDATE customers SET status='active' WHERE customer_id=1;

UPDATE customers SET daily_limit_kzt = 1000 WHERE customer_id = 1;
INSERT INTO transactions(from_account_id,to_account_id,amount,currency,exchange_rate,amount_kzt,type,status,created_at,completed_at,description)
VALUES ((SELECT account_id FROM accounts WHERE account_number='KZ01ACC0000000001'),
        (SELECT account_id FROM accounts WHERE account_number='KZ02ACC0000000003'),
        900,'KZT',1,900,'transfer','completed',now(),now(),'today prefill');
SELECT * FROM process_transfer('KZ01ACC0000000001','KZ02ACC0000000003', 200, 'KZT', 'limit test');
UPDATE customers SET daily_limit_kzt = 5000000 WHERE customer_id = 1;

SELECT process_salary_batch(
  'KZ10ACC0000000101',
  '[
    {"iin":"870101123456","amount":100000,"description":"May salary"},
    {"iin":"880202234567","amount":80000,"description":"May salary"},
    {"iin":"950909901234","amount":70000,"description":"May salary"}
  ]'::jsonb
);

UPDATE accounts SET balance = 1000 WHERE account_number = 'KZ10ACC0000000101';
SELECT process_salary_batch(
  'KZ10ACC0000000101',
  '[
    {"iin":"870101123456","amount":100000,"description":"May salary"}
  ]'::jsonb
);
UPDATE accounts SET balance = 10000000 WHERE account_number = 'KZ10ACC0000000101';
