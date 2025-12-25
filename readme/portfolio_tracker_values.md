# Portfolio Tracker - Valid Values Reference

This document lists all valid values for dropdown fields in the Portfolio Tracker module. These values are used when importing/exporting investment data and when creating or editing investments in the app.

---

## Investment Category

The category of the investment. Use the **Display Name** when importing/exporting data.

| Enum Name | Display Name |
|-----------|--------------|
| `cryptocurrency` | Cryptocurrency |
| `usShare` | US Share |
| `indianShare` | Indian Share |
| `mutualFundEquity` | Mutual Fund - Equity |
| `mutualFundDebt` | Mutual Fund - Debt |
| `goldBond` | Gold Bond |
| `nationalPensionScheme` | National Pension Scheme |
| `publicProvidentFund` | Public Provident Fund |
| `guaranteedInvestment` | Guaranteed Investment |
| `employeeProvidentFund` | Employee Provident Fund |
| `employeePensionScheme` | Employee Pension Scheme |
| `emergencyAccount` | Emergency Account |

**Note:** When importing data, you can use either the enum name (case-insensitive) or the display name. The export will use the display name.

---

## Investment Tracking Type

The type of tracking method for the investment.

| Enum Name | Display Name |
|-----------|--------------|
| `unit` | Unit |
| `amount` | Amount |

**Note:** When importing data, you can use either the enum name (case-insensitive) or the display name. The export will use the display name.

---

## Investment Currency

The currency in which the investment is denominated.

| Enum Name | Display Name | Symbol |
|-----------|--------------|--------|
| `inr` | INR | ₹ |
| `usd` | USD | $ |

**Note:** When importing data, you can use either the enum name (case-insensitive) or the display name. The export will use the display name.

---

## Risk Factor

The risk level associated with the investment.

| Enum Name | Display Name |
|-----------|--------------|
| `insane` | Insane |
| `high` | High |
| `medium` | Medium |
| `low` | Low |

**Note:** When importing data, you can use either the enum name (case-insensitive) or the display name. The export will use the display name.

---

## Import/Export Notes

### Export Behavior
- Exported files will contain **Display Names** (e.g., "US Share", "Unit", "USD", "High")
- This matches what users see in the app interface

### Import Behavior
- The import function accepts both enum names and display names (case-insensitive)
- Examples of valid import values:
  - `usShare` or `US Share` or `us share` → all work
  - `unit` or `Unit` or `UNIT` → all work
  - `usd` or `USD` → both work
  - `high` or `High` or `HIGH` → all work

### Required Fields for Import
When importing investment data, the following fields are required:
- `shortName` - Short identifier for the investment
- `name` - Full name of the investment
- `investmentCategory` - One of the values listed above
- `investmentTrackingType` - One of the values listed above
- `investmentCurrency` - One of the values listed above
- `riskFactor` - One of the values listed above

### Optional Fields for Import
- `id` - Investment ID (for updating existing investments)
- `created_at` - Creation date (defaults to current date if not provided)
- `updated_at` - Last update date (defaults to current date if not provided)
- `delete` - Set to "Yes" or "Y" to delete an investment (requires `id`)

---

## Quick Reference

### All Valid Values (Display Names)

**Investment Category:**
- Cryptocurrency
- US Share
- Indian Share
- Mutual Fund - Equity
- Mutual Fund - Debt
- Gold Bond
- National Pension Scheme
- Public Provident Fund
- Guaranteed Investment
- Employee Provident Fund
- Employee Pension Scheme
- Emergency Account

**Investment Tracking Type:**
- Unit
- Amount

**Investment Currency:**
- INR
- USD

**Risk Factor:**
- Insane
- High
- Medium
- Low

---

## See Also

- [README.md](README.md) - Main project documentation
- [ARCHITECTURE.md](../ARCHITECTURE.md) - Architecture overview
- Portfolio Tracker export/import functions in `lib/trackers/portfolio_tracker/features/investment_import_export.dart`

