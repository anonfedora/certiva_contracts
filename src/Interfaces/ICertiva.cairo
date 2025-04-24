use starknet::ContractAddress;
use crate::certiva::Certiva::University;

#[starknet::interface]
pub trait ICertiva<TContractState> {
    fn register_university(
        ref self: TContractState,
        university_name: felt252,
        website_domain: ByteArray,
        country: felt252,
        accreditation_body: felt252,
        university_email: ByteArray,
        wallet_address: ContractAddress,
    );
    fn get_university(self: @TContractState, wallet_address: ContractAddress) -> University;
    fn is_owner(self: @TContractState) -> bool;
}
