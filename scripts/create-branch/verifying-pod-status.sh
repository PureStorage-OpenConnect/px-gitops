echo -e "\nChecking pod status.....";  
  vChecksDone=1;
  vTotalChecks=10;
  while (( vChecksDone <= vTotalChecks ))
    do  
      vRetVal="$(kubectl get pod -n $PX_DESTINATION_NAMESPACE | awk 'FNR==2{print $3}')"
      if [[ "${vRetVal}" = "Running" ]]; then
         Vpodname="$(kubectl get pod -n $PX_DESTINATION_NAMESPACE | awk 'FNR==2{print $1}')"
         echo $Vpodname;
         kubectl cp create-dev-branch.sh $PX_DESTINATION_NAMESPACE/$Vpodname:/root && 
         kubectl exec --stdin --tty $Vpodname -n $PX_DESTINATION_NAMESPACE -- /bin/bash -c "bash /root/create-dev-branch.sh"
         break;
      fi   
      vChecksDone=$(( vChecksDone + 1 ));
      sleep 5
    done;
    if (( vChecksDone > vTotalChecks )); then
       printf "\n\n    pod is not ready. And checking process has timed out.\n\n"          
       exit 1
    fi   