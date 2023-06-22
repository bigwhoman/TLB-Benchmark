CREATE TABLE users
(
    id          INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    first_name  TEXT    NOT NULL,
    last_name   TEXT    NOT NULL,
    address     TEXT    NOT NULL,
    age         INTEGER NOT NULL,
    coordinates REAL
);
CREATE TABLE goods
(
    id        INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name      TEXT    NOT NULL,
    price     INTEGER NOT NULL,
    available BOOLEAN NOT NULL
);
CREATE INDEX idx_goods_available ON goods (available);
CREATE TABLE orders
(
    user_id       INTEGER NOT NULL,
    good_id       INTEGER NOT NULL,
    order_date    TEXT    NOT NULL,
    delivery_time TEXT,
    FOREIGN KEY (user_id) REFERENCES users (id),
    FOREIGN KEY (good_id) REFERENCES goods (id)
);
