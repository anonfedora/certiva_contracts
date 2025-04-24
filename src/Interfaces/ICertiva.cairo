use starknet::ContractAddress;
use crate::certiva::Certiva::{University, Certificate};
use core::array::Array;
use core::byte_array::ByteArray;

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
    
    // Certificate functions
    fn issue_certificate(
        ref self: TContractState,
        certificate_meta_data: ByteArray,
        hashed_key: ByteArray,
        certificate_id: ByteArray,
    );
    
    fn bulk_issue_certificates(
        ref self: TContractState,
        certificate_meta_data_array: Array<ByteArray>,
        hashed_key_array: Array<ByteArray>,
        certificate_id_array: Array<ByteArray>,
    );
    
    fn get_certificate(self: @TContractState, certificate_id: ByteArray) -> Certificate;
}
