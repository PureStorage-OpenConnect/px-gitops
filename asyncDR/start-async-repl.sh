#!/bin/bash
set -e -u
set -o pipefail

##Setting common variables
  PX_TIME_STAMP="$(date -u '+%Y-%m-%d-%H-%M-%S-%Z')";
  PX_LOG_FILE="./debug.log";

printf "\n\n==========================================================\nBEGIN: ${PX_TIME_STAMP}\n" >> "${PX_LOG_FILE}"

##Check utililities
  printf "Checking utililities:\n" >> "${PX_LOG_FILE}"
  for util in storkctl kubectl awk sed; do
    if ! which $util  2>&1 >> "${PX_LOG_FILE}" ; then
      echo "ERROR: $util binary not found in your PATH veriable. Aborting."| tee -a "${PX_LOG_FILE}"
      exit 1
    fi
  done
  printf "All utililities are available\n" >> "${PX_LOG_FILE}"

##Help text
  howtouse() {
    echo -e "\nUsage:\n    ${0} <namespace-containing-the-repository-to-replicate-on-remote-cluster>\n" >&2
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

printf "Started setting up AsyncDR replication. This may take some time.\n" | tee -a "${PX_LOG_FILE}"
##Check: command-line parameter must passed.
  printf "Checking: Command-line parameter must passed: " >> "${PX_LOG_FILE}"
  if [[ -z "${1+x}" ]]; then
    echo -e "\n\nCommand-line parameter missing." | tee -a "${PX_LOG_FILE}"
    howtouse
  fi
  PX_NAMESPACE_TO_MIGRATE="$1"
  printf "Successful\n" >> "${PX_LOG_FILE}"
  fun_progress

##Inport config variables
  vCONFIFILE=./config-vars
  source ${vCONFIFILE}
  fun_progress

##Check: kube-config files must exist.
  printf "Checking: kube-config files must exist: " >> "${PX_LOG_FILE}"
  if [[ ! -f "${PX_KUBECONF_FILE_SOURCE_CLUSTER}" ]]; then
    printf "\nError: Kube-config file for source cluster not found: \"${PX_KUBECONF_FILE_SOURCE_CLUSTER}\"\nMake sure to correctly set the PX_KUBECONF_FILE_SOURCE_CLUSTER variable in \"${vCONFIFILE}\" file.\n\n" | tee -a "${PX_LOG_FILE}"
    exit
  fi
  fun_progress
  if [[ ! -f "${PX_KUBECONF_FILE_DESTINATION_CLUSTER}" ]]; then
    printf "\nError: Kube-config file for destination cluster not found: \"${PX_KUBECONF_FILE_DESTINATION_CLUSTER}\"\nMake sure to correctly set the PX_KUBECONF_FILE_DESTINATION_CLUSTER variable in \"${vCONFIFILE}\" file.\n\n"  | tee -a "${PX_LOG_FILE}"
    exit 
  fi
  printf "Successful\n" >> "${PX_LOG_FILE}"
  fun_progress

##Setting kube-configs.
  PX_KUBECONF_SRC="--kubeconfig=${PX_KUBECONF_FILE_SOURCE_CLUSTER}";
  PX_KUBECONF_DST="--kubeconfig=${PX_KUBECONF_FILE_DESTINATION_CLUSTER}";
  fun_progress

##Check: connectivity.
  printf "Checking connectivity to the source and destination clusters by listing kube-system namespace.\n" >> "${PX_LOG_FILE}"
  kubectl get ns kube-system ${PX_KUBECONF_SRC} >> "${PX_LOG_FILE}" 2>&1 || { echo "Error: Unable to connect to the source cluster." | tee -a "${PX_LOG_FILE}"; exit 1 ;}
  kubectl get ns kube-system ${PX_KUBECONF_DST} >> "${PX_LOG_FILE}" 2>&1 || { echo "Error: Unable to connect to the destination cluster." | tee -a "${PX_LOG_FILE}"; exit 1 ;}
  printf "Successful\n" >> "${PX_LOG_FILE}"
  fun_progress

##Check: Namespace must exist and it must be a valid git-repo.
  printf "Checking: Namespace must exist and must be a valid git-repo: " >> "${PX_LOG_FILE}"
  kubectl get namespace ${PX_NAMESPACE_TO_MIGRATE} -o custom-columns=":metadata.labels.type" --no-headers ${PX_KUBECONF_SRC} 2>> "${PX_LOG_FILE}" | \
      grep -x "git-server" > /dev/null 2>&1 || \
      { echo -e "\nError: Repository namespace \"${PX_NAMESPACE_TO_MIGRATE}\" does not exist on the source cluster OR it is not a valid repository.\n" | tee -a "${PX_LOG_FILE}"; exit 1 ;}
  printf "Successful\n" >> "${PX_LOG_FILE}" 
  fun_progress

##Check: Namespace must not be existing already on the destination cluster.
  printf "Checking: Namespace must not be existing already on the destination cluster: " >> "${PX_LOG_FILE}"
  kubectl get namespace ${PX_NAMESPACE_TO_MIGRATE} ${PX_KUBECONF_DST} > /dev/null 2>&1 && { printf "\n\n"; echo -e "Error: Namespace \"${PX_NAMESPACE_TO_MIGRATE}\" is already existing on the destination cluster.\n" | tee -a "${PX_LOG_FILE}"; exit 1 ;}
  printf "Successful\n" >> "${PX_LOG_FILE}"
  fun_progress

##Generate ClusterPair
  printf "Going to generate ClusterPair.\n" >> "${PX_LOG_FILE}"
  #Finding portworx executable;
  printf "Finding portworx executable: " >> "${PX_LOG_FILE}"
  PX_NS_AND_POD=$(kubectl ${PX_KUBECONF_DST} get pods -l name=portworx --all-namespaces -o jsonpath="{range .items[?(@.metadata.ownerReferences[*].kind=='StorageCluster')]}{.metadata.namespace}{' '}{.metadata.name}{'\n'}{end}" | head -1||true)
  if [[ "${PX_NS_AND_POD}" == "" ]]; then
    printf "\nError; Unable to find portworx executable pod, make sure portworx is set up and functioning.\n\n";
    exit;
  fi
  printf "Successful\n" >> "${PX_LOG_FILE}"
  fun_progress

  #Finding destination cluster details and adding to the 'options' spec for clusterpair
  printf "Finding destination cluster details and adding to the 'options' spec for clusterpair: " >> "${PX_LOG_FILE}"
  PX_DST_TOKEN="$(kubectl ${PX_KUBECONF_DST} exec -n $PX_NS_AND_POD -c portworx -- /opt/pwx/bin/pxctl cluster token show 2>> "${PX_LOG_FILE}"|  grep -i 'Token is '|cut -d' ' -f3;)"
  fun_progress
  PX_DST_PX_NODE_IP="$(kubectl ${PX_KUBECONF_DST} get storagenodes.core.libopenstorage.org --all-namespaces -o jsonpath='{.items[1].status.network.mgmtIP}{"\n"}' 2>> "${PX_LOG_FILE}")"
  fun_progress
  vRetVal1="$(kubectl ${PX_KUBECONF_DST} get storageclusters.core.libopenstorage.org --all-namespaces -o jsonpath='{.items[*].spec.startPort}{"/"}{.items[*].status.clusterUid}{"\n"}' 2>> "${PX_LOG_FILE}")"
  fun_progress
  PX_DST_PX_SVC_PORT="$(echo "${vRetVal1}"|cut -d'/' -f1)"
  PX_DST_CLUSTER_UUID="$(echo "${vRetVal1}"|cut -d'/' -f2)"
  PX_DR_MODE="DisasterRecovery"
  fun_progress
  
  PX_CLUSTER_PAIR_OPTIONS="$(cat ./templates/cluster-pair-options.yml | \
      sed "s,<PX_DST_PX_NODE_IP>,${PX_DST_PX_NODE_IP},g" | \
      sed "s,<PX_DST_PX_SVC_PORT>,${PX_DST_PX_SVC_PORT},g" | \
      sed "s,<PX_DST_TOKEN>,${PX_DST_TOKEN},g" | \
      sed "s,<PX_DR_MODE>,${PX_DR_MODE},g")"
  printf "Successful\n" >> "${PX_LOG_FILE}"
  fun_progress

  PX_CRDs_PREFIX=${PX_DST_CLUSTER_UUID}-${PX_NAMESPACE_TO_MIGRATE}
  PX_DIR_FOR_MANIFEST_FILES="./output/${PX_CRDs_PREFIX}";
  mkdir -p ${PX_DIR_FOR_MANIFEST_FILES}
  PX_CLUSTER_PAIR_NAME="${PX_CRDs_PREFIX}-cluster-pair";
  PX_AsyncDR_CRDs_NAMESPACE="kube-system";
  PX_CLUSTER_PAIR_MANIFEST_FILE="${PX_DIR_FOR_MANIFEST_FILES}/${PX_CLUSTER_PAIR_NAME}.yml";

##Generate and apply new ClusterPair manifest.
  printf "Generating ClusterPair manifest: ${PX_CLUSTER_PAIR_MANIFEST_FILE}\n" >> "${PX_LOG_FILE}"
  storkctl generate clusterpair ${PX_CLUSTER_PAIR_NAME} -n ${PX_AsyncDR_CRDs_NAMESPACE} ${PX_KUBECONF_DST} > "${PX_CLUSTER_PAIR_MANIFEST_FILE}" 2>> "${PX_LOG_FILE}"
  awk -v replc="${PX_CLUSTER_PAIR_OPTIONS//$'\n'/\\n}" '{gsub(/    insert_storage_options_here: .*/,replc)}1' "${PX_CLUSTER_PAIR_MANIFEST_FILE}"  > tmpfile && mv tmpfile "${PX_CLUSTER_PAIR_MANIFEST_FILE}"
  fun_progress
  printf "Manifest for ClusterPair '${PX_CLUSTER_PAIR_NAME}' has been generated.\nApplying ClusterPair manifest: " >> "${PX_LOG_FILE}"
  kubectl ${PX_KUBECONF_SRC} apply -f ${PX_CLUSTER_PAIR_MANIFEST_FILE} >> "${PX_LOG_FILE}" 2>&1
  sleep 1
  fun_progress

  vChecksDone=1;
  vTotalChecks=5;
  while (( vChecksDone <= vTotalChecks )); do
    printf "Verify if ClusterPair is ready (Check ${vChecksDone} of ${vTotalChecks}): " >> "${PX_LOG_FILE}"
    vRetVal="$(kubectl ${PX_KUBECONF_SRC} get clusterpairs.stork.libopenstorage.org ${PX_CLUSTER_PAIR_NAME} -n ${PX_AsyncDR_CRDs_NAMESPACE} -o jsonpath='{.status.schedulerStatus}{" "}{.status.storageStatus}' 2>> /dev/null || true)"
    if [[ "${vRetVal}" == "Ready Ready" ]]; then
      printf "Verified: ClusterPair is in ready state.\n" >> "${PX_LOG_FILE}"
      break;
    else
      printf "Not Ready, Retrying...\n" >> "${PX_LOG_FILE}"
    fi
    vChecksDone=$(( vChecksDone + 1 ));
    sleep 5
    fun_progress
  done;
  if (( vChecksDone > vTotalChecks )); then
    printf "\nUnable to proceed. Issue: ClusterPair status is not ready. Trying to find the event logs for more information:\n\n" | tee -a "${PX_LOG_FILE}"
    vRetVal="$(kubectl ${PX_KUBECONF_SRC} get events -n ${PX_AsyncDR_CRDs_NAMESPACE} -o=jsonpath='{range .items[?(@.involvedObject.kind=="ClusterPair")]}{.message}{"\n"}{end}' 2>> "${PX_LOG_FILE}" || true )"
    if [[ "${vRetVal}" != "" ]]; then
      printf "${vRetVal}" | tee -a "${PX_LOG_FILE}"
    else
      printf "No event logs detected. Unable to identify the reason." | tee -a "${PX_LOG_FILE}"
    fi
    exit 1;
  fi
  printf "ClusterPair creation finished.\n" >> "${PX_LOG_FILE}"
  fun_progress

##Creating schedule policy.
  #PX_SCHEDULE_POLICY_INTERVAL_MINUTES= Defined in config-vars file
  #PX_SCHEDULE_POLICY_DAILY_TIME= Defined in config-vars file
  #PX_SCHEDULE_POLICY_NAME="-daily-$(date -d"${PX_SCHEDULE_POLICY_DAILY_TIME}" +%I-%M-%P)"
  PX_SCHEDULE_POLICY_NAME="${PX_CRDs_PREFIX}-schedule-policy"
  PX_SCHEDULE_POLICY_MANIFEST_FILE="${PX_DIR_FOR_MANIFEST_FILES}/${PX_SCHEDULE_POLICY_NAME}.yml"
  printf "Creating schedule policy: " >> "${PX_LOG_FILE}"
  cat ./templates/schedule-policy.yml | \
      sed "s,<PX_SCHEDULE_POLICY_NAME>,${PX_SCHEDULE_POLICY_NAME},g" | \
      sed "s,<PX_SCHEDULE_POLICY_NAMESPACE>,${PX_AsyncDR_CRDs_NAMESPACE},g" | \
      sed "s,<PX_SCHEDULE_POLICY_INTERVAL_MINUTES>,${PX_SCHEDULE_POLICY_INTERVAL_MINUTES},g" | \
      sed "s,<PX_SCHEDULE_POLICY_DAILY_TIME>,${PX_SCHEDULE_POLICY_DAILY_TIME},g" > "${PX_SCHEDULE_POLICY_MANIFEST_FILE}"
  kubectl ${PX_KUBECONF_SRC} apply -f ${PX_SCHEDULE_POLICY_MANIFEST_FILE} >> "${PX_LOG_FILE}" 2>&1
  fun_progress

##Creating migration schedule.
  printf "Going to create the migration schedule: " >> "${PX_LOG_FILE}"
  PX_MIGRATION_SCHEDULE_NAME="${PX_CRDs_PREFIX}-migration-schedule"
  PX_MIGRATION_SCHEDULE_MANIFEST_FILE="${PX_DIR_FOR_MANIFEST_FILES}/${PX_MIGRATION_SCHEDULE_NAME}.yml"
  fun_progress

  cat ./templates/migration-schedule.yml | \
      sed "s,<PX_MIGRATION_SCHEDULE_NAME>,${PX_MIGRATION_SCHEDULE_NAME},g" | \
      sed "s,<PX_MIGRATION_SCHEDULE_NAMESPACE>,${PX_AsyncDR_CRDs_NAMESPACE},g" | \
      sed "s,<PX_CLUSTER_PAIR_NAME>,${PX_CLUSTER_PAIR_NAME},g" | \
      sed "s,<PX_NAMESPACE_TO_MIGRATE>,${PX_NAMESPACE_TO_MIGRATE},g" | \
      sed "s,<PX_SCHEDULE_POLICY_NAME>,${PX_SCHEDULE_POLICY_NAME},g" > "${PX_MIGRATION_SCHEDULE_MANIFEST_FILE}"
  kubectl ${PX_KUBECONF_SRC} apply -f ${PX_MIGRATION_SCHEDULE_MANIFEST_FILE} >> "${PX_LOG_FILE}" 2>&1
  printf "Migration schedule creation finished.\n" >> "${PX_LOG_FILE}"
  fun_progress

  vChecksDone=1
  vTotalChecks=500
  vSleepSeconds=15
  printf "Verify if application has been migrated to destination cluster.\n" >> "${PX_LOG_FILE}"
  while (( vChecksDone <= vTotalChecks )); do
    if (( vChecksDone = 6 )); then
      printf "Taking really long, please wait till it finishes.\n For debug open another terminal tab and try to describe the migration on source cluster as follows:\n" >> "${PX_LOG_FILE}"
      printf "kubectl ${PX_KUBECONF_SRC} describe -f ${PX_MIGRATION_SCHEDULE_MANIFEST_FILE} -n ${PX_AsyncDR_CRDs_NAMESPACE}\n" >> "${PX_LOG_FILE}"
    fi
    vRetVal="$(kubectl ${PX_KUBECONF_SRC} get -f ${PX_MIGRATION_SCHEDULE_MANIFEST_FILE} -n ${PX_AsyncDR_CRDs_NAMESPACE} -o jsonpath='{.status.items.Interval[0].status}' 2>> "${PX_LOG_FILE}" || true)"
    printf "(Check ${vChecksDone}), Current status is '${vRetVal}'\n" >> "${PX_LOG_FILE}"
    if [[ "${vRetVal}" == "Successful" ]]; then
      printf "Verified: The application has been migrated.\n" >> "${PX_LOG_FILE}"
      break;
    fi
    vChecksDone=$(( vChecksDone + 1 ));
    sleep ${vSleepSeconds}
    fun_progress
  done;
  if (( vChecksDone > vTotalChecks )); then
    printf "\nUnable to migrate the application. Try to debug the issue.\nRefer the manifest files saved in: ${PX_DIR_FOR_MANIFEST_FILES}\n\n" | tee -a "${PX_LOG_FILE}"
    exit 1;
  fi
  fun_progress
  printf "\n";
  printf "Successfully set up AsyncDR replication.\n\n" | tee -a "${PX_LOG_FILE}"

##Calling clone creation script.
  printf "Preparing to start the application on remote cluster using PX Application-Clone." >> "${PX_LOG_FILE}"
  ./update.sh ${PX_NAMESPACE_TO_MIGRATE}
exit 0;

