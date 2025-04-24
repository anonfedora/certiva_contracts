#[starknet::contract]
pub mod Certiva {
    use core::starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, contract_address_const, get_caller_address};
    use crate::Interfaces::ICertiva::ICertiva;

    #[storage]
    struct Storage {
        owner: ContractAddress,
        university: Map<ContractAddress, University>,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
    }
    #[derive(Drop, Serde, starknet::Event, starknet::Store)]
    pub struct University {
        pub university_name: felt252,
        pub website_domain: ByteArray,
        pub country: felt252,
        pub accreditation_body: felt252,
        pub university_email: ByteArray,
        pub wallet_address: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        university_created: University,
    }

    #[abi(embed_v0)]
    impl CertivaImpl of ICertiva<ContractState> {
        fn register_university(
            ref self: ContractState,
            university_name: felt252,
            website_domain: ByteArray,
            country: felt252,
            accreditation_body: felt252,
            university_email: ByteArray,
            wallet_address: ContractAddress,
        ) {
            // Check that caller is the owner
            let caller = get_caller_address();
            let owner = self.owner.read();
            let zero_address = contract_address_const::<0>();
            assert(caller == owner, 'Unauthorized caller');

            // Validate inputs
            assert(university_name != 0, 'University name is required');
            assert(wallet_address != zero_address, 'Wallet address cannot be zero');
            assert(country != 0, 'Country is required');

            // Create university struct
            let new_university = University {
                university_name: university_name,
                website_domain: website_domain.clone(),
                country: country,
                accreditation_body: accreditation_body,
                university_email: university_email.clone(),
                wallet_address: wallet_address,
            };

            // Store university using wallet_address as key
            self.university.write(wallet_address, new_university);

            // Emit university registered event
            self
                .emit(
                    Event::university_created(
                        University {
                            university_name,
                            website_domain,
                            country,
                            accreditation_body,
                            university_email,
                            wallet_address,
                        },
                    ),
                );
        }

        // Function to get university details by wallet address
        fn get_university(self: @ContractState, wallet_address: ContractAddress) -> University {
            self.university.read(wallet_address)
        }

        // Function to check if caller is contract owner
        fn is_owner(self: @ContractState) -> bool {
            let caller = get_caller_address();
            let owner = self.owner.read();
            caller == owner
        }
    }
}
