-- 26 вариант

-- 1. Вывести трек-номера для всех отправлений, где сумма марок не совпадает с итоговой стоимостью отправки.

SELECT DISTINCT c.tracking_number
FROM correspondence AS c
JOIN mail_acceptance AS ma
    ON ma.tracking_number = c.tracking_number
WHERE ma.total_shipping_cost IS NOT NULL
  AND COALESCE(c.stamp_amount, 0) <> ma.total_shipping_cost
ORDER BY c.tracking_number;


-- 2. Вывести информацию о корреспонденции, отправленной за предыдущие 30 дней.

SELECT DISTINCT
    c.tracking_number,
    c.correspondence_type_code,
    c.weight_g,
    c.length_cm,
    c.width_cm,
    c.height_cm,
    c.sender_code,
    c.stamp_amount
FROM correspondence AS c
JOIN mail_acceptance AS ma
    ON ma.tracking_number = c.tracking_number
WHERE ma.sent_at >= CURRENT_DATE - INTERVAL '30 days'
  AND ma.sent_at <= CURRENT_TIMESTAMP
ORDER BY c.tracking_number;


-- 3. Создать таблицу, содержащую данные 1 запроса с указанием информации о приеме и отправке корреспонденции.

DROP TABLE IF EXISTS query_3_results;

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
INTO query_3_results
FROM correspondence AS c
JOIN mail_acceptance AS ma
    ON ma.tracking_number = c.tracking_number
WHERE ma.total_shipping_cost IS NOT NULL
  AND COALESCE(c.stamp_amount, 0) <> ma.total_shipping_cost;


-- 4. Добавить в созданную таблицу все посылки, которые находились на каком-либо отделении больше недели.

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
  AND (COALESCE(ma.sent_at::timestamp, CURRENT_TIMESTAMP::timestamp) - ma.accepted_at::timestamp) > INTERVAL '7 days'
  AND NOT EXISTS (
      SELECT 1
      FROM query_3_results AS q
      WHERE q.tracking_number = c.tracking_number
        AND q.postal_office_code IS NOT DISTINCT FROM ma.postal_office_code
        AND q.accepted_at IS NOT DISTINCT FROM ma.accepted_at
  );


-- 5. В созданной таблице убрать отметку об оплате для всех посылок, если для оплаты итоговой стоимости требуется сдача с купюр номиналом 50, 100 и 200 рублей.

UPDATE query_3_results
SET paid = FALSE
WHERE correspondence_type_code = 3
  AND paid = TRUE
  AND MOD(total_shipping_cost::numeric, 50) <> 0;


-- 6. Удалить из созданной таблицы все трек-номера, в записи которых все цифры одинаковые.

DELETE FROM query_3_results
WHERE regexp_replace(tracking_number::text, '[^0-9]', '', 'g') ~ '^([0-9])\1*$';


-- 7. Посчитать количество почтовых отделений, на которых была произведена оплата для каждого трек-номера отправленной корреспонденции.

SELECT
    tracking_number,
    COUNT(DISTINCT postal_office_code) FILTER (WHERE paid = TRUE) AS paid_post_office_count
FROM mail_acceptance
GROUP BY tracking_number
HAVING COUNT(sent_at) > 0
ORDER BY tracking_number;
