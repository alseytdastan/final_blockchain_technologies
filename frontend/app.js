const TARGET_CHAIN = {
  chainId: "0x66eee",
  chainName: "Arbitrum Sepolia",
  nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 },
  rpcUrls: ["https://sepolia-rollup.arbitrum.io/rpc"],
  blockExplorerUrls: ["https://sepolia.arbiscan.io"]
};

// After deploy: copy addresses from deployments/arbitrum-sepolia.json
const CONFIG = {
  subgraphUrl: "https://api.studio.thegraph.com/query/YOUR_SUBGRAPH_ID/defihub/version/latest",
  tokenA: "0x7abAE8a8217f77CA0EDb60bbd00297aD936a392c",
  tokenB: "0xF9B62c21F0D9655CaEeC0A21DAeA9409B2678E1A",
  governanceToken: "0xA0d618c8F07d823416fC98dCC54fc5850Bba3A77",
  pool: "0x03b1882CE3EB333A29806c66acD24AaeB7F8eC7B",
  vault: "0x1F248BF5FFa817d5658253AF86ffCFB8e6710715",
  governor: "0xdA6E681f08045391C9b342349bFd3DC263f2556F",
  proposals: []
};

const ERC20_ABI = [
  "function balanceOf(address) view returns (uint256)",
  "function approve(address,uint256) returns (bool)",
  "function decimals() view returns (uint8)",
  "function symbol() view returns (string)"
];

const GOV_TOKEN_ABI = [
  ...ERC20_ABI,
  "function getVotes(address) view returns (uint256)",
  "function delegates(address) view returns (address)",
  "function delegate(address) returns ()"
];

const POOL_ABI = [
  "function reserveA() view returns (uint256)",
  "function reserveB() view returns (uint256)",
  "function swapExactTokensForTokens(address,uint256,uint256,uint256) returns (uint256)"
];

const VAULT_ABI = [
  "function balanceOf(address) view returns (uint256)",
  "function deposit(uint256,address) returns (uint256)"
];

const GOVERNOR_ABI = [
  "function castVote(uint256,uint8) returns (uint256)",
  "function proposalThreshold() view returns (uint256)",
  "function state(uint256) view returns (uint8)"
];

const stateNames = ["Pending", "Active", "Canceled", "Defeated", "Succeeded", "Queued", "Expired", "Executed"];

let provider;
let signer;
let account;

const $ = (id) => document.getElementById(id);

window.addEventListener("load", () => {
  $("connectBtn").addEventListener("click", connectWallet);
  $("switchBtn").addEventListener("click", switchNetwork);
  $("refreshBtn").addEventListener("click", refreshState);
  $("delegateBtn").addEventListener("click", delegateSelf);
  $("swapBtn").addEventListener("click", swapAForB);
  $("depositBtn").addEventListener("click", depositVault);
  $("voteBtn").addEventListener("click", vote);
  $("loadSubgraphBtn").addEventListener("click", loadSubgraphData);
  renderProposalList();
});

async function connectWallet() {
  try {
    if (!window.ethereum) throw new Error("MetaMask is not installed.");
    provider = new ethers.BrowserProvider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    signer = await provider.getSigner();
    account = await signer.getAddress();
    $("account").textContent = account;
    await updateNetworkStatus();
    await refreshState();
    window.ethereum.on("chainChanged", () => window.location.reload());
    window.ethereum.on("accountsChanged", () => window.location.reload());
    showMessage("Wallet connected.", "success");
  } catch (error) {
    showError(error);
  }
}

async function updateNetworkStatus() {
  const network = await provider.getNetwork();
  const expected = BigInt(parseInt(TARGET_CHAIN.chainId, 16));
  const status = $("networkStatus");
  if (network.chainId === expected) {
    status.textContent = TARGET_CHAIN.chainName;
    status.className = "status ok";
  } else {
    status.textContent = `Wrong network: ${network.chainId}`;
    status.className = "status warn";
  }
}

async function switchNetwork() {
  try {
    await window.ethereum.request({
      method: "wallet_switchEthereumChain",
      params: [{ chainId: TARGET_CHAIN.chainId }]
    });
  } catch (error) {
    if (error.code === 4902) {
      await window.ethereum.request({
        method: "wallet_addEthereumChain",
        params: [TARGET_CHAIN]
      });
      return;
    }
    showError(error);
  }
}

async function refreshState() {
  try {
    requireConnection();
    const tokenA = contract(CONFIG.tokenA, ERC20_ABI);
    const govToken = contract(CONFIG.governanceToken, GOV_TOKEN_ABI);
    const pool = contract(CONFIG.pool, POOL_ABI);
    const vault = contract(CONFIG.vault, VAULT_ABI);
    const governor = contract(CONFIG.governor, GOVERNOR_ABI);

    const [symbol, tokenBalance, votes, delegate, reserveA, reserveB, shares, threshold] = await Promise.all([
      tokenA.symbol(),
      tokenA.balanceOf(account),
      govToken.getVotes(account),
      govToken.delegates(account),
      pool.reserveA(),
      pool.reserveB(),
      vault.balanceOf(account),
      governor.proposalThreshold()
    ]);

    $("tokenBalance").textContent = `${fmt(tokenBalance)} ${symbol}`;
    $("votingPower").textContent = fmt(votes);
    $("delegate").textContent = delegate;
    $("reserveA").textContent = fmt(reserveA);
    $("reserveB").textContent = fmt(reserveB);
    $("vaultShares").textContent = fmt(shares);
    $("proposalThreshold").textContent = fmt(threshold);
    await renderProposalList();
  } catch (error) {
    showError(error);
  }
}

async function delegateSelf() {
  try {
    requireConnection();
    const tx = await contract(CONFIG.governanceToken, GOV_TOKEN_ABI).delegate(account);
    await tx.wait();
    showMessage("Delegation confirmed.", "success");
    await refreshState();
  } catch (error) {
    showError(error);
  }
}

async function swapAForB() {
  try {
    requireConnection();
    const amountIn = parseAmount($("swapAmount").value);
    const amountOutMin = parseAmount($("swapMinOut").value || "0");
    const deadline = Math.floor(Date.now() / 1000) + 900;
    await approveIfNeeded(CONFIG.tokenA, CONFIG.pool, amountIn);
    const tx = await contract(CONFIG.pool, POOL_ABI).swapExactTokensForTokens(
      CONFIG.tokenA,
      amountIn,
      amountOutMin,
      deadline
    );
    await tx.wait();
    showMessage("Swap confirmed.", "success");
    await refreshState();
  } catch (error) {
    showError(error);
  }
}

async function depositVault() {
  try {
    requireConnection();
    const amount = parseAmount($("depositAmount").value);
    await approveIfNeeded(CONFIG.tokenA, CONFIG.vault, amount);
    const tx = await contract(CONFIG.vault, VAULT_ABI).deposit(amount, account);
    await tx.wait();
    showMessage("Vault deposit confirmed.", "success");
    await refreshState();
  } catch (error) {
    showError(error);
  }
}

async function vote() {
  try {
    requireConnection();
    const proposalId = $("proposalId").value.trim();
    if (!proposalId) throw new Error("Enter a proposal id.");
    const support = Number($("voteSupport").value);
    const tx = await contract(CONFIG.governor, GOVERNOR_ABI).castVote(proposalId, support);
    await tx.wait();
    showMessage("Vote confirmed.", "success");
    await renderProposalList();
  } catch (error) {
    showError(error);
  }
}

async function renderProposalList() {
  const list = $("proposalList");
  list.innerHTML = "";
  if (CONFIG.proposals.length === 0) {
    list.innerHTML = "<li>No configured proposals. Add proposal ids to CONFIG.proposals after deployment.</li>";
    return;
  }

  for (const id of CONFIG.proposals) {
    let label = "Unknown";
    if (signer) {
      try {
        const status = await contract(CONFIG.governor, GOVERNOR_ABI).state(id);
        label = stateNames[Number(status)] || "Unknown";
      } catch (_) {
        label = "Unreadable";
      }
    }
    const item = document.createElement("li");
    item.textContent = `${id}: ${label}`;
    list.appendChild(item);
  }
}

async function loadSubgraphData() {
  try {
    const query = `{
      swaps(first: 5, orderBy: timestamp, orderDirection: desc) {
        id sender tokenIn tokenOut amountIn amountOut timestamp
      }
      loanPositions(first: 5, orderBy: updatedAt, orderDirection: desc) {
        user borrowed repaid collateralDeposited collateralWithdrawn
      }
    }`;
    const response = await fetch(CONFIG.subgraphUrl, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ query })
    });
    if (!response.ok) throw new Error("Subgraph request failed.");
    const data = await response.json();
    $("subgraphOutput").textContent = JSON.stringify(data, null, 2);
  } catch (error) {
    showError(error);
  }
}

async function approveIfNeeded(tokenAddress, spender, amount) {
  const token = contract(tokenAddress, ERC20_ABI);
  const tx = await token.approve(spender, amount);
  await tx.wait();
}

function contract(address, abi) {
  assertConfigured(address);
  return new ethers.Contract(address, abi, signer);
}

function assertConfigured(address) {
  if (!address || address === ethers.ZeroAddress) {
    throw new Error("Contract address is not configured. Update frontend/app.js after deployment.");
  }
}

function requireConnection() {
  if (!signer || !account) throw new Error("Connect your wallet first.");
}

function parseAmount(value) {
  if (!value || Number(value) <= 0) throw new Error("Enter a positive amount.");
  return ethers.parseUnits(value, 18);
}

function fmt(value) {
  return Number(ethers.formatUnits(value, 18)).toLocaleString(undefined, { maximumFractionDigits: 6 });
}

function showMessage(text, type) {
  const box = $("message");
  box.textContent = text;
  box.className = `message ${type}`;
}

function showError(error) {
  const raw = error?.shortMessage || error?.reason || error?.message || String(error);
  const friendly = raw.includes("user rejected") ? "Transaction rejected in wallet." : raw;
  showMessage(friendly, "error");
}
