examples/counter: examples/counter.o coroutine.o
	ld -o $@ $^ /usr/lib/crt1.o -lc -dynamic-linker /lib64/ld-linux-x86-64.so.2

examples/counter.o: examples/counter.c
	gcc -c -o $@ $<

coroutine.o: coroutine.s
	fasm coroutine.s $@

proof_of_concept: proof_of_concept.s
	fasm proof_of_concept.s
	proof_of_concept

clean:
	rm -f examples/counter examples/counter.o coroutine.o
