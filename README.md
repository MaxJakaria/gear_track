# 🛠️ GearTrack — Smart Inventory, POS & Analytics Management System

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Backend-Cloud_Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![State Management](https://img.shields.io/badge/State_Management-BLoC_Pattern-8A2BE2)](https://bloclibrary.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean_Architecture-brightgreen)](#-system-architecture)
[![License](https://img.shields.io/badge/License-Academic_FYP-blue)](#)

> **GearTrack** is a cross-platform inventory management, Point of Sale (POS), and business analytics application built with **Flutter**, **Firebase Cloud Firestore**, and **BLoC (Clean Architecture)**. Developed as a **Final Year Project (FYP)** to streamline retail operations, track inventory real-time, generate PDF invoices, and provide visual business intelligence.

---

## 📌 Table of Contents

- [Project Overview](#-project-overview)
- [Key Features & Modules](#-key-features--modules)
  - [1. Inventory Management](#1-inventory-management)
  - [2. Point of Sale (POS) & Billing](#2-point-of-sale-pos--billing)
  - [3. Receipt & PDF Invoicing](#3-receipt--pdf-invoicing)
  - [4. Reports & Business Analytics](#4-reports--business-analytics)
- [System Architecture](#-system-architecture)
- [Project Directory Structure](#-project-directory-structure)
- [Tech Stack & Dependencies](#-tech-stack--dependencies)
- [Installation & Setup](#-installation--setup)
- [Testing](#-testing)
- [Future Enhancements](#-future-enhancements)

---

## 📖 Project Overview

Small to medium-sized retail businesses often face challenges with fragmented tools for inventory management, checkout billing, and financial reporting. **GearTrack** solves this by offering an all-in-one solution:

- **Real-time Synchronization:** Instant updates to stock levels upon sales transactions via Cloud Firestore.
- **Fast Point of Sale:** Smooth checkout experience with cart management and automated calculations.
- **Automated Invoicing:** On-the-fly PDF invoice generation ready for physical printing or digital sharing.
- **Actionable Analytics:** Visual dashboards showing revenue trends, profit margins, and performance KPIs.

---

## 🚀 Key Features & Modules

### 1. Inventory Management

- **Product Catalog:** Full CRUD capabilities (Create, Read, Update, Delete) for inventory products.
- **Stock Tracking:** Real-time stock counts with purchase cost, retail selling price, and profit estimation.
- **Search & Filtering:** Instant search by product name and categories.
- **Quick Stock Adjustment:** Bottom sheets for rapid stock increments/decrements.
- **Low Stock Alerts:** Visual warning indicators for items running low on stock.

### 2. Point of Sale (POS) & Billing

- **Fast Product Search:** Real-time lookup with instant stock validation.
- **Smart Cart Management:** Add items, adjust quantities, calculate real-time item totals, and prevent selling out-of-stock items.
- **Automated Calculations:** Computes subtotal, customizable tax/VAT, and discount deductions.
- **Inventory Sync:** Automatically deducts sold quantities from the Firestore inventory collection upon successful checkout.

### 3. Receipt & PDF Invoicing

- **Instant Receipt Generation:** Generates styled PDF invoices using the `pdf` and `printing` packages.
- **Thermal & Standard Print Support:** Interactive print preview and direct printing support.
- **Digital Sharing:** Export and share receipts directly to customers.

### 4. Reports & Business Analytics

- **Executive KPI Cards:** Quick overview of Total Revenue, Net Profit, Total Orders, and Units Sold.
- **Visual Charts (`fl_chart`):**
  - **Daily Sales Trends:** Interactive line/bar charts showing daily sales fluctuations.
  - **Monthly Profit Overview:** Comparison between cost and gross profits.
- **Date Range Filters:** Filter data by today, this week, this month, or custom date ranges via an embedded calendar.
- **Transaction Logs:** Detailed sales transaction history with full itemized breakdown.

---

## 🏗️ System Architecture

**GearTrack** adheres to **Clean Architecture** principles and **Feature-First** modular organization, ensuring scalability, maintainability, and testability.

```
       ┌───────────────────────────────────────┐
       │           Presentation Layer          │
       │   (UI Pages, Widgets, BLoC / States)  │
       └───────────────────┬───────────────────┘
                           │
       ┌───────────────────▼───────────────────┐
       │              Domain Layer             │
       │     (Entities, UseCases, Contracts)   │
       └───────────────────▲───────────────────┘
                           │
       ┌───────────────────┴───────────────────┐
       │               Data Layer              │
       │   (Models, Remote Data Sources, Repos)│
       └───────────────────────────────────────┘
```

- **Domain Layer:** Pure Dart code containing business entities, use case classes, and abstract repository contracts.
- **Data Layer:** Handles API/Firestore communication, data mapping (DTO/Models), and repository implementations.
- **Presentation Layer:** Flutter UI components, state management with `flutter_bloc`, and reactive rendering.
- **Dependency Injection:** Handled cleanly with `get_it` service locator (`lib/init_dependencies.dart`).
- **Functional Error Handling:** Uses `fpdart`'s `Either<Failure, Success>` pattern to handle errors without throwing unhandled exceptions.

---

## 📁 Project Directory Structure

```plaintext
lib/
├── core/
│   ├── error/              # Failure classes & Exception handlers
│   ├── utils/              # Helper functions & formatters
│   └── widgets/            # Reusable UI widgets (Buttons, TextFields, etc.)
│
├── dependencies/           # Feature dependency injection modules
│   ├── inventory.dart
│   ├── pos.dart
│   └── reports.dart
│
├── feature/
│   ├── inventory/          # Inventory Feature Module
│   │   ├── data/           # Models, Data Sources, Repository Implementations
│   │   ├── domain/         # Entities, Repository Interfaces, UseCases
│   │   └── presentation/   # Inventory BLoC, Pages, and Custom Widgets
│   │
│   ├── point_of_sale/      # POS & Checkout Feature Module
│   │   ├── data/           # Sale models, Remote Data Sources
│   │   ├── domain/         # Cart & Sale entities, Repositories, UseCases
│   │   ├── presentation/   # POS BLoC, Cart Widgets, POS Main Screen
│   │   └── utils/          # PDF Receipt Generation & Print Service
│   │
│   └── reports/            # Analytics & Reporting Module
│       ├── data/           # Reports data source & repository impl
│       ├── domain/         # Analytics models, UseCases
│       └── presentation/   # Reports BLoC, KPI Cards, Charts & Calendar
│
├── presentation/
│   └── pages/              # Main App Shell & Bottom Navigation Bar
│
├── firebase_options.dart   # Firebase configuration
├── init_dependencies.dart  # Global Service Locator setup (GetIt)
└── main.dart               # Application entry point
```

---

## 💻 Tech Stack & Dependencies

| Category                   | Technology / Package                                                                                    | Description                                         |
| -------------------------- | ------------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| **Framework**              | [Flutter](https://flutter.dev) (v3.x)                                                                   | UI Framework for cross-platform apps                |
| **Language**               | [Dart](https://dart.dev) (v3.x)                                                                         | Object-oriented client-optimized language           |
| **Backend & Database**     | [Firebase Cloud Firestore](https://firebase.google.com)                                                 | Real-time NoSQL cloud database                      |
| **State Management**       | [flutter_bloc](https://pub.dev/packages/flutter_bloc) + [equatable](https://pub.dev/packages/equatable) | Predictable event-driven state management           |
| **Dependency Injection**   | [get_it](https://pub.dev/packages/get_it)                                                               | Service locator for clean decoupling                |
| **Functional Programming** | [fpdart](https://pub.dev/packages/fpdart)                                                               | Functional programming & `Either` error handling    |
| **Charts & Visualization** | [fl_chart](https://pub.dev/packages/fl_chart)                                                           | Highly customizable interactive charts              |
| **Invoicing & PDF**        | [pdf](https://pub.dev/packages/pdf) & [printing](https://pub.dev/packages/printing)                     | Document generation and thermal/printer integration |
| **Date & Localization**    | [intl](https://pub.dev/packages/intl)                                                                   | Currency formatting and date manipulation           |

---

## ⚙️ Installation & Setup

### Prerequisites

1. **Flutter SDK:** Install Flutter 3.12+ ([Guide](https://docs.flutter.dev/get-started/install)).
2. **Dart SDK:** Included with Flutter.
3. **Firebase Account:** A Firebase project configured with Cloud Firestore.
4. **Android Studio / VS Code:** Configured with Flutter and Dart plugins.

### Steps

1. **Clone the repository:**

   ```bash
   git clone https://github.com/MaxJakaria/gear_track.git
   cd gear_track
   ```

2. **Install project dependencies:**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   - Make sure you have the [Firebase CLI](https://firebase.google.com/docs/cli) and [FlutterFire CLI](https://firebase.flutter.dev/docs/cli) installed.
   - Run the configuration command if setting up with a new Firebase project:
     ```bash
     flutterfire configure
     ```
   - Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are properly placed if configuring manually.

4. **Run the Application:**
   ```bash
   flutter run
   ```

---

## 🧪 Testing

Run all unit and repository tests using Flutter's test runner:

```bash
flutter test
```

Specific feature tests:

```bash
flutter test test/feature/reports/reports_repository_test.dart
```

---

## 🔮 Future Enhancements

- [ ] Multi-store & branch management support
- [ ] Barcode / QR Code scanning for instant checkout
- [ ] User authentication with role-based access control (Admin vs Cashier)
- [ ] Offline caching and background synchronization

---

## 👨‍💻 Author & Attribution

- **Project:** Final Year Project (FYP)
- **Repository:** [MaxJakaria/gear_track](https://github.com/MaxJakaria/gear_track)
- **Developer:** Max Jakaria
