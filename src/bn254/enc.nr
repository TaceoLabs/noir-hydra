use crate::bn254::ks;
//todo discuss interface (nonce merged with iv??)
fn encrypt<R>(plains: [Field; R], key:[Field; 4],  iv:[Field; 4]) -> [Field; R]{
    let ks = ks::gen_ks(plains, key, iv);
    let mut ciphers = [0; R];
    for i in 0..R {
        ciphers[i] = plains[i] + ks[i];
    }
    ciphers
}