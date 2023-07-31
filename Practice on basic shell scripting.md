## basic shell scripting commands
- present directory
````bash
 pwd
````
- Make directory
````bash
mkdir VTK
mkdir CL_training_VTK
````
- Navigate
````bash
cd VTK
pwd
cd ../
cd CL_training_VTK
ls
cd -
pwd
````
- Copy, paste and remove
````bash
cp CL_training_VTK/Ceratodon_purpureus.fasta VTK/
cp CL_BC_data/* CL_training_VTK/
rm VTK/Ceratodon_purpureus.fasta
rm VTK/
rm -r VTK/
````

- navigate files (cat, head,tail)
````bash
cd CL_training_VTK/
cat Dunaliella_salina.fasta
head Dunaliella_salina.fasta
cat Dunaliella_salina.fasta Ceratodon_purpureus.fasta Physcomitrium_patens.fasta
cat *.fasta >> merged_seq.faa
more Dunaliella_salina.fasta
Ctrl+c
less Dunaliella_salina.fasta
````
- select strings and edit (grep and sed)
````bash
grep '>' Dunaliella_salina.fasta
grep -c '>' Dunaliella_salina.fasta
grep -c '>' *.fasta
grep -v '>' Dunaliella_salina.fasta
grep '>' Dunaliella_salina.fasta|head
sed 's/>/</g' Dunaliella_salina.fasta
sed 's/>/</g' Dunaliella_salina.fasta > Dunaliella_salina.faa
sed -i 's/</>/g' Dunaliella_salina.faa
sed 's/Dunaliella_salina/Chlorophyta_core chlorophytes_Dunaliella_salina/g' Dunaliella_salina.fasta
sed '/^>/s/$/_Chlorophyta_core/g' Dunaliella_salina.fasta
sed '/^>/s/$/_Chlorophyta_core/g' Dunaliella_salina.fasta|grep '>'|head
````
- wc and cut commands
````bash
wc 1kP_Sample_List.csv
wc -l 1kP_Sample_List.csv
ls |wc -l
cut -f1 1kP_Sample_List.csv
cut -f1,3 1kP_Sample_List.csv
````
## looping
````bash
mkdir loop
for i in `cat CL_BC_data/sp_list.txt`; do cp $i.fasta loop/;done
````
## create bash program

````bash
nano script.sh
vi script.sh
vim script.sh
````
````bash
#!/bin/bash
pwd
ls
mkdir test_data
cd test_data
pwd
cp ../CL_BC_data/sp_list.txt ./

for i in `cat sp_list.txt`; 
do 
    cp ../CL_BC_data/$i.fasta ./
    echo 'file is transfered';
done
rm Physcomitrium_patens.fasta
cd ../
ls 

echo 'THIS IS HOW WE DO IT'
````
````bash
chmod a+x script.sh
bash script.sh
./script.sh
````








