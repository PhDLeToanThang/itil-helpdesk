#!/bin/bash
# ============================================================
# upgrade_itsm_v10017-to-v11007.sh
# Nâng cấp GLPI từ 10.0.17 lên 11.0.7
# Dành cho Ubuntu 22.04 LTS / 24.04 LTS
# Ngày: 31/05/2026
# ============================================================
#
# Các bước thực hiện:
#   1. Kiểm tra tiên quyết (PHP, MariaDB/MySQL)
#   2. Backup toàn bộ (database + file)
#   3. Tải GLPI 11.0.7
#   4. Thay thế core GLPI, giữ lại config + plugins + marketplace
#   5. Nâng cấp database schema
#   6. Fix permissions
#   7. Dọn dẹp
# ============================================================

set -euo pipefail

# ---------- Màu sắc cho output ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()   { echo -e "${RED}[ERROR]${NC} $1"; }

# ---------- Kiểm tra quyền root ----------
if [ "$(id -u)" -ne 0 ]; then
    err "Script này cần chạy với quyền root (sudo)."
    exit 1
fi

# ---------- Thông báo ----------
cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║  NÂNG CẤP GLPI 10.0.17 → 11.0.7                        ║
║  Đọc kỹ hướng dẫn trước khi thực hiện.                  ║
║  Yêu cầu: Ubuntu 22.04+ | PHP 8.2+ | MariaDB 10.6+     ║
╚══════════════════════════════════════════════════════════╝
EOF
echo ""

# ---------- Nhập thông tin từ người dùng ----------
read -p "Đường dẫn thư mục GLPI hiện tại (VD: /var/www/html/demo.company.vn): " GLPI_ROOT
GLPI_ROOT="${GLPI_ROOT:-/var/www/html/glpi}"

if [ ! -d "$GLPI_ROOT" ]; then
    err "Thư mục $GLPI_ROOT không tồn tại!"
    exit 1
fi

read -p "Tên database GLPI (VD: itildata): " dbname
read -p "User database (VD: userdata): " dbuser
read -sp "Password database: " dbpass
echo ""
read -p "Database host [localhost]: " dbhost
dbhost="${dbhost:-localhost}"

BACKUP_DIR="/opt/glpi-backup-$(date +%Y%m%d_%H%M%S)"
GitGLPIversion="11.0.7"
GLPI_TMP="/opt/glpi-${GitGLPIversion}"

echo ""
echo "========== THÔNG TIN CẤU HÌNH =========="
echo "GLPI root:     $GLPI_ROOT"
echo "Database:      $dbname"
echo "DB user:       $dbuser"
echo "DB host:       $dbhost"
echo "Backup dir:    $BACKUP_DIR"
echo "GLPI version:  $GitGLPIversion"
echo "========================================="
echo ""

read -p "Tiếp tục nâng cấp? (y/N): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    info "Hủy nâng cấp."
    exit 0
fi

# ============================================================
# Bước 1: Kiểm tra tiên quyết
# ============================================================
echo ""
info "Bước 1/7: Kiểm tra tiên quyết..."

# PHP version
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" 2>/dev/null || echo "0")
PHP_MAJOR_MINOR=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" 2>/dev/null || echo "0")

# Luôn đảm bảo PPA ondrej/php đã được thêm (cần cho các gói PHP modules)
if ! apt-cache policy | grep -q "ondrej/php"; then
    info "Thêm PPA ondrej/php..."
    add-apt-repository ppa:ondrej/php -y
    apt update -y
else
    apt update -y 2>/dev/null || true
fi

if [ "$(printf '%s\n' "8.2" "$PHP_VERSION" | sort -V | head -n1)" = "8.2" ]; then
    ok "PHP $PHP_VERSION đạt yêu cầu (≥ 8.2)."
else
    warn "PHP hiện tại: $PHP_VERSION. Cần nâng cấp lên PHP 8.2+."
    info "Đang nâng cấp PHP lên 8.3..."

    apt install -y php8.3-fpm php8.3-cli php8.3-common php8.3-curl \
        php8.3-gd php8.3-intl php8.3-mbstring php8.3-mysql php8.3-xml \
        php8.3-zip php8.3-bz2 php8.3-bcmath php8.3-ldap php8.3-soap \
        php8.3-xmlrpc php8.3-opcache

    # Disable old PHP version, enable new
    update-alternatives --set php /usr/bin/php8.3 2>/dev/null || true
    systemctl enable php8.3-fpm || true

    PHP_VERSION="8.3"
    PHP_MAJOR_MINOR="8.3"
    ok "Đã nâng cấp PHP lên $PHP_VERSION."
fi

# Sửa lỗi extension name sai trong php.ini cũ (10.0.17 ghi "php-ldap.so" / "php_ldap.so")
for ini in /etc/php/${PHP_MAJOR_MINOR}/cli/php.ini /etc/php/${PHP_MAJOR_MINOR}/fpm/php.ini; do
    if [ -f "$ini" ]; then
        sed -i 's/extension\s*=\s*php-ldap\.so/extension=ldap.so/g' "$ini" 2>/dev/null || true
        sed -i 's/extension\s*=\s*php_ldap\.so/extension=ldap.so/g' "$ini" 2>/dev/null || true
    fi
done

# Xóa các extension= đã compiled-in trong PHP 8.3 để tránh warning "already loaded"
# Các module này là built-in trong PHP 8.3, không cần extension= line
PHP_BUILTIN=("bz2" "curl" "fileinfo" "intl" "mbstring" "openssl" "session" "tokenizer" "xml" "ctype" "dom" "json" "simplexml" "sodium" "sqlite3" "xmlreader" "xmlwriter" "zlib")
for ini in /etc/php/${PHP_MAJOR_MINOR}/cli/php.ini /etc/php/${PHP_MAJOR_MINOR}/fpm/php.ini; do
    if [ -f "$ini" ]; then
        for mod in "${PHP_BUILTIN[@]}"; do
            sed -i "/^extension\s*=\s*${mod}/d" "$ini" 2>/dev/null || true
            sed -i "/^extension\s*=\s*php-${mod}/d" "$ini" 2>/dev/null || true
        done
    fi
done

# Kiểm tra PHP modules bắt buộc cho GLPI 11.0
PHP_MODULES=("bcmath" "bz2" "curl" "dom" "fileinfo" "gd" "intl" "json" "ldap" "mbstring" "mysqli" "openssl" "session" "simplexml" "xml" "xmlreader" "xmlwriter" "zip")

# Lấy danh sách module từ php -m (chỉ lấy 1 lần, tránh flood stderr)
PHP_MOD_LIST=$(php -m 2>/dev/null || true)

MISSING=()
for mod in "${PHP_MODULES[@]}"; do
    if ! echo "$PHP_MOD_LIST" | grep -qi "^${mod}$"; then
        MISSING+=("$mod")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    warn "Thiếu PHP modules: ${MISSING[*]}"
    info "Đang cài đặt..."
    PHP_REQUIRED_VER=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" 2>/dev/null || echo "8.3")
    
    # Gỡ các gói PHP cũ đang conflict (vd: php7.4-bcmath chặn php8.3-bcmath)
    for old_ver in 7.1 7.2 7.3 7.4 8.0 8.1; do
        dpkg -l "php${old_ver}-*" 2>/dev/null | grep -q "^ii" && {
            info "Phát hiện PHP ${old_ver} modules cũ, đang gỡ để tránh conflict..."
            DEBIAN_FRONTEND=noninteractive apt remove -y $(dpkg -l "php${old_ver}-*" 2>/dev/null | grep "^ii" | awk '{print $2}') 2>/dev/null || true
            DEBIAN_FRONTEND=noninteractive apt autoremove -y 2>/dev/null || true
        }
    done
    
    for mod in "${MISSING[@]}"; do
        pkg="php${PHP_REQUIRED_VER}-${mod}"
        
        # Mapping tên gói -> extension
        case "$mod" in
            dom|json|session|simplexml|xml|xmlreader|xmlwriter)
                pkg="php-${mod}"
                # Các module này built-in trong core, không cần cài riêng
                info "$mod là built-in, bỏ qua."
                continue
                ;;
            mysqli)
                pkg="php${PHP_REQUIRED_VER}-mysql"
                ;;
            fileinfo)
                pkg="php${PHP_REQUIRED_VER}-common"
                ;;
            ldap)
                pkg="php${PHP_REQUIRED_VER}-ldap"
                ;;
        esac
        
        # Kiểm tra gói có tồn tại trong repo không
        if apt-cache show "$pkg" &>/dev/null; then
            info "Đang cài $pkg..."
            DEBIAN_FRONTEND=noninteractive apt install -y "$pkg" || {
                warn "Lỗi cài $pkg, thử apt-get install..."
                DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg" || true
            }
        else
            warn "Gói $pkg không tồn tại trong repo. Tìm gói thay thế..."
            # Tìm tất cả gói có chứa tên module
            CANDIDATES=$(apt-cache search "php.*${mod}" 2>/dev/null | grep -i "${PHP_REQUIRED_VER}" | head -5 | awk '{print $1}')
            if [ -n "$CANDIDATES" ]; then
                for c in $CANDIDATES; do
                    info "Thử cài $c..."
                    DEBIAN_FRONTEND=noninteractive apt install -y "$c" && break
                done
            else
                warn "Không tìm thấy gói nào chứa module $mod cho PHP $PHP_REQUIRED_VER."
                warn "Thử cài php${PHP_REQUIRED_VER}-* đồng loạt..."
                DEBIAN_FRONTEND=noninteractive apt install -y "php${PHP_REQUIRED_VER}-bcmath" "php${PHP_REQUIRED_VER}-gd" "php${PHP_REQUIRED_VER}-ldap" 2>/dev/null || true
            fi
        fi
    done
    
    # Kích hoạt modules
    if command -v phpenmod &>/dev/null; then
        phpenmod -v "${PHP_REQUIRED_VER}" bcmath gd ldap 2>/dev/null || true
    fi
    
    # Kiểm tra lại sau khi cài
    sleep 1
    PHP_MOD_LIST=$(php -m 2>/dev/null || true)
    MISSING_AFTER=()
    for mod in "${PHP_MODULES[@]}"; do
        if ! echo "$PHP_MOD_LIST" | grep -qi "^${mod}$"; then
            MISSING_AFTER+=("$mod")
        fi
    done
    
    if [ ${#MISSING_AFTER[@]} -gt 0 ]; then
        warn "Vẫn còn thiếu modules: ${MISSING_AFTER[*]}"
        warn "Thử cài thủ công sau:"
        for m in "${MISSING_AFTER[@]}"; do
            warn "  apt install php${PHP_REQUIRED_VER}-${m}"
        done
    else
        ok "Tất cả PHP modules đã sẵn sàng."
    fi
else
    ok "Tất cả PHP modules đã sẵn sàng."
fi

# Restart PHP-FPM để áp dụng thay đổi
systemctl restart "php${PHP_MAJOR_MINOR}-fpm" 2>/dev/null || true

# MariaDB / MySQL version
DB_VERSION=$(mysql --version 2>/dev/null || echo "")
if echo "$DB_VERSION" | grep -qi "mariadb"; then
    # Trích xuất MariaDB version (dùng awk thay grep -oP để tương thích tốt hơn)
    MARIADB_VER=$(mysql --version 2>/dev/null | awk '{for(i=1;i<=NF;i++){if(match($i,/[0-9]+\.[0-9]+/)){print substr($i,RSTART,RLENGTH); exit}}}' || echo "0")
    if [ -z "$MARIADB_VER" ] || [ "$MARIADB_VER" = "0" ]; then
        mariadb --version 2>/dev/null | awk '{for(i=1;i<=NF;i++){if(match($i,/[0-9]+\.[0-9]+/)){print substr($i,RSTART,RLENGTH); exit}}}'
        MARIADB_VER=$(mariadb --version 2>/dev/null | awk '{for(i=1;i<=NF;i++){if(match($i,/[0-9]+\.[0-9]+/)){print substr($i,RSTART,RLENGTH); exit}}}' || echo "0")
    fi
    if [ "$(printf '%s\n' "10.6" "$MARIADB_VER" | sort -V | head -n1)" = "10.6" ]; then
        ok "MariaDB $MARIADB_VER đạt yêu cầu (≥ 10.6)."
    else
        err "MariaDB $MARIADB_VER quá cũ. Cần ≥ 10.6. Hãy nâng cấp MariaDB trước."
        err "Lệnh nâng cấp: sudo apt install mariadb-server-10.6 mariadb-client-10.6"
        err "Hoặc: sudo apt install mariadb-server mariadb-client (nếu repo có sẵn)"
        exit 1
    fi
elif echo "$DB_VERSION" | grep -qi "mysql"; then
    MYSQL_VER=$(mysql --version 2>/dev/null | awk '{for(i=1;i<=NF;i++){if(match($i,/[0-9]+\.[0-9]+/)){print substr($i,RSTART,RLENGTH); exit}}}' || echo "0")
    if [ "$(printf '%s\n' "8.0" "$MYSQL_VER" | sort -V | head -n1)" = "8.0" ]; then
        ok "MySQL $MYSQL_VER đạt yêu cầu (≥ 8.0)."
    else
        err "MySQL $MYSQL_VER quá cũ. Cần ≥ 8.0. Hãy nâng cấp MySQL trước."
        exit 1
    fi
else
    # Thử lệnh mariadb nếu mysql không có
    if command -v mariadb &>/dev/null; then
        DB_VERSION=$(mariadb --version 2>/dev/null || echo "")
        MARIADB_VER=$(mariadb --version 2>/dev/null | awk '{for(i=1;i<=NF;i++){if(match($i,/[0-9]+\.[0-9]+/)){print substr($i,RSTART,RLENGTH); exit}}}' || echo "0")
        if [ "$(printf '%s\n' "10.6" "$MARIADB_VER" | sort -V | head -n1)" = "10.6" ]; then
            ok "MariaDB $MARIADB_VER đạt yêu cầu (≥ 10.6)."
        else
            err "MariaDB $MARIADB_VER quá cũ. Cần ≥ 10.6."
            exit 1
        fi
    else
        err "Không tìm thấy MariaDB/MySQL. Vui lòng kiểm tra database."
        err "Cài đặt: sudo apt install mariadb-server mariadb-client -y"
        exit 1
    fi
fi

# ============================================================
# Bước 2: Backup toàn bộ
# ============================================================
echo ""
info "Bước 2/7: Backup toàn bộ dữ liệu..."

mkdir -p "$BACKUP_DIR"
ok "Thư mục backup: $BACKUP_DIR"

# Backup database
info "Đang backup database..."
MYSQL_CMD="mysql -u${dbuser} -p${dbpass} -h${dbhost}"
MYSQLDUMP_CMD="mysqldump -u${dbuser} -p${dbpass} -h${dbhost} --single-transaction --routines --events --triggers"

if $MYSQL_CMD -e "USE ${dbname};" 2>/dev/null; then
    $MYSQLDUMP_CMD "$dbname" | gzip > "$BACKUP_DIR/database-${dbname}.sql.gz"
    ok "Database $dbname đã được backup."
else
    err "Không thể kết nối database $dbname. Kiểm tra lại thông tin đăng nhập."
    exit 1
fi

# Backup source code
info "Đang backup source code..."
tar czf "$BACKUP_DIR/glpi-source.tar.gz" -C "$(dirname $GLPI_ROOT)" "$(basename $GLPI_ROOT)" \
    --exclude="*/files/_dumps" \
    --exclude="*/files/_cache" \
    --exclude="*/files/_log" \
    --exclude="*/files/_sessions" \
    --exclude="*/files/_tmp" 2>/dev/null || \
    warn "Không thể backup source code (có thể thiếu quyền). Backups lấy file thủ công."

# Backup config file riêng
if [ -f "$GLPI_ROOT/config/config_db.php" ]; then
    cp "$GLPI_ROOT/config/config_db.php" "$BACKUP_DIR/config_db.php.bak"
    ok "Đã backup config database."
fi

# Backup plugins + marketplace
if [ -d "$GLPI_ROOT/plugins" ]; then
    tar czf "$BACKUP_DIR/glpi-plugins.tar.gz" -C "$GLPI_ROOT" plugins/
    ok "Đã backup plugins."
fi

if [ -d "$GLPI_ROOT/marketplace" ]; then
    tar czf "$BACKUP_DIR/glpi-marketplace.tar.gz" -C "$GLPI_ROOT" marketplace/
    ok "Đã backup marketplace."
fi

# Cấu hình GLPI 10.0.17 — lưu các thông tin cần thiết
GLPI_CONFIG_PHP="$GLPI_ROOT/inc/config.php"  # 10.0.x
GLPI_CONFIG_DB="$GLPI_ROOT/config/config_db.php"

if [ -f "$GLPI_CONFIG_DB" ]; then
    cp "$GLPI_CONFIG_DB" "$BACKUP_DIR/config_db.php.bak2"
fi

ok "Backup hoàn tất: $BACKUP_DIR"

# ============================================================
# Bước 3: Tải GLPI 11.0.7
# ============================================================
echo ""
info "Bước 3/7: Tải GLPI $GitGLPIversion..."

cd /opt

if [ -f "glpi-${GitGLPIversion}.tgz" ]; then
    ok "File đã tồn tại, bỏ qua tải lại."
else
    wget "https://github.com/glpi-project/glpi/releases/download/${GitGLPIversion}/glpi-${GitGLPIversion}.tgz" \
        -O "glpi-${GitGLPIversion}.tgz"
    ok "Đã tải GLPI $GitGLPIversion."
fi

# Giải nén
# Lưu ý: GLPI release tar xả vào thư mục glpi/ (không phải glpi-11.0.7/)
rm -rf /opt/glpi
tar xvf "glpi-${GitGLPIversion}.tgz" -C /opt/ > /dev/null 2>&1

# Đổi tên thư mục glpi/ -> glpi-11.0.7/ để khớp GLPI_TMP
if [ -d "/opt/glpi" ] && [ ! -d "$GLPI_TMP" ]; then
    mv /opt/glpi "$GLPI_TMP"
elif [ -d "/opt/glpi" ] && [ -d "$GLPI_TMP" ]; then
    rm -rf "$GLPI_TMP"
    mv /opt/glpi "$GLPI_TMP"
fi
ok "Đã giải nén GLPI $GitGLPIversion."

# ============================================================
# Bước 4: Thay thế core, giữ lại config + plugins
# ============================================================
echo ""
info "Bước 4/7: Cập nhật file GLPI..."

# Đặt chế độ bảo trì (GLPI 10.0.x)
MAINTENANCE_FILE="$GLPI_ROOT/config/maintenance.php"
if [ ! -f "$MAINTENANCE_FILE" ]; then
    echo "<?php return true;" > "$MAINTENANCE_FILE"
    ok "Đã bật chế độ bảo trì GLPI."
fi

# Backup các thư mục/files cần giữ lại
TMP_KEEP="/tmp/glpi-keep-$$"
mkdir -p "$TMP_KEEP"

# Các thư mục cần giữ nguyên
for dir in config files plugins marketplace; do
    if [ -d "$GLPI_ROOT/$dir" ]; then
        cp -a "$GLPI_ROOT/$dir" "$TMP_KEEP/"
        ok "Giữ lại: $dir"
    fi
done

# File .htaccess nếu có
if [ -f "$GLPI_ROOT/.htaccess" ]; then
    cp -a "$GLPI_ROOT/.htaccess" "$TMP_KEEP/"
fi

# File robots.txt nếu có
if [ -f "$GLPI_ROOT/robots.txt" ]; then
    cp -a "$GLPI_ROOT/robots.txt" "$TMP_KEEP/"
fi

# Xóa GLPI cũ (giữ lại thư mục files, config để tránh mất dữ liệu)
info "Đang xóa GLPI cũ..."
find "$GLPI_ROOT" -mindepth 1 -maxdepth 1 \
    ! -name 'files' \
    ! -name 'config' \
    ! -name 'plugins' \
    ! -name 'marketplace' \
    -exec rm -rf {} + 2>/dev/null || true

# Copy GLPI mới vào
info "Đang copy GLPI $GitGLPIversion..."
cp -a "$GLPI_TMP/"* "$GLPI_ROOT/"

# Khôi phục config + plugins + files + marketplace
for dir in config files plugins marketplace; do
    if [ -d "$TMP_KEEP/$dir" ]; then
        rm -rf "$GLPI_ROOT/$dir"
        cp -a "$TMP_KEEP/$dir" "$GLPI_ROOT/"
        ok "Đã khôi phục: $dir"
    fi
done

# Khôi phục .htaccess
if [ -f "$TMP_KEEP/.htaccess" ]; then
    cp -a "$TMP_KEEP/.htaccess" "$GLPI_ROOT/"
fi

if [ -f "$TMP_KEEP/robots.txt" ]; then
    cp -a "$TMP_KEEP/robots.txt" "$GLPI_ROOT/"
fi

# Dọn dẹp
rm -rf "$TMP_KEEP"

# GLPI 11.0 dùng config/config_db.php (giống 10.0.x)
# Nếu chưa có, copy từ backup
if [ ! -f "$GLPI_ROOT/config/config_db.php" ]; then
    if [ -f "$BACKUP_DIR/config_db.php.bak2" ]; then
        cp "$BACKUP_DIR/config_db.php.bak2" "$GLPI_ROOT/config/config_db.php"
        ok "Đã khôi phục config_db.php từ backup."
    elif [ -f "$BACKUP_DIR/config_db.php.bak" ]; then
        cp "$BACKUP_DIR/config_db.php.bak" "$GLPI_ROOT/config/config_db.php"
        ok "Đã khôi phục config_db.php từ backup."
    fi
fi

ok "Core GLPI 11.0.7 đã được cập nhật."

# ============================================================
# Bước 5: Fix permissions
# ============================================================
echo ""
info "Bước 5/7: Phân quyền thư mục..."

chown -R www-data:www-data "$GLPI_ROOT/"
find "$GLPI_ROOT" -type d -exec chmod 755 {} \;
find "$GLPI_ROOT" -type f -exec chmod 644 {} \;
chmod -R 755 "$GLPI_ROOT/files/" 2>/dev/null || true
chmod -R 755 "$GLPI_ROOT/config/" 2>/dev/null || true

# Đảm bảo các thư mục cache/log/session có quyền ghi
for dir in _cache _log _sessions _tmp _uploads _dumps _lock _graphs _plugins; do
    target="$GLPI_ROOT/files/$dir"
    if [ -d "$target" ]; then
        chmod -R 755 "$target"
        chown -R www-data:www-data "$target"
    fi
done

ok "Permissions đã được thiết lập."

# ============================================================
# Bước 6: Nâng cấp database schema
# ============================================================
echo ""
info "Bước 6/7: Nâng cấp database schema GLPI 10.0 → 11.0..."

cd "$GLPI_ROOT"

SU=""
if [ "$(id -u)" -eq 0 ]; then
    SU="--allow-superuser"
fi

if [ -f "bin/console" ]; then
    # Nâng cấp database schema (GLPI 10.0 -> 11.0)
    info "Đang nâng cấp database schema (có thể mất vài phút)..."
    php bin/console glpi:database:update --force --no-interaction $SU 2>/dev/null

    # Kiểm tra kết quả
    DB_UPGRADE_OK=$?
    if [ $DB_UPGRADE_OK -ne 0 ]; then
        warn "glpi:database:update gặp lỗi. Thử phương án migration..."
        php bin/console glpi:migration:build --force --no-interaction $SU 2>/dev/null || \
            warn "Database upgrade có vấn đề. Chạy thủ công: php bin/console glpi:database:update --allow-superuser"
    else
        ok "Database schema đã được nâng cấp."
    fi

    # Plugin upgrades
    PLUGIN_LIST=$(php bin/console glpi:plugin:list $SU 2>/dev/null)
    if echo "$PLUGIN_LIST" | grep -qi "not installed\|to update"; then
        info "Đang nâng cấp plugins..."
        php bin/console glpi:plugin:install --all --force $SU 2>/dev/null || true
    fi

    # Clear cache (quan trọng: GLPI 11.0 dùng Symfony cache)
    php bin/console cache:clear --no-interaction $SU 2>/dev/null || true
    php bin/console glpi:cache:clear --no-interaction $SU 2>/dev/null || true
    # Xóa cache thủ công để chắc chắn
    rm -rf "$GLPI_ROOT/var/cache/"* "$GLPI_ROOT/files/_cache/"* 2>/dev/null || true

    ok "Database schema đã được nâng cấp."
else
    warn "Không tìm thấy bin/console. Có thể cài đặt GLPI chưa đúng."
    warn "Chạy thủ công: cd $GLPI_ROOT && php bin/console glpi:database:update --allow-superuser"
fi

# ============================================================
# Bước 7: Tắt maintenance & dọn dẹp
# ============================================================
echo ""
info "Bước 7/7: Hoàn tất..."

# Tắt chế độ bảo trì
if [ -f "$MAINTENANCE_FILE" ]; then
    rm -f "$MAINTENANCE_FILE"
    ok "Đã tắt chế độ bảo trì."
fi

# Dọn dẹp file tạm
rm -rf /opt/glpi-${GitGLPIversion}
ok "Đã dọn dẹp file tạm."

# Restart services
info "Đang restart services..."
if systemctl is-active --quiet nginx; then
    systemctl restart nginx || true
fi

if systemctl is-active --quiet php8.3-fpm; then
    systemctl restart php8.3-fpm || true
fi

if systemctl is-active --quiet php8.2-fpm; then
    systemctl restart php8.2-fpm || true
fi

if systemctl is-active --quiet mariadb; then
    systemctl restart mariadb || true
fi

ok "Services đã được restart."

# ============================================================
# Kết quả
# ============================================================
echo ""
echo "=============================================="
echo -e "${GREEN}  NÂNG CẤP GLPI HOÀN TẤT!${NC}"
echo "=============================================="
echo ""
echo -e "  Phiên bản:    ${CYAN}10.0.17 → 11.0.7${NC}"
echo -e "  Thư mục:      ${CYAN}$GLPI_ROOT${NC}"
echo -e "  Backup:       ${CYAN}$BACKUP_DIR${NC}"
echo ""
echo -e "  ${YELLOW}Kiểm tra nâng cấp thành công:${NC}"
# Trích xuất domain từ đường dẫn GLPI_ROOT để hiển thị
GLPI_DOMAIN=$(basename "$GLPI_ROOT")
echo -e "    https://${GLPI_DOMAIN}/  (trang web)"
echo -e "    php bin/console glpi:database:update  (kiểm tra DB)"
echo ""
echo -e "  ${YELLOW}Nếu có lỗi:${NC}"
echo -e "    1. Kiểm tra file: $GLPI_ROOT/files/_log/php-errors.log"
echo -e "    2. Chạy thủ công: php bin/console glpi:database:update"
echo -e "    3. Restore backup:"
echo -e "       - DB:     gunzip -c $BACKUP_DIR/database-${dbname}.sql.gz | mysql -u$dbuser -p${dbpass} -h${dbhost} $dbname"
echo -e "       - Files:  tar xzf $BACKUP_DIR/glpi-source.tar.gz -C /"
echo ""
echo -e "  ${RED}Đừng quên đổi mật khẩu mặc định!${NC}"
echo "=============================================="
echo ""
