use dep::std;
use crate::vec::vec_add;
use crate::vec::vec_concat;
use crate::vec::vec_split;

use crate::bn254::consts;


fn hydra_body(key: [Field; 4], iv: [Field; 4]) -> ([Field; 8], [Field; 8]) {
    let (mut state, z) = permutation_b(vec_add(iv, key));
    state = vec_add(state, key);
    (
        vec_concat(state, z),
        vec_concat(key, matrix_e(key))
    )
} 

fn hydra_first_head<R>(state: [Field; 8], key: [Field; 8]) ->  [Field; 8] {
    vec_add(permutation_h(state, key), state)
}


fn hydra_head<R>(state: [Field; 8], key: [Field; 8], index: u32) -> ([Field; 8], [Field; 8]) {
    let roll = rolling(state, index);
    (roll, vec_add(permutation_h(roll, key), roll))
}

fn copy_vec<R>(src: [Field; 8], mut dst: [Field; R], off: u64) -> [Field; R] {
    for i in 0..8 {
        dst[off + i] = src[i];
    }
    dst
}


fn rolling(state: [Field; 8], index: u32) -> [Field; 8]{
    let (y, z) = vec_split(state);
    let (y, z) = non_linear_r(y, z);
    let y_perm = matrix_i(y, consts::Mi);
    let z_perm = matrix_i(z, consts::Mi);
    vec_add(vec_concat(y_perm, z_perm), consts::rc_r[index])
}

fn permutation_h(mut roll: [Field; 8], extended_key: [Field; 8]) -> [Field; 8] {
    for i in 0..consts::Rh {
        roll = non_linear_h(roll);
        roll = matrix_i(roll, consts::Mh);
        roll = vec_add(roll, consts::rc_h[i]);
        roll = vec_add(roll, extended_key);
    }
    roll
}

fn permutation_b(state: [Field; 4]) -> ([Field;4], [Field; 4]) {
    let mut acc = [0; 4];
    let mut state = matrix_e(state);
    for i in 0..consts::Re_1 {
        state = non_linear_e(state);
        state = matrix_e(state);
        state = vec_add(state, consts::rc_b[i]);
        acc = vec_add(acc, state);
    }
    for i in 0..consts::Ri {
        state = non_linear_i(state);
        state = matrix_i(state, consts::Mi);
        state = vec_add(state, consts::rc_b[i + consts::Re_1]);
        acc = vec_add(acc, state);
    }
    for i in consts::Re_1..consts::Re_1 + consts::Re_2 - 1{
        state = non_linear_e(state);
        state = matrix_e(state);
        state = vec_add(state, consts::rc_b[i + consts::Ri]);
        acc = vec_add(acc, state);
    }
    //one more time but without addition
    state = non_linear_e(state);
    state = matrix_e(state);
    state = vec_add(state, consts::rc_b[consts::Re_1 + consts::Re_2 - 1 + consts::Ri]);
    (state, acc)
}

fn hydra_body_ks(key: [Field; 4], iv: [Field; 4]) -> [Field; 4] {
    let state = vec_add(key, iv);
    let mut state = matrix_e(state);
    for i in 0..consts::Re_1 {
        state = non_linear_e(state);
        state = matrix_e(state);
        state = vec_add(state, consts::rc_b[i]);
    }
    for i in 0..consts::Ri {
        state = non_linear_i(state);
        state = matrix_i(state, consts::Mi);
        state = vec_add(state, consts::rc_b[i + consts::Re_1]);
    }
    for i in consts::Re_1..consts::Re_1 + consts::Re_2 {
        state = non_linear_e(state);
        state = matrix_e(state);
        state = vec_add(state, consts::rc_b[i + consts::Ri]);
    }
    vec_add(state, key)
}

fn matrix_e<R>(state: [Field; R]) -> [Field; R] {
    let sum = state.reduce(|a,b| a + b);
    let rot_state = rotate_left(state);
    let mut result = [0; R];
    for i in 0..R {
        result[i] = sum + rot_state[i] + state[i] + state[i];
    }
    result
}

fn matrix_i<R,L>(state: [Field; R], mat:[[Field; R]; L]) -> [Field; R] {
    let sum = state.reduce(|a,b| a + b);
    let mut out = [sum; R];
    out[0] += state[0] * mat[0][0];
    for i in 1..R {
        out[i] += (state[0] * mat[i][0]) + (state[i] * mat[i][i]);
    }
    out
}

fn rotate_left<R>(mat: [Field; R]) -> [Field; R] {
    let mut rotated = [0; R];
    for i in 1..R {
        rotated[i-1] = mat[i];
    }
    rotated[R-1] = mat[0];
    rotated
}

fn non_linear_h(roll: [Field; 8]) -> [Field; 8] {
    let mut dot = roll[0] + roll[1] + roll[2] + roll[3] 
                - roll[4] - roll[5] - roll[6] - roll[7];
    dot = dot.pow_32(2);
    roll.map(|r| r + dot)
}

fn non_linear_e(state: [Field;4]) -> [Field; 4] {
    [
        state[0].pow_32(5),
        state[1].pow_32(5),
        state[2].pow_32(5),
        state[3].pow_32(5),
    ]
}

fn non_linear_i(state: [Field; 4]) -> [Field;4] {
    let (dot1, dot2) = get_lm_dot(state);
    let sum = square(square(dot1) + dot2); 
    [
        state[0] + sum,
        state[1] + sum,
        state[2] + sum,
        state[3] + sum,
    ]
}

fn non_linear_r(y: [Field;4], z: [Field; 4]) -> ([Field; 4], [Field; 4]) {
    let (vy, wy) = get_lm_dot(y);
    let (wz, vz) = get_lm_dot(z);
    let v = (vy * vz);
    let w = (wy * wz);
    (
        y.map(|yi| yi + v),
        z.map(|zi| zi + w)
    )
}

fn get_lm_dot(state: [Field; 4]) -> (Field, Field) {
    let tmp = state[0] - state[3];
    (tmp - state[1] + state[2], tmp + state[1] - state[2])
}

fn square(x: Field) -> Field {
    x * x
}

#[test]
fn test_rotate_left() {
    let test = [0,1,2,3,4,5,6,7];
    assert(rotate_left(test) == [1,2,3,4,5,6,7,0]);
}


#[test]
fn test_get_lm_dot() {
    let (dot1, dot2) = get_lm_dot([17162050878538720375407210140639637720303994375562539862452690421292386592590, 11912527370530146728703046717149243981430064476687468213603991691404411193217, 18430438893156814166144129663793173051281448131580613239977654404180923080739, 7614633435608198927774246011281602559236719354621200488645904294064394220068]);
    assert(dot1 == 16065328965557188885074047076001964230918658675834484400180448840004504260044);
    assert(dot2 == 3029505920303854010191881182714106091215891366048194347433123414451480485000);
}

#[test]
fn test_non_linear_h() {
    let state = non_linear_h([17311339206079525542322783825459319113913165622286561296721622612914673407804, 16276728151221844182140219810267241649985535582588722449384727866117202327093, 10801048258802086965858707507694761799252711922965390030528950861087300763030, 3638652786377497073268842010725440468491752112825502524378677961251293024759, 7645315248887656730315052486323154491745884763740850513982583264261456826307, 10323065323391982836294143162837377995469044206483281154564046348037825339388, 20343326181502906791617898953771792194510136932068335746318866730568328752863, 17802268834568716074000952286650978346952421838604678848244855399442974823193]);
    assert(state == [4547325791835956019343387175706495521510639735313024107278926563682326597476, 3512714736978274659160823160514418057583009695615185259942031816884855516765, 19925277716397792665125716603199213295398550436407887184784458998430762448319, 12762882243973202772535851106229891964637590626267999678634186098594754710048, 16769544706483362429582061581827605987891723277183347668238091401604918511596, 19447294780987688535561152258341829491614882719925778308819554485381287024677, 7579312767259337268638502304018968602107611045094798556876170681335981942535, 5038255420325146551021555636898154754549895951631141658802159350210628012865]);
}

#[test]
fn test_non_linear_i() {
    let state = non_linear_i([17162050878538720375407210140639637720303994375562539862452690421292386592590, 11912527370530146728703046717149243981430064476687468213603991691404411193217, 18430438893156814166144129663793173051281448131580613239977654404180923080739, 7614633435608198927774246011281602559236719354621200488645904294064394220068]);
    assert(state == [4309430684818317694633606829961546606191461818288188130026024885465599697736, 20948150048649019270175849151728427955865896319829150824875530342153432793980, 5577818699436411485370526353115081937168915574306261507550988868354136185885, 16650256113727071469247048445860786533672551197762883099917442944813415820831]);
}

#[test]
fn test_non_linear_e() {
    assert(non_linear_e([10,8,8,9]) == [100000, 32768, 32768, 59049]);
}

#[test]
fn test_non_linear_r() {
    let y_in = [17311339206079525542322783825459319113913165622286561296721622612914673407804, 16276728151221844182140219810267241649985535582588722449384727866117202327093, 10801048258802086965858707507694761799252711922965390030528950861087300763030, 3638652786377497073268842010725440468491752112825502524378677961251293024759];
    let z_in = [7645315248887656730315052486323154491745884763740850513982583264261456826307, 10323065323391982836294143162837377995469044206483281154564046348037825339388, 20343326181502906791617898953771792194510136932068335746318866730568328752863, 17802268834568716074000952286650978346952421838604678848244855399442974823193];
    let (y_out, z_out) = non_linear_r(y_in, z_in);
    assert(y_out == [16474558665066990056068011496692118409558256462734362411538742665023636404753, 15439947610209308695885447481500040945630626423036523564201847918226165324042, 9964267717789551479603935178927561094897802763413191145346070913196263759979, 2801872245364961587014069681958239764136842953273303639195798013360256021708]);
    assert(z_out == [18800231885746230730599298706870897921156360762149932570264867923720730257667, 21477981960250556836578389383385121424879520204892363210846331007497098770748, 9609999946522205569655739429062260535372248530061383458902947203451793688606, 7068942599588014852038792761941446687814533436597726560828935872326439758936]);
}

#[test]
fn test_matrix_e() {
    assert(matrix_e([2, 1, 1, 1]) == [10, 8, 8, 9]);
}