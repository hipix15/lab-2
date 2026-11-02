DROP TABLE IF EXISTS "selected_correspondence";

CREATE TABLE "selected_correspondence" AS
SELECT c."tracking_number", c."mail_type_code", c."weight_g", c."stamps_amount",
       a."post_office_code", a."acceptance_datetime", a."total_shipping_cost", a."is_paid", a."shipping_datetime"
FROM "correspondence" c
JOIN "acceptance" a ON c."tracking_number" = a."tracking_number"
WHERE c."stamps_amount" <> a."total_shipping_cost";

ALTER TABLE "selected_correspondence" ADD PRIMARY KEY ("tracking_number");