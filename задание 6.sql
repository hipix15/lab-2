DELETE FROM "selected_correspondence"
WHERE substring("tracking_number" from '[0-9]+') ~ '^([0-9])\1+$';