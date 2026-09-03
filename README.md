# 🛠️ GearTrack — Smart Inventory, POS, Return & Analytics Management System

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Backend-Cloud_Firestore_%26_Auth-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![State Management](https://img.shields.io/badge/State_Management-BLoC_Pattern-8A2BE2)](https://bloclibrary.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean_Architecture-brightgreen)](#-system-architecture)
[![License](https://img.shields.io/badge/License-Academic_FYP-blue)](#)

> **GearTrack** is an enterprise-grade, cross-platform retail management solution built with **Flutter**, **Firebase Cloud Firestore**, and **BLoC (Clean Architecture)**. Designed as a comprehensive **Final Year Project (FYP)**, it integrates real-time inventory tracking, high-speed Point of Sale (POS), sales returns & refund processing, QR receipt verification, offline-capable PDF document generation, and visual business intelligence into a seamless, modern application.

---

## 📌 Table of Contents

- [Project Overview](#-project-overview)
- [System Architecture](#-system-architecture)
- [Key Features & Modules](#-key-features--modules)
  - [1. User Authentication & Security](#1-user-authentication--security)
  - [2. Inventory & Stock Management](#2-inventory--stock-management)
  - [3. Point of Sale (POS) & Billing](#3-point-of-sale-pos--billing)
  - [4. Sales Returns & Refund Management](#4-sales-returns--refund-management)
  - [5. Receipt Verification & Scanner](#5-receipt-verification--scanner)
  - [6. Business Intelligence & Reports](#6-business-intelligence--reports)
  - [7. Offline PDF Engine](#7-offline-pdf-engine)
- [Project Directory Structure](#-project-directory-structure)
- [Tech Stack & Dependencies](#-tech-stack--dependencies)
- [Database Schema (Firestore)](#-database-schema-firestore)
- [Getting Started](#-getting-started)
- [Building for Production](#-building-for-production)
- [Author & Acknowledgments](#-author--acknowledgments)

---

## 📖 Project Overview

Traditional retail workflows often suffer from fragmented tools—disconnected spreadsheets for stock, manual POS calculation, clumsy return tracking, and complex accounting. **GearTrack** consolidates retail operations into a unified, responsive ecosystem:

- **Real-time Synchronization:** Stock levels and financial metrics update immediately upon sales or returns via Cloud Firestore transactions.
- **Fast Point of Sale:** Streamlined cart management, automated discount and tax calculations, and instant receipt generation.
- **Return & Refund Integrity:** Strict item validation, automatic stock replenishment, and dedicated PDF refund vouchers.
- **Offline Document Engine:** Standalone, bundled-font PDF engine capable of generating reports and receipts anywhere without internet dependencies.
- **Executive Analytics:** Interactive charts and date-filtered KPIs offering deep visibility into revenue, profit margins, and sales velocity.

---

## 🏗️ System Architecture

GearTrack is built strictly on **Clean Architecture** and **Feature-First** modular design principles.

```
       ┌──────────────────────────────────────────────────┐
       │                Presentation Layer                │
       │   (Screens, Widgets, BLoC State Management)      │
       └────────────────────────┬─────────────────────────┘
                                │
       ┌────────────────────────▼─────────────────────────┐
       │                   Domain Layer                   │
       │   (Entities, Use Cases, Repository Contracts)    │
       └────────────────────────▲─────────────────────────┘
                                │
       ┌────────────────────────┴─────────────────────────┐
       │                    Data Layer                    │
       │   (Models / DTOs, Remote Data Sources, Firebase) │
       └──────────────────────────────────────────────────┘
```

### Architecture Highlights:
- **Separation of Concerns:** Business rules in the Domain layer have zero dependencies on Flutter UI or Firebase SDKs.
- **Dependency Injection:** Centralized service locator with `get_it` (`lib/init_dependencies.dart`).
- **Functional Error Handling:** Errors are modeled with `fpdart`'s `Either<Failure, Success>` pattern to eliminate unhandled runtime exceptions.
- **Theme Engine:** Built-in dynamic Light and Dark mode with custom color tokens (`AppTheme`).

---

## 🚀 Key Features & Modules

### 1. User Authentication & Security
- **Firebase Authentication:** Secure email and password authentication (`AuthBloc`).
- **Session Persistence:** Automatic session recovery on app launch with auth state listeners.
- **Shop Profile Configuration:** Editable shop name, address, phone number, and currency settings.

### 2. Inventory & Stock Management
- **Full Catalog Management:** Add, edit, delete, and view items with part numbers, models, and categories.
- **Stock Tracking & Pricing:** Tracks purchase costs, selling prices, available quantities, and estimated gross margin.
- **Instant Search & Category Filters:** Fast client-side and remote search capabilities.
- **Visual Stock Status:** Low-stock and out-of-stock badges and alerts.

### 3. Point of Sale (POS) & Billing
- **Fast Product Lookup:** Quick search and instant addition to the active cart.
- **Stock Guard:** Real-time stock validation preventing checkout of out-of-stock items.
- **Dynamic Cart Calculations:** Subtotal, custom discounts, VAT/tax deductions, and total amount.
- **Atomic Checkout Transactions:** Firestore batch writes ensure inventory deduction and sales logging succeed atomically.
- **Digital & Printable Receipts:** Immediate PDF receipt generation with thermal print support.

### 4. Sales Returns & Refund Management
- **Invoice-Based Returns:** Lookup past invoices to process partial or full item returns.
- **Validation Guard:** Prevents returning more units than originally purchased.
- **Automatic Stock Replenishment:** Restores returned item quantities back to active inventory.
- **Refund Voucher Generation:** Dedicated PDF Return & Refund Voucher (`PdfReturnVoucherService`).

### 5. Receipt Verification & Scanner
- **QR / Barcode Scanning:** Built-in camera scanner via `mobile_scanner` for rapid receipt lookup.
- **Manual Verification:** Invoice ID search to verify customer receipts, purchase dates, and itemized lists.

### 6. Business Intelligence & Reports
- **Executive KPI Metrics:** Real-time calculation of Total Investment, Total Sales, Gross Profit, and Profit Margin.
- **Performance Trend Visualizations (`fl_chart`):**
  - **Daily Sales Trends:** Daily revenue graph with date-based plotting.
  - **Monthly Profit Overview:** Side-by-side comparison of monthly sales and net profits.
- **Flexible Date Range Filtering:** Switch between Today, This Month, All Time, or Custom Date Ranges via an embedded calendar.
- **Detailed Sales History Table:** Horizontal scrollable, center-aligned data grid displaying Serial No., Date, Product Name, Part No., Quantity, Unit Price, and Total Price.

### 7. Offline PDF Engine
- **100% Offline Capability:** Bundles `NotoSansBengali-Regular.ttf` and `NotoSansBengali-Bold.ttf` inside local app assets (`assets/fonts/`).
- **Zero Network Latency:** Eliminates Google Fonts CDN delays and generates reports instantaneously (0 ms delay).
- **Unicode & Bengali Support:** Flawless rendering of Unicode Bengali text and currency symbols (`৳`).
- **Standardized Styling:** Clean table borders, repeat headers across pages, shop metadata headers, and itemized breakdowns.

---

## 📁 Project Directory Structure

```plaintext
lib/
├── core/
│   ├── common/             # Global entities, cubits, and widgets
│   ├── entities/           # Core entities (e.g. ShopSettings)
│   ├── error/              # Failure models & Exception classes
│   ├── theme/              # AppTheme, light/dark color palettes
│   └── utils/              # Formatters, currency helpers, and validators
│
├── dependencies/           # Feature-specific Dependency Injection modules
│   ├── auth.dart
│   ├── inventory.dart
│   ├── pos.dart
│   ├── receipt_verification.dart
│   ├── reports.dart
│   └── return.dart
│
├── feature/
│   ├── auth/               # User Authentication Module
│   │   ├── data/           # Auth remote data sources & repository impl
│   │   ├── domain/         # User entities, Auth repository contracts, UseCases
│   │   └── presentation/   # AuthBloc, Login & Registration screens
│   │
│   ├── inventory/          # Inventory Management Module
│   │   ├── data/           # Product models & Firestore data sources
│   │   ├── domain/         # Product entities & Inventory use cases
│   │   └── presentation/   # InventoryBloc, Product list, Add/Edit sheets
│   │
│   ├── point_of_sale/      # POS & Checkout Module
│   │   ├── data/           # Sale models, invoice records & data sources
│   │   ├── domain/         # Cart item entities & Checkout use cases
│   │   ├── presentation/   # PosBloc, Cart widgets, Checkout page
│   │   └── utils/          # PDF Receipt service
│   │
│   ├── receipt_verification/ # Scanner & Invoice Lookup Module
│   │   ├── domain/         # Verification use cases
│   │   └── presentation/   # Camera QR scanner & verification screen
│   │
│   ├── returns/            # Sales Return & Refund Module
│   │   ├── data/           # Return record models & Firestore sources
│   │   ├── domain/         # Return entities & ProcessReturn use case
│   │   ├── presentation/   # ReturnBloc & Process return screens
│   │   └── utils/          # PDF Return voucher service
│   │
│   └── reports/            # Analytics & Business Intelligence Module
│       ├── data/           # Analytics calculation sources & repositories
│       ├── domain/         # Analytics summaries & report entities
│       ├── presentation/   # ReportsBloc, KPI cards, Trend charts, Sales table
│       └── utils/          # Standalone offline PDF Report generator
│
├── presentation/           # Main App Shell & Bottom Navigation Bar
├── firebase_options.dart   # Generated Firebase configuration
├── init_dependencies.dart  # Global Service Locator setup (GetIt)
└── main.dart               # Application entry point
```

---

## 💻 Tech Stack & Dependencies

| Layer / Category            | Technology / Package                                                                                    | Purpose                                             |
| --------------------------- | ------------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| **Framework**               | [Flutter](https://flutter.dev) (v3.x)                                                                   | Cross-platform UI toolkit                           |
| **Language**                | [Dart](https://dart.dev) (v3.x)                                                                         | Client-optimized, strongly typed language           |
| **Backend & Database**      | [Firebase Cloud Firestore](https://firebase.google.com)                                                 | Real-time NoSQL cloud database                      |
| **Authentication**          | [Firebase Auth](https://firebase.google.com/products/auth)                                               | Secure user authentication & sessions               |
| **State Management**        | [flutter_bloc](https://pub.dev/packages/flutter_bloc) + [equatable](https://pub.dev/packages/equatable) | Predictable, reactive event-driven state management |
| **Dependency Injection**    | [get_it](https://pub.dev/packages/get_it)                                                               | Decoupled service locator architecture              |
| **Functional Error Handle** | [fpdart](https://pub.dev/packages/fpdart)                                                               | `Either<Failure, Success>` functional programming   |
| **Visual Charts**           | [fl_chart](https://pub.dev/packages/fl_chart)                                                           | Interactive sales & profit charts                   |
| **Invoicing & PDF**         | [pdf](https://pub.dev/packages/pdf) & [printing](https://pub.dev/packages/printing)                     | Native PDF creation and thermal print integration   |
| **Barcode / QR Scanning**   | [mobile_scanner](https://pub.dev/packages/mobile_scanner)                                               | High-speed camera barcode/QR scanner                |
| **Date & Localization**     | [intl](https://pub.dev/packages/intl)                                                                   | Number and date formatting                          |

---

## 🗄️ Database Schema (Firestore)

```
firestore_root/
├── users/ {userId}
│   ├── shopName: String
│   ├── address: String
│   ├── phone: String
│   └── currency: String
│
├── products/ {productId}
│   ├── itemName: String
│   ├── model: String
│   ├── partNo: String
│   ├── category: String
│   ├── costPrice: Double
│   ├── sellPrice: Double
│   ├── stock: Integer
│   └── updatedAt: Timestamp
│
├── sales/ {saleId}
│   ├── invoiceNo: String
│   ├── items: Array<CartItemModel>
│   ├── subtotal: Double
│   ├── discount: Double
│   ├── tax: Double
│   ├── totalAmount: Double
│   └── saleDate: Timestamp
│
└── returns/ {returnId}
    ├── originalInvoiceId: String
    ├── returnedItems: Array<ReturnItemModel>
    ├── totalRefundAmount: Double
    └── returnDate: Timestamp
```

---

## ⚙️ Getting Started

### Prerequisites
1. **Flutter SDK:** 3.12+ ([Install Flutter](https://docs.flutter.dev/get-started/install)).
2. **Firebase Project:** Configured with Cloud Firestore & Firebase Auth.
3. **IDE:** VS Code or Android Studio with Flutter/Dart extensions.

### Installation

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/MaxJakaria/gear_track.git
   cd gear_track
   ```

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   ```bash
   flutterfire configure
   ```

4. **Run the App:**
   ```bash
   flutter run
   ```

---

## 📦 Building for Production

To generate optimized, architecture-specific Android release APKs:

```bash
flutter build apk --split-per-abi
```

**Output Artifacts:**
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

---

## 👨‍💻 Author & Acknowledgments

- **Project:** Final Year Project (FYP)
- **Developer:** Max Jakaria
- **Repository:** [MaxJakaria/gear_track](https://github.com/MaxJakaria/gear_track)
- **Built with:** ❤️, Flutter, Firebase, and Clean Architecture
