pub mod Errors {
    pub const COURSE_NOT_FOUND: felt252 = 'Course does not exist';
    pub const ALREADY_ENROLLED: felt252 = 'Student already enrolled';
    pub const NOT_ENROLLED: felt252 = 'Student not enrolled';
    pub const INVALID_GRADE: felt252 = 'Grade must be 0-100';
    pub const COURSE_INACTIVE: felt252 = 'Course is inactive';
    pub const NOT_ADMIN: felt252 = 'Caller is not admin';
}
