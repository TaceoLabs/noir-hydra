# Noir Hydra for BN254

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This repository contains a Noir crate implementing the Hydra block cipher for Noir's native curve BN254.

Hydra consists of a set of multiple permutations and round functions and is optimized for encrypting large amounts of data while minimizing the number of multiplications. You can see the design of Hydra in the following picture:
![Hydra Design](https://github.com/TaceoLabs/noir-hydra/blob/1847fdcec75c1f25979f943e993cc16c04910c58/fig/hydra.jpeg)

The body of the Hydra consists of a Poseidon-like structure that expands and transforms the initial state of 4 field elements and an additional feed-forward step to 8 field elements. These eight elements serve as seeds for the keystream generation. Every head of the hydra produces eight key stream elements with the seed mentioned above and a rolling function.

**Note**: Every head of the Hydra uses a dedicated random round constant. To ensure soundness and to decrease necessary constraints, we pre-computed 1000 round constants with shake-128 (see Sage script section below). This means the implementation can only encrypt 8000 field elements at once. If you need to encrypt more, you have to rerun the encryption with a fresh nonce or create your own round constants.

For further information, you can read the [Hydra Paper](https://eprint.iacr.org/2022/342.pdf).

## Performance

We tested our implementation with version 0.10.5 of the Noir compiler and the following circuit:

```Rust
    use dep::hydra;

    fn main(plains: [Field; 8], key : [Field; 4], iv: [Field;4]) -> pub [Field; 8] {
        hydra::bn254::enc::encrypt(plains, key, iv)
    }
```

For our experiments, we varied the amount of encrypted field elements. Hydra outperforms [gMiMC](https://github.com/TaceoLabs/noir-hydra/blob/main/src/bn254/ks.nr) starting at 10 Field elements. It is possible to only use the Hydra's body to generate eight key stream elements when the plaintext only consists of maximal eight elements:

```Rust
    use dep::hydra;

    fn main(plains: [Field; 8], key : [Field; 4], iv: [Field;4]) -> pub [Field; 8] {
        let (ks, _) = hydra::bn254::ks::hydra_body(key, iv);
        let mut ciphers = [0; 8];
        for i in 0..8 {
            ciphers[i] = plains[i] + ks[i];
        }
        ciphers
    }
```

We also compared our implementation with the [MiMC-Sponge](https://github.com/seugu/Noir-MiMCsponge/tree/main) crate. We used the `MiMCSponge` function to create a key stream of size N. The results can be seen in the following table (cells represent the amount of constraints by `nargo info`):

| #Field elements | Hydra | Hydra (only body) | gMiMC | MiMCSponge |
| --------------- | ----- | ----------------- | ----- | ---------- |
| 4               | 6189  | 2351              | 3837  | 23331      |
| 8               | 6621  | 2582              | 5580  | 57319      |
| 12              | 10702 | -                 | 9138  | 94182      |
| 16              | 11142 | -                 | 20403 | 132926     |
| 20              | 15313 | -                 | -     | -          |
| 24              | 15761 | -                 | -     | -          |

## Installation

In your `Nargo.toml` file, add the following dependency:

```toml
[dependencies]
hydra = { tag = "v0.1.0", git = "https://github.com/TaceoLabs/noir-hydra" }
```

## Examples

To encrypt 8 `Field` elements write:

```Rust
    let plains = [0, 1, 2, 3, 4, 5, 6, 7];
    let key = [34245092, 1216, 54609, 32945];
    let nonce = 11561;
    let iv = [nonce, 432,324,14];
    let ciphers = hydra::bn254::enc::encrypt(plains, key, iv);
    let plains = hydra::bn254::dec::decrypt(ciphers, key, iv);
```

The API supports an arbitrary amount of inputs, up to 8000 field elements.

For further examples on how to use the Hydra crate, have a look in the `lib.nr` file in the `src/` directory and check the tests.

## Tools

You can find a (unoptimized) Sage implementation of hydra under `tools/` as reference. We used this tool to create the round constants of the Hydra's heads.

## Disclaimer

This is **experimental software** and is provided on an "as is" and "as available" basis. We do **not give any warranties** and will **not be liable for any losses** incurred through any use of this code base.
