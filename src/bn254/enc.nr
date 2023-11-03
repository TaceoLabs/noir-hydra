use crate::bn254::ks;
use dep::std::collections::vec::Vec;


//encrypts up to 8000 Field Elements
pub fn encrypt<R>(plains: [Field; R], key:[Field; 4],  iv:[Field; 4]) -> [Field; R] {
    let mut ciphers = [0; R];
    let (mut state, extended_key) = ks::hydra_body(key, iv);
    let mut ks = ks::hydra_first_head(state, extended_key);
    if R <= 8 as u32  {
        for i in 0..R {
            ciphers[i] = plains[i] + ks[i]; 
        }
    } else {
        for i in 0..8 {
            ciphers[i] = plains[i] + ks[i]; 
        }
        for i in 8..R {
            let off = i % 8;
            if off == 0 {
                let result = ks::hydra_head(state, extended_key, off);
                state = result.0;
                ks = result.1;
            }
            ciphers[i] = plains[i] + ks[off];
        }
    }
    ciphers
}
