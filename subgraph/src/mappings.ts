import { Address, BigInt, ethereum } from "@graphprotocol/graph-ts";
import { Pool, LiquidityEvent, LoanAction, LoanPosition, Swap, VaultAccount, VaultAction } from "../generated/schema";
import { PoolCreated } from "../generated/PoolFactory/PoolFactory";
import { Burn, Mint, Swap as SwapEvent } from "../generated/AMMPool/AMMPool";
import { Deposit, Withdraw } from "../generated/YieldVault/YieldVault";
import {
  Borrowed,
  CollateralDeposited,
  CollateralWithdrawn,
  Liquidated,
  Repaid
} from "../generated/LendingPool/LendingPool";

const ZERO = BigInt.fromI32(0);

export function handlePoolCreated(event: PoolCreated): void {
  let pool = getPool(event.params.pool, event);
  pool.tokenA = event.params.tokenA;
  pool.tokenB = event.params.tokenB;
  pool.creator = event.transaction.from;
  pool.save();
}

export function handleMint(event: Mint): void {
  let pool = getPool(event.address, event);
  pool.totalLiquidityEvents = pool.totalLiquidityEvents.plus(BigInt.fromI32(1));
  pool.save();

  let entity = new LiquidityEvent(eventId(event));
  entity.pool = pool.id;
  entity.sender = event.params.sender;
  entity.amountA = event.params.amountA;
  entity.amountB = event.params.amountB;
  entity.liquidity = event.params.liquidity;
  entity.eventType = "MINT";
  entity.blockNumber = event.block.number;
  entity.timestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;
  entity.save();
}

export function handleBurn(event: Burn): void {
  let pool = getPool(event.address, event);
  pool.totalLiquidityEvents = pool.totalLiquidityEvents.plus(BigInt.fromI32(1));
  pool.save();

  let entity = new LiquidityEvent(eventId(event));
  entity.pool = pool.id;
  entity.sender = event.params.sender;
  entity.amountA = event.params.amountA;
  entity.amountB = event.params.amountB;
  entity.liquidity = event.params.liquidity;
  entity.eventType = "BURN";
  entity.blockNumber = event.block.number;
  entity.timestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;
  entity.save();
}

export function handleSwap(event: SwapEvent): void {
  let pool = getPool(event.address, event);
  pool.totalSwaps = pool.totalSwaps.plus(BigInt.fromI32(1));
  pool.save();

  let entity = new Swap(eventId(event));
  entity.pool = pool.id;
  entity.sender = event.params.sender;
  entity.tokenIn = event.params.tokenIn;
  entity.tokenOut = event.params.tokenOut;
  entity.amountIn = event.params.amountIn;
  entity.amountOut = event.params.amountOut;
  entity.blockNumber = event.block.number;
  entity.timestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;
  entity.save();
}

export function handleVaultDeposit(event: Deposit): void {
  let account = getVaultAccount(event.params.owner, event.block.timestamp);
  account.totalDeposited = account.totalDeposited.plus(event.params.assets);
  account.shareBalanceDelta = account.shareBalanceDelta.plus(event.params.shares);
  account.updatedAt = event.block.timestamp;
  account.save();

  let action = new VaultAction(eventId(event));
  action.sender = event.params.sender;
  action.owner = event.params.owner;
  action.receiver = null;
  action.assets = event.params.assets;
  action.shares = event.params.shares;
  action.actionType = "DEPOSIT";
  action.blockNumber = event.block.number;
  action.timestamp = event.block.timestamp;
  action.transactionHash = event.transaction.hash;
  action.save();
}

export function handleVaultWithdraw(event: Withdraw): void {
  let account = getVaultAccount(event.params.owner, event.block.timestamp);
  account.totalWithdrawn = account.totalWithdrawn.plus(event.params.assets);
  account.shareBalanceDelta = account.shareBalanceDelta.minus(event.params.shares);
  account.updatedAt = event.block.timestamp;
  account.save();

  let action = new VaultAction(eventId(event));
  action.sender = event.params.sender;
  action.owner = event.params.owner;
  action.receiver = event.params.receiver;
  action.assets = event.params.assets;
  action.shares = event.params.shares;
  action.actionType = "WITHDRAW";
  action.blockNumber = event.block.number;
  action.timestamp = event.block.timestamp;
  action.transactionHash = event.transaction.hash;
  action.save();
}

export function handleCollateralDeposited(event: CollateralDeposited): void {
  let position = getLoanPosition(event.params.user, event.block.timestamp);
  position.collateralDeposited = position.collateralDeposited.plus(event.params.amount);
  position.updatedAt = event.block.timestamp;
  position.save();
  saveLoanAction(event, event.params.user, event.params.user, event.params.amount, ZERO, "COLLATERAL_DEPOSITED");
}

export function handleCollateralWithdrawn(event: CollateralWithdrawn): void {
  let position = getLoanPosition(event.params.user, event.block.timestamp);
  position.collateralWithdrawn = position.collateralWithdrawn.plus(event.params.amount);
  position.updatedAt = event.block.timestamp;
  position.save();
  saveLoanAction(event, event.params.user, event.params.user, event.params.amount, ZERO, "COLLATERAL_WITHDRAWN");
}

export function handleBorrowed(event: Borrowed): void {
  let position = getLoanPosition(event.params.user, event.block.timestamp);
  position.borrowed = position.borrowed.plus(event.params.amount);
  position.updatedAt = event.block.timestamp;
  position.save();
  saveLoanAction(event, event.params.user, event.params.user, event.params.amount, event.params.totalDebt, "BORROWED");
}

export function handleRepaid(event: Repaid): void {
  let position = getLoanPosition(event.params.user, event.block.timestamp);
  position.repaid = position.repaid.plus(event.params.amount);
  position.updatedAt = event.block.timestamp;
  position.save();
  saveLoanAction(event, event.params.user, event.params.user, event.params.amount, event.params.remainingDebt, "REPAID");
}

export function handleLiquidated(event: Liquidated): void {
  let position = getLoanPosition(event.params.borrower, event.block.timestamp);
  position.liquidatedDebt = position.liquidatedDebt.plus(event.params.debtRepaid);
  position.collateralSeized = position.collateralSeized.plus(event.params.collateralSeized);
  position.updatedAt = event.block.timestamp;
  position.save();
  saveLoanAction(
    event,
    event.params.borrower,
    event.params.liquidator,
    event.params.debtRepaid,
    event.params.collateralSeized,
    "LIQUIDATED"
  );
}

function getPool(address: Address, event: ethereum.Event): Pool {
  let id = address.toHexString();
  let pool = Pool.load(id);
  if (pool == null) {
    pool = new Pool(id);
    pool.tokenA = Address.zero();
    pool.tokenB = Address.zero();
    pool.creator = null;
    pool.createdAtBlock = event.block.number;
    pool.createdAtTimestamp = event.block.timestamp;
    pool.totalSwaps = ZERO;
    pool.totalLiquidityEvents = ZERO;
  }
  return pool;
}

function getVaultAccount(owner: Address, timestamp: BigInt): VaultAccount {
  let id = owner.toHexString();
  let account = VaultAccount.load(id);
  if (account == null) {
    account = new VaultAccount(id);
    account.owner = owner;
    account.totalDeposited = ZERO;
    account.totalWithdrawn = ZERO;
    account.shareBalanceDelta = ZERO;
    account.updatedAt = timestamp;
  }
  return account;
}

function getLoanPosition(user: Address, timestamp: BigInt): LoanPosition {
  let id = user.toHexString();
  let position = LoanPosition.load(id);
  if (position == null) {
    position = new LoanPosition(id);
    position.user = user;
    position.collateralDeposited = ZERO;
    position.collateralWithdrawn = ZERO;
    position.borrowed = ZERO;
    position.repaid = ZERO;
    position.liquidatedDebt = ZERO;
    position.collateralSeized = ZERO;
    position.updatedAt = timestamp;
  }
  return position;
}

function saveLoanAction(
  event: ethereum.Event,
  user: Address,
  actor: Address,
  amount: BigInt,
  secondaryAmount: BigInt,
  actionType: string
): void {
  let action = new LoanAction(eventId(event));
  action.user = user;
  action.actor = actor;
  action.amount = amount;
  action.secondaryAmount = secondaryAmount;
  action.actionType = actionType;
  action.blockNumber = event.block.number;
  action.timestamp = event.block.timestamp;
  action.transactionHash = event.transaction.hash;
  action.save();
}

function eventId(event: ethereum.Event): string {
  return event.transaction.hash.toHexString() + "-" + event.logIndex.toString();
}
