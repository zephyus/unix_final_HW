#!/bin/sh

fail=0

run_test() {
    num=$1
    script=$2
    args="$3"
    input="$4"
    expected="$5"
    out=$(printf '%b' "$input" | ./msed_new.csh "$script" $args 2>/dev/null)
    if [ "$out" = "$expected" ]; then
        echo "Test $num PASS"
    else
        echo "Test $num FAIL: expected [$expected], got [$out]"
        fail=1
    fi
}

# Test definitions
run_test 1 '/$1/p' "foo" 'foo\nbar\n' 'foo'
run_test 2 's/$1/$2/' "cat dog" 'a cat.\n' 'a dog.'
run_test 3 's:$1:$2:g; s:$2:$3:g' "a b c" 'a a b\n' 'c c c'
run_test 4 '/^$1/p' "\\*end" '*end\nstar\n' '*end'
run_test 5 '/$1/!d; s/$1/X/' "num" 'num\nalpha\n' 'X'

run_test 6 '$-1p' "" 'a\nb\nc\nd\n' 'c'
run_test 7 '2,$-0p' "" 'x\ny\nz\n' 'y\nz'
run_test 8 '$-2d' "" '1\n2\n3\n4\n5\n' '1\n2\n4\n5'
run_test 9 '$-0 s/.*/LAST/' "" 'a\nb\n' 'a\nLAST'

run_test 10 's/x/X/;s/y/Y/' "" 'x y\n' 'X Y'

