# Community Fundraiser Smart Contract

A decentralized fundraising platform built on the Stacks blockchain that enables community members to create, contribute to, and manage fundraising campaigns for various projects and causes.

## 📝 Description

The Community Fundraiser smart contract provides a transparent and trustless way to raise funds for community projects. It features automated fund management, goal tracking, and secure fund distribution mechanisms.

### Key Features

- Create fundraising campaigns with customizable goals and deadlines
- Accept STX token donations from community members
- Automatic tracking of campaign progress
- Secure fund withdrawal system
- Campaign status verification
- Donation history tracking

## 🛠 Technical Stack

- Language: Clarity
- Platform: Stacks Blockchain
- Development Framework: Clarinet
- Testing: Clarinet Test Suite

## 📋 Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- [Stacks Wallet](https://www.hiro.so/wallet) for contract interaction
- Basic understanding of Clarity and Stacks blockchain

## 🚀 Getting Started

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/community-fundraiser
cd community-fundraiser
```

2. Install dependencies:
```bash
clarinet install
```

### Contract Deployment

1. Test the contract:
```bash
clarinet test
```

2. Check contract:
```bash
clarinet check
```

3. Deploy to testnet:
```bash
clarinet deploy --network testnet
```

## 💡 Usage

### Creating a Campaign

```clarity
(contract-call? .community-fund create-campaign 
    u1000000                         ;; goal amount in µSTX
    "Community Garden Project"        ;; campaign title
    "Creating a sustainable garden"   ;; campaign description
    u144                             ;; duration in blocks
)
```

### Making a Donation

```clarity
(contract-call? .community-fund donate
    u1                               ;; campaign ID
    u500000                          ;; donation amount in µSTX
)
```

### Withdrawing Funds

```clarity
(contract-call? .community-fund withdraw-funds
    u1                               ;; campaign ID
)
```

## 📊 Contract Functions

### Public Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `create-campaign` | Creates a new fundraising campaign | `goal`: uint, `title`: string-ascii, `description`: string-ascii, `duration`: uint |
| `donate` | Contributes STX to a campaign | `campaign-id`: uint, `amount`: uint |
| `withdraw-funds` | Withdraws funds when goal is reached | `campaign-id`: uint |

### Read-Only Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `get-campaign` | Retrieves campaign details | `campaign-id`: uint |
| `get-donation` | Gets donation amount for a donor | `campaign-id`: uint, `donor`: principal |
| `is-goal-reached` | Checks if campaign goal is met | `campaign-id`: uint |

## 🔒 Security Features

- Owner-only withdrawal access
- Goal-based fund release
- Deadline enforcement
- Active campaign status verification
- Protected fund management

## ⚠️ Error Codes

| Code | Description |
|------|-------------|
| u100 | Not owner |
| u101 | Campaign inactive |
| u102 | Goal reached |
| u103 | Deadline passed |
| u104 | Unauthorized |

## 🧪 Testing

The contract includes comprehensive test cases covering all major functionality:

```bash
# Run all tests
clarinet test

# Run specific test file
clarinet test tests/community-fund_test.ts
```

## 📈 Project Structure

```
community-fundraiser/
├── contracts/
│   └── community-fund.clar
├── tests/
│   └── community-fund_test.ts
├── settings/
│   └── Devnet.toml
└── Clarinet.toml
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📬 Contact

Your Name - [@yourusername](https://twitter.com/yourusername)

Project Link: [https://github.com/yourusername/community-fundraiser](https://github.com/yourusername/community-fundraiser)

## 🙏 Acknowledgments

- Stacks Foundation
- Hiro Systems
- Clarity Language Documentation
- Community Contributors
