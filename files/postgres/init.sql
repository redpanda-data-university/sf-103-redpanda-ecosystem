CREATE TABLE purchases (
    id           SERIAL PRIMARY KEY,
    product_id   INT,
    quantity     INT,
    customer_id  INT,
    purchase_date TIMESTAMP,
    price        DECIMAL(10, 2),
    currency     VARCHAR(50)
);

INSERT INTO purchases (product_id, quantity, customer_id, purchase_date, price, currency) VALUES (1, 2, 1, '2023-06-01 10:00:00', 19.99, 'USD');
INSERT INTO purchases (product_id, quantity, customer_id, purchase_date, price, currency) VALUES (2, 1, 2, '2023-06-02 15:30:00', 12.99, 'USD');
INSERT INTO purchases (product_id, quantity, customer_id, purchase_date, price, currency) VALUES (3, 3, 3, '2023-06-03 09:45:00', 9.99, 'USD');