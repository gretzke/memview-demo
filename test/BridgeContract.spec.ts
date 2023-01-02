import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { ethers } from 'hardhat';
import { BridgeContract } from '../typechain-types';

describe('Contract', () => {
  let account: SignerWithAddress;
  let contract: BridgeContract;

  before(async () => {
    account = (await ethers.getSigners())[0];
    const factory = await ethers.getContractFactory('BridgeContract');
    contract = (await factory.deploy()) as BridgeContract;
  });

  it('should be able to parse ERC20 transfer', async () => {
    const message = ethers.utils.solidityPack(['uint8', 'address', 'uint256'], [1, account.address, 1000]);
    await expect(contract.processMessage(message)).to.emit(contract, 'ERC20Transfer').withArgs(account.address, 1000);
  });

  it('should be able to parse ERC721 transfer', async () => {
    const message = ethers.utils.solidityPack(['uint8', 'uint8', 'address', 'uint256'], [2, 0, account.address, 123]);
    await expect(contract.processMessage(message)).to.emit(contract, 'ERC721Transfer').withArgs(account.address, 123);
  });

  it('should be able to parse ERC1155 transfer', async () => {
    const message = ethers.utils.solidityPack(
      ['uint8', 'uint8', 'address', 'uint256', 'uint256'],
      [2, 1, account.address, 123, 1000]
    );
    await expect(contract.processMessage(message))
      .to.emit(contract, 'ERC1155Transfer')
      .withArgs(account.address, 123, 1000);
  });

  it('should be able to parse a smart contract call', async () => {
    const data = ethers.utils.randomBytes(64);
    const message = ethers.utils.solidityPack(['uint8', 'bytes4', 'bytes'], [3, '0x23b872dd', data]);
    await expect(contract.processMessage(message)).to.emit(contract, 'ContractCall').withArgs('0x23b872dd', data);
  });
});
