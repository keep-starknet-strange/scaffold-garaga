install-bun:
	curl -fsSL https://bun.sh/install | bash

install-noir:
	curl -L https://raw.githubusercontent.com/noir-lang/noirup/refs/heads/main/install | bash
	noirup --version 1.0.0-beta.16

install-barretenberg:
	curl -L https://raw.githubusercontent.com/AztecProtocol/aztec-packages/refs/heads/master/barretenberg/bbup/install | bash
	bbup --version 3.0.0-nightly.20251104

install-starknet:
	curl --proto '=https' --tlsv1.2 -sSf https://sh.starkup.dev | sh

install-devnet:
	asdf plugin add starknet-devnet
	asdf install starknet-devnet 0.6.1

install-garaga:
	pip install garaga==1.0.1

install-app-deps:
	cd app && bun install

update-tools:
	asdf install starknet-devnet
	asdf install starknet-foundry
	asdf install scarb

devnet:
	starknet-devnet --accounts=2 --seed=0 --initial-balance=100000000000000000000000

accounts-file:
	curl -s -X POST -H "Content-Type: application/json" \
		--data '{"jsonrpc":"2.0","id":"1","method":"devnet_getPredeployedAccounts"}' http://127.0.0.1:5050/ \
		| jq '{"alpha-sepolia": {"devnet0": {\
			address: .result[0].address, \
			private_key: .result[0].private_key, \
			public_key: .result[0].public_key, \
			class_hash: "0xe2eb8f5672af4e6a4e8a8f1b44989685e668489b0a25437733756c5a34a1d6", \
			deployed: true, \
			legacy: false, \
			salt: "0x14", \
			type: "open_zeppelin"\
		}}}' > ./contracts/accounts.json

build-circuit:
	cd circuit && nargo build

exec-circuit:
	cd circuit && nargo execute witness

prove-circuit:
	bb prove --scheme ultra_honk \
		--oracle_hash keccak \
		-b ./circuit/target/circuit.json \
		-w ./circuit/target/witness.gz \
		-k ./circuit/target/vk \
		-o ./circuit/target

gen-vk:
	bb write_vk --scheme ultra_honk --oracle_hash keccak -b ./circuit/target/circuit.json -o ./circuit/target

gen-verifier:
	cd contracts && garaga gen --system ultra_keccak_zk_honk --vk ../circuit/target/vk --project-name verifier

build-contracts:
	cd contracts && scarb build

declare-verifier:
	cd contracts && sncast declare --package verifier --contract-name UltraKeccakZKHonkVerifier

declare-main:
	# TODO: don't forget to update the class hash in the main code (VERIFIER_CLASSHASH) from the result of the `make declare-verifier` step
	cd contracts && sncast declare --package main --contract-name MainContract

deploy-main:
	# TODO: use class hash from the result of the `make declare-main` step
	# NOTE: the public key is corresponding to the private key `1`
	cd contracts && sncast deploy --salt 0x02 --class-hash 0x6c07fb3260611d93220f6d9ff1169fee85db0a22a1e5180cbf15e85268f6511 --arguments 217234377348884654691879377518794323857294947151490278790710809376325639809

artifacts:
	cp ./circuit/target/circuit.json ./app/src/assets/circuit.json
	cp ./circuit/target/vk ./app/src/assets/vk.bin
	cp ./contracts/target/release/main_MainContract.contract_class.json ./app/src/assets/main.json

run-app:
	cd app && bun run dev

all:
	make build-circuit
	make gen-vk
	make gen-verifier
	make declare-verifier
	make artifacts
