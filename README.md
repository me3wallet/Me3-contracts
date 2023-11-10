# Me3

## Usage

### Pre Requisites

Before running any command, you need to create a `.env` file
Follow the example in `.env.example`.

Then, proceed with installing dependencies:

```sh
yarn install
```

### Compile

Compile the smart contracts with Hardhat:

```sh
$ yarn compile
```

### Lint Solidity

Lint the Solidity code:

```sh
$ yarn lint:sol
```

### Test

Run the tests:

```sh
$ yarn test
```

### Coverage

Generate the code coverage report:

```sh
$ yarn coverage
```

### Report Gas

See the gas usage per unit test and average gas per method call:

```sh
$ REPORT_GAS=true yarn test
```

### Clean

Delete the smart contract artifacts, the coverage reports and the Hardhat cache:

```sh
$ yarn clean
```

### Deploy

Deploy the contracts to Hardhat Network:

```sh
$ yarn deploy
```

## Syntax Highlighting

If you use VSCode, you can enjoy syntax highlighting for your Solidity code via the
[vscode-solidity](https://github.com/juanfranblanco/vscode-solidity) extension. The recommended approach to set the
compiler version is to add the following fields to your VSCode user settings:

```json
{
  "solidity.compileUsingRemoteVersion": "v0.8.4+commit.c7e474f2",
  "solidity.defaultCompiler": "remote"
}
```

Where of course `v0.8.4+commit.c7e474f2` can be replaced with any other version.

## Understanding the me3 Contracts

## Me3 Farm

This is the core protocol for the me3 farming contract.

```js
stake();
```

| **Parameter** | **Type**  | **Description**                                        |
| ------------- | --------- | ------------------------------------------------------ |
| `amount`      | _uint256_ | The amount a user wants to stake in the me3 farm    |
| `lockPeriod`  | _uint256_ | Total amount of time user wants his funds to be locked |

```js
withdraw();
```

| **Parameter** | **Type**  | **Description**                                                   |
| ------------- | --------- | ----------------------------------------------------------------- |
| `amount`      | _uint256_ | The amount of stake a user wants to withdraw from the me3 farm |

```js
calculateReward();
```

| **Parameter** | **Type**  | **Description**                                                               |
| ------------- | --------- | ----------------------------------------------------------------------------- |
| `recordId`    | _uint256_ | Calculates the reward a particular stake record will recieve in me3 Tokens |

```js
calculateHoursPassed();
```

| **Parameter** | **Type**  | **Description**                                                   |
| ------------- | --------- | ----------------------------------------------------------------- |
| `duration`    | _uint256_ | Calculates the number of hours that have been passed |

## Me3 Storage

The Me3 storage contract is the DB of the me3 protocol. It holds the getter and setter methods of the me3 protocol
