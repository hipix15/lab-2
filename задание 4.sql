INSERT INTO "selected_correspondence"
SELECT c."tracking_number", c."mail_type_code", c."weight_g", c."stamps_amount",
       a."post_office_code", a."acceptance_datetime", a."total_shipping_cost", a."is_paid", a."shipping_datetime"
FROM "correspondence" c
JOIN "acceptance" a ON c."tracking_number" = a."tracking_number"
WHERE (a."shipping_datetime" - a."acceptance_datetime") > INTERVAL '7 days'
ON CONFLICT ("tracking_number") DO NOTHING;