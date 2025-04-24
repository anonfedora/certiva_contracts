#[starknet::contract]
pub mod Certiva {
    use core::starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, contract_address_const, get_caller_address};
    use crate::Interfaces::ICertiva::ICertiva;
    use core::array::ArrayTrait;
    use core::byte_array::ByteArray;

    #[storage]
    struct Storage {
        owner: ContractAddress,
        university: Map<ContractAddress, University>,
        certificates: Map<felt252, Certificate>,
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

    #[derive(Drop, Clone, Serde, starknet::Event, starknet::Store)]
    pub struct Certificate {
        pub certificate_meta_data: ByteArray,
        pub hashed_key: ByteArray,
        pub certificate_id: ByteArray,
        pub issuer_domain: ByteArray,
        pub issuer_address: ContractAddress,
        pub isActive: bool,
    }

    #[derive(Drop, Serde, starknet::Event)]
    pub struct BulkCertificatesIssued {
        pub count: felt252,
        pub issuer: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        university_created: University,
        certificate_issued: Certificate,
        certificates_bulk_issued: BulkCertificatesIssued,
    }

    // Helper function to hash a ByteArray to a felt252
    fn hash_certificate_id(certificate_id: ByteArray) -> felt252 {
        let str_len = certificate_id.len();
        
        if str_len == 0 {
            return 123456; // Default hash for empty string
        }
        
        // Process all bytes of the certificate_id
        let mut hash: felt252 = 0;
        let mut i: usize = 0;
        
        // Iterate through all bytes in the ByteArray
        while i != str_len {
            // Get character at position i, unwrap from Option<u8>
            let char: u8 = certificate_id.at(i).unwrap();
            
            // This is a common string hashing algorithm
            hash = hash * 31 + char.into();
            
            i += 1;
        }
        
        // Ensure we don't return 0 as a key
        if hash == 0 {
            return 1;
        }
        
        hash
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

        // Function to issue a certificate by a registered university
        fn issue_certificate(
            ref self: ContractState,
            certificate_meta_data: ByteArray,
            hashed_key: ByteArray,
            certificate_id: ByteArray,
        ) {
            // Get caller address (must be a registered university)
            let caller = get_caller_address();
            
            // Check that the caller is a registered university
            let university = self.university.read(caller);
            let zero_address = contract_address_const::<0>();
            assert(university.wallet_address != zero_address, 'University not registered');
            
            // Create certificate with university domain and active status
            let new_certificate = Certificate {
                certificate_meta_data: certificate_meta_data.clone(),
                hashed_key: hashed_key.clone(),
                certificate_id: certificate_id.clone(),
                issuer_domain: university.website_domain.clone(),
                issuer_address: caller,
                isActive: true,
            };
            
            let cert_key: felt252 = hash_certificate_id(certificate_id.clone());
            
            // Store certificate using the generated key
            self.certificates.write(cert_key, new_certificate.clone());
            
            // Emit certificate issued event
            self.emit(Event::certificate_issued(new_certificate));
        }
        
        // Function to issue multiple certificates at once by a registered university
        fn bulk_issue_certificates(
            ref self: ContractState, 
            certificate_meta_data_array: Array<ByteArray>,
            hashed_key_array: Array<ByteArray>,
            certificate_id_array: Array<ByteArray>,
        ) {
            // Get caller address (must be a registered university)
            let caller = get_caller_address();
            
            // Check that the caller is a registered university
            let university = self.university.read(caller);
            let zero_address = contract_address_const::<0>();
            assert(university.wallet_address != zero_address, 'University not registered');
            
            // Validate input arrays have the same length
            let len = certificate_id_array.len();
            assert(certificate_meta_data_array.len() == len, 'Arrays length mismatch');
            assert(hashed_key_array.len() == len, 'Arrays length mismatch');
            
            // Issue certificates in bulk
            let mut i: u32 = 0;
            while i != len {
                // In a production environment we would generate a unique key from certificate_id
                let cert_key: felt252 = hash_certificate_id(certificate_id_array.at(i).clone());
                
                // Process ith certificate - create temporary certificates for each loop iteration
                let certificate_meta_data = certificate_meta_data_array.at(i).clone();
                let hashed_key = hashed_key_array.at(i).clone();
                let certificate_id = certificate_id_array.at(i).clone();
                
                // Create certificate
                let new_certificate = Certificate {
                    certificate_meta_data: certificate_meta_data,
                    hashed_key: hashed_key,
                    certificate_id: certificate_id,
                    issuer_domain: university.website_domain.clone(),
                    issuer_address: caller,
                    isActive: true,
                };
                
                // Store certificate
                self.certificates.write(cert_key, new_certificate.clone());
                
                i += 1;
            }
            
            // Convert len to felt252 and emit bulk certificates issued event
            let count_felt: felt252 = len.into();
            
            // Emit bulk certificates issued event
            self.emit(
                Event::certificates_bulk_issued(
                    BulkCertificatesIssued { count: count_felt, issuer: caller }
                )
            );
        }
        
        // Function to get certificate details by certificate ID
        fn get_certificate(self: @ContractState, certificate_id: ByteArray) -> Certificate {
            let cert_key: felt252 = hash_certificate_id(certificate_id);
            
            self.certificates.read(cert_key)
        }
    }
}
