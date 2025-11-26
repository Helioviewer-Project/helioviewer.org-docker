set -e
mariadb -h database -u root -p"${MARIADB_ROOT_PASSWORD}" -e "CREATE USER IF NOT EXISTS '${SUPERSET_USER}'@'%' IDENTIFIED BY '${SUPERSET_PASS}';"
cd /scripts
/setup_scripts/headless_setup.sh

