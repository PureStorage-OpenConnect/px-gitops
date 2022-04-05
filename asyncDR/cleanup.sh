#!/bin/bash
set -e -u
set -o pipefail

##Setting common variables
  PX_TIME_STAMP="$(date -u '+%Y-%m-%d-%H-%M-%S')";
  PX_LOG_FILE="./debug.log";

printf "\n\n==========================================================\nBEGIN: ${PX_TIME_STAMP}\n" >> "${PX_LOG_FILE}"

##Check utilities
  printf "Checking utilities:\n" >> "${PX_LOG_FILE}"
  for util in kubectl sed; do
    if ! which $util  2>&1 >> "${PX_LOG_FILE}" ; then
      echo "ERROR: $util binary not found in your PATH veriable. Aborting."| tee -a "${PX_LOG_FILE}"
      exit 1
    fi
  done
  printf "All utililities are available\n" >> "${PX_LOG_FILE}"

##Help text
  fun_howtouse() {
    echo -e "\nUsage:\n    ${0} <Namespace_name_to_cleanup_the_AsyncDR>\n" >&2
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

printf "Cleaning up the resources created for AsyncDR. Please wait...\n" | tee -a "${PX_LOG_FILE}"
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

##Check: kube-config file must exist.
  printf "Checking: kube-config files must exist: " >> "${PX_LOG_FILE}"
  if [[ ! -f "${PX_KUBECONF_FILE_SOURCE_CLUSTER}" ]]; then
    printf "\nError: Kube-config file for the source cluster not found: \"${PX_KUBECONF_FILE_SOURCE_CLUSTER}\"\nMake sure to correctly set the PX_KUBECONF_FILE_SOURCE_CLUSTER variable in \"${vCONFIFILE}\" file.\n\n"  | tee -a "${PX_LOG_FILE}"
    exit 
  fi
  if [[ ! -f "${PX_KUBECONF_FILE_DESTINATION_CLUSTER}" ]]; then
    printf "\nError: Kube-config file for the destination cluster not found: \"${PX_KUBECONF_FILE_DESTINATION_CLUSTER}\"\nMake sure to correctly set the PX_KUBECONF_FILE_DESTINATION_CLUSTER variable in \"${vCONFIFILE}\" file.\n\n"  | tee -a "${PX_LOG_FILE}"
    exit 
  fi

  PX_KUBECONF_SRC="--kubeconfig=${PX_KUBECONF_FILE_SOURCE_CLUSTER}";
  PX_KUBECONF_DST="--kubeconfig=${PX_KUBECONF_FILE_DESTINATION_CLUSTER}";
  printf "Successful\n" >> "${PX_LOG_FILE}"
  fun_progress

##Check: connectivity.
  printf "Checking connectivity to the source cluster by listing kube-system namespace.\n" >> "${PX_LOG_FILE}"
  kubectl get ns kube-system ${PX_KUBECONF_SRC} >> "${PX_LOG_FILE}" 2>&1 || { echo "Error: Unable to connect to the source cluster." | tee -a "${PX_LOG_FILE}"; exit 1 ;}
  printf "Successful\n" >> "${PX_LOG_FILE}"
  fun_progress

  printf "Checking connectivity to the destination cluster by listing kube-system namespace.\n" >> "${PX_LOG_FILE}"
  kubectl get ns kube-system ${PX_KUBECONF_DST} >> "${PX_LOG_FILE}" 2>&1 || { echo "Error: Unable to connect to the destination cluster." | tee -a "${PX_LOG_FILE}"; exit 1 ;}
  printf "Successful\n" >> "${PX_LOG_FILE}"
  fun_progress

##Finding the UUID of the destination cluster.
  printf "Finding destination PX cluster UUID: " >> "${PX_LOG_FILE}"
  PX_DST_CLUSTER_UUID="$(kubectl ${PX_KUBECONF_DST} get storageclusters.core.libopenstorage.org --all-namespaces -o jsonpath='{.items[*].status.clusterUid}' 2>> "${PX_LOG_FILE}")"
  printf "Successful\n" >> "${PX_LOG_FILE}" 

##Set config variables.
  PX_CRDs_PREFIX=${PX_DST_CLUSTER_UUID}-${PX_SRC_NAMESPACE}
  PX_AsyncDR_CRDs_NAMESPACE="kube-system";
  PX_DIR_FOR_MANIFEST_FILES="./output/${PX_CRDs_PREFIX}";

  PX_CLUSTER_PAIR_MANIFEST_FILE="${PX_DIR_FOR_MANIFEST_FILES}/${PX_CRDs_PREFIX}-cluster-pair.yml";

  PX_SCHEDULE_POLICY_MANIFEST_FILE="${PX_DIR_FOR_MANIFEST_FILES}/${PX_CRDs_PREFIX}-schedule-policy.yml"

  PX_MIGRATION_SCHEDULE_MANIFEST_FILE="${PX_DIR_FOR_MANIFEST_FILES}/${PX_CRDs_PREFIX}-migration-schedule.yml"

  PX_APPLICATION_CLONE_NAME=""
  PX_APPLICATION_CLONE_MANIFEST_FILE="${PX_DIR_FOR_MANIFEST_FILES}/${PX_SRC_NAMESPACE}-to-${PX_DST_NAMESPACE}-clone.yml";

##Deleting the resources.
  printf "\nDeleting application clone from destination cluster...\n" >> "${PX_LOG_FILE}"
  kubectl ${PX_KUBECONF_DST} delete -f ${PX_APPLICATION_CLONE_MANIFEST_FILE} >> "${PX_LOG_FILE}" 2>&1 || true
  fun_progress

  printf "\nDeleting migration-schedule from the source cluster...\n" >> "${PX_LOG_FILE}"
  kubectl ${PX_KUBECONF_SRC} delete -f ${PX_MIGRATION_SCHEDULE_MANIFEST_FILE} >> "${PX_LOG_FILE}" 2>&1 || true
  fun_progress

  printf "\nDeleting schedule-policy from the source cluster...\n" >> "${PX_LOG_FILE}"
  kubectl ${PX_KUBECONF_SRC} delete -f ${PX_SCHEDULE_POLICY_MANIFEST_FILE} >> "${PX_LOG_FILE}" 2>&1 || true
  fun_progress

  printf "\nDeleting cluster-pair from the source cluster...\n" >> "${PX_LOG_FILE}"
  kubectl ${PX_KUBECONF_SRC} delete -f ${PX_CLUSTER_PAIR_MANIFEST_FILE} >> "${PX_LOG_FILE}" 2>&1 || true
  fun_progress

  printf "\nDeleting migrated namespaces (Standby+Running) from the destination cluster...\n" >> "${PX_LOG_FILE}"
  kubectl ${PX_KUBECONF_DST} delete ns ${PX_SRC_NAMESPACE} ${PX_DST_NAMESPACE} >> "${PX_LOG_FILE}" 2>&1 || true
  fun_progress

  printf "\nThe cleanup process completed.\n\n" | tee -a "${PX_LOG_FILE}"