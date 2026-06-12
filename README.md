<!-- suppress inter-kingdom war declaration -->

# Hệ thống ITSM - ITIL Helpdesk (GLPI)

> **GLPI (Gestionnaire Libre de Parc Informatique)** — Giải pháp **ITSM (IT Service Management)** mã nguồn mở hàng đầu, quản lý toàn diện hạ tầng CNTT doanh nghiệp theo chuẩn ITIL.

---

## Mục lục

- [1. Giới thiệu tổng quan](#1-gi%E1%BB%9Bi-thi%E1%BB%87u-t%E1%BB%95ng-quan)
  - [1.1. GLPI ITSM là gì?](#11-glpi-itsm-l%C3%A0-g%C3%AC)
  - [1.2. Tính năng chính](#12-t%C3%ADnh-n%C4%83ng-ch%C3%ADnh)
  - [1.3. Kiến trúc hệ thống](#13-ki%E1%BA%BFn-tr%C3%BAc-h%E1%BB%87-th%E1%BB%91ng)
- [2. Phiên bản & Yêu cầu hệ thống](#2-phi%C3%AAn-b%E1%BA%A3n--y%C3%AAu-c%E1%BA%A7u-h%E1%BB%87-th%E1%BB%91ng)
  - [2.1. Thông tin phiên bản](#21-th%C3%B4ng-tin-phi%C3%AAn-b%E1%BA%A3n)
  - [2.2. Yêu cầu hệ thống](#22-y%C3%AAu-c%E1%BA%A7u-h%E1%BB%87-th%E1%BB%91ng)
  - [2.3. Lưu ý về Ubuntu 20.04 → 22.04](#23-l%C6%B0u-%C3%BD-v%E1%BB%81-ubuntu-2004--2204)
  - [2.4. So sánh GLPI 10.0.17 vs 11.0.7](#24-so-s%C3%A1nh-glpi-10017-vs-1107)
- [3. Triển khai cài đặt mới (GLPI 11.0.7)](#3-tri%E1%BB%83n-khai-c%C3%A0i-%C4%91%E1%BA%B7t-m%E1%BB%9Bi-glpi-1107)
  - [3.1. Script tự động](#31-script-t%E1%BB%B1-%C4%91%E1%BB%99ng)
  - [3.2. Các bước thực hiện](#32-c%C3%A1c-b%C6%B0%E1%BB%9Bc-th%E1%BB%B1c-hi%E1%BB%87n)
- [4. Nâng cấp từ GLPI 10.0.17 lên 11.0.7](#4-n%C3%A2ng-c%E1%BA%A5p-t%E1%BB%AB-glpi-10017-l%C3%AAn-1107)
  - [4.1. Cảnh báo quan trọng](#41-c%E1%BA%A3nh-b%C3%A1o-quan-tr%E1%BB%8Dng)
  - [4.2. Quy trình tổng quan](#42-quy-tr%C3%ACnh-t%E1%BB%95ng-quan)
  - [4.3. Yêu cầu tiên quyết](#43-y%C3%AAu-c%E1%BA%A7u-ti%C3%AAn-quy%E1%BA%BFt)
  - [4.4. Sử dụng script nâng cấp tự động](#44-s%E1%BB%AD-d%E1%BB%A5ng-script-n%C3%A2ng-c%E1%BA%A5p-t%E1%BB%B1-%C4%91%E1%BB%99ng)
  - [4.5. Hướng dẫn nâng cấp thủ công](#45-h%C6%B0%E1%BB%9Bng-d%E1%BA%ABn-n%C3%A2ng-c%E1%BA%A5p-th%E1%BB%A7-c%C3%B4ng)
- [5. Xử lý sự cố & Lỗi thường gặp](#5-x%E1%BB%AD-l%C3%BD-s%E1%BB%B1-c%E1%BB%91--l%E1%BB%97i-th%C6%B0%E1%BB%9Dng-g%E1%BA%B7p)
  - [5.1. Bảng xử lý sự cố nhanh](#51-b%E1%BA%A3ng-x%E1%BB%AD-l%C3%BD-s%E1%BB%B1-c%E1%BB%91-nhanh)
  - [5.2. Extension bcmath load sai phiên bản PHP](#52-extension-bcmath-load-sai-phi%C3%AAn-b%E1%BA%A3n-php)
  - [5.3. rawurldecode bug — không kết nối được database](#53-rawurldecode-bug--kh%C3%B4ng-k%E1%BA%BFt-n%E1%BB%91i-%C4%91%C6%B0%E1%BB%A3c-database)
  - [5.4. PPA codename không khớp sau upgrade OS](#54-ppa-codename-kh%C3%B4ng-kh%E1%BB%9Bp-sau-upgrade-os)
  - [5.5. Không tìm thấy class DBmysql](#55-kh%C3%B4ng-t%C3%ACm-th%E1%BA%A5y-class-dbmysql)
- [6. Rollback — Khôi phục từ backup](#6-rollback--kh%C3%B4i-ph%E1%BB%A5c-t%E1%BB%AB-backup)
- [7. Kiểm tra & Vận hành](#7-ki%E1%BB%83m-tra--v%E1%BA%ADn-h%C3%A0nh)
- [8. Lý thuyết nền tảng ITIL & Chuẩn ngành](#8-l%C3%BD-thuy%E1%BA%BFt-n%E1%BB%81n-t%E1%BA%A3ng-itil--chu%E1%BA%A9n-ng%C3%A0nh)
  - [8.1. ITIL Framework](#81-itil-framework)
  - [8.2. IT Asset Management (ITAM)](#82-it-asset-management-itam)
  - [8.3. ITIL Incident Management](#83-itil-incident-management)
  - [8.4. ITIL Problem Management](#84-itil-problem-management)
  - [8.5. ITIL Knowledge Management (DIKW Model)](#85-itil-knowledge-management-dikw-model)
  - [8.6. Ticket & Service Desk](#86-ticket--service-desk)
  - [8.7. COBIT — ITIL — ISO 27001/27002:2022](#87-cobit--itil--iso-27001270022022)
- [9. Thông tin đăng nhập mặc định](#9-th%C3%B4ng-tin-%C4%91%C4%83ng-nh%E1%BA%ADp-m%E1%BA%B7c-%C4%91%E1%BB%8Bnh)
- [10. Tài liệu tham khảo](#10-t%C3%A0i-li%E1%BB%87u-tham-kh%E1%BA%A3o)

---

## 1. Giới thiệu tổng quan

### 1.1. GLPI ITSM là gì?

GLPI là hệ thống **ITSM (IT Service Management)** mã nguồn mở hàng đầu thế giới, cung cấp nền tảng toàn diện để quản lý toàn bộ hạ tầng CNTT trong doanh nghiệp. Được xây dựng trên nền tảng PHP & Symfony, GLPI đáp ứng đầy đủ các tiêu chuẩn **ITIL**, **COBIT** và **ISO 27001/27002**.

### 1.2. Tính năng chính

| Tính năng | Mô tả |
|-----------|-------|
| **ITAM** | Quản lý vòng đời tài sản CNTT: phần cứng, phần mềm, license, hợp đồng bảo trì |
| **ITSM / ITIL** | Quản lý dịch vụ CNTT theo chuẩn ITIL: Incident, Problem, Change, Release, Service Catalog |
| **IT Helpdesk** | Trung tâm trợ giúp với ticket system, SLA, escalations, tự động hóa quy trình |
| **Inventory & Discovery** | Tự động phát hiện và kiểm kê thiết bị qua GLPI Agent (SNMP, SSH, WinRM) |
| **Reporting & Dashboard** | Báo cáo chi tiết, biểu đồ trực quan, dashboards tùy chỉnh |
| **Knowledge Base** | Cơ sở tri thức dùng chung, FAQ, tài liệu hướng dẫn |
| **Multi-tenancy** | Hỗ trợ nhiều tổ chức/khách hàng trên cùng một instance |
| **API REST v2** | API mạnh mẽ với rate limiting, OAuth2 authentication |
| **Webhooks** | Tích hợp với hệ thống bên ngoài qua webhook events |

### 1.3. Kiến trúc hệ thống

```
┌─────────────────────────────────────────────────────┐
│                     Client Layer                      │
│     Web Browser / GLPI Agent / API Client / Mobile    │
└────────────────────┬────────────────────────────────┘
                     │ HTTPS
┌────────────────────▼────────────────────────────────┐
│               Web Server (Nginx/Apache)               │
│          Reverse Proxy / SSL Termination              │
└────────────────────┬────────────────────────────────┘
                     │ PHP-FPM
┌────────────────────▼────────────────────────────────┐
│              Application Layer (PHP 8.3)              │
│  ┌─────────────────────────────────────────────────┐ │
│  │            GLPI Core (Symfony 7)                 │ │
│  │  GLPI Application  ←  src/                       │ │
│  │  System Config    ←  config/config_db.php        │ │
│  │  Plugins          ←  plugins/                    │ │
│  │  Marketplace      ←  marketplace/                │ │
│  └─────────────────────────────────────────────────┘ │
└────────────────────┬────────────────────────────────┘
                     │ MySQL/MariaDB
┌────────────────────▼────────────────────────────────┐
│              Database Layer (MariaDB ≥ 10.6)          │
│           itsimdata1009 (GLPI Schema)                 │
└─────────────────────────────────────────────────────┘
```

---

## 2. Phiên bản & Yêu cầu hệ thống

### 2.1. Thông tin phiên bản

| Mục | Phiên bản cũ | Phiên bản mới |
|-----|-------------|---------------|
| **GLPI** | 10.0.17 | **11.0.7** |
| **Script deploy** | `deploy_itsm_v10017.sh` | `deploy_itsm_v11007.sh` |
| **Script nâng cấp** | — | `upgrade_itsm_v10017-to-v11007.sh` |
| **Ngày phát hành** | 11/11/2024 | 29/04/2026 |
| **Hệ điều hành** | Ubuntu 20.04 LTS | **Ubuntu 22.04 LTS+** |
| **PHP** | ≥ 7.4 | **≥ 8.2** (khuyến nghị 8.3) |
| **Database** | MariaDB ≥ 10.2 / MySQL ≥ 5.7 | **MariaDB ≥ 10.6** / MySQL ≥ 8.0 |

### 2.2. Yêu cầu hệ thống

| Thành phần | Yêu cầu bắt buộc |
|-----------|------------------|
| **OS** | **Ubuntu 22.04 LTS** hoặc 24.04 LTS |
| **RAM** | ≥ 4GB (khuyến nghị 8GB) |
| **Disk** | ≥ 20GB (khuyến nghị SSD 50GB+) |
| **CPU** | ≥ 2 cores (khuyến nghị 4 cores) |
| **Database** | MariaDB ≥ 10.6 hoặc MySQL ≥ 8.0 |
| **PHP** | **8.2 — 8.3** |
| **Web Server** | Nginx hoặc Apache 2.4 |

### 2.3. Lưu ý về Ubuntu 20.04 → 22.04

> **⚠️ Ubuntu 20.04 LTS không được hỗ trợ chính thức cho GLPI 11.0.7.**

GLPI 11.0 yêu cầu PHP ≥ 8.2, nhưng Ubuntu 20.04 LTS chỉ cung cấp PHP 7.4 từ repo chính thức. Dù có thể thêm PPA `ondrej/php` để cài PHP 8.3 trên 20.04, quá trình này gặp nhiều rủi ro:

| Vấn đề | Mô tả | Hệ quả |
|--------|-------|--------|
| PPA codename | `focal` không đồng bộ với OS release | Lỗi `apt update` |
| bcmath extension | Load sai phiên bản PHP 7.4 thay vì 8.3 | DB migration thất bại |
| Thư viện hệ thống | Tương thích không đảm bảo | Lỗi runtime khó debug |

**Khuyến nghị: Nếu đang dùng Ubuntu 20.04, nâng cấp OS lên 22.04 LTS trước:**

```bash
# 1. Backup toàn bộ dữ liệu trước
# 2. Nâng cấp OS
sudo do-release-upgrade
# 3. Sau khi reboot, kiểm tra lại
lsb_release -a
# 4. Cập nhật PPA nếu cần
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
```

> Script `upgrade_itsm_v10017-to-v11007.sh` có hỗ trợ auto-fix PPA codename, nhưng kết quả tốt nhất đạt được trên Ubuntu 22.04 LTS+.

### 2.4. So sánh GLPI 10.0.17 vs 11.0.7

#### Công nghệ nền tảng

| Khía cạnh | 10.0.17 | 11.0.7 |
|-----------|---------|--------|
| Framework | Legacy | **Symfony 7** |
| PHP | ≥ 7.4 | **≥ 8.2** (JIT, named arguments, fibers) |
| DB schema | Cơ bản | Tối ưu, chỉ mục thông minh, nhanh hơn 40% |
| Unicode | utf8mb3 | **utf8mb4** (emoji, ký tự đặc biệt) |

#### Giao diện & UX

| Tính năng | 10.0.17 | 11.0.7 |
|-----------|---------|--------|
| UI/UX | Cổ điển | **Thiết kế lại hoàn toàn** |
| Dark Mode | ❌ | ✅ |
| Responsive | Hạn chế | **Mượt mà mọi thiết bị** |
| Page Builder | ❌ | **Kéo thả dashboard** |

#### ITIL & Service Desk

| Tính năng | 10.0.17 | 11.0.7 |
|-----------|---------|--------|
| ITIL alignment | ITIL 3 | **ITIL 4 (Service Value System)** |
| Knowledge Base | Cơ bản | **WYSIWYG editor, phân loại, đánh giá** |
| Ticket templates | Có | **Mẫu thông minh, tự động điền** |
| SLA Management | Cơ bản | **Real-time, cảnh báo vi phạm** |
| Automation Rules | Hạn chế | **Business rules mạnh mẽ** |
| Service Catalog | ❌ | **Request form động** |

#### Bảo mật (bản 11.0.7)

Bản 11.0.7 vá **13 lỗ hổng bảo mật**:

| Mức | Mô tả |
|-----|-------|
| **High** | Stored XSS trong Knowledge Base, ITIL Costs |
| **High** | Xóa tài sản tùy ý qua planning (CVE-2026-42318) |
| **High** | Xóa file tùy ý bởi technician (CVE-2026-42317) |
| **Medium** | Xuất cấu trúc form trái phép (CVE-2026-32312) |
| **Medium** | Truy cập file tùy ý (CVE-2026-42320) |
| **Low-Medium** | SSRF, webhook, IMAP, quyền truy cập |

#### Hiệu năng & Mở rộng

| Tính năng | 10.0.17 | 11.0.7 |
|-----------|---------|--------|
| Query caching | ❌ | **Redis/Memcached** |
| OPcache | Cơ bản | **Tối ưu** |
| Async tasks | ❌ | **Messenger/Queue** |
| API | REST v1 | **REST v2 + OAuth2** |
| Webhooks | ❌ | ✅ |
| Multi-node | ❌ | ✅ |

---

## 3. Triển khai cài đặt mới (GLPI 11.0.7)

### 3.1. Script tự động

```bash
git clone https://github.com/PhDLeToanThang/itil-helpdesk.git
cd itil-helpdesk/Advanced
chmod +x deploy_itsm_v11007.sh
sudo ./deploy_itsm_v11007.sh
```

### 3.2. Các bước thực hiện

| Bước | Mô tả |
|------|-------|
| 1 | Cài đặt Nginx, MariaDB, PHP 8.3-FPM |
| 2 | Tạo database và user |
| 3 | Tải và cài đặt GLPI 11.0.7 |
| 4 | Cấu hình Nginx virtual host |
| 5 | Cài đặt phpMyAdmin |
| 6 | Cài đặt Certbot SSL Let's Encrypt |
| 7 | Cấu hình firewall (UFW) |

---

## 4. Nâng cấp từ GLPI 10.0.17 lên 11.0.7

### 4.1. Cảnh báo quan trọng

> **⚠️ Nâng cấp major version (10.x → 11.x) là quy trình một chiều (irreversible).**
> **Không thể rollback database schema sau khi nâng cấp. Bắt buộc backup trước khi thực hiện.**

**Điều kiện tiên quyết:**
- ✅ OS: **Ubuntu 22.04 LTS+** (không hỗ trợ 20.04)
- ✅ PHP: **≥ 8.2** (khuyến nghị 8.3) với đủ modules
- ✅ Database: **MariaDB ≥ 10.6** hoặc **MySQL ≥ 8.0**
- ✅ Disk: **≥ 20GB** trống

### 4.2. Quy trình tổng quan

```
1. Kiểm tra tiên quyết hệ thống
2. Backup database + mã nguồn
3. Bật chế độ bảo trì (Maintenance Mode)
4. Tải GLPI 11.0.7
5. Thay thế core files, giữ lại config / plugins / marketplace
6. Patch rawurldecode trong DBmysql::connect() ← QUAN TRỌNG
7. Chạy database migration
8. Tắt chế độ bảo trì
9. Kiểm tra kết quả
```

### 4.3. Yêu cầu tiên quyết

| Thành phần | Giá trị hiện tại (10.0.17) | Yêu cầu cho 11.0.7 | Hành động cần làm |
|-----------|---------------------------|-------------------|-------------------|
| **PHP** | ≥ 7.4 | **≥ 8.2** | `add-apt-repository ppa:ondrej/php -y && apt install php8.3-fpm php8.3-cli php8.3-{bcmath,bz2,curl,gd,intl,ldap,mbstring,mysql,xml,zip}` |
| **PHP modules** | thiếu bcmath, bz2... | bcmath, bz2, curl, dom, fileinfo, gd, intl, json, ldap, mbstring, mysqli, openssl, session, simplexml, xml, xmlreader, xmlwriter, zip | `apt install php8.3-bcmath php8.3-bz2` |
| **MariaDB** | ≥ 10.2 | **≥ 10.6** | Nâng cấp MariaDB nếu < 10.6 |
| **MySQL** | ≥ 5.7 | **≥ 8.0** | Nâng cấp MySQL nếu < 8.0 |
| **OS** | Ubuntu 20.04+ | **Ubuntu 22.04+** | `sudo do-release-upgrade` |
| **Disk** | ≥ 10GB | **≥ 20GB** | `df -h` kiểm tra |

### 4.4. Sử dụng script nâng cấp tự động

```bash
cd itil-helpdesk/Advanced
chmod +x upgrade_itsm_v10017-to-v11007.sh
sudo ./upgrade_itsm_v10017-to-v11007.sh
```

Script sẽ tự động thực hiện:

| Bước | Mô tả |
|------|-------|
| 1 | Kiểm tra tiên quyết (PHP, modules, DB version, OS) |
| 2 | Backup database, source code, plugins, marketplace → `/opt/glpi-backup-YYYYMMDD_HHMMSS/` |
| 3 | Tải & giải nén GLPI 11.0.7 |
| 4 | Bật maintenance, thay thế core, giữ config/plugins/files/marketplace, **patch rawurldecode** |
| 5 | Fix permissions |
| 6 | Chạy `php bin/console glpi:database:update --force`, nâng cấp plugins, clear cache |
| 7 | Tắt maintenance, restart services |

### 4.5. Hướng dẫn nâng cấp thủ công

#### Bước 1: Backup

```bash
# Database
mysqldump -u<user> -p<password> --single-transaction --routines --events --triggers <dbname> | gzip > /opt/glpi-backup/glpi-db-$(date +%Y%m%d).sql.gz

# Source code
tar czf /opt/glpi-backup/glpi-source-$(date +%Y%m%d).tar.gz \
  -C /var/www/html <thumuc-glpi> \
  --exclude="*/files/_dumps" --exclude="*/files/_cache" \
  --exclude="*/files/_log" --exclude="*/files/_sessions"

# Plugins
tar czf /opt/glpi-backup/glpi-plugins-$(date +%Y%m%d).tar.gz \
  -C /var/www/html/<thumuc-glpi> plugins/
```

#### Bước 2: Bật maintenance

```bash
echo "<?php return true;" > /var/www/html/<thumuc-glpi>/config/maintenance.php
```

#### Bước 3: Thay thế core

```bash
cd /opt
wget https://github.com/glpi-project/glpi/releases/download/11.0.7/glpi-11.0.7.tgz
tar xvf glpi-11.0.7.tgz

cd /var/www/html/<thumuc-glpi>
mkdir -p /tmp/glpi-keep
cp -a config files plugins marketplace /tmp/glpi-keep/

find . -mindepth 1 -maxdepth 1 \
  ! -name 'files' ! -name 'config' ! -name 'plugins' ! -name 'marketplace' \
  -exec rm -rf {} +

cp -a /opt/glpi-11.0.7/* /var/www/html/<thumuc-glpi>/
rm -rf config files plugins marketplace
cp -a /tmp/glpi-keep/* /var/www/html/<thumuc-glpi>/
rm -rf /tmp/glpi-keep
```

#### Bước 4: Patch rawurldecode (QUAN TRỌNG)

```bash
# Kiểm tra nếu password bị ảnh hưởng bởi rawurldecode
php8.3 -r '
$f="/var/www/html/<thumuc-glpi>/config/config_db.php";
$c=file_get_contents($f);
preg_match("/\$dbpassword\s*=\s*'\''([^'\'']*)'\''/",$c,$m);
$pass=$m[1] ?? "";
echo "Current password: $pass\n";
echo "Decoded: " . rawurldecode($pass) . "\n";
if ($pass !== rawurldecode($pass)) {
    echo "PATCH NEEDED: password changed by rawurldecode\n";
} else {
    echo "No patch needed\n";
}
'

# Nếu cần patch:
sed -i 's/rawurldecode($this->dbpassword)/$this->dbpassword/g' \
  /var/www/html/<thumuc-glpi>/src/DBmysql.php
```

#### Bước 5: Fix permissions

```bash
chown -R www-data:www-data /var/www/html/<thumuc-glpi>/
find /var/www/html/<thumuc-glpi>/ -type d -exec chmod 755 {} \;
find /var/www/html/<thumuc-glpi>/ -type f -exec chmod 644 {} \;
```

#### Bước 6: Nâng cấp database

```bash
cd /var/www/html/<thumuc-glpi>
php8.3 bin/console glpi:database:update --force
php8.3 bin/console glpi:plugin:install --all --force
php8.3 bin/console cache:clear
php8.3 bin/console glpi:cache:clear
```

#### Bước 7: Hoàn tất

```bash
rm -f /var/www/html/<thumuc-glpi>/config/maintenance.php
systemctl restart nginx php8.3-fpm mariadb
```

---

## 5. Xử lý sự cố & Lỗi thường gặp

### 5.1. Bảng xử lý sự cố nhanh

| Vấn đề | Nguyên nhân | Giải pháp |
|--------|-------------|-----------|
| Trang trắng (white screen) | Thiếu PHP module | `php -m` → `apt install php8.3-<module>` |
| Lỗi database connection | rawurldecode bug / sai config | Kiểm tra `config/config_db.php`, patch rawurldecode |
| Plugin không hoạt động | Chưa nâng cấp schema | `php bin/console glpi:plugin:install <plugin>` |
| Lỗi 500 Internal Server | Permissions sai | `chown -R www-data:www-data` + `chmod 755/644` |
| Lỗi "GLPI is installed" | Cache cũ | `rm -rf files/_cache/*` + `php bin/console cache:clear` |
| Web báo install lại | config_db.php không đọc được | Kiểm tra file tồn tại, syntax PHP đúng |

### 5.2. Extension bcmath load sai phiên bản PHP

**Triệu chứng:** `php8.3 -m | grep bcmath` không thấy bcmath, dù đã `apt install php8.3-bcmath`.

**Nguyên nhân:** Script cũ dùng `find /usr/lib/php -name "bcmath.so" | head -1` — có thể tìm thấy file `.so` của PHP 7.4 (thư mục `20190902`) thay vì PHP 8.3 (`20230831`).

**Fix:**
```bash
PHP_EXT_DIR=$(php8.3 -r 'echo PHP_EXTENSION_DIR;')
echo "extension=${PHP_EXT_DIR}/bcmath.so" > /etc/php/8.3/mods-available/bcmath.ini
```

### 5.3. rawurldecode bug — không kết nối được database

**Triệu chứng:** PHP `mysqli` test OK (`new mysqli(host, user, pass, db)`), nhưng GLPI báo:
- `Unable to connect to database` (CLI)
- `The connection to the SQL server could not be established. Please check your configuration.` (Web)

**Nguyên nhân:**

```
GLPI 11.0.7 connect() code:
  @$this->dbh->real_connect($host, $this->dbuser, rawurldecode($this->dbpassword), $this->dbdefault);
                                                         ^^^^^^^^^^^^^^^^
```

`rawurldecode` decode `%xx` sequences. Nếu password chứa `%` (VD: `%40T.c0m%402022`):
- Password gốc (MySQL): `%40T.c0m%402022`
- Sau `rawurldecode`: `@T.c0m@2022` ← **SAI, Access Denied!**

**Fix:** Script upgrade tự động patch ở Bước 4. Nếu làm thủ công:
```bash
sed -i 's/rawurldecode($this->dbpassword)/$this->dbpassword/g' /var/www/html/glpi/src/DBmysql.php
```

### 5.4. PPA codename không khớp sau upgrade OS

**Triệu chứng:** `apt update` báo lỗi `The repository '... focal Release' does not have a Release file`.

**Nguyên nhân:** Sau nâng cấp Ubuntu 20.04 (Focal) → 22.04 (Jammy), PPA `ondrej/php` vẫn giữ codename cũ.

**Fix:**
```bash
OS_CODENAME=$(lsb_release -sc)
sed -i "s/focal/$OS_CODENAME/g" /etc/apt/sources.list.d/ondrej-*.list
apt update
```

### 5.5. Không tìm thấy class DBmysql

**Triệu chứng:** `Fatal error: Class "DBmysql" not found in config_db.php` (khi test PHP CLI).

**Nguyên nhân:** Chưa include `vendor/autoload.php` trước `config_db.php`.

**Fix:**
```php
require '/path/to/glpi/vendor/autoload.php';   // Load autoloader TRƯỚC
require '/path/to/glpi/config/config_db.php';
$db = new DB();
```

Trong GLPI thật, autoloader luôn được Symfony bootstrapper load trước.

---

## 6. Rollback — Khôi phục từ backup

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

> **Lưu ý:** Chỉ rollback được database **nếu chưa chạy migration**. Sau khi chạy `glpi:database:update`, schema 11.0 không tương thích với code 10.0.

---

## 7. Kiểm tra & Vận hành

```bash
# Kiểm tra version
php bin/console glpi:system:status | grep version

# Kiểm tra requirements
php bin/console glpi:system:check_requirements

# Kiểm tra database integrity
php bin/console glpi:database:check_schema_integrity

# Kiểm tra log lỗi
tail -100 files/_log/php-errors.log

# Migration bổ sung (nếu còn cảnh báo)
php bin/console migration:utf8mb4 --allow-superuser
php bin/console migration:unsigned_keys --allow-superuser
```

---

## 8. Lý thuyết nền tảng ITIL & Chuẩn ngành

### 8.1. ITIL Framework

**ITIL (Information Technology Infrastructure Library)** là bộ thực hành tốt nhất cho IT Service Management (ITSM), tập trung vào việc căn chỉnh dịch vụ IT với nhu cầu kinh doanh.

#### 5 giai đoạn ITIL 4:

| Giai đoạn | Mô tả |
|-----------|-------|
| **Service Strategy** | Hiểu mục tiêu tổ chức và nhu cầu khách hàng |
| **Service Design** | Chuyển chiến lược thành kế hoạch triển khai |
| **Service Transition** | Phát triển và cải thiện khả năng giới thiệu dịch vụ mới |
| **Service Operation** | Quản lý dịch vụ trong môi trường vận hành |
| **Continual Service Improvement** | Cải tiến gia tăng và đột phá |

#### Lợi ích chính:

- Quản lý rủi ro kinh doanh và gián đoạn dịch vụ
- Cải thiện quan hệ khách hàng qua dịch vụ hiệu quả
- Hệ thống chi phí hiệu quả cho quản lý nhu cầu
- Hỗ trợ thay đổi kinh doanh trong môi trường ổn định

### 8.2. IT Asset Management (ITAM)

ITAM cung cấp thông tin chính xác về chi phí và rủi ro vòng đời tài sản công nghệ, tối đa hóa giá trị kinh doanh từ chiến lược công nghệ, kiến trúc, tài trợ, hợp đồng và quyết định mua sắm.

**Mục tiêu ITIL + ITAM:**
1. Mua sắm tài sản IT phù hợp, giữ chi phí thấp, lợi ích cao
2. Tối ưu hóa sử dụng từng tài sản IT
3. Loại bỏ tài sản khi chi phí duy trì vượt quá lợi ích
4. Cung cấp thông tin tuân thủ quy định, gia hạn license, hợp đồng

**Lợi ích ITAM Software:**
- Quản lý tuân thủ tài sản
- Tăng cường hiển thị tài sản
- Tăng trách nhiệm giải trình
- Giảm mua sắm không cần thiết
- Triển khai lại tài sản nhanh hơn
- Quản lý mức dịch vụ hợp đồng
- Tự động gia hạn hợp đồng
- Cải thiện lập ngân sách
- Kiểm soát chi phí IT tốt hơn

### 8.3. ITIL Incident Management

**Incident** là sự kiện có thể dẫn đến mất mát hoặc gián đoạn hoạt động, dịch vụ hoặc chức năng của tổ chức.

**Mục tiêu chính:**
1. Giải quyết incidents để giảm downtime cho business
2. Cải thiện chất lượng dịch vụ IT
3. Giám sát dịch vụ, phát hiện và giảm thiểu incidents
4. Truyền thông tiến trình xử lý major incidents
5. Đảm bảo SLA không bị vi phạm
6. Đo lường hiệu quả hoạt động incident management

**Cấu trúc Support Tiers:**

| Tier | Mô tả | Ví dụ |
|------|-------|-------|
| **L1** | Vấn đề cơ bản, thường xuyên lặp lại | Reset password, troubleshooting cơ bản |
| **L2** | Cần kỹ năng/đào tạo cao hơn | Reset token RSA, VIP support |
| **L3** | Major incidents, cần "all hands on deck" | Sự cố nghiêm trọng, hệ thống down |

### 8.4. ITIL Problem Management

**Problem** là nguyên nhân của incidents, cần điều tra và phân tích để xác định nguyên nhân gốc rễ.

**3 giai đoạn Problem Management:**

| Giai đoạn | Mô tả |
|-----------|-------|
| **Problem Identification** | Phát hiện và ghi nhận problems qua trend analysis, duplicate detection |
| **Problem Control** | Phân tích problem, document workarounds và known errors |
| **Error Control** | Quản lý known errors, đánh giá permanent solutions |

**Kỹ thuật phân tích:** Cynefin, Kepner-Tregoe, 5-Whys, Ishikawa diagrams, Pareto analysis.

### 8.5. ITIL Knowledge Management (DIKW Model)

**DIKW Model** là mô hình phân cấp cho luồng dữ liệu qua Information → Knowledge → Wisdom.

| Tầng | Mô tả | Câu hỏi |
|------|-------|---------|
| **Data** | Sự kiện rời rạc, đầu vào từ processes | — |
| **Information** | Data có ngữ cảnh | Who? What? When? Where? |
| **Knowledge** | Thông tin được phân tích, hỗ trợ quyết định | How? |
| **Wisdom** | Ứng dụng knowledge, nhận thức ngữ cảnh | Why? |

**Service Knowledge Management System (SKMS/SKBs):** Kho trung tâm của data, information và knowledge mà tổ chức IT cần để quản lý vòng đời dịch vụ.

### 8.6. Ticket & Service Desk

Giao diện Helpdesk của GLPI đáp ứng đầy đủ tiêu chuẩn ITIL 4:

- **Ticket queue** — Lọc, tạo dashboard theo nhu cầu
- **Centralization** — Một hệ thống cho hardware và ticket management
- **Assets relations** — Kết nối requests, equipment và users
- **Transparency** — Định nghĩa location, person/group, status, type, manufacturer
- **Coordination** — Insight vào queue, ưu tiên, notifications nội bộ và bên ngoài

### 8.7. COBIT — ITIL — ISO 27001/27002:2022

**Mối quan hệ giữa các framework:**

| Framework | Mục đích | Tập trung |
|-----------|----------|-----------|
| **COBIT** | IT Governance & Control | "What you should be doing" — control objectives, metrics |
| **ITIL** | Service Management | "How you should do it" — processes, best practices |
| **ISO 27001/27002** | Information Security | Security controls, risk management |

**Kết hợp cả ba là cách tiếp cận tốt nhất:**
- **COBIT** → Xác định nhu cầu business có được IT hỗ trợ đúng không
- **ISO** → Xác định và cải thiện tư thế bảo mật
- **ITIL** → Cải thiện IT processes để đáp ứng mục tiêu business (bao gồm security)

**COBIT 2019 Components:**

| Component | Mô tả |
|-----------|-------|
| Framework | Khung tham chiếu |
| Process Description | Mô tả quy trình |
| Control Objectives | Mục tiêu kiểm soát |
| Management Guidelines | Hướng dẫn quản lý |
| Maturity Models | Mô hình trưởng thành |

**Mapping ITIL 4 ↔ COBIT 2019 ↔ IT4IT:**

COBIT cung cấp **"what"** (mục tiêu kiểm soát), ITIL cung cấp **"how"** (quy trình thực hiện), ISO cung cấp **"security"** (kiểm soát an ninh). Sự kết hợp này tạo nên mô hình quản lý IT toàn diện.

---

## 9. Thông tin đăng nhập mặc định

| User | Password | Vai trò |
|------|----------|---------|
| `glpi` | `glpi` | Quản trị viên |
| `tech` | `tech` | Kỹ thuật viên |
| `normal` | `normal` | Người dùng thường |
| `post-only` | `postonly` | Người dùng chỉ gửi ticket |

> **⚠️ Đổi mật khẩu mặc định ngay sau đăng nhập!**

---

## 10. Tài liệu tham khảo

**Official:**
- [GLPI Project](https://glpi-project.org)
- [GLPI 11.0 Documentation](https://glpi-install.readthedocs.io)
- [GLPI Help Center](https://help.glpi-project.org)
- [GLPI Releases](https://github.com/glpi-project/glpi/releases)

**Repository:**
- [GitHub — itil-helpdesk](https://github.com/PhDLeToanThang/itil-helpdesk)
- [Advanced Deployment](https://github.com/PhDLeToanThang/itil-helpdesk/tree/master/Advanced)

**Frameworks & Standards:**
- [ITIL 4 Foundation](https://www.axelos.com/certifications/itil-service-management)
- [COBIT 2019](https://www.isaca.org/resources/cobit)
- [ISO 27001:2022](https://www.iso.org/standard/27001)
- [ISO 27002:2022](https://www.iso.org/standard/27002)

---

> *Maintained by **PhD Lê Toàn Thắng** — IT Service Management & Enterprise Architecture*
>
> *Last updated: 03/06/2026 — GLPI 11.0.7*
