# CosmeticTrace

CosmeticTrace is a comprehensive supply chain tracking smart contract for cosmetic product ingredients and testing verification built on the Stacks blockchain. This contract provides end-to-end traceability from raw ingredient sourcing to final product manufacturing, ensuring transparency, authenticity, and safety in the cosmetics supply chain.

## Features

- **Ingredient Registry**: Register and verify raw cosmetic ingredients with supplier information and certifications
- **Batch Tracking**: Track ingredient batches through the entire supply chain with ownership transfers
- **Quality Testing**: Record and verify safety and quality test results from certified testing bodies
- **Product Traceability**: Create final cosmetic products with full ingredient batch traceability
- **Supplier Verification**: Maintain a verified supplier registry with authorization controls
- **Supply Chain Transparency**: Complete audit trail from ingredient source to final product
- **Multi-stakeholder Support**: Support for suppliers, manufacturers, testers, and regulatory bodies

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity
- **Version**: 1.0.0
- **Clarity Version**: 2
- **Epoch**: 2.5

## Architecture

The contract implements five core data structures:

1. **Ingredients**: Raw material registry with supplier and certification data
2. **Batches**: Trackable units of ingredients with manufacturing and expiry dates
3. **Test Results**: Quality and safety testing records with pass/fail status
4. **Products**: Final cosmetic products linking to ingredient batches
5. **Verified Suppliers**: Registry of authorized suppliers

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) for Clarity development
- Node.js and npm for testing framework
- Stacks wallet for deployment

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd CosmeticTrace
```

2. Install dependencies:
```bash
cd CosmeticTrace_contract
npm install
```

3. Run tests:
```bash
npm test
```

4. Run tests with coverage:
```bash
npm run test:report
```

5. Watch mode for development:
```bash
npm run test:watch
```

## Usage Examples

### Registering an Ingredient

```clarity
;; Register a new organic shea butter ingredient
(contract-call? .CosmeticTrace register-ingredient
  "Organic Shea Butter"
  'SP1234...SUPPLIER
  "Ghana"
  "USDA Organic")
```

### Creating an Ingredient Batch

```clarity
;; Create a batch of the registered ingredient
(contract-call? .CosmeticTrace create-batch
  u1          ;; ingredient-id
  u1000       ;; quantity (1000 units)
  u1640995200 ;; manufacturing-date (timestamp)
  u1672531200 ;; expiry-date (timestamp)
)
```

### Recording Test Results

```clarity
;; Record safety test results for a batch
(contract-call? .CosmeticTrace record-test-result
  u1                    ;; batch-id
  "Heavy Metal Test"    ;; test-type
  "All levels within safe limits" ;; result
  true                  ;; passed
  (some 'SP5678...TESTER)) ;; certification-body
```

### Creating a Final Product

```clarity
;; Create a final cosmetic product using verified batches
(contract-call? .CosmeticTrace create-product
  "Premium Face Cream"
  (list u1 u2 u3))     ;; list of batch-ids used
```

## Contract Functions

### Public Functions

#### Administrative Functions
- `register-ingredient(name, supplier, origin-country, certification)` - Register new ingredient (owner only)
- `verify-ingredient(ingredient-id)` - Verify ingredient authenticity (owner only)
- `verify-supplier(supplier)` - Add supplier to verified registry (owner only)

#### Supply Chain Functions
- `create-batch(ingredient-id, quantity, manufacturing-date, expiry-date)` - Create ingredient batch (verified suppliers only)
- `transfer-batch(batch-id, new-owner)` - Transfer batch ownership
- `record-test-result(batch-id, test-type, result, passed, certification-body)` - Record test results
- `create-product(name, ingredient-batches)` - Create final product using verified batches

### Read-Only Functions

#### Data Retrieval
- `get-ingredient(ingredient-id)` - Get ingredient details
- `get-batch(batch-id)` - Get batch information
- `get-test-result(test-id)` - Get test result details
- `get-product(product-id)` - Get product information
- `get-supplier-status(supplier)` - Check supplier verification status
- `get-counters()` - Get current ID counters

#### Validation
- `is-batch-tested(batch-id)` - Check if batch has passed required tests

## Error Codes

- `u100` - ERR_UNAUTHORIZED: Insufficient permissions
- `u101` - ERR_NOT_FOUND: Resource not found
- `u102` - ERR_ALREADY_EXISTS: Resource already exists
- `u103` - ERR_INVALID_BATCH: Invalid batch operation
- `u104` - ERR_INVALID_TEST: Invalid test operation
- `u105` - ERR_INGREDIENT_NOT_VERIFIED: Ingredient not verified

## Deployment Guide

### Local Development

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy contract:
```clarity
::deploy_contract CosmeticTrace
```

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deployments apply --network testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`
2. Ensure thorough testing and security audit completion
3. Deploy using Clarinet:
```bash
clarinet deployments apply --network mainnet
```

## Workflow

1. **Setup Phase**:
   - Deploy contract
   - Verify suppliers
   - Register ingredients

2. **Production Phase**:
   - Suppliers create ingredient batches
   - Transfer batches through supply chain
   - Conduct quality testing at each stage

3. **Manufacturing Phase**:
   - Manufacturers acquire verified batches
   - Create final products with full traceability
   - Maintain audit trail for regulatory compliance

## Security Considerations

### Access Control
- Contract owner has exclusive rights to ingredient and supplier verification
- Only verified suppliers can create ingredient batches
- Only current batch owners can transfer ownership
- Batch usage is tracked to prevent double-spending

### Data Integrity
- All timestamps use block-height for tamper resistance
- Batch expiry dates are enforced
- Test results are immutable once recorded
- Product creation requires verified ingredient batches

### Audit Trail
- Complete supply chain history maintained on-chain
- All operations logged with block-height timestamps
- Supplier verification tracks authorization source
- Test results include tester and certification body information

## Testing

The project includes comprehensive test coverage using Vitest and Clarinet SDK:

- Unit tests for all public functions
- Integration tests for complete workflows
- Error condition testing
- Gas cost analysis

Run the full test suite:
```bash
npm run test:report
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

ISC License

## Support

For technical support or questions about implementation, please refer to the contract documentation or create an issue in the repository.