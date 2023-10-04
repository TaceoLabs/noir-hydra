# Noir Hydra for BN254

This repository contains a Noir crate implementing the Hydra block cipher for the native curve BN254 in encryption mode.

Hydra consists of a set of multiple permutations and round functions and is optimized for encrypting large amounts of data while minimizing the number of multiplications. You can see the design of Hydra in the following picture:
![Hydra Design](https://github.com/TaceoLabs/noir-hydra/blob/1847fdcec75c1f25979f943e993cc16c04910c58/fig/hydra.jpeg)

The body of the Hydra consists of a Poseidon-like structure that expands and transforms the initial state of 4 field elements and an additional feed-forward step to 8 field elements. These eight elements serve as seeds for the keystream generation. Every head of the hydra produces eight key stream elements with the seed mentioned above and a rolling function.

**Note**: Every head of the Hydra uses a dedicated random round constant. To ensure soundness and to decrease necessary constraints, we pre-computed 1000 round constants with shake-128 (see Sage script section below). This means the implementation can only encrypt 8000 field elements at once. If you need to encrypt more, you have to rerun the encryption with a fresh nonce or create your own round constants.

For further information, you can read the [Hydra Paper](https://eprint.iacr.org/2022/342.pdf).

## Installation

In your `Nargo.toml` file, add the following dependency:

```toml
[dependencies]
gmimc = { tag = "v0.1.0", git = "https://github.com/TaceoLabs/noir-hydra" }
```

## Examples

To encrypt two `Field` elements write:

```Rust
    let plains = [0, 1, 2, 3, 4, 5, 6, 7];
    let nonce = 0x1584516;
    let key = [nonce, 0x418541, 0x4684, 0x8461461];
    let ciphers = bn254::enc::encrypt(plains, key, iv);
    let plains = bn254::dec::decrypt(ciphers, key, iv);
```

For further examples on how to use the Hydra crate, have a look in the `lib.nr` file in the `src/` directory and check the tests.

## Tools

You can find a (unoptimized) Sage implementation of hydra under `tools/` as reference.

## Disclaimer

This is **experimental software** and is provided on an "as is" and "as available" basis. We do **not give any warranties** and will **not be liable for any losses** incurred through any use of this code base.
