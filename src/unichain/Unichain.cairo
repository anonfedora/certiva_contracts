
#[starknet::contract]
pub mod Unichain {

    #[storage]
    struct Storage {    }

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[abi(embed_v0)]
    impl UnichainImpl of unichain_contracts::interfaces::IUnichain<ContractState> {
    }
}