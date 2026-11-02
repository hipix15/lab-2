SELECT c.*, a."acceptance_datetime", a."shipping_datetime"
FROM "correspondence" c
JOIN "acceptance" a ON c."tracking_number" = a."tracking_number"
WHERE a."acceptance_datetime" >= CURRENT_DATE - INTERVAL '30 days';