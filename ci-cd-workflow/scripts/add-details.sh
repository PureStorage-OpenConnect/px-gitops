echo > ../setup-vars/setup-vars
cp ../setup-vars/setup-vars-template ../setup-vars/setup-vars

echo "Enter Application Git Repo details"
echo "                            "
echo "1) Main Branch Namespace"
read MainBranchNamespace
sed -ie "s,XX-MainBranch_Namespace-XX,$MainBranchNamespace,g" ../setup-vars/setup-vars
echo "                                           "
echo "2) Main Branch KubeConfig path"
read MainBranch_KUBECONF_PATH
sed -ie "s,XX-MainBranch_KUBECONF_PATH-XX,$MainBranch_KUBECONF_PATH,g" ../setup-vars/setup-vars
echo "                                           "
echo "3)  Dev Branch Namespace"
read DevBranchNamespace
sed -ie "s,XX-DevBranch_Namespace-XX,$DevBranchNamespace,g" ../setup-vars/setup-vars
echo "                                           "
echo "4)  Dev Branch KubeConfig path"
read DevBranch_KUBECONF_PATH
sed -ie "s,XX-DevBranch_KUBECONF_PATH-XX,$DevBranch_KUBECONF_PATH,g" ../setup-vars/setup-vars
echo "                                           "
countsetupVars=`ls -1 ../setup-vars/*-varse 2>/dev/null | wc -l`
if [ $countsetupVars != 0 ]
then 
rm ../setup-vars/*-varse
fi
