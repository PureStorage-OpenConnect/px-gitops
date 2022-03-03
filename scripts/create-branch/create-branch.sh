#!/bin/bash
set -e -u
set -o pipefail

##Check utililities
  for util in kubectl awk grep sed; do
    if ! which $util >& /dev/null; then
      echo "ERROR: $util binary not found in path. Aborting."
      exit 1
    fi
  done

##Help text
  howtouse() {
      echo -e "\nUsage:\n    $0 [Namespace-Containing-Source-Repo] [New-Namespace-For-Branch-Repo]\n" >&2
      exit 1
  }

##Test if source and destination namespaces passed.
  if [[ -z "${1+x}" ]]; then
    echo -e "\n\nSource and destination namespaces not passed."
    howtouse
  fi
  if [[ -z "${2+x}" ]]; then
    echo -e "\n\nDestination namespace not passed."
    howtouse
  fi

##Inport config variables
  vCONFIFILE=./config-vars
  source ${vCONFIFILE}

##Checking aws credentials:
  if [[ "${PX_AWS_REGION}x" == "x" ]]; then echo "PX_AWS_REGION is not set. Please edit the ${vCONFIFILE} file and put the correct value."; exit 1; fi
  if [[ "${PX_AWS_ACCESS_KEY_ID}x" == "x" ]]; then echo "PX_AWS_ACCESS_KEY_ID is not set. Please edit the ${vCONFIFILE} file and put the correct value."; exit 1; fi
  if [[ "${PX_AWS_SECRET_ACCESS_KEY}x" == "x" ]]; then echo "PX_AWS_SECRET_ACCESS_KEY is not set. Please edit the ${vCONFIFILE} file and put the correct value."; exit 1; fi

##Setting kube-configs.
  PX_KUBECONF_SOURCE="";
  PX_KUBECONF_DESTINATION="";

  if [[ "${PX_KUBECONF_PATH_SOURCE_CLUSTER}x" != "x" ]]; then
    PX_KUBECONF_SOURCE="--kubeconfig=${PX_KUBECONF_PATH_SOURCE_CLUSTER}";
  else
    echo -e "\nSelecting default cluster as source.\nTo use a different cluster edit the ${vCONFIFILE} file and set the PX_KUBECONF_PATH_SOURCE_CLUSTER variable."
  fi
  if [[ "${PX_KUBECONF_PATH_DESTINATION_CLUSTER}x" != "x" ]]; then
    PX_KUBECONF_DESTINATION="--kubeconfig=${PX_KUBECONF_PATH_DESTINATION_CLUSTER}";
  else
    echo -e "\nSelecting default cluster as destination.\nTo use a different cluster edit the ${vCONFIFILE} file and set the PX_KUBECONF_PATH_DESTINATION_CLUSTER variable."
  fi

##Checking connectivity.
  printf "\nChecking connectivity to the source and destination clusters: "
  kubectl get nodes ${PX_KUBECONF_SOURCE} >/dev/null 2>&1 || { echo "Error: Unable to connect to the source cluster."; exit 1 ;}
  kubectl get nodes ${PX_KUBECONF_DESTINATION} >/dev/null 2>&1 || { echo "Error: Unable to connect to the destination cluster."; exit 1 ;}
  printf "Successful\n" 

##Check: Source-namespace must exists and it must be a valid git-repo.
  PX_SOURCE_NAMESPACE="$1"
  kubectl get namespace ${PX_SOURCE_NAMESPACE} -o custom-columns=":metadata.labels.type" --no-headers ${PX_KUBECONF_SOURCE} 2> /dev/null | grep "git-server" >/dev/null 2>&1 || { echo -e "\nError: Branch \"${PX_SOURCE_NAMESPACE}\" does not exist on the source cluster OR it is not a valid repository.\n"; exit 1 ;}

##Check: Destination namespace must not be existing already.
  PX_DESTINATION_NAMESPACE="$2"
  kubectl get namespace ${PX_DESTINATION_NAMESPACE} ${PX_KUBECONF_DESTINATION} >/dev/null 2>&1 && { echo -e "\nError: Namesace \"${PX_DESTINATION_NAMESPACE}\" is already existing on the destination cluster.\n\n"; exit 1 ;}

##Prepare backup location and backup manifests:
  PX_TIME_STAMP="$(date -u '+%Y-%m-%d-%H-%M-%S')";
  PX_NAME_PREFIX="px-backup";

  PX_SECRET_NAME=${PX_NAME_PREFIX}-${PX_SOURCE_NAMESPACE}-${PX_TIME_STAMP}
  PX_BACKUP_LOCATION_NAME=${PX_NAME_PREFIX}-${PX_SOURCE_NAMESPACE}-${PX_TIME_STAMP}
  PX_APPLICATION_BACKUP_NAME=${PX_NAME_PREFIX}-${PX_SOURCE_NAMESPACE}-${PX_TIME_STAMP}
  PX_BUCKET_NAME=${PX_NAME_PREFIX}-${PX_SOURCE_NAMESPACE}
  PX_NAMESPACE_FOR_BACKUP_CRD="kube-system"
  
  TEMPLATES_MANIFEST_DIR=./templates
  GENERATED_MANIFESTS_DIR="./generated-manifests"
  mkdir -p "${GENERATED_MANIFESTS_DIR}"

  PX_FILENAME_FOR_BACKUP_LOCATION="${GENERATED_MANIFESTS_DIR}/${PX_APPLICATION_BACKUP_NAME}_BACKUP_LO.yml"
  PX_FILENAME_FOR_APPLICATION_BACKUP="${GENERATED_MANIFESTS_DIR}/${PX_APPLICATION_BACKUP_NAME}_BACKUP.yml"
  PX_FILENAME_FOR_APPLICATION_RESTORE="${GENERATED_MANIFESTS_DIR}/${PX_APPLICATION_BACKUP_NAME}_RESTORE.yml"
  
  PX_BACKUP_RESOURCES_SELECTOR_LABEL=""
  
  if [[ "${PX_BACKUP_RESOURCES_SELECTOR_LABEL_NAME}x" != "x" ]]; then
    PX_BACKUP_RESOURCES_SELECTOR_LABEL="${PX_BACKUP_RESOURCES_SELECTOR_LABEL_NAME}: \"${PX_BACKUP_RESOURCES_SELECTOR_LABEL_VALUE}\""
  fi

  cat "${TEMPLATES_MANIFEST_DIR}/1-TEMPLATE-aws-s3-backup-location.yml" | \
  sed "s,XX_ACCESS_KEYID_XX,${PX_AWS_ACCESS_KEY_ID},g" | \
  sed "s,XX_SECRET_ACCESS_KEY_XX,${PX_AWS_SECRET_ACCESS_KEY},g" | \
  sed "s,XX_REGION_XX,${PX_AWS_REGION},g" | \
  sed "s,XX_SECRET_NAME_XX,${PX_SECRET_NAME},g" | \
  sed "s,XX_BACKUP_LOCATION_NAME_XX,${PX_BACKUP_LOCATION_NAME},g" | \
  sed "s,XX_BUCKET_NAME_XX,${PX_BUCKET_NAME},g" | \
  sed "s,XX_NAMESPACE_FOR_BACKUP_CRD_XX,${PX_NAMESPACE_FOR_BACKUP_CRD},g" | \
  sed "s,XX_APPLICATION_BACKUP_NAME_XX,${PX_APPLICATION_BACKUP_NAME},g" | \
  sed "s,XX_SOURCE_NAMESPACE_XX,${PX_SOURCE_NAMESPACE},g" > ${PX_FILENAME_FOR_BACKUP_LOCATION}
  
  cat "${TEMPLATES_MANIFEST_DIR}/2-TEMPLATE-backup.yml" | \
  sed "s,XX_ACCESS_KEYID_XX,${PX_AWS_ACCESS_KEY_ID},g" | \
  sed "s,XX_SECRET_ACCESS_KEY_XX,${PX_AWS_SECRET_ACCESS_KEY},g" | \
  sed "s,XX_REGION_XX,${PX_AWS_REGION},g" | \
  sed "s,XX_SECRET_NAME_XX,${PX_SECRET_NAME},g" | \
  sed "s,XX_NAMESPACE_FOR_BACKUP_CRD_XX,${PX_NAMESPACE_FOR_BACKUP_CRD},g" | \
  sed "s,XX_BACKUP_LOCATION_NAME_XX,${PX_BACKUP_LOCATION_NAME},g" | \
  sed "s,XX_BUCKET_NAME_XX,${PX_BUCKET_NAME},g" | \
  sed "s,XX_BACKUP_SELECTORS_XX,${PX_BACKUP_RESOURCES_SELECTOR_LABEL},g" | \
  sed "s,XX_APPLICATION_BACKUP_NAME_XX,${PX_APPLICATION_BACKUP_NAME},g" | \
  sed "s,XX_SOURCE_NAMESPACE_XX,${PX_SOURCE_NAMESPACE},g" > ${PX_FILENAME_FOR_APPLICATION_BACKUP}

##Creating backup location on source and destination clusters.
  if [[ "${PX_KUBECONF_PATH_SOURCE_CLUSTER}" = "${PX_KUBECONF_PATH_DESTINATION_CLUSTER}" ]]; then
    printf "\nCreating Backup location: "
    kubectl apply -f ${PX_FILENAME_FOR_BACKUP_LOCATION} ${PX_KUBECONF_SOURCE} >/dev/null
  else
    printf "\nCreating Backup location on both clusters: "
    kubectl apply -f ${PX_FILENAME_FOR_BACKUP_LOCATION} ${PX_KUBECONF_SOURCE} >/dev/null
    kubectl apply -f ${PX_FILENAME_FOR_BACKUP_LOCATION} ${PX_KUBECONF_DESTINATION} >/dev/null
  fi
  printf "Successful\n"

##Start taking backup
  echo -e "\nStarted creating new branch \"${PX_DESTINATION_NAMESPACE}\" from \"${PX_SOURCE_NAMESPACE}\".";

  echo -e "\nTaking backup of \"${PX_SOURCE_NAMESPACE}\" namespace.";
  kubectl apply -f ${PX_FILENAME_FOR_APPLICATION_BACKUP} ${PX_KUBECONF_SOURCE} >/dev/null

  vChecksDone=1;
  vTotalChecks=50;
  while (( vChecksDone <= vTotalChecks ))
    do
      vRetVal="$(kubectl get applicationbackup ${PX_APPLICATION_BACKUP_NAME} --namespace ${PX_NAMESPACE_FOR_BACKUP_CRD} --no-headers -o custom-columns='Status:status.status,Stage:status.stage' ${PX_KUBECONF_SOURCE})";
      vStatus="$( echo "${vRetVal}"|awk -F ' +' '{print $1}')"
      vState="$(  echo "${vRetVal}"|awk -F ' +' '{print $2}')"
      printf "\r"; printf "%s%-15s%s%-15s%s" "    Status: " "${vStatus}" "State: " "${vState}" "|"
      if [[ "${vState,,}" = "final" ]]; then
        if [[ "${vStatus,,}" = "successful" ]]; then
          printf "\n    Backup completed successfully.\n"
        elif [[ "${vStatus,,}" = "partialsuccess" ]]; then
          printf "\n    Caution: Backup completed with partial success. Trying to get information about failed resources:\n"
          kubectl get applicationbackup ${PX_APPLICATION_BACKUP_NAME} --namespace ${PX_NAMESPACE_FOR_BACKUP_CRD} --no-headers -o=jsonpath='{range .status.resources[?(@.status=="Failed")]}{"    ----------------------------------------------------\n"}{"    Resource Type : "}{.kind}{"\n"}{"    Name          : "}{.name}{"\n"}{"    Status        : "}{.reason}{"\n"}{end}' ${PX_KUBECONF_SOURCE}
          read -p "    Do you want to proceed to the restore process? (Y/N): " vConfirm
          if [[ "${vConfirm,,}" != "y" ]]; then
            printf "    Operation aborted.\n\n"
            exit 1;
          fi
        elif [[ "${vStatus,,}" = "failed" ]]; then
          printf "\n\n    Backup creation failed. Trying to find the reason.\n\n";
          kubectl get applicationbackup ${PX_APPLICATION_BACKUP_NAME} --namespace ${PX_NAMESPACE_FOR_BACKUP_CRD} --no-headers -o=jsonpath='{.status.reason}' ${PX_KUBECONF_SOURCE} 
          exit 1
        else
          printf "\n\nThere was some unknown error. Please try to create the backup manually.\n\n"
        fi
        break;
      fi
      echo -en $(yes "=" | head -n "${vChecksDone}"); printf " >";
      vChecksDone=$(( vChecksDone + 1 ));
      sleep 5
  done;
  if (( vChecksDone > vTotalChecks )); then
    printf "\n\nThere was some unknown error. Please try to create the backup manually.\n\n"
    exit 1
  fi

##Check if backup is ready to restore on remote restore:
  echo -e "\nChecking if backup is ready to restore.";

  vChecksDone=1;
  vTotalChecks=50;
  while (( vChecksDone <= vTotalChecks ))
  do
    vRetVal="$(kubectl get applicationbackup --namespace ${PX_NAMESPACE_FOR_BACKUP_CRD} --no-headers -l=name=="${PX_APPLICATION_BACKUP_NAME}" -o jsonpath="{.items[*].metadata.name}:{.items[*].metadata.labels.name}" ${PX_KUBECONF_DESTINATION})";
    vBakupName="$(echo ${vRetVal} | cut -f1 -d':')"
    vBakupLabel="$(echo ${vRetVal} | cut -f2 -d':')"
    if [[ "${vBakupLabel}" = "${PX_APPLICATION_BACKUP_NAME}" ]]; then
      echo -e "    Backup is available to restore.";
      break;
    fi
    printf "\r    Checking...     |"; echo -en $(yes "=" | head -n "${vChecksDone}"); printf " >";
    vChecksDone=$(( vChecksDone + 1 ));
    sleep 5
  done;
  if (( vChecksDone > vTotalChecks )); then
    printf "\n\n    Backup is not ready. And checking process has timed out.\n\n"
    exit 1
  fi

##Prepare restore manifest
  PX_APPLICATION_RESTORE_NAME="px-restore-${PX_SOURCE_NAMESPACE}-to-${PX_DESTINATION_NAMESPACE}-${PX_TIME_STAMP}"
  cat "${TEMPLATES_MANIFEST_DIR}/3-TEMPLATE-restore.yml" | \
  sed "s,XX_ACCESS_KEYID_XX,${PX_AWS_ACCESS_KEY_ID},g" | \
  sed "s,XX_SECRET_ACCESS_KEY_XX,${PX_AWS_SECRET_ACCESS_KEY},g" | \
  sed "s,XX_REGION_XX,${PX_AWS_REGION},g" | \
  sed "s,XX_NAMESPACE_FOR_BACKUP_CRD_XX,${PX_NAMESPACE_FOR_BACKUP_CRD},g" | \
  sed "s,XX_SECRET_NAME_XX,${PX_SECRET_NAME},g" | \
  sed "s,XX_BACKUP_LOCATION_NAME_XX,${PX_BACKUP_LOCATION_NAME},g" | \
  sed "s,XX_BUCKET_NAME_XX,${PX_BUCKET_NAME},g" | \
  sed "s,XX_APPLICATION_RESTORE_NAME_XX,${PX_APPLICATION_RESTORE_NAME},g" | \
  sed "s,XX_APPLICATION_BACKUP_NAME_XX,${vBakupName},g" | \
  sed "s,XX_SOURCE_NAMESPACE_XX,${PX_SOURCE_NAMESPACE},g" | \
  sed "s,XX_DESTINATION_NAMESPACE_XX,${PX_DESTINATION_NAMESPACE},g" > "${PX_FILENAME_FOR_APPLICATION_RESTORE}"

##Start restoring backup to new NS
  echo -e "\nRestoring backup of \"${PX_SOURCE_NAMESPACE}\" repository to \"${PX_DESTINATION_NAMESPACE}\".";
  kubectl apply -f "${PX_FILENAME_FOR_APPLICATION_RESTORE}" ${PX_KUBECONF_DESTINATION} >/dev/null

  vChecksDone=1;
  vTotalChecks=50;
  while (( vChecksDone <= vTotalChecks ))
    do
      vRetVal="$(kubectl get applicationrestore ${PX_APPLICATION_RESTORE_NAME} --namespace ${PX_NAMESPACE_FOR_BACKUP_CRD} --no-headers -o custom-columns='Status:status.status,Stage:status.stage' ${PX_KUBECONF_DESTINATION})";
      vStatus="$( echo "${vRetVal}"|awk -F ' +' '{print $1}')"
      vState="$(  echo "${vRetVal}"|awk -F ' +' '{print $2}')"
      printf "\r"; printf "%s%-15s%s%-15s%s" "    Status: " "${vStatus}" "State: " "${vState}" "|"
      if [[ "${vState,,}" = "final" ]]; then
        if [[ "${vStatus,,}" = "successful" ]]; then
          printf "\n    Restore completed successfully.\n"
        elif [[ "${vStatus,,}" = "partialsuccess" ]]; then
          printf "\n    Caution: Restore completed with partial success. Trying to get information about failed resources:\n"
          kubectl get applicationrestore ${PX_APPLICATION_RESTORE_NAME} --namespace ${PX_NAMESPACE_FOR_BACKUP_CRD} --no-headers -o=jsonpath='{range .status.resources[?(@.status=="Failed")]}{"    ----------------------------------------------------\n"}{"    Resource Type : "}{.kind}{"\n"}{"    Name          : "}{.name}{"\n"}{"    Status        : "}{.reason}{"\n"}{end}' ${PX_KUBECONF_DESTINATION}
        elif [[ "${vStatus,,}" = "failed" ]]; then
          printf "\n\n    Restore process failed. Trying to find the reason.\n\n"
          kubectl get applicationrestore ${PX_APPLICATION_RESTORE_NAME} --namespace ${PX_NAMESPACE_FOR_BACKUP_CRD} --no-headers -o=jsonpath='{.status.reason}' ${PX_KUBECONF_DESTINATION}
          exit 1
        else
          printf "\n\n    There was some unknown error. Please try to restore the backup manually.\n\n"
          exit 1
        fi
        break;
      fi
      echo -en $(yes "=" | head -n "${vChecksDone}"); printf " >";
      vChecksDone=$(( vChecksDone + 1 ));
      sleep 5
  done;
  if (( vChecksDone > vTotalChecks )); then
    printf "\n\nThere was some unknown error. Please try to restore the backup manually.\n\n"
    exit 1
  fi

##Cleanup
  printf "\nCleaning up the resources: ";
  if [[ "${PX_KUBECONF_PATH_SOURCE_CLUSTER}" = "${PX_KUBECONF_PATH_DESTINATION_CLUSTER}" ]]; then
    kubectl delete -f ${PX_FILENAME_FOR_BACKUP_LOCATION} ${PX_KUBECONF_SOURCE} >/dev/null
  else
    printf "\nCreating Backup location on both clusters: "
    kubectl delete -f ${PX_FILENAME_FOR_BACKUP_LOCATION} ${PX_KUBECONF_SOURCE} >/dev/null
    kubectl delete -f ${PX_FILENAME_FOR_BACKUP_LOCATION} ${PX_KUBECONF_DESTINATION} >/dev/null
  fi
  kubectl delete -f ${PX_FILENAME_FOR_APPLICATION_BACKUP} ${PX_KUBECONF_SOURCE} >/dev/null
  kubectl delete -f ${PX_FILENAME_FOR_APPLICATION_RESTORE} ${PX_KUBECONF_DESTINATION} >/dev/null
  printf "Done!\n\n"


echo > git-service-tmp.yaml
cp service.yaml git-service-tmp.yaml
sed -i "s,XX-namespace-XX,$PX_DESTINATION_NAMESPACE,g" git-service-tmp.yaml
kubectl apply -f git-service-tmp.yaml

kubectl create secret -n $PX_DESTINATION_NAMESPACE generic regcred \
    --from-file=.dockerconfigjson=config.json \
    --type=kubernetes.io/dockerconfigjson

while true; do
     read -p "Enter the branch name: " branch
     [[ -z $branch ]] && break
     echo -n " $branch" >> branch.txt
done
multipleBranch="$(cat branch.txt)"
echo $multipleBranch
rm branch.txt


echo -e "\nChecking pod status.....";  
  vChecksDone=1;
  vTotalChecks=10;
  while (( vChecksDone <= vTotalChecks ))
    do  
      vRetVal="$(kubectl get pod -n $PX_DESTINATION_NAMESPACE | awk 'FNR==2{print $3}')"
      if [[ "${vRetVal}" = "Running" ]]; then
         Vpodname="$(kubectl get pod -n $PX_DESTINATION_NAMESPACE | awk 'FNR==2{print $1}')"
         echo $Vpodname;
         kubectl cp create-multiple-branch.sh $PX_DESTINATION_NAMESPACE/$Vpodname:/tmp 
         kubectl exec --stdin --tty $Vpodname -n $PX_DESTINATION_NAMESPACE -- /bin/bash -c "bash /tmp/create-multiple-branch.sh $multipleBranch"
         break;
      fi   
      vChecksDone=$(( vChecksDone + 1 ));
      sleep 5
    done;
    if (( vChecksDone > vTotalChecks )); then
       printf "\n\n    pod is not ready. And checking process has timed out.\n\n"          
       exit 1
    fi 