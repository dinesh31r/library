# 📚 Library Management System

A production-ready, feature-rich web application built with **.NET 8 (ASP.NET Core MVC)**, **Entity Framework Core**, **MySQL**, and **ASP.NET Core Identity**. The system supports full library operations including catalog administration, circulation (issuing/returning books), online holds & reservations, automated overdue fine calculation, reporting & analytics, and role-based access control (RBAC).

---

## 🌟 Key Features

### 👤 Role-Based Access Control (RBAC)
- **Admin**: Full catalog & user administration, system configuration, financial reports, audit logging.
- **Librarian**: Desk operations, checkout/checkin processing, copy status management, hold fulfillment, fine collection.
- **User (Member)**: Catalog searching, book reservations, online renewal, loan history tracking, notification center.

### 📖 Catalog Management
- Hierarchical structure supporting **Books**, **Physical Book Copies**, **Authors**, **Publishers**, and **Categories**.
- Real-time physical copy tracking (`Available`, `Issued`, `Reserved`, `Maintenance`, `Damaged`, `Lost`).

### 🔄 Circulation & Hold Engine
- **Check-out / Issue:** Enforces user borrowing limits, overdue blocks, and active fine checks.
- **Check-in / Return:** Automated calculation of late return fees based on configurable daily rates.
- **Hold & Reservations:** Automated queue management; notifies patrons when reserved titles become available upon return.
- **Renewals:** Online self-service loan extension subject to renewal count limits and reservation checks.

### 💰 Fine & Payment Tracking
- Automatic overdue fine generation.
- Support for recording payments (Cash, Card, Online) or processing administrator fine waivers.
- Aggregated financial tracking (Collected vs. Outstanding pending fines).

### 📊 Analytics & Reporting
- Comprehensive executive reports:
  - Circulation trends (Most borrowed titles, active loans)
  - Category breakdowns
  - Financial reports (Fine revenue & outstanding debts)
  - Audit logging for operational transparency

---

## 🛠️ Technology Stack

| Component | Technology |
|---|---|
| **Framework** | .NET 8.0 ASP.NET Core MVC |
| **ORM** | Entity Framework Core 8.0 (`Pomelo.EntityFrameworkCore.MySql`) |
| **Database** | **MySQL / MariaDB** (Default, fully integrated with **SQLyog**) |
| **Authentication** | ASP.NET Core Identity (Cookie-based auth with RBAC) |
| **Data Utilities** | CsvHelper (Data import/export) |
| **Frontend** | Razor Views, Vanilla CSS, JavaScript, HTML5 |

---

## 🐬 Database Configuration & SQLyog Management

The application is configured to use **MySQL / MariaDB** as its default database engine.

### 1. `appsettings.json` Configuration:
```json
{
  "DatabaseProvider": "MySql",
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=LibraryDb;User=root;Password=root;"
  }
}
```
*Note: Replace `root` / `root` with your MySQL server credentials if different.*

### 2. Viewing & Managing Data in SQLyog:
1. Launch **SQLyog**.
2. Create a new Connection:
   - **MySQL Host Address:** `localhost` (or `127.0.0.1`)
   - **Username:** `root`
   - **Password:** *your MySQL root password*
   - **Port:** `3306`
   - **Database:** `LibraryDb`
3. Click **Connect** to manage tables, run queries, and monitor real-time library transactions visually!

---

## 🧪 Testing & Verification Guide

### 1. Build & Compilation Verification
To verify that the project compiles cleanly without errors:
```powershell
dotnet build
```
*Expected Output:* `Build succeeded. 0 Warning(s), 0 Error(s)`

### 2. Role-Based End-to-End Test Scenarios

#### 👑 Scenario A: Administrator Verification
1. Log in at `http://localhost:5026/Account/Login` using `admin@library.com` / `Admin@123456`.
2. **Dashboard Test:** Confirm system statistics (Total Books, Total Users, Active Loans, Overdue Fines) render correctly.
3. **User Management Test:** Navigate to **Administration -> User Management**. Test creating a new user, updating roles, or toggling user status.
4. **Audit Log Verification:** Navigate to **Administration -> Audit Logs** to confirm system actions are recorded with timestamps and IP addresses.

#### 📚 Scenario B: Librarian Desk Operations Test
1. Log in using `librarian@library.com` / `Librarian@123456`.
2. **Issue Book Test:** Navigate to **Circulation -> Issue Book**. Select a patron and an available book copy to check out.
3. **Return & Fine Calculation Test:** Navigate to **Circulation -> Return Book**. Search by copy barcode/ID and process a return. If the loan is overdue, verify fine calculation.
4. **Fine Collection Test:** Navigate to **Circulation -> Fines**. Record a cash or card payment and verify status updates to `Paid`.

#### 👤 Scenario C: Member Self-Service Test
1. Log in using `user@library.com` / `User@123456`.
2. **Catalog Search Test:** Navigate to **Browse Books**. Search for a title/author and view physical copy availability.
3. **Reservation Test:** Place a hold request on a book.
4. **Self-Service Renewal Test:** Navigate to **My Borrowings** and click **Renew** on an active loan.

### 3. Database Integrity & SQLyog Verification
1. Connect **SQLyog** to your MySQL instance (`localhost:3306`, database `LibraryDb`).
2. Verify the following core tables are populated with seed data:
   - `AspNetUsers`: Contains Admin, Librarian, and User seed accounts.
   - `Books` & `BookCopies`: Contains catalog items and physical barcodes.
   - `Borrowings`: Tracks active and completed loan transactions.
   - `Fines`: Tracks pending, paid, and waived fee records.
   - `AuditLogs`: Captures operational events across the application.

---

## 🚀 Quick Start Guide

### Prerequisites
- [.NET 8.0 SDK](https://dotnet.microsoft.com/download/dotnet/8.0) installed.
- **MySQL Server** / **MariaDB** (or XAMPP/WAMP) running locally on port `3306`.

### Running the Application

1. **Navigate to the project folder:**
   ```powershell
   cd c:\Projects\library\LibraryManagementSystem
   ```

2. **Run the application:**
   ```powershell
   dotnet run --launch-profile http
   ```

3. **Access the application:**
   Open your browser and navigate to:
   👉 **`http://localhost:5026`**

---

## 🔑 Default Seed Credentials

Upon first startup, the system automatically initializes the MySQL database schema (`LibraryDb`) and seeds initial sample records alongside pre-configured accounts:

| Role | Email | Password |
|---|---|---|
| 👑 **Admin** | `admin@library.com` | `Admin@123456` |
| 📚 **Librarian** | `librarian@library.com` | `Librarian@123456` |
| 👤 **User (Member)** | `user@library.com` | `User@123456` |

---

## 📂 Project Structure

```
LibraryManagementSystem/
├── Controllers/            # MVC Controllers (Admin, Librarian, User, Books, Fines, etc.)
├── Data/                   # DbContext and DbInitializer (MySQL Seed Data)
├── Models/                 # Domain Entities (Book, Borrowing, Fine, Reservation, User, etc.)
├── Services/               # Business Logic Layer (Book, Borrowing, Fine, Audit, Settings)
├── ViewModels/             # View Data Models & DTOs
├── Views/                  # Razor Views grouped by module
└── wwwroot/                # Static assets (CSS, JS, Libraries)
```

---

## 📝 License
This project is open source and available for educational and production deployment.
