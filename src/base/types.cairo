#[derive(Drop, Serde, starknet::Store)]
pub struct Course {
    pub id: u256,
    pub name: felt252, // Short string (max 31 chars)
    pub credits: u32,
    pub active: bool,
}

#[derive(Drop, Serde, starknet::Store)]
pub struct Progress {
    pub course_id: u256,
    pub student: starknet::ContractAddress,
    pub completed: bool,
    pub grade: u8, // 0-100
}
