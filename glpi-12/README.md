# GLPI ITSM - Advanced Deployment

## Giới thiệu GLPI

**GLPI (Gestionnaire Libre de Parc Informatique)** là giải pháp **ITSM (IT Service Management)** mã nguồn mở hàng đầu, cung cấp nền tảng toàn diện để quản lý toàn bộ hạ tầng CNTT trong doanh nghiệp.

Với GLPI, tổ chức có thể:

- **ITAM (IT Asset Management)** — Quản lý vòng đời tài sản CNTT: phần cứng, phần mềm, license, hợp đồng bảo trì
- **ITSM / ITIL** — Quản lý dịch vụ CNTT theo chuẩn ITIL: Incident, Problem, Change, Release, Service Catalog
- **IT Helpdesk** — Trung tâm trợ giúp với ticket system, SLA, escalations, tự động hóa quy trình
- **Inventory & Discovery** — Tự động phát hiện và kiểm kê thiết bị qua GLPI Agent (snmp, ssh, winrm)
- **Reporting & Dashboard** — Báo cáo chi tiết, biểu đồ trực quan, dashboards tùy chỉnh
- **Knowledge Base** — Cơ sở tri thức dùng chung, FAQ, tài liệu hướng dẫn
- **Multi-tenancy** — Hỗ trợ nhiều tổ chức/khách hàng trên cùng một instance

---

## Thông tin phiên bản

| Mục | Phiên bản cũ | Phiên bản mới |
|-----|-------------|---------------|
| **GLPI** | 10.0.17 | **11.0.7** |
| **File script** | `deploy_itsm_v10017.sh` | `deploy_itsm_v11007.sh` |
| **Ngày phát hành** | 11/11/2024 | 29/04/2026 |
| **Hệ điều hành** | Ubuntu 20.04 LTS | Ubuntu 22.04 LTS+ |
| **PHP** | 8.3 | 8.3 (yêu cầu ≥ 8.2) |
| **Database** | MariaDB ≥ 10.2 / MySQL ≥ 5.7 | MariaDB ≥ 10.6 / MySQL ≥ 8.0 |

---

## Thay đổi nâng cấp chính

### 1. GLPI 11.0 — Công nghệ nền tảng mới

GLPI 11.0 là bước nhảy vọt về kiến trúc so với dòng 10.0:

- **Symfony 7** — Framework hiện đại, hiệu suất cao, bảo mật tốt hơn
- **PHP 8.2+** — Tận dụng JIT, named arguments, match expression, readonly classes, fibers
- **Database schema được tối ưu** — Chỉ mục thông minh, truy vấn nhanh hơn 40%
- **UTF-8 MB4** — Hỗ trợ đầy đủ Unicode, emoji, ký tự đặc biệt

### 2. Giao diện người dùng mới

- **UI/UX thiết kế lại** — Giao diện trực quan, hiện đại, thân thiện với người dùng
- **Dark Mode** — Chế độ tối bảo vệ mắt
- **Responsive** — Hoạt động mượt mà trên mọi thiết bị (desktop, tablet, mobile)
- **Page Builder** — Kéo thả tùy chỉnh giao diện, dashboard

### 3. ITIL & Service Desk cải tiến

- **ITIL 4 alignment** — Hỗ trợ chuẩn ITIL 4 với Service Value System
- **Knowledge Base nâng cấp** — WYSIWYG editor, phân loại, đánh giá, gắn thẻ
- **Ticket templates** — Mẫu ticket thông minh, tự động điền thông tin
- **SLA Management** — Theo dõi SLA real-time, cảnh báo vi phạm
- **Automation Rules** — Business rules mạnh mẽ: tự động gán, phân loại, escalate
- **Service Catalog** — Danh mục dịch vụ với request form động

### 4. Asset & Inventory Management

- **GLPI Agent 1.6+** — Tương thích agent mới nhất, inventory nhanh hơn
- **Network discovery** — Phát hiện thiết bị mạng qua SNMP v3, SSH, WinRM
- **Software audit** — Kiểm kê phần mềm chi tiết, phát hiện license không hợp lệ
- **License management** — Quản lý license subscription, renewal tracking
- **Datacenter management** — Quản lý rack, PDU, UPS, HVAC trong datacenter

### 5. Bảo mật (Security Release 11.0.7)

Bản 11.0.7 vá **13 lỗ hổng bảo mật** quan trọng:

- **High**: Stored XSS trong Knowledge Base, ITIL Costs
- **High**: Xóa tài sản tùy ý qua planning (CVE-2026-42318)
- **High**: Xóa file tùy ý bởi technician (CVE-2026-42317)
- **Medium**: Xuất cấu trúc form trái phép (CVE-2026-32312)
- **Medium**: Truy cập file tùy ý (CVE-2026-42320)
- **Low — Medium**: Các lỗi về SSRF, webhook, IMAP, quyền truy cập

### 6. Hiệu năng & Mở rộng

- **Query caching** — Redis/Memcached hỗ trợ chính thức
- **OPcache** — Tối ưu PHP bytecode cache
- **Async tasks** — Xử lý tác vụ nặng bất đồng bộ qua messenger/queue
- **API REST v2** — API mạnh mẽ, rate limiting, OAuth2 authentication
- **Webhooks** — Tích hợp với hệ thống bên ngoài qua webhook events
- **Multi-node support** — Phân tán tải qua nhiều web server

---

## Cấu trúc thư mục

```
Advanced/
├── deploy_itsm_v10017.sh              # Script deploy GLPI 10.0.17 (legacy)
├── deploy_itsm_v11007.sh              # Script deploy GLPI 11.0.7 (cài mới)
├── upgrade_itsm_v10017-to-v11007.sh   # Script nâng cấp từ 10.0.17 → 11.0.7
└── README.md                          # Tài liệu hướng dẫn (file này)
```

## Hướng dẫn sử dụng

### Yêu cầu hệ thống

| Thành phần | Yêu cầu bắt buộc |
|-----------|------------------|
| OS | **Ubuntu 22.04 LTS** hoặc 24.04 LTS (xem ghi chú bên dưới) |
| RAM | ≥ 4GB (khuyến nghị 8GB) |
| Disk | ≥ 20GB (khuyến nghị SSD) |
| CPU | ≥ 2 cores |
| Database | MariaDB ≥ 10.6 hoặc MySQL ≥ 8.0 |
| PHP | **8.2 — 8.3** (yêu cầu ≥ 8.2) |
| Web Server | Nginx hoặc Apache 2.4 |

> **⚠️ Quan trọng — Ubuntu 20.04 LTS không được hỗ trợ:**
> GLPI 11.0 yêu cầu PHP ≥ 8.2, nhưng Ubuntu 20.04 LTS chỉ cung cấp PHP 7.4 từ repo chính thức.
> Dù có thể thêm PPA `ondrej/php` để cài PHP 8.3 trên 20.04, quá trình này gặp nhiều rủi ro:
> - PPA codename (`focal`) không đồng bộ với OS release, gây lỗi `apt update`
> - Extension bcmath load sai phiên bản (lấy từ PHP 7.4 thay vì 8.3)
> - Tương thích thư viện hệ thống không đảm bảo
>
> **Khuyến nghị: Nếu đang chạy Ubuntu 20.04, hãy nâng cấp OS lên 22.04 LTS trước khi nâng cấp GLPI:**
> ```bash
> # Backup toàn bộ trước khi nâng cấp OS!
> # Sau đó chạy upgrade OS
> sudo do-release-upgrade
> ```
> Script `upgrade_itsm_v10017-to-v11007.sh` có hỗ trợ auto-fix PPA codename,
> nhưng kết quả tốt nhất đạt được trên Ubuntu 22.04 LTS+.

### Cài đặt nhanh

```bash
# Clone repository
git clone https://github.com/PhDLeToanThang/itil-helpdesk.git
cd itil-helpdesk/Advanced

# Phân quyền thực thi
chmod +x deploy_itsm_v11007.sh  

# Chạy script
sudo ./deploy_itsm_v11007.sh
```

Script sẽ tự động:

1. Cài đặt Nginx, MariaDB, PHP 8.3-FPM
2. Tạo database và user
3. Tải và cài đặt GLPI 11.0.7
4. Cấu hình Nginx virtual host
5. Cài đặt phpMyAdmin
6. Cài đặt Certbot SSL Let's Encrypt
7. Cấu hình firewall (UFW)

## Nâng cấp từ GLPI 10.0.17 lên 11.0.7

> **⚠️ Cảnh báo quan trọng:**
> Nâng cấp major version (10.x → 11.x) là quy trình một chiều (irreversible).
> Không thể rollback database sau khi nâng cấp schema. Bắt buộc phải backup trước khi thực hiện.

### Quy trình nâng cấp tổng quan

```
1. Kiểm tra tiên quyết hệ thống
2. Backup database + mã nguồn
3. Bật chế độ bảo trì (Maintenance Mode)
4. Tải GLPI 11.0.7
5. Thay thế core files, giữ lại config / plugins / marketplace
6. Chạy database migration
7. Tắt chế độ bảo trì
8. Kiểm tra kết quả
```

### Yêu cầu tiên quyết trước nâng cấp

| Thành phần | Giá trị hiện tại (10.0.17) | Yêu cầu cho 11.0.7 | Hành động cần làm |
|-----------|---------------------------|-------------------|-------------------|
| **PHP** | ≥ 7.4 | **≥ 8.2** (khuyến nghị 8.3) | `add-apt-repository ppa:ondrej/php -y && apt install php8.3-fpm php8.3-cli php8.3-{bcmath,bz2,curl,gd,intl,ldap,mbstring,mysql,xml,zip}` |
| **PHP modules** | thiếu bcmath, bz2, dom, simplexml... | bcmath, bz2, curl, dom, fileinfo, gd, intl, json, ldap, mbstring, mysqli, openssl, session, simplexml, xml, xmlreader, xmlwriter, zip | Cài bổ sung: `apt install php8.3-bcmath php8.3-bz2` |
| **MariaDB** | ≥ 10.2 | **≥ 10.6** | `mariadb --version` → nếu < 10.6, cần nâng cấp MariaDB trước |
| **MySQL** | ≥ 5.7 | **≥ 8.0** | `mysql --version` → nếu < 8.0, cần nâng cấp MySQL trước |
| **OS** | Ubuntu 20.04+ | **Ubuntu 22.04+** | `lsb_release -a` → nếu 20.04 vẫn dùng được, nhưng khuyến nghị 22.04+ |
| **Disk** | ≥ 10GB | **≥ 20GB** | `df -h` kiểm tra dung lượng trống |

### Sử dụng script nâng cấp tự động

```bash
# Clone repository (nếu chưa có)
git clone https://github.com/PhDLeToanThang/itil-helpdesk.git
cd itil-helpdesk/Advanced

# Phân quyền thực thi
chmod +x upgrade_itsm_v10017-to-v11007.sh

# Chạy script (với quyền root)
sudo ./upgrade_itsm_v10017-to-v11007.sh
```

Script nâng cấp sẽ tự động:

1. **Kiểm tra tiên quyết** — PHP version, PHP modules, MariaDB/MySQL version
2. **Backup toàn bộ** — Database (`mysqldump --single-transaction`), source code, plugins, marketplace → `/opt/glpi-backup-YYYYMMDD_HHMMSS/`
3. **Bật chế độ bảo trì** — tạo file `config/maintenance.php`
4. **Thay thế core GLPI** — giữ nguyên `config/`, `files/`, `plugins/`, `marketplace/`
5. **Fix permissions** — www-data sở hữu toàn bộ thư mục
6. **Nâng cấp database** — `php bin/console glpi:database:update --force`
7. **Tắt maintenance** — xóa file maintenance
8. **Restart services** — nginx, php-fpm, mariadb

### Hướng dẫn nâng cấp thủ công (từng bước)

Nếu không sử dụng script tự động, thực hiện các bước sau:

#### Bước 1: Backup database

```bash
# Backup database
mysqldump -u<user> -p<password> --single-transaction --routines --events --triggers <dbname> | gzip > /opt/glpi-backup/glpi-db-$(date +%Y%m%d).sql.gz

# Backup source code
tar czf /opt/glpi-backup/glpi-source-$(date +%Y%m%d).tar.gz \
  -C /var/www/html <thumuc-glpi> \
  --exclude="*/files/_dumps" \
  --exclude="*/files/_cache" \
  --exclude="*/files/_log" \
  --exclude="*/files/_sessions"

# Backup plugins riêng
tar czf /opt/glpi-backup/glpi-plugins-$(date +%Y%m%d).tar.gz \
  -C /var/www/html/<thumuc-glpi> plugins/
```

#### Bước 2: Bật chế độ bảo trì

```bash
# Tạo file maintenance để chặn người dùng truy cập
echo "<?php return true;" > /var/www/html/<thumuc-glpi>/config/maintenance.php
```

#### Bước 3: Tải và thay thế core GLPI

```bash
cd /opt
wget https://github.com/glpi-project/glpi/releases/download/11.0.7/glpi-11.0.7.tgz
tar xvf glpi-11.0.7.tgz

cd /var/www/html/<thumuc-glpi>

# Backup các thư mục cần giữ lại
mkdir -p /tmp/glpi-keep
cp -a config files plugins marketplace /tmp/glpi-keep/

# Xóa core cũ (giữ lại thư mục cần thiết)
find . -mindepth 1 -maxdepth 1 \
  ! -name 'files' ! -name 'config' \
  ! -name 'plugins' ! -name 'marketplace' \
  -exec rm -rf {} +

# Copy core mới vào
cp -a /opt/glpi-11.0.7/* /var/www/html/<thumuc-glpi>/

# Khôi phục config, plugins, files, marketplace
rm -rf config files plugins marketplace
cp -a /tmp/glpi-keep/* /var/www/html/<thumuc-glpi>/
rm -rf /tmp/glpi-keep
```

#### Bước 4: Fix permissions

```bash
chown -R www-data:www-data /var/www/html/<thumuc-glpi>/
find /var/www/html/<thumuc-glpi>/ -type d -exec chmod 755 {} \;
find /var/www/html/<thumuc-glpi>/ -type f -exec chmod 644 {} \;
```

#### Bước 5: Nâng cấp database schema

```bash
cd /var/www/html/<thumuc-glpi>
php bin/console glpi:database:update --force
# Hoặc nếu gặp lỗi:
php bin/console glpi:migration:build --force

# Nâng cấp plugins
php bin/console glpi:plugin:list
php bin/console glpi:plugin:install --all --force

# Clear cache
php bin/console cache:clear

# Kiểm tra kết quả
php bin/console glpi:system:check_requirements
```

#### Bước 6: Tắt chế độ bảo trì

```bash
rm -f /var/www/html/<thumuc-glpi>/config/maintenance.php
systemctl restart nginx php8.3-fpm mariadb
```

### Xử lý sự cố sau nâng cấp

| Vấn đề | Nguyên nhân | Giải pháp |
|--------|-------------|-----------|
| Trang trắng (white screen) | Thiếu PHP module | `php -m` → cài module thiếu: `apt install php8.3-<module>` |
| Lỗi database connection | config_db.php sai | Kiểm tra `config/config_db.php`, restore từ backup nếu cần |
| Plugin không hoạt động | Chưa nâng cấp plugin schema | `php bin/console glpi:plugin:install <plugin>` |
| Lỗi 500 Internal Server | Permissions sai | `chown -R www-data:www-data` toàn bộ thư mục GLPI |
| Lỗi "GLPI is installed" | Cache cũ | `rm -rf files/_cache/*` và `php bin/console cache:clear` |

### Rollback — Khôi phục từ backup nếu thất bại

```bash
# 1. Khôi phục database
gunzip -c /opt/glpi-backup/glpi-db-YYYYMMDD.sql.gz | mysql -u<user> -p<password> <dbname>

# 2. Khôi phục source code
tar xzf /opt/glpi-backup/glpi-source-YYYYMMDD.tar.gz -C /

# 3. Khôi phục plugins
tar xzf /opt/glpi-backup/glpi-plugins-YYYYMMDD.tar.gz -C /var/www/html/<thumuc-glpi>/

# 4. Fix permissions
chown -R www-data:www-data /var/www/html/<thumuc-glpi>/

# 5. Restart services
systemctl restart nginx php8.3-fpm mariadb
```

### Các lỗi thường gặp khi nâng cấp và cách xử lý

#### 1. Extension bcmath load sai phiên bản PHP

**Triệu chứng:** `php8.3 -m | grep bcmath` không thấy bcmath, dù đã `apt install php8.3-bcmath`.

**Nguyên nhân:** Script cũ dùng `find /usr/lib/php -name "bcmath.so" | head -1` để tìm đường dẫn extension, nhưng trên Ubuntu 20.04/22.04 có thể tìm thấy file `.so` của PHP 7.4 (thư mục `20190902`) thay vì PHP 8.3 (`20230831`).

**Fix:** Luôn dùng `PHP_EXTENSION_DIR` từ chính PHP binary:
```bash
PHP_EXT_DIR=$(php8.3 -r 'echo PHP_EXTENSION_DIR;')
echo "extension=${PHP_EXT_DIR}/bcmath.so" > /etc/php/8.3/mods-available/bcmath.ini
```

#### 2. Không kết nối được database sau nâng cấp (rawurldecode bug)

**Triệu chứng:** PHP `mysqli` test OK, nhưng GLPI báo `Unable to connect to database` hoặc `The connection to the SQL server could not be established`.

**Nguyên nhân:** GLPI 11.0 thêm `rawurldecode($this->dbpassword)` trong `DBmysql::connect()` (`src/DBmysql.php:293`). Nếu mật khẩu MySQL chứa ký tự `%xx` (ví dụ `%40` là `@` khi URL-decode), `rawurldecode` sẽ biến đổi password thành sai.

Ví dụ: Password thật `%40T.c0m%402022` → `rawurldecode` thành `@T.c0m@2022` → Access Denied.

**Fix:** Script upgrade tự động patch file `src/DBmysql.php`:
```bash
sed -i 's/rawurldecode($this->dbpassword)/$this->dbpassword/g' /var/www/html/glpi/src/DBmysql.php
```

> **Lưu ý:** GLPI 11.0 `rawurlencode` mật khẩu khi ghi config (qua `DBConnection::createMainConfig()`), và `rawurldecode` khi đọc. Khi nâng cấp từ 10.0.x, config cũ chưa được encode, gây mismatch. Nếu dùng script upgrade tự động, vấn đề này được xử lý tự động ở Bước 4.

#### 3. PPA codename không khớp sau upgrade OS

**Triệu chứng:** `apt update` báo lỗi `The repository '... focal Release' does not have a Release file`.

**Nguyên nhân:** Sau khi nâng cấp Ubuntu từ 20.04 (Focal) lên 22.04 (Jammy), PPA `ondrej/php` vẫn giữ codename cũ `focal`.

**Fix:** Script upgrade tự động phát hiện và sửa:
```bash
OS_CODENAME=$(lsb_release -sc)
sed -i "s/$OS_CODENAME/$OS_CODENAME/g" /etc/apt/sources.list.d/ondrej-*.list
```

#### 4. Không tìm thấy class DBmysql

**Triệu chứng:** `Fatal error: Class "DBmysql" not found in config_db.php`.

**Nguyên nhân:** Test PHP không include `vendor/autoload.php` trước khi include `config/config_db.php`. Trong GLPI thật, autoloader luôn được load trước.

**Fix:** Luôn load autoloader trước config:
```php
require '/path/to/glpi/vendor/autoload.php';
require '/path/to/glpi/config/config_db.php';
$db = new DB();
```

### Kiểm tra sau nâng cấp

```bash
# Kiểm tra version
php bin/console glpi:system:status | grep version

# Kiểm tra requirements
php bin/console glpi:system:check_requirements

# Kiểm tra database
php bin/console glpi:database:check_schema_integrity

# Kiểm tra log lỗi
tail -f files/_log/php-errors.log
```

### Thông tin đăng nhập mặc định

| User | Password | Vai trò |
|------|----------|---------|
| `glpi` | `glpi` | Quản trị viên |
| `tech` | `tech` | Kỹ thuật viên |
| `normal` | `normal` | Người dùng thường |
| `post-only` | `postonly` | Người dùng chỉ gửi ticket |

> **⚠️ Lưu ý:** Đổi mật khẩu mặc định ngay sau đăng nhập!

---

## Tài liệu tham khảo

- [GLPI Project](https://glpi-project.org)
- [GLPI 11.0 Documentation](https://glpi-install.readthedocs.io)
- [GLPI Help Center](https://help.glpi-project.org)
- [GitHub Repository](https://github.com/PhDLeToanThang/itil-helpdesk)
- [GLPI Releases](https://github.com/glpi-project/glpi/releases)

---

*Maintained by PhD Lê Toàn Thắng*
