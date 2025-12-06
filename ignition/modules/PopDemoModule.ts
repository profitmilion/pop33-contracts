import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const Pop33DemoModule = buildModule("Pop33DemoModule", (m) => {
  const pop33 = m.contract("Pop33Demo");
  return { pop33 };
});

export default Pop33DemoModule;
