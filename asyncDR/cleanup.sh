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
    echo -e "\nUsage:\n    ${0} Namespace_name_to_cleanup_the_AsyncDR [--all]\n" >&2
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

##Check: Command-line parameters.
  PX_DELETE_ALL=false
  printf "Checking: Command-line parameters: " >> "${PX_LOG_FILE}"
  if [[ -z "${1+x}" ]]; then
    echo -e "\n\nCommand-line parameter missing." | tee -a "${PX_LOG_FILE}"
    fun_howtouse
  else
    printf "Namespace passed: ${1}" >> "${PX_LOG_FILE}"
    if [[ -n "${2+x}" ]]; then
      if [[ "${2}" == "--all" ]]; then
        printf ", '--all' option passed\n" >> "${PX_LOG_FILE}"
        PX_DELETE_ALL=true
      else
        printf "\nUnrecognized option: ${2}\n\n" | tee -a "${PX_LOG_FILE}"
        fun_howtouse
      fi
    else
      printf "'--all' option not passed\n" >> "${PX_LOG_FILE}"
    fi
  fi
  printf "Successful\n" >> "${PX_LOG_FILE}"

printf "Cleaning up the resources created for AsyncDR. Please wait...\n" | tee -a "${PX_LOG_FILE}"

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
  PX_DIR_FOR_GENERATED_FILES="./output/${PX_CRDs_PREFIX}";

  PX_CLUSTER_PAIR_MANIFEST_FILE="${PX_DIR_FOR_GENERATED_FILES}/${PX_CRDs_PREFIX}-cluster-pair.yml";

  PX_SCHEDULE_POLICY_MANIFEST_FILE="${PX_DIR_FOR_GENERATED_FILES}/${PX_CRDs_PREFIX}-schedule-policy.yml"

  PX_MIGRATION_SCHEDULE_MANIFEST_FILE="${PX_DIR_FOR_GENERATED_FILES}/${PX_CRDs_PREFIX}-migration-schedule.yml"

  PX_APPLICATION_CLONE_MANIFEST_FILE="${PX_DIR_FOR_GENERATED_FILES}/${PX_SRC_NAMESPACE}-to-${PX_DST_NAMESPACE}-clone.yml";

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

  printf "\nDeleting migrated namespaces (Standby+Clone) from the destination cluster...\n" >> "${PX_LOG_FILE}"
  kubectl ${PX_KUBECONF_DST} delete ns ${PX_SRC_NAMESPACE} ${PX_DST_NAMESPACE} >> "${PX_LOG_FILE}" 2>&1 || true
  fun_progress

  if [[ "${PX_DELETE_ALL}"  == "true" ]]; then
    PX_RESOURCES_LOG_FILE="${PX_DIR_FOR_GENERATED_FILES}/resources-created"
    printf "\nThe '--all' option is passed, so also removing the PX API service and object-store-credentials if those had been created during the setup.\n" >> "${PX_LOG_FILE}"

    ##Deleting the service for Portworx API
      printf "\nChecking: If the service for Portworx API was created: " >> "${PX_LOG_FILE}"
      PX_API_SVC_DST="$(grep "|service|" "${PX_RESOURCES_LOG_FILE}"||true)"
      if [[ "${PX_API_SVC_DST}"  != "" ]]; then
        printf "Yes\nDeleting the service: " >> "${PX_LOG_FILE}"
        PX_SVC_NAME="$(echo "${PX_API_SVC_DST}" | cut -d'|' -f5 )"
        PX_SVC_NS="$(echo "${PX_API_SVC_DST}" | cut -d'|' -f3 )"
        kubectl ${PX_KUBECONF_DST} delete service "${PX_SVC_NAME}" -n ${PX_SVC_NS} >> "${PX_LOG_FILE}" 2> /dev/null || \
            printf "Service not found.\n" >> "${PX_LOG_FILE}"
        fun_progress
      else
        printf "No\n" >> "${PX_LOG_FILE}"
      fi
  
    ##Deleting the object-store-credentials from source cluster.
      PX_OBJ_STORE_CREDs_SRC="$(grep "SRC|NULL|object-store-credentials|" "${PX_RESOURCES_LOG_FILE}"||true)"
      printf "\nChecking: If the object-store-credentials was created on the source cluster: " >> "${PX_LOG_FILE}"
      if [[ "${PX_OBJ_STORE_CREDs_SRC}" != "" ]]; then
        printf "Yes, Needs to be deleted.\n" >> "${PX_LOG_FILE}"
        PX_OBJ_STORE_CREDENTIALS_NAME_SRC="$(echo "${PX_OBJ_STORE_CREDs_SRC}" | cut -d'|' -f5 )"
        PX_NS_SRC="$(grep "INFO|PX_NS_SRC|" "${PX_RESOURCES_LOG_FILE}" | cut -d'|' -f3 || true)"        
        PX_STORAGE_CLUSTER_NAME_SRC="$(grep "INFO|PX_STORAGE_CLUSTER_NAME_SRC|" "${PX_RESOURCES_LOG_FILE}" | cut -d'|' -f3 || true)"        
        PX_POD_SRC="$(grep "INFO|PX_ALL_PODS_SRC|" "${PX_RESOURCES_LOG_FILE}" | cut -d'|' -f3 | cut -d' ' -f1|| true)"

        ##It will require using pxctl, so set token if authorization is enabled.
        printf "Checking: If authorization is enabled on the source cluster: " >> "${PX_LOG_FILE}"
        PX_AUTH_CHECK="$(kubectl ${PX_KUBECONF_SRC} -n ${PX_NS_SRC} get storageclusters.core.libopenstorage.org ${PX_STORAGE_CLUSTER_NAME_SRC} -o custom-columns=":spec.security.enabled" --no-headers 2>/dev/null||true)"
        fun_progress
        if [[ "${PX_AUTH_CHECK}" == "true" ]]; then
          printf "Enabled, Going to add authorization token.\n" >> "${PX_LOG_FILE}"
          printf "Getting PX authorization token from the source cluster: " >> "${PX_LOG_FILE}"
          ADMIN_TOKEN_SRC="$(kubectl ${PX_KUBECONF_SRC} -n ${PX_NS_SRC} get secret px-admin-token -o jsonpath='{.data.auth-token}' | base64 -d 2> /dev/null)"
          fun_progress
          if [[ "${ADMIN_TOKEN_SRC}" != "" ]]; then
            printf "Successful\n" >> "${PX_LOG_FILE}"
            printf "Adding authorization token to the portworx pod '${PX_POD_SRC}': " >> "${PX_LOG_FILE}"
            kubectl ${PX_KUBECONF_SRC} -n ${PX_NS_SRC} exec -ti ${PX_POD_SRC} -c portworx -- /opt/pwx/bin/pxctl context create admin --token=$ADMIN_TOKEN_SRC >> "${PX_LOG_FILE}" 2>&1 || true;
            fun_progress
          else
            printf "Authorization is enabled but unable to get authorization token. Skipping add authorization token.\n" | tee -a "${PX_LOG_FILE}";
          fi
        else    
          printf "Disabled, Skipping add authorization token.\n" >> "${PX_LOG_FILE}"
        fi
        printf "Deleting the object-store-credentials from source cluster: " >> "${PX_LOG_FILE}"
        kubectl ${PX_KUBECONF_SRC} exec -n ${PX_NS_SRC} ${PX_POD_SRC} -c portworx -- /opt/pwx/bin/pxctl credentials delete ${PX_OBJ_STORE_CREDENTIALS_NAME_SRC} >> "${PX_LOG_FILE}" 2>&1 || true;
        fun_progress
      else
        printf "No\n" >> "${PX_LOG_FILE}"
      fi

    ##Deleting the object-store-credentials from destination cluster.
      PX_OBJ_STORE_CREDs_DST="$(grep "DST|NULL|object-store-credentials|" "${PX_RESOURCES_LOG_FILE}"||true)"
      printf "\nChecking: If the object-store-credentials was created on the destination cluster: " >> "${PX_LOG_FILE}"
      if [[ "${PX_OBJ_STORE_CREDs_DST}" != "" ]]; then
        printf "Yes, Needs to be deleted.\n" >> "${PX_LOG_FILE}"
        PX_OBJ_STORE_CREDENTIALS_NAME_DST="$(echo "${PX_OBJ_STORE_CREDs_DST}" | cut -d'|' -f5 )"
        PX_NS_DST="$(grep "INFO|PX_NS_DST|" "${PX_RESOURCES_LOG_FILE}" | cut -d'|' -f3 || true)"
        PX_STORAGE_CLUSTER_NAME_DST="$(grep "INFO|PX_STORAGE_CLUSTER_NAME_DST|" "${PX_RESOURCES_LOG_FILE}" | cut -d'|' -f3 || true)"
        PX_POD_DST="$(grep "INFO|PX_ALL_PODS_DST|" "${PX_RESOURCES_LOG_FILE}" | cut -d'|' -f3 | cut -d' ' -f1|| true)"

        ##It will require using pxctl, so set token if authorization is enabled.
        printf "Checking: If authorization is enabled on the destination cluster: " >> "${PX_LOG_FILE}"
        PX_AUTH_CHECK="$(kubectl ${PX_KUBECONF_DST} -n ${PX_NS_DST} get storageclusters.core.libopenstorage.org ${PX_STORAGE_CLUSTER_NAME_DST} -o custom-columns=":spec.security.enabled" --no-headers 2>/dev/null||true)"
        fun_progress
        if [[ "${PX_AUTH_CHECK}" == "true" ]]; then
          printf "Enabled, Going to add authorization token.\n" >> "${PX_LOG_FILE}"
          printf "Getting PX authorization token from the destination cluster: " >> "${PX_LOG_FILE}"
          ADMIN_TOKEN_DST="$(kubectl ${PX_KUBECONF_DST} -n ${PX_NS_DST} get secret px-admin-token -o jsonpath='{.data.auth-token}' | base64 -d 2> /dev/null)"
          fun_progress
          if [[ "${ADMIN_TOKEN_DST}" != "" ]]; then
            printf "Successful\n" >> "${PX_LOG_FILE}"
            printf "Adding authorization token to the portworx pod '${PX_POD_DST}': " >> "${PX_LOG_FILE}"
            kubectl ${PX_KUBECONF_DST} -n ${PX_NS_DST} exec -ti ${PX_POD_DST} -c portworx -- /opt/pwx/bin/pxctl context create admin --token=$ADMIN_TOKEN_DST >> "${PX_LOG_FILE}" 2>&1 || true;
            fun_progress
          else
            printf "Authorization is enabled but unable to get authorization token. Skipping add authorization token.\n" | tee -a "${PX_LOG_FILE}";
          fi
        else
          printf "Disabled, Skipping add authorization token.\n" >> "${PX_LOG_FILE}"
        fi
        printf "Deleting the object-store-credentials from destination cluster: " >> "${PX_LOG_FILE}"
        kubectl ${PX_KUBECONF_DST} exec -n ${PX_NS_DST} ${PX_POD_DST} -c portworx -- /opt/pwx/bin/pxctl credentials delete ${PX_OBJ_STORE_CREDENTIALS_NAME_DST} >> "${PX_LOG_FILE}" 2>&1 || true;
        fun_progress
      else
        printf "No\n" >> "${PX_LOG_FILE}"
      fi
    fi
  printf "\n"
  printf "The cleanup process completed.\n\n" | tee -a "${PX_LOG_FILE}"
