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
├── deploy_itsm_v10017.sh    # Script deploy GLPI 10.0.17 (legacy)
├── deploy_itsm_v11007.sh    # Script deploy GLPI 11.0.7 (mới nhất)
└── README.md                # Tài liệu hướng dẫn (file này)
```

## Hướng dẫn sử dụng

### Yêu cầu hệ thống

| Thành phần | Yêu cầu |
|-----------|---------|
| OS | Ubuntu 22.04 LTS hoặc 24.04 LTS |
| RAM | ≥ 4GB (khuyến nghị 8GB) |
| Disk | ≥ 20GB (khuyến nghị SSD) |
| CPU | ≥ 2 cores |
| Database | MariaDB ≥ 10.6 hoặc MySQL ≥ 8.0 |
| PHP | 8.2 — 8.3 |
| Web Server | Nginx hoặc Apache 2.4 |

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
