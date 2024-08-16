# Hardhat Tasks for Novaro Deployment and Configuration

This project includes custom Hardhat tasks to deploy and configure the `DynamicSocialToken` (DST) and `StakingPool` contracts.

## Tasks

### Deploy and Configure DST

This task deploys the `DynamicSocialToken` (DST) and `StakingPool` contracts, initializes the DST contract, reads interval data from a JSON file, and configures the intervals for the DST contract.

#### Command

```bash
npx hardhat deploy-novaro --mapping-name <json-file> --network <network-name>
```

#### Example Usage

```bash
npx hardhat deploy-novaro --mapping-name dst_interval_config.json --network hardhat
```

#### Parameters

- `mapping-name`: The name of the JSON file containing interval data (located in the `config/mapping` folder).
- `network`: The target network for deployment (e.g., `hardhat`, `ropsten`, etc.).

#### Output

- The contract addresses are saved to a JSON file in the `deployments` directory, named according to the target network (e.g., `hardhat_addresses.json`).

### Configure DST Intervals

This task configures the intervals for the `DynamicSocialToken` (DST) contract by reading data from a specified JSON file.

#### Command

```bash
npx hardhat read-dst-interval --dst-address <contract-address> --mapping-name <json-file>
```

#### Parameters

- `dst-address`: The address of the deployed `DynamicSocialToken` contract.
- `mapping-name`: The name of the JSON file containing interval data.