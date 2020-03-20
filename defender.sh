#! /bin/sh
#***********************************************
#*		     genw.sh		       *
#***********************************************

# Parameter
#-----------
dev=/dev/sdc
#-----------

# finding current node index then making key for Persistent Reserve
key=abc00`clpstat --local | sed -n '/<server>/,/<group>/p' | grep '^   [\* ][^ ]' | sed -n '0,/^   [\*]/p' | wc -l`
interval=3	#sec

echo "[D] key : ${key}"
echo "[D] dev : ${dev}"
echo "[D] int : ${interval}"

function clear () {
	sg_persist -o -C -K $key -d $dev > /dev/null 2>&1
	ret=$?
	if [ $ret -eq 0 ]; then
		echo [I] [$ret] Clear succeeded
	else
		echo [E] [$ret] Clear failed
	fi
}

function register () {
	sg_persist -o -G -S $key -d $dev > /dev/null 2>&1
	ret=$?
	if [ $ret -eq 0 ] || [ $ret -eq 2 ]; then
		echo [I] [$ret] Register key succeeded
	else
		echo [E] [$ret] Register key failed
	fi
}

function reserve () {
	sg_persist -o -R -K $key -T 3 -d $dev > /dev/null 2>&1
	ret=$?
	if [ $ret -eq 0 ]; then
		echo [I] [$ret] Reserve succeeded
	else
		echo [E] [$ret] Reserve failed
	fi
}

register
while [ 1 ];do
	clear
	register
	reserve
	sg_persist -r $dev | grep -A 1 $key | grep  'Exclusive Access' > /dev/null 2>&1
	ret=$?
	if [ $ret -ne 0 ]; then
		echo [E] [$ret] Reserve not found. Will SUICIDE as failed defender
		exit 1
	fi
	echo [D] [$ret] Reserve found.
	sleep $interval
done
exit 0