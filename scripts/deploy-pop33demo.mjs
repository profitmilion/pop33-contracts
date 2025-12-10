import { JsonRpcProvider, Wallet, ContractFactory } from "ethers";
import fs from "fs";
import path from "path";
import dotenv from "dotenv";
import { fileURLToPath } from "url";

dotenv.config();

// Symulacja __dirname w ESM
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function main() {
  // 1. RPC i klucz prywatny
  const RPC = process.env.BASE_SEPOLIA_RPC_URL || "https://sepolia.base.org";
  const PRIVATE_KEY = process.env.PRIVATE_KEY;

  if (!PRIVATE_KEY) {
    throw new Error("Brak PRIVATE_KEY w pliku .env");
  }

  const provider = new JsonRpcProvider(RPC);
  const wallet = new Wallet(PRIVATE_KEY, provider);

  console.log("Deployuję z adresu:", wallet.address);

  // 2. Wczytujemy artefakt kontraktu Pop33DemoV2
  const artifactPath = path.join(
    __dirname,
    "..",
    "artifacts",
    "contracts",
    "Pop33DemoV2.sol",
    "Pop33DemoV2.json"
  );

  if (!fs.existsSync(artifactPath)) {
    throw new Error(
      `Nie znaleziono artefaktu kontraktu pod ścieżką: ${artifactPath}
Upewnij się że:
- plik nazywa się Pop33DemoV2.sol
- kontrakt nazywa się Pop33DemoV2
- wykonałeś: npx hardhat compile`
    );
  }

  const artifact = JSON.parse(fs.readFileSync(artifactPath, "utf8"));

  // 3. Tworzymy fabrykę kontraktu
  const factory = new ContractFactory(
    artifact.abi,
    artifact.bytecode,
    wallet
  );

  console.log("Deployuję kontrakt Pop33DemoV2 na Base Sepolia...");

  const contract = await factory.deploy();
  await contract.waitForDeployment();

  const address = await contract.getAddress();
  console.log("Pop33DemoV2 deployed at:", address);
}

main().catch((error) => {
  console.error("Błąd podczas deployu:", error);
  process.exit(1);
});
