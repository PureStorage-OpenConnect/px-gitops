source ../setup-vars/setup-vars
echo $gitRepoUrl    
encodedurl="$(echo -n $gitRepoUrl |  base64 )"
echo $encodedurl