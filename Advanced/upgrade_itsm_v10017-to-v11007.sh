#!/bin/bash
# ============================================================
# upgrade_itsm_v10017-to-v11007.sh
# Nâng cấp GLPI từ 10.0.17 lên 11.0.7
# Hỗ trợ: Ubuntu 20.04 / 22.04 / 24.04 LTS
# Ngày: 01/06/2026
# ============================================================
set -eo pipefail

# ---------- Màu ----------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()   { echo -e "${RED}[ERROR]${NC} $1"; }

# ---------- Root check ----------
if [ "$(id -u)" -ne 0 ]; then
    err "Cần quyền root (sudo)."
    exit 1
fi

# ---------- Input ----------
cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║  NÂNG CẤP GLPI 10.0.17 → 11.0.7                        ║
║  Yêu cầu: PHP ≥ 8.2 | MariaDB ≥ 10.6 / MySQL ≥ 8.0     ║
╚══════════════════════════════════════════════════════════╝
EOF

read -p "Đường dẫn GLPI (VD: /var/www/html/itsm.atcom.vn): " GLPI_ROOT
GLPI_ROOT="${GLPI_ROOT:-/var/www/html/glpi}"
[ ! -d "$GLPI_ROOT" ] && { err "Không tìm thấy $GLPI_ROOT"; exit 1; }

read -p "DB name (VD: itsimdata1009): " dbname
read -p "DB user (VD: useritsmcloud): " dbuser
read -sp "DB password: " dbpass; echo ""
read -p "DB host [localhost]: " dbhost; dbhost="${dbhost:-localhost}"

BACKUP_DIR="/opt/glpi-backup-$(date +%Y%m%d_%H%M%S)"
GitGLPIversion="11.0.7"
GLPI_TMP="/opt/glpi-${GitGLPIversion}"

echo ""
echo "========== THÔNG TIN =========="
echo "GLPI root:    $GLPI_ROOT"
echo "Database:     $dbname @ $dbhost"
echo "Backup dir:   $BACKUP_DIR"
echo "================================"
read -p "Tiếp tục? (y/N): " confirm
[ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && { info "Hủy."; exit 0; }

# ============================================================
# Bước 1: Kiểm tra & sửa PHP (KHÔNG xoá gói cũ)
# ============================================================
echo ""
info "Bước 1/7: Kiểm tra PHP & Database..."

# --- Kiểm tra PHP có chạy không ---
PHP_BIN=""
for p in php8.3 php8.2 php8.1 php8.0 php; do
    if command -v "$p" &>/dev/null; then
        PHP_BIN="$p"
        break
    fi
done

PHP_VER="0"
PHP_MAJOR_MINOR="0"
if [ -n "$PHP_BIN" ]; then
    PHP_VER=$("$PHP_BIN" -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" 2>/dev/null || echo "0")
    PHP_MAJOR_MINOR="$PHP_VER"
fi

info "PHP binary: ${PHP_BIN:-không tìm thấy}, version: $PHP_VER"

# --- Đảm bảo PPA ondrej/php ---
if ! apt-cache policy | grep -q "ondrej/php"; then
    info "Thêm PPA ondrej/php..."
    add-apt-repository ppa:ondrej/php -y
fi

# Sửa codename trong PPA source nếu OS đã nâng cấp (VD: focal→jammy)
UBUNTU_CODENAME=$(lsb_release -cs 2>/dev/null || echo "jammy")
for ppa_src in /etc/apt/sources.list.d/ondrej-*.list /etc/apt/sources.list.d/ondrej-ubuntu-php-*.list; do
    [ -f "$ppa_src" ] && sed -i "s/ focal/ ${UBUNTU_CODENAME}/g; s/ jammy/ ${UBUNTU_CODENAME}/g" "$ppa_src" 2>/dev/null || true
done

apt update -y 2>/dev/null || true

# --- Nếu PHP < 8.2 hoặc không có, thử cài php8.3 NHƯNG không xoá gì cũ ---
PHP_NEEDS_INSTALL=false
if [ "$(printf '%s\n' "8.2" "$PHP_VER" | sort -V | head -n1)" != "8.2" ]; then
    PHP_NEEDS_INSTALL=true
    warn "PHP $PHP_VER chưa đạt yêu cầu (cần ≥ 8.2)."
    info "Đang thử cài PHP 8.3 (giữ nguyên các bản cũ)..."
    
    PHP83_AVAILABLE=false
    apt-cache show php8.3-fpm &>/dev/null && PHP83_AVAILABLE=true
    
    if [ "$PHP83_AVAILABLE" = true ]; then
        DEBIAN_FRONTEND=noninteractive apt install -y php8.3-fpm php8.3-cli php8.3-common php8.3-curl php8.3-gd php8.3-intl php8.3-mbstring php8.3-mysql php8.3-xml php8.3-zip php8.3-bz2 php8.3-bcmath php8.3-ldap php8.3-soap php8.3-xmlrpc php8.3-opcache
        update-alternatives --set php /usr/bin/php8.3 2>/dev/null || true
        systemctl enable php8.3-fpm 2>/dev/null || true
        PHP_BIN="php8.3"
        PHP_VER="8.3"
        PHP_MAJOR_MINOR="8.3"
        ok "Đã cài PHP 8.3."
    else
        err "Gói php8.3-fpm không có trong PPA cho Ubuntu $(lsb_release -cs 2>/dev/null || echo 'n/a')."
        err "GLPI 11.0 yêu cầu PHP ≥ 8.2."
        err ""
        err "Giải pháp 1: Nâng cấp Ubuntu lên 22.04 LTS (khuyến nghị)"
        err "  sudo do-release-upgrade"
        err ""
        err "Giải pháp 2: Cài PHP 8.3 từ nguồn khác (không chính thức)"
        err "  Tham khảo: https://github.com/phpleague/docker-php"
        err ""
        err "Giải pháp 3: Quay lại GLPI 10.0.x với PHP hiện tại"
        err "  php bin/console glpi:database:update (cho 10.0.x)"
        exit 1
    fi
fi

# --- Sửa extension name ldap trong php.ini cũ ---
for ini in /etc/php/${PHP_MAJOR_MINOR}/cli/php.ini /etc/php/${PHP_MAJOR_MINOR}/fpm/php.ini; do
    [ -f "$ini" ] && sed -i 's/extension\s*=\s*php-ldap\.so/extension=ldap.so/g; s/extension\s*=\s*php_ldap\.so/extension=ldap.so/g' "$ini" 2>/dev/null || true
done

# --- Cài các PHP modules còn thiếu ---
PHP_MODULES_REQUIRED=("bcmath" "bz2" "curl" "gd" "intl" "ldap" "mbstring" "mysqli" "xml" "zip")
PHP_MOD_LIST=$("$PHP_BIN" -m 2>/dev/null || true)
MISSING=()

for mod in "${PHP_MODULES_REQUIRED[@]}"; do
    if ! echo "$PHP_MOD_LIST" | grep -qi "^${mod}$"; then
        MISSING+=("$mod")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    warn "Thiếu PHP modules: ${MISSING[*]}"
    info "Đang cài bổ sung..."
    for mod in "${MISSING[@]}"; do
        case "$mod" in
            bcmath) pkg="php${PHP_MAJOR_MINOR}-bcmath" ;;
            mysqli) pkg="php${PHP_MAJOR_MINOR}-mysql" ;;
            ldap)   pkg="php${PHP_MAJOR_MINOR}-ldap" ;;
            gd)     pkg="php${PHP_MAJOR_MINOR}-gd" ;;
            *)      pkg="php${PHP_MAJOR_MINOR}-${mod}" ;;
        esac
        info "Cài: $pkg"
        DEBIAN_FRONTEND=noninteractive apt install -y "$pkg" || {
            DEBIAN_FRONTEND=noninteractive apt install -y "php-${mod}" || true
        }
    done
fi

# --- BẮT BUỘC: bcmath cho GLPI 11.0 ---
# Cài đặt mạnh mẽ hơn với kiểm tra đầy đủ
install_bcmath() {
    local phpver="$1"
    info "Đang cài php${phpver}-bcmath..."
    DEBIAN_FRONTEND=noninteractive apt install -y "php${phpver}-bcmath" 2>&1
    DEBIAN_FRONTEND=noninteractive apt install -y "php-bcmath" 2>&1 || true
    
    # Lấy đúng thư mục extension của PHP đang dùng
    PHP_EXT_DIR=$("$PHP_BIN" -r 'echo PHP_EXTENSION_DIR;' 2>/dev/null || echo "/usr/lib/php/20230831")
    info "PHP extension dir: $PHP_EXT_DIR"
    
    # Kích hoạt bằng phpenmod
    phpenmod -v "$phpver" bcmath 2>/dev/null || true
    
    # Tạo ini với đường dẫn TUYỆT ĐỐI để tránh load nhầm phiên bản
    MODS_DIR="/etc/php/${phpver}/mods-available"
    CLI_DIR="/etc/php/${phpver}/cli/conf.d"
    FPM_DIR="/etc/php/${phpver}/fpm/conf.d"
    BCMATH_SO="${PHP_EXT_DIR}/bcmath.so"
    
    mkdir -p "$MODS_DIR" "$CLI_DIR" "$FPM_DIR"
    
    if [ -f "$BCMATH_SO" ]; then
        echo "extension=${BCMATH_SO}" > "${MODS_DIR}/bcmath.ini"
        info "Ghi extension=${BCMATH_SO} vào bcmath.ini"
    elif [ -f "/usr/lib/php/20230831/bcmath.so" ]; then
        # Fallback hardcode cho PHP 8.3
        echo "extension=/usr/lib/php/20230831/bcmath.so" > "${MODS_DIR}/bcmath.ini"
        info "Ghi extension=/usr/lib/php/20230831/bcmath.so (fallback)"
    else
        echo "extension=bcmath" > "${MODS_DIR}/bcmath.ini"
    fi
    
    ln -sf "${MODS_DIR}/bcmath.ini" "${CLI_DIR}/20-bcmath.ini" 2>/dev/null || true
    ln -sf "${MODS_DIR}/bcmath.ini" "${FPM_DIR}/20-bcmath.ini" 2>/dev/null || true
    
    # Restart FPM
    systemctl restart "php${phpver}-fpm" 2>/dev/null || true
    
    # Kiểm tra
    if "$PHP_BIN" -r 'echo function_exists("bcadd") ? "1" : "0";' 2>/dev/null | grep -q 1; then
        ok "bcmath đã hoạt động."
        return 0
    fi
    
    # Liệt kê trạng thái để debug
    echo "--- Trạng thái bcmath ---"
    dpkg -l "php*-bcmath" 2>/dev/null | grep "^ii" || echo "(chưa cài package nào)"
    ls -la /etc/php/${phpver}/mods-available/bcmath.ini 2>/dev/null || echo "(không có bcmath.ini)"
    ls -la /etc/php/${phpver}/cli/conf.d/*bcmath* 2>/dev/null || echo "(không có symlink cli)"
    echo "Content ${MODS_DIR}/bcmath.ini:"
    cat "${MODS_DIR}/bcmath.ini" 2>/dev/null || echo "(không đọc được)"
    echo "PHP extension_dir: $PHP_EXT_DIR"
    ls -la "$BCMATH_SO" 2>/dev/null || echo "(không có $BCMATH_SO)"
    echo "---"
    return 1
}

# Kiểm tra bcmath
BCMATH_OK=false
if "$PHP_BIN" -r 'echo function_exists("bcadd") ? "1" : "0";' 2>/dev/null | grep -q 1; then
    BCMATH_OK=true
    ok "bcmath hoạt động."
else
    install_bcmath "$PHP_MAJOR_MINOR" && BCMATH_OK=true
fi

if [ "$BCMATH_OK" = false ]; then
    warn "bcmath CHƯA khả dụng dù đã cài. Thử khởi động lại PHP-FPM và kiểm tra lại..."
    systemctl restart "php${PHP_MAJOR_MINOR}-fpm"
    sleep 2
    "$PHP_BIN" -r 'echo function_exists("bcadd") ? "1" : "0";' 2>/dev/null | grep -q 1 && BCMATH_OK=true
    
    if [ "$BCMATH_OK" = false ]; then
        warn "========================================"
        warn "bcmath vẫn chưa hoạt động sau khi cài."
        warn "GLPI 11.0 yêu cầu bcmath."
        warn ""
        warn "Chạy thủ công các lệnh sau để khắc phục:"
        warn "  sudo apt update"
        warn "  sudo apt install php${PHP_MAJOR_MINOR}-bcmath php-bcmath"
        warn "  sudo phpenmod bcmath"
        warn "  sudo systemctl restart php${PHP_MAJOR_MINOR}-fpm"
        warn "  php -m | grep bcmath"
        warn "  php -r 'echo bcadd(1,1);'"
        warn "========================================"
    fi
fi

# --- Restart PHP-FPM ---
systemctl restart "php${PHP_MAJOR_MINOR}-fpm" 2>/dev/null || true

# --- Database check ---
DB_VERSION=$(mysql --version 2>/dev/null || echo "")
if echo "$DB_VERSION" | grep -qi "mariadb"; then
    MARIADB_VER=$(mysql --version 2>/dev/null | awk '{for(i=1;i<=NF;i++){if(match($i,/[0-9]+\.[0-9]+/)){print substr($i,RSTART,RLENGTH); exit}}}' || echo "0")
    [ "$MARIADB_VER" = "0" ] && MARIADB_VER=$(mariadb --version 2>/dev/null | awk '{for(i=1;i<=NF;i++){if(match($i,/[0-9]+\.[0-9]+/)){print substr($i,RSTART,RLENGTH); exit}}}' || echo "0")
    if [ "$(printf '%s\n' "10.6" "$MARIADB_VER" | sort -V | head -n1)" = "10.6" ]; then
        ok "MariaDB $MARIADB_VER OK."
    else
        err "MariaDB $MARIADB_VER < 10.6. Cần nâng cấp MariaDB."
        exit 1
    fi
elif echo "$DB_VERSION" | grep -qi "mysql"; then
    MYSQL_VER=$(mysql --version 2>/dev/null | awk '{for(i=1;i<=NF;i++){if(match($i,/[0-9]+\.[0-9]+/)){print substr($i,RSTART,RLENGTH); exit}}}' || echo "0")
    if [ "$(printf '%s\n' "8.0" "$MYSQL_VER" | sort -V | head -n1)" = "8.0" ]; then
        ok "MySQL $MYSQL_VER OK."
    else
        err "MySQL $MYSQL_VER < 8.0."
        exit 1
    fi
else
    err "Không tìm thấy MariaDB/MySQL."
    exit 1
fi

# ============================================================
# Bước 2: Backup
# ============================================================
echo ""; info "Bước 2/7: Backup..."
mkdir -p "$BACKUP_DIR"

MYSQL_CMD="mysql -u${dbuser} -p${dbpass} -h${dbhost}"
MYSQLDUMP_CMD="mysqldump -u${dbuser} -p${dbpass} -h${dbhost} --single-transaction --routines --events --triggers"

$MYSQL_CMD -e "USE ${dbname};" 2>/dev/null || { err "Không kết nối được DB $dbname."; exit 1; }
$MYSQLDUMP_CMD "$dbname" | gzip > "$BACKUP_DIR/database-${dbname}.sql.gz" && ok "DB backed up."

cd "$(dirname "$GLPI_ROOT")"
tar czf "$BACKUP_DIR/glpi-source.tar.gz" "$(basename "$GLPI_ROOT")" \
    --exclude="*/files/_dumps" --exclude="*/files/_cache" --exclude="*/files/_log" \
    --exclude="*/files/_sessions" --exclude="*/files/_tmp" 2>/dev/null && ok "Source backed up." || warn "Source backup skipped (tiếp tục)."
[ -d "$GLPI_ROOT/plugins" ] && tar czf "$BACKUP_DIR/glpi-plugins.tar.gz" -C "$GLPI_ROOT" plugins/ && ok "Plugins backed up."
[ -d "$GLPI_ROOT/marketplace" ] && tar czf "$BACKUP_DIR/glpi-marketplace.tar.gz" -C "$GLPI_ROOT" marketplace/ && ok "Marketplace backed up."
[ -f "$GLPI_ROOT/config/config_db.php" ] && cp "$GLPI_ROOT/config/config_db.php" "$BACKUP_DIR/" && ok "Config backed up."
ok "Backup hoàn tất: $BACKUP_DIR"

# ============================================================
# Bước 3: Tải GLPI 11.0.7
# ============================================================
echo ""; info "Bước 3/7: Tải GLPI $GitGLPIversion..."
cd /opt
if [ ! -f "glpi-${GitGLPIversion}.tgz" ]; then
    wget "https://github.com/glpi-project/glpi/releases/download/${GitGLPIversion}/glpi-${GitGLPIversion}.tgz" -O "glpi-${GitGLPIversion}.tgz"
fi
rm -rf /opt/glpi /opt/glpi-${GitGLPIversion}
tar xf "glpi-${GitGLPIversion}.tgz" -C /opt/
mv /opt/glpi "$GLPI_TMP"
ok "Đã tải và giải nén GLPI $GitGLPIversion."

# ============================================================
# Bước 4: Thay thế core GLPI (giữ config/plugins/files/marketplace)
# ============================================================
echo ""; info "Bước 4/7: Cập nhật core GLPI..."

# Maintenance mode ON (dùng cách cũ của 10.0.x)
MAINTENANCE_FILE="$GLPI_ROOT/config/maintenance.php"
echo "<?php return true;" > "$MAINTENANCE_FILE" 2>/dev/null && ok "Maintenance mode ON."

# Giữ lại các thư mục quan trọng
TMP_KEEP="/tmp/glpi-keep-$$"
mkdir -p "$TMP_KEEP"
for dir in config files plugins marketplace; do
    [ -d "$GLPI_ROOT/$dir" ] && cp -a "$GLPI_ROOT/$dir" "$TMP_KEEP/"
done
[ -f "$GLPI_ROOT/inc/config.php" ] && cp -a "$GLPI_ROOT/inc/config.php" "$TMP_KEEP/" 2>/dev/null || true

# Xoá core cũ (giữ lại thư mục đã backup)
find "$GLPI_ROOT" -mindepth 1 -maxdepth 1 \
    ! -name 'files' ! -name 'config' ! -name 'plugins' ! -name 'marketplace' \
    -exec rm -rf {} + 2>/dev/null || true

# Copy core mới
cp -a "$GLPI_TMP/"* "$GLPI_ROOT/"

# Khôi phục
for dir in config files plugins marketplace; do
    [ -d "$TMP_KEEP/$dir" ] && { rm -rf "$GLPI_ROOT/$dir"; cp -a "$TMP_KEEP/$dir" "$GLPI_ROOT/"; }
done
[ -f "$TMP_KEEP/config.php" ] && cp -a "$TMP_KEEP/config.php" "$GLPI_ROOT/inc/" 2>/dev/null || true
rm -rf "$TMP_KEEP"

# Xoá file install.php (bắt buộc sau upgrade)
rm -f "$GLPI_ROOT/install/install.php" 2>/dev/null || true

# GLPI 11.0 dùng config/config_db.php (giống 10.0.x)
# Kiểm tra và khôi phục từ backup nếu cần
if [ ! -f "$GLPI_ROOT/config/config_db.php" ]; then
    if [ -f "$BACKUP_DIR/config_db.php" ]; then
        cp "$BACKUP_DIR/config_db.php" "$GLPI_ROOT/config/config_db.php"
        info "Đã khôi phục config_db.php từ backup."
    else
        # Thử tìm trong TMP_KEEP backup
        TMP_KEEP_OLD=$(ls -d /tmp/glpi-keep-* 2>/dev/null | head -1)
        if [ -n "$TMP_KEEP_OLD" ] && [ -f "$TMP_KEEP_OLD/config/config_db.php" ]; then
            cp "$TMP_KEEP_OLD/config/config_db.php" "$GLPI_ROOT/config/config_db.php"
            info "Đã khôi phục config_db.php từ temp backup."
        fi
    fi
fi

# Luôn đảm bảo file tồn tại
if [ -f "$GLPI_ROOT/config/config_db.php" ]; then
    # Kiểm tra file có nội dung hợp lệ (có class DB extends)
    if ! head -5 "$GLPI_ROOT/config/config_db.php" 2>/dev/null | grep -q "class DB"; then
        warn "config_db.php có vẻ không hợp lệ. Thử restore từ backup..."
        [ -f "$BACKUP_DIR/config_db.php" ] && cp "$BACKUP_DIR/config_db.php" "$GLPI_ROOT/config/config_db.php"
    fi
fi

ok "Core GLPI 11.0.7 đã cập nhật."

# ============================================================
# Bước 5: Permissions
# ============================================================
echo ""; info "Bước 5/7: Phân quyền..."
chown -R www-data:www-data "$GLPI_ROOT/"
find "$GLPI_ROOT" -type d -exec chmod 755 {} \;
find "$GLPI_ROOT" -type f -exec chmod 644 {} \;
chmod -R 755 "$GLPI_ROOT/files/" "$GLPI_ROOT/config/" 2>/dev/null || true
for dir in _cache _log _sessions _tmp _uploads _dumps _lock _graphs _plugins; do
    [ -d "$GLPI_ROOT/files/$dir" ] && chown -R www-data:www-data "$GLPI_ROOT/files/$dir"
done
ok "Permissions OK."

# ============================================================
# Bước 6: Nâng cấp DB
# ============================================================
echo ""; info "Bước 6/7: Nâng cấp database schema 10.0 → 11.0..."

cd "$GLPI_ROOT"
SU=""
[ "$(id -u)" -eq 0 ] && SU="--allow-superuser"

# Kiểm tra config_db.php trước khi migration
if [ ! -f "config/config_db.php" ]; then
    err "Không tìm thấy config/config_db.php!"
    err "Khôi phục từ backup: cp $BACKUP_DIR/config_db.php $GLPI_ROOT/config/"
    exit 1
fi
CFG_DBUSER=$(sed -n "s/.*\\\$dbuser[[:space:]]*=[[:space:]]*'\([^']*\)'.*/\1/p" config/config_db.php 2>/dev/null || echo "?")
CFG_DBHOST=$(sed -n "s/.*\\\$dbhost[[:space:]]*=[[:space:]]*'\([^']*\)'.*/\1/p" config/config_db.php 2>/dev/null || echo "?")
CFG_DBNAME=$(sed -n "s/.*\\\$dbdefault[[:space:]]*=[[:space:]]*'\([^']*\)'.*/\1/p" config/config_db.php 2>/dev/null || echo "?")
CFG_DBPASS=$(sed -n "s/.*\\\$dbpassword[[:space:]]*=[[:space:]]*'\([^']*\)'.*/\1/p" config/config_db.php 2>/dev/null || echo "?")
info "config_db.php: user=$CFG_DBUSER host=$CFG_DBHOST db=$CFG_DBNAME"

# Test PHP MySQLi trực tiếp (giống cách GLPI kết nối)
info "Test PHP mysqli connection (host=$CFG_DBHOST)..."
cat > /tmp/test_mysqli.php << 'PHPEOF'
<?php
$host = $argv[1];
$user = $argv[2];
$pass = $argv[3];
$db   = $argv[4];
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
try {
    $m = new mysqli($host, $user, $pass, $db);
    echo "OK";
    $m->close();
} catch (Exception $e) {
    echo "FAIL: " . $e->getMessage();
}
PHPEOF
PHP_MYSQLI_TEST=$("$PHP_BIN" /tmp/test_mysqli.php "$CFG_DBHOST" "$CFG_DBUSER" "$CFG_DBPASS" "$CFG_DBNAME" 2>&1)
echo "PHP mysqli: $PHP_MYSQLI_TEST"

if echo "$PHP_MYSQLI_TEST" | grep -q "^OK$"; then
    ok "PHP mysqli connection OK."
    
    # Dù PHP mysqli OK, GLPI console vẫn fail.
    # Nguyên nhân: GLPI 11.0 có thể đã thay đổi DB layer.
    # Kiểm tra class DBmysql có tồn tại trong GLPI 11.0 không
    BCMYSQL_CLASS=""
    for d in src inc; do
        found=$(grep -rle "^class\s\+DBmysql\b" "$GLPI_TMP/$d" --include="*.php" 2>/dev/null | head -1)
        [ -n "$found" ] && BCMYSQL_CLASS="$found" && break
    done
    if [ -z "$BCMYSQL_CLASS" ]; then
        warn "GLPI 11.0 KHÔNG có class DBmysql — Config format đã thay đổi!"
        info "--- Tìm cấu hình DB mới trong GLPI 11.0 ---"
        
        # Tìm file cấu hình DB (symfony-style)
        SYMFONY_ENV=$(find "$GLPI_TMP" -maxdepth 2 -name ".env" -o -name ".env.local" 2>/dev/null | head -1)
        if [ -n "$SYMFONY_ENV" ]; then
            info "Tìm thấy .env file: $SYMFONY_ENV"
            cp "$SYMFONY_ENV" "$GLPI_ROOT/.env" 2>/dev/null || true
            DB_URL=$(grep "^DATABASE_URL" "$SYMFONY_ENV" 2>/dev/null)
            info "DB config trong .env: $DB_URL"
        fi
        
        ok "GLPI 11.0 dùng cơ chế config DB mới."
        warn "Chạy lại script để migration qua bước mới."
    else
        info "GLPI 11.0 có DBmysql class tại: $BCMYSQL_CLASS"
        DB_NAMESPACE=$(grep "^namespace " "$BCMYSQL_CLASS" 2>/dev/null | head -1 | sed 's/namespace //;s/;//')
        info "Namespace DBmysql: ${DB_NAMESPACE:-global}"
        
        # Test y hệt cách GLPI kết nối DB
        info "Chạy test DB connection theo đúng cách GLPI 11.0..."
        cat > /tmp/test_glpi_db.php << 'GLPITEST'
<?php
// Giả lập chính xác cách GLPI kết nối
require_once '/var/www/html/itsm.atcom.vn/config/config_db.php';
try {
    $db = new DB();
    if ($db->connected) {
        echo "GLPI_DB_OK\n";
        echo "Host: " . $db->dbhost . "\n";
        echo "User: " . $db->dbuser . "\n";
        echo "DB: " . $db->dbdefault . "\n";
    } else {
        echo "GLPI_DB_FAIL\n";
        echo "Error: " . ($db->dbh->connect_error ?? 'unknown') . "\n";
        echo "Errno: " . ($db->dbh->connect_errno ?? 'N/A') . "\n";
    }
} catch (Exception $e) {
    echo "GLPI_DB_EXCEPTION: " . $e->getMessage() . "\n";
    echo "File: " . $e->getFile() . ":" . $e->getLine() . "\n";
}
GLPITEST
        GLPI_DB_TEST=$("$PHP_BIN" /tmp/test_glpi_db.php 2>&1)
        echo "$GLPI_DB_TEST"
        
        if echo "$GLPI_DB_TEST" | grep -q "GLPI_DB_OK"; then
            ok "GLPI 11.0 DB connection OK (qua DBmysql class)."
        else
            warn "GLPI 11.0 DB connection FAILED (dù PHP mysqli test OK)."
            # Có thể do dbhost=localhost dùng socket vs TCP
            warn "Thử với dbhost=127.0.0.1 (TCP thay vì socket)..."
            sed -i "s/'localhost'/'127.0.0.1'/" "$GLPI_ROOT/config/config_db.php"
            GLPI_DB_TEST2=$("$PHP_BIN" /tmp/test_glpi_db.php 2>&1)
            echo "$GLPI_DB_TEST2"
            if echo "$GLPI_DB_TEST2" | grep -q "GLPI_DB_OK"; then
                ok "DB host phải dùng 127.0.0.1 thay vì localhost. Đã sửa."
            else
                err "Vẫn không kết nối được! Xem chi tiết bên trên."
                exit 1
            fi
        fi
        rm -f /tmp/test_glpi_db.php
    fi
else
    warn "PHP mysqli kết nối thất bại. Kiểm tra socket MySQL..."
    MYSQL_SOCK=$(mysql -u "$CFG_DBUSER" -p"$CFG_DBPASS" -h "$CFG_DBHOST" -e "SHOW VARIABLES LIKE 'socket'" 2>/dev/null | grep socket | awk '{print $2}')
    PHP_SOCK=$("$PHP_BIN" -r 'echo ini_get("mysqli.default_socket");' 2>/dev/null)
    info "MySQL socket path: $MYSQL_SOCK"
    info "PHP mysqli.default_socket: $PHP_SOCK"
    
    # Thử kết nối bằng TCP (127.0.0.1 thay vì localhost)
    info "Thử PHP mysqli qua TCP 127.0.0.1..."
    PHP_TCP_TEST=$("$PHP_BIN" /tmp/test_mysqli.php "127.0.0.1" "$CFG_DBUSER" "$CFG_DBPASS" "$CFG_DBNAME" 2>&1)
    echo "PHP mysqli via TCP: $PHP_TCP_TEST"
    
    if echo "$PHP_TCP_TEST" | grep -q "^OK$"; then
        warn "PHP chỉ kết nối được qua TCP, không qua socket."
        warn "Đổi dbhost từ 'localhost' → '127.0.0.1' trong config_db.php"
        sed -i "s/'localhost'/'127.0.0.1'/" config/config_db.php
        CFG_DBHOST="127.0.0.1"
        ok "Config updated: dbhost=127.0.0.1"
    else
        # Liệt kê MySQL sockets available
        info "Các MySQL socket files trên hệ thống:"
        find /var/run /var/lib/mysql -name "*.sock" 2>/dev/null || echo "(không tìm thấy)"
        find /tmp -name "*.sock" 2>/dev/null || true
        # Kiểm tra MySQL running
        systemctl status mariadb 2>/dev/null | head -5 || true
        systemctl status mysql 2>/dev/null | head -5 || true
        
        # Thử dùng credentials user nhập
        warn "Thử dùng credentials bạn đã nhập..."
        mysql -u "$dbuser" -p"$dbpass" -h "$dbhost" "$dbname" -e "SELECT 1" 2>/dev/null && {
            info "Credentials bạn nhập OK. Cập nhật config_db.php..."
            cat > "config/config_db.php" << PHPEOF
<?php
class DB extends DBmysql {
   public \$dbhost = '$dbhost';
   public \$dbuser = '$dbuser';
   public \$dbpassword = '$dbpass';
   public \$dbdefault = '$dbname';
}
PHPEOF
            ok "Đã cập nhật config_db.php."
        } || {
            err "KHÔNG THỂ KẾT NỐI DATABASE!"
            err "MySQL CLI OK nhưng PHP mysqli FAIL."
            err "Socket PHP ($PHP_SOCK) != MySQL socket ($MYSQL_SOCK)"
            err ""
            err "Fix: ln -sf $MYSQL_SOCK $PHP_SOCK"
            err "Hoặc sửa php.ini: mysqli.default_socket = $MYSQL_SOCK"
            exit 1
        }
    fi
fi
rm -f /tmp/test_mysqli.php

if [ -f "bin/console" ]; then
    if [ "$BCMATH_OK" = false ]; then
        warn "bcmath chưa khả dụng. GLPI 11.0 yêu cầu bcmath để nâng cấp DB."
        PHP_EXT_DIR=$("$PHP_BIN" -r 'echo PHP_EXTENSION_DIR;' 2>/dev/null || echo "/usr/lib/php/20230831")
        BCMATH_SO="${PHP_EXT_DIR}/bcmath.so"
        if [ -f "$BCMATH_SO" ]; then
            info "Thử load bcmath trực tiếp: -d extension=${BCMATH_SO}"
            "$PHP_BIN" -d "extension=${BCMATH_SO}" bin/console glpi:database:update --force --no-interaction $SU 2>&1 && {
                ok "DB migration thành công (bcmath load bằng -d)."
            } || {
                err "DB migration thất bại dù đã load bcmath."
                err "Chạy thủ công để xem lỗi chi tiết:"
                err "  cd $GLPI_ROOT && php -d extension=${BCMATH_SO} bin/console glpi:database:update --force --allow-superuser"
                exit 1
            }
        else
            err "Không tìm thấy $BCMATH_SO"
            err "Hãy cài bcmath bằng tay, sau đó chạy:"
            err "  cd $GLPI_ROOT && php bin/console glpi:database:update --force --allow-superuser"
            exit 1
        fi
    else
        info "Đang chạy DB migration (có thể mất vài phút)..."
        "$PHP_BIN" bin/console glpi:database:update --force --no-interaction $SU 2>&1 || {
            warn "Migration lần 1 thất bại. Thử clear cache và chạy lại..."
            rm -rf "$GLPI_ROOT/var/cache/"* "$GLPI_ROOT/files/_cache/"* 2>/dev/null || true
            "$PHP_BIN" bin/console glpi:database:update --force --no-interaction $SU 2>&1 || {
                err "DB migration thất bại. Chạy thủ công:"
                err "  cd $GLPI_ROOT && php bin/console glpi:database:update --force --allow-superuser"
                exit 1
            }
        }
        ok "Database schema đã nâng cấp."
    fi

    # Plugin upgrades
    "$PHP_BIN" bin/console glpi:plugin:install --all --force $SU 2>/dev/null || true

    # Clear cache
    "$PHP_BIN" bin/console cache:clear --no-interaction $SU 2>/dev/null || true
    "$PHP_BIN" bin/console glpi:cache:clear --no-interaction $SU 2>/dev/null || true
    rm -rf "$GLPI_ROOT/var/cache/"* "$GLPI_ROOT/files/_cache/"* 2>/dev/null || true
else
    warn "Không tìm thấy bin/console."
fi

# ============================================================
# Bước 7: Hoàn tất
# ============================================================
echo ""; info "Bước 7/7: Hoàn tất..."

# Maintenance OFF
rm -f "$MAINTENANCE_FILE" 2>/dev/null || true
ok "Maintenance mode OFF."

# Dọn dẹp
rm -rf /opt/glpi-${GitGLPIversion} /opt/glpi
ok "Dọn dẹp xong."

# Restart services
for svc in nginx apache2 "php${PHP_MAJOR_MINOR}-fpm" mariadb mysql; do
    systemctl is-active --quiet "$svc" 2>/dev/null && { systemctl restart "$svc" 2>/dev/null || true; }
done
ok "Services restarted."

# Kết quả
GLPI_DOMAIN=$(basename "$GLPI_ROOT")
echo ""
echo "=============================================="
echo -e "${GREEN}  NÂNG CẤP HOÀN TẤT! 10.0.17 → 11.0.7${NC}"
echo "=============================================="
echo "  Website:  https://${GLPI_DOMAIN}/"
echo "  Thư mục:  $GLPI_ROOT"
echo "  Backup:   $BACKUP_DIR"
echo ""
echo "  Kiểm tra: php bin/console glpi:system:status --allow-superuser"
echo "  Log lỗi:  tail -100 $GLPI_ROOT/files/_log/php-errors.log"
echo ""
echo "  Nếu lỗi DB, chạy lại:"
echo "    cd $GLPI_ROOT && php bin/console glpi:database:update --force --allow-superuser"
echo "=============================================="

if [ "$BCMATH_OK" = false ]; then
    echo ""
    echo -e "${YELLOW}⚠️  bcmath chưa khả dụng. Cần cài để GLPI hoạt động đầy đủ:${NC}"
    echo "  sudo apt install php${PHP_MAJOR_MINOR}-bcmath"
    echo "  sudo phpenmod bcmath"
    echo "  sudo systemctl restart php${PHP_MAJOR_MINOR}-fpm"
fi
echo ""
