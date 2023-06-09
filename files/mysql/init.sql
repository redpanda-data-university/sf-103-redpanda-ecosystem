CREATE TABLE pg_public_purchases (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    product_id   INT,
    quantity     INT,
    customer_id  INT,
    purchase_date TIMESTAMP,
    price        DECIMAL(10, 2),
    currency     VARCHAR(50)
);