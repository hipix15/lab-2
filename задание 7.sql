SELECT "tracking_number", COUNT(DISTINCT "post_office_code") AS "paid_office_count"
FROM "selected_correspondence"
WHERE "is_paid" = TRUE
GROUP BY "tracking_number";