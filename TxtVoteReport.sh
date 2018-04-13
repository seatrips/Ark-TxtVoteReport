#!/bin/bash
# Gr33nDrag0n / v1.2 / 2017-04-02

OutputFile='/var/www/html/VoteReport.txt'


###############################################################################
# FUNCTIONS
###############################################################################

function GetVotersCount {
	
	VotersJsonData=$( curl -s "http://127.0.0.1:18124/api/delegates/voters?publicKey=$1" )
	echo $VotersJsonData | jq '.accounts | length'	
}

#==============================================================================

function PrintJsonData {

	echo $1 | jq -c -r '.delegates[] | { rate, username, vote, address, publicKey, approval }' | while read Line; do
		
		Rank=$( printf %02d $( echo $Line | jq -r '.rate' ) )
		
		Delegate=$( printf %-25s $( echo $Line | jq -r '.username' ) )
		Approval=$( printf %0.2f $( echo $Line | jq -r '.approval' ) )
	
		Vote=$( expr $( echo $Line | jq -r '.vote' ) / 100000000 )
		Vote=$( echo $Vote | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta' )
		Vote=$( printf %10s $Vote )
		
		PublicKey=$( echo $Line | jq -r '.publicKey' )
		Voters=$( printf %4s $( GetVotersCount $PublicKey ) )
		
		echo "|  $Rank  | $Delegate |  $Approval  | $Vote |  $Voters  |" >> $2
	done
}

#==============================================================================

function PrintTotalVotingWeightData {

	TotalArk=$( curl -s "http://127.0.0.1:18124/api/blocks/getSupply" | jq '.supply' )
	
	TotalVote=0
	TotalVoters=0
	while read Line; do
		
		Vote=$( echo $Line | jq -r '.vote' )
		TotalVote=$( expr $TotalVote + $Vote )
		
		PublicKey=$( echo $Line | jq -r '.publicKey' )
		Voters=$( GetVotersCount $PublicKey )
		TotalVoters=$( expr $TotalVoters + $Voters )

	done <<< "$( echo $1 | jq -c -r '.delegates[] | { rate, username, vote, address, publicKey, approval }' )"
	
	Percentage=$( bc <<< "scale=2; $TotalVote * 100 / $TotalArk" )
	
	TotalVote=$( expr $( echo $TotalVote ) / 100000000 )
	TotalVote=$( echo $TotalVote | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta' )
	
	TotalArk=$( expr $( echo $TotalArk ) / 100000000 )
	TotalArk=$( echo $TotalArk | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta' )
	
	echo -e "Top 51 Delegates Stats\n" >> $2
	echo -e "=> Total Votes  : $Percentage% ( $TotalVote / $TotalArk )" >> $2
	echo -e "=> Total Voters : $TotalVoters\n" >> $2
}

###############################################################################
# MAIN
###############################################################################

JsonData1=$( curl -s 'http://127.0.0.1:18124/api/delegates' )
JsonData2=$( curl -s 'http://127.0.0.1:18124/api/delegates?limit=29&offset=51' )

WorkFile='./TxtVoteReport.txt'

echo '' > $WorkFile
PrintTotalVotingWeightData $JsonData1 $WorkFile
echo '===================================================================' >> $WorkFile
echo '| Rank | Delegate                  | Vote % |  Vote ARK  | Voters |' >> $WorkFile
echo '===================================================================' >> $WorkFile
PrintJsonData $JsonData1 $WorkFile
echo '===================================================================' >> $WorkFile
PrintJsonData $JsonData2 $WorkFile
echo '===================================================================' >> $WorkFile
Date=$( date -u "+%Y-%m-%d %H:%M:%S" )
echo -e "\n$Date UTC / TxtVoteReport.sh v1.2 / ArkNode.net (Gr33nDrag0n)\n" >> $WorkFile

#cat $WorkFile
cp -f $WorkFile $OutputFile
