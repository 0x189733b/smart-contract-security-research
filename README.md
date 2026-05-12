# Smart Contract Security Research

Security research & vulnerability discovery by **Adom Asare** — Computer Science student at the University of Ghana.  
Actively competing in audit contests on **HackenProof**, **Code4rena** and **Sherlock**.

## Featured Findings

| # | Title                              | Severity | Protocol Type | Status     | PoC |
|---|------------------------------------|----------|---------------|------------|-----|
| 1 | Spot Price Oracle Manipulation     | High     | Lending       | Reported   | [→](findings/oracle-manipulation.md) |
| 2 | `amountOutMin = 0` Sandwich Attack | Medium   | AMM           | Reported   | [→](findings/sandwich-attack.md) |
| 3 | Fee-on-Transfer Vault Insolvency   | High     | Vault         | Reported   | [→](findings/fee-on-transfer.md) |

## Setup & Running PoCs

```bash
git clone https://github.com/0x189733b/smart-contract-security-research.git
cd smart-contract-security-research

# Example: Run oracle manipulation PoC
cd pocs/oracle-manipulation
forge test -vvv
