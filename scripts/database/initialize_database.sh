set -e
cd /scripts
/setup_scripts/headless_setup.sh

# Create readonly user with SELECT permissions
mysql -h database -u root -p"${MARIADB_ROOT_PASSWORD}" <<EOF
CREATE USER IF NOT EXISTS '${SUPERSET_READ_USER}'@'%' IDENTIFIED BY '${SUPERSET_READ_PASS}';
GRANT SELECT ON ${HV_DB_NAME}.* TO '${SUPERSET_READ_USER}'@'%';
FLUSH PRIVILEGES;
EOF

echo "Created ${SUPERSET_READ_USER} user with SELECT permissions on ${HV_DB_NAME}.*"
