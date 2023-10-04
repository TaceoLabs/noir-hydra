fn vec_concat(lhs:  [Field; 4], rhs: [Field; 4]) -> [Field; 8] {
    [
        lhs[0],
        lhs[1],
        lhs[2],
        lhs[3],
        rhs[0],
        rhs[1],
        rhs[2],
        rhs[3],
    ]
}


fn vec_split(vec:  [Field; 8]) -> ([Field; 4], [Field; 4]) {
    ([
        vec[0],
        vec[1],
        vec[2],
        vec[3],
    ],
    [
        vec[4],
        vec[5],
        vec[6],
        vec[7],
    ])
}

fn vec_add<R>(lhs: [Field; R], rhs: [Field; R]) -> [Field; R] {
    let mut result = [0; R];
    for i in 0..R {
        result[i] = lhs[i] + rhs[i];
    }
    result
} 