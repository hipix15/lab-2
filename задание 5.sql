UPDATE "selected_correspondence"
SET "is_paid" = FALSE
WHERE ("total_shipping_cost" % 50) <> 0;