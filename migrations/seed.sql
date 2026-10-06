
INSERT INTO offices (id, name, latitude, longitude, radius_meters, is_active)
VALUES (
    'a0000000-0000-0000-0000-000000000001',
    'Chennai Tech Hub',
    13.082700,
    80.270700,
    10.0,
    TRUE
) ON CONFLICT (id) DO NOTHING;

INSERT INTO employees (id, employee_code, password_hash, full_name, role, office_id, is_active)
VALUES (
    'b0000000-0000-0000-0000-000000000001',
    'EMP1001',
    '$2a$10$6YDr.CsixdhSpxEAtLAgruMsAR25VyiaCo63DHm4HEE.ZC0WiwsGG',
    'John Doe',
    'EMPLOYEE',
    'a0000000-0000-0000-0000-000000000001',
    TRUE
) ON CONFLICT (employee_code) DO NOTHING;
