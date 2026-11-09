-- 26 вариант


-- 1. Вывести трек-номера для всех отправлений, где сумма марок не совпадает с итоговой стоимостью отправки.

SELECT DISTINCT c.tracking_number
FROM correspondence AS c
JOIN mail_acceptance AS ma
    ON ma.tracking_number = c.tracking_number
WHERE c.stamp_amount IS DISTINCT FROM ma.total_shipping_cost
ORDER BY c.tracking_number;


-- 2. Вывести информацию о корреспонденции, отправленной за предыдущие 30 дней.

SELECT
    c.tracking_number,
    c.correspondence_type_code,
    c.weight_g,
    c.length_cm,
    c.width_cm,
    c.height_cm,
    c.sender_code,
    c.stamp_amount,
    ma.postal_office_code,
    ma.accepted_at,
    ma.declared_value,
    ma.total_shipping_cost,
    ma.paid,
    ma.sent_at
FROM correspondence AS c
JOIN mail_acceptance AS ma
    ON ma.tracking_number = c.tracking_number
WHERE ma.sent_at >= LOCALTIMESTAMP - INTERVAL '30 days'
  AND ma.sent_at <= LOCALTIMESTAMP
ORDER BY ma.sent_at DESC, c.tracking_number;


-- 3. Создать таблицу, содержащую данные 1 запроса с указанием информации о приеме и отправке корреспонденции.

-- При повторном запуске скрипта таблица результатов будет пересоздана.
DROP TABLE IF EXISTS query_3_results;

CREATE TABLE query_3_results AS
SELECT
    c.tracking_number,
    c.correspondence_type_code,
    c.weight_g,
    c.length_cm,
    c.width_cm,
    c.height_cm,
    c.sender_code,
    c.stamp_amount,
    ma.postal_office_code,
    ma.accepted_at,
    ma.declared_value,
    ma.total_shipping_cost,
    ma.paid,
    ma.sent_at
FROM correspondence AS c
JOIN mail_acceptance AS ma
    ON ma.tracking_number = c.tracking_number
WHERE c.stamp_amount IS DISTINCT FROM ma.total_shipping_cost;

-- Составной ключ различает события одного трек-номера
-- в разных отделениях или в разное время.
ALTER TABLE query_3_results
ADD CONSTRAINT pk_query_3_results
PRIMARY KEY (tracking_number, postal_office_code, accepted_at);


-- 4. Добавить в созданную таблицу все посылки, которые находились на каком-либо отделении больше недели.

-- Замените 3 на фактический код посылки, если в ваших данных он другой.
-- Для неотправленных посылок длительность считается до текущего времени.
INSERT INTO query_3_results (
    tracking_number,
    correspondence_type_code,
    weight_g,
    length_cm,
    width_cm,
    height_cm,
    sender_code,
    stamp_amount,
    postal_office_code,
    accepted_at,
    declared_value,
    total_shipping_cost,
    paid,
    sent_at
)
SELECT
    c.tracking_number,
    c.correspondence_type_code,
    c.weight_g,
    c.length_cm,
    c.width_cm,
    c.height_cm,
    c.sender_code,
    c.stamp_amount,
    ma.postal_office_code,
    ma.accepted_at,
    ma.declared_value,
    ma.total_shipping_cost,
    ma.paid,
    ma.sent_at
FROM correspondence AS c
JOIN mail_acceptance AS ma
    ON ma.tracking_number = c.tracking_number
WHERE c.correspondence_type_code = 3
  AND COALESCE(ma.sent_at, LOCALTIMESTAMP) - ma.accepted_at
      > INTERVAL '7 days'
ON CONFLICT (tracking_number, postal_office_code, accepted_at)
DO NOTHING;


-- 5. В созданной таблице убрать отметку об оплате для всех посылок, если для оплаты итоговой стоимости требуется сдача с купюр номиналом 50, 100 и 200 рублей.

-- Предполагается, что итоговую стоимость можно оплатить без сдачи,
-- если она кратна 50 рублям.
-- Замените 3 на фактический код посылки, если в ваших данных он другой.
UPDATE query_3_results
SET paid = FALSE
WHERE correspondence_type_code = 3
  AND paid = TRUE
  AND MOD(total_shipping_cost, 50::numeric) <> 0;


-- 6. Удалить из созданной таблицы все трек-номера, в записи которых все цифры одинаковые.

DELETE FROM query_3_results
WHERE regexp_replace(tracking_number, '[^0-9]', '', 'g')
      ~ E'^([0-9])\\1*$';


-- 7. Посчитать количество почтовых отделений, на которых была произведена оплата для каждого трек-номера отправленной корреспонденции.

WITH sent_tracking AS (
    SELECT DISTINCT tracking_number
    FROM mail_acceptance
    WHERE sent_at IS NOT NULL
)
SELECT
    st.tracking_number,
    COUNT(DISTINCT ma.postal_office_code)
        FILTER (WHERE ma.paid = TRUE) AS paid_post_office_count
FROM sent_tracking AS st
LEFT JOIN mail_acceptance AS ma
    ON ma.tracking_number = st.tracking_number
GROUP BY st.tracking_number
ORDER BY st.tracking_number;