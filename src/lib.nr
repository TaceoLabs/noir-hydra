mod bn254;
use dep::std;



#[test]
fn test_main() {

    // Uncomment to make test fail
    // main(1, 1);
    let should_plains = [0,1,2,3,4,5,6,7,8,9,10,11];
    let key = [0,1,2,3];
    let iv = [4,5,6,7];
    let ciphers = bn254::enc::encrypt(should_plains, key, iv);
    let is_plains = bn254::dec::decrypt(ciphers, key, iv);
    assert(is_plains == should_plains);
}
