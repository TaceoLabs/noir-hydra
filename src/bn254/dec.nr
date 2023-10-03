
use crate::bn254::ks;
//todo discuss interface (nonce merged with iv??)
fn decrypt<R>(ciphers: [Field; R], key:[Field; 4],  iv:[Field; 4]) -> [Field; R]{
    let ks = ks::gen_ks(ciphers, key, iv);
    let mut plains = [0; R];
    for i in 0..R {
        plains[i] = ciphers[i] - ks[i];
    }
    plains
}