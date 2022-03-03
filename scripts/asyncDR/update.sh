#!/bin/bash
set -e -u
set -o pipefail

##Setting common variables
  PX_TIME_STAMP="$(date -u '+%Y-%m-%d-%H-%M-%S')";
  PX_LOG_FILE="./debug.log";

printf "\n\n==========================================================\nBEGIN: ${PX_TIME_STAMP}\n" >> "${PX_LOG_FILE}"

##Check utilities
  printf "Checking utilities:\n" >> "${PX_LOG_FILE}"
  for util in storkctl kubectl sed; do
    if ! which $util  2>&1 >> "${PX_LOG_FILE}" ; then
      echo "ERROR: $util binary not found in your PATH veriable. Aborting."| tee -a "${PX_LOG_FILE}"
      exit 1
    fi
  done
  printf "All utililities are available\n" >> "${PX_LOG_FILE}"

##Help text
  fun_howtouse() {
    echo -e "\nUsage:\n    ${0} <namespace-containing-the-repository-to-be-cloned>\n" >&2
    exit 1
  }

##Display Progress
  vPROGRESS=" = >"
  fun_progress() {
    printf "\r${vPROGRESS}"
    vPROGRESS="$(
        if [[ "${vPROGRESS:0:1}" == "=" ]]; then
          printf " ";
        else
          printf "=";
        fi)${vPROGRESS}"
    sleep .2
  }

printf "Launched repository update (cloning) process. Please wait until it completes.\n" | tee -a "${PX_LOG_FILE}"
##Check: Command-line parameter must passed.
  printf "Checking: Command-line parameter must passed: " >> "${PX_LOG_FILE}"
  if [[ -z "${1+x}" ]]; then
    echo -e "\n\nCommand-line parameter missing." | tee -a "${PX_LOG_FILE}"
    fun_howtouse
  fi
  printf "Successful\n" >> "${PX_LOG_FILE}"
  fun_progress


##Inport config variables
  vCONFIFILE=./config-vars
  source ${vCONFIFILE}
  fun_progress

  PX_SRC_NAMESPACE="$1"
  PX_DST_NAMESPACE="${PX_SRC_NAMESPACE}-${PX_DST_NAMESPACE_SUFFIX}"
  PX_AsyncDR_CRDs_NAMESPACE="kube-system";

##Check: kube-config file must exist.
  printf "Checking: kube-config file must exist: " >> "${PX_LOG_FILE}"
  if [[ ! -f "${PX_KUBECONF_FILE_DESTINATION_CLUSTER}" ]]; then
    printf "\nError: Kube-config file for the cluster not found: \"${PX_KUBECONF_FILE_DESTINATION_CLUSTER}\"\nMake sure to correctly set the PX_KUBECONF_FILE_DESTINATION_CLUSTER variable in \"${vCONFIFILE}\" file.\n\n"  | tee -a "${PX_LOG_FILE}"
    exit 
  fi
  PX_KUBECONF_DST="--kubeconfig=${PX_KUBECONF_FILE_DESTINATION_CLUSTER}";
  printf "Successful\n" >> "${PX_LOG_FILE}"
  fun_progress

##Check: connectivity.
  printf "Checking connectivity to the cluster by listing kube-system namespace.\n" >> "${PX_LOG_FILE}"
  kubectl get ns kube-system ${PX_KUBECONF_DST} >> "${PX_LOG_FILE}" 2>&1 || { echo "Error: Unable to connect to the cluster." | tee -a "${PX_LOG_FILE}"; exit 1 ;}
  printf "Successful\n" >> "${PX_LOG_FILE}"
  fun_progress

##Check: The namespace to be cloned must exist and it must be a valid git-repo.
  printf "Checking: Namespace to be cloned must exist and must be a valid git-repo: " >> "${PX_LOG_FILE}"
  kubectl get namespace ${PX_SRC_NAMESPACE} -o custom-columns=":metadata.labels.type" --no-headers ${PX_KUBECONF_DST} 2>> "${PX_LOG_FILE}" | \
      grep -x "git-server" > /dev/null 2>&1 || \
      { echo -e "\nError: Repository namespace \"${PX_SRC_NAMESPACE}\" does not exist on the cluster OR it is not a valid git server namespace.\n" | tee -a "${PX_LOG_FILE}"; exit 1 ;}
  printf "Successful\n" >> "${PX_LOG_FILE}" 
  fun_progress

##Generate application clone manifest
  printf "Finding portworx cluster UUID: " >> "${PX_LOG_FILE}"
  PX_DST_CLUSTER_UUID="$(kubectl ${PX_KUBECONF_DST} get storageclusters.core.libopenstorage.org --all-namespaces -o jsonpath='{.items[*].status.clusterUid}' 2>> "${PX_LOG_FILE}")"
  printf "Successful\n" >> "${PX_LOG_FILE}" 
  PX_CRDs_PREFIX=${PX_DST_CLUSTER_UUID}-${PX_SRC_NAMESPACE}
  PX_DIR_FOR_MANIFEST_FILES="./output/${PX_CRDs_PREFIX}";
  mkdir -p ${PX_DIR_FOR_MANIFEST_FILES}
  fun_progress

  printf "Generating application clone manifest.\n" >> "${PX_LOG_FILE}"
  PX_APPLICATION_CLONE_NAME="clone-${PX_SRC_NAMESPACE}-to-${PX_DST_NAMESPACE}"
  PX_APPLICATION_CLONE_NAMESPACE="${PX_AsyncDR_CRDs_NAMESPACE}"
  PX_APPLICATION_CLONE_MANIFEST_FILE="${PX_DIR_FOR_MANIFEST_FILES}/${PX_APPLICATION_CLONE_NAME}.yml";

  cat ./templates/app-clone.yml | \
      sed "s,<PX_APPLICATION_CLONE_NAME>,${PX_APPLICATION_CLONE_NAME},g" | \
      sed "s,<PX_APPLICATION_CLONE_NAMESPACE>,${PX_APPLICATION_CLONE_NAMESPACE},g" | \
      sed "s,<PX_SOURCE_NAMESPACE>,${PX_SRC_NAMESPACE},g" | \
      sed "s,<PX_DESTINATION_NAMESPACE>,${PX_DST_NAMESPACE},g" > "${PX_APPLICATION_CLONE_MANIFEST_FILE}"
  printf "Generated application clone manifest: ${PX_APPLICATION_CLONE_MANIFEST_FILE}\n" >> "${PX_LOG_FILE}"
  fun_progress

##Deleting Application clone CRD if already existing.
  vRetVal="$(kubectl ${PX_KUBECONF_DST} get applicationclones.stork.libopenstorage.org ${PX_APPLICATION_CLONE_NAME} -n ${PX_AsyncDR_CRDs_NAMESPACE} -o jsonpath='{.metadata.name}' 2>> /dev/null || true)"
  if [[ "${vRetVal}" != "" ]]; then
    printf "Application clone CRD is already existing.\nGoing to delete it: " >> "${PX_LOG_FILE}"
    kubectl ${PX_KUBECONF_DST} delete applicationclones.stork.libopenstorage.org ${PX_APPLICATION_CLONE_NAME} -n ${PX_AsyncDR_CRDs_NAMESPACE} >> "${PX_LOG_FILE}" 2>&1
    printf "Successful\n" >> "${PX_LOG_FILE}"
  fi

##Check if destination NS is already existing.
  printf "Check: If destination namespace \"${PX_DST_NAMESPACE}\" exists already: " >> "${PX_LOG_FILE}"
  vRetVal="$(kubectl ${PX_KUBECONF_DST} get namespace ${PX_DST_NAMESPACE} -o jsonpath="{.metadata.name}" 2>> "${PX_LOG_FILE}" || true)"
  fun_progress
  if [[ "${vRetVal}" == "${PX_DST_NAMESPACE}" ]]; then
    printf "It is already existing.\n" >> "${PX_LOG_FILE}"
    printf "Check: Destination namespace must be a valid git repository: " >> "${PX_LOG_FILE}"
    vRetVal="$(kubectl ${PX_KUBECONF_DST} get namespace "${PX_DST_NAMESPACE}" -o custom-columns=":metadata.labels.type" --no-headers 2>> "${PX_LOG_FILE}" | \
        grep -x "git-server" 2> /dev/null)";
    fun_progress
    if [[ "${vRetVal}" != "" ]]; then
      printf "It is a valid git repository.\n" >> "${PX_LOG_FILE}"
      printf "Finding deployment name to scale down the replicas to 0: \n" >> "${PX_LOG_FILE}"
      vRetVal="$(kubectl ${PX_KUBECONF_DST} get deployment -n "${PX_DST_NAMESPACE}" -o name 2>> "${PX_LOG_FILE}")" 
      fun_progress
      printf "${vRetVal}\n" >> "${PX_LOG_FILE}"
      printf "Scaleing down the replicas to 0 for '${vRetVal}' deployment: " >> "${PX_LOG_FILE}"
      kubectl ${PX_KUBECONF_DST} scale --replicas=0 "${vRetVal}" -n "${PX_DST_NAMESPACE}" >> "${PX_LOG_FILE}" 2>&1
      fun_progress
      printf "Deleting PVCs: " >> "${PX_LOG_FILE}"
      kubectl ${PX_KUBECONF_DST} delete pvc --all  -n "${PX_DST_NAMESPACE}"  >> "${PX_LOG_FILE}" 2>&1
      fun_progress
    else
      printf "It is not a valid git repository. So can not continue.\n" >> "${PX_LOG_FILE}";
      printf "Error: The destination namespace \"${PX_DST_NAMESPACE}\" is existing on the cluster but it is not a valid git server namespace. So can not continue.\n" | tee -a "${PX_LOG_FILE}";
      exit 1;
    fi
  else
    printf "It is not existing.\n" >> "${PX_LOG_FILE}"
  fi

##Apply application clone manifest.
  printf "Applying application clone manifest: " >> "${PX_LOG_FILE}"
  kubectl ${PX_KUBECONF_DST} apply -f ${PX_APPLICATION_CLONE_MANIFEST_FILE} >> "${PX_LOG_FILE}" 2>&1
  printf "Successful\n" >> "${PX_LOG_FILE}" 
  fun_progress

  vChecksDone=1
  vTotalChecks=40
  vSleepSeconds=5
  printf "Verify if application clone is ready.\n" >> "${PX_LOG_FILE}"
  while (( vChecksDone <= vTotalChecks )); do
    vRetVal="$(kubectl ${PX_KUBECONF_DST} get -f ${PX_APPLICATION_CLONE_MANIFEST_FILE} -n ${PX_AsyncDR_CRDs_NAMESPACE} -o jsonpath='{.status.volumes[0].status}' 2>> "${PX_LOG_FILE}" || true)"
    printf "(Check ${vChecksDone} of ${vTotalChecks}), Current status is '${vRetVal}'\n" >> "${PX_LOG_FILE}"
    if [[ "${vRetVal}" == "Successful" ]]; then
      printf "Verified: The application clone has been created.\n" >> "${PX_LOG_FILE}"
      break;
    fi
    vChecksDone=$(( vChecksDone + 1 ));
    sleep ${vSleepSeconds}
    fun_progress
  done;
  if (( vChecksDone > vTotalChecks )); then
    printf "\nUnable to create the application clone. Try to debug the issue.\nRefer the manifest files saved in: ${PX_DIR_FOR_MANIFEST_FILES}\n\n" | tee -a "${PX_LOG_FILE}"
    exit 1;
  fi
##Starting the cloned application.
  printf "Starting the cloned application. It takes some time, please wait.\n" >> "${PX_LOG_FILE}"
  (storkctl "${PX_KUBECONF_DST}" activate migrations -n "${PX_DST_NAMESPACE}" >> "${PX_LOG_FILE}" 2>&1)
  printf "Successful\n" >> "${PX_LOG_FILE}"
  fun_progress

##Setting the permissions to readonly.
  printf "Finding a pod from the namespace: " >> "${PX_LOG_FILE}"
  PX_GIT_POD_NAME="$(kubectl "${PX_KUBECONF_DST}" get pods -n "${PX_DST_NAMESPACE}" -o jsonpath={.items[0].metadata.name} 2>> "${PX_LOG_FILE}" || true)"
  fun_progress
  if [[ "${PX_GIT_POD_NAME}" != "" ]]; then
    printf "Found pod '${PX_GIT_POD_NAME}'\n" >> "${PX_LOG_FILE}"
    vChecksDone=1
    vTotalChecks=20
    vSleepSeconds=5
    printf "Checking if the pod is in running state: '${PX_GIT_POD_NAME}'" >> "${PX_LOG_FILE}"
    while (( vChecksDone <= vTotalChecks )); do
      PX_GIT_POD_STATUS="$(kubectl "${PX_KUBECONF_DST}" get pods ${PX_GIT_POD_NAME} -n "${PX_DST_NAMESPACE}" -o jsonpath={.status.phase} 2>> "${PX_LOG_FILE}")"
      fun_progress
      printf "(Check ${vChecksDone} of ${vTotalChecks}), Current status is '${PX_GIT_POD_STATUS}'\n" >> "${PX_LOG_FILE}"
      if [[ "${PX_GIT_POD_STATUS}" == "Running" ]]; then
        printf "The pod '${PX_GIT_POD_NAME} is in running state.\n" >> "${PX_LOG_FILE}"
        printf "Changing the permissions to readonly, also getting repo path for later use: " >> "${PX_LOG_FILE}"
        PX_REPO_PATH="$(kubectl "${PX_KUBECONF_DST}" exec --tty --stdin "${PX_GIT_POD_NAME}" -n "${PX_DST_NAMESPACE}" -- bash -c "chmod -R a-w /home/git/repos/*;ls /home/git/repos;" 2>> "${PX_LOG_FILE}")"
        fun_progress
        printf "Successful\n" >> "${PX_LOG_FILE}"
        break;
      else
        printf "The pod is not in running state, skipping set-permissions.\n" >> "${PX_LOG_FILE}"
      fi
    done;
    if (( vChecksDone > vTotalChecks )); then
      printf "\nWaiting for the pod to come in running state has timedout, skipping set-permissions\n" | tee -a "${PX_LOG_FILE}"
      exit 1;
    fi
  else
    printf "No pod is available, skipping set-permissions.\n" >> "${PX_LOG_FILE}"
  fi


##Delete the application clone CRD.
  printf "Delete the application clone CRD: " >> "${PX_LOG_FILE}"
  kubectl ${PX_KUBECONF_DST} delete -f ${PX_APPLICATION_CLONE_MANIFEST_FILE} >> "${PX_LOG_FILE}" 2>&1
  fun_progress
  printf "\n";
  printf "Successfully completed. Repository is ready to use in ${PX_DST_NAMESPACE} namespace.\n\n" | tee -a "${PX_LOG_FILE}"

##Show git repo end-point 
  printf "Preparing git repo end point.\n" >> "${PX_LOG_FILE}"
  printf "Getting service IP: " >> "${PX_LOG_FILE}"
  PX_SVC_IP="$(kubectl "${PX_KUBECONF_DST}" get service git-server-service -n ${PX_DST_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2> /dev/null || true)"

  if [[ "${PX_SVC_IP}" != "" ]]; then
    printf "Service IP: ${PX_SVC_IP}\n" >> "${PX_LOG_FILE}"
    printf "Check if git repository path is available: " >> "${PX_LOG_FILE}"
    if [[ "${PX_REPO_PATH}" != "" ]]; then
      PX_REPO_END_POINT="ssh://git@${PX_SVC_IP}/home/git/repos/${PX_REPO_PATH}"
      printf "Here is the git repository endpoint: ${PX_REPO_END_POINT}\n\n" | tee -a "${PX_LOG_FILE}"
    else
      printf "Unable to find repository path.\n" >> "${PX_LOG_FILE}"
    fi
  else
    printf "Unable to find service IP.\n" >> "${PX_LOG_FILE}"
  fi
