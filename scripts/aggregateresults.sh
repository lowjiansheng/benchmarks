if [ $# -le 0 ]; then
	to="300.0"
else
	to=$1
fi

if [ $# -le 2 ]; then
	extrstart=0
	extrlen=0
else
        extrstart=$2
	extrlen=$3
fi

aggregate="
library(doBy);

t <- read.table('stdin',header=FALSE,as.is=TRUE)

# extract odd and even columns
odd <- c(1,seq(3,ncol(t),2))
even <- c(1,2,seq(4,ncol(t),2))

# compute means of odd and sums of even columns
means <- summaryBy(.~V1, data=t[,odd], FUN=mean)
sums <- summaryBy(.~V1, data=t[,even], FUN=sum)

#interleave the columns again
merged <- merge(means,sums)
g <-    function(x){
                 if ( x == 1 ){
                        return (1);
                }else if ( x == 2 ){
                        return (ncol(means) + 1);
                }else{
                        if (x %% 2 != 0 ){
                                return (1 + (x - 1) / 2);
                        }else{
                                return (ncol(means) + x / 2);
                        }
                }
        }

mixed <- sapply(seq(1,ncol(merged)), FUN=g)
merged <- merged[mixed]

# round all values in odd columns except in column 1
output <- merged
odd <- seq(3,ncol(output),2)
output[odd] <- round(output[odd],2)

write.table(format(output, nsmall=2, scientific=FALSE), , , FALSE, , , , , FALSE, FALSE)
"

# add a trailing # in order to eliminate the last line if incomplete
data=$(mktemp)
cat > $data
echo "#" >> $data
while read line
do
	read -a array <<< "$line"
	if [[ $line != \#* ]]; then
		fn=${array[0]}

		# extract size
		start=$(echo $fn| egrep [0-9]* -bo | head -n 1 | cut -f1 -d':')
		len=$(echo $fn| egrep [0-9]* -bo | head -n 1 | cut -f2 -d':')
		len=${#len}
		if [[ $extrstart -eq 0 ]] && [[ $extrlen -eq 0 ]]; then
			extrstart=$start
			extrlen=$len
		else
			if [[ $# -le 2 ]]; then
				if [[ $start -ne $extrstart ]] || [[ $len -ne $extrlen ]]; then
					echo "Could not extract instance size due to inconsistent naming; please specify start and length of size within the filename manually"
					exit 1
				fi
			fi
		fi

		if [ $extrlen -ge 1 ]; then
			array[0]="${fn:$extrstart:$extrlen} 1"
		else
			array[0]="${array[0]} 1"
		fi
	        line=$(echo ${array[@]} | grep -v "#" | sed "s/\ \([0-9]*\)\.\([0-9]*\)/ \1.\2 0/g" | sed "s/---/$to 1/g")
		file=$(echo "$file\n$line")
	fi
done < $data
echo -e $file | Rscript <(echo "$aggregate")
rm $data
