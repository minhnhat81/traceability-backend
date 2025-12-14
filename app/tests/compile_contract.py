from solcx import compile_source, install_solc, set_solc_version

# Cài và kích hoạt compiler Solidity
install_solc("0.8.20")
set_solc_version("0.8.20")

# Contract Solidity (ProofRegistry)
src = """
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ProofRegistry {
    mapping(string => bytes32) public proofs;

    event ProofStored(string indexed key, bytes32 hash);

    function anchor(string memory key, bytes32 hash) public {
        proofs[key] = hash;
        emit ProofStored(key, hash);
    }

    function getProof(string memory key) public view returns (bytes32) {
        return proofs[key];
    }
}
"""

compiled = compile_source(src)
print(compiled)
