echo > ../setup-vars/setup-vars
cp ../setup-vars/setup-vars-template ../setup-vars/setup-vars

echo "Enter Application Git Repo details"
echo "=> Application  Repo NameSpace"
read gitRepoNamespace
sed -ie "s,XX-gitRepoNamespace-XX,$gitRepoNamespace,g" ../setup-vars/setup-vars
echo "                                           "
echo "=> Application repo name"
read gitRepoName
sed -ie "s,XX-gitRepoName-XX,$gitRepoName,g" ../setup-vars/setup-vars
echo "                                           "
echo "=> Cluster Kube-Config File paths"
read ClusterKubeConfigFilePath
sed -ie "s,XX-ClusterKubeConfigFilePath-XX,$ClusterKubeConfigFilePath,g" ../setup-vars/setup-vars
echo "                                           "
echo "=>  application git repo url"
read gitRepoUrl
sed -ie "s,XX-gitRepoUrl-XX,$gitRepoUrl,g" ../setup-vars/setup-vars
echo "                                           "
echo "=> application manifest file directory path"
read directoryPath
sed -ie "s,XX-directoryPath-XX,$directoryPath,g" ../setup-vars/setup-vars

countsetupVars=`ls -1 ../setup-vars/*-varse 2>/dev/null | wc -l`
if [ $countsetupVars != 0 ]
then 
rm ../setup-vars/*-varse
fi

