import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer, utils } from 'ethers';

const addressToBytes32 = (address: string): string => {
  if (address.length === 42) {
    return `0x${address
      .toLowerCase()
      .slice(2)
      .padStart(64, '0')}`;
  }
  return '';
};

describe('TokenFactory', () => {
  let TokenFactory: Contract;
  let StandardToken: Contract;

  const contractVersion = '1';
  const tokenName = 'Template';
  const tokenSymbol = 'TEMP';
  const tokenDecimals = BigNumber.from('18');
  const initialToken = BigNumber.from('100000000000000000000');

  let wallet: Signer;
  let walletTo: Signer;
  let Dummy: Signer;

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet, walletTo, Dummy] = accounts;

    const TokenFactoryTemplate = await ethers.getContractFactory('contracts/TokenFactory.sol:TokenFactory', wallet);
    TokenFactory = await TokenFactoryTemplate.deploy();

    const StandardTokenTemplate = await ethers.getContractFactory('contracts/StandardToken.sol:StandardToken', wallet);
    StandardToken = await StandardTokenTemplate.deploy();

    await StandardToken.deployed();
    await StandardToken.initialize(contractVersion, tokenName, tokenSymbol, tokenDecimals);
  });

  describe('#newTemplate()', () => {
    it('should be success when set token template', async () => {
      const tokenAddress = StandardToken.address;
      const value = utils.parseUnits('0.01');
      const key = addressToBytes32(tokenAddress);
      await expect(TokenFactory.newTemplate(tokenAddress, value))
        .to.emit(TokenFactory, 'SetTemplate')
        .withArgs(key, tokenAddress, value);
    });

    it('should be revert when set same token template', async () => {
      const tokenAddress = StandardToken.address;
      const value = utils.parseUnits('0.01');
      const key = addressToBytes32(tokenAddress);
      await expect(TokenFactory.newTemplate(tokenAddress, value))
        .to.emit(TokenFactory, 'SetTemplate')
        .withArgs(key, tokenAddress, value);
      await expect(TokenFactory.newTemplate(tokenAddress, value)).to.be.revertedWith('TokenFactory/Already Exist');
    });
  });

  describe('#updateTemplate()', () => {
    it('should be success when set token template', async () => {
      const tokenAddress = StandardToken.address;
      const value = utils.parseUnits('0.01');
      const afterValue = utils.parseUnits('0.011');
      const key = addressToBytes32(tokenAddress);
      await expect(TokenFactory.newTemplate(tokenAddress, value))
        .to.emit(TokenFactory, 'SetTemplate')
        .withArgs(key, tokenAddress, value);
      await expect(TokenFactory.updateTemplate(key, tokenAddress, afterValue))
        .to.emit(TokenFactory, 'SetTemplate')
        .withArgs(key, tokenAddress, afterValue);
    });

    it('should be revert when set same token template', async () => {
      const tokenAddress = StandardToken.address;
      const value = utils.parseUnits('0.01');
      const key = addressToBytes32(tokenAddress);
      await expect(TokenFactory.updateTemplate(key, tokenAddress, value)).to.be.revertedWith(
        'TokenFactory/Template is Not Exist',
      );
    });
  });

  describe('#deleteTemplate()', () => {
    it('should be success when delete token template', async () => {
      const tokenAddress = StandardToken.address;
      const value = utils.parseUnits('0.01');
      const key = addressToBytes32(tokenAddress);
      await expect(TokenFactory.newTemplate(tokenAddress, value))
        .to.emit(TokenFactory, 'SetTemplate')
        .withArgs(key, tokenAddress, value);
      await expect(TokenFactory.deleteTemplate(key))
        .to.emit(TokenFactory, 'RemovedTemplate')
        .withArgs(key);
    });

    it('should be revert when Dont exist token template', async () => {
      const tokenAddress = StandardToken.address;
      const key = addressToBytes32(tokenAddress);
      await expect(TokenFactory.deleteTemplate(key)).to.be.revertedWith('TokenFactory/Template is Not Exist');
    });
  });
});
