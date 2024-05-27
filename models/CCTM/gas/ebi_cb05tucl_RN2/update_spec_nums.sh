#!/bin/bash

for i1 in `seq 206 -1 174` ; do
    i2=`echo $i1+1|bc`
    bash -c "perl -pi -e 's/ $i1 / $i2 /g' hrprodloss.F"
done

for i1 in `seq 206 -1 174` ; do
    i2=`echo $i1+1|bc`
    bash -c "perl -pi -e 's/ $i1 / $i2 /g' hrrates.F"
done


for i1 in `seq 206 -1 174` ; do
    i2=`echo $i1+1|bc`
    bash -c "perl -pi -e 's/ $i1 / $i2 /g' hrg1.F"
done

for i1 in `seq 206 -1 174` ; do
    i2=`echo $i1+1|bc`
    bash -c "perl -pi -e 's/ $i1 / $i2 /g' hrg2.F"
done

for i1 in `seq 206 -1 174` ; do
    i2=`echo $i1+1|bc`
    bash -c "perl -pi -e 's/ $i1 / $i2 /g' hrg3.F"
done

for i1 in `seq 206 -1 174` ; do
    i2=`echo $i1+1|bc`
    bash -c "perl -pi -e 's/ $i1 / $i2 /g' hrg4.F"
done

