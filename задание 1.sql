SELECT c."tracking_number"
FROM "correspondence" c
JOIN "acceptance" a ON c."tracking_number" = a."tracking_number"
WHERE c."stamps_amount" <> a."total_shipping_cost";