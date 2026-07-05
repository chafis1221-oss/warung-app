
# 🛒 Warung Mama Fahri

![Build Status](https://img.shields.io/github/actions/workflow/status/chafis1221-oss/warung-app/deploy.yml?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)
![Platform](https://img.shields.io/badge/platform-Android-brightgreen?style=flat-square)
![Language](https://img.shields.io/badge/Go-1.21-00ADD8?style=flat-square&logo=go)
![Flutter](https://img.shields.io/badge/Flutter-3.24-02569B?style=flat-square&logo=flutter)

A lightning-fast, offline-first product catalog and price checker designed for small grocery shops. Built with simplicity and speed in mind, this app allows shopkeepers to instantly browse, search, and manage products even on low-end devices and unstable networks.

---

## ✨ Features

- **⚡ Instant Search & Filter**  
  All product data lives in local memory. Search, sort (A-Z, price), and filter by category happen entirely on the device — no network lag.

- **📱 Offline-First**  
  Works seamlessly without an internet connection. Data is cached locally and automatically refreshed when a connection is available.

- **🖼️ Smart Image Caching**  
  Product images are compressed to 300x300 thumbnails and cached persistently. No double-loading — images are only re-fetched when changed.

- **🔌 Flexible Connectivity**  
  Automatically connects to the local server via Wi-Fi. Falls back to Cloudflare Tunnel when outside the local network.

- **🗂️ Full CRUD Admin**  
  Intuitive admin panel for adding, editing, and deleting products. Includes in-app category management and bulk import from Supabase.

- **🧮 Built-in Calculator**  
  A simple calculator with history — handy for quick price calculations.

- **🌙 Minimalist UI**  
  Clean white-and-green theme inspired by traditional Indonesian grocery shops. Toggle between list and grid views.

- **🔒 Secure & Lightweight**  
  No authentication required (intended for local use). Backend runs as a single Go binary with SQLite — minimal resources, maximum reliability.

---

## 🧱 Tech Stack

| Layer      | Technology                              |
| ---------- | --------------------------------------- |
| Frontend   | Flutter 3.24 (Android)                  |
| Backend    | Go 1.21 + `net/http`                    |
| Database   | SQLite (via `mattn/go-sqlite3`)         |
| Server     | STB Armbian (ARM64)                     |
| Tunnel     | Cloudflare Tunnel                       |
| CI/CD      | GitHub Actions (auto-build & release)   |

---

## 🏗️ Architecture

```

[ Android App (Flutter) ]
│
▼
[ Local Wi-Fi: 192.168.1.17:8088 ]  ─── OR ─── [ Cloudflare Tunnel: backend.chafis.my.id ]
│
▼
[ Go Backend (STB Armbian) ]
├── In-Memory Cache
├── SQLite Database
├── Image Storage (thumbnails)
└── Cloudflare Tunnel Service

```

- **Backend** serves a REST API and static image files.
- **All product data** is loaded once into the phone's memory and filtered client-side.
- **Images** are thumbnailed (300px) and cached using `CachedNetworkImage` with MD5 version keys.

---

## 📸 Screenshots

| Home (List) | Home (Grid) | Admin Panel |
|-------------|-------------|-------------|
| ![list](screenshots/list.png) | ![grid](screenshots/grid.png) | ![admin](screenshots/admin.png) |

> *Replace with actual screenshots before public release.*

---

## 🚀 Getting Started

### Prerequisites

- **STB Armbian** with Go 1.21+, SQLite3, and ImageMagick installed.
- **Android device** running Android 5.0+.
- (Optional) **Cloudflare Tunnel** for remote access.

### 1. Clone the repository

```bash
git clone https://github.com/chafis1221-oss/warung-app.git
cd warung-app
```

2. Setup the Backend (on STB)

```bash
cd backend
go build -o warung-server main.go
sqlite3 db/warung.db < scripts/init_db.sql
sudo cp deploy/warung-server.service /etc/systemd/system/
sudo systemctl enable warung-server
sudo systemctl start warung-server
```

The server will start on port 8088.

3. Setup Cloudflare Tunnel (optional)

```bash
sudo apt install cloudflared
cloudflared tunnel login
cloudflared tunnel create warung-tunnel
cloudflared tunnel route dns warung-tunnel backend.chafis.my.id
# Edit /root/.cloudflared/config.yml with your tunnel details
cloudflared service install
```

4. Build the Flutter App

1. Open the frontend/ folder in your Flutter IDE.
2. Update config.dart with your server URLs.
3. Place your warung-keystore.jks in the root (or configure GitHub Secrets for CI/CD).
4. Run:

```bash
flutter pub get
flutter build apk --release
```

5. GitHub Actions CI/CD

This repo uses GitHub Actions to automatically build and release a signed APK on every push to main.
Set the following GitHub Secrets:

· KEYSTORE_BASE64 – Base64-encoded keystore file.
· KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD
· (Optional) STB_HOST, STB_USER, STB_SSH_KEY for auto-deploy.

---

📡 API Reference

Products

Method Endpoint Description
GET /api/products List all products (cached)
GET /api/products?search=&kategori=&page=&limit= Search & filter
POST /api/products Create a new product
PUT /api/products/{id} Update product name/price/category
DELETE /api/products/{id} Delete a product (and its image)
POST /api/products/{id}/image Upload & auto-compress image
GET /api/products/version Get latest update timestamp
GET /api/products/export Export all products as CSV

Misc

Method Endpoint Description
GET /api/categories List all categories
GET /health Health check
GET /images/{file} Serve static thumbnails

---

🤝 Contributing

This is a personal project, but suggestions and bug reports are welcome!
Please open an issue before submitting any major changes.

---

📄 License

MIT License © 2025 – Warung Mama Fahri

```

README.md ini mencakup semua aspek proyek secara profesional dan lengkap. Jika ada yang perlu ditambahkan atau diubah, beri tahu.
