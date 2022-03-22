for((int i=0;i< $1; i++)); {
	echo $i
	./gen.py $i > in
	./a.out < in

