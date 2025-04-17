#[starknet::contract]
pub mod Unichain {
    use starknet::{ContractAddress, get_caller_address};
    use unichain_contracts::base::errors::Errors;
    use unichain_contracts::base::types::{Course, Progress};
    use unichain_contracts::interfaces::IUnichain::IUnichain;

    #[storage]
    struct Storage {}

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[abi(embed_v0)]
    impl UnichainImpl of IUnichain<ContractState> {}
}
