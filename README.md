# 📋 Universal Compliance Registry

A blockchain-based compliance registry built with Clarity smart contracts for immutable storage and verification of regulatory compliance documents across industries.

## 🚀 Overview

The Universal Compliance Registry enables companies in regulated industries (oil, food, logistics, etc.) to store compliance documents immutably on the Stacks blockchain. Regulators can instantly verify compliance status, creating transparency and trust in regulatory processes.

## ✨ Key Features

- 🏢 **Company Registration** - Register companies with industry classification
- 📄 **Document Submission** - Submit compliance documents with metadata
- ✅ **Regulator Verification** - Authorized regulators can verify/reject documents
- 🔍 **Instant Compliance Checks** - Real-time compliance status verification
- 🔒 **Immutable Storage** - Tamper-proof document records on blockchain
- ⏰ **Expiration Tracking** - Automatic tracking of document validity periods

## 🛠️ Smart Contract Functions

### Public Functions

#### Company Management
```clarity
(register-company (name (string-ascii 100)) (industry (string-ascii 50)) (registration-number (string-ascii 50)))
```
Register a new company in the system.

#### Document Management
```clarity
(submit-compliance-document (industry (string-ascii 50)) (document-type (string-ascii 100)) (document-hash (buff 32)) (expires-at uint) (metadata (string-ascii 500)))
```
Submit a compliance document for verification.

#### Regulator Functions
```clarity
(add-regulator (regulator principal))
(remove-regulator (regulator principal))
(verify-document (document-id uint) (verification-note (string-ascii 200)))
(reject-document (document-id uint) (rejection-note (string-ascii 200)))
(update-document-status (document-id uint) (new-status (string-ascii 20)))
```
Manage regulators and document verification status.

### Read-Only Functions

```clarity
(get-document (document-id uint))
(get-company-profile (company principal))
(get-company-compliance-status (company principal) (industry (string-ascii 50)))
(is-regulator (regulator principal))
(is-document-valid (document-id uint))
(is-company-compliant (company principal) (industry (string-ascii 50)))
(verify-document-hash (document-id uint) (provided-hash (buff 32)))
```

## 📖 Usage Instructions

### 1. Deploy Contract
```bash
clarinet deploy --testnet
```

### 2. Register as Regulator (Contract Owner Only)
```clarity
(contract-call? .Universal-Compliance-Registry add-regulator 'ST1REGULATOR123...)
```

### 3. Register Company
```clarity
(contract-call? .Universal-Compliance-Registry register-company "Acme Food Corp" "food" "REG123456")
```

### 4. Submit Compliance Document
```clarity
(contract-call? .Universal-Compliance-Registry submit-compliance-document 
  "food" 
  "HACCP Certificate" 
  0x1234567890abcdef... 
  u2000000 
  "Annual HACCP compliance certificate")
```

### 5. Verify Document (Regulator Only)
```clarity
(contract-call? .Universal-Compliance-Registry verify-document u1 "Document meets regulatory standards")
```

### 6. Check Compliance Status
```clarity
(contract-call? .Universal-Compliance-Registry is-company-compliant 'ST1COMPANY... "food")
```

## 🏭 Industry Applications

- **🛢️ Oil & Gas** - Environmental compliance, safety certifications
- **🍕 Food Industry** - HACCP, FDA approvals, quality certifications  
- **🚛 Logistics** - Transportation licenses, safety compliance
- **💊 Pharmaceuticals** - Drug approvals, manufacturing certifications
- **🏭 Manufacturing** - ISO certifications, safety compliance

## 🔧 Development

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet)
- Node.js (for testing)

### Setup
```bash
git clone https://github.com/your-repo/Universal-Compliance-Registry
cd Universal-Compliance-Registry
clarinet check
clarinet test
```

### Testing
```bash
clarinet test
```

## 📊 Data Structures

### Company Profile
- Name, industry, registration number
- Registration timestamp and active status

### Compliance Document
- Company, industry, document type
- Document hash, issuance/expiration dates
- Status (pending/verified/rejected/active/suspended/revoked)
- Regulator and metadata

### Compliance Status
- Real-time compliance status per company/industry
- Count of active and expired documents

## 🔐 Security Features

- **Access Control** - Only authorized regulators can verify documents
- **Immutable Records** - Blockchain-based tamper-proof storage
- **Hash Verification** - Document integrity through cryptographic hashes
- **Expiration Tracking** - Automatic validity period management

## 📝 License

MIT License - Feel free to use for regulatory compliance applications.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request with clear description

---

Built with ❤️ using Stacks blockchain and Clarity smart contracts
