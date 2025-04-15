use poseidon::poseidon::bn254::hash_2;

fn main(secret_key: Field, input: u32, public_key: pub Field, nullifier: pub Field) {
    // Check that the input is a perfect square
    // Safety: it doesn't matter how we obtained the square root
    let sqrt_input = unsafe { sqrt(input) };
    assert(sqrt_input * sqrt_input == input);

    // Check that the public key is valid
    assert(hash_2([secret_key, secret_key]) == public_key);

    // Check that the nullifier is valid
    let nonce = [secret_key, input as Field];
    assert(hash_2(nonce) == nullifier);
}

/// Simple binary search-style integer square root
unconstrained fn sqrt(x: u32) -> u32 {
    let mut low: u64 = 1;
    let mut high: u64 = x as u64;

    loop {
        let mid = (low + high) / 2;
        let val = mid * mid;

        if val <= x as u64 {
            low = mid + 1;
        } else {
            high = mid - 1;
        }

        if low > high {
            break;
        }
    }

    high as u32
}
