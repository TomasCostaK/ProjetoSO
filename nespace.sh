#!/bin/bash

function guardarFiles() {
	tamanhoTotal=0
	
	for file in "$1"/* ; do
	
		#Tem que conter o caminho absoluto	
        contemElemento "${file}" "${filesEscondidos[@]}"
		if [[ -f $file && $? -eq 1 ]];
		then
            if [ -r $file ]; then
				tamanhoLocal=$(stat $file | head -2 | tail -1 | awk '{print $2}')
				file_date=$(stat $file | head -5 | tail -1 | awk '{print $2, $3}')
				file_date=$(date -d $file_date "+%Y%m%d%H%M")
       
				# Verificar se os ficheiros satisfazem determinadas condições
                # Opções -n e -d passadas na liha de comandos
                if [ $n_flag -eq 1 -a $d_flag -eq 1 ]; then
                    if [[ $file_date -le $d_arg && $file =~ $n_arg ]]; then
                        tamanhoTotal=$((tamanhoTotal + tamanhoLocal));
                        dicionarioFicheiro[$file]=$tamanhoLocal
                    fi
                # Opção -n passada na linha de comandos
                elif [ $n_flag -eq 1 ]; then
                    if [[ $file =~ $n_arg ]];then
                        tamanhoTotal=$((tamanhoTotal + tamanhoLocal));
                        dicionarioFicheiro[$file]=$tamanhoLocal
                    fi
                # Opção -d passada na linha de comandos
                elif [ $d_flag -eq 1 ]; then
                    if  [ $file_date -le $d_arg ]; then
                        tamanhoTotal=$((tamanhoTotal + tamanhoLocal));
                        dicionarioFicheiro[$file]=$tamanhoLocal
                    fi 
                else
                    tamanhoTotal=$((tamanhoTotal + tamanhoLocal));
                    dicionarioFicheiro[$file]=$tamanhoLocal
                fi
            else
                #Tentar fazer a verificaçao aqui de NA
				#flagged=1
            fi
			
		elif [ -d "${file}" ] ;then
			arrayDiretorias+=($file)
			if [ $flagged -eq 0 ]
			then
				arrayTamanhos+=($tamanhoTotal) 
			else
				arrayTamanhos+=("NA")
			fi
			flagged=0
			guardarFiles "${file}"
        fi
        
	done
}

function showVals() {

    if [ $l_flag -eq 1 ]; then
        for i in "${!dicionarioMae[@]}"
        do  
            path=0;
            tamanhoLocal_b=0;
            final_space_files=()
            storage=($( ls -l $i | sort -nr | awk '{print $9}'))
            for j in "${storage[@]}"
            do
                # Se $j for um ficheiro
                path="$i/$j"
                if [ -f $path ]; then
					tamanhoLocal=$(ls -l ${path} | awk '{print $5}')
					file_date=$(stat $file | head -5 | tail -1 | awk '{print $2, $3}')
					file_date=$(date -d $file_date "+%Y%m%d%H%M")
            

                    if [ $n_flag -eq 1 -a $d_flag -eq 1 ]; then
                        if [[ $file_date -le $d_arg && $path =~ $n_arg ]]; then
                            final_space_files+=( $tamanhoLocal )
                        fi
                    elif [ $n_flag -eq 1 ]; then
                        if [[ $path =~ $n_arg ]];then
                            final_space_files+=( $tamanhoLocal )
                        fi
                    elif [ $d_flag -eq 1 ]; then
                        if [ $file_date -le $d_arg ]; then
                            final_space_files+=( $tamanhoLocal )
                        fi 
                    else
                        final_space_files+=( $tamanhoLocal )
                    fi
                fi
            done
            final_space_files=( $( printf "%s\n" "${final_space_files[@]}" | sort -nr | head -${l_arg} ) )
            for k in "${final_space_files[@]}"
            do
                tamanhoLocal_b=$((tamanhoLocal_b + k));
            done
            dicionarioMae[$i]=$tamanhoLocal_b
            echo ${dicionarioMae[$i]} $i
        done | sort $s
    fi
    

    if [ $L_flag -eq 1 ];then
        for k in "${!dicionarioFicheiro[@]}"
        do
            echo ${dicionarioFicheiro["$k"]} $k 
        done | sort $s | head -${L_arg}
    else

        for i in "${!dicionarioMae[@]}"
        do  
            final_space=0;
            diretorios=($( ls -lhR $i | grep '/' ))
            for j in "${diretorios[@]}"
            do
                j=${j%?}
                final_space=$((dicionarioMae[$j] + $final_space))
                
            done
			if [ $l_flag -eq 0 ];then
				echo $final_space $i
			fi
        done  | sort $s
    fi
}

function usoerro(){
    echo "Incorrect Usage of arguemnts."
    echo "Usage: ./totalspace.sh <Options> <Directories>"
    echo "   Examples:"
    echo "        Option: -l k, choose int_k biggest files from each directory"
    echo "        Option: -L k, choose int_k biggest files in all directories"
    echo "        Option: -n <.*sh>, only files that match regex expression"
    echo "        Option: -r, sort in reverse"
    echo "        Option: -a, sort alphabetically"
    echo "        Option: -d 'Sep 10 2018 10:00', acess maximum data to the file"
    echo "        Option: -e <filelist>, esconder ficheiros essenciais"
    echo "Warning! Options -l and -L can't be used simultaneosly, all other combinations allowed"
    echo "Warning! Options [ -L , -l , -n , -d ] require arguments."
    exit 1 #Terminar e indicar erro
}

function verificarArgs(){
    if [[ $1 == -* ]]
    then
        echo "Error: $1 can't be an option, it has to be an argument"
        usoerro
    fi
}

function verificarDobro(){
    if [[ $1 -eq 1 ]]
    then
        echo "Error: $opt has been used already"
        usoerro
    fi
}

function contemElemento() {
    local e match="$1"
    shift

    for e; 
        do [[ "$e" == "$match" ]] && echo "Pertence" && return 0
    done

    return 1
}

IFS=$'\n'
# Opções
	a_flag=0          # Opção -a
	d_flag=0            # Opção -d
	l_flag=0            # Opção -l
	L_flag=0            # Opção -L
	n_flag=0            # Opção -n
	r_flag=0          # Opção -r
    e_flag=0

	d_arg=0        # Argumento da opção -d
	l_arg=0        # Argumento da opção -l
	L_arg=0         # Argumento da opção -L
	n_arg=0
    e_arg=0
	
	flagged=0

	while getopts ":e:l:L:n:rad:" opt; do
		case ${opt} in
			n) # Procura por nome dos ficheiros
                verificarDobro "$n_flag"
				n_arg=${OPTARG}
                verificarArgs "${n_arg}"
				n_flag=1
				;;

			l) # Maiores em cada diretoria
				l_arg=${OPTARG}
                verificarDobro $l_flag
                l_flag=1
                verificarArgs $l_arg
				;;
	
			d) # Data máxima
                verificarDobro $d_flag
				d_arg=${OPTARG}
                verificarArgs "${d_arg}"
				d_flag=1
				;;

			L) # Maiores em todas as diretoria
                verificarDobro $L_flag
				L_arg=${OPTARG}
                verificarArgs "${L_arg}"
				L_flag=1
				;;

			r) # ordenar os valores
                verificarDobro $r_flag
				r_flag=1
				;;

			a) # ordenar alfabeticamente
                verificarDobro $a_flag
				a_flag=1
				;;
            e)
                verificarDobro $e_flag
                e_arg=${OPTARG}
                verificarArgs
                e_flag=1
                ;;
			*)
                usoerro
                ;;	
		esac
	done 


shift $(($OPTIND - 1)) 
	
if [[ $# -eq 0 ]]; then
    usoerro
fi

#verificar se e inteiro
if [[ $l_flag -eq 1 ]]; then
    if ! [[ $l_arg =~ ^[0-9]+$ ]]; then
        usoerro
    fi
fi

#verificar se e inteiro
if [[ $l_flag -eq 1 ]]; then
    if ! [[ $l_arg =~ ^[0-9]+$ ]]; then
        usoerro
    fi
fi

#Verificar ambos -l e -L
if [[ $l_flag -eq 1 && $L_flag -eq 1 ]]; then
    usoerro
fi

if [[ $n_flag -eq 1 ]]; then
    if ! [[ $n_arg =~ ^[0-9A-Za-z*.$_]+$ ]]; then
        usoerro
    fi
fi

if [[ $e_flag -eq 1 ]]; then
    if ! [[ -f $e_arg ]]; then
        usoerro
    fi
fi

if [[ $d_flag -eq 1 ]]; then
    d_return=$(date -d $d_arg)
    if [[ $? -eq 0 ]]; then
        d_arg=$(date -d $d_arg "+%Y%m%d%H%M")
    else
        echo "Invalid date, example: Sep 10 10:00"
        usoerro
    fi
fi


if [ $r_flag -eq 1 -a $a_flag -eq 0 ]; then    # -r: ordenação numérica e decrescente
	s="-nr"
elif [ $a_flag -eq 1 -a $r_flag -eq 0 ]; then  # -a: ordenação alfabética e crescente (de A até Z)
	s="-k2"
elif [ $r_flag -eq 1 -a $a_flag -eq 1 ]; then   # -a && -r: ordenação alfabética e decrescente (de Z até A)
	s="-k2r"
else                                                # Default: ordenação numérica e crescente
	s="-n"                                       
fi


if [[ $e_flag -eq 1 ]]; then
    read -d '' -r -a filesEscondidos < $e_arg
    echo "Estes files estao escondidos: " "${filesEscondidos[@]}"
fi

declare -A dicionarioFicheiro 
declare -A dicionarioMae   
arrayTamanhos=()
arrayDiretorias=("$1")

guardarFiles $1
arrayTamanhos+=("${tamanhoTotal}")
count=0;                                    
for i in "${arrayDiretorias[@]}"
do
	dicionarioMae["${i}"]="${arrayTamanhos[$count]}"
	((count++));
done
showVals





