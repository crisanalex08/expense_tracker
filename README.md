# SpentLog – Project Specification
### How many times it happend that at the end of salary you had half of month left?
## 1. Overview


SpentLog is a mobile expense tracking application designed to help users manage personal finances efficiently. The app allows users to manually add expenses or automatically extract them from scanned receipts using Optical Character Recognition (OCR). It provides visual analytics for spending habits on weekly and monthly bases.

The system is built as a lightweight alternative to complex budgeting tools, focusing on simplicity and usability.

---

## 2. Objectives

- Enable fast and simple expense tracking
- Support manual and automated (receipt-based) expense input
- Provide clear financial insights via charts and summaries
- Simplify onboarding with Google Sign-In authentication
- Establish a foundation for future AI-based enhancements

---

## 3. Core Features

### 3.1 Authentication
- Google Sign-In integration (Firebase)
- User registration and login

### 3.2 Expense Management
- Add expense manually
- View list of all expenses

### 3.3 Receipt Scanning (OCR)
- Capture receipt images via camera
- Extract text using OCR engine
- Parse key fields using regex:
  - Total amount
  - Merchant name
  - Date (if available)
- Auto-create expense entry from extracted data

### 3.4 Categories
Predefined categories:
- Food
- Transport
- Bills
- Misc

Categories are designed to be extendable in future versions.

### 3.5 Dashboard & Analytics
- Weekly expense overview
- Monthly expense overview
- Pie chart visualization by category
- Tabular summary of spending

---

## 4. System Design

### 4.1 Architecture
- Mobile-first application (Flutter-based)
- Local processing for OCR and parsing
- Optional cloud integration for user data sync (future extension)

### 4.2 Data Flow
1. User adds expense manually OR scans receipt
2. OCR extracts raw text (if applicable)
3. Regex parser extracts structured data
4. Expense stored in Firestore
5. Dashboard aggregates and visualizes data

---

## 5. Technologies

- Flutter (Mobile UI)
- Google Sign-In (Authentication)
- OCR Engine (Google OCR)
- Local Database (local storage + Firestore)

---

## 6. Limitations

- OCR accuracy depends on receipt quality
- Regex-based parsing is not robust for unstructured formats
- No AI-based categorization currently implemented
- No real-time cloud synchronization in current version

---

## 7. Future Improvements

- AI-based receipt understanding and categorization
- Custom user-defined expense categories
- Cloud synchronization across devices
- Advanced analytics (spending trends, predictions)
- Export data (CSV / PDF reports)

---

## 8. Authors

- Sole Developer: *Alex Crisan*

---
